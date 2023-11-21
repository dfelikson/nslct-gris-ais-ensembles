%
% Sample uncertainty in model parameters:
%  1.) rheology: rigidity
%      - bounds: -10% to +10%
%  2.) friction: friction coefficient
%      - bounds: -10% to +10%
%  3.) calving: von Mises sigma max
%      - bounds: 500 kPa to 1500 kPa
%

%
% TODO: In the future, can sample:
% Ocean forcing:
%  a.) EN4
%  b.) ASTE
%  c.) ORAS5
%  d.) ECCO
%  e.) etc.
%
% Atmospheric forcing:
%  a.) ...
%

addpath(genpath('/Users/dfelikso/Software/ScriptsAndUtilities/matlab'));

relaxation_start_yr =  0; calving = 'VM'; ensembleGroup = 'A';
%relaxation_start_yr =  5; calving = 'VM'; ensembleGroup = 'B';
%relaxation_start_yr = 20; calving = 'VM'; ensembleGroup = 'C';

ocean_forcing = 'EN4';

% Start and end times
start_time_hist = 2007;
final_time_hist = 2020;
final_time_proj = 2100;

% Setup end members
calving = 'VM';
%                       A900    A901    A902    A903    A904    A905     A906    A907    A908
%                               [lo]                                                     [hi]
rigidity_end_members  = [1.0     0.9     0.9     0.9     0.9     1.1      1.1     1.1     1.1];
friction_end_members  = [1.0     0.9     0.9     1.1     1.1     0.9      0.9     1.1     1.1];
sigma_max_end_members = [1e6     5e5   1.5e6     5e5   1.5e6     5e5    1.5e6     5e5   1.5e6];

[~, branch] = system('git branch --show-current');
branch = strip(branch);
if ~exist(['./models/' branch], 'dir')
   mkdir(['./models/' branch]);
end

% Run
% mesh / param / inversion / relaxation
runme_mesh;
for i = 0:length(friction_end_members)-1 %%{{{
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);

   rigidity  = rigidity_end_members(i+1);
   friction  = friction_end_members(i+1);

   runme_param;
   runme_inversion;
   runme_relaxation;
end
%%}}}

fprintf('\n');
s = input('Ready to load relaxation simulations (y/n)? ', 's');
if strcmpi(s,'n')
   fprintf('\n');
   return
end

% Load relaxation %%{{{
for i = 0:length(friction_end_members)-1
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Loading relaxation for ensembleID: ' ensembleID green_text_end '\n']);

   runme_relaxation_loadresultsfromcluster;
end
%%}}}

% Run moving front --- historical
frontalforcings_ready = false;
for i = 0:length(friction_end_members)-1 %%{{{
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);

   fprintf('\n');
   fprintf([green_text_start 'Running movingfront for ensembleID: ' ensembleID green_text_end '\n']);

   sigma_max = sigma_max_end_members(i+1);

   runme_movingfront;
end
%%}}}
% Load movingfront --- historical %%{{{
fprintf('\n');
s = input('Ready to load movingfront simulations (y/n)? ', 's');
if strcmpi(s,'n')
   fprintf('\n');
   return
end

for i = 0:length(friction_end_members)-1
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Loading movingfront for ensembleID: ' ensembleID green_text_end '\n']);

   runme_movingfront_loadresultsfromcluster;
end
%%}}}

% Run moving front --- projection
projectionforcings_ready = false;
for i = 0:length(friction_end_members)-1 %%{{{
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);

   sigma_max = sigma_max_end_members(i+1);

   fprintf('\n');
   fprintf([green_text_start 'Running projection for ensembleID: ' ensembleID green_text_end '\n']);

   runme_movingfront_proj;
end
%%}}}
% Load movingfront --- projection %%{{{
fprintf('\n');
s = input('Ready to load projection simulations (y/n)? ', 's');
if strcmpi(s,'n')
   fprintf('\n');
   return
end

for i = 0:length(friction_end_members)-1
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Loading projection for ensembleID: ' ensembleID green_text_end '\n']);

   runme_movingfront_proj_loadresultsfromcluster;
end
%%}}}
return

d = dir('./*tar.gz');
ensemblejobs = {};
for i=1:numel(d)
   ensemblejobs{i} = d(i).name;
end
if ~isempty(ensemblejobs)
   md = solve(md, 'tr', 'ensemblelaunch', true, 'ensemblejobs', ensemblejobs);
   for i=1:numel(ensemblejobs)
      [flag, message, messageid] = movefile(ensemblejobs{i}, '~/.Trash','f');
   end
end

% Load moving front results
%%{{{
f = fopen('tmp_execution/tmp_rsync_list.txt', 'w');
for i = 1:n_ensemble_members
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Cataloging ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');
   
   %runme_movingfront_loadresultsfromcluster;
   filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
   md = loadmodel(filename);
   fprintf(f, ['%s/' md.miscellaneous.name '.errlog\n'], md.private.runtimename);
   fprintf(f, ['%s/' md.miscellaneous.name '.outlog\n'], md.private.runtimename);
   fprintf(f, ['%s/' md.miscellaneous.name '.outbin\n'], md.private.runtimename);
end
%%}}}

s = dir('tmp_execution/tmp_rsync_list.txt');
if s.bytes > 0 %%{{{
   command = 'rsync -avz --progress -d --files-from tmp_execution/tmp_rsync_list.txt dfelikso@discover.nccs.nasa.gov:/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/execution/ tmp_execution/';
   system(command)

   for i = 1:n_ensemble_members
      ensembleID = sprintf('%1s%03d', ensembleGroup, i);
      fprintf('\n');
      fprintf([green_text_start 'Loading ensembleID: ' ensembleID green_text_end '\n']);
      fprintf('\n');
   
      % Relaxation
      filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
      fprintf(['loading ' filename '\n']);
      md = loadmodel(filename);
      
      cluster = md.cluster;
      md.cluster = load_cluster('');
      md.cluster.executionpath = './tmp_execution';
   
      md = loadresultsfromcluster(md);
   
      md.cluster = cluster;
   
      % Save model with results
      filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr'];
      fprintf(['saving ' filename '\n']);
      save(filename, 'md', '-v7.3');
   end
end
return

%runme_movingfront_loadresultsfromcluster;
%%{{{
for i = 1:n_ensemble_members
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');

   % Moving front
   filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
   fprintf(['loading ' filename '\n']);
   md = loadmodel(filename);

   cluster = md.cluster;
   md.cluster = load_cluster('');
   md.cluster.executionpath = './tmp_execution';

   if ~exist(['./tmp_execution/' md.private.runtimename '/gris_ssa_sbinv.outbin'], 'file')
      fprintf('no\n')
      continue
   end
   md = loadresultsfromcluster(md);

   md.cluster = cluster;

   % Save model with results
   filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr'];
   fprintf(['saving ' filename '\n']);
   save(filename, 'md', '-v7.3');
end
%%}}}

