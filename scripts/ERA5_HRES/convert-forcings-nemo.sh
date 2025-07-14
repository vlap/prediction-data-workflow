#!/usr/bin/env bash

# script adapted from generate_forcing.sh in EC-Earth 3.3.2

# scripts for era-interim were here:
#/esarchive/scratch/jacosta/TMP/Interp_ERA/input_ERAInt/
#/esarchive/scratch/jacosta/TMP/Interp_ERA/output_ORCA1/

# copy era5-hres n320 to /gpfs/projects/bsc32/repository/fg/ocean/ERA5_HRES after running this
# for file in *era5-hres-n320_????.nc ; do echo mv $file ${file//_era5-hres-n320_/_fc00_ERA5_HRES_} ; done

function get_forcing_era5()
{
  # generic function to get data 
  fy=$2 #forcing year
  subdir=$1 #forcing file subdir (if forcing_raw_subdir=true) and outfile middle-fix
  prefix=$3 #forcing file prefix
  infreq=$4 #forcing frequency in hours
  outfreq=$5 #output forcing frequency in hours
  dest_dir=$6
  fc=$7

  $forcing_raw_subdir && fd=$forcing_raw_dir/$subdir || fd=$forcing_raw_dir

  suffix=${fc}_${subdir}_${fy}
  suffix2=${fc}_${subdir}_${fy}-reg


  [[ $outfreq != $infreq ]] && [[ $infreq != 1 ]] && echo "error! forcing frequency must be 1 hour if output frequency is different!" && exit 1

  hours=$( printf "%02d," $(seq 0 $outfreq 23) )
  hours="${hours:0:-1}"

  # change true to false to skip untarring
  if true ; then
  #if false ; then

  for var in $nemo_forcing_vars
  do
    rm -f data.${var}.??.grb data.${var}.grb
  done

  months=`seq 1 12`
  #months=1
  [[ $outfreq != $infreq ]] && months="0 $months"

  for im in $months
  do
    mm=$(printf "%02d" $im)

    # we need the last timestep of the previous year for the average of the first timestep
    if [[ $im = 0 ]] ; then
      yy=$(( $fy-1 ))
      rename_cmd="cdo -f grb1 -seldate,${yy}-12-31T$((24-$outfreq+1)):00:00,${fy}-01-01T00:00:00"
      tar_file=$fd/${prefix}${yy}1200${fc}.tar.gz
      # if previous month not found (e.g. 1979/1950), then repeat the first timesteps
      if [[ ! -f ${tar_file} ]] ; then
        echo "warning! file ${tar_file} not found for year $fy !"
        yy=$fy
        # Since the new back extension update, 1979/1950 are no longer "special" years. Only 1940 is
#	if [[ $yy = 1950 ]] ; then
#       if [[ $yy = 1940 ]] ; then
#	    # this only works for 3hr output frequency and 1hr input frequency (era5-hres)!
#            rename_cmd="cdo -f grb1 -shifttime,-7hour -seldate,${fy}-01-01T01:00:00,${fy}-01-01T013:00:00"
#	else
            rename_cmd="cdo -f grb1 -shifttime,-${outfreq}hour -seldate,${fy}-01-01T01:00:00,${fy}-01-01T0$((outfreq-1)):00:00"
#	fi
        tar_file=$fd/${prefix}${yy}0100${fc}.tar.gz
        echo "using ${tar_file} instead"
      fi
    else
      yy=$fy
      rename_cmd="mv"
      tar_file=$fd/${prefix}${yy}${mm}00${fc}.tar.gz
      #tar_file=$fd/${prefix}${yy}${mm}01${fc}.tar.gz
      # could be that we got data from era5rt, check with expver=5
      if [[ ! -f ${tar_file} ]] ; then
        tar_file=$fd/${prefix/ea_1/ea_5}${yy}${mm}00${fc}.tar.gz
        [[ ! -f ${tar_file} ]] && break
      fi
    fi

    # untar files
    ${copy_cmd} ${tar_file} forcing.tar.gz
    tar -zxvf forcing.tar.gz
    rm -f forcing.tar.gz

    # rename to monthly files
    ${rename_cmd} Tair.grb data.t10.${mm}.grb
    ${rename_cmd} Qair.grb data.q10.${mm}.grb 
    #cdo exp PSurf.grb data.sp${mm}.grb
    ${rename_cmd} PSurf.grb data.slp.${mm}.grb
    ${rename_cmd} Wind_E.grb data.u10.${mm}.grb 
    ${rename_cmd} Wind_N.grb data.v10.${mm}.grb 
    ${rename_cmd} SWdown.grb data.qsw.${mm}.grb 
    ${rename_cmd} LWdown.grb data.qlw.${mm}.grb 
    ${rename_cmd} Rainf.grb data.precip.${mm}.grb 
    ${rename_cmd} Snowf.grb data.snow.${mm}.grb 

#    nemo_vars=( ${nemo_forcing_vars} )
#    osm_vars=( ${osm_forcing_vars} )
#    for((i=0;i<${#nemo_vars[@]};i++))
#    do
#	echo "$i: ${nemo_vars[$i]} ${osm_vars[$i]}"
#	nemo_var=${nemo_vars[$i]}
#	osm_var=${osm_vars[$i]}
#	${rename_cmd} ${osm_var}.grb data.${nemo_var}.${mm}.grb
#    done


  done  

  fi

  if true; then
  #if false; then

  # merge monthly files into yearly files, skip overlapping timesteps
  for var in $nemo_forcing_vars
  do
    SKIP_SAME_TIME=1 cdo -f grb1 -O mergetime data.${var}.??.grb tmp.grb
    # this is to remove vertical dimension and variables hyai nhyi hyam hybm
    grib_set -s typeOfLevel=surface tmp.grb data.${var}.grb
  done

  fi

  # convert to netcdf format (reduced gaussian)
  #cdo -f grb setgrid,../../lsm-t319.grb t10_fc0_era5-enda_2010.nc tmp1.grb
  #cdo -f nc4c -z zip_2 -setgridtype,regular tmp1.grb tmp1.nc
  npts=`cdo griddes data.t10.grb | grep gridsize | awk '{print $3}'`

  #cdo_cmd="cdo --timestat_date=last -f nc4c -z zip_2 -setgrid,g${npts}x1"
  cdo_cmd="cdo --timestat_date last copy" # keep grib format
  cdo_cmd2="cdo --timestat_date last -f nc4c -z zip_2 -setgridtype,regular" # unused, regular gaussian netcdf

  [[ $outfreq != $infreq ]] && time_cmd="-selhour,$hours" || time_cmd=""
  for var in ${vars_inst} ; do
    ${cdo_cmd} ${time_cmd} data.${var}.grb ${var}${suffix}.grb #&
    #${cdo_cmd2} ${time_cmd} data.${var}.grb ${var}${suffix2} &
    #wait
  done

  [[ $outfreq != $infreq ]] && time_cmd="-timselmean,$outfreq" || time_cmd=""
  for var in ${vars_mean} ; do
    #${cdo_cmd} ${time_cmd} data.${var}.grb ${var}${suffix}.grb
    ${cdo_cmd} ${time_cmd} data.${var}.grb ${var}${suffix}.grb.tmp
    # workaround for cdo which gets confused with time axis
    grib_set -s timeRangeIndicator=10 ${var}${suffix}.grb.tmp ${var}${suffix}.grb
    rm -f ${var}${suffix}.grb.tmp
  done

}

function convert_forcings()
{
  fy=$2 #forcing year
  midfix=$1 #outfile middle-fix
  grid=$3 # target grid recognized by cdo e.g. n320 or "" to only convert to regular grid
  res=$4 # name of the grid in the output files
  suffix=_${midfix}-${res}_${year}.nc

  [ "$grid" == "" ] && remap_str="copy" || remap_str="remapbil,${grid}"

  # remap to target grid
#  for var in t10 ; do
  for var in $nemo_forcing_vars ; do
      #cdo -f nc4c -z zip_2 -R remapbil,${grid_dir}/grid_${res}.txt ${var}_${midfix}_${year}.grb ${var}_${midfix}-${res}_${year}.nc

      #stupid workaround convert grib2 to grib1 to avoid interpolation issues.
      #[ ! -f ${var}_${midfix}_${year}.grb1 ] && cdo -f grb copy ${var}_${midfix}_${year}.grb ${var}_${midfix}_${year}.grb1
      #cdo -f nc4c -z zip_2 -R remapbil,${grid_dir}/grid_${res}.txt ${var}_${midfix}_${year}.grb1 ${var}_${midfix}-${res}_${year}.nc
      #cdo -f nc4c -z zip_2 -R ${remap_str} ${var}_${midfix}_${year}.grb1 ${var}_${midfix}-${res}_${year}.nc

      # workaround not required anymore, since we convert to grb1 beforehand
#      if [[ ${var} == precip ]] ; then
      case ${var} in
           precip)
             # fix the incorrect treatment of precip as rain-only, istead of rain+snow
              cdo -f nc4c -z zip_2 -R ${remap_str} -add ${var}_${midfix}_${year}.grb snow_${midfix}_${year}.grb ${var}_${midfix}-${res}_${year}.nc
            ;;
           slp)
             # lnsp becomes var25, convert lnsp to sp
             cdo -f nc4c -z zip_2 -R ${remap_str} -expr,'slp=exp(var25)' ${var}_${midfix}_${year}.grb ${var}_${midfix}-${res}_${year}.nc
            ;;
           *)
              cdo -f nc4c -z zip_2 -R ${remap_str} ${var}_${midfix}_${year}.grb ${var}_${midfix}-${res}_${year}.nc
            ;;
       esac

  done

  #rename vars and fix metadata

  ncrename -v var0,t10 t10${suffix}
  ncrename -v var0,q10 q10${suffix}
  ncrename -v var2,u10 u10${suffix}
  ncrename -v var3,v10 v10${suffix}
  ncrename -v var169,qsw qsw${suffix}
  ncrename -v var175,qlw qlw${suffix}
  ncrename -v var143,precip precip${suffix}
  ncrename -v var144,snow snow${suffix}

#  for var in t10 ; do
  for var in $nemo_forcing_vars ; do
      ncatted -h -a  param,${var},d,, ${var}${suffix}
      ncatted -h -a  table,${var},d,, ${var}${suffix}
      ncatted -h -a  code,${var},d,, ${var}${suffix}
  done

}


set -euxv

# ./convert-forcings-nemo.sh era5-enda 2009 2009 3 0

nemo_forcing_type=$1 #'era5-hres' #'era5-enda'
year1=$2 #1979
year2=$3 #1979
#nemo_grid=$4 #ORCA1 # ORCA025
frequency=$4 # in hours (1, 3 etc.)

[ "$#" -eq 5 ] && memb=$5 || memb=-1
[ $memb -ge 0 ] && fc1="_fc${memb}" || fc1=""
[ $memb -ge 0 ] && fc2="fc${memb}_" || fc2=""


#hardcoded parameters
#remap_grid="n128"

#global parameters

work_dir="/gpfs/scratch/bsc32/bsc032446/tmp/nemo_forcing"  # base work directory
echo $work_dir
#save_dir="$SCRATCH/ECEARTH-RUNS/OSM_FORCING" # base directory to save forcing 
save_dir="/gpfs/scratch/bsc32/bsc032446/NEMO_FORCING" # base directory to save forcing 
#forcing_raw_dir='/gpfs/projects/bsc32/bsc32144/ERA_FORCING'
#forcing_raw_dir='/gpfs/projects/bsc32/bsc032051/ERA_FORCING'               # base directory to get forcing
forcing_raw_dir="/gpfs/scratch/bsc32/bsc032446/ERA_FORCING"
#forcing_raw_dir='/gpfs/projects/bsc32/bsc032051/ERA_FORCING'

forcing_raw_subdir=true
copy_cmd="ln -sf "

if true ; then
set +x

# commented module load statements to adapt from mn4 to mn5

#module load intel/2018.3 impi/2018.3 mkl/2018.3
module load intel/2023.2.0 impi/2021.10.0 mkl/2023.2.0
#module load netcdf/4.2 hdf5/1.8.19 CDO/1.8.2 
module load hdf5 pnetcdf netcdf
#module load udunits/2.2.25 gsl/2.4
module load udunits gsl
#module load nco/4.2.3_netcdf-4.2
module load libexpat nco
#module load eccodes/2.8.0 python/2.7.13i
module load aec eccodes CDO
#module load fftw emoslib/4.5.7

unset GRIB_DEFINITION_PATH
unset GRIB_SAMPLES_PATH
unset GRIB_BIN_PATH
set -x
fi


##=====================================
# 0.2 - Generated variables 
nemo_forcing_dir=${save_dir}/${nemo_forcing_type} # output directory /year


vars_inst="t10 q10 u10 v10 slp"
vars_mean="qsw qlw snow precip"
#vars_inst="slp" # slp-only
#vars_mean=" " # slp-only
nemo_forcing_vars="${vars_inst} ${vars_mean}"
#nemo_forcing_vars="slp" # slp-only
#make sure the match if you change nemo_forcing_vars!
osm_forcing_vars="Tair Qair Wind_E Wind_N PSurf SWdown LWdown Snowf Rainf"
#osm_forcing_vars="PSurf"  # slp-only


##=====================================
# 1. Start work


for year in `seq $year1 $year2`
do

nemo_forcing_files="" #_era5-hres_1979.nc
nemo_forcing_files_grb="" #_era5-hres_1979.nc
if [ "$nemo_forcing_type" == "era5-enda" ] ; then for cvar in ${nemo_forcing_vars} ; do nemo_forcing_files+=" ${cvar}${fc1}_${nemo_forcing_type}-n160_${year}.nc " ; done ; fi
if [ "$nemo_forcing_type" == "era5-hres" ] ; then for cvar in ${nemo_forcing_vars} ; do nemo_forcing_files+=" ${cvar}${fc1}_${nemo_forcing_type}-n320_${year}.nc " ; done ; fi
if [ "$nemo_forcing_type" == "era5-old"  ] ; then for cvar in ${nemo_forcing_vars} ; do nemo_forcing_files+=" ${cvar}${fc1}_${nemo_forcing_type}-n128_${year}.nc " ; done ; fi
for cvar in ${nemo_forcing_vars} ; do nemo_forcing_files_grb+=" ${cvar}${fc1}_${nemo_forcing_type}_${year}.grb" ; done
echo $nemo_forcing_files

## check if files already exist:
ret=0
for ff in ${nemo_forcing_files}
do
  if [[ ! -r ${nemo_forcing_dir}/$ff ]]; then
    ret=1
  fi
done

if [[ $ret == 0 ]]; then
  echo "Files already present, skipping year $year"
else

# go to working directory
WDIR=${work_dir}/${nemo_forcing_type}/${year}${fc1}
mkdir -p $WDIR
cd $WDIR
rm -rfv *

expver=1
#temporary workaround for ERA5-BE only available with expver=98
#[[ "$year" < 1979 ]] && expver=98
#[[ "$year" < 1979 ]] && expver=98

# get data
#if false ; then
if true ; then
case $nemo_forcing_type in
  era5-hres ) get_forcing_era5 era5-hres $year forcing_ea_${expver}_oper_1_ 1 $frequency ${nemo_forcing_dir}/$year "$fc1" ;;
  era5-enda ) get_forcing_era5 era5-enda $year forcing_ea_${expver}_enda_3_ 3 $frequency ${nemo_forcing_dir}/$year "$fc1" ;;
  era5-old  ) get_forcing_era5 era5-hres $year forcing_ea_${expver}_oper_1_ 1 $frequency ${nemo_forcing_dir}/$year "$fc1" ;;
          #ftype='ML';Rainf_pp=False;Flx_acc=False
  *)     echo "nemo_forcing_type $nemo_forcing_type not coded!"
         exit 1;;
esac
fi

[ "$nemo_forcing_type" == "era5-old" ]  && convert_forcings "era5-hres" $year "n128" n128
[ "$nemo_forcing_type" == "era5-old" ]  && for file in *era5-hres-n128_????.nc ; do mv $file ${file//-hres/-old} ; done
[ "$nemo_forcing_type" == "era5-old" ]  && for file in *era5-hres_????.grb ; do mv $file ${file//-hres/-old} ; done

[ "$nemo_forcing_type" == "era5-enda" ] && convert_forcings "${fc2}${nemo_forcing_type}" $year "" n160
[ "$nemo_forcing_type" == "era5-hres" ] && convert_forcings "${fc2}${nemo_forcing_type}" $year "" n320

# move to final dir

mkdir -p ${nemo_forcing_dir}/grb
mv ${nemo_forcing_files} ${nemo_forcing_dir}
mv ${nemo_forcing_files_grb} ${nemo_forcing_dir}/grb

rm -rfv $WDIR

fi # $ret == 0

done #for year
