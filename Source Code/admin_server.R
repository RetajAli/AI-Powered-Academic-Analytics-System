# ═══════════════════════════════════════════════════════════════════════════════
# ADMIN / DEAN DASHBOARD — Full Server Code with Print Reports
# ═══════════════════════════════════════════════════════════════════════════════
#
# SETUP REQUIREMENTS:
#   1. Add library(shinyjs) to global.R or top of server.R
#   2. Add useShinyjs() inside dashboardBody() in ui.R
#   3. Add these 5 actionButtons in their matching tabItem in ui.R:
#
#      Doctor Performance tab:
#        actionButton("print_doctor",   "Print Report", icon=icon("print"), class="btn-print")
#      Subject Analytics tab:
#        actionButton("print_subject",  "Print Report", icon=icon("print"), class="btn-print")
#      GPA Trend tab:
#        actionButton("print_gpa",      "Print Report", icon=icon("print"), class="btn-print")
#      At-Risk Students tab:
#        actionButton("print_risk",     "Print Report", icon=icon("print"), class="btn-print")
#      College Rankings tab:
#        actionButton("print_rankings", "Print Report", icon=icon("print"), class="btn-print")
#
# ═══════════════════════════════════════════════════════════════════════════════


# ── Initialize data reactive ──────────────────────────────────────────────────
data <- reactiveVal(load_student_data_app())

# ── Refresh data on button click ──────────────────────────────────────────────
observeEvent(input$admin_refresh_btn, {
  data(load_student_data_app())
  showNotification("Dean dashboard data updated successfully", type = "message")
}, ignoreInit = TRUE)


# ── GPA conversion: score/100 * 4.0 scale ────────────────────────────────────
to_gpa4 <- function(score) round((score / 100) * 4.0, 2)

# ── Subject vectors ───────────────────────────────────────────────────────────
admin_subjects <- c("Math", "Programming", "Database", "Statistics", "Software_Engineering")
admin_labels   <- c("Mathematics", "Programming", "Database", "Statistics", "Soft. Engineering")
subject_colors <- c("#6366f1", "#06b6d4", "#22c55e", "#f59e0b", "#f43f5e")


# ═══════════════════════════════════════════════════════════════════════════════
# 1. COLLEGE OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════

output$admin_total_students_box <- renderValueBox({
  df <- data()
  valueBox(nrow(df), "Total Students", icon = icon("users"), color = "blue")
})

output$admin_total_doctors_box <- renderValueBox({
  valueBox(3, "Faculty Doctors", icon = icon("chalkboard-user"), color = "purple")
})

output$admin_total_courses_box <- renderValueBox({
  df  <- data()
  val <- if ("Course" %in% names(df)) length(unique(df$Course)) else 2
  valueBox(val, "Active Courses", icon = icon("book-open"), color = "navy")
})

output$admin_pass_rate_box <- renderValueBox({
  df  <- data()
  val <- if (nrow(df) > 0 && "Status" %in% names(df))
    paste0(round(mean(df$Status != "Fail", na.rm = TRUE) * 100, 1), "%")
  else "N/A"
  valueBox(val, "Pass Rate", icon = icon("circle-check"), color = "green")
})

output$admin_overall_gpa_box <- renderValueBox({
  df  <- data()
  val <- if (nrow(df) > 0) {
    gpa <- to_gpa4(mean(df$Average, na.rm = TRUE))
    paste0(gpa, " / 4.0")
  } else "N/A"
  valueBox(val, "College GPA (4.0 Scale)", icon = icon("graduation-cap"), color = "yellow")
})

output$admin_high_risk_box <- renderValueBox({
  df  <- data()
  val <- if (nrow(df) > 0 && "Attendance_Percentage" %in% names(df))
    sum(df$Attendance_Percentage < 60, na.rm = TRUE)
  else "N/A"
  valueBox(val, "High-Risk Students", icon = icon("triangle-exclamation"), color = "red")
})

output$admin_avg_attendance_box <- renderValueBox({
  df  <- data()
  val <- if (nrow(df) > 0)
    paste0(round(mean(df$Attendance_Percentage, na.rm = TRUE), 1), "%")
  else "N/A"
  valueBox(val, "Avg Attendance", icon = icon("calendar-check"), color = "green")
})

output$admin_college_health_box <- renderValueBox({
  df  <- data()
  val <- if (nrow(df) > 0) {
    gpa_score <- mean(df$Average, na.rm = TRUE) * 0.50
    att_score <- mean(df$Attendance_Percentage, na.rm = TRUE) * 0.30
    act_score <- if ("Questions_Asked" %in% names(df))
      (mean(df$Questions_Asked, na.rm = TRUE) / 6) * 100 * 0.20 else 0
    round(gpa_score + att_score + act_score, 1)
  } else "N/A"
  color <- if (is.numeric(val) && val >= 75) "green"
  else if (is.numeric(val) && val >= 60) "yellow" else "red"
  valueBox(val, "College Health Score", icon = icon("heart-pulse"), color = color)
})

output$admin_health_score_num <- renderText({
  df <- data()
  if (nrow(df) == 0) return("--")
  gpa_score <- mean(df$Average, na.rm = TRUE) * 0.50
  att_score <- mean(df$Attendance_Percentage, na.rm = TRUE) * 0.30
  act_score <- if ("Questions_Asked" %in% names(df))
    (mean(df$Questions_Asked, na.rm = TRUE) / 6) * 100 * 0.20 else 0
  round(gpa_score + att_score + act_score, 1)
})

output$admin_course_avg_chart <- renderPlotly({
  df <- data()
  if (!"Course" %in% names(df) || nrow(df) == 0) return(plotly_empty())
  chart_df <- df %>%
    group_by(Course) %>%
    summarise(Avg = round(mean(Average, na.rm = TRUE), 1), .groups = "drop")
  plot_ly(chart_df, x = ~Course, y = ~Avg, type = "bar",
          marker = list(color = c("#6366f1", "#06b6d4")),
          text = ~paste0(Avg, "%"), textposition = "outside") %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb"),
           yaxis = list(title = "Average Score", range = c(0, 110),
                        gridcolor = "rgba(255,255,255,0.06)"),
           xaxis = list(title = ""))
})

output$admin_grade_pie <- renderPlotly({
  df <- data()
  if (nrow(df) == 0 || !"Grade" %in% names(df)) return(plotly_empty())
  counts <- as.data.frame(table(df$Grade))
  plot_ly(counts, labels = ~Var1, values = ~Freq, type = "pie",
          marker = list(colors = c("#6366f1", "#22c55e", "#f59e0b", "#f43f5e", "#06b6d4"))) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", font = list(color = "#e5e7eb"))
})

output$admin_summary_table <- renderTable({
  df <- data()
  gpa_val <- if (nrow(df) > 0) paste0(to_gpa4(mean(df$Average, na.rm = TRUE)), " / 4.0") else "N/A"
  data.frame(
    Metric = c("Total Students", "College GPA (4.0)", "Pass Rate",
               "Avg Attendance", "High-Risk Students", "Active Courses"),
    Value  = c(
      nrow(df),
      gpa_val,
      if (nrow(df) > 0 && "Status" %in% names(df))
        paste0(round(mean(df$Status != "Fail") * 100, 1), "%") else "N/A",
      if (nrow(df) > 0)
        paste0(round(mean(df$Attendance_Percentage, na.rm = TRUE), 1), "%") else "N/A",
      if (nrow(df) > 0) sum(df$Attendance_Percentage < 60, na.rm = TRUE) else "N/A",
      if ("Course" %in% names(df)) length(unique(df$Course)) else 2
    )
  )
}, striped = FALSE, hover = FALSE, bordered = TRUE, align = "l", na = "N/A")


# ═══════════════════════════════════════════════════════════════════════════════
# 2. DOCTOR PERFORMANCE
# ═══════════════════════════════════════════════════════════════════════════════

admin_doctor_summary <- reactive({
  df <- data()
  if (!"Course" %in% names(df) || nrow(df) == 0) return(data.frame())
  df %>%
    group_by(Course) %>%
    summarise(
      Students       = n(),
      Avg_Score      = round(mean(Average, na.rm = TRUE), 1),
      GPA_4          = to_gpa4(mean(Average, na.rm = TRUE)),
      Avg_Attendance = round(mean(Attendance_Percentage, na.rm = TRUE), 1),
      Pass_Rate      = round(mean(Status != "Fail", na.rm = TRUE) * 100, 1),
      Avg_Questions  = round(mean(Questions_Asked, na.rm = TRUE), 1),
      .groups = "drop"
    ) %>%
    mutate(
      Doctor = case_when(
        Course == "Advanced Statistics" ~ "Dr. Mohamed Fathy",
        Course == "Linear Algebra"      ~ "Dr. Ahmed Salem",
        TRUE                            ~ "Dr. Sara Khalil"
      )
    )
})

output$admin_doctor_comparison_chart <- renderPlotly({
  df <- admin_doctor_summary()
  if (nrow(df) == 0) return(plotly_empty())
  plot_ly(df, x = ~Doctor, y = ~Avg_Score, type = "bar", name = "Avg Score (100)",
          marker = list(color = "#6366f1")) %>%
    add_trace(y = ~Avg_Attendance, name = "Avg Attendance %",
              marker = list(color = "#06b6d4")) %>%
    add_trace(y = ~Pass_Rate, name = "Pass Rate %",
              marker = list(color = "#22c55e")) %>%
    layout(barmode = "group",
           paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb"),
           yaxis = list(title = "Score / %", range = c(0, 110),
                        gridcolor = "rgba(255,255,255,0.06)"),
           xaxis = list(title = ""),
           legend = list(orientation = "h", y = -0.2))
})

output$admin_doctor_cards <- renderUI({
  df <- admin_doctor_summary()
  if (nrow(df) == 0) return(tags$p("No data available", style = "color:#94a3b8;"))
  cards <- lapply(seq_len(nrow(df)), function(i) {
    row <- df[i, ]
    tags$div(class = "doctor-card",
             tags$p(style = "color:#e2e8f0;font-weight:700;font-size:15px;margin:0 0 4px 0;",
                    icon("user-tie"), " ", row$Doctor),
             tags$p(style = "color:#6366f1;font-size:12px;margin:0 0 10px 0;",
                    icon("book"), " ", row$Course),
             tags$div(
               tags$span(class = "stat-chip chip-blue",   paste0(row$Students,       " Students")),
               tags$span(class = "stat-chip chip-green",  paste0(row$Avg_Score,      " Avg Score")),
               tags$span(class = "stat-chip chip-purple", paste0(row$GPA_4,          " GPA")),
               tags$span(class = "stat-chip chip-yellow", paste0(row$Avg_Attendance, "% Attend"))
             )
    )
  })
  do.call(tagList, cards)
})

output$admin_doctor_attendance_chart <- renderPlotly({
  df <- admin_doctor_summary()
  if (nrow(df) == 0) return(plotly_empty())
  plot_ly(df, x = ~Doctor, y = ~Avg_Attendance, type = "bar",
          marker = list(color = subject_colors[seq_len(nrow(df))]),
          text = ~paste0(Avg_Attendance, "%"), textposition = "outside") %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb"),
           yaxis = list(title = "Avg Attendance %", range = c(0, 110),
                        gridcolor = "rgba(255,255,255,0.06)"),
           xaxis = list(title = ""))
})

output$activity_pie_chart <- renderPlotly({
  df <- data()
  if (nrow(df) == 0 || !"Questions_Asked" %in% names(df)) return(plotly_empty())
  df <- df %>%
    mutate(Activity_Level = case_when(
      Questions_Asked >= 4 ~ "High",
      Questions_Asked >= 2 ~ "Medium",
      TRUE                 ~ "Low"
    ))
  counts <- as.data.frame(table(df$Activity_Level))
  plot_ly(counts, labels = ~Var1, values = ~Freq, type = "pie",
          marker = list(colors = c("High" = "#22c55e", "Medium" = "#f59e0b", "Low" = "#f43f5e"))) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", font = list(color = "#e5e7eb"),
           legend = list(orientation = "h", y = -0.1))
})

# ── Filter dropdowns ──────────────────────────────────────────────────────────
observe({
  df <- data()
  default_courses <- c("Advanced Statistics", "Linear Algebra")
  courses <- if ("Course" %in% names(df)) sort(unique(na.omit(as.character(df$Course)))) else character(0)
  courses <- unique(c(default_courses, courses))
  grades  <- c("F", "D", "C", "B", "A")
  course_choices <- c("All Courses" = "", setNames(courses, courses))
  grade_choices  <- c("All Grades"  = "", setNames(grades,  grades))
  updateSelectInput(session, "filter_doctor_course", choices = course_choices, selected = "")
  updateSelectInput(session, "filter_risk_course",   choices = course_choices, selected = "")
  updateSelectInput(session, "filter_top10_course",  choices = course_choices, selected = "")
  updateSelectInput(session, "filter_top10_grade",   choices = grade_choices,  selected = "")
  updateSelectInput(session, "filter_bot10_course",  choices = course_choices, selected = "")
  updateSelectInput(session, "filter_bot10_grade",   choices = grade_choices,  selected = "")
  updateSelectInput(session, "filter_rank_course",   choices = course_choices, selected = "")
  updateSelectInput(session, "filter_rank_grade",    choices = grade_choices,  selected = "")
  if (nrow(df) > 0 && "Average" %in% names(df)) {
    score_min <- floor(min(df$Average,   na.rm = TRUE))
    score_max <- ceiling(max(df$Average, na.rm = TRUE))
    updateSliderInput(session, "filter_rank_score", min = score_min, max = score_max,
                      value = c(score_min, score_max))
  }
})

# ── Reset buttons ─────────────────────────────────────────────────────────────
observeEvent(input$reset_risk_filters, {
  updateTextInput(session,   "filter_risk_search", value = "")
  updateSelectInput(session, "filter_risk_course", selected = "")
  updateSelectInput(session, "filter_risk_level",  selected = "")
  updateSelectInput(session, "filter_risk_status", selected = "")
})

observeEvent(input$reset_rank_filters, {
  updateTextInput(session,   "filter_rank_search",  value = "")
  updateSelectInput(session, "filter_rank_course",  selected = "")
  updateSelectInput(session, "filter_rank_grade",   selected = "")
  updateSelectInput(session, "filter_rank_status",  selected = "")
  df <- data()
  if (nrow(df) > 0)
    updateSliderInput(session, "filter_rank_score",
                      value = c(floor(min(df$Average, na.rm = TRUE)),
                                ceiling(max(df$Average, na.rm = TRUE))))
})

# ── Doctor table (filtered) ───────────────────────────────────────────────────
output$admin_doctor_table <- renderDT({
  df <- admin_doctor_summary()
  if (nrow(df) == 0) return(datatable(data.frame(Message = "No data"),
                                      options = list(dom = "t")))
  if (!is.null(input$filter_doctor_course) && input$filter_doctor_course != "")
    df <- df %>% filter(Course == input$filter_doctor_course)
  datatable(
    df %>% select(Doctor, Course, Students, Avg_Score, GPA_4, Avg_Attendance, Pass_Rate, Avg_Questions),
    options = list(pageLength = 10, dom = "tip", scrollX = TRUE),
    rownames = FALSE,
    colnames = c("Doctor", "Course", "Students", "Avg Score", "GPA (4.0)",
                 "Avg Attendance %", "Pass Rate %", "Avg Questions")
  )
})

output$doctor_table_count <- renderUI({
  df <- admin_doctor_summary()
  if (!is.null(input$filter_doctor_course) && input$filter_doctor_course != "")
    df <- df %>% filter(Course == input$filter_doctor_course)
  span(paste(nrow(df), "rows"))
})


# ═══════════════════════════════════════════════════════════════════════════════
# 3. SUBJECT ANALYTICS
# ═══════════════════════════════════════════════════════════════════════════════

admin_subject_avgs <- reactive({
  df <- data()
  if (nrow(df) == 0) return(data.frame())
  avgs <- sapply(admin_subjects, function(s) {
    if (s %in% names(df)) round(mean(df[[s]], na.rm = TRUE), 1) else NA
  })
  data.frame(Subject = admin_labels, Avg = avgs, stringsAsFactors = FALSE)
})

output$admin_best_subject_box <- renderValueBox({
  df <- admin_subject_avgs()
  if (nrow(df) == 0 || all(is.na(df$Avg)))
    return(valueBox("N/A", "Best Subject", icon = icon("star"), color = "green"))
  best <- df[which.max(df$Avg), ]
  valueBox(tags$span(style = "font-size:26px;line-height:1.2;white-space:normal;",
                     paste0(best$Subject, " ", best$Avg)),
           "Best Subject", icon = icon("star"), color = "green")
})

output$admin_worst_subject_box <- renderValueBox({
  df <- admin_subject_avgs()
  if (nrow(df) == 0 || all(is.na(df$Avg)))
    return(valueBox("N/A", "Needs Attention", icon = icon("circle-exclamation"), color = "red"))
  worst <- df[which.min(df$Avg), ]
  valueBox(tags$span(style = "font-size:26px;line-height:1.2;white-space:normal;",
                     paste0(worst$Subject, " ", worst$Avg)),
           "Needs Attention", icon = icon("circle-exclamation"), color = "red")
})

output$admin_avg_all_sub_box <- renderValueBox({
  df  <- admin_subject_avgs()
  val <- if (nrow(df) > 0) round(mean(df$Avg, na.rm = TRUE), 1) else "N/A"
  valueBox(val, "Overall Subject Avg", icon = icon("calculator"), color = "blue")
})

output$admin_subject_bar <- renderPlotly({
  df <- admin_subject_avgs()
  if (nrow(df) == 0) return(plotly_empty())
  plot_ly(df, x = ~Subject, y = ~Avg, type = "bar",
          marker = list(color = subject_colors),
          text = ~paste0(Avg, "%"), textposition = "outside") %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb"),
           yaxis = list(title = "Average Score", range = c(0, 115),
                        gridcolor = "rgba(255,255,255,0.06)"),
           xaxis = list(title = ""))
})

output$admin_subject_pass_pie <- renderPlotly({
  df_raw <- data()
  if (nrow(df_raw) == 0) return(plotly_empty())
  pass_rates <- sapply(admin_subjects, function(s) {
    if (s %in% names(df_raw)) round(mean(df_raw[[s]] >= 60, na.rm = TRUE) * 100, 1) else NA
  })
  pass_df <- data.frame(Subject = admin_labels, PassRate = pass_rates,
                        stringsAsFactors = FALSE) %>%
    filter(!is.na(PassRate)) %>%
    arrange(PassRate)
  plot_ly(pass_df, x = ~PassRate, y = ~Subject, type = "bar", orientation = "h",
          marker = list(color = subject_colors[match(pass_df$Subject, admin_labels)]),
          text = ~paste0(PassRate, "%"), textposition = "outside",
          hovertemplate = "<b>%{y}</b><br>Pass Rate: %{x}%<extra></extra>") %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb", size = 12),
           xaxis = list(title = "Pass Rate %", range = c(0, 110),
                        gridcolor = "rgba(255,255,255,0.06)"),
           yaxis = list(title = "", automargin = TRUE),
           showlegend = FALSE,
           margin = list(l = 120, r = 45, t = 15, b = 45)) %>%
    config(displayModeBar = FALSE)
})

output$admin_subject_box_plot <- renderPlotly({
  df <- data()
  if (nrow(df) == 0) return(plotly_empty())
  p <- plot_ly(type = "box")
  for (i in seq_along(admin_subjects)) {
    s <- admin_subjects[i]
    if (s %in% names(df)) {
      p <- add_trace(p, y = df[[s]], name = admin_labels[i],
                     marker = list(color = subject_colors[i]),
                     line   = list(color = subject_colors[i]))
    }
  }
  p %>% layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
               font = list(color = "#e5e7eb"),
               yaxis = list(title = "Score", range = c(0, 100),
                            gridcolor = "rgba(255,255,255,0.06)"),
               showlegend = TRUE)
})


# ═══════════════════════════════════════════════════════════════════════════════
# 4. GPA TREND
# ═══════════════════════════════════════════════════════════════════════════════

admin_gpa_trend <- reactive({
  df <- data()
  if (!all(c("Week", "Average") %in% names(df)) || nrow(df) == 0) return(data.frame())
  df %>%
    mutate(
      Week_Num = as.numeric(gsub("Week ", "", Week)),
      Semester = ifelse(Week_Num <= 7, "Semester 1", "Semester 2")
    ) %>%
    group_by(Semester) %>%
    summarise(
      Avg_Raw = round(mean(Average, na.rm = TRUE), 2),
      GPA_4   = to_gpa4(mean(Average, na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    arrange(Semester)
})

output$admin_gpa_peak_box <- renderValueBox({
  df  <- admin_gpa_trend()
  val <- if (nrow(df) > 0 && !all(is.na(df$GPA_4))) {
    pk <- df[which.max(df$GPA_4), ]
    paste0(pk$GPA_4, " / 4.0 (", pk$Semester, ")")
  } else "N/A"
  valueBox(val, "Peak GPA Semester", icon = icon("arrow-trend-up"), color = "green")
})

output$admin_gpa_low_box <- renderValueBox({
  df  <- admin_gpa_trend()
  val <- if (nrow(df) > 0 && !all(is.na(df$GPA_4))) {
    lw <- df[which.min(df$GPA_4), ]
    paste0(lw$GPA_4, " / 4.0 (", lw$Semester, ")")
  } else "N/A"
  valueBox(val, "Lowest GPA Semester", icon = icon("arrow-trend-down"), color = "red")
})

output$admin_gpa_delta_box <- renderValueBox({
  df  <- admin_gpa_trend()
  val <- if (nrow(df) >= 2) {
    delta <- round(df$GPA_4[nrow(df)] - df$GPA_4[1], 2)
    paste0(if (delta >= 0) "+" else "", delta, " pts (Sem 1 → Sem 2)")
  } else "N/A"
  color <- if (is.character(val) && val != "N/A" && grepl("^\\+", val)) "green" else "red"
  valueBox(val, "GPA Change Sem 1 → Sem 2", icon = icon("chart-line"), color = color)
})

output$admin_gpa_trend_chart <- renderPlotly({
  df <- admin_gpa_trend()
  if (nrow(df) == 0) return(plotly_empty())
  plot_ly(df, x = ~Semester, y = ~GPA_4, type = "bar",
          marker = list(color = c("#6366f1", "#06b6d4"),
                        line  = list(color = c("#818cf8", "#67e8f9"), width = 2)),
          text = ~paste0(Semester, "<br>GPA: ", GPA_4, " / 4.0<br>Avg Score: ", Avg_Raw, "%"),
          hoverinfo = "text",
          textposition = "outside",
          texttemplate = "%{y:.2f}") %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font  = list(color = "#e5e7eb"),
           xaxis = list(title = "", gridcolor = "rgba(255,255,255,0.06)"),
           yaxis = list(title = "GPA (4.0 Scale)", range = c(0, 4.5),
                        gridcolor = "rgba(255,255,255,0.06)"),
           shapes = list(
             list(type = "line", x0 = -0.5, x1 = 1.5, xref = "x",
                  y0 = 2.0, y1 = 2.0,
                  line = list(color = "#f43f5e", dash = "dot", width = 2))
           ),
           annotations = list(
             list(x = 0, y = 2.08, xref = "x", yref = "y",
                  text = "Min Pass GPA (2.0)", showarrow = FALSE,
                  font = list(color = "#f43f5e", size = 11))
           ))
})

output$admin_gpa_course_trend <- renderPlotly({
  df <- data()
  if (!all(c("Week", "Average", "Course") %in% names(df)) || nrow(df) == 0) return(plotly_empty())
  trend <- df %>%
    mutate(
      Week_Num = as.numeric(gsub("Week ", "", Week)),
      Semester = ifelse(Week_Num <= 7, "Semester 1", "Semester 2")
    ) %>%
    group_by(Semester, Course) %>%
    summarise(GPA_4 = to_gpa4(mean(Average, na.rm = TRUE)), .groups = "drop") %>%
    arrange(Semester)
  courses <- unique(trend$Course)
  colors  <- c("#6366f1", "#06b6d4")
  p       <- plot_ly(barmode = "group")
  for (i in seq_along(courses)) {
    sub <- trend %>% filter(Course == courses[i])
    p <- add_trace(p, data = sub, x = ~Semester, y = ~GPA_4,
                   name = courses[i], type = "bar",
                   marker       = list(color = colors[i]),
                   text         = ~paste0(round(GPA_4, 2), " / 4.0"),
                   textposition = "outside")
  }
  p %>% layout(barmode = "group",
               paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
               font  = list(color = "#e5e7eb"),
               xaxis = list(title = "", gridcolor = "rgba(255,255,255,0.06)"),
               yaxis = list(title = "GPA (4.0 Scale)", range = c(0, 4.5),
                            gridcolor = "rgba(255,255,255,0.06)"),
               legend = list(orientation = "h", y = -0.25))
})


# ═══════════════════════════════════════════════════════════════════════════════
# 5. AT-RISK STUDENTS
# ═══════════════════════════════════════════════════════════════════════════════

admin_risk_data <- reactive({
  df <- data()
  if (nrow(df) == 0) return(data.frame())
  df %>%
    mutate(
      GPA_4      = to_gpa4(Average),
      Risk_Level = case_when(
        Attendance_Percentage < 60 | Average < 50 ~ "High Risk",
        Attendance_Percentage < 75 | Average < 60 ~ "Medium Risk",
        TRUE ~ "Safe"
      )
    )
})

output$admin_high_risk_count_box <- renderValueBox({
  df  <- admin_risk_data()
  val <- if (nrow(df) > 0) sum(df$Risk_Level == "High Risk") else "N/A"
  valueBox(val, "High Risk", icon = icon("circle-xmark"), color = "red")
})

output$admin_medium_risk_count_box <- renderValueBox({
  df  <- admin_risk_data()
  val <- if (nrow(df) > 0) sum(df$Risk_Level == "Medium Risk") else "N/A"
  valueBox(val, "Medium Risk", icon = icon("circle-exclamation"), color = "yellow")
})

output$admin_failing_count_box <- renderValueBox({
  df  <- data()
  val <- if (nrow(df) > 0 && "Status" %in% names(df))
    sum(df$Status == "Fail", na.rm = TRUE) else "N/A"
  valueBox(val, "Failing Students", icon = icon("triangle-exclamation"), color = "red")
})

output$admin_low_attend_count_box <- renderValueBox({
  df  <- data()
  val <- if (nrow(df) > 0) sum(df$Attendance_Percentage < 75, na.rm = TRUE) else "N/A"
  valueBox(val, "Low Attendance < 75%", icon = icon("calendar-xmark"), color = "maroon")
})

output$admin_risk_pie <- renderPlotly({
  df <- admin_risk_data()
  if (nrow(df) == 0) return(plotly_empty())
  counts <- as.data.frame(table(df$Risk_Level))
  plot_ly(counts, labels = ~Var1, values = ~Freq, type = "pie",
          marker = list(colors = c("#f43f5e", "#f59e0b", "#22c55e"))) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", font = list(color = "#e5e7eb"))
})

output$admin_risk_by_course <- renderPlotly({
  df <- admin_risk_data()
  if (!"Course" %in% names(df) || nrow(df) == 0) return(plotly_empty())
  summary_df <- df %>%
    group_by(Course, Risk_Level) %>%
    summarise(Count = n(), .groups = "drop")
  plot_ly(summary_df, x = ~Course, y = ~Count, color = ~Risk_Level, type = "bar",
          colors = c("High Risk" = "#f43f5e", "Medium Risk" = "#f59e0b", "Safe" = "#22c55e")) %>%
    layout(barmode = "stack",
           paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb"),
           yaxis = list(title = "Students", gridcolor = "rgba(255,255,255,0.06)"),
           xaxis = list(title = ""))
})

# ── At-Risk table (filtered) ──────────────────────────────────────────────────
admin_risk_filtered <- reactive({
  df <- admin_risk_data()
  if (nrow(df) == 0) return(data.frame())
  df <- df %>% filter(Risk_Level != "Safe")
  if (!is.null(input$filter_risk_search) && nchar(trimws(input$filter_risk_search)) > 0) {
    q  <- tolower(trimws(input$filter_risk_search))
    df <- df %>% filter(grepl(q, tolower(Student_Name), fixed = TRUE) |
                          grepl(q, tolower(Student_ID),   fixed = TRUE))
  }
  if (!is.null(input$filter_risk_course) && input$filter_risk_course != "")
    df <- df %>% filter(Course == input$filter_risk_course)
  if (!is.null(input$filter_risk_level) && input$filter_risk_level != "")
    df <- df %>% filter(Risk_Level == input$filter_risk_level)
  if (!is.null(input$filter_risk_status) && input$filter_risk_status != "")
    df <- df %>% filter(Status == input$filter_risk_status)
  df %>% arrange(Average)
})

output$admin_risk_table <- renderDT({
  df <- admin_risk_filtered()
  if (nrow(df) == 0) return(datatable(data.frame(Message = "No matching students"),
                                      options = list(dom = "t")))
  show <- c("Student_ID", "Student_Name", "Course", "Average", "GPA_4",
            "Attendance_Percentage", "Status", "Risk_Level")
  show <- show[show %in% names(df)]
  datatable(df %>% select(all_of(show)),
            options = list(pageLength = 10, scrollX = TRUE, dom = "tip"),
            rownames = FALSE,
            colnames = c("ID", "Name", "Course", "Score", "GPA (4.0)",
                         "Attendance %", "Status", "Risk")[seq_along(show)])
})

output$risk_table_count <- renderUI({
  span(paste(nrow(admin_risk_filtered()), "students"))
})


# ═══════════════════════════════════════════════════════════════════════════════
# 6. COLLEGE RANKINGS
# ═══════════════════════════════════════════════════════════════════════════════

output$admin_score_hist <- renderPlotly({
  df <- data()
  if (nrow(df) == 0) return(plotly_empty())
  plot_ly(df, x = ~Average, type = "histogram", nbinsx = 20,
          marker = list(color = "#6366f1",
                        line  = list(color = "#818cf8", width = 1))) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb"),
           xaxis = list(title = "Average Score",  gridcolor = "rgba(255,255,255,0.06)"),
           yaxis = list(title = "Number of Students", gridcolor = "rgba(255,255,255,0.06)"))
})

output$admin_grade_bar <- renderPlotly({
  df <- data()
  if (nrow(df) == 0 || !"Grade" %in% names(df)) return(plotly_empty())
  counts <- as.data.frame(table(df$Grade)) %>% arrange(desc(Freq))
  plot_ly(counts, x = ~Var1, y = ~Freq, type = "bar",
          marker = list(color = subject_colors[seq_len(nrow(counts))])) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
           font = list(color = "#e5e7eb"),
           xaxis = list(title = "Grade"),
           yaxis = list(title = "Count", gridcolor = "rgba(255,255,255,0.06)"))
})

output$admin_top10_table <- renderDT({
  df <- data()
  if (nrow(df) == 0) return(datatable(data.frame(Message = "No data available"),
                                      options = list(dom = "t")))
  if (!is.null(input$filter_top10_course) && input$filter_top10_course != "")
    df <- df %>% filter(Course == input$filter_top10_course)
  if (!is.null(input$filter_top10_grade) && input$filter_top10_grade != "")
    df <- df %>% filter(Grade == input$filter_top10_grade)
  df <- df %>%
    mutate(GPA_4 = to_gpa4(Average)) %>%
    arrange(desc(Average)) %>% head(10) %>% mutate(Rank = row_number())
  cols <- c("Rank", "Student_Name", "Average", "GPA_4", "Grade", "Attendance_Percentage")
  cols <- cols[cols %in% names(df)]
  datatable(df %>% select(all_of(cols)),
            options = list(dom = "t"), rownames = FALSE,
            colnames = c("Rank", "Name", "Score", "GPA (4.0)", "Grade", "Attendance %")[seq_along(cols)])
})

output$admin_bottom10_table <- renderDT({
  df <- data()
  if (nrow(df) == 0) return(datatable(data.frame(Message = "No data available"),
                                      options = list(dom = "t")))
  if (!is.null(input$filter_bot10_course) && input$filter_bot10_course != "")
    df <- df %>% filter(Course == input$filter_bot10_course)
  if (!is.null(input$filter_bot10_grade) && input$filter_bot10_grade != "")
    df <- df %>% filter(Grade == input$filter_bot10_grade)
  df <- df %>%
    mutate(GPA_4 = to_gpa4(Average)) %>%
    arrange(Average) %>% head(10) %>% mutate(Rank = row_number())
  cols <- c("Rank", "Student_Name", "Average", "GPA_4", "Grade", "Attendance_Percentage")
  cols <- cols[cols %in% names(df)]
  datatable(df %>% select(all_of(cols)),
            options = list(dom = "t"), rownames = FALSE,
            colnames = c("Rank", "Name", "Score", "GPA (4.0)", "Grade", "Attendance %")[seq_along(cols)])
})

# ── Full rankings (filtered) ──────────────────────────────────────────────────
admin_rank_filtered <- reactive({
  df <- data()
  if (nrow(df) == 0) return(data.frame())
  df <- df %>% mutate(GPA_4 = to_gpa4(Average))
  if (!is.null(input$filter_rank_search) && nchar(trimws(input$filter_rank_search)) > 0) {
    q  <- tolower(trimws(input$filter_rank_search))
    df <- df %>% filter(grepl(q, tolower(Student_Name), fixed = TRUE) |
                          grepl(q, tolower(Student_ID),   fixed = TRUE))
  }
  if (!is.null(input$filter_rank_course) && input$filter_rank_course != "")
    df <- df %>% filter(Course == input$filter_rank_course)
  if (!is.null(input$filter_rank_grade) && input$filter_rank_grade != "")
    df <- df %>% filter(Grade == input$filter_rank_grade)
  if (!is.null(input$filter_rank_status) && input$filter_rank_status != "")
    df <- df %>% filter(Status == input$filter_rank_status)
  if (!is.null(input$filter_rank_score))
    df <- df %>% filter(Average >= input$filter_rank_score[1],
                        Average <= input$filter_rank_score[2])
  df %>% arrange(desc(Average)) %>% mutate(Rank = row_number())
})

output$admin_full_rankings_table <- renderDT({
  df <- admin_rank_filtered()
  if (nrow(df) == 0) return(datatable(data.frame(Message = "No matching students"),
                                      options = list(dom = "t")))
  cols <- c("Rank", "Student_ID", "Student_Name", "Course",
            "Average", "GPA_4", "Grade", "Status", "Attendance_Percentage")
  cols <- cols[cols %in% names(df)]
  datatable(df %>% select(all_of(cols)),
            options = list(pageLength = 20, scrollX = TRUE, dom = "tip"),
            rownames = FALSE,
            colnames = c("Rank", "ID", "Name", "Course", "Score",
                         "GPA (4.0)", "Grade", "Status", "Attendance %")[seq_along(cols)])
})

output$rank_table_count <- renderUI({
  span(paste(nrow(admin_rank_filtered()), "students"))
})


# ═══════════════════════════════════════════════════════════════════════════════
# PRINT REPORT — Shared Helpers
# ═══════════════════════════════════════════════════════════════════════════════

print_css <- "
<style>
  * { box-sizing: border-box; }
  body { font-family: 'Segoe UI', Arial, sans-serif; color: #1e293b; margin: 0; padding: 0; }

  .report-header {
    text-align: center;
    border-bottom: 3px solid #6366f1;
    padding-bottom: 14px;
    margin-bottom: 22px;
  }
  .report-header h2 {
    margin: 0 0 4px;
    color: #6366f1;
    font-size: 22px;
    letter-spacing: .5px;
  }
  .report-header p { margin: 0; color: #64748b; font-size: 13px; }

  .section-title {
    font-size: 14px;
    font-weight: 700;
    color: #6366f1;
    border-left: 4px solid #6366f1;
    padding-left: 9px;
    margin: 22px 0 9px;
    text-transform: uppercase;
    letter-spacing: .4px;
  }

  /* Stat cards row */
  .stat-row {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
    margin-bottom: 18px;
  }
  .stat-box {
    flex: 1;
    min-width: 110px;
    background: #f1f5f9;
    border-radius: 10px;
    padding: 10px 12px;
    text-align: center;
    border-top: 3px solid #6366f1;
  }
  .stat-box .val { font-size: 18px; font-weight: 700; color: #6366f1; line-height: 1.3; }
  .stat-box .lbl { font-size: 11px; color: #64748b; margin-top: 3px; }

  /* Table */
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12.5px;
    margin-bottom: 18px;
  }
  thead tr { background: #6366f1; color: #fff; }
  th { padding: 9px 11px; text-align: left; font-weight: 600; }
  td { padding: 7px 11px; border-bottom: 1px solid #e2e8f0; }
  tbody tr:nth-child(even) { background: #f8fafc; }
  tbody tr:hover { background: #eff6ff; }

  /* Risk badges */
  .badge-high   { background:#fee2e2; color:#dc2626; padding:2px 9px;
                  border-radius:12px; font-size:11px; font-weight:600; white-space:nowrap; }
  .badge-medium { background:#fef9c3; color:#b45309; padding:2px 9px;
                  border-radius:12px; font-size:11px; font-weight:600; white-space:nowrap; }
  .badge-safe   { background:#dcfce7; color:#16a34a; padding:2px 9px;
                  border-radius:12px; font-size:11px; font-weight:600; white-space:nowrap; }

  /* Grade badges */
  .badge-a { background:#dcfce7; color:#16a34a; padding:2px 9px; border-radius:12px;
             font-size:11px; font-weight:700; }
  .badge-b { background:#dbeafe; color:#2563eb; padding:2px 9px; border-radius:12px;
             font-size:11px; font-weight:700; }
  .badge-c { background:#fef9c3; color:#b45309; padding:2px 9px; border-radius:12px;
             font-size:11px; font-weight:700; }
  .badge-d { background:#ffedd5; color:#c2410c; padding:2px 9px; border-radius:12px;
             font-size:11px; font-weight:700; }
  .badge-f { background:#fee2e2; color:#dc2626; padding:2px 9px; border-radius:12px;
             font-size:11px; font-weight:700; }

  /* Footer */
  .footer {
    text-align: center;
    color: #94a3b8;
    font-size: 11px;
    border-top: 1px solid #e2e8f0;
    padding-top: 12px;
    margin-top: 26px;
  }

  @media print {
    .modal-footer, button, .shiny-notification,
    .btn-print-trigger { display: none !important; }
    .modal-dialog  { max-width: 100% !important; margin: 0 !important; }
    .modal-content { border: none !important; box-shadow: none !important; }
    body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  }
</style>
"

report_footer <- function() {
  paste0(
    '<div class="footer">',
    'Generated on ', format(Sys.time(), "%B %d, %Y at %H:%M"),
    '&nbsp;|&nbsp; College Academic Dashboard',
    '</div>'
  )
}

grade_badge <- function(g) {
  cls <- switch(toupper(trimws(g)),
                "A" = "badge-a", "B" = "badge-b", "C" = "badge-c",
                "D" = "badge-d", "F" = "badge-f", "badge-f")
  paste0('<span class="', cls, '">', g, '</span>')
}

show_print_modal <- function(title, body_html) {
  showModal(modalDialog(
    title     = NULL,
    size      = "l",
    easyClose = TRUE,
    footer    = tagList(
      actionButton("do_print_btn", "Print / Save as PDF",
                   icon  = icon("print"),
                   style = "background:#6366f1;color:#fff;border:none;
                            border-radius:7px;padding:7px 18px;
                            font-weight:600;cursor:pointer;"),
      modalButton("Close")
    ),
    HTML(paste0(
      print_css,
      '<div id="printable_report">',
      '<div class="report-header">',
      '  <h2>', title, '</h2>',
      '  <p>Academic Year Report &nbsp;|&nbsp; College Dashboard &nbsp;|&nbsp; ',
      format(Sys.Date(), "%B %Y"), '</p>',
      '</div>',
      body_html,
      report_footer(),
      '</div>'
    ))
  ))
}

# ── Single observer triggers window.print() ───────────────────────────────────
observeEvent(input$do_print_btn, {
  shinyjs::runjs("window.print();")
})


# ═══════════════════════════════════════════════════════════════════════════════
# PRINT REPORT — 1. Doctor Performance
# ═══════════════════════════════════════════════════════════════════════════════
observeEvent(input$print_doctor, {
  df <- admin_doctor_summary()

  stat_html <- if (nrow(df) > 0) {
    paste0(
      '<div class="stat-row">',
      '<div class="stat-box"><div class="val">', nrow(df), '</div>',
      '<div class="lbl">Doctors / Courses</div></div>',
      '<div class="stat-box"><div class="val">',
      round(mean(df$Avg_Score, na.rm = TRUE), 1), '</div>',
      '<div class="lbl">Avg Score (100)</div></div>',
      '<div class="stat-box"><div class="val">',
      round(mean(df$GPA_4, na.rm = TRUE), 2), ' / 4.0</div>',
      '<div class="lbl">Avg GPA</div></div>',
      '<div class="stat-box"><div class="val">',
      round(mean(df$Avg_Attendance, na.rm = TRUE), 1), '%</div>',
      '<div class="lbl">Avg Attendance</div></div>',
      '<div class="stat-box"><div class="val">',
      round(mean(df$Pass_Rate, na.rm = TRUE), 1), '%</div>',
      '<div class="lbl">Avg Pass Rate</div></div>',
      '<div class="stat-box"><div class="val">',
      round(mean(df$Avg_Questions, na.rm = TRUE), 1), '</div>',
      '<div class="lbl">Avg Questions</div></div>',
      '</div>'
    )
  } else ""

  rows_html <- if (nrow(df) > 0) {
    paste(apply(df, 1, function(r) {
      paste0(
        '<tr>',
        '<td>', r["Doctor"],         '</td>',
        '<td>', r["Course"],         '</td>',
        '<td>', r["Students"],       '</td>',
        '<td>', r["Avg_Score"],      '</td>',
        '<td>', r["GPA_4"], ' / 4.0','</td>',
        '<td>', r["Avg_Attendance"], '%</td>',
        '<td>', r["Pass_Rate"],      '%</td>',
        '<td>', r["Avg_Questions"],  '</td>',
        '</tr>'
      )
    }), collapse = "")
  } else '<tr><td colspan="8">No data available</td></tr>'

  tbl_html <- paste0(
    '<div class="section-title">Doctor Performance Summary</div>',
    '<table><thead><tr>',
    '<th>Doctor</th><th>Course</th><th>Students</th>',
    '<th>Avg Score</th><th>GPA (4.0)</th>',
    '<th>Avg Attendance %</th><th>Pass Rate %</th><th>Avg Questions</th>',
    '</tr></thead><tbody>', rows_html, '</tbody></table>'
  )

  show_print_modal("Doctor Performance Report", paste0(stat_html, tbl_html))
})


# ═══════════════════════════════════════════════════════════════════════════════
# PRINT REPORT — 2. Subject Analytics
# ═══════════════════════════════════════════════════════════════════════════════
observeEvent(input$print_subject, {
  df_raw  <- data()
  df_avgs <- admin_subject_avgs()

  stat_html <- if (nrow(df_avgs) > 0 && !all(is.na(df_avgs$Avg))) {
    best    <- df_avgs[which.max(df_avgs$Avg), ]
    worst   <- df_avgs[which.min(df_avgs$Avg), ]
    overall <- round(mean(df_avgs$Avg, na.rm = TRUE), 1)
    paste0(
      '<div class="stat-row">',
      '<div class="stat-box"><div class="val">', overall, '</div>',
      '<div class="lbl">Overall Avg Score</div></div>',
      '<div class="stat-box"><div class="val">', best$Subject, '</div>',
      '<div class="lbl">Best Subject</div></div>',
      '<div class="stat-box"><div class="val">', best$Avg, '%</div>',
      '<div class="lbl">Best Avg Score</div></div>',
      '<div class="stat-box"><div class="val">', worst$Subject, '</div>',
      '<div class="lbl">Needs Attention</div></div>',
      '<div class="stat-box"><div class="val">', worst$Avg, '%</div>',
      '<div class="lbl">Lowest Avg Score</div></div>',
      '</div>'
    )
  } else ""

  avg_rows <- if (nrow(df_avgs) > 0) {
    paste(apply(df_avgs, 1, function(r)
      paste0('<tr><td>', r["Subject"], '</td><td>', r["Avg"], '%</td></tr>')
    ), collapse = "")
  } else '<tr><td colspan="2">No data</td></tr>'

  avg_tbl <- paste0(
    '<div class="section-title">Average Score per Subject</div>',
    '<table><thead><tr><th>Subject</th><th>Average Score</th></tr></thead>',
    '<tbody>', avg_rows, '</tbody></table>'
  )

  pass_tbl <- if (nrow(df_raw) > 0) {
    pass_rates <- sapply(admin_subjects, function(s) {
      if (s %in% names(df_raw)) round(mean(df_raw[[s]] >= 60, na.rm = TRUE) * 100, 1) else NA
    })
    pass_df <- data.frame(Subject = admin_labels, PassRate = pass_rates,
                          stringsAsFactors = FALSE)
    pass_rows <- paste(apply(pass_df, 1, function(r)
      paste0('<tr><td>', r["Subject"], '</td><td>', r["PassRate"], '%</td></tr>')
    ), collapse = "")
    paste0(
      '<div class="section-title">Pass Rate per Subject</div>',
      '<table><thead><tr><th>Subject</th><th>Pass Rate (%)</th></tr></thead>',
      '<tbody>', pass_rows, '</tbody></table>'
    )
  } else ""

  show_print_modal("Subject Analytics Report", paste0(stat_html, avg_tbl, pass_tbl))
})


# ═══════════════════════════════════════════════════════════════════════════════
# PRINT REPORT — 3. GPA Trend
# ═══════════════════════════════════════════════════════════════════════════════
observeEvent(input$print_gpa, {
  df     <- data()
  df_gpa <- admin_gpa_trend()

  stat_html <- if (nrow(df_gpa) >= 2) {
    peak  <- df_gpa[which.max(df_gpa$GPA_4), ]
    low   <- df_gpa[which.min(df_gpa$GPA_4), ]
    delta <- round(df_gpa$GPA_4[nrow(df_gpa)] - df_gpa$GPA_4[1], 2)
    delta_str <- paste0(if (delta >= 0) "+" else "", delta)
    paste0(
      '<div class="stat-row">',
      '<div class="stat-box"><div class="val">', peak$GPA_4, ' / 4.0</div>',
      '<div class="lbl">Peak GPA (', peak$Semester, ')</div></div>',
      '<div class="stat-box"><div class="val">', low$GPA_4, ' / 4.0</div>',
      '<div class="lbl">Lowest GPA (', low$Semester, ')</div></div>',
      '<div class="stat-box"><div class="val">', delta_str, ' pts</div>',
      '<div class="lbl">GPA Change Sem 1 → 2</div></div>',
      '</div>'
    )
  } else ""

  sem_rows <- if (nrow(df_gpa) > 0) {
    paste(apply(df_gpa, 1, function(r)
      paste0('<tr><td>', r["Semester"], '</td><td>', r["GPA_4"],
             ' / 4.0</td><td>', r["Avg_Raw"], '%</td></tr>')
    ), collapse = "")
  } else '<tr><td colspan="3">No data</td></tr>'

  sem_tbl <- paste0(
    '<div class="section-title">GPA by Semester (4.0 Scale)</div>',
    '<table><thead><tr>',
    '<th>Semester</th><th>GPA (4.0)</th><th>Avg Raw Score</th>',
    '</tr></thead><tbody>', sem_rows, '</tbody></table>'
  )

  course_tbl <- if (nrow(df) > 0 && all(c("Week", "Average", "Course") %in% names(df))) {
    trend <- df %>%
      mutate(Week_Num = as.numeric(gsub("Week ", "", Week)),
             Semester = ifelse(Week_Num <= 7, "Semester 1", "Semester 2")) %>%
      group_by(Semester, Course) %>%
      summarise(GPA_4   = to_gpa4(mean(Average, na.rm = TRUE)),
                Avg_Raw = round(mean(Average, na.rm = TRUE), 1),
                .groups = "drop") %>%
      arrange(Semester, Course)
    c_rows <- paste(apply(trend, 1, function(r)
      paste0('<tr><td>', r["Semester"], '</td><td>', r["Course"],
             '</td><td>', r["GPA_4"], ' / 4.0</td><td>', r["Avg_Raw"], '%</td></tr>')
    ), collapse = "")
    paste0(
      '<div class="section-title">GPA by Course &amp; Semester</div>',
      '<table><thead><tr>',
      '<th>Semester</th><th>Course</th><th>GPA (4.0)</th><th>Avg Raw Score</th>',
      '</tr></thead><tbody>', c_rows, '</tbody></table>'
    )
  } else ""

  show_print_modal("GPA Trend Report", paste0(stat_html, sem_tbl, course_tbl))
})


# ═══════════════════════════════════════════════════════════════════════════════
# PRINT REPORT — 4. At-Risk Students
# ═══════════════════════════════════════════════════════════════════════════════
observeEvent(input$print_risk, {
  df        <- admin_risk_data()
  risk_only <- if (nrow(df) > 0) df %>% filter(Risk_Level != "Safe") %>% arrange(Average) else df

  stat_html <- if (nrow(df) > 0) {
    paste0(
      '<div class="stat-row">',
      '<div class="stat-box"><div class="val">', nrow(df), '</div>',
      '<div class="lbl">Total Students</div></div>',
      '<div class="stat-box"><div class="val">',
      sum(df$Risk_Level == "High Risk",   na.rm = TRUE), '</div>',
      '<div class="lbl">High Risk</div></div>',
      '<div class="stat-box"><div class="val">',
      sum(df$Risk_Level == "Medium Risk", na.rm = TRUE), '</div>',
      '<div class="lbl">Medium Risk</div></div>',
      '<div class="stat-box"><div class="val">',
      sum(df$Risk_Level == "Safe",        na.rm = TRUE), '</div>',
      '<div class="lbl">Safe</div></div>',
      '<div class="stat-box"><div class="val">',
      if ("Status" %in% names(df)) sum(df$Status == "Fail", na.rm = TRUE) else "N/A",
      '</div><div class="lbl">Failing</div></div>',
      '<div class="stat-box"><div class="val">',
      sum(df$Attendance_Percentage < 75, na.rm = TRUE), '</div>',
      '<div class="lbl">Low Attendance</div></div>',
      '</div>'
    )
  } else ""

  tbl_html <- if (nrow(risk_only) > 0) {
    rows <- paste(apply(risk_only, 1, function(r) {
      badge <- switch(r["Risk_Level"],
        "High Risk"   = paste0('<span class="badge-high">',   r["Risk_Level"], '</span>'),
        "Medium Risk" = paste0('<span class="badge-medium">', r["Risk_Level"], '</span>'),
        paste0('<span class="badge-safe">',  r["Risk_Level"], '</span>')
      )
      paste0(
        '<tr>',
        '<td>', r["Student_ID"],            '</td>',
        '<td>', r["Student_Name"],          '</td>',
        '<td>', r["Course"],                '</td>',
        '<td>', r["Average"],               '</td>',
        '<td>', r["GPA_4"], ' / 4.0',       '</td>',
        '<td>', r["Attendance_Percentage"], '%</td>',
        '<td>', r["Status"],                '</td>',
        '<td>', badge,                      '</td>',
        '</tr>'
      )
    }), collapse = "")
    paste0(
      '<div class="section-title">At-Risk Students (High &amp; Medium Risk)</div>',
      '<table><thead><tr>',
      '<th>ID</th><th>Name</th><th>Course</th><th>Score</th>',
      '<th>GPA (4.0)</th><th>Attendance %</th><th>Status</th><th>Risk Level</th>',
      '</tr></thead><tbody>', rows, '</tbody></table>'
    )
  } else '<p style="color:#64748b;">No at-risk students found.</p>'

  show_print_modal("At-Risk Students Report", paste0(stat_html, tbl_html))
})


# ═══════════════════════════════════════════════════════════════════════════════
# PRINT REPORT — 5. College Rankings
# ═══════════════════════════════════════════════════════════════════════════════
observeEvent(input$print_rankings, {
  df <- admin_rank_filtered()   # respects active filters

  stat_html <- if (nrow(df) > 0) {
    top_student <- df[1, ]
    avg_score   <- round(mean(df$Average, na.rm = TRUE), 1)
    avg_gpa     <- round(mean(df$GPA_4,   na.rm = TRUE), 2)
    pass_rate   <- if ("Status" %in% names(df))
      paste0(round(mean(df$Status != "Fail", na.rm = TRUE) * 100, 1), "%") else "N/A"
    paste0(
      '<div class="stat-row">',
      '<div class="stat-box"><div class="val">', nrow(df), '</div>',
      '<div class="lbl">Students Listed</div></div>',
      '<div class="stat-box"><div class="val">', avg_score, '</div>',
      '<div class="lbl">Average Score</div></div>',
      '<div class="stat-box"><div class="val">', avg_gpa, ' / 4.0</div>',
      '<div class="lbl">Average GPA</div></div>',
      '<div class="stat-box"><div class="val">', pass_rate, '</div>',
      '<div class="lbl">Pass Rate</div></div>',
      '<div class="stat-box"><div class="val">',
      if ("Student_Name" %in% names(top_student)) top_student$Student_Name else "—",
      '</div><div class="lbl">Top Ranked Student</div></div>',
      '</div>'
    )
  } else ""

  tbl_html <- if (nrow(df) > 0) {
    cols <- c("Rank", "Student_ID", "Student_Name", "Course",
              "Average", "GPA_4", "Grade", "Status", "Attendance_Percentage")
    cols <- cols[cols %in% names(df)]
    rows <- paste(apply(df %>% select(all_of(cols)), 1, function(r) {
      grade_cell <- if ("Grade" %in% names(r)) grade_badge(r["Grade"]) else ""
      cells <- sapply(cols, function(col) {
        val <- r[col]
        if      (col == "Grade")               grade_cell
        else if (col == "GPA_4")               paste0(val, " / 4.0")
        else if (col == "Average")             paste0(val, "%")
        else if (col == "Attendance_Percentage") paste0(val, "%")
        else                                   val
      })
      paste0('<tr>', paste0('<td>', cells, '</td>', collapse = ""), '</tr>')
    }), collapse = "")

    header_names <- c(Rank = "Rank", Student_ID = "ID", Student_Name = "Name",
                      Course = "Course", Average = "Score", GPA_4 = "GPA (4.0)",
                      Grade = "Grade", Status = "Status",
                      Attendance_Percentage = "Attendance %")
    headers <- paste0('<th>', header_names[cols], '</th>', collapse = "")

    paste0(
      '<div class="section-title">Full Rankings (', nrow(df), ' students)</div>',
      '<table><thead><tr>', headers, '</tr></thead>',
      '<tbody>', rows, '</tbody></table>'
    )
  } else '<p style="color:#64748b;">No students match the current filters.</p>'

  show_print_modal("College Rankings Report", paste0(stat_html, tbl_html))
})
