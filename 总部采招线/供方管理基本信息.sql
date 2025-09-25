DECLARE @buguid VARCHAR(MAX) = '528CA87C-F7AF-4FDD-BD05-79641D9F67FB';

--把拼接的BUGUIDS分成多行
SELECT a.ProviderZZPGGUID,
       b.BUGUIDs
INTO #zzpg
FROM
(
    SELECT ProviderZZPGGUID,
           BUGUIDs = CAST('<v>' + REPLACE(BUGUIDs, ',', '</v><v>') + '</v>' AS XML)
    FROM p_ProviderZZPG
) AS a
    OUTER APPLY
(
    SELECT BUGUIDs = T.C.value('.', 'varchar(50)')
    FROM a.BUGUIDs.nodes('v') AS T(C)
) AS b
WHERE b.BUGUIDs IN ( @buguid );
-- ( SELECT Value FROM dbo.fn_Split2(@buguid, ',') );


--缓存联系人、区域
SELECT b.ApplyAreaGUID,
       a.ProviderGUID,
       a.ProviderBusinessContact,
       a.Name + a.MobilePhone Name
INTO #t
FROM dbo.p_ProviderBusinessContact a
    LEFT JOIN p_ProviderBusinessContactApplyArea b
        ON a.ProviderBusinessContact = b.ProviderBusinessContact
WHERE 1 = 1
     -- AND b.ApplyAreaGUID IN ( @buguid );
--( SELECT Value FROM dbo.fn_Split2(@buguid, ',') );



SELECT DISTINCT
    -- a.ProviderTypeNameList 供方类别,
       a.ProviderGUID,
       a.ProviderName 供应商全称,
       a.Corporation 法人代表,
       f.Name 业务负责人,
       k.BUName 平台公司,
       a.CreateDate 成立日期,
       a.TaxpayerIdentificationNumber 供方单位社会信用代码,
       a.RegisterFund 注册资本,
       d.GradeName 供方等级,
       c.ProductTypeShortName 服务范围,
       dd.ProductTypeShortName 四级服务范围,
       aa.maxdate AS 入库时间,
       a.CooperationState 合作状态,
       DATEADD(yy, 2, aa.maxdate) 预计期满未合作出库时间,
       bb.maxdate AS 出库时间
INTO #g
FROM dbo.p_Provider a
    LEFT JOIN dbo.p_Provider2ServiceCompany b
        ON a.ProviderGUID = b.ProviderGUID
    LEFT JOIN
    (
        SELECT DISTINCT
               t.ApplyAreaGUID,
               t.ProviderGUID,
               Name = STUFF(
                      (
                          SELECT ';' + t1.Name
                          FROM #t t1
                          WHERE 1 = 1
                                AND t1.ApplyAreaGUID = t.ApplyAreaGUID
                                AND t1.ProviderGUID = t.ProviderGUID
                          FOR XML PATH('')
                      ),
                      1,
                      1,
                      ''
                           )
        FROM
        (SELECT DISTINCT a.ApplyAreaGUID, a.ProviderGUID FROM #t a) t
    ) f
        ON b.ProviderGUID = f.ProviderGUID
         --  AND b.BUGUID = f.ApplyAreaGUID
    INNER JOIN dbo.p_ProductType c
        ON c.ProductTypeCode = b.ProductTypeCode
           AND c.IfEnd = 1
    LEFT JOIN dbo.p_ProductType dd
        ON c.ParentCode = dd.ProductTypeCode
    LEFT JOIN dbo.p_ProviderGrade d
        ON d.ProviderGradeGUID = b.ServiceCompanyGradeGUID
    LEFT JOIN dbo.ek_Company k
        ON b.BUGUID = k.BUGUID
    LEFT JOIN
    (
        SELECT p.ProviderGUID,
               a.BUGUID,
               t.ProductTypeCode,
               a.ApprovalStatus,
               MAX(a.ApprovalDate) AS maxdate
        FROM p_ProviderZZPG a
            LEFT JOIN dbo.p_ProviderZZPG_Provider p
                ON p.ProviderZZPGGUID = a.ProviderZZPGGUID
            LEFT JOIN dbo.p_ProviderZZPG_ProductTypeCode t
                ON t.ProviderZZPGGUID = a.ProviderZZPGGUID
                   AND t.ProviderGUID = p.ProviderGUID
            INNER JOIN #zzpg b
                ON b.ProviderZZPGGUID = a.ProviderZZPGGUID
        WHERE 1 = 1
              AND a.ZZPGType = '入库审批'
        GROUP BY p.ProviderGUID,
                 a.BUGUID,
                 t.ProductTypeCode,
                 a.ApprovalStatus
    ) aa
        ON a.ProviderGUID = aa.ProviderGUID
           AND b.ProductTypeCode = aa.ProductTypeCode
    LEFT JOIN
    (
        SELECT p.ProviderGUID,
               a.BUGUID,
               t.ProductTypeCode,
               a.ApprovalStatus,
               MAX(a.ApprovalDate) AS maxdate
        FROM p_ProviderZZPG a
            LEFT JOIN dbo.p_ProviderZZPG_Provider p
                ON p.ProviderZZPGGUID = a.ProviderZZPGGUID
            LEFT JOIN dbo.p_ProviderZZPG_ProductTypeCode t
                ON t.ProviderZZPGGUID = a.ProviderZZPGGUID
                   AND t.ProviderGUID = p.ProviderGUID
            INNER JOIN #zzpg b
                ON b.ProviderZZPGGUID = a.ProviderZZPGGUID
        WHERE 1 = 1
              AND a.ZZPGType = '出库审批'
        GROUP BY p.ProviderGUID,
                 a.BUGUID,
                 t.ProductTypeCode,
                 a.ApprovalStatus
    ) bb
        ON a.ProviderGUID = bb.ProviderGUID
           AND b.ProductTypeCode = bb.ProductTypeCode
WHERE b.BUGUID IN ( @buguid );
--( SELECT Value FROM dbo.fn_Split2(@buguid, ',') );

SELECT p.ProviderTypeNameList 供方类别,
       g.*
FROM #g g
LEFT JOIN dbo.p_Provider p ON g.ProviderGUID=p.ProviderGUID


DROP TABLE #zzpg;
DROP TABLE #t;
DROP TABLE #g;