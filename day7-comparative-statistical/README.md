# Day 7: Comparative Genomics & Statistical Analysis

Connect genomes to environment through pangenomics, statistical ecology, and network analysis.

## 📋 Overview

**What You'll Learn:**

- Pangenome analysis (core vs accessory genes)
- Statistical tests for environmental effects
- Co-occurrence network analysis
- Integration of multi-omic data

**Prerequisites:** Days 1-6 (Annotated genomes + metadata)

---

## 🚀 Quick Start

### Statistical Analysis (R Scripts)

```r
# PERMANOVA: Test if groups differ
Rscript scripts/permanova_simple.R

# RDA: Identify environmental drivers
Rscript scripts/rda_simple.R
```

**All scripts include toy data** - no external files needed!

---

## 📁 Repository Structure

```
day7-comparative-statistical/
├── README.md                    # This file
└── scripts/
    ├── permanova_analysis.R     # Comprehensive PERMANOVA
    ├── permanova_simple.R       # Beginner-friendly PERMANOVA
    ├── rda_analysis.R           # Complete RDA/db-RDA
    └── rda_simple.R             # Quick RDA guide
```

---

## 📊 Available Scripts

### PERMANOVA (Group Differences)

| Script                   | Description       | Time   | Difficulty    |
| ------------------------ | ----------------- | ------ | ------------- |
| **permanova_simple.R**   | Beginner guide    | 5 min  | ⭐ Easy       |
| **permanova_analysis.R** | Complete analysis | 10 min | ⭐⭐ Advanced |

**Question answered:** Do groups have different communities?

**Example:** Control vs Treatment, Healthy vs Diseased

---

### RDA (Environmental Associations)

| Script             | Description   | Time   | Difficulty      |
| ------------------ | ------------- | ------ | --------------- |
| **rda_simple.R**   | Quick start   | 5 min  | ⭐ Easy         |
| **rda_analysis.R** | Full workflow | 15 min | ⭐⭐⭐ Advanced |

**Question answered:** Which environmental factors explain community variation?

**Example:** pH, temperature, nutrients

---

## 🔄 Complete Day 7 Workflow

```
Annotated Genomes + Metadata
    ↓
1. Pangenome Analysis
   → PanX, Roary, BPGA, Anvi'o
   → Identify core/accessory genes
    ↓
2. PERMANOVA
   → Test: Are communities different?
   → Output: P-value, R²
    ↓
3. RDA / db-RDA
   → Test: Which environmental factors matter?
   → Output: Ordination, vectors
    ↓
4. Co-occurrence Networks
   → Build: SparCC, WGCNA
   → Identify: Hubs, modules
    ↓
5. Integration
   → Connect findings
   → Generate figures
```

## 🎯 Key Features

### Self-Contained

- ✅ All scripts include toy data
- ✅ No external files required
- ✅ Works immediately

### Comprehensive

- ✅ Assumption testing (betadisper, VIF)
- ✅ Multiple models compared
- ✅ Publication-quality figures
- ✅ Saves results automatically

### Educational

- ✅ Clear comments throughout
- ✅ Interpretation guides
- ✅ "What to report" sections
- ✅ Troubleshooting included

---

## 📊 Expected Outputs

### PERMANOVA

- P-value (significant difference?)
- R² (variance explained)
- Pairwise comparisons
- NMDS ordination plot
- Dispersion test results

### RDA

- Significant variables identified
- R² per variable
- Ordination with vectors
- Variance explained by axes
- Publication-ready plots

---

## 💡 Which Script to Use?

### Use Simple Scripts If:

- ✅ Learning the methods
- ✅ Quick exploratory analysis
- ✅ Need basic results fast
- ✅ First time using these methods

### Use Full Scripts If:

- ✅ Publication-quality analysis
- ✅ Multiple models to compare
- ✅ Need detailed diagnostics
- ✅ Complex experimental designs

---

## 📖 Documentation

**Complete tutorial:** See blog post at [Day 7 Blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day7-comparative-statistical/)

**Covers:**

- Pangenome analysis (4 tools)
- PERMANOVA & RDA theory
- Co-occurrence networks (SparCC, WGCNA)
- Integration strategies
- Best practices

---

## ✅ Success Checklist

After Day 7:

- [ ] Ran PERMANOVA (groups differ?)
- [ ] Checked dispersion assumption
- [ ] Identified environmental drivers (RDA)
- [ ] Created ordination plots
- [ ] Understood R² values
- [ ] Know what to report in papers

---

## 💬 Troubleshooting

### "Package not found"

```r
install.packages("vegan")
install.packages("ggplot2")
```

### "Cannot find toy data"

- Scripts generate toy data automatically
- No external files needed!

### "PERMANOVA not significant"

- Check sample size (n > 20 recommended)
- Verify groups are actually different
- Try with your own data

### "RDA: No variables selected"

- Variables may not explain variation
- Check for collinearity (VIF)
- Try db-RDA instead

---

## 📚 Additional Resources

**Pangenome tools:**

- [PanX detailed tutorial](https://jojyjohn28.github.io/blog/panx-pangenome-analysis/)
- [Roary](https://github.com/sanger-pathogens/Roary)
- [Anvi'o](https://anvio.org/)

**Statistical methods:**

- [vegan tutorial](https://cran.r-project.org/web/packages/vegan/vignettes/intro-vegan.pdf)
- [PERMANOVA guide](https://doi.org/10.1111/j.1442-9993.2001.01070.pp.x)

---

## Read more at [Day 7 Blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day7-comparative-statistical/)

Last updated: February 2026
