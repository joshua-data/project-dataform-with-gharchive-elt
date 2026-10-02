# =============================================================================
# Runner SA
# =============================================================================

resource "google_service_account" "dataform_runner" {
  account_id   = local.dataform_runner_sa_id
  display_name = "Dataform workflow runner (impersonated by the Dataform service agent)"

  depends_on = [google_project_service.api_enabled]
}

resource "google_project_iam_member" "runner_project_roles" {
  for_each = toset(local.runner_sa_project_roles)

  project = var.project_id
  member  = local.dataform_runner_sa_email
  role    = each.value
}

resource "google_storage_bucket_iam_member" "runner_raw_bucket_roles" {
  for_each = toset(local.runner_sa_raw_bucket_roles)

  bucket = local.gharchive_bucket_name
  member = local.dataform_runner_sa_email
  role   = each.value
}

resource "google_bigquery_dataset_iam_member" "runner_bq_raw_roles" {
  for_each = toset(local.runner_sa_raw_dataset_roles)

  project    = var.project_id
  dataset_id = local.bq_raw_dataset_id
  member     = local.dataform_runner_sa_email
  role       = each.value
}

resource "google_bigquery_dataset_iam_member" "runner_bq_output_roles" {
  for_each = {
    for pair in setproduct(keys(local.output_datasets), local.runner_sa_output_dataset_roles) :
    "${pair[0]}:${pair[1]}" => { dataset_id = pair[0], role = pair[1] }
  }

  project    = var.project_id
  dataset_id = google_bigquery_dataset.output[each.value.dataset_id].dataset_id
  member     = local.dataform_runner_sa_email
  role       = each.value.role
}

# =============================================================================
# CI deployer SA
# =============================================================================

resource "google_service_account" "dataform_ci" {
  account_id   = local.dataform_ci_sa_id
  display_name = "GitHub Actions CI deployer (impersonated via WIF)"

  depends_on = [google_project_service.api_enabled]
}

resource "google_project_iam_member" "ci_project_roles" {
  for_each = toset(local.ci_sa_project_roles)

  project = var.project_id
  member  = local.dataform_ci_sa_email
  role    = each.value
}

resource "google_bigquery_dataset_iam_member" "ci_bq_output_roles" {
  for_each = {
    for pair in setproduct(keys(local.output_datasets), local.ci_sa_output_dataset_roles) :
    "${pair[0]}:${pair[1]}" => { dataset_id = pair[0], role = pair[1] }
  }

  project    = var.project_id
  dataset_id = google_bigquery_dataset.output[each.value.dataset_id].dataset_id
  member     = local.dataform_ci_sa_email
  role       = each.value.role
}

resource "google_secret_manager_secret_iam_member" "ci_git_token_roles" {
  for_each = toset(local.ci_sa_secret_roles)

  project   = var.project_id
  secret_id = data.google_secret_manager_secret.git_token.secret_id
  member    = local.dataform_ci_sa_email
  role      = each.value
}

resource "google_service_account_iam_member" "ci_acts_as_runner" {
  service_account_id = google_service_account.dataform_runner.name
  member             = local.dataform_ci_sa_email
  role               = "roles/iam.serviceAccountUser"
}

resource "google_storage_bucket_iam_member" "ci_tfstate" {
  bucket = "${var.project_id}-gharchive-tfstate"
  member = local.dataform_ci_sa_email
  role   = "roles/storage.admin"
}

# =============================================================================
# Dataform service agent
# =============================================================================

resource "google_service_account_iam_member" "agent_runner_sa_roles" {
  for_each = toset(local.dataform_agent_runner_sa_roles)

  service_account_id = google_service_account.dataform_runner.name
  member             = local.dataform_agent
  role               = each.value

  depends_on = [google_dataform_repository.this]
}

resource "google_secret_manager_secret_iam_member" "agent_git_token_accessor" {
  project   = var.project_id
  secret_id = data.google_secret_manager_secret.git_token.secret_id
  member    = local.dataform_agent
  role      = "roles/secretmanager.secretAccessor"

  depends_on = [google_dataform_repository.this]
}
