#!/usr/bin/env python3
"""
Script: 02_assembly_statistics.py
Description: Calculate detailed assembly statistics from FASTA files
Author: github.com/jojyjohn28
Usage: python 02_assembly_statistics.py --assemblies *.fasta --output stats.csv
"""

import os
import sys
import argparse
import pandas as pd
from Bio import SeqIO
from pathlib import Path
import statistics

def calculate_assembly_stats(fasta_file):
    """Calculate comprehensive assembly statistics"""
    
    print(f"  Analyzing {Path(fasta_file).name}...")
    
    stats = {
        'file': Path(fasta_file).name,
        'sample': Path(fasta_file).parent.name
    }
    
    # Read all sequences
    sequences = list(SeqIO.parse(fasta_file, "fasta"))
    
    if not sequences:
        print(f"    WARNING: No sequences found in {fasta_file}")
        return None
    
    # Calculate lengths
    lengths = [len(seq.seq) for seq in sequences]
    lengths_sorted = sorted(lengths, reverse=True)
    
    # Basic statistics
    stats['total_contigs'] = len(lengths)
    stats['total_length'] = sum(lengths)
    stats['mean_length'] = statistics.mean(lengths)
    stats['median_length'] = statistics.median(lengths)
    stats['min_length'] = min(lengths)
    stats['max_length'] = max(lengths)
    stats['stdev_length'] = statistics.stdev(lengths) if len(lengths) > 1 else 0
    
    # N50 calculation
    cumsum = 0
    for i, length in enumerate(lengths_sorted):
        cumsum += length
        if cumsum >= stats['total_length'] / 2:
            stats['n50'] = length
            stats['l50'] = i + 1
            break
    
    # N75 calculation
    cumsum = 0
    for i, length in enumerate(lengths_sorted):
        cumsum += length
        if cumsum >= stats['total_length'] * 0.75:
            stats['n75'] = length
            stats['l75'] = i + 1
            break
    
    # N90 calculation
    cumsum = 0
    for i, length in enumerate(lengths_sorted):
        cumsum += length
        if cumsum >= stats['total_length'] * 0.90:
            stats['n90'] = length
            stats['l90'] = i + 1
            break
    
    # Count contigs by size
    stats['contigs_500bp'] = sum(1 for l in lengths if l >= 500)
    stats['contigs_1kb'] = sum(1 for l in lengths if l >= 1000)
    stats['contigs_5kb'] = sum(1 for l in lengths if l >= 5000)
    stats['contigs_10kb'] = sum(1 for l in lengths if l >= 10000)
    stats['contigs_50kb'] = sum(1 for l in lengths if l >= 50000)
    stats['contigs_100kb'] = sum(1 for l in lengths if l >= 100000)
    
    # Calculate GC content
    gc_contents = []
    for seq in sequences:
        seq_str = str(seq.seq).upper()
        gc_count = seq_str.count('G') + seq_str.count('C')
        total = len(seq_str)
        if total > 0:
            gc_contents.append(gc_count / total * 100)
    
    if gc_contents:
        stats['mean_gc'] = statistics.mean(gc_contents)
        stats['median_gc'] = statistics.median(gc_contents)
        stats['min_gc'] = min(gc_contents)
        stats['max_gc'] = max(gc_contents)
        stats['stdev_gc'] = statistics.stdev(gc_contents) if len(gc_contents) > 1 else 0
    
    # Calculate assembly efficiency
    stats['bases_in_1kb_contigs'] = sum(l for l in lengths if l >= 1000)
    stats['bases_in_10kb_contigs'] = sum(l for l in lengths if l >= 10000)
    stats['percent_in_1kb'] = (stats['bases_in_1kb_contigs'] / stats['total_length'] * 100) \
                              if stats['total_length'] > 0 else 0
    stats['percent_in_10kb'] = (stats['bases_in_10kb_contigs'] / stats['total_length'] * 100) \
                               if stats['total_length'] > 0 else 0
    
    return stats

def main():
    parser = argparse.ArgumentParser(
        description='Calculate detailed assembly statistics'
    )
    parser.add_argument(
        '--assemblies', '-a',
        nargs='+',
        required=True,
        help='Assembly FASTA files (can use wildcards)'
    )
    parser.add_argument(
        '--output', '-o',
        required=True,
        help='Output CSV file'
    )
    
    args = parser.parse_args()
    
    print("="*70)
    print("  Assembly Statistics Calculator")
    print("="*70)
    print(f"Number of assemblies: {len(args.assemblies)}")
    print(f"Output file: {args.output}")
    print("")
    
    # Calculate statistics for all assemblies
    all_stats = []
    
    for fasta_file in args.assemblies:
        if not os.path.exists(fasta_file):
            print(f"  WARNING: File not found: {fasta_file}")
            continue
        
        try:
            stats = calculate_assembly_stats(fasta_file)
            if stats:
                all_stats.append(stats)
        except Exception as e:
            print(f"  ERROR processing {fasta_file}: {e}")
            continue
    
    if not all_stats:
        print("\nNo statistics calculated!")
        sys.exit(1)
    
    # Convert to DataFrame
    df = pd.DataFrame(all_stats)
    
    # Sort by N50 (descending)
    df = df.sort_values('n50', ascending=False)
    
    # Save to CSV
    df.to_csv(args.output, index=False)
    
    print(f"\n✓ Statistics calculated for {len(df)} assemblies")
    print(f"✓ Results saved to: {args.output}")
    print("")
    
    # Print summary
    print("="*70)
    print("  Summary Statistics")
    print("="*70)
    
    print("\nN50 Distribution:")
    print(f"  Mean:   {df['n50'].mean():>12,.0f} bp")
    print(f"  Median: {df['n50'].median():>12,.0f} bp")
    print(f"  Min:    {df['n50'].min():>12,.0f} bp")
    print(f"  Max:    {df['n50'].max():>12,.0f} bp")
    
    print("\nTotal Assembly Length:")
    print(f"  Mean:   {df['total_length'].mean():>12,.0f} bp")
    print(f"  Median: {df['total_length'].median():>12,.0f} bp")
    print(f"  Min:    {df['total_length'].min():>12,.0f} bp")
    print(f"  Max:    {df['total_length'].max():>12,.0f} bp")
    
    print("\nContig Count:")
    print(f"  Mean:   {df['total_contigs'].mean():>12,.0f}")
    print(f"  Median: {df['total_contigs'].median():>12,.0f}")
    print(f"  Min:    {df['total_contigs'].min():>12,.0f}")
    print(f"  Max:    {df['total_contigs'].max():>12,.0f}")
    
    print("\nGC Content:")
    print(f"  Mean:   {df['mean_gc'].mean():>12.2f}%")
    print(f"  Median: {df['median_gc'].median():>12.2f}%")
    
    # Best assemblies
    print("\n" + "="*70)
    print("  Top 5 Assemblies (by N50)")
    print("="*70)
    top5 = df.head(5)[['sample', 'file', 'n50', 'total_contigs', 'total_length']]
    top5.columns = ['Sample', 'File', 'N50 (bp)', '# Contigs', 'Total Length (bp)']
    print(top5.to_string(index=False))
    print("")

if __name__ == '__main__':
    main()
