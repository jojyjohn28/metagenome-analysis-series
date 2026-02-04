## Fast qc to Table (from Multiple genomes)

**A clean, standalone Python script that parses FastQC outputs and generates a summary table you can use for reporting, plotting, or downstream filtering..**

This repository documents the **analysis day by day**, following real research progress rather than a polished, post-hoc pipeline.
I update this README daily as new steps, scripts, and results are added.

##🎯 What this script does

It extracts key metrics from FastQC results and outputs a tidy table:

✔ Sample name
✔ Total reads
✔ Read length
✔ %GC
✔ Per-base quality status
✔ Adapter content status
✔ Overrepresented sequences status

**Works with:**

• \*\_fastqc.zip

• or unzipped \*\_fastqc/ folders

Please use fastqc_to_table.py Day1/scripts

## ▶️ How to run it

```bash
cd day01_qc_preprocessing
python scripts/fastqc_to_table.py
```

Output:fastqc_summary_table.tsv

## 📊 Example output table

| Sample | Total_Sequences | Sequence_Length | GC_percent | Per_base_sequence_quality | Adapter_Content | Overrepresented_sequences |
| ------ | --------------- | --------------- | ---------- | ------------------------- | --------------- | ------------------------- |
| S01    | 48,210,332      | 150             | 51         | PASS                      | WARN            | FAIL                      |
| S02    | 45,901,114      | 150             | 49         | PASS                      | PASS            | PASS                      |

Perfect for:

• QC reports

• Filtering bad samples

• Heatmaps / barplots

• Supplementary tables
