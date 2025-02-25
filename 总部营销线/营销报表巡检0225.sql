-- 营销线报表巡检
-- 统计报表的查看导出频次

-- 使用CTE递归查询获取报表组层级结构
WITH GroupPath AS (
    -- 基础查询:获取没有父级的报表组
    SELECT 
        grpguid,        -- 报表组ID
        grpcname,       -- 报表组中文名称
        parentid,       -- 父级ID
        CAST(grpcname AS VARCHAR(1000)) AS full_path  -- 完整路径
    FROM rptgroup
    WHERE parentid IS NULL
    
    UNION ALL
    
    -- 递归查询:获取子报表组并拼接名称路径
    SELECT 
        g.grpguid,
        g.grpcname,
        g.parentid,
        CAST(p.full_path + '-' + g.grpcname AS VARCHAR(1000))
    FROM rptgroup g
    INNER JOIN GroupPath p ON g.parentid = p.grpguid
)
-- 查询报表详细信息及其使用情况
SELECT 
    a.rptid as 报表ID,           -- 报表ID
    a.rptename as 报表英文名称,        -- 报表英文名称
    a.rptcname as 报表中文名称,        -- 报表中文名称
    a.lastdate as 最后更新日期,        -- 最后更新日期
    gp.full_path AS 报表组层级路径,  -- 报表组层级路径
    lg.viewnum as 报表查看次数         -- 报表查看次数
FROM rptdetail a
LEFT JOIN (
    -- 统计近三年报表查看次数
    SELECT 
        RptID,
        COUNT(1) AS viewnum
    FROM rptOperLog
    WHERE DATEDIFF(YEAR, BeginExecDate, GETDATE()) IN (0,1,2)
    GROUP BY RptID
) lg ON lg.RptID = a.rptid
INNER JOIN GroupPath gp ON a.grpguid = gp.grpguid 
WHERE gp.full_path LIKE 'ERP-销售管理%'  -- 仅查询销售管理相关报表