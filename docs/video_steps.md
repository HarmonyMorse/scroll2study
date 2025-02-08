# Instruction Document: Seeding Dummy Videos & Enabling Basic Video Feature

Below are step-by-step instructions to align the backend (in the "api" folder) and the iOS app (in the "scroll2study" folder) more closely with the requirements stated in [docs/overview.md], [docs/TDD.md], and [docs/project-architecture.md]. These instructions focus on:

1. Seeding Firestore with dummy video documents.  
2. Adding (or refining) the basic video feature in the iOS app.  

No advanced AI features are required for this Week 1 MVP (see [docs/proj-reqs.md]). Keep the solution limited to essential video metadata storage and retrieval.

---

## Overview

- You have an existing Firestore structure with collections like "subjects," "complexity_levels," and "videos."
- You need a reliable method (script) to add dummy video metadata, so that your iOS front-end can display actual or placeholder videos in the 2D grid.  
- After seeding, you will augment the SwiftUI app so that the grid cells pointing to these video documents can play videos or show placeholders.  

Below is a comprehensive to-do list in logical order.

---

## Part 1: Seeding the Database With Dummy Videos

### 1. Set Up or Update the Seeding Script

- [x] Create or modify a dedicated script in the "api" folder (e.g., "seedVideos.js" or enhance the existing "addSampleData.js").  
- [x] Import your Firebase Admin SDK and connect to Firestore.  
- [x] Define an array of dummy video objects (include fields like "id," "title," "description," "subject," "complexityLevel," "metadata," "isActive," etc.).  
- [x] Ensure each dummy video references a valid subject ID and a complexity level that already exists in Firestore.

### 2. Insert Dummy Videos

- [x] Insert the new videos into the "videos" collection using Firestore Admin APIs.  
- [x] Assign stable IDs if you want to reference them easily in your SwiftUI code (e.g., "math_l1_intro"). Alternatively, let Firestore create an auto ID and log those IDs in the script.  
- [x] Verify that each video has all the fields your SwiftUI code expects (for example, "subject" or "subjectId," "complexityLevel," "metadata.duration," etc.).  
- [x] Add a console log or print statement indicating success or failure after each write.

### 3. Validate the Data

- [x] Run the seeding script locally or in your hosting environment.  
- [x] Check the Firestore console to confirm the new documents are in the "videos" collection with correct fields.  
- [x] Confirm that "subjects" and "complexity_levels" collections reference the same IDs and levels you used in the script to avoid mismatch.

### 4. (Optional) Retrieve and Print Document IDs

- [x] If your seeding script needs to return newly created IDs (when using auto-IDs), log them.  
- [x] Store the resulting IDs somewhere if you plan to upload actual video files in Cloud Storage or another media service.

---

## Part 2: Adding the Basic Video Feature to the iOS App

### 1. Confirm Firestore Fields in iOS Models

- [x] Review "scroll2study/scroll2study/Models/GridModels.swift" (or similar model files) to ensure you have a struct or class representing your video documents.  
- [x] Add or adjust fields if necessary (e.g., a "videoUrl" or "storagePath" field) for playback in SwiftUI.  
- [x] Check that "GridService" or any data-fetching service can pull from the "videos" collection. If not, create or update a new service method to fetch relevant videos.

### 2. Load and Display Video Data

- [x] In "GridService.swift" (or a dedicated VideoService), add a Firestore query to retrieve the newly seeded dummy videos.  
- [x] Store these in an array or dictionary so you can check, for a given Subject + Complexity, if there's a matching video.

### 3. Integrate a Video Player (SwiftUI)

- [x] Add a SwiftUI view that can present a video player. For iOS, consider using "AVPlayer" or a SwiftUI-compatible video player library.  
- [x] Ensure your "GridCell" (in "GridView.swift") can conditionally show:  
  - A playable video when "hasVideo == true," pointing to the video's URL or local resource.  
  - A placeholder when no video is found or "hasVideo == false."

### 4. Handle Playback State

- [x] Provide basic controls to play/pause the video (e.g., a "Play" button or tap-to-play).  
- [x] Optionally, keep track of any playback time or completion status if you want to reflect progress.

### 5. Test on Real or Dummy Video URLs

- [x] If you have real video URLs in Firestore (e.g., referencing a file in Firebase Storage), implement a method to retrieve the download URL.  
- [x] Otherwise, you can embed a short local video or use your dummy metadata to display placeholders.  
- [x] Launch the app on a simulator or device; navigate horizontally and vertically. Confirm that cells with seeded video data show a video player or at least a correct placeholder.

### 6. Verify No AI Features Are Included

- [x] Confirm the MVP meets the "no AI features for Week 1" mandate. You're only focusing on the 2D scroll, subject/complexity navigation, and basic video playback.  
- [x] Remove or comment out any advanced AI logic if it accidentally creeps in.

### 7. Final Checks

### 1. Firestore Rules & Indexes

- [x] Confirm "firestore.rules" allows read access to the "videos" collection for all your user types (or for public read, if that's the plan).  
- [x] Update indexing if you need composite indexes for queries on "subject" + "complexityLevel."  

### 2. Frontend Design Consistency

- [x] In "GridView.swift," ensure your layout logic shows correct placeholders if "hasVideo" is false.  
- [x] If you split video data by subject and complexity level, confirm you use the same ordering fields as in "subjects" (order) and "complexity_levels" (order).

### 3. Documentation & Handoff

- [x] Update any README or internal docs describing how to run the seeding script and where to find the dummy videos.  
- [x] Provide instructions for your team on how to add or modify additional videos in Firestore if needed.  
- [x] Ensure local environment variables (e.g., Firestore credentials) are well-documented so teammates can replicate your setup.

---

## Conclusion

Following these steps will give you:  
• A Firestore collection of dummy videos, correctly associated with existing subjects and complexity levels.  
• A SwiftUI-based UI that can navigate horizontally (by subject) and vertically (by complexity), showing playable or placeholder videos.  

This approach addresses the Week 1 MVP goals without introducing AI features. You'll have a fully functional grid that loads subject pages and complexity tiers, backed by actual or placeholder videos in Firestore. Feel free to iterate on these instructions as your data models evolve.
