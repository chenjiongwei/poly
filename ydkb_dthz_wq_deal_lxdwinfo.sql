USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_dthz_wq_deal_lxdwinfo]    Script Date: 2024/10/17 15:15:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_ydkb_dthz_wq_deal_lxdwinfo]
AS
/*
author:ltx  date:20200525

运行样例：[usp_ydkb_dthz_wq_deal_lxdwinfo]

modify:lintx  date:20220608
1、增加立项的总建筑面积，地下建筑面积；取投管系统
2、增加定位的总建筑面积，地下建筑面积；总建筑面积取投管，地下建筑面积取基础系统

modify:lintx date:20221013
1、原有定位指标版本调整为取上报版（二次上报版>上报版）
2、新增定位批复版指标（二次批复版>上报版）

modify:lintx date:20231201
1、增加产品级别的指标情况
2、增加土地成本
3、增加最新版定位信息：有批复取批复，若无取上报版

modify:lintx date:20231212
1、立项定位业态层级数据可能会存在关联丢失的情况，所以项目层级的数据改成从总计取数

modify:lintx date:20240618
1、新增指标：
立项可售住宅户数、立项可售车位面积、立项可售车位个数、立项自有资金内部收益率、立项实际开工时间、立项竣工时间、立项交付时间、定位财务费用账面

*/
BEGIN
    ---------------------参数设置------------------------
    DECLARE @bnYear VARCHAR(4) = YEAR(GETDATE());
    DECLARE @byMonth VARCHAR(2) = MONTH(GETDATE());
    DECLARE @buguid VARCHAR(max) = '248B1E17-AACB-E511-80B8-E41F13C51836,4975b69c-9953-4dd0-a65e-9a36db8c66df';
    DECLARE @developmentguid VARCHAR(max) = 'C69E89BB-A2DB-E511-80B8-E41F13C51836,461889dc-e991-4238-9d7c-b29e0aa347bb';

    ---------------------缓存定位指标版本信息---------------------
    --缓存项目信息

    SELECT pj.*
    INTO #mdm_project
    FROM dbo.mdm_Project pj
    WHERE pj.DevelopmentCompanyGUID IN (SELECT Value FROM dbo.fn_Split2(@developmentguid, ','));

    SELECT p.ProjGUID,
           VersionGUID,
           VersionTypeName,
           '上报版' AS dw_ver
    INTO #dw_ver
    FROM mdm_Project p
        INNER JOIN
        (SELECT v.VersionGUID,
          v.VersionTypeName,
          v.ProjGUID,
          ROW_NUMBER() OVER (PARTITION BY p.ProjGUID
              ORDER BY CASE WHEN ISNULL(VersionTypeName, '') = '二次定位上报版' THEN
                               3
                           WHEN ISNULL(VersionTypeName, '') = '定位上报版' THEN
                               1
                           ELSE
                               0
                       END DESC,
                       CreateDate DESC
             ) num
           FROM dbo.mdm_DWProjVer v
               INNER JOIN #mdm_project p
                   ON p.ProjGUID = v.ProjGUID
        ) ver
            ON ver.ProjGUID = p.ProjGUID
               AND num = 1
    WHERE DevelopmentCompanyGUID IN (
                                        SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
                                    )
          AND p.Level = 2
          AND VersionTypeName LIKE '%上报版%'
    UNION ALL
    SELECT p.ProjGUID,
           VersionGUID,
           VersionTypeName,
           '批复版' AS dw_ver
    FROM mdm_Project p
        INNER JOIN
        (
            SELECT v.VersionGUID,
                   v.VersionTypeName,
                   v.ProjGUID,
                   ROW_NUMBER() OVER (PARTITION BY p.ProjGUID
                                      ORDER BY CASE
                                                   WHEN ISNULL(VersionTypeName, '') = '二次定位批复版' THEN
                                                       4
                                                   WHEN ISNULL(VersionTypeName, '') = '定位批复版' THEN
                                                       2
                                                   ELSE
                                                       0
                                               END DESC,
                                               CreateDate DESC
                                     ) num
            FROM dbo.mdm_DWProjVer v
                INNER JOIN #mdm_project p
                    ON p.ProjGUID = v.ProjGUID
        ) ver
            ON ver.ProjGUID = p.ProjGUID
               AND num = 1
    WHERE DevelopmentCompanyGUID IN (
                                        SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
                                    )
          AND p.Level = 2
          AND VersionTypeName LIKE '%批复版%';

    SELECT p.ProjGUID,
           VersionGUID,
           VersionTypeName,
           case when VersionTypeName  LIKE '%批复版%' then '批复版' else '上报版' end as vername
    INTO #dw_ver_summary
    FROM mdm_Project p
        INNER JOIN
        (SELECT v.VersionGUID,
          v.VersionTypeName,
          v.ProjGUID,
          ROW_NUMBER() OVER (PARTITION BY p.ProjGUID
              ORDER BY CASE WHEN ISNULL(VersionTypeName, '') = '二次定位批复版' THEN
                                                       4 
                            WHEN ISNULL(VersionTypeName, '') = '二次定位上报版' THEN
                               3
                            WHEN ISNULL(VersionTypeName, '') = '定位批复版' THEN
                                                       2
                           WHEN ISNULL(VersionTypeName, '') = '定位上报版' THEN
                               1
                           ELSE
                               0
                       END DESC,
                       CreateDate DESC
             ) num
           FROM dbo.mdm_DWProjVer v
               INNER JOIN #mdm_project p
                   ON p.ProjGUID = v.ProjGUID
        ) ver
            ON ver.ProjGUID = p.ProjGUID
               AND num = 1
    WHERE DevelopmentCompanyGUID IN (
                                        SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
                                    )
    AND p.Level = 2 

    ---------------------产品粒度统计---------------------

    ----------------------------获取定位、立项单价 begin----------------------------
    SELECT lx.ProjGUID,
           lx.ProductType,
           lx.ProductName,	
           lx.BusinessType,	
           lx.Standard, 
           SUM(ISNULL(lx.SaleableArea, 0)) as 可售面积,
           SUM(ISNULL(LxZhz, 0) * 10000.0) as 立项货值,
           CASE WHEN SUM(ISNULL(lx.SaleableArea, 0)) = 0 THEN 0
               ELSE SUM(ISNULL(LxZhz, 0) * 10000.0) / SUM(ISNULL(lx.SaleableArea, 0))
           END AS 立项单价
    INTO #lxprice_cp
    FROM dbo.vmdm_lxproductPrice lx
        INNER JOIN #mdm_project pj
            ON lx.ProjGUID = pj.ProjGUID
    WHERE ISNULL(lx.LxZksmj, 0) <> 0
    GROUP BY lx.ProjGUID, lx.ProductType,lx.ProductName,lx.BusinessType,lx.Standard; 

    SELECT lx.ProjGUID,
           lx.ProductType, 
           SUM(ISNULL(lx.SaleableArea, 0)) as 可售面积,
           SUM(ISNULL(LxZhz, 0) * 10000.0) as 立项货值,
           CASE WHEN SUM(ISNULL(lx.SaleableArea, 0)) = 0 THEN 0
               ELSE SUM(ISNULL(LxZhz, 0) * 10000.0) / SUM(ISNULL(lx.SaleableArea, 0))
           END AS 立项单价
    INTO #lxprice
    FROM dbo.vmdm_lxproductPrice lx
        INNER JOIN #mdm_project pj
            ON lx.ProjGUID = pj.ProjGUID
    WHERE ISNULL(lx.LxZksmj, 0) <> 0
    GROUP BY lx.ProjGUID, lx.ProductType;  

    SELECT dw.ProjGUID,
           ProductType,
           ProductName,	
           BusinessType,
           Standard ,
           CASE WHEN SUM(ISNULL(DwZksmj, 0)) = 0 THEN 0 ELSE
                   SUM(ISNULL(DwZhz, 0) * 10000.0) / SUM(ISNULL(DwZksmj, 0))
           END AS 定位单价,
           CASE  WHEN SUM(ISNULL(PfDwZksmj, 0)) = 0 THEN 0 ELSE
                   SUM(ISNULL(PfDwZhz, 0) * 10000.0) / SUM(ISNULL(PfDwZksmj, 0))
           END AS 定位批复版单价
    INTO #dwprice_cp
    FROM
    (
        SELECT pe.ProjGUID,
               CASE
                   WHEN ver.dw_ver = '上报版' THEN
                       mj.SaleArea
                   ELSE
                       0
               END AS DwZksmj,   -- 上报版总可售面积
               CASE
                   WHEN ver.dw_ver = '上报版' THEN
                       pe.TotalPrice
                   ELSE
                       0
               END DwZhz,        --上报版总货值
               CASE
                   WHEN ver.dw_ver = '批复版' THEN
                       mj.SaleArea
                   ELSE
                       0
               END AS PfDwZksmj, -- 批复版总可售面积
               CASE
                   WHEN ver.dw_ver = '批复版' THEN
                       pe.TotalPrice
                   ELSE
                       0
               END PfDwZhz,      --批复版总货值
               pr.ProductType,
               pr.ProductName,	
               pr.BusinessType,
               pr.Standard 
        FROM mdm_Project p
            INNER JOIN dbo.mdm_ProductEarningsProfit pe
                ON pe.ProjGUID = p.ProjGUID
            LEFT JOIN dbo.mdm_ProductEarningsArea mj
                ON mj.VersionGUID = pe.VersionGUID
                   AND pe.ProductGUID = mj.ProductGUID
            INNER JOIN dbo.mdm_PositioningCost mc
                ON mc.CostGUID = pe.CostGUID
                   AND mc.CostName = '销售收入（含税）'
            INNER JOIN mdm_DWProduct pr
                ON pe.ProjGUID = pr.ProjGUID
                   AND pe.ProductGUID = pr.ProductGUID
            INNER JOIN #dw_ver ver
                ON ver.ProjGUID = pe.ProjGUID
                   AND ver.VersionGUID = pe.VersionGUID
        WHERE pe.ProductGUID NOT IN ( '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
                                      '00000000-0000-0000-0000-000000000000'
                                    )
    ) dw
    GROUP BY dw.ProjGUID, ProductType,ProductName,BusinessType,Standard ;


    SELECT dw.ProjGUID,
           ProductType, 
           CASE WHEN SUM(ISNULL(DwZksmj, 0)) = 0 THEN 0 ELSE
                   SUM(ISNULL(DwZhz, 0) * 10000.0) / SUM(ISNULL(DwZksmj, 0))
           END AS 定位单价,
           CASE  WHEN SUM(ISNULL(PfDwZksmj, 0)) = 0 THEN 0 ELSE
                   SUM(ISNULL(PfDwZhz, 0) * 10000.0) / SUM(ISNULL(PfDwZksmj, 0))
           END AS 定位批复版单价
    INTO #dwprice
    FROM
    (
        SELECT pe.ProjGUID,
               CASE
                   WHEN ver.dw_ver = '上报版' THEN
                       mj.SaleArea
                   ELSE
                       0
               END AS DwZksmj,   -- 上报版总可售面积
               CASE
                   WHEN ver.dw_ver = '上报版' THEN
                       pe.TotalPrice
                   ELSE
                       0
               END DwZhz,        --上报版总货值
               CASE
                   WHEN ver.dw_ver = '批复版' THEN
                       mj.SaleArea
                   ELSE
                       0
               END AS PfDwZksmj, -- 批复版总可售面积
               CASE
                   WHEN ver.dw_ver = '批复版' THEN
                       pe.TotalPrice
                   ELSE
                       0
               END PfDwZhz,      --批复版总货值
               pr.ProductType,
               pr.ProductName,	
               pr.BusinessType,
               pr.Standard 
        FROM mdm_Project p
            INNER JOIN dbo.mdm_ProductEarningsProfit pe
                ON pe.ProjGUID = p.ProjGUID
            LEFT JOIN dbo.mdm_ProductEarningsArea mj
                ON mj.VersionGUID = pe.VersionGUID
                   AND pe.ProductGUID = mj.ProductGUID
            INNER JOIN dbo.mdm_PositioningCost mc
                ON mc.CostGUID = pe.CostGUID
                   AND mc.CostName = '销售收入（含税）'
            INNER JOIN mdm_DWProduct pr
                ON pe.ProjGUID = pr.ProjGUID
                   AND pe.ProductGUID = pr.ProductGUID
            INNER JOIN #dw_ver ver
                ON ver.ProjGUID = pe.ProjGUID
                   AND ver.VersionGUID = pe.VersionGUID
        WHERE pe.ProductGUID NOT IN ( '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
                                      '00000000-0000-0000-0000-000000000000'
                                    )
    ) dw
    GROUP BY dw.ProjGUID, ProductType ;
    ----------------------------获取定位、立项指标 begin----------------------------
    --立项定位指标:车位的可售面积只在业态层级统计
    SELECT Pd.ProjGUID,
           ProductType,Pd.ProductName, Pd.BusinessType, Pd.Standard ,
           SUM(ISNULL(Pd.KsArea, 0)) AS 可售面积,
           SUM(ISNULL(Pd.JzArea, 0)) AS 总建筑面积,
           sum(isnull(pd.HbgNum,0)) 套数,
           SUM(ISNULL(Pd.JzArea, 0) - ISNULL(Pd.DsArea, 0)) AS 地下建筑面积,
           sum(case when Pd.ProductType in ('住宅','高级住宅','别墅') and issale = '可售' then isnull(pd.HbgNum,0) else 0 end) 立项可售住宅户数 ,
           sum(case when Pd.ProductType in ('地下室/车库') and issale = '可售' then isnull(Pd.KsArea,0) else 0 end) 立项可售车位面积,	
           sum(case when Pd.ProductType in ('地下室/车库') and issale = '可售' then isnull(Pd.HbgNum,0) else 0 end) 立项可售车位个数
    INTO #lxmj_cp
    FROM mdm_TechTargetProduct Pd
        INNER JOIN #mdm_project pj
            ON Pd.ProjGUID = pj.ProjGUID
    GROUP BY Pd.ProjGUID, ProductType, Pd.ProductName, Pd.BusinessType, Pd.Standard ;

    SELECT Pd.ProjGUID,
           ProductType,
           SUM(ISNULL(Pd.KsArea, 0)) AS 可售面积,
           SUM(ISNULL(Pd.JzArea, 0)) AS 总建筑面积,
           sum(isnull(pd.HbgNum,0)) 套数,
           SUM(ISNULL(Pd.JzArea, 0) - ISNULL(Pd.DsArea, 0)) AS 地下建筑面积,
           sum(case when Pd.ProductType in ('住宅','高级住宅','别墅') and issale = '可售' then isnull(pd.HbgNum,0) else 0 end) 立项可售住宅户数 ,
           sum(case when Pd.ProductType in ('地下室/车库') and issale = '可售' then isnull(Pd.KsArea,0) else 0 end) 立项可售车位面积,	
           sum(case when Pd.ProductType in ('地下室/车库') and issale = '可售' then isnull(Pd.HbgNum,0) else 0 end) 立项可售车位个数
    INTO #lxmj
    FROM mdm_TechTargetProduct Pd
        INNER JOIN #mdm_project pj
            ON Pd.ProjGUID = pj.ProjGUID
    GROUP BY Pd.ProjGUID,  ProductType;

    SELECT Pd.ProjGUID,
           SUM(ISNULL(Pd.KsAreaTotal, 0)) AS 可售面积,
           SUM(ISNULL(Pd.JzAreaTotal, 0)) AS 总建筑面积,
           sum(isnull(pd.HbgNum_sale,0)) 套数,
           SUM(ISNULL(Pd.DxJZArea, 0)) AS 地下建筑面积,
           sum(isnull(yt.立项可售住宅户数,0)) as 立项可售住宅户数,
           sum(isnull(yt.立项可售车位面积,0)) as 立项可售车位面积,
           sum(isnull(yt.立项可售车位个数,0)) as 立项可售车位个数
    INTO #lxmj_proj
    FROM mdm_TechTarget Pd
        INNER JOIN #mdm_project pj
            ON Pd.ProjGUID = pj.ProjGUID
        left join (
            select projguid,sum(isnull(立项可售住宅户数,0)) as 立项可售住宅户数,sum(isnull(立项可售车位面积,0)) as 立项可售车位面积,
            sum(isnull(立项可售车位个数,0)) as 立项可售车位个数 from  #lxmj group by projguid 
        )yt on yt.projguid = pd.projguid
    GROUP BY Pd.ProjGUID;

	select * from mdm_TechTarget

    --成本指标
    SELECT a.ProjGUID,
           pd.ProductType,Pd.ProductName, Pd.BusinessType, Pd.Standard ,
           SUM(CASE WHEN b.CostShortName IN ( '总投资合计' ) THEN a.CostMoney ELSE 0 END ) AS 总投资,
           SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney ELSE  0 END ) as 土地款,
           --直接投资合计-土地款
           ISNULL(SUM(CASE WHEN b.CostShortName = '直接投资合计' THEN a.CostMoney ELSE  0 END ), 0 ) - 
                ISNULL(SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney ELSE  0 END ), 0 ) AS 除地价外直投,
           SUM(CASE WHEN b.CostShortName IN ('管理费用') THEN  a.CostMoney ELSE 0 END ) AS 管理费用,
           SUM(CASE WHEN b.CostShortName IN ('营销费用') THEN  a.CostMoney ELSE 0 END ) AS 营销费用,
           SUM(CASE WHEN b.CostShortName IN ('财务费用') THEN  a.CostMoney ELSE 0 END ) AS 财务费用
    INTO #lx_cb_cp
    FROM dbo.mdm_ProjProductCostIndex a
        INNER JOIN mdm_TechTargetProduct pd
            ON a.ProjGUID = pd.ProjGUID
               AND a.ProductGUID = pd.ProductGUID
        INNER JOIN mdm_CostIndex b
            ON a.CostGuid = b.CostGUID
        INNER JOIN #mdm_project pj
            ON pj.ProjGUID = a.ProjGUID
    GROUP BY a.ProjGUID,
             ProductType,Pd.ProductName, Pd.BusinessType, Pd.Standard;
    
    SELECT a.ProjGUID,
           pd.ProductType ,
           SUM(CASE WHEN b.CostShortName IN ( '总投资合计' ) THEN a.CostMoney ELSE 0 END ) AS 总投资,
           SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney  ELSE 0 END ) as 土地款,
           ISNULL(SUM(   CASE
                             WHEN b.CostShortName = '直接投资合计' THEN
                                 a.CostMoney
                             ELSE
                                 0
                         END
                     ),
                  0
                 ) - ISNULL(SUM(   CASE
                                       WHEN b.CostShortName = '土地款' THEN
                                           a.CostMoney
                                       ELSE
                                           0
                                   END
                               ),
                            0
                           ) AS 除地价外直投,
           --直接投资合计-土地款

           SUM(   CASE
                      WHEN b.CostShortName IN ( '管理费用' ) THEN
                          a.CostMoney
                      ELSE
                          0
                  END
              ) AS 管理费用,
           SUM(   CASE
                      WHEN b.CostShortName IN ( '营销费用' ) THEN
                          a.CostMoney
                      ELSE
                          0
                  END
              ) AS 营销费用,
           SUM(   CASE
                      WHEN b.CostShortName IN ( '财务费用' ) THEN
                          a.CostMoney
                      ELSE
                          0
                  END
              ) AS 财务费用
    INTO #lx_cb
    FROM dbo.mdm_ProjProductCostIndex a
        INNER JOIN mdm_TechTargetProduct pd
            ON a.ProjGUID = pd.ProjGUID
               AND a.ProductGUID = pd.ProductGUID
        INNER JOIN mdm_CostIndex b
            ON a.CostGuid = b.CostGUID
        INNER JOIN #mdm_project pj
            ON pj.ProjGUID = a.ProjGUID
    GROUP BY a.ProjGUID, ProductType;

      SELECT a.ProjGUID,
           SUM(CASE WHEN b.CostShortName IN ( '总投资合计' ) THEN a.CostMoney ELSE 0 END ) AS 总投资,
           SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney  ELSE 0 END ) as 土地款,
           ISNULL(SUM(   CASE
                             WHEN b.CostShortName = '直接投资合计' THEN
                                 a.CostMoney
                             ELSE
                                 0
                         END
                     ),
                  0
                 ) - ISNULL(SUM(   CASE
                                       WHEN b.CostShortName = '土地款' THEN
                                           a.CostMoney
                                       ELSE
                                           0
                                   END
                               ),
                            0
                           ) AS 除地价外直投,
           --直接投资合计-土地款

           SUM(   CASE
                      WHEN b.CostShortName IN ( '管理费用' ) THEN
                          a.CostMoney
                      ELSE
                          0
                  END
              ) AS 管理费用,
           SUM(   CASE
                      WHEN b.CostShortName IN ( '营销费用' ) THEN
                          a.CostMoney
                      ELSE
                          0
                  END
              ) AS 营销费用,
           SUM(   CASE
                      WHEN b.CostShortName IN ( '财务费用' ) THEN
                          a.CostMoney
                      ELSE
                          0
                  END
              ) AS 财务费用
    INTO #lx_cb_proj
    FROM dbo.mdm_ProjProductCostIndex a
        INNER JOIN mdm_CostIndex b
            ON a.CostGuid = b.CostGUID
        INNER JOIN #mdm_project pj
            ON pj.ProjGUID = a.ProjGUID
		where a.ProductGUID = '00000000-0000-0000-0000-000000000000'
    GROUP BY a.ProjGUID;

    --利润指标
    --货值  税前利润 税后利润 税后现金利润
    SELECT b.ProjGUID,
           b.ProductType,
           b.ProductName, b.BusinessType, b.Standard ,
           SUM(CashInflowTax) 货值,
           SUM(PreTaxProfit) 税前利润,
           SUM(AfterTaxProfit) 税后利润,
           SUM(CashProfit) 税后现金利润,
           sum(FixedAssetsOne) 固定资产
    INTO #lx_lr_cp
    FROM mdm_ProjectIncomeIndex a
        INNER JOIN mdm_TechTargetProduct b
            ON a.ProjGUID = b.ProjGUID
               AND a.ProductGUID = b.ProductGUID
        INNER JOIN #mdm_project pj
            ON pj.ProjGUID = b.ProjGUID
    GROUP BY b.ProjGUID,
             b.ProductType,b.ProductName, b.BusinessType, b.Standard;
    
    SELECT b.ProjGUID,
           b.ProductType, 
           SUM(CashInflowTax) 货值,
           SUM(PreTaxProfit) 税前利润,
           SUM(AfterTaxProfit) 税后利润,
           SUM(CashProfit) 税后现金利润,
           sum(FixedAssetsOne) 固定资产
    INTO #lx_lr
    FROM mdm_ProjectIncomeIndex a
        INNER JOIN mdm_TechTargetProduct b
            ON a.ProjGUID = b.ProjGUID
               AND a.ProductGUID = b.ProductGUID
        INNER JOIN #mdm_project pj
            ON pj.ProjGUID = b.ProjGUID
    GROUP BY b.ProjGUID,b.ProductType;

    SELECT a.ProjGUID,
           SUM(CashInflowTax) 货值,
           SUM(PreTaxProfit) 税前利润,
           SUM(AfterTaxProfit) 税后利润,
           SUM(CashProfit) 税后现金利润,
           sum(FixedAssetsOne) 固定资产
    INTO #lx_lr_proj
    FROM mdm_ProjectIncomeIndex a
        INNER JOIN #mdm_project pj
            ON pj.ProjGUID = a.ProjGUID
    where a.ProductGUID = '00000000-0000-0000-0000-000000000000' 
    GROUP BY a.ProjGUID;

    ------------------------------定位指标
    SELECT t.ProjGUID,
           t.ProductType,t.ProductName, t.BusinessType, t.Standard ,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.可售面积
                      ELSE
                          0
                  END
              ) AS 可售面积,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.总建筑面积
                      ELSE
                          0
                  END
              ) AS 总建筑面积,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.货值
                      ELSE
                          0
                  END
              ) AS 货值,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.总投资
                      ELSE
                          0
                  END
              ) AS 总投资,
            SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.土地款
                      ELSE
                          0
                  END
              ) AS 土地款,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.除地价外直投
                      ELSE
                          0
                  END
              ) AS 除地价外直投,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.营销费用
                      ELSE
                          0
                  END
              ) AS 营销费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.财务费用
                      ELSE
                          0
                  END
              ) AS 财务费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.财务费用账面口径
                      ELSE
                          0
                  END
              ) AS 财务费用账面口径,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.管理费用
                      ELSE
                          0
                  END
              ) AS 管理费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税前利润
                      ELSE
                          0
                  END
              ) AS 税前利润,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税后利润
                      ELSE
                          0
                  END
              ) AS 税后利润,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税后现金利润
                      ELSE
                          0
                  END
              ) AS 税后现金利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.可售面积
                      ELSE
                          0
                  END
              ) AS 定位批复版可售面积,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.总建筑面积
                      ELSE
                          0
                  END
              ) AS 定位批复版总建筑面积,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.货值
                      ELSE
                          0
                  END
              ) AS 定位批复版货值,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.总投资
                      ELSE
                          0
                  END
              ) AS 定位批复版总投资,
            SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.土地款
                      ELSE
                          0
                  END
              ) AS 定位批复版土地款,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.除地价外直投
                      ELSE
                          0
                  END
              ) AS 定位批复版除地价外直投,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.营销费用
                      ELSE
                          0
                  END
              ) AS 定位批复版营销费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.财务费用
                      ELSE
                          0
                  END
              ) AS 定位批复版财务费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.财务费用账面口径
                      ELSE
                          0
                  END
              ) AS 定位批复版财务费用账面口径,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.管理费用
                      ELSE
                          0
                  END
              ) AS 定位批复版管理费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税前利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税前利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税后利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税后利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税后现金利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税后现金利润
    INTO #dw_cp
    FROM
    (
        SELECT pe.ProjGUID,
               pr.ProductType,
               pr.ProductName, pr.BusinessType, pr.Standard ,
               ver.dw_ver,
               ISNULL(mj.SaleArea, 0) AS 可售面积,
               ISNULL(mj.BuildArea, 0) AS 总建筑面积,
               SUM(   CASE
                          WHEN mc.CostName = '销售收入（含税）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 货值,
               SUM(   CASE
                          WHEN mc.CostName = '总成本（含税，计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 总投资,
                SUM(   CASE
                          WHEN mc.CostName = '1、土地成本' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 土地款, 
               SUM(   CASE
                          WHEN mc.CostName = '除土地外直接投资（含税）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 除地价外直投,
               SUM(   CASE
                          WHEN mc.CostName = '4、营销费用' THEN
                              ISNULL(pe.TotalPrice, 0)*1.06
                          ELSE
                              0
                      END
                  ) 营销费用,
               SUM(   CASE
                          WHEN mc.CostName = '3、财务费用（账面）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 财务费用账面口径,
               SUM(   CASE
                          WHEN mc.CostName = '财务费用（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 财务费用,
               SUM(   CASE
                          WHEN mc.CostName = '5、管理费用' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 管理费用,
               SUM(   CASE
                          WHEN mc.CostName = '税前利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税前利润,
               SUM(   CASE
                          WHEN mc.CostName = '税后利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税后利润,
               SUM(   CASE
                          WHEN mc.CostName = '税后现金利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税后现金利润
        FROM #mdm_project p
            INNER JOIN #dw_ver ver
                ON p.ProjGUID = ver.ProjGUID
            INNER JOIN dbo.mdm_ProductEarningsProfit pe
                ON pe.ProjGUID = p.ProjGUID
                   AND pe.VersionGUID = ver.VersionGUID
            INNER JOIN dbo.mdm_PositioningCost mc
                ON mc.CostGUID = pe.CostGUID
            INNER JOIN mdm_DWProduct pr
                ON pe.ProductGUID = pr.ProductGUID
                   AND pe.VersionTypeName = pr.VersionTypeName
            LEFT JOIN dbo.mdm_ProductEarningsArea mj
                ON mj.VersionGUID = pe.VersionGUID
                   AND pe.ProductGUID = mj.ProductGUID
        GROUP BY pe.ProjGUID,
                 pr.ProductType,pr.ProductName, pr.BusinessType, pr.Standard ,
                 ver.dw_ver,
                 ISNULL(mj.SaleArea, 0),
                 ISNULL(mj.BuildArea, 0)
    ) t
    GROUP BY t.ProjGUID, t.ProductType,t.ProductName, t.BusinessType, t.Standard;

    SELECT t.ProjGUID,
           t.ProductType,
           SUM(CASE WHEN dw_ver = '上报版' THEN
                          t.可售面积
                      ELSE
                          0
                  END
              ) AS 可售面积,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.总建筑面积
                      ELSE
                          0
                  END
              ) AS 总建筑面积,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.货值
                      ELSE
                          0
                  END
              ) AS 货值,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.总投资
                      ELSE
                          0
                  END
              ) AS 总投资,
            SUM(   CASE
                     WHEN dw_ver = '上报版' THEN
                         t.土地款
                     ELSE
                         0
                 END
             ) AS 土地款,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.除地价外直投
                      ELSE
                          0
                  END
              ) AS 除地价外直投,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.营销费用
                      ELSE
                          0
                  END
              ) AS 营销费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.财务费用
                      ELSE
                          0
                  END
              ) AS 财务费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.财务费用账面口径
                      ELSE
                          0
                  END
              ) AS 财务费用账面口径,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.管理费用
                      ELSE
                          0
                  END
              ) AS 管理费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税前利润
                      ELSE
                          0
                  END
              ) AS 税前利润,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税后利润
                      ELSE
                          0
                  END
              ) AS 税后利润,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税后现金利润
                      ELSE
                          0
                  END
              ) AS 税后现金利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.可售面积
                      ELSE
                          0
                  END
              ) AS 定位批复版可售面积,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.总建筑面积
                      ELSE
                          0
                  END
              ) AS 定位批复版总建筑面积,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.货值
                      ELSE
                          0
                  END
              ) AS 定位批复版货值,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.总投资
                      ELSE
                          0
                  END
              ) AS 定位批复版总投资,
            SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.土地款
                      ELSE
                          0
                  END
              ) AS 定位批复版土地款,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.除地价外直投
                      ELSE
                          0
                  END
              ) AS 定位批复版除地价外直投,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.营销费用
                      ELSE
                          0
                  END
              ) AS 定位批复版营销费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.财务费用
                      ELSE
                          0
                  END
              ) AS 定位批复版财务费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.财务费用账面口径
                      ELSE
                          0
                  END
              ) AS 定位批复版财务费用账面口径,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.管理费用
                      ELSE
                          0
                  END
              ) AS 定位批复版管理费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税前利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税前利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税后利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税后利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税后现金利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税后现金利润
    INTO #dw
    FROM
    (
        SELECT pe.ProjGUID,
               pr.ProductType,
               pr.ProductName, pr.BusinessType, pr.Standard ,
               ver.dw_ver,
               ISNULL(mj.SaleArea, 0) AS 可售面积,
               ISNULL(mj.BuildArea, 0) AS 总建筑面积,
               SUM(   CASE
                          WHEN mc.CostName = '销售收入（含税）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 货值,
               SUM(   CASE
                          WHEN mc.CostName = '总成本（含税，计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 总投资,
                SUM(   CASE
                          WHEN mc.CostName = '1、土地成本' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 土地款, 
               SUM(   CASE
                          WHEN mc.CostName = '除土地外直接投资（含税）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 除地价外直投,
               SUM(   CASE
                          WHEN mc.CostName = '4、营销费用' THEN
                              ISNULL(pe.TotalPrice, 0)*1.06
                          ELSE
                              0
                      END
                  ) 营销费用,
               SUM(   CASE
                          WHEN mc.CostName = '3、财务费用（账面）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 财务费用账面口径,
               SUM(   CASE
                          WHEN mc.CostName = '财务费用（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 财务费用,
               SUM(   CASE
                          WHEN mc.CostName = '5、管理费用' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 管理费用,
               SUM(   CASE
                          WHEN mc.CostName = '税前利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税前利润,
               SUM(   CASE
                          WHEN mc.CostName = '税后利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税后利润,
               SUM(   CASE
                          WHEN mc.CostName = '税后现金利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税后现金利润
        FROM #mdm_project p
            INNER JOIN #dw_ver ver
                ON p.ProjGUID = ver.ProjGUID
            INNER JOIN dbo.mdm_ProductEarningsProfit pe
                ON pe.ProjGUID = p.ProjGUID
                   AND pe.VersionGUID = ver.VersionGUID
            INNER JOIN dbo.mdm_PositioningCost mc
                ON mc.CostGUID = pe.CostGUID
            INNER JOIN mdm_DWProduct pr
                ON pe.ProductGUID = pr.ProductGUID
                   AND pe.VersionTypeName = pr.VersionTypeName
            LEFT JOIN dbo.mdm_ProductEarningsArea mj
                ON mj.VersionGUID = pe.VersionGUID
                   AND pe.ProductGUID = mj.ProductGUID
        GROUP BY pe.ProjGUID,
                 pr.ProductType,pr.ProductName, pr.BusinessType, pr.Standard ,
                 ver.dw_ver,
                 ISNULL(mj.SaleArea, 0),
                 ISNULL(mj.BuildArea, 0)
    ) t
    GROUP BY t.ProjGUID,
             t.ProductType;


    SELECT t.ProjGUID,
           SUM(CASE WHEN dw_ver = '上报版' THEN
                          t.可售面积
                      ELSE
                          0
                  END
              ) AS 可售面积,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.总建筑面积
                      ELSE
                          0
                  END
              ) AS 总建筑面积,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.货值
                      ELSE
                          0
                  END
              ) AS 货值,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.总投资
                      ELSE
                          0
                  END
              ) AS 总投资,
            SUM(   CASE
                     WHEN dw_ver = '上报版' THEN
                         t.土地款
                     ELSE
                         0
                 END
             ) AS 土地款,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.除地价外直投
                      ELSE
                          0
                  END
              ) AS 除地价外直投,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.营销费用
                      ELSE
                          0
                  END
              ) AS 营销费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.财务费用
                      ELSE
                          0
                  END
              ) AS 财务费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.财务费用账面口径
                      ELSE
                          0
                  END
              ) AS 财务费用账面口径,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.管理费用
                      ELSE
                          0
                  END
              ) AS 管理费用,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税前利润
                      ELSE
                          0
                  END
              ) AS 税前利润,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税后利润
                      ELSE
                          0
                  END
              ) AS 税后利润,
           SUM(   CASE
                      WHEN dw_ver = '上报版' THEN
                          t.税后现金利润
                      ELSE
                          0
                  END
              ) AS 税后现金利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.可售面积
                      ELSE
                          0
                  END
              ) AS 定位批复版可售面积,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.总建筑面积
                      ELSE
                          0
                  END
              ) AS 定位批复版总建筑面积,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.货值
                      ELSE
                          0
                  END
              ) AS 定位批复版货值,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.总投资
                      ELSE
                          0
                  END
              ) AS 定位批复版总投资,
            SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.土地款
                      ELSE
                          0
                  END
              ) AS 定位批复版土地款,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.除地价外直投
                      ELSE
                          0
                  END
              ) AS 定位批复版除地价外直投,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.营销费用
                      ELSE
                          0
                  END
              ) AS 定位批复版营销费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.财务费用
                      ELSE
                          0
                  END
              ) AS 定位批复版财务费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.财务费用账面口径
                      ELSE
                          0
                  END
              ) AS 定位批复版财务费用账面口径,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.管理费用
                      ELSE
                          0
                  END
              ) AS 定位批复版管理费用,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税前利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税前利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税后利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税后利润,
           SUM(   CASE
                      WHEN dw_ver = '批复版' THEN
                          t.税后现金利润
                      ELSE
                          0
                  END
              ) AS 定位批复版税后现金利润
    INTO #dw_proj
    FROM
    (
        SELECT pe.ProjGUID,
               ver.dw_ver,
               ISNULL(mj.SaleArea, 0) AS 可售面积,
               ISNULL(mj.BuildArea, 0) AS 总建筑面积,
               SUM(   CASE
                          WHEN mc.CostName = '销售收入（含税）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 货值,
               SUM(   CASE
                          WHEN mc.CostName = '总成本（含税，计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 总投资,
                SUM(   CASE
                          WHEN mc.CostName = '1、土地成本' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 土地款, 
               SUM(   CASE
                          WHEN mc.CostName = '除土地外直接投资（含税）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 除地价外直投,
               SUM(   CASE
                          WHEN mc.CostName = '4、营销费用' THEN
                              ISNULL(pe.TotalPrice, 0)*1.06
                          ELSE
                              0
                      END
                  ) 营销费用,
               SUM(   CASE
                          WHEN mc.CostName = '3、财务费用（账面）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 财务费用账面口径,
               SUM(   CASE
                          WHEN mc.CostName = '财务费用（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 财务费用,
               SUM(   CASE
                          WHEN mc.CostName = '5、管理费用' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 管理费用,
               SUM(   CASE
                          WHEN mc.CostName = '税前利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税前利润,
               SUM(   CASE
                          WHEN mc.CostName = '税后利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税后利润,
               SUM(   CASE
                          WHEN mc.CostName = '税后现金利润（计划）' THEN
                              ISNULL(pe.TotalPrice, 0)
                          ELSE
                              0
                      END
                  ) 税后现金利润
        FROM #mdm_project p
            INNER JOIN #dw_ver ver
                ON p.ProjGUID = ver.ProjGUID
            INNER JOIN dbo.mdm_ProductEarningsProfit pe
                ON pe.ProjGUID = p.ProjGUID
                   AND pe.VersionGUID = ver.VersionGUID
            INNER JOIN dbo.mdm_PositioningCost mc
                ON mc.CostGUID = pe.CostGUID
            LEFT JOIN dbo.mdm_ProductEarningsArea mj
                ON mj.VersionGUID = pe.VersionGUID
                   AND pe.ProductGUID = mj.ProductGUID
        where pe.productguid = '00000000-0000-0000-0000-000000000000'
        GROUP BY pe.ProjGUID,
                 ver.dw_ver,
                 ISNULL(mj.SaleArea, 0),
                 ISNULL(mj.BuildArea, 0)
    ) t
    GROUP BY t.ProjGUID;

    --定位的地下建筑面积、套数从基础数据取
    SELECT t.ProjGUID,
           cf.ProductType,cf.ProductName, cf.BusinessType, cf.Standard ,
           SUM(   CASE
                      WHEN t.dw_ver = '上报版' THEN
                          ISNULL(cfdtl.JzArea, 0) - ISNULL(cfdtl.DsArea, 0)
                      ELSE
                          0
                  END
              ) AS 地下建筑面积,
           SUM(   CASE
                      WHEN t.dw_ver = '批复版' THEN
                          ISNULL(cfdtl.JzArea, 0) - ISNULL(cfdtl.DsArea, 0)
                      ELSE
                          0
                  END
              ) AS 定位批复版地下建筑面积,
            SUM(   CASE
                      WHEN t.dw_ver = '上报版' THEN
                          ISNULL(cfdtl.HbgNum, 0) 
                      ELSE
                          0
                  END
              ) AS 套数,
           SUM(   CASE
                      WHEN t.dw_ver = '批复版' THEN
                          ISNULL(cfdtl.HbgNum, 0) 
                      ELSE
                          0
                  END
              ) AS 定位批复版套数
    INTO #dw_dxarea_cp
    FROM
    (
        SELECT pj.*,
               ver.dw_ver,
               ROW_NUMBER() OVER (PARTITION BY pj.ProjGUID ORDER BY pj.CreateDate DESC) AS ranknum
        FROM #dw_ver ver
            INNER JOIN vmd_DwProject352 pj
                ON ver.ProjGUID = pj.ProjGUID
                   AND ver.VersionTypeName = pj.VersionTypeName
    ) t
        INNER JOIN MyCost_Erp352.dbo.md_product_cf cf
            ON cf.ProjGUID = t.ProjGUID
               AND cf.VersionGUID = t.VersionGUID
        INNER JOIN MyCost_Erp352.dbo.md_ProductDtl_CF cfdtl
            ON cfdtl.ProjGUID = cf.ProjGUID
               AND cfdtl.VersionGUID = cf.VersionGUID
               AND cf.ProductGUID = cfdtl.ProductGUID
    WHERE t.ranknum = 1
    GROUP BY t.ProjGUID,
             cf.ProductType,cf.ProductName, cf.BusinessType, cf.Standard;

    SELECT t.ProjGUID,
           cf.ProductType,
           SUM(   CASE
                      WHEN t.dw_ver = '上报版' THEN
                          ISNULL(cfdtl.JzArea, 0) - ISNULL(cfdtl.DsArea, 0)
                      ELSE
                          0
                  END
              ) AS 地下建筑面积,
           SUM(   CASE
                      WHEN t.dw_ver = '批复版' THEN
                          ISNULL(cfdtl.JzArea, 0) - ISNULL(cfdtl.DsArea, 0)
                      ELSE
                          0
                  END
              ) AS 定位批复版地下建筑面积,
            SUM(   CASE
                      WHEN t.dw_ver = '上报版' THEN
                          ISNULL(cfdtl.HbgNum, 0) 
                      ELSE
                          0
                  END
              ) AS 套数,
           SUM(   CASE
                      WHEN t.dw_ver = '批复版' THEN
                          ISNULL(cfdtl.HbgNum, 0) 
                      ELSE
                          0
                  END
              ) AS 定位批复版套数
    INTO #dw_dxarea
    FROM
    (
        SELECT pj.*,
               ver.dw_ver,
               ROW_NUMBER() OVER (PARTITION BY pj.ProjGUID ORDER BY pj.CreateDate DESC) AS ranknum
        FROM #dw_ver ver
            INNER JOIN vmd_DwProject352 pj
                ON ver.ProjGUID = pj.ProjGUID
                   AND ver.VersionTypeName = pj.VersionTypeName
    ) t
        INNER JOIN MyCost_Erp352.dbo.md_product_cf cf
            ON cf.ProjGUID = t.ProjGUID
               AND cf.VersionGUID = t.VersionGUID
        INNER JOIN MyCost_Erp352.dbo.md_ProductDtl_CF cfdtl
            ON cfdtl.ProjGUID = cf.ProjGUID
               AND cfdtl.VersionGUID = cf.VersionGUID
               AND cf.ProductGUID = cfdtl.ProductGUID
    WHERE t.ranknum = 1
    GROUP BY t.ProjGUID, cf.ProductType;

    SELECT t.ProjGUID,
           SUM(   CASE
                      WHEN t.dw_ver = '上报版' THEN
                          ISNULL(cfdtl.JzArea, 0) - ISNULL(cfdtl.DsArea, 0)
                      ELSE
                          0
                  END
              ) AS 地下建筑面积,
           SUM(   CASE
                      WHEN t.dw_ver = '批复版' THEN
                          ISNULL(cfdtl.JzArea, 0) - ISNULL(cfdtl.DsArea, 0)
                      ELSE
                          0
                  END
              ) AS 定位批复版地下建筑面积,
            SUM(   CASE
                      WHEN t.dw_ver = '上报版' THEN
                          ISNULL(cfdtl.HbgNum, 0) 
                      ELSE
                          0
                  END
              ) AS 套数,
           SUM(   CASE
                      WHEN t.dw_ver = '批复版' THEN
                          ISNULL(cfdtl.HbgNum, 0) 
                      ELSE
                          0
                  END
              ) AS 定位批复版套数
    INTO #dw_dxarea_proj
    FROM
    (
        SELECT pj.*,
               ver.dw_ver,
               ROW_NUMBER() OVER (PARTITION BY pj.ProjGUID ORDER BY pj.CreateDate DESC) AS ranknum
        FROM #dw_ver ver
            INNER JOIN vmd_DwProject352 pj
                ON ver.ProjGUID = pj.ProjGUID
                   AND ver.VersionTypeName = pj.VersionTypeName
    ) t
        INNER JOIN MyCost_Erp352.dbo.md_product_cf cf
            ON cf.ProjGUID = t.ProjGUID
               AND cf.VersionGUID = t.VersionGUID
        INNER JOIN MyCost_Erp352.dbo.md_ProductDtl_CF cfdtl
            ON cfdtl.ProjGUID = cf.ProjGUID
               AND cfdtl.VersionGUID = cf.VersionGUID
               AND cf.ProductGUID = cfdtl.ProductGUID
    WHERE t.ranknum = 1
    GROUP BY t.ProjGUID;

    ----------------------------获取定位、立项指标 end----------------------------
    IF EXISTS
    (
        SELECT *
        FROM dbo.sysobjects
        WHERE id = OBJECT_ID(N'ydkb_dthz_wq_deal_lxdwinfo')
              AND OBJECTPROPERTY(id, 'IsTable') = 1
    )
    BEGIN
        DROP TABLE ydkb_dthz_wq_deal_lxdwinfo;

    END;

    --湾区PC端货量报表

    CREATE TABLE ydkb_dthz_wq_deal_lxdwinfo
    (
        组织架构父级ID UNIQUEIDENTIFIER,
        组织架构ID UNIQUEIDENTIFIER,
        组织架构名称 VARCHAR(400),
        组织架构编码 [VARCHAR](100),
        组织架构类型 [INT],
        立项单价 MONEY,
        立项首开时间 DATETIME,
        立项收回股东投资时间 DATETIME,
        立项现金流回正时间 DATETIME,
        立项实际开工时间 DATETIME,
        立项竣工时间 DATETIME,	
        立项交付时间 DATETIME,
        立项IRR MONEY,
        定位单价 MONEY,
        定位首开时间 DATETIME,
        定位收回股东投资时间 DATETIME,
        定位现金流回正时间 DATETIME,
        定位IRR MONEY,
        立项可售面积 MONEY,
        立项总建筑面积 MONEY,
        立项套数 int,
        立项地下建筑面积 MONEY,
        立项可售住宅户数 int,
        立项可售车位面积 money,	
        立项可售车位个数 int,
        立项货值 MONEY,
        立项总投资 MONEY,
        立项土地款 money,
        立项除地价外直投 MONEY,
        立项营销费用 MONEY,
        立项管理费用 MONEY,
        立项财务费用 MONEY,
        立项税前成本利润率 MONEY,
        立项自有资金内部收益率 money,
        立项税前利润 MONEY,
        立项税后利润 MONEY,
        立项税后现金利润 MONEY,
        立项固定资产 money,
        立项贷款金额 money,
        定位可售面积 MONEY,
        定位总建筑面积 MONEY,
        定位地下建筑面积 MONEY,
        定位套数 int,
        定位货值 MONEY,
        定位总投资 MONEY,
        定位土地款 money,
        定位除地价外直投 MONEY,
        定位营销费用 MONEY,
        定位管理费用 MONEY,
        定位财务费用 MONEY,
        定位财务费用账面 money,
        定位贷款金额 MONEY,
        定位贷款利息 MONEY,
        定位股东借款利息  MONEY,
        定位税前成本利润率 MONEY,
        定位税前利润 MONEY, 
        定位税后利润 MONEY,
        定位税后现金利润 MONEY,
        定位固定资产 money,
        [定位批复版总建筑面积] MONEY,
        [定位批复版地下建筑面积] MONEY,
        [定位批复版套数] int,
        [定位批复版可售面积] MONEY,
        [定位批复版定位单价] MONEY,
        [定位批复版货值] MONEY,
        [定位批复版总投资] MONEY,
        [定位批复版土地款] MONEY,
        [定位批复版除地价外直投] MONEY,
        [定位批复版营销费用] MONEY,
        [定位批复版管理费用] MONEY,
        [定位批复版财务费用计划口径] MONEY,
        [定位批复版财务费用账面口径] MONEY,
        [定位批复版贷款金额] MONEY,
        [定位批复版贷款利息] MONEY,
        [定位批复版股东借款利息] MONEY,
        [定位批复版税前成本利润率] MONEY,
        [定位批复版税前利润] MONEY,
        [定位批复版税后利润] MONEY,
        [定位批复版税后现金利润] MONEY,
        [定位批复版固定资产] money,
        [定位批复版IRR] MONEY,
        [定位批复版首开时间] DATETIME,
        [定位批复版现金流回正时间] DATETIME,
        [定位批复版收回股东投资时间] DATETIME,
        --获取最新版的定位版本，定位批复>上报
        [定位最新版总建筑面积] MONEY,
        [定位最新版地下建筑面积] MONEY, 
        [定位最新版套数] int, 
        [定位最新版可售面积] MONEY,
        [定位最新版定位单价] MONEY,
        [定位最新版货值] MONEY,
        [定位最新版总投资] MONEY,
        [定位最新版土地款] MONEY,
        [定位最新版除地价外直投] MONEY,
        [定位最新版营销费用] MONEY,
        [定位最新版管理费用] MONEY,
        [定位最新版财务费用计划口径] MONEY,
        [定位最新版财务费用账面口径] MONEY,
        [定位最新版贷款金额] MONEY,
        [定位最新版贷款利息] MONEY,
        [定位最新版股东借款利息] MONEY,
        [定位最新版税前成本利润率] MONEY,
        [定位最新版税前利润] MONEY,
        [定位最新版税后利润] MONEY,
        [定位最新版税后现金利润] MONEY,
        [定位最新版固定资产] money,
        [定位最新版IRR] MONEY,
        [定位最新版首开时间] DATETIME,
        [定位最新版现金流回正时间] DATETIME,
        [定位最新版收回股东投资时间] DATETIME,
        项目guid uniqueidentifier ,
        产品类型 varchar(50),
        产品名称 varchar(50),
        商品类型 varchar(50), 
        装修标准 varchar(30)
    );


    --插入产品的值,现有底表没有产品的维度，所以需要插入前需要新增产品粒度
    --1、汇总产品维度
    select projguid,ProductType,ProductName, BusinessType, Standard 
    into #cp
    from (
    select projguid,ProductType,ProductName, BusinessType, Standard from #dwprice_cp
    union all 
    select projguid,ProductType,ProductName, BusinessType, Standard from #lxprice_cp
    union all 
    select projguid,ProductType,ProductName, BusinessType, Standard from #lx_cb_cp
    union all 
    select projguid,ProductType,ProductName, BusinessType, Standard from #lx_lr_cp
    union all 
    select projguid,ProductType,ProductName, BusinessType, Standard from #lxmj_cp
    union all 
    select projguid,ProductType,ProductName, BusinessType, Standard from #dw_cp
    union all 
    select projguid,ProductType,ProductName, BusinessType, Standard from #dw_dxarea_cp) t
    group by projguid,ProductType,ProductName, BusinessType, Standard

    --2、插入产品的值
    INSERT INTO ydkb_dthz_wq_deal_lxdwinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        立项单价,
        立项首开时间,
        立项收回股东投资时间,
        立项现金流回正时间,
        立项实际开工时间,
        立项竣工时间,	
        立项交付时间,
        立项IRR,
        定位单价,
        定位首开时间,
        定位收回股东投资时间,
        定位现金流回正时间,
        定位IRR,
        立项可售面积,
        立项总建筑面积,
        立项套数,
        立项地下建筑面积,
        立项可售住宅户数,
        立项可售车位面积,	
        立项可售车位个数,
        立项货值,
        立项总投资,
        立项土地款,
        立项除地价外直投,
        立项营销费用,
        立项管理费用,
        立项财务费用,
        立项税前成本利润率,
        立项自有资金内部收益率,
        立项税前利润,
        立项税后利润,
        立项税后现金利润,
        立项固定资产, 
        定位可售面积,
        定位总建筑面积,
        定位地下建筑面积,
        定位套数,
        定位货值,
        定位总投资,
        定位土地款,
        定位除地价外直投,
        定位营销费用,
        定位管理费用,
        定位财务费用,
        定位财务费用账面,
        定位贷款金额,
        定位贷款利息,
        定位股东借款利息,
        定位税前成本利润率,
        定位税前利润,
        定位税后利润,
        定位税后现金利润, 
        [定位批复版总建筑面积],
        [定位批复版地下建筑面积],
        [定位批复版套数],
        [定位批复版可售面积],
        [定位批复版定位单价],
        [定位批复版货值],
        [定位批复版总投资],
        定位批复版土地款,
        [定位批复版除地价外直投],
        [定位批复版营销费用],
        [定位批复版管理费用],
        [定位批复版财务费用计划口径],
        [定位批复版财务费用账面口径],
        [定位批复版贷款金额],
        [定位批复版贷款利息],
        [定位批复版股东借款利息],
        [定位批复版税前成本利润率],
        [定位批复版税前利润],
        [定位批复版税后利润],
        [定位批复版税后现金利润],
        项目guid ,
        产品类型 ,
        产品名称 ,
        商品类型 , 
        装修标准  
    )
    select 
           null 组织架构父级ID,
           null 组织架构ID,
           null 组织架构名称,
           null 组织架构编码,
           null 组织架构类型,
           lxprice.立项单价,
           NULL 立项首开时间,
           NULL 立项收回股东投资时间,
           NULL 立项现金流回正时间,
           null 立项实际开工时间,
           null 立项竣工时间,	
           null 立项交付时间,
           NULL 立项IRR,
           dwprice.定位单价,
           NULL 定位首开时间,
           NULL 定位收回股东投资时间,
           NULL 定位现金流回正时间,
           NULL 定位IRR,
           lxmj.可售面积 立项可售面积,
           lxmj.总建筑面积 立项总建筑面积,
           lxmj.套数 立项套数,
           lxmj.地下建筑面积 立项地下建筑面积,
           lxmj.立项可售住宅户数,
           lxmj.立项可售车位面积,	
           lxmj.立项可售车位个数,
           lxlr.货值 立项货值,
           lxcb.总投资 立项总投资,
           lxcb.土地款 立项土地款,
           lxcb.除地价外直投 立项除地价外直投,
           lxcb.营销费用 立项营销费用,
           lxcb.管理费用 立项管理费用,
           lxcb.财务费用 立项财务费用,
           CASE
               WHEN ISNULL(lxcb.总投资, 0) = 0 THEN
                   0
               ELSE
                   lxlr.税前利润 * 1.0 / lxcb.总投资
           END 立项税前成本利润率,
           null 立项自有资金内部收益率,
           lxlr.税前利润 立项税前利润,
           lxlr.税后利润 立项税后利润,
           lxlr.税后现金利润 立项税后现金利润,
           lxlr.固定资产 立项固定资产,
           dw.可售面积 定位可售面积,
           dw.总建筑面积 定位总建筑面积,
           dx.地下建筑面积 定位地下建筑面积,
           dx.套数 定位套数,
           dw.货值 定位货值,
           dw.总投资 定位总投资,
           dw.土地款 定位土地款,
           dw.除地价外直投 定位除地价外直投,
           dw.营销费用 定位营销费用,
           dw.管理费用 定位管理费用,
           dw.财务费用 定位财务费用,
           dw.财务费用账面口径 as 定位财务费用账面,
           null 定位贷款金额,
           null 定位贷款利息,
           null 定位股东借款利息,
           CASE
               WHEN ISNULL(dw.总投资, 0) = 0 THEN
                   0
               ELSE
                   dw.税前利润 / (dw.总投资)
           END 定位税前成本利润率,
           dw.税前利润 定位税前利润,
           dw.税后利润 定位税后利润,
           dw.税后现金利润 定位税后现金利润,
           dw.定位批复版总建筑面积 [定位批复版总建筑面积],
           dx.定位批复版地下建筑面积 [定位批复版地下建筑面积],
           dx.定位批复版套数 [定位批复版套数],
           dw.定位批复版可售面积 [定位批复版可售面积],
           dwprice.定位批复版单价 [定位批复版定位单价],
           dw.定位批复版货值 [定位批复版货值],
           dw.定位批复版总投资 [定位批复版总投资],
           dw.定位批复版土地款 定位批复版土地款,
           dw.定位批复版除地价外直投 [定位批复版除地价外直投],
           dw.定位批复版营销费用 [定位批复版营销费用],
           dw.定位批复版管理费用 [定位批复版管理费用],
           dw.定位批复版财务费用 [定位批复版财务费用计划口径],
           dw.定位批复版财务费用账面口径 [定位批复版财务费用账面口径],
           NULL [定位批复版贷款金额],
           NULL [定位批复版贷款利息],
           NULL [定位批复版股东借款利息],
           CASE
               WHEN ISNULL(dw.定位批复版总投资, 0) = 0 THEN
                   0
               ELSE
                   dw.税前利润 / (dw.定位批复版总投资)
           END [定位批复版税前成本利润率],
           dw.定位批复版税前利润 [定位批复版税前利润],
           dw.定位批复版税后利润 [定位批复版税后利润],
           dw.定位批复版税后现金利润 [定位批复版税后现金利润],
           cp.projguid 项目guid ,
           cp.ProductType 产品类型 ,
           cp.ProductName 产品名称 ,
           cp.BusinessType 商品类型 , 
           cp.Standard 装修标准 
    from #cp cp
    LEFT JOIN #dwprice_cp dwprice  ON cp.projguid = dwprice.projguid and cp.ProductType= dwprice.ProductType and cp.ProductName= dwprice.ProductName
        and cp.BusinessType = dwprice.BusinessType and  cp.Standard= dwprice.Standard 
    LEFT JOIN #lxprice_cp lxprice ON cp.projguid = lxprice.projguid and cp.ProductType= lxprice.ProductType and cp.ProductName= lxprice.ProductName
        and cp.BusinessType = lxprice.BusinessType and  cp.Standard= lxprice.Standard 
    LEFT JOIN #lx_cb_cp lxcb ON cp.projguid = lxcb.projguid and cp.ProductType= lxcb.ProductType and cp.ProductName= lxcb.ProductName
        and cp.BusinessType = lxcb.BusinessType and  cp.Standard= lxcb.Standard 
    LEFT JOIN #lx_lr_cp lxlr ON cp.projguid = lxlr.projguid and cp.ProductType= lxlr.ProductType and cp.ProductName= lxlr.ProductName
        and cp.BusinessType = lxlr.BusinessType and  cp.Standard= lxlr.Standard 
    LEFT JOIN #lxmj_cp lxmj  ON cp.projguid = lxmj.projguid and cp.ProductType= lxmj.ProductType and cp.ProductName= lxmj.ProductName
        and cp.BusinessType = lxmj.BusinessType and  cp.Standard= lxmj.Standard 
    LEFT JOIN #dw_cp dw ON cp.projguid = dw.projguid and cp.ProductType= dw.ProductType and cp.ProductName= dw.ProductName
        and cp.BusinessType = dw.BusinessType and  cp.Standard= dw.Standard 
    LEFT JOIN #dw_dxarea_cp dx  ON cp.projguid = dx.projguid and cp.ProductType= dx.ProductType and cp.ProductName= dx.ProductName
        and cp.BusinessType = dx.BusinessType and  cp.Standard= dx.Standard 

    --插入业态的值
    INSERT INTO ydkb_dthz_wq_deal_lxdwinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        立项单价,
        立项首开时间,
        立项收回股东投资时间,
        立项现金流回正时间,
        立项实际开工时间,
        立项竣工时间,	
        立项交付时间,
        立项IRR,
        定位单价,
        定位首开时间,
        定位收回股东投资时间,
        定位现金流回正时间,
        定位IRR,
        立项可售面积,
        立项总建筑面积,
        立项套数,
        立项地下建筑面积,
        立项可售住宅户数,
        立项可售车位面积,
        立项可售车位个数,
        立项货值,
        立项总投资,
        立项土地款,
        立项除地价外直投,
        立项营销费用,
        立项管理费用,
        立项财务费用,
        立项税前成本利润率,
        立项自有资金内部收益率,
        立项税前利润,
        立项税后利润,
        立项税后现金利润,
        立项固定资产, 
        定位可售面积,
        定位总建筑面积,
        定位地下建筑面积,
        定位套数,
        定位货值,
        定位总投资,
        定位土地款,
        定位除地价外直投,
        定位营销费用,
        定位管理费用,
        定位财务费用,
        定位财务费用账面,
        定位贷款金额,
        定位贷款利息,
        定位股东借款利息,
        定位税前成本利润率,
        定位税前利润,
        定位税后利润,
        定位税后现金利润, 
        [定位批复版总建筑面积],
        [定位批复版地下建筑面积],
        定位批复版套数,
        [定位批复版可售面积],
        [定位批复版定位单价],
        [定位批复版货值],
        [定位批复版总投资],
        定位批复版土地款,
        [定位批复版除地价外直投],
        [定位批复版营销费用],
        [定位批复版管理费用],
        [定位批复版财务费用计划口径],
        [定位批复版财务费用账面口径],
        [定位批复版贷款金额],
        [定位批复版贷款利息],
        [定位批复版股东借款利息],
        [定位批复版税前成本利润率],
        [定位批复版税前利润],
        [定位批复版税后利润],
        [定位批复版税后现金利润],
        项目guid 
    )
    SELECT bi2.组织架构父级ID,
           bi2.组织架构ID,
           bi2.组织架构名称,
           bi2.组织架构编码,
           bi2.组织架构类型,
           lxprice.立项单价,
           NULL 立项首开时间,
           NULL 立项收回股东投资时间,
           NULL 立项现金流回正时间,
           null 立项实际开工时间,
           null 立项竣工时间,	
           null 立项交付时间,
           NULL 立项IRR,
           dwprice.定位单价,
           NULL 定位首开时间,
           NULL 定位收回股东投资时间,
           NULL 定位现金流回正时间,
           NULL 定位IRR,
           lxmj.可售面积 立项可售面积,
           lxmj.总建筑面积 立项总建筑面积,
           lxmj.套数 as 立项套数,
           lxmj.地下建筑面积 立项地下建筑面积,
           lxmj.立项可售住宅户数,
           lxmj.立项可售车位面积,
           lxmj.立项可售车位个数,
           lxlr.货值 立项货值,
           lxcb.总投资 立项总投资,
           lxcb.土地款 立项土地款,
           lxcb.除地价外直投 立项除地价外直投,
           lxcb.营销费用 立项营销费用,
           lxcb.管理费用 立项管理费用,
           lxcb.财务费用 立项财务费用,
           CASE
               WHEN ISNULL(lxcb.总投资, 0) = 0 THEN
                   0
               ELSE
                   lxlr.税前利润 * 1.0 / lxcb.总投资
           END 立项税前成本利润率,
           null 立项自有资金内部收益率,
           lxlr.税前利润 立项税前利润,
           lxlr.税后利润 立项税后利润,
           lxlr.税后现金利润 立项税后现金利润,
           lxlr.固定资产 立项固定资产,
           dw.可售面积 定位可售面积,
           dw.总建筑面积 定位总建筑面积,
           dx.地下建筑面积 定位地下建筑面积,
           dx.套数 定位套数,
           dw.货值 定位货值,
           dw.总投资 定位总投资,
           dw.土地款 定位土地款,
           dw.除地价外直投 定位除地价外直投,
           dw.营销费用 定位营销费用,
           dw.管理费用 定位管理费用,
           dw.财务费用 定位财务费用,
           dw.财务费用账面口径 as 定位财务费用账面,
           null 定位贷款金额,
           null 定位贷款利息,
           null 定位股东借款利息,
           CASE
               WHEN ISNULL(dw.总投资, 0) = 0 THEN
                   0
               ELSE
                   dw.税前利润 / (dw.总投资)
           END 定位税前成本利润率,
           dw.税前利润 定位税前利润,
           dw.税后利润 定位税后利润,
           dw.税后现金利润 定位税后现金利润,
           dw.定位批复版总建筑面积 [定位批复版总建筑面积],
           dx.定位批复版地下建筑面积 [定位批复版地下建筑面积],
           dx.定位批复版套数 定位批复版套数,
           dw.定位批复版可售面积 [定位批复版可售面积],
           dwprice.定位批复版单价 [定位批复版定位单价],
           dw.定位批复版货值 [定位批复版货值],
           dw.定位批复版总投资 [定位批复版总投资],
           dw.定位批复版土地款,
           dw.定位批复版除地价外直投 [定位批复版除地价外直投],
           dw.定位批复版营销费用 [定位批复版营销费用],
           dw.定位批复版管理费用 [定位批复版管理费用],
           dw.定位批复版财务费用 [定位批复版财务费用计划口径],
           dw.定位批复版财务费用账面口径 [定位批复版财务费用账面口径],
           NULL [定位批复版贷款金额],
           NULL [定位批复版贷款利息],
           NULL [定位批复版股东借款利息],
           CASE
               WHEN ISNULL(dw.定位批复版总投资, 0) = 0 THEN
                   0
               ELSE
                   dw.税前利润 / (dw.定位批复版总投资)
           END [定位批复版税前成本利润率],
           dw.定位批复版税前利润 [定位批复版税前利润],
           dw.定位批复版税后利润 [定位批复版税后利润],
           dw.定位批复版税后现金利润 [定位批复版税后现金利润],
           bi2.组织架构父级id as 项目guid
    FROM ydkb_BaseInfo bi2
        LEFT JOIN #dwprice dwprice
            ON bi2.组织架构父级ID = dwprice.ProjGUID
               AND bi2.组织架构名称 = dwprice.ProductType
        LEFT JOIN #lxprice lxprice
            ON bi2.组织架构父级ID = lxprice.ProjGUID
               AND bi2.组织架构名称 = lxprice.ProductType
        LEFT JOIN #lx_cb lxcb
            ON bi2.组织架构父级ID = lxcb.ProjGUID
               AND bi2.组织架构名称 = lxcb.ProductType
        LEFT JOIN #lx_lr lxlr
            ON bi2.组织架构父级ID = lxlr.ProjGUID
               AND bi2.组织架构名称 = lxlr.ProductType
        LEFT JOIN #lxmj lxmj
            ON bi2.组织架构父级ID = lxmj.ProjGUID
               AND bi2.组织架构名称 = lxmj.ProductType
        LEFT JOIN #dw dw
            ON bi2.组织架构父级ID = dw.ProjGUID
               AND bi2.组织架构名称 = dw.ProductType
        LEFT JOIN #dw_dxarea dx
            ON bi2.组织架构父级ID = dx.ProjGUID
               AND bi2.组织架构名称 = dx.ProductType
    WHERE bi2.组织架构类型 = 4
          AND bi2.平台公司GUID IN (
                                  SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
                              );
    
    --插入项目的值
    INSERT INTO ydkb_dthz_wq_deal_lxdwinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        立项单价,
        立项首开时间,
        立项收回股东投资时间,
        立项现金流回正时间,
        立项实际开工时间,
        立项竣工时间,	
        立项交付时间,
        立项IRR,
        定位单价,
        定位首开时间,
        定位收回股东投资时间,
        定位现金流回正时间,
        定位IRR,
        立项可售面积,
        立项总建筑面积,
        立项套数,
        立项地下建筑面积,
        立项可售住宅户数,
        立项可售车位面积,
        立项可售车位个数,
        立项货值,
        立项总投资,
        立项土地款,
        立项除地价外直投,
        立项营销费用,
        立项管理费用,
        立项财务费用,
        立项税前成本利润率,
        立项自有资金内部收益率,
        立项税前利润,
        立项税后利润,
        立项税后现金利润,
        立项固定资产, 
        定位可售面积,
        定位总建筑面积,
        定位地下建筑面积,
        定位套数,
        定位货值,
        定位总投资,
        定位土地款,
        定位除地价外直投,
        定位营销费用,
        定位管理费用,
        定位财务费用,
        定位财务费用账面,
        定位贷款金额,
        定位贷款利息,
        定位股东借款利息,
        定位税前成本利润率,
        定位税前利润,
        定位税后利润,
        定位税后现金利润, 
        [定位批复版总建筑面积],
        [定位批复版地下建筑面积],
        定位批复版套数,
        [定位批复版可售面积],
        [定位批复版定位单价],
        [定位批复版货值],
        [定位批复版总投资],
        定位批复版土地款,
        [定位批复版除地价外直投],
        [定位批复版营销费用],
        [定位批复版管理费用],
        [定位批复版财务费用计划口径],
        [定位批复版财务费用账面口径],
        [定位批复版贷款金额],
        [定位批复版贷款利息],
        [定位批复版股东借款利息],
        [定位批复版税前成本利润率],
        [定位批复版税前利润],
        [定位批复版税后利润],
        [定位批复版税后现金利润],
        项目guid 
    )
    SELECT bi2.组织架构父级ID,
           bi2.组织架构ID,
           bi2.组织架构名称,
           bi2.组织架构编码,
           bi2.组织架构类型,
           null 立项单价,
           NULL 立项首开时间,
           NULL 立项收回股东投资时间,
           NULL 立项现金流回正时间,
           null 立项实际开工时间,
           null 立项竣工时间,	
           null 立项交付时间,
           NULL 立项IRR,
           null 定位单价,
           NULL 定位首开时间,
           NULL 定位收回股东投资时间,
           NULL 定位现金流回正时间,
           NULL 定位IRR,
           lxmj.可售面积 立项可售面积,
           lxmj.总建筑面积 立项总建筑面积,
           lxmj.套数 立项套数,
           lxmj.地下建筑面积 立项地下建筑面积,
           lxmj.立项可售住宅户数,
           lxmj.立项可售车位面积,
           lxmj.立项可售车位个数,
           lxlr.货值 立项货值,
           lxcb.总投资 立项总投资,
           lxcb.土地款 立项土地款,
           lxcb.除地价外直投 立项除地价外直投,
           lxcb.营销费用 立项营销费用,
           lxcb.管理费用 立项管理费用,
           lxcb.财务费用 立项财务费用,
           CASE
               WHEN ISNULL(lxcb.总投资, 0) = 0 THEN
                   0
               ELSE
                   lxlr.税前利润 * 1.0 / lxcb.总投资
           END 立项税前成本利润率,
           null 立项自有资金内部收益率,
           lxlr.税前利润 立项税前利润,
           lxlr.税后利润 立项税后利润,
           lxlr.税后现金利润 立项税后现金利润,
           lxlr.固定资产 立项固定资产,
           dw.可售面积 定位可售面积,
           dw.总建筑面积 定位总建筑面积,
           dx.地下建筑面积 定位地下建筑面积,
           dx.套数 定位套数,
           dw.货值 定位货值,
           dw.总投资 定位总投资,
           dw.土地款 定位土地款,
           dw.除地价外直投 定位除地价外直投,
           dw.营销费用 定位营销费用,
           dw.管理费用 定位管理费用,
           dw.财务费用 定位财务费用,
           dw.财务费用账面口径 as 定位财务费用账面,
           null 定位贷款金额,
           null 定位贷款利息,
           null 定位股东借款利息,
           CASE
               WHEN ISNULL(dw.总投资, 0) = 0 THEN
                   0
               ELSE
                   dw.税前利润 / (dw.总投资)
           END 定位税前成本利润率,
           dw.税前利润 定位税前利润,
           dw.税后利润 定位税后利润,
           dw.税后现金利润 定位税后现金利润,
           dw.定位批复版总建筑面积 [定位批复版总建筑面积],
           dx.定位批复版地下建筑面积 [定位批复版地下建筑面积],
           dx.定位批复版套数 定位批复版套数,
           dw.定位批复版可售面积 [定位批复版可售面积],
           null [定位批复版定位单价],
           dw.定位批复版货值 [定位批复版货值],
           dw.定位批复版总投资 [定位批复版总投资],
           dw.定位批复版土地款,
           dw.定位批复版除地价外直投 [定位批复版除地价外直投],
           dw.定位批复版营销费用 [定位批复版营销费用],
           dw.定位批复版管理费用 [定位批复版管理费用],
           dw.定位批复版财务费用 [定位批复版财务费用计划口径],
           dw.定位批复版财务费用账面口径 [定位批复版财务费用账面口径],
           NULL [定位批复版贷款金额],
           NULL [定位批复版贷款利息],
           NULL [定位批复版股东借款利息],
           CASE
               WHEN ISNULL(dw.定位批复版总投资, 0) = 0 THEN
                   0
               ELSE
                   dw.税前利润 / (dw.定位批复版总投资)
           END [定位批复版税前成本利润率],
           dw.定位批复版税前利润 [定位批复版税前利润],
           dw.定位批复版税后利润 [定位批复版税后利润],
           dw.定位批复版税后现金利润 [定位批复版税后现金利润],
           bi2.组织架构id as 项目guid
    FROM ydkb_BaseInfo bi2
        LEFT JOIN #lx_cb_proj lxcb ON bi2.组织架构ID = lxcb.ProjGUID
        LEFT JOIN #lx_lr_proj lxlr ON bi2.组织架构ID = lxlr.ProjGUID
        LEFT JOIN #lxmj_proj lxmj ON bi2.组织架构ID = lxmj.ProjGUID
        LEFT JOIN #dw_proj dw  ON bi2.组织架构ID = dw.ProjGUID
        LEFT JOIN #dw_dxarea_proj dx ON bi2.组织架构ID = dx.ProjGUID
    WHERE bi2.组织架构类型 = 3
          AND bi2.平台公司GUID IN (
                                  SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
                              );

    --更新项目层级的立项可售面积：去掉车位

            UPDATE t
            SET t.立项可售面积 = xminfo.可售面积,
            t.立项贷款金额 = jk.CashMoney
            FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
                left JOIN
                (
                    SELECT Pd.ProjGUID,
                           SUM(   CASE
                                      WHEN Pd.ProductType = '地下室/车库' THEN
                                          0
                                      ELSE
                                          ISNULL(KsArea, 0)
                                  END
                              ) AS 可售面积
                    FROM mdm_TechTargetProduct Pd
                        INNER JOIN #mdm_project pj
                            ON Pd.ProjGUID = pj.ProjGUID
                    GROUP BY Pd.ProjGUID
                ) xminfo
                    ON t.组织架构ID = xminfo.ProjGUID
                left join (
                     select projguid,CashMoney from mdm_ProjectCashFlow where CostName = '银行借款' and CashFlowYear = '合计'
                )jk on jk.projguid = t.组织架构ID; 

        --更新项目层级税后现金利润

            UPDATE t
            SET t.定位税后现金利润 = xminfo.定位税后现金利润,
                t.定位批复版税后现金利润 = xminfo.定位批复版税后现金利润,
                t.定位固定资产 = xminfo.定位固定资产 ,
                t.定位批复版固定资产  = xminfo.定位固定资产 
            FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
                INNER JOIN
                (
                    SELECT pe.ProjGUID,
                           sum(CASE 
                               --从项目层级总计取值
                               WHEN ver.dw_ver = '上报版' and mc.CostName = '税后现金利润（计划）' and ProductGUID = '22222222-2222-2222-2222-222222222222' THEN
                                   pe.TotalPrice
                               ELSE
                                   0
                           END ) AS 定位税后现金利润,
                           sum(CASE
                               WHEN ver.dw_ver = '批复版' and mc.CostName = '税后现金利润（计划）'and ProductGUID = '22222222-2222-2222-2222-222222222222' THEN
                                   pe.TotalPrice
                               ELSE
                                   0
                           END) AS 定位批复版税后现金利润,
                           sum(CASE 
                               --从项目层级经营产品取值
                               WHEN ver.dw_ver = '上报版' and mc.CostName = '总成本（不含税，账面）' and ProductGUID = '11111111-1111-1111-1111-111111111111' THEN
                                   pe.TotalPrice
                               ELSE
                                   0
                           END ) AS 定位固定资产,
                           sum(CASE
                               WHEN ver.dw_ver = '批复版' and mc.CostName = '总成本（不含税，账面）'and ProductGUID = '11111111-1111-1111-1111-111111111111' THEN
                                   pe.TotalPrice
                               ELSE
                                   0
                           END) AS 定位批复版固定资产

                    FROM dbo.mdm_ProductEarningsProfit pe
                        INNER JOIN #dw_ver ver
                            ON pe.ProjGUID = ver.ProjGUID
                               AND pe.VersionGUID = ver.VersionGUID
                        INNER JOIN dbo.mdm_PositioningCost mc
                            ON mc.CostGUID = pe.CostGUID
                    WHERE ProductGUID in ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222')
					group by  pe.ProjGUID
                ) xminfo
                    ON t.组织架构ID = xminfo.ProjGUID;
 
            --更新项目层级的贷款利息和股东借款利息
             UPDATE t
             SET t.定位贷款利息 = xminfo.定位贷款利息,
                 t.定位股东借款利息 = xminfo.定位股东借款利息,
                 t.定位批复版贷款利息 = xminfo.定位批复版贷款利息,
                 t.定位批复版股东借款利息 = xminfo.定位批复版股东借款利息 
            FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
                INNER JOIN
                (
                    SELECT pe.ProjGUID,  
                    case when ver.dw_ver = '上报版' then GDOutInterest else 0 end as 定位股东借款利息, 
                    case when ver.dw_ver = '上报版' then LoansInterest else 0 end as 定位贷款利息, 
                    case when ver.dw_ver = '批复版' then GDOutInterest else 0 end as 定位批复版股东借款利息, 
                    case when ver.dw_ver = '批复版' then LoansInterest else 0 end as 定位批复版贷款利息 
                    FROM dbo.mdm_DWCashFlow pe
                        INNER JOIN #dw_ver ver
                            ON pe.ProjGUID = ver.ProjGUID
                               AND pe.VersionGUID = ver.VersionGUID   
                    WHERE Month = '利息（合计）'
                ) xminfo
                    ON t.组织架构ID = xminfo.ProjGUID;   
            --更新项目层级的贷款金额
            UPDATE t
             SET t.定位贷款金额 = xminfo.定位贷款金额, 
                 t.定位批复版贷款金额 = xminfo.定位批复版贷款金额 
            FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
                INNER JOIN
                (
                    SELECT pe.ProjGUID,   
                    sum(case when ver.dw_ver = '上报版' then CurAddLoans else 0 end) as 定位贷款金额,  
                    sum(case when ver.dw_ver = '批复版' then CurAddLoans else 0 end) as 定位批复版贷款金额 
                    FROM dbo.mdm_DWCashFlow pe
                        INNER JOIN #dw_ver ver
                            ON pe.ProjGUID = ver.ProjGUID
                               AND pe.VersionGUID = ver.VersionGUID   
                    WHERE Month <> '利息（合计）' and Month like '%年%' and Month like '%月%'
                    group by pe.ProjGUID
                ) xminfo
                    ON t.组织架构ID = xminfo.ProjGUID;  

            --更新定位最新版指标情况
            --通过项目guid来更新产品、业态、项目层级的数据
            UPDATE t
             SET t.定位最新版总建筑面积 = case when ver.vername = '上报版' then 定位总建筑面积 else 定位批复版总建筑面积 end,
                 t.定位最新版地下建筑面积 =case when ver.vername = '上报版' then 定位地下建筑面积 else 定位批复版地下建筑面积 end,
                 t.定位最新版套数 =case when ver.vername = '上报版' then 定位套数 else 定位批复版套数 end,
                 t.定位最新版可售面积 = case when ver.vername = '上报版' then 定位可售面积 else 定位批复版可售面积 end,
                 t.定位最新版定位单价 = case when ver.vername = '上报版' then 定位单价 else 定位批复版定位单价 end,
                 t.定位最新版货值 = case when ver.vername = '上报版' then 定位货值 else 定位批复版货值 end,
                 t.定位最新版总投资 = case when ver.vername = '上报版' then 定位总投资 else 定位批复版总投资 end,
                 t.定位最新版土地款 = case when ver.vername = '上报版' then 定位土地款 else 定位批复版土地款 end,
                 t.定位最新版除地价外直投 = case when ver.vername = '上报版' then 定位除地价外直投 else 定位批复版除地价外直投 end,
                 t.定位最新版营销费用 = case when ver.vername = '上报版' then 定位营销费用 else 定位批复版营销费用 end,
                 t.定位最新版管理费用 = case when ver.vername = '上报版' then 定位管理费用 else 定位批复版管理费用 end,
                 t.定位最新版财务费用计划口径 = case when ver.vername = '上报版' then 定位财务费用 else 定位批复版财务费用计划口径 end,
                 t.定位最新版财务费用账面口径 = case when ver.vername = '上报版' then 定位财务费用账面 else 定位批复版财务费用账面口径 end,
                 t.定位最新版贷款金额 = case when ver.vername = '上报版' then 定位贷款金额 else 定位批复版贷款金额 end,
                 t.定位最新版贷款利息 = case when ver.vername = '上报版' then 定位贷款利息 else 定位批复版贷款利息 end,
                 t.定位最新版股东借款利息 = case when ver.vername = '上报版' then 定位股东借款利息 else 定位批复版股东借款利息 end,
                 t.定位最新版税前成本利润率 = case when ver.vername = '上报版' then 定位税前成本利润率 else 定位批复版税前成本利润率 end,
                 t.定位最新版税前利润 = case when ver.vername = '上报版' then 定位税前利润 else 定位批复版税前利润 end,
                 t.定位最新版税后利润 = case when ver.vername = '上报版' then 定位税后利润 else 定位批复版税后利润 end, 
                 t.定位最新版税后现金利润 = case when ver.vername = '上报版' then 定位税后现金利润 else 定位批复版税后现金利润 end,
                 t.[定位最新版固定资产] = case when ver.vername = '上报版' then 定位固定资产 else 定位批复版固定资产 end 
            FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
                INNER JOIN #dw_ver_summary ver ON t.项目guid = ver.ProjGUID;   
    
    --循环插入项目，城市公司，平台公司的值
    DECLARE @baseinfo INT;

    SET @baseinfo = 3;

    WHILE (@baseinfo > 1)
    BEGIN
        INSERT INTO ydkb_dthz_wq_deal_lxdwinfo
        (
            组织架构父级ID,
            组织架构ID,
            组织架构名称,
            组织架构编码,
            组织架构类型,
            立项单价,
            立项首开时间,
            立项收回股东投资时间,
            立项现金流回正时间,
            立项实际开工时间,
            立项竣工时间,	
            立项交付时间,
            立项IRR,
            定位单价,
            定位首开时间,
            定位收回股东投资时间,
            定位现金流回正时间,
            定位IRR,
            立项可售面积,
            立项总建筑面积,
            立项套数,
            立项地下建筑面积,
            立项可售住宅户数,
            立项可售车位面积,
            立项可售车位个数,
            立项货值,
            立项总投资,
            立项土地款,
            立项除地价外直投,
            立项营销费用,
            立项管理费用,
            立项财务费用,
            立项税前成本利润率,
            立项自有资金内部收益率,
            立项税前利润,
            立项税后利润,
            立项税后现金利润,
            立项固定资产,
            立项贷款金额,
            定位可售面积,
            定位总建筑面积,
            定位地下建筑面积,
            定位套数,
            定位货值,
            定位总投资,
            定位土地款,
            定位除地价外直投,
            定位营销费用,
            定位管理费用,
            定位财务费用,
            定位财务费用账面,
            定位贷款金额,
            定位贷款利息,
            定位股东借款利息,
            定位税前成本利润率,
            定位税前利润,
            定位税后利润,
            定位税后现金利润,
            定位固定资产,
            [定位批复版总建筑面积],
            [定位批复版地下建筑面积],
            定位批复版套数,
            [定位批复版可售面积],
            [定位批复版定位单价],
            [定位批复版货值],
            [定位批复版总投资],
            定位批复版土地款,
            [定位批复版除地价外直投],
            [定位批复版营销费用],
            [定位批复版管理费用],
            [定位批复版财务费用计划口径],
            [定位批复版财务费用账面口径],
            [定位批复版贷款金额],
            [定位批复版贷款利息],
            [定位批复版股东借款利息],
            [定位批复版税前成本利润率],
            [定位批复版税前利润],
            [定位批复版税后利润],
            [定位批复版税后现金利润],
            [定位批复版固定资产],
            项目guid
        )
        SELECT bi.组织架构父级ID,
               bi.组织架构ID,
               bi.组织架构名称,
               bi.组织架构编码,
               bi.组织架构类型,
               NULL 立项单价,
               NULL 立项首开时间,
               NULL 立项收回股东投资时间,
               NULL 立项现金流回正时间,
               NULL 立项实际开工时间,
               NULL 立项竣工时间,	
               NULL 立项交付时间,
               NULL 立项IRR,
               NULL 定位单价,
               NULL 定位首开时间,
               NULL 定位收回股东投资时间,
               NULL 定位现金流回正时间,
               NULL 定位IRR,
               SUM(ISNULL(立项可售面积, 0)) AS 立项可售面积,
               SUM(ISNULL(立项总建筑面积, 0)) AS 立项总建筑面积,
               SUM(ISNULL(立项套数, 0)) AS 立项套数,
               SUM(ISNULL(立项地下建筑面积, 0)) AS 立项地下建筑面积,
               sum(isnull(立项可售住宅户数,0)) as 立项可售住宅户数,
               sum(isnull(立项可售车位面积,0)) as 立项可售车位面积,
               sum(isnull(立项可售车位个数,0)) as 立项可售车位个数,
               SUM(ISNULL(立项货值, 0)) AS 立项货值,
               SUM(ISNULL(立项总投资, 0)) AS 立项总投资,
               SUM(ISNULL(立项土地款, 0)) AS 立项土地款,
               SUM(ISNULL(立项除地价外直投, 0)) AS 立项除地价外直投,
               SUM(ISNULL(立项营销费用, 0)) AS 立项营销费用,
               SUM(ISNULL(立项管理费用, 0)) AS 立项管理费用,
               SUM(ISNULL(立项财务费用, 0)) AS 立项财务费用,
               CASE
                   WHEN SUM(ISNULL(立项总投资, 0)) = 0 THEN
                       0
                   ELSE
                       SUM(ISNULL(立项税前利润, 0)) * 100 / SUM(ISNULL(立项总投资, 0))
               END 立项税前成本利润率,
               --湾区要求精确到0.01%
               null 立项自有资金内部收益率,
               SUM(ISNULL(立项税前利润, 0)) AS 立项税前利润,
               SUM(ISNULL(立项税后利润, 0)) AS 立项税后利润,
               SUM(ISNULL(立项税后现金利润, 0)) AS 立项税后现金利润,
               sum(isnull(立项固定资产,0)) as 立项固定资产,
               sum(isnull(立项贷款金额,0)) as 立项贷款金额,
               SUM(ISNULL(定位可售面积, 0)) AS 定位可售面积,
               SUM(ISNULL(定位总建筑面积, 0)) AS 定位总建筑面积,
               SUM(ISNULL(定位地下建筑面积, 0)) AS 定位地下建筑面积,
               SUM(ISNULL(定位套数, 0)) AS 定位套数,
               SUM(ISNULL(定位货值, 0)) AS 定位货值,
               SUM(ISNULL(定位总投资, 0)) AS 定位总投资,
               SUM(ISNULL(定位土地款, 0)) AS 定位土地款,
               SUM(ISNULL(定位除地价外直投, 0)) AS 定位除地价外直投,
               SUM(ISNULL(定位营销费用, 0)) AS 定位营销费用,
               SUM(ISNULL(定位管理费用, 0)) AS 定位管理费用,
               SUM(ISNULL(定位财务费用, 0)) AS 定位财务费用,
               SUM(ISNULL(定位财务费用账面, 0)) as 定位财务费用账面,
               SUM(ISNULL(定位贷款金额, 0)) AS 定位贷款金额,
               SUM(ISNULL(定位贷款利息, 0)) AS 定位贷款利息,
               SUM(ISNULL(定位股东借款利息, 0)) AS 定位股东借款利息,
               CASE
                   WHEN SUM(ISNULL(定位总投资, 0)) = 0 THEN
                       0
                   ELSE
                       SUM(ISNULL(定位税前利润, 0)) * 100 / SUM(ISNULL(定位总投资, 0))
               END 定位税前成本利润率,
               SUM(ISNULL(定位税前利润, 0)) AS 定位税前利润,
               SUM(ISNULL(定位税后利润, 0)) AS 定位税后利润,
               SUM(ISNULL(定位税后现金利润, 0)) AS 定位税后现金利润,
               SUM(ISNULL(定位固定资产, 0)) AS 定位固定资产,
               SUM(ISNULL([定位批复版总建筑面积], 0)) [定位批复版总建筑面积],
               SUM(ISNULL([定位批复版地下建筑面积], 0)) [定位批复版地下建筑面积],
               SUM(ISNULL([定位批复版套数], 0)) [定位批复版套数],
               SUM(ISNULL([定位批复版可售面积], 0)) [定位批复版可售面积],
               NULL [定位批复版定位单价],
               SUM(ISNULL([定位批复版货值], 0)) [定位批复版货值],
               SUM(ISNULL([定位批复版总投资], 0)) [定位批复版总投资],
               SUM(ISNULL([定位批复版土地款], 0)) [定位批复版土地款],
               SUM(ISNULL([定位批复版除地价外直投], 0)) [定位批复版除地价外直投],
               SUM(ISNULL([定位批复版营销费用], 0)) [定位批复版营销费用],
               SUM(ISNULL([定位批复版管理费用], 0)) [定位批复版管理费用],
               SUM(ISNULL([定位批复版财务费用计划口径], 0)) [定位批复版财务费用计划口径],
               SUM(ISNULL([定位批复版财务费用账面口径], 0)) [定位批复版财务费用账面口径],
               SUM(ISNULL([定位批复版贷款金额], 0)) [定位批复版贷款金额],
               SUM(ISNULL([定位批复版贷款利息], 0)) [定位批复版贷款利息],
               SUM(ISNULL([定位批复版股东借款利息], 0)) [定位批复版股东借款利息],
               CASE
                   WHEN SUM(ISNULL([定位批复版总投资], 0)) = 0 THEN
                       0
                   ELSE
                       SUM(ISNULL([定位批复版税前利润], 0)) * 100 / SUM(ISNULL([定位批复版总投资], 0))
               END [定位批复版税前成本利润率],
               SUM(ISNULL([定位批复版税前利润], 0)) [定位批复版税前利润],
               SUM(ISNULL([定位批复版税后利润], 0)) [定位批复版税后利润],
               SUM(ISNULL([定位批复版税后现金利润], 0)) [定位批复版税后现金利润],
               SUM(ISNULL(定位批复版固定资产, 0)) AS 定位批复版固定资产,
               case when bi.组织架构类型 = 3 then bi.组织架构id else null end as 项目guid
        FROM ydkb_dthz_wq_deal_lxdwinfo b
            INNER JOIN ydkb_BaseInfo bi
                ON bi.组织架构ID = b.组织架构父级ID
        WHERE b.组织架构类型 = @baseinfo
        GROUP BY bi.组织架构父级ID,
                 bi.组织架构ID,
                 bi.组织架构名称,
                 bi.组织架构编码,
                 bi.组织架构类型;

        SET @baseinfo = @baseinfo - 1;

    END;

    -----更新项目层级时间指标
    --更新项目的IRR、收回股东投资时间、现金流回正时间、首次开盘销售时间
    --立项

    UPDATE t
    SET t.立项首开时间 = xminfo.首开时间,
        t.立项收回股东投资时间 = xminfo.收回股东投资时间,
        t.立项现金流回正时间 = xminfo.现金流回正时间,
        t.立项实际开工时间 = xminfo.立项实际开工时间,
        t.立项竣工时间 = xminfo.立项竣工时间,
        t.立项交付时间 = xminfo.首期结转时间
    FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
        INNER JOIN
        (
            SELECT t.ProjGUID,
                   SckpDate AS 首开时间,
                   ShgdtzDate AS 收回股东投资时间,
                   SxzxjlDate AS 现金流回正时间,
                   SjkgDate as 立项实际开工时间,
                   ZtjgDate as 立项竣工时间,
                   SqjzDate as 首期结转时间
            FROM mdm_ProjectNodeIndex t
                INNER JOIN #mdm_project pj
                    ON t.ProjGUID = pj.ProjGUID
        ) xminfo
            ON t.组织架构ID = xminfo.ProjGUID;


    UPDATE t
    SET t.立项IRR = xminfo.IRR,
    t.立项自有资金内部收益率 = xminfo.Zyzjnbsyl
    FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
        INNER JOIN
        (
            SELECT t.ProjGUID,
                   Qtznbsyl AS IRR,
                   Zyzjnbsyl
            FROM dbo.mdm_ProjectIncomeIndex t
                INNER JOIN #mdm_project pj
                    ON t.ProjGUID = pj.ProjGUID
            WHERE ProductGUID = '00000000-0000-0000-0000-000000000000'
        ) xminfo
            ON t.组织架构ID = xminfo.ProjGUID;

    --定位
    --经营性现金流回正时间 
    SELECT t1.ProjGUID,
           t1.cashDate,
           t1.dw_ver,
           SUM(t2.CurIRRCashFlow) AS 累计经营性现金流,
           SUM(t2.CurSelfCashFlow) AS 股东回收现金流,
           SUM(t2.CurHL) AS 当期回笼
    INTO #t1
    FROM
    (
        SELECT c.ProjGUID,
               dw_ver,
               CurIRRCashFlow,
               CurSelfCashFlow,
               CurHL,
               CASE
                   WHEN RIGHT(c.Month, 1) = '月' THEN
                       DATEADD(
                                  d,
                                  -1,
                                  DATEADD(
                                             mm,
                                             DATEDIFF(
                                                         m,
                                                         0,
                                                         CONVERT(
                                                                    DATE,
                                                                    REPLACE(REPLACE(c.Month, '年', '-'), '月', '-') + '1'
                                                                )
                                                     ) + 1,
                                             0
                                         )
                              )
               END cashDate
        FROM dbo.mdm_DWCashFlow c
            INNER JOIN #dw_ver ver
                ON c.ProjGUID = ver.ProjGUID
                   AND c.VersionGUID = ver.VersionGUID
            INNER JOIN #mdm_project pj
                ON c.ProjGUID = pj.ProjGUID
        WHERE CHARINDEX('月', c.Month) > 0
    ) t1
        LEFT JOIN
        (
            SELECT c.ProjGUID,
                   dw_ver,
                   CurIRRCashFlow,
                   CurSelfCashFlow,
                   CurHL,
                   CASE WHEN RIGHT(c.Month, 1) = '月' THEN
                           DATEADD(
                                      d,
                                      -1,
                                      DATEADD(
                                                 mm,
                                                 DATEDIFF(
                                                             m,
                                                             0,
                                                             CONVERT(
                                                                        DATE,
                                                                        REPLACE(REPLACE(c.Month, '年', '-'), '月', '-')
                                                                        + '1'
                                                                    )
                                                         ) + 1,
                                                 0
                                             )
                                  )
                   END cashDate
            FROM dbo.mdm_DWCashFlow c
                INNER JOIN #dw_ver ver
                    ON c.ProjGUID = ver.ProjGUID
                       AND c.VersionGUID = ver.VersionGUID
                INNER JOIN #mdm_project pj
                    ON c.ProjGUID = pj.ProjGUID
            WHERE CHARINDEX('月', c.Month) > 0
        ) t2
            ON t1.ProjGUID = t2.ProjGUID
               AND t1.dw_ver = t2.dw_ver
    WHERE t1.cashDate >= t2.cashDate
    GROUP BY t1.cashDate,
             t1.ProjGUID,
             t1.dw_ver
    ORDER BY t1.cashDate,
             t1.ProjGUID;
        
    UPDATE t
    SET t.定位首开时间 = xminfo.FirstReturnDate,
        t.定位收回股东投资时间 = xminfo.CurSelfCashDate,
        t.定位现金流回正时间 = xminfo.CurIRRCashDate,
        t.定位IRR = xminfo.QTZIRR,
        t.定位批复版首开时间 = xminfo.pfFirstReturnDate,
        t.定位批复版收回股东投资时间 = xminfo.pfCurSelfCashDate,
        t.定位批复版现金流回正时间 = xminfo.pfCurIRRCashDate,
        t.定位批复版IRR = xminfo.pfQTZIRR
    FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
        INNER JOIN
        (
            SELECT proj.ProjGUID,
                   max(CASE
                       WHEN jyx.dw_ver = '上报版' THEN
                           jyx.CurIRRCashDate
                       ELSE
                           NULL
                   END) CurIRRCashDate,
                   max(CASE
                       WHEN gd.dw_ver = '上报版' THEN
                           gd.CurSelfCashDate
                       ELSE
                           NULL
                   END) CurSelfCashDate,
                   max(CASE
                       WHEN cash.dw_ver = '上报版' THEN
                           cash.QTZIRR
                       ELSE
                           NULL
                   END) AS QTZIRR,
                   --全投资IRR
                   max(CASE
                       WHEN sqhl.dw_ver = '上报版' THEN
                           sqhl.FirstReturnDate
                       ELSE
                           NULL
                   END) FirstReturnDate,
                   max(CASE
                       WHEN jyx.dw_ver = '批复版' THEN
                           jyx.CurIRRCashDate
                       ELSE
                           NULL
                   END) pfCurIRRCashDate,
                   max(CASE
                       WHEN gd.dw_ver = '批复版' THEN
                           gd.CurSelfCashDate
                       ELSE
                           NULL
                   END) pfCurSelfCashDate,
                   max(CASE
                       WHEN cash.dw_ver = '批复版' THEN
                           cash.QTZIRR
                       ELSE
                           NULL
                   END) AS pfQTZIRR,
                   --全投资IRR    
                   max(CASE
                       WHEN sqhl.dw_ver = '批复版' THEN
                           sqhl.FirstReturnDate
                       ELSE
                           NULL
                   END) pfFirstReturnDate
            FROM #mdm_project proj
                INNER JOIN #dw_ver dw
                    ON dw.ProjGUID = proj.ProjGUID
                LEFT JOIN myBusinessUnit unit
                    ON proj.OrgCompanyGUID = unit.BUGUID
                LEFT JOIN
                (
                    SELECT c.ProjGUID,
                           ver.dw_ver,
                           MAX(   CASE
                                      WHEN MONTH = '全投资IRR' THEN
                                          COALESCE(LJTR, 0)
                                      ELSE
                                          0
                                  END
                              ) AS QTZIRR,
                           MAX(   CASE
                                      WHEN MONTH = '自有资金IRR' THEN
                                          COALESCE(LJTR, 0)
                                      ELSE
                                          0
                                  END
                              ) AS ZYZJIRR
                    FROM mdm_DWCashFlow c
                        INNER JOIN #dw_ver ver
                            ON c.ProjGUID = ver.ProjGUID
                               AND c.VersionGUID = ver.VersionGUID
                        INNER JOIN #mdm_project pj
                            ON c.ProjGUID = pj.ProjGUID
                    WHERE MONTH IN ( '全投资IRR', '自有资金IRR' )
                    GROUP BY c.ProjGUID,
                             ver.dw_ver
                ) cash
                    ON proj.ProjGUID = cash.ProjGUID
                       AND dw.dw_ver = cash.dw_ver --经营性现金流回正时间

                LEFT JOIN
                (
                    SELECT ProjGUID,
                           dw_ver,
                           MIN(cashDate) AS CurIRRCashDate
                    FROM #t1
                    WHERE 累计经营性现金流 > 0
                    GROUP BY ProjGUID,
                             dw_ver
                ) jyx
                    ON jyx.ProjGUID = proj.ProjGUID
                       AND dw.dw_ver = jyx.dw_ver --股东投资回收回正时间

                LEFT JOIN
                (
                    SELECT ProjGUID,
                           dw_ver,
                           MIN(cashDate) AS CurSelfCashDate
                    FROM #t1
                    WHERE 股东回收现金流 > 0
                    GROUP BY ProjGUID,
                             dw_ver
                ) gd
                    ON gd.ProjGUID = proj.ProjGUID
                       AND dw.dw_ver = gd.dw_ver 
                --首次回笼时间
                LEFT JOIN
                (
                --     SELECT ProjGUID,
                --            dw_ver,
                --            MIN(cashDate) AS FirstReturnDate
                --     FROM #t1
                --     WHERE 当期回笼 > 0
                --     GROUP BY ProjGUID,
                --              dw_ver
                       select c.ProjGUID,
                        dw_ver, c.NodesDate as FirstReturnDate
                       from mdm_ProjMilestoneNodes c 
                       INNER JOIN #dw_ver ver ON c.ProjGUID = ver.ProjGUID AND c.VersionGUID = ver.VersionGUID
                       INNER JOIN #mdm_project pj ON c.ProjGUID = pj.ProjGUID
                       where c.Nodes = '首开'
                ) sqhl
                    ON sqhl.ProjGUID = proj.ProjGUID
                       AND dw.dw_ver = sqhl.dw_ver
            WHERE DevelopmentCompanyGUID IN (
                                                SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
                                            )
                  AND proj.Level = 2
				  group by proj.ProjGUID
        ) xminfo
            ON t.组织架构ID = xminfo.ProjGUID ;

        UPDATE t
             SET t.定位最新版IRR = case when ver.vername = '上报版' then 定位IRR else 定位批复版IRR end,
                 t.定位最新版首开时间 =case when ver.vername = '上报版' then 定位首开时间 else 定位批复版首开时间 end,
                 t.定位最新版现金流回正时间 = case when ver.vername = '上报版' then 定位现金流回正时间 else 定位批复版现金流回正时间 end,
                 t.定位最新版收回股东投资时间 = case when ver.vername = '上报版' then 定位收回股东投资时间 else 定位批复版收回股东投资时间 end
            FROM dbo.ydkb_dthz_wq_deal_lxdwinfo t
                INNER JOIN #dw_ver_summary ver ON t.项目guid = ver.ProjGUID;   
 
    SELECT *
    FROM dbo.ydkb_dthz_wq_deal_lxdwinfo; --删除临时表
    
    DROP TABLE #dw,#dwprice, #dw_ver, #lxmj, #lxprice, #lx_cb, #lx_lr, #t1, #mdm_project,
    #dw_cp,#dwprice_cp, #lxmj_cp, #lxprice_cp, #lx_cb_cp, #lx_lr_cp,  #cp,#dw_ver_summary;

END;
 