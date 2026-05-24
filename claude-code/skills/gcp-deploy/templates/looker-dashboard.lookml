# Looker dashboard for {{SERVICE_NAME}} analytics.
# Connect this to the BigQuery table defined by bigquery/schema.json.
- dashboard: {{SERVICE_NAME}}_overview
  title: {{SERVICE_NAME}} Overview
  layout: newspaper
  refresh: 1 hour

  filters:
    - name: date_range
      title: Date Range
      type: field_filter
      default_value: 7 days
      explore: events
      field: events.event_timestamp_date

  elements:
    - title: Events per day
      name: events_per_day
      model: {{SERVICE_NAME}}_analytics
      explore: events
      type: looker_line
      fields: [events.event_timestamp_date, events.count]
      sorts: [events.event_timestamp_date desc]
      limit: 30

    - title: Top event types
      name: top_event_types
      model: {{SERVICE_NAME}}_analytics
      explore: events
      type: looker_bar
      fields: [events.event_type, events.count]
      sorts: [events.count desc]
      limit: 10

    - title: Unique users (7d)
      name: unique_users
      model: {{SERVICE_NAME}}_analytics
      explore: events
      type: single_value
      fields: [events.unique_user_count]
