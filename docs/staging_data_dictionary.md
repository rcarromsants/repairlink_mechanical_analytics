# RepairLink Staging Models — Data Dictionary

**Jira epic:** [DAT-2215 — Identify DIM Tables](https://oeconnection.atlassian.net/browse/DAT-2215)
**Source database / schema:** `RAW.REPAIRLINK_SQLSERVER_DBO`
**Ingestion:** Fivetran from RepairLink SQL Server 
!! (except for `transaction_enu_contact`, for no particular reason — we agreed to review whether it would make sense to keep this incremental method in the future or if we could switch to a view without this parameter) !!
**Last data validation:** 2026-05-26

---

## Overview

This document describes every source table currently staged in the `repairlink_mechanical_analytics` dbt project, why it was added, what's in it, and how it flows downstream into the dimensional model.

The goal of the epic is to identify and model the relevant dim tables → shops, dealers, users, locations, and related entities. Every staging model below was selected from the **133 tables** in `RAW.REPAIRLINK_SQLSERVER_DBO` based on:

1. Whether it represents a **business entity** worth dimensioning, or
2. Whether it provides **enrichment data** for an existing dimension, or
3. Whether it is a **reference / lookup** that decodes IDs into meaningful labels.

Tables that are operational, audit, log, or cross-reference (`*_AUD_*`, `*_HST_*`, `*_LOG_*`, `*_XRF_*`, `INTEGRATION_OUTBOX_*`, etc.) were intentionally excluded — they don't add analytical value at the dim layer.


Current Staging Models

stg_repairlink__contact	Transactional organizational contact source data
stg_repairlink__dealertrial	Dealer lifecycle and trial records
stg_repairlink__dealer_mapper	Dealer-to-dealer distance/proximity mappings
stg_repairlink__dealeroemenrollment	Dealer OEM enrollment relationships
stg_repairlink__shopconfig	Shop configuration and operational metadata
stg_repairlink__manufacturer	Manufacturer source reference data
stg_repairlink__countrymaster	Country source lookup data
stg_repairlink__currencymaster	Currency source lookup data
stg_repairlink__vehicle	Vehicle transaction entities
stg_repairlink__transaction_enu_contacttype	Contact type enumeration lookup
stg_repairlink__suppliermapper	Supplier mapping relationships
stg_repairlink__shopusermapper	Shop/user mapping relationships

## Architecture Flow
STAGING
   │
   ├── stg_repairlink__contact ───────────────► int_repairlink__contact
   │
   ├── stg_repairlink__dealertrial ──────────┐
   ├── stg_repairlink__dealer_mapper ────────┼──► int_repairlink__dealer
   ├── stg_repairlink__dealeroemenrollment ──┘
   │
   ├── stg_repairlink__shopconfig ───────────► int_repairlink__shop
   ├── stg_repairlink__manufacturer ─────────► int_repairlink__manufacturer
   ├── stg_repairlink__vehicle ──────────────► int_repairlink__vehicle
   │
   ├── stg_repairlink__countrymaster ────────► ref_repairlink__country
   ├── stg_repairlink__currencymaster ───────► ref_repairlink__currency
   │
   ├── stg_repairlink__transaction_enu_contacttype
   │                                              └──► ref_repairlink__contact_type
   │
   └── stg_repairlink__dealeroemenrollment ───► ref_repairlink__oem

## Model Catalogue
### stg_repairlink__contact
	
Source table	TRANSACTION_ENT_CONTACT
Grain	One row per transactional contact record
Purpose	Organizational and contact source data used for enrichment
Notes

This model acts as the base source for organizational enrichment logic later implemented in:

int_repairlink__contact
int_repairlink__dealer
int_repairlink__shop

The source includes dealer, shop, and potentially supplier/manufacturer-related contacts.

### stg_repairlink__dealertrial
	
Source table	DEALERTRIAL
Grain	One row per dealer trial record
Purpose	Dealer lifecycle and trial-status source data
Notes

Used downstream by:

int_repairlink__dealer
dim_dealer_trial

Dealer IDs in this source use the longer source-system identifier format and are normalized downstream to the canonical 11-character dealer ID where needed.

### stg_repairlink__dealer_mapper
	
Source table	DEALER_MAPPER
Grain	One row per dealer relationship pair
Purpose	Dealer-to-dealer distance/proximity mappings
Notes

Used downstream by:

int_repairlink__dealer
bridge_dealer_distance

This dataset represents a many-to-many dealer relationship network.

### stg_repairlink__dealeroemenrollment
	
Source table	DEALEROEMENROLLMENT
Grain	One row per dealer OEM enrollment
Purpose	Dealer OEM relationship source data
Notes

Used downstream by:

int_repairlink__dealer
ref_repairlink__oem
bridge_dealer_oem

This source is also used to derive OEM normalization logic.

### stg_repairlink__shopconfig
	
Source table	SHOPCONFIG
Grain	One row per shop
Purpose	Shop operational configuration data
Notes

Used downstream by:

int_repairlink__shop
dim_shop

Shop identifiers use the canonical 11-character business identifier format.

### stg_repairlink__manufacturer
	
Source table	MASTER_ENT_MANUFACTURER
Grain	One row per manufacturer
Purpose	Manufacturer operational source dataset
Notes

Used downstream by:

int_repairlink__manufacturer
dim_manufacturer

Contains operational manufacturer metadata and enrichment attributes.

### stg_repairlink__countrymaster
	
Source table	COUNTRYMASTER
Grain	One row per country
Purpose	Country lookup source data
Notes

Used downstream by:

ref_repairlink__country

Contains ISO country reference information.

### stg_repairlink__currencymaster
	
Source table	CURRENCYMASTER
Grain	One row per currency
Purpose	Currency lookup source data
Notes

Used downstream by:

ref_repairlink__currency

Contains ISO currency reference information.

### stg_repairlink__vehicle
	
Source table	TRANSACTION_ENT_VEHICLE
Grain	One row per transactional vehicle entity
Purpose	Vehicle transaction source data
Notes

Used downstream by:

int_repairlink__vehicle
dim_vehicle

This source contains VINs and vehicle metadata later enriched with VIN intelligence data.

### stg_repairlink__transaction_enu_contacttype
	
Source table	TRANSACTION_ENU_CONTACTTYPE
Grain	One row per contact type
Purpose	Contact type enumeration lookup
Notes

Used downstream by:

ref_repairlink__contact_type
int_repairlink__shop

Provides reusable contact type semantics and descriptions.

### stg_repairlink__suppliermapper
	
Source table	SUPPLIERMAPPER
Grain	One row per supplier mapping
Purpose	Supplier relationship mapping data
Notes

Currently staged for future supplier modeling and enrichment use cases.

### stg_repairlink__shopusermapper
	
Source table	SHOPUSERMAPPER
Grain	One row per shop/user relationship
Purpose	Shop-to-user relationship mapping
Notes

Currently staged for future analytical or identity-resolution use cases.

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
