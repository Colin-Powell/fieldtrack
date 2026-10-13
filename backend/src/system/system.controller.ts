import { Request, Response } from 'express';
import { prisma } from '../db.js';

export const getSystemVersion = async (req: Request, res: Response) => {
  try {
    const envData = {
      latestVersion: process.env.APP_LATEST_VERSION || '1.0.1',
      requiredVersion: process.env.APP_REQUIRED_VERSION || '1.0.1',
      updateUrl: process.env.APP_UPDATE_URL || 'https://fieldtrack.top/update.html',
    };

    let setting = await prisma.systemSetting.findUnique({ where: { key: 'APP_VERSION_CONFIG' } });

    if (!setting) {
      try {
        setting = await prisma.systemSetting.create({
          data: {
            key: 'APP_VERSION_CONFIG',
            value: envData
          }
        });
      } catch (e) {
        return res.json(envData);
      }
      return res.json(setting.value);
    }

    const dbValue = setting.value as { latestVersion?: string; requiredVersion?: string; updateUrl?: string } | null;
    const responseData = {
      latestVersion: envData.latestVersion || dbValue?.latestVersion || '1.0.1',
      requiredVersion: envData.requiredVersion || dbValue?.requiredVersion || '1.0.1',
      updateUrl: envData.updateUrl || dbValue?.updateUrl || 'https://fieldtrack.top/update.html',
    };

    res.json(responseData);
  } catch (error) {
    console.error('Get system version error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

export const updateSystemVersion = async (req: Request, res: Response) => {
  try {
    const { latestVersion, requiredVersion, updateUrl } = req.body;

    if (!latestVersion || !requiredVersion || !updateUrl) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const payload = { latestVersion, requiredVersion, updateUrl };
    const userId = req.user?.userId;

    const setting = await prisma.systemSetting.upsert({
      where: { key: 'APP_VERSION_CONFIG' },
      update: { value: payload, updatedBy: userId },
      create: { key: 'APP_VERSION_CONFIG', value: payload, updatedBy: userId }
    });

    res.json({ message: 'System version updated', data: setting.value });
  } catch (error) {
    console.error('Update system version error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};
