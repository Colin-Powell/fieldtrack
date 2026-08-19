import { initFirebaseAdmin } from './firebase_admin.js';

await initFirebaseAdmin();
await import('./worker.js');
await import('./index.js');
