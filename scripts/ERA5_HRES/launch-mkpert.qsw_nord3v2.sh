#!/bin/bash
#SBATCH -n 96
#SBATCH -t 24:00:00
#SBATCH -J qsw_pre_perturbation
#SBATCH --constraint='highmem'
#SBATCH -o slurm_mkpert-%j.qsw.out
#SBATCH -e slurm_mkpert-%j.qsw.err

module load R
 
Rscript mkpert.new.qsw4.R
