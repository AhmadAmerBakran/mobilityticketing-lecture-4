# MobilityTicketing compulsory assignment 1

This repository is the review copy for the first four database lectures. The implementation files are kept close to the work they came from, and the `submission` folder collects the material that is useful during the review meeting.

Submitted commit: use the exact commit hash entered in Moodle.

## Setup and reset

Docker Desktop with Compose is required.

```bash
docker compose up -d
docker compose ps
```

To reset the database and replay the initialization scripts:

```bash
docker compose down -v
docker compose up -d
```

The lecture 4 migration sequence can be checked with the SQL files under `database/postgres/experiments/lecture04` and `database/postgres/migrations`.

## Where to find the work

### Lecture 1

The workload map, relational model, modelling assumption and functional dependency are in [lecture 1 notes](submission/lecture01/notes.md). The executable schema, seed and three route or timetable queries are in [schema.sql](submission/lecture01/schema.sql), [seed.sql](submission/lecture01/seed.sql) and [queries.sql](submission/lecture01/queries.sql).

### Lecture 2

The integrity map and the limits of database constraints are in [lecture 2 notes](submission/lecture02/notes.md). The migration is in [integrity_migration.sql](submission/lecture02/integrity_migration.sql). Successful writes are in [valid_writes.sql](submission/lecture02/valid_writes.sql), and rejected writes with expected SQLSTATE values are in [rejected_writes.sql](submission/lecture02/rejected_writes.sql).

### Lecture 3

The reporting comparison and responsibility decision are in [lecture 3 notes](submission/lecture03/notes.md). The direct query, function, trigger, materialized view, test cases and rebuild query are all in [submission/lecture03](submission/lecture03). The captured console output is in [reporting_output.txt](submission/lecture03/reporting_output.txt).

### Lecture 4

The migration stages, compatibility checks and ticket price evidence are summarized in [lecture 4 notes](submission/lecture04/notes.md). The actual migrations are in [database/postgres/migrations](database/postgres/migrations), and the old, new and final readers and writers are in [database/postgres/experiments/lecture04](database/postgres/experiments/lecture04).

## Two decisions worth discussing

### Route stop identity

I used `(route_id, stop_sequence)` as the primary key for `route_stops`. The alternative was `(route_id, stop_id)`. Using the sequence keeps each position on a route unique while still allowing the same stop to appear more than once on one route. The schema and ordered stop query show the consequence of that choice.

### Reporting responsibility

I kept `payments` as the authority for captured revenue and chose a materialized view as the daily read model. A trigger maintained summary was the main alternative. The experiment shows why I did not make the trigger summary authoritative: it becomes incorrect for backfill, status corrections and deletes unless more write side logic is added. The materialized view can be stale, but its freshness point is explicit and it can be rebuilt from the base tables.

## One limitation

The integrity migration keeps a single trip row valid, but it does not guarantee that two concurrent purchases cannot oversell the same trip. That needs a transaction strategy such as a locking or atomic update approach around the purchase workflow. The current database constraints deliberately do not pretend to solve that cross write problem.
