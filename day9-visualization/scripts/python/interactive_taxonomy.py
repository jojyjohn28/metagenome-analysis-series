import pandas as pd
import numpy as np
import plotly.express as px

# ============================
# TOY DATA: full lineage taxonomy table
# ============================
np.random.seed(42)

rows = [
    ("Bacteria","Proteobacteria","Gammaproteobacteria","Oceanospirillales","Halomonadaceae"),
    ("Bacteria","Proteobacteria","Alphaproteobacteria","Rhodobacterales","Rhodobacteraceae"),
    ("Bacteria","Bacteroidota","Bacteroidia","Flavobacteriales","Flavobacteriaceae"),
    ("Bacteria","Actinobacteriota","Actinobacteria","Micrococcales","Micrococcaceae"),
    ("Bacteria","Firmicutes","Bacilli","Bacillales","Bacillaceae"),
    ("Bacteria","Cyanobacteria","Cyanobacteriia","Synechococcales","Synechococcaceae"),
]

taxonomy_full = pd.DataFrame(rows, columns=["Domain","Phylum","Class","Order","Family"])
taxonomy_full["Abundance"] = np.random.randint(50, 400, size=len(taxonomy_full))

# Sunburst
fig = px.sunburst(
    taxonomy_full,
    path=["Domain", "Phylum", "Class", "Order", "Family"],
    values="Abundance",
    title="Taxonomic Composition - Interactive Sunburst (Toy Data)"
)

fig.update_layout(width=800, height=800)
fig.write_html("taxonomy_sunburst_toy.html")
fig.show()

