function cluster = load_cluster(cluster_name)

   switch cluster_name
      case {'','gs15serac'}
         cluster = generic('name', oshostname(), 'np', 2);
         cluster.interactive = 1;
         waitonlock = Inf;
   
      case 'oibserve'
         cluster = generic('name', 'gs615-oibserve.ndc.nasa.gov', 'np', 28, ...
            'login', 'dfelikso', ...
            'codepath', '/home/dfelikso/Software/ISSM/trunk-jpl/bin', ...
            'etcpath', '/home/dfelikso/Software/ISSM/trunk-jpl/etc', ...
            'executionpath', '/home/dfelikso/Projects/GrIS_Calibrated_SLR/ISSM/execution');
         cluster.interactive = 0;
         waitonlock = 0;
   
      case 'discover'
         cluster=discover;
         cluster.name='discover.nccs.nasa.gov';
         cluster.login='dfelikso';
         cluster.project='s2321';
         cluster.numnodes=1;
         cluster.cpuspernode=nan; %16;
         cluster.time=1.0*60*60;
         cluster.processor='sand';
         cluster.queue='allnccs';
         cluster.codepath='/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/bin';
         cluster.executionpath='/discover/nobackup/dfelikso/Software/ISSM/trunk-jpl/execution';
         cluster.email='denis.felikson@nasa.gov';
   
         cluster.interactive = 0;
         waitonlock = 0;
   
   end

end % main function

