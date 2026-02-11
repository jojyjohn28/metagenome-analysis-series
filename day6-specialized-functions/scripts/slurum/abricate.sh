#!/bin/bash

#SBATCH --job-name=ABricate
#SBATCH --partition=camplab                 # Job name
#SBATCH --nodes=1                           # Number of nodes
#SBATCH --cpus-per-task=32                  # Number of CPU cores
#SBATCH --gpus-per-node=a100:1              # Number of GPUs
#SBATCH --mem=150gb                         # Memory allocation
#SBATCH --time=72:00:00                     # Max runtime
#SBATCH --output=ABri_%j.out                # Standard output
#SBATCH --error=ABri_%j.err                 # Standard error

# Activate the environment 
conda activate /home/jojyj/.conda/envs/abricate_env

# Directory containing your FASTA files
fasta_dir="/project/bcampb7/camplab/Alisha/WGS_All_Fred_project/WGS_all"

# Directory to save the output files
output_dir="/project/bcampb7/camplab/Alisha/WGS_All_Fred_project/ABricate_results"

# Create the output directory if it doesn't exist
mkdir -p $output_dir

# List of databases you want to use
databases=("argannot" "card" "vfdb" "ncbi" "plasmidfinder" "resfinder" "megares")

# Loop through each FASTA file in the directory
for fasta_file in $fasta_dir/*.fasta; do
  # Initialize an empty list to store the output files for each FASTA file
  output_files=""
  
  # Loop through each database
  for db in "${databases[@]}"; do
    # Run Abricate for each database and save the output in the output directory
    abricate --db $db $fasta_file > ${output_dir}/$(basename ${fasta_file%.fasta})_${db}_out.tab
    output_files="${output_files} ${output_dir}/$(basename ${fasta_file%.fasta})_${db}_out.tab"  # Add the output file to the list
  done
  
  # Combine the individual database output files into a summary table for the current FASTA file
  abricate --summary $output_files > ${output_dir}/$(basename ${fasta_file%.fasta})_combined_summary.tab
  
  # Clean up individual output files
  rm $output_files
done

echo "Analysis complete! Summary files saved to $output_dir."
