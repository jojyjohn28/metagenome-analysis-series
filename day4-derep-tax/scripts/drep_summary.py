#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Read dRep tables
clusters = pd.read_csv('dereplicated_genomes/data_tables/Cdb.csv')
winners = pd.read_csv('dereplicated_genomes/data_tables/Widb.csv')

# Count genomes per cluster
cluster_sizes = clusters['secondary_cluster'].value_counts()

print("="*60)
print("  Dereplication Summary")
print("="*60)
print(f"Total input genomes: {len(clusters)}")
print(f"Dereplicated genomes: {len(winners)}")
print(f"Reduction: {(1 - len(winners)/len(clusters))*100:.1f}%")
print(f"\nClusters formed: {len(cluster_sizes)}")
print(f"Mean cluster size: {cluster_sizes.mean():.2f}")
print(f"Max cluster size: {cluster_sizes.max()}")

# Plot cluster size distribution
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Histogram
axes[0].hist(cluster_sizes, bins=30, color='steelblue', edgecolor='black')
axes[0].set_xlabel('Cluster Size')
axes[0].set_ylabel('Frequency')
axes[0].set_title('Genome Cluster Size Distribution')
axes[0].grid(alpha=0.3, axis='y')

# Pie chart: Singletons vs Multi-member
singletons = (cluster_sizes == 1).sum()
multi = (cluster_sizes > 1).sum()
axes[1].pie([singletons, multi], 
            labels=['Unique genomes', 'Redundant groups'],
            autopct='%1.1f%%',
            colors=['#27ae60', '#e74c3c'])
axes[1].set_title('Genome Redundancy')

plt.tight_layout()
plt.savefig('dereplication_summary.pdf', dpi=300)
print("\n✓ Plot saved: dereplication_summary.pdf")
