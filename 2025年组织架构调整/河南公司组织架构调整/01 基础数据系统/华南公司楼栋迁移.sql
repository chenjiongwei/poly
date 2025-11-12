--迁移脚本
--赋值新旧分期
declare @old_projguid varchar(max)= '9A3ED978-9630-E711-80BA-E61F13C57837'
declare @new_projguid varchar(max)= '10B3BA01-9A30-E711-80BA-E61F13C57837'



select a.GCBldGUID,a.salebldguid,@old_projguid oldprojguid,@new_projguid newProjguid
INTO #t
from erp25_test.dbo.p_lddbamj	 a
where a.gcbldguid in (
'71CD183F-7E42-4402-9178-7E2BBC9D5B27',
'114988A1-90C3-4F3E-9484-808A0F0FD817',
'630D3782-A645-4615-9355-9C1A148D9149',
'26D544E3-F2DF-40D6-BFE3-C834E454D389',
'FB5A30D3-89B9-4214-9F57-C8495E270D1A',
'A1C46552-6971-4F23-B3A4-E302E8DAFF48')
and datediff(day,qxdate,getdate())=0

--销售
SELECT a.BldGUID,a.ProjGUID,t.newProjguid,a.ParentCode ,p.ProjCode,a.BldCode,a.*
FROM dbo.p_Building a
INNER JOIN #t t ON a.BldGUID = t.SaleBldGUID
INNER JOIN p_project p ON t.newProjguid = p.ProjGUID
WHERE a.ProjGUID<> t.newProjguid

UPDATE a SET a.ProjGUID= t.newProjguid
FROM dbo.p_Building a
INNER JOIN #t t ON a.BldGUID = t.SaleBldGUID
INNER JOIN p_project p ON t.newProjguid = p.ProjGUID
WHERE a.ProjGUID<> t.newProjguid

--投管
SELECT a.GCBldGUID,a.ProjGUID,t.newProjguid
FROM dbo.mdm_GCBuild a 
INNER JOIN #t t ON t.GCBldGUID = a.GCBldGUID
WHERE a.ProjGUID<> t.newProjguid

UPDATE a SET a.ProjGUID= t.newProjguid
FROM dbo.mdm_GCBuild a 
INNER JOIN #t t ON t.GCBldGUID = a.GCBldGUID
WHERE a.ProjGUID<> t.newProjguid

--基础数据工程楼栋
SELECT a.BldGUID,a.ProjGUID ,t.newProjguid
FROM MyCost_Erp352_ceshi.dbo.md_GCBuild a
INNER JOIN #t t ON a.BldGUID = t.GCBldGUID
WHERE a.ProjGUID<> t.newProjguid

UPDATE a SET a.ProjGUID= t.newProjguid
FROM MyCost_Erp352_ceshi.dbo.md_GCBuild a
INNER JOIN #t t ON a.BldGUID = t.GCBldGUID
WHERE a.ProjGUID<> t.newProjguid

--基础数据产品楼栋
SELECT a.ProductBuildGUID,a.ProjGUID ,t.newProjguid
FROM MyCost_Erp352_ceshi.dbo.md_ProductBuild a
INNER JOIN #t t ON a.ProductBuildGUID = t.SaleBldGUID
WHERE a.ProjGUID<> t.newProjguid

UPDATE a SET a.ProjGUID= t.newProjguid
FROM MyCost_Erp352_ceshi.dbo.md_ProductBuild a
INNER JOIN #t t ON a.ProductBuildGUID = t.SaleBldGUID
WHERE a.ProjGUID<> t.newProjguid
--组团-标段 通过前台处理


DROP TABLE #t