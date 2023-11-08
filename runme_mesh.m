if exist(['./models/' branch '/' branch '.mesh.mat'], 'file');
   fprintf(['Model already exists: ./models/' branch '/' branch '.mesh.mat. Skipping runme_mesh.m!\n']);
   return
end

hinit = 1000;
hmin = 500;
hmid = 1500;
hmax = 25000;

% Generate initial uniform mesh (resolution = 500 m)
fprintf('create uniform %4.1f km mesh\n', hinit/1000);
md = triangle(model, ['./Exp/' branch '.exp'], hinit);

% extra refinement beyond present-day ice mask
%bed = interpBedmachineGreenland(md.mesh.x, md.mesh.y);
mask = interpBedmachineGreenland(md.mesh.x, md.mesh.y, 'mask');

%signed_distance= mask;
%signed_distance(mask==2) = -1;
%signed_distance(mask~=2) = +1;
%disp('reinitialize levelset');
%signed_distance = reinitializelevelset(md, signed_distance);

% NOTE: Buffer the current ice extent by one element and refine to high resolution

% NOTE: Remove ice from nodes that are connected to only one other ice node

% Beyond the present-day front, where there is ocean, refine to high resolution
h = NaN * ones(md.mesh.numberofvertices,1);
pos = find(mask == 0);
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
% md = bamg(md,'hmax',hmax,'hmin',hmin,'gradation',1.7,'field',vel,'err',8,'hVertices',h);
md = bamg(md,'hmax',hmax,'hmin',hmin,'field',vel,'err',5,'hVertices',h);

disp(['saving ./models/' branch '/' branch '.mesh.mat'])
save(['./models/' branch '/' branch '.mesh.mat'], 'md');

