#!/bin/bash

module load wget
set -vx

DATES=%DATELIST%

for date in ${DATES[@]}; do
	y=$(echo $date | cut -c1-4)
	m=$(echo $date | cut -c5-6)

cd /esarchive/obs/ukmo/en4-v4.2.2/original_files

if [[ ! -f EN.4.2.2.analyses.g10.${y}.zip ]]; then
    wget -nc https://www.metoffice.gov.uk/hadobs/en4/data/en4-2-1/EN.4.2.2.analyses.g10.${y}.zip
    no | unzip EN.4.2.2.analyses.g10.${y}.zip
fi

if [[ ! -f EN.4.2.2.p.analysis.g10.${y}${m}.nc.gz ]];then
    wget -nc https://www.metoffice.gov.uk/hadobs/en4/data/en4-2-1/EN.4.2.2.p.analysis.g10.${y}${m}.nc.gz
    no | gunzip EN.4.2.2.p.analysis.g10.${y}${m}.nc.gz
fi


done
