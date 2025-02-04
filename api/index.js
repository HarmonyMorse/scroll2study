import express from 'express'
import cors from 'cors'
import admin from 'firebase-admin'
import dotenv from 'dotenv'
import { readFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

dotenv.config({ path: '../.env' })

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
const initializeApp = () => {
    let serviceAccount;
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } else {
        const serviceAccountPath = join(__dirname, 'config', 'scroll2study-firebase-adminsdk-fbsvc-3df97c197f.json');
        serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    }

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
};

// Simple in-memory personal counter for demonstration
// In a production setup, you'd likely store this in Firestore.
let personalCounter = 0;

// Test route
app.get('/', (req, res) => {
    res.send({ message: 'Backend is running!' });
});

// Protected route: increment counter
app.post('/incrementCounter', async (req, res) => {
    try {
        // Verify user's ID token
        const idToken = req.headers.authorization?.split('Bearer ')[1] || '';
        await admin.auth().verifyIdToken(idToken);

        // Increment the counter
        personalCounter += 1;
        res.send({ personalCounter });
    } catch (err) {
        res.status(401).send({ error: 'Unauthorized' });
    }
});

// Initialize Firebase and start server only if not in test mode
if (process.env.NODE_ENV !== 'test') {
    try {
        initializeApp();
        const PORT = process.env.PORT || 3000;
        app.listen(PORT, () =>
            console.log(`Server listening on port ${PORT}`)
        );
    } catch (error) {
        console.error('Failed to initialize Firebase:', error);
        process.exit(1);
    }
}

export default app 