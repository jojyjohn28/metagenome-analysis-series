import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# ============================
# TOY DATA: metadata + alpha diversity (Sample-level)
# ============================
np.random.seed(42)

n_samples = 30
samples = [f"S{i+1:02d}" for i in range(n_samples)]

metadata = pd.DataFrame({
    "Sample": samples,
    "Treatment": np.random.choice(["Low", "Medium", "High"], size=n_samples),
    "pH": np.random.normal(7.8, 0.25, size=n_samples),
    "Temperature": np.random.normal(20, 4, size=n_samples),
}).set_index("Sample")

# Toy diversity with treatment effects
div_rows = []
for s in samples:
    t = metadata.loc[s, "Treatment"]
    if t == "Low":
        shannon = np.random.normal(4.2, 0.25)
        simpson = np.random.normal(0.90, 0.02)
    elif t == "Medium":
        shannon = np.random.normal(4.8, 0.25)
        simpson = np.random.normal(0.93, 0.02)
    else:
        shannon = np.random.normal(4.0, 0.25)
        simpson = np.random.normal(0.88, 0.02)

    div_rows.append([s, shannon, simpson])

diversity = pd.DataFrame(div_rows, columns=["Sample", "Shannon", "Simpson"]).set_index("Sample")

# Combine data
data_combined = pd.concat([diversity, metadata[["Treatment", "pH", "Temperature"]]], axis=1).reset_index()

# Pairplot
g = sns.pairplot(
    data_combined,
    hue="Treatment",
    vars=["Shannon", "Simpson", "pH", "Temperature"],
    diag_kind="kde",
    plot_kws={"alpha": 0.6, "s": 50, "edgecolor": "k"},
    height=2.5
)

g.fig.suptitle("Multivariate Relationships (Toy Data)", y=1.02, fontsize=16, fontweight="bold")
plt.savefig("diversity_environment_pairplot_toy.pdf", dpi=300, bbox_inches="tight")
plt.savefig("diversity_environment_pairplot_toy.png", dpi=300, bbox_inches="tight")
plt.show()

