-- query_journals_issue13.sql
SELECT j.id, j.journalized_type, j.journalized_id, j.user_id, j.notes, j.created_on
FROM journals j
WHERE j.journalized_type='Issue' AND j.journalized_id=13
ORDER BY j.created_on DESC
LIMIT 20;
