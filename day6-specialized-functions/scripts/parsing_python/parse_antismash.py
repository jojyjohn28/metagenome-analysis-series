#!/usr/bin/env python3
# parse_antismash.py

import json
import pandas as pd

# Read antiSMASH JSON
with open('antismash_output/genome1/genome1.json') as f:
    data = json.load(f)

bgcs = []
for record in data['records']:
    for region in record.get('areas', []):
        bgc = {
            'genome': 'genome1',
            'region': region['region_number'],
            'type': ','.join(region['products']),
            'start': region['start'],
            'end': region['end'],
            'length': region['end'] - region['start']
        }
        bgcs.append(bgc)

df = pd.DataFrame(bgcs)

print("="*60)
print("  antiSMASH BGC Summary")
print("="*60)
print(f"Total BGCs: {len(df)}")
print(f"\nBGC Types:")
for bgc_type in df['type'].value_counts().head(10).items():
    print(f"  {bgc_type[0]}: {bgc_type[1]}")

df.to_csv('bgc_summary.csv', index=False)
print(f"\n✓ BGC summary saved: bgc_summary.csv")
