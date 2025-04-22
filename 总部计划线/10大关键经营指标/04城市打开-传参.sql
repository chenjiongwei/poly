 -- 声明日期变量
DECLARE @zbdate DATETIME;     -- 本周开始日期
DECLARE @zenddate DATETIME;   -- 本周结束日期
DECLARE @lzdate DATETIME;     -- 上周开始日期
DECLARE @newzbdate DATETIME;  -- 新口径本周开始日期
DECLARE @newzenddate DATETIME; -- 新口径本周结束日期

--本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
SET @zenddate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
SET @lzdate =  ${lzdate};     -- 设置上周开始日期为2025年3月23日(上上周日)
SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
SET @newzenddate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)


-- SET @zbdate =  DATEADD(week,-1,DATEADD(week,DATEDIFF(week,0,getdate()),6)) ;     -- 设置本周开始日期为2025年3月30日(周日)
-- SET @zenddate = DATEADD(day, 7 - DATEPART(dw, GETDATE()), GETDATE());   -- 设置本周结束日期为2025年4月5日(周六)
-- SET @lzdate = DATEADD(day,-7,@zbdate);     -- 设置上周开始日期为2025年3月23日(上上周日)
-- SET @newzbdate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) ;  -- 设置新口径本周开始日期为2025年4月1日（本月第一天）
-- SET @newzenddate = DATEADD(day, 7 - DATEPART(dw, GETDATE()), GETDATE()); -- 设置新口径本周结束日期为2025年4月5日

-- 如果当前日期与设定的周结束日期不同，则将周结束日期更新为当前日期
-- 这确保在实际运行日期晚于预设结束日期时使用最新数据
-- IF DATEDIFF(DAY, @zenddate, GETDATE()) <> 0 
-- BEGIN
--      SET @zenddate = GETDATE()  -- 记得改回去
-- END  
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
        a.ctype,                                                           -- 城市类型（一线/二线/三四线/海外）
        (a.本年签约金额 - b.本年签约金额) / 10000 AS 本周签约金额,           -- 本周签约金额（万元）
        -- (d.本年签约金额 - bb.本年签约金额) / 10000 AS 新本周签约金额,        -- 新口径本周签约金额（万元）
        (b.本年签约金额 - c.本年签约金额) / 10000 AS 上周签约金额,           -- 上周签约金额（万元）
        -- 本周签约环比计算（与上周相比的增长率）
        CASE
            WHEN b.本年签约金额 - c.本年签约金额 <> 0 THEN 
                ((a.本年签约金额 - b.本年签约金额) - (b.本年签约金额 - c.本年签约金额)) / (b.本年签约金额 - c.本年签约金额)
            ELSE 0 
        END AS 本周签约环比,
        -- -- 新口径本周签约环比计算
        -- CASE
        --     WHEN b.本年签约金额 - c.本年签约金额 <> 0 THEN 
        --         ((d.本年签约金额 - bb.本年签约金额) - (b.本年签约金额 - c.本年签约金额)) / (b.本年签约金额 - c.本年签约金额)
        --     ELSE 0 
        -- END AS 新本周签约环比,
        a.本月签约金额 / 10000 AS 本月签约金额,                             -- 本月签约金额（万元）
        a.本年签约金额 / 10000 AS 本年签约金额                              -- 本年签约金额（万元）
    FROM
        -- 截至本周结束日期的累计数据
        (   
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM  S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)
            LEFT JOIN  vmdm_projectFlag f with (NOLOCK) ON a.projguid = f.projguid
            LEFT JOIN  city t ON f.城市 = t.city
            WHERE 
                DATEDIFF(dd, qxdate, @zenddate) = 0
            GROUP BY 
                t.ctype
        ) a
    LEFT JOIN 
        -- 截至本周开始日期前一天的累计数据
        (
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM  S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)
            LEFT JOIN  vmdm_projectFlag f with (NOLOCK) ON a.projguid = f.projguid
            LEFT JOIN  city t ON f.城市 = t.city
            WHERE 
                DATEDIFF(dd, qxdate, @zbdate) = 1
            GROUP BY 
                t.ctype
        ) b ON a.ctype = b.ctype
    LEFT JOIN 
        -- 截至上周开始日期前一天的累计数据
        (
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM  S_08ZYXSQYJB_HHZTSYJ_daily a  with (NOLOCK)  
            LEFT JOIN  vmdm_projectFlag f with (NOLOCK)   ON a.projguid = f.projguid
            LEFT JOIN   city t ON f.城市 = t.city
            WHERE 
                DATEDIFF(dd, qxdate, @lzdate) = 1
            GROUP BY 
                t.ctype
        ) c ON a.ctype = c.ctype
    -- LEFT JOIN 
    --     -- 截至本月开始日期前一天的累计数据
    --     (
    --         SELECT 
    --             t.ctype,
    --             SUM(本月签约金额) AS 本月签约金额,
    --             SUM(本年签约金额) AS 本年签约金额
    --         FROM   S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)  
    --         LEFT JOIN  vmdm_projectFlag f with (NOLOCK)   ON a.projguid = f.projguid
    --         LEFT JOIN  city t ON f.城市 = t.city
    --         WHERE 
    --             DATEDIFF(dd, qxdate, @newzbdate) = 1
    --         GROUP BY 
    --             t.ctype
    --     ) bb ON a.ctype = bb.ctype
    -- LEFT JOIN 
    --     -- 截至本月当前日期的累计数据
    --     (
    --         SELECT 
    --             t.ctype,
    --             SUM(本月签约金额) AS 本月签约金额,
    --             SUM(本年签约金额) AS 本年签约金额
    --         FROM  S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)  
    --         LEFT JOIN vmdm_projectFlag f with (NOLOCK)    ON a.projguid = f.projguid
    --         LEFT JOIN  city t ON f.城市 = t.city
    --         WHERE DATEDIFF(dd, qxdate, @newzenddate) = 0
    --         GROUP BY 
    --             t.ctype
    --     ) d ON a.ctype = d.ctype
    WHERE a.ctype <> '海外'
    ORDER BY 
        CASE 
            WHEN a.ctype = '一线' THEN 1    
            WHEN a.ctype = '二线' THEN 2  
            WHEN a.ctype = '三四线' THEN 3  
            ELSE 9  
        END
end  
ELSE
begin 
    PRINT '本周开始日期和本周结束日期不在同一个月';

    SELECT 
        a.ctype,                                                           -- 城市类型（一线/二线/三四线/海外）
        --  (a.本年签约金额 - b.本年签约金额) / 10000 AS 本周签约金额,           -- 本周签约金额（万元）
        (d.本年签约金额 - bb.本年签约金额) / 10000 AS 本周签约金额,        -- 新口径本周签约金额（万元）
        (b.本年签约金额 - c.本年签约金额) / 10000 AS 上周签约金额,           -- 上周签约金额（万元）
        -- 本周签约环比计算（与上周相比的增长率）
        -- CASE
        --     WHEN b.本年签约金额 - c.本年签约金额 <> 0 THEN 
        --         ((a.本年签约金额 - b.本年签约金额) - (b.本年签约金额 - c.本年签约金额)) / (b.本年签约金额 - c.本年签约金额)
        --     ELSE 0 
        -- END AS 本周签约环比,
        -- 新口径本周签约环比计算
        CASE
            WHEN b.本年签约金额 - c.本年签约金额 <> 0 THEN 
                ((d.本年签约金额 - bb.本年签约金额) - (b.本年签约金额 - c.本年签约金额)) / (b.本年签约金额 - c.本年签约金额)
            ELSE 0 
        END AS 本周签约环比,
        a.本月签约金额 / 10000 AS 本月签约金额,                             -- 本月签约金额（万元）
        a.本年签约金额 / 10000 AS 本年签约金额                              -- 本年签约金额（万元）
    FROM
        -- 截至本周结束日期的累计数据
        (   
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM  S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)
            LEFT JOIN  vmdm_projectFlag f with (NOLOCK) ON a.projguid = f.projguid
            LEFT JOIN  city t ON f.城市 = t.city
            WHERE 
                DATEDIFF(dd, qxdate, @zenddate) = 0
            GROUP BY 
                t.ctype
        ) a
    LEFT JOIN 
        -- 截至本周开始日期前一天的累计数据
        (
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM  S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)
            LEFT JOIN  vmdm_projectFlag f with (NOLOCK) ON a.projguid = f.projguid
            LEFT JOIN  city t ON f.城市 = t.city
            WHERE 
                DATEDIFF(dd, qxdate, @zbdate) = 1
            GROUP BY 
                t.ctype
        ) b ON a.ctype = b.ctype
    LEFT JOIN 
        -- 截至上周开始日期前一天的累计数据
        (
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM  S_08ZYXSQYJB_HHZTSYJ_daily a  with (NOLOCK)  
            LEFT JOIN  vmdm_projectFlag f with (NOLOCK)   ON a.projguid = f.projguid
            LEFT JOIN   city t ON f.城市 = t.city
            WHERE 
                DATEDIFF(dd, qxdate, @lzdate) = 1
            GROUP BY 
                t.ctype
        ) c ON a.ctype = c.ctype
    LEFT JOIN 
        -- 截至本月开始日期前一天的累计数据
        (
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM   S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)  
            LEFT JOIN  vmdm_projectFlag f with (NOLOCK)   ON a.projguid = f.projguid
            LEFT JOIN  city t ON f.城市 = t.city
            WHERE 
                DATEDIFF(dd, qxdate, @newzbdate) = 1
            GROUP BY 
                t.ctype
        ) bb ON a.ctype = bb.ctype
    LEFT JOIN 
        -- 截至本月当前日期的累计数据
        (
            SELECT 
                t.ctype,
                SUM(本月签约金额) AS 本月签约金额,
                SUM(本年签约金额) AS 本年签约金额
            FROM  S_08ZYXSQYJB_HHZTSYJ_daily a with (NOLOCK)  
            LEFT JOIN vmdm_projectFlag f with (NOLOCK)    ON a.projguid = f.projguid
            LEFT JOIN  city t ON f.城市 = t.city
            WHERE DATEDIFF(dd, qxdate, @newzenddate) = 0
            GROUP BY 
                t.ctype
        ) d ON a.ctype = d.ctype
    WHERE a.ctype <> '海外'
    ORDER BY 
        CASE 
            WHEN a.ctype = '一线' THEN 1    
            WHEN a.ctype = '二线' THEN 2  
            WHEN a.ctype = '三四线' THEN 3  
            ELSE 9  
        END
end 


-- DROP TABLE #t;