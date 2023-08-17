h = figure;
plotmodel(md, 'data', md.results.StressbalanceSolution.FrictionCoefficient-md.friction.coefficient, 'mask#all', md.mask.ice_levelset<0, 'caxis', [-25 25], 'figure', h.Num)

h = figure;
plotmodel(md, 'data', md.results.StressbalanceSolution.Vel-md.inversion.vel_obs, 'mask#all', md.mask.ice_levelset<0, 'caxis', [-25 25], 'figure', h.Number)

pos = find(md.inversion.vel_obs > 500);
figure;
hist(md.results.StressbalanceSolution.Vel(pos) - md.inversion.vel_obs(pos), 1000);
mean(md.results.StressbalanceSolution.Vel(pos) - md.inversion.vel_obs(pos))
std(md.results.StressbalanceSolution.Vel(pos) - md.inversion.vel_obs(pos))

