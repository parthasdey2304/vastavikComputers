# Vastavik Computers: Master Implementation Plan

This master plan covers every single feature request derived from the infrastructure audit. It is broken down into 5 functional phases to ensure we build it systematically.

## Open Questions

> [!IMPORTANT]
> 1. **Firebase**: Do you have a Firebase project initialized and the `google-services.json` file added to your project? Most of these features require the database to be active.
> 2. **PhonePe**: Do you already have a PhonePe Merchant ID and Salt Key, or do you still need to register for it?
> 3. **Approval**: Do you approve of starting execution strictly on **Phase 1** to get the foundation working before we move to Phase 2?

## Phase 1: Database Foundation & Admin Panel

**1. Firestore Schema & Security**
- Finalize the core database schema for users, courses, lessons, mcqs, pyqs, and payments.
- Add `role: admin` support in the `users` collection to protect admin routes.

**2. Admin Panel Complete Overhaul (`admin_dashboard.dart`)**
- Build an Admin Route guard.
- Create UI forms and logic to **Design Courses** and **Add Lessons** (with YouTube unlisted URLs).
- Create UI to **Add Question Papers** (MCQs and Coding Challenges).
- Create UI to upload and manage promotional **Banners**.

**3. Fix Java Learning Path**
- Connect the `LearningPathScreen` to Firestore so it dynamically loads the parts and subparts for every theory paper (Java, Python, etc).
- Integrate the `youtube_player_iframe` on the `lesson_detail_screen.dart` so when you add a YouTube unlisted format video, it plays properly.

## Phase 2: Monetization (PhonePe Integration)

**1. PhonePe Implementation (`payment_screen.dart`)**
- Integrate PhonePe Merchant API for accepting monthly subscription payments.
- Implement the payment gateway UI flow.
- Setup a mechanism (likely requiring a Firebase Cloud Function) to scan subscriptions on a monthly basis and expire users who haven't paid.

## Phase 3: Content & UI Polish

**1. Fix Quiz UI**
- Completely redesign the broken Quiz question paper and answer script for a proper, clean look (color coding correct/wrong answers, score cards).

**2. PYQs (Past Year Questions)**
- Add PYQs to the database.
- Build a new `pyq_screen.dart` to list and display these past papers cleanly.

**3. Light/Dark Mode System**
- Implement a Riverpod theme provider.
- Add a toggle in the Settings option to switch between Light Mode and Dark Mode across the entire app.

## Phase 4: Artificial Intelligence Power-Ups

**1. AI Export Capabilities**
- Give AI the access to generate and export content as **PDF** and **PPT** directly from the chat or lesson screens.
- Connect the AI Quiz generator to the database so it can make Question Papers on the fly.

**2. OCR Copy Checking**
- Build an OCR scanner screen (`image_picker` + `google_mlkit_text_recognition`).
- Allow users/admins to scan handwritten copies, extract the text, and use AI to automatically check it and assign marks/feedback.

## Phase 5: User Engagement & Personalization

**1. Streak System**
- Add logic to track daily logins and lesson completions.
- Display a 🔥 streak counter (like Duolingo) showing a person opening and learning from the basics over time.

**2. Handwritten Stylus Notes**
- Update the "My Notes" section in the profile page.
- Integrate a drawing board package (`flutter_drawing_board`) to allow users on phones and tablets to add handwritten images using a stylus.

---

## Verification Plan

Because this is massive, verification will happen at the end of each Phase.
1. **Phase 1 Verification**: Log in as Admin, create a course/lesson/banner, and verify it appears dynamically on the Learning Path screen with a working YouTube video.
2. **Phase 2 Verification**: Test a sandbox PhonePe transaction and verify the user subscription status changes.
3. **Phase 3/4/5 Verification**: Will be defined as we reach those phases.
