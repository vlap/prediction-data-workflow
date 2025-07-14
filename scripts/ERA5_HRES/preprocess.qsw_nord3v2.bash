#!/bin/bash
#SBATCH -n 16
#SBATCH -t 20:00:00
#SBATCH -J qsw.pre_perturbation
#SBATCH --constraint='highmem'
#SBATCH -o slurm_pre-%j.qsw.out
#SBATCH -e slurm_pre-%j.qsw.err

# run on nord3v2 with sbatch

set -o nounset
set -o errexit
set -x

# =============================================================================
# Author - F. Massonnet
# Changed by JC. Acosta N; V. Lapin
# Purpose- Prepare era5 forcing set to create perturbations later
# What the script does:
#   1) Make daily means in the case atmospheric data is at higher frequency
#   2) Remove leap days if any
#   3) Computes year-to-year differences
#
# The year-to-year differences are then used to generate perturbations,
# in a second script.
#
# History - February 2016: creation for T2 perturbation
#         - March    2016: sorting problems with values beyond bounds
#         - April    2016: extension to other variables

# =============================================================================

# Which variable of the ERA5 forcing set has to be perturbed?
# Possibilities: t2, q2, u10, v10, qlw, qsw, snow or precip
var=qsw

# Years defining the period considered. If perturbations have to be generated
# for 1980-1990 but based on anomalies of the period 1975-1985, the longest
# period has to be set: 1975-1990
#
# yearb = 1979 and yeare = 2015 are recommended choices since the forcing
# spans these years and all variables are interannual

yearb=1959
yeare=2021

# Directory of the source of the data (i.e., the original files)
#sourcedir=/esarchive/scratch/jacosta/TMP/Interp_ERA/ERA5_HR_LowPert
sourcedir=/esarchive/scratch/vlapin/Interp_ERA/ERA5_HR

# Working directory
#workdir=/esarchive/scratch/jacosta/TMP/TMP_${var}_101
workdir=/esarchive/scratch/vlapin/tmp/TMP_${var}

# =============================================================================
# Script Starts
# =============================================================================

mkdir -p $workdir
cd    $workdir
echo "Workdir is $workdir"

case ${var} in 
  t10)
    min=100.0 	# Min and max values allowed
    max=400.0
    freq=3hour  # Frequency of availability
    fvar=${var} # Name of the variable in the NetCDF
    ;;
  q10)
    min=0.0
    max=0.1
    freq=3hour
    fvar=${var}
    ;;
  u10)
    min=-100.0
    max=100.0
    freq=3hour
    fvar=${var}
    ;;
  v10)
    min=-100.0
    max=100.0
    freq=3hour
    fvar=${var}
    ;;
  qsw)
    min=0.0
    max=2000.0
    freq=3hour
    fvar=${var}
    ;;
  qlw)
    min=0.0
    max=2000.0
    freq=3hour
    fvar=${var}
    ;;
  snow)
    min=0.0
    max=0.001
    freq=3hour
    fvar=${var}
    ;;
  precip)
    min=0.0
    max=0.01
    freq=3hour
    fvar=${var}
    ;;
  *)
  echo "Variable $var unknown"
  exit
esac

for year in `seq ${yearb} ${yeare}`
do
  echo "Year $year / $yeare"

  # Reset valid range. Otherwise, the CDO command settaxis messes up and several points are reported as 
  # missing values. This then makes NEMO crash.
  ncatted -O -a valid_range,${fvar},m,f,"${min}, ${max}" ${sourcedir}/${var}_era5_${year}.nc tmp.${year}.nc 
  
  if [ $year -eq 1980 ] || [ $year -eq 1984 ] || [ $year -eq 1988 ] || [ $year -eq 1992 ] || [ $year -eq 1996 ] || [ $year -eq 2000 ] || [ $year -eq 2004 ] || [ $year -eq 2008 ] || [ $year -eq 2012 ] || [ $year -eq 2016 ] || [ $year -eq 2020 ]  || [ $year -eq 2024 ] 
  then 
    cdo -L -settaxis,${year}-01-01,00:00,${freq} -seltimestep,1/2928 tmp.${year}.nc ${var}_era5_${year}.nc
  else
    cdo -L -settaxis,${year}-01-01,00:00,${freq} -seltimestep,1/2920 tmp.${year}.nc ${var}_era5_${year}.nc
  fi

  if [ ${freq} = 3hour ]
  then
    cdo daymean ${var}_era5_${year}.nc ${var}_era5_day_${year}.nc
  else
    cp ${var}_era5_${year}.nc ${var}_era5_day_${year}.nc
  fi

  # Cope with leap years
  ndays=`cdo ntime ${var}_era5_day_${year}.nc`

  if [[ $ndays = 366 ]]
  then
    cdo delete,month=2,day=29 ${var}_era5_day_${year}.nc ${var}_era5_day_${year}.nc.X
    mv ${var}_era5_day_${year}.nc.X ${var}_era5_day_${year}.nc
  else
    if [[ $ndays != 365 ]]
    then
      echo "Problem: nb of days is neither 365 nor 366"
      exit
    fi  
  fi

  if [[ $year -ge $(( ${yearb} + 1 )) ]]
  then
    cdo sub ${var}_era5_day_${year}.nc ${var}_era5_day_$(( ${year} - 1 )).nc diff_${var}_era5_day_${year}-$(( ${year} - 1 )).nc
  fi

  rm -f tmp.${year}.nc
done


echo "SCRIPT SUCCESSFULLY FINISHED"
