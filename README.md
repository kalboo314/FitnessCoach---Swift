# FitnessCoach - Swift

A modern SwiftUI fitness coaching application powered by AI, featuring HealthKit integration and intelligent workout recommendations.

## Overview

FitnessCoach is an iOS application that combines Apple HealthKit data with AI-powered chat capabilities to provide personalized fitness coaching. The app features an innovative AppleHealthAgent persona that retrieves and analyzes your health metrics in an A2A JSON format.

## Features

### 🏥 Health Integration
- **HealthKit Integration**: Direct access to Apple Health data
- **AppleHealthAgent Persona**: Intelligent health data retrieval via A2A JSON responses
- **Real-time Metrics**: Active calories, resting calories, and total energy expenditure tracking
- **Health Status Dashboard**: Visual representation of fitness metrics

### 🤖 AI-Powered Coaching
- **Groq API Integration**: Fast, intelligent chat responses using Mixtral-8x7b
- **Context-Aware Recommendations**: AI generates personalized workout suggestions based on your health snapshot
- **Multi-turn Conversations**: Maintain conversation history for better context
- **Real-time Chat Interface**: Beautiful chat bubbles with role-based styling

### 📊 Dashboard & Analytics
- **Fitness Dashboard**: Comprehensive view of your fitness metrics
- **Progress Tracking**: Visual ring indicators for goal progress
- **Recommendation Cards**: Personalized workout and health recommendations
- **Goal Editor**: Set and track custom fitness goals

## Project Structure

```
FitnessCoach/
├── Core/
│   └── AppTheme.swift          # App-wide styling and colors
├── Features/
│   ├── CoachChat/              # Chat interface with AI
│   │   ├── ChatBubbleView.swift
│   │   ├── CoachChatModel.swift
│   │   ├── CoachChatView.swift
│   │   └── GroqAPIKeyView.swift
│   ├── Dashboard/              # Main fitness dashboard
│   │   ├── FitnessDashboardModel.swift
│   │   ├── FitnessDashboardView.swift
│   │   ├── GoalEditorView.swift
│   │   ├── HealthStatusCardView.swift
│   │   ├── MetricCardView.swift
│   │   ├── ProgressRingView.swift
│   │   └── RecommendationCardView.swift
│   └── AppleHealthAgent/       # Health data agent
│       ├── AppleHealthAgentView.swift
│       └── AppleHealthAgentModel.swift
├── Models/
│   ├── A2AResponse.swift       # A2A JSON response models
│   ├── AppTab.swift            # App navigation tabs
│   ├── ChatMessage.swift       # Chat data model
│   ├── ChatMessageRole.swift   # Message role enum
│   ├── FitnessSnapshot.swift   # Health snapshot data
│   ├── HealthAccessState.swift # HealthKit permission state
│   └── WorkoutRecommendation.swift
├── Services/
│   ├── AppleHealthAgent.swift  # Health data service
│   ├── GroqChatService.swift   # AI chat service
│   ├── HealthKitService.swift  # HealthKit integration
│   └── WorkoutRecommendationEngine.swift
├── ContentView.swift           # Main app view
└── FitnessCoachApp.swift       # App entry point
```

## AppleHealthAgent - A2A JSON Integration

The AppleHealthAgent persona generates and parses A2A (Agent-to-Agent) JSON responses containing health data:

```json
{
  "agent": {
    "name": "AppleHealthAgent",
    "version": "1.0.0",
    "source": "HealthKit"
  },
  "ts": "2026-05-14T...",
  "data": {
    "calories": {
      "active": 342.5,
      "resting": 1680.0,
      "total": 2022.5,
      "unit": "kcal",
      "period": {
        "start": "2026-05-14T00:00:00Z",
        "end": "2026-05-15T00:00:00Z"
      }
    },
    "summary": {
      "last_updated": "2026-05-14T...",
      "data_points": 287
    }
  }
}
```

### Key Components
- **A2AResponse.swift**: Decodable models for parsing health data
- **AppleHealthAgent.swift**: Service for generating and parsing A2A responses
- **AppleHealthAgentView.swift**: SwiftUI view displaying parsed health metrics

## Tech Stack

- **Swift 6.2+**: Modern Swift concurrency with async/await
- **SwiftUI**: Modern declarative UI framework
- **HealthKit**: Apple's health and fitness data framework
- **Groq API**: Fast LLM inference with Mixtral-8x7b
- **URLSession**: Network requests for API integration
- **Observable**: Swift 6 observation pattern for state management

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.2+

## Setup

### 1. Clone the Repository
```bash
git clone https://github.com/kalboo314/FitnessCoach---Swift.git
cd FitnessCoach
```

### 2. Add Groq API Key
The app requires a Groq API key for AI-powered recommendations:
1. Sign up at [console.groq.com](https://console.groq.com)
2. Generate an API key
3. Input the key in the app's settings view

### 3. Configure HealthKit Permissions
The app requests the following HealthKit permissions:
- Active Energy (Calories)
- Resting Energy
- Steps
- Workouts
- Heart Rate

### 4. Build and Run
```bash
xcode-build FitnessCoach.xcodeproj
# or open in Xcode and press Cmd+R
```

## Usage

### Main Dashboard
- View your daily fitness metrics
- Track active and resting calories
- Monitor goal progress

### AI Coach Chat
1. Enter your Groq API key in settings
2. Ask fitness-related questions
3. Receive AI-powered recommendations based on your health data

### AppleHealthAgent
- View raw A2A JSON responses from HealthKit
- Monitor data collection metrics
- Refresh to get the latest health data

## Model Configuration

Currently using **Mixtral-8x7b** from Groq:
- Fast inference (~500ms)
- High-quality responses
- Excellent for fitness coaching context

## Architecture

### State Management
- Uses Swift 6 `@Observable` macro for reactive updates
- Observable view models manage UI state
- Clean separation between business logic and presentation

### Services Layer
- **GroqChatService**: Handles API communication with Groq
- **HealthKitService**: Manages HealthKit queries and permissions
- **AppleHealthAgent**: Provides A2A JSON format health data
- **WorkoutRecommendationEngine**: Generates personalized recommendations

### Data Flow
```
HealthKit → HealthKitService → FitnessSnapshot
                                      ↓
                            GroqChatService
                                      ↓
                            Chat Response
```

## Performance Considerations

- Minimal HealthKit queries using efficient date ranges
- Cached health snapshots to reduce redundant queries
- Optimized JSON parsing with Decodable
- Swift concurrency for non-blocking operations

## Future Enhancements

- [ ] Workout tracking and logging
- [ ] Personalized meal recommendations
- [ ] Social sharing and challenges
- [ ] Advanced analytics and trends
- [ ] Offline mode for health data
- [ ] Custom A2A agent plugins

## License

MIT License - feel free to use this project for your own fitness apps!

## Author

Created by Haikal Jamil | [GitHub Profile](https://github.com/kalboo314)
