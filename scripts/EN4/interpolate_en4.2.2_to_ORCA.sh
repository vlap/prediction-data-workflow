#!/bin/bash

#BSUB -n 1
#BSUB -J interpolate_EN4.2.2
#BSUB -W 10:00
#BSUB -o ../logs/output_%J.out
#BSUB -e ../logs/output_%J.err


# Original: Francois Massonnet, 2016
# Adapted : Vladimir Lapin, 2019
#
# Interpolation of EN4.2.2 to ORCA grid

module load NCO CDO
module load sosie

set -x
set -o nounset
set -o errexit

#yearb=1951    # Years to process
#yeare=1979
yearb=2024
#yearb=1957
yeare=2025

grid=ORCA1    # Grid type
#grid=ORCA025

#sosiedir=/scratch/sosie/bin

mask=/esarchive/autosubmit/con_files/mesh_mask_nemo.Ec3.2_O1L75.nc
#mask=/esarchive/autosubmit/con_files/mesh_mask_nemo.Ec3.3_O25L75.nc
sourcedir=/esarchive/obs/ukmo/en4-v4.2.2/monthly_mean # Where original files are located
#outdir=/esarchive/releases/nudging/ocean/en4-v4.2.2/${grid}L75/fc0
outdir=/gpfs/projects/bsc32/repository/nudging/ocean/en4-v4.2.2/${grid}L75/fc0

scratchdir=/esarchive/scratch/$USER/tmp

# Create a directory to work
# --------------------------
tmpdir=$scratchdir/TMP_${RANDOM}

echo "TMPDIR IS >>>>>> $tmpdir <<<<<<<"
mkdir -p $tmpdir
cp namelist_en4.2.2* $tmpdir

cd $tmpdir

# Link sosie
#ln -sf $sosiedir/sosie3.x .

# 1. Get the model grid and the mask
if [ ! -f ${mask} ]
then
	echo "${mask} does not exist."
	exit
fi

ln -sf ${mask} mask_out.nc 

listvars3d=('thetao' 'so' )

for year in `seq ${yearb} ${yeare}`
do

      for var in ${listvars3d[@]}
      do

      for mon in $(seq -w 01 12)
      do

      echo "Doing ${var} y=${year} m=${mon}!"

        # Select year from the original monthly file
        ln -s $sourcedir/${var}/${var}_${year}${mon}.nc filein.nc

        # Interpolation of sea ice concentrations
        sed -e "s/TTAARRGGEETT_GRID/${grid}/" \
            -e "s/TTAARRGGEETT_FILE/filein.nc/" \
            -e "s/TTAARRGGEETT_MESHMASK/mask_out.nc/" \
            -e "s/TTAARRGGEETT_VAR/${var}/" \
            -e "s/OOUUTT_VAR/${var}/" \
            -e "s/OOUUTT_EXTRA/${year}${mon}/" \
                namelist_en4.2.2_${var} > namelist
        
#        ./sosie3.x -f namelist
        sosie3.x -f namelist
        rm -f filein.nc namelist

       done # for each month

       cdo cat "${var}*_${year}??.nc" ${var}_${year}.nc
       rm -f ${var}*_${year}??.nc

       done # for each var

cdo -L -merge -subc,273.15 -chname,thetao,votemper thetao_${year}.nc -chname,so,vosaline \
          so_${year}.nc temp_votemp_${year}.nc

#ncks -v    thetao thetao_${year}.nc temp_votemp_${year}.nc
#ncks -A -v so so_${year}.nc         temp_votemp_${year}.nc
#ncrename -v thetao,votemper -v so,vosaline temp_votemp_${year}.nc

#final_file=en4.2.2_fc0_${year}.nc
final_file=temp_sal_y${year}.nc
mv temp_votemp_${year}.nc $final_file
ssh bsc032446@transfer1 dtmv /gpfs/archive/bsc32/${tmpdir}/${final_file} ${outdir}/

# Do a bit of cleaning here!
rm -f thetao_${year}.nc so_${year}.nc # temp_votemp_${year}.nc

done # for each year
