USE [MyCost_Erp352]
GO

/****** Object:  View [dbo].[vcb_InvoiceQuery]    Script Date: 2025/10/24 11:41:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-------------------------------------------------END 创建付款确认单列表视图[vcb_PayConfirmSheet_InvoiceRef]-------------------------------------------

-------------------------------------------------BEGIN 修改发票列表视图[vcb_InvoiceQuery] 增加合同\付款单据字段-------------------------------------------
-- CREATE VIEW [dbo].[vcb_InvoiceQuery]    
-- AS    
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
    FROM    cb_PayConfirmSheet_Invoice a    
            -- LEFT JOIN dbo.myBusinessUnit b ON b.BUGUID = a.BUGUID    
            -- LEFT JOIN ( SELECT  COUNT(1) AS RowNum ,    
            --                     InvoiceGUID    
            --             FROM    cb_PayConfirmSheet_InvoiceRef a inner join cb_PayConfirmSheet b on a.PayConfirmSheetGUID=b.PayConfirmSheetGUID   WHERE a.PayConfirmSheetGUID IS NOT NULL
            --             GROUP BY InvoiceGUID    
            --           ) c ON c.InvoiceGUID = a.InvoiceGUID    
            LEFT JOIN (SELECT (SELECT ApplyCode + ';' FROM vcb_PayConfirmSheet_InvoiceRef WHERE InvoiceGUID=ref.InvoiceGUID FOR XML PATH('')) AS ApplyCode,
                              InvoiceGUID,ContractGUID FROM vcb_PayConfirmSheet_InvoiceRef ref WHERE ref.ContractGUID IS NOT NULL GROUP BY InvoiceGUID,ContractGUID
                       ) d ON a.InvoiceGUID=d.InvoiceGUID       
            LEFT JOIN dbo.cb_Contract ht ON d.ContractGUID = ht.ContractGUID  
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
    FROM    cb_InvoiceItem a    
            INNER JOIN dbo.cb_Voucher b ON a.RefGUID = b.VouchGUID    
            LEFT JOIN dbo.cb_Contract c ON b.ContractGUID = c.ContractGUID    
            LEFT JOIN dbo.myBusinessUnit d ON c.DeptGUID = d.BUGUID 
            LEFT JOIN (SELECT (SELECT ApplyCode + ';' FROM cb_HTFKApply WHERE ContractGUID=fk.ContractGUID FOR XML PATH('')) AS ApplyCode,
                              ContractGUID FROM cb_HTFKApply fk GROUP BY ContractGUID
                       ) e ON a.ContractGUID=e.ContractGUID

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
		from fy_Invoice a 
		inner join cb_HTFKApply b on a.SourceGUID = b.HTFKApplyGUID 
		left join cb_Contract c on b.ContractGUID = c.ContractGUID
		LEFT JOIN dbo.myBusinessUnit e ON b.BUGUID = e.BUGUID  
		where b.ApplyState='已审核'
GO


