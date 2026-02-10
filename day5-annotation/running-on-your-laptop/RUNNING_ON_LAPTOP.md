# Running Day 5 Genome Annotation on Your Laptop/Desktop

Practical guide for annotating MAGs on personal computers with real-world commands you'll actually use.

## 💻 System Requirements

### Minimum Specifications

- **CPU:** 8 cores
- **RAM:** 16 GB (32 GB recommended for DRAM)
- **Storage:** 300 GB free (databases are huge!)
- **OS:** Linux (Ubuntu 20.04+) or macOS

### Database Size Reality Check

| Tool      | Database Size | One-time? |
| --------- | ------------- | --------- |
| Prokka    | ~2 GB         | ✅ Yes    |
| eggNOG    | ~45 GB        | ✅ Yes    |
| DRAM      | ~200 GB       | ✅ Yes    |
| METABOLIC | ~50 GB        | ✅ Yes    |

**Good news:** Download once, use forever!

---

## 📦 Quick Installation

### Basic Tools (Fast)

```bash
# Prodigal (gene prediction) - 2 minutes
conda create -n prodigal -c bioconda prodigal -y
conda activate prodigal
prodigal -v

# Prokka (rapid annotation) - 5 minutes
conda create -n prokka -c bioconda prokka -y
conda activate prokka
prokka --version
```

### Advanced Tools (Takes longer)

```bash
# eggNOG-mapper - 10 minutes install + 2 hours database download
conda create -n eggnog -c bioconda eggnog-mapper -y
conda activate eggnog
download_eggnog_data.py -y  # ~45 GB, grab coffee!

# DRAM - 15 minutes install + 4-6 hours database setup
conda create -n dram -c bioconda dram -y
conda activate dram
DRAM-setup.py prepare_databases --output_dir ~/DRAM_data

# METABOLIC - 10 minutes
conda create -n metabolic -c bioconda metabolic -y
```

---

## 🚀 One-Line Commands (What You'll Actually Use)

### Prodigal: Predict Genes

```bash
# Single genome - 30 seconds
prodigal -i genome.fa -a proteins.faa -d genes.fna -f gbk -o genes.gbk

# Batch all genomes - 5 minutes for 50 genomes
for f in genomes/*.fa; do prodigal -i $f -a ${f%.fa}.faa -d ${f%.fa}.fna -f gbk -o ${f%.fa}.gbk; done
```

**What you get:** Protein and gene sequences ready for downstream analysis

---

### Prokka: Quick Annotation

```bash
# Basic annotation - 1 genome in 3-5 minutes
prokka --outdir prokka_out --prefix my_genome --cpus 8 genome.fa

# With taxonomy info (better results) - 3-5 minutes
prokka --outdir prokka_out --prefix ecoli_genome --genus Escherichia --species coli --cpus 8 genome.fa

# Batch mode - just loop it
for f in genomes/*.fa; do name=$(basename $f .fa); prokka --outdir prokka_out/$name --prefix $name --cpus 8 $f; done
```

**What you get:** GFF, GenBank, protein files - ready for NCBI submission!

---

### eggNOG-mapper: Functional Annotation

```bash
# Single genome proteins - 10-30 minutes depending on size
emapper.py -i proteins.faa -o genome --output_dir eggnog_out --cpu 8 -m diamond

# Use Prodigal output directly
emapper.py -i prodigal_output/genome.faa -o genome --output_dir eggnog_out --cpu 8 -m diamond

# Batch mode - overnight for 50 genomes
for f in prodigal_output/*.faa; do name=$(basename $f .faa); emapper.py -i $f -o $name --output_dir eggnog_out --cpu 8 -m diamond; done
```

**What you get:** KEGG pathways, EC numbers, GO terms, COG categories

---

### DRAM: Metabolic Annotation

```bash
# Single genome - 30-60 minutes
DRAM.py annotate -i 'genome.fa' -o dram_output --threads 8

# Multiple genomes - 2-6 hours for 50 genomes
DRAM.py annotate -i 'genomes/*.fa' -o dram_output --threads 8 --min_contig_size 1000

# Distill results (metabolic summary) - 5 minutes
DRAM.py distill -i dram_output/annotations.tsv -o dram_distillate --trna_path dram_output/trnas.tsv --rrna_path dram_output/rrnas.tsv
```

**What you get:** Metabolic pathways, CAZymes, transporters - beautiful HTML report!

---

### METABOLIC: Comprehensive Pathways

```bash
# Run on genome directory - 1-3 hours for 50 genomes
perl METABOLIC-G.pl -in-gn genomes/ -o metabolic_output -t 8

# With custom module cutoff
perl METABOLIC-G.pl -in-gn genomes/ -o metabolic_output -t 8 -m-cutoff 0.75
```

**What you get:** Excel sheets with 40+ metabolic pathways, interactive diagrams

---

## 📖 Complete 1-Sample Tutorial

### Step 0: Setup

```bash
# Create project directory
mkdir -p ~/annotation_project
cd ~/annotation_project
mkdir -p results/{prodigal,prokka,eggnog,dram,metabolic}

# Copy your MAG
cp ~/day4_taxonomy/species_representatives/genome1.fa .
```

---

### Step 1: Gene Prediction (2 minutes)

```bash
conda activate prodigal

echo "Step 1: Predicting genes with Prodigal..."
prodigal -i genome1.fa \
         -a results/prodigal/genome1.faa \
         -d results/prodigal/genome1.fna \
         -f gbk \
         -o results/prodigal/genome1.gbk

# Quick check
echo "Genes predicted: $(grep -c '>' results/prodigal/genome1.faa)"
```

**Expected:** ~1000 genes per Mb of genome

---

### Step 2: Quick Annotation with Prokka (5 minutes)

```bash
conda activate prokka

echo "Step 2: Quick annotation with Prokka..."
prokka --outdir results/prokka/genome1 \
       --prefix genome1 \
       --cpus 8 \
       genome1.fa

# Check annotation rate
total=$(grep -c "CDS" results/prokka/genome1/genome1.tsv)
annotated=$(grep -vc "hypothetical protein" results/prokka/genome1/genome1.tsv)
echo "Annotation rate: $annotated/$total genes"
```

**Expected:** 60-80% of genes annotated

---

### Step 3: Deep Functional Annotation (30 minutes)

```bash
conda activate eggnog

echo "Step 3: Functional annotation with eggNOG-mapper..."
emapper.py -i results/prodigal/genome1.faa \
           -o genome1 \
           --output_dir results/eggnog \
           --cpu 8 \
           -m diamond

# Parse KEGG pathways
grep -v "^#" results/eggnog/genome1.emapper.annotations | \
  cut -f12 | grep -v "^-$" | sort -u > results/eggnog/kegg_pathways.txt

echo "KEGG pathways identified: $(wc -l < results/eggnog/kegg_pathways.txt)"
```

**Expected:** 70-90% genes with functional annotation

---

### Step 4: Metabolic Analysis with DRAM (1 hour)

```bash
conda activate dram

echo "Step 4: Metabolic annotation with DRAM..."
DRAM.py annotate \
    -i 'genome1.fa' \
    -o results/dram \
    --threads 8 \
    --min_contig_size 1000

# Distill metabolic summary
DRAM.py distill \
    -i results/dram/annotations.tsv \
    -o results/dram/distillate \
    --trna_path results/dram/trnas.tsv \
    --rrna_path results/dram/rrnas.tsv

echo "✓ Open results/dram/distillate/product.html in browser!"
```

**Expected:** Beautiful interactive metabolic report

---

### Step 5: Comprehensive Pathways (30 minutes)

```bash
conda activate metabolic

echo "Step 5: Comprehensive pathway analysis..."
mkdir -p metabolic_input
cp genome1.fa metabolic_input/

perl METABOLIC-G.pl \
    -in-gn metabolic_input \
    -o results/metabolic \
    -t 8

echo "✓ Check results/metabolic/METABOLIC_result.xlsx"
```

**Expected:** Complete metabolic capability matrix

---

## 💡 Real-World Workflows

### Workflow 1: Quick Screen (15 minutes)

```bash
# Just want to know what genes are there?
conda activate prokka
prokka --outdir quick_check --prefix genome --cpus 8 genome.fa
cat quick_check/genome.txt  # Read the summary
```

**Use when:** You need fast results, NCBI submission

---

### Workflow 2: Functional Focus (1 hour)

```bash
# Need functional categories and pathways?
conda activate prodigal
prodigal -i genome.fa -a proteins.faa -f gbk -o genes.gbk

conda activate eggnog
emapper.py -i proteins.faa -o genome --cpu 8 -m diamond

# Parse results
grep -v "^#" genome.emapper.annotations | cut -f1,5,8,12 > functional_summary.tsv
```

**Use when:** Comparative genomics, functional analysis

---

### Workflow 3: Metabolic Deep Dive (3 hours)

```bash
# Want complete metabolic picture?
conda activate dram
DRAM.py annotate -i 'genome.fa' -o dram_out --threads 8
DRAM.py distill -i dram_out/annotations.tsv -o dram_distill

# Open the HTML report
firefox dram_distill/product.html
```

**Use when:** Metabolic modeling, environmental studies

---

### Workflow 4: Publication Quality (Full day)

```bash
# Run everything for comprehensive analysis
prodigal -i genome.fa -a proteins.faa
prokka --outdir prokka_out --prefix genome --cpus 8 genome.fa
emapper.py -i proteins.faa -o genome --cpu 8
DRAM.py annotate -i 'genome.fa' -o dram_out --threads 8
perl METABOLIC-G.pl -in-gn genome_dir -o metabolic_out -t 8

# Compile all results
python compile_annotations.py
```

**Use when:** Writing papers, grant proposals

---

## 🎯 Batch Processing Examples

### Process 10 Genomes with Prokka

```bash
#!/bin/bash
# batch_prokka.sh

conda activate prokka

for genome in species_representatives/*.fa; do
    name=$(basename $genome .fa)
    echo "Processing: $name"

    prokka --outdir prokka_batch/$name \
           --prefix $name \
           --cpus 8 \
           --force \
           $genome

    echo "✓ $name completed"
done

echo "All genomes annotated!"
```

**Runtime:** ~50 minutes for 10 genomes

---

### Process 10 Genomes with DRAM

```bash
#!/bin/bash
# batch_dram.sh

conda activate dram

# Annotate all at once (DRAM handles multiple genomes)
DRAM.py annotate \
    -i 'species_representatives/*.fa' \
    -o dram_batch \
    --threads 8 \
    --min_contig_size 1000

# Distill results
DRAM.py distill \
    -i dram_batch/annotations.tsv \
    -o dram_batch/distillate \
    --trna_path dram_batch/trnas.tsv \
    --rrna_path dram_batch/rrnas.tsv

echo "✓ Open dram_batch/distillate/product.html"
```

**Runtime:** 2-4 hours for 10 genomes

---

## 📊 Quick Result Checks

### Check Prodigal Output

```bash
# Count genes
grep -c ">" proteins.faa

# Check gene lengths
grep ">" proteins.faa | sed 's/.*# //' | awk '{print $1-$2}' | \
  awk '{sum+=$1; n++} END {print "Mean gene length:", sum/n, "bp"}'
```

---

### Check Prokka Annotation Rate

```bash
total=$(grep -c "CDS" prokka_out/genome.tsv)
hypo=$(grep -c "hypothetical protein" prokka_out/genome.tsv)
annotated=$((total - hypo))
rate=$((annotated * 100 / total))

echo "Total: $total"
echo "Annotated: $annotated ($rate%)"
echo "Hypothetical: $hypo"
```

---

### Check eggNOG KEGG Coverage

```bash
# Extract KEGG pathways
grep -v "^#" genome.emapper.annotations | \
  awk -F'\t' '$12 != "-" {print $12}' | \
  tr ',' '\n' | sort -u > kegg_pathways.txt

echo "KEGG pathways: $(wc -l < kegg_pathways.txt)"

# Count genes per pathway
grep -v "^#" genome.emapper.annotations | \
  awk -F'\t' '$12 != "-" {print $12}' | \
  tr ',' '\n' | sort | uniq -c | sort -rn | head -10
```

---

## 🔧 Troubleshooting

### Prodigal: No Output

```bash
# Check if genome is DNA (not protein)
head -20 genome.fa

# Check for weird characters
cat genome.fa | tr -d 'ACGTN\n>' | wc -c  # Should be 0

# Try meta mode for fragmented genomes
prodigal -i genome.fa -a proteins.faa -p meta
```

---

### Prokka: Low Annotation

```bash
# Update database
prokka --setupdb

# Add taxonomy for better hits
prokka --genus Bacteroides --species uniformis ...

# Check if proteins are being predicted
ls -lh prokka_out/*.faa  # Should not be empty
```

---

### eggNOG: Slow or Hangs

```bash
# Use diamond (faster) instead of mmseqs
emapper.py -m diamond ...  # not -m mmseqs

# Reduce CPU if memory limited
emapper.py --cpu 4 ...

# Check database location
ls -lh ~/eggnog_data/
```

---

### DRAM: Database Errors

```bash
# Verify DRAM databases exist
echo $DRAM_CONFIG_LOCATION
cat $DRAM_CONFIG_LOCATION

# Re-setup if needed
DRAM-setup.py prepare_databases --output_dir ~/DRAM_data --verbose

# Set manually
export DRAM_DB_LOC=~/DRAM_data
```

---

## ⏱️ Time Estimates (8-core laptop)

| Tool          | 1 Genome | 10 Genomes | 50 Genomes |
| ------------- | -------- | ---------- | ---------- |
| **Prodigal**  | 30 sec   | 5 min      | 20 min     |
| **Prokka**    | 5 min    | 50 min     | 4 hrs      |
| **eggNOG**    | 30 min   | 5 hrs      | 24 hrs     |
| **DRAM**      | 1 hr     | 3-4 hrs    | 12-20 hrs  |
| **METABOLIC** | 30 min   | 2-3 hrs    | 8-12 hrs   |

**Pro tip:** Run DRAM or eggNOG overnight!

---

## 💾 Cloud Computing Options

If laptop struggles:

### Google Colab (Free - 12 GB RAM)

- Good for: Prodigal, Prokka (small batches)
- Not for: DRAM, METABOLIC (too memory intensive)

### AWS EC2 r5.2xlarge

- 8 cores, 64 GB RAM
- ~$0.50/hour
- Can run all tools
- Cost for 50 genomes: ~$10

---

## 📁 Final Directory Structure

```
annotation_project/
├── genomes/                    # Input MAGs
│   ├── genome1.fa
│   ├── genome2.fa
│   └── ...
├── results/
│   ├── prodigal/              # Gene predictions
│   │   ├── genome1.faa
│   │   ├── genome1.fna
│   │   └── genome1.gbk
│   ├── prokka/                # Quick annotations
│   │   ├── genome1/
│   │   │   ├── genome1.gff
│   │   │   ├── genome1.gbk
│   │   │   └── genome1.tsv
│   │   └── genome2/
│   ├── eggnog/                # Functional annotations
│   │   ├── genome1.emapper.annotations
│   │   └── genome2.emapper.annotations
│   ├── dram/                  # Metabolic annotations
│   │   ├── annotations.tsv
│   │   └── distillate/
│   │       └── product.html   # ← VIEW THIS!
│   └── metabolic/             # Comprehensive pathways
│       └── METABOLIC_result.xlsx
└── scripts/
    ├── batch_prokka.sh
    └── batch_dram.sh
```

---

## ✅ Quick Reference Card

```bash
# Gene prediction
prodigal -i genome.fa -a proteins.faa

# Quick annotation
prokka --outdir out --prefix name --cpus 8 genome.fa

# Functional annotation
emapper.py -i proteins.faa -o name --cpu 8 -m diamond

# Metabolic annotation
DRAM.py annotate -i 'genome.fa' -o out --threads 8
DRAM.py distill -i out/annotations.tsv -o distill

# Comprehensive pathways
perl METABOLIC-G.pl -in-gn genomes/ -o out -t 8
```

**Bookmark this!**

---

## 🎓 Which Tool When?

| Your Goal             | Use This      |
| --------------------- | ------------- |
| Just genes            | Prodigal      |
| NCBI submission       | Prokka        |
| Functional categories | eggNOG-mapper |
| Metabolic focus       | DRAM          |
| All pathways          | METABOLIC     |
| Complete analysis     | All of them!  |

---

<div align="center">

**[⬆ Back to Day 5](../README.md)** | **[← Day 4](../../day4-dereplication-taxonomy/)** | **[Resources →](../../resources/)**

_Practical commands for real people_

</div>
