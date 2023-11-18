function [ smb_ref ] = load_smb_ref( md )
%LOAD_SMB_REF Get smb_ref for md mesh
%   reads in the smb reference period from netcdf (RACMO)
%   and interpolates onto the model mesh
%   Jan 1960 - Dec 1989
%   Converts units from mm/month w.e. to m/yr ice equivalent

   smb_dir = '/Users/dfelikso/Research/Data/RACMO/RACMO2.3/originalData/downscaled';
   x    = ncread([smb_dir '/smb_rec.2007.BN_RACMO2.3p2_ERA5_3h_FGRN055.1km.MM.nc'],'x'); % despite name in netcdf, it isn't actually lat and lon, but projected x y
   y    = ncread([smb_dir '/smb_rec.2007.BN_RACMO2.3p2_ERA5_3h_FGRN055.1km.MM.nc'],'y');

   ncsmb='/Users/dfelikso/Research/Data/RACMO/RACMO2.3/originalData/downscaled/smb_rec.1958-2017.BN_RACMO2.3p2_FGRN055_GrIS.MM.nc';
   % 30 years from Jan 1960 - Dec 1989:
   smb   = (sum(ncread(ncsmb,'SMB_rec',[1 1 25],[Inf Inf 360]),3)/30)'; % sum monthly data and divide by number of years
   disp('   Interpolate 1960-1989 mean SMB onto model mesh');
   % Interpolate onto model mesh
   smb_ref=InterpFromGridToMesh(x,y,smb,md.mesh.x,md.mesh.y,0);
   % convert mm/yr to m/yr of ice equivalent
   smb_ref=(smb_ref*md.materials.rho_freshwater/md.materials.rho_ice)/1000; %to get m/yr ice equivalent


end

