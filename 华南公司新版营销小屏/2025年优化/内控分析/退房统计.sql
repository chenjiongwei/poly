

SELECT 
    年份,
    -- ISNULL(SUM(签约后退房套数),0) AS 退房套数,
    -- ISNULL(SUM(签约后退房金额),0) AS 退房金额,
    -- ISNULL(SUM(换房套数),0) AS 换房套数,
    -- ISNULL(SUM(换房金额),0) AS 换房金额,
    -- ISNULL(SUM(签约后退房套数),0)+ISNULL(SUM(换房套数),0) AS 合计套数,
    -- ISNULL(SUM(签约后退房金额),0)+ISNULL(SUM(换房金额),0) AS 合计金额,
    isnull(sum(本年签约后退房套数),0) as 退房套数,
    isnull(sum(本年签约后退房金额),0) as 退房金额,
    isnull(sum(本年签约后换房套数),0) as 换房套数,
    isnull(sum(本年签约后换房金额),0) as 换房金额,
    isnull(sum(本年签约后退房套数),0)+isnull(sum(本年签约后换房套数),0) as 合计套数,
    isnull(sum(本年签约后退房金额),0)+isnull(sum(本年签约后换房金额),0) as 合计金额,

    ISNULL(SUM(跨年签约后退房套数),0) AS 跨年签约后退房套数,
    ISNULL(SUM(跨年签约后退房金额),0) AS 跨年签约后退房金额,
    ISNULL(SUM(跨年换房套数),0) AS 跨年换房套数,
    ISNULL(SUM(跨年换房金额),0) AS 跨年换房金额,
    ISNULL(SUM(跨年签约后退房套数),0)+ISNULL(SUM(跨年换房套数),0) AS 跨年合计套数,
    ISNULL(SUM(跨年签约后退房金额),0)+ISNULL(SUM(跨年换房金额),0) AS 跨年合计金额
into #t
FROM data_wide_dws_s_nkfx t
where  1=1
    AND ((${var_biz} IN ('全部区域','全部项目','全部组团')) --若前台选择"全部区域"、"全部项目"、"全部组团"，则按照公司来统计
    OR (${var_biz} = t.片区) --前台选择了具体某个区域
    OR (${var_biz} = t.组团) --前台选择了具体某个组团
    OR (${var_biz} = t.推广名)) --前台选择了具体某个项目 
GROUP BY 年份

-- 当年签约退换房
SELECT 1 as 排序, 年份, 退房套数, 退房金额, 换房套数, 换房金额, 合计套数, 合计金额 
FROM #t
WHERE 年份 = YEAR(GETDATE())
UNION ALL
-- 跨年签约后退换房合计
SELECT 2 as 排序,
       '往年成交退换房合计' as 年份, 
       SUM(跨年签约后退房套数) AS 跨年签约后退房套数, 
       SUM(跨年签约后退房金额) AS 跨年签约后退房金额, 
       SUM(跨年换房套数) AS 跨年换房套数, 
       SUM(跨年换房金额) AS 跨年换房金额, 
       SUM(跨年合计套数) AS 跨年合计套数, 
       SUM(跨年合计金额) AS 跨年合计金额    
FROM #t
WHERE 年份 < YEAR(GETDATE()) 
UNION ALL
-- 跨年签约后退换房
SELECT row_number() over(order by 年份 desc) +2 as 排序,
    年份, 跨年签约后退房套数, 跨年签约后退房金额, 跨年换房套数, 跨年换房金额, 跨年合计套数, 跨年合计金额 
FROM #t
WHERE 年份 < YEAR(GETDATE()) and isnull(跨年合计套数,0) <> 0


-- 删除临时表
DROP TABLE #t;