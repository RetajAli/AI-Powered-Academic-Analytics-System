library(shiny)
library(shinydashboard)
library(dplyr)
library(plotly)
library(DT)

# ── Load CSV ──────────────────────────────────────────────────────────────────
load_data <- function() {
  path <- "students_dashboard_slots_fixed.csv"
  if (!file.exists(path)) {
    showNotification("CSV file not found!", type = "error")
    return(NULL)
  }
  df <- read.csv(path, stringsAsFactors = FALSE)
  df$Average                <- as.numeric(df$Average)
  df$Total                  <- as.numeric(df$Total)
  df$Math                   <- as.numeric(df$Math)
  df$Programming            <- as.numeric(df$Programming)
  df$Database               <- as.numeric(df$Database)
  df$Statistics             <- as.numeric(df$Statistics)
  df$Software_Engineering   <- as.numeric(df$Software_Engineering)
  df$Attendance_Percentage  <- as.numeric(df$Attendance_Percentage)
  df
}

SUBJECTS       <- c("Math", "Programming", "Database", "Statistics", "Software_Engineering")
SUBJECT_LABELS <- c("Math", "Programming", "Database", "Statistics", "Soft. Eng.")

score_bar_color <- function(score) {
  if (score >= 85) "linear-gradient(90deg,#22c55e,#06b6d4)"
  else if (score >= 70) "linear-gradient(90deg,#06b6d4,#7c3aed)"
  else if (score >= 60) "linear-gradient(90deg,#f59e0b,#f97316)"
  else "linear-gradient(90deg,#ef4444,#dc2626)"
}

# ── Helper: mini stat card ────────────────────────────────────────────────────
stat_mini_card <- function(label, value, sub, color) {
  div(
    style = paste0(
      "background:rgba(15,23,42,0.8);border:1px solid rgba(255,255,255,0.1);",
      "border-radius:16px;padding:18px;position:relative;overflow:hidden;"
    ),
    div(style = "font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:#94a3b8;font-weight:600;margin-bottom:6px;", label),
    div(style = paste0("font-size:26px;font-weight:900;color:", color, ";font-family:'Space Grotesk',sans-serif;"), value),
    div(style = "font-size:12px;color:#64748b;margin-top:4px;", sub)
  )
}

# ── Pill toggle filter UI helper ──────────────────────────────────────────────
subject_filter_ui <- function(input_id) {
  div(
    style = "display:flex;flex-wrap:wrap;gap:10px;margin-bottom:20px;align-items:center;",
    span(style = "font-size:13px;color:#94a3b8;font-weight:600;margin-right:4px;", "Filter:"),
    # "All" pill handled via JS toggle; we use checkboxGroupButtons pattern via custom HTML + shinyjs approach
    # Using standard checkboxGroupInput styled as pills via CSS
    tags$div(
      id = paste0(input_id, "_container"),
      class = "pill-filter-group",
      checkboxGroupInput(
        inputId  = input_id,
        label    = NULL,
        choices  = setNames(SUBJECTS, SUBJECT_LABELS),
        selected = SUBJECTS,
        inline   = TRUE
      )
    ),
    actionButton(
      paste0(input_id, "_all"),
      "Select All",
      class = "pill-select-all"
    ),
    actionButton(
      paste0(input_id, "_none"),
      "Clear All",
      class = "pill-clear-all"
    )
  )
}

# ── Student Dashboard UI Function ────────────────────────────────────────────
make_student_dashboard_ui <- function() {
  dashboardPage(
    skin = "black",
    
    dashboardHeader(title = ""),
    
    dashboardSidebar(
      div(class = "brand-panel",
          div(class = "brand-icon", icon("user-graduate")),
          div(class = "brand-title", "Student Dashboard"),
          div(class = "brand-subtitle", "Your Academic Portal")
      ),
      sidebarMenu(
        id = "student_tabs",
        menuItem("Overview",           tabName = "student_overview",    icon = icon("chart-line")),
        menuItem("Subject Performance",tabName = "student_subjects",    icon = icon("book")),
        menuItem("Class Comparison",   tabName = "student_comparison",  icon = icon("users")),
        menuItem("Class Rankings",     tabName = "student_rankings",    icon = icon("trophy"))
      ),
      div(class = "sidebar-footer",
          div(class = "live-dot"),
          span("Dashboard Active"),
          br(), br(),
          actionButton("student_logout_btn", "Logout",
                       icon = icon("right-from-bracket"), class = "logout-button")
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$style(HTML("
          /* ── Layout ─────────────────────────────────────────────── */
          .main-header { display: none !important; }
          html, body { height:100% !important; margin:0 !important; padding:0 !important; }
          body, .content-wrapper, .right-side {
            background: linear-gradient(135deg,#020617 0%,#0f172a 45%,#111827 100%);
            color: #e5e7eb;
            font-family: 'Segoe UI', Arial, sans-serif;
          }
          .wrapper { min-height:100vh !important; }
          .content-wrapper, .right-side {
            position:fixed !important; top:0 !important; left:230px !important;
            right:0 !important; bottom:0 !important; margin-left:0 !important;
            padding:22px !important; min-height:100vh !important;
            overflow-y:auto !important; overflow-x:hidden !important;
          }
          .main-sidebar {
            position:fixed !important; top:0 !important; left:0 !important;
            bottom:0 !important; width:230px !important; height:100vh !important;
            min-height:100vh !important;
            background:rgba(2,6,23,0.98) !important;
            border-right:1px solid rgba(255,255,255,0.08);
            overflow-y:auto !important; overflow-x:hidden !important;
          }
          .main-sidebar .sidebar {
            min-height:100vh !important; padding-top:20px !important; padding-bottom:170px !important;
          }

          /* ── Sidebar brand ───────────────────────────────────────── */
          .brand-panel { padding:18px; text-align:center; }
          .brand-icon {
            width:64px; height:64px; margin:auto; border-radius:22px;
            background:linear-gradient(135deg,#22c55e,#06b6d4);
            color:white; display:flex; align-items:center; justify-content:center; font-size:26px;
          }
          .brand-title { margin-top:14px; font-size:17px; font-weight:900; color:white; }
          .brand-subtitle { font-size:12px; color:#94a3b8; margin-top:5px; }
          .sidebar-menu > li > a {
            color:#cbd5e1 !important; font-weight:700;
            margin:8px 13px; border-radius:18px; padding:14px 16px;
          }
          .sidebar-menu > li.active > a, .sidebar-menu > li:hover > a {
            background:linear-gradient(90deg,#22c55e,#06b6d4) !important; color:white !important;
          }
          .sidebar-footer {
            position:fixed !important; bottom:24px !important; left:0 !important;
            width:230px !important; text-align:center; color:#94a3b8; font-size:12px;
            padding:12px; background:rgba(2,6,23,0.98);
          }
          .live-dot {
            width:10px; height:10px; background:#22c55e;
            display:inline-block; border-radius:50%; margin-right:7px;
          }
          .logout-button {
            width:85%;
            background:linear-gradient(90deg,#dc2626,#991b1b) !important;
            color:white !important; border:none !important;
            border-radius:999px !important; font-weight:900;
          }

          /* ── Hero card ───────────────────────────────────────────── */
          .hero-card {
            background:linear-gradient(135deg,rgba(34,197,94,0.15),rgba(6,182,212,0.12)),rgba(15,23,42,0.82);
            border:1px solid rgba(255,255,255,0.12);
            border-radius:30px; padding:30px; margin-bottom:24px;
          }
          .hero-title  { font-size:32px; font-weight:900; color:#ffffff; margin-bottom:8px; }
          .hero-subtitle { color:#cbd5e1; font-size:14px; }
          .status-badge {
            background:rgba(34,197,94,0.16) !important; color:#86efac !important;
            border:1px solid rgba(34,197,94,0.40) !important;
            padding:10px 18px; border-radius:999px; font-weight:800;
          }

          /* ── Box (card) ──────────────────────────────────────────── */
          .box {
            background:rgba(15,23,42,0.86);
            border:1px solid rgba(255,255,255,0.10); border-radius:16px;
          }
          .box-header { color:#ffffff !important; background:rgba(255,255,255,0.04); border-radius:16px 16px 0 0; }
          .box-title  { font-weight:900 !important; color:#ffffff !important; font-size:15px; }
          .box-header .fa, .box-header .fas, .box-header svg { color:#22c55e !important; }
          .box-body   { color:#e5e7eb; }

          /* ── Value boxes ─────────────────────────────────────────── */
          .small-box > .inner > p  { color:#ffffff !important; font-size:15px !important; font-weight:700 !important; }
          .small-box > .inner > h3 { color:#ffffff !important; font-size:30px !important; font-weight:900 !important; }
          .small-box > .small-box-footer { color:rgba(255,255,255,0.75) !important; }

          /* ── DataTable ───────────────────────────────────────────── */
          .dataTables_wrapper,
          .dataTables_wrapper table,
          .dataTables_wrapper th,
          .dataTables_wrapper td { color:#e2e8f0 !important; background:transparent !important; }
          .dataTables_wrapper table thead th {
            color:#ffffff !important; font-weight:800 !important;
            border-bottom:1px solid rgba(255,255,255,0.15) !important;
            background:rgba(255,255,255,0.06) !important;
          }
          .dataTables_wrapper table tbody tr { background:transparent !important; }
          .dataTables_wrapper table tbody tr:hover td { background:rgba(255,255,255,0.05) !important; }
          .dataTables_wrapper table tbody td { border-top:1px solid rgba(255,255,255,0.06) !important; }
          .dataTables_filter label, .dataTables_length label,
          .dataTables_info, .dataTables_paginate { color:#94a3b8 !important; }
          .dataTables_paginate .paginate_button { color:#94a3b8 !important; }
          .dataTables_paginate .paginate_button.current { color:#22c55e !important; font-weight:900; }

          /* ── Pill filter ─────────────────────────────────────────── */
          .pill-filter-group .shiny-input-container { margin-bottom:0; }
          .pill-filter-group .checkbox-inline { margin:0 !important; }
          .pill-filter-group input[type='checkbox'] { display:none !important; }
          .pill-filter-group input[type='checkbox'] + span {
            display:inline-block; cursor:pointer;
            padding:7px 16px; border-radius:999px; font-size:13px; font-weight:700;
            border:1.5px solid rgba(255,255,255,0.18); color:#94a3b8;
            background:rgba(255,255,255,0.05);
            transition:all .2s ease; user-select:none;
          }
          .pill-filter-group input[type='checkbox']:checked + span {
            background:linear-gradient(90deg,#22c55e,#06b6d4) !important;
            color:#ffffff !important; border-color:transparent !important;
            box-shadow:0 0 10px rgba(34,197,94,0.35);
          }
          .pill-select-all, .pill-clear-all {
            padding:7px 16px !important; border-radius:999px !important;
            font-size:12px !important; font-weight:700 !important;
            border:1.5px solid rgba(255,255,255,0.2) !important;
            background:rgba(255,255,255,0.07) !important; color:#cbd5e1 !important;
            box-shadow:none !important;
          }
          .pill-select-all:hover { border-color:#22c55e !important; color:#4ade80 !important; }
          .pill-clear-all:hover  { border-color:#ef4444 !important; color:#fca5a5 !important; }

          /* ── No-subject warning ──────────────────────────────────── */
          .no-subject-warning {
            text-align:center; padding:40px; color:#94a3b8;
            font-size:15px; font-weight:600;
          }
        "))
      ),
      
      tabItems(
        
        # ── Overview Tab ──────────────────────────────────────────────────────
        tabItem(tabName = "student_overview",
                div(class = "hero-card",
                    div(
                      div(class = "hero-title",    textOutput("student_welcome")),
                      div(class = "hero-subtitle", "Track your academic progress")
                    ),
                    div(class = "status-badge", icon("star"), " Student View")
                ),
                fluidRow(
                  valueBoxOutput("student_avg_box",        width = 3),
                  valueBoxOutput("student_grade_box",      width = 3),
                  valueBoxOutput("student_total_box",      width = 3),
                  valueBoxOutput("student_attendance_box", width = 3)
                ),
                fluidRow(
                  box(title = tagList(icon("chart-simple"), " Subject Performance"),
                      width = 5, uiOutput("student_subject_bars")),
                  box(title = tagList(icon("gauge"), " Overall Score"),
                      width = 7, plotlyOutput("student_grade_gauge", height = 280))
                ),
                fluidRow(
                  box(title = tagList(icon("table"),    " Subject Details"),      width = 6, DTOutput("student_subject_table")),
                  box(title = tagList(icon("lightbulb")," Recommendations"),      width = 6, uiOutput("student_recommendations"))
                )
        ),
        
        # ── Subject Performance Tab ───────────────────────────────────────────
        tabItem(tabName = "student_subjects",
                div(class = "hero-card",
                    div(class = "hero-title",    "Subject Performance"),
                    div(class = "hero-subtitle", "Detailed analysis of each subject")
                ),
                # Pill filter
                div(class = "box", style = "padding:20px;margin-bottom:20px;",
                    subject_filter_ui("subj_filter_perf")
                ),
                fluidRow(
                  box(title = tagList(icon("chart-bar"), " Scores by Subject"),
                      width = 6, plotlyOutput("student_all_subjects_chart", height = 400)),
                  box(title = tagList(icon("circle-nodes"), " Performance Radar"),
                      width = 6, plotlyOutput("student_radar_chart", height = 400))
                )
        ),
        
        # ── Class Comparison Tab ──────────────────────────────────────────────
        tabItem(tabName = "student_comparison",
                div(class = "hero-card",
                    div(class = "hero-title",    "Compare with Class"),
                    div(class = "hero-subtitle", "See how you rank compared to classmates")
                ),
                div(class = "box", style = "padding:20px;margin-bottom:20px;",
                    subject_filter_ui("subj_filter_comp")
                ),
                fluidRow(
                  box(title = tagList(icon("info-circle"), " Your Class Standing"),
                      width = 12, uiOutput("class_standing_info"))
                ),
                fluidRow(
                  box(title = tagList(icon("chart-bar"), " You vs Class Average"),
                      width = 12, plotlyOutput("student_comparison_chart", height = 400))
                )
        ),
        
        # ── Class Rankings Tab ────────────────────────────────────────────────
        tabItem(tabName = "student_rankings",
                div(class = "hero-card",
                    div(class = "hero-title",    "Class Rankings"),
                    div(class = "hero-subtitle", "View class performance rankings")
                ),
                div(class = "box", style = "padding:20px;margin-bottom:20px;",
                    subject_filter_ui("subj_filter_rank")
                ),
                fluidRow(
                  box(title = tagList(icon("trophy"),       " Top 5 Students"),      width = 6, DTOutput("top_performers_table")),
                  box(title = tagList(icon("chart-column"), " Score Distribution"),  width = 6, plotlyOutput("score_distribution_chart", height = 350))
                ),
                fluidRow(
                  box(title = tagList(icon("list-ol"), " Full Class Rankings"),
                      width = 12, DTOutput("full_rankings_table"))
                )
        )
      )
    )
  )
}

# ── Plotly theme defaults ─────────────────────────────────────────────────────
plotly_layout_defaults <- list(
  paper_bgcolor = "rgba(0,0,0,0)",
  plot_bgcolor  = "rgba(0,0,0,0)",
  font          = list(color = "#94a3b8", family = "Space Grotesk, Segoe UI, sans-serif"),
  xaxis  = list(gridcolor = "rgba(255,255,255,0.06)", zerolinecolor = "rgba(255,255,255,0.06)", color = "#94a3b8"),
  yaxis  = list(gridcolor = "rgba(255,255,255,0.06)", zerolinecolor = "rgba(255,255,255,0.06)", color = "#94a3b8"),
  legend = list(bgcolor  = "rgba(0,0,0,0)", font = list(color = "#cbd5e1")),
  margin = list(l = 40, r = 20, t = 30, b = 40)
)

# ── Student Dashboard Server ──────────────────────────────────────────────────
register_student_dashboard_server <- function(input, output, session, current_student) {
  
  ALL_DATA <- load_data()
  
  student <- reactive({
    req(current_student())
    if (is.null(ALL_DATA)) return(NULL)
    current_student()
  })
  
  ranked_class <- reactive({
    if (is.null(ALL_DATA)) return(NULL)
    df <- ALL_DATA[!is.na(ALL_DATA$Average), ]
    df[order(-df$Average), ]
  })
  
  # ── Helper: resolve selected subjects & labels for a filter input ───────────
  sel_subjects <- function(filter_id) {
    vals <- input[[filter_id]]
    if (is.null(vals) || length(vals) == 0) return(list(subj = character(0), labels = character(0)))
    idx <- match(vals, SUBJECTS)
    list(subj = SUBJECTS[idx], labels = SUBJECT_LABELS[idx])
  }
  
  # ── Select-All / Clear-All observers for each tab ──────────────────────────
  for (fid in c("subj_filter_perf", "subj_filter_comp", "subj_filter_rank")) {
    local({
      filter_id <- fid
      observeEvent(input[[paste0(filter_id, "_all")]], {
        updateCheckboxGroupInput(session, filter_id, selected = SUBJECTS)
      })
      observeEvent(input[[paste0(filter_id, "_none")]], {
        updateCheckboxGroupInput(session, filter_id, selected = character(0))
      })
    })
  }
  
  # ════════════════════════════════════════════════════════════════════════════
  #  OVERVIEW TAB
  # ════════════════════════════════════════════════════════════════════════════
  
  output$student_welcome <- renderText({
    s <- student(); req(s)
    paste0("Welcome back, ", s$Student_Name, " \U0001f44b")
  })
  
  output$student_avg_box <- renderValueBox({
    s <- student(); req(s)
    valueBox(paste0(round(s$Average, 1), "%"), "Average Score", icon("chart-line"), color = "light-blue")
  })
  
  output$student_grade_box <- renderValueBox({
    s <- student(); req(s)
    col <- switch(s$Grade, "A" = "green", "B" = "light-blue", "C" = "yellow", "red")
    valueBox(s$Grade, "Letter Grade", icon("graduation-cap"), color = col)
  })
  
  output$student_total_box <- renderValueBox({
    s <- student(); req(s)
    valueBox(s$Total, "Total Score", icon("calculator"), color = "purple")
  })
  
  output$student_attendance_box <- renderValueBox({
    s <- student(); req(s)
    col <- if (s$Attendance_Percentage >= 80) "green" else if (s$Attendance_Percentage >= 60) "yellow" else "red"
    valueBox(paste0(s$Attendance_Percentage, "%"), "Attendance", icon("calendar-check"), color = col)
  })
  
  output$student_subject_bars <- renderUI({
    s <- student(); req(s)
    bars <- lapply(seq_along(SUBJECTS), function(i) {
      score <- s[[SUBJECTS[i]]]
      color <- if (score >= 85) "#22c55e" else if (score >= 70) "#06b6d4" else if (score >= 60) "#f59e0b" else "#ef4444"
      div(style = "margin-bottom:14px;",
          div(style = "display:flex;justify-content:space-between;font-size:13px;margin-bottom:6px;",
              span(style = "font-weight:600;color:#cbd5e1;", SUBJECT_LABELS[i]),
              span(style = paste0("font-weight:700;color:", color, ";"), score)
          ),
          div(style = "background:rgba(255,255,255,0.07);border-radius:999px;height:8px;overflow:hidden;",
              div(style = paste0("width:", score, "%;height:100%;border-radius:999px;background:", score_bar_color(score), ";"))
          )
      )
    })
    do.call(tagList, bars)
  })
  
  output$student_subject_table <- renderDT({
    s <- student(); req(s)
    df <- data.frame(
      Subject = SUBJECT_LABELS,
      Score   = sapply(SUBJECTS, function(x) s[[x]]),
      Grade   = sapply(SUBJECTS, function(x) {
        sc <- s[[x]]
        if (sc >= 85) "A" else if (sc >= 70) "B" else if (sc >= 60) "C" else "D"
      }),
      stringsAsFactors = FALSE
    )
    datatable(df, options = list(dom = "t", paging = FALSE, searching = FALSE),
              rownames = FALSE, class = "compact") |>
      formatStyle("Score",
                  background = styleInterval(c(60,70,85),
                                             c("rgba(239,68,68,0.2)","rgba(245,158,11,0.2)","rgba(6,182,212,0.2)","rgba(34,197,94,0.2)")),
                  color      = styleInterval(c(60,70,85),
                                             c("#fca5a5","#fcd34d","#67e8f9","#4ade80")),
                  fontWeight = "bold") |>
      formatStyle("Grade",
                  color      = styleEqual(c("A","B","C","D"), c("#4ade80","#67e8f9","#fcd34d","#fca5a5")),
                  fontWeight = "bold")
  }, server = FALSE)
  
  output$student_grade_gauge <- renderPlotly({
    s <- student(); req(s)
    avg   <- s$Average
    color <- if (avg >= 85) "#22c55e" else if (avg >= 70) "#06b6d4" else if (avg >= 60) "#f59e0b" else "#ef4444"
    plot_ly(
      values = c(avg, 100 - avg), labels = c("Score","Remaining"),
      type   = "pie", hole = 0.72,
      marker = list(colors = c(color, "rgba(255,255,255,0.06)"),
                    line   = list(color = "rgba(0,0,0,0)", width = 0)),
      textinfo  = "none", hoverinfo = "label+value",
      sort = FALSE, direction = "clockwise", rotation = 225
    ) |>
      layout(
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        showlegend = FALSE,
        margin = list(l=10, r=10, t=10, b=10),
        annotations = list(list(
          text = paste0("<b>", round(avg,1), "%</b><br><span style='font-size:12px'>",
                        s$Grade, " \u00b7 ", s$Status, "</span>"),
          x = 0.5, y = 0.5, showarrow = FALSE,
          font = list(size=22, color="#ffffff", family="Space Grotesk, sans-serif"),
          xref = "paper", yref = "paper"
        ))
      ) |> config(displayModeBar = FALSE)
  })
  
  output$student_recommendations <- renderUI({
    s <- student(); req(s)
    recs <- list()
    for (i in seq_along(SUBJECTS)) {
      sc <- s[[SUBJECTS[i]]]
      if (sc < 65)
        recs[[length(recs)+1]] <- list(color="#ef4444",
                                       text = paste0("Focus on improving ", SUBJECT_LABELS[i], " — currently at ", sc, "/100."))
      else if (sc < 75)
        recs[[length(recs)+1]] <- list(color="#f59e0b",
                                       text = paste0(SUBJECT_LABELS[i], " needs more practice to reach the next level."))
    }
    if (s$Attendance_Percentage < 80)
      recs[[length(recs)+1]] <- list(color="#f97316",
                                     text = paste0("Attendance is ", s$Attendance_Percentage, "% — attend more classes to improve grades."))
    if (s$Average >= 85)
      recs[[length(recs)+1]] <- list(color="#22c55e", text="Excellent performance! Keep up the outstanding academic work.")
    else if (s$Average >= 75)
      recs[[length(recs)+1]] <- list(color="#06b6d4", text="Good performance. A little more effort can push you to the top tier.")
    if (length(recs) == 0)
      recs[[1]] <- list(color="#22c55e", text="You're on track. Maintain your consistent academic performance!")
    
    items <- lapply(recs, function(r) {
      div(style="display:flex;align-items:flex-start;gap:12px;padding:12px;background:rgba(255,255,255,0.03);border-radius:12px;margin-bottom:10px;",
          div(style=paste0("width:8px;height:8px;border-radius:50%;background:",r$color,";margin-top:5px;flex-shrink:0;")),
          div(style="font-size:13px;color:#e2e8f0;line-height:1.6;", r$text)
      )
    })
    do.call(tagList, items)
  })
  
  # ════════════════════════════════════════════════════════════════════════════
  #  SUBJECT PERFORMANCE TAB  (filtered)
  # ════════════════════════════════════════════════════════════════════════════
  
  output$student_all_subjects_chart <- renderPlotly({
    s  <- student(); req(s)
    sel <- sel_subjects("subj_filter_perf")
    if (length(sel$subj) == 0) {
      return(plotly_empty() |>
               layout(title = list(text="No subjects selected", font=list(color="#94a3b8")),
                      paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)"))
    }
    scores     <- sapply(sel$subj, function(x) s[[x]])
    bar_colors <- sapply(scores, function(sc)
      if (sc >= 85) "rgba(34,197,94,0.75)" else if (sc >= 70) "rgba(6,182,212,0.75)"
      else if (sc >= 60) "rgba(245,158,11,0.75)" else "rgba(239,68,68,0.75)")
    plot_ly(x = sel$labels, y = scores, type = "bar",
            marker  = list(color = bar_colors, line = list(color="rgba(0,0,0,0)", width=0)),
            text    = scores, textposition = "outside",
            hovertemplate = "<b>%{x}</b><br>Score: %{y}<extra></extra>") |>
      layout(
        xaxis = list(title="", color="#94a3b8", gridcolor="rgba(255,255,255,0.06)"),
        yaxis = list(title="Score", range=c(0,115), color="#94a3b8", gridcolor="rgba(255,255,255,0.06)"),
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
        font=list(color="#94a3b8"), margin=list(l=40,r=20,t=20,b=40), showlegend=FALSE
      ) |> config(displayModeBar=FALSE)
  })
  
  output$student_radar_chart <- renderPlotly({
    s   <- student(); req(s)
    sel <- sel_subjects("subj_filter_perf")
    if (length(sel$subj) < 3) {
      return(plotly_empty() |>
               layout(title=list(text="Select at least 3 subjects for radar", font=list(color="#94a3b8")),
                      paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)"))
    }
    scores     <- sapply(sel$subj, function(x) s[[x]])
    class_avgs <- sapply(sel$subj, function(x) mean(ALL_DATA[[x]], na.rm=TRUE))
    
    plot_ly(type="scatterpolar", fill="toself") |>
      add_trace(r=c(scores, scores[1]), theta=c(sel$labels, sel$labels[1]),
                name="You", fillcolor="rgba(34,197,94,0.2)",
                line=list(color="#22c55e", width=2)) |>
      add_trace(r=c(class_avgs, class_avgs[1]), theta=c(sel$labels, sel$labels[1]),
                name="Class Avg", fillcolor="rgba(6,182,212,0.1)",
                line=list(color="#06b6d4", width=2, dash="dash")) |>
      layout(
        polar = list(
          radialaxis  = list(visible=TRUE, range=c(0,100), color="#94a3b8", gridcolor="rgba(255,255,255,0.1)"),
          angularaxis = list(color="#cbd5e1")
        ),
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
        font=list(color="#94a3b8"),
        legend=list(bgcolor="rgba(0,0,0,0)", font=list(color="#cbd5e1")),
        margin=list(l=40,r=40,t=20,b=40)
      ) |> config(displayModeBar=FALSE)
  })
  
  # ════════════════════════════════════════════════════════════════════════════
  #  CLASS COMPARISON TAB  (filtered)
  # ════════════════════════════════════════════════════════════════════════════
  
  output$class_standing_info <- renderUI({
    s  <- student(); req(s)
    rc <- ranked_class(); req(rc)
    rank      <- which(rc$Student_ID == s$Student_ID)[1]
    total     <- nrow(rc)
    pct       <- round((1 - rank / total) * 100)
    class_avg <- round(mean(ALL_DATA$Average, na.rm=TRUE), 1)
    
    div(style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:16px;",
        stat_mini_card("Class Rank",  paste0("#", rank),        paste0("out of ", total, " students"), "#06b6d4"),
        stat_mini_card("Percentile",  paste0("Top ", pct, "%"), "better than peers",                   "#7c3aed"),
        stat_mini_card("Your Avg",    paste0(round(s$Average,1)),"score",                              "#22c55e"),
        stat_mini_card("Class Avg",   paste0(class_avg),         "score",                              "#f59e0b")
    )
  })
  
  output$student_comparison_chart <- renderPlotly({
    s   <- student(); req(s)
    sel <- sel_subjects("subj_filter_comp")
    if (length(sel$subj) == 0) {
      return(plotly_empty() |>
               layout(title=list(text="No subjects selected", font=list(color="#94a3b8")),
                      paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)"))
    }
    scores     <- sapply(sel$subj, function(x) s[[x]])
    class_avgs <- sapply(sel$subj, function(x) mean(ALL_DATA[[x]], na.rm=TRUE))
    
    plot_ly() |>
      add_bars(x=sel$labels, y=scores,
               name="You", marker=list(color="rgba(34,197,94,0.75)"),
               hovertemplate="<b>%{x}</b><br>You: %{y}<extra></extra>") |>
      add_bars(x=sel$labels, y=round(class_avgs,1),
               name="Class Avg", marker=list(color="rgba(6,182,212,0.5)"),
               hovertemplate="<b>%{x}</b><br>Class Avg: %{y:.1f}<extra></extra>") |>
      layout(
        barmode="group",
        xaxis=list(title="", color="#94a3b8", gridcolor="rgba(255,255,255,0.06)"),
        yaxis=list(title="Score", range=c(0,110), color="#94a3b8", gridcolor="rgba(255,255,255,0.06)"),
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
        font=list(color="#94a3b8"),
        legend=list(bgcolor="rgba(0,0,0,0)", font=list(color="#cbd5e1")),
        margin=list(l=40,r=20,t=20,b=40)
      ) |> config(displayModeBar=FALSE)
  })
  
  # ════════════════════════════════════════════════════════════════════════════
  #  CLASS RANKINGS TAB  (filtered)
  # ════════════════════════════════════════════════════════════════════════════
  
  # Recompute averages based on selected subjects only
  filtered_ranked <- reactive({
    rc  <- ranked_class(); req(rc)
    sel <- sel_subjects("subj_filter_rank")
    if (length(sel$subj) == 0) return(NULL)
    
    # Recompute average over selected subjects
    rc$Filtered_Avg <- rowMeans(rc[, sel$subj, drop=FALSE], na.rm=TRUE)
    rc[order(-rc$Filtered_Avg), ]
  })
  
  output$top_performers_table <- renderDT({
    s  <- student(); req(s)
    rc <- filtered_ranked(); req(rc)
    sel <- sel_subjects("subj_filter_rank")
    
    top5 <- head(rc, 5)
    top5$Rank <- paste0("#", seq_len(nrow(top5)))
    df <- top5[, c("Rank","Student_Name","Filtered_Avg","Grade","Attendance_Percentage")]
    names(df) <- c("Rank","Name","Avg (Filtered)","Grade","Attend%")
    df[["Avg (Filtered)"]] <- round(df[["Avg (Filtered)"]], 1)
    
    datatable(df, options=list(dom="t", paging=FALSE, searching=FALSE),
              rownames=FALSE, class="compact") |>
      formatStyle("Avg (Filtered)",
                  color=styleInterval(c(70,85), c("#fcd34d","#67e8f9","#4ade80")),
                  fontWeight="bold") |>
      formatStyle("Grade",
                  color=styleEqual(c("A","B","C","D"), c("#4ade80","#67e8f9","#fcd34d","#fca5a5")),
                  fontWeight="bold")
  }, server=FALSE)
  
  output$score_distribution_chart <- renderPlotly({
    rc  <- filtered_ranked()
    if (is.null(rc)) {
      return(plotly_empty() |>
               layout(title=list(text="No subjects selected", font=list(color="#94a3b8")),
                      paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)"))
    }
    avgs <- rc$Filtered_Avg
    bins <- c(sum(avgs<60,na.rm=T), sum(avgs>=60&avgs<70,na.rm=T),
              sum(avgs>=70&avgs<80,na.rm=T), sum(avgs>=80&avgs<90,na.rm=T),
              sum(avgs>=90,na.rm=T))
    bin_labels <- c("<60","60-70","70-80","80-90","90+")
    bin_colors <- c("rgba(239,68,68,0.75)","rgba(245,158,11,0.75)",
                    "rgba(6,182,212,0.75)","rgba(124,58,237,0.75)","rgba(34,197,94,0.75)")
    plot_ly(x=bin_labels, y=bins, type="bar",
            marker=list(color=bin_colors),
            text=bins, textposition="outside",
            hovertemplate="<b>%{x}</b><br>Students: %{y}<extra></extra>") |>
      layout(
        xaxis=list(title="Score Range", color="#94a3b8", gridcolor="rgba(255,255,255,0.06)"),
        yaxis=list(title="Students", color="#94a3b8", gridcolor="rgba(255,255,255,0.06)"),
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
        font=list(color="#94a3b8"), margin=list(l=40,r=20,t=20,b=40), showlegend=FALSE
      ) |> config(displayModeBar=FALSE)
  })
  
  output$full_rankings_table <- renderDT({
    s  <- student(); req(s)
    rc <- filtered_ranked(); req(rc)
    sel <- sel_subjects("subj_filter_rank")
    
    df <- rc[, c("Student_Name","Student_ID", sel$subj, "Grade","Attendance_Percentage","Filtered_Avg")]
    df$Rank <- seq_len(nrow(df))
    df$Filtered_Avg <- round(df$Filtered_Avg, 1)
    
    col_names <- c("Name","ID", sel$labels, "Grade","Attend%","Avg (Filtered)","Rank")
    df <- df[, c("Rank","Student_Name","Student_ID", sel$subj, "Grade","Attendance_Percentage","Filtered_Avg")]
    names(df) <- c("Rank","Name","ID", sel$labels, "Grade","Attend%","Avg")
    
    datatable(df,
              options=list(dom="ftp", pageLength=20, searching=TRUE,
                           columnDefs=list(list(className="dt-center", targets="_all"))),
              rownames=FALSE, class="compact hover") |>
      formatStyle("Avg",
                  color=styleInterval(c(60,70,85), c("#fca5a5","#fcd34d","#67e8f9","#4ade80")),
                  fontWeight="bold") |>
      formatStyle("Grade",
                  color=styleEqual(c("A","B","C","D"), c("#4ade80","#67e8f9","#fcd34d","#fca5a5")),
                  fontWeight="bold") |>
      formatStyle("Name",
                  target="row",
                  backgroundColor=styleEqual(s$Student_Name, "rgba(34,197,94,0.12)"),
                  color          =styleEqual(s$Student_Name, "#4ade80"))
  }, server=FALSE)
  
}