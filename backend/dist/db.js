import dotenv from 'dotenv';
dotenv.config();
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
    throw new Error('DATABASE_URL must be set in the environment variables.');
}
const pool = new Pool({
    connectionString,
    max: 100, // Maximum number of clients in the pool
    min: 20, // Minimum number of clients to keep in the pool
    idleTimeoutMillis: 30000 // Close idle clients after 30 seconds
});
const adapter = new PrismaPg(pool);
export const prisma = new PrismaClient({ adapter });
