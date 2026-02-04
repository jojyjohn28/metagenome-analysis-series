# Dataset Information for Day 1 Tutorial

This document provides information about datasets you can use to practice the Day 1 metagenome analysis workflow.

## 📊 Tutorial Datasets

### Public Metagenome Project (For Real Analysis)

**Project:** PRJNA432171  
**Type:** Metagenomes, metatranscriptomes, and MAGs  
**Source:** NCBI BioProject  
**Best for:** Real research, publication-quality analysis

The metagenomes, metatranscriptomes, and MAGs are available in NCBI under the umbrella project **PRJNA432171**.

#### Downloading from NCBI

##### Method 1: Using SRA Toolkit (Recommended)

```bash
# Install SRA Toolkit
conda install -c bioconda sra-tools

# Configure SRA Toolkit (first time only)
vdb-config --interactive
# Enable "Remote Access" and set cache location

# List all runs in the project
esearch -db sra -query "PRJNA432171" | efetch -format runinfo > runinfo.csv

# View available samples
column -t -s, runinfo.csv | less -S

# Download specific samples (replace SRR numbers with actual IDs)
prefetch SRR1234567 SRR1234568 SRR1234569

# Convert to FASTQ format
fastq-dump --split-files --gzip SRR1234567
fastq-dump --split-files --gzip SRR1234568
fastq-dump --split-files --gzip SRR1234569

# Or use faster fasterq-dump
fasterq-dump --split-files SRR1234567
gzip SRR1234567_*.fastq
```

##### Method 2: Using NCBI Website

1. Visit: https://www.ncbi.nlm.nih.gov/bioproject/PRJNA432171
2. Click "SRA Experiments" in the right panel
3. Select samples of interest
4. Click "Send to" → "Run Selector"
5. Download metadata and accession list
6. Use SRA Toolkit to download selected samples

##### Method 3: Batch Download Script

```bash
#!/bin/bash
#
# Script: download_prjna432171.sh
# Download samples from PRJNA432171

# Create output directory
mkdir -p raw_data
cd raw_data

# List of SRA accessions (replace with actual accessions from the project)
ACCESSIONS=(
    "SRR1234567"
    "SRR1234568"
    "SRR1234569"
    # Add more accessions here
)

# Download and convert each sample
for SRR in "${ACCESSIONS[@]}"; do
    echo "Downloading ${SRR}..."

    # Download
    prefetch ${SRR}

    # Convert to FASTQ (paired-end)
    fasterq-dump --split-files ${SRR}

    # Compress
    gzip ${SRR}_1.fastq ${SRR}_2.fastq

    # Rename for clarity (optional)
    mv ${SRR}_1.fastq.gz ${SRR}_R1.fastq.gz
    mv ${SRR}_2.fastq.gz ${SRR}_R2.fastq.gz

    # Clean up cache
    rm -rf ${SRR}

    echo "Completed ${SRR}"
done

echo "All downloads complete!"
```

#### Finding Sample Information

```bash
# Get sample metadata
esearch -db sra -query "PRJNA432171" | \
  efetch -format runinfo | \
  cut -d',' -f1,12,30 | \
  column -t -s','

# Fields: Run_ID, Sample_Name, BioSample

# Get more details
esearch -db sra -query "SRR1234567" | \
  efetch -format xml | \
  xtract -pattern EXPERIMENT_PACKAGE \
    -element EXPERIMENT@accession \
    -element SAMPLE@accession \
    -element TITLE
```

### Option 3: Create Your Own Subsampled Dataset

If you want to practice with full datasets but have limited resources:

```bash
#!/bin/bash
#
# Script: subsample_data.sh
# Create smaller test datasets from large files

# Install seqtk
conda install -c bioconda seqtk

# Subsample to 1 million reads (adjust as needed)
READS=1000000

for R1 in large_dataset/*_R1.fastq.gz; do
    sample=$(basename ${R1} _R1.fastq.gz)
    R2="${sample}_R2.fastq.gz"

    echo "Subsampling ${sample}..."

    seqtk sample -s100 large_dataset/${sample}_R1.fastq.gz ${READS} | \
        gzip > raw_data/${sample}_R1.fastq.gz

    seqtk sample -s100 large_dataset/${sample}_R2.fastq.gz ${READS} | \
        gzip > raw_data/${sample}_R2.fastq.gz

    echo "Created: raw_data/${sample}_R[1-2].fastq.gz"
done
```

## 📋 Dataset Specifications

### Expected File Format

Your raw data should follow this naming convention:

```
sample1_R1.fastq.gz  # Forward reads
sample1_R2.fastq.gz  # Reverse reads
sample2_R1.fastq.gz
sample2_R2.fastq.gz
...
```

### File Structure

```
project_directory/
├── raw_data/
│   ├── sample1_R1.fastq.gz
│   ├── sample1_R2.fastq.gz
│   ├── sample2_R1.fastq.gz
│   └── sample2_R2.fastq.gz
├── scripts/
│   └── (analysis scripts)
└── results/
    └── (will be created)
```

## 🔍 Quality Checks Before Analysis

### Check File Integrity

```bash
# Verify all files are gzipped and not corrupted
for file in raw_data/*.fastq.gz; do
    echo "Checking ${file}..."
    gunzip -t ${file} && echo "  ✓ OK" || echo "  ✗ CORRUPTED"
done
```

### Check File Sizes

```bash
# List file sizes
ls -lh raw_data/*.fastq.gz

# Typical sizes:
# Small dataset: 100-500 MB per file
# Medium dataset: 1-5 GB per file
# Large dataset: 5-20 GB per file
```

### Quick Read Count

```bash
# Count reads (divide by 4 for FASTQ format)
echo "Sample,Forward_Reads,Reverse_Reads"
for R1 in raw_data/*_R1.fastq.gz; do
    sample=$(basename ${R1} _R1.fastq.gz)
    R2="raw_data/${sample}_R2.fastq.gz"

    forward=$(zcat ${R1} | wc -l | awk '{print $1/4}')
    reverse=$(zcat ${R2} | wc -l | awk '{print $1/4}')

    echo "${sample},${forward},${reverse}"
done
```

### Verify Paired-End Matching

```bash
# Check that R1 and R2 have same number of reads
for R1 in raw_data/*_R1.fastq.gz; do
    sample=$(basename ${R1} _R1.fastq.gz)
    R2="raw_data/${sample}_R2.fastq.gz"

    reads_R1=$(zcat ${R1} | wc -l | awk '{print $1/4}')
    reads_R2=$(zcat ${R2} | wc -l | awk '{print $1/4}')

    if [ "$reads_R1" -eq "$reads_R2" ]; then
        echo "✓ ${sample}: ${reads_R1} paired reads"
    else
        echo "✗ ${sample}: MISMATCH! R1=${reads_R1}, R2=${reads_R2}"
    fi
done
```
