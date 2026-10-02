data "google_secret_manager_secret" "git_token" {
  project   = var.project_id
  secret_id = var.git_token_secret_id

  depends_on = [google_project_service.api_enabled]
}

resource "google_dataform_repository" "this" {
  provider = google-beta

  region       = var.region
  name         = local.dataform_repo_name
  display_name = local.dataform_repo_name
  labels       = local.common_labels

  service_account = google_service_account.dataform_runner.email

  git_remote_settings {
    url                                 = local.github_repo_url
    default_branch                      = "main"
    authentication_token_secret_version = local.git_token_secret_version
  }

  workspace_compilation_overrides {
    default_database = var.project_id
    schema_suffix    = local.output_dev_schema_suffix
  }

  depends_on = [google_project_service.api_enabled]
}

resource "google_dataform_repository_release_config" "prod" {
  provider = google-beta

  project = var.project_id
  region  = var.region

  repository    = google_dataform_repository.this.name
  name          = "prod"
  git_commitish = "main"
  time_zone     = var.schedule_timezone
  cron_schedule = var.release_cron

  code_compilation_config {
    default_location = var.region
    default_database = var.project_id
    default_schema   = local.bq_output_dataset_id
    assertion_schema = local.bq_output_dataset_id

    # Explicitly empty for prod
    database_suffix = ""
    schema_suffix   = ""
    table_prefix    = ""

    vars = {
      env                      = "prod"
      stgStartDate             = var.prod_stg_start_date
      lookbackDays             = var.prod_lookback_days
      freshnessHours           = var.prod_freshness_hours
      completenessLookbackDays = var.prod_completeness_lookback_days
    }
  }

  depends_on = [
    google_service_account_iam_member.agent_runner_sa_roles,
    google_secret_manager_secret_iam_member.agent_git_token_accessor,
  ]
}

resource "google_dataform_repository_workflow_config" "daily" {
  provider = google-beta

  project = var.project_id
  region  = var.region

  repository     = google_dataform_repository.this.name
  name           = "daily"
  release_config = google_dataform_repository_release_config.prod.id
  time_zone      = var.schedule_timezone
  cron_schedule  = var.workflow_cron
  disabled       = var.workflow_disabled

  invocation_config {
    service_account                          = google_service_account.dataform_runner.email
    transitive_dependencies_included         = true
    fully_refresh_incremental_tables_enabled = var.fully_refresh_incremental_tables
  }
}
