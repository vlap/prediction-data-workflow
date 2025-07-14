#!/bin/bash
#SBATCH -n 96
#SBATCH -t 24:00:00
#SBATCH -J t10_pre_perturbation
#SBATCH --constraint='highmem'
#SBATCH -o slurm_mkpert-%j.t10.out
#SBATCH -e slurm_mkpert-%j.t10.err

module load R
 
Rscript mkpert.new.t104.R
