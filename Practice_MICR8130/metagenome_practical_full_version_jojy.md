#### Metagenome analysis_detailed work flow

### Quality Control & Taxonomic Profiling

### FastQC

gives a quick quality snapshot of sequencing data and MultiQC combines the results if you have many samples.

**Running on palmetto**

```bash
module avail fastqc
module load fastqc/0.12.1
cd /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data
mkdir -p fastqc_results #FastQC will NOT create the output directory automatically.
fastqc -o fastqc_results/ -f fastq /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/*.fastq.gz
```

**What if you have many samples, use the below batch script**

See fastqc.slurum in the /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/scripts
submit the job

```bash
 sbatch fastqc.slurm
scontrol show job <jobid> #check your job status
squeue -u $USER #check your job status, you forgot to note your jobid
```

**How to create the .slurum scripts?**

1. Uning Nano

```bash
cd /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data
nano fastqc.slurm
CTRL + O
ENTER
CTRL + X
```

2. Create Script in One Command_advanced

```bash
cat << 'EOF' > fastqc.slurm
#!/bin/bash
#SBATCH --job-name=fastqc_raw
#SBATCH --partition=camplab
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=your_email@clemson.edu
#SBATCH -o fastqc_%j.out
#SBATCH -e fastqc_%j.err

module load fastqc/0.12.1
cd /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data
mkdir -p fastqc_results
fastqc -t ${SLURM_CPUS_PER_TASK} -o fastqc_results -f fastq *.fastq.gz
EOF
```

#this will create same fastqc.slurum in the given folder 3. write the batch script on notepad/text editor and save it as fastqc.slurm and upload to your folder. (easy, very beginer way)
when you change the name it should show some colurs_check

### Adapter Trimming (Trimmomatic)

Why trim?
■ Remove adapters
■ Remove low-quality bases
■ Remove short reads

```bash
module avail trimmomatic
module load trimmomatic/0.39
java -jar $trimmomatic -h #Palmetto the module does not put trimmomatic-0.39.jar in your current folder. Instead, it sets an environment variable pointing to the jar so change the calling in default settings;java -jar $trimmomatic -h
cd /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data #no need to change
mkdir -p trimming_results
#on Palmetto2. please use
java -jar "$trimmomatic" PE \
  -threads 8 \
  -phred33 \
  ABF4_143_1.fastq \
  ABF4_143_2.fastq \
  ABF4_143_1_paired.fastq.gz \
  ABF4_143_1_unpaired.fastq.gz \
  ABF4_143_2_paired.fastq.gz \
  ABF4_143_2_unpaired.fastq.gz \
  ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:2:True \
  LEADING:3 \
  TRAILING:3 \
  SLIDINGWINDOW:4:15 \
  MINLEN:36 \
  2> ABF4_143_trimmomatic.log
#below is the default command
java -jar trimmomatic-0.39.jar PE \
  -threads 8 \
  -phred33 \
  ABF4_143_1.fastq \
  ABF4_143_2.fastq \
  ABF4_143_1_paired.fastq.gz \
  ABF4_143_1_unpaired.fastq.gz \
  ABF4_143_2_paired.fastq.gz \
  ABF4_143_2_unpaired.fastq.gz \
  ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:2:True \
  LEADING:3 \
  TRAILING:3 \
  SLIDINGWINDOW:4:15 \
  MINLEN:36 \
  2> ABF4_143_trimmomatic.log
```

● 📁 What are these output files?

Trimmomatic in PE (paired-end) mode produces 4 FASTQ files:

1. ABF4_143_1_paired.fastq.gz

✅ Forward reads (R1) that survived trimming AND still have a mate
👉 Use this for downstream paired-end analysis

2. ABF4_143_2_paired.fastq.gz

✅ Reverse reads (R2) that survived trimming AND still have a mate
👉 Use this together with the R1 paired file

3. ABF4_143_1_unpaired.fastq.gz

⚠ Forward reads where the reverse mate was dropped (too short/poor)
👉 Optional to keep; useful for some single-end analyses or debugging

4. ABF4_143_2_unpaired.fastq.gz

⚠ Reverse reads where the forward mate was dropped
👉 Same idea as above

**What if you have many samples?**

Use sbatch trimmomatic_batch.slurm from /scripts

● How to run

```bash
cd /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data
nano trimmomatic_batch.slurm   # paste script, set YOUR_EMAIL
sbatch trimmomatic_batch.slurm
```

● 🧬 What This Batch Script Does

This SLURM script automatically trims all paired-end FASTQ files in the folder.

**🔄 It Performs:**

1️⃣ Loads the Trimmomatic module on Palmetto
2️⃣ Loops through all _\_1.fastq / _\_1.fastq.gz files
3️⃣ Matches each forward read with its reverse pair
4️⃣ Runs Trimmomatic on each sample
5️⃣ Removes:

````
Adapters

Low-quality bases

Short reads
6️⃣ Saves:

● Paired reads (for analysis)
● Unpaired reads (optional)
● Log + summary files

📁 Output Generated

*_1_paired.fastq.gz → Clean forward reads
*_2_paired.fastq.gz → Clean reverse reads
*_unpaired.fastq.gz → Reads that lost their mate

Logs → Trimming statistics per sample

#### Post-Trimming QC
**ALWAYS rerun FastQC after trimming**
```bash
fastqc trimmed/*_paired.fastq.gz
multiqc qc/fastqc_trimmed
````

#### Host removal

**Metagenomic samples often contain host DNA (human, mouse, plant, etc.) that needs to be removed before analysis**

● Option 1: KneadData
KneadData is specifically designed for metagenomic data and integrates multiple tools.

```bash
mkdir -p decontaminated
mkdir -p logs/kneaddata

# Single sample
kneaddata \
    --input trimmed/sample1_R1_paired.fastq.gz \
    --input trimmed/sample1_R2_paired.fastq.gz \
    --output decontaminated/sample1 \
    --reference-db /path/to/databases/kneaddata_db/human_genome \
    --threads 16 \
    --trimmomatic /path/to/trimmomatic \
    --bypass-trim \
    --log logs/kneaddata/sample1.log

# Options:
# --bypass-trim : Skip trimming (already done with Trimmomatic)
# --reference-db : Path to host genome database
# --threads : Number of threads
```

● Option 2: BBDuk (Fast alternative)
BBDuk from BBTools is faster and uses less memory than KneadData.

```bash
bbduk.sh \
    in1=R1.fastq.gz \
    in2=R2.fastq.gz \
    out1=R1_clean.fastq.gz \
    out2=R2_clean.fastq.gz \
    ref=contaminants.fna \
    k=31 \
    hdist=1 \
    threads=16
```

#### Phix Removal

PhiX (PhiX174) is a small viral genome (~5.3 kb) added by Illumina during sequencing as a:

✅ Control for run quality
✅ Calibration reference
✅ Base balance stabilizer (especially for low-diversity libraries)
It is not part of your biological sample.

```bash
bbduk.sh \
    in1=trimmed/sample1_R1_paired.fastq.gz \
    in2=trimmed/sample1_R2_paired.fastq.gz \
    out1=clean/sample1_R1_clean.fastq.gz \
    out2=clean/sample1_R2_clean.fastq.gz \
    ref=bbmap/resources/phix174_ill.ref.fa.gz \
    k=31 \
    hdist=1 \
    threads=16
```

Read detailed version here : https://jojyjohn28.github.io/blog/metagenome-analysis-day1-qc-taxonomy/

#### Read-Based Taxonomic Profiling

We are currently not covering this.
if you are interested you can read at : https://jojyjohn28.github.io/blog/metagenome-analysis-day1-qc-taxonomy/ look for Read-Based Taxonomic Profiling

#### Metagenome Assembly​

**Use this decision tree to quickly choose the right assembler for your situation:**
START
│
├─ What type of reads do you have?
│ ├─ Illumina short reads → Continue below
│ ├─ ONT/PacBio long reads → Use Flye (--meta)
│ └─ Both (hybrid) → Use Flye + Pilon polishing
│
├─ How much RAM do you have?
│ ├─ ≤16 GB (laptop/desktop) → Use MEGAHIT
│ ├─ 32-64 GB (workstation) → Use MEGAHIT or IDBA-UD
│ └─ ≥128 GB (HPC) → Use metaSPAdes
│
├─ What's your priority?
│ ├─ Highest quality assembly → Use metaSPAdes
│ ├─ Fastest results → Use MEGAHIT
│ └─ Uneven coverage → Use IDBA-UD
│
└─ Special cases:
├─ Very large dataset (>100 GB) → Use MEGAHIT
├─ Extremely uneven coverage → Use IDBA-UD
└─ Novel/complex metagenome → Use metaSPAdes

**metaSPAdes Assembly**
metaSPAdes is part of the SPAdes assembler family, specifically designed for metagenomic data.

```bash
module avail spades
module load spades/4.0.0
# Single sample, paired-end
metaspades.py \
    -1 /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/trimming_results/ABF4_143_1_paired.fastq.gz \
    -2 /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/trimming_results/ABF4_143_2_paired.fastq.gz \
    -o metaspades_output \
    -t 32 \
    -m 200
# Options explained:
# -1/-2    : Paired-end input files
# -o       : Output directory
# -t       : Number of threads
# -m       : Memory limit in GB
```

The raw data is small and metaspades will take ~40 minutes with 200GB memory
If you are using big and many data Megahit is a good alternative.

#### Many samples

Use metaspades_batch.slurm from /scripts

#### Understanding metaSPAdes Output

metaspades_output/
├── assembly_graph.fastg # Assembly graph
├── assembly_graph_with_scaffolds.gfa # Scaffold graph
├── before_rr.fasta # Before repeat resolution
├── contigs.fasta # Final contigs
├── scaffolds.fasta # Final scaffolds
├── contigs.paths # Contig paths
├── scaffolds.paths # Scaffold paths
├── K21/ # K-mer 21 assembly
├── K33/ # K-mer 33 assembly
├── ...
├── params.txt # Parameters used
├── spades.log # Assembly log
└── warnings.log # Warnings

**contigs.fasta: Use for binning and annotation**

**MEGAHIT Assembly**
Basic usage

```bash
# Single sample
megahit \
    -1 clean_R1.fastq.gz \
    -2 clean_R2.fastq.gz \
    -o megahit_output \
    -t 32 \
    -m 0.9

# Options explained:
# -m 0.9   : Use 90% of available memory
# -t       : Number of threads
```

Output

megahit_output/
├── final.contigs.fa # Final assembly
├── intermediate_contigs/ # Intermediate k-mer assemblies
├── log # Assembly log
└── options.json # Parameters used

---

### Day2

#### Assembly Quality Assessment

MetaQUAST: The Standard for Assembly Evaluation
MetaQUAST (Quality Assessment Tool for Metagenome Assemblies) provides comprehensive quality metrics.

Basic usage

# Single assembly

```bash
module avail quast
module load quast/5.0.2
metaquast.py \
  /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/metaspades_output/contigs.fasta \
  -o metaquast_output \
  -t 32 \
  --max-ref-number 0
```

**Undersatnding metaquast output**
metaquast_output/
├── report.html # Interactive HTML report
├── report.pdf # PDF report
├── report.txt # Text summary
├── report.tsv # Tab-separated values
├── contigs_reports/ # Per-contig statistics
├── basic_stats/ # Basic statistics
└── icarus.html # Contig browser

If you have samples like below:

```bash
/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metaspades_assemblies/
   ├── SAMPLE1/contigs.fasta
   ├── SAMPLE2/contigs.fasta
   ├── SAMPLE3/contigs.fasta
```

Run metaquast_batch.slurm from /scripts
If you are interested read more at :https://jojyjohn28.github.io/blog/metagenome-analysis-day2-assembly/

#### Genome Binning - Recovering Individual Genomes (MAGs)\_ will continue next class.

Genome binning groups contigs that likely originated from the same organism based on:

Modern Approach: MetaWRAP can run all three binners (MetaBAT2, MaxBin2, CONCOCT) in a single command!

Why use multiple binners?

    Each algorithm has different strengths
    Combining results improves MAG quality
    Captures more of the community diversity
    MetaWRAP automatically handles coverage calculation

**for creating micromamba bubble of metawrap please see metawrap_micromaba.md in this repo**

**For Owner**

```bash
module purge
module load anaconda3/2023.09-0
ls -lh /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools/bin/ #you should see micromamba
MM=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools/bin/micromamba
$MM --version
#to run binning _we are not activation the env, instead we are calling it using micromamba run
BASE=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools
MM=$BASE/bin/micromamba
ENV=$BASE/conda_envs/metawrap_py3
MW=$BASE/src/metaWRAP/bin/metawrap
$MM run -p $ENV $MW --help
#this will print metawrap help
BASE=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools

cat > $BASE/run_metawrap.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools
MM=$BASE/bin/micromamba
ENV=$BASE/conda_envs/metawrap_py3
MW=$BASE/src/metaWRAP/bin/metawrap

exec "$MM" run -p "$ENV" "$MW" "$@"
EOF

chmod +x $BASE/run_metawrap.sh
$BASE/run_metawrap.sh --help


export PATH=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools/bin:$PATH
source ~/.bashrc
micromamba --version
```

**student version**

```bash
module purge
module load anaconda3/2023.09-0
/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools/run_metawrap.sh --help
TOOLS=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools
$TOOLS/run_metawrap.sh --help

```

#### gunzip the files for metawrap

```bash
gunzip -k /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/trimming_results/for_binning/ABF4-143_1.fastq.gz
gunzip -k /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/trimming_results/for_binning/ABF4-143_2.fastq.gz
```

##Binning

```bash
/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools/run_metawrap.sh binning \
  -o /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/INITIAL_BINNING-2 \
  -t 32 \
  -m 200 \
  -a /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/metaspades_output/contigs.fasta \
  --metabat2 \
  --maxbin2 \
  /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/trimming_results/for_binning/ABF4-143_1.fastq \
  /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/raw_data/trimming_results/for_binning/ABF4-143_2.fastq
```

#### Bin Refinement

Jojy #if face any erors

```bash
BASE=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools
PY=$BASE/conda_envs/metawrap_py3/bin/python
SCRIPT=$BASE/src/metaWRAP/bin/metawrap-scripts/binning_refiner.py

# 1) Disable history expansion (prevents ! problems)
set +H

# 2) Rewrite the first line safely
tmp=$(mktemp)
printf '#!%s\n' "$PY" > "$tmp"
tail -n +2 "$SCRIPT" >> "$tmp"
mv "$tmp" "$SCRIPT"
chmod +x "$SCRIPT"

# 3) Confirm
head -3 "$SCRIPT"
micromamba run -p $BASE/conda_envs/metawrap_py3 \
  python $BASE/src/metaWRAP/bin/metawrap-scripts/binning_refiner.py -h | head #testing
```

**students can Run**

```bash
cd /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/INITIAL_BINNING
module load checkm2/1.0.1
export CHECKM_DATA_PATH=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/MY_CHECKM_FOLDER
/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools/run_metawrap.sh bin_refinement \
  -o /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/BIN_REFINEMENT \
  -t 32 \
  -m 200 \
  -A /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/INITIAL_BINNING/metabat2_bins \
  -B /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/INITIAL_BINNING/maxbin2_bins \
  -c 50 -x 10
```

**The output**
Finished parsing hits for 4 of 4 (100.00%) bins.

---

## Bin Id Marker lineage # genomes # markers # marker sets 0 1 2 3 4 5+ Completeness Contamination Strain heterogeneity

bin.2 c**Gammaproteobacteria (UID4444) 263 507 232 2 504 1 0 0 0 99.14 0.43 0.00  
 bin.4 f**Rhodobacteraceae (UID3360) 56 582 313 4 576 2 0 0 0 99.09 0.27 50.00  
 bin.1 f**Rhodobacteraceae (UID3360) 56 582 313 7 573 2 0 0 0 99.02 0.27 50.00  
 bin.3 c**Gammaproteobacteria (UID4444) 263 507 232 7 499 1 0 0 0 97.84 0.43 0.00

---

#### Bin Quality Assessment

Modern metawrap allows this to couple with bin refinement, so we have alredy done this.

```bash
# Run CheckM on refined bins
checkm lineage_wf \
    -t 16 \
    -x fa \
    BIN_REFINEMENT/metawrap_50_10_bins/ \
    checkm_output/
```

#### Genome Dereplication

Dereplication identifies and removes redundant genomes based on sequence similarity.

```bash
module avail drep
module load drep/3.5.0
export CHECKM_DATA_PATH=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/MY_CHECKM_FOLDER

# Strain-level dereplication (99% ANI)
dRep dereplicate \
/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/drep/ \
-g /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/BIN_REFINEMENT/metawrap_50_10_bins/*.fa
```

**Understanding dRep Output**
dereplicated_genomes/
├── data/
│ ├── Clustering_files/
│ │ ├── Mdb.csv # MASH distances
│ │ └── Ndb.csv # ANI distances
│ ├── checkM/
│ │ └── checkM_outfile.tsv # Quality scores
│ └── MASH_files/
├── data_tables/
│ ├── Cdb.csv # Cluster information
│ ├── Sdb.csv # Score information
│ ├── Wdb.csv # Winner information (selected reps)
│ └── Widb.csv # Winner information with details
├── dereplicated_genomes/ # Final dereplicated MAGs
│ ├── genome1.fa
│ ├── genome2.fa
│ └── ...
└── figures/
├── Clustering_dendrogram.pdf
├── Primary_clustering_dendrogram.pdf
├── Secondary_clustering_dendrograms.pdf
└── Winning_genomes.pdf

#### Taxonomy

GTDB (Genome Taxonomy Database) is the modern, standardized bacterial taxonomy system.
It does

1. Gene Calling
2. Aligh
3. Classification
4. denovo classification

```bash
conda activate /project/bcampb7/camplab/Jojy/MTM2_RoL/gtdbtk_may24

#gene calling(identify)
gtdbtk identify --genome_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/drep/dereplicated_genomes --out_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk --extension fa --cpus 32

#Allighn genomespr
gtdbtk align --identify_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk/identify --out_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk/align --cpus 32

#Classyfy the genome
gtdbtk classify --genome_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/drep/dereplicated_genomes  --align_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk/align  --out_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk/classify -x fa --cpus 32 --mash_db /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk

#Denovo_workflow
gtdbtk de_novo_wf --genome_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/drep/dereplicated_genomes  --out_dir /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk/de_novo --extension fa --bacteria  --cpus 32 --outgroup_taxon p__Chloroflexota --skip_gtdb_refs --custom_taxonomy_file path/custom_taxonomy_file.tsv
# select a outgroup taxa, which is not present in your samples, --skip_gtdb_refs will skip all references files from the tree, if you want to keep them, remove this; custom taxonomy file will be generated in last step (classify) edit the file accordingly.

#convert to itol
gtdbtk convert_to_itol --input_tree  /project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/Gtdbtk/de_novo/gtdbtk.bac120.decorated.tree --output_tree /scratch/jojyj/UK/Genomes/gtdbtk/de_novo/OUTPUT_TREE (this is optional, if you want to anotate the tree on iToL use this or skip)

```

Due to need of high mem computational resources, we are going to use the alredy annotated tree provided in the folder with toy annotation data in excel.

##### Genome annotations

**1.Basic_Prokka**

```bash
module avail prokka
module load prokka/1.14.5

mkdir -p prokka_out

for g in *.fa 2>/dev/null; do
  [ -e "$g" ] || continue
  sample=$(basename "$g")
  sample=${sample%.*}

  prokka \
    --outdir "prokka_out/${sample}" \
    --prefix "${sample}" \
    --cpus 8 \
    --kingdom Bacteria \
    "$g"
done
```

**output**
Inside each prokka_out/<genome>/ you’ll see:

\*.gff (main annotation file)

\*.gbk (GenBank)

\*.faa (proteins)

\*.ffn (genes nucleotide)

\*.fna (contigs copy)

_.tbl, _.txt (summary)

**2. DRAM annotation**
DRAM (Distilled and Refined Annotation of Metabolism) specializes in metabolic reconstruction.

```bash
module avail dram
module load dram/1.4.6
source /project/cugbf/software/gbf/DRAM/1.4.6.sh

# Annotate MAGs
DRAM.py annotate \
    -i '/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/metawrap/drep/dereplicated_genomes/*.fa' \
    -o dram_output

# Distill annotations into metabolic summary
DRAM.py distill \
    -i dram_output/annotations.tsv \
    -o dram_distillate \
    --trna_path dram_output/trnas.tsv \
    --rrna_path dram_output/rrnas.tsv
```

#### DRAM outputs:

dram_output/
├── annotations.tsv # All annotations
├── genes.faa # Predicted proteins
├── genes.fna # Predicted genes
├── genes.gff # GFF format
├── trnas.tsv # tRNA predictions
└── rrnas.tsv # rRNA predictions

dram_distillate/
├── metabolism_summary.xlsx # Metabolic capabilities
├── product.html # Interactive visualization
└── genome_stats.tsv # Quality statistics

## End of the class training

## prepared by Jojy John
