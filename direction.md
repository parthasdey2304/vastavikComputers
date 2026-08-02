# vastavikComputers — Infrastructure & Feature Backlog

> Generated from a full codebase audit of `d:\vastavikComputers\lib\src\`.
> The app uses **Flutter Web + Android**, **Firebase (Auth, Firestore, Storage)**, **Riverpod**, **GoRouter**, **Gemini AI**, and **Judge0** for code execution.

---

## 1. Firestore Database Schema

This is the complete proposed schema for every feature in the app.

```
Firestore (Root Collections)
│
├── users/{uid}
│   ├── name: string
│   ├── email: string
│   ├── role: "student" | "admin"
│   ├── photoUrl: string
│   ├── selectedLanguage: string         (Java, Python, etc.)
│   ├── subscriptionStatus: "free" | "active" | "expired"
│   ├── subscriptionExpiresAt: timestamp
│   ├── streakCount: number
│   ├── lastActiveDate: timestamp        ← for streak calculation
│   ├── totalLessonsCompleted: number
│   ├── theme: "light" | "dark"          ← for dark mode preference
│   │
│   ├── notes/{noteId}
│   │   ├── title: string
│   │   ├── content: string
│   │   ├── imageUrl: string             ← for handwritten image/stylus
│   │   └── createdAt: timestamp
│   │
│   └── progress/{courseId}
│       ├── completedLessons: [string]   ← list of lesson IDs
│       └── lastUpdated: timestamp
│
├── courses/{courseId}
│   ├── title: string                    (e.g. "Java Programming")
│   ├── language: string                 (java, python, c, etc.)
│   ├── description: string
│   ├── thumbnailUrl: string
│   ├── createdBy: string (adminUID)
│   ├── isPublished: bool
│   └── createdAt: timestamp
│
├── lessons/{lessonId}
│   ├── courseId: string                 ← links to courses
│   ├── title: string
│   ├── description: string
│   ├── youtubeUnlistedUrl: string       ← YOUR unlisted YouTube video
│   ├── codeSnippet: string
│   ├── language: string
│   ├── notes: string                    (key takeaways)
│   ├── order: number                    ← for sorting in the learning path
│   └── createdAt: timestamp
│
├── mcqs/{questionId}
│   ├── topic: string
│   ├── question: string
│   ├── options: [string]
│   ├── correctAnswer: number (0-3 index)
│   ├── explanation: string
│   ├── difficulty: "easy" | "medium" | "hard"
│   ├── source: "ai" | "admin"
│   └── createdAt: timestamp
│
├── pyqs/{pyqId}
│   ├── year: number
│   ├── board: "ICSE" | "CBSE"
│   ├── subject: string
│   ├── questionText: string
│   ├── solutionText: string
│   ├── imageUrl: string                 ← optional scanned image
│   └── createdAt: timestamp
│
├── coding_challenges/{challengeId}
│   ├── title: string
│   ├── topic: string
│   ├── description: string
│   ├── difficulty: "easy" | "medium" | "hard"
│   ├── starterCode: {python, java, c, cpp, js}: string
│   ├── testCases: [{input, expectedOutput}]
│   └── createdAt: timestamp
│
├── notes/{noteId}                       ← Quick notes from code editor (existing)
│   ├── content: string
│   ├── challengeId: string
│   └── timestamp: timestamp
│
├── banners/{bannerId}                   ← Admin-controlled promotional banners
│   ├── imageUrl: string
│   ├── linkUrl: string
│   ├── isActive: bool
│   └── createdAt: timestamp
│
└── payments/{paymentId}
    ├── userId: string
    ├── amount: number
    ├── currency: "INR"
    ├── status: "pending" | "success" | "failed"
    ├── phonePeTransactionId: string
    ├── merchantTransactionId: string
    └── createdAt: timestamp
```

---

## 2. Feature Backlog (Prioritized)

---

### 🔴 HIGH PRIORITY

#### A. Admin Panel — Content Management System
**Files to create/modify:** `admin_dashboard.dart` (overhaul), new admin sub-screens.

| Task | Details |
|---|---|
| **Secure admin route** | Admin role check: `if (user.role != 'admin') redirect`. Store `role: 'admin'` in Firestore `users/{uid}`. |
| **Manage Lessons** | CRUD screen for `lessons` collection. Upload YouTube unlisted URL + code snippet per lesson. |
| **Manage MCQs** | Add/Edit/Delete questions in `mcqs` collection. Approve AI-generated ones. |
| **Manage Coding Challenges** | Full CRUD for `coding_challenges` collection. |
| **Manage PYQs** | Add past year papers to `pyqs` collection (year, board, question, solution). |
| **Manage Banners** | Upload promotional banner images to Firebase Storage, store URL in `banners`. Display on the home screen. |
| **User Management** | View all users, see their subscription status, manually grant/revoke access. |
| **Revenue Dashboard** | Pull from `payments` collection and aggregate totals. |

---

#### B. PhonePe Payment Integration (Monthly Subscription)
**Files to create:** `payment_service.dart`, `payment_screen.dart`, `subscription_gate_widget.dart`.

| Task | Details |
|---|---|
| **PhonePe Merchant setup** | Register at [PhonePe for Business](https://business.phonepe.com). Get `merchantId` and `saltKey`. |
| **Payment initiation** | Call PhonePe Payment Gateway API from a Firebase Cloud Function (never expose keys in Flutter). |
| **Payment verification** | Cloud Function webhook verifies payment, then writes `status: "success"` to `payments/{id}` and updates `users/{uid}.subscriptionStatus`. |
| **Subscription gate** | A widget that checks `subscriptionStatus` and blocks premium content if `status != 'active'` or `expiresAt < now`. |
| **Payment history** | Already has `payment_history_screen.dart` — wire it to the `payments` collection. |
| **Monthly renewal scan** | A **Firebase Cloud Function** (cron) running daily: checks all `users` where `subscriptionExpiresAt < today`, sets `subscriptionStatus = 'expired'`. |

---

#### C. Fix Learning Path (Java / All Languages)
**Files to modify:** `learning_path_screen.dart`, `lesson_detail_screen.dart`.

| Task | Details |
|---|---|
| **Dynamic path from Firestore** | Replace hardcoded node list with a Firestore query: `lessons` where `courseId == selectedCourseId`, ordered by `order` field. |
| **Language selector** | Add a dropdown/tab at top of `LearningPathScreen` to switch courses (Java, Python, C, etc.). |
| **Real YouTube player** | Add `youtube_player_iframe` package. Pass `youtubeUnlistedUrl` from Firestore into the video player widget. |
| **Progress tracking** | On lesson complete, write to `users/{uid}/progress/{courseId}`. Show a checkmark on completed nodes. |

---

### 🟡 MEDIUM PRIORITY

#### D. Fix Quiz / Question Paper UI
**Files to modify:** `quiz_taking_screen.dart`, `quiz_setup_screen.dart`.

| Task | Details |
|---|---|
| **UI overhaul** | Clean card-based layout per question. Clear progress bar at top (Question 3 of 10). |
| **Answer state design** | After choosing, highlight the selected answer in blue. After submit, show green (correct) / red (wrong). |
| **Explanation on wrong** | Pull `explanation` field from the MCQ and show it when a wrong answer is chosen. |
| **Result screen** | Score summary card at the end with % score, time taken, and retry option. |

---

#### E. Add PYQs to the App
**Files to create:** `pyq_screen.dart`, `pyq_detail_screen.dart`.

| Task | Details |
|---|---|
| **PYQ List Screen** | Filter by Board (ICSE/CBSE), Year, Subject. Pull from `pyqs` collection. |
| **PYQ Detail** | Show question text, optional image, and solution. |
| **Admin PYQ upload** | Form in admin panel to add new PYQs with text + optional image to Firebase Storage. |

---

#### F. AI Capabilities Expansion
**Files to modify:** `chat_screen.dart`, AI-related services.

| Task | Details |
|---|---|
| **Generate PDF** | Button in AI Chat: "Export as PDF". Use `pdf` package to render the AI response as a formatted PDF and trigger download. |
| **Generate PPT** | Similar — use `pptx_generator` or export as structured text for user to paste into Google Slides. |
| **Generate Quiz from topic** | Already partially built. Ensure it saves to Firestore `mcqs` collection when an admin triggers it. |
| **Generate Question Paper** | Admin selects topic + num of questions → AI generates a formatted question paper PDF. |

---

#### G. OCR — Check Paper with AI
**Files to create:** `ocr_scanner_screen.dart`.

| Task | Details |
|---|---|
| **Camera / Image picker** | Use `image_picker` package to let the user take a photo of a handwritten answer/paper. |
| **OCR** | Send the image to **Google Cloud Vision API** (OCR endpoint) to extract text. |
| **AI checking** | Send extracted text + the original question to Gemini AI: `"Check this student answer and give marks out of 10 with feedback."` |
| **Result display** | Show the extracted text, AI score, and feedback in a clean result card. |

---

### 🟢 LOWER PRIORITY (BUT IMPORTANT)

#### H. Streak Tracking
**Files to modify:** `home_screen.dart`, `profile_screen.dart`. New: `streak_service.dart`.

| Task | Details |
|---|---|
| **Daily streak logic** | On app open: if `lastActiveDate == yesterday`, increment `streakCount`. If gap > 1 day, reset to 0. Write back to Firestore. |
| **Display streak** | Show a 🔥 flame icon + streak count prominently on the Home screen header (like Duolingo). |
| **Streak milestone** | Award a badge or show a congratulations card at 7, 30, 100 day streaks. |

---

#### I. Handwritten Notes with Stylus (My Notes screen)
**Files to modify:** `my_notes_screen.dart`.

| Task | Details |
|---|---|
| **Image picker** | Add a camera/gallery icon to the "New Note" dialog. Upload image to Firebase Storage. Store `imageUrl` in the note document. |
| **Stylus drawing canvas** | Use `flutter_drawing_board` package for freehand drawing on tablets/phones with stylus. Save canvas as an image to Firebase Storage. |
| **Display image notes** | In the note list, show a thumbnail of the attached image. |

---

#### J. Light Mode / Dark Mode
**Files to modify:** `app_theme.dart`, `settings_screen.dart`, `main.dart`. New: `theme_provider.dart`.

| Task | Details |
|---|---|
| **Theme provider** | Create a Riverpod `StateNotifierProvider<ThemeMode>` that loads from `users/{uid}.theme` in Firestore. |
| **Settings toggle** | Add a "Dark Mode" switch tile in `settings_screen.dart`. On toggle, update Firestore and the provider. |
| **MaterialApp update** | Pass `themeMode: ref.watch(themeModeProvider)` to `MaterialApp` in `main.dart`. Define both `theme` (light) and `darkTheme` in `app_theme.dart`. |

---

## 3. Firebase Cloud Functions Required

| Function | Trigger | Action |
|---|---|---|
| `verifyPhonePePayment` | HTTP webhook from PhonePe | Verify signature, update `payments` doc and `users/{uid}.subscriptionStatus` |
| `checkExpiredSubscriptions` | Cron (daily) | Query users where `subscriptionExpiresAt < now`, set `subscriptionStatus = 'expired'` |
| `onUserCreate` | Auth onCreate trigger | Create the initial `users/{uid}` document in Firestore |

---

## 4. New Packages Needed

```yaml
# pubspec.yaml additions
youtube_player_iframe: ^2.3.0      # Real YouTube player in lesson detail
image_picker: ^1.0.4               # Camera/gallery for OCR and notes
pdf: ^3.10.7                       # Export AI responses as PDF
google_mlkit_text_recognition: ^0.11.0  # On-device OCR (no API key needed)
flutter_drawing_board: ^0.6.0      # Stylus drawing for handwritten notes
```

---

## 5. Implementation Order (Recommended)

```
Phase 1 (Foundation):
  1. Firestore Schema setup (create collections manually or via admin)
  2. Admin Panel — Secure route + Lesson/MCQ CRUD
  3. Fix Learning Path — Dynamic from Firestore + YouTube player

Phase 2 (Monetization):
  4. PhonePe payment integration + Cloud Function webhook
  5. Subscription gate widget on premium content

Phase 3 (Content):
  6. PYQs screen + admin upload form
  7. Fix Quiz UI/UX
  8. Streak system

Phase 4 (AI Power):
  9. OCR + AI paper checking
  10. AI → PDF/PPT export
  11. Handwritten notes with stylus

Phase 5 (Polish):
  12. Light / Dark mode
  13. Banners on home screen
  14. Revenue dashboard in admin
```
