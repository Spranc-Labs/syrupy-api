.PHONY: help build up down logs shell migrate test seed console

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Docker images
	docker-compose build

up: ## Start all services
	docker-compose up

up-d: ## Start all services in detached mode
	docker-compose up -d

down: ## Stop all services
	docker-compose down

logs: ## Show logs for all services
	docker-compose logs -f

logs-api: ## Show logs for API service only
	docker-compose logs -f api

logs-frontend: ## Show logs for frontend service only
	docker-compose logs -f frontend

shell: ## Open a shell in the API container
	docker-compose exec api sh

shell-frontend: ## Open a shell in the frontend container
	docker-compose exec frontend sh

console: ## Open Rails console
	docker-compose exec api bundle exec rails console

migrate: ## Run database migrations
	docker-compose exec api bundle exec rails db:migrate

create-db: ## Create and migrate database
	docker-compose exec api bundle exec rails db:create db:migrate

seed: ## Seed the database
	docker-compose exec api bundle exec rails db:seed

reset-db: ## Reset database (drop, create, migrate, seed)
	docker-compose exec api bundle exec rails db:drop db:create db:migrate db:seed

test: ## Run the test suite
	docker-compose exec api bundle exec rspec

test-models: ## Run model tests only
	docker-compose exec api bundle exec rspec spec/models/

test-controllers: ## Run controller tests only
	docker-compose exec api bundle exec rspec spec/controllers/

lint: ## Run RuboCop linter
	docker-compose exec api bundle exec rubocop

lint-fix: ## Run RuboCop with auto-fix
	docker-compose exec api bundle exec rubocop -A

routes: ## Show all routes
	docker-compose exec api bundle exec rails routes

clean: ## Clean up containers and volumes
	docker-compose down -v --remove-orphans
	docker system prune -f

setup: build up-d wait-for-db create-db seed ## Complete setup for new development environment

wait-for-db: ## Wait for database to be ready
	@echo "Waiting for database to be ready..."
	@until docker-compose exec db pg_isready -U postgres -h localhost; do \
		echo "Database not ready, waiting..."; \
		sleep 2; \
	done
	@echo "Database is ready!" 