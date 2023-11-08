function plot_mass_change(mds, ensembleIDs, plot_imbie)
   figure; hold on;
   h_lines = [];
   for i = 1:numel(mds)
      time = [mds{i}.results.TransientSolution(:).time];
      vol  = [mds{i}.results.TransientSolution(:).IceVolumeAboveFloatation]; % m3
      mass = vol * mds{i}.materials.rho_ice * 1e-12; % Gt
   
      plot(time, mass-mass(1), 'LineWidth', 2);
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
      
      [~, idx_start] = min(abs(time_imbie-time(1)));
      [~, idx_end  ] = min(abs(time_imbie-time(end)));
      time_imbie = time_imbie(idx_start:idx_end);
      mass_imbie = mass_imbie(idx_start:idx_end)-mass_imbie(idx_start);
      rate_imbie = diff(mass_imbie)./diff(time_imbie);
      u = uncr_imbie(idx_start:idx_end);
      plot(time_imbie, mass_imbie, 'k-', 'LineWidth', 2)
      %patch([t fliplr(t)], m+[u fliplr(-u)], [0.1 0.1 0.1])
      
      legend_str{end+1} = 'IMBIE';
   end

   legend(legend_str)
   
   xlabel('time (year)')
   ylabel('mass change (Gt)')
   white_bg_and_font(gcf, gca, 14);
   %export_fig(['mass_change_' ensembleGroup 'XXXX.pdf']);
end

