# Instructions: Aligning the Current Codebase with the Overview for the Week 1 MVP

Below is a step-by-step checklist detailing how to adjust the existing backend (api) and iOS app (scroll2study) to better match the high-level vision from docs/overview.md. These instructions draw upon the technical details found in docs/TDD.md and docs/project-architecture.md. AI features are excluded at this stage (per Week 1 MVP in docs/proj-reqs.md).

---

## 1. Project Setup and General Structure
- [x] Verify that both the iOS project (scroll2study) and the Node.js backend (api) are up to date and can run locally without errors.  
- [x] Ensure the iOS project has all standard SwiftUI and Firebase dependencies configured (FirebaseAuth, Firestore, etc.).  
- [x] Confirm that the Node.js backend uses Firebase Admin SDK for JWT verification and Firestore interactions.  
- [x] Decide on a dedicated Firestore layout for the "grid" concept (subject vs. complexity). Create any necessary sample collections or documents.
  - [x] Design schema structure
  - [x] Create collections
  - [x] Add sample data
  - [x] Configure security rules
  - [x] Set up composite indexes

---

## 2. Authentication and User Data
- [x] Confirm user sign-up, sign-in (including guest/anonymous), and sign-out flows are functioning in the iOS app.  
- [x] On successful login, store (or fetch) profile data in Firestore under a "users" collection, which can later be used for grid progress tracking.  
- [x] Validate that the existing Anonymous Auth flow updates the user's local state as described in docs/overview.md (even if minimal for MVP).  

---

## 3. 2D Grid Design (Core to the MVP)
Per docs/overview.md, the most important feature is the 2D scroll system for the MVP:
1. Horizontal scroll = Different subjects.  
2. Vertical scroll = Increasing complexity level.

- [ ] Plan and create a basic SwiftUI structure (e.g., a "GridView") that displays a 2D layout.  
- [ ] Ensure each cell (subject+complexity) is either a static snapshot or a placeholder item for now (video not required yet, but recommended to have placeholders).  
- [ ] Track whether or not a cell has been "visited." In Firestore, create a "visitedCells" sub-collection or a field like "visited: true/false" for each user's visited grid positions.  
- [ ] Add simple user navigation gestures:  
  - [ ] Swipe horizontally to move between subjects.  
  - [ ] Swipe vertically to move between complexity levels.  

---

## 4. Video Playback (Basic MVP)
- [ ] Implement a rudimentary SwiftUI view that plays a placeholder or sample video when users select a cell in the grid.  
- [ ] Use SwiftUI's native video components (e.g., AVPlayer or VideoPlayer in SwiftUI) to keep it simple.  
- [ ] On finishing or dismissing the video, update Firestore so that the user's visited cell is marked as watched.  

---

## 5. Progress Tracking
- [ ] When a user enters a grid cell for the first time, store that "visited" status in Firestore (e.g., /users/{userId}/gridProgress/{subjectId_complexityId}).  
- [ ] In the SwiftUI grid, visually highlight visited cells to indicate progress.  
- [ ] Optionally, provide a small progress summary (e.g., "You have visited X out of Y cells").

---

## 6. Minimizing AI and Advanced Features for MVP
The overview mentions quizzes, AI summaries, and other features, but for Week 1:
- [ ] Skip all AI-driven quizzes and summaries.  
- [ ] Focus on ensuring sign-up, grid navigation, and video playback are stable.  
- [ ] In the code, leave placeholders or comments indicating "AI Quiz / Summaries to be added in Week 2" if needed.

---

## 7. Backend Routes for Basic Grid Data
- [ ] Create or update an endpoint (e.g., GET /grid or GET /subjects) to serve the basic structure of subjects and complexity levels to the iOS app if you want the grid to be dynamic.  
- [ ] Confirm that the incrementCounter route or similar test endpoints are either removed or repurposed. The final MVP should revolve around the grid and progress tracking, not a counter.

---

## 8. Firestore Security Rules
- [ ] Define Firestore rules that allow authorized users to read/write only their own progress data.  
- [ ] Prevent any cross-user writes or unauthorized access.  

---

## 9. Testing
- [ ] Expand test coverage in the Node.js backend to ensure the new Firestore read/write logic (for grid or progress) is tested.  
- [ ] In scroll2studyTests, add tests verifying that after sign-in, the user can fetch or display subject/complexity data.  
- [ ] In scroll2studyUITests, confirm that the 2D grid UI loads and transitions horizontally/vertically without errors.

---

## 10. Deployment (Optional at MVP Stage)
- [ ] (Optional for MVP) Deploy the backend to a service (Firebase Hosting or other) and ensure environment variables for Firebase Admin are set up.  
- [ ] Use TestFlight (or similar) to distribute the iOS build if you want external testers or internal team to test the grid feature.

---

## 11. Future Considerations (Beyond MVP)
∙ The following items should be added after the MVP is stable (Week 2 or beyond):
- AI Quiz Generation (docs/TDD.md references).  
- AI Summaries.  
- Social features like comments or likes.  
- More advanced video library and real-time push notifications.  

---

### Conclusion
By completing each of these steps, the existing codebase will be closer to the 2D-scroll design described in docs/overview.md while following the architectural and technical guidelines in docs/TDD.md and docs/project-architecture.md. This checklist focuses on the core functionalities for Week 1's MVP requirements outlined in docs/proj-reqs.md.   