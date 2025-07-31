
WITH fyyj AS (
    SELECT
        t.ParentProjName  AS 项目名称,
        t.ParentProjGUID  AS 项目GUID,
        t.ProjName  AS 分期名称,
        t.ProjGUID  AS 分期GUID,
        t.BldName  AS 产品楼栋名称,
        t.BldGUID  AS 产品楼栋GUID,
        t.TopProductTypeName  AS 产品类型,
        '可售'  AS 经营属性,
        case when t.TopProductTypeName ='地下室/车库' then '是' else '否' end  AS 是否车位,
        sum(t.CNetCount)  AS 套数,

        year(t.StatisticalDate)  AS 年份,
        month(t.StatisticalDate)  AS 月份,
        sum(t.CNetArea)  AS '本月销售面积（签约）',
        sum(t.CNetAmount)  AS '本月销售金额（签约）',
        CASE WHEN sum(t.CNetArea) = 0 THEN 0 ELSE sum(t.CNetAmount)/sum(t.CNetArea) END AS '本月销售均价（签约）'
        
    FROM data_wide_dws_s_SalesPerf t
    INNER JOIN data_wide_dws_mdm_Project p ON t.ProjGUID = p.ProjGUID
    WHERE year(t.StatisticalDate) >=2025
        AND p.BUGUID ='455FC380-B609-4A5A-9AAC-EE0F84C7F1B8'
    group by 
        t.ParentProjName,
        t.ParentProjGUID,
        t.ProjName,
        t.ProjGUID,
        t.BldName,
        t.BldGUID,
        t.TopProductTypeName,
        case when t.TopProductTypeName ='地下室/车库' then '是' else '否' END,
        year(t.StatisticalDate),
        month(t.StatisticalDate)
),
wnyj AS (
    SELECT
        t.ParentProjName  AS 项目名称,
        t.ParentProjGUID  AS 项目GUID,
        t.ProjName  AS 分期名称,
        t.ProjGUID  AS 分期GUID,
        t.BldName  AS 产品楼栋名称,
        t.BldGUID  AS 产品楼栋GUID,
        sum(case when year(t.StatisticalDate)<=2024 then CNetArea else 0 end)  AS 往年及以前累计签约面积,
        sum(case when year(t.StatisticalDate)<=2024 then CNetAmount else 0 end)  AS 往年及以前累计签约金额
        
    FROM data_wide_dws_s_SalesPerf t
    INNER JOIN data_wide_dws_mdm_Project p ON t.ProjGUID = p.ProjGUID
    WHERE p.BUGUID ='455FC380-B609-4A5A-9AAC-EE0F84C7F1B8'
    GROUP BY t.ParentProjName,
        t.ParentProjGUID,
        t.ProjName,
        t.ProjGUID,
        t.BldName,
        t.BldGUID
)
SELECT 
    fyyj.*,
    wnyj.往年及以前累计签约面积,
    wnyj.往年及以前累计签约金额
FROM fyyj
LEFT JOIN wnyj ON fyyj.项目GUID = wnyj.项目GUID
    AND fyyj.分期GUID = wnyj.分期GUID
    AND fyyj.产品楼栋GUID = wnyj.产品楼栋GUID



        