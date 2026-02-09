#!/usr/bin/env python3
import pandas as pd
from collections import Counter

# Read GTDB-Tk results
df = pd.read_csv('gtdbtk_output/classify/gtdbtk.bac120.summary.tsv', sep='\t')

print("="*60)
print("  GTDB-Tk Classification Summary")
print("="*60)
print(f"\nTotal genomes classified: {len(df)}")

# Extract taxonomic levels
tax_levels = ['domain', 'phylum', 'class', 'order', 'family', 'genus', 'species']
prefixes = ['d__', 'p__', 'c__', 'o__', 'f__', 'g__', 's__']

for level, prefix in zip(tax_levels, prefixes):
    taxa = [tax.split(prefix)[1].split(';')[0] 
            for tax in df['classification'] if prefix in tax]
    unique = len(set(taxa))
    print(f"  {level.capitalize()}: {unique} unique")

# Top 5 phyla
print("\nTop 5 Phyla:")
phyla = [tax.split('p__')[1].split(';')[0] for tax in df['classification']]
for phylum, count in Counter(phyla).most_common(5):
    print(f"  {phylum}: {count} genomes")

# ANI distribution
print("\nANI to Reference Genomes:")
print(f"  Mean: {df['fastani_ani'].mean():.2f}%")
print(f"  Median: {df['fastani_ani'].median():.2f}%")
print(f"  ANI >95% (same species): {(df['fastani_ani']>95).sum()}")
print(f"  ANI 90-95% (new species): {((df['fastani_ani']>=90) & (df['fastani_ani']<=95)).sum()}")
print(f"  ANI <90% (novel genus): {(df['fastani_ani']<90).sum()}")

print("="*60)
