SELECT  dtDetails.RecollectDetailsGUID AS MonthlyReviewGUID , --月度回顾明细GUID 
		dtDetails.RecollectDetailsGUID, --月度回顾明细GUID 
        dtDetails.RecollectGUID AS ReviewGUID , --RecollectGUID字段       
        p.ProjGUID ,  --项目GUID(ProjGUID)        
        p.BUGUID ,  --公司GUID        
        dtcr.LastVersion , --上次版本号        
        dtcr.CurVersion , --本次版本号     
        dtcr.VersionType, -- 动态成本拍照版本类型   
        dtcr.RecollectDate AS ReviewDate , --回顾日期 
        dtcr.Remarks AS Remark , --回顾说明
		dtcr.JcRemark as  JcRemark, --节超说明
        myOption.ParamGUID AS ProductTypeGUID ,	--产品类型GUID
        product.BProductTypeName AS ProductType , --产品类型
        mdModule.ProductNameGUID AS ProductNameGUID ,  --产品名称GUID
        product.ProductName AS ProductName ,  --产品名称
        productYt.CbYtCode AS YtCode ,  --成本业态产品编码
        productYt.ProductYtGUID AS ProductYtGUID , --成本业态产品编码GUID
        projYtSet.YtGUID AS YtGUID ,  --成本业态产品GUID
        projYtSet.YtName AS YtName ,  --成本业态产品名称
        mdModule.PhyAddress AS PhyAddress ,  --产品类型物理位置
        dtcrProduct.IsSale AS isSale ,  --是否可售
        dtDetails.CostCode AS AccountCode ,--科目代码
        dtDetails.CostShortName AS AccountName , --科目名称
        ISNULL(dtDetails.TargetCost, 0) AS TargetCost ,--目标成本
        ISNULL(dtDetails.ExcludingTaxTargetCost, 0) AS TargetCostNonTax ,--目标成本不含税
        ISNULL(dtDetails.DtCost, 0) AS CurDynamicCost ,  --本次动态成本	
        ISNULL(dtDetails.ExcludingTaxDtCost,0) AS CurDynamicCostNonTax ,  --本次动态成本不含税
        ISNULL(dtDetails.DtCost, 0) - ISNULL(SumAlterAmount_Fxj, 0) AS CurDynamicCost_fxj ,  --本次动态成本(非现金)
        ISNULL(dtDetails.ExcludingTaxDtCost, 0)
        - ISNULL(ExcludingTaxSumAlterAmount_Fxj, 0) AS CurDynamicCostNonTax_fxj , --本次动态成本(非现金)不含税
        ISNULL(dtDetails.DfsBudget, 0) AS CurOccurCost ,  --本次待发生合约规划
        ISNULL(dtDetails.ExcludingTaxDfsBudget, 0) AS CurOccurCostNonTax ,  --本次待发生合约规划不含税
        ISNULL(dtDetails.HtAmount_Bz_FX, 0) AS CurContractAmount ,  --本次合同成本
        ISNULL(dtDetails.ExcludingTaxHtAmount_Bz_FX, 0) AS CurContractAmountNonTax ,  --本次合同成本不含税
        ISNULL(dtDetails.SumAlterAmount_Fxj, 0) AS CurAlterAmount_Fxj ,  --本次变更（非现金）
        ISNULL(dtDetails.ExcludingTaxSumAlterAmount_Fxj, 0) AS ExcludingTaxCurAlterAmount_Fxj ,  --本次变更不含税（非现金）
        ISNULL(dtDetails.JsAmount, 0) AS CurBalanceAmount ,  --本次结算金额
        ISNULL(dtDetails.ExcludingTaxJsAmount, 0) AS CurBalanceAmountNonTax ,  --本次结算金额不含税
        ISNULL(dtDetails.ZTCost, 0) AS CurTransitCost ,  --本次在途成本
        ISNULL(dtDetails.ExcludingTaxZTCost, 0) AS CurTransitCostNonTax ,  --本次在途成本不含税
        ISNULL(dtDetails.HtAmount_Bz_FX_Last, 0) AS LastContractAmount ,  --上次合同成本
        ISNULL(dtDetails.ExcludingTaxHtAmount_Bz_FX_Last, 0) AS LastContractAmountNonTax ,  --上次合同成本不含税
        ISNULL(dtDetails.DtCost_Last, 0) AS LastDynamicCost ,  --上次动态成本
        ISNULL(dtDetails.ExcludingTaxDtCost_Last, 0) AS LastDynamicCostNonTax ,  --上次动态成本不含税
        ISNULL(dtDetails.SumAlterAmount_Fxj_Last, 0) AS LastAlterAmount_Fxj ,  --上次变更（非现金）
        ISNULL(dtDetails.ExcludingTaxSumAlterAmount_Fxj_Last, 0) AS ExcludingTaxLastAlterAmount_Fxj ,  --上次变更不含税（非现金）
        ISNULL(dtDetails.DtCost_Last, 0)
        - ISNULL(dtDetails.SumAlterAmount_Fxj_Last, 0) AS LastDynamicCost_fxj ,  --上次次动态成本(非现金)
        ISNULL(dtDetails.ExcludingTaxDtCost_Last, 0)
        - ISNULL(dtDetails.ExcludingTaxSumAlterAmount_Fxj_Last, 0) AS LastDynamicCostNonTax_fxj ,  --上次动态成本(非现金)不含税
        ISNULL(dtDetails.DfsBudget_Last, 0) AS LastOccurCost ,  --上次待发生合约规划
        ISNULL(dtDetails.ExcludingTaxDfsBudget_Last, 0) AS LastOccurCostNonTax ,  --上次待发生合约规划不含税
        ISNULL(dtDetails.JsAmount_Last, 0) AS LastBalanceAmount ,  --上次结算金额
        ISNULL(dtDetails.ExcludingTaxJsAmount_Last, 0) AS LastBalanceAmountNonTax ,  --上次结算金额不含税
        ISNULL(dtDetails.ZTCost_Last,0) AS LastTransitCost ,  --上次在途成本
        ISNULL(dtDetails.ExcludingTaxZTCost_Last, 0) AS LastTransitCostNonTax ,  --上次在途成本不含税
        NULL AS AdjustCost , --调整成本
        NULL AS AdjustCostNonTax , --调整成本不含税
        NULL AS CurDeductAmount ,  --本次扣款金额
        NULL AS CurDeductAmountNonTax ,  --本次扣款金额不含税
        NULL AS CurDesignerAlterCost ,  --本次设计变更
        NULL AS CurDesignerAlterCostNonTax ,  --本次设计变更不含税
        NULL AS CurEstimateChange ,  --本次预估变更
        NULL AS CurEstimateChangeNonTax ,  --本次预估变更不含税
        NULL AS CurHtAmount ,  --本次合同净值_含补充
        NULL AS CurHtAmountNonTax ,  --本次合同净值_含补充不含税
        NULL AS CurLocalAlterCost ,  --本次现场签证
        NULL AS CurLocalAlterCostNonTax ,  --本次现场签证不含税
        NULL AS CurSettlementMarginAmount ,  --本次结算调整
        NULL AS CurSettlementMarginAmountNonTax ,  --本次结算调整不含税
        NULL AS CurSubContract ,  --本次分包合同
        NULL AS CurSubContractNonTax ,  --本次分包合同不含税
        NULL AS CurSupplementalContract ,  --本次补充合同
        NULL AS CurSupplementalContractNonTax ,  --本次补充合同不含税
        NULL AS CurWithoutContractAmount ,  --本次无合同成本
        NULL AS CurWithoutContractAmountNonTax ,  --本次无合同成本不含税
        NULL AS LastDeductAmount ,  --上次扣款金额
        NULL AS LastDeductAmountNonTax ,  --上次扣款金额不含税
        NULL AS LastDesignerAlterCost ,  --上次设计变更
        NULL AS LastDesignerAlterCostNonTax ,  --上次设计变更不含税
        NULL AS LastEstimateChange ,  --上次预估变更
        NULL AS LastEstimateChangeNonTax ,  --上次预估变更不含税
        NULL AS LastHtAmount ,  --上次合同净值_含补充
        NULL AS LastHtAmountNonTax ,  --上次合同净值_含补充不含税
        NULL AS LastLocalAlterCost ,  --上次现场签证
        NULL AS LastLocalAlterCostNonTax ,  --上次现场签证不含税
        NULL AS LastSettlementMarginAmount ,  --上次结算调整
        NULL AS LastSettlementMarginAmountNonTax ,  --上次结算调整不含税
        NULL AS LastSubContract ,  --上次分包合同
        NULL AS LastSubContractNonTax ,  --上次分包合同不含税
        NULL AS LastSupplementalContract ,  --上次补充合同
        NULL AS LastSupplementalContractNonTax ,  --上次补充合同不含税
        NULL AS LastWithoutContractAmount ,  --上次无合同成本
        NULL AS LastWithoutContractAmountNonTax ,  --上次无合同成本不含税
        NULL AS HtfkTotalCfAmount ,  --付款申请累计分期拆分金额
        NULL AS PayTotalCfAmount,  --实付成本
        dtcrProduct.DtCostRecollectProductGUID AS DtCostRecollectProductGUID, --动态成本回顾产品相关信息GUID
        product.ProductGUID AS ProductGUID,  --成本产品GUID
        dtcr.CreateUserName,
        dtcr.ApproveState
FROM    cb_DtCostRecollectDetails AS dtDetails
        inner join cb_DtCostRecollect dtc on dtDetails.RecollectGUID = dtc.RecollectGUID
        left JOIN cb_DtCostRecollectProduct AS dtcrProduct ON dtcrProduct.RecollectGUID = dtDetails.RecollectGUID   AND dtcrProduct.ProductGUID = dtDetails.YtGUID
        INNER JOIN (		
            	SELECT RecollectGUID,ProjectGUID,LastVersion,CurVersion,RecollectDate,convert(varchar(2000),Remarks) as Remarks,ApproveState,JcRemark,CreateUserName,
				ROW_NUMBER() over(PARTITION BY ProjectGUID ORDER BY RecollectDate desc) AS num,'本年最新已审核拍照版本' as VersionType
				FROM cb_DTCostRecollect 
                WHERE 1=1 and  DATEDIFF(YEAR, RecollectDate, GETDATE()) = 0  and  ApproveState='已审核' -- or CreateUserName = '系统管理员'
                union 
                SELECT RecollectGUID,ProjectGUID,LastVersion,CurVersion,RecollectDate,convert(varchar(2000),Remarks) as Remarks,ApproveState,JcRemark,CreateUserName,
				ROW_NUMBER() over(PARTITION BY ProjectGUID ORDER BY RecollectDate desc) AS num,'本年最新拍照版本' as VersionType
				FROM cb_DTCostRecollect 
                WHERE 1=1 and  DATEDIFF(YEAR, RecollectDate, GETDATE()) = 0  and  
                not exists (
                    select  1 from cb_DTCostRecollect dt where DATEDIFF(YEAR, dt.RecollectDate, GETDATE()) = 0  and  dt.ApproveState='已审核'
                    and  dt.RecollectGUID = cb_DTCostRecollect.RecollectGUID
                ) -- or CreateUserName = '系统管理员'
                union 
                SELECT RecollectGUID,ProjectGUID,LastVersion,CurVersion,RecollectDate,convert(varchar(2000),Remarks) as Remarks,ApproveState,JcRemark,CreateUserName,
				ROW_NUMBER() over(PARTITION BY ProjectGUID ORDER BY RecollectDate ) AS num,'去年12月拍照版本' as VersionType
				FROM cb_DTCostRecollect WHERE 1=1 AND DATEDIFF(YEAR, RecollectDate, GETDATE()) = 1 AND MONTH(RecollectDate) = 12   
                union   
                SELECT RecollectGUID,ProjectGUID,LastVersion,CurVersion,RecollectDate,convert(varchar(2000),Remarks) as Remarks,ApproveState,JcRemark,CreateUserName,
				ROW_NUMBER() over(PARTITION BY ProjectGUID ORDER BY RecollectDate ) AS num,'历史拍照版本' as VersionType
				FROM cb_DTCostRecollect WHERE 1=1 and  DATEDIFF(YEAR, RecollectDate, GETDATE()) >=1 AND MONTH(RecollectDate) <> 12
		) AS dtcr  ON dtcr.ProjectGUID = dtc.ProjectGUID AND dtcr.RecollectGUID = dtc.RecollectGUID  AND dtcr.num =1
        LEFT JOIN cb_ProductYt AS productYt ON productYt.ProductYtGUID = dtcrProduct.ProductGUID 
        outer  apply (
			SELECT top 1 ProjGUID,CbYtCode,ProductCode,ProductGUID,ProductName,BProductTypeName 
			FROM cb_Product product
			where  product.ProjGUID = productYt.ProjGUID AND product.CbYtCode = productYt.CbYtCode
			ORDER BY OrderNo desc
		) product 
        LEFT JOIN myBizParamOption AS myOption ON myOption.ParamName = 'md_ProductType'
                                                  AND myOption.ParamValue = product.BProductTypeName
        LEFT JOIN md_ProductNameModule AS mdModule ON mdModule.ProductNameCode = product.ProductCode
        LEFT JOIN p_Project AS p ON p.ProjGUID = dtc.ProjectGUID
        LEFT JOIN cb_ProjYtSet AS projYtSet ON projYtSet.ProjGUID = productYt.ProjGUID
                                               AND projYtSet.YtCode = productYt.CbYtCode
WHERE   dtDetails.Type = '科目'  and dtcrProduct.DtCostRecollectProductGUID is null 
