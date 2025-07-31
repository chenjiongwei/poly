/*
优化说明：
1. 使用WITH CTE替代临时表，减少IO操作
2. 减少重复的类型转换，将转换操作提取出来
3. 简化CASE WHEN语句，使用IIF函数
4. 优化GROUP BY子句，移除不必要的转换
5. 合并对基础表的访问，减少重复扫描
6. 添加索引建议，提高查询性能
*/

-- 索引建议：为提高查询性能，建议添加以下索引
-- CREATE INDEX idx_product_rest_main ON wqzydtBi_product_rest(统计维度, 清洗时间, 月份差);
-- CREATE INDEX idx_product_rest_filter ON wqzydtBi_product_rest(业态, 户型, 产品名称);

-- 使用CTE优化查询，替代临时表
WITH 
-- 基础数据CTE，处理主要数据
base_data AS (
    SELECT 
        清洗时间,
        统计维度,
        公司,
        城市,
        片区,
        镇街,
        项目,
        外键关联,
        id,
        parentid,
        产品名称,
        户型,
        CASE 
            WHEN 户型 IS NOT NULL THEN 户型 
            WHEN 产品名称 IS NOT NULL THEN 产品名称 
            ELSE 业态 
        END AS 业态,
        CAST(CAST(近三月流速 AS DECIMAL(16,2)) AS VARCHAR(20)) AS 近三月流速,
        CAST(CAST(当前存货面积 AS DECIMAL(16,2)) AS VARCHAR(20)) AS 当前存货面积,
        CAST(CAST(当前已开工未售面积 AS DECIMAL(16,2)) AS VARCHAR(20)) AS 当前已开工未售面积,
        月份差,
        存销比,
        产销比
    FROM wqzydtBi_product_rest
    WHERE (统计维度 = '项目' OR (统计维度 <> '项目' AND 户型 IS NULL)) -- 非项目层级不需要到户型
    AND DATEDIFF(YEAR, 清洗时间, GETDATE()) = 0
),
-- 聚合数据CTE，计算各月份的存销比和产销比
aggregated_data AS (
    SELECT 
        清洗时间,
        统计维度,
        公司,
        城市,
        片区,
        镇街,
        项目,
        外键关联,
        id,
        parentid,
        产品名称,
        户型,
        业态,
        近三月流速,
        当前存货面积,
        当前已开工未售面积,
        CAST(CAST(MAX(CASE WHEN 月份差 = 0 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态1月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = 0 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态1月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -1 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态2月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -1 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态2月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -2 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态3月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -2 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态3月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -3 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态4月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -3 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态4月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -4 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态5月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -4 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态5月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -5 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态6月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -5 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态6月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -6 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态7月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -6 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态7月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -7 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态8月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -7 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态8月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -8 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态9月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -8 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态9月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -9 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态10月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -9 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态10月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -10 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态11月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -10 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态11月产销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -11 THEN 存销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态12月存销比,
        CAST(CAST(MAX(CASE WHEN 月份差 = -11 THEN 产销比 ELSE 0 END) AS DECIMAL(16,2)) AS VARCHAR(20)) AS 动态12月产销比,
        0 AS 是否表头
    FROM base_data
    GROUP BY 
        清洗时间, 统计维度, 公司, 城市, 片区, 镇街, 项目, 外键关联, id, parentid, 产品名称, 户型, 业态,
        近三月流速, 当前存货面积, 当前已开工未售面积
),
-- 表头数据CTE，生成表头行
header_data AS (
    SELECT 
        清洗时间,
        统计维度,
        公司,
        城市,
        片区,
        镇街,
        项目,
        外键关联,
        NULL AS id,
        NULL AS parentid,
        '产品名称' AS 产品名称,
        '户型' AS 户型,
        '业态' AS 业态,
        '近三月流速' AS 近三月流速,
        '当前存货面积' AS 当前存货面积,
        '当前已开工未售面积' AS 当前已开工未售面积,
        CONVERT(VARCHAR(7), 清洗时间, 120) AS 动态1月存销比,
        CONVERT(VARCHAR(7), 清洗时间, 120) AS 动态1月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 1, 清洗时间), 120) AS 动态2月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 1, 清洗时间), 120) AS 动态2月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 2, 清洗时间), 120) AS 动态3月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 2, 清洗时间), 120) AS 动态3月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 3, 清洗时间), 120) AS 动态4月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 3, 清洗时间), 120) AS 动态4月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 4, 清洗时间), 120) AS 动态5月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 4, 清洗时间), 120) AS 动态5月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 5, 清洗时间), 120) AS 动态6月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 5, 清洗时间), 120) AS 动态6月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 6, 清洗时间), 120) AS 动态7月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 6, 清洗时间), 120) AS 动态7月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 7, 清洗时间), 120) AS 动态8月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 7, 清洗时间), 120) AS 动态8月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 8, 清洗时间), 120) AS 动态9月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 8, 清洗时间), 120) AS 动态9月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 9, 清洗时间), 120) AS 动态10月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 9, 清洗时间), 120) AS 动态10月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 10, 清洗时间), 120) AS 动态11月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 10, 清洗时间), 120) AS 动态11月产销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 11, 清洗时间), 120) AS 动态12月存销比,
        CONVERT(VARCHAR(7), DATEADD(MONTH, 11, 清洗时间), 120) AS 动态12月产销比,
        1 AS 是否表头
    FROM (
        SELECT DISTINCT 清洗时间, 统计维度, 公司, 城市, 片区, 镇街, 项目, 外键关联
        FROM wqzydtBi_product_rest
        WHERE (统计维度 = '项目' OR (统计维度 <> '项目' AND 户型 IS NULL))
        AND DATEDIFF(YEAR, 清洗时间, GETDATE()) = 0
    ) AS distinct_data
),
-- 合并数据和表头
combined_data AS (
    SELECT * FROM aggregated_data
    UNION ALL
    SELECT * FROM header_data
)

-- 最终查询，应用业务规则
SELECT
    清洗时间,
    统计维度,
    公司,
    城市,
    片区,
    镇街,
    项目,
    外键关联,
    id,
    parentid,
    产品名称,
    户型,
    业态,
    近三月流速,
    当前存货面积,
    当前已开工未售面积,
    -- 使用IIF函数简化CASE WHEN语句
    IIF(近三月流速 = '0.00', '/', 动态1月存销比) AS 动态1月存销比,
    IIF(近三月流速 = '0.00', '/', 动态1月产销比) AS 动态1月产销比,
    IIF(近三月流速 = '0.00', '/', 动态2月存销比) AS 动态2月存销比,
    IIF(近三月流速 = '0.00', '/', 动态2月产销比) AS 动态2月产销比,
    IIF(近三月流速 = '0.00', '/', 动态3月存销比) AS 动态3月存销比,
    IIF(近三月流速 = '0.00', '/', 动态3月产销比) AS 动态3月产销比,
    IIF(近三月流速 = '0.00', '/', 动态4月存销比) AS 动态4月存销比,
    IIF(近三月流速 = '0.00', '/', 动态4月产销比) AS 动态4月产销比,
    IIF(近三月流速 = '0.00', '/', 动态5月存销比) AS 动态5月存销比,
    IIF(近三月流速 = '0.00', '/', 动态5月产销比) AS 动态5月产销比,
    IIF(近三月流速 = '0.00', '/', 动态6月存销比) AS 动态6月存销比,
    IIF(近三月流速 = '0.00', '/', 动态6月产销比) AS 动态6月产销比,
    IIF(近三月流速 = '0.00', '/', 动态7月存销比) AS 动态7月存销比,
    IIF(近三月流速 = '0.00', '/', 动态7月产销比) AS 动态7月产销比,
    IIF(近三月流速 = '0.00', '/', 动态8月存销比) AS 动态8月存销比,
    IIF(近三月流速 = '0.00', '/', 动态8月产销比) AS 动态8月产销比,
    IIF(近三月流速 = '0.00', '/', 动态9月存销比) AS 动态9月存销比,
    IIF(近三月流速 = '0.00', '/', 动态9月产销比) AS 动态9月产销比,
    IIF(近三月流速 = '0.00', '/', 动态10月存销比) AS 动态10月存销比,
    IIF(近三月流速 = '0.00', '/', 动态10月产销比) AS 动态10月产销比,
    IIF(近三月流速 = '0.00', '/', 动态11月存销比) AS 动态11月存销比,
    IIF(近三月流速 = '0.00', '/', 动态11月产销比) AS 动态11月产销比,
    IIF(近三月流速 = '0.00', '/', 动态12月存销比) AS 动态12月存销比,
    IIF(近三月流速 = '0.00', '/', 动态12月产销比) AS 动态12月产销比,
    是否表头
FROM combined_data
WHERE 业态 <> '后勤区'
AND DATEDIFF(YEAR, 清洗时间, GETDATE()) = 0;