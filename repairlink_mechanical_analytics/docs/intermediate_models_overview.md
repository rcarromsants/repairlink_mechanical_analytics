## int_repairlink__contact
- Business meaning: Transactional contact information linked to RepairLink transactions/documents
- Grain: 1 row = 1 contact_id
- Main logic: Filters out records with no meaningful identity information
- Main usage: Contact, organization, and location analytics

## int_repairlink__country
- Business meaning: Country reference/master data
- Grain: 1 row = 1 country
- Main logic: Removes sentinel “Unknown” record (`country_id = 0`)
- Main usage: Geographic standardization and reporting

## int_repairlink__currency
- Business meaning: Currency reference/master data
- Grain: 1 row = 1 currency
- Main logic: Removes sentinel “Unknown” record (`currency_id = 0`)
- Main usage: Financial and localization analytics

## int_repairlink__manufacturer
- Business meaning: Vehicle manufacturer reference entity
- Grain: 1 row = 1 manufacturer
- Main logic: Removes sentinel “Unknown” manufacturer (`manufacturer_id = 0`)
- Main usage: OEM/manufacturer analytics

## int_repairlink__shop
- Business meaning: Latest operational/configuration state of a RepairLink shop
- Grain: 1 row = 1 shop_id
- Main logic: Deduplicates by `shop_id`, keeping the most recent record
- Main usage: Shop-level operational analytics

## int_repairlink__dealer
- Business meaning: Dealer and OEM enrollment/trial information
- Grain: 1 row = 1 dealer
- Main logic: Consolidates dealer operational and enrollment data
- Main usage: Dealer and enrollment analytics

## int_repairlink__vehicle
- Business meaning: Physical vehicles enriched with Automotive Dimensions VIN intelligence
- Grain: 1 row = 1 VIN / physical vehicle
- Main logic:
  - Deduplicates by VIN
  - Keeps the most recently updated record
  - Enriches vehicle make/model using Automotive Dimensions
  - Retains original RepairLink values temporarily for validation
- Main usage:
  - Vehicle analytics
  - VIN standardization
  - OEM reporting