USE [HighData_prod]
GO

/*
  业态签约利润对比表索引维护脚本
  
  此脚本用于定期维护业态签约利润对比表的索引，确保查询性能持续优化
  建议每周执行一次或在大批量数据更新后执行
*/

-- 变量声明
DECLARE @TableName NVARCHAR(255) = N'业态签约利润对比表'
DECLARE @SchemaName NVARCHAR(255) = N'dbo'
DECLARE @SQL NVARCHAR(MAX)
DECLARE @IndexName NVARCHAR(255)
DECLARE @ObjectID INT
DECLARE @IndexID INT
DECLARE @Fragmentation FLOAT

-- 获取表的对象ID
SELECT @ObjectID = OBJECT_ID(@SchemaName + '.' + @TableName)

-- 如果表不存在，则退出
IF @ObjectID IS NULL
BEGIN
    PRINT '表 ' + @SchemaName + '.' + @TableName + ' 不存在'
    RETURN
END

-- 创建临时表存储索引碎片信息
IF OBJECT_ID('tempdb..#IndexFragmentation') IS NOT NULL
    DROP TABLE #IndexFragmentation

CREATE TABLE #IndexFragmentation
(
    ObjectID INT,
    IndexID INT,
    IndexName NVARCHAR(255),
    Fragmentation FLOAT
)

-- 获取索引碎片信息
INSERT INTO #IndexFragmentation (ObjectID, IndexID, IndexName, Fragmentation)
SELECT 
    s.object_id,
    s.index_id,
    i.name,
    s.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), @ObjectID, NULL, NULL, 'LIMITED') s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.index_id > 0 -- 排除堆表

-- 输出索引碎片信息
PRINT '===== 索引碎片分析结果 ====='
SELECT 
    IndexName,
    Fragmentation AS 碎片率_百分比
FROM #IndexFragmentation
ORDER BY Fragmentation DESC

-- 处理索引碎片
PRINT '===== 开始索引维护 ====='

-- 声明游标遍历索引
DECLARE IndexCursor CURSOR FOR
SELECT IndexName, IndexID, Fragmentation
FROM #IndexFragmentation
ORDER BY Fragmentation DESC

OPEN IndexCursor
FETCH NEXT FROM IndexCursor INTO @IndexName, @IndexID, @Fragmentation

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 根据碎片率决定重建还是重组索引
    IF @Fragmentation > 30.0
    BEGIN
        PRINT '重建索引: ' + @IndexName + ' (碎片率: ' + CAST(@Fragmentation AS NVARCHAR(10)) + '%)'
        SET @SQL = 'ALTER INDEX ' + @IndexName + ' ON ' + @SchemaName + '.' + @TableName + ' REBUILD WITH (ONLINE = OFF)'
        EXEC sp_executesql @SQL
    END
    ELSE IF @Fragmentation >= 5.0
    BEGIN
        PRINT '重组索引: ' + @IndexName + ' (碎片率: ' + CAST(@Fragmentation AS NVARCHAR(10)) + '%)'
        SET @SQL = 'ALTER INDEX ' + @IndexName + ' ON ' + @SchemaName + '.' + @TableName + ' REORGANIZE'
        EXEC sp_executesql @SQL
    END
    ELSE
    BEGIN
        PRINT '索引 ' + @IndexName + ' 无需维护 (碎片率: ' + CAST(@Fragmentation AS NVARCHAR(10)) + '%)'
    END
    
    FETCH NEXT FROM IndexCursor INTO @IndexName, @IndexID, @Fragmentation
END

CLOSE IndexCursor
DEALLOCATE IndexCursor

-- 更新统计信息
PRINT '===== 更新统计信息 ====='
SET @SQL = 'UPDATE STATISTICS ' + @SchemaName + '.' + @TableName + ' WITH FULLSCAN'
EXEC sp_executesql @SQL
PRINT '统计信息更新完成'

-- 检查未使用的索引
PRINT '===== 未使用索引检查 ====='
SELECT 
    i.name AS 索引名称,
    OBJECT_NAME(i.object_id) AS 表名,
    i.type_desc AS 索引类型,
    'ALTER INDEX ' + i.name + ' ON ' + @SchemaName + '.' + @TableName + ' DISABLE' AS 禁用索引脚本,
    'DROP INDEX ' + i.name + ' ON ' + @SchemaName + '.' + @TableName AS 删除索引脚本
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id AND s.database_id = DB_ID()
WHERE OBJECT_NAME(i.object_id) = @TableName
    AND i.is_primary_key = 0  -- 不是主键
    AND i.is_unique = 0       -- 不是唯一索引
    AND i.type_desc <> 'HEAP' -- 不是堆
    AND (s.user_seeks IS NULL AND s.user_scans IS NULL AND s.user_lookups IS NULL)
ORDER BY i.name

-- 清理临时表
DROP TABLE #IndexFragmentation

PRINT '===== 索引维护完成 =====' 