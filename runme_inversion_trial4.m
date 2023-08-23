md = loadmodel(['./models/inversion_trials/gris.param.trial3.mat']);

% % 
% pos = find(md.inversion.vel_obs>750);
% md.friction.coefficient(pos) = 20;

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
% md.inversion.cost_functions_coefficients(:,1)=5000;    %1000
% md.inversion.cost_functions_coefficients(:,2)=5;      %5
% md.inversion.cost_functions_coefficients(:,3)=3e-5; %3e-5; %0.5*50^-3; %1.5*50^-3

% % De-weight slow velocity areas
% pos = find(md.inversion.vel_obs < 500);
% md.inversion.cost_functions_coefficients(pos,:) = md.inversion.cost_functions_coefficients(pos,:) / 500;

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
md.stressbalance.restol=0.01;
md.stressbalance.reltol=0.1;
md.stressbalance.abstol=NaN;

md.friction.coupling = 0;
%pos = sum(md.mask.ice_levelset(md.mesh.elements)<0.,2)>0 & sum(md.mask.ice_levelset(md.mesh.elements)>0.,2)>0 & sum(md.geometry.bed(md.mesh.elements)>0.,2);
%pos = md.mesh.elements(pos,:);
%md.stressbalance.spcvx(pos)=md.inversion.vx_obs(pos);
%md.stressbalance.spcvy(pos)=md.inversion.vy_obs(pos);

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
md.settings.waitonlock=NaN; % Model results must be loaded manually with md=loadresultsfromcluster(md);

md=solve(md,'sb');

save(['./models/inversion_trials/gris.inversion.trial4.ssa.sb.mat'], 'md');

