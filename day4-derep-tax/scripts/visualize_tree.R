library(ggtree)
library(treeio)
library(ggplot2)
library(dplyr)

# Read tree
tree <- read.tree("gtdbtk_output/classify/gtdbtk.bac120.classify.tree")

# Read GTDB-Tk metadata
metadata <- read.delim("gtdbtk_output/classify/gtdbtk.bac120.summary.tsv", 
                       sep = "\t", header = TRUE)

# Extract phylum
metadata$phylum <- gsub(".*;p__([^;]+);.*", "\\1", metadata$classification)

# Create basic tree
p <- ggtree(tree) + 
  theme_tree2()

# Add phylum colors
p <- p %<+% metadata +
  geom_tippoint(aes(color = phylum), size = 3) +
  scale_color_brewer(palette = "Set3") +
  theme(legend.position = "right")

# Save
ggsave("phylogenetic_tree.pdf", p, width = 12, height = 10, dpi = 300)
ggsave("phylogenetic_tree.png", p, width = 12, height = 10, dpi = 300)

print("✓ Tree saved: phylogenetic_tree.pdf/png")

# Advanced: Circular tree with genome labels
p2 <- ggtree(tree, layout = "circular") +
  geom_tiplab(aes(color = phylum), size = 2, offset = 0.01) +
  scale_color_brewer(palette = "Set3") +
  theme(legend.position = "bottom")

ggsave("phylogenetic_tree_circular.pdf", p2, width = 14, height = 14, dpi = 300)

# With heatmap of ANI values
p3 <- ggtree(tree) %<+% metadata +
  geom_tippoint(aes(color = fastani_ani), size = 3) +
  scale_color_gradient(low = "blue", high = "red", 
                       name = "ANI to\nReference (%)") +
  theme_tree2() +
  theme(legend.position = "right")

ggsave("phylogenetic_tree_ani.pdf", p3, width = 12, height = 10, dpi = 300)