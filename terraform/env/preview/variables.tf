variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service."
  type        = string
  default     = "asia-northeast1"
}

variable "pr_number" {
  description = "Pull request number. Used to name and isolate the preview environment."
  type        = number
}

variable "app_image" {
  description = "Fully-qualified app image reference, built and passed in by CI. Empty on teardown, where no build happens and a placeholder default applies."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}
