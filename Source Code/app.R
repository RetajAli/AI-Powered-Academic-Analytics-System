library(shiny)
library(shinydashboard)
library(dplyr)
library(plotly)
library(DT)

source("ui_login.R")
source("ui_admin.R")
source("doctor_dashboard.R")
source("student_dashboard_only.R")
source("parent_dashboard.R")

ui <- tagList(
  tags$head(
    tags$style(HTML("
      html, body {
        width: 100% !important;
        height: 100% !important;
        margin: 0 !important;
        padding: 0 !important;
        overflow-x: hidden !important;
        background: #020617 !important;
      }

      #main_ui {
        width: 100% !important;
        min-height: 100vh !important;
        animation: fadeIn 0.3s ease-in-out;
      }

      .wrapper {
        width: 100% !important;
        min-height: 100vh !important;
        margin: 0 auto !important;
      }

      .content-wrapper,
      .right-side {
        margin-left: 230px !important;
        width: auto !important;
        min-height: 100vh !important;
      }

      .main-sidebar {
        min-height: 100vh !important;
      }

      .content {
        margin: auto !important;
        max-width: 1400px !important;
      }

      @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
      }
      /* ===== FIX PLACEHOLDERS IN LIGHT MODE ===== */

body.light-mode input::placeholder,
body.light-mode textarea::placeholder,
body.light-mode .form-control::placeholder {
  color: #64748b !important;
  opacity: 1 !important;
}

body.light-mode input::-webkit-input-placeholder {
  color: #64748b !important;
  opacity: 1 !important;
}

body.light-mode input::-moz-placeholder {
  color: #64748b !important;
  opacity: 1 !important;
}

body.light-mode input:-ms-input-placeholder {
  color: #64748b !important;
  opacity: 1 !important;
}
/* ===== FLOATING PREMIUM THEME TOGGLE ===== */

.theme-floating-toggle {
  position: fixed;
  top: 22px;
  right: 28px;
  z-index: 999999;
}

.theme-toggle-btn {
  width: 58px !important;
  height: 58px !important;
  border-radius: 50% !important;
  border: 1px solid rgba(255,255,255,0.28) !important;
  background: linear-gradient(135deg, #111827, #2563eb, #7c3aed) !important;
  color: white !important;
  font-size: 21px !important;
  box-shadow: 0 18px 40px rgba(37,99,235,0.38) !important;
  transition: 0.25s ease !important;
}

.theme-toggle-btn:hover {
  transform: translateY(-2px) scale(1.04);
  box-shadow: 0 22px 48px rgba(124,58,237,0.48) !important;
}

body.light-mode .theme-toggle-btn {
  background: linear-gradient(135deg, #f59e0b, #f97316, #7c3aed) !important;
  color: #ffffff !important;
  box-shadow: 0 18px 40px rgba(249,115,22,0.35) !important;
}

/* ===== PREMIUM BALANCED LIGHT MODE ===== */

body.light-mode,
body.light-mode .content-wrapper,
body.light-mode .right-side {
  background:
    radial-gradient(circle at 15% 10%, rgba(37,99,235,0.22), transparent 32%),
    radial-gradient(circle at 90% 0%, rgba(124,58,237,0.20), transparent 35%),
    linear-gradient(135deg, #dbeafe 0%, #f8fafc 48%, #ede9fe 100%) !important;
  color: #0f172a !important;
}

body.light-mode .box,
body.light-mode .hero-card,
body.light-mode .login-card {
  background: rgba(255,255,255,0.96) !important;
  color: #0f172a !important;
  border: 1px solid rgba(37,99,235,0.20) !important;
  box-shadow: 0 24px 58px rgba(30,41,59,0.20) !important;
}

body.light-mode .hero-card {
  background:
    linear-gradient(135deg, rgba(219,234,254,0.94), rgba(237,233,254,0.94)),
    rgba(255,255,255,0.98) !important;
}

body.light-mode .box-header {
  background: linear-gradient(90deg, #dbeafe, #ede9fe) !important;
  color: #0f172a !important;
  border-bottom: 1px solid rgba(15,23,42,0.10) !important;
}

body.light-mode .box-title,
body.light-mode .hero-title,
body.light-mode .brand-title,
body.light-mode label,
body.light-mode p,
body.light-mode span,
body.light-mode h1,
body.light-mode h2,
body.light-mode h3,
body.light-mode h4 {
  color: #0f172a !important;
}

body.light-mode .hero-subtitle,
body.light-mode .brand-subtitle,
body.light-mode .box-body {
  color: #334155 !important;
}

body.light-mode .main-sidebar,
body.light-mode .sidebar-footer {
  background: linear-gradient(180deg, #ffffff 0%, #eff6ff 55%, #e0e7ff 100%) !important;
  color: #0f172a !important;
  border-right: 1px solid rgba(15,23,42,0.12) !important;
  box-shadow: 10px 0 35px rgba(15,23,42,0.14) !important;
}

body.light-mode .sidebar-menu > li > a {
  color: #1e293b !important;
}

body.light-mode .sidebar-menu > li.active > a,
body.light-mode .sidebar-menu > li:hover > a {
  color: white !important;
}

body.light-mode table.dataTable thead th {
  background: #dbeafe !important;
  color: #0f172a !important;
}

body.light-mode table.dataTable tbody td {
  color: #0f172a !important;
  background: rgba(255,255,255,0.92) !important;
}

body.light-mode .dataTables_wrapper,
body.light-mode .dataTables_info,
body.light-mode .dataTables_paginate,
body.light-mode .dataTables_length,
body.light-mode .dataTables_filter {
  color: #0f172a !important;
}

body.light-mode .dataTables_filter input,
body.light-mode .dataTables_length select,
body.light-mode input,
body.light-mode select,
body.light-mode .form-control {
  background: #ffffff !important;
  color: #0f172a !important;
  border: 1px solid rgba(15,23,42,0.18) !important;
}

body.light-mode .selectize-input,
body.light-mode .selectize-dropdown,
body.light-mode .selectize-dropdown-content .option {
  background: #ffffff !important;
  color: #0f172a !important;
}

body.light-mode .js-plotly-plot,
body.light-mode .plot-container {
  filter: none !important;
}

body.dark-mode {
  background: #020617 !important;
}
    ")),
    tags$script(HTML("
  function applyPlotlyTheme(theme) {
    var isLight = theme === 'light';
    var textColor = isLight ? '#0f172a' : '#e5e7eb';
    var gridColor = isLight ? 'rgba(15,23,42,0.18)' : 'rgba(255,255,255,0.08)';
   var plotBg = isLight ? 'rgba(255,255,255,0.98)' : '#0f172a';

    document.querySelectorAll('.js-plotly-plot').forEach(function(gd) {
      if (window.Plotly && gd.data) {
        Plotly.relayout(gd, {
          'font.color': textColor,
          'paper_bgcolor': 'rgba(0,0,0,0)',
          'plot_bgcolor': plotBg,
          'xaxis.color': textColor,
          'yaxis.color': textColor,
          'xaxis.tickfont.color': textColor,
          'yaxis.tickfont.color': textColor,
          'xaxis.title.font.color': textColor,
          'yaxis.title.font.color': textColor,
          'xaxis.gridcolor': gridColor,
          'yaxis.gridcolor': gridColor,
          'legend.font.color': textColor
        });
      }
    });
  }

  window.applyPremiumTheme = function(theme) {
    document.body.classList.remove('dark-mode', 'light-mode');
    document.body.classList.add(theme + '-mode');


    setTimeout(function(){ applyPlotlyTheme(theme); }, 80);
    setTimeout(function(){ applyPlotlyTheme(theme); }, 350);
    setTimeout(function(){ applyPlotlyTheme(theme); }, 900);
  };

  document.addEventListener('DOMContentLoaded', function() {
    window.applyPremiumTheme('dark');
  });

  $(document).on('shown.bs.tab click', function() {
    var theme = document.body.classList.contains('light-mode') ? 'light' : 'dark';
    setTimeout(function(){ applyPlotlyTheme(theme); }, 250);
  });
"))
  ),
  
  uiOutput("main_ui"),
  
  
  tags$style(HTML("
/* ===== FINAL PREMIUM THEME OVERRIDE - DO NOT MOVE ===== */
body.dark-mode,
body.dark-mode .content-wrapper,
body.dark-mode .right-side {
  background:
    radial-gradient(circle at 15% 10%, rgba(37,99,235,0.30), transparent 30%),
    radial-gradient(circle at 85% 0%, rgba(147,51,234,0.28), transparent 32%),
    linear-gradient(135deg, #020617 0%, #0f172a 45%, #111827 100%) !important;
  color: #e5e7eb !important;
}

body.light-mode,
body.light-mode .content-wrapper,
body.light-mode .right-side,
body.light-mode .wrapper,
body.light-mode #main_ui {
  background:
    radial-gradient(circle at 12% 8%, rgba(37,99,235,0.24), transparent 28%),
    radial-gradient(circle at 88% 2%, rgba(124,58,237,0.22), transparent 32%),
    linear-gradient(135deg, #c7d2fe 0%, #eef2ff 42%, #dbeafe 100%) !important;
  color: #0f172a !important;
}

body.light-mode .main-sidebar,
body.light-mode .sidebar-footer {
  background: linear-gradient(180deg, #ffffff 0%, #eff6ff 50%, #e0e7ff 100%) !important;
  color: #0f172a !important;
  border-right: 1px solid rgba(37,99,235,0.18) !important;
  box-shadow: 10px 0 35px rgba(30,41,59,0.14) !important;
}

body.light-mode .box,
body.light-mode .hero-card,
body.light-mode .login-card,
body.light-mode .session-filter-box,
body.light-mode .student-search-box,
body.light-mode .report-box,
body.light-mode .clean-table-box {
  background: rgba(255,255,255,0.94) !important;
  color: #0f172a !important;
  border: 1px solid rgba(37,99,235,0.20) !important;
  box-shadow: 0 24px 58px rgba(30,41,59,0.20) !important;
}

body.light-mode .hero-card {
  background:
    linear-gradient(135deg, rgba(219,234,254,0.98), rgba(237,233,254,0.98)),
    rgba(255,255,255,0.98) !important;
}

body.light-mode .box-header {
  background: linear-gradient(90deg, #dbeafe, #ede9fe) !important;
  color: #0f172a !important;
  border-bottom: 1px solid rgba(15,23,42,0.10) !important;
}

body.light-mode .box-title,
body.light-mode .hero-title,
body.light-mode .brand-title,
body.light-mode .card-title,
body.light-mode label,
body.light-mode p,
body.light-mode span,
body.light-mode h1,
body.light-mode h2,
body.light-mode h3,
body.light-mode h4,
body.light-mode .box-body,
body.light-mode .dataTables_wrapper,
body.light-mode .dataTables_info,
body.light-mode .dataTables_paginate,
body.light-mode .dataTables_length,
body.light-mode .dataTables_filter {
  color: #0f172a !important;
}

body.light-mode .hero-subtitle,
body.light-mode .brand-subtitle,
body.light-mode .card-subtitle,
body.light-mode .secure-note {
  color: #334155 !important;
}

body.light-mode .sidebar-menu > li > a {
  color: #1e293b !important;
}

body.light-mode .sidebar-menu > li.active > a,
body.light-mode .sidebar-menu > li:hover > a {
  color: #ffffff !important;
  background: linear-gradient(90deg, #2563eb, #7c3aed) !important;
}

body.light-mode table.dataTable thead th {
  background: #dbeafe !important;
  color: #0f172a !important;
}

body.light-mode table.dataTable tbody td,
body.light-mode table.dataTable tbody tr {
  background: rgba(255,255,255,0.96) !important;
  color: #0f172a !important;
}

body.light-mode .dataTables_filter input,
body.light-mode .dataTables_length select,
body.light-mode input,
body.light-mode select,
body.light-mode .form-control,
body.light-mode .selectize-input,
body.light-mode .selectize-dropdown,
body.light-mode .selectize-dropdown-content .option {
  background: #ffffff !important;
  color: #0f172a !important;
  border: 1px solid rgba(15,23,42,0.18) !important;
}

body.light-mode .js-plotly-plot,
body.light-mode .plot-container {
  filter: none !important;
}

.theme-floating-toggle {
  position: fixed !important;
  top: 22px !important;
  right: 28px !important;
  z-index: 999999 !important;
}

.theme-toggle-btn {
  width: 58px !important;
  height: 58px !important;
  border-radius: 50% !important;
  border: 1px solid rgba(255,255,255,0.28) !important;
  background: linear-gradient(135deg, #111827, #2563eb, #7c3aed) !important;
  color: white !important;
  font-size: 22px !important;
  box-shadow: 0 18px 40px rgba(37,99,235,0.38) !important;
  transition: 0.25s ease !important;
  padding: 0 !important;
}

.theme-toggle-btn:hover {
  transform: translateY(-2px) scale(1.04) !important;
  box-shadow: 0 22px 48px rgba(124,58,237,0.48) !important;
}
/* ===== FIX PALE PLOTLY TEXT IN LIGHT MODE ===== */

body.light-mode .js-plotly-plot .xtick text,
body.light-mode .js-plotly-plot .ytick text,
body.light-mode .js-plotly-plot .gtitle,
body.light-mode .js-plotly-plot .xtitle,
body.light-mode .js-plotly-plot .ytitle,
body.light-mode .js-plotly-plot .legend text,
body.light-mode .js-plotly-plot text {
  fill: #0f172a !important;
  color: #0f172a !important;
  opacity: 1 !important;
}

body.light-mode .js-plotly-plot .gridlayer path {
  stroke: rgba(15,23,42,0.18) !important;
}

body.light-mode .js-plotly-plot .plot_bg {
  fill: rgba(255,255,255,0.95) !important;
}

body.light-mode .js-plotly-plot .bg {
  fill: rgba(255,255,255,0.95) !important;
}

body.light-mode .theme-toggle-btn {
  background: linear-gradient(135deg, #f59e0b, #f97316, #7c3aed) !important;
  box-shadow: 0 18px 40px rgba(249,115,22,0.35) !important;
}


/* ===== STRONG PLOTLY TEXT FIX FOR LIGHT MODE ===== */
body.light-mode .js-plotly-plot .main-svg text,
body.light-mode .js-plotly-plot .g-gtitle text,
body.light-mode .js-plotly-plot .xtick text,
body.light-mode .js-plotly-plot .ytick text,
body.light-mode .js-plotly-plot .xtitle,
body.light-mode .js-plotly-plot .ytitle,
body.light-mode .js-plotly-plot .legendtext,
body.light-mode .js-plotly-plot .slicetext,
body.light-mode .js-plotly-plot .annotation-text,
body.light-mode .js-plotly-plot text {
  fill: #0f172a !important;
  color: #0f172a !important;
  opacity: 1 !important;
}

body.light-mode .js-plotly-plot .gridlayer path,
body.light-mode .js-plotly-plot .xgrid,
body.light-mode .js-plotly-plot .ygrid {
  stroke: rgba(15,23,42,0.18) !important;
  opacity: 1 !important;
}

body.light-mode .js-plotly-plot .plot .bg,
body.light-mode .js-plotly-plot .plot_bg,
body.light-mode .js-plotly-plot .cartesianlayer .bg {
  fill: rgba(255,255,255,0.98) !important;
}

body.dark-mode .js-plotly-plot .main-svg text,
body.dark-mode .js-plotly-plot .g-gtitle text,
body.dark-mode .js-plotly-plot .xtick text,
body.dark-mode .js-plotly-plot .ytick text,
body.dark-mode .js-plotly-plot .xtitle,
body.dark-mode .js-plotly-plot .ytitle,
body.dark-mode .js-plotly-plot .legendtext,
body.dark-mode .js-plotly-plot text {
  fill: #e5e7eb !important;
  color: #e5e7eb !important;
  opacity: 1 !important;
}
")),
  
  tags$style(HTML("
/* ===== FINAL CLEAN LIGHT MODE POLISH + PROFESSIONAL SWITCH ===== */

/* Professional floating switch */
.theme-switch-container {
  position: fixed !important;
  top: 22px !important;
  right: 24px !important;
  z-index: 999999 !important;
}

.professional-theme-toggle {
  width: 78px !important;
  height: 40px !important;
  border-radius: 999px !important;
  cursor: pointer !important;
  background: transparent !important;
  border: none !important;
  padding: 0 !important;
  box-shadow: none !important;
  outline: none !important;
}

.professional-theme-toggle .toggle-track {
  width: 78px !important;
  height: 40px !important;
  border-radius: 999px !important;
  display: block !important;
  position: relative !important;
  background: linear-gradient(135deg, #0f172a, #312e81) !important;
  border: 1px solid rgba(255,255,255,0.16) !important;
  box-shadow: 0 14px 32px rgba(15,23,42,0.38), inset 0 -4px 12px rgba(0,0,0,0.22) !important;
  transition: all 0.28s ease !important;
}

.professional-theme-toggle .toggle-thumb {
  position: absolute !important;
  top: 5px !important;
  left: 43px !important;
  width: 30px !important;
  height: 30px !important;
  border-radius: 50% !important;
  background: #f8fafc !important;
  box-shadow: inset -7px -3px 0 #cbd5e1, 0 5px 14px rgba(255,255,255,0.22) !important;
  transition: all 0.28s ease !important;
}

.professional-theme-toggle .toggle-track::before,
.professional-theme-toggle .toggle-track::after {
  content: '' !important;
  position: absolute !important;
  width: 4px !important;
  height: 4px !important;
  border-radius: 50% !important;
  background: #ffffff !important;
  opacity: 0.85 !important;
  transition: all 0.28s ease !important;
}

.professional-theme-toggle .toggle-track::before { left: 17px !important; top: 12px !important; }
.professional-theme-toggle .toggle-track::after  { left: 28px !important; top: 25px !important; }

body.light-mode .professional-theme-toggle .toggle-track {
  background: linear-gradient(135deg, #93c5fd, #e0f2fe) !important;
  border: 1px solid rgba(37,99,235,0.22) !important;
  box-shadow: 0 14px 32px rgba(37,99,235,0.18), inset 0 -4px 10px rgba(15,23,42,0.10) !important;
}

body.light-mode .professional-theme-toggle .toggle-thumb {
  left: 5px !important;
  background: #fbbf24 !important;
  box-shadow: 0 5px 14px rgba(245,158,11,0.35), inset 0 -2px 5px rgba(15,23,42,0.18) !important;
}

body.light-mode .professional-theme-toggle .toggle-track::before {
  width: 18px !important;
  height: 8px !important;
  left: 42px !important;
  top: 12px !important;
  border-radius: 999px !important;
  background: rgba(255,255,255,0.92) !important;
}

body.light-mode .professional-theme-toggle .toggle-track::after {
  width: 12px !important;
  height: 6px !important;
  left: 53px !important;
  top: 23px !important;
  border-radius: 999px !important;
  background: rgba(255,255,255,0.92) !important;
}

.professional-theme-toggle:hover .toggle-track {
  transform: translateY(-1px) !important;
}

/* Logout button red with white text in light + dark mode */
#logout_btn,
.logout-button,
body.light-mode #logout_btn,
body.light-mode .logout-button {
  background: linear-gradient(90deg, #dc2626, #991b1b) !important;
  color: #ffffff !important;
  border: none !important;
  box-shadow: 0 12px 28px rgba(220,38,38,0.30) !important;
}

#logout_btn *,
.logout-button *,
body.light-mode #logout_btn *,
body.light-mode .logout-button * {
  color: #ffffff !important;
}

#logout_btn:hover,
.logout-button:hover,
body.light-mode #logout_btn:hover,
body.light-mode .logout-button:hover {
  background: linear-gradient(90deg, #ef4444, #b91c1c) !important;
  color: #ffffff !important;
}

/* Stronger instructor control panel badge in light mode */
body.light-mode .status-badge {
  background: linear-gradient(90deg, #2563eb, #7c3aed) !important;
  color: #ffffff !important;
  border: 1px solid rgba(255,255,255,0.45) !important;
  box-shadow: 0 14px 34px rgba(37,99,235,0.28) !important;
}

body.light-mode .status-badge,
body.light-mode .status-badge * {
  color: #ffffff !important;
  opacity: 1 !important;
}

/* Make Doctor / Student toggle readable on login page */
body.light-mode .toggle-label,
body.light-mode .toggle-label *,
body.light-mode .toggle-switch-container,
body.light-mode .toggle-switch-container *,
body.light-mode [class*='toggle'] {
  color: #0f172a !important;
  opacity: 1 !important;
}

body.light-mode .toggle-label {
  font-weight: 900 !important;
  text-shadow: none !important;
}

body.light-mode .toggle-switch {
  background: rgba(255,255,255,0.82) !important;
  border: 2px solid rgba(124,58,237,0.36) !important;
  box-shadow: 0 10px 26px rgba(124,58,237,0.16) !important;
}

body.light-mode .toggle-knob {
  color: #ffffff !important;
  opacity: 1 !important;
}

/* Login placeholders + inputs readable */
body.light-mode input::placeholder,
body.light-mode textarea::placeholder,
body.light-mode .form-control::placeholder {
  color: #64748b !important;
  opacity: 1 !important;
}

body.light-mode .login-card input,
body.light-mode .login-card .form-control {
  background: #ffffff !important;
  color: #0f172a !important;
  border: 1px solid rgba(15,23,42,0.18) !important;
}

/* prevent Plotly flash when switching back to dark */
body.dark-mode .js-plotly-plot .plot_bg,
body.dark-mode .js-plotly-plot .bg,
body.dark-mode .js-plotly-plot .cartesianlayer .bg {
  fill: #0f172a !important;
}

body.dark-mode .js-plotly-plot .main-svg {
  background: transparent !important;
}

body.light-mode .login-card label,
body.light-mode .login-card .card-title,
body.light-mode .login-card .card-subtitle,
body.light-mode .login-card .secure-note {
  color: #0f172a !important;
  opacity: 1 !important;
}

body.light-mode .login-card .card-subtitle,
body.light-mode .login-card .secure-note {
  color: #334155 !important;
}

/* Keep white button text inside colored buttons */
body.light-mode .login-btn,
body.light-mode .refresh-button,
body.light-mode .small-box,
body.light-mode .small-box *,
body.light-mode .login-btn * {
  color: #ffffff !important;
}

@media (max-width: 768px) {
  .theme-switch-container { top: 16px !important; right: 16px !important; }
}
")),
  div(
    class = "theme-switch-container",
    tags$div(
      id = "theme_toggle_btn",
      class = "professional-theme-toggle",
      onclick = "var nextTheme = document.body.classList.contains('light-mode') ? 'dark' : 'light'; if (window.applyPremiumTheme) { window.applyPremiumTheme(nextTheme); } else { document.body.classList.toggle('light-mode', nextTheme === 'light'); document.body.classList.toggle('dark-mode', nextTheme === 'dark'); }",
      tags$span(class = "toggle-track", tags$span(class = "toggle-thumb"))
    )
  )
)
# ── Server ───────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  active_page    <- reactiveVal("login")
  current_student <- reactiveVal(NULL)
  current_parent_student <- reactiveVal(NULL)
  
  # ── Helper: load CSV (or return empty skeleton) ───────────────────────────
  load_student_data_app <- function() {
    possible_paths <- c(
      "students_dashboard_slots_fixed.csv",
      "students_dashboard_slots_fixed(1).csv",
      file.path(getwd(), "students_dashboard_slots_fixed.csv"),
      file.path(getwd(), "students_dashboard_slots_fixed(1).csv")
    )
    csv_path <- possible_paths[file.exists(possible_paths)][1]
    
    if (is.na(csv_path) || length(csv_path) == 0) {
      showNotification(
        "CSV file not found: students_dashboard_slots_fixed.csv",
        type = "error"
      )
      return(data.frame())
    }
    
    df <- read.csv(csv_path, stringsAsFactors = FALSE)
    names(df) <- trimws(names(df))
    
    df <- df %>%
      mutate(
        Course_Work_Recommendation = case_when(
          Attendance_Percentage >= 85 & Questions_Asked >= 4 ~ "Excellent participation",
          Attendance_Percentage >= 75 & Questions_Asked >= 2 ~ "Good, keep improving",
          Attendance_Percentage < 75 & Questions_Asked < 2 ~ "Needs more attendance and participation",
          Attendance_Percentage < 75 ~ "Improve attendance",
          Questions_Asked < 2 ~ "Ask more questions in class",
          TRUE ~ "Normal performance"
        )
      )
    
    return(df)
  }
  
  # ── Page router — call make_*() every time so bindings are always fresh ───
  output$main_ui <- renderUI({
    page <- active_page()
    
    if (page == "doctor") {
      make_dashboard_ui()
    } else if (page == "student") {
      make_student_dashboard_ui()
    } else if (page == "admin") {
      if (exists("make_admin_dashboard_ui")) {
        make_admin_dashboard_ui()
      } else if (exists("admin_ui")) {
        admin_ui
      } else {
        tags$div("Admin UI file loaded, but no admin UI object/function was found.")
      }
    } else if (page == "parent" || page == "Parent") {
      make_parent_dashboard_ui()
    } else {
      make_login_ui()
    }
  })
  
  # ── Doctor login: username = "Mohamed fathy", password = "1234" ───────────
  observeEvent(input$login_btn, {
    req(input$username, input$password)
    username <- tolower(trimws(input$username))
    password <- trimws(input$password)
    
    if (username == "mohamed fathy" && password == "1234") {
      active_page("doctor")
      updateTabItems(session, "tabs", selected = "overview")
      
    } else if (username == "dean" && password == "dean2024") {
      active_page("admin")
      updateTabItems(session, "admin_tabs", selected = "admin_overview")
      
    } else if (username == "parent" && password == "parent1234") {
      df <- load_student_data_app()
      if (nrow(df) > 0) current_parent_student(df[1, ])
      active_page("parent")
      updateTabItems(session, "Parent_tabs", selected = "p_overview")
      
    } else {
      showNotification("Wrong username or password", type = "error")
    }
  })
  
  # ── Student login ─────────────────────────────────────────────────────────
observeEvent(input$student_login_btn, {
  
  df <- load_student_data_app()

  # Check if file exists or empty
  if (nrow(df) == 0) {
    showNotification("Student data file is empty or missing", type = "error")
    return()
  }

  # Find student
  student <- df %>%
    filter(
      Student_ID == trimws(input$student_username) |
      tolower(Student_Name) == tolower(trimws(input$student_username))
    )

  # Student not found
  if (nrow(student) == 0) {
    showNotification("Student not found", type = "error")
    return()
  }

  # Password check
  if (trimws(input$student_password) == trimws(student$Student_ID[1])) {

    current_student(student[1, ])
    active_page("student")
    updateTabItems(session, "student_tabs", selected = "student_overview")

    showNotification("Login successful", type = "message")

  } else {

    showNotification(
      "Incorrect password. Please enter your Student ID.",
      type = "error"
    )
  }
})
# ── Parent Login ─────────────────────────────────────────
observeEvent(input$parent_login_btn, {
  
  df <- load_student_data_app()
  
  # Check if file exists or empty
  if (nrow(df) == 0) {
    showNotification("Student data file is empty or missing", type = "error")
    return()
  }
  
  # Find student by ID or name
  student <- df %>%
    filter(
      Student_ID == trimws(input$parent_username) |
      tolower(Student_Name) == tolower(trimws(input$parent_username))
    )
  
  # Student not found
  if (nrow(student) == 0) {
    showNotification("Student not found", type = "error")
    return()
  }
  
  # Password check — same rule as student: password must match Student_ID
  if (trimws(input$parent_password) == trimws(student$Student_ID[1])) {
    
    current_parent_student(student[1, ])
    active_page("parent")
    
    showNotification("Login successful", type = "message")
    
  } else {
    showNotification(
      "Incorrect password. Please enter your Student ID.",
      type = "error"
    )
  }
  
})
  
  observeEvent(input$logout_btn, {
    current_student(NULL)
    current_parent_student(NULL)
    active_page("login")
  })
  
  observeEvent(input$student_logout_btn, {
    current_student(NULL)
    active_page("login")
  })
  
  observeEvent(input$parent_logout_btn, {
    current_parent_student(NULL)
    active_page("login")
  })
  
  register_doctor_dashboard_server(input, output, session, load_student_data_app)
  if (exists("register_parent_dashboard_server")) {
    register_parent_dashboard_server(input, output, session, current_parent_student, load_student_data_app)
  }
  
  # ═══════════════════════════════════════════════════════════════════════════
  # STUDENT DASHBOARD Server Registration
  # ═══════════════════════════════════════════════════════════════════════════
  if (exists("register_student_dashboard_server")) {
    register_student_dashboard_server(input, output, session, current_student)
  }
  if (file.exists("admin_server.R")) {
    source("admin_server.R", local = TRUE)
  }
}

shinyApp(ui = ui, server = server)
