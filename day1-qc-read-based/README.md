# Day 1 Scripts - Metagenome Analysis Series

This directory contains all batch processing scripts for Day 1 of the metagenome analysis workflow.

## 📁 Script Overview

### Quality Control

- **01_fastqc_batch.sh** - Run FastQC on multiple raw samples
- **06_final_qc_summary.sh** - Final QC check and read count summary

### Read Processing

- **02_trimmomatic_batch.sh** - Adapter trimming and quality filtering with statistics
- **03_kneaddata_batch.sh** - Host contamination removal using KneadData
- **04_bbduk_host_removal.sh** - Host contamination removal using BBDuk (alternative)
- **05_phix_removal.sh** - PhiX spike-in removal

### Taxonomic Profiling

- **07_kaiju_profiling.sh** - Protein-based classification with Kaiju
- **08_kraken2_bracken.sh** - K-mer based classification with Kraken2 + Bracken
- **09_motus_profiling.sh** - Marker gene profiling with mOTUs
- **10_metaphlan_profiling.sh** - Marker gene profiling with MetaPhlAn

### Analysis and Visualization

- **11_venn_diagram_taxa.sh** - Compare detected taxa across tools
- **compare_taxonomy.R** - Comprehensive R visualization script

## 🚀 Usage

### Before Running

1. Set appropriate paths in each script (INPUT_DIR, OUTPUT_DIR, database paths)
2. Adjust thread counts based on your system
3. Make scripts executable: `chmod +x *.sh`

### Running Scripts

SLURM Submission

```bash
# Sequential with dependencies
sbatch slurm/01_fastqc_batch_slurm.sh
sbatch slurm/02_trimmomatic_batch_slurm.sh
# ... continue with remaining scripts

# Or use the master pipeline script
bash slurm/master_pipeline.sh
```

## 📝 Customization

### Thread Count

Adjust `THREADS` variable in each script based on your system:

- **HPC:** 32-64 cores
- **Desktop:** 4-8 cores (use n-1)

### Memory

Some tools (especially Kraken2) require significant RAM:

- Kraken2 standard: ~50GB RAM
- Kaiju nr: ~70GB RAM
- mOTUs: ~8GB RAM
- MetaPhlAn: ~5GB RAM

### Database Paths

Update these paths in scripts:

- `KAIJU_DB`: Path to Kaiju database (.fmi file)
- `KRAKEN_DB`: Path to Kraken2 database directory
- `HOST_REF`: Path to host genome reference
- `PHIX_REF`: Path to PhiX reference

## 📊 Expected Outputs

### QC Scripts

- FastQC HTML reports
- MultiQC summary reports
- Trimming statistics CSV
- Read count summary CSV

### Taxonomic Profiling

- Per-sample taxonomic profiles
- Combined abundance tables
- Krona interactive plots (Kaiju)
- Summary statistics

### Visualization

- Heatmaps (PDF)
- Stacked barplots (PDF)
- Tool comparison plots (PDF)
- Correlation plots (PDF)
- Diversity metrics (CSV)

## ⚠️ Important Notes

1. **Run order matters**: Follow the sequential order for processing scripts (01-06)
2. **Taxonomic profiling**: Scripts 07-10 can run independently
3. **Disk space**: Ensure sufficient space for intermediate files
4. **Logs**: Check log directories for errors
5. **Validation**: Always verify outputs before proceeding

## 🐛 Troubleshooting

### Script fails with "command not found"

- Ensure all tools are installed and in PATH
- Activate conda environment if using conda

### Out of memory errors

- Reduce thread count
- Use smaller databases
- Process samples sequentially

### No output files generated

- Check log files in logs/ directories
- Verify input file paths
- Ensure correct file naming conventions

## 📚 Requirements

### Software

- FastQC (v0.11.9+)
- MultiQC (v1.12+)
- Trimmomatic (v0.39+)
- BBTools/BBDuk (v38.90+)
- KneadData (v0.12.0+) or BBDuk
- Kaiju (v1.9.0+)
- Kraken2 (v2.1.2+)
- Bracken (v2.7+)
- mOTUs (v3.0.3+)
- MetaPhlAn (v4.0+)

### R Packages (for visualization)

- ggplot2
- dplyr
- tidyr
- ComplexHeatmap
- RColorBrewer
- pheatmap

Install R packages:

```r
install.packages(c("ggplot2", "dplyr", "tidyr", "RColorBrewer", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("ComplexHeatmap")
```

## 🔗 Links

- **Main Tutorial**: [Day 1 Blog Post](https://jojyjohn28.github.io/blog/metagenome-analysis-day1-qc-taxonomy/)
- **GitHub Repository**: https://github.com/jojyjohn28/metagenome-analysis-series
- **Issues**: https://github.com/jojyjohn28/metagenome-analysis-series/issues

## 📄 License

These scripts are part of the Metagenome Analysis Series tutorial.
Feel free to use and modify for your research.

---

**Author**: Jojy John  
**GitHub**: [@jojyjohn28](https://github.com/jojyjohn28)  
**Date**: February 2026
