locals {
  # ---------------------------------------------------------------------------
  # Labels
  # ---------------------------------------------------------------------------

  common_labels = {
    project    = "gharchive"
    managed_by = "terraform"
    tool       = "dataform"
  }

  # ---------------------------------------------------------------------------
  # APIs
  # ---------------------------------------------------------------------------

  required_apis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "secretmanager.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "dataform.googleapis.com",
  ]

  # ---------------------------------------------------------------------------
  # IAM
  # ---------------------------------------------------------------------------

  dataform_ci_sa_id        = "gharchive-dataform-ci"
  dataform_ci_sa_email     = "serviceAccount:${google_service_account.dataform_ci.email}"
  dataform_runner_sa_id    = "gharchive-dataform-runner"
  dataform_runner_sa_email = "serviceAccount:${google_service_account.dataform_runner.email}"

  ci_sa_project_roles = [
    "roles/viewer",
    "roles/dataform.admin",
    "roles/bigquery.jobUser",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/serviceusage.serviceUsageAdmin",
  ]
  ci_sa_output_dataset_roles = ["roles/bigquery.dataOwner"]
  ci_sa_secret_roles         = ["roles/secretmanager.admin"]

  runner_sa_project_roles        = ["roles/bigquery.jobUser"]
  runner_sa_raw_dataset_roles    = ["roles/bigquery.dataViewer"]
  runner_sa_raw_bucket_roles     = ["roles/storage.objectViewer"]
  runner_sa_output_dataset_roles = ["roles/bigquery.dataEditor"]

  wif_pool_id     = "github-pool"
  wif_pool_name   = "projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${local.wif_pool_id}"
  wif_provider_id = "dataform-provider"

  dataform_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-dataform.iam.gserviceaccount.com"

  dataform_agent_runner_sa_roles = [
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
  ]

  git_token_secret_version = "projects/${data.google_project.this.number}/secrets/${var.git_token_secret_id}/versions/latest"

  # ---------------------------------------------------------------------------
  # Names
  # ---------------------------------------------------------------------------

  github_repo_url    = "https://github.com/${var.github_repo}.git"
  dataform_repo_name = "gharchive-dataform"

  gharchive_bucket_name    = "${var.project_id}-gharchive"
  bq_raw_dataset_id        = "raw__gharchive"
  bq_output_dataset_id     = "dw_dataform"
  bq_output_dev_dataset_id = "dw_dataform_dev"

  output_datasets = {
    (local.bq_output_dataset_id)     = "prod"
    (local.bq_output_dev_dataset_id) = "dev"
  }

  output_dev_schema_suffix = "dev"
}
