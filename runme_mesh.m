addpath(genpath('/Users/dfelikso/Software/ScriptsAndUtilities/matlab'));
debug_plots = false;

% Step 1 - buffer the original domain outline
GrIS_exp_nias = './Exp/DomainOutlineEditV3.exp';
GrIS_exp_expanded = './Exp/DomainOutlineEditV3_expanded.exp';

a = [-2.1823e+05 -1.6148e+05 -2.2277e+06 -2.1300e+06];
a = [-0.2102e+06 -0.1829e+06   -2.2247e+06   -2.1778e+06];
a = [-0.2055   -0.1981   -2.2079   -2.1952] * 1e+06;

hinit = 1000;
hmin = 500;
hmid = 1500;
hmax = 25000;

% Step 2 - generate a new mesh, refine based on bed topography
expcontract(GrIS_exp_expanded, GrIS_exp_nias, 5000);

%GrIS_exp_expanded = 'tmp.exp';

% Generate initial uniform mesh (resolution = 500 m)
fprintf('create uniform %4.1f km mesh\n', hinit/1000);
md = triangle(model, GrIS_exp_expanded, hinit);

% extra refinement beyond present-day ice mask
%bed = interpBedmachineGreenland(md.mesh.x, md.mesh.y);
mask = interpBedmachineGreenland(md.mesh.x, md.mesh.y, 'mask');

%signed_distance= mask;
%signed_distance(mask==2) = -1;
%signed_distance(mask~=2) = +1;
%disp('reinitialize levelset');
%signed_distance = reinitializelevelset(md, signed_distance);

% Beyond the present-day front, refine to medium resolution
h = NaN * ones(md.mesh.numberofvertices,1);
pos = find(mask ~= 2);
h(pos) = hmid;

% buffer by one element
h_e = h(md.mesh.elements);
pos_e = find( any(~isnan(h_e),2) );
pos = unique(md.mesh.elements(pos_e));
h(pos) = hmid;

% refine mesh in fast flowing regions
% or rather areas with high gradients
[vx vy] = interpITS_LIVE(md.mesh.x, md.mesh.y);
vel = sqrt(vx.^2 + vy.^2);

disp('refine mesh');
md = bamg(md,'hmax',hmax,'hmin',hmin,'gradation',1.7,'field',vel,'err',8,'hVertices',h);

disp('saving ./models/initial_mesh_setup/gris.mesh.mat')
save models/initial_mesh_setup/gris.mesh.mat md;
