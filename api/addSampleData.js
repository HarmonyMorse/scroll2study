import admin from 'firebase-admin';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const serviceAccount = require('./config/scroll2study-firebase-adminsdk-fbsvc-3df97c197f.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
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
    }
];

const videos = [
    {
        id: 'math_l1_1',
        title: 'Introduction to Algebra',
        description: 'Basic algebraic concepts',
        subject: 'math',
        complexityLevel: 1,
        metadata: {
            duration: 300,
            views: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        },
        position: { x: 0, y: 0 },
        isActive: true
    },
    {
        id: 'physics_l1_1',
        title: 'Forces and Motion',
        description: 'Newton\'s laws of motion',
        subject: 'physics',
        complexityLevel: 1,
        metadata: {
            duration: 360,
            views: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        },
        position: { x: 1, y: 0 },
        isActive: true
    }
];

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