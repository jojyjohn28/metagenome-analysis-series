#!/usr/bin/env python3
"""
Script: combine_abundance_coverage.py
Description: Combine CoverM abundance and SingleM coverage data
Author: github.com/jojyjohn28
Usage: python combine_abundance_coverage.py --coverm mag_abundance/mag_abundance_table.tsv --singlem singlem_results/found_mags.tsv --output combined_results/
"""

import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import sys

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Combine CoverM and SingleM results'
    )
    parser.add_argument(
        '--coverm',
        required=True,
        help='CoverM abundance table (mag_abundance_table.tsv)'
    )
    parser.add_argument(
        '--singlem',
        required=True,
        help='SingleM found_mags.tsv file'
    )
    parser.add_argument(
        '--output', '-o',
        default='combined_results',
        help='Output directory (default: combined_results)'
    )
    
    return parser.parse_args()

def load_coverm_data(filepath):
    """Load CoverM abundance data"""
    print(f"Loading CoverM data from: {filepath}")
    
    df = pd.read_csv(filepath, sep='\t')
    
    # Extract relative abundance columns
    ra_cols = [col for col in df.columns if 'Relative Abundance' in col]
    abundance = df[['Genome'] + ra_cols].copy()
    
    # Clean column names
    abundance.columns = ['MAG'] + [col.split()[0] + '_RA' for col in ra_cols]
    abundance = abundance.set_index('MAG')
    
    print(f"  Loaded {len(abundance)} MAGs, {len(abundance.columns)} samples")
    
    return abundance

def load_singlem_data(filepath):
    """Load SingleM coverage data"""
    print(f"Loading SingleM data from: {filepath}")
    
    df = pd.read_csv(filepath, sep='\t')
    
    # Create pivot table
    coverage = df.pivot_table(values='coverage', 
                              index='genome', 
                              columns='sample', 
                              aggfunc='mean')
    
    # Rename columns
    coverage.columns = [col + '_Cov' for col in coverage.columns]
    coverage.index.name = 'MAG'
    
    print(f"  Loaded {len(coverage)} MAGs, {len(coverage.columns)} samples")
    
    return coverage

def combine_data(abundance, coverage):
    """Combine abundance and coverage data"""
    print("\nCombining data...")
    
    # Merge on MAG index
    combined = abundance.join(coverage, how='outer')
    
    print(f"  Combined dataset: {len(combined)} MAGs")
    print(f"  MAGs in both datasets: {len(combined.dropna())}")
    print(f"  MAGs only in CoverM: {combined[combined.filter(like='_Cov').isna().all(axis=1)].shape[0]}")
    print(f"  MAGs only in SingleM: {combined[combined.filter(like='_RA').isna().all(axis=1)].shape[0]}")
    
    return combined

def classify_mags(combined):
    """Classify MAGs based on abundance and coverage"""
    print("\nClassifying MAGs...")
    
    # Get column names
    ra_cols = [col for col in combined.columns if '_RA' in col]
    cov_cols = [col for col in combined.columns if '_Cov' in col]
    
    # Calculate mean abundance and coverage
    combined['Mean_RA'] = combined[ra_cols].mean(axis=1)
    combined['Mean_Cov'] = combined[cov_cols].mean(axis=1)
    
    # Classify
    def classify(row):
        ra = row['Mean_RA']
        cov = row['Mean_Cov']
        
        if pd.isna(ra) or pd.isna(cov):
            return 'Incomplete_Data'
        elif ra > 5 and cov > 80:
            return 'High_Abundance_High_Coverage'
        elif ra > 5 and cov <= 80:
            return 'High_Abundance_Low_Coverage'
        elif ra <= 5 and cov > 80:
            return 'Low_Abundance_High_Coverage'
        else:
            return 'Low_Abundance_Low_Coverage'
    
    combined['Classification'] = combined.apply(classify, axis=1)
    
    # Print classification summary
    class_counts = combined['Classification'].value_counts()
    print("\nMAG Classification:")
    for cls, count in class_counts.items():
        print(f"  {cls}: {count}")
    
    return combined

def create_decision_matrix_plot(combined, output_dir):
    """Create scatter plot showing abundance vs coverage"""
    print("\nCreating decision matrix plot...")
    
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Color by classification
    colors = {
        'High_Abundance_High_Coverage': '#27ae60',  # Green
        'High_Abundance_Low_Coverage': '#f39c12',   # Orange
        'Low_Abundance_High_Coverage': '#3498db',   # Blue
        'Low_Abundance_Low_Coverage': '#e74c3c',    # Red
        'Incomplete_Data': '#95a5a6'                # Gray
    }
    
    for cls, color in colors.items():
        mask = combined['Classification'] == cls
        if mask.any():
            ax.scatter(combined[mask]['Mean_RA'], 
                      combined[mask]['Mean_Cov'],
                      label=cls.replace('_', ' '),
                      color=color,
                      s=100,
                      alpha=0.6,
                      edgecolors='black')
    
    # Add threshold lines
    ax.axvline(x=5, color='black', linestyle='--', alpha=0.3, label='RA threshold (5%)')
    ax.axhline(y=80, color='black', linestyle='--', alpha=0.3, label='Coverage threshold (80%)')
    
    # Add quadrant labels
    ax.text(1, 95, 'Rare but\nComplete', ha='center', fontsize=10, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))
    ax.text(15, 95, 'Abundant &\nComplete ✓', ha='center', fontsize=10, fontweight='bold',
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.5))
    ax.text(1, 40, 'Rare &\nIncomplete', ha='center', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.5))
    ax.text(15, 40, 'Abundant but\nIncomplete', ha='center', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.5))
    
    ax.set_xlabel('Mean Relative Abundance (%)', fontsize=12)
    ax.set_ylabel('Mean Coverage (%)', fontsize=12)
    ax.set_title('MAG Decision Matrix: Abundance vs Coverage', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xlim(0, combined['Mean_RA'].max() * 1.1)
    ax.set_ylim(0, 105)
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5))
    ax.grid(alpha=0.3)
    
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_decision_matrix.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def create_combined_heatmap(combined, output_dir, top_n=20):
    """Create heatmap showing both abundance and coverage"""
    print(f"\nCreating combined heatmap (top {top_n} MAGs)...")
    
    # Select top N MAGs by mean abundance
    top_mags = combined.nlargest(top_n, 'Mean_RA').index
    
    # Extract data for top MAGs
    ra_cols = [col for col in combined.columns if '_RA' in col]
    cov_cols = [col for col in combined.columns if '_Cov' in col]
    
    # Create figure with two subplots
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 10))
    
    # Abundance heatmap
    abundance_data = combined.loc[top_mags, ra_cols]
    abundance_data.columns = [col.replace('_RA', '') for col in abundance_data.columns]
    
    sns.heatmap(abundance_data, annot=True, fmt='.2f', cmap='YlOrRd',
                cbar_kws={'label': 'Relative Abundance (%)'}, ax=ax1,
                linewidths=0.5, linecolor='gray')
    ax1.set_title('Relative Abundance', fontsize=12, fontweight='bold')
    ax1.set_ylabel('MAG', fontsize=10)
    ax1.set_xlabel('Sample', fontsize=10)
    
    # Coverage heatmap
    coverage_data = combined.loc[top_mags, cov_cols]
    coverage_data.columns = [col.replace('_Cov', '') for col in coverage_data.columns]
    
    sns.heatmap(coverage_data, annot=True, fmt='.1f', cmap='RdYlGn',
                vmin=0, vmax=100, cbar_kws={'label': 'Coverage (%)'}, ax=ax2,
                linewidths=0.5, linecolor='gray')
    ax2.set_title('Coverage', fontsize=12, fontweight='bold')
    ax2.set_ylabel('')
    ax2.set_xlabel('Sample', fontsize=10)
    
    plt.suptitle(f'Top {top_n} MAGs: Abundance and Coverage', 
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'combined_abundance_coverage_heatmap.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def save_results(combined, output_dir):
    """Save combined results to file"""
    print("\nSaving results...")
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Save full combined table
    output_path = output_dir / 'combined_abundance_coverage.tsv'
    combined.to_csv(output_path, sep='\t')
    print(f"  ✓ Saved: {output_path}")
    
    # Save classified MAGs
    for cls in combined['Classification'].unique():
        if cls != 'Incomplete_Data':
            cls_mags = combined[combined['Classification'] == cls]
            cls_path = output_dir / f'{cls}_mags.tsv'
            cls_mags.to_csv(cls_path, sep='\t')
            print(f"  ✓ Saved: {cls_path}")
    
    # Save summary statistics
    summary_path = output_dir / 'summary_statistics.txt'
    with open(summary_path, 'w') as f:
        f.write("="*70 + "\n")
        f.write("  COMBINED ABUNDANCE AND COVERAGE SUMMARY\n")
        f.write("="*70 + "\n\n")
        
        f.write(f"Total MAGs: {len(combined)}\n\n")
        
        f.write("Classification Summary:\n")
        for cls, count in combined['Classification'].value_counts().items():
            pct = count / len(combined) * 100
            f.write(f"  {cls}: {count} ({pct:.1f}%)\n")
        
        f.write("\nMean Statistics:\n")
        f.write(f"  Mean Relative Abundance: {combined['Mean_RA'].mean():.2f}%\n")
        f.write(f"  Mean Coverage: {combined['Mean_Cov'].mean():.2f}%\n")
        
        f.write("\n" + "="*70 + "\n")
    
    print(f"  ✓ Saved: {summary_path}")

def main():
    args = parse_arguments()
    
    print("="*70)
    print("  Combining CoverM and SingleM Results")
    print("="*70)
    print(f"CoverM input: {args.coverm}")
    print(f"SingleM input: {args.singlem}")
    print(f"Output directory: {args.output}")
    
    # Load data
    abundance = load_coverm_data(args.coverm)
    coverage = load_singlem_data(args.singlem)
    
    # Combine
    combined = combine_data(abundance, coverage)
    
    # Classify
    combined = classify_mags(combined)
    
    # Visualize
    print("\nGenerating visualizations...")
    print("-" * 70)
    
    create_decision_matrix_plot(combined, args.output)
    create_combined_heatmap(combined, args.output)
    
    # Save results
    save_results(combined, args.output)
    
    print("\n" + "="*70)
    print("  Analysis Complete!")
    print("="*70)
    print(f"\nOutput files saved to: {args.output}")
    print("  - combined_abundance_coverage.tsv")
    print("  - mag_decision_matrix.pdf/png")
    print("  - combined_abundance_coverage_heatmap.pdf/png")
    print("  - *_mags.tsv (classified MAG lists)")
    print("  - summary_statistics.txt")
    print("\n✓ All analysis complete!")

if __name__ == '__main__':
    main()
