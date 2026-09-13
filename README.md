# Xeno Data Analyst Assignment — Comm-Log Send Reconciliation

## 1. Objective

The objective of this analysis is to reproduce Finance's reported `target_base` of 22 for merchant 501's October 2026 Diwali campaigns.

The analysis starts from the raw `communication_log` data and reconciles the difference between a naive send-attempt count and the final reporting metric.

---

## 2. Dataset

The analysis uses the supplied SQLite database:

`data/comm_log.db`

The database contains two tables:

* `campaign`
* `communication_log`

### Important fields

From `campaign`:

* `id` — campaign identifier
* `parent_id` — identifies a retry relationship
* `creation_status` — campaign creation/approval state
* `processing_status` — send-processing state

From `communication_log`:

* `communication_id` — campaign associated with the send
* `customer_id` — customer targeted
* `delivery_status` — delivery result
* `sent_time` — send timestamp

---

## 3. Investigation Approach

I started with the most straightforward possible query:

```sql
SELECT COUNT(*)
FROM communication_log;
```

This produced:

**30 send attempts**

Finance's reported target was:

**22**

Therefore, there was an initial difference of:

**8**

I then investigated the data in stages.

---

## 4. Reconciliation Bridge

| Step      | Description                                     | Result | Reason                                                                                 |
| --------- | ----------------------------------------------- | -----: | -------------------------------------------------------------------------------------- |
| 0         | Naive count of `communication_log`              |     30 | Every row represents a raw send attempt                                                |
| 1         | Apply campaign eligibility                      |     26 | Campaign 9004 is `approval_awaiting`, so its 4 log rows are not eligible for reporting |
| 2         | Reconcile retry family `9001 → 9002 → 9003`     |     10 | 13 attempts represent 10 distinct customers within the same retry chain                |
| 3         | Reconcile retry family `9201 → 9202`            |      5 | 6 attempts represent 5 distinct customers within the same retry chain                  |
| 4         | Preserve standalone campaign `9101` send events |      7 | The campaign is standalone, so repeated sends are separate events                      |
| **Final** | **Finance's `target_base`**                     | **22** | **10 + 7 + 5 = 22**                                                                    |

---

## 5. Campaign Eligibility

A campaign is eligible when:

* `creation_status` is one of:

  * `approved`
  * `aborted`
  * `resumed`
  * `stopped`
* `processing_status = 'processed'`

Campaign `9004` has:

```text
creation_status = approval_awaiting
processing_status = processed
```

It has 4 communication-log rows.

Therefore, those 4 rows are excluded from the reporting calculation:

```text
30 → 26
```

---

## 6. Retry Chain Logic

The campaign hierarchy contains two retry families:

```text
9001
 └── 9002
      └── 9003

9201
 └── 9202
```

Within a retry family, multiple attempts against the same customer represent the same underlying communication.

Therefore, retry families are counted using distinct customers.

### Family 9001 → 9002 → 9003

```text
Raw attempts:       13
Distinct customers: 10
Qualifying sends:   10
```

### Family 9201 → 9202

```text
Raw attempts:       6
Distinct customers: 5
Qualifying sends:   5
```

---

## 7. Standalone Campaign

Campaign `9101` is standalone and has no retry relationship.

It contains 7 send events.

Customer `C20` appears twice, but these are separate send events:

```text
C20 → 2026-10-10

C20 → 2026-10-20
```

Therefore, using `COUNT(DISTINCT customer_id)` for the standalone campaign would incorrectly reduce the count from 7 to 6.

The standalone campaign contributes:

```text
7 qualifying sends
```

---

## 8. Final Calculation

The final target is:

```text
Retry family 9001 → 9002 → 9003 = 10

Standalone campaign 9101          = 7

Retry family 9201 → 9202          = 5

10 + 7 + 5 = 22
```

Therefore:

**Finance's `target_base = 22` is reconciled.**

---

## 9. SQL

The final reconciliation query is available in:

`sql/04_final_reconciliation.sql`

A detailed breakdown is available in:

`sql/05_reconciliation_detail.sql`

The earlier investigation queries are also included:

* `sql/01_naive_count.sql`
* `sql/02_eligibility_check.sql`
* `sql/03_retry_family_analysis.sql`

---

## 10. Findings / Surprises

The most surprising finding was that campaign 9004 already had communication-log rows even though its creation status was still `approval_awaiting`. This means that simply counting raw communication-log rows would include sends that are not yet eligible for reporting.

Another important finding was that customer deduplication cannot be applied globally. Repeated customers within retry chains should be counted once, while repeated sends within the standalone campaign 9101 are legitimate separate events.

This distinction was necessary to reconcile the raw data to Finance's reported target of 22.
