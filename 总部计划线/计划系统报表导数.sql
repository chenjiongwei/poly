SELECT dev.DevelopmentCompanyName AS [公司],
       lb.TgProjCode [投管代码],
       mpp.ProjName [项目立项名],
       mpp.SpreadName [项目案名], 
       mp.ProjName [分期],
       mpp.AcquisitionDate [项目获取时间],
       mp.ConstructStatus [分期建设状态],
       gc.BldNameList [分期包含楼栋],
       p.SumBuildArea AS [总建筑面积],
       p.SumSaleArea AS [总可售面积],
       NULL [累计开工面积],
       NULL [累计竣工面积],
       NULL [当前在建面积],
       NULL [累计销售面积],
       NULL [累计开工比例],
       NULL [累计销售比例],
       NULL [分期开工时间],
       NULL [分期首批竣工时间],
       NULL [分期末批竣备时间],
       NULL [最新版进度回顾时间],
       NULL [最新版未开工面积],
       NULL [最新版施工准备面积],
       NULL [最新版地下结构施工面积],
       NULL [最新版主体结构施工面积],
       NULL [最新版精装及园林施工面积],
       NULL [最新版查验整改面积],
       NULL [最新版已竣备未交付面积],
       NULL [最新版已交付面积],
       NULL [次新版进度回顾时间],
       NULL [次新版未开工面积],
       NULL [次新版施工准备面积],
       NULL [次新版地下结构施工面积],
       NULL [次新版主体结构施工面积],
       NULL [次新版精装及园林施工面积],
       NULL [次新版查验整改面积],
       NULL [次新版已竣备未交付面积],
       NULL [次新版已交付面积],
       NULL [新增开工],
       NULL [新增停工缓建]
FROM erp25.dbo.mdm_project mp
INNER JOIN erp25.dbo.mdm_Project mpp 
    ON mpp.ProjGUID = mp.ParentProjGUID 
    AND mpp.Level = 2
INNER JOIN (
    SELECT *
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
               *
        FROM dbo.md_Project
        WHERE ApproveState = '已审核'
              AND ISNULL(CreateReason, '') <> '补录'
              --AND CurVersion IN ( '立项版', '定位版', '修详规版', '建规证版' )
    ) x
    WHERE x.rowmo = 1
) p ON p.ProjGUID = mp.ProjGUID
left join (
    select  ProjGUID,VersionGUID,
    STRING_AGG(gc.BldName,',') within group(order by gc.BldName) as BldNameList,
    
    from md_GCBuild gc
    group by ProjGUID,VersionGUID
) gc on gc.ProjGUID = mp.ProjGUID and  gc.VersionGUID = p.VersionGUID
INNER JOIN erp25.dbo.p_DevelopmentCompany dev 
    ON dev.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
LEFT JOIN (
    SELECT ProjGUID AS ParentGUID,
           LbProjectValue AS TgProjCode
    FROM mdm_LbProject
    WHERE LbProject = 'tgid'
) lb ON lb.ParentGUID = mp.ParentProjGUID
WHERE mp.Level = 3