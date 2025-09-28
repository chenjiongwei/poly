/******************************************************************************************
* 存货报表字段分类说明（用于报表输出字段结构设计）
* 1. 分类：用于区分不同的存货类型及统计口径
* 2. 是否并表：区分“我司并表”、“不并表”等口径
* 3. 产品类型：如住宅、商业、办公等
* 4. 成本合计：项目/产品的总成本
* 5. 账面存货金额：当前账面上存货的金额
* 6. 预计待投入成本：后续预计还需投入的成本
* 7. 货值：可售货值，通常为可售面积*单价
* 8. 融资余额：项目/产品相关的融资余额
* 9. 面积/个数：如可售面积、楼栋数等
* 10. 已售部分：已售部分的相关统计
* 11. 已售金额：已售部分的金额
* 12. 融资期限：相关融资的期限
* 13. 其中：一年内到期：一年内到期的融资金额
* 14. 融资类型：如开发贷、按揭贷等
* 15. 合计：各类金额的合计
******************************************************************************************/

/******************************************************************************************
* 存储过程名称：[dbo].[usp_cb_存货报表] 'F8176252-C765-4660-82BA-4416352E5485'
* 功能描述    ：生成存货报表，按并表/不并表、产成品/在建开发成本/停工缓建/土地储备等分类统计
* 参数说明    ：
*   @var_buguid  公司GUID，多个用逗号分隔
* 维护记录    ：
*   2025-09-28  chenjw  创建
******************************************************************************************/
CREATE OR ALTER PROC [dbo].[usp_cb_存货报表] (
    @var_buguid VARCHAR(MAX) -- 公司GUID，多个用逗号分隔
)
AS
BEGIN
    /**********************************************
    * 步骤1：创建项目临时表
    * 说明：从erp25库的vmdm_projectFlagnew视图获取项目信息
    *      可根据需要筛选@var_buguid涉及的公司项目
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
      AND flg.projguid IN (SELECT value FROM dbo.fn_Split2(@var_buguid, ','))

    /**********************************************
    * 步骤2：创建楼栋临时表
    * 说明：包含实际竣工时间、实际开工时间、停工缓建等信息
    *      具体字段和来源请根据业务需求补充
    **********************************************/
    -- 缓存产品楼栋信息，包含项目、分期、楼栋、产品、面积、停工等信息
    SELECT   
        p1.projguid AS 项目GUID,                 -- 项目GUID
        p.projguid AS 分期GUID,                  -- 分期GUID
        ms.SaleBldGUID,                          -- 销售楼栋GUID
        p1.spreadname,                           -- 推广名
        gc.GCBldGUID,                            -- 工程楼栋GUID
        ms.BldCode,                              -- 楼栋编码
        gc.BldName AS gcBldName,                 -- 工程楼栋名称
        ISNULL(ms.UpBuildArea, 0) + ISNULL(ms.DownBuildArea, 0) AS zjm, -- 总建筑面积
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
    WHERE 1 = 1 
      AND p1.projguid IN (SELECT 项目GUID FROM #proj) 
    -- 可根据需要添加其他筛选条件，如开发公司、是否停工等

    -- 缓存当天的楼栋底表数据（如面积、货值等）
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
    * 具体统计逻辑请根据业务需求补充
    **********************************************/

    -- 1. 并表
    -- 1.1 并表-产成品：竣工备案实际完成时间不为空，且未停工/缓建
    SELECT 
        pj.项目GUID,
        pj.DevelopmentCompanyGUID,
        pj.平台公司,
        '并表-产成品' AS 类别,                        -- 分类
        sb.ProductType AS 产品类型,                    -- 产品类型
        NULL AS 成本合计,                              -- 成本合计（待补充）
        NULL AS 账面存货金额,                          -- 账面存货金额（待补充）
        NULL AS 预计待投入成本,                        -- 预计待投入成本（待补充）
        SUM(ISNULL(lddb.zhz, 0)) AS 货值,              -- 货值
        NULL AS 融资余额,                              -- 融资余额（待补充）
        NULL AS 面积个数                               -- 面积/个数（待补充）
    FROM #proj pj
    LEFT JOIN (
        SELECT 
            项目GUID,
            SaleBldGUID,
            竣工备案实际完成时间,
            ProductType,
            ProductName
        FROM #ms
        WHERE ISNULL(是否停工, '') NOT IN ('停工', '缓建')
          AND 竣工备案实际完成时间 IS NOT NULL
    ) sb ON sb.项目GUID = pj.项目GUID
    LEFT JOIN #lddbamj lddb ON lddb.SaleBldGUID = sb.SaleBldGUID
    WHERE pj.并表方式 = '我司并表'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司, sb.ProductType

    UNION ALL

    -- 1.2 并表-在建开发成本：竣工备案实际完成时间为空，且未停工/缓建
    SELECT 
        pj.项目GUID,
        pj.DevelopmentCompanyGUID,
        pj.平台公司,
        '并表-在建开发成本' AS 类别,                   -- 分类
        sb.ProductType AS 产品类型,                    -- 产品类型
        NULL AS 成本合计,                              -- 成本合计（待补充）
        NULL AS 账面存货金额,                          -- 账面存货金额（待补充）
        NULL AS 预计待投入成本,                        -- 预计待投入成本（待补充）
        SUM(ISNULL(lddb.zhz, 0)) AS 货值,              -- 货值
        NULL AS 融资余额,                              -- 融资余额（待补充）
        NULL AS 面积个数                               -- 面积/个数（待补充）
    FROM #proj pj
    LEFT JOIN (
        SELECT 
            项目GUID,
            SaleBldGUID,
            竣工备案实际完成时间,
            ProductType,
            ProductName
        FROM #ms
        WHERE ISNULL(是否停工, '') NOT IN ('停工', '缓建')
          AND 竣工备案实际完成时间 IS NULL
    ) sb ON sb.项目GUID = pj.项目GUID
    LEFT JOIN #lddbamj lddb ON lddb.SaleBldGUID = sb.SaleBldGUID
    WHERE pj.并表方式 = '我司并表'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司, sb.ProductType

    UNION ALL

    -- 1.3 并表-停工缓建：停工或缓建
    SELECT 
        pj.项目GUID,
        pj.DevelopmentCompanyGUID,
        pj.平台公司,
        '并表-停工缓建' AS 类别,                       -- 分类
        sb.ProductType AS 产品类型,                    -- 产品类型
        NULL AS 成本合计,                              -- 成本合计（待补充）
        NULL AS 账面存货金额,                          -- 账面存货金额（待补充）
        NULL AS 预计待投入成本,                        -- 预计待投入成本（待补充）
        SUM(ISNULL(lddb.zhz, 0)) AS 货值,              -- 货值
        NULL AS 融资余额,                              -- 融资余额（待补充）
        NULL AS 面积个数                               -- 面积/个数（待补充）
    FROM #proj pj
    LEFT JOIN (
        SELECT 
            项目GUID,
            SaleBldGUID,
            竣工备案实际完成时间,
            ProductType,
            ProductName
        FROM #ms
        WHERE ISNULL(是否停工, '') IN ('停工', '缓建')
    ) sb ON sb.项目GUID = pj.项目GUID
    LEFT JOIN #lddbamj lddb ON lddb.SaleBldGUID = sb.SaleBldGUID
    WHERE pj.并表方式 = '我司并表'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司, sb.ProductType

    UNION ALL

    -- 1.4 并表-土地储备：土地储备类项目
    SELECT 
        pj.项目GUID,
        pj.DevelopmentCompanyGUID,
        pj.平台公司,
        '并表-土地储备' AS 类别,                       -- 分类
        NULL AS 产品类型,                              -- 产品类型
        NULL AS 成本合计,                              -- 成本合计（待补充）
        NULL AS 账面存货金额,                          -- 账面存货金额（待补充）
        NULL AS 预计待投入成本,                        -- 预计待投入成本（待补充）
        NULL AS 货值,                                  -- 货值
        NULL AS 融资余额,                              -- 融资余额（待补充）
        NULL AS 面积个数                               -- 面积/个数（待补充）
    FROM #proj pj
    WHERE pj.并表方式 = '我司并表'
    -- 可根据需要添加项目类型筛选，如 AND pj.项目类型 = '土地储备'
    GROUP BY pj.项目GUID, pj.DevelopmentCompanyGUID, pj.平台公司

    -- 2. 出表（全部留空不统计）
    -- 3. 不并表（可参照上面并表结构补充）

    /**********************************************
    * 步骤4：删除临时表，释放资源
    **********************************************/
    DROP TABLE #proj, #ms, #lddbamj
    -- 如有其他临时表（如#building等），请一并删除
    -- DROP TABLE #building

END