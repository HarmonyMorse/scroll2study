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

const bucket = admin.storage().bucket();

async function listAllVideos() {
    try {
        // List files in the 'vids' folder
        const [files] = await bucket.getFiles({ prefix: 'vids/' });
        console.log('Found the following files:');
        files.forEach(file => {
            if (file.name.match(/\.(mp4|mov|avi|wmv)$/i)) {
                console.log(`File: ${file.name}`);
                console.log(`Storage path: gs://${bucket.name}/${file.name}`);
                console.log(`Download URL: ${file.publicUrl()}`);
                console.log('---');
            }
        });
    } catch (error) {
        console.error('Error listing files:', error);
    } finally {
        process.exit(0);
    }
}

listAllVideos(); 