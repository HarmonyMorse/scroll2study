# Technical Design Document (TDD)

This document describes the technical architecture and design choices behind the 2D TikTok-Inspired Educational App (STUDYnSCROLL") as referenced in [docs/overview.md] and aligned with the requirements outlined by [docs/proj-reqs.md].

---

## 1. Project Overview

This application offers short-form educational videos navigable via a 2D grid:
- Horizontal (subject-based) scroll
- Vertical (complexity-based) scroll

Students explore educational content in a playful, "grid-based" manner reminiscent of TikTok's short-video platform but with an emphasis on structured progression, AI-driven features, and an educational framework.

Key user flows:
1. Grid Overview (top-level map)
2. Video Playback with vertical/horizontal swipe transitions
3. Interactive AI-driven quizzes and summaries
4. Progress tracking on the grid

### Primary Goals
1. Engage users with short and focused educational content.  
2. Provide AI-driven quizzes and smart summaries to reinforce learning.  
3. Offer a grid-based visual overview of learning progress.  

---

## 2. High-Level Architecture

The system consists of the following layers:

1. **Frontend (Mobile App)**
   - Built with Swift/SwiftUI (iOS).
   - Implements the 2D scroll (horizontal for subjects, vertical for complexity).
   - Handles user interactions, video playback, and UI/UX.

2. **Backend Services**
   - **Node.js + Express** providing serverless functions and user-defined endpoints.
   - **Firebase Authentication** for secure, scalable user auth.
   - **Firestore** (NoSQL) storing user progress, metadata, quiz data, and grid structure.
   - **Firebase Cloud Storage** for video-related media assets.
   - **OpenAI** (via serverless functions) for generating dynamic quiz questions and summaries.
   - **LangChain** for capturing AI metrics and chain-of-thought process if needed.

3. **Optional**
   - **Firebase Cloud Messaging** for push notifications.
   - **Analytics** (e.g., Google Analytics for Firebase) for tracking user engagement.

Diagram (simplified):

```
[ Mobile App (SwiftUI) ] 
       |         ^
       v         |
[ Node.js/Express ] --- [ OpenAI API / LangChain ]
       |         ^
       v         |
[ Firebase Services ]
   - Auth
   - Firestore
   - Cloud Storage
   - Cloud Functions
   - (Cloud Messaging)
```

---

## 3. Key Components and Responsibilities

### 3.1 Frontend (SwiftUI)

1. **Grid Screen**  
   - Dynamically renders a 2D "map" of videos (cells = subject + complexity).
   - Highlights visited cells; allows toggling a "Full Grid" to show unvisited topics.  

2. **Video Playback Screen**  
   - Uses SwiftUI's native video player or AVKit.
   - Handles swipes:  
     - Horizontal → Move subject.  
     - Vertical → Move complexity level.

3. **AI Quiz and Summary Overlays**  
   - Retrieves AI-generated quiz questions and summaries from the backend.
   - Displays them post-video or on demand.

4. **User Profile & Library**  
   - Stores progress, saved videos, quiz performance.

### 3.2 Backend Services

1. **Serverless Functions (Node.js/Express)**  
   - Business logic for generating quiz questions via OpenAI.  
   - Summaries creation using AI.  
   - Writes results to Firestore as the user engages with lessons.

2. **Firestore**  
   - Stores user progress, visited grid cells, and quiz results.  
   - Maintains the educational grid schema with subject hierarchy (horizontal) and complexity tiers (vertical).

3. **Firebase Cloud Storage**  
   - Holds video assets, thumbnails, and other media.

4. **Firebase Authentication**  
   - Provides secure login/sign-up.  
   - Supports social logins (Google, Apple ID).

5. **LangChain**  
   - May be used to orchestrate AI prompts and track usage or performance metrics.  
   - Maintains structured prompts, chaining logic for generating tailored content.

---

## 4. Data Model

### 4.1 Firestore Collections

1. **users**  
   - userId (string)  
   - displayName (string)  
   - email (string)  
   - progress (map of subject → complexity level → visited boolean or timestamp)  
   - savedVideos (array of videoIds)

2. **videos**  
   - videoId (string)  
   - subject (string, e.g., "Math", "Art", etc.)  
   - complexityLevel (number, e.g., 1 = Intro, 2 = Intermediate …)  
   - title (string)  
   - description (string)  
   - storagePath (string or URL referencing Cloud Storage)  

3. **quizzes**  
   - quizId (string)  
   - videoId (string, reference to videos)  
   - questionData (dynamic structure: multiple-choice, fill-in, etc.)  
   - correctAnswers (array or string)  

4. **summaries**  
   - summaryId (string)  
   - videoId (string, reference to videos)  
   - summaryText (string, AI-generated text)

### 4.2 AI-Oriented Metadata

- **AI prompts** used to generate quizzes and summaries may be logged in Firestore or in a separate analytics collection for user analytics and debugging.
- **LangChain** logs or chain-of-thought are stored either in a dedicated logging system or partially in Firestore, depending on performance needs.

---

## 5. Feature Implementation

### 5.1 2D Grid Navigation
- **Implementation**: A SwiftUI "List" or "ScrollView" customized to allow both horizontal and vertical navigation. Each axis is mapped to subject vs. complexity.  
- **Rationale**: SwiftUI's flexible layout allows building custom scroll experiences. Alternatively, separate nested horizontal and vertical `ScrollView`s could be used with synchronization logic.

### 5.2 Video Playback
- **Implementation**: Native SwiftUI `VideoPlayer` or AVKit.  
- **Controls**:  
  - Single Tap → pause/resume.  
  - Double Tap → "Deeper dive" (or recommended similar topic).  
  - Tap & Hold → Save to library.

### 5.3 AI Quizzes
- **Flow**:  
  1. Upon video end, client triggers an endpoint (via Cloud Functions).  
  2. The endpoint requests quiz questions from OpenAI with a structured prompt (possibly using LangChain).  
  3. The generated quiz is stored in Firestore; client fetches it to display.  
- **Question Types**: Multiple choice, fill-in-the-blank, short answer.

### 5.4 Smart Summaries
- **Flow**:  
  1. On video upload or after user requests a summary, serverless function calls OpenAI.  
  2. The summary is stored under a "summaries" collection keyed by videoId.  
  3. Users can view the summary in the app.

### 5.5 Progress and "Full Grid" Feature
- **Implementation**:
  - Each visited session updates Firestore with user's visited cell info: (subject, complexity level).  
  - "Full Grid" toggles between showing all cells vs. only visited cells.  

---

## 6. AI Integration (LangChain + OpenAI)

### 6.1 LangChain Flow for Quiz Generation
1. Node.js function receives a request from the client with the video details (title, transcript).  
2. LangChain loads a "quiz generation" chain, injecting the transcript as context.  
3. The chain queries OpenAI for quiz questions and obtains relevant answers.  
4. The results are returned to the Node.js function, stored in Firestore, and served to the client.

### 6.2 Summaries with OpenAI
- A single prompt or chain is used to produce a bullet-point summary of the key educational points in the video.  
- Possibly includes best practices: "Key Terms", "Quick Recap", or "Discussion Points".

### 6.3 Security & Rate Limits
- Use Firebase Authentication tokens to confirm valid users.  
- Leverage rate-limiting or usage checks on the serverless function level to avoid excessive OpenAI calls.

---

## 7. Persistent Storage

- **Firestore** is the primary store for user data, quiz data, and summaries.  
- **Firebase Cloud Storage** houses all media (videos, thumbnails).  
- **CDN Delivery** ensures quick load times (videos are streamed or progressively downloaded from Cloud Storage).

---

## 8. Deployment & CI/CD

- **Firebase Hosting** (for static or web admin tools if needed).  
- **iOS App Distribution**:
  - Use TestFlight or Firebase App Distribution for QA builds.  
  - Eventually deploy to the Apple App Store.
- **Cloud Functions** automatically deployed from GitHub or via Firebase CLI.
- **Continuous Integration**:
  - GitHub Actions or similar pipeline for building SwiftUI code and testing.  
  - Automated test runs (unit + UI tests) before merges to main.

---

## 9. Testing Strategy

1. **Unit Tests**:
   - Frontend (Xcode): XCTest for SwiftUI components
   - Backend (Vitest): Unit tests for API endpoints and business logic
   - Command: `npm test` runs Vitest in watch mode
2. **Integration Tests** (Firebase Test Lab):
   - Check end-to-end flows: from user login to video playback to quiz generation.
3. **AI Output Testing**:
   - Automatic checks comparing generated quiz questions to the video transcript for consistency.
   - Validate summary length, grammar, and presence of essential key points.
4. **Performance Testing**:
   - Evaluate load times for video playback, quiz generation, and summary fetching.

---

## 10. Future Enhancements

1. **Advanced Analytics**  
   - Offer personalized learning paths based on user performance.
2. **Multi-Platform**  
   - Extend to Android (Kotlin) or cross-platform solutions.
3. **Social Interactions**  
   - Likes, comments, and user feedback on each lesson or quiz.
4. **Caption & Translation**  
   - Use AI for real-time translation and closed-caption generation to broaden accessibility.

---

## 11. Conclusion

This Technical Design Document outlines the structural and architectural decisions driving the 2D TikTok-Inspired Educational App. By combining game-like grid navigation with short-form video, AI-driven quizzes, and summaries, we aim to deliver a unique and engaging educational experience. The combination of SwiftUI (frontend), Firebase (backend), and OpenAI (AI capabilities) ensures a scalable, robust solution aligned with the requirements from [docs/overview.md] and [docs/proj-reqs.md].