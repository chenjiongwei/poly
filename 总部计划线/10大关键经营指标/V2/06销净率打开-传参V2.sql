USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_xsjlv]    Script Date: 2025/7/23 10:32:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- 项目销净率分析报表
-- 功能：分析项目2024年及2025年初的销售净利率情况
-- 包括：24年累计数据、本周数据、本月数据对比分析
-- =============================================

-- DECLARE @zedate DATETIME;
-- DECLARE @zbdate DATETIME;
-- DECLARE @newzbdate DATETIME;
-- DECLARE @newzedate DATETIME;
-- DECLARE @szedate DATETIME;
-- DECLARE @szbdate DATETIME;
-- --本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差

-- SET @zbdate = '2025-07-07'; -- 本周开始日期
-- SET @zedate = '2025-07-13'; --  本周结束日期
-- SET @newzbdate = '2025-07-07'; -- 新本周开始日期
-- SET @newzedate = '2025-07-13'; -- 新本周结束日期
-- SET @szbdate = '2025-06-30'; --上周开始日期
-- SET @szedate = '2025-07-06'; --上周结束日期




JY02净利率打开V2


DECLARE @qxdate DATETIME;
DECLARE @zbdate DATETIME;
DECLARE @zedate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;
DECLARE @szbdate DATETIME; 
DECLARE @szedate DATETIME;  

set @qxdate =getdate(); 
SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
SET @zedate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
SET @newzedate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)
set @szbdate =${szbdate};
set @szedate =${szedate};

 exec usp_s_xsjlv_v2 @qxdate,@zbdate,@zedate,@newzbdate,@newzedate,@szbdate,@szedate

--  exec usp_s_xsjlv_v2 '2025-07-23','2025-07-07','2025-07-13','2025-07-07','2025-07-13','2025-06-30','2025-07-06'
create or alter  proc [dbo].[usp_s_xsjlv_v2](
     @qxdate datetime, -- 清洗时间
     @zbdate datetime, -- 本周开始日期(周日)
     @zedate datetime, -- 本周结束日期(周六)
     @newzbdate datetime, -- 新本周开始日期         
     @newzedate datetime, -- 新本周结束日期（周六）
     @szbdate DATETIME, -- 上周开始日期
     @szedate DATETIME -- 上周结束日期

)
as  
begin 

 -- 判断传递参数是否同当前结果表存储参数一致，如果一致则不做清洗，直接返回结果值
     if exists (select 1 from [销净率打开_v2] 
          where  datediff(day,@qxdate,qxdate) = 0
              and datediff(day,@zbdate,zbdate) = 0
              and datediff(day,@zedate,zedate) = 0
              and datediff(day,@newzbdate,newzbdate) = 0
              and datediff(day,@newzedate,newzedate) = 0
              and datediff(day,@szedate,szedate) = 0
              and datediff(day,@szbdate,szbdate) = 0
              )
     begin
          select * from  [销净率打开_v2] where  datediff(day,@qxdate,qxdate) = 0
          return 
     end

-- 声明日期变量
-- DECLARE @zedate DATETIME;    -- 结束日期
-- DECLARE @zbdate DATETIME;    -- 开始日期
-- DECLARE @newzbdate DATETIME; -- 新的开始日期
-- DECLARE @newzedate DATETIME; -- 新的结束日期

-- 初始化日期参数
-- SET @zbdate = '2025-07-07'; -- 本周开始日期
-- SET @zedate = '2025-07-13'; --  本周结束日期
-- SET @newzbdate = '2025-07-07'; -- 新本周开始日期
-- SET @newzedate = '2025-07-13'; -- 新本周结束日期
-- SET @szbdate = '2025-06-30'; --上周开始日期
-- SET @szedate = '2025-07-06'; --上周结束日期

-- SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
-- SET @zedate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
-- SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
-- SET @newzedate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)



-- DECLARE @zedate DATETIME;
-- DECLARE @zbdate DATETIME;
-- DECLARE @newzbdate DATETIME;
-- DECLARE @newzedate DATETIME;
-- DECLARE @szedate DATETIME;
-- DECLARE @szbdate DATETIME;
-- --本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
-- SET @zbdate = '2025-07-07'; -- 本周开始日期
-- SET @zedate = '2025-07-13'; --  本周结束日期
-- SET @newzbdate = '2025-07-07'; -- 新本周开始日期
-- SET @newzedate = '2025-07-13'; -- 新本周结束日期
-- SET @szbdate = '2025-06-30'; --上周开始日期
-- SET @szedate = '2025-07-06'; --上周结束日期

    -- 获取24年累计数据
    -- 获取24年累计剩余面积
    SELECT projguid,
        SUM(zksmj - ysmj) / 10000 symj
    INTO #symj
    FROM p_lddbamj
    WHERE DATEDIFF(dd, qxdate, '2024-12-31') = 0
        AND producttype <> '地下室/车库'
    GROUP BY projguid;

    --获取24年的净利率
    SELECT a.projguid,
        p.AcquisitionDate,
        SUM(本年签约金额) 本年签约金额,
        SUM(本年签约金额不含税) 本年签约金额不含税,
        SUM(本年净利润签约) 本年净利润签约,
        CASE
            WHEN SUM(本年签约金额不含税) <> 0 THEN
                    SUM(本年净利润签约) / SUM(本年签约金额不含税)
            ELSE 0
        END 本年销净率
    INTO #jjl
    FROM s_M002项目级毛利净利汇总表New a
        LEFT JOIN mdm_project p ON a.projguid = p.projguid
    WHERE DATEDIFF(DAY, qxdate, '2024-12-31') = 0
    GROUP BY a.projguid,
            p.AcquisitionDate;

    --获取24年累计签约
    SELECT projguid,
        SUM(累计签约金额) 累计签约金额
    INTO #ljqy24
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(DAY, qxdate, '2024-12-31') = 0
    GROUP BY projguid;


    --获取本周本月数据
    SELECT a.projguid,
        ISNULL(a.本年签约金额, 0) - ISNULL(b.本年签约金额, 0) 本周签约金额,
        ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) 本周签约金额不含税,
        ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0) 本周净利润签约,
        CASE
            WHEN ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) <> 0 THEN
        (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / (ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
            ELSE 0
        END 本周净利率,
        ISNULL(c.本年签约金额, 0) - ISNULL(bb.本年签约金额, 0) 新本周签约金额,
        ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0) 新本周签约金额不含税,
        ISNULL(c.本年净利润签约, 0) - ISNULL(bb.本年净利润签约, 0) 新本周净利润签约,
        CASE
            WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0) <> 0 THEN
        (ISNULL(c.本年净利润签约, 0) - ISNULL(bb.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0))
            ELSE 0
        END 新本周净利率,
        ISNULL(sa.本年签约金额, 0) - ISNULL(sb.本年签约金额, 0) 上周签约金额,
        ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0) 上周签约金额不含税,
        ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0) 上周净利润签约,
        CASE
            WHEN ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0) <> 0 THEN
        (ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0)) / (ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0))
            ELSE 0
        END 上周净利率,
        ISNULL(c.本月签约金额, 0) 本月签约金额,
        ISNULL(c.本月签约金额不含税, 0) 本月签约金额不含税,
        ISNULL(c.本月净利润签约, 0) 本月净利润签约,
        c.本月净利率,
        c.本年销净率,
        c.本年签约金额,
        c.本年净利润签约,
        c.本年签约金额不含税,
        ISNULL(d.本年签约金额, 0) 一季度签约金额,
        ISNULL(d.本年签约金额不含税, 0) 一季度签约金额不含税,
        ISNULL(d.本年净利润签约, 0) 一季度净利润签约,
        d.本年销净率 一季度净利率,
        ISNULL(d2.本年签约金额, 0) - ISNULL(d.本年签约金额, 0) 二季度签约金额,
        ISNULL(d2.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0) 二季度签约金额不含税,
        ISNULL(d2.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0) 二季度净利润签约,
        case when (ISNULL(d2.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0)) = 0 then 0 
        else (ISNULL(d.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0))/ (ISNULL(d2.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0)) 
        end 二季度净利率,
        ISNULL(e.本月签约金额, 0) 四月签约金额,
        ISNULL(e.本月签约金额不含税, 0) 四月签约金额不含税,
        ISNULL(e.本月净利润签约, 0) 四月净利润签约,
        e.本月净利率 四月净利率,
        ISNULL(f.本月签约金额, 0) 五月签约金额,
        ISNULL(f.本月签约金额不含税, 0) 五月签约金额不含税,
        ISNULL(f.本月净利润签约, 0) 五月净利润签约,
        f.本月净利率 五月净利率,
        ISNULL(g.本月签约金额, 0) 六月签约金额,
        ISNULL(g.本月签约金额不含税, 0) 六月签约金额不含税,
        ISNULL(g.本月净利润签约, 0) 六月净利润签约,
        g.本月净利率 六月净利率
    INTO #benzhou
    FROM
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
        GROUP BY projguid
    ) a
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
        GROUP BY projguid
    ) b ON a.projguid = b.projguid
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
        GROUP BY projguid
    ) bb ON a.projguid = bb.projguid
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率,
            CASE
                WHEN SUM(本年签约金额不含税) <> 0 THEN
                        SUM(本年净利润签约) / SUM(本年签约金额不含税)
                ELSE 0
            END 本年销净率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
        GROUP BY projguid
    ) c ON a.projguid = c.projguid

    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率,
            CASE
                WHEN SUM(本年签约金额不含税) <> 0 THEN
                        SUM(本年净利润签约) / SUM(本年签约金额不含税)
                ELSE 0
            END 本年销净率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
        GROUP BY projguid
    ) d ON a.projguid = d.projguid
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率,
            CASE
                WHEN SUM(本年签约金额不含税) <> 0 THEN
                        SUM(本年净利润签约) / SUM(本年签约金额不含税)
                ELSE 0
            END 本年销净率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, '2025-06-30') = 0
        GROUP BY projguid
    ) d2 ON a.projguid = d2.projguid
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率,
            CASE
                WHEN SUM(本年签约金额不含税) <> 0 THEN
                        SUM(本年净利润签约) / SUM(本年签约金额不含税)
                ELSE 0
            END 本年销净率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, '2025-04-30') = 0
        GROUP BY projguid
    ) e ON a.projguid = e.projguid
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率,
            CASE
                WHEN SUM(本年签约金额不含税) <> 0 THEN
                        SUM(本年净利润签约) / SUM(本年签约金额不含税)
                ELSE 0
            END 本年销净率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, '2025-05-31') = 0
        GROUP BY projguid
    ) f ON a.projguid = f.projguid
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率,
            CASE
                WHEN SUM(本年签约金额不含税) <> 0 THEN
                        SUM(本年净利润签约) / SUM(本年签约金额不含税)
                ELSE 0
            END 本年销净率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, '2025-06-30') = 0
        GROUP BY projguid
    ) g ON a.projguid = g.projguid
    LEFT JOIN 
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约,
            CASE
                WHEN SUM(本月签约金额不含税) <> 0 THEN
                        SUM(本月净利润签约) / SUM(本月签约金额不含税)
                ELSE 0
            END 本月净利率
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, @szedate) = 0
        GROUP BY projguid
    ) sa ON a.projguid = sa.projguid
    LEFT JOIN
    (
        SELECT projguid,
            SUM(本月签约金额) 本月签约金额,
            SUM(本月签约金额不含税) 本月签约金额不含税,
            SUM(本月净利润签约) 本月净利润签约,
            SUM(本年签约金额) 本年签约金额,
            SUM(本年签约金额不含税) 本年签约金额不含税,
            SUM(本年净利润签约) 本年净利润签约
        FROM s_M002项目级毛利净利汇总表New
        WHERE DATEDIFF(DAY, qxdate, @szbdate) = 1
        GROUP BY projguid
    ) sb ON a.projguid = sb.projguid;


    SELECT ProjGUID,
        SUM(syhz) / 100000000 syhz
    INTO #nchz
    FROM p_lddb a
    WHERE DATEDIFF(dd, qxdate, '2024-12-31') = 0
    GROUP BY a.ProjGUID;

    SELECT f.projguid,
        f.平台公司,
        f.项目代码,
        f.投管代码,
        f.项目名,
        f.推广名,
        f.获取时间,
        CASE
            WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN
                    '24～25年获取'
            WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN
                    '22～23年获取'
            ELSE '存量（21年及之前获取）'
        END 项目划分,
        CASE
            WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN
                    '8'
            WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN
                    '7'
            ELSE CASE
                        WHEN j.本年销净率 >= 0 THEN
                            '1'
                        WHEN j.本年销净率 >= -0.1
                            AND j.本年销净率 < 0 THEN
                            '2'
                        WHEN j.本年销净率 >= -0.2
                            AND j.本年销净率 < -0.1 THEN
                            '3'
                        WHEN j.本年销净率 >= -0.3
                            AND j.本年销净率 < -0.2 THEN
                            '4'
                        ELSE '5'
                    END
        END num,
        CASE
            WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN
                    '24～25年获取'
            WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN
                    '22～23年获取'
            ELSE CASE
                        WHEN j.本年销净率 >= 0 THEN
                            '≥0%'
                        WHEN j.本年销净率 >= -0.1
                            AND j.本年销净率 < 0 THEN
                            '-10%～0%'
                        WHEN j.本年销净率 >= -0.2
                            AND j.本年销净率 < -0.1 THEN
                            '-20%～-10%'
                        WHEN j.本年销净率 >= -0.3
                            AND j.本年销净率 < -0.2 THEN
                            '-30%～-20%'
                        ELSE '＜-30%'
                    END
        END 项目类型,
        s.symj '24年地上剩余可售',
        l.累计签约金额 '截止24年底签约金额',
        j.本年签约金额 '24年签约金额',
        j.本年签约金额不含税 '24年签约金额不含税',
        j.本年净利润签约 '24年净利润签约',
        j.本年销净率 * 1.00 '24年净利率',
        a.本年销净率 * 1.00 '本年净利率',
        a.本周签约金额,
        a.本周签约金额不含税,
        a.本周净利润签约,
        a.本周净利率,
        a.新本周签约金额,
        a.新本周签约金额不含税,
        a.新本周净利润签约,
        a.新本周净利率,
        a.上周签约金额,
        a.上周签约金额不含税,
        a.上周净利润签约,
        a.上周净利率,
        a.一季度签约金额,
        a.一季度签约金额不含税,
        a.一季度净利润签约,
        a.二季度签约金额,
        a.二季度签约金额不含税,
        a.二季度净利润签约,
        a.四月签约金额,
        a.四月签约金额不含税,
        a.四月净利润签约,
        a.五月签约金额,
        a.五月签约金额不含税,
        a.五月净利润签约,
        a.六月签约金额,
        a.六月签约金额不含税,
        a.六月净利润签约,
        a.本月签约金额,
        a.本月签约金额不含税,
        a.本月净利润签约,
        a.本月净利率 * 1.00 本月净利率,
        h.syhz '25年初可售货值',
        CASE
            WHEN f.获取时间 IS NOT NULL
                    AND
                    (
                        (
                            YEAR(f.获取时间) < 2024
                            AND s.symj >= 1
                        )
                        OR ISNULL(s.symj, 1) >= 1
                    ) THEN
                    '是'
            ELSE '否'
        END 是否统计
    INTO #result24
    FROM #benzhou a
        LEFT JOIN #jjl j ON a.projguid = j.projguid
        LEFT JOIN #ljqy24 l ON a.projguid = l.projguid
        LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
        LEFT JOIN #symj s ON a.projguid = s.projguid
        LEFT JOIN #nchz h ON a.projguid = h.projguid
    WHERE f.获取时间 IS NOT NULL --获取时间为空的去掉
    AND year(f.获取时间) < 2025
    --and f.项目状态 in  ('正常','正常（拟退出）')
    ORDER BY f.平台公司,
            f.项目代码;
            
            
    SELECT f.projguid,
        f.平台公司,
        f.项目代码,
        f.投管代码,
        f.项目名,
        f.推广名,
        f.获取时间,
        CASE
            WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN
                    '24～25年获取'
            WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN
                    '22～23年获取'
            ELSE '存量（21年及之前获取）'
        END 项目划分,
        CASE
            WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN
                    '8'
            WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN
                    '7'
            ELSE CASE
                        WHEN a.本年销净率 >= 0 THEN
                            '1'
                        WHEN a.本年销净率 >= -0.1
                            AND a.本年销净率 < 0 THEN
                            '2'
                        WHEN a.本年销净率 >= -0.2
                            AND a.本年销净率 < -0.1 THEN
                            '3'
                        WHEN a.本年销净率 >= -0.3
                            AND a.本年销净率 < -0.2 THEN
                            '4'
                        ELSE '5'
                    END
        END num,
        CASE
            WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN
                    '24～25年获取'
            WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN
                    '22～23年获取'
            ELSE CASE
                        WHEN a.本年销净率 >= 0 THEN
                            '≥0%'
                        WHEN a.本年销净率 >= -0.1
                            AND a.本年销净率 < 0 THEN
                            '-10%～0%'
                        WHEN a.本年销净率 >= -0.2
                            AND a.本年销净率 < -0.1 THEN
                            '-20%～-10%'
                        WHEN a.本年销净率 >= -0.3
                            AND a.本年销净率 < -0.2 THEN
                            '-30%～-20%'
                        ELSE '＜-30%'
                    END
        END 项目类型,
        s.symj '24年地上剩余可售',
        l.累计签约金额 '截止24年底签约金额',
        j.本年签约金额 '24年签约金额',
        j.本年签约金额不含税 '24年签约金额不含税',
        j.本年净利润签约 '24年净利润签约',
        j.本年销净率 * 1.00 '24年净利率',
        a.本年销净率 * 1.00 '本年净利率',
        a.本年签约金额,
        a.本年净利润签约,
        a.本年签约金额不含税,
        a.本周签约金额,
        a.本周签约金额不含税,
        a.本周净利润签约,
        a.本周净利率,
        a.新本周签约金额,
        a.新本周签约金额不含税,
        a.新本周净利润签约,
        a.新本周净利率,
        a.上周签约金额,
        a.上周签约金额不含税,
        a.上周净利润签约,
        a.上周净利率,
        a.一季度签约金额,
        a.一季度签约金额不含税,
        a.一季度净利润签约,
        a.二季度签约金额,
        a.二季度签约金额不含税,
        a.二季度净利润签约,
        a.四月签约金额,
        a.四月签约金额不含税,
        a.四月净利润签约,
        a.五月签约金额,
        a.五月签约金额不含税,
        a.五月净利润签约,
        a.六月签约金额,
        a.六月签约金额不含税,
        a.六月净利润签约,
        a.本月签约金额,
        a.本月签约金额不含税,
        a.本月净利润签约,
        a.本月净利率 * 1.00 本月净利率,
        h.syhz '25年初可售货值',
        CASE
            WHEN f.获取时间 IS NOT NULL
                    AND
                    (
                        (
                            YEAR(f.获取时间) < 2024
                            AND s.symj >= 1
                        )
                        OR ISNULL(s.symj, 1) >= 1
                    ) THEN
                    '是'
            ELSE '否'
        END 是否统计
    INTO #result
    FROM #benzhou a
        LEFT JOIN #jjl j ON a.projguid = j.projguid
        LEFT JOIN #ljqy24 l ON a.projguid = l.projguid
        LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
        LEFT JOIN #symj s ON a.projguid = s.projguid
        LEFT JOIN #nchz h ON a.projguid = h.projguid
    WHERE f.获取时间 IS NOT NULL --获取时间为空的去掉
    --and f.项目状态 in  ('正常','正常（拟退出）')
    ORDER BY f.平台公司,
            f.项目代码;


    --24年签约金额	24年平均销净率	本周销净率	本周签约金额	本月销净率	本月签约金额
    SELECT num,
        项目划分,
        项目类型,
        COUNT(1) [24年项目个数],
        SUM([24年签约金额]) [24年签约金额],
        CASE
            WHEN SUM([24年签约金额不含税]) > 0 THEN
                    SUM([24年净利润签约]) / SUM([24年签约金额不含税])
            ELSE 0
        END '24年平均销净率',
        COUNT(1) [25年项目个数],
        SUM(本周签约金额) 本周签约金额,
        SUM(本周签约金额不含税) 本周签约金额不含税,
        SUM(本周净利润签约) 本周净利润签约,
        CASE
            WHEN SUM(本周签约金额不含税) > 0 THEN
                    SUM(本周净利润签约) / SUM(本周签约金额不含税)
            ELSE 0
        END '本周销净率',
        SUM(新本周签约金额) 新本周签约金额,
        SUM(新本周签约金额不含税) 新本周签约金额不含税,
        SUM(新本周净利润签约) 新本周净利润签约,
        CASE
            WHEN SUM(新本周签约金额不含税) > 0 THEN
                    SUM(新本周净利润签约) / SUM(新本周签约金额不含税)
            ELSE 0
        END '新本周销净率',
        SUM(上周签约金额) 上周签约金额,
        SUM(上周签约金额不含税) 上周签约金额不含税,
        SUM(上周净利润签约) 上周净利润签约,
        CASE
            WHEN SUM(上周签约金额不含税) > 0 THEN
                    SUM(上周净利润签约) / SUM(上周签约金额不含税)
            ELSE 0
        END '上周销净率',
        SUM(一季度签约金额) 一季度签约金额,
        CASE
            WHEN SUM(一季度签约金额不含税) > 0 THEN
                    SUM(一季度净利润签约) / SUM(一季度签约金额不含税)
            ELSE 0
        END '一季度销净率',
        SUM(二季度签约金额) 二季度签约金额,
        CASE
            WHEN SUM(二季度签约金额不含税) > 0 THEN
                    SUM(二季度净利润签约) / SUM(二季度签约金额不含税)
            ELSE 0
        END '二季度销净率',
        SUM(四月签约金额) 四月签约金额,
        CASE
            WHEN SUM(四月签约金额不含税) > 0 THEN
                    SUM(四月净利润签约) / SUM(四月签约金额不含税)
            ELSE 0
        END '四月销净率',
        SUM(五月签约金额) 五月签约金额,
        CASE
            WHEN SUM(五月签约金额不含税) > 0 THEN
                    SUM(五月净利润签约) / SUM(五月签约金额不含税)
            ELSE 0
        END '五月销净率',
        SUM(六月签约金额) 六月签约金额,
        CASE
            WHEN SUM(六月签约金额不含税) > 0 THEN
                    SUM(六月净利润签约) / SUM(六月签约金额不含税)
            ELSE 0
        END '六月销净率',
        SUM(本月签约金额) 本月签约金额,
        SUM(本月签约金额不含税) 本月签约金额不含税,
        SUM(本月净利润签约) 本月净利润签约,
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                    SUM(本月净利润签约) / SUM(本月签约金额不含税)
            ELSE 0
        END '本月销净率',
        SUM(本年签约金额) 本年签约金额,
        SUM(本年签约金额不含税) 本年签约金额不含税,
        SUM(本年净利润签约) 本年净利润签约,
        CASE
            WHEN SUM(本年签约金额不含税) > 0 THEN
                    SUM(本年净利润签约) / SUM(本年签约金额不含税)
            ELSE 0
        END '本年销净率'
    INTO #result1
    FROM #result
    --WHERE 是否统计 = '是'
    GROUP BY num,
            项目划分,
            项目类型;


    --24年签约金额	24年平均销净率	本周销净率	本周签约金额	本月销净率	本月签约金额
    SELECT 6 num,
        '存量合计' 项目划分,
        '存量合计' 项目类型,
        COUNT(1) [24年项目个数],
        SUM([24年签约金额]) [24年签约金额],
        CASE
            WHEN SUM([24年签约金额不含税]) > 0 THEN
                    SUM([24年净利润签约]) / SUM([24年签约金额不含税])
            ELSE 0
        END '24年平均销净率',
        COUNT(1) [25年项目个数],
        SUM(本周签约金额) 本周签约金额,
        SUM(本周签约金额不含税) 本周签约金额不含税,
        SUM(本周净利润签约) 本周净利润签约,
        CASE
            WHEN SUM(本周签约金额不含税) > 0 THEN
                    SUM(本周净利润签约) / SUM(本周签约金额不含税)
            ELSE 0
        END '本周销净率',
        SUM(新本周签约金额) 新本周签约金额,
        SUM(新本周签约金额不含税) 新本周签约金额不含税,
        SUM(新本周净利润签约) 新本周净利润签约,
        CASE
            WHEN SUM(新本周签约金额不含税) > 0 THEN
                    SUM(新本周净利润签约) / SUM(新本周签约金额不含税)
            ELSE 0
        END '新本周销净率',
        SUM(上周签约金额) 上周签约金额,
        SUM(上周签约金额不含税) 上周签约金额不含税,
        SUM(上周净利润签约) 上周净利润签约,
        CASE
            WHEN SUM(上周签约金额不含税) > 0 THEN
                    SUM(上周净利润签约) / SUM(上周签约金额不含税)
            ELSE 0
        END '上周销净率',
        SUM(一季度签约金额) 一季度签约金额,
        CASE
            WHEN SUM(一季度签约金额不含税) > 0 THEN
                    SUM(一季度净利润签约) / SUM(一季度签约金额不含税)
            ELSE 0
        END '一季度销净率',
        SUM(二季度签约金额) 二季度签约金额,
        CASE
            WHEN SUM(二季度签约金额不含税) > 0 THEN
                    SUM(二季度净利润签约) / SUM(二季度签约金额不含税)
            ELSE 0
        END '二季度销净率',
        SUM(四月签约金额) 四月签约金额,
        CASE
            WHEN SUM(四月签约金额不含税) > 0 THEN
                    SUM(四月净利润签约) / SUM(四月签约金额不含税)
            ELSE 0
        END '四月销净率',
        SUM(五月签约金额) 五月签约金额,
        CASE
            WHEN SUM(五月签约金额不含税) > 0 THEN
                    SUM(五月净利润签约) / SUM(五月签约金额不含税)
            ELSE 0
        END '五月销净率',
        SUM(六月签约金额) 六月签约金额,
        CASE
            WHEN SUM(六月签约金额不含税) > 0 THEN
                    SUM(六月净利润签约) / SUM(六月签约金额不含税)
            ELSE 0
        END '六月销净率',
        SUM(本月签约金额) 本月签约金额,
        SUM(本月签约金额不含税) 本月签约金额不含税,
        SUM(本月净利润签约) 本月净利润签约,
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                    SUM(本月净利润签约) / SUM(本月签约金额不含税)
            ELSE 0
        END '本月销净率',
        SUM(本年签约金额) 本年签约金额,
        SUM(本年签约金额不含税) 本年签约金额不含税,
        SUM(本年净利润签约) 本年净利润签约,
        CASE
            WHEN SUM(本年签约金额不含税) > 0 THEN
                    SUM(本年净利润签约) / SUM(本年签约金额不含税)
            ELSE 0
        END '本年销净率'
    INTO #result3
    FROM #result
    WHERE(1=1)
    --and 是否统计 = '是'
        AND 项目划分 = '存量（21年及之前获取）';

    --24年签约金额	24年平均销净率	本周销净率	本周签约金额	本月销净率	本月签约金额
    SELECT 9 num,
        '合计' 项目划分,
        '合计' 项目类型,
        COUNT(1) [24年项目个数],
        SUM([24年签约金额]) [24年签约金额],
        CASE
            WHEN SUM([24年签约金额不含税]) > 0 THEN
                    SUM([24年净利润签约]) / SUM([24年签约金额不含税])
            ELSE 0
        END '24年平均销净率',
        COUNT(1) [25年项目个数],
        SUM(本周签约金额) 本周签约金额,
        SUM(本周签约金额不含税) 本周签约金额不含税,
        SUM(本周净利润签约) 本周净利润签约,
        CASE
            WHEN SUM(本周签约金额不含税) > 0 THEN
                    SUM(本周净利润签约) / SUM(本周签约金额不含税)
            ELSE 0
        END '本周销净率',
        SUM(新本周签约金额) 新本周签约金额,
        SUM(新本周签约金额不含税) 新本周签约金额不含税,
        SUM(新本周净利润签约) 新本周净利润签约,
        CASE
            WHEN SUM(新本周签约金额不含税) > 0 THEN
                    SUM(新本周净利润签约) / SUM(新本周签约金额不含税)
            ELSE 0
        END '新本周销净率',
        SUM(上周签约金额) 上周签约金额,
        SUM(上周签约金额不含税) 上周签约金额不含税,
        SUM(上周净利润签约) 上周净利润签约,
        CASE
            WHEN SUM(上周签约金额不含税) > 0 THEN
                    SUM(上周净利润签约) / SUM(上周签约金额不含税)
            ELSE 0
        END '上周销净率',
        SUM(一季度签约金额) 一季度签约金额,
        CASE
            WHEN SUM(一季度签约金额不含税) > 0 THEN
                    SUM(一季度净利润签约) / SUM(一季度签约金额不含税)
            ELSE 0
        END '一季度销净率',
        SUM(二季度签约金额) 二季度签约金额,
        CASE
            WHEN SUM(二季度签约金额不含税) > 0 THEN
                    SUM(二季度净利润签约) / SUM(二季度签约金额不含税)
            ELSE 0
        END '二季度销净率',
        SUM(四月签约金额) 四月签约金额,
        CASE
            WHEN SUM(四月签约金额不含税) > 0 THEN
                    SUM(四月净利润签约) / SUM(四月签约金额不含税)
            ELSE 0
        END '四月销净率',
        SUM(五月签约金额) 五月签约金额,
        CASE
            WHEN SUM(五月签约金额不含税) > 0 THEN
                    SUM(五月净利润签约) / SUM(五月签约金额不含税)
            ELSE 0
        END '五月销净率',
        SUM(六月签约金额) 六月签约金额,
        CASE
            WHEN SUM(六月签约金额不含税) > 0 THEN
                    SUM(六月净利润签约) / SUM(六月签约金额不含税)
            ELSE 0
        END '六月销净率',
        SUM(本月签约金额) 本月签约金额,
        SUM(本月签约金额不含税) 本月签约金额不含税,
        SUM(本月净利润签约) 本月净利润签约,
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                    SUM(本月净利润签约) / SUM(本月签约金额不含税)
            ELSE 0
        END '本月销净率',
        SUM(本年签约金额) 本年签约金额,
        SUM(本年签约金额不含税) 本年签约金额不含税,
        SUM(本年净利润签约) 本年净利润签约,
        CASE
            WHEN SUM(本年签约金额不含税) > 0 THEN
                    SUM(本年净利润签约) / SUM(本年签约金额不含税)
            ELSE 0
        END '本年销净率'
    INTO #result2
    FROM #result
    --WHERE 是否统计 = '是';


    --24年签约金额	24年平均销净率	本周销净率	本周签约金额	本月销净率	本月签约金额
    SELECT num,
        项目划分,
        项目类型,
        COUNT(1) [24年项目个数],
        SUM([24年签约金额]) [24年签约金额],
        CASE
            WHEN SUM([24年签约金额不含税]) > 0 THEN
                    SUM([24年净利润签约]) / SUM([24年签约金额不含税])
            ELSE 0
        END '24年平均销净率',
        COUNT(1) [25年项目个数],
        SUM(本周签约金额) 本周签约金额,
        SUM(本周签约金额不含税) 本周签约金额不含税,
        SUM(本周净利润签约) 本周净利润签约,
        CASE
            WHEN SUM(本周签约金额不含税) > 0 THEN
                    SUM(本周净利润签约) / SUM(本周签约金额不含税)
            ELSE 0
        END '本周销净率',
        SUM(新本周签约金额) 新本周签约金额,
        SUM(新本周签约金额不含税) 新本周签约金额不含税,
        SUM(新本周净利润签约) 新本周净利润签约,
        CASE
            WHEN SUM(新本周签约金额不含税) > 0 THEN
                    SUM(新本周净利润签约) / SUM(新本周签约金额不含税)
            ELSE 0
        END '新本周销净率',
        SUM(上周签约金额) 上周签约金额,
        SUM(上周签约金额不含税) 上周签约金额不含税,
        SUM(上周净利润签约) 上周净利润签约,
        CASE
            WHEN SUM(上周签约金额不含税) > 0 THEN
                    SUM(上周净利润签约) / SUM(上周签约金额不含税)
            ELSE 0
        END '上周销净率',
        SUM(一季度签约金额) 一季度签约金额,
        CASE
            WHEN SUM(一季度签约金额不含税) > 0 THEN
                    SUM(一季度净利润签约) / SUM(一季度签约金额不含税)
            ELSE 0
        END '一季度销净率',
        SUM(二季度签约金额) 二季度签约金额,
        CASE
            WHEN SUM(二季度签约金额不含税) > 0 THEN
                    SUM(二季度净利润签约) / SUM(二季度签约金额不含税)
            ELSE 0
        END '二季度销净率',
        SUM(四月签约金额) 四月签约金额,
        CASE
            WHEN SUM(四月签约金额不含税) > 0 THEN
                    SUM(四月净利润签约) / SUM(四月签约金额不含税)
            ELSE 0
        END '四月销净率',
        SUM(五月签约金额) 五月签约金额,
        CASE
            WHEN SUM(五月签约金额不含税) > 0 THEN
                    SUM(五月净利润签约) / SUM(五月签约金额不含税)
            ELSE 0
        END '五月销净率',
        SUM(六月签约金额) 六月签约金额,
        CASE
            WHEN SUM(六月签约金额不含税) > 0 THEN
                    SUM(六月净利润签约) / SUM(六月签约金额不含税)
            ELSE 0
        END '六月销净率',
        SUM(本月签约金额) 本月签约金额,
        SUM(本月签约金额不含税) 本月签约金额不含税,
        SUM(本月净利润签约) 本月净利润签约,
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                    SUM(本月净利润签约) / SUM(本月签约金额不含税)
            ELSE 0
        END '本月销净率'
    INTO #result124
    FROM #result24
    --WHERE 是否统计 = '是'
    GROUP BY num,
            项目划分,
            项目类型;


    --24年签约金额	24年平均销净率	本周销净率	本周签约金额	本月销净率	本月签约金额
    SELECT 6 num,
        '存量合计' 项目划分,
        '存量合计' 项目类型,
        COUNT(1) [24年项目个数],
        SUM([24年签约金额]) [24年签约金额],
        CASE
            WHEN SUM([24年签约金额不含税]) > 0 THEN
                    SUM([24年净利润签约]) / SUM([24年签约金额不含税])
            ELSE 0
        END '24年平均销净率',
        COUNT(1) [25年项目个数],
        SUM(本周签约金额) 本周签约金额,
        SUM(本周签约金额不含税) 本周签约金额不含税,
        SUM(本周净利润签约) 本周净利润签约,
        CASE
            WHEN SUM(本周签约金额不含税) > 0 THEN
                    SUM(本周净利润签约) / SUM(本周签约金额不含税)
            ELSE 0
        END '本周销净率',
        SUM(新本周签约金额) 新本周签约金额,
        SUM(新本周签约金额不含税) 新本周签约金额不含税,
        SUM(新本周净利润签约) 新本周净利润签约,
        CASE
            WHEN SUM(新本周签约金额不含税) > 0 THEN
                    SUM(新本周净利润签约) / SUM(新本周签约金额不含税)
            ELSE 0
        END '新本周销净率',
        SUM(上周签约金额) 上周签约金额,
        SUM(上周签约金额不含税) 上周签约金额不含税,
        SUM(上周净利润签约) 上周净利润签约,
        CASE
            WHEN SUM(上周签约金额不含税) > 0 THEN
                    SUM(上周净利润签约) / SUM(上周签约金额不含税)
            ELSE 0
        END '上周销净率',
        SUM(一季度签约金额) 一季度签约金额,
        CASE
            WHEN SUM(一季度签约金额不含税) > 0 THEN
                    SUM(一季度净利润签约) / SUM(一季度签约金额不含税)
            ELSE 0
        END '一季度销净率',
        SUM(二季度签约金额) 二季度签约金额,
        CASE
            WHEN SUM(二季度签约金额不含税) > 0 THEN
                    SUM(二季度净利润签约) / SUM(二季度签约金额不含税)
            ELSE 0
        END '二季度销净率',
        SUM(四月签约金额) 四月签约金额,
        CASE
            WHEN SUM(四月签约金额不含税) > 0 THEN
                    SUM(四月净利润签约) / SUM(四月签约金额不含税)
            ELSE 0
        END '四月销净率',
        SUM(五月签约金额) 五月签约金额,
        CASE
            WHEN SUM(五月签约金额不含税) > 0 THEN
                    SUM(五月净利润签约) / SUM(五月签约金额不含税)
            ELSE 0
        END '五月销净率',
        SUM(六月签约金额) 六月签约金额,
        CASE
            WHEN SUM(六月签约金额不含税) > 0 THEN
                    SUM(六月净利润签约) / SUM(六月签约金额不含税)
            ELSE 0
        END '六月销净率',
        SUM(本月签约金额) 本月签约金额,
        SUM(本月签约金额不含税) 本月签约金额不含税,
        SUM(本月净利润签约) 本月净利润签约,
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                    SUM(本月净利润签约) / SUM(本月签约金额不含税)
            ELSE 0
        END '本月销净率'
    INTO #result324
    FROM #result24
    WHERE (1=1)
    --and 是否统计 = '是'
        AND 项目划分 = '存量（21年及之前获取）';

    --24年签约金额	24年平均销净率	本周销净率	本周签约金额	本月销净率	本月签约金额
    SELECT 9 num,
        '合计' 项目划分,
        '合计' 项目类型,
        COUNT(1) [24年项目个数],
        SUM([24年签约金额]) [24年签约金额],
        CASE
            WHEN SUM([24年签约金额不含税]) > 0 THEN
                    SUM([24年净利润签约]) / SUM([24年签约金额不含税])
            ELSE 0
        END '24年平均销净率',
        COUNT(1) [25年项目个数],
        SUM(本周签约金额) 本周签约金额,
        SUM(本周签约金额不含税) 本周签约金额不含税,
        SUM(本周净利润签约) 本周净利润签约,
        CASE
            WHEN SUM(本周签约金额不含税) > 0 THEN
                    SUM(本周净利润签约) / SUM(本周签约金额不含税)
            ELSE 0
        END '本周销净率',
        SUM(新本周签约金额) 新本周签约金额,
        SUM(新本周签约金额不含税) 新本周签约金额不含税,
        SUM(新本周净利润签约) 新本周净利润签约,
        CASE
            WHEN SUM(新本周签约金额不含税) > 0 THEN
                    SUM(新本周净利润签约) / SUM(新本周签约金额不含税)
            ELSE 0
        END '新本周销净率',
        SUM(上周签约金额) 上周签约金额,
        SUM(上周签约金额不含税) 上周签约金额不含税,
        SUM(上周净利润签约) 上周净利润签约,
        CASE
            WHEN SUM(上周签约金额不含税) > 0 THEN
                    SUM(上周净利润签约) / SUM(上周签约金额不含税)
            ELSE 0
        END '上周销净率',
        SUM(一季度签约金额) 一季度签约金额,
        CASE
            WHEN SUM(一季度签约金额不含税) > 0 THEN
                    SUM(一季度净利润签约) / SUM(一季度签约金额不含税)
            ELSE 0
        END '一季度销净率',
        SUM(二季度签约金额) 二季度签约金额,
        CASE
            WHEN SUM(二季度签约金额不含税) > 0 THEN
                    SUM(二季度净利润签约) / SUM(二季度签约金额不含税)
            ELSE 0
        END '二季度销净率',
        SUM(四月签约金额) 四月签约金额,
        CASE
            WHEN SUM(四月签约金额不含税) > 0 THEN
                    SUM(四月净利润签约) / SUM(四月签约金额不含税)
            ELSE 0
        END '四月销净率',
        SUM(五月签约金额) 五月签约金额,
        CASE
            WHEN SUM(五月签约金额不含税) > 0 THEN
                    SUM(五月净利润签约) / SUM(五月签约金额不含税)
            ELSE 0
        END '五月销净率',
        SUM(六月签约金额) 六月签约金额,
        CASE
            WHEN SUM(六月签约金额不含税) > 0 THEN
                    SUM(六月净利润签约) / SUM(六月签约金额不含税)
            ELSE 0
        END '六月销净率',
        SUM(本月签约金额) 本月签约金额,
        SUM(本月签约金额不含税) 本月签约金额不含税,
        SUM(本月净利润签约) 本月净利润签约,
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                    SUM(本月净利润签约) / SUM(本月签约金额不含税)
            ELSE 0
        END '本月销净率'
    INTO #result224
    FROM #result24
    --WHERE 是否统计 = '是';

    -- 输出查询结果
    SELECT 
        a.num,
        a.项目划分,
        a.项目类型,
        b.[24年项目个数],
        b.[24年签约金额],
        b.[24年平均销净率],
        a.[25年项目个数],
        a.本周签约金额,
        a.本周签约金额不含税,
        a.本周净利润签约,
        a.本周销净率,
        a.新本周签约金额,
        a.新本周签约金额不含税,
        a.新本周净利润签约,
        a.新本周销净率,
        a.上周签约金额,
        a.上周签约金额不含税,
        a.上周净利润签约,
        a.上周销净率,
        a.一季度签约金额,
        a.一季度销净率,
        a.二季度签约金额,
        a.二季度销净率,
        a.四月签约金额,
        a.四月销净率,
        a.五月签约金额,
        a.五月销净率,
        a.六月签约金额,
        a.六月销净率,
        a.本月签约金额,
        a.本月签约金额不含税,
        a.本月净利润签约,
        a.本月销净率,
        a.本年签约金额,
        a.本年签约金额不含税,
        a.本年净利润签约,
        a.本年销净率
    into #resultall
    FROM
    (
        SELECT *
        FROM #result1
        UNION
        SELECT *
        FROM #result3
        UNION
        SELECT *
        FROM #result2
    ) a
    LEFT JOIN (
        SELECT *
        FROM #result124
        UNION
        SELECT *
        FROM #result324
        UNION
        SELECT *
        FROM #result224
    ) b ON a.项目划分 = b.项目划分 AND a.项目类型 = b.项目类型
    ORDER BY a.num;


    -- =============================================
    -- 最终结果输出
    -- =============================================
    -- 为避免清洗时间重复，将清洗时间为当天的数据清除掉
    truncate table   [dbo].[销净率打开_v2] 
    -- WHERE DATEDIFF(day, qxdate, GETDATE()) = 0;  

    INSERT INTO [dbo].[销净率打开_v2]
    SELECT * 
    FROM
    (
        SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate,@szedate AS szedate,@szbdate AS szbdate , * 
        FROM #resultall

    ) a
    ORDER BY a.num;

    -- 输出仓结果
    select  * from 销净率打开_v2 where datediff(day,qxdate,@qxdate) = 0
    order by num

    -- 删除临时表
    DROP TABLE #benzhou,
            #jjl,
            #ljqy24,
            #symj,
            #result,
            #result1,
            #result2,
            #result3,
            #resultall,
            #nchz,#result124,#result224,#result24,#result324;


end 


