# ------------------------------------------------------------
# 5) MAG–ENVIRONMENT CORRELATIONS HEATMAP
#    Correlate each MAG (across samples) with pH/Temp/Salinity
# ------------------------------------------------------------
library(tidyverse)
library(pheatmap)
library(vegan)
library(GGally)
library(plotly)

metadata <- tibble(
  Sample = samples2,
  Treatment = ifelse(str_detect(samples2, "_FL"), "FL", "PA"),
  pH = rnorm(length(samples2), 7.8, 0.3),
  Temperature = rnorm(length(samples2), 18, 3),
  Salinity = rnorm(length(samples2), 20, 7)
)

# Add signal so correlations exist
abundance_sig <- as.matrix(abundance)
abundance_sig[1:5, ]  <- abundance_sig[1:5, ]  + rep(metadata$Salinity, each=5) * 8
abundance_sig[6:10, ] <- abundance_sig[6:10, ] + rep(metadata$Temperature, each=5) * 10
abundance_sig[11:15,] <- abundance_sig[11:15,] + rep((8.5 - metadata$pH), each=5) * 120
abundance_sig <- as.data.frame(abundance_sig)
rownames(abundance_sig) <- mag_ids
colnames(abundance_sig) <- samples2

env_mat <- metadata %>% select(pH, Temperature, Salinity) %>% as.matrix()

corr_mat <- sapply(colnames(env_mat), function(v){
  apply(abundance_sig, 1, function(m) cor(m, env_mat[,v], method="pearson"))
})
corr_mat <- t(corr_mat)  # env rows
colnames(corr_mat) <- rownames(abundance_sig)

#pdf("mag_environment_correlations_toy.pdf", width=10, height=8)

pheatmap(corr_mat,
         cluster_rows = FALSE,
         cluster_cols = TRUE,
         main = "MAG–Environment Correlations (Toy Data)",
         border_color = "grey70")
dev.off()





