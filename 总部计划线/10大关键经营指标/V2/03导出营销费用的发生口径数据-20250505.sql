SELECT projguid,
       SUM(本年签约金额) / 10000 本年签约金额
INTO #qy
FROM S_08ZYXSQYJB_HHZTSYJ_daily
WHERE DATEDIFF(dd, qxdate,GETDATE()) = 1
GROUP BY projguid;




--年度预算&年度发生（费用签约）已筛公司、预算范围			
SELECT pj.projguid,
       SUM(FactAmount1 ) / 100000000 AS '本年分摊一月已发生费用',
       SUM(FactAmount1+ FactAmount2 ) / 100000000 AS '本年分摊一月二月已发生费用',
       SUM(FactAmount1+ FactAmount2+FactAmount3) / 100000000 AS '本年分摊一月到三月已发生费用',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4) / 100000000 AS '本年分摊一月到四月已发生费用',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4+FactAmount5) / 100000000 AS '本年分摊一月到五月已发生费用',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4+FactAmount5+FactAmount6) / 100000000 AS '本年分摊一月到六月已发生费用',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4+FactAmount5+FactAmount6+FactAmount7) / 100000000 AS '本年分摊一月到七月已发生费用',
       SUM(FactAmount1 + FactAmount2 + FactAmount3 + FactAmount4 + FactAmount5 + FactAmount6 + FactAmount7
           + FactAmount8 + FactAmount9 + FactAmount10 + FactAmount11 + FactAmount12
          ) / 100000000 AS '本年已发生费用'
INTO #fy
FROM MyCost_Erp352.dbo.ys_YearPlanDept2Cost a
     INNER JOIN MyCost_Erp352.dbo.ys_DeptCost b ON b.DeptCostGUID = a.costguid
                                                   AND a.YEAR = b.YEAR
     INNER JOIN MyCost_Erp352.dbo.ys_SpecialBusinessUnit u ON a.DeptGUID = u.SpecialUnitGUID
     INNER JOIN p_project p ON u.ProjGUID = p.ProjGUID
     INNER JOIN erp25.dbo.vmdm_projectFlag pj ON p.projguid = pj.projguid
     INNER JOIN MyCost_Erp352.dbo.ys_fy_DimCost dim ON dim.costguid = a.costguid
                                                       AND dim.year = a.year
                                                       AND dim.IsEndCost = 1
WHERE a.year = YEAR(GETDATE())
AND  b.costtype = '营销类'
GROUP BY pj.projguid;



SELECT f.projguid,
       f.平台公司,
       f.项目代码,
       f.投管代码,
       f.项目名,
       f.推广名,
       f.获取时间,
       f.操盘方式,
       f.营销操盘方,
       ISNULL(qy.本年签约金额, 0) 本年签约金额,
       ISNULL(fy.本年分摊一月已发生费用, 0) 本年分摊一月已发生费用,
       ISNULL(fy.本年分摊一月二月已发生费用, 0) 本年分摊一月二月已发生费用,
       ISNULL(fy.本年分摊一月到三月已发生费用, 0) 本年分摊一月到三月已发生费用,
       ISNULL(fy.本年分摊一月到四月已发生费用, 0) 本年分摊一月到四月已发生费用,
       ISNULL(fy.本年分摊一月到五月已发生费用, 0) 本年分摊一月到五月已发生费用,
       ISNULL(fy.本年分摊一月到六月已发生费用, 0) 本年分摊一月到六月已发生费用,
       ISNULL(fy.本年分摊一月到七月已发生费用, 0) 本年分摊一月到七月已发生费用,
       ISNULL(fy.本年已发生费用, 0) 本年已发生费用
FROM vmdm_projectflag f
     LEFT JOIN #qy qy ON f.projguid = qy.projguid
     LEFT JOIN #fy fy ON f.projguid = fy.projguid
ORDER BY f.平台公司,
         f.项目代码;

DROP TABLE #fy,
           #qy;
