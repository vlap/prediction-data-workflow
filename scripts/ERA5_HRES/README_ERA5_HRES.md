The following scripts are used to format the ERA5 surface forcing fields from raw grib files downloaded with the script_osm_data scripts, to netcdf files which can be read by NEMO.

- correct-era5-197901.sh - script to correct the grib headers of the first timesteps of 1979 (or 1950 when the new data becomes available), to be run (once) before anything else
- convert-forcings-nemo.sh - script which converts raw 1hr/monthly grib files in native reduced gaussian grid 3hr/yearly grib files in t255 regular gaussian grid
- convert-forcings-nemo-2020.sh - script to merge the last 2 months of 2019 data into the partial 2020 files - temporary!

old scripts

- convert-forcings-nemo4.sh - script which converts raw 1hr/monthly grib files to 3hr/yearly netcdf files in reduced gaussian grid
- convert-nemo-orca1.sh - script to convert netcdf files in reduced gaussian grid to orca1 grid, to be read directly by nemo
- convert-nemo-T255.sh - script to convert netcdf files in reduced gaussian grid to regular gaussian grid at T255/N320 resolution, which can be read directly by nemo using the remapping weights from T255/N320 to ORCA1
