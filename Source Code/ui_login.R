library(shiny)
library(shinydashboard)

make_login_ui <- function() {
  fluidPage(
    tags$head(
      tags$style(HTML("
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
          min-height: 100vh;
          background: linear-gradient(135deg, #020617 0%, #0f172a 45%, #1e1b4b 100%);
          font-family: 'Segoe UI', Arial, sans-serif;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
        }

        .unified-login-wrapper {
          width: 100%;
          max-width: 650px;
          margin-left: auto !important;
          margin-right: auto !important;
        }

        .login-header { text-align: center; margin-bottom: 30px; color: white; }

        .login-header-title {
          font-size: 42px;
          font-weight: 900;
          margin-bottom: 12px;
          background: linear-gradient(90deg, #7c3aed, #06b6d4, #22c55e);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }

        .login-header-subtitle { font-size: 18px; color: #94a3b8; }

        .access-row {
          display: grid;
          grid-template-columns: 1fr auto 1fr;
          align-items: center;
          gap: 18px;
          margin-bottom: 22px;
        }

        .toggle-switch-container {
          display: flex;
          justify-content: center;
          gap: 20px;
          align-items: center;
        }

        .toggle-label { font-size: 14px; font-weight: 750; color: #cbd5e1; white-space: nowrap; }

        .toggle-switch {
          position: relative;
          width: 120px;
          height: 50px;
          background: rgba(255,255,255,0.1);
          border: 2px solid rgba(255,255,255,0.15);
          border-radius: 999px;
          cursor: pointer;
          display: flex;
          align-items: center;
          padding: 3px;
          transition: all 0.3s ease;
        }

        .toggle-switch.doctor { border-color: rgba(124,58,237,0.3); background: rgba(124,58,237,0.1); }
        .toggle-switch.student { border-color: rgba(34,197,85,0.3); background: rgba(34,197,85,0.1); }

        .toggle-knob {
          width: 42px;
          height: 42px;
          background: linear-gradient(135deg, #7c3aed, #06b6d4);
          border-radius: 999px;
          position: absolute;
          left: 4px;
          transition: all 0.3s ease;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 20px;
          box-shadow: 0 4px 12px rgba(124,58,237,0.3);
        }

        .toggle-switch.student .toggle-knob {
          left: calc(100% - 46px);
          background: linear-gradient(135deg, #06b6d4, #22c55e);
          box-shadow: 0 4px 12px rgba(34,197,85,0.3);
        }

        .parent-portal-card {
          margin: 0 auto 24px auto;
          max-width: 520px;
          position: relative;
          padding: 15px 18px;
          border-radius: 22px;
          background:
            linear-gradient(135deg, rgba(245,158,11,0.13), rgba(236,72,153,0.10)),
            rgba(15,23,42,0.72);
          border: 1px solid rgba(245,158,11,0.28);
          box-shadow: 0 18px 48px rgba(0,0,0,0.28);
          cursor: pointer;
          overflow: hidden;
          transition: 0.25s ease;
        }

        .parent-portal-card::after {
          content: '';
          position: absolute;
          right: -35px;
          top: -35px;
          width: 110px;
          height: 110px;
          border-radius: 999px;
          background: radial-gradient(circle, rgba(245,158,11,0.24), transparent 70%);
        }

        .parent-portal-card:hover {
          transform: translateY(-2px);
          border-color: rgba(245,158,11,0.55);
          box-shadow: 0 24px 60px rgba(245,158,11,0.16);
        }

        .parent-portal-content {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 14px;
          position: relative;
          z-index: 2;
        }

        .parent-left { display: flex; align-items: center; gap: 13px; }

        .parent-mini-icon {
          width: 48px;
          height: 48px;
          border-radius: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(135deg, #f59e0b, #ef4444, #ec4899);
          color: white;
          font-size: 22px;
          box-shadow: 0 12px 26px rgba(245,158,11,0.25);
        }

        .parent-mini-title { color: white; font-size: 16px; font-weight: 900; margin-bottom: 3px; }
        .parent-mini-subtitle { color: #cbd5e1; font-size: 12px; }

        .parent-open-pill {
          background: rgba(255,255,255,0.08);
          color: #fcd34d;
          border: 1px solid rgba(245,158,11,0.28);
          border-radius: 999px;
          padding: 8px 12px;
          font-size: 12px;
          font-weight: 850;
          white-space: nowrap;
        }

        .login-card {
          background: rgba(15, 23, 42, 0.92);
          border: 1px solid rgba(255,255,255,0.12);
          border-radius: 28px;
          padding: 34px 36px !important;
          max-width: 520px !important;
          margin: 0 auto !important;
          box-shadow: 0 30px 90px rgba(0,0,0,0.45);
          animation: fadeIn 0.4s ease-in-out;
        }

        .login-card.doctor { border-color: rgba(124,58,237,0.3); }
        .login-card.student { border-color: rgba(34,197,85,0.3); }
        .login-card.parent {
          border-color: rgba(245,158,11,0.36);
          background:
            linear-gradient(135deg, rgba(245,158,11,0.08), rgba(236,72,153,0.07)),
            rgba(15,23,42,0.94);
        }

        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to   { opacity: 1; transform: translateY(0); }
        }

        .card-header {
          display: flex;
          align-items: center;
          gap: 16px;
          margin-bottom: 26px !important;
          padding-bottom: 20px;
          border-bottom: 2px solid rgba(255,255,255,0.08);
        }

        .card-icon {
          width: 60px;
          height: 60px;
          border-radius: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 30px;
          flex-shrink: 0;
          color: white;
        }

        .card-icon.doctor  { background: linear-gradient(135deg, #7c3aed, #06b6d4); }
        .card-icon.student { background: linear-gradient(135deg, #06b6d4, #22c55e); }
        .card-icon.parent  { background: linear-gradient(135deg, #f59e0b, #ef4444, #ec4899); }

        .card-titles { flex: 1; }
        .card-title { font-size: 24px; font-weight: 900; color: white; margin-bottom: 4px; }
        .card-subtitle { font-size: 13px; color: #94a3b8; }

        .parent-back {
          border: 1px solid rgba(255,255,255,0.10);
          background: rgba(255,255,255,0.06);
          color: #cbd5e1;
          border-radius: 999px;
          padding: 7px 12px;
          font-size: 12px;
          font-weight: 800;
          cursor: pointer;
          transition: 0.2s;
        }

        .parent-back:hover { color: white; background: rgba(255,255,255,0.10); }

        .form-group { max-width: 100% !important; margin-bottom: 18px !important; }
        label { display: block; color: #e5e7eb; font-weight: 750; margin-bottom: 8px; font-size: 14px; text-align: left !important; }

        .form-control {
          width: 100% !important;
          height: 48px;
          background: rgba(255,255,255,0.07) !important;
          color: white !important;
          border: 1px solid rgba(255,255,255,0.15) !important;
          border-radius: 14px !important;
          padding: 12px 16px !important;
          font-size: 14px !important;
          box-shadow: none !important;
          font-family: 'Segoe UI', Arial, sans-serif !important;
        }

        .form-control::placeholder { color: rgba(255,255,255,0.4) !important; }

        .form-control:focus {
          border-color: #06b6d4 !important;
          box-shadow: 0 0 0 3px rgba(6,182,212,0.18) !important;
          outline: none !important;
        }

        .login-card.student .form-control:focus {
          border-color: #22c55e !important;
          box-shadow: 0 0 0 3px rgba(34,197,85,0.18) !important;
        }

        .login-card.parent .form-control:focus {
          border-color: #f59e0b !important;
          box-shadow: 0 0 0 3px rgba(245,158,11,0.18) !important;
        }

        .login-btn {
          width: 100% !important;
          height: 44px !important;
          border: none;
          border-radius: 14px;
          font-weight: 850;
          font-size: 14px !important;
          color: white;
          cursor: pointer;
          transition: all 0.2s;
          margin-top: 16px !important;
          font-family: 'Segoe UI', Arial, sans-serif;
        }

        .login-btn.doctor { background: linear-gradient(90deg, #7c3aed, #06b6d4); box-shadow: 0 12px 28px rgba(124,58,237,0.2); }
        .login-btn.student { background: linear-gradient(90deg, #06b6d4, #22c55e); box-shadow: 0 12px 28px rgba(34,197,85,0.2); }
        .login-btn.parent { background: linear-gradient(90deg, #f59e0b, #ef4444, #ec4899); box-shadow: 0 12px 28px rgba(245,158,11,0.24); }

        .login-btn:hover { transform: translateY(-2px); }
        .login-btn.doctor:hover { box-shadow: 0 16px 36px rgba(124,58,237,0.3); }
        .login-btn.student:hover { box-shadow: 0 16px 36px rgba(34,197,85,0.3); }
        .login-btn.parent:hover { box-shadow: 0 16px 36px rgba(245,158,11,0.35); }

        .secure-note { margin-top: 18px !important; color: #94a3b8; font-size: 12px; text-align: center !important; }
        .shiny-input-container { margin-bottom: 0 !important; }
        .hidden { display: none !important; }

        body.light-mode .parent-portal-card {
          background: rgba(255,255,255,0.86) !important;
          border-color: rgba(245,158,11,0.35) !important;
          box-shadow: 0 18px 46px rgba(30,41,59,0.16) !important;
        }
        body.light-mode .parent-mini-title { color: #0f172a !important; }
        body.light-mode .parent-mini-subtitle { color: #475569 !important; }
        body.light-mode .parent-open-pill { background: #fff7ed !important; color: #c2410c !important; }
        body.light-mode .login-card.parent .card-title,
        body.light-mode .login-card.parent label { color: #0f172a !important; }
        body.light-mode .login-card.parent .card-subtitle,
        body.light-mode .login-card.parent .secure-note { color: #475569 !important; }
        body.light-mode .parent-back { color: #334155 !important; background: #f8fafc !important; border-color: rgba(15,23,42,0.12) !important; }

        @media (max-width: 680px) {
          .login-header-title { font-size: 32px; }
          .access-row { grid-template-columns: 1fr; gap: 12px; }
          .toggle-switch-container { grid-row: 1; }
          .parent-portal-card { margin-bottom: 18px; }
        }
      ")),
      tags$script(HTML("
        function switchLogin(type) {
          var toggle = document.getElementById('loginToggle');
          var doctorCard = document.getElementById('doctorCard');
          var studentCard = document.getElementById('studentCard');
          var parentCard = document.getElementById('parentCard');
          var parentPortal = document.getElementById('parentPortalCard');
          if (!toggle || !doctorCard || !studentCard || !parentCard) return;

          var knob = toggle.querySelector('.toggle-knob');
          parentCard.classList.add('hidden');
          if (parentPortal) parentPortal.classList.remove('hidden');

          if (type === 'student') {
            toggle.classList.remove('doctor');
            toggle.classList.add('student');
            if (knob) knob.textContent = '👨‍🎓';
            doctorCard.classList.add('hidden');
            studentCard.classList.remove('hidden');
          } else {
            toggle.classList.remove('student');
            toggle.classList.add('doctor');
            if (knob) knob.textContent = '🎓';
            doctorCard.classList.remove('hidden');
            studentCard.classList.add('hidden');
          }
        }

        function toggleLoginRole() {
          var toggle = document.getElementById('loginToggle');
          if (!toggle) return;
          if (toggle.classList.contains('doctor')) {
            switchLogin('student');
          } else {
            switchLogin('doctor');
          }
        }

        function openParentLogin() {
          var doctorCard = document.getElementById('doctorCard');
          var studentCard = document.getElementById('studentCard');
          var parentCard = document.getElementById('parentCard');
          var parentPortal = document.getElementById('parentPortalCard');
          if (doctorCard) doctorCard.classList.add('hidden');
          if (studentCard) studentCard.classList.add('hidden');
          if (parentPortal) parentPortal.classList.add('hidden');
          if (parentCard) parentCard.classList.remove('hidden');
        }

        function closeParentLogin() {
          var parentCard = document.getElementById('parentCard');
          var parentPortal = document.getElementById('parentPortalCard');
          if (parentCard) parentCard.classList.add('hidden');
          if (parentPortal) parentPortal.classList.remove('hidden');
          switchLogin('doctor');
        }
      "))
    ),
    
    div(
      class = "unified-login-wrapper",
      div(
        class = "login-header",
        div(class = "login-header-title", "Academic Analytics System"),
        div(class = "login-header-subtitle", "Student Statistics & Emotion Detection System")
      ),
      
      div(
        class = "access-row",
        div(),
        div(
          class = "toggle-switch-container",
          div(class = "toggle-label", "🎓 Doctor"),
          div(class = "toggle-switch doctor", id = "loginToggle", onclick = "toggleLoginRole()", div(class = "toggle-knob", "🎓")),
          div(class = "toggle-label", "Student 👨‍🎓")
        ),
        div()
      ),
      
      div(
        class = "parent-portal-card",
        id = "parentPortalCard",
        onclick = "openParentLogin()",
        div(
          class = "parent-portal-content",
          div(
            class = "parent-left",
            div(class = "parent-mini-icon", icon("people-roof")),
            div(
              div(class = "parent-mini-title", "Parent Portal"),
              div(class = "parent-mini-subtitle", "A secure family view for your child’s progress")
            )
          ),
          div(class = "parent-open-pill", "Open parent access")
        )
      ),
      
      div(
        class = "login-card doctor",
        id = "doctorCard",
        div(class = "card-header",
            div(class = "card-icon doctor", "🎓"),
            div(class = "card-titles", div(class = "card-title", "Doctor Access"), div(class = "card-subtitle", "Instructor Dashboard"))
        ),
        div(class = "form-group", tags$label("Username"), textInput("username", NULL, placeholder = "Enter username")),
        div(class = "form-group", tags$label("Password"), passwordInput("password", NULL, placeholder = "Enter password")),
        actionButton("login_btn", "Sign In", class = "login-btn doctor", icon = icon("sign-in")),
        div(class = "secure-note", "🔒 Secure instructor-only access")
      ),
      
      div(
        class = "login-card student hidden",
        id = "studentCard",
        div(class = "card-header",
            div(class = "card-icon student", "👨‍🎓"),
            div(class = "card-titles", div(class = "card-title", "Student Access"), div(class = "card-subtitle", "Personal Dashboard"))
        ),
        div(class = "form-group", tags$label("Student Name or ID"), textInput("student_username", NULL, placeholder = "e.g., Rawan Atef or STU2026001")),
        div(class = "form-group", tags$label("Password (Student ID)"), passwordInput("student_password", NULL, placeholder = "Enter your Student ID as password")),
        actionButton("student_login_btn", "Access Dashboard", class = "login-btn student", icon = icon("graduation-cap")),
        div(class = "secure-note", "🔒 Password is your Student ID")
      ),
      
      div(
        class = "login-card parent hidden",
        id = "parentCard",
        div(class = "card-header",
            div(class = "card-icon parent", icon("people-roof")),
            div(class = "card-titles", div(class = "card-title", "Parent Access"), div(class = "card-subtitle", "Family academic progress view")),
            div(class = "parent-back", onclick = "closeParentLogin()", "Back")
        ),
        div(class = "form-group", tags$label("Parent Username"), textInput("parent_username", NULL, placeholder = "Enter parent username")),
        div(class = "form-group", tags$label("Password"), passwordInput("parent_password", NULL, placeholder = "Enter password")),
        actionButton("parent_login_btn", "Open Parent Dashboard", class = "login-btn parent", icon = icon("heart-circle-check")),
        div(class = "secure-note", "🔒 Parent-only access • Demo: parent / parent1234")
      )
    )
  )
}

