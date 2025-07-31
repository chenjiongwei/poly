/*
营销看板营销业绩报表 - 性能优化脚本
此脚本包含针对原始查询的性能优化建议，主要包括索引创建和查询结构优化
使用前请先在测试环境验证，并根据实际情况调整
*/

-- =============================================
-- 第1部分: 索引优化
-- =============================================

-- 1.1 为s_hnyxxp_projSaleNew表创建索引（用于Sale CTE）
-- 说明: 这个索引覆盖了Sale CTE中的WHERE条件和GROUP BY字段
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_projSaleNew_Performance_1' AND object_id = OBJECT_ID('[s_hnyxxp_projSaleNew]'))
BEGIN
    PRINT '创建索引: IX_projSaleNew_Performance_1'
    CREATE NONCLUSTERED INDEX IX_projSaleNew_Performance_1 ON [s_hnyxxp_projSaleNew]
    (
        层级,
        层级名称,
        数据清洗日期,
        项目GUID
    )
    INCLUDE (
        投管编码,
        区域,
        营销片区,
        项目名称,
        项目负责人,
        存量增量,
        城市,
        业态,
        产品类型
    );
END

-- 1.2 为s_hnyxxp_projSaleNew表创建索引（用于szyx CTE）
-- 说明: 这个索引覆盖了szyx CTE中的WHERE条件和GROUP BY字段
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_projSaleNew_Performance_2' AND object_id = OBJECT_ID('[s_hnyxxp_projSaleNew]'))
BEGIN
    PRINT '创建索引: IX_projSaleNew_Performance_2'
    CREATE NONCLUSTERED INDEX IX_projSaleNew_Performance_2 ON [s_hnyxxp_projSaleNew]
    (
        层级,
        层级名称,
        数据清洗日期,
        项目GUID
    )
    INCLUDE (
        投管编码,
        区域,
        营销片区,
        项目名称,
        项目负责人,
        存量增量,
        城市,
        本日认购金额,
        本周认购金额,
        本周签约金额,
        本月认购金额,
        本月签约金额,
        本年认购金额,
        本年签约金额
    );
END

-- 1.3 为s_YHJVisitNum表创建索引（用于lf CTE）
-- 说明: 这个索引覆盖了lf CTE中的JOIN条件和聚合字段
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_YHJVisitNum_Performance' AND object_id = OBJECT_ID('[s_YHJVisitNum]'))
BEGIN
    PRINT '创建索引: IX_YHJVisitNum_Performance'
    CREATE NONCLUSTERED INDEX IX_YHJVisitNum_Performance ON [s_YHJVisitNum]
    (
        managementProjectGuid,
        bizdate
    )
    INCLUDE (
        newVisitNum,
        oldVisitNum
    );
END

-- 1.4 为data_wide_dws_mdm_Project表创建索引（用于lf CTE）
-- 说明: 这个索引覆盖了lf CTE中的JOIN条件和WHERE条件
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Project_Performance' AND object_id = OBJECT_ID('[data_wide_dws_mdm_Project]'))
BEGIN
    PRINT '创建索引: IX_Project_Performance'
    CREATE NONCLUSTERED INDEX IX_Project_Performance ON [data_wide_dws_mdm_Project]
    (
        BUGUID,
        ProjGUID
    );
END

-- =============================================
-- 第2部分: 优化日期比较
-- =============================================

-- 2.1 为s_hnyxxp_projSaleNew表添加计算列和索引（优化日期比较）
-- 说明: 这个计算列和索引可以优化DATEDIFF函数调用
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = '数据清洗日期_日' AND object_id = OBJECT_ID('[s_hnyxxp_projSaleNew]'))
BEGIN
    PRINT '添加计算列: 数据清洗日期_日'
    ALTER TABLE [s_hnyxxp_projSaleNew] ADD 数据清洗日期_日 AS CAST(数据清洗日期 AS DATE) PERSISTED;
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_数据清洗日期_日' AND object_id = OBJECT_ID('[s_hnyxxp_projSaleNew]'))
BEGIN
    PRINT '创建索引: IX_数据清洗日期_日'
    CREATE NONCLUSTERED INDEX IX_数据清洗日期_日 ON [s_hnyxxp_projSaleNew](数据清洗日期_日);
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = '数据清洗年月' AND object_id = OBJECT_ID('[s_hnyxxp_projSaleNew]'))
BEGIN
    PRINT '添加计算列: 数据清洗年月'
    ALTER TABLE [s_hnyxxp_projSaleNew] ADD 数据清洗年月 AS CAST(YEAR(数据清洗日期) * 100 + MONTH(数据清洗日期) AS INT) PERSISTED;
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_数据清洗年月' AND object_id = OBJECT_ID('[s_hnyxxp_projSaleNew]'))
BEGIN
    PRINT '创建索引: IX_数据清洗年月'
    CREATE NONCLUSTERED INDEX IX_数据清洗年月 ON [s_hnyxxp_projSaleNew](数据清洗年月);
END

-- 2.2 为s_YHJVisitNum表添加计算列和索引（优化日期比较）
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'bizdate_日' AND object_id = OBJECT_ID('[s_YHJVisitNum]'))
BEGIN
    PRINT '添加计算列: bizdate_日'
    ALTER TABLE [s_YHJVisitNum] ADD bizdate_日 AS CAST(bizdate AS DATE) PERSISTED;
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_bizdate_日' AND object_id = OBJECT_ID('[s_YHJVisitNum]'))
BEGIN
    PRINT '创建索引: IX_bizdate_日'
    CREATE NONCLUSTERED INDEX IX_bizdate_日 ON [s_YHJVisitNum](bizdate_日);
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'bizdate_年月' AND object_id = OBJECT_ID('[s_YHJVisitNum]'))
BEGIN
    PRINT '添加计算列: bizdate_年月'
    ALTER TABLE [s_YHJVisitNum] ADD bizdate_年月 AS CAST(YEAR(bizdate) * 100 + MONTH(bizdate) AS INT) PERSISTED;
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_bizdate_年月' AND object_id = OBJECT_ID('[s_YHJVisitNum]'))
BEGIN
    PRINT '创建索引: IX_bizdate_年月'
    CREATE NONCLUSTERED INDEX IX_bizdate_年月 ON [s_YHJVisitNum](bizdate_年月);
END

-- =============================================
-- 第3部分: 创建物化视图（预聚合数据）
-- =============================================

-- 3.1 创建物化视图预聚合Sale CTE数据
-- 说明: 这个视图预先计算了Sale CTE中的聚合数据，可以显著提高查询性能
IF NOT EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ProjSale_Aggregated')
BEGIN
    PRINT '创建物化视图: vw_ProjSale_Aggregated'
    EXEC('
    CREATE VIEW vw_ProjSale_Aggregated
    WITH SCHEMABINDING
    AS
    SELECT
        投管编码,
        区域,
        营销片区,
        项目GUID,
        项目名称,
        项目负责人,
        存量增量,
        城市,
        业态,
        产品类型,
        SUM(ISNULL(本年任务, 0)) AS 年度任务,
        SUM(CASE WHEN 业态 =''住宅'' THEN ISNULL(本年任务, 0) ELSE 0 END) AS 年度住宅类任务,
        SUM(CASE WHEN 业态 =''商办'' THEN ISNULL(本年任务, 0) ELSE 0 END) AS 年度商办任务,
        SUM(CASE WHEN 产品类型 IN (''写字楼'') THEN ISNULL(本年任务, 0) ELSE 0 END) AS 年度写字楼任务,
        SUM(CASE WHEN 产品类型 IN (''公寓'') THEN ISNULL(本年任务, 0) ELSE 0 END) AS 年度公寓任务,
        SUM(CASE WHEN 产品类型 IN (''商墅'') THEN ISNULL(本年任务, 0) ELSE 0 END) AS 年度商墅任务,
        SUM(CASE WHEN 产品类型 IN (''商铺'') THEN ISNULL(本年任务, 0) ELSE 0 END) AS 年度商铺任务,
        SUM(CASE WHEN 业态=''车位'' THEN ISNULL(本年任务, 0) ELSE 0 END) AS 年度车位任务,
        -- 其他聚合字段可以根据需要添加
        COUNT_BIG(*) AS row_count
    FROM dbo.[s_hnyxxp_projSaleNew]
    WHERE 层级 = ''项目'' AND 层级名称 = ''全部项目''
    GROUP BY
        投管编码,
        区域,
        营销片区,
        项目GUID,
        项目名称,
        项目负责人,
        存量增量,
        城市,
        业态,
        产品类型
    ');
END

-- 在视图上创建唯一聚集索引以实现物化
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_vw_ProjSale_Aggregated' AND object_id = OBJECT_ID('vw_ProjSale_Aggregated'))
BEGIN
    PRINT '在视图上创建唯一聚集索引: IX_vw_ProjSale_Aggregated'
    CREATE UNIQUE CLUSTERED INDEX IX_vw_ProjSale_Aggregated
    ON vw_ProjSale_Aggregated (项目GUID, 业态, 产品类型);
END

-- =============================================
-- 第4部分: 优化后的查询示例
-- =============================================

/*
-- 以下是优化后的查询示例，使用了计算列和索引来提高性能
-- 注意：这只是一个示例，实际使用时需要根据具体情况调整

DECLARE @var_date DATETIME = GETDATE();
DECLARE @var_projguid VARCHAR(50) = '9CEDEF9B-5D32-E811-80BA-E61F13C57837';
DECLARE @var_date_day DATE = CAST(@var_date AS DATE);
DECLARE @var_date_month INT = YEAR(@var_date) * 100 + MONTH(@var_date);

WITH Sale AS (
    SELECT    
        投管编码 AS 项目代码,
        区域 AS 公司事业部,
        营销片区 AS 组团,
        项目GUID,
        项目名称 AS 项目名称,
        项目负责人 AS 营销经理,
        存量增量 AS 项目获取状态,
        城市 AS 城市,
        -- 其他字段和聚合计算
    FROM [172.16.4.161].highdata_prod.dbo.[s_hnyxxp_projSaleNew] sale
    WHERE sale.层级 = '项目' 
      AND 层级名称 = '全部项目' 
      AND 数据清洗日期_日 = @var_date_day  -- 使用计算列代替DATEDIFF
      AND sale.项目GUID IN (@var_projguid)
    GROUP BY 
        投管编码,
        区域,
        营销片区,
        项目GUID,
        项目名称,
        项目负责人,
        存量增量,
        城市
),
lf AS (
    SELECT  
        p.ProjGUID AS 项目GUID, 
        SUM(CASE WHEN a.bizdate_日 = @var_date_day THEN ISNULL([newVisitNum], 0) + ISNULL([oldVisitNum], 0) ELSE 0 END) AS 本日来访,
        SUM(CASE WHEN a.bizdate_年月 = @var_date_month THEN ISNULL([newVisitNum], 0) + ISNULL([oldVisitNum], 0) ELSE 0 END) AS 本月到访
    FROM dbo.s_YHJVisitNum a
    INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project p ON a.[managementProjectGuid] = p.ProjGUID
    WHERE p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
      AND p.projguid IN (@var_projguid)
    GROUP BY p.ProjGUID
),
szyx AS (
    SELECT    
        投管编码 AS 项目代码,