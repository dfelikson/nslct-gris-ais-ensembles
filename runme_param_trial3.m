% load in refined mesh
md = loadmodel('./models/initial_mesh_setup/gris.mesh.mat');

%md = setmask(md,'',''); % empty arguements denotes that all ice is grounded
md = parameterize(md,'./Par/Greenland_trial3.par');
md = setflowequation(md,'SSA','all');

save(['./models/inversion_trials/gris.param.trial3.mat'], 'md');

