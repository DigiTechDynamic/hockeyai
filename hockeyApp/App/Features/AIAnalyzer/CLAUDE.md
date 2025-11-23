# AIAnalyzer - Architecture & Development Guide

**Last Updated**: 2025-10-04
**Purpose**: Comprehensive reference for AI Coach Flow, Shot Rater, and Stick Analyzer features

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Feature Breakdown](#feature-breakdown)
4. [Shared Infrastructure](#shared-infrastructure)
5. [Related Modules](#related-modules)
6. [Architecture Patterns](#architecture-patterns)
7. [Development Guidelines](#development-guidelines)
8. [Integration Points](#integration-points)

---

## Overview

The AIAnalyzer is a multi-feature AI-powered hockey analysis system with three primary features:

- **AI Coach Flow**: Dual-angle shot analysis with detailed biomechanical coaching
- **Shot Rater**: Single-angle shot evaluation with technique and power metrics
- **Stick Analyzer**: Equipment recommendations based on shooting technique

All features share common infrastructure through **AIFeatureKit** and **MediaCaptureKit** modules.

---

## Directory Structure

```
AIAnalyzer/
├── Views/
│   └── AICoachView.swift                    # Main landing page for AI features
│
├── AICoachFlow/                              # Multi-angle shot analysis
│   ├── Configuration/
│   │   └── AICoachFlowConfig.swift          # Flow setup + 373-line analysis prompt
│   ├── Models/
│   │   ├── AICoachFlowModels.swift          # Result models + radar metrics
│   │   ├── AICoachSimpleResponse.swift      # Typed AI response
│   │   └── AICoachSimpleSchema.swift        # JSON schema for AI
│   ├── Services/
│   │   └── AICoachFlowService.swift         # Multi-video analysis logic
│   ├── ViewModels/
│   │   └── AICoachFlowViewModel.swift       # Flow state management
│   └── Views/
│       ├── AICoachFlowView.swift            # Main flow container
│       ├── AICoachFlowProcessingView.swift  # Processing UI
│       ├── AICoachFlowResultsView.swift     # Results display
│       ├── FrontNetVideoCaptureView.swift   # Behind-shooter camera
│       ├── SideAngleVideoCaptureView.swift  # Side-angle camera
│       └── PlayerProfileStageView.swift     # Profile input
│
├── ShotRater/                                # Single-angle shot evaluation
│   ├── Configuration/
│   │   └── ShotRaterConfig.swift            # Flow setup + analysis prompt
│   ├── Models/
│   │   ├── ShotRaterModels.swift            # Shot types + result models
│   │   ├── ShotRaterResponse.swift          # Typed AI response
│   │   └── ShotRaterSchema.swift            # JSON schema for AI
│   ├── Services/
│   │   ├── ShotRaterService.swift           # Single-video analysis
│   │   └── ShotRaterBackgroundManager.swift # Background status tracking
│   ├── Storage/
│   │   └── ShotRaterResultStore.swift       # Result persistence
│   ├── ViewModels/
│   │   └── ShotRaterViewModel.swift         # Flow state management
│   └── Views/
│       ├── ShotRaterView.swift              # Main flow container
│       ├── ShotRaterCaptureView.swift       # Video capture
│       ├── ShotRaterProcessingView.swift    # Processing UI
│       └── ShotRaterResultsView.swift       # Results display
│
├── StickAnalyzer/                            # Equipment recommendations
│   ├── Configuration/
│   │   └── StickAnalyzerConfig.swift        # Flow setup + equipment guidelines
│   ├── Models/
│   │   ├── StickAnalyzerModels.swift        # Stick details + recommendations
│   │   ├── StickAnalyzerResponse.swift      # Typed AI response
│   │   └── StickAnalyzerSchema.swift        # JSON schema for AI
│   ├── Services/
│   │   └── StickAnalyzerService.swift       # Analysis logic
│   ├── ViewModels/
│   │   └── StickAnalyzerViewModel.swift     # Flow state management
│   └── Views/
│       ├── StickAnalyzerView.swift          # Main flow container
│       ├── StickAnalyzerResultsView.swift   # Results display
│       ├── StickProcessingView.swift        # Processing UI
│       ├── StickDetailsInputView.swift      # Current stick input
│       └── ShootingQuestionnaireView.swift  # Shot preferences
│
└── Shared/                                   # Common components
    ├── AIAnalyzerError.swift                # Unified error handling
    ├── AIValidationService.swift            # Pre-analysis validation
    ├── AICoachCard.swift                    # Reusable UI card
    ├── ShotStatCard.swift                   # Reusable UI card
    ├── SharedValidationView.swift           # Shared validation UI
    ├── AIAnalysisErrorView.swift            # Error display
    └── TrimmerConfigurations.swift          # Video trim settings
```

---

## Feature Breakdown

### AI Coach Flow (Multi-Angle Analysis)

**Purpose**: Analyze hockey shots from two camera angles with detailed biomechanical feedback

**7-Stage Flow**:
1. Shot Type Selection (if not pre-selected)
2. Player Profile (height, weight, age, position, handedness)
3. Front Net Video Capture (behind shooter)
4. Side Angle Video Capture (10-20ft to side)
5. Shot Validation (parallel validation of both videos)
6. AI Analysis (multi-video processing)
7. Results (radar chart + coaching guide)

**Key Files**:
- **AICoachFlowConfig.swift**: 373-line analysis prompt with kinetic chain framework
- **AICoachFlowService.swift**: Multi-video analysis with player profile context
- **AICoachFlowResultsView.swift**: Unified card design with collapsible coaching guide

**Data Models**:
- `AICoachAnalysisResult`: Main container
- `RadarChartMetrics`: 5 metrics (Stance, Balance, Power, Release, Follow-through)
- `MetricScore`: Individual metric with score (0-100)
- `FocusAreaMetric`: Detailed coaching for weakest area

**Analysis Prompt Structure**:
1. Video Context (3-5 observations proving AI watched)
2. Key Observation (40-60 words about technique)
3. Metric Reasoning (explanations for all 5 metrics)
4. Primary Focus (weakest area with 200-300 word coaching guide)
5. Scoring (0-100 per metric)
6. Metadata (frames analyzed, FPS, angles)

---

### Shot Rater (Single-Angle Evaluation)

**Purpose**: Quick shot evaluation with technique and power metrics

**Flow**:
1. Shot Type Selection
2. Video Capture
3. Validation
4. Analysis
5. Results

**Key Files**:
- **ShotRaterService.swift**: Single-video analysis
- **ShotRaterBackgroundManager.swift**: Background status for main view
- **ShotRaterResultStore.swift**: Result persistence

**Data Models**:
- `ShotAnalysisResult`: Main container
- `ShotMetrics`: Technique + Power scores
- `ShotType`: 4 types (wrist, slap, backhand, snap)

**Unique Features**:
- Background analysis indicators on main view
- Local notifications on completion
- Result storage for history

---

### Stick Analyzer (Equipment Recommendations)

**Purpose**: Analyze shooting technique to recommend optimal stick specifications

**Flow**:
1. Player Profile
2. Current Stick Details
3. Shot Video Capture
4. Shooting Questionnaire (priority, primary shot, zone)
5. Validation + Analysis
6. Results (flex/length/curve/lie + 3-5 stick models)

**Key Files**:
- **StickAnalyzerService.swift**: Comprehensive analysis with equipment guidelines
- **StickAnalyzerResultsView.swift**: Clean card design matching AI Coach

**Data Models**:
- `StickDetails`: Current stick specs
- `ShootingQuestionnaire`: Shooting preferences
- `StickRecommendations`: Ideal specs + recommended models
- `RecommendedStick`: Specific models with match score (0-100)

**Integration**:
- Primary entry point: Equipment tab (`EquipmentView.swift`)
- Results saved to UserDefaults as `StickAnalysisData`

---

## Shared Infrastructure

### AIAnalyzerError (Unified Error Handling)

**Location**: `Shared/AIAnalyzerError.swift`

**Error Types**:
- `networkIssue`: Network failures
- `aiProcessingFailed`: AI service errors
- `invalidContent`: Content validation failures
- `validationParsingFailed`: Pre-validation parsing errors
- `analysisParsingFailed`: Analysis parsing errors

**Features**:
- User-friendly messages
- Recovery suggestions
- Action button text
- Automatic error conversion

---

### AIValidationService (Pre-Analysis Validation)

**Location**: `Shared/AIValidationService.swift`

**Purpose**: Fast pre-validation before full analysis (3 FPS, ultra-fast)

**Methods**:
- `validateHockeyShot()`: Basic shot validation
- `validateHockeyShotWithAngles()`: Multi-angle awareness
- `validateMultipleShots()`: Sequential validation (2-min timeout per video)

**Smart Fallback**: Assumes valid if timeout/error (don't block users)

---

### Shared UI Components

**AICoachCard** & **ShotStatCard**:
- Reusable cards for main AICoachView
- Show analysis status, scores, launch buttons

**SharedValidationView**:
- Shared validation UI across features
- Handles validation errors and retries

**TrimmerConfigurations**:
- Video trimming duration configs
- Min/max durations per feature

---

## Related Modules

### AIFeatureKit Module

**Location**: `/SnapHockey/Modules/AIFeatureKit/`

#### Core Components

**AIAnalysisFacade.swift** (349 lines)
- Clean interface for AI analysis
- `sendToAI()`: Main entry point
- `extractJSON()`: Cleans markdown/thinking tags
- `sanitizeJSON()`: Fixes malformed JSON
- `extractVideoMetadata()`: Gets duration, resolution, FPS

**AIFlowFramework.swift** (642 lines)
- Generic multi-stage workflow system
- `AIFlowState`: ObservableObject managing flow
- `LinearAIFlow`: Linear stage progression
- `AIFlowContainer`: Generic container with header + progress
- Pre-built stages: Selection, MediaCapture, Processing, Results

**AIService.swift** (1,222 lines)
- Low-level Gemini API communication
- `generateContent()`: Generic multi-modal generation
- `generateFromMultipleVideos()`: Multi-video analysis
- Smart inline vs upload: ≤20MB inline, >20MB upload
- Retry logic: 1 retry max, 1.5s delay
- Circuit breaker: 3 failures → open for 60s
- Timeouts: 120s video, 90s default

**AISchemaBuilder.swift** (221 lines)
- Type-safe JSON schema generation
- `AISchemaConvertible`: Protocol for schema-model linking
- `SchemaBuilder`: DSL for building schemas

**GeminiProvider.swift**
- Concrete `AIProvider` implementation
- Wraps `AIService` for video analysis

---

### MediaCaptureKit Module

**Location**: `/SnapHockey/Modules/MediaCaptureKit/`

#### Core Components

**MediaCaptureFacade.swift** (351 lines)
- Clean interface for media operations
- `createCameraView()`: SwiftUI camera
- `createLibraryPickerView()`: Photo library picker
- `createVideoTrimmerView()`: Trimming UI
- Permission checks

**VideoStorageManager.swift** (181 lines)
- Centralized temporary video cleanup
- Singleton pattern
- `registerVideo()`: Track for cleanup
- `cleanupVideo()`: Delete single video
- `cleanupAll()`: Delete all tracked videos
- Automatic cleanup on termination + memory warnings

**CustomCameraView.swift**
- Custom camera implementation
- Video recording with orientation support

**VideoTrimmerView.swift**
- Trimming interface
- Min/max duration enforcement

---

## Architecture Patterns

### Layered Architecture

```
UI Layer (Views)
    ↓
ViewModel Layer (State Management)
    ↓
Service Layer (Business Logic)
    ↓
Facade Layer (Clean API)
    ↓
Provider Layer (AI Abstraction)
    ↓
Network Layer (AIService → Gemini API)
```

---

### Design Patterns Used

**Facade Pattern**:
- `AIAnalysisFacade`: Simplifies AI requests
- `MediaCaptureFacade`: Simplifies media operations

**Provider Pattern**:
- `AIProvider` protocol: Swappable AI services
- `GeminiProvider`: Concrete Gemini implementation

**Flow Pattern**:
- `AIFlowFramework`: Generic multi-stage workflow
- Stage-based navigation with validation

**Singleton Pattern**:
- `VideoStorageManager.shared`: Video lifecycle
- `ShotRaterBackgroundManager.shared`: Background status

**MVVM Pattern**:
- ViewModels: `@MainActor` ObservableObjects
- Views: SwiftUI declarative UI
- Models: Codable data structures

**Circuit Breaker Pattern**:
- `RequestCircuitBreaker`: Failure protection
- Opens after 3 failures, recovers after 60s

---

### Data Flow

**Request Flow**:
```
User Input → ViewModel → Service → AIAnalysisFacade → Provider → AIService → Gemini API
```

**Response Flow**:
```
Gemini API → AIService → Provider → Facade (sanitize) → Service (parse) → ViewModel → UI
```

**Video Lifecycle**:
```
Capture → Register → Use → Cleanup on dismiss/reset
```

---

## Development Guidelines

### Adding a New AI Feature

1. **Create Directory Structure**:
   ```
   NewFeature/
   ├── Configuration/
   ├── Models/
   ├── Services/
   ├── ViewModels/
   └── Views/
   ```

2. **Define Models**:
   - Create response model conforming to `Codable`
   - Create schema model conforming to `AISchemaConvertible`
   - Use `SchemaBuilder` DSL

3. **Create Service**:
   - Use `AIAnalysisFacade.sendToAI()` for analysis
   - Use `AIValidationService` for pre-validation
   - Return typed result model

4. **Build Flow**:
   - Use `AIFlowFramework` for multi-stage UI
   - Create config file with `buildFlow()` method
   - Define stages: Selection → Input → Capture → Validation → Analysis → Results

5. **Implement ViewModel**:
   - Conform to `@MainActor ObservableObject`
   - Manage flow state and video lifecycle
   - Register videos with `VideoStorageManager`

6. **Create Views**:
   - Use `AIFlowContainer` for consistency
   - Implement results view with clean card design
   - Handle errors with `AIAnalyzerError`

---

### Prompt Engineering Best Practices

**Structure**:
1. Clear role definition
2. Detailed instructions with examples
3. Output format specification (JSON schema)
4. Constraints and rules
5. Example outputs

**For Video Analysis**:
- Specify FPS (30 FPS standard, 3 FPS for validation)
- Provide player profile context
- Use predefined options to prevent hallucination
- Request specific observations to prove AI watched
- Enforce JSON schema for consistent structure

**Schema Design**:
- Use `SchemaBuilder` DSL for type safety
- Mark all critical fields as `required`
- Provide detailed descriptions for AI guidance
- Use constraints (min/max, enum) where applicable

---

### UI Consistency Guidelines

**Results Card Design**:
- Single unified card with glassmorphic background
- Sections separated by dividers
- Collapsible coaching guide at bottom
- No score numbers in metric display (strengths vs. areas to develop)
- Minimal icons (✓ for strengths, ⚠ for areas to develop)
- Simple bullets (•) for metric items

**Color Usage**:
- Success: Green (strengths, high scores)
- Warning: Orange (areas to develop, priorities)
- Primary: Theme color (bullets, accents)

**Typography**:
- Section headers: 12pt, semibold, secondary color
- Metric labels: 14pt, semibold
- Reasoning text: 12pt, regular, secondary color
- Coaching guide: 13pt steps, 12pt cues

---

## Integration Points

### Equipment Tab

**File**: `/SnapHockey/App/Features/Equipment/EquipmentView.swift`

**Integration**:
- Primary entry point for Stick Analyzer
- `StickAnalysisCard` shows current vs. optimized specs
- Results saved to UserDefaults as `StickAnalysisData`
- Launches `StickAnalyzerView` in full-screen cover

**Data Flow**:
```
StickAnalyzerView → Analysis → StickAnalysisResult → Save as StickAnalysisData → EquipmentView loads
```

---

### Profile System

**File**: `/SnapHockey/Shared/Models/PlayerProfile.swift`

**Used By**:
- AI Coach Flow (provides context for analysis)
- Stick Analyzer (height/weight affect recommendations)

**Fields**:
- Height, weight, age, gender
- Position, handedness, play style

---

### Notification System

**Integration**:
- Shot Rater sends local notifications on completion
- `sendShotAnalysisNotification()` with shot type and results

---

## AI Processing Characteristics

**Frame Rates**:
- Analysis: 30 FPS (standard)
- Validation: 3 FPS (ultra-fast)
- Max supported: 60 FPS for sports

**Timeouts**:
- Video requests: 120 seconds
- Other requests: 90 seconds

**File Handling**:
- ≤20MB: Inline base64
- >20MB: Upload to Gemini File API

**Retry Logic**:
- Max retries: 1
- Delay: 1.5 seconds
- Only for timeouts and 5xx errors

**Model**:
- Gemini 2.5 Flash (optimal cost/speed for video)

**Generation Config**:
- Temperature: 0.1 (consistent)
- Top K: 10
- Response MIME: application/json

---

## Recent Changes

### File Reorganization (2025-10)
- `AICoach/` → `AICoachFlow/` (clearer naming)
- `Logic/` → `Services/` + `ViewModels/` (separation)
- Shared components moved to `Shared/`

### Schema Simplification
- Removed complex strict schemas
- Using simpler typed responses
- `AICoachSimpleSchema` replaces `AICoachStrictSchema`

### UI Redesign
- Unified card design across features
- Removed individual metric icons
- Strengths vs. Areas to Develop sections
- Collapsible coaching guide
- No score numbers displayed

---

## Future Considerations

### Potential Improvements
- [ ] Add video comparison feature (before/after analysis)
- [ ] Progress tracking over time
- [ ] Drill library with video demonstrations
- [ ] Social sharing of results
- [ ] Coach mode for team analysis

### Technical Debt
- [ ] Consider offline caching for prompts
- [ ] Add unit tests for parsing logic
- [ ] Implement retry exponential backoff
- [ ] Add telemetry for analysis success rates
- [ ] Consider WebSocket for real-time progress

---

## Support

For questions or issues:
1. Check this documentation
2. Review code comments in key files
3. Examine existing feature implementations as templates
4. Test with debug mode enabled (`AIDebugLogger`)

---

**End of Documentation**
