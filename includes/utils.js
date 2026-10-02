// ════════════════════════════════════════════════════════════════════════
// How to use: `utils.jsonInt(...)`
// ════════════════════════════════════════════════════════════════════════
// 1. jsonByType: extract one single value from a json object
// 2. checkpointDeclare: dbt's is_incremental() + batch_filter
// 3. EVENT_FACTS: core_fact_*_events table's specification

const vars = dataform.projectConfig.vars;

// ════════════════════════════════════════════════════════════════════════
// 1. jsonByType: extract one single value from a json object
// ════════════════════════════════════════════════════════════════════════

function jsonRaw(col, path) {
  return `nullif(trim(json_value(${col}, '$.${path}')), '')`;
}

function jsonString(col, path) {
  return jsonRaw(col, path);
}

function jsonLower(col, path) {
  return `lower(${jsonRaw(col, path)})`;
}

function jsonInt(col, path) {
  return `safe_cast(${jsonRaw(col, path)} as int64)`;
}

function jsonByType(col, path, type) {
  if (type === "int64") return jsonInt(col, path);
  if (type === "lower") return jsonLower(col, path);
  return jsonString(col, path);
}

// ════════════════════════════════════════════════════════════════════════
// 2. checkpointDeclare: dbt's is_incremental() + batch_filter
// ════════════════════════════════════════════════════════════════════════

function checkpointDeclare(isIncremental, selfTable, dateCol) {
  // (1) Incremental Strategy
  const incrementalBuild = `
    select
      coalesce(
        date_sub(max(${dateCol}), interval ${vars.lookbackDays} day),
        date('${vars.stgStartDate}')
      ),
    from
      ${selfTable}
  `;
  // (2) Full Refresh Strategy
  const firstBuild = `select date('${vars.stgStartDate}')`;

  if (isIncremental) {
    return `declare checkpoint_date date default (${incrementalBuild});`;
  } else {
    return `declare checkpoint_date date default (${firstBuild});`;
  }
}

// ════════════════════════════════════════════════════════════════════════
// 3. EVENT_FACTS: core_fact_*_events table's specification
// ════════════════════════════════════════════════════════════════════════

const EVENT_FACTS = [
  {
    eventName: "push_event",
    tableSuffix: "push",
    payloadColumns: [
      { name: "push_id",       path: "push_id",       type: "int64"  },
      { name: "ref",           path: "ref",           type: "string" },
      { name: "head",          path: "head",          type: "lower"  },
      { name: "before",        path: "before",        type: "lower"  },
      { name: "repository_id", path: "repository_id", type: "int64"  },
    ],
  },
  {
    eventName: "pull_request_event",
    tableSuffix: "pull_request",
    payloadColumns: [
      { name: "action",                path: "action",                  type: "lower"  },
      { name: "pull_request_id",       path: "pull_request.id",         type: "int64"  },
      { name: "pull_request_number",   path: "pull_request.number",     type: "int64"  },
      { name: "pull_request_head_ref", path: "pull_request.head.ref",   type: "string" },
      { name: "pull_request_base_ref", path: "pull_request.base.ref",   type: "string" },
    ],
  },
  {
    eventName: "issues_event",
    tableSuffix: "issues",
    payloadColumns: [
      { name: "action",       path: "action",       type: "lower" },
      { name: "issue_id",     path: "issue.id",     type: "int64" },
      { name: "issue_number", path: "issue.number", type: "int64" },
      { name: "issue_state",  path: "issue.state",  type: "lower" },
    ],
  },
  {
    eventName: "watch_event",
    tableSuffix: "watch",
    payloadColumns: [
      { name: "action", path: "action", type: "lower" },
    ],
  },
  {
    eventName: "fork_event",
    tableSuffix: "fork",
    repoIdCanBeNull: true,
    payloadColumns: [
      { name: "action",           path: "action",           type: "lower"  },
      { name: "forkee_id",        path: "forkee.id",        type: "int64"  },
      { name: "forkee_full_name", path: "forkee.full_name", type: "string" },
    ],
  },
];

module.exports = {
  jsonString,
  jsonLower,
  jsonInt,
  jsonByType,
  checkpointDeclare,
  EVENT_FACTS,
};
