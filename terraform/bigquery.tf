resource "google_bigquery_dataset" "output" {
  for_each = local.output_datasets

  location   = var.region
  dataset_id = each.key

  default_table_expiration_ms = each.value == "dev" ? var.dev_table_expiration_days * 24 * 60 * 60 * 1000 : null
  delete_contents_on_destroy  = each.value == "dev"

  description = each.value == "prod" ? "Dataform-built warehouse (prod)" : "Dataform-built warehouse (dev)"
  labels      = merge(local.common_labels, { env = each.value })

  depends_on = [google_project_service.api_enabled]
}
