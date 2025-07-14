rm(list = ls())
graphics.off()
library(ncdf4)

# =============================================================================
# Author - François Massonnet
#      
#        - Juan C Acosta Navrro;  Vladimir Lapin
# Date   - 27 May 2021 Modified;  22 July 2022 Modified
#        - Adapted to handle ERA5 forcing data, using finer temporal and spatial resolution than DFS/ERA-Interim 
# Date   - 02 February 2016, Candelaria! 
#          https://es.wikipedia.org/wiki/Fiesta_de_la_Candelaria
#        - 22 June 2016: enhancement to make consistent perturbations across
#          several variables
#        - 1st July 2016: Simplification. It is indeed not necessary to do 
#          a SVD here. By multiplying the available perturbations by
#          z / sqrt(N - 1) we create data with the same cov. matrix.
#          See also M. Meinvielle's thesis:
#          https://hal.inria.fr/file/index/docid/681484/filename/24564_MEINVIELLE_2012_archivage.pdf
# Goal   - Create perturbed versions of the fields of ERA5 As many
#          perturbations as the user wants can be created, but they will remain
#          in the subspace spanned by the available perturbations (computed in
#          the first script preprocess.bash)
#          A seed is used to ensure reproducibility of perturbations.
#
# Input  - Files of perturbations must be available. They can be computed 
#          using the script preprocess.bash
# =============================================================================

strvar  <- c('qlw')     # Name of the variables for which perturbations
                                     # have to be created. 
fstrvar <- c('qlw')     # Matching name of the variable as they
                               # appear in the NetCDF
                               # Normally equal to strvar, except 
                               # qsw --> radsw and qlw --> radlw

# The folder where the perturbations are (the folder was created during
# the execution of preprocess.bash)
#pertdir <- c('/esarchive/scratch/vlapin/tmp/TMP_qlw')
pertdir <- c('/gpfs/scratch/bsc32/bsc32446/tmp/TMP_qlw')

yearbp <- 1959 # The years defining the time period used 
               # to compute perturbations. That is, the reference period from
               # which variability is estimated. 
yearep <- 2020 # That period must be included in the period for which perturbations were
               # created (in preprocess.bash)

yearb  <- 1980 # The years for which a new perturbation has to be calculated
yeare  <- 2021 # Can be outside the interval above 

npert <-  5   # Number of perturbations that have to be created each year


# ---------------------------------------------
# Script starts -------------------------------
# ---------------------------------------------

nvar  <- length(strvar)

nyearp <- yearep - yearbp + 1 # Number of years for the reference period
nyear  <- yeare  - yearb  + 1 # Number of years for which to create perturbations

nsamp <- nyearp - 1          # Number of perturbations samples available. 
                             # Since we create 
                             # the perturbations as successive year-to-year diffs,
                             # we have one less than the number of years

for (jvar in seq(1, nvar)) {
  print(paste("Working on variable", strvar[jvar]))
  # 1/ Recording the perturbations from the available sample
  # --------------------------------------------------------
  for (year in seq(yearbp + 1, yearep)) {
    print(paste("  Reading data:", year, "-", year - 1))
    filein <- paste(pertdir[jvar], "/", "diff_", strvar[jvar], "_era5_day_", year, 
                  "-", year - 1, ".nc", sep = "")
 #   f <- open.ncdf(filein, mode = 'r')
    f <- nc_open(filein)
 #   var <- get.var.ncdf(f, fstrvar[jvar])
     print(f,fstrvar[jvar])
     var <- ncvar_get(f, fstrvar[jvar])
    if (year == yearbp + 1) {
    # If we are in the first year
    # let's also create the matrix that will receive the data

      ny <- dim(var)[1]
      nx <- dim(var)[2]
      nt <- dim(var)[3]

      ns <- ny * nx * nt # state vector dimension
  
#      lat <- get.dim.ncdf(f, 'lat')
#      lon <- get.dim.ncdf(f, 'lon')
  
      lon <- seq(1,1280)
      lat <- seq(1,640) 
  
      print("    Creating X_raw, this has to be done only once")
      X_raw <- matrix(NA, ns, nsamp)
      print("    X_raw created")
    } # if
   #   close.ncdf(f)
      nc_close(f)
      var[is.na(var)] <- 0
      # This last step is necessary, because the DFS5.2 forcing set has, sometimes,
      # NaNs. (See e.g., year 2008, variable t2, time step 1776, in the Southern)

      X_raw[, year - (yearbp + 1) + 1] <- var[]

      rm(list = "var")
    } # year

    # Centering X
    # -----------
    print("Centering the data")
    myones <- matrix(1, nrow = nsamp, ncol = 1)

    Xbar <- 1 / nsamp * X_raw %*% myones
    X    <- X_raw - Xbar %*% t(myones)

    # Clearing X_raw and Xbar, as they are taking resources!
    rm(list = c("X_raw", "Xbar", "myones"))
  
    print("Data centered")


    # Creating perturbations
    # ----------------------
    # We take a N(0,1) random vector z of size nsamp by 1
    # so that the product X %*% z / sqrt(nsamp - 1)
    # will give us a new perturbation
    # with the desired properties

    print("Creating perturbations")

    for (year in seq(yearb, yeare)) {
      print(paste("Recording perturbations for variable", strvar[jvar], "and year", year))
  
      for (jpert in seq(1, npert)) {
        print(paste("  Recording perturbation for member", sprintf("%02d", jpert)))

        # EXTREMELY IMPORTANT - this ensures reproducibility. DON'T CHANGE.
        # if year 1987, and perturbation 302:
        # then the seed is 1000 * 1987 + 302 = 1987302. 
        # This is then a unique identifier. It won't be unique if we go beyond 999 
        # members, but I might no longer be on this planet when that happens.
        #
        # In addition the value of z must be the same for all variables to have coherent
        # perturbations
        set.seed(year * 1000 + jpert)

        z <- matrix(rnorm(nsamp))
        sample <- array(X %*% z / sqrt(nsamp - 1), c(ny, nx, nt))
        print("First and last elements of perturbation: ")
        print(z[1])
        print(z[nsamp])
        rm(list = "z")

        # Record in  NetCDF
        # ----------------
        # 1/ Create dimensions
        # --------------------
        dimt <- ncdim_def('time', 'time', seq(1, nt), unlim = TRUE)
        dimy <- ncdim_def('lat', 'lat', lat)
        dimx <- ncdim_def('lon', 'lon', lon)

        # 2/ Define variables
        # -------------------
        mylist <- list()
        mylist[[1]] <-  ncvar_def(fstrvar[jvar], '-', list(dimx,dimy,dimt), -1e24)
    
        # 3/ Create NetCDF
        # ----------------
        fileout <- paste(pertdir[jvar], '/pert_', strvar[jvar], '_era5_', year, '_fc', sprintf("%02d", jpert), '_ref', yearbp, '-', yearep, '.nc', sep = "")
        fo <- nc_create(fileout, mylist)
        nc_close(fo)

        # 4/ Open it
        # ----------
        fo <- nc_open(fileout, write = TRUE)

        # 5/ Put variable
        # ---------------
        ncvar_put(fo, fstrvar[jvar], sample)

        # 6/ Close it
        # -----------
        nc_close(fo)

        print(paste(fileout, "created"))

        # 7/ Clear workspace
        # ------------------
        rm(list = "sample")
    } # jpert
  } # year 
} # var
