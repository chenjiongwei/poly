
--退房率红黑榜
-- 查询结果
SELECT *,
    /*
    入榜规则：年度有认购项目
    红榜评分规则：
    红榜 <=10%
    黑榜评分规则：
    黑榜 >10%
    */
    CASE 
        WHEN 总签约套数 > 0 AND 退房率 <= 0.1 THEN 
            -- 红榜评分
            CASE 
                WHEN 退房率 <= 0.1 AND 退房率 > 0.05 THEN '及格'
                WHEN 退房率 <= 0.05 AND 退房率 > 0 THEN '良好'
                WHEN 退房率 <= 0 THEN '优秀'                      
            END 
        ELSE  
            -- 黑榜评分
            CASE  
                WHEN 退房率 > 0.3 THEN '严重不及格'
                WHEN 退房率 > 0.1 AND 退房率 <= 0.3 THEN '不及格'
            END 
    END AS 评分,
    CASE 
        WHEN 总签约套数 > 0 AND 退房率 <= 0.1 THEN '红榜' 
        ELSE '黑榜' 
    END 红黑榜
INTO #ztfl
FROM (
    SELECT 
        片区,
        组团,
        推广名,
        项目责任人,
        项目简称,
        SUM(总签约套数) AS 总签约套数,
        ISNULL(SUM(签约后退房套数), 0) AS 签约后退房套数,
        CASE 
            WHEN SUM(总签约套数) = 0 THEN 0 
            ELSE ISNULL(SUM(签约后退房套数), 0) / SUM(总签约套数) 
        END AS 退房率
    FROM data_wide_dws_s_nkfx
    WHERE 年份 = YEAR(GETDATE())
    GROUP BY 
        片区,
        组团,
        推广名,
        项目责任人,
        项目简称
    HAVING SUM(总签约套数) > 0
) t  

-- 排序
SELECT  
    t.*,
    CASE 
        WHEN 正序 = 1 THEN 1 
        WHEN 正序 = 2 THEN 2
        WHEN 正序 = 3 THEN 3
        WHEN 倒序 = 3 THEN 6
        WHEN 倒序 = 2 THEN 5
        WHEN 倒序 = 1 THEN 4
        WHEN 正序 > 3 THEN 正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
    END AS 排序,
    CASE 
        WHEN 倒序 = 1 THEN '倒数第一'
        WHEN 倒序 = 2 THEN '倒数第二'   
        WHEN 倒序 = 3 THEN '倒数第三' 
        ELSE CONVERT(VARCHAR(20), 正序) 
    END AS 序号
FROM (
    SELECT 
        *,
        Rank() OVER(ORDER BY 红黑榜 DESC, 退房率) AS 正序,
        Rank() OVER(ORDER BY 红黑榜, 退房率 DESC) AS 倒序
    FROM #ztfl 
) t
WHERE 1=1
    AND ((${var_biz} IN ('全部区域', '全部项目', '全部组团')) --若前台选择"全部区域"、"全部项目"、"全部组团"，则按照公司来统计
    OR (${var_biz} = t.片区) --前台选择了具体某个区域
    OR (${var_biz} = t.组团) --前台选择了具体某个组团
    OR (${var_biz} = t.推广名)) --前台选择了具体某个项目 

DROP TABLE #ztfl;