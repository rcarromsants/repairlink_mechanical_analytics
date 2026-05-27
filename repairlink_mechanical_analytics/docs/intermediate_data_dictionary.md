# RepairLink Intermediate Models — Data Dictionary

**Jira epic:** [DAT-2219 — Create Intermediate Models]( https://oeconnection.atlassian.net/browse/DAT-2219 )
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

STAGING                                         REFERENCE
────────                                        ─────────

stg_repairlink__transaction_enu_contacttype ─► ref_repairlink__contact_type

stg_repairlink__countrymaster               ─► ref_repairlink__country

stg_repairlink__currencymaster             ─► ref_repairlink__currency

stg_repairlink__dealeroemenrollment        ─► ref_repairlink__oem



STAGING / REFERENCE                             INTERMEDIATE
──────────────────                              ────────────

stg_repairlink__contact                    ─► int_repairlink__contact


stg_repairlink__dealertrial               ┐
stg_repairlink__dealer_mapper             ├── int_repairlink__dealer
stg_repairlink__dealeroemenrollment       ┘
int_repairlink__contact                   ┘


stg_repairlink__shopconfig                ┐
int_repairlink__contact                   ├── int_repairlink__shop
ref_repairlink__contact_type              ┘


stg_repairlink__manufacturer              ─► int_repairlink__manufacturer

stg_repairlink__vehicle                   ─► int_repairlink__vehicle
catalog_analytics.vintelligence_datafile  ┘


---


## Intermediate model catalogue

### REFERENCE Models

Reference models hold reusable lookup semantics and lightweight normalization logic.

They intentionally:

avoid unknown rows;
preserve stable operational identifiers;
avoid unnecessary business transformation logic.

#### ref_repairlink__contact_type
	
Source	stg_repairlink__transaction_enu_contacttype
Grain	One row per contact type
Business key	contact_type_id
Purpose

Reusable lookup table containing RepairLink contact type semantics.

Used to enrich:

int_repairlink__shop


#### ref_repairlink__country
	
Source	stg_repairlink__countrymaster
Grain	One row per country
Business key	country_id
Purpose

Canonical country lookup dataset.

Provides reusable ISO country semantics across downstream models.

Key logic
excludes sentinel country_id = 0;
preserves ISO alpha-2 and alpha-3 codes.


#### ref_repairlink__currency
	
Source	stg_repairlink__currencymaster
Grain	One row per currency
Business key	currency_id
Purpose

Canonical currency lookup dataset.

Provides reusable ISO currency semantics.

Key logic
excludes sentinel currency_id = 0;
preserves ISO alpha-3 currency codes.


#### ref_repairlink__oem
	
Source	stg_repairlink__dealeroemenrollment
Grain	One row per normalized OEM
Business key	oem_id
Purpose

Reusable OEM lookup dataset.

Centralizes lightweight OEM normalization logic used across downstream dealer/OEM relationships.

Normalization rules
OEM ID	Canonical Name
1	Chrysler
3	General Motors

All other OEM names pass through directly from source.

### INTERMEDIATE Models

Intermediate models contain reusable business transformation logic.

They are responsible for:

deduplication;
enrichment;
entity consolidation;
reusable business logic;
grain reshaping.

The FINAL layer intentionally stays thin and mostly projects curated entities from these models.

#### int_repairlink__contact
	
Source	stg_repairlink__contact
Grain	One row per (org_key, contact_type_id)
Business key	(org_key, contact_type_id)
Purpose

Reusable organizational enrichment layer.

This model is intentionally not a contact dimension.

Instead, it provides reusable organizational/contact enrichment for:

dealers;
shops;
future organizational entities.
Key logic
Filtering

Keeps only records where:

org_key exists;
at least one of:
first_name
last_name
org_name
is populated.
Normalization

Applies lightweight text normalization to:

organization names;
first/last names;
city/state;
address formatting.

Special handling:

converts STE → SUITE
removes punctuation from address_line_2
Deduplication

Deduplicates to:

(org_key, contact_type_id)

keeping:

the most recently updated row;
the row with the richest identifying information.

Important relationships
Relationship	Logic
dealer enrichment	dealer_id = left(org_key, 11)
shop enrichment	shop_id = left(org_key, 11)

#### int_repairlink__dealer
	
Sources	dealer trial, dealer mapper, OEM enrollment, contact enrichment
Grain	One row per canonical 11-character dealer
Business key	dealer_id
Purpose

Consolidated dealer business entity.

Builds the broader dealer ecosystem across multiple RepairLink operational datasets.

Dealer universe logic

The dealer universe is built from:

dealer trial records;
dealer mapper relationships;
connected dealer relationships;
OEM enrollment records.

Dealer identifiers are normalized to the canonical 11-character format.

Enrichment logic

Adds:

total OEM enrollment count;
active OEM enrollment count;
organizational contact enrichment.

Contact enrichment comes from:

int_repairlink__contact

using: left(org_key, 11) as the dealer identifier.



#### int_repairlink__manufacturer
	
Source	stg_repairlink__manufacturer
Grain	One row per manufacturer
Business key	manufacturer_id
Purpose

Reusable manufacturer business entity.

Unlike REFERENCE models, manufacturers contain richer operational/business attributes and therefore remain in the INTERMEDIATE layer.

Key logic
excludes sentinel manufacturer_id = 0;
preserves operational manufacturer attributes.


#### int_repairlink__shop
	
Sources	shop config, contact enrichment, contact type reference
Grain	One row per shop/contact enrichment combination
Business key	shop_id plus contact context
Purpose

Shop business entity enriched with organizational contact metadata.

Enrichment logic

Joins:

int_repairlink__contact
ref_repairlink__contact_type

using:

shop_id = left(org_key, 11)

This normalization is required because:

shop_id uses the canonical 11-character identifier;
org_key may contain the longer source-system format.
Contact type enrichment

Adds:

contact_type_name
contact_type_remark

from:

ref_repairlink__contact_type
Important note on grain

This model is not strictly one row per shop.

A shop can appear multiple times when multiple contact types exist.

The true grain is:

shop + contact enrichment context


#### int_repairlink__vehicle
	
Sources	vehicle staging + VIN intelligence
Grain	One row per VIN
Business key	vin
Purpose

Deduplicated vehicle entity enriched with VIN intelligence metadata.

Deduplication logic

The model:

excludes null VINs;
deduplicates by VIN;
keeps the most recently updated record.
VIN intelligence enrichment

Joins:

catalog_analytics.vintelligence_datafile

using:

first 8 VIN characters;
VIN positions 10–11.

This enrichment adds:

canonical make;
canonical model;
VIN intelligence signature matching.
Defensive deduplication

A final deduplication step guarantees:

exactly one row per VIN

even if VIN intelligence matching introduces unexpected duplication.


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

## Looking ahead — SCD impact

Per the [Slowly Changing Dimension Strategy](https://oeconnection.atlassian.net/wiki/spaces/PDD/pages/1058177171/Slowly+Changing+Dimension+Strategy):

- **`int_repairlink__dealer` and `int_repairlink__shop`** will likely become Type 2 dimensions in marts. When that happens, a `snapshots/snp_dealer.sql` and `snapshots/snp_shop.sql` will sit between intermediate and marts to capture historical versions. The intermediate models themselves stay the same — they always represent the current state.

- **`int_repairlink__vehicle`, `int_repairlink__manufacturer`, `int_repairlink__contact`** — Type 1 dimensions, no snapshots needed. Vehicle attributes are immutable per VIN; reference tables effectively never change meaningfully.
