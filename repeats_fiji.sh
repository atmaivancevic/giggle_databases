#!/bin/bash

# jump onto a node
srun -N 1 -c 8 --propagate=NONE --pty bash

# setup a repeats dir
cd /Users/CL_Shared/db/giggle/hg38
mkdir -p repeats
cd repeats

# get the repeat bed files from the genomes dir
cp -r /Users/CL_Shared/db/genomes/hg38/repeats/eachRep .

# bgzip them
module load samtools
cd eachRep
for i in *.bed; do bgzip $i; done
cd ..

# sort
mkdir sorted
~/repos/giggle/scripts/sort_bed "eachRep/*.bed.gz" sorted/ 8

# check that all files are there
# should be 1315 repeat bed files
find sorted/ -name "*.gz" | wc -l
# 1315

# index
time giggle index -i "sorted/*gz" -o indexed -f -s 

# Indexed 5302311 intervals.

# real	1m38.037s
# user	0m14.792s
# sys	0m8.453s

# remove superfluous dirs
# e.g. don't need eachRep because we have all the repeats in sorted/
rm -r eachRep

# for convenience, also made separate databases for the main repeat classes
# i.e. LINEs, SINEs, LTRs and DNA transposons
# respectively, these are in indexed_LINE/, indexed_SINE/, indexed_LTR/, and indexed_DNA/
# and the bed files are in sorted_LINE/, sorted_SINE/, sorted_LTR/, and sorted_DNA/

# for more info about different repeat families, see /Users/CL_Shared/db/giggle/hg38/repeats/groups/repeat_families.txt
