import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# ============================
# TOY DATA: abundance (MAG x Sample) + metadata (Sample-level env)
# ============================
np.random.seed(42)

n_mags = 25
n_samples = 18

mags = [f"MAG_{i+1:02d}" for i in range(n_mags)]
samples = [f"S{i+1:02d}" for i in range(n_samples)]

# Toy metadata
metadata = pd.DataFrame({
    "Sample": samples,
    "Treatment": np.random.choice(["FL", "PA"], size=n_samples),
    "pH": np.random.normal(7.8, 0.3, size=n_samples),
    "Temperature": np.random.normal(18, 3, size=n_samples),
    "Salinity": np.random.normal(20, 7, size=n_samples),
}).set_index("Sample")

# Toy abundance with some structured signal (so correlations exist)
# Base abundance: positive values with skew
abund = np.random.gamma(shape=2, scale=60, size=(n_mags, n_samples))

# Make some MAGs correlate with environment
abund[0:5, :] += (metadata["Salinity"].values * 8)          # MAG_01-05 ~ Salinity+
abund[5:10, :] += (metadata["Temperature"].values * 10)     # MAG_06-10 ~ Temp+
abund[10:15, :] += ((8.5 - metadata["pH"].values) * 120)    # MAG_11-15 ~ pH-

abundance = pd.DataFrame(abund, index=mags, columns=samples)

# ============================
# Correlations: MAG x environment variable matrix
# ============================
env = metadata[["pH", "Temperature", "Salinity"]]

corr = pd.DataFrame(
    {col: abundance.T.corrwith(env[col]) for col in env.columns},
    index=abundance.index
)

# Plot
plt.figure(figsize=(10, 8))
sns.heatmap(
    corr,
    annot=True, fmt=".2f",
    cmap="RdBu_r",
    center=0, vmin=-1, vmax=1,
    linewidths=0.5,
    cbar_kws={"label": "Correlation coefficient"}
)
plt.title("MAG–Environment Correlations (Toy Data)", fontsize=14, fontweight="bold")
plt.xlabel("Environmental variable")
plt.ylabel("MAG")
plt.tight_layout()
plt.savefig("mag_environment_correlations_toy.pdf", dpi=300, bbox_inches="tight")
plt.savefig("mag_environment_correlations_toy.png", dpi=300, bbox_inches="tight")
plt.show()

