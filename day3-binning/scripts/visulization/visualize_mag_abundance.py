#!/usr/bin/env python3
"""
Script: visualize_mag_abundance.py
Description: Create publication-quality abundance heatmaps and composition plots
Author: github.com/jojyjohn28
Usage: python visualize_mag_abundance.py --input mag_abundance/mag_abundance_table.tsv --output figures/
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
        description='Visualize MAG abundance from CoverM output'
    )
    parser.add_argument(
        '--input', '-i',
        required=True,
        help='CoverM abundance table (mag_abundance_table.tsv)'
    )
    parser.add_argument(
        '--output', '-o',
        default='figures',
        help='Output directory for figures (default: figures)'
    )
    parser.add_argument(
        '--min-abundance',
        type=float,
        default=0.1,
        help='Minimum relative abundance to display (default: 0.1%%)'
    )
    parser.add_argument(
        '--top-n',
        type=int,
        default=20,
        help='Number of top MAGs to display in heatmap (default: 20)'
    )
    
    return parser.parse_args()

def load_abundance_data(filepath):
    """Load and parse CoverM abundance table"""
    print(f"Loading abundance data from: {filepath}")
    
    df = pd.read_csv(filepath, sep='\t')
    
    # Extract relative abundance columns
    ra_cols = [col for col in df.columns if 'Relative Abundance' in col]
    
    if not ra_cols:
        print("ERROR: No 'Relative Abundance' columns found")
        sys.exit(1)
    
    # Create clean dataframe
    abundance_df = df[['Genome'] + ra_cols].copy()
    
    # Clean column names (extract sample names)
    clean_cols = ['MAG'] + [col.split()[0] for col in ra_cols]
    abundance_df.columns = clean_cols
    
    # Set MAG as index
    abundance_df = abundance_df.set_index('MAG')
    
    print(f"Loaded {len(abundance_df)} MAGs across {len(abundance_df.columns)} samples")
    
    return abundance_df

def create_abundance_heatmap(df, output_dir, top_n=20):
    """Create abundance heatmap for top N MAGs"""
    print(f"\nCreating abundance heatmap (top {top_n} MAGs)...")
    
    # Calculate mean abundance across samples
    df_mean = df.mean(axis=1).sort_values(ascending=False)
    
    # Select top N MAGs
    top_mags = df_mean.head(top_n).index
    df_top = df.loc[top_mags]
    
    # Create figure
    fig, ax = plt.subplots(figsize=(12, 10))
    
    # Create heatmap
    sns.heatmap(df_top, 
                annot=True, 
                fmt='.2f', 
                cmap='YlOrRd',
                cbar_kws={'label': 'Relative Abundance (%)'},
                linewidths=0.5,
                linecolor='gray',
                ax=ax)
    
    ax.set_title(f'Top {top_n} MAG Relative Abundance Across Samples', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xlabel('Sample', fontsize=12)
    ax.set_ylabel('MAG', fontsize=12)
    
    # Rotate x labels
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_abundance_heatmap.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def create_composition_barplot(df, output_dir, min_abundance=0.1):
    """Create stacked bar chart showing community composition"""
    print(f"\nCreating composition stacked bar chart...")
    
    # Filter MAGs by minimum abundance
    df_filtered = df[(df > min_abundance).any(axis=1)]
    
    # Group low-abundance MAGs
    other_abundance = df[~df.index.isin(df_filtered.index)].sum()
    
    if not other_abundance.empty and other_abundance.sum() > 0:
        df_filtered.loc['Other (<{:.1f}%)'.format(min_abundance)] = other_abundance
    
    # Create figure
    fig, ax = plt.subplots(figsize=(12, 7))
    
    # Create stacked bar chart
    df_filtered.T.plot(kind='bar', 
                       stacked=True, 
                       ax=ax,
                       colormap='tab20',
                       width=0.8)
    
    ax.set_title('MAG Community Composition Across Samples', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xlabel('Sample', fontsize=12)
    ax.set_ylabel('Relative Abundance (%)', fontsize=12)
    ax.legend(title='MAG', bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=8)
    ax.set_ylim(0, 100)
    
    # Add grid
    ax.grid(axis='y', alpha=0.3, linestyle='--')
    
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_composition_barplot.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def create_abundance_distribution(df, output_dir):
    """Create histogram of abundance distribution"""
    print(f"\nCreating abundance distribution plots...")
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # Flatten all abundance values
    all_abundances = df.values.flatten()
    all_abundances = all_abundances[all_abundances > 0]  # Remove zeros
    
    # Histogram (linear scale)
    axes[0].hist(all_abundances, bins=50, color='steelblue', edgecolor='black', alpha=0.7)
    axes[0].axvline(all_abundances.mean(), color='red', linestyle='--', 
                    label=f'Mean: {all_abundances.mean():.2f}%')
    axes[0].axvline(np.median(all_abundances), color='orange', linestyle='--',
                    label=f'Median: {np.median(all_abundances):.2f}%')
    axes[0].set_xlabel('Relative Abundance (%)', fontsize=12)
    axes[0].set_ylabel('Frequency', fontsize=12)
    axes[0].set_title('MAG Abundance Distribution (Linear)', fontsize=12, fontweight='bold')
    axes[0].legend()
    axes[0].grid(alpha=0.3, axis='y')
    
    # Histogram (log scale)
    axes[1].hist(all_abundances, bins=50, color='coral', edgecolor='black', alpha=0.7)
    axes[1].axvline(all_abundances.mean(), color='red', linestyle='--', 
                    label=f'Mean: {all_abundances.mean():.2f}%')
    axes[1].axvline(np.median(all_abundances), color='orange', linestyle='--',
                    label=f'Median: {np.median(all_abundances):.2f}%')
    axes[1].set_xlabel('Relative Abundance (%)', fontsize=12)
    axes[1].set_ylabel('Frequency (log scale)', fontsize=12)
    axes[1].set_title('MAG Abundance Distribution (Log)', fontsize=12, fontweight='bold')
    axes[1].set_yscale('log')
    axes[1].legend()
    axes[1].grid(alpha=0.3, axis='y')
    
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'mag_abundance_distribution.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def create_sample_comparison(df, output_dir):
    """Create sample-to-sample comparison plot"""
    print(f"\nCreating sample comparison plot...")
    
    # Calculate correlation matrix
    corr = df.T.corr()
    
    # Create figure
    fig, ax = plt.subplots(figsize=(10, 8))
    
    # Create heatmap
    sns.heatmap(corr, 
                annot=True, 
                fmt='.2f', 
                cmap='coolwarm',
                center=0,
                vmin=-1, vmax=1,
                cbar_kws={'label': 'Pearson Correlation'},
                linewidths=0.5,
                ax=ax)
    
    ax.set_title('Sample-to-Sample MAG Abundance Correlation', 
                 fontsize=14, fontweight='bold', pad=20)
    
    plt.tight_layout()
    
    # Save
    output_path = Path(output_dir) / 'sample_correlation.pdf'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.savefig(output_path.with_suffix('.png'), dpi=300, bbox_inches='tight')
    
    print(f"  ✓ Saved: {output_path}")
    plt.close()

def print_summary_statistics(df):
    """Print summary statistics"""
    print("\n" + "="*70)
    print("  MAG ABUNDANCE SUMMARY STATISTICS")
    print("="*70)
    
    print(f"\nDataset Overview:")
    print(f"  Total MAGs: {len(df)}")
    print(f"  Total samples: {len(df.columns)}")
    
    print(f"\nAbundance Statistics (all MAGs, all samples):")
    all_abundances = df.values.flatten()
    all_abundances = all_abundances[all_abundances > 0]
    
    print(f"  Mean: {all_abundances.mean():.2f}%")
    print(f"  Median: {np.median(all_abundances):.2f}%")
    print(f"  Std Dev: {all_abundances.std():.2f}%")
    print(f"  Min: {all_abundances.min():.2f}%")
    print(f"  Max: {all_abundances.max():.2f}%")
    
    print(f"\nMAG Detection Across Samples:")
    print(f"  MAGs with >10% abundance (any sample): {(df > 10).any(axis=1).sum()}")
    print(f"  MAGs with >5% abundance (any sample): {(df > 5).any(axis=1).sum()}")
    print(f"  MAGs with >1% abundance (any sample): {(df > 1).any(axis=1).sum()}")
    print(f"  MAGs with >0.1% abundance (any sample): {(df > 0.1).any(axis=1).sum()}")
    
    print(f"\nTop 5 Most Abundant MAGs (mean across samples):")
    top5 = df.mean(axis=1).nlargest(5)
    for i, (mag, abund) in enumerate(top5.items(), 1):
        print(f"  {i}. {mag}: {abund:.2f}%")
    
    print("="*70)

def main():
    args = parse_arguments()
    
    # Create output directory
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("="*70)
    print("  MAG Abundance Visualization")
    print("="*70)
    print(f"Input: {args.input}")
    print(f"Output: {output_dir}")
    print(f"Minimum abundance: {args.min_abundance}%")
    print(f"Top N MAGs: {args.top_n}")
    
    # Load data
    df = load_abundance_data(args.input)
    
    # Print statistics
    print_summary_statistics(df)
    
    # Create visualizations
    print("\nGenerating visualizations...")
    print("-" * 70)
    
    create_abundance_heatmap(df, output_dir, top_n=args.top_n)
    create_composition_barplot(df, output_dir, min_abundance=args.min_abundance)
    create_abundance_distribution(df, output_dir)
    create_sample_comparison(df, output_dir)
    
    print("\n" + "="*70)
    print("  Visualization Complete!")
    print("="*70)
    print(f"\nOutput files saved to: {output_dir}")
    print("  - mag_abundance_heatmap.pdf/png")
    print("  - mag_composition_barplot.pdf/png")
    print("  - mag_abundance_distribution.pdf/png")
    print("  - sample_correlation.pdf/png")
    print("\n✓ All visualizations generated successfully!")

if __name__ == '__main__':
    main()
