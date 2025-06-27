import path from 'path'

import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    // Need to use this host so that the dev server, when run in docker,
    // can be accessed from the host machine.
    host: '0.0.0.0',
    watch: {
      usePolling: process.env.IN_DEV_CONTAINER === 'true',
    },
    allowedHosts: ['localhost', 'frontend'],
    // HMR configuration for Docker
    hmr: {
      host: 'localhost',
      clientPort: 5173,
      protocol: 'ws',
    },
  },
  plugins: [react()],
  define: {
    __APP_VERSION__: process.env.COMMIT_HASH
      ? JSON.stringify(process.env.COMMIT_HASH)
      : JSON.stringify('development'),
    global: {}, // For undefined global error
  },
  resolve: {
    alias: {
      src: `${path.resolve(__dirname, './src/')}`,
    },
  },
}) 