# Banking Database (PostgreSQL)

This service provides a standalone PostgreSQL database for the Banking app with schema and seed scripts.

## Defaults

- DB name: myapp
- User: appuser
- Password: dbuser123
- Port: 5000
- Connection URL: postgresql://appuser:dbuser123@localhost:5000/myapp

These values are also exported to db_visualizer/postgres.env for convenience.

## Files

- startup.sh — boots PostgreSQL (if needed), ensures DB/user/permissions, and applies schema.sql and seed.sql idempotently.
- schema.sql — creates tables: users, accounts, transactions, with constraints and indexes.
- seed.sql — inserts a demo user, two accounts, and sample transactions.
- db_connection.txt — convenience psql connection command.
- db_visualizer/ — simple Node.js database viewer to inspect tables and data.

## Usage

1) Start PostgreSQL and apply schema/seed (idempotent)
- Run:
  - bash startup.sh

The script will:
- Start PostgreSQL on port 5000 (if not already running)
- Ensure database and user exist
- Apply schema.sql if not already applied (checks for users table)
- Apply seed.sql (safe to re-run)
- Write aligned env variables to db_visualizer/postgres.env:
  - POSTGRES_URL="postgresql://localhost:5000/myapp"
  - POSTGRES_USER="appuser"
  - POSTGRES_PASSWORD="dbuser123"
  - POSTGRES_DB="myapp"
  - POSTGRES_PORT="5000"

2) Connect to the database
- psql -h localhost -U appuser -d myapp -p 5000
- Or use the command saved to db_connection.txt:
  - cat db_connection.txt
  - psql postgresql://appuser:dbuser123@localhost:5000/myapp

3) Backend DATABASE_URL
- Point the backend .env to the same URL:
  - DATABASE_URL=postgresql://appuser:dbuser123@localhost:5000/myapp

4) Launch the simple database viewer (optional)
- Prepare environment:
  - source db_visualizer/postgres.env
- Install and run viewer (from db_visualizer directory):
  - cd db_visualizer
  - npm install
  - npm start
- Open http://localhost:3000 and choose postgres
  - Endpoints:
    - GET /api/databases
    - GET /api/postgres/tables
    - GET /api/postgres/tables/:table/data?limit=50

## Schema Overview

- users
  - id (serial pk)
  - email (unique)
  - password_hash
  - created_at (timestamptz default now())

- accounts
  - id (serial pk)
  - user_id (fk users.id)
  - name
  - currency
  - balance numeric(14,2) default 0
  - created_at (timestamptz default now())
  - indexes: (user_id), (created_at)

- transactions
  - id (serial pk)
  - account_id (fk accounts.id)
  - type text check in ('deposit','withdrawal','transfer')
  - amount numeric(14,2) check > 0
  - currency
  - description text
  - created_at (timestamptz default now())
  - related_account_id int null fk accounts(id)
  - indexes: (account_id), (created_at)

## Notes

- The seed uses a placeholder password hash. Replace with a real hash in production.
- Schema and seed scripts are safe to run multiple times; schema checks the existence of the users table; seed uses checks and upserts-by-absence to avoid duplicates.
