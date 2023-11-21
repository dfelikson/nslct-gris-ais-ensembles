function [ smb_anomaly ] = load_smb_anomaly( md, cmip, startyr, endyr)
%LOAD_SMB_ANOMALY Load the projected smb_anomaly
%   
%   cmip5 simulation options:
%       - ACCESS1.3-rcp85
%       - CSIRO-Mk3.6-rcp85
%       - HadGEM2-ES-rcp85
%       - IPSL-CM5-MR-rcp85
%       - MIROC5-rcp26
%       - MIROC5-rcp85
%       - NorESM1-rcp85

    %masterdir = datalocs('asmb_prj');
    masterdir = '/Users/dfelikso/Research/Data/ISMIP6/Forcing/GrIS/Atmosphere_Forcing/aSMB_observed/v1/';
    
    smb_anomaly = zeros(md.mesh.numberofvertices,(endyr-startyr+1));
    
    disp('    Interpolating aSMB onto model mesh')
    for k  = startyr:endyr
        filename = sprintf('aSMB_MARv3.9-yearly-%s-%d.nc',cmip, k);
        nc = strcat(masterdir,cmip,'/aSMB/',filename);
        
        % Get data from netcdf
        x = ncread(nc,'x');
        y = ncread(nc,'y');
        aSMB = ncread(nc,'aSMB')';
        % Interpolate onto model mesh
        smb_anomaly(:,(k-startyr+1)) = InterpFromGridToMesh(x,y,aSMB,md.mesh.x,md.mesh.y,0);
        
    end 
    
end

