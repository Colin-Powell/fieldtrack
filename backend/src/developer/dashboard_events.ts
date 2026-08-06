import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';
import { verifyToken } from '../auth/jwt.js';

const dashboardClients = new Set<WebSocket>();

export function initializeDashboardSocket(server: Server) {
  const wss = new WebSocketServer({ server, path: '/api/v1/developer/ws' });

  wss.on('connection', (socket, request) => {
    const requestUrl = new URL(request.url ?? '/', `http://${request.headers.host || 'localhost'}`);
    const token = requestUrl.searchParams.get('token');

    if (!token) {
      socket.send(JSON.stringify({ type: 'error', message: 'Unauthorized' }));
      socket.close();
      return;
    }

    try {
      const payload = verifyToken(token);
      if (payload.role !== 'ADMIN') {
        throw new Error('Forbidden');
      }
    } catch (_error) {
      socket.send(JSON.stringify({ type: 'error', message: 'Unauthorized' }));
      socket.close();
      return;
    }

    dashboardClients.add(socket);
    socket.send(JSON.stringify({
      type: 'connected',
      message: 'Developer dashboard live feed connected',
      timestamp: new Date().toISOString(),
    }));

    socket.on('close', () => {
      dashboardClients.delete(socket);
    });
  });

  return wss;
}

export function broadcastDashboardEvent(payload: Record<string, unknown>) {
  const message = JSON.stringify(payload);
  for (const client of dashboardClients) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  }
}
