#!/bin/bash
#SBATCH --job-name=final_qc
#SBATCH --output=logs/slurm/final_qc_%j.out
#SBATCH --error=logs/slurm/final_qc_%j.err
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=compute

# Script: 06_final_qc_summary_slurm.sh
# Description: Final QC check and read count summary (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 06_final_qc_summary_slurm.sh

# Load modules
module load fastqc/0.11.9
module load multiqc/1.12

# Set variables
THREADS=${SLURM_CPUS_PER_TASK}

# Create directories
mkdir -p qc/fastqc_final
mkdir -p logs/slurm

echo "Starting final QC..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# FastQC on final cleaned reads
echo "Running FastQC on final reads..."
fastqc -o qc/fastqc_final \
       -t ${THREADS} \
       decontaminated_phix/*_final.fastq.gz

# MultiQC report
echo "Generating MultiQC report..."
multiqc qc/fastqc_final \
        -o qc/multiqc_final \
        -n final_reads_report

# Compare read counts across all steps
echo "Generating read count summary..."
echo "Sample,Raw,Trimmed,Decontaminated,Final" > read_count_summary.csv

for R1 in raw_data/*_R1.fastq.gz; do
    sample=$(basename ${R1} _R1.fastq.gz)
    
    echo "Counting reads for ${sample}..."
    
    raw=$(zcat raw_data/${sample}_R1.fastq.gz | wc -l | awk '{print $1/4}')
    trimmed=$(zcat trimmed/${sample}_R1_paired.fastq.gz | wc -l | awk '{print $1/4}')
    decontam=$(zcat decontaminated/${sample}_R1_clean.fastq.gz | wc -l | awk '{print $1/4}')
    final=$(zcat decontaminated_phix/${sample}_R1_final.fastq.gz | wc -l | awk '{print $1/4}')
    
    echo "${sample},${raw},${trimmed},${decontam},${final}" >> read_count_summary.csv
done

echo "Final QC complete!"
echo "Summary saved to: read_count_summary.csv"
echo "MultiQC report: qc/multiqc_final/final_reads_report.html"
