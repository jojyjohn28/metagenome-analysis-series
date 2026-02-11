#!/usr/bin/env Rscript
# cazyme_bubble_plot.R
# Visualize CAZyme family distributions across genomes
# Input: CAZyme counts from dbCAN
# Output: Bubble plot showing CAZyme patterns and genome quality

# Load libraries
library(ggplot2)
library(reshape2)

# ============================================================
# TOY DATA - Replace with your dbCAN results
# ============================================================

# Create toy dataset: CAZyme families across taxonomic orders
toy_data <- data.frame(
  Order = c("Pseudomonadales", "Enterobacterales", "Bacillales", "Burkholderiales",
            "Rhizobiales", "Actinomycetales", "Lactobacillales", "Clostridiales",
            "Sphingomonadales", "Xanthomonadales", "Flavobacteriales", "Caulobacterales"),
  Average_completion = c(95.3, 92.1, 88.5, 94.2, 91.8, 96.5, 89.3, 87.4, 93.1, 90.2, 85.6, 94.8),
  GH = c(45, 52, 38, 41, 36, 58, 33, 42, 39, 47, 31, 38),
  GT = c(32, 38, 28, 35, 30, 42, 26, 31, 29, 36, 24, 32),
  PL = c(8, 12, 6, 10, 7, 15, 5, 9, 8, 11, 4, 7),
  CE = c(15, 18, 12, 16, 13, 22, 10, 14, 13, 17, 9, 14),
  AA = c(5, 7, 4, 6, 5, 9, 3, 5, 4, 6, 3, 5),
  CBM = c(12, 15, 10, 13, 11, 18, 8, 12, 11, 14, 7, 11)
)

# ============================================================
# TO USE YOUR OWN DATA:
# ============================================================
# library(readxl)
# cazyme_data <- read_excel("path/to/dbcan_summary.xlsx")
# OR
# cazyme_data <- read.csv("path/to/dbcan_summary.csv")

# ============================================================
# PREPARE DATA FOR BUBBLE PLOT
# ============================================================

# Melt data to long format
table_m <- melt(toy_data, id.vars = c("Order", "Average_completion"))
colnames(table_m) <- c("Order", "Completion", "CAZyme_Family", "Count")

# Keep order from original data
table_m$Order <- factor(table_m$Order, levels = unique(table_m$Order))

# ============================================================
# BUBBLE PLOT 1: Basic
# ============================================================

p1 <- ggplot(table_m, aes(x = Order, y = CAZyme_Family)) +
  geom_point(aes(size = Count, color = Completion), alpha = 0.75, shape = 19) +
  scale_size_continuous(limits = c(min(table_m$Count), max(table_m$Count)),
                        range = c(4, 20),
                        breaks = c(10, 30, 50)) +
  labs(x = "", y = "", 
       size = "CAZyme\nCount",
       color = "Genome\nCompletion (%)") +
  theme(
    legend.key = element_blank(),
    axis.text.x = element_text(colour = "black", size = 12, face = "bold",
                               angle = 45, vjust = 1, hjust = 1),
    axis.text.y = element_text(colour = "black", face = "bold", size = 11),
    legend.text = element_text(size = 10, face = "bold", colour = "black"),
    legend.title = element_text(size = 12, face = "bold"),
    panel.background = element_blank(),
    panel.border = element_rect(colour = "black", fill = NA, size = 1.2),
    legend.position = "right",
    panel.grid.major = element_line(colour = "grey95")
  ) +
  scale_color_gradientn(colours = c("steelblue4", "antiquewhite2", "red4")) +
  scale_y_discrete(limits = rev(levels(table_m$CAZyme_Family)))

ggsave("cazyme_bubble_plot.pdf", p1, width = 12, height = 8)
cat("✓ Created: cazyme_bubble_plot.pdf\n")

# ============================================================
# BUBBLE PLOT 2: Alternative color scheme
# ============================================================

p2 <- ggplot(table_m, aes(x = Order, y = CAZyme_Family)) +
  geom_point(aes(size = Count, color = Completion), alpha = 0.8, shape = 19) +
  scale_size_continuous(limits = c(min(table_m$Count), max(table_m$Count)),
                        range = c(4, 20)) +
  labs(x = "", y = "",
       size = "Number of\nCAZymes",
       color = "Genome\nCompleteness (%)") +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(colour = "black", angle = 45, vjust = 1, hjust = 1),
    axis.text.y = element_text(colour = "black"),
    legend.text = element_text(colour = "black"),
    panel.background = element_blank(),
    panel.border = element_rect(colour = "black", fill = NA, size = 1.2),
    panel.grid.major = element_line(colour = "grey90")
  ) +
  scale_color_gradient(low = "yellow", high = "red3") +
  scale_y_discrete(limits = rev(levels(table_m$CAZyme_Family)))

ggsave("cazyme_bubble_plot_alt.pdf", p2, width = 12, height = 8)
cat("✓ Created: cazyme_bubble_plot_alt.pdf\n")

# ============================================================
# BAR PLOT: Total CAZymes per Order
# ============================================================

# Calculate totals
cazyme_totals <- toy_data
cazyme_totals$Total_CAZymes <- rowSums(cazyme_totals[, 3:ncol(cazyme_totals)])

p3 <- ggplot(cazyme_totals, aes(x = reorder(Order, Total_CAZymes), 
                                 y = Total_CAZymes,
                                 fill = Average_completion)) +
  geom_bar(stat = "identity", width = 0.7) +
  coord_flip() +
  scale_fill_gradient(low = "lightblue", high = "darkblue",
                      name = "Genome\nCompletion (%)") +
  labs(x = "", y = "Total CAZymes", title = "Total CAZyme Count by Order") +
  theme_minimal(base_size = 12) +
  theme(
    panel.border = element_rect(colour = "black", fill = NA, size = 1),
    axis.text = element_text(colour = "black")
  )

ggsave("cazyme_total_barplot.pdf", p3, width = 10, height = 8)
cat("✓ Created: cazyme_total_barplot.pdf\n")

# ============================================================
# HEATMAP: CAZyme families
# ============================================================

library(pheatmap)

# Prepare matrix
cazyme_matrix <- as.matrix(toy_data[, 3:ncol(toy_data)])
rownames(cazyme_matrix) <- toy_data$Order

pdf("cazyme_heatmap.pdf", width = 10, height = 8)
pheatmap(
  cazyme_matrix,
  scale = "column",
  clustering_distance_rows = "euclidean",
  clustering_method = "complete",
  color = colorRampPalette(c("white", "yellow", "orange", "red"))(100),
  main = "CAZyme Family Distribution",
  fontsize_row = 10,
  fontsize_col = 12,
  border_color = "grey60"
)
dev.off()

cat("✓ Created: cazyme_heatmap.pdf\n")

# ============================================================
# SUMMARY STATISTICS
# ============================================================

cat("\n========================================\n")
cat("  CAZyme Summary Statistics\n")
cat("========================================\n")

cat(sprintf("Total genomes analyzed: %d\n", nrow(toy_data)))
cat(sprintf("Average genome completion: %.1f%%\n", mean(toy_data$Average_completion)))

cat("\nCAZyme family totals:\n")
family_sums <- colSums(cazyme_matrix)
for (fam in names(sort(family_sums, decreasing = TRUE))) {
  cat(sprintf("  %s: %d (%.1f per genome)\n", 
              fam, family_sums[fam], family_sums[fam]/nrow(toy_data)))
}

cat("\nTop 5 orders by total CAZymes:\n")
top_orders <- cazyme_totals[order(-cazyme_totals$Total_CAZymes), ]
for (i in 1:min(5, nrow(top_orders))) {
  cat(sprintf("  %s: %d CAZymes (%.1f%% complete)\n",
              top_orders$Order[i],
              top_orders$Total_CAZymes[i],
              top_orders$Average_completion[i]))
}

# Save summary
write.csv(cazyme_totals, "cazyme_summary.csv", row.names = FALSE)
cat("\n✓ Saved: cazyme_summary.csv\n")
cat("========================================\n")

# ============================================================
# DEGRADATION CAPABILITY ANALYSIS
# ============================================================

cat("\nDegradation Capability Analysis:\n")

# Cellulose degradation potential (GH families)
cellulose_potential <- toy_data$GH
names(cellulose_potential) <- toy_data$Order
cat("\nCellulose degradation potential (GH count):\n")
top_cellulose <- sort(cellulose_potential, decreasing = TRUE)[1:5]
for (i in 1:length(top_cellulose)) {
  cat(sprintf("  %s: %d GH enzymes\n", names(top_cellulose)[i], top_cellulose[i]))
}

# Polysaccharide lyases (PL - breakdown of pectin, alginate, etc.)
pl_potential <- toy_data$PL
names(pl_potential) <- toy_data$Order
cat("\nPolysaccharide degradation (PL count):\n")
top_pl <- sort(pl_potential, decreasing = TRUE)[1:5]
for (i in 1:length(top_pl)) {
  cat(sprintf("  %s: %d PL enzymes\n", names(top_pl)[i], top_pl[i]))
}

cat("\n✓ Analysis complete!\n")

# ============================================================
# USAGE NOTES
# ============================================================
#
# To use with your dbCAN data:
# 1. Create a summary table with columns:
#    - Order (or Genus, Species)
#    - Average_completion (genome quality)
#    - GH, GT, PL, CE, AA, CBM (CAZyme family counts)
#
# 2. Load your data and run:
#    Rscript cazyme_bubble_plot.R
#
# Output files:
#   - cazyme_bubble_plot.pdf (main visualization)
#   - cazyme_bubble_plot_alt.pdf (alternative colors)
#   - cazyme_total_barplot.pdf (total counts)
#   - cazyme_heatmap.pdf (clustered heatmap)
#   - cazyme_summary.csv (summary statistics)
