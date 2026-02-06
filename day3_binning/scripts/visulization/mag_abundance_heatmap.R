#!/usr/bin/env Rscript

# MAG Abundance Heatmap
# Author: github.com/jojyjohn28
# Description: Create publication-quality heatmaps from CoverM abundance data
# Usage: Rscript mag_abundance_heatmap.R --input mag_abundance_table.tsv --output figures/

# Load required libraries
suppressPackageStartupMessages({
  library(optparse)
  library(tidyverse)
  library(pheatmap)
  library(RColorBrewer)
  library(viridis)
})

# Parse command line arguments
option_list <- list(
  make_option(c("-i", "--input"), type="character", default=NULL,
              help="CoverM abundance table (TSV format)", metavar="FILE"),
  make_option(c("-o", "--output"), type="character", default="figures",
              help="Output directory [default= %default]", metavar="DIR"),
  make_option(c("--top-n"), type="integer", default=20,
              help="Number of top MAGs to display [default= %default]"),
  make_option(c("--min-abundance"), type="numeric", default=0.1,
              help="Minimum abundance threshold (%) [default= %default]"),
  make_option(c("--cluster-mags"), action="store_true", default=TRUE,
              help="Cluster MAGs by similarity [default= %default]"),
  make_option(c("--cluster-samples"), action="store_true", default=TRUE,
              help="Cluster samples by similarity [default= %default]")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Check required arguments
if (is.null(opt$input)) {
  print_help(opt_parser)
  stop("Input file must be specified (--input)", call.=FALSE)
}

cat("=======================================================================\n")
cat("  MAG Abundance Heatmap (R)\n")
cat("=======================================================================\n")
cat(sprintf("Input file: %s\n", opt$input))
cat(sprintf("Output directory: %s\n", opt$output))
cat(sprintf("Top N MAGs: %d\n", opt$`top-n`))
cat(sprintf("Minimum abundance: %.2f%%\n", opt$`min-abundance`))
cat("\n")

# Create output directory
dir.create(opt$output, showWarnings = FALSE, recursive = TRUE)

# Load data
cat("Loading abundance data...\n")
abundance_data <- read.table(opt$input, header = TRUE, sep = "\t", 
                             row.names = 1, check.names = FALSE)

# Extract relative abundance columns
ra_cols <- grep("Relative Abundance", colnames(abundance_data), value = TRUE)

if (length(ra_cols) == 0) {
  stop("No 'Relative Abundance' columns found in input file", call.=FALSE)
}

abundance_matrix <- as.matrix(abundance_data[, ra_cols])

# Clean column names (remove "Relative Abundance" text)
colnames(abundance_matrix) <- gsub(" Relative Abundance.*", "", colnames(abundance_matrix))

cat(sprintf("  Loaded %d MAGs across %d samples\n", nrow(abundance_matrix), 
            ncol(abundance_matrix)))
cat("\n")

# Filter low abundance MAGs
cat(sprintf("Filtering MAGs with max abundance < %.2f%%...\n", opt$`min-abundance`))
max_abundance <- apply(abundance_matrix, 1, max)
filtered_matrix <- abundance_matrix[max_abundance >= opt$`min-abundance`, ]
cat(sprintf("  Retained %d / %d MAGs\n", nrow(filtered_matrix), nrow(abundance_matrix)))
cat("\n")

# Select top N MAGs by mean abundance
cat(sprintf("Selecting top %d MAGs...\n", opt$`top-n`))
mean_abundance <- rowMeans(filtered_matrix)
top_indices <- order(mean_abundance, decreasing = TRUE)[1:min(opt$`top-n`, 
                                                               nrow(filtered_matrix))]
top_matrix <- filtered_matrix[top_indices, ]
cat(sprintf("  Selected %d MAGs\n", nrow(top_matrix)))
cat("\n")

# Print summary statistics
cat("Summary Statistics:\n")
cat(sprintf("  Mean abundance: %.2f%%\n", mean(as.vector(top_matrix))))
cat(sprintf("  Median abundance: %.2f%%\n", median(as.vector(top_matrix))))
cat(sprintf("  Max abundance: %.2f%%\n", max(as.vector(top_matrix))))
cat(sprintf("  Min abundance: %.2f%%\n", min(as.vector(top_matrix))))
cat("\n")

# Create heatmap 1: Basic heatmap with clustering
cat("Creating clustered heatmap...\n")
pdf(file.path(opt$output, "mag_abundance_heatmap_clustered.pdf"), 
    width = 12, height = 10)

pheatmap(top_matrix,
         color = colorRampPalette(rev(brewer.pal(n = 9, name = "YlOrRd")))(100),
         cluster_rows = opt$`cluster-mags`,
         cluster_cols = opt$`cluster-samples`,
         display_numbers = TRUE,
         number_format = "%.2f",
         fontsize_number = 8,
         main = sprintf("Top %d MAG Relative Abundance (%%)", opt$`top-n`),
         fontsize = 10,
         cellwidth = 40,
         cellheight = 20,
         border_color = "grey80",
         angle_col = 45)

dev.off()

png(file.path(opt$output, "mag_abundance_heatmap_clustered.png"), 
    width = 1200, height = 1000, res = 100)

pheatmap(top_matrix,
         color = colorRampPalette(rev(brewer.pal(n = 9, name = "YlOrRd")))(100),
         cluster_rows = opt$`cluster-mags`,
         cluster_cols = opt$`cluster-samples`,
         display_numbers = TRUE,
         number_format = "%.2f",
         fontsize_number = 8,
         main = sprintf("Top %d MAG Relative Abundance (%%)", opt$`top-n`),
         fontsize = 10,
         cellwidth = 40,
         cellheight = 20,
         border_color = "grey80",
         angle_col = 45)

dev.off()

cat("  ✓ Saved: mag_abundance_heatmap_clustered.pdf/png\n")

# Create heatmap 2: Ordered by abundance (no clustering)
cat("Creating ordered heatmap...\n")

# Order by mean abundance
ordered_matrix <- top_matrix[order(rowMeans(top_matrix), decreasing = TRUE), ]

pdf(file.path(opt$output, "mag_abundance_heatmap_ordered.pdf"), 
    width = 12, height = 10)

pheatmap(ordered_matrix,
         color = colorRampPalette(rev(brewer.pal(n = 9, name = "YlOrRd")))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         display_numbers = TRUE,
         number_format = "%.2f",
         fontsize_number = 8,
         main = sprintf("Top %d MAG Relative Abundance (%%) - Ordered", opt$`top-n`),
         fontsize = 10,
         cellwidth = 40,
         cellheight = 20,
         border_color = "grey80",
         angle_col = 45)

dev.off()

png(file.path(opt$output, "mag_abundance_heatmap_ordered.png"), 
    width = 1200, height = 1000, res = 100)

pheatmap(ordered_matrix,
         color = colorRampPalette(rev(brewer.pal(n = 9, name = "YlOrRd")))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         display_numbers = TRUE,
         number_format = "%.2f",
         fontsize_number = 8,
         main = sprintf("Top %d MAG Relative Abundance (%%) - Ordered", opt$`top-n`),
         fontsize = 10,
         cellwidth = 40,
         cellheight = 20,
         border_color = "grey80",
         angle_col = 45)

dev.off()

cat("  ✓ Saved: mag_abundance_heatmap_ordered.pdf/png\n")

# Create heatmap 3: Viridis color scheme
cat("Creating viridis heatmap...\n")

pdf(file.path(opt$output, "mag_abundance_heatmap_viridis.pdf"), 
    width = 12, height = 10)

pheatmap(top_matrix,
         color = viridis(100, option = "plasma"),
         cluster_rows = opt$`cluster-mags`,
         cluster_cols = opt$`cluster-samples`,
         display_numbers = TRUE,
         number_format = "%.2f",
         fontsize_number = 8,
         main = sprintf("Top %d MAG Relative Abundance (%%) - Viridis", opt$`top-n`),
         fontsize = 10,
         cellwidth = 40,
         cellheight = 20,
         border_color = "grey80",
         angle_col = 45)

dev.off()

png(file.path(opt$output, "mag_abundance_heatmap_viridis.png"), 
    width = 1200, height = 1000, res = 100)

pheatmap(top_matrix,
         color = viridis(100, option = "plasma"),
         cluster_rows = opt$`cluster-mags`,
         cluster_cols = opt$`cluster-samples`,
         display_numbers = TRUE,
         number_format = "%.2f",
         fontsize_number = 8,
         main = sprintf("Top %d MAG Relative Abundance (%%) - Viridis", opt$`top-n`),
         fontsize = 10,
         cellwidth = 40,
         cellheight = 20,
         border_color = "grey80",
         angle_col = 45)

dev.off()

cat("  ✓ Saved: mag_abundance_heatmap_viridis.pdf/png\n")

# Create correlation heatmap between samples
cat("Creating sample correlation heatmap...\n")

sample_cor <- cor(top_matrix)

pdf(file.path(opt$output, "sample_correlation_heatmap.pdf"), 
    width = 10, height = 8)

pheatmap(sample_cor,
         color = colorRampPalette(rev(brewer.pal(n = 11, name = "RdBu")))(100),
         cluster_rows = TRUE,
         cluster_cols = TRUE,
         display_numbers = TRUE,
         number_format = "%.3f",
         fontsize_number = 10,
         main = "Sample-to-Sample Correlation (Pearson)",
         fontsize = 12,
         breaks = seq(-1, 1, length.out = 101))

dev.off()

png(file.path(opt$output, "sample_correlation_heatmap.png"), 
    width = 1000, height = 800, res = 100)

pheatmap(sample_cor,
         color = colorRampPalette(rev(brewer.pal(n = 11, name = "RdBu")))(100),
         cluster_rows = TRUE,
         cluster_cols = TRUE,
         display_numbers = TRUE,
         number_format = "%.3f",
         fontsize_number = 10,
         main = "Sample-to-Sample Correlation (Pearson)",
         fontsize = 12,
         breaks = seq(-1, 1, length.out = 101))

dev.off()

cat("  ✓ Saved: sample_correlation_heatmap.pdf/png\n")

cat("\n")
cat("=======================================================================\n")
cat("  Heatmap Generation Complete!\n")
cat("=======================================================================\n")
cat(sprintf("\nOutput files saved to: %s\n", opt$output))
cat("  - mag_abundance_heatmap_clustered.pdf/png\n")
cat("  - mag_abundance_heatmap_ordered.pdf/png\n")
cat("  - mag_abundance_heatmap_viridis.pdf/png\n")
cat("  - sample_correlation_heatmap.pdf/png\n")
cat("\n✓ All heatmaps generated successfully!\n")
