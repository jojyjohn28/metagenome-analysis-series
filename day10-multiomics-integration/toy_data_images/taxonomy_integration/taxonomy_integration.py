#!/usr/bin/env python3
"""
Toy Taxonomic Integration (DNA vs RNA activity)

Self-contained script:
- Generates toy taxonomy abundance tables if missing:
    data/mg_taxonomy_abundance.tsv
    data/mtx_taxonomy_abundance.tsv
- Runs your activity-score analysis
- Saves outputs to your requested path:

/home/jojy-john/Jojy_Research_Sync/website_assets/projects/metagenome-analysis-series/day10-multiomics-integration/toy_data_images/

Creates:
  results/taxonomic_activity_scores.csv
  figures/top_active_species.png
  figures/species_abundance_vs_activity.png
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# ============================================================
# Base path (your requested path)
# ============================================================
BASE_DIR = "/home/jojy-john/Jojy_Research_Sync/website_assets/projects/metagenome-analysis-series/day10-multiomics-integration/toy_data_images"
DATA_DIR = os.path.join(BASE_DIR, "data")
RESULTS_DIR = os.path.join(BASE_DIR, "results")
FIG_DIR = os.path.join(BASE_DIR, "figures")

os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(RESULTS_DIR, exist_ok=True)
os.makedirs(FIG_DIR, exist_ok=True)

MG_FP = os.path.join(DATA_DIR, "mg_taxonomy_abundance.tsv")
MTX_FP = os.path.join(DATA_DIR, "mtx_taxonomy_abundance.tsv")

# ============================================================
# Toy data generator (only if missing)
# ============================================================
def generate_toy_taxa(n_taxa=120, n_samples=8, seed=11):
    if os.path.exists(MG_FP) and os.path.exists(MTX_FP):
        print("Toy taxonomy files already exist. Skipping generation.")
        return

    print("Generating toy taxonomy abundance tables...")

    rng = np.random.default_rng(seed)
    samples = [f"S{i:02d}" for i in range(1, n_samples + 1)]

    # Mix of species-like names (so plots look realistic)
    genera = [
        "Alteromonas", "Vibrio", "Pelagibacter", "Roseobacter", "Flavobacterium",
        "Pseudomonas", "Shewanella", "Marinobacter", "Candidatus_Actinomarina",
        "Synechococcus", "Prochlorococcus", "Nitrosopumilus", "Nitrospina",
        "SAR86", "SAR11", "SAR116", "Rhodobacter", "Bacteroides", "Sphingomonas",
        "Loktanella", "Winogradskyella", "Polaribacter", "Aurantivirga",
        "Cytophaga", "Planctomyces", "Ruegeria", "Acinetobacter"
    ]

    # Create taxa labels
    taxa = []
    for i in range(n_taxa):
        g = genera[i % len(genera)]
        taxa.append(f"{g} sp. strain_{i+1:03d}")

    # Heavy-tailed base abundances (counts-like, not yet relative)
    mg_base = rng.lognormal(mean=4.0, sigma=1.2, size=(n_taxa, 1))
    mtx_base = rng.lognormal(mean=4.0, sigma=1.3, size=(n_taxa, 1))

    # Sample effects
    mg_eff = rng.lognormal(mean=0.0, sigma=0.35, size=(1, n_samples))
    mtx_eff = rng.lognormal(mean=0.0, sigma=0.35, size=(1, n_samples))

    mg = mg_base @ mg_eff
    mtx = mtx_base @ mtx_eff

    # Inject biological structure:
    # - some taxa: "rare but active" (low DNA, high RNA)
    # - some taxa: "abundant but inactive" (high DNA, low RNA)
    rare_active = rng.choice(n_taxa, size=int(0.12 * n_taxa), replace=False)
    remaining = [i for i in range(n_taxa) if i not in set(rare_active)]
    abundant_inactive = rng.choice(remaining, size=int(0.12 * n_taxa), replace=False)

    mg[rare_active, :] *= 0.15
    mtx[rare_active, :] *= 4.5

    mg[abundant_inactive, :] *= 3.5
    mtx[abundant_inactive, :] *= 0.35

    # sprinkle zeros (dropouts)
    mg[rng.random(mg.shape) < 0.02] = 0.0
    mtx[rng.random(mtx.shape) < 0.03] = 0.0

    mg_df = pd.DataFrame(mg, index=taxa, columns=samples)
    mtx_df = pd.DataFrame(mtx, index=taxa, columns=samples)

    mg_df.to_csv(MG_FP, sep="\t")
    mtx_df.to_csv(MTX_FP, sep="\t")

    print(f"  ✓ Wrote: {MG_FP}")
    print(f"  ✓ Wrote: {MTX_FP}")

# ============================================================
# Main analysis (your logic, path-adjusted)
# ============================================================
def main():
    generate_toy_taxa()

    # Load taxonomic abundances
    mg_taxa = pd.read_csv(MG_FP, sep='\t', index_col=0)
    mtx_taxa = pd.read_csv(MTX_FP, sep='\t', index_col=0)

    # Normalize to relative abundance (%)
    mg_taxa_rel = (mg_taxa / mg_taxa.sum(axis=0)) * 100
    mtx_taxa_rel = (mtx_taxa / mtx_taxa.sum(axis=0)) * 100

    # Calculate activity scores
    common_taxa = mg_taxa_rel.index.intersection(mtx_taxa_rel.index)

    activity_scores = pd.DataFrame()
    for taxon in common_taxa:
        mg_mean = mg_taxa_rel.loc[taxon].mean()
        mtx_mean = mtx_taxa_rel.loc[taxon].mean()

        activity_scores.loc[taxon, 'DNA_Abundance'] = mg_mean
        activity_scores.loc[taxon, 'RNA_Activity'] = mtx_mean
        activity_scores.loc[taxon, 'Activity_Score'] = mtx_mean / (mg_mean + 0.01)
        activity_scores.loc[taxon, 'Log2_Ratio'] = np.log2((mtx_mean + 0.01) / (mg_mean + 0.01))

    # Sort by activity score
    activity_scores = activity_scores.sort_values('Activity_Score', ascending=False)

    # Save results
    out_csv = os.path.join(RESULTS_DIR, "taxonomic_activity_scores.csv")
    activity_scores.to_csv(out_csv)

    # Classify species
    highly_active = activity_scores[activity_scores['Activity_Score'] > 2]
    dormant = activity_scores[activity_scores['Activity_Score'] < 0.5]

    print(f"Highly active species (activity > 2): {len(highly_active)}")
    print(f"Dormant species (activity < 0.5): {len(dormant)}")

    # --------------------------------------------------------
    # Plot 1: Top 20 most active species (DNA vs RNA bars)
    # --------------------------------------------------------
    top20_active = activity_scores.head(20)

    fig, ax = plt.subplots(figsize=(12, 8))
    x = np.arange(len(top20_active))
    width = 0.35

    ax.barh(x - width/2, top20_active['DNA_Abundance'], width, label='DNA Abundance')
    ax.barh(x + width/2, top20_active['RNA_Activity'], width, label='RNA Activity')

    ax.set_yticks(x)
    ax.set_yticklabels([t[:60] for t in top20_active.index], fontsize=9)
    ax.set_xlabel('Relative Abundance (%)', fontsize=12)
    ax.set_title('Top 20 Most Active Species', fontsize=14, fontweight='bold')
    ax.legend()
    ax.invert_yaxis()

    plt.tight_layout()
    out_png1 = os.path.join(FIG_DIR, "top_active_species.png")
    plt.savefig(out_png1, dpi=300, bbox_inches='tight')
    plt.close()

    # --------------------------------------------------------
    # Plot 2: Quadrant scatter (DNA abundance vs RNA activity)
    # --------------------------------------------------------
    plt.figure(figsize=(10, 10))
    plt.scatter(activity_scores['DNA_Abundance'],
                activity_scores['RNA_Activity'],
                alpha=0.5, s=50)

    # Reference lines (medians)
    plt.axhline(y=activity_scores['RNA_Activity'].median(),
                linestyle='--', alpha=0.6)
    plt.axvline(x=activity_scores['DNA_Abundance'].median(),
                linestyle='--', alpha=0.6)

    # Quadrant annotations
    plt.text(0.02, 0.98, 'Rare but Active', transform=plt.gca().transAxes,
             fontsize=12, verticalalignment='top',
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    plt.text(0.98, 0.98, 'Abundant & Active', transform=plt.gca().transAxes,
             fontsize=12, verticalalignment='top', horizontalalignment='right',
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.5))
    plt.text(0.02, 0.02, 'Rare & Inactive', transform=plt.gca().transAxes,
             fontsize=12, verticalalignment='bottom',
             bbox=dict(boxstyle='round', facecolor='lightgray', alpha=0.5))
    plt.text(0.98, 0.02, 'Abundant but Inactive', transform=plt.gca().transAxes,
             fontsize=12, verticalalignment='bottom', horizontalalignment='right',
             bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.5))

    plt.xlabel('DNA Abundance (%)', fontsize=12)
    plt.ylabel('RNA Activity (%)', fontsize=12)
    plt.title('Species Abundance vs Activity', fontsize=14, fontweight='bold')

    # Log scales (avoid errors: remove zeros)
    plt.xscale('log')
    plt.yscale('log')

    plt.tight_layout()
    out_png2 = os.path.join(FIG_DIR, "species_abundance_vs_activity.png")
    plt.savefig(out_png2, dpi=300)
    plt.close()

    print("Taxonomic integration complete!")
    print(f"✓ Saved results: {out_csv}")
    print(f"✓ Saved figures: {out_png1} and {out_png2}")

if __name__ == "__main__":
    main()

