% load in refined mesh
md = loadmodel('./models/initial_mesh_setup/gris.mesh.mat');

%md = setmask(md,'',''); % empty arguements denotes that all ice is grounded
md = parameterize(md,'./Par/Greenland.par');
md = setflowequation(md,'SSA','all');

save(['./models/ice_temperature_HO/gris.param.' ensembleID '.mat'], 'md');

