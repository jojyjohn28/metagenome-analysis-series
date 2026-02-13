import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from scipy import stats

# ============================
# Create TOY alpha diversity data
# ============================

np.random.seed(42)

treatments = ['Low', 'Medium', 'High']
n_per_group = 20

data = []

for t in treatments:
    for i in range(n_per_group):
        
        if t == 'Low':
            shannon = np.random.normal(4.2, 0.3)
            simpson = np.random.normal(0.90, 0.02)
            observed = np.random.normal(1800, 150)
        
        elif t == 'Medium':
            shannon = np.random.normal(4.8, 0.3)
            simpson = np.random.normal(0.93, 0.02)
            observed = np.random.normal(2200, 150)
        
        else:  # High
            shannon = np.random.normal(4.0, 0.3)
            simpson = np.random.normal(0.88, 0.02)
            observed = np.random.normal(1600, 150)
        
        data.append([t, shannon, simpson, observed])

diversity = pd.DataFrame(
    data,
    columns=['Treatment', 'Shannon', 'Simpson', 'Observed_OTUs']
)

print("Toy diversity data preview:")
print(diversity.head())


# ============================
# Plotting
# ============================

fig, axes = plt.subplots(1, 3, figsize=(15, 5))

metrics = ['Shannon', 'Simpson', 'Observed_OTUs']
colors = ['#3498db', '#e74c3c', '#2ecc71']

for ax, metric, color in zip(axes, metrics, colors):
    
    sns.boxplot(
        data=diversity,
        x='Treatment',
        y=metric,
        ax=ax,
        palette=[color]
    )
    
    sns.swarmplot(
        data=diversity,
        x='Treatment',
        y=metric,
        ax=ax,
        color='black',
        alpha=0.5,
        size=4
    )
    
    ax.set_title(f'{metric} Index', fontsize=12, fontweight='bold')
    ax.set_xlabel('Treatment', fontsize=10)
    ax.set_ylabel(metric, fontsize=10)
    
    # Kruskal-Wallis test
    groups = [
        diversity[diversity['Treatment'] == t][metric].values
        for t in diversity['Treatment'].unique()
    ]
    
    stat, pval = stats.kruskal(*groups)
    
    ax.text(
        0.5, 0.95,
        f'p = {pval:.4f}',
        transform=ax.transAxes,
        ha='center',
        va='top',
        bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5)
    )

plt.tight_layout()
plt.savefig('alpha_diversity_toy.pdf', dpi=300, bbox_inches='tight')
plt.savefig('alpha_diversity_toy.png', dpi=300, bbox_inches='tight')

plt.show()
