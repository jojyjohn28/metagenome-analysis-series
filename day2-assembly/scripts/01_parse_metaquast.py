#!/usr/bin/env python3
"""
Script: 01_parse_metaquast.py
Description: Parse MetaQUAST results and extract key metrics
Author: github.com/jojyjohn28
Usage: python 01_parse_metaquast.py --input metaquast_dir --output results.csv
"""

import os
import sys
import argparse
import pandas as pd
from pathlib import Path

def parse_metaquast_report(report_file):
    """Parse a MetaQUAST report.txt file"""
    metrics = {}
    
    with open(report_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # Parse key metrics
            if '# contigs (>= 0 bp)' in line:
                metrics['total_contigs'] = int(line.split()[-1])
            elif '# contigs (>= 1000 bp)' in line:
                metrics['contigs_1kb'] = int(line.split()[-1])
            elif '# contigs (>= 5000 bp)' in line:
                metrics['contigs_5kb'] = int(line.split()[-1])
            elif '# contigs (>= 10000 bp)' in line:
                metrics['contigs_10kb'] = int(line.split()[-1])
            elif 'Total length (>= 0 bp)' in line:
                metrics['total_length'] = int(line.split()[-1])
            elif 'Total length (>= 1000 bp)' in line:
                metrics['total_length_1kb'] = int(line.split()[-1])
            elif 'Largest contig' in line:
                metrics['largest_contig'] = int(line.split()[-1])
            elif line.startswith('N50'):
                metrics['n50'] = int(line.split()[-1])
            elif line.startswith('N75'):
                metrics['n75'] = int(line.split()[-1])
            elif line.startswith('L50'):
                metrics['l50'] = int(line.split()[-1])
            elif line.startswith('L75'):
                metrics['l75'] = int(line.split()[-1])
            elif 'GC (%)' in line:
                metrics['gc_percent'] = float(line.split()[-1])
            elif '# misassemblies' in line:
                metrics['misassemblies'] = int(line.split()[-1])
            elif '# mismatches per 100 kbp' in line:
                metrics['mismatches_per_100kb'] = float(line.split()[-1])
            elif '# indels per 100 kbp' in line:
                metrics['indels_per_100kb'] = float(line.split()[-1])
    
    return metrics

def parse_metaquast_directory(metaquast_dir):
    """Parse all MetaQUAST results in a directory"""
    results = []
    
    # Find all report.txt files
    metaquast_path = Path(metaquast_dir)
    
    for sample_dir in metaquast_path.iterdir():
        if not sample_dir.is_dir():
            continue
        
        report_file = sample_dir / 'report.txt'
        if not report_file.exists():
            continue
        
        print(f"Parsing {sample_dir.name}...")
        
        try:
            metrics = parse_metaquast_report(report_file)
            metrics['sample'] = sample_dir.name
            
            # Check for multiple assemblies in the same report
            transposed_file = sample_dir / 'transposed_report.tsv'
            if transposed_file.exists():
                df = pd.read_csv(transposed_file, sep='\t')
                # Process each assembly separately
                for col in df.columns[1:]:  # Skip first column (metric names)
                    assembly_metrics = metrics.copy()
                    assembly_metrics['assembler'] = col
                    results.append(assembly_metrics)
            else:
                metrics['assembler'] = 'unknown'
                results.append(metrics)
                
        except Exception as e:
            print(f"  Error parsing {sample_dir.name}: {e}")
            continue
    
    return results

def calculate_quality_score(row):
    """Calculate overall assembly quality score (0-100)"""
    score = 0
    
    # N50 contribution (40 points max)
    if row['n50'] >= 20000:
        score += 40
    elif row['n50'] >= 10000:
        score += 30
    elif row['n50'] >= 5000:
        score += 20
    elif row['n50'] >= 1000:
        score += 10
    
    # Total contigs contribution (20 points max, fewer is better)
    if row['total_contigs'] <= 5000:
        score += 20
    elif row['total_contigs'] <= 20000:
        score += 15
    elif row['total_contigs'] <= 50000:
        score += 10
    elif row['total_contigs'] <= 100000:
        score += 5
    
    # Largest contig contribution (20 points max)
    if row['largest_contig'] >= 200000:
        score += 20
    elif row['largest_contig'] >= 100000:
        score += 15
    elif row['largest_contig'] >= 50000:
        score += 10
    elif row['largest_contig'] >= 10000:
        score += 5
    
    # L50 contribution (20 points max, fewer is better)
    total_contigs = row['total_contigs']
    l50_ratio = row['l50'] / total_contigs if total_contigs > 0 else 1
    
    if l50_ratio <= 0.01:
        score += 20
    elif l50_ratio <= 0.05:
        score += 15
    elif l50_ratio <= 0.10:
        score += 10
    elif l50_ratio <= 0.20:
        score += 5
    
    return score

def main():
    parser = argparse.ArgumentParser(
        description='Parse MetaQUAST results and extract key metrics'
    )
    parser.add_argument(
        '--input', '-i',
        required=True,
        help='MetaQUAST output directory'
    )
    parser.add_argument(
        '--output', '-o',
        required=True,
        help='Output CSV file'
    )
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"Error: Input directory not found: {args.input}")
        sys.exit(1)
    
    print("="*60)
    print("  MetaQUAST Results Parser")
    print("="*60)
    print(f"Input directory: {args.input}")
    print(f"Output file: {args.output}")
    print("")
    
    # Parse all results
    results = parse_metaquast_directory(args.input)
    
    if not results:
        print("No MetaQUAST results found!")
        sys.exit(1)
    
    # Convert to DataFrame
    df = pd.DataFrame(results)
    
    # Calculate quality scores
    df['quality_score'] = df.apply(calculate_quality_score, axis=1)
    
    # Sort by sample and quality score
    df = df.sort_values(['sample', 'quality_score'], ascending=[True, False])
    
    # Save results
    df.to_csv(args.output, index=False)
    
    print(f"\nParsed {len(df)} assembly results")
    print(f"Unique samples: {df['sample'].nunique()}")
    print("")
    
    # Print summary statistics
    print("="*60)
    print("  Summary Statistics")
    print("="*60)
    print("\nN50 Statistics:")
    print(f"  Mean:   {df['n50'].mean():,.0f} bp")
    print(f"  Median: {df['n50'].median():,.0f} bp")
    print(f"  Min:    {df['n50'].min():,.0f} bp")
    print(f"  Max:    {df['n50'].max():,.0f} bp")
    
    print("\nTotal Contigs:")
    print(f"  Mean:   {df['total_contigs'].mean():,.0f}")
    print(f"  Median: {df['total_contigs'].median():,.0f}")
    print(f"  Min:    {df['total_contigs'].min():,.0f}")
    print(f"  Max:    {df['total_contigs'].max():,.0f}")
    
    print("\nQuality Scores:")
    print(f"  Mean:   {df['quality_score'].mean():.1f}/100")
    print(f"  Median: {df['quality_score'].median():.1f}/100")
    
    # Best assemblies
    print("\n" + "="*60)
    print("  Top 5 Assemblies (by quality score)")
    print("="*60)
    top5 = df.nlargest(5, 'quality_score')[['sample', 'assembler', 'n50', 'total_contigs', 'quality_score']]
    print(top5.to_string(index=False))
    
    print(f"\n✓ Results saved to: {args.output}")
    print("")

if __name__ == '__main__':
    main()
