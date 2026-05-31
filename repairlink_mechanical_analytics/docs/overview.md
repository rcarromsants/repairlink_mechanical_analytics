# RepairLink Warehouse Models — Data Dictionary

**Jira epic:** DAT-2215 — Identify DIM Tables
**Companion doc:** `staging_data_dictionary.md`

---

# Overview

The warehouse architecture was simplified and reorganized to better separate:

* raw source representation;
* reusable reference/lookup semantics;
* business transformations;
* analyst-facing curated datasets.

The current warehouse flow is:

```
RAW
 ↓
STAGING
 ↓
REFERENCE
 ↓
INTERMEDIATE
 ↓
FINAL
```

---

# Layer Responsibilities

## STAGING

Purpose:

* mirror source-system structures;
* standardize naming conventions;
* apply lightweight typing and cleanup;
* remove Fivetran metadata columns.

Examples:

* `stg_repairlink__dealertrial`
* `stg_repairlink__shopconfig`
* `stg_repairlink__vehicle`
* `stg_repairlink__transaction_enu_contacttype`

---

## REFERENCE

Purpose:

* centralize reusable lookup/reference datasets;
* apply lightweight normalization and canonicalization;
* store enums, mappings, and reference semantics;
* avoid duplicating lookup logic across downstream models.

Reference models intentionally:

* use operational business identifiers directly;
* avoid surrogate keys;
* avoid artificial “unknown” rows;
* avoid unnecessary intermediate abstraction.

Examples:

* `ref_repairlink__country`
* `ref_repairlink__currency`
* `ref_repairlink__oem`
* `ref_repairlink__contact_type`

---

## INTERMEDIATE

Purpose:

* perform business transformations;
* reshape grain;
* deduplicate transactional datasets;
* enrich entities using reusable reference datasets;
* consolidate multiple source systems into analysis-ready entities.

Examples:

* `int_repairlink__dealer`
* `int_repairlink__shop`
* `int_repairlink__vehicle`
* `int_repairlink__contact`

---

## FINAL

Purpose:

* expose curated business-facing analytical datasets;
* represent stable business entities and relationship bridges;
* preserve operational business keys;
* provide simplified downstream consumption.

Examples:

* `dim_dealer`
* `dim_shop`
* `dim_vehicle`
* `bridge_dealer_oem`
* `bridge_dealer_distance`

---

# Architecture Flow

```
STAGING                                         REFERENCE
────────                                        ─────────
stg_repairlink__countrymaster               ─►  ref_repairlink__country
stg_repairlink__currencymaster             ─►  ref_repairlink__currency
stg_repairlink__dealeroemenrollment        ─►  ref_repairlink__oem
stg_repairlink__transaction_enu_contacttype ─► ref_repairlink__contact_type


STAGING                                         INTERMEDIATE
────────                                        ────────────
stg_repairlink__dealertrial                 ┐
stg_repairlink__dealer_mapper              ├── int_repairlink__dealer
stg_repairlink__dealeroemenrollment        ┘

stg_repairlink__shopconfig                 ─── int_repairlink__shop
stg_repairlink__manufacturer               ─── int_repairlink__manufacturer
stg_repairlink__vehicle                    ─── int_repairlink__vehicle
stg_repairlink__contact                    ─── int_repairlink__contact


INTERMEDIATE / REFERENCE                        FINAL
────────────────────────                        ─────
int_repairlink__dealer                     ─► dim_dealer
stg_repairlink__dealertrial               ─► dim_dealer_trial
int_repairlink__shop                      ─► dim_shop
int_repairlink__manufacturer              ─► dim_manufacturer
int_repairlink__vehicle                   ─► dim_vehicle

ref_repairlink__oem                       ─► bridge_dealer_oem
int_repairlink__dealer                    ─► bridge_dealer_distance
```

---

# Business Key Strategy

The warehouse no longer generates surrogate keys.

All models now rely directly on stable operational business identifiers:

| Entity       | Business Key      |
| ------------ | ----------------- |
| Dealer       | `dealer_id`       |
| Shop         | `shop_id`         |
| Vehicle      | `vin`             |
| Manufacturer | `manufacturer_id` |
| OEM          | `oem_id`          |
| Country      | `country_id`      |
| Currency     | `currency_id`     |

This significantly simplified:

* lineage;
* joins;
* testing;
* debugging;
* downstream semantic clarity.

Artificial “unknown” rows were also removed across the warehouse.

---

# Reference Model Catalogue

## `ref_repairlink__country`

|         |                                                                   |
| ------- | ----------------------------------------------------------------- |
| Purpose | Canonical country reference dataset used across downstream models |
| Source  | `stg_repairlink__countrymaster`                                   |
| Grain   | One row per country                                               |
| Key     | `country_id`                                                      |
| Logic   | Excludes sentinel `country_id = 0` record                         |

### Important columns

| Column                  | Notes                  |
| ----------------------- | ---------------------- |
| `country_id`            | ISO numeric identifier |
| `country_name`          | Country name           |
| `two_letter_iso_code`   | ISO alpha-2            |
| `three_letter_iso_code` | ISO alpha-3            |

---

## `ref_repairlink__currency`

|         |                                            |
| ------- | ------------------------------------------ |
| Purpose | Canonical currency reference dataset       |
| Source  | `stg_repairlink__currencymaster`           |
| Grain   | One row per currency                       |
| Key     | `currency_id`                              |
| Logic   | Excludes sentinel `currency_id = 0` record |

### Important columns

| Column          | Notes                  |
| --------------- | ---------------------- |
| `currency_id`   | ISO numeric identifier |
| `currency_code` | ISO alpha-3            |
| `currency_name` | Currency name          |

---

## `ref_repairlink__oem`

|         |                                            |
| ------- | ------------------------------------------ |
| Purpose | Canonical OEM lookup table                 |
| Source  | `stg_repairlink__dealeroemenrollment`      |
| Grain   | One row per OEM                            |
| Key     | `oem_id`                                   |
| Logic   | Applies lightweight OEM name normalization |

### Important columns

| Column     | Notes              |
| ---------- | ------------------ |
| `oem_id`   | OEM identifier     |
| `oem_name` | Canonical OEM name |

### Normalization rules

| OEM ID | Canonical Name   |
| ------ | ---------------- |
| `1`    | `Chrysler`       |
| `3`    | `General Motors` |

---

## `ref_repairlink__contact_type`

|         |                                               |
| ------- | --------------------------------------------- |
| Purpose | Lookup table for RepairLink contact types     |
| Source  | `stg_repairlink__transaction_enu_contacttype` |
| Grain   | One row per contact type                      |
| Key     | `contact_type_id`                             |

### Important columns

| Column                | Notes                      |
| --------------------- | -------------------------- |
| `contact_type_id`     | Contact type identifier    |
| `contact_type_name`   | System contact type key    |
| `contact_type_remark` | Human-readable description |

---

# Intermediate Model Catalogue

## `int_repairlink__dealer`

|         |                                                                                       |
| ------- | ------------------------------------------------------------------------------------- |
| Purpose | Consolidated dealer entity with enrollment and organizational enrichment              |
| Grain   | One row per dealer                                                                    |
| Key     | `dealer_id`                                                                           |
| Sources | dealer trial, dealer mapper, dealer OEM enrollment, organizational contact enrichment |

### Important transformations

* canonicalizes dealer IDs to 11-character format;
* aggregates OEM enrollment metrics;
* enriches dealers with organizational contact information;
* consolidates multiple dealer-related operational datasets.

---

## `int_repairlink__shop`

|         |                                                                                         |
| ------- | --------------------------------------------------------------------------------------- |
| Purpose | Shop entity enriched with organizational contact information                            |
| Grain   | One row per shop and contact type combination                                           |
| Key     | `shop_id`                                                                               |
| Sources | `stg_repairlink__shopconfig`, `int_repairlink__contact`, `ref_repairlink__contact_type` |

### Important transformations

* joins organizational contact enrichment using:

```sql
shop_id = left(org_key, 11)
```

* enriches shops with:

  * contact details;
  * address information;
  * contact type metadata.

---

## `int_repairlink__manufacturer`

|         |                                     |
| ------- | ----------------------------------- |
| Purpose | Curated manufacturer entity dataset |
| Grain   | One row per manufacturer            |
| Key     | `manufacturer_id`                   |
| Source  | `stg_repairlink__manufacturer`      |

### Important transformations

* excludes sentinel manufacturer rows;
* preserves operational business identifiers;
* retains enrichment attributes used downstream.

---

## `int_repairlink__vehicle`

|         |                                     |
| ------- | ----------------------------------- |
| Purpose | Deduplicated vehicle entity dataset |
| Grain   | One row per VIN                     |
| Key     | `vin`                               |
| Source  | `stg_repairlink__vehicle`           |

### Important transformations

* filters invalid/null VINs;
* deduplicates vehicles by VIN;
* keeps the latest transaction representation;
* preserves VIN intelligence enrichment attributes.

---

## `int_repairlink__contact`

|         |                                          |
| ------- | ---------------------------------------- |
| Purpose | Organizational enrichment dataset        |
| Grain   | One row per `(org_key, contact_type_id)` |
| Key     | `(org_key, contact_type_id)`             |
| Source  | `stg_repairlink__contact`                |

### Important transformations

* normalizes names and address formatting;
* filters incomplete contact records;
* deduplicates organizational contacts;
* acts as reusable enrichment for dealers, shops, and future organizational entities.

---

# Final Model Catalogue

## `dim_dealer`

|         |                                |
| ------- | ------------------------------ |
| Purpose | Curated dealer business entity |
| Grain   | One row per dealer             |
| Key     | `dealer_id`                    |

---

## `dim_dealer_trial`

|         |                                |
| ------- | ------------------------------ |
| Purpose | Dealer trial lifecycle dataset |
| Grain   | One row per dealer trial       |
| Key     | `dealer_trial_id`              |

---

## `dim_shop`

|         |                                           |
| ------- | ----------------------------------------- |
| Purpose | Curated shop business entity              |
| Grain   | One row per shop/contact type combination |
| Key     | `shop_id`                                 |

---

## `dim_manufacturer`

|         |                                      |
| ------- | ------------------------------------ |
| Purpose | Curated manufacturer business entity |
| Grain   | One row per manufacturer             |
| Key     | `manufacturer_id`                    |

---

## `dim_vehicle`

|         |                                 |
| ------- | ------------------------------- |
| Purpose | Curated vehicle business entity |
| Grain   | One row per VIN                 |
| Key     | `vin`                           |

---

## `bridge_dealer_distance`

|         |                                      |
| ------- | ------------------------------------ |
| Purpose | Dealer-to-dealer relationship bridge |
| Grain   | One row per dealer pair              |
| Keys    | `from_dealer_id`, `to_dealer_id`     |

---

## `bridge_dealer_oem`

|         |                                   |
| ------- | --------------------------------- |
| Purpose | Dealer-to-OEM enrollment bridge   |
| Grain   | One row per dealer OEM enrollment |
| Key     | `dealer_oem_enrollment_id`        |

---

# Testing Strategy

The warehouse testing strategy now focuses on:

* operational business-key uniqueness;
* nullability validation;
* grain validation;
* relationship consistency;
* lightweight semantic normalization.

Examples:

* unique dealer IDs;
* unique VINs;
* valid ISO country codes;
* OEM normalization consistency;
* shop/contact enrichment coverage.

---

# Design Decisions

## Why surrogate keys were removed

Surrogate keys introduced unnecessary abstraction and complexity for this warehouse use case.

The operational source systems already expose stable business identifiers that:

* remain consistent across loads;
* simplify lineage;
* simplify debugging;
* improve readability;
* reduce transformation overhead.

---

## Why REFERENCE was separated from INTERMEDIATE

Lookup/reference datasets have different responsibilities from business transformation models.

Separating them improves:

* model clarity;
* lineage simplicity;
* reuse across downstream entities;
* maintainability;
* semantic consistency.

REFERENCE models now own:

* enums;
* lookup semantics;
* lightweight normalization;
* canonical mappings.

INTERMEDIATE models focus exclusively on:

* entity consolidation;
* business transformations;
* deduplication;
* enrichment.
