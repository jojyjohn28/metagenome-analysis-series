import plotly.graph_objects as go
import pandas as pd
import numpy as np

# ============================
# Create TOY NMDS data
# ============================

np.random.seed(42)

treatments = ['FL_Low', 'FL_High', 'PA_Low', 'PA_High']
samples_per_group = 8

data = []

for t in treatments:
    for i in range(samples_per_group):
        
        # Create structured separation
        if t == 'FL_Low':
            x = np.random.normal(-1.5, 0.3)
            y = np.random.normal(1.5, 0.3)
        elif t == 'FL_High':
            x = np.random.normal(1.5, 0.3)
            y = np.random.normal(1.5, 0.3)
        elif t == 'PA_Low':
            x = np.random.normal(-1.5, 0.3)
            y = np.random.normal(-1.5, 0.3)
        else:  # PA_High
            x = np.random.normal(1.5, 0.3)
            y = np.random.normal(-1.5, 0.3)
        
        sample_name = f"{t}_S{i+1}"
        data.append([sample_name, t, x, y])

ordination = pd.DataFrame(
    data,
    columns=['Sample', 'Treatment', 'NMDS1', 'NMDS2']
)

print("Toy NMDS preview:")
print(ordination.head())


# ============================
# Interactive NMDS Plot
# ============================

fig = go.Figure()

for treatment in ordination['Treatment'].unique():
    
    subset = ordination[ordination['Treatment'] == treatment]
    
    fig.add_trace(go.Scatter(
        x=subset['NMDS1'],
        y=subset['NMDS2'],
        mode='markers+text',
        name=treatment,
        text=subset['Sample'],
        textposition='top center',
        marker=dict(
            size=12,
            line=dict(width=2, color='DarkSlateGrey')
        ),
        hovertemplate='<b>%{text}</b><br>NMDS1: %{x:.2f}<br>NMDS2: %{y:.2f}<extra></extra>'
    ))

fig.update_layout(
    title='NMDS Ordination - Interactive (Toy Data)',
    xaxis_title='NMDS1',
    yaxis_title='NMDS2',
    hovermode='closest',
    width=900,
    height=700
)

fig.write_html('nmds_interactive_toy.html')
fig.show()

