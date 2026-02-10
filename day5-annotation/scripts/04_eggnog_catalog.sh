#!/bin/bash
#SBATCH --job-name=eggnog_catalog
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=750G
#SBATCH --time=336:00:00
#SBATCH --partition=camplab
#SBATCH -o /project/bcampb7/camplab/AL_JJ_oct23/substrate_FRed/00_logs/eggnog_catalog_%j.out
#SBATCH -e /project/bcampb7/camplab/AL_JJ_oct23/substrate_FRed/00_logs/eggnog_catalog_%j.err

source ~/.bashrc
conda activate /home/jojyj/.conda/envs/eggnog_env

# Use the existing, working database
export EGGNOG_DATA_DIR=/project/bcampb7/camplab/nichole_jo_trial/eggnog-mapper-2.1.12/data

OUTDIR="/project/bcampb7/camplab/AL_JJ_oct23/substrate_FRed/05_eggnog"
mkdir -p ${OUTDIR}

echo "Starting eggNOG annotation..."
echo "Database: ${EGGNOG_DATA_DIR}"
echo "Input: /project/bcampb7/camplab/AL_JJ_oct23/substrate_FRed/01_catalog/MG_gene_catalog90.faa"
date

# For eggNOG-mapper v2.1.12, the syntax is different:
# -i input file (proteins assumed by default)
# -m diamond (method)
# --cpu (threads)
# --output (output prefix)
# --output_dir (output directory)

emapper.py \
  -i /project/bcampb7/camplab/AL_JJ_oct23/substrate_FRed/01_catalog/MG_gene_catalog90.faa \
  -m diamond \
  --output MG_catalog \
  --output_dir ${OUTDIR} \
  --cpu 32 \
  --data_dir ${EGGNOG_DATA_DIR} \
  --override

echo "eggNOG annotation complete"
date

# Show output files
ls -lh ${OUTDIR}/MG_catalog.*
