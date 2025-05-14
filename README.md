# DEGeneExplorer

**A Gene-Centric Platform for Cross-Study Differential Expression Exploration**

DEGeneExplorer is a reproducible, Shiny-based application designed to help researchers search for a specific gene and identify public RNA-seq studies in which it is significantly differentially expressed (DE). The app supports interactive queries, DE result filtering, visualization, and reproducibility from raw data to web output.

---

🔍 Features

- Search by **gene symbol** (e.g., `TP53`) or **Ensembl ID** (e.g., `ENSG00000141510`)
- Apply filters: adjusted p-value (`padj`) and log₂ fold change
- Visualize gene-level DE across multiple studies
- Study-specific **volcano plots** with thresholds and gene highlighting
- Access HTML-based DE reports per study
- Download filtered results as CSV
- All computations built on a reproducible pipeline using `nf-core/differentialabundance`

---

## 📁 Repository Structure

```

DEGeneExplorer/
├── app.R                       # R Shiny application
├── annotate_results.R         # Script for annotating DESeq2 results
├── Master_table.R             # Aggregates annotated results into a master file
├── Metadata_count_align.R     # Aligns count matrix and metadata sample IDs
├── standardmetadata.R         # Standardizes metadata column formats across studies
├── data/                      # Directory for study-specific input files
├── result/                    # Directory for pipeline output and reports
└── master_deseq2_annotated_combined.csv  # Main input for app (generated)

````

---

## 🧪 Data & Pipeline Summary

- Processed **9 public RNA-seq studies** from GEO/recount3
- DE analysis performed using **DESeq2** via the `nf-core/differentialabundance` pipeline
- Final output includes:
  - Gene-level statistics (log2FoldChange, p-value, padj)
  - Study metadata (condition, tissue, study ID)
  - Linked HTML reports for full result context

---

## ▶️ Running the App Locally

1. **Install R and dependencies**  
   R ≥ 4.1.0 required. Install required packages:

   ```r
   install.packages(c("shiny", "DT", "dplyr", "readr", "ggplot2", "bslib"))
   ```

2. **Download files**
   Ensure the following files are present in the working directory:

   * `app.R`
   * `master_deseq2_annotated_combined.csv`
   * `study_metadata_with_tissue.csv`

3. **Launch the app**

   ```r
   shiny::runApp("app.R")
   ```

---

## ☁️ Deployment Options

* Local (RStudio)
* Institutional or cloud-based Shiny Server
* Optionally deploy via [shinyapps.io](https://www.shinyapps.io/)
* Docker containerization planned for full portability

---

## 🐳 Future Features

* Dockerized deployment environment
* Live database backend (e.g., PostgreSQL)
* Multi-gene and pathway-level querying
* Ontology-based metadata normalization

---

## 📜 License

This project is provided for academic use. See `LICENSE` for usage terms.

---

## 🧾 Citation

If you use DEGeneExplorer in your research or teaching, please cite:

> Arya Himmatsingh Jain (2025). *DEGeneExplorer: A gene-centric differential expression exploration platform*. Master’s Thesis, Friedrich-Alexander-Universität Erlangen-Nürnberg.

---

## 🔗 Resources

* GitHub: [github.com/AryaJain04/DEGeneExplorer](https://github.com/AryaJain04/DEGeneExplorer)
* Pipeline: [nf-core/differentialabundance](https://nf-co.re/differentialabundance)
* DESeq2: [Genome Biology, 2014](https://doi.org/10.1186/s13059-014-0550-8)



