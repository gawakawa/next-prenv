terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    # google_project_service_identity (provisions the IAP service agent) is
    # a beta-only resource.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.15"
    }
  }

  # Applied once, manually, by the project owner — never by CI. State still
  # lives in GCS (not local) so it survives losing this machine; bucket must
  # be bootstrapped first (see README), since it's this config's own output.
  backend "gcs" {
    bucket = "gawakawa-next-prenv-tfstate"
    prefix = "env/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
