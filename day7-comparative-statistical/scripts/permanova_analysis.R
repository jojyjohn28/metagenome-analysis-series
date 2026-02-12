#!/usr/bin/env Rscript
# PERMANOVA: Permutational Multivariate Analysis of Variance
# Test if groups have significantly different community compositions
# Author: Metagenome Analysis Series
# Date: 2026-02-12

#==============================================================================
# WHAT IS PERMANOVA?
#==============================================================================
# PERMANOVA tests whether groups (e.g., treatments, seasons, sites) have
# significantly different multivariate centroids (community compositions).
#
# Questions it answers:
# - Do microbial communities differ between healthy vs diseased samples?
# - Does treatment affect community composition?
# - Are communities different across seasons or sites?
#
# Key outputs:
# - P-value: Is there a significant difference?
# - R²: How much variance is explained by grouping?
# - F-statistic: Effect size
#==============================================================================

# Load required libraries
library(vegan)
library(ggplot2)
library(ggrepel)

set.seed(123)

#==============================================================================
# SECTION 1: CREATE TOY DATA
#==============================================================================

cat("Creating toy dataset...\n")

# Create abundance data
# 30 samples with 25 MAGs each
n_samples <- 30
n_mags <- 25

# Generate realistic MAG abundance data
abundance <- matrix(
  rpois(n_samples * n_mags, lambda = 50),
  nrow = n_samples,
  ncol = n_mags
)

rownames(abundance) <- paste0("Sample_", 1:n_samples)
colnames(abundance) <- paste0("MAG_", 1:n_mags)

# Create metadata with grouping variables
metadata <- data.frame(
  Sample_ID = paste0("Sample_", 1:n_samples),
  
  # Categorical variables
  Treatment = rep(c("Control", "Treatment_A", "Treatment_B"), each = 10),
  Season = rep(c("Summer", "Winter", "Spring"), times = 10),
  Site = rep(c("Site_1", "Site_2", "Site_3"), each = 10),
  
  # Continuous variables (for supplementary analyses)
  pH = rnorm(n_samples, 7.5, 0.8),
  Temperature = rnorm(n_samples, 20, 5),
  Salinity = rnorm(n_samples, 35, 3)
)

rownames(metadata) <- metadata$Sample_ID

# Make treatment effect stronger (for demonstration)
# Treatment_A samples have more of certain MAGs
abundance[metadata$Treatment == "Treatment_A", 1:8] <- 
  abundance[metadata$Treatment == "Treatment_A", 1:8] * 2

# Treatment_B samples have more of different MAGs  
abundance[metadata$Treatment == "Treatment_B", 9:16] <- 
  abundance[metadata$Treatment == "Treatment_B", 9:16] * 2

cat("✓ Toy data created:\n")
cat(paste("  -", n_samples, "samples\n"))
cat(paste("  -", n_mags, "MAGs\n"))
cat(paste("  - Treatments:", paste(unique(metadata$Treatment), collapse = ", "), "\n"))
cat(paste("  - Seasons:", paste(unique(metadata$Season), collapse = ", "), "\n\n"))

#==============================================================================
# SECTION 2: CALCULATE DISTANCE MATRIX
#==============================================================================

cat("Calculating distance matrix...\n")

# Bray-Curtis dissimilarity is most common for abundance data
dist_bray <- vegdist(abundance, method = "bray")

# Alternative distance metrics (uncomment to try)
# dist_jaccard <- vegdist(abundance, method = "jaccard")  # Presence/absence
# dist_euclidean <- dist(abundance)  # Euclidean distance

cat("✓ Distance matrix calculated using Bray-Curtis\n\n")

#==============================================================================
# SECTION 3: BASIC PERMANOVA - SINGLE FACTOR
#==============================================================================

cat("========================================\n")
cat("PERMANOVA: Single Factor Analysis\n")
cat("========================================\n\n")

# Test effect of Treatment
cat("Testing: Does Treatment affect community composition?\n\n")

permanova_treatment <- adonis2(dist_bray ~ Treatment, 
                               data = metadata, 
                               permutations = 999)

print(permanova_treatment)

# Interpret results
if(permanova_treatment$`Pr(>F)`[1] < 0.05) {
  cat("\n✓ SIGNIFICANT! Treatment significantly affects communities (p < 0.05)\n")
  cat(paste("  R² =", round(permanova_treatment$R2[1], 3), 
            "→ Treatment explains", 
            round(permanova_treatment$R2[1] * 100, 1), 
            "% of variation\n"))
} else {
  cat("\n✗ NOT SIGNIFICANT. Treatment does not affect communities (p >= 0.05)\n")
}

cat("\n")

#==============================================================================
# SECTION 4: TEST DISPERSION HOMOGENEITY
#==============================================================================

cat("========================================\n")
cat("Testing Homogeneity of Dispersions\n")
cat("========================================\n\n")

cat("IMPORTANT: PERMANOVA assumes equal dispersion among groups!\n")
cat("Testing this assumption with betadisper...\n\n")

# Test if groups have equal dispersion
disp_treatment <- betadisper(dist_bray, metadata$Treatment)
disp_test <- permutest(disp_treatment, pairwise = TRUE)

print(disp_test)

if(disp_test$tab$`Pr(>F)`[1] < 0.05) {
  cat("\n⚠ WARNING: Dispersions are NOT equal (p < 0.05)\n")
  cat("   PERMANOVA results may be unreliable!\n")
  cat("   → Groups differ in variance, not just centroids\n")
  cat("   → Consider using PERMDISP2 or transforming data\n")
} else {
  cat("\n✓ GOOD! Dispersions are homogeneous (p >= 0.05)\n")
  cat("   PERMANOVA assumption met\n")
}

# Plot dispersion
plot(disp_treatment, main = "Dispersion among Treatment groups")
boxplot(disp_treatment, main = "Distance to centroid by Treatment")

cat("\n")

#==============================================================================
# SECTION 5: PERMANOVA - MULTIPLE FACTORS
#==============================================================================

cat("========================================\n")
cat("PERMANOVA: Multiple Factors\n")
cat("========================================\n\n")

cat("Testing: Treatment + Season + Site\n\n")

permanova_multi <- adonis2(dist_bray ~ Treatment + Season + Site, 
                          data = metadata, 
                          permutations = 999)

print(permanova_multi)

cat("\nInterpretation:\n")
sig_factors <- rownames(permanova_multi)[permanova_multi$`Pr(>F)` < 0.05 & 
                                        !is.na(permanova_multi$`Pr(>F)`)]
if(length(sig_factors) > 0) {
  cat("Significant factors (p < 0.05):\n")
  for(factor in sig_factors) {
    r2 <- permanova_multi[factor, "R2"]
    pval <- permanova_multi[factor, "Pr(>F)"]
    cat(paste0("  • ", factor, ": R² = ", round(r2, 3), 
               " (", round(r2 * 100, 1), "%), p = ", 
               round(pval, 4), "\n"))
  }
}

cat("\n")

#==============================================================================
# SECTION 6: PERMANOVA WITH INTERACTIONS
#==============================================================================

cat("========================================\n")
cat("PERMANOVA: Testing Interactions\n")
cat("========================================\n\n")

cat("Testing: Treatment * Season (interaction)\n\n")

permanova_interact <- adonis2(dist_bray ~ Treatment * Season, 
                             data = metadata, 
                             permutations = 999)

print(permanova_interact)

if(!is.na(permanova_interact["Treatment:Season", "Pr(>F)"]) && 
   permanova_interact["Treatment:Season", "Pr(>F)"] < 0.05) {
  cat("\n✓ INTERACTION DETECTED!\n")
  cat("   Treatment effect depends on Season\n")
  cat("   → Need to analyze seasons separately\n")
} else {
  cat("\n✗ NO INTERACTION\n")
  cat("   Treatment effect is consistent across seasons\n")
}

cat("\n")

#==============================================================================
# SECTION 7: PAIRWISE COMPARISONS
#==============================================================================

cat("========================================\n")
cat("Pairwise Comparisons Between Groups\n")
cat("========================================\n\n")

# Manual pairwise PERMANOVA
cat("Pairwise comparisons for Treatment:\n\n")

treatments <- unique(metadata$Treatment)
pairwise_results <- data.frame(
  Comparison = character(),
  R2 = numeric(),
  F_value = numeric(),
  P_value = numeric(),
  stringsAsFactors = FALSE
)

for(i in 1:(length(treatments) - 1)) {
  for(j in (i + 1):length(treatments)) {
    # Subset data
    pair_samples <- metadata$Treatment %in% c(treatments[i], treatments[j])
    pair_dist <- vegdist(abundance[pair_samples, ], method = "bray")
    pair_meta <- metadata[pair_samples, ]
    
    # Run PERMANOVA
    pair_result <- adonis2(pair_dist ~ Treatment, 
                          data = pair_meta, 
                          permutations = 999)
    
    # Store results
    pairwise_results <- rbind(pairwise_results, 
                             data.frame(
                               Comparison = paste(treatments[i], "vs", treatments[j]),
                               R2 = pair_result$R2[1],
                               F_value = pair_result$F[1],
                               P_value = pair_result$`Pr(>F)`[1]
                             ))
  }
}

# Adjust p-values for multiple testing
pairwise_results$P_adjusted <- p.adjust(pairwise_results$P_value, method = "BH")

print(pairwise_results)

cat("\nSignificant pairwise differences (adjusted p < 0.05):\n")
sig_pairs <- pairwise_results[pairwise_results$P_adjusted < 0.05, ]
if(nrow(sig_pairs) > 0) {
  for(i in 1:nrow(sig_pairs)) {
    cat(paste0("  ✓ ", sig_pairs$Comparison[i], 
               " (p.adj = ", round(sig_pairs$P_adjusted[i], 4), ")\n"))
  }
} else {
  cat("  No significant pairwise differences\n")
}

cat("\n")

#==============================================================================
# SECTION 8: PERMANOVA WITH CONTINUOUS VARIABLES
#==============================================================================

cat("========================================\n")
cat("PERMANOVA: Continuous Variables\n")
cat("========================================\n\n")

cat("Testing: Treatment + pH + Temperature + Salinity\n\n")

permanova_continuous <- adonis2(dist_bray ~ Treatment + pH + Temperature + Salinity, 
                               data = metadata, 
                               permutations = 999)

print(permanova_continuous)

cat("\n")

#==============================================================================
# SECTION 9: VISUALIZE WITH NMDS
#==============================================================================

cat("========================================\n")
cat("Visualization: NMDS Ordination\n")
cat("========================================\n\n")

cat("Running NMDS ordination...\n")

# Run NMDS
nmds <- metaMDS(abundance, distance = "bray", k = 2, trymax = 100)

cat(paste("Stress:", round(nmds$stress, 3), "\n"))
if(nmds$stress < 0.05) {
  cat("✓ Excellent representation (stress < 0.05)\n")
} else if(nmds$stress < 0.10) {
  cat("✓ Good representation (stress < 0.10)\n")
} else if(nmds$stress < 0.20) {
  cat("○ Fair representation (stress < 0.20)\n")
} else {
  cat("✗ Poor representation (stress > 0.20)\n")
}

# Extract NMDS scores
nmds_scores <- data.frame(scores(nmds, display = "sites"))
nmds_scores$Treatment <- metadata$Treatment
nmds_scores$Season <- metadata$Season

# Base R plot
plot(nmds, type = "n", main = "NMDS: Treatment Groups")
points(nmds, display = "sites", 
       col = as.numeric(factor(metadata$Treatment)),
       pch = 19, cex = 2)
legend("topright", 
       legend = levels(factor(metadata$Treatment)),
       col = 1:length(unique(metadata$Treatment)),
       pch = 19,
       title = "Treatment")

# Add 95% confidence ellipses
ordiellipse(nmds, metadata$Treatment, kind = "se", conf = 0.95, lwd = 2)

# ggplot2 version
p1 <- ggplot(nmds_scores, aes(x = NMDS1, y = NMDS2, color = Treatment)) +
  geom_point(size = 4, alpha = 0.7) +
  stat_ellipse(type = "norm", level = 0.95, linewidth = 1) +
  theme_bw() +
  labs(title = paste0("NMDS Ordination (Stress = ", round(nmds$stress, 3), ")"),
       subtitle = paste0("PERMANOVA: R² = ", 
                        round(permanova_treatment$R2[1], 3),
                        ", p = ", round(permanova_treatment$`Pr(>F)`[1], 4))) +
  theme(legend.position = "right",
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5))

print(p1)

# Save plot
ggsave("permanova_nmds.pdf", p1, width = 10, height = 8)
ggsave("permanova_nmds.png", p1, width = 10, height = 8, dpi = 300)

cat("\n✓ Plots saved: permanova_nmds.pdf and permanova_nmds.png\n\n")

#==============================================================================
# SECTION 10: PERMANOVA WITH STRATA (BLOCKING)
#==============================================================================

cat("========================================\n")
cat("PERMANOVA: With Blocking/Strata\n")
cat("========================================\n\n")

cat("Use strata when you have nested or blocked designs\n")
cat("Example: Test Treatment within each Site\n\n")

# Permutations restricted within sites
permanova_strata <- adonis2(dist_bray ~ Treatment, 
                           data = metadata, 
                           permutations = how(nperm = 999, 
                                             blocks = metadata$Site))

print(permanova_strata)

cat("\n")

#==============================================================================
# SECTION 11: EFFECT SIZE INTERPRETATION
#==============================================================================

cat("========================================\n")
cat("Understanding Effect Sizes (R²)\n")
cat("========================================\n\n")

r2_treatment <- permanova_treatment$R2[1]

cat("Your R² value:", round(r2_treatment, 3), "\n\n")

cat("Effect size interpretation:\n")
if(r2_treatment < 0.01) {
  cat("  < 0.01: Negligible effect\n")
} else if(r2_treatment < 0.06) {
  cat("  0.01-0.06: Small effect ✓\n")
} else if(r2_treatment < 0.14) {
  cat("  0.06-0.14: Medium effect ✓✓\n")
} else {
  cat("  > 0.14: Large effect ✓✓✓\n")
}

cat("\nWhat does R² mean?\n")
cat(paste0("  • ", round(r2_treatment * 100, 1), 
           "% of community variation is explained by Treatment\n"))
cat(paste0("  • ", round((1 - r2_treatment) * 100, 1), 
           "% is explained by other factors\n"))

cat("\n")

#==============================================================================
# SECTION 12: SUMMARY AND RECOMMENDATIONS
#==============================================================================

cat("========================================\n")
cat("SUMMARY & RECOMMENDATIONS\n")
cat("========================================\n\n")

cat("✓ PERMANOVA Results Summary:\n\n")

cat("1. MAIN EFFECT:\n")
if(permanova_treatment$`Pr(>F)`[1] < 0.05) {
  cat(paste0("   ✓ Treatment significantly affects communities\n"))
  cat(paste0("   ✓ Explains ", round(permanova_treatment$R2[1] * 100, 1), 
             "% of variation\n"))
} else {
  cat("   ✗ Treatment does NOT significantly affect communities\n")
}

cat("\n2. DISPERSION TEST:\n")
if(disp_test$tab$`Pr(>F)`[1] < 0.05) {
  cat("   ⚠ WARNING: Unequal dispersions detected\n")
  cat("   → Be cautious interpreting PERMANOVA\n")
  cat("   → Consider PERMDISP or data transformation\n")
} else {
  cat("   ✓ Dispersions are homogeneous\n")
  cat("   → PERMANOVA assumptions met\n")
}

cat("\n3. RECOMMENDATIONS:\n")
cat("   • Report both PERMANOVA and betadisper results\n")
cat("   • Visualize with NMDS or PCoA ordination\n")
cat("   • Follow up with pairwise comparisons\n")
cat("   • Consider effect size (R²), not just p-value\n")
cat("   • Use 999+ permutations for final analysis\n")

cat("\n4. NEXT STEPS:\n")
cat("   • Identify which taxa drive differences (use indicator species)\n")
cat("   • Test environmental associations (use RDA/db-RDA)\n")
cat("   • Examine patterns with constrained ordination\n")

cat("\n========================================\n")
cat("✓ PERMANOVA ANALYSIS COMPLETE!\n")
cat("========================================\n\n")

#==============================================================================
# BONUS: SAVE RESULTS
#==============================================================================

# Create summary table
results_summary <- data.frame(
  Analysis = c("Treatment (single)", 
               "Multiple factors", 
               "With interaction",
               "With continuous"),
  R2 = c(permanova_treatment$R2[1],
         permanova_multi["Treatment", "R2"],
         permanova_interact["Treatment", "R2"],
         permanova_continuous["Treatment", "R2"]),
  F_value = c(permanova_treatment$F[1],
              permanova_multi["Treatment", "F"],
              permanova_interact["Treatment", "F"],
              permanova_continuous["Treatment", "F"]),
  P_value = c(permanova_treatment$`Pr(>F)`[1],
              permanova_multi["Treatment", "Pr(>F)"],
              permanova_interact["Treatment", "Pr(>F)"],
              permanova_continuous["Treatment", "Pr(>F)"])
)

# Save to file
write.csv(results_summary, "permanova_summary.csv", row.names = FALSE)
write.csv(pairwise_results, "permanova_pairwise.csv", row.names = FALSE)

# Save full results
sink("permanova_full_results.txt")
cat("PERMANOVA ANALYSIS - FULL RESULTS\n")
cat("==================================\n\n")
cat("1. Single Factor (Treatment):\n")
print(permanova_treatment)
cat("\n2. Dispersion Test:\n")
print(disp_test)
cat("\n3. Multiple Factors:\n")
print(permanova_multi)
cat("\n4. Pairwise Comparisons:\n")
print(pairwise_results)
sink()

cat("✓ Results saved:\n")
cat("  - permanova_summary.csv\n")
cat("  - permanova_pairwise.csv\n")
cat("  - permanova_full_results.txt\n")
cat("  - permanova_nmds.pdf/png\n")
