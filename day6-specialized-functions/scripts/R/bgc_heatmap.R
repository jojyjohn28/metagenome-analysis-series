#!/usr/bin/env Rscript
# bgc_heatmap.R
# Visualize antiSMASH BGC distributions across genomes
# Input: BGC counts per genome (from antiSMASH)
# Output: Clustered heatmap showing BGC patterns

# Load libraries
library(pheatmap)
library(reshape2)
library(RColorBrewer)

# ============================================================
# TOY DATA - Replace with your antiSMASH results
# ============================================================

# Create toy dataset: BGC types across 15 genomes
toy_data <- data.frame(
  Genome = c("Genome_1", "Genome_2", "Genome_3", "Genome_4", "Genome_5",
             "Genome_6", "Genome_7", "Genome_8", "Genome_9", "Genome_10",
             "Genome_11", "Genome_12", "Genome_13", "Genome_14", "Genome_15"),
  NRPS = c(3, 5, 2, 4, 3, 6, 2, 3, 4, 5, 2, 3, 4, 5, 3),
  PKS = c(2, 3, 4, 2, 3, 5, 3, 2, 3, 4, 2, 3, 2, 4, 3),
  Terpene = c(1, 2, 1, 3, 2, 4, 1, 2, 3, 2, 1, 2, 3, 2, 1),
  Bacteriocin = c(4, 3, 5, 3, 4, 2, 5, 4, 3, 2, 4, 5, 3, 2, 4),
  Siderophore = c(2, 1, 2, 1, 3, 1, 2, 3, 1, 2, 3, 2, 1, 3, 2),
  RiPP = c(1, 2, 1, 2, 1, 3, 2, 1, 2, 3, 1, 2, 1, 2, 1),
  "T1PKS" = c(0, 1, 0, 1, 2, 1, 0, 1, 1, 2, 0, 1, 1, 0, 1),
  "T3PKS" = c(1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1),
  Hybrid = c(2, 3, 2, 4, 3, 5, 2, 3, 4, 3, 2, 3, 4, 5, 3)
)

# ============================================================
# TO USE YOUR OWN DATA:
# ============================================================
# Replace toy_data with:
# library(readxl)
# bgc_data <- read_excel("path/to/antismash_bgc_summary.xlsx")
# OR
# bgc_data <- read.csv("path/to/antismash_bgc_summary.csv")

# ============================================================
# PREPARE DATA
# ============================================================

# Set genome names as row names
rownames(toy_data) <- toy_data$Genome
toy_data <- toy_data[, -1]  # Remove Genome column

# Convert to matrix
data_matrix <- as.matrix(toy_data)

# Optional: Log-transform (comment out if not needed)
# data_matrix_log <- log10(data_matrix + 1)

# ============================================================
# HEATMAP 1: Basic clustered heatmap
# ============================================================

pdf("bgc_heatmap_basic.pdf", width = 10, height = 8)
pheatmap(
  data_matrix,
  scale = "row",
  clustering_distance_rows = "euclidean",
  clustering_method = "complete",
  main = "BGC Distribution Across Genomes",
  fontsize_row = 10,
  fontsize_col = 12
)
dev.off()

cat("✓ Created: bgc_heatmap_basic.pdf\n")

# ============================================================
# HEATMAP 2: Custom colors
# ============================================================

pdf("bgc_heatmap_custom.pdf", width = 10, height = 8)
pheatmap(
  data_matrix,
  scale = "row",
  clustering_distance_rows = "euclidean",
  clustering_method = "complete",
  color = colorRampPalette(c("white", "gold", "red3", "purple4"))(100),
  main = "BGC Distribution (Custom Colors)",
  fontsize_row = 10,
  fontsize_col = 12,
  border_color = "grey60"
)
dev.off()

cat("✓ Created: bgc_heatmap_custom.pdf\n")

# ============================================================
# HEATMAP 3: With annotations
# ============================================================

# Create annotation for genomes (example: group by BGC richness)
total_bgcs <- rowSums(data_matrix)
annotation_row <- data.frame(
  Total_BGCs = cut(total_bgcs, 
                   breaks = c(0, 15, 25, 50),
                   labels = c("Low", "Medium", "High"))
)
rownames(annotation_row) <- rownames(data_matrix)

# Annotation colors
ann_colors <- list(
  Total_BGCs = c(Low = "#3498db", Medium = "#f39c12", High = "#e74c3c")
)

pdf("bgc_heatmap_annotated.pdf", width = 11, height = 8)
pheatmap(
  data_matrix,
  scale = "row",
  clustering_distance_rows = "euclidean",
  clustering_method = "complete",
  annotation_row = annotation_row,
  annotation_colors = ann_colors,
  color = colorRampPalette(c("white", "yellow", "orange", "red", "darkred"))(100),
  main = "BGC Distribution with Annotations",
  fontsize_row = 10,
  fontsize_col = 12
)
dev.off()

cat("✓ Created: bgc_heatmap_annotated.pdf\n")

# ============================================================
# SUMMARY STATISTICS
# ============================================================

cat("\n========================================\n")
cat("  BGC Summary Statistics\n")
cat("========================================\n")
cat(sprintf("Total genomes: %d\n", nrow(data_matrix)))
cat(sprintf("BGC types: %d\n", ncol(data_matrix)))
cat(sprintf("\nBGCs per genome:\n"))
cat(sprintf("  Mean: %.1f\n", mean(rowSums(data_matrix))))
cat(sprintf("  Median: %.1f\n", median(rowSums(data_matrix))))
cat(sprintf("  Range: %d - %d\n", min(rowSums(data_matrix)), max(rowSums(data_matrix))))

cat(sprintf("\nMost common BGC types:\n"))
bgc_totals <- colSums(data_matrix)
bgc_sorted <- sort(bgc_totals, decreasing = TRUE)
for (i in 1:min(5, length(bgc_sorted))) {
  cat(sprintf("  %s: %d\n", names(bgc_sorted)[i], bgc_sorted[i]))
}

# Save summary
write.csv(data.frame(Genome = rownames(data_matrix), 
                     Total_BGCs = rowSums(data_matrix),
                     data_matrix),
          "bgc_summary.csv", row.names = FALSE)

cat("\n✓ Saved: bgc_summary.csv\n")
cat("========================================\n")

# ============================================================
# USAGE NOTES
# ============================================================
# 
# To use with your antiSMASH data:
# 1. Parse antiSMASH JSON output to create a table:
#    Rows = Genomes, Columns = BGC types, Values = Counts
# 
# 2. Load your data:
#    bgc_data <- read.csv("your_bgc_table.csv")
# 
# 3. Run this script:
#    Rscript bgc_heatmap.R
#
# Output files:
#   - bgc_heatmap_basic.pdf (simple clustered heatmap)
#   - bgc_heatmap_custom.pdf (custom color scheme)
#   - bgc_heatmap_annotated.pdf (with row annotations)
#   - bgc_summary.csv (summary statistics)
