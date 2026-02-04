# Running Day 2 Assembly on Your Laptop/Desktop

This guide provides practical instructions for running metagenome assembly on personal computers with limited resources.

## 💻 System Requirements

### Minimum Specifications

- **CPU:** 4 cores (Intel i5/i7 or AMD Ryzen 5/7)
- **RAM:** 8 GB (16 GB strongly recommended)
- **Storage:** 50 GB free space
- **OS:** Linux, macOS, or Windows (WSL2)

### Recommended Specifications

- **CPU:** 8+ cores
- **RAM:** 16-32 GB
- **Storage:** 100 GB SSD
- **OS:** Linux (Ubuntu 20.04/22.04)

## 📦 Software Installation

### Quick Setup (Using Conda)

```bash
# Create environment for Day 2
conda create -n day2_assembly python=3.9
conda activate day2_assembly

# Install essential tools
conda install -c bioconda -c conda-forge \
    megahit \
    quast \
    bowtie2 \
    samtools \
    seqkit \
    biopython

# Optional: metaSPAdes (if you have enough RAM)
conda install -c bioconda spades
```

### Verify Installation

```bash
# Check versions
megahit --version
metaquast.py --version
bowtie2 --version
samtools --version

# Everything should print version numbers
```

## 🎯 Strategy for Limited Resources

### 1. Use MEGAHIT (Not metaSPAdes)

**Why MEGAHIT for laptops?**

- ✅ Uses only 8-16 GB RAM
- ✅ 10x faster than metaSPAdes
- ✅ Still produces good quality assemblies
- ✅ Perfect for learning and testing

**When to use metaSPAdes:**

- Only if you have 64GB+ RAM
- For final, publication-quality assemblies
- When you have access to HPC

### 2. Work with Subsampled Data

If your dataset is large (>10M read pairs), subsample first:

```bash
# Subsample to 2 million read pairs (~600 MB files)
seqtk sample -s100 large_R1.fastq.gz 2000000 | gzip > subset_R1.fastq.gz
seqtk sample -s100 large_R2.fastq.gz 2000000 | gzip > subset_R2.fastq.gz
```

### 3. Optimize Parameters

```bash
# For MEGAHIT on laptops:
# - Reduce k-mer max to 99 (instead of 141)
# - Use 80% of available RAM
# - Limit threads to n-2 cores
```

## 🚀 Complete 1-Sample Tutorial

### Step 0: Prepare Your Environment

```bash
# Create project directory
mkdir -p ~/metagenome_project/day2_assembly
cd ~/metagenome_project/day2_assembly

# Create subdirectories
mkdir -p data results logs scripts

# Activate environment
conda activate day2_assembly
```

### Step 1: Prepare Input Data

For this tutorial, we'll use a **single sample** from Day 1.

```bash
# Copy cleaned reads from Day 1
# Assuming you completed Day 1 and have clean reads
cp ../day1-qc-read-based/results/trimmed/sample1_R1_paired.fastq.gz data/
cp ../day1-qc-read-based/results/trimmed/sample1_R2_paired.fastq.gz data/

# Verify files exist
ls -lh data/
```

**Expected output:**

```
-rw-r--r-- 1 user user 450M sample1_R1_paired.fastq.gz
-rw-r--r-- 1 user user 450M sample1_R2_paired.fastq.gz
```

**If you don't have Day 1 data:**
Download tutorial data (see `DATA.md` in repository (day1))

### Step 2: Quick Data Check

```bash
# Check number of reads (should take ~1 minute)
echo "Counting reads in R1..."
reads_R1=$(zcat data/sample1_R1_paired.fastq.gz | wc -l | awk '{print $1/4}')
echo "Read pairs: $reads_R1"

# If >5M reads, consider subsampling for faster testing:
if [ $reads_R1 -gt 5000000 ]; then
    echo "Large dataset detected. Subsampling to 2M reads for testing..."
    seqtk sample -s100 data/sample1_R1_paired.fastq.gz 2000000 | \
        gzip > data/sample1_R1_subset.fastq.gz
    seqtk sample -s100 data/sample1_R2_paired.fastq.gz 2000000 | \
        gzip > data/sample1_R2_subset.fastq.gz

    # Use subsampled files
    R1="data/sample1_R1_subset.fastq.gz"
    R2="data/sample1_R2_subset.fastq.gz"
else
    R1="data/sample1_R1_paired.fastq.gz"
    R2="data/sample1_R2_paired.fastq.gz"
fi
```

### Step 3: Assembly with MEGAHIT

This is the main step - grab a coffee! ☕

```bash
# Check available RAM
free -h

# Set parameters based on your system
THREADS=4           # Use n-2 of your CPU cores
SAMPLE="sample1"

echo "========================================="
echo "  Starting MEGAHIT Assembly"
echo "========================================="
echo "Sample: ${SAMPLE}"
echo "Threads: ${THREADS}"
echo "Start time: $(date)"
echo ""

# Run MEGAHIT
megahit \
    -1 ${R1} \
    -2 ${R2} \
    -o results/${SAMPLE}_megahit \
    -t ${THREADS} \
    --k-min 21 \
    --k-max 99 \
    --k-step 20 \
    --min-contig-len 500 \
    --memory 0.8 \
    2>&1 | tee logs/${SAMPLE}_assembly.log

echo ""
echo "End time: $(date)"
echo ""
```

**What to expect:**

- **Time:** 1-4 hours depending on data size and your CPU
- **RAM usage:** Will gradually increase, peak around 8-12 GB
- **Progress:** MEGAHIT shows progress bars - you can monitor them

**Monitor progress in another terminal:**

```bash
# Watch RAM usage
htop

# Or check log file
tail -f logs/sample1_assembly.log
```

### Step 4: Check Assembly Success

```bash
# Check if assembly completed
if [ -f "results/${SAMPLE}_megahit/final.contigs.fa" ]; then
    echo "✓ Assembly successful!"

    # Copy to easy-to-find location
    cp results/${SAMPLE}_megahit/final.contigs.fa \
       results/${SAMPLE}_contigs.fasta

    # Quick statistics
    echo ""
    echo "Quick statistics:"
    total_contigs=$(grep -c "^>" results/${SAMPLE}_contigs.fasta)
    echo "  Total contigs: ${total_contigs}"

else
    echo "✗ Assembly failed!"
    echo "Check log file: logs/${SAMPLE}_assembly.log"
    exit 1
fi
```

### Step 5: Detailed Assembly Statistics

Let's calculate comprehensive statistics using Python:

```bash
# Create a quick stats script
cat > scripts/quick_stats.py << 'EOF'
#!/usr/bin/env python3
from Bio import SeqIO
import statistics

fasta_file = "results/sample1_contigs.fasta"
lengths = [len(rec.seq) for rec in SeqIO.parse(fasta_file, "fasta")]
lengths_sorted = sorted(lengths, reverse=True)
total_length = sum(lengths)

# Calculate N50
cumsum = 0
n50 = 0
for length in lengths_sorted:
    cumsum += length
    if cumsum >= total_length / 2:
        n50 = length
        break

print("\n" + "="*50)
print("  Assembly Statistics")
print("="*50)
print(f"Total contigs:      {len(lengths):,}")
print(f"Total length:       {total_length:,} bp")
print(f"Longest contig:     {max(lengths):,} bp")
print(f"Mean length:        {statistics.mean(lengths):.0f} bp")
print(f"Median length:      {statistics.median(lengths):.0f} bp")
print(f"N50:                {n50:,} bp")
print("")

# Size distribution
print("Contigs by size:")
for min_len in [500, 1000, 5000, 10000, 50000]:
    count = sum(1 for l in lengths if l >= min_len)
    print(f"  >= {min_len:>6} bp: {count:>6,} contigs")
print("="*50 + "\n")
EOF

chmod +x scripts/quick_stats.py
python scripts/quick_stats.py
```

**Expected output:**

```
==================================================
  Assembly Statistics
==================================================
Total contigs:      25,432
Total length:       45,678,901 bp
Longest contig:     156,789 bp
Mean length:        1,796 bp
Median length:      892 bp
N50:                3,456 bp

Contigs by size:
  >=    500 bp: 25,432 contigs
  >= 1,000 bp: 12,345 contigs
  >= 5,000 bp:  2,456 contigs
  >= 10,000 bp:   892 contigs
  >= 50,000 bp:    45 contigs
==================================================
```

### Step 6: Quality Assessment with MetaQUAST

```bash
echo "Running MetaQUAST quality assessment..."

metaquast.py \
    results/${SAMPLE}_contigs.fasta \
    -o results/${SAMPLE}_metaquast \
    -t ${THREADS} \
    --min-contig 500 \
    --fast \
    2>&1 | tee logs/${SAMPLE}_metaquast.log

echo "✓ MetaQUAST complete!"
echo "View report: results/${SAMPLE}_metaquast/report.html"
```

**View the report:**

```bash
# On Linux
firefox results/sample1_metaquast/report.html

# On macOS
open results/sample1_metaquast/report.html

# On Windows (WSL2)
explorer.exe results/sample1_metaquast/report.html
```

### Step 7: Calculate Coverage (for Day 3 Binning)

This step prepares data for genome binning in Day 3.

```bash
echo "========================================="
echo "  Calculating Contig Coverage"
echo "========================================="
echo ""

CONTIGS="results/${SAMPLE}_contigs.fasta"

# Step 1: Build Bowtie2 index (5-10 minutes)
echo "[1/4] Building Bowtie2 index..."
bowtie2-build --threads ${THREADS} \
    ${CONTIGS} \
    results/${SAMPLE}_index \
    2>&1 | tee logs/${SAMPLE}_bowtie2_build.log

# Step 2: Map reads to contigs (30-90 minutes)
echo ""
echo "[2/4] Mapping reads to contigs..."
echo "This is the longest step - be patient!"
echo ""

bowtie2 \
    -x results/${SAMPLE}_index \
    -1 ${R1} \
    -2 ${R2} \
    -p ${THREADS} \
    --no-unal \
    2> logs/${SAMPLE}_mapping.log | \
samtools view -bS - | \
samtools sort -@ ${THREADS} -o results/${SAMPLE}_sorted.bam -

# Step 3: Index BAM file
echo ""
echo "[3/4] Indexing BAM file..."
samtools index results/${SAMPLE}_sorted.bam

# Step 4: Calculate depth
echo ""
echo "[4/4] Calculating coverage depth..."
samtools depth results/${SAMPLE}_sorted.bam > results/${SAMPLE}_depth.txt

# Get mapping statistics
echo ""
echo "Mapping statistics:"
samtools flagstat results/${SAMPLE}_sorted.bam

echo ""
echo "✓ Coverage calculation complete!"
```

**Checkpoint files for Day 3:**

```bash
# Verify you have these files:
ls -lh results/sample1_contigs.fasta      # Assembled contigs
ls -lh results/sample1_sorted.bam         # Mapped reads
ls -lh results/sample1_sorted.bam.bai     # BAM index
ls -lh results/sample1_depth.txt          # Coverage depth
```

### Step 8: Visualize Results (Optional but Recommended!)

Create some nice plots using R:

```bash
# Create visualization script
cat > scripts/visualize.R << 'EOF'
#!/usr/bin/env Rscript
library(ggplot2)
library(dplyr)

# Read contig lengths
contigs <- read.table(pipe("grep '^>' results/sample1_contigs.fasta | sed 's/>//' | awk '{print $1}'"),
                      col.names="contig_id")

# Read contig sequences and calculate lengths
lengths <- sapply(Biostrings::readDNAStringSet("results/sample1_contigs.fasta"), length)

# Create data frame
df <- data.frame(
  contig = names(lengths),
  length = as.numeric(lengths)
)

# Plot 1: Length distribution
p1 <- ggplot(df, aes(x=length)) +
  geom_histogram(bins=50, fill="steelblue", color="black") +
  scale_x_log10() +
  theme_minimal() +
  labs(title="Contig Length Distribution",
       x="Contig Length (bp, log scale)",
       y="Count")

ggsave("results/contig_length_distribution.pdf", p1, width=8, height=6)

# Plot 2: Cumulative length
df_sorted <- df %>% arrange(desc(length)) %>%
  mutate(cumsum = cumsum(length),
         pct = cumsum / sum(length) * 100)

p2 <- ggplot(df_sorted, aes(x=1:nrow(df_sorted), y=pct)) +
  geom_line(color="darkgreen", size=1) +
  geom_hline(yintercept=50, linetype="dashed", color="red") +
  theme_minimal() +
  labs(title="Cumulative Assembly Length",
       x="Number of Contigs",
       y="Cumulative % of Assembly")

ggsave("results/cumulative_length.pdf", p2, width=8, height=6)

cat("\n✓ Plots saved:\n")
cat("  - results/contig_length_distribution.pdf\n")
cat("  - results/cumulative_length.pdf\n\n")
EOF

# Run R script (requires R and Biostrings)
Rscript scripts/visualize.R
```

## 📊 Understanding Your Results

### Good Assembly Indicators

✅ **N50 > 1,000 bp** - Acceptable
✅ **N50 > 5,000 bp** - Good
✅ **N50 > 10,000 bp** - Excellent

✅ **Total length 20-200 MB** - Typical for metagenomes
✅ **Longest contig > 50 kb** - Great sign
✅ **Mapping rate > 70%** - Good coverage calculation

### Red Flags

⚠️ **N50 < 500 bp** - Poor assembly, check data quality
⚠️ **Mapping rate < 50%** - Something went wrong
⚠️ **Very few long contigs** - Low coverage or high complexity

## 💡 Tips for Success on Laptops

### Memory Management

```bash
# Monitor memory during assembly
watch -n 5 free -h

# If running out of memory:
# 1. Close other applications
# 2. Reduce thread count (THREADS=2)
# 3. Subsample data more aggressively
# 4. Use swap space (slower but works)
```

### Speed Optimization

```bash
# Use all available cores (leave 1-2 for system)
THREADS=$(nproc)
THREADS=$((THREADS - 2))

# On macOS
THREADS=$(sysctl -n hw.ncpu)
THREADS=$((THREADS - 2))
```

### Storage Management

```bash
# Check disk space regularly
df -h ~/metagenome_project

# Clean up space if needed:
# Delete intermediate k-mer assemblies (after assembly completes)
rm -rf results/sample1_megahit/intermediate_contigs/

# Compress old logs
gzip logs/*.log
```

## 🔧 Troubleshooting

### Problem: MEGAHIT runs out of memory

**Solution 1:** Subsample data

```bash
seqtk sample -s100 input.fastq.gz 1000000 > subset.fastq
```

**Solution 2:** Reduce k-mer maximum

```bash
megahit --k-max 77 ...  # Instead of 99
```

**Solution 3:** Use more conservative memory

```bash
megahit --memory 0.6 ...  # Use only 60% of RAM
```

### Problem: Assembly takes forever

**Solution:**

- Check if it's actually running: `top` or `htop`
- For testing, use subsampled data (500K-1M reads)
- Expected time: 1-4 hours for 2M read pairs

### Problem: Low N50

**Possible causes:**

- Insufficient sequencing depth
- Poor read quality (check Day 1 QC)
- High community complexity

**Solutions:**

- Ensure Day 1 QC was successful
- Try different k-mer ranges
- Consider deeper sequencing

### Problem: Mapping rate is low

**Solutions:**

- Make sure you're using the SAME reads for mapping that you used for assembly
- Check if assembly actually succeeded
- Verify file paths are correct

## ⏱️ Expected Runtimes (Laptop with 4 cores, 16GB RAM)

| Step                   | 500K Pairs  | 2M Pairs     | 5M Pairs     |
| ---------------------- | ----------- | ------------ | ------------ |
| **Assembly (MEGAHIT)** | 30 min      | 2 hours      | 4 hours      |
| **MetaQUAST**          | 5 min       | 15 min       | 30 min       |
| **Index building**     | 2 min       | 5 min        | 10 min       |
| **Read mapping**       | 15 min      | 45 min       | 2 hours      |
| **Coverage calc**      | 1 min       | 3 min        | 5 min        |
| **Total**              | **~1 hour** | **~4 hours** | **~7 hours** |

## 🎓 Learning Checklist

After completing this tutorial, you should have:

- [ ] Installed MEGAHIT and dependencies
- [ ] Assembled a metagenome on your laptop
- [ ] Generated assembly statistics (N50, etc.)
- [ ] Run MetaQUAST quality assessment
- [ ] Calculated contig coverage
- [ ] Created visualization plots
- [ ] Prepared files for Day 3 binning

## 📚 Additional Resources

### If Your Laptop Struggles

**Option 1: Cloud Computing (Pay-as-you-go)**

- AWS EC2 t3.xlarge: 4 cores, 16GB RAM (~$0.17/hour)
- Google Cloud n1-standard-4: 4 cores, 15GB RAM (~$0.19/hour)
- Run for 4-6 hours, costs <$1

**Option 2: Google Colab (Free tier)**

- 12GB RAM, 2 cores
- Good for small datasets
- 12-hour session limit

**Option 3: Request HPC Access**

- Contact your institution's IT department
- Many universities offer HPC for students
- Worth it for larger projects

### Documentation

- [MEGAHIT GitHub](https://github.com/voutcn/megahit)
- [MetaQUAST Manual](http://quast.sourceforge.net/metaquast)
- [Bowtie2 Documentation](http://bowtie-bio.sourceforge.net/bowtie2/)

## ✅ Success Checklist

Before moving to Day 3:

- [ ] Assembly completed successfully
- [ ] N50 > 1,000 bp
- [ ] MetaQUAST report generated
- [ ] BAM file created with >70% mapping
- [ ] Coverage depth calculated
- [ ] All files in `results/` directory

## ➡️ Next Steps

**Congratulations!** You've successfully assembled a metagenome on your laptop!

**Ready for Day 3?**

[Proceed to Day 3: Genome Binning (MAG Recovery) →](../day3-binning/)

Learn to separate individual genomes from your assembly!

---

<div align="center">

**[⬆ Back to Day 2 README](../README.md)** | **[← Day 1](../../day1-qc-read-based/running-on-your-laptop/)** | **[Day 3 →](../../day3-binning/running-on-your-laptop/)**

</div>
