% Load model
md = loadmodel(['./models/ice_temperature_HO/gris.inversion.' ensembleGroup '000.ssa.sb']);

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

if false
% Sliding exponent
md.cluster = load_cluster('');
md1 = solve(md, 'sb');

sliding = evalin('base', 'sliding');
% NOTE: Youngmin
md1.initialization.vx = md1.results.StressbalanceSolution.Vx;
md1.initialization.vy = md1.results.StressbalanceSolution.Vy;
md1.initialization.vel = md1.results.StressbalanceSolution.Vel;
md2 = md1;
ub=sqrt(md1.initialization.vx.^2+md1.initialization.vy.^2)./md1.constants.yts;
p_ice   = md1.constants.g*md1.materials.rho_ice*md1.geometry.thickness;
p_water = max(0.,md1.materials.rho_water*md1.constants.g*(0-md1.geometry.base));
N = p_ice - p_water;
pos=find(N<=0); N(pos)=1;
s=averaging(md1,1./md1.friction.p,0);
r=averaging(md1,md1.friction.q./md1.friction.p,0);
b=(md1.friction.coefficient).^2.*(N.^r).*(ub.^s);
alpha2=md1.friction.coefficient.^2.*N.^r.*ub.^(s-1);

%new friction coefficient
md2.friction.p = sliding.*ones(md1.mesh.numberofelements,1);
md2.friction.q = sliding.*ones(md1.mesh.numberofelements,1);

%new friction coefficient
s=averaging(md2,1./md2.friction.p,0);
r=averaging(md2,md2.friction.q./md2.friction.p,0);

friction_coefficient = sqrt(b./((N.^r).*(ub.^s)));
md2.friction.coefficient=friction_coefficient;
pos=find(isnan(md2.friction.coefficient)); md2.friction.coefficient(pos)=0;
% NOTE: Youngmin
%md = friction_coefficient_conversion(md, 'budd', 'budd', 'p', sliding, 'q', sliding);
md2 = solve(md2, 'sb');

md = md2;
end

friction = evalin('base','friction');
fprintf([yellow_highlight_start 'Changing friction coefficient by %3.1f%%' yellow_highlight_end '\n'], friction);
md.friction.coefficient = (1+friction/100) * md.friction.coefficient;

% Outputs
md.verbose = verbose('solution', true);
md.transient.requested_outputs = {'default', 'IceVolumeAboveFloatation'}; %, 'CalvingAblationrate'};

% Solve
%md.cluster = load_cluster('oibserve');
%md.cluster.interactive = 0;
md.cluster = load_cluster('discover');
md.settings.waitonlock = 0; 9999;
md.toolkits = toolkits;
md = solve(md, 'tr', 'ensembleprep', true);

% Save the model that was sent to the cluster
filename = ['./models/ice_temperature_HO/gris.relaxation.' ensembleID '.ssa.tr.sent2cluster'];
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

