if exist(['./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr.sent2cluster'], 'file')
   fprintf(['Model already exists: ./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr.sent2cluster. Skipping runme_movingfront.m!\n']);
   return
end

% Load model
md_param = loadmodel(['./models/' branch '/' branch '.param.' ensembleID '.mat']);
md = loadmodel(['./models/' branch '/' branch '.relaxation.' ensembleID '.ssa.tr']);
 
% Select the starting point from the relaxation
%relaxation_start_yr = 20; % 5 | 10 | 15 | 20
relaxation_start_yr = evalin('base','relaxation_start_yr');
fprintf([yellow_highlight_start 'Using relaxation start year: %3.0f' yellow_highlight_end '\n'], relaxation_start_yr);
if relaxation_start_yr ~= 0
   pos = find([md.results.TransientSolution(:).time] == relaxation_start_yr);
   if isempty(pos)
      fprintf('Could not find an entry for start yr %5.2f from relaxation! Exiting.\n', relaxation_start_yr)
      return
   end
   md = transientrestart(md, pos);
   results = rmfield(md.results, 'TransientSolution3');
   md.results = results;
else
   md.results.TransientSolution  = struct();
end

md.frontalforcings.meltingrate = frontalforcings_meltingrate;

% SMB
md.smb.mass_balance = md_param.smb.mass_balance;

% Calving
calving = evalin('base','calving');
fprintf([yellow_highlight_start 'Using calving: %s' yellow_highlight_end '\n'], calving);
switch calving
   case 'VM'
     sigma_max = evalin('base', 'sigma_max');
     fprintf([yellow_highlight_start 'Using sigma_max: %10.0f' yellow_highlight_end '\n'], sigma_max);
     md.calving = calvingvonmises();
     md.calving.stress_threshold_groundedice = sigma_max;
     %md.calving.stress_threshold_floatingice = 5e5;
   case 'CD'
     water_height = evalin('base', 'water_height');
     fprintf([yellow_highlight_start 'Using water_height: %5.0f' yellow_highlight_end '\n'], water_height);
     md.calving = calvingcrevassedepth();
     md.calving.crevasse_opening_stress = 0;
     md.calving.water_height = water_height * ones(md.mesh.numberofvertices,1);
end

% spclevelset -- where there's no ice and bed>0, keep it that way
md.levelset.spclevelset = nan * ones(md.mesh.numberofvertices,1);
%pos = find(md.geometry.bed < 0 & md.mesh.vertexonboundary);
%md.levelset.spclevelset(pos) = nan;
%md.levelset.migration_max = 1e6;

pos = md.mask.ice_levelset>0 & md.geometry.bed>0;
md.levelset.spclevelset(pos) = 1;

% Other settings
md.levelset.stabilization = 2;
md.levelset.reinit_frequency = 1;

% Turn on movingfront
md.transient.ismovingfront = 1;
md.transient.isgroundingline = 1;

% set which components of the transient solution to run
md.inversion.iscontrol = 0;
md.transient.issmb=0;
md.transient.ismasstransport=1;
md.transient.isstressbalance=1;
md.transient.isthermal=0;
md.transient.isgroundingline=1;
md.transient.isesa=0;
md.transient.isdamageevolution=0;
md.transient.ismovingfront=1;
md.transient.ishydrology=0;
md.transient.isslc=0;
md.transient.isoceancoupling=0;
%md.transient.iscoupler=0;

md.groundingline.migration='SubelementMigration';
 
md.verbose = verbose('solution', true);
md.transient.requested_outputs = {'default', 'IceVolumeAboveFloatation', 'CalvingFluxLevelset', 'SigmaVM', 'CalvingMeltingrate', 'CalvingCalvingrate', 'SmbMassBalance', 'TotalSmb'}; %, 'CalvingAblationrate'};

% Start and end times
md.timestepping.start_time = evalin('base','start_time');
md.timestepping.final_time = evalin('base','final_time');
md.timestepping.time_step = 0.01;
md.settings.output_frequency = 20;

% Solve
md.miscellaneous.name = 'gris_ssa_tr';
%md.cluster = load_cluster('oibserve');
%md.cluster.interactive = 0;
md.cluster = load_cluster('discover');
md.cluster.time = 5400;
md.settings.waitonlock = 0; 9999;
md.toolkits = toolkits;
md = solve(md, 'tr');

% Save the model that was sent to the cluster
filename = ['./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

