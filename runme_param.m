% load in refined mesh
md = loadmodel('./models/gris.mesh.mat');

%md = setmask(md,'',''); % empty arguements denotes that all ice is grounded
md = parameterize(md,'./Par/Greenland.par');
md = setflowequation(md,'SSA','all');

save ./models/gris.param.mat md;

