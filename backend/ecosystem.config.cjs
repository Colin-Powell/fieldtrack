module.exports = {
  apps: [
    {
      name: 'fieldtrack-api',
      script: './dist/index.js',
      instances: 'max',       // Run in cluster mode across all available CPUs
      exec_mode: 'cluster',
      autorestart: true,      // Restart if crashes
      watch: false,           // Do not watch files in production
      max_memory_restart: '1G', // Restart if memory exceeds 1 GB
      env: {
        NODE_ENV: 'development',
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    },
    {
      name: 'fieldtrack-worker',
      script: './dist/worker.js',
      instances: 1,           // Generally, 1 instance of a background worker is enough to start.
      autorestart: true,      // Restart if crashes
      watch: false,           // Do not watch files in production
      max_memory_restart: '1G', // Restart if memory exceeds 1 GB
      env: {
        NODE_ENV: 'development',
      },
      env_production: {
        NODE_ENV: 'production',
      }
    }
  ]
};
