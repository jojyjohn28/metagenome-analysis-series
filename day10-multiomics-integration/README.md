# Day 10: Multi-Omics Integration - Metagenomics & Metatranscriptomics

Integrate metagenomics (DNA) and metatranscriptomics (RNA) data to reveal active microbial functions. This tutorial provides complete workflows for expression ratio analysis, differential expression testing, and multi-omics visualization.

---

## 📁 Repository Structure

```
day10-multiomics-integration/
├── scripts/                          # Main analysis scripts
│   ├── 01_load_and_prepare_data.py      # Load and align MG/MTX data
│   ├── 02_normalize_data.py             # CPM normalization
│   ├── 03_calculate_expression_ratios.py # RNA/DNA ratio calculation
│   ├── 04_visualize_expression_ratios.py # Generate plots
│   └── deseq2_analysis.R                # Differential expression analysis
│
├── toy_data_images/                  # Example outputs with toy data
│   ├── comparative_heatmaps/            # DNA vs RNA heatmaps
│   ├── de_seq/                          # DESeq2 results and plots
│   ├── pathway/                         # Pathway activity analysis
│   ├── python_expression/               # Expression ratio visualizations
│   ├── ratio/                           # Expression ratio heatmaps
│   └── taxonomy_integration/            # Species activity analysis
│
└── README.md                         # This file
```

**💡 No data but interested in learning?**
The repo includes toy datasets, so you can practice the full workflow step-by-step.

---

## 📊 Analysis Workflows

### 1. Gene-Level Integration

**Script:** `01-04_*.py`  
**Input:** MG gene counts, MTX transcript counts  
**Output:** Expression ratios, visualizations  
**Example outputs:** `toy_data_images/python_expression/`

**What it does:**

- Loads and aligns gene IDs between MG and MTX
- Normalizes to CPM (Counts Per Million)
- Calculates log2(RNA/DNA) expression ratios
- Generates histogram, MA plot, and boxplots

### 2. Differential Expression (DESeq2)

**Script:** `deseq2_analysis.R`  
**Input:** MTX count matrix, sample metadata  
**Output:** Statistical results, DE genes, plots  
**Example outputs:** `toy_data_images/de_seq/`

**What it does:**

- Statistical testing for differential expression
- Generates MA plot, volcano plot, PCA
- Creates heatmaps of top DE genes
- Identifies significantly up/downregulated genes

### 3. Comparative Heatmaps

**Script:** `toy_data_images/comparative_heatmaps/comparative_heatmaps.py`  
**Input:** MG CPM, MTX CPM, significant genes  
**Output:** Side-by-side DNA vs RNA heatmaps  
**Example outputs:** `toy_data_images/comparative_heatmaps/`

**What it does:**

- Creates side-by-side heatmaps comparing DNA and RNA
- Z-score normalization for visualization
- Highlights expression patterns across samples

### 4. Expression Ratio Heatmap

**Script:** `toy_data_images/ratio/ratio-heatmap.py`  
**Input:** Expression ratios, significant genes  
**Output:** Ratio heatmap visualization  
**Example outputs:** `toy_data_images/ratio/`

**What it does:**

- Visualizes log2(RNA/DNA) ratios as heatmap
- Color-coded by activity level
- Focuses on differentially expressed genes

### 5. Pathway Integration

**Script:** `toy_data_images/pathway/pathway.py`  
**Input:** MG pathway abundance, MTX pathway abundance  
**Output:** Pathway activity scores, comparison plots  
**Example outputs:** `toy_data_images/pathway/`

**What it does:**

- Compares pathway DNA abundance vs RNA activity
- Identifies highly active vs dormant pathways
- Generates pathway activity comparison plots

### 6. Taxonomic Integration

**Script:** `toy_data_images/taxonomy_integration/taxonomy_integration.py`  
**Input:** MG taxonomy, MTX taxonomy  
**Output:** Species activity scores, quadrant plots  
**Example outputs:** `toy_data_images/taxonomy_integration/`

**What it does:**

- Calculates species-level activity scores
- Identifies active vs dormant species
- Creates abundance vs activity plots

---

## 📈 Example Outputs

### Expression Ratio Analysis

- `expression_ratio_histogram.png` - Distribution of ratios
- `ma_plot_expression.png` - Abundance vs expression
- `expression_ratio_boxplot.png` - Sample-wise variation

### DESeq2 Results

- `deseq2_all_results.csv` - Complete statistical results
- `deseq2_significant_genes.csv` - Filtered DE genes
- `deseq2_ma_plot.pdf` - MA plot visualization
- `deseq2_volcano_plot.pdf` - Volcano plot
- `deseq2_top50_heatmap.pdf` - Top 50 DE genes heatmap

### Pathway Analysis

- `pathway_expression_ratios.csv` - Pathway-level ratios
- `pathway_activity_comparison.png` - Active vs inactive pathways

### Taxonomic Analysis

- `taxonomic_activity_scores.csv` - Species activity metrics
- `top_active_species.png` - Most active species
- `species_abundance_vs_activity.png` - Quadrant plot

---

### Why Integration Matters

- **DNA alone** shows genetic potential (what microbes _can_ do)
- **RNA** reveals actual activity (what microbes _are_ doing)
- **Integration** identifies:
  - Active pathways beyond genomic potential
  - Rare but highly active species
  - Dormant vs metabolically active populations
  - Community responses to environmental changes

---

## 🎓 Learning Outcomes

After completing this tutorial, you will:

- ✅ Calculate and interpret expression ratios
- ✅ Perform statistical differential expression analysis
- ✅ Create publication-quality comparative visualizations
- ✅ Integrate pathway and taxonomic data
- ✅ Identify biologically meaningful patterns
- ✅ Generate comprehensive multi-omics reports

---

## 🐛 Troubleshooting

### Common Issues

**1. No common genes between MG and MTX**

- Ensure gene IDs match exactly
- Check for consistent formatting
- Verify same gene annotation database used

**2. DESeq2 error: "counts must be integers"**

- Use raw counts (not CPM) for DESeq2
- Round counts if necessary: `round(counts)`

**3. Sample name mismatch**

- MG samples should contain 'MG' in name
- MTX samples should contain 'MTX' in name
- Corresponding samples differ only by MG/MTX

**4. Low expression ratios across all genes**

- Check if data is properly normalized
- Verify RNA extraction quality
- Consider rRNA contamination in MTX

---

### Tools Documentation

- [DESeq2 Bioconductor](https://bioconductor.org/packages/release/bioc/html/DESeq2.html)
- [pandas Documentation](https://pandas.pydata.org/docs/)
- [matplotlib Gallery](https://matplotlib.org/stable/gallery/index.html)
- [seaborn Tutorial](https://seaborn.pydata.org/tutorial.html)

---

More detail read today's blog post [Day 10](https://jojyjohn28.github.io/blog/metagenome-analysis-day10-multiomics-integration/)

**Last Updated:** February 2026
