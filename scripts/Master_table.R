# Load required libraries
library(dplyr)
library(readr)

# === CONFIGURATION ===
# Path to the folder containing the annotated files
input_dir <- "result"
output_file <- "master_deseq2_annotated_combined.csv"

# Pattern to find all annotated files across studies
annotated_files <- list.files(
  path = input_dir,
  pattern = "deseq2\\.annotated\\.tsv$",
  recursive = TRUE,
  full.names = TRUE
)

# Initialize empty list to collect data
all_studies <- list()

# Loop through each annotated file and tag with study_id
for (file_path in annotated_files) {
  # Extract study_id (assumes structure: result/<study_id>/tables/differential/)
  study_id <- basename(dirname(dirname(dirname(file_path))))
  
  # Print for debugging
  cat("📂 Detected study_id:", study_id, "from", file_path, "\n")
  
  # Read the annotated DESeq2 file
  df <- read_tsv(file_path, show_col_types = FALSE)
  
  # Add study metadata
  df$study_id <- study_id
  df$condition <- "Control_vs_Case"  # Modify if needed per study
  
  # Keep only essential columns (reorder if needed)
  df <- df %>%
    select(
      Symbol, EnsemblGeneID, Description,
      log2FoldChange, pvalue, padj,
      study_id, condition
    )
  
  # Store in list
  all_studies[[study_id]] <- df
}

# Combine all studies into one master dataframe
master_df <- bind_rows(all_studies)

# Save to CSV
write_csv(master_df, output_file)
cat("✅ Master DESeq2 table written to:", output_file, "\n")

