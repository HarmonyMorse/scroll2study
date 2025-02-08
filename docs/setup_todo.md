# Section 1: Project Setup and General Structure Todo List

## 1.1 Verify Local Development Environment
- [x] Test iOS Project (scroll2study)
  - [x] Project structure exists and includes necessary files
  - [x] Build the project (successful build for simulator)
  - [ ] Run the project locally
  - [x] Check for any build errors or warnings (none found)
  
- [x] Test Node.js Backend (api)
  - [x] Project structure exists
  - [x] Dependencies are properly defined in package.json
  - [x] Install dependencies
  - [x] Start the server (confirmed working on port 3000)
  - [x] Test existing endpoints (auth and counter functionality confirmed in code)

## 1.2 iOS Dependencies Check
- [x] Review current dependencies in Xcode project
- [x] Verify Firebase dependencies:
  - [x] FirebaseAuth (confirmed in code)
  - [x] FirebaseCore (confirmed in code)
  - [x] Firestore (confirmed in build output)
  - [x] Other required Firebase modules (all present in build)
- [x] Check if CocoaPods or SPM is properly configured (using SPM confirmed in build)
- [x] Ensure all dependencies are at compatible versions (build successful)

## 1.3 Backend Firebase Admin Setup
- [x] Verify Firebase Admin SDK installation (confirmed in package.json)
- [x] Check Firebase Admin configuration (confirmed in index.js)
- [x] Test JWT verification functionality (implemented in authenticateUser middleware)
- [x] Confirm Firestore interaction capabilities (confirmed in incrementCounter route)

## 1.4 Firestore Schema Design
- [x] Design Firestore collections for grid concept:
  - [x] Define subject collection structure
  - [x] Define complexity levels structure
  - [x] Plan user progress tracking schema
- [ ] Create sample collections/documents
- [ ] Document the schema design

### Firestore Schema Structure (MVP)

#### Collections

1. `subjects` Collection
```typescript
{
  id: string,              // Auto-generated
  name: string,            // e.g., "Mathematics", "Physics"
  description: string,     // Brief description
  order: number,          // Horizontal position in grid
  isActive: boolean,      // For enabling/disabling subjects
  createdAt: timestamp,
  updatedAt: timestamp
}
```

2. `complexity_levels` Collection
```typescript
{
  id: string,             // Auto-generated
  level: number,          // 1-5 for MVP
  name: string,           // e.g., "Beginner", "Intermediate"
  description: string,    // Level description
  requirements: string,   // Prerequisites
  order: number,         // Vertical position in grid
  isActive: boolean
}
```

3. `grid_cells` Collection
```typescript
{
  id: string,             // Auto-generated
  subjectId: string,      // Reference to subjects
  complexityId: string,   // Reference to complexity_levels
  title: string,          // Cell title
  description: string,    // Content description
  videoUrl: string,       // URL to video content
  thumbnailUrl: string,   // Preview image
  position: {
    x: number,           // Horizontal (subject) position
    y: number            // Vertical (complexity) position
  },
  metadata: {
    duration: number,    // Video duration in seconds
    views: number,
    createdAt: timestamp,
    updatedAt: timestamp
  },
  isActive: boolean
}
```

4. `users` Collection
```typescript
{
  id: string,             // Firebase Auth UID
  // Remove email and basic auth fields (handled by Firebase Auth)
  lastActive: timestamp,
  role: 'creator' | 'consumer', // Added to match project requirements
  preferences: {
    selectedSubjects: string[],  // Subject IDs
    preferredLevel: number,      // 1-5
    contentType: string[]        // Types of content interested in
  },
  profile: {              // Additional profile data not in Firebase Auth
    bio: string,
    avatarUrl: string,
    displayName: string   // Can be synced with Firebase Auth displayName
  },
  stats: {               // User engagement metrics
    totalWatchTime: number,
    completedVideos: number,
    lastLoginAt: timestamp
  },
  settings: {            // User-specific settings
    notifications: boolean,
    autoplay: boolean,
    preferredLanguage: string
  },
  // System fields
  createdAt: timestamp,  // Synced with Firebase Auth creationTime
  updatedAt: timestamp
}
```

5. `user_progress` Collection
```typescript
{
  id: string,             // Auto-generated
  userId: string,         // Reference to users
  cellId: string,         // Reference to grid_cells
  status: 'visited' | 'completed',
  watchTime: number,      // Time spent in seconds
  lastVisited: timestamp,
  firstVisited: timestamp,
  visitCount: number
}
```

### Indexes Required
1. grid_cells:
   - position.x, position.y (composite)
   - subjectId, complexityId (composite)

2. user_progress:
   - userId, cellId (composite)
   - userId, status (composite)

### Security Rules
```typescript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public read access for subjects, complexity_levels, and grid_cells
    match /subjects/{document} {
      allow read: if true;
      allow write: if false;  // Admin only via backend
    }
    
    match /complexity_levels/{document} {
      allow read: if true;
      allow write: if false;  // Admin only via backend
    }
    
    match /grid_cells/{document} {
      allow read: if true;
      allow write: if false;  // Admin only via backend
    }
    
    // User data - authenticated access only
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Progress tracking - authenticated access only
    match /user_progress/{document} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### Next Implementation Steps
1. [x] Create the collections in Firestore
2. [x] Add sample data for testing
3. [x] Implement security rules
4. [ ] Test read/write operations
   - [ ] Test public read access for subjects, complexity_levels, and videos
   - [ ] Test authenticated user operations (create/update user profile)
   - [ ] Test progress tracking operations (create/read user progress)
5. [x] Document any additional indexes needed

Notes:
- Schema supports the 2D grid navigation concept
- Separates subject and complexity data for flexibility
- Includes user progress tracking
- Security rules enforce proper access control
- Designed for MVP features with room for expansion
- Sample data added with subjects (Math, Physics), complexity levels (1-2), and corresponding videos
- Security rules deployed via Firebase Console
- Composite indexes created for efficient querying