import { Request, Response } from 'express';
import { prisma } from '../db.js';
import { emailService } from '../auth/email.service.js';
import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 10;

function generateRandomPassword(length = 10) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < length; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

export const importUsersCsv = async (req: Request, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No CSV file uploaded' });
    }

    const fileContent = req.file.buffer.toString('utf-8');
    const records = parse(fileContent, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });

    if (records.length === 0) {
      return res.status(400).json({ error: 'CSV file is empty' });
    }

    const importedUsers = [];
    const errors = [];

    for (let i = 0; i < records.length; i++) {
      const row: any = records[i];
      const rowNum = i + 2; // +1 for 0-index, +1 for header

      const { name, email, role, phone, password, registrationNo, staffNumber, department } = row;

      if (!name || !email || !role) {
        errors.push(`Row ${rowNum}: Missing required fields (name, email, role).`);
        continue;
      }

      const upperRole = role.toUpperCase();
      if (!['STUDENT', 'SUPERVISOR'].includes(upperRole)) {
        errors.push(`Row ${rowNum}: Invalid role "${role}". Only STUDENT and SUPERVISOR are allowed via CSV import.`);
        continue;
      }

      if (upperRole === 'STUDENT' && !registrationNo) {
        errors.push(`Row ${rowNum}: Registration number is required for STUDENTS.`);
        continue;
      }

      if (upperRole === 'SUPERVISOR' && !staffNumber) {
        errors.push(`Row ${rowNum}: Staff number is required for SUPERVISORS.`);
        continue;
      }

      const existingUser = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
      if (existingUser) {
        errors.push(`Row ${rowNum}: Email ${email} is already in use.`);
        continue;
      }

      let plainPassword = password;
      let isGenerated = false;

      if (!plainPassword) {
        plainPassword = generateRandomPassword();
        isGenerated = true;
      }

      const hashedPassword = await bcrypt.hash(plainPassword, SALT_ROUNDS);

      try {
        const newUser = await prisma.$transaction(async (tx) => {
          const user = await tx.user.create({
            data: {
              name,
              email: email.toLowerCase(),
              role: upperRole as 'STUDENT' | 'SUPERVISOR',
              password: hashedPassword,
              preferences: { create: {} },
            },
          });

          if (upperRole === 'STUDENT') {
            await tx.studentProfile.create({
              data: {
                userId: user.id,
                registrationNo,
                department: department || null,
                phone: phone || null,
              },
            });
          } else if (upperRole === 'SUPERVISOR') {
            await tx.supervisorProfile.create({
              data: {
                userId: user.id,
                staffNumber,
                department: department || null,
                phone: phone || null,
              },
            });
          }

          return user;
        });

        // Send welcome email with password
        try {
          const emailHtml = `
            <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
              <h2 style="color: #1BA654;">Welcome to FieldTrack!</h2>
              <p>Hello ${name},</p>
              <p>An account has been created for you on FieldTrack with the role of <strong>${upperRole}</strong>.</p>
              <p>Your login credentials are:</p>
              <div style="background-color: #f3f4f6; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0 0 10px 0;"><strong>Email:</strong> ${email}</p>
                <p style="margin: 0;"><strong>Password:</strong> <span style="font-family: monospace; font-size: 16px;">${plainPassword}</span></p>
              </div>
              ${isGenerated ? '<p><em>Note: This password was auto-generated securely. We recommend changing it after you log in.</em></p>' : ''}
              <p>Best regards,<br>The FieldTrack Team</p>
            </div>
          `;
          await emailService.sendEmail(
            email.toLowerCase(),
            'Welcome to FieldTrack - Your Account Details',
            emailHtml
          );
        } catch (emailError) {
          console.error(`Failed to send email to ${email}:`, emailError);
        }

        importedUsers.push({ email, role: upperRole });
      } catch (dbError: any) {
        if (dbError.code === 'P2002') {
           errors.push(`Row ${rowNum}: A user with this registration/staff number already exists.`);
        } else {
           errors.push(`Row ${rowNum}: Database error - ${dbError.message}`);
        }
      }
    }

    return res.status(200).json({
      message: `Successfully imported ${importedUsers.length} users.`,
      imported: importedUsers.length,
      errors,
    });
  } catch (error: any) {
    console.error('CSV Import Error:', error);
    return res.status(500).json({ error: 'Failed to process CSV file', details: error.message });
  }
};

export const exportUsersCsv = async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      include: {
        studentProfile: true,
        supervisorProfile: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    const formattedData = users.map(user => {
      let regStaffNo = '';
      let department = '';
      let phone = '';
      
      if (user.role === 'STUDENT' && user.studentProfile) {
        regStaffNo = user.studentProfile.registrationNo;
        department = user.studentProfile.department || '';
        phone = user.studentProfile.phone || '';
      } else if (user.role === 'SUPERVISOR' && user.supervisorProfile) {
        regStaffNo = user.supervisorProfile.staffNumber;
        department = user.supervisorProfile.department || '';
        phone = user.supervisorProfile.phone || '';
      }

      return {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: phone,
        status: user.status,
        registration_or_staff_no: regStaffNo,
        department: department,
        created_at: user.createdAt.toISOString(),
      };
    });

    const csvString = stringify(formattedData, {
      header: true,
      columns: [
        { key: 'id', header: 'ID' },
        { key: 'name', header: 'Name' },
        { key: 'email', header: 'Email' },
        { key: 'role', header: 'Role' },
        { key: 'phone', header: 'Phone' },
        { key: 'status', header: 'Status' },
        { key: 'registration_or_staff_no', header: 'Reg/Staff No' },
        { key: 'department', header: 'Department' },
        { key: 'created_at', header: 'Created At' },
      ],
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="users_export.csv"');
    
    return res.status(200).send(csvString);
  } catch (error: any) {
    console.error('CSV Export Error:', error);
    return res.status(500).json({ error: 'Failed to export users to CSV' });
  }
};
