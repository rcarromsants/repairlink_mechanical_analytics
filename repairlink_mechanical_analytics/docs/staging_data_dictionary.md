# RepairLink Staging Models — Data Dictionary

**Jira epic:** [DAT-2215 — Identify DIM Tables](https://oeconnection.atlassian.net/browse/DAT-2215)
**Source database / schema:** `RAW.REPAIRLINK_SQLSERVER_DBO`
**Ingestion:** Fivetran from RepairLink SQL Server
**Last data validation:** 2026-05-06

---

## Overview

This document describes every source table currently staged in the `repairlink_mechanical_analytics` dbt project, why it was added, what's in it, and how it flows downstream into the dimensional model.

The goal of the epic is to identify and model the relevant dim tables → shops, dealers, users, locations, and related entities. Every staging model below was selected from the **130 tables** in `RAW.REPAIRLINK_SQLSERVER_DBO` based on:

1. Whether it represents a **business entity** worth dimensioning, or
2. Whether it provides **enrichment data** for an existing dimension, or
3. Whether it is a **reference / lookup** that decodes IDs into meaningful labels.

Tables that are operational, audit, log, or cross-reference (`*_AUD_*`, `*_HST_*`, `*_LOG_*`, `*_XRF_*`, `INTEGRATION_OUTBOX_*`, etc.) were intentionally excluded — they don't add analytical value at the dim layer.

### Architecture flow

```
STAGING (incremental (for now) - should be review for view, rename/cast)
        │
        ├── stg_repairlink__dealertrial ───────────┐
        │   stg_repairlink__dealeroemenrollment ───►  int_repairlink__dealer ──► dim_dealer
        │   stg_repairlink__dealer_mapper ─────────┘
        │
        ├── stg_repairlink__shopconfig ────────────►  int_repairlink__shop ───► dim_shop
        │   stg_repairlink__shopusermapper                (passthrough — kept staging-only)
        │
        ├── stg_repairlink__manufacturer ──────────►  int_repairlink__manufacturer ──► dim_manufacturer
        ├── stg_repairlink__countrymaster ─────────►  int_repairlink__country ─────► dim_country
        ├── stg_repairlink__currencymaster ────────►  int_repairlink__currency ────► dim_currency
        │
        ├── stg_repairlink__vehicle ───────────────►  int_repairlink__vehicle (dedup by VIN) ──► dim_vehicle
        ├── stg_repairlink__contact ───────────────►  int_repairlink__contact (filtered) ─────► dim_contact
        │
        └── stg_repairlink__suppliermapper                (staging-only — no dim yet)
```

---

## Tables intentionally excluded

These were considered and dropped after data validation:

| Table | Reason for exclusion |
|---|---|
| `INTEGRATORMASTER` | Only **1 row** — not enough data to warrant a dim |
| `FEATURES` | Only **1 row** — placeholder for future feature flags |
| `FEATURESOVERRIDE` | Only **1 row** — depends on FEATURES being populated |

These can be added later if the source data fills in.

---

## Staging model catalogue

### 1. `stg_repairlink__dealertrial`

| | |
|---|---|
| **Source table** | `DEALERTRIAL` |
| **Why we added it** | Base source for `dim_dealer`. Tracks dealer lifecycle (trial start, end, status). |
| **Row count** | 18 active records |
| **Primary key** | `dealer_trial_id` (from source `DEALERTRIALID`) |
| **Natural key** | `dealer_id` (15-char varchar) |
| **Materialization** | `incremental` on `_fivetran_synced` |
| **Downstream** | `int_repairlink__dealer` → `dim_dealer` |

**Important columns:**
- `dealer_trial_id` (PK)
- `dealer_id` — natural key, joins to dealer enrollment + mapper
- `status_id` — currently `1` for all rows (single value observed)
- `trial_started_at` / `trial_ended_at` — UTC timestamps; null `trial_ended_at` = active dealer

**Data notes:**
- Very small dataset (18 records) — likely demo/sandbox or early-stage account
- `is_active` flag derived in `dim_dealer` from `trial_ended_at IS NULL`

---

### 2. `stg_repairlink__shopconfig`

| | |
|---|---|
| **Source table** | `SHOPCONFIG` |
| **Why we added it** | Base source for `dim_shop`. Holds shop configuration (location, order type). |
| **Row count** | 15 active records |
| **Primary key** | `shop_config_id` (from source `ID`) |
| **Natural key** | `shop_id` (15-char varchar) |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__shop` → `dim_shop` |

**Important columns:**
- `shop_config_id` (PK)
- `shop_id` — natural key for the shop
- `location_code` — geographic identifier
- `order_type` — currently `1` for all rows (single value observed)

---

### 3. `stg_repairlink__shopusermapper`

| | |
|---|---|
| **Source table** | `SHOPUSERMAPPER` |
| **Why we added it** | Maps Snowflake users to external shop user IDs. Useful for joining users to shops. |
| **Row count** | 45 active records |
| **Primary key** | `shop_user_mapper_id` (from source `ID`) |
| **Materialization** | `incremental` |
| **Downstream** | Staging-only (no dim — this is a bridge/mapping table) |

**Important columns:**
- `shop_user_mapper_id` (PK)
- `user_id` — internal user identifier
- `external_id` — external system's user ID

---

### 4. `stg_repairlink__dealer_mapper`

| | |
|---|---|
| **Source table** | `DEALER_MAPPER` |
| **Why we added it** | Captures the dealer-to-dealer distance/connection network. Used to enrich `dim_dealer` with `connected_dealer_count`. |
| **Row count** | 2,999 active records |
| **Primary key** | `fivetran_id` (surrogate; source has no natural PK) |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__dealer` (aggregated) |

**Important columns:**
- `fivetran_id` (PK) — surrogate, source has no natural key
- `dealer_id` + `connected_dealer_id` — the directed pair
- `distance_km` — integer (NUMBER(18,0))
- `group_id` — clustering identifier
- `status` — currently `3` for all rows (enum meaning not documented)

**Data notes:**
- Source table lacks a natural PK; we use `_fivetran_id` as surrogate
- All records have `status = 3` — investigate enum if more values appear later

---

### 5. `stg_repairlink__suppliermapper`

| | |
|---|---|
| **Source table** | `SUPPLIERMAPPER` |
| **Why we added it** | Maps seller organisation keys (`001-XXX-XXX` format) to supplier numbers. Useful for supplier-side analysis. |
| **Row count** | 111 active records |
| **Primary key** | `supplier_mapper_id` (from source `ID`) |
| **Materialization** | `incremental` |
| **Downstream** | Staging-only (no dim yet) |

**Important columns:**
- `supplier_mapper_id` (PK)
- `seller_org_key` — format `001-XXX-XXX`
- `supplier_number` — integer; **NOT unique** (multiple seller_org_keys can map to the same supplier)

**Data notes:**
- `supplier_number` is non-unique (e.g. `24499` appears for IDs 16 and 17; `23282` for IDs 36–39)
- Source table has no audit columns (no `created_by`, `created_at`, etc.)

---

### 6. `stg_repairlink__dealeroemenrollment`

| | |
|---|---|
| **Source table** | `DEALEROEMENROLLMENT` |
| **Why we added it** | Tracks which OEMs each dealer is enrolled with. Enriches `dim_dealer` with OEM relationship counts. |
| **Row count** | 8,481 active records |
| **Primary key** | `dealer_oem_enrollment_id` (from source `ID`) |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__dealer` (aggregated) |

**Important columns:**
- `dealer_oem_enrollment_id` (PK)
- `dealer_id` — FK to dealer
- `oem_id` — FK to manufacturer (maps to `manufacturer_id` in `stg_repairlink__manufacturer`)
- `oem_name` — **denormalised**; same `oem_id` can have different name values
- `is_active` — boolean enrollment status
- `created_at` / `updated_at` — UTC timestamps

**Data notes:**
- `oem_name` denormalisation: `oem_id=1` appears as both `'Chrysler'` and `'DCX'`; `oem_id=3` as `'General Motors'` and `'GM'`
- Top OEMs by enrollment count: GM (1,590), Ford (1,424), Chrysler (1,023)
- Use `stg_repairlink__manufacturer` for canonical OEM names — don't rely on `oem_name` here

---

### 7. `stg_repairlink__manufacturer`

| | |
|---|---|
| **Source table** | `MASTER_ENT_MANUFACTURER` |
| **Why we added it** | Reference table of manufacturers (vehicle OEMs, tire brands, commercial trucks). Base for `dim_manufacturer`. |
| **Row count** | 78 active records |
| **Primary key** | `manufacturer_id` (from source `MANUFACTURERID`) |
| **Business key** | `manufacturer_key` |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__manufacturer` → `dim_manufacturer` |

**Important columns:**
- `manufacturer_id` (PK)
- `manufacturer_name_long` — full name (e.g. 'Ford Motor Company')
- `manufacturer_name_short` — short name (e.g. 'Ford')
- `abbreviation` — e.g. 'GM', 'DCX'
- `manufacturer_key` — unique business key (often same as abbreviation)
- `industry_id` — `1` = Automotive OEM, `4` = Construction, `5` = Commercial Trucks
- `org_key` — sparsely populated (only GM, Hyundai, etc.)
- `is_phoenix_published_inv` — true for major OEMs publishing inventory in Phoenix

**Data notes:**
- `manufacturer_id = 0 / 'Unknown'` is a sentinel record — excluded in intermediate
- Mix of vehicle OEMs (Ford, GM, Toyota), tire brands (Michelin, Goodyear), and truck makers (Navistar, Daimler Truck)

---

### 8. `stg_repairlink__countrymaster`

| | |
|---|---|
| **Source table** | `COUNTRYMASTER` |
| **Why we added it** | ISO country reference. Base for `dim_country`. Used to decode country IDs across other tables. |
| **Row count** | 240 active records |
| **Primary key** | `country_id` (from source `COUNTRYID`; this **is** the ISO 3166-1 numeric code) |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__country` → `dim_country` |

**Important columns:**
- `country_id` (PK / ISO numeric code, e.g. `840` = USA, `826` = GBR)
- `country_name` — full formal name (e.g. `'Albania, People's Socialist Republic of'`)
- `two_letter_iso_code` — ISO 3166-1 alpha-2 (e.g. `US`, `GB`)
- `three_letter_iso_code` — ISO 3166-1 alpha-3 (e.g. `USA`, `GBR`)

**Data notes:**
- `country_id = 0 / 'Unknown'` is a sentinel — excluded in intermediate
- Country names use formal designations and may include commas

---

### 9. `stg_repairlink__currencymaster`

| | |
|---|---|
| **Source table** | `CURRENCYMASTER` |
| **Why we added it** | ISO currency reference. Base for `dim_currency`. |
| **Row count** | 165 active records |
| **Primary key** | `currency_id` (from source `CURRENCYID`; this **is** the ISO 4217 numeric code) |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__currency` → `dim_currency` |

**Important columns:**
- `currency_id` (PK / ISO numeric code, e.g. `840` = USD, `978` = EUR, `826` = GBP)
- `currency_name` — full name (e.g. `'US Dollar'`)
- `currency_code` — ISO 4217 alpha-3 (e.g. `USD`, `EUR`)

**Data notes:**
- `currency_id = 0 / 'Unknown'` is a sentinel — excluded in intermediate
- Includes historical/deprecated currencies (e.g. `EEK` Estonian Kroon, `SKK` Slovak Koruna)

---

### 10. `stg_repairlink__vehicle`

| | |
|---|---|
| **Source table** | `TRANSACTION_ENT_VEHICLE` |
| **Why we added it** | Vehicle entity per transaction. Base for `dim_vehicle` (deduplicated by VIN in intermediate). |
| **Row count** | 5,617,883 active records |
| **Primary key** | `vehicle_id` (from source `VEHICLEID`) |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__vehicle` (dedup by VIN) → `dim_vehicle` |

**Important columns:**
- `vehicle_id` (PK)
- `transaction_id` / `document_id` — FKs (nullable; transactional in nature)
- `vin` — VIN (~92% populated)
- `vehicle_year` — model year (always populated; `0` = unknown sentinel; up to 2027 for new model years)
- `vehicle_make` — brand (always populated, ~100%)
- `vehicle_model` — model name (~96% populated)
- `vehicle_type_id` — FK to vehicle type enum

**Data notes:**
- Transactional in nature — one row per transaction, NOT per physical vehicle
- `odometer_reading`, all `plate_*` fields, `vin_decoded_correctly` are **always null/false** in current data
- `vin_decoded_correctly` always false → no VIN decoding implemented yet
- Intermediate model deduplicates by VIN to produce one row per physical vehicle

---

### 11. `stg_repairlink__contact`

| | |
|---|---|
| **Source table** | `TRANSACTION_ENT_CONTACT` |
| **Why we added it** | Contact entity per transaction (buyer, seller, etc.). Base for `dim_contact`. |
| **Row count** | 57,747,230 active records |
| **Primary key** | `contact_id` (from source `CONTACTID`) |
| **Materialization** | `incremental` |
| **Downstream** | `int_repairlink__contact` (filtered) → `dim_contact` |

**Important columns:**
- `contact_id` (PK)
- `transaction_id` / `document_id` — FKs (both nullable)
- `contact_type_id` — FK to contact type enum (buyer, seller, etc.)
- `org_name` / `org_key` — organisation if contact represents a business
- Name fields split: `first_name`, `middle_name`, `last_name`, `last_name_2`, `name_suffix`, `nickname`, `name_title`
- Address fields: `address_line_1/2/3`, `city`, `state`, `postal_code`, `country_code`
- Geographic: `latitude`, `longitude`
- Contact: `email`, `phone_business`, `phone_mobile`, `phone_fax`, `website`

**Data notes:**
- **Highest volume table** in the project (57.7M rows)
- Transactional in nature — one row per transaction contact, not deduplicated by person
- `status_id = 1` for **all** records (no variability observed)
- `country_code` is text (e.g. `US`), not a FK to `country_id`
- Intermediate model filters to records with at least a name or org_name

---

## Standard column conventions

Across all staging models, the following columns follow a uniform pattern:

| Column | Type | Source pattern | Notes |
|---|---|---|---|
| `*_id` | integer | source camelCase (e.g. `id`, `dealertrialid`) | Primary or foreign key |
| `created_at` | timestamp_ntz | `createddate` or `createdonutc` | UTC |
| `updated_at` | timestamp_ntz | `updateddate` or `updatedonutc` | UTC |
| `created_by` | varchar | `createdby` | User who created the record |
| `updated_by` | varchar | `updatedby` | User who last updated |
| `ingested_at` | timestamp_tz | `_fivetran_synced` | Used as incremental high-water mark |

All staging models filter `where not _fivetran_deleted` to exclude soft-deleted source records.

---

## Tests defined

The staging layer has **64 tests** total (visible via `dbt list --resource-type test`):

- `not_null` + `unique` on every primary key
- `not_null` on all `ingested_at` columns
- `not_null` on critical foreign keys (e.g. `dealer_id`, `seller_org_key`)
- `not_null` + `unique` on business keys where applicable (e.g. `manufacturer_key`)

Run them with: `dbt test --select staging`

---

## Source table reference

The source `repairlink` is configured at:

```yaml
sources:
  - name: repairlink
    database: RAW
    schema: REPAIRLINK_SQLSERVER_DBO
```

All 11 source tables are declared in `models/staging/_repairlink__sources.yml`.
