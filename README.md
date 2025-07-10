# Prediction Data Workflow

This repository contains the data formatting workflow for climate predictions, as discussed in [issue #294](https://earth.bsc.es/gitlab/es/Experiments/-/issues/294).

## Data Sources and Workflow

This section outlines the data sources and the steps involved in the data preparation workflow.

### Atmospheric ICs

*   **Source:** ICs from ERA5 at `/gpfs/projects/bsc32/repository/ic/atmos/T255L91/a2k7/`
*   **Process:**
    *   Manual transfer from `hpc2020` to `MN5` (@etourign).
    *   **Goal:** Automate transfer and perform interpolation on MN5.

### Atmospheric DA

*   ERA5 nudging files (to be used for DCPP soon).

### Ocean DA

*   **Forcing Files:**
    *   Download ERA5 realtime atmospheric forcing files (@etourign).
    *   Format and remap forcing to ERA5 Gaussian grid (T639/N320) at 3-hour steps (@vlapin).
    *   Add random perturbations to t10, qsw, qlw to create 10 forcing members (@vlapin).
*   **Ocean Data:**
    *   Download latest ORAS5 & EN4 data (up to Nov 2024, with a ~2-3 week delay, automated by PA + Marga).
    *   Regrid and reformat EN4 (using `sosie`) & ORAS5 (@vlapin).

### Land

*   **Forcing Files:**
    *   Format ERA5 atmospheric forcing files (@etourign).
    *   Source: `/esarchive/recon/ecmwf/era5/original_files/surface_forcing/hres`

## Usage

The scripts for downloading and formatting the data are located in the `templates` directory.

*   To download EN4 data, use:
    ```bash
    ./templates/download_en4.sh
    ```
*   To download ORAS5 data, use:
    ```bash
    ./templates/download_oras5.sh
    ```
*   To format EN4 data, use:
    ```bash
    ./templates/format_en4.bash
    ```
*   To format ORAS5 data, use:
    ```bash
    ./templates/format_oras5.bash
    ```

## Future Work

*   Extend the workflow to other forcing files used in DA (e.g., BGC @vsicardi and @vlapin).
*   Unify interpolation scripts. Currently, they are spread across `mn5`, `nord3/4`, and `hpc2020` using different tools (`cdo`, `R`, `sosie`, etc.).
