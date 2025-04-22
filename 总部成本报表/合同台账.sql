
-- 成本系统合同台账报表
-- 2025-4-15 chenjw 新增【是否标准合同】字段

DECLARE @var_buguid varchar(50) = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 

SELECT  
    con.ContractGUID,
    mypr.BusinessGUID,
    CONVERT(XML, mypr.BT_DomainXML) data
INTO  #con
FROM  cb_Contract con WITH (NOLOCK)
INNER JOIN  myWorkflowProcessEntity mypr WITH (NOLOCK)  ON mypr.BusinessGUID = con.ContractGUID AND mypr.ProcessStatus = '2'
WHERE  con.buguid in (@var_buguid)


SELECT 
       ContractGUID,
       m.c.value('@name', 'varchar(max)') AS 属性 ,
       m.c.value('.', 'nvarchar(max)') AS Value
INTO #value
FROM   #con AS s
       OUTER APPLY s.data.nodes('BusinessType/Item/Domain') AS m(c)
WHERE  m.c.value('@name', 'varchar(max)') IN ( '是否标准合同','是否使用标准合同模板')

SELECT 
    ROW_NUMBER() OVER (ORDER BY a.ContractCode DESC) AS RowNum,
    a.JsState AS '结算状态',
    a.ApproveState AS '审核状态',
    a.ContractCode AS '合同编号',
    a.ContractName AS '合同名称',
    a.ProjName AS '所属项目',
    v.Value as '是否标准合同',
    mp.ProjCode 明源系统代码,
    lb.LbProjectValue 投管代码,
    cb_Currency.CurrencyName AS '币种',
    a.HtAmount AS '有效签约金额',
    a.HtAmount_Bz AS '有效签约金额_人民币',
    a.ExcludingTaxHtAmount_Bz AS '有效签约金额_不含税',
    a.SignDate AS '签约日期',
    CASE
        WHEN a.IfDdhs = 1 THEN
            ISNULL(my1.FinishDatetime, BalanceDate)
        ELSE
            a1.balancedate1
    END AS '结算日期',
    a.YfProviderName AS '乙方单位',
    a.YfCorporation AS '乙方法人代表',
    cb_contract.bfProviderName AS '丙方单位',
    a.HtClass AS '合同属性',
    DjDate AS '登记日期',
    HtTypeName AS '合同类别',
    a.bgxs AS '计价方式',
    JbrNew AS '经办人',
    a.JbDeptName AS '经办部门',
    my.InitiateRoleOrBUName AS '发起部门',
    my.InitiateDatetime AS '发起时间',
    a.JsAmount AS '结算金额',
    a.SumPayAmount AS '累计已付金额',
    CASE
        WHEN LEN(a.UseCostInfo) > 0 THEN
            '是'
        ELSE
            '否'
    END AS '关联合约规划',
    a.SignMode AS '采购方式',
    CASE
        WHEN a.Contract2CgProcGUID IS NOT NULL THEN
            cc.CgPlanName
        ELSE
            '-'
    END AS '采购方案名称',
    CASE
        WHEN j.cnt > 0 THEN
            '是'
        ELSE
            '否'
    END AS '是否有补充协议',
    a.VouchType AS '发票类型',
    a.CollectionType AS '征收方式',
    a.budgetlibraryname '合约包名称',
    dbo.fn_get_tax_budgetuse_contract(a.ContractGUID) AS '税率',
    h.YgAlterAmount_Bz AS '预估变更金额',
    CASE
        WHEN a.HtAmount = 0 THEN
            0
        ELSE
            h.YgAlterAmount_Bz * 1.00 / a.HtAmount
    END AS '预估变更金额比例',
    cb_HTBalance.SsAmountBz AS '送审金额',
    cb_HTBalance.EsAmountBz AS '二审金额',
    pr.ContractName 预呈批名称,
    mypr.FinishDatetime 预呈批审批时间,
    mydb.FinishDatetime 定标审批时间,
    a.LwProviderName as 劳务分包单位,
    win.providername AS 中标单位,
    a.Htproperty as 合同性质,
    case when a.IfDdhs =1 then '是' else '否' end as 是否单独执行,
    a.zlbs as 是否通过筑龙平台进行定标
FROM 
    vcb_Contract a
    left join #value v on a.ContractGUID =v.ContractGUID
    LEFT JOIN cb_Contract_Pre pr ON a.PreContractGUID = pr.PreContractGUID
    LEFT JOIN myWorkflowProcessEntity mypr  ON mypr.BusinessGUID = pr.PreContractGUID AND mypr.ProcessStatus = '2'
    LEFT JOIN p_Project p
        ON p.ProjCode = CASE
                            WHEN LEN(a.ProjectCode) > 1
                                 AND CHARINDEX(';', a.ProjectCode) < 1 THEN
                                a.ProjectCode
                            WHEN LEN(a.ProjectCode) > 1
                                 AND CHARINDEX(';', a.ProjectCode) >= 1 THEN
                                LEFT(a.ProjectCode, CHARINDEX(';', a.ProjectCode) - 1)
                            ELSE
                                NULL
                        END
    LEFT JOIN ERP25.dbo.mdm_Project mp
        ON mp.ProjGUID = p.ProjGUID
    LEFT JOIN ERP25.dbo.mdm_LbProject lb
        ON lb.projGUID = ISNULL(mp.ParentProjGUID, mp.ProjGUID)
           AND lb.LbProject = 'tgid'
    LEFT JOIN
    (
        SELECT ContractGUID contractguid,
               BfProviderName bfProviderName
        FROM cb_Contract
    ) cb_contract
        ON a.ContractGUID = cb_contract.contractguid
    LEFT JOIN cb_Currency
        ON a.Bz = cb_Currency.CurrencyGUID
    LEFT JOIN cb_HTBalance
        ON a.ContractGUID = cb_HTBalance.ContractGUID
           AND BalanceType = '结算'
           AND cb_HTBalance.ApproveState = '已审核'
    LEFT JOIN myWorkflowProcessEntity my
        ON a.ContractGUID = my.BusinessGUID
           AND my.IsHistory = 0
    LEFT JOIN myWorkflowProcessEntity my1
        ON my1.BusinessGUID = cb_HTBalance.HTBalanceGUID
           AND my1.ProcessStatus = '2'
    LEFT JOIN
    (
        SELECT vcb_Contract.ContractGUID,
               ISNULL(myWorkflowProcessEntity.FinishDatetime, BalanceDate) AS balancedate1
        FROM vcb_Contract
            INNER JOIN cb_HTBalance
                ON vcb_Contract.MasterContractGUID = cb_HTBalance.ContractGUID
                   AND BalanceType = '结算'
                   AND cb_HTBalance.ApproveState = '已审核'
            LEFT JOIN myWorkflowProcessEntity
                ON myWorkflowProcessEntity.BusinessGUID = cb_HTBalance.HTBalanceGUID
                   AND myWorkflowProcessEntity.ProcessStatus = '2'
        WHERE vcb_Contract.IfDdhs <> 1
    ) a1  ON a.ContractGUID = a1.ContractGUID
    LEFT JOIN cb_ContractYgAlter h ON a.ContractGUID = h.ContractGUID
    LEFT JOIN
    (
        SELECT MasterContractGUID,
               COUNT(*) AS cnt
        FROM cb_Contract a
        WHERE a.ApproveState = '已审核'
        GROUP BY a.MasterContractGUID
    ) j
        ON a.ContractGUID = j.MasterContractGUID
    LEFT JOIN cg_Contract2CgProc cc
        ON cc.Contract2CgProcGUID = a.Contract2CgProcGUID
    LEFT JOIN cg_CgProcWinBid db
        ON db.CgSolutionGUID = cc.CgSolutionGUID
    LEFT JOIN myWorkflowProcessEntity mydb
        ON mydb.BusinessGUID = db.CgProcWinBidGUID
           AND mydb.ProcessStatus = '2'
	LEFT JOIN (SELECT a.CgSolutionGUID, STRING_AGG(p.providername, '; ') AS providername
				FROM Cg_CgProcReturnBid a
				left join p_provider p on p.providerGUID = a.providerGUID
				where WinBidResult='已中标'
				GROUP BY a.CgSolutionGUID
			  ) win on win.CgSolutionGUID = cc.CgSolutionGUID
WHERE 
    (1 = 1)
    AND a.BUGUID IN ( @var_buguid )
ORDER BY 
    DjDate DESC;