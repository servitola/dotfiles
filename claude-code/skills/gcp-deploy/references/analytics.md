# Analytics setup (BigQuery + Looker)

Read this only if the user answered yes to BigQuery and/or Looker in Phase 2.

## BigQuery table

The schema in `bigquery/schema.json` describes a single events table.

**Create the dataset and table** (user runs this after the skill finishes):

```bash
gcloud config set project {{PROJECT_ID}}
bq --location={{REGION}} mk --dataset {{PROJECT_ID}}:{{SERVICE_NAME}}_analytics
bq mk --table \
  --time_partitioning_field=event_timestamp \
  --time_partitioning_type=DAY \
  {{PROJECT_ID}}:{{SERVICE_NAME}}_analytics.events \
  bigquery/schema.json
```

Day-partitioning on `event_timestamp` keeps query cost predictable.

## Ingestion patterns

Pick one based on event volume.

| Volume        | Pattern                                                                                              |
|---------------|------------------------------------------------------------------------------------------------------|
| Low (<10/s)   | Cloud Run → `bigquery.tables.insertAll` (streaming insert). Simple, but per-row cost.                |
| Medium / high | Cloud Run → Pub/Sub topic → BigQuery subscription (native, no Dataflow). Cheaper, slight latency.    |

For both patterns the Cloud Run service account needs `roles/bigquery.dataEditor`
(streaming) or `roles/pubsub.publisher` (Pub/Sub). Add to `service.yaml`'s
TODO list when wiring up.

## Looker dashboard

The template at `looker/dashboard.lookml` is a starting LookML dashboard,
not a full model. To make it usable:

1. In Looker, create a connection to BigQuery dataset
   `{{PROJECT_ID}}:{{SERVICE_NAME}}_analytics`.
2. Create a model named `{{SERVICE_NAME}}_analytics` with one explore: `events`.
3. Define a view `events` over the `events` table with measures:
   - `count` (count of rows),
   - `unique_user_count` (count distinct `user_id`).
4. Drop `dashboard.lookml` into the LookML project — the dashboard will render.

If the user prefers Looker Studio (free, no LookML), skip the `.lookml`
file and instead instruct them to: BigQuery console → table → Explore →
Looker Studio. The Looker Studio connection is automatic.
