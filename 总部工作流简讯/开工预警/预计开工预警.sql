
-- 累计开工
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       公司,
       投管项目名称 项目名,
       项目分期 分期,
       标段名称 标段,
       --计划组团名称 组团,
       --是否为首开组团,
       ISNULL(实际开工预计完成时间, 实际开工计划完成时间) 预计开工时间,
       SUM(计划组团建筑面积) 面积
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport]
WHERE [实际开工实际完成时间] IS  NULL
      AND ISNULL(实际开工预计完成时间, 实际开工计划完成时间) > GETDATE()
      AND DATEDIFF(dd, GETDATE(), ISNULL(实际开工预计完成时间, 实际开工计划完成时间)) < 90
GROUP BY 公司,
         投管项目名称,
         项目分期,
         标段名称,
         ISNULL(实际开工预计完成时间, 实际开工计划完成时间);


-- 本月预计开工
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       公司,
       投管项目名称 项目名,
       项目分期 分期,
       标段名称 标段,
       --计划组团名称 组团,
       --是否为首开组团,
       ISNULL(实际开工预计完成时间, 实际开工计划完成时间) 预计开工时间,
       SUM(计划组团建筑面积) 面积
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport]
WHERE [实际开工实际完成时间] IS  NULL
      AND ISNULL(实际开工预计完成时间, 实际开工计划完成时间) > GETDATE()
      AND DATEDIFF(month, GETDATE(), ISNULL(实际开工预计完成时间, 实际开工计划完成时间)) =0
GROUP BY 公司,
         投管项目名称,
         项目分期,
         标段名称,
         ISNULL(实际开工预计完成时间, 实际开工计划完成时间);

-- 下月预计开工
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       公司,
       投管项目名称 项目名,
       项目分期 分期,
       标段名称 标段,
       --计划组团名称 组团,
       --是否为首开组团,
       ISNULL(实际开工预计完成时间, 实际开工计划完成时间) 预计开工时间,
       SUM(计划组团建筑面积) 面积
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport]
WHERE [实际开工实际完成时间] IS  NULL
      AND ISNULL(实际开工预计完成时间, 实际开工计划完成时间) > GETDATE()
      AND DATEDIFF(month, GETDATE(), ISNULL(实际开工预计完成时间, 实际开工计划完成时间)) =1
GROUP BY 公司,
         投管项目名称,
         项目分期,
         标段名称,
         ISNULL(实际开工预计完成时间, 实际开工计划完成时间);

-- 下下月预计开工
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       公司,
       投管项目名称 项目名,
       项目分期 分期,
       标段名称 标段,
       --计划组团名称 组团,
       --是否为首开组团,
       ISNULL(实际开工预计完成时间, 实际开工计划完成时间) 预计开工时间,
       SUM(计划组团建筑面积) 面积
FROM [MyCost_Erp352].[dbo].[jd_PlanTaskExecuteObjectForReport]
WHERE [实际开工实际完成时间] IS  NULL
      AND ISNULL(实际开工预计完成时间, 实际开工计划完成时间) > GETDATE()
      AND DATEDIFF(month, GETDATE(), ISNULL(实际开工预计完成时间, 实际开工计划完成时间)) >1
      AND DATEDIFF(dd, GETDATE(), ISNULL(实际开工预计完成时间, 实际开工计划完成时间)) < 90
GROUP BY 公司,
         投管项目名称,
         项目分期,
         标段名称,
         ISNULL(实际开工预计完成时间, 实际开工计划完成时间);