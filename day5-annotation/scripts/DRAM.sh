#!/bin/bash

#SBATCH --job-name=DRAM                  # Job name
#SBATCH --nodes=1                        # Number of nodes
#SBATCH --cpus-per-task=32               # Number of CPU cores
#SBATCH --gpus-per-node=a100:1           # Number of GPUs
#SBATCH --mem=1500gb                     # Memory allocation
#SBATCH --time=72:00:00                  # Max runtime
#SBATCH --output=dram_%j.out             # Standard output
#SBATCH --error=dram_%j.err              # Standard error

# Load the DRAM module and activate Conda environment
module load dram/1.4.6
source /project/cugbf/software/gbf/DRAM/1.4.6.sh

# Change to the directory containing the FASTA files
cd /project/bcampb7/camplab/Alisha/WGS_All_Fred_project/WGS_all || exit

# Ensure output directory exists
output_dir="/project/bcampb7/camplab/Alisha/WGS_All_Fred_project/output_DRAM/annotation"
mkdir -p "$output_dir"

# Run DRAM annotation
DRAM.py annotate \
    -i /project/bcampb7/camplab/Alisha/WGS_All_Fred_project/WGS_all/*.fasta \
    -o "$output_dir" \
    --threads 32

# DRAM distill step
DRAM.py distill \
    -i "$output_dir/annotations.tsv" \
    -o "$output_dir/genome_summaries"
    
    
 
