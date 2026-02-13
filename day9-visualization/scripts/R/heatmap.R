# ------------------------------------------------------------
# TOY MAG ABUNDANCE HEATMAP (clustered)
#    Rows = MAGs, Cols = Samples, Values = abundance
# ------------------------------------------------------------
library(tidyverse)
library(pheatmap)
library(vegan)
library(GGally)
library(plotly)


n_mags <- 30
mag_ids <- sprintf("MAG_%02d", 1:n_mags)

samples2 <- c(
  "Spring_Low_FL","Spring_Med_FL","Spring_High_FL",
  "Spring_Low_PA","Spring_Med_PA","Spring_High_PA",
  "Summer_Low_FL","Summer_Med_FL","Summer_High_FL",
  "Summer_Low_PA","Summer_Med_PA","Summer_High_PA"
)

abund <- matrix(rgamma(n_mags*length(samples2), shape=2, scale=50),
                nrow=n_mags, dimnames=list(mag_ids, samples2))

# Add structure: first 10 enriched in FL, next 10 enriched in PA
abund[1:10, 1:6] <- abund[1:10, 1:6] * 2
abund[11:20, 7:12] <- abund[11:20, 7:12] * 2

abundance <- as.data.frame(abund)
abundance_log <- log10(abundance + 1)

pheatmap(as.matrix(abundance_log),
         clustering_distance_rows = "euclidean",
         clustering_distance_cols = "euclidean",
         clustering_method = "complete",
         border_color = "grey70",
         show_rownames = FALSE,
         main = "Clustered MAG Abundance Heatmap (Toy Data)")

# Save heatmap (base device)
#pdf("mag_heatmap_clustered_toy.pdf", width=10, height=9)
#pheatmap(as.matrix(abundance_log),
         clustering_distance_rows = "euclidean",
         clustering_distance_cols = "euclidean",
         clustering_method = "complete",
         border_color = "grey70",
         show_rownames = FALSE,
         main = "Clustered MAG Abundance Heatmap (Toy Data)")
dev.off()
