#!/usr/bin/env python3

import os
import zipfile
import pandas as pd

def parse_fastqc_data(lines):
    data = {}
    for line in lines:
        if line.startswith("Total Sequences"):
            data["Total_Sequences"] = line.split("\t")[1]
        elif line.startswith("Sequence length"):
            data["Sequence_Length"] = line.split("\t")[1]
        elif line.startswith("%GC"):
            data["GC_percent"] = line.split("\t")[1]
    return data


def parse_summary(lines):
    summary = {}
    for line in lines:
        status, module, _ = line.strip().split("\t")
        summary[module.replace(" ", "_")] = status
    return summary


def read_fastqc(fastqc_path):
    results = {}

    if fastqc_path.endswith(".zip"):
        with zipfile.ZipFile(fastqc_path) as z:
            data_file = [f for f in z.namelist() if f.endswith("fastqc_data.txt")][0]
            summary_file = [f for f in z.namelist() if f.endswith("summary.txt")][0]

            data_lines = z.read(data_file).decode().splitlines()
            summary_lines = z.read(summary_file).decode().splitlines()

    else:
        data_file = os.path.join(fastqc_path, "fastqc_data.txt")
        summary_file = os.path.join(fastqc_path, "summary.txt")

        with open(data_file) as f:
            data_lines = f.readlines()
        with open(summary_file) as f:
            summary_lines = f.readlines()

    results.update(parse_fastqc_data(data_lines))
    results.update(parse_summary(summary_lines))

    return results


def main():
    fastqc_dir = "fastqc_raw"
    records = []

    for f in os.listdir(fastqc_dir):
        if f.endswith("_fastqc.zip") or os.path.isdir(os.path.join(fastqc_dir, f)):
            sample = f.replace("_fastqc.zip", "").replace("_fastqc", "")
            path = os.path.join(fastqc_dir, f)

            record = {"Sample": sample}
            record.update(read_fastqc(path))
            records.append(record)

    df = pd.DataFrame(records)
    df.to_csv("fastqc_summary_table.tsv", sep="\t", index=False)

    print("✅ FastQC summary table saved as fastqc_summary_table.tsv")


if __name__ == "__main__":
    main()

