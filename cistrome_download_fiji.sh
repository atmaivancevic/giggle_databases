# download cistrome data from http://cistrome.org/db/#/bdown
# enter in Name, Lab PI, Institute, Email
# choose Human_Factor (or whichever one you're interested in)
# agree to the terms and submit
# after receiving the cistrome email, use the link to download dataset

srun -N 1 -c 8 --propagate=NONE --pty bash
# IMPORTANT NOTE: must include --propagate=NONE to have the user-specific high ulimit

cd /Users/CL_Shared/db/giggle/hg38
mkdir cistrome
cd cistrome

mkdir Human_Factor
mkdir Human_Histone
mkdir Human_Chromatin_Accessibility

cd Human_Factor
wget http://cistrome.org/db/batchdata/24KRO157XZ5Y204IEVFN.tar.gz

cd ../Human_Histone
wget http://cistrome.org/db/batchdata/GTYPP2KEMBOVQL3DDGS2.tar.gz

cd ../Human_Chromatin_Accessibility
wget http://cistrome.org/db/batchdata/R56Q7GGRZEY7L4PH4RA9.tar.gz

################################################################################
# HUMAN Factor

cd ../Human_Factor
mv 24KRO157XZ5Y204IEVFN.tar.gz Human_Factor.tar.gz

mkdir raw
mv Human_Factor.tar.gz raw/

mkdir split
tar -xvf raw/Human_Factor.tar.gz -C split/
cd split

mkdir tmp
tar -zxvf human_factor.tar.gz -C tmp/
mv tmp/human_factor/ .
rm -r tmp

# rename narrowpeak files into informative names
# take care to remove special characters e.g: /, ', ;, (, )
# also keep the original number associated with each file
cat human_factor.txt \
| sed 's/ /_/g' \
| sed 's#/#-#g' \
| awk '{print $8 "\t" $4"_"$5"_"$6"_"$7}' \
| grep -v "Cell_line_Cell_type_Tissue_type_Factor" \
| sed 's/_/ /' \
| awk '{print $1"_"$2 "\t" $3"."$1".bed"}' \
| sed "s/'//g" \
| sed "s/(//g" \
| sed "s/)//g" \
| sed "s/,//g" \
| sed "s/;/-/g" \
> name_reference.tab

mkdir ../renamed
cd human_factor/

while read -r old_name new_name; do cp $old_name ../../renamed/$new_name; done < ../name_reference.tab

# bgzip the renamed bed files
# note: use forloop to avoid the "Argument list too long" error
cd ../../renamed/
module load samtools
for i in *.bed; do bgzip $i; done
cd ..

# sort the bgzipped bed files
# note: run it in batches to avoid the "Argument list too long" error
mkdir sorted

~/repos/giggle/scripts/sort_bed "renamed/*.[1-3]*.bed.gz" sorted/ 8
~/repos/giggle/scripts/sort_bed "renamed/*.[4]*.bed.gz" sorted/ 8
~/repos/giggle/scripts/sort_bed "renamed/*.[5-6]*.bed.gz" sorted/ 8
~/repos/giggle/scripts/sort_bed "renamed/*.[7-9]*.bed.gz" sorted/ 8

# check that we have the right num of files
# should be 11348 files total
find sorted/ -name "*.gz" | wc -l
# yay 11348

# now giggle index
time giggle index -i "sorted/*gz" -o indexed -f -s 

# Indexed 235577369 intervals.
# real	63m51.067s
# user	17m57.820s
# sys	3m43.730s

# then to giggle search, do something like:
time giggle search -i indexed -q test.bed.gz -s > test.giggleout

# real	1m8.986s
# user	1m0.721s
# sys	0m7.353s

# make sure that everyone can read and write to the databases
cd /Users/CL_Shared/db
chmod -R g=u giggle/
# note: email Jon to see if we can make this the default setting
# yay Jon fixed it

# also want to make a subset of good quality peaks only
# since there's a lot of crap out there
mkdir filtered_q100

# retain peaks with a q-value greater than 100
cd renamed
for i in *.bed.gz; do zcat $i | awk '{if ($9>100) print}' > ../filtered_q100/${i%.bed.gz}.filtq100.bed; done

# remove files with 0 peaks
cd ../filtered_q100
find . -type f -empty -delete

# do a file count to see how many left
ls *.bed | wc -l
# 10797

# then bgzip
for i in *.bed; do bgzip $i; done
cd ..

# sort the filtered files, as before
mkdir sorted_q100

~/repos/giggle/scripts/sort_bed "filtered_q100/*.[1-3]*.bed.gz" sorted_q100/ 8
~/repos/giggle/scripts/sort_bed "filtered_q100/*.[4]*.bed.gz" sorted_q100/ 8
~/repos/giggle/scripts/sort_bed "filtered_q100/*.[5-6]*.bed.gz" sorted_q100/ 8
~/repos/giggle/scripts/sort_bed "filtered_q100/*.[7-9]*.bed.gz" sorted_q100/ 8

# index
time giggle index -i "sorted_q100/*gz" -o indexed_q100 -f -s 

# So indexed/ is the unflitered set of all peaks, and indexed_q100/ contains only peaks with q>100

# Remove unnecessary dirs
rm -r renamed
rm -r filtered_q100

# Note: for now, going to keep sorted/ and sorted_q100/, for easy look-up inside the bed files that contain peaks
# Also keep raw/ (which contains the downloaded .tar.gz) and split/ (which contains a record of the original names versus new names)
# Altogether this dir takes up ~ 31gb

################################################################################

# Then want to do the same for the other cistrome databases

# Human_Histone: GTYPP2KEMBOVQL3DDGS2.tar.gz, 11079 files total, 8721 files after filtering (q>100)

# Human_Chromatin_Accessibility: R56Q7GGRZEY7L4PH4RA9.tar.gz, 2412 files total, 2055 files after filtering (q>100)

# Mouse_Factor: R9MXVUTB72SQ8FJLMWXU.tar.gz, 9060 files total, ___ files after filtering (q>100)

# Mouse_Histone: DPOUA6WA6SNLMRHVC7GW.tar.gz, 10944 files total, ___ files after filtering (q>100)

# Mouse_Chromatin_Accessibility: FGRVH30PLYTNOQPXMCUL.tar.gz, 2358 files total, ___ files after filtering (q>100)


