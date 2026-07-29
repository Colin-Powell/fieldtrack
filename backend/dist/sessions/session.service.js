import { prisma } from '../db.js';
export class SessionService {
    /**
     * Check in a student, creating a new active FieldSession.
     */
    async checkIn(data) {
        // Check if an active session already exists
        const existingActive = await prisma.fieldSession.findFirst({
            where: {
                studentId: data.studentId,
                status: 'ACTIVE'
            }
        });
        if (existingActive) {
            throw new Error('An active session already exists. Please checkout first.');
        }
        const session = await prisma.fieldSession.create({
            data: {
                studentId: data.studentId,
                startLatitude: data.latitude,
                startLongitude: data.longitude,
                startAccuracy: data.accuracy,
                batteryLevelStart: data.batteryLevelStart,
                networkType: data.networkType,
                deviceModel: data.deviceModel,
                status: 'ACTIVE',
            }
        });
        // Update student status to IN_FIELD
        await prisma.studentProfile.update({
            where: { userId: data.studentId },
            data: { status: 'IN_FIELD' }
        });
        return session;
    }
    /**
     * Check out a student, completing their active FieldSession.
     */
    async checkOut(data) {
        const session = await prisma.fieldSession.findFirst({
            where: {
                studentId: data.studentId,
                status: 'ACTIVE'
            }
        });
        if (!session) {
            throw new Error('No active session found to checkout.');
        }
        const checkOutTime = new Date();
        const durationSeconds = Math.floor((checkOutTime.getTime() - session.checkInTime.getTime()) / 1000);
        // Get all location pings to calculate distance (basic approximation)
        const pings = await prisma.locationPing.findMany({
            where: { sessionId: session.id },
            orderBy: { timestamp: 'asc' }
        });
        let distanceTravelled = 0;
        // Calculate simple distance if we have enough pings (Haversine omitted for brevity, you'd add it here if needed)
        // For now, average accuracy calculation:
        const accuracies = pings.map(p => p.accuracy);
        if (session.startAccuracy)
            accuracies.push(session.startAccuracy);
        if (data.accuracy)
            accuracies.push(data.accuracy);
        const averageAccuracy = accuracies.length > 0 ? (accuracies.reduce((a, b) => a + b, 0) / accuracies.length) : null;
        const updatedSession = await prisma.fieldSession.update({
            where: { id: session.id },
            data: {
                checkOutTime,
                durationSeconds,
                endLatitude: data.latitude,
                endLongitude: data.longitude,
                endAccuracy: data.accuracy,
                batteryLevelEnd: data.batteryLevelEnd,
                status: 'COMPLETED',
                distanceTravelled,
                averageAccuracy,
            }
        });
        // Update student status back to IDLE
        await prisma.studentProfile.update({
            where: { userId: data.studentId },
            data: { status: 'IDLE' }
        });
        return updatedSession;
    }
    /**
     * Get the active session for a student.
     */
    async getActiveSession(studentId) {
        return prisma.fieldSession.findFirst({
            where: {
                studentId: studentId,
                status: 'ACTIVE'
            }
        });
    }
    /**
     * Log a location ping for an active session.
     */
    async logLocationPing(data) {
        return prisma.locationPing.create({
            data: {
                sessionId: data.sessionId,
                latitude: data.latitude,
                longitude: data.longitude,
                accuracy: data.accuracy,
                altitude: data.altitude,
                speed: data.speed,
                heading: data.heading,
            }
        });
    }
}
