import bcrypt from 'bcrypt';
import { prisma } from './db.js';
export async function ensureEnvAdminAccount() {
    const adminEmail = process.env.ADMIN_EMAIL;
    const adminPassword = process.env.ADMIN_PASSWORD;
    if (!adminEmail || !adminPassword) {
        return;
    }
    const existingAdmin = await prisma.user.findFirst({
        where: { role: 'ADMIN' },
    });
    const hashedPassword = await bcrypt.hash(adminPassword, 12);
    if (!existingAdmin) {
        await prisma.user.create({
            data: {
                name: 'System Administrator',
                email: adminEmail,
                password: hashedPassword,
                role: 'ADMIN',
                status: 'ACTIVE',
                isActive: true,
                failedLoginAttempts: 0,
                accountLockedUntil: null,
            },
        });
        console.log(`Admin account created for ${adminEmail}`);
        return;
    }
    const updates = {};
    if (existingAdmin.email !== adminEmail) {
        updates.email = adminEmail;
    }
    if (existingAdmin.status !== 'ACTIVE') {
        updates.status = 'ACTIVE';
    }
    if (!existingAdmin.isActive) {
        updates.isActive = true;
    }
    if (existingAdmin.failedLoginAttempts !== 0) {
        updates.failedLoginAttempts = 0;
    }
    if (existingAdmin.accountLockedUntil) {
        updates.accountLockedUntil = null;
    }
    if (existingAdmin.password !== hashedPassword) {
        updates.password = hashedPassword;
    }
    if (Object.keys(updates).length > 0) {
        await prisma.user.update({
            where: { id: existingAdmin.id },
            data: updates,
        });
        console.log(`Admin account synced for ${adminEmail}`);
    }
}
