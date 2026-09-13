# Xeno Data Analyst Assignment
## Investigation Notes

## Step 0 — Naive Count

I started by counting all rows in communication_log.

Result: 30

Finance target_base: 22

Initial difference: 8.

---

## Step 1 — Campaign-level investigation

I grouped communication_log rows by campaign and inspected
campaign lifecycle statuses.

Campaign 9004 had 4 communication_log rows despite having
creation_status = approval_awaiting.

---

## Step 2 — Campaign Eligibility

The data dictionary defines eligible campaigns as those with
a finalized creation status and processing_status = processed.

Applying this filter removed the four rows from campaign 9004.

30 → 26

The result was still four higher than Finance's target.

---

## Step 3 — Retry Family Investigation

I inspected parent_id and found two retry families:

9001 → 9002 → 9003

and

9201 → 9202

The first family contained 13 attempts across 10 customers.

Therefore:

13 → 10

The second family contained 6 attempts across 5 customers.

Therefore:

6 → 5

These reductions occur because multiple attempts within a retry
chain represent the same underlying communication.

---

## Step 4 — Standalone Campaign Investigation

Campaign 9101 is standalone and contains 7 send events.

Customer C20 appears twice.

A global COUNT(DISTINCT customer_id) would incorrectly count
only 6 customers.

Because 9101 has no retry relationship, each send is a separate
qualifying event.

Therefore:

9101 → 7 qualifying sends.

---

## Final Reconciliation

Retry family 9001 → 9002 → 9003 = 10
Standalone campaign 9101             = 7
Retry family 9201 → 9202             = 5

10 + 7 + 5 = 22

Finance target_base = 22.

The reported number has been successfully reconciled.