library(shiny)
library(shinythemes)
library(dplyr)
library(readr)
library(ggplot2)
library(tools)

# ── Folder paths (relative to app working directory) ─────────────────────────
RAW_DATA_DIR    <- file.path(getwd(), "raw_data")
BINNED_DATA_DIR <- file.path(getwd(), "binned_data")

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  theme = shinytheme("flatly"),
  
  tags$head(
    tags$style(HTML("
      body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; }

      /* ── Sidebar ── */
      .sidebar-panel {
        background-color: #2c3e50;
        color: #ecf0f1;
        min-height: 100vh;
        padding: 20px 15px;
      }
      .sidebar-panel h4 {
        color: #1abc9c;
        font-weight: 600;
        margin-top: 18px;
        margin-bottom: 8px;
        text-transform: uppercase;
        font-size: 12px;
        letter-spacing: 1px;
        border-bottom: 1px solid #3d5166;
        padding-bottom: 5px;
      }
      .sidebar-panel label { color: #bdc3c7; font-size: 13px; }
      .sidebar-panel .form-control,
      .sidebar-panel .shiny-input-container input[type='number'] {
        background-color: #3d5166;
        border: 1px solid #4a6278;
        color: #ecf0f1;
        border-radius: 4px;
      }
      .sidebar-panel .btn {
        width: 100%;
        margin-top: 6px;
        font-weight: 600;
        letter-spacing: 0.5px;
      }

      /* ── Buttons ── */
      .btn-primary   { background-color: #1abc9c; border-color: #16a085; }
      .btn-primary:hover { background-color: #16a085; }
      .btn-success   { background-color: #27ae60; border-color: #219a52; }
      .btn-success:hover { background-color: #219a52; }
      .btn-info      { background-color: #2980b9; border-color: #2471a3; }
      .btn-info:hover { background-color: #2471a3; }
      .btn-refresh   { background-color: #4a6278 !important; color: #ecf0f1 !important; border: none !important; }
      .btn-refresh:hover { background-color: #5a7a92 !important; }
      .btn-nav       { background-color: #34495e !important; color: #ecf0f1 !important;
                       border: 1px solid #4a6278 !important; font-size: 18px !important;
                       padding: 4px 14px !important; line-height: 1.2; }
      .btn-nav:hover { background-color: #1abc9c !important; }

      /* ── Title ── */
      .main-title {
        background-color: #2c3e50;
        color: #1abc9c;
        padding: 14px 20px;
        font-size: 22px;
        font-weight: 700;
        letter-spacing: 2px;
        text-transform: uppercase;
        margin-bottom: 0;
      }
      .subtitle {
        background-color: #34495e;
        color: #95a5a6;
        padding: 5px 20px 8px;
        font-size: 11px;
        letter-spacing: 1px;
        margin-bottom: 0;
      }

      /* ── Status / cards ── */
      .folder-info { color: #7f8c8d; font-size: 11px; margin-bottom: 8px;
                     word-break: break-all; line-height: 1.4; }
      .status-box  { background: #ecf0f1; border-left: 4px solid #1abc9c;
                     padding: 10px 14px; border-radius: 3px;
                     margin-bottom: 12px; font-size: 13px; }
      .status-box.warning { border-left-color: #e67e22; }
      .status-box.error   { border-left-color: #e74c3c; }

      /* ── Column chooser ── */
      .col-select-container {
        max-height: 360px; overflow-y: auto;
        border: 1px solid #dee2e6; border-radius: 4px;
        padding: 8px; background: #fff;
      }
      .col-select-container .checkbox { margin: 2px 0; }
      .col-select-container label { font-size: 12px; color: #333; }

      /* ── Tabs ── */
      .nav-tabs > li > a {
        color: #2c3e50;
        font-weight: 600;
        font-size: 13px;
        letter-spacing: 0.5px;
      }
      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:focus,
      .nav-tabs > li.active > a:hover {
        color: #1abc9c !important;
        border-top: 3px solid #1abc9c !important;
      }

      /* ── Plot viewer ── */
      .plot-nav-bar {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 10px;
        padding: 8px 12px;
        background: #f8f9fa;
        border-radius: 6px;
        border: 1px solid #dee2e6;
      }
      .plot-counter {
        font-size: 13px;
        color: #7f8c8d;
        min-width: 80px;
        text-align: center;
      }
      .plot-var-name {
        font-weight: 700;
        color: #2c3e50;
        font-size: 14px;
        flex: 1;
      }

      /* ── Table ── */
      #preview_table_container { overflow-x: auto; font-size: 12px; }
      table.dataTable thead { background-color: #2c3e50; color: white; }
      .dataTables_wrapper { font-size: 12px; }

      .section-header {
        font-weight: 700; color: #2c3e50;
        border-bottom: 2px solid #1abc9c;
        padding-bottom: 5px; margin-bottom: 12px; margin-top: 5px;
        text-transform: uppercase; font-size: 12px; letter-spacing: 1px;
      }

      .shiny-notification {
        background-color: #2c3e50; color: #ecf0f1;
        border-left: 4px solid #1abc9c;
      }
    "))
  ),
  
  # ── Title banner ─────────────────────────────────────────────────────────────
  fluidRow(column(12,
                  div(class = "main-title", "\u2697 CaliBin"),
                  div(class = "subtitle",   "Calibre breath-by-breath \u2192 time-bin averager")
  )),
  
  fluidRow(
    # ── SIDEBAR ────────────────────────────────────────────────────────────────
    column(3,
           div(class = "sidebar-panel",
               
               h4("\U0001f4c1 Data"),
               div(class = "folder-info", textOutput("folder_path_display")),
               uiOutput("file_selector_ui"),
               
               h4("\u23f1 Binning"),
               numericInput("bin_size", "Bin size (seconds)", value = 15,
                            min = 1, max = 600, step = 1),
               
               h4("\U0001f4ca Columns to Export"),
               checkboxInput("select_all", "Select / Deselect All", value = TRUE),
               uiOutput("col_selector_ui"),
               
               h4("\U0001f4be Export"),
               actionButton("process_btn", "Process & Preview", class = "btn btn-info btn-sm"),
               br(),
               actionButton("save_btn", "Save CSV", class = "btn btn-success btn-sm"),
               br(), br(),
               uiOutput("save_status_ui")
           )
    ),
    
    # ── MAIN PANEL ─────────────────────────────────────────────────────────────
    column(9,
           uiOutput("status_ui"),
           
           # Summary cards (only show when data loaded)
           fluidRow(
             column(3, uiOutput("card_rows")),
             column(3, uiOutput("card_bins")),
             column(3, uiOutput("card_cols")),
             column(3, uiOutput("card_duration"))
           ),
           
           br(),
           
           tabsetPanel(id = "main_tabs",
                       
                       # ── TAB 1: Raw data plots ──────────────────────────────────────────────
                       tabPanel(
                         title = "\U0001f4c8 Raw Data",
                         value = "tab_raw",
                         br(),
                         uiOutput("raw_plot_ui")
                       ),
                       
                       # ── TAB 2: Binned data plots ───────────────────────────────────────────
                       tabPanel(
                         title = "\U0001f4ca Binned Data",
                         value = "tab_binned",
                         br(),
                         uiOutput("binned_plot_ui")
                       ),
                       
                       # ── TAB 3: Data table ──────────────────────────────────────────────────
                       tabPanel(
                         title = "\U0001f5c3 Data Table",
                         value = "tab_table",
                         br(),
                         div(class = "section-header", "Binned Data Preview"),
                         div(id = "preview_table_container",
                             DT::dataTableOutput("preview_table")
                         )
                       )
           )
    )
  )
)

# ── SERVER ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  rv <- reactiveValues(
    files         = character(0),
    raw_data      = NULL,
    binned_data   = NULL,
    loaded_file   = NULL,
    all_cols      = character(0),
    numeric_cols  = character(0),   # numeric cols only, for plotting
    save_msg      = NULL,
    raw_plot_idx  = 1L,
    bin_plot_idx  = 1L
  )
  
  # ── Folder path display ──────────────────────────────────────────────────────
  output$folder_path_display <- renderText({
    paste0("Reading from: ", RAW_DATA_DIR)
  })
  
  # ── Scan raw_data/ ───────────────────────────────────────────────────────────
  scan_folder <- function(notify = FALSE) {
    if (!dir.exists(RAW_DATA_DIR)) {
      rv$files <- character(0)
      if (notify) showNotification("'raw_data' folder not found.", type = "error")
    } else {
      csvs <- list.files(RAW_DATA_DIR, pattern = "\\.csv$",
                         full.names = FALSE, ignore.case = TRUE)
      rv$files <- csvs
      if (notify) {
        if (length(csvs) == 0)
          showNotification("No CSV files found in raw_data/", type = "warning")
        else
          showNotification(paste(length(csvs), "CSV file(s) found."), type = "message")
      }
    }
  }
  
  observe({ scan_folder(notify = FALSE) }) |> bindEvent(TRUE, once = TRUE)
  observeEvent(input$refresh_files, { scan_folder(notify = TRUE) })
  
  # ── File selector UI ─────────────────────────────────────────────────────────
  output$file_selector_ui <- renderUI({
    if (!dir.exists(RAW_DATA_DIR)) {
      return(tagList(
        div(style = "color:#e74c3c;font-size:12px;margin:8px 0;",
            "Create a 'raw_data' folder next to app.R and place CSV files inside."),
        actionButton("refresh_files", "\u21bb Refresh", class = "btn btn-refresh btn-sm")
      ))
    }
    if (length(rv$files) == 0) {
      return(tagList(
        div(style = "color:#e67e22;font-size:12px;margin:8px 0;",
            "No CSV files found in raw_data/"),
        actionButton("refresh_files", "\u21bb Refresh", class = "btn btn-refresh btn-sm")
      ))
    }
    tagList(
      selectInput("selected_file", "Select File",
                  choices = rv$files, selected = rv$files[1], width = "100%"),
      fluidRow(
        column(7, actionButton("load_file",     "Load File",      class = "btn btn-primary btn-sm")),
        column(5, actionButton("refresh_files", "\u21bb Refresh", class = "btn btn-refresh btn-sm"))
      )
    )
  })
  
  # ── Load file ────────────────────────────────────────────────────────────────
  observeEvent(input$load_file, {
    req(input$selected_file)
    fp <- file.path(RAW_DATA_DIR, input$selected_file)
    tryCatch({
      dat        <- read_csv(fp, show_col_types = FALSE)
      time_col   <- names(dat)[1]
      dat[[time_col]] <- suppressWarnings(as.numeric(dat[[time_col]]))
      
      rv$raw_data     <- dat
      rv$loaded_file  <- input$selected_file
      rv$binned_data  <- NULL
      rv$all_cols     <- names(dat)
      rv$numeric_cols <- names(dat)[sapply(dat, is.numeric)]
      rv$save_msg     <- NULL
      rv$raw_plot_idx <- 1L
      rv$bin_plot_idx <- 1L
      
      showNotification(paste("Loaded:", input$selected_file), type = "message")
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message), type = "error")
    })
  })
  
  # ── Column selector UI ───────────────────────────────────────────────────────
  output$col_selector_ui <- renderUI({
    req(rv$all_cols)
    div(class = "col-select-container",
        checkboxGroupInput("selected_cols", label = NULL,
                           choices = rv$all_cols, selected = rv$all_cols)
    )
  })
  
  observeEvent(input$select_all, {
    req(rv$all_cols)
    updateCheckboxGroupInput(session, "selected_cols",
                             selected = if (input$select_all) rv$all_cols else character(0))
  })
  
  # ── Status banner ────────────────────────────────────────────────────────────
  output$status_ui <- renderUI({
    if (is.null(rv$raw_data)) {
      div(class = "status-box warning",
          "Select a file from the list and click 'Load File' to begin.")
    } else if (is.null(rv$binned_data)) {
      div(class = "status-box",
          paste0("\u2705 Loaded: ", rv$loaded_file,
                 "  \u2014  ", nrow(rv$raw_data), " breaths  |  ",
                 ncol(rv$raw_data), " columns  |  Press 'Process & Preview'"))
    } else {
      div(class = "status-box",
          paste0("\U0001f7e2 Binned: ", rv$loaded_file,
                 "  \u2014  ", nrow(rv$binned_data),
                 " bins of ", input$bin_size, " s"))
    }
  })
  
  # ── Summary cards ────────────────────────────────────────────────────────────
  make_card <- function(value, label, color) {
    div(style = paste0("background:", color, ";color:white;padding:14px 10px;",
                       "border-radius:6px;text-align:center;margin-bottom:10px;"),
        div(style = "font-size:28px;font-weight:700;", value),
        div(style = "font-size:11px;text-transform:uppercase;letter-spacing:1px;", label)
    )
  }
  
  output$card_rows <- renderUI({
    if (is.null(rv$raw_data)) return(NULL)
    make_card(nrow(rv$raw_data), "Raw breaths", "#2980b9")
  })
  output$card_bins <- renderUI({
    if (is.null(rv$binned_data)) return(NULL)
    make_card(nrow(rv$binned_data), paste0(input$bin_size, "-s bins"), "#1abc9c")
  })
  output$card_cols <- renderUI({
    if (is.null(rv$binned_data)) return(NULL)
    make_card(ncol(rv$binned_data), "Columns", "#8e44ad")
  })
  output$card_duration <- renderUI({
    if (is.null(rv$raw_data)) return(NULL)
    time_col <- names(rv$raw_data)[1]
    dur <- round(max(rv$raw_data[[time_col]], na.rm = TRUE) / 60, 1)
    make_card(paste0(dur, " min"), "Duration", "#e67e22")
  })
  
  # ── Plot-able columns: numeric, selected by user, excluding time column ───────
  plot_cols <- function(dat, selected = NULL) {
    time_col    <- names(dat)[1]
    nms         <- names(dat)
    numeric_nms <- nms[sapply(dat, is.numeric) & nms != time_col]
    if (!is.null(selected) && length(selected) > 0) {
      numeric_nms <- intersect(selected, numeric_nms)
    }
    numeric_nms
  }
  
  # ── Generic plot function ─────────────────────────────────────────────────────
  make_line_plot <- function(dat, var, subtitle = NULL) {
    time_col <- names(dat)[1]
    df <- dat[, c(time_col, var)]
    names(df) <- c("time_s", "value")
    df <- df[!is.na(df$value), ]
    
    x_lab <- paste0("Time (s)")
    y_lab <- var
    
    ggplot(df, aes(x = time_s, y = value)) +
      geom_line(colour = "#2980b9", linewidth = 0.7) +
      geom_point(colour = "#1abc9c", size = 1.2, alpha = 0.6) +
      labs(title = var, subtitle = subtitle, x = x_lab, y = y_lab) +
      theme_minimal(base_size = 13) +
      theme(
        plot.title    = element_text(face = "bold", colour = "#2c3e50", size = 14),
        plot.subtitle = element_text(colour = "#7f8c8d", size = 11),
        axis.title    = element_text(colour = "#7f8c8d", size = 11),
        panel.grid.minor = element_blank(),
        panel.border  = element_rect(colour = "#dee2e6", fill = NA)
      )
  }
  
  # ── Helper: nav bar UI ────────────────────────────────────────────────────────
  nav_bar_ui <- function(prev_id, next_id, idx, total, var_name) {
    div(class = "plot-nav-bar",
        actionButton(prev_id, "\u2039", class = "btn btn-nav btn-sm"),
        actionButton(next_id, "\u203a", class = "btn btn-nav btn-sm"),
        div(class = "plot-counter", paste0(idx, " / ", total)),
        div(class = "plot-var-name", var_name)
    )
  }
  
  # ════════════════════════════════════════════════════════════════════════════
  # TAB 1 — RAW DATA PLOTS
  # ════════════════════════════════════════════════════════════════════════════
  
  # Navigate raw plots
  observeEvent(input$raw_prev, {
    cols <- plot_cols(rv$raw_data, input$selected_cols)
    rv$raw_plot_idx <- max(1L, rv$raw_plot_idx - 1L)
  })
  observeEvent(input$raw_next, {
    cols <- plot_cols(rv$raw_data, input$selected_cols)
    rv$raw_plot_idx <- min(length(cols), rv$raw_plot_idx + 1L)
  })
  
  output$raw_plot_ui <- renderUI({
    if (is.null(rv$raw_data)) {
      return(div(class = "status-box warning",
                 "Load a file to view raw data plots."))
    }
    cols <- plot_cols(rv$raw_data, input$selected_cols)
    n    <- length(cols)
    if (n == 0) return(div(class = "status-box warning",
                           "No numeric columns selected. Tick at least one column in the sidebar."))
    idx  <- min(rv$raw_plot_idx, n)
    tagList(
      nav_bar_ui("raw_prev", "raw_next", idx, n, cols[idx]),
      plotOutput("raw_plot", height = "420px")
    )
  })
  
  output$raw_plot <- renderPlot({
    req(rv$raw_data)
    cols <- plot_cols(rv$raw_data, input$selected_cols)
    req(length(cols) > 0)
    idx <- min(rv$raw_plot_idx, length(cols))
    make_line_plot(rv$raw_data, cols[idx],
                   subtitle = paste("Raw breath-by-breath \u2014", rv$loaded_file))
  })
  
  # ════════════════════════════════════════════════════════════════════════════
  # TAB 2 — BINNED DATA PLOTS
  # ════════════════════════════════════════════════════════════════════════════
  
  observeEvent(input$bin_prev, {
    rv$bin_plot_idx <- max(1L, rv$bin_plot_idx - 1L)
  })
  observeEvent(input$bin_next, {
    cols <- plot_cols(rv$binned_data, input$selected_cols)
    rv$bin_plot_idx <- min(length(cols), rv$bin_plot_idx + 1L)
  })
  
  output$binned_plot_ui <- renderUI({
    if (is.null(rv$binned_data)) {
      return(div(class = "status-box warning",
                 "Process the data first (click 'Process & Preview') to view binned plots."))
    }
    cols <- plot_cols(rv$binned_data, input$selected_cols)
    n    <- length(cols)
    if (n == 0) return(div(class = "status-box warning",
                           "No numeric columns selected. Tick at least one column in the sidebar."))
    idx  <- min(rv$bin_plot_idx, n)
    tagList(
      nav_bar_ui("bin_prev", "bin_next", idx, n, cols[idx]),
      plotOutput("binned_plot", height = "420px")
    )
  })
  
  output$binned_plot <- renderPlot({
    req(rv$binned_data)
    cols <- plot_cols(rv$binned_data, input$selected_cols)
    req(length(cols) > 0)
    idx <- min(rv$bin_plot_idx, length(cols))
    make_line_plot(rv$binned_data, cols[idx],
                   subtitle = paste0(input$bin_size, "-s bins \u2014 ", rv$loaded_file))
  })
  
  # ════════════════════════════════════════════════════════════════════════════
  # BINNING LOGIC
  # ════════════════════════════════════════════════════════════════════════════
  
  bin_data <- function(dat, bin_sec, keep_cols) {
    time_col    <- names(dat)[1]
    cols_to_use <- intersect(keep_cols, names(dat))
    
    dat %>%
      mutate(.bin = floor(.data[[time_col]] / bin_sec)) %>%
      select(all_of(c(cols_to_use, ".bin"))) %>%
      group_by(.bin) %>%
      summarise(across(where(is.numeric), ~ mean(.x, na.rm = TRUE)),
                across(where(~ !is.numeric(.x)), ~ first(.x)),
                .groups = "drop") %>%
      mutate(!!time_col := .bin * bin_sec) %>%
      select(-.bin) %>%
      select(all_of(c(time_col, setdiff(cols_to_use, time_col))))
  }
  
  observeEvent(input$process_btn, {
    req(rv$raw_data, input$bin_size, length(input$selected_cols) > 0)
    withProgress(message = "Binning data...", value = 0.5, {
      tryCatch({
        rv$binned_data  <- bin_data(rv$raw_data, input$bin_size, input$selected_cols)
        rv$bin_plot_idx <- 1L
        showNotification(paste("Done:", nrow(rv$binned_data), "bins created."), type = "message")
        updateTabsetPanel(session, "main_tabs", selected = "tab_binned")
      }, error = function(e) {
        showNotification(paste("Binning error:", e$message), type = "error")
      })
    })
  })
  
  # ── Preview table ─────────────────────────────────────────────────────────────
  output$preview_table <- DT::renderDataTable({
    req(rv$binned_data)
    DT::datatable(rv$binned_data,
                  options = list(scrollX = TRUE, pageLength = 20, dom = "ltip"),
                  rownames = FALSE
    ) %>%
      DT::formatRound(columns = which(sapply(rv$binned_data, is.numeric)), digits = 4)
  })
  
  # ── Save CSV → binned_data/ ───────────────────────────────────────────────────
  observeEvent(input$save_btn, {
    req(rv$binned_data, rv$loaded_file, input$bin_size)
    
    # Create binned_data folder if it doesn't exist
    if (!dir.exists(BINNED_DATA_DIR)) {
      dir.create(BINNED_DATA_DIR, recursive = TRUE)
    }
    
    new_name <- paste0(input$bin_size, "_sec_", rv$loaded_file)
    out_path <- file.path(BINNED_DATA_DIR, new_name)
    
    tryCatch({
      write_csv(rv$binned_data, out_path)
      rv$save_msg <- paste0("\u2705 Saved: binned_data/", new_name)
      showNotification(rv$save_msg, type = "message")
    }, error = function(e) {
      rv$save_msg <- paste0("\u274c Save failed: ", e$message)
      showNotification(rv$save_msg, type = "error")
    })
  })
  
  output$save_status_ui <- renderUI({
    req(rv$save_msg)
    div(style = "color:#1abc9c;font-size:12px;margin-top:6px;word-break:break-all;",
        rv$save_msg)
  })
}

shinyApp(ui = ui, server = server)