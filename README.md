# MobilityTicketing - Lecture 4

Work for the product identity migration lab.

Tickets start out linked to products by `product_code`. The migration adds a stable UUID to each product and moves tickets to `product_id` in stages, so the old and new access patterns can overlap without changing historical ticket prices.

## Run the database

```bash
docker compose up -d
docker compose ps
```

Reset it when needed with:

```bash
docker compose down -v
docker compose up -d
```

The completed migration files are in `database/postgres/migrations/`. The readers, writers and failure tests are in `database/postgres/experiments/lecture04/`.

The lab notes and test results are in `docs/evidence/lecture04/README.md`.
