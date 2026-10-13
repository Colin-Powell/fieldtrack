import { Request, Response, NextFunction } from 'express';
import { ZodError, ZodSchema } from 'zod';

export function validate(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const details = error.issues.map((e: any) => ({
          path: e.path.join('.'),
          message: e.message,
        }));

        const firstMessage = details[0]?.message ?? 'Please check the submitted data.';

        return res.status(400).json({
          error: 'Validation failed',
          message: firstMessage,
          details,
        });
      }
      return res.status(500).json({ error: 'Internal Server Error' });
    }
  };
}
