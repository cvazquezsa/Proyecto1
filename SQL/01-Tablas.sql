EXEC spAlter_Table 'Prod','KrbMaquila', 'bit NULL DEFAULT 0'
EXEC spAlter_Table 'Prod','KrbMaquilaProv', 'varchar(20) NULL'
EXEC spAlter_Table 'Prod','KrbCondicion', 'varchar(20) NULL'
GO

--SELECT * FROM PROD