#!/usr/bin/env bash

# Installs system dependencies, sets up Python venv, installs packages,
# creates a PostgreSQL user/db, and initializes the database.
# Designed for Ubuntu/Debian-based systems. 


set -e 


echo "Installing system dependencies (Python, pip, etc)..."
# get up to date postgresql 
sudo mkdir -p /etc/apt/keyrings
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/keyrings/postgresql.asc

echo "deb [signed-by=/etc/apt/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo add-apt-repository ppa:deadsnakes/ppa -y

sudo apt update
sudo apt install -y postgresql software-properties-common python3.11 python3.11-venv python3.11-dev libpq-dev -y


echo "Setting up PostgreSQL user and database..."

DB_USER="slog"
DB_PASS="your_secure_password"
DB_NAME="slog_db"

sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (
       SELECT FROM pg_catalog.pg_roles
       WHERE  rolname = '${DB_USER}'
   ) THEN
       CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
   END IF;
END
\$\$;

CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
EOF

echo "PostgreSQL user/database created or already exists."


cd ~/slog/server
echo "Creating Python venv in $(pwd)/venv ..."
python3.11 -m venv venv

echo "Activating virtual environment..."
source venv/bin/activate

echo "Installing Python dependencies..."
python3.11 -m pip install --upgrade pip
python3.11 -m pip install -r requirements.txt

echo "Initializing database tables..."
python3.11 db_init.py

# to automatically start the server, uncomment:
# uvicorn app:app --host 0.0.0.0 --port 8000

echo "Server setup script complete!"
echo "To run the server manually, activate the venv and start uvicorn:"
echo "  cd ~/slog/server"
echo "  source venv/bin/activate"
echo "  uvicorn app:app --host 0.0.0.0 --port 8000"
