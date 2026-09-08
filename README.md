# 🚀 Career Copilot

<p align="center">
  <strong>Next-Generation Autonomous Opportunity Pipeline & AI Career Tracker</strong><br>
  <em>Powered by Flutter, Liquid Glass Aesthetics, and Smart Alarm Automation</em>
</p>

<p align="center">
  <a href="https://laksh718.github.io/Career-Copilot/"><img src="https://img.shields.io/badge/Live%20Demo-GitHub%20Pages-00F5D4?style=for-the-badge&logo=github&logoColor=black" alt="Live Demo" /></a>
  <a href="https://laksh718.github.io/Career-Copilot/Career-Copilot.apk"><img src="https://img.shields.io/badge/Download%20APK-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Download APK" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Web%20%7C%20Android-FF5722?style=for-the-badge" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License" />
</p>

---

## 📱 Download Android App (Recommended for Full Experience)

> [!TIP]
> **Get the Native Experience!** For 1-tap OS Share Sheet auto-ingestion (direct share from WhatsApp, Gmail, LinkedIn), persistent audible alarms, and 120Hz liquid glass animations, download the native Android app:
> 
> 📲 **[Download Career Copilot Android APK (Direct Download)](https://laksh718.github.io/Career-Copilot/Career-Copilot.apk)**
> 
> - **Package**: `Career-Copilot.apk`
> - **Highlights**: 1-Tap Share Target intake, Google Gemini AI Career Coach, local heuristic fallback, custom alarm sounds, and 100% offline data persistence.

---

## 🌐 Live Web Experience

Try the interactive web build directly in your browser on GitHub Pages:
👉 **[https://laksh718.github.io/Career-Copilot/](https://laksh718.github.io/Career-Copilot/)**


---

## ✨ Key Highlights & Features

### 📥 1-Tap Auto-Add via Share Intent
- **Zero-Friction Ingestion**: Share emails (Gmail/Apple Mail), messages (WhatsApp/Telegram), or job posts directly to Career Copilot via the native OS share sheet.
- **Instant AI Extraction**: Automatically parses Company Name, Role, Opportunity Category, Application Deadline, Interview Date/Time, and Compensation/Stipend.
- **Auto-Scheduled Alarms**: Detects interview dates and application deadlines, instantly creating and scheduling alarms in the notification engine.
- **Celebration Confirmation Sheet**: Visual modal displaying verified company logos, extracted timeline tags, and quick actions.

### ⏰ Proactive Smart Alarms & Notification Engine
- **Cross-Platform Alerts**: Native OS alarms on mobile and HTML5 background notifications on the web.
- **Audible & Persistent**: Configurable sound alarms, vibration patterns, and custom lead-time notifications (e.g., 30 mins before, 1 hour before, 1 day before).
- **Alarm Management Hub**: View upcoming alarms, toggle notifications, filter by priority, test alarm sounds, and edit scheduled dates.

### 🎨 Liquid Glass UI & Fluid Hero Morph Transitions
- **Liquid Obsidian Hero Drops**: Top black drop headers with subtle warm specular highlights that fluidly morph and interpolate geometry during tab transitions.
- **Frosted Glass Floating Dock**: 26px squircle bottom navigation bar with dual specular rim reflections, caustic ambient glow, and hover micro-animations.
- **Molten Liquid Action Button**: Elevated center button with dynamic liquid sheen and scale responsiveness.
- **100% Overflow-Resilient**: Adaptive `FittedBox` scaling and flexible constraints across all device form factors.

### 💼 Multi-Category Opportunity Tracking
Organize and advance your pipeline through 4 dedicated tracks:
- 💼 **Jobs & Internships**: Full-time, part-time, and co-op roles with compensation tags.
- 💻 **Hackathons**: Team registrations, submission countdowns, and track categories.
- 🎟️ **Tech Events & Summits**: Speaker sessions, RSVPs, and conference logistics.
- 🏆 **Coding Contests**: Platform links, problem sets, and rating milestones.
- **Dynamic Company Logos**: Instant brand logos for Google, Amazon, Microsoft, Apple, Meta, Netflix, and automated clean monograms for others.

### 📅 Calendar & Timeline Radar
- **Multi-View Modes**: Switch between full Month View and condensed 2-Week Sprint view.
- **Day Event Inspector**: Visual badges distinguishing interview rounds from hard application deadlines.
- **Add to Calendar**: One-tap synchronization with Google Calendar, Apple Calendar, and Outlook (.ics export).

### 🤖 Interactive Copilot AI Coach
- **Interview Prep**: Tailored technical and behavioral interview questions based on company profile and role level.
- **Email Draft Generator**: Generate polite follow-up emails, interview confirmations, or mentor inquiries with a one-tap copy button.
- **Opportunity Audit**: AI feedback highlighting resume strengths and preparation tips.

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter 3.24+ & Dart 3.5+ |
| **State Management** | Provider (Scoped Controllers: `ApplicationController`, `AIController`, `ReminderController`, `ThemeController`) |
| **Animations & Motion** | `flutter_animate`, `CurvedAnimation(Curves.easeInOutCubic)`, Custom Hero Flight Shuttles |
| **Calendar Engine** | `table_calendar` |
| **Persistence** | `shared_preferences` |
| **Notifications** | `flutter_local_notifications` (Mobile) & HTML5 Web Notifications API (Web) |
| **Share Ingestion** | `receive_sharing_intent` |
| **Deployment** | GitHub Actions & GitHub Pages |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.24.0 or later)
- Dart SDK (version 3.5.0 or later)
- Chrome / Android Studio / Xcode (for respective targets)

### Installation

1. **Clone the repository:**
   ```bash
   git clone git@github.com:Laksh718/Career-Copilot.git
   cd Career-Copilot
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run tests:**
   ```bash
   flutter test
   ```

4. **Launch locally:**
   ```bash
   # Run on Chrome
   flutter run -d chrome

   # Run on iOS Simulator
   flutter run -d ios

   # Run on Android Device
   flutter run -d android
   ```

---

## 🌐 GitHub Pages Deployment

The repository includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) configured to automatically build and deploy the Flutter Web version upon any push to `main`:

```bash
flutter build web --base-href /Career-Copilot/ --release
```

### Enabling GitHub Pages on Your Repo:
1. Navigate to your repository on GitHub: **Settings → Pages**.
2. Under **Build and deployment → Source**, select **GitHub Actions**.
3. Push to `main` — the workflow will automatically build and publish the live site at:
   `https://laksh718.github.io/Career-Copilot/`

---

## 📁 Project Architecture

```
career_copilot/
├── .github/
│   └── workflows/
│       └── deploy.yml              # Automated GitHub Pages CI/CD workflow
├── lib/
│   ├── app/
│   │   ├── app.dart                # App entry, share intent routing & routes
│   │   └── theme.dart              # Liquid glass tokens, hero decorations & morph routes
│   ├── controllers/
│   │   ├── ai_controller.dart      # Copilot AI analysis engine
│   │   ├── application_controller.dart # Opportunity pipeline CRUD & persistence
│   │   ├── reminder_controller.dart    # Alarm & notification scheduler
│   │   └── theme_controller.dart   # Light/dark obsidian theme mode
│   ├── models/
│   │   ├── application.dart        # Opportunity data model & status enums
│   │   └── reminder.dart           # Smart alarm model & priorities
│   ├── screens/
│   │   ├── add_opportunity/        # Manual & auto-add share intake screens
│   │   ├── application_details/    # Rich opportunity details & pipeline stages
│   │   ├── applications/           # Categorized pipeline cards & search
│   │   ├── calendar/               # Month & 2-week timeline calendar
│   │   ├── chat/                   # Copilot AI coach & email drafts
│   │   ├── home/                   # Dashboard, radar spotlight & upcoming events
│   │   ├── profile/                # User portfolio stats & global settings
│   │   └── reminders/              # Alarms hub, sound test & notification toggles
│   ├── services/
│   │   ├── notification_service.dart   # Cross-platform local & web notifications
│   │   ├── shared_ingestion_service.dart # Email & message parsing engine
│   │   └── web_notification_helper.dart  # HTML5 Notification bridge
│   └── widgets/
│       ├── bottom_navigation.dart  # Frosted glass floating dock & liquid Add button
│       ├── company_logo_widget.dart# Auto company logos & monogram fallbacks
│       ├── gradient_button.dart    # Overflow-resilient action button
│       ├── textured_background.dart# Obsidian noise & subtle dot matrix
│       └── upcoming_event_card.dart# Timeline cards
├── test/                           # 19 comprehensive unit & widget tests
└── web/
    └── index.html                  # Web entry point with base href support
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
