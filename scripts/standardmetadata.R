# Load required library
library(dplyr)
library(readr)

# Define the standard column names
standard_columns <- c("Sample Name", "Tissue", "Condition", "Age", "Gender", "Ethnicity", "Race", "Assay Type", "Version")

# Define column mappings from different datasets
column_mappings <- list(
  "Sample Name" = c("Sample Name", "SampleID", "samplelabel", "siteandparticipantcode"),
  "Tissue" = c("tissue", "cell_type"),
  "Condition" = c("disease_state", "Phenotype", "Group", "status"),
  "Age" = c("AGE"),
  "Gender" = c("gender"),
  "Ethnicity" = c("ETHNICITY", "ethnicity"),
  "Race" = c("Race", "race", "ancestry"),
  "Assay Type" = c("Assay Type"),
  "Version" = c("version")
)

# Function to process a single file and standardize columns
process_file <- function(file_path) {
  # Read the CSV file
  df <- read_csv(file_path, show_col_types = FALSE)
  
  # Initialize an empty standardized dataframe
  standardized_df <- data.frame(matrix(ncol = length(standard_columns), nrow = nrow(df)))
  colnames(standardized_df) <- standard_columns
  
  # Map and rename columns
  for (std_col in names(column_mappings)) {
    for (col in column_mappings[[std_col]]) {
      if (col %in% colnames(df)) {
        standardized_df[[std_col]] <- df[[col]]
        break
      }
    }
  }
  
  return(standardized_df)
}

# Define multiple directories example SRP098758(folder contains metadata for SRP098758 study)  
directories <- c("data/SRP098758") 

# Output directory
output_directory <- "standardized_output"

# Create output directory if it doesn't exist
if (!dir.exists(output_directory)) {
  dir.create(output_directory)
}

# Process files from multiple directories
for (dir_path in directories) {
  # Get all CSV files in the directory
  file_list <- list.files(dir_path, pattern = "*.csv", full.names = TRUE)
  
  for (file in file_list) {
    standardized_df <- process_file(file)
    
    # Save the standardized file
    output_file <- file.path(output_directory, paste0("standardized_", basename(file)))
    write_csv(standardized_df, output_file)
    
    print(paste("Processed and saved:", output_file))
  }
}

print("All files have been standardized and saved.")
