SELECT 
    p.ProjGUID,
    p.ProjName,
    p.tgprojcode,
    p.SaleStatus,
    p.ProjStatus,
    COUNT(1) AS 今年及之后预计开盘楼栋数量
    -- PlanOpenDate, FactOpenDate,
    -- PlanNotOpen, FactNotOpen 
FROM 
    data_wide_dws_mdm_Building bld
    INNER JOIN data_wide_dws_mdm_Project p 
        ON p.ProjGUID = bld.ParentProjGUID 
        AND p.Level = 2
WHERE   bld.BldType='产品楼栋' and
    YEAR(ISNULL(bld.FactOpenDate, bld.PlanOpenDate)) >= 2025
    OR YEAR(ISNULL(bld.FactNotOpen, bld.PlanNotOpen)) >= 2025
GROUP BY 
    p.ProjGUID,
    p.ProjName,
    p.tgprojcode,
    p.SaleStatus,
    p.ProjStatus


select      
    p.ProjGUID,
    p.ProjName,
    p.tgprojcode,
    p.SaleStatus,
    p.ProjStatus,
    p.begindate,
    bld.BuildingGUID,
    bld.BuildingName,
    bld.Code,
    bld.PlanOpenDate,
    bld.FactOpenDate,
    bld.PlanNotOpen,
    bld.FactNotOpen
FROM 
    data_wide_dws_mdm_Building bld
    INNER JOIN data_wide_dws_mdm_Project p 
        ON p.ProjGUID = bld.ParentProjGUID 
        AND p.Level = 2
WHERE   bld.BldType='产品楼栋' and
    YEAR(ISNULL(bld.FactOpenDate, bld.PlanOpenDate)) >= 2025
    OR YEAR(ISNULL(bld.FactNotOpen, bld.PlanNotOpen)) >= 2025