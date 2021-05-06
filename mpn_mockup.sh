#!/bin/bash

#---------------------------------------------------
#Author  - Aman Rajput
#Created - 01/May/2021
#---------------------------------------------------


echo "+reading parameters"

#---------------------------------------------------

for ARGUMENT in "$@"    # all input arguments
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            sf)              source_file=${VALUE} ;;
            lf)              lookup_file=${VALUE} ;;    
            ifs)             ifs=${VALUE} ;;   
            lfs)             lfs=${VALUE} ;;  
            cols)            cols=${VALUE} ;; 
            skp)             skip=${VALUE} ;;   
            drp)             drop=${VALUE} ;;
            *)   
    esac    
done

#---------------------------------------------------

skip="${skip:-0}"    #setting default values for parameters
drop="${drop:-0}"
ifs="${ifs:-,}"
lfs="${lfs:-,}"


rm ${source_file}_output.csv >/dev/null 2>&1     #removing any pre-existing output file

# ------------------------------------------------------------------------------------------------------------------------------------------------------------


if [ -z "$source_file" ] | [ -z "$lookup_file" ] | [ -z "$cols" ]   #checking mandatory parameters
then
echo "Insufficient parameters"
exit 1
fi

# ------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "+Using input file field separator $ifs"
echo "+Using lookup file field separator $lfs"
# ------------------------------------------------------------------------------------------------------------------------------------------------------------

if [[ -f $source_file ]]   # checking if source file exist
then
 true
else
    echo "--------------------- $source_file does not exist ---------------------"
    exit 1
fi

if [[ -f $lookup_file ]]   #checking if lookup file exist
then
 true
else
    echo "--------------------- $lookup_file does not exist ---------------------"
    exit 1
fi

# ------------------------------------------------------------------------------------------------------------------------------------------------------------

if [ $skip -gt 0 ]            #copying header into output file if skip is specified?
then

head -n $skip $source_file >> ${source_file}_output.csv

fi


echo "+Skipping $skip row(s) in the source file"

awk -F $ifs -v sk=$skip ' NR > sk { print } '  $source_file >> sourcedata1  #copying source data into a temp file

og_source=$source_file


# ------------------------------------------------------------------------------------------------------------------------------------------------------------

#code to check multifile.


#-------------------------------------------------------------------------------------------------------------------------------------------------------------

echo "+Counting number of rows in data and lookup file"    #counting row in the input file and lookup file

data_rows=`sed -n '=' $source_file | wc -l`
lkp_rows=`sed -n '=' $lookup_file | wc -l`

echo "+Total number of records in" `basename $og_source` "is $data_rows"
echo "+Total number of records in" `basename $lookup_file` "is $lkp_rows"

#-------------------------------------------------------------------------------------------------------------------------------------------------------------


#Created temporary files"

no_of_keys=`awk -F $lfs ' END{ print NF }' $lookup_file`

read -a keyarr <<< "$cols"      #reading column numbers  of the input file which are key in the lookup file


if [ ${#keyarr[*]} -ne $no_of_keys ]   
then

 #checking if number of keys column in lookup match with the provided number of col in parameter

echo " --------------------- Data feed key columns do not match with the lookup key columns ---------------------"
echo " --------------------- Please provide key column number in data feed in the cols parameter	 ---------------------"
echo " --------------------- Column number in the cols parameter should be space separated and double quoted	 ---------------------"

rm ${source_file}_output.csv
rm sourcedata1
exit 1

fi


#-------------------------------------------------------------------------------------------------------------------------------------------------------------

#create temporary file for keys in source file

i=1

for val in "${keyarr[@]}";
do
echo "+Fetching keys from the data feed into the file >>>>>>>>>>>>> " keysnotfound${i}
awk -F $ifs -v col=$val -v sk=$skip ' { print $col; }'  $source_file > keysnotfound${i}
i=$((i + 1))
done

#-------------------------------------------------------------------------------------------------------------------------------------------------------------

#create temporary file for keys in lookup file

for ((i = 1 ; i <= $no_of_keys ; i++)); do
echo "+Fetching keys from the lookup feed into the file >>>>>>>>>>>>> " templookupfile${i}
awk -F $lfs -v col=$i -v sk=$skip ' { print $col }'  $lookup_file  > templookupfile${i}
done

#-------------------------------------------------------------------------------------------------------------------------------------------------------------

#filtering out keys which are not present in source file

for ((i = 1 ; i <= $no_of_keys ; i++)); do

grep -F -x -v -f keysnotfound${i} templookupfile${i} > keysnotfound${i}   

echo "+Filtering the keys in lookup for which data is not present in the data feed >>>>>>>> " keysnotfound${i}

done


rm templookupfile*  #deleting temporary lookup key files
#-------------------------------------------------------------------------------------------------------------------------------------------------------------

#updating records with the keys in lookup file


count=0
i=1

echo "+Creating records for the filtered out keys "

for val in "${keyarr[@]}";
do


count=0
while read dataline <&3 && read keyline <&4; do    
           
          echo "$dataline" | awk -F $ifs -v col=$val -v line="$keyline" ' { $col=line; print $0 ;} ' OFS=$ifs >> sourcedata2
          
          count=$((count + 1)) 
      
done 3<sourcedata1 4<keysnotfound${i}


cat sourcedata2 > sourcedata1
true > sourcedata2



i=$((i + 1))

done


cat sourcedata1 | sort | uniq >> ${source_file}_output.csv  # distinct records in output file

count=$((count + skip + 1))

#-------------------------------------------------------------------------------------------------------------------------------------------------------------

#checking if remaining data in source file
#needs to be loaded in output file (keys will not match for this data) 0 = load data, 1 = do not load data
#default value is 0

if [ $drop -eq 0 ]     
then
tail -n +${count} $og_source | sort | uniq >> ${source_file}_output.csv # distinct records in output file
fi

#-------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------

echo "+Removing temporary files"   #removing all temporary files

rm keysnotfound*
rm sourcedata*

sed -i '/^$/d' ${source_file}_output.csv  #removing any blank line in output file


#-------------------------------------------------------------------------------------------------------------------------------------------------------------



echo "+All lookup keys updated in the file >>>>>>>> "  ${source_file}_output.csv




