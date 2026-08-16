import { ActivityService } from './activity.service.js';
const activityService = new ActivityService();
export class ActivityController {
    async create(req, res) {
        try {
            const { title, description, latitude, longitude, gpsAccuracy, methodology, objectives, findings, remarks } = req.body;
            const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId;
            if (!studentId || !title) {
                return res.status(400).json({ error: 'Missing required fields: studentId, title' });
            }
            const activity = await activityService.createDraft({
                studentId, title, description, latitude, longitude, gpsAccuracy, methodology, objectives, findings, remarks
            });
            res.status(201).json(activity);
        }
        catch (error) {
            console.error('[createDraft]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async update(req, res) {
        try {
            const id = req.params.id;
            const { title, description, methodology, objectives, findings, remarks } = req.body;
            const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId;
            if (!studentId) {
                return res.status(400).json({ error: 'Missing studentId' });
            }
            const activity = await activityService.updateActivity(id, studentId, {
                title, description, methodology, objectives, findings, remarks
            });
            res.status(200).json(activity);
        }
        catch (error) {
            if (error.message.includes('not found') || error.message.includes('Cannot edit')) {
                return res.status(403).json({ error: error.message });
            }
            console.error('[updateActivity]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async submit(req, res) {
        try {
            const id = req.params.id;
            const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId;
            if (!studentId) {
                return res.status(400).json({ error: 'Missing studentId' });
            }
            const activity = await activityService.submitActivity(id, studentId);
            res.status(200).json(activity);
        }
        catch (error) {
            if (error.message.includes('not found') || error.message.includes('Cannot submit')) {
                return res.status(403).json({ error: error.message });
            }
            console.error('[submitActivity]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async getForStudent(req, res) {
        try {
            const studentId = req.query.studentId;
            if (!studentId) {
                return res.status(400).json({ error: 'Missing studentId' });
            }
            const limit = parseInt(req.query.limit, 10) || 50;
            const offset = parseInt(req.query.offset, 10) || 0;
            const activities = await activityService.getStudentActivities(studentId, limit, offset);
            res.status(200).json(activities);
        }
        catch (error) {
            console.error('[getForStudent]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async getForSupervisor(req, res) {
        try {
            const supervisorId = req.query.supervisorId;
            if (!supervisorId) {
                return res.status(400).json({ error: 'Missing supervisorId' });
            }
            const limit = parseInt(req.query.limit, 10) || 50;
            const offset = parseInt(req.query.offset, 10) || 0;
            const activities = await activityService.getSupervisorActivities(supervisorId, limit, offset);
            res.status(200).json(activities);
        }
        catch (error) {
            console.error('[getForSupervisor]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async getById(req, res) {
        try {
            const id = req.params.id;
            const activity = await activityService.getActivity(id);
            if (!activity) {
                return res.status(404).json({ error: 'Activity not found' });
            }
            res.status(200).json(activity);
        }
        catch (error) {
            console.error('[getById]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async delete(req, res) {
        try {
            const id = req.params.id;
            const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId;
            if (!studentId) {
                return res.status(400).json({ error: 'Missing studentId' });
            }
            await activityService.deleteActivity(id, studentId);
            res.status(200).json({ message: 'Activity deleted successfully' });
        }
        catch (error) {
            if (error.message.includes('not found') || error.message.includes('Unauthorized')) {
                return res.status(403).json({ error: error.message });
            }
            console.error('[deleteActivity]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
}
