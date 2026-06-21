library(shiny)
library(shinydashboard)
library(dplyr)
library(plotly)
library(DT)

make_dashboard_ui <- function() {
  dashboardPage(
    skin = "black",
    
    dashboardHeader(
      title = ""
    ),
    
    dashboardSidebar(
      div(class = "brand-panel",
          div(class = "brand-icon", icon("eye")),
          div(class = "brand-title", "Academic Analytics System"),
          div(class = "brand-subtitle", "Student Analytics Portal")
      ),
      
      sidebarMenu(
        id = "tabs",
        menuItem("Dashboard Overview", tabName = "overview", icon = icon("chart-line")),
        menuItem("Session", tabName = "session", icon = icon("video-camera")),
        menuItem("Session Filter", tabName = "sessions", icon = icon("calendar-days")),
        menuItem("Student Report", tabName = "student_report", icon = icon("user-graduate")),
        menuItem("Attendance", tabName = "attendance", icon = icon("clipboard-check")),
        menuItem("Activity", tabName = "activity", icon = icon("bolt")),
        menuItem("Raw Data", tabName = "rawlog", icon = icon("database"))
      ),
      
      div(
        style = "padding: 15px; display: flex; justify-content: center;",
        actionButton(
          "refresh_btn",
          "Update Data",
          icon = icon("rotate"),
          class = "refresh-button",
          style = "width:85%;"
        )
      ),
      
      div(class = "sidebar-footer",
          div(class = "live-dot"),
          span("Live Monitoring Active"),
          br(), br(),
          actionButton(
            "logout_btn",
            "Logout",
            icon = icon("right-from-bracket"),
            class = "logout-button"
          )
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$style(HTML("
  .main-header {
    display: none !important;
  }

html, body {
  height: 100% !important;
  margin: 0 !important;
  padding: 0 !important;
  overflow: hidden !important;
}
.start-session-btn {
  background: linear-gradient(90deg, #06b6d4, #22c55e);
  border: none;
  color: white;
  font-weight: bold;
  height: 50px;
  border-radius: 12px;
  font-size: 16px;
  transition: 0.3s;
}

.start-session-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(34,197,85,0.3);
}

  body, .content-wrapper, .right-side {
    background:
      radial-gradient(circle at 15% 10%, rgba(37,99,235,0.30), transparent 30%),
      radial-gradient(circle at 85% 0%, rgba(147,51,234,0.28), transparent 32%),
      linear-gradient(135deg, #020617 0%, #0f172a 45%, #111827 100%);
    color: #e5e7eb;
    font-family: 'Segoe UI', Arial, sans-serif;
  }

  .session-filter-box {
  background:
    linear-gradient(135deg, rgba(15,23,42,0.96), rgba(30,41,59,0.86)) !important;
  border: 1px solid rgba(6,182,212,0.18) !important;
  box-shadow: 0 25px 70px rgba(0,0,0,0.42) !important;
}

.session-filter-box .box-header {
  padding: 20px 24px !important;
}

.session-filter-box .box-title {
  font-size: 20px !important;
}

.session-filter-box .box-body {
  padding: 26px 28px !important;
}

.session-filter-box select.form-control {
  background: rgba(15,23,42,0.92) !important;
  color: #e5e7eb !important;
  border: 1px solid rgba(6,182,212,0.45) !important;
  border-radius: 18px !important;
  height: 52px !important;
  font-size: 15px !important;
  font-weight: 800 !important;
  box-shadow: 0 0 0 3px rgba(6,182,212,0.08) !important;
}

.session-filter-box select.form-control option {
  background: #0f172a !important;
  color: #e5e7eb !important;
  font-weight: 700 !important;
}

.session-filter-box label {
  color: #e5e7eb !important;
  font-weight: 900 !important;
  font-size: 15px !important;
  margin-bottom: 10px !important;
}

.session-line {
  border: none !important;
  height: 1px !important;
  background: linear-gradient(90deg, transparent, rgba(6,182,212,0.35), transparent) !important;
  margin: 24px 0 18px 0 !important;
}

.week-title {
  color: #e5e7eb;
  font-size: 16px;
  font-weight: 900;
  margin-bottom: 12px;
}

.week-scroll {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  overflow-y: hidden;
  padding: 8px 4px 16px 4px;
  scroll-behavior: smooth;
}

.week-scroll::-webkit-scrollbar {
  height: 8px;
}

.week-scroll::-webkit-scrollbar-track {
  background: rgba(255,255,255,0.06);
  border-radius: 999px;
}

.week-scroll::-webkit-scrollbar-thumb {
  background: linear-gradient(90deg, #2563eb, #7c3aed);
  border-radius: 999px;
}

.week-pill {
  min-width: 105px !important;
  height: 44px !important;
  border-radius: 999px !important;
  border: 1px solid rgba(255,255,255,0.12) !important;
  background: rgba(255,255,255,0.06) !important;
  color: #cbd5e1 !important;
  font-weight: 900 !important;
  box-shadow: none !important;
}

.week-pill:hover,
.week-pill:focus {
  background: linear-gradient(90deg, #2563eb, #7c3aed) !important;
  color: white !important;
  transform: translateY(-1px);
}

.active-week {
  background: linear-gradient(90deg, #2563eb, #7c3aed) !important;
  color: white !important;
  box-shadow: 0 12px 26px rgba(37,99,235,0.35) !important;
}

  .wrapper {
    min-height: 100vh !important;
  }

.content-wrapper,
.right-side {
  position: fixed !important;
  top: 0 !important;
  left: 230px !important;
  right: 0 !important;
  bottom: 0 !important;
  margin-left: 0 !important;
  padding: 22px !important;
  min-height: 100vh !important;
  overflow-y: auto !important;
  overflow-x: hidden !important;
}

  .main-sidebar {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    bottom: 0 !important;
    width: 230px !important;
    height: 100vh !important;
    min-height: 100vh !important;
    background: rgba(2,6,23,0.98) !important;
    border-right: 1px solid rgba(255,255,255,0.08);
    box-shadow: 10px 0 35px rgba(0,0,0,0.40);
    padding-top: 0 !important;
    overflow-y: auto !important;
    overflow-x: hidden !important;
    scroll-behavior: smooth;
  }

  .main-sidebar .sidebar {
    min-height: 100vh !important;
    padding-top: 20px !important;
    padding-bottom: 170px !important;
  }

  .main-sidebar::-webkit-scrollbar {
    width: 6px;
  }

  .main-sidebar::-webkit-scrollbar-thumb {
    background: rgba(255,255,255,0.2);
    border-radius: 10px;
  }

  .brand-panel {
    padding: 18px 18px 18px 18px;
    text-align: center;
  }

  .brand-icon {
    width: 64px;
    height: 64px;
    margin: auto;
    border-radius: 22px;
    background: linear-gradient(135deg, #2563eb, #7c3aed);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 26px;
    box-shadow: 0 16px 35px rgba(37,99,235,0.45);
  }

  .brand-title {
    margin-top: 14px;
    font-size: 17px;
    font-weight: 900;
    color: white;
  }

  .brand-subtitle {
    font-size: 12px;
    color: #94a3b8;
    margin-top: 5px;
  }

  .sidebar-menu > li > a {
    color: #cbd5e1 !important;
    font-weight: 700;
    margin: 8px 13px;
    border-radius: 18px;
    padding: 14px 16px;
  }

  .sidebar-menu > li.active > a,
  .sidebar-menu > li:hover > a {
    background: linear-gradient(90deg, #2563eb, #7c3aed) !important;
    color: white !important;
    border-left: none !important;
    box-shadow: 0 12px 24px rgba(37,99,235,0.32);
  }

  .sidebar-footer {
    position: fixed !important;
    bottom: 24px !important;
    left: 0 !important;
    width: 230px !important;
    text-align: center;
    color: #94a3b8;
    font-size: 12px;
    padding: 12px;
    z-index: 9999;
    background: rgba(2,6,23,0.98);
  }

  .live-dot {
    width: 10px;
    height: 10px;
    background: #22c55e;
    display: inline-block;
    border-radius: 50%;
    box-shadow: 0 0 16px #22c55e;
    margin-right: 7px;
  }

  .refresh-button {
    background: linear-gradient(90deg, #2563eb, #7c3aed) !important;
    color: white !important;
    border: none !important;
    border-radius: 999px !important;
    padding: 11px 24px !important;
    font-weight: 900;
    box-shadow: 0 12px 28px rgba(37,99,235,0.38);
  }

  .logout-button {
    width: 85%;
    background: linear-gradient(90deg, #dc2626, #991b1b) !important;
    color: white !important;
    border: none !important;
    border-radius: 999px !important;
    padding: 11px 24px !important;
    font-weight: 900;
    box-shadow: 0 12px 28px rgba(220,38,38,0.30);
  }

  .hero-card {
    background:
      linear-gradient(135deg, rgba(37,99,235,0.25), rgba(124,58,237,0.22)),
      rgba(15,23,42,0.82);
    border: 1px solid rgba(255,255,255,0.12);
    border-radius: 30px;
    padding: 30px;
    margin-bottom: 24px;
    box-shadow: 0 28px 70px rgba(0,0,0,0.42);
    backdrop-filter: blur(16px);
    position: relative;
    overflow: hidden !important;
  }

  .hero-card::after {
    content: '';
    position: absolute;
    right: -80px;
    top: -80px;
    width: 240px;
    height: 240px;
    background: radial-gradient(circle, rgba(6,182,212,0.22), transparent 70%);
    border-radius: 50%;
  }

  .hero-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 15px;
    position: relative;
    z-index: 2;
  }

  .hero-title {
    font-size: 32px;
    font-weight: 900;
    color: white;
    margin-bottom: 8px;
  }

  .hero-subtitle {
    color: #cbd5e1;
    font-size: 14px;
    line-height: 1.7;
  }

  .status-badge {
    background: rgba(6,182,212,0.16) !important;
    color: #67e8f9 !important;
    border: 1px solid rgba(6,182,212,0.40) !important;
    padding: 10px 18px;
    border-radius: 999px;
    font-weight: 800;
    white-space: nowrap;
    box-shadow: 0 10px 30px rgba(6,182,212,0.12);
  }

  .box {
    background: rgba(15,23,42,0.86);
    border-radius: 26px;
    border: 1px solid rgba(255,255,255,0.10);
    box-shadow: 0 20px 50px rgba(0,0,0,0.36);
    border-top: none !important;
    overflow: visible !important;
    backdrop-filter: blur(14px);
  }

  .box-header {
    color: white;
    background: rgba(255,255,255,0.04);
    border-bottom: 1px solid rgba(255,255,255,0.08);
    padding: 16px 20px;
  }

  .box-title {
    font-weight: 900;
    font-size: 16px;
  }

  .box-body {
    color: #e5e7eb;
    padding: 20px;
  }

  .small-box {
    border-radius: 26px;
    box-shadow: 0 20px 45px rgba(0,0,0,0.36);
    overflow: hidden !important;
    border: 1px solid rgba(255,255,255,0.12);
  }

  .small-box h3 {
    font-weight: 900;
    font-size: 32px;
  }

  .small-box p {
    font-weight: 800;
  }

  .small-box .icon {
    opacity: 0.24;
  }

  .session-filter-box {
    margin-bottom: 28px !important;
  }

  .shiny-input-container label {
    color: #e5e7eb !important;
    font-weight: 900 !important;
    margin-bottom: 8px !important;
  }

table.dataTable tbody tr:hover {
  background-color: rgba(37, 99, 235, 0.15) !important;
  color: #e5e7eb !important;
}
table.dataTable tbody tr:hover {
  background: linear-gradient(90deg, rgba(37,99,235,0.18), rgba(124,58,237,0.18)) !important;
}

table.dataTable tbody tr.selected {
  background-color: rgba(124, 58, 237, 0.25) !important;
  color: white !important;
}

.dataTable tbody tr {
  background-color: transparent !important;
}

  .clean-table-box .box-body {
    padding: 18px !important;
  }

  .dataTables_wrapper {
    color: #e5e7eb;
    width: 100% !important;
    overflow-x: auto !important;
  }

  table.dataTable {
    width: 100% !important;
    border-collapse: collapse !important;
    font-size: 13px !important;
  }

  table.dataTable thead th {
    background: rgba(15,23,42,0.95) !important;
    color: #e5e7eb !important;
    font-weight: 800 !important;
    padding: 12px 10px !important;
    border-bottom: 1px solid rgba(255,255,255,0.12) !important;
    white-space: nowrap !important;
  }
  .content-wrapper {
  padding-top: 22px !important;
  overflow-x: hidden !important;
}

.content {
  padding-top: 0 !important;
}

  table.dataTable tbody td {
    color: #e5e7eb !important;
    padding: 12px 10px !important;
    border-bottom: 1px solid rgba(255,255,255,0.06) !important;
    white-space: nowrap !important;
  }

  .dataTables_length,
  .dataTables_filter {
    margin-bottom: 14px !important;
  }

  .dataTables_filter input,
  .dataTables_length select {
    background: rgba(255,255,255,0.08) !important;
    color: white !important;
    border: 1px solid rgba(255,255,255,0.18) !important;
    border-radius: 10px !important;
    padding: 7px 10px !important;
  }

  .student-search-box {
    margin-bottom: 24px !important;
  }

  .student-search-box .box-body {
    padding: 24px !important;
  }

  .student-search-box input {
    background: #ffffff !important;
    color: #111827 !important;
    height: 48px !important;
    border-radius: 14px !important;
    border: 1px solid rgba(6,182,212,0.55) !important;
    font-weight: 700 !important;
    padding: 10px 16px !important;
  }

  .student-search-box input::placeholder {
    color: #6b7280 !important;
  }

  .student-search-box label {
    color: #e5e7eb !important;
    font-weight: 900 !important;
    margin-bottom: 10px !important;
  }

  .report-box {
    min-height: 360px !important;
  }

  .report-box .box-body {
    min-height: 300px !important;
  }

select.form-control {
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;

  background: linear-gradient(135deg, rgba(15,23,42,0.95), rgba(30,41,59,0.9)) !important;
  color: #e5e7eb !important;

  border: 1px solid rgba(124,58,237,0.5) !important;
  border-radius: 16px !important;

  height: 52px !important;
  font-weight: 800 !important;

  padding: 10px 40px 10px 16px !important;

  background-image: linear-gradient(45deg, transparent 50%, #7c3aed 50%),
                    linear-gradient(135deg, #7c3aed 50%, transparent 50%);
  background-position: calc(100% - 20px) calc(50% - 3px),
                       calc(100% - 14px) calc(50% - 3px);
  background-size: 6px 6px;
  background-repeat: no-repeat;

  box-shadow:
    0 10px 24px rgba(0,0,0,0.38),
    0 0 14px rgba(6,182,212,0.10) !important;

  transition: all 0.25s ease !important;
}

select.form-control:hover {
  border-color: #38bdf8 !important;
  box-shadow:
    0 0 16px rgba(6,182,212,0.35),
    0 10px 24px rgba(0,0,0,0.45) !important;
}

select.form-control:focus {
  border-color: #7c3aed !important;
  box-shadow:
    0 0 18px rgba(124,58,237,0.45),
    0 10px 24px rgba(0,0,0,0.45) !important;
}

select.form-control option {
  background: #0f172a !important;
  color: #e5e7eb !important;
  font-weight: 800 !important;
}

.dataTables_length select {
  background: #0f172a !important;
  color: #e5e7eb !important;
  border: 1px solid rgba(6,182,212,0.45) !important;
  border-radius: 10px !important;
}

.dataTables_filter input {
  background: rgba(15,23,42,0.95) !important;
  color: #e5e7eb !important;
  border: 1px solid rgba(6,182,212,0.45) !important;
  border-radius: 10px !important;
}

.shiny-input-container {
  position: relative;
}

.selectize-input {
  background: #0f172a !important;
  color: #e5e7eb !important;
  border: 1px solid rgba(6,182,212,0.65) !important;
  border-radius: 18px !important;
  min-height: 52px !important;
  padding: 15px 45px 12px 18px !important;
  font-weight: 900 !important;
  box-shadow: 0 0 18px rgba(6,182,212,0.18) !important;
}

.selectize-input input {
  color: #e5e7eb !important;
}

.selectize-dropdown {
  background: #0f172a !important;
  color: #e5e7eb !important;
  border: 1px solid rgba(6,182,212,0.45) !important;
  border-radius: 14px !important;
  overflow: hidden !important;
  z-index: 99999 !important;
}

.selectize-dropdown-content .option {
  background: #0f172a !important;
  color: #e5e7eb !important;
  padding: 12px 18px !important;
  font-weight: 800 !important;
}

.selectize-dropdown-content .option.active {
  background: linear-gradient(90deg, #2563eb, #7c3aed) !important;
  color: white !important;
}

.selectize-control.single .selectize-input:after {
  border-color: #38bdf8 transparent transparent transparent !important;
  right: 18px !important;
}

/* ── PRINT PDF BUTTON ───────────────────────────────────────── */
.print-pdf-btn {
  background: linear-gradient(90deg, #dc2626, #b91c1c) !important;
  color: white !important;
  border: none !important;
  border-radius: 999px !important;
  padding: 11px 28px !important;
  font-weight: 900 !important;
  font-size: 14px !important;
  box-shadow: 0 12px 28px rgba(220,38,38,0.38) !important;
  transition: all 0.25s ease !important;
  cursor: pointer !important;
}

.print-pdf-btn:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 16px 36px rgba(220,38,38,0.50) !important;
  color: white !important;
}

/* ── PRINT MEDIA STYLES ─────────────────────────────────────── */
@media print {
  * {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }

  /* Hide everything except the student report content */
  .main-sidebar,
  .main-header,
  .sidebar-footer,
  .print-pdf-btn,
  #print_report_btn,
  .student-search-box,
  .hero-card .status-badge,
  .dataTables_length,
  .dataTables_filter,
  .dataTables_paginate,
  .dataTables_info,
  .shiny-input-container,
  .tab-content > .tab-pane:not(.active) {
    display: none !important;
  }

  html, body {
    height: auto !important;
    overflow: visible !important;
    background: #ffffff !important;
    color: #111827 !important;
    margin: 0 !important;
    padding: 0 !important;
    font-family: 'Segoe UI', Arial, sans-serif !important;
  }

  .content-wrapper,
  .right-side {
    position: static !important;
    left: 0 !important;
    top: 0 !important;
    margin: 0 !important;
    padding: 24px !important;
    background: #ffffff !important;
    color: #111827 !important;
    overflow: visible !important;
    height: auto !important;
    min-height: unset !important;
    width: 100% !important;
  }

  /* Print header banner */
  .print-header {
    display: block !important;
    background: linear-gradient(135deg, #1e3a8a, #4c1d95) !important;
    color: white !important;
    padding: 20px 28px !important;
    border-radius: 12px !important;
    margin-bottom: 24px !important;
  }

  .print-header h1 {
    margin: 0 0 6px 0 !important;
    font-size: 22px !important;
    font-weight: 900 !important;
  }

  .print-header p {
    margin: 0 !important;
    font-size: 12px !important;
    opacity: 0.85 !important;
  }

  /* Hero card */
  .hero-card {
    background: linear-gradient(135deg, #1e3a8a, #4c1d95) !important;
    color: white !important;
    border-radius: 12px !important;
    padding: 20px !important;
    margin-bottom: 20px !important;
    box-shadow: none !important;
    page-break-inside: avoid !important;
  }

  .hero-title {
    color: white !important;
    font-size: 22px !important;
  }

  .hero-subtitle {
    color: rgba(255,255,255,0.85) !important;
  }

  /* Boxes */
  .box {
    background: #ffffff !important;
    border: 1.5px solid #e2e8f0 !important;
    border-radius: 10px !important;
    box-shadow: none !important;
    margin-bottom: 18px !important;
    page-break-inside: avoid !important;
    backdrop-filter: none !important;
  }

  .box-header {
    background: #f1f5f9 !important;
    color: #1e293b !important;
    border-bottom: 1.5px solid #e2e8f0 !important;
    border-radius: 10px 10px 0 0 !important;
    padding: 12px 18px !important;
  }

  .box-title {
    color: #1e293b !important;
    font-weight: 900 !important;
  }

  .box-body {
    color: #1e293b !important;
    padding: 16px 18px !important;
  }

  /* Value boxes (small-box) */
  .small-box {
    border-radius: 10px !important;
    box-shadow: none !important;
    border: 1.5px solid #e2e8f0 !important;
    page-break-inside: avoid !important;
  }

  .small-box.bg-purple,
  .small-box.bg-blue,
  .small-box.bg-green,
  .small-box.bg-yellow {
    background: linear-gradient(135deg, #1e3a8a, #4c1d95) !important;
  }

  .small-box h3,
  .small-box p {
    color: white !important;
  }

  .small-box .icon {
    opacity: 0.3 !important;
  }

  /* Tables */
  table.dataTable {
    width: 100% !important;
    border-collapse: collapse !important;
    font-size: 12px !important;
  }

  table.dataTable thead th {
    background: #1e3a8a !important;
    color: white !important;
    font-weight: 800 !important;
    padding: 10px 8px !important;
    border-bottom: 2px solid #3b82f6 !important;
  }

  table.dataTable tbody td {
    color: #1e293b !important;
    padding: 9px 8px !important;
    border-bottom: 1px solid #e2e8f0 !important;
  }

  table.dataTable tbody tr:nth-child(even) td {
    background: #f8fafc !important;
  }

  /* Recommendation box */
  #report_recommendation > div {
    background: #f0f9ff !important;
    border-left: 4px solid #4c1d95 !important;
    color: #1e293b !important;
    border-radius: 8px !important;
    padding: 14px 18px !important;
  }

  /* Activity summary */
  #student_activity_summary p {
    color: #1e293b !important;
    margin: 6px 0 !important;
  }

  /* Page settings */
  @page {
    margin: 15mm 12mm !important;
    size: A4 portrait !important;
  }

  /* Plotly charts - let them render as-is */
  .js-plotly-plot {
    page-break-inside: avoid !important;
  }
}
")),

        # ── PRINT JAVASCRIPT ──────────────────────────────────────────────────
        tags$script(HTML("
  function forceTopScroll() {
    window.scrollTo(0, 0);
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
    $('.content-wrapper').scrollTop(0);
    $('.right-side').scrollTop(0);
    $('.content').scrollTop(0);
  }

  $(document).on('click', '.sidebar-menu a', function() {
    forceTopScroll();
    setTimeout(forceTopScroll, 50);
    setTimeout(forceTopScroll, 150);
    setTimeout(forceTopScroll, 300);
    setTimeout(forceTopScroll, 600);
  });

  $(document).on('shown.bs.tab', 'a[data-toggle=\"tab\"]', function() {
    forceTopScroll();
    setTimeout(forceTopScroll, 50);
    setTimeout(forceTopScroll, 150);
    setTimeout(forceTopScroll, 300);
  });

  $(document).on('click', '.week-pill', function() {
    $('.week-pill').removeClass('active-week');
    $(this).addClass('active-week');
  });

  // ── PRINT PDF HANDLER ──────────────────────────────────────────────────
  $(document).on('click', '#print_report_btn', function() {
    var studentName = $('#student_search').val().trim();
    if (!studentName) {
      alert('Please search for a student first before printing.');
      return;
    }
    window.print();
  });
"))
      ),
      
      tabItems(
        
        # ── ACTIVITY ──────────────────────────────────────────────────────────
        tabItem(
          tabName = "activity",
          
          div(class = "hero-card",
              div(class = "hero-title", "Student Activity"),
              div(class = "hero-subtitle",
                  "Monitor student engagement, questions asked, lecture participation, and activity level.")
          ),
          
          fluidRow(
            valueBoxOutput("total_questions_box", width = 3),
            valueBoxOutput("avg_questions_box",   width = 3),
            valueBoxOutput("high_activity_box",   width = 3),
            valueBoxOutput("low_activity_box",    width = 3)
          ),
          
          fluidRow(
            box(title = tagList(icon("circle-question"), " Questions Asked by Students"),
                width = 6, plotlyOutput("questions_chart", height = 380)),
            box(title = tagList(icon("bolt"), " Activity Level Distribution"),
                width = 6, plotlyOutput("activity_level_pie", height = 380))
          ),
          
          fluidRow(
            box(title = tagList(icon("ranking-star"), " Most Active Students"),
                width = 6, DTOutput("most_active_table")),
            box(title = tagList(icon("user-clock"), " Activity vs Minutes Stayed"),
                width = 6, plotlyOutput("activity_minutes_chart", height = 350))
          )
        ),
        
        # ── OVERVIEW ──────────────────────────────────────────────────────────
        tabItem(
          tabName = "overview",
          
          div(class = "hero-card",
              div(class = "hero-top",
                  div(
                    div(class = "hero-title", "Welcome back, Mohamed Fathy"),
                    div(class = "hero-subtitle",
                        "Monitor class performance, attendance, student activity, and final exam readiness from one professional dashboard.")
                  ),
                  div(class = "status-badge", icon("chart-line"), " Instructor Control Panel")
              )
          ),
          
          fluidRow(
            valueBoxOutput("total_students_box",  width = 3),
            valueBoxOutput("avg_score_box",        width = 3),
            valueBoxOutput("attendance_box",       width = 3),
            valueBoxOutput("avg_prediction_box",   width = 3)
          ),
          
          fluidRow(
            box(title = tagList(icon("chart-bar"), " Average Grade by Course"),
                width = 6, solidHeader = FALSE,
                plotlyOutput("course_avg_chart", height = 330)),
            box(title = tagList(icon("users"), " Activity Level Distribution"),
                width = 6, solidHeader = FALSE,
                plotlyOutput("activity_pie_chart", height = 330))
          )
        ),
        
        # ── SESSION FILTER ────────────────────────────────────────────────────
        tabItem(
          tabName = "sessions",
          
          div(class = "hero-card",
              div(class = "hero-title", "Class Session Filter"),
              div(class = "hero-subtitle",
                  "Choose course, week, day, and class time to view the selected lecture session.")
          ),
          
          fluidRow(
            box(
              title = "Choose Session",
              width = 12, solidHeader = FALSE,
              class = "session-filter-box",
              
              fluidRow(
                column(3, selectInput("course_filter", "Course",
                                      choices  = c("Advanced Statistics", "Linear Algebra"),
                                      selected = "Advanced Statistics", selectize = TRUE)),
                column(3, selectInput("day_filter", "Day",
                                      choices  = c("Saturday","Sunday","Monday","Tuesday","Wednesday","Thursday"),
                                      selected = "Saturday", selectize = TRUE)),
                column(3, selectInput("time_filter", "Class Time",
                                      choices  = c("1st slot","2nd slot","3rd slot","4th slot"),
                                      selected = "1st slot", selectize = TRUE)),
                column(3, selectInput("class_name_filter", "Class Name",
                                      choices  = c("Class 1","Class 2","Class 3","Class 4"),
                                      selected = "Class 1", selectize = TRUE))
              ),
              
              tags$hr(class = "session-line"),
              div(
                class = "week-scroll",
                actionButton("week_btn_all", "All", class = "week-pill active-week"),
                lapply(1:14, function(i) {
                  actionButton(paste0("week_btn_", i), paste("Week", i), class = "week-pill")
                })
              )
            )
          ),
          
          fluidRow(
            valueBoxOutput("session_students_box",    width = 3),
            valueBoxOutput("session_avg_box",          width = 3),
            valueBoxOutput("session_attendance_box",   width = 3),
            valueBoxOutput("session_questions_box",    width = 3)
          ),
          
          fluidRow(
            box(title = "Filtered Session Students", width = 12,
                class = "clean-table-box", DTOutput("session_table"))
          ),
          
          fluidRow(
            box(title = tagList(icon("chart-line"), " Exam Readiness Trend by Class"),
                width = 12, plotlyOutput("class_sequence_chart", height = 380))
          )
        ),
        
        # ── STUDENT REPORT ────────────────────────────────────────────────────
        tabItem(
          tabName = "student_report",
          
          div(class = "hero-card",
              div(class = "hero-top",
                  div(
                    div(class = "hero-title", "Student Report"),
                    div(class = "hero-subtitle",
                        "Search and analyze individual student performance, attendance, and activity insights.")
                  ),
                  div(class = "status-badge", icon("eye"), " Student Insight View")
              )
          ),

          # ── PRINT PDF BUTTON ROW ──────────────────────────────────────────
          fluidRow(
            column(12,
              div(
                style = "display: flex; justify-content: flex-end; margin-bottom: 16px;",
                actionButton(
                  "print_report_btn",
                  label  = tagList(icon("file-pdf"), " Print PDF Report"),
                  class  = "print-pdf-btn"
                )
              )
            )
          ),
          
          fluidRow(
            box(title = tagList(icon("graduation-cap"), " Coursework & Attendance Recommendation"),
                width = 12, class = "clean-table-box",
                uiOutput("report_recommendation"))
          ),
          
          fluidRow(
            box(title = tagList(icon("eye"), " Search Student"),
                width = 12, class = "student-search-box",
                textInput("student_search", "Student Name or ID",
                          placeholder = "Example: Rawan Atef or STU2026001"))
          ),
          
          fluidRow(
            valueBoxOutput("report_seventh_box",    width = 4),
            valueBoxOutput("report_twelfth_box",    width = 4),
            valueBoxOutput("report_coursework_box", width = 4)
          ),
          
          br(),
          
          fluidRow(
            valueBoxOutput("report_grade_box",      width = 3),
            valueBoxOutput("report_attendance_box", width = 3),
            valueBoxOutput("report_prediction_box", width = 3),
            valueBoxOutput("report_questions_box",  width = 3)
          ),
          
          fluidRow(
            box(title = tagList(icon("clipboard-list"), " Student Activity Summary"),
                width = 6, class = "report-box", uiOutput("student_activity_summary")),
            box(title = tagList(icon("chart-column"), " Student Performance Chart"),
                width = 6, class = "report-box",
                plotlyOutput("student_report_chart", height = 330))
          ),
          
          fluidRow(
            box(title = tagList(icon("table"), " Student Full Report"),
                width = 12, class = "clean-table-box",
                DTOutput("student_report_table"))
          )
        ),
        
        # ── ATTENDANCE ────────────────────────────────────────────────────────
        tabItem(
          tabName = "attendance",
          
          div(class = "hero-card",
              div(class = "hero-title", "Attendance Monitoring"),
              div(class = "hero-subtitle",
                  "Track attendance trends, lecture staying time, and identify students who may need support.")
          ),
          
          fluidRow(
            box(title = tagList(icon("chart-line"), " Attendance Trend by Week"),
                width = 6, plotlyOutput("attendance_trend_chart", height = 380)),
            box(title = tagList(icon("clock"), " Minutes Stayed in Lecture"),
                width = 6, plotlyOutput("minutes_stayed_chart", height = 380))
          ),
          
          fluidRow(
            box(title = tagList(icon("triangle-exclamation"), " Attendance Risk Students"),
                width = 6, DTOutput("attendance_risk_table")),
            box(title = tagList(icon("door-open"), " Lecture Staying Category"),
                width = 6, plotlyOutput("staying_category_chart", height = 350))
          )
        ),
        
        # ── SESSION (LIVE) ────────────────────────────────────────────────────
        tabItem(
          tabName = "session",
          
          div(class = "hero-card",
              div(class = "hero-title", "Live Session Camera"),
              div(class = "hero-subtitle", "AI Vision Pipeline - Face Recognition, Emotion & Activity Monitoring")
          ),
          
          fluidRow(
            box(
              title = "Live Camera Feed",
              width = 12, class = "session-box",
              uiOutput("camera_display")
            )
          ),
          
          fluidRow(
            column(
              6,
              actionButton("start_session_btn", "Start Session",
                           class = "start-session-btn", width = "100%",
                           icon = icon("play"))
            ),
            column(
              6,
              actionButton("stop_session_btn", "Stop Session",
                           class = "start-session-btn", width = "100%",
                           icon = icon("square"),
                           style = "background: linear-gradient(90deg, #dc2626, #991b1b) !important;")
            )
          ),
          
          br(),
          
          fluidRow(
            box(
              title = tagList(icon("info-circle"), " Session Status"),
              width = 12,
              verbatimTextOutput("session_status")
            )
          )
        ),
        
        # ── RAW DATA ──────────────────────────────────────────────────────────
        tabItem(
          tabName = "rawlog",
          
          div(class = "hero-card",
              div(class = "hero-title", "Raw Student Data"),
              div(class = "hero-subtitle",
                  "Full academic dataset used by the instructor dashboard.")
          ),
          
          fluidRow(
            box(title = tagList(icon("table"), " All Student Records"),
                width = 12, solidHeader = FALSE,
                DTOutput("raw_table"))
          )
        )
      )
    )
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# DATA LOADER
# ══════════════════════════════════════════════════════════════════════════════
load_student_data_app <- function() {
  
  file_path <- "students_dashboard_slots_fixed.csv"
  
  if (!file.exists(file_path)) {
    stop(paste("CSV file not found:", file_path,
               "\nMake sure the file is in the same folder as your R script."))
  }
  
  df <- read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
  
  names(df) <- trimws(names(df))
  
  numeric_cols <- c(
    "Average", "Attendance_Percentage", "Final_Prediction",
    "Questions_Asked", "Minutes_Stayed",
    "Seventh_Mark", "Twelfth_Mark", "Course_Work"
  )
  
  for (col in numeric_cols) {
    if (col %in% names(df)) df[[col]] <- as.numeric(df[[col]])
  }
  
  return(df)
}

# ══════════════════════════════════════════════════════════════════════════════
# Load Activity Data from AI Vision Pipeline Logs
# ══════════════════════════════════════════════════════════════════════════════
load_activity_data <- function() {
  possible_paths <- c(
    file.path("../data", "detections_log.csv"),
    file.path(getwd(), "data", "detections_log.csv"),
    "detections_log.csv"
  )
  
  activity_file <- NULL
  for (path in possible_paths) {
    if (file.exists(path)) {
      activity_file <- path
      break
    }
  }
  
  if (is.null(activity_file)) {
    return(data.frame(
      timestamp = character(),
      face_detected = numeric(),
      face_count = numeric(),
      emotion = character(),
      emotion_confidence = numeric(),
      sign_label = character(),
      sign_confidence = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  
  df <- read.csv(activity_file, stringsAsFactors = FALSE, check.names = FALSE)
  names(df) <- trimws(names(df))
  
  if ("timestamp" %in% names(df)) {
    df$timestamp <- as.POSIXct(df$timestamp, format = "%Y-%m-%d %H:%M:%S")
  }
  
  return(df)
}

# ══════════════════════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════════════════════
register_doctor_dashboard_server <- function(input, output, session, load_student_data_app) {
  
  data          <- reactiveVal(load_student_data_app())
  activity_data <- reactiveVal(load_activity_data())
  selected_week <- reactiveVal("All")
  
  # Week buttons
  observeEvent(input$week_btn_all, { selected_week("All") })
  lapply(1:14, function(i) {
    observeEvent(input[[paste0("week_btn_", i)]], {
      selected_week(paste("Week", i))
    }, ignoreInit = TRUE)
  })
  
  # Refresh button
  observeEvent(input$refresh_btn, {
    data(load_student_data_app())
    activity_data(load_activity_data())
    showNotification("Data and Activity Logs updated successfully", type = "message")
  }, ignoreInit = TRUE)
  
  # ── SESSION MANAGEMENT ────────────────────────────────────────────────────
  session_process <- reactiveVal(NULL)
  session_active  <- reactiveVal(FALSE)
  session_message <- reactiveVal("Ready to start session")
  
  observeEvent(input$start_session_btn, {
    if (session_active()) {
      showNotification("Session already running!", type = "warning")
      return()
    }
    
    python_path <- Sys.which("python") %||% Sys.which("python3")
    
    script_dir <- file.path(dirname(getwd()), "python_filles")
    if (!dir.exists(script_dir)) {
      script_dir <- file.path(getwd(), "python_filles")
    }
    
    main_py_path <- file.path(script_dir, "main.py")
    
    if (!file.exists(main_py_path)) {
      session_message("ERROR: main.py not found")
      showNotification("main.py not found at: " %+% main_py_path, type = "error")
      return()
    }
    
    if (python_path == "") {
      session_message("ERROR: Python not found")
      showNotification("Python not found in system PATH", type = "error")
      return()
    }
    
    script_dir <- file.path(dirname(getwd()), "python_filles")
    if (!dir.exists(script_dir)) {
      script_dir <- file.path(getwd(), "python_filles")
    }
    
    main_py_path <- file.path(script_dir, "main.py")
    
    tryCatch({
      old_wd <- getwd()
      setwd(script_dir)
      
      proc <- system2(python_path, c("main.py"),
                      stdout = NULL, stderr = NULL, wait = FALSE)
      
      setwd(old_wd)
      
      session_process(proc)
      session_active(TRUE)
      session_message("Session Started - Camera is now active")
      showNotification("AI Vision Pipeline started! Press 'q' in the camera window to stop.",
                       type = "message", duration = 5)
      
    }, error = function(e) {
      session_message(paste0("ERROR: ", as.character(e)))
      showNotification(paste("Failed to start session:", e$message), type = "error")
    })
  })
  
  observeEvent(input$stop_session_btn, {
    if (!session_active()) {
      showNotification("No session running!", type = "warning")
      return()
    }
    
    tryCatch({
      proc <- session_process()
      if (!is.null(proc)) {
        tools::pskill(proc)
      }
      session_process(NULL)
      session_active(FALSE)
      session_message("Session Stopped")
      showNotification("AI Vision Pipeline stopped.", type = "message")
    }, error = function(e) {
      showNotification("Error stopping session", type = "error")
    })
  })
  
  output$camera_display <- renderUI({
    if (session_active()) {
      div(
        style = "
          width: 100%; height: 500px;
          background: #000;
          border-radius: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #22c55e;
          font-size: 18px;
          font-weight: bold;
          text-align: center;
          padding: 20px;
          box-sizing: border-box;
        ",
        div(
          "\U0001F4F9 AI Vision Pipeline Active",
          br(),
          "Camera feed is running in OpenCV window",
          br(), br(),
          "Monitoring: Face Recognition \u2022 Emotion Detection \u2022 Sign Language \u2022 Activity Level",
          br(),
          "Close the camera window or click 'Stop Session' to end recording"
        )
      )
    } else {
      div(
        style = "
          width: 100%; height: 500px;
          background: #0f172a;
          border-radius: 16px;
          border: 2px dashed #06b6d4;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #94a3b8;
          font-size: 18px;
        ",
        "Click 'Start Session' to open camera feed"
      )
    }
  })
  
  output$session_status <- renderText({
    status <- ifelse(session_active(), "\U0001F534 ACTIVE", "\U0001F7E2 INACTIVE")
    paste0(
      "Status: ", status, "\n",
      "Message: ", session_message(), "\n",
      "\nThe AI Vision Pipeline monitors:\n",
      "\u2022 Face Detection & Recognition\n",
      "\u2022 Emotion Detection & Confidence\n",
      "\u2022 Sign Language Detection\n",
      "\u2022 Student Activity & Participation\n",
      "\u2022 Automatic CSV Logging (1 sec intervals)"
    )
  })
  
  # Sync Class Name -> Time slot
  observeEvent(input$class_name_filter, {
    slot_map <- c("Class 1" = "1st slot", "Class 2" = "2nd slot",
                  "Class 3" = "3rd slot", "Class 4" = "4th slot")
    updateSelectInput(session, "time_filter",
                      selected = slot_map[input$class_name_filter])
  })
  
  # ── REACTIVE FILTERS ──────────────────────────────────────────────────────
  filtered_course_data <- reactive({
    df <- data()
    if ("Course" %in% names(df)) df <- df %>% filter(Course == input$course_filter)
    df
  })
  
  filtered_session_data <- reactive({
    df <- data()
    req(input$class_name_filter, input$course_filter,
        input$day_filter, input$time_filter)
    
    needed <- c("Class_Name", "Course", "Week", "Day", "Class_Time")
    if (!all(needed %in% names(df))) return(df[0, ])
    
    df <- df %>%
      filter(
        Class_Name == input$class_name_filter,
        Course     == input$course_filter,
        Day        == input$day_filter,
        Class_Time == input$time_filter
      )
    
    if (selected_week() != "All") df <- df %>% filter(Week == selected_week())
    df
  })
  
  student_report_data <- reactive({
    df     <- data()
    search <- trimws(input$student_search)
    if (is.null(search) || search == "") return(df[0, ])
    df %>% filter(
      grepl(search, Student_Name, ignore.case = TRUE) |
        grepl(search, Student_ID,   ignore.case = TRUE)
    )
  })
  
  # ── OVERVIEW VALUE BOXES ──────────────────────────────────────────────────
  output$total_students_box <- renderValueBox({
    valueBox(nrow(data()), "Total Students", icon = icon("users"), color = "blue")
  })
  
  output$avg_score_box <- renderValueBox({
    df  <- data()
    val <- if (nrow(df) > 0) round(mean(df$Average, na.rm = TRUE), 1) else "N/A"
    valueBox(val, "Class Average Score", icon = icon("graduation-cap"), color = "green")
  })
  
  output$attendance_box <- renderValueBox({
    df  <- data()
    val <- if (nrow(df) > 0)
      paste0(round(mean(df$Attendance_Percentage, na.rm = TRUE), 1), "%") else "N/A"
    valueBox(val, "Avg Attendance", icon = icon("calendar-check"), color = "red")
  })
  
  output$avg_prediction_box <- renderValueBox({
    df  <- filtered_course_data()
    val <- if ("Final_Prediction" %in% names(df) && nrow(df) > 0)
      paste0(round(mean(df$Final_Prediction, na.rm = TRUE), 1), "%") else "N/A"
    valueBox(val, "Avg Final Prediction", icon = icon("chart-line"), color = "purple")
  })
  
  # ── OVERVIEW CHARTS ───────────────────────────────────────────────────────
  output$course_avg_chart <- renderPlotly({
    df <- data()
    if (!all(c("Course", "Average") %in% names(df)) || nrow(df) == 0) return(plotly_empty())
    
    chart_df <- data.frame(Course = c("Advanced Statistics", "Linear Algebra")) %>%
      left_join(
        df %>% group_by(Course) %>%
          summarise(Average = round(mean(Average, na.rm = TRUE), 1), .groups = "drop"),
        by = "Course"
      ) %>%
      mutate(Average = ifelse(is.na(Average), 0, Average))
    
    plot_ly(chart_df, x = ~Course, y = ~Average, type = "bar",
            marker = list(color = c("#7c3aed", "#06b6d4"))) %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
             font = list(color = "#e5e7eb"),
             xaxis = list(title = "Course"),
             yaxis = list(title = "Average", range = c(0, 100)))
  })
  
  output$activity_pie_chart <- renderPlotly({
    df <- filtered_course_data()
    if (!"Activity_Level" %in% names(df) || nrow(df) == 0) return(plotly_empty())
    counts <- as.data.frame(table(df$Activity_Level))
    plot_ly(counts, labels = ~Var1, values = ~Freq, type = "pie") %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", font = list(color = "#e5e7eb"))
  })
  
  # ── ACTIVITY VALUE BOXES ──────────────────────────────────────────────────
  output$total_questions_box <- renderValueBox({
    df  <- filtered_course_data()
    val <- if ("Questions_Asked" %in% names(df) && nrow(df) > 0)
      sum(df$Questions_Asked, na.rm = TRUE) else "N/A"
    valueBox(val, "Total Questions", icon = icon("circle-question"), color = "yellow")
  })
  
  output$avg_questions_box <- renderValueBox({
    df  <- filtered_course_data()
    val <- if ("Questions_Asked" %in% names(df) && nrow(df) > 0)
      round(mean(df$Questions_Asked, na.rm = TRUE), 1) else "N/A"
    valueBox(val, "Avg Questions", icon = icon("chart-simple"), color = "blue")
  })
  
  output$high_activity_box <- renderValueBox({
    df  <- filtered_course_data()
    val <- if ("Activity_Level" %in% names(df) && nrow(df) > 0)
      sum(df$Activity_Level == "High", na.rm = TRUE) else "N/A"
    valueBox(val, "High Activity", icon = icon("bolt"), color = "green")
  })
  
  output$low_activity_box <- renderValueBox({
    df  <- filtered_course_data()
    val <- if ("Activity_Level" %in% names(df) && nrow(df) > 0)
      sum(df$Activity_Level == "Low", na.rm = TRUE) else "N/A"
    valueBox(val, "Low Activity", icon = icon("triangle-exclamation"), color = "red")
  })
  
  # ── ACTIVITY CHARTS ───────────────────────────────────────────────────────
  output$questions_chart <- renderPlotly({
    df <- filtered_course_data()
    if (!all(c("Student_Name", "Questions_Asked") %in% names(df)) || nrow(df) == 0)
      return(plotly_empty())
    plot_ly(df, x = ~Student_Name, y = ~Questions_Asked, type = "bar",
            marker = list(color = "#f59e0b")) %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
             font = list(color = "#e5e7eb"),
             xaxis = list(title = "Student"),
             yaxis = list(title = "Questions Asked"))
  })
  
  output$activity_level_pie <- renderPlotly({
    df <- filtered_course_data()
    if (!"Activity_Level" %in% names(df) || nrow(df) == 0) return(plotly_empty())
    counts <- as.data.frame(table(df$Activity_Level))
    plot_ly(counts, labels = ~Var1, values = ~Freq, type = "pie") %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", font = list(color = "#e5e7eb"))
  })
  
  output$most_active_table <- renderDT({
    df <- filtered_course_data()
    needed <- c("Student_ID", "Student_Name", "Questions_Asked", "Minutes_Stayed", "Activity_Level")
    if (!all(needed %in% names(df)) || nrow(df) == 0)
      return(datatable(data.frame(Message = "No data."), options = list(dom = "t"), rownames = FALSE))
    df %>% select(all_of(needed)) %>%
      arrange(desc(Questions_Asked), desc(Minutes_Stayed)) %>%
      datatable(options = list(pageLength = 6, dom = "tip"), rownames = FALSE)
  })
  
  output$activity_minutes_chart <- renderPlotly({
    df <- filtered_course_data()
    if (!all(c("Student_Name", "Questions_Asked", "Minutes_Stayed") %in% names(df)) || nrow(df) == 0)
      return(plotly_empty())
    plot_ly(df, x = ~Minutes_Stayed, y = ~Questions_Asked,
            text = ~Student_Name, type = "scatter", mode = "markers",
            marker = list(size = 11, opacity = 0.85)) %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
             font = list(color = "#e5e7eb"),
             xaxis = list(title = "Minutes Stayed"),
             yaxis = list(title = "Questions Asked"))
  })
  
  # ── SESSION FILTER VALUE BOXES ────────────────────────────────────────────
  output$session_students_box <- renderValueBox({
    valueBox(nrow(filtered_session_data()), "Session Students",
             icon = icon("users"), color = "blue")
  })
  
  output$session_avg_box <- renderValueBox({
    df  <- filtered_session_data()
    val <- if (nrow(df) > 0) round(mean(df$Average, na.rm = TRUE), 1) else "N/A"
    valueBox(val, "Session Average", icon = icon("calculator"), color = "green")
  })
  
  output$session_attendance_box <- renderValueBox({
    df  <- filtered_session_data()
    val <- if (nrow(df) > 0)
      paste0(round(mean(df$Attendance_Percentage, na.rm = TRUE), 1), "%") else "N/A"
    valueBox(val, "Session Attendance", icon = icon("calendar-check"), color = "yellow")
  })
  
  output$session_questions_box <- renderValueBox({
    df  <- filtered_session_data()
    val <- if ("Questions_Asked" %in% names(df) && nrow(df) > 0)
      sum(df$Questions_Asked, na.rm = TRUE) else "N/A"
    valueBox(val, "Questions Asked", icon = icon("circle-question"), color = "red")
  })
  
  # ── SESSION TABLE ─────────────────────────────────────────────────────────
  output$session_table <- renderDT({
    df        <- filtered_session_data()
    show_cols <- c("Student_ID","Student_Name","Grade","Average",
                   "Attendance_Percentage","Final_Prediction",
                   "Questions_Asked","Minutes_Stayed","Activity_Level")
    show_cols <- show_cols[show_cols %in% names(df)]
    
    if (nrow(df) == 0)
      return(datatable(data.frame(Message = "No data for this session."),
                       options = list(dom = "t"), rownames = FALSE))
    
    datatable(df[, show_cols],
              options = list(pageLength = 5, scrollX = FALSE, dom = "tip"),
              rownames = FALSE)
  })
  
  # ── EXAM READINESS TREND ──────────────────────────────────────────────────
  output$class_sequence_chart <- renderPlotly({
    df <- filtered_session_data()
    if (nrow(df) == 0) return(plotly_empty())
    
    chart_df <- df %>%
      group_by(Week) %>%
      summarise(
        Avg_Attendance = mean(Attendance_Percentage, na.rm = TRUE),
        Avg_Score      = mean(Average, na.rm = TRUE),
        Avg_Questions  = mean(Questions_Asked, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        Week_Num = as.numeric(gsub("Week ", "", Week)),
        Readiness_Score = round(
          (Avg_Attendance * 0.35) +
            (Avg_Score      * 0.50) +
            ((Avg_Questions / 6) * 100 * 0.15), 1),
        Exam_Recommendation = case_when(
          Readiness_Score < 65 ~ "Easy Exam Recommended",
          Readiness_Score < 80 ~ "Moderate Exam Recommended",
          TRUE                 ~ "Challenging Exam Possible"
        )
      ) %>%
      arrange(Week_Num)
    
    week_levels <- chart_df$Week
    
    plot_ly(chart_df, x = ~factor(Week, levels = week_levels)) %>%
      add_lines(y = ~Readiness_Score, name = "Class Readiness Score",
                line = list(width = 5),
                text  = ~paste("Week:", Week,
                               "<br>Readiness:", Readiness_Score,
                               "<br>Recommendation:", Exam_Recommendation),
                hoverinfo = "text") %>%
      add_markers(y = ~Readiness_Score, name = "Weekly Point",
                  marker = list(size = 10), hoverinfo = "text") %>%
      layout(
        title = paste("Exam Readiness Trend -", input$class_name_filter),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
        font = list(color = "#e5e7eb"),
        xaxis = list(title = "Week", categoryorder = "array",
                     categoryarray = week_levels),
        yaxis = list(title = "Readiness Score", range = c(0, 100)),
        shapes = list(
          list(type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = 0,  y1 = 65,
               fillcolor = "rgba(239,68,68,0.12)",   line = list(width = 0)),
          list(type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = 65, y1 = 80,
               fillcolor = "rgba(245,158,11,0.12)",  line = list(width = 0)),
          list(type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = 80, y1 = 100,
               fillcolor = "rgba(34,197,94,0.12)",   line = list(width = 0))
        )
      )
  })
  
  # ── STUDENT REPORT VALUE BOXES ────────────────────────────────────────────
  output$report_seventh_box <- renderValueBox({
    df  <- student_report_data()
    val <- if (nrow(df) > 0) paste0(df$Seventh_Mark[1], " / 30") else "N/A"
    valueBox(val, "7th Exam", icon = icon("pen"), color = "blue")
  })
  
  output$report_twelfth_box <- renderValueBox({
    df  <- student_report_data()
    val <- if (nrow(df) > 0) paste0(df$Twelfth_Mark[1], " / 20") else "N/A"
    valueBox(val, "12th Exam", icon = icon("file-lines"), color = "purple")
  })
  
  output$report_coursework_box <- renderValueBox({
    df  <- student_report_data()
    val <- if (nrow(df) > 0) paste0(df$Course_Work[1], " / 10") else "N/A"
    valueBox(val, "Course Work", icon = icon("clipboard-check"), color = "green")
  })
  
  output$report_grade_box <- renderValueBox({
    df  <- student_report_data()
    val <- if (nrow(df) > 0) df$Grade[1] else "N/A"
    valueBox(val, "Grade", icon = icon("award"), color = "purple")
  })
  
  output$report_attendance_box <- renderValueBox({
    df  <- student_report_data()
    val <- if (nrow(df) > 0) paste0(df$Attendance_Percentage[1], "%") else "N/A"
    valueBox(val, "Attendance", icon = icon("clipboard-check"), color = "green")
  })
  
  output$report_prediction_box <- renderValueBox({
    df  <- student_report_data()
    val <- if ("Final_Prediction" %in% names(df) && nrow(df) > 0)
      paste0(df$Final_Prediction[1], "%") else "N/A"
    valueBox(val, "Final Prediction", icon = icon("chart-line"), color = "blue")
  })
  
  output$report_questions_box <- renderValueBox({
    df  <- student_report_data()
    val <- if ("Questions_Asked" %in% names(df) && nrow(df) > 0)
      df$Questions_Asked[1] else "N/A"
    valueBox(val, "Questions Asked", icon = icon("circle-question"), color = "yellow")
  })
  
  # ── STUDENT REPORT UI ─────────────────────────────────────────────────────
  output$report_recommendation <- renderUI({
    df <- student_report_data()
    if (nrow(df) == 0) return(tags$p("Search for a student to see recommendation."))
    tags$div(
      style = "background:#0f172a; padding:15px; border-radius:12px;
               border-left:4px solid #7c3aed; color:#e5e7eb; font-weight:500;",
      tags$strong("Recommendation: "), df$Course_Work_Recommendation[1]
    )
  })
  
  output$student_activity_summary <- renderUI({
    df <- student_report_data()
    if (nrow(df) == 0) return(tags$p("Search for a student to view activity summary."))
    tags$div(
      tags$p(tags$strong("Student: "),    df$Student_Name[1]),
      tags$p(tags$strong("Student ID: "), df$Student_ID[1]),
      tags$p(tags$strong("Minutes Stayed: "),
             if ("Minutes_Stayed"  %in% names(df)) df$Minutes_Stayed[1]  else "N/A"),
      tags$p(tags$strong("Activity Level: "),
             if ("Activity_Level"  %in% names(df)) df$Activity_Level[1]  else "N/A")
    )
  })
  
  output$student_report_chart <- renderPlotly({
    df <- student_report_data()
    if (nrow(df) == 0) {
      return(plot_ly() %>%
               layout(paper_bgcolor = "rgba(0,0,0,0)",
                      plot_bgcolor  = "rgba(15,23,42,0.4)",
                      font = list(color = "#e5e7eb"),
                      xaxis = list(visible = FALSE), yaxis = list(visible = FALSE),
                      annotations = list(
                        text = "Search for a student to view performance chart",
                        x = 0.5, y = 0.5, showarrow = FALSE,
                        font = list(size = 15, color = "#cbd5e1"))))
    }
    plot_ly(
      x = c("Attendance", "Average", "Final Prediction"),
      y = c(df$Attendance_Percentage[1], df$Average[1], df$Final_Prediction[1]),
      type = "bar",
      marker = list(color = c("#06b6d4", "#7c3aed", "#22c55e"))
    ) %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
             font = list(color = "#e5e7eb"),
             yaxis = list(title = "Percentage", range = c(0, 100)))
  })
  
  output$student_report_table <- renderDT({
    datatable(student_report_data(),
              options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })
  
  # ── ATTENDANCE CHARTS ─────────────────────────────────────────────────────
  output$attendance_trend_chart <- renderPlotly({
    df <- filtered_course_data()
    if (!all(c("Week", "Attendance_Percentage") %in% names(df)) || nrow(df) == 0)
      return(plotly_empty())
    
    trend_df <- df %>%
      mutate(Week_Num = as.numeric(gsub("Week ", "", Week))) %>%
      group_by(Week, Week_Num) %>%
      summarise(Avg_Attendance = round(mean(Attendance_Percentage, na.rm = TRUE), 1),
                .groups = "drop") %>%
      arrange(Week_Num)
    
    plot_ly(trend_df, x = ~factor(Week, levels = trend_df$Week),
            y = ~Avg_Attendance, type = "scatter", mode = "lines+markers",
            line = list(width = 4), marker = list(size = 9)) %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
             font = list(color = "#e5e7eb"),
             xaxis = list(title = "Week"),
             yaxis = list(title = "Average Attendance %", range = c(0, 100)))
  })
  
  output$minutes_stayed_chart <- renderPlotly({
    df <- filtered_course_data()
    if (!all(c("Student_Name", "Minutes_Stayed") %in% names(df)) || nrow(df) == 0)
      return(plotly_empty())
    plot_ly(df, x = ~Student_Name, y = ~Minutes_Stayed, type = "bar",
            marker = list(color = "#06b6d4")) %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(15,23,42,0.4)",
             font = list(color = "#e5e7eb"),
             xaxis = list(title = "Student"),
             yaxis = list(title = "Minutes Stayed"))
  })
  
  output$attendance_risk_table <- renderDT({
    df <- filtered_course_data()
    needed <- c("Student_ID", "Student_Name", "Attendance_Percentage")
    if (!all(needed %in% names(df)) || nrow(df) == 0)
      return(datatable(data.frame(Message = "No attendance data."),
                       options = list(dom = "t"), rownames = FALSE))
    
    df %>%
      mutate(Risk_Level = case_when(
        Attendance_Percentage < 60 ~ "High Risk",
        Attendance_Percentage < 75 ~ "Medium Risk",
        TRUE                       ~ "Safe"
      )) %>%
      select(Student_ID, Student_Name, Attendance_Percentage, Risk_Level) %>%
      arrange(Attendance_Percentage) %>%
      datatable(options = list(pageLength = 6, dom = "tip"), rownames = FALSE)
  })
  
  output$staying_category_chart <- renderPlotly({
    df <- filtered_course_data()
    if (!"Minutes_Stayed" %in% names(df) || nrow(df) == 0) return(plotly_empty())
    
    counts <- df %>%
      mutate(Staying_Category = case_when(
        Minutes_Stayed < 80   ~ "Early Exit",
        Minutes_Stayed >= 100 ~ "Highly Engaged",
        TRUE                  ~ "Normal Stay"
      )) %>%
      { as.data.frame(table(.$Staying_Category)) }
    
    plot_ly(counts, labels = ~Var1, values = ~Freq, type = "pie") %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)",
             font = list(color = "#e5e7eb"), showlegend = TRUE)
  })
  
  # ── RAW DATA TABLE ────────────────────────────────────────────────────────
  output$raw_table <- renderDT({
    datatable(data(),
              options = list(pageLength = 20, scrollX = TRUE),
              class   = "table-dark table-bordered table-hover")
  })
}