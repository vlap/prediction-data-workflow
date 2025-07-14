for file in *era5-hres-n320_????.nc ; do 
dtmv $file /gpfs/projects/bsc32/repository/fg/ocean/ERA5_HRES/${file//_era5-hres-n320_/_fc00_ERA5_HRES_} ;
done
