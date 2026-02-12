#!/usr/bin/env Rscript
# SIMPLIFIED RDA ANALYSIS
# Quick start guide for distance-based redundancy analysis
# Perfect for beginners!

#==============================================================================
# STEP 1: INSTALL AND LOAD PACKAGES
#==============================================================================

# Install packages if needed (uncomment first time)
# install.packages("vegan")
# install.packages("ggplot2")
# install.packages("ggrepel")

library(vegan)
library(ggplot2)
library(ggrepel)

#==============================================================================
# STEP 2: LOAD YOUR DATA
#==============================================================================

# Option A: Use toy data (for testing)
set.seed(123)
abundance <- matrix(rpois(20 * 34, lambda = 50), nrow = 20, ncol = 34)
rownames(abundance) <- paste0("MAG_", 1:20)
colnames(abundance) <- paste0("Sample_", 1:34)

metadata <- data.frame(
  Season = rep(c("Summer", "Spring", "Fall"), length.out = 34),
  Salinity = rnorm(34, 35, 5),
  Temperature = rnorm(34, 20, 8),
  pH = rnorm(34, 7.5, 0.5),
  Phosphate = rnorm(34, 2, 0.5),
  Nitrate = rnorm(34, 5, 2)
)
rownames(metadata) <- colnames(abundance)

# Option B: Load your own data (uncomment and modify paths)
# abundance <- read.csv("your_abundance_table.csv", row.names = 1)
# metadata <- read.csv("your_metadata.csv", row.names = 1)

#==============================================================================
# STEP 3: PREPARE DATA
#==============================================================================

# Extract environmental variables (continuous only)
env_vars <- metadata[, c("Salinity", "Temperature", "pH", "Phosphate", "Nitrate")]

# Standardize environmental variables
env_norm <- decostand(env_vars, "standardize")

# Transform abundance data
# Rows must be samples, columns must be MAGs
abundance_t <- t(abundance)  # Transpose
abundance_norm <- decostand(abundance_t, "hellinger")  # Hellinger transform

cat("✓ Data prepared successfully!\n")
cat(paste("  -", nrow(abundance_norm), "samples\n"))
cat(paste("  -", ncol(abundance_norm), "MAGs\n"))
cat(paste("  -", ncol(env_norm), "environmental variables\n\n"))

#==============================================================================
# STEP 4: RUN RDA WITH FORWARD SELECTION
#==============================================================================

cat("Running RDA with forward selection...\n")

# Full model
rda_full <- rda(abundance_norm ~ ., data = env_norm)

# Null model
rda_null <- rda(abundance_norm ~ 1, data = env_norm)

# Forward selection (keeps only significant variables)
rda_selected <- ordiR2step(rda_null, 
                          scope = formula(rda_full),
                          direction = "forward",
                          permutations = 999)

cat("\n✓ Selected significant variables:\n")
print(attr(terms(rda_selected), "term.labels"))

#==============================================================================
# STEP 5: TEST SIGNIFICANCE
#==============================================================================

cat("\n" ,"=", rep("=", 50), "\n", sep = "")
cat("SIGNIFICANCE TESTS\n")
cat("=" , rep("=", 50), "\n\n", sep = "")

# Overall model
cat("1. Is the model significant?\n")
model_test <- anova(rda_selected, permutations = 999)
print(model_test)

if(model_test$`Pr(>F)`[1] < 0.05) {
  cat("\n✓ YES! The model is significant (p < 0.05)\n")
} else {
  cat("\n✗ NO. The model is not significant\n")
}

# Individual variables
cat("\n2. Which variables are significant?\n")
var_test <- anova(rda_selected, by = "terms", permutations = 999)
print(var_test)

cat("\nSignificant variables (p < 0.05):\n")
sig_vars <- rownames(var_test)[var_test$`Pr(>F)` < 0.05]
cat(paste("  -", sig_vars, collapse = "\n"), "\n")

#==============================================================================
# STEP 6: BASIC PLOT
#==============================================================================

cat("\nCreating basic plot...\n")

# Simple plot
plot(rda_selected, 
     main = "RDA: MAGs vs Environment",
     scaling = 2)

# Add legend for seasons
legend("topright", 
       legend = unique(metadata$Season),
       pch = 19,
       col = c("red", "green", "blue"),
       bty = "n")

#==============================================================================
# STEP 7: DISTANCE-BASED RDA (db-RDA)
#==============================================================================

cat("\nRunning distance-based RDA...\n")

# Get significant variables
sig_formula <- as.formula(paste("abundance_norm ~", 
                               paste(attr(terms(rda_selected), "term.labels"), 
                                     collapse = " + ")))

# Run db-RDA with Bray-Curtis distance
dbrda <- capscale(sig_formula, 
                  data = env_norm, 
                  dist = "bray")

# Test significance
cat("\ndb-RDA significance:\n")
print(anova(dbrda))

#==============================================================================
# STEP 8: NICE PLOT
#==============================================================================

cat("\nCreating publication-quality plot...\n")

# Extract variance explained
var_explained <- round(100 * summary(dbrda)$cont$importance[2, 1:2], 1)

# Extract scores
sites <- scores(dbrda, display = "sites", choices = 1:2)
species <- scores(dbrda, display = "species", choices = 1:2)
env <- scores(dbrda, display = "bp", choices = 1:2)

# Define colors
season_colors <- c("Summer" = "red2", "Spring" = "green3", "Fall" = "blue")

# Create plot
par(mar = c(5, 5, 4, 2))
plot(dbrda,
     type = "none",
     xlim = range(sites[,1]) * 1.2,
     ylim = range(sites[,2]) * 1.2,
     xlab = paste0("dbRDA1 (", var_explained[1], "%)"),
     ylab = paste0("dbRDA2 (", var_explained[2], "%)"),
     main = "Distance-based RDA",
     cex.lab = 1.2)

# Add reference lines
abline(h = 0, v = 0, col = "gray", lty = 2)

# Add site points colored by season
for(season in unique(metadata$Season)) {
  points(sites[metadata$Season == season, ],
         pch = 21,
         bg = season_colors[season],
         cex = 2)
}

# Add environmental vectors
arrows(0, 0, env[,1], env[,2],
       col = "darkred",
       lwd = 2,
       length = 0.1)

text(env * 1.15,
     labels = rownames(env),
     col = "darkred",
     font = 2)

# Add legend
legend("topleft",
       legend = names(season_colors),
       pch = 21,
       pt.bg = season_colors,
       pt.cex = 2,
       bty = "n")

#==============================================================================
# STEP 9: INTERPRETATION
#==============================================================================

cat("\n", "=", rep("=", 50), "\n", sep = "")
cat("HOW TO INTERPRET YOUR RESULTS\n")
cat("=", rep("=", 50), "\n\n", sep = "")

# R-squared
rsq <- RsquareAdj(dbrda)
cat("1. MODEL FIT:\n")
cat(paste("   R² =", round(rsq$r.squared, 3), 
          "→", round(rsq$r.squared * 100, 1), 
          "% of variance explained\n"))

if(rsq$r.squared > 0.3) {
  cat("   ✓ Good! Environmental variables explain >30% of variation\n")
} else if(rsq$r.squared > 0.1) {
  cat("   ○ Moderate. Environmental variables explain 10-30% of variation\n")
} else {
  cat("   ✗ Weak. Environmental variables explain <10% of variation\n")
}

cat("\n2. ENVIRONMENTAL DRIVERS:\n")
cat("   The most important factors are:\n")
var_importance <- sort(var_test$`F`[1:(nrow(var_test)-1)], decreasing = TRUE)
for(i in 1:min(3, length(var_importance))) {
  cat(paste0("   ", i, ". ", names(var_importance)[i], 
             " (F = ", round(var_importance[i], 2), ")\n"))
}

cat("\n3. AXIS INTERPRETATION:\n")
cat(paste("   - dbRDA1 explains", var_explained[1], "% of constrained variance\n"))
cat(paste("   - dbRDA2 explains", var_explained[2], "% of constrained variance\n"))
cat("   - Together:", sum(var_explained), "%\n")

cat("\n4. WHAT THIS MEANS:\n")
cat("   → Your microbial communities are significantly structured by:\n")
for(var in sig_vars) {
  cat(paste0("      • ", var, "\n"))
}

cat("\n   → Look at the plot:\n")
cat("      • Samples close together = similar communities\n")
cat("      • Arrow direction = environmental gradient\n")
cat("      • Arrow length = strength of effect\n")

cat("\n", "=", rep("=", 50), "\n", sep = "")
cat("✓ ANALYSIS COMPLETE!\n")
cat("=", rep("=", 50), "\n", sep = "")

#==============================================================================
# BONUS: SAVE RESULTS
#==============================================================================

# Save plot
pdf("rda_plot.pdf", width = 10, height = 8)
plot(dbrda, type = "none",
     xlim = range(sites[,1]) * 1.2,
     ylim = range(sites[,2]) * 1.2,
     xlab = paste0("dbRDA1 (", var_explained[1], "%)"),
     ylab = paste0("dbRDA2 (", var_explained[2], "%)"),
     main = "Distance-based RDA")
abline(h = 0, v = 0, col = "gray", lty = 2)
for(season in unique(metadata$Season)) {
  points(sites[metadata$Season == season, ],
         pch = 21, bg = season_colors[season], cex = 2)
}
arrows(0, 0, env[,1], env[,2], col = "darkred", lwd = 2, length = 0.1)
text(env * 1.15, labels = rownames(env), col = "darkred", font = 2)
legend("topleft", legend = names(season_colors), 
       pch = 21, pt.bg = season_colors, pt.cex = 2, bty = "n")
dev.off()

# Save summary
sink("rda_summary.txt")
cat("RDA ANALYSIS SUMMARY\n")
cat("===================\n\n")
cat("Model formula:\n")
print(formula(dbrda))
cat("\nOverall significance:\n")
print(model_test)
cat("\nVariable significance:\n")
print(var_test)
cat("\nR-squared:\n")
print(rsq)
sink()

cat("\n✓ Results saved:\n")
cat("  - rda_plot.pdf\n")
cat("  - rda_summary.txt\n")
