#!/usr/bin/env python3
"""
Script: visualize_singlem_coverage.py
Description: Visualize MAG coverage from SingleM appraisal results
Author: github.com/jojyjohn28
Usage: python visualize_singlem_coverage.py --input singlem_results/found_mags.tsv --output figures/
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
        description='Visualize MAG coverage from SingleM results'
    )
    parser.add_argument(
        '--input', '-i',
        required=True,
        help='SingleM found_mags.tsv file'
    )
    parser.add_argument(
        '--binned-otus',
        default=None,
        help='Optional: SingleM binned_otus.tsv for detailed analysis'
    )
    parser.add_argument(
        '--output', '-o',
        default='figures',
        help='Output directory for figures (default: figures)'
    )
    
    return parser.parse_args()

def load_singlem_data(filepath):
    """Load and parse SingleM results"""
    print(f"Loading SingleM data from: {filepath}")
    
    try:
        df = pd.read_csv(filepath, sep='\t')
    except FileNotFoundError:
        print(f"ERROR: File not found: {filepath}")
        sys.exit(1)
    
    print(f"Loaded {len(df)} MAG-sample combinations")
    
    return df

def create_coverage_heatmap(df, output_dir):
    """Create MAG coverage heatmap across samples"""
    print(f"\nCreating coverage heatmap...")
    
    # Create pivot table
    if 'genome' in df.columns and 'sample' in df.columns and 'coverage' in df.columns:
        pivot = df.pivot_table(values='coverage', 
                               index='genome', 
                               columns='sample', 
                               aggfunc='mean')
    else:
        print("ERROR: Expected columns not found. Need: genome, sample, coverage")
        return
    
    # Create figure
    fig, ax = plt.subplots(figsize=(12, 10))
    
    # Create heatmap
    sns.heatmap(pivot, 
                annot=True, 
                fmt='.1f', 
                cmap='RdYlGn',
                vmin=0, vmax=100,
                cbar_kws={'label': 'Coverage (%)'},
                linewidths=0.5,
                linecolor='gray',
                ax=ax)
    
    ax.set_title('MAG Coverage Across Samples (SingleM)', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xlabel('Sample', fontsize=12)
    ax.set_ylabel('MAG', fontsize=12)
    
    # Rotate labels
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_coverage_heatmap.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    return pivot

def create_coverage_distribution(df, output_dir):
    """Create coverage distribution plots"""
    print(f"\nCreating coverage distribution plots...")
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # Extract coverage values
    coverage_values = df['coverage'].values
    
    # Histogram
    axes[0].hist(coverage_values, bins=50, color='steelblue', edgecolor='black', alpha=0.7)
    axes[0].axvline(coverage_values.mean(), color='red', linestyle='--', 
                    label=f'Mean: {coverage_values.mean():.1f}%')
    axes[0].axvline(np.median(coverage_values), color='orange', linestyle='--',
                    label=f'Median: {np.median(coverage_values):.1f}%')
    axes[0].set_xlabel('Coverage (%)', fontsize=12)
    axes[0].set_ylabel('Frequency', fontsize=12)
    axes[0].set_title('MAG Coverage Distribution', fontsize=12, fontweight='bold')
    axes[0].legend()
    axes[0].grid(alpha=0.3, axis='y')
    
    # Box plot per sample
    if 'sample' in df.columns:
        sample_data = [df[df['sample'] == s]['coverage'].values 
                      for s in df['sample'].unique()]
        axes[1].boxplot(sample_data, labels=df['sample'].unique())
        axes[1].set_xlabel('Sample', fontsize=12)
        axes[1].set_ylabel('Coverage (%)', fontsize=12)
        axes[1].set_title('Coverage Distribution per Sample', fontsize=12, fontweight='bold')
        axes[1].grid(alpha=0.3, axis='y')
        plt.setp(axes[1].xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_coverage_distribution.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def create_detection_matrix(pivot, output_dir):
    """Create binary detection matrix (MAG present/absent)"""
    print(f"\nCreating MAG detection matrix...")
    
    # Create binary matrix (>50% coverage = detected)
    threshold = 50
    binary = (pivot > threshold).astype(int)
    
    fig, ax = plt.subplots(figsize=(10, 8))
    
    sns.heatmap(binary, 
                cmap=['white', 'darkgreen'],
                cbar_kws={'label': 'Detected (>50% coverage)', 'ticks': [0, 1]},
                linewidths=0.5,
                linecolor='gray',
                ax=ax)
    
    ax.set_title(f'MAG Detection Matrix (>{threshold}% coverage)', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xlabel('Sample', fontsize=12)
    ax.set_ylabel('MAG', fontsize=12)
    
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_detection_matrix.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def create_mag_quality_scatter(df, output_dir):
    """Create scatter plot of MAG coverage vs detection frequency"""
    print(f"\nCreating MAG quality scatter plot...")
    
    # Calculate mean coverage and detection frequency per MAG
    mag_stats = df.groupby('genome').agg({
        'coverage': 'mean',
        'sample': 'count'
    }).reset_index()
    mag_stats.columns = ['MAG', 'Mean_Coverage', 'Detection_Frequency']
    
    fig, ax = plt.subplots(figsize=(10, 8))
    
    scatter = ax.scatter(mag_stats['Detection_Frequency'], 
                        mag_stats['Mean_Coverage'],
                        s=100, 
                        alpha=0.6,
                        c=mag_stats['Mean_Coverage'],
                        cmap='RdYlGn',
                        edgecolors='black')
    
    # Add threshold lines
    n_samples = df['sample'].nunique()
    ax.axhline(y=90, color='green', linestyle='--', alpha=0.5, label='High coverage (90%)')
    ax.axhline(y=50, color='orange', linestyle='--', alpha=0.5, label='Medium coverage (50%)')
    ax.axvline(x=n_samples, color='blue', linestyle='--', alpha=0.5, label='All samples')
    
    ax.set_xlabel('Detection Frequency (# samples)', fontsize=12)
    ax.set_ylabel('Mean Coverage (%)', fontsize=12)
    ax.set_title('MAG Quality: Coverage vs Detection', fontsize=14, fontweight='bold', pad=20)
    ax.legend()
    ax.grid(alpha=0.3)
    
    plt.colorbar(scatter, ax=ax, label='Mean Coverage (%)')
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_quality_scatter.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def print_coverage_summary(df):
    """Print coverage summary statistics"""
    print("\n" + "="*70)
    print("  MAG COVERAGE SUMMARY STATISTICS")
    print("="*70)
    
    print(f"\nDataset Overview:")
    print(f"  Unique MAGs: {df['genome'].nunique()}")
    print(f"  Unique samples: {df['sample'].nunique()}")
    print(f"  Total MAG-sample pairs: {len(df)}")
    
    print(f"\nCoverage Statistics:")
    print(f"  Mean coverage: {df['coverage'].mean():.1f}%")
    print(f"  Median coverage: {df['coverage'].median():.1f}%")
    print(f"  Std deviation: {df['coverage'].std():.1f}%")
    print(f"  Min coverage: {df['coverage'].min():.1f}%")
    print(f"  Max coverage: {df['coverage'].max():.1f}%")
    
    print(f"\nMAG Quality Classification:")
    high_cov = (df['coverage'] > 90).sum()
    med_cov = ((df['coverage'] > 50) & (df['coverage'] <= 90)).sum()
    low_cov = (df['coverage'] <= 50).sum()
    
    print(f"  High coverage (>90%): {high_cov} ({high_cov/len(df)*100:.1f}%)")
    print(f"  Medium coverage (50-90%): {med_cov} ({med_cov/len(df)*100:.1f}%)")
    print(f"  Low coverage (<50%): {low_cov} ({low_cov/len(df)*100:.1f}%)")
    
    # Per-MAG statistics
    mag_coverage = df.groupby('genome')['coverage'].mean().sort_values(ascending=False)
    
    print(f"\nTop 5 Most Covered MAGs:")
    for i, (mag, cov) in enumerate(mag_coverage.head(5).items(), 1):
        n_samples = len(df[df['genome'] == mag])
        print(f"  {i}. {mag}: {cov:.1f}% (detected in {n_samples} samples)")
    
    print(f"\nBottom 5 Least Covered MAGs:")
    for i, (mag, cov) in enumerate(mag_coverage.tail(5).items(), 1):
        n_samples = len(df[df['genome'] == mag])
        print(f"  {i}. {mag}: {cov:.1f}% (detected in {n_samples} samples)")
    
    # Detection frequency
    detection_freq = df.groupby('genome')['sample'].count().sort_values(ascending=False)
    total_samples = df['sample'].nunique()
    
    print(f"\nMAG Detection Frequency:")
    print(f"  MAGs in all samples: {(detection_freq == total_samples).sum()}")
    print(f"  MAGs in >50% samples: {(detection_freq > total_samples/2).sum()}")
    print(f"  MAGs in only 1 sample: {(detection_freq == 1).sum()}")
    
    print("="*70)

def main():
    args = parse_arguments()
    
    # Create output directory
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("="*70)
    print("  MAG Coverage Visualization (SingleM)")
    print("="*70)
    print(f"Input: {args.input}")
    print(f"Output: {output_dir}")
    
    # Load data
    df = load_singlem_data(args.input)
    
    # Print statistics
    print_coverage_summary(df)
    
    # Create visualizations
    print("\nGenerating visualizations...")
    print("-" * 70)
    
    pivot = create_coverage_heatmap(df, output_dir)
    create_coverage_distribution(df, output_dir)
    
    if pivot is not None:
        create_detection_matrix(pivot, output_dir)
    
    create_mag_quality_scatter(df, output_dir)
    
    print("\n" + "="*70)
    print("  Visualization Complete!")
    print("="*70)
    print(f"\nOutput files saved to: {output_dir}")
    print("  - mag_coverage_heatmap.pdf/png")
    print("  - mag_coverage_distribution.pdf/png")
    print("  - mag_detection_matrix.pdf/png")
    print("  - mag_quality_scatter.pdf/png")
    print("\n✓ All visualizations generated successfully!")

if __name__ == '__main__':
    main()
