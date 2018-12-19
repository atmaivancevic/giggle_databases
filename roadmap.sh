#!/bin/bash

# jump onto a node
srun -N 1 -c 8 --propagate=NONE --pty bash

# setup dir
cd /Users/CL_Shared/db/giggle/hg38
mkdir roadmap
cd roadmap

# download hg38 roadmap epigenomics bed files
wget https://egg2.wustl.edu/roadmap/data/byFileType/chromhmmSegmentations/ChmmModels/coreMarks/jointModel/final/all_hg38lift.mnemonics.bedFiles.tgz
mkdir raw 
mv all_hg38lift.mnemonics.bedFiles.tgz raw/
cd raw

# unzip 
mkdir ../split
tar zxvf all_hg38lift.mnemonics.bedFiles.tgz -C ../split/
cd ../split

# right now the files names are quite useless
# want to rename them to something reflecting the epigenome/cell line
# Ryan provides the cell line type for each file, E001 to E129
# (which is from the epigenome google spreadsheet at https://egg2.wustl.edu/roadmap/web_portal/meta.html)
cp ~/repos/giggle/examples/rme/EDACC_NAME.txt .

# rename files based on the EDACC names
cat EDACC_NAME.txt | awk '{print $1 "_15_coreMarks_hg38lift_mnemonics.bed.gz" "\t" $2 ".bed.gz" }' > name_reference.tab
mkdir ../renamed
while read -r old_name new_name; do cp $old_name ../renamed/$new_name; done < name_reference.tab
cd ..

# sort 
mkdir sorted
~/repos/giggle/scripts/sort_bed "renamed/*.bed.gz" sorted/ 8

# index 
time giggle index -i "sorted/*gz" -o indexed -f -s 

# Indexed 56440237 intervals.

# real	3m49.564s
# user	1m25.004s
# sys	0m11.982s

# remove unnecessary dir
rm -r renamed

# important note: each of these 127 epigenome bed files contains regions representing a bunch of different states
# so we can also create separate databases split by state

# From roadmap 
# https://egg2.wustl.edu/roadmap/web_portal/chr_state_learning.html:

# STATE NO. 	MNEMONIC 	DESCRIPTION	COLOR NAME	COLOR CODE
# 1	TssA	Active TSS	Red	255,0,0
# 2	TssAFlnk	Flanking Active TSS	Orange Red	255,69,0
# 3	TxFlnk	Transcr. at gene 5' and 3'	LimeGreen	50,205,50
# 4	Tx	Strong transcription	Green	0,128,0
# 5	TxWk	Weak transcription	DarkGreen	0,100,0
# 6	EnhG	Genic enhancers	GreenYellow	194,225,5
# 7	Enh	Enhancers	Yellow	255,255,0
# 8	ZNF/Rpts	ZNF genes & repeats	Medium Aquamarine	102,205,170
# 9	Het	Heterochromatin	PaleTurquoise	138,145,208
# 10	TssBiv	Bivalent/Poised TSS	IndianRed	205,92,92
# 11	BivFlnk	Flanking Bivalent TSS/Enh	DarkSalmon	233,150,122
# 12	EnhBiv	Bivalent Enhancer	DarkKhaki	189,183,107
# 13	ReprPC	Repressed PolyComb	Silver	128,128,128
# 14	ReprPCWk	Weak Repressed PolyComb	Gainsboro	192,192,192
# 15	Quies	Quiescent/Low	White	255,255,255

# each bed file has four tab-delim columns:
# chromosome, start (0-based), end (1-based), state_label for that region

# categorize by column 4
module load samtools
cd sorted

for i in 1_TssA 2_TssAFlnk 3_TxFlnk 4_Tx 5_TxWk 6_EnhG 7_Enh 8_ZNF 9_Het 10_TssBiv 11_BivFlnk 12_EnhBiv 13_ReprPC 14_ReprPCWk 15_Quies;
do
	mkdir -p ../sorted_$i;
	for j in *.bed.gz; do zcat $j | grep $i > ../sorted_$i/${j%.bed.gz}.$i.bed && bgzip ../sorted_$i/${j%.bed.gz}.$i.bed; done;
done

# then index each one
cd ..

for i in 1_TssA 2_TssAFlnk 3_TxFlnk 4_Tx 5_TxWk 6_EnhG 7_Enh 8_ZNF 9_Het 10_TssBiv 11_BivFlnk 12_EnhBiv 13_ReprPC 14_ReprPCWk 15_Quies;
do
	time giggle index -i "sorted_"$i"/*gz" -o indexed_"$i" -f -s;
done

# Indexed 2522587 intervals.

# real	0m10.176s
# user	0m3.462s
# sys	0m0.538s
# Indexed 3650868 intervals.

# real	0m16.835s
# user	0m5.084s
# sys	0m0.920s
# Indexed 277757 intervals.

# real	0m2.388s
# user	0m0.396s
# sys	0m0.158s
# Indexed 3887567 intervals.

# real	0m22.877s
# user	0m5.613s
# sys	0m1.234s
# Indexed 10422225 intervals.

# real	1m1.326s
# user	0m15.211s
# sys	0m3.168s
# Indexed 1302262 intervals.

# real	0m10.166s
# user	0m1.862s
# sys	0m0.607s
# Indexed 11211068 intervals.

# real	1m3.151s
# user	0m15.566s
# sys	0m3.347s
# Indexed 731689 intervals.

# real	0m5.524s
# user	0m0.939s
# sys	0m0.330s
# Indexed 4076699 intervals.

# real	0m28.909s
# user	0m5.965s
# sys	0m1.534s
# Indexed 495352 intervals.

# real	0m3.135s
# user	0m0.824s
# sys	0m0.194s
# Indexed 647974 intervals.

# real	0m3.185s
# user	0m0.900s
# sys	0m0.181s
# Indexed 1099775 intervals.

# real	0m7.473s
# user	0m1.178s
# sys	0m0.321s
# Indexed 2435300 intervals.

# real	0m18.316s
# user	0m3.557s
# sys	0m1.027s
# Indexed 4115104 intervals.

# real	0m35.382s
# user	0m6.134s
# sys	0m2.007s
# Indexed 9564010 intervals.

# real	1m9.420s
# user	0m14.630s
# sys	0m3.872s

