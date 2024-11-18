-- 重点合约包对应的科目的合同金额
SELECT  DISTINCT c.BUGUID ,
                 cp.ProjGUID ,
                 c.ContractGUID ,
                 c.HtAmount
INTO    #zdht
FROM    cb_ProjHyb hyb
        INNER JOIN cb_httype ht ON hyb.buguid = ht.BUGUID AND  ht.HtTypeGUID = hyb.HtTypeGUID
        INNER JOIN cb_Contract c ON c.HtTypeCode = ht.HtTypeCode AND   c.BUGUID = ht.BUGUID
        INNER JOIN cb_ContractProj cp ON cp.ContractGUID = c.ContractGUID AND  cp.ProjGUID = hyb.ProjGUID
WHERE   hyb.ContractName IN ('施工总承包工程', '精装修工程', '园林绿化工程') AND  c.approvestate = '已审核';

--宽表底表
SELECT  p.ProjGUID ,
        p.projcode ,
        p.projname ,
        CONVERT(NVARCHAR(MAX), c.projectnamelist) projectnamelist ,
        CONVERT(NVARCHAR(MAX), c.projectcodelist) projectcodelist ,
        c.ContractCode ,
        c.ContractGUID ,
        c.contractname ,
        c.HtTypeCode ,
        ht.htTypeName ,
        c.htclass ,
        c.JsState ,
        AlterDate ,
        c.HtAmount ,
        CASE WHEN zd.ContractGUID IS NOT NULL THEN c.HtAmount ELSE 0 END AS zdHtAmount ,
        alt.AlterType ,
		alt.ApplyAmount , --申报金额
		alt.QrApproveState, --金额确认状态
        alt.AlterAmount ,
		alt.QrAlterAmount AS WgQrAlterAmount, --完工确认金额集团口径
        CASE WHEN zd.ContractGUID IS NOT NULL THEN alt.AlterAmount ELSE 0 END AS zdAlterAmount ,
        alt.alterreason ,
        alt.htalterguid ,
        alt.altercode ,
        CASE WHEN (alt.QrStatus IN ('已完工', '无需完工') OR   alt.QrApproveState = '已审核') THEN 1 ELSE 0 END AS QrAlterNum ,                                   -- 已完工签证变更份数
        CASE WHEN (alt.QrStatus IN ('已完工', '无需完工') OR   alt.QrApproveState = '已审核') THEN alt.AlterAmount ELSE 0 END AS QrAlterAmount ,                  -- 已完工签证变更金额 
        CASE WHEN alt.altertype = '设计变更' AND (alt.QrStatus IN ('已完工', '无需完工') OR alt.QrApproveState = '已审核') THEN 1 ELSE 0 END AS QrDesignAlterNum ,    -- 已完工签证变更份数
        (CASE WHEN e.AlterClass = 'Ⅰ类变更' THEN ISNULL(alt.AlterAmount, 0)ELSE 0 END) firstSjAlterAmount ,
        (CASE WHEN e.AlterClass = 'Ⅱ类变更' THEN ISNULL(alt.AlterAmount, 0)ELSE 0 END) SecondSjAlterAmount
FROM    cb_contract c
        LEFT JOIN cb_httype ht ON c.HtTypeCode = ht.HtTypeCode AND c.buguid = ht.buguid
        INNER JOIN cb_ContractProj cp ON cp.ContractGUID = c.ContractGUID
        INNER JOIN p_Project p ON p.ProjGUID = cp.ProjGUID
        INNER JOIN cb_HtAlter alt ON alt.ContractGUID = c.ContractGUID
        LEFT JOIN cb_DesignAlter e ON alt.DesignAlterGuid = e.DesignAlterGuid
        LEFT JOIN #zdht zd ON zd.ContractGUID = cp.ContractGUID AND zd.ProjGUID = cp.ProjGUID
WHERE   alt.ApproveState = '已审核' AND alt.AlterType IN ('设计变更', '现场签证') AND  (c.HtTypeCode LIKE '04%' OR
                                                                            --c.HtTypeCode  like '02%' or 
                                                                            c.HtTypeCode LIKE '06%' OR  c.HtTypeCode LIKE '03%' OR  c.HtTypeCode LIKE '05%') AND c.htclass NOT LIKE '%非合同%'
        AND c.approvestate = '已审核'

DROP TABLE #zdht
