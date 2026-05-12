# RepairLink Intermediate Models — Data Dictionary

**Jira epic:** [DAT-2215 — Identify DIM Tables](https://oeconnection.atlassian.net/browse/DAT-2215)
**Companion doc:** [`staging_data_dictionary.md`](./staging_data_dictionary.md)
**Layer purpose:** Take the staged source data and turn it into clean, analysis-ready entities — one row per business entity, joined with relevant enrichment, filtered for data quality. Intermediate models are the bridge between raw-shaped staging and the analyst-shaped marts.

---

## Overview

The intermediate layer has three jobs:

1. **Deduplicate** — turn transactional rows into one row per business entity (e.g. one row per VIN, one row per dealer)
2. **Enrich** — pre-join related staging data so marts don't have to repeat the work (e.g. attach OEM enrollment counts to each dealer)
3. **Filter** — exclude sentinel records and rows that fail basic data-quality checks (e.g. drop the `id=0 / 'Unknown'` rows; drop vehicles with no VIN)

All intermediate models are materialized as **`table`** (full refresh on every run, in `dbt_<user>_intermediate`).

### Architecture flow

```
STAGING                                 INTERMEDIATE                            MARTS
────────                                ────────────                            ─────
stg_repairlink__dealertrial         ┐
stg_repairlink__dealeroemenrollment ├── int_repairlink__dealer ──────────► dim_dealer
stg_repairlink__dealer_mapper       ┘

stg_repairlink__shopconfig          ─── int_repairlink__shop ────────────► dim_shop

stg_repairlink__manufacturer        ─── int_repairlink__manufacturer ────► dim_manufacturer
stg_repairlink__countrymaster       ─── int_repairlink__country ─────────► dim_country
stg_repairlink__currencymaster      ─── int_repairlink__currency ────────► dim_currency

stg_repairlink__vehicle             ─── int_repairlink__vehicle (dedup by VIN) ──► dim_vehicle
stg_repairlink__contact             ─── int_repairlink__contact (filtered) ─────► dim_contact
```

---

## Cross-model relationships

| FK | From | To |
|---|---|---|
| `dealer_id` | `int_repairlink__dealer` | (natural key — links to dealer-related facts and staging mappers) |
| `oem_id` | aggregated inside `int_repairlink__dealer` | `int_repairlink__manufacturer.manufacturer_id` |
| `connected_dealer_id` (in source dealer_mapper) | `int_repairlink__dealer` | itself (self-relationship for dealer network) |
| `shop_id` | `int_repairlink__shop` | (natural key — links to shop-related facts) |
| `transaction_id`, `document_id` | `int_repairlink__vehicle`, `int_repairlink__contact` | (link to a future `fct_transaction` / `fct_document`, currently only in source) |
| `country_code` (text) | `int_repairlink__contact` | `int_repairlink__country.two_letter_iso_code` (NOT a numeric FK) |
| `vehicle_type_id` | `int_repairlink__vehicle` | enum (`TRANSACTION_ENU_VEHICLETYPE` — not yet staged) |
| `contact_type_id` | `int_repairlink__contact` | enum (`TRANSACTION_ENU_CONTACTTYPE` — not yet staged) |

Note: cross-intermediate joins should use the natural key (`dealer_id`, `shop_id`, `manufacturer_id`, etc.), not the eventual mart surrogate keys. Surrogate keys are mart-only.

---

## Intermediate model catalogue

### 1. `int_repairlink__dealer`

| | |
|---|---|
| **Source models** | `stg_repairlink__dealertrial` (base), `stg_repairlink__dealeroemenrollment` (agg), `stg_repairlink__dealer_mapper` (agg) |
| **Purpose** | One row per dealer with the most recent trial state, plus pre-computed enrichment metrics so `dim_dealer` doesn't repeat the joins |
| **Materialization** | `table` |
| **Primary key** | `dealer_id` (natural key, varchar 15) |
| **Logic** | (1) Dedup `dealertrial` by `dealer_id` keeping the latest by `updated_at` <br> (2) Aggregate `dealeroemenrollment` to count `total_oem_enrollment_count` and `active_oem_enrollment_count` per dealer <br> (3) Aggregate `dealer_mapper` to count `connected_dealer_count` per dealer <br> (4) `LEFT JOIN` aggregates onto deduplicated dealers; `coalesce(..., 0)` for dealers with no enrollments/connections |
| **Expected row count** | ≤ 18 (one per dealer that ever had a trial) |
| **Downstream** | `dim_dealer` |

**Important columns:**

| Column | Type | Notes |
|---|---|---|
| `dealer_id` | varchar | PK; natural key |
| `dealer_trial_id` | integer | Source PK from latest trial record |
| `status_id` | integer | Trial status; all current rows = 1 |
| `trial_started_at` | timestamp_ntz | UTC; required (not_null) |
| `trial_ended_at` | timestamp_ntz | UTC; null = trial still active |
| `total_oem_enrollment_count` | integer | All enrollments (active + inactive); 0 for dealers with none |
| `active_oem_enrollment_count` | integer | Currently active OEM enrollments only |
| `connected_dealer_count` | integer | Dealers reachable via the distance network |
| `created_at`, `updated_at`, `ingested_at` | timestamps | Source audit + Fivetran watermark |

**Caveats:**
- `LEFT JOIN` for enrichments — a dealer with no OEM enrollment or no neighbours appears with `0` counts, never null
- The "latest trial" dedup means if a dealer ever had multiple trials, only the most-recently-updated one survives — historical trials are lost (acceptable for Type 1 Marts; if Type 2 is needed, source from snapshots instead)

---

### 2. `int_repairlink__shop`

| | |
|---|---|
| **Source model** | `stg_repairlink__shopconfig` |
| **Purpose** | One row per shop with the latest config record |
| **Materialization** | `table` |
| **Primary key** | `shop_id` (natural key, varchar 15) |
| **Logic** | Dedup `shopconfig` by `shop_id` keeping the latest by `updated_at` |
| **Expected row count** | ≤ 15 |
| **Downstream** | `dim_shop` |

**Important columns:**

| Column | Type | Notes |
|---|---|---|
| `shop_config_id` | integer | Source PK from latest config |
| `shop_id` | varchar | Natural key (PK of this model) |
| `location_code` | varchar | Location identifier |
| `order_type` | integer | All current rows = 1 |
| `created_by`, `updated_by` | varchar | Audit |
| `created_at`, `updated_at`, `ingested_at` | timestamps | Audit + watermark |

**Caveats:**
- Pure passthrough + dedup. No enrichment yet — `shopusermapper` is staging-only and not joined here (kept as a future bridge if needed)

---

### 3. `int_repairlink__manufacturer`

| | |
|---|---|
| **Source model** | `stg_repairlink__manufacturer` |
| **Purpose** | Clean manufacturer reference excluding the sentinel `Unknown` row |
| **Materialization** | `table` |
| **Primary key** | `manufacturer_id` (integer) |
| **Business key** | `manufacturer_key` (unique varchar) |
| **Logic** | `select * where manufacturer_id != 0` |
| **Expected row count** | 77 (78 staging rows – 1 sentinel) |
| **Downstream** | `dim_manufacturer` |

**Important columns:**

| Column | Type | Notes |
|---|---|---|
| `manufacturer_id` | integer | PK |
| `manufacturer_name_long` | varchar | e.g. "Ford Motor Company" |
| `manufacturer_name_short` | varchar | e.g. "Ford" |
| `abbreviation` | varchar | e.g. "GM", "DCX" |
| `manufacturer_key` | varchar | Unique business key (often = abbreviation) |
| `org_key` | varchar | Sparsely populated |
| `industry_id` | integer | 1 = Auto OEM, 4 = Construction, 5 = Commercial Trucks |
| `is_phoenix_published_inv` | boolean | Phoenix inventory flag |

---

### 4. `int_repairlink__country`

| | |
|---|---|
| **Source model** | `stg_repairlink__countrymaster` |
| **Purpose** | Clean country reference excluding the sentinel `Unknown` row |
| **Materialization** | `table` |
| **Primary key** | `country_id` (integer; ISO 3166-1 numeric code) |
| **Logic** | `select * where country_id != 0` |
| **Expected row count** | 239 (240 staging rows – 1 sentinel) |
| **Downstream** | `dim_country` |

**Important columns:**

| Column | Type | Notes |
|---|---|---|
| `country_id` | integer | PK; ISO 3166-1 numeric (e.g. 840 = USA) |
| `country_name` | varchar | Full formal name |
| `two_letter_iso_code` | varchar | ISO alpha-2 (e.g. US, GB) |
| `three_letter_iso_code` | varchar | ISO alpha-3 (e.g. USA, GBR) |

**Note:** `int_repairlink__contact.country_code` matches `two_letter_iso_code` here — it's a text-based lookup, not a numeric FK.

---

### 5. `int_repairlink__currency`

| | |
|---|---|
| **Source model** | `stg_repairlink__currencymaster` |
| **Purpose** | Clean currency reference excluding the sentinel `Unknown` row |
| **Materialization** | `table` |
| **Primary key** | `currency_id` (integer; ISO 4217 numeric code) |
| **Logic** | `select * where currency_id != 0` |
| **Expected row count** | 164 (165 staging rows – 1 sentinel) |
| **Downstream** | `dim_currency` |

**Important columns:**

| Column | Type | Notes |
|---|---|---|
| `currency_id` | integer | PK; ISO 4217 numeric (e.g. 840 = USD, 978 = EUR) |
| `currency_name` | varchar | Full name |
| `currency_code` | varchar | ISO 4217 alpha-3 (e.g. USD, EUR) |

---

### 6. `int_repairlink__vehicle`

| | |
|---|---|
| **Source model** | `stg_repairlink__vehicle` |
| **Purpose** | One row per **physical vehicle** (deduplicated by VIN) with the most recent transaction's data |
| **Materialization** | `table` |
| **Primary key** | `vehicle_id` (integer; PK from the latest source row, unique after dedup) |
| **Business key** | `vin` (varchar; also unique after dedup) |
| **Logic** | (1) Filter `where vin is not null and vehicle_year != 0` (drops ~8% null-VIN rows + sentinel year=0 rows) <br> (2) Dedup by VIN keeping the latest by `updated_at desc nulls last` |
| **Expected row count** | Significantly less than 5.6M staging rows — collapses transactional duplicates per VIN. **First build will reveal the actual count; expect roughly 1–3M unique VINs based on industry patterns.** |
| **Downstream** | `dim_vehicle` |

**Important columns:**

| Column | Type | Notes |
|---|---|---|
| `vehicle_id` | integer | PK (latest source row's ID for this VIN) |
| `vin` | varchar | Business key, unique after dedup, always populated |
| `transaction_id` | integer | Most recent transaction this vehicle appeared in (nullable upstream but should be populated for the latest record) |
| `vehicle_year` | integer | Always populated; ranges 1–2027 (year=0 excluded upstream) |
| `vehicle_make` | varchar | Always populated |
| `vehicle_model` | varchar | ~96% populated |
| `vehicle_type_id` | integer | FK to vehicle type enum (not yet staged) |
| `body_trim_code`, `paint_exterior_color_code` | varchar | Optional |

**Caveats:**
- Plate fields (`plate_number`, `plate_state_province`, etc.) and `odometer_reading` are excluded from the column projection — they're 100% null in current source data
- `vin_decoded_correctly` always false in source — keeping it but marked as low-signal
- The "latest" timestamp can be ambiguous if two transactions for the same VIN have identical `updated_at` — `nulls last` handles null timestamps but ties default to dbt's row order

---

### 7. `int_repairlink__contact`

| | |
|---|---|
| **Source model** | `stg_repairlink__contact` |
| **Purpose** | Filter contacts to those with at least a name or org_name (drops orphaned/blank rows). NOT deduplicated — `contact_id` is already unique per source row |
| **Materialization** | `table` |
| **Primary key** | `contact_id` (integer) |
| **Logic** | `where first_name is not null or last_name is not null or org_name is not null` <br> Plus a column projection that drops audit/comment fields and the always-`status_id=1` field to keep the model lean |
| **Expected row count** | Filter rate is unknown until first build — based on staging's 57.7M, expect to drop a small percentage that have neither person nor org name |
| **Downstream** | `dim_contact` |

**Important columns:**

| Column | Type | Notes |
|---|---|---|
| `contact_id` | integer | PK |
| `transaction_id` | integer | Nullable FK to (future) `fct_transaction` |
| `document_id` | integer | Nullable FK to (future) `fct_document` |
| `contact_type_id` | integer | FK to contact type enum (not yet staged) |
| `org_name`, `org_key` | varchar | Organisation context (when contact represents a business) |
| `first_name`, `last_name`, `last_name_2`, `middle_name`, `name_title`, `name_suffix`, `nickname` | varchar | Person name fields |
| `email`, `phone_business`, `phone_mobile`, `phone_fax`, `website` | varchar | Communication channels |
| `address_line_1/2/3`, `city`, `state`, `postal_code`, `country_code` | varchar | Address (`country_code` is the ISO alpha-2, not a numeric FK) |
| `latitude`, `longitude` | float | Geographic coordinates |
| `locale_code` | varchar | i18n locale |

**Caveats:**
- High volume (~57M rows) — full-table refresh on every `dbt run` is expensive. Worth re-evaluating materialization (incremental or `merge`) once the marts are stable
- Truly transactional in nature — multiple "Bob Smith" rows can exist if the same person appears across many transactions. **Person identity resolution is a separate concern not handled in this layer.**
- `status_id` (always 1) and `comment` (free-text noise) are intentionally dropped from the projection

---

## Standard column conventions

| Column | Behaviour |
|---|---|
| `*_id` | Natural key from staging (carries through unchanged) |
| `created_at`, `updated_at` | Source audit timestamps; intermediate keeps the latest version's |
| `ingested_at` | Fivetran watermark from the surviving (latest) row after dedup |
| `_fivetran_id`, `_fivetran_deleted` | Always dropped (handled at staging) |

Surrogate keys (`*_key` MD5 hashes per the [Surrogate Key Strategy](https://oeconnection.atlassian.net/wiki/spaces/PDD/pages/1059684438/Surrogate+Key+Strategy)) are **not generated here** — they're added at the marts layer.

---

## Tests defined

The intermediate layer's tests can be listed via:

```bash
dbt list --resource-type test --select intermediate
```

Each model has at minimum:
- `not_null` + `unique` on the primary key
- `not_null` on critical FKs and natural keys (e.g. `int_repairlink__manufacturer.manufacturer_key`)
- `not_null` on `vin` (since it's the business key for `int_repairlink__vehicle` after the filter)

---

## Counts to validate after first build

After running `dbt build --select intermediate`, run these in Snowflake against your dev schema (`dbt_<user>_intermediate`) to validate the row counts match the doc's expectations. Replace `<user>` with your dbt Cloud user.

```sql
USE DATABASE <your_dev_db>;
USE SCHEMA dbt_<user>_intermediate;

SELECT 'int_repairlink__dealer'         AS model, count(*) AS rows FROM int_repairlink__dealer
UNION ALL SELECT 'int_repairlink__shop',                    count(*) FROM int_repairlink__shop
UNION ALL SELECT 'int_repairlink__manufacturer',            count(*) FROM int_repairlink__manufacturer
UNION ALL SELECT 'int_repairlink__country',                 count(*) FROM int_repairlink__country
UNION ALL SELECT 'int_repairlink__currency',                count(*) FROM int_repairlink__currency
UNION ALL SELECT 'int_repairlink__vehicle',                 count(*) FROM int_repairlink__vehicle
UNION ALL SELECT 'int_repairlink__contact',                 count(*) FROM int_repairlink__contact
ORDER BY rows DESC;
```

Expected:
- `int_repairlink__manufacturer`: **77**
- `int_repairlink__country`: **239**
- `int_repairlink__currency`: **164**
- `int_repairlink__shop`: **≤ 15**
- `int_repairlink__dealer`: **≤ 18**
- `int_repairlink__vehicle`: **<< 5.6M** (TBD — fill in after first run)
- `int_repairlink__contact`: **≈ 57M** (TBD — fill in after first run)

---

## Looking ahead — SCD impact

Per the [Slowly Changing Dimension Strategy](https://oeconnection.atlassian.net/wiki/spaces/PDD/pages/1058177171/Slowly+Changing+Dimension+Strategy):

- **`int_repairlink__dealer` and `int_repairlink__shop`** will likely become Type 2 dimensions in marts. When that happens, a `snapshots/snp_dealer.sql` and `snapshots/snp_shop.sql` will sit between intermediate and marts to capture historical versions. The intermediate models themselves stay the same — they always represent the current state.

- **`int_repairlink__vehicle`, `int_repairlink__manufacturer`, `int_repairlink__country`, `int_repairlink__currency`, `int_repairlink__contact`** — Type 1 dimensions, no snapshots needed. Vehicle attributes are immutable per VIN; reference tables effectively never change meaningfully.
