#!/usr/bin/env python3
# parse_interproscan.py

import pandas as pd

# Read InterProScan TSV
df = pd.read_csv('interproscan_output.tsv', sep='\t', header=None,
                 names=['protein_id', 'md5', 'length', 'database', 
                        'signature_accession', 'signature_description',
                        'start', 'end', 'score', 'status', 'date',
                        'interpro_accession', 'interpro_description'])

print("="*60)
print("  InterProScan Domain Summary")
print("="*60)
print(f"Proteins analyzed: {df['protein_id'].nunique()}")
print(f"Domains found: {len(df)}")

# Top domains
print(f"\nTop 10 Protein Families:")
for domain in df['interpro_description'].value_counts().head(10).items():
    if pd.notna(domain[0]):
        print(f"  {domain[0]}: {domain[1]}")
