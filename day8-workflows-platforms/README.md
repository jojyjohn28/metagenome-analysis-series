# Day 8: Workflow Wrappers & Web Platforms

Automate Days 1-7 with pre-built pipelines and browser-based platforms.

## 📋 Overview

**Stop running tools one by one. Automate everything.**

**Time savings:**

- Manual (Days 1-7): 2-4 weeks per sample
- Automated: 2-3 days for 50 samples!

---

## 📁 Repository Structure

```
day8-workflows-platforms/
├── README.md                             # This file
└── scripts/
    ├── MetaWRAP_complete_workflow.sh    # Complete MetaWRAP pipeline
    ├── nf-core_mag_run.sh                # Modern Nextflow pipeline
    ├── anvio_quick_start.sh              # Interactive Anvi'o workflow
    ├── atlas_setup.sh                     # ATLAS initialization
    └── Galaxy_workflow.txt                # Galaxy step-by-step guide
```

---

## 🚀 Quick Start Guide

### Choose Your Approach

| Script          | Best For                 | Time      | Difficulty |
| --------------- | ------------------------ | --------- | ---------- |
| **MetaWRAP**    | Complete automation, HPC | 24-48 hrs | ⭐⭐⭐     |
| **nf-core/mag** | Reproducibility, modern  | 12-24 hrs | ⭐⭐       |
| **Anvi'o**      | Interactive binning, viz | Variable  | ⭐⭐⭐     |
| **ATLAS**       | Large datasets, RNA-seq  | 24-36 hrs | ⭐⭐⭐     |
| **Galaxy**      | No Linux, learning       | 6-12 hrs  | ⭐ Easy!   |

---

## 🎯 Decision Matrix

| Your Situation            | Use This                |
| ------------------------- | ----------------------- |
| HPC access + Linux skills | MetaWRAP or nf-core/mag |
| Want reproducibility      | nf-core/mag             |
| Interactive binning       | Anvi'o                  |
| 100+ samples              | ATLAS or nf-core/mag    |
| No Linux skills           | Galaxy                  |
| Teaching/learning         | Galaxy                  |
| Metabolic modeling        | KBase (see blog)        |
| Compare to public data    | IMG/M (see blog)        |

## 📚 Documentation

### Scripts

- **MetaWRAP:** [GitHub](https://github.com/bxlab/metaWRAP)
- **nf-core/mag:** [Docs](https://nf-co.re/mag)
- **Anvi'o:** [Website](http://merenlab.org/software/anvio/)
- **ATLAS:** [GitHub](https://github.com/metagenome-atlas/atlas)
- **Galaxy:** [Training](https://training.galaxyproject.org/)

## 📖 Documentation

**Complete tutorial:** See blog post at [Day 8 Blog](https://jojyjohn28.github.io/blog/metagenome-analysis-day8-workflows-platforms/)

Last updated: February 2026
