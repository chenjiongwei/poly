-- 声明开发公司GUID变量
declare @dev varchar(max) = '5A4B2DEF-E803-49F8-9FE2-308735E7233D'

-- 1. 获取符合小于-30%的认购利润数据
SELECT 
    a.projguid,
    产品类型,
    -- 计算本日净利润率 
    CASE
        WHEN SUM(本日认购金额不含税) > 0 THEN
            SUM(本日净利润认购) / SUM(本日认购金额不含税)
        ELSE 0
    END 本日净利润率,
    -- 计算本日销售金额(单位:元)
    SUM(本日认购金额) * 10000 AS 本日销售金额
into #s_M002项目级毛利净利汇总表New
FROM s_M002项目级毛利净利汇总表New a
WHERE DATEDIFF(dd, qxdate, GETDATE()) = 0
    AND a.OrgGuid = @dev
GROUP BY 
    a.projguid,
    产品类型
-- 筛选净利润率小于等于-30%的记录
HAVING (
    CASE
        WHEN SUM(本日认购金额不含税) > 0 THEN
            SUM(本日净利润认购) / SUM(本日认购金额不含税)
        ELSE 0
    END
) <= -0.3;

-- 2. 预处理业态结论数据
WITH res AS (
    SELECT 
        p.推广名,
        t.产品类型,
        CONVERT(DECIMAL(16, 1), t.本日销售金额) AS 本日销售金额,
        CONVERT(DECIMAL(16, 0), t.本日净利润率 * 100) AS 本日净利润率
    FROM #s_M002项目级毛利净利汇总表New t
    LEFT JOIN vmdm_projectFlag p 
        ON t.projguid = p.projguid
)
SELECT 
    推广名,
    -- 使用STUFF和FOR XML PATH合并同一项目下的业态数据
    业态结论 = STUFF(
        (
            SELECT ';' + '认购' + 产品类型 + 
                   CONVERT(VARCHAR, 本日销售金额) + '万，销净率' + 
                   CONVERT(VARCHAR, 本日净利润率) + '%'
            FROM res r2
            WHERE r2.推广名 = res.推广名
            ORDER BY r2.本日净利润率 DESC
            FOR XML PATH('')
        ),
        1,
        1,
        ''
    ),
    ROW_NUMBER() OVER (ORDER BY MAX(本日净利润率)) AS 排序
INTO #res_业态合并
FROM res
GROUP BY 推广名;

-- 3. 输出最终结论
SELECT 
    header + '<br>' + 
    CASE
        WHEN t.利率结论 IS NULL THEN '无'
        ELSE ISNULL(利率结论, '')
    END AS 利润率通报情况
FROM (
    SELECT '二、当日销净率低于-30%项目情况' AS header
) AS a
LEFT JOIN (
    SELECT STRING_AGG(
        CONVERT(VARCHAR, t.排序) + '、【' + t.推广名 + '】今日' + 
        t.业态结论 + '；原因为：', 
        '<br>'
    ) AS 利率结论
    FROM #res_业态合并 t
) t ON 1 = 1;

-- 清理临时表
DROP TABLE 
    #res_业态合并,
    #s_M002项目级毛利净利汇总表New;