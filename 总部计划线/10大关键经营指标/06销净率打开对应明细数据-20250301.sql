-- 声明日期变量
DECLARE @zedate DATETIME;    -- 本周结束日期
DECLARE @zbdate DATETIME;    -- 本周开始日期
DECLARE @newzbdate DATETIME; -- 新本周开始日期
DECLARE @newzedate DATETIME; -- 新本周结束日期

-- 设置日期参数
-- 本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
SET @zbdate = '2025-03-30';
SET @zedate = '2025-04-05';
SET @newzbdate = '2025-04-01';
SET @newzedate = '2025-04-05';

-- 计算2024年地上剩余可售面积
SELECT projguid,
       SUM(zksmj - ysmj) / 10000 symj
INTO #symj
FROM p_lddbamj
WHERE DATEDIFF(dd, qxdate, '2024-12-31') = 0
      AND producttype <> '地下室/车库'
GROUP BY projguid;

-- 获取2024年的净利率数据
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

-- 获取2024年累计签约数据
SELECT projguid,
       SUM(累计签约金额) 累计签约金额
INTO #ljqy24
FROM S_08ZYXSQYJB_HHZTSYJ_daily
WHERE DATEDIFF(DAY, qxdate, '2024-12-31') = 0
GROUP BY projguid;

-- 获取本周和本月的数据
SELECT a.projguid,
       -- 本周数据计算
       ISNULL(a.本年签约金额, 0) - ISNULL(b.本年签约金额, 0) 本周签约金额,
       ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) 本周签约金额不含税,
       ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0) 本周净利润签约,
       CASE
           WHEN ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) <> 0 THEN
                (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / 
                (ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
           ELSE 0
       END 本周净利率,
       
       -- 新本周数据计算
       ISNULL(c.本年签约金额, 0) - ISNULL(bb.本年签约金额, 0) 新本周签约金额,
       ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0) 新本周签约金额不含税,
       ISNULL(c.本年净利润签约, 0) - ISNULL(bb.本年净利润签约, 0) 新本周净利润签约,
       CASE
           WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0) <> 0 THEN
                (ISNULL(c.本年净利润签约, 0) - ISNULL(bb.本年净利润签约, 0)) / 
                (ISNULL(c.本年签约金额不含税, 0) - ISNULL(bb.本年签约金额不含税, 0))
           ELSE 0
       END 新本周净利率,
       
       -- 本月数据
       ISNULL(c.本月签约金额, 0) 本月签约金额,
       ISNULL(c.本月签约金额不含税, 0) 本月签约金额不含税,
       ISNULL(c.本月净利润签约, 0) 本月净利润签约,
       c.本月净利率
INTO #benzhou
FROM
(
    -- 获取本周结束日期的数据
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
    -- 获取本周开始日期的数据
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
    -- 获取新本周开始日期的数据
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
    -- 获取新本周结束日期的数据
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
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
    GROUP BY projguid
) c ON a.projguid = c.projguid;

-- 最终结果查询
SELECT f.projguid,
       f.平台公司,
       f.项目代码,
       f.投管代码,
       f.项目名,
       f.推广名,
       f.获取时间,
       f.项目状态,
       
       -- 项目划分逻辑
       CASE
           WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN '24～25年获取'
           WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN '22～23年获取'
           ELSE '存量（21年及之前获取）'
       END 项目划分,
       
       -- 项目类型编号
       CASE
           WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN '8'
           WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN '7'
           ELSE CASE
                    WHEN j.本年签约金额 = 0 THEN '6'
                    WHEN j.本年销净率 >= 0 THEN '1'
                    WHEN j.本年销净率 >= -0.1 AND j.本年销净率 < 0 THEN '2'
                    WHEN j.本年销净率 >= -0.2 AND j.本年销净率 < -0.1 THEN '3'
                    WHEN j.本年销净率 >= -0.3 AND j.本年销净率 < -0.2 THEN '4'
                    ELSE '5'
                END
       END num,
       
       -- 项目类型描述
       CASE
           WHEN YEAR(f.获取时间) IN ( '2024', '2025' ) THEN '24～25年获取'
           WHEN YEAR(f.获取时间) IN ( '2022', '2023' ) THEN '22～23年获取'
           ELSE CASE
                    WHEN j.本年签约金额 = 0 THEN '24年0签约'
                    WHEN j.本年销净率 >= 0 THEN '≥0%'
                    WHEN j.本年销净率 >= -0.1 AND j.本年销净率 < 0 THEN '-10%～0%'
                    WHEN j.本年销净率 >= -0.2 AND j.本年销净率 < -0.1 THEN '-20%～-10%'
                    WHEN j.本年销净率 >= -0.3 AND j.本年销净率 < -0.2 THEN '-30%～-20%'
                    ELSE '＜-30%'
                END
       END 项目类型,
       
       -- 项目指标数据
       s.symj '24年地上剩余可售',
       l.累计签约金额 '截止24年底签约金额',
       j.本年签约金额 '24年签约金额',
       j.本年签约金额不含税 '24年签约金额不含税',
       j.本年净利润签约 '24年净利润签约',
       j.本年销净率 * 1.00 '24年净利率',
       
       -- 本周数据
       a.本周签约金额,
       a.本周签约金额不含税,
       a.本周净利润签约,
       a.本周净利率,
       
       -- 新本周数据
       a.新本周签约金额,
       a.新本周签约金额不含税,
       a.新本周净利润签约,
       a.新本周净利率,
       
       -- 本月数据
       a.本月签约金额,
       a.本月签约金额不含税,
       a.本月净利润签约,
       a.本月净利率 * 1.00 本月净利率,
       
       -- 状态标记
       CASE WHEN 本月签约金额 = 0 THEN '0签约' ELSE '' END 是否零签约,
       CASE
           WHEN 本月签约金额 > 0 AND
                ((l.累计签约金额 = 0 AND 本月签约金额 > 0) OR 本月净利率 - j.本年销净率 > 0.01) THEN '提升'
           ELSE ''
       END 是否提升,
       CASE
           WHEN 本月签约金额 > 0 AND
                (本月净利率 - j.本年销净率 <= 0.01 AND 本月净利率 - j.本年销净率 >= -0.01) THEN '持平'
           ELSE ''
       END 是否持平,
       CASE
           WHEN 本月签约金额 > 0 AND 本月净利率 - j.本年销净率 < -0.01 THEN '下降'
           ELSE ''
       END 是否下降,
       
       -- 统计标记
       CASE
           WHEN f.获取时间 IS NOT NULL AND
                ((YEAR(f.获取时间) < 2024 AND s.symj >= 1) OR ISNULL(s.symj, 1) >= 1) THEN '是'
           ELSE '否'
       END 是否统计
FROM #benzhou a
     LEFT JOIN #jjl j ON a.projguid = j.projguid
     LEFT JOIN #ljqy24 l ON a.projguid = l.projguid
     LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
     LEFT JOIN #symj s ON a.projguid = s.projguid
ORDER BY f.平台公司,
         f.项目代码;

-- 清理临时表
DROP TABLE #benzhou,
           #jjl,
           #ljqy24,
           #symj;
