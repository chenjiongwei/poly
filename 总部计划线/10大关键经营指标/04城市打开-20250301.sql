 -- 声明日期变量
DECLARE @zbdate DATETIME;     -- 本周开始日期
DECLARE @zenddate DATETIME;   -- 本周结束日期
DECLARE @lzdate DATETIME;     -- 上周开始日期
DECLARE @newzbdate DATETIME;  -- 新口径本周开始日期
DECLARE @newzenddate DATETIME; -- 新口径本周结束日期

--本周是上周日到本周六晚，上周日就是上上周六对应的清洗数据差
-- SET @zbdate = '2025-03-30';     -- 设置本周开始日期为2025年3月30日(周日)
-- SET @zenddate = '2025-04-05';   -- 设置本周结束日期为2025年4月5日(周六)
-- SET @lzdate = '2025-03-23';     -- 设置上周开始日期为2025年3月23日(上上周日)
-- SET @newzbdate = '2025-04-01';  -- 设置本月开始日期为2025年4月1日
-- SET @newzenddate = '2025-04-05'; -- 设置本月当前日期为2025年4月5日(周六)


SET @zbdate =  DATEADD(week,-1,DATEADD(week,DATEDIFF(week,0,getdate()),6)) ;     -- 设置本周开始日期为2025年3月30日(周日)
SET @zenddate = DATEADD(day, 7 - DATEPART(dw, GETDATE()), GETDATE());   -- 设置本周结束日期为2025年4月5日(周六)
SET @lzdate = DATEADD(day,-7,@zbdate);     -- 设置上周开始日期为2025年3月23日(上上周日)
SET @newzbdate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) ;  -- 设置新口径本周开始日期为2025年4月1日（本月第一天）
SET @newzenddate = DATEADD(day, 7 - DATEPART(dw, GETDATE()), GETDATE()); -- 设置新口径本周结束日期为2025年4月5日

-- 如果当前日期与设定的周结束日期不同，则将周结束日期更新为当前日期
-- 这确保在实际运行日期晚于预设结束日期时使用最新数据
IF DATEDIFF(DAY, @zenddate, GETDATE()) <> 0 
BEGIN
    SET @zenddate = GETDATE()
END  

-- -- 创建城市临时表
-- CREATE TABLE City (
--     city VARCHAR(20),
--     ctype VARCHAR(20));

-- INSERT INTO City (city,ctype)
-- VALUES ('广州', '一线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('长沙', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('北京', '一线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('武汉', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('重庆', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('上海', '一线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('沈阳', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('岳阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('佛山', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('包头', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('成都', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('杭州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('南昌', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('天津', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('丹东', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('青岛', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('长春', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('大连', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('黄冈', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('南京', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('无锡', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('阳江', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('常州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('东莞', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('福州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('嘉兴', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('连云港', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('南通', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('厦门', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('绍兴', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('营口', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('中山', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('珠海', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('德阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('合肥', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('石家庄', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('通化', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('郑州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('宁波', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('郴州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('江门', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('三亚', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('西安', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('遂宁', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('清远', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('太原', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('韶关', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('湛江', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('海口', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('林芝', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('肇庆', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('莆田', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('惠州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('洛阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('兰州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('汕尾', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('茂名', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('乌鲁木齐', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('泉州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('宜昌', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('晋中', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('沧州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('常德', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('赣州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('临沂', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('汕头', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('深圳', '一线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('九江', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('徐州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('梅州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('益阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('芜湖', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('眉山', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('盐城', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('衡水', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('昆明', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('镇江', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('苏州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('湖州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('漳州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('济南', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('天水', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('台州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('揭阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('温州', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('潍坊', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('邢台', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('金华', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('开封', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('邯郸', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('荆州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('德州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('许昌', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('襄阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('烟台', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('秦皇岛', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('张家口', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('河源', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('孝感', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('贵阳', '二线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('抚州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('渭南', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('济宁', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('淮安', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('阜阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('库尔勒', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('舟山', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('湘潭', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('西双版纳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('琼海', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('临汾', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('大同', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('廊坊', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('扬州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('长治', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('儋州', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('宜宾', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('龙岩', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('宜春', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('宁德', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('晋城', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('衡阳', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('墨尔本', '海外');
-- INSERT INTO City (city,  ctype)
-- VALUES ('悉尼', '海外');
-- INSERT INTO City (city,  ctype)
-- VALUES ('伦敦', '海外');
-- INSERT INTO City (city,  ctype)
-- VALUES ('洛杉矶', '海外');
-- INSERT INTO City (city,  ctype)
-- VALUES ('旧金山', '海外');
-- INSERT INTO City (city,  ctype)
-- VALUES ('布里斯班', '海外');
-- INSERT INTO City (city,  ctype)
-- VALUES ('黄石', '三四线');
-- INSERT INTO City (city,  ctype)
-- VALUES ('辽阳', '三四线');


-- 判断 本周开始日期和本周结束日期是否在同一个月

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