Parameters

lookuptool.sh sf=employees.csv lf=data.lkp ifs=, lfs=, cols="6" skp=1 drp=0

          sf    ->  Data file location                 example: sf="/home/external/data.csv"       No default value
          lf    ->  Lookup file location               example: lf="/home/external/lookup.dat"     No default value
          ifs   ->  Input file field separator         example: ifs=|                              Default value = ,
          lfs   ->  Lookup file field separator        example: ifs=|                              Default value = ,
          cols  ->  lookup key columns in input file   example: cols="2 3 5"                       No default value
          skp   ->  Number of rows to skip in          example: skp=1                              Default value = 0
                    input file (header)
          drp   ->  If set to 1 it does not copy       example: drp=1                              Default value = 0
                    the remaining records to output
                    after all keys are updated in 
                    the data file.
                    (if there are 10 records in
                     lookup file only 10 will be 
                     generated in output)


NOTE -> cols parameter must be separated with space and double quoted.
        sequence of cols parameter must be same as columns in lookup file

        for example:

        if lookup file has entry like 
        
        148.124.213.63,Harry
       
        and data file 

        1,Pietrek,Coakley,pcoakley0@utexas.edu,Agender,53.144.39.41

        then cols parameter sequence should be 

        cols="6 2"
       
        Script does not handle header in the lookup file.