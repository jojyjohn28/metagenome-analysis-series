# Running Metagenome Analysis on Your Laptop/Desktop

This guide provides practical instructions and optimized scripts for running Day 1 metagenome analysis on personal computers with limited resources.

## 💻 System Requirements

### Minimum Specifications
- **CPU:** 4 cores (Intel i5/i7 or AMD Ryzen 5/7)
- **RAM:** 8 GB (16 GB recommended)
- **Storage:** 100 GB free space
- **OS:** Linux, macOS, or Windows (WSL2)

### Recommended Specifications
- **CPU:** 8+ cores
- **RAM:** 32 GB
- **Storage:** 500 GB SSD
- **OS:** Linux (Ubuntu 20.04/22.04)

## 📦 Installation

### Quick Setup (Using Conda)

```bash
# Install Miniconda if not already installed
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Create and activate environment
conda create -n metagenomics python=3.9
conda activate metagenomics

# Install essential tools
conda install -c bioconda -c conda-forge \
    fastqc \
    multiqc \
    trimmomatic \
    bbmap \
    kraken2 \
    bracken

# For taxonomic profiling (pick 1-2 based on your needs)
conda install -c bioconda kaiju     # Protein-based
conda install -c bioconda metaphlan # Marker gene-based
```

## 🎯 Strategy for Limited Resources

### 1. Subsample Your Data

Work with smaller datasets for learning/testing:

```bash
# Install seqtk for subsampling
conda install -c bioconda seqtk

# Subsample to 1 million read pairs (~300 MB files)
seqtk sample -s100 raw_R1.fastq.gz 1000000 | gzip > subset_R1.fastq.gz
seqtk sample -s100 raw_R2.fastq.gz 1000000 | gzip > subset_R2.fastq.gz
```

### 2. Use Lighter Tools

- **Instead of Kaiju with nr (70GB):** Use RefSeq (30GB) or skip
- **Instead of Kraken2 Standard (50GB):** Use MiniKraken (8GB)
- **For QC:** FastQC and Trimmomatic work fine on any system

### 3. Process Sequentially

Avoid parallel processing to save memory:
```bash
# Process one sample at a time
for sample in sample1 sample2; do
    # Run analysis
done
```

## 🚀 Optimized Workflow for Laptops

### Step 1: Quality Control & Trimming

This step is lightweight and works on any laptop.

**Script:** `laptop_01_qc_trim.sh`

```bash
#!/bin/bash
#
# Lightweight QC and trimming for laptop/desktop
# Works on systems with 8GB+ RAM

set -e  # Exit on error

# Configuration
INPUT_DIR="raw_data"
OUTPUT_DIR="results"
THREADS=4  # Adjust based on your CPU

# Create directories
mkdir -p ${OUTPUT_DIR}/fastqc_raw
mkdir -p ${OUTPUT_DIR}/trimmed
mkdir -p ${OUTPUT_DIR}/fastqc_trimmed
mkdir -p logs

echo "=== Starting Laptop-Friendly QC Pipeline ==="
echo "Using ${THREADS} CPU threads"
echo "Input: ${INPUT_DIR}"
echo "Output: ${OUTPUT_DIR}"

# Step 1: Initial QC
echo ""
echo "[1/4] Running FastQC on raw reads..."
fastqc -o ${OUTPUT_DIR}/fastqc_raw \
       -t ${THREADS} \
       ${INPUT_DIR}/*.fastq.gz

# Step 2: Trimming
echo ""
echo "[2/4] Running Trimmomatic..."
for R1 in ${INPUT_DIR}/*_R1.fastq.gz; do
    sample=$(basename ${R1} _R1.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2.fastq.gz"
    
    echo "  Processing ${sample}..."
    
    trimmomatic PE \
        -threads ${THREADS} \
        -phred33 \
        ${R1} ${R2} \
        ${OUTPUT_DIR}/trimmed/${sample}_R1_paired.fastq.gz \
        ${OUTPUT_DIR}/trimmed/${sample}_R1_unpaired.fastq.gz \
        ${OUTPUT_DIR}/trimmed/${sample}_R2_paired.fastq.gz \
        ${OUTPUT_DIR}/trimmed/${sample}_R2_unpaired.fastq.gz \
        ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:2:True \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 \
        2> logs/${sample}_trimmomatic.log
done

# Step 3: Post-trimming QC
echo ""
echo "[3/4] Running FastQC on trimmed reads..."
fastqc -o ${OUTPUT_DIR}/fastqc_trimmed \
       -t ${THREADS} \
       ${OUTPUT_DIR}/trimmed/*_paired.fastq.gz

# Step 4: Generate reports
echo ""
echo "[4/4] Generating MultiQC reports..."
multiqc ${OUTPUT_DIR}/fastqc_raw -o ${OUTPUT_DIR} -n raw_multiqc_report
multiqc ${OUTPUT_DIR}/fastqc_trimmed -o ${OUTPUT_DIR} -n trimmed_multiqc_report

echo ""
echo "=== QC and Trimming Complete! ==="
echo "Results in: ${OUTPUT_DIR}/"
echo "View reports: ${OUTPUT_DIR}/*_multiqc_report.html"
```

### Step 2: Lightweight Taxonomic Profiling

Use MetaPhlAn - it's memory-efficient and publication-ready.

**Script:** `laptop_02_taxonomy.sh`

```bash
#!/bin/bash
#
# Lightweight taxonomic profiling with MetaPhlAn
# Memory requirement: ~8-16 GB

set -e

# Configuration
INPUT_DIR="results/trimmed"
OUTPUT_DIR="results/taxonomy"
THREADS=4

# Create directories
mkdir -p ${OUTPUT_DIR}/metaphlan
mkdir -p ${OUTPUT_DIR}/metaphlan/bowtie2

echo "=== Starting MetaPhlAn Profiling ==="
echo "Using ${THREADS} CPU threads"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_paired.fastq.gz; do
    sample=$(basename ${R1} _R1_paired.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_paired.fastq.gz"
    
    echo ""
    echo "Profiling ${sample}..."
    
    metaphlan \
        ${R1},${R2} \
        --input_type fastq \
        --nproc ${THREADS} \
        --bowtie2out ${OUTPUT_DIR}/metaphlan/bowtie2/${sample}.bt2.bz2 \
        --output_file ${OUTPUT_DIR}/metaphlan/${sample}_profile.txt
    
    echo "  Complete: ${sample}"
done

# Merge profiles
echo ""
echo "Merging all sample profiles..."
merge_metaphlan_tables.py \
    ${OUTPUT_DIR}/metaphlan/*_profile.txt \
    > ${OUTPUT_DIR}/metaphlan/merged_abundance_table.txt

# Extract species-level
grep -E "s__|clade_name" ${OUTPUT_DIR}/metaphlan/merged_abundance_table.txt \
    | grep -v "t__" \
    > ${OUTPUT_DIR}/metaphlan/merged_species.txt

echo ""
echo "=== Profiling Complete! ==="
echo "Results: ${OUTPUT_DIR}/metaphlan/"
echo "Merged table: ${OUTPUT_DIR}/metaphlan/merged_abundance_table.txt"
```

### Step 3: Simple Visualization

**Script:** `laptop_03_visualize.R`

```r
#!/usr/bin/env Rscript
#
# Simple visualization for laptop analysis
# Creates barplot of taxonomic composition

# Install packages if needed
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("dplyr")) install.packages("dplyr")
if (!require("tidyr")) install.packages("tidyr")

library(ggplot2)
library(dplyr)
library(tidyr)

# Read MetaPhlAn output
cat("Reading taxonomic data...\n")
data <- read.table("results/taxonomy/metaphlan/merged_species.txt",
                   header=TRUE, sep="\t", row.names=1, 
                   comment.char="", check.names=FALSE)

# Clean species names (remove taxonomic prefixes)
rownames(data) <- gsub(".*s__", "", rownames(data))

# Get top 15 species
top_species <- names(sort(rowSums(data), decreasing=TRUE)[1:15])

# Prepare data for plotting
plot_data <- data[top_species,] %>%
  as.data.frame() %>%
  tibble::rownames_to_column("Species") %>%
  pivot_longer(-Species, names_to="Sample", values_to="Abundance")

# Create stacked barplot
cat("Creating visualization...\n")
p <- ggplot(plot_data, aes(x=Sample, y=Abundance, fill=Species)) +
  geom_bar(stat="identity", position="stack") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle=45, hjust=1),
        legend.position = "right") +
  labs(title="Taxonomic Composition (Top 15 Species)",
       x="Sample",
       y="Relative Abundance (%)",
       fill="Species") +
  scale_fill_brewer(palette="Set3")

# Save plot
ggsave("results/taxonomy_barplot.pdf", plot=p, width=10, height=6)
ggsave("results/taxonomy_barplot.png", plot=p, width=10, height=6, dpi=300)

cat("Done! Plots saved in results/\n")
```

## 📋 Complete Laptop Workflow

### Quick Start (Copy-Paste)

```bash
# 1. Setup environment
conda activate metagenomics

# 2. Prepare directory structure
mkdir -p raw_data results logs

# 3. Copy your data to raw_data/
# Files should be named: sample1_R1.fastq.gz, sample1_R2.fastq.gz, etc.

# 4. Run QC and trimming (30-60 minutes)
bash laptop_01_qc_trim.sh

# 5. Run taxonomic profiling (1-3 hours depending on data size)
bash laptop_02_taxonomy.sh

# 6. Visualize results (1-2 minutes)
Rscript laptop_03_visualize.R

# 7. View results
firefox results/raw_multiqc_report.html
firefox results/trimmed_multiqc_report.html
firefox results/taxonomy_barplot.pdf
```

## 💡 Tips for Success

### Memory Management

```bash
# Monitor memory usage
htop  # or 'top' on macOS

# If running out of memory:
# - Process one sample at a time
# - Reduce thread count (THREADS=2)
# - Close other applications
# - Use swap space
```

### Speed Optimization

```bash
# Use all available cores (but leave 1-2 for system)
THREADS=$(nproc)
THREADS=$((THREADS - 2))

# On macOS
THREADS=$(sysctl -n hw.ncpu)
THREADS=$((THREADS - 2))
```

### Storage Management

```bash
# Check disk space regularly
df -h

# Clean up intermediate files after completion
rm -rf results/trimmed/*_unpaired.fastq.gz
rm -rf results/fastqc_raw/*_fastqc.zip
```

## 🎓 Learning Path

### Week 1: Basic QC
- Run FastQC on tutorial data
- Understand quality metrics
- Practice trimming with different parameters

### Week 2: Small Dataset
- Subsample real data (1M reads)
- Complete full pipeline
- Interpret results

### Week 3: Full Dataset
- Process complete sample
- Or move to cloud/HPC for larger datasets

## 🔧 Troubleshooting

### Problem: Out of Memory

**Solution 1:** Reduce thread count
```bash
THREADS=2  # Use fewer threads
```

**Solution 2:** Subsample data more aggressively
```bash
seqtk sample -s100 input.fastq.gz 500000 > subset.fastq  # 500K reads
```

**Solution 3:** Process one sample at a time
```bash
# Don't run multiple tools simultaneously
# Wait for each step to complete before starting next
```

### Problem: Slow Performance

**Solution:** Use faster tools
```bash
# Use BBDuk instead of Trimmomatic (faster)
# Use MetaPhlAn instead of Kaiju (lighter)
# Skip host removal if not human/mouse samples
```

### Problem: Database Downloads Failing

**Solution:** Use pre-built databases
```bash
# MetaPhlAn databases are downloaded automatically on first run
# For Kraken2, use smaller pre-built databases:
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz
tar -xzf minikraken2_v2_8GB_201904.tgz
```

## 📊 Expected Runtime (8GB RAM, 4 cores)

| Step | 1M Read Pairs | 5M Read Pairs | 10M Read Pairs |
|------|---------------|---------------|----------------|
| FastQC | 5 min | 15 min | 30 min |
| Trimmomatic | 10 min | 30 min | 1 hour |
| MetaPhlAn | 30 min | 2 hours | 4 hours |
| Visualization | 1 min | 2 min | 3 min |
| **Total** | **~45 min** | **~3 hours** | **~5.5 hours** |

## 🌟 Alternative: Cloud Options

If your laptop struggles, consider:

### Google Colab (Free)
- 12GB RAM, 2 CPU cores
- Upload small datasets
- Run basic QC and profiling

### AWS EC2 (Pay-as-you-go)
- t3.xlarge: 4 cores, 16GB RAM (~$0.17/hour)
- t3.2xlarge: 8 cores, 32GB RAM (~$0.33/hour)
- Run for a few hours when needed

### Galaxy (Free)
- Web-based, no installation
- Pre-configured tools
- Covered in Day 8

## 📚 Additional Resources

- [FastQC Documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [MetaPhlAn Tutorial](https://github.com/biobakery/MetaPhlAn/wiki)
- [Conda Cheat Sheet](https://docs.conda.io/projects/conda/en/latest/user-guide/cheatsheet.html)

## ✅ Success Checklist

- [ ] Conda environment created and activated
- [ ] Sample data in `raw_data/` directory
- [ ] FastQC report shows good quality (>Q28)
- [ ] >80% reads survive trimming
- [ ] Taxonomic profile generated successfully
- [ ] Visualization created without errors

---

**Remember:** Start small, learn the workflow, then scale up! 🚀

For full HPC workflow, see the main `scripts/` directory.
