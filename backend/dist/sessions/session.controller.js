import { SessionService } from './session.service.js';
const sessionService = new SessionService();
export class SessionController {
    async checkIn(req, res) {
        try {
            // In a real app, studentId comes from the authenticated user token
            // e.g. req.user.id
            const { studentId, latitude, longitude, accuracy, batteryLevelStart, networkType, deviceModel } = req.body;
            if (!studentId || latitude === undefined || longitude === undefined || accuracy === undefined) {
                return res.status(400).json({ error: 'Missing required fields: studentId, latitude, longitude, accuracy' });
            }
            const session = await sessionService.checkIn({
                studentId,
                latitude,
                longitude,
                accuracy,
                batteryLevelStart,
                networkType,
                deviceModel
            });
            res.status(201).json(session);
        }
        catch (error) {
            if (error.message.includes('already exists')) {
                return res.status(409).json({ error: error.message });
            }
            console.error('[checkIn]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async checkOut(req, res) {
        try {
            const { studentId, latitude, longitude, accuracy, batteryLevelEnd } = req.body;
            if (!studentId || latitude === undefined || longitude === undefined || accuracy === undefined) {
                return res.status(400).json({ error: 'Missing required fields: studentId, latitude, longitude, accuracy' });
            }
            const session = await sessionService.checkOut({
                studentId,
                latitude,
                longitude,
                accuracy,
                batteryLevelEnd
            });
            res.status(200).json(session);
        }
        catch (error) {
            if (error.message.includes('No active session')) {
                return res.status(404).json({ error: error.message });
            }
            console.error('[checkOut]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async getActive(req, res) {
        try {
            // e.g. req.user.id
            const studentId = req.query.studentId;
            if (!studentId) {
                return res.status(400).json({ error: 'Missing studentId' });
            }
            const session = await sessionService.getActiveSession(studentId);
            res.status(200).json({ session: session || null });
        }
        catch (error) {
            console.error('[getActive]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async logPing(req, res) {
        try {
            const { sessionId, latitude, longitude, accuracy, altitude, speed, heading } = req.body;
            if (!sessionId || latitude === undefined || longitude === undefined || accuracy === undefined) {
                return res.status(400).json({ error: 'Missing required fields' });
            }
            const ping = await sessionService.logLocationPing({
                sessionId,
                latitude,
                longitude,
                accuracy,
                altitude,
                speed,
                heading
            });
            res.status(201).json(ping);
        }
        catch (error) {
            console.error('[logPing]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async getStudentPings(req, res) {
        try {
            const { studentId } = req.params;
            if (!studentId) {
                return res.status(400).json({ error: 'Missing studentId' });
            }
            const pings = await sessionService.getStudentPings(studentId);
            res.status(200).json(pings);
        }
        catch (error) {
            console.error('[getStudentPings]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
}
