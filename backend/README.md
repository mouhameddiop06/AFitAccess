# Backend

## Local dev

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Alembic

```bash
alembic revision --autogenerate -m "init"
alembic upgrade head
```
