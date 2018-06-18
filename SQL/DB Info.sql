USE DB
SELECT	
	COLUMNS.TABLE_NAME AS 'Table',
	COLUMNS.COLUMN_NAME AS 'Column',
	CASE COLUMNS.DATA_TYPE
		WHEN 'numeric' THEN CONCAT(COLUMNS.DATA_TYPE, '(', COLUMNS.NUMERIC_PRECISION, ')')
		WHEN 'varchar' THEN CONCAT(COLUMNS.DATA_TYPE, '(', COLUMNS.CHARACTER_MAXIMUM_LENGTH, ')')
		ELSE COLUMNS.DATA_TYPE
	END AS 'Type',
	CASE WHEN COLUMNPROPERTY(OBJECT_ID(TABLES.TABLE_NAME), COLUMNS.COLUMN_NAME, 'isIdentity') = 1 THEN 'TRUE' ELSE 'FALSE' END AS 'Identity',
	SUBSTRING(COLUMNS.COLUMN_DEFAULT, 3, LEN(COLUMNS.COLUMN_DEFAULT) - 4) AS 'Default',
	CASE 
		WHEN UK.CONSTRAINT_NAME IS NULL AND PK.CONSTRAINT_NAME IS NULL THEN 'FALSE'
		ELSE 'TRUE'
	END AS 'Unique',
	CASE COLUMNS.IS_NULLABLE
		WHEN 'Yes' THEN 'TRUE'
		ELSE 'FALSE'
	END AS 'Nullable',
	ISNULL(FK_REF.TABLE_NAME + '.' + FK_REF.COLUMN_NAME, '') AS REF,
	ISNULL(PK.CONSTRAINT_NAME, '') AS 'Primary Key',
	ISNULL(FK.CONSTRAINT_NAME, '') AS 'Foreign Key',
	ISNULL(UK.CONSTRAINT_NAME, '') AS 'Unique Key',
	ISNULL(INDX.name, '') AS 'Index',
	COLUMNS.COLUMN_NAME + ' ' + UPPER(CASE COLUMNS.DATA_TYPE
		WHEN 'numeric' THEN CONCAT(COLUMNS.DATA_TYPE, '(', COLUMNS.NUMERIC_PRECISION, ')')
		WHEN 'varchar' THEN CONCAT(COLUMNS.DATA_TYPE, '(', COLUMNS.CHARACTER_MAXIMUM_LENGTH, ')')
		ELSE COLUMNS.DATA_TYPE
	END) + CASE COLUMNS.IS_NULLABLE
		WHEN 'Yes' THEN ' NULL'
		ELSE ''
	END AS 'Column Def',
	ISNULL(COLUMNS.TABLE_NAME + '.' + COLUMNS.COLUMN_NAME + ' = ' + FK_REF.TABLE_NAME + '.' + FK_REF.COLUMN_NAME, '') AS 'Association'
FROM INFORMATION_SCHEMA.COLUMNS
INNER JOIN INFORMATION_SCHEMA.TABLES
	ON COLUMNS.TABLE_NAME = TABLES.TABLE_NAME
		AND COLUMNS.table_schema = TABLES.table_schema
		AND TABLES.table_type = 'BASE TABLE'

-- PRIMARY_KEY
LEFT OUTER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS PK
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS PK_COLUMN_USAGE
		ON PK.CONSTRAINT_TYPE = 'PRIMARY KEY' AND
			PK.CONSTRAINT_NAME = PK_COLUMN_USAGE.CONSTRAINT_NAME
	ON PK_COLUMN_USAGE.TABLE_NAME = TABLES.TABLE_NAME
		AND PK_COLUMN_USAGE.COLUMN_NAME = COLUMNS.COLUMN_NAME

-- FOREIGN_KEY
LEFT OUTER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS FK
	INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS
		ON REFERENTIAL_CONSTRAINTS.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS FK_COLUMN_USAGE
		ON FK.CONSTRAINT_NAME = FK_COLUMN_USAGE.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS PK_REF
		ON REFERENTIAL_CONSTRAINTS.UNIQUE_CONSTRAINT_NAME = PK_REF.CONSTRAINT_NAME
	INNER JOIN (SELECT
			t.TABLE_NAME,
			c.COLUMN_NAME
		FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS t
			INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS c
				ON t.CONSTRAINT_NAME = c.CONSTRAINT_NAME
		WHERE t.CONSTRAINT_TYPE = 'PRIMARY KEY') AS FK_REF
	ON FK_REF.TABLE_NAME = PK_REF.TABLE_NAME

	ON FK_COLUMN_USAGE.TABLE_NAME = COLUMNS.TABLE_NAME
		AND FK_COLUMN_USAGE.COLUMN_NAME = COLUMNS.COLUMN_NAME

-- UNIQUE_KEY
LEFT OUTER JOIN	INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS UK
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS
		ON TABLE_CONSTRAINTS.CONSTRAINT_TYPE = 'UNIQUE'
			AND TABLE_CONSTRAINTS.CONSTRAINT_NAME = UK.CONSTRAINT_NAME
	ON UK.TABLE_NAME = COLUMNS.TABLE_NAME
		AND UK.COLUMN_NAME = COLUMNS.COLUMN_NAME
		AND UK.CONSTRAINT_NAME = TABLE_CONSTRAINTS.CONSTRAINT_NAME

-- INDEX
LEFT OUTER JOIN SYS.INDEXES AS INDX
	INNER JOIN SYS.INDEX_COLUMNS
		ON INDEX_COLUMNS.object_id = INDX.object_id
			AND INDEX_COLUMNS.index_id = INDX.index_id
	INNER JOIN SYS.ALL_COLUMNS
		ON ALL_COLUMNS.object_id = INDX.object_id
			AND ALL_COLUMNS.column_id = INDEX_COLUMNS.column_id
	INNER JOIN SYS.TYPES
		ON TYPES.system_type_id = ALL_COLUMNS.system_type_id
			AND TYPES.user_type_id = ALL_COLUMNS.user_type_id
	INNER JOIN SYS.TABLES AS INDX_Tables
		ON INDX_Tables.object_id = INDX.object_id
	ON INDX_Tables.name = COLUMNS.TABLE_NAME
		AND ALL_COLUMNS.name = COLUMNS.COLUMN_NAME
		AND (INDX.name != PK.CONSTRAINT_NAME OR PK.CONSTRAINT_NAME IS NULL)
		AND (INDX.name != UK.CONSTRAINT_NAME OR UK.CONSTRAINT_NAME IS NULL)
WHERE TABLES.TABLE_NAME != 'sysdiagrams'
	-- AND (COLUMNS.COLUMN_NAME = 'date_created' OR COLUMNS.COLUMN_NAME = 'last_updated')
--WHERE FK_REF.TABLE_NAME = 'jimi_status' 
ORDER BY COLUMNS.TABLE_NAME, COLUMNS.ordinal_position, FK_REF.TABLE_NAME, FK_REF.COLUMN_NAME, PK.CONSTRAINT_NAME, FK.CONSTRAINT_NAME, UK.CONSTRAINT_NAME, INDX.name
/*
SELECT 
      DATABASE_NAME = DB_NAME(DATABASE_ID),
	  LOG_SIZE_MB = CAST(SUM(CASE WHEN TYPE_DESC = 'LOG' THEN size END) * 8. / 1024 AS DECIMAL(8,2)),
	  ROW_SIZE_MB = CAST(SUM(CASE WHEN TYPE_DESC = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(8,2)),
	  TOTAL_SIZE_MB = CAST(SUM(size) * 8. / 1024 AS DECIMAL(8,2))
FROM sys.master_files WITH(NOWAIT)
WHERE DATABASE_ID = DB_ID() -- for current db 
GROUP BY DATABASE_ID

EXEC SP_SPACEUSED
*/