#!/usr/bin/env python3
"""
dna_vs_rna_heatmap_comparison_toy.py

What this script does
1) Generates *toy* input files (if they don't already exist):
   - results/mg_genes_cpm.csv
   - results/mtx_transcripts_cpm.csv
   - results/deseq2_significant_genes.csv
2) Creates a side-by-side DNA vs RNA heatmap for the top 50 "significant" genes
3) Saves:
   - figures/dna_vs_rna_heatmap_comparison.png
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# -----------------------------
# Helpers
# -----------------------------
def ensure_dirs():
    os.makedirs("results", exist_ok=True)
    os.makedirs("figures", exist_ok=True)

def zscore_rows(df: pd.DataFrame) -> pd.DataFrame:
    """Row-wise z-score (per gene), safe for constant rows."""
    mu = df.mean(axis=1)
    sd = df.std(axis=1).replace(0, np.nan)
    z = df.sub(mu, axis=0).div(sd, axis=0).fillna(0.0)
    return z

def generate_toy_inputs(
    mg_fp="results/mg_genes_cpm.csv",
    mtx_fp="results/mtx_transcripts_cpm.csv",
    sig_fp="results/deseq2_significant_genes.csv",
    n_genes=1200,
    n_samples=10,
    seed=42,
):
    """
    Create toy CPM matrices + toy DE "significant genes" table.
    If files already exist, this does nothing.
    """
    if os.path.exists(mg_fp) and os.path.exists(mtx_fp) and os.path.exists(sig_fp):
        print("Toy inputs already exist. Skipping toy-data generation.")
        return

    print("Generating toy input files in ./results/ ...")
    rng = np.random.default_rng(seed)

    genes = [f"gene_{i:05d}" for i in range(1, n_genes + 1)]
    samples = [f"S{i:02d}" for i in range(1, n_samples + 1)]

    # --- Toy CPM data (positive, heavy-tailed) ---
    # MG (DNA) and MTX (RNA) abundance on CPM-like scale
    mg_base = rng.lognormal(mean=1.6, sigma=1.0, size=(n_genes, 1))
    mtx_base = rng.lognormal(mean=1.5, sigma=1.1, size=(n_genes, 1))

    sample_effect_mg = rng.lognormal(mean=0.0, sigma=0.25, size=(1, n_samples))
    sample_effect_mt = rng.lognormal(mean=0.0, sigma=0.30, size=(1, n_samples))

    mg = mg_base @ sample_effect_mg
    mtx = mtx_base @ sample_effect_mt

    # Sprinkle a few zeros (dropouts)
    mg[rng.random(mg.shape) < 0.03] = 0.0
    mtx[rng.random(mtx.shape) < 0.04] = 0.0

    mg_df = pd.DataFrame(mg, index=genes, columns=samples)
    mtx_df = pd.DataFrame(mtx, index=genes, columns=samples)

    # --- Toy "DESeq2 significant genes" table ---
    # Create pseudo log2FC/padj and pick some genes as "significant"
    log2_ratio = np.log2((mtx_df.mean(axis=1) + 1.0) / (mg_df.mean(axis=1) + 1.0))

    # Select some "true" DE genes (up & down), then add noise
    n_de = max(60, int(0.08 * n_genes))
    de_idx = rng.choice(n_genes, size=n_de, replace=False)
    up_idx = de_idx[: n_de // 2]
    down_idx = de_idx[n_de // 2 :]

    log2fc = log2_ratio.copy()
    log2fc.iloc[up_idx] += rng.normal(loc=2.2, scale=0.4, size=len(up_idx))
    log2fc.iloc[down_idx] += rng.normal(loc=-2.0, scale=0.4, size=len(down_idx))
    log2fc += rng.normal(loc=0.0, scale=0.3, size=n_genes)

    # Fake adjusted p-values: smaller for larger |log2FC|
    strength = np.abs(log2fc.values)
    padj = np.exp(-strength)  # not real stats; just toy behavior
    padj = np.clip(padj, 1e-12, 1.0)

    sig = pd.DataFrame(
        {
            "baseMean": (mg_df.mean(axis=1) + mtx_df.mean(axis=1)) / 2.0,
            "log2FoldChange": log2fc.values,
            "padj": padj,
        },
        index=genes,
    )

    # Apply your criteria: padj < 0.05 and |log2FC| > 1
    sig = sig[(sig["padj"] < 0.05) & (np.abs(sig["log2FoldChange"]) > 1)]
    sig = sig.sort_values("padj")

    # Save
    mg_df.to_csv(mg_fp)
    mtx_df.to_csv(mtx_fp)
    sig.to_csv(sig_fp)

    print(f"  ✓ Wrote: {mg_fp}")
    print(f"  ✓ Wrote: {mtx_fp}")
    print(f"  ✓ Wrote: {sig_fp}")
    if sig.shape[0] == 0:
        print("  ⚠️ Note: toy sig_genes ended up empty (rare). Increase n_genes or adjust thresholds.")


# -----------------------------
# Main
# -----------------------------
def main():
    ensure_dirs()

    # 1) Generate toy inputs (only if missing)
    generate_toy_inputs()

    # 2) Load data
    mg_cpm = pd.read_csv("results/mg_genes_cpm.csv", index_col=0)
    mtx_cpm = pd.read_csv("results/mtx_transcripts_cpm.csv", index_col=0)
    sig_genes = pd.read_csv("results/deseq2_significant_genes.csv", index_col=0)

    if sig_genes.shape[0] == 0:
        raise SystemExit("No significant genes found in results/deseq2_significant_genes.csv (toy or real).")

    # Select top 50 genes by adjusted p-value (row order)
    top_genes = sig_genes.index[:50].tolist()

    # Filter data for these genes (keep only genes that exist in CPM tables)
    top_genes = [g for g in top_genes if g in mg_cpm.index and g in mtx_cpm.index]
    if len(top_genes) == 0:
        raise SystemExit("Top genes not found in CPM matrices. Check gene IDs match across files.")

    mg_top = mg_cpm.loc[top_genes]
    mtx_top = mtx_cpm.loc[top_genes]

    # Log transform
    mg_log = np.log2(mg_top + 1.0)
    mtx_log = np.log2(mtx_top + 1.0)

    # Z-score per gene (row-wise)
    mg_scaled = zscore_rows(mg_log)
    mtx_scaled = zscore_rows(mtx_log)

    # 3) Plot side-by-side heatmaps
    sns.set_style("white")
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 12))

    sns.heatmap(
        mg_scaled,
        cmap="RdBu_r",
        center=0,
        vmin=-2,
        vmax=2,
        cbar_kws={"label": "Z-score"},
        yticklabels=True,
        xticklabels=True,
        ax=ax1,
    )
    ax1.set_title("Metagenomic Gene Abundance (DNA)", fontsize=14, fontweight="bold")
    ax1.set_xlabel("Samples", fontsize=12)
    ax1.set_ylabel("Genes", fontsize=12)

    sns.heatmap(
        mtx_scaled,
        cmap="RdBu_r",
        center=0,
        vmin=-2,
        vmax=2,
        cbar_kws={"label": "Z-score"},
        yticklabels=True,
        xticklabels=True,
        ax=ax2,
    )
    ax2.set_title("Metatranscriptomic Expression (RNA)", fontsize=14, fontweight="bold")
    ax2.set_xlabel("Samples", fontsize=12)
    ax2.set_ylabel("")

    plt.tight_layout()
    out_fp = "figures/dna_vs_rna_heatmap_comparison.png"
    plt.savefig(out_fp, dpi=300, bbox_inches="tight")
    plt.close()

    print(f"Comparative heatmap created! ✓ Saved: {out_fp}")


if __name__ == "__main__":
    main()

