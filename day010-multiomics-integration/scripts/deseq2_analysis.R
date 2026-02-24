#Deseq Analysis
#load required libraries
library(DESeq2)
library(ggplot2)
library(pheatmap)
library(EnhancedVolcano)

# ==========================================
# Load Data
# ==========================================
cat("Loading data...\n")
count_data <- read.csv("results/mtx_counts_filtered.csv", row.names = 1)
metadata <- read.csv("results/metadata_mtx.csv", row.names = 1)

# Ensure all counts are integers
count_data <- round(count_data)

# Verify sample order
count_data <- count_data[, rownames(metadata)]

cat("Count matrix dimensions:", dim(count_data), "\n")
cat("Number of samples:", nrow(metadata), "\n")

# ==========================================
# Create DESeq2 Object
# ==========================================
dds <- DESeqDataSetFromMatrix(
  countData = count_data,
  colData = metadata,
  design = ~ Condition
)

cat("DESeq2 object created\n")

# ==========================================
# Run DESeq2
# ==========================================
cat("Running DESeq2 analysis...\n")
dds <- DESeq(dds)

# ==========================================
# Extract Results
# ==========================================
res <- results(dds, contrast = c("Condition", "Treatment", "Control"))
res_ordered <- res[order(res$padj), ]

# Summary
cat("\n=== DESeq2 Results Summary ===\n")
summary(res)

# Save results
write.csv(as.data.frame(res_ordered), 
          "results/deseq2_all_results.csv")

# ==========================================
# Extract Significant Genes
# ==========================================
# Criteria: padj < 0.05 and |log2FC| > 1
sig_genes <- subset(res_ordered, padj < 0.05 & abs(log2FoldChange) > 1)

cat("\n=== Significant Genes ===\n")
cat("Total DE genes:", nrow(sig_genes), "\n")
cat("Upregulated:", sum(sig_genes$log2FoldChange > 0), "\n")
cat("Downregulated:", sum(sig_genes$log2FoldChange < 0), "\n")

write.csv(as.data.frame(sig_genes), 
          "results/deseq2_significant_genes.csv")

# ==========================================
# Visualization 1: MA Plot
# ==========================================
pdf("figures/deseq2_ma_plot.pdf", width = 10, height = 6)
plotMA(res, ylim = c(-5, 5), 
       main = "MA Plot: Treatment vs Control",
       alpha = 0.05)
dev.off()

# ==========================================
# Visualization 2: Volcano Plot
# ==========================================
pdf("figures/deseq2_volcano_plot.pdf", width = 12, height = 10)
EnhancedVolcano(res,
                lab = rownames(res),
                x = 'log2FoldChange',
                y = 'padj',
                title = 'Differential Expression: Treatment vs Control',
                pCutoff = 0.05,
                FCcutoff = 1,
                pointSize = 2.0,
                labSize = 3.0,
                legendPosition = 'right',
                legendLabSize = 12,
                legendIconSize = 4.0)
dev.off()

# ==========================================
# Visualization 3: PCA Plot
# ==========================================
vsd <- vst(dds, blind = FALSE)

pdf("figures/deseq2_pca_plot.pdf", width = 8, height = 6)
pcaData <- plotPCA(vsd, intgroup = "Condition", returnData = TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))
ggplot(pcaData, aes(PC1, PC2, color = Condition, label = name)) +
  geom_point(size = 4) +
  geom_text(vjust = -1, hjust = 0.5, size = 3) +
  xlab(paste0("PC1: ", percentVar[1], "% variance")) +
  ylab(paste0("PC2: ", percentVar[2], "% variance")) +
  ggtitle("PCA of Samples") +
  theme_bw() +
  theme(legend.position = "top",
        plot.title = element_text(hjust = 0.5, face = "bold"))
dev.off()

# ==========================================
# Visualization 4: Sample Distance Heatmap
# ==========================================
sampleDists <- dist(t(assay(vsd)))
sampleDistMatrix <- as.matrix(sampleDists)

pdf("figures/deseq2_sample_distances.pdf", width = 10, height = 8)
pheatmap(sampleDistMatrix,
         clustering_distance_rows = sampleDists,
         clustering_distance_cols = sampleDists,
         annotation_col = metadata[, "Condition", drop = FALSE],
         main = "Sample-to-Sample Distances")
dev.off()

# ==========================================
# Visualization 5: Heatmap of Top DE Genes
# ==========================================
# Top 50 genes by adjusted p-value
top_genes <- head(rownames(sig_genes), 50)

if(length(top_genes) > 0) {
  pdf("figures/deseq2_top50_heatmap.pdf", width = 10, height = 12)
  pheatmap(assay(vsd)[top_genes, ],
           annotation_col = metadata[, "Condition", drop = FALSE],
           scale = "row",
           clustering_distance_rows = "euclidean",
           clustering_distance_cols = "euclidean",
           show_rownames = TRUE,
           fontsize_row = 6,
           main = "Top 50 Differentially Expressed Genes")
  dev.off()
}

# ==========================================
# Gene Expression Plots
# ==========================================
# Plot top 6 DE genes
top6_genes <- rownames(sig_genes)[1:min(6, nrow(sig_genes))]

pdf("figures/deseq2_top_genes_boxplots.pdf", width = 12, height = 8)
par(mfrow = c(2, 3))
for(gene in top6_genes) {
  plotCounts(dds, gene = gene, intgroup = "Condition", 
             main = gene, returnData = FALSE)
}
dev.off()

cat("\n=== Analysis Complete! ===\n")
cat("All results and figures saved.\n")