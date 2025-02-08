# Task 3: 2D Grid Design – Step-by-Step Instructions

Below is a checklist-style instruction document to guide the implementation of the **2D grid design** for the MVP (Week 1) of `scroll2study`. This design aligns with the high-level requirements in [docs/overview.md](../docs/overview.md) and the technical details in [docs/TDD.md](../docs/TDD.md) and [docs/project-architecture.md](../docs/project-architecture.md). **Note**: AI features are not required for this MVP, so focus on the core 2D scrolling and basic video handling.

---

## Goal

- [x] **Implement a 2D grid** where:
  - [x] Horizontal scroll = different subjects
  - [x] Vertical scroll = different complexity levels
  - [x] Each cell in this 2D grid corresponds to a specific [subject + complexity level] pairing and displays the relevant video(s) or a placeholder if no video is available.

---

## Step 1: Ensure Firestore Structure for the Grid

- [x] **Review Firestore Collections**  
  - [x] Confirm that the `subjects` collection and `videos` collection exist (or create them if not).  
  - [x] Each `subject` is identified by an `id` (like `"math"`, `"history"`, etc.) and should include `order` to inform horizontal positioning.
  - [x] Each `video` document should map to a subject + complexity level.  

- [x] **Check for `subjects` Ordering**  
  - [x] Make sure each subject has a numeric `order` field so the app can render them in the correct horizontal order.  
  - [x] Confirm consistency with any existing fields (e.g., `metadata.order` or `position.x`).  

- [x] **Confirm Complexity Level Field**  
  - [x] Verify that each `video` in Firestore includes a `complexityLevel` field (an integer) for straightforward sorting.  
  - [x] If using a separate `complexity_levels` collection, confirm it matches the architecture plan in TDD.

- [x] **Validate Indexing**  
  - [x] Confirm indexing strategy in `api/firestore.indexes.json` (if the queries require combined `subject + complexityLevel` ordering).  
  - [x] Create or update indexes if needed.  

---

## Step 2: Modify Backend (If Needed)

- [x] **Check `addSampleData.js`**  
  - [x] Ensure the sample data includes well-defined subject IDs and complexity levels.  
  - [x] Update or add new entries so the example grid has a range of complexities (e.g., `complexityLevel: 1 to 5`).  

- [x] **Update Endpoints**  
  - [x] If an endpoint is needed to fetch subjects and videos by complexity, confirm or create it in `index.js` or a dedicated file.  
  - [x] For the MVP, the backend might simply return all subjects and their videos, allowing the client to handle rendering.

- [x] **Confirm Authentication**  
  - [x] Users can remain anonymous for the MVP. No special roles are required just to browse the 2D grid.  
  - [x] Make sure the backend does not block anonymous users from making GET requests to fetch the grid.

---

## Step 3: SwiftUI 2D Grid Implementation

- [x] **Create/Refine ViewModel**  
  - [x] In `scroll2study/scroll2study` (iOS code), introduce or update a `ContentGridViewModel` (or equivalent) that:  
    - [x] Fetches a list of subjects (sorted by `order`).  
    - [x] Fetches videos for each subject.  
    - [x] Groups or filters videos by `complexityLevel`.

- [x] **Construct 2D Grid Layout**  
  - [x] In SwiftUI, build a parent view (e.g., `ContentGrid`) that uses nested scrolling:  
    - [x] A horizontal scroll for subjects (e.g., `ScrollView(.horizontal)` in SwiftUI).  
    - [x] Within each `subject` column, a vertical stack or list to represent complexity levels.  

- [x] **Configure LazyVGrid or Equivalent**  
  - [x] Use `LazyVGrid` plus a `ScrollView([.horizontal, .vertical])`, or two nested `ScrollView`s, to achieve 2D movement.  
  - [x] Ensure each subject is placed side by side horizontally, with complexity levels stacked vertically.

- [x] **Define Grid Cells**  
  - [x] Each cell shows a placeholder or a small preview of the video's title, subject, and complexity level.  
  - [x] Optionally show an image thumbnail (if available) or a static icon.

- [ ] **Navigation or Playback Handling**  
  - [ ] For MVP, tapping a cell can navigate to a simple video player view (even if it's a placeholder for now).  
  - [ ] This approach ensures the basic 2D structure is in place.

---

## Step 4: Integrate with Firestore Data

- [x] **Asynchronous Data Fetch**  
  - [x] In the new or existing ViewModel, fetch `subjects` sorted by `order`.  
  - [x] For each `subject`, fetch or filter videos by `complexityLevel`.  
  - [x] Combine them into a data model that the SwiftUI view can iterate over.

- [ ] **Handle Edge Cases**  
  - [ ] If a subject has no videos at a certain complexity level, show a "No Video" placeholder cell.  
  - [ ] If the user is offline, handle any missing data gracefully (show non-blocking placeholders).

- [ ] **Ensure Real-Time Updates**  
  - [ ] Opt to use Firestore snapshots if you want the 2D grid to update in real-time on new data.  
  - [ ] For the MVP, a simple `.getDocuments()` or `.get()` may suffice if real-time updates aren't mandatory yet.

---

## Step 5: Validate the User Flow

- [x] **Test in Simulator**  
  - [x] Launch the iOS app.  
  - [x] Sign in anonymously (no AI needed).  
  - [x] Expect to see a scrollable horizontal list of subjects, each with multiple vertical rows for different complexity levels.  

- [x] **Check Grid Navigation**  
  - [x] Scroll horizontally to switch subjects.  
  - [x] Scroll vertically to see complexity levels from basic to advanced.  

- [x] **Confirm Data Accuracy**  
  - [x] Verify that each cell's subject name, complexity level, or placeholder data is correct.  
  - [x] Provide multiple test subjects and complexity levels to ensure the 2D layout is correct.

---

## Step 6: Documentation & Next Steps

- [ ] **Document Final Steps**  
  - [ ] Update any relevant README or internal doc with instructions on how to populate the grid, referencing the new Firestore structure.  
  - [ ] Add comments in code describing the 2D navigation logic and where it fits into the overall architecture.

- [ ] **Plan Future AI Enhancements**  
  - [ ] AI-driven quizzes or summaries can later hook into these grid cells. For now, ensure the grid scaffolding is stable.

- [x] **Confirm MVP**  
  - [x] Make sure everything requested in the [docs/proj-reqs.md](../docs/proj-reqs.md) for "Week 1 MVP" is satisfied from a front-end perspective:  
    - [x] At least one subject.  
    - [x] A minimal set of complexity levels.  
    - [x] Functioning scroll interactions.  
    - [ ] Placeholder or actual video playback.

---

### Completion Criteria

By the end of Task 3, you should have:
1. [x] A **Firestore** collection for `subjects` that is sorted and used for horizontal navigation.  
2. [x] A straightforward mapping of `videos` to `complexityLevel` for vertical navigation.  
3. [x] A **SwiftUI** layout that enables 2D scrolling with minimal friction.  
4. [ ] Basic user flow handling to tap a cell and move to a more detailed view (or a placeholder).  

_No additional AI features or advanced analytics are needed in this Week 1 scope._  