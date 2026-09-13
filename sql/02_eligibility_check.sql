SELECT COUNT(*) AS eligible_attempts
FROM communication_log cl
JOIN campaign c
    ON c.id = cl.communication_id
WHERE cl.merchant_id = 501
  AND cl.communication_type = '2'
  AND c.creation_status IN (
      'approved',
      'aborted',
      'resumed',
      'stopped'
  )
  AND c.processing_status = 'processed';