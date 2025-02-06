import admin from 'firebase-admin';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const serviceAccount = require('./config/scroll2study-firebase-adminsdk-fbsvc-3df97c197f.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: 'scroll2study.firebasestorage.app'
    });
}

const db = admin.firestore();

// Get download URL for the video
const bucket = admin.storage().bucket();
const videoFile = bucket.file('vids/rice.mov');
const [videoUrl] = await videoFile.getSignedUrl({
    action: 'read',
    expires: '03-01-2500', // Long expiration for demo
});

// Temporary video placeholder - to be replaced with actual video later
const temporaryVideoPath = videoUrl;
const temporaryThumbnailPath = "https://storage.googleapis.com/scroll2study.firebasestorage.app/pics%2FScreenshot%202025-02-06%20at%2011.42.20.png";

// Sample data
const subjects = [
    { id: 'math', name: 'Mathematics', description: 'Core mathematical concepts', maxLevels: 15 },
    { id: 'physics', name: 'Physics', description: 'Fundamental physics principles', maxLevels: 12 },
    { id: 'chemistry', name: 'Chemistry', description: 'Chemical principles and reactions', maxLevels: 10 },
    { id: 'biology', name: 'Biology', description: 'Life sciences and organisms', maxLevels: 8 },
    { id: 'cs', name: 'Computer Science', description: 'Programming and computational thinking', maxLevels: 14 },
    { id: 'history', name: 'History', description: 'Study of past events', maxLevels: 6 },
    { id: 'geography', name: 'Geography', description: 'Study of places and environments', maxLevels: 4 },
    { id: 'literature', name: 'Literature', description: 'Study of written works', maxLevels: 7 },
    { id: 'art', name: 'Art', description: 'Visual and creative expression', maxLevels: 5 },
    { id: 'music', name: 'Music', description: 'Study of sound and composition', maxLevels: 9 },
    { id: 'psychology', name: 'Psychology', description: 'Study of mind and behavior', maxLevels: 11 },
    { id: 'economics', name: 'Economics', description: 'Study of resource allocation', maxLevels: 13 },
    { id: 'philosophy', name: 'Philosophy', description: 'Study of fundamental questions', maxLevels: 3 },
    { id: 'linguistics', name: 'Linguistics', description: 'Study of language', maxLevels: 8 },
    { id: 'astronomy', name: 'Astronomy', description: 'Study of celestial objects', maxLevels: 6 }
].map((subject, index) => ({
    ...subject,
    order: index + 1,
    isActive: true
}));

// Function to generate complexity levels
function generateLevels(maxLevel) {
    const levels = [];
    for (let i = 1; i <= maxLevel; i++) {
        levels.push({
            id: `level${i}`,
            level: i,
            name: `Level ${i}`,
            description: `Level ${i} concepts and applications`,
            requirements: i === 1 ? 'None' : `Level ${i - 1} completion`,
            order: i,
            isActive: true
        });
    }
    return levels;
}

// Find the maximum number of levels across all subjects
const maxLevels = Math.max(...subjects.map(subject => subject.maxLevels));

// Generate global complexity levels
const complexityLevels = generateLevels(maxLevels);

const videos = [];
const gridCells = [];

// Create grid cells and videos for each subject at their respective levels
subjects.forEach((subject, subjectIndex) => {
    // Create grid cells only up to this subject's max level
    const subjectLevels = complexityLevels.slice(0, subject.maxLevels);
    subjectLevels.forEach((level, levelIndex) => {
        // Create grid cell
        gridCells.push({
            id: `${subject.id}_${level.id}`,
            subject: subject.id,
            complexityLevel: level.level,
            position: { x: subjectIndex, y: levelIndex },
            hasVideo: true,  // Since we're only creating cells up to max level
            isActive: true
        });

        // Create video (since we're only creating cells up to max level, all cells have videos)
        videos.push({
            id: `${subject.id}_l${level.level}`,
            title: `${subject.name} - ${level.name}`,
            description: `${level.name} ${subject.name} concepts`,
            subject: subject.id,
            complexityLevel: level.level,
            metadata: {
                duration: 300, // placeholder duration
                views: 0,
                videoUrl: temporaryVideoPath,
                storagePath: temporaryVideoPath,
                thumbnailUrl: temporaryThumbnailPath,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            },
            position: { x: subjectIndex, y: levelIndex },
            isActive: true
        });
    });
});

// Add data to Firestore
async function addSampleData() {
    try {
        // Add subjects
        for (const subject of subjects) {
            const { maxLevels, ...subjectData } = subject;  // Remove maxLevels before saving
            await db.collection('subjects').doc(subject.id).set({
                ...subjectData,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        console.log('Added subjects');

        // Add global complexity levels
        for (const level of complexityLevels) {
            await db.collection('complexity_levels').doc(level.id).set(level);
        }
        console.log('Added complexity levels');

        // Add grid cells
        for (const cell of gridCells) {
            await db.collection('grid_cells').doc(cell.id).set(cell);
            console.log(`Added grid cell: ${cell.id}`);
        }
        console.log('Added grid cells');

        // Add videos
        for (const video of videos) {
            await db.collection('videos').doc(video.id).set(video);
            console.log(`Added video: ${video.id}`);
        }
        console.log('Added videos');

        console.log('Sample data added successfully');
    } catch (error) {
        console.error('Error adding sample data:', error);
    } finally {
        process.exit(0);
    }
}

// Run the function
addSampleData(); 