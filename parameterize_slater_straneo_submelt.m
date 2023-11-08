function [md_basins, twglaciers] = parameterize_slater_straneo_submelt(md)
   load /Users/dfelikso/Research/Projects/N-SLCT/GitRepositories/slater_2022_submelt/data/twglaciers.mat
   load /Users/dfelikso/Research/Projects/ISMIP6/GrIS_Ocean_Forcing/Tidewater_Basins/mat/basins4highres.mat
   load /Users/dfelikso/Research/Projects/ISMIP6/GrIS_Ocean_Forcing/Tidewater_Basins/mat/basins4highres_xy.mat

   b = basins;
   clear basins;
   basins = struct();
   basins.basin = flipud(double(b));
   basins.x = x';
   basins.y = flipud(y');
   [xm, ym] = meshgrid(basins.x, basins.y);
   basins.xm = xm;
   basins.ym = ym;

   %close all
   %figure
   % Find basin extent for each TWG
   for i_twg = 1:numel(twglaciers)
      dist = (twglaciers(i_twg).x - basins.xm).^2 + (twglaciers(i_twg).y - basins.ym).^2;
      [~,i] = min(dist(:));
      [r,c] = ind2sub(size(basins.xm), i);

      basin_num = basins.basin(r,c);
      twglaciers(i_twg).basin_num = basin_num;

      %imagesc(basins.x, basins.y, basins.basin==basin_num);
      %hold on
      %set(gca,'YDir','normal');
      %axis('equal');
      %plot(twglaciers(i_twg).x, twglaciers(i_twg).y, 'r.', 'markersize', 20);
      %pause(0.5);
      %clf

   end

   %md_basins = InterpFromGridToMesh(basins.x, basins.y, basins.basin, md.mesh.x, md.mesh.y, 0);
   md_basins = InterpFromGridToMesh_matlab(basins.x, basins.y, basins.basin, md.mesh.x, md.mesh.y, 0, 'nearest');

end


