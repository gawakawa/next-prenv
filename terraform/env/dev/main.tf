locals {
  services = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "storage.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iap.googleapis.com",
  ]
}

resource "google_project_service" "core" {
  for_each = toset(local.services)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Holds tfstate for terraform/env/preview, one object per PR (prefix "pr/<N>").
# CI reads and writes this on every deploy/teardown.
resource "google_storage_bucket" "tfstate" {
  name     = "${var.project_id}-tfstate"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.core]
}

resource "google_artifact_registry_repository" "preview" {
  project       = var.project_id
  location      = var.region
  repository_id = "prenv"
  format        = "DOCKER"
  description   = "Docker images for PR preview environments."

  # Server-side GC: delete stale preview images automatically. The daily
  # stale sweep (teardown-prenv.yml) destroys Cloud Run services after 3
  # days, so images older than that are safe to delete — an in-use image is
  # always newer than 7 days.
  cleanup_policies {
    id     = "delete-stale-preview-images"
    action = "DELETE"
    condition {
      older_than = "604800s" # 7 days
    }
  }

  depends_on = [google_project_service.core]
}

# --- Workload Identity Federation: lets GitHub Actions impersonate the
# deploy service account without a long-lived key. ---

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "prenv-github"
  project                   = var.project_id
  display_name              = "GitHub Actions – prenv"
  description               = "WIF pool for the preview environment workflows."

  depends_on = [google_project_service.core]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  project                            = var.project_id
  display_name                       = "GitHub Actions OIDC"
  description                        = "Allows GitHub Actions in this repository to impersonate the deploy SA."

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deployer" {
  account_id   = "prenv-deployer"
  project      = var.project_id
  display_name = "prenv deploy SA"
  description  = "Impersonated by GitHub Actions to build images and manage the PR preview Cloud Run service."
}

resource "google_service_account_iam_member" "wif_deployer" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

# Build and push images to Artifact Registry.
resource "google_artifact_registry_repository_iam_member" "deployer_ar_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.preview.location
  repository = google_artifact_registry_repository.preview.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

# Create/update/delete the Cloud Run service. Setting its IAM isn't needed —
# the IAP service agent's run.invoker is granted at the project level below.
resource "google_project_iam_member" "deployer_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# actAs the default compute SA used as the Cloud Run service's runtime identity.
resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_storage_bucket_iam_member" "deployer_tfstate" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_project_iam_member" "deployer_serviceusage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# --- IAP: restrict access to the preview environment to iap_members. ---

resource "google_iap_web_iam_member" "preview_accessor" {
  for_each = toset(var.iap_members)

  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = each.value

  depends_on = [google_project_service.core]
}

# The IAP service agent doesn't exist until something explicitly provisions
# it — enabling iap.googleapis.com alone isn't enough, and referencing its
# well-known email before it exists 400s ("Service account ... does not
# exist"). This resource is the documented way to force that provisioning.
resource "google_project_service_identity" "iap" {
  provider = google-beta
  project  = var.project_id
  service  = "iap.googleapis.com"

  depends_on = [google_project_service.core]
}

# Granted at the PROJECT level instead of per-service so CI never needs
# roles/iap.admin (which has a known provider bug on the per-service IAM
# resource: hashicorp/terraform-provider-google#23092) and there's no
# post-deploy propagation delay causing a transient 403.
resource "google_project_iam_member" "iap_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = google_project_service_identity.iap.member
}
