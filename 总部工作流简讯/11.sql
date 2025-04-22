SELECT 
    [InvoiceGUID],
    [SourceGUID],
    [imageId],
    [invoiceId],
    [billCode],
    [billEntityCode],
    [scanUserId],
    [scanUserName],
    [scanTime],
    [commitStatus],
    [ticketCode],
    InvoiceType = CASE 
                        WHEN [invoiceType] = 'c' THEN '增值税普通发票'
                        WHEN [invoiceType] = 's' THEN '增值税专用发票'
                        WHEN [invoiceType] = 'se' THEN '增值税电子专用发票'
                        WHEN [invoiceType] = 'ce' THEN '增值税电子普通发票'
                        WHEN [invoiceType] = 'qc' THEN '全电增值税电子普通发票'
                        WHEN [invoiceType] = 'qs' THEN '全电增值税电子专用发票'
                        WHEN [invoiceType] = 'cz' THEN '全电增值税纸质普通发票'
                        WHEN [invoiceType] = 'sz' THEN '全电增值税纸质专用发票'
                        ELSE '增值税普通发票'
                    END,
    [checkStatus],
    [checkRemark],
    [invoiceStatus],
    [invoiceNo],
    [invoiceCode],
    [buyerName],
    [buyerTaxNo],
    [buyerAddrTel],
    [buyerAddress],
    [buyerTel],
    [buyerBankInfo],
    [buyerBankName],
    [buyerBankAccount],
    [sellerName],
    [sellerTaxNo],
    [sellerAddrTel],
    [sellerAddress],
    [sellerTel],
    [sellerBankInfo],
    [sellerBankName],
    [sellerBankAccount],
    [paperDrewDate],
    [checkCode],
    [invoiceSheet],
    [specialInvoiceFlag],
    [isReplace],
    [replaceTaxNo],
    [replaceCompanyName],
    [machineCode],
    [cipherText],
    [taxRate],
    [taxAmount],
    [amountWithTax],
    [amountWithoutTax],
    [cashierName],
    [checkerName],
    [invoicerName],
    [remark],
    [sourceFileUrl],
    [imageUrl],
    [sourceImageUrl],
    [imageFileUrl],
    [CreateTime]
FROM 
    [dbo].[fy_Invoice]



   SELECT TOP 1 
    ContractCode, 
    cht.HtTypeCode, 
    ProjectCode, 
    cht.HtTypeName, 
    BudgetInfo AS UseCostInfo, 
    StockInfo AS UseStockInfo, 
    HTFKApplyGUID, 
    vcb_HTFKApply.ContractGUID, 
    vcb_HTFKApply.ContractName, 
    vcb_HTFKApply.HTFKPlanGUID, 
    AppliedBy, 
    ApplyBUGUID, 
    vcb_HTFKApply.BUGUID, 
    PayProviderName, 
    ReceiveProviderName, 
    DfdkAmount, 
    YfAmount, 
    RemainAmount, 
    CurrencyGUID, 
    ApplyState, 
    ApplyClass, 
    BankName, 
    BankAccounts, 
    BudgetColor, 
    BudgetInfo, 
    StockInfo, 
    ApplyCodeFormat, 
    ApplyRateInfo, 
    ApplyRateColor, 
    Subject, 
    ApplyCode, 
    PayProviderGUID, 
    ApplyTypeGUID, 
    ApplyTypeName, 
    ApplyType, 
    ReceiveProviderGUID, 
    ApplyAmount_Bz, 
    vcb_HTFKApply.FundType, 
    vcb_HTFKApply.FundName, 
    DfdkAmount_Bz, 
    vcb_HTFKApply.YfAmount_Bz, 
    PayState, 
    CurrencyName, 
    vcb_HTFKApply.Rate, 
    vcb_HTFKApply.ApplyAmount, 
    AppliedByName, 
    ApplyDeptName, 
    sumljamount, 
    CASE 
        WHEN ApplyState = '审核中' OR ApplyState = '已审核' THEN ApplyDate 
        ELSE CONVERT(VARCHAR(10), GETDATE(), 120) 
    END AS ApplyDate, 
    ApplyRemarks, 
    ProjType, 
    CASE 
        WHEN RIGHT(Htclass, 3) = '非合同' THEN '非合同付款类型' 
        ELSE '合同付款类型' 
    END AS FKSPClass, 
    BalanceAmount_Bz, 
    BalanceAmount, 
    ZjPlanControl, 
    dbo.fn_ys_GetDeptUseInfo(vcb_HTFKApply.ContractGUID, HTFKApplyGUID) AS DeptUseInfo, 
    IsFyControl, 
    ISNULL(( 
        SELECT CAST(exe.ExecutionGUID AS VARCHAR(40)) + ',' 
        FROM ys_fy_HTFKApply_Execution appexe 
        INNER JOIN ys_fy_ExecutionInfo exe ON appexe.ExecutionGUID = exe.ExecutionGUID 
        WHERE appexe.HTFKApplyGUID = vcb_HTFKApply.HTFKApplyGUID 
        FOR XML PATH('')
    ), '') AS ExecutionGUIDList, 
    ISNULL(( 
        SELECT exe.ExecutionName + ';' 
        FROM ys_fy_HTFKApply_Execution appexe 
        INNER JOIN ys_fy_ExecutionInfo exe ON appexe.ExecutionGUID = exe.ExecutionGUID 
        WHERE appexe.HTFKApplyGUID = vcb_HTFKApply.HTFKApplyGUID 
        FOR XML PATH('')
    ), '') AS ExecutionNameList, 
    Month(ApplyDate) AS ApplyMonth, 
    Year(ApplyDate) AS ApplyYear, 
    vcb_HTFKApply.ExecProgress, 
    vcb_HTFKApply.PayBasis, 
    (SELECT VouchType FROM cb_Contract WHERE ContractGUID = vcb_HTFKApply.ContractGUID) AS VouchType, 
    (SELECT CollectionType FROM cb_Contract WHERE ContractGUID = vcb_HTFKApply.ContractGUID) AS CollectionType, 
    vcb_HTFKApply.PayBankName, 
    vcb_HTFKApply.PayBankAccount, 
    vcb_HTFKApply.Contract_TotalAmount as TotalAmount, 
    vcb_HTFKApply.FtBeginDate, 
    vcb_HTFKApply.FtPeriod, 
    vcb_HTFKApply.FtPeriod, 
    CASE 
        WHEN ApplyState <> '已审核' THEN 0 
        ELSE vcb_HTFKApply.ApplyAmount 
    END AS ApplyStateAmount, 
    SameFtPeriod, 
    vcb_HTFKApply.EnterpriseName, 
    vcb_HTFKApply.EnterprisePerson, 
    vcb_HTFKApply.EnterpriseTelephone, 
    vcb_HTFKApply.CooperateProj, 
    vcb_HTFKApply.CooperateDate, 
    vcb_HTFKApply.CooperateContent, 
    vcb_HTFKApply.CooperateAmount, 
    vcb_HTFKApply.Goodness, 
    vcb_HTFKApply.Quality, 
    vcb_HTFKApply.Profession, 
    vcb_HTFKApply.Performance, 
    vcb_HTFKApply.AfterService, 
    vcb_HTFKApply.TotalScore, 
    vcb_HTFKApply.Comment, 
    vcb_HTFKApply.CommentPerson, 
    vcb_HTFKApply.CommentDate, 
    0.00 as SumApplyAmount_Bz, 
    b.AgencyfeeSettleName, 
    d.ThirdOrderNo, 
    IsPushPyt, 
    PytStatus, 
    commitStatus, 
    IsGenerateYfd, 
    IsExistsInvoice, 
    IsBlInvoice, 
    isnull(IsInvoiceAmountlessFyAmount,1) as IsInvoiceAmountlessFyAmount, 
    InvoiceAmount, 
    '详情链接' as link, 
    BlIsCommit, 
    d.ApplyAmount AS Yfkje, 
    d.PrepayAmount AS Bcsqyfje, 
    d.PrepayDeductionAmount AS Bcyfdkje, 
    0 AS Dqyfje, 
    0 AS Bcsqhyfje, 
    vcb_HTFKApply.HtGenera, 
    vcb_HTFKApply.BudgetLibraryName, 
    vcb_HTFKApply.IsYxfHistory, 
    CASE 
        WHEN (SELECT COUNT(1) FROM cb_ContractProj b1 
              INNER JOIN dbo.vcb_Contract cc ON cc.ContractGUID = b1.ContractGUID 
              INNER JOIN p_Project c1 ON c1.ProjGUID = b1.ProjGUID 
              LEFT JOIN p_Project d1 ON c1.ParentCode = d1.ProjCode AND c1.BUGUID = d1.BUGUID 
              WHERE b1.ContractGUID = vcb_HTFKApply.ContractGUID 
              AND EXISTS(SELECT TOP 1 a2.ProjGUID FROM fy_AgencyContractSet a2 
                         WHERE (a2.ProjGUID = b1.ProjGUID OR a2.ProjGUID = d1.ProjGUID) 
                         AND a2.HTType = cc.BudgetLibraryName 
                         AND ISNULL(a2.TbdlfgzSet,1) = 0)) > 0 THEN '1' 
        ELSE '0' 
    END AS CommissionModel, 
    vcb_HTFKApply.DeductionAmount, 
    isnull(vcb_HTFKApply.IsDeduction,0) as IsDeduction, 
    vcb_HTFKApply.ExerciseBeginDate, 
    vcb_HTFKApply.ExerciseEndDate, 
    vcb_HTFKApply.IsMallPurchase 
   FROM vcb_HTFKApply 
   LEFT JOIN cb_HtType cht ON cht.HtTypeCode = vcb_HTFKApply.HtTypeCode 
   LEFT JOIN cb_HTFKPlan b ON vcb_HTFKApply.HTFKPlanGUID=b.HTFKPlanGUID 
   LEFT JOIN fy_AgencyFeeSettle d ON d.AgencyFeeSettleGUID = b.AgencyFeeSettleGUID 
   WHERE (1=1) AND (2=2) 