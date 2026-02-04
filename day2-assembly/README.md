# Day 2: Genome Assembly

Reconstruct genomes from short reads using de novo assembly with metaSPAdes, MEGAHIT, and quality assessment with MetaQUAST.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Learning Objectives](#learning-objectives)
- [Workflow Summary](#workflow-summary)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
- [Detailed Workflow](#detailed-workflow)
- [Assembler Comparison](#assembler-comparison)
- [Results & Interpretation](#results--interpretation)
- [Troubleshooting](#troubleshooting)
- [Citation](#citation)

---

## 🎯 Overview

Day 2 focuses on **de novo metagenome assembly** - reconstructing longer DNA sequences (contigs and scaffolds) from millions of short sequencing reads. This is a computationally intensive but essential step for downstream genome binning and functional analysis.

### Why Assembly Matters

Assembly enables you to:

- 🧬 Recover **complete or near-complete genomes** (MAGs)
- 📊 Identify **novel genes** and biosynthetic clusters
- 🔬 Understand **genomic context** and synteny
- 📈 Improve **taxonomic resolution** beyond marker genes
- 🎯 Enable **functional annotation** at the genome level

### What You'll Achieve

By the end of Day 2, you'll have:

- ✅ Assembled metagenomic contigs using multiple strategies
- ✅ Assessed assembly quality with comprehensive metrics
- ✅ Calculated contig coverage (essential for Day 3)
- ✅ Compared different assemblers and parameters
- ✅ Prepared data for genome binning

---

## 🎓 Learning Objectives

After completing Day 2, you will be able to:

1. **Assemble Metagenomes**
   - Use metaSPAdes for high-quality assemblies
   - Use MEGAHIT for memory-efficient assemblies
   - Handle long-read data with Flye
   - Choose appropriate assemblers for your system

2. **Assess Assembly Quality**
   - Calculate N50, L50, and related metrics
   - Use MetaQUAST for comprehensive evaluation
   - Interpret assembly statistics
   - Compare multiple assembly strategies

3. **Prepare for Binning**
   - Map reads back to contigs
   - Calculate contig coverage
   - Generate BAM files for downstream analysis
   - Understand contigs vs scaffolds

4. **Optimize Workflows**
   - Choose optimal k-mer ranges
   - Adjust parameters for your system
   - Work with limited computational resources
   - Use Python and R for analysis

---

## 🔄 Workflow Summary

```
Clean FASTQ Files (from Day 1)
    ↓
┌───────────────────────────────────┐
│  Assembly                         │
│  • metaSPAdes (high quality)      │
│  • MEGAHIT (fast, low memory)     │
│  • Flye (long reads)               │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│  Quality Assessment               │
│  • MetaQUAST                      │
│  • N50, total length, # contigs   │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│  Coverage Calculation             │
│  • Bowtie2 mapping                │
│  • SAMtools processing            │
│  • Depth calculation              │
└───────────────────────────────────┘
    ↓
Assembled Contigs + Coverage
(Ready for Day 3 Binning!)
```

---

## 🚀 Quick Start

### For Laptop Users (8-16GB RAM)

```bash
# 1. Navigate to directory
cd day2-assembly/

# 2. Activate conda environment
conda activate day2_assembly

# 3. Run laptop-optimized workflow
cd running-on-your-laptop/
bash laptop_01_assembly.sh           # 2-4 hours
bash laptop_02_quality_check.sh      # 15-30 min
bash laptop_03_calculate_coverage.sh # 1-2 hours

# 4. View results
firefox results/sample1_metaquast/report.html
```

**See [RUNNING_ON_LAPTOP.md](running-on-your-laptop/RUNNING_ON_LAPTOP.md) for complete tutorial**

### For HPC Users

```bash
# 1. Navigate to directory
cd day2-assembly/

# 2. Submit SLURM jobs
cd scripts/slurm/
sbatch 01_metaspades_assembly_slurm.sh    # or MEGAHIT
sbatch 03_metaquast_assessment_slurm.sh
sbatch 04_calculate_coverage_slurm.sh

# 3. Monitor progress
squeue -u $USER
tail -f logs/slurm/metaspades_*.out
```

---

## 📁 Directory Structure

```
day2-assembly/
├── README.md                           # This file
├── DATA.md                            # Dataset information
├── running-on-your-laptop/
│   ├── RUNNING_ON_LAPTOP.md          # Detailed laptop guide
│   ├── laptop_01_assembly.sh         # Assembly (MEGAHIT)
│   ├── laptop_02_quality_check.sh    # MetaQUAST
│   └── laptop_03_calculate_coverage.sh # Coverage calculation
├── scripts/
│   ├── 01_parse_metaquast.py         # Python: Parse MetaQUAST
│   ├── 02_assembly_statistics.py     # Python: Calculate stats
│   ├── 02_assembly_visualization.R   # R: Visualizations
│   └── slurm/
│       ├── 01_metaspades_assembly_slurm.sh
│       ├── 02_megahit_assembly_slurm.sh
│       ├── 03_metaquast_assessment_slurm.sh
│       ├── 04_calculate_coverage_slurm.sh
│       ├── 05_filter_assemblies_slurm.sh
│       └── 06_compare_assemblies_slurm.sh
└── data/
    └── (raw reads from Day 1)
```

---

## 📦 Prerequisites

### Software Requirements

**Core Tools:**

- metaSPAdes (v3.15.5+) - Optional, needs 64GB+ RAM
- MEGAHIT (v1.2.9+) - **Recommended for laptops**
- MetaQUAST (v5.2.0+)
- Bowtie2 (v2.4.0+)
- SAMtools (v1.15+)

**Optional Tools:**

- Flye (v2.9+) - For long-read assembly
- Python (v3.8+) - For analysis scripts
- R (v4.0+) - For visualizations

### Installation

#### Quick Install (Conda)

```bash
# Create environment
conda create -n day2_assembly python=3.9
conda activate day2_assembly

# Install core tools
conda install -c bioconda -c conda-forge \
    megahit \
    quast \
    bowtie2 \
    samtools \
    seqkit \
    biopython \
    pandas \
    matplotlib

# Optional: metaSPAdes (if you have RAM)
conda install -c bioconda spades

# Optional: For R visualizations
conda install -c conda-forge r-base r-ggplot2 r-dplyr r-tidyr
```

#### Verify Installation

```bash
megahit --version
metaquast.py --version
bowtie2 --version
samtools --version
```

---

## 📊 Detailed Workflow

### Step 1: Assembly (2-48 hours)

**Option A: MEGAHIT (Recommended for most users)**

```bash
# Fast, memory-efficient
megahit \
    -1 clean_R1.fastq.gz \
    -2 clean_R2.fastq.gz \
    -o megahit_output \
    -t 16 \
    --k-min 21 --k-max 141 --k-step 20 \
    --min-contig-len 500
```

**Time:** 2-8 hours  
**Memory:** 16-64 GB  
**Best for:** Desktop, workstation, large datasets

**Option B: metaSPAdes (Gold standard)**

```bash
# Highest quality, slow
metaspades.py \
    -1 clean_R1.fastq.gz \
    -2 clean_R2.fastq.gz \
    -o metaspades_output \
    -t 32 \
    -m 200 \
    -k 21,33,55,77,99,127
```

**Time:** 12-48 hours  
**Memory:** 64-256 GB  
**Best for:** HPC, final assemblies, publications

**Option C: Flye (Long reads)**

```bash
# For ONT/PacBio data
flye \
    --nano-raw ont_reads.fastq.gz \
    --out-dir flye_output \
    --threads 32 \
    --meta
```

**Time:** 4-16 hours  
**Memory:** 32-128 GB  
**Best for:** Long-read data (ONT, PacBio)

### Step 2: Quality Assessment (15min - 2 hours)

```bash
# Run MetaQUAST
metaquast.py \
    contigs.fasta \
    -o metaquast_output \
    -t 16 \
    --min-contig 500

# View HTML report
firefox metaquast_output/report.html
```

**Key Metrics to Check:**

- **N50**: Higher is better (>5,000 bp is good)
- **Total contigs**: Fewer is often better
- **Total length**: Depends on community
- **Largest contig**: >50kb is excellent

### Step 3: Coverage Calculation (1-6 hours)

**Essential for Day 3 binning!**

```bash
# Build index
bowtie2-build contigs.fasta contigs_index

# Map reads
bowtie2 -x contigs_index \
    -1 R1.fastq.gz -2 R2.fastq.gz \
    -p 16 | samtools sort -o contigs.bam -

# Index BAM
samtools index contigs.bam

# Calculate depth
samtools depth contigs.bam > depth.txt
```

**Files needed for Day 3:**

- ✅ contigs.fasta
- ✅ contigs.bam
- ✅ contigs.bam.bai
- ✅ depth.txt

---

## 🔬 Assembler Comparison

### Quick Decision Guide

**Choose MEGAHIT if:**

- ✅ RAM ≤ 32 GB (laptop/desktop)
- ✅ Need fast results (2-8 hours)
- ✅ Dataset is large (>50M read pairs)
- ✅ First-time user or testing

**Choose metaSPAdes if:**

- ✅ RAM ≥ 128 GB (HPC)
- ✅ Need highest quality
- ✅ Time is not critical (12-48 hours)
- ✅ Publication-quality assembly

**Choose Flye if:**

- ✅ Have ONT or PacBio long reads
- ✅ Want to resolve repeats
- ✅ Need complete genomes

### Performance Comparison

| Metric          | metaSPAdes      | MEGAHIT      | Flye  |
| --------------- | --------------- | ------------ | ----- |
| **N50**         | ★★★★★ (Highest) | ★★★★☆        | ★★★★★ |
| **Speed**       | ★★☆☆☆ (Slow)    | ★★★★★ (Fast) | ★★★★☆ |
| **Memory**      | ★★☆☆☆ (High)    | ★★★★★ (Low)  | ★★★☆☆ |
| **Quality**     | ★★★★★           | ★★★★☆        | ★★★★★ |
| **Ease of Use** | ★★★★☆           | ★★★★★        | ★★★☆☆ |

---

## 📈 Results & Interpretation

### What Makes a Good Assembly?

**Excellent Assembly:**

- N50 > 20,000 bp
- Total contigs < 10,000
- Largest contig > 200kb
- > 85% reads map back

**Good Assembly:**

- N50 > 5,000 bp
- Total contigs < 50,000
- Largest contig > 50kb
- > 75% reads map back

**Acceptable Assembly:**

- N50 > 1,000 bp
- Total contigs < 100,000
- Largest contig > 10kb
- > 60% reads map back

### Red Flags

⚠️ **N50 < 500 bp**: Very poor, check:

- Sequencing depth (need >5-10M pairs)
- Read quality (Day 1 QC)
- Community complexity

⚠️ **Mapping rate < 50%**: Something wrong, check:

- Used correct reads?
- Assembly actually succeeded?
- File paths correct?

⚠️ **Too many short contigs**: Consider:

- Deeper sequencing
- Better QC
- Different assembler

---

## 🔧 Troubleshooting

### Problem: Out of Memory (metaSPAdes)

**Solutions:**

1. Use MEGAHIT instead
2. Subsample reads (1-2M pairs for testing)
3. Reduce k-mer maximum (`-k 21,33,55,77`)
4. Request more RAM on HPC

### Problem: Assembly Too Slow

**Solutions:**

1. Use MEGAHIT (10x faster)
2. Reduce k-mer maximum
3. Subsample for testing
4. Check if actually running (`top`/`htop`)

### Problem: Low N50

**Possible Causes:**

- Low sequencing depth
- High community complexity
- Poor read quality
- Wrong parameters

**Solutions:**

- Verify Day 1 QC passed
- Try different assemblers
- Optimize k-mer range
- Consider deeper sequencing

### Problem: Can't Calculate Coverage

**Solutions:**

- Check you have correct reads
- Verify assembly file exists
- Ensure enough disk space
- Check file permissions

---

## 💡 Best Practices

### Before Assembly

- ✅ Complete Day 1 QC successfully
- ✅ Remove host contamination
- ✅ Check sequencing depth (>5M pairs minimum)
- ✅ Verify adequate disk space (3x raw data)
- ✅ Plan computational resources

### During Assembly

- ✅ Use `screen` or `tmux` for long jobs
- ✅ Monitor log files regularly
- ✅ Check disk space periodically
- ✅ Save parameters for reproducibility

### After Assembly

- ✅ Run MetaQUAST immediately
- ✅ Calculate coverage for binning
- ✅ Compare multiple assemblies if possible
- ✅ Document which assembly to use
- ✅ Backup important files

---

## 📚 Additional Resources

### Documentation

- [metaSPAdes Manual](http://cab.spbu.ru/software/meta-spades/)
- [MEGAHIT GitHub](https://github.com/voutcn/megahit)
- [MetaQUAST Documentation](http://quast.sourceforge.net/metaquast)
- [Flye Manual](https://github.com/fenderglass/Flye)

### Key Papers

- Nurk et al. (2017) - metaSPAdes: _Nature Methods_
- Li et al. (2015) - MEGAHIT: _Bioinformatics_
- Kolmogorov et al. (2019) - Flye: _Nature Biotechnology_
- Mikheenko et al. (2016) - MetaQUAST: _Bioinformatics_

### Video Tutorials

- Coming soon!

---

## 📝 Citation

If you use this tutorial, please cite:

```
John, J. (2026). Metagenome Analysis Series - Day 2: Genome Assembly.
GitHub repository.
https://github.com/jojyjohn28/metagenome-analysis-series
```

**Please also cite the tools you use:**

- metaSPAdes: Nurk et al. (2017) Nature Methods
- MEGAHIT: Li et al. (2015) Bioinformatics
- MetaQUAST: Mikheenko et al. (2016) Bioinformatics
- Bowtie2: Langmead & Salzberg (2012) Nature Methods

---

## ✅ Success Checklist

Before moving to Day 3:

- [ ] Assembly completed successfully
- [ ] MetaQUAST report generated (N50 > 1kb)
- [ ] Coverage calculated (>70% mapping)
- [ ] BAM file created and indexed
- [ ] Contigs filtered (≥500bp)
- [ ] Files organized in output directory

---

## ➡️ Next Steps

**Congratulations!** You've successfully assembled your metagenome!

**Ready for Day 3?**

[Proceed to Day 3: Genome Binning (MAG Recovery) →](../day3-binning/)

Learn to separate individual genomes from your metagenomic assembly!

---

## 💬 Feedback & Support

- **Found an issue?** [Open an issue](https://github.com/jojyjohn28/metagenome-analysis-series/issues)
- **Have a question?** Check existing issues or create new one
- **Want to contribute?** Pull requests welcome!

---

<div align="center">

**[⬆ Back to Main README](../README.md)** | **[← Day 1](../day1-qc-read-based/)** | **[Day 3 →](../day3-binning/)**

**[View Laptop Tutorial](running-on-your-laptop/RUNNING_ON_LAPTOP.md)** | **[View All Scripts](scripts/)**

Made with ❤️ for the metagenomics community

</div>
