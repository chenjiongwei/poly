

-- select 
-- BldGUID,
-- BldCode,
-- BldName,
-- ProductBldGUID,
-- ProductBldName,
-- TotalCost,* from cb_stockftcosttwo where   projguid='F0BC641F-B8C8-EF11-B3A6-F40270D39969'
-- -- select  * from  cb_StockFtProjVersionZb
-- select  * from  cb_StockFtProjVersion -- 线上分摊
-- select * from cb_StockFtProjVersionPhoto -- 线下分摊

-- select  TotalCost,* from  [dbo].[cb_StockFtCostPhoto] where ProjGUID ='a9cb63b1-a930-e711-80ba-e61f13c57837'


/******************************************************************************************
* 存货报表存储过程
* 过程名称：[dbo].[usp_cb_存货报表]
* 功能描述：生成存货报表，按并表/不并表、产成品/在建开发成本/停工缓建/土地储备等分类统计
* 参数说明：
*   @var_buguid  公司GUID，多个用逗号分隔
  exec [usp_cb_存货报表]  '22930F53-A830-E711-80BA-E61F13C57837' -- 广东公司
******************************************************************************************/

CREATE OR ALTER PROC [dbo].[usp_cb_存货报表] (
    @var_buguid VARCHAR(MAX) -- 平台公司GUID，多个用逗号分隔
)
AS
BEGIN
    /**********************************************
    * 步骤1：创建项目临时表
    * 说明：从erp25库的vmdm_projectFlagnew视图获取项目信息
    *      仅筛选@var_buguid涉及的公司项目
    **********************************************/
    SELECT 
        flg.projguid AS 项目GUID,                -- 项目唯一标识
        flg.DevelopmentCompanyGUID,              -- 开发公司GUID
        flg.平台公司,                            -- 平台公司名称
        flg.推广名,                              -- 推广名
        flg.项目名,                              -- 项目名称
        flg.项目代码,                            -- 项目代码
        flg.投管代码,                            -- 投管代码
        flg.获取时间,                            -- 获取时间
        flg.并表方式                             -- 并表方式（我司并表/不并表等）
    INTO #proj
    FROM erp25.dbo.vmdm_projectFlagnew flg
    INNER JOIN erp25.dbo.mdm_project p ON flg.projguid = p.projguid
    WHERE p.level = 2 
      AND flg.DevelopmentCompanyGUID IN (SELECT value FROM dbo.fn_Split2(@var_buguid, ','))

    /**********************************************
    * 步骤1.1：获取最新的存货成本分摊数据
    * 说明：仅取每个项目最新一次“已审核”版本的分摊数据
    **********************************************/
    SELECT 
        sfp.ProjCode,                -- 项目编码
        sfp.ProjGUID,                -- 项目GUID
        sfp.BldGUID,                 -- 楼栋GUID
        sfp.BldName,                 -- 楼栋名称
        sfp.ProductBldGUID,          -- 产品楼栋GUID
        sfp.ProductBldName,          -- 产品楼栋名称
        sfp.TotalCost                -- 存货成本总数
    INTO #ch
    FROM  [TaskCenterData].dbo.cb_StockFtCostPhoto sfp
    INNER JOIN (
        SELECT  
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY PhotoDate DESC) AS num, -- 取最新
            VersionGUID,
            ProjGUID,
            ProjName,
            PhotoDate
        FROM [TaskCenterData].dbo.cb_StockFtProjVersionPhoto 
        WHERE ApproveState = '已审核'
    ) vr 
        ON vr.VersionGUID = sfp.VersionGUID 
        AND sfp.ProjGUID = vr.ProjGUID 
        AND vr.num = 1

    /**********************************************
    * 步骤1.2：获取最新的楼栋产值数据
    * 说明：仅取每个项目最新一次“已审核”产值月度评审
    **********************************************/
    SELECT 
        bld.OutputValueMonthReviewGUID, -- 产值月度评审GUID
        bld.BldGUID,                    -- 楼栋GUID
        bld.BldName,                    -- 楼栋名称
        bld.ProdBldGUID,                -- 产品楼栋GUID
        bld.ProdBldName,                -- 产品楼栋名称
        bld.Zcz,                        -- 总产值
        bld.Xmpdljwccz                  -- 项目累计已完成产值
    INTO #cz
    FROM cb_OutputValueReviewProdBld bld
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY ReviewDate DESC) AS num, -- 取最新
            OutputValueMonthReviewGUID,
            ProjGUID,
            ReviewDate
        FROM [dbo].[cb_OutputValueMonthReview]
        WHERE ApproveState = '已审核'
    ) vr 
        ON vr.OutputValueMonthReviewGUID = bld.OutputValueMonthReviewGUID 
        AND vr.num = 1

    /**********************************************
    * 步骤1.3：获取最新的开发贷余额数据
    * 说明：仅取每个项目最新一次“有效”版本的开发贷余额
    **********************************************/
    SELECT 
        kfd.ProjGUID,                                   -- 项目GUID
        kfd.ProductBldGUID,                             -- 产品楼栋GUID
        SUM(ISNULL(Fkje, 0) - ISNULL(CurYearPayAmount, 0)) AS kfdye  -- 开发贷余额 = 放款金额 - 本年实际还款金额
    INTO #kfd
    FROM md_ProductBldKfd kfd
    INNER JOIN (
        SELECT 
            VersionGUID, 
            ProjGUID, 
            ParentProjGUID, 
            projname,
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowno -- 取最新
        FROM md_Project 
        WHERE IsActive = 1
    ) a 
        ON kfd.VersionGUID = a.VersionGUID  
        AND kfd.ProjGUID = a.ProjGUID  
        AND a.rowno = 1
    GROUP BY 
        kfd.ProjGUID,
        kfd.ProductBldGUID

    /**********************************************
    * 步骤2：创建楼栋临时表
    * 说明：包含实际竣工时间、实际开工时间、停工缓建等信息
    *      具体字段和来源请根据业务需求补充
    **********************************************/
    -- 缓存产品楼栋信息，包含项目、分期、楼栋、产品、面积、停工等信息
    SELECT   
        p1.projguid AS 项目GUID,                 -- 项目GUID（项目公司级）
        p.projguid AS 分期GUID,                  -- 分期GUID
        ms.SaleBldGUID,                          -- 销售楼栋GUID
        p1.spreadname,                           -- 推广名
        gc.GCBldGUID,                            -- 工程楼栋GUID
        ms.BldCode,                              -- 楼栋编码
        gc.BldName AS gcBldName,                 -- 工程楼栋名称
        ISNULL(ms.UpBuildArea, 0) + ISNULL(ms.DownBuildArea, 0) AS zjm, -- 总建筑面积
        ms.HouseNum,                             -- 户个数
        ms.UpBuildArea AS dsjm,                  -- 地上建筑面积
        ms.DownBuildArea AS dxjm,                -- 地下建筑面积
        pr.ProductType,                          -- 产品类型
        pr.ProductName,                          -- 产品名称
        pr.BusinessType,                         -- 业态类型
        pr.IsSale,                               -- 是否可售
        pr.IsHold,                               -- 是否自持
        pr.STANDARD,                             -- 标准
        ms.UpNum,                                -- 地上层数
        ms.DownNum,                              -- 地下层数
        c.*                                      -- 计划任务执行对象相关字段（如是否停工、竣工备案实际完成时间等）
    INTO #ms
    FROM erp25.dbo.mdm_SaleBuild ms
    INNER JOIN erp25.dbo.mdm_Product pr ON pr.ProductGUID = ms.ProductGUID
    INNER JOIN erp25.dbo.mdm_GCBuild gc ON gc.GCBldGUID = ms.GCBldGUID
    LEFT JOIN erp25.dbo.mdm_project p ON gc.projguid = p.projguid
    LEFT JOIN erp25.dbo.mdm_project p1 ON p.parentprojguid = p1.projguid
    LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b ON ms.GCBldGUID = b.BuildingGUID
    LEFT JOIN MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport c ON b.budguid = c.ztguid
    WHERE p1.projguid IN (SELECT 项目GUID FROM #proj) 
    -- 可根据需要添加其他筛选条件，如开发公司、是否停工等

    /**********************************************
    * 步骤2.1：缓存当天的楼栋底表数据（如面积、货值等）
    * 说明：仅取当天最新的底表数据
    **********************************************/
    SELECT  
        ProjGUID,           -- 项目GUID
        SaleBldGUID,        -- 销售楼栋GUID
        GCBldGUID,          -- 工程楼栋GUID
        ProductType,        -- 产品类型
        ProductName,        -- 产品名称
        zksmj,              -- 总可售面积
        zhz                 -- 总货值
    INTO #lddbamj
    FROM erp25.dbo.p_lddbamj 
    WHERE DATEDIFF(DAY, QXDate, GETDATE()) = 0 

    /**********************************************
    * 步骤3：查询并输出存货报表结果
    * 说明：按以下分类统计
    *   1. 并表
    *      1.1 并表-产成品
    *      1.2 并表-在建开发成本
    *      1.3 并表-停工缓建
    *      1.4 并表-土地储备
    *   2. 出表（全部留空不统计）
    *   3. 不并表
    *      3.1 不并表-产成品
    *      3.2 不并表-在建开发成本
    *      3.3 不并表-停工缓建
    *      3.4 不并表-土地储备
    **********************************************/

    /************ 1. 并表 ************/
    /************ 1.1 并表-产成品：竣工备案实际完成时间不为空，且未停工/缓建 ************/
    SELECT 
        pj.项目GUID,                                 -- 项目GUID
        pj.DevelopmentCompanyGUID,                   -- 开发公司GUID
        pj.平台公司,                                 -- 平台公司名称
        '并表-产成品' AS 类别,                        -- 分类
        sb.ProductType AS 产品类型,                  -- 产品类型
        -- 管理存货合计
        SUM(ISNULL(ch.TotalCost,0)) + SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 成本合计,         -- 成本合计 = 存货成本 + (总产值-累计完成产值)
        SUM(ISNULL(ch.TotalCost,0)) AS 账面存货金额,                                                      -- 账面存货金额
        SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 预计待投入成本,                                 -- 预计待投入成本
        SUM(ISNULL(lddb.zhz, 0)) AS 货值,                                                                -- 货值
        SUM(ISNULL(kfd.kfdye,0)) AS 融资余额,                                                            -- 融资余额
        SUM(CASE WHEN sb.ProductType <> '地下室/车库' THEN ISNULL(sb.zjm,0) ELSE ISNULL(sb.HouseNum,0) END) AS 面积个数 -- 面积/个数
    FROM #proj pj
    INNER JOIN (
        SELECT 
            项目GUID,
            SaleBldGUID,
            竣工备案实际完成时间,
            实际开工实际完成时间,
            ProductType,
            ProductName,
            zjm,
            HouseNum
        FROM #ms
        WHERE ISNULL(是否停工, '') NOT IN ('停工', '缓建')
          AND 竣工备案实际完成时间 IS NOT NULL
    ) sb ON sb.项目GUID = pj.项目GUID
    LEFT JOIN #lddbamj lddb ON lddb.SaleBldGUID = sb.SaleBldGUID
    LEFT JOIN #ch ch ON ch.ProductBldGUID = sb.SaleBldGUID
    LEFT JOIN #cz cz ON cz.BldGUID = sb.SaleBldGUID
    LEFT JOIN #kfd kfd ON kfd.ProductBldGUID = sb.SaleBldGUID
    WHERE pj.并表方式 = '我司并表'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司, sb.ProductType

    UNION ALL

    /************ 1.2 并表-在建开发成本：竣工备案实际完成时间为空，且未停工/缓建 ************/
    SELECT 
        pj.项目GUID,
        pj.DevelopmentCompanyGUID,
        pj.平台公司,
        '并表-在建开发成本' AS 类别,                   -- 分类
        sb.ProductType AS 产品类型,                  -- 产品类型
        SUM(ISNULL(ch.TotalCost,0)) + SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 成本合计,         -- 成本合计
        SUM(ISNULL(ch.TotalCost,0)) AS 账面存货金额,                                                      -- 账面存货金额
        SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 预计待投入成本,                                 -- 预计待投入成本
        SUM(ISNULL(lddb.zhz, 0)) AS 货值,                                                                -- 货值
        SUM(ISNULL(kfd.kfdye,0)) AS 融资余额,                                                            -- 融资余额
        SUM(CASE WHEN sb.ProductType <> '地下室/车库' THEN ISNULL(sb.zjm,0) ELSE ISNULL(sb.HouseNum,0) END) AS 面积个数 -- 面积/个数
    FROM #proj pj
    INNER JOIN (
        SELECT 
            项目GUID,
            SaleBldGUID,
            竣工备案实际完成时间,
            实际开工实际完成时间,
            ProductType,
            ProductName,
            zjm,
            HouseNum
        FROM #ms
        WHERE ISNULL(是否停工, '') NOT IN ('停工', '缓建')
          AND 竣工备案实际完成时间 IS NULL 
          AND 实际开工实际完成时间 IS NOT NULL
    ) sb ON sb.项目GUID = pj.项目GUID
    LEFT JOIN #lddbamj lddb ON lddb.SaleBldGUID = sb.SaleBldGUID
    LEFT JOIN #ch ch ON ch.ProductBldGUID = sb.SaleBldGUID
    LEFT JOIN #cz cz ON cz.BldGUID = sb.SaleBldGUID
    LEFT JOIN #kfd kfd ON kfd.ProductBldGUID = sb.SaleBldGUID
    WHERE pj.并表方式 = '我司并表'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司, sb.ProductType

    UNION ALL

    /************ 1.3 并表-停工缓建：停工或缓建 ************/
    SELECT 
        pj.项目GUID,
        pj.DevelopmentCompanyGUID,
        pj.平台公司,
        '并表-停工缓建' AS 类别,                      -- 分类
        sb.ProductType AS 产品类型,                  -- 产品类型
        SUM(ISNULL(ch.TotalCost,0)) + SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 成本合计,         -- 成本合计
        SUM(ISNULL(ch.TotalCost,0)) AS 账面存货金额,                                                      -- 账面存货金额
        SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 预计待投入成本,                                 -- 预计待投入成本
        SUM(ISNULL(lddb.zhz, 0)) AS 货值,                                                                -- 货值
        SUM(ISNULL(kfd.kfdye,0)) AS 融资余额,                                                            -- 融资余额
        SUM(CASE WHEN sb.ProductType <> '地下室/车库' THEN ISNULL(sb.zjm,0) ELSE ISNULL(sb.HouseNum,0) END) AS 面积个数 -- 面积/个数
    FROM #proj pj
    INNER JOIN (
        SELECT 
            项目GUID,
            SaleBldGUID,
            竣工备案实际完成时间,
            实际开工实际完成时间,
            ProductType,
            ProductName,
            zjm,
            HouseNum
        FROM #ms
        WHERE ISNULL(是否停工, '') IN ('停工', '缓建')
    ) sb ON sb.项目GUID = pj.项目GUID
    LEFT JOIN #lddbamj lddb ON lddb.SaleBldGUID = sb.SaleBldGUID
    LEFT JOIN #ch ch ON ch.ProductBldGUID = sb.SaleBldGUID
    LEFT JOIN #cz cz ON cz.BldGUID = sb.SaleBldGUID
    LEFT JOIN #kfd kfd ON kfd.ProductBldGUID = sb.SaleBldGUID
    WHERE pj.并表方式 = '我司并表'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司, sb.ProductType

    UNION ALL

    /************ 1.4 并表-土地储备：土地储备类项目，未开工的 ************/
    SELECT 
        pj.项目GUID,
        pj.DevelopmentCompanyGUID,
        pj.平台公司,
        '并表-土地储备' AS 类别,                      -- 分类
        sb.ProductType AS 产品类型,                  -- 产品类型
        SUM(ISNULL(ch.TotalCost,0)) + SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 成本合计,         -- 成本合计
        SUM(ISNULL(ch.TotalCost,0)) AS 账面存货金额,                                                      -- 账面存货金额
        SUM(ISNULL(cz.Zcz,0) - ISNULL(cz.Xmpdljwccz,0)) AS 预计待投入成本,                                 -- 预计待投入成本
        SUM(ISNULL(lddb.zhz, 0)) AS 货值,                                                                -- 货值
        SUM(ISNULL(kfd.kfdye,0)) AS 融资余额,                                                            -- 融资余额
        SUM(CASE WHEN sb.ProductType <> '地下室/车库' THEN ISNULL(sb.zjm,0) ELSE ISNULL(sb.HouseNum,0) END) AS 面积个数 -- 面积/个数
    FROM #proj pj
    INNER JOIN (
        SELECT 
            项目GUID,
            SaleBldGUID,
            竣工备案实际完成时间,
            实际开工实际完成时间,
            ProductType,
            ProductName,
            zjm,
            HouseNum
        FROM #ms
        WHERE ISNULL(是否停工, '') NOT IN ('停工', '缓建') 
          AND 实际开工实际完成时间 IS NULL 
    ) sb ON sb.项目GUID = pj.项目GUID
    LEFT JOIN #lddbamj lddb ON lddb.SaleBldGUID = sb.SaleBldGUID
    LEFT JOIN #ch ch ON ch.ProductBldGUID = sb.SaleBldGUID
    LEFT JOIN #cz cz ON cz.BldGUID = sb.SaleBldGUID
    LEFT JOIN #kfd kfd ON kfd.ProductBldGUID = sb.SaleBldGUID
    WHERE pj.并表方式 = '我司并表'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司, sb.ProductType

    -- 2. 出表（全部留空不统计）
    -- 3. 不并表（可参照上面并表结构补充）

    /**********************************************
    * 步骤4：删除临时表，释放资源
    **********************************************/
    DROP TABLE #proj, #ms, #lddbamj, #ch, #cz, #kfd
    -- 如有其他临时表（如#building等），请一并删除
    -- DROP TABLE #building

END

