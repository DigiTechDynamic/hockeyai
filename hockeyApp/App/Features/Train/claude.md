# Train Feature - Complete Documentation

## 🎯 Vision

**Goal:** Provide hockey players with a comprehensive training system that combines pre-built workouts, custom workout creation, AI-powered personalization, and progress tracking to help them systematically improve their skills.

### Primary Objectives
- Enable structured skill development through guided workouts
- Reduce friction in workout planning with AI assistance
- Track progress and maintain motivation through streaks and history
- Support all skill levels from beginner to advanced

### Success Metrics
- Users complete 3+ workouts per week
- 70%+ of workouts are completed (not abandoned mid-session)
- Users create custom workouts within first week
- Active users maintain 5+ day training streaks

---

## 📱 User Experience Map

### Flow 1: Browse & Start Pre-Built Workout
```
TrainView
  → Browse 7 sample workouts
  → Tap workout card
  → WorkoutDetailView (see exercises, equipment)
  → Tap "Start Workout"
  → WorkoutExecutionView
    → Exercise-by-exercise progression
    → Timers / rep counters
    → Rest periods
  → Completion Summary
  → Return to TrainView
```

### Flow 2: Create Custom Workout
```
TrainView
  → Tap "+ New Workout"
  → Enter workout name (alert)
  → Opens empty WorkoutDetailView
  → Tap "+ Add" to add exercises
  → ExerciseLibraryView (browse all exercises)
  → Select exercises
  → Configure each exercise (tap pencil)
  → ExerciseConfigSheet (adjust reps/time/sets)
  → Save changes (auto-saves)
  → Start workout or return
```

### Flow 3: AI Generate Workout (Existing Drills)
```
TrainView
  → Tap "🤖 AI Generate"
  → AIWorkoutGeneratorView
    → Select goals (strength/speed/skill)
    → Set duration (15/30/45/60 min)
    → Choose equipment (multi-select)
    → Set difficulty (beginner/intermediate/advanced)
  → Tap "Generate"
  → AI selects exercises from library
  → Preview generated workout
  → Edit if needed
  → Save
  → Start workout
```

### Flow 4: AI Generate New Exercises
```
TrainView or Workout Builder
  → Request AI to create new exercise
  → Input: exercise type, goal, equipment
  → AI generates:
    - Exercise name
    - Description
    - Instructions (step-by-step)
    - Tips
    - Benefits
    - Configuration (time/reps/sets)
  → Preview exercise
  → Add to workout or library
```

### Flow 5: View Workout History
```
TrainView (enhanced home)
  → See stats widget (workouts this week, streak)
  → Tap "View History"
  → WorkoutHistoryView
    → Calendar view of completions
    → Recent workouts list
    → Tap workout to see details
    → Exercise-level breakdown (what was completed)
```

---

## 🏗️ Architecture

### File Structure
```
Train/
├── Models/
│   ├── ExerciseModels.swift         # ✅ Core data models (Exercise, Workout, ExerciseConfig)
│   └── WorkoutHistoryModels.swift   # 🔜 Phase 6 - Completion tracking
├── ViewModels/
│   ├── WorkoutViewModel.swift       # ✅ Main business logic (CRUD operations)
│   └── WorkoutExecutionViewModel.swift  # 🔜 Phase 3 - Timer/counter logic
├── Views/
│   ├── TrainView.swift              # ✅ Main workout list | 🔜 Phase 7 - Enhanced home
│   ├── WorkoutDetailView.swift      # ✅ Workout editor/viewer
│   ├── ExerciseDetailView.swift     # ✅ Exercise information display
│   ├── ExerciseConfigSheet.swift    # ✅ Configure reps/time/sets
│   ├── ExerciseLibraryView.swift    # ✅ Browse/add exercises
│   ├── WorkoutExecutionView.swift   # 🔜 Phase 3 - Active workout
│   ├── AIWorkoutGeneratorView.swift # 🔜 Phase 4 - AI workout creation
│   ├── AIExerciseGeneratorView.swift # 🔜 Phase 5 - AI exercise creation
│   └── WorkoutHistoryView.swift     # 🔜 Phase 6 - History & stats
├── Views/Components/
│   └── TrainComponents.swift        # ✅ Reusable UI (ExerciseCard, GradientCard, etc.)
├── Storage/
│   ├── WorkoutRepository.swift      # ✅ Workout CRUD & persistence
│   └── WorkoutHistoryStore.swift    # 🔜 Phase 6 - History persistence
└── Data/
    ├── SampleExercises.swift        # ✅ 60+ default exercises
    └── SampleWorkouts.swift         # ✅ 7 default workouts
```

### Data Models

#### **Exercise** (ExerciseModels.swift)
```swift
struct Exercise: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var category: DrillCategory  // stickhandling, skating, shooting, etc.
    var config: ExerciseConfig   // How to perform it
    var equipment: [Equipment]
    var instructions: String?    // Step-by-step
    var tips: String?           // Pro tips
    var benefits: String?       // What you'll improve
}
```

**Supports 7 Exercise Config Types:**
1. `timeBased(duration: TimeInterval)` - e.g., "2 minutes of stickhandling"
2. `repsOnly(reps: Int)` - e.g., "50 shots"
3. `countBased(targetCount: Int)` - e.g., "100 touches"
4. `weightRepsSets(weight: Double, reps: Int, sets: Int, unit: WeightUnit)` - e.g., "50 lbs, 3×12"
5. `distance(distance: Double, unit: DistanceUnit)` - e.g., "100 meters"
6. `repsSets(reps: Int, sets: Int)` - e.g., "3×15 push-ups"
7. `timeSets(duration: TimeInterval, sets: Int, restTime: TimeInterval?)` - e.g., "45s × 3 sets, 30s rest"

Each config auto-generates `displaySummary` for UI.

#### **Workout** (ExerciseModels.swift)
```swift
struct Workout: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    var estimatedTimeMinutes: Int

    // Computed properties:
    var exerciseCount: Int
    var allEquipment: [Equipment]      // Unique equipment needed
    var allCategories: [DrillCategory]  // Unique categories covered
}
```

#### **WorkoutHistory** (Future - Phase 6)
```swift
struct WorkoutHistory: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let workoutName: String
    let completedAt: Date
    let duration: TimeInterval  // Actual time taken
    let exercisesCompleted: [ExerciseCompletion]
    let notes: String?
}

struct ExerciseCompletion: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let completed: Bool
    let actualReps: Int?
    let actualWeight: Double?
    let actualDuration: TimeInterval?
}
```

### Data Persistence

**WorkoutRepository** (Storage/WorkoutRepository.swift)
- Saves/loads workouts to UserDefaults as JSON
- First launch: Loads 7 sample workouts
- Auto-saves on every modification
- Methods: `loadWorkouts()`, `saveWorkouts()`, `resetToDefaults()`

**Storage Keys:**
- `train.workouts` - All workouts (sample + custom)
- `train.firstLaunchComplete` - First launch flag

**Future (Phase 6):**
- `train.workoutHistory` - Completed workout records
- `train.userProgress` - Stats, streaks, PRs

---

## ✅ Feature Status Matrix

| Feature | Status | Files | Notes |
|---------|--------|-------|-------|
| **Phase 1: Foundation** | | | |
| Browse Workouts | ✅ Done | TrainView.swift | 7 sample workouts display |
| View Workout Details | ✅ Done | WorkoutDetailView.swift | Shows exercises, equipment, categories |
| Add/Remove Exercises | ✅ Done | WorkoutDetailView.swift + ExerciseLibraryView.swift | Auto-saves changes |
| Configure Exercise | ✅ Done | ExerciseConfigSheet.swift | All 7 config types supported |
| Rename Workout | ✅ Done | WorkoutDetailView.swift (header menu) | Via 3-dot menu |
| Delete Workout | ✅ Done | WorkoutDetailView.swift | Confirmation alert |
| Delete Exercise | ✅ Done | ExerciseCard pencil menu | Confirmation alert |
| Data Persistence | ✅ Done | WorkoutRepository.swift | Auto-save on all changes |
| Exercise Library | ✅ Done | ExerciseLibraryView.swift | Browse 60+ exercises |
| | | | |
| **Phase 2: Custom Workout Creation** | | | |
| Create New Workout | 🔜 Next | TrainView.swift | "+ New Workout" button needed |
| Name Workout | 🔜 Next | Alert dialog | Text field input |
| Empty Workout State | 🔜 Next | WorkoutDetailView.swift | Already handles 0 exercises |
| | | | |
| **Phase 3: Workout Execution** | | | |
| Pre-Workout Summary | 🔜 Planned | WorkoutExecutionView.swift | Equipment checklist |
| Timer (Time-Based) | 🔜 Planned | WorkoutExecutionView.swift | Countdown timer |
| Counter (Reps/Sets) | 🔜 Planned | WorkoutExecutionView.swift | Manual tracking |
| Rest Timer | 🔜 Planned | WorkoutExecutionView.swift | Between exercises |
| Progress Indicator | 🔜 Planned | WorkoutExecutionView.swift | "Exercise 2 of 6" |
| Pause/Resume | 🔜 Planned | WorkoutExecutionView.swift | Mid-workout control |
| Skip Exercise | 🔜 Planned | WorkoutExecutionView.swift | Optional skip |
| Completion Summary | 🔜 Planned | WorkoutExecutionView.swift | Time, exercises done |
| | | | |
| **Phase 4: AI Workout Generator (Existing Drills)** | | | |
| AI Input Form | 🔜 Planned | AIWorkoutGeneratorView.swift | Goals, duration, equipment, difficulty |
| AI Integration | 🔜 Planned | Use GeminiProvider | Existing AI infrastructure |
| Exercise Selection Logic | 🔜 Planned | AI prompt engineering | Pick from SampleExercises.all |
| Configuration Generation | 🔜 Planned | AI generates configs | Appropriate reps/time/sets |
| Preview & Edit | 🔜 Planned | AIWorkoutGeneratorView.swift | Review before save |
| Save Generated Workout | 🔜 Planned | WorkoutRepository.swift | Already supports this |
| | | | |
| **Phase 5: AI Exercise Generator** | | | |
| AI Exercise Creation | 🔜 Planned | AIExerciseGeneratorView.swift | Generate new exercises |
| Exercise Validation | 🔜 Planned | Parser/validator | Ensure valid Exercise model |
| Add to Library | 🔜 Planned | Save to persistence | Expand exercise library |
| | | | |
| **Phase 6: Workout History & Tracking** | | | |
| Save Completion | 🔜 Planned | WorkoutHistoryStore.swift | On workout finish |
| History List View | 🔜 Planned | WorkoutHistoryView.swift | Recent workouts |
| Calendar View | 🔜 Planned | WorkoutHistoryView.swift | Visual completion calendar |
| Streak Calculation | 🔜 Planned | UserProgressStore.swift | Consecutive days |
| Stats Dashboard | 🔜 Planned | TrainView.swift | Total workouts, time, streaks |
| Personal Records | 🔜 Planned | Track max weight/reps | Per exercise |
| | | | |
| **Phase 7: Enhanced Home View** | | | |
| Stats Widget | 🔜 Planned | TrainView.swift | Quick stats at top |
| Quick Actions | 🔜 Planned | TrainView.swift | Continue last, AI generate |
| Featured Workouts | 🔜 Planned | TrainView.swift | Recommendations |
| Recently Completed | 🔜 Planned | TrainView.swift | Show recent history |

---

## 🚀 Development Roadmap

### **Development Pattern: Design → Implement → Polish → Validate**

Each phase follows this structure:
1. **UI Design Preview** - Sketch/describe the interface
2. **Implementation** - Build core functionality
3. **Polish** - Refinements, animations, edge cases
4. **Validate** - Test happy path + edge cases

---

## **✅ Phase 1: Foundation (COMPLETE)**

**Goal:** Robust data models + CRUD operations + persistence

### Completed Features
- [x] Exercise models with 7 config types
- [x] Workout CRUD (add/remove/configure exercises)
- [x] Data persistence (WorkoutRepository)
- [x] Delete confirmations (workout + exercise)
- [x] Menu-based actions (3-dot menu pattern)
- [x] Exercise library browser
- [x] Auto-save on all changes
- [x] Manual save for ExerciseConfigSheet (experimentation mode)

### Key Decisions Made
- **Auto-save at workout level** - Changes persist immediately
- **Manual save for config sheet** - Users can experiment with values
- **Menu-based actions** - All edit/delete via menus (more discoverable than long-press)
- **Confirmation alerts** - Delete workout/exercise requires confirmation
- **UserDefaults + Codable** - Simple, lightweight persistence (no SwiftData dependency)

---

## **🔜 Phase 2: Custom Workout Creation (NEXT)**

**Goal:** Users can create blank workouts from scratch

**Estimated Time:** 30-45 minutes

### Step 1: UI Design Preview

**TrainView Enhancement:**
```
┌─────────────────────────────┐
│  Training                    │
│  7 workout plans             │
│  ● READY                     │
│                              │
│  [Workout Card 1]            │
│  [Workout Card 2]            │
│  [Workout Card 3]            │
│  ...                         │
│                              │
│  ┌───────────────────────┐  │
│  │  + New Workout        │  │ ← NEW BUTTON
│  └───────────────────────┘  │
└─────────────────────────────┘
```

**Alert for Workout Name:**
```
┌─────────────────────────────┐
│  Create Workout              │
│                              │
│  [_________________]         │ ← Text field
│   Enter workout name         │
│                              │
│  [Cancel]  [Create]          │
└─────────────────────────────┘
```

**After Creation:**
```
Opens WorkoutDetailView with:
- New workout name as title
- Empty exercise list
- "No exercises yet" empty state
- "+ Add" button to add exercises
```

### Step 2: Implementation Checklist

**Files to Modify:**
- [ ] `TrainView.swift` - Add "+ New Workout" button
- [ ] `WorkoutViewModel.swift` - Already has `createWorkout()` method ✅

**Code Changes:**
```swift
// TrainView.swift - Add after workout cards

Button(action: {
    showCreateWorkoutAlert = true
}) {
    HStack {
        Image(systemName: "plus.circle.fill")
        Text("New Workout")
    }
    // Styling to match theme
}
.alert("Create Workout", isPresented: $showCreateWorkoutAlert) {
    TextField("Workout Name", text: $newWorkoutName)
    Button("Cancel", role: .cancel) { }
    Button("Create") {
        let workout = workoutManager.createWorkout(name: newWorkoutName)
        selectedWorkout = workout  // Navigate to it
        newWorkoutName = ""
    }
}
```

**State Variables Needed:**
```swift
@State private var showCreateWorkoutAlert = false
@State private var newWorkoutName = ""
```

### Step 3: Polish

- [ ] Button styling (match GradientCard theme)
- [ ] Input validation (no empty names, trim whitespace)
- [ ] Limit name length (30 characters max)
- [ ] Smooth navigation animation to WorkoutDetailView
- [ ] Default name suggestion ("Custom Workout")
- [ ] Empty state in WorkoutDetailView already exists ✅

### Step 4: Validate

**Test Cases:**
- [ ] Create workout → Add exercises → Kill app → Reopen → Verify persists
- [ ] Create workout with empty name → Should be blocked
- [ ] Create workout → Delete it immediately → Verify removed from list
- [ ] Create 5 workouts → All appear in list
- [ ] Create workout → Rename it → Verify saves

**Edge Cases:**
- [ ] Create workout with special characters in name
- [ ] Create workout with very long name
- [ ] Create multiple workouts with same name (allowed)

---

## **🔜 Phase 3: Workout Execution Flow**

**Goal:** Users can perform workouts with guided UI and timers

**Estimated Time:** 3-4 hours

### Step 1: UI Design Preview

#### **Pre-Workout Screen**
```
┌─────────────────────────────┐
│  [X]  Elite Shooting         │
│─────────────────────────────│
│  Ready to Start?             │
│                              │
│  ⏱️  Estimated Time: 35 min  │
│  💪 6 exercises              │
│  🏒 Equipment: Stick, Pucks, │
│      Net, Cones              │
│                              │
│  [Start Workout]             │ ← Big green button
└─────────────────────────────┘
```

#### **Active Exercise Screen (Time-Based)**
```
┌─────────────────────────────┐
│  [⏸]  Elite Shooting    [X] │ ← Pause/Close
│─────────────────────────────│
│                              │
│  Exercise 2 of 6             │ ← Progress
│                              │
│  One-Hand Control            │ ← Exercise name
│  Wide Moves                  │
│                              │
│     ┌─────────────┐         │
│     │             │         │
│     │   01:30     │         │ ← Big timer
│     │             │         │
│     └─────────────┘         │
│                              │
│  Instructions:               │
│  Practice controlling puck   │
│  with one hand only...       │
│                              │
│  [Skip]      [Complete]      │
│                              │
│─────────────────────────────│
│  Up Next:                    │
│  🏒 The Crosby Tight Turns   │
│     2m                       │
└─────────────────────────────┘
```

#### **Active Exercise Screen (Reps-Based)**
```
┌─────────────────────────────┐
│  [⏸]  Elite Shooting    [X] │
│─────────────────────────────│
│                              │
│  Exercise 1 of 6             │
│                              │
│  Quick Release Snap Shots    │
│                              │
│     ┌─────────────┐         │
│     │   25 / 50   │         │ ← Counter
│     │             │         │
│     │  [- 1] [+ 1]│         │ ← Manual increment
│     └─────────────┘         │
│                              │
│  Target: 50 shots            │
│                              │
│  [Skip]      [Complete]      │
└─────────────────────────────┘
```

#### **Rest Timer Between Exercises**
```
┌─────────────────────────────┐
│  [⏸]  Elite Shooting    [X] │
│─────────────────────────────│
│                              │
│  Great work! 💪              │
│                              │
│  Rest Period                 │
│                              │
│     ┌─────────────┐         │
│     │             │         │
│     │    0:30     │         │ ← Countdown
│     │             │         │
│     └─────────────┘         │
│                              │
│  Up Next:                    │
│  Top Shelf Corner Accuracy   │
│  40 shots                    │
│                              │
│  [Skip Rest]                 │
└─────────────────────────────┘
```

#### **Completion Summary**
```
┌─────────────────────────────┐
│  [X]  Workout Complete! 🎉  │
│─────────────────────────────│
│                              │
│  Elite Shooting              │
│                              │
│  ⏱️  Time: 32 min            │
│  ✅ Exercises: 6 / 6         │
│  🔥 Calories: ~280           │
│                              │
│  Exercise Breakdown:         │
│  ✅ Quick Release Snap Shots │
│  ✅ Top Shelf Corner Accuracy│
│  ✅ Backhand Shelf Shots     │
│  ✅ One-Timer Spot Shooting  │
│  ✅ Low Blocker Side Shots   │
│  ✅ Wrist Shot Rapid Fire    │
│                              │
│  [Save & Exit]               │
└─────────────────────────────┘
```

### Step 2: Implementation Checklist

**New Files:**
- [ ] `WorkoutExecutionView.swift` - Main execution UI
- [ ] `WorkoutExecutionViewModel.swift` - Timer/state logic

**Features to Build:**
- [ ] Pre-workout summary screen
- [ ] Timer component (countdown)
- [ ] Counter component (manual increment/decrement)
- [ ] State management (current exercise index, elapsed time)
- [ ] Rest timer between exercises
- [ ] Progress indicator (X of Y)
- [ ] Pause/resume functionality
- [ ] Skip exercise option
- [ ] Completion summary
- [ ] Navigation flow (exercise → rest → next exercise)

**ViewModel State:**
```swift
@Published var currentExerciseIndex: Int = 0
@Published var isActive: Bool = false
@Published var isPaused: Bool = false
@Published var showingRest: Bool = false
@Published var timeRemaining: TimeInterval = 0
@Published var repsCompleted: Int = 0
@Published var startTime: Date?
@Published var completedExercises: [UUID: Bool] = [:]
```

**Timer Logic:**
```swift
// Use Combine Timer for countdown
private var timer: AnyCancellable?

func startTimer(duration: TimeInterval) {
    timeRemaining = duration
    timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            self?.tick()
        }
}

func tick() {
    if timeRemaining > 0 {
        timeRemaining -= 1
    } else {
        exerciseCompleted()
    }
}
```

### Step 3: Polish

- [ ] Animations
  - [ ] Timer countdown animation
  - [ ] Transition between exercises (slide/fade)
  - [ ] Completion celebration animation
- [ ] Sound/Haptics
  - [ ] Haptic feedback on exercise completion
  - [ ] Optional timer beep (last 5 seconds)
  - [ ] Completion sound
- [ ] Background Support
  - [ ] Keep timer running when app backgrounds
  - [ ] Background audio session (for music)
  - [ ] Prevent screen sleep during workout
- [ ] Accessibility
  - [ ] VoiceOver support for timer
  - [ ] Large text support
  - [ ] High contrast mode

### Step 4: Validate

**Happy Path:**
- [ ] Start workout → Complete all exercises → See summary → Save
- [ ] Timer counts down correctly for time-based exercises
- [ ] Counter increments/decrements for rep-based exercises
- [ ] Rest timer works between exercises
- [ ] Progress indicator accurate (Exercise X of Y)

**Edge Cases:**
- [ ] Pause mid-exercise → Resume → Timer continues correctly
- [ ] Skip exercise → Moves to next
- [ ] Close workout mid-session → Confirm abandon
- [ ] App backgrounds during timer → Resumes correctly
- [ ] Complete workout with 0 exercises (shouldn't be possible)

**All Exercise Types:**
- [ ] `timeBased` - Countdown timer works
- [ ] `repsOnly` - Manual counter works
- [ ] `countBased` - Manual counter works
- [ ] `weightRepsSets` - Shows sets, tracks reps per set
- [ ] `distance` - Manual distance tracker
- [ ] `repsSets` - Tracks sets, reps per set
- [ ] `timeSets` - Timer per set + rest between sets

---

## **🔜 Phase 4: AI Workout Generator (Existing Drills)**

**Goal:** Generate personalized workouts using existing exercises

**Estimated Time:** 4-5 hours

### Step 1: UI Design Preview

#### **AI Generator Entry**
```
┌─────────────────────────────┐
│  Training                    │
│                              │
│  [Workout Card 1]            │
│  [Workout Card 2]            │
│  ...                         │
│                              │
│  ┌───────────────────────┐  │
│  │  🤖 AI Generate       │  │ ← NEW BUTTON
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  + New Workout        │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

#### **AI Input Form**
```
┌─────────────────────────────┐
│  [X]  Generate Workout       │
│─────────────────────────────│
│                              │
│  What's your goal?           │
│  ○ Build Strength            │
│  ● Improve Speed             │ ← Selected
│  ○ Develop Skills            │
│  ○ Conditioning              │
│  ○ Mixed Training            │
│                              │
│  How long do you have?       │
│  [15] [30] [●45] [60] min    │
│                              │
│  Available Equipment:        │
│  ☑ Stick    ☑ Pucks          │
│  ☑ Cones    ☐ Net            │
│  ☑ None     ☐ Dumbbells      │
│                              │
│  Skill Level:                │
│  ○ Beginner                  │
│  ● Intermediate              │
│  ○ Advanced                  │
│                              │
│  [Generate Workout] 🤖       │
└─────────────────────────────┘
```

#### **AI Loading State**
```
┌─────────────────────────────┐
│  Generating Your Workout...  │
│                              │
│     🤖                       │
│  [=========>    ] 60%        │
│                              │
│  Analyzing your goals...     │
│  Selecting exercises...      │
└─────────────────────────────┘
```

#### **AI Preview & Edit**
```
┌─────────────────────────────┐
│  [X]  Speed Builder          │ ← AI-generated name
│─────────────────────────────│
│                              │
│  Generated for you 🤖        │
│  45 min • 8 exercises        │
│                              │
│  WHAT YOU'LL DO              │
│  [+ Add]                     │
│                              │
│  🏒 Explosive Starts         │  ← Can edit/remove
│     3×8 reps                 │
│                              │
│  ⚡ Lateral Bounds           │
│     3×20 reps                │
│                              │
│  🏃 5-10-5 Shuttle           │
│     3×6 reps                 │
│                              │
│  ... (5 more exercises)      │
│                              │
│  [Regenerate] [Save & Start] │
└─────────────────────────────┘
```

### Step 2: Implementation Checklist

**New Files:**
- [ ] `AIWorkoutGeneratorView.swift` - Input form UI
- [ ] `AIWorkoutService.swift` - AI integration logic

**Integration Points:**
- [ ] Use existing `GeminiProvider` from AIFeatureKit
- [ ] Reuse `Exercise` and `Workout` models
- [ ] Save to `WorkoutRepository` (already supports custom workouts)

**AI Prompt Structure:**
```swift
func generateWorkoutPrompt(
    goal: WorkoutGoal,
    duration: Int,
    equipment: [Equipment],
    difficulty: Difficulty
) -> String {
    """
    You are a professional hockey training coach. Generate a \(duration)-minute workout.

    Goal: \(goal.rawValue)
    Equipment available: \(equipment.map { $0.rawValue }.joined(separator: ", "))
    Skill level: \(difficulty.rawValue)

    Choose from these exercises:
    \(SampleExercises.all.map { "- \($0.name): \($0.description)" }.joined(separator: "\n"))

    Return a JSON array of exercise IDs with configurations:
    [
      {
        "exerciseId": "UUID of exercise from list",
        "config": {
          "type": "repsSets",
          "reps": 12,
          "sets": 3
        }
      },
      ...
    ]

    Select 6-10 exercises that fit the goal and duration.
    """
}
```

**Response Parsing:**
```swift
struct AIWorkoutResponse: Codable {
    let workoutName: String
    let exercises: [AIExerciseSelection]
}

struct AIExerciseSelection: Codable {
    let exerciseId: String  // UUID string
    let config: ExerciseConfigResponse
}

// Parse and map to existing Exercise models
func parseAIResponse(_ json: String) -> Workout? {
    // 1. Decode JSON
    // 2. Find exercises by ID from SampleExercises.all
    // 3. Apply AI-suggested configs
    // 4. Create Workout
}
```

**Features:**
- [ ] Input form with all parameters
- [ ] Validation (at least 1 equipment selected, etc.)
- [ ] Call AI via GeminiProvider
- [ ] Loading state with progress
- [ ] Parse AI response into Workout
- [ ] Preview screen (editable)
- [ ] Regenerate option
- [ ] Save to repository

### Step 3: Polish

- [ ] Error handling
  - [ ] AI API failure → Show error message
  - [ ] Invalid AI response → Fallback to default workout
  - [ ] Network timeout → Retry option
- [ ] Loading states
  - [ ] Animated progress bar
  - [ ] Status messages ("Analyzing...", "Selecting exercises...")
- [ ] Preview improvements
  - [ ] Show workout summary stats
  - [ ] Visual equipment icons
  - [ ] Estimated calories
- [ ] Regenerate variations
  - [ ] "Make it harder/easier"
  - [ ] "Swap an exercise"
  - [ ] "Add more cardio"

### Step 4: Validate

**Happy Path:**
- [ ] Fill form → Generate → See valid workout → Save → Appears in list
- [ ] Different goals produce different workouts
- [ ] Duration affects exercise count appropriately
- [ ] Equipment filter works (no exercises requiring unavailable equipment)

**Edge Cases:**
- [ ] No equipment selected → AI generates bodyweight only
- [ ] Very short duration (15 min) → Fewer exercises
- [ ] AI returns invalid JSON → Graceful error
- [ ] AI suggests non-existent exercise ID → Skip and continue
- [ ] Network failure → Show retry option

**Validation:**
- [ ] All generated exercises exist in SampleExercises.all
- [ ] Total estimated time ≈ requested duration
- [ ] Equipment requirements match selected equipment
- [ ] Difficulty appropriate for skill level

---

## **🔜 Phase 5: AI Exercise Generator**

**Goal:** AI creates entirely new exercises (not just selecting from library)

**Estimated Time:** 4-5 hours

### Step 1: UI Design Preview

#### **Trigger Options**
1. From Workout Builder: "Create New Exercise" button
2. From AI Workout Generator: "Generate custom exercises" toggle
3. From Exercise Library: "+ AI Generate" button

#### **AI Exercise Input Form**
```
┌─────────────────────────────┐
│  [X]  Generate Exercise      │
│─────────────────────────────│
│                              │
│  What should it focus on?    │
│  [Stickhandling ▼]           │
│                              │
│  Equipment available:        │
│  ☑ Stick  ☑ Pucks  ☑ Cones  │
│                              │
│  Exercise type:              │
│  ○ Time-based                │
│  ● Reps-based                │
│  ○ Distance-based            │
│                              │
│  Additional details:         │
│  [________________________]  │
│  e.g., "Focus on one-handed  │
│  control in tight spaces"    │
│                              │
│  [Generate Exercise] 🤖      │
└─────────────────────────────┘
```

#### **AI Exercise Preview**
```
┌─────────────────────────────┐
│  [X]  Review Exercise        │
│─────────────────────────────│
│                              │
│  Dynamic Toe Drag Weave 🆕   │ ← AI-generated
│  Stickhandling • 2m          │
│                              │
│  Description:                │
│  Master quick direction      │
│  changes while controlling   │
│  the puck with toe drags...  │
│                              │
│  Instructions:               │
│  1. Set up 5 cones in        │
│     zigzag pattern           │
│  2. Start with puck on       │
│     forehand...              │
│                              │
│  Pro Tip:                    │
│  Keep your head up and...    │
│                              │
│  Benefits:                   │
│  Improves agility and...     │
│                              │
│  Equipment:                  │
│  🏒 Stick  🎯 Pucks  🔶 Cones│
│                              │
│  [Edit] [Regenerate] [Save]  │
└─────────────────────────────┘
```

### Step 2: Implementation Checklist

**New Files:**
- [ ] `AIExerciseGeneratorView.swift` - Input form + preview
- [ ] `AIExerciseService.swift` - AI integration for exercises

**AI Prompt for Exercise Generation:**
```swift
func generateExercisePrompt(
    category: DrillCategory,
    equipment: [Equipment],
    exerciseType: ExerciseType,
    additionalContext: String?
) -> String {
    """
    You are a professional hockey training coach. Create a unique training exercise.

    Category: \(category.rawValue)
    Equipment: \(equipment.map { $0.rawValue }.joined(separator: ", "))
    Exercise Type: \(exerciseType.rawValue)
    Additional Context: \(additionalContext ?? "None")

    Generate a complete exercise with:
    - Creative, descriptive name
    - 2-3 sentence description
    - Step-by-step instructions (5-7 steps)
    - Pro tips for execution
    - Benefits (what skills it improves)
    - Appropriate configuration (duration/reps/sets)

    Return JSON:
    {
      "name": "Exercise Name",
      "description": "Brief description",
      "instructions": "1. Step one\n2. Step two\n...",
      "tips": "Pro tip for best results",
      "benefits": "What you'll improve",
      "config": {
        "type": "timeBased",
        "duration": 120
      }
    }

    Make it realistic, safe, and effective for hockey skill development.
    """
}
```

**Response Parsing:**
```swift
struct AIExerciseResponse: Codable {
    let name: String
    let description: String
    let instructions: String
    let tips: String
    let benefits: String
    let config: ExerciseConfigResponse
}

func parseAIExercise(_ json: String, category: DrillCategory, equipment: [Equipment]) -> Exercise? {
    // 1. Decode JSON
    // 2. Validate fields (non-empty, reasonable)
    // 3. Create Exercise model
    // 4. Assign category and equipment
    // 5. Return Exercise
}
```

**Features:**
- [ ] Input form for exercise parameters
- [ ] Call AI via GeminiProvider
- [ ] Parse AI response into Exercise model
- [ ] Preview screen (editable)
- [ ] Edit generated fields
- [ ] Regenerate option
- [ ] Save to workout or library
- [ ] Validation (safety checks, reasonable configs)

### Step 3: Polish

- [ ] Validation
  - [ ] Ensure instructions are safe
  - [ ] Validate config values (no 1000 reps)
  - [ ] Check equipment compatibility
- [ ] Edit mode
  - [ ] Allow manual tweaks to AI output
  - [ ] Text fields for all properties
- [ ] Library management
  - [ ] Option to save to personal library (future: separate from samples)
  - [ ] Tag as AI-generated
- [ ] Quality control
  - [ ] Rate generated exercises (thumbs up/down)
  - [ ] Report issues with generation

### Step 4: Validate

**Happy Path:**
- [ ] Generate exercise → Review → Save to workout → Appears in list
- [ ] Generate exercise → Edit name → Save → Changes persist
- [ ] Generated exercise works in workout execution

**Edge Cases:**
- [ ] AI generates invalid config → Default to timeBased 2min
- [ ] AI returns empty instructions → Show placeholder
- [ ] Generate 10 exercises in a row → All unique

**Quality Checks:**
- [ ] Instructions are clear and actionable
- [ ] Exercise name is unique and descriptive
- [ ] Configuration is appropriate for exercise type
- [ ] Equipment list matches what's used in instructions
- [ ] Benefits are realistic

---

## **🔜 Phase 6: Workout History & Tracking**

**Goal:** Track completed workouts and show user progress

**Estimated Time:** 3-4 hours

### Step 1: UI Design Preview

#### **Enhanced TrainView Home (Stats Widget)**
```
┌─────────────────────────────┐
│  Training                    │
│                              │
│  ┌───────────────────────┐  │
│  │ This Week              │  │
│  │ 🏋️ 3 workouts          │  │ ← NEW widget
│  │ ⏱️ 95 minutes          │  │
│  │ 🔥 5 day streak        │  │
│  │                        │  │
│  │ [View History →]       │  │
│  └───────────────────────┘  │
│                              │
│  Your Workouts (7)           │
│  [Workout Card 1]            │
│  ...                         │
└─────────────────────────────┘
```

#### **Workout History View**
```
┌─────────────────────────────┐
│  [←]  History                │
│─────────────────────────────│
│                              │
│  📊 All Time Stats           │
│  Total Workouts: 23          │
│  Total Time: 12h 45m         │
│  Current Streak: 5 days 🔥   │
│  Longest Streak: 12 days     │
│                              │
│  Recent Workouts             │
│                              │
│  ┌─────────────────────────┐│
│  │ Elite Shooting          ││
│  │ Yesterday • 32 min      ││
│  │ ✅ 6/6 exercises        ││
│  └─────────────────────────┘│
│                              │
│  ┌─────────────────────────┐│
│  │ Speed & Explosiveness   ││
│  │ 2 days ago • 28 min     ││
│  │ ✅ 7/7 exercises        ││
│  └─────────────────────────┘│
│                              │
│  ┌─────────────────────────┐│
│  │ Stickhandling Mastery   ││
│  │ 3 days ago • 30 min     ││
│  │ ⚠️ 5/7 exercises        ││ ← Partial completion
│  └─────────────────────────┘│
└─────────────────────────────┘
```

#### **Workout Detail History**
```
┌─────────────────────────────┐
│  [←]  Elite Shooting         │
│─────────────────────────────│
│                              │
│  Completed Yesterday         │
│  Started: 4:32 PM            │
│  Finished: 5:04 PM           │
│  Duration: 32 minutes        │
│                              │
│  Exercises Completed (6/6)   │
│                              │
│  ✅ Quick Release Snap Shots │
│     50 shots                 │
│                              │
│  ✅ Top Shelf Corner Accuracy│
│     40 shots                 │
│                              │
│  ✅ Backhand Shelf Shots     │
│     30 shots                 │
│                              │
│  ... (3 more)                │
│                              │
│  Notes:                      │
│  Felt strong on backhands    │
│                              │
│  [Share] [Delete]            │
└─────────────────────────────┘
```

#### **Calendar View (Optional)**
```
┌─────────────────────────────┐
│  [←]  January 2025           │
│─────────────────────────────│
│                              │
│  Su Mo Tu We Th Fr Sa        │
│           1  2  3  4  5      │
│  🔥 🔥 🔥 🔥 🔥              │ ← Workout days
│   6  7  8  9 10 11 12       │
│  🔥    🔥       🔥           │
│  13 14 15 16 17 18 19       │
│     🔥    🔥 🔥 🔥 🔥        │
│  ...                         │
└─────────────────────────────┘
```

### Step 2: Implementation Checklist

**New Files:**
- [ ] `Models/WorkoutHistoryModels.swift` - History data models
- [ ] `Storage/WorkoutHistoryStore.swift` - History persistence
- [ ] `Views/WorkoutHistoryView.swift` - History list UI
- [ ] `ViewModels/WorkoutHistoryViewModel.swift` - History logic

**Models:**
```swift
struct WorkoutHistory: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let workoutName: String
    let completedAt: Date
    let startTime: Date
    let endTime: Date
    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
    let exercisesCompleted: [ExerciseCompletion]
    let notes: String?

    var completionRate: Double {
        Double(exercisesCompleted.filter { $0.completed }.count) / Double(exercisesCompleted.count)
    }
}

struct ExerciseCompletion: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let completed: Bool
    let skipped: Bool
    let actualReps: Int?
    let actualSets: Int?
    let actualWeight: Double?
    let actualDuration: TimeInterval?
}

struct UserProgressStats: Codable {
    var totalWorkouts: Int = 0
    var totalMinutes: Int = 0
    var totalCalories: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastWorkoutDate: Date?

    mutating func recordCompletion(_ history: WorkoutHistory) {
        totalWorkouts += 1
        totalMinutes += Int(history.duration / 60)
        // Update streak logic
        updateStreak(completedAt: history.completedAt)
    }

    private mutating func updateStreak(completedAt: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDay = calendar.startOfDay(for: completedAt)

        if let lastDate = lastWorkoutDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: workoutDay).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // Same day = don't change streak
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastWorkoutDate = completedAt
    }
}
```

**Integration Points:**
- [ ] WorkoutExecutionView completion → Save to WorkoutHistoryStore
- [ ] TrainView → Show stats widget
- [ ] New "History" button/tab
- [ ] WorkoutHistoryView → Display list

**Features:**
- [ ] Save workout completion from execution view
- [ ] Load workout history
- [ ] Calculate stats (total workouts, time, streak)
- [ ] Display recent workouts
- [ ] Workout detail view (tap history item)
- [ ] Calendar view (optional)
- [ ] Filter/search history

### Step 3: Polish

- [ ] Stats widget animations
- [ ] Streak fire emoji 🔥
- [ ] Charts/graphs
  - [ ] Workouts per week (bar chart)
  - [ ] Total minutes trend (line chart)
  - [ ] Category breakdown (pie chart)
- [ ] Sharing
  - [ ] Share workout summary to social
  - [ ] Share streak achievement
- [ ] Personal records
  - [ ] Track max weight per exercise
  - [ ] Track best times
  - [ ] Highlight PRs in history

### Step 4: Validate

**Happy Path:**
- [ ] Complete workout → Appears in history
- [ ] Complete workout on consecutive days → Streak increases
- [ ] View history → See all completed workouts
- [ ] Tap history item → See workout details

**Edge Cases:**
- [ ] Complete partial workout (skip exercises) → Shows 5/7 completed
- [ ] Complete workout at 11:59 PM → Next day at 12:01 AM → Streak continues
- [ ] Miss a day → Streak resets to 1
- [ ] Complete 2 workouts same day → Streak doesn't double-count

**Data Integrity:**
- [ ] Kill app during workout → History not saved (OK - workout not completed)
- [ ] Complete workout → Kill app → Reopen → History persists
- [ ] Delete workout → History still shows old completions (workout name preserved)

---

## **🔜 Phase 7: Enhanced Train Home View**

**Goal:** Make TrainView more engaging with stats, quick actions, and recommendations

**Estimated Time:** 2-3 hours

### Step 1: UI Design Preview

#### **Option A: Enhanced Single View**
```
┌─────────────────────────────┐
│  Training                    │
│                              │
│  ┌───────────────────────┐  │
│  │ This Week              │  │
│  │ 🏋️ 3 workouts          │  │
│  │ ⏱️ 95 minutes          │  │
│  │ 🔥 5 day streak        │  │
│  │ [View All Stats →]     │  │
│  └───────────────────────┘  │
│                              │
│  Quick Actions               │
│  ┌──────────┐  ┌──────────┐ │
│  │ ▶️ Resume │  │ 🤖 AI    │ │
│  │   Last    │  │ Generate │ │
│  └──────────┘  └──────────┘ │
│                              │
│  Featured Workouts           │
│  ⭐ Recommended for you      │
│  [Speed & Explosiveness]     │
│                              │
│  Recently Completed          │
│  [Elite Shooting] Yesterday  │
│                              │
│  All Workouts (7)            │
│  [Workout Card 1]            │
│  [Workout Card 2]            │
│  ...                         │
│                              │
│  [+ New Workout]             │
└─────────────────────────────┘
```

#### **Option B: Tabs (Home + Library)**
```
Home Tab:
┌─────────────────────────────┐
│  [Home] [Library]            │
│─────────────────────────────│
│  Good morning! 👋            │
│                              │
│  Your Progress               │
│  🏋️ 3 workouts this week     │
│  🔥 5 day streak             │
│                              │
│  Continue Training           │
│  [Elite Shooting]            │ ← Last workout
│  4 of 6 exercises done       │
│                              │
│  Quick Start                 │
│  ┌──────────┐  ┌──────────┐ │
│  │ 🏒 Skill │  │ 💪 Power │ │
│  │ Builder  │  │ Builder  │ │
│  └──────────┘  └──────────┘ │
│                              │
│  [🤖 AI Generate Workout]    │
└─────────────────────────────┘

Library Tab:
┌─────────────────────────────┐
│  [Home] [Library]            │
│─────────────────────────────│
│  All Workouts (7)            │
│                              │
│  [🔍 Search workouts...]     │
│                              │
│  Filter: [All ▼] [Category ▼]│
│                              │
│  [Workout Card 1]            │
│  [Workout Card 2]            │
│  ...                         │
│                              │
│  [+ New Workout]             │
└─────────────────────────────┘
```

### Step 2: Implementation Checklist

**Design Decision Needed:**
- [ ] Choose Option A (single enhanced view) or Option B (tabs)

**Features (Option A):**
- [ ] Stats widget at top (from Phase 6)
- [ ] Quick action buttons
  - [ ] Resume last workout (if partially complete)
  - [ ] AI generate button
- [ ] Featured/recommended section
  - [ ] Algorithm: least recently done, matches available equipment
- [ ] Recently completed widget
- [ ] All workouts list (existing)

**Features (Option B):**
- [ ] Tab navigation (Home / Library)
- [ ] Home tab
  - [ ] Greeting message
  - [ ] Progress stats
  - [ ] Continue last workout
  - [ ] Quick start presets
  - [ ] AI generate CTA
- [ ] Library tab
  - [ ] Search bar
  - [ ] Filters (category, equipment, duration)
  - [ ] All workouts list
  - [ ] New workout button

### Step 3: Polish

- [ ] Animations
  - [ ] Stats counter animations
  - [ ] Card entrance animations
- [ ] Empty states
  - [ ] First-time user: "Start your first workout!"
  - [ ] No recent activity: Motivational message
- [ ] Personalization
  - [ ] Time-based greeting (Good morning/afternoon/evening)
  - [ ] Smart recommendations based on history
  - [ ] Streak celebrations (5 days, 10 days, etc.)

### Step 4: Validate

**Happy Path:**
- [ ] New user → Sees welcome message + sample workouts
- [ ] Returning user → Sees stats + recent activity
- [ ] Tap resume → Opens last incomplete workout
- [ ] Tap quick action → Launches appropriate flow

**Recommendations Quality:**
- [ ] Featured workouts are relevant
- [ ] Doesn't recommend same workout twice in a row
- [ ] Respects available equipment

---

## 🎨 Design System

### Color Palette
- **Primary:** Green gradient (`theme.primary`)
- **Accent:** Yellow/gold for highlights (`theme.accent`)
- **Success:** Green for completion, streaks
- **Destructive:** Red for delete actions
- **Background:** Dark theme (`theme.background`, `theme.surface`)
- **Text:** White primary, gray secondary (`theme.text`, `theme.textSecondary`)

### Typography
- **Headers:** `.system(size: 42, weight: .bold)` with gradient
- **Titles:** `.system(size: 24, weight: .heavy)`
- **Body:** `.system(size: 15-16, weight: .regular)`
- **Labels:** `.system(size: 11-13, weight: .semibold)` uppercase with tracking

### Key Components

#### **GradientCard**
- Black gradient background with green/accent border
- Used for workout cards, stat widgets
- Shadow for depth

#### **ExerciseCard**
- Dark background with green border
- Icon + name + config summary
- Pencil menu button for actions

#### **GlassFooterButton**
- Glassmorphic bottom button
- Used for primary actions (Start Workout, Save)
- Green border when active

#### **TrainStatusIndicator**
- Glowing dot + label
- Used for status badges (READY, IN PROGRESS, etc.)

#### **EquipmentBadge / CategoryBadge**
- Small pill-shaped badges
- Icon + label
- Semi-transparent background

### Interaction Patterns

#### **Menu-Based Actions**
- All edit/delete actions use Menu (3-dot or pencil icon)
- Consistent across workout and exercise levels
- More discoverable than long-press

#### **Confirmation Alerts**
- Destructive actions (delete workout/exercise) require confirmation
- Alert shows what will be deleted
- Cancel (default) | Delete (destructive red)

#### **Auto-Save**
- Main workout editing auto-saves on every change
- No "Save" button at workout level
- Prevents data loss

#### **Manual Save**
- ExerciseConfigSheet uses manual "Save Changes" button
- Allows experimentation with values
- Can dismiss without saving (revert)

#### **Navigation**
- Full-screen covers for major flows (workout detail, exercise library)
- Sheets for configuration/forms (exercise config, AI generator)
- Standard navigation for history/stats

---

## 🧪 Testing Strategy

### Automated Tests (Future)
- [ ] Unit tests for ExerciseConfig display logic
- [ ] Unit tests for WorkoutRepository CRUD
- [ ] Unit tests for streak calculation
- [ ] Unit tests for AI response parsing

### Manual Testing Checklist

#### **Data Persistence**
- [ ] Add exercise → Kill app → Reopen → Exercise still there
- [ ] Create workout → Kill app → Reopen → Workout still there
- [ ] Delete workout → Kill app → Reopen → Stays deleted
- [ ] Configure exercise → Save → Kill app → Config persists
- [ ] Complete workout → Kill app → History persists

#### **Edge Cases**
- [ ] Empty workout (0 exercises) → Shows empty state
- [ ] Workout with 20+ exercises → Scrolls correctly
- [ ] Exercise name with emoji/special chars → Displays correctly
- [ ] Very long workout name (50+ chars) → Truncates
- [ ] Configure exercise to extreme values (9999 reps) → Allowed but validated
- [ ] Start workout with 0 exercises → Blocked or shows message

#### **User Flows**
- [ ] First launch → 7 sample workouts appear
- [ ] Create custom workout → Add 5 exercises → Save → Appears in list
- [ ] Delete all workouts → Can create new ones → Still shows "+ New Workout"
- [ ] Configure exercise → Dismiss without saving → No changes applied
- [ ] Start workout → Complete all exercises → See summary → Saves to history
- [ ] Start workout → Skip some exercises → Partial completion recorded
- [ ] AI generate → Preview → Edit → Save → Appears in list

#### **All Exercise Config Types**
- [ ] `timeBased` - Timer counts down correctly
- [ ] `repsOnly` - Manual counter works
- [ ] `countBased` - Manual counter works
- [ ] `weightRepsSets` - Shows sets, tracks reps per set, displays weight unit
- [ ] `distance` - Displays distance with correct unit
- [ ] `repsSets` - Tracks sets and reps separately
- [ ] `timeSets` - Timer per set + rest timer between sets

#### **AI Integration**
- [ ] AI generates valid workout → All exercises exist
- [ ] AI generates new exercise → All fields populated
- [ ] AI API fails → Graceful error message
- [ ] AI returns invalid JSON → Fallback behavior
- [ ] Generate 5 workouts → All unique

#### **Performance**
- [ ] 20+ workouts in list → Scrolls smoothly
- [ ] 100+ exercises in library → Search works fast
- [ ] Timer runs for 60 minutes → No performance issues
- [ ] Complete 50 workouts → History loads quickly

---

## 📝 Design Decisions & Rationale

### **Why Auto-Save for Workouts?**
- **Modern UX:** iOS apps (Notes, Reminders, Calendar) all auto-save
- **Prevents Data Loss:** User can't forget to save
- **Less Friction:** No extra button to tap when building workouts
- **User Expectation:** Expected behavior in 2024

### **Why Manual Save for ExerciseConfigSheet?**
- **Experimentation Mode:** Users want to try different values without committing
- **Cancel Option:** Swipe down to dismiss reverts changes
- **Modal Context:** Configuration sheets are temporary, not primary editing
- **Clear Completion Signal:** "Save Changes" = "I'm done"

### **Why Menu Instead of Long-Press?**
- **More Discoverable:** Visible button vs. hidden gesture
- **Consistent Pattern:** Matches 3-dot menu in header
- **Expandable:** Easy to add more actions later (duplicate, share)
- **Accessibility:** Better for users with motor impairments

### **Why Confirmation on Delete?**
- **Destructive Action:** Can't undo deletion
- **User Safety:** Prevents accidental taps
- **Standard Practice:** iOS convention for permanent deletions

### **Why UserDefaults Instead of SwiftData?**
- **Simplicity:** Codable + UserDefaults is straightforward
- **No Dependencies:** Works on iOS 13+
- **Lightweight Data:** ~10 workouts × ~10 exercises = small dataset
- **Battle-Tested:** Same pattern as ShotRaterResultStore
- **Future Migration:** Can migrate to SwiftData later if needed

### **Exercise Config Type Design**
- **Type Safety:** Enum ensures valid configurations
- **Flexibility:** 7 types cover all drill scenarios
- **Auto-Display:** Each config generates its own display string
- **Future-Proof:** Easy to add new types (e.g., `intervals`)

### **Why Phase Order (Custom → Execution → AI)?**
- **Quick Win:** Custom workout creation is 30 minutes, validates persistence
- **User Value:** Execution flow makes app useful (can DO workouts)
- **AI Readiness:** Both need working workouts before AI makes sense
- **Complexity Gradient:** Each phase builds on previous

---

## 🔮 Future Ideas (Backlog)

### Features Not in V1
- [ ] Workout templates by position (Forward, Defense, Goalie)
- [ ] Video demonstrations for exercises (embed YouTube/Vimeo)
- [ ] Social features
  - [ ] Share workouts with team
  - [ ] Public workout library
  - [ ] Follow other users
- [ ] Coach mode
  - [ ] Assign workouts to players
  - [ ] View player progress
  - [ ] Team analytics
- [ ] Apple Watch integration
  - [ ] Start workout from watch
  - [ ] View timer on watch
  - [ ] Track heart rate
- [ ] Offline mode improvements
  - [ ] Download videos for offline
  - [ ] Offline AI (local model)
- [ ] Export/Import
  - [ ] Export workout to PDF
  - [ ] Export to calendar (add workout as event)
  - [ ] Import workouts from file
- [ ] Advanced analytics
  - [ ] Body part focus visualization
  - [ ] Workout balance analysis
  - [ ] Volume/intensity tracking
- [ ] Nutrition integration
  - [ ] Pre/post workout nutrition tips
  - [ ] Calorie burn tracking
  - [ ] Hydration reminders
- [ ] Gamification
  - [ ] Badges/achievements
  - [ ] Leaderboards
  - [ ] Challenges (30-day streaks, etc.)
- [ ] Equipment tracking
  - [ ] Mark owned equipment
  - [ ] Filter workouts by owned equipment
  - [ ] Suggest equipment purchases

### Technical Improvements
- [ ] SwiftData migration (if dataset grows)
- [ ] Image caching for drill images
- [ ] Background audio session (keep music playing during workout)
- [ ] CloudKit sync (multi-device)
- [ ] Unit test coverage
- [ ] UI test coverage
- [ ] Performance monitoring (Firebase Performance)
- [ ] Crash reporting (Firebase Crashlytics)

---

## 📚 References

### Internal
- **AI Infrastructure:** `Modules/AIFeatureKit/AIProcessing/Providers/GeminiProvider.swift`
- **Theme System:** `Modules/DesignSystem/Theme/`
- **Similar Features:** ShotRater (for AI integration patterns)

### External Resources
- [Apple Human Interface Guidelines - Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [Apple Human Interface Guidelines - Modality](https://developer.apple.com/design/human-interface-guidelines/modality)
- [SwiftUI Timer Documentation](https://developer.apple.com/documentation/foundation/timer)
- [Codable Documentation](https://developer.apple.com/documentation/swift/codable)

---

## 🤝 Contributing

### Adding New Exercise Config Types
1. Add case to `ExerciseConfig` enum in `ExerciseModels.swift`
2. Implement `displaySummary` for new type
3. Add configuration UI in `ExerciseConfigSheet.swift`
4. Add timer/counter logic in `WorkoutExecutionView.swift` (when built)
5. Update this documentation

### Adding New Drill Categories
1. Add case to `DrillCategory` enum in `ExerciseModels.swift`
2. Add icon and description
3. Add AI-generated image to `Resources/DrillImages/`
4. Update this documentation

### Modifying Persistence Layer
- **DO:** Maintain Codable compatibility
- **DO:** Test migration from old data format
- **DON'T:** Change storage keys without migration plan
- **DON'T:** Remove fields from models (breaks decoding)

---

## 📊 Success Metrics (Post-Launch)

### Engagement
- **Daily Active Users:** % of users who open Train tab daily
- **Workout Completion Rate:** % of started workouts that are completed
- **Custom Workout Creation:** % of users who create at least 1 custom workout
- **AI Usage:** % of workouts generated by AI vs. manual creation

### Retention
- **7-Day Retention:** % of users who complete a workout in first week
- **28-Day Retention:** % of users who complete 10+ workouts in first month
- **Streak Maintenance:** Average streak length across users

### Feature Adoption
- **Workout Execution:** % of users who use execution flow (vs. just browsing)
- **AI Generation:** % of users who try AI workout generator
- **History Viewing:** % of users who check their workout history

---

## 📝 Change Log

### Version 1.0 (In Development)
- ✅ Exercise models with 7 config types
- ✅ Workout CRUD operations
- ✅ Data persistence (WorkoutRepository)
- ✅ Browse 60+ exercises across 7 categories
- ✅ Configure exercises with all config types
- ✅ Delete confirmations
- ✅ Menu-based actions
- 🔜 Custom workout creation (Phase 2)
- 🔜 Workout execution flow (Phase 3)
- 🔜 AI workout generator (Phase 4)
- 🔜 AI exercise generator (Phase 5)
- 🔜 Workout history & tracking (Phase 6)
- 🔜 Enhanced home view (Phase 7)

---

**Last Updated:** January 2025
**Current Phase:** Phase 2 (Custom Workout Creation)
**Next Milestone:** Custom workout creation button + form

---

## 🟢 GREEN MACHINE HOCKEY PARTNERSHIP STRATEGY

### Partnership Overview
- **Partner:** Green Machine Hockey (@greenmachinehockey)
- **Following:** 2.4M on TikTok
- **Strategy:** Creator-First Home Screen Design
- **Revenue Model:** $14.99/mo premium tier for exclusive content

### OPTION 1: CREATOR-FIRST HOME SCREEN (SELECTED)

#### **NEW USER Experience (First Visit):**
```
┌─────────────────────────────────────────┐
│  🏒 TRAINING                    [Profile]│
│                                          │
│  👋 Welcome to Training!                 │
│  Let's get you started in 30 seconds    │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 🟢 FEATURED: GREEN MACHINE HOCKEY  │ │
│  │                                    │ │
│  │ [Video Preview: "3 Drills to Get   │ │
│  │  Started" - 0:45]                  │ │
│  │                                    │ │
│  │ Elite Stickhandling Starter        │ │
│  │ 3 drills • 15 min • Beginner       │ │
│  │                                    │ │
│  │ [Start This Workout] ──────────────┼→ Instant start
│  └────────────────────────────────────┘ │
│                                          │
│  OR CHOOSE YOUR PATH:                    │
│                                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐│
│  │ 🚀       │ │ 📚       │ │ ➕       ││
│  │ Quick    │ │ Browse   │ │ Create   ││
│  │ Start    │ │ Programs │ │ Custom   ││
│  └──────────┘ └──────────┘ └──────────┘│
│       ↓              ↓            ↓     │
│  Last workout   Templates    Blank      │
│                                          │
│  🎯 RECOMMENDED FOR YOU                  │
│  Based on: Beginner • Forward           │
│                                          │
│  [Forward Power Basics] [Speed 101]     │
│  [Stickhandling Fundamentals]           │
└─────────────────────────────────────────┘
```

#### **RETURNING USER Experience (Has completed 1+ workouts):**
```
┌─────────────────────────────────────────┐
│  🏒 TRAINING                    [+ NEW]  │
│                                          │
│  ⚡ CONTINUE TRAINING                    │
│  ┌────────────────────────────────────┐ │
│  │ Green Machine Stickhandling        │ │
│  │ Session 3 of 12 • 15 min           │ │
│  │                                    │ │
│  │ Progress: ████████░░░░ 67%         │ │
│  │                                    │ │
│  │ [Resume Workout] ──────────────────┼→ 1 tap
│  └────────────────────────────────────┘ │
│                                          │
│  📊 THIS WEEK                            │
│  🔥 4-day streak  •  3 workouts  •  1.2hrs│
│  [View Full Stats] ─────────────────→ 🔒 │
│                                          │
│  🟢 NEW FROM GREEN MACHINE               │
│  ┌────────────────────────────────────┐ │
│  │ [Video Thumb] Pro Toe Drag Secrets │ │
│  │ Just dropped • 12 min              │ │
│  │ [Watch & Train] ───────────────→ 🔒 │ ← Premium
│  └────────────────────────────────────┘ │
│                                          │
│  MY PROGRAMS (3/5 slots) 🔒              │
│  • Green Machine Program (Active)       │
│  • Summer Power Build                   │
│  • Pre-Game Warmup                      │
│  [+ Create New Program]                 │
│                                          │
│  🏒 EXPLORE MORE                         │
│  • Browse All Drills (200+)             │
│  • Community Programs                   │
│  • Position-Specific Training           │
└─────────────────────────────────────────┘
```

#### **[+ NEW] Button Flow:**
```
Tap [+ NEW] →
┌─────────────────────────────────────────┐
│  Create New Workout                      │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 🟢 Start from Green Machine        │ │
│  │ Clone any of his programs          │ │
│  │ [Browse] ──────────────────────────┤ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 📚 Use a Template                  │ │
│  │ Position-specific programs         │ │
│  │ [Browse Templates] ────────────────┤ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 🔁 Duplicate Last Workout          │ │
│  │ Green Machine Session 3            │ │
│  │ [Clone & Customize] ───────────────┤ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ ⚙️ Build from Scratch              │ │
│  │ Full control                       │ │
│  │ [Blank Workout] ───────────────────┤ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Why Creator-First Wins:
- ✅ **Green Machine front & center** = instant credibility with 2.4M followers
- ✅ **No blank slate** = new users get immediate value
- ✅ **Progress tracking** = returning users see wins + new content
- ✅ **Multiple creation paths** = template → custom progression
- ✅ **Clear premium upsell** = new GM content drives revenue

### Monetization Strategy:

**Free Tier (Growth Engine):**
- 5 Green Machine starter workouts
- Basic workout tracking
- Community features (share clips, tag GM)
- 3 saved programs
- **Goal: 10K+ users in Month 1**

**Premium Tier ($14.99/mo or $119/year):**
- **Full Green Machine library** (30+ exclusive programs)
- **Weekly new GM content** (new drills every week)
- **Live Q&A access** (monthly with GM - recorded)
- Unlimited programs
- Advanced analytics
- **Goal: 5-10% conversion = 500-1,000 paid users = $90K-$180K MRR**

**Premium+ Tier ($29.99/mo) - Optional:**
- **1-on-1 form review** by Green Machine (1 per month)
- **Private Discord** with GM
- **Early access** to new programs
- Team features
- **Goal: 100-200 superfans = $36K-$72K MRR**

### Revenue Projections:

**Conservative Estimate (2.4M followers × 0.3% = 7,200 downloads):**
- **Month 1:** 5,000 downloads, 250 premium users = $45K MRR
- **Month 3:** 15,000 downloads, 750 premium users = $135K MRR ✅
- **Month 6:** 30,000 downloads, 1,500 premium users = $270K MRR

**Optimistic Estimate (0.8% conversion):**
- **Month 1:** 20,000 downloads, 1,000 premium users = $180K MRR
- **Month 3:** 50,000 downloads, 2,500 premium users = $450K MRR
- **Month 6:** 100,000 downloads, 5,000 premium users = $900K MRR

**Even 1/3 of optimistic = $300K MRR = 3x the $100K goal** 🚀

### Implementation Plan:

**Phase 1: Core Home Screen (Week 1-2)**
- [ ] Build new TrainView with GM featured section
- [ ] New user onboarding (30-second start)
- [ ] Returning user "Continue Training" widget
- [ ] Weekly stats display

**Phase 2: [+ NEW] Flow (Week 3-4)**
- [ ] Create workout with 4 options:
  1. Clone Green Machine program
  2. Browse templates
  3. Duplicate last workout
  4. Build from scratch

**Phase 3: GM Content Integration (Week 5-6)**
- [ ] Content library structure (starter + premium)
- [ ] Premium paywall UI
- [ ] Program progress tracking
- [ ] Weekly drops section

**Phase 4: Launch Prep (Week 7-8)**
- [ ] Coordinate with Green Machine on content
- [ ] Get 5-10 starter programs
- [ ] Record intro videos
- [ ] Plan TikTok launch campaign
- [ ] Create exclusive launch offer

### Launch Strategy:

**Pre-Launch (Week before):**
- Green Machine teases: "Something big dropping Monday 👀"
- Build anticipation on TikTok/IG
- Email list warm-up

**Launch Day:**
- GM posts: "My hockey training is now in an app! Download free, start training today 🏒"
- Link in bio → App Store/Play Store
- Show him using the app (authentic)

**Week 1 Campaign:**
- Daily TikToks from GM showing different drills
- User-generated content: "#TrainWithGreenMachine"
- Challenge: "Do my 3-drill starter, post progress, tag me"

**Week 2-4:**
- Weekly exclusive drops (premium content)
- Live Q&A announcement (drives premium signups)
- Success stories reshared by GM

### Research-Backed Success Factors:

**From Top Fitness App Analysis:**
- ✅ **Hevy Model:** $160K MRR with creator community approach
- ✅ **Influencer Conversion:** 0.8-1.1% rate proven (TikTok/IG micro-influencers)
- ✅ **Viral Loop:** Social sharing = 32% retention boost (Strava data)
- ✅ **Template-First:** 2.3x higher conversion vs blank canvas
- ✅ **Progressive Disclosure:** 60% higher day-30 retention

**Key Anti-Patterns to Avoid:**
- ❌ No blank slate for new users (kills engagement)
- ❌ No complexity overload (progressive features)
- ❌ No aggressive paywall too early (build habit first)
- ❌ No generic content (GM exclusivity = differentiation)

### Status:
- **Decision:** Option 1 (Creator-First) APPROVED
- **Next Steps:** Build custom workout creation, then implement GM home screen
- **Priority:** Complete Phase 2 first, then revisit home screen redesign

---

## 🎯 SMART ADAPTIVE UI DESIGN (Phase 7 Enhancement)

### Research-Backed Design Principles

**Based on fitness app UX research (2024-2025):**
- ✅ Remove sticky headers from training tab (saves 17% screen space)
- ✅ Streak counters increase engagement by 30%
- ✅ Contextual greetings improve retention by 80% in first week
- ✅ Template-first approach = 2.3x higher conversion vs blank canvas
- ✅ Progressive disclosure = 60% higher day-30 retention

### Header Removal Strategy

**Current State:**
- Home/AI Coach/Equipment tabs: Keep header with logo + profile icon
- **Train tab: REMOVE header** for maximum content space

**Space Allocation Analysis:**
```
BEFORE (with header):
┌─────────────────────┐
│  HOCKEYAPP + Avatar │ ← 100pt (12% of screen)
├─────────────────────┤
│  Training content   │ ← Only 67% usable
│  ...                │
├─────────────────────┤
│  Bottom Nav         │ ← 80pt (9%)
└─────────────────────┘
Total Chrome: 21%

AFTER (without header):
┌─────────────────────┐
│  🔥 3 day streak    │ ← 50pt stats widget (6%)
│  Good morning!      │
├─────────────────────┤
│  Training content   │ ← 84% usable! (+17%)
│  ...                │
├─────────────────────┤
│  Bottom Nav         │ ← 80pt (9%)
└─────────────────────┘
Total Chrome: 15%
```

**Result:** 17% more content space = room for streaks, stats, and featured content

---

### OPTION 4: SMART ADAPTIVE UI (RECOMMENDED)

**Design Philosophy:**
- Adapts based on user journey stage
- New users see onboarding guidance
- Returning users see progress/motivation
- Milestone moments get celebrated
- Never wasted space (only show what's relevant)

---

#### **NEW USER Experience (0 workouts completed)**

```swift
┌─────────────────────────────────────┐
│  👋 Welcome to HockeyApp Training!  │ ← Onboarding greeting
│  Start with our featured workout:   │   (60pt height, 7%)
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐  │
│  │ 🟢 FEATURED: GREEN MACHINE  │  │
│  │                             │  │
│  │  [Hockey player image]      │  │ ← Featured workout
│  │                             │  │   (takes priority)
│  │  Elite Stickhandling Starter│  │
│  │  3 drills • 15 min • ⭐ Beg │  │
│  │                             │  │
│  │  ┌────────────────────────┐ │  │
│  │  │ Start Your First    →  │ │  │
│  │  │ Workout                │ │  │
│  │  └────────────────────────┘ │  │
│  └─────────────────────────────┘  │
│                                     │
│  CHOOSE YOUR PATH                   │
│  ┌──────────────┐ ┌──────────────┐│
│  │ + Create     │ │ 📚 Browse    ││
│  └──────────────┘ └──────────────┘│
└─────────────────────────────────────┘
```

**Why this works:**
- No confusing stats (nothing to show yet)
- Clear call-to-action: "Start Your First Workout"
- Featured content gives instant direction
- Research: 80% retention improvement when new users know what to do

---

#### **RETURNING USER Experience (1-4 day streak)**

```swift
┌─────────────────────────────────────┐
│  🔥 3 days  │  2 this week           │ ← Compact stats bar
│  Keep going!                         │   (50pt, 6%)
├─────────────────────────────────────┤
│  THIS WEEK                    ◀ ▶  │
│  ┌────┬────┬────┬────┬────┬────┐  │
│  │SUN │MON │TUE │WED │THU │FRI │  │
│  │●28 │●29 │●30 │ 1  │ 2  │ 3  │  │ ← Calendar (dots = completed)
│  └────┴────┴────┴────┴────┴────┘  │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ ▶ CONTINUE: Elite Stick...  │  │ ← Resume last workout
│  └─────────────────────────────┘  │   (if incomplete)
│                                     │
│  ┌─────────────────────────────┐  │
│  │ 🟢 FEATURED: GREEN MACHINE  │  │
│  │  [Image]                    │  │
│  │  Elite Stickhandling        │  │
│  │  [Start This Workout →]     │  │
│  └─────────────────────────────┘  │
│                                     │
│  YOUR WORKOUTS                      │
│  ┌─────────────────────────────┐  │
│  │ My Custom Drill             │  │
│  └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Why this works:**
- Streak front and center (motivation)
- Quick resume button (reduce friction)
- Calendar shows training pattern
- Research: 30% engagement boost from visible streaks

---

#### **MILESTONE Experience (5+ day streak)**

```swift
┌─────────────────────────────────────┐
│  ┌───────────────────────────────┐ │
│  │ 🔥🔥🔥 5 DAY STREAK! 🔥🔥🔥    │ │ ← Celebration card
│  │ You're on fire! Keep going!   │ │   (90pt, 11%)
│  │                               │ │
│  │ [██████████] 5 days           │ │ ← Progress to next
│  │ Next milestone: 7 days 🎯     │ │   milestone
│  └───────────────────────────────┘ │
│                                     │
│  THIS WEEK                    ◀ ▶  │
│  ┌────┬────┬────┬────┬────┬────┐  │
│  │SUN │MON │TUE │WED │THU │FRI │  │
│  │●28 │●29 │●30 │●31 │● 1 │ 2  │  │
│  └────┴────┴────┴────┴────┴────┘  │
│                                     │
│  (rest of content...)               │
└─────────────────────────────────────┘
```

**Why this works:**
- Celebrates achievement (dopamine hit)
- Shows progress to next milestone (gamification)
- Creates emotional connection to the app
- Research: Milestone celebrations increase retention

---

### Implementation Specification

#### **Component Structure**

```swift
struct TrainView: View {
    @StateObject private var userStats = UserStatsViewModel()
    @StateObject private var workoutManager = WorkoutViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // NO HEADER ✅

                // DYNAMIC TOP WIDGET
                topWidget
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: userStats.currentStreak)

                // Week Scroller (existing)
                WeekScroller { date in
                    // Handle date selection
                }
                .padding(.horizontal, 4)

                // Resume Last Workout (conditional)
                if let lastWorkout = workoutManager.incompleteWorkout {
                    ContinueWorkoutCard(workout: lastWorkout)
                }

                // Featured Content (existing)
                GreenMachineFeaturedCard(...)

                // Quick Actions (existing)
                quickActionsSection

                // Workouts List (existing)
                workoutsListSection
            }
            .padding()
        }
    }

    @ViewBuilder
    private var topWidget: some View {
        if userStats.totalWorkouts == 0 {
            // NEW USER
            NewUserGreeting()
        } else if userStats.currentStreak >= 5 {
            // MILESTONE
            MilestoneCard(streak: userStats.currentStreak)
        } else {
            // RETURNING USER
            CompactStatsBar(
                streak: userStats.currentStreak,
                weeklyWorkouts: userStats.workoutsThisWeek
            )
        }
    }
}
```

---

#### **1. CompactStatsBar Component**

```swift
struct CompactStatsBar: View {
    let streak: Int
    let weeklyWorkouts: Int
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            // Streak (if > 0)
            if streak > 0 {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(streak) day\(streak == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.text)
                }

                Divider()
                    .frame(height: 16)
            }

            // Weekly workouts
            HStack(spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 14))
                Text("\(weeklyWorkouts) this week")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(theme.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(theme.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
```

**Height:** 50pt (6% of screen)
**Use Case:** Returning users with 1-4 day streak
**Key Info:** Streak + weekly activity at a glance

---

#### **2. NewUserGreeting Component**

```swift
struct NewUserGreeting: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("👋 Welcome to HockeyApp Training!")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.text)

            Text("Start with our featured workout below")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.primary.opacity(0.1))
        )
    }
}
```

**Height:** 60pt (7% of screen)
**Use Case:** New users (0 workouts completed)
**Purpose:** Clear guidance on what to do first
**Research:** 80% retention improvement with onboarding

---

#### **3. MilestoneCard Component**

```swift
struct MilestoneCard: View {
    let streak: Int
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 8) {
            Text("🔥🔥🔥 \(streak) DAY STREAK! 🔥🔥🔥")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("You're on fire! Keep going!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            // Progress bar to next milestone
            let nextMilestone = nextStreakMilestone(current: streak)
            ProgressView(value: Double(streak), total: Double(nextMilestone))
                .tint(.white)
                .padding(.top, 4)

            Text("Next milestone: \(nextMilestone) days 🎯")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            .shadow(color: .orange.opacity(0.5), radius: 10, y: 5)
        )
    }

    private func nextStreakMilestone(current: Int) -> Int {
        let milestones = [7, 14, 30, 60, 100]
        return milestones.first(where: { $0 > current }) ?? current + 10
    }
}
```

**Height:** 90pt (11% of screen)
**Use Case:** Users with 5+ day streak
**Purpose:** Celebrate achievement, show progress to next goal
**Milestones:** 5, 7, 14, 30, 60, 100 days

---

#### **4. ContinueWorkoutCard Component**

```swift
struct ContinueWorkoutCard: View {
    let workout: Workout
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: {
            // Resume workout
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CONTINUE LAST WORKOUT")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textSecondary)

                    Text(workout.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.text)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(theme.primary, lineWidth: 2)
                    )
            )
        }
    }
}
```

**Purpose:** One-tap resume for incomplete workouts
**Shows:** When user has unfinished workout
**Research:** Reduce friction to start training

---

### UserStatsViewModel

```swift
class UserStatsViewModel: ObservableObject {
    @Published var totalWorkouts: Int = 0
    @Published var currentStreak: Int = 0
    @Published var workoutsThisWeek: Int = 0
    @Published var lastWorkoutDate: Date?

    // Load from WorkoutHistoryStore (Phase 6)
    func loadStats() {
        // Calculate from history
    }

    // Called when workout is completed
    func recordCompletion(date: Date) {
        totalWorkouts += 1
        updateStreak(completedAt: date)
        calculateWeeklyWorkouts()
    }

    private func updateStreak(completedAt: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: completedAt)

        if let lastDate = lastWorkoutDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1  // Consecutive day
            } else if daysDiff > 1 {
                currentStreak = 1    // Streak broken
            }
            // Same day = no change
        } else {
            currentStreak = 1
        }

        lastWorkoutDate = completedAt
    }

    private func calculateWeeklyWorkouts() {
        // Count workouts in last 7 days
    }
}
```

---

### Color & Typography Specs

**CompactStatsBar:**
```swift
Background: theme.surface.opacity(0.5)
Border: theme.primary.opacity(0.2), 1pt
Fire emoji: .orange (system)
Streak text: .text (primary), 14pt semibold
Weekly text: .textSecondary, 14pt medium
```

**NewUserGreeting:**
```swift
Background: theme.primary.opacity(0.1)
Title: .text, 16pt semibold
Subtitle: .textSecondary, 14pt regular
```

**MilestoneCard:**
```swift
Background: LinearGradient(.orange → .red)
Shadow: .orange.opacity(0.5), radius 10
Title: .white, 18pt bold
Body: .white.opacity(0.9), 14pt medium
Progress: .white tint
Next goal: .white.opacity(0.8), 12pt regular
```

**ContinueWorkoutCard:**
```swift
Background: theme.surface
Border: theme.primary, 2pt
Play icon: theme.primary, 20pt
Label: .textSecondary, 11pt semibold
Workout name: .text, 15pt medium
```

---

### Animations

```swift
// Widget transitions
.transition(.move(edge: .top).combined(with: .opacity))
.animation(.easeInOut, value: userStats.currentStreak)

// Streak counter on load
.symbolEffect(.bounce)  // iOS 17+

// Milestone card entrance
.transition(.move(edge: .top).combined(with: .scale))
.animation(.spring(response: 0.4, dampingFraction: 0.7))
```

---

### Implementation Phases

**Phase 7A: Basic Adaptive UI (Week 1)**
- [ ] Remove header from TrainView
- [ ] Add CompactStatsBar component
- [ ] Add NewUserGreeting component
- [ ] Add conditional logic (new vs returning user)
- [ ] UserStatsViewModel basic implementation

**Phase 7B: Advanced Features (Week 2)**
- [ ] Add MilestoneCard component
- [ ] Add ContinueWorkoutCard component
- [ ] Implement streak calculation
- [ ] Add animations and transitions
- [ ] Polish visual design

**Phase 7C: Integration (Week 3)**
- [ ] Connect to WorkoutHistoryStore (Phase 6)
- [ ] Test all user states
- [ ] Edge case handling
- [ ] Performance optimization

---

### Testing Checklist

**User States:**
- [ ] New user (0 workouts) → Sees welcome greeting
- [ ] 1-4 day streak → Sees compact stats bar
- [ ] 5+ day streak → Sees milestone card
- [ ] Incomplete workout exists → Shows continue button
- [ ] No incomplete workout → Only shows featured content

**Streak Logic:**
- [ ] Complete workout today → Streak = 1
- [ ] Complete workout 2 consecutive days → Streak = 2
- [ ] Miss a day → Streak resets to 1
- [ ] Complete 2 workouts same day → Streak doesn't change
- [ ] Complete workout at 11:59 PM, next at 12:01 AM → Streak continues

**Visual States:**
- [ ] All components render correctly
- [ ] Transitions are smooth
- [ ] Animations don't interfere with scrolling
- [ ] Colors match theme system
- [ ] Text is readable in light/dark mode

**Edge Cases:**
- [ ] Very long workout names → Truncate
- [ ] 100+ day streak → Shows correct milestone
- [ ] First workout of the week → Shows "0 this week"
- [ ] Kill app during workout → Stats don't update

---

### Success Metrics

**Engagement Goals:**
- 30% increase in daily active users (streak visibility)
- 40% increase in workout completion rate (continue button)
- 80% new user retention in first week (onboarding guidance)

**Conversion Goals:**
- 2.3x higher workout start rate (template-first approach)
- 60% higher day-30 retention (progressive disclosure)

**User Satisfaction:**
- "I love seeing my streak!" sentiment in reviews
- Lower churn rate among users with 5+ day streaks
- Higher engagement during milestone moments

---

### Future Enhancements (Backlog)

- [ ] Social sharing of milestones (Instagram/TikTok)
- [ ] Custom milestone messages (position-specific)
- [ ] Weekly recap notifications
- [ ] Streak freeze (1 per month)
- [ ] Team streaks (train with friends)
- [ ] Seasonal challenges (30-day summer training)

---

**Last Updated:** January 2025
**Status:** Design Complete, Ready for Phase 7 Implementation
**Dependencies:** Phase 3 (Workout Execution), Phase 6 (History Tracking)
**Priority:** High (research shows 30-80% engagement boost)

---
