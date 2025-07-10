#!/bin/bash
set -xuve

source ~/.bashrc

# Nord4
module purge
module load nord3-singu
module use /gpfs/projects/bsc32/software/suselinux/11/modules/all
unset PYTHONSTARTUP
module load Python
module load netcdf4-python
module load CDO
module load NCO

newgrp earth
tmpdir=/esarchive/scratch/msamso/tests
#tmpdir=$TMPDIR

###################################################################
# This script formats EN.4.2.2.f.analysis.g10.${y}${mon}.nc files
###################################################################
# Input parameters
for date in $( echo ${dates[@]}) ; do
	y=$(echo $date | cut -c1-4)
for var in tos sos thetao so; do


cd /esarchive/obs/ukmo/en4-v4.2.2/original_files

dirout=/esarchive/obs/ukmo/en4-v4.2.2/monthly_mean/${var}
#dirout=/esarchive/scratch/msamso/tmp/ukmo/en4-v4.2.2/monthly_mean/${var}

for mon in $(seq -w 1 12);do
	fileout=${var}_${y}${mon}.nc
	mkdir -p $dirout

	case $var in 
	tos) varin=temperature ; long_name="Sea surface temperature" ; standard_name="sea_surface_temperature";;
	sos) varin=salinity ; long_name="Sea surface salinity" ; standard_name="sea_surface_salinity";;
	thetao) varin=temperature ; long_name="Potential temperature" ; standard_name="potential_temperature";;
	so) varin=salinity ; long_name="Salinity" ; standard_name="salinity";;
	*) echo "Variable not included in the case list"; exit;;
	esac

	if [[ ! -f $dirout/$fileout ]]; then
	    echo $fileout
	    filein=$(ls EN.4.2.2.f.analysis.g10.${y}${mon}.nc)
	    # Selext variable
	    cdo selvar,$varin,${varin}_uncertainty $filein $dirout/$fileout

	    # Rename variables
	    nccopy -k classic $dirout/$fileout $tmpdir/$fileout
	    ncrename -v .$varin,$var -v .${varin}_uncertainty,${var}_uncertainty $tmpdir/$fileout
	    ncrename -d .depth,lev -v .depth,lev $tmpdir/$fileout
	    ncrename -v .depth_bnds,lev_bnds $tmpdir/$fileout
	    nccopy -k 4 $tmpdir/$fileout $dirout/$fileout

	    # Change type for coordinates from float to double and remove coordinates bounds
	    if [[ -z $(ncdump -h $file | grep "double lat(") ]];then
	      ncap2 -O -s "lat=double(lat); lon=double(lon)" ${dirout}/${fileout} ${dirout}/${fileout}
	    fi

	    # Edit attributes
	    ncatted -O -a long_name,$var,m,c,"$long_name" $dirout/$fileout
	    ncatted -O -a standard_name,$var,m,c,"$standard_name" $dirout/$fileout
	    ncatted -O -a missing_value,$var,m,f,-32768 $dirout/$fileout
	    ncatted -O -a valid_min,$var,d,, $dirout/$fileout
	    ncatted -O -a valid_max,$var,d,, $dirout/$fileout

	    # Convert time from float to double to homogenize data
	    if [[ ! -z $(ncdump -h $dirout/$fileout | grep "float time(") ]];then
	      ncap2 -O -s "time=double(time)" $dirout/$fileout $dirout/$fileout
	    fi

	    # Convert units for tos
	    if [[ $var == "tos" ]];then
		ncap2 -O -s "tos=tos-273.15" $dirout/$fileout ${tmpdir}/${fileout}
		ncatted -O -a units,tos,m,c,"degC" ${tmpdir}/${fileout}
		ncatted -O -a units,tos_uncertainty,m,c,"degC" ${tmpdir}/${fileout}
		mv ${tmpdir}/${fileout} $dirout/$fileout
	    fi

	    # Remap 
	    grid="/esarchive/obs/ukmo/en4-v4.2.2/scripts/grido.txt"
	    cdo -s -remapnn,${grid} $dirout/$fileout ${tmpdir}/${fileout}
	    mv ${tmpdir}/${fileout} $dirout/$fileout

	    # Rename depth to lev
	    nccopy -k classic $dirout/$fileout $tmpdir/$fileout
	    ncrename -d .depth,lev -v .depth,lev $tmpdir/$fileout
	    ncrename -v .depth_bnds,lev_bnds $tmpdir/$fileout
	    nccopy -k 4 $tmpdir/$fileout $dirout/$fileout

	    # Edit lev attributes
	    ncatted -O -a long_name,lev,m,c,"ocean depth coordinate" $dirout/$fileout
	    ncatted -O -a units,lev,m,c,"m" $dirout/$fileout
	    ncatted -O -a cell_methods,lev,d,, $dirout/$fileout
	    if [[ $var == "thetao" ]] || [[ $var == "so" ]];then # 3D variables
		if [[ -z $(ncdump -h $dirout/$fileout | grep "lev:bounds") ]];then
  	            ncatted -O -a bounds,lev,c,c,"lev_bnds" $dirout/$fileout
	        else
  	            ncatted -O -a bounds,lev,m,c,"lev_bnds" $dirout/$fileout
		fi
	   fi
	
           # Remove dimension depth for 2D variables (at surface) (time, lat, lon)
	    if [[ $var == "tos" || $var == "sos" ]];then
  	        # Select first value for variable depth
	        ncks -O -d lev,0 $dirout/$fileout ${tmpdir}/${fileout}2

	        # Remove dimension depth once it only has one level (dimension depth = 1)
	        ncwa -O -a lev ${tmpdir}/${fileout}2 ${dirout}/${fileout}

  	        # Remove coordinates bounds and lev bounds
		if [[ -z $(ncdump -h $file | grep "double lat_bnds(") ]];then
		      ncks -O -C -x -v lon_bnds ${dirout}/${fileout} $tmpdir/$fileout
		      ncks -O -C -x -v lat_bnds $tmpdir/$fileout ${dirout}/${fileout}
		      ncatted -O -a bounds,lon,d,, ${dirout}/${fileout}
		      ncatted -O -a bounds,lat,d,, ${dirout}/${fileout}
		fi
		if [[ -z $(ncdump -h $file | grep "double lev_bnds(") ]];then
		      ncks -O -C -x -v lev_bnds ${dirout}/${fileout} $tmpdir/$fileout
		      mv $tmpdir/$fileout ${dirout}/${fileout}
		      ncatted -O -a bounds,lev,d,, ${dirout}/${fileout} 
		      ncatted -O -a cell_methods,$var,m,c,"time: mean" $dirout/$fileout
		      ncatted -O -a cell_methods,$var_uncertainty,m,c,"time: mean" $dirout/$fileout
		      ncatted -O -a cell_methods,lev,d,, $dirout/$fileout
		fi
	    fi

	    # Change units attribute for so
	    if [[ $var == "so" ]];then
		ncatted -O -a units,so,m,c,"0.001" $dirout/$fileout
                ncatted -O -a units,so_uncertainty,m,c,"0.001" $dirout/$fileout
	    fi
            if [[ $var == "sos" ]];then
                ncatted -O -a units,sos,m,c,"0.001" $dirout/$fileout
                ncatted -O -a units,sos_uncertainty,m,c,"0.001" $dirout/$fileout
            fi
	fi
done
done
