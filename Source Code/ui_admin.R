make_admin_dashboard_ui <- function() {
  dashboardPage(
    skin = "black",
    dashboardHeader(title = ""),
    dashboardSidebar(
      div(class = "brand-panel",
          div(class = "brand-icon", icon("user-tie")),
          div(class = "brand-title", "Dean's Portal"),
          div(class = "brand-subtitle", "Full System Access")
      ),
      sidebarMenu(
        id = "admin_tabs",
        menuItem("College Overview",   tabName = "admin_overview",  icon = icon("chart-line")),
        menuItem("Doctor Performance", tabName = "admin_doctors",   icon = icon("chalkboard-user")),
        menuItem("Subject Analytics",  tabName = "admin_subjects",  icon = icon("book-open")),
        menuItem("GPA Trend",          tabName = "admin_gpa",       icon = icon("arrow-trend-up")),
        menuItem("At-Risk Students",   tabName = "admin_risk",      icon = icon("triangle-exclamation")),
        menuItem("College Rankings",   tabName = "admin_rankings",  icon = icon("trophy")),
        menuItem("Doctor Dashboard",   tabName = "admin_doc_view",  icon = icon("stethoscope"))
      ),
      div(
        style = "padding: 15px; display: flex; justify-content: center;",
        actionButton(
          "admin_refresh_btn",
          "Update Data",
          icon = icon("rotate"),
          class = "admin-refresh-button",
          style = "width:85%;"
        )
      ),
      div(
        class = "sidebar-footer",
        div(class = "live-dot"),
        span("Dean Access Active"),
        br(), br(),
        actionButton("admin_logout_btn", "Logout",
                     icon = icon("right-from-bracket"), class = "logout-button")
      )
    ),
    dashboardBody(
      tags$head(tags$style(HTML(paste0(
        ".main-header{display:none!important;}",
        "html,body{height:100%!important;margin:0!important;padding:0!important;overflow-x:hidden!important;overflow-y:auto!important;}",
        "body,.content-wrapper,.right-side{",
        "background:radial-gradient(circle at 15% 10%,rgba(37,99,235,.30),transparent 30%),",
        "radial-gradient(circle at 85% 0%,rgba(147,51,234,.28),transparent 32%),",
        "linear-gradient(135deg,#020617 0%,#0f172a 45%,#111827 100%);",
        "color:#e5e7eb;font-family:'Segoe UI',Arial,sans-serif;}",
        ".wrapper{min-height:100vh!important;}",
        ".content-wrapper,.right-side{position:fixed!important;top:0!important;left:230px!important;",
        "right:0!important;bottom:0!important;margin-left:0!important;padding:22px!important;",
        "min-height:100vh!important;max-height:100vh!important;overflow-y:scroll!important;overflow-x:hidden!important;-webkit-overflow-scrolling:touch!important;}",
        ".content-wrapper{padding-top:22px!important;}.content{padding-top:0!important;}",
        ".main-sidebar{position:fixed!important;top:0!important;left:0!important;bottom:0!important;",
        "width:230px!important;height:100vh!important;min-height:100vh!important;",
        "background:rgba(2,6,23,.98)!important;border-right:1px solid rgba(255,255,255,.08);",
        "box-shadow:10px 0 35px rgba(0,0,0,.40);padding-top:0!important;",
        "overflow-y:auto!important;overflow-x:hidden!important;}",
        ".main-sidebar .sidebar{min-height:100vh!important;padding-top:20px!important;padding-bottom:170px!important;}",
        ".main-sidebar::-webkit-scrollbar{width:6px;}",
        ".main-sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.2);border-radius:10px;}",
        ".brand-panel{padding:18px;text-align:center;}",
        ".brand-icon{width:64px;height:64px;margin:auto;border-radius:22px;",
        "background:linear-gradient(135deg,#2563eb,#7c3aed);color:white;",
        "display:flex;align-items:center;justify-content:center;font-size:26px;",
        "box-shadow:0 16px 35px rgba(37,99,235,.45);}",
        ".brand-title{margin-top:14px;font-size:17px;font-weight:900;color:white;}",
        ".brand-subtitle{font-size:12px;color:#94a3b8;margin-top:5px;}",
        ".sidebar-menu>li>a{color:#cbd5e1!important;font-weight:700;margin:8px 13px;border-radius:18px;padding:14px 16px;}",
        ".sidebar-menu>li.active>a,.sidebar-menu>li:hover>a{",
        "background:linear-gradient(90deg,#2563eb,#7c3aed)!important;color:white!important;",
        "border-left:none!important;box-shadow:0 12px 24px rgba(37,99,235,.32);}",
        ".sidebar-footer{position:fixed!important;bottom:24px!important;left:0!important;",
        "width:230px!important;text-align:center;color:#94a3b8;font-size:12px;",
        "padding:12px;z-index:9999;background:rgba(2,6,23,.98);}",
        ".live-dot{width:10px;height:10px;background:#22c55e;display:inline-block;",
        "border-radius:50%;box-shadow:0 0 16px #22c55e;margin-right:7px;}",
        ".admin-refresh-button{width:85%!important;background:linear-gradient(90deg,#2563eb,#7c3aed)!important;",
        "color:white!important;border:none!important;border-radius:999px!important;",
        "padding:11px 24px!important;font-weight:900;",
        "box-shadow:0 12px 28px rgba(37,99,235,.38)!important;}",
        ".admin-refresh-button:hover{transform:translateY(-2px);box-shadow:0 16px 34px rgba(124,58,237,.42)!important;}",
        ".logout-button{width:85%!important;",
        "background:linear-gradient(90deg,#dc2626,#991b1b)!important;",
        "color:white!important;border:none!important;border-radius:999px!important;",
        "padding:11px 24px!important;font-weight:900;",
        "box-shadow:0 12px 28px rgba(220,38,38,.30);}",
        ".hero-card{background:linear-gradient(135deg,rgba(37,99,235,.25),rgba(124,58,237,.22)),rgba(15,23,42,.82);",
        "border:1px solid rgba(255,255,255,.12);border-radius:30px;padding:30px;margin-bottom:24px;",
        "box-shadow:0 28px 70px rgba(0,0,0,.42);backdrop-filter:blur(16px);",
        "position:relative;overflow:hidden!important;}",
        ".hero-card::after{content:'';position:absolute;right:-80px;top:-80px;width:240px;height:240px;",
        "background:radial-gradient(circle,rgba(6,182,212,.22),transparent 70%);border-radius:50%;}",
        ".hero-top{display:flex;justify-content:space-between;align-items:center;gap:15px;position:relative;z-index:2;}",
        ".hero-title{font-size:32px;font-weight:900;color:white;margin-bottom:8px;}",
        ".hero-subtitle{color:#cbd5e1;font-size:14px;line-height:1.7;}",
        ".status-badge{background:rgba(6,182,212,.16)!important;color:#67e8f9!important;",
        "border:1px solid rgba(6,182,212,.40)!important;padding:10px 18px;border-radius:999px;",
        "font-weight:800;white-space:nowrap;box-shadow:0 10px 30px rgba(6,182,212,.12);}",
        ".box{background:rgba(15,23,42,.86);border-radius:26px;border:1px solid rgba(255,255,255,.10);",
        "box-shadow:0 20px 50px rgba(0,0,0,.36);border-top:none!important;",
        "overflow:visible!important;backdrop-filter:blur(14px);}",
        ".box-header{color:white;background:rgba(255,255,255,.04);",
        "border-bottom:1px solid rgba(255,255,255,.08);padding:16px 20px;}",
        ".box-title{font-weight:900;font-size:16px;}.box-body{color:#e5e7eb;padding:20px;}",
        ".small-box{border-radius:26px;box-shadow:0 20px 45px rgba(0,0,0,.36);",
        "overflow:hidden!important;border:1px solid rgba(255,255,255,.12);}",
        ".small-box{min-height:190px!important;}",
        ".small-box h3{font-weight:900!important;font-size:20px!important;line-height:1.28!important;white-space:normal!important;overflow:visible!important;text-overflow:unset!important;word-break:normal!important;max-width:100%!important;}",
        ".small-box p{white-space:normal!important;font-size:15px!important;line-height:1.25!important;}",
        ".small-box .inner{padding-right:58px!important;padding-top:18px!important;}",
        ".small-box p{font-weight:800;}.small-box .icon{opacity:.24;}",
        ".dataTables_wrapper{color:#e5e7eb;width:100%!important;overflow-x:auto!important;}",
        "table.dataTable{width:100%!important;border-collapse:collapse!important;font-size:13px!important;}",
        "table.dataTable thead th{background:rgba(15,23,42,.95)!important;color:#e5e7eb!important;",
        "font-weight:800!important;padding:12px 10px!important;",
        "border-bottom:1px solid rgba(255,255,255,.12)!important;white-space:nowrap!important;}",
        "table.dataTable tbody td{color:#e5e7eb!important;padding:12px 10px!important;",
        "border-bottom:1px solid rgba(255,255,255,.06)!important;white-space:nowrap!important;}",
        "table.dataTable tbody tr{background-color:transparent!important;}",
        "table.dataTable tbody tr:hover{background:linear-gradient(90deg,rgba(37,99,235,.18),rgba(124,58,237,.18))!important;color:#e5e7eb!important;}",
        "table.dataTable tbody tr.selected{background-color:rgba(124,58,237,.25)!important;color:white!important;}",
        ".dataTables_length,.dataTables_filter{margin-bottom:14px!important;}",
        ".dataTables_filter input,.dataTables_length select{background:rgba(255,255,255,.08)!important;",
        "color:white!important;border:1px solid rgba(255,255,255,.18)!important;",
        "border-radius:10px!important;padding:7px 10px!important;}",
        ".doctor-card{background:rgba(15,23,42,.86);border:1px solid rgba(255,255,255,.10);",
        "border-radius:18px;padding:16px;margin-bottom:12px;",
        "transition:border-color .2s,box-shadow .2s;}",
        ".doctor-card:hover{border-color:rgba(37,99,235,.55);box-shadow:0 8px 24px rgba(37,99,235,.18);}",
        ".stat-chip{display:inline-block;padding:4px 12px;border-radius:999px;font-size:11px;font-weight:800;margin:3px 2px;}",
        ".chip-blue{background:rgba(37,99,235,.22);color:#60a5fa;}",
        ".chip-green{background:rgba(34,197,94,.18);color:#4ade80;}",
        ".chip-purple{background:rgba(124,58,237,.22);color:#c084fc;}",
        ".chip-yellow{background:rgba(245,158,11,.18);color:#fbbf24;}",
        ".college-health-card{background:linear-gradient(135deg,rgba(37,99,235,.25),rgba(124,58,237,.22)),rgba(15,23,42,.82);",
        "border:1px solid rgba(37,99,235,.35);border-radius:20px;padding:28px;text-align:center;}",
        ".health-score-num{font-size:72px;font-weight:900;",
        "background:linear-gradient(135deg,#38bdf8,#818cf8);",
        "-webkit-background-clip:text;-webkit-text-fill-color:transparent;line-height:1;}",
        ".shiny-input-container label{color:#e5e7eb!important;font-weight:900!important;margin-bottom:8px!important;}",
        ".clean-table-box .box-body{padding:18px!important;}",
        ".admin-filter-bar{display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;",
        "background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.09);",
        "border-radius:16px;padding:14px 18px;margin-bottom:16px;}",
        ".admin-filter-bar .shiny-input-container{margin:0!important;min-width:150px;}",
        ".admin-filter-bar label{color:#94a3b8!important;font-size:11px!important;",
        "font-weight:800!important;text-transform:uppercase;letter-spacing:.6px;margin-bottom:5px!important;}",
        ".admin-filter-bar .form-control,.admin-filter-bar select,",
        ".admin-filter-bar .selectize-input{",
        "background:rgba(255,255,255,.07)!important;color:#e5e7eb!important;",
        "border:1px solid rgba(255,255,255,.14)!important;border-radius:10px!important;",
        "font-size:13px!important;padding:7px 11px!important;}",
        ".filter-reset-btn{background:rgba(239,68,68,.18)!important;color:#fca5a5!important;",
        "border:1px solid rgba(239,68,68,.35)!important;border-radius:10px!important;",
        "padding:6px 16px!important;font-weight:800!important;font-size:12px!important;height:36px;}",
        ".filter-reset-btn:hover{background:rgba(239,68,68,.32)!important;}",
        ".filter-results-badge{background:rgba(99,102,241,.18);color:#a5b4fc;",
        "border:1px solid rgba(99,102,241,.30);border-radius:999px;",
        "padding:3px 12px;font-size:12px;font-weight:800;}",
        
        "select.form-control option{background:#0f172a!important;color:#e5e7eb!important;font-weight:800!important;}",
        "select.form-control:focus{outline:none!important;border-color:#38bdf8!important;box-shadow:0 0 0 3px rgba(6,182,212,.18)!important;}"
      )))),
      
      tags$style(HTML("\n/* ===== PREMIUM DROPDOWN FIX - ALL DASHBOARDS ===== */\n.selectize-control { width: 100% !important; z-index: 9999 !important; }\n.selectize-control.single .selectize-input,\n.selectize-input {\n  min-height: 52px !important;\n  height: 52px !important;\n  background: rgba(15,23,42,0.96) !important;\n  color: #e5e7eb !important;\n  border: 1px solid rgba(6,182,212,0.65) !important;\n  border-radius: 18px !important;\n  padding: 15px 46px 12px 18px !important;\n  font-size: 15px !important;\n  font-weight: 900 !important;\n  box-shadow: 0 0 0 3px rgba(6,182,212,0.08), 0 12px 28px rgba(0,0,0,0.32) !important;\n}\n.selectize-input.full,\n.selectize-input.focus,\n.selectize-input.dropdown-active {\n  background: rgba(15,23,42,0.98) !important;\n  color: #ffffff !important;\n  border-color: #38bdf8 !important;\n  box-shadow: 0 0 22px rgba(6,182,212,0.32), 0 12px 30px rgba(0,0,0,0.42) !important;\n}\n.selectize-input > input { color: #e5e7eb !important; font-weight: 800 !important; }\n.selectize-dropdown {\n  background: #0f172a !important;\n  border: 1px solid rgba(6,182,212,0.65) !important;\n  border-radius: 18px !important;\n  overflow: hidden !important;\n  z-index: 999999 !important;\n  box-shadow: 0 22px 50px rgba(0,0,0,0.55) !important;\n}\n.selectize-dropdown-content { max-height: 260px !important; }\n.selectize-dropdown .option,\n.selectize-dropdown-content .option {\n  background: #0f172a !important;\n  color: #e5e7eb !important;\n  padding: 14px 18px !important;\n  font-size: 15px !important;\n  font-weight: 900 !important;\n}\n.selectize-dropdown .option.active,\n.selectize-dropdown .option:hover,\n.selectize-dropdown-content .option.active {\n  background: linear-gradient(90deg, #2563eb, #7c3aed) !important;\n  color: #ffffff !important;\n}\n.selectize-control.single .selectize-input:after {\n  border-color: #38bdf8 transparent transparent transparent !important;\n  right: 18px !important;\n  border-width: 7px 7px 0 7px !important;\n}\n.shiny-input-container label {\n  color: #e5e7eb !important;\n  font-weight: 900 !important;\n  font-size: 14px !important;\n  margin-bottom: 9px !important;\n}\n.admin-filter-bar {\n  overflow: visible !important;\n  position: relative !important;\n  z-index: 20 !important;\n}\n.admin-filter-bar .shiny-input-container { min-width: 230px !important; }\n.box, .box-body { overflow: visible !important; }\n.content-wrapper, .right-side { overflow-y: auto !important; overflow-x: hidden !important; }\nbody.light-mode .selectize-input,\nbody.light-mode .selectize-control.single .selectize-input {\n  background: #ffffff !important;\n  color: #0f172a !important;\n  border-color: rgba(37,99,235,0.40) !important;\n}\nbody.light-mode .selectize-dropdown,\nbody.light-mode .selectize-dropdown .option,\nbody.light-mode .selectize-dropdown-content .option {\n  background: #ffffff !important;\n  color: #0f172a !important;\n}\nbody.light-mode .selectize-dropdown .option.active,\nbody.light-mode .selectize-dropdown-content .option.active {\n  background: linear-gradient(90deg, #2563eb, #7c3aed) !important;\n  color: #ffffff !important;\n}\n")),
      tags$style(HTML('\n/* ===== FINAL NATIVE DROPDOWN FIX - CLICKABLE ===== */\n.admin-filter-bar,\n.admin-filter-bar .shiny-input-container,\n.box,\n.box-body,\n.content-wrapper,\n.right-side {\n  overflow: visible !important;\n}\n\n.admin-filter-bar select.form-control,\nselect.form-control {\n  display: block !important;\n  width: 100% !important;\n  min-width: 210px !important;\n  height: 54px !important;\n  cursor: pointer !important;\n  pointer-events: auto !important;\n  appearance: auto !important;\n  -webkit-appearance: menulist !important;\n  -moz-appearance: auto !important;\n  background: rgba(15,23,42,0.98) !important;\n  color: #e5e7eb !important;\n  border: 1px solid rgba(6,182,212,0.75) !important;\n  border-radius: 18px !important;\n  padding: 12px 18px !important;\n  font-size: 15px !important;\n  font-weight: 900 !important;\n  box-shadow: 0 0 0 3px rgba(6,182,212,0.08), 0 12px 28px rgba(0,0,0,0.32) !important;\n}\n\n.admin-filter-bar select.form-control:hover,\nselect.form-control:hover {\n  border-color: #38bdf8 !important;\n  box-shadow: 0 0 22px rgba(6,182,212,0.35), 0 12px 30px rgba(0,0,0,0.42) !important;\n}\n\n.admin-filter-bar select.form-control:focus,\nselect.form-control:focus {\n  outline: none !important;\n  border-color: #7c3aed !important;\n  box-shadow: 0 0 22px rgba(124,58,237,0.45), 0 12px 30px rgba(0,0,0,0.42) !important;\n}\n\n.admin-filter-bar select.form-control option,\nselect.form-control option {\n  background: #0f172a !important;\n  color: #e5e7eb !important;\n  font-weight: 800 !important;\n  padding: 12px !important;\n}\n\n.admin-filter-bar .shiny-input-container {\n  min-width: 230px !important;\n  margin: 0 !important;\n  position: relative !important;\n  z-index: 50 !important;\n}\n\nbody.light-mode .admin-filter-bar select.form-control,\nbody.light-mode select.form-control {\n  background: #ffffff !important;\n  color: #0f172a !important;\n  border-color: rgba(37,99,235,0.45) !important;\n}\n\nbody.light-mode .admin-filter-bar select.form-control option,\nbody.light-mode select.form-control option {\n  background: #ffffff !important;\n  color: #0f172a !important;\n}\n')),
      tags$style(HTML('\n/* ===== FORCE PAGE SCROLL FIX ===== */\nhtml, body {\n  height: 100% !important;\n  overflow-x: hidden !important;\n  overflow-y: auto !important;\n}\n.wrapper {\n  min-height: 100vh !important;\n  overflow: visible !important;\n}\n.content-wrapper, .right-side {\n  position: fixed !important;\n  top: 0 !important;\n  left: 230px !important;\n  right: 0 !important;\n  bottom: 0 !important;\n  height: 100vh !important;\n  max-height: 100vh !important;\n  overflow-y: scroll !important;\n  overflow-x: hidden !important;\n  -webkit-overflow-scrolling: touch !important;\n}\n.content {\n  padding-bottom: 90px !important;\n}\n.box, .box-body, .admin-filter-bar {\n  overflow: visible !important;\n}\n')),
      tags$style(HTML("
/* ===== GPA TREND VALUE BOX TEXT FIX ===== */
.small-box {
  min-height: 190px !important;
}
.small-box h3 {
  font-weight: 900 !important;
  font-size: 20px !important;
  line-height: 1.28 !important;
  white-space: normal !important;
  overflow: visible !important;
  text-overflow: unset !important;
  word-break: normal !important;
  max-width: 100% !important;
}
.small-box p {
  white-space: normal !important;
  font-size: 15px !important;
  line-height: 1.25 !important;
}
.small-box .inner {
  padding-right: 58px !important;
  padding-top: 18px !important;
}
")), 
      tags$script(HTML(
        "function adminScrollTop(){",
        "window.scrollTo(0,0);",
        "document.documentElement.scrollTop=0;",
        "document.body.scrollTop=0;",
        "$('.content-wrapper').scrollTop(0);",
        "$('.right-side').scrollTop(0);",
        "}",
        "$(document).on('click','.sidebar-menu a',function(){",
        "adminScrollTop();",
        "setTimeout(adminScrollTop,50);",
        "setTimeout(adminScrollTop,200);",
        "setTimeout(adminScrollTop,500);",
        "});"
      )),
      
      tabItems(
        
        tabItem(tabName = "admin_overview",
                div(class = "hero-card",
                    div(class = "hero-top",
                        div(
                          div(class = "hero-title", "College Overview"),
                          div(class = "hero-subtitle", "High-level summary of the entire college — performance, attendance, and student health at a glance.")
                        ),
                        div(class = "status-badge", icon("shield-halved"), " Dean Access")
                    )
                ),
                fluidRow(
                  valueBoxOutput("admin_total_students_box", width = 3),
                  valueBoxOutput("admin_total_doctors_box",  width = 3),
                  valueBoxOutput("admin_total_courses_box",  width = 3),
                  valueBoxOutput("admin_pass_rate_box",      width = 3)
                ),
                fluidRow(
                  valueBoxOutput("admin_overall_gpa_box",    width = 3),
                  valueBoxOutput("admin_high_risk_box",      width = 3),
                  valueBoxOutput("admin_avg_attendance_box", width = 3),
                  valueBoxOutput("admin_college_health_box", width = 3)
                ),
                fluidRow(
                  box(title = tagList(icon("heart-pulse"), " College Health Score"), width = 4, solidHeader = FALSE,
                      div(class = "college-health-card",
                          tags$p(style = "color:#94a3b8;font-size:13px;font-weight:700;margin:0 0 8px 0;", "Composite Performance Index"),
                          div(class = "health-score-num", textOutput("admin_health_score_num", inline = TRUE)),
                          tags$p(style = "color:#7c3aed;font-size:14px;font-weight:800;margin:8px 0 0 0;", "/ 100"),
                          tags$hr(style = "border-color:rgba(255,255,255,.10);margin:16px 0;"),
                          tags$p(style = "color:#94a3b8;font-size:12px;margin:0;", "GPA (50%) + Attendance (30%) + Activity (20%)")
                      )
                  ),
                  box(title = tagList(icon("chart-bar"), " Average Score by Course"), width = 8, solidHeader = FALSE,
                      plotlyOutput("admin_course_avg_chart", height = "240px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-pie"), " Grade Distribution"), width = 6, solidHeader = FALSE,
                      plotlyOutput("admin_grade_pie", height = "280px")
                  ),
                  box(title = tagList(icon("table"), " College Summary"), width = 6, solidHeader = FALSE,
                      tableOutput("admin_summary_table")
                  )
                )
        ),
        
        tabItem(tabName = "admin_doctors",
                div(class = "hero-card",
                    div(class = "hero-top",
                        div(
                          div(class = "hero-title", "Doctor Performance"),
                          div(class = "hero-subtitle", "Monitor each doctor's student outcomes, attendance rates, and class engagement.")
                        ),
                        div(class = "status-badge", icon("chalkboard-user"), " Faculty View")
                    )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-bar"), " Doctor Performance Comparison"), width = 12, solidHeader = FALSE,
                      plotlyOutput("admin_doctor_comparison_chart", height = "300px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("id-card"), " Doctor Course Assignment"), width = 5, solidHeader = FALSE,
                      uiOutput("admin_doctor_cards")
                  ),
                  box(title = tagList(icon("calendar-check"), " Avg Attendance per Doctor"), width = 7, solidHeader = FALSE,
                      plotlyOutput("admin_doctor_attendance_chart", height = "280px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("table"), " Doctor Performance Table"), width = 12, solidHeader = FALSE, class = "clean-table-box",
                      div(class = "admin-filter-bar",
                          selectInput("filter_doctor_course", "Course",
                                      choices = c("All Courses" = "", "Advanced Statistics" = "Advanced Statistics", "Linear Algebra" = "Linear Algebra"), selectize = FALSE, width = "220px"),
                          div(class = "filter-results-badge", uiOutput("doctor_table_count", inline = TRUE))
                      ),
                      DTOutput("admin_doctor_table")
                  )
                )
        ),
        
        tabItem(tabName = "admin_subjects",
                div(class = "hero-card",
                    div(class = "hero-title", "Subject Analytics"),
                    div(class = "hero-subtitle", "Subject-level performance across the entire college.")
                ),
                fluidRow(
                  valueBoxOutput("admin_best_subject_box",  width = 4),
                  valueBoxOutput("admin_worst_subject_box", width = 4),
                  valueBoxOutput("admin_avg_all_sub_box",   width = 4)
                ),
                fluidRow(
                  box(title = tagList(icon("chart-bar"), " Subject Averages"), width = 7, solidHeader = FALSE,
                      plotlyOutput("admin_subject_bar", height = "320px")
                  ),
                  box(title = tagList(icon("chart-simple"), " Subject Pass Rates"), width = 5, solidHeader = FALSE,
                      plotlyOutput("admin_subject_pass_pie", height = "320px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-simple"), " Score Distribution per Subject"), width = 12, solidHeader = FALSE,
                      plotlyOutput("admin_subject_box_plot", height = "300px")
                  )
                )
        ),
        
        tabItem(tabName = "admin_gpa",
                div(class = "hero-card",
                    div(class = "hero-title", "GPA Trend Analysis"),
                    div(class = "hero-subtitle", "Track GPA growth or decline across semesters. Spot the stronger half, the drop, and the overall semester direction.")
                ),
                fluidRow(
                  valueBoxOutput("admin_gpa_peak_box",  width = 4),
                  valueBoxOutput("admin_gpa_low_box",   width = 4),
                  valueBoxOutput("admin_gpa_delta_box", width = 4)
                ),
                fluidRow(
                  box(title = tagList(icon("chart-line"), " GPA by Semester — College Wide"), width = 12, solidHeader = FALSE,
                      plotlyOutput("admin_gpa_trend_chart", height = "320px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-line"), " GPA per Course by Semester"), width = 12, solidHeader = FALSE,
                      plotlyOutput("admin_gpa_course_trend", height = "300px")
                  )
                )
        ),
        
        tabItem(tabName = "admin_risk",
                div(class = "hero-card",
                    div(class = "hero-top",
                        div(
                          div(class = "hero-title", "At-Risk Students"),
                          div(class = "hero-subtitle", "Students requiring academic or attendance intervention.")
                        ),
                        div(class = "status-badge", icon("triangle-exclamation"), " Alert View")
                    )
                ),
                fluidRow(
                  valueBoxOutput("admin_high_risk_count_box",   width = 3),
                  valueBoxOutput("admin_medium_risk_count_box", width = 3),
                  valueBoxOutput("admin_failing_count_box",     width = 3),
                  valueBoxOutput("admin_low_attend_count_box",  width = 3)
                ),
                fluidRow(
                  box(title = tagList(icon("chart-pie"), " Risk Level Distribution"), width = 5, solidHeader = FALSE,
                      plotlyOutput("admin_risk_pie", height = "260px")
                  ),
                  box(title = tagList(icon("chart-bar"), " At-Risk by Course"), width = 7, solidHeader = FALSE,
                      plotlyOutput("admin_risk_by_course", height = "260px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("triangle-exclamation"), " At-Risk Student List"), width = 12, solidHeader = FALSE, class = "clean-table-box",
                      div(class = "admin-filter-bar",
                          textInput("filter_risk_search", "Search Name / ID", placeholder = "Type to search...", width = "200px"),
                          selectInput("filter_risk_course", "Course",
                                      choices = c("All Courses" = "", "Advanced Statistics" = "Advanced Statistics", "Linear Algebra" = "Linear Algebra"), selectize = FALSE, width = "220px"),
                          selectInput("filter_risk_level", "Risk Level",
                                      choices = c("All" = "", "High Risk", "Medium Risk"), selectize = FALSE, width = "150px"),
                          selectInput("filter_risk_status", "Status",
                                      choices = c("All" = "", "Pass", "Fail"), selectize = FALSE, width = "130px"),
                          actionButton("reset_risk_filters", "Reset", class = "filter-reset-btn"),
                          div(class = "filter-results-badge", uiOutput("risk_table_count", inline = TRUE))
                      ),
                      DTOutput("admin_risk_table")
                  )
                )
        ),
        
        tabItem(tabName = "admin_rankings",
                div(class = "hero-card",
                    div(class = "hero-top",
                        div(
                          div(class = "hero-title", "College Rankings"),
                          div(class = "hero-subtitle", "Top and bottom performers across the entire college.")
                        ),
                        div(class = "status-badge", icon("trophy"), " Rankings View")
                    )
                ),
                fluidRow(
                  box(title = tagList(icon("ranking-star"), " Top 10 Students"), width = 6, solidHeader = FALSE, class = "clean-table-box",
                      div(class = "admin-filter-bar",
                          selectInput("filter_top10_course", "Course",
                                      choices = c("All Courses" = "", "Advanced Statistics" = "Advanced Statistics", "Linear Algebra" = "Linear Algebra"), selectize = FALSE, width = "220px"),
                          selectInput("filter_top10_grade", "Grade",
                                      choices = c("All Grades" = "", "F" = "F", "D" = "D", "C" = "C", "B" = "B", "A" = "A"), selectize = FALSE, width = "140px")
                      ),
                      DTOutput("admin_top10_table")
                  ),
                  box(title = tagList(icon("arrow-trend-down"), " Bottom 10 Students"), width = 6, solidHeader = FALSE, class = "clean-table-box",
                      div(class = "admin-filter-bar",
                          selectInput("filter_bot10_course", "Course",
                                      choices = c("All Courses" = "", "Advanced Statistics" = "Advanced Statistics", "Linear Algebra" = "Linear Algebra"), selectize = FALSE, width = "220px"),
                          selectInput("filter_bot10_grade", "Grade",
                                      choices = c("All Grades" = "", "F" = "F", "D" = "D", "C" = "C", "B" = "B", "A" = "A"), selectize = FALSE, width = "140px")
                      ),
                      DTOutput("admin_bottom10_table")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-simple"), " Score Distribution"), width = 8, solidHeader = FALSE,
                      plotlyOutput("admin_score_hist", height = "280px")
                  ),
                  box(title = tagList(icon("chart-bar"), " Grade Breakdown"), width = 4, solidHeader = FALSE,
                      plotlyOutput("admin_grade_bar", height = "280px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("table"), " Full Rankings Table"), width = 12, solidHeader = FALSE, class = "clean-table-box",
                      div(class = "admin-filter-bar",
                          textInput("filter_rank_search", "Search Name / ID", placeholder = "Type to search...", width = "200px"),
                          selectInput("filter_rank_course", "Course",
                                      choices = c("All Courses" = "", "Advanced Statistics" = "Advanced Statistics", "Linear Algebra" = "Linear Algebra"), selectize = FALSE, width = "220px"),
                          selectInput("filter_rank_grade", "Grade",
                                      choices = c("All Grades" = "", "F" = "F", "D" = "D", "C" = "C", "B" = "B", "A" = "A"), selectize = FALSE, width = "140px"),
                          selectInput("filter_rank_status", "Status",
                                      choices = c("All" = "", "Pass", "Fail"), selectize = FALSE, width = "130px"),
                          sliderInput("filter_rank_score", "Score Range",
                                      min = 0, max = 100, value = c(0, 100), width = "220px"),
                          actionButton("reset_rank_filters", "Reset", class = "filter-reset-btn"),
                          div(class = "filter-results-badge", uiOutput("rank_table_count", inline = TRUE))
                      ),
                      DTOutput("admin_full_rankings_table")
                  )
                )
        ),
        
        tabItem(tabName = "admin_doc_view",
                div(class = "hero-card",
                    div(class = "hero-top",
                        div(
                          div(class = "hero-title", "Doctor Dashboard View"),
                          div(class = "hero-subtitle", "Full instructor dashboard — all doctor features available to the Dean.")
                        ),
                        div(class = "status-badge", icon("stethoscope"), " Instructor View")
                    )
                ),
                fluidRow(
                  column(
                    width = 10,
                    offset = 1,
                    
                    fluidRow(
                      
                      column(
                        4,
                        valueBoxOutput("total_students_box", width = 12)
                      ),
                      
                      column(
                        4,
                        valueBoxOutput("avg_score_box", width = 12)
                      ),
                      
                      column(
                        4,
                        valueBoxOutput("attendance_box", width = 12)
                      )
                      
                    )
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-bar"), " Average Grade by Course"), width = 6, solidHeader = FALSE,
                      plotlyOutput("course_avg_chart", height = "300px")
                  ),
                  box(title = tagList(icon("users"), " Activity Level Distribution"), width = 6, solidHeader = FALSE,
                      plotlyOutput("activity_pie_chart", height = "300px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-bar"), " Subject Averages"), width = 6, solidHeader = FALSE,
                      plotlyOutput("subject_avg_chart", height = "300px")
                  ),
                  box(title = tagList(icon("chart-pie"), " Grade Distribution"), width = 6, solidHeader = FALSE,
                      plotlyOutput("grade_pie", height = "300px")
                  )
                ),
                fluidRow(
                  box(title = tagList(icon("chart-simple"), " Attendance vs Average Score"), width = 6, solidHeader = FALSE,
                      plotlyOutput("avg_attendance_scatter", height = "300px")
                  ),
                  box(title = tagList(icon("table"), " Summary"), width = 6, solidHeader = FALSE,
                      tableOutput("summary_table")
                  )
                )
        )
      )
    )
  )
}
