#!/usr/bin/env Rscript
#
# Script: 02_assembly_visualization.R
# Description: Visualize assembly statistics and comparisons
# Author: github.com/jojyjohn28
# Usage: Rscript 02_assembly_visualization.R metaquast_stats.csv detailed_stats.csv output_dir

# Load required libraries
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(RColorBrewer)
  library(scales)
})

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  cat("Usage: Rscript 02_assembly_visualization.R <metaquast_stats.csv> <detailed_stats.csv> <output_dir>\n")
  quit(status = 1)
}

metaquast_file <- args[1]
detailed_file <- args[2]
output_dir <- args[3]

cat("="*70, "\n")
cat("  Assembly Visualization\n")
cat("="*70, "\n\n")
cat("MetaQUAST stats:", metaquast_file, "\n")
cat("Detailed stats:", detailed_file, "\n")
cat("Output directory:", output_dir, "\n\n")

# Create output directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Read data
metaquast_data <- read.csv(metaquast_file, stringsAsFactors = FALSE)
detailed_data <- read.csv(detailed_file, stringsAsFactors = FALSE)

cat("Loaded", nrow(metaquast_data), "MetaQUAST results\n")
cat("Loaded", nrow(detailed_data), "detailed statistics\n\n")

# ============================================================================
# 1. N50 Comparison Plot
# ============================================================================
cat("[1/6] Creating N50 comparison plot...\n")

p1 <- ggplot(metaquast_data, aes(x = reorder(sample, -n50), y = n50, fill = assembler)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", size = 0.3) +
  scale_fill_brewer(palette = "Set2") +
  scale_y_continuous(labels = comma) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "top",
    legend.title = element_text(face = "bold"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "N50 Comparison Across Samples and Assemblers",
    x = "Sample",
    y = "N50 (bp)",
    fill = "Assembler"
  )

ggsave(file.path(output_dir, "n50_comparison.pdf"), plot = p1, width = 10, height = 6)
ggsave(file.path(output_dir, "n50_comparison.png"), plot = p1, width = 10, height = 6, dpi = 300)

# ============================================================================
# 2. Contig Length Distribution
# ============================================================================
cat("[2/6] Creating contig length distribution...\n")

# Prepare data for distribution plot
dist_data <- detailed_data %>%
  select(sample, contigs_500bp, contigs_1kb, contigs_5kb, contigs_10kb, contigs_50kb, contigs_100kb) %>%
  pivot_longer(cols = starts_with("contigs_"), names_to = "size_category", values_to = "count") %>%
  mutate(
    size_category = factor(size_category,
                          levels = c("contigs_500bp", "contigs_1kb", "contigs_5kb", 
                                    "contigs_10kb", "contigs_50kb", "contigs_100kb"),
                          labels = c("≥500bp", "≥1kb", "≥5kb", "≥10kb", "≥50kb", "≥100kb"))
  )

p2 <- ggplot(dist_data, aes(x = size_category, y = count, fill = sample)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", size = 0.3) +
  scale_fill_brewer(palette = "Set3") +
  scale_y_continuous(labels = comma) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 0, size = 11),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "Contig Length Distribution",
    x = "Minimum Contig Length",
    y = "Number of Contigs",
    fill = "Sample"
  )

ggsave(file.path(output_dir, "contig_distribution.pdf"), plot = p2, width = 12, height = 6)
ggsave(file.path(output_dir, "contig_distribution.png"), plot = p2, width = 12, height = 6, dpi = 300)

# ============================================================================
# 3. GC Content Analysis
# ============================================================================
cat("[3/6] Creating GC content analysis...\n")

p3 <- ggplot(detailed_data, aes(x = sample, y = mean_gc)) +
  geom_point(size = 4, color = "#2E86C1") +
  geom_errorbar(aes(ymin = mean_gc - stdev_gc, ymax = mean_gc + stdev_gc), 
                width = 0.2, color = "#2E86C1") +
  geom_hline(yintercept = mean(detailed_data$mean_gc), 
             linetype = "dashed", color = "red", size = 1) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "GC Content Distribution Across Samples",
    subtitle = paste0("Red dashed line: Overall mean (", 
                     round(mean(detailed_data$mean_gc), 2), "%)"),
    x = "Sample",
    y = "Mean GC Content (%)"
  ) +
  ylim(min(detailed_data$mean_gc - detailed_data$stdev_gc) - 5,
       max(detailed_data$mean_gc + detailed_data$stdev_gc) + 5)

ggsave(file.path(output_dir, "gc_content.pdf"), plot = p3, width = 10, height = 6)
ggsave(file.path(output_dir, "gc_content.png"), plot = p3, width = 10, height = 6, dpi = 300)

# ============================================================================
# 4. Assembly Quality Heatmap
# ============================================================================
cat("[4/6] Creating assembly quality heatmap...\n")

# Normalize metrics for heatmap (0-100 scale)
heatmap_data <- metaquast_data %>%
  mutate(
    n50_score = (n50 / max(n50)) * 100,
    length_score = (total_length / max(total_length)) * 100,
    contig_score = (1 - (total_contigs / max(total_contigs))) * 100,  # Inverse: fewer is better
    largest_score = (largest_contig / max(largest_contig)) * 100
  ) %>%
  select(sample, assembler, n50_score, length_score, contig_score, largest_score) %>%
  pivot_longer(cols = ends_with("_score"), names_to = "metric", values_to = "score") %>%
  mutate(
    metric = factor(metric,
                   levels = c("n50_score", "largest_score", "length_score", "contig_score"),
                   labels = c("N50", "Largest Contig", "Total Length", "Contig Count"))
  )

p4 <- ggplot(heatmap_data, aes(x = metric, y = paste(sample, assembler, sep = "_"), fill = score)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradient2(low = "#D32F2F", mid = "#FFF59D", high = "#388E3C",
                      midpoint = 50, limits = c(0, 100)) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 0, size = 11, face = "bold"),
    axis.text.y = element_text(size = 10),
    axis.title = element_blank(),
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "Assembly Quality Heatmap",
    subtitle = "Normalized scores (0-100)",
    fill = "Score"
  )

ggsave(file.path(output_dir, "quality_heatmap.pdf"), plot = p4, width = 8, height = 6)
ggsave(file.path(output_dir, "quality_heatmap.png"), plot = p4, width = 8, height = 6, dpi = 300)

# ============================================================================
# 5. Total Length vs Number of Contigs
# ============================================================================
cat("[5/6] Creating length vs contigs scatter plot...\n")

p5 <- ggplot(metaquast_data, aes(x = total_contigs, y = total_length, 
                                 color = assembler, size = n50)) +
  geom_point(alpha = 0.7) +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  scale_size_continuous(labels = comma, range = c(3, 10)) +
  scale_color_brewer(palette = "Set1") +
  theme_minimal() +
  theme(
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "Assembly Length vs Contig Count",
    subtitle = "Point size represents N50",
    x = "Number of Contigs",
    y = "Total Assembly Length (bp)",
    color = "Assembler",
    size = "N50 (bp)"
  )

ggsave(file.path(output_dir, "length_vs_contigs.pdf"), plot = p5, width = 10, height = 7)
ggsave(file.path(output_dir, "length_vs_contigs.png"), plot = p5, width = 10, height = 7, dpi = 300)

# ============================================================================
# 6. Assembly Efficiency Plot
# ============================================================================
cat("[6/6] Creating assembly efficiency plot...\n")

efficiency_data <- detailed_data %>%
  select(sample, percent_in_1kb, percent_in_10kb) %>%
  pivot_longer(cols = starts_with("percent_"), names_to = "category", values_to = "percent") %>%
  mutate(
    category = factor(category,
                     levels = c("percent_in_1kb", "percent_in_10kb"),
                     labels = c("Bases in ≥1kb contigs", "Bases in ≥10kb contigs"))
  )

p6 <- ggplot(efficiency_data, aes(x = sample, y = percent, fill = category)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", size = 0.3) +
  scale_fill_manual(values = c("#66C2A5", "#FC8D62")) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "top",
    legend.title = element_blank(),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "Assembly Efficiency",
    subtitle = "Percentage of bases in longer contigs",
    x = "Sample",
    y = "Percentage of Total Bases (%)"
  ) +
  ylim(0, 100)

ggsave(file.path(output_dir, "assembly_efficiency.pdf"), plot = p6, width = 10, height = 6)
ggsave(file.path(output_dir, "assembly_efficiency.png"), plot = p6, width = 10, height = 6, dpi = 300)

# ============================================================================
# Summary Statistics
# ============================================================================
cat("\n" + "="*70 + "\n")
cat("  Visualization Complete!\n")
cat("="*70 + "\n\n")

cat("Generated plots:\n")
cat("  1. n50_comparison.pdf/png\n")
cat("  2. contig_distribution.pdf/png\n")
cat("  3. gc_content.pdf/png\n")
cat("  4. quality_heatmap.pdf/png\n")
cat("  5. length_vs_contigs.pdf/png\n")
cat("  6. assembly_efficiency.pdf/png\n\n")

cat("Summary Statistics:\n")
cat(sprintf("  Samples analyzed: %d\n", length(unique(metaquast_data$sample))))
cat(sprintf("  Assemblers compared: %d\n", length(unique(metaquast_data$assembler))))
cat(sprintf("  Mean N50: %s bp\n", format(mean(metaquast_data$n50), big.mark=",")))
cat(sprintf("  Best N50: %s bp\n", format(max(metaquast_data$n50), big.mark=",")))
cat(sprintf("  Mean GC%%: %.2f%%\n", mean(detailed_data$mean_gc)))

cat("\n✓ All visualizations saved to:", output_dir, "\n\n")
