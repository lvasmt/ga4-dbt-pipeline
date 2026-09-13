### GA4 Raw Data Transformation

A dbt project that transforms raw GA4 BigQuery export data into a dimensional
model suitable for BI reporting.

## Overview

The project takes GA4's raw, nested BigQuery export and turns it into a
conformed star schema. It covers sessions, events, and A/B test assignment as
three separate but related stars, sharing a common set of dimensions.

## Stack

- dbt-core with dbt-bigquery
- Google BigQuery
- Python (venv, pip)
- Windows, PowerShell

## Data model

**Dimensions**
- `dim_date`: date spine with calendar attributes
- `dim_page`: page path and title
- `dim_traffic_source`: source, medium, and campaign, with a derived channel
  grouping
- `dim_geo`: country and city
- `dim_device`: device category, brand, model, and marketing name
- `dim_ab_test`: test name and variant

**Facts**
- `fct_sessions`: one row per session, joined to the dimensions above
- `fct_events`: one row per event, including a conversion flag driven by a
  seed table
- `fct_ab_test_sessions`: session-to-test-assignment bridge

**Seeds**
- `seed_conversion_events`: the default set of events treated as conversions
- `seed_ab_test_conversion_events`: per-test conversion event mapping, joined
  at reporting time rather than materialised in dbt

Surrogate keys are generated with a persisted, append-only key-mapping
mechanism for dimensions and other slow-changing business keys, and with a
deterministic hash for the high-volume event grain, where a persisted mapping
table would offer no benefit.

## Design principles

- The pipeline is built to be idempotent: rerunning it on unchanged source
  data must not duplicate rows or drift.
- Consent Mode is handled explicitly. Core reporting only includes hits with
  explicit analytics consent; consent-denied and pending hits are excluded
  from the star schema but retained in staging for potential future analysis.
- Staging is incremental, with deduplication against genuine duplicate event
  delivery from the GA4 export.
- Schema tests cover primary key uniqueness and foreign key integrity across
  the model.

## Setup

1. Create and activate a Python virtual environment, then install
   `requirements.txt`.
2. Create a local `.env` file (not committed) defining: `DBT_BQ_KEYFILE`,
   `DBT_BQ_PROJECT`, `DBT_BQ_RAW_DATASET`, `DBT_BQ_DEV_DATASET`,
   `DBT_BQ_PROD_DATASET`, and `DBT_SEND_ANONYMOUS_USAGE_STATS`.
3. Run `.\load_env.ps1` at the start of each terminal session to load those
   variables.
4. `dbt seed`, then `dbt run`, then `dbt test`.

## Status

The core star schema (sessions, events, A/B test assignment) is built and
tested. Retention and customer journey modelling are planned but deferred, as
they follow a different modelling pattern (cohort and path analysis rather
than a conformed star).
