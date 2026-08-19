import { Request, Response } from 'express';
import { ActivityService } from './activity.service.js';

const activityService = new ActivityService();

export class ActivityController {
  
  async create(req: Request, res: Response) {
    try {
      const { title, description, latitude, longitude, gpsAccuracy, methodology, objectives, findings, remarks } = req.body;
      
      const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId;

      if (!studentId || typeof title !== 'string' || title.trim() === '') {
        return res.status(400).json({ error: 'Missing required fields: studentId, title' });
      }

      const activity = await activityService.createDraft({
        studentId, title: title.trim(), description, latitude, longitude, gpsAccuracy, methodology, objectives, findings, remarks
      });

      res.status(201).json(activity);
    } catch (error) {
      console.error('[createDraft]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async update(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const { title, description, methodology, objectives, findings, remarks } = req.body;
      const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId as string;

      if (!studentId) {
        return res.status(400).json({ error: 'Missing studentId' });
      }

      const activity = await activityService.updateActivity(id, studentId, {
        title, description, methodology, objectives, findings, remarks
      });

      res.status(200).json(activity);
    } catch (error: any) {
      if (error.message.includes('not found') || error.message.includes('Cannot edit')) {
        return res.status(403).json({ error: error.message });
      }
      console.error('[updateActivity]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async submit(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId as string;

      if (!studentId) {
        return res.status(400).json({ error: 'Missing studentId' });
      }

      const activity = await activityService.submitActivity(id, studentId);
      res.status(200).json(activity);
    } catch (error: any) {
      if (error.message.includes('not found') || error.message.includes('Cannot submit')) {
        return res.status(403).json({ error: error.message });
      }
      console.error('[submitActivity]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async getForStudent(req: Request, res: Response) {
    try {
      const studentId = req.query.studentId as string;
      if (!studentId) {
        return res.status(400).json({ error: 'Missing studentId' });
      }

      const limit = parseInt(req.query.limit as string, 10) || 50;
      const page = parseInt(req.query.page as string, 10) || 1;
      const offset = (page - 1) * limit;
      const status = req.query.status as string | undefined;
      const search = req.query.search as string | undefined;

      const activities = await activityService.getStudentActivities(studentId, limit, offset, status, search);
      res.status(200).json(activities);
    } catch (error) {
      console.error('[getForStudent]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async getForSupervisor(req: Request, res: Response) {
    try {
      const supervisorId = req.query.supervisorId as string;
      if (!supervisorId) {
        return res.status(400).json({ error: 'Missing supervisorId' });
      }

      const limit = parseInt(req.query.limit as string, 10) || 50;
      const offset = parseInt(req.query.offset as string, 10) || 0;
      const activities = await activityService.getSupervisorActivities(supervisorId, limit, offset);
      res.status(200).json(activities);
    } catch (error) {
      console.error('[getForSupervisor]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async getById(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const activity = await activityService.getActivity(id);
      
      if (!activity) {
        return res.status(404).json({ error: 'Activity not found' });
      }

      res.status(200).json(activity);
    } catch (error) {
      console.error('[getById]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async delete(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const studentId = req.user?.role === 'STUDENT' ? req.user.userId : req.body.studentId as string;

      if (!studentId) {
        return res.status(400).json({ error: 'Missing studentId' });
      }

      await activityService.deleteActivity(id, studentId);
      res.status(200).json({ message: 'Activity deleted successfully' });
    } catch (error: any) {
      if (error.message.includes('not found') || error.message.includes('Unauthorized')) {
        return res.status(403).json({ error: error.message });
      }
      console.error('[deleteActivity]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
}
