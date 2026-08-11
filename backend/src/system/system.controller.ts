import { Request, Response } from 'express';

export const getSystemVersion = (req: Request, res: Response) => {
  try {
    // In a real application, these values might be stored in the database or environment variables.
    // For now, we are hardcoding them to always prompt an update to 2.0.0.
    res.json({
      latestVersion: '2.0.0',
      requiredVersion: '2.0.0',
      updateUrl: 'https://example.com/update-placeholder'
    });
  } catch (error) {
    console.error('Get system version error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};
