if exist(['./models/' branch '/' branch '.param.' ensembleID '.mat'], 'file');
   fprintf(['Model already exists: ./models/' branch '/' branch '.param.' ensembleID '.mat. Skipping runme_param.m!\n']);
   return
end

% load in refined mesh
md = loadmodel(['./models/' branch '/' branch '.mesh.mat']);

%md = setmask(md,'',''); % empty arguements denotes that all ice is grounded
md = parameterize(md,'./Par/Greenland.par');
md = setflowequation(md,'SSA','all');

save(['./models/' branch '/' branch '.param.' ensembleID '.mat'], 'md');

