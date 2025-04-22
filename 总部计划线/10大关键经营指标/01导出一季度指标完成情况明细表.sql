DECLARE @qxdate DATETIME;
DECLARE @zbdate DATETIME;
DECLARE @zedate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;

set @qxdate =getdate(); 
SET @zbdate =  ${zbdate};     -- 设置本周开始日期为2025年3月30日(周日)
SET @zedate =  ${zenddate};   -- 设置本周结束日期为2025年4月5日(周六)
SET @newzbdate = ${newzbdate};  -- 设置本月开始日期为2025年4月1日
SET @newzedate =  ${newzenddate}; -- 设置本月当前日期为2025年4月5日(周六)

 -- exec usp_s_sumIndexTotal @qxdate,@zbdate,@zedate,@newzbdate,@newzedate

-- 查询一季度指标完成情况明细表 对于结果进行格式化
SELECT 
    num,
    convert(varchar(10),@qxdate,121) as 数据清洗截止日期,
    CASE 
        WHEN 指标 = '总签约' THEN '1'
        WHEN 指标 = '年初预算住宅②' THEN '1-1'
        WHEN 指标 = '世博③' THEN '1-2'
        WHEN 指标 = '商业⑥a' THEN '1-3'
        WHEN 指标 = '公寓⑥b' THEN '1-4'
        WHEN 指标 = '写字楼⑥c' THEN '1-5'
        WHEN 指标 = '车位⑥d' THEN '1-6'
        WHEN 指标 = '其他⑥e' THEN '1-7'
        WHEN 指标 = '现有可售资源合计' THEN '1-8'
        WHEN 指标 = '当年获取当年签约⑧' THEN '1-9'
        WHEN 指标 = 'BC赛道盘活转化⑨' THEN '1-10'
        WHEN 指标 = '全年签约净利率' THEN '2'
        WHEN 指标 = '其中：-<30%的签约金额(按业态)' THEN '2-1'
        WHEN 指标 = '营销费率' THEN '3'
        WHEN 指标 = '期初在建面积' THEN '4'
        WHEN 指标 = '新开工面积' THEN '5'
        WHEN 指标 = '新开工面积21年及之前获取' THEN '5-11'
        WHEN 指标 = '新开工面积22年23年获取' THEN '5-12'
        WHEN 指标 = '新开工面积24年及之后获取' THEN '5-13'
        WHEN 指标 = '地上新开工面积' THEN '5-2'
        WHEN 指标 = '地上新开工面积21年及之前获取' THEN '5-21'
        WHEN 指标 = '地上新开工面积22年23年获取' THEN '5-22'
        WHEN 指标 = '地上新开工面积24年及之后获取' THEN '5-23'
        WHEN 指标 = '竣工面积' THEN '6'
        WHEN 指标 = '交付套数' THEN '7'
        WHEN 指标 = '操盘交付套数' THEN '7-1' 
        ELSE NULL 
    END AS 新序号,
    CASE 
        WHEN 指标 = '总签约' THEN '亿元'
        WHEN 指标 = '年初预算住宅②' THEN '亿元'
        WHEN 指标 = '世博③' THEN '亿元'
        WHEN 指标 = '商业⑥a' THEN '亿元'
        WHEN 指标 = '公寓⑥b' THEN '亿元'
        WHEN 指标 = '写字楼⑥c' THEN '亿元'
        WHEN 指标 = '车位⑥d' THEN '亿元'
        WHEN 指标 = '其他⑥e' THEN '亿元'
        WHEN 指标 = '现有可售资源合计' THEN '亿元'
        WHEN 指标 = '当年获取当年签约⑧' THEN '亿元'
        WHEN 指标 = 'BC赛道盘活转化⑨' THEN '亿元'
        WHEN 指标 = '全年签约净利率' THEN '%'
        WHEN 指标 = '营销费率' THEN '%'
        WHEN 指标 = '其中：-<30%的签约金额(按业态)' THEN '亿元'
        WHEN 指标 = '期初在建面积' THEN '万平'
        WHEN 指标 = '新开工面积' THEN '万平'
        WHEN 指标 = '新开工面积21年及之前获取' THEN '万平'
        WHEN 指标 = '新开工面积22年23年获取' THEN '万平'
        WHEN 指标 = '新开工面积24年及之后获取' THEN '万平'
        WHEN 指标 = '地上新开工面积' THEN '万平'
        WHEN 指标 = '地上新开工面积21年及之前获取' THEN '万平'
        WHEN 指标 = '地上新开工面积22年23年获取' THEN '万平'
        WHEN 指标 = '地上新开工面积24年及之后获取' THEN '万平'
        WHEN 指标 = '竣工面积' THEN '万平'
        WHEN 指标 = '交付套数' THEN '套'
        WHEN 指标 = '操盘交付套数' THEN '套'
        ELSE NULL 
    END AS 单位,
    case when  指标 ='全年签约净利率' then '签约净利率' else 指标 end as 指标,
    本周,
    本月,
    一季度,
    二季度,
    本年
FROM (
    SELECT 
        num,
        口径 AS 指标,
        ISNULL(CONVERT(VARCHAR(20), CAST(本周签约金额 AS DECIMAL(18,1))), '-') AS 本周,
        ISNULL(CONVERT(VARCHAR(20), CAST(本月签约金额 AS DECIMAL(18,1))), '-') AS 本月,
        ISNULL(CONVERT(VARCHAR(20), CAST(一季度签约金额 AS DECIMAL(18,1))), '-') AS 一季度,
        ISNULL(CONVERT(VARCHAR(20), CAST(二季度签约金额 AS DECIMAL(18,1))), '-') AS 二季度,
        ISNULL(CONVERT(VARCHAR(20), CAST(本年签约金额 AS DECIMAL(18,1))), '-') AS 本年
    FROM [导出一季度指标完成情况]
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0
        AND 口径 NOT IN ('全年签约净利率', '营销费率', '交付套数', '操盘交付套数')
    
    UNION ALL
    
    SELECT 
        num,
        口径 AS 指标,
        ISNULL(CONVERT(VARCHAR(20), CAST(本周签约金额 * 100 AS DECIMAL(18,1))) + '%', '-') AS 本周,
        ISNULL(CONVERT(VARCHAR(20), CAST(本月签约金额 * 100 AS DECIMAL(18,1))) + '%', '-') AS 本月,
        ISNULL(CONVERT(VARCHAR(20), CAST(一季度签约金额 * 100 AS DECIMAL(18,1))) + '%', '-') AS 一季度,
        ISNULL(CONVERT(VARCHAR(20), CAST(二季度签约金额 * 100 AS DECIMAL(18,1))) + '%', '-') AS 二季度,
        ISNULL(CONVERT(VARCHAR(20), CAST(本年签约金额 * 100 AS DECIMAL(18,1))) + '%', '-') AS 本年
    FROM [导出一季度指标完成情况]
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0
        AND 口径 IN ('全年签约净利率', '营销费率')

    UNION ALL

    SELECT 
        num,
        口径 AS 指标,
        ISNULL(CONVERT(VARCHAR(20), CAST(本周签约金额 AS DECIMAL(18,0))), '-') AS 本周,
        ISNULL(CONVERT(VARCHAR(20), CAST(本月签约金额 AS DECIMAL(18,0))), '-') AS 本月,
        ISNULL(CONVERT(VARCHAR(20), CAST(一季度签约金额 AS DECIMAL(18,0))), '-') AS 一季度,
        ISNULL(CONVERT(VARCHAR(20), CAST(二季度签约金额 AS DECIMAL(18,0))), '-') AS 二季度,
        ISNULL(CONVERT(VARCHAR(20), CAST(本年签约金额 AS DECIMAL(18,0))), '-') AS 本年
    FROM [导出一季度指标完成情况]
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0
        AND 口径 IN ( '交付套数', '操盘交付套数')
) t
ORDER BY num