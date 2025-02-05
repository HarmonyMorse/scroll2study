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

async function deleteCollection(collectionPath) {
    const collectionRef = db.collection(collectionPath);
    const query = collectionRef.orderBy('__name__');

    return new Promise((resolve, reject) => {
        deleteQueryBatch(db, query, resolve).catch(reject);
    });
}

async function deleteQueryBatch(db, query, resolve) {
    const snapshot = await query.get();

    const batchSize = snapshot.size;
    if (batchSize === 0) {
        // When there are no documents left, we are done
        resolve();
        return;
    }

    // Delete documents in a batch
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
    });
    await batch.commit();

    // Recurse on the next process tick, to avoid exploding the stack
    process.nextTick(() => {
        deleteQueryBatch(db, query, resolve);
    });
}

async function clearAllData() {
    try {
        console.log('Clearing all data...');

        // Delete all collections
        await deleteCollection('subjects');
        console.log('Cleared subjects collection');

        await deleteCollection('complexity_levels');
        console.log('Cleared complexity_levels collection');

        await deleteCollection('videos');
        console.log('Cleared videos collection');

        console.log('All data cleared successfully');
    } catch (error) {
        console.error('Error clearing data:', error);
    } finally {
        process.exit(0);
    }
}

// Run the function
clearAllData(); 