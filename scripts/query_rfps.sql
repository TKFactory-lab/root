-- query_rfps.sql
SELECT p.identifier AS project, i.id AS issue_id, i.subject, s.name AS status
FROM issues i
JOIN projects p ON i.project_id = p.id
JOIN trackers t ON i.tracker_id = t.id
JOIN issue_statuses s ON i.status_id = s.id
WHERE p.identifier = 'crewai-rfps' AND t.name = 'RFP' AND s.name = 'Submitted' LIMIT 100;
