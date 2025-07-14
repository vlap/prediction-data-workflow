#!/bin/bash
#SBATCH -n 1
#SBATCH -t 2:00:00
#SBATCH -J surforas5
#SBATCH -o surforas5-%j.out   
#SBATCH -e surforas5-%j.err


#module purge
module load CDO NCO
#module load CDO/1.9.10-foss-2019b
#module load NCO/4.9.2-foss-2019b
#module load OpenMPI/4.0.5-GCC-8.3.0-nord3-v2
 set -evx

year1=2024
year2=2025
memb1=0
memb2=4

#grid=ORCA025L75
grid=ORCA1L75

indir=/gpfs/projects/bsc32/repository/nudging/ocean/s5/
outdir=/gpfs/projects/bsc32/repository/surface_restoring/ocean/s5/
TEMP_DIR=/gpfs/projects/bsc32/repository/surface_restoring/ocean/s5/tmp2/
mkdir -p ${TEMP_DIR}

for year in `seq $year1 $year2` ; do
   echo ${year}
   for memb in `seq $memb1 $memb2` ; do
      cdo sellevidx,1 ${indir}/${grid}/fc0${memb}/s5_fc0${memb}_${year}.nc ${TEMP_DIR}/s5_fc0${memb}_${year}_surface.nc
      cdo select,name=votemper ${TEMP_DIR}/s5_fc0${memb}_${year}_surface.nc ${TEMP_DIR}/sst_tmp_fc0${memb}_${year}.nc
      cdo select,name=vosaline ${TEMP_DIR}/s5_fc0${memb}_${year}_surface.nc ${TEMP_DIR}/sss_tmp_fc0${memb}_${year}.nc
      cdo chname,votemper,thetao ${TEMP_DIR}/sst_tmp_fc0${memb}_${year}.nc ${TEMP_DIR}/sst_1m_data_fc0${memb}_${year}.nc
      cdo chname,vosaline,so ${TEMP_DIR}/sss_tmp_fc0${memb}_${year}.nc ${TEMP_DIR}/sss_1m_data_fc0${memb}_${year}.nc
      ncwa -O -a nav_lev ${TEMP_DIR}/sst_1m_data_fc0${memb}_${year}.nc ${outdir}/${grid}/fc0${memb}/sst_restore_data_y${year}.nc
      ncwa -O -a nav_lev ${TEMP_DIR}/sss_1m_data_fc0${memb}_${year}.nc ${outdir}/${grid}/fc0${memb}/sss_restore_data_y${year}.nc
      rm ${TEMP_DIR}/s5_fc0${memb}_${year}_surface.nc
      rm ${TEMP_DIR}/ss*_1m_data_fc0${memb}_${year}.nc
      rm ${TEMP_DIR}/ss*_tmp_fc0${memb}_${year}.nc
   done
done
