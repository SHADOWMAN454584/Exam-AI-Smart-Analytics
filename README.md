# ExamAI — Smart Exam Analytics & Predictions

A Flutter-based AI-powered exam preparation app that helps students analyse their performance, practise mock tests, scan previous year questions, and receive personalised study recommendations.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
  - [1. Login & Authentication](#1-login--authentication)
  - [2. Dashboard](#2-dashboard)
  - [3. Practice Test](#3-practice-test)
  - [4. PYQ Scanner](#4-pyq-scanner)
  - [5. Progress Analytics](#5-progress-analytics)
  - [6. AI Recommendations](#6-ai-recommendations)
- [Supported Exams](#supported-exams)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Demo Credentials](#demo-credentials)
- [Project Structure](#project-structure)

---

## Overview

**ExamAI** is designed for competitive exam aspirants (JEE, NEET, GATE, CAT, etc.). It combines performance tracking, interactive mock tests, camera-based PYQ scanning, and AI-driven study recommendations into a single, polished mobile/web app.

---

## Features

### 1. Login & Authentication

- Animated login screen with fade and slide transitions.
- Email & password form with inline validation.
- Simulated network delay for a realistic login experience.
- "Fill sample credentials" shortcut for instant demo access.
- Secure logout with confirmation dialog accessible from any screen.

---

### 2. Dashboard

The home screen gives a quick snapshot of current preparation status:

| Section | Details |
|---|---|
| **Greeting card** | Personalised welcome with the student's name and avatar initials. |
| **Latest Score card** | Displays the most recent test score (/100) with a circular progress ring and a colour-coded grade label (Excellent / Good / Average / Needs Work / Weak). |
| **Quick Stats row** | Shows total tests taken, average score, and study streak at a glance. |
| **Weekly Progress chart** | Visual bar chart showing score trends over the past 7 weeks. |
| **Recent Tests list** | Cards for every past test showing name, date, duration, score, and per-subject breakdown with coloured progress bars. |

**Grade colour system:**

| Range | Label | Colour |
|---|---|---|
| 90 – 100% | Excellent | Green |
| 75 – 89% | Good | Blue |
| 50 – 74% | Average | Amber |
| 30 – 49% | Needs Work | Orange |
| 0 – 29% | Weak | Red |

---

### 3. Practice Test

An interactive MCQ test engine with the following capabilities:

- **Question navigator** — horizontal scrollable pill bar; pills change colour when a question is answered.
- **Question card** — displays subject tag, topic, difficulty badge, and question text.
- **Answer options** — tappable option cards; selected option is highlighted.
- **Navigation** — Previous / Next buttons to move between questions freely.
- **Progress counter** — live answered/total count shown in the header.
- **Submit flow** — confirmation dialog shows how many questions are answered before final submission.
- **Result view** — after submission, shows score, correct/wrong counts, and per-question answer review with correct answer highlighted in green and wrong answer in red.

Current question bank covers **Physics**, **Chemistry**, and **Mathematics** with varying difficulty levels (Easy / Medium / Hard).

---

### 4. PYQ Scanner

Scan previous year questions (PYQs) directly from paper or PDF and get AI-powered analysis:

- **Exam selector** — dropdown to choose target exam before scanning (see [Supported Exams](#supported-exams)).
- **Upload methods:**
  - 📷 **Camera** — capture a question paper directly.
  - 🖼️ **Gallery** — pick an existing image from the device.
  - 📄 **PDF** — upload a PDF document.
- **Processing indicator** — animated loading state while the AI analyses the uploaded content.
- **Mock result panel** — displays extracted question info, predicted important topics, and difficulty rating after processing.
- **Scanning tips** — guidance cards on good lighting, flat surface, sharp focus, and full-page framing for best OCR results.

---

### 5. Progress Analytics

A detailed analytics dashboard tracking preparation over time:

- **Overall Performance card** — percentage score with a trend indicator (e.g., +5.2% vs last period).
- **Score Trend chart** — visual line/bar chart showing historical test scores.
- **Subject Performance breakdown:**
  - Physics (with topics: Mechanics, Electrostatics, Optics, Thermodynamics, Modern Physics)
  - Chemistry (Organic, Inorganic, Physical, Coordination Chemistry)
  - Mathematics (Calculus, Algebra, Coordinate Geometry, Trigonometry, Probability)
  - Each subject shows an overall percentage and per-topic progress bars.
- **Strengths & Weak Areas cards** — side-by-side cards listing top 3 strong and weak topics.
- **Test Statistics grid** — accuracy rate, average speed, total questions attempted, and best score.

---

### 6. AI Recommendations

A personalised "For You" feed powered by AI analysis of past performance:

- **AI Analysis Summary banner** — headline insight (e.g., "Your score improved 24% over 7 weeks — focus on weak areas to push past 85%").
- **Priority filter chips** — filter cards by All / High Priority / Practice / Revision / Test.
- **Recommendation cards** — each card shows:
  - Subject tag with colour coding.
  - Task type icon (Practice ✏️ / Revision 📖 / Mock Test 📝).
  - Priority badge (High 🔴 / Medium 🟡 / Low 🟢).
  - Description with specific advice.
  - Estimated study time.
- **Study Schedule suggestion** — a structured weekly study plan block with recommended daily time allocation.

---

## Supported Exams

| Exam | Full Name |
|---|---|
| JEE Main | Joint Entrance Examination (Main) |
| JEE Advanced | Joint Entrance Examination (Advanced) |
| NEET | National Eligibility cum Entrance Test |
| GATE | Graduate Aptitude Test in Engineering |
| CAT | Common Admission Test |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Material 3) |
| Language | Dart (SDK ^3.11.0) |
| UI Theme | Custom theme with Poppins font, purple/indigo primary palette |
| State management | `setState` (local widget state) |
| Navigation | `Navigator` with `MaterialPageRoute` |
| Platforms | Android, iOS, Web, Windows, macOS, Linux |

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.11.0
- Dart SDK ≥ 3.11.0
- Android Studio / VS Code with Flutter extension

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd aiexamprediction

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# iOS (macOS required)
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

---

## Demo Credentials

Use the following credentials to log in without creating an account:

| Field | Value |
|---|---|
| Email | `student@exam.ai` |
| Password | `test1234` |

A **"Use Sample Account"** button on the login screen fills these in automatically.

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── constants/
│   ├── app_theme.dart               # Colours, typography, theme config
│   └── sample_data.dart             # Mock credentials, tests, questions, recommendations
└── screens/
    ├── login_screen.dart            # Animated login with form validation
    ├── home_screen.dart             # Bottom nav shell, logout dialog
    ├── dashboard_screen.dart        # Score overview, stats, recent tests
    ├── test_screen.dart             # Interactive MCQ practice test engine
    ├── camera_upload_screen.dart    # PYQ scanner with upload options
    ├── progress_screen.dart         # Subject analytics, trends, strengths/weaknesses
    └── recommendation_screen.dart  # AI-powered personalised study recommendations
```
