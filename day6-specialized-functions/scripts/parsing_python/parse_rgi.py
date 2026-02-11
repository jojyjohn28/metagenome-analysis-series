#!/usr/bin/env python3
# parse_rgi.py

import pandas as pd

# Read RGI results
df = pd.read_csv('rgi_output.txt', sep='\t')

print("="*60)
print("  CARD-RGI AMR Summary")
print("="*60)
print(f"Total AMR genes: {len(df)}")

# Drug classes
print(f"\nDrug Classes:")
for drug in df['Drug Class'].value_counts().head(10).items():
    print(f"  {drug[0]}: {drug[1]}")

# Resistance mechanisms
print(f"\nResistance Mechanisms:")
for mech in df['Resistance Mechanism'].value_counts().items():
    print(f"  {mech[0]}: {mech[1]}")

# Critical AMR genes
critical = ['mcr-1', 'NDM', 'KPC', 'VIM', 'OXA-48']
for gene in critical:
    hits = df[df['Best_Hit_ARO'].str.contains(gene, case=False, na=False)]
    if len(hits) > 0:
        print(f"\n⚠️  CRITICAL: {gene} detected ({len(hits)} hits)")
