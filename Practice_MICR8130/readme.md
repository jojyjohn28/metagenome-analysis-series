#### Metagenome analysis_detailed work flow

**Toy <100MB data provided as raw data**

You have toy data
toy-R1.fastq.gz
toy-R2.fastq.gz

**What this <100 MB toy dataset is good for**

It will work well to demonstrate:

● QC (FastQC), trimming (fastp / Trimmomatic)

● basic host-filtering workflow (if relevant)

● k-mer profiling (Mash/sourmash)

● read mapping (Bowtie2/BWA) to a reference or MAGs

● taxonomic profiling workflows (Kraken2/Bracken, Kaiju) — results will be “toy-scale” but pipeline works

● small assembly demo (MEGAHIT/metaSPAdes) — assembly will be fragmented but still shows steps

● binning demo only if you also provide a tiny “toy assembly”/contigs or use a very targeted example

**Toy assembly data_assembly.fasta**

Please use this for binning.

● This is an assembly from a contaminated genomes inteded only for learning purpose. You will suceed in binning and down stream analyis.

● However it will only produce 2 bins. You can run, drep, gtdbtk, and annotation with this

● So for learning pylogentic tree annotations, please use the tree file provided with the toy annotation file.

**Real data** : Download data from project PRJNA432171 from NCBI SRA.

## End of the class training

## prepared by Jojy John
