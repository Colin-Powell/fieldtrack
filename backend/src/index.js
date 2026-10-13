"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importStar(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const client_1 = require("@prisma/client");
const pg_1 = require("pg");
const adapter_pg_1 = require("@prisma/adapter-pg");
dotenv_1.default.config();
const app = (0, express_1.default)();
const connectionString = process.env.DATABASE_URL;
const pool = new pg_1.Pool({ connectionString });
const adapter = new adapter_pg_1.PrismaPg(pool);
const prisma = new client_1.PrismaClient({ adapter });
const port = process.env.PORT || 3000;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// ── Health Check ──
app.get('/health', (req, res) => {
    res.json({ status: 'ok', message: 'FieldTrack Unified Backend is running' });
});
// ── Shared Routes ──
app.post('/api/v1/auth/login', async (req, res) => {
    // TODO: Implement actual login logic with JWT
    res.json({ token: 'mock-jwt-token', user: { id: '1', role: 'SUPERVISOR' } });
});
// ── Supervisor Routes ──
app.get('/api/v1/supervisor/dashboard/stats', async (req, res) => {
    try {
        // Example: Mock response for now until we insert real data
        res.json({ checkedOut: 24, checkedIn: 12, inField: 9 });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
app.get('/api/v1/supervisor/students', async (req, res) => {
    try {
        const students = await prisma.user.findMany({
            where: { role: 'STUDENT' },
            include: { studentProfile: true }
        });
        res.json(students);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
// ── Student Routes ──
app.post('/api/v1/student/location', async (req, res) => {
    const { studentId, latitude, longitude } = req.body;
    try {
        const location = await prisma.locationUpdate.create({
            data: { studentId, latitude, longitude }
        });
        res.status(201).json(location);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
// ── Admin Routes ──
app.get('/api/v1/admin/users', async (req, res) => {
    try {
        const users = await prisma.user.findMany();
        res.json(users);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
app.listen(port, () => {
    console.log(`[server]: Unified Server is running at http://localhost:${port}`);
});
//# sourceMappingURL=index.js.map