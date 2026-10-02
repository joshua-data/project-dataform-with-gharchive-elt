resource "google_iam_workload_identity_pool_provider" "dataform" {
  workload_identity_pool_id          = local.wif_pool_id
  workload_identity_pool_provider_id = local.wif_provider_id

  display_name = "GitHub OIDC (Dataform)"
  description  = "WIF provider for GitHub Actions OIDC from ${var.github_repo}"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  attribute_condition = <<-EOT
    assertion.repository == "${var.github_repo}" && assertion.ref == "refs/heads/main"
  EOT

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  depends_on = [google_project_service.api_enabled]
}

resource "google_service_account_iam_member" "github_repo_acts_as_ci" {
  service_account_id = google_service_account.dataform_ci.name
  member             = "principalSet://iam.googleapis.com/${local.wif_pool_name}/attribute.repository/${var.github_repo}"
  role               = "roles/iam.workloadIdentityUser"

  depends_on = [google_iam_workload_identity_pool_provider.dataform]
}
