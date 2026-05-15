# AFitAccess - Guide de demarrage

## Prerequis

- Docker Desktop installe et lance
- Git installe
- Optionnel pour lancer les services sans Docker :
  - Python 3.11
  - Node.js 20

## Demarrage avec Docker

### 1. Cloner le depot

```bash
git clone https://github.com/mouhameddiop06/AFitAccess.git
cd AFitAccess
```

### 2. Lancer tous les services

```bash
docker compose up --build
```

Pour les lancements suivants :

```bash
docker compose up
```

## Acces aux services

| Service | URL |
| --- | --- |
| Frontend Vue/Vite | http://localhost:5173 |
| API FastAPI | http://localhost:8000 |
| Documentation Swagger | http://localhost:8000/docs |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

La base de donnees est initialisee au premier demarrage avec le fichier
`database/afitaccess_postgresql.sql`.

## Demarrage local sans Docker

### Backend

```bash
cd backend
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# macOS/Linux
source .venv/bin/activate

python -m pip install --upgrade pip
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend

Dans un second terminal :

```bash
cd frontend
npm install
npm run dev
```

## Verification locale

```bash
# Backend
cd backend
ruff check .
pytest

# Frontend
cd frontend
npm run build
```

## Arreter le projet Docker

```bash
docker compose down
```

Pour supprimer aussi les volumes de donnees :

```bash
docker compose down -v
```

## Commandes utiles

```bash
# Logs de tous les services
docker compose logs -f

# Logs d'un service specifique
docker compose logs -f api

# Reconstruire uniquement l'API
docker compose up --build api

# Voir les conteneurs actifs
docker ps
```
