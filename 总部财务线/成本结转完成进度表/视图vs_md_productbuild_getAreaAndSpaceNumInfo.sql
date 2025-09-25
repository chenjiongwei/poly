-- vs_md_productbuild_getAreaAndSpaceNumInfo 视图的取数逻辑

SELECT      f.ProjName AS pprojname,
            bld.ProjGUID AS ProjGUID,
            bld.ProjName AS projname,
            bld.BldGUID AS BldGUID,
            bld.BldName AS gcbldname,
            c.ProductBuildGUID AS ProductBuildGUID,
            c.BldName AS productbldname,
			   ISNULL(dd.YdArea, 0) AS YdArea,--用地面积
            c.BuildArea AS BuildArea, --建筑面积
            c.JrArea AS JrArea,--计容面积
            mo.PhyAddress,--地上地下
            --CASE WHEN THEN ELSE END 
            CASE
                 WHEN e.ProductType = '地下室/车库' THEN
                     CASE
                          WHEN ISNULL(k.RoomSum, 0) > 0 THEN
                              CASE
                                   WHEN ISNULL(k.SaleRoomCount, 0) > 0 THEN
                                       ISNULL(k.RoomBldAreaSum, 0) * (ISNULL(c.QHRate, 0) / 100)
                                   ELSE 0 END
                          ELSE CASE
                                    WHEN c.IsHold = '是' THEN 0
                                    WHEN c.IsSale = '是'
                                     AND c.IsHold = '否' THEN ISNULL(c.SaleArea, 0) * (ISNULL(c.QHRate, 0) / 100)
                                    ELSE 0 END END
                 ELSE CASE
                           WHEN (   ISNULL(k.RoomSum, 0) > 0
                              AND   ISNULL(k.SaleRoomCount, 0) > 0) THEN ISNULL(k.SumRoomBldArea, 0)
                           WHEN (   ISNULL(k.RoomSum, 0) <= 0
                              AND   c.IsHold = '否') THEN ISNULL(c.SaleArea, 0)
                           ELSE 0 END END AS SaleArea,--可售面积
            CASE
                 WHEN e.ProductType = '地下室/车库' THEN
                     CASE
                          WHEN ISNULL(k.RoomSum, 0) > 0 THEN
                              CASE
                                   WHEN ISNULL(k.SaleRoomCount, 0) > 0 THEN
                                       ISNULL(k.RoomBldAreaSum, 0) * (1 - (ISNULL(c.QHRate, 0) / 100))
                                   ELSE ISNULL(k.ZcSumRoomBldArea, 0) END
                          ELSE CASE
                                    WHEN c.IsHold = '是' THEN ISNULL(c.BuildArea, 0)
                                    WHEN c.IsHold = '否'
                                     AND f.IsManualManageProductBld = 1
                                     AND c.IsSale = '是' THEN ISNULL(c.SaleArea, 0) * (1 - (ISNULL(c.QHRate, 0) / 100))
                                    WHEN c.IsHold = '否'
                                     AND f.IsManualManageProductBld = 1
                                     AND c.IsSale = '否' THEN 0
                                    WHEN c.IsHold = '否'
                                     AND f.IsManualManageProductBld = 0
                                     AND e.IsSale = '是' THEN ISNULL(c.SaleArea, 0) * (1 - (ISNULL(c.QHRate, 0) / 100))
                                    WHEN c.IsHold = '否'
                                     AND f.IsManualManageProductBld = 0
                                     AND e.IsSale = '否' THEN 0
                                    ELSE 0 END END
                 ELSE CASE
                           WHEN (   ISNULL(k.RoomSum, 0) > 0
                              AND   ISNULL(ZcRoomCount, 0) > 0) THEN ISNULL(k.ZcSumRoomBldArea, 0)
                           WHEN (   ISNULL(k.RoomSum, 0) <= 0
                              AND   c.IsHold = '是') THEN ISNULL(c.BuildArea, 0)
                           ELSE 0 END END AS HoldArea --自持面积
            -- --SUM(CASE WHEN ( d.RoomGUID IS NOT NULL
            -- --                AND ( d.UseProperty = '经营'
            -- --                      OR d.UseProperty = '留存自用'
            -- --                    )
            -- --              ) THEN d.BldArea
            -- --         WHEN ( d.RoomGUID IS NULL
            -- --                AND c.IsHold = '是'
            -- --              ) THEN c.BuildArea
            -- --         ELSE 0
            -- --    END) AS HoldArea ,
            -- CASE
            --      WHEN (   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) > 0) THEN
            --          CASE
            --               WHEN ISNULL(k.SaleRoomCount, 0) > 0 THEN
            --                   ISNULL(k.RoomSum, 0) - (CEILING(ISNULL(k.RoomSum, 0) * (ISNULL(c.QHRate, 0) / 100)))
            --               ELSE ISNULL(k.ZcRoomCount, 0) END
            --      WHEN (   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   c.IsHold = '是') THEN c.HbgNum
            --      WHEN (   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   f.IsManualManageProductBld = 1
            --         AND   c.IsHold = '否'
            --         AND   c.IsSale = '是') THEN c.HbgNum - (CEILING(c.HbgNum * (ISNULL(c.QHRate, 0) / 100)))
            --      WHEN (   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   f.IsManualManageProductBld = 1
            --         AND   c.IsHold = '否'
            --         AND   c.IsSale = '否') THEN 0
            --      WHEN (   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   f.IsManualManageProductBld = 0
            --         AND   c.IsHold = '否'
            --         AND   e.IsSale = '是') THEN c.HbgNum - (CEILING(c.HbgNum * (ISNULL(c.QHRate, 0) / 100)))
            --      WHEN (   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   f.IsManualManageProductBld = 0
            --         AND   c.IsHold = '否'
            --         AND   e.IsSale = '否') THEN 0
            --      ELSE 0 END AS HoldSpaceNum,
            -- CASE
            --      WHEN (   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) > 0) THEN
            --          CASE
            --               WHEN ISNULL(k.SaleRoomCount, 0) > 0 THEN
            --                   CEILING(ISNULL(k.RoomSum, 0) * (ISNULL(c.QHRate, 0) / 100))
            --               ELSE 0 END
            --      -- IsManualManageProductBld=1 条件为md_ProductBuild表的IsSale
            --      WHEN (   f.IsManualManageProductBld = 1
            --         AND   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   c.IsSale = '是'
            --         AND   c.IsHold = '否') THEN CEILING(c.HbgNum * (ISNULL(c.QHRate, 0) / 100))
            --      WHEN (   f.IsManualManageProductBld = 1
            --         AND   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   c.IsSale = '否') THEN 0
            --      -- IsManualManageProductBld=0 条件为md_Product表的IsSale
            --      WHEN (   f.IsManualManageProductBld = 0
            --         AND   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   e.IsSale = '是'
            --         AND   c.IsHold = '否') THEN CEILING(c.HbgNum * (ISNULL(c.QHRate, 0) / 100))
            --      WHEN (   f.IsManualManageProductBld = 0
            --         AND   e.ProductType = '地下室/车库'
            --         AND   ISNULL(k.RoomSum, 0) <= 0
            --         AND   e.IsSale = '否') THEN 0
            --      ELSE 0 END AS SaleSpaceNum
  FROM     
   (   
                  SELECT a.ProjGUID,
                       a.ProjName,
                       b.BldGUID,
                       b.BldName,
                       b.VersionGUID,
					        b.CurVersion,
                       a.ParentProjGUID
                  FROM dbo.md_Project a
                  JOIN (   SELECT MAX(CreateDate) AS CreateDate,
                                  ProjGUID
                             FROM dbo.md_Project
                            WHERE ApproveState             = '已审核'
                              AND ISNULL(CreateReason, '') <> '补录'
                            GROUP BY ProjGUID) a_1
                    ON a.CreateDate  = a_1.CreateDate
                   AND a.ProjGUID    = a_1.ProjGUID
                  JOIN dbo.md_GCBuild b
                    ON a.ProjGUID    = b.ProjGUID
                   AND a.VersionGUID = b.VersionGUID
                   AND b.CurVersion NOT IN ( '预售查丈版', '竣工验收版' )
                   AND NOT EXISTS (   SELECT 1
                                        FROM md_GCBuild g
                                       WHERE g.bldguid  = b.BldGUID
                                         AND g.ProjGUID = b.ProjGUID
                                         AND g.IsActive = 1
                                         AND g.CurVersion IN ( '预售查丈版', '竣工验收版' ))
                UNION ALL
                SELECT      p.ProjGUID,
                            p.ProjName,
                            gc.BldGUID,
                            gc.BldName,
                            gc.VersionGUID,
							gc.CurVersion,
                            p.ParentProjGUID
                  FROM      md_GCBuild gc
                 INNER JOIN md_Project p
                    ON p.ProjGUID = gc.ProjGUID
                   AND p.IsActive = 1
                 WHERE      gc.IsActive = 1
                   AND      gc.CurVersion IN ( '预售查丈版', '竣工验收版' )
   ) bld
  JOIN      dbo.md_ProductBuild c ON bld.BldGUID = c.BldGUID AND bld.VersionGUID    = c.VersionGUID
  --LEFT JOIN dbo.md_Room d ON c.ProductBuildGUID = d.ProductBldGUID
  LEFT JOIN dbo.md_Product e ON c.ProductGUID      = e.ProductGUID AND c.VersionGUID      = e.VersionGUID
  left join MyCost_Erp352.dbo.md_Product_work pro on e.projguid = pro.projguid and e.versionguid = pro.versionguid and e.productkeyguid = pro.productkeyguid
  left JOIN MyCost_Erp352.dbo.md_ProductDtl_work dd ON pro.ProductKeyGUID = dd.ProductKeyGUID
  JOIN      dbo.md_Project f ON bld.ParentProjGUID = f.ProjGUID AND f.IsActive         = 1
  LEFT JOIN (   SELECT COUNT(0) AS RoomSum,
                       ProductBldGUID,
                       SUM(ISNULL(BldArea, 0)) AS RoomBldAreaSum,
                       SUM(CASE
                                WHEN UseProperty = '出售'
                                  OR UseProperty = '租售' THEN ISNULL(BldArea, 0)
                                ELSE 0 END) AS SumRoomBldArea,
                       SUM(CASE
                                WHEN UseProperty = '出售'
                                  OR UseProperty = '租售' THEN 1
                                ELSE 0 END) AS SaleRoomCount,
                       SUM(CASE
                                WHEN UseProperty = '经营'
                                  OR UseProperty = '留存自用' THEN ISNULL(BldArea, 0)
                                ELSE 0 END) AS ZcSumRoomBldArea,
                       SUM(CASE
                                WHEN UseProperty = '经营'
                                  OR UseProperty = '留存自用' THEN 1
                                ELSE 0 END) AS ZcRoomCount
                  FROM dbo.md_Room
                 --WHERE UseProperty <> '公配化房间'
                 GROUP BY ProductBldGUID
    ) k ON c.ProductBuildGUID = k.ProductBldGUID
  left  join MyCost_Erp352.dbo.[vmd_Product_Work] d ON c.ProductKeyGUID=d.ProductKeyGUID and  c.VersionGUID=d.VersionGUID and  d.ProjGUID=c.ProjGUID 
  LEFT JOIN MyCost_Erp352.dbo.md_ProductNameModule mo ON mo.ProductName = d.ProductName AND mo.ProductType = d.ProductType 
  -- where bld.projguid = 'A4A8125C-56D9-E711-80BA-E61F13C57837';