# Load required packages
library(data.table)

# File paths (update as needed)
metadata_file <- "data/Metadata/standardized_SRP116272.csv"
count_matrix_file <- "data/counts/SRP116272_raw_count.csv"

# Output paths
aligned_metadata_file <- "data/Metadata/aligned_metadata_SRP116272.csv"
aligned_count_matrix_file <- "aligned_count_matrix_SRP116272.csv"
report_file <- "data/Metadata/sample_alignment_report.txt"

# Read files
metadata <- fread(metadata_file)
count_matrix <- fread(count_matrix_file)

# Extract sample IDs (excluding gene_id column in count matrix)
metadata_samples <- trimws(as.character(metadata$sample))
count_matrix_samples <- trimws(colnames(count_matrix)[-1])

# 🚨 Check if samples are already aligned
if (setequal(metadata_samples, count_matrix_samples) && identical(metadata_samples, count_matrix_samples)) {
  cat("✅ Metadata and count matrix are already aligned. No further processing required.\n")
} else {
  cat("⚠️ Metadata and count matrix are NOT aligned. Proceeding with filtering and alignment...\n")
  
  # Identify matched, missing, and extra samples
  matched_samples <- intersect(metadata_samples, count_matrix_samples)
  missing_in_matrix <- setdiff(metadata_samples, count_matrix_samples)
  extra_in_matrix <- setdiff(count_matrix_samples, metadata_samples)
  
  # Summary and reporting before processing
  sink(report_file)
  cat("✅ Total metadata samples:", length(metadata_samples), "\n")
  cat("✅ Total count matrix samples:", length(count_matrix_samples), "\n")
  cat("✅ Matched samples:", length(matched_samples), "\n")
  cat("⚠️ Missing in matrix:", length(missing_in_matrix), "\n")
  if (length(missing_in_matrix) > 0) print(missing_in_matrix)
  
  cat("⚠️ Extra in matrix:", length(extra_in_matrix), "\n")
  if (length(extra_in_matrix) > 0) print(extra_in_matrix)
  
  identical_order <- identical(metadata_samples, count_matrix_samples)
  cat("🧾 Sample order identical before processing:", identical_order, "\n")
  sink()
  
  # 🚨 If there are no matches, stop with an error
  if (length(matched_samples) == 0) {
    stop("❌ No matching samples found between metadata and count matrix. Check sample names!")
  }
  
  # ✅ Filter metadata to keep only matched samples
  aligned_metadata <- metadata[sample %in% matched_samples]
  
  # ✅ Filter and reorder count matrix to match aligned metadata order
  aligned_count_matrix <- count_matrix[, c("gene_id", matched_samples), with = FALSE]
  
  # Save aligned files
  fwrite(aligned_metadata, aligned_metadata_file)
  fwrite(aligned_count_matrix, aligned_count_matrix_file)
  
  cat("✅ Aligned metadata saved to:", aligned_metadata_file, "\n")
  cat("✅ Aligned count matrix saved to:", aligned_count_matrix_file, "\n")
  
  # 🔎 Double-check alignment after filtering
  cat("🔎 Performing double-check alignment after filtering...\n")
  final_metadata_samples <- trimws(as.character(aligned_metadata$sample))
  final_count_matrix_samples <- trimws(colnames(aligned_count_matrix)[-1])
  
  # Check again for matched, missing, and extra samples after filtering
  final_matched_samples <- intersect(final_metadata_samples, final_count_matrix_samples)
  final_missing_in_matrix <- setdiff(final_metadata_samples, final_count_matrix_samples)
  final_extra_in_matrix <- setdiff(final_count_matrix_samples, final_metadata_samples)
  
  # Report results after filtering
  final_identical_order <- identical(final_metadata_samples, final_count_matrix_samples)
  cat("✅ Post-filter: Matched samples:", length(final_matched_samples), "\n")
  cat("⚠️ Post-filter: Missing in matrix:", length(final_missing_in_matrix), "\n")
  if (length(final_missing_in_matrix) > 0) print(final_missing_in_matrix)
  
  cat("⚠️ Post-filter: Extra in matrix:", length(final_extra_in_matrix), "\n")
  if (length(final_extra_in_matrix) > 0) print(final_extra_in_matrix)
  
  cat("🧾 Post-filter: Sample order identical:", final_identical_order, "\n")
  
  # Save final check results to the report
  sink(report_file, append = TRUE)
  cat("\n🔎 Double-Check Results After Filtering:\n")
  cat("✅ Post-filter: Matched samples:", length(final_matched_samples), "\n")
  cat("⚠️ Post-filter: Missing in matrix:", length(final_missing_in_matrix), "\n")
  cat("⚠️ Post-filter: Extra in matrix:", length(final_extra_in_matrix), "\n")
  cat("🧾 Post-filter: Sample order identical:", final_identical_order, "\n")
  sink()
  
  cat("📄 Final alignment report updated with post-filter check.\n")
}

