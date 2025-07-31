DECLARE @zbdate DATETIME;
DECLARE @zedate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;

SET @zbdate = '2025-07-07';
SET @zedate = '2025-07-13';
SET @newzbdate = '2025-07-07';
SET @newzedate = '2025-07-13';



--本日销售毛利率
SELECT f.平台公司,
       f.项目名,
       f.推广名,
	   f.城市,
       f.项目代码,
       f.投管代码,
       f.获取时间,
       a.产品类型,
       SUM(ISNULL(a.本年签约套数, 0) - ISNULL(b.本年签约套数, 0)) 本周签约套数,
       SUM(ISNULL(a.本年签约面积, 0) - ISNULL(b.本年签约面积, 0)) 本周签约面积,
       SUM(ISNULL(a.本年签约金额, 0) - ISNULL(b.本年签约金额, 0)) 本周签约金额,
       SUM(ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0)) 本周签约金额不含税,
       SUM(ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) 本周净利润签约,
       CASE
           WHEN SUM(ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0)) > 0 THEN
                SUM(ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / SUM(ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
           ELSE 0
       END 本周净利率,
       SUM(ISNULL(c.本年签约套数, 0) - ISNULL(bb.本年签约套数, 0)) 新本周签约套数,
       SUM(ISNULL(c.本年签约面积, 0) - ISNULL(bb.本年签约面积, 0)) 新本周签约面积,
       SUM(ISNULL(c.本年签约金额, 0) - ISNULL(bb.本年签约金额, 0)) 新本周签约金额,
       SUM(ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0)) 新本周签约金额不含税,
       SUM(ISNULL(c.本年净利润签约, 0) - ISNULL(bb.本年净利润签约, 0)) 新本周净利润签约,
       CASE
           WHEN SUM(ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0)) > 0 THEN
                SUM(ISNULL(c.本年净利润签约, 0) - ISNULL(bb.本年净利润签约, 0)) / SUM(ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0))
           ELSE 0
       END 新本周净利率,
       SUM(ISNULL(d.本年签约套数, 0)) 一季度签约套数,
       SUM(ISNULL(d.本年签约面积, 0)) 一季度签约面积,
       SUM(ISNULL(d.本年签约金额, 0)) 一季度签约金额,
       SUM(ISNULL(d.本年签约金额不含税, 0)) 一季度签约金额不含税,
       SUM(ISNULL(d.本年净利润签约, 0)) 一季度净利润签约,
       CASE
           WHEN SUM(ISNULL(d.本年签约金额不含税, 0)) > 0 THEN
                SUM(ISNULL(d.本年净利润签约, 0)) / SUM(ISNULL(d.本年签约金额不含税, 0))
           ELSE 0
       END 一季度净利率,
       SUM(ISNULL(c.本月签约套数, 0)) 本月签约套数,
       SUM(ISNULL(c.本月签约面积, 0)) 本月签约面积,
       SUM(ISNULL(c.本月签约金额, 0)) 本月签约金额,
       SUM(ISNULL(c.本月签约金额不含税, 0)) 本月签约金额不含税,
       SUM(ISNULL(c.本月净利润签约, 0)) 本月净利润签约,
       CASE
           WHEN SUM(ISNULL(c.本月签约金额不含税, 0)) > 0 THEN
                SUM(ISNULL(c.本月净利润签约, 0)) / SUM(ISNULL(c.本月签约金额不含税, 0))
           ELSE 0
       END 本月净利率,
       SUM(ISNULL(a.本年签约套数, 0)) 本年签约套数,
       SUM(ISNULL(a.本年签约面积, 0)) 本年签约面积,
       SUM(ISNULL(a.本年签约金额, 0)) 本年签约金额,
       SUM(ISNULL(a.本年签约金额不含税, 0)) 本年签约金额不含税,
       SUM(ISNULL(a.本年净利润签约, 0)) 本年净利润签约,
       CASE
           WHEN SUM(ISNULL(a.本年签约金额不含税, 0)) > 0 THEN
                SUM(ISNULL(a.本年净利润签约, 0)) / SUM(ISNULL(a.本年签约金额不含税, 0))
           ELSE 0
       END 本年净利率
FROM
(
    SELECT projguid,
           产品类型,
           SUM(本月签约套数) 本月签约套数,
           SUM(本月签约面积) 本月签约面积,
           SUM(本月签约金额) 本月签约金额,
           SUM(本年签约套数) 本年签约套数,
           SUM(本年签约面积) 本年签约面积,
           SUM(本年签约金额) 本年签约金额,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
    GROUP BY projguid,
             产品类型
) a
LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
LEFT JOIN
(
    SELECT projguid,
           产品类型,
           SUM(本月签约套数) 本月签约套数,
           SUM(本月签约面积) 本月签约面积,
           SUM(本月签约金额) 本月签约金额,
           SUM(本年签约套数) 本年签约套数,
           SUM(本年签约面积) 本年签约面积,
           SUM(本年签约金额) 本年签约金额,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
    GROUP BY projguid,
             产品类型
) b ON a.projguid = b.projguid
       AND a.产品类型 = b.产品类型
LEFT JOIN
(
    SELECT projguid,
           产品类型,
           SUM(本月签约套数) 本月签约套数,
           SUM(本月签约面积) 本月签约面积,
           SUM(本月签约金额) 本月签约金额,
           SUM(本年签约套数) 本年签约套数,
           SUM(本年签约面积) 本年签约面积,
           SUM(本年签约金额) 本年签约金额,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
    GROUP BY projguid,
             产品类型
) bb ON a.projguid = bb.projguid
       AND a.产品类型 = bb.产品类型
LEFT JOIN
(
    SELECT projguid,
           产品类型,
           SUM(本月签约套数) 本月签约套数,
           SUM(本月签约面积) 本月签约面积,
           SUM(本月签约金额) 本月签约金额,
           SUM(本年签约套数) 本年签约套数,
           SUM(本年签约面积) 本年签约面积,
           SUM(本年签约金额) 本年签约金额,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
    GROUP BY projguid,
             产品类型
) c ON a.projguid = c.projguid
       AND a.产品类型 = c.产品类型
LEFT JOIN
(
    SELECT projguid,
           产品类型,
           SUM(本月签约套数) 本月签约套数,
           SUM(本月签约面积) 本月签约面积,
           SUM(本月签约金额) 本月签约金额,
           SUM(本年签约套数) 本年签约套数,
           SUM(本年签约面积) 本年签约面积,
           SUM(本年签约金额) 本年签约金额,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
    GROUP BY projguid,
             产品类型
) d ON a.projguid = d.projguid
       AND a.产品类型 = d.产品类型
GROUP BY f.平台公司,
         f.项目名,
         f.推广名,
	   f.城市,
         f.项目代码,
         f.投管代码,
         f.获取时间,
         a.产品类型
HAVING (SUM(ISNULL(a.本年签约金额, 0))) > 0
ORDER BY f.平台公司,
         f.项目代码,
         a.产品类型;
