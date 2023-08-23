% Plots for one model
h = figure;
plotmodel(md, 'data', md.results.StressbalanceSolution.FrictionCoefficient-md.friction.coefficient, 'mask#all', md.mask.ice_levelset<0, 'caxis', [-25 25], 'figure', h.Number)

h = figure;
plotmodel(md, 'data', md.results.StressbalanceSolution.Vel-md.inversion.vel_obs, 'mask#all', md.mask.ice_levelset<0, 'caxis', [-500 500], 'figure', h.Number)

pos = find(md.inversion.vel_obs > 500);
figure;
hist(md.results.StressbalanceSolution.Vel(pos) - md.inversion.vel_obs(pos), 1000);
mean(md.results.StressbalanceSolution.Vel(pos) - md.inversion.vel_obs(pos))
std(md.results.StressbalanceSolution.Vel(pos) - md.inversion.vel_obs(pos))

% Histograms for all models -- high-velocity points
pos = md1.mask.ice_levelset<0 & md1.inversion.vel_obs>1000;
vel_diff_1 = md1.results.StressbalanceSolution.Vel(pos) - md1.inversion.vel_obs(pos);
vel_diff_2 = md2.results.StressbalanceSolution.Vel(pos) - md2.inversion.vel_obs(pos);
vel_diff_3 = md3.results.StressbalanceSolution.Vel(pos) - md3.inversion.vel_obs(pos);
vel_diff_4 = md4.results.StressbalanceSolution.Vel(pos) - md4.inversion.vel_obs(pos);

close all;
figure; hold on;
histogram(vel_diff_1, 1000, 'FaceAlpha', 0.5);
histogram(vel_diff_2, 1000, 'FaceAlpha', 0.5);
histogram(vel_diff_3, 1000, 'FaceAlpha', 0.5);
histogram(vel_diff_4, 1000, 'FaceAlpha', 0.5);
xlim([-250,250])

