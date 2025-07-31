/*
==============================================
脚本名称: 01导出一季度指标完成情况-传参V2-带注释
功能描述: 该脚本用于导出和计算关键经营指标的完成情况，包括签约、认购、净利率等多项指标
适用范围: 总部计划线 - 10大关键经营指标分析
==============================================
*/

-- =============================================
-- 第一部分: 变量声明与初始化
-- 定义各种日期参数，用于后续查询的时间范围控制
-- =============================================
DECLARE @zbdate DATETIME;     -- 周开始日期
DECLARE @zedate DATETIME;     -- 周结束日期
DECLARE @newzbdate DATETIME;  -- 新周开始日期
DECLARE @newzedate DATETIME;  -- 新周结束日期
DECLARE @szbdate DATETIME;    -- 上周开始日期
DECLARE @szedate DATETIME;    -- 上周结束日期

-- 设置日期参数值（周日到周六，周日早上导出）
SET @zbdate = '2025-07-07';    -- 本周开始日期
SET @zedate = '2025-07-13';    -- 本周结束日期
SET @newzbdate = '2025-07-07'; -- 新本周开始日期
SET @newzedate = '2025-07-13'; -- 新本周结束日期
SET @szbdate = '2025-06-30';   -- 上周开始日期
SET @szedate = '2025-07-06';   -- 上周结束日期

-- 注意：到3月份时，FactAmount1+ FactAmount2需要加上FactAmount3

-- =============================================
-- 第二部分: 总签约数据获取
-- 计算总签约金额相关指标，包括本周、本月、季度等多个时间维度
-- =============================================
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,  -- 业务单元GUID
       10 num,                                          -- 序号，用于最终结果排序
       '总签约' 口径,                                    -- 指标口径名称
       SUM(ISNULL(b.本年签约金额, 0) - ISNULL(c.本年签约金额, 0)) / 10000 本周签约金额,  -- 计算本周签约金额（本周末累计-本周初累计）
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(e.本年签约金额, 0)) / 10000 新本周签约金额, -- 计算新口径本周签约金额
       SUM(ISNULL(sb.本年签约金额, 0) - ISNULL(sc.本年签约金额, 0)) / 10000 上周签约金额, -- 计算上周签约金额
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 本月签约金额,                              -- 计算本月签约金额
       SUM(ISNULL(f.本年签约金额, 0)) / 10000 一季度签约金额,                            -- 计算一季度签约金额
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(f.本年签约金额, 0)) / 10000 二季度签约金额, -- 计算二季度签约金额（本年累计-一季度累计）
       SUM(ISNULL(b.本年签约金额, 0)) / 10000 本年签约金额                               -- 计算本年累计签约金额
INTO #sumqy  -- 将结果存入临时表#sumqy
FROM
(
    -- 子查询：获取项目基础信息，合并两个日期的数据以确保完整性
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1  -- 筛选本周开始日期前一天的数据
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0  -- 筛选本周结束日期当天的数据
) a
-- 关联本周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0  -- 匹配本周末数据
-- 关联本周初数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1  -- 匹配本周初数据（前一天）
-- 关联新口径本周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0  -- 匹配新口径本周末数据
-- 关联新口径本周初数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1  -- 匹配新口径本周初数据（前一天）
-- 关联一季度末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0  -- 匹配一季度末数据
-- 关联上周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0  -- 匹配上周末数据
-- 关联上周初数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.产品类型 = sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1;  -- 匹配上周初数据（前一天）