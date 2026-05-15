# AFitAccess — Guide de démarrage

## Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et lancé
- [Git](https://git-scm.com/) installé

---

## Démarrage du projet

### 1. Cloner le dépôt

```bash
git clone https://github.com/mouhameddiop06/AFitAccess.git
cd AFitAccess
```

### 2. Lancer le projet

```bash
docker compose up --build
```

> La première fois, le build peut prendre quelques minutes le temps de télécharger les images et construire les conteneurs.

Pour les lancements suivants (sans rebuild) :

```bash
docker compose up
```

---

## Accès aux services

| Service | URL |
|---|---|
| Frontend | [http://localhost:5173](http://localhost:5173) |
| API (Swagger UI) | [http://localhost:8000/docs](http://localhost:8000/docs) |
| Base de données | `localhost:5432` (PostgreSQL) |
| Cache | `localhost:6379` (Redis) |

---

## Arrêter le projet

```bash
docker compose down
```

Pour tout supprimer (conteneurs + volumes de données) :

```bash
docker compose down -v
```

---

## Structure des services

```
afitaccess-frontend   → React/Vite         (port 5173)
afitaccess-api        → FastAPI/Python      (port 8000)
afitaccess-db         → PostgreSQL 16       (port 5432)
afitaccess-redis      → Redis 7             (port 6379)
```

La base de données est initialisée automatiquement au premier démarrage avec le fichier `database/afitaccess_postgresql.sql`.

---

## Commandes utiles

```bash
# Voir les logs de tous les services
docker compose logs -f

# Voir les logs d'un service spécifique
docker compose logs -f api

# Reconstruire uniquement un service
docker compose up --build api

# Voir les conteneurs en cours d'exécution
docker ps
``