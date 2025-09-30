-- 公司资源情况填报
SELECT 
    mpp.DevelopmentCompanyGUID,
    mpp.SpreadName            AS 项目推广名,
    mpp.ProjGUID              AS 项目GUID,
    mpp.ProjCode              AS 项目代码,
    mp.ProjGUID               AS 分期GUID,
    mp.ProjName               AS 分期名称,
    ISNULL(gc.BldName, gc.BldCode) AS 工程楼栋名称,
    ISNULL(sb.BldName, sb.BldCode) AS 产品楼栋名称,
    sb.SaleBldGUID            AS 产品楼栋GUID,
    gc.GCBldGUID              AS 工程楼栋GUID,
    pdt.ProductType           AS 产品类型,
    pdt.ProductName           AS 产品名称,
    isnull(b.isStopWork,'正常') as  是否停工,
    tag.BuildTagValue         AS 赛道图楼栋标签
FROM 
    mdm_project mp
    INNER JOIN mdm_project mpp  ON mpp.ProjGUID = mp.ParentProjGUID
    LEFT JOIN mdm_GCBuild gc  ON gc.ProjGUID = mp.ProjGUID
    LEFT JOIN mdm_SaleBuild sb   ON sb.GCBldGUID = gc.GCBldGUID
    LEFT JOIN mdm_Product pdt  ON pdt.ProductGUID = sb.ProductGUID 
        AND pdt.ProjGUID = mp.ProjGUID
    left join  [172.16.4.161].[HighData_prod].dbo.data_wide_dws_mdm_Building b on b.BuildingGUID = sb.SaleBldGUID and  b.BldType ='产品楼栋'
    LEFT JOIN mdm_BuildTag tag 
        ON tag.SaleBldGUID = sb.SaleBldGUID 
        AND tag.BuildTag = 'SDT'
WHERE  
    mp.Level = 3 
    AND mp.DevelopmentCompanyGUID = 'C69E89BB-A2DB-E511-80B8-E41F13C51836' -- 湾区公司
ORDER BY 
    mpp.DevelopmentCompanyGUID,
    mpp.ProjCode,
    gc.GCBldGUID
-- 处置前五类	
-- 处置后去向
