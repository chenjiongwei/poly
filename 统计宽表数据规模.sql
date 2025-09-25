-- 创建结果表
IF OBJECT_ID('tempdb..#ResultTable') IS NOT NULL DROP TABLE #ResultTable;
CREATE TABLE #ResultTable (
    TableName NVARCHAR(255),
    TableRowNum INT
);

-- 遍历mdc_calcrules中的TableName，统计每个表的记录数并插入结果表
DECLARE @TableName NVARCHAR(255);
DECLARE @SQL NVARCHAR(MAX);

DECLARE cur CURSOR FOR
    SELECT DISTINCT TableName FROM mdc_calcrules WHERE ISNULL(TableName, '') <> '';

OPEN cur;
FETCH NEXT FROM cur INTO @TableName;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'INSERT INTO #ResultTable(TableName, TableRowNum) SELECT N''' + @TableName + ''', COUNT(*) FROM ' + QUOTENAME(@TableName) + ';';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM cur INTO @TableName;
END
CLOSE cur;
DEALLOCATE cur;

-- 查询结果
SELECT * FROM #ResultTable;