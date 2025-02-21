# slog <span style="font-size: small;"> Star Citizen Game Log Parsing for Teams </span>

## Overview

This system provides:
- A **PowerShell client** that tails Star Citizen's `Game.log` and sends events to a central **FastAPI** server.
- A **FastAPI** server that stores events in a **PostgreSQL** database, handles deduplication, and broadcasts updates both in Discord and to a mobile app via **WebSockets**.

**Player groups** are identified by password, and can only be viewed on Discord/mobile by subscribing to that password (eg `/subscribe <password>`)

---

## 1. System Requirements

### Server (Linux)
- **Python 3.9+**  
- **PostgreSQL 13+**  
- **Git** (optional, but required to use the `sparse_checkout.sh` script for minimal server setup)  

### Client (Windows 10/11)
- **PowerShell 5.1 or later**  
- **.NET Framework 4.7 or higher** (for the GUI script `config_gui.ps1`)  

---

## 2. Server Setup Options

### Option A: Git Clone

1. Clone or copy the entire repo onto the server.
2. Follow the [Installation and Running the Server](#4-installing-and-running-the-server-using-venv) steps below.

### Option B: Sparse Checkout

If only the `server/` (and optionally `scripts/`) directories are needed, you can do a **sparse checkout**:
```bash
# 1) Ensure git is installed:
sudo apt update
sudo apt install -y git

# 2) Run the sparse_checkout.sh script
cd ~   # place the project in the home dir
bash sparse_checkout.sh
```

## 3. Database Setup (PostgreSQL)

1. Install PostgreSQL (if not already installed):
```bash
sudo apt install -y postgresql postgresql-contrib
```
2. Create a user and database (if desired). For example:

sudo -u postgres psql
CREATE USER starcitizen WITH PASSWORD 'your_secure_password';
CREATE DATABASE starcitizen_db OWNER starcitizen;
\q
