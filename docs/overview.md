# STUDYnSCROLL: Scholars Traveling Uncharted Domains, Yearning navigable Scrolls of Curated Resources for Outstanding Learning and Literacy

## Project Description
This app is modeled on the social video experience popularized by TikTok but tailored for an **educational niche**. The major design twist is a **2D scroll** interface, allowing users to navigate both horizontally and vertically:
- **Vertical Scroll** adjusts the *complexity level* of the content—ranging from basic to advanced.  
- **Horizontal Scroll** allows users to browse different subject areas—ranging from arts to sciences.

Instead of an infinite feed, the app uses a **preset "grid" of topics** built by educators. Users can visually see which parts of the grid they have explored—like a video game map that highlights "visited" nodes.

## Primary User Flow
1. **Grid Overview**  
   - The user sees a grid of topics on a map-like UI.  
   - Each cell represents a combination of *complexity level* (vertical) and *subject area* (horizontal).

2. **Scrolling and Playback**  
   - Swiping up/down moves to higher or lower complexity videos on the same subject.  
   - Swiping left/right shifts to adjacent subject areas at the same complexity level.

3. **Basic Interactions**  
   - **Tap**: Pauses/resumes the video.  
   - **Double Tap**: Shows a recommended video ("similar to current topic")—an optional "deeper dive" feature.  
   - **Tap & Hold**: Adds the current video to the user's personal library.

4. **Grid Progression**  
   - As the student explores each cell (a given subject & complexity), that region of the grid lights up or becomes marked as visited.  
   - The app includes a **"Full Grid"** button that toggles the display of unvisited cells. By default, unvisited cells are hidden. When the full grid is enabled, users can instantly jump to any previously watched video or to an adjacent (greyed out) video. This helps learners track their progress and easily navigate to nearby or unlocked topics.

## User Stories
- As a student, I want to navigate the content grid so I can find topics at my skill level.
- As a student, I want to track my progress visually on the grid so I can see what I've learned.
- As a student, I want to take AI-generated quizzes after videos to test my understanding.
- As a student, I want to view AI-generated summaries to review key points.
- As a student, I want to save videos to my library for later review.
- As a student, I want to adjust content complexity by scrolling vertically to match my learning pace.

## AI Features

1. **Interactive Quizzes**  
   - After or during video playback, AI generates context-specific quiz questions (e.g., multiple-choice, fill-in-the-blank) to enhance retention.  
   - Students can receive immediate feedback on their answers, and the system can suggest re-watching certain video segments if they miss key points.

2. **Smart Summaries**  
   - AI automatically compiles concise summaries and key takeaways from each educational video.  
   - Summaries help students quickly review what they've learned and decide whether they need to re-watch or dive deeper.

3. **Lesson Plans Creator**
   - AI generates lesson plans based on the user's progress and interests.
   - Lesson plans include a list of videos to watch, in order, and a suggested schedule for how long to spend on each video.

4. **Study Notes Summarizer**
   - AI generates summaries of the user's study notes.
   - The summaries can then be used to create a new quiz.

## Technical Stack
- **Frontend**:  
  - **Swift** and **SwiftUI** for iOS development (native).
  - 2D grid-based scroll logic implemented within SwiftUI's view hierarchy.
- **Backend Services**:
  - **Node.js** for serverless functions.
  - **Express** for API endpoints.
  - **OpenAI** for AI integrations.
  - **LangChain** for AI metrics.
  - **Firebase Authentication** for secure user login and account management.
  - **Firestore** for storing metadata: user progress, quiz questions, video references, and grid structure.
  - **Firebase Cloud Storage** for hosting video assets (and potentially images/thumbnails).
- **Optional**: Push notifications (Firebase Cloud Messaging) to remind users about new educational topics or prompt them to revisit saved content.

## Future Enhancements
- **Social Features**: Adding likes, comments, or the ability to collaborate with peers on certain videos could foster a stronger learning community.  
- **Advanced Analytics**: Track user performance/engagement with quizzes and offer personalized suggestions.  
- **Multi-Platform**: Expand to Android (Kotlin) or cross-platform (Flutter) in later phases if desired.  
- **Caption and Translation**: Add caption and translation features to make the app more accessible to a wider audience.

## Summary
This project introduces an "educational TikTok" with a 2D grid-based navigation system, where vertical and horizontal swipes change complexity level and subject matter. By blending **entertaining short videos** with **AI-driven quizzes** and **smart summaries**, the app aims to engage students in a more structured, game-like approach to learning.