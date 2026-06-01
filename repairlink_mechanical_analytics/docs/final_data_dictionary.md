# RepairLink Final Models — Data Dictionary

## Overview

The final layer contains analyst-facing dimensional and bridge models built from the intermediate layer.

These models expose business-ready entities while preserving source lineage and supporting future analytical expansion.

Current dimensions:

* dim_dealer
* dim_shop
* dim_manufacturer
* dim_vehicle

Current bridges:

* bridge_dealer_oem
* bridge_dealer_distance

Reference dimensions:

* dim_country
* dim_currency

---

## Architecture Flow

```
INTERMEDIATE                           FINAL
────────────                           ─────

int_repairlink__dealer ─────────────► dim_dealer
int_repairlink__shop ───────────────► dim_shop
int_repairlink__manufacturer ───────► dim_manufacturer
int_repairlink__vehicle ────────────► dim_vehicle

ref_repairlink__country ────────────► dim_country
ref_repairlink__currency ───────────► dim_currency

bridge_dealer_oem ──────────────────► bridge_dealer_oem
bridge_dealer_distance ─────────────► bridge_dealer_distance
```

---

## dim_dealer

### Purpose

Canonical dealer entity dimension.

The dealer universe combines:

* operational dealer datasets

  * dealertrial
  * dealer_mapper
  * dealeroemenrollment

and

* dealer-related organizational contacts

  * contact_type_id 101
  * contact_type_id 104

This approach ensures dealer entities identified through contact activity are not excluded from analytical reporting.

### Key Fields

| Column            | Description                                           |
| ----------------- | ----------------------------------------------------- |
| dealer_id         | Canonical 11-character dealer identifier              |
| total_oem_count   | Total OEM enrollments                                 |
| active_oem_count  | Active OEM enrollments                                |
| is_contact_source | Dealer identified through contacts                    |
| is_dealer_source  | Dealer identified through operational dealer datasets |

### Contact Enrichment

Dealer entities are enriched with the latest dealer-related contact record.

The following timestamps originate from the selected contact record and do not represent dealer lifecycle timestamps:

* contact_created_at
* contact_updated_at
* contact_ingested_at

---

## dim_shop

### Purpose

Canonical shop entity dimension.

The shop universe combines:

* operational shop configuration records
* shop-related organizational contacts

  * contact_type_id 100
  * contact_type_id 103

This ensures shops referenced through contact activity are retained even when not present in operational shop configuration data.

### Key Fields

| Column            | Description                                  |
| ----------------- | -------------------------------------------- |
| shop_id           | Shop identifier                              |
| location_code     | Operational location code                    |
| order_type        | Shop order type                              |
| is_contact_source | Shop identified through contacts             |
| is_shop_source    | Shop identified through operational datasets |

### Contact Enrichment

Shop entities are enriched using the latest shop-related contact record.

The following timestamps originate from the selected contact record:

* contact_created_at
* contact_updated_at
* contact_ingested_at

These timestamps do not represent shop creation or lifecycle events.

---

## dim_vehicle

## Purpose

Canonical vehicle dimension.

One row per VIN.

Vehicle records are deduplicated in the intermediate layer and enriched using Automotive Dimensions VIN Intelligence data.

### Make / Model Standardization

Vehicle attributes follow the hierarchy:

1. VIN Intelligence values
2. Normalized RepairLink values (fallback)

This produces canonical values for:

* vehicle_make
* vehicle_model

even when VIN enrichment is unavailable.

### Key Fields

| Column                | Description                         |
| --------------------- | ----------------------------------- |
| vin                   | Vehicle Identification Number       |
| vehicle_make          | Canonical make                      |
| vehicle_model         | Canonical model                     |
| vin_vintelligence     | VIN Intelligence pattern match      |
| vin_decoded_correctly | Indicates successful VIN enrichment |

### Notes

VIN enrichment coverage is still being monitored.

Unmatched VINs automatically fall back to normalized RepairLink values.

---

## dim_manufacturer

### Purpose

Canonical manufacturer dimension.

One row per manufacturer.

The dimension is sourced from the RepairLink manufacturer master dataset.

### Key Fields

| Column                    | Description             |
| ------------------------- | ----------------------- |
| manufacturer_id           | Manufacturer identifier |
| manufacturer_name_long    | Full manufacturer name  |
| manufacturer_name_short   | Short manufacturer name |
| manufacturer_business_key | Source business key     |
| industry_id               | Industry segment        |

---

## dim_country

### Purpose

Country reference dimension.

One row per ISO country.

### Notes

country_id corresponds to the ISO 3166-1 numeric code.

country_code values from contact entities should join through:

* two_letter_iso_code

not through country_id.

---

## dim_currency

### Purpose

Currency reference dimension.

One row per ISO currency.

### Notes

currency_id corresponds to the ISO 4217 numeric code.

currency_name is not guaranteed to be unique.

Analytical joins should use:

* currency_code

rather than currency_name.

---

## bridge_dealer_oem

### Purpose

Represents dealer-to-OEM enrollment relationships.

One row per dealer OEM enrollment.

### Key Fields

* dealer_oem_enrollment_id
* dealer_id
* oem_id
* is_active
* enrolled_at

---

## bridge_dealer_distance

### Purpose

Represents dealer-to-dealer distance relationships.

One row per dealer pair.

### Key Fields

* from_dealer_id
* to_dealer_id
* distance_km
* group_id
* status

---

## Data Quality Notes

The final layer focuses on business consumption rather than source-level validation.

Detailed profiling and source quality assessments are performed in the staging and intermediate layers.

Validation at the final layer focuses primarily on:

* entity uniqueness
* key completeness
* referential integrity
* source lineage consistency

---

## Future Enhancements

1. Revisit dealer and shop universe definitions with business stakeholders to confirm whether contact-derived entities should permanently contribute to the canonical entity population.

2. Continue monitoring VIN Intelligence coverage and unmatched VIN populations.

3. Evaluate Type 2 history requirements for dealer and shop entities.

4. Reassess the need for a dedicated contact dimension once transactional fact models are introduced.
