#!/bin/bash
#SBATCH --job-name=taxonomy_viz
#SBATCH --output=logs/slurm/taxonomy_viz_%j.out
#SBATCH --error=logs/slurm/taxonomy_viz_%j.err
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=compute

# Script: 12_compare_taxonomy_slurm.sh
# Description: Visualize and compare taxonomic profiles (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 12_compare_taxonomy_slurm.sh

# Load modules
module load R/4.2.0

echo "Starting taxonomic visualization..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"

# Create log directory
mkdir -p logs/slurm

# Run R script
Rscript << 'EOF'

# Load required libraries
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(ComplexHeatmap)
  library(RColorBrewer)
  library(pheatmap)
})

cat("Loading taxonomic data...\n")

# Read data from different tools
kaiju <- read.table("taxonomy/kaiju/all_samples_genus.tsv", 
                    header=TRUE, sep="\t", row.names=1, check.names=FALSE)
kraken2 <- read.table("taxonomy/kraken2/bracken_genus_combined.txt",
                      header=TRUE, sep="\t", row.names=1, check.names=FALSE)
motus <- read.table("taxonomy/motus/merged_profiles.txt",
                    header=TRUE, sep="\t", row.names=1, skip=2, check.names=FALSE)

cat("Normalizing data to relative abundances...\n")

# Normalize to relative abundance (%)
kaiju_norm <- sweep(kaiju, 2, colSums(kaiju), "/") * 100
kraken2_norm <- sweep(kraken2, 2, colSums(kraken2), "/") * 100
motus_norm <- sweep(motus, 2, colSums(motus), "/") * 100

# Get top 20 genera based on Kaiju results
top20 <- names(sort(rowSums(kaiju_norm), decreasing=TRUE)[1:20])

cat("Generating visualizations...\n")

# 1. Heatmap of top 20 genera (Kaiju)
cat("  Creating heatmap...\n")
pdf("taxonomy_comparison_heatmap.pdf", width=10, height=8)
pheatmap(as.matrix(kaiju_norm[top20,]),
         main = "Top 20 Genera - Kaiju",
         color = colorRampPalette(c("white", "yellow", "orange", "red"))(50),
         cluster_rows = TRUE,
         cluster_cols = TRUE,
         display_numbers = FALSE,
         fontsize = 10,
         fontsize_row = 8,
         fontsize_col = 8)
dev.off()

# 2. Stacked barplot - Kaiju
cat("  Creating stacked barplot...\n")
kaiju_long <- kaiju_norm[top20,] %>%
  as.data.frame() %>%
  tibble::rownames_to_column("Genus") %>%
  pivot_longer(-Genus, names_to="Sample", values_to="Abundance")

colors <- colorRampPalette(brewer.pal(12, "Set3"))(20)

p1 <- ggplot(kaiju_long, aes(x=Sample, y=Abundance, fill=Genus)) +
  geom_bar(stat="identity", position="stack") +
  scale_fill_manual(values=colors) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle=45, hjust=1, size=10),
        axis.text.y = element_text(size=10),
        legend.text = element_text(size=8),
        legend.title = element_text(size=10, face="bold"),
        plot.title = element_text(size=14, face="bold")) +
  labs(title="Taxonomic Composition - Kaiju (Top 20 Genera)",
       x="Sample", 
       y="Relative Abundance (%)",
       fill="Genus")

ggsave("taxonomy_barplot_kaiju.pdf", plot=p1, width=12, height=7)

# 3. Comparison of total genera detected
cat("  Creating tool comparison plot...\n")
comparison_data <- data.frame(
  Tool = c("Kaiju", "Kraken2", "mOTUs"),
  Genera_Detected = c(nrow(kaiju_norm[rowSums(kaiju_norm) > 0,]),
                      nrow(kraken2_norm[rowSums(kraken2_norm) > 0,]),
                      nrow(motus_norm[rowSums(motus_norm) > 0,]))
)

p2 <- ggplot(comparison_data, aes(x=Tool, y=Genera_Detected, fill=Tool)) +
  geom_bar(stat="identity") +
  geom_text(aes(label=Genera_Detected), vjust=-0.5, size=5) +
  scale_fill_brewer(palette="Set2") +
  theme_minimal() +
  theme(legend.position="none",
        axis.text = element_text(size=12),
        axis.title = element_text(size=14, face="bold"),
        plot.title = element_text(size=16, face="bold")) +
  labs(title="Total Genera Detected by Each Tool",
       x="Tool",
       y="Number of Genera")

ggsave("tool_comparison_genera.pdf", plot=p2, width=8, height=6)

# 4. Correlation between tools
cat("  Creating correlation plot...\n")
shared_samples <- intersect(colnames(kaiju_norm), colnames(kraken2_norm))
if(length(shared_samples) > 0) {
  shared_genera <- intersect(rownames(kaiju_norm), rownames(kraken2_norm))
  
  if(length(shared_genera) > 10) {
    kaiju_subset <- kaiju_norm[shared_genera, shared_samples]
    kraken2_subset <- kraken2_norm[shared_genera, shared_samples]
    
    cor_data <- data.frame(
      Kaiju = as.vector(as.matrix(kaiju_subset)),
      Kraken2 = as.vector(as.matrix(kraken2_subset))
    )
    
    p3 <- ggplot(cor_data, aes(x=Kaiju, y=Kraken2)) +
      geom_point(alpha=0.5, size=2) +
      geom_smooth(method="lm", color="red", se=TRUE) +
      theme_minimal() +
      labs(title=sprintf("Correlation: Kaiju vs Kraken2 (R = %.3f)", 
                        cor(cor_data$Kaiju, cor_data$Kraken2)),
           x="Kaiju Abundance (%)",
           y="Kraken2 Abundance (%)") +
      theme(plot.title = element_text(size=14, face="bold"))
    
    ggsave("correlation_kaiju_kraken2.pdf", plot=p3, width=8, height=6)
  }
}

# 5. Diversity metrics
cat("  Calculating diversity metrics...\n")
shannon_diversity <- function(x) {
  x <- x[x > 0]
  -sum((x/sum(x)) * log(x/sum(x)))
}

diversity_results <- data.frame(
  Sample = colnames(kaiju_norm),
  Shannon_Kaiju = apply(kaiju_norm, 2, shannon_diversity),
  Richness_Kaiju = apply(kaiju_norm > 0, 2, sum)
)

write.csv(diversity_results, "diversity_metrics.csv", row.names=FALSE)

# 6. Summary statistics
cat("  Generating summary statistics...\n")
summary_stats <- data.frame(
  Tool = c("Kaiju", "Kraken2", "mOTUs"),
  Total_Genera = c(nrow(kaiju_norm), nrow(kraken2_norm), nrow(motus_norm)),
  Detected_Genera = c(sum(rowSums(kaiju_norm) > 0),
                      sum(rowSums(kraken2_norm) > 0),
                      sum(rowSums(motus_norm) > 0))
)

write.csv(summary_stats, "taxonomy_summary_statistics.csv", row.names=FALSE)

cat("\nVisualization complete!\n")
cat("Generated files:\n")
cat("  - taxonomy_comparison_heatmap.pdf\n")
cat("  - taxonomy_barplot_kaiju.pdf\n")
cat("  - tool_comparison_genera.pdf\n")
cat("  - correlation_kaiju_kraken2.pdf\n")
cat("  - diversity_metrics.csv\n")
cat("  - taxonomy_summary_statistics.csv\n")

EOF

echo "Taxonomic visualization complete!"
