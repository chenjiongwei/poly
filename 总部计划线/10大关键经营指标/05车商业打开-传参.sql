DECLARE @zenddate DATETIME;
DECLARE @zbdate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzenddate DATETIME;

--本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
-- SET @zbdate = '2025-03-30';
-- SET @zenddate = '2025-04-05';
-- SET @newzbdate = '2025-04-01';
-- SET @newzenddate = '2025-04-05';

SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
SET @zenddate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
SET @newzenddate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)

-- SET @zbdate =  DATEADD(week,-1,DATEADD(week,DATEDIFF(week,0,getdate()),6)) ;     -- 设置本周开始日期为2025年3月30日(周日)
-- SET @zenddate = DATEADD(day, 7 - DATEPART(dw, GETDATE()), GETDATE());   -- 设置本周结束日期为2025年4月5日(周六)
-- SET @lzdate = DATEADD(day,-7,@zbdate);     -- 设置上周开始日期为2025年3月23日(上上周日)
-- SET @newzbdate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) ;  -- 设置新口径本周开始日期为2025年4月1日（本月第一天）
-- SET @newzenddate = DATEADD(day, 7 - DATEPART(dw, GETDATE()), GETDATE()); -- 设置新口径本周结束日期为2025年4月5日

--公寓-公寓
--商铺-商业
--办公-写字楼
--车位-地下室/车库

-- 如果当前日期与设定的周结束日期不同，则将周结束日期更新为当前日期
-- 这确保在实际运行日期晚于预设结束日期时使用最新数据
-- IF DATEDIFF(DAY, @zenddate, GETDATE()) <> 0 
-- BEGIN
--     SET @zenddate = GETDATE()  -- 记得改回去
-- END  


SELECT 
    projguid,
    产品类型,
    SUM(本月签约金额) 本月签约金额,
    SUM(本月签约金额不含税) 本月签约金额不含税,
    SUM(本月净利润签约) 本月净利润签约,
    CASE
        WHEN SUM(本月签约金额不含税) <> 0 THEN
                SUM(本月净利润签约) / SUM(本月签约金额不含税)
        ELSE 0
    END 本月净利率
INTO #jjl
FROM s_M002项目级毛利净利汇总表New
WHERE DATEDIFF(DAY, qxdate, @zenddate) = 0
    AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
GROUP BY projguid,
        产品类型;

-- 判断本周开始日期和本周结束日期是否在同一个月
DECLARE @SameMonth BIT;
SET @SameMonth = CASE 
                    WHEN MONTH(@zbdate) = MONTH(@zenddate) AND YEAR(@zbdate) = YEAR(@zenddate) THEN 1 
                    ELSE 0 
                 END;
--本周签约金额	本周签约环比	本月签约金额	本年签约金额
-- 按城市类型统计签约金额数据
-- 输出判断结果
IF @SameMonth = 1
begin 
    PRINT '本周开始日期和本周结束日期在同一个月';

        SELECT 
             @zenddate as 数据统计截止日期,
             CASE
                WHEN a.产品类型 = '公寓' THEN 1
                WHEN a.产品类型 = '商业' THEN 2
                WHEN a.产品类型 = '写字楼' THEN 3
                ELSE 4
            END num,
            a.产品类型,
            (a.本年签约金额 - b.本年签约金额) * 1.0 / 10000 本周签约金额,
            -- (c.本年签约金额 - b.本年签约金额) * 1.0 / 10000 新本周签约金额,
            a.本月签约金额 * 1.0 / 10000 本月签约金额,
            NULL as 本月签约完成率,
            j.区间0 '本月净利率>=0%',
            j.区间1 '本月净利率-10%～0%',
            j.区间2 '本月净利率-20%～-10%',
            j.区间3 '本月净利率-30%～-20%',
            j.区间4 '本月净利率＜-30%',
            a.本年签约金额 * 1.0 / 10000 本年签约金额,
            NULL as 本年签约完成率
        FROM (
            SELECT 产品类型,
                SUM(本月签约金额) 本月签约金额,
                SUM(本年签约金额) 本年签约金额
            FROM S_08ZYXSQYJB_HHZTSYJ_daily
            WHERE DATEDIFF(dd, qxdate, @zenddate) = 0
                AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
            GROUP BY 产品类型
        ) a
        LEFT JOIN (
            SELECT 产品类型,
                SUM(本月签约金额) 本月签约金额,
                SUM(本年签约金额) 本年签约金额
            FROM S_08ZYXSQYJB_HHZTSYJ_daily
            WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
                AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
            GROUP BY 产品类型
        ) b ON a.产品类型 = b.产品类型
        LEFT JOIN (
            SELECT 产品类型,
                SUM(本月签约金额) 本月签约金额,
                SUM(本年签约金额) 本年签约金额
            FROM S_08ZYXSQYJB_HHZTSYJ_daily
            WHERE DATEDIFF(dd, qxdate, @newzbdate) = 1
                AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
            GROUP BY 产品类型
        ) bb ON a.产品类型 = bb.产品类型
        -- LEFT JOIN (
        --     SELECT 产品类型,
        --         SUM(本月签约金额) 本月签约金额,
        --         SUM(本年签约金额) 本年签约金额
        --     FROM S_08ZYXSQYJB_HHZTSYJ_daily
        --     WHERE DATEDIFF(dd, qxdate, @newzenddate) = 0
        --         AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
        --     GROUP BY 产品类型
        -- ) c ON a.产品类型 = c.产品类型
        LEFT JOIN (
            --≥0%	-10%～0%	-20%～-10%	-30%～-20%	＜-30%
            SELECT 产品类型,
                SUM(CASE
                        WHEN 本月净利率 >= 0 THEN 本月签约金额
                        ELSE 0
                    END) '区间0',
                SUM(CASE
                        WHEN 本月净利率 < 0 AND 本月净利率 >= -0.1 THEN 本月签约金额
                        ELSE 0
                    END) '区间1',
                SUM(CASE
                        WHEN 本月净利率 < -0.1 AND 本月净利率 >= -0.2 THEN 本月签约金额
                        ELSE 0
                    END) '区间2',
                SUM(CASE
                        WHEN 本月净利率 < -0.2 AND 本月净利率 >= -0.3 THEN 本月签约金额
                        ELSE 0
                    END) '区间3',
                SUM(CASE
                        WHEN 本月净利率 < -0.3 THEN 本月签约金额
                        ELSE 0
                    END) '区间4'
            FROM #jjl
            GROUP BY 产品类型
        ) j ON a.产品类型 = j.产品类型
        ORDER BY CASE
                    WHEN a.产品类型 = '公寓' THEN 1
                    WHEN a.产品类型 = '商业' THEN 2
                    WHEN a.产品类型 = '写字楼' THEN 3
                    ELSE 4
                END
end 
else  
begin 
      SELECT 
            @zenddate as 数据统计截止日期,
            CASE
                WHEN a.产品类型 = '公寓' THEN 1
                WHEN a.产品类型 = '商业' THEN 2
                WHEN a.产品类型 = '写字楼' THEN 3
                ELSE 4
            END num,
            a.产品类型,
            -- (a.本年签约金额 - b.本年签约金额) * 1.0 / 10000 本周签约金额,
            (c.本年签约金额 - b.本年签约金额) * 1.0 / 10000 本周签约金额,
            a.本月签约金额 * 1.0 / 10000 本月签约金额,
            NULL as 本月签约完成率,
            j.区间0 '本月净利率>=0%',
            j.区间1 '本月净利率-10%～0%',
            j.区间2 '本月净利率-20%～-10%',
            j.区间3 '本月净利率-30%～-20%',
            j.区间4 '本月净利率＜-30%',
            a.本年签约金额 * 1.0 / 10000 本年签约金额,
            NULL as 本年签约完成率
        FROM (
            SELECT 产品类型,
                SUM(本月签约金额) 本月签约金额,
                SUM(本年签约金额) 本年签约金额
            FROM S_08ZYXSQYJB_HHZTSYJ_daily
            WHERE DATEDIFF(dd, qxdate, @zenddate) = 0
                AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
            GROUP BY 产品类型
        ) a
        LEFT JOIN (
            SELECT 产品类型,
                SUM(本月签约金额) 本月签约金额,
                SUM(本年签约金额) 本年签约金额
            FROM S_08ZYXSQYJB_HHZTSYJ_daily
            WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
                AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
            GROUP BY 产品类型
        ) b ON a.产品类型 = b.产品类型
        LEFT JOIN (
            SELECT 产品类型,
                SUM(本月签约金额) 本月签约金额,
                SUM(本年签约金额) 本年签约金额
            FROM S_08ZYXSQYJB_HHZTSYJ_daily
            WHERE DATEDIFF(dd, qxdate, @newzbdate) = 1
                AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
            GROUP BY 产品类型
        ) bb ON a.产品类型 = bb.产品类型
        LEFT JOIN (
            SELECT 产品类型,
                SUM(本月签约金额) 本月签约金额,
                SUM(本年签约金额) 本年签约金额
            FROM S_08ZYXSQYJB_HHZTSYJ_daily
            WHERE DATEDIFF(dd, qxdate, @newzenddate) = 0
                AND 产品类型 IN ('商业', '公寓', '写字楼', '地下室/车库')
            GROUP BY 产品类型
        ) c ON a.产品类型 = c.产品类型
        LEFT JOIN (
            --≥0%	-10%～0%	-20%～-10%	-30%～-20%	＜-30%
            SELECT 产品类型,
                SUM(CASE
                        WHEN 本月净利率 >= 0 THEN 本月签约金额
                        ELSE 0
                    END) '区间0',
                SUM(CASE
                        WHEN 本月净利率 < 0 AND 本月净利率 >= -0.1 THEN 本月签约金额
                        ELSE 0
                    END) '区间1',
                SUM(CASE
                        WHEN 本月净利率 < -0.1 AND 本月净利率 >= -0.2 THEN 本月签约金额
                        ELSE 0
                    END) '区间2',
                SUM(CASE
                        WHEN 本月净利率 < -0.2 AND 本月净利率 >= -0.3 THEN 本月签约金额
                        ELSE 0
                    END) '区间3',
                SUM(CASE
                        WHEN 本月净利率 < -0.3 THEN 本月签约金额
                        ELSE 0
                    END) '区间4'
            FROM #jjl
            GROUP BY 产品类型
        ) j ON a.产品类型 = j.产品类型
        ORDER BY CASE
                    WHEN a.产品类型 = '公寓' THEN 1
                    WHEN a.产品类型 = '商业' THEN 2
                    WHEN a.产品类型 = '写字楼' THEN 3
                    ELSE 4
                END
end 
-- 删除临时表
DROP TABLE #jjl;