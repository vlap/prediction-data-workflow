# Interpolate EN4 to ORCA Grid

## Purpose
Interpolate EN4.2.2 dataset to ORCA1 grid for ocean models.

## Inputs
- Directory containing EN4.2.2 NetCDF files.
- ORCA1 grid file.

## Outputs
- Interpolated NetCDF files for ORCA1 grid (`en4.2.2_*_ORCA1.nc`).

## Dependencies
- Modules: `nco/4.9.3`, `cdo/1.9.8`
- Script: `workflows/EN4/scripts/interpolate_en4.2.2_to_ORCA.sh`

## Validation
- Smoke test: Verify output file exists and has correct dimensions.

## Owner
- Climate Variability and Change Group

## Last Verified
- 2026-09-19 (🟡 Needs verification)