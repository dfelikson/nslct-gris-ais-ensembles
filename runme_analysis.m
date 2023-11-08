function plot_mass_change_rate(mds) %%{{{
   % Plot mass change rate
   figure; hold on;
   h_lines = [];
   res_rss_1yr = [];
   res_rss_3yr = [];
   res_rss_5yr = [];
   for i = 1:numel(models)
      time = [mds{i}.results.TransientSolution(:).time];
      vol  = [mds{i}.results.TransientSolution(:).IceVolumeAboveFloatation]; % m3
      mass = vol * mds{i}.materials.rho_ice * 1e-12; % Gt
   
      if strcmp(ensembleIDs{i}, 'G003')
         time = time(1:end-4);
         mass = mass(1:end-4);
      end
      if strcmp(ensembleIDs{i}, 'E024')
         h_lines(end+1) = nan;
         res_rss_1yr(end+1) = nan;
         res_rss_3yr(end+1) = nan;
         res_rss_5yr(end+1) = nan;
         continue
      end
   
      rate = diff(mass)./diff(time);
   
      if i == idx_best
         h_lines(end+1) = plot(time(2:end), rate, 'Color', 'r', 'LineWidth', 3);
      else
         h_lines(end+1) = plot(time(2:end), rate, 'Color', [50, 156, 201]/255, 'LineWidth', 1);
      end
   
      % Residual RSS - mean(dM/dt) over final 1 yr
      res_rss_1yr(end+1) = sqrt( (mean(rate(find(time==2014):end)) - mean(rate_imbie(find(time_imbie==2014):end))).^2 );
      % Residual RSS - mean(dM/dt) over final 3 yr
      res_rss_3yr(end+1) = sqrt( (mean(rate(find(time==2012):end)) - mean(rate_imbie(find(time_imbie==2012):end))).^2 );
      % Residual RSS - mean(dM/dt) over final 5 yr
      res_rss_5yr(end+1) = sqrt( (mean(rate(find(time==2010):end)) - mean(rate_imbie(find(time_imbie==2010):end))).^2 );
   end
   
   plot(time_imbie(2:end), rate_imbie, 'k-', 'LineWidth', 2)
   xlabel('time (year)')
   ylabel('mass change rate (Gt/yr)')
   white_bg_and_font(gcf, gca, 14);
   export_fig(['mass_change_rate_' ensembleGroup 'XXXX.pdf']);
end
%%}}}

[~, branch] = system('git branch --show-current');
branch = strip(branch);

% Load models
ensembleIDs = {};
for i = 1:8
   ensembleIDs{i} = sprintf('K9%02.0f', i);
end

models = {};
for i = 1:numel(ensembleIDs)
   models{i} = ['models/' branch '/' branch '.relaxation.' ensembleIDs{i} '.ssa.tr'];
end
model_names = ensembleIDs;

mds = {};
for i = 1:numel(ensembleIDs)
   if exist(models{i}, 'file')
      fprintf('Loading model %s\n', models{i})
      mds{end+1} = loadmodel(models{i});
   else
      fprintf('Model %s not found. Skipping.\n', models{i})
   end
end

colors = cbrewer('qual', 'Set2', numel(models));
styles = {'-', '--'};
% Plot mass change
plot_mass_change(mds, ensembleIDs, false);
return

% Plot LHS parameters
calving = 'VM';
lhs_file = ['ensemble_LHS_' calving '.txt'];
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

figure
plot(s_VM(:,1), s_VM(:,2)/1000, 'ko', 'MarkerFaceColor', 'k');
xlabel('friction change (%)')
ylabel('von Mises threshold (kPa)')
white_bg_and_font(gcf, gca, 14);
export_fig(['LHS_parameters_' ensembleGroup 'XXXX.pdf']);

% % Plot initial velocity
% for i = [1]
%    plotmodel(mds{i}, 'data', mds{i}.results.StressbalanceSolution.Vel, 'caxis', [0 1500], ...
%                      'mask', mds{i}.mask.ice_levelset<0, ...
%                      'unit', 'km', 'figure', 1, 'figposition', [0 0 1000 1000])
%                      %'data', mds{i}.inversion.vel_obs, 'caxis#2', [0 1500], ...
%                      %'data', mds{i}.results.StressbalanceSolution.Vel-mds{i}.inversion.vel_obs, 'caxis#3', [-250 250], ...
% end

return

[~, idx_best] = min(res_rss_5yr);
[~, idx_worst] = max(res_rss_5yr);

% Plot ice extent %%{{{
steps = [11 21 31 41];
for i = [idx_best, idx_worst]
   plot_ice_extent(mds{i}, 'source', 'transient', 'style', 'contours', 'steps', steps);
   break
end
%%}}}
return

% Plot velocity change %%{{{
for i = 1:2 %numel(models)
   hFig = figure;
   md = mds{i};
   plotmodel(md, 'data', md.results.TransientSolution(end).Vel - md.results.TransientSolution(1).Vel, ...
      'mask', md.results.TransientSolution(end).MaskIceLevelset<0, ...
      'caxis', [-500 500], 'colormap', cbrewer('div', 'RdBu', 11), 'figure', hFig.Number);
end
%%}}}

% Plot thickness change %%{{{
for i = 1:2 %numel(models)
   hFig = figure;
   md = mds{i};
   plotmodel(md, 'data', md.results.TransientSolution(end).Thickness - md.results.TransientSolution(1).Thickness, ...
      'mask', md.results.TransientSolution(end).MaskIceLevelset<0, ...
      'caxis', [-500 500], 'colormap', cbrewer('div', 'RdBu', 11), 'figure', hFig.Number);
end
%%}}}

