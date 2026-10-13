import admin from 'firebase-admin';
import { cert } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';
import { getMessaging } from 'firebase-admin/messaging';
import dotenv from 'dotenv';
dotenv.config();
export const firebaseAdmin = admin;
export const getStorageBucket = () => getStorage().bucket();
export const getMessagingClient = () => getMessaging();
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
    const storageBucket = process.env.FIREBASE_STORAGE_BUCKET;
    if (rawServiceAccountJson) {
        try {
            const serviceAccount = JSON.parse(rawServiceAccountJson);
            firebaseAdmin.initializeApp({
                credential: cert(serviceAccount),
                storageBucket,
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
        try {
            const fs = await import('fs');
            if (fs.existsSync(credentialsPath)) {
                const serviceAccount = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
                firebaseAdmin.initializeApp({
                    credential: cert(serviceAccount),
                    storageBucket,
                });
                console.log('Firebase Admin initialized using GOOGLE_APPLICATION_CREDENTIALS explicit cert.');
                return;
            }
        }
        catch (e) {
            console.warn('Failed to explicitly load GOOGLE_APPLICATION_CREDENTIALS cert:', e);
        }
        // Fallback
        firebaseAdmin.initializeApp({
            storageBucket,
        });
        console.log('Firebase Admin initialized using GOOGLE_APPLICATION_CREDENTIALS implicit.');
        return;
    }
    console.warn('Firebase Admin was not initialized. No credentials found in FIREBASE_SERVICE_ACCOUNT or GOOGLE_APPLICATION_CREDENTIALS. Push notifications will be disabled.');
}
