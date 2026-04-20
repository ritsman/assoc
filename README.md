# Synetra

Monorepo for the Synetra association platform.

## Apps

- `synetra_web`: Next.js web application
- `synetra_bkend`: Node.js + Express + Prisma backend
- `synetra_py`: reserved for future Python services
- `synetra`: reserved for future Flutter app

## Stack

- Next.js for the web app
- Node.js + Express for the API
- PostgreSQL with Prisma ORM
- Docker Compose for local and VPS deployment

## Database approach

Synetra is designed as a multi-tenant SaaS that reuses the same PostgreSQL server/container already running for your society manager app.

- Existing database: `society_db`
- New database for Synetra: `synetra_db`
- Same PostgreSQL server/container, separate databases
- Tenant model: one association = one client/tenant

## Quick start

1. Copy the environment templates:
   - `cp synetra_bkend/.env.example synetra_bkend/.env`
   - `cp synetra_web/.env.example synetra_web/.env.local`
2. Start Docker:
   - `docker compose up --build`
3. Run migrations:
   - `docker compose exec synetra_bkend npx prisma migrate dev --name init`
4. Open:
   - Web: `http://localhost:5001`
   - API: `http://localhost:8083/api/health`

## Shared Postgres

Synetra does not start its own Postgres container anymore.

- The backend connects to `host.docker.internal:5432` from Docker
- The backend connects to `localhost:5432` when run directly on the host
- You should create `synetra_db` inside the same PostgreSQL instance used by the society manager app
- The Synetra web app is published on host port `5001`
- The Synetra backend runs on port `5000` inside Docker and is published on host port `8083`

## Tenancy model

- One association is one tenant
- Members belong to only one association
- Branding, admin setup, web app behavior, and future Flutter apps are isolated by `associationId`
