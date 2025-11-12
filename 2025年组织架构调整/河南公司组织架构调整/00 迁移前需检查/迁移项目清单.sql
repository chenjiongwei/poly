

--DROP TABLE dqy_proj_20251027

CREATE TABLE dqy_proj_20251027
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
    OldParentprojguid UNIQUEIDENTIFIER,
    OldParentprojCode352 VARCHAR(200),
    NewParentprojguid UNIQUEIDENTIFIER,
    NewParentprojCode25 VARCHAR(200),
    NewParentprojCode352 VARCHAR(200),
    项目分类 VARCHAR(20),
    qytype INT
);

DECLARE @NewDevelopmentCompanyGUID UNIQUEIDENTIFIER 
DECLARE @NewBuguid UNIQUEIDENTIFIER
DECLARE @NewBuname VARCHAR(20)

SELECT @NewDevelopmentCompanyGUID = DevelopmentCompanyGUID,
       @NewBuguid = bu.buguid,
       @NewBuname = bu.buname 
FROM companyjoin 
INNER JOIN  dbo.myBusinessUnit  bu ON bu.BUGUID =companyjoin.buguid AND  bu.IsEndCompany =1
WHERE bu.buname = '河南公司'



INSERT INTO dqy_proj_20251027
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
       pj.ParentProjGUID AS OldParentprojguid,   
       (
                select
                        top 1 projcode
                from
                        MyCost_Erp352.dbo.p_Project 
                where
                        level = 2
                        and projguid =pj.ParentProjGUID
        )  as OldParentprojCode352,
        'b5393568-beaf-f011-b3a7-f40270d39969'  AS NewParentprojguid, -- 郑州市高新区文广二期66亩
       '0371034' as NewParentprojCode25, -- 投管和基础数据项目代码
       (
                select
                        top 1 projcode
                from
                        MyCost_Erp352.dbo.p_Project 
                where
                        level = 2
                        and projguid ='b5393568-beaf-f011-b3a7-f40270d39969'
        ) as NewParentprojCode352,-- 成本系统项目代码
       CASE
           WHEN pj.Level = 2 THEN
               '一级项目'
           ELSE
               '分期'
       END AS 项目类别,
       1 AS qytype                --  默认为0
FROM erp25.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352.dbo.p_Project p
    ) p352  ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN erp25.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
    INNER JOIN  MyCost_Erp352.dbo.myBusinessUnit  unit ON bu.BUGUID =unit.buguid AND  unit.IsEndCompany =1
WHERE pj.Level =3 
-- and pj.projguid ='5F4A536B-D813-E911-80BF-E61F13C57837' -- 杓苑3号地
and  pj.ProjGUID ='0e63e1ad-4703-4a95-b661-9e8e415e041f' -- 杓袁7号地



-- http://172.16.8.131/PubProject/Project/Project_Form.aspx?mode=2&funcid=01010102&oid=b5393568-beaf-f011-b3a7-f40270d39969&isshare=0&Type=0&level=1&WorkMode=1
-- 查询待迁移项目清单
SELECT 
    a.*
FROM 
     erp25.dbo.dqy_proj_20251027 a
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