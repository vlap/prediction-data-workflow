#!/bin/bash
#SBATCH -n 1
#SBATCH -t 48:00:00
#SBATCH -J remaporas5
#SBATCH -o remaporas5-%j.out   
#SBATCH -e remaporas5-%j.err

set -exv
module load CDO

year1=1960              # 2022
year2=1978              # 2022
memb1=0
memb2=0

orcagrid1=/esarchive/scratch/vlapin/cdo_griddes_files/orca1_grid
orcagrid025=/esarchive/scratch/vlapin/cdo_griddes_files/orca025_grid

if [[ ! -f genbil_orca025_orca1.nc ]]; then
# Generate the map weights
cdo genbil,${orcagrid1} -setgrid,${orcagrid025} /gpfs/projects/bsc32/repository/nudging/ocean/s5/ORCA025L75/fc${memb1}/s5_fc${memb1}_${year1}.nc genbil_orca025_orca1.nc
fi

for year in `seq $year1  $year2` ; do
   for memb in `seq $memb1  $memb2` ; do
   cdo -L -setmisstoc,0 -remap,${orcagrid1},genbil_orca025_orca1.nc -fillmiss2 -setctomiss,0 -setgrid,${orcagrid025} /gpfs/projects/bsc32/repository/nudging/ocean/s5/ORCA025L75/fc${memb}/s5_fc${memb}_${year}.nc /gpfs/projects/bsc32/repository/nudging/ocean/s5/ORCA1L75/fc0${memb}/s5_fc0${memb}_${year}.nc ;  
   done ; 
done
