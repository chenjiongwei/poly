-- 保利系统里面，同一个项目下包含的可售可经营的产品类型数量、公建配套的产品类型最大数量
SELECT 
    dc.DevelopmentCompanyname, 
    a.DevelopmentCompanyGUID,
    a.ProjCode,
    a.ProjGUID,
    a.ProjName,
    COUNT( CASE WHEN pdt.IsSale = '是' AND pdt.IsHold = '否' THEN ProductType END) AS 可售可经营产品类型数量,
    COUNT( CASE WHEN ProductType = '公建配套' THEN ProductType END) AS 公建配套的产品类型数量
FROM 
    md_Product pdt
INNER JOIN 
    (
        SELECT 
            VersionGUID,
            level,
            DevelopmentCompanyGUID,
            ProjName,
            ProjCode, 
            ProjGUID,
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) rowno 
        FROM  
            md_Project  
        WHERE 
            IsActive = 1 
            AND Level = 2
    ) a ON a.VersionGUID = pdt.VersionGUID AND a.ProjGUID = pdt.ProjGUID AND a.rowno = 1 --项目必须要有激活版，否则排除掉 
INNER JOIN 
    erp25.dbo.p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = a.DevelopmentCompanyGUID
GROUP BY  
    dc.DevelopmentCompanyname,  
    a.DevelopmentCompanyGUID,
    a.ProjCode,
    a.ProjGUID,
    a.ProjName

-- 查询产品明细
select dc.DevelopmentCompanyname, a.DevelopmentCompanyGUID,a.ProjCode,a.ProjGUID,a.ProjName,a.VersionGUID,
pdt.IsSale,pdt.HoldRate,ProductType,ProductName
from md_Product pdt
inner join (
SELECT VersionGUID,level,DevelopmentCompanyGUID,ProjName,ProjCode, ProjGUID,ROW_NUMBER() OVER ( PARTITION BY ProjGUID ORDER BY CreateDate DESC ) rowno 
FROM  md_Project  
where IsActive = 1 and Level =2) a on  a.VersionGUID =pdt.VersionGUID  and a.ProjGUID = pdt.ProjGUID and a.rowno=1 --项目必须要有激活版，否则排除掉 
inner  join erp25.dbo.p_DevelopmentCompany dc on dc.DevelopmentCompanyGUID =a.DevelopmentCompanyGUID



-- 还有同一个分期下包含的可售可经营的产品数量、公建配套的产品最大数量谁帮忙查下
SELECT 
    dc.DevelopmentCompanyname as 平台公司, 
    a.DevelopmentCompanyGUID,
    pp.ProjCode as 项目编码,
    pp.ProjName as 项目名称,
    pp.ProjGUID as 项目GUID,
    a.ProjGUID as 分期GUID,
    a.ProjName as 分期名称,
    a.ProjCode as 分期编码,
    COUNT( CASE WHEN pdt.IsSale = '是' AND pdt.HoldRate = 0 THEN ProductType END) AS 可售可经营产品类型数量,
    COUNT( CASE WHEN ProductType = '公建配套' THEN ProductType END) AS 公建配套的产品类型数量
FROM 
    md_Product pdt
INNER JOIN 
    (
        SELECT 
            VersionGUID,
            level,
            DevelopmentCompanyGUID,
            ProjName,
            ProjCode, 
            ParentProjGUID,
            ProjGUID,
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) rowno 
        FROM  
            md_Project  
        WHERE 
            IsActive = 1 
            AND Level = 3
    ) a ON a.VersionGUID = pdt.VersionGUID AND a.ProjGUID = pdt.ProjGUID AND a.rowno = 1 --项目必须要有激活版，否则排除掉 
inner join erp25.dbo.p_Project pp on pp.ProjGUID = a.ParentProjGUID and  pp.level = 2
INNER JOIN 
    erp25.dbo.p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = a.DevelopmentCompanyGUID
GROUP BY  
    dc.DevelopmentCompanyname, 
    a.DevelopmentCompanyGUID,
    pp.ProjCode ,
    pp.ProjName ,
    pp.ProjGUID,
    a.ProjGUID,
    a.ProjName,
    a.ProjCode

-- 查询产品明细
select 
    dc.DevelopmentCompanyname as 平台公司, 
    a.DevelopmentCompanyGUID,
    pp.ProjCode as 项目编码,
    pp.ProjName as 项目名称,
    pp.ProjGUID as 项目GUID,
    a.ProjGUID as 分期GUID,
    a.ProjName as 分期名称,
    a.ProjCode as 分期编码, a.VersionGUID,
    pdt.IsSale,pdt.HoldRate,ProductType,ProductName
FROM 
    md_Product pdt
INNER JOIN 
    (
        SELECT 
            VersionGUID,
            level,
            DevelopmentCompanyGUID,
            ProjName,
            ProjCode, 
            ParentProjGUID,
            ProjGUID,
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) rowno 
        FROM  
            md_Project  
        WHERE 
            IsActive = 1 
            AND Level = 3
    ) a ON a.VersionGUID = pdt.VersionGUID AND a.ProjGUID = pdt.ProjGUID AND a.rowno = 1 --项目必须要有激活版，否则排除掉 
inner join erp25.dbo.p_Project pp on pp.ProjGUID = a.ParentProjGUID and  pp.level = 2
INNER JOIN erp25.dbo.p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = a.DevelopmentCompanyGUID