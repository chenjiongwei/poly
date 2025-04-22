USE MyCost_Erp352
GO
/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏

采购系统基础表组织架构迁移
注意：替换dqy_proj_20250424 
*/
-- CREATE PROC usp_cg_Update
-- AS
    BEGIN

        --赋值项目Code
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
                    INNER JOIN dqy_proj_20250424 dqy ON p.projguid = dqy.oldprojguid
                    INNER JOIN mybusinessunit bu ON bu.buguid = dqy.newbuguid
                    INNER JOIN mybusinessunit bu1 ON bu1.buguid = dqy.oldbuguid
             WHERE  ApplySys LIKE '%0201%') t;

        --开始刷新项目所属公司GUID和项目编码
        IF OBJECT_ID(N'cg_DocArchive_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_DocArchive_bak_20250424
            FROM    cg_DocArchive a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode ,
            a.BUGUID = p.BUGUID
        FROM    cg_DocArchive a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '文档归档表:cg_DocArchive' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgApply_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgApply_bak_20250424
            FROM    cg_CgApply a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode ,
            a.BUGUID = p.BUGUID
        FROM    cg_CgApply a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '采购申请表:cg_CgApply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgPlan_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgPlan_bak_20250424
            FROM    cg_CgPlan a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjectGUIDList) <> 0;

        UPDATE  a
        SET a.ProjectCodeList = SUBSTRING(REPLACE(';' + ProjectCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjectCodeList, ';' + oldbucode, ';' + newbucode)) - 1) ,
            a.BUGUID = p.BUGUID
        FROM    cg_CgPlan a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjectGUIDList) <> 0;

        PRINT '采购计划表:cg_CgPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgSolution_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgSolution_bak_20250424
            FROM    cg_CgSolution a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        UPDATE  a
        SET a.ProjCodeList = SUBSTRING(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode)) - 1) ,
            a.BUGUID = p.BUGUID
        FROM    cg_CgSolution a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        PRINT '采购方案表:cg_CgSolution' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_CgSolutionLinkedPlan_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_CgSolutionLinkedPlan_bak_20250424
            FROM    cg_CgSolutionLinkedPlan a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode
        FROM    cg_CgSolutionLinkedPlan a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '采购方案关联计划表:cg_CgSolutionLinkedPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PG2Contract_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PG2Contract_bak_20250424
            FROM    cg_PG2Contract a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        UPDATE  a
        SET a.ProjCodeList = SUBSTRING(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode)) - 1) ,
            a.BUGUID = p.buguid
        FROM    cg_PG2Contract a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0;

        PRINT '履约评估合同设置表:cg_PG2Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PGPlan2Contract_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PGPlan2Contract_bak_20250424
            FROM    cg_PGPlan2Contract a
                    INNER JOIN #proj p ON CHARINDEX(ProjCode, a.ProjCodeList) <> 0;

        UPDATE  a
        SET a.ProjCodeList = SUBSTRING(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode), 2, LEN(REPLACE(';' + ProjCodeList, ';' + oldbucode, ';' + newbucode)) - 1)
        FROM    cg_PGPlan2Contract a
                INNER JOIN dbo.cb_ContractProj cp ON cp.ContractGUID = a.ContractGUID
                INNER JOIN #proj p ON CHARINDEX(ProjCode, a.ProjCodeList) <> 0;

        PRINT '履约评估计划合同表:cg_PGPlan2Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PGPlan_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PGPlan_bak_20250424
            FROM    cg_PGPlan a
                    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    cg_PGPlan a
                INNER JOIN dbo.#proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '履约评估计划表:cg_PGPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'Cg_CgPlanSp_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.Cg_CgPlanSp_bak_20250424
            FROM    Cg_CgPlanSp a
                    INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlanSp a
                INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '采购计划审批表:Cg_CgPlanSp' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'Cg_CgPlan_OriginSp_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.Cg_CgPlan_OriginSp_bak_20250424
            FROM    Cg_CgPlan_OriginSp a
                    INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlan_OriginSp a
                INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '整体采购计划审批表:Cg_CgPlan_OriginSp' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_cgplan_origin_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_cgplan_origin_bak_20250424
            FROM    Cg_CgPlan_Origin a
                    INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlan_Origin a
                INNER JOIN #proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '整体采购计划表:cg_cgplan_origin' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_PGProjReceipt_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_PGProjReceipt_bak_20250424
            FROM    cg_PGProjReceipt a
                    INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
            WHERE   a.ProjCode <> p.ProjCode;

        UPDATE  a
        SET a.ProjCode = p.ProjCode
        FROM    cg_PGProjReceipt a
                INNER JOIN dbo.#proj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.ProjCode <> p.ProjCode;

        PRINT '项目进退场单据表:cg_PGProjReceipt' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'cg_Contract2CgProc_bak_20250424', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cg_Contract2CgProc_bak_20250424
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
	    PRINT '合同相关采招过程信息表:cg_cgsolution' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'myWorkflowProcessEntity_bak_20250121', N'U') IS NULL
            SELECT  w.*
            INTO    dbo.myWorkflowProcessEntity_bak_20250121
            FROM    cg_cgsolution a
                    INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = a.CgSolutionGUID
            WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2 AND a.BUGUID IN(SELECT buguid FROM #proj)
            UNION ALL
            SELECT  w.*
            FROM    cg_cgsolution a
                    INNER JOIN cg_CgProcWinBid b ON b.CgSolutionGUID = a.CgSolutionGUID
                    INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = b.CgProcWinBidGUID
            WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2 AND a.BUGUID IN(SELECT buguid FROM #proj);

        --采购过程        
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = a.CgSolutionGUID
                LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = a.BUGUID
        WHERE   a.BUGUID <> w.BUGUID AND a.buguid IN(SELECT buguid FROM #proj) AND  w.ProcessStatus = 2;

        --定标结果
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN cg_CgProcWinBid b ON b.CgSolutionGUID = a.CgSolutionGUID
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = b.CgProcWinBidGUID
        WHERE   a.BUGUID <> w.BUGUID AND a.buguid IN(SELECT buguid FROM #proj) AND  w.ProcessStatus = 2;

        PRINT '工作流实例迁移:myWorkflowProcessEntity' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
     */
        IF OBJECT_ID(N'myWorkflowProcessEntity_bak_20250424', N'U') IS NULL
            SELECT  w.*
            INTO    dbo.myWorkflowProcessEntity_bak_20250424
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

        --采购过程        
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = a.CgSolutionGUID
                LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = a.BUGUID
        WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2;

        PRINT '工作流实例迁移:myWorkflowProcessEntity' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        -- AND a.buguid IN(SELECT buguid FROM #proj) 

        --定标结果
        UPDATE  w
        SET w.BUGUID = a.BUGUID
        FROM    cg_cgsolution a
                INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.ProjGUID), a.ProjGUIDList) <> 0
                INNER JOIN cg_CgProcWinBid b ON b.CgSolutionGUID = a.CgSolutionGUID
                INNER JOIN dbo.myWorkflowProcessEntity w ON w.BusinessGUID = b.CgProcWinBidGUID
        WHERE   a.BUGUID <> w.BUGUID AND w.ProcessStatus = 2;   -- AND a.buguid IN(SELECT buguid FROM #proj) 

        PRINT '工作流实例迁移:myWorkflowProcessEntity' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        -- PRINT 'cg_TacticCgPlan战略采购计划表';

        -- PRINT 'cg_CgPlanOrder 采购订单表'; --没有数据忽略

        -- PRINT 'cg_CgSolutionSection采购方案标段表'; --没有关联公司GUID，无需调整

        -- PRINT 'Cg_CgSolutionTeamMember采购方案招标团队成员表'; --不确定是否需要变更BUGUD

        -- PRINT 'Cg_CgSolutionTeamMemberForPlan采购计划TO招标团队成员表'; --不确定是否需要变更BUGUD
        -- PRINT 'cg_CodeFormat采招编码规则设置表'; --前台业务参数设置无需调整
        -- PRINT 'cg_p_GradePGSetting等级评估项设置'; --公司级业务参数设置，设置后需要批量替换

        -- --SELECT * FROM cg_p_GradePGSetting WHERE BUGUID ='8A08A706-0273-48BA-A1D4-6AB783024D42'
        -- PRINT 'cg_PGGradePlan定级计划表'; --江苏公司没有数据

        -- PRINT 'cg_ProcDataAuthor采购过程数据授权对象表'; --重新授权暂不处理

        -- PRINT 'cg_ProductServiceProperty服务范围属性表';
        -- --SELECT * FROM  cg_ProductServiceProperty

        -- PRINT 'cg_ProjCgPlanSet项目整体采购计划参数表';
        -- PRINT 'cg_ProviderTypeAction供应商类别资源化权限表';
        -- PRINT 'cg_QuDefine问卷定义表'; --没有数据不用处理
        -- PRINT 'cg_TacticCgAdjustBill战略采购协议调整单据表'; --战略协议不用处理
        -- PRINT 'cg_TacticCgAgreement战略协议表（修改表）'; --战略协议不用处理
        -- PRINT 'cg_TacticCgPlan战略采购计划表'; --战略协议不用处理
        -- PRINT 'Cg_TacticCgPlanSP战略采购计划审批表'; --战略协议不用处理
        -- PRINT 'cg_web_BUAliasName公司别名表'; --没有数据，暂不用处理

        -- PRINT 'cg_YearPGFormula总评与定级计算公式设置'; --业务参数设置，暂不用处理
        -- PRINT 'cg_YearPGPlan年度评估计划表'; --没有数据
        -- PRINT 'p_ProviderZZPG 供应商产品资质评估表'; --业务参数设置，暂不用处理
        DROP TABLE #proj;
    END;
