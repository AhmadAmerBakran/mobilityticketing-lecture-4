# Lecture 4 notes

## Goal

The ticket originally identifies its product with `product_code`. The migration introduces a stable UUID in `products.id` and moves tickets toward `product_id` without breaking old readers and writers immediately.

Historical ticket price is kept on the ticket. Product identity and price are treated as different concerns.

## Migration sequence

The first migration, `030_expand_product_identity.sql`, adds a UUID to products, fills existing products, gives new products a UUID default, adds nullable `tickets.product_id` and creates the new foreign key as `NOT VALID`. Nothing removes `product_code` at this point, so the old contract still exists.

The backfill in `031_backfill_ticket_product.sql` only fills rows where `product_id` is null. It matches the old `product_code` to the product row and copies the UUID. Running it again is safe because already migrated tickets are left alone.

Before the new identity becomes required, `verify.sql` checks three things: no ticket has an unresolved product, the UUID and code do not disagree, and the original ticket product, price and currency values have not changed.

The final migration in this sequence, `032_require_ticket_product.sql`, validates the new foreign key and makes `product_id` required. This migration is intentionally blocked while an old writer can still create rows with a null `product_id`.

## Compatibility during the overlap

Before expansion, only the old reader and old writer work.

After expansion, the old reader and writer still work. The dual writer stores both references, and the fallback reader can resolve either the new UUID or the old code. An ID only writer is not ready yet because `product_code` is still required.

After `product_id` becomes required, the old writer fails because it does not supply the UUID. The old reader can still work because the code column remains for a short compatibility period.

After `product_code` is removed from tickets, only the ID based reader and writer remain valid.

The scripts that demonstrate these states are in `database/postgres/experiments/lecture04`.

## Late old writer

The test sequence deliberately inserts a ticket with the old writer after the first backfill. Running the backfill again fills only that late row. This is the important overlap case because it proves that one successful backfill is not enough while old writers are still active.

## Ticket price evidence

`TICKET-3` is a DAY ticket bought for 65 DKK while the current DAY catalogue price is 80 DKK. The migration keeps the ticket at 65 DKK. The UUID migration changes product identity only and never recalculates the amount that was agreed when the ticket was sold.

## Mismatch check

During the overlap, the database has separate foreign keys for `product_code` and `product_id`. Both references can individually point to valid products while describing different products. `mismatch_test.sql` proves that case, and `verify.sql` is the check used before making the UUID mandatory and before removing the old reference.

The new writer reduces this risk by taking the UUID as input and reading the matching product code from the product row instead of trusting a caller supplied code.

## Before removing the old column

`remove_legacy.sql` checks public views and routines for references to `product_code`. It then rehearses the drop without `CASCADE`, runs the ID only writer and reader, and rolls the transaction back.

In a real rollout I would only remove the old column after old writers are stopped, the final backfill has run, verification returns no problem rows, the new foreign key is validated, and the application versions that still depend on `tickets.product_code` are gone.
