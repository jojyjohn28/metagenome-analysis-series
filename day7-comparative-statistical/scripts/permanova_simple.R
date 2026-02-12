#!/usr/bin/env Rscript
# PERMANOVA SIMPLIFIED
# Quick guide to test if groups have different communities
# Perfect for beginners!

#==============================================================================
# WHAT DOES PERMANOVA DO?
#==============================================================================
# Question: Do my treatment groups have different microbial communities?
# Answer: PERMANOVA gives you a YES or NO (with a p-value)
#
# Example questions:
# - Are diseased samples different from healthy samples?
# - Does antibiotic treatment change the microbiome?
# - Are communities different between sites?
#==============================================================================

# Load package
library(vegan)
library(ggplot2)

set.seed(123)

#==============================================================================
# STEP 1: CREATE TOY DATA
#==============================================================================

cat("Creating example data...\n\n")

# 30 samples, 25 MAGs each
abundance <- matrix(rpois(30 * 25, lambda = 50), nrow = 30, ncol = 25)
rownames(abundance) <- paste0("Sample_", 1:30)
colnames(abundance) <- paste0("MAG_", 1:25)

# Metadata with treatment groups
metadata <- data.frame(
  Sample = paste0("Sample_", 1:30),
  Treatment = rep(c("Control", "Treatment_A", "Treatment_B"), each = 10)
)

# Make treatment groups actually different
# (so PERMANOVA finds something!)
abundance[metadata$Treatment == "Treatment_A", 1:8] <- 
  abundance[metadata$Treatment == "Treatment_A", 1:8] * 2

cat("✓ Data created:\n")
cat("  - 30 samples\n")
cat("  - 3 treatment groups (10 samples each)\n")
cat("  - 25 MAGs\n\n")

#==============================================================================
# STEP 2: CALCULATE DISTANCES
#==============================================================================

cat("Calculating distances between samples...\n\n")

# Bray-Curtis distance (most common)
distances <- vegdist(abundance, method = "bray")

cat("✓ Distance matrix created\n\n")

#==============================================================================
# STEP 3: RUN PERMANOVA
#==============================================================================

cat("Running PERMANOVA...\n")
cat("Question: Do treatments have different communities?\n\n")

# Run PERMANOVA
result <- adonis2(distances ~ Treatment, 
                 data = metadata, 
                 permutations = 999)

print(result)

#==============================================================================
# STEP 4: INTERPRET RESULTS
#==============================================================================

cat("\n", rep("=", 60), "\n", sep = "")
cat("HOW TO INTERPRET\n")
cat(rep("=", 60), "\n\n", sep = "")

# Extract key values
pvalue <- result$`Pr(>F)`[1]
rsquared <- result$R2[1]
fvalue <- result$F[1]

# 1. Significance
cat("1. IS THERE A DIFFERENCE?\n")
if(pvalue < 0.05) {
  cat("   ✓ YES! p =", round(pvalue, 4), "(< 0.05)\n")
  cat("   → Treatment groups have significantly different communities\n")
} else {
  cat("   ✗ NO. p =", round(pvalue, 4), "(>= 0.05)\n")
  cat("   → Treatment groups are not significantly different\n")
}

# 2. Effect size
cat("\n2. HOW STRONG IS THE EFFECT?\n")
cat("   R² =", round(rsquared, 3), "→", round(rsquared * 100, 1), "%\n")
cat("   This means:\n")
cat("   •", round(rsquared * 100, 1), "% of variation is explained by Treatment\n")
cat("   •", round((1 - rsquared) * 100, 1), "% is explained by other factors\n")

if(rsquared < 0.06) {
  cat("   → Small effect\n")
} else if(rsquared < 0.14) {
  cat("   → Medium effect\n")
} else {
  cat("   → Large effect\n")
}

# 3. F-statistic
cat("\n3. EFFECT SIZE MEASURE:\n")
cat("   F =", round(fvalue, 2), "\n")
cat("   Larger F = stronger difference between groups\n")

cat("\n", rep("=", 60), "\n\n", sep = "")

#==============================================================================
# STEP 5: CHECK ASSUMPTIONS
#==============================================================================

cat("CHECKING ASSUMPTION: Equal Dispersion\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("PERMANOVA assumes groups have equal spread (dispersion)\n")
cat("Testing this with betadisper...\n\n")

# Test dispersion
disp <- betadisper(distances, metadata$Treatment)
disp_test <- permutest(disp)

print(disp_test)

cat("\n")
if(disp_test$tab$`Pr(>F)`[1] < 0.05) {
  cat("⚠ WARNING: Dispersions are NOT equal (p < 0.05)\n")
  cat("   → Groups have different spreads\n")
  cat("   → PERMANOVA results may be unreliable\n")
  cat("   → Consider transforming your data\n")
} else {
  cat("✓ GOOD: Dispersions are equal (p >= 0.05)\n")
  cat("   → Assumption met\n")
  cat("   → PERMANOVA results are reliable\n")
}

# Plot dispersion
boxplot(disp, main = "Dispersion by Treatment Group",
        ylab = "Distance to group centroid",
        col = c("lightblue", "lightgreen", "lightcoral"))

cat("\n", rep("=", 60), "\n\n", sep = "")

#==============================================================================
# STEP 6: VISUALIZE WITH NMDS
#==============================================================================

cat("Creating visualization...\n\n")

# Run NMDS
nmds <- metaMDS(abundance, distance = "bray", k = 2, trymax = 50)

cat("NMDS Stress:", round(nmds$stress, 3), "\n")
if(nmds$stress < 0.2) {
  cat("✓ Good representation (stress < 0.2)\n\n")
} else {
  cat("⚠ Poor representation (stress > 0.2) - interpret with caution\n\n")
}

# Get NMDS coordinates
nmds_points <- data.frame(scores(nmds, display = "sites"))
nmds_points$Treatment <- metadata$Treatment

# Create plot
p <- ggplot(nmds_points, aes(x = NMDS1, y = NMDS2, color = Treatment)) +
  geom_point(size = 4, alpha = 0.7) +
  stat_ellipse(level = 0.95, linewidth = 1) +
  theme_bw() +
  labs(title = "NMDS: Community Composition by Treatment",
       subtitle = paste0("PERMANOVA: p = ", round(pvalue, 4), 
                        ", R² = ", round(rsquared, 3))) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5),
        legend.position = "right")

print(p)

# Save
ggsave("permanova_simple.pdf", p, width = 8, height = 6)
ggsave("permanova_simple.png", p, width = 8, height = 6, dpi = 300)

cat("✓ Plot saved: permanova_simple.pdf/png\n\n")

#==============================================================================
# STEP 7: PAIRWISE COMPARISONS
#==============================================================================

cat(rep("=", 60), "\n", sep = "")
cat("PAIRWISE COMPARISONS\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("Which specific groups are different from each other?\n\n")

treatments <- unique(metadata$Treatment)

for(i in 1:(length(treatments) - 1)) {
  for(j in (i + 1):length(treatments)) {
    # Get samples for this pair
    pair_idx <- metadata$Treatment %in% c(treatments[i], treatments[j])
    pair_dist <- vegdist(abundance[pair_idx, ], method = "bray")
    pair_meta <- data.frame(Treatment = metadata$Treatment[pair_idx])
    
    # Run PERMANOVA
    pair_result <- adonis2(pair_dist ~ Treatment, data = pair_meta, permutations = 999)
    
    # Print result
    cat(treatments[i], "vs", treatments[j], "\n")
    cat("  p-value:", round(pair_result$`Pr(>F)`[1], 4), "\n")
    
    if(pair_result$`Pr(>F)`[1] < 0.05) {
      cat("  ✓ DIFFERENT (p < 0.05)\n")
    } else {
      cat("  ✗ Not different (p >= 0.05)\n")
    }
    cat("\n")
  }
}

#==============================================================================
# STEP 8: WHAT TO REPORT
#==============================================================================

cat(rep("=", 60), "\n", sep = "")
cat("WHAT TO REPORT IN YOUR PAPER\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("Example text for your methods:\n")
cat('"We tested for differences in community composition using\n')
cat(' PERMANOVA (adonis2 function in vegan) with 999 permutations\n')
cat(' and Bray-Curtis dissimilarity."\n\n')

cat("Example text for your results:\n")
if(pvalue < 0.05) {
  cat(paste0('"Treatment significantly affected community composition\n'))
  cat(paste0(' (PERMANOVA: F = ', round(fvalue, 2), 
             ', R² = ', round(rsquared, 3), 
             ', p = ', round(pvalue, 4), ')."\n\n'))
} else {
  cat(paste0('"Treatment did not significantly affect community composition\n'))
  cat(paste0(' (PERMANOVA: F = ', round(fvalue, 2), 
             ', p = ', round(pvalue, 4), ')."\n\n'))
}

cat("Include in your figure caption:\n")
cat(paste0('"NMDS ordination of bacterial communities. Points represent\n'))
cat(paste0(' samples colored by treatment. Ellipses show 95% confidence\n'))
cat(paste0(' intervals. PERMANOVA: R² = ', round(rsquared, 3), 
           ', p = ', round(pvalue, 4), '."\n\n'))

#==============================================================================
# SUMMARY CHECKLIST
#==============================================================================

cat(rep("=", 60), "\n", sep = "")
cat("CHECKLIST\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("✓ Things to check:\n")
cat("  [ ] P-value < 0.05? → Groups are different\n")
cat("  [ ] R² value? → How much variation explained?\n")
cat("  [ ] Dispersion test passed? → Assumption met?\n")
cat("  [ ] NMDS stress < 0.2? → Good visualization?\n")
cat("  [ ] Pairwise comparisons done? → Which groups differ?\n")

cat("\n✓ Things to report:\n")
cat("  [ ] PERMANOVA F-statistic\n")
cat("  [ ] R² value\n")
cat("  [ ] P-value\n")
cat("  [ ] Number of permutations (999)\n")
cat("  [ ] Distance metric (Bray-Curtis)\n")
cat("  [ ] Dispersion test results\n")

cat("\n✓ Figures to include:\n")
cat("  [ ] NMDS ordination with ellipses\n")
cat("  [ ] Dispersion boxplot (if relevant)\n")

cat("\n", rep("=", 60), "\n", sep = "")
cat("✓ ANALYSIS COMPLETE!\n")
cat(rep("=", 60), "\n", sep = "")

#==============================================================================
# SAVE SUMMARY
#==============================================================================

# Create summary
summary_text <- paste0(
  "PERMANOVA RESULTS SUMMARY\n",
  "========================\n\n",
  "Question: Do treatments have different communities?\n\n",
  "P-value: ", round(pvalue, 4), 
  ifelse(pvalue < 0.05, " (SIGNIFICANT)\n", " (not significant)\n"),
  "R²: ", round(rsquared, 3), " (", round(rsquared * 100, 1), "% explained)\n",
  "F-statistic: ", round(fvalue, 2), "\n\n",
  "Interpretation:\n",
  ifelse(pvalue < 0.05, 
         "✓ Treatment groups have significantly different communities.\n",
         "✗ Treatment groups do not have significantly different communities.\n"),
  "\nDispersion test p-value: ", round(disp_test$tab$`Pr(>F)`[1], 4),
  ifelse(disp_test$tab$`Pr(>F)`[1] < 0.05,
         " (WARNING: unequal dispersions)\n",
         " (OK: equal dispersions)\n"),
  "\nNMDS stress: ", round(nmds$stress, 3),
  ifelse(nmds$stress < 0.2, " (good)\n", " (poor)\n")
)

writeLines(summary_text, "permanova_summary.txt")

cat("\n✓ Summary saved: permanova_summary.txt\n")
