SELECT  *
FROM(SELECT [TacticCgAgreementGUID] ,
            [AgreementCode] AS 战略协议编号 ,
            [AgreementName] AS 战略协议名称 ,
            [YfProviderName] AS 乙方单位 ,
            [ValidBeginDate] AS 有效开始日期 ,
            [ValidEndDate] AS 有效截止日期 ,
            [CgProjectName] AS 采购项 ,
            TacticCgAdjustBillGUID ,
            --JicaiLevelGuid,
            --ISNULL(CAST([Provider2ServiceGUID] AS NVARCHAR(36)), '') Provider2ServiceGUID,
            [SignDate] AS 签约日期 ,
            --ApplyAreaGUIDList,
            Operator AS 经办人 ,
            --CreateDate,
            --AuditDate,
            State AS 状态 ,
            AuditState ,
            [CgSolutionGUID] ,
            CgPlanGUID ,
            CASE WHEN ApplyAreaGUIDList = '00000000-0000-0000-0000-000000000000' THEN '全国'
                 ELSE
            (CASE WHEN CHARINDEX('00000000-0000-0000-0000-000000000000', ApplyAreaGUIDList) <> 0 THEN '全国；' ELSE '' END)
            + SUBSTRING((SELECT     '；' + BUName
                         FROM   dbo.myBusinessUnit
                         WHERE   BUGUID IN(SELECT   B.value
                                           FROM     (SELECT CONVERT(XML, '<v>' + REPLACE(CASE ApplyAreaGUIDList WHEN '' THEN NULL ELSE ApplyAreaGUIDList END, ',', '</v><v>') + '</v>') AS value) AS A
                                                    OUTER APPLY(SELECT  N.v.value('.', 'varchar(max)') AS value
                                                                FROM    A.[value].nodes('/v') N(v) ) AS B )
                         ORDER BY OrderHierarchyCode
                        FOR XML PATH('')), 2, 8000)
            END AS 适用区域 ,
            IsHistoryData ,
            CASE WHEN IsPublish = 1 THEN '已公示' ELSE '未公示' END AS 公示结果 ,
            JfProviderName AS 甲方单位 ,
            ProductTypeName AS 服务范围
     FROM   [dbo].[vcg_TacticCgAgreement] t
            INNER JOIN dbo.myBusinessUnit bu ON t.BUGUID = bu.BUGUID
     WHERE  bu.BUName = '上海公司') t
WHERE(((1 = 1) AND  ((2 = 2)) AND   TacticCgAdjustBillGUID IS NULL) OR  ((1 = 1) AND ((2 = 2)) AND  TacticCgAdjustBillGUID IS NOT NULL AND  AuditState = '已审核'))
ORDER BY 签约日期 DESC;
