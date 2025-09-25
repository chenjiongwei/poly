use TaskCenterData
go
    -- 成本结转完成进度表
SELECT
    dc.DevelopmentCompanyName AS 区域,
    p1.projname AS 项目,
    p1.SpreadName AS 推广名,
    p.projname AS 分期,
    ld.symj AS 未售面积,
    -- 剩余可售面积
    p1.AcquisitionDate AS 项目获取时间,
    ld.BuildArea AS 总建筑面积,
    ld.SaleArea AS 总可售面积,
    -- ld.jbbuildarea AS 截至5月底已竣备建筑面积,
    ld.SaleArea530 as  截止5月底已竣备的可售面积,
    ld.IsHoldArea530 AS 截止5月底已竣备的自持面积,

    --截止到530累计结转开发产品面积之和
    jz_530.JzTotalArea AS 截至5月底已收入结转面积,
    frist_jz.VersionName AS 产成品结转初始化版本,
    frist_jz.ApproveDate AS 产成品结转初始化时间,
    frist_jz.Creator AS 产成品结转初始化操作人,
    isnull(frist_jz.JzTotalArea, cbjz.TotalArea) AS 产成品结转初始化结转面积,
    main_frist_jz.VersionName AS 主营业务成本结转初始化版本,
    main_frist_jz.ApproveDate AS 主营业务成本结转初始化时间,
    main_frist_jz.Creator AS 主营业务成本结转初始化操作人,
    isnull(main_frist_jz.MainJzTotalArea,pld.TotalArea) AS 主营业务成本结转初始化结转面积,
    jz.ApproveDate AS 最新的产成品结转单据日期,
    main_jz.ApproveDate AS 最新的主营业务结转单据日期,
    jz.ProductCostRecollectName AS 最新的产成品结转单据所引用的动态成本版本,
    main_jz.ProductCostRecollectName AS 最新的主营业务成本结转单据所引用的动态成本版本
FROM
    [172.16.4.129].erp25.dbo.mdm_project p
    LEFT JOIN [172.16.4.129].erp25.dbo.mdm_project p1 ON p.parentprojguid = p1.projguid
    INNER JOIN [172.16.4.129].erp25.dbo.[p_DevelopmentCompany] dc ON dc.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
    LEFT JOIN (
        SELECT
            gb.ProjGUID,
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
            sum(case when lddb.IsHold ='是' and lddb.SJjgbadate IS NOT NULL  -- AND DATEDIFF(DAY, lddb.SJjgbadate, '2025-05-31') <= 0 
                     then ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0) 
                   else  
                       --ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0) - ISNULL(lddb.zksmj, 0)  
                       isnull( mdroom.zcbldarea,0 )
                   end
            ) as IsHoldArea530 -- 截止530之前的自持建筑面积
        FROM
            [172.16.4.129].erp25.dbo.p_lddbamj lddb
            LEFT JOIN [172.16.4.129].erp25.dbo.mdm_SaleBuild sb ON sb.SaleBldGUID = lddb.SaleBldGUID
            LEFT JOIN [172.16.4.129].erp25.dbo.mdm_GCBuild gb ON gb.GCBldGUID = lddb.GCBldGUID
            -- inner join (
            --     SELECT VersionGUID, ProjGUID,ParentProjGUID,projname,ROW_NUMBER() OVER ( PARTITION BY ProjGUID ORDER BY CreateDate DESC ) rowno 
            --      FROM  [172.16.4.129].MyCost_Erp352.dbo.md_Project where IsActive = 1 ) proj on proj.projguid = gb.projguid and proj.rowno = 1 --项目必须要有激活版，否则排除掉
            -- inner join [172.16.4.129].MyCost_Erp352.dbo.md_ProductBuild pdb on pdb.VersionGUID = proj.VersionGUID and pdb.ProjGUID = proj.ProjGUID --and pdb.rowno=1 项目必须要有激活版，否则排除掉   
            left join (
                 select ProductBldGUID, 
                    sum(isnull(BldArea,0)) as zcbldarea -- 房间自持建筑面积
                 from [172.16.4.129].MyCost_Erp352.dbo.md_room 
                 where  IsSale <>'可售'
                 group by ProductBldGUID
            )  mdroom on mdroom.ProductBldGUID = sb.SaleBldGUID
        WHERE
            DATEDIFF(DAY, '2025-08-11', QXDate) = 0
        GROUP BY
            gb.ProjGUID
    ) ld ON ld.ProjGUID = p.ProjGUID -- -- 截止530 截至5月底已收入结转面积
    -- left join (
    --     SELECT 
    --         bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator,
    --         SUM(bld.TotalArea) AS JzTotalArea --累计已结转面积
    --     FROM   cb_CarryOverDevelopBldDtl bld
    --     INNER JOIN (
    --         SELECT 
    --             ROW_NUMBER() OVER(PARTITION BY projguid ORDER BY ApproveDate DESC) AS rownum, -- 最后一版
    --             CarryOverDevelopGUID,
    --             projguid,
    -- 			VersionName,
    -- 			Creator,
    --             ApproveDate
    --         FROM   cb_CarryOverDevelop 
    --         WHERE  ApproverState = '已审核'  AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
    --     ) t ON t.projguid = bld.projguid   AND t.CarryOverDevelopGUID = bld.CarryOverDevelopGUID   AND t.rownum = 1
    --     WHERE  bld.Subject = 1
    --       --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
    --     GROUP BY bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator
    -- ) jz_530 on jz_530.projguid =p.projguid
    LEFT JOIN (
        SELECT
            r.projguid,
            SUM(r.BldArea1) AS JzTotalArea
        FROM
            [172.16.4.129].erp25.dbo.vs_trade st
            INNER JOIN [172.16.4.129].erp25.dbo.p_room r ON st.roomguid = r.roomguid
        WHERE
			st.status ='激活'
            and r.jzdate IS NOT NULL
            AND DATEDIFF(DAY, r.jzdate, '2025-08-11') >= 0
        GROUP BY
            r.projguid
    ) jz_530 ON jz_530.projguid = p.projguid -- 最新一版产成品结转
    left join (
        SELECT
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator,
            SUM(bld.TotalArea) AS JzTotalArea,
            --累计已结转面积
            max(bld.ProductCostRecollectName) as ProductCostRecollectName
        FROM
            cb_CarryOverDevelopBldDtl bld
            INNER JOIN (
                SELECT
                    ROW_NUMBER() OVER(
                        PARTITION BY projguid
                        ORDER BY
                            ApproveDate DESC
                    ) AS rownum,
                    -- 最后一版
                    CarryOverDevelopGUID,
                    projguid,
                    VersionName,
                    Creator,
                    ApproveDate
                FROM
                    cb_CarryOverDevelop
                WHERE
                    1 = 1 --  ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
            ) t ON t.projguid = bld.projguid
            AND t.CarryOverDevelopGUID = bld.CarryOverDevelopGUID
            AND t.rownum = 1
        WHERE
            bld.Subject = 1 --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
        GROUP BY
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator
    ) jz on jz.projguid = p.projguid -- 第一版的产成品结转单据
    left join (
        SELECT
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator,
            SUM(bld.TotalArea) AS JzTotalArea,
            --累计已结转面积
            max(bld.ProductCostRecollectName) as ProductCostRecollectName
        FROM
            cb_CarryOverDevelopBldDtl bld
            INNER JOIN (
                SELECT
                    ROW_NUMBER() OVER(
                        PARTITION BY projguid
                        ORDER BY
                            ApproveDate
                    ) AS rownum,
                    -- 第一版
                    CarryOverDevelopGUID,
                    projguid,
                    VersionName,
                    Creator,
                    ApproveDate
                FROM
                    cb_CarryOverDevelop
                WHERE
                    1 = 1 -- ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
            ) t ON t.projguid = bld.projguid
            AND t.CarryOverDevelopGUID = bld.CarryOverDevelopGUID
            AND t.rownum = 1
        WHERE
            bld.Subject = 1 --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
        GROUP BY
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator
    ) frist_jz on frist_jz.projguid = p.projguid 
    -- 当系统中无结转版本记录，取成本结转-结转开发产品 累计已结转开发产品“面积/个数”列
    left join (
        --usp_cb_InitJGKFCB_BuildView 结转开发产品
        select projguid,sum(isnull(TotalArea,0)) as TotalArea
        from cb_CarryOverDevelopSetBldDtl bld
        where  bld.Subject = 1
        group by projguid
        -- select
        --     t3.ProjGUID,
        --     sum (ISNULL(t3.SaleArea, 0) + ISNULL(t3.HoldArea, 0)) as JzAllArea
        -- from
        --     [172.16.4.129].MyCost_Erp352.dbo.vs_md_productbuild_getAreaAndSpaceNumInfo t3 -- where ProjGUID ='3ff3700c-b332-ea11-80b8-0a94ef7517dd' 
        --     -- and ProductBuildGUID ='EA70A41B-535F-462E-AE4D-2DBBD71E97B0'
        -- group by t3.ProjGUID
    ) cbjz on cbjz.ProjGUID = p.projguid 
    -- 当系统中无成本结转-主营业务成本结转的累计已结转主营成本的“面积/个数”列
    left join (
        -- usp_cb_InitJZZYYWCB_BuildView 结转主营业务成本
        select projguid,sum(isnull(TotalArea,0)) as TotalArea
         from   cb_CarryOverMainSetBldDtl bld
         where  bld.Subject = 1
         -- where  ProjGUID ='3ff3700c-b332-ea11-80b8-0a94ef7517dd'
        group by projguid
    ) pld on pld.projguid = p.projguid
    -- 主营业务结转 最新一版
    left join (
        SELECT
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator,
            SUM(bld.TotalArea) AS MainJzTotalArea,
            --累计已结转面积
            max(bld.ProductCostRecollectName) as ProductCostRecollectName
        FROM
            cb_CarryOverMainBldDtl bld
            INNER JOIN (
                SELECT
                    ROW_NUMBER() OVER(
                        PARTITION BY projguid
                        ORDER BY
                            ApproveDate DESC
                    ) AS rownum,
                    -- 最后一版
                    CarryOverMainGUID,
                    projguid,
                    VersionName,
                    Creator,
                    ApproveDate
                FROM
                    cb_CarryOverMain
                WHERE
                    1 = 1 --  ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
            ) t ON t.projguid = bld.projguid
            AND t.CarryOverMainGUID = bld.CarryOverMainGUID
            AND t.rownum = 1
        WHERE
            bld.Subject = 1 --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
        GROUP BY
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator
    ) main_jz on main_jz.projguid = p.projguid -- 主营业务结转 最新一版
    left join (
        SELECT
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator,
            SUM(bld.TotalArea) AS MainJzTotalArea,
            --累计已结转面积
            max(bld.ProductCostRecollectName) as ProductCostRecollectName
        FROM
            cb_CarryOverMainBldDtl bld
            INNER JOIN (
                SELECT
                    ROW_NUMBER() OVER(
                        PARTITION BY projguid
                        ORDER BY
                            ApproveDate
                    ) AS rownum,
                    -- 第一版
                    CarryOverMainGUID,
                    projguid,
                    VersionName,
                    Creator,
                    ApproveDate
                FROM
                    cb_CarryOverMain
                WHERE
                    1 = 1 -- ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
            ) t ON t.projguid = bld.projguid
            AND t.CarryOverMainGUID = bld.CarryOverMainGUID
            AND t.rownum = 1
        WHERE
            bld.Subject = 1 --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
        GROUP BY
            bld.ProjGUID,
            t.ApproveDate,
            t.VersionName,
            t.Creator
    ) main_frist_jz on main_frist_jz.projguid = p.projguid
WHERE
    p.level = 3
    -- and p.ProjGUID = '3ff3700c-b332-ea11-80b8-0a94ef7517dd'