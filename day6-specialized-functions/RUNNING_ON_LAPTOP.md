# Running Day 6 Specialized Functions on Your Laptop/Desktop

Discover hidden genomic capabilities: secondary metabolites, antimicrobial resistance, CAZymes, prophages, CRISPR, and mobile elements.

## 💻 System Requirements

### Minimum Specifications

- **CPU:** 8 cores
- **RAM:** 16 GB (32 GB for InterProScan)
- **Storage:** 100 GB free (databases!)
- **OS:** Linux (Ubuntu 20.04+) or macOS

### Database Reality Check

| Tool         | Database            | Size    | Download Time |
| ------------ | ------------------- | ------- | ------------- |
| antiSMASH    | ClusterBlast + more | ~15 GB  | 30-60 min     |
| CARD-RGI     | CARD                | ~500 MB | 5 min         |
| ABRicate     | Multiple            | ~2 GB   | 10 min        |
| dbCAN        | CAZy + more         | ~3 GB   | 15 min        |
| VirSorter2   | Viral DB            | ~10 GB  | 30 min        |
| InterProScan | Pfam + others       | ~25 GB  | 1-2 hrs       |

**Total: ~60 GB** (one-time setup)

---

## 📦 Quick Installation

### Fast Tools

```bash
# ABRicate (AMR screening)
conda create -n abricate -c bioconda abricate -y
conda activate abricate
abricate-get_db --db all

# MinCED (CRISPR detection)
conda create -n minced -c bioconda minced -y
```

### Medium Tools

```bash
# CARD-RGI (AMR)
conda create -n rgi -c bioconda rgi -y
conda activate rgi
rgi load --card_json ~/card_database/card.json

# dbCAN (CAZymes)
conda create -n dbcan -c bioconda dbcan -y
conda activate dbcan
# Databases auto-download on first run

# VirSorter2 (prophages)
conda create -n virsorter2 -c bioconda virsorter=2 -y
conda activate virsorter2
virsorter setup -d ~/virsorter2-db -j 4
```

### Slow Tools (Worth it!)

```bash
# antiSMASH (BGCs) - 30 min install
conda create -n antismash -c bioconda antismash -y
conda activate antismash
download-antismash-databases

# InterProScan - Use web service or local install
# Web: https://www.ebi.ac.uk/interpro/search/sequence/
```

---

## 🚀 One-Line Commands

### 1. Secondary Metabolites (antiSMASH)

```bash
# Single genome - 30-60 minutes
antismash --output-dir antismash_out --genefinding-tool prodigal --cpus 8 genome.gbk

# With all features - 1-2 hours
antismash --output-dir antismash_out --genefinding-tool prodigal --knownclusterblast --subclusterblast --smcog-trees --cpus 8 genome.gbk

# View results
firefox antismash_out/index.html
```

---

### 2. Antimicrobial Resistance

**Quick screening (ABRicate) - 2 minutes:**

```bash
# Screen all AMR databases
abricate genome.fa > amr_results.tab

# Specific databases
abricate --db card genome.fa > card_amr.tab
abricate --db resfinder genome.fa > resfinder_amr.tab
abricate --db vfdb genome.fa > virulence.tab

# Batch all genomes
abricate genomes/*.fa > all_genomes_amr.tab

# Create summary
abricate --summary all_genomes_amr.tab > amr_summary.tab
```

**Comprehensive (CARD-RGI) - 10 minutes:**

```bash
# From proteins
rgi main -i proteins.faa -o rgi_out -t protein --num_threads 8

# From genome (more sensitive)
rgi main -i genome.fa -o rgi_out -t contig --num_threads 8 --include_loose

# View results
cat rgi_out.txt | column -t | less -S
```

---

### 3. CAZymes (dbCAN)

```bash
# Single genome - 15-20 minutes
run_dbcan proteins.faa protein --out_dir dbcan_out --tools all --threads 8

# View results
cat dbcan_out/overview.txt | column -t | less -S

# Count CAZyme families
cut -f4 dbcan_out/overview.txt | tail -n +2 | sort | uniq -c | sort -rn
```

---

### 4. Prophages (VirSorter2)

```bash
# Detect prophages - 20-40 minutes
virsorter run -i genome.fa -w virsorter2_out --min-length 5000 --min-score 0.5 -j 8 all

# View viral sequences
cat virsorter2_out/final-viral-boundary.tsv

# Extract high-confidence prophages
awk '$6 > 0.9' virsorter2_out/final-viral-score.tsv
```

---

### 5. CRISPR Systems

```bash
# Quick CRISPR detection - 1 minute
minced genome.fa crispr_out.txt

# View CRISPRs
grep "CRISPR" crispr_out.txt

# Count CRISPR arrays
grep -c "CRISPR" crispr_out.txt
```

---

### 6. Mobile Genetic Elements

```bash
# Insertion sequences
abricate --db isfinder genome.fa > insertion_sequences.tab

# Integrons - 5-10 minutes
conda activate integron_finder
integron_finder --cpu 8 genome.fa

# Plasmids
abricate --db plasmidfinder genome.fa > plasmids.tab
```

---

## 📖 Complete 1-Genome Tutorial

### Step 0: Prepare Files

```bash
mkdir -p ~/specialized_analysis
cd ~/specialized_analysis

# Copy genome from Day 4/5
cp ~/day5_annotation/genome1.fa .
cp ~/day5_annotation/prodigal_output/genome1.faa proteins.faa

# If you have GenBank format (better for antiSMASH)
cp ~/day5_annotation/prokka_out/genome1/genome1.gbk .
```

---

### Step 1: Secondary Metabolites (1 hour)

```bash
conda activate antismash

echo "Step 1: Detecting biosynthetic gene clusters..."

antismash \
    --output-dir results/antismash \
    --genefinding-tool prodigal \
    --knownclusterblast \
    --cpus 8 \
    genome1.gbk

# Quick check
bgc_count=$(grep -c "region" results/antismash/genome1.json)
echo "BGCs detected: $bgc_count"

# Open in browser
firefox results/antismash/index.html
```

**Expected:** 5-30 BGCs depending on organism

---

### Step 2: Antimicrobial Resistance (15 min)

```bash
echo "Step 2: Screening antimicrobial resistance..."

# Quick screen
conda activate abricate
abricate genome1.fa > results/abricate_amr.tab

# Comprehensive
conda activate rgi
rgi main -i proteins.faa -o results/rgi_out -t protein --num_threads 8

# Summary
amr_count=$(tail -n +2 results/abricate_amr.tab | wc -l)
echo "AMR genes detected: $amr_count"

# Critical AMR genes
grep -E "mcr|NDM|KPC|VIM|OXA" results/rgi_out.txt && echo "⚠️ CRITICAL AMR DETECTED" || echo "No critical AMR"
```

**Expected:** 0-50 AMR genes (pathogen vs environmental)

---

### Step 3: CAZymes (20 min)

```bash
conda activate dbcan

echo "Step 3: Analyzing carbohydrate-active enzymes..."

run_dbcan \
    proteins.faa \
    protein \
    --out_dir results/dbcan \
    --tools all \
    --threads 8

# Count CAZyme families
echo "CAZyme families detected:"
cut -f4 results/dbcan/overview.txt | tail -n +2 | sort | uniq -c | sort -rn | head -10

# Cellulose degradation
cellulose=$(grep -E "GH5|GH6|GH7|GH9|GH45" results/dbcan/overview.txt | wc -l)
echo "Cellulose degradation genes: $cellulose"

# Starch degradation
starch=$(grep -E "GH13|GH14|GH15" results/dbcan/overview.txt | wc -l)
echo "Starch degradation genes: $starch"
```

**Expected:** 50-500 CAZymes

---

### Step 4: Prophages (30 min)

```bash
conda activate virsorter2

echo "Step 4: Detecting prophages..."

virsorter run \
    -i genome1.fa \
    -w results/virsorter2 \
    --min-length 5000 \
    --min-score 0.5 \
    -j 8 \
    all

# Count prophages
prophage_count=$(tail -n +2 results/virsorter2/final-viral-boundary.tsv | wc -l)
echo "Prophages detected: $prophage_count"

# High-confidence prophages
high_conf=$(awk '$6 > 0.9' results/virsorter2/final-viral-score.tsv | wc -l)
echo "High-confidence prophages: $high_conf"
```

**Expected:** 0-10 prophages

---

### Step 5: CRISPR Systems (2 min)

```bash
conda activate minced

echo "Step 5: Detecting CRISPR systems..."

minced genome1.fa results/crispr_out.txt

# Count CRISPR arrays
crispr_count=$(grep -c "CRISPR" results/crispr_out.txt)
echo "CRISPR arrays: $crispr_count"

# Show details
grep "CRISPR" results/crispr_out.txt
```

**Expected:** 0-5 CRISPR arrays

---

### Step 6: Mobile Elements (5 min)

```bash
conda activate abricate

echo "Step 6: Screening mobile genetic elements..."

# Insertion sequences
abricate --db isfinder genome1.fa > results/insertion_sequences.tab
is_count=$(tail -n +2 results/insertion_sequences.tab | wc -l)
echo "Insertion sequences: $is_count"

# Plasmid replicons
abricate --db plasmidfinder genome1.fa > results/plasmids.tab
plasmid_count=$(tail -n +2 results/plasmids.tab | wc -l)
echo "Plasmid replicons: $plasmid_count"

# Integrons
conda activate integron_finder
integron_finder --cpu 8 genome1.fa
integron_count=$(find Results_Integron_Finder_genome1.fa -name "*.integrons" | wc -l)
echo "Integrons: $integron_count"
```

---

### Step 7: Create Summary Report

```bash
echo "Creating summary report..."

cat > results/SUMMARY.txt << EOF
==========================================
  Specialized Functions Summary
  Genome: genome1
  Date: $(date)
==========================================

BGCs (antiSMASH):              $bgc_count
AMR genes (ABRicate):          $amr_count
CAZymes (dbCAN):               $(wc -l < results/dbcan/overview.txt | awk '{print $1-1}')
  - Cellulose degradation:     $cellulose
  - Starch degradation:        $starch
Prophages (VirSorter2):        $prophage_count
  - High confidence:           $high_conf
CRISPR arrays (MinCED):        $crispr_count
Insertion sequences:           $is_count
Plasmid replicons:             $plasmid_count
Integrons:                     $integron_count

==========================================
Key Findings:
EOF

# Add critical findings
if [ $amr_count -gt 10 ]; then
    echo "  ⚠️ High AMR gene count detected" >> results/SUMMARY.txt
fi

if [ $bgc_count -gt 15 ]; then
    echo "  🧪 Rich secondary metabolite potential" >> results/SUMMARY.txt
fi

if [ $cellulose -gt 5 ]; then
    echo "  🍬 Strong cellulose degradation capability" >> results/SUMMARY.txt
fi

cat results/SUMMARY.txt
```

---

## 🔄 Batch Processing (10 Genomes)

### Simple Loop Script

Create `batch_specialized_analysis.sh`:

```bash
#!/bin/bash
# Batch analysis of specialized functions
# Usage: bash batch_specialized_analysis.sh

GENOMES_DIR="genomes"
OUTPUT_DIR="specialized_results"
CPUS=8

mkdir -p $OUTPUT_DIR

# List of genomes
GENOMES=($(ls $GENOMES_DIR/*.fa))

echo "Processing ${#GENOMES[@]} genomes..."

for genome in "${GENOMES[@]}"; do
    name=$(basename $genome .fa)
    echo ""
    echo "========================================="
    echo "Processing: $name"
    echo "========================================="

    mkdir -p $OUTPUT_DIR/$name

    # 1. AMR screening (fast)
    echo "[1/6] AMR screening..."
    conda activate abricate
    abricate $genome > $OUTPUT_DIR/$name/amr.tab

    # 2. CAZymes (medium)
    echo "[2/6] CAZymes..."
    conda activate dbcan
    run_dbcan ${genome%.fa}.faa protein \
        --out_dir $OUTPUT_DIR/$name/dbcan \
        --tools hmmer --threads $CPUS

    # 3. Prophages (medium)
    echo "[3/6] Prophages..."
    conda activate virsorter2
    virsorter run -i $genome \
        -w $OUTPUT_DIR/$name/virsorter2 \
        -j $CPUS all

    # 4. CRISPR (fast)
    echo "[4/6] CRISPR..."
    conda activate minced
    minced $genome $OUTPUT_DIR/$name/crispr.txt

    # 5. Mobile elements (fast)
    echo "[5/6] Mobile elements..."
    conda activate abricate
    abricate --db isfinder $genome > $OUTPUT_DIR/$name/is.tab

    # 6. antiSMASH (slow - optional)
    if [ -f "${genome%.fa}.gbk" ]; then
        echo "[6/6] BGCs (this may take 30-60 min)..."
        conda activate antismash
        antismash --output-dir $OUTPUT_DIR/$name/antismash \
                  --cpus $CPUS \
                  --genefinding-tool prodigal \
                  ${genome%.fa}.gbk
    fi

    echo "✓ $name completed"
done

echo ""
echo "========================================="
echo "All genomes processed!"
echo "Results in: $OUTPUT_DIR"
echo "========================================="
```

**Runtime:** ~2-3 hours for 10 genomes (without antiSMASH), ~10-12 hours with antiSMASH

---

### Priority-Based Loop (Fast Tools Only)

For quick screening without antiSMASH:

```bash
#!/bin/bash
# quick_screen.sh - Fast specialized function screening

for genome in genomes/*.fa; do
    name=$(basename $genome .fa)
    echo "Screening $name..."

    # AMR (2 min)
    abricate $genome > quick_results/${name}_amr.tab

    # Mobile elements (2 min)
    abricate --db isfinder $genome > quick_results/${name}_is.tab
    abricate --db plasmidfinder $genome > quick_results/${name}_plasmids.tab

    # CRISPR (1 min)
    minced $genome quick_results/${name}_crispr.txt

    echo "✓ $name done (5 min)"
done

# Create summary
abricate --summary quick_results/*_amr.tab > quick_results/AMR_SUMMARY.tab
echo "✓ All genomes screened in ~50 minutes!"
```

---

## 📊 Quick Result Checks

### Check BGCs

```bash
# Count BGCs
bgc_count=$(grep -c "region" antismash_out/genome1.json)
echo "BGCs: $bgc_count"

# BGC types
grep "products" antismash_out/genome1.json | head -5
```

### Check AMR

```bash
# Total AMR genes
tail -n +2 amr_results.tab | wc -l

# Critical AMR
grep -iE "mcr|NDM|KPC|VIM|OXA|CTX-M" amr_results.tab

# Drug classes
cut -f14 rgi_out.txt | tail -n +2 | sort | uniq -c | sort -rn
```

### Check CAZymes

```bash
# Total CAZymes
tail -n +2 dbcan_out/overview.txt | wc -l

# Top families
cut -f4 dbcan_out/overview.txt | tail -n +2 | sort | uniq -c | sort -rn | head -10

# Degradation potential
grep -E "GH5|GH6|GH7" dbcan_out/overview.txt | wc -l  # Cellulose
grep -E "GH13|GH14" dbcan_out/overview.txt | wc -l   # Starch
```

### Check Prophages

```bash
# Count prophages
tail -n +2 virsorter2_out/final-viral-boundary.tsv | wc -l

# High-confidence only
awk '$6 > 0.9' virsorter2_out/final-viral-score.tsv | wc -l
```

---

## ⏱️ Time Estimates (8-core laptop)

### Single Genome

| Tool                    | Time      | Can Skip?             |
| ----------------------- | --------- | --------------------- |
| ABRicate (AMR)          | 2 min     | No - critical         |
| MinCED (CRISPR)         | 1 min     | No - fast             |
| dbCAN (CAZymes)         | 15-20 min | Sometimes             |
| VirSorter2 (prophages)  | 30-40 min | Sometimes             |
| antiSMASH (BGCs)        | 30-60 min | For slow laptops      |
| RGI (comprehensive AMR) | 10 min    | If ABRicate is enough |
| InterProScan            | 1-2 hrs   | Use web service       |

**Fast screening (AMR + CRISPR + MGEs):** 5 minutes  
**Standard analysis (add CAZymes + prophages):** 1 hour  
**Complete analysis (add antiSMASH):** 2 hours

### 10 Genomes

| Workflow                              | Time      |
| ------------------------------------- | --------- |
| **Fast screen** (ABRicate + MinCED)   | 50 min    |
| **Standard** (add dbCAN + VirSorter2) | 8-10 hrs  |
| **Complete** (add antiSMASH)          | 15-20 hrs |

**Recommendation:** Run overnight for 10 genomes

---

## 💡 Laptop-Friendly Strategies

### Strategy 1: Prioritize Fast Tools

```bash
# Day 1: Fast screening
abricate genome.fa > amr.tab
minced genome.fa crispr.txt

# Day 2: Medium tools
run_dbcan proteins.faa protein --out_dir dbcan_out --threads 8

# Day 3: Slow tools
antismash --output-dir antismash_out --cpus 8 genome.gbk
```

### Strategy 2: Use Web Services

- **InterProScan:** https://www.ebi.ac.uk/interpro/
- **PHASTER:** https://phaster.ca/
- **antiSMASH:** https://antismash.secondarymetabolites.org/

Upload genome, get email when done!

### Strategy 3: Cloud Computing

```bash
# AWS EC2 c5.2xlarge (8 cores, 16 GB RAM)
# Cost: ~$0.34/hour
# 10 genomes complete analysis: ~$6
```

---

## 🔧 Troubleshooting

### antiSMASH: Too Slow

```bash
# Skip optional analyses
antismash --minimal --cpus 8 genome.gbk

# Or use --taxon for faster processing
antismash --taxon bacteria --cpus 8 genome.gbk
```

### VirSorter2: High Memory

```bash
# Reduce database groups
virsorter run -i genome.fa -w out --db-dir ~/virsorter2-db/db --groups dsDNAphage -j 8
```

### dbCAN: Installation Issues

```bash
# Use docker instead
docker pull haidyi/run_dbcan:latest
docker run --rm -v $(pwd):/data haidyi/run_dbcan proteins.faa protein
```

---

## 📁 Final Directory Structure

```
specialized_analysis/
├── genome1.fa
├── proteins.faa
├── genome1.gbk
└── results/
    ├── antismash/
    │   └── index.html              # ← Open in browser!
    ├── abricate_amr.tab
    ├── rgi_out.txt
    ├── dbcan/
    │   └── overview.txt
    ├── virsorter2/
    │   └── final-viral-boundary.tsv
    ├── crispr_out.txt
    ├── insertion_sequences.tab
    ├── plasmids.tab
    └── SUMMARY.txt                  # ← Quick overview
```

---

## ✅ Quick Reference Card

```bash
# AMR screening (2 min)
abricate genome.fa > amr.tab

# CAZymes (20 min)
run_dbcan proteins.faa protein --out_dir dbcan --threads 8

# BGCs (60 min)
antismash --output-dir antismash --cpus 8 genome.gbk

# Prophages (30 min)
virsorter run -i genome.fa -w virsorter2 -j 8 all

# CRISPR (1 min)
minced genome.fa crispr.txt

# Mobile elements (2 min)
abricate --db isfinder genome.fa > is.tab
```
