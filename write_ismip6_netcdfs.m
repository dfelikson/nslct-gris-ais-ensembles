function write_ismip6_netcdfs(ensembleGroup, endmembers)

   [~, branch] = system('git branch --show-current');
   branch = strip(branch);

   % Load models
   if endmembers
      ensembleIDs = cell(1,9);
      for i = 0:8
         ensembleIDs{i+1} = sprintf('%s9%02.0f', ensembleGroup, i);
      end
   else
      ensembleIDs = cell(1,25);
      for i = 1:25
         ensembleIDs{i} = sprintf('%s%03.0f', ensembleGroup, i);
      end
   end

   mds = struct();
   for i = 1:numel(ensembleIDs)
      output_directory = './netcdfs';
      
      % Historical %%{{{
      output_netcdf_suffix = [ensembleIDs{i} '_hist'];
      if exist([output_directory '/' 'limnsw_' output_netcdf_suffix '.nc'])
         continue
      end

      model_name = ['models/' branch '/' branch '.movingfront.' ensembleIDs{i} '.ssa.tr'];
      if exist(model_name, 'file')
         fprintf('Loading model %s\n', model_name)
         md = loadmodel(model_name);
      else
         fprintf('Model %s not found. Skipping.\n', model_name)
         continue
      end

      idx = 6:5:66; % NOTE: hardcoded to output yearly
      time = [md.results.TransientSolution(idx).time];
      vx = [md.results.TransientSolution(idx).Vx];
      vy = [md.results.TransientSolution(idx).Vy];
      MAF = [md.results.TransientSolution(idx).IceVolumeAboveFloatation] * 917;

      % Write velocity
      fprintf(' -> writing velocity\n');
      write_ismip6_velocity_netcdfs(md.mesh.elements, md.mesh.x, md.mesh.y, time, vx, vy, output_directory, output_netcdf_suffix);

      % Write MAF
      fprintf(' -> writing MAF\n');
      write_ismip6_MAF_netcdf(time, MAF, output_directory, output_netcdf_suffix);

      fprintf('\n');
      %%}}}
      % Projection %%{{{
      output_netcdf_suffix = [ensembleIDs{i} '_proj'];
      if exist([output_directory '/' 'limnsw_' output_netcdf_suffix '.nc'])
         continue
      end

      model_name = ['models/' branch '/' branch '.proj.' ensembleIDs{i} '.ssa.tr'];
      if exist(model_name, 'file')
         fprintf('Loading model %s\n', model_name)
         md = loadmodel(model_name);
      else
         fprintf('Model %s not found. Skipping.\n', model_name)
         continue
      end

      idx = 6:5:66; % NOTE: hardcoded to output yearly
      time = [md.results.TransientSolution(idx).time];
      vx = [md.results.TransientSolution(idx).Vx];
      vy = [md.results.TransientSolution(idx).Vy];
      MAF = [md.results.TransientSolution(idx).IceVolumeAboveFloatation] * 917;

      % Write velocity
      fprintf(' -> writing velocity\n');
      write_ismip6_velocity_netcdfs(md.mesh.elements, md.mesh.x, md.mesh.y, time, vx, vy, output_directory, output_netcdf_suffix);

      % Write MAF
      fprintf(' -> writing MAF\n');
      write_ismip6_MAF_netcdf(time, MAF, output_directory, output_netcdf_suffix);

      fprintf('\n');

      return
      %%}}}
   end

end % main function

