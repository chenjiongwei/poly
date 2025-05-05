USE ERP25;
GO

/*
数据迁移范围：浙南合并进浙江，齐鲁合并进山东，大连合并进辽宁，淮海合并进江苏
*/

-- 注意替换数据库名称
--DROP TABLE dqy_proj_20240613;

-- 将CompanyJoin表的公司名称改成保利里城

-- UPDATE a
-- SET DevelopmentCompanyName = '保利里城',
--     buname = '保利里城'
-- FROM ERP25.dbo.companyjoin a
-- WHERE buname = '中航里城';


-- UPDATE a
-- SET DevelopmentCompanyName = '保利里城',
--     buname = '保利里城'
-- FROM MyCost_Erp352.dbo.CompanyJoin a
-- WHERE buname = '中航里城';


--确认合约包模板是否需要迁移，如果合约包名称不一致的，可通过直接复制一份原有公司的模板到新公司，如果模板名称是一致的话，那么就判断新公司合约包是否涵盖了原有公司的合约包，如果是的话，那就不需要迁移模板
--需要迁移模板：qytype = 0
--不需要迁移模板：qytype = 1

SELECT  dc.DevelopmentCompanyName AS 平台公司,
        mp.ProjName AS 项目名称,
        mp.SpreadName AS 推广名称,
        mp.ProjCode AS 项目代码,
        mp.ProjStatus AS 项目状态,
        mp.SaleStatus AS 销售状态,
        city.ParamValue AS 所在城市,
        '山东公司' AS 所属新公司
FROM    mdm_Project mp
        INNER JOIN p_DevelopmentCompany dc 
            ON mp.DevelopmentCompanyGUID = dc.DevelopmentCompanyGUID
        LEFT JOIN (
            SELECT  ParamGUID,
                    ParamCode,
                    ParamValue
            FROM    myBizParamOption
            WHERE   ParamName = 'td_City'
        ) city 
            ON city.ParamGUID = mp.CityGUID
WHERE   dc.DevelopmentCompanyName = '齐鲁公司' AND mp.Level = 2

--- /////////////////2025年1月21日 创建新的组织架构调整待迁移项目清单///////////////////////////------------------------------


-- 修改companyjoin表中名称不一致的问题
use ERP25
-- 查询公司名称不一致的
SELECT a.buname,a.buguid,bu.BUName,bu.BUGUID 
FROM companyjoin a
INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
WHERE bu.buname<> a.buname

-- 修改
UPDATE a
SET a.buname = bu.BUName
FROM companyjoin a
INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
WHERE bu.buname<> a.buname

use MyCost_Erp352
-- 查询公司名称不一致的
SELECT a.buname,a.buguid,bu.BUName,bu.BUGUID 
FROM companyjoin a
INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
WHERE bu.buname<> a.buname

-- 修改
UPDATE a
SET a.buname = bu.BUName
FROM companyjoin a
INNER JOIN mybusinessunit bu ON a.buguid = bu.buguid
WHERE bu.buname<> a.buname

--浙南合并进浙江，齐鲁合并进山东，大连合并进辽宁，淮海合并进江苏
-- 创建新的组织架构调整待迁移项目清单
--2、齐鲁合并进山东
CREATE TABLE dqy_proj_20250411
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

DECLARE @NewDevelopmentCompanyGUID UNIQUEIDENTIFIER 
DECLARE @NewBuguid UNIQUEIDENTIFIER
DECLARE @NewBuname VARCHAR(20)

SELECT @NewDevelopmentCompanyGUID = DevelopmentCompanyGUID,
       @NewBuguid = buguid,
       @NewBuname = buname 
FROM companyjoin 
WHERE buname = '山东公司'


INSERT INTO dqy_proj_20250411
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
WHERE pj.Level =3 and  bu.buname = '齐鲁公司'
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
WHERE  pj.Level =2 and  bu.buname = '齐鲁公司'



-- 查询待迁移项目清单
SELECT 
    CASE 
        WHEN p.level = 3 THEN pp.projname 
        ELSE p.projname 
    END AS ParentProjName, 
    a.*
FROM 
     erp25.dbo.dqy_proj_20250411 a
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


