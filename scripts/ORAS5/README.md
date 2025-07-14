# Producing ORAS5 nudging files

The script **Interp_ORAS5_to_ORCA1.sh** applies to standard resolution (ORCA1), **enlarge.py** to high resolution (ORCA025). 
These scripts are used to interpolate/extrapolate the oras5 fields to the eORCA grid, to produce 3D-nudging for ocean-only reconstructions.

They both use as inputs the oras5 netcdf files from /esarchive/releases/nudging/ocean/s5/ORCA025L75_ORAS5/ processed by CES people (P.A. Bretonniere).
The output files are then moved from /esarchive/releases/nudging/ocean/s5/ORCA${resolution}/ to /gpfs/projects/bsc32/repository/nudging/ocean/s5/.


- **Interp_ORAS5_to_ORCA1.sh**: produces ORAS5 nudging file interpolated into ORCA1 grid. Mainly CDO commands.

- **enlarge.py** (and its launcher script for nord3v2): extends ORAS5 grid to eORCA025 grid of NEMO. 
The script is an adapation of the one created by Thomas Arzouse, initially developed on Power9. 

Note that for the recent years of ORAS5 (2018 to 2021), we had some issues because the original ORAS5 data are not processed the same way. 
It's mainly related to the definition of the mask/missing value. Pierre-Antoine Bretonniere has to pre-processed them differently (those saved in /esarchive/releases/nudging/ocean/s5/ORCA025L75_ORAS5/). Cf issue es/requests#1351 (comment 162522) to know more about it.


# Producing ORAS5 surface restoring files

The script **create_restoring_file_ORAS5_nord3v2.sh** consists in taking the fields (temperature and salinity) at the surface from the previous nudging files produced and modified some attributs for them to be used by NEMO.
