SELECT  *
FROM(SELECT [TacticCgAgreementGUID] ,
            [AgreementCode] AS ս��Э���� ,
            [AgreementName] AS ս��Э������ ,
            [YfProviderName] AS �ҷ���λ ,
            [ValidBeginDate] AS ��Ч��ʼ���� ,
            [ValidEndDate] AS ��Ч��ֹ���� ,
            [CgProjectName] AS �ɹ��� ,
            TacticCgAdjustBillGUID ,
            --JicaiLevelGuid,
            --ISNULL(CAST([Provider2ServiceGUID] AS NVARCHAR(36)), '') Provider2ServiceGUID,
            [SignDate] AS ǩԼ���� ,
            --ApplyAreaGUIDList,
            Operator AS ������ ,
            --CreateDate,
            --AuditDate,
            State AS ״̬ ,
            AuditState ,
            [CgSolutionGUID] ,
            CgPlanGUID ,
            CASE WHEN ApplyAreaGUIDList = '00000000-0000-0000-0000-000000000000' THEN 'ȫ��'
                 ELSE
            (CASE WHEN CHARINDEX('00000000-0000-0000-0000-000000000000', ApplyAreaGUIDList) <> 0 THEN 'ȫ����' ELSE '' END)
            + SUBSTRING((SELECT     '��' + BUName
                         FROM   dbo.myBusinessUnit
                         WHERE   BUGUID IN(SELECT   B.value
                                           FROM     (SELECT CONVERT(XML, '<v>' + REPLACE(CASE ApplyAreaGUIDList WHEN '' THEN NULL ELSE ApplyAreaGUIDList END, ',', '</v><v>') + '</v>') AS value) AS A
                                                    OUTER APPLY(SELECT  N.v.value('.', 'varchar(max)') AS value
                                                                FROM    A.[value].nodes('/v') N(v) ) AS B )
                         ORDER BY OrderHierarchyCode
                        FOR XML PATH('')), 2, 8000)
            END AS �������� ,
            IsHistoryData ,
            CASE WHEN IsPublish = 1 THEN '�ѹ�ʾ' ELSE 'δ��ʾ' END AS ��ʾ��� ,
            JfProviderName AS �׷���λ ,
            ProductTypeName AS ����Χ
     FROM   [dbo].[vcg_TacticCgAgreement] t
            INNER JOIN dbo.myBusinessUnit bu ON t.BUGUID = bu.BUGUID
     WHERE  bu.BUName = '�Ϻ���˾') t
WHERE(((1 = 1) AND  ((2 = 2)) AND   TacticCgAdjustBillGUID IS NULL) OR  ((1 = 1) AND ((2 = 2)) AND  TacticCgAdjustBillGUID IS NOT NULL AND  AuditState = '�����'))
ORDER BY ǩԼ���� DESC;
