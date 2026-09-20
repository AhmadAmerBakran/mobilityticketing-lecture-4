# Lecture 4 lab notes

I started from the lecture 4 fixture and left `database/postgres/init/` unchanged. The work is done as migrations and experiment scripts.

## Baseline

I used:

```bash
docker compose up -d
docker compose exec -T postgres psql -U mobility -d mobility -v ON_ERROR_STOP=1 < database/postgres/experiments/lecture04/baseline.sql
```

The starting tickets are:

| Ticket | Product | Paid price | Currency |
| --- | --- | ---: | --- |
| TICKET-1 | SINGLE | 36.00 | DKK |
| TICKET-2 | SINGLE | 36.00 | DKK |
| TICKET-3 | DAY | 65.00 | DKK |

The DAY product is currently 80.00 DKK, so `TICKET-3` is the useful check that the migration does not recalculate historical prices.

## Unsafe change

`unsafe_change.sql` drops `tickets.product_code` inside a transaction and immediately runs the old reader. The drop itself can happen, but the old query then fails because `product_code` no longer exists. At that point the tickets would also have lost their only product reference because `product_id` has not been populated yet.

I did not use price to rebuild that link. Prices are not product identity, and the 65 DKK DAY ticket already proves that the price on a ticket can differ from the current catalogue.

After the expected failure I reset the lab database before continuing.

## Expansion

I ran `030_expand_product_identity.sql` once. It does four things without removing the old contract:

- gives every product a stored UUID;
- gives new products a UUID default;
- adds nullable `tickets.product_id`;
- adds the new foreign key as `NOT VALID`.

The old reader and old writer still work at this stage. The new reader also works before backfill because it falls back to `product_code` when `product_id` is null.

On a much larger table I would keep the lock timeout, watch the row update and WAL volume, and avoid one very large backfill transaction. I would also consider building the unique index concurrently and doing the backfill in batches to reduce blocking.

## Writers during the overlap

`old_writer.sql` only writes `product_code`.

`new_writer.sql` takes a product ID and stores both references. The stored code is looked up from the product row; a caller-supplied code is not trusted. Passing the ID for SINGLE together with `DAY` as the caller code still stores `SINGLE`, so the writer cannot create a mismatched pair that way.

An unknown product ID matches no product and inserts no ticket.

The database itself does not enforce that the two references describe the same product during the overlap. `mismatch_test.sql` changes `TICKET-1` to the DAY product ID while leaving its code as SINGLE. Both individual foreign keys are valid, so PostgreSQL accepts the update. The verification query finds the mismatch, and the transaction is rolled back.

## Backfill and verification

The backfill only touches rows where `product_id` is null:

```sql
update tickets t
set product_id = p.id
from products p
where t.product_id is null
  and p.code = t.product_code;
```

In the test sequence, the first backfill fills the three original tickets plus one old-style ticket. Running it again changes zero rows. I then add another ticket with the old writer and run the backfill again; only that new row is filled.

`verify.sql` checks for null IDs, missing products, and code/ID pairs that point to different products. It also compares the three original tickets with the baseline values. The final verification before requiring the ID returns no problem rows, and `TICKET-3` is still DAY / 65.00 DKK.

## Requiring product_id

Before the successful run of `032_require_ticket_product.sql`, I add one more ticket with the old writer. The migration fails at `SET NOT NULL`, which is the wanted result while a null reference still exists.

After one last backfill and verification, the migration validates `tickets_product_id_fk` and makes `product_id` required. At that point an old-only writer fails because it does not provide `product_id`.

That is also the point where I would stop the old writers in a real rollout. Old readers can still work for a while because `product_code` is still present.

## Removing the old ticket reference

`final_reader.sql` joins products only through `product_id`. `final_writer.sql` inserts only `product_id` and keeps the agreed price on the ticket.

Before dropping the old column, `remove_legacy.sql` checks public views and routines for `product_code`. It then drops `tickets.product_code` without `CASCADE`, runs the ID-only writer and reader, and rolls the transaction back. `products.code` is not removed; it is still useful as a catalogue/business code.

I would keep `tickets.product_code` for a short period after old writers are stopped. While it is still populated, going back to the old application is possible before `product_id` becomes required. After `product_id` is required, an old writer cannot be restored without changing the schema again. After the old column is dropped, a rollback to the old application would require restoring the column and rebuilding its values from `product_id` first.

A UUID default only controls new rows. It does not make an existing product ID immutable. The application should never expose an ID update, and the production database role can be limited to updating business columns such as code, name and price rather than `products.id`.

## Compatibility check

| Stage | Old writer | Old reader | Dual writer | Fallback reader | ID-only writer | ID-only reader |
| --- | --- | --- | --- | --- | --- | --- |
| Before expansion | works | works | no `product_id` column | no `product_id` column | no `product_id` column | no `product_id` column |
| After expansion | works | works | works | works | fails because `product_code` is required | runs but misses tickets that still have null `product_id` |
| ID required | fails | works | works | works | fails while `product_code` is still required | works |
| Old column removed | fails | fails | fails | fails | works | works |

## Migration-tool check

This repository does not use EF Core, so there is no project-generated migration SQL to inspect. A model diff can work out the new UUID columns, keys and the final removal of `tickets.product_code`. It cannot infer the safe rollout order from the final model alone: the dual-write period, matching old rows by product code, preserving the ticket price, waiting for old writers to stop, and deciding when the old column may be removed all depend on the existing data and running application versions.

## Automated check

The GitHub Actions job runs the same sequence against PostgreSQL 17. It checks the expected unsafe-drop failure, the repeatable backfill, the blocked `NOT NULL` change while a null reference exists, the old-writer failure after the ID becomes required, the 65 DKK historical DAY price, and the reversible old-column drop rehearsal.
