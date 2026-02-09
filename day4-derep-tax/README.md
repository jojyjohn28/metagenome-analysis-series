# Day 4: Genome Dereplication & Taxonomic Classification

Identify unique species and assign accurate taxonomic classifications to your MAGs.

## 📋 Overview

Remove redundant genomes and classify species using GTDB taxonomy - the gold standard for bacterial and archaeal classification.

### What You'll Learn

✅ Dereplicate MAGs with dRep (species-level clustering)  
✅ Classify genomes with GTDB-Tk  
✅ Identify novel species (ANI <95%)  
✅ Visualize phylogenetic trees (iTOL, ggtree)  
✅ Create species catalogs

---

## 🚀 Quick Start

### HPC (PBS/SLURM)

```bash
# 1. Dereplicate genomes
qsub scripts/slurm/drep.pbs

# 2. Classify with GTDB-Tk
qsub scripts/slurm/gtdbtk.pbs

# 3. Visualize results
python scripts/drep_summary.py
python scripts/gtdbtk_tax_summary.py
Rscript scripts/visualize_tree.R
```

### Desktop/Laptop

See **[RUNNING_ON_LAPTOP.md](RUNNING_ON_LAPTOP.md)** for complete tutorial.

**One-line commands:**

```bash
# dRep (species level, 95% ANI)
dRep dereplicate dereplicated_genomes -g quality_mags/*.fa -p 8 -sa 0.95

# GTDB-Tk (complete workflow)
gtdbtk classify_wf --genome_dir dereplicated_genomes --out_dir gtdbtk_output --extension fa --cpus 8
```

---

## 📁 Repository Structure

```
day4-derep-tax/
├── README.md                      # This file
├── RUNNING_ON_LAPTOP.md          # Complete laptop tutorial
└── scripts/
    ├── slurm/
    │   ├── drep.pbs              # dRep dereplication
    │   └── gtdbtk.pbs            # GTDB-Tk classification
    ├── drep_summary.py           # Analyze dRep results
    ├── gtdbtk_tax_summary.py     # Taxonomic summaries
    └── visualize_tree.R          # Phylogenetic tree visualization
```

---

## 🔄 Workflow

```
Quality MAGs (from Day 3)
    ↓
┌─────────────────────┐
│ dRep                │  Remove redundant genomes
│ • 95% ANI          │  Get species representatives
│ • 40-70% reduction │  (~1-4 hours)
└─────────────────────┘
    ↓
Dereplicated Genomes (species representatives)
    ↓
┌─────────────────────┐
│ GTDB-Tk             │  Taxonomic classification
│ • Identify markers  │  GTDB R207 database
│ • Align + classify  │  (~4-12 hours)
└─────────────────────┘
    ↓
Classified Species + Phylogenetic Trees
```

---

## 📊 Expected Results

### Dereplication

| Input MAGs | Dereplicated | Reduction |
| ---------- | ------------ | --------- |
| 100        | 40-60        | 40-60%    |
| 200        | 70-120       | 40-65%    |
| 500        | 150-300      | 40-70%    |

**Typical:** 50-70% reduction from redundancy

### GTDB-Tk Classification

- ✅ 95-99% successful classification
- 🆕 10-30% novel species (ANI <95%)
- 🎉 1-5% novel genera (ANI <85%)

---

## 🛠️ Software Requirements

### Installation

```bash
# dRep
conda create -n drep python=3.9
conda install -c bioconda drep

# GTDB-Tk (separate environment)
conda create -n gtdbtk python=3.9
conda install -c bioconda gtdbtk

# Download GTDB database (~65 GB, one-time)
download-db.sh
```

### Key Tools

- **dRep** v3.4+ - Genome dereplication
- **GTDB-Tk** v2.2+ - Taxonomic classification
- **GTDB** R207 - Database (65 GB)

---

## 📈 Key Metrics

### ANI Thresholds

| ANI     | Taxonomic Level | Usage                  |
| ------- | --------------- | ---------------------- |
| **99%** | Strain          | Strain-level analysis  |
| **95%** | Species         | Standard (recommended) |
| **90%** | Genus (approx)  | Broad clustering       |
| **85%** | Family (approx) | Very loose             |

### Quality Filters

- Minimum completeness: 50%
- Maximum contamination: 10%
- Recommended: Use HQ+MQ MAGs from Day 3

---

## 🎯 Deliverables

After Day 4, you'll have:

✅ **Dereplicated genome set** - One representative per species  
✅ **Taxonomic classifications** - Full GTDB taxonomy  
✅ **Species catalog** - CSV with all classifications  
✅ **Phylogenetic trees** - For visualization (iTOL, ggtree)  
✅ **Novel species list** - Potential new discoveries

---

## 📖 Documentation

- **[Tutorial Blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day4-dereplication-taxonomy/)** - Comprehensive guide
- **[Laptop Guide](RUNNING_ON_LAPTOP.md)** - Desktop/laptop workflow
- **[dRep Docs](https://drep.readthedocs.io/)** - Official documentation
- **[GTDB-Tk Docs](https://github.com/Ecogenomics/GTDBTk)** - GitHub repository

---

## ➡️ Next Steps

**Day 5: Functional Annotation** (Coming Soon)

Annotate genes and predict metabolic functions in your species representatives!

Topics:

- Gene prediction (Prodigal)
- Functional annotation (eggNOG-mapper)
- Pathway reconstruction (KEGG)
- Secondary metabolite prediction (antiSMASH)

---

## 💬 Feedback

- 🐛 [Report issues](https://github.com/jojyjohn28/metagenome-analysis-series/issues)
- 💡 [Discussions](https://github.com/jojyjohn28/metagenome-analysis-series/discussions)
- ⭐ [Star the repo](https://github.com/jojyjohn28/metagenome-analysis-series)
