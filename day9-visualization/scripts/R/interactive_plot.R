# ------------------------------------------------------------
# TOY NMDS (coords) + ggplot 
#    (A) Direct toy coords (fast)
#    (B) Optional: compute NMDS from toy community table using vegan
# ------------------------------------------------------------
library(tidyverse)
library(pheatmap)
library(vegan)
library(GGally)
library(plotly)

treats <- c("FL_Low","FL_High","PA_Low","PA_High")
n_each <- 8

ordination <- map_dfr(treats, function(t){
  mu <- switch(t,
               "FL_Low"  = c(-1.5,  1.5),
               "FL_High" = c( 1.5,  1.5),
               "PA_Low"  = c(-1.5, -1.5),
               "PA_High" = c( 1.5, -1.5))
  tibble(
    Sample = paste0(t, "_S", 1:n_each),
    Treatment = t,
    NMDS1 = rnorm(n_each, mu[1], 0.3),
    NMDS2 = rnorm(n_each, mu[2], 0.3)
  )
})

p_nmds <- ggplot(ordination, aes(NMDS1, NMDS2, color=Treatment, label=Sample)) +
  geom_point(size=3) +
  ggrepel::geom_text_repel(size=3, max.overlaps = 20) +
  labs(title="NMDS Ordination (Toy Data)", x="NMDS1", y="NMDS2") +
  theme_bw(base_size = 12) +
  theme(plot.title = element_text(face="bold"))

#ggsave("nmds_toy.pdf", p_nmds, width=7, height=6)
print(p_nmds)

