USE MyCost_Erp352
GO

/****** Object:  StoredProcedure [dbo].[usp_cb_ChgProjBuguid]    Script Date: 01/09/2020 17:31:11 ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏
 cb_ContractCzcfControl 合同产值表
 cb_ContractNodeRateSetting 合同产值节点设置 不处理
 cb_ControlRedLineProjects  管控红线项目设置表
 cb_JgbaProjectsSet 竣工备案项目设置表
 cb_ProjectBldDelControl  已完工工程楼栋删除设置表
 cb_YLAmountUpperLimit  预留金上限设置表  不处理

2025-04-02 新增调整表
1、cb_ControlHTFKApplyProj 项目付款申请端口开放设置表
2、cb_DesignAlterToTZXT  设计变更信息传图纸系统监听表

*/



BEGIN
    /* 
	   执行前注意检查dqy_proj_20250121 表的projcode352是否正常！！！！
        迁移类型 qytype：确认合约包模板是否需要迁移，如果合约包名称不一致的，可通过直接复制一份原有公司的模板到新公司，如果模板名称是一致的话，那么就判断新公司合约包是否涵盖了原有公司的合约包，如果是的话，那就不需要迁移模板
		需要迁移模板：qytype = 0
		不需要迁移模板：qytype = 1
*/

    --获取迁移的项目清单
    SELECT  a.* ,
            bu.BUCode AS bucodeold ,
            bu1.BUCode AS BUCodeNew
    INTO    #dqy_proj
    FROM    dqy_proj_20250121 a
            INNER JOIN myBusinessUnit bu ON a.OldBuguid = bu.BUGUID
            INNER JOIN myBusinessUnit bu1 ON bu1.BUGUID = a.NewBuguid;

    --1.1 更新项目（执行表）
    IF OBJECT_ID(N'p_Project_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.p_Project_bak_20250121
        FROM    dbo.p_Project A
                INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    UPDATE  A
    SET A.BUGUID = B.NewBuguid ,
        A.ParentCode = B.BUCodeNew + CASE WHEN CHARINDEX('.', A.ParentCode) = 0 THEN '' ELSE '.' + SUBSTRING(A.ParentCode, CHARINDEX('.', A.ParentCode) + 1, 100)END ,
        A.ProjCode = B.BUCodeNew + '.' + SUBSTRING(A.ProjCode, CHARINDEX('.', A.ProjCode) + 1, 100)
    FROM    dbo.p_Project A
            INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    PRINT '项目（执行表）:p_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --1.2 更新项目（编制表）
    IF OBJECT_ID(N'p_HkbProjectWork_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.p_HkbProjectWork_bak_20250121
        FROM    dbo.p_HkbProjectWork A
                INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    UPDATE  A
    SET BUGUID = B.NewBuguid ,
        ParentCode = B.BUCodeNew + CASE WHEN CHARINDEX('.', A.ParentCode) = 0 THEN '' ELSE '.' + SUBSTRING(A.ParentCode, CHARINDEX('.', A.ParentCode) + 1, 100)END ,
        ProjCode = B.BUCodeNew + '.' + SUBSTRING(A.ProjCode, CHARINDEX('.', A.ProjCode) + 1, 100)
    FROM    dbo.p_HkbProjectWork A
            INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    PRINT '项目（编制表）:p_HkbProjectWork' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --1.3 更新项目（审批表）  
    IF OBJECT_ID(N'p_HkbApprove_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.p_HkbApprove_bak_20250121
        FROM    dbo.p_HkbApprove A
                INNER JOIN p_HkbProjectCompare B ON A.HkbApproveGUID = B.HkbApproveGUID
                INNER JOIN #dqy_proj C ON B.ProjGUID = C.OldProjGuid;

    UPDATE  A
    SET A.BUGUID = C.NewBuguid ,
        A.ProjInfo = REPLACE(A.ProjInfo, SUBSTRING(A.ProjInfo, 14, 36), C.NewBuguid)
    FROM    dbo.p_HkbApprove A
            INNER JOIN p_HkbProjectCompare B ON A.HkbApproveGUID = B.HkbApproveGUID
            INNER JOIN #dqy_proj C ON B.ProjGUID = C.OldProjGuid;

    PRINT '项目（审批表）:p_HkbApprove' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --1.4 更新项目（对比表）
    IF OBJECT_ID(N'p_HkbProjectCompare_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.p_HkbProjectCompare_bak_20250121
        FROM    dbo.p_HkbProjectCompare A
                INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    UPDATE  dbo.p_HkbProjectCompare
    SET BUGUID = B.NewBuguid ,
        ParentCode = B.BUCodeNew + CASE WHEN CHARINDEX('.', A.ParentCode) = 0 THEN '' ELSE '.' + SUBSTRING(A.ParentCode, CHARINDEX('.', A.ParentCode) + 1, 100)END ,
        ProjCode = B.BUCodeNew + '.' + SUBSTRING(A.ProjCode, CHARINDEX('.', A.ProjCode) + 1, 100)
    FROM    dbo.p_HkbProjectCompare A
            INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    PRINT '项目（对比表）:p_HkbProjectCompare' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --1.5 更新项目（历史表）
    IF OBJECT_ID(N'p_HkbProjectHistory_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.p_HkbProjectHistory_bak_20250121
        FROM    dbo.p_HkbProjectHistory A
                INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    UPDATE  A
    SET BUGUID = B.NewBuguid ,
        ParentCode = B.BUCodeNew + CASE WHEN CHARINDEX('.', A.ParentCode) = 0 THEN '' ELSE '.' + SUBSTRING(A.ParentCode, CHARINDEX('.', A.ParentCode) + 1, 100)END ,
        ProjCode = B.BUCodeNew + '.' + SUBSTRING(A.ProjCode, CHARINDEX('.', A.ProjCode) + 1, 100)
    FROM    dbo.p_HkbProjectHistory A
            INNER JOIN #dqy_proj B ON A.ProjCode = B.projcode352;

    PRINT '项目（历史表）:p_HkbProjectHistory' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


    --- ////////////////////////// 更新业务表 //////////////////////////
    ---- cb_Bid  招投标管理表
    ALTER TABLE cb_Bid DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Bid_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Bid_bak_20250121
        FROM    dbo.cb_Bid A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_Bid A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '招投标管理表:cb_Bid' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Bid ENABLE TRIGGER ALL;

    ---- cb_Budget 合约规划表
    ALTER TABLE cb_Budget DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Budget_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Budget_bak_20250121
        FROM    dbo.cb_Budget A
                INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_Budget A
            INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    PRINT '合约规划表:cb_Budget' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Budget ENABLE TRIGGER ALL;

    ----- cb_Budget_Executing  新合约规划执行表
    ALTER TABLE cb_Budget_Executing DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Budget_Executing_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Budget_Executing_bak_20250121
        FROM    dbo.cb_Budget_Executing A
                INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_Budget_Executing A
            INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    PRINT '新合约规划执行表:cb_Budget_Executing' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Budget ENABLE TRIGGER ALL;

    ---- cb_Budget_Working   新合约规划编制表
    ALTER TABLE cb_Budget_Working DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Budget_Working_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Budget_Working_bak_20250121
        FROM    dbo.cb_Budget_Working A
                INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_Budget_Working A
            INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    PRINT '新合约规划编制表:cb_Budget_Working' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Budget_Working ENABLE TRIGGER ALL;

    ----- cb_BudgetUse  合约规划使用表
    ALTER TABLE cb_BudgetUse DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_BudgetUse_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_BudgetUse_bak_20250121
        FROM    dbo.cb_BudgetUse A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_BudgetUse A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '合约规划使用表:cb_BudgetUse' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_BudgetUse ENABLE TRIGGER ALL;

    ---- cb_Contract  合同管理表
    ALTER TABLE cb_Contract DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_contract_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_contract_bak_20250121
        FROM    dbo.cb_Contract A
                INNER JOIN cb_ContractProj B ON A.ContractGUID = B.ContractGUID
                INNER JOIN #dqy_proj C ON C.OldProjGuid = B.ProjGUID
                INNER JOIN p_Project p ON p.ProjGUID = B.ProjGUID;

    UPDATE  A
    SET A.ProjectCodeList = SUBSTRING(REPLACE(';' + ProjectCodeList, ';' + C.bucodeold, ';' + C.bucodenew), 2, LEN(REPLACE(';' + ProjectCodeList, ';' + C.bucodeold, ';' + C.bucodenew)) - 1) ,
        BUGUID = C.NewBuguid
    FROM    dbo.cb_Contract A
            INNER JOIN cb_ContractProj B ON A.ContractGUID = B.ContractGUID
            INNER JOIN #dqy_proj C ON C.OldProjGuid = B.ProjGUID
            INNER JOIN p_Project p ON p.ProjGUID = B.ProjGUID;

    PRINT '合同管理表:cb_Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Contract ENABLE TRIGGER ALL;

    ---- cb_Contract_Pre  合同预呈批（修改）
    ALTER TABLE cb_Contract_Pre DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Contract_Pre_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Contract_Pre_bak_20250121
        FROM    dbo.cb_Contract_Pre A
                INNER JOIN #dqy_proj C ON A.ProjectCodeList LIKE '%' + C.projcode352 + '%'
                INNER JOIN p_Project p ON p.ProjGUID = C.OldProjGuid;

    UPDATE  A
    SET A.ProjectCodeList = SUBSTRING(REPLACE(';' + A.ProjectCodeList, ';' + C.bucodeold, ';' + C.bucodenew), 2, LEN(REPLACE(';' + A.ProjectCodeList, ';' + C.bucodeold, ';' + C.bucodenew)) - 1) ,
        BUGUID = C.NewBuguid
    FROM    dbo.cb_Contract_Pre A
            INNER JOIN #dqy_proj C ON A.ProjectCodeList LIKE '%' + C.projcode352 + '%'
            INNER JOIN p_Project p ON p.ProjGUID = C.OldProjGuid;

    PRINT '合同预呈批（修改）:cb_Contract_Pre' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Contract_Pre ENABLE TRIGGER ALL;

    ---- cb_DesignAlter  设计变更
    ALTER TABLE cb_DesignAlter DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_DesignAlter_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_DesignAlter_bak_20250121
        FROM    cb_DesignAlter A
                INNER JOIN #dqy_proj C ON A.ProjCodeList LIKE '%' + C.projcode352 + '%'
                INNER JOIN p_Project p ON p.ProjGUID = C.OldProjGuid;

    UPDATE  A
    SET A.ProjCodeList = SUBSTRING(REPLACE(';' + A.ProjCodeList, ';' + C.bucodeold, ';' + C.bucodenew), 2, LEN(REPLACE(';' + A.ProjCodeList, ';' + C.bucodeold, ';' + C.bucodenew)) - 1) ,
        A.BUGUID = C.NewBuguid
    FROM    cb_DesignAlter A
            INNER JOIN #dqy_proj C ON A.ProjCodeList LIKE '%' + C.projcode352 + '%'
            INNER JOIN p_Project p ON p.ProjGUID = C.OldProjGuid;

    --更新设计变更部门信息    
    IF OBJECT_ID(N'cb_DesignAlter_dept_bak_20250121', N'U') IS NULL
        SELECT  cb.*
        INTO    cb_DesignAlter_dept_bak_20250121
        FROM    cb_DesignAlter cb
                INNER JOIN mybusinessunit bu ON bu.buguid = cb.JbDeptGuid
                INNER JOIN mybusinessunit com ON com.buguid = cb.buguid
        WHERE   cb.buguid <> bu.companyguid AND cb.buguid IN(SELECT DISTINCT newbuguid FROM #dqy_proj);

    UPDATE  cb
    SET cb.JbDept = com.BUName ,
        cb.JbDeptGuid = com.BUGUID
    FROM    cb_DesignAlter cb
            INNER JOIN mybusinessunit bu ON bu.buguid = cb.JbDeptGuid
            INNER JOIN mybusinessunit com ON com.buguid = cb.buguid
    WHERE   cb.buguid <> bu.companyguid AND cb.buguid IN(SELECT DISTINCT newbuguid FROM #dqy_proj);

    PRINT '设计变更:cb_DesignAlter' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_DesignAlter ENABLE TRIGGER ALL;

    ---- cb_MonthPlanDtl  月度资金计划明细表
    ALTER TABLE cb_MonthPlanDtl DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_MonthPlanDtl_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_MonthPlanDtl_bak_20250121
        FROM    cb_MonthPlanDtl A
                INNER JOIN cb_Contract B ON A.ContractGUID = B.ContractGUID
                INNER JOIN cb_ContractProj C ON B.ContractGUID = C.ContractGUID
                INNER JOIN #dqy_proj D ON C.ProjGUID = D.OldProjGuid;

    UPDATE  A
    SET A.ProjectCodeList = B.ProjectCodeList
    FROM    cb_MonthPlanDtl A
            INNER JOIN cb_Contract B ON A.ContractGUID = B.ContractGUID
            INNER JOIN cb_ContractProj C ON B.ContractGUID = C.ContractGUID
            INNER JOIN #dqy_proj D ON C.ProjGUID = D.OldProjGuid;

    PRINT '月度资金计划明细表:cb_MonthPlanDtl' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_MonthPlanDtl ENABLE TRIGGER ALL;

    --刷新科目分摊规则表
    IF OBJECT_ID(N'cb_CostSharingSet_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_CostSharingSet_bak_20250121
        FROM    cb_CostSharingSet A
                INNER JOIN cb_Cost b ON A.CostGUID = b.CostGUID
                INNER JOIN #dqy_proj C ON C.projcode352 = b.ProjectCode
                INNER JOIN p_Project p ON p.ProjGUID = C.OldProjGuid;

    UPDATE  a
    SET a.ProjectCode = p.ProjCode
    FROM    cb_CostSharingSet a
            INNER JOIN cb_Cost b ON a.CostGUID = b.CostGUID
            INNER JOIN #dqy_proj C ON C.projcode352 = b.ProjectCode
            INNER JOIN p_Project p ON p.ProjGUID = C.OldProjGuid;

    PRINT '科目分摊规则表:cb_CostSharingSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ---- cb_Cost 成本科目表
    ALTER TABLE cb_Cost DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Cost_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Cost_bak_20250121
        FROM    cb_Cost A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_Cost A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            INNER JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '成本科目设置表:cb_Cost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Cost ENABLE TRIGGER ALL;

    ----  cb_CostControlSet  成本控制指标设置表
    ALTER TABLE cb_CostControlSet DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_CostControlSet_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_CostControlSet_bak_20250121
        FROM    dbo.cb_CostControlSet A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET Buguid = B.NewBuguid
    FROM    dbo.cb_CostControlSet A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '成本控制指标设置表:cb_CostControlSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_CostControlSet ENABLE TRIGGER ALL;

    ---- cb_CostPlan 成本保存方案表
    ALTER TABLE cb_CostPlan DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_CostPlan_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_CostPlan_bak_20250121
        FROM    dbo.cb_CostPlan A
                INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = A.ProjectGUID;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_CostPlan A
            INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = A.ProjectGUID;

    PRINT '成本保存方案表:cb_CostPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_CostPlan ENABLE TRIGGER ALL;

    ---- cb_CostStationRights  科目岗位权限表
    ALTER TABLE cb_CostStationRights DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_CostStationRights_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_CostStationRights_bak_20250121
        FROM    dbo.cb_CostStationRights A
                INNER JOIN #dqy_proj B ON A.ProjGuid = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_CostStationRights A
            INNER JOIN #dqy_proj B ON A.ProjGuid = B.OldProjGuid;

    PRINT '科目岗位权限表:cb_CostStationRights' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_CostStationRights ENABLE TRIGGER ALL;

    ---- cb_costVersion   历史科目版表
    ALTER TABLE cb_costVersion DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_costVersion_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_costVersion_bak_20250121
        FROM    dbo.cb_costVersion A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    dbo.cb_costVersion A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '历史科目版表:cb_costVersion' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_costVersion ENABLE TRIGGER ALL;

    ---- cb_DTCostRecollect  动态成本月度回顾报告主表
    ALTER TABLE cb_DTCostRecollect DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_DTCostRecollect_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_DTCostRecollect_bak_20250121
        FROM    dbo.cb_DTCostRecollect A
                INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        A.ProjectName = C.ProjName ,
        BUGUID = B.NewBuguid
    FROM    dbo.cb_DTCostRecollect A
            INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '动态成本月度回顾报告主表:cb_DTCostRecollect' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_DTCostRecollect ENABLE TRIGGER ALL;

    ---- cb_DtCostRecollectCost  动态成本回顾科目信息
    ALTER TABLE cb_DtCostRecollectCost DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_DtCostRecollectCost_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_DtCostRecollectCost_bak_20250121
        FROM    dbo.cb_DtCostRecollectCost A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_DtCostRecollectCost A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '动态成本回顾科目信息:cb_DtCostRecollectCost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_DtCostRecollectCost ENABLE TRIGGER ALL;

    ---- cb_DtInvestPlan  动态投资计划表
    ALTER TABLE cb_DtInvestPlan DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_DtInvestPlan_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_DtInvestPlan_bak_20250121
        FROM    dbo.cb_DtInvestPlan A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_DtInvestPlan A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '动态投资计划表:cb_DtInvestPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_DtInvestPlan ENABLE TRIGGER ALL;

    ---- cb_Expense   日常报销表
    ALTER TABLE cb_Expense DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Expense_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Expense_bak_20250121
        FROM    dbo.cb_Expense A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_Expense A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '日常报销表:cb_Expense' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Expense ENABLE TRIGGER ALL;

    ---- cb_HsCost  核算科目表
    ALTER TABLE cb_HsCost DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HsCost_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_HsCost_bak_20250121
        FROM    dbo.cb_HsCost A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_HsCost A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '核算科目表:cb_HsCost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HsCost ENABLE TRIGGER ALL;

    ---- cb_HsCost_CsVersion  测算科目产品版本表
    ALTER TABLE cb_HsCost_CsVersion DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HsCost_CsVersion_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_HsCost_CsVersion_bak_20250121
        FROM    dbo.cb_HsCost_CsVersion A
                INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    UPDATE  A
    SET BuGUID = B.NewBuguid
    FROM    dbo.cb_HsCost_CsVersion A
            INNER JOIN #dqy_proj B ON A.ProjectGUID = B.OldProjGuid;

    PRINT '测算科目产品版本表:cb_HsCost_CsVersion' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HsCost_CsVersion ENABLE TRIGGER ALL;

    ---- cb_HsCost_HtcfProduct  合同拆分产品核算成本
    ALTER TABLE cb_HsCost_HtcfProduct DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HsCost_HtcfProduct_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_HsCost_HtcfProduct_bak_20250121
        FROM    dbo.cb_HsCost_HtcfProduct A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_HsCost_HtcfProduct A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '合同拆分产品核算成本:cb_HsCost_HtcfProduct' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HsCost_HtcfProduct ENABLE TRIGGER ALL;

    ---- cb_Loan   领借款表
    ALTER TABLE cb_Loan DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Loan_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Loan_bak_20250121
        FROM    dbo.cb_Loan A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_Loan A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '领借款表:cb_Loan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Loan ENABLE TRIGGER ALL;

    ---- cb_PlanAnalyseProj   资金计划项目图形分析拍照表
    ALTER TABLE cb_PlanAnalyseProj DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_PlanAnalyseProj_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_PlanAnalyseProj_bak_20250121
        FROM    dbo.cb_PlanAnalyseProj A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_PlanAnalyseProj A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '资金计划项目图形分析拍照表:cb_PlanAnalyseProj' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_PlanAnalyseProj ENABLE TRIGGER ALL;

    ---- cb_ProjHyb  项目合约包
    ALTER TABLE cb_ProjHyb DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_ProjHyb_bak_20250121', N'U') IS NULL
        SELECT  *
        INTO    dbo.cb_ProjHyb_bak_20250121
        FROM    dbo.cb_ProjHyb A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid ,
        A.HtTypeGUID = newh.HtTypeGUID
    FROM    dbo.cb_ProjHyb A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
            INNER JOIN dbo.cb_HtType ht ON ht.HtTypeGUID = A.HtTypeGUID
            INNER JOIN dbo.cb_HtType newh ON newh.HtTypeCode = ht.HtTypeCode AND   B.newbuguid = newh.BUGUID;

    PRINT '项目合约包:cb_ProjHyb' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --更新合约包信息
    IF OBJECT_ID(N'cb_ProjHyb_Con_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_ProjHyb_con_bak_20250121
        FROM    cb_ProjHyb a
                INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) t ON a.BUGUID = t.newbuguid
                LEFT JOIN cb_BudgetLibrary b ON a.ContractBaseGUID = b.BudgetLibraryGUID
                LEFT JOIN cb_BudgetLibrary c ON c.BUGUID = t.NewBuguid AND b.BudgetName = c.BudgetName
        WHERE   a.BUGUID IN(SELECT  NewBuguid FROM  #dqy_proj) AND  a.ContractBaseGUID = b.BudgetLibraryGUID;

    UPDATE  cb_ProjHyb
    SET ContractBaseGUID = c.BudgetLibraryGUID ,
        YgbgRate = c.YgbgRate ,
        IsNeedDataValidSp = CASE WHEN c.IsZlSh = '否' THEN 0 ELSE 1 END
    FROM    cb_ProjHyb a
            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) t ON a.BUGUID = t.newbuguid
            INNER JOIN cb_BudgetLibrary b ON a.ContractBaseGUID = b.BudgetLibraryGUID
            LEFT JOIN cb_BudgetLibrary c ON c.BUGUID = t.NewBuguid AND b.BudgetName = c.BudgetName
    WHERE   a.BUGUID IN(SELECT  NewBuguid FROM  #dqy_proj) AND  a.ContractBaseGUID = b.BudgetLibraryGUID;

    PRINT '合约包的ContractBaseGUID:cb_ProjHyb' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_ProjHyb ENABLE TRIGGER ALL;

    ---- cb_ProjHyb_Version  项目合约包-历史
    ALTER TABLE cb_ProjHyb_Version DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_ProjHyb_Version_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_ProjHyb_Version_bak_20250121
        FROM    dbo.cb_ProjHyb_Version A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid ,
        A.HtTypeGUID = newh.HtTypeGUID
    FROM    dbo.cb_ProjHyb_Version A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
            INNER JOIN dbo.cb_HtType ht ON ht.HtTypeGUID = A.HtTypeGUID
            INNER JOIN dbo.cb_HtType newh ON newh.HtTypeCode = ht.HtTypeCode AND   B.newbuguid = newh.BUGUID;

    PRINT '项目合约包-历史:cb_ProjHyb_Version' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_ProjHyb_Version ENABLE TRIGGER ALL;

    ---- cb_ProjHyb_Working  项目合约包-编制
    ALTER TABLE cb_ProjHyb_Working DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_ProjHyb_Working_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_ProjHyb_Working_bak_20250121
        FROM    dbo.cb_ProjHyb_Working A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid ,
        A.ContractBaseGUID = c.BudgetLibraryGUID ,
        A.YgbgRate = c.YgbgRate ,
        A.IsNeedDataValidSp = CASE WHEN c.IsZlSh = '否' THEN 0 ELSE 1 END
    FROM    dbo.cb_ProjHyb_Working A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
            INNER JOIN cb_BudgetLibrary d ON A.ContractBaseGUID = d.BudgetLibraryGUID
            LEFT JOIN cb_BudgetLibrary c ON c.BUGUID = B.NewBuguid AND d.BudgetName = c.BudgetName;

    UPDATE  A
    SET BUGUID = B.NewBuguid ,
        A.HtTypeGUID = newh.HtTypeGUID
    FROM    dbo.cb_ProjHyb_Working A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
            INNER JOIN dbo.cb_HtType ht ON ht.HtTypeGUID = A.HtTypeGUID
            INNER JOIN dbo.cb_HtType newh ON newh.HtTypeCode = ht.HtTypeCode AND   B.newbuguid = newh.BUGUID;

    PRINT '项目合约包-编制:cb_ProjHyb_Working' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_ProjHyb_Working ENABLE TRIGGER ALL;

    ---- cb_sjkCsfa  测算方案表
    ALTER TABLE cb_sjkCsfa DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_sjkCsfa_Working_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_sjkCsfa_Working_bak_20250121
        FROM    dbo.cb_sjkCsfa A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjName = C.ProjName ,
        BUGUID = B.NewBuguid
    FROM    dbo.cb_sjkCsfa A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '测算方案表:cb_sjkCsfa' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_sjkCsfa ENABLE TRIGGER ALL;

    ---- cb_sjkDataCd  成本数据沉淀表
    ALTER TABLE cb_sjkDataCd DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_sjkDataCd_Working_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_sjkDataCd_Working_bak_20250121
        FROM    dbo.cb_sjkDataCd A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjName = C.ProjName ,
        BUGUID = B.NewBuguid
    FROM    cb_sjkDataCd A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '成本数据沉淀表:cb_sjkDataCd' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_sjkDataCd ENABLE TRIGGER ALL;

    ---- cb_StockCost 公司库存科目表
    ALTER TABLE cb_StockCost DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_StockCost_Working_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_StockCost_Working_bak_20250121
        FROM    dbo.cb_StockCost A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_StockCost A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '公司库存科目表:cb_StockCost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_StockCost ENABLE TRIGGER ALL;

    ---- cb_StockCost_History
    ALTER TABLE cb_StockCost_History DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_StockCost_History_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_StockCost_History_bak_20250121
        FROM    dbo.cb_StockCost_History A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_StockCost_History A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '公司库存科目历史表:cb_StockCost_History' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_StockCost_History ENABLE TRIGGER ALL;


    --- ////////////////////////// 2025年新增成本表更新 开始 //////////////////////////
    ALTER TABLE cb_ContractCzcfControl DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_ContractCzcfControl_bak_20250121', N'U') IS NULL
        SELECT 
            a.BuGUID,
            a.BuName,
            a.ContractCzcfControlGUID,
            a.ProjGUIDs,
            a.ProjNames
        INTO 
            cb_ContractCzcfControl_bak_20250121
        FROM 
            (
                SELECT 
                    a.BuName,
                    a.BuGUID,
                    a.ContractCzcfControlGUID,
                    a.ProjGUIDs,
                    a.ProjNames,
                    Value AS Projguid   
                FROM 
                    cb_ContractCzcfControl a
                CROSS APPLY 
                    dbo.fn_Split1(a.ProjGUIDs, ',') 
                WHERE 
                    ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
            ) a 
        INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;

    -- 调整buguid和buname信息
        UPDATE a
        SET a.BuGUID = b.NewBuguid,
            a.BuName = b.NewBUName
        FROM 
            (
                SELECT 
                    a.BuName,
                    a.BuGUID,
                    a.ContractCzcfControlGUID,
                    a.ProjGUIDs,
                    a.ProjNames,
                    Value AS Projguid   
                FROM 
                    cb_ContractCzcfControl a
                CROSS APPLY 
                    dbo.fn_Split1(a.ProjGUIDs, ',') 
                WHERE 
                    ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
            ) a 
        INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
        WHERE a.buguid <> b.NewBuguid;

        PRINT '合同产值表:cb_ContractCzcfControl' + CONVERT(NVARCHAR(20), @@ROWCOUNT);        
    ALTER TABLE cb_ContractCzcfControl ENABLE TRIGGER ALL;

    -- 管控红线项目设置表 
    ALTER TABLE cb_ControlRedLineProjects DISABLE TRIGGER ALL;
    IF OBJECT_ID(N'cb_ControlRedLineProjects_bak_20250121', N'U') IS NULL
        SELECT 
            a.BuGUID,
            a.BuName,
            a.ControlRedLineProjectsGUID,
            a.ProjGUIDs,
            a.ProjNames
        INTO  cb_ControlRedLineProjects_bak_20250121
        FROM 
            (
                SELECT 
                    a.BuName,
                    a.BuGUID,
                    a.ControlRedLineProjectsGUID,
                    a.ProjGUIDs,
                    a.ProjNames,
                    Value AS Projguid   
                FROM 
                    cb_ControlRedLineProjects a
                CROSS APPLY 
                    dbo.fn_Split1(a.ProjGUIDs, ',') 
                WHERE 
                    ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
            ) a 
        INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;

    -- 调整buguid和buname信息
    UPDATE A
    SET a.BuGUID = b.NewBuguid,
        a.BuName = b.NewBUName        
    FROM 
        (
            SELECT 
                a.BuName,
                a.BuGUID,
                a.ControlRedLineProjectsGUID,
                a.ProjGUIDs,
                a.ProjNames,
                Value AS Projguid   
            FROM 
                cb_ControlRedLineProjects a
            CROSS APPLY 
                dbo.fn_Split1(a.ProjGUIDs, ',') 
            WHERE 
                ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        ) a 
    INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
    WHERE a.buguid <> b.NewBuguid;
      
    PRINT '管控红线项目设置表:cb_ControlRedLineProjects' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 
        
    ALTER TABLE cb_ControlRedLineProjects ENABLE TRIGGER ALL;

    --  cb_JgbaProjectsSet 竣工备案项目设置表
    ALTER TABLE cb_JgbaProjectsSet DISABLE TRIGGER ALL;
    IF OBJECT_ID(N'cb_JgbaProjectsSet_bak_20250121', N'U') IS NULL
        SELECT 
            a.BuGUID,
            a.BuName,
            a.JgbaProjectsSetGUID,
            a.ProjGUIDs,
            a.ProjNames
        INTO  cb_JgbaProjectsSet_bak_20250121
        FROM 
            (
                SELECT 
                    a.BuName,
                    a.BuGUID,
                    a.JgbaProjectsSetGUID,
                    a.ProjGUIDs,
                    a.ProjNames,
                    Value AS Projguid   
                FROM   cb_JgbaProjectsSet a
                CROSS APPLY 
                    dbo.fn_Split1(a.ProjGUIDs, ',') 
                WHERE  ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
            ) a 
        INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;

    -- 调整buguid和buname信息
    UPDATE A
    SET a.BuGUID = b.NewBuguid,
        a.BuName = b.NewBUName        
    FROM 
        (
            SELECT 
                a.BuName,
                a.BuGUID,
                a.JgbaProjectsSetGUID,
                a.ProjGUIDs,
                a.ProjNames,
                Value AS Projguid   
            FROM 
                cb_JgbaProjectsSet a
            CROSS APPLY 
                dbo.fn_Split1(a.ProjGUIDs, ',') 
            WHERE 
                ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        ) a 
    INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
    WHERE a.buguid <> b.NewBuguid;
      
    PRINT '竣工备案项目设置表:cb_JgbaProjectsSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 
        
    ALTER TABLE cb_JgbaProjectsSet ENABLE TRIGGER ALL;

    -- cb_ProjectBldDelControl  已完工工程楼栋删除设置表
    ALTER TABLE cb_ProjectBldDelControl DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_ProjectBldDelControl_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_ProjectBldDelControl_bak_20250121
        FROM    dbo.cb_ProjectBldDelControl A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_ProjectBldDelControl A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '已完工工程楼栋删除设置表:cb_ProjectBldDelControl' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 
        
    ALTER TABLE cb_ProjectBldDelControl ENABLE TRIGGER ALL;

    --项目付款申请端口开放设置表  cb_ControlHTFKApplyProj
    ALTER TABLE cb_ControlHTFKApplyProj DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_ControlHTFKApplyProj_bak_20250121', N'U') IS NULL
    BEGIN
        SELECT  a.*
        INTO    dbo.cb_ControlHTFKApplyProj_bak_20250121
        FROM 
        (
            SELECT 
                    a.BuName,
                    a.BuGUID,
                    a.ControlHTFKApplyProjGUID,
                    a.ProjGUIDs,
                    a.ProjNames,
                    Value AS Projguid   
            FROM 
                    cb_ControlHTFKApplyProj a
            CROSS APPLY 
                    dbo.fn_Split1(a.ProjGUIDs, ',') 
            WHERE 
                    ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        ) a 
        INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;
    END

    -- 调整buguid和buname信息
    UPDATE A
    SET a.BuGUID = b.NewBuguid,
        a.BuName = b.NewBUName    
    FROM 
    (
        SELECT 
                a.BuName,
                a.BuGUID,
                a.ControlHTFKApplyProjGUID,
                a.ProjGUIDs,
                a.ProjNames,
                Value AS Projguid   
        FROM 
                cb_ControlHTFKApplyProj a
        CROSS APPLY 
                dbo.fn_Split1(a.ProjGUIDs, ',') 
        WHERE 
                ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
    ) a 
    INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
    WHERE a.buguid <> b.NewBuguid;

    PRINT '项目付款申请端口开放设置表：cb_ControlHTFKApplyProj' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 

    ALTER TABLE cb_ControlHTFKApplyProj ENABLE TRIGGER ALL;


    -- cb_DesignAlterToTZXT  设计变更信息传图纸系统监听表
    ALTER TABLE cb_DesignAlterToTZXT DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_DesignAlterToTZXT_bak_20250121', N'U') IS NULL
    BEGIN
        SELECT  a.*
        INTO    dbo.cb_DesignAlterToTZXT_bak_20250121
        FROM 
        (
            SELECT 
                a.id,
                a.DesignAlterGuid,
                a.BuGUID,
                a.ProjGuidList,
                a.ProjectInfo,
                Value AS Projguid   
            FROM 
                    cb_DesignAlterToTZXT a
            CROSS APPLY 
                    dbo.fn_Split1(a.ProjGuidList, ',') 
            WHERE 
                    ISNULL(convert(varchar(max), a.ProjGuidList), '') <> ''
        ) a 
        INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;
    END

    -- 调整buguid和buname信息
    UPDATE A
    SET a.BuGUID = b.NewBuguid
    FROM 
    (
        SELECT 
                a.id,
                a.DesignAlterGuid,
                a.BuGUID,
                a.ProjGuidList,
                a.ProjectInfo,
                Value AS Projguid   
        FROM 
                    cb_DesignAlterToTZXT a
        CROSS APPLY 
                    dbo.fn_Split1(a.ProjGuidList, ',') 
        WHERE 
                    ISNULL(convert(varchar(max), a.ProjGuidList), '') <> ''
    ) a 
    INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
    WHERE a.buguid <> b.NewBuguid;

    PRINT '设计变更信息传图纸系统监听表：cb_DesignAlterToTZXT' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 

    ALTER TABLE cb_DesignAlterToTZXT ENABLE TRIGGER ALL;
    --- ////////////////////////// 2025年新增成本表更新  结束 //////////////////////////  

    ---- cb_Task  任务设置表
    ALTER TABLE cb_Task DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Task_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_Task_bak_20250121
        FROM    dbo.cb_Task A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET BUGUID = B.NewBuguid
    FROM    dbo.cb_Task A
            INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

    PRINT '任务设置表:cb_Task' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Task ENABLE TRIGGER ALL;

    ---- cb_ZjPlan  资金计划表
    ALTER TABLE cb_ZjPlan DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_ZjPlan_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_ZjPlan_bak_20250121
        FROM    dbo.cb_ZjPlan A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode ,
        BUGUID = B.NewBuguid
    FROM    cb_ZjPlan A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '资金计划表:cb_ZjPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_ZjPlan ENABLE TRIGGER ALL;

    -- cb_CfDtl 成本拆分明细表
    ALTER TABLE cb_CfDtl DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_CfDtl_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_CfDtl_bak_20250121
        FROM    dbo.cb_CfDtl A
                INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    UPDATE  A
    SET A.ProjectCode = C.ProjCode
    FROM    cb_CfDtl A
            INNER JOIN #dqy_proj B ON A.ProjectCode = B.projcode352
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.OldProjGuid;

    PRINT '成本拆分明细表:cb_CfDtl' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_CfDtl ENABLE TRIGGER ALL;

    ALTER TABLE cb_CfRule DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_CfRule_bak_20250121', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_CfRule_bak_20250121
        FROM    dbo.cb_CfRule A
                INNER JOIN dbo.cb_ContractProj c ON c.ContractGUID = A.ContractGUID
                INNER JOIN #dqy_proj B ON c.ProjGUID = B.OldProjGuid
                INNER JOIN dbo.p_Project p ON p.ProjGUID = B.OldProjGuid;

    UPDATE  a
    SET a.ProjectCode = p.ProjCode
    FROM    dbo.cb_CfRule a
            INNER JOIN dbo.cb_ContractProj c ON c.ContractGUID = a.ContractGUID
            INNER JOIN #dqy_proj B ON c.ProjGUID = B.OldProjGuid
            INNER JOIN dbo.p_Project p ON p.ProjGUID = B.OldProjGuid;

    PRINT '成本拆分规则表:cb_CfRule' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_CfRule ENABLE TRIGGER ALL;

    --补充合同类别
    IF OBJECT_ID(N'cb_HtType_bak_20250121', N'U') IS NULL
        INSERT  dbo.cb_HtType(HtTypeGUID, BUGUID, HtTypeShortCode, HtTypeCode, HtTypeShortName, HtTypeName, ParentCode, Level, IfEnd, AlterWarnRate, PayWarnRate, CostGUID, FinanceHsxmCode ,
                              FinanceHsxmName , Remarks, HTProcessGUID, FhtProcessGUID, FDdhtProcessGUID, IsContractPG, IsCostControl, isNeedBudget, IsControlProviderTaxInfo, IsShowInvoiceRemark ,
                              IsConfirmMainContract)
        SELECT  NEWID() AS HtTypeGUID ,
                b.NewBuguid AS BUGUID ,
                HtTypeShortCode ,
                HtTypeCode ,
                HtTypeShortName ,
                HtTypeName ,
                ParentCode ,
                Level ,
                IfEnd ,
                AlterWarnRate ,
                PayWarnRate ,
                CostGUID ,
                FinanceHsxmCode ,
                FinanceHsxmName ,
                Remarks ,
                HTProcessGUID ,
                FhtProcessGUID ,
                FDdhtProcessGUID ,
                IsContractPG ,
                IsCostControl ,
                isNeedBudget ,
                IsControlProviderTaxInfo ,
                IsShowInvoiceRemark ,
                IsConfirmMainContract
        FROM    dbo.cb_HtType a
                LEFT JOIN(SELECT    DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) b ON a.BUGUID = b.OldBuguid
        WHERE   b.NewBuguid NOT IN(SELECT   BUGUID FROM dbo.cb_HtType);

    ALTER TABLE cb_Contract2HTType DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_Contract2HTType_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_Contract2HTType_bak_20250121
        FROM    dbo.cb_Contract2HTType a
                INNER JOIN dbo.cb_HtType c ON a.HtTypeGUID = c.HtTypeGUID
        WHERE   c.BUGUID IN(SELECT  OldBuguid FROM  #dqy_proj)
                AND  a.ContractGUID IN(SELECT   a.ContractGUID
                                       FROM     cb_Contract a
                                                LEFT JOIN cb_HtType b ON a.HtTypeCode = b.HtTypeCode AND a.BUGUID = b.BUGUID
                                                LEFT JOIN cb_Contract2HTType c ON a.ContractGUID = c.ContractGUID
                                       WHERE a.BUGUID IN(SELECT     NewBuguid FROM  #dqy_proj) AND  a.ContractGUID <> b.HtTypeGUID AND  a.ContractGUID <> c.HtTypeGUID AND  b.HtTypeGUID <> c.HtTypeGUID);

    UPDATE  a
    SET a.HtTypeGUID = d.HtTypeGUID ,
        a.BUGUID = c.BUGUID
    FROM    cb_Contract2HTType a
            INNER JOIN cb_Contract2HTType_bak_20250121 b ON a.ContractGUID = b.ContractGUID
            INNER JOIN dbo.cb_Contract c ON a.ContractGUID = c.ContractGUID
            INNER JOIN dbo.cb_HtType d ON d.BUGUID = c.BUGUID AND  d.HtTypeCode = c.HtTypeCode;

    PRINT '合同类别对应关系表:cb_Contract2HTType' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_Contract2HTType ENABLE TRIGGER ALL;

    ---更新部门信息
    --获取待迁移项目个数进行循环更新
    SELECT  * ,
            ROW_NUMBER() OVER (ORDER BY OldProjGuid) AS rowid
    INTO    #tmp_dqy
    FROM(SELECT * FROM  #dqy_proj WHERE 项目分类 LIKE '%项目%') t;

    DECLARE @i INT;

    SET @i = 1;

    DECLARE @num INT;

    SELECT  @num = MAX(rowid)FROM   #tmp_dqy;

    WHILE @i <= @num
        BEGIN
            DECLARE @projguid UNIQUEIDENTIFIER;
            DECLARE @BUGUID UNIQUEIDENTIFIER;
            DECLARE @buname VARCHAR(20);

            SELECT  @projguid = t.OldProjGuid ,
                    @BUGUID = bu.BUGUID ,
                    @buname = bu.BUName
            FROM    #tmp_dqy t
                    INNER JOIN myBusinessUnit bu ON t.NewBuguid = bu.BUGUID
            WHERE   t.rowid = @i;

            EXEC usp_p_UpdateProjDeptGUID @projguid, @BUGUID, @buname;

            SET @i = @i + 1;
        END;

    --刷新json 字段
    DECLARE @var_ContractGUID UNIQUEIDENTIFIER;
    DECLARE @count INT;
    SET @i = 1;

    SELECT  ROW_NUMBER() OVER (ORDER BY a.ContractCode) AS num ,
            a.*
    INTO    #cb_Contract
    FROM    dbo.cb_Contract a
            INNER JOIN dbo.cb_ContractProj b ON b.ContractGUID = a.ContractGUID
            INNER JOIN vcb_ContractGrid c ON c.ContractGUID = a.ContractGUID
            INNER JOIN #dqy_proj p ON b.ProjGUID = p.OldProjGuid
    WHERE   c.IsUseCostInfo = '是';

    --计算记录数
    SELECT  @count = COUNT(1)FROM   #cb_Contract;

    WHILE @i <= @count
        BEGIN
            SELECT  @var_ContractGUID = ContractGUID FROM   #cb_Contract WHERE  num = @i;

            PRINT '开始刷新json，剩余：';
            PRINT @count - @i;
            PRINT @var_ContractGUID;

            --刷新json
            EXEC dbo.usp_UpdateContractBudgetJson_Ds @var_ContractGUID;

            SET @i = @i + 1;
        END;

    --刷新成本系统财务接口数据
    --刷新财务公司 
    IF OBJECT_ID(N'p_cwjkcompany_bak_20250121', N'U') IS NULL
        SELECT  b.*
        INTO    dbo.p_cwjkcompany_bak_20250121
        FROM    dbo.p_cwjkproject_New a
                INNER JOIN dbo.p_cwjkcompany b ON a.CompanyGUID = b.CompanyGUID
                INNER JOIN #dqy_proj d ON d.OldProjGuid = a.ProjGUID;

    UPDATE  b
    SET b.BUGUID = d.NewBuguid
    FROM    dbo.p_cwjkproject_New a
            INNER JOIN dbo.p_cwjkcompany b ON a.CompanyGUID = b.CompanyGUID
            INNER JOIN #dqy_proj d ON d.OldProjGuid = a.ProjGUID;

    PRINT '财务公司p_cwjkcompany：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --刷新票易通
    IF OBJECT_ID(N'cb_PayConfirmSheet_Invoice_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_PayConfirmSheet_Invoice_bak_20250121
        FROM    dbo.cb_PayConfirmSheet_Invoice a
                LEFT JOIN(SELECT    (SELECT ApplyCode + ';'
                                     FROM   vcb_PayConfirmSheet_InvoiceRef
                                     WHERE  InvoiceGUID = ref.InvoiceGUID
                                    FOR XML PATH('')) AS ApplyCode ,
                                    InvoiceGUID ,
                                    ContractGUID
                          FROM  vcb_PayConfirmSheet_InvoiceRef ref
                          GROUP BY InvoiceGUID ,
                                   ContractGUID) d ON a.InvoiceGUID = d.InvoiceGUID
                LEFT JOIN dbo.cb_Contract ht ON d.ContractGUID = ht.ContractGUID
                INNER JOIN dbo.myBusinessUnit bu ON bu.BUGUID = ht.BUGUID
        WHERE   a.BUGUID <> bu.BUGUID AND   bu.BUGUID IN(SELECT NewBuguid FROM  #dqy_proj);

    UPDATE  a
    SET a.BUGUID = bu.BUGUID
    FROM    cb_PayConfirmSheet_Invoice a
            LEFT JOIN(SELECT    (SELECT ApplyCode + ';'
                                 FROM   vcb_PayConfirmSheet_InvoiceRef
                                 WHERE  InvoiceGUID = ref.InvoiceGUID
                                FOR XML PATH('')) AS ApplyCode ,
                                InvoiceGUID ,
                                ContractGUID
                      FROM  vcb_PayConfirmSheet_InvoiceRef ref
                      GROUP BY InvoiceGUID ,
                               ContractGUID) d ON a.InvoiceGUID = d.InvoiceGUID
            LEFT JOIN dbo.cb_Contract ht ON d.ContractGUID = ht.ContractGUID
            INNER JOIN dbo.myBusinessUnit bu ON bu.BUGUID = ht.BUGUID
    WHERE   a.BUGUID <> bu.BUGUID AND   bu.BUGUID IN(SELECT NewBuguid FROM  #dqy_proj);

    PRINT '易票通cb_PayConfirmSheet_Invoice：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'cb_PayConfirmSheet_Invoice_1_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_PayConfirmSheet_Invoice_1_bak_20250121
        FROM    dbo.cb_PayConfirmSheet_Invoice a
                INNER JOIN p_cwjkcompany cw ON cw.CompanyName = a.PurchaserName
        WHERE   a.BUGUID <> cw.BUGUID AND   a.BUGUID IN(SELECT  OldBuguid FROM  #dqy_proj);

    UPDATE  a
    SET a.BUGUID = cw.buguid
    FROM    dbo.cb_PayConfirmSheet_Invoice a
            INNER JOIN p_cwjkcompany cw ON cw.CompanyName = a.PurchaserName
    WHERE   a.BUGUID <> cw.BUGUID AND   a.BUGUID IN(SELECT  OldBuguid FROM  #dqy_proj);

    PRINT '根据名称刷新cb_PayConfirmSheet_Invoice：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'cb_InvoiceItem_bak_20250121', N'U') IS NULL
        --SELECT a.*
        --INTO dbo.cb_InvoiceItem_bak_20250121
        --FROM cb_InvoiceItem a
        --    INNER JOIN dbo.cb_Voucher b
        --        ON a.RefGUID = b.VouchGUID
        --    LEFT JOIN dbo.cb_Contract c
        --        ON b.ContractGUID = c.ContractGUID
        --    LEFT JOIN dbo.myBusinessUnit d
        --        ON c.DeptGUID = d.BUGUID
        --WHERE a.BUGUID <> c.BUGUID
        --        AND d.BUGUID IN (
        --                            SELECT NewBuguid FROM #dqy_proj
        --                        );

        --UPDATE a
        --SET a.BUGUID = d.BUGUID
        --FROM cb_InvoiceItem a
        --    INNER JOIN dbo.cb_Voucher b
        --        ON a.RefGUID = b.VouchGUID
        --    LEFT JOIN dbo.cb_Contract c
        --        ON b.ContractGUID = c.ContractGUID
        --    LEFT JOIN dbo.myBusinessUnit d
        --        ON c.DeptGUID = d.BUGUID
        --WHERE a.BUGUID <> c.BUGUID
        --      AND d.BUGUID IN (
        --                          SELECT NewBuguid FROM #dqy_proj
        --                      );
        SELECT  a.*
        INTO    dbo.cb_InvoiceItem_bak_20250121
        FROM    cb_InvoiceItem a
                INNER JOIN dbo.cb_Voucher b ON a.RefGUID = b.VouchGUID
                INNER JOIN dbo.cb_Contract c ON b.ContractGUID = c.ContractGUID
        WHERE   a.BUGUID <> c.BUGUID AND c.BUGUID IN(SELECT NewBuguid FROM  #dqy_proj);

    UPDATE  a
    SET a.BUGUID = c.BUGUID
    FROM    cb_InvoiceItem a
            INNER JOIN dbo.cb_Voucher b ON a.RefGUID = b.VouchGUID
            INNER JOIN dbo.cb_Contract c ON b.ContractGUID = c.ContractGUID
    WHERE   a.BUGUID <> c.BUGUID AND c.BUGUID IN(SELECT NewBuguid FROM  #dqy_proj);

    PRINT '票据类型cb_InvoiceItem：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'cb_Bank_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_Bank_bak_20250121
        FROM    cb_Bank a
                INNER JOIN dbo.cb_BankProj b ON a.BankGUID = b.BankGUID
                INNER JOIN #dqy_proj p ON b.ProjGUID = p.OldProjGuid;

    UPDATE  a
    SET a.BUGUID = p.NewBuguid
    FROM    cb_Bank a
            INNER JOIN dbo.cb_BankProj b ON a.BankGUID = b.BankGUID
            INNER JOIN #dqy_proj p ON b.ProjGUID = p.OldProjGuid;

    PRINT '银行信息cb_Bank：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTAlter DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HTAlter_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HTAlter_bak_20250121
        FROM    cb_HTAlter a
                LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
        WHERE   a.BUGUID <> b.BUGUID AND a.BUGUID IN(SELECT OldBuguid FROM  #dqy_proj);

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    cb_HTAlter a
            LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
    WHERE   a.BUGUID <> b.BUGUID AND a.BUGUID IN(SELECT OldBuguid FROM  #dqy_proj);

    PRINT '合同付款:cb_HTAlter' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTAlter ENABLE TRIGGER ALL;

    ALTER TABLE cb_HTFKApply DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HTFKApply_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HTFKApply_bak_20250121
        FROM    cb_HTFKApply a
                LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
        WHERE   a.BUGUID <> b.BUGUID AND a.BUGUID IN(SELECT OldBuguid FROM  #dqy_proj);

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    cb_HTFKApply a
            LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
    WHERE   a.BUGUID <> b.BUGUID AND a.BUGUID IN(SELECT OldBuguid FROM  #dqy_proj);

    PRINT '合同付款申请:cb_HTFKApply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTFKApply ENABLE TRIGGER ALL;

    ALTER TABLE cb_HTFKPlan DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HTFKPlan_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HTFKPlan_bak_20250121
        FROM    cb_HTFKPlan a
                LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
        WHERE   a.BUGUID <> b.BUGUID AND a.BUGUID IN(SELECT OldBuguid FROM  #dqy_proj);

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    cb_HTFKPlan a
            LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
    WHERE   a.BUGUID <> b.BUGUID AND a.BUGUID IN(SELECT OldBuguid FROM  #dqy_proj);

    PRINT '合同付款计划:cb_HTFKPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTFKPlan ENABLE TRIGGER ALL;

    --补充，刷新应收单
    ALTER TABLE cb_payfeebill DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_payfeebill_bak_20250121', N'U') IS NULL
        SELECT  bil.*
        INTO    cb_payfeebill_bak_20250121
        FROM    cb_contract con
                INNER JOIN cb_contractproj pro ON pro.contractguid = con.contractguid
                INNER JOIN #dqy_proj p ON p.oldprojguid = pro.projguid
                INNER JOIN cb_payfeebill bil ON bil.contractguid = con.contractguid
        WHERE   con.buguid <> bil.buguid;

    UPDATE  bil
    SET bil.BUGUID = con.BUGUID
    FROM    cb_contract con
            INNER JOIN cb_contractproj pro ON pro.contractguid = con.contractguid
            INNER JOIN #dqy_proj p ON p.oldprojguid = pro.projguid
            INNER JOIN cb_payfeebill bil ON bil.contractguid = con.contractguid
    WHERE   con.buguid <> bil.buguid;

    PRINT '应收单:cb_payfeebill' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_payfeebill ENABLE TRIGGER ALL;

    ------------------------------------补充
    ALTER TABLE cb_pay DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_pay_bak_20250121', N'U') IS NULL
        SELECT  cp.*
        INTO    cb_pay_bak_20250121
        FROM    cb_contract con
                INNER JOIN cb_pay cp ON cp.contractguid = con.contractguid
        WHERE   con.buguid <> cp.buguid;

    UPDATE  cp
    SET cp.BUGUID = con.BUGUID
    FROM    cb_contract con
            INNER JOIN cb_pay cp ON cp.contractguid = con.contractguid
    WHERE   con.buguid <> cp.buguid;

    PRINT '实付款单据:cb_pay' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_pay ENABLE TRIGGER ALL;

    --更新合同和合同预呈批的部门信息:统一刷新为公司信息 
    UPDATE  p
    SET p.DeptGUID = (SELECT    TOP 1  dept.BUGUID
                      FROM  myBusinessUnit dept
                      WHERE dept.CompanyGUID = p.BUGUID AND dept.Level = 3)
    FROM    cb_Contract_Pre p
            INNER JOIN myBusinessUnit bu ON p.DeptGUID = bu.BUGUID
            INNER JOIN #dqy_proj b ON p.buguid = b.newbuguid
    WHERE   p.BUGUID <> bu.CompanyGUID;

    UPDATE  p
    SET p.DeptGUID = (SELECT    TOP 1  dept.BUGUID
                      FROM  myBusinessUnit dept
                      WHERE dept.CompanyGUID = p.BUGUID AND dept.Level = 3)
    FROM    cb_Contract p
            INNER JOIN myBusinessUnit bu ON p.DeptGUID = bu.BUGUID
            INNER JOIN #dqy_proj b ON p.buguid = b.newbuguid
    WHERE   p.BUGUID <> bu.CompanyGUID;

    -----------------------------------处理合约包模板 begin ----------------------------- 
    --备份合约包模板
    IF OBJECT_ID(N'cb_HybTemplate_bak_20250121', N'U') IS NULL
        SELECT  t.* INTO    cb_HybTemplate_bak_20250121 FROM    cb_HybTemplate t;

    --在合约包模板中插入新模板
    INSERT INTO cb_HybTemplate
    SELECT  NEWID() HybTemplateGUID ,
            dqy.NewBuguid BUGUID ,
            HybTemplateName HybTemplateName ,
            GETDATE() CreatedOn ,
            Remark ,
            '系统管理员' CreatedBy ,
            IsHistory ,
            PublishTime ,
            PublishBy ,
            ApproveState ,
            YtName
    FROM    cb_HybTemplate t
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj WHERE qytype = 1) dqy ON t.BUGUID = dqy.OldBuguid;

    --不需要将原公司模板迁移到新公司，直接用新公司模板  
    UPDATE  t
    SET t.BUGUID = dqy.NewBuguid
    FROM    cb_HybTemplate t
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj WHERE qytype = 0) dqy ON t.BUGUID = dqy.OldBuguid;

    --在 合约包表（新）（新增表） 新增记录
    IF OBJECT_ID(N'cb_HybPack_bak_20250121', N'U') IS NULL
        SELECT  t.* INTO    cb_HybPack_bak_20250121 FROM    cb_HybPack t;

    INSERT INTO cb_HybPack
    SELECT  NEWID() ,
            newt.HybTemplateGUID ,
            pa.ContractBaseGUID ,
            pa.HtName ,
            pa.ParentCode ,
            pa.HtTypeGUID ,
            pa.HtFw ,
            pa.CreatedOn ,
            '系统管理员'
    FROM    cb_HybPack pa
            INNER JOIN cb_HybTemplate oldt ON pa.HybTemplateGUID = oldt.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj WHERE qytype = 1) dqy ON dqy.OldBuguid = oldt.BUGUID
            INNER JOIN cb_HybTemplate newt ON oldt.HybTemplateName = newt.HybTemplateName AND  newt.BUGUID = dqy.NewBuguid;

    --在 合约包模板关联科目表 新增记录
    IF OBJECT_ID(N'cb_HybTemplate2Cost_bak_20250121', N'U') IS NULL
        SELECT  t.* INTO    cb_HybTemplate2Cost_bak_20250121 FROM   cb_HybTemplate2Cost t;

    INSERT INTO cb_HybTemplate2Cost
    SELECT  newp.HybPackGUID ,
            NEWID() ,
            a.CostGUID ,
            a.CostCode ,
            a.ContractBaseGUID
    FROM    cb_HybTemplate2Cost a
            INNER JOIN cb_HybPack oldp ON a.HybPackGUID = oldp.HybPackGUID
            INNER JOIN cb_HybTemplate oldt ON oldp.HybTemplateGUID = oldt.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj WHERE qytype = 1) dqy ON dqy.OldBuguid = oldt.BUGUID
            INNER JOIN cb_HybTemplate newt ON oldt.HybTemplateName = newt.HybTemplateName AND  newt.BUGUID = dqy.NewBuguid
            INNER JOIN cb_HybPack newp ON oldp.HtName = newp.HtName AND newp.HybTemplateGUID = newt.HybTemplateGUID;

    --修改cb_HybPack的合同类别
    IF OBJECT_ID(N'cb_HybPack_httype_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HybPack_httype_bak_20250121
        FROM    cb_HybPack a
                INNER JOIN cb_HtType ht ON a.ParentCode = ht.HtTypeCode
                INNER JOIN(SELECT   DISTINCT NewBuguid FROM #dqy_proj) dqy ON ht.BUGUID = dqy.NewBuguid
                INNER JOIN cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID AND   tem.BUGUID = dqy.NewBuguid;

    UPDATE  a
    SET a.HtTypeGUID = ht.HtTypeGUID
    FROM    cb_HybPack a
            INNER JOIN cb_HtType ht ON a.ParentCode = ht.HtTypeCode
            INNER JOIN(SELECT   DISTINCT NewBuguid FROM #dqy_proj) dqy ON ht.BUGUID = dqy.NewBuguid
            INNER JOIN cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID AND   tem.BUGUID = dqy.NewBuguid;

    --修改cb_HybPack的合约库
    IF OBJECT_ID(N'cb_HybPack_CBG_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HybPack_CBG_bak_20250121
        FROM    cb_HybPack a
                INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID
                INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.NewBuguid
                INNER JOIN(SELECT   a1.* ,
                                    b1.BudgetName
                           FROM cb_HybPack a1
                                INNER JOIN cb_BudgetLibrary b1 ON a1.ContractBaseGUID = b1.BudgetLibraryGUID
                                INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a1.HybTemplateGUID
                                INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.OldBuguid) b ON a.HtName = b.HtName
                INNER JOIN cb_BudgetLibrary c ON c.BudgetName = b.BudgetName AND   dqy.NewBuguid = c.BUGUID;

    UPDATE  a
    SET a.ContractBaseGUID = c.BudgetLibraryGUID
    FROM    cb_HybPack a
            INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.NewBuguid
            INNER JOIN(SELECT   a1.* ,
                                b1.BudgetName
                       FROM cb_HybPack a1
                            INNER JOIN cb_BudgetLibrary b1 ON a1.ContractBaseGUID = b1.BudgetLibraryGUID
                            INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a1.HybTemplateGUID
                            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.OldBuguid) b ON a.HtName = b.HtName
            INNER JOIN cb_BudgetLibrary c ON c.BudgetName = b.BudgetName AND   dqy.NewBuguid = c.BUGUID;

    --修改cb_HybTemplate2Cost的科目信息
    IF OBJECT_ID(N'cb_HybTemplate2Cost_Cost_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HybTemplate2Cost_Cost_bak_20250121
        FROM    cb_HybTemplate2Cost a
                INNER JOIN cb_Cost b ON a.CostCode = b.CostCode
                INNER JOIN cb_HybPack hp ON hp.HybPackGUID = a.HybPackGUID
                INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON dqy.NewBuguid = b.BUGUID
                INNER JOIN dbo.cb_HybTemplate tmp ON tmp.HybTemplateGUID = hp.HybTemplateGUID AND  tmp.BUGUID = dqy.NewBuguid
        WHERE   ProjectType = '公司';

    UPDATE  a
    SET a.CostGUID = b.CostGUID
    FROM    cb_HybTemplate2Cost a
            INNER JOIN cb_Cost b ON a.CostCode = b.CostCode
            INNER JOIN cb_HybPack hp ON hp.HybPackGUID = a.HybPackGUID
            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON dqy.NewBuguid = b.BUGUID
            INNER JOIN dbo.cb_HybTemplate tmp ON tmp.HybTemplateGUID = hp.HybTemplateGUID AND  tmp.BUGUID = dqy.NewBuguid
    WHERE   ProjectType = '公司';

    --修改合约包模板信息 
    UPDATE  hyb
    SET hyb.HybTemplateGUID = newt.HybTemplateGUID
    FROM    dbo.cb_ProjHyb hyb
            INNER JOIN cb_HybTemplate oldt ON hyb.HybTemplateGUID = oldt.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj) dqy ON dqy.OldBuguid = oldt.BUGUID
            INNER JOIN cb_HybTemplate newt ON oldt.HybTemplateName = newt.HybTemplateName AND  newt.BUGUID = dqy.NewBuguid;

    UPDATE  hyb
    SET hyb.HybTemplateGUID = newt.HybTemplateGUID
    FROM    dbo.cb_ProjHyb_Working hyb
            INNER JOIN cb_HybTemplate oldt ON hyb.HybTemplateGUID = oldt.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj) dqy ON dqy.OldBuguid = oldt.BUGUID
            INNER JOIN cb_HybTemplate newt ON oldt.HybTemplateName = newt.HybTemplateName AND  newt.BUGUID = dqy.NewBuguid;

    -----------------------------------处理合约包模板 end -----------------------------

    --修改cb_HybPack的合同类别
    IF OBJECT_ID(N'cb_HybPack_httype_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HybPack_httype_bak_20250121
        FROM    cb_HybPack a
                INNER JOIN cb_HtType ht ON a.ParentCode = ht.HtTypeCode
                INNER JOIN(SELECT   DISTINCT NewBuguid FROM #dqy_proj) dqy ON ht.BUGUID = dqy.NewBuguid
                INNER JOIN cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID AND   tem.BUGUID = dqy.NewBuguid;

    UPDATE  a
    SET a.HtTypeGUID = ht.HtTypeGUID
    FROM    cb_HybPack a
            INNER JOIN cb_HtType ht ON a.ParentCode = ht.HtTypeCode
            INNER JOIN(SELECT   DISTINCT NewBuguid FROM #dqy_proj) dqy ON ht.BUGUID = dqy.NewBuguid
            INNER JOIN cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID AND   tem.BUGUID = dqy.NewBuguid;

    --修改cb_HybPack的合约库
    IF OBJECT_ID(N'cb_HybPack_CBG_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HybPack_CBG_bak_20250121
        FROM    cb_HybPack a
                INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID
                INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.NewBuguid
                INNER JOIN(SELECT   a1.* ,
                                    b1.BudgetName
                           FROM cb_HybPack a1
                                INNER JOIN cb_BudgetLibrary b1 ON a1.ContractBaseGUID = b1.BudgetLibraryGUID
                                INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a1.HybTemplateGUID
                                INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.OldBuguid) b ON a.HtName = b.HtName
                INNER JOIN cb_BudgetLibrary c ON c.BudgetName = b.BudgetName AND   dqy.NewBuguid = c.BUGUID;

    UPDATE  a
    SET a.ContractBaseGUID = c.BudgetLibraryGUID
    FROM    cb_HybPack a
            INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.NewBuguid
            INNER JOIN(SELECT   a1.* ,
                                b1.BudgetName
                       FROM cb_HybPack a1
                            INNER JOIN cb_BudgetLibrary b1 ON a1.ContractBaseGUID = b1.BudgetLibraryGUID
                            INNER JOIN dbo.cb_HybTemplate tem ON tem.HybTemplateGUID = a1.HybTemplateGUID
                            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON tem.BUGUID = dqy.OldBuguid) b ON a.HtName = b.HtName
            INNER JOIN cb_BudgetLibrary c ON c.BudgetName = b.BudgetName AND   dqy.NewBuguid = c.BUGUID;

    --修改cb_HybTemplate2Cost的科目信息
    IF OBJECT_ID(N'cb_HybTemplate2Cost_Cost_bak_20250121', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HybTemplate2Cost_Cost_bak_20250121
        FROM    cb_HybTemplate2Cost a
                INNER JOIN cb_Cost b ON a.CostCode = b.CostCode
                INNER JOIN cb_HybPack hp ON hp.HybPackGUID = a.HybPackGUID
                INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON dqy.NewBuguid = b.BUGUID
                INNER JOIN dbo.cb_HybTemplate tmp ON tmp.HybTemplateGUID = hp.HybTemplateGUID AND  tmp.BUGUID = dqy.NewBuguid
        WHERE   ProjectType = '公司';

    UPDATE  a
    SET a.CostGUID = b.CostGUID
    FROM    cb_HybTemplate2Cost a
            INNER JOIN cb_Cost b ON a.CostCode = b.CostCode
            INNER JOIN cb_HybPack hp ON hp.HybPackGUID = a.HybPackGUID
            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) dqy ON dqy.NewBuguid = b.BUGUID
            INNER JOIN dbo.cb_HybTemplate tmp ON tmp.HybTemplateGUID = hp.HybTemplateGUID AND  tmp.BUGUID = dqy.NewBuguid
    WHERE   ProjectType = '公司';

    --修改合约包模板信息 
    UPDATE  hyb
    SET hyb.HybTemplateGUID = newt.HybTemplateGUID
    FROM    dbo.cb_ProjHyb hyb
            INNER JOIN cb_HybTemplate oldt ON hyb.HybTemplateGUID = oldt.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj) dqy ON dqy.OldBuguid = oldt.BUGUID
            INNER JOIN cb_HybTemplate newt ON oldt.HybTemplateName = newt.HybTemplateName AND  newt.BUGUID = dqy.NewBuguid;

    UPDATE  hyb
    SET hyb.HybTemplateGUID = newt.HybTemplateGUID
    FROM    dbo.cb_ProjHyb_Working hyb
            INNER JOIN cb_HybTemplate oldt ON hyb.HybTemplateGUID = oldt.HybTemplateGUID
            INNER JOIN(SELECT   DISTINCT OldBuguid, NewBuguid FROM  #dqy_proj) dqy ON dqy.OldBuguid = oldt.BUGUID
            INNER JOIN cb_HybTemplate newt ON oldt.HybTemplateName = newt.HybTemplateName AND  newt.BUGUID = dqy.NewBuguid;

    -----------------------------------处理合约包模板 end -----------------------------

    -----------------------------------刷新合约规划的合同类别 begin 20250121 -----------------------------
    IF OBJECT_ID(N'cb_budget_working_httype_bak_20250121', N'U') IS NULL
        SELECT  a.budgetname ,
                a.WorkingBudgetGUID ,
                a.httypeguid ,
                c.httypeguid NewHttypeGUID
        INTO    cb_budget_working_httype_bak_20250121
        FROM    cb_budget_working a
                LEFT JOIN cb_httype b ON a.httypeguid = b.HtTypeGUID
                LEFT JOIN cb_httype c ON a.buguid = c.buguid AND   c.HtTypeCode = b.httypecode
        WHERE   b.httypeguid <> c.httypeguid;

    UPDATE  a
    SET a.httypeguid = c.httypeguid
    FROM    cb_budget_executing a
            INNER JOIN cb_budget_working_httype_bak_20250121 t ON t.WorkingBudgetGUID = a.ExecutingBudgetGUID
            LEFT JOIN cb_httype b ON a.httypeguid = b.HtTypeGUID
            LEFT JOIN cb_httype c ON a.buguid = c.buguid AND   c.HtTypeCode = b.httypecode;

    UPDATE  a
    SET a.httypeguid = c.httypeguid
    FROM    cb_budget_working a
            INNER JOIN cb_budget_working_httype_bak_20250121 t ON t.WorkingBudgetGUID = a.WorkingBudgetGUID
            LEFT JOIN cb_httype b ON a.httypeguid = b.HtTypeGUID
            LEFT JOIN cb_httype c ON a.buguid = c.buguid AND   c.HtTypeCode = b.httypecode;

    -----------------------------------刷新合约规划的合同类别 end 20250121 -----------------------------

    ----- 删除临时表 
    --DROP TABLE #dqy_proj;
END;
