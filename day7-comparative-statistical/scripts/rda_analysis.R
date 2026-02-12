#!/usr/bin/env Rscript
# Distance-based Redundancy Analysis (db-RDA)
# Analyzes how environmental variables explain variation in microbial communities
# Author: Updated script with toy data
# Date: 2026-02-12

# Load required libraries
library(vegan)
library(ggplot2)
library(ggrepel)

# Set working directory and random seed for reproducibility
set.seed(123)

#==============================================================================
# SECTION 1: CREATE TOY DATA
#==============================================================================

# Create toy abundance data (20 MAGs across 34 samples)
# Rows = MAGs, Columns = Samples
n_mags <- 20
n_samples <- 34

# Generate realistic MAG abundance data
species <- matrix(
  rpois(n_mags * n_samples, lambda = 50),
  nrow = n_mags,
  ncol = n_samples
)

# Add MAG names
rownames(species) <- paste0("MAG_", 1:n_mags)
colnames(species) <- paste0("Sample_", 1:n_samples)

# Create toy metadata
metadata <- data.frame(
  Sample_ID = paste0("Sample_", 1:n_samples),
  Season = rep(c("Summer", "Spring", "Fall"), length.out = n_samples),
  Site = rep(c("A", "B", "C"), length.out = n_samples),
  
  # Environmental variables (continuous)
  Salinity = rnorm(n_samples, mean = 35, sd = 5),
  Temperature = rnorm(n_samples, mean = 20, sd = 8),
  pH = rnorm(n_samples, mean = 7.5, sd = 0.5),
  Silicate = rnorm(n_samples, mean = 10, sd = 3),
  Phosphate = rnorm(n_samples, mean = 2, sd = 0.5),
  Nitrate = rnorm(n_samples, mean = 5, sd = 2),
  Cells_mL = rnorm(n_samples, mean = 1e6, sd = 3e5),
  Bacterial_production = rnorm(n_samples, mean = 100, sd = 30),
  DOC = rnorm(n_samples, mean = 80, sd = 20),
  Chlorophyll = rnorm(n_samples, mean = 2, sd = 1)
)

rownames(metadata) <- metadata$Sample_ID

# Save toy data (optional - uncomment to save)
# write.csv(species, "toy_abundance_data.csv", row.names = TRUE)
# write.csv(metadata, "toy_metadata.csv", row.names = TRUE)

cat("Toy data created successfully!\n")
cat(paste("Abundance matrix:", nrow(species), "MAGs x", ncol(species), "samples\n"))
cat(paste("Metadata:", nrow(metadata), "samples x", ncol(metadata), "variables\n\n"))

#==============================================================================
# SECTION 2: DATA PREPARATION
#==============================================================================

# Select continuous environmental variables
chemistry <- metadata[, c("Salinity", "Temperature", "pH", "Silicate", 
                         "Phosphate", "Nitrate", "Cells_mL", 
                         "Bacterial_production", "DOC", "Chlorophyll")]

# Check structure
str(chemistry)

# Standardize environmental variables (mean=0, SD=1)
chemistry_norm <- decostand(chemistry, "standardize")

# Transpose species data (samples as rows, MAGs as columns)
species_transposed <- t(species)

# Hellinger transformation for species data
# Recommended for abundance data before RDA
species_transposed_norm <- decostand(species_transposed, "hellinger")

cat("Data prepared:\n")
cat("- Environmental variables standardized\n")
cat("- Species data Hellinger-transformed\n\n")

#==============================================================================
# SECTION 3: CHECK FOR COLLINEARITY
#==============================================================================

cat("Checking for collinearity among environmental variables...\n")

# Full model with all variables
species.rda.full <- rda(species_transposed_norm ~ ., data = chemistry_norm)

# Check VIF (Variance Inflation Factor)
# VIF > 10 indicates problematic collinearity
vif_values <- vif.cca(species.rda.full)
print(vif_values)

# Remove highly collinear variables if VIF > 10
if(any(vif_values > 10)) {
  cat("\nWarning: Some variables have VIF > 10 (collinearity detected)\n")
  cat("Consider removing:", names(vif_values)[vif_values > 10], "\n")
} else {
  cat("\nNo problematic collinearity detected (all VIF < 10)\n")
}

cat("\n")

#==============================================================================
# SECTION 4: FORWARD SELECTION OF VARIABLES
#==============================================================================

cat("Performing forward selection of significant variables...\n")

# Null model (intercept only)
species.rda.null <- rda(species_transposed_norm ~ 1, data = chemistry_norm)

# Forward selection with adjusted R² criterion
step.res <- ordiR2step(species.rda.null, 
                       scope = formula(species.rda.full), 
                       perm.max = 999, 
                       direction = "forward")

cat("\nSelected variables:\n")
print(step.res$call)

#==============================================================================
# SECTION 5: TEST SIGNIFICANCE
#==============================================================================

cat("\n========================================\n")
cat("SIGNIFICANCE TESTS\n")
cat("========================================\n")

# Test 1: Overall model significance
cat("\n1. Overall model significance:\n")
model_sig <- anova(step.res, permutations = 999)
print(model_sig)

# Test 2: Significance of each axis
cat("\n2. Significance of each RDA axis:\n")
axis_sig <- anova(step.res, by = "axis", permutations = 999)
print(axis_sig)

# Test 3: Significance of each environmental variable
cat("\n3. Significance of each environmental variable:\n")
term_sig <- anova(step.res, by = "terms", permutations = 999)
print(term_sig)

#==============================================================================
# SECTION 6: BASIC PLOT
#==============================================================================

cat("\n========================================\n")
cat("CREATING PLOTS\n")
cat("========================================\n")

# Basic plot
plot(step.res, main = "RDA Triplot - Basic")

# Add points colored by season
Season <- metadata$Season
points(step.res, display = "sites", cex = 1.5, 
       select = which(Season == "Summer"), 
       pch = 19, col = "red2")
points(step.res, display = "sites", cex = 1.5, 
       select = which(Season == "Spring"), 
       pch = 19, col = "green3")
points(step.res, display = "sites", cex = 1.5, 
       select = which(Season == "Fall"), 
       pch = 19, col = "blue")

# Add legend
legend("topright", 
       legend = c("Summer", "Spring", "Fall"),
       pch = 19,
       col = c("red2", "green3", "blue"),
       bty = "n")

#==============================================================================
# SECTION 7: DISTANCE-BASED RDA (db-RDA)
#==============================================================================

cat("\nPerforming distance-based RDA (db-RDA)...\n")

# Check which distance metric correlates best with environmental gradients
cat("\nTesting different distance metrics:\n")
rank_indices <- rankindex(chemistry_norm, species_transposed_norm, 
                         indices = c("euc", "man", "bray", "jaccard"), 
                         method = "spearman")
print(rank_indices)
cat("\nBest metric (highest correlation):", 
    names(rank_indices)[which.max(rank_indices)], "\n")

# Perform db-RDA with Bray-Curtis distance
# Using only significant variables from forward selection
sig_vars <- attr(terms(step.res), "term.labels")
formula_dbrda <- as.formula(paste("species_transposed_norm ~", 
                                  paste(sig_vars, collapse = " + ")))

dbRDA <- capscale(formula_dbrda, 
                  data = chemistry_norm, 
                  dist = "bray")

# Test significance
cat("\ndb-RDA significance tests:\n")
print(anova(dbRDA))
print(anova(dbRDA, by = "axis", permutations = 999))

#==============================================================================
# SECTION 8: PUBLICATION-QUALITY PLOT
#==============================================================================

# Extract variance explained
perc <- round(100 * (summary(dbRDA)$cont$importance[2, 1:2]), 2)

# Extract scores
sc_si <- scores(dbRDA, display = "sites", choices = c(1, 2))
sc_sp <- scores(dbRDA, display = "species", choices = c(1, 2))
sc_bp <- scores(dbRDA, display = "bp", choices = c(1, 2))

# Calculate species score lengths for filtering
splen <- sqrt(rowSums(sc_sp^2))

# Create color vector for seasons
colors <- c("Summer" = "red2", "Spring" = "green3", "Fall" = "blue")
site_colors <- colors[Season]

# Publication-quality plot
par(mar = c(5, 5, 4, 2))
plot(dbRDA,
     scaling = 1, 
     type = "none", 
     frame = TRUE,
     xlim = range(sc_si[, 1]) * 1.3,
     ylim = range(sc_si[, 2]) * 1.3,
     main = "Distance-based RDA (Bray-Curtis)",
     xlab = paste0("dbRDA1 (", perc[1], "%)"), 
     ylab = paste0("dbRDA2 (", perc[2], "%)"),
     cex.lab = 1.2,
     cex.main = 1.3
)

# Add grid
abline(h = 0, v = 0, col = "gray", lty = 2)

# Add site points colored by season
points(sc_si, 
       pch = 21, 
       col = "black", 
       bg = site_colors, 
       cex = 2)

# Add species points (only those with high scores)
high_score_species <- splen > quantile(splen, 0.7)
points(sc_sp[high_score_species, ], 
       pch = 22, 
       col = "black", 
       bg = "orange", 
       cex = 1.5)

# Add species labels
text(sc_sp[high_score_species, ], 
     labels = rownames(sc_sp)[high_score_species],
     cex = 0.7,
     pos = 4,
     col = "gray30")

# Add environmental vectors
arrows(0, 0, 
       sc_bp[, 1], sc_bp[, 2], 
       col = "darkred", 
       lwd = 2.5,
       length = 0.1)

# Add environmental variable labels
text(sc_bp * 1.1, 
     labels = rownames(sc_bp), 
     col = "darkred", 
     cex = 0.9, 
     font = 2)

# Add legend
legend("topleft", 
       legend = c("Summer", "Spring", "Fall"),
       pch = 21,
       pt.bg = c("red2", "green3", "blue"),
       pt.cex = 2,
       bty = "n",
       title = "Season")

#==============================================================================
# SECTION 9: GGPLOT2 VERSION
#==============================================================================

cat("\nCreating ggplot2 version...\n")

# Prepare data for ggplot
plot_data <- data.frame(
  RDA1 = sc_si[, 1],
  RDA2 = sc_si[, 2],
  Season = Season
)

arrows_data <- data.frame(
  x = 0,
  y = 0,
  xend = sc_bp[, 1],
  yend = sc_bp[, 2],
  Variable = rownames(sc_bp)
)

species_data <- data.frame(
  RDA1 = sc_sp[high_score_species, 1],
  RDA2 = sc_sp[high_score_species, 2],
  MAG = rownames(sc_sp)[high_score_species]
)

# Create ggplot
p <- ggplot() +
  # Add site points
  geom_point(data = plot_data, 
             aes(x = RDA1, y = RDA2, fill = Season),
             shape = 21, size = 4, stroke = 1) +
  
  # Add species points
  geom_point(data = species_data,
             aes(x = RDA1, y = RDA2),
             shape = 22, size = 3, fill = "orange", color = "black") +
  
  # Add species labels
  geom_text_repel(data = species_data,
                  aes(x = RDA1, y = RDA2, label = MAG),
                  size = 3, color = "gray30") +
  
  # Add environmental vectors
  geom_segment(data = arrows_data,
               aes(x = x, y = y, xend = xend, yend = yend),
               arrow = arrow(length = unit(0.3, "cm")),
               color = "darkred", linewidth = 1) +
  
  # Add environmental labels
  geom_text(data = arrows_data,
            aes(x = xend * 1.1, y = yend * 1.1, label = Variable),
            color = "darkred", fontface = "bold", size = 4) +
  
  # Styling
  scale_fill_manual(values = c("Summer" = "red2", 
                               "Spring" = "green3", 
                               "Fall" = "blue")) +
  labs(title = "Distance-based RDA (Bray-Curtis)",
       x = paste0("dbRDA1 (", perc[1], "%)"),
       y = paste0("dbRDA2 (", perc[2], "%)")) +
  theme_bw() +
  theme(
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank(),
    legend.position = "top",
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray70") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray70")

print(p)

# Save plot
ggsave("dbRDA_plot.pdf", p, width = 10, height = 8)
ggsave("dbRDA_plot.png", p, width = 10, height = 8, dpi = 300)

#==============================================================================
# SECTION 10: VARIANCE PARTITIONING (Optional)
#==============================================================================

cat("\n========================================\n")
cat("VARIANCE PARTITIONING\n")
cat("========================================\n")

# Partition variance among environmental variable groups
# Example: Temperature vs Nutrients vs Other

if(length(sig_vars) >= 3) {
  # Group 1: Temperature-related
  temp_vars <- sig_vars[grep("Temperature|Temp", sig_vars, ignore.case = TRUE)]
  
  # Group 2: Nutrient-related
  nutr_vars <- sig_vars[grep("Phosphate|Nitrate|Silicate", sig_vars, ignore.case = TRUE)]
  
  # Group 3: Other
  other_vars <- setdiff(sig_vars, c(temp_vars, nutr_vars))
  
  if(length(temp_vars) > 0 & length(nutr_vars) > 0) {
    varpart_result <- varpart(species_transposed_norm,
                             chemistry_norm[, temp_vars, drop = FALSE],
                             chemistry_norm[, nutr_vars, drop = FALSE])
    
    cat("\nVariance partitioning results:\n")
    print(varpart_result)
    plot(varpart_result, 
         bg = c("red", "blue"), 
         Xnames = c("Temperature", "Nutrients"))
  }
}

#==============================================================================
# SECTION 11: SUMMARY STATISTICS
#==============================================================================

cat("\n========================================\n")
cat("SUMMARY STATISTICS\n")
cat("========================================\n")

# Model summary
cat("\nRDA Summary:\n")
print(summary(step.res))

# R-squared
rsq <- RsquareAdj(step.res)
cat("\nR-squared:\n")
cat("  Unadjusted:", round(rsq$r.squared, 3), "\n")
cat("  Adjusted:  ", round(rsq$adj.r.squared, 3), "\n")

# Variance explained by each axis
cat("\nVariance explained by constrained axes:\n")
eigenvals <- step.res$CCA$eig
prop_explained <- eigenvals / sum(eigenvals) * 100
for(i in 1:min(3, length(eigenvals))) {
  cat(paste0("  RDA", i, ": ", round(prop_explained[i], 2), "%\n"))
}

cat("\n========================================\n")
cat("Analysis complete!\n")
cat("Plots saved: dbRDA_plot.pdf and dbRDA_plot.png\n")
cat("========================================\n")
