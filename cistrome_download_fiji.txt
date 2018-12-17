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
time giggle search -i indexed -q test.bed.gz -s > output_test.gigglestats

# real	1m8.986s
# user	1m0.721s
# sys	0m7.353s

# make sure that everyone can read and write to the databases
cd /Users/CL_Shared/db
chmod -R g=u giggle/
# note: email Jon to see if we can make this the default setting

################################################################################
# HUMAN Histone

cd /Users/CL_Shared/db/giggle/hg38/cistrome/Human_Histone
mv GTYPP2KEMBOVQL3DDGS2.tar.gz Human_Histone.tar.gz

mkdir raw
mv Human_Histone.tar.gz raw/

mkdir split
tar -xvf raw/Human_Histone.tar.gz -C split/
cd split

mkdir tmp
tar -zxvf human_hm.tar.gz -C tmp/
mv tmp/human_hm/ .
rm -r tmp

# rename narrowpeak files into informative names
# take care to remove special characters e.g: /, ', ;, (, )
# also keep the original number associated with each file
cat human_hm.txt \
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
cd human_hm/

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
# should be 11079 files total
find sorted/ -name "*.gz" | wc -l
# yay 11079

# now giggle index
giggle index -i "sorted/*gz" -o indexed -f -s 

# oops forgot to time it

# then to giggle search, do something like:
cp ../Human_Factor/test.bed.gz .
time giggle search -i indexed -q test.bed.gz -s > output

# real	3m45.422s
# user	1m51.326s
# sys	0m23.725s

################################################################################
# HUMAN Chromatin Accessibility

cd ../Human_Chromatin_Accessibility
mv R56Q7GGRZEY7L4PH4RA9.tar.gz Human_Chromatin_Accessibility.tar.gz

mkdir raw
mv Human_Chromatin_Accessibility.tar.gz raw/

mkdir split
tar -xvf raw/Human_Chromatin_Accessibility.tar.gz -C split/
cd split

mkdir tmp
tar -zxvf human_ca.tar.gz -C tmp/
mv tmp/human_ca/ .
rm -r tmp

# rename narrowpeak files into informative names
# take care to remove special characters e.g: /, ', ;, (, )
# also keep the original number associated with each file
cat human_ca.txt \
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
cd human_ca/

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

~/repos/giggle/scripts/sort_bed "renamed/*.[1-5]*.bed.gz" sorted/ 8
~/repos/giggle/scripts/sort_bed "renamed/*.[6-9]*.bed.gz" sorted/ 8

# check that we have the right num of files
# should be 2412 files total
find sorted/ -name "*.gz" | wc -l
# yay 2412

# now giggle index
time giggle index -i "sorted/*gz" -o indexed -f -s 

# Indexed 156698929 intervals.
# real	27m56.544s
# user	6m44.420s
# sys	1m24.182s

# then to giggle search, do something like:
cp ../Human_Factor/test.bed.gz .
time giggle search -i indexed -q test.bed.gz -s > output_test.gigglestats

# real	0m40.316s
# user	0m33.363s
# sys	0m5.152s
