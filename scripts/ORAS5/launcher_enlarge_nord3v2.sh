#!/bin/bash
#SBATCH -n 16  # ask rather for memory?
#SBATCH -t 03:00:00
# #SBATCH -t 02:00:00
# #SBATCH --qos=debug
#SBATCH -J extrapol_oras5
#SBATCH --constraint=highmem
#SBATCH -o extrapol_oras5-%j.out   
#SBATCH -e extrapol_oras5-%j.err


module purge
module load Python/3.7.4-GCCcore-8.3.0
module load netcdf4-python/1.5.8-foss-2019b-Python-3.7.4
module load xarray/0.19.0-foss-2019b-Python-3.7.4  #tester same as xarray/0.11.2-foss-2018b-Python-2.7.15
# module load numpy/1.20.2-foss-2019b-Python-3.7.4 #loaded by default with xarray
module load OpenMPI/4.0.5-GCC-8.3.0-nord3-v2

year1=2021
year2=2023
memb1=0
memb2=4

#IN_DIR=/esarchive/releases/nudging/ocean/s5/ORCA025L75_ORAS5
IN_DIR=/gpfs/projects/bsc32/repository/nudging/ocean/s5/ORCA025L75_ORAS5
#TEMP_DIR=/esarchive/scratch/Earth/acarreri/extrapolate_ORAS5_to_ORCA025/output
TEMP_DIR=/gpfs/projects/bsc32/repository/nudging/ocean/s5/tmp/
#ES_DIR=/esarchive/releases/nudging/ocean/s5/ORCA025L75
ES_DIR=/gpfs/projects/bsc32/repository/nudging/ocean/s5/ORCA025L75

SCRIPT_DIR="/esarchive/scratch/vlapin/git/cpg-shared-tools/Generation of ICs/Interpolation tools/"

for vname in votemper vosaline
do
    for year in `seq $year1 $year2` ; do
    echo ${year}
    for memb in `seq $memb1 $memb2` ; do
        time python "$SCRIPT_DIR"/enlarge.py ${IN_DIR}/fc${memb}/s5_fc${memb}_${year}.nc $vname
    done
    done
wait
done

# DO NOT LOAD CDO BEFORE, WILL COMPETE WITH HDF5: DUE TO OPENMPI?
module load CDO/1.9.10-foss-2019b
for year in `seq $year1 $year2` ; do
    echo ${year}
    for memb in `seq $memb1 $memb2` ; do
        cdo -L -b 32 merge -setmisstoc,0 -setmissval,NaN ${TEMP_DIR}/s5_fc${memb}_${year}_votemper.nc -setmisstoc,0 -setmissval,NaN ${TEMP_DIR}/s5_fc${memb}_${year}_vosaline.nc ${ES_DIR}/fc${memb}/s5_fc${memb}_${year}.nc
    done
done



# test only one for no
# to do: loop over year and member
#time python /esarchive/scratch/Earth/acarreri/scripts/scripts_bash/extrapolate_ORAS5_to_ORCA025/enlarge.py /esarchive/releases/nudging/ocean/s5/ORCA025L75_ORAS5/fc0/s5_fc0_2018.nc vosaline
#wait 

## After finishing this script, type the following to move the files to rhe right directory:
# in nord3_v2
# module load CDO/1.9.10-foss-2019b
# warning: -L mandatory to avoid HDF error
# cdo    merge (Warning): Using a non-thread-safe NetCDF4/HDF5 library in a multi-threaded environment may lead to erroneous results!
# cdo    merge (Warning): Use a thread-safe NetCDF4/HDF5 library or the CDO option -L to avoid such errors.
# cdf_get_vara_double: ncid=65536  varid=4  start[0]=0  count[0]=1
#  Error (cdf_get_vara_double): NetCDF: HDF error

# cdo -L -b 32  merge -setmisstoc,0 -setmissval,NaN s5_fc0_2018_votemper.nc -setmisstoc,0 -setmissval,NaN s5_fc0_2018_vosaline.nc s5_fc0_2018.nc
## for i in `seq 1958 2017` ; do echo cdo -b 32 merge   -setmisstoc,0 -setmissval,NaN  s5_fc0_${i}_votemper.nc  -setmisstoc,0 -setmissval,NaN   s5_fc0_${i}_vosaline.nc /esarchive/releases/nudging/ocean/s5/ORCA025L75/{MEMBER}/s5_fc0_${i}.nc; done

