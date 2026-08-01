import { ZodError } from 'zod';
export function validate(schema) {
    return (req, res, next) => {
        try {
            schema.parse({
                body: req.body,
                query: req.query,
                params: req.params,
            });
            next();
        }
        catch (error) {
            if (error instanceof ZodError) {
                return res.status(400).json({
                    error: 'Validation failed',
                    details: error.issues.map((e) => ({
                        path: e.path.join('.'),
                        message: e.message,
                    })),
                });
            }
            return res.status(500).json({ error: 'Internal Server Error' });
        }
    };
}
