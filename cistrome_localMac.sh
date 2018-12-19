# download cistrome data from http://cistrome.org/db/#/bdown
# enter in Name, Lab PI, Institute, Email
# choose Human_Factor (or whichever one you're interested in)
# agree to the terms and submit
# after receiving the cistrome email, use the link to download dataset

# prep data on my mac
# first, download and unzip
cd  ~/workspace/db/giggle/hg38/cistrome
mkdir Human_Factor
cd Human_Factor
wget http://cistrome.org/db/batchdata/24KRO157XZ5Y204IEVFN.tar.gz
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
| sed "s/;/-/g" \
> name_reference.tab

mkdir ../renamed
cd human_factor/

while read -r old_name new_name; do cp $old_name ../../renamed/$new_name; done < ../name_reference.tab

# bgzip the renamed bed files
# note: use forloop to avoid the "Argument list too long" error
cd ../../renamed/
for i in *.bed; do bgzip $i; done
cd ..

# sort the bgzipped bed files
# note: subset into batches to avoid the "Argument list too long" error
mkdir sorted

~/repos/giggle/scripts/sort_bed "renamed/*.[1-3]*.bed.gz" sorted/ 8
~/repos/giggle/scripts/sort_bed "renamed/*.[4]*.bed.gz" sorted/ 8
~/repos/giggle/scripts/sort_bed "renamed/*.[5-6]*.bed.gz" sorted/ 8
~/repos/giggle/scripts/sort_bed "renamed/*.[7-9]*.bed.gz" sorted/ 8

# check that we have the right num of files
# should be 11348 files total
find sorted/ -name "*.gz" | wc -l
# yay 11348

# then run giggle index
# EXCEPT this needs to be able to open all of the input files at once
# so make sure to increase the default Mac open-file limit

# First, check the current file limit
ulimit -a
# core file size          (blocks, -c) 0
# data seg size           (kbytes, -d) unlimited
# file size               (blocks, -f) unlimited
# max locked memory       (kbytes, -l) unlimited
# max memory size         (kbytes, -m) unlimited
# open files                      (-n) 256
# pipe size            (512 bytes, -p) 1
# stack size              (kbytes, -s) 8192
# cpu time               (seconds, -t) unlimited
# max user processes              (-u) 1418
# virtual memory          (kbytes, -v) unlimited

# The Mac default is 256. Increase it (only for this terminal session)
ulimit -n 12000

# Check that it changed successfully
ulimit -a
# core file size          (blocks, -c) 0
# data seg size           (kbytes, -d) unlimited
# file size               (blocks, -f) unlimited
# max locked memory       (kbytes, -l) unlimited
# max memory size         (kbytes, -m) unlimited
# open files                      (-n) 12000
# pipe size            (512 bytes, -p) 1
# stack size              (kbytes, -s) 8192
# cpu time               (seconds, -t) unlimited
# max user processes              (-u) 1418
# virtual memory          (kbytes, -v) unlimited

# now giggle index
time giggle index -i "sorted/*gz" -o indexed -f -s 

# Indexed 235577369 intervals.
# real	14m53.052s
# user	9m52.631s
# sys	1m57.864s

# then to giggle search, just do something like:
time giggle search -i indexed -q TEST.h3k27ac.uniq_peaks.broadPeak.bed.gz -s > output.giggleStats

# real	2m53.734s
# user	1m5.155s
# sys	0m28.559s

# important note: need to keep the ulimit set to 12000 for both giggle indexing and searching
# this could make things tricky for cluster use...
# guess could always break the dataset up (into bundles less than the file limit on fiji)

######################################################################################

TODO: 
Make a filtered dataset (i.e. keep only peaks with q>100 which is col 9 in narrowPeak file format). 
And only keep files with =>100 peaks. See giggle manuscript for recommendations.

Then do the same for the other cistrome datasets, and then roadmap and fanthom etc.
