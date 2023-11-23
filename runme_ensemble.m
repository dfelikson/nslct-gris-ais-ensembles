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
n_ensemble_members = 25;
calving = 'VM';
relaxation_start_yr =  0; calving = 'VM'; ensembleGroup = 'A';
%relaxation_start_yr =  5; calving = 'VM'; ensembleGroup = 'B';
%relaxation_start_yr = 20; calving = 'VM'; ensembleGroup = 'C';

[~, branch] = system('git branch --show-current');
branch = strip(branch);
if ~exist(['./models/' branch], 'dir')
   mkdir(['./models/' branch]);
end

% Setup the ensemble
lhs_file = ['ensemble_LHS_' ensembleGroup 'XXX_' calving '.txt'];
if ~exist(lhs_file,'file') %%{{{
   switch calving
      case 'VM'
         lhs = lhsu([0.9, 0.9, 5e5], [1.1, 1.1, 1.5e6], n_ensemble_members);
   end
   %s_CD = lhsu([-10,   0], [+10,   75], n_ensemble_members);

   f = fopen(lhs_file,'w');
   for i = 1:n_ensemble_members
      ensembleID = sprintf('%1s%03d', ensembleGroup, i);
      fprintf(f, '%4s', ensembleID);
      for ii = 1:size(lhs,2)
         fprintf(f, ' %8.2f', lhs(i,ii));
      end
      fprintf(f, '\n');
   end
%%}}}
else %%{{{
   fprintf('Using existing LHS file: %s\n', lhs_file);
   fid = fopen('ensemble_LHS_AXXX_VM.txt','r');
   C = textscan(fid, '%s %f %f %f');
   fclose(fid);
   lhs = [];
   for i = 1:numel(C)-1
      lhs(:,i) = C{i+1};
   end
end
%%}}}

% Run
% mesh / param / inversion / relaxation
runme_mesh;
for i = 1:n_ensemble_members %%{{{
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);

   rigidity = lhs(i,1);
   friction = lhs(i,2);

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
f = fopen('tmp_execution/tmp_rsync_list.txt', 'w');
for i = 1:n_ensemble_members %%{{{
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Cataloging ensembleID: ' ensembleID green_text_end '\n']);

   model_relaxation_name = ['./models/' branch '/' branch '.relaxation.' ensembleID '.ssa.tr'];
   if exist(model_relaxation_name,'file')
      fprintf([' Model ' model_relaxation_name ' already exists ... skipping!\n']);
      continue
   end

   filename = ['./models/' branch '/' branch '.relaxation.' ensembleID '.ssa.tr.sent2cluster'];
   md = loadmodel(filename);
   fprintf(f, '%s/gris_ssa_sbinv.errlog\n', md.private.runtimename);
   fprintf(f, '%s/gris_ssa_sbinv.outlog\n', md.private.runtimename);
   fprintf(f, '%s/gris_ssa_sbinv.outbin\n', md.private.runtimename);
end
%%}}}
s = dir('tmp_execution/tmp_rsync_list.txt');
if s.bytes > 0 %%{{{
   !rsync -avz --progress -d --files-from tmp_execution/tmp_rsync_list.txt dfelikso@discover.nccs.nasa.gov:/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/execution/ tmp_execution/

   for i = 1:n_ensemble_members
      ensembleID = sprintf('%1s%03d', ensembleGroup, i);
      fprintf('\n');
      fprintf([green_text_start 'Loading ensembleID: ' ensembleID green_text_end '\n']);
      fprintf('\n');

      % Relaxation
      filename = ['./models/' branch '/' branch '.relaxation.' ensembleID '.ssa.tr.sent2cluster'];
      fprintf(['loading ' filename '\n']);
      md = loadmodel(filename);

      cluster = md.cluster;
      md.cluster = load_cluster('');
      md.cluster.executionpath = './tmp_execution';

      md = loadresultsfromcluster(md);

      md.cluster = cluster;

      % Save model with results
      filename = ['./models/' branch '/' branch '.relaxation.' ensembleID '.ssa.tr'];
      fprintf(['saving ' filename '\n']);
      save(filename, 'md', '-v7.3');
   end
end
%%}}}
%%}}}

% Run moving front --- historical
frontalforcings_ready = false;
for i = 1:n_ensemble_members %%{{{
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);

   fprintf('\n');
   fprintf([green_text_start 'Running movingfront for ensembleID: ' ensembleID green_text_end '\n']);

   sigma_max = lhs(i,3);

   runme_movingfront_ensembleprep;
end
%%}}}
d = dir('./*tar.gz');
s = input(sprintf('\nReady to launch %d movingfront simulations (y/n)? ', length(d)), 's');
if strcmpi(s,'n')
   fprintf('\n');
   return
end

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

fprintf('\n');
s = input('Ready to load movingfront simulations (y/n)? ', 's');
if strcmpi(s,'n')
   fprintf('\n');
   return
end

% Load movingfront --- historical %%{{{
f = fopen('tmp_execution/tmp_rsync_list.txt', 'w');
for i = 1:n_ensemble_members %%{{{
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Cataloging ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');
   
   filename = ['./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr'];
   if exist(filename,'file')
      fprintf([' Model ' filename ' already exists ... skipping!\n']);
      continue
   end

   filename = ['./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
   md = loadmodel(filename);
   fprintf(f, ['%s/' md.miscellaneous.name '.errlog\n'], md.private.runtimename);
   fprintf(f, ['%s/' md.miscellaneous.name '.outlog\n'], md.private.runtimename);
   fprintf(f, ['%s/' md.miscellaneous.name '.outbin\n'], md.private.runtimename);
end
%%}}}
s = dir('tmp_execution/tmp_rsync_list.txt');
if s.bytes > 0 %%{{{
   !rsync -avz --progress -d --files-from tmp_execution/tmp_rsync_list.txt dfelikso@discover.nccs.nasa.gov:/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/execution/ tmp_execution/;

   for i = 1:n_ensemble_members
      ensembleID = sprintf('%1s%03d', ensembleGroup, i);
      fprintf('\n');
      fprintf([green_text_start 'Loading ensembleID: ' ensembleID green_text_end '\n']);
      fprintf('\n');
   
      % Relaxation
      filename = ['./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
      fprintf(['loading ' filename '\n']);
      md = loadmodel(filename);
      
      cluster = md.cluster;
      md.cluster = load_cluster('');
      md.cluster.executionpath = './tmp_execution';
   
      md = loadresultsfromcluster(md);
   
      md.cluster = cluster;
   
      % Save model with results
      filename = ['./models/' branch '/' branch '.movingfront.' ensembleID '.ssa.tr'];
      fprintf(['saving ' filename '\n']);
      save(filename, 'md', '-v7.3');
   end
end
%%}}}
%%}}}

% Run moving front --- projection
projectionforcings_ready = false;
for i = 1:n_ensemble_members %%{{{
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);

   fprintf('\n');
   fprintf([green_text_start 'Running projection for ensembleID: ' ensembleID green_text_end '\n']);

   sigma_max = lhs(i,3);

   runme_movingfront_proj_ensembleprep;
end
%%}}}

d = dir('./*tar.gz');
s = input(sprintf('\nReady to launch %d projection simulations (y/n)? ', length(d)), 's');
if strcmpi(s,'n')
   fprintf('\n');
   return
end

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

% Load movingfront --- projection %%{{{
f = fopen('tmp_execution/tmp_rsync_list.txt', 'w');
for i = 1:n_ensemble_members %%{{{
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Cataloging ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');
   
   filename = ['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr'];
   if exist(filename,'file')
      fprintf([' Model ' filename ' already exists ... skipping!\n']);
      continue
   end

   filename = ['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr.sent2cluster'];
   md = loadmodel(filename);
   fprintf(f, ['%s/' md.miscellaneous.name '.errlog\n'], md.private.runtimename);
   fprintf(f, ['%s/' md.miscellaneous.name '.outlog\n'], md.private.runtimename);
   fprintf(f, ['%s/' md.miscellaneous.name '.outbin\n'], md.private.runtimename);
end
%%}}}
s = dir('tmp_execution/tmp_rsync_list.txt');
if s.bytes > 0 %%{{{
   !rsync -avz --progress -d --files-from tmp_execution/tmp_rsync_list.txt dfelikso@discover.nccs.nasa.gov:/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/execution/ tmp_execution/;

   for i = 1:n_ensemble_members
      ensembleID = sprintf('%1s%03d', ensembleGroup, i);
      fprintf('\n');
      fprintf([green_text_start 'Loading ensembleID: ' ensembleID green_text_end '\n']);
      fprintf('\n');
   
      % Relaxation
      filename = ['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr.sent2cluster'];
      fprintf(['loading ' filename '\n']);
      md = loadmodel(filename);
      
      cluster = md.cluster;
      md.cluster = load_cluster('');
      md.cluster.executionpath = './tmp_execution';
   
      md = loadresultsfromcluster(md);
   
      md.cluster = cluster;
   
      % Save model with results
      filename = ['./models/' branch '/' branch '.proj.' ensembleID '.ssa.tr'];
      fprintf(['saving ' filename '\n']);
      save(filename, 'md', '-v7.3');
   end
end
%%}}}
%%}}}

