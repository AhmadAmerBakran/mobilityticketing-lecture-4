# Lecture 2 notes

## Integrity map

The migration adds rules that PostgreSQL can enforce reliably without pretending that every business rule belongs in a row constraint.

### Trip rules

1. `capacity` is required and cannot be negative.
2. `reserved_seats` is required and must stay between zero and capacity.
3. Trip status is limited to `Scheduled`, `Cancelled` and `Completed`.

### Product and user rules

1. A product needs a name, non negative price and a three letter uppercase currency representation.
2. A user needs an email and a stored disabled state.
3. Email addresses are unique.

### Ticket rules

1. A ticket must point to an existing user, trip and product.
2. Ticket codes are unique.
3. The validity end cannot be before the validity start.
4. Ticket price cannot be negative.
5. Currency uses the same three letter uppercase representation.
6. Ticket status is limited to the states used by this lab.

### Payment rules

1. A payment must point to an existing user and ticket.
2. Amount cannot be negative.
3. A captured payment requires an external payment reference.
4. A non null external payment reference is unique.
5. Payment status is limited to the states used by this lab.

### Validation rules

1. The stored ticket id and ticket code must identify the same ticket.
2. Validation result must be `Accepted` or `Rejected`.
3. A recorded stop must exist.

## Two rules that are useful to demonstrate

The first is `trips_reserved_seats_valid`. A normal update that leaves reserved seats between zero and capacity succeeds. Setting `reserved_seats` above capacity is rejected with SQLSTATE `23514`.

The second is `validations_ticket_identity_fk`. A validation using the correct ticket id and ticket code succeeds. Mixing the id from one ticket with the code from another is rejected with SQLSTATE `23503`.

These examples are useful because one is a local row invariant and the other protects consistency across related rows.

## Boundary of the database rules

The database still does not guarantee that two concurrent purchases cannot oversell a trip. A row check only sees the final value presented by one transaction. The purchase workflow needs a transaction strategy that prevents two writers from both acting on the same remaining capacity.

The database also cannot make an external payment gateway operation atomic with the local commit. The unique external reference helps with duplicate persistence, but retries and idempotency still belong to the workflow design.

The meaning of `users.is_disabled` is also intentionally not enforced as a purchase rule because the case does not define whether disabling a user blocks only new purchases or also affects existing tickets.

## Test files

`valid_writes.sql` contains a valid user, ticket, payment and validation path inside a transaction that is rolled back at the end.

`rejected_writes.sql` contains the rejected cases. Each case records the expected SQLSTATE and the constraint or column responsible for the rejection so the result can be tied to a concrete database rule.
