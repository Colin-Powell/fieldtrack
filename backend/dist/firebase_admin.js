import admin from 'firebase-admin';
export const firebaseAdmin = admin;
function normalizeServiceAccountJson(value) {
    if (!value)
        return undefined;
    const trimmed = value.trim();
    if (!trimmed)
        return undefined;
    if (trimmed.startsWith('{')) {
        return trimmed;
    }
    return trimmed.replace(/\\n/g, '\n');
}
export async function initFirebaseAdmin() {
    const existingApps = Array.isArray(firebaseAdmin.apps) ? firebaseAdmin.apps : [];
    if (existingApps.length > 0) {
        return;
    }
    const rawServiceAccountJson = normalizeServiceAccountJson(process.env.FIREBASE_SERVICE_ACCOUNT || process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (rawServiceAccountJson) {
        try {
            const serviceAccount = JSON.parse(rawServiceAccountJson);
            firebaseAdmin.initializeApp({
                credential: firebaseAdmin.credential.cert(serviceAccount),
            });
            console.log('Firebase Admin initialized using service account JSON from env.');
            return;
        }
        catch (error) {
            console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', error);
            throw error;
        }
    }
    if (credentialsPath) {
        firebaseAdmin.initializeApp();
        console.log('Firebase Admin initialized using GOOGLE_APPLICATION_CREDENTIALS.');
        return;
    }
    console.warn('Firebase Admin was not initialized. No credentials found in FIREBASE_SERVICE_ACCOUNT or GOOGLE_APPLICATION_CREDENTIALS. Push notifications will be disabled.');
}
