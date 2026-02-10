# Day 5: Genome Annotation

Annotate MAGs to understand their metabolic potential and functional capabilities.

## 📋 Overview

Predict genes, assign functions, and reconstruct metabolic pathways to understand what your organisms can do.

### What You'll Learn

✅ Gene prediction (Prodigal)  
✅ Rapid annotation (Prokka)  
✅ Functional annotation (eggNOG-mapper)  
✅ Metabolic distillation (DRAM)  
✅ Comprehensive pathways (METABOLIC)

---

## 🚀 Quick Start

### One-Line Commands

```bash
# Gene prediction
prodigal -i genome.fa -a proteins.faa -d genes.fna -f gbk -o genes.gbk

# Quick annotation
prokka --outdir prokka_out --prefix genome --cpus 8 genome.fa

# Functional annotation
emapper.py -i proteins.faa -o genome --cpu 8 -m diamond

# Metabolic annotation
DRAM.py annotate -i 'genome.fa' -o dram_out --threads 8
DRAM.py distill -i dram_out/annotations.tsv -o dram_distill

# Comprehensive pathways
perl METABOLIC-G.pl -in-gn genomes/ -o metabolic_out -t 8
```

See **[RUNNING_ON_LAPTOP.md](running-on-your-laptop/RUNNING_ON_LAPTOP.md)** for complete tutorial.

---

## 📁 Repository Structure

```
day5-annotation/
├── README.md                     # This file
├── running-on-your-laptop/
│   └── RUNNING_ON_LAPTOP.md     # Complete laptop guide
│
└── scripts/ # HPC batch scripts

---

## 🔄 Workflow

```

Dereplicated MAGs (from Day 4)
↓
┌─────────────────────────┐
│ Gene Prediction │ Prodigal
│ Find all genes │ (~1 min per genome)
└─────────────────────────┘
↓
┌─────────────────────────┐
│ Basic Annotation │ Prokka
│ Quick functional ID │ (~5 min per genome)
└─────────────────────────┘
↓
┌─────────────────────────┐
│ Functional Annotation │ eggNOG-mapper
│ KEGG, COG, GO, EC │ (~30 min per genome)
└─────────────────────────┘
↓
┌─────────────────────────┐
│ Metabolic Analysis │ DRAM or METABOLIC
│ Pathways & capabilities │ (~1-2 hrs per genome)
└─────────────────────────┘
↓
Fully Annotated Genomes + Metabolic Maps

```

---


## 📖 Documentation

- **[Tutorial Blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day5-annotation/)** - Comprehensive guide
- **[Laptop Guide](running-on-your-laptop/RUNNING_ON_LAPTOP.md)** - Practical commands
- [Prodigal](https://github.com/hyattpd/Prodigal)
- [Prokka](https://github.com/tseemann/prokka)
- [eggNOG-mapper](http://eggnog-mapper.embl.de/)
- [DRAM](https://github.com/WrightonLabCSU/DRAM)
- [METABOLIC](https://github.com/AnantharamanLab/METABOLIC)

---

## ✅ Success Checklist

Before completing Day 5:

- [ ] Genes predicted for all MAGs
- [ ] Functional annotations generated
- [ ] Metabolic pathways reconstructed
- [ ] Key capabilities identified (N-fixation, carbon metabolism, etc.)
- [ ] Comparative analysis completed
- [ ] Results visualized

---

## 💡 Real-World Applications

**After annotation, you can answer:**

✓ Can this organism fix nitrogen?
✓ Does it have antibiotic resistance genes?
✓ What carbon sources can it use?
✓ Can it produce secondary metabolites?
✓ Does it have metal reduction capabilities?
✓ Can it degrade pollutants?

---


```
