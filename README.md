# Syrupy - Rails-Powered Journaling Platform API

Syrupy is a sophisticated Rails-powered, web-based journaling platform grounded in stoic principles, designed to turn self-reflection into action. This repository contains the backend API that powers the journaling experience.

## 🏗️ High-Level Architecture

### System Overview

```mermaid
graph TB
    User[User/Client] --> API[Rails API Server]
    API --> DB[(PostgreSQL Database)]
    API --> BG[GoodJob Background Worker]
    API --> Cache[SolidCache]
    
    subgraph "Rails Application"
        API --> Auth[Authentication Layer]
        API --> Policies[Authorization Policies]
        API --> Controllers[API Controllers]
        Controllers --> Services[Service Objects]
        Controllers --> Models[ActiveRecord Models]
        Models --> DB
    end
    
    subgraph "Data Processing"
        BG --> Analytics[Mood Analytics]
        BG --> Insights[Journal Insights]
        BG --> Notifications[User Notifications]
    end
```

### Architectural Patterns

- **API-Only Rails Application**: Clean JSON API following RESTful conventions
- **Service-Oriented Architecture**: Complex business logic encapsulated in service objects
- **Policy-Based Authorization**: Pundit policies for fine-grained access control
- **Soft Deletion Pattern**: All models support soft deletion with `discarded_at` timestamps
- **Background Job Processing**: Asynchronous tasks handled by GoodJob
- **Request-Scoped Context**: Current user and request context management
- **Blueprint Serialization**: Consistent API responses using Blueprinter
- **Auditing**: Complete change tracking with the audited gem

## 📊 Entity Relationship Diagram

```mermaid
erDiagram
    User ||--o{ JournalEntry : creates
    User ||--o{ Goal : sets
    User ||--o{ MoodLog : tracks
    User ||--o{ Habit : maintains
    User ||--o{ HabitLog : logs
    User }o--|| Account : "authenticated by"
    
    JournalEntry ||--o{ JournalEntryTag : tagged
    Tag ||--o{ JournalEntryTag : categorizes
    
    Habit ||--o{ HabitLog : "tracked by"
    
    User {
        bigint id PK
        bigint account_id FK
        string first_name
        string last_name
        string email
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }
    
    Account {
        bigint id PK
        integer status
        citext email
    }
    
    JournalEntry {
        bigint id PK
        bigint user_id FK
        string title
        text content
        integer mood_rating
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }
    
    Goal {
        bigint id PK
        bigint user_id FK
        string title
        text description
        string status
        string priority
        date target_date
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }
    
    MoodLog {
        bigint id PK
        bigint user_id FK
        integer rating
        text notes
        datetime logged_at
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }
    
    Habit {
        bigint id PK
        bigint user_id FK
        string name
        text description
        string frequency
        boolean active
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }
    
    HabitLog {
        bigint id PK
        bigint user_id FK
        bigint habit_id FK
        date logged_date
        boolean completed
        text notes
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }
    
    Tag {
        bigint id PK
        string name
        string color
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }
    
    JournalEntryTag {
        bigint id PK
        bigint journal_entry_id FK
        bigint tag_id FK
        datetime created_at
        datetime updated_at
    }
```

## 🚀 Features

### Core Functionality
- **📝 Journal Management**: Create, read, update, and delete journal entries with mood ratings
- **🏷️ Tagging System**: Organize entries with color-coded tags
- **😊 Mood Tracking**: Log emotional state over time with 1-10 ratings
- **🎯 Goal Setting**: Set and track personal goals with priorities and deadlines
- **🔄 Habit Tracking**: Define habits and log daily/weekly/monthly completion
- **📈 Analytics & Insights**: Track trends and get personalized recommendations

### Technical Features
- **🔐 Authentication**: Secure user authentication with Rodauth (currently disabled)
- **🛡️ Authorization**: Role-based access control with Pundit policies
- **♻️ Soft Deletion**: Recoverable deletion system
- **📋 Audit Trail**: Complete change tracking for all models
- **⚡ Background Jobs**: Async processing for analytics and notifications
- **💾 Caching**: PostgreSQL-backed caching with SolidCache
- **📊 Pagination**: Efficient data pagination with will_paginate

## 🛠️ Tech Stack

### Backend
- **Framework**: Rails 7.1.3 (API-only mode)
- **Language**: Ruby 3.3.3
- **Database**: PostgreSQL 14
- **Authentication**: Rodauth (temporarily disabled)
- **Authorization**: Pundit
- **Serialization**: Blueprinter
- **Background Jobs**: GoodJob
- **Caching**: SolidCache
- **Soft Deletion**: Discard
- **Auditing**: Audited gem
- **Testing**: RSpec with Factory Bot

### Frontend
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **Data Fetching**: TanStack Query
- **State Management**: Zustand
- **Routing**: React Router
- **Forms**: React Hook Form + Zod validation
- **UI Components**: Headless UI

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Web Server**: Puma (API) + Vite Dev Server (Frontend)
- **Database**: PostgreSQL with performance monitoring (PGHero)
- **Job Queue**: PostgreSQL-backed GoodJob
- **CORS**: Rack-CORS for cross-origin requests

### Development Tools
- **Code Quality**: RuboCop with Rails/RSpec/Performance extensions
- **Security**: Brakeman static analysis
- **Testing**: RSpec, WebMock, Timecop, N+1 query detection
- **IDE Support**: Ruby LSP

## 🏃‍♂️ Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd syrupy-api
   ```

2. **Build and start the application**:
   ```bash
   make setup
   ```
   
   This command will:
   - Build Docker images
   - Start all services (API, database, background worker)
   - Run database migrations
   - Seed the database with sample data

3. **Verify the installation**:
   ```bash
   # Check service status
   docker-compose ps
   
   # Test the API
   curl http://localhost:3000/up
   curl http://localhost:3000/api/tags
   
   # Test the frontend
   curl http://localhost:5173/
   ```

### Alternative Setup (Manual)

If you prefer manual setup:

```bash
# Build and start services
docker-compose up --build -d

# Create and migrate database
docker-compose exec api bundle exec rails db:create db:migrate

# Seed with sample data (optional)
docker-compose exec api bundle exec rails db:seed

# Check application health
curl http://localhost:3000/up
curl http://localhost:5173/
```

The API will be available at `http://localhost:3000`  
The frontend will be available at `http://localhost:5173`

## 🔧 Development

### Daily Development Workflow

```bash
# Start all services
docker-compose up

# Run migrations (if any)
docker-compose exec api bundle exec rails db:migrate

# Access Rails console
docker-compose exec api bundle exec rails console

# Run tests
docker-compose exec api bundle exec rspec

# View application logs
docker-compose logs -f api

# View background job logs
docker-compose logs -f good-job
```

### Database Operations

```bash
# Reset database
docker-compose exec api bundle exec rails db:drop db:create db:migrate db:seed

# Create new migration
docker-compose exec api bundle exec rails generate migration AddFieldToModel field:type

# Run specific migration
docker-compose exec api bundle exec rails db:migrate:up VERSION=20231225000001

# Rollback migration
docker-compose exec api bundle exec rails db:rollback
```

### Testing

```bash
# Run all tests
docker-compose exec api bundle exec rspec

# Run specific test file
docker-compose exec api bundle exec rspec spec/models/journal_entry_spec.rb

# Run tests with specific tag
docker-compose exec api bundle exec rspec --tag focus

# Run tests for specific controller
docker-compose exec api bundle exec rspec spec/controllers/api/journal_entries_controller_spec.rb
```

### Code Quality

```bash
# Run RuboCop
docker-compose exec api bundle exec rubocop

# Auto-correct RuboCop issues
docker-compose exec api bundle exec rubocop -a

# Run security analysis
docker-compose exec api bundle exec brakeman

# Check for N+1 queries in tests
docker-compose exec api bundle exec rspec --tag n_plus_one_control
```

## 🌐 API Documentation

### Base URL
All API endpoints are prefixed with `/api/` and return JSON responses.

### Authentication
> **Note**: Authentication is currently disabled for development. When enabled, include authentication headers in requests.

### Standard Response Format

```json
{
  "data": {
    "items": [...],
    "pages": 1,
    "total": 10
  }
}
```

### Core Endpoints

#### Health Check
- `GET /up` - Application health check (returns HTML)

#### Journal Entries
```bash
GET    /api/journal_entries          # List entries
POST   /api/journal_entries          # Create entry
GET    /api/journal_entries/:id      # Get specific entry
PUT    /api/journal_entries/:id      # Update entry
DELETE /api/journal_entries/:id      # Delete entry
GET    /api/journal_entries/insights # Get insights
```

#### Goals
```bash
GET    /api/goals              # List goals
POST   /api/goals              # Create goal
GET    /api/goals/:id          # Get specific goal
PUT    /api/goals/:id          # Update goal
DELETE /api/goals/:id          # Delete goal
GET    /api/goals/due_soon     # Get goals due soon
```

#### Mood Logs
```bash
GET    /api/mood_logs          # List mood logs
POST   /api/mood_logs          # Create mood log
GET    /api/mood_logs/:id      # Get specific mood log
PUT    /api/mood_logs/:id      # Update mood log
DELETE /api/mood_logs/:id      # Delete mood log
GET    /api/mood_logs/trends   # Get mood trends
```

#### Habits
```bash
GET    /api/habits                    # List habits
POST   /api/habits                    # Create habit
GET    /api/habits/:id                # Get specific habit
PUT    /api/habits/:id                # Update habit
DELETE /api/habits/:id                # Delete habit
POST   /api/habits/:id/log_completion # Log habit completion
GET    /api/habits/streaks            # Get habit streaks
```

#### Tags
```bash
GET    /api/tags      # List tags
POST   /api/tags      # Create tag
GET    /api/tags/:id  # Get specific tag
PUT    /api/tags/:id  # Update tag
DELETE /api/tags/:id  # Delete tag
```

#### User Profile
```bash
GET /api/me  # Get current user profile
PUT /api/me  # Update current user profile
```

### Query Parameters

Most list endpoints support:
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 30)
- `q` - Search query
- `sort` - Sort field
- `order` - Sort direction (asc/desc)

### Authentication API

#### Register a New User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123!",
    "first_name": "John",
    "last_name": "Doe"
  }' \
  -c cookies.txt
```

#### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123!"
  }' \
  -c cookies.txt
```

#### Check Authentication Status
```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

#### Logout
```bash
curl -X DELETE http://localhost:3000/api/auth/logout \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

### Example API Calls (Authenticated)

```bash
# Get all tags (requires authentication)
curl http://localhost:3000/api/tags -b cookies.txt

# Create a journal entry (requires authentication)
curl -X POST http://localhost:3000/api/journal_entries \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "journal_entry": {
      "title": "Today was great!",
      "content": "Had an amazing day reflecting on my goals.",
      "mood_rating": 8,
      "tag_ids": [1, 2]
    }
  }'

# Get paginated mood logs (requires authentication)
curl "http://localhost:3000/api/mood_logs?page=1&per_page=10" -b cookies.txt
```

## 📁 Project Structure

```
syrupy/
├── app/
│   └── frontend/                # React frontend application
│       ├── src/
│       │   ├── components/     # Reusable UI components
│       │   ├── features/       # Feature-based organization
│       │   ├── hooks/          # Custom React hooks
│       │   ├── router/         # Routing configuration
│       │   ├── services/       # API service layer
│       │   ├── stores/         # Zustand state stores
│       │   └── utils/          # Utility functions
│       ├── public/             # Static assets
│       ├── package.json        # Node.js dependencies
│       ├── vite.config.ts      # Vite configuration
│       ├── tailwind.config.js  # Tailwind CSS configuration
│       └── Dockerfile          # Frontend Docker image
├── api/                        # Rails API application
│   ├── app/
│   │   ├── blueprints/         # API serializers
│   │   ├── controllers/        # API controllers
│   │   │   └── api/           # Namespaced API controllers
│   │   ├── models/            # ActiveRecord models
│   │   ├── policies/          # Pundit authorization policies
│   │   └── services/          # Business logic services
│   ├── config/                # Rails configuration
│   ├── db/
│   │   ├── migrate/           # Database migrations
│   │   └── seeds.rb           # Seed data
│   ├── spec/                  # RSpec tests
│   ├── Dockerfile.dev         # Development Docker image
│   └── Gemfile               # Ruby dependencies
├── docker-compose.yml        # Development environment
├── Makefile                 # Development commands
└── README.md               # This file
```

## 🗄️ Database Schema Details

### Key Model Relationships

1. **User-Centric Design**: All core entities belong to a User
2. **Soft Deletion**: All models include `discarded_at` for recovery
3. **Audit Trail**: All changes tracked with `audited` gem
4. **Tagging System**: Many-to-many relationship between JournalEntries and Tags
5. **Habit Tracking**: Habits have many HabitLogs for completion tracking

### Database Constraints

- **Unique Constraints**: Email addresses, tag names, habit completion dates
- **Foreign Key Constraints**: Referential integrity maintained
- **Check Constraints**: Mood ratings (1-10), goal statuses, habit frequencies
- **Indexes**: Optimized for common query patterns

### Seed Data

The application includes seed data for development:
- 4 demo tags (gratitude, reflection, goals, daily)
- Demo user account
- Sample journal entries with various moods
- Example goals with different priorities
- Habit tracking examples
- Mood log history

## 🧪 Testing Strategy

### Test Structure
```
spec/
├── controllers/    # Controller tests
├── models/        # Model tests with validations and associations
├── policies/      # Authorization policy tests
├── factories/     # Factory Bot definitions
├── support/       # Test helpers and shared examples
└── rails_helper.rb # RSpec configuration
```

### Testing Conventions
- **Model Tests**: Validations, associations, scopes, and methods
- **Controller Tests**: API endpoints, authorization, and response formats
- **Policy Tests**: Authorization rules for different user roles
- **Integration Tests**: End-to-end API workflows
- **Factory Tests**: Ensure all factories produce valid objects

### Test Data
- Factory Bot for test data generation
- Faker for realistic test content
- Timecop for time-dependent testing
- WebMock for external API mocking

## 🚀 Deployment

### Environment Variables

Set these variables for production:

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:port/database

# Rails Security
RAILS_MASTER_KEY=your_master_key
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=your_primary_key
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=your_deterministic_key
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=your_salt

# Application
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# Background Jobs
GOOD_JOB_EXECUTION_MODE=async
GOOD_JOB_QUEUES=*
GOOD_JOB_MAX_THREADS=5
```

### Production Checklist

- [ ] Set all required environment variables
- [ ] Configure SSL/TLS certificates
- [ ] Set up database backups
- [ ] Configure log aggregation
- [ ] Set up monitoring and alerts
- [ ] Configure CORS for your frontend domain
- [ ] Enable authentication (Rodauth)
- [ ] Set up background job monitoring

## 🔧 Troubleshooting

### Common Issues

1. **Docker Build Failures**
   ```bash
   # Clean up Docker resources
   docker system prune -a
   docker-compose down -v
   docker-compose up --build
   ```

2. **Database Connection Issues**
   ```bash
   # Check database service
   docker-compose ps db
   docker-compose logs db
   
   # Reset database
   docker-compose exec api bundle exec rails db:reset
   ```

3. **Authentication Errors**
   > Session-based authentication is enabled. Use `/api/auth/register`, `/api/auth/login`, and `/api/auth/logout` endpoints.

4. **Empty API Responses**
   - Check if user authentication is working
   - Verify Pundit policies allow access
   - Check for soft-deleted records

### Debugging Tips

```bash
# Check application logs
docker-compose logs -f api

# Access Rails console for debugging
docker-compose exec api bundle exec rails console

# Check database directly
docker-compose exec db psql -U postgres -d syrupy_development

# Run specific tests for debugging
docker-compose exec api bundle exec rspec spec/models/user_spec.rb --format documentation
```

## 🤝 Contributing

### Development Guidelines

1. **Code Style**: Follow existing patterns and RuboCop rules
2. **Testing**: Write comprehensive tests for all new features
3. **Documentation**: Update this README for significant changes
4. **Commits**: Use conventional commit messages
5. **Pull Requests**: Include tests and documentation updates

### Adding New Features

1. **Create Migration**: `rails generate migration AddFeatureToModel`
2. **Update Model**: Add validations, associations, and methods
3. **Create Policy**: Define authorization rules in `app/policies/`
4. **Add Blueprint**: Create serializer in `app/blueprints/`
5. **Build Controller**: Implement API endpoints in `app/controllers/api/`
6. **Update Routes**: Add routes in `config/routes.rb`
7. **Write Tests**: Comprehensive test coverage
8. **Update Documentation**: API endpoints and schema changes

### Architecture Decisions

When adding new features, consider:
- **RESTful Design**: Follow REST conventions for API endpoints
- **Authorization**: Implement proper Pundit policies
- **Soft Deletion**: Use `discard` for user-facing deletions
- **Background Jobs**: Use GoodJob for time-consuming operations
- **Caching**: Implement caching for expensive queries
- **Validation**: Both model and controller-level validation

---

## 📞 Support

For questions or issues:
1. Check this documentation first
2. Search existing issues in the repository
3. Create a new issue with detailed information
4. Include relevant logs and error messages

---

**Happy Journaling! 📝✨** 