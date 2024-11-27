
--统计各项目的本月任务完成情况
SELECT  org.清洗时间,
        org.组织架构类型 ,
        org.组织架构类型名称 ,
        org.组织架构名称 ,
        org.项目guid ,
        org.项目代码 ,
        org.项目名称 ,
        org.平台公司GUID ,
        org.平台公司名称 ,
        base.区域 ,
        base.项目状态 ,
        base.工程状态 ,
        base.销售片区 ,
        sale.本月签约任务 ,
        sale.本月签约金额 ,
        CASE WHEN ISNULL(sale.本月签约任务, 0) = 0 THEN null ELSE ISNULL(sale.本月签约金额, 0) / ISNULL(sale.本月签约任务, 0)END AS 本月签约完成率 ,
        hl.本月回笼任务 ,
        hl.本月回笼金额 ,
        CASE WHEN ISNULL(hl.本月回笼任务, 0) = 0 THEN null ELSE ISNULL(hl.本月回笼金额, 0) / ISNULL(hl.本月回笼任务, 0)END AS 本月回笼完成率
INTO    #qyhlTemp
FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_baseinfo base ON org.组织架构id = base.组织架构id and org.清洗时间id = base.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and org.清洗时间id = sale.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_ProfitInfo profit ON profit.组织架构id = org.组织架构id and org.清洗时间id = profit.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and org.清洗时间id = hl.清洗时间id
WHERE   1 = 1 AND   org.组织架构类型 = 3 
    AND  org.平台公司名称 = '湾区公司' AND base.项目状态 <> '清算退出' 
    AND (ISNULL(sale.本月签约任务, 0) <> 0 OR ISNULL(hl.本月回笼任务, 0) <> 0);

--查询结果
--3、排名按照签约回笼完成比例各占50%。
SELECT  convert(datetime, 清洗时间 ) as 清洗时间,
        ROW_NUMBER() OVER ( PARTITION BY 清洗时间  ORDER BY(ISNULL(本月签约完成率, 0) * 0.5 + ISNULL(本月回笼完成率, 0) * 0.5) DESC) AS 倒序排序 ,
        ROW_NUMBER() OVER (  PARTITION BY 清洗时间 ORDER BY(ISNULL(本月签约完成率, 0) * 0.5 + ISNULL(本月回笼完成率, 0) * 0.5)) AS 正序排序 ,
        (ISNULL(本月签约完成率, 0) * 0.5 + ISNULL(本月回笼完成率, 0) * 0.5) AS 完成率排序 ,
        平台公司名称 ,
        平台公司GUID ,
        项目guid ,
        项目代码 ,
        项目名称 ,
        区域 AS 项目部 ,
        本月签约任务 ,
        本月签约金额 ,
        本月签约完成率 ,
        本月回笼任务 ,
        本月回笼金额 ,
        本月回笼完成率
INTO    #RskqyhlTemp
FROM    #qyhlTemp a;

--WHERE(ISNULL(本月签约完成率, 0) * 0.5 + ISNULL(本月回笼完成率, 0) * 0.5) >= 0;

----红黑榜
SELECT  CASE WHEN 倒序排序 BETWEEN 1 AND 3 THEN '红榜' WHEN 正序排序 BETWEEN 1 AND 2 THEN '黑榜' ELSE '普通' END AS 红黑榜 ,
        CONVERT(VARCHAR(10), MONTH(GETDATE())) + '月' AS 月份 ,
        CONVERT(VARCHAR(10), DAY(GETDATE())) + '日' AS 日期 ,
        *
FROM    #RskqyhlTemp
ORDER BY 倒序排序;

--删除临时表 
DROP TABLE #qyhlTemp ,
           #RskqyhlTemp;
