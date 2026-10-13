import { z } from 'zod';
export const loginSchema = z.object({
    body: z.object({
        email: z.string().trim().email('Invalid email address').nullish(),
        registrationNo: z.string().trim().min(1, 'Registration number is required').nullish(),
        password: z.string().min(1, 'Password is required'),
    }).refine((data) => Boolean(data.email || data.registrationNo), {
        message: 'Either email or registrationNo is required',
    }),
});
export const registerSchema = z.object({
    body: z.object({
        name: z.string().min(2, 'Name must be at least 2 characters'),
        email: z.string().email('Invalid email address'),
        password: z.string().min(8, 'Password must be at least 8 characters long'),
        role: z.enum(['STUDENT', 'SUPERVISOR', 'ADMIN']).optional(),
    }),
});
