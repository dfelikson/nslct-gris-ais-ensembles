% load in refined mesh
md = loadmodel('./models/gris_mesh.mat');

%md = setmask(md,'',''); % empty arguements denotes that all ice is grounded
md = parameterize(md,'./Par/gris_initMIP.par');
md = setflowequation(md,'SSA','all');

save ./models/gris_param.mat md;

