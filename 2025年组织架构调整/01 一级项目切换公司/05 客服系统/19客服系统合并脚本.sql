--http://192.168.0.103/PubProject/BizParam/BizParamSetting_Option_Edit.aspx?objecttypecode=undefined&funcid=01020209&mode=1&ParamName=k_ProblemCloseResoon&ScopeGUID=248b1e17-aacb-e511-80b8-e41f13c51836&ParamCode=0

/*--ҵ���������-����ر�ԭ��
SELECT  *
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_ProblemCloseResoon' AND  ScopeGUID IN( SELECT BUGUID
                                                             FROM   dbo.myBusinessUnit
                                                             WHERE  BUName = '������˾' AND IsEndCompany = 1 );

--�����չ�˾������ر�ԭ��ҵ��������Ƶ�������˾
INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID, AreaInfo ,
                                 IsLandCbDk , ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf)
SELECT  ParamName ,
        (SELECT BUGUID
         FROM   dbo.myBusinessUnit
         WHERE  BUName = '������˾' AND IsEndCompany = 1) AS ScopeGUID ,
        ParamValue ,
        ParamCode ,
        ParentCode ,
        ParamLevel ,
        IfEnd ,
        IfSys ,
        NEWID() AS ParamGUID ,
        IsAjSk ,
        IsQykxdc ,
        TaxItemsDetailCode ,
        IsCalcTax ,
        CompanyGUID ,
        AreaInfo ,
        IsLandCbDk ,
        ReceiveTypeValue ,
        NEWID() AS myBizParamOptionGUID ,
        IsYxfjxzf
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_ProblemCloseResoon' AND  ScopeGUID IN(SELECT BUGUID
                                                             FROM   dbo.myBusinessUnit
                                                             WHERE  BUName = '���չ�˾' AND IsEndCompany = 1);

--ҵ���������-���⴦��λ
SELECT  *
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_place' AND   ScopeGUID IN(SELECT BUGUID
                                                 FROM   dbo.myBusinessUnit
                                                 WHERE  BUName = '������˾' AND IsEndCompany = 1);

--����
SELECT  * INTO  myBizParamOption_bak20240613 FROM dbo.myBizParamOption;

--ɾ��������˾���⴦��λ����
DELETE  FROM dbo.myBizParamOption
--SELECT * FROM myBizParamOption
WHERE   ParamName = 'k_place' AND   ScopeGUID IN(SELECT BUGUID
                                                 FROM   dbo.myBusinessUnit
                                                 WHERE  BUName = '������˾' AND IsEndCompany = 1);

--�������⴦�����
INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID, AreaInfo ,
                                 IsLandCbDk , ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf)
SELECT  ParamName ,
        (SELECT BUGUID
         FROM   dbo.myBusinessUnit
         WHERE  BUName = '������˾' AND IsEndCompany = 1) AS ScopeGUID ,
        ParamValue ,
        ParamCode ,
        ParentCode ,
        ParamLevel ,
        IfEnd ,
        IfSys ,
        NEWID() AS ParamGUID ,
        IsAjSk ,
        IsQykxdc ,
        TaxItemsDetailCode ,
        IsCalcTax ,
        CompanyGUID ,
        AreaInfo ,
        IsLandCbDk ,
        ReceiveTypeValue ,
        NEWID() AS myBizParamOptionGUID ,
        IsYxfjxzf
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_place' AND   ScopeGUID IN(SELECT BUGUID
                                                 FROM   dbo.myBusinessUnit
                                                 WHERE  BUName = '���չ�˾' AND IsEndCompany = 1);
*/
BEGIN
    --������ʱ��
    SELECT *
    INTO #dqy_proj
    FROM dqy_proj_20240613 t;

    -- --����λ��
    PRINT '����λ��k_AcceptBU';

    IF OBJECT_ID(N'k_AcceptBU_bak20240613', N'U') IS NULL
        SELECT a.*
        INTO k_AcceptBU_bak20240613
        FROM k_AcceptBU a
            INNER JOIN k_Receive b
                ON a.ReceiveGUID = b.ReceiveGUID
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = b.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_AcceptBU a
        INNER JOIN k_Receive b
            ON a.ReceiveGUID = b.ReceiveGUID
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = b.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '����λ��k_AcceptBU' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ----����ʵ��
    PRINT '����ʵ��k_Task';

    IF OBJECT_ID(N'k_Task_bak20240613', N'U') IS NULL
        SELECT a.*
        INTO k_Task_bak20240613
        FROM k_Task a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Task a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '����ʵ��k_Task' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ----�����
    PRINT '�����k_Receive';

    IF OBJECT_ID(N'k_Receive_bak20240613', N'U') IS NULL
        SELECT a.*
        INTO k_Receive_bak20240613
        FROM k_Receive a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Receive a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '�����k_Receive' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --Ͷ��ר���k_Complaint --û������
    IF OBJECT_ID(N'k_Complaint_bak20240613', N'U') IS NULL
        SELECT a.*
        INTO k_Complaint_bak20240613
        FROM k_Complaint a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Complaint a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT 'Ͷ��ר���k_Complaint' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --�⸶��¼ʵ��k_Pay --û������
    IF OBJECT_ID(N'k_Pay_bak20240613', N'U') IS NULL
        SELECT a.*
        INTO k_Pay_bak20240613
        FROM k_Pay a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Pay a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '�⸶��¼ʵ��k_Pay' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


----�Ӵ���¼��OK ����ϵͳǨ�ƽű����Ѿ�����
--SELECT a.BUGUID ,
--       *
--FROM   k_Receive a
--       INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
--       INNER JOIN dbo.myBusinessUnit bu ON bu.BUGUID = p.BUGUID
--WHERE  bu.BUName = '������˾'
--       AND bu.IsEndCompany = 1
--       AND a.BUGUID <> bu.BUGUID;

--k_TaskAutoUpdateSetting
--�漰�洢���̣�usp_TaskAutoUpdate
--�漰��ҵ�񳡾����ͷ������Զ������������k_TASK��BUGUID���������BUGUID�����в����������Ż��ʼ���Ϣ
--SELECT  *
--FROM    k_TaskAutoUpdateSetting
--WHERE   BUGUID IN(SELECT    BUGUID
--                  FROM  dbo.myBusinessUnit
--                  WHERE BUName = '���չ�˾' AND IsEndCompany = 1);

--INSERT INTO dbo.k_TaskAutoUpdateSetting(SettingGUID, BUGUID, TaskLevelName, TimeoutThanDay, TimeoutLessDay, ReBuildThanDay, ReBuildLessDay)
--SELECT  NEWID() AS SettingGUID ,
--        (SELECT BUGUID
--         FROM   dbo.myBusinessUnit
--         WHERE  BUName = '������˾' AND IsEndCompany = 1) AS BUGUID ,
--        TaskLevelName ,
--        TimeoutThanDay ,
--        TimeoutLessDay ,
--        ReBuildThanDay ,
--        ReBuildLessDay
--FROM    k_TaskAutoUpdateSetting
--WHERE   BUGUID IN(SELECT    BUGUID
--                  FROM  dbo.myBusinessUnit
--                  WHERE BUName = '���չ�˾' AND IsEndCompany = 1);

----�������������ñ�
--SELECT  *
--FROM    k_TaskWarnManSetting a
--        INNER JOIN dbo.mdm_Project p ON a.ProjGUID = p.ProjGUID
--WHERE   p.DevelopmentCompanyGUID IN(SELECT  DevelopmentCompanyGUID
--                                    FROM    dbo.p_DevelopmentCompany
--                                    WHERE   DevelopmentCompanyName = '������˾');

--UPDATE  a
--SET a.BUGUID = (SELECT  BUGUID
--                FROM    dbo.myBusinessUnit
--                WHERE   BUName = '������˾' AND IsEndCompany = 1)
--FROM    k_TaskWarnManSetting a
--        INNER JOIN dbo.mdm_Project p ON a.ProjGUID = p.ProjGUID
--WHERE   p.DevelopmentCompanyGUID IN(SELECT  DevelopmentCompanyGUID
--                                    FROM    dbo.p_DevelopmentCompany
--                                    WHERE   DevelopmentCompanyName = '������˾');

----�����λȨ�ޱ� --���ô���
--SELECT * FROM k_Station2Action
----�鷿/�����ܽ�� --���ô���
--SELECT * FROM k_SumUp

----�Զ�������׼���ñ� --���ô���
--SELECT * FROM  k_TaskAutoUpdateSetting
----�����������ɹ���ģ����ձ�  --���ô���
--SELECT * FROM  dbo.k_TaskType2WorkTemplet
----�������������ñ�  --���ô���
--SELECT * FROM  k_TaskWarnManSetting       
END;