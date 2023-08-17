% Load model
md = loadmodel(['./models/inversion_trials/gris.inversion.trial2.ssa.sb']);

% Start and end time setup
md.timestepping.time_step=0.05;%0.01; % need to adjust for CFL
md.timestepping.start_time=0; %years
md.timestepping.final_time=20; %years
md.settings.output_frequency=10; % output every Nth timestep

% Update model friction fields accordingly
md.friction.coefficient=md.results.StressbalanceSolution.FrictionCoefficient;

% set which components of the transient solution to run
md.inversion.iscontrol = 0;
md.transient.issmb=0;
md.transient.ismasstransport=1;
md.transient.isstressbalance=1;
md.transient.isthermal=0;
md.transient.isgroundingline=1;
md.transient.isesa=0;
md.transient.isdamageevolution=0;
md.transient.ismovingfront=0;
md.transient.ishydrology=0;
md.transient.isslc=0;
md.transient.isoceancoupling=0;
%md.transient.iscoupler=0;

md.groundingline.migration='SubelementMigration';

% Outputs
md.verbose = verbose('solution', true);
md.transient.requested_outputs = {'default', 'IceVolumeAboveFloatation'}; %, 'CalvingAblationrate'};

% Solve
%md.cluster = load_cluster('oibserve');
%md.cluster.interactive = 0;
md.cluster = load_cluster('discover');
md.settings.waitonlock = 0;
md.toolkits = toolkits;
md = solve(md, 'tr');

% Save the model that was sent to the cluster
filename = ['./models/inversion_trials/gris.relaxation.trial2.ssa.tr.sent2cluster'];
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

