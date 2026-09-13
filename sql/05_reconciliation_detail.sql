WITH RECURSIVE campaign_tree AS (

    SELECT
        id AS campaign_id,
        id AS root_id
    FROM campaign
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.id AS campaign_id,
        ct.root_id
    FROM campaign c
    JOIN campaign_tree ct
        ON c.parent_id = ct.campaign_id
),

eligible_logs AS (

    SELECT
        cl.id,
        cl.customer_id,
        cl.communication_id,
        ct.root_id
    FROM communication_log cl
    JOIN campaign c
        ON c.id = cl.communication_id
    JOIN campaign_tree ct
        ON ct.campaign_id = cl.communication_id
    WHERE cl.merchant_id = 501
      AND cl.communication_type = '2'
      AND c.creation_status IN (
          'approved',
          'aborted',
          'resumed',
          'stopped'
      )
      AND c.processing_status = 'processed'
),

family_flags AS (

    SELECT
        ct.root_id,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM campaign child
                WHERE child.parent_id = ct.root_id
            )
            THEN 1
            ELSE 0
        END AS has_retry_chain
    FROM campaign_tree ct
    GROUP BY ct.root_id
)

SELECT
    el.root_id,
    CASE
        WHEN ff.has_retry_chain = 1
            THEN 'retry_family'
        ELSE 'standalone'
    END AS campaign_type,
    COUNT(*) AS raw_attempts,
    COUNT(DISTINCT el.customer_id) AS distinct_customers,
    CASE
        WHEN ff.has_retry_chain = 1
            THEN COUNT(DISTINCT el.customer_id)
        ELSE COUNT(*)
    END AS qualifying_sends
FROM eligible_logs el
JOIN family_flags ff
    ON ff.root_id = el.root_id
GROUP BY
    el.root_id,
    ff.has_retry_chain
ORDER BY el.root_id;