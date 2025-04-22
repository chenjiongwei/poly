USE MyCost_Erp352
GO
BEGIN
    --赋值项目Code
    SELECT  *
    INTO    #proj
    FROM(SELECT DISTINCT p.BUGUID ,
                            -- p.ProjGUID,
                            -- ProjCode,
                            -- p.Level,
                            --projcode352 AS oldProjCode,
                         bu1.BUCode oldbucode ,
                         bu.BUCode newbucode ,
                         bu1.BUGUID AS oldbuguid
         FROM   dbo.p_Project p
                INNER JOIN dqy_proj_20250411 dqy ON p.ProjGUID = dqy.OldProjGuid
                INNER JOIN myBusinessUnit bu ON bu.BUGUID = dqy.NewBuguid
                INNER JOIN myBusinessUnit bu1 ON bu1.BUGUID = dqy.OldBuguid
         WHERE  ApplySys LIKE '%0201%') t;



    IF OBJECT_ID(N'cg_TacticCgPlan_bak_20250411', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cg_TacticCgPlan_bak_20250411
        FROM    cg_TacticCgPlan a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cg_TacticCgPlan a
            INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
    WHERE   a.BUGUID <> p.BUGUID;

    PRINT '战略采购计划表:cg_TacticCgPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


--     IF OBJECT_ID(N'cg_PGGradePlan_bak_20250411', N'U') IS NULL
--         SELECT  a.*
--         INTO    dbo.cg_PGGradePlan_bak_20250411
--         FROM    cg_PGGradePlan a
--                 INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
--         WHERE   a.BUGUID <> p.BUGUID;

--     UPDATE  a
--     SET a.BUGUID = p.BUGUID
--     FROM    cg_PGGradePlan a
--             INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
--     WHERE   a.BUGUID <> p.BUGUID;

--     PRINT '定级计划表:cg_PGGradePlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


    IF OBJECT_ID(N'cg_TacticCgAdjustBill_bak_20250411', N'U') IS NULL
        SELECT a.*
        INTO dbo.cg_TacticCgAdjustBill_bak_20250411
        FROM cg_TacticCgAgreement a
        INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.oldbuguid), a.ApplyAreaGUIDList) <> 0
        AND CHARINDEX(CONVERT(VARCHAR(50), p.BUGUID), a.ApplyAreaGUIDList) = 0
        INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid;

    UPDATE a
    SET a.BUGUID = p.BUGUID,
        ApplyAreaGUIDList = CASE 
                                WHEN CHARINDEX(CONVERT(VARCHAR(50), p.buguid), ApplyAreaGUIDList) = 0 
                                THEN ApplyAreaGUIDList + ',' + CONVERT(VARCHAR(50), p.buguid)
                                ELSE ApplyAreaGUIDList 
                            END,
        ApplyAreaList = CASE 
                            WHEN CHARINDEX(CONVERT(VARCHAR(50), p.buguid), ApplyAreaGUIDList) = 0 
                            THEN ApplyAreaList + '；' + bu.buname
                            ELSE ApplyAreaList 
                        END
    FROM cg_TacticCgAgreement a
    INNER JOIN #proj p ON CHARINDEX(CONVERT(VARCHAR(50), p.oldbuguid), ApplyAreaGUIDList) <> 0 
                        AND CHARINDEX(CONVERT(VARCHAR(50), p.BUGUID), ApplyAreaGUIDList) = 0
    INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid;

    PRINT '战略采购协议调整单据表:cg_TacticCgAdjustBill' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


    IF OBJECT_ID(N'cg_TacticCgAgreement_bak_20250411', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cg_TacticCgAgreement_bak_20250411
        FROM    cg_TacticCgAgreement a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

    UPDATE a
    SET a.BUGUID = p.BUGUID,
        ApplyAreaGUIDList = CASE 
                                WHEN CHARINDEX(CONVERT(VARCHAR(50), p.buguid), ApplyAreaGUIDList) = 0 
                                THEN ApplyAreaGUIDList + ',' + CONVERT(VARCHAR(50), p.buguid)
                                ELSE ApplyAreaGUIDList 
                            END,
        ApplyAreaList = CASE 
                            WHEN CHARINDEX(CONVERT(VARCHAR(50), p.buguid), ApplyAreaGUIDList) = 0 
                            THEN ApplyAreaList + ',' + bu.buname
                            ELSE ApplyAreaList 
                        END
    FROM cg_TacticCgAgreement a
    INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
    INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
    WHERE a.BUGUID <> p.BUGUID;

    PRINT '战略协议表（修改表）:cg_TacticCgAgreement' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


    IF OBJECT_ID(N'Cg_TacticCgPlanSP_bak_20250411', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.Cg_TacticCgPlanSP_bak_20250411
        FROM    Cg_TacticCgPlanSP a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    Cg_TacticCgPlanSP a
            INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
    WHERE   a.BUGUID <> p.BUGUID;

    PRINT '战略采购计划审批表:Cg_TacticCgPlanSP' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'Cg_CgPlan_Origin_bak_20250411_按公司', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.Cg_CgPlan_Origin_bak_20250411_按公司
        FROM    Cg_CgPlan_Origin a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlan_Origin a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

    PRINT '整体采购计划表:Cg_CgPlan_Origin' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'Cg_CgPlan_bak_20250411_按公司', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.Cg_CgPlan_bak_20250411_按公司
        FROM    Cg_CgPlan a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    Cg_CgPlan a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

    PRINT '采购计划表:Cg_CgPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'cg_CgSolution_bak_20250411_按公司', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cg_CgSolution_bak_20250411_按公司
        FROM    cg_CgSolution a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    cg_CgSolution a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

    PRINT '采购方案表:cg_CgSolution' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'cb_contract_bak_20250411_按公司', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_contract_bak_20250411_按公司
        FROM    cb_contract a
                INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
        WHERE   a.BUGUID <> p.BUGUID;

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cb_contract a
            INNER JOIN #proj p ON a.BUGUID = p.oldbuguid
    WHERE   a.BUGUID <> p.BUGUID;

    PRINT '合同表:cb_contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
END;