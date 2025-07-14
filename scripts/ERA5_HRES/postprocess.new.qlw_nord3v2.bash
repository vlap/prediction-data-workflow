#!/bin/bash
#SBATCH -n 16
# #SBATCH -t 48:00:00
# #SBATCH -n 1
#SBATCH -t 1:30:00
#SBATCH -J qlw_post_perturbation
# #SBATCH --qos='debug'
#SBATCH --constraint='medmem'
#SBATCH -o slurm_post-%j.out
#SBATCH -e slurm_post-%j.err

# run on nord3v2 with sbatch

module load NCO CDO

set -o nounset
set -o errexit
set -x

# -----------------------------------------------------------------------------
# Author - F. Massonnet
#        - J.C. Acosta Navarro, V. Lapin (Adapted to handle ERA5)     
# Purpose- Process perturbations of ERA5 forcing and adds them
#          to the actual forcing. 
# What the script does:
#   1) Interpolate from daily to 3hourly
#   2) Add 29 February if necessary
#   3) Add to the true forcing
# -----------------------------------------------------------------------------

# Which variable of the ERA5 forcing set has to be perturbed?
# Possibilities: t2, q2, u10, v10, qlw, qsw, snow or precip
var=qlw

alpha=0.3333333 # VERY IMPORTANT: strength of the perturbation. 1 = same as interannual variability. 0.5 = half of it.

# First and end years for which a perturbation has to be created. 
#yearb=1959
#yeare=2021
yearb=2024
yeare=2024

yearbp=1959    # First and end years defining the reference period on which
yearep=2020    # the perturbations were created (must match those in preprocess.bash and in mkpert.R)

nmb=1   # members to loop over. nmb = first member; nme = last one.
        # Usually the first member ("fc0") is the true forcing so it should *NOT* be perturbed.
        # Hence put nmb=1 and nme=25 if you want 25 perturbed forcings
nme=5  

#workdir=/esarchive/scratch/jacosta/TMP/TMP_${var}_101/
workdir=/esarchive/scratch/vlapin/tmp/TMP_${var}  # Where all perturbations are recorded
                                                # This folder was defined during the execution of preprocess.bash

outtag=era5                                   # Name of the forcing after perturbations are created
                                                # Can be the same (ERA5) or modified (perturbed-ERA5 for instance)
#outdir=/esarchive/scratch/jacosta/TMP/Interp_ERA/ERA5_HR_LowPert/
outdir=/esarchive/scratch/vlapin/Interp_ERA/ERA5_HR

cd $workdir
echo "Workdir is $workdir"

case ${var} in
  t10)
    min=100.0 	# Min and max values allowed
    max=400.0
    freq=3hour  # Frequency of availability
    ntim=2920   # Number of time steps in a year
    fvar=${var} # Name of the variable in the NetCDF
    ;;
  q10)
    min=0.0
    max=0.1
    freq=3hour
    ntim=2920
    fvar=${var}
    ;;
  u10)
    min=-100.0
    max=100.0
    freq=3hour
    ntim=2920
    fvar=${var}
    ;;
  v10)
    min=-100.0
    max=100.0
    freq=3hour
    ntim=2920
    fvar=${var}
    ;;
  qsw)
    min=0.0
    max=2000.0
    freq=3hour
    ntim=2920
    fvar=${var}
    ;;
  qlw)
    min=0.0
    max=2000.0
    freq=3hour
    ntim=2920
    fvar=${var}
    ;;
  snow)
    min=0.0
    max=0.001
    freq=3hour
    ntim=2920
    fvar=${var}
    ;;
  precip)
    min=0.0
    max=0.01
    freq=3hour
    ntim=2920
    fvar=${var}
    ;;
  *)
  echo "Variable $var unknown"
  exit
esac

for year in `seq ${yearb} ${yeare}`
do
  for mm in `seq $nmb $nme`
  do
    if [ $mm == 0 ] 
    then
      echo "WARNING!!!!"
      echo "Usually, at BSC, member 0 is booked to point towards the true forcing"
      echo "By creating a perturbed forcing named fc00, and then copying to the source"
      echo "directory, you are going to erase a symbolic link that points to the true forcing"
      echo "and thereby erase the true forcing!!"
      echo "Since this is highly dangerous, this script is aborting."
      echo "Contact francois.massonnet@bsc.es for further questions"
  
      exit
    fi

    m=$(printf "%02d" $mm)

    mm1=$((mm))
    m1=$(printf "%02d" $mm1)

    # There is a small trick here. If we have 3 days of data and ask for 3-hourly interpolation, we will have only 17 points and not 24.
    # We have in fact (ndays - 1) * 8 + 1. So the trick is to append the last day to the data twice and remove the last time frame.
    # 
    # Extract the last time frame
    ncks -F -O -d time,365,365              pert_${var}_era5_${year}_fc${m}_ref${yearbp}-${yearep}.nc  tmp.${year}.${m}.nc
    # Append it 
    ncrcat -F -O                            pert_${var}_era5_${year}_fc${m}_ref${yearbp}-${yearep}.nc  tmp.${year}.${m}.nc pert_${var}_era5_${year}_fc${m}.nc.1
    # Set time axis
    cdo -L settaxis,${year}-01-01,00:00,1day   pert_${var}_era5_${year}_fc${m}.nc.1                       pert_${var}_era5_${year}_fc${m}.nc.2
    # Interpolate in time
    cdo -L inttime,${year}-01-01,00:00,${freq} pert_${var}_era5_${year}_fc${m}.nc.2                       pert_${var}_era5_${year}_fc${m}.nc.3
    # Remove the last time frame
    ncks -F -O -d time,1,${ntim}            pert_${var}_era5_${year}_fc${m}.nc.3                       pert_${var}_era5_${year}_fc${m}.nc.4

    # Add the desired fraction "alpha" of the perturbation to the true forcing
    cdo add -mulc,${alpha}                  pert_${var}_era5_${year}_fc${m}.nc.4   ${outdir}/${var}_era5_${year}.nc ${var}_fc${m}_era5_${year}.nc.0
    
    # Physical bounds
    cdo setrtoc,-10000000000,${min},${min}  ${var}_fc${m}_era5_${year}.nc.0                            ${var}_fc${m}_era5_${year}.nc.1 
    cdo setrtoc,${max},10000000000,${max}   ${var}_fc${m}_era5_${year}.nc.1                            ${var}_fc${m}_era5_${year}.nc.2

    # Set time units to allow nice reading
    cdo -f nc4c -z zip_2 settunits,years    ${var}_fc${m}_era5_${year}.nc.2                            ${outdir}/${var}_fc${m1}_${outtag}_${year}.nc

    # Add description in the header
    ncatted -O -a description,${fvar},a,c,"Perturbed version of ERA-interim variable ${fvar} for year ${year} (member fc${m}). Strength of perturbation is ${alpha} times the year-to-year differences estimated over the ${yearbp}-${yearep} reference period. For more details: francois.massonnet@bsc.es" ${outdir}/${var}_fc${m1}_${outtag}_${year}.nc

    chmod 644 ${outdir}/${var}_fc${m1}_${outtag}_${year}.nc

    rm -f tmp.${year}.${m}.nc pert_${var}_era5_${year}_fc${m}.nc.? ${var}_fc${m}_era5_${year}.nc.?
  done
done


echo "SCRIPT POSTPROCESS.BASH FINISHED"
