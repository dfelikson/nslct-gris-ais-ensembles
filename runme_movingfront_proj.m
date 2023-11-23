if exist(['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr.sent2cluster'], 'file')
   fprintf(['Model already exists: ./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr.sent2cluster. Skipping runme_movingfront_proj.m!\n']);
   return
end

% Load model
md = loadmodel(['./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr']);
 
% This is mostly taken from Isabel's scripts for ISMIP6 GrIS projections
md = transientrestart(md);
md.results = rmfield(md.results, 'TransientSolution3');

% turn on smb solution in transient
md.transient.issmb = 1;

% Prep forcings %%{{{
if ~projectionforcings_ready
   fprintf('\n');
   fprintf('Preparing forcings\n');

   disp('   apply SMB forcing'); %%{{{
   % load reference smb (the 1960-1989 mean)
   smb_ref = load_smb_ref(md);
   
   % convert smb_ref from m/yr ice to mm/yr w.e.
   % because mm/yr required by SMBgradients()
   smb_ref = (smb_ref*1000*md.materials.rho_ice)/md.materials.rho_freshwater;
   
   cmip = 'MIROC5-rcp85';
   
   % load the time-varying SMB anomaly
   smb_anomaly = load_smb_anomaly(md,cmip,final_time_hist,final_time_proj);
   % convert kg m^-2 s^-1 (i.e. mm/s w.e.) to mm/yr w.e.
   % using 31556926 s/yr as used by ISMIP6 (compared to md.constants.yts)
   % kg m^-2 = mm w.e. (for md.matertials.rho_freshwater)
   smb_anomaly = smb_anomaly*31556926;
   % years
   smb_anomaly_years = final_time_hist:final_time_proj;
   
   % reference SMB [mm/yr water equiv]
   warning('check the units on smb_ref and smb_anomaly!')
   smbref = [smb_ref + smb_anomaly; smb_anomaly_years];
   
   % dSMB/dz [ (mm/yr water equiv)/(m) ]
   dSMBdz = load_dSMBdz(md,cmip,final_time_hist,final_time_proj);
   % convert from (kg m^-2 s^-1)/m to (mm/yr w.e.)/m
   dSMBdz = dSMBdz*31556926;
   % years
   dSMBdz_years = final_time_hist:final_time_proj;
   %%}}}
   disp('   apply ocean forcing'); %%{{{
   ocean_forcing_dir = '/Users/dfelikso/Research/Data/ISMIP6/Forcing/GrIS/Ocean_Forcing/Melt_Implementation/v4';
   cmip = 'miroc5';
   rcp = 'rcp8.5';
   
   ncfile_runoff = [ocean_forcing_dir '/' cmip '_' rcp '/MAR3.9_' upper(cmip) '_' strrep(rcp, '.', '') '_basinRunoff_v4.nc'];
   ncfile_TF     = [ocean_forcing_dir '/' cmip '_' rcp '/MAR3.9_' upper(cmip) '_' strrep(rcp, '.', '') '_oceanThermalForcing_v4.nc'];
   
   x = ncread(ncfile_runoff,'x');
   y = ncread(ncfile_runoff,'y');
   runoff = ncread(ncfile_runoff,'basin_runoff',[1,1,57],[Inf,Inf,Inf]); % NOTE: hardcoded to 2006-2100
   TF = ncread(ncfile_TF,'thermal_forcing',[1,1,57],[Inf,Inf,Inf]); % NOTE: hardcoded to 2006-2100
   
   frontalforcings_meltingrate = zeros(md.mesh.numberofvertices+1,size(runoff,3));
   frontalforcings_meltingrate(end,:) = 2006:2100; % NOTE: hardcoded to 2006-2100
   for i = 1:size(runoff,3)
      runoff_interp = InterpFromGridToMesh_matlab(x, y, runoff(:,:,i)', md.mesh.x, md.mesh.y, nan) * (86400/1000);
      TF_interp     = InterpFromGridToMesh_matlab(x, y, TF(:,:,i)',     md.mesh.x, md.mesh.y, nan);
   
      frontalforcings_meltingrate(1:end-1,i) = ((3e-4 .* -md.geometry.bed .* runoff_interp.^0.39 + 0.15) .* TF_interp.^1.18) .* 365;
   end
   
   md.frontalforcings.meltingrate = frontalforcings_meltingrate;
   
   pos = find(frontalforcings_meltingrate < 0);
   frontalforcings_meltingrate(pos) = 0;
   pos = find(isnan(frontalforcings_meltingrate));
   frontalforcings_meltingrate(pos) = 0;
   %%}}}

   projectionforcings_ready = true;
end
%%}}}

% update with the SMBgradients class
% to allow elevation feedback
md.smb = SMBgradients();
md.smb.smbref = smbref;

% reference surface [m] -- surface at the end of the historical run
md.smb.href = md.geometry.surface; % reinitialised surface

% update lapse rates
md.smb.b_pos = [dSMBdz; dSMBdz_years];
md.smb.b_neg = md.smb.b_pos;

% update ocean forcings
md.frontalforcings.meltingrate = frontalforcings_meltingrate;

% additional outputs from transient
md.transient.requested_outputs{end+1} = 'CalvingFluxLevelset';
md.transient.requested_outputs{end+1} = 'CalvingMeltingFluxLevelset';

% 
md.timestepping.final_time = final_time_proj;

%
md.cluster.time = 7*60*60;
md = solve(md, 'tr');

% Save the model that was sent to the cluster
filename = ['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr.sent2cluster'];
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

