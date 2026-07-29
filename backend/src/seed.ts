import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

dotenv.config();

const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Starting seeder...');
  
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@fieldtrack.com';
  const adminPassword = process.env.ADMIN_PASSWORD || 'ChangeMe123!';

  // Check if admin already exists
  const existingAdmin = await prisma.user.findFirst({
    where: { role: 'ADMIN' },
  });

  if (existingAdmin) {
    console.log('An ADMIN user already exists. Seeder is skipping to prevent duplicates.');
    return;
  }

  // Hash password
  const saltRounds = 12;
  const hashedPassword = await bcrypt.hash(adminPassword, saltRounds);

  // Create admin user
  const admin = await prisma.user.create({
    data: {
      name: 'System Administrator',
      email: adminEmail,
      password: hashedPassword,
      role: 'ADMIN',
    },
  });

  console.log(`Created admin account successfully! Email: ${admin.email}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
