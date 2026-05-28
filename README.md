# FitnessCoach

A SwiftUI fitness coaching app with real-time camera pose detection, AI coaching, HealthKit integration, and a full workout planner.

## Features

### Dashboard
- Daily step count and active calorie ring from HealthKit
- Progress toward your calorie goal
- Personalized workout recommendations powered by your health snapshot

### AI Coach Chat
- Chat with an AI fitness coach backed by Groq (Mixtral-8x7b)
- Context-aware responses — the coach sees your real HealthKit data
- Multi-turn conversation history

### Apple Health Agent
- A dedicated view that surfaces raw health metrics in A2A JSON format
- Shows active calories, resting calories, steps, and data freshness

### Workout Planner
- Choose **Focus** (full body, upper, lower, core, cardio), **Intensity** (beginner / intermediate / expert), and **Duration**
- Exercises pulled from a local database of 70+ movements across 17 muscle groups
- Animated GIF demos for each exercise via WorkoutX API
- Estimated duration and calorie burn shown before you start

### Custom Workout Builder
- Search exercises by name
- **Interactive muscle body map** — tap any muscle group on a front/back body diagram to filter the exercise list
- Difficulty filter (beginner / intermediate / expert)
- Build your own plan, set intensity, preview stats, then start

### Active Workout Session
- Exercise-by-exercise view with GIF demo, muscle/equipment badges, set tracker
- **Live camera rep counting** using Apple Vision on-device body pose detection — no cloud, no ML model download required for basic counting
- Skeleton overlay drawn on the live camera feed
- Real-time form feedback text (depth cues, alignment cues)
- Automatic rest timer between sets
- Manual override button if camera tracking isn't available for an exercise

### Post-Workout Form Report
- After completing a workout, tap **View Form Report**
- Circular overall score ring (% good form reps)
- Per-exercise colour bars — one bar per rep, coloured by category
- **Form categories:**
  - **Good Form** — full range achieved, knees tracking correctly
  - **Range Incomplete** — didn't reach target depth/extension
  - **Knee Alignment** — knees caving inward during squat (valgus)
  - **Body Not Visible** — joints left the camera frame that rep
  - **Low Confidence** — poor lighting or framing during that frame

### Fix My Move (MoveCorrection Tab)
- **Live mode** — real-time rep counter + form feedback for squat, push-up, sit-up, and bicep curl
- **Photo mode** — take or pick a photo, get a detailed AI written critique via Groq Vision

### Squat Form Classifier (CoreML)
The squat rep classifier uses a two-input decision tree:

| Input | Description |
|---|---|
| `knee_angle` | Average hip-knee-ankle angle (°). Lower = deeper squat. |
| `knee_alignment_ratio` | Knee width ÷ ankle width. Below 0.75 = valgus. |

Output: `goodForm` / `rangeIncomplete` / `kneeAlignment`

If `SquatFormClassifier.mlmodelc` is not in the bundle the app falls back automatically to the same rule-based thresholds used during training. To generate the model file:

```bash
pip3 install coremltools scikit-learn numpy
python3 Scripts/GenerateSquatModel.py
# Drag the output SquatFormClassifier.mlmodel into Xcode → FitnessCoach group
```

### User Profile
- Enter your name, weight, height, and preferred units (kg/lbs, cm/ft)
- Data stored in `@AppStorage` and read by the workout planner for calorie estimates

---

## Camera & Pose Detection Architecture

```
Camera frame (AVFoundation)
    ↓
VNDetectHumanBodyPoseRequest  (Apple Vision — on-device, no model download)
    ↓
VNHumanBodyPoseObservation
  joint name + normalized 2D location + confidence score
    ↓
MovementAnalyzer
  • averages left/right joint angles
  • computes knee_alignment_ratio for squats
  • detects low-confidence frames
    ↓
SquatFormClassifier  (CoreML → rule fallback)
    ↓
FormFeedbackCategory  →  live feedback text  +  RepFormRecord
```

Three framework layers:
- **AVFoundation** — captures camera frames via `AVCaptureVideoDataOutput`
- **Vision** — runs Apple's built-in body pose detector (`VNDetectHumanBodyPoseRequest`)
- **CoreML / Rules** — converts pose data into form feedback

---

## Requirements

- iOS 16.4+  (runs on iOS 26)
- Xcode 15+
- Swift 5.9+
- Groq API key (free tier) for AI coach chat and photo form analysis

---

## Setup

### 1. Clone
```bash
git clone https://github.com/kalboo314/FitnessCoach---Swift.git
cd FitnessCoach
```

### 2. Groq API Key
1. Sign up at [console.groq.com](https://console.groq.com) and generate a key
2. In the app, tap the **Groq Key** button in the Fix My Move tab or Coach Chat tab and paste it in

### 3. HealthKit Permissions
The app requests these HealthKit read permissions on first launch:
- Active Energy Burned
- Resting Energy Burned
- Step Count
- Workouts
- Heart Rate

### 4. (Optional) Generate the CoreML Squat Model
```bash
pip3 install coremltools scikit-learn numpy
python3 Scripts/GenerateSquatModel.py
```
Drag `SquatFormClassifier.mlmodel` into the Xcode project (FitnessCoach group, added to app target). The app works without it — the rule-based fallback is identical to the trained model.

### 5. Build
Open `FitnessCoach.xcodeproj` in Xcode and press `Cmd+R`.

---

## Project Structure

```
FitnessCoach/
├── Core/
│   └── AppTheme.swift
├── Features/
│   ├── Dashboard/
│   │   ├── FitnessDashboardView.swift
│   │   ├── FitnessDashboardModel.swift
│   │   ├── GoalEditorView.swift
│   │   ├── HealthStatusCardView.swift
│   │   ├── MetricCardView.swift
│   │   ├── ProgressRingView.swift
│   │   └── RecommendationCardView.swift
│   ├── CoachChat/
│   │   ├── CoachChatView.swift
│   │   ├── CoachChatModel.swift
│   │   ├── ChatBubbleView.swift
│   │   ├── CoachContextCardView.swift
│   │   └── GroqAPIKeyView.swift
│   ├── AppleHealthAgent/
│   │   ├── AppleHealthAgentView.swift
│   │   └── AppleHealthAgentModel.swift
│   ├── MoveCorrection/
│   │   ├── MoveCorrectionView.swift       — live + photo form analysis
│   │   ├── MoveCorrectionModel.swift
│   │   ├── MovementAnalysis.swift         — Vision angles, SquatFeatures, form categories
│   │   ├── MovementCameraSession.swift    — AVFoundation capture
│   │   ├── MovementCameraPreview.swift    — SwiftUI camera preview
│   │   └── MovementOverlayView.swift      — skeleton overlay
│   ├── WorkoutPlanner/
│   │   ├── WorkoutPlannerView.swift       — focus / intensity / duration picker
│   │   ├── WorkoutPlannerModel.swift
│   │   ├── WorkoutPlanDetailView.swift    — exercise list with GIFs
│   │   ├── ActiveWorkoutView.swift        — live session + camera tracking
│   │   ├── WorkoutMovementTrackingModel.swift
│   │   ├── WorkoutFormReportView.swift    — post-workout form report
│   │   ├── CustomWorkoutBuilderView.swift — build your own plan
│   │   └── MuscleBodyMapView.swift        — tappable body diagram filter
│   └── Profile/
│       ├── UserProfileView.swift
│       └── UserProfileModel.swift
├── Models/
│   ├── Exercise.swift
│   ├── FitnessGoal.swift
│   ├── UserProfile.swift
│   ├── WorkoutRecommendation.swift
│   ├── FitnessSnapshot.swift
│   ├── A2AResponse.swift
│   ├── AppTab.swift
│   ├── ChatMessage.swift
│   ├── ChatMessageRole.swift
│   └── HealthAccessState.swift
├── Services/
│   ├── HealthKitService.swift
│   ├── ExerciseAPIService.swift           — GIF lookup via WorkoutX API
│   ├── LocalExerciseDatabase.swift        — 70+ hardcoded exercises
│   ├── SquatFormClassifier.swift          — CoreML wrapper + rule fallback
│   ├── GroqChatService.swift
│   ├── GroqVisionService.swift
│   ├── AppleHealthAgent.swift
│   └── WorkoutRecommendationEngine.swift
├── Scripts/
│   └── GenerateSquatModel.py              — generates SquatFormClassifier.mlmodel
├── ContentView.swift
└── FitnessCoachApp.swift
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 16.4+) |
| Health data | HealthKit |
| Camera | AVFoundation |
| Pose detection | Apple Vision (`VNDetectHumanBodyPoseRequest`) |
| Form classification | CoreML + rule-based fallback |
| AI chat | Groq API — Mixtral-8x7b |
| Photo form analysis | Groq Vision API |
| Concurrency | Swift async/await, `@MainActor` |
| State | `@StateObject`, `@ObservedObject`, `@AppStorage` |

---

## License

MIT — feel free to use this for your own fitness projects.

## Author

Haikal Jamil · [GitHub](https://github.com/kalboo314)
