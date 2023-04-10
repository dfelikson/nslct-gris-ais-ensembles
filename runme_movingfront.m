% Load model
md = loadmodel('./models/gris.inversion.ssa.sb');

% Frontal forcings -- basic tests that are commented out %%{{{
% Frontal forcings -- basic test of frontalforcings
%md.frontalforcings = frontalforcings();
%md.frontalforcings.meltingrate = 0 * ones(md.mesh.numberofvertices,1) * 365.25; % 5 m/day converted to m/year
%md.frontalforcings.ablationrate = 0 * md.initialization.vel;
%pos = find(md.geometry.bed<0);
%md.frontalforcings.meltingrate = 0 * ones(md.mesh.numberofvertices,1);
%md.frontalforcings.meltingrate(pos) = 1000;

% Frontal forcings -- basic test of fromtalforcingsrignot
%md.frontalforcings = frontalforcingsrignot();
%md.frontalforcings.basin_id = ones(md.mesh.numberofelements,1);
%md.frontalforcings.num_basins = 1;
%md.frontalforcings.subglacial_discharge = 300 * 86400 * ones(md.mesh.numberofvertices,1);
%md.frontalforcings.thermalforcing = 10 * ones(md.mesh.numberofvertices,1);

% Calving -- basic test
%pos = find(md.geometry.bed<0);
%md.calving.calvingrate = zeros(md.mesh.numberofvertices,1);
%md.calving.calvingrate(pos) = 10000; %5 * md.initialization.vel; % * ones(md.mesh.numberofvertices,1) * 365.25; % 5 m/day converted to m/year
%%}}}

% Slater and Straneo (2022) frontal forcings
[md_basins, twglaciers] = parameterize_slater_straneo_submelt(md);
submelt_source = 'ORAS5';
md.frontalforcings.meltingrate = 0 * ones(md.mesh.numberofvertices+1,length(twglaciers(1).submelt.t));
md.frontalforcings.meltingrate(end,:) = twglaciers(1).submelt.t;
for i_twg = 1:numel(twglaciers)
   submelt = eval(['twglaciers(i_twg).submelt.m_' submelt_source]);
   pos = find(md_basins == twglaciers(i_twg).basin_num);
   md.frontalforcings.meltingrate(pos,:) = repmat(submelt, length(pos), 1) * 365.25;
end
pos = find(md.geometry.bed > 0 );
md.frontalforcings.meltingrate(pos,:) = 0;

% Calving
md.calving = calvingvonmises();
md.calving.stress_threshold_groundedice = 1e6;

md.levelset.spclevelset = nan * ones(md.mesh.numberofvertices,1);
%pos = find(md.geometry.bed < 0 & md.mesh.vertexonboundary);
%md.levelset.spclevelset(pos) = nan;
%md.levelset.migration_max = 1e6;

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
   
md.timestepping.time_step=0.05;%0.01; % need to adjust for CFL
md.timestepping.start_time=2007; %years
md.timestepping.final_time=2016; %years
md.settings.output_frequency=4; % output every Nth timestep

md.verbose = verbose('solution', true);
md.transient.requested_outputs = {'default', 'IceVolumeAboveFloatation', 'CalvingFluxLevelset', 'SigmaVM', 'CalvingMeltingrate', 'CalvingCalvingrate'}; %, 'CalvingAblationrate'};

% Solve
md.cluster = load_cluster('oibserve');
md.cluster.np = 28;
md.cluster.interactive = 0;
md.settings.waitonlock = 0; 9999;
md.toolkits = toolkits;
md = solve(md, 'tr');

% Save the model that was sent to the cluster
filename = './models/gris.movingfront.ssa.tr.sent2cluster';
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');
return

% Load results from cluster
md = loadmodel(filename);
md = loadresultsfromcluster(md);

% Save model with results
filename = './models/gris.movingfront.ssa.tr';
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

