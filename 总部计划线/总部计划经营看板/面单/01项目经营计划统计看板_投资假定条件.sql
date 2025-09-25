-- 01 投资假定条件偏差 
-- 测试数据：龙川臻悦 18409189-6E34-EF11-B3A4-F40270D39969 
-- 存储过程：usp_zb_jyjhtjkb_PositDiff
-- 主要功能：每日汇总并插入投资假定条件偏差相关数据，避免重复插入，并可校验当日数据
create or ALTER     proc [dbo].[usp_zb_jyjhtjkb_PositDiff]
as
begin

    -- --------------------------------------------------------------------
    -- 1. 判断表是否存在，存在则不创建（实际部署时建议启用）
    -- --------------------------------------------------------------------
    -- IF OBJECT_ID('zb_jyjhtjkb_PositDiff', 'U') IS NULL
    -- BEGIN
    --    CREATE TABLE zb_jyjhtjkb_PositDiff (
    --        [buguid] UNIQUEIDENTIFIER,                -- 组织GUID
    --        [projguid] UNIQUEIDENTIFIER,              -- 项目GUID
    --        [清洗日期] DATETIME,                       -- 清洗日期
    --        -- 1.1 开盘时间
    --        [开盘时间_动态版] DATETIME,                -- 动态版开盘时间
    --        [开盘时间_立项版] DATETIME,                -- 立项版开盘时间
    --        [开盘时长_动态版] DECIMAL(32, 10),
    --        [开盘时长_立项版] DECIMAL(32, 10),
    --        -- 1.2 首开去化
    --        [首开去化套数_动态版] INT,                -- 动态版首开去化套数
    --        [首开去化套数_立项版] INT,                -- 立项版首开去化套数
    --        -- 1.3 续销流速
    --        [续销流速累计套数_立项版] INT,            -- 立项版续销流速累计套数
    --        [续销流速累计本月套数_立项版] INT,        -- 立项版续销流速累计本月套数
    --        [续销流速累计本月金额_立项版] DECIMAL(32, 10), -- 立项版续销流速累计本月金额
    --        [续销流速截止本月累计套数] INT,           -- 截止本月续销流速累计套数
    --        [续销流速截止本月累计金额] DECIMAL(32, 10), -- 截止本月续销流速累计金额
    --        [续销流速截止上月累计套数] INT,           -- 截止上月续销流速累计套数
    --        [续销流速截止上月累计金额] DECIMAL(32, 10)  -- 截止上月续销流速累计金额
    --    );
    -- END
    -- 定义变量参数
    DECLARE  @lastMonth datetime = dateadd(ms,-3,DATEADD(mm, DATEDIFF(mm,0,getdate()), 0))   -- 上月最后一天
    DECLARE  @thisMonth datetime = dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,getdate())+1, 0))    -- 本月最后一天

    -- 获取项目首推时间
    SELECT 
        t.projguid, 
        MIN(SJkpxsDate) AS SJkpxsDate 
    INTO #stDate
    FROM (
        -- 获取房间认购的时间
        SELECT 
            parentprojguid AS projguid, 
            MIN(qsdate) AS SJkpxsDate
        FROM data_wide_s_SaleHsData sd
        GROUP BY parentprojguid

        -- 获取特殊业绩计算货量的录入时间
        UNION ALL 
        SELECT 
            ParentProjGUID AS projguid,
            MIN(StatisticalDate) AS SJkpxsDate
        FROM data_wide_s_SpecialPerformance
        WHERE TsyjType IN (
            SELECT TsyjTypeName 
            FROM [172.16.4.141].erp25.dbo.s_TsyjType t 
            WHERE IsCalcYSHL = 1
        )
        GROUP BY ParentProjGUID

        -- 合作业绩录入不为0
        UNION ALL 
        SELECT 
            ParentProjGUID AS projguid,
            MIN(StatisticalDate) AS SJkpxsDate
        FROM data_wide_s_NoControl
        WHERE CCjTotal > 0
        GROUP BY ParentProjGUID
    ) t
    INNER JOIN data_wide_dws_mdm_project pj 
        ON t.projguid = pj.projguid 
    GROUP BY t.projguid


    -- 首开去化动态版
    SELECT 
        Sale.ParentProjGUID AS projguid,           
        SUM(
            CASE 
                WHEN DATEDIFF(DAY, sk.SJkpxsDate, Sale.StatisticalDate) <= 30 
                    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) 
                ELSE 0  
            END
        ) / 100000000.0 AS 首开去化签约金额, -- 亿元
        SUM(
            CASE 
                WHEN DATEDIFF(DAY, sk.SJkpxsDate, Sale.StatisticalDate) <= 30 
                    THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)  
                ELSE 0 
            END
        ) / 10000.0 AS 首开去化签约面积, -- 万㎡
        SUM(
            CASE 
                WHEN DATEDIFF(DAY, sk.SJkpxsDate, Sale.StatisticalDate) <= 30 
                    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) 
                ELSE 0  
            END
        ) AS 首开去化签约套数, -- 套数
        -- 截止上月的签约金额
         SUM(
            CASE 
                WHEN DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth ) >=0
                    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) 
                ELSE 0  
            END
        ) / 100000000.0 AS 截止上月的累计签约金额, -- 亿元 
       SUM(
            CASE 
                WHEN DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth ) >=0
                    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) 
                ELSE 0  
            END
        ) AS 截止上月的累计签约套数, -- 套数        
        -- 截止本月的签约金额
        SUM(
            CASE 
                WHEN DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0 
                    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) 
                ELSE 0  
            END
        ) / 100000000.0 AS 截止本月的累计签约金额, -- 亿元
        SUM(
            CASE 
                WHEN DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0 
                    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) 
                ELSE 0  
            END
        ) AS 截止本月的累计签约套数 -- 套数    
    into #sale
    FROM data_wide_dws_s_SalesPerf Sale
    INNER JOIN #stDate sk 
        ON Sale.ParentProjGUID = sk.projguid
    GROUP BY Sale.ParentProjGUID

    -- 填报数据
    SELECT 
        jytb.项目GUID,
        jytb.首开去化套数_立项版,
        jytb.续销流速累计套数_立项版,
        jytb.续销流速累计本月套数_立项版,
        jytb.续销流速累计本月金额_立项版
    INTO #JyjhtjkbTb
    FROM data_wide_dws_qt_Jyjhtjkb jytb
    WHERE jytb.FillHistoryGUID IN (
        SELECT TOP 1 FillHistoryGUID
        FROM data_wide_dws_qt_Jyjhtjkb
        ORDER BY FillDate DESC
    )


    ----------------------------------------------------------------------
    -- 2. 删除当天已存在的数据，避免重复插入
    --    说明：以“清洗日期”为当天，防止重复插入同一天的数据
    ----------------------------------------------------------------------
    DELETE FROM zb_jyjhtjkb_PositDiff
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;
   
    ----------------------------------------------------------------------
    -- 3. 汇总各项数据，插入投资假定条件表
    --    说明：此处为结构示例，实际业务数据需补充汇总逻辑
    --    目前所有业务字段均为NULL，仅做结构占位
    ----------------------------------------------------------------------
    INSERT INTO zb_jyjhtjkb_PositDiff (
        [buguid],                          -- 组织GUID
        [projguid],                        -- 项目GUID
        [清洗日期],                        -- 清洗日期
        [开盘时间_动态版],                  -- 动态版开盘时间
        [开盘时间_立项版],                  -- 立项版开盘时间
        [开盘时长_动态版],                  -- 动态版开盘时长
        [开盘时长_立项版],                  -- 立项版开盘时长
        [首开去化套数_动态版],              -- 动态版首开去化套数
        [首开去化套数_立项版],              -- 立项版首开去化套数
        [续销流速累计套数_立项版],          -- 立项版续销流速累计套数
        [续销流速累计本月套数_立项版],      -- 立项版续销流速累计本月套数
        [续销流速累计本月金额_立项版],      -- 立项版续销流速累计本月金额
        [续销流速截止本月累计套数],         -- 截止本月续销流速累计套数
        [续销流速截止本月累计金额],         -- 截止本月续销流速累计金额
        [续销流速截止上月累计套数],         -- 截止上月续销流速累计套数
        [续销流速截止上月累计金额]          -- 截止上月续销流速累计金额
    )
    SELECT
        pj.buguid                                       AS [buguid],                        -- 事业部GUID
        pj.projguid                                     AS [projguid],                      -- 项目GUID
        GETDATE()                                       AS [清洗日期],                      -- 当前清洗日期
        sk.SJkpxsDate                               AS [开盘时间_动态版],                -- 动态版开盘时间
        t.FirstOpenDate                                AS [开盘时间_立项版],                -- 立项版开盘时间
        DATEDIFF(month, pj.BeginDate, sk.SJkpxsDate)    AS [开盘时长_动态版],               -- 动态版开盘时长
        DATEDIFF(month, pj.BeginDate, t.FirstOpenDate)  AS [开盘时长_立项版],               -- 立项版开盘时长
        sale.首开去化签约套数                            AS [首开去化套数_动态版],            -- 动态版首开去化套数
        jb.首开去化套数_立项版                           AS [首开去化套数_立项版],            -- 立项版首开去化套数
        jb.续销流速累计套数_立项版                       AS [续销流速累计套数_立项版],        -- 立项版续销流速累计套数
        jb.续销流速累计本月套数_立项版                   AS [续销流速累计本月套数_立项版],    -- 立项版续销流速累计本月套数
        jb.续销流速累计本月金额_立项版                   AS [续销流速累计本月金额_立项版],    -- 立项版续销流速累计本月金额
        CASE 
            WHEN DATEDIFF(month, sk.SJkpxsDate, @thisMonth) - 1 = 0 THEN 0
            ELSE 
                (ISNULL(sale.截止本月的累计签约套数, 0) - ISNULL(sale.首开去化签约套数, 0)) 
                / (DATEDIFF(month, sk.SJkpxsDate, @thisMonth) - 1)
        END                                             AS [续销流速截止本月累计套数],        -- 【截止本月累计签约套数-首开套数】/【截止目前时间-开盘时间-1】

        sale.截止上月的累计签约金额                      AS [续销流速截止本月累计金额],        -- 截止本月续销流速累计金额
        CASE 
            WHEN DATEDIFF(month, sk.SJkpxsDate, @lastMonth) - 1 = 0 THEN 0
            ELSE 
                (ISNULL(sale.截止上月的累计签约套数, 0) - ISNULL(sale.首开去化签约套数, 0)) 
                / (DATEDIFF(month, sk.SJkpxsDate, @lastMonth) - 1)
        END                                             AS [续销流速截止上月累计套数],        -- 【截止上月累计签约套数-首开套数】/【截止目前时间-开盘时间-1】
        sale.截止本月的累计签约金额                      AS [续销流速截止上月累计金额]         -- 截止上月续销流速累计金额
    FROM 
        data_wide_dws_mdm_Project pj
        LEFT JOIN data_wide_dws_ys_SumOperatingProfitDataLXDWBfYt t 
            ON t.projguid = pj.projguid 
            AND EditonType = '立项版'
        LEFT JOIN #stDate sk  
            ON sk.projguid = pj.projguid
        LEFT JOIN #JyjhtjkbTb jb  
            ON jb.项目GUID = pj.projguid
        LEFT JOIN #sale sale 
            ON sale.projguid = pj.projguid
    WHERE 
        pj.level = 2                                   -- 只统计二级项目

    ----------------------------------------------------------------------
    -- 4. 查询当天插入的最终数据，便于校验
    --    说明：可用于数据校验和后续分析
    ----------------------------------------------------------------------
    SELECT
        [buguid],                                  -- 组织GUID
        [projguid],                                -- 项目GUID
        [清洗日期],                                -- 清洗日期
        [开盘时间_动态版],                          -- 动态版开盘时间
        [开盘时间_立项版],                          -- 立项版开盘时间
        [开盘时长_动态版],
        [开盘时长_立项版],      
        [首开去化套数_动态版],                      -- 动态版首开去化套数
        [首开去化套数_立项版],                      -- 立项版首开去化套数
        [续销流速累计套数_立项版],                  -- 立项版续销流速累计套数
        [续销流速累计本月套数_立项版],              -- 立项版续销流速累计本月套数
        [续销流速累计本月金额_立项版],              -- 立项版续销流速累计本月金额
        [续销流速截止本月累计套数],                 -- 截止本月续销流速累计套数
        [续销流速截止本月累计金额],                 -- 截止本月续销流速累计金额
        [续销流速截止上月累计套数],                 -- 截止上月续销流速累计套数
        [续销流速截止上月累计金额]                  -- 截止上月续销流速累计金额
    FROM zb_jyjhtjkb_PositDiff
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    -- 删除临时表
    drop table  #stDate
    drop table #JyjhtjkbTb
    drop  table  #sale
end



-- SELECT
--     [buguid],                                   -- 组织GUID
--     [projguid],                                 -- 项目GUID
--     [清洗日期],                                 -- 清洗日期
--     [开盘时间_动态版],                          -- 动态版开盘时间
--     [开盘时间_立项版],                          -- 立项版开盘时间
--     [开盘时长_动态版],                          -- 动态版开盘时长
--     [开盘时长_立项版],                          -- 立项版开盘时长
--     CASE 
--         WHEN [开盘时长_动态版] IS NOT NULL AND [开盘时长_立项版] IS NOT NULL 
--         THEN ISNULL([开盘时长_立项版], 0) - ISNULL([开盘时长_动态版], 0) 
--         ELSE NULL 
--     END AS [开盘时长偏差],                       -- 开盘时长偏差
--     [首开去化套数_动态版],                      -- 动态版首开去化套数
--     [首开去化套数_立项版],                      -- 立项版首开去化套数
--     CASE 
--         WHEN [首开去化套数_动态版] IS NOT NULL AND [首开去化套数_立项版] IS NOT NULL 
--         THEN  ISNULL([首开去化套数_动态版], 0) - ISNULL([首开去化套数_立项版], 0) 
--         ELSE NULL 
--     END AS [首开去化套数偏差],                   -- 首开去化套数偏差

--     [续销流速累计套数_立项版],                  -- 立项版续销流速累计套数

--     [续销流速截止本月累计套数],                 -- 截止本月续销流速累计套数
--     [续销流速截止上月累计套数],                 -- 截止上月续销流速累计套数
--     case when [续销流速累计套数_立项版] is  not null  and  [续销流速截止本月累计套数] is  not null 
--        then   isnull([续销流速截止本月累计套数],0) - isnull([续销流速累计套数_立项版],0) end  as  [续销流速累计套数偏差],
--     [续销流速累计本月套数_立项版],              -- 立项版续销流速累计本月套数
--     [续销流速累计本月金额_立项版],              -- 立项版续销流速累计本月金额
--     [续销流速截止本月累计金额],                 -- 截止本月续销流速累计金额
--     [续销流速截止上月累计金额],                  -- 截止上月续销流速累计金额
--     case when [续销流速累计本月金额_立项版] is  not null  and  [续销流速截止本月累计金额] is  not null 
--        then  isnull([续销流速累计本月金额_立项版],0) -isnull([续销流速截止本月累计金额],0) end  as  [续销流速累计本月金额缺口],
--     case when [续销流速截止本月累计套数] is  not null and [续销流速截止上月累计套数] is  not  null 
--         then   isnull([续销流速截止上月累计套数],0) -isnull([续销流速截止本月累计套数],0)  end  as   [续销流速环比上月提降]
-- FROM 
--     zb_jyjhtjkb_PositDiff 
-- WHERE 
--     DATEDIFF(DAY, [清洗日期], ${qxDate}) = 0




SELECT
    [buguid],                                   -- 组织GUID
    [projguid],                                 -- 项目GUID
    [清洗日期],                                 -- 清洗日期
    [开盘时间_动态版],                          -- 动态版开盘时间
    [开盘时间_立项版],                          -- 立项版开盘时间
    [开盘时长_动态版],                          -- 动态版开盘时长
    [开盘时长_立项版],                          -- 立项版开盘时长
    CASE 
        WHEN [开盘时长_动态版] IS NOT NULL AND [开盘时长_立项版] IS NOT NULL 
        THEN  ISNULL([开盘时长_动态版], 0)  - ISNULL([开盘时长_立项版], 0)   
        ELSE NULL 
    END AS [开盘时长偏差],                       -- 开盘时长偏差
    [首开去化套数_动态版],                      -- 动态版首开去化套数
    [首开去化套数_立项版],                      -- 立项版首开去化套数
    CASE 
        WHEN [首开去化套数_动态版] IS NOT NULL AND [首开去化套数_立项版] IS NOT NULL 
        THEN  ISNULL([首开去化套数_动态版], 0) - ISNULL([首开去化套数_立项版], 0) 
        ELSE NULL 
    END AS [首开去化套数偏差],                   -- 首开去化套数偏差

    [续销流速累计套数_立项版],                  -- 立项版续销流速累计套数

    [续销流速截止本月累计套数],                 -- 截止本月续销流速累计套数
    [续销流速截止上月累计套数],                 -- 截止上月续销流速累计套数
    case when [续销流速累计套数_立项版] is  not null  and  [续销流速截止本月累计套数] is  not null 
       then   isnull([续销流速截止本月累计套数],0) - isnull([续销流速累计套数_立项版],0) end  as  [续销流速累计套数偏差],
    [续销流速累计本月套数_立项版],              -- 立项版续销流速累计本月套数
    [续销流速累计本月金额_立项版],              -- 立项版续销流速累计本月金额
    [续销流速截止本月累计金额],                 -- 截止本月续销流速累计金额
    [续销流速截止上月累计金额],                  -- 截止上月续销流速累计金额
    case when [续销流速累计本月金额_立项版] is  not null  and  [续销流速截止本月累计金额] is  not null 
       then  isnull([续销流速截止本月累计金额],0) -isnull([续销流速累计本月金额_立项版],0) end  as  [续销流速累计本月金额缺口],
    case when [续销流速截止本月累计套数] is  not null and [续销流速截止上月累计套数] is  not  null 
        then   isnull([续销流速截止上月累计套数],0) -isnull([续销流速截止本月累计套数],0)  end  as   [续销流速环比上月提降]
FROM 
    zb_jyjhtjkb_PositDiff 
WHERE 
    DATEDIFF(DAY, [清洗日期], ${qxDate}) = 0

