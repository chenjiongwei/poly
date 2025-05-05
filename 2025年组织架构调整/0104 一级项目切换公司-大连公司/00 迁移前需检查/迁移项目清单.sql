USE ERP25;
GO

--- /////////////////2025年4月21日 创建新的组织架构调整待迁移项目清单///////////////////////////------------------------------

-- 修改companyjoin表中名称不一致的问题
-- 查询公司名称不一致的
-- SELECT a.buname,a.buguid,bu.BUName,bu.BUGUID 
-- FROM companyjoin a
-- INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
-- WHERE bu.buname<> a.buname

-- -- 修改
-- UPDATE a
-- SET a.buname = bu.BUName
-- FROM companyjoin a
-- INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
-- WHERE bu.buname<> a.buname

-- use MyCost_Erp352
-- -- 查询公司名称不一致的
-- SELECT a.buname,a.buguid,bu.BUName,bu.BUGUID 
-- FROM companyjoin a
-- INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
-- WHERE bu.buname<> a.buname

-- -- 修改
-- UPDATE a
-- SET a.buname = bu.BUName
-- FROM companyjoin a
-- INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
-- WHERE bu.buname<> a.buname

--浙南合并进浙江，齐鲁合并进山东，大连合并进辽宁，淮海合并进江苏
-- 创建新的组织架构调整待迁移项目清单
CREATE TABLE dqy_proj_20250424
(
    NewDevelopmentCompanyGUID UNIQUEIDENTIFIER, --迁移后平台公司guid
    NewBuguid UNIQUEIDENTIFIER,                 --迁移后公司guid,
    NewBuname VARCHAR(20),
    OldDevelopmentCompanyGUID UNIQUEIDENTIFIER, --迁移前平台公司guid
    OldBuguid UNIQUEIDENTIFIER,                 --迁移前公司guid,
    OldBuname VARCHAR(20),
    OldProjGuid UNIQUEIDENTIFIER,               --老项目guid
    OldProjName VARCHAR(200),                   --老项目名称
    projcode25 VARCHAR(200),
    projcode352 VARCHAR(200),
    项目分类 VARCHAR(20),
    qytype INT
);

-- 1、大连合并进辽宁

DECLARE @NewDevelopmentCompanyGUID UNIQUEIDENTIFIER 
DECLARE @NewBuguid UNIQUEIDENTIFIER
DECLARE @NewBuname VARCHAR(20)

SELECT @NewDevelopmentCompanyGUID = DevelopmentCompanyGUID,
       @NewBuguid = buguid,
       @NewBuname = buname 
FROM companyjoin 
WHERE buname = '辽宁公司'


INSERT INTO dqy_proj_20250424
--分期
SELECT @NewDevelopmentCompanyGUID AS NewDevelopmentCompanyGUID,
       @NewBuguid newbuguid,
       @NewBuname AS newbuname,
       pj.DevelopmentCompanyGUID AS OldDevelopmentCompanyGUID,
       bu.buguid AS oldbuguid,
       bu.buname AS oldbuname,
       pj.ProjGUID AS oldprojguid,
       SpreadName AS oldprojname, -- 推广名
       pj.ProjCode projcode25,
       p352.ProjCode projcode352,
       CASE
           WHEN pj.Level = 2 THEN
               '一级项目'
           ELSE
               '分期'
       END AS 项目类别,
       1 AS qytype                --  默认为0
FROM ERP25.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352.dbo.p_Project p
    ) p352  ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE pj.Level =3 and  bu.buname = '大连公司'
UNION ALL
-- 一级项目
SELECT @NewDevelopmentCompanyGUID AS NewDevelopmentCompanyGUID,
       @NewBuguid newbuguid,
       @NewBuname AS newbuname,
       pj.DevelopmentCompanyGUID AS OldDevelopmentCompanyGUID,
       bu.buguid AS oldbuguid,
       bu.buname AS oldbuname,
       pj.ProjGUID AS oldprojguid,
       SpreadName AS oldprojname, -- 推广名
       pj.ProjCode projcode25,
       p352.ProjCode projcode352,
       CASE
           WHEN pj.Level = 2 THEN
               '一级项目'
           ELSE
               '分期'
       END AS 项目类别,
       1 AS qytype
FROM ERP25.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352.dbo.p_Project p
    ) p352 ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE  pj.Level =2 and  bu.buname = '大连公司'

-- 查询待迁移项目清单
-- 查询长春公司
SELECT 
    CASE 
        WHEN p.level = 3 THEN pp.projname 
        ELSE p.projname 
    END AS ParentProjName, 
    a.*
FROM 
     erp25.dbo.dqy_proj_20250424 a
INNER JOIN 
    erp25.dbo.mdm_project p ON a.OldProjGuid = p.projguid
LEFT JOIN 
    erp25.dbo.mdm_project pp ON pp.projguid = p.ParentProjGUID
ORDER BY 
    CASE 
        WHEN p.level = 3 THEN pp.projname 
        ELSE p.projname 
    END, 
    projcode25;


