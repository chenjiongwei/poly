-- 成本结转完成进度表
SELECT 
    dc.DevelopmentCompanyName AS 区域,
    p1.projname AS 项目,
    p.projname AS 分期,
    ld.symj AS 未售面积, -- 剩余可售面积
    p1.AcquisitionDate AS 项目获取时间,
    ld.BuildArea AS 总建筑面积,
    ld.SaleArea AS 总可售面积,
    ld.jbbuildarea AS 截至5月底已竣备建筑面积,
    --截止到530累计结转开发产品面积之和
    jz_530.JzTotalArea AS 截至5月底已收入结转面积,

    frist_jz.VersionName AS 产成品结转初始化版本,
    frist_jz.ApproveDate AS 产成品结转初始化时间,
    frist_jz.Creator AS 产成品结转初始化操作人,
    frist_jz.JzTotalArea AS 产成品结转初始化结转面积,

    main_frist_jz.VersionName AS 主营业务成本结转初始化版本,
    main_frist_jz.ApproveDate AS 主营业务成本结转初始化时间,
    main_frist_jz.Creator AS 主营业务成本结转初始化操作人,
    main_frist_jz.MainJzTotalArea AS 主营业务成本结转初始化结转面积,

    jz.ApproveDate AS 最新的产成品结转单据日期,
    main_jz.ApproveDate AS 最新的主营业务结转单据日期,
    jz.ProductCostRecollectName AS 最新的产成品结转单据所引用的动态成本版本,
    main_jz.ProductCostRecollectName AS 最新的主营业务成本结转单据所引用的动态成本版本
FROM [172.16.4.129].erp25.dbo.mdm_project p 
LEFT JOIN [172.16.4.129].erp25.dbo.mdm_project p1 ON p.parentprojguid = p1.projguid
INNER JOIN [172.16.4.129].erp25.dbo.[p_DevelopmentCompany] dc ON dc.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
LEFT JOIN (
    SELECT 
        gb.ProjGUID,
        SUM(ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0)) AS BuildArea,
        SUM(ISNULL(sb.SaleArea, 0)) AS SaleArea,
        SUM(ISNULL(lddb.ytwsmj, 0) + ISNULL(lddb.wtmj, 0)) AS symj,
        SUM(CASE WHEN lddb.SJjgbadate IS NOT NULL -- AND DATEDIFF(DAY, lddb.SJjgbadate, '2025-05-31') <= 0 
                THEN ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0) 
                ELSE 0 
            END) AS jbbuildarea --获取竣备证日期在530以前的楼栋建面之和 
    FROM [172.16.4.129].erp25.dbo.p_lddbamj lddb
    LEFT JOIN [172.16.4.129].erp25.dbo.mdm_SaleBuild sb ON sb.SaleBldGUID = lddb.SaleBldGUID
    LEFT JOIN [172.16.4.129].erp25.dbo.mdm_GCBuild gb ON gb.GCBldGUID = lddb.GCBldGUID
    WHERE DATEDIFF(DAY, '2025-05-31', QXDate) = 0
    GROUP BY gb.ProjGUID
) ld ON ld.ProjGUID = p.ProjGUID
-- 截止530产成品结转
left join (
    SELECT 
        bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator,
        SUM(bld.TotalArea) AS JzTotalArea --累计已结转面积
    FROM   cb_CarryOverDevelopBldDtl bld
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY projguid ORDER BY ApproveDate DESC) AS rownum, -- 最后一版
            CarryOverDevelopGUID,
            projguid,
			VersionName,
			Creator,
            ApproveDate
        FROM   cb_CarryOverDevelop 
        WHERE  ApproverState = '已审核'  AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
    ) t ON t.projguid = bld.projguid   AND t.CarryOverDevelopGUID = bld.CarryOverDevelopGUID   AND t.rownum = 1
    WHERE  bld.Subject = 1
      --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
    GROUP BY bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator
) jz_530 on jz_530.projguid =p.projguid
-- 最新一版产成品结转
left join (
    SELECT 
        bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator,
        SUM(bld.TotalArea) AS JzTotalArea, --累计已结转面积
        max(bld.ProductCostRecollectName) as ProductCostRecollectName
    FROM   cb_CarryOverDevelopBldDtl bld
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY projguid ORDER BY ApproveDate DESC) AS rownum, -- 最后一版
            CarryOverDevelopGUID,
            projguid,
			VersionName,
			Creator,
            ApproveDate
        FROM   cb_CarryOverDevelop 
        WHERE  ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
    ) t ON t.projguid = bld.projguid   AND t.CarryOverDevelopGUID = bld.CarryOverDevelopGUID   AND t.rownum = 1
    WHERE  bld.Subject = 1
      --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
    GROUP BY bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator
) jz on jz.projguid =p.projguid
-- 第一版的产成品结转单据
left join (
       SELECT 
        bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator,
        SUM(bld.TotalArea) AS JzTotalArea, --累计已结转面积
        max(bld.ProductCostRecollectName) as ProductCostRecollectName
    FROM   cb_CarryOverDevelopBldDtl bld
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY projguid ORDER BY ApproveDate ) AS rownum, -- 第一版
            CarryOverDevelopGUID,
            projguid,
			VersionName,
			Creator,
            ApproveDate
        FROM   cb_CarryOverDevelop 
        WHERE  ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
    ) t ON t.projguid = bld.projguid   AND t.CarryOverDevelopGUID = bld.CarryOverDevelopGUID   AND t.rownum = 1
    WHERE  bld.Subject = 1
      --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
    GROUP BY bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator 
) frist_jz on frist_jz.projguid =p.projguid
-- 主营业务结转 最新一般
left join (
    SELECT 
        bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator,
        SUM(bld.TotalArea) AS MainJzTotalArea, --累计已结转面积
        max(bld.ProductCostRecollectName) as ProductCostRecollectName
    FROM   cb_CarryOverMainBldDtl bld
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY projguid ORDER BY ApproveDate DESC) AS rownum, -- 最后一版
            CarryOverMainGUID,
            projguid,
			VersionName,
			Creator,
            ApproveDate
        FROM   cb_CarryOverMain 
        WHERE  ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
    ) t ON t.projguid = bld.projguid   AND t.CarryOverMainGUID = bld.CarryOverMainGUID   AND t.rownum = 1
    WHERE  bld.Subject = 1
      --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
    GROUP BY bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator
) main_jz on main_jz.projguid =p.projguid
-- 主营业务结转 最新一般
left join (
    SELECT 
        bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator,
        SUM(bld.TotalArea) AS MainJzTotalArea, --累计已结转面积
        max(bld.ProductCostRecollectName) as ProductCostRecollectName
    FROM   cb_CarryOverMainBldDtl bld
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY projguid ORDER BY ApproveDate ) AS rownum, -- 第一版
            CarryOverMainGUID,
            projguid,
			VersionName,
			Creator,
            ApproveDate
        FROM   cb_CarryOverMain 
        WHERE  ApproverState = '已审核'  -- AND DATEDIFF(DAY, ApproveDate, '2025-05-31') >= 0
    ) t ON t.projguid = bld.projguid   AND t.CarryOverMainGUID = bld.CarryOverMainGUID   AND t.rownum = 1
    WHERE  bld.Subject = 1
      --bld.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837' and 
    GROUP BY bld.ProjGUID,t.ApproveDate,t.VersionName,t.Creator
) main_frist_jz on main_frist_jz.projguid =p.projguid
WHERE p.level = 3 -- and p.ProjGUID = '7F2C6488-3C27-E811-80BA-E61F13C57837'


