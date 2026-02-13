import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# ============================
# Create TOY MAG abundance data
# Rows = MAGs
# Columns = Samples
# Values = Abundance
# ============================

np.random.seed(42)

n_mags = 30
n_samples = 12

mags = [f"MAG_{i+1}" for i in range(n_mags)]
samples = [
    "Spring_Low_FL", "Spring_Med_FL", "Spring_High_FL",
    "Spring_Low_PA", "Spring_Med_PA", "Spring_High_PA",
    "Summer_Low_FL", "Summer_Med_FL", "Summer_High_FL",
    "Summer_Low_PA", "Summer_Med_PA", "Summer_High_PA"
]

# Generate abundance with structure
data = np.random.gamma(shape=2, scale=50, size=(n_mags, n_samples))

# Introduce ecological structure:
# First 10 MAGs enriched in FL
data[:10, :6] *= 2

# Next 10 MAGs enriched in PA
data[10:20, 6:] *= 2

abundance = pd.DataFrame(data, index=mags, columns=samples)

print("Toy MAG abundance preview:")
print(abundance.head())


# ============================
# Log transform
# ============================

abundance_log = np.log10(abundance + 1)


# ============================
# Clustered heatmap
# ============================

sns.clustermap(
    abundance_log,
    cmap='viridis',
    figsize=(12, 10),
    cbar_kws={'label': 'log10(Abundance + 1)'},
    linewidths=0.3,
    linecolor='gray',
    xticklabels=True,
    yticklabels=False,
    dendrogram_ratio=(0.1, 0.2),
    cbar_pos=(0.02, 0.8, 0.03, 0.15)
)

plt.savefig('mag_heatmap_clustered_toy.pdf', dpi=300, bbox_inches='tight')
plt.savefig('mag_heatmap_clustered_toy.png', dpi=300, bbox_inches='tight')

plt.show()

