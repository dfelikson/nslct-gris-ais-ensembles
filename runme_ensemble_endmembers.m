% Forcings:
%  A.) EN4
%  B.) ASTE
%  C.) ORAS5
%
% Varied model parameters:
%  1.) calving: von Mises sigma max
%      - bounds: 500 kPa to 1500 kPa
%  2.) rheology: ice temperature
%      - bounds: -10% to +10%
%  3.) friction: friction coefficient
%      - bounds: -10% to +10%

addpath(genpath('/Users/dfelikso/Software/ScriptsAndUtilities/matlab'));

relaxation_start_yr =  0; calving = 'VM'; ensembleGroup = 'K';
%relaxation_start_yr =  5; calving = 'VM'; ensembleGroup = 'L';
%relaxation_start_yr = 20; calving = 'VM'; ensembleGroup = 'M';

ocean_forcing = 'EN4';

% Setup end members
calving = 'VM';
rheology_end_members  = [0.9     0.9   0.9     0.9   1.1    1.1   1.1     1.1];
friction_end_members  = [0.9     0.9   1.1     1.1   0.9    0.9   1.1     1.1];
sigma_max_end_members = [5e5   1.5e6   5e5   1.5e6   5e5  1.5e6   5e5   1.5e6];

[~, branch] = system('git branch --show-current');
branch = strip(branch);
if ~exist(['./models/' branch], 'dir')
   mkdir(['./models/' branch]);
end

% Run
% mesh / param / inversion / relaxation
runme_mesh;
for i = 1:length(friction_end_members) %%{{{
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);

   rheology  = rheology_end_members(i);
   friction  = friction_end_members(i);
   sigma_max = sigma_max_end_members(i);

   runme_param;
   runme_inversion;
   runme_relaxation;
   %runme_relaxation_ensembleprep_from000;
end
%%}}}

for i = 1:length(friction_end_members)
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Loading relaxation for ensembleID: ' ensembleID green_text_end '\n']);

   runme_relaxation_loadresultsfromcluster;
end

% Run moving front
for i = 1:length(friction_end_members) %%{{{
   ensembleID = sprintf('%1s9%02d', ensembleGroup, i);
   % Moving front
   fprintf('\n');
   fprintf('Preparing frontalforcings\n');
   if i == 1
      md = loadmodel(['./models/' branch '/' branch '.relaxation.' ensembleID '.ssa.tr']);

      % Start and end time setup
      md.timestepping.time_step=0.01; % need to adjust for CFL
      md.timestepping.start_time=2007; %years
      md.timestepping.final_time=2020; %years
      md.settings.output_frequency=20; % output every Nth timestep

      % Slater and Straneo (2022) frontal forcings -- scaled with bed depth
      [md_basins, twglaciers] = parameterize_slater_straneo_submelt(md);
      t = eval(['twglaciers(1).ocean.' ocean_forcing '.t']);
      idx_start = find(t >= md.timestepping.start_time, 1, 'first');
      idx_final = find(t <= md.timestepping.final_time, 1, 'last');
      t = t(idx_start:idx_final);
      fprintf([yellow_highlight_start 'Using ocean forcing: %s' yellow_highlight_end '\n'], ocean_forcing);
      frontalforcings_meltingrate = 0 * ones(md.mesh.numberofvertices+1,length(t));
      frontalforcings_meltingrate(end,:) = t;
      for i_twg = 1:numel(twglaciers)
         pos = find(md_basins == twglaciers(i_twg).basin_num);
         if ~isempty(pos)
            bed_min = min(md.geometry.bed(pos));

            z = eval(['twglaciers(i_twg).ocean.' ocean_forcing '.z']);
            Q_sg = interp1(twglaciers(i_twg).runoff.RACMO.t, twglaciers(i_twg).runoff.RACMO.Q, t) * (86400/1000000);
            TF = eval(['twglaciers(i_twg).ocean.' ocean_forcing '.TF']);
            TF = TF(:,idx_start:idx_final);
            if min(z) > bed_min;
               z(end+1) = bed_min;
               TF(end+1,:) = TF(end,:);
            end

            TF_interp = interp1(z, TF, md.geometry.bed(pos));
            frontalforcings_meltingrate(pos,:) = ((3e-4 .* -md.geometry.bed(pos) .* Q_sg.^0.39 + 0.15) .* TF_interp.^1.18) .* 365;
         end
      end

      % Cleanup
      pos = find(md.geometry.bed > 0);
      frontalforcings_meltingrate(pos,:) = 0;
      pos = find(isnan(frontalforcings_meltingrate));
      frontalforcings_meltingrate(pos) = 0;
   end

   fprintf('\n');
   fprintf([green_text_start 'Running moving front for ensembleID: ' ensembleID green_text_end '\n']);

   runme_movingfront;
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

