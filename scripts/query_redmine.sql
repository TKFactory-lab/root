-- query_redmine.sql
SELECT 'USERS' as section;
SELECT id, login, mail FROM users WHERE login IN ('nobu','hide','yasu');
SELECT 'WATCHERS_issue_13' as section;
SELECT w.id, w.watchable_type, w.watchable_id, w.user_id, u.login FROM watchers w LEFT JOIN users u ON w.user_id = u.id WHERE w.watchable_type='Issue' AND w.watchable_id=13;
