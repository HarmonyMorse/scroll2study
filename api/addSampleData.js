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

// Sample data
const subjects = [
    {
        id: 'math',
        name: 'Mathematics',
        description: 'Core mathematical concepts',
        order: 1,
        isActive: true
    },
    {
        id: 'physics',
        name: 'Physics',
        description: 'Fundamental physics principles',
        order: 2,
        isActive: true
    },
    {
        id: 'chemistry',
        name: 'Chemistry',
        description: 'Chemical principles and reactions',
        order: 3,
        isActive: true
    },
    {
        id: 'biology',
        name: 'Biology',
        description: 'Life sciences and organisms',
        order: 4,
        isActive: true
    },
    {
        id: 'cs',
        name: 'Computer Science',
        description: 'Programming and computational thinking',
        order: 5,
        isActive: true
    }
];

const complexityLevels = [
    {
        id: 'level1',
        level: 1,
        name: 'Beginner',
        description: 'Foundational concepts',
        requirements: 'None',
        order: 1
    },
    {
        id: 'level2',
        level: 2,
        name: 'Intermediate',
        description: 'Building on basics',
        requirements: 'Level 1 completion',
        order: 2
    },
    {
        id: 'level3',
        level: 3,
        name: 'Advanced',
        description: 'Complex topics and applications',
        requirements: 'Level 2 completion',
        order: 3
    }
];

// Available video files from storage
const availableVideos = [
    'vids/RPReplay_Final1619234227.mov',
    'vids/RPReplay_Final1621912841.mov',
    'vids/RPReplay_Final1621912895.mov',
    'vids/RPReplay_Final1623207673.mov',
    'vids/RPReplay_Final1623207810.mov',
    'vids/RPReplay_Final1623207894.mov',
    'vids/RPReplay_Final1623207917.mov',
    'vids/RPReplay_Final1623207960.mov',
    'vids/RPReplay_Final1623207982.mov',
    'vids/RPReplay_Final1623208751.mov',
    'vids/RPReplay_Final1623475654.mov',
    'vids/RPReplay_Final1630290820.mov',
    'vids/RPReplay_Final1633115354.MP4',
    'vids/RPReplay_Final1619234227 2.mov',
    'vids/RPReplay_Final1619234227 3.mov'
];

// Function to get a random video and remove it from the array
function getRandomVideo() {
    const index = Math.floor(Math.random() * availableVideos.length);
    return availableVideos.splice(index, 1)[0];
}

const videos = [];
let position = { x: 0, y: 0 };

// Create one video for each subject at each complexity level
subjects.forEach((subject, subjectIndex) => {
    complexityLevels.forEach((level, levelIndex) => {
        const videoPath = getRandomVideo();
        videos.push({
            id: `${subject.id}_l${level.level}`,
            title: `${subject.name} - ${level.name}`,
            description: `${level.name} level ${subject.name} concepts`,
            subject: subject.id,
            complexityLevel: level.level,
            metadata: {
                duration: 300, // placeholder duration
                views: 0,
                videoUrl: `gs://scroll2study.firebasestorage.app/${videoPath}`,
                storagePath: videoPath,
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
            await db.collection('subjects').doc(subject.id).set({
                ...subject,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        console.log('Added subjects');

        // Add complexity levels
        for (const level of complexityLevels) {
            await db.collection('complexity_levels').doc(level.id).set({
                ...level,
                isActive: true
            });
        }
        console.log('Added complexity levels');

        // Add videos
        for (const video of videos) {
            await db.collection('videos').doc(video.id).set(video);
            console.log(`Added video: ${video.id} with storage path: ${video.metadata.storagePath}`);
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