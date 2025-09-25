SELECT
    [buguid],
    [projguid],
    [清洗日期],
    [税前成本利润率_动态版],
    [税前成本利润率_立项版],
    CASE 
        WHEN [税前成本利润率_动态版] IS NOT NULL AND [税前成本利润率_立项版] IS NOT NULL
        THEN ISNULL([税前成本利润率_立项版], 0) - ISNULL([税前成本利润率_动态版], 0)
    END AS [税前成本利润率偏差], 

    [税前利润_动态版],
    [税前利润_立项版],
    CASE 
        WHEN [税前利润_动态版] IS NOT NULL AND [税前利润_立项版] IS NOT NULL
        THEN ISNULL([税前利润_立项版], 0) - ISNULL([税前利润_动态版], 0)
    END AS [税前利润偏差],

    [销售净利率_动态版],
    [销售净利率_立项版],
    CASE 
        WHEN [销售净利率_动态版] IS NOT NULL AND [销售净利率_立项版] IS NOT NULL
        THEN ISNULL([销售净利率_立项版], 0) - ISNULL([销售净利率_动态版], 0)
    END AS [销售净利率偏差],

    [税后利润_动态版],
    [税后利润_立项版],
    CASE 
        WHEN [税后利润_动态版] IS NOT NULL AND [税后利润_立项版] IS NOT NULL
        THEN ISNULL([税后利润_立项版], 0) - ISNULL([税后利润_动态版], 0)
    END AS [税后利润偏差],

    [留存资产_动态版],
    [留存资产_立项版],
    [税后现金利润_动态版],
    [税后现金利润_立项版],
    CASE 
        WHEN [税后现金利润_动态版] IS NOT NULL AND [税后现金利润_立项版] IS NOT NULL
        THEN ISNULL([税后现金利润_立项版], 0) - ISNULL([税后现金利润_动态版], 0)
    END AS [税后现金利润偏差],

    [已实现税后利润_动态版],
    [已实现销售净利率_动态版],
    [未实现税后利润_动态版]
FROM zb_jyjhtjkb_Profit
WHERE
    DATEDIFF(DAY, [清洗日期], ${qxDate} ) = 0