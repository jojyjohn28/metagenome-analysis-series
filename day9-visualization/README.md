# Day 9: Visualization & Publication

Create publication-quality figures that tell compelling stories with your data.

## 📁 Repository Structure

```
day9-visualization/
├── README.md
├── images/                          # Example outputs (12 images)
└── scripts/
    ├── R/                           # 5 R scripts
    └── python/                      # 7 Python scripts
```

---

## 🎨 Available Scripts

### R Scripts (5)

| Script               | Plot Type             | Output Example           |
| -------------------- | --------------------- | ------------------------ |
| `stacked_barplot.R`  | Taxonomic composition | `stacked_barplot_r.png`  |
| `alpha_diversity.R`  | Diversity boxplots    | `alpha_diversity.png`    |
| `heatmap.R`          | Clustered heatmap     | `heatmap_r.png`          |
| `correlation.R`      | Scatter + regression  | `correlation_r.png`      |
| `interactive_plot.R` | Interactive HTML      | `interactive_plot_r.png` |

### Python Scripts (7)

| Script                       | Plot Type             | Output Example           |
| ---------------------------- | --------------------- | ------------------------ |
| `basic_taxonomy_bar_plot.py` | Taxonomic barplot     | `basic_taxonomy_py.png`  |
| `alpha_diversity.py`         | Diversity boxplots    | `alpha_diversity_py.png` |
| `heatmap.py`                 | Clustered heatmap     | `heatmap_py.png`         |
| `correlations.py`            | Correlation matrix    | `correlation-py.png`     |
| `scatter.py`                 | Ordination (PCA/NMDS) | `scater-py.png`          |
| `Pairplot.py`                | Multivariate pairs    | `multivariate_py.png`    |
| `interactive_taxonomy.py`    | Interactive HTML      | `interactive-tax.png`    |

## 🚀 Quick Start

### R

```r
# Run any R script
Rscript scripts/R/stacked_barplot.R
Rscript scripts/R/alpha_diversity.R
Rscript scripts/R/heatmap.R
```

### Python

```bash
# Run any Python script
python scripts/python/basic_taxonomy_bar_plot.py
python scripts/python/alpha_diversity.py
python scripts/python/heatmap.py
```

**All scripts include toy data - work immediately!**

## 📊 Common Use Cases

| Need to Show                 | Use This Script                                                |
| ---------------------------- | -------------------------------------------------------------- |
| **Taxonomic composition**    | R: `stacked_barplot.R` or Python: `basic_taxonomy_bar_plot.py` |
| **Diversity metrics**        | R: `alpha_diversity.R` or Python: `alpha_diversity.py`         |
| **MAG/Gene abundance**       | R: `heatmap.R` or Python: `heatmap.py`                         |
| **Environment correlations** | R: `correlation.R` or Python: `correlations.py`                |
| **Ordination (PCA/NMDS)**    | Python: `scatter.py`                                           |
| **Multiple variables**       | Python: `Pairplot.py`                                          |
| **Interactive exploration**  | R: `interactive_plot.R` or Python: `interactive_taxonomy.py`   |

---

## 🎯 R vs Python

### Use R:

- ✅ ggplot2 grammar of graphics
- ✅ Statistical overlays built-in
- ✅ **See complete R series:** [My R Visualization Tutorials](https://jojyjohn28.github.io/blog/r-visualization-series/)

### Use Python:

- ✅ Integration with pandas/numpy
- ✅ Interactive plots (Plotly)
- ✅ Network analysis (NetworkX)

---

## 📐 Publication Standards

All scripts produce:

- ✅ **300 DPI** resolution
- ✅ **PDF** (vector) + PNG (raster)
- ✅ **Colorblind-safe** palettes
- ✅ **Clear labels** with units
- ✅ **Readable fonts** (10-12pt)

Final figures can be exported to in Adobe Illustrator and refine it for publication, including adjustments to fonts, spacing, and layout.

## 📚 Resources

- **Matplotlib:** https://matplotlib.org/
- **ggplot2:** https://ggplot2.tidyverse.org/

---

## 📖 Documentation

**Complete tutorial:** See blog post at [Day 8 Blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day8-workflows-platforms/)

Last updated: February 2026
