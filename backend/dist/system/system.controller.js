import { prisma } from '../db.js';
export const getSystemVersion = async (req, res) => {
    try {
        let setting = await prisma.systemSetting.findUnique({ where: { key: 'APP_VERSION_CONFIG' } });
        if (!setting) {
            const defaultData = {
                latestVersion: process.env.APP_LATEST_VERSION || '1.0.0',
                requiredVersion: process.env.APP_REQUIRED_VERSION || '1.0.0',
                updateUrl: process.env.APP_UPDATE_URL || 'https://fieldtrack.top/update',
            };
            try {
                setting = await prisma.systemSetting.create({
                    data: {
                        key: 'APP_VERSION_CONFIG',
                        value: defaultData
                    }
                });
            }
            catch (e) {
                return res.json(defaultData);
            }
        }
        res.json(setting.value);
    }
    catch (error) {
        console.error('Get system version error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};
export const updateSystemVersion = async (req, res) => {
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
    }
    catch (error) {
        console.error('Update system version error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};
