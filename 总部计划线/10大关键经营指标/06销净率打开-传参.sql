-- =============================================
-- 项目销净率分析报表
-- 功能：分析项目2024年及2025年初的销售净利率情况
-- 包括：24年累计数据、本周数据、本月数据对比分析
-- =============================================
-- exec usp_s_xsjlv
--      @qxdate = '2025-04-18', -- 清洗时间
--      @zbdate = '2025-04-06', -- 本周开始日期(周日)
--      @zedate = '2025-04-12', -- 本周结束日期(周六)
--      @newzbdate = '2025-04-06', -- 新本周开始日期         
--      @newzedate = '2025-04-12' -- 新本周结束日期（周六）

-- DECLARE @qxdate DATETIME;
-- DECLARE @zbdate DATETIME;
-- DECLARE @zedate DATETIME;
-- DECLARE @newzbdate DATETIME;
-- DECLARE @newzedate DATETIME;

-- set @qxdate =getdate(); 
-- SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
-- SET @zedate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
-- SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
-- SET @newzedate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)

--  exec usp_s_xsjlv @qxdate,@zbdate,@zedate,@newzbdate,@newzedate
alter  proc usp_s_xsjlv(
     @qxdate datetime, -- 清洗时间
     @zbdate datetime, -- 本周开始日期(周日)
     @zedate datetime, -- 本周结束日期(周六)
     @newzbdate datetime, -- 新本周开始日期         
     @newzedate datetime -- 新本周结束日期（周六）
)
as  
begin 

 -- 判断传递参数是否同当前结果表存储参数一致，如果一致则不做清洗，直接返回结果值
     if exists (select 1 from [销净率打开] 
          where  datediff(day,@qxdate,qxdate) = 0
              and datediff(day,@zbdate,zbdate) = 0
              and datediff(day,@zedate,zedate) = 0
              and datediff(day,@newzbdate,newzbdate) = 0
              and datediff(day,@newzedate,newzedate) = 0)
     begin
          select * from  [销净率打开] where  datediff(day,@qxdate,qxdate) = 0
          return 
     end

-- 声明日期变量
-- DECLARE @zedate DATETIME;    -- 结束日期
-- DECLARE @zbdate DATETIME;    -- 开始日期
-- DECLARE @newzbdate DATETIME; -- 新的开始日期
-- DECLARE @newzedate DATETIME; -- 新的结束日期

-- 初始化日期参数
-- SET @zbdate = '2025-03-30';
-- SET @zedate = '2025-04-05';
-- SET @newzbdate = '2025-04-01';
-- SET @newzedate = '2025-04-05';

-- SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
-- SET @zedate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
-- SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
-- SET @newzedate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)


-- 如果当前日期与设定的周结束日期不同，则将周结束日期更新为当前日期
-- 这确保在实际运行日期晚于预设结束日期时使用最新数据
IF DATEDIFF(DAY, @zedate, GETDATE()) <> 0 
BEGIN
    SET @zedate = GETDATE()  
    SET @newzedate = GETDATE()
END  


-- =============================================
-- 创建临时表 #symj - 计算24年地上剩余可售面积
-- =============================================
SELECT projguid,
       SUM(zksmj - ysmj) / 10000 symj
INTO #symj
FROM p_lddbamj
WHERE DATEDIFF(dd, qxdate, '2024-12-31') = 0
      AND producttype <> '地下室/车库'
GROUP BY projguid;

-- =============================================
-- 创建临时表 #jjl - 计算24年净利率数据
-- =============================================
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

-- =============================================
-- 创建临时表 #ljqy24 - 计算24年累计签约金额
-- =============================================
SELECT projguid,
       SUM(累计签约金额) 累计签约金额
INTO #ljqy24
FROM S_08ZYXSQYJB_HHZTSYJ_daily
WHERE DATEDIFF(DAY, qxdate, '2024-12-31') = 0
GROUP BY projguid;

-- =============================================
-- 创建临时表 #benzhou - 计算本周和本月数据
-- =============================================
SELECT a.projguid,
       -- 本周数据
       ISNULL(a.本年签约金额, 0) - ISNULL(b.本年签约金额, 0) 本周签约金额,
       ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) 本周签约金额不含税,
       ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0) 本周净利润签约,
       CASE
           WHEN ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) <> 0 THEN
                (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / 
                (ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
           ELSE 0
       END 本周净利率,
       
       -- 新本周数据
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
    -- 获取结束日期数据
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
    -- 获取开始日期前一天数据
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
    -- 获取新开始日期前一天数据
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
    -- 获取新结束日期数据
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

-- =============================================
-- 创建临时表 #nchz - 计算24年地上剩余可售货值
-- =============================================
SELECT ProjGUID,
       SUM(syhz) / 100000000 syhz
INTO #nchz
FROM p_lddb a
WHERE DATEDIFF(dd, qxdate, '2024-12-31') = 0
GROUP BY a.ProjGUID;

-- =============================================
-- 创建临时表 #result - 整合所有数据
-- =============================================
SELECT f.projguid,
       f.平台公司,
       f.项目代码,
       f.投管代码,
       f.项目名,
       f.推广名,
       f.获取时间,
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
       -- 基础数据
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
       h.syhz '25年初可售货值',
       -- 是否统计标志
       CASE
           WHEN f.获取时间 IS NOT NULL
                AND ((YEAR(f.获取时间) < 2024 AND s.symj >= 1)
                     OR ISNULL(s.symj, 1) >= 1) THEN '是'
           ELSE '否'
       END 是否统计
INTO #result
FROM #benzhou a
     LEFT JOIN #jjl j ON a.projguid = j.projguid
     LEFT JOIN #ljqy24 l ON a.projguid = l.projguid
     LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
     LEFT JOIN #symj s ON a.projguid = s.projguid
     LEFT JOIN #nchz h ON a.projguid = h.projguid
WHERE f.获取时间 IS NOT NULL
      AND f.项目状态 IN ('正常', '正常（拟退出）')
ORDER BY f.平台公司,
         f.项目代码;

-- =============================================
-- 创建临时表 #result1 - 按项目类型汇总数据
-- =============================================
SELECT num,
       项目划分,
       项目类型,
       COUNT(1) 项目个数,
       SUM([24年签约金额]) [24年签约金额],
       SUM([25年初可售货值]) [25年初可售货值],
       -- 计算平均销净率
       CASE
           WHEN SUM([24年签约金额不含税]) > 0 THEN
                SUM([24年净利润签约]) / SUM([24年签约金额不含税])
           ELSE 0
       END '24年平均销净率',
       -- 本周数据
       CASE
           WHEN SUM(本周签约金额不含税) > 0 THEN
                SUM(本周净利润签约) / SUM(本周签约金额不含税)
           ELSE 0
       END '本周销净率',
       SUM(本周签约金额) 本周签约金额,
       -- 新本周数据
       CASE
           WHEN SUM(新本周签约金额不含税) > 0 THEN
                SUM(新本周净利润签约) / SUM(新本周签约金额不含税)
           ELSE 0
       END '新本周销净率',
       SUM(新本周签约金额) 新本周签约金额,
       -- 本月数据
       CASE
           WHEN SUM(本月签约金额不含税) > 0 THEN
                SUM(本月净利润签约) / SUM(本月签约金额不含税)
           ELSE 0
       END '本月销净率',
       SUM(本月签约金额) 本月签约金额,
       -- 统计本月0签约项目
       SUM(CASE WHEN 本月签约金额 = 0 THEN 1 ELSE 0 END) '本月净利率变化0签约',
       SUM(CASE WHEN 本月签约金额 = 0 THEN [25年初可售货值] ELSE 0 END) '本月净利率变化0签约25年初可售货值',
       -- 统计较24年提升项目
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN 1 ELSE 0 
       END) '较24年提升个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年提升项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN 本月签约金额 ELSE 0 
       END) '较24年提升项目的签约额',
       -- 统计较24年持平项目
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN 1 ELSE 0 
       END) '较24年持平个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年持平项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN 本月签约金额 ELSE 0 
       END) '较24年持平项目的签约额',
       -- 统计较24年下降项目
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN 1 ELSE 0 
       END) '较24年下降个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年下降项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN 本月签约金额 ELSE 0 
       END) '较24年下降项目的签约额'
INTO #result1
FROM #result
WHERE 是否统计 = '是'
GROUP BY num,
         项目划分,
         项目类型;

-- =============================================
-- 创建临时表 #result3 - 存量项目合计
-- =============================================
SELECT 6 num,
       '存量合计' 项目划分,
       '存量合计' 项目类型,
       -- 重复上述统计逻辑，仅针对存量项目
       COUNT(1) 项目个数,
       SUM([24年签约金额]) [24年签约金额],
       SUM([25年初可售货值]) [25年初可售货值],
       CASE WHEN SUM([24年签约金额不含税]) > 0 THEN SUM([24年净利润签约]) / SUM([24年签约金额不含税]) ELSE 0 END '24年平均销净率',
       CASE WHEN SUM(本周签约金额不含税) > 0 THEN SUM(本周净利润签约) / SUM(本周签约金额不含税) ELSE 0 END '本周销净率',
       SUM(本周签约金额) 本周签约金额,
       CASE WHEN SUM(新本周签约金额不含税) > 0 THEN SUM(新本周净利润签约) / SUM(新本周签约金额不含税) ELSE 0 END '新本周销净率',
       SUM(新本周签约金额) 新本周签约金额,
       CASE WHEN SUM(本月签约金额不含税) > 0 THEN SUM(本月净利润签约) / SUM(本月签约金额不含税) ELSE 0 END '本月销净率',
       SUM(本月签约金额) 本月签约金额,
       SUM(CASE WHEN 本月签约金额 = 0 THEN 1 ELSE 0 END) '本月净利率变化0签约',
       SUM(CASE WHEN 本月签约金额 = 0 THEN [25年初可售货值] ELSE 0 END) '本月净利率变化0签约25年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN 1 ELSE 0 
       END) '较24年提升个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年提升项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN 本月签约金额 ELSE 0 
       END) '较24年提升项目的签约额',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN 1 ELSE 0 
       END) '较24年持平个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年持平项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN 本月签约金额 ELSE 0 
       END) '较24年持平项目的签约额',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN 1 ELSE 0 
       END) '较24年下降个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年下降项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN 本月签约金额 ELSE 0 
       END) '较24年下降项目的签约额'
INTO #result3
FROM #result
WHERE 是否统计 = '是'
      AND 项目划分 = '存量（21年及之前获取）';

-- =============================================
-- 创建临时表 #result2 - 全量合计
-- =============================================
SELECT 9 num,
       '合计' 项目划分,
       '合计' 项目类型,
       -- 重复上述统计逻辑，针对所有项目
       COUNT(1) 项目个数,
       SUM([24年签约金额]) [24年签约金额],
       SUM([25年初可售货值]) [25年初可售货值],
       CASE WHEN SUM([24年签约金额不含税]) > 0 THEN SUM([24年净利润签约]) / SUM([24年签约金额不含税]) ELSE 0 END '24年平均销净率',
       CASE WHEN SUM(本周签约金额不含税) > 0 THEN SUM(本周净利润签约) / SUM(本周签约金额不含税) ELSE 0 END '本周销净率',
       SUM(本周签约金额) 本周签约金额,
       CASE WHEN SUM(新本周签约金额不含税) > 0 THEN SUM(新本周净利润签约) / SUM(新本周签约金额不含税) ELSE 0 END '新本周销净率',
       SUM(新本周签约金额) 新本周签约金额,
       CASE WHEN SUM(本月签约金额不含税) > 0 THEN SUM(本月净利润签约) / SUM(本月签约金额不含税) ELSE 0 END '本月销净率',
       SUM(本月签约金额) 本月签约金额,
       SUM(CASE WHEN 本月签约金额 = 0 THEN 1 ELSE 0 END) '本月净利率变化0签约',
       SUM(CASE WHEN 本月签约金额 = 0 THEN [25年初可售货值] ELSE 0 END) '本月净利率变化0签约25年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN 1 ELSE 0 
       END) '较24年提升个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年提升项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (([截止24年底签约金额] = 0 AND 本月签约金额 > 0) OR 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 > 0.01) 
           THEN 本月签约金额 ELSE 0 
       END) '较24年提升项目的签约额',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN 1 ELSE 0 
       END) '较24年持平个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年持平项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                (本月净利率 * 1.00 - [24年净利率] * 1.00 <= 0.01 AND 
                 本月净利率 * 1.00 - [24年净利率] * 1.00 >= -0.01) 
           THEN 本月签约金额 ELSE 0 
       END) '较24年持平项目的签约额',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN 1 ELSE 0 
       END) '较24年下降个数',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN [25年初可售货值] ELSE 0 
       END) '较24年下降项目的25年年初可售货值',
       SUM(CASE 
           WHEN 本月签约金额 > 0 AND 
                本月净利率 * 1.00 - [24年净利率] * 1.00 < -0.01 
           THEN 本月签约金额 ELSE 0 
       END) '较24年下降项目的签约额'
INTO #result2
FROM #result
WHERE 是否统计 = '是';

-- =============================================
-- 最终结果输出
-- =============================================

-- 为避免清洗时间重复，将清洗时间为当天的数据清除掉
truncate table   [dbo].[销净率打开] 
-- WHERE DATEDIFF(day, qxdate, GETDATE()) = 0;  

INSERT INTO [dbo].[销净率打开]
SELECT * 
FROM
(
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate,  * FROM #result1
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate,  * FROM #result3
    UNION
    SELECT @qxdate AS qxdate, @zbdate AS zbdate, @zedate AS zedate, @newzbdate AS newzbdate, @newzedate AS newzedate,  * FROM #result2
) a
ORDER BY a.num;

-- 输出仓结果
select  * from 销净率打开 where datediff(day,qxdate,@qxdate) = 0
order by num

-- =============================================
-- 清理临时表
-- =============================================
DROP TABLE #benzhou,
           #jjl,
           #ljqy24,
           #symj,
           #result,
           #result1,
           #result2,
           #result3,
           #nchz;
end 


