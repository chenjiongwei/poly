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

CREATE TABLE dqy_proj_20240613
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

INSERT INTO dqy_proj_20240613
--分期
SELECT NULL AS NewDevelopmentCompanyGUID,
       NULL newbuguid,
       NULL AS newbuname,
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
       0 AS qytype                --  默认为0
FROM ERP25.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352.dbo.p_Project p
    ) p352
        ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25.dbo.companyjoin bu
        ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE pj.ProjGUID IN ( '4BA1C8D9-F10F-E911-80BF-E61F13C57837', '02CE6907-CD2D-4387-A810-0DA3FF0ACACA',
                       'BBADA202-CB1A-4A20-8F22-FFF9EC399A50', 'A79AEFE3-8223-41AD-8B53-CBFD994ACBDA',
                       'DD4D7608-A9F7-4CB4-8E26-23AE39EF1611', 'EBCE1211-CD0E-EB11-B398-F40270D39969',
                       '1590B64A-1178-EB11-B398-F40270D39969', '0ADA93A5-F20F-E911-80BF-E61F13C57837',
                       '81AEA2F0-3018-EB11-B398-F40270D39969', '7E7DA193-F20F-E911-80BF-E61F13C57837',
                       'BD5F3657-6BB0-4786-A96D-008927784637', 'EF5A7E70-97D2-459F-9555-A65B6AC4E63F',
                       '6DF9A29E-C38A-41AE-90E6-781C10EAB4DC', '7AA32C69-1315-EC11-B398-F40270D39969',
                       'B5E63497-329B-484D-A95B-8D6CBBB13890', 'B803BD21-F20F-E911-80BF-E61F13C57837',
                       'ADF3AF2D-F20F-E911-80BF-E61F13C57837', '79071E3A-B873-4DDE-96BF-D738470DE19D',
                       'C1E6322F-CD0E-EB11-B398-F40270D39969', 'D5F9BB45-F20F-E911-80BF-E61F13C57837',
                       '9642BA57-F20F-E911-80BF-E61F13C57837', '7264B169-F20F-E911-80BF-E61F13C57837',
                       'E4845487-A1BA-451D-98FD-65CC61C742B4', '83AA5BB8-0F82-EB11-B398-F40270D39969',
                       '283293FC-60B1-4966-861E-B4EE9344B196', 'D5FAEEF5-7A51-4D0B-9659-619F6CDD643F',
                       '68998E4A-3BEE-4AD6-9B5A-EDD423A752D1'
                     )
UNION ALL
-- 一级项目
SELECT NULL AS NewDevelopmentCompanyGUID,
       NULL newbuguid,
       NULL AS newbuname,
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
       0 AS qytype
FROM ERP25.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352.dbo.p_Project p
    ) p352
        ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25.dbo.companyjoin bu
        ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE pj.ProjGUID IN
      (
          SELECT ParentProjGUID
          FROM ERP25.dbo.mdm_Project p
          WHERE p.ProjGUID IN ( '4BA1C8D9-F10F-E911-80BF-E61F13C57837', '02CE6907-CD2D-4387-A810-0DA3FF0ACACA',
                                'BBADA202-CB1A-4A20-8F22-FFF9EC399A50', 'A79AEFE3-8223-41AD-8B53-CBFD994ACBDA',
                                'DD4D7608-A9F7-4CB4-8E26-23AE39EF1611', 'EBCE1211-CD0E-EB11-B398-F40270D39969',
                                '1590B64A-1178-EB11-B398-F40270D39969', '0ADA93A5-F20F-E911-80BF-E61F13C57837',
                                '81AEA2F0-3018-EB11-B398-F40270D39969', '7E7DA193-F20F-E911-80BF-E61F13C57837',
                                'BD5F3657-6BB0-4786-A96D-008927784637', 'EF5A7E70-97D2-459F-9555-A65B6AC4E63F',
                                '6DF9A29E-C38A-41AE-90E6-781C10EAB4DC', '7AA32C69-1315-EC11-B398-F40270D39969',
                                'B5E63497-329B-484D-A95B-8D6CBBB13890', 'B803BD21-F20F-E911-80BF-E61F13C57837',
                                'ADF3AF2D-F20F-E911-80BF-E61F13C57837', '79071E3A-B873-4DDE-96BF-D738470DE19D',
                                'C1E6322F-CD0E-EB11-B398-F40270D39969', 'D5F9BB45-F20F-E911-80BF-E61F13C57837',
                                '9642BA57-F20F-E911-80BF-E61F13C57837', '7264B169-F20F-E911-80BF-E61F13C57837',
                                'E4845487-A1BA-451D-98FD-65CC61C742B4', '83AA5BB8-0F82-EB11-B398-F40270D39969',
                                '283293FC-60B1-4966-861E-B4EE9344B196', 'D5FAEEF5-7A51-4D0B-9659-619F6CDD643F',
                                '68998E4A-3BEE-4AD6-9B5A-EDD423A752D1'
                              )
      );

--//////更新迁移后的公司信息
-- 调整海西公司
-- 查询
--SELECT  *
--FROM    dqy_proj_20240613
--WHERE   projcode25 LIKE '0592006%' OR   projcode25 LIKE '0595004%' OR   projcode25 LIKE '0595006%'
--ORDER BY projcode25;


-- 调整
UPDATE dqy_proj_20240613
SET NewBuguid =
    (
        SELECT BUGUID
        FROM myBusinessUnit
        WHERE BUName = '海西公司'
              AND IsEndCompany = 1
    ),
    NewBuname =
    (
        SELECT BUName
        FROM myBusinessUnit
        WHERE BUName = '海西公司'
              AND IsEndCompany = 1
    ),
    NewDevelopmentCompanyGUID =
    (
        SELECT DevelopmentCompanyGUID
        FROM p_DevelopmentCompany
        WHERE DevelopmentCompanyName = '海西公司'
    )
WHERE projcode25 LIKE '0592006%'
      OR projcode25 LIKE '0595004%'
      OR projcode25 LIKE '0595006%';

-- 调整湖南公司
-- 查询
--SELECT  *
--FROM    dqy_proj_20240613
--WHERE   projcode25 LIKE '0731015%' OR   projcode25 LIKE '0731025%'
--ORDER BY projcode25;

-- 调整
UPDATE dqy_proj_20240613
SET NewBuguid =
    (
        SELECT BUGUID
        FROM myBusinessUnit
        WHERE BUName = '湖南公司'
              AND IsEndCompany = 1
    ),
    NewBuname =
    (
        SELECT BUName
        FROM myBusinessUnit
        WHERE BUName = '湖南公司'
              AND IsEndCompany = 1
    ),
    NewDevelopmentCompanyGUID =
    (
        SELECT DevelopmentCompanyGUID
        FROM p_DevelopmentCompany
        WHERE DevelopmentCompanyName = '湖南公司'
    )
WHERE projcode25 LIKE '0731015%'
      OR projcode25 LIKE '0731025%';

-- 调整江苏公司
-- 查询
--SELECT  *
--FROM    dqy_proj_20240613
--WHERE   projcode25 LIKE '0025032%' OR   projcode25 LIKE '0025033%' OR   projcode25 LIKE '0025034%' OR   projcode25 LIKE '0025039%' OR   projcode25 LIKE '0025048%'
--ORDER BY projcode25;

-- 调整
UPDATE dqy_proj_20240613
SET NewBuguid =
    (
        SELECT BUGUID
        FROM myBusinessUnit
        WHERE BUName = '江苏公司'
              AND IsEndCompany = 1
    ),
    NewBuname =
    (
        SELECT BUName
        FROM myBusinessUnit
        WHERE BUName = '江苏公司'
              AND IsEndCompany = 1
    ),
    NewDevelopmentCompanyGUID =
    (
        SELECT DevelopmentCompanyGUID
        FROM p_DevelopmentCompany
        WHERE DevelopmentCompanyName = '江苏公司'
    )
WHERE projcode25 LIKE '0025032%'
      OR projcode25 LIKE '0025033%'
      OR projcode25 LIKE '0025034%'
      OR projcode25 LIKE '0025039%'
      OR projcode25 LIKE '0025048%';

-- 调整陕西公司
-- 查询
--SELECT  *
--FROM    dqy_proj_20240613
--WHERE   projcode25 LIKE '0029008%' OR   projcode25 LIKE '0029023%'
--ORDER BY projcode25;

-- 调整
UPDATE dqy_proj_20240613
SET NewBuguid =
    (
        SELECT BUGUID
        FROM myBusinessUnit
        WHERE BUName = '陕西公司'
              AND IsEndCompany = 1
    ),
    NewBuname =
    (
        SELECT BUName
        FROM myBusinessUnit
        WHERE BUName = '陕西公司'
              AND IsEndCompany = 1
    ),
    NewDevelopmentCompanyGUID =
    (
        SELECT DevelopmentCompanyGUID
        FROM p_DevelopmentCompany
        WHERE DevelopmentCompanyName = '陕西公司'
    )
WHERE projcode25 LIKE '0029008%'
      OR projcode25 LIKE '0029023%';

-- 调整云南公司
-- 查询
--SELECT  *
--FROM    dqy_proj_20240613
--WHERE   projcode25 LIKE '0871001%' OR   projcode25 LIKE '0871005%'
--ORDER BY projcode25;

-- 调整
UPDATE dqy_proj_20240613
SET NewBuguid =
    (
        SELECT BUGUID
        FROM myBusinessUnit
        WHERE BUName = '云南公司'
              AND IsEndCompany = 1
    ),
    NewBuname =
    (
        SELECT BUName
        FROM myBusinessUnit
        WHERE BUName = '云南公司'
              AND IsEndCompany = 1
    ),
    NewDevelopmentCompanyGUID =
    (
        SELECT DevelopmentCompanyGUID
        FROM p_DevelopmentCompany
        WHERE DevelopmentCompanyName = '云南公司'
    )
WHERE projcode25 LIKE '0871001%'
      OR projcode25 LIKE '0871005%';

-- 调整重庆公司
-- 查询
--SELECT  *
--FROM    dqy_proj_20240613
--WHERE   projcode25 LIKE '0023025%'
--ORDER BY projcode25;

-- 调整
UPDATE dqy_proj_20240613
SET NewBuguid =
    (
        SELECT BUGUID
        FROM myBusinessUnit
        WHERE BUName = '重庆公司'
              AND IsEndCompany = 1
    ),
    NewBuname =
    (
        SELECT BUName
        FROM myBusinessUnit
        WHERE BUName = '重庆公司'
              AND IsEndCompany = 1
    ),
    NewDevelopmentCompanyGUID =
    (
        SELECT DevelopmentCompanyGUID
        FROM p_DevelopmentCompany
        WHERE DevelopmentCompanyName = '重庆公司'
    )
WHERE projcode25 LIKE '0023025%';

-- 查询最后结果表
SELECT *
FROM dqy_proj_20240613
ORDER BY projcode25;

-- 将项目清单表插入到EPR352的数据库
SELECT *
INTO MyCost_Erp352.dbo.dqy_proj_20240613
FROM dqy_proj_20240613;


--- /////////////////2025年1月21日 创建新的组织架构调整待迁移项目清单///////////////////////////------------------------------

-- 修改companyjoin表中名称不一致的问题
use ERP25_test
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

use MyCost_Erp352_ceshi
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
CREATE TABLE dqy_proj_20250121
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

-- 1、浙南合并进浙江

DECLARE @NewDevelopmentCompanyGUID UNIQUEIDENTIFIER 
DECLARE @NewBuguid UNIQUEIDENTIFIER
DECLARE @NewBuname VARCHAR(20)

SELECT @NewDevelopmentCompanyGUID = DevelopmentCompanyGUID,
       @NewBuguid = buguid,
       @NewBuname = buname 
FROM companyjoin 
WHERE buname = '浙江公司'


INSERT INTO dqy_proj_20250121
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352  ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE pj.Level =3 and  bu.buname = '浙南公司'
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352 ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE  pj.Level =2 and  bu.buname = '浙南公司'

--2、齐鲁合并进山东
DECLARE @NewDevelopmentCompanyGUID UNIQUEIDENTIFIER 
DECLARE @NewBuguid UNIQUEIDENTIFIER
DECLARE @NewBuname VARCHAR(20)

SELECT @NewDevelopmentCompanyGUID = DevelopmentCompanyGUID,
       @NewBuguid = buguid,
       @NewBuname = buname 
FROM companyjoin 
WHERE buname = '山东公司'


INSERT INTO dqy_proj_20250121
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352  ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352 ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE  pj.Level =2 and  bu.buname = '齐鲁公司'

--3、大连合并进辽宁（通辽公司）
DECLARE @NewDevelopmentCompanyGUID UNIQUEIDENTIFIER 
DECLARE @NewBuguid UNIQUEIDENTIFIER
DECLARE @NewBuname VARCHAR(20)

SELECT @NewDevelopmentCompanyGUID = DevelopmentCompanyGUID,
       @NewBuguid = buguid,
       @NewBuname = buname 
FROM companyjoin 
WHERE buname = '辽宁公司'


INSERT INTO dqy_proj_20250121
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352  ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352 ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE  pj.Level =2 and  bu.buname = '大连公司'


--4、淮海合并进江苏（苏北公司改成淮海公司）
DECLARE @NewDevelopmentCompanyGUID UNIQUEIDENTIFIER 
DECLARE @NewBuguid UNIQUEIDENTIFIER
DECLARE @NewBuname VARCHAR(20)

SELECT @NewDevelopmentCompanyGUID = DevelopmentCompanyGUID,
       @NewBuguid = buguid,
       @NewBuname = buname 
FROM companyjoin 
WHERE buname = '江苏公司'

INSERT INTO dqy_proj_20250121
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352  ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE pj.Level =3 and  bu.buname = '淮海公司'
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
FROM ERP25_test.dbo.mdm_Project pj
    LEFT JOIN
    (
        SELECT DISTINCT
               ProjGUID,
               ProjCode,
               BUGUID
        FROM MyCost_Erp352_ceshi.dbo.p_Project p
    ) p352 ON pj.ProjGUID = p352.ProjGUID
    INNER JOIN ERP25_test.dbo.companyjoin bu  ON bu.DevelopmentCompanyGUID = pj.DevelopmentCompanyGUID
WHERE  pj.Level =2 and  bu.buname = '淮海公司'


-- 查询待迁移项目清单
SELECT *
FROM dqy_proj_20250121
ORDER BY newbuname, projcode352


