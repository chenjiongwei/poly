-- with zcmjld  as 
-- (     
--           select 
--                    c.ProductBuildGUID AS ProductBuildGUID,
--                    c.BldName AS productbldname,
--                    CASE
--                     WHEN e.ProductType = '地下室/车库' THEN
--                         CASE
--                             WHEN ISNULL(k.RoomSum, 0) > 0 THEN
--                                 CASE
--                                     WHEN ISNULL(k.SaleRoomCount, 0) > 0 THEN
--                                         ISNULL(k.RoomBldAreaSum, 0) * (1 - (ISNULL(c.QHRate, 0) / 100))
--                                     ELSE ISNULL(k.ZcSumRoomBldArea, 0) END
--                             ELSE CASE
--                                         WHEN c.IsHold = '是' THEN ISNULL(c.BuildArea, 0)
--                                         WHEN c.IsHold = '否'
--                                         AND f.IsManualManageProductBld = 1
--                                         AND c.IsSale = '是' THEN ISNULL(c.SaleArea, 0) * (1 - (ISNULL(c.QHRate, 0) / 100))
--                                         WHEN c.IsHold = '否'
--                                         AND f.IsManualManageProductBld = 1
--                                         AND c.IsSale = '否' THEN 0
--                                         WHEN c.IsHold = '否'
--                                         AND f.IsManualManageProductBld = 0
--                                         AND e.IsSale = '是' THEN ISNULL(c.SaleArea, 0) * (1 - (ISNULL(c.QHRate, 0) / 100))
--                                         WHEN c.IsHold = '否'
--                                         AND f.IsManualManageProductBld = 0
--                                         AND e.IsSale = '否' THEN 0
--                                         ELSE 0 END END
--                     ELSE CASE
--                             WHEN (   ISNULL(k.RoomSum, 0) > 0
--                                 AND   ISNULL(ZcRoomCount, 0) > 0) THEN ISNULL(k.ZcSumRoomBldArea, 0)
--                             WHEN (   ISNULL(k.RoomSum, 0) <= 0
--                                 AND   c.IsHold = '是') THEN ISNULL(c.BuildArea, 0)
--                             ELSE 0 END END HoldArea
--                  from (
--                         SELECT a.ProjGUID,
--                                     a.ProjName,
--                                     b.BldGUID,
--                                     b.BldName,
--                                     b.VersionGUID,
--                                     b.CurVersion,
--                                     a.ParentProjGUID
--                                 FROM [172.16.4.129].MyCost_Erp352.dbo.md_Project a WITH(NOLOCK)
--                                 JOIN (   SELECT MAX(CreateDate) AS CreateDate,
--                                                 ProjGUID
--                                             FROM [172.16.4.129].MyCost_Erp352.dbo.md_Project WITH(NOLOCK)
--                                             WHERE ApproveState             = '已审核'
--                                             AND ISNULL(CreateReason, '') <> '补录'
--                                             GROUP BY ProjGUID) a_1
--                                     ON a.CreateDate  = a_1.CreateDate
--                                 AND a.ProjGUID    = a_1.ProjGUID
--                                 JOIN [172.16.4.129].MyCost_Erp352.dbo.md_GCBuild b
--                                     ON a.ProjGUID    = b.ProjGUID
--                                 AND a.VersionGUID = b.VersionGUID
--                                 AND b.CurVersion NOT IN ( '预售查丈版', '竣工验收版' )
--                                 AND NOT EXISTS (   SELECT 1
--                                                         FROM [172.16.4.129].MyCost_Erp352.dbo.md_GCBuild g
--                                                     WHERE g.bldguid  = b.BldGUID
--                                                         AND g.ProjGUID = b.ProjGUID
--                                                         AND g.IsActive = 1
--                                                         AND g.CurVersion IN ( '预售查丈版', '竣工验收版' ))
--                                 UNION ALL
--                                 SELECT      p.ProjGUID,
--                                             p.ProjName,
--                                             gc.BldGUID,
--                                             gc.BldName,
--                                             gc.VersionGUID,
--                                             gc.CurVersion,
--                                             p.ParentProjGUID
--                                 FROM  [172.16.4.129].MyCost_Erp352.dbo.md_GCBuild gc WITH(NOLOCK)
--                                 INNER JOIN [172.16.4.129].MyCost_Erp352.dbo.md_Project p WITH(NOLOCK)
--                                     ON p.ProjGUID = gc.ProjGUID
--                                 AND p.IsActive = 1
--                                 WHERE      gc.IsActive = 1
--                                 AND      gc.CurVersion IN ( '预售查丈版', '竣工验收版' )
--                 ) bld 
--            left  JOIN   [172.16.4.129].MyCost_Erp352.dbo.md_ProductBuild c WITH(NOLOCK) ON bld.BldGUID        = c.BldGUID AND bld.VersionGUID    = c.VersionGUID
--            LEFT JOIN [172.16.4.129].MyCost_Erp352.dbo.md_Product e  WITH(NOLOCK) ON c.ProductGUID      = e.ProductGUID AND c.VersionGUID      = e.VersionGUID
--            LEFT JOIN [172.16.4.129].MyCost_Erp352.dbo.md_Project f WITH(NOLOCK) ON bld.ParentProjGUID = f.ProjGUID AND f.IsActive         = 1
--            LEFT JOIN (   SELECT COUNT(0) AS RoomSum,
--                         ProductBldGUID,
--                         SUM(ISNULL(BldArea, 0)) AS RoomBldAreaSum,
--                         SUM(CASE
--                                     WHEN UseProperty = '出售'
--                                     OR UseProperty = '租售' THEN ISNULL(BldArea, 0)
--                                     ELSE 0 END) AS SumRoomBldArea,
--                         SUM(CASE
--                                     WHEN UseProperty = '出售'
--                                     OR UseProperty = '租售' THEN 1
--                                     ELSE 0 END) AS SaleRoomCount,
--                         SUM(CASE
--                                     WHEN UseProperty = '经营'
--                                     OR UseProperty = '留存自用' THEN ISNULL(BldArea, 0)
--                                     ELSE 0 END) AS ZcSumRoomBldArea,
--                         SUM(CASE
--                                     WHEN UseProperty = '经营'
--                                     OR UseProperty = '留存自用' THEN 1
--                                     ELSE 0 END) AS ZcRoomCount
--                     FROM [172.16.4.129].MyCost_Erp352.dbo.md_Room WITH(NOLOCK)
--                     --WHERE UseProperty <> '公配化房间'
--                     GROUP BY ProductBldGUID
--         ) k ON c.ProductBuildGUID = k.ProductBldGUID
--         where bld.Projguid = 'A4A8125C-56D9-E711-80BA-E61F13C57837'
-- )

SELECT
            gb.ProjGUID,
			sb.salebldguid,
			sb.ProductBldName,
            SUM(
                ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0)
            ) AS BuildArea,
            -- SUM(ISNULL(sb.SaleArea, 0)) AS SaleArea,
            SUM(ISNULL(lddb.zksmj, 0)) AS SaleArea, --取楼栋底表的总可售面积
            SUM(ISNULL(lddb.ytwsmj, 0) + ISNULL(lddb.wtmj, 0)) AS symj,
            SUM(
                CASE
                    WHEN lddb.SJjgbadate IS NOT NULL  -- AND DATEDIFF(DAY, lddb.SJjgbadate, '2025-05-31') <= 0 
                    THEN ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0)
                    ELSE 0
                END
            ) AS jbbuildarea530, --获取竣备证日期在530以前的楼栋建面之和 
            SUM(case when lddb.SJjgbadate IS NOT NULL  -- AND DATEDIFF(DAY, lddb.SJjgbadate, '2025-05-31') <= 0  
                           then ISNULL(lddb.zksmj, 0) else  0 end  ) AS SaleArea530,
						      
            --  sum(case when lddb.IsHold ='是' and lddb.SJjgbadate IS NOT NULL  -- AND DATEDIFF(DAY, lddb.SJjgbadate, '2025-05-31') <= 0 
            --          then ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0) 
			-- 			when  lddb.IsHold ='否' and lddb.SJjgbadate IS NOT NULL
            --            --ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0) - ISNULL(lddb.zksmj, 0)  
            --          then  isnull( mdroom.zcbldarea,0 )
            --        end
            -- ) as IsHoldArea530 -- 截止530之前的自持建筑面积

            sum( case when  lddb.SJjgbadate IS NOT NULL then
                    zcmjld.HoldArea else  0 end ) AS IsHoldArea530 --自持面积
        FROM
            [172.16.4.129].erp25.dbo.p_lddbamj lddb WITH(NOLOCK)
            LEFT JOIN [172.16.4.129].erp25.dbo.mdm_SaleBuild sb WITH(NOLOCK) ON sb.SaleBldGUID = lddb.SaleBldGUID
            LEFT JOIN [172.16.4.129].erp25.dbo.mdm_GCBuild gb WITH(NOLOCK) ON gb.GCBldGUID = lddb.GCBldGUID
            left join (
                    select 
                        c.ProductBuildGUID AS ProductBuildGUID,
                        c.BldName AS productbldname,
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
                                ELSE 0 END END HoldArea
                        from (
                            SELECT a.ProjGUID,
                                        a.ProjName,
                                        b.BldGUID,
                                        b.BldName,
                                        b.VersionGUID,
                                        b.CurVersion,
                                        a.ParentProjGUID
                                    FROM [172.16.4.129].MyCost_Erp352.dbo.md_Project a WITH(NOLOCK)
                                    JOIN (   SELECT MAX(CreateDate) AS CreateDate,
                                                    ProjGUID
                                                FROM [172.16.4.129].MyCost_Erp352.dbo.md_Project WITH(NOLOCK)
                                                WHERE ApproveState             = '已审核'
                                                AND ISNULL(CreateReason, '') <> '补录'
                                                GROUP BY ProjGUID) a_1
                                        ON a.CreateDate  = a_1.CreateDate
                                    AND a.ProjGUID    = a_1.ProjGUID
                                    JOIN [172.16.4.129].MyCost_Erp352.dbo.md_GCBuild b
                                        ON a.ProjGUID    = b.ProjGUID
                                    AND a.VersionGUID = b.VersionGUID
                                    AND b.CurVersion NOT IN ( '预售查丈版', '竣工验收版' )
                                    AND NOT EXISTS (   SELECT 1
                                                            FROM [172.16.4.129].MyCost_Erp352.dbo.md_GCBuild g
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
                                    FROM  [172.16.4.129].MyCost_Erp352.dbo.md_GCBuild gc WITH(NOLOCK)
                                    INNER JOIN [172.16.4.129].MyCost_Erp352.dbo.md_Project p WITH(NOLOCK)
                                        ON p.ProjGUID = gc.ProjGUID
                                    AND p.IsActive = 1
                                    WHERE      gc.IsActive = 1
                                    AND      gc.CurVersion IN ( '预售查丈版', '竣工验收版' )
                    ) bld 
                    left  JOIN   [172.16.4.129].MyCost_Erp352.dbo.md_ProductBuild c WITH(NOLOCK) ON bld.BldGUID        = c.BldGUID AND bld.VersionGUID    = c.VersionGUID
                    LEFT JOIN [172.16.4.129].MyCost_Erp352.dbo.md_Product e  WITH(NOLOCK) ON c.ProductGUID      = e.ProductGUID AND c.VersionGUID      = e.VersionGUID
                    LEFT JOIN [172.16.4.129].MyCost_Erp352.dbo.md_Project f WITH(NOLOCK) ON bld.ParentProjGUID = f.ProjGUID AND f.IsActive         = 1
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
                        FROM [172.16.4.129].MyCost_Erp352.dbo.md_Room WITH(NOLOCK)
                        --WHERE UseProperty <> '公配化房间'
                        GROUP BY ProductBldGUID
                    ) k ON c.ProductBuildGUID = k.ProductBldGUID
                    -- where bld.Projguid = 'A4A8125C-56D9-E711-80BA-E61F13C57837'
            ) zcmjld ON  zcmjld.ProductBuildGUID= lddb.SaleBldGUID
WHERE
    DATEDIFF(DAY, '2025-08-15', QXDate) = 0
    --and sb.SaleBldGUID='3361FA9F-BD6B-4F06-A38F-E384A1D534DB'
    and gb.projguid = 'A4A8125C-56D9-E711-80BA-E61F13C57837'
GROUP BY
    gb.ProjGUID,
    sb.salebldguid,
    sb.ProductBldName