#!/bin/bash
#SBATCH --job-name=motus
#SBATCH --output=logs/slurm/motus_%j.out
#SBATCH --error=logs/slurm/motus_%j.err
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32G
#SBATCH --partition=compute

# Script: 09_motus_profiling_slurm.sh
# Description: Taxonomic profiling using mOTUs (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 09_motus_profiling_slurm.sh

# Load modules
module load motus/3.0.3

# Set variables
INPUT_DIR="decontaminated_phix"
OUTPUT_DIR="taxonomy/motus"
THREADS=${SLURM_CPUS_PER_TASK}

# Create output directory
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "Starting mOTUs taxonomic profiling..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_final.fastq.gz; do
    sample=$(basename ${R1} _R1_final.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_final.fastq.gz"
    
    echo "Running mOTUs on ${sample}..."
    
    # Run mOTUs profile
    motus profile \
        -f ${R1} \
        -r ${R2} \
        -t ${THREADS} \
        -n ${sample} \
        -o ${OUTPUT_DIR}/${sample}_profile.txt \
        -c \
        -k mOTU \
        -q
    
    echo "Completed ${sample}"
done

# Merge all profiles
echo "Merging all profiles..."
motus merge \
    -i ${OUTPUT_DIR}/*_profile.txt \
    -o ${OUTPUT_DIR}/merged_profiles.txt

echo "mOTUs analysis complete!"
echo "Merged profile: ${OUTPUT_DIR}/merged_profiles.txt"
