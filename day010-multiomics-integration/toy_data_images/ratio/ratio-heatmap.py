#!/usr/bin/env python3
"""
Make Expression-Ratio Heatmap (Top 50 DE genes) with *embedded toy data*
Outputs image to:
  /home/jojy-john/Jojy_Research_Sync/website_assets/projects/metagenome-analysis-series/day10-multiomics-integration/toy_data_images/

This script is self-contained:
- If the needed CSVs don't exist, it generates toy versions inside the same output folder.
- Then it creates:
  expression_ratio_heatmap.png
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# ============================================================
# OUTPUT PATH (your requested path)
# ============================================================
OUT_DIR = "/home/jojy-john/Jojy_Research_Sync/website_assets/projects/metagenome-analysis-series/day10-multiomics-integration/toy_data_images"
RESULTS_DIR = os.path.join(OUT_DIR, "results")
FIG_DIR = os.path.join(OUT_DIR, "figures")

os.makedirs(RESULTS_DIR, exist_ok=True)
os.makedirs(FIG_DIR, exist_ok=True)

# ============================================================
# Files used by the script
# ============================================================
MG_FP = os.path.join(RESULTS_DIR, "mg_genes_cpm.csv")
MTX_FP = os.path.join(RESULTS_DIR, "mtx_transcripts_cpm.csv")
EXPR_RATIO_FP = os.path.join(RESULTS_DIR, "expression_ratios.csv")
SIG_FP = os.path.join(RESULTS_DIR, "deseq2_significant_genes.csv")

# ============================================================
# Toy-data generation (only if missing)
# ============================================================
def make_toy_inputs(
    n_genes=1200,
    n_samples=10,
    seed=42,
):
    """
    Generates toy:
      - mg_genes_cpm.csv
      - mtx_transcripts_cpm.csv
      - expression_ratios.csv (per-sample log2(RNA/DNA), plus Mean_Log2_Ratio, StdDev)
      - deseq2_significant_genes.csv (toy table with padj + log2FoldChange, sorted by padj)
    """
    if all(os.path.exists(fp) for fp in [MG_FP, MTX_FP, EXPR_RATIO_FP, SIG_FP]):
        print("Toy inputs already exist — skipping toy-data generation.")
        return

    print("Generating toy inputs...")

    rng = np.random.default_rng(seed)
    genes = [f"gene_{i:05d}" for i in range(1, n_genes + 1)]
    samples = [f"S{i:02d}" for i in range(1, n_samples + 1)]

    # --- Toy CPM matrices (positive, heavy-tailed) ---
    mg_base = rng.lognormal(mean=1.6, sigma=1.0, size=(n_genes, 1))
    mtx_base = rng.lognormal(mean=1.5, sigma=1.1, size=(n_genes, 1))

    sample_effect_mg = rng.lognormal(mean=0.0, sigma=0.25, size=(1, n_samples))
    sample_effect_mt = rng.lognormal(mean=0.0, sigma=0.30, size=(1, n_samples))

    mg = mg_base @ sample_effect_mg
    mtx = mtx_base @ sample_effect_mt

    # sprinkle some zeros
    mg[rng.random(mg.shape) < 0.03] = 0.0
    mtx[rng.random(mtx.shape) < 0.04] = 0.0

    mg_df = pd.DataFrame(mg, index=genes, columns=samples)
    mtx_df = pd.DataFrame(mtx, index=genes, columns=samples)

    mg_df.to_csv(MG_FP)
    mtx_df.to_csv(MTX_FP)

    # --- Expression ratios per sample: log2((RNA+1)/(DNA+1)) ---
    ratio = np.log2((mtx_df.values + 1.0) / (mg_df.values + 1.0))

    # Inject DE-like structure for a subset of genes
    n_de = int(0.10 * n_genes)
    de_idx = rng.choice(n_genes, size=n_de, replace=False)
    up_idx = de_idx[: n_de // 2]
    down_idx = de_idx[n_de // 2 :]

    ratio[up_idx, :] += rng.normal(loc=2.2, scale=0.4, size=(len(up_idx), n_samples))
    ratio[down_idx, :] += rng.normal(loc=-2.0, scale=0.4, size=(len(down_idx), n_samples))

    # add measurement noise
    ratio += rng.normal(loc=0.0, scale=0.35, size=ratio.shape)

    expr_ratio_df = pd.DataFrame(ratio, index=genes, columns=samples)
    expr_ratio_df["Mean_Log2_Ratio"] = expr_ratio_df[samples].mean(axis=1)
    expr_ratio_df["StdDev"] = expr_ratio_df[samples].std(axis=1)
    expr_ratio_df.to_csv(EXPR_RATIO_FP)

    # --- Toy "DESeq2 significant genes" table ---
    # Create a fake log2FC and fake padj that gets smaller as |log2FC| gets larger
    mean_ctrl = mg_df.mean(axis=1)
    mean_trt = mtx_df.mean(axis=1)
    log2fc = np.log2((mean_trt + 1.0) / (mean_ctrl + 1.0)) + rng.normal(0, 0.2, size=n_genes)

    strength = np.abs(log2fc.values)
    padj = np.exp(-strength)               # toy behavior: big effects -> small padj
    padj = np.clip(padj, 1e-12, 1.0)

    sig = pd.DataFrame(
        {
            "baseMean": (mean_ctrl + mean_trt) / 2.0,
            "log2FoldChange": log2fc.values,
            "padj": padj,
        },
        index=genes,
    )

    # Apply same criteria you used: padj < 0.05 and |log2FC| > 1
    sig = sig[(sig["padj"] < 0.05) & (np.abs(sig["log2FoldChange"]) > 1)].sort_values("padj")
    sig.to_csv(SIG_FP)

    print(f"  ✓ Wrote: {MG_FP}")
    print(f"  ✓ Wrote: {MTX_FP}")
    print(f"  ✓ Wrote: {EXPR_RATIO_FP}")
    print(f"  ✓ Wrote: {SIG_FP}")
    print(f"  ✓ Significant genes (toy): {sig.shape[0]}")

# ============================================================
# Main plot
# ============================================================
def main():
    make_toy_inputs()

    # Load significant DE genes
    sig_genes = pd.read_csv(SIG_FP, index_col=0)

    if sig_genes.shape[0] == 0:
        raise SystemExit(
            f"No significant genes in {SIG_FP}. "
            "Try increasing n_genes or relaxing thresholds in toy generator."
        )

    # Select top 50 genes by adjusted p-value
    top_genes = sig_genes.index[:50].tolist()

    # Load expression ratios and subset top genes
    expression_ratios = pd.read_csv(EXPR_RATIO_FP, index_col=0)

    # Keep only sample columns (drop Mean_Log2_Ratio and StdDev if present)
    drop_cols = [c for c in ["Mean_Log2_Ratio", "StdDev"] if c in expression_ratios.columns]
    ratio_only = expression_ratios.drop(columns=drop_cols, errors="ignore")

    # Subset to top genes (keep only genes present)
    top_genes = [g for g in top_genes if g in ratio_only.index]
    if len(top_genes) == 0:
        raise SystemExit("Top genes not found in expression_ratios table. Check gene IDs match.")

    ratio_top = ratio_only.loc[top_genes]

    # Plot
    sns.set_style("white")
    plt.figure(figsize=(10, 12))
    sns.heatmap(
        ratio_top,
        cmap="RdYlGn",
        center=0,
        vmin=-3, vmax=3,
        cbar_kws={"label": "Log2(RNA/DNA)"},
        yticklabels=True,
        xticklabels=True,
    )
    plt.title("Expression Ratios: Top 50 DE Genes", fontsize=14, fontweight="bold")
    plt.xlabel("Samples", fontsize=12)
    plt.ylabel("Genes", fontsize=12)
    plt.tight_layout()

    out_png = os.path.join(OUT_DIR, "expression_ratio_heatmap.png")
    plt.savefig(out_png, dpi=300, bbox_inches="tight")
    plt.close()

    print("Expression ratio heatmap created!")
    print(f"✓ Saved: {out_png}")
    print(f"(Also wrote toy inputs under: {RESULTS_DIR} and {FIG_DIR})")

if __name__ == "__main__":
    main()

