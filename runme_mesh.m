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
hmax = 25000;

% Step 2 - generate a new mesh, refine based on bed topography
expcontract(GrIS_exp_expanded, GrIS_exp_nias, 5000);

%GrIS_exp_expanded = 'tmp.exp';

% Generate initial uniform mesh (resolution = 500 m)
fprintf('create uniform %4.1f km mesh\n', hinit/1000);
md = triangle(model, GrIS_exp_expanded, hinit);

% extra refinement beyond present-day ice mask
bed = interpBedmachineGreenland(md.mesh.x, md.mesh.y);
[vx vy] = interpJoughinCompositeGreenland(md.mesh.x, md.mesh.y);
vel = sqrt(vx.^2 + vy.^2);
vel_e = vel(md.mesh.elements);

mask = interpBedmachineGreenland(md.mesh.x, md.mesh.y, 'mask');
mask_e = mask(md.mesh.elements);
bed_e = bed(md.mesh.elements);
h = NaN * ones(md.mesh.numberofvertices,1);
pos_e = find( sum((mask_e~=2 & bed_e<0) | isnan(vel_e), 2) > 0);
pos = unique(md.mesh.elements(pos_e));
h(pos) = hmin;

% TODO - different method
signed_distance= mask;
signed_distance(mask==2) = -1;
signed_distance(mask~=2) = +1;
disp('reinitialize levelset');
signed_distance = reinitializelevelset(md, signed_distance);

h = NaN * ones(md.mesh.numberofvertices,1);
pos = find(abs(signed_distance) < 10000 & bed < 0);
h(pos) = hmin;

% buffer by one element
h_e = h(md.mesh.elements);
pos_e = find( any(~isnan(h_e),2) );
pos = unique(md.mesh.elements(pos_e));
h(pos) = hmin;

if debug_plots
   cmap = bedColormap;
   plotmodel(md, 'data', bed, 'caxis', [-1500 +1500], 'colormap', cmap, 'edgecolor', 'k', 'figposition', 'fullscreen')
   hold on
   pos = find(~isnan(h));
   plot(md.mesh.x(pos), md.mesh.y(pos), 'r.', 'markersize', 20)
   axis(a)
end
% TODO - different method

%plotmodel(md, 'data', vel, 'edgecolor', 'k', 'caxis', [0 1500], 'figposition', 'fullscreen', 'figure', 1)
%hold on
%plot(md.mesh.x(pos), md.mesh.y(pos), 'r.', 'markersize', 20)
%title('mesh before refinement')
%%axis(a)
%a = axis;

% refine mesh in fast flowing regions
% or rather areas with high gradients
disp('refine mesh');
md = bamg(md,'hmax',hmax,'hmin',hmin,'gradation',1.7,'field',vel,'err',8,'hmaxVertices',h);

if debug_plots
   [vx vy] = interpJoughinCompositeGreenland(md.mesh.x, md.mesh.y);
   vel = sqrt(vx.^2 + vy.^2);
   plotmodel(md, 'data', vel, 'edgecolor', 'k', 'caxis', [0 1500], 'figposition', 'fullscreen', 'figure', 2)
   axis(a)
   title('mesh after refinement')

   md_nias = loadmodel('models/gris.proj.cmmtt.A0000.starting_point');
   [vx vy] = interpJoughinCompositeGreenland(md_nias.mesh.x, md_nias.mesh.y);
   vel = sqrt(vx.^2 + vy.^2);
   plotmodel(md_nias, 'data', vel, 'edgecolor', 'k', 'caxis', [0 1500], 'figposition', 'fullscreen', 'figure', 3)
   axis(a)
   title('nias mesh')
end

disp('saving ./models/gris_mesh.mat')
save models/gris_mesh.mat md;
