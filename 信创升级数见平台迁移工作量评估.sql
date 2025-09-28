

-- 明细宽表
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

-- 汇总宽表

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
    SELECT DISTINCT TableName FROM mdc_SumTableCalcRules WHERE ISNULL(TableName, '') <> '';

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

-- 业务系统报表迁移清单

-- 租赁系统
-- 修复递归全路径分组名称不全问题，需从根节点递归到叶子节点，路径拼接顺序应为“根 > ... > 当前”
WITH GroupCTE AS (
    SELECT 
        grpguid, 
        CAST(grpcname AS nvarchar(MAX)) AS grpcname, 
        parentid
    FROM 
        rptgroup
    WHERE 
        linkproduct = '0201' 
        AND (parentid IS NULL OR parentid = '')
    UNION ALL
    SELECT 
        g.grpguid, 
        CAST(cte.grpcname + N' > ' + g.grpcname AS nvarchar(MAX)) AS grpcname, 
        g.parentid
    FROM 
        rptgroup g
        INNER JOIN GroupCTE cte ON g.parentid = cte.grpguid
    WHERE 
        g.linkproduct = '0201'
)
SELECT 
    cte.grpcname AS 全路径分组名称,
   -- a.id , 
    a.rptid as 报表名称,
    a.rptcname as 报表中文名,
    rptename as 报表英文名,
    rpt.exptNum AS 导数次数
FROM 
    rptdetail a
    INNER JOIN (
        -- 取每个分组的全路径（最长路径），即分组名最长的那条
        SELECT 
            grpguid, 
            grpcname
        FROM (
            SELECT 
                grpguid, 
                grpcname,
                ROW_NUMBER() OVER (PARTITION BY grpguid ORDER BY LEN(grpcname) DESC) AS rn
            FROM 
                GroupCTE
        ) t
        WHERE 
            rn = 1
    ) cte ON a.grpguid = cte.grpguid
    LEFT JOIN (
        SELECT  
            RptID,
            COUNT(1) AS exptNum 
        FROM  
            [dbo].[rptOperLog] 
        WHERE 
            ExecState = '成功' 
            AND DATEDIFF(YEAR, BeginExecDate, GETDATE()) = 0
        GROUP BY  
            RptID
    ) rpt ON a.rptid = rpt.rptid
order  by  cte.grpcname  




-- Dss系统报表工作量评估
-- 修复递归全路径分组名称不全问题，需从根节点递归到叶子节点，路径拼接顺序应为“根 > ... > 当前”
WITH GroupCTE AS (
    SELECT 
        grpguid, 
        CAST(grpcname AS nvarchar(MAX)) AS grpcname, 
        parentid
    FROM 
        rptgroup
    WHERE 
        linkproduct  in ( '0501','0303') 
        AND (parentid IS NULL OR parentid = '')
    UNION ALL
    SELECT 
        g.grpguid, 
        CAST(cte.grpcname + N' > ' + g.grpcname AS nvarchar(MAX)) AS grpcname, 
        g.parentid
    FROM 
        rptgroup g
        INNER JOIN GroupCTE cte ON g.parentid = cte.grpguid
    WHERE 
        g.linkproduct  in ( '0501','0303') 
)
SELECT 
    cte.grpcname AS 全路径分组名称,
   -- a.id , 
    a.rptid as 报表名称,
    a.rptcname as 报表中文名,
    rptename as 报表英文名,
    rpt.exptNum AS 导数次数
FROM 
    rptdetail a
    INNER JOIN (
        -- 取每个分组的全路径（最长路径），即分组名最长的那条
        SELECT 
            grpguid, 
            grpcname
        FROM (
            SELECT 
                grpguid, 
                grpcname,
                ROW_NUMBER() OVER (PARTITION BY grpguid ORDER BY LEN(grpcname) DESC) AS rn
            FROM 
                GroupCTE
        ) t
        WHERE 
            rn = 1
    ) cte ON a.grpguid = cte.grpguid
    LEFT JOIN (
        SELECT  
            RptID,
            COUNT(1) AS exptNum 
        FROM  
            [dbo].[rptOperLog] 
        WHERE 
            ExecState = '成功' 
            AND DATEDIFF(YEAR, BeginExecDate, GETDATE()) = 0
        GROUP BY  
            RptID
    ) rpt ON a.rptid = rpt.rptid
order  by  cte.grpcname  