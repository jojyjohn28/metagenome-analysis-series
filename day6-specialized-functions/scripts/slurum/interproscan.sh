#!/bin/bash

#SBATCH --job-name=interproscan_batch       # Job name
#SBATCH --nodes=1                          # Number of nodes
#SBATCH --cpus-per-task=8                # Number of CPU cores per task
#SBATCH --mem=350gb                        # Memory allocation
#SBATCH --time=72:00:00                   # Max runtime (14 days)
#SBATCH --mail-type=ALL                    # Notification type
#SBATCH --output=interproscan_%j.out       # Standard output
#SBATCH --error=interproscan_%j.err        # Standard error

# Ensure Conda is initialized
module load anaconda3/2023.09-0
source activate interproscan_jjnew

# Add InterProScan to the PATH
export PATH="/home/jojyj/interproscan-5.72-103.0:$PATH"
cd /home/jojyj/interproscan-5.72-103.0

# Directory containing protein FASTA files
input_dir="/project/bcampb7/camplab/Alisha/WGS_All_Fred_project/all_protein"

# Directory to store InterProScan outputs
output_dir="/project/bcampb7/camplab/Alisha/WGS_All_Fred_project/interproscan_output"
mkdir -p "$output_dir"

# Loop through all .faa files in the input directory
for file in "$input_dir"/*.faa; do
    # Get the base name of the current file
    base_name=$(basename "$file" .faa)
   
# Run InterProScan for the current file
  interproscan.sh \
        -i "$file" \
        -f tsv \
        -o "$output_dir/${base_name}.tsv" \
        -cpu 32
done