
-- 规则说明：
-- 1. 优先取最新一笔发票信息；
-- 2. 若无发票，则取最新一笔付款单据信息；
-- 3. 若无付款单据，则取最新一笔签约信息。

    SELECT  a.KpDate AS KpDate ,    
            a.InvoiceType ,    
            a.InvoiceCode ,    
            a.InvoiceNo ,    
            -- a.NoTaxAmount ,    
            -- a.TaxAmount ,    
            -- a.State ,    
            -- a.PurchaserName AS BuyerName ,    
            -- a.SellerName ,    
            -- b.HierarchyCode AS JbDeptCode ,    
            -- CASE WHEN ISNULL(c.RowNum, 0) > 0 THEN '是'    
            --      ELSE '否'    
            -- END AS MatchingState ,    
            a.InvoiceGUID ,    
            a.TotalAmount ,    
            -- 0 AS AutoWriteState ,    
            -- a.SellerIsCooperate ,    
            -- a.RzRequestState,
            ht.ContractCode,
            ht.ContractName,
            ht.ContractGUID
            -- d.ApplyCode,
			-- a.pytInvoiceType,
			-- a.invoiceOrig,
			-- 0 as IsFyControl,
			-- null HTFKApplyGUID
    into  #vcb_InvoiceQuery 
    FROM    cb_PayConfirmSheet_Invoice a with(nolock)   
            -- LEFT JOIN dbo.myBusinessUnit b ON b.BUGUID = a.BUGUID    
            -- LEFT JOIN ( SELECT  COUNT(1) AS RowNum ,    
            --                     InvoiceGUID    
            --             FROM    cb_PayConfirmSheet_InvoiceRef a inner join cb_PayConfirmSheet b on a.PayConfirmSheetGUID=b.PayConfirmSheetGUID   WHERE a.PayConfirmSheetGUID IS NOT NULL
            --             GROUP BY InvoiceGUID    
            --           ) c ON c.InvoiceGUID = a.InvoiceGUID    
            LEFT JOIN (SELECT (SELECT ApplyCode + ';' FROM vcb_PayConfirmSheet_InvoiceRef with(nolock) WHERE InvoiceGUID=ref.InvoiceGUID FOR XML PATH('')) AS ApplyCode,
                              InvoiceGUID,ContractGUID FROM vcb_PayConfirmSheet_InvoiceRef ref with(nolock) WHERE ref.ContractGUID IS NOT NULL GROUP BY InvoiceGUID,ContractGUID
                       ) d ON a.InvoiceGUID=d.InvoiceGUID       
            LEFT JOIN dbo.cb_Contract ht with(nolock) ON d.ContractGUID = ht.ContractGUID  
    UNION ALL    
    SELECT  a.InvoiceDate ,    
            a.InvoiceType ,    
            a.InvoiceCode ,    
            a.InvoNO ,    
            -- a.InvoiceAmount - a.InputTaxAmount AS NoTaxAmount ,    
            -- a.InputTaxAmount AS TaxAmount ,    
            -- '手工录入' AS State ,    
            -- '' AS BuyerName ,    
            -- '' AS SellerName ,    
            -- d.HierarchyCode AS JbDeptCode ,    
            -- '否' AS MatchingState ,               
            a.InvoiceItemGUID AS InvoiceGUID ,    
            a.InvoiceAmount AS TotalAmount ,    
            -- 1 AS AutoWriteState ,    
            -- 0 AS SellerIsCooperate ,    
            -- '' AS RzRequestState,
            c.ContractCode,
            c.ContractName,
            c.ContractGUID
            -- e.ApplyCode ,
			-- '' AS pytInvoiceType,
			-- '' AS invoiceOrig,
			-- 0 as IsFyControl,
			-- null HTFKApplyGUID
    FROM    cb_InvoiceItem a with(nolock)   
            INNER JOIN dbo.cb_Voucher b with(nolock) ON a.RefGUID = b.VouchGUID    
            LEFT JOIN dbo.cb_Contract c with(nolock) ON b.ContractGUID = c.ContractGUID    
            -- LEFT JOIN dbo.myBusinessUnit d ON c.DeptGUID = d.BUGUID 
            -- LEFT JOIN (SELECT (SELECT ApplyCode + ';' FROM cb_HTFKApply WHERE ContractGUID=fk.ContractGUID FOR XML PATH('')) AS ApplyCode,
            --                   ContractGUID FROM cb_HTFKApply fk GROUP BY ContractGUID
            --            ) e ON a.ContractGUID=e.ContractGUID

	union all
	--费用系统付款申请发票
	select 
		paperDrewDate
		,InvoiceType = case invoiceType 
			when 'c' then '增值税普通发票' 
			when 's' then '增值税专用发票' 
			when 'se' then '增值税电子专用发票' 
			when 'ce' then '增值税电子普通发票'  
			when 'qc' then '全电增值税电子普通发票' 
			when 'qs' then '全电增值税电子专用发票' 
			when 'cz' then '全电增值税纸质普通发票' 
			when 'sz' then '全电增值税纸质专用发票'
			else '增值税普通发票' end
		,invoiceCode
		,invoiceNo
		-- ,amountWithoutTax
		-- ,taxAmount
		-- ,State = case checkStatus when 0 then '待验真' when 1 then '验真中' when 2 then '验真成功' when 3 then '验真失败' when 4 then '无需验真'  else '待验真' end
		-- ,buyerName
		-- ,sellerName
		-- ,e.HierarchyCode AS JbDeptCode
		-- ,null as MatchingState
		,InvoiceGUID
		,amountWithTax
		-- ,null as AutoWriteState
		-- ,null AS SellerIsCooperate
		-- ,null as RzRequestState 
		,c.ContractCode
		,c.ContractName
        ,c.ContractGUID
		-- ,b.ApplyCode,
		-- '' AS pytInvoiceType
		-- ,'' AS invoiceOrig
		-- ,1 as IsFyControl
		-- ,b.HTFKApplyGUID
		from fy_Invoice a with(nolock)
		inner join cb_HTFKApply b with(nolock) on a.SourceGUID = b.HTFKApplyGUID 
		left join cb_Contract c with(nolock) on b.ContractGUID = c.ContractGUID
		-- LEFT JOIN dbo.myBusinessUnit e ON b.BUGUID = e.BUGUID  
		where b.ApplyState='已审核';

-- 1. 合同信息（包含乙方、甲方供应商，已审核，且供应商GUID不为空）
WITH #con AS (
    SELECT 
        BUGUID, 
        ContractCode,
        ContractName,
        ContractGUID,
        SignDate,
        HtAmount,
        YfProviderGUID AS ProviderGUID,      -- 乙方供应商GUID
        YfProviderName AS ProviderName       -- 乙方供应商名称
    FROM cb_contract with(nolock)
    WHERE ApproveState = '已审核' 
      AND YfProviderGUID IS NOT NULL

    UNION

    SELECT 
        BUGUID, 
        ContractCode,
        ContractName,
        ContractGUID,
        SignDate,
        HtAmount,
        BfProviderGUID AS ProviderGUID,      -- 甲方供应商GUID
        BfProviderName AS ProviderName       -- 甲方供应商名称
    FROM cb_contract with(nolock)
    WHERE ApproveState = '已审核' 
      AND BfProviderGUID IS NOT NULL 
),


-- 2. 付款单据信息（已审核，且发票类型为“发票”）
#pay AS (
    SELECT 
        con.BUGUID,
        con.ContractCode,
        con.ContractName,
        con.ContractGUID,
        con.SignDate,
        con.HtAmount,
        con.ProviderGUID,
        con.ProviderName,
        v.vouchguid,             -- 凭证GUID
        v.Invotype,              -- 发票类型
        v.InvoNO,                -- 发票号码
        pay.PayAmount,           -- 付款金额
        pay.PayDate,             -- 付款日期
        t.freeitem1_New          -- NC底层唯一码
    FROM #con con
    INNER JOIN cb_pay pay with(nolock) ON pay.ContractGUID = con.ContractGUID
    INNER JOIN cb_Voucher v with(nolock) ON pay.vouchguid = v.vouchguid
    OUTER APPLY (
        -- 取最新一笔（按开票日期倒序）已审核且导出日期有效的付款明细
        SELECT TOP 1 vouchguid, payguid, freeitem1_New 
        FROM vcb_Voucher2PayDetail_New v2p with(nolock)
        WHERE ApproveState = '已审核'
          AND FinanceExportDate_New IS NOT NULL
          AND DATEDIFF(dd, FinanceExportDate_New, '1918-01-01') != 0
          AND v2p.vouchguid = v.vouchguid
          AND pay.payguid = v2p.payguid 
        ORDER BY v2p.kpdate DESC 
    ) t  
    WHERE pay.ApproveState = '已审核' 
      AND v.Invotype = '发票'
),
-- 3. 发票信息（已审核，发票与付款单据关联）
#Invoice AS (

    -- SELECT  
    --     pay.ProviderGUID,
    --     pay.ProviderName,
    --     pay.ContractGUID,
    --     pay.ContractCode,
    --     pay.ContractName,
    --     pay.HtAmount,
    --     pay.InvoNO AS payInvoNO,         -- 付款单据发票号
    --     pay.PayAmount,
    --     pay.vouchguid,
    --     pay.PayDate,
    --     pay.freeitem1_New,
    --     iv.InvoiceCode,                  -- 发票代码
    --     iv.InvoNO,                       -- 发票号码
    --     iv.InvoiceAmount,                -- 发票金额
    --     iv.InvoiceDate                 -- 发票日期
    --     -- iv.PayProviderGUID,              -- 供应商GUID
    --     -- PayProviderName                  -- 供应商名称
    -- FROM #pay pay
    -- INNER JOIN cb_Invoiceitem iv   ON pay.ContractGUID = iv.ContractGUID  AND pay.vouchguid = iv.RefGUID
    -- WHERE iv.ApproveState = '已审核' 

      SELECT
          pay.ProviderGUID,
          pay.ProviderName,
          pay.ContractGUID,
          pay.ContractCode,
          pay.ContractName,
          pay.HtAmount,
          pay.InvoNO AS payInvoNO,              -- 付款单据发票号
          pay.PayAmount,
          pay.vouchguid,
          pay.PayDate,
          pay.freeitem1_New,
          iv.InvoiceCode,                       -- 发票代码
          iv.InvoNO,                            -- 发票号码
          iv.InvoiceAmount,                     -- 发票金额
          iv.InvoiceDate                        -- 发票日期
      FROM
          #pay pay
      OUTER APPLY (
          SELECT TOP 1
              InvoiceCode,
              InvoiceNo AS InvoNO, 
              TotalAmount AS InvoiceAmount,
              kpdate AS InvoiceDate
          FROM
              #vcb_InvoiceQuery
          WHERE  contractGUID = pay.ContractGUID
          ORDER BY kpdate DESC
      ) iv
),

-- 4. 供应商最新发票信息（每个供应商取最新一笔发票）
#invoice_pov AS (
    SELECT 
        pov.Providerguid AS 供应商GUID,
        pov.ProviderName AS 供应商名称,
        pov.ProviderCode AS 供应商编号,
  
        invoice.ContractCode AS 最新的合同编码,
        invoice.ContractName AS 合同名称,
        case when cg_TacticCgAgreement.YfProviderGUID is not null then  '是' else '否' end as 是否有战略协议,  
        invoice.HtAmount AS 合同金额,
        invoice.payInvoNO AS 最新付款登记单据编码,
        invoice.PayAmount AS 最新付款登记金额,
        invoice.freeitem1_New AS 导单给NC的底层唯一码,
        NULL AS 项目档案,
        invoice.InvoiceCode AS 最新的发票代码,
        invoice.InvoNO AS 最新的发票号码,
        invoice.InvoiceAmount AS 最新的发票金额
    FROM p_Provider pov with(nolock)
    left join    (     
        select YfProviderGUID  
        from  [vcg_TacticCgAgreement] with(nolock)
        where AuditState ='已审核'
        group by YfProviderGUID  
    ) cg_TacticCgAgreement  on pov.ProviderGUID = cg_TacticCgAgreement.YfProviderGUID  
    INNER JOIN (
        -- 每个供应商按发票日期倒序排序，取最新一笔
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY ProviderGUID ORDER BY InvoiceDate DESC) AS rownum,  
            ProviderGUID,
            ContractCode,
            ContractName,
            HtAmount,
            payInvoNO,
            PayAmount,
            freeitem1_New,
            InvoiceCode,
            InvoNO,
            InvoiceAmount,
            InvoiceDate
        FROM #Invoice
    ) invoice  ON invoice.ProviderGUID = pov.ProviderGUID AND rownum = 1
    WHERE pov.IsJfProvider = 0
),

-- 5. 供应商最新付款单据（若无发票，则取最新付款单据）
#pay_pov AS (
    SELECT  
        pov.Providerguid AS 供应商GUID,
        pov.ProviderName AS 供应商名称,
        pov.ProviderCode AS 供应商编号,

        pay.ContractCode AS 最新的合同编码,
        pay.ContractName AS 合同名称,
        case when cg_TacticCgAgreement.YfProviderGUID is not null then  '是' else '否' end as 是否有战略协议,
        pay.HtAmount AS 合同金额,
        pay.InvoNO AS 最新付款登记单据编码,
        pay.PayAmount AS 最新付款登记金额,
        pay.freeitem1_New AS 导单给NC的底层唯一码,
        NULL AS 项目档案,
        NULL AS 最新的发票代码,
        NULL AS 最新的发票号码,
        NULL AS 最新的发票金额
    FROM p_Provider pov with(nolock)
    left join    (     
        select YfProviderGUID  
        from  [vcg_TacticCgAgreement] with(nolock)
        where AuditState ='已审核'
        group by YfProviderGUID  
    ) cg_TacticCgAgreement  on pov.ProviderGUID = cg_TacticCgAgreement.YfProviderGUID
    INNER JOIN (
        -- 每个供应商按付款日期倒序排序，取最新一笔
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY ProviderGUID ORDER BY PayDate DESC) AS rownum, 
            ProviderGUID,
            ContractCode,
            ContractName,
            HtAmount,
            InvoNO,
            PayAmount,
            freeitem1_New
        FROM #pay
    ) pay
        ON pay.ProviderGUID = pov.ProviderGUID AND rownum = 1
    WHERE pov.IsJfProvider = 0
      AND NOT EXISTS (
          -- 若该供应商已存在发票信息，则不再取付款单据
          SELECT 1 FROM #invoice_pov ipov WHERE ipov.供应商GUID = pov.Providerguid
      )
),

-- 6. 供应商最新合同信息（若无发票、无付款单据，则取最新合同）
#con_pov AS (
    SELECT  
        pov.Providerguid AS 供应商GUID,
        pov.ProviderName AS 供应商名称,
        pov.ProviderCode AS 供应商编号,
       
        con.ContractCode AS 最新的合同编码,
        con.ContractName AS 合同名称,
        case when cg_TacticCgAgreement.YfProviderGUID is not null then  '是' else '否' end as 是否有战略协议,
        con.HtAmount AS 合同金额,
        NULL AS 最新付款登记单据编码,
        NULL AS 最新付款登记金额,
        NULL AS 导单给NC的底层唯一码,
        NULL AS 项目档案,
        NULL AS 最新的发票代码,
        NULL AS 最新的发票号码,
        NULL AS 最新的发票金额
    FROM p_Provider pov with(nolock)
    left join (
    --    SELECT cg_TacticCgAgreement.TacticCgAgreementGUID ,cg_TacticCgAgreement.AgreementCode ,cg_TacticCgAgreement.AgreementName ,
    --    cg_TacticCgAgreement.SignDate ,cg_TacticCgAgreement.ValidBeginDate ,cg_TacticCgAgreement.ValidEndDate ,b.ProviderName 
    --    FROM vcg_TacticCgAgreement cg_TacticCgAgreement 
    --    LEFT JOIN p_Provider b on cg_TacticCgAgreement.YfProviderGUID=b.ProviderGUID WHERE (2=2) AND cg_TacticCgAgreement.BUGUID=[当前公司]
        select YfProviderGUID  
        from  [vcg_TacticCgAgreement] with(nolock)
        where AuditState ='已审核'
        group by YfProviderGUID  
    ) cg_TacticCgAgreement  on pov.ProviderGUID = cg_TacticCgAgreement.YfProviderGUID
    LEFT JOIN (
        -- 每个供应商按签约日期倒序排序，取最新一笔
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY ProviderGUID ORDER BY SignDate DESC) AS rownum, 
            ProviderGUID,
            ContractCode,
            ContractName,
            HtAmount
        FROM #con
    ) con ON con.ProviderGUID = pov.ProviderGUID AND rownum = 1
    WHERE pov.IsJfProvider = 0
      AND NOT EXISTS (
          -- 若该供应商已存在发票信息，则不再取合同
          SELECT 1 FROM #invoice_pov ipov WHERE ipov.供应商GUID = pov.Providerguid
      )
      AND NOT EXISTS (
          -- 若该供应商已存在付款单据，则不再取合同
          SELECT 1 FROM #pay_pov pay WHERE pay.供应商GUID = pov.Providerguid
      )
)

-- 7. 查询最终结果，优先级：发票 > 付款单据 > 合同
SELECT * FROM #invoice_pov
UNION ALL
SELECT * FROM #pay_pov
UNION ALL
SELECT * FROM #con_pov