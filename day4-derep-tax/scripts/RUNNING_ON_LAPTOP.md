# Running Day 4 Dereplication & Taxonomy on Your Laptop/Desktop

This guide provides practical instructions for genome dereplication and taxonomic classification on personal computers.

## 💻 System Requirements

### Minimum Specifications

- **CPU:** 8 cores (Intel i7/i9 or AMD Ryzen 7/9)
- **RAM:** 32 GB (64 GB recommended for GTDB-Tk)
- **Storage:** 100 GB free space (GTDB database alone is 65 GB!)
- **OS:** Linux (Ubuntu 20.04/22.04) or macOS

### Recommended Specifications

- **CPU:** 16+ cores
- **RAM:** 64-128 GB
- **Storage:** 200 GB SSD
- **OS:** Linux (Ubuntu 22.04)

### ⚠️ Reality Check for Laptops

Day 4 is **less resource-intensive** than Day 3 binning, but still requires:

| Task                 | RAM      | Time     | Disk Space |
| -------------------- | -------- | -------- | ---------- |
| **dRep**             | 16-32 GB | 1-4 hrs  | 10 GB      |
| **GTDB-Tk database** | N/A      | One-time | **65 GB**  |
| **GTDB-Tk classify** | 32-64 GB | 4-12 hrs | 20 GB      |

**Good news:** You only need to download the GTDB database **once**!

---

## 📦 Software Installation

### Step 1: Create dRep Environment

```bash
# Create environment
conda create -n drep python=3.9
conda activate drep

# Install dRep
conda install -c bioconda drep

# Verify
dRep -h
```

### Step 2: Create GTDB-Tk Environment

```bash
# Create separate environment (different dependencies)
conda create -n gtdbtk python=3.9
conda activate gtdbtk

# Install GTDB-Tk
conda install -c bioconda gtdbtk

# Verify
gtdbtk -h
```

### Step 3: Download GTDB-Tk Database

**⚠️ This is a LARGE download (~65 GB)** - Do this on a stable connection!

```bash
conda activate gtdbtk

# Option 1: Automatic download (recommended)
download-db.sh

# Option 2: Manual download
wget https://data.gtdb.ecogenomic.org/releases/latest/auxillary_files/gtdbtk_data.tar.gz
tar -xzf gtdbtk_data.tar.gz -C ~/gtdbtk_db/

# Set environment variable permanently
export GTDBTK_DATA_PATH=~/gtdbtk_db/release207
echo 'export GTDBTK_DATA_PATH=~/gtdbtk_db/release207' >> ~/.bashrc
source ~/.bashrc

# Verify database
gtdbtk check_install
```

---

## 🚀 Quick Start: Single-Line Commands

### dRep - One Command

```bash
conda activate drep

# Basic dereplication (species level, 95% ANI)
dRep dereplicate \
    dereplicated_genomes \
    -g quality_mags/*.fa \
    --ignoreGenomeQuality \
    -p 8 \
    -sa 0.95
```

**Real-world example** (from your workflow):

```bash
# Your actual command structure
dRep dereplicate \
    /path/to/output/dereplicated_combined/ \
    -g /path/to/input/dereplicated_genomes/*.fa \
    -p 8 \
    -sa 0.95 \
    --ignoreGenomeQuality
```

### GTDB-Tk - Complete Workflow

**Option 1: One-step classify_wf (recommended for most users)**

```bash
conda activate gtdbtk

# Complete classification in one command
gtdbtk classify_wf \
    --genome_dir dereplicated_genomes \
    --out_dir gtdbtk_output \
    --extension fa \
    --cpus 8
```

**Option 2: Step-by-step workflow** (your approach - more control)

```bash
conda activate gtdbtk

# Step 1: Identify marker genes
gtdbtk identify \
    --genome_dir genome_dir \
    --out_dir identify_output \
    --extension fa \
    --cpus 8

# Step 2: Check identified markers (optional)
cat identify_output/gtdbtk.bac120.markers_summary.tsv
cat identify_output/gtdbtk.ar53.markers_summary.tsv

# Step 3: Align marker genes
gtdbtk align \
    --identify_dir identify_output \
    --out_dir align_output \
    --cpus 8

# Step 4: Classify genomes
gtdbtk classify \
    --genome_dir genome_dir \
    --align_dir align_output \
    --out_dir classify_output \
    --extension fa \
    --cpus 8
```

**Option 3: De novo workflow** (for custom taxonomy or novel clades)

```bash
# Your actual de novo command
gtdbtk de_novo_wf \
    --genome_dir dereplicated_genomes \
    --out_dir gtdbtk_denovo_output \
    --extension fa \
    --bacteria \
    --cpus 8 \
    --outgroup_taxon p__Chloroflexota \
    --skip_gtdb_refs \
    --custom_taxonomy_file custom_taxonomy.csv
```

### Convert Tree for iTOL

```bash
# Convert GTDB-Tk tree to iTOL format
gtdbtk convert_to_itol \
    --input_tree gtdbtk_output/classify/gtdbtk.bac120.decorated.tree \
    --output_tree itol_output_tree.nwk
```

---

## 📖 Complete 1-Sample Tutorial

### Step 0: Prepare Your Environment

```bash
# Create project directory
mkdir -p ~/metagenome_project/day4_taxonomy
cd ~/metagenome_project/day4_taxonomy

# Create subdirectories
mkdir -p quality_mags results logs

# Copy quality MAGs from Day 3
cp ../day3-binning/quality_mags/*.fa quality_mags/

# Activate environment
conda activate drep
```

### Step 1: Genome Dereplication

**Estimate:** 1-4 hours depending on number of genomes

```bash
echo "========================================="
echo "  Step 1: dRep Dereplication"
echo "========================================="
echo "Start time: $(date)"
echo ""

# Count input genomes
n_genomes=$(ls quality_mags/*.fa | wc -l)
echo "Input genomes: ${n_genomes}"

# Run dRep
dRep dereplicate \
    results/dereplicated \
    -g quality_mags/*.fa \
    --ignoreGenomeQuality \
    -p 8 \
    -sa 0.95 \
    2>&1 | tee logs/drep.log

if [ $? -eq 0 ]; then
    echo "✓ dRep completed successfully"

    # Count dereplicated genomes
    n_derep=$(ls results/dereplicated/dereplicated_genomes/*.fa 2>/dev/null | wc -l)
    reduction=$(echo "scale=1; (${n_genomes}-${n_derep})/${n_genomes}*100" | bc)

    echo ""
    echo "Results:"
    echo "  Input genomes:        ${n_genomes}"
    echo "  Dereplicated genomes: ${n_derep}"
    echo "  Reduction:            ${reduction}%"
else
    echo "✗ dRep failed - check logs/drep.log"
    exit 1
fi

echo ""
echo "End time: $(date)"
```

**Understanding the output:**

```
results/dereplicated/
├── data_tables/
│   ├── Cdb.csv           # Cluster assignments (which genomes cluster together)
│   ├── Sdb.csv           # Score table (quality scores)
│   ├── Wdb.csv           # Winner table (best representative per cluster)
│   └── Widb.csv          # Winner with details
├── dereplicated_genomes/  # ← Your species representatives!
│   ├── genome1.fa
│   ├── genome2.fa
│   └── ...
└── figures/
    └── *.pdf              # Dendrograms showing clustering
```

### Step 2: Analyze Dereplication Results

```bash
echo "Analyzing dereplication results..."

# View cluster information
echo "Cluster assignments:"
head -20 results/dereplicated/data_tables/Cdb.csv | column -t -s,

# View winner genomes
echo ""
echo "Representative genomes (winners):"
cat results/dereplicated/data_tables/Widb.csv | column -t -s,

# Count cluster sizes
echo ""
echo "Cluster size distribution:"
tail -n +2 results/dereplicated/data_tables/Cdb.csv | \
    cut -d',' -f2 | sort | uniq -c | \
    awk '{print "  Cluster size "$2": "$1" genomes"}'
```

### Step 3: GTDB-Tk Classification

**Estimate:** 4-12 hours (depends on number of genomes)

```bash
echo ""
echo "========================================="
echo "  Step 2: GTDB-Tk Classification"
echo "========================================="
echo "Start time: $(date)"
echo ""

# Switch to GTDB-Tk environment
conda activate gtdbtk

# Verify database
if [ -z "$GTDBTK_DATA_PATH" ]; then
    echo "ERROR: GTDBTK_DATA_PATH not set!"
    echo "Run: export GTDBTK_DATA_PATH=~/gtdbtk_db/release207"
    exit 1
fi

echo "GTDB database: $GTDBTK_DATA_PATH"

# Count genomes to classify
n_classify=$(ls results/dereplicated/dereplicated_genomes/*.fa | wc -l)
echo "Genomes to classify: ${n_classify}"
echo "Estimated time: ~10-15 minutes per genome"
echo "Total estimate: ~$((n_classify * 12 / 60)) hours"
echo ""

# Run GTDB-Tk classify workflow
gtdbtk classify_wf \
    --genome_dir results/dereplicated/dereplicated_genomes \
    --out_dir results/gtdbtk \
    --extension fa \
    --cpus 8 \
    --pplacer_cpus 4 \
    2>&1 | tee logs/gtdbtk.log

if [ $? -eq 0 ]; then
    echo "✓ GTDB-Tk classification completed"
else
    echo "✗ GTDB-Tk classification failed - check logs/gtdbtk.log"
    exit 1
fi

echo ""
echo "End time: $(date)"
```

### Step 4: Examine Classification Results

```bash
echo ""
echo "========================================="
echo "  Examining Classification Results"
echo "========================================="

# Find summary file (bacteria or archaea)
if [ -f "results/gtdbtk/classify/gtdbtk.bac120.summary.tsv" ]; then
    SUMMARY="results/gtdbtk/classify/gtdbtk.bac120.summary.tsv"
    echo "Found: Bacterial classifications"
elif [ -f "results/gtdbtk/classify/gtdbtk.ar53.summary.tsv" ]; then
    SUMMARY="results/gtdbtk/classify/gtdbtk.ar53.summary.tsv"
    echo "Found: Archaeal classifications"
else
    echo "ERROR: No classification summary found!"
    exit 1
fi

echo ""
echo "Summary file: ${SUMMARY}"
echo ""

# Display first 5 classifications
echo "First 5 classified genomes:"
head -6 ${SUMMARY} | column -t -s$'\t'

# Count phyla
echo ""
echo "Phylum distribution:"
tail -n +2 ${SUMMARY} | \
    awk -F'\t' '{print $2}' | \
    sed 's/.*p__\([^;]*\).*/\1/' | \
    sort | uniq -c | sort -rn

# Novel species analysis
echo ""
echo "Novel species analysis (ANI <95%):"
tail -n +2 ${SUMMARY} | \
    awk -F'\t' '$NF < 95 {count++} END {print "  Novel species candidates: " count+0}'
```

---

## 💡 Tips for Success on Laptops

### Memory Management

```bash
# Monitor memory during GTDB-Tk
watch -n 5 free -h

# If running out of memory:
# 1. Close all other applications
# 2. Reduce CPU threads (uses less memory)
gtdbtk classify_wf --cpus 4 --pplacer_cpus 1 ...

# 3. Process in batches
mkdir batch1 batch2
# Move half of genomes to each batch
gtdbtk classify_wf --genome_dir batch1 ...
gtdbtk classify_wf --genome_dir batch2 ...
```

### Speed Optimization

```bash
# Use all but 2 CPU cores
THREADS=$(nproc)
THREADS=$((THREADS - 2))

# dRep with all cores
dRep dereplicate output -g *.fa -p ${THREADS}

# GTDB-Tk with all cores (but limit pplacer)
gtdbtk classify_wf ... --cpus ${THREADS} --pplacer_cpus 4
```

### Disk Space Management

```bash
# Check space before starting
df -h ~/metagenome_project

# GTDB-Tk uses temporary files - clean up after
rm -rf gtdbtk_output/align/intermediate_results/
rm -rf gtdbtk_output/identify/intermediate_results/

# Compress old logs
gzip logs/*.log
```

---

## 🔧 Troubleshooting

### Problem: dRep "No clusters formed"

**Cause:** Genomes too dissimilar (all <95% ANI)

**Solutions:**

```bash
# Lower ANI threshold
dRep dereplicate output -g *.fa -sa 0.90

# Check if genomes are valid
head -1 quality_mags/*.fa

# Verify MASH installation
which mash
```

### Problem: GTDB-Tk "Database not found"

**Solutions:**

```bash
# Check environment variable
echo $GTDBTK_DATA_PATH

# Set it if empty
export GTDBTK_DATA_PATH=~/gtdbtk_db/release207

# Add to bashrc permanently
echo 'export GTDBTK_DATA_PATH=~/gtdbtk_db/release207' >> ~/.bashrc

# Verify database
gtdbtk check_install
```

### Problem: GTDB-Tk "Out of memory"

**Solutions:**

```bash
# Reduce threads
gtdbtk classify_wf --cpus 4 --pplacer_cpus 1 ...

# Use scratch directory
gtdbtk classify_wf --scratch_dir /tmp/gtdbtk ...

# Process in smaller batches (10-20 genomes at a time)
```

### Problem: GTDB-Tk "Not enough markers"

**Cause:** Genome quality too low

**Solutions:**

```bash
# Check genome quality
head results/gtdbtk/identify/gtdbtk.bac120.markers_summary.tsv

# Filter low-quality genomes (need ≥50% completeness)
# Re-run with only good quality genomes
```

---

## ⏱️ Expected Runtimes (Laptop: 8 cores, 32GB RAM)

| Step                 | 50 Genomes  | 100 Genomes  | 200 Genomes   |
| -------------------- | ----------- | ------------ | ------------- |
| **dRep**             | 30-60 min   | 1-2 hrs      | 2-4 hrs       |
| **GTDB-Tk identify** | 1-2 hrs     | 2-4 hrs      | 4-8 hrs       |
| **GTDB-Tk align**    | 30 min      | 1 hr         | 2 hrs         |
| **GTDB-Tk classify** | 1-2 hrs     | 2-4 hrs      | 4-8 hrs       |
| **Total**            | **3-5 hrs** | **6-11 hrs** | **12-22 hrs** |

**Pro tip:** Run overnight for large datasets!

---

## 📊 Understanding Your Results

### dRep Results

**Good dereplication:**

- 40-70% reduction in genome count
- Clear clustering in dendrograms
- High-scoring winners (score >60)

**Red flags:**

- <20% reduction (maybe already dereplicated?)
- > 90% reduction (ANI threshold too high?)
- Many singletons (diverse community or low quality?)

### GTDB-Tk Results

**Good classification:**

- 95-99% of genomes classified
- Clear taxonomic distribution
- ANI values mostly >80%

**Novel discoveries:**

- ANI 90-95%: Potential new species! 🎉
- ANI <90%: Potential new genus! 🎉🎉
- ANI <70%: Potential new family! 🎉🎉🎉

---

## 📁 Final Directory Structure

```
day4_taxonomy/
├── quality_mags/                    # Input from Day 3
│   ├── bin.1.fa
│   ├── bin.2.fa
│   └── ...
├── results/
│   ├── dereplicated/
│   │   ├── dereplicated_genomes/    # ← Species representatives
│   │   ├── data_tables/
│   │   └── figures/
│   ├── gtdbtk/
│   │   ├── classify/
│   │   │   ├── gtdbtk.bac120.summary.tsv  # ← Main results
│   │   │   └── gtdbtk.bac120.classify.tree
│   │   ├── identify/
│   │   └── align/
│   ├── species_catalog.csv          # ← Species list
│   ├── itol_tree.nwk               # ← For iTOL
│   └── itol_phylum_colors.txt      # ← iTOL annotation
└── logs/
    ├── drep.log
    └── gtdbtk.log
```

---

## ✅ Success Checklist

After completing this tutorial:

- [ ] dRep completed with 40-70% reduction
- [ ] Dereplicated genomes in results/dereplicated/dereplicated_genomes/
- [ ] GTDB-Tk classified 95%+ of genomes
- [ ] Species catalog created
- [ ] Tree files ready for visualization
- [ ] Novel species identified (if any)
- [ ] Results documented

---

## 💾 Cloud Computing Alternative

If your laptop struggles:

### Google Colab (Free - 12GB RAM)

```python
# In Colab notebook
!conda install -c bioconda drep gtdbtk
# Upload genomes and run
```

### AWS EC2 r5.2xlarge

- 8 cores, 64GB RAM
- ~$0.50/hour
- Run for 6-12 hours
- Total cost: $3-6

---

## ➡️ Next Steps

After dereplication and classification:

1. **Visualize trees** - Upload to iTOL or use ggtree
2. **Explore taxonomy** - Look for novel species
3. **Prepare for Day 5** - Functional annotation of species representatives

---
