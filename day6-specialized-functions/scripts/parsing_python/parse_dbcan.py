#!/usr/bin/env python3
# parse_dbcan.py

import pandas as pd

# Read overview
df = pd.read_csv('dbcan_output/overview.txt', sep='\t')

print("="*60)
print("  dbCAN CAZyme Summary")
print("="*60)
print(f"Total CAZymes: {len(df)}")

# Count by family
families = []
for index, row in df.iterrows():
    if pd.notna(row['HMMER']):
        families.append(row['HMMER'].split('(')[0])

from collections import Counter
family_counts = Counter(families)

print(f"\nTop 10 CAZyme Families:")
for family, count in family_counts.most_common(10):
    print(f"  {family}: {count}")

# Cellulose degradation capability
cellulose_families = ['GH5', 'GH6', 'GH7', 'GH9', 'GH45']
cellulose_cazymes = sum([family_counts.get(f, 0) for f in cellulose_families])
print(f"\nCellulose degradation genes: {cellulose_cazymes}")

# Starch degradation
starch_families = ['GH13', 'GH14', 'GH15', 'GH31']
starch_cazymes = sum([family_counts.get(f, 0) for f in starch_families])
print(f"Starch degradation genes: {starch_cazymes}")
