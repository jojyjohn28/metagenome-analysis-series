# ------------------------------------------------------------
#  TOY ALPHA DIVERSITY (3-panel box + points + Kruskal p)
#    Metrics: Shannon, Simpson, Observed_OTUs
# ------------------------------------------------------------
library(tidyverse)
library(pheatmap)
library(vegan)
library(GGally)
library(plotly)

treatments <- c("Low","Medium","High")
n_per_group <- 20

diversity <- map_dfr(treatments, function(t){
  tibble(
    Treatment = t,
    Shannon = rnorm(n_per_group, mean=ifelse(t=="Medium", 4.8, ifelse(t=="Low", 4.2, 4.0)), sd=0.25),
    Simpson = rnorm(n_per_group, mean=ifelse(t=="Medium", 0.93, ifelse(t=="Low", 0.90, 0.88)), sd=0.02),
    Observed_OTUs = rnorm(n_per_group, mean=ifelse(t=="Medium", 2200, ifelse(t=="Low", 1800, 1600)), sd=150)
  )
})

plot_div_metric <- function(df, metric){
  pval <- kruskal.test(df[[metric]] ~ df$Treatment)$p.value
  ggplot(df, aes(x=Treatment, y=.data[[metric]])) +
    geom_boxplot(outlier.shape = NA) +
    geom_jitter(width=0.15, alpha=0.6, size=2) +
    annotate("label", x=2, y=Inf, label=sprintf("p = %.4f", pval),
             vjust=1.2, label.size=0.2) +
    labs(title=paste0(metric, " Index (Toy Data)"), x="Treatment", y=metric) +
    theme_bw(base_size = 12) +
    theme(plot.title = element_text(face="bold"))
}

p_shannon <- plot_div_metric(diversity, "Shannon")
p_simpson <- plot_div_metric(diversity, "Simpson")
p_obs     <- plot_div_metric(diversity, "Observed_OTUs")


# Save as separate files (simple + reliable)
#ggsave("alpha_diversity_shannon_toy.pdf", p_shannon, width=5.5, height=4.5)
#ggsave("alpha_diversity_simpson_toy.pdf", p_simpson, width=5.5, height=4.5)
#ggsave("alpha_diversity_observed_toy.pdf", p_obs, width=5.5, height=4.5)

print(p_shannon); print(p_simpson); print(p_obs)

library(ggplot2)
library(patchwork)

plot_div_metric <- function(df, metric){
  pval <- kruskal.test(df[[metric]] ~ df$Treatment)$p.value
  
  # compute a good label position (top of data)
  y_top <- max(df[[metric]], na.rm = TRUE)
  
  ggplot(df, aes(x=Treatment, y=.data[[metric]])) +
    geom_boxplot(outlier.shape = NA) +
    geom_jitter(width=0.15, alpha=0.6, size=2) +
    geom_label(
      aes(x = 2, y = y_top),
      label = sprintf("p = %.4f", pval),
      inherit.aes = FALSE,
      vjust = -0.2,
      label.size = 0.25 # border thickness (works here)
    ) +
    coord_cartesian(clip = "off") +
    labs(title=paste0(metric, " (Toy Data)"), x="Treatment", y=metric) +
    theme_bw(base_size = 12) +
    theme(
      plot.title = element_text(face="bold"),
      plot.margin = margin(5.5, 20, 5.5, 5.5) # extra top room for label
    )
}

# Build plots
p_shannon <- plot_div_metric(diversity, "Shannon")
p_simpson <- plot_div_metric(diversity, "Simpson")
p_obs     <- plot_div_metric(diversity, "Observed_OTUs")

# Combine with patchwork
p_all <- (p_shannon | p_simpson | p_obs) +
  plot_annotation(
    title = "Alpha Diversity (Toy Data)",
    theme = theme(plot.title = element_text(face="bold", size=16))
  )

# Save single multi-panel figure
ggsave("alpha_diversity_3panel_toy.pdf", p_all, width=14, height=4.8)
ggsave("alpha_diversity_3panel_toy.png", p_all, width=14, height=4.8, dpi=300)

# Print
p_all

