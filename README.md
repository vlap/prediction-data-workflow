Initial commit for the Data formatting workflow for predictions commented in https://earth.bsc.es/gitlab/es/Experiments/-/issues/294

# List of Data for the Workflow

**Atmospheric ICs:**

* ICs from ERA5 at `/gpfs/projects/bsc32/repository/ic/atmos/T255L91/a2k7/`
* (@etourign) Transfer from `hpc2020` to `MN5` currently manual.
* Goal: automate transfer + do interpolation on MN5.

**Atmospheric DA:**

* ERA5 nudging files (not yet used for DCPP but will be soon)

**Ocean DA:**

* Download ERA5 realtime atmospheric forcing files (@etourign).
* Format + remap forcing to ERA5 Gaussian grid (T639/N320) at 3hr steps (@vlapin).
* Add random perturbations to t10, qsw, qlw → create 10 forcing members (@vlapin).
* Download latest ORAS5 & EN4 data (up to Nov 2024, ~2-3 week delay, PA + Marga automated).
* Regrid/reformat EN4 (using sosie) & ORAS5 (@vlapin)

**Land:**

* Format ERA5 atmospheric forcing files (@etourign).
* ERA5 surface forcing files: `/esarchive/recon/ecmwf/era5/original_files/surface_forcing/hres`

**More:**

* Workflow should be extendable to other forcing files used in DA (e.g. BGC @vsicardi and @vlapin).
* Interpolation scripts should be unified. Some work on mn5, some on nord3/4, some on hpc2020. Some cdo, some R, some sosie, etc