SELECT 平台公司, ProjGUID, 投管代码, 项目名, 推广名
INTO #p
FROM erp25.[dbo].[vmdm_projectFlagnew]
WHERE 投管代码 IN (
    '3638', 
    '7404', 
    '3637', 
    '3634', 
    '268', 
    '263', 
    '266', 
    '261', 
    '3328', 
    '2436', 
    '2435', 
    '5322', 
    '5318', 
    '5409', 
    '5410', 
    '1990042', 
    '1990049', 
    '1990040', 
    '1990044', 
    '1990047', 
    '1990032', 
    '177', 
    '1990026', 
    '1990034',
    '4220', 
    '4216', 
    '2519', 
    '6220', 
    '2513', 
    '3925', 
    '3924', 
    '3923', 
    '3919', 
    '3825', 
    '3812', 
    '445', 
    '427', 
    '728', 
    '727', 
    '724', 
    '725', 
    '2987', 
    '2988', 
    '2985', 
    '2989', 
    '2983', 
    '2984', 
    '2981', 
    '2979', 
    '2971', 
    '2976', 
    '7216', 
    '7213', 
    '7215', 
    '1856', 
    '1855', 
    '1854', 
    '1431', 
    '1417', 
    '1423', 
    '3324', 
    '625', 
    '630', 
    '8508', 
    '1644', 
    '1640', 
    '4924', 
    '4923', 
    '4912', 
    '4917', 
    '4922', 
    '4017', 
    '4024', 
    '4016', 
    '4020', 
    '354', 
    '348', 
    '345', 
    '327', 
    '1286', 
    '1282', 
    '1284', 
    '1283', 
    '1276', 
    '1268', 
    '8606', 
    '8610', 
    '8612', 
    '8213', 
    '8611', 
    '1532', 
    '1526', 
    '3146', 
    '5708', 
    '4112', 
    '2706', 
    '4111', 
    '4105', 
    '2010', 
    '9309', 
    '11502', 
    '1129', 
    '1127', 
    '2810', 
    '2809', 
    '2811', 
    '8711', 
    '8904', 
    '538', 
    '532', 
    '10501'
)

SELECT  p.平台公司, p.投管代码, 项目名, 推广名, t1.projguid,  
        SUM(t.TotalOccurredAmount) 整盘累计已发生费用,
        SUM(t.PlanAmount) AS 执行营销费用金额
-- INTO #fy_ys
FROM MyCost_Erp352.dbo.ys_OverAllPlanDtlWork t
INNER JOIN MyCost_Erp352.dbo.ys_OverAllPlanWork t1 ON t.OverAllPlanGUID=t1.OverAllPlanGUID
INNER JOIN #p p ON p.ProjGUID =t1.ProjGUID
WHERE   t.PlanDate = 0 AND t.CostCode = 'C.01'
GROUP BY  p.平台公司, p.投管代码, 项目名, 推广名, t1.projguid 


SELECT TOP 99 
    DjDate, 
    ProjectName, 
    vcb_ContractGrid.ContractGUID, 
    vcb_ContractGrid.HtTypeCode, 
    vcb_ContractGrid.BUGUID, 
    IsJtContract, 
    ApproveState, 
    ProjType, 
    isUseYgAmount, 
    ApproveStateFlag, 
    JsState, 
    MasterContractGUID, 
    IfDdhs, 
    HtCfStateShow, 
    CfMode, 
    HtClass, 
    ContractCode, 
    ContractName, 
    HtAmount, 
    SignDate, 
    YfProviderName, 
    YfCorporation, 
    jbrGUID, 
    ProcessGUID, 
    IsLock, 
    CurrencyName, 
    HtAmount_Bz, 
    bgxs, 
    SignMode, 
    IsUseCostInfo, 
    ShowDfdk, 
    IsDfdk, 
    ShowLock, 
    HtProperty, 
    ProjectCode, 
    IsHistoryClHt, 
    ShowIsHistoryClHt, 
    ShowIsAllowPlaceOrder, 
    vcb_ContractGrid.IsSupplyAndInstallation, 
    vcb_ContractGrid.IsAllowPlaceOrder, 
    vcb_ContractGrid.HtTypeName, 
    vcb_ContractGrid.EconomyIndexState, 
    vcb_ContractGrid.zlbs
FROM vcb_ContractGrid_New AS vcb_ContractGrid
LEFT JOIN myWorkflowProcessEntity b ON vcb_ContractGrid.ContractGUID = b.BusinessGUID
AND ISNULL(b.IsHistory, 0) = 0
AND (
    b.BusinessType = '合同审批' 
    OR b.BusinessType = '非合同审批' 
    OR b.BusinessType = '非单独执行合同审批' 
    OR b.BusinessType = '统签合同审批'
)
WHERE (
    (
        (
            (
                ContractCode LIKE N'%长春市绿园区富民大街地块合%'
            ) AND (
                JbDeptCode = 'zb.0048' 
                OR JbDeptCode LIKE 'zb.0048.%'
            )
        ) AND (
            contractGUID IN (
                SELECT contractguid 
                FROM vcb_ContractProj 
                WHERE ProjCode = '0048.0431024.001' 
                OR ProjCode LIKE '0048.0431024.001.%'
            )
        )
    ) AND (1 = N'1')
) AND vcb_ContractGrid.BUGUID = '528ca87c-f7af-4fdd-bd05-79641d9f67fb' 
AND IsFyControl = 0
ORDER BY vcb_ContractGrid.ContractCode DESC, vcb_ContractGrid.ContractGUID