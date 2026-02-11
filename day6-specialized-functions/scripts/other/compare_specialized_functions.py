#!/usr/bin/env python3
# compare_specialized_functions.py

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import glob

# Collect results from multiple genomes
genomes = []

for genome_dir in glob.glob('specialized_analysis/*'):
    genome_name = genome_dir.split('/')[-1]
    
    result = {
        'Genome': genome_name,
        'BGCs': 0,
        'AMR_genes': 0,
        'CAZymes': 0,
        'Prophages': 0,
        'CRISPR': 0
    }
    
    # Count BGCs
    antismash_json = f'{genome_dir}/antismash/genome.json'
    if os.path.exists(antismash_json):
        with open(antismash_json) as f:
            data = json.load(f)
            for record in data['records']:
                result['BGCs'] += len(record.get('areas', []))
    
    # Count AMR
    rgi_file = f'{genome_dir}/rgi_output.txt'
    if os.path.exists(rgi_file):
        rgi = pd.read_csv(rgi_file, sep='\t')
        result['AMR_genes'] = len(rgi)
    
    # Count CAZymes
    dbcan_file = f'{genome_dir}/dbcan_output/overview.txt'
    if os.path.exists(dbcan_file):
        dbcan = pd.read_csv(dbcan_file, sep='\t')
        result['CAZymes'] = len(dbcan)
    
    # Count prophages
    virsorter_file = f'{genome_dir}/virsorter2_output/final-viral-boundary.tsv'
    if os.path.exists(virsorter_file):
        virsorter = pd.read_csv(virsorter_file, sep='\t')
        result['Prophages'] = len(virsorter)
    
    genomes.append(result)

# Create comparison dataframe
df = pd.DataFrame(genomes)

# Heatmap
fig, ax = plt.subplots(figsize=(12, 8))
sns.heatmap(df.set_index('Genome'), annot=True, fmt='d', cmap='YlOrRd',
            cbar_kws={'label': 'Count'})
plt.title('Specialized Functions Across Genomes', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('specialized_functions_comparison.pdf', dpi=300)
print("✓ Comparison plot saved")

# Summary statistics
print("\n" + "="*60)
print("  Specialized Functions Summary")
print("="*60)
print(df.describe())
