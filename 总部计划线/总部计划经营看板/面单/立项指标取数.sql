--经营性现金流回正时间
SELECT  t1.ProjGUID ,
        t1.VersionTypeName ,
        t1.cashDate ,
        SUM(t2.CurIRRCashFlow) AS 累计经营性现金流 ,
        SUM(t2.CurSelfCashFlow) AS 股东回收现金流
INTO    #t1
FROM(SELECT ProjGUID ,
            VersionTypeName ,
            CurIRRCashFlow ,
            CurSelfCashFlow ,
            CASE WHEN RIGHT(c.Month, 1) = '月' THEN DATEADD(d, -1, DATEADD(mm, DATEDIFF(m, 0, CONVERT(DATE, REPLACE(REPLACE(c.Month, '年', '-'), '月', '-') + '1')) + 1, 0))END cashDate
     FROM   dbo.mdm_DWCashFlow c
     WHERE  CHARINDEX('月', c.Month) > 0) t1
    LEFT JOIN(SELECT    ProjGUID ,
                        VersionTypeName ,
                        CurIRRCashFlow ,
                        CurSelfCashFlow ,
                        CASE WHEN RIGHT(c.Month, 1) = '月' THEN DATEADD(d, -1, DATEADD(mm, DATEDIFF(m, 0, CONVERT(DATE, REPLACE(REPLACE(c.Month, '年', '-'), '月', '-') + '1')) + 1, 0))END cashDate
              FROM  dbo.mdm_DWCashFlow c
              WHERE CHARINDEX('月', c.Month) > 0) t2 ON t1.ProjGUID = t2.ProjGUID AND t1.VersionTypeName = t2.VersionTypeName
WHERE   t1.cashDate >= t2.cashDate
GROUP BY t1.cashDate ,
         t1.ProjGUID ,
         t1.VersionTypeName
ORDER BY t1.cashDate ,
         t1.ProjGUID ,
         t1.VersionTypeName;


SELECT dwp.VersionGUID AS VerGUID ,
            dwp.VersionTypeName AS VerName ,
            dwp.CreateDate AS VersionDate ,
            CASE WHEN dwp.Versionnum = 1 THEN 1 ELSE 0 END IsBase ,
            product.YtName ,
            product.issale ,
            productname ,
            --,product.ProductGUID
            dwp.ProjGUID ,
            dwp.VersionGUID ,
            YtBldArea ,
            YtUpBldArea ,
            YtDownBldArea ,
            zksmj ,
			HbgNum,
            YtJrArea
     into #temp_a
	 FROM   (SELECT *
             FROM   (SELECT * ,
                            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY VersionTypeNameFlag) AS Versionnum
                     FROM   (SELECT a.* ,
                                    CASE WHEN VersionTypeName = '二次定位批复版' THEN 1
                                         WHEN VersionTypeName = '二次定位上报版' THEN 2
                                         WHEN VersionTypeName = '定位批复版' THEN 3
                                         WHEN VersionTypeName = '定位上报版' THEN 4
                                         ELSE 5
                                    END VersionTypeNameFlag
                             FROM   (select distinct projguid,versiontype from vmdm_dwproductPrice_Ver )vr
							 inner join vmd_DwProject352 a on vr.projguid =a.projguid  and  a.VersionTypeName =vr.versiontype
                             WHERE   ApplySubject NOT LIKE '%回滚%') t ) Pro
             WHERE Pro.Versionnum = 1) dwp
            INNER JOIN(SELECT   a.ProjGUID ,    --a.ProductGUID,
                                a.VersionGUID ,
                                a.ProductType AS YtName ,
                                a.ProductName ,
                                issale ,
                                SUM(b.JzArea) AS YtBldArea ,
                                SUM(b.DsArea) AS YtUpBldArea ,
                                SUM(b.DxArea) AS YtDownBldArea ,
                                SUM(CASE WHEN isHold = '否' AND  issale = '是' THEN KsArea ELSE 0 END) AS zksmj ,
								SUM(CASE WHEN isHold = '否' AND  issale = '是' THEN HbgNum ELSE 0 END) AS HbgNum ,
                                SUM(b.JrArea) AS YtJrArea
                       FROM MyCost_Erp352.dbo.md_product_cf a
                            INNER JOIN MyCost_Erp352.dbo.md_ProductDtl_CF b ON a.ProductGUID = b.ProductGUID AND   a.VersionGUID = b.VersionGUID AND   a.ProjGUID = b.ProjGUID
                       GROUP BY a.ProjGUID ,
                                a.ProductType ,
                                a.VersionGUID ,
                                a.ProductName ,
                                issale) product ON dwp.ProjGUID = product.ProjGUID AND dwp.VersionGUID = product.VersionGUID


SELECT    projguid ,
                        versiontype ,
                        producttype ,
                        productname ,
                        issale ,
                        MAX(dwprice) YtSynPice ,
                        SUM(dwzksmj) zksmj ,
                        SUM(dwzhz) dwzhz
             into #temp_jj
			 FROM  dbo.vmdm_dwproductPrice_Ver --WHERE ProjGUID= '0FC50C86-6461-E711-80BA-E61F13C57837' and VersionType='总部批复版'			 
              GROUP BY producttype ,
                       projguid ,
                       versiontype ,
                       productname ,
                       issale


SELECT a.ProjGUID ,
                                                    --   a.ProductGUID ,
                            ProductType ,
                            pd.ProductName ,
                                                    --a.VersionGUID ,
                            a.VersionTypeName ,     --add a. by hegj01 20211101
                            CASE WHEN b.CostName = '总成本（含税，计划）' AND pd.IsSale = '是' THEN TotalPrice * 10000 ELSE 0 END YtTotalCostAmount ,
                            CASE WHEN b.CostName = '税前利润（计划）' AND   pd.IsSale = '是' THEN TotalPrice * 10000 ELSE 0 END YtBeforeProfit ,
                            CASE WHEN b.CostName = '税后利润（计划）' AND   pd.IsSale = '是' THEN TotalPrice * 10000 ELSE 0 END YtAfterProfit ,
                            CASE WHEN b.CostName = '1、土地成本' AND pd.IsSale = '是' THEN TotalPrice * 10000 ELSE 0 END YtLandAmount ,
                            CASE WHEN b.CostName = '除土地外直接投资（含税）' AND   pd.IsSale = '是' THEN TotalPrice * 10000 ELSE 0 END YtZtAmount ,
                            CASE WHEN b.CostName IN ('财务费用（计划）', '4、营销费用', '5、管理费用') AND pd.IsSale = '是' THEN TotalPrice * 10000 ELSE 0 END YtExpenses ,
                            CASE WHEN b.CostName = '总成本（含税，计划）' AND pd.IsSale = '是' THEN AvailableUnilaterally ELSE 0 END YtSalePice ,
                            CASE WHEN b.CostName = '销售收入（含税）' AND   pd.IsSale = '是' THEN AvailableUnilaterally ELSE 0 END YtSynPice ,
                            CASE WHEN b.CostName = '销售收入（含税）' AND   pd.IsSale = '是' THEN TotalPrice * 10000 ELSE 0 END YtSynSaleAmount ,
                            CASE WHEN b.CostName = '销售收入（含税）' AND   pd.IsSale = '是' AND pd.IsHold = '否' THEN TotalPrice * 10000 ELSE 0 END zhz ,
                                                    --固定资产取可售持有的总成本（含税，计划）
                            CASE WHEN b.CostName = '总成本（含税，计划）' AND pd.IsSale = '是' AND pd.IsHold = '是' THEN TotalPrice * 10000 ELSE 0 END YtFixedAssets ,
                            pd.IsSale AS pd_IsSale  --add ,pd.IsSale as pd_IsSale by hegj01 20211103
                    into #temp
					FROM   (SELECT CostGUID ,
                                    ProductGUID ,
                                    ProjGUID ,
                                                    --  VersionGUID ,
                                    TotalPrice ,
                                    AvailableUnilaterally ,
                                    BuildUnilaterally ,
                                    LienUnilaterally ,
                                    VersionTypeName --add ,VersionTypeName by hegj01 20211101
                             FROM   dbo.mdm_ProductEarningsProfit
                     -- UNION
                     -- SELECT  
                     --  CostGUID ,
                     --  ProductGUID ,
                     --  ProjGUID ,
                     ----  VersionGUID ,
                     --  TotalPrice ,
                     --  AvailableUnilaterally ,
                     --  BuildUnilaterally ,
                     --  LienUnilaterally
                     -- FROM   dbo.mdm_ProductEarningsProfit_History 
                     ) a
                            INNER JOIN mdm_PositioningCost b ON b.CostGUID = a.CostGUID
                            INNER JOIN(SELECT   ProductGUID ,
                                                ProductType ,
                                                ProductName ,
                                                IsSale ,
                                                IsHold ,
                                                a.ProjGUID ,
                                                a.VersionTypeName
                                       FROM dbo.mdm_DWProduct a
                                       UNION
                                       SELECT   ProductGUID ,
                                                ProductType ,
                                                ProductName ,
                                                IsSale ,
                                                IsHold ,
                                                a.ProjGUID ,
                                                a.VersionTypeName
                                       FROM dbo.mdm_DWProductHistory a) pd ON pd.ProjGUID = a.ProjGUID AND pd.ProductGUID = a.ProductGUID --AND pd.IsSale = '是'
                                                                              AND  pd.VersionTypeName = a.VersionTypeName   --add AND pd.VersionTypeName= a.VersionTypeName by hegj01 20211101
                     WHERE  b.CostName IN ('总成本（含税，计划）', '税前利润（计划）', '税后利润（计划）', '1、土地成本', '除土地外直接投资（含税）', '财务费用（计划）', '4、营销费用', '5、管理费用', '销售收入（含税）')

SELECT    ProjGUID ,  --ProductGUID,
                                    --VersionGUID,
                        VersionTypeName AS VerName ,
                        ProductType ,
                        productname ,
                        SUM(YtTotalCostAmount) AS YtTotalCostAmount ,
                        CASE WHEN ISNULL(SUM(YtTotalCostAmount), 0) <> 0 THEN SUM(YtBeforeProfit) / SUM(YtTotalCostAmount)ELSE 0 END AS YtBeforeCostRate ,
                        SUM(YtBeforeProfit) AS YtBeforeProfit ,
                        SUM(YtAfterProfit) AS YtAfterProfit ,
                        0 AS YtAfterCashProfit ,
                        SUM(YtLandAmount) AS YtLandAmount ,
                        SUM(YtZtAmount) AS YtZtAmount ,
                        SUM(YtExpenses) AS YtExpenses ,
                        MAX(YtSalePice) AS YtSalePice ,
                        MAX(YtSynPice) AS YtSynPice ,
                        SUM(YtSynSaleAmount) AS YtSynSaleAmount ,
                        SUM(ISNULL(YtFixedAssets, 0)) AS YtFixedAssets ,
                        SUM(zhz) AS zhz ,
                        pd_IsSale   --add ,pd_IsSale by hegj01 20211103
              into #PositioningCost
			  FROM #temp
			  GROUP BY projGUID ,
                       VersionTypeName ,
                       ProductType ,
                       productname ,
                       pd_IsSale
--立项版
SELECT  ProjVerNew.ProjVerGUID AS VerGUID ,
        ProjVerNew.VerName AS VerName ,
        ProjVerNew.CreatedOn AS VersionDate ,
        '立项版' AS EditonType ,
        1 AS IsBase ,
        unit.BUGUID ,
        unit.BUName ,
        unit.BUCode ,
        pproj.ProjGUID AS ParentProjguid ,
        pproj.ProjName AS ParentProjName ,
        pproj.ProjCode AS ParentProjCode ,
        proj.ProjGUID ,
        proj.ProjName ,
        proj.ProjCode ,
        proj.Level ,
        ttp.ProductType AS YtName ,
        NULL ProductGUID ,
        ppci.YtTotalCostAmount ,
        pii.YtBeforeCostRate ,
        pii.YtBeforeProfit ,
        pii.YtAfterProfit ,
        pii.YtAfterCashProfit ,
        ttp.JzArea AS YtBldArea ,
        ttp.DsArea AS YtUpBldArea ,
        ttp.YtDownBldArea ,
        ppci.YtLandAmount ,
        ppci.YtZtAmount ,
        ppci.YtExpenses ,
        CASE WHEN ISNULL(pii.zksmj, 0) = 0 THEN 0 ELSE ppci.总投资合计 / ISNULL(pii.zksmj, 0)END YtSalePice ,
        CASE WHEN ISNULL(ttp.JzArea, 0) = 0 THEN 0 ELSE ppci.总投资合计 / ISNULL(ttp.JzArea, 0)END AS YtBldPice ,
        CASE WHEN ISNULL(pii.zksmj, 0) = 0 THEN 0 ELSE pii.YtSynSaleAmount / ISNULL(pii.zksmj, 0)END YtSynPice ,
        pii.YtSynSaleAmount ,
        pii.YtFixedAssets ,
        xjlhz.SxzxjlDate ,
        xjlhz.ShgdtzDate ,
        pii.zhz ,
        pii.zksmj ,
		pii.carnum,
        ttp.ProductName ,
        pii.issale ,
        ttp.JrArea AS YtJrArea,
		ppci.ytksarea cbYtSalePice
FROM(SELECT *
     FROM   (SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreatedOn DESC) AS num ,
                    ProjVerGUID ,
                    ProjGUID ,
                    CreatedOn ,
                    VerName
             FROM   mdm_ProjVerNew) ver
     WHERE  ver.num = 1) ProjVerNew
    INNER  JOIN mdm_Project proj ON proj.ProjGUID = ProjVerNew.ProjGUID
    INNER  JOIN myBusinessUnit unit ON proj.OrgCompanyGUID = unit.BUGUID
    LEFT JOIN mdm_Project pproj ON proj.ParentProjGUID = pproj.ProjGUID
    LEFT JOIN(SELECT    ProjGUID ,
                                    --ProductGUID ,
                        ProductType ,
                        ProductName ,
                        IsSale ,    --add IsSale, by hegj 20211109
                        SUM(JzArea) AS JzArea ,
                        SUM(ISNULL(JzArea, 0) - ISNULL(DsArea, 0)) AS YtDownBldArea ,
                        SUM(DsArea) AS DsArea ,
                        SUM(JrArea) AS JrArea
              FROM  mdm_TechTargetProduct
              GROUP BY ProjGUID ,
                       ProductName ,
                       ProductType ,
                       IsSale   --add ,IsSale by hegj 20211109
    ) ttp ON ttp.ProjGUID = ProjVerNew.ProjGUID
    LEFT JOIN(SELECT    a.ProjGUID ,
                                                                                                                                                                                                                            -- pd.ProductGUID ,
                        pd.ProductName ,
                        issale ,
                        SUM(CASE WHEN b.CostShortName IN ('总投资合计') THEN a.CostMoney * 10000 ELSE 0 END) AS YtTotalCostAmount ,
                        SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney * 10000 ELSE 0 END) AS YtLandAmount ,
                        ISNULL(SUM(CASE WHEN b.CostShortName = '直接投资合计' THEN a.CostMoney * 10000 ELSE 0 END), 0) - ISNULL(SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney * 10000 ELSE 0 END), 0) AS YtZtAmount ,    --直接投资合计-土地款
                        SUM(CASE WHEN b.CostShortName IN ('营销费用', '管理费用', '财务费用') THEN a.CostMoney * 10000 ELSE 0 END) AS YtExpenses ,
                        MAX(CASE WHEN b.CostShortName IN ('总可售单方') THEN a.BuildAreaCostMoney ELSE 0 END) AS YtSalePice ,
                        SUM(CASE WHEN b.CostShortName IN ('总投资合计') THEN a.CostMoney * 10000 ELSE 0 END) AS 总投资合计,
						SUM(CASE WHEN b.CostShortName IN ('总投资合计') THEN ISNULL(a.CostMoney * 10000/NULLIF(a.BuildAreaCostMoney,0),0) ELSE 0 END) AS ytksarea
              FROM  dbo.mdm_ProjProductCostIndex a
                    INNER JOIN mdm_TechTargetProduct pd ON a.ProjGUID = pd.ProjGUID AND a.ProductGUID = pd.ProductGUID
                    INNER JOIN mdm_CostIndex b ON a.CostGuid = b.CostGUID
              --20211027 by 善章 成本指标剔除不可售、不自持业态
              WHERE (IsSale = '可售' OR   isHold = '自持')
              GROUP BY a.ProjGUID ,
                       pd.ProductName ,
                       ProductType ,
                       issale) ppci ON ppci.ProjGUID = ProjVerNew.ProjGUID AND  ppci.ProductName = ttp.ProductName AND  ppci.issale = ttp.issale
    LEFT JOIN(SELECT    b.ProjGUID ,
                        b.ProductName ,
                        issale ,
                                                                        --SUM(PreTaxCostProfitRate) AS YtBeforeCostRate , --mark by hegj01 20211104 改为取最大值
                        MAX(PreTaxCostProfitRate) AS YtBeforeCostRate , --add MAX(PreTaxCostProfitRate) AS YtBeforeCostRate , by hegj01 20211104 取最大值
                        SUM(PreTaxProfit) * 10000 AS YtBeforeProfit ,
                        SUM(AfterTaxProfit) * 10000 AS YtAfterProfit ,
                        SUM(CashProfit) * 10000 AS YtAfterCashProfit ,
                        MAX(EstimatedSellingPrice) AS YtSynPice ,
                        SUM(CashInflowTax) * 10000 AS YtSynSaleAmount ,
                        SUM(FixedAssetsTwo) * 10000 AS YtFixedAssets ,
                        SUM(CASE WHEN isHold = '不自持' AND   issale = '可售' THEN CashInflowTax ELSE 0 END) * 10000 AS zhz ,
                        SUM(CASE WHEN isHold = '不自持' AND   issale = '可售' THEN KsArea ELSE 0 END) AS zksmj,
						SUM(CASE WHEN isHold = '不自持' AND   issale = '可售' THEN HbgNum ELSE 0 END) AS carnum
              FROM  mdm_ProjectIncomeIndex a
                    INNER JOIN mdm_TechTargetProduct b ON a.ProjGUID = b.ProjGUID AND   a.ProductGUID = b.ProductGUID
              GROUP BY b.ProjGUID ,
                       b.ProductName ,
                       issale) pii ON pii.ProjGUID = ProjVerNew.ProjGUID AND pii.ProductName = ttp.ProductName AND  pii.IsSale = ttp.IsSale --add and pii.IsSale = ttp.IsSale by hegj 20211109
    LEFT JOIN(SELECT    ProjGUID, ShgdtzDate, SxzxjlDate FROM   mdm_ProjectNodeIndex) xjlhz ON xjlhz.ProjGUID = ProjVerNew.ProjGUID
UNION ALL
SELECT  VerGUID ,
        temp_a.VerName ,
        VersionDate ,
        '定位版' AS EditonType ,
        IsBase ,
        unit.BUGUID ,
        unit.BUName ,
        unit.BUCode ,
        pproj.ProjGUID AS ParentProjguid ,
        pproj.ProjName AS ParentProjName ,
        pproj.ProjCode AS ParentProjCode ,
        proj.ProjGUID ,
        proj.ProjName ,
        proj.ProjCode ,
        proj.Level ,
        YtName ,
        NULL AS ProductGUID ,
        YtTotalCostAmount ,
        YtBeforeCostRate ,
        YtBeforeProfit ,
        YtAfterProfit ,
        YtAfterCashProfit ,
        YtBldArea ,
        YtUpBldArea ,
        YtDownBldArea ,
        YtLandAmount ,
        YtZtAmount ,
        YtExpenses ,
        CASE WHEN ISNULL(temp_jj.zksmj, 0) <> 0 THEN YtTotalCostAmount / temp_jj.zksmj ELSE 0 END AS YtSalePice ,
        CASE WHEN ISNULL(YtBldArea, 0) <> 0 THEN YtTotalCostAmount / YtBldArea ELSE 0 END AS YtBldPice ,
        --,CASE WHEN ISNULL(zksmj,0)<>0 then YtSynSaleAmount/zksmj ELSE 0 end as YtSynPice
        ISNULL(temp_jj.YtSynPice, 0) YtSynPice ,
        YtSynSaleAmount ,
        YtFixedAssets ,
        jyx.CurIRRCashDate SxzxjlDate ,
        gd.CurSelfCashDate ShgdtzDate ,
        zhz ,
        ISNULL(temp_jj.zksmj, 0) zksmj ,
		temp_a.HbgNum as carnum,
        temp_a.ProductName ,
        CASE WHEN temp_a.issale = '是' THEN '可售' ELSE '不可售' END AS issale ,
        YtJrArea,
		CASE WHEN ISNULL(temp_jj.zksmj, 0) <> 0 THEN YtTotalCostAmount / temp_jj.zksmj ELSE 0 END cbYtSalePice
		
FROM  #temp_a temp_a
    LEFT JOIN #temp_jj temp_jj ON temp_jj.versiontype = temp_a.VerName AND  temp_jj.ProjGUID = temp_a.ProjGUID AND  temp_jj.producttype = temp_a.YtName
                                          AND temp_jj.productname = temp_a.ProductName AND temp_a.issale = temp_jj.issale
	--LEFT JOIN #dwCarQH QH on QH.ProjGUID=temp_a.ProjGUID AND	QH.producttype = temp_a.YtName AND QH.productname =temp_a.productname AND QH.issale =temp_a.issale  								 
    LEFT JOIN #PositioningCost PositioningCost ON PositioningCost.ProjGUID = temp_a.ProjGUID AND
    --PositioningCost.ProductGUID= temp_a.ProductGUID and
    --PositioningCost.VersionGUID= temp_a.VersionGUID and
    PositioningCost.VerName = temp_a.VerName AND PositioningCost.ProductName = temp_a.ProductName AND   PositioningCost.pd_IsSale = temp_a.issale --add AND PositioningCost.pd_IsSale = temp_a.issale by hegj01 20211103 增加是否可售的关联
    INNER  JOIN mdm_Project proj ON proj.ProjGUID = temp_a.ProjGUID
    INNER  JOIN myBusinessUnit unit ON proj.OrgCompanyGUID = unit.BUGUID
    LEFT JOIN mdm_Project pproj ON proj.ParentProjGUID = pproj.ProjGUID
    --经营性现金流回正时间 
    LEFT JOIN(SELECT    ProjGUID ,
                        VersionTypeName ,
                        MIN(cashDate) AS CurIRRCashDate
              FROM  #t1
              WHERE 累计经营性现金流 > 0
              GROUP BY ProjGUID ,
                       VersionTypeName) jyx ON jyx.ProjGUID = temp_a.ProjGUID AND   jyx.VersionTypeName = temp_a.VerName
    --股东投资回收回正时间
    LEFT JOIN(SELECT    ProjGUID ,
                        VersionTypeName ,
                        MIN(cashDate) AS CurSelfCashDate
              FROM  #t1
              WHERE 股东回收现金流 > 0
              GROUP BY ProjGUID ,
                       VersionTypeName) gd ON gd.ProjGUID = temp_a.ProjGUID AND gd.VersionTypeName = temp_a.VerName
	--WHERE  unit.BUName IN  ('华南公司')
DROP TABLE #t1,#PositioningCost,#temp,#temp_a,#temp_jj
