USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_sumIndexTotal]    Script Date: 2025/4/19 17:28:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 /*
 * 文件名: 01导出一季度指标完成情况-传参.sql
 * 功能: 导出公司一季度关键经营指标完成情况
 * 主要指标包括:
 * 1. 签约金额(总签约、分类签约)
 * 2. 销售净利率
 * 3. 营销费率
 * 4. 新开工面积
 * 5. 竣工面积
 * 6. 交付套数
 * 7. 投资情况
 * 
 * 数据来源:
 * - S_08ZYXSQYJB_HHZTSYJ_daily: 签约数据
 * - s_M002项目级毛利净利汇总表New: 销售净利率
 * - MyCost_Erp352.dbo.ys_YearPlanDept2Cost: 营销费用
 * - jd_PlanTaskExecuteObjectForReport: 新开工和竣工面积
 * - s_contract: 交付数据
 */
-- exec usp_s_sumIndexTotal
--      @qxdate = '2025-04-18', -- 清洗时间
--      @zbdate = '2025-04-06', -- 本周开始日期(周日)
--      @zedate = '2025-04-12', -- 本周结束日期(周六)
--      @newzbdate = '2025-04-06', -- 新本周开始日期         
--      @newzedate = '2025-04-12' -- 新本周结束日期（周六）

--	  --周日到周六，周日早上导出
--SET @zbdate = '2025-04-06';
--SET @zedate = '2025-04-12';
--SET @newzbdate = '2025-04-06';
--SET @newzedate = '2025-04-12';


ALTER proc [dbo].[usp_s_sumIndexTotal](
     @qxdate datetime, -- 清洗时间
     @zbdate datetime, -- 本周开始日期(周日)
     @zedate datetime, -- 本周结束日期(周六)
     @newzbdate datetime, -- 新本周开始日期         
     @newzedate datetime -- 新本周结束日期（周六）
)
AS
begin 
     -- 判断传递参数是否同当前结果表存储参数一致，如果一致则不做清洗，直接返回结果值
     IF EXISTS (
          SELECT 1 
          FROM [导出一季度指标完成情况] 
          WHERE DATEDIFF(DAY, @qxdate, qxdate) = 0
                AND DATEDIFF(DAY, @zbdate, zbdate) = 0
                AND DATEDIFF(DAY, @zedate, zedate) = 0
                AND DATEDIFF(DAY, @newzbdate, newzbdate) = 0
                AND DATEDIFF(DAY, @newzedate, newzedate) = 0
     )
     BEGIN
          SELECT * 
          FROM [导出一季度指标完成情况] 
          WHERE DATEDIFF(DAY, @qxdate, qxdate) = 0
                AND DATEDIFF(DAY, @zbdate, zbdate) = 0
                AND DATEDIFF(DAY, @zedate, zedate) = 0
                AND DATEDIFF(DAY, @newzbdate, newzbdate) = 0
                AND DATEDIFF(DAY, @newzedate, newzedate) = 0
          RETURN
     END

-- =============================================
-- 1. 日期参数设置
-- =============================================
-- 声明日期变量
-- DECLARE @zbdate DATETIME;    -- 本周开始日期(周日)
-- DECLARE @zedate DATETIME;    -- 本周结束日期(周六)
-- DECLARE @newzbdate DATETIME; -- 本月开始日期
-- DECLARE @newzedate DATETIME; -- 本月当前日期

-- -- 设置日期参数
-- SET @zbdate = ${zbdate};     -- 设置本周开始日期
-- SET @zedate = ${zenddate};   -- 设置本周结束日期
-- SET @newzbdate = ${newzbdate};  -- 设置本月开始日期
-- SET @newzedate = ${newzenddate}; -- 设置本月当前日期


-- --周日到周六，周日早上导出
-- SET @zbdate = '2025-04-06';
-- SET @zedate = '2025-04-12';
-- SET @newzbdate = '2025-04-06';
-- SET @newzedate = '2025-04-12';



-- =============================================
-- 2. 签约数据统计
-- =============================================

-- 2.1 总签约数据
-- 计算本周、本月、一季度、二季度和本年的总签约金额
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       0 num,
       '总签约' 口径,
       SUM(ISNULL(b.本年签约金额, 0) - ISNULL(c.本年签约金额, 0)) / 10000 本周签约金额,
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(e.本年签约金额, 0)) / 10000 新本周签约金额,
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 本月签约金额,
       SUM(ISNULL(f.本年签约金额, 0)) / 10000 一季度签约金额,
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 二季度签约金额,
       SUM(ISNULL(b.本年签约金额, 0)) / 10000 本年签约金额
INTO #sumqy
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zedate) = 1
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b WITH (NOLOCK) ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c WITH (NOLOCK) ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d WITH (NOLOCK) ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e WITH (NOLOCK) ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f WITH (NOLOCK) ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0;


-----————————————————获取成交数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       CASE
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                CASE
                    WHEN a.projguid = '7125EDA8-FCC1-E711-80BA-E61F13C57837' THEN
                         '2'
                    WHEN a.projguid IN ( '7125EDA8-FCC1-E711-80BA-E61F13C57831',
                                         '7125EDA8-FCC1-E711-80BA-E61F13C57831', '7125EDA8-FCC1-E711-80BA-E61F13C57831'
                                       ) THEN
                         '3'
                    WHEN a.projguid = '00730596-95A9-EB11-B398-F40270D39969' THEN
                         '4'
                    ELSE '1'
                END
           WHEN a.产品类型 = '商业' THEN
                '5'
           WHEN a.产品类型 = '公寓' THEN
                '6'
           WHEN a.产品类型 = '写字楼' THEN
                '7'
           WHEN a.产品类型 = '地下室/车库' THEN
                '8'
           ELSE '9'
       END num,
       CASE
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                CASE
                    WHEN a.projguid = '7125EDA8-FCC1-E711-80BA-E61F13C57837' THEN
                         '世博③'
                    WHEN a.projguid IN ( '7125EDA8-FCC1-E711-80BA-E61F13C57831',
                                         '7125EDA8-FCC1-E711-80BA-E61F13C57831', '7125EDA8-FCC1-E711-80BA-E61F13C57831'
                                       ) THEN
                         '广州三项目④'
                    WHEN a.projguid = '00730596-95A9-EB11-B398-F40270D39969' THEN
                         '冼村⑤'
                    ELSE '年初预算住宅②'
                END
           WHEN a.产品类型 = '商业' THEN
                '商业⑥a'
           WHEN a.产品类型 = '公寓' THEN
                '公寓⑥b'
           WHEN a.产品类型 = '写字楼' THEN
                '写字楼⑥c'
           WHEN a.产品类型 = '地下室/车库' THEN
                '车位⑥d'
           ELSE '其他⑥e'
       END 口径,
       SUM(ISNULL(b.本年签约金额, 0) - ISNULL(c.本年签约金额, 0)) / 10000 本周签约金额,  ---临时修改本年签约金额
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(e.本年签约金额, 0)) / 10000 新本周签约金额, ---临时修改本年签约金额
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 本月签约金额,
       SUM(ISNULL(f.本年签约金额, 0)) / 10000 一季度签约金额,
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 二季度签约金额,
       SUM(ISNULL(b.本年签约金额, 0)) / 10000 本年签约金额
INTO #sumqyfenlei
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zedate) = 1
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b WITH (NOLOCK) ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c WITH (NOLOCK) ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d WITH (NOLOCK) ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e WITH (NOLOCK) ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f WITH (NOLOCK) ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
GROUP BY CASE
             WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                  CASE
                      WHEN a.projguid = '7125EDA8-FCC1-E711-80BA-E61F13C57837' THEN
                           '2'
                      WHEN a.projguid IN ( '7125EDA8-FCC1-E711-80BA-E61F13C57831',
                                           '7125EDA8-FCC1-E711-80BA-E61F13C57831',
                                           '7125EDA8-FCC1-E711-80BA-E61F13C57831'
                                         ) THEN
                           '3'
                      WHEN a.projguid = '00730596-95A9-EB11-B398-F40270D39969' THEN
                           '4'
                      ELSE '1'
                  END
             WHEN a.产品类型 = '商业' THEN
                  '5'
             WHEN a.产品类型 = '公寓' THEN
                  '6'
             WHEN a.产品类型 = '写字楼' THEN
                  '7'
             WHEN a.产品类型 = '地下室/车库' THEN
                  '8'
             ELSE '9'
         END,
         CASE
             WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                  CASE
                      WHEN a.projguid = '7125EDA8-FCC1-E711-80BA-E61F13C57837' THEN
                           '世博③'
                      WHEN a.projguid IN ( '7125EDA8-FCC1-E711-80BA-E61F13C57831',
                                           '7125EDA8-FCC1-E711-80BA-E61F13C57831',
                                           '7125EDA8-FCC1-E711-80BA-E61F13C57831'
                                         ) THEN
                           '广州三项目④'
                      WHEN a.projguid = '00730596-95A9-EB11-B398-F40270D39969' THEN
                           '冼村⑤'
                      ELSE '年初预算住宅②'
                  END
             WHEN a.产品类型 = '商业' THEN
                  '商业⑥a'
             WHEN a.产品类型 = '公寓' THEN
                  '公寓⑥b'
             WHEN a.产品类型 = '写字楼' THEN
                  '写字楼⑥c'
             WHEN a.产品类型 = '地下室/车库' THEN
                  '车位⑥d'
             ELSE '其他⑥e'
         END;

-- =============================================
-- 10. 现有可售资源合计 统计
-- =============================================

-----————————————————获取成交数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       10 num,
       '现有可售资源合计' 口径,
       SUM(ISNULL(b.本年签约金额, 0) - ISNULL(c.本年签约金额, 0)) / 10000 本周签约金额,  ---临时修改本年签约金额
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(e.本年签约金额, 0)) / 10000 新本周签约金额, ---临时修改本年签约金额
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 本月签约金额,
       SUM(ISNULL(f.本年签约金额, 0)) / 10000 一季度签约金额,  
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 二季度签约金额,                       ---临时修改本年签约金额
       SUM(ISNULL(b.本年签约金额, 0)) / 10000 本年签约金额
INTO #sumqytotal
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zedate) = 1
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b WITH (NOLOCK) ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c WITH (NOLOCK) ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d WITH (NOLOCK) ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e WITH (NOLOCK) ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f WITH (NOLOCK) ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0;

-----———————————————— 
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       11 num,
       '当年获取当年签约⑧' 口径,
       SUM(ISNULL(b.本年签约金额, 0) - ISNULL(c.本年签约金额, 0)) / 10000 本周签约金额,  ---临时修改本年签约金额
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(e.本年签约金额, 0)) / 10000 新本周签约金额, ---临时修改本年签约金额
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 本月签约金额,
       SUM(ISNULL(f.本月签约金额, 0)) / 10000 一季度签约金额,
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 二季度签约金额,
       SUM(ISNULL(b.本年签约金额, 0)) / 10000 本年签约金额
INTO #sumqydnhuoqu
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zedate) = 1
) a
LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.projguid = mp.projguid
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b WITH (NOLOCK) ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c WITH (NOLOCK) ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d WITH (NOLOCK) ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e WITH (NOLOCK) ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f WITH (NOLOCK) ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
WHERE YEAR(mp.AcquisitionDate) = 2025;

-- =============================================
-- 12. BC赛道盘活转化⑨ 统计
-- =============================================

-----———————————————— 
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       12 num,
       'BC赛道盘活转化⑨' 口径,
       SUM(0) / 10000 本周签约金额,
       SUM(0) / 10000 新本周签约金额,
       SUM(0) / 10000 本月签约金额,
       SUM(0) / 10000 一季度签约金额,
       SUM(0) / 10000 二季度签约金额,
       SUM(0) / 10000 本年签约金额
INTO #sumqybczhuanhua
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily WITH (NOLOCK)
    WHERE DATEDIFF(dd, qxdate, @zedate) = 1
) a
LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.projguid = mp.projguid
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b WITH (NOLOCK) ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c WITH (NOLOCK) ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d WITH (NOLOCK) ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
WHERE YEAR(mp.AcquisitionDate) = 2025;

-- =============================================
-- 13. 全年签约净利率统计
-- =============================================

SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       13 num,
       '全年签约净利率' 口径,
       CASE
           WHEN ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) > 0 THEN
       (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / (ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
           ELSE 0
       END 本周签约金额,
       CASE
           WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0) > 0 THEN
           (ISNULL(c.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0))
           ELSE 0
       END 新本周签约金额,
       CASE
           WHEN ISNULL(c.本月签约金额不含税, 0) > 0 THEN
                ISNULL(c.本月净利润签约, 0) / ISNULL(c.本月签约金额不含税, 0)
           ELSE 0
       END 本月签约金额,
       CASE
           WHEN ISNULL(e.本年签约金额不含税, 0) > 0 THEN
                ISNULL(e.本年净利润签约, 0) / ISNULL(e.本年签约金额不含税, 0)
           ELSE 0
       END 一季度签约金额,
       -- 二季度签约金额取数有问题，暂时用本月签约金额代替
       CASE
           WHEN ISNULL(c.本月签约金额不含税, 0) > 0 THEN
                ISNULL(c.本月净利润签约, 0) / ISNULL(c.本月签约金额不含税, 0)
           ELSE 0
       END 二季度签约金额,
       CASE
           WHEN ISNULL(a.本年签约金额不含税, 0) > 0 THEN
                ISNULL(a.本年净利润签约, 0) / ISNULL(a.本年签约金额不含税, 0)
           ELSE 0
       END 本年销净率
INTO #sumxjl
FROM
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
) a
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
) b ON a.buguid = b.buguid
-- 2025年二季度净利率
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
) c ON a.buguid = c.buguid
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
) d ON a.buguid = d.buguid
-- 2025年一季度净利率
LEFT JOIN 
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
) e ON a.buguid = e.buguid;


-- 其中：-<30%的签约金额(按业态)
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       13 num,
       '其中：-<30%的签约金额(按业态)' 口径,
       isnull(a.本年签约金额,0) -isnull(b.本年签约金额,0)   as 本周签约金额,
       isnull(c.本年签约金额,0) -isnull(d.本年签约金额,0)   as 新本周签约金额,
       isnull(c.本月签约金额,0) as  本月签约金额,
       isnull(e.本年签约金额,0)   as 一季度签约金额,
       -- 二季度签约金额取数有问题，暂时用本月签约金额代替
       isnull(c.本月签约金额,0)   as 二季度签约金额,
       isnull(a.本年签约金额,0)   as 本年签约金额
INTO #LowXjlqy
FROM
(
      SELECT  
     '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
     sum(本月签约金额) as 本月签约金额,
     sum(本年签约金额) as 本年签约金额
     FROM
     (
     SELECT ProjGUID,
               产品类型,
               SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额,
               SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额,
               CASE
                    WHEN SUM(本年签约金额不含税) <> 0 THEN
                         SUM(本年净利润签约) / SUM(本年签约金额不含税)
                    ELSE 0
               END 本年销净率
     FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
     WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
     GROUP BY ProjGUID,
               产品类型
     ) t
     WHERE t.本年销净率 < -0.3
) a 
LEFT JOIN
(
     SELECT  
     '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
     sum(本月签约金额) as 本月签约金额,
     sum(本年签约金额) as 本年签约金额
     FROM
     (
     SELECT ProjGUID,
               产品类型,
               SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额,
               SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额,
               CASE
                    WHEN SUM(本年签约金额不含税) <> 0 THEN
                         SUM(本年净利润签约) / SUM(本年签约金额不含税)
                    ELSE 0
               END 本年销净率
     FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
     WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
     GROUP BY ProjGUID,
               产品类型
     ) t
     WHERE t.本年销净率 < -0.3
) b ON a.buguid = b.buguid
-- 2025年二季度净利率
LEFT JOIN
(
     SELECT  
     '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
     sum(本月签约金额) as 本月签约金额,
     sum(本年签约金额) as 本年签约金额
     FROM
     (
     SELECT ProjGUID,
               产品类型,
               SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额,
               SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额,
               CASE
                    WHEN SUM(本年签约金额不含税) <> 0 THEN
                         SUM(本年净利润签约) / SUM(本年签约金额不含税)
                    ELSE 0
               END 本年销净率
     FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
     WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
     GROUP BY ProjGUID,
               产品类型
     ) t
     WHERE t.本年销净率 < -0.3
) c ON a.buguid = c.buguid
LEFT JOIN
(
     SELECT  
     '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
     sum(本月签约金额) as 本月签约金额,
     sum(本年签约金额) as 本年签约金额
     FROM
     (
     SELECT ProjGUID,
               产品类型,
               SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额,
               SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额,
               CASE
                    WHEN SUM(本年签约金额不含税) <> 0 THEN
                         SUM(本年净利润签约) / SUM(本年签约金额不含税)
                    ELSE 0
               END 本年销净率
     FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
     WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
     GROUP BY ProjGUID,
               产品类型
     ) t
     WHERE t.本年销净率 < -0.3
) d ON a.buguid = d.buguid
-- 2025年一季度净利率
LEFT JOIN 
(
     SELECT  
     '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
     sum(本月签约金额) as 本月签约金额,
     sum(本年签约金额) as 本年签约金额
     FROM
     (
     SELECT ProjGUID,
               产品类型,
               SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额,
               SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额,
               CASE
                    WHEN SUM(本年签约金额不含税) <> 0 THEN
                         SUM(本年净利润签约) / SUM(本年签约金额不含税)
                    ELSE 0
               END 本年销净率
     FROM s_M002项目级毛利净利汇总表New WITH (NOLOCK)
     WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
     GROUP BY ProjGUID,
               产品类型
     ) t
     WHERE t.本年销净率 < -0.3
) e ON a.buguid = e.buguid;



-- =============================================
-- 14. 营销费率 统计
-- =============================================
--————————————————————————————营销费用————————————————————————————————

--年度预算&年度发生（费用签约）已筛公司、预算范围			
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(FactAmount1 + FactAmount2 + FactAmount3 ) / 100000000 AS '一季度已发生费用',
       SUM(FactAmount4) / 100000000 AS '二季度已发生费用',
       SUM(FactAmount1 + FactAmount2 + FactAmount3 +FactAmount4) / 100000000 AS '本年已发生费用'
--SUM(FactAmount1 + FactAmount2 + FactAmount3 + FactAmount4 + FactAmount5 + FactAmount6 + FactAmount7
--    + FactAmount8 + FactAmount9 + FactAmount10 + FactAmount11 + FactAmount12
--   ) / 100000000 AS '本年已发生费用'
INTO #fy
FROM MyCost_Erp352.dbo.ys_YearPlanDept2Cost a WITH (NOLOCK)
     INNER JOIN MyCost_Erp352.dbo.ys_DeptCost b WITH (NOLOCK) ON b.DeptCostGUID = a.costguid
                                                   AND a.YEAR = b.YEAR
     INNER JOIN MyCost_Erp352.dbo.ys_SpecialBusinessUnit u WITH (NOLOCK) ON a.DeptGUID = u.SpecialUnitGUID
     INNER JOIN MyCost_Erp352.dbo.ys_fy_DimCost dim WITH (NOLOCK) ON dim.costguid = a.costguid
                                                       AND dim.year = a.year
                                                       AND dim.IsEndCost = 1
WHERE a.year = YEAR(GETDATE())
      AND b.costtype = '营销类';


SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       14 num,
       '营销费率' 口径,
       0 本周费率,
       0 新本周费率,
       0 本月费率,
       CASE
           WHEN q.一季度签约金额 > 0 THEN
                f.[一季度已发生费用] / q.一季度签约金额
           ELSE 0
       END 一季度费率,
       CASE
           WHEN q.二季度签约金额 > 0 THEN
                f.[二季度已发生费用] / q.二季度签约金额
           ELSE 0
       END 二季度费率,
       CASE
           WHEN q.本年签约金额 > 0 THEN
                f.[本年已发生费用] / q.本年签约金额
           ELSE 0
       END 本年费率
INTO #sumfeiyong
FROM mybusinessunit bu WITH (NOLOCK)
     LEFT JOIN #fy f ON bu.buguid = f.buguid
     LEFT JOIN #sumqy q ON bu.buguid = q.buguid
WHERE bu.buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23';

-- =============================================
-- 15. 期初在建面积统计
-- =============================================

--取本周新开工的项目
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       15 num,
       '期初在建面积' 口径,
       SUM(   CASE
                  WHEN DATEDIFF(dd, 实际开工实际完成时间, @zbdate) > 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 - SUM(   CASE
                                 WHEN DATEDIFF(dd, 竣工备案实际完成时间, @zbdate) > 0 THEN
                                      计划组团建筑面积
                                 ELSE 0
                             END
                         ) / 10000 本周,
       SUM(   CASE
                  WHEN DATEDIFF(dd, 实际开工实际完成时间, @newzbdate) > 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 - SUM(   CASE
                                 WHEN DATEDIFF(dd, 竣工备案实际完成时间, @newzbdate) > 0 THEN
                                      计划组团建筑面积
                                 ELSE 0
                             END
                         ) / 10000 新本周,
       SUM(   CASE
                  WHEN DATEDIFF(dd, 实际开工实际完成时间, '2025-04-01') > 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 - SUM(   CASE
                                 WHEN DATEDIFF(dd, 竣工备案实际完成时间, '2025-04-01') > 0 THEN
                                      计划组团建筑面积
                                 ELSE 0
                             END
                         ) / 10000 本月,
       SUM(   CASE
                  WHEN DATEDIFF(dd, 实际开工实际完成时间, '2025-01-01') > 0  THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 - SUM(   CASE
                                 WHEN DATEDIFF(dd, 竣工备案实际完成时间, '2025-01-01') > 0 THEN
                                      计划组团建筑面积
                                 ELSE 0
                             END
                         ) / 10000 一季度,
       SUM(   CASE
                  WHEN DATEDIFF(dd, 实际开工实际完成时间, '2025-04-01') > 0  THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 - SUM(   CASE
                                 WHEN DATEDIFF(dd, 竣工备案实际完成时间, '2025-04-01') > 0 THEN
                                      计划组团建筑面积
                                 ELSE 0
                             END
                         ) / 10000 二季度,
       SUM(   CASE
                  WHEN DATEDIFF(dd, 实际开工实际完成时间, '2025-01-01') > 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 - SUM(   CASE
                                 WHEN DATEDIFF(dd, 竣工备案实际完成时间, '2025-01-01') > 0 THEN
                                      计划组团建筑面积
                                 ELSE 0
                             END
                         ) / 10000 本年
INTO #sumqichuzaijiankg
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport] a WITH (NOLOCK)
     LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.topprojguid = mp.projguid
WHERE mp.ProjStatus IN ( '正常', '跟进待落实', '正常(拟退出)' )
      AND mp.ManageModeName NOT IN ( '代建', '代管' );



-- =============================================
-- 16. 新开工面积统计
-- =============================================

--取本周新开工的项目
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       16 num,
       '新开工面积' 口径,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @zbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @newzbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @newzedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 新本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(mm, 实际开工实际完成时间, @newzedate) = 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本月开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, '2025-04-01') > 0  THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 一季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(dd, '2025-04-01', 实际开工实际完成时间) >= 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0  THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 二季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0  THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本年开工金额   --0209修改
INTO #sumxinkg
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport] a WITH (NOLOCK)
     LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.topprojguid = mp.projguid
WHERE mp.ProjStatus IN ( '正常', '跟进待落实', '正常(拟退出)' )
      AND mp.ManageModeName NOT IN ( '代建', '代管' );


-- =============================================
-- 16. 增加新开工：21年及以前、22&23、24年及以后获
-- =============================================
--增加新开工：21年及以前、22&23、24年及以后获
--取本周新开工的项目
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       CASE
           WHEN YEAR(AcquisitionDate) >= 2024 THEN
                '16'
           WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                '16'
           ELSE '16'
       END num,
       CASE
           WHEN YEAR(AcquisitionDate) >= 2024 THEN
                '新开工面积24年及之后获取'
           WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                '新开工面积22年23年获取'
           ELSE '新开工面积21年及之前获取'
       END 口径,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @zbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @newzbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @newzedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 新本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(mm, 实际开工实际完成时间, @newzedate) = 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本月开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0
					   AND DATEDIFF(dd, 实际开工实际完成时间, '2025-04-01') > 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 一季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(dd, '2025-04-01', 实际开工实际完成时间) >= 0
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 二季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本年开工金额   --0209修改
INTO #sumxinkgchaifen
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport] a WITH (NOLOCK)
     LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.topprojguid = mp.projguid
WHERE mp.ProjStatus IN ( '正常', '跟进待落实', '正常(拟退出)' )
      AND mp.ManageModeName NOT IN ( '代建', '代管' )
GROUP BY CASE
             WHEN YEAR(AcquisitionDate) >= 2024 THEN
                  '16'
             WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                  '16'
             ELSE '16'
         END,
         CASE
             WHEN YEAR(AcquisitionDate) >= 2024 THEN
                  '新开工面积24年及之后获取'
             WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                  '新开工面积22年23年获取'
             ELSE '新开工面积21年及之前获取'
         END;


-- =============================================
-- 17. 地上新开工面积 统计
-- =============================================

--取本周新开工的项目
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       17 num,
       '地上新开工面积' 口径,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @zbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @newzbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @newzedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 新本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(mm, 实际开工实际完成时间, @newzedate) = 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 本月开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, '2025-04-01') > 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 一季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(dd, '2025-04-01', 实际开工实际完成时间) >= 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 二季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 本年开工金额   --0209修改
INTO #sumxinkgdishang
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport] a WITH (NOLOCK)
     LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.topprojguid = mp.projguid
WHERE mp.ProjStatus IN ( '正常', '跟进待落实', '正常(拟退出)' )
      AND mp.ManageModeName NOT IN ( '代建', '代管' );

---新开工拆分
--取本周新开工的项目
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       CASE
           WHEN YEAR(AcquisitionDate) >= 2024 THEN
                '17'
           WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                '17'
           ELSE '17'
       END num,
       CASE
           WHEN YEAR(AcquisitionDate) >= 2024 THEN
                '地上新开工面积24年及之后获取'
           WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                '地上新开工面积22年23年获取'
           ELSE '地上新开工面积21年及之前获取'
       END 口径,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @zbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @newzbdate, 实际开工实际完成时间) >= 0
                       AND DATEDIFF(dd, 实际开工实际完成时间, @newzedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 新本周开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(mm, 实际开工实际完成时间, @newzedate) = 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 本月开工金额,
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, '2025-04-01') > 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 一季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(dd, '2025-04-01', 实际开工实际完成时间) >= 0 
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 二季度开工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(yy, 实际开工实际完成时间, @zedate) = 0  
					   AND DATEDIFF(dd, 实际开工实际完成时间, @zedate) >= 0 THEN
                       地上面积
                  ELSE 0
              END
          ) / 10000 本年开工金额   --0209修改
INTO #sumxinkgdishangchaifen
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport] a WITH (NOLOCK)
     LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.topprojguid = mp.projguid
WHERE mp.ProjStatus IN ( '正常', '跟进待落实', '正常(拟退出)' )
      AND mp.ManageModeName NOT IN ( '代建', '代管' )
GROUP BY CASE
             WHEN YEAR(AcquisitionDate) >= 2024 THEN
                  '17'
             WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                  '17'
             ELSE '17'
         END,
         CASE
             WHEN YEAR(AcquisitionDate) >= 2024 THEN
                  '地上新开工面积24年及之后获取'
             WHEN YEAR(AcquisitionDate) IN ( '2022', '2023' ) THEN
                  '地上新开工面积22年23年获取'
             ELSE '地上新开工面积21年及之前获取'
         END;

-- =============================================
-- 18. 竣工面积 统计
-- =============================================

SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       18 num,
       '竣工面积' 口径,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @zbdate, 竣工备案实际完成时间) >= 0
                       AND DATEDIFF(dd, 竣工备案实际完成时间, @zedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本周竣工金额,
       SUM(   CASE
                  WHEN DATEDIFF(dd, @newzbdate, 竣工备案实际完成时间) >= 0
                       AND DATEDIFF(dd, 竣工备案实际完成时间, @newzedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 新本周竣工金额,
       SUM(   CASE
                  WHEN DATEDIFF(mm, 竣工备案实际完成时间, @newzedate) = 0 
                       AND DATEDIFF(dd, 竣工备案实际完成时间, @newzedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本月竣工金额,
       SUM(   CASE
                  WHEN DATEDIFF(yy, 竣工备案实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 竣工备案实际完成时间, '2025-04-01') > 0THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 一季度竣工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(dd, '2025-04-01', 竣工备案实际完成时间) >= 0 
					   AND DATEDIFF(dd, 竣工备案实际完成时间, @zedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 二季度竣工金额, --0209修改
       SUM(   CASE
                  WHEN DATEDIFF(yy, 竣工备案实际完成时间, @zedate) = 0 
					   AND DATEDIFF(dd, 竣工备案实际完成时间, @zedate) >= 0 THEN
                       计划组团建筑面积
                  ELSE 0
              END
          ) / 10000 本年竣工金额   --0209修改
INTO #sumxinjungongbeian
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport] a WITH (NOLOCK)
     LEFT JOIN mdm_project mp WITH (NOLOCK) ON a.topprojguid = mp.projguid
WHERE mp.ProjStatus IN ( '正常', '跟进待落实', '正常(拟退出)' )
      AND mp.ManageModeName NOT IN ( '代建', '代管' );



-- =============================================
-- 19. 除地价外直投 统计
-- =============================================
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       19 num,
       '除地价外直投' 口径,
       '' 本周总投资,
       '' 新本周总投资,
       [本月总投资（万元）] 本月总投资,
       [本年总投资（万元）] 一季度总投资, ---0209临时修改语句
       [本年总投资（万元）] 二季度总投资, ---0209临时修改语句
       [本年总投资（万元）] 本年
INTO #sumcdjwai
FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a WITH (NOLOCK)
     INNER JOIN
     (
         SELECT TOP 1
                a.FillHistoryGUID
         FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a WITH (NOLOCK)
              INNER JOIN dss.dbo.nmap_F_FillHistory b WITH (NOLOCK) ON a.FillHistoryGUID = b.FillHistoryGUID
         WHERE b.ApproveStatus = '已审核'
         ORDER BY b.BeginDate DESC
     ) F ON F.FillHistoryGUID = a.FillHistoryGUID;


-- =============================================
-- 20. 交付套数  21操盘交付套数 统计
-- =============================================
-- 获取2025年住宅和高级住宅的激活状态交易
SELECT DISTINCT
       a.tradeguid,
       a.JyTotal,
       a.status
INTO #trade
FROM s_contract a WITH (NOLOCK)
     INNER JOIN ep_room r WITH (NOLOCK) ON a.RoomGUID = r.RoomGUID
WHERE a.status = '激活'
      AND YEAR(a.jfdate) = 2025
      AND r.ProductType IN ('住宅', '高级住宅');

-- 创建索引以提升后续查询性能
CREATE INDEX IX_trade_tradeguid ON #trade(tradeguid);

-- =============================================
-- 3. 计算回款数据
-- =============================================
-- 获取每个交易的回款总额(不含补差款)
SELECT r.TradeGUID,
       SUM(g.Amount) 截止入参回款
INTO #getin
FROM s_Getin g WITH (NOLOCK)
     INNER JOIN #trade r ON g.SaleGUID = r.TradeGUID
WHERE g.ItemType IN ('贷款类房款', '非贷款类房款')
      AND g.ItemName NOT IN ('房款补差款')
      AND ISNULL(g.status, '') <> '作废'
      AND g.GetDate <= GETDATE()
GROUP BY r.TradeGUID;

-- 创建索引以提升后续查询性能
CREATE INDEX IX_getin_tradeguid ON #getin(TradeGUID);

-- 获取每个交易的补差款总额
SELECT v.TradeGUID,
       SUM(CASE
               WHEN ItemName LIKE '%补差%' THEN Amount
               ELSE 0
           END) bck
INTO #fee
FROM s_Fee s WITH (NOLOCK)
     INNER JOIN #trade v ON s.TradeGUID = v.TradeGUID
WHERE s.ItemType = '非贷款类房款'
GROUP BY v.TradeGUID;

-- 创建索引以提升后续查询性能
CREATE INDEX IX_fee_tradeguid ON #fee(TradeGUID);

-- =============================================
-- 4. 判断交易是否款清
-- =============================================
-- 判断每个交易是否款清
SELECT a.TradeGUID,
       CASE
           -- 补差款>=0时,回款>=交易总额即为款清
           WHEN ISNULL(g.截止入参回款, 0) >= ISNULL(a.JyTotal, 0)
                AND ISNULL(g.截止入参回款, 0) > 0
                AND ISNULL(f.bck, 0) >= 0 
           THEN '是'
           -- 补差款<0时(需退款),回款>=交易总额+补差款即为款清
           WHEN ISNULL(g.截止入参回款, 0) >= (ISNULL(a.JyTotal, 0) + ISNULL(f.bck, 0))
                AND ISNULL(g.截止入参回款, 0) > 0
                AND ISNULL(f.bck, 0) < 0
           THEN '是'
           ELSE '否'
       END 是否款清
INTO #trade_kq
FROM #trade a
     LEFT JOIN #getin g ON a.TradeGUID = g.TradeGUID
     LEFT JOIN #fee f ON f.TradeGUID = a.TradeGUID;

-- 创建索引以提升后续查询性能
CREATE INDEX IX_trade_kq_tradeguid ON #trade_kq(TradeGUID);
CREATE INDEX IX_trade_kq_是否款清 ON #trade_kq(是否款清);

-- =============================================
-- 5. 统计交付套数
-- =============================================
-- 统计不同时间维度的交付套数
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       20 num,
       '交付套数' 口径,
       -- 本周交付套数
       SUM(CASE
               WHEN c.jfdate BETWEEN @zbdate AND @zedate THEN 1
               ELSE 0
           END) 本周应交付套数,
       -- 新本周交付套数  
       SUM(CASE
               WHEN c.jfdate BETWEEN @newzbdate AND @newzedate THEN 1
               ELSE 0
           END) 新本周应交付套数,
       -- 本月交付套数
       SUM(CASE
               WHEN YEAR(c.jfdate) = YEAR(@newzedate) 
                    AND MONTH(c.jfdate) = MONTH(@newzedate) THEN 1
               ELSE 0
           END) 本月应交付套数,
       -- 一季度交付套数
       SUM(CASE
               WHEN YEAR(c.jfdate) = 2025 
                    AND c.jfdate > '2025-04-01' THEN 1
               ELSE 0
           END) 一季度应交付套数,
       -- 二季度交付套数  
       SUM(CASE
               WHEN YEAR(c.jfdate) = 2025 
                    AND DATEPART(QUARTER, c.jfdate) = 2 THEN 1
               ELSE 0
           END) 二季度应交付套数,
       -- 本年交付套数
       SUM(CASE
               WHEN YEAR(c.jfdate) = 2025 THEN 1
               ELSE 0
           END) 本年应交付套数
INTO #sumjf
FROM s_contract c WITH (NOLOCK)
     INNER JOIN #trade_kq t ON c.TradeGUID = t.TradeGUID
WHERE t.是否款清 = '是'
      AND c.status = '激活';

-- =============================================
-- 6. 统计操盘交付套数
-- =============================================
-- 统计不同时间维度的操盘交付套数（仅统计保利操盘项目）
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       21 num,
       '操盘交付套数' 口径,
       -- 本周操盘交付套数
       SUM(CASE
               WHEN c.jfdate BETWEEN @zbdate AND @zedate THEN 1
               ELSE 0
           END) 本周应交付套数,
       -- 新本周操盘交付套数
       SUM(CASE
               WHEN c.jfdate BETWEEN @newzbdate AND @newzedate THEN 1
               ELSE 0
           END) 新本周应交付套数,
       -- 本月操盘交付套数
       SUM(CASE
               WHEN YEAR(c.jfdate) = YEAR(@newzedate) 
                    AND MONTH(c.jfdate) = MONTH(@newzedate) THEN 1
               ELSE 0
           END) 本月应交付套数,
       -- 一季度操盘交付套数
       SUM(CASE
               WHEN YEAR(c.jfdate) = 2025 
                    AND c.jfdate > '2025-04-01' THEN 1
               ELSE 0
           END) 一季度应交付套数,
       -- 二季度操盘交付套数
       SUM(CASE
               WHEN YEAR(c.jfdate) = 2025 
                    AND DATEPART(QUARTER, c.jfdate) = 2 THEN 1
               ELSE 0
           END) 二季度应交付套数,
       -- 本年操盘交付套数
       SUM(CASE
               WHEN YEAR(c.jfdate) = 2025 THEN 1
               ELSE 0
           END) 本年应交付套数
INTO #sumjfcp
FROM s_contract c WITH (NOLOCK)
     INNER JOIN #trade_kq t ON c.TradeGUID = t.TradeGUID
     INNER JOIN p_project p WITH (NOLOCK) ON c.projguid = p.projguid
     INNER JOIN p_project p1 WITH (NOLOCK) ON p.parentcode = p1.projcode
                               AND p1.applysys LIKE '%0101%'
     INNER JOIN mdm_project mp WITH (NOLOCK) ON p1.projguid = mp.projguid
WHERE t.是否款清 = '是'
      AND c.status = '激活'
      AND mp.Kgcpf LIKE '%保利%';


-- =============================================
-- 8. 结果合并和排序
-- =============================================
-- 合并所有统计结果并按num和口径排序
-- 合并顺序说明:
-- 1. #sumqy: 总签约数据
-- 2. #sumqyfenlei: 分类签约数据(按产品类型和项目分类)
-- 3. #sumqybczhuanhua: BC赛道盘活转化数据
-- 4. #sumqydnhuoqu: 当年获取当年签约数据
-- 5. #sumqytotal: 现有可售资源合计
-- 6. #sumxjl: 销售净利率数据
-- 7. #LowXjlqy: 销售净利率小于-30%的签约金额
-- 8. #sumqichuzaijiankg: 期初在建面积数据
-- 9. #sumxinkgdishang: 地上新开工面积数据
-- 10. #sumxinkgdishangchaifen: 地上新开工面积按获取年份分类数据
-- 11. #sumxinkg: 新开工面积数据
-- 12. #sumxinkgchaifen: 新开工面积按获取年份分类数据
-- 13. #sumxinjungongbeian: 竣工面积数据
-- 14. #sumjf: 交付套数数据
-- 15. #sumfeiyong: 营销费用数据
-- 16. #sumjfcp: 操盘交付套数数据

-- 为避免清洗时间重复，将清洗时间重复的数据清除掉
truncate table [dbo].[导出一季度指标完成情况] 

-- 插入合并后的数据
INSERT INTO [dbo].[导出一季度指标完成情况]
SELECT * 
FROM (
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumqy                      -- 总签约数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumqyfenlei               -- 分类签约数据(按产品类型和项目分类)
    UNION 
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumqybczhuanhua           -- BC赛道盘活转化数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumqydnhuoqu              -- 当年获取当年签约数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumqytotal                -- 现有可售资源合计
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumxjl 
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #LowXjlqy                   -- 销售净利率数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumqichuzaijiankg         -- 期初在建面积数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumxinkgdishang           -- 地上新开工面积数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumxinkgdishangchaifen    -- 地上新开工面积按获取年份分类数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumxinkg                  -- 新开工面积数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumxinkgchaifen           -- 新开工面积按获取年份分类数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumxinjungongbeian        -- 竣工面积数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumjf                     -- 交付套数数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumfeiyong                -- 营销费用数据
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate, * FROM #sumjfcp                   -- 操盘交付套数数据
) a
-- 按num和口径排序，确保数据展示的层次性和可读性
-- num字段用于控制主要类别的排序
-- 口径字段用于控制同一类别下的子项排序
ORDER BY a.num, 口径;

-- 输出仓结果
SELECT * 
FROM [导出一季度指标完成情况]
WHERE DATEDIFF(DAY, qxdate, @qxdate) = 0
      AND DATEDIFF(DAY, @zbdate, zbdate) = 0
      AND DATEDIFF(DAY, @zedate, zedate) = 0
      AND DATEDIFF(DAY, @newzbdate, newzbdate) = 0
      AND DATEDIFF(DAY, @newzedate, newzedate) = 0

-- =============================================
-- 9. 清理临时表
-- =============================================
-- 删除所有临时表，释放数据库资源
DROP TABLE #sumcdjwai,
         #sumqichuzaijiankg,
         #sumqy,
         #sumqybczhuanhua,
         #sumqydnhuoqu,
         #sumqyfenlei,
         #sumqytotal,
         #sumxinjungongbeian,
         #sumxinkg, 
         #sumxinkgchaifen,
         #sumxinkgdishang,
         #sumxinkgdishangchaifen,
         #sumxjl,
         #LowXjlqy,
         #fy,
         #sumfeiyong,
         #sumjf,
         #trade,
         #trade_kq,
         #fee,
         #getin,
         #sumjfcp;

END 