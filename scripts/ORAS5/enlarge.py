## Python script to enlarge the nudging files from their ORCA025L75 grid to the EC.Earth3.3 ORCA025L75 grid.
## Script adapted from the enlarge.py created by T.Arzouse for CTE-POWER
## 
## To run on Nord3_v2 after loading these modules (cf launcher_enlarge_nord3v2.sh)
# module load Python/3.7.4-GCCcore-8.3.0
# module load netcdf4-python/1.5.8-foss-2019b-Python-3.7.4
# module load xarray/0.19.0-foss-2019b-Python-3.7.4
# module load OpenMPI/4.0.5-GCC-8.3.0-nord3-v2 #temporarily?


import xarray as xr
import numpy as np
import os.path
from datetime import datetime
import sys


#outpath = '/esarchive/scratch/Earth/acarreri/extrapolate_ORAS5_to_ORCA025/output/'
outpath = '/gpfs/projects/bsc32/repository/nudging/ocean/s5/tmp/'
print(outpath)
mask_file = '/esarchive/autosubmit/con_files/mesh_mask_nemo.Ec3.3_O25L75.nc'

def generate_extrapolation(fname, vname):
#    ds_mask = xr.open_dataset(mask_file).rename({'z':'nav_lev'})
    ds_mask = xr.open_dataset(mask_file)
#    print('mesh mash', ds_mask)
#    ds_oras5 = xr.open_dataset(fname).rename({'deptht':'nav_lev'}) 
    ds_oras5 = xr.open_dataset(fname)
#    print(ds_oras5)
    print('Variable:', vname)
    # select variable
    var_os5 = ds_oras5[vname]
    print(var_os5.shape)
    # (12, 75, 1021, 1442)
    print(ds_mask.tmask.shape)
    # (1, 75, 1050, 1442) = final goal

    # create the output dataset
    values = np.empty((ds_oras5.dims['time'], ds_oras5.dims['nav_lev'], ds_mask.dims['y'],ds_mask.dims['x']))
    ds_out = xr.DataArray(
        data=values,
        coords=dict(nav_lon=(['y','x'],ds_mask.nav_lon.values),
        nav_lat=(['y','x'],ds_mask.nav_lat.values),
        nav_lev=(['nav_lev'],ds_mask.nav_lev.values),
        time=(['time'],ds_oras5.time.values)),
        dims=['time','nav_lev','y','x'],
        name=vname)
    
    # extrapolate on land, only for Antarctic case : if find a nan value, then copy the value from the line above.
    # Aude: not sure about what is doing this line! What do we need to fill the NaN of oras5? Does it even work? 
    # It's 0 value in the masked lands.
    for j in range(250,0,-1):
        var_os5[:,:,j,:]=xr.where(np.isnan(var_os5[:,:,j,:]),var_os5[:,:,j+1,:],var_os5[:,:,j,:])
    print(np.shape(var_os5))
    # affect to new field on ORCA025
    ds_out[:,:,29:,:]=var_os5*ds_mask.tmask[0,:,29:,:].where(ds_mask.tmask[0,:,29:,:]==1)
    # expend to full ORCA025 grid
    for i in range(1,30):
        ds_out[:,:,i,:]=var_os5[:,:,1,:]*ds_mask.tmask[0,:,i,:].where(ds_mask.tmask[0,:,i,:]==1)
    
    # try with the time attributs by default in the initial ORAS5_ORCA025 netcdf
    # without saying anything for the time dimension, the CDO command line then keeps only one time step
    ds_out.time
    
    # add history and save the netcdf output
    ds_out = ds_out.to_dataset()
    history = ds_oras5.attrs['history']
    now = datetime.now()
    call_str = " ".join(sys.argv)
    history = (now.strftime("%a %b %d %H:%M:%S %Y") + ": {}\n".format(call_str) + history)
    ds_out.attrs['history'] = history
    oname = os.path.join(outpath, (os.path.basename(fname).split(".")[0] + "_" + vname + ".nc"))
    ds_out.to_netcdf(oname, unlimited_dims='time')

    ds_mask.close()
    ds_oras5.close()


if __name__ == '__main__':
    import sys
    fname = sys.argv[1]
    vname = sys.argv[2]
    generate_extrapolation(fname, vname)
