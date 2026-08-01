import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';

const { combine, timestamp, json, printf } = winston.format;

const logFormat = combine(
  timestamp(),
  json()
);

export const appLogger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: logFormat,
  transports: [
    new DailyRotateFile({
      filename: 'logs/application/app-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxFiles: '14d',
    }),
    new DailyRotateFile({
      filename: 'logs/errors/error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxFiles: '30d',
      level: 'error',
    })
  ]
});

export const authLogger = winston.createLogger({
  level: 'info',
  format: logFormat,
  transports: [
    new DailyRotateFile({
      filename: 'logs/authentication/auth-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxFiles: '90d',
    })
  ]
});

export const uploadsLogger = winston.createLogger({
  level: 'info',
  format: logFormat,
  transports: [
    new DailyRotateFile({
      filename: 'logs/uploads/uploads-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxFiles: '14d',
    })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  const consoleTransport = new winston.transports.Console({
    format: winston.format.simple(),
  });
  appLogger.add(consoleTransport);
  authLogger.add(consoleTransport);
  uploadsLogger.add(consoleTransport);
}
