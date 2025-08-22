-- query_tokens.sql
SHOW TABLES LIKE '%token%';
SHOW TABLES LIKE '%api%';
SHOW TABLES LIKE '%personal%';

SELECT table_name FROM information_schema.tables WHERE table_schema='redmine_prod' AND (table_name LIKE '%token%' OR table_name LIKE '%api%' OR table_name LIKE '%personal%') LIMIT 100;

-- if a token-like table exists, try selecting some rows
SELECT 'CANDIDATE_TOKENS' as section;
SELECT * FROM api_tokens LIMIT 5;
SELECT * FROM tokens LIMIT 5;
SELECT * FROM personal_access_tokens LIMIT 5;
