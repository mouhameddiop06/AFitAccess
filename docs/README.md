# AFitAccess

Documentation du projet AFitAccess.

## Liens utiles

- Guide de demarrage : [`../demarrage.md`](../demarrage.md)
- Backend FastAPI : [`../backend/README.md`](../backend/README.md)
- Script d'initialisation PostgreSQL : [`../database/afitaccess_postgresql.sql`](../database/afitaccess_postgresql.sql)

## Verification CI

Les controles principaux sont executes par GitHub Actions :

- `ruff check .` dans `backend`
- `pytest` dans `backend`
- `npm ci` puis `npm run build` dans `frontend`
