md = loadmodel('./models/gris.param.mat');

fprintf(['\n\033[33m   Basal friction \033[0m \n\n']);
disp('   Initialize basal friction using driving stress');
disp('      -- Compute surface slopes and use 10 L2 projections');
[sx,sy,s]=slope(md); sslope=averaging(md,s,10);
disp('      -- Process surface velocity data');
vel = md.inversion.vel_obs;
flags=(vel==0); pos1=find(flags); pos2=find(~flags);
vel(pos1) = griddata(md.mesh.x(pos2),md.mesh.y(pos2),vel(pos2),md.mesh.x(pos1),md.mesh.y(pos1));
%velmax = max(vel);
%vel(vel==0 & md.mask.ice_levelset<0) = velmax;
disp('      -- Filling in missing ice velocity with MEaSUREs mosaic');
[velx, vely] = interpJoughinCompositeGreenland(md.mesh.x,md.mesh.y);
vel = sqrt( velx.^2 + vely.^2 );
idx = md.mask.ice_levelset < 0 & isnan(vel);
vel(idx) = sqrt( velx(idx).^2 + vely(idx).^2 );
vel=max(vel,0.1);
disp('      -- Calculate effective pressure');
Neff = md.materials.rho_ice*md.geometry.thickness+md.materials.rho_water*md.geometry.base;
Neff(find(Neff<=0))=1;
% -- NOTE --
Neff=max(Neff,5e4);
pos1 = find(Neff==5e4 & vel <100 & md.mask.ice_levelset<0);
pos2 = find(Neff >5e4 & vel>=100 & md.mask.ice_levelset<0);
vel(pos1) = griddata(md.mesh.x(pos2),md.mesh.y(pos2),vel(pos2),md.mesh.x(pos1),md.mesh.y(pos1),'nearest');
% -- NOTE --
disp('      -- Deduce friction coefficient');
md.friction.coefficient=sqrt(md.materials.rho_ice*md.geometry.thickness.*(sslope)./(Neff.*vel/md.constants.yts));
md.friction.coefficient=min(md.friction.coefficient,200);
md.friction.p = 1.0 * ones(md.mesh.numberofelements,1);
md.friction.q = 1.0 * ones(md.mesh.numberofelements,1);
disp('      -- Extrapolate on ice free and floating ice regions');
flags=(md.mask.ice_levelset>0) | (md.mask.ice_levelset<0 & md.mask.ocean_levelset<0); pos1=find(flags); pos2=find(~flags);
%md.friction.coefficient(pos1) = griddata(md.mesh.x(pos2),md.mesh.y(pos2),md.friction.coefficient(pos2),md.mesh.x(pos1),md.mesh.y(pos1),'natural');
md.friction.coefficient(pos1) = 1;
pos=find(isnan(md.friction.coefficient));
md.friction.coefficient(pos)  = 1;

% Control general
md.inversion.iscontrol=1;
md.inversion.maxsteps=100;   %%%% increase? in Helenes code nsteps=300
md.inversion.maxiter=40;
md.inversion.dxmin=0.1;
md.inversion.gttol=0.0001;

% Cost functions
md.inversion.cost_functions=[101 103 501];
md.inversion.cost_functions_coefficients=ones(md.mesh.numberofvertices,3);
md.inversion.cost_functions_coefficients(:,1)= 200;     % 100;
md.inversion.cost_functions_coefficients(:,2)= 1;       % 1;
md.inversion.cost_functions_coefficients(:,3)= 1e-7;    % 1e-8;

% Where vel==0, set coefficients to 0 (i.e., don't try to match this in model
disp(['Removing vel==0 obs from inversion']);
pos = find(md.inversion.vel_obs == 0);
md.inversion.cost_functions_coefficients(pos,1) = 0;
md.inversion.cost_functions_coefficients(pos,2) = 0;

% Controls on inverted values
md.inversion.control_parameters={'FrictionCoefficient'};
md.inversion.min_parameters=1*ones(md.mesh.numberofvertices,1);
md.inversion.max_parameters=200*ones(md.mesh.numberofvertices,1);

% Additional parameters
% % For stress balance
md.stressbalance.restol=0.01; md.stressbalance.reltol=0.1;
md.stressbalance.abstol=NaN;

% Go solve
%md.cluster=load_cluster('discover');
%md.cluster.np=4;
%md.cluster.queue='debug';
%md.cluster.time=60;
md.cluster = load_cluster('oibserve');
md.miscellaneous.name='gris_ssa_sbinv';
md.cluster.interactive=0; %runs in background on cluster (adds & to end of *.queue)
md.toolkits=toolkits;
md.verbose=verbose('control',true);
md.settings.waitonlock=0; % Model results must be loaded manually with md=loadresultsfromcluster(md);

md=solve(md,'sb');

save ./models/gris.inversion.ssa.sb.mat md;

