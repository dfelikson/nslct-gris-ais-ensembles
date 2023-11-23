if exist(['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr'], 'file')
   fprintf(['Model already exists: ./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr. Skipping runme_movingfront_proj_loadresultsfromcluster.m!\n']);
   return
end

% Load results from cluster
filename = ['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr.sent2cluster'];
md = loadmodel(filename);
md = loadresultsfromcluster(md);

% Save model with results
filename = ['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr'];
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

