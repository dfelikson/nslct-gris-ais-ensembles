
[~, branch] = system('git branch --show-current');
branch = strip(branch);

% Load models
ensembleIDs = {};
for i = 1:8
   ensembleIDs{i} = sprintf('A9%02.0f', i);
end

models = {};
for i = 1:numel(ensembleIDs)
   %models{i} = ['models/' branch '/' branch '.relaxation.' ensembleIDs{i} '.ssa.tr'];
   models{i} = ['models/' branch '/' branch '.movingfront.' ensembleIDs{i} '.ssa.tr'];
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
%plot_mass_change(mds, ensembleIDs, false);
plot_mass_change(mds, ensembleIDs, false, true);
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

