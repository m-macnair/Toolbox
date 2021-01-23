--Databases size - data 

SELECT NOW(); 
SELECT 
	table_schema "DB", 
	ROUND(SUM(data_length ) / 1024 / 1024, 1) "MB" 
FROM information_schema.tables 
GROUP BY table_schema;

--Databases size - data & index
SELECT NOW(); 
SELECT 
	table_schema 
	"DB Name", 
	ROUND(SUM(data_length + index_length ) / 1024 / 1024, 1) "MB" 
FROM information_schema.tables 
GROUP BY table_schema; 


--Tables size - data 
SELECT table_name AS "Tbl",
ROUND(((data_length ) / 1024 / 1024), 2) AS "MB"
FROM information_schema.TABLES
WHERE table_schema = "<>"
ORDER BY (data_length ) DESC;

--Tables size - data & index
SELECT table_name AS "Tbl",
ROUND(((data_length + index_length) / 1024 / 1024), 2) AS "MB"
FROM information_schema.TABLES
WHERE table_schema = "<>"
ORDER BY (data_length + index_length) DESC;


-- show process list but better
select * from INFORMATION_SCHEMA.PROCESSLIST 
order by TIME desc
limit 50;