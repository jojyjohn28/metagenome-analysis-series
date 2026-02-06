# Running Day 3 Binning on Your Laptop/Desktop

This guide provides practical instructions for genome binning on personal computers with limited resources.

## 💻 System Requirements

### Minimum Specifications

- **CPU:** 8 cores (Intel i7/i9 or AMD Ryzen 7/9)
- **RAM:** 32 GB (64 GB strongly recommended)
- **Storage:** 100 GB free space
- **OS:** Linux (Ubuntu 20.04/22.04 recommended)

### Recommended Specifications

- **CPU:** 16+ cores
- **RAM:** 64-128 GB
- **Storage:** 200 GB SSD
- **OS:** Linux (Ubuntu 22.04)

### ⚠️ Reality Check for Laptops

Binning is **more resource-intensive** than assembly. Here's what to expect:

| Resource    | Minimum   | Recommended | Why Important                 |
| ----------- | --------- | ----------- | ----------------------------- |
| **RAM**     | 32 GB     | 64 GB+      | CheckM needs 30-40GB alone    |
| **CPU**     | 8 cores   | 16+ cores   | MetaWRAP runs parallel CheckM |
| **Storage** | 100 GB    | 200 GB      | Many intermediate files       |
| **Time**    | 12-24 hrs | 4-8 hrs     | Depends on bin count          |

**If your laptop has <32GB RAM:** Consider cloud computing (AWS, Google Cloud) or HPC access for this step.

---

## 📦 Software Installation

### Step 1: Create Main Environment (Python 3 - Modern Approach)

```bash
# Create clean Python 3 environment
conda create -n binning python=3.9
conda activate binning

# Install core binning tools
conda install -c bioconda -c conda-forge \
    metabat2 \
    maxbin2 \
    concoct \
    checkm-genome \
    checkm2 \
    pplacer \
    biopython \
    pandas \
    seaborn \
    matplotlib
```

### Step 2: Install MetaWRAP (Without metawrap-mg)

```bash
# Install MetaWRAP from bioconda
conda install -c bioconda metawrap-mg

# Or from source for latest version
git clone https://github.com/bxlab/metaWRAP.git
cd metaWRAP/bin
export PATH=$(pwd):$PATH
```

### Step 3: Create Separate Environments for Problematic Tools

**Prokka (for annotation):**

```bash
conda create -n prokka python=3.8
conda activate prokka
conda install -c bioconda prokka
which prokka  # Note this path
```

**Salmon (for quantification):**

```bash
conda create -n salmon python=3.8
conda activate salmon
conda install -c bioconda salmon
which salmon  # Note this path
```

### Step 4: Download CheckM Database

```bash
conda activate binning

# Download CheckM database (~275 MB compressed, ~1.4 GB uncompressed)
mkdir -p ~/checkm_db
cd ~/checkm_db
wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
tar -xvzf checkm_data_2015_01_16.tar.gz
rm checkm_data_2015_01_16.tar.gz

# Set CheckM database location
checkm data setRoot ~/checkm_db

# Verify
checkm test ~/checkm_test_output
```

### Step 5: Download CheckM2 Database (Recommended)

```bash
# CheckM2 is faster and more accurate
checkm2 database --download --path ~/checkm2_db/

# This downloads ~3.5 GB
```

### Verify Installation

```bash
conda activate binning

# Test each tool
metabat2 --help
run_MaxBin.pl -h
concoct --help
checkm -h
checkm2 -h
metawrap --help

# All should work without errors
```

---

## 🚀 Complete 1-Sample Binning Tutorial

### Step 0: Prepare Your Environment

```bash
# Create project directory
mkdir -p ~/metagenome_project/day3_binning
cd ~/metagenome_project/day3_binning

# Create subdirectories
mkdir -p data results logs scripts

# Activate environment
conda activate binning
```

### Step 1: Prepare Input Files from Day 2

You need three things from Day 2:

```bash
# From Day 2 assembly
CONTIGS="../day2-assembly/results/assembly/sample1_contigs.fasta"

# From Day 2 clean reads (for MetaWRAP)
READS_R1="../day1-qc-read-based/results/trimmed/sample1_R1_paired.fastq.gz"
READS_R2="../day1-qc-read-based/results/trimmed/sample1_R2_paired.fastq.gz"

# Verify files exist
ls -lh ${CONTIGS}
ls -lh ${READS_R1}
ls -lh ${READS_R2}
```

**Expected output:**

```
-rw-r--r-- 1 user user  45M sample1_contigs.fasta
-rw-r--r-- 1 user user 450M sample1_R1_paired.fastq.gz
-rw-r--r-- 1 user user 450M sample1_R2_paired.fastq.gz
```

### Step 2: Initial Binning with MetaWRAP (All-in-One)

This is the **modern approach** - MetaWRAP runs all three binners together!

```bash
SAMPLE="sample1"
THREADS=8  # Adjust based on your CPU

echo "========================================="
echo "  MetaWRAP Initial Binning"
echo "========================================="
echo "Sample: ${SAMPLE}"
echo "Threads: ${THREADS}"
echo "Start time: $(date)"
echo ""

# Run MetaWRAP binning module (runs MetaBAT2, MaxBin2, CONCOCT)
metawrap binning \
    -o results/INITIAL_BINNING \
    -t ${THREADS} \
    -a ${CONTIGS} \
    --metabat2 \
    --maxbin2 \
    --concoct \
    ${READS_R1} ${READS_R2} \
    -m 1500 \
    --run-checkm \
    2>&1 | tee logs/${SAMPLE}_initial_binning.log

echo ""
echo "End time: $(date)"
```

**What this does:**

1. ✅ Maps reads back to contigs (automatic)
2. ✅ Calculates coverage (automatic)
3. ✅ Runs MetaBAT2, MaxBin2, and CONCOCT
4. ✅ Runs CheckM on all bins
5. ✅ Generates summary statistics

**Expected time:** 4-8 hours depending on data size

**Monitor progress:**

```bash
# In another terminal
tail -f logs/sample1_initial_binning.log

# Check memory usage
htop
```

### Step 3: Check Initial Binning Results

```bash
# Check output structure
ls -lh results/INITIAL_BINNING/

# Count bins from each method
metabat_bins=$(ls results/INITIAL_BINNING/metabat2_bins/*.fa 2>/dev/null | wc -l)
maxbin_bins=$(ls results/INITIAL_BINNING/maxbin2_bins/*.fasta 2>/dev/null | wc -l)
concoct_bins=$(ls results/INITIAL_BINNING/concoct_bins/*.fa 2>/dev/null | wc -l)

echo "Initial Binning Results:"
echo "  MetaBAT2: ${metabat_bins} bins"
echo "  MaxBin2:  ${maxbin_bins} bins"
echo "  CONCOCT:  ${concoct_bins} bins"
echo "  Total:    $((metabat_bins + maxbin_bins + concoct_bins)) bins"

# View CheckM results
cat results/INITIAL_BINNING/metabat2_bins.stats
cat results/INITIAL_BINNING/maxbin2_bins.stats
cat results/INITIAL_BINNING/concoct_bins.stats
```

**Expected output:**

```
Initial Binning Results:
  MetaBAT2: 15 bins
  MaxBin2:  12 bins
  CONCOCT:  18 bins
  Total:    45 bins
```

### Step 4: Bin Refinement (Consolidate Best Bins)

Now combine the three binning results to get the **best possible MAGs**:

```bash
echo "========================================="
echo "  MetaWRAP Bin Refinement"
echo "========================================="
echo "Combining bins from 3 methods..."
echo "Start time: $(date)"
echo ""

# Refine bins (consolidate + remove contamination)
metawrap bin_refinement \
    -o results/BIN_REFINEMENT \
    -t ${THREADS} \
    -A results/INITIAL_BINNING/metabat2_bins/ \
    -B results/INITIAL_BINNING/maxbin2_bins/ \
    -C results/INITIAL_BINNING/concoct_bins/ \
    -c 50 \
    -x 10 \
    -m 1500 \
    2>&1 | tee logs/${SAMPLE}_refinement.log

echo ""
echo "End time: $(date)"
```

**Parameters explained:**

- `-c 50`: Keep bins with ≥50% completeness
- `-x 10`: Keep bins with ≤10% contamination
- `-m 1500`: Minimum bin size (1.5 Mb)

**Expected time:** 2-6 hours

**What refinement does:**

1. Compares bins across all three methods
2. Picks best contigs from each method
3. Removes contaminating contigs
4. Re-runs CheckM on refined bins
5. Creates Venn diagrams showing overlap

### Step 5: Examine Refined Bins

```bash
# Check refined bins
ls -lh results/BIN_REFINEMENT/metawrap_50_10_bins/

# Count refined bins
refined_bins=$(ls results/BIN_REFINEMENT/metawrap_50_10_bins/*.fa 2>/dev/null | wc -l)
echo "Refined bins: ${refined_bins}"

# View quality statistics
cat results/BIN_REFINEMENT/metawrap_50_10_bins.stats

# View figures
# MetaWRAP creates helpful visualizations
ls results/BIN_REFINEMENT/figures/
# - binning_results.png (Venn diagram)
# - bin_refinement_stats.png (quality comparison)
```

**Interpreting the stats file:**

```
bin      completeness  contamination  GC      lineage                      N50    size
bin.1    95.2         2.1            0.42    Bacteroidetes               45678   3.2M
bin.2    87.3         8.5            0.48    Proteobacteria             23456   2.8M
bin.3    72.1         4.2            0.55    Firmicutes                 12345   2.1M
```

**Quality tiers:**

- **High-quality (HQ):** Completeness ≥90%, Contamination <5%
- **Medium-quality (MQ):** Completeness ≥50%, Contamination <10%
- **Low-quality (LQ):** Below MQ thresholds

### Step 6: Enhanced Quality Assessment with CheckM2

CheckM2 is faster and more accurate than CheckM:

```bash
echo "Running CheckM2 for enhanced quality assessment..."

# Run CheckM2 on refined bins
checkm2 predict \
    --threads ${THREADS} \
    --input results/BIN_REFINEMENT/metawrap_50_10_bins \
    --output-directory results/checkm2_output \
    -x fa \
    2>&1 | tee logs/${SAMPLE}_checkm2.log

# View results
cat results/checkm2_output/quality_report.tsv
```

**Compare CheckM vs CheckM2:**

```python
# Create comparison script
cat > scripts/compare_checkm.py << 'EOF'
#!/usr/bin/env python3
import pandas as pd

# Read CheckM results (from MetaWRAP)
checkm = pd.read_csv('results/BIN_REFINEMENT/metawrap_50_10_bins.stats', sep='\t')

# Read CheckM2 results
checkm2 = pd.read_csv('results/checkm2_output/quality_report.tsv', sep='\t')

print("="*60)
print("  CheckM vs CheckM2 Comparison")
print("="*60)
print(f"\nCheckM:  {len(checkm)} bins assessed")
print(f"CheckM2: {len(checkm2)} bins assessed")
print()

# Compare metrics
for idx, row in checkm.iterrows():
    bin_name = row['bin']
    ckm_comp = row['completeness']
    ckm_cont = row['contamination']

    # Find in CheckM2
    ckm2_row = checkm2[checkm2['Name'].str.contains(bin_name)]
    if not ckm2_row.empty:
        ckm2_comp = ckm2_row.iloc[0]['Completeness']
        ckm2_cont = ckm2_row.iloc[0]['Contamination']

        print(f"{bin_name}:")
        print(f"  CheckM:  {ckm_comp:.1f}% comp, {ckm_cont:.1f}% cont")
        print(f"  CheckM2: {ckm2_comp:.1f}% comp, {ckm2_cont:.1f}% cont")
        print()
EOF

chmod +x scripts/compare_checkm.py
python scripts/compare_checkm.py
```

### Step 7: Quantify Bin Abundance (Optional)

Calculate the abundance of each MAG across your sample:

```bash
echo "Quantifying bin abundances..."

metawrap quant_bins \
    -b results/BIN_REFINEMENT/metawrap_50_10_bins \
    -o results/QUANT_BINS \
    -a ${CONTIGS} \
    ${READS_R1} ${READS_R2} \
    -t ${THREADS} \
    2>&1 | tee logs/${SAMPLE}_quant.log

# View abundance results
cat results/QUANT_BINS/bin_abundance_table.tab
```

**Why quantify?**

- See which organisms are most abundant
- Track changes across time series
- Identify rare vs dominant community members

### Step 8: Filter High-Quality MAGs

Keep only the best MAGs for downstream analysis:

```bash
# Create filtering script
cat > scripts/filter_quality_mags.py << 'EOF'
#!/usr/bin/env python3
import pandas as pd
import shutil
import os

# Read quality stats
df = pd.read_csv('results/checkm2_output/quality_report.tsv', sep='\t')

# Define quality thresholds
hq = df[(df['Completeness'] >= 90) & (df['Contamination'] < 5)]
mq = df[(df['Completeness'] >= 50) & (df['Contamination'] < 10) &
        ~((df['Completeness'] >= 90) & (df['Contamination'] < 5))]

print("="*60)
print("  Filtering Quality MAGs")
print("="*60)
print(f"High-quality MAGs: {len(hq)}")
print(f"Medium-quality MAGs: {len(mq)}")
print(f"Total quality MAGs: {len(hq) + len(mq)}")
print()

# Create output directories
os.makedirs('results/quality_mags/HQ', exist_ok=True)
os.makedirs('results/quality_mags/MQ', exist_ok=True)

# Copy HQ MAGs
print("Copying high-quality MAGs...")
for bin_name in hq['Name']:
    src = f'results/BIN_REFINEMENT/metawrap_50_10_bins/{bin_name}.fa'
    dst = f'results/quality_mags/HQ/{bin_name}.fa'
    if os.path.exists(src):
        shutil.copy(src, dst)
        print(f"  ✓ {bin_name}")

# Copy MQ MAGs
print("\nCopying medium-quality MAGs...")
for bin_name in mq['Name']:
    src = f'results/BIN_REFINEMENT/metawrap_50_10_bins/{bin_name}.fa'
    dst = f'results/quality_mags/MQ/{bin_name}.fa'
    if os.path.exists(src):
        shutil.copy(src, dst)
        print(f"  ✓ {bin_name}")

# Save quality list
quality_df = pd.concat([hq, mq])
quality_df.to_csv('results/quality_mags/quality_mags_list.csv', index=False)

print()
print("="*60)
print(f"Quality MAGs saved to: results/quality_mags/")
print("="*60)
EOF

chmod +x scripts/filter_quality_mags.py
python scripts/filter_quality_mags.py
```

### Step 9: Visualize Results

Create quality plots to understand your MAGs:

```bash
cat > scripts/plot_mag_quality.py << 'EOF'
#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Read CheckM2 results
df = pd.read_csv('results/checkm2_output/quality_report.tsv', sep='\t')

# Create figure with subplots
fig, axes = plt.subplots(2, 2, figsize=(14, 10))
fig.suptitle('MAG Quality Assessment', fontsize=16, fontweight='bold')

# 1. Completeness vs Contamination scatter
ax1 = axes[0, 0]
scatter = ax1.scatter(df['Contamination'], df['Completeness'],
                      s=100, alpha=0.6,
                      c=df['Completeness']-df['Contamination'],
                      cmap='RdYlGn', edgecolors='black')
ax1.axhline(y=90, color='green', linestyle='--', alpha=0.5, label='HQ (90%)')
ax1.axhline(y=50, color='orange', linestyle='--', alpha=0.5, label='MQ (50%)')
ax1.axvline(x=5, color='green', linestyle='--', alpha=0.5)
ax1.axvline(x=10, color='orange', linestyle='--', alpha=0.5)
ax1.set_xlabel('Contamination (%)', fontsize=12)
ax1.set_ylabel('Completeness (%)', fontsize=12)
ax1.set_title('Completeness vs Contamination')
ax1.legend()
ax1.grid(alpha=0.3)
plt.colorbar(scatter, ax=ax1, label='Quality Score')

# 2. Quality distribution
ax2 = axes[0, 1]
quality_counts = {
    'High-Quality\n(≥90%, <5%)': len(df[(df['Completeness']>=90) & (df['Contamination']<5)]),
    'Medium-Quality\n(50-90%, <10%)': len(df[(df['Completeness']>=50) &
                                              (df['Completeness']<90) &
                                              (df['Contamination']<10)]),
    'Low-Quality': len(df[(df['Completeness']<50) | (df['Contamination']>=10)])
}
colors = ['#27ae60', '#f39c12', '#e74c3c']
ax2.bar(quality_counts.keys(), quality_counts.values(), color=colors, edgecolor='black')
ax2.set_ylabel('Number of MAGs', fontsize=12)
ax2.set_title('MAG Quality Distribution')
for i, (k, v) in enumerate(quality_counts.items()):
    ax2.text(i, v + 0.5, str(v), ha='center', fontweight='bold')

# 3. Completeness distribution
ax3 = axes[1, 0]
ax3.hist(df['Completeness'], bins=20, color='steelblue', edgecolor='black', alpha=0.7)
ax3.axvline(df['Completeness'].mean(), color='red', linestyle='--',
            label=f'Mean: {df["Completeness"].mean():.1f}%')
ax3.set_xlabel('Completeness (%)', fontsize=12)
ax3.set_ylabel('Frequency', fontsize=12)
ax3.set_title('Completeness Distribution')
ax3.legend()
ax3.grid(alpha=0.3, axis='y')

# 4. Contamination distribution
ax4 = axes[1, 1]
ax4.hist(df['Contamination'], bins=20, color='coral', edgecolor='black', alpha=0.7)
ax4.axvline(df['Contamination'].mean(), color='red', linestyle='--',
            label=f'Mean: {df["Contamination"].mean():.1f}%')
ax4.set_xlabel('Contamination (%)', fontsize=12)
ax4.set_ylabel('Frequency', fontsize=12)
ax4.set_title('Contamination Distribution')
ax4.legend()
ax4.grid(alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig('results/mag_quality_plots.pdf', dpi=300, bbox_inches='tight')
plt.savefig('results/mag_quality_plots.png', dpi=300, bbox_inches='tight')
print("\n✓ Plots saved to results/mag_quality_plots.pdf/png")
EOF

chmod +x scripts/plot_mag_quality.py
python scripts/plot_mag_quality.py
```

---

## 📊 Understanding Your Results

### What Makes a Good Binning Result?

**Excellent binning:**

- 10-30 HQ MAGs (≥90% comp, <5% cont)
- 20-50 MQ MAGs (50-90% comp, <10% cont)
- Low overlap between bins
- N50 of bins >10kb

**Good binning:**

- 5-15 HQ MAGs
- 15-30 MQ MAGs
- Some overlap between bins
- N50 of bins >5kb

**Acceptable binning:**

- 3-10 HQ MAGs
- 10-20 MQ MAGs
- High overlap indicates similar organisms
- N50 of bins >2kb

### Red Flags

⚠️ **Very few bins (<5 total)**

- Assembly quality too low
- Coverage insufficient
- Community too simple (expected?) or complex

⚠️ **High contamination across all bins (>15%)**

- Closely related strains
- Poor assembly
- Need stricter refinement

⚠️ **Low completeness across all bins (<40%)**

- Low sequencing depth
- High fragmentation
- May need deeper sequencing

---

## 💡 Tips for Success on Laptops

### Memory Management

```bash
# Monitor memory during binning
watch -n 5 free -h

# If running out of memory:
# 1. Close all other applications
# 2. Reduce thread count
THREADS=4  # instead of 8

# 3. Process one sample at a time
# 4. Use swap space (slower but works)
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Speed Optimization

```bash
# Use all available cores
THREADS=$(nproc)
THREADS=$((THREADS - 2))  # Leave 2 for system

# Skip CheckM during initial binning (run separately later)
metawrap binning ... --skip-checkm

# Then run CheckM only on refined bins
checkm lineage_wf -x fa refined_bins/ checkm_output/
```

### Disk Space Management

```bash
# Check space regularly
df -h ~/metagenome_project

# Clean up after refinement:
# Remove intermediate binning files (keep only refined)
# WARNING: Only do this after verifying refinement succeeded!
# rm -rf results/INITIAL_BINNING/work_files/

# Compress old logs
gzip logs/*.log
```

---

## 🔧 Troubleshooting

### Problem: MetaWRAP binning fails immediately

**Check:**

```bash
# Verify input files exist
ls ${CONTIGS}
ls ${READS_R1}
ls ${READS_R2}

# Check file formats
head ${CONTIGS}  # Should be FASTA
zcat ${READS_R1} | head  # Should be FASTQ

# Check if enough disk space
df -h .
```

**Solutions:**

- Ensure contigs are in FASTA format (not FASTQ)
- Reads should be clean (from Day 1)
- Need at least 100GB free space

### Problem: Out of memory during CheckM

**Solutions:**

```bash
# Run without CheckM initially
metawrap binning --skip-checkm ...

# Run CheckM separately with reduced parallel jobs
checkm lineage_wf -x fa --reduced_tree -t 4 bins/ output/

# Or use CheckM2 (uses less memory)
checkm2 predict --threads 4 ...
```

### Problem: Few bins recovered

**Possible causes & solutions:**

1. **Low coverage:**

   ```bash
   # Check mapping rate from logs
   grep "overall alignment rate" logs/*_initial_binning.log
   # Should be >70%
   ```

2. **Poor assembly:**

   ```bash
   # Check N50 from Day 2
   # Should be >5kb for good binning
   ```

3. **Adjust binning parameters:**

   ```bash
   # Lower minimum bin size
   metawrap binning -m 1000 ...  # instead of 1500

   # More lenient refinement
   metawrap bin_refinement -c 40 -x 15 ...
   ```

### Problem: High contamination in bins

**Solutions:**

1. **Stricter refinement:**

   ```bash
   metawrap bin_refinement -c 70 -x 5 ...
   ```

2. **Manual curation with anvi'o:**

   ```bash
   # Install anvi'o
   conda create -n anvio python=3.6
   conda activate anvio
   conda install -c bioconda anvio

   # Import bins and manually refine
   anvi-script-reformat-fasta bin.fa -o reformatted.fa -l 1000 --simplify-names
   ```

3. **Check for strain heterogeneity:**
   - Multiple strains of same species can cause contamination
   - Consider keeping them separate for strain-level analysis

### Problem: CheckM2 database download fails

**Solutions:**

```bash
# Manual download
wget http://ftp.ebi.ac.uk/pub/databases/metagenomics/genome_sets/checkm2/checkm2_database.tar.gz

# Extract to database location
mkdir -p ~/checkm2_db
tar -xzf checkm2_database.tar.gz -C ~/checkm2_db/

# Verify
ls ~/checkm2_db/
checkm2 database --check --path ~/checkm2_db/
```

---

## ⏱️ Expected Runtimes (Laptop: 8 cores, 32GB RAM)

| Step                | Small Dataset | Medium Dataset | Large Dataset   |
| ------------------- | ------------- | -------------- | --------------- |
| **Initial Binning** | 2-4 hours     | 4-8 hours      | 8-16 hours      |
| **Refinement**      | 1-2 hours     | 2-4 hours      | 4-8 hours       |
| **CheckM2**         | 30 min        | 1-2 hours      | 2-4 hours       |
| **Quantification**  | 30 min        | 1 hour         | 2 hours         |
| **Total**           | **4-7 hours** | **8-15 hours** | **16-30 hours** |

_Small: <5M read pairs, Medium: 5-20M pairs, Large: >20M pairs_

---

## ✅ Success Checklist

After completing this tutorial, you should have:

- [ ] Installed MetaWRAP and dependencies
- [ ] Run initial binning with 3 algorithms
- [ ] Refined bins to improve quality
- [ ] Assessed quality with CheckM2
- [ ] Generated quality plots
- [ ] Filtered HQ and MQ MAGs
- [ ] (Optional) Quantified bin abundances
- [ ] Organized MAGs for Day 4 annotation

---

## 💾 Final Directory Structure

```
day3_binning/
├── data/
│   └── (symlinks to Day 2 files)
├── results/
│   ├── INITIAL_BINNING/
│   │   ├── metabat2_bins/
│   │   ├── maxbin2_bins/
│   │   ├── concoct_bins/
│   │   └── work_files/
│   ├── BIN_REFINEMENT/
│   │   ├── metawrap_50_10_bins/  ← REFINED MAGs
│   │   ├── figures/
│   │   └── metawrap_50_10_bins.stats
│   ├── checkm2_output/
│   │   └── quality_report.tsv
│   ├── QUANT_BINS/
│   │   └── bin_abundance_table.tab
│   └── quality_mags/
│       ├── HQ/                    ← HIGH-QUALITY MAGs
│       ├── MQ/                    ← MEDIUM-QUALITY MAGs
│       └── quality_mags_list.csv
├── logs/
└── scripts/
```

---

## 📚 Additional Resources

### If Your Laptop Struggles

**Cloud Computing Options:**

- **AWS EC2 r5.2xlarge:** 8 cores, 64GB RAM (~$0.50/hour)
- **Google Cloud n1-highmem-8:** 8 cores, 52GB RAM (~$0.48/hour)
- Run for 8-12 hours, total cost: $4-6

**Free Tier Options:**

- Google Colab Pro ($10/month, 25GB RAM)
- Kaggle Kernels (16GB RAM, free)

### Alternative Binners

If MetaWRAP doesn't work:

```bash
# Try SemiBin2 (deep learning, very good)
SemiBin single_easy_bin -i contigs.fa -b reads.bam -o semibin_out

# Try VAMB (variational autoencoder)
conda install -c bioconda vamb
vamb --fasta contigs.fa --bamfiles *.bam --outdir vamb_out
```

---

## ➡️ Next Steps

**Congratulations!** You've successfully recovered MAGs from your metagenome!

**Ready for Day 4?**

[Proceed to Day 4: Functional Annotation →](../day4-functional-annotation/)

Learn to annotate genes and predict metabolic functions!

---

<div align="center">

**[⬆ Back to Day 3 README](../README.md)** | **[← Day 2](../../day2-assembly/)** | **[Day 4 →](../../day4-functional-annotation/)**

Made with ❤️ for the metagenomics community

</div>
