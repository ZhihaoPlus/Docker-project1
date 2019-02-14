#!/bin/sh

###################### EDIT FIELDS ##############################

f_read_ext="_L001_R1_001.fastq.gz"
r_read_ext="_L001_R2_001.fastq.gz"

f_reads=${1}${f_read_ext}
r_reads=${1}${r_read_ext}
#r_reads=${2}
folder=$2
output=${1}

###################### EDIT FIELDS ############################

left_seq="agtcctcttctaccccaccc"
right_seq="tgtgttatgtctaagagtag"
chr=">chr2"
min=60493771 # hg38
max=60496771
amplicon="agtcctcttctaccccacccacgcccccaccctaatcagaggccaaacccttcctggagcctgtgataaaagcaactgttagcttgcactagactagcttcaaagttgtattgaccctggtgtgttatgtctaagagtag"
min_len=71

######################### PATHS ################################

CLEAN_ADAPTER_PATH=/home/nextgen/pipelines/BSO182113/clean_adapter.rb
NW_PATH=/home/nextgen/tools/seq-align/bin/needleman_wunsch
PRINSEQ_PATH=/home/nextgen/tools/prinseq-lite-0.20.4/prinseq-lite.pl
BOWTIE_INDEXED_GEN=/home/nextgen/BSO182113/hg38_bt

################################################################

# Set up additional variables
left_motif="^"$left_seq
right_motif=$right_seq"$"

######################### Run ################################
# create TEMP folder
mkdir ${output}_TEMP_FILES

# Prepare sequences (remove adapters and merge pairs)
SeqPrep  -f $folder/$f_reads -r $folder/$r_reads -1 ${output}_TEMP_FILES/${f_reads}.out.gz -2 ${output}_TEMP_FILES/${r_reads}.out.gz -s ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.gz  -3 ${output}_TEMP_FILES/${r_reads}.${f_reads}.3 -4 ${output}_TEMP_FILES/${r_reads}.${f_reads}.4

# Run fastQC to check quality of reads
mkdir ${output}_fastqc_out
fastqc $folder/$f_reads $folder/$r_reads ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.gz --outdir=./${output}_fastqc_out

# Filter reads that correspond to expected amplicon
zcat ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.gz | ruby $CLEAN_ADAPTER_PATH $left_seq $right_seq | grep $left_motif -A 2 -B 1 --ignore-case --no-group-separator | grep $right_motif --ignore-case -A 2 -B 1 --no-group-separator > ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.clean.fastq

#Filter on quality - no trim
cat ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.clean.fastq | perl $PRINSEQ_PATH -fastq stdin -min_qual_score 15 -out_good ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean

# Check alignment with bowtie
bowtie2 -x $BOWTIE_INDEXED_GEN -U ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.fastq -S ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.sam -p 1
samtools sort ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.sam > ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.bam
samtools index ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.bam

# Remove sequences that map outside the amplicon
samtools view ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.bam | awk -v chr="$chr" -v min="$min" -v max="$max" '$2==4 || ($2==0 && $3==chr && $4>=min && $4<=max)'  |  awk -v minlen="$min_len" 'length($10)>=minlen' > ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.on_target

# Re-align sequences using NW algorithm
for i in `gawk '{print $10}'  ${output}_TEMP_FILES/${r_reads}.${f_reads}.merged.prinseq.clean.on_target ` ; do $NW_PATH --gapopen -4 $i $amplicon  | paste -s -d '\t'; done > ${output}.NW

################################################################

