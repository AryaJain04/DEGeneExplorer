args <- commandArgs(trailingOnly = TRUE)

# Check arguments
if (length(args) != 3) {
  stop("Usage: Rscript annotate_results.R <DE_result> <annotation_file> <output_file>")
}

de_results_file <- args[1]
annotation_file <- args[2]
output_file <- args[3]

library(dplyr)

# Load data
de_results <- read.delim(de_results_file, header = TRUE, stringsAsFactors = FALSE)
annotation <- read.delim(annotation_file, header = TRUE, stringsAsFactors = FALSE)

# Merge and select relevant columns
annotated_df <- de_results %>%
  left_join(annotation, by = "gene_id") %>%
  select(any_of(c(
    "gene_id", "Symbol", "Description", "EnsemblGeneID",
    "baseMean", "log2FoldChange", "pvalue", "padj"
  )))

# Save annotated results
write.table(annotated_df, file = output_file, sep = "\t", row.names = FALSE, quote = FALSE)

cat("✅ Annotated file written to:", output_file, "\n")
