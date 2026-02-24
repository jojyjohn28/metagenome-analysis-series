#!/usr/bin/env python3
"""
Toy Pathway Activity Analysis (DNA vs RNA)

Outputs to:
 /home/jojy-john/Jojy_Research_Sync/website_assets/projects/metagenome-analysis-series/day10-multiomics-integration/toy_data_images/

Creates:
 - data/mg_pathway_abundance.tsv
 - data/mtx_pathway_abundance.tsv
 - results/pathway_expression_ratios.csv
 - pathway_activity_comparison.png
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# ============================================================
# Paths
# ============================================================
BASE_DIR = "/home/jojy-john/Jojy_Research_Sync/website_assets/projects/metagenome-analysis-series/day10-multiomics-integration/toy_data_images"
DATA_DIR = os.path.join(BASE_DIR, "data")
RESULTS_DIR = os.path.join(BASE_DIR, "results")

os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(RESULTS_DIR, exist_ok=True)

MG_FP = os.path.join(DATA_DIR, "mg_pathway_abundance.tsv")
MTX_FP = os.path.join(DATA_DIR, "mtx_pathway_abundance.tsv")

# ============================================================
# Generate Toy Data (if missing)
# ============================================================
def generate_toy_pathway_data(n_pathways=150, n_samples=8, seed=7):

    if os.path.exists(MG_FP) and os.path.exists(MTX_FP):
        print("Toy pathway files already exist. Skipping generation.")
        return

    print("Generating toy pathway abundance tables...")

    rng = np.random.default_rng(seed)

    pathways = [f"Pathway_{i:03d}_Metabolism_Process" for i in range(1, n_pathways + 1)]
    samples = [f"S{i:02d}" for i in range(1, n_samples + 1)]

    # Generate DNA and RNA abundances
    mg_base = rng.lognormal(mean=4.0, sigma=1.0, size=(n_pathways, 1))
    mtx_base = rng.lognormal(mean=4.0, sigma=1.2, size=(n_pathways, 1))

    sample_effect_mg = rng.lognormal(mean=0.0, sigma=0.3, size=(1, n_samples))
    sample_effect_mtx = rng.lognormal(mean=0.0, sigma=0.3, size=(1, n_samples))

    mg = mg_base @ sample_effect_mg
    mtx = mtx_base @ sample_effect_mtx

    # Inject biological structure (some pathways highly active, some repressed)
    active_idx = rng.choice(n_pathways, size=int(0.15*n_pathways), replace=False)
    inactive_idx = rng.choice([i for i in range(n_pathways) if i not in active_idx],
                              size=int(0.15*n_pathways), replace=False)

    mtx[active_idx] *= 4   # highly expressed
    mtx[inactive_idx] *= 0.25  # repressed

    mg_df = pd.DataFrame(mg, index=pathways, columns=samples)
    mtx_df = pd.DataFrame(mtx, index=pathways, columns=samples)

    mg_df.to_csv(MG_FP, sep="\t")
    mtx_df.to_csv(MTX_FP, sep="\t")

    print("✓ Toy pathway files written.")

# ============================================================
# Main Analysis
# ============================================================
def main():

    generate_toy_pathway_data()

    # Load pathway abundances
    mg_pathways = pd.read_csv(MG_FP, sep='\t', index_col=0)
    mtx_pathways = pd.read_csv(MTX_FP, sep='\t', index_col=0)

    # Normalize to CPM
    mg_pathways_cpm = (mg_pathways / mg_pathways.sum(axis=0)) * 1e6
    mtx_pathways_cpm = (mtx_pathways / mtx_pathways.sum(axis=0)) * 1e6

    # Find common pathways
    common_pathways = mg_pathways_cpm.index.intersection(mtx_pathways_cpm.index)
    print(f"Common pathways: {len(common_pathways)}")

    # Calculate pathway expression ratios
    pathway_ratios = pd.DataFrame()

    for pathway in common_pathways:
        mg_mean = mg_pathways_cpm.loc[pathway].mean()
        mtx_mean = mtx_pathways_cpm.loc[pathway].mean()

        if mg_mean > 0:
            ratio = np.log2((mtx_mean + 1) / (mg_mean + 1))
            pathway_ratios.loc[pathway, 'Log2_Ratio'] = ratio
            pathway_ratios.loc[pathway, 'Mean_DNA'] = mg_mean
            pathway_ratios.loc[pathway, 'Mean_RNA'] = mtx_mean

    pathway_ratios = pathway_ratios.sort_values('Log2_Ratio', ascending=False)

    # Save results
    out_csv = os.path.join(RESULTS_DIR, "pathway_expression_ratios.csv")
    pathway_ratios.to_csv(out_csv)

    # Visualize
    top_active = pathway_ratios.head(20)
    top_inactive = pathway_ratios.tail(20)

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8))

    # Top active
    y_pos = np.arange(len(top_active))
    ax1.barh(y_pos, top_active['Log2_Ratio'], color='forestgreen', alpha=0.7)
    ax1.set_yticks(y_pos)
    ax1.set_yticklabels([p[:50] for p in top_active.index], fontsize=9)
    ax1.set_xlabel('Log2(RNA/DNA)')
    ax1.set_title('Top 20 Most Active Pathways', fontweight='bold')
    ax1.axvline(x=0, color='red', linestyle='--', alpha=0.5)
    ax1.invert_yaxis()

    # Top inactive
    y_pos2 = np.arange(len(top_inactive))
    ax2.barh(y_pos2, top_inactive['Log2_Ratio'], color='firebrick', alpha=0.7)
    ax2.set_yticks(y_pos2)
    ax2.set_yticklabels([p[:50] for p in top_inactive.index], fontsize=9)
    ax2.set_xlabel('Log2(RNA/DNA)')
    ax2.set_title('Top 20 Least Active Pathways', fontweight='bold')
    ax2.axvline(x=0, color='red', linestyle='--', alpha=0.5)
    ax2.invert_yaxis()

    plt.tight_layout()

    out_png = os.path.join(BASE_DIR, "pathway_activity_comparison.png")
    plt.savefig(out_png, dpi=300, bbox_inches='tight')
    plt.close()

    print("✓ Pathway analysis complete!")
    print(f"✓ Figure saved to: {out_png}")
    print(f"✓ Results saved to: {out_csv}")

if __name__ == "__main__":
    main()

