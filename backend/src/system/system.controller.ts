import { Request, Response } from 'express';

export const getSystemVersion = (req: Request, res: Response) => {
  try {
    const latestVersion = process.env.APP_LATEST_VERSION || '1.0.0';
    const requiredVersion = process.env.APP_REQUIRED_VERSION || '1.0.0';
    const updateUrl = process.env.APP_UPDATE_URL || 'https://fieldtrack.top/update';

    res.json({
      latestVersion,
      requiredVersion,
      updateUrl
    });
  } catch (error) {
    console.error('Get system version error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};
