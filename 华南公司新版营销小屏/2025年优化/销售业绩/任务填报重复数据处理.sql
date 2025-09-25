-- 备份表
select  * into  data_tb_hnyx_jdfxtb_bak20250908 from  data_tb_hnyx_jdfxtb
-- 删除刘龙德填报的业绩数据
delete  from  data_tb_hnyx_jdfxtb  
where  _ExcelGUID = '6D6A583A-0D2E-EF11-9C29-005056BD8A74'


select  * from mdc_CollectUserData_Excel where  ExcelGUID in (
select  _ExcelGUID from  data_tb_hnyx_jdfxtb group by  _ExcelGUID )



SELECT
    Contract2CgProcGUID,
    ContractGUID,
    BUGUID,
    HtTypeCode,
    HtKind,
    ContractCode,
    ContractName,
    HtClass,
    SignMode,
    CostProperty,
    DeptGUID,
    Jbr,
    SignDate,
    JfCorporation,
    YfCorporation,
    BfCorporation,
    HtProperty,
    IfDdhs,
    MasterContractGUID,
    TotalAmount,
    BjcbAmount,
    ItemAmount,
    HtAmount,
    ItemDtAmount,
    HtycAmount,
    JsState,
    ZjsAmount,
    JsAmount,
    JsBxAmount,
    JsOtherDeduct,
    JsItemDeduct,
    LocaleAlterAmount,
    DesignAlterAmount,
    OtherAlterAmount,
    BalanceAdjustAmount,
    SumALterAmount,
    SumYfAmount,
    SumScheduleAmount,
    SumFactAmount,
    ConfirmJhfkAmount,
    IfConfirmFkPlan,
    SumPayAmount,
    LandSource,
    LandUseLimit,
    BuildArea,
    LandProperty,
    LandUse,
    LandRemarks,
    BeginDate,
    EndDate,
    WorkPeriod,
    BxAmount,
    BxLimit,
    PerformBail,
    PerformRemarks,
    TechnicRemarks,
    RewardRemarks,
    BreachRemarks,
    TermRemarks,
    ApproveState,
    ApproveDate,
    ApprovedBy,
    CfMode,
    YcfAmount,
    HtCfState,
    AlterCfState,
    FactCfAmount,
    FactCfState,
    PayCfState,
    ItemCfAmount,
    ItemCfState,
    HtycCfAmount,
    HtycCfState,
    FinanceHsxmCode,
    FinanceHsxmName,
    ApproveLog,
    ProcessStatusContract,
    TacticProtocolGUID,
    CgPlanGUID,
    zlbs,
    JfProviderGUID,
    YfProviderGUID,
    BfProviderGUID,
    IsJtContract,
    Bz,
    Rate,
    SumScheduleAmount_Bz,
    SumPayAmount_Bz,
    SumAlterAmount_Bz,
    SumYfAmount_Bz,
    JsAmount_Bz,
    ZjsAmount_Bz,
    HtAmount_Bz,
    JsOtherDeduct_Bz,
    JbrGUID,
    ProjType,
    JfProviderName,
    YfProviderName,
    BfProviderName,
    ContractCodeFormat,
    UseStockInfo,
    ApproveStateFlag,
    HtCfStateShow,
    UseCostInfo,
    UseCostColor,
    IsLock,
    HtTypeName,
    HtTypeGUID,
    JbDeptName,
    JbDeptCode,
    MasterContractCode,
    MasterContractName,
    BUName,
    CgPlanName,
    TacticProtocolname,
    CurrencyName,
    ProjCode,
    ProjectCode,
    ProjName,
    SchedulePayRate,
    ProjectPlanAffect,
    HsCfState,
    DeptUseInfo,
    ContractBound,
    PayMode,
    QualityRequest,
    BXAssumpsit,
    '' as BM,
    'HT' as ContractType,
    '合同登记' as DocType,
    '' as ProjGUIDList,
    dbo.fn_GetContractProj(ContractGUID, 'ProjName') as ProjectNameList,
    ProjCode as ProjectCodeList,
    isUseYgAmount,
    IsFyControl,
    InputTaxAmount,
    InputTaxAmount_Bz,
    ExcludingTaxHtAmount,
    ExcludingTaxHtAmount_Bz,
    AverageTaxRate,
    JfProvider2GUID,
    JfProvider2Name,
    JfProvider3GUID,
    JfProvider3Name,
    YfProvider2GUID,
    YfProvider2Name,
    YfProvider3GUID,
    YfProvider3Name,
    BfProvider2GUID,
    BfProvider2Name,
    BfProvider3GUID,
    BfProvider3Name,
    Jf2Corporation,
    Yf2Corporation,
    Bf2Corporation,
    Jf3Corporation,
    Yf3Corporation,
    Bf3Corporation,
    HtYxq,
    DjDate,
    JsMode,
    DesignPhase,
    isJs,
    isIfZsq,
    isIfJzcg,
    VouchType,
    CollectionType,
    JzcgType,
    BldNameList,
    BldGUIDList,
    isHTAlter,
    HTAlterGUIDList,
    HTAlterNameList,
    HTAlterAmount,
    bgxs,
    IsConstructionBalance,
    JbrNew,
    PreContractGUID,
    PreContractName,
    BudgetLibraryGUID,
    BudgetLibraryName,
    bzHTMBGUID,
    bzHTMBName,
    STUFF(
        (
            select
                ',' + convert(varchar(50), ProcessGUID)
            from
                cb_HtZlApprove a
                INNER JOIN myWorkflowProcessEntity b ON a.HtZlApproveGUID = b.BusinessGUID
            where
                ISNULL(b.IsHistory, 0) = 0
                AND ProcessStatus in (0, 1, 2)
                AND a.ContractGUID = vcb_Contract.ContractGUID FOR XML PATH('')
        ),
        1,
        1,
        ''
    ) as YjsGUIDList,
    isnull(
        (
            select
                UseCostInfo
            from
                cb_Contract
            where
                ContractGUID = vcb_Contract.MasterContractGUID
        ),
        ''
    ) as MasterUseCostInfo,
    LwProviderGUID,
    LwProviderName,
    '' as LwCorporation,
    ContractUpArea,
    ContractDownArea,
    InvoiceBuyerGUID,
    InvoiceBuyer,
    InvoiceSellerGUID,
    InvoiceSeller,
    IsDfdk,
    DesignScope,
    STUFF(
        (
            SELECT
                ';' + CAST(wp.ProcessGUID AS VARCHAR(36))
            FROM
                cb_Contract2Wf wf
                INNER JOIN myWorkflowProcessEntity wp ON wf.CwfGUID = wp.BusinessGUID
            WHERE
                wf.ContractGUID = vcb_Contract.ContractGUID
            ORDER BY
                wf.CreateDate Desc FOR xml path('')
        ),
        1,
        1,
        ''
    ) AS ContractWFGUID,
    STUFF(
        (
            SELECT
                ';' + CAST(wp.ProcessName AS VARCHAR(36))
            FROM
                cb_Contract2Wf wf
                INNER JOIN myWorkflowProcessEntity wp ON wf.CwfGUID = wp.BusinessGUID
            WHERE
                wf.ContractGUID = vcb_Contract.ContractGUID
            ORDER BY
                wf.CreateDate Desc FOR xml path('')
        ),
        1,
        1,
        ''
    ) AS ContractWFName,
    TacticCgAgreementGUIDList,
    City,
    CityCode,
    IsCollectionMaterial,
    DecorationGrade,
    CivilConstructionGrade,
    TacticCgAgreementNameList,
    'HtEdit' as PageInlet,
    NewHtClass,
    IsAllowPlaceOrder,
    IsAllowDocuments,
    IsSupplyAndInstallation,
    Provider2ServiceGUID,
    (
        select
            top 1 ProductTypeShortName
        from
            p_Provider2Service b
            inner join p_ProductType a on a.ProductTypeCode = b.ProductTypeCode
        where
            Provider2ServiceGUID = vcb_Contract.Provider2ServiceGUID
    ) as Provider2ServiceName,
    BidGUID,
    BidName,
    IsTjZbHt,
    DirectEntrustment,
    DirectEntrustmentContent,
    STUFF(
        (
            SELECT
                ';' + isnull(mp.SpreadName, pp.ProjName) + '-' + p.ProjShortName
            from
                cb_ContractProj cp with(nolock)
                join p_Project p with(nolock) on cp.ProjGUID = p.ProjGUID
                join p_Project pp with(nolock) on p.ParentCode = pp.ProjCode
                left join md_Project mp with(nolock) on pp.ProjGUID = mp.ProjGUID
                and mp.IsActive = 1
            where
                ContractGUID = vcb_Contract.ContractGUID
            order by
                cp.contractProjGUID desc FOR xml path('')
        ),
        1,
        1,
        ''
    ) mdSpreadName,
    ZzgJsdCode,
    ZzgHTBalanceGUID,
    FpcJsdCode,
    FpcHTBalanceGUID,
    isnull(IsJgBaNewContract, 0) as IsJgBaNewContract,
    IsEAContract,
    IsZzgbx,
    isnull(IsCompleteZzg, '未暂转固') as IsCompleteZzg,
    ZzgAmount,
    CurrZzgCfAmount
FROM
    vcb_Contract
WHERE
    (1 = 1)