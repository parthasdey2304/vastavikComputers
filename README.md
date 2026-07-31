# vastavikComputers 💻

> **A Production-Grade Cross-Platform Coding Education Platform**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Gemini](https://img.shields.io/badge/Gemini%20AI-8E75B2?style=for-the-badge&logo=google&logoColor=white)

**vastavikComputers** is a comprehensive coding education platform tailored for students (Class 9–12, ICSE/CBSE/ISC boards). Designed to deliver high-quality video lessons, AI-generated practice questions, notes, and cheat sheets, this application runs seamlessly on phones, tablets, and the web—all from a single Flutter codebase.

---

## ✨ Key Features

- 🎓 **Structured Course Catalog:** Organized courses by class level, subject (Python, Java, C, Data Structures), and difficulty.
- 📹 **Video Lessons:** Integrated video streaming for whiteboard theory + VS Code-style implementation.
- 🤖 **Gemini 3.5 AI Integration:** Embedded AI Chat terminal to generate practice quizzes, explain code step-by-step, and provide hints without revealing answers.
- 💻 **Code Implementation Blocks:** Copy-paste-ready dark theme code blocks with syntax highlighting.
- 📝 **Notes & Cheat Sheets:** Build personalized study materials securely synced via Supabase.
- 🔒 **Robust Authentication:** Firebase Auth (Email/Password & Google) combined with Supabase for isolated user profiles.
- 💸 **Zero-Fee Payments:** Seamless integration with PhonePe Payment Gateway.

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.x | Single codebase for Android, iOS, Web |
| **State Management** | Riverpod | Reactive state & DI container |
| **Routing** | GoRouter | Declarative routing with auth guards |
| **Backend DB** | Supabase (PostgreSQL) | Course data, profiles, progress, RLS policies |
| **Auth** | Firebase + Supabase | Authentication & secure session management |
| **AI Engine** | Gemini 3.5 Flash | Code explanation & coding assistance |
| **Video Storage**| YouTube API / Mux | Video hosting and HLS streaming |
| **Payments** | PhonePe PG | Zero transaction fee payments |

---

## 📥 How to Download the App

**Notice:** We are officially distributing the Android application directly via **GitHub Releases**. We have chosen not to upload the app to the Google Play Store as direct distribution gives us more flexibility, allows for faster updates without lengthy review processes, and provides a much better experience for our users!

To install the app on your Android phone, please follow these steps:

1. **Go to the Releases Page:** Navigate to the [Releases section](../../releases) of this GitHub repository.
2. **Download the APK:** Under the latest release (e.g., `v1.0.0`), find the `Assets` section and click on the `vastavikComputers.apk` file to download it to your phone.
3. **Allow Installation from Unknown Sources:** 
   - When you tap the downloaded APK, your phone may warn you about installing apps from unknown sources.
   - Go to your phone's **Settings > Security** (or follow the prompt) and enable installation from your web browser or file manager.
4. **Install and Run:** Complete the installation and open the app to start learning!

---

## 🏗️ Architecture

The app is built using **Clean Architecture** to separate concerns:
1. **Domain Layer:** Entities, Repositories (Interfaces), and Use Cases.
2. **Data Layer:** Models, Repositories (Implementations), and Datasources (Supabase, Firebase, Gemini Proxy).
3. **Presentation Layer:** Riverpod Providers, Widgets, and Screens.

All sensitive API calls (e.g., Gemini AI) are routed through **Supabase Edge Functions** to ensure API keys are never exposed on the client side.

---

## 🚀 Getting Started (For Developers)

1. Clone the repository.
2. Ensure you have Flutter 3.x installed.
3. Run `flutter pub get` to fetch dependencies.
4. Make sure you have your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their respective directories.
5. Create `.env` files if required for local development.
6. Run the app using `flutter run` or launch via your IDE.

*(Please refer to the `infrastructure.md` file for an in-depth explanation of the database schemas, auth flow, and feature structures.)*

---

**Built with ❤️ by Parth Vastavik for vastavikComputers.**
