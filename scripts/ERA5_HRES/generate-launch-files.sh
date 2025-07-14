type=era5-hres  # era5-hres (n320) era5-old (n128) era5-enda (n160)

#for yr in {1950..1955}; do 
#for yr in {1985..1990}; do
for yr in {2000..2020}; do
    sed -e "s/YEAR/${yr}/g"  -e "s/TYPE/${type}/g" \
    launch-template-convert-forcings-nemo.sh > launch-convert-forcings-nemo.${type}.${yr}.sh ;
    sbatch launch-convert-forcings-nemo.${type}.${yr}.sh ;
done
