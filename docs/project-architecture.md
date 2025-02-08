# ReelAI Project Architecture

## Task Progress Tracking

### Task 1: Architecture Planning
- [x] Architecture Planning Section Review
- [x] Tech Stack Confirmation
- [x] Application Layers Planning
- [x] Data Models Definition
- [x] 2D Grid Logic Planning
- [x] Requirements Validation
- [x] Documentation Finalization
- [x] Task Completion Confirmation

## Detailed Architecture Documentation

### Tech Stack Rationale
1. **Frontend (SwiftUI)**
   - Modern, declarative UI framework for iOS
   - Native performance and iOS integration
   - Excellent support for grid-based layouts and animations
   - Required by project specs (native iOS development)

2. **Backend (Firebase + Node.js)**
   - Firebase provides scalable, real-time infrastructure
   - Serverless architecture reduces operational complexity
   - Built-in authentication and file storage
   - Node.js enables custom server logic when needed

3. **AI Integration**
   - OpenAI API for advanced language processing
   - Firebase Generative AI for platform-integrated AI features
   - OpenShot API for video processing
   - LangSmith/LangFuse for AI feature evaluation and monitoring

### Application Layer Architecture

1. **Presentation Layer (SwiftUI)**
   - Components:
     - Views: Grid view, video player, profile views
     - ViewModels: State management and business logic
     - UI Components: Custom controls and animations
   - Responsibilities:
     - Render 2D grid interface
     - Handle user interactions
     - Manage local state
     - Display video content
     - Show AI-generated content (quizzes, summaries)

2. **Domain Layer**
   - Components:
     - Models: User, Video, Quiz, Summary
     - Services: VideoService, UserService, AIService
     - Repositories: Data access interfaces
   - Responsibilities:
     - Business logic implementation
     - Data transformation
     - Domain model management
     - Service coordination

3. **Data Layer**
   - Components:
     - Firebase Repositories: Concrete implementations
     - Local Storage: Cache and offline support
     - Data Models: DTOs and mappers
   - Responsibilities:
     - Data persistence
     - Remote data synchronization
     - Cache management
     - Data mapping

4. **Network Layer**
   - Components:
     - API Clients: Firebase, OpenAI, OpenShot
     - Network Models: Request/Response types
     - Error Handling: Network-specific error types
   - Responsibilities:
     - Handle API communications
     - Manage authentication tokens
     - Network error handling
     - Request/Response parsing

5. **AI Processing Layer**
   - Components:
     - OpenAI Service: Language processing
     - Video Processing Service: OpenShot integration
     - Firebase ML: On-device ML features
   - Responsibilities:
     - Generate quizzes and summaries
     - Process video content
     - Handle AI model interactions
     - Manage AI feature evaluation

6. **Infrastructure Layer**
   - Components:
     - Configuration: Environment and app settings
     - Logging: Application monitoring
     - Analytics: Usage tracking
     - Security: Key management
   - Responsibilities:
     - App configuration
     - Logging and monitoring
     - Analytics collection
     - Security implementation

### Layer Communication Patterns

1. **Dependency Direction**
   - Layers depend only on layers below them
   - Upper layers access lower layers through interfaces
   - Domain layer contains interfaces, implemented by data layer

2. **Data Flow**
   - Presentation → Domain → Data → External Services
   - Each layer transforms data for the layer above
   - Asynchronous operations use Swift's async/await

3. **Event Handling**
   - UI events flow down through layers
   - Data updates flow up through layers
   - Real-time updates use Firebase observers

4. **Error Handling**
   - Each layer has specific error types
   - Errors are transformed as they move up
   - User-facing errors handled in presentation layer

### Key Architectural Decisions
1. **Mobile-First Architecture**
   - Native iOS development using SwiftUI
   - Focus on smooth video playback and grid navigation
   - Optimized for mobile device capabilities

2. **Real-Time Data Layer**
   - Firestore for real-time data synchronization
   - Cloud Functions for backend processing
   - Cloud Messaging for notifications

3. **AI Processing Layer**
   - Serverless functions for AI processing
   - Integration with multiple AI services
   - Video processing pipeline using OpenShot

4. **Security & Authentication**
   - Firebase Auth for user management
   - Secure API key management
   - Role-based access control 

### Data Models

1. **Users Collection (`users`)**
   ```typescript
   interface User {
     id: string;                 // Firebase Auth UID
     username: string;           // Display name
     email: string;             // User's email
     createdAt: Timestamp;      // Account creation date
     lastActive: Timestamp;     // Last activity timestamp
     role: 'creator' | 'consumer'; // User type
     preferences: {
       subjects: string[];      // Preferred subject areas
       difficulty: number;      // Preferred complexity level (1-5)
     };
     progress: {
       [subjectId: string]: {   // Progress by subject
         completedVideos: string[];
         currentLevel: number;
         quizScores: number[];
       }
     };
     achievements: {            // Gamification data
       badges: string[];
       points: number;
     };
   }
   ```

2. **Videos Collection (`videos`)**
   ```typescript
   interface Video {
     id: string;               // Unique video ID
     creatorId: string;        // Reference to users collection
     title: string;           
     description: string;
     subject: string;          // Subject category
     complexityLevel: number;  // 1-5 scale
     metadata: {
       duration: number;       // Video duration in seconds
       thumbnail: string;      // URL to thumbnail
       videoUrl: string;       // URL to video file
       views: number;         
       likes: number;
       createdAt: Timestamp;
     };
     tags: string[];          // Searchable tags
     aiMetadata: {            // AI-generated metadata
       transcript: string;
       keywords: string[];
       summary: string;
     };
     gridPosition: {          // Position in 2D grid
       x: number;            // Subject index
       y: number;            // Complexity level
     };
   }
   ```

3. **Quizzes Collection (`quizzes`)**
   ```typescript
   interface Quiz {
     id: string;
     videoId: string;         // Reference to videos collection
     questions: {
       question: string;
       options: string[];
       correctAnswer: number; // Index of correct option
       explanation: string;   // AI-generated explanation
     }[];
     metadata: {
       difficulty: number;    // 1-5 scale
       timeLimit: number;     // Time limit in seconds
       createdAt: Timestamp;
     };
     stats: {
       attempts: number;
       avgScore: number;
     };
   }
   ```

4. **Summaries Collection (`summaries`)**
   ```typescript
   interface Summary {
     id: string;
     videoId: string;         // Reference to videos collection
     content: {
       mainPoints: string[];  // Key takeaways
       detailedText: string; // Full summary
       keywords: string[];   
     };
     metadata: {
       generatedAt: Timestamp;
       version: number;      // For tracking AI model versions
       model: string;        // AI model used
     };
     userFeedback: {
       helpful: number;      // Number of helpful votes
       notHelpful: number;   // Number of not helpful votes
     };
   }
   ```

5. **Subjects Collection (`subjects`)**
   ```typescript
   interface Subject {
     id: string;
     name: string;           // Subject name
     description: string;
     icon: string;          // URL to subject icon
     order: number;         // Horizontal position in grid
     metadata: {
       videoCount: number;  // Total videos in subject
       activeUsers: number; // Users currently learning
       createdAt: Timestamp;
     };
     prerequisites: string[]; // IDs of prerequisite subjects
   }
   ```

### Collection Relationships

1. **One-to-Many**
   - User → Videos (creator's videos)
   - Video → Quizzes
   - Video → Summaries

2. **Many-to-Many**
   - Users ↔ Videos (through progress tracking)
   - Subjects ↔ Videos (through subject categorization)

3. **Hierarchical**
   - Subjects (prerequisites form a DAG)
   - Videos (complexity levels form vertical hierarchy)

### Data Access Patterns

1. **Grid View**
   ```typescript
   // Query videos by subject and complexity
   videos
     .where('subject', '==', selectedSubject)
     .where('complexityLevel', '<=', userLevel)
     .orderBy('complexityLevel')
     .limit(10)
   ```

2. **User Progress**
   ```typescript
   // Query user's progress in a subject
   users
     .doc(userId)
     .collection('progress')
     .where('subjectId', '==', selectedSubject)
   ```

3. **Video Details**
   ```typescript
   // Get video with related quiz and summary
   const video = await videos.doc(videoId).get();
   const quiz = await quizzes
     .where('videoId', '==', videoId)
     .limit(1)
     .get();
   const summary = await summaries
     .where('videoId', '==', videoId)
     .limit(1)
     .get();
   ```

### 2D Grid Architecture

1. **Grid Structure**
   ```swift
   struct GridPosition {
       let subject: Subject      // Horizontal axis
       let complexity: Int       // Vertical axis (1-5)
   }
   
   struct GridCell {
       let position: GridPosition
       let video: Video?
       let isLocked: Bool
       let isCompleted: Bool
       var prerequisites: [GridPosition]
   }
   ```

2. **Grid Navigation**
   - **Horizontal Navigation (Subjects)**
     ```swift
     class SubjectNavigator {
         // Fetch ordered subjects
         func fetchSubjects() async -> [Subject] {
             return await subjects
                 .orderBy("order")
                 .get()
         }
         
         // Check if subject is unlocked
         func isSubjectUnlocked(_ subject: Subject, 
                              for user: User) async -> Bool {
             let prerequisites = subject.prerequisites
             return await checkPrerequisitesCompleted(prerequisites, user)
         }
     }
     ```
   
   - **Vertical Navigation (Complexity)**
     ```swift
     class ComplexityNavigator {
         // Get available complexity levels
         func getAvailableLevels(for subject: Subject, 
                                user: User) async -> [Int] {
             let userProgress = user.progress[subject.id]
             let maxLevel = userProgress?.currentLevel ?? 1
             return Array(1...min(maxLevel + 1, 5))
         }
         
         // Check if complexity level is accessible
         func isLevelAccessible(_ level: Int, 
                              in subject: Subject,
                              for user: User) async -> Bool {
             let userLevel = user.progress[subject.id]?.currentLevel ?? 0
             return level <= userLevel + 1
         }
     }
     ```

3. **Grid View Implementation**
   ```swift
   struct ContentGrid: View {
       @StateObject private var viewModel: ContentGridViewModel
       
       var body: some View {
           ScrollView([.horizontal, .vertical]) {
               LazyVGrid(columns: subjects) { subject in
                   LazyVStack(spacing: 10) {
                       ForEach(1...5, id: \.self) { level in
                           GridCellView(
                               subject: subject,
                               complexity: level,
                               video: viewModel.videoAt(subject, level)
                           )
                       }
                   }
               }
           }
       }
   }
   ```

4. **Grid Cell States**
   ```swift
   enum CellState {
       case locked          // Prerequisites not met
       case available      // Ready to watch
       case completed      // Watched and quiz passed
       case inProgress    // Partially watched
       case recommended   // AI-suggested next content
   }
   ```

5. **Grid Data Management**
   ```swift
   class ContentGridViewModel: ObservableObject {
       // Cache for visible grid area
       private var visibleCache: [GridPosition: Video] = [:]
       
       // Prefetch adjacent cells
       func prefetchAdjacentCells(_ position: GridPosition) async {
           let adjacent = getAdjacentPositions(position)
           for pos in adjacent {
               if visibleCache[pos] == nil {
                   let video = await fetchVideo(at: pos)
                   visibleCache[pos] = video
               }
           }
       }
       
       // Update cell state
       func updateCellState(_ position: GridPosition, 
                           state: CellState) async {
           guard let video = visibleCache[position] else { return }
           // Update Firestore
           await updateProgress(video, state)
           // Update UI
           objectWillChange.send()
       }
   }
   ```

6. **Grid Interactions**
   ```swift
   extension ContentGridViewModel {
       // Handle cell selection
       func cellSelected(_ position: GridPosition) async {
           guard let video = visibleCache[position] else { return }
           
           if await canAccessCell(position) {
               // Launch video player
               await launchVideo(video)
           } else {
               // Show prerequisites
               await showPrerequisites(position)
           }
       }
       
       // Handle swipe gestures
       func handleSwipe(_ direction: SwipeDirection, 
                       from position: GridPosition) async {
           switch direction {
           case .left, .right:
               await navigateSubjects(direction, from: position)
           case .up, .down:
               await navigateComplexity(direction, from: position)
           }
       }
   }
   ```

7. **Grid State Persistence**
   ```swift
   struct GridState: Codable {
       var lastPosition: GridPosition
       var visibleRange: GridRange
       var completedCells: Set<GridPosition>
       
       func save() async {
           // Save to UserDefaults and Firestore
           await persistGridState(self)
       }
       
       static func restore() async -> GridState {
           // Restore from persistence
           return await loadGridState()
       }
   }
   ```

8. **Performance Optimizations**
   - Implement cell recycling for smooth scrolling
   - Cache videos for adjacent cells
   - Lazy load video thumbnails
   - Use pagination for large grids
   - Maintain viewport information for efficient updates 

### Requirements Validation

1. **Frontend Requirements**
   - ✅ SwiftUI Implementation
     - Matches TDD's specification for native iOS development
     - Grid implementation aligns with SwiftUI best practices
     - Video playback using native components
   
   - ✅ Grid Navigation
     - Horizontal/vertical scroll implementation matches TDD specs
     - Cell states (locked, available, completed) properly tracked
     - Performance optimizations for smooth scrolling implemented

2. **Backend Requirements**
   - ✅ Firebase Services
     - Auth, Firestore, and Storage implementations match TDD
     - Cloud Functions architecture follows serverless pattern
     - Real-time data sync implemented for progress tracking

   - ✅ AI Integration
     - OpenAI integration for quiz/summary generation
     - LangSmith/LangFuse for AI evaluation as specified
     - Proper rate limiting and security measures

3. **Data Model Requirements**
   - ✅ Collection Structure
     - All required collections (users, videos, quizzes, summaries) implemented
     - Schema matches TDD specifications
     - Added subjects collection for better grid organization

   - ✅ Relationships
     - Proper references between collections
     - Efficient querying patterns for grid view
     - Progress tracking structure matches TDD

4. **Grid Implementation Requirements**
   - ✅ Navigation
     - Swipe gestures for subject/complexity navigation
     - Proper state management for grid position
     - Cell recycling for performance

   - ✅ Progress Tracking
     - Visited cells tracking
     - Complexity level progression
     - Prerequisites system

5. **Testing & Performance Requirements**
   - ✅ Testing Strategy
     - Unit tests for grid logic
     - Integration tests for Firebase
     - AI output validation

   - ✅ Performance
     - Lazy loading implementation
     - Caching strategy
     - Viewport optimization

6. **Security Requirements**
   - ✅ Authentication
     - Firebase Auth integration
     - Role-based access
     - Secure API key management

   - ✅ Data Access
     - Proper Firestore rules
     - Rate limiting
     - Error handling

### Areas Needing Attention

1. **Analytics Implementation**
   - [ ] Need to add detailed analytics tracking
   - [ ] Implement user engagement metrics
   - [ ] Add AI performance tracking

2. **Offline Support**
   - [ ] Implement robust caching
   - [ ] Add offline progress tracking
   - [ ] Handle sync conflicts

3. **Social Features**
   - [ ] Plan for future social interactions
   - [ ] Design comment system
   - [ ] Consider sharing features 