import express from 'express'
import cors from 'cors'
import admin from 'firebase-admin'
import dotenv from 'dotenv'
import { readFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { getAuth } from 'firebase/auth'

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
let personalCounter = 0;

// Authentication Middleware
const authenticateUser = async (req, res, next) => {
    try {
        const idToken = req.headers.authorization?.split('Bearer ')[1];
        if (!idToken) {
            return res.status(401).json({ error: 'No token provided' });
        }
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.user = decodedToken;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
};

// Auth Routes
app.post('/auth/signup', async (req, res) => {
    try {
        const { email, password } = req.body;
        const userRecord = await admin.auth().createUser({
            email,
            password,
        });

        // Create custom token for initial sign in
        const customToken = await admin.auth().createCustomToken(userRecord.uid);

        res.json({
            token: customToken,
            user: {
                uid: userRecord.uid,
                email: userRecord.email
            }
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

app.post('/auth/signin', async (req, res) => {
    try {
        const { email, password } = req.body;

        // First verify the credentials exist
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        try {
            // Get user record to check if user exists
            const userRecord = await admin.auth().getUserByEmail(email);

            // Create a custom token
            const customToken = await admin.auth().createCustomToken(userRecord.uid);

            // Return success response
            res.json({
                token: customToken,
                user: {
                    uid: userRecord.uid,
                    email: userRecord.email,
                    isAnonymous: false
                }
            });
        } catch (error) {
            // Don't expose internal errors
            res.status(401).json({ error: 'Invalid credentials' });
        }
    } catch (error) {
        console.error('Sign in error:', error);
        res.status(500).json({ error: 'Authentication failed' });
    }
});

app.post('/auth/anonymous', async (req, res) => {
    try {
        const anonUser = await admin.auth().createUser({});
        const customToken = await admin.auth().createCustomToken(anonUser.uid);

        res.json({
            token: customToken,
            user: {
                uid: anonUser.uid,
                isAnonymous: true
            }
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

app.post('/auth/verify', authenticateUser, (req, res) => {
    res.json({ user: req.user });
});

// Protected Routes
app.post('/incrementCounter', authenticateUser, async (req, res) => {
    try {
        const userId = req.user.uid;

        // Get user's document from Firestore
        const userRef = admin.firestore().collection('users').doc(userId);

        // Use transaction for atomic counter increment
        const result = await admin.firestore().runTransaction(async (transaction) => {
            const doc = await transaction.get(userRef);
            const currentCounter = doc.exists ? (doc.data()?.counter ?? 0) : 0;
            const newCounter = currentCounter + 1;

            transaction.set(userRef, {
                counter: newCounter,
                userId: userId,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            return newCounter;
        });

        res.json({ personalCounter: result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Test route
app.get('/', (req, res) => {
    res.send({ message: 'Backend is running!' });
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