-- 第三部分: 总认购数据获取
-- 与总签约数据结构类似，但计算的是认购数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,  -- 业务单元GUID
       '总认购' 口径,                                    -- 指标口径名称
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, -- 计算新口径本周认购金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,                              -- 计算本月认购金额
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 二季度签约金额, -- 计算二季度认购金额（本年累计-一季度累计）
INTO #sumrg  -- 将结果存入临时表#sumrg
(
    SELECT projguid,
           首推日期
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1  -- 筛选本周开始日期前一天的数据
    SELECT projguid,
           首推日期
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0  -- 筛选本周结束日期当天的数据
-- 关联本周末数据
                                          AND a.产品类型 = b.产品类型
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0  -- 匹配本周末数据
-- 关联本周初数据
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
-- 关联新口径本周末数据qxdate, @zbdate) = 1  -- 匹配本周初数据（前一天）
                                          AND a.产品类型 = d.产品类型
                                          A D DA EDIFF(dd, d.qx  te, @newze ate) = 0 (--.匹配新口径本周末数据= ISNULL(d.首推日期, '')
-- 关联新口径本周初数据
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
-- 关联一季度末数据
                                          AND a.产品类型 = f.产品类型
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0  -- 匹配一季度末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
-- 关联上周初数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.pao产品类型sc.产品类型
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1;  -- 匹配上周初数据（前一天）
-- 第四部分: 首开项目数据处理
-- 创建临时表存储首开项目信息，用于后续分析
select pp.projguid, min(QSDate) skdate
into #skp  -- 创建临时表存储项目首开日期
left join p_Project p on pp.ProjCode = p.ParentCode
where pp.ApplySys like '%0101%'  -- 筛选特定系统的项目

select f.ProjGUID, p.skdate 
from vmdm_projectFlag f 
where p.skdate >= '2025-01-01';  -- 筛选2025年1月