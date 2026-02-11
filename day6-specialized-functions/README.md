# Day 6: Specialized Genomic Functions

Discover hidden genomic capabilities: secondary metabolites, antimicrobial resistance, CAZymes, prophages, CRISPR systems, and mobile genetic elements.

## 📋 Overview

Go beyond basic annotation to uncover specialized functions that make organisms unique.

### What You'll Discover

🧪 **Secondary metabolites** - BGCs, antibiotics, toxins  
💊 **Antimicrobial resistance** - AMR genes & mechanisms  
🍬 **CAZymes** - Carbohydrate degradation  
🦠 **Prophages** - Integrated viral sequences  
✂️ **CRISPR systems** - Bacterial immunity  
🔄 **Mobile elements** - Transposons, integrons  
🧬 **Protein domains** - Functional motifs

---

## 📜 Script Descriptions

### SLURM Scripts (HPC)

```bash
# AMR screening across all databases
sbatch scripts/slurm/abricate.sh

# BGC detection with antiSMASH
sbatch scripts/slurm/antismash.sh

# Protein domain annotation
sbatch scripts/slurm/interproscan.sh
```

### Parsing Scripts (Python)

```bash
# Parse antiSMASH results
python scripts/parsing_python/parse_antismash.py antismash_output/

# Parse dbCAN CAZyme results
python scripts/parsing_python/parse_dbcan.py dbcan_output/overview.txt

# Parse InterProScan domains
python scripts/parsing_python/parse_ipr.py interproscan_output.tsv

# Parse CARD-RGI AMR results
python scripts/parsing_python/parse_rgi.py rgi_output.txt
```

### Visualization Scripts (R)

```bash
# Create BGC heatmap across genomes
Rscript scripts/R/bgc_heatmap.R bgc_summary.csv

# Generate CAZyme bubble plot
Rscript scripts/R/cazyme_bubble_plot.R cazyme_data.csv
```

### Other Scripts

```bash
# Comprehensive analysis pipeline
bash scripts/other/comprehensive_analysis.sh genome.fa

# Compare specialized functions across genomes
python scripts/other/compare_specialized_functions.py specialized_results/
```

---

## 🚀 Quick Start

### One-Line Commands

```bash
# Secondary metabolites (30-60 min)
antismash --output-dir antismash_out --genefinding-tool prodigal --cpus 8 genome.gbk

# AMR screening (2 min)
abricate genome.fa > amr_results.tab

# AMR comprehensive (10 min)
rgi main -i proteins.faa -o rgi_out -t protein --num_threads 8

# CAZymes (15-20 min)
run_dbcan proteins.faa protein --out_dir dbcan_out --tools all --threads 8

# Prophages (30-40 min)
virsorter run -i genome.fa -w virsorter2_out -j 8 all

# CRISPR (1 min)
minced genome.fa crispr_out.txt

# Mobile elements (2 min)
abricate --db isfinder genome.fa > insertion_sequences.tab
```

See **[RUNNING_ON_LAPTOP.md](running-on-your-laptop/RUNNING_ON_LAPTOP.md)** for complete tutorial.

---

## 📁 Repository Structure

```
day6-specialized-functions/
├── README.md                          # This file
├── RUNNING_ON_LAPTOP.md              # Practical guide with batch scripts
└── scripts/
    ├── slurm/                         # HPC batch scripts
    │   ├── abricate.sh
    │   ├── antismash.sh
    │   └── interproscan.sh
    ├── parsing_python/                # Result parsing scripts
    │   ├── parse_antismash.py
    │   ├── parse_dbcan.py
    │   ├── parse_ipr.py
    │   └── parse_rgi.py
    ├── R/                             # Visualization scripts
    │   ├── bgc_heatmap.R
    │   └── cazyme_bubble_plot.R
    └── other/                         # Additional scripts
        ├── comprehensive_analysis.sh
        └── compare_specialized_functions.py
```

---

## 🔄 Workflow

```
Annotated Genomes (Day 5)
    ↓
┌─────────────────────────────┐
│ Fast Screening              │  ABRicate, MinCED
│ AMR + CRISPR + MGEs         │  (~5 min per genome)
└─────────────────────────────┘
    ↓
┌─────────────────────────────┐
│ Medium Analysis             │  dbCAN, VirSorter2
│ CAZymes + Prophages         │  (~1 hr per genome)
└─────────────────────────────┘
    ↓
┌─────────────────────────────┐
│ Deep Analysis               │  antiSMASH, RGI
│ BGCs + Comprehensive AMR    │  (~2 hrs per genome)
└─────────────────────────────┘
    ↓
Specialized Function Catalog
```

---

## 🛠️ Tools Overview

| Tool             | Function          | Speed  | Depth     |
| ---------------- | ----------------- | ------ | --------- |
| **antiSMASH**    | BGCs              | ⚡     | Excellent |
| **ABRicate**     | AMR screening     | ⚡⚡⚡ | Good      |
| **CARD-RGI**     | AMR comprehensive | ⚡⚡   | Excellent |
| **dbCAN**        | CAZymes           | ⚡⚡   | Excellent |
| **VirSorter2**   | Prophages         | ⚡     | Excellent |
| **MinCED**       | CRISPR            | ⚡⚡⚡ | Good      |
| **InterProScan** | Domains           | ⚡     | Excellent |

---

## 📦 Installation

```bash
# Fast tools
conda create -n abricate -c bioconda abricate -y
conda create -n minced -c bioconda minced -y

# Standard tools
conda create -n rgi -c bioconda rgi -y
conda create -n dbcan -c bioconda dbcan -y
conda create -n virsorter2 -c bioconda virsorter=2 -y

# Advanced tools
conda create -n antismash -c bioconda antismash -y
conda create -n integron_finder -c bioconda integron_finder -y

# Download databases
conda activate antismash && download-antismash-databases
conda activate rgi && rgi load --card_json ~/card_database/card.json
conda activate abricate && abricate-get_db --db all
conda activate virsorter2 && virsorter setup -d ~/virsorter2-db -j 4
```

---

## 🎯 Use Cases

### Research Questions You Can Answer

**After Day 6, you can determine:**

✓ Can this organism produce antibiotics?  
✓ Is this strain resistant to last-resort antibiotics?  
✓ Can it degrade cellulose/chitin/starch?  
✓ Does it carry prophages (potential HGT)?  
✓ Does it have CRISPR immunity?  
✓ Are resistance genes on mobile elements?  
✓ What biosynthetic capabilities does it have?

---

## 📖 Documentation

- **[Laptop Guide](RUNNING_ON_LAPTOP.md)** - Practical workflows & batch processing
- **[SLURM Scripts](scripts/slurm/)** - HPC batch scripts
- **[Parsing Scripts](scripts/parsing_python/)** - Result analysis
- **[Visualization](scripts/R/)** - R plotting scripts
- [antiSMASH](https://antismash.secondarymetabolites.org/)
- [CARD](https://card.mcmaster.ca/)
- [ABRicate](https://github.com/tseemann/abricate)
- [dbCAN](http://bcb.unl.edu/dbCAN2/)
- [VirSorter2](https://github.com/jiarong/VirSorter2)

## ✅ Success Checklist

- [ ] BGCs identified and classified
- [ ] AMR profile generated (critical genes flagged)
- [ ] CAZyme repertoire characterized
- [ ] Prophage regions detected
- [ ] CRISPR systems identified
- [ ] Mobile elements cataloged
- [ ] Comparative analysis completed

---

## 📈 Real-World Examples

### Pathogen Analysis

"Identified KPC carbapenemase + mcr-1 colistin resistance on same plasmid"

### Environmental Microbe

"30 BGCs detected including novel NRPS cluster; 200+ CAZymes for cellulose degradation"

### Probiotic Strain

"5 bacteriocin BGCs, no AMR genes, 3 CRISPR arrays"

---

## ➡️ What's Next?

After Day 6:

- **Comparative genomics** - How do strains differ?
- **Pangenome analysis** - Core vs accessory genome
- **Phylogenomics** - Evolutionary relationships
- **Publication** - You have a complete dataset!

- **[Tutorial Blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day6-specialized-functions/)** - Comprehensive guide

_Last updated: February 2026_
