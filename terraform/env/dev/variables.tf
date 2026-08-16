variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for Artifact Registry and the tfstate bucket."
  type        = string
  default     = "asia-northeast1"
}

variable "github_repository" {
  description = "GitHub repository in OWNER/REPO format allowed to impersonate the deploy service account via WIF."
  type        = string
  default     = "gawakawa/next-prenv"
}

variable "iap_members" {
  description = "Members granted IAP access to the preview environment (e.g. [\"user:you@example.com\"])."
  type        = list(string)

  validation {
    condition     = length(var.iap_members) > 0
    error_message = "iap_members must not be empty — otherwise the preview environment always returns IAP 403."
  }
}
