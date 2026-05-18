# RepairLink Final (Marts) Models — Data Dictionary

**Jira epic:** [DAT-2215 — Identify DIM Tables](https://oeconnection.atlassian.net/browse/DAT-2215)
**Companion docs:** [`staging_data_dictionary.md`](./staging_data_dictionary.md), [`intermediate_data_dictionary.md`](./intermediate_data_dictionary.md)
**Strategy refs:** [Surrogate Key Strategy](https://oeconnection.atlassian.net/wiki/spaces/PDD/pages/1059684438/Surrogate+Key+Strategy), [Slowly Changing Dimension Strategy](https://oeconnection.atlassian.net/wiki/spaces/PDD/pages/1058177171/Slowly+Changing+Dimension+Strategy)
**Materialization:** `table` (full refresh)
**Schema:** `dbt_<user>_final` (per-developer in dev; production schema TBD)

---

## Overview

The final layer holds analyst-facing dimension tables. Each dim has:

- A **surrogate key** (`*_key`) — deterministic MD5 hash of the natural key, generated via `dbt_utils.generate_surrogate_key()`
- The **natural key** preserved (so joins from facts can still use the business identifier)
- One additional **"Unknown" row** with a stable surrogate key from the literal `'UNKNOWN'`, so late-arriving facts can `coalesce()` to a valid key instead of producing null joins

All 5 dims in this layer are **Type 1** (current state only). The SCD strategy doc recommends Type 2 for `dim_dealer` and `dim_shop` long-term — we deferred that to keep the first delivery simple and will revisit once historical-version requirements emerge.

### Architecture flow

```
INTERMEDIATE                           FINAL
────────────                           ─────
int_repairlink__dealer ─────────────► dim_dealer
int_repairlink__shop ───────────────► dim_shop
int_repairlink__manufacturer ───────► dim_manufacturer
int_repairlink__country ────────────► dim_country
int_repairlink__currency ───────────► dim_currency
int_repairlink__vehicle ────────────► dim_vehicle
                                       ❌ dim_contact (deferred — see end of doc)
```

---

## Surrogate key convention

| | Pattern |
|---|---|
| Surrogate column name | `<entity>_key` (e.g. `dealer_key`, `shop_key`) |
| Hash function | `dbt_utils.generate_surrogate_key([<natural_key>])` |
| Hash input — regular row | natural key column (e.g. `dealer_id`, `vin`, `country_id`) |
| Hash input — Unknown row | literal `'UNKNOWN'` |
| Resulting type | `VARCHAR(32)` (hexadecimal MD5) |

**Why hashing instead of sequences:** the marts are rebuilt via full refresh. Auto-incrementing keys would break every downstream foreign key on every rebuild. Hashing produces the same key for the same input forever.

**Fact table lookups:** future fact tables should `LEFT JOIN` to dims on the natural key, then `COALESCE` the surrogate key to the Unknown row's key when the join misses:

```sql
left join dim_dealer d on f.dealer_id = d.dealer_id
-- ...
coalesce(d.dealer_key, '<UNKNOWN hash>') as dealer_key
```

---

## Per-dim catalogue

### 1. `dim_dealer`

| | |
|---|---|
| **SCD type** | Type 1 (current state only) |
| **Source** | `int_repairlink__dealer` |
| **Natural key** | `dealer_id` |
| **Surrogate key** | `dealer_key` = MD5(`dealer_id`) |
| **Expected row count** | 18 dealer rows + 1 Unknown row = 19 |

**Columns kept:** `dealer_key`, `dealer_id`, `dealer_trial_id`, `total_oem_enrollment_count`, `active_oem_enrollment_count`, `trial_started_at`, `trial_ended_at`, `created_at`, `updated_at`, `ingested_at`

**Columns intentionally dropped:**
- `status_id` — only one distinct value (1) in dev data; no analytical signal
- `connected_dealer_count` — always 0 in dev (dealertrial population doesn't overlap with dealer_mapper population); revisit once live data is flowing

---

### 2. `dim_shop`

| | |
|---|---|
| **SCD type** | Type 1 |
| **Source** | `int_repairlink__shop` |
| **Natural key** | `shop_id` |
| **Surrogate key** | `shop_key` = MD5(`shop_id`) |
| **Expected row count** | 15 shop rows + 1 Unknown row = 16 |

**Columns kept:** `shop_key`, `shop_id`, `location_code`, `order_type`, `created_at`, `updated_at`

**Columns intentionally dropped:**
- `created_by`, `updated_by` — only one distinct value in dev data (single operator)
- `ingested_at` — no analytical value at the dim level

**Note on `order_type`:** kept in the projection but always = 1 in dev data. Will become useful once production order types diversify.

---

### 3. `dim_manufacturer`

| | |
|---|---|
| **SCD type** | Type 1 |
| **Source** | `int_repairlink__manufacturer` (sentinel id=0 excluded upstream) |
| **Natural key** | `manufacturer_id` |
| **Surrogate key** | `manufacturer_key` = MD5(`manufacturer_id`) |
| **Expected row count** | 77 manufacturers + 1 Unknown = 78 |

**Important column note:** the source has a column also called `manufacturer_key` (a text business key like `'GM'`, `'DCX'`). To avoid clashing with the surrogate key name, that column is renamed in the dim to `manufacturer_business_key`.

**Industry segments** in `industry_id`:
- 1 = Automotive OEM
- 4 = Construction / Heavy Equipment
- 5 = Commercial Trucks

---

### 4. `dim_country`

| | |
|---|---|
| **SCD type** | Type 1 |
| **Source** | `int_repairlink__country` (sentinel id=0 excluded upstream) |
| **Natural key** | `country_id` (this **is** the ISO 3166-1 numeric code, not an arbitrary internal ID) |
| **Surrogate key** | `country_key` = MD5(`country_id`) |
| **Expected row count** | 239 countries + 1 Unknown = 240 |

**Unknown row defaults:** `two_letter_iso_code = 'XX'`, `three_letter_iso_code = 'XXX'`, `country_name = 'Unknown'`.

Notable use: `int_repairlink__contact.country_code` (text, alpha-2) joins to `dim_country.two_letter_iso_code`, **not** to the numeric `country_id`.

---

### 5. `dim_currency`

| | |
|---|---|
| **SCD type** | Type 1 |
| **Source** | `int_repairlink__currency` (sentinel id=0 excluded upstream) |
| **Natural key** | `currency_id` (this **is** the ISO 4217 numeric code) |
| **Surrogate key** | `currency_key` = MD5(`currency_id`) |
| **Expected row count** | 164 currencies + 1 Unknown = 165 |

⚠️ **Important caveat:** `currency_name` is **NOT unique**. The name `'Kwacha'` refers to **two distinct currencies**:
- MWK — Malawian Kwacha
- ZMK — Zambian Kwacha

This is a legitimate real-world overlap, not a data quality issue. **Always join on `currency_code` (ISO 4217 alpha-3) which IS unique. Never use `currency_name` as a join key.**

---

### 6. `dim_vehicle`

| | |
|---|---|
| **SCD type** | Type 1 (per SCD strategy — VIN attributes are immutable, only corrections expected) |
| **Source** | `int_repairlink__vehicle` (deduplicated by VIN upstream) |
| **Natural key** | `vin` |
| **Surrogate key** | `vehicle_key` = MD5(`vin`) |
| **Expected row count** | ~3.35M vehicles + 1 Unknown |

**VIN intelligence enrichment:** the dim carries both the RepairLink-source values (`vehicle_make`, `vehicle_model`) and the canonical values from the VIN intelligence dataset (`vehicle_make_vintelligence`, `vehicle_model_vintelligence`). Long-term, BI will switch to the vintelligence variants once enrichment coverage is confirmed.

**Columns kept:** `vehicle_key`, `vin`, `vehicle_id`, `transaction_id`, `vehicle_type_id`, `status_id`, `vehicle_year`, `vehicle_make`, `vehicle_model`, `vehicle_make_vintelligence`, `vehicle_model_vintelligence`, `vin_vintelligence`, `vin_decoded_correctly`, `created_at`, `updated_at`, `ingested_at`

**Columns intentionally dropped:**
- `odometer_reading`, all `plate_*`, `auto_pickup_at`, `auto_dropoff_at` — 100% null in dev
- `document_id`, `owner_id`, `vin_source`, `body_trim_code`, `paint_exterior_color_code` — 100% null in dev
- `vin_suffix_vehicle`, `vin_suffix_vintelligence` — testing only, will be removed from the intermediate model

**Single-value caveats** (still in the dim):
- `vehicle_type_id` always = 103 in dev
- `status_id` always = 1 in dev
- `vin_decoded_correctly` always = false in dev

---

## ❌ `dim_contact` — deferred

`dim_contact` was considered but **not built in this delivery**. The reasoning:

- `int_repairlink__contact` has 57.7M rows that are **transactional in nature** (one row per transaction contact, the same person/org appears N times)
- It carries `transaction_id` and `document_id` — fact-table signals, not dimension signals
- Person identity resolution (merging duplicate "Bob Smith" rows correctly) is its own project and requires business rules we don't yet have

**Future direction:** when the first transaction fact (`fct_transaction` / `fct_document`) is built, we'll decide whether to:
- Build a slim `dim_contact` after identity resolution + a `fct_transaction_contact` bridge, or
- Keep contact attributes denormalised on the fact tables

If a `dim_contact` becomes urgent before identity resolution lands, the fallback is a thin Type 1 with `contact_id` as the natural key (one dim row per source row, ~57M).

---

## Counts to validate after first build

Run this in Snowflake after `dbt build --select final+`:

```sql
USE DATABASE <your_dev_db>;
USE SCHEMA dbt_<user>_final;

SELECT 'dim_dealer'        AS model, count(*) AS rows FROM dim_dealer
UNION ALL SELECT 'dim_shop',                    count(*) FROM dim_shop
UNION ALL SELECT 'dim_manufacturer',            count(*) FROM dim_manufacturer
UNION ALL SELECT 'dim_country',                 count(*) FROM dim_country
UNION ALL SELECT 'dim_currency',                count(*) FROM dim_currency
UNION ALL SELECT 'dim_vehicle',                 count(*) FROM dim_vehicle
ORDER BY rows DESC;
```

Expected:
- `dim_dealer`: 19 (18 + Unknown)
- `dim_shop`: 16 (15 + Unknown)
- `dim_manufacturer`: 78 (77 + Unknown)
- `dim_country`: 240 (239 + Unknown)
- `dim_currency`: 165 (164 + Unknown)
- `dim_vehicle`: ~3.35M + Unknown

---

## Tests

Each dim has at minimum:
- `not_null` + `unique` on the surrogate `*_key`
- `not_null` on the natural key (so the Unknown row's literal `'UNKNOWN'` value still passes)

Run with:
```bash
dbt test --select final
```

---

## Looking ahead

1. **SCD Type 2 for dim_dealer and dim_shop** — once history requirements emerge (shop renames, dealer status changes), introduce `snapshots/snp_dealer.sql` and `snapshots/snp_shop.sql` and re-key the surrogates as MD5(`<natural_key>`, `dbt_valid_from`).
2. **`dim_contact`** — will be revisited when the first transaction fact is built.
3. **Vehicle make/model normalization** — once VIN intelligence coverage is verified, switch BI to use `vehicle_make_vintelligence` and drop the original-RepairLink columns.
4. **Production schemas** — current dev config writes to `dbt_<user>_final`. Production should map to a stable `FINAL` schema (or per-environment overrides).
