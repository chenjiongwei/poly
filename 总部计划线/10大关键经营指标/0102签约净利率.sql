    SELECT '本周' AS 指标,
           本周签约金额 AS 签约净利率
    FROM [导出一季度指标完成情况] 
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0 
    AND 口径 = '全年签约净利率'
    
    UNION ALL
    
    SELECT '本月' AS 指标,
           本月签约金额 AS 签约净利率
    FROM [导出一季度指标完成情况]
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0
    AND 口径 = '全年签约净利率'
    
    UNION ALL
    
    SELECT '本年' AS 指标,
           本年签约金额 AS 签约净利率
    FROM [导出一季度指标完成情况]
    WHERE DATEDIFF(day, qxdate, GETDATE()) = 0
    AND 口径 = '全年签约净利率'
