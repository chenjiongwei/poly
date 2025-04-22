SELECT 
    FinancialInfoGUID, 
    p_DevelopmentCompany_FinancialInfo.DevelopmentCompanyGUID, 
    FundApprovalAuthority, 
    FundManagementIntensity, 
    Seal1, 
    Seal2, 
    OnlineBanking1, 
    OnlineBanking2, 
    AccountingEntity, 
    CheckApprove, 
    PushOrderModel, 
    BusinessSystemUser_CDJZT, 
    BusinessSystemUser_YXLFY, 
    BusinessSystemUser_GLLFY, 
    ISNULL(ApproveStatus, '未审核') AS ApproveStatus, 
    ApproveDate, 
    Approver, 
    ApproverGUID, 
    Editer, 
    EditerGUID, 
    EditDate, 
    SubmitApproveDate, 
    NULL AS DevelopmentCompanyCode, 
    NULL AS DevelopmentCompanyName, 
    NULL AS ParentCompanyName, 
    NULL AS docName, 
    p_DevelopmentCompany.IsOurTable, 
    p_DevelopmentCompany.AndTable, 
    p_DevelopmentCompany.AndTableGUID, 
    FinancialCompanyGUID, 
    FinancialCompany, 
    IsWhollyOwned, 
    p_DevelopmentCompany.BLShareRate, 
    bwb, 
    iscp, 
    isgtgs, 
    isbddtzgs, 
    dc.DevelopmentCompanyName AS blzjhztxsjzzName, 
    dca.DevelopmentCompanyName AS blcwbbtxsjzzName, 
    blzjhztxsjzz, 
    blcwbbtxsjzz, 
    ywqcqj, 
    p_DevelopmentCompany.ParentCompanyGUID
FROM 
    p_DevelopmentCompany_FinancialInfo
LEFT JOIN 
    p_DevelopmentCompany ON p_DevelopmentCompany.DevelopmentCompanyGUID = p_DevelopmentCompany_FinancialInfo.DevelopmentCompanyGUID
LEFT JOIN 
    p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = blzjhztxsjzz
LEFT JOIN 
    p_DevelopmentCompany dca ON dca.DevelopmentCompanyGUID = blcwbbtxsjzz
WHERE 
    (1=1) AND (2=2) 