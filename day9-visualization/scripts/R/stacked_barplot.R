# ------------------------------------------------------------
# 1) STACKED BARPLOT (Toy taxonomy table)
#    Rows = Phyla, Cols = Samples, Values = Relative abundance %
# ------------------------------------------------------------
library(tidyverse)
library(pheatmap)
library(vegan)
library(GGally)
library(plotly)

phyla <- c("Proteobacteria","Bacteroidota","Actinobacteriota","Firmicutes","Cyanobacteria","Planctomycetota")
samples <- c("Spring_Low","Spring_Medium","Spring_High","Summer_Low","Summer_Medium","Summer_High")

toy_tax <- matrix(rexp(length(phyla)*length(samples), rate=1), nrow=length(phyla))
toy_tax <- sweep(toy_tax, 2, colSums(toy_tax), FUN="/") * 100
taxonomy <- as.data.frame(toy_tax)
rownames(taxonomy) <- phyla
colnames(taxonomy) <- samples

taxonomy_long <- taxonomy %>%
  rownames_to_column("Phylum") %>%
  pivot_longer(-Phylum, names_to="Sample", values_to="Abundance")

p_tax <- ggplot(taxonomy_long, aes(x=Sample, y=Abundance, fill=Phylum)) +
  geom_col(color="white", linewidth=0.3) +
  labs(title="Taxonomic Composition Across Samples (Toy Data)",
       x="Sample", y="Relative Abundance (%)") +
  theme_bw(base_size = 12) +
  theme(axis.text.x = element_text(angle=45, hjust=1),
        plot.title = element_text(face="bold"))
#optional
#ggsave("taxonomy_barplot_toy.pdf", p_tax, width=10, height=5)
#ggsave("taxonomy_barplot_toy.png", p_tax, width=10, height=5, dpi=300)

print(p_tax)
