# Lecture 3 notes

## Reporting question

The report is daily captured revenue per operator. The same result was implemented four ways: a direct query, a SQL function, a materialized view and a trigger maintained summary.

`payments` is treated as the authority. The direct query is the reference calculation because it always reads the current source rows.

## What the experiment shows

The direct query and the SQL function stay current because both calculate from the base tables when they run.

The materialized view is correct only at its last refresh. After a new captured payment is inserted, the direct query and function move from 36 DKK to 72 DKK for OP METRO while the materialized view remains at 36 DKK until it is refreshed.

The trigger summary changes during the payment write, but the supplied trigger only handles inserts of captured payments. It does not backfill older rows, it does not add revenue when a payment changes from `Failed` to `Captured`, and it does not remove revenue when a captured payment becomes `Refunded` or is deleted.

The console output in `reporting_output.txt` records those differences. It also shows that rebuilding the trigger summary from `payments` and refreshing the materialized view brings the derived data back in line with the authority.

## Responsibility decision

For this daily report I would keep `payments` as the authority and use `daily_captured_revenue` as the read model. The materialized view gives cheap report reads without adding hidden work to every payment write. Its main cost is freshness, but that is explicit and operationally manageable because the view can be refreshed after payment reconciliation or just before the report is produced.

The direct query stays as the reference definition used to verify the materialized result. The SQL function is useful when a caller needs the same calculation for one operator and day, but it does not reduce the underlying aggregation work.

I would not make the trigger summary authoritative in its current form. Making it correct would require handling initial backfill, status transitions, deletes and duplicate delivery, which increases coupling and write path responsibility.

## Stale and incorrect examples

Immediately after a new captured payment, the materialized view is stale because it has not been refreshed. That is an expected freshness issue.

The trigger summary is a different kind of problem. It can be wrong even while updating immediately, because it only knows about events covered by its trigger logic. A later status correction can therefore leave a result that is fresh in time but incorrect in meaning.

## Recovery

The materialized result is recovered with `REFRESH MATERIALIZED VIEW daily_captured_revenue`.

The trigger summary can be rebuilt by truncating it and recalculating from the base payment rows. `rebuild_summary.sql` contains that recovery query.
