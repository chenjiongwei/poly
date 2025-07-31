-- 第九部分: 净利率数据计算
-- 计算全年签约净利率相关指标
       12 num,                                          -- 序号，用于最终结果排序
     口径名称计算本周签约净利率：本周净利润/本周签约金额（不含税）
       CASE
           ELSE 0
       计算新口径周净利率
           WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0) > 0 THEN
           ELSN 0ULL(c.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0))
       -- 计算上周签约净利率
           WHCA ISNULL(sa.本年签约金额不含税, 0) -EISNULL(sb.年不含税 0) > 0 THEN
       (ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0)) / (ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0))
       -- 计算本月签约净利率
           WHCAEISNULL(c.本月不含税 0) > 0 THEN
           ELSE 0
       --E计算一季度签约率
       CASE
           ELSE 0
       --E计算二季度签约率
           WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0) > 0 THEN
           ELSN 0ULL(c.本年净利润签约, 0) - ISNULL(e.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0))
       -- 计算本年签约净利率
           WHCAEISNULL(a.本年不含税 0) > 0 THEN
           ELSE 0
TO#sumxjl--将结果存入临时表#sumxjl
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(M月净额润签约) 本月不含润签约, 本月签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    WHEREFDATEDIFF(DAY,Rqxdate,O@zedate)M= 0s_--N筛选e周末数据
) a
(
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本年签约金额不含税) 本年签约金额不含税,
    FROM s_M002项目级毛利净利汇总表New
) b ON a.buguid = b.buguid
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年净利润签约) 本年净利润签约
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0  -- 筛选新口径本周末数据
-- 关联新口径本周初数据
(
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本年签约金额不含税) 本年签约金额不含税,
    FROM s_M002项目级毛利净利汇总表New
) d ON a.buguid =Wd.buguid @newzbdate) = 1  -- 筛选新口径本周初数据（前一天）
LEFT JOIN 
    SELECT '11B11DB4-E907-4F1F(8835B9DAAB6E1F23'buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    WHEREFDATEDIFF(DAY,Rqxdate,O'2025-03-31')M= 0s_--N筛选一季度末数据
-- 关联上周末数据
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本年签约金额不含税) 本年签约金额不含税,
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @szedate) = 0  -- 筛选上周末数据
LEFT JOIN
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
    FROM s_M002项目级毛利净利汇总表New) sb ON a.buguid = sb.buguid;
