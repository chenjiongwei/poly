use MyCost_Erp352
go 

/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏


2025-04-02 新增调整表
1、ys_YearBudgetDept_Detail_History 部门年度预算历史明细表
2、ys_YearBudgetDept_History 部门年度预算历史表
3、ys_YearPlanAdjustPLSB 公司预算调整批量上报表（暂不处理）
4、ys_YearPlanAdjustPLSBCompanyYs 公司预算调整批量上报公司预算表（暂不处理）
5、ys_YearPlanDept2Cost_Working 部门年度预算编制表
6、ys_YearPlanDept2CostExt 费用科目扩展表
7、ys_YearPlanProceeding2Cost_Working 部门年度预算编制表

*/

BEGIN
    --获取待迁移的信息
    SELECT  *, OldProjGuid AS projguid INTO #dqy_proj FROM  dbo.dqy_proj_20250411;

    --1、调整费用部门所属公司
    --备份
    IF OBJECT_ID(N'ys_SpecialBusinessUnit_bak20250411_cost', N'U') IS NULL
        SELECT  *
        INTO    ys_SpecialBusinessUnit_bak20250411_cost
        FROM    ys_SpecialBusinessUnit;

    UPDATE  a
    SET a.BUGUID = p.NewBuguid
    FROM    ys_SpecialBusinessUnit a
            INNER JOIN ys_fy_DeptToProject b ON a.SpecialUnitGUID = b.DeptGUID
            INNER JOIN #dqy_proj p ON p.ProjGUID = b.ProjectGUID
    WHERE   a.BUGUID <> p.NewBuguid;

    PRINT '刷新费用部门表所属公司：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --获取目标公司的预算部门清单
    SELECT  DISTINCT sbu.SpecialUnitGUID AS DeptGUID ,
                     sbu.Year ,
                     sbu.BUGUID
    INTO    #ys_SpecialBusinessUnit
    FROM    dbo.ys_SpecialBusinessUnit sbu
    INNER JOIN #dqy_proj t ON sbu.projguid = t.oldprojguid;

    --获取目标平台公司-目标公司所有年份的科目清单，若目标平台公司的ys_DeptCost为空，可以在系统基础设置中一键引入生成
    SELECT  DISTINCT dc.DeptCostGUID AS CostGUID ,
                     dc.CostCode ,
                     dc.ParentCode ,
                     dc.IsEndCost ,
                     dc.CostLevel ,
                     dc.Year ,
                     dc.BUGUID
    INTO    #ys_DeptCostMb
    FROM    dbo.ys_DeptCost dc
            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) p ON dc.BUGUID = p.NewBuguid;

    --获取获取源平台公司所有年份的科目清单
    SELECT  DISTINCT dc.DeptCostGUID AS CostGUID ,
                     dc.CostCode ,
                     dc.ParentCode ,
                     dc.IsEndCost ,
                     dc.CostLevel ,
                     dc.Year ,
                     dc.BUGUID
    INTO    #ys_DeptCostLy
    FROM    dbo.ys_DeptCost dc
            INNER JOIN(SELECT   DISTINCT NewBuguid, OldBuguid FROM  #dqy_proj) p ON dc.BUGUID = p.OldBuguid;

    --获取目标公司下合同GUID清单
    SELECT  DISTINCT c.ContractGUID
    INTO    #cb_Contract
    FROM    dbo.cb_Contract c
            INNER JOIN cb_Contractproj p1 ON c.ContractGUID = p1.ContractGUID
            INNER JOIN #dqy_proj p ON p1.projguid = p.oldprojguid
    WHERE   1 = 1 AND   c.IsFyControl = 1;

    --获取源公司及目标公司的项目代码 
    SELECT  p.* ,
            p1.projcode352 AS OldProjCode
    INTO    #mbProj
    FROM    p_Project p
            INNER JOIN #dqy_proj p1 ON p.ProjGUID = p1.OldProjGuid;

    --2、调整预呈批数据
    --备份要刷科目的预呈批的分摊明细
    IF OBJECT_ID(N'fy_Apply_FtDetail_20250411_cost', N'U') IS NULL
        SELECT  cfp.*
        INTO    fy_Apply_FtDetail_20250411_cost
        FROM    dbo.fy_Apply_FtDetail cfp
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = cfp.DeptGUID
                INNER JOIN #ys_DeptCostMb dc ON dc.CostCode = cfp.CostCode AND dc.Year = sbu.Year AND  sbu.buguid = dc.buguid;

    --刷预呈批的科目分摊明细
    UPDATE  cfp
    SET cfp.CostGUID = dc.CostGUID
    FROM    dbo.fy_Apply_FtDetail cfp
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = cfp.DeptGUID
            INNER JOIN #ys_DeptCostMb dc ON dc.CostCode = cfp.CostCode AND dc.Year = sbu.Year AND  sbu.buguid = dc.buguid
    WHERE   cfp.costguid <> dc.costguid;

    PRINT '刷预呈批的科目分摊明细：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份申请单分摊明细在分摊周期上的分摊信息
    IF OBJECT_ID(N'fy_Apply_FtDetail_Period_20250411_cost', N'U') IS NULL
        SELECT  cfp.*
        INTO    fy_Apply_FtDetail_Period_20250411_cost
        FROM    dbo.fy_Apply_FtDetail_Period cfp
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = cfp.DeptGUID
                INNER JOIN #ys_DeptCostMb dc ON dc.CostCode = cfp.CostCode AND sbu.buguid = dc.buguid AND  dc.Year = sbu.Year;

    --刷申请单分摊明细在分摊周期上的分摊信息科目GUID
    UPDATE  cfp
    SET cfp.CostGUID = dc.CostGUID
    FROM    dbo.fy_Apply_FtDetail_Period cfp
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = cfp.DeptGUID
            INNER JOIN #ys_DeptCostMb dc ON dc.CostCode = cfp.CostCode AND dc.buguid = sbu.buguid AND  dc.Year = sbu.Year;

    PRINT '刷申请单分摊明细在分摊周期上的分摊信息科目：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ----------------------------------------------------------------------------------
    --备份费用预算使用明细表
    IF OBJECT_ID(N'cb_DeptCostUseDtl_20250411_cost', N'U') IS NULL
        SELECT  dcud.*
        INTO    cb_DeptCostUseDtl_20250411_cost
        FROM    dbo.cb_DeptCostUseDtl dcud
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dcud.CostGUID
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dcud.DeptGUID
                INNER JOIN #ys_DeptCostMb dc ON dc.CostCode = dcl.CostCode AND sbu.buguid = dc.buguid AND  dc.Year = sbu.Year
        WHERE   dcud.ContractGUID IN(SELECT c.ContractGUID FROM #cb_Contract c);

    --更新费用预算使用明细表科目GUID
    UPDATE  dcud
    SET dcud.CostGUID = dc.CostGUID
    FROM    dbo.cb_DeptCostUseDtl dcud
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dcud.CostGUID
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dcud.DeptGUID
            INNER JOIN #ys_DeptCostMb dc ON dc.CostCode = dcl.CostCode AND dc.Year = sbu.Year AND  dc.buguid = sbu.buguid
    WHERE   dcud.ContractGUID IN(SELECT c.ContractGUID FROM #cb_Contract c);

    ----------------------------------------------------------------------------------

    --备份变更主表所属BUGUID
    IF OBJECT_ID(N'cb_HTAlter_20250411_cost', N'U') IS NULL
        SELECT  hta.*
        INTO    cb_HTAlter_20250411_cost
        FROM    dbo.cb_HTAlter hta
                INNER JOIN #cb_Contract c ON hta.ContractGUID = c.ContractGUID
                INNER JOIN cb_contractproj pr ON c.ContractGUID = pr.ContractGUID
                INNER JOIN #dqy_proj p ON pr.projguid = p.oldprojguid
        WHERE   1 = 1;

    --刷新变更主表所属BUGUID
    UPDATE  hta
    SET hta.BUGUID = p.NewBuguid
    FROM    dbo.cb_HTAlter hta
            INNER JOIN #cb_Contract c ON hta.ContractGUID = c.ContractGUID
            INNER JOIN cb_contractproj pr ON c.ContractGUID = pr.ContractGUID
            INNER JOIN #dqy_proj p ON pr.projguid = p.oldprojguid
    WHERE   1 = 1

    PRINT '刷新变更主表所属BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份变更明细表
    SELECT  hta.*
    INTO    #cb_HTAlter
    FROM    dbo.cb_HTAlter hta
    WHERE   1 = 1 AND   hta.ContractGUID IN(SELECT  c.ContractGUID FROM #cb_Contract c WHERE 1 = 1);

    IF OBJECT_ID(N'fy_HtAlter_FtDetail_Period_20250411_cost', N'U') IS NULL
        SELECT  hafp.*
        INTO    fy_HtAlter_FtDetail_Period_20250411_cost
        FROM    fy_HtAlter_FtDetail_Period hafp
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = hafp.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = hafp.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   sbu.buguid = dcm.buguid AND dcm.Year = dcl.Year
        WHERE   hafp.HtAlterGUID IN(SELECT  hta.HTAlterGUID FROM    #cb_HTAlter hta);

    --更新变更明细表科目GUID
    UPDATE  hafp
    SET hafp.CostGUID = dcm.CostGUID
    FROM    fy_HtAlter_FtDetail_Period hafp
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = hafp.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = hafp.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   sbu.buguid = dcm.buguid AND dcm.Year = dcl.Year
    WHERE   hafp.HtAlterGUID IN(SELECT  hta.HTAlterGUID FROM    #cb_HTAlter hta);

    PRINT '更新变更明细表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --获取目标公司下合同关联的结算单主表GUID
    SELECT  DISTINCT htb.HTBalanceGUID
    INTO    #cb_HTBalance
    FROM    dbo.cb_HTBalance htb
    WHERE   htb.ContractGUID IN(SELECT  c.ContractGUID FROM #cb_Contract c);

    --备份目标公司下合同关联的结算的明细表数据
    IF OBJECT_ID(N'fy_HTBalance_FtDetail_Period_20250411_cost', N'U') IS NULL
        SELECT  htbfp.*
        INTO    fy_HTBalance_FtDetail_Period_20250411_cost
        FROM    dbo.fy_HTBalance_FtDetail_Period htbfp
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = htbfp.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = htbfp.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        WHERE   htbfp.HTBalanceGUID IN(SELECT   htb.HTBalanceGUID FROM  #cb_HTBalance htb);

    --更新目标公司下合同关联的结算的明细表数据科目GUID
    UPDATE  htbfp
    SET htbfp.CostGUID = dcm.CostGUID
    FROM    dbo.fy_HTBalance_FtDetail_Period htbfp
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = htbfp.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = htbfp.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
    WHERE   htbfp.HTBalanceGUID IN(SELECT   htb.HTBalanceGUID FROM  #cb_HTBalance htb);

    PRINT '更新目标公司下合同关联的结算的明细表数据科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --获取目标公司下预呈批、合同、结算、变更GUID清单
    SELECT  DISTINCT cc.BizGUID
    INTO    #BizGUID
    FROM(SELECT a.ApplyGUID AS BizGUID
         FROM   dbo.fy_Apply a
         WHERE  a.DeptGUID IN(SELECT    sbu.DeptGUID FROM   #ys_SpecialBusinessUnit sbu)
         UNION
         SELECT htb.HTBalanceGUID AS BizGUID
         FROM   dbo.cb_HTBalance htb
                INNER JOIN #cb_Contract c ON c.ContractGUID = htb.ContractGUID
         UNION
         SELECT hta.HTAlterGUID AS BizGUID
         FROM   dbo.cb_HTAlter hta
                INNER JOIN #cb_Contract c ON c.ContractGUID = hta.ContractGUID
         UNION
         SELECT c.ContractGUID AS BizGUID
         FROM   #cb_Contract c) AS cc;

    --备份跨年结转主表所属BUGUID
    IF OBJECT_ID(N'fy_YearCarryOver_ydgs_20250411_cost', N'U') IS NULL
        SELECT  yco.*
        INTO    fy_YearCarryOver_ydgs_20250411_cost
        FROM    dbo.fy_YearCarryOver yco
                INNER JOIN fy_YearCarryOverFtDetail dtl ON yco.YearCarryOverGUID = dtl.YearCarryOverGUID
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dtl.DeptGUID
        WHERE   yco.BizGUID IN(SELECT   b.BizGUID FROM  #BizGUID b WHERE 1 = 1);

    --刷新跨年结转主表所属BUGUID
    UPDATE  yco
    SET yco.BUGUID = bu.BUGUID
    FROM    dbo.fy_YearCarryOver yco
            INNER JOIN fy_YearCarryOverFtDetail dtl ON yco.YearCarryOverGUID = dtl.YearCarryOverGUID
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dtl.DeptGUID
    WHERE   yco.BizGUID IN(SELECT   b.BizGUID FROM  #BizGUID b WHERE 1 = 1);

    PRINT '刷新跨年结转主表所属BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --获取目标公司预呈批、合同、变更、结算关联的结转主表GUID
    SELECT  DISTINCT yco.YearCarryOverGUID
    INTO    #YearCarryOverGUID
    FROM    dbo.fy_YearCarryOver yco
    WHERE   yco.BizGUID IN(SELECT   b.BizGUID FROM  #BizGUID b WHERE 1 = 1);

    --备份目标公司预呈批、合同、变更、结算关联的结转主表下的明细表数据
    IF OBJECT_ID(N'fy_YearCarryOverFtDetail_20250411_cost', N'U') IS NULL
        SELECT  ycofd.*
        INTO    fy_YearCarryOverFtDetail_20250411_cost
        FROM    dbo.fy_YearCarryOverFtDetail ycofd
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = ycofd.DeptGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = ycofd.CostCode AND dcm.Year = ycofd.FtYear AND dcm.buguid = bu.buguid
        WHERE   ycofd.YearCarryOverGUID IN(SELECT   y.YearCarryOverGUID FROM    #YearCarryOverGUID y WHERE 1 = 1);

    --刷目标公司预呈批、合同、变更、结算关联的结转主表下的明细表数据科目GUID
    UPDATE  ycofd
    SET ycofd.CostGUID = dcm.CostGUID
    FROM    dbo.fy_YearCarryOverFtDetail ycofd
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = ycofd.DeptGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = ycofd.CostCode AND dcm.Year = ycofd.FtYear AND dcm.buguid = bu.buguid
    WHERE   ycofd.YearCarryOverGUID IN(SELECT   y.YearCarryOverGUID FROM    #YearCarryOverGUID y WHERE 1 = 1);

    PRINT '刷目标公司预呈批、合同、变更、结算关联的结转主表下的明细表数据科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份费用使用事实表
    IF OBJECT_ID(N'ys_fy_FactDeptFeeUsed_bu_20250411_cost', N'U') IS NULL
        SELECT  fdfu.*
        INTO    ys_fy_FactDeptFeeUsed_bu_20250411_cost
        FROM    dbo.ys_fy_FactDeptFeeUsed fdfu
        WHERE   fdfu.DeptGUID IN(SELECT DISTINCT sbu.DeptGUID FROM  #ys_SpecialBusinessUnit sbu);

    --更新费用使用事实表BUGUID
    UPDATE  fdfu
    SET fdfu.BUGUID = p.buguid
    FROM    dbo.ys_fy_FactDeptFeeUsed fdfu
            INNER JOIN #ys_SpecialBusinessUnit p ON fdfu.DeptGUID = p.DeptGUID;

    PRINT '更新费用使用事实表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份更新费用使用事实表科目GUID
    IF OBJECT_ID(N'ys_fy_FactDeptFeeUsed_cost_20250411_cost', N'U') IS NULL
        SELECT  fdfu.*
        INTO    ys_fy_FactDeptFeeUsed_cost_20250411_cost
        FROM    dbo.ys_fy_FactDeptFeeUsed fdfu
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = fdfu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = fdfu.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   dcm.buguid = bu.buguid AND  dcm.Year = dcl.Year;

    --更新费用使用事实表科目GUID
    UPDATE  fdfu
    SET fdfu.CostGUID = dcm.CostGUID
    FROM    dbo.ys_fy_FactDeptFeeUsed fdfu
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = fdfu.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = fdfu.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = bu.buguid;

    PRINT '更新费用使用事实表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份费用事项使用事实表
    IF OBJECT_ID(N'ys_fy_FactProceedingFeeUsed_bu_20250411_cost', N'U') IS NULL
        SELECT  fdfu.*
        INTO    ys_fy_FactProceedingFeeUsed_bu_20250411_cost
        FROM    dbo.ys_fy_FactProceedingFeeUsed fdfu
        WHERE   fdfu.DeptGUID IN(SELECT DISTINCT sbu.DeptGUID FROM  #ys_SpecialBusinessUnit sbu);

    --更新费用事项使用事实表BUGUID
    UPDATE  fdfu
    SET fdfu.BUGUID = bu.BUGUID
    FROM    dbo.ys_fy_FactProceedingFeeUsed fdfu
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = fdfu.DeptGUID;

    PRINT '更新费用事项使用事实表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份更新事项费用使用事实表科目GUID
    IF OBJECT_ID(N'ys_fy_FactProceedingFeeUsed_cost_20250411_cost', N'U') IS NULL
        SELECT  fdfu.*
        INTO    ys_fy_FactProceedingFeeUsed_cost_20250411_cost
        FROM    dbo.ys_fy_FactProceedingFeeUsed fdfu
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = fdfu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = fdfu.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = bu.buguid;

    --更新费用事项使用事实表科目GUID
    UPDATE  fdfu
    SET fdfu.CostGUID = dcm.CostGUID
    FROM    dbo.ys_fy_FactProceedingFeeUsed fdfu
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = fdfu.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = fdfu.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcl.CostCode = dcm.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = bu.buguid;

    PRINT '更新费用事项使用事实表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份公司部门费用事实表
    IF OBJECT_ID(N'ys_FactDepartmentFee_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    ys_FactDepartmentFee_20250411_cost
        FROM    dbo.ys_FactDepartmentFee fdf
                INNER JOIN #ys_SpecialBusinessUnit sbu ON fdf.SpecialUnitGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.DeptCostGUID = dcl.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year;

    --备份公司部门费用事实表科目GUID
    UPDATE  fdf
    SET fdf.DeptCostGUID = dcm.CostGUID
    FROM    dbo.ys_FactDepartmentFee fdf
            INNER JOIN #ys_SpecialBusinessUnit sbu ON fdf.SpecialUnitGUID = sbu.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON fdf.DeptCostGUID = dcl.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year;

    PRINT '更新公司部门费用事实表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份公司部门费用事实表
    IF OBJECT_ID(N'ys_FactProceedingFee_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    ys_FactProceedingFee_20250411_cost
        FROM    dbo.ys_FactProceedingFee fdf
                INNER JOIN #ys_SpecialBusinessUnit sbu ON fdf.SpecialUnitGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.DeptCostGUID = dcl.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = sbu.buguid;

    --更新部门费用事实明细表科目GUID
    UPDATE  fdf
    SET fdf.DeptCostGUID = dcm.CostGUID
    FROM    dbo.ys_FactProceedingFee fdf
            INNER JOIN #ys_SpecialBusinessUnit sbu ON fdf.SpecialUnitGUID = sbu.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON fdf.DeptCostGUID = dcl.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = sbu.buguid;

    PRINT '更新部门费用事实明细表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份业务费用分摊历史分摊表
    IF OBJECT_ID(N'fy_FtDetail_His_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    fy_FtDetail_His_20250411_cost
        FROM    dbo.fy_FtDetail_His fdf
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = fdf.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = sbu.buguid;

    --更新业务费用分摊历史分摊表科目GUID
    UPDATE  fdf
    SET fdf.CostGUID = dcm.CostGUID
    FROM    dbo.fy_FtDetail_His fdf
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = fdf.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = sbu.buguid;

    PRINT '更新业务费用分摊历史分摊表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份业务费用分摊历史分摊明细表
    IF OBJECT_ID(N'fy_FtDetail_Period_His_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    fy_FtDetail_Period_His_20250411_cost
        FROM    dbo.fy_FtDetail_Period_His fdf
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = fdf.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = sbu.buguid;

    --更新业务费用分摊历史分摊明细表科目GUID
    UPDATE  fdf
    SET fdf.CostGUID = dcm.CostGUID
    FROM    dbo.fy_FtDetail_Period_His fdf
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = fdf.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.Year = dcl.Year AND dcm.buguid = sbu.buguid;

    PRINT '更新业务费用分摊历史分摊明细表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_DeptCostCfDtl表
    IF OBJECT_ID(N'fy_DeptCostCfDtl_20250411_cost', N'U') IS NULL
        SELECT  dccd.*
        INTO    fy_DeptCostCfDtl_20250411_cost
        FROM    dbo.fy_DeptCostCfDtl dccd
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新fy_DeptCostCfDtl表科目GUID
    UPDATE  dccd
    SET dccd.CostGUID = dcm.CostGUID
    FROM    dbo.fy_DeptCostCfDtl dccd
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新fy_DeptCostCfDtl表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_DeptCostCfRule表
    IF OBJECT_ID(N'fy_DeptCostCfRule_20250411_cost', N'U') IS NULL
        SELECT  dccd.*
        INTO    fy_DeptCostCfRule_20250411_cost
        FROM    dbo.fy_DeptCostCfRule dccd
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新fy_DeptCostCfRule表科目GUID
    UPDATE  dccd
    SET dccd.CostGUID = dcm.CostGUID
    FROM    dbo.fy_DeptCostCfRule dccd
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新fy_DeptCostCfRule表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_CfPayDeptCost表
    IF OBJECT_ID(N'ys_CfPayDeptCost_20250411_cost', N'U') IS NULL
        SELECT  dccd.*
        INTO    ys_CfPayDeptCost_20250411_cost
        FROM    dbo.ys_CfPayDeptCost dccd
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新ys_CfPayDeptCost表科目GUID
    UPDATE  dccd
    SET dccd.CostGUID = dcm.CostGUID
    FROM    dbo.ys_CfPayDeptCost dccd
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新ys_CfPayDeptCost表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_Dept2DeptAdjustDtl表
    IF OBJECT_ID(N'ys_Dept2DeptAdjustDtl_20250411_cost', N'U') IS NULL
        SELECT  dccd.*
        INTO    ys_Dept2DeptAdjustDtl_20250411_cost
        FROM    dbo.ys_Dept2DeptAdjustDtl dccd
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新ys_Dept2DeptAdjustDtl表科目GUID
    UPDATE  dccd
    SET dccd.CostGUID = dcm.CostGUID
    FROM    dbo.ys_Dept2DeptAdjustDtl dccd
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新ys_Dept2DeptAdjustDtl表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_Dept2DeptAdjust表
    IF OBJECT_ID(N'ys_Dept2DeptAdjust_20250411_cost', N'U') IS NULL
        SELECT  d2da.*
        INTO    ys_Dept2DeptAdjust_20250411_cost
        FROM    dbo.ys_Dept2DeptAdjust d2da
                INNER JOIN dbo.ys_Dept2DeptAdjustDtl d2dad ON d2dad.Dept2DeptAdjustGUID = d2da.Dept2DeptAdjustGUID
        WHERE   d2dad.DeptGUID IN(SELECT    DISTINCT   sbu.DeptGUID FROM    #ys_SpecialBusinessUnit sbu);

    --备份ys_Dept2DeptAdjust表
    UPDATE  d2da
    SET d2da.BUGUID = bu.BUGUID
    FROM    dbo.ys_Dept2DeptAdjust d2da
            INNER JOIN dbo.ys_Dept2DeptAdjustDtl d2dad ON d2dad.Dept2DeptAdjustGUID = d2da.Dept2DeptAdjustGUID
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = d2dad.DeptGUID;

    PRINT '更新ys_Dept2DeptAdjust表公司GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_DimProceedingToCost表
    IF OBJECT_ID(N'ys_fy_DimProceedingToCost_cost_20250411_cost', N'U') IS NULL
        SELECT  dccd.*
        INTO    ys_fy_DimProceedingToCost_cost_20250411_cost
        FROM    dbo.ys_fy_DimProceedingToCost dccd
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新ys_fy_DimProceedingToCost表科目GUID
    UPDATE  dccd
    SET dccd.CostGUID = dcm.CostGUID
    FROM    dbo.ys_fy_DimProceedingToCost dccd
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新ys_fy_DimProceedingToCost表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_DimProceedingToCost表
    IF OBJECT_ID(N'ys_fy_DimProceedingToCost_bu_20250411_cost', N'U') IS NULL
        SELECT  *
        INTO    ys_fy_DimProceedingToCost_bu_20250411_cost
        FROM    dbo.ys_fy_DimProceedingToCost dptc
        WHERE   dptc.DeptGUID IN(SELECT DISTINCT sbu.DeptGUID FROM  #ys_SpecialBusinessUnit sbu);

    --更新ys_fy_DimProceedingToCost表BUGUID
    UPDATE  dptc
    SET dptc.BUGUID = bu.BUGUID
    FROM    dbo.ys_fy_DimProceedingToCost dptc
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dptc.DeptGUID;

    PRINT '更新ys_fy_DimProceedingToCost表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_DimProceeding表
    IF OBJECT_ID(N'ys_fy_DimProceeding_20250411_cost', N'U') IS NULL
        SELECT  dptc.*
        INTO    ys_fy_DimProceeding_20250411_cost
        FROM    dbo.ys_fy_DimProceeding dptc
                INNER JOIN ys_fy_DimProceedingToCost b ON b.ProceedingGUID = dptc.ProceedingGUID
        WHERE   dptc.BUGUID <> b.BUGUID;

    --更新ys_fy_DimProceedingToCost表BUGUID
    UPDATE  dptc
    SET dptc.BUGUID = b.BUGUID
    FROM    dbo.ys_fy_DimProceeding dptc
            INNER JOIN ys_fy_DimProceedingToCost b ON b.ProceedingGUID = dptc.ProceedingGUID
    WHERE   dptc.BUGUID <> b.BUGUID;;

    PRINT '更新ys_fy_DimProceeding表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_FactDeptPeopleNum表
    IF OBJECT_ID(N'ys_fy_FactDeptPeopleNum_20250411_cost', N'U') IS NULL
        SELECT  *
        INTO    ys_fy_FactDeptPeopleNum_20250411_cost
        FROM    dbo.ys_fy_FactDeptPeopleNum dptc
        WHERE   dptc.DeptGUID IN(SELECT DISTINCT sbu.DeptGUID FROM  #ys_SpecialBusinessUnit sbu);

    --更新ys_fy_FactDeptPeopleNum表BUGUID
    UPDATE  dptc
    SET dptc.BUGUID = bu.BUGUID
    FROM    dbo.ys_fy_FactDeptPeopleNum dptc
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dptc.DeptGUID;

    PRINT '更新ys_fy_FactDeptPeopleNum表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_SaleFactDeptFeeUsed表
    IF OBJECT_ID(N'ys_fy_SaleFactDeptFeeUsed_20250411_cost', N'U') IS NULL
        SELECT  dccd.*
        INTO    ys_fy_SaleFactDeptFeeUsed_20250411_cost
        FROM    dbo.ys_fy_SaleFactDeptFeeUsed dccd
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新ys_fy_SaleFactDeptFeeUsed表科目GUID
    UPDATE  dccd
    SET dccd.CostGUID = dcm.CostGUID
    FROM    dbo.ys_fy_SaleFactDeptFeeUsed dccd
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.CostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新ys_fy_SaleFactDeptFeeUsed表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_SaleMonthPlan_FyysDetail表
    IF OBJECT_ID(N'ys_fy_SaleMonthPlan_FyysDetail_20250411_cost', N'U') IS NULL
        SELECT  smpfd.*
        INTO    ys_fy_SaleMonthPlan_FyysDetail_20250411_cost
        FROM    dbo.ys_fy_SaleMonthPlan_FyysDetail smpfd
                INNER JOIN dbo.ys_fy_SaleMonthPlan smp ON smpfd.PlanGUID = smp.GUID
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = smp.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = smpfd.DeptCostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新ys_fy_SaleMonthPlan_FyysDetail表科目GUID
    UPDATE  smpfd
    SET smpfd.DeptCostGUID = dcm.CostGUID
    FROM    dbo.ys_fy_SaleMonthPlan_FyysDetail smpfd
            INNER JOIN dbo.ys_fy_SaleMonthPlan smp ON smpfd.PlanGUID = smp.GUID
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = smp.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = smpfd.DeptCostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新ys_fy_SaleMonthPlan_FyysDetail表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_SaleMonthPlanHistory_FyysDetail表
    IF OBJECT_ID(N'ys_fy_SaleMonthPlanHistory_FyysDetail_20250411_cost', N'U') IS NULL
        SELECT  smpfd.*
        INTO    ys_fy_SaleMonthPlanHistory_FyysDetail_20250411_cost
        FROM    dbo.ys_fy_SaleMonthPlanHistory_FyysDetail smpfd
                INNER JOIN dbo.ys_fy_SaleMonthPlan smp ON smpfd.PlanGUID = smp.GUID
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = smp.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = smpfd.DeptCostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新ys_fy_SaleMonthPlanHistory_FyysDetail表科目GUID
    UPDATE  smpfd
    SET smpfd.DeptCostGUID = dcm.CostGUID
    FROM    dbo.ys_fy_SaleMonthPlanHistory_FyysDetail smpfd
            INNER JOIN dbo.ys_fy_SaleMonthPlan smp ON smpfd.PlanGUID = smp.GUID
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = smp.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = smpfd.DeptCostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新ys_fy_SaleMonthPlanHistory_FyysDetail表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_R3FactCompanyCostExecute表
    IF OBJECT_ID(N'ys_R3FactCompanyCostExecute_cost_20250411_cost', N'U') IS NULL
        SELECT  dccd.*
        INTO    ys_R3FactCompanyCostExecute_cost_20250411_cost
        FROM    dbo.ys_R3FactCompanyCostExecute dccd
                INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.DeptCostGUID
                INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    --更新ys_R3FactCompanyCostExecute表科目GUID
    UPDATE  dccd
    SET dccd.DeptCostGUID = dcm.CostGUID
    FROM    dbo.ys_R3FactCompanyCostExecute dccd
            INNER JOIN #ys_SpecialBusinessUnit sbu ON sbu.DeptGUID = dccd.DeptGUID
            INNER JOIN #ys_DeptCostLy dcl ON dcl.CostGUID = dccd.DeptCostGUID
            INNER JOIN #ys_DeptCostMb dcm ON dcm.Year = dcl.Year AND   dcm.CostCode = dcl.CostCode AND dcm.buguid = sbu.buguid;

    PRINT '更新ys_R3FactCompanyCostExecute表科目GUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_R3FactCompanyCostExecute表
    IF OBJECT_ID(N'ys_R3FactCompanyCostExecute_bu_20250411_cost', N'U') IS NULL
        SELECT  *
        INTO    ys_R3FactCompanyCostExecute_bu_20250411_cost
        FROM    dbo.ys_R3FactCompanyCostExecute dptc
        WHERE   dptc.DeptGUID IN(SELECT DISTINCT sbu.DeptGUID FROM  #ys_SpecialBusinessUnit sbu);

    --更新ys_R3FactCompanyCostExecute表BUGUID
    UPDATE  dptc
    SET dptc.BUGUID = bu.BUGUID
    FROM    dbo.ys_R3FactCompanyCostExecute dptc
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dptc.DeptGUID;

    PRINT '更新ys_R3FactCompanyCostExecute表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_PublishYearBudgetDept表
    IF OBJECT_ID(N'ys_PublishYearBudgetDept_20250411_cost', N'U') IS NULL
        SELECT  dptc.*
        INTO    ys_PublishYearBudgetDept_20250411_cost
        FROM    dbo.ys_PublishYearBudgetDept dptc
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dptc.BudgetDeptGUID;

    --更新ys_PublishYearBudgetDept表BUGUID
    UPDATE  dptc
    SET dptc.BUGUID = bu.BUGUID
    FROM    dbo.ys_PublishYearBudgetDept dptc
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dptc.BudgetDeptGUID;

    PRINT '更新ys_PublishYearBudgetDept表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_R3DimDepartment表
    IF OBJECT_ID(N'ys_R3DimDepartment_20250411_cost', N'U') IS NULL
        SELECT  *
        INTO    ys_R3DimDepartment_20250411_cost
        FROM    dbo.ys_R3DimDepartment dptc
        WHERE   dptc.SpecialUnitGUID IN(SELECT  DISTINCT sbu.DeptGUID FROM  #ys_SpecialBusinessUnit sbu);

    --更新ys_R3DimDepartment表BUGUID
    UPDATE  dptc
    SET dptc.BUGUID = bu.BUGUID
    FROM    dbo.ys_R3DimDepartment dptc
            INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = dptc.SpecialUnitGUID;

    PRINT '更新ys_R3DimDepartment表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_DeptCost2ContractUseDtl表
    IF OBJECT_ID(N'ys_DeptCost2ContractUseDtl_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_DeptCost2ContractUseDtl_20250411_cost
        FROM    ys_DeptCost2ContractUseDtl a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID;

    UPDATE  a
    SET a.CostGUID = e.CostGUID
    FROM    ys_DeptCost2ContractUseDtl a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON d.CostGUID = a.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND b.buguid = e.buguid
    WHERE   a.CostGUID <> e.CostGUID;

    PRINT '更新ys_DeptCost2ContractUseDtl表CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_Contract_FtDetail_Period表
    IF OBJECT_ID(N'fy_Contract_FtDetail_Period_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_Contract_FtDetail_Period_20250411_cost
        FROM    fy_Contract_FtDetail_Period a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy d ON d.CostGUID = a.CostGUID
                INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND b.buguid = e.buguid
        WHERE   a.CostGUID <> e.CostGUID;

    --修改costguid
    UPDATE  a
    SET a.CostGUID = e.CostGUID
    FROM    fy_Contract_FtDetail_Period a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON d.CostGUID = a.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND b.buguid = e.buguid
    WHERE   a.CostGUID <> e.CostGUID;

    PRINT '更新fy_Contract_FtDetail_Period表CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_DimDeptToCost表
    IF OBJECT_ID(N'ys_fy_DimDeptToCost_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_fy_DimDeptToCost_20250411_cost
        FROM    ys_fy_DimDeptToCost a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
                INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND e.buguid = b.buguid
        WHERE   a.CostGUID <> e.CostGUID;

    --修改
    PRINT '修改ys_fy_DimDeptToCost表';

    UPDATE  a
    SET a.BUGUID = b.BUGUID ,
        a.CostGUID = e.CostGUID
    FROM    ys_fy_DimDeptToCost a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND e.buguid = b.buguid
    WHERE   a.CostGUID <> e.CostGUID AND a.BUGUID <> b.BUGUID;

    PRINT '更新ys_fy_DimDeptToCost表CostGUID、BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_CostPlanAdjust表
    IF OBJECT_ID(N'ys_CostPlanAdjust_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_CostPlanAdjust_20250411_cost
        FROM    ys_CostPlanAdjust a
                INNER JOIN #mbProj b ON a.ProjCode = b.OldProjCode;

    --修改
    UPDATE  a
    SET a.ProjCode = b.ProjCode
    FROM    ys_CostPlanAdjust a
            INNER JOIN #mbProj b ON a.ProjCode = b.OldProjCode
    WHERE   a.ProjCode <> b.ProjCode;

    PRINT '更新ys_CostPlanAdjust表ProjCode：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ---修改ys_YearPlanProceeding2Cost表
    IF OBJECT_ID(N'ys_YearPlanProceeding2Cost_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_YearPlanProceeding2Cost_20250411_cost
        FROM    ys_YearPlanProceeding2Cost a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
                INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND b.buguid = e.buguid
        WHERE   a.BUGUID <> b.BUGUID AND a.CostGUID <> e.CostGUID;

    --修改
    UPDATE  a
    SET a.BUGUID = b.BUGUID ,
        a.CostGUID = e.CostGUID
    FROM    ys_YearPlanProceeding2Cost a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND b.buguid = e.buguid
    WHERE   a.BUGUID <> b.BUGUID AND a.CostGUID <> e.CostGUID;

    PRINT '更新ys_YearPlanProceeding2Cost表BUGUID、CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_YearPlanDept2Cost表
    IF OBJECT_ID(N'ys_YearPlanDept2Cost_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_YearPlanDept2Cost_20250411_cost
        FROM    ys_YearPlanDept2Cost a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
                INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND e.buguid = b.buguid
        WHERE   a.BUGUID <> b.BUGUID AND a.CostGUID <> e.CostGUID;

    --修改
    UPDATE  a
    SET a.BUGUID = b.BUGUID ,
        a.CostGUID = e.CostGUID
    FROM    ys_YearPlanDept2Cost a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND e.buguid = b.buguid
    WHERE   a.BUGUID <> b.BUGUID AND a.CostGUID <> e.CostGUID;

    PRINT '更新ys_YearPlanDept2Cost表BUGUID、CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_DeptCostCfRule表
    IF OBJECT_ID(N'fy_DeptCostCfRule_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_DeptCostCfRule_20250411_cost
        FROM    fy_DeptCostCfRule a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID;

    --修改fy_DeptCostCfRule的ProjectCode字段
    UPDATE  a
    SET a.ProjectCode = p.ProjCode
    FROM    fy_DeptCostCfRule a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #mbProj p ON p.OldProjCode = a.ProjectCode
    WHERE   a.ProjectCode <> p.ProjCode;

    PRINT '更新fy_DeptCostCfRule表ProjCode：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --修改fy_DeptCostCfRule的CostGUID字段
    UPDATE  a
    SET a.CostGUID = e.CostGUID
    FROM    fy_DeptCostCfRule a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND b.buguid = e.buguid
    WHERE   a.CostGUID <> e.CostGUID;

    PRINT '更新fy_DeptCostCfRule表CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_Proj_FeeTargetTotal表
    IF OBJECT_ID(N'fy_Proj_FeeTargetTotal_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_Proj_FeeTargetTotal_20250411_cost
        FROM    dbo.fy_Proj_FeeTargetTotal a
                INNER JOIN #mbProj p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    dbo.fy_Proj_FeeTargetTotal a
            INNER JOIN #mbProj p ON a.ProjGUID = p.ProjGUID
    WHERE   a.BUGUID <> p.BUGUID;

    PRINT '更新fy_Proj_FeeTargetTotal表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_DimDept表
    IF OBJECT_ID(N'fy_DimDept_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_DimDept_20250411_cost
        FROM    fy_DimDept a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
        WHERE   a.BUGUID <> b.BUGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    fy_DimDept a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '更新fy_DimDept表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_HtAlter_FtDetail_Period表
    IF OBJECT_ID(N'fy_HtAlter_FtDetail_Period_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_HtAlter_FtDetail_Period_20250411_cost
        FROM    fy_HtAlter_FtDetail_Period a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
                INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND e.buguid = b.buguid
        WHERE   a.CostGUID <> e.CostGUID;

    --修改
    UPDATE  a
    SET a.CostGUID = e.CostGUID
    FROM    fy_HtAlter_FtDetail_Period a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND e.buguid = b.buguid
    WHERE   a.CostGUID <> e.CostGUID;

    PRINT '更新fy_HtAlter_FtDetail_Period表CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份cb_DeptCostUseDtl表
    IF OBJECT_ID(N'cb_DeptCostUseDtl_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    cb_DeptCostUseDtl_20250411_cost
        FROM    cb_DeptCostUseDtl a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
                INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.CostCode = d.CostCode AND e.buguid = b.buguid
        WHERE   a.CostGUID <> e.CostGUID;

    --修改
    UPDATE  a
    SET a.CostGUID = e.CostGUID
    FROM    cb_DeptCostUseDtl a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy d ON a.CostGUID = d.CostGUID
            INNER JOIN #ys_DeptCostMb e ON e.Year = d.Year AND e.buguid = b.buguid AND e.CostCode = d.CostCode
    WHERE   a.CostGUID <> e.CostGUID;

    PRINT '更新cb_DeptCostUseDtl表CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_DeptPeopleNum表
    IF OBJECT_ID(N'ys_DeptPeopleNum_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_DeptPeopleNum_20250411_cost
        FROM    ys_DeptPeopleNum a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
        WHERE   a.BUGUID <> b.BUGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_DeptPeopleNum a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '更新ys_DeptPeopleNum表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_DynamicCostReview表
    IF OBJECT_ID(N'ys_DynamicCostReview_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_DynamicCostReview_20250411_cost
        FROM    ys_DynamicCostReview a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
        WHERE   a.BUGUID <> b.BUGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_DynamicCostReview a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '更新ys_DynamicCostReview表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_FileTypeControlDetail表
    IF OBJECT_ID(N'ys_FileTypeControlDetail_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_FileTypeControlDetail_20250411_cost
        FROM    ys_FileTypeControlDetail a
                INNER JOIN ys_ContractTypeFile b ON a.FileTypeControlDetailGUID = b.FileTypeControlDetailGUID
                INNER JOIN dbo.cb_Contract sc ON b.ContractGUID = sc.ContractGUID
        WHERE   sc.BUGUID <> a.BUGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = sc.BUGUID
    FROM    ys_FileTypeControlDetail a
            INNER JOIN ys_ContractTypeFile b ON a.FileTypeControlDetailGUID = b.FileTypeControlDetailGUID
            INNER JOIN dbo.cb_Contract sc ON b.ContractGUID = sc.ContractGUID
    WHERE   sc.BUGUID <> a.BUGUID;

    PRINT '更新ys_FileTypeControlDetail表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_FileTypeControl表
    IF OBJECT_ID(N'ys_FileTypeControl_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_FileTypeControl_20250411_cost
        FROM    ys_FileTypeControl a
                INNER JOIN ys_FileTypeControlDetail b ON a.FileTypeControlGUID = b.FileTypeControlGUID
        WHERE   b.BUGUID <> a.BUGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = B.BUGUID
    FROM    ys_FileTypeControl a
            INNER JOIN ys_FileTypeControlDetail B ON a.FileTypeControlGUID = B.FileTypeControlGUID
    WHERE   B.BUGUID <> a.BUGUID;

    PRINT '更新ys_FileTypeControl表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_DimCost表
    IF OBJECT_ID(N'ys_fy_DimCost_bu_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_fy_DimCost_bu_20250411_cost
        FROM    ys_fy_DimCost a
                INNER JOIN ys_fy_DimDeptToCost B ON a.CostGUID = B.CostGUID AND a.BUGUID = B.BUGUID
                INNER JOIN #ys_SpecialBusinessUnit C ON B.DeptGUID = C.DeptGUID
        WHERE   a.BUGUID <> C.BUGUID;

    --修改
    UPDATE  a
    SET a.BUGUID = C.BUGUID
    FROM    ys_fy_DimCost a
            INNER JOIN ys_fy_DimDeptToCost B ON a.CostGUID = B.CostGUID AND a.BUGUID = B.BUGUID
            INNER JOIN #ys_SpecialBusinessUnit C ON B.DeptGUID = C.DeptGUID
    WHERE   a.BUGUID <> C.BUGUID;

    PRINT '更新ys_fy_DimCost表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'ys_fy_DimCost_cost_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_fy_DimCost_cost_20250411_cost
        FROM    ys_fy_DimCost a
                INNER JOIN ys_fy_DimDeptToCost b ON a.CostGUID = b.CostGUID
                INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
                INNER JOIN #ys_DeptCostMb mb ON mb.CostCode = ly.CostCode AND  mb.Year = ly.Year AND   a.buguid = mb.buguid
        WHERE   a.BUGUID <> ly.BUGUID;

    --修改
    UPDATE  a
    SET a.CostGUID = mb.CostGUID
    FROM    ys_fy_DimCost a
            INNER JOIN ys_fy_DimDeptToCost b ON a.CostGUID = b.CostGUID
            INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
            INNER JOIN #ys_DeptCostMb mb ON mb.CostCode = ly.CostCode AND  mb.Year = ly.Year AND   a.buguid = mb.buguid
    WHERE   a.BUGUID <> ly.buguid;

    PRINT '更新ys_fy_DimCost表COST：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_fy_DimDeptToCost表
    IF OBJECT_ID(N'ys_fy_DimDeptToCost_bu_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_fy_DimDeptToCost_bu_20250411_cost
        FROM    ys_fy_DimDeptToCost a
                INNER JOIN #ys_SpecialBusinessUnit C ON a.DeptGUID = C.DeptGUID
        WHERE   a.BUGUID <> C.BUGUID;

    --修改
    UPDATE  a
    SET a.BUGUID = C.BUGUID
    FROM    ys_fy_DimDeptToCost a
            INNER JOIN #ys_SpecialBusinessUnit C ON a.DeptGUID = C.DeptGUID
    WHERE   a.BUGUID <> C.BUGUID;

    PRINT '更新ys_fy_DimDeptToCost表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'ys_fy_DimDeptToCost_cost_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_fy_DimDeptToCost_cost_20250411_cost
        FROM    ys_fy_DimDeptToCost a
                INNER JOIN #ys_SpecialBusinessUnit C ON a.DeptGUID = C.DeptGUID
                INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
                INNER JOIN #ys_DeptCostMb mb ON mb.CostCode = ly.CostCode AND  mb.Year = ly.Year AND   mb.buguid = C.buguid;

    --修改
    UPDATE  a
    SET a.CostGUID = mb.CostGUID
    FROM    ys_fy_DimDeptToCost a
            INNER JOIN #ys_SpecialBusinessUnit C ON a.DeptGUID = C.DeptGUID
            INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
            INNER JOIN #ys_DeptCostMb mb ON mb.CostCode = ly.CostCode AND  mb.Year = ly.Year AND   C.buguid = mb.buguid;

    PRINT '更新ys_fy_DimDeptToCost表COST：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_OverAllPlan表
    IF OBJECT_ID(N'ys_OverAllPlan_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlan_20250411_cost
        FROM    ys_OverAllPlan a
                INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
                INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_OverAllPlan a
            INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
            INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    PRINT '更新ys_OverAllPlan表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_OverAllPlanHistory表
    IF OBJECT_ID(N'ys_OverAllPlanHistory_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlanHistory_20250411_cost
        FROM    ys_OverAllPlanHistory a
                INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
                INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_OverAllPlanHistory a
            INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
            INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    PRINT '更新ys_OverAllPlanHistory表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_OverAllPlanRateSet表
    IF OBJECT_ID(N'ys_OverAllPlanRateSet_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlanRateSet_20250411_cost
        FROM    ys_OverAllPlanRateSet a
                INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
                INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_OverAllPlanRateSet a
            INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
            INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    PRINT '更新ys_OverAllPlanRateSet表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_OverAllPlanWork表
    IF OBJECT_ID(N'ys_OverAllPlanWork_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlanWork_20250411_cost
        FROM    ys_OverAllPlanWork a
                INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
                INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_OverAllPlanWork a
            INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
            INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    PRINT '更新ys_OverAllPlanWork表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_Proceeding表
    IF OBJECT_ID(N'ys_Proceeding_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_Proceeding_20250411_cost
        FROM    ys_Proceeding a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_Proceeding a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID;

    PRINT '更新ys_Proceeding表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_YearPlanDept2Cost_IndexYear表
    IF OBJECT_ID(N'ys_YearPlanDept2Cost_IndexYear_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_YearPlanDept2Cost_IndexYear_20250411_cost
        FROM    ys_YearPlanDept2Cost_IndexYear a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    ys_YearPlanDept2Cost_IndexYear a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID;

    PRINT '更新ys_YearPlanDept2Cost_IndexYear表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_YearPlanPLSB表
    IF OBJECT_ID(N'ys_YearPlanPLSB_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_YearPlanPLSB_20250411_cost
        FROM    ys_YearPlanPLSB a
                INNER JOIN ys_YearPlanPLSBDtl B ON a.YearPlanPLSBGUID = B.YearPlanPLSBGUID
                INNER JOIN ys_SpecialBusinessUnit C ON C.SpecialUnitGUID = B.SpecialUnitGUID
        WHERE   a.BUGUID <> C.BUGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = C.BUGUID
    FROM    ys_YearPlanPLSB a
            INNER JOIN ys_YearPlanPLSBDtl B ON a.YearPlanPLSBGUID = B.YearPlanPLSBGUID
            INNER JOIN ys_SpecialBusinessUnit C ON C.SpecialUnitGUID = B.SpecialUnitGUID
    WHERE   a.BUGUID <> C.BUGUID;

    PRINT '更新ys_YearPlanDept2Cost_IndexYear表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_ExpenseAnalyseInfoSF表
    IF OBJECT_ID(N'fy_ExpenseAnalyseInfoSF_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_ExpenseAnalyseInfoSF_20250411_cost
        FROM    fy_ExpenseAnalyseInfoSF a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
                INNER JOIN #ys_DeptCostMb mb ON ly.CostCode = mb.CostCode AND  ly.Year = mb.Year AND   b.buguid = mb.buguid;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID ,
        a.CostGUID = mb.CostGUID
    FROM    fy_ExpenseAnalyseInfoSF a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
            INNER JOIN #ys_DeptCostMb mb ON ly.CostCode = mb.CostCode AND  ly.Year = mb.Year AND   b.buguid = mb.buguid;

    PRINT '更新fy_ExpenseAnalyseInfoSF表BUGUID&CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_ExpenseAnalyseInfoYFS表
    IF OBJECT_ID(N'fy_ExpenseAnalyseInfoYFS_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_ExpenseAnalyseInfoYFS_20250411_cost
        FROM    fy_ExpenseAnalyseInfoYFS a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
                INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
                INNER JOIN #ys_DeptCostMb mb ON ly.CostCode = mb.CostCode AND  ly.Year = mb.Year AND   b.buguid = mb.buguid;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID ,
        a.CostGUID = mb.CostGUID
    FROM    fy_ExpenseAnalyseInfoYFS a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.DeptGUID = b.DeptGUID
            INNER JOIN #ys_DeptCostLy ly ON a.CostGUID = ly.CostGUID
            INNER JOIN #ys_DeptCostMb mb ON ly.CostCode = mb.CostCode AND  ly.Year = mb.Year AND   mb.buguid = b.buguid;

    PRINT '更新fy_ExpenseAnalyseInfoYFS表BUGUID&CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_FeeTarget_Bu2ProjDtl表
    IF OBJECT_ID(N'fy_FeeTarget_Bu2ProjDtl_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_FeeTarget_Bu2ProjDtl_20250411_cost
        FROM    fy_FeeTarget_Bu2ProjDtl a
                INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
                INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    fy_FeeTarget_Bu2ProjDtl a
            INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
            INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    PRINT '更新fy_FeeTarget_Bu2ProjDtl表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_Proj_FeeTargetTotal表
    IF OBJECT_ID(N'fy_Proj_FeeTargetTotal_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_Proj_FeeTargetTotal_20250411_cost
        FROM    fy_Proj_FeeTargetTotal a
                INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
                INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    fy_Proj_FeeTargetTotal a
            INNER JOIN ys_SpecialBusinessUnit b ON a.ProjGUID = b.ProjGUID
            INNER JOIN #ys_SpecialBusinessUnit C ON b.SpecialUnitGUID = C.DeptGUID;

    PRINT '更新fy_Proj_FeeTargetTotal表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_SplitYearDeptMapping表
    IF OBJECT_ID(N'fy_SplitYearDeptMapping_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_SplitYearDeptMapping_20250411_cost
        FROM    fy_SplitYearDeptMapping a
                INNER JOIN #ys_SpecialBusinessUnit b ON a.CurrentDeptGUID = b.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    fy_SplitYearDeptMapping a
            INNER JOIN #ys_SpecialBusinessUnit b ON a.CurrentDeptGUID = b.DeptGUID;

    PRINT '更新fy_SplitYearDeptMapping表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_YearCarryOver表
    IF OBJECT_ID(N'fy_YearCarryOver_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_YearCarryOver_20250411_cost
        FROM    fy_YearCarryOver a
                INNER JOIN fy_YearCarryOverFtDetail c ON a.YearCarryOverGUID = c.YearCarryOverGUID
                INNER JOIN #ys_SpecialBusinessUnit b ON c.DeptGUID = b.DeptGUID;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    fy_YearCarryOver a
            INNER JOIN fy_YearCarryOverFtDetail c ON a.YearCarryOverGUID = c.YearCarryOverGUID
            INNER JOIN #ys_SpecialBusinessUnit b ON c.DeptGUID = b.DeptGUID;

    PRINT '更新fy_YearCarryOver表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份fy_SplitYearCostMapping表
    IF OBJECT_ID(N'fy_SplitYearCostMapping_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_SplitYearCostMapping_20250411_cost
        FROM    fy_SplitYearCostMapping a;

    INSERT INTO fy_SplitYearCostMapping
    SELECT  NEWID() SplitYearCostMappingGUID ,
            a.year CurrentYear ,
            a.deptcostguid CurrentCostGUID ,
            b.deptcostguid LastCostGUID ,
            a.buguid BUGUID
    FROM    ys_deptcost a
            INNER JOIN ys_deptcost b ON a.costcode = b.costcode AND a.year - 1 = b.year AND a.buguid = b.buguid
            LEFT JOIN fy_SplitYearCostMapping t ON t.CurrentCostGUID = a.deptcostguid
    WHERE   t.CurrentCostGUID IS NULL AND   a.buguid NOT IN(SELECT  buguid FROM fy_SplitYearCostMapping);

    PRINT '更新fy_SplitYearCostMapping表CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --补充 20220225， 增加预呈批部门数据刷新
    --备份fy_Apply 表
    IF OBJECT_ID(N'fy_Apply_20250411_dept', N'U') IS NULL
        SELECT  b.*
        INTO    fy_Apply_20250411_dept
        FROM    [dbo].[fy_Apply_FtDetail] a
                INNER JOIN fy_Apply b ON a.ApplyGUID = b.ApplyGUID
                INNER JOIN #ys_SpecialBusinessUnit c ON a.DeptGUID = c.DeptGUID;

    --修改 ：需手工选择公司下的某个部门，不能直接刷新为公司信息
    UPDATE  b
    SET b.deptguid = (SELECT    TOP 1  dep.BUGUID
                      FROM  dbo.myBusinessUnit dep
                      WHERE dep.CompanyGUID = c.buguid AND  iscompany = 0 AND   dep.ProjGUID IS NULL AND butype = 1) ,
        b.deptname = (SELECT    TOP 1  dep.BUName
                      FROM  dbo.myBusinessUnit dep
                      WHERE dep.CompanyGUID = c.buguid AND  iscompany = 0 AND   dep.projguid IS NULL AND butype = 1)
    FROM    [dbo].[fy_Apply_FtDetail] a
            INNER JOIN fy_Apply b ON a.ApplyGUID = b.ApplyGUID
            INNER JOIN #ys_SpecialBusinessUnit c ON a.DeptGUID = c.DeptGUID
            INNER JOIN mybusinessunit bu ON bu.buguid = c.BUGUID;

    PRINT '更新fy_Apply表部门信息：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --/////////////////////////  2025年组织架构调整 新增表 开始 ////////////////////////////////--------------
    --备份批量事项申请单表
    IF OBJECT_ID(N'fy_ItemApplyBatch_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    fy_ItemApplyBatch_20250411_cost
        FROM    dbo.fy_ItemApplyBatch a
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = a.DeptGUID
        WHERE   a.buguid <> bu.buguid

    --刷新跨年结转主表所属BUGUID
    UPDATE  a
       SET a.BUGUID = bu.BUGUID
        FROM    dbo.fy_ItemApplyBatch a
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = a.DeptGUID
        WHERE   a.buguid <> bu.buguid

    PRINT '刷新批量事项申请单表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- 备份ys_YearPlanLxSet
    IF OBJECT_ID(N'ys_YearPlanLxSet_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_YearPlanLxSet_20250411_cost
        FROM    ys_YearPlanLxSet a
                INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
        WHERE   a.BUGUID <> b.newbuguid;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.newBUGUID
    FROM    ys_YearPlanLxSet a
            INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
    WHERE   a.BUGUID <> b.newbuguid;

    PRINT '更新ys_YearPlanLxSet表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);



    -- ys_YearBudgetDept_Detail_History 部门年度预算历史明细表

    --备份部门年度预算历史明细表
    IF OBJECT_ID(N'ys_YearBudgetDept_Detail_History_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    ys_YearBudgetDept_Detail_History_20250411_cost
        FROM    dbo.ys_YearBudgetDept_Detail_History fdf
                INNER JOIN ys_YearBudgetDept_History fd on fdf.HistoryGUID =fd.HistoryGUID and fdf.Year =fd.Year
                inner join #ys_SpecialBusinessUnit sbu ON fd.BudgetDeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.DeptCostGUID = dcl.CostGUID and dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID

    -- 修改
    UPDATE  fdf
          SET fdf.DeptCostGUID = dcm.CostGUID,
              fdf.BUGUID = dcm.BUGUID
    FROM    dbo.ys_YearBudgetDept_Detail_History fdf
                INNER JOIN ys_YearBudgetDept_History fd on fdf.HistoryGUID =fd.HistoryGUID and fdf.Year =fd.Year
                inner join #ys_SpecialBusinessUnit sbu ON fd.BudgetDeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.DeptCostGUID = dcl.CostGUID and dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID
    PRINT '更新ys_YearBudgetDept_Detail_History表BUGUID和DeptCostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- ys_YearBudgetDept_History 部门年度预算历史表
    --备份部门年度预算历史表
    IF OBJECT_ID(N'ys_YearBudgetDept_History_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_YearBudgetDept_History_20250411_cost
        FROM    dbo.ys_YearBudgetDept_History a
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = a.BudgetDeptGUID
        WHERE   a.buguid <> bu.buguid

    --刷新
    UPDATE  a
       SET a.BUGUID = bu.BUGUID
        FROM    dbo.ys_YearBudgetDept_History a
                INNER JOIN #ys_SpecialBusinessUnit bu ON bu.DeptGUID = a.BudgetDeptGUID
        WHERE   a.buguid <> bu.buguid

    PRINT '刷新部门年度预算历史表的BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);



    -- ys_YearPlanDept2Cost_Working 部门年度预算编制表
     --备份部门年度预算编制表
    IF OBJECT_ID(N'ys_YearPlanDept2Cost_Working_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    ys_YearPlanDept2Cost_Working_20250411_cost
        FROM    dbo.ys_YearPlanDept2Cost_Working fdf
                inner join #ys_SpecialBusinessUnit sbu ON fdf.DeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID AND   dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID

    -- 修改
    UPDATE  fdf
          SET fdf.CostGUID = dcm.CostGUID,
              fdf.BUGUID = dcm.BUGUID
        FROM    dbo.ys_YearPlanDept2Cost_Working fdf
                inner join #ys_SpecialBusinessUnit sbu ON fdf.DeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID AND   dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID

    PRINT '更新部门年度预算编制表ys_YearPlanDept2Cost_Working表BUGUID和CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- ys_YearPlanProceeding2Cost_Working 部门年度预算编制表
    --备份部门年度预算编制表
    IF OBJECT_ID(N'ys_YearPlanProceeding2Cost_Working_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    ys_YearPlanProceeding2Cost_Working_20250411_cost
        FROM    dbo.ys_YearPlanProceeding2Cost_Working fdf
                inner join #ys_SpecialBusinessUnit sbu ON fdf.DeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID AND   dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID

    -- 修改
    UPDATE  fdf
          SET fdf.CostGUID = dcm.CostGUID,
              fdf.BUGUID = dcm.BUGUID
        FROM    dbo.ys_YearPlanProceeding2Cost_Working fdf
                inner join #ys_SpecialBusinessUnit sbu ON fdf.DeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID AND   dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID
        
    PRINT '更新部门年度预算编制表ys_YearPlanProceeding2Cost_Working表BUGUID和CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- ys_YearPlanDept2CostExt 费用科目扩展表
    --备份费用科目扩展表
    IF OBJECT_ID(N'ys_YearPlanDept2CostExt_20250411_cost', N'U') IS NULL
        SELECT  fdf.*
        INTO    ys_YearPlanDept2CostExt_20250411_cost
        FROM    dbo.ys_YearPlanDept2CostExt fdf
                inner join #ys_SpecialBusinessUnit sbu ON fdf.DeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID AND   dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID

    -- 修改
        UPDATE  fdf
          SET fdf.CostGUID = dcm.CostGUID,
              fdf.BUGUID = dcm.BUGUID
        FROM    dbo.ys_YearPlanDept2CostExt fdf
                inner join #ys_SpecialBusinessUnit sbu ON fdf.DeptGUID = sbu.DeptGUID
                INNER JOIN #ys_DeptCostLy dcl ON fdf.CostGUID = dcl.CostGUID AND   dcl.Year = fdf.Year
                INNER JOIN #ys_DeptCostMb dcm ON dcm.CostCode = dcl.CostCode AND   dcm.buguid = sbu.buguid AND dcm.Year = dcl.Year
        where   fdf.BUGUID <> sbu.BUGUID
        
    PRINT '更新费用科目扩展表ys_YearPlanDept2CostExt表BUGUID和CostGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);



    -- fy_AgencyFeeSettle 佣金报告单
    IF OBJECT_ID(N'fy_AgencyFeeSettle_20250411', N'U') IS NULL
    BEGIN
        SELECT a.*
        INTO fy_AgencyFeeSettle_20250411
        FROM fy_AgencyFeeSettle a
        INNER JOIN (
            SELECT DISTINCT NewBuguid, OldBuguid, NewBUName, OldBUName
            FROM #dqy_proj
        ) p ON a.BUGUID = p.OldBuguid
        WHERE p.NewBuguid <> a.buguid;
    END;

    UPDATE a
    SET a.BuGUID = p.NewBuguid,
        a.BuName = p.NewBUName
    FROM fy_AgencyFeeSettle a
    INNER JOIN (
        SELECT DISTINCT NewBuguid, OldBuguid, NewBUName, OldBUName
        FROM #dqy_proj
    ) p ON a.BUGUID = p.OldBuguid
    WHERE p.NewBuguid <> a.buguid;

    PRINT '更新佣金报告单fy_AgencyFeeSettle表的BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


    --/////////////////////////  2025年组织架构调整 新增表 结束 ////////////////////////////////--------------
    DROP TABLE #BizGUID ,
               #cb_Contract ,
               #cb_HTAlter ,
               #cb_HTBalance ,
               #dqy_proj ,
               #mbProj ,
               #YearCarryOverGUID ,
               #ys_DeptCostLy ,
               #ys_DeptCostMb ,
               #ys_SpecialBusinessUnit
END;

/*
BEGIN
    --只处理全周期的营销费用预算
    --获取待迁移的信息
    --只处理全周期的营销费用预算
    --获取待迁移的信息
    SELECT  * INTO  #dqy_proj FROM  dbo.dqy_proj_20250411;

    --备份ys_OverAllPlan表
    IF OBJECT_ID(N'ys_OverAllPlan_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlan_20250411_cost
        FROM    ys_OverAllPlan a
                INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
        WHERE   a.BUGUID <> b.newbuguid;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.newBUGUID
    FROM    ys_OverAllPlan a
            INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
    WHERE   a.BUGUID <> b.newbuguid;

    PRINT '更新ys_OverAllPlan表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_OverAllPlanHistory表
    IF OBJECT_ID(N'ys_OverAllPlanHistory_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlanHistory_20250411_cost
        FROM    ys_OverAllPlanHistory a
                INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
        WHERE   a.BUGUID <> b.newbuguid;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.newBUGUID
    FROM    ys_OverAllPlanHistory a
            INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
    WHERE   a.BUGUID <> b.newbuguid;

    PRINT '更新ys_OverAllPlanHistory表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_OverAllPlanRateSet表
    IF OBJECT_ID(N'ys_OverAllPlanRateSet_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlanRateSet_20250411_cost
        FROM    ys_OverAllPlanRateSet a
                INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
        WHERE   a.BUGUID <> b.newbuguid;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.newBUGUID
    FROM    ys_OverAllPlanRateSet a
            INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
    WHERE   a.BUGUID <> b.newbuguid;

    PRINT '更新ys_OverAllPlanRateSet表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --备份ys_OverAllPlanWork表
    IF OBJECT_ID(N'ys_OverAllPlanWork_20250411_cost', N'U') IS NULL
        SELECT  a.*
        INTO    ys_OverAllPlanWork_20250411_cost
        FROM    ys_OverAllPlanWork a
                INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
        WHERE   a.BUGUID <> b.newbuguid;

    --修改 
    UPDATE  a
    SET a.BUGUID = b.newBUGUID
    FROM    ys_OverAllPlanWork a
            INNER JOIN #dqy_proj b ON b.oldprojguid = a.ProjGUID
    WHERE   a.BUGUID <> b.newbuguid;

    PRINT '更新ys_OverAllPlanWork表BUGUID：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
END;
*/

/*

select bu.BUName,bu.BUGUID,count(1) 
from fy_ItemApply_FtDetail a
inner join  ys_DeptCost dcl on a.CostGUID =dcl.DeptCostGUID --and  a.FtYear =dcl.Year
inner join  ys_SpecialBusinessUnit spb on a.DeptGUID =spb.SpecialUnitGUID
inner join  ys_DeptCost mdl on mdl.CostCode =dcl.CostCode and  dcl.Year =mdl.Year and  mdl.BUGUID =spb.BUGUID
inner join [myBusinessUnit] bu on bu.BUGUID =dcl.BUGUID
where dcl.BUGUID <> mdl.BUGUID 
and dcl.BUGUID in (
'289A694A-E5D1-4F02-BFEF-8510E4B6C6A0',
'A8E2ACA1-508E-46F3-B764-8E2114255B4B',
'CEBF9C18-CF48-49FD-B490-A86E3D9F10D4',
'31120F08-22C4-4220-8ED2-DCAD398C823C',
'4674A41A-81C3-4A20-8B5C-E52319022195'
)
group by bu.BUName,bu.BUGUID

update  a
   set  a.CostGUID=mdl.DeptCostGUID
from fy_ItemApply_FtDetail a
inner join  ys_DeptCost dcl on a.CostGUID =dcl.DeptCostGUID --and  a.FtYear =dcl.Year
inner join  ys_SpecialBusinessUnit spb on a.DeptGUID =spb.SpecialUnitGUID
inner join  ys_DeptCost mdl on mdl.CostCode =dcl.CostCode and  dcl.Year =mdl.Year and  mdl.BUGUID =spb.BUGUID
inner join [myBusinessUnit] bu on bu.BUGUID =dcl.BUGUID
where dcl.BUGUID <> mdl.BUGUID 
and dcl.BUGUID in (
'289A694A-E5D1-4F02-BFEF-8510E4B6C6A0',
'A8E2ACA1-508E-46F3-B764-8E2114255B4B',
'CEBF9C18-CF48-49FD-B490-A86E3D9F10D4',
'31120F08-22C4-4220-8ED2-DCAD398C823C',
'4674A41A-81C3-4A20-8B5C-E52319022195'
)

*/