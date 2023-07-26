% Forcings:
%  A.) EN4
%  B.) ASTE
%  C.) ORAS5
%
% Varied model parameters:
%  1.) calving: von Mises sigma max
%      - bounds: 400 kPa to 1200 kPa
%  2.) rheology: ice temperature
%      - bounds: -10 deg C to -3 deg C
%  3.) friction: friction coefficient
%      - bounds: -10% to +10%

n_ensemble_members = 25;

rheology = 0; relaxation_start_yr =  5; calving = 'VM'; ensembleGroup = 'E';
%rheology = 0; relaxation_start_yr = 10; calving = 'VM'; ensembleGroup = 'F';
rheology = 0; relaxation_start_yr = 20; calving = 'VM'; ensembleGroup = 'G';
%rheology = 0; relaxation_start_yr =  5; calving = 'CD'; ensembleGroup = 'H';
%rheology = 0; relaxation_start_yr = 10; calving = 'CD'; ensembleGroup = 'I';
%rheology = 0; relaxation_start_yr = 20; calving = 'CD'; ensembleGroup = 'J';

sliding = 1;

ocean_forcing = 'EN4';

% Setup the ensemble
lhs_file = ['ensemble_LHS_' calving '.txt'];
if ~exist(lhs_file,'file') %%{{{
   s_VM = lhsu([-10, 400], [+10, 1200], n_ensemble_members);
   s_CD = lhsu([-10,   0], [+10,   75], n_ensemble_members);
   
   f = fopen(lhs_file,'w');
   for i = 1:n_ensemble_members
      ensembleID = sprintf('%1s%03d', ensembleGroup, i);
      switch calving
         case 'VM'
            friction  = s_VM(i,1);
            sigma_max = s_VM(i,2);
            fprintf(f, '%4s: %6.2f %8.2f\n', ensembleID, friction, sigma_max);
         case 'CD'
            friction    = s_CD(i,1);
            water_depth = s_CD(i,2);
            fprintf(f, '%4s: %6.2f %8.2f\n', ensembleID, friction, water_depth);
      end
   end
%%}}}
else %%{{{
   fprintf('Using existing LHS file: %s\n', lhs_file);
   switch calving
      case 'VM'
         s_VM = [];
   end
   fid = fopen(lhs_file);
   tline = fgetl(fid);
   while ischar(tline)
      tline_split = split(tline);
      s_VM(end+1,1) = str2num(tline_split{2});
      s_VM(end  ,2) = str2num(tline_split{3});
      tline = fgetl(fid);
   end
   fclose(fid);
end
%%}}}

% Run
% param / inversion / relaxation
if false
%%{{{
for i = 1:n_ensemble_members
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');
   switch calving
      case 'VM'
         friction  = s_VM(i,1);
         sigma_max = s_VM(i,2);
      case 'CD'
         friction    = s_CD(i,1);
         water_depth = s_CD(i,2);
   end
   
   if i == 1
      %runme_param;
      %runme_inversion;
      runme_relaxation;
   else
      %runme_relaxation_from001;
   end
end
%%}}}
end

% Load relaxation results
if false
%%{{{
f = fopen('tmp_execution/tmp_rsync_list.txt', 'w');
for i = 1:n_ensemble_members
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   if exist(['models/ice_temperature_HO/gris.relaxation.' ensembleID '.ssa.tr'],'file')
      fprintf('Output file already exists. Skipping.\n');
      continue
   end
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');
   switch calving
      case 'VM'
         friction  = s_VM(i,1);
         sigma_max = s_VM(i,2);
      case 'CD'
         friction    = s_CD(i,1);
         water_depth = s_CD(i,2);
   end
   
   filename = ['./models/ice_temperature_HO/gris.relaxation.' ensembleID '.ssa.tr.sent2cluster'];
   md = loadmodel(filename);
   fprintf(f, '%s/gris_ssa_sbinv.errlog\n', md.private.runtimename);
   fprintf(f, '%s/gris_ssa_sbinv.outlog\n', md.private.runtimename);
   fprintf(f, '%s/gris_ssa_sbinv.outbin\n', md.private.runtimename);
   
end
%%}}}
end

%rsync -avz --progress -d --files-from tmp_execution/tmp_rsync_list.txt dfelikso@discover.nccs.nasa.gov:/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/execution/ tmp_execution/

%runme_relaxation_loadresultsfromcluster;
if false
%%{{{
for i = 1:n_ensemble_members
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');

   % Relaxation
   filename = ['./models/ice_temperature_HO/gris.relaxation.' ensembleID '.ssa.tr.sent2cluster'];
   fprintf(['loading ' filename '\n']);
   md = loadmodel(filename);

   cluster = md.cluster;
   md.cluster = load_cluster('');
   md.cluster.executionpath = './tmp_execution';

   md = loadresultsfromcluster(md);

   md.cluster = cluster;

   % Save model with results
   filename = ['./models/ice_temperature_HO/gris.relaxation.' ensembleID '.ssa.tr'];
   fprintf(['saving ' filename '\n']);
   save(filename, 'md', '-v7.3');
end
%%}}}
end
  
% Run moving front
if false
%%{{{
for i = 1:n_ensemble_members
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');

   % Moving front
   switch calving
      case 'VM'
         friction  = s_VM(i,1);
         sigma_max = s_VM(i,2);
      case 'CD'
         friction    = s_CD(i,1);
         water_depth = s_CD(i,2);
   end
   
   if i == 1
      md = loadmodel(['./models/ice_temperature_HO/gris.relaxation.' ensembleID '.ssa.tr']);

      % Start and end time setup
      md.timestepping.time_step=0.05;%0.01; % need to adjust for CFL
      md.timestepping.start_time=2007; %years
      md.timestepping.final_time=2016; %years
      md.settings.output_frequency=4; % output every Nth timestep

      % Slater and Straneo (2022) frontal forcings
      [md_basins, twglaciers] = parameterize_slater_straneo_submelt(md);
      idx_start = find(twglaciers(1).submelt.t >= md.timestepping.start_time, 1, 'first');
      idx_final = find(twglaciers(1).submelt.t <= md.timestepping.final_time, 1, 'last');
      ocean_forcing = evalin('base', 'ocean_forcing');
      fprintf([yellow_highlight_start 'Using ocean forcing: %s' yellow_highlight_end '\n'], ocean_forcing);
      frontalforcings_meltingrate = 0 * ones(md.mesh.numberofvertices+1,length(twglaciers(1).submelt.t(idx_start:idx_final)));
      frontalforcings_meltingrate(end,:) = twglaciers(1).submelt.t(idx_start:idx_final);
      for i_twg = 1:numel(twglaciers)
         submelt = eval(['twglaciers(i_twg).submelt.m_' ocean_forcing]);
         pos = find(md_basins == twglaciers(i_twg).basin_num);
         frontalforcings_meltingrate(pos,:) = repmat(submelt(idx_start:idx_final), length(pos), 1) * 365.25;
         if any(isnan(frontalforcings_meltingrate(pos,:)))
            fprintf('WARNING: NaNs in meltingrate for twglacier idx %d (%s, morlighem_number %d, basin %d)\n', i_twg, twglaciers(i_twg).name, twglaciers(i_twg).morlighem_number, twglaciers(i_twg).basin_num);
         end
      end
      pos = find(md.geometry.bed > 0 );
      frontalforcings_meltingrate(pos,:) = 0;
   end

   runme_movingfront;
end
%%}}}
end

% Load moving front results
if false
%%{{{
f = fopen('tmp_execution/tmp_rsync_list.txt', 'w');
for i = 1:n_ensemble_members
   ensembleID = sprintf('%1s%03d', ensembleGroup, i);
   fprintf('\n');
   fprintf([green_text_start 'Running ensembleID: ' ensembleID green_text_end '\n']);
   fprintf('\n');
   switch calving
      case 'VM'
         friction  = s_VM(i,1);
         sigma_max = s_VM(i,2);
      case 'CD'
         friction    = s_CD(i,1);
         water_depth = s_CD(i,2);
   end
   
   %runme_movingfront_loadresultsfromcluster;
   filename = ['./models/ice_temperature_HO/gris.movingfront.' ensembleID '.ssa.tr.sent2cluster'];
   md = loadmodel(filename);
   fprintf(f, '%s/gris_ssa_sbinv.errlog\n', md.private.runtimename);
   fprintf(f, '%s/gris_ssa_sbinv.outlog\n', md.private.runtimename);
   fprintf(f, '%s/gris_ssa_sbinv.outbin\n', md.private.runtimename);
end
%%}}}
end

%rsync -avz --progress -d --files-from tmp_execution/tmp_rsync_list.txt dfelikso@discover.nccs.nasa.gov:/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/execution/ tmp_execution/

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

