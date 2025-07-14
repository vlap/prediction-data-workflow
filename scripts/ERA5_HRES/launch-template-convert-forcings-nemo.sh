#!/usr/bin/env bash

#SBATCH -J convert.TYPE.YEAR
#SBATCH -N 1
#SBATCH -o slurm_convert.TYPE.YEAR.%j.out
#SBATCH -e slurm_convert.TYPE.YEAR.%j.err

# #SBATCH -t 12:00:00
#SBATCH -t 02:00:00
# #SBATCH --exclusive
#SBATCH -q debug
# #SBATCH -p interactive

bash ./convert-forcings-nemo.sh TYPE YEAR YEAR 3
#bash ./convert-forcings-nemo.sh era5-hres 2022 2022 3
#bash ./convert-forcings-nemo.sh era5-old  1990 1990 3
#bash ./convert-forcings-nemo.sh era5-enda 1980 2019 3 0
