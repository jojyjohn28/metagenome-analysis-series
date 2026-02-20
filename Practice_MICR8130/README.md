# Metagenome Analysis - Graduate Course Materials

**Beginner-Level Practical Training**

This repository contains materials for a graduate-level metagenome analysis course, designed for students with little to no prior bioinformatics experience.

---

## 📚 Course Overview

A hands-on introduction to metagenomics covering the complete workflow from raw sequencing reads to taxonomic classification, genome recovery, and phylogenetic analysis.

**Level:** Beginner  
**Prerequisites:** Basic command-line knowledge  
**Duration:** Full semester practical course  
**Instructors:** Co-taught graduate course

---

## 📁 Repository Contents

```
metagenome-analysis-class/
├── README.md                                    # This file
├── metagenome_practical_full_version_jojy.md   # Complete course guide
├── data.md                                      # Data use instructions
├── metawrap_micromamba.md                       # MetaWRAP setup guide
│
├── Toy Data (< 100 MB - Included)
│   ├── toy-R1.fastq.gz                         # Forward reads
│   ├── toy-R2.fastq.gz                         # Reverse reads
│   └── assembly.fasta                          # Pre-assembled contigs
│
└── Phylogenetic Analysis
    ├── class_practice_tree/                    # Tree files
    └── tree_annotation_data.xlsx               # Annotation metadata
    └──Metagenome_M8130_Feb16_JJ.pdf            # full class materials
```

---

## 🎯 Learning Objectives

After completing this course, students will be able to:

✅ Perform quality control on raw sequencing data  
✅ Conduct taxonomic profiling of microbial communities  
✅ Assemble metagenome reads into contigs  
✅ Recover individual genomes (MAGs) through binning  
✅ Classify recovered genomes taxonomically  
✅ Annotate and visualize phylogenetic relationships

---

## 🧬 Toy Dataset (< 100 MB)

### What's Included:

- **toy-R1.fastq.gz** - Forward paired-end reads
- **toy-R2.fastq.gz** - Reverse paired-end reads
- **assembly.fasta** - Pre-assembled contigs for binning practice

### What This Dataset is Good For:

✅ **Quality Control**

- FastQC analysis
- Adapter trimming (fastp / Trimmomatic)
- Quality score visualization

✅ **Taxonomic Profiling**

- Kraken2 / Bracken classification
- Kaiju protein-level profiling
- K-mer profiling (Mash/sourmash)

✅ **Read Mapping**

- Bowtie2 / BWA alignment
- Coverage calculation
- Mapping to reference genomes

✅ **Assembly Demonstration**

- MEGAHIT or metaSPAdes assembly
- **Note:** Results will be fragmented (toy-scale data) but demonstrate the workflow

✅ **Binning Practice**

- Use provided `assembly.fasta` for binning exercises
- MetaBAT2, MaxBin2, or CONCOCT
- Bin refinement and quality assessment

### What to Expect:

⚠️ **Important Notes:**

- Dataset is intentionally small for quick processing
- Assembly will be **fragmented** - this is expected for toy data
- Binning will produce **~2 bins only** - sufficient for learning
- Bins are from **contaminated genomes** - for educational purposes only
- Results are **not publication-quality** - this is for learning workflows

---

## 🧪 Pre-Assembled Data

### assembly.fasta

A toy assembly file provided for students to practice:

- Genome binning
- Bin quality assessment (CheckM)
- Dereplication (dRep)
- Taxonomic classification (GTDB-Tk)
- Functional annotation

**Expected Output:** ~2 bins (intentionally limited for faster processing)

**Use Case:**

- Practice binning workflows without waiting hours for assembly
- Learn downstream analysis steps quickly
- Understand MAG quality metrics

---

## 🌳 Phylogenetic Tree Materials

For learning phylogenetic tree construction and annotation:

### Files:

- **class_practice_tree/** - Tree files in various formats
- **tree_annotation_data.xlsx** - Metadata for tree annotation

### Purpose:

- Visualize evolutionary relationships
- Annotate trees with metadata
- Practice using iTOL or similar tools

**Note:** Use these tree files for annotation practice, as toy data binning produces limited genomes.

---

## 📊 Real Dataset (Optional)

For students wanting to work with real-world data:

**NCBI BioProject:** [PRJNA432171](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA432171)

### Download Instructions:

See `data.md` for detailed download instructions.

**Important:**

- Real data is significantly larger (several GB)
- Processing time: hours to days depending on sample
- Requires more computational resources
- Provides publication-quality results

---

## 🚀 Getting Started

### 1. Prerequisites

**Software Requirements:**

- FastQC
- fastp or Trimmomatic
- MEGAHIT or metaSPAdes
- MetaWRAP for integrated workflow

See `metawrap_micromamba.md` for complete setup instructions.

### 2. Quick Start with Toy Data

```bash
# 1. Clone this repository
git clone [your-repo-url]
cd metagenome-analysis-class

# 2. Quality control
fastqc toy-R1.fastq.gz toy-R2.fastq.gz

# 3. Trim adapters
fastp -i toy-R1.fastq.gz -I toy-R2.fastq.gz \
      -o toy-R1.clean.fastq.gz -O toy-R2.clean.fastq.gz

# 4. Taxonomic profiling
kraken2 --db /path/to/db --paired \
        toy-R1.clean.fastq.gz toy-R2.clean.fastq.gz \
        --output toy.kraken --report toy.report

# 5. Binning (using provided assembly)
metabat2 -i assembly.fasta -o bins/bin
```

### 3. Follow the Full Tutorial

Open `metagenome_practical_full_version_jojy.md` for complete step-by-step instructions.

---

## 📖 Course Materials

### Main Tutorial

**metagenome_practical_full_version_jojy.md**

- Complete workflow from QC to phylogenetic analysis
- Code examples for each step
- Troubleshooting tips
- Expected outputs

### Setup Guides

**metawrap_micromamba.md**

- MetaWRAP installation with micromamba
- Database setup
- Configuration instructions

**data.md**

- Download instructions for real data
- File organization
- Storage requirements

---

## 💡 Teaching Tips

### For Instructors:

1. **Start with Toy Data**
   - Fast processing for demonstrations
   - Students see results quickly
   - Reduces frustration with long wait times

2. **Use Pre-Assembled Contigs**
   - Skip assembly for initial binning lessons
   - Focus on binning concepts first
   - Students can assemble later if interested

3. **Provide Tree Files**
   - Binning produces limited results
   - Use provided trees for annotation practice
   - Demonstrates publication-quality phylogenies

4. **Optional Real Data**
   - Advanced students can download real data
   - Compare toy vs. real results
   - Understand computational requirements

### For Students:

1. **Master the Workflow First**
   - Use toy data to understand each step
   - Don't worry about fragmented assembly
   - Focus on learning the process

2. **Understand Limitations**
   - Toy data = toy results
   - Real data requires more time/resources
   - Concepts are the same at any scale

3. **Practice Makes Perfect**
   - Run the workflow multiple times
   - Experiment with parameters
   - Try real data when confident

---

## ⚠️ Important Disclaimers

### About Toy Data:

- **Not for publication** - Educational purposes only
- **Contaminated genomes** - Intentionally included for learning
- **Limited results** - Expect ~2 bins maximum
- **Fragmented assembly** - Expected behavior for small dataset
- **Simplified workflow** - Real projects are more complex

### About Computational Resources:

- **Toy data:** Runs on laptops (4-8 GB RAM)
- **Real data:** Requires HPC or workstation (64+ GB RAM)
- **Processing time:** Toy=minutes, Real=hours to days

---

## 🤝 Contributing

This is a course repository. If you're a student or instructor using these materials:

- **Students:** Report issues or ask questions via GitHub Issues
- **Instructors:** Feel free to adapt materials for your courses
- **Improvements:** Pull requests welcome for corrections or enhancements

---

## 📧 Contact

**Course Instructor:** Jojy John  
**GitHub:** [jojyjohn28](https://github.com/jojyjohn28)  
**Website:** [jojyjohn28.github.io](https://jojyjohn28.github.io)

For course-related questions, open an issue in this repository.

---

## 📝 Citation

If you use these materials in your course, please cite:

```
Jojy John. (2026). Metagenome Analysis Graduate Course Materials.
GitHub repository: https://github.com/jojyjohn28/metagenome-analysis-class
```

---

## 📜 License

Educational materials provided for academic use.

- Course materials: Free to use with attribution
- Toy data: Educational purposes only
- Code examples: MIT License

---

## 🎉 Acknowledgments

This course was developed as part of a graduate-level metagenomics training program.

**Special Thanks:**

- Students who provided feedback
- Co-instructors
- Metagenomics community for tool development

---

**Last Updated:** February 2026  
**Version:** 1.0 - Beginner Level

---

## Quick Reference Card

| Task     | Tool     | Input   | Output         | Time (Toy Data) |
| -------- | -------- | ------- | -------------- | --------------- |
| QC       | FastQC   | FASTQ   | HTML reports   | 1-2 min         |
| Trim     | fastp    | FASTQ   | Clean FASTQ    | 2-3 min         |
| Taxonomy | Kraken2  | FASTQ   | Classification | 5-10 min        |
| Assembly | MEGAHIT  | FASTQ   | Contigs        | 10-15 min       |
| Binning  | MetaBAT2 | Contigs | MAGs (~2)      | 5-10 min        |
| Quality  | CheckM   | MAGs    | Completeness   | 5-10 min        |
| Classify | GTDB-Tk  | MAGs    | Taxonomy       | 15-30 min       |

**Total workflow time with toy data: ~1-2 hours**

---

**Happy Learning! 🧬**
