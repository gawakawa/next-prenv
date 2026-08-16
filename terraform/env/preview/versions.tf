terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    # iap_enabled on google_cloud_run_v2_service is a Beta-only field.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.15"
    }
  }

  # Neither bucket nor prefix is hardcoded here; both are supplied at init
  # time so each PR gets its own state file:
  #   tofu init -backend-config="bucket=<state_bucket_name>" \
  #             -backend-config="prefix=pr/<PR_NUMBER>"
  # bucket must match terraform/env/dev's state_bucket_name output.
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
