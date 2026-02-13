#!/bin/bash
# Interactive metagenomics with Anvi'o
# Best for visualization and manual binning

CONTIGS="assembly/contigs.fa"
R1="reads/sample_R1.fastq"
R2="reads/sample_R2.fastq"
THREADS=8

# Create contigs database
anvi-gen-contigs-database -f $CONTIGS -o contigs.db -n "My_Project"

# Annotate
anvi-run-hmms -c contigs.db -T $THREADS
anvi-run-ncbi-cogs -c contigs.db -T $THREADS
anvi-run-kegg-kofams -c contigs.db -T $THREADS

# Map reads
bowtie2-build $CONTIGS contigs_index
bowtie2 -x contigs_index -1 $R1 -2 $R2 -S sample.sam -p $THREADS
samtools view -bS sample.sam | samtools sort -o sample_sorted.bam
anvi-init-bam sample_sorted.bam -o sample_final.bam

# Profile
anvi-profile -i sample_final.bam -c contigs.db -o PROFILE -T $THREADS

# Interactive interface
echo "Run: anvi-interactive -p PROFILE/PROFILE.db -c contigs.db"
