# Project number is required for the IAP JWT audience below — the numeric
# form, not var.project_id.
data "google_project" "this" {
  project_id = var.project_id
}

locals {
  service_name = "next-prenv-pr-${var.pr_number}"

  # The app verifies the IAP-signed JWT assertion itself (see
  # src/lib/iap.ts), so it needs to know which audience to expect. Format is
  # specific to Cloud Run without a load balancer in front:
  # https://cloud.google.com/iap/docs/signed-headers-howto
  iap_audience = "/projects/${data.google_project.this.number}/locations/${var.region}/services/${local.service_name}"
}

# Used only as the app's AUTH_SECRET (Auth.js session cookie signing).
# Stored in tfstate in the open rather than Secret Manager: prenv-deployer
# has no secretmanager role today, and this is a throwaway preview
# environment behind a private state bucket. Don't reuse this pattern for
# production secrets.
resource "random_password" "auth_secret" {
  length  = 32
  special = false
}

# PR preview environment: one Cloud Run service running the app next to a
# MySQL sidecar. Cloud Run rejects the deploy with a 400 unless exactly one
# container declares `ports` (the ingress container) and every container
# named in another's `depends_on` declares a `startup_probe`.
resource "google_cloud_run_v2_service" "preview" {
  # iap_enabled is a Beta-only field, so this resource uses the google-beta provider.
  provider = google-beta

  name     = local.service_name
  project  = var.project_id
  location = var.region

  # Must be false so `tofu destroy` can remove the service on PR close.
  deletion_protection = false

  # BETA launch stage is required to use the preview iap_enabled field.
  launch_stage = "BETA"

  # Restricts access to identities granted roles/iap.httpsResourceAccessor
  # in terraform/env/dev (var.iap_members). No public (allUsers) access.
  iap_enabled = true

  template {
    scaling {
      max_instance_count = 1
    }

    volumes {
      name = "mysql-data"
      empty_dir {
        medium     = "MEMORY"
        size_limit = "512Mi"
      }
    }

    containers {
      name  = "app"
      image = var.app_image

      ports {
        container_port = 3000
      }

      env {
        name  = "DATABASE_URL"
        value = "mysql://root:password@localhost:3306/app"
      }

      # See src/lib/iap.ts: rejects any assertion not minted for this
      # specific Cloud Run service.
      env {
        name  = "IAP_AUDIENCE"
        value = local.iap_audience
      }

      env {
        name  = "AUTH_SECRET"
        value = random_password.auth_secret.result
      }

      # Migrations and seed data live only in the in-memory `db` sidecar, so
      # they must run again on every cold start (there's no equivalent of
      # compose.yaml's one-shot `migrate` service on Cloud Run). Reuses the
      # same `pnpm migrate:deploy && pnpm seed` compose.yaml's own `migrate`
      # service runs, on the same `builder` image (var.app_image is built
      # with `target: builder` in CI) — that image already has the full
      # `prisma` CLI toolchain, unlike the slim standalone runner image.
      command = ["sh", "-c"]
      args = [
        "pnpm migrate:deploy && pnpm seed && pnpm start"
      ]

      resources {
        limits   = { cpu = "1", memory = "1Gi" }
        cpu_idle = true
      }

      depends_on = ["db"]
    }

    containers {
      name  = "db"
      image = "mysql:8.4"

      env {
        name  = "MYSQL_ROOT_PASSWORD"
        value = "password"
      }
      env {
        name  = "MYSQL_DATABASE"
        value = "app"
      }

      volume_mounts {
        name       = "mysql-data"
        mount_path = "/var/lib/mysql"
      }

      resources {
        # mysqld idles around 400MB; the in-memory data directory above
        # counts against this too.
        limits            = { cpu = "1", memory = "1Gi" }
        cpu_idle          = true
        startup_cpu_boost = false
      }

      # mysqld only starts listening on TCP after its own init (creating
      # `app`, applying grants) completes, so this probe doubles as the
      # readiness signal `compose.yaml`'s migrate retry loop existed for.
      startup_probe {
        tcp_socket {
          port = 3306
        }
        initial_delay_seconds = 5
        period_seconds        = 5
        timeout_seconds       = 3
        failure_threshold     = 24
      }
    }
  }

  # The Cloud Run Admin API doesn't persist launch_stage — it's a
  # request-only directive, and GET always reports back the stage actually
  # required by the service's features. That makes launch_stage a permanent
  # GA/BETA diff.
  lifecycle {
    ignore_changes = [launch_stage]
  }
}
