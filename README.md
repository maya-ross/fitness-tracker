# Fitness Tracker - iOS Native App

A modern SwiftUI-based fitness tracking application for iOS that allows users to create, track, and manage their workout routines.

---

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Technical Architecture](#technical-architecture)
4. [Database Schema](#database-schema)
5. [Authentication](#authentication)
6. [Exercise Library](#exercise-library)
7. [Testing Strategy](#testing-strategy)
8. [Implementation Steps](#implementation-steps)
9. [Dependencies](#dependencies)
10. [Questions for Clarification](#questions-for-clarification)

---

## Overview

**Platform:** iOS (iPhone & iPad)  
**Minimum iOS Version:** iOS 15.0+ (recommended for modern SwiftUI features)  
**Language:** Swift 5.5+  
**UI Framework:** SwiftUI  
**Target Audience:** Fitness enthusiasts who want to track their weight training and bodyweight exercises

### Purpose
The Fitness Tracker app enables users to:
- Sign in securely via Google OAuth
- Browse a comprehensive library of 100 pre-populated popular exercises
- Add custom exercises to their personal library
- Create and manage workouts with multiple exercises
- Track sets, reps, and weights for each exercise
- Mark workouts as completed

---

## Features

### 1. User Authentication
- **Google OAuth Sign-In:** Users authenticate using their Google account
- **Persistent Login:** User session maintained across app launches
- **Sign Out:** Users can sign out from the app

### 2. Exercise Library
- **Pre-populated Library:** 100 most popular weight training and bodyweight exercises
- **Exercise Details:** Each exercise includes:
  - Name (e.g., "Barbell Bench Press")
  - Short description (e.g., "Chest exercise targeting pectorals, performed lying on a bench")
- **Search Functionality:** Users can search exercises by name
- **Add Custom Exercise:** Users can add their own exercises with name and description
- **Persistent Storage:** Exercises saved locally and synced with user account

### 3. Workout Creation & Management
- **Create Workout:** Users can create a new workout with:
  - Workout name (e.g., "Upper Body Day")
  - Date (defaults to current date, user can change)
  - List of exercises
- **Add Exercises to Workout:** 
  - Search exercise library
  - Select exercise to add
  - Specify number of reps
  - Specify weight used in pounds (lbs)
  - Can add same exercise multiple times for multiple sets
- **Workout States:**
  - **Not Started (default):** Initial state when workout is created
  - **Completed:** User marks workout as completed after finishing
- **View Workouts:** List of all workouts with status indicators
- **Edit Workouts:** Modify workout details before completion (question: should completed workouts be editable?)

### 4. User Interface
- **Home Screen:** Dashboard showing recent/upcoming workouts
- **Exercise Library Screen:** Searchable list of exercises with add custom exercise option
- **Workout Creation Screen:** Multi-step flow for building a workout
- **Workout Detail Screen:** View/edit workout details and mark as complete
- **Profile Screen:** User info, sign out option

---

## Technical Architecture

### Design Pattern
**MVVM (Model-View-ViewModel)** with SwiftUI
- **Models:** Data structures (User, Exercise, Workout, WorkoutExercise)
- **Views:** SwiftUI views for each screen
- **ViewModels:** Business logic, data management, API calls
- **Services:** Authentication, Database, Network services

### Key Components

#### 1. Authentication Service
- **GoogleSignIn SDK** integration
- Token management
- User session handling

#### 2. Database Layer
- **Primary Storage:** Core Data for local persistence
- **Alternative Option:** SwiftData (iOS 17+) - Question: Which should we use?
- **Cloud Sync:** CloudKit for syncing across user devices (optional - Question: Is cloud sync required?)

#### 3. Data Models

**User**
- `id`: UUID
- `googleId`: String
- `email`: String
- `displayName`: String
- `createdAt`: Date

**Exercise**
- `id`: UUID
- `name`: String
- `description`: String
- `isCustom`: Bool (true if user-created, false if pre-populated)
- `userId`: UUID? (null for pre-populated, user ID for custom)
- `createdAt`: Date

**Workout**
- `id`: UUID
- `userId`: UUID
- `name`: String
- `date`: Date
- `status`: String (enum: "not_started", "completed")
- `completedAt`: Date? (timestamp when marked complete)
- `createdAt`: Date
- `updatedAt`: Date

**WorkoutExercise** (junction table for workout-exercise relationship)
- `id`: UUID
- `workoutId`: UUID
- `exerciseId`: UUID
- `reps`: Int
- `weightLbs`: Double
- `orderIndex`: Int (to maintain order of exercises in workout)
- `notes`: String? (optional - for user notes per exercise)

#### 4. Network Layer
- Google OAuth API integration
- Error handling and retry logic
- Network reachability checking

#### 5. State Management
- `@StateObject` and `@ObservedObject` for ViewModels
- `@EnvironmentObject` for shared state (AuthenticationManager, DatabaseManager)
- Combine framework for reactive updates

---

## Database Schema

### Core Data Entities

#### User Entity
```
User
├── id: UUID (Primary Key)
├── googleId: String
├── email: String
├── displayName: String
└── createdAt: Date
```

#### Exercise Entity
```
Exercise
├── id: UUID (Primary Key)
├── name: String (indexed for search)
├── description: String
├── isCustom: Boolean
├── userId: UUID? (nullable, foreign key to User)
└── createdAt: Date
```

#### Workout Entity
```
Workout
├── id: UUID (Primary Key)
├── userId: UUID (foreign key to User)
├── name: String
├── date: Date (indexed)
├── status: String (not_started | completed)
├── completedAt: Date? (nullable)
├── createdAt: Date
├── updatedAt: Date
└── workoutExercises: Relationship (one-to-many with WorkoutExercise)
```

#### WorkoutExercise Entity
```
WorkoutExercise
├── id: UUID (Primary Key)
├── workoutId: UUID (foreign key to Workout)
├── exerciseId: UUID (foreign key to Exercise)
├── reps: Integer
├── weightLbs: Double
├── orderIndex: Integer
├── notes: String? (nullable)
├── workout: Relationship (many-to-one with Workout)
└── exercise: Relationship (many-to-one with Exercise)
```

### Relationships
- User → Workouts (one-to-many)
- User → Exercises (one-to-many, for custom exercises)
- Workout → WorkoutExercises (one-to-many)
- Exercise → WorkoutExercises (one-to-many)

---

## Authentication

### Google OAuth Integration

#### Setup Requirements
1. Create Google Cloud Project
2. Enable Google Sign-In API
3. Configure OAuth consent screen
4. Create iOS OAuth client ID
5. Add URL schemes to Info.plist

#### Implementation
- Use **Google Sign-In for iOS SDK** (pod 'GoogleSignIn')
- Store user credentials securely in Keychain
- Implement token refresh logic
- Handle sign-in errors gracefully

#### User Flow
1. Launch app → Check for existing session
2. If not authenticated → Show sign-in screen
3. User taps "Sign in with Google"
4. Google OAuth flow (browser redirect)
5. Return to app with tokens
6. Store user info in Core Data
7. Navigate to home screen

---

## Exercise Library

### Pre-populated Exercises (100 Most Popular)

The app should be pre-seeded with the following categories of exercises:

#### Weight Training Exercises (~60 exercises)

**Chest (8-10 exercises)**
- Barbell Bench Press
- Dumbbell Bench Press
- Incline Barbell Bench Press
- Incline Dumbbell Bench Press
- Decline Bench Press
- Dumbbell Flyes
- Cable Crossover
- Push-ups (weighted variation)
- Chest Dips

**Back (10-12 exercises)**
- Deadlift
- Barbell Row
- Dumbbell Row
- Pull-ups
- Chin-ups
- Lat Pulldown
- Seated Cable Row
- T-Bar Row
- Face Pulls
- Hyperextensions

**Shoulders (8-10 exercises)**
- Overhead Press (Barbell)
- Dumbbell Shoulder Press
- Arnold Press
- Lateral Raises
- Front Raises
- Rear Delt Flyes
- Upright Row
- Shrugs

**Arms (10-12 exercises)**
- Barbell Curl
- Dumbbell Curl
- Hammer Curl
- Preacher Curl
- Cable Curl
- Tricep Dips
- Close-Grip Bench Press
- Tricep Pushdown
- Overhead Tricep Extension
- Skull Crushers

**Legs (10-12 exercises)**
- Barbell Squat
- Front Squat
- Leg Press
- Romanian Deadlift
- Leg Curl
- Leg Extension
- Lunges
- Bulgarian Split Squat
- Calf Raises
- Hip Thrust

**Core (4-6 exercises)**
- Plank
- Side Plank
- Ab Wheel Rollout
- Hanging Leg Raises
- Cable Crunches

#### Bodyweight Exercises (~40 exercises)

**Upper Body (15-20)**
- Push-ups (standard)
- Diamond Push-ups
- Wide Push-ups
- Pike Push-ups
- Decline Push-ups
- Pull-ups (various grips)
- Chin-ups
- Dips
- Inverted Rows
- Handstand Push-ups

**Lower Body (10-12)**
- Bodyweight Squats
- Pistol Squats
- Jump Squats
- Lunges
- Bulgarian Split Squats
- Glute Bridges
- Single-Leg Deadlift

**Core (8-10)**
- Crunches
- Sit-ups
- Russian Twists
- Mountain Climbers
- Bicycle Crunches
- V-ups
- Hollow Body Hold

**Full Body/Cardio (5-8)**
- Burpees
- Jumping Jacks
- High Knees
- Box Jumps (step-ups)

### Data Source
Pre-populated exercises should be loaded from a JSON file bundled with the app, inserted into Core Data on first launch.

**JSON Structure Example:**
```json
[
  {
    "name": "Barbell Bench Press",
    "description": "Compound chest exercise performed lying on bench, pressing barbell from chest to full arm extension",
    "isCustom": false
  },
  {
    "name": "Pull-ups",
    "description": "Bodyweight back exercise, pulling body up to bar until chin clears the bar",
    "isCustom": false
  }
]
```

---

## Testing Strategy

### Testing Framework
- **XCTest** for unit and integration tests
- **XCTestUI** for UI testing
- **Target Coverage:** Minimum 70% code coverage for business logic

### Test Categories

#### 1. Unit Tests
**Models**
- Test model initialization
- Test data validation
- Test computed properties

**ViewModels**
- Test data fetching logic
- Test state changes
- Test error handling
- Mock dependencies (database, authentication)

**Services**
- Test authentication flow (mocked)
- Test database CRUD operations
- Test search functionality

#### 2. Integration Tests
- Test full workout creation flow
- Test exercise library operations
- Test data persistence and retrieval
- Test user session management

#### 3. UI Tests
- Test navigation flows
- Test sign-in process (with test account)
- Test workout creation user journey
- Test exercise search
- Test marking workout as complete

#### 4. Test Data
- Create mock exercise data
- Create test user credentials
- Use in-memory Core Data store for tests

---

## Implementation Steps

The following steps outline the development process for building this app. Each step should be implemented, tested, and verified before moving to the next.

### Phase 1: Project Setup & Foundation

#### Step 1: Initialize Xcode Project
- Create new iOS App project with SwiftUI
- Set minimum deployment target to iOS 15.0
- Configure bundle identifier
- Set up Git repository (already done)
- Configure project structure (Models, Views, ViewModels, Services folders)

#### Step 2: Set Up Dependencies
- Create Podfile and install CocoaPods (or use SPM)
- Add Google Sign-In SDK
- Add any additional dependencies (e.g., Kingfisher for images if needed)
- Configure Info.plist for Google OAuth

#### Step 3: Create Core Data Stack
- Set up Core Data container
- Create all entity definitions (User, Exercise, Workout, WorkoutExercise)
- Set up relationships and constraints
- Create DatabaseManager service
- Implement CRUD operations
- Add migration support

### Phase 2: Authentication

#### Step 4: Implement Google OAuth
- Set up Google Cloud project and OAuth credentials
- Configure GoogleSignIn in AppDelegate/SceneDelegate
- Create AuthenticationManager service
- Implement sign-in flow
- Implement sign-out flow
- Store user session in Keychain
- Handle token refresh

#### Step 5: Create Authentication UI
- Create SignInView with Google Sign-In button
- Create splash/loading screen
- Implement authentication state routing
- Add error handling and user feedback
- Test sign-in/sign-out flows

### Phase 3: Exercise Library

#### Step 6: Prepare Exercise Data
- Create exercises.json with 100 pre-populated exercises
- Research and compile the most popular exercises from:
  - Bodybuilding.com
  - StrongLifts 5x5
  - Starting Strength
  - Popular fitness programs
- Include accurate descriptions for each exercise
- Bundle JSON file with app

#### Step 7: Implement Exercise Library Features
- Create Exercise model and Core Data entity
- Implement exercise data seeding (first launch only)
- Create ExerciseLibraryViewModel
- Implement search functionality
- Create ExerciseLibraryView (list with search)
- Create ExerciseDetailView
- Create AddExerciseView for custom exercises
- Test exercise CRUD operations

### Phase 4: Workout Management

#### Step 8: Implement Workout Models
- Create Workout and WorkoutExercise models
- Set up Core Data entities and relationships
- Create WorkoutManager service
- Implement workout CRUD operations

#### Step 9: Create Workout UI - Listing & Details
- Create WorkoutsListView (shows all workouts)
- Create WorkoutCardView component
- Implement workout status indicators
- Create WorkoutDetailView
- Add mark as complete functionality
- Test workout state changes

#### Step 10: Create Workout Creation Flow
- Create CreateWorkoutView
- Implement workout name input
- Implement date picker
- Create AddExerciseToWorkoutView
  - Exercise search/selection
  - Reps input field
  - Weight input field
  - Add to workout list
- Handle multiple exercises in workout
- Implement exercise ordering
- Save workout to database
- Test complete workout creation flow

### Phase 5: Home Screen & Navigation

#### Step 11: Implement Home Screen
- Create HomeView dashboard
- Show recent workouts
- Show upcoming/scheduled workouts
- Quick action buttons
- Navigation to other screens

#### Step 12: Set Up Navigation
- Implement TabView or NavigationView structure
- Create navigation between screens:
  - Home
  - Exercise Library
  - Create Workout
  - Workouts List
  - Profile/Settings
- Test navigation flows

### Phase 6: Polish & Features

#### Step 13: Implement Profile Screen
- Display user information
- Sign out button
- App version info
- Link to settings (if needed)

#### Step 14: Add Error Handling & Validation
- Validate user inputs (workout name, reps, weight)
- Add error messages and alerts
- Handle network errors gracefully
- Handle database errors
- Add loading states

#### Step 15: Improve UX/UI
- Add animations and transitions
- Implement pull-to-refresh where appropriate
- Add empty states (no workouts, no exercises)
- Improve accessibility (VoiceOver support)
- Test on different screen sizes (iPhone, iPad)

### Phase 7: Testing

#### Step 16: Write Unit Tests
- Test all ViewModels
- Test models and business logic
- Test services (with mocks)
- Achieve 70%+ code coverage

#### Step 17: Write Integration Tests
- Test workout creation end-to-end
- Test authentication flow
- Test data persistence

#### Step 18: Write UI Tests
- Test critical user journeys
- Test navigation
- Test data entry forms

### Phase 8: Optimization & Deployment

#### Step 19: Performance Optimization
- Profile app for memory leaks
- Optimize Core Data queries
- Optimize image loading (if any)
- Test on older devices

#### Step 20: Prepare for App Store
- Add app icon
- Create launch screen
- Add privacy policy (required for OAuth)
- Configure App Store listing
- Create screenshots
- Submit for review (if desired)

---

## Dependencies

### Required Frameworks & Libraries

#### Core iOS Frameworks
- SwiftUI (UI framework)
- Combine (reactive programming)
- Core Data (local persistence)
- Foundation (core utilities)

#### Third-Party Dependencies

**Authentication**
- **GoogleSignIn** (~> 7.0)
  - Purpose: Google OAuth authentication
  - Installation: CocoaPods or Swift Package Manager

**Optional Dependencies** (Question: Are these needed?)
- Networking library (Alamofire?) - Built-in URLSession may be sufficient
- Image loading library - Not needed unless we add exercise images
- Analytics (Firebase Analytics?) - Question: Do we want analytics?

### Dependency Management
**Recommended:** Swift Package Manager (native to Xcode)
**Alternative:** CocoaPods

---

## Questions for Clarification

The following questions need answers to finalize the specification:

### 1. Database & Sync
- **Question:** Should workouts and custom exercises sync across user devices via CloudKit/iCloud?
- **Impact:** Affects architecture complexity and data model design
- **Recommendation:** Start with local-only storage, add sync in future version

### 2. iOS Version Target
- **Question:** Should we target iOS 15.0 (wider compatibility) or iOS 17.0 (latest features like SwiftData)?
- **Impact:** Affects available APIs and potential user base
- **Recommendation:** iOS 15.0 for broader compatibility

### 3. Workout Editing
- **Question:** Can users edit completed workouts? Or should they be locked?
- **Impact:** UI flow and data validation logic
- **Recommendation:** Allow editing with warning message, or lock after completion

### 4. Exercise Sets
- **Question:** The spec mentions adding exercises with reps and weight. Should users be able to add multiple sets of the same exercise (e.g., 3 sets of bench press with different weights)?
- **Current assumption:** Yes, user adds same exercise multiple times for each set
- **Alternative:** Have a "sets" field and array of reps/weights per exercise
- **Recommendation:** Keep it simple - add exercise multiple times for now

### 5. Exercise Images
- **Question:** Should exercises have accompanying images/videos?
- **Impact:** Significantly increases app size and development time
- **Recommendation:** Start without images, add in future version

### 6. Historical Tracking
- **Question:** Should the app show historical progress (e.g., weight progression over time for an exercise)?
- **Impact:** Requires analytics views and charts
- **Recommendation:** Future feature, not in v1

### 7. Workout Templates
- **Question:** Should users be able to save workouts as templates for reuse?
- **Impact:** Adds another model and UI flow
- **Recommendation:** Future feature, not in v1

### 8. Backend Server
- **Question:** Do we need a backend server, or is local storage + Google Auth sufficient?
- **Current assumption:** Local storage only (Core Data)
- **Impact:** Affects architecture significantly
- **Recommendation:** Local storage for v1, backend for multi-device sync later

### 9. Offline Support
- **Question:** Should the app work fully offline (except sign-in)?
- **Recommendation:** Yes, Core Data enables full offline functionality

### 10. Data Export
- **Question:** Should users be able to export their workout data (CSV, PDF)?
- **Recommendation:** Future feature, not in v1

---

## Getting Started for Developers

Once this specification is approved, the Copilot coding agent should:

1. Review this entire README
2. Ask for answers to any unresolved questions
3. Proceed through implementation steps 1-20 sequentially
4. Request review after completing each phase
5. Make adjustments based on feedback

---

## Version History

- **v1.0 (Planned)** - Initial release with core features outlined above

---

## License

[To be determined]

---

## Contact

[Project maintainer contact information]
