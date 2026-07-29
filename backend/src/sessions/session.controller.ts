import { Request, Response } from 'express';
import { SessionService } from './session.service.js';

const sessionService = new SessionService();

export class SessionController {
  
  async checkIn(req: Request, res: Response) {
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
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        return res.status(409).json({ error: error.message });
      }
      console.error('[checkIn]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async checkOut(req: Request, res: Response) {
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
    } catch (error: any) {
      if (error.message.includes('No active session')) {
        return res.status(404).json({ error: error.message });
      }
      console.error('[checkOut]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async getActive(req: Request, res: Response) {
    try {
      // e.g. req.user.id
      const studentId = req.query.studentId as string;
      if (!studentId) {
        return res.status(400).json({ error: 'Missing studentId' });
      }

      const session = await sessionService.getActiveSession(studentId);
      res.status(200).json({ session: session || null });
    } catch (error) {
      console.error('[getActive]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async logPing(req: Request, res: Response) {
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
    } catch (error) {
      console.error('[logPing]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
}
