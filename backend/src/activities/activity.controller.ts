import { Request, Response } from 'express';
import { ActivityService } from './activity.service.js';

const activityService = new ActivityService();

export class ActivityController {
  
  async create(req: Request, res: Response) {
    try {
      const { studentId, title, description, latitude, longitude, gpsAccuracy, methodology, objectives, findings, remarks } = req.body;
      
      if (!studentId || !title) {
        return res.status(400).json({ error: 'Missing required fields: studentId, title' });
      }

      const activity = await activityService.createDraft({
        studentId, title, description, latitude, longitude, gpsAccuracy, methodology, objectives, findings, remarks
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
      const studentId = req.body.studentId as string;

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
      const studentId = req.body.studentId as string;

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

      const activities = await activityService.getStudentActivities(studentId);
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

      const activities = await activityService.getSupervisorActivities(supervisorId);
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
}
