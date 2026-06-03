# RepairLink Mechanical Analytics

dbt project for RepairLink Mechanical Analytics.
Iniciative: https://oeconnection.atlassian.net/browse/DAT-2212

## Overview

This project contains the dbt models, sources, transformations, and documentation used to build the RepairLink Mechanical Analytics data model.

## Project Structure

* `models/` – dbt models organized by layer (staging, intermediate, final)
* `docs/` – project documentation and data dictionaries
* `macros/` – reusable dbt macros
* `seeds/` – static seed data
* `snapshots/` – dbt snapshots
* `tests/` – custom tests
* `analyses/` – ad hoc analyses

## Getting Started

Install dependencies:

```bash
dbt deps
```

Run the project:

```bash
dbt run
```

Run tests:

```bash
dbt test
```

Generate documentation:

```bash
dbt docs generate
dbt docs serve
```

