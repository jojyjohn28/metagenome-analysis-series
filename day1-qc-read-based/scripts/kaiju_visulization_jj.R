# ---------------------------
# Load libraries
# ---------------------------
library(ggplot2)
library(readxl)
library(dplyr)
library(tidyr)

# ---------------------------
# Load Kaiju-derived data
# ---------------------------
data <- read_excel(
  "/home/jojyj/Downloads/Book 77.xlsx",
  sheet = "Sheet1"
)

# ---------------------------
# Reshape data (wide → long)
# ---------------------------
data_long <- data %>%
  pivot_longer(
    cols = -Order,
    names_to = "Sample",
    values_to = "Abundance"
  )

# ---------------------------
# Define color palette
# ---------------------------
order_colors <- c(
  "Acidimicrobiales" = "#D55E00",
  "Actinomycetales" = "#CC79A7",
  "Alteromonadales" = "#E69F00",
  "Bacillales" = "#F0E442",
  "Burkholderiales" = "#0072B2",
  "Ca. Actinomarinales" = "#56B4E9",
  "Ca. Nanopelagicales (Actino)" = "#009E73",
  "Cellvibrionales" = "#999999",
  "Chitinophagales" = "#E69F00",
  "Clostridiales" = "#D55E00",
  "Corynebacteriales" = "#CC79A7",
  "Cytophagales" = "#0072B2",
  "Flavobacteriales" = "#56B4E9",
  "Micrococcales" = "#009E73",
  "Nitrosomonadales" = "#999999",
  "Oceanospirillales" = "#E69F00",
  "Other classified" = "#F0E442",
  "Pelagibacterales" = "#D55E00",
  "Pseudomonadales" = "#CC79A7",
  "Rhizobiales" = "#0072B2",
  "Rhodobacterales" = "#56B4E9",
  "Rhodospirillales" = "#009E73",
  "Sphingobacteriales" = "#999999",
  "Sphingomonadales" = "#E69F00",
  "Sporadotrichida" = "#F0E442",
  "Streptomycetales" = "#D55E00",
  "Synechococcales" = "#CC79A7",
  "Verrucomicrobiales" = "#0072B2"
)

# ---------------------------
# Plot: Relative abundance
# ---------------------------
ggplot(data_long, aes(x = Sample, y = Abundance, fill = Order)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = order_colors) +
  labs(
    x = "Samples",
    y = "Relative Abundance",
    fill = "Order"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(
      angle = 65,
      hjust = 1,
      color = "black",
      face = "bold",
      size = 10
    ),
    axis.text.y = element_text(
      color = "black",
      face = "bold"
    ),
    axis.title = element_text(
      color = "black",
      face = "bold"
    ),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    legend.text = element_text(size = 10)
  )
