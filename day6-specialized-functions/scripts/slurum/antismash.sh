#!/bin/bash

#SBATCH --job-name=antismash_batch
#SBATCH --partition=camplab
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=150gb
#SBATCH --time=336:00:00
#SBATCH --mail-type=ALL
#SBATCH --output=antismash_%j.out    # Standard output
#SBATCH --error=antismash_%j.err     # Standard error

# Load necessary modules
conda activate /home/jojyj/.conda/envs/bio_seq_env

# Direct to working directory
cd /project/bcampb7/camplab/alvee_jj_working/antismash-7.1.0

# Input directory with FASTA files
INPUT_DIR="/project/bcampb7/camplab/Jojy/MTM2_RoL/mg_all_asembly/all_contigs"

# Base output directory
BASE_OUTPUT_DIR="/project/bcampb7/camplab/alvee_jj_working/antismash_jj"

# Loop through each FASTA file in the input directory
for INPUT_FILE in $INPUT_DIR/*.fasta; do
  # Extract the base name of the FASTA file (without directory and extension)
  BASENAME=$(basename $INPUT_FILE .fasta)

  # Create an output directory based on the input file name
  OUTPUT_DIR="$BASE_OUTPUT_DIR/$BASENAME"

  # Create the output directory if it doesn't exist
  mkdir -p $OUTPUT_DIR

  # Run AntiSMASH with the specified parameters
  python3 /project/bcampb7/camplab/alvee_jj_working/antismash-7.1.0/run_antismash.py \
    $INPUT_FILE \
    --genefinding-tool 'prodigal-m' \
    --output-dir $OUTPUT_DIR 
    
done


