#!/bin/bash

# Fri Jan 25

# download blueprint data 
# go to deepblue dashboard, experiments grid page (https://deepblue.mpi-inf.mpg.de/dashboard.php#ajax/deepblue_view_grid.php)
# first, download all H3K27ac chipseq bed files
# In Data types, select: Peaks (35075)
# In Projects, select: BLUEPRINT Epigenome (2485)
# In Genome, select: GRCh38 (2485)
# In Epigenetic Marks, select: H3K27ac (401)
# Then at the top left, click 'Select all experiments displayed in the Grid'
# These 401 entries should now appear at the bottom. Click 'Proceed to the download page'
# In the Download Options, got to Metadata, and from the dropdown menu add: Name, Epigenetic_Mark, Biosource, Sample_ID
# At the bottom, click 'Request Download'
# request id r3488283 (https://deepblue.mpi-inf.mpg.de/request.php?_id=r3488283) 
# now we wait..... (usually only takes a few min)

# Oops didn't work - Error:
# failed:
# The output string (4096MBytes) is bigger than the size that you are allowed to use: '4096 MBytes'. We recomend you to select fewer experiments, chromosomes, or check the metafields that you are using, for example the @SEQUENCE metafield.

# Try again, separating the data dump into two batches.
# Remember to include the same metadata columns each time (Name, Epigenetic_Mark, Biosource, Sample_ID)
# And keep the other columns default
# So altogether the columns should be:

# deepblue_data_r3488284.bed = venous blood (115 samples)
# deepblue_data_r3488285.bed = everything else (286 samples)
# 401 total for all chipseq h3k27ac 

# unzip and concatenate bed files 
cat deepblue_data_r3488284.bed deepblue_data_r3488285.bed > deepblue_data_chipseq_h3k27ac.bed

# upload to fiji
scp deepblue_data_chipseq_h3k27ac.bed ativ2716@fiji.colorado.edu:/Users/CL_Shared/db/giggle/hg38/blueprint/chipseq/H3K27ac

# column 11 contains the original bed file name for each entry
# seperate them back into the 401 individual bed files

# on fiji
srun --pty bash
cat deepblue_data_chipseq_h3k27ac.bed | awk '{print $11}' | sort | uniq > files.txt

while read -r file_name; do grep $file_name deepblue_data_chipseq_h3k27ac.bed > $file_name; done < files.txt

rm deepblue_data_chipseq_h3k27ac.bed
rm files.txt

# rename each bed file so that the file name includes the biosource (cell/tissue type), using the info in column 13
# first, make a reference dictionary for renaming
for i in *.bed; do  head -n 1 $i | awk -F "\t" '{print $11 "\t" $13}' | tr " " "_" | sed 's/,//g' | awk '{print $1 "\t" $2"."$1}' | awk '{gsub(/.bwa.GRCh38/,"",$2);print}'  ; done > name_reference.tab

# put all the individual bed files in a new dir
mkdir split
mv *.bed split

# make a new dir to put renamed bed files 
while read -r old_name new_name; do cp split/$old_name renamed/$new_name; done < name_reference.tab

# bgzip the renamed bed files
# note: use forloop to avoid the "Argument list too long" error
cd renamed/
module load samtools
for i in *.bed; do bgzip $i; done
cd ..

# sort the bgzipped bed files
mkdir sorted
~/repos/giggle/scripts/sort_bed "renamed/*.bed.gz" sorted/ 8

# check that we have the right num of files
# should be 401 files total
find sorted/ -name "*.gz" | wc -l
# yay 401

# now giggle index
time giggle index -i "sorted/*gz" -o indexed -f -s 

# Indexed - intervals.
# real	-
# user	-
# sys	-

# remove unnecessary dirs
rm -r renamed/
