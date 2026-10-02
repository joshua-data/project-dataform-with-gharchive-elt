# =============================================================================
# Required
# =============================================================================

variable "project_id" {
  description = "GCP project"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in owner/name form"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repo))
    error_message = "github_repo must be in owner/name form."
  }
}

# =============================================================================
# Operational
# =============================================================================

variable "git_token_secret_id" {
  description = "Secret Manager secret holding the GitHub fine-grained PAT used by Dataform to fetch code."
  type        = string
  default     = "dataform-github-token"
}

variable "prod_stg_start_date" {
  description = "stgStartDate for the production release config"
  type        = string
  default     = "2026-09-01"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.prod_stg_start_date))
    error_message = "prod_stg_start_date must be an ISO date, e.g. 2026-09-01."
  }
}

variable "prod_lookback_days" {
  description = "How many days back from the target table's MAX the incremental checkpoint reaches."
  type        = string
  default     = "2"

  validation {
    condition     = can(tonumber(var.prod_lookback_days)) && tonumber(var.prod_lookback_days) >= 0
    error_message = "prod_lookback_days must be a non-negative number."
  }
}

variable "prod_freshness_hours" {
  description = "assert_raw_freshness fails when the newest ingested_at is older than this many hours."
  type        = string
  default     = "3"

  validation {
    condition     = can(tonumber(var.prod_freshness_hours)) && tonumber(var.prod_freshness_hours) > 0
    error_message = "prod_freshness_hours must be a positive number."
  }
}

variable "prod_completeness_lookback_days" {
  description = "assert_raw_hourly_completeness checks this many days back, excluding today and yesterday."
  type        = string
  default     = "7"

  validation {
    condition     = can(tonumber(var.prod_completeness_lookback_days)) && tonumber(var.prod_completeness_lookback_days) >= 2
    error_message = "prod_completeness_lookback_days must be at least 2, since the window already excludes today and yesterday."
  }
}

variable "dev_table_expiration_days" {
  description = "Default table expiration on dw_dataform_dev."
  type        = number
  default     = 14

  validation {
    condition     = var.dev_table_expiration_days >= 1 && var.dev_table_expiration_days <= 365
    error_message = "dev_table_expiration_days must be between 1 and 365."
  }
}

variable "release_cron" {
  description = "When the production release config compiles main. Must run BEFORE workflow_cron."
  type        = string
  default     = "30 0 * * *"

  validation {
    condition     = length(split(" ", trimspace(var.release_cron))) == 5
    error_message = "release_cron must be a 5-field cron expression."
  }
}

variable "workflow_cron" {
  description = "When the daily workflow config executes the latest compilation result."
  type        = string
  default     = "0 1 * * *"

  validation {
    condition     = length(split(" ", trimspace(var.workflow_cron))) == 5
    error_message = "workflow_cron must be a 5-field cron expression."
  }
}

variable "schedule_timezone" {
  description = "tz database name used to interpret both cron expressions."
  type        = string
  default     = "Etc/UTC"
}

variable "workflow_disabled" {
  description = "Set true to keep the Dataform repository and release config in place while suspending automatic workflow invocations."
  type        = bool
  default     = false
}

variable "fully_refresh_incremental_tables" {
  description = "When true, every scheduled run rebuilds incremental tables from scratch instead of MERGEing. Leave false; flip it for a one-off backfill after widening prod_stg_start_date."
  type        = bool
  default     = false
}
