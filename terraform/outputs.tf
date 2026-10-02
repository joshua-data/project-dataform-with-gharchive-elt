output "project_id" {
  description = "Register this as GitHub Variable GCP_PROJECT_ID."
  value       = var.project_id
}

output "region" {
  description = "Register this as GitHub Variable GCP_REGION."
  value       = var.region
}

output "ci_sa_email" {
  description = "Register this as GitHub Secret GCP_SA_EMAIL. The identity GitHub Actions impersonates to run terraform apply."
  value       = google_service_account.dataform_ci.email
}

output "dataform_runner_sa_email" {
  description = "Identity every Dataform workflow invocation executes as. "
  value       = google_service_account.dataform_runner.email
}

output "dataform_agent" {
  description = "Google-managed Dataform service agent."
  value       = local.dataform_agent
}

output "wif_provider_id" {
  description = "Register this as GitHub Secret GCP_WIF_PROVIDER. Full resource name of the OIDC provider google-github-actions/auth exchanges the workflow token against."
  value       = "projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${local.wif_pool_id}/providers/${local.wif_provider_id}"
}

output "dataform_repository" {
  description = "Dataform repository name, visible under BigQuery > Dataform in the console."
  value       = google_dataform_repository.this.name
}

output "dataform_release_config" {
  description = "Release config that compiles main on a schedule."
  value       = google_dataform_repository_release_config.prod.name
}

output "dataform_workflow_config" {
  description = "Workflow config that executes the latest compilation result on a schedule."
  value       = google_dataform_repository_workflow_config.daily.name
}

output "datasets" {
  description = "BigQuery datasets this state owns. Everything Dataform builds lands in one of these."
  value       = sort(keys(google_bigquery_dataset.output))
}

output "git_token_secret_version" {
  description = "Secret Manager version the Dataform repository reads the GitHub token from. The alias means rotation needs no Terraform run."
  value       = local.git_token_secret_version
}
