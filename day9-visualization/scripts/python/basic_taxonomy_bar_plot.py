import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# ============================
# Create TOY taxonomy data
# Rows = Phylum
# Columns = Samples
# Values = Relative abundance (%)
# ============================

np.random.seed(42)

phyla = [
    "Proteobacteria",
    "Bacteroidota",
    "Actinobacteriota",
    "Firmicutes",
    "Cyanobacteria",
    "Planctomycetota"
]

samples = [
    "Spring_Low",
    "Spring_Medium",
    "Spring_High",
    "Summer_Low",
    "Summer_Medium",
    "Summer_High"
]

# Generate random abundance and normalize to %
data = np.random.rand(len(phyla), len(samples))
data = data / data.sum(axis=0) * 100

taxonomy = pd.DataFrame(data, index=phyla, columns=samples)

print("Toy taxonomy table:")
print(taxonomy.round(2))


# ============================
# Stacked barplot
# ============================

fig, ax = plt.subplots(figsize=(12, 6))

colors = plt.cm.Set3(np.linspace(0, 1, len(taxonomy.index)))

taxonomy.T.plot(
    kind='bar',
    stacked=True,
    ax=ax,
    color=colors,
    edgecolor='white',
    linewidth=0.5
)

# Styling
ax.set_xlabel('Sample', fontsize=12, fontweight='bold')
ax.set_ylabel('Relative Abundance (%)', fontsize=12, fontweight='bold')
ax.set_title('Taxonomic Composition Across Samples', fontsize=14, fontweight='bold')

ax.legend(
    title='Phylum',
    bbox_to_anchor=(1.05, 1),
    loc='upper left'
)

plt.xticks(rotation=45, ha='right')
plt.tight_layout()

# Save
plt.savefig('taxonomy_barplot_toy.pdf', dpi=300, bbox_inches='tight')
plt.savefig('taxonomy_barplot_toy.png', dpi=300, bbox_inches='tight')

plt.show()

