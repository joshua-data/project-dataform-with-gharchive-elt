// ════════════════════════════════════════════════════════════════════════
// One file, 5 tables at once
//    - core_fact__push_events
//    - core_fact__pull_request_events
//    - core_fact__issues_events
//    - core_fact__watch_events
//    - core_fact__fork_events
// ════════════════════════════════════════════════════════════════════════

for (const fact of utils.EVENT_FACTS) {

  // ════════════════════════════════════════════════════════════════
  // Step 1. Extract all the columns from payload
  // ════════════════════════════════════════════════════════════════

  const payloadLines = [];

  for (const col of fact.payloadColumns) {
    const expression = utils.jsonByType("payload", col.path, col.type);
    payloadLines.push(`${expression} as ${col.name},`);
  }

  const payloadSelect = payloadLines.join("\n");

  // ════════════════════════════════════════════════════════════════
  // Step 2. Define columns for nonNull assertion
  // ════════════════════════════════════════════════════════════════

  const nonNullColumns = ["event_id", "event_name", "created_date"];
  if (!fact.repoIdCanBeNull) {
    nonNullColumns.push("repo_id");
  }

  // ════════════════════════════════════════════════════════════════
  // Step 3. Define table configuration and query
  // ════════════════════════════════════════════════════════════════

  const table = publish(
    `core_fact__${fact.tableSuffix}_events`,
    {
      type: "incremental",
      description:
        `Transactional fact filtered to ${fact.eventName} only. ` +
        `Inherits every column from stg_fact__events as-is and flattens ` +
        `the event-specific fields inside the payload JSON into typed columns. ` +
        `Grain: one event.`,
      uniqueKey: ["event_id"],
      bigquery: {
        partitionBy: "created_date",
        clusterBy: ["repo_id", "user_id"],
        updatePartitionFilter: "created_date >= checkpoint_date",
      },
      tags: ["core", "fact", "transactional-fact"],
      assertions: {
        uniqueKey: ["event_id"],
        nonNull: nonNullColumns
      },
    }    
  );

  table.preOps(
    (ctx) => utils.checkpointDeclare(ctx.incremental(), ctx.self(), "created_date")
  );

  table.query(
    (ctx) => `
      select
          * except (payload),
          ${payloadSelect}
      from
          ${ctx.ref("stg_fact__events")}
      where true
          and created_date >= checkpoint_date
          and event_name = '${fact.eventName}'
    `
  );
}
