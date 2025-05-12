# Load libraries
library(shiny)
library(DT)
library(dplyr)
library(readr)
library(ggplot2)
library(bslib)

# === Load Data ===
master_df <- read_csv("master_deseq2_annotated_combined.csv", show_col_types = FALSE)
study_meta <- read_csv("study_metadata_with_tissue.csv", show_col_types = FALSE)

# === UI ===
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    base_font = font_google("Inter")
  ),
  
  tags$style(HTML("
    .btn-sm {
      padding: 2px 6px;
      font-size: 12px;
    }
  ")),
  
  titlePanel(
    div(
      "Gene-Centric Differential Expression Explorer",
      actionButton("how_to_use", label = NULL, icon = icon("circle-info"), class = "btn-sm", style = "margin-left: 10px;", title = "How to use")
    )
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      textInput("gene_input", "Enter Gene Symbol or Ensembl ID:", "LINC02528"),
      numericInput("padj_threshold", "Adjusted p-value <", 0.05, step = 0.01),
      numericInput("logfc_threshold", "Absolute log2 Fold Change >", 1, step = 0.1),
      div(
        actionButton("search_btn", "Search", class = "btn-primary btn-sm"),
        br(), br(),
        helpText("Results show studies where this gene is significantly differentially expressed.")
      ),
      uiOutput("study_selector")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Study Table", uiOutput("results_ui")),
        tabPanel(
          "Volcano Plot",
          fluidRow(
            column(4,
                   checkboxInput("apply_thresholds", "Apply thresholds to volcano plot", value = TRUE)
            )
          ),
          plotOutput("volcano_plot", height = "500px", width = "100%")
        ),
        tabPanel(
          "Meta Summary",
          plotOutput("summary_barplot", height = "500px", width = "100%")
        )
      )
    )
  )
)

# === SERVER ===
server <- function(input, output, session) {
  addResourcePath("result", "result")
  
  # ℹ️ Info modal
  observeEvent(input$how_to_use, {
    showModal(modalDialog(
      title = "How to Use This App",
      HTML("
        <p><strong>1.</strong> Enter a gene symbol (e.g., <code>TP53</code>) or Ensembl ID.</p>
        <p><strong>2.</strong> Adjust the p-value and log2FC thresholds if needed.</p>
        <p><strong>3.</strong> Click <strong>Search</strong> to view differential expression across studies.</p>
        <p><strong>4.</strong> Use the Study Table to explore results and access full HTML reports.</p>
        <p><strong>5.</strong> Use the Volcano Plot tab to visualize DE significance for the selected study.</p>
        <p><strong>6.</strong> Toggle the threshold overlay for clarity.</p>
        <p><strong>7.</strong> Download the filtered results as CSV.</p>
      "),
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })
  
  # Filtered search results
  search_results <- eventReactive(input$search_btn, {
    req(input$gene_input)
    gene_query <- trimws(input$gene_input)
    
    master_df %>%
      filter(
        grepl(gene_query, Symbol, ignore.case = TRUE) |
          grepl(gene_query, EnsemblGeneID, ignore.case = TRUE),
        padj < input$padj_threshold,
        abs(log2FoldChange) > input$logfc_threshold
      ) %>%
      mutate(direction = ifelse(log2FoldChange > 0, "Up", "Down")) %>%
      left_join(study_meta, by = "study_id") %>%
      mutate(
        report_link = paste0(
          '<a href="result/', study_id, '/report/study.html" target="_blank">Open Report</a>'
        )
      )
  })
  
  # Table and cleanly placed download button
  output$results_ui <- renderUI({
    results <- search_results()
    if (nrow(results) == 0) return(NULL)
    
    tagList(
      DTOutput("results_table"),
      tags$div(
        style = "
          border-top: 1px solid #eee;
          padding-top: 8px;
          margin-top: -5px;
          text-align: left;
        ",
        downloadButton("download_results", "Download Results", class = "btn-sm")
      )
    )
  })
  
  output$results_table <- renderDT({
    results <- search_results()
    datatable(
      results %>%
        dplyr::select(study_id, tissue, n_samples, Symbol, log2FoldChange, padj, direction, report_link),
      escape = FALSE,
      options = list(pageLength = 10)
    )
  })
  
  output$study_selector <- renderUI({
    results <- search_results()
    if (nrow(results) == 0) return(NULL)
    selectInput("selected_study", "Select study for volcano plot:", choices = unique(results$study_id))
  })
  
  volcano_data <- reactive({
    req(input$selected_study)
    file_path <- file.path("result", input$selected_study, "tables", "differential", "deseq2.annotated.tsv")
    if (!file.exists(file_path)) {
      showNotification(paste("❌ File not found:", file_path), type = "error")
      return(NULL)
    }
    read_tsv(file_path, show_col_types = FALSE)
  })
  
  output$volcano_plot <- renderPlot({
    df <- volcano_data()
    req(df)
    
    gene_query <- toupper(trimws(input$gene_input))
    
    df <- df %>%
      mutate(significant = padj < input$padj_threshold & abs(log2FoldChange) > input$logfc_threshold)
    
    highlighted_gene <- df %>%
      filter(toupper(Symbol) == gene_query | toupper(EnsemblGeneID) == gene_query)
    
    plot <- ggplot(df, aes(x = log2FoldChange, y = -log10(padj)))
    
    if (input$apply_thresholds) {
      plot <- plot +
        geom_point(aes(color = significant), alpha = 0.5) +
        scale_color_manual(values = c("TRUE" = "tomato", "FALSE" = "lightgray")) +
        labs(color = "Significant")
    } else {
      plot <- plot +
        geom_point(alpha = 0.4)
    }
    
    plot +
      geom_point(data = highlighted_gene, color = "red", size = 3) +
      geom_hline(yintercept = -log10(input$padj_threshold), linetype = "dashed", color = "gray") +
      geom_vline(xintercept = c(-input$logfc_threshold, input$logfc_threshold), linetype = "dashed", color = "gray") +
      theme_minimal() +
      labs(
        title = paste("Volcano Plot for", gene_query),
        x = "log2 Fold Change",
        y = "-log10 Adjusted p-value"
      )
  })
  
  output$summary_barplot <- renderPlot({
    results <- search_results()
    req(results)
    
    ggplot(results, aes(x = reorder(study_id, log2FoldChange), y = log2FoldChange, fill = direction)) +
      geom_col(width = 0.6) +
      coord_flip() +
      theme_minimal() +
      scale_fill_manual(values = c("Up" = "tomato", "Down" = "steelblue")) +
      labs(title = paste("Log2 Fold Change Across Studies for", toupper(input$gene_input)))
  })
  
  output$download_results <- downloadHandler(
    filename = function() {
      paste0("DE_results_", input$gene_input, ".csv")
    },
    content = function(file) {
      results <- search_results()
      write_csv(results, file)
    }
  )
}

# === Run App ===
shinyApp(ui, server)


