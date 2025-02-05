# Scroll2Study

A 2D scrolling educational video platform that allows users to navigate through subjects horizontally and complexity levels vertically.

## Project Structure

- `/api` - Backend services and scripts
- `/scroll2study` - iOS app
- `/docs` - Project documentation

## Setup

### Prerequisites

- Node.js 18+ for backend
- Xcode 15+ for iOS development
- Firebase project with Firestore enabled

### Backend Setup

1. Install dependencies:
```bash
cd api
npm install
```

2. Set up Firebase credentials:
- Place your Firebase Admin SDK service account key in `api/config/scroll2study-firebase-adminsdk-fbsvc-3df97c197f.json`

3. Seed the database:
```bash
node addSampleData.js
```

This will create:
- Subject entries (Math, Physics)
- Complexity levels (Beginner, Intermediate)
- Sample video documents with metadata

### iOS App Setup

1. Open `scroll2study/scroll2study.xcodeproj` in Xcode
2. Build and run the project

## Development

### Adding New Videos

To add new videos to the platform:

1. Add video metadata to `api/addSampleData.js` following the existing format:
```javascript
{
    id: 'subject_level_name',
    title: 'Video Title',
    description: 'Video Description',
    subject: 'subjectId',
    complexityLevel: levelNumber,
    metadata: {
        duration: seconds,
        views: 0,
        thumbnailUrl: 'url',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    },
    position: { x: number, y: number },
    isActive: true
}
```

2. Run the seeding script:
```bash
cd api
node addSampleData.js
```

### Environment Variables

Required environment variables:
- `FIREBASE_PROJECT_ID`: Your Firebase project ID
- `GOOGLE_APPLICATION_CREDENTIALS`: Path to your service account key

## Architecture

- Backend: Node.js with Firebase Admin SDK
- Frontend: SwiftUI with MVVM architecture
- Database: Cloud Firestore

### Collections

- `subjects`: Subject categories
- `complexity_levels`: Difficulty levels
- `videos`: Video metadata
- `user_progress`: User progress tracking (authenticated users only)

## Security

- Public read access for educational content (subjects, complexity levels, videos)
- Write operations restricted to admin via backend
- User data and progress require authentication
