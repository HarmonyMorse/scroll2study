# Next Steps: Implementing the Grid Exploration Progress Feature

Below is a step-by-step outline of tasks needed to align our MVP with the 2D navigation concept described in [docs/overview.md], referencing [docs/TDD.md] and [docs/project-architecture.md]. These tasks focus on creating a user "progress" view (a tab) that displays a grid showing which videos the user has fully watched. They also address the change in how complexity levels are handled when horizontally scrolling between subjects.

Remember: • You have the Firestore rules and data models in place. • AI features (quizzes, summaries, etc.) are out of scope for this MVP. • Only include tasks that are not already implemented. • The aim is to ensure horizontal scrolling resets the complexity to the "easiest" level by default, and to provide a user "progress" interface.

---

## 1. Adjust Horizontal Scrolling Behavior
- [x] Investigate and confirm where in the code to modify the scroll logic (likely in "GridView.swift").
- [x] When the user swipes horizontally to a new subject, reset the vertical (complexity) index to the easiest level available (index 0 or some default).
- [x] Ensure the user remains at their existing complexity level if they scroll back to a previously visited subject (optional, discuss if needed).
- [x] Test the manual swiping flow to verify that moving horizontally forces a reset to the lowest complexity.

## 2. Track Video Completion Status in Firestore
- [x] Decide on a schema to store finished videos. Consider using "user_progress" or a similar collection with fields like:
  • userId  
  • videoId  
  • watchedFull (boolean)  
  • lastWatchedAt (timestamp)  
- [x] For each relevant video playback completion, write an entry (or update an existing one) in the user's progress document.  
- [x] Make sure the Firestore security rules (in "api/firestore.rules") allow each user only to write their own progress documents.

## 3. Firestore Updates from the iOS App
- [x] In "VideoPlayerView" or an equivalent playback management area, trigger a Firestore write/update when a user finishes watching a video.  
- [x] Use the current user's UID from Firebase Auth to set or update the user's progress record.  
- [x] Handle the case where the same user watches the same video multiple times (only update if watchedFull wasn't already true).

## 4. Create the "Progress" Tab
- [x] Add a new tab in "ContentView.swift" (or wherever tabs are configured) to show progress overview.  
- [x] Make a SwiftUI view called "ProgressView" (or similar) that queries "user_progress," "subjects," and "complexity_levels."  
- [x] Dynamically build a grid with columns = number of subjects, rows = number of complexity levels.  
- [x] For each grid cell, check whether "watchedFull" is true for that (subject + complexity) → fill the cell; if not, leave the cell unfilled or partially indicated.

## 5. Populate the Grid Data in the "Progress" Tab
- [x] Fetch all subjects (sorted by "order") and complexity levels (also sorted).  
- [x] Fetch the user's progress documents:
  • Map each videoId from progress to the correct subject and complexity.  
  • Keep a local data structure (e.g., [subjectId: [complexity: Bool]]) indicating completion.  
- [x] Render the grid based on the above structure, marking each cell as completed or incomplete.

## 6. Visual Feedback and Testing
- [x] Implement a clear visual style on the grid cells (e.g., color or icon to show completion).  
- [x] Confirm that, when a user completes a video, the grid cell becomes filled on the next refresh of the "Progress" tab.  
- [x] Thoroughly test horizontal and vertical scrolling to ensure the new logic matches the desired 2D navigation experience.

## 7. (Optional) Additional Progress Features
- [ ] If needed, add user setting toggles for whether they want to see partially watched progress.  
- [ ] Optionally store partial watch time for analytics or future AI features (out of scope for this immediate MVP).

---

**By completing the above steps, the user will see a well-structured "progress" tab that matches the original 2D navigation intent and provides feedback on which topics and complexities they've completed. This approach also ensures horizontal scrolling starts at the easiest complexity each time the user navigates to a new subject.**  