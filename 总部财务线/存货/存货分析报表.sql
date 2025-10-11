-- 存货报表
/******************************************************************************************
* 存货报表存储过程
* 过程名称：[dbo].[usp_cb_存货分析报表]
* 功能描述：生成存货报表，按并表/不并表、产成品/在建开发成本/停工缓建/土地储备等分类统计
* 参数说明：
*   @var_buguid  公司GUID，多个用逗号分隔
* 使用示例：
*   exec [usp_cb_存货分析报表]  '22930F53-A830-E711-80BA-E61F13C57837' -- 广东公司
* 测试项目：
*   线上分摊：广州市天河区员村二横路以西720、721地块-一期  1BCF8FE5-46C7-EF11-B3A6-F40270D39969
*   线下分摊：广州大塱村项目-二期
******************************************************************************************/

CREATE OR ALTER PROC [dbo].[usp_cb_存货分析报表] (
    @var_buguid VARCHAR(MAX) -- 平台公司GUID，多个用逗号分隔
)
AS
BEGIN
    -- 项目分类说明
    -- 存量 就是 "存量项目"
    -- 增量 就是 "增量项目、⑦增量项目、已投资未落实"
    -- 其他标签的归纳到"其他"

    -- 步骤1：获取项目基本信息
    SELECT 
        flg.projguid AS 项目GUID,                -- 项目唯一标识
        flg.DevelopmentCompanyGUID,              -- 开发公司GUID
        flg.平台公司,                            -- 平台公司名称
        flg.推广名,                              -- 推广名
        flg.项目名,                              -- 项目名称
        flg.项目代码,                            -- 项目代码
        flg.投管代码,                            -- 投管代码
        flg.获取时间,                            -- 获取时间
        flg.并表方式,                            -- 并表方式（我司并表/不并表等）
        flg.项目五分类,                          -- 项目五分类
        CASE 
            WHEN flg.项目五分类 IN ('增量项目','⑦增量项目','已投资未落实') THEN '增量'
            WHEN flg.项目五分类 IN ('存量项目') THEN '存量'
            ELSE '其他' 
        END AS 存量增量分类
        -- flg.存量增量                          -- 存量增量标识（暂不使用）
    INTO #proj
    FROM erp25.dbo.vmdm_projectFlagnew flg
    INNER JOIN erp25.dbo.mdm_project p ON flg.projguid = p.projguid
    WHERE p.level = 2                            -- 只取二级项目
      AND flg.DevelopmentCompanyGUID IN (SELECT value FROM dbo.fn_Split2(@var_buguid, ',')) -- 按传入的公司GUID筛选

    -- 步骤2：获取存货排查最新数据
    SELECT 
        mp.ParentProjGUID AS ProjGUID,           -- 项目GUID
        sfp.ProjGUID AS fqProjGUID,              -- 分期GUID
        sfp.BldGUID,                             -- 楼栋GUID
        sfp.BldName,                             -- 楼栋名称
        sfp.ProductBldGUID,                      -- 产品楼栋GUID
        sfp.ProductBldName,                      -- 产品楼栋名称
        pt.ProductType,                          -- 产品类型
        pt.ProductName,                          -- 产品名称
        pt.BusinessType,                         -- 商品类型
        pt.Standard,                             -- 状态标准
        sfp.TotalCost                            -- 存货成本总数
    INTO #chld
    FROM [TaskCenterData].dbo.cb_StockFtCostPhoto sfp
    INNER JOIN erp25.dbo.mdm_SaleBuild sb ON sfp.ProductBldGUID = sb.SaleBldGUID
    INNER JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = sfp.ProjGUID
    LEFT JOIN erp25.dbo.mdm_Product pt ON pt.ProductGUID = sb.ProductGUID
    INNER JOIN (
        SELECT  
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY PhotoDate DESC) AS num, -- 取每个项目最新的审核版本
            VersionGUID,
            ProjGUID,
            ProjName,
            PhotoDate
        FROM [TaskCenterData].dbo.cb_StockFtProjVersionPhoto 
        WHERE ApproveState = '已审核'            -- 只取已审核的版本
    ) vr 
        ON vr.VersionGUID = sfp.VersionGUID 
        AND sfp.ProjGUID = vr.ProjGUID 
        AND vr.num = 1                           -- 只取最新版本

    -- 汇总存货信息
    SELECT 
        ProjGUID,                                -- 项目GUID
        ProductType,                             -- 产品类型
        ProductName,                             -- 产品名称
        BusinessType,                            -- 商品类型
        Standard,                                -- 状态标准
        SUM(ISNULL(TotalCost, 0)) / 10000.0 AS TotalCost -- 存货成本总数
    INTO #ch
    FROM #chld
    GROUP BY ProjGUID, ProductType, ProductName, BusinessType, Standard
  
    -- 步骤3：获取产值月度评审数据
    SELECT 
        bld.OutputValueMonthReviewGUID,          -- 产值月度评审GUID
        bld.BldGUID,                             -- 楼栋GUID
        bld.BldName,                             -- 楼栋名称
        bld.ProdBldGUID,                         -- 产品楼栋GUID
        bld.ProdBldName,                         -- 产品楼栋名称
        bld.Zcz,                                 -- 总产值
        bld.Xmpdljwccz                           -- 项目累计已完成产值
    INTO #cz
    FROM cb_OutputValueReviewProdBld bld
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY ReviewDate DESC) AS num, -- 取每个项目最新的审核版本
            OutputValueMonthReviewGUID,
            ProjGUID,
            ReviewDate
        FROM [dbo].[cb_OutputValueMonthReview]
        WHERE ApproveState = '已审核'            -- 只取已审核的版本
    ) vr 
        ON vr.OutputValueMonthReviewGUID = bld.OutputValueMonthReviewGUID 
        AND vr.num = 1                           -- 只取最新版本
      
    -- 步骤4：获取立项指标成本数据（按产品类型、产品名称、商品类型、状态标准分组）
    SELECT 
        a.ProjGUID,                              -- 项目GUID
        -- pd.ProductType AS 产品类型,              -- 产品类型
        -- pd.ProductName AS 产品名称,              -- 产品名称
        -- pd.BusinessType AS 商品类型,             -- 商品类型
        -- pd.Standard AS 状态标准,                 -- 状态标准
        SUM(CASE WHEN b.CostShortName IN ('总投资合计') THEN a.CostMoney ELSE 0 END) AS 总投资, -- 总投资金额
        -- MAX(CASE WHEN b.CostShortName IN ('总投资合计') THEN a.BuildAreaCostMoney ELSE 0 END) AS 总投资建筑单方, -- 含税
        
        -- 直投 = 总投资 - 三费(管理费用、营销费用、财务费用)
        ISNULL(SUM(CASE WHEN b.CostShortName = '总投资合计' THEN a.CostMoney ELSE 0 END), 0) 
         - ISNULL(SUM(CASE WHEN b.CostShortName IN ('管理费用','营销费用','财务费用') THEN a.CostMoney ELSE 0 END), 0) AS 直投,
        
        SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney ELSE 0 END) AS 土地款, -- 土地款金额
        
        -- 除地价外直投 = 除地价外投资合计 - 三费(管理费用、营销费用、财务费用)
        ISNULL(SUM(CASE WHEN b.CostShortName = '除地价外投资合计' THEN a.CostMoney ELSE 0 END), 0) 
         - ISNULL(SUM(CASE WHEN b.CostShortName IN ('管理费用','营销费用','财务费用') THEN a.CostMoney ELSE 0 END), 0) AS 除地价外直投,
        
        -- 三费明细
        SUM(CASE WHEN b.CostShortName IN ('管理费用') THEN a.CostMoney ELSE 0 END) AS 管理费用,
        SUM(CASE WHEN b.CostShortName IN ('营销费用') THEN a.CostMoney ELSE 0 END) AS 营销费用,
        SUM(CASE WHEN b.CostShortName IN ('财务费用') THEN a.CostMoney ELSE 0 END) AS 财务费用
    INTO #lx_cb -- 暂时不需要存入临时表
    FROM erp25.dbo.mdm_ProjProductCostIndex a
    INNER JOIN erp25.dbo.mdm_TechTargetProduct pd
        ON a.ProjGUID = pd.ProjGUID
        AND a.ProductGUID = pd.ProductGUID
    INNER JOIN erp25.dbo.mdm_CostIndex b
        ON a.CostGuid = b.CostGUID
    INNER JOIN #proj pj  
        ON pj.项目GUID = a.ProjGUID
    GROUP BY 
        a.ProjGUID
        -- pd.ProductType,
        -- pd.ProductName,
        -- pd.BusinessType,
        -- pd.Standard;
    
    -- 步骤5：获取利润指标数据
    SELECT 
        b.ProjGUID,                              -- 项目GUID
        -- b.ProductType AS 产品类型,               -- 产品类型
        -- b.ProductName AS 产品名称,               -- 产品名称
        -- b.BusinessType AS 商品类型,              -- 商品类型
        -- b.Standard AS 状态标准,                  -- 状态标准
        SUM(ISNULL(TotalInvestmentTax, 0)) AS 总投资,       -- 总投资（含税） 
        -- 税前成本利润率 = 税前利润/总投资
        CASE WHEN SUM(ISNULL(TotalInvestmentTax, 0)) = 0 THEN 0 
             ELSE SUM(ISNULL(PreTaxProfit, 0)) / SUM(ISNULL(TotalInvestmentTax, 0)) 
        END AS 税前成本利润率,
        
        SUM(ISNULL(CashInflowTax, 0)) AS 总货值,            -- 总货值（含税现金流入）
        SUM(ISNULL(PreTaxProfit, 0)) AS 税前利润,           -- 税前利润（重复，可考虑删除）
        SUM(ISNULL(AfterTaxProfit, 0)) AS 税后利润,         -- 税后利润（净利润）
        SUM(ISNULL(CashProfit, 0)) AS 税后现金利润,         -- 税后现金利润
        SUM(ISNULL(FixedAssetsOne, 0)) AS 固定资产,         -- 固定资产    
        -- 税费 = 土地增值税 + 流转税附加
        SUM(ISNULL(LandAddedTax, 0)) + SUM(ISNULL(TurnoverTaxPlus, 0)) AS 税费,
        SUM(ISNULL(LandAddedTax, 0)) AS 土地增值税,         -- 土地增值税
        SUM(ISNULL(TurnoverTaxPlus, 0)) AS 流转税附加       -- 流转税附加
    INTO #lx_lr -- 暂时不需要存入临时表
    FROM erp25.dbo.mdm_ProjectIncomeIndex a
    INNER JOIN erp25.dbo.mdm_TechTargetProduct b
        ON a.ProjGUID = b.ProjGUID
        AND a.ProductGUID = b.ProductGUID
    INNER JOIN #proj pj  
        ON pj.项目GUID = b.ProjGUID
    -- WHERE b.projguid = '1BCF8FE5-46C7-EF11-B3A6-F40270D39969' -- 测试用，可注释
    GROUP BY 
        b.ProjGUID
        -- b.ProductType,
        -- b.ProductName,
        -- b.BusinessType,
        -- b.Standard;

    -- 查询最终结果
    SELECT  
        pj.平台公司 AS 公司,
        pj.投管代码,
        pj.项目名 AS 项目名称,
        pj.存量增量分类,    
        -- 立项指标
        lx_lr.总货值 AS 立项指标_货值,
        lx_cb.直投 AS 立项指标_直投,
        lx_cb.除地价外直投 AS 立项指标_除地价外直投,
        ISNULL(lx_cb.管理费用, 0) + ISNULL(lx_cb.营销费用, 0) + ISNULL(lx_cb.财务费用, 0) AS 立项指标_费用,
        lx_lr.税费 AS 立项指标_税金,
        lx_lr.税后利润 AS 立项指标_净利润,
        lx_lr.税前成本利润率 AS 立项指标_税前成本利润率,
        
        ch.ProductType AS 业态类型, -- 产品类型
        ch.ProductName + '-' + ch.Standard + '-' + ch.BusinessType AS 业态, -- 产品名称+装修标准+商品类型

        -- 存货结构-按支付口径
        ch.TotalCost AS 存货结构_存货余额,	
        NULL AS 存货结构_实际已付,	
        NULL AS 存货结构_账面计提,	
        NULL AS 存货结构_已达产值但未计提存货,	
        NULL AS 存货结构_项目竣备待发生成本,
        -- 存货按工程进度分类
        NULL AS 存货按工程进度分类_已投资未落实金额,
        NULL AS 存货按工程进度分类_未开工土地金额,
        NULL AS 存货按工程进度分类_已开工分期未售存货金额合计,
        NULL AS 存货按工程进度分类_已开工分期未售存货面积合计,
        NULL AS 存货按工程进度分类_已开工分期未售存货未开工楼栋面积,
        NULL AS 存货按工程进度分类_已开工分期未售存货未开工楼栋金额,
        NULL AS 存货按工程进度分类_已开工分期未售存货已开工未达可售条件面积,
        NULL AS 存货按工程进度分类_已开工分期未售存货已开工未达可售条件金额,
        NULL AS 存货按工程进度分类_已开工分期未售存货已达可售条件未竣备面积,
        NULL AS 存货按工程进度分类_已开工分期未售存货已开可售条件未竣备金额,
        NULL AS 存货按工程进度分类_已开工分期未售存货已竣备面积,
        NULL AS 存货按工程进度分类_已开工分期未售存货已竣备金额,
        NULL AS 存货按工程进度分类_已开工分期未售存货计划转经营面积,
        NULL AS 存货按工程进度分类_已开工分期未售存货计划转经营金额,
        NULL AS 存货按工程进度分类_已开工分期未售存货不存成本面积,
        NULL AS 存货按工程进度分类_已售面积,
        NULL AS 存货按工程进度分类_已售金额,
        NULL AS 存货按工程进度分类_经营资产存成本经营资产面积,
        NULL AS 存货按工程进度分类_经营资产存成本经营资产金额,
        NULL AS 存货按工程进度分类_经营资产不存成本经营资产面积,
        -- 未开工土地存货质量分析
        NULL AS 未开工土地存货质量分析_存货金额,
        NULL AS 未开工土地存货质量分析_未开工土地账龄,
        NULL AS 未开工土地存货质量分析_拟退存货面积,
        NULL AS 未开工土地存货质量分析_拟退存货金额,
        NULL AS 未开工土地存货质量分析_拟换存货面积,
        NULL AS 未开工土地存货质量分析_拟换存货金额,
        NULL AS 未开工土地存货质量分析_拟调存货面积,
        NULL AS 未开工土地存货质量分析_拟调存货金额,
        -- 已开工未达可售存货质量分析
        NULL AS 已开工未达可售存货质量分析_存货金额,
        NULL AS 已开工未达可售存货质量分析_账龄,
        NULL AS 已开工未达可售存货质量分析_竣备待发生成本,
        NULL AS 已开工未达可售存货质量分析_冰冻存货面积,
        NULL AS 已开工未达可售存货质量分析_冰冻存货金额,
        NULL AS 已开工未达可售存货质量分析_冰冻存货待发生成本,
        -- 已达可售条件未竣备但未售存货的质量分析
        NULL AS 已达可售条件未竣备但未售存货的质量分析_存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_存货金额,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_账龄,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货金额,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_顶底存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_顶底存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_顶底存货金额,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货金额,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_合计存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_合计存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_合计存货金额,
        -- 已竣备未售存货的质量分析
        NULL AS 已竣备未售存货的质量分析_存货套数,
        NULL AS 已竣备未售存货的质量分析_存货面积,
        NULL AS 已竣备未售存货的质量分析_存货金额,
        NULL AS 已竣备未售存货的质量分析_账龄,
        NULL AS 已竣备未售存货的质量分析_冰冻存货面积,
        NULL AS 已竣备未售存货的质量分析_冰冻存货金额,
        NULL AS 已竣备未售存货的质量分析_冰冻存货待发生成本,
        -- 存货近期销售情况
        NULL AS 存货近期销售情况_近3个月销售流速,
        NULL AS 存货近期销售情况_近3个月销售签约,
        NULL AS 存货近期销售情况_近3个月销售签约均价,
        NULL AS 存货近期销售情况_近6个月销售流速,
        NULL AS 存货近期销售情况_近6个月销售签约,
        NULL AS 存货近期销售情况_近6个月销售签约均价,
        NULL AS 存货近期销售情况_近12个月销售流速,
        NULL AS 存货近期销售情况_近12个月销售签约,
        NULL AS 存货近期销售情况_近12个月销售签约均价,
        -- 经营资产质量分析
        NULL AS 经营资产质量分析_资产面积,
        NULL AS 经营资产质量分析_净值,
        NULL AS 经营资产质量分析_原值,
        NULL AS 经营资产质量分析_累计折旧,
        NULL AS 经营资产质量分析_二次改造装修成本,
        NULL AS 经营资产质量分析_NPI回报率,
        NULL AS 经营资产质量分析_EBITDA,
        NULL AS 经营资产质量分析_净利润,
        -- 存货现金流风险分析
        NULL AS 存货现金流风险分析_项目经营现金流_已回笼,
        NULL AS 存货现金流风险分析_项目经营现金流_已支付直投,
        NULL AS 存货现金流风险分析_项目经营现金流_已签约待回笼,
        NULL AS 存货现金流风险分析_项目经营现金流_已发生产值待支付,
        NULL AS 存货现金流风险分析_融资余额_合计,
        NULL AS 存货现金流风险分析_融资余额_开发贷,
        NULL AS 存货现金流风险分析_融资余额_保理,
        NULL AS 存货现金流风险分析_融资余额_经营贷,
        NULL AS 存货现金流风险分析_融资期限_合计,
        NULL AS 存货现金流风险分析_融资期限_开发贷,
        NULL AS 存货现金流风险分析_融资期限_经营贷,
        NULL AS 存货现金流风险分析_其中一年内到期融资_合计,
        NULL AS 存货现金流风险分析_其中一年内到期融资_开发贷,
        NULL AS 存货现金流风险分析_其中一年内到期融资_保理,
        NULL AS 存货现金流风险分析_其中一年内到期融资_经营贷,
        NULL AS 存货现金流风险分析_股东投入余额_合计,
        NULL AS 存货现金流风险分析_股东投入余额_我方,
        NULL AS 存货现金流风险分析_股东投入余额_合作方,
        -- 存货利润分析
        NULL AS 存货利润分析_已售存货_货值,
        NULL AS 存货利润分析_已售存货_成本,
        NULL AS 存货利润分析_已售存货_股权溢价,
        NULL AS 存货利润分析_已售存货_费用,
        NULL AS 存货利润分析_已售存货_税金,
        NULL AS 存货利润分析_已售存货_净利润,
        NULL AS 存货利润分析_已售存货_净利率,
        NULL AS 存货利润分析_未售存货_货值,
        NULL AS 存货利润分析_未售存货_成本,
        NULL AS 存货利润分析_未售存货_股权溢价,
        NULL AS 存货利润分析_未售存货_费用,
        NULL AS 存货利润分析_未售存货_税金,
        NULL AS 存货利润分析_未售存货_净利润,
        NULL AS 存货利润分析_未售存货_净利率
    FROM #ch ch
    INNER JOIN #proj pj ON pj.项目GUID = ch.ProjGUID
    LEFT JOIN #lx_cb lx_cb ON lx_cb.ProjGUID = ch.ProjGUID --and  ch.ProductType = lx_cb.ProductType and ch.ProductName = lx_cb.ProductName and ch.BusinessType = lx_cb.BusinessType and ch.Standard = lx_cb.Standard
    LEFT JOIN #lx_lr lx_lr ON lx_lr.ProjGUID = ch.ProjGUID --and  ch.ProductType = lx_lr.ProductType and ch.ProductName = lx_lr.ProductName and ch.BusinessType = lx_lr.BusinessType and ch.Standard = lx_lr.Standard
    ORDER BY pj.平台公司, pj.项目名, pj.存量增量分类, ch.ProductType DESC, ch.ProductName + '-' + ch.Standard + '-' + ch.BusinessType

    -- 删除临时表
    DROP TABLE #proj, #ch, #chld, #cz, #lx_cb, #lx_lr

END