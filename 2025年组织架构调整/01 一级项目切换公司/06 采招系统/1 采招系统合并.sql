USE MyCost_Erp352;
GO

/*
�ɹ�ϵͳ��������֯�ܹ�Ǩ��
ע�⣺�滻dqy_proj_20240613 
*/
CREATE PROC usp_cg_Update
AS
    BEGIN

        --��ֵ��ĿCode
        SELECT  *
        INTO    #proj
        FROM(SELECT p.BUGUID ,
                    p.ProjGUID ,
                    ProjCode ,
                    p.Level ,
                    projcode352 AS oldProjCode ,
                    bu1.bucode oldbucode ,
                    bu.bucode newbucode
             FROM   dbo.p_Project p
                    INNER JOIN dqy_proj_20240613 dqy ON p.projguid = dqy.oldprojguid
                    INNER JOIN mybusinessunit bu ON bu.buguid = dqy.newbuguid
                    INNER JOIN mybusinessunit bu1 ON bu1.buguid = dqy.oldbuguid
             WHERE  ApplySys LIKE '%0201%') t;

        --��ʼˢ����Ŀ������˾GUID����Ŀ����
        IF OBJECT_ID(N'cg_DocArchive_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_DocArchive_bak_20240613
            FROM    cg_DocArchive a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode ,
            a.BUGUID = p.BUGUID
        FROM    cg_DocArchive a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '�ĵ��鵵��:cg_DocArchive' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgApply_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgApply_bak_20240613
            FROM    cg_CgApply a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode ,
            a.BUGUID = p.BUGUID
        FROM    cg_CgApply a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '�ɹ������:cg_CgApply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgPlan_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgPlan_bak_20240613
            FROM    cg_CgPlan a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjectGUIDList) <> 0;

        UPDATE  a
        SET a.ProjectCodeList = SUBSTRING(REPLACE(';' + ProjectCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjectCodeList, ';' + oldbucode, ';' + newbucode)) - 1) ,
            a.BUGUID = p.BUGUID
        FROM    cg_CgPlan a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjectGUIDList) <> 0;

        PRINT '�ɹ��ƻ���:cg_CgPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgSolution_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgSolution_bak_20240613
            FROM    cg_CgSolution a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        UPDATE  a
        SET a.ProjCodeList = SUBSTRING(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode)) - 1) ,
            a.BUGUID = p.BUGUID
        FROM    cg_CgSolution a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        PRINT '�ɹ�������:cg_CgSolution' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgSolutionLinkedPlan_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgSolutionLinkedPlan_bak_20240613
            FROM    cg_CgSolutionLinkedPlan a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode
        FROM    cg_CgSolutionLinkedPlan a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '�ɹ����������ƻ���:cg_CgSolutionLinkedPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PG2Contract_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PG2Contract_bak_20240613
            FROM    cg_PG2Contract a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        UPDATE  a
        SET a.ProjCodeList = SUBSTRING(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode)) - 1) ,
            a.BUGUID = p.buguid
        FROM    cg_PG2Contract a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        PRINT '��Լ������ͬ���ñ�:cg_PG2Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PGPlan2Contract_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PGPlan2Contract_bak_20240613
            FROM    cg_PGPlan2Contract a
                    INNER JOIN #proj p ON CHARINDEX(ProjCode, a.ProjCodeList) <> 0;

        UPDATE  a
        SET a.ProjCodeList = SUBSTRING(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode)) - 1)
        FROM    cg_PGPlan2Contract a
                INNER JOIN dbo.cb_ContractProj cp ON cp.ContractGUID = a.ContractGUID
                INNER JOIN #proj p ON CHARINDEX(ProjCode, a.ProjCodeList) <> 0;

        PRINT '��Լ�����ƻ���ͬ��:cg_PGPlan2Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PGPlan_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PGPlan_bak_20240613
            FROM    cg_PGPlan a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    cg_PGPlan a
                INNER JOIN dbo.#proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '��Լ�����ƻ���:cg_PGPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'Cg_CgPlanSp_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.Cg_CgPlanSp_bak_20240613
            FROM    Cg_CgPlanSp a
                    INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlanSp a
                INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '�ɹ��ƻ�������:Cg_CgPlanSp' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'Cg_CgPlan_OriginSp_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.Cg_CgPlan_OriginSp_bak_20240613
            FROM    Cg_CgPlan_OriginSp a
                    INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlan_OriginSp a
                INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '����ɹ��ƻ�������:Cg_CgPlan_OriginSp' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_cgplan_origin_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_cgplan_origin_bak_20240613
            FROM    Cg_CgPlan_Origin a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlan_Origin a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '����ɹ��ƻ���:cg_cgplan_origin' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PGProjReceipt_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PGProjReceipt_bak_20240613
            FROM    cg_PGProjReceipt a
                    INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode
        FROM    cg_PGProjReceipt a
                INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '��Ŀ���˳����ݱ�:cg_PGProjReceipt' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_Contract2CgProc_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_Contract2CgProc_bak_20240613
            FROM    cg_Contract2CgProc a
                    INNER JOIN cg_CgSolution b ON a.CgSolutionGUID = b.CgSolutionGUID
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), b.ProjGUIDList) <> 0
            WHERE   a.ProjectCodeList <> b.ProjCodeList;

        UPDATE  a
        SET a.ProjectCodeList = b.ProjCodeList
        FROM    cg_Contract2CgProc a
                INNER JOIN cg_CgSolution b ON a.CgSolutionGUID = b.CgSolutionGUID
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), b.ProjGUIDList) <> 0
        WHERE   a.ProjectCodeList <> b.ProjCodeList;

        PRINT 'cg_Contract2CgProc' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        /* 
	    PRINT '��ͬ��ز��й�����Ϣ��:cg_cgsolution' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'myWorkflowProcessEntity_bak_20240613', N'U') IS NULL
            SELECT  w.*
            INTO    dbo.myWorkflowProcessEntity_bak_20240613
            FROM    cg_cgsolution a
                    INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = a.CgSolutionGUID
            WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2 AND a.BUGUID IN(SELECT buguid FROM #proj)
            UNION ALL
            SELECT  w.*
            FROM    cg_cgsolution a
                    INNER JOIN cg_CgProcWinBid b ON b.CgSolutionGUID = a.CgSolutionGUID
                    INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = b.CgProcWinBidGUID
            WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2 AND a.BUGUID IN(SELECT buguid FROM #proj);

        --�ɹ�����        
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = a.CgSolutionGUID
                LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = a.BUGUID
        WHERE   a.BUGUID <> w.BUGUID AND a.buguid IN(SELECT buguid FROM #proj) AND  w.ProcessStatus = 2;

        --������
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN cg_CgProcWinBid b ON b.CgSolutionGUID = a.CgSolutionGUID
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = b.CgProcWinBidGUID
        WHERE   a.BUGUID <> w.BUGUID AND a.buguid IN(SELECT buguid FROM #proj) AND  w.ProcessStatus = 2;

        PRINT '������ʵ��Ǩ��:myWorkflowProcessEntity' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
     */
        IF OBJECT_ID(N'myWorkflowProcessEntity_bak_20240613', N'U') IS NULL
            SELECT  w.*
            INTO    dbo.myWorkflowProcessEntity_bak_20240613
            FROM    cg_cgsolution a
                    INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = a.CgSolutionGUID
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
            WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2    --AND a.BUGUID IN(SELECT buguid FROM #proj)
            UNION ALL
            SELECT  w.*
            FROM    cg_cgsolution a
                    INNER JOIN cg_CgProcWinBid b ON b.CgSolutionGUID = a.CgSolutionGUID
                    INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = b.CgProcWinBidGUID
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
            WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2;

        -- AND a.BUGUID IN(SELECT buguid FROM #proj);

        --�ɹ�����        
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = a.CgSolutionGUID
                LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = a.BUGUID
        WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2;

        -- AND a.buguid IN(SELECT buguid FROM #proj) 

        --������
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
                INNER JOIN cg_CgProcWinBid b ON b.CgSolutionGUID = a.CgSolutionGUID
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = b.CgProcWinBidGUID
        WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2;   -- AND a.buguid IN(SELECT buguid FROM #proj) 

        PRINT '������ʵ��Ǩ��:myWorkflowProcessEntity' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        -- PRINT 'cg_TacticCgPlanս�Բɹ��ƻ���';

        -- PRINT 'cg_CgPlanOrder �ɹ�������'; --û�����ݺ���

        -- PRINT 'cg_CgSolutionSection�ɹ�������α�'; --û�й�����˾GUID���������

        -- PRINT 'Cg_CgSolutionTeamMember�ɹ������б��Ŷӳ�Ա��'; --��ȷ���Ƿ���Ҫ���BUGUD

        -- PRINT 'Cg_CgSolutionTeamMemberForPlan�ɹ��ƻ�TO�б��Ŷӳ�Ա��'; --��ȷ���Ƿ���Ҫ���BUGUD
        -- PRINT 'cg_CodeFormat���б���������ñ�'; --ǰ̨ҵ����������������
        -- PRINT 'cg_p_GradePGSetting�ȼ�����������'; --��˾��ҵ��������ã����ú���Ҫ�����滻

        -- --SELECT * FROM cg_p_GradePGSetting WHERE BUGUID ='8A08A706-0273-48BA-A1D4-6AB783024D42'
        -- PRINT 'cg_PGGradePlan�����ƻ���'; --���չ�˾û������

        -- PRINT 'cg_ProcDataAuthor�ɹ�����������Ȩ�����'; --������Ȩ�ݲ�����

        -- PRINT 'cg_ProductServiceProperty����Χ���Ա�';
        -- --SELECT * FROM  cg_ProductServiceProperty

        -- PRINT 'cg_ProjCgPlanSet��Ŀ����ɹ��ƻ�������';
        -- PRINT 'cg_ProviderTypeAction��Ӧ�������Դ��Ȩ�ޱ�';
        -- PRINT 'cg_QuDefine�ʾ����'; --û�����ݲ��ô���
        -- PRINT 'cg_TacticCgAdjustBillս�Բɹ�Э��������ݱ�'; --ս��Э�鲻�ô���
        -- PRINT 'cg_TacticCgAgreementս��Э����޸ı�'; --ս��Э�鲻�ô���
        -- PRINT 'cg_TacticCgPlanս�Բɹ��ƻ���'; --ս��Э�鲻�ô���
        -- PRINT 'Cg_TacticCgPlanSPս�Բɹ��ƻ�������'; --ս��Э�鲻�ô���
        -- PRINT 'cg_web_BUAliasName��˾������'; --û�����ݣ��ݲ��ô���

        -- PRINT 'cg_YearPGFormula�����붨�����㹫ʽ����'; --ҵ��������ã��ݲ��ô���
        -- PRINT 'cg_YearPGPlan��������ƻ���'; --û������
        -- PRINT 'p_ProviderZZPG ��Ӧ�̲�Ʒ����������'; --ҵ��������ã��ݲ��ô���
        DROP TABLE #proj;
    END;
