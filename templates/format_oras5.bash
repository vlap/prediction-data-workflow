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
module load ECAC

set -xuve

# Input parameters
DATELIST="%DATELIST"

# Function nb_days_mon
#source ~/scripts/bash_functions.bash
function nb_days_mon() {
  year=$1
  mon=$2
  if [ $# -ne 2 ] ; then
    echo "Wrong usage: nb_days_mon" $1 $2 " and should be nb_days_mon year mon "
             #    exit
  else
   nb_days_mon=$(( $( cal $mon $year | grep "[0-9]" | wc -w ) - 2 ))
   echo $nb_days_mon
 fi
}

# Paths
basedir="/esarchive/recon/ecmwf/oras5"
operdir="${basedir}/scripts/operational"

cd ${basedir}/original_files

for date in ${DATELIST[@]}; do
	y=$(echo $date | cut -c1-4)
	mon=$(echo $date | cut -c5-6)
for mb in $(seq 0 4);do
    mkdir -p $mb
    
    for var in "vosaline" "votemper";do
        # Create formatting scripts for the date
        mkdir -p ${operdir}/${y}${mon}
        case $var in
sohtc300) grid="T";;
sossheig | sosstsst | votemper) grid="T";;
vomecrty) grid="V";;
vosaline) grid="T";;
vovecrtz) grid="W";;
vozocrtx) grid="U";;
*) echo "Add variable to case list"; exit 1;;
esac

# Directories
basedir=/esarchive/recon/ecmwf/oras5
if [[ $mb == "0" ]];then
  # ${basedir}/monthly_mean/${var}/opa0 is a link to ${basedir}/monthly_mean/${var}
  outdir=${basedir}/monthly_mean/${var}
else
  outdir=${basedir}/monthly_mean/${var}/opa${mb}
  mkdir -p $outdir
fi

cd $basedir/original_files


for zipfile in $(ls ${mb}/*_1m_*${y}${mon}*_${grid}_*gz);do
    extracted_file="$(echo $zipfile | cut -f1 -d".").nc"
    [[ -f $extracted_file ]] && rm $zipfile
    [[ ! -f $extracted_file ]] && gunzip $zipfile
done
for f in $(ls ${mb}/*_1m_*_${y}${mon}*_${grid}_*nc) ; do
    date=$(echo $f | cut -f3 -d"_" | cut -c1-6)
    outfile=${outdir}/${var}_${date}.nc

    if [[ ! -f $outfile ]]; then

      # Extract variable
      ncks -O -v $var $f ${tmpdir}/tmp_${var}_${date}_${mb}.nc

      # Rename variables and dimensions
      ncrename -v .time_counter,time -d .time_counter,time -v .nav_lon,longitude -v .nav_lat,latitude ${tmpdir}/tmp_${var}_${date}_${mb}.nc $outfile

      # Delete conflicting attributes and variables
      ncatted -O -a bounds,time,d,, ${outfile}
      ncatted -O -a coordinates,${var},d,, ${outfile}
      ncks -O -x -v time_counter_bnds ${outfile} ${tmpdir}/tmp_${var}_${date}_${mb}.nc
      mv ${tmpdir}/tmp_${var}_${date}_${mb}.nc ${outfile}2

      # Set 0 (strong blue colour in the ncview map) to NaN (miss, white colour in the ncview map) because it's ocean
      cdo setctomiss,0 ${outfile}2 ${outfile}3
      rm ${outfile}2

      # To have latitude without missing_value (produced by cdo setctomiss) 
      ncap2 -O -s "latitude(498,:)=latitude(1,1)-latitude(1,1)" ${outfile}3 ${outfile}

      # Change group to earth 
      chgrp earth ${outfile}

      # Remove temporary files
      rm ${outfile}3
    fi
done

    done
done
var_list="vosaline votemper"

orca1_grid="/esarchive/recon/ecmwf/oras5/scripts/operational/orca1_grid"
srcdir="/esarchive/recon/ecmwf/oras5/monthly_mean"
#outdir="/gpfs/projects/bsc32/repository/nudging/ocean/s5/ORCA1L75"
outdir="/esarchive/scratch/msamso/tmp/oras5"
mkdir -p $outdir

#for mb in $(seq 0 4);do 
  mkdir -p ${outdir}/fc${mb}
  mkdir -p ${tmpdir}/vosaline/opa${mb}
  mkdir -p ${tmpdir}/votemper/opa${mb}
  mkdir -p $tmpdir/fc0${mb}

  cd ${outdir}/fc${mb}

  if [[ ! -f ${tmpdir}/vosaline_${y}_opa${mb}.nc ]];then
        for var in $var_list;do
          for file in $(ls ${srcdir}/$var/opa${mb}/*${y}*nc);do
            filename=$(echo $file | rev | cut -f1 -d"/" | rev)

            # Correct missing time dimension for variable time
            if [[ -z $(ncdump -h $file | grep "time(time) ;") ]];then
                ncrename -v .time_counter,time -d .time_counter,time $file
                ncap2 -O -s 'time[time]=time' $file $file
                ncatted -O -a coordinates,$var,m,c,"time deptht latitude longitude" $file
            fi

            if [[ ! -f ${tmpdir}/$var/opa${mb}/${filename} ]];then
              # Removed time_counter_bnds if needed
              if [[ ! -z $(ncdump -h $file | grep "time_counter_bnds(") ]];then
                ncks -O -C -x -v time_counter_bnds ${file} ${tmpdir}/$var/opa${mb}/${filename}
                ncatted -O -a bounds,time,d,, ${tmpdir}/$var/opa${mb}/${filename}
              else
                cp ${file} ${tmpdir}/$var/opa${mb}/${filename}
              fi
              # Rename variables and dimensions
              ncrename -v .time_counter,time -d .time_counter,time -v .deptht,nav_lev -d .deptht,nav_lev ${tmpdir}/$var/opa${mb}/${filename}
              ncrename -v .latitude,lat -d .latitude,lat -v .longitude,lon -d .longitude,lon ${tmpdir}/$var/opa${mb}/${filename}
            fi

          done

          # Merge each variable's files
          [[ ! -f ${tmpdir}/${var}_${y}_opa${mb}.nc ]] && ncrcat ${tmpdir}/$var/opa${mb}/*${y}* ${tmpdir}/${var}_${y}_opa${mb}.nc

        done
  # Add variable vosaline to votemper file
        if [[ -z $(ncdump -h ${tmpdir}/votemper_${y}_opa${mb}.nc | grep vosaline) ]];then
            ncks -A -v vosaline ${tmpdir}/vosaline_${y}_opa${mb}.nc ${tmpdir}/votemper_${y}_opa${mb}.nc
        fi

        ncatted -O -a coordinates,votemper,c,c,"time nav_lev lat lon" ${tmpdir}/votemper_${y}_opa${mb}.nc
        ncatted -O -a coordinates,vosaline,c,c,"time nav_lev lat lon" ${tmpdir}/votemper_${y}_opa${mb}.nc
    fi

    if [[ ! -f ${outdir}/fc${mb}/s5_fc${mb}_${y}.nc ]];then
        cdo -L -setmisstoc,0 -setmissval,NaN ${tmpdir}/votemper_${y}_opa${mb}.nc ${outdir}/fc${mb}/s5_fc${mb}_${y}.nc
    else
        nts=$(ncdump -h ${outdir}/s5_fc${mb}_${y}.nc | grep UNLIMITED | cut -f2 -d"(" | cut -f1 -d" ")
        if (( $nts != 12 ));then
            cdo -L -setmisstoc,0 -setmissval,NaN ${tmpdir}/votemper_${y}_opa${mb}.nc ${outdir}/fc${mb}/s5_fc${mb}_${y}.nc
        fi
    fi


#used to be: ssh bsc032707@nord4login1.bsc.es sbatch -A bsc32 -q bsc_es /esarchive/recon/ecmwf/oras5/scripts/operational/ft-oper-launch-releases-nudging-ocean-s5-i1351.bash $y
#ssh bsc32707@nord4.bsc.es sbatch /gpfs/projects/bsc32/repository/nudging/ocean/s5/scripts/operational/ft-oper-launch-releases-nudging-ocean-s5-i1351.bash $y
done
