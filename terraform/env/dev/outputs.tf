output "project_id" {
  description = "Google Cloud project ID. Set as the GitHub `preview` environment variable GCP_PROJECT_ID."
  value       = var.project_id
}

output "region" {
  description = "Region used for Artifact Registry, the tfstate bucket, and the Cloud Run service. Set as the GitHub `preview` environment variable GCP_REGION."
  value       = var.region
}

output "repository_url" {
  description = "Docker registry URL for the Artifact Registry repository. Set as the GitHub `preview` environment variable AR_REPO."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.preview.repository_id}"
}

output "state_bucket_name" {
  description = "GCS bucket holding terraform/env/preview's per-PR tfstate. Set as the GitHub `preview` environment variable GCS_BUCKET."
  value       = google_storage_bucket.tfstate.name
}

output "wif_provider_name" {
  description = "Workload Identity Provider resource name. Set as the GitHub `preview` environment variable WIF_PROVIDER."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account_email" {
  description = "Deploy service account email. Set as the GitHub `preview` environment variable DEPLOY_SA."
  value       = google_service_account.deployer.email
}
