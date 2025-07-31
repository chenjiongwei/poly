-- =============================================
-- 第十部分: 巨亏项目数据计算
-- 计算不合理巨亏项目对应亏损净利润金额
-- =============================================
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,  -- 业务单元GUID
       '13' num,                                         -- 序号，用于最终结果排序
       '不合理巨亏项目对应亏损净利润金额' 口径,           -- 指标口径名称
       -- 计算本周巨亏项目亏损金额（净利率<-30%的项目）
       sum(case when 
		   CASE
			   WHEN ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / (ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0))	   
	   else 0 end) 本周签约金额,
       -- 计算新口径本周巨亏项目亏损金额
       sum(case when 
		   CASE
			   WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(c.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(c.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0))
	   else 0 end) 新本周签约金额,
       -- 计算上周巨亏项目亏损金额
       sum(case when 
		   CASE
			   WHEN ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0)) / (ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0))	   
	   else 0 end) 上周签约金额,
       -- 计算本月巨亏项目亏损金额
       sum(case when 
		   CASE
			   WHEN ISNULL(c.本月签约金额不含税, 0) > 0 THEN
					ISNULL(c.本月净利润签约, 0) / ISNULL(c.本月签约金额不含税, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(c.本月净利润签约, 0)
	   else 0 end) 本月签约金额,
       -- 计算一季度巨亏项目亏损金额
       sum(case when 
		   CASE
			   WHEN ISNULL(e.本年签约金额不含税, 0) > 0 THEN
					ISNULL(e.本年净利润签约, 0) / ISNULL(e.本年签约金额不含税, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(e.本年净利润签约, 0)
	   else 0 end) 一季度签约金额,
       -- 计算二季度巨亏项目亏损金额
       sum(case when 
		   CASE
			   WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(c.本年净利润签约, 0) - ISNULL(e.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(c.本年净利润签约, 0) - ISNULL(e.本年净利润签约, 0))
	   else 0 end) 二季度签约金额,
       -- 计算本年巨亏项目亏损金额
       sum(case when 
		   CASE
			   WHEN ISNULL(a.本年签约金额不含税, 0) > 0 THEN
					ISNULL(a.本年净利润签约, 0) / ISNULL(a.本年签约金额不含税, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(a.本年净利润签约, 0)
	   else 0 end) 本年销净率
INTO #sumjk  -- 将结果存入临时表#sumjk
FROM
(
    -- 子查询：获取本周末项目级毛利净利数据（仅限非合理项目）
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.ProjGUID
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0 
	and ISNULL(f.特定项目标签, '') <> '合理'  -- 排除标记为合理的项目
	group by a.ProjGUID
) a
-- 关联本周初数据
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.ProjGUID
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) b ON a.ProjGUID = b.ProjGUID
-- 关联新口径本周末数据
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.ProjGUID
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) c ON a.ProjGUID = c.ProjGUID
-- 关联新口径本周初数据
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.ProjGUID
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) d ON a.ProjGUID = d.ProjGUID
-- 关联一季度末数据
LEFT JOIN 
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.ProjGUID
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) e ON a.ProjGUID = e.ProjGUID
-- 关联上周末数据
LEFT JOIN 
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.ProjGUID
    WHERE DATEDIFF(DAY, qxdate, @szedate) = 0 
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) sa ON a.ProjGUID = sa.ProjGUID
-- 关联上周初数据
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.ProjGUID
    WHERE DATEDIFF(DAY, qxdate, @szbdate) = 1
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) sb ON a.ProjGUID = sb.ProjGUID;