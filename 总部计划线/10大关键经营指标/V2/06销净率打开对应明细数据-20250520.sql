DECLARE @zedate DATETIME;
DECLARE @zbdate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;
DECLARE @szedate DATETIME;
DECLARE @szbdate DATETIME;
--本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
SET @zbdate = '2025-07-07';
SET @zedate = '2025-07-13';
SET @newzbdate = '2025-07-07';
SET @newzedate = '2025-07-13';
SET @szbdate = '2025-06-30';
SET @szedate = '2025-07-06';

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
       ISNULL(e.本月签约金额, 0) 四月签约金额,
       ISNULL(e.本月签约金额不含税, 0) 四月签约金额不含税,
       ISNULL(e.本月净利润签约, 0) 四月净利润签约,
       e.本月净利率 四月净利率,
       ISNULL(e.本月签约金额, 0) 五月签约金额,
       ISNULL(e.本月签约金额不含税, 0) 五月签约金额不含税,
       ISNULL(e.本月净利润签约, 0) 五月净利润签约,
       e.本月净利率 五月净利率
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


SELECT f.projguid,
       f.平台公司,
       f.项目代码,
       f.投管代码,
       f.项目名,
       f.推广名,
       f.获取时间,
	   f.项目状态,
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
       END [24年项目类型],
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
       END [25年项目类型],
       s.symj '24年地上剩余可售',
       l.累计签约金额 '截止24年底签约金额',
       j.本年签约金额 '24年签约金额',
       j.本年签约金额不含税 '24年签约金额不含税',
       j.本年净利润签约 '24年净利润签约',
       j.本年销净率 * 1.00 '24年净利率',
	   a.本年签约金额 '本年签约金额',
       a.本年签约金额不含税 '本年签约金额不含税',
       a.本年净利润签约 '本年净利润签约',
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
       a.四月签约金额,
       a.四月签约金额不含税,
       a.四月净利润签约,
       a.五月签约金额,
       a.五月签约金额不含税,
       a.五月净利润签约,
       a.本月签约金额,
       a.本月签约金额不含税,
       a.本月净利润签约,
       a.本月净利率 * 1.00 本月净利率,
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
FROM #benzhou a
     LEFT JOIN #jjl j ON a.projguid = j.projguid
     LEFT JOIN #ljqy24 l ON a.projguid = l.projguid
     LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
     LEFT JOIN #symj s ON a.projguid = s.projguid
ORDER BY f.平台公司,
         f.项目代码;



DROP TABLE #benzhou,
           #jjl,
           #ljqy24,
           #symj;
