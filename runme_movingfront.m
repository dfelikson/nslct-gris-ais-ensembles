% Load model
md = loadmodel('./models/gris.inversion.ssa.sb');

% Fix stuff -- NOTE: this is needed for Isabel's models only
%md.groundingline.requested_outputs = {'default'};
%md.mask.ice_levelset = md.mask.ice_levelset + 0.1;
%md.mask.ocean_levelset = reinitializelevelset(md, md.mask.ocean_levelset);
%md.mask.ice_levelset   = reinitializelevelset(md, md.mask.ice_levelset);

% Frontal forcings
if false
md.frontalforcings = frontalforcingsrignot();
md.frontalforcings.basin_id = ones(md.mesh.numberofelements,1);
md.frontalforcings.num_basins = 1;
md.frontalforcings.subglacial_discharge = 300 * 86400 * ones(md.mesh.numberofvertices,1);
md.frontalforcings.thermalforcing = 10 * ones(md.mesh.numberofvertices,1);
end

md.frontalforcings = frontalforcings();
md.frontalforcings.meltingrate = 0 * ones(md.mesh.numberofvertices,1) * 365.25; % 5 m/day converted to m/year
md.frontalforcings.ablationrate = 0 * md.initialization.vel;

% Calving
%md.calving = calvingvonmises();
%md.calving.stress_threshold_groundedice = 2e5;
pos = find(md.geometry.bed<0);
md.calving.calvingrate = zeros(md.mesh.numberofvertices,1);
%md.calving.calvingrate(pos) = 10000; %5 * md.initialization.vel; % * ones(md.mesh.numberofvertices,1) * 365.25; % 5 m/day converted to m/year
md.frontalforcings.meltingrate = 0 * ones(md.mesh.numberofvertices,1);
md.frontalforcings.meltingrate(pos) = 10000;

md.levelset.spclevelset = nan * ones(md.mesh.numberofvertices,1);
%pos = find(md.geometry.bed < 0 & md.mesh.vertexonboundary);
%md.levelset.spclevelset(pos) = nan;
%md.levelset.migration_max = 1e6;

% Fix base<bed
%pos = find(md.geometry.base - md.geometry.bed < 1e-3);
%md.geometry.base(pos) = md.geometry.bed;

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
%md.transient.isgia=0;
md.transient.isesa=0;
md.transient.isdamageevolution=0;
md.transient.ismovingfront=1;
md.transient.ishydrology=0;
md.transient.isslc=0;
md.transient.isoceancoupling=0;
%md.transient.iscoupler=0;

md.groundingline.migration='SubelementMigration';
   
md.timestepping.time_step=0.05;%0.01; % need to adjust for CFL
md.timestepping.start_time=0; %years
md.timestepping.final_time=0.25; %years
md.settings.output_frequency=1; % output every Nth timestep

% NOTE DEBUG
%md.smb.mass_balance(md.geometry.surface < 500) = -10;
% NOTE DEBUG

md.verbose = verbose('solution', true);
md.transient.requested_outputs = {'default', 'IceVolumeAboveFloatation', 'CalvingFluxLevelset', 'SigmaVM', 'CalvingMeltingrate', 'CalvingCalvingrate'}; %, 'CalvingAblationrate'};

% Solve
md.cluster = load_cluster('oibserve');
md.cluster.np = 28;
md.cluster.interactive = 1;

md.settings.waitonlock = 9999;

md.toolkits = toolkits;
md = solve(md, 'tr');

% Save
filename = './models/gris.movingfront.ssa.tr';
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

