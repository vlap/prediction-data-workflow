#!/bin/bash
#SBATCH -n 96
#SBATCH -t 24:00:00
#SBATCH -J qlw_pre_perturbation
#SBATCH --constraint='highmem'
#SBATCH -o slurm_mkpert-%j.qlw.out
#SBATCH -e slurm_mkpert-%j.qlw.err

module load R
 
Rscript mkpert.new.qlw4.R
