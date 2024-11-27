-- 统计平台公司的各城市公司的签约、回笼、现金流排行榜
SELECT  
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 AS 城市公司 ,
        CONVERT(DECIMAL(10, 2),sale.本月签约任务/10000.0 ) as 本月签约任务  ,
        CONVERT(DECIMAL(10, 2),sale.本月签约金额/10000.0 ) as 本月签约金额 ,
        CASE WHEN CONVERT(DECIMAL(10, 2),sale.本月签约任务/10000.0 ) = 0 THEN null ELSE 
		    CONVERT(DECIMAL(10, 2),sale.本月签约金额/10000.0 ) / CONVERT(DECIMAL(10, 2),sale.本月签约任务/10000.0 )  END AS 本月签约完成率 ,
        CONVERT(DECIMAL(10, 2),hl.本月回笼任务 /10000.0 )  as 本月回笼任务 ,
        CONVERT(DECIMAL(10, 2),hl.本月回笼金额 /10000.0 )  as 本月回笼金额 ,
        CASE WHEN CONVERT(DECIMAL(10, 2),hl.本月回笼任务 /10000.0 ) = 0 THEN null ELSE 
		    CONVERT(DECIMAL(10, 2),hl.本月回笼金额 /10000.0 )/ CONVERT(DECIMAL(10, 2),hl.本月回笼任务 /10000.0 )  END AS 本月回笼完成率 ,
        cash.本月经营性现金流 ,
        cash.本月股东现金流
INTO    #temp
FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_baseinfo base ON org.组织架构id = base.组织架构id  and  org.清洗时间id = base.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and  org.清洗时间id = sale.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_ProfitInfo profit ON profit.组织架构id = org.组织架构id and org.清洗时间id = profit.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and  org.清洗时间id = hl.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_cashflowInfo cash ON cash.组织架构id = org.组织架构id and  org.清洗时间id = cash.清洗时间id
WHERE   1 = 1 AND   org.组织架构类型 = 2 AND  org.平台公司名称 = '湾区公司';

-- 排序
SELECT 
        ROW_NUMBER() OVER ( PARTITION BY 清洗时间 ORDER BY(ISNULL(签约排序, 0) + ISNULL(回笼排序, 0) + ISNULL(现金流排序, 0))) AS 综合排序红榜 ,
        CASE WHEN 签约排序 = 1 THEN '一' WHEN 签约排序 = 2 THEN '二' WHEN 签约排序 = 3 THEN '三' WHEN 签约排序 = 4 THEN '四' WHEN 签约排序 = 5 THEN '五' END AS 签约排名 ,
        CASE WHEN 回笼排序 = 1 THEN '一' WHEN 回笼排序 = 2 THEN '二' WHEN 回笼排序 = 3 THEN '三' WHEN 回笼排序 = 4 THEN '四' WHEN 回笼排序 = 5 THEN '五' END AS 回笼排名 ,
        CASE WHEN 现金流排序 = 1 THEN '一' WHEN 现金流排序 = 2 THEN '二' WHEN 现金流排序 = 3 THEN '三' WHEN 现金流排序 = 4 THEN '四' WHEN 现金流排序 = 5 THEN '五' END AS 现金流排名 ,
        *
FROM(
            SELECT 
            convert(datetime, 清洗时间) as 清洗时间,
            ROW_NUMBER() OVER ( PARTITION BY 清洗时间 ORDER BY 本月签约完成率 DESC) AS 签约排序 ,
            ROW_NUMBER() OVER ( PARTITION BY 清洗时间 ORDER BY 本月回笼完成率 DESC) AS 回笼排序 ,
            ROW_NUMBER() OVER ( PARTITION BY 清洗时间 ORDER BY 本月经营性现金流 DESC) AS 现金流排序 ,
            平台公司GUID ,
            组织架构父级id ,
            组织架构id ,
            城市公司 ,
            本月签约任务 ,
            本月签约金额 ,
            本月签约完成率,
            本月回笼任务 ,
            本月回笼金额 ,
            本月回笼完成率,
            本月经营性现金流 ,
            本月股东现金流
     FROM   #temp
     WHERE  城市公司 <> '深圳项目部') t
UNION ALL
SELECT  

        NULL AS 综合排序红榜 ,
        case when  本月签约任务 > 0  then '六' end  AS 签约排名 ,
        case when  本月回笼任务 > 0 then '六'  end  AS 回笼排名 ,
        null AS 现金流排名 ,
		convert(datetime, 清洗时间) as 清洗时间,
        case when 本月签约任务> 0 then 6 end   AS 签约排序 ,
        case when  本月回笼任务>0 then 6 end  AS 回笼排序 ,
        NULL AS 现金流排序 ,
        平台公司GUID ,
        组织架构父级id ,
        组织架构id ,
        城市公司 ,
        本月签约任务 ,
        本月签约金额 ,
        本月签约完成率,
        本月回笼任务 ,
        本月回笼金额 ,
        本月回笼完成率,
        本月经营性现金流 ,
        本月股东现金流
FROM    #temp
WHERE   城市公司 = '深圳项目部';

--删除临时表
DROP TABLE #temp;
