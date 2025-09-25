--  PDU需求：https://pdu.mingyuanyun.com/#/ds3/4hBti5LOzUesczeG-mKBxcL3ljavWXKQhFNx8e4n41Xc2E9Y8WLW62CrNl8rAP5fWb-xNKEoZv2Y8Tx0EOCDW0aviErYY97U9sOzw89K6xMyIiPBxP9DDg

-- ========================================================
-- 新开工申请单 
-- 1、项目基本信息
-- 2、已开工部分情况
-- 3、已开工未售及去化承诺
-- 4、本次开工现金流及利润情况
-- ========================================================

USE MyCost_Erp352
GO

-- ===========================================
-- 1、项目基本信息
--    1.1 股东信息
-- ===========================================
WITH shareholder AS (
    SELECT
        a1.ProjShareholderGUID,         -- 项目合作方ID
        a1.ProjCompanyGUID,             -- 项目公司GUID
        a1.ProjCompanyName,             -- 项目公司名称
        a1.BLShareRate,                 -- 保利方权益比例（项目公司股权）
        a1.ParentProjGUID,              -- 项目GUID
        a1.ParentProjName,              -- 项目名称
        a1.ParentProjCode,              -- 项目编码
        a1.ProjGUID,                    -- 分期GUID
        a1.ProjName,                    -- 分期名称
        a1.ProjCode,                    -- 分期编码
        a1.ShareholderGUID,             -- 合作方GUID
        ISNULL(a1.ShareholderName,p1.Partners) AS ShareholderName, -- 合作方名称（优先取Partners字段）
        a1.ShareRate,                   -- 股权比例
        a1.EquityRatio,                 -- 财务收益比例
        a1.ShareTradersWay,             -- 操盘方式
        a1.ShareBbWay                   -- 并表方式
    FROM
        erp25.dbo.p_ProjShareholder a1
        LEFT JOIN erp25.dbo.p_developmentcompany p1
            ON a1.ShareholderGUID = p1.DevelopmentCompanyGUID
    where  isnull(p1.IsOurTable,0) =0 
),

-- ===========================================
-- 1.2 Dss系统现金流填报
--    取各项目最新版本的现金流数据
-- ===========================================
cashflow AS (
    SELECT DISTINCT
        x.ID AS ID,                                         -- 主键ID
        x.BusinessGUID AS ProjGUID,                         -- 项目GUID
        x.[一级项目名称] AS ProjName,                        -- 一级项目名称
        x.[FillDate] AS VersionDate,                        -- 填报日期
        x.[ApproveDate] AS ExtractedDate,                   -- 审批日期
        x.[FillHistoryGUID] AS VersionGUID,                 -- 填报历史GUID
        CASE
            WHEN ISNULL(x.[累计直接投资（万元）], 0) > 0 AND x.Isbase = 1 THEN 1
            ELSE 0
        END AS IsBase,                                      -- 是否为最新版本
        x.年份 AS year,                                     -- 年份
        x.月份 AS month,                                    -- 月份
        ISNULL(x.[累计总投资（万元）], 0) AS InvestmentAmountTotal,         -- 累计总投资
        ISNULL(x.[贷款余额（万元）], 0) AS LoanBalanceTotal,                -- 贷款余额
        ISNULL(x.[累计回笼（万元）], 0) AS CollectionAmountTotal,           -- 累计回笼
        ISNULL(x.[累计直接投资（万元）], 0) AS DirectInvestmentTotal,        -- 累计直接投资
        ISNULL(x.[累计直接投资其中土地费用（万元）], 0) AS LandCostTotal,     -- 累计直接投资-土地费用
        ISNULL(x.[累计税金（万元）], 0) AS TaxTotal,                        -- 累计税金
        ISNULL(x.[累计直接建安投资（万元）], 0) AS JaInvestmentAmount,       -- 累计直接建安投资
        ISNULL(x.[累计总投资（万元）], 0) - ISNULL(x.[累计直接投资（万元）], 0) AS ExpenseTotal, -- 累计间接费用
        ISNULL(x.[本年总投资（万元）], 0) AS YearInvestmentAmount,          -- 本年总投资
        ISNULL(x.[本年贷款金额（万元）], 0) AS YearLoanBalance,              -- 本年贷款金额
        ISNULL(x.[本年资金回笼（万元）], 0) AS YearCollectionAmount,         -- 本年资金回笼
        ISNULL(x.[本年直接投资（万元）], 0) AS YearDirectInvestment,         -- 本年直接投资
        ISNULL(x.[本年直接投资土地费用（万元）], 0) AS YearLandCost,         -- 本年直接投资-土地费用
        ISNULL(x.[本年税金（万元）], 0) AS YearTax,                         -- 本年税金
        ISNULL(x.[本年总投资（万元）], 0) - ISNULL(x.[本年直接投资（万元）], 0) AS YearExpense, -- 本年间接费用
        ISNULL(x.[本年直接建安投资（万元）], 0) AS YearJaInvestmentAmount,   -- 本年直接建安投资
        ISNULL(x.[本月总投资（万元）], 0) AS MonthInvestmentAmount,         -- 本月总投资
        ISNULL(x.[本月贷款金额（万元）], 0) AS MonthLoanBalance,             -- 本月贷款金额
        ISNULL(x.[本月资金回笼（万元）], 0) AS MonthCollectionAmount,        -- 本月资金回笼
        ISNULL(x.[本月直接投资（万元）], 0) AS MonthDirectInvestment,        -- 本月直接投资
        ISNULL(x.[本月直接投资土地费用（万元）], 0) AS MonthLandCost,        -- 本月直接投资-土地费用
        ISNULL(x.[本月税金（万元）], 0) AS MonthTax,                        -- 本月税金
        ISNULL(x.[本月总投资（万元）], 0) - ISNULL(x.[本月直接投资（万元）], 0) AS MonthExpense, -- 本月间接费用
        ISNULL(x.[本月直接建安投资（万元）], 0) AS MonthJaInvestmentAmount,  -- 本月直接建安投资
        x.[预计现金流回正日期] AS PlanOFCFReturnabilityDate,                -- 预计现金流回正日期
        -- x.[实际现金流回正日期] AS ActualOFCFReturnabilityDate,           -- 实际现金流回正日期（注释掉）
        x.[预计收回股东投资日期] AS PlanOCFRetDate,                        -- 预计收回股东投资日期
        ISNULL(x.[本年净增贷款（万元）], 0) AS YearNetIncreaseLoan,         -- 本年净增贷款
        ISNULL(x.[本月直接投资土地费用（万元）], 0) AS YearfinancingAmount, -- 本年实际融资（取本月直接投资土地费用字段）
        ISNULL(x.[本月净增贷款（万元）], 0) AS MonthNetIncreaseLoan,        -- 本月净增贷款
        ISNULL(x.[开发贷款余额（万元）], 0) AS DevelopmentLoans,            -- 开发贷款余额
        ISNULL(x.[供应链融资余额（万元）], 0) AS SupplyChainLoan,            -- 供应链融资余额
        ISNULL(x.[本年管理费用（万元）], 0) AS YearManageAmount,            -- 本年管理费用
        ISNULL(x.[本年营销费用（万元）], 0) AS YearMarketAmount,            -- 本年营销费用
        ISNULL(x.[本年财务费用（万元）], 0) AS YearFinancial,               -- 本年财务费用
        ISNULL(x.[累计管理费用（万元）], 0) AS ManageAmount,                -- 累计管理费用
        ISNULL(x.[累计营销费用（万元）], 0) AS MarketAmount,                -- 累计营销费用
        ISNULL(x.[累计财务费用（万元）], 0) AS Financial,                   -- 累计财务费用
        ISNULL(x.[本年净增供应链融资（万元）], 0) AS YearSupplyChainLoan,    -- 本年净增供应链融资
        ISNULL(x.[本年净增开发贷（万元）], 0) AS YearDevelopmentLoans,      -- 本年净增开发贷
        ISNULL(x.[累计经营性现金流（项目账面）（万元）], 0) AS LjJyxcashflow_zm, -- 累计经营性现金流（账面）
        ISNULL(x.[累计权益经营性现金流（含股权溢价）（万元）], 0) AS LjQyJyxcashflow_hgqyj, -- 累计权益经营性现金流（含股权溢价）
        ISNULL(x.[本年经营性现金流（项目账面）（万元）], 0) AS YearJyxcashflow_zm, -- 本年经营性现金流（账面）
        ISNULL(x.[本年权益经营性现金流（含股权溢价）（万元）], 0) AS YearQyJyxcashflow_hgqyj, -- 本年权益经营性现金流（含股权溢价）
        ISNULL(x.[项目累计投资比例], 0) AS projtzrate,                    -- 项目累计投资比例
        ISNULL(x.[项目累计收益比例], 0) AS projsyrate                      -- 项目累计收益比例
    FROM (
        SELECT
            YEAR(b.EndDate) AS 年份,                                      -- 年份
            MONTH(b.EndDate) AS 月份,                                     -- 月份
            ROW_NUMBER() OVER (
                PARTITION BY a.BusinessGUID
                ORDER BY a.[累计直接投资（万元）] DESC, b.FillDate DESC
            ) AS Isbase,                                                 -- 最新版本标识
            b.FillDate,                                                  -- 填报日期
            b.ApproveDate,                                               -- 审批日期
            a.ID,                                                        -- 主键ID
            a.BusinessGUID,                                              -- 项目GUID
            a.FillHistoryGUID,                                           -- 填报历史GUID
            a.[一级项目名称],                                             -- 一级项目名称
            a.[本年净增贷款（万元）],
            a.[本月贷款金额（万元）],
            a.[贷款余额（万元）],
            a.[累计回笼（万元）],
            a.[累计直接投资（万元）],
            a.[累计直接投资其中土地费用（万元）],
            a.[累计税金（万元）],
            a.[累计总投资（万元）],
            a.[累计直接建安投资（万元）],
            a.[本年总投资（万元）],
            a.[本年贷款金额（万元）],
            a.[本年资金回笼（万元）],
            a.[本年直接投资（万元）],
            a.[本年直接建安投资（万元）],
            a.[本年直接投资土地费用（万元）],
            a.[本年税金（万元）],
            a.[本月总投资（万元）],
            a.[本月资金回笼（万元）],
            a.[本月直接投资（万元）],
            a.[本月直接建安投资（万元）],
            a.[本月直接投资土地费用（万元）],
            a.[本月税金（万元）],
            a.[预计现金流回正日期],
            a.[实际现金流回正日期],
            a.[预计收回股东投资日期],
            a.[实际收回股东投资日期],
            a.[本月净增贷款（万元）],
            a.[开发贷款余额（万元）],
            a.[供应链融资余额（万元）],
            a.[本年管理费用（万元）],
            a.[本年营销费用（万元）],
            a.[本年财务费用（万元）],
            a.[累计管理费用（万元）],
            a.[累计营销费用（万元）],
            a.[累计财务费用（万元）],
            a.[本年净增供应链融资（万元）],
            a.[本年净增开发贷（万元）],
            a.[累计经营性现金流（项目账面）（万元）],
            a.[累计权益经营性现金流（含股权溢价）（万元）],
            a.[本年经营性现金流（项目账面）（万元）],
            a.[本年权益经营性现金流（含股权溢价）（万元）],
            a.[项目累计投资比例],
            a.[项目累计收益比例]
        FROM
            dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a
            INNER JOIN dss.dbo.nmap_F_FillHistory b
                ON a.FillHistoryGUID = b.FillHistoryGUID
    ) x
    WHERE
        CASE
            WHEN ISNULL(x.[累计直接投资（万元）], 0) > 0 AND x.Isbase = 1 THEN 1
            ELSE 0
        END = 1 -- 只取已填报的最新版本
),

-- ===========================================
-- 1.3 查询项目基本信息及相关财务数据
-- ===========================================
baseproj as ( 
    SELECT 
     distinct
    bu.buguid,
    bu.BUName AS 公司名称, -- 业务单元名称
    pproj.Projguid,
    ISNULL(mp.SpreadName, pproj.SpreadName) AS 项目名称, -- 项目名称（优先取SpreadName）
    mp.[AcquisitionDate] AS 获取时间, -- 获取时间
    CASE
        WHEN flg.项目股权比例 IS NOT NULL THEN CONVERT(VARCHAR(10), flg.项目股权比例) + '%'
        ELSE NULL
    END AS 我方股权比例, -- 我方股权比例
    flg.并表方式 AS 并表情况, -- 并表方式
    (
        SELECT STUFF(
            (
                SELECT DISTINCT
                    ',' + CONVERT(VARCHAR(200), ShareholderName + '(' + CONVERT(VARCHAR(10), ShareRate) + '%)')
                FROM
                    shareholder a
                WHERE
                    a.ParentProjGUID = pproj.projguid
                FOR XML PATH('')
            ),
            1, 1, ''
        )
    ) AS 合作方名称及持股比例, -- 合作方及持股比例（拼接字符串）
    LoanBalanceTotal / 10000.0 AS  累计贷款余额,
    (
        ISNULL(CollectionAmountTotal, 0)
        - ISNULL(DirectInvestmentTotal, 0)
        - ISNULL(ManageAmount, 0)
        - ISNULL(MarketAmount, 0)
        - ISNULL(Financial, 0)
        - ISNULL(TaxTotal, 0)
    ) / 10000.0 AS 累计经营现金流, -- 单位：亿元 (累计回笼-累计直接投资-累计财务费用-累计管理费用-累计营销费用-累计税金)
    (
        ISNULL(CollectionAmountTotal, 0)
        + ISNULL(LoanBalanceTotal, 0)
        - ISNULL(DirectInvestmentTotal, 0)
        - ISNULL(ManageAmount, 0)
        - ISNULL(MarketAmount, 0)
        - ISNULL(Financial, 0)
        - ISNULL(TaxTotal, 0)
    ) / 10000.0 AS 股东占压现金流, -- 单位：亿元 (累计回笼+贷款余额-累计直接投资-累计财务费用-累计管理费用-累计营销费用-累计税金)
    mp.TotalLandPrice/100000000.0 AS 总地价, -- 获取总成本
    mp.LMDJ AS 楼面价,           -- 楼面价
    vpInfo.SumBuildArea/10000.0 AS 项目总建面, -- 动态版总建筑面积
    vpInfo.LjkgArea/10000.0 AS 已开工建面     -- 累计开工建筑面积
FROM
    MyCost_Erp352.dbo.p_project proj
    INNER JOIN MyCost_Erp352.dbo.myBusinessUnit bu  ON proj.buguid = bu.buguid
    INNER JOIN MyCost_Erp352.dbo.p_project pproj  ON pproj.projcode = proj.ParentCode
    INNER JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = pproj.ProjGUID
    INNER JOIN erp25.dbo.vmdm_projectFlagnew flg ON flg.ProjGUID = mp.ProjGUID
    LEFT JOIN cashflow cf ON cf.ProjGUID = mp.projguid
    inner join erp25.dbo.vmdm_ProjectInfoEx vpInfo ON vpInfo.ProjGUID = mp.ProjGUID
WHERE
    proj.level = 3 -- 只取分期级项目
    AND proj.ApplySys LIKE '%0201%' 
)



-- ===========================================
-- 2、已开工部分情况统计
-- 说明：
-- 1. 统计已开工地上可售面积、已售面积、未售面积、货值等核心指标
-- 2. 仅统计“地上”部分（phyAddress不等于“地下”），且实际开工完成日期不为空的数据
-- 3. 货值单位为亿元，面积单位为万㎡
-- ===========================================
SELECT
    baseproj.*,
    
    -- 已开工地上可售面积 = 已售面积 + 未售面积
    ISNULL(F05601.已开地上已售面积, 0) + ISNULL(F05601.已开地上未售面积, 0) AS 已开工地上可售面积,
    
    -- 已开地上已售面积
    ISNULL(F05601.已开地上已售面积, 0) AS 已开地上已售面积,
    
    -- 已开地上未售面积（注：原字段名为“未售货值”，应为“未售面积”，此处保持原逻辑）
    ISNULL(F05601.已开地上未售货值, 0) AS 已开地上未售面积,
    
    -- 已开工地上货值 = 已售货值 + 未售货值
    ISNULL(F05601.已开地上已售货值, 0) + ISNULL(F05601.已开地上未售货值, 0) AS 已开工地上货值,
    
    -- 已开工地上已售货值
    ISNULL(F05601.已开地上已售货值, 0) AS 已开工地上已售货值,
    
    -- 已开工地上未售货值
    ISNULL(F05601.已开地上未售货值, 0) AS 已开工地上未售货值,
    
    -- 当期住宅已售面积
    ISNULL(F05601.住宅已售面积, 0) AS 当期住宅已售面积,
    
    -- 历史版本住宅已售面积（三个月前版本）
    ISNULL(F056LastMonth.历史版本住宅已售面积, 0) AS 历史版本住宅已售面积,
    
    -- 近三个月住宅流速 = (当期住宅已售面积 - 历史版本住宅已售面积) / 3
    (ISNULL(F05601.住宅已售面积, 0) - ISNULL(F056LastMonth.历史版本住宅已售面积, 0)) / 3.0 AS 近三个月住宅流速,
    
    -- 住宅产销比 = 已开工未售住宅面积 / 近三个月住宅流速
    CASE
        WHEN (ISNULL(F05601.住宅已售面积, 0) - ISNULL(F056LastMonth.历史版本住宅已售面积, 0)) > 0
            THEN F05601.已开工未售住宅面积 / (ISNULL(F05601.住宅已售面积, 0) - ISNULL(F056LastMonth.历史版本住宅已售面积, 0)) / 3.0
        ELSE 0
    END AS 住宅产销比,
    
    -- 住宅存销比 = 已达预售条件住宅面积 / 近三个月住宅流速
    CASE
        WHEN (ISNULL(F05601.住宅已售面积, 0) - ISNULL(F056LastMonth.历史版本住宅已售面积, 0)) > 0
            THEN F05601.已达预售条件住宅面积 / (ISNULL(F05601.住宅已售面积, 0) - ISNULL(F056LastMonth.历史版本住宅已售面积, 0)) / 3.0
        ELSE 0
    END AS 住宅存销比,
    
    -- 本次开工业态已售单方成本（各业态拼接字符串）
    ysdf.本次开工业态已售单方成本,
    
    -- 本次开工业态已售均价（各业态拼接字符串）
    ysdf.本次开工业态已售均价,
    
    -- 本次开工业态已售税后利润（各业态拼接字符串）
    ysdf.本次开工业态已售税后利润,
    
    -- 本次开工业态已售销净率（各业态拼接字符串）
    ysdf.本次开工业态已售销净率

FROM
    baseproj

    -- 关联F05601表，统计各项目地上已开工、已售/未售面积及货值等
    LEFT JOIN (
        SELECT
            mp.ParentProjGUID,
            
            -- 地上、已开工、已售面积
            SUM(
                CASE
                    WHEN [产品类型] <> '地下室/车库' --ISNULL(pnm.phyAddress, '') <> '地下'
                         AND 实际开工完成日期 IS NOT NULL
                        THEN 已售面积
                    ELSE 0
                END
            ) AS 已开地上已售面积,
            
            -- 地上、已开工、未售面积
            SUM(
                CASE
                    WHEN [产品类型] <> '地下室/车库'  --ISNULL(pnm.phyAddress, '') <> '地下'
                         AND 实际开工完成日期 IS NOT NULL
                        THEN 待售面积
                    ELSE 0
                END
            ) AS 已开地上未售面积,
            
            -- 地上、已开工、已售货值（万元转亿元）
            SUM(
                CASE
                    WHEN [产品类型] <> '地下室/车库'  --ISNULL(pnm.phyAddress, '') <> '地下'
                         AND 实际开工完成日期 IS NOT NULL
                        THEN 已售货值
                    ELSE 0
                END
            ) / 10000.0 AS 已开地上已售货值,
            
            -- 地上、已开工、未售货值（万元转亿元）
            SUM(
                CASE
                    WHEN [产品类型] <> '地下室/车库'  --ISNULL(pnm.phyAddress, '') <> '地下'
                         AND 实际开工完成日期 IS NOT NULL
                        THEN 待售货值
                    ELSE 0
                END
            ) / 10000.0 AS 已开地上未售货值,
            
            -- 已开工未售住宅面积（仅住宅类产品）
            SUM(
                CASE
                    WHEN 实际开工完成日期 IS NOT NULL
                         AND 产品类型 IN ('住宅', '高级住宅', '别墅')
                        THEN 待售面积
                    ELSE 0
                END
            ) AS 已开工未售住宅面积,
            
            -- 住宅已售面积（累计）
            SUM(
                CASE
                    WHEN 产品类型 IN ('住宅', '高级住宅', '别墅')
                        THEN 已售面积
                    ELSE 0
                END
            ) AS 住宅已售面积,
            
            -- 已达预售条件住宅面积
            SUM(
                CASE
                    WHEN 达到预售形象完成日期 IS NOT NULL
                         AND 产品类型 IN ('住宅', '高级住宅', '别墅')
                        THEN 待售面积
                    ELSE 0
                END
            ) AS 已达预售条件住宅面积

        FROM
            dss.[dbo].nmap_s_F05601各项目产品楼栋表系统取数原始表单_qx F05601
           -- LEFT JOIN [MyCost_Erp352].dbo.md_ProductNameModule pnm ON pnm.ProductName = F05601.产品名称
            INNER JOIN erp25.dbo.mdm_GCBuild gb
                ON gb.GCBldGUID = F05601.GCBldGUID
            INNER JOIN erp25.dbo.mdm_Project mp
                ON mp.ProjGUID = gb.ProjGUID
        GROUP BY
            mp.ParentProjGUID
    ) F05601 ON F05601.ParentProjGUID = baseproj.ProjGUID

    -- 关联三个月前拍照版本的住宅累计已售面积
    LEFT JOIN (
        SELECT
            mp.ParentProjGUID,  -- 父级项目GUID，用于后续与主表关联
            SUM(
                CASE
                    -- 只统计住宅类产品（包括住宅、高级住宅、别墅）的已售面积
                    WHEN F056.产品类型 IN ('住宅', '高级住宅', '别墅')
                        THEN F056.已售面积
                    ELSE 0
                END
            ) AS 历史版本住宅已售面积  -- 该父级项目下住宅类产品的累计已售面积
        FROM
            dss.[dbo].[nmap_s_F056各项目产品楼栋表系统取数原始表单] F056
            INNER JOIN (
                -- 取2个月前当月最新的版本
                SELECT TOP 1
                    ver.VersionGuid,      -- 版本唯一标识
                    ver.StartTime         -- 版本开始时间
                FROM
                    dss.[dbo].[nmap_RptVersion] ver
                WHERE
                    ver.RptID = 'a7497fb0_41ca_457f_b95a_479d19b131cf'
                    AND DATEDIFF(MONTH, ver.StartTime, GETDATE()) = 2
                ORDER BY
                    ver.StartTime DESC
            ) b ON b.VersionGuid = F056.VersionGuid
            INNER JOIN erp25.dbo.mdm_GCBuild gb
                ON gb.GCBldGUID = F056.GCBldGUID
            INNER JOIN erp25.dbo.mdm_Project mp
                ON mp.ProjGUID = gb.ProjGUID
        WHERE
            F056.产品类型 IN ('住宅', '高级住宅', '别墅')
        GROUP BY
            mp.ParentProjGUID
    ) F056LastMonth ON F056LastMonth.ParentProjGUID = baseproj.ProjGUID

    -- 关联本次开工业态已售单方成本、均价、税后利润、销净率（各业态拼接字符串）
    LEFT JOIN (
        SELECT 
            projguid,
            
            -- 拼接各业态的单方成本（格式：业态:数值单位;...）
            STRING_AGG(
                CONCAT(
                    产品类型, 
                    ':', 
                    CONVERT(VARCHAR(100), 本次开工业态已售单方成本) + 单位
                ), 
                ';'
            ) AS 本次开工业态已售单方成本,
            
            -- 拼接各业态的已售均价（格式：业态:数值单位;...）
            STRING_AGG(
                CONCAT(
                    产品类型, 
                    ':', 
                    CONVERT(VARCHAR(100), 本次开工业态已售均价) + 单位
                ), 
                ';'
            ) AS 本次开工业态已售均价,
            
            -- 拼接各业态的已售税后利润（格式：业态:数值亿元;...）
            STRING_AGG(
                CONCAT(
                    产品类型, 
                    ':', 
                    CONVERT(VARCHAR(100), 累计净利润签约) + '亿元'
                ), 
                ';'
            ) AS 本次开工业态已售税后利润,
            
            -- 拼接各业态的已售销净率（格式：业态:数值%;...）
            STRING_AGG(
                CONCAT(
                    产品类型, 
                    ':', 
                    CONVERT(VARCHAR(100), 本次开工业态已售销净率) +'%'
                ), 
                ';'
            ) AS 本次开工业态已售销净率

        FROM (
            SELECT
                [ProjGUID],
                [产品类型],
                SUM([累计签约面积]) AS [累计签约面积], -- 各业态累计签约面积
                SUM(累计签约金额) AS 累计签约金额,   -- 各业态累计签约金额
                CONVERT(DECIMAL(18,2), SUM(ISNULL(累计净利润签约,0))) AS 累计净利润签约, -- 各业态累计净利润（签约）
                
                -- 销净率 = 累计净利润签约 / 累计签约金额不含税 * 100
                CONVERT(DECIMAL(18,2),
                    CASE 
                        WHEN SUM(ISNULL(累计签约金额不含税,0)) <> 0 
                            THEN SUM(ISNULL(累计净利润签约,0)) / SUM(ISNULL(累计签约金额不含税,0)) * 100.0
                        ELSE 0 
                    END
                ) AS 本次开工业态已售销净率,
                
                -- 单位：地下室/车库为“万/套”，其他为“元/㎡”
                CASE 
                    WHEN [产品类型] = '地下室/车库' THEN '万/套' 
                    ELSE '元/㎡' 
                END AS 单位,
                
                -- 单方成本（地下室/车库单位换算为万元/套，其他为元/㎡）
                CONVERT(
                    DECIMAL(18, 2), 
                    CASE 
                        WHEN [产品类型] = '地下室/车库' THEN  
                            CASE 
                                WHEN SUM([累计签约面积]) <> 0 THEN 
                                    (
                                        ISNULL(SUM([盈利规划营业成本单方] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划股权溢价单方] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划营销费用单方] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划综合管理费单方协议口径] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划税金及附加单方] * [累计签约面积]), 0)
                                    ) / SUM([累计签约面积]) / 10000.0
                                ELSE 0
                            END
                        ELSE 
                            CASE 
                                WHEN SUM([累计签约面积]) <> 0 THEN 
                                    (
                                        ISNULL(SUM([盈利规划营业成本单方] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划股权溢价单方] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划营销费用单方] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划综合管理费单方协议口径] * [累计签约面积]), 0) +
                                        ISNULL(SUM([盈利规划税金及附加单方] * [累计签约面积]), 0)
                                    ) / SUM([累计签约面积])
                                ELSE 0
                            END
                    END
                ) AS 本次开工业态已售单方成本,
                
                -- 已售均价（地下室/车库单位换算为万/套，其他为元/㎡）
                CONVERT(
                    DECIMAL(18, 2), 
                    CASE 
                        WHEN [产品类型] = '地下室/车库' THEN  
                            CASE 
                                WHEN SUM([累计签约面积]) <> 0 THEN 
                                    SUM(累计签约金额 * 10000.0) / SUM([累计签约面积])
                                ELSE 0
                            END 
                        ELSE 
                            CASE 
                                WHEN SUM([累计签约面积]) <> 0 THEN 
                                    SUM(累计签约金额 * 10000.0) / SUM([累计签约面积])
                                ELSE 0
                            END
                    END
                ) AS 本次开工业态已售均价

            FROM
                erp25.[dbo].[s_M002业态级净利汇总表_数仓用]
            WHERE
                DATEDIFF(DAY, [qxdate], GETDATE()) = 0 -- 仅取当天数据
                AND [累计签约面积] <> 0
            GROUP BY
                [ProjGUID],
                [产品类型],
                CASE 
                    WHEN [产品类型] = '地下室/车库' THEN '万/套' 
                    ELSE '元/㎡' 
                END
        ) ysdf
        WHERE 本次开工业态已售单方成本 > 0 -- 只保留有成本的业态
        GROUP BY [ProjGUID]
    ) ysdf ON ysdf.projguid = baseproj.projguid
order  by 公司名称,项目名称

