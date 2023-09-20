% Load results from cluster
filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
md = loadmodel(filename);
md = loadresultsfromcluster(md);

% Save model with results
filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr'];
fprintf(['saving ' filename '\n']);
save(filename, 'md', '-v7.3');

