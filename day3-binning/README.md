# Day 3: Genome Binning

Recover individual genomes (MAGs) from metagenomic assemblies using modern binning approaches.

## 📋 Overview

This directory contains all scripts and documentation for Day 3 of the metagenome analysis series: **Genome Binning**. Learn to separate individual genomes from complex metagenomic assemblies using MetaWRAP, CoverM, and SingleM.

### What You'll Learn

✅ Run MetaWRAP binning (MetaBAT2 + MaxBin2 + CONCOCT)  
✅ Refine bins for improved quality  
✅ Assess MAG quality with CheckM2  
✅ Calculate MAG abundance across samples (CoverM)  
✅ Validate MAG coverage in samples (SingleM)  
✅ Visualize and interpret results

---

## 📁 Directory Structure

```
day3-binning/
├── README.md                          # This file
├── scripts/
│   ├── slurm/                         # HPC batch scripts
│   │   ├── 01_metawrap_binning_batch.sh     # Initial binning + refinement
│   │   ├── 02_coverm_abundance_batch.sh     # Abundance calculation
│   │   └── 03_singlem_coverage_batch.sh     # Coverage validation
│   ├
│   │
│   └── visulization/                      # Visualization scripts
│       ├── visualize_mag_abundance.py       # Abundance heatmaps
│       ├── visualize_singlem_coverage.py    # Coverage plots
│       ├── combine_abundance_coverage.py    # Integrated analysis
│       └── mag_abundance_heatmap.R          # R heatmap script
└── running-on-your-laptop/
    └── RUNNING_ON_LAPTOP.md           # Complete laptop tutorial
    └── desktop_metawrap_loop.sh
```

---

### Main Tutorials

- **[Day 3 Blog Post](https://jojyjohn28.github.io/blog/metagenome-analysis-day3-binning/)** - Complete tutorial with modern MetaWRAP workflow
- **[Laptop Guide](/running-on-your-laptop/RUNNING_ON_LAPTOP.md)** - Step-by-step for desktop/laptop users

## 💻 Script Descriptions

### SLURM Scripts (HPC)

**01_metawrap_binning_batch.sh**

- Runs MetaWRAP binning on multiple samples in parallel
- Includes initial binning, refinement, and quantification
- Uses SLURM array jobs for parallel processing

**02_coverm_abundance_batch.sh**

- Calculates MAG abundance across all samples
- Generates relative abundance, mean coverage, RPKM
- Produces abundance tables and summary statistics

**03_singlem_coverage_batch.sh**

- Validates MAG detection in samples using marker genes
- Calculates % of genome covered by reads
- Identifies unbinned organisms

### Desktop Scripts

**desktop_metawrap_loop.sh**

- Processes samples sequentially on desktop/laptop
- Adjustable threads and memory settings
- Automatic error handling and progress tracking

### Visualization Scripts

**visualize_mag_abundance.py**

- Creates abundance heatmaps and composition plots
- Generates distribution histograms
- Sample correlation analysis

**visualize_singlem_coverage.py**

- MAG coverage heatmaps
- Detection matrix (present/absent)
- Quality scatter plots

**combine_abundance_coverage.py**

- Merges CoverM and SingleM results
- Creates decision matrix plots
- Classifies MAGs by quality

**mag_abundance_heatmap.R**

- Publication-quality heatmaps
- Multiple color schemes (YlOrRd, Viridis)
- Clustering and correlation analysis

---

## 📚 Additional Resources

### Key Papers

- Kang et al. (2019) - MetaBAT2: _PeerJ_
- Wu et al. (2016) - MaxBin2: _Bioinformatics_
- Alneberg et al. (2014) - CONCOCT: _Nature Methods_
- Uritskiy et al. (2018) - MetaWRAP: _Microbiome_
- Chklovski et al. (2023) - CheckM2: _Nature Methods_

---

## ✅ Success Checklist

Before moving to Day 4:

- [ ] Initial binning completed (3 binners run)
- [ ] Bins refined with MetaWRAP
- [ ] Quality assessment with CheckM2
- [ ] At least 5-10 MQ+ MAGs recovered
- [ ] Abundance calculated with CoverM
- [ ] Coverage validated with SingleM
- [ ] Visualizations generated
- [ ] MAGs organized in final directory

---

## ➡️ What's Next?

**Day 4: Functional Annotation** (Coming Soon)

Learn to annotate genes and predict metabolic functions in your MAGs!

Topics:

- Gene prediction with Prodigal
- Functional annotation with eggNOG-mapper
- Pathway reconstruction with KEGG
- Biosynthetic gene cluster identification

---

## 💬 Feedback & Support

- 🐛 [Report issues](https://github.com/jojyjohn28/metagenome-analysis-series/issues)
- 💡 [Ask questions](https://github.com/jojyjohn28/metagenome-analysis-series/discussions)
- ⭐ [Star the repo](https://github.com/jojyjohn28/metagenome-analysis-series)
- ▶ [Read the blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day3-binning/)

---

_Last updated: February 2026_
