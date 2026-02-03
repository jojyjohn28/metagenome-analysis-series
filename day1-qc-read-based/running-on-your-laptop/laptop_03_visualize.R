#!/usr/bin/env Rscript
#
# Script: laptop_03_visualize.R
# Description: Simple visualization for laptop metagenome analysis
# Author: github.com/jojyjohn28
# Usage: Rscript laptop_03_visualize.R

cat("========================================\n")
cat("  Taxonomic Visualization\n")
cat("========================================\n\n")

# Install packages if needed
cat("Checking required packages...\n")
packages <- c("ggplot2", "dplyr", "tidyr", "RColorBrewer")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste0("Installing ", pkg, "...\n"))
    install.packages(pkg, repos = "https://cloud.r-project.org/", quiet = TRUE)
    library(pkg, character.only = TRUE)
  }
}
cat("✓ All packages loaded\n\n")

# Read MetaPhlAn output
cat("Reading taxonomic data...\n")
data_file <- "results/taxonomy/metaphlan/merged_species.txt"

if (!file.exists(data_file)) {
  cat("ERROR: File not found:", data_file, "\n")
  cat("Make sure you've run laptop_02_taxonomy.sh first!\n")
  quit(status = 1)
}

data <- read.table(data_file,
                   header = TRUE, 
                   sep = "\t", 
                   row.names = 1,
                   comment.char = "", 
                   check.names = FALSE)

cat("✓ Data loaded:", nrow(data), "species,", ncol(data), "samples\n\n")

# Clean species names (remove taxonomic prefixes)
rownames(data) <- gsub(".*s__", "", rownames(data))
rownames(data) <- gsub("_", " ", rownames(data))

# Get top 15 species by total abundance
cat("Selecting top 15 most abundant species...\n")
top_n <- min(15, nrow(data))
top_species <- names(sort(rowSums(data), decreasing = TRUE)[1:top_n])

# Group remaining as "Other"
data_plot <- data
data_plot["Other",] <- colSums(data[!rownames(data) %in% top_species, , drop=FALSE])
data_plot <- data_plot[c(top_species, "Other"),]

cat("✓ Top", top_n, "species selected\n\n")

# Prepare data for plotting
library(dplyr)
library(tidyr)

plot_data <- data_plot %>%
  as.data.frame() %>%
  tibble::rownames_to_column("Species") %>%
  pivot_longer(-Species, names_to = "Sample", values_to = "Abundance") %>%
  mutate(Species = factor(Species, levels = rev(c(top_species, "Other"))))

# Create color palette
library(RColorBrewer)
if (top_n + 1 <= 12) {
  colors <- brewer.pal(max(3, top_n + 1), "Set3")
} else {
  colors <- colorRampPalette(brewer.pal(12, "Set3"))(top_n + 1)
}

# Create stacked barplot
cat("Creating visualization...\n")
library(ggplot2)

p <- ggplot(plot_data, aes(x = Sample, y = Abundance, fill = Species)) +
  geom_bar(stat = "identity", position = "stack", color = "white", size = 0.3) +
  scale_fill_manual(values = colors) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 9),
    legend.title = element_text(size = 11, face = "bold"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    panel.grid.minor = element_blank()
  ) +
  labs(
    title = "Taxonomic Composition",
    subtitle = paste0("Top ", top_n, " Most Abundant Species"),
    x = "Sample",
    y = "Relative Abundance (%)",
    fill = "Species"
  ) +
  guides(fill = guide_legend(reverse = TRUE, ncol = 1))

# Save plot
cat("Saving plots...\n")
ggsave("results/taxonomy_barplot.pdf", plot = p, width = 10, height = 7)
ggsave("results/taxonomy_barplot.png", plot = p, width = 10, height = 7, dpi = 300)

cat("✓ Plots saved\n\n")

# Create simple summary table
cat("Generating summary statistics...\n")
summary_stats <- data.frame(
  Sample = colnames(data),
  Total_Species = colSums(data > 0),
  Shannon_Diversity = apply(data, 2, function(x) {
    x <- x[x > 0]
    -sum((x/sum(x)) * log(x/sum(x)))
  }),
  Top_Species = apply(data, 2, function(x) {
    rownames(data)[which.max(x)]
  }),
  Top_Abundance = apply(data, 2, max)
)

write.csv(summary_stats, "results/taxonomy_summary.csv", row.names = FALSE)
cat("✓ Summary table saved\n\n")

# Print summary to console
cat("========================================\n")
cat("  Analysis Complete!\n")
cat("========================================\n\n")

cat("Summary Statistics:\n")
cat("------------------\n")
for (i in 1:nrow(summary_stats)) {
  cat(sprintf("%s:\n", summary_stats$Sample[i]))
  cat(sprintf("  Species detected: %d\n", summary_stats$Total_Species[i]))
  cat(sprintf("  Shannon diversity: %.2f\n", summary_stats$Shannon_Diversity[i]))
  cat(sprintf("  Most abundant: %s (%.1f%%)\n\n", 
              summary_stats$Top_Species[i],
              summary_stats$Top_Abundance[i]))
}

cat("\nFiles created:\n")
cat("  1. results/taxonomy_barplot.pdf\n")
cat("  2. results/taxonomy_barplot.png\n")
cat("  3. results/taxonomy_summary.csv\n\n")

cat("View your results:\n")
cat("  - Open: results/taxonomy_barplot.pdf\n")
cat("  - Or: results/taxonomy_barplot.png\n\n")

cat("🎉 All done! 🎉\n\n")
