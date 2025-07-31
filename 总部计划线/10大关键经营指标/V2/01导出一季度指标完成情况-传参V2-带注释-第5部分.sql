-- 第七部分: 产品类型数据获取
-- 按产品类型（住宅、商业、公寓、写字楼、车位、其他）分类获取认购数据
       -- 根据产品类型设置序号
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN '3'  -- 住宅类产品
           WHEN a.产品类型 = '商业' THEN '5'                   -- 商业类产品
           WHEN a.产品类型 = '地下室/车库' THEN '8'            -- 车位类产品
           ELSE '9'                                           -- 其他类产品
       CASE
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN '住宅'
           WHEN a.产品类型 = '写字楼' THEN '写字楼'
           ELSE '其他'
       END 口径,
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, -- 计算新口径本周认购金额
       round(cast(SUM(ISNULL(db.月年认购金额, 00)) / 10000.00 as decimal(18,4)),4)月上周签约金 额,                            -- 计算月周认购金额
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,                            -- 计算一季度认购金额
INTO #sumqyfenlei  -- 将结果存入临时表#sumqyfenlei

    -- 子查询：获取项目基础信息，合并两个日期的数据以确保完整性
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    SELECT projguid,
           首推日期  产品类型,
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
-- 关联本周末数据
                                          ANDEF.产品类型 = b.产品类型T JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0  -- 匹配本周末数据
-- 关联本周初数据
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
-- 关联新口径本周末数据
                                          AND a.产品类型 = d.产品类型
-- 关联新口径本周初数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
-- 关联一季度末数据
                                          AND a.产品类型 = f.产品类型
-- 关联上周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
-- 关联上周初数据
                                          AND a.产品类型 = sc.产品类型
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1  -- 匹配上周初数据（前一天）
GROUP BY CASE
           WHEN a.     = '商业' THEN '5' WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN '3'
           WHEN a.产品类型 = '写字楼' THEN '7'
           ELS'TH9N '8'
       CASE
           WH   a.产品类型 = '商业' THEN '商业'HEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN '住宅'
           WHEN a.产品类型 = '写字楼' THEN '写字楼'
           ELSE '其他'
       END;