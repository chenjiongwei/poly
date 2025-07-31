-- =============================================
-- 第十一部分: 营销费用数据处理
-- 计算营销费用相关指标
-- =============================================
-- 年度预算&年度发生（费用签约）已筛公司、预算范围
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       -- 计算一季度已发生费用（单位：亿元）
       SUM(FactAmount1 + FactAmount2 + FactAmount3 ) / 100000000 AS '一季度已发生费用',
       -- 计算二季度已发生费用
       SUM(FactAmount4 + FactAmount5) / 100000000 AS '二季度已发生费用',
       -- 计算本年已发生费用
       SUM(FactAmount1 + FactAmount2 + FactAmount3 +FactAmount4 +FactAmount5) / 100000000 AS '本年已发生费用'
       /* 全年12个月费用计算（注释掉）
       SUM(FactAmount1 + FactAmount2 + FactAmount3 + FactAmount4 + FactAmount5 + FactAmount6 + FactAmount7
           + FactAmount8 + FactAmount9 + FactAmount10 + FactAmount11 + FactAmount12
          ) / 100000000 AS '本年已发生费用'
       */
INTO #fy  -- 将结果存入临时表#fy
FROM MyCost_Erp352.dbo.ys_YearPlanDept2Cost a
     -- 关联部门费用表
     INNER JOIN MyCost_Erp352.dbo.ys_DeptCost b ON b.DeptCostGUID = a.costguid
                                                   AND a.YEAR = b.YEAR
     -- 关联业务单元表
     INNER JOIN MyCost_Erp352.dbo.ys_SpecialBusinessUnit u ON a.DeptGUID = u.SpecialUnitGUID
     -- 关联费用维度表
     INNER JOIN MyCost_Erp352.dbo.ys_fy_DimCost dim ON dim.costguid = a.costguid
                                                       AND dim.year = a.year
                                                       AND dim.IsEndCost = 1  -- 仅统计最终费用
WHERE a.year = YEAR(GETDATE())  -- 当前年份
      AND b.costtype = '营销类';  -- 仅统计营销类费用

-- =============================================
-- 第十二部分: 营销费率计算
-- 计算营销费用与签约金额的比率
-- =============================================
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       11 num,                                          -- 序号，用于最终结果排序
       '营销费率' 口径,                                  -- 指标口径名称
       0 本周费率,                                      -- 本周费率（暂未计算）
       0 新本周费率,                                     -- 新本周费率（暂未计算）
       0 上周费率,                                      -- 上周费率（暂未计算）
       0 本月费率,                                      -- 本月费率（暂未计算）
       -- 计算一季度营销费率：一季度营销费用/一季度签约金额
       CASE
           WHEN q.一季度签约金额 > 0 THEN
                f.[一季度已发生费用] / q.一季度签约金额
           ELSE 0
       END 一季度费率,
       -- 计算二季度营销费率：二季度营销费用/二季度签约金额
       CASE
           WHEN q.二季度签约金额 > 0 THEN
                f.[二季度已发生费用] / q.二季度签约金额
           ELSE 0
       END 二季度费率,
       -- 计算本年营销费率：本年营销费用/本年签约金额
       CASE
           WHEN q.本年签约金额 > 0 THEN
                f.[本年已发生费用] / q.本年签约金额
           ELSE 0
       END 本年费率
INTO #sumfeiyong  -- 将结果存入临时表#sumfeiyong
FROM mybusinessunit bu
     -- 关联营销费用数据
     LEFT JOIN #fy f ON bu.buguid = f.buguid
     -- 关联总签约数据
     LEFT JOIN #sumqy q ON bu.buguid = q.buguid
WHERE bu.buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23';  -- 筛选特定业务单元

-- =============================================
-- 第十三部分: 产成品数据处理
-- 计算21年及以前获取项目的产成品认购数据
-- =============================================
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'2' num,                                         -- 序号，用于最终结果排序
		'其中：21年及以前获取项目产成品认购' 口径,        -- 指标口径名称
		sum(BzJe)/100000000 本周金额,                    -- 计算本周认购金额（单位：亿元）
		sum(newBzJe)/100000000 新本周金额,               -- 计算新口径本周认购金额
		sum(sBzJe)/100000000 上周金额,                   -- 计算上周认购金额
		sum(Byje)/100000000 本月金额,                    -- 计算本月认购金额
		sum(yjdJe)/100000000 一季度金额,                 -- 计算一季度认购金额
		sum(ejdje)/100000000 二季度金额,                 -- 计算二季度认购金额
		sum(bnje)/100000000 本年金额                    -- 计算本年累计认购金额
	into #sumccprg  -- 将结果存入临时表#sumccprg
	FROM #saleord a  -- 从销售订单临时表获取数据
	left join vmdm_projectflag f on a.projguid = f.projguid  -- 关联项目标志表
	where a.isccp = '产成品'  -- 筛选产成品
	and year(f.获取时间) <= 2021;  -- 筛选2021年及以前获取的项目