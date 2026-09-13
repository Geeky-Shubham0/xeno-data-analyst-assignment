SELECT
    c.id AS campaign_id,
    c.parent_id,
    c.name
FROM campaign c
WHERE c.merchant_id = 501
ORDER BY c.id;

-- Family 9001 → 9002 → 9003
SELECT
    COUNT(*) AS attempts,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM communication_log
WHERE communication_id IN (9001, 9002, 9003);

-- Family 9201 → 9202
SELECT
    COUNT(*) AS attempts,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM communication_log
WHERE communication_id IN (9201, 9202);

-- Standalone 9101
SELECT
    COUNT(*) AS send_events,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM communication_log
WHERE communication_id = 9101;
