function plot_mass_change(mds, ensembleIDs, colors, plot_imbie, plot_mougn)
   figure; hold on;
   h_lines = [];
   for i = 1:numel(mds)
      time = mds(i).historical.time;
      vol  = mds(i).historical.IceVolumeAboveFloatation; % m3
      mass = vol * 917 * 1e-12; % Gt
      mass_init = mass(2);
      plot(time, mass-mass_init, 'color', colors(i,:), 'LineWidth', 2);

      time = mds(i).proj.time;
      vol  = mds(i).proj.IceVolumeAboveFloatation; % m3
      mass = vol * 917 * 1e-12; % Gt
      plot(time, mass-mass_init, 'color', colors(i,:), 'LineWidth', 2, 'HandleVisibility', 'off');
      
      %if i == idx_best
      %   h_lines(end+1) = plot(time, mass-mass(1), 'Color', 'r', 'LineWidth', 3);
      %else
      %   h_lines(end+1) = plot(time, mass-mass(1), 'Color', [89, 205, 255]/255, 'LineWidth', 1);
      %end
   end
   
   legend_str = ensembleIDs;
   
   % Plot IMBIE
   if plot_imbie
      imbie_data = xlsread('/Users/dfelikso/Research/Data/IMBIE/imbie_dataset_greenland_dynamics-2020_02_28.xlsx');
      time_imbie = imbie_data(145:end,1);
      mass_imbie = imbie_data(145:end,4);
      uncr_imbie = imbie_data(145:end,5);
      
      time_obs = time_imbie;
      mass_obs = mass_imbie;
      uncr_obs = uncr_imbie;
   end
   if plot_mougn
      mougn_data = xlsread('/Users/dfelikso/Zotero/storage/M89GPQ4A/Proceedings_of_the_National_Academy_of_Sciences_2019_Mouginot.xlsx', '(2) MB_GIS', 'AY31:BJ39');
      time_mougn = mougn_data(1,:);
      mass_mougn = mougn_data(4,:);
      
      time_obs = time_mougn;
      mass_obs = cumsum(mass_mougn);
   end

   if plot_imbie | plot_mougn
      %[~, idx_start] = min(abs(time_obs-time(1)));
      %[~, idx_end  ] = min(abs(time_obs-time(end)));
      %time_obs = time_obs(idx_start:idx_end);
      %mass_obs = mass_obs(idx_start:idx_end) - mass_obs(idx_start);
      %rate_imbie = diff(mass_imbie)./diff(time_imbie);
      %u = uncr_imbie(idx_start:idx_end);
      plot(time_obs, mass_obs, 'k-', 'LineWidth', 2)
      %patch([t fliplr(t)], m+[u fliplr(-u)], [0.1 0.1 0.1])
      
      legend_str{end+1} = 'observations';

   end

   legend(legend_str)
   
   xlabel('time (year)')
   ylabel('mass change (Gt)')
   white_bg_and_font(gcf, gca, 14);
   %export_fig(['mass_change_' ensembleGroup 'XXXX.pdf']);
end

