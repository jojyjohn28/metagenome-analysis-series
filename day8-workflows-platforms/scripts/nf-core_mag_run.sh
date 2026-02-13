#!/bin/bash
# Quick launcher for nf-core/mag pipeline
# Modern, reproducible Nextflow workflow

# Create sample sheet template
# Edit this CSV with your sample info
cat > samplesheet.csv << 'EOF'
sample,group,short_reads_1,short_reads_2,long_reads
sample1,group1,sample1_R1.fastq.gz,sample1_R2.fastq.gz,
sample2,group1,sample2_R1.fastq.gz,sample2_R2.fastq.gz,
sample3,group2,sample3_R1.fastq.gz,sample3_R2.fastq.gz,
EOF

# Run nf-core/mag
nextflow run nf-core/mag \
    --input samplesheet.csv \
    --outdir results_nfcore \
    --skip_spades \
    --megahit_fix_cpu_1 \
    --min_contig_size 1500 \
    --busco_db bacteria_odb10 \
    -profile docker,test \
    -resume
