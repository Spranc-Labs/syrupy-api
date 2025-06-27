# Syrupy Frontend

Modern React frontend for the Syrupy journaling platform, built with TypeScript and Vite.

## 🛠️ Tech Stack

- **React 18** - Modern React with hooks and concurrent features
- **TypeScript** - Type-safe development
- **Vite** - Fast build tool and dev server  
- **TanStack Query** - Data fetching and caching
- **React Router** - Client-side routing
- **Tailwind CSS** - Utility-first CSS framework
- **Zustand** - Lightweight state management
- **React Hook Form** - Form handling with validation
- **Zod** - TypeScript-first schema validation

## 🚀 Development

### Prerequisites

The frontend runs in Docker alongside the Rails API. Make sure you have:
- Docker and Docker Compose
- The main Syrupy project running

### Getting Started

```bash
# From the project root
make up-d

# Or start in foreground to see logs
make up
```

The frontend will be available at: http://localhost:5173

### Development Commands

```bash
# View frontend logs
make logs-frontend

# Open shell in frontend container
make shell-frontend

# Install new dependencies (from inside container)
npm install <package-name>

# Run linting
docker-compose exec frontend npm run lint

# Type checking
docker-compose exec frontend npm run type-check
```

## 📁 Project Structure

```
src/
├── components/        # Reusable UI components
├── features/          # Feature-based organization
│   ├── auth/         # Authentication features
│   ├── dashboard/    # Dashboard features
│   ├── journal/      # Journal entry features
│   ├── goals/        # Goal tracking features
│   ├── habits/       # Habit tracking features
│   └── mood/         # Mood logging features
├── hooks/            # Custom React hooks
├── router/           # Routing configuration
├── services/         # API service layer
├── stores/           # Zustand state stores
├── styles/           # Global styles and themes
├── types/            # TypeScript type definitions
├── utils/            # Utility functions
└── config/           # Configuration files
```

## 🔌 API Integration

The frontend integrates with the Rails API running on port 3000. All API calls are proxied through Vite's dev server for seamless development.

### Authentication

- Session-based authentication using cookies
- Login/logout/register flows
- Protected routes with authentication guards

### Key Features

- **Journal Entries** - Create, edit, and manage journal entries
- **Goal Tracking** - Set and track personal goals
- **Habit Formation** - Build and maintain healthy habits
- **Mood Logging** - Track emotional well-being over time
- **Analytics** - Visualize progress and insights

## 🎨 UI/UX

- Clean, modern interface built with Tailwind CSS
- Responsive design that works on all devices
- Accessible components following WCAG guidelines
- Loading states and error handling
- Toast notifications for user feedback

## 🧪 Development Philosophy

Following the same patterns as the Subble codebase:

- **Feature-driven architecture** - Organized by business features
- **TypeScript everywhere** - Type safety across the application
- **Component composition** - Reusable, composable UI components
- **Data fetching with React Query** - Optimized caching and synchronization
- **Form handling with React Hook Form** - Performant, accessible forms
- **State management with Zustand** - Simple, scalable state management

## 📦 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript compiler check

## 🐳 Docker Integration

The frontend runs in a Docker container alongside the Rails API:

- **Development**: Uses Vite dev server with hot reloading
- **Volume mounting**: Source code is mounted for live development
- **Dependency caching**: Node modules are cached in Docker volume
- **Health checks**: Container health monitoring included

## 🔧 Configuration

Key configuration files:

- `vite.config.ts` - Vite build configuration
- `tailwind.config.js` - Tailwind CSS configuration
- `tsconfig.json` - TypeScript configuration
- `.eslintrc.cjs` - ESLint rules and plugins
- `postcss.config.js` - PostCSS plugins 