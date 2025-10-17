-- 开工申请新推承诺量价明细表清洗存储过程
-- ============================================
-- 存储过程名称：[usp_s_集团开工申请新推承诺量价明细表智能体数据提取]
-- 创建人: chenjw 2025-09-09
-- 作用：清洗并提取集团开工申请新推量价承诺跟踪明细表数据，供智能体使用
-- ============================================
CREATE OR ALTER PROC [dbo].[usp_s_集团开工申请新推承诺量价明细表智能体数据提取]
AS
BEGIN
    SET NOCOUNT ON;  -- 禁止显示受影响的行数信息
    /***********************************************************************
    步骤1：提取承诺主表数据，存入临时表#Commitment
    说明：
        - 从[本次新推承诺表]提取承诺主数据
        - 关联项目表获取推广名称
        - 字段说明见注释
    ***********************************************************************/
    SELECT  
        xt.本次新推量价承诺ID         AS [本次新推量价承诺ID],      -- 唯一主键
        xt.投管代码                  AS [投管代码],               -- 投管系统项目代码
        xt.项目GUID                  AS [项目GUID],               -- 项目唯一标识
        xt.项目名称                  AS [项目名称],               -- 项目名称
        p.SpreadName                 AS [推广名称],               -- 推广名称
        xt.承诺时间                  AS [承诺时间],               -- 承诺时间
        xt.本批开工的产品楼栋GUID      as [本批开工的产品楼栋GUID],
        xt.本批开工的产品楼栋编码        AS [本批开工的产品楼栋编码],     -- 楼栋编码（分号分隔）
        xt.本批开工的产品楼栋名称        AS [本批开工的产品楼栋名称]      -- 楼栋名称
    INTO #Commitment
    FROM [172.16.4.141].[MyCost_Erp352].dbo.本次新推承诺表 xt
    INNER JOIN data_wide_dws_mdm_Project p
        ON xt.项目GUID = p.projguid


    /***********************************************************************
    步骤2：拆分产品楼栋GUID，便于明细处理
    说明：
        - 一条承诺可能对应多个楼栋，楼栋GUID以分号分隔
        - 使用自定义拆分函数fn_Split1，将每个楼栋GUID拆分为单独一行
        - 结果存入临时表#ld
    ***********************************************************************/
    SELECT  
        a.本次新推量价承诺ID,
        a.投管代码,
        a.项目GUID,
        a.项目名称,
        a.推广名称,
        a.承诺时间,
        value AS 产品楼栋GUID
    INTO #ld
    FROM #Commitment a
    CROSS APPLY dbo.fn_Split1(a.本批开工的产品楼栋GUID, ';')
    WHERE ISNULL(a.本批开工的产品楼栋GUID, '') <> ''

    /***********************************************************************
    步骤2.1：生成承诺明细临时表#xtxmld
    说明：
        - 以拆分后的楼栋GUID为基础，生成明细表
        - 可后续补充与明细表的关联
    ***********************************************************************/
    SELECT 
        ld.本次新推量价承诺ID,
        ld.投管代码,
        ld.项目GUID,
        ld.项目名称,
        ld.推广名称,
        ld.承诺时间,
        ld.产品楼栋GUID
    INTO #xtxmld
    FROM #ld ld
    LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.[本次新推承诺明细表] chdtl
        ON ld.本次新推量价承诺ID = chdtl.本次新推量价承诺ID
        AND ld.产品楼栋GUID = chdtl.产品楼栋GUID

    -- 产品楼栋的产值信息
    SELECT 
        bld.OutputValueMonthReviewGUID, -- 产值月度评审GUID
        bld.BldGUID,                    -- 楼栋GUID
        bld.BldName,                    -- 楼栋名称
        bld.ProdBldGUID,                -- 产品楼栋GUID
        bld.ProdBldName,                -- 产品楼栋名称
        bld.Zcz  AS 总产值,                        -- 总产值  -- 亿元
        bld.Xmpdljwccz  as 累计已完成产值                 -- 累计已完成产值
    INTO #cz
    FROM [172.16.4.141].[MyCost_Erp352].dbo.cb_OutputValueReviewProdBld bld with (nolock)
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY ReviewDate DESC) AS num, -- 取最新
            OutputValueMonthReviewGUID,
            ProjGUID,
            ReviewDate
        FROM [172.16.4.141].[MyCost_Erp352].[dbo].[cb_OutputValueMonthReview] with (nolock)
        WHERE ApproveState = '已审核'
    ) vr  ON vr.OutputValueMonthReviewGUID = bld.OutputValueMonthReviewGUID  AND vr.num = 1
    inner join #xtxmld xt on xt.产品楼栋GUID = bld.ProdBldGUID

    -- 计算本年营销费率
    SELECT  
        t1.projguid,  -- 一级项目
        SUM(case when t.PlanDate = YEAR(GETDATE()) then t.ContractAmount else 0 end) 本年累计签约金额,	
        SUM(case when t.PlanDate = YEAR(GETDATE()) then t.TotalOccurredAmount else 0 end) 本年累计已发生费用,
        CASE WHEN SUM(case when t.PlanDate = YEAR(GETDATE()) then t.ContractAmount else 0 end) = 0 THEN 0 
         ELSE SUM(case when t.PlanDate = YEAR(GETDATE()) then t.TotalOccurredAmount else 0 end)
         /SUM(case when t.PlanDate = YEAR(GETDATE()) then t.ContractAmount else 0 end) END 本年营销费用系统已发生费率,
        SUM(case when t.PlanDate = 0 then t.ContractAmount else 0 end) 整盘累计签约金额,	
        SUM(case when t.PlanDate= 0 then t.TotalOccurredAmount else 0 end) 整盘累计已发生费用,
        CASE WHEN SUM(case when t.PlanDate= 0 then t.ContractAmount else 0 end) = 0 THEN 0 
         ELSE SUM(case when t.PlanDate= 0 then t.TotalOccurredAmount else 0 end)
         /SUM(case when t.PlanDate= 0 then t.ContractAmount else 0 end) END 整盘营销费用系统已发生费率
    INTO #fy_ys
    FROM [172.16.4.141].MyCost_Erp352.dbo.ys_OverAllPlanDtlWork t
    INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.ys_OverAllPlanWork t1 
        ON t.OverAllPlanGUID = t1.OverAllPlanGUID
    WHERE 1=1  -- t.PlanDate = YEAR(GETDATE()) 
        AND t.CostCode = 'C.01'
    GROUP BY t1.projguid 

    -- 管理费用和财务费用 
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
    into #Dss_cashflow
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
            [172.16.4.141].dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a
            INNER JOIN  [172.16.4.141].dss.dbo.nmap_F_FillHistory b
                ON a.FillHistoryGUID = b.FillHistoryGUID
    ) x
    WHERE 
        CASE
            WHEN ISNULL(x.[累计直接投资（万元）], 0) > 0 AND x.Isbase = 1 THEN 1
            ELSE 0
        END = 1 -- 只取已填报的最新版本
        and  EXISTS (  SELECT 1  FROM #Commitment xt  WHERE xt.项目GUID = x.BusinessGUID )

    -- 楼栋在建面积占比
    SELECT 
        projguid,
        BuildingGUID,
        SUM(楼栋在建面积) OVER (PARTITION BY projguid) AS 项目在建面积,
        楼栋在建面积,
        CASE 
            WHEN SUM(楼栋在建面积) OVER (PARTITION BY projguid) = 0 THEN 0  
            ELSE 楼栋在建面积 * 1.0 / SUM(楼栋在建面积) OVER (PARTITION BY projguid) 
        END AS 楼栋在建面积占比
    INTO #jzmj
    FROM (
        SELECT 
            bd.parentprojguid AS projguid,
            bd.BuildingGUID,
            SUM(
                CASE 
                    WHEN lddb.SJzskgdate IS NOT NULL 
                         AND lddb.SJjgbadate IS NULL 
                    THEN ISNULL(bd.BuildArea, 0) 
                    ELSE 0 
                END
            ) AS 楼栋在建面积
        FROM data_wide_dws_mdm_Building bd
        INNER JOIN data_wide_dws_s_p_lddbamj lddb 
            ON lddb.SaleBldGUID = bd.BuildingGUID 
            AND bd.BldType = '产品楼栋'
        WHERE EXISTS (
            SELECT 1 
            FROM #Commitment xt 
            WHERE xt.项目GUID = bd.parentprojguid
        )
        GROUP BY 
            bd.parentprojguid,
            bd.BuildingGUID
    ) ld

    -- -- M002表的成本单方数据
    -- SELECT 
    --     distinct
    --     projguid, 
    --     versionType,
    --     产品类型,
    --     产品名称,
    --     商品类型,
    --     装修标准,
    --     盈利规划营业成本单方,
    --     盈利规划股权溢价单方,
    --     盈利规划营销费用单方,
    --     盈利规划综合管理费单方协议口径,
    --     盈利规划税金及附加单方
    -- into  #M002
    -- FROM data_wide_dws_qt_M002项目业态级毛利净利表 
    -- WHERE versionType IN ('累计版', '本年版')

    /***********************************************************************
    步骤3：删除当天已存在的数据，避免重复插入
    说明：
        - 以清洗日期为准，删除当天数据
        - 保证数据唯一性
    ***********************************************************************/
    DELETE FROM s_集团开工申请新推量价承诺明细表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

    /***********************************************************************
    步骤4：插入最新清洗结果数据
    说明：
        - 从#xtxmld及相关表汇总数据，插入目标表
        - 部分字段暂未计算，后续可补充
        - 字段含义详见注释
    ***********************************************************************/
    INSERT INTO s_集团开工申请新推量价承诺明细表智能体数据提取 (
        [本次新推量价承诺ID],
        [投管代码],
        [项目名称],
        [推广名称],
        [项目GUID],
        [业态],
        [产品楼栋GUID],
        [产品楼栋编码],
        [产品楼栋名称],
        [首开日期],
        [可售面积],
        [开工货值],
        [供货周期],
        [去化周期],
        [累计签约回笼],
        [累计除地价外直投及费用],
        [累计贡献现金流],
        [一年内签约金额],
        [一年内回笼金额],
        [一年内除地价外直投及费用],
        [一年内贡献现金流],
        [含税签约金额],
        [已售面积],
        [不含税签约金额],
        [清洗日期]
    )
    SELECT 
        xt.本次新推量价承诺ID,                        -- 唯一主键
        xt.投管代码,                                 -- 投管系统项目代码
        xt.项目名称,                                 -- 项目名称
        xt.推广名称,                                 -- 推广名称
        xt.项目GUID,                                 -- 项目唯一标识
        -- 业态分类，住宅/车位/商办
        CASE 
            WHEN lddb.ProductType IN ('住宅', '高级住宅', '别墅') THEN '住宅'
            WHEN lddb.ProductType = '地下室/车库' THEN '车位'
            ELSE '商办'
        END AS [业态],
        xt.产品楼栋GUID,                             -- 楼栋GUID
        bd.Code AS [产品楼栋编码],                   -- 楼栋编码
        bd.BuildingName AS [产品楼栋名称],           -- 楼栋名称
        sk.首开日期,                                -- 首开日期（楼栋下第一个房间的认购/签约日期）
        lddb.zksmj / 10000.0 AS [可售面积],          -- 楼栋总可售面积（单位：万㎡）
        -- 开工货值，实际开工节点的实际完成时间不为空的未售货值含税（单位：亿元）
        CASE 
            WHEN lddb.SJzskgdate IS NOT NULL THEN lddb.zhz --lddb.syhz 
            ELSE 0  
        END / 100000000.0 AS [开工货值],

        -- 供货周期=楼栋实际达预售形象汇报完成时间-楼栋实际开工汇报完成时间（月）
        DATEDIFF(MONTH, isnull(lddb.SJzskgdate, lddb.YJzskgdate), isnull(lddb.SjDdysxxDate, lddb.YjDdysxxDate)) AS [供货周期],
        -- 去化周期=楼栋下最后一个房间的签约时间-第一个房间的认购时间（月）
        -- CASE WHEN    sk.售罄日期 IS NOT NULL 
        --     THEN DATEDIFF(MONTH, sk.首开日期, sk.售罄日期)
        -- END AS [去化周期],
        case when datediff(day,getdate(),isnull(sk.售罄日期,'1900-01-01')) >= 0 then
           datediff(day,sk.首开日期,isnull(sk.售罄日期,'1900-01-01')) / 30.0 
          when datediff(day,getdate(),isnull(sk.售罄日期,'1900-01-01')) <0 then
            datediff(day,sk.首开日期,getdate()) / 30.0 end  AS [去化周期],  

        hk.累计回笼金额 / 100000000.0 AS [累计签约回笼], -- 累计签约回笼（单位：亿元）
        --- 取M002表楼栋对应业态组合键(产品类型+产品名称+商品类型+装修标准)的“盈利规划营业成本单方”+“”+“盈利规划股权溢价单方”+“盈利规划营销费用单方”+“盈利规划综合管理费单方协议口径”+“盈利规划税金及附加单方”*一年内楼栋的销售面积
        -- case when bd.TopProductTypeName ='地下室/车库' then 
        --             (isnull(ljm002.盈利规划营业成本单方,0) 
        --             +isnull(ljm002.盈利规划股权溢价单方,0)
        --             +isnull(ljm002.盈利规划营销费用单方,0)
        --             +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售套数,0) 
        -- else 
        --        (isnull(ljm002.盈利规划营业成本单方,0) 
        --             +isnull(ljm002.盈利规划股权溢价单方,0)
        --             +isnull(ljm002.盈利规划营销费用单方,0)
        --             +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售面积,0)
        -- end / 100000000.0 AS [累计除地价外直投及费用],                -- 预留，后续补充
        -- isnull(hk.累计回笼金额,0) / 100000000.0  -
        -- case when bd.TopProductTypeName ='地下室/车库' then 
        --             (isnull(ljm002.盈利规划营业成本单方,0) 
        --             +isnull(ljm002.盈利规划股权溢价单方,0)
        --             +isnull(ljm002.盈利规划营销费用单方,0)
        --             +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售套数,0) 
        -- else 
        --        (isnull(ljm002.盈利规划营业成本单方,0) 
        --             +isnull(ljm002.盈利规划股权溢价单方,0)
        --             +isnull(ljm002.盈利规划营销费用单方,0)
        --             +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售面积,0)
        -- end / 100000000.0   AS [累计贡献现金流],                        -- 累计签约回笼（亿）X1 - 累计除地价外直投及费用（亿）Y1
        isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.一年内签约金额 / 100000000.0 ) * fy.本年营销费用系统已发生费率
        + (isnull(dss.YearManageAmount,0) + isnull(dss.YearFinancial,0)) / 10000 * jzmj.楼栋在建面积占比      as 累计除地价外直投及费用,
        isnull(hk.累计回笼金额 / 100000000.0,0) 
        -(isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.一年内签约金额 / 100000000.0 ) * fy.本年营销费用系统已发生费率
        + (isnull(dss.YearManageAmount,0) + isnull(dss.YearFinancial,0)) / 10000 * jzmj.楼栋在建面积占比  )    as 累计贡献现金流, -- 累计签约回笼-累计除地价外直投及费用
        sf.一年内签约金额 / 100000000.0 AS [一年内签约金额], -- 一年内签约金额（单位：亿元）
        hk.累计本年回笼金额 / 100000000.0 AS [一年内回笼金额], -- 一年内回笼金额（单位：亿元）
        -- case when bd.TopProductTypeName ='地下室/车库' then 
        --             (isnull(bnm002.盈利规划营业成本单方,0) 
        --             +isnull(bnm002.盈利规划股权溢价单方,0)
        --             +isnull(bnm002.盈利规划营销费用单方,0)
        --             +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约套数,0) 
        -- else 
        --        (isnull(bnm002.盈利规划营业成本单方,0) 
        --             +isnull(bnm002.盈利规划股权溢价单方,0)
        --             +isnull(bnm002.盈利规划营销费用单方,0)
        --             +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约面积,0)
        -- end  / 100000000.0 AS [一年内除地价外直投及费用],              -- 预留，后续补充
        
        -- hk.累计本年回笼金额 / 100000000.0 - 
        -- case when bd.TopProductTypeName ='地下室/车库' then 
        --             (isnull(bnm002.盈利规划营业成本单方,0) 
        --             +isnull(bnm002.盈利规划股权溢价单方,0)
        --             +isnull(bnm002.盈利规划营销费用单方,0)
        --             +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约套数,0) 
        -- else 
        --        (isnull(bnm002.盈利规划营业成本单方,0) 
        --             +isnull(bnm002.盈利规划股权溢价单方,0)
        --             +isnull(bnm002.盈利规划营销费用单方,0)
        --             +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
        --             +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约面积,0)
        -- end  / 100000000.0 AS [一年内贡献现金流],                      -- 一年内实现回笼（亿）X2 - 一年内除地价外直投及费用（亿）Y2

        isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.一年内签约金额 / 100000000.0 ) * fy.本年营销费用系统已发生费率
        + (isnull(dss.YearManageAmount,0) + isnull(dss.YearFinancial,0)) / 10000 * jzmj.楼栋在建面积占比    as  [一年内除地价外直投及费用],
        isnull(hk.累计本年回笼金额 / 100000000.0,0) - 
        (
        isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.一年内签约金额 / 100000000.0 ) * fy.本年营销费用系统已发生费率
        + (isnull(dss.YearManageAmount,0) + isnull(dss.YearFinancial,0)) / 10000 * jzmj.楼栋在建面积占比  
        )  as  [一年内贡献现金流],     --本年回笼-本年除地价外直投及费用
        sf.含税签约金额 / 100000000.0 AS [含税签约金额], -- 含税签约金额（单位：亿元）
        sf.已售面积 / 10000.0 AS [已售面积],             -- 已售面积（单位：万㎡）
        sf.不含税签约金额 / 100000000.0 AS [不含税签约金额], -- 不含税签约金额（单位：亿元）
        GETDATE() AS [清洗日期]                          -- 当前清洗日期
    FROM #xtxmld xt
    -- 关联楼栋主数据，获取编码、名称
    inner JOIN data_wide_dws_mdm_Building bd ON bd.BuildingGUID = xt.产品楼栋GUID  AND bd.BldType = '产品楼栋'
    -- 关联楼栋底表，获取业态、面积、开工等信息
    LEFT JOIN data_wide_dws_s_p_lddbamj lddb  ON lddb.SaleBldGUID = xt.产品楼栋GUID
    left  join #cz cz  on cz.ProdBldGUID = xt.产品楼栋GUID
    left join #Jzmj jzmj on jzmj.BuildingGUID =xt.产品楼栋GUID
    -- 计算首开日期、售罄日期
    LEFT JOIN (
        SELECT 
            本次新推量价承诺ID,
            产品楼栋GUID,
            首开日期,
            CASE 
                WHEN ISNULL(sale.TotalRoomCount, 0) = ISNULL(sale.QyRoomCount, 0) 
                    THEN lastQyDate 
            END AS 售罄日期
        FROM (
            SELECT 
                xt.本次新推量价承诺ID,
                xt.产品楼栋GUID,
                -- 首开日期：第一个认购/签约房间的认购/签约日期
                MIN(
                    CASE 
                        WHEN Status IN ('认购', '签约') AND specialFlag <> '是' THEN ISNULL(RgQsDate, QSDate)
                        WHEN Status IN ('认购', '签约') THEN ISNULL(TsRoomQSDate, ISNULL(RgQsDate, QSDate))
                    END
                ) AS 首开日期,
                -- 售罄日期：最后一个签约房间的签约日期
                MAX(
                    CASE 
                        WHEN Status = '签约' AND specialFlag <> '是' THEN QSDate
                        WHEN Status = '签约' THEN ISNULL(TsRoomQSDate, QSDate) 
                    END
                ) AS lastQyDate,
                COUNT(1) AS TotalRoomCount, -- 房间总数
                SUM(CASE WHEN Status = '签约' THEN 1 ELSE 0 END) AS QyRoomCount -- 签约房间数
            FROM data_wide_s_RoomoVerride room
            INNER JOIN #xtxmld xt 
                ON room.bldguid = xt.产品楼栋GUID
            GROUP BY xt.本次新推量价承诺ID, xt.产品楼栋GUID
        ) sale 
        WHERE ISNULL(sale.TotalRoomCount, 0) > 0
    ) sk  ON sk.本次新推量价承诺ID = xt.本次新推量价承诺ID  AND sk.产品楼栋GUID = xt.产品楼栋GUID
    -- 关联房款一览表，获取累计回笼金额
    LEFT JOIN (
        SELECT  
            xt.本次新推量价承诺ID,
            xt.产品楼栋GUID,
            SUM(ISNULL(fk.累计回笼金额,0)) AS 累计回笼金额,         -- 累计签约回笼
            SUM(ISNULL(fk.累计本年回笼金额,0)) AS 累计本年回笼金额   -- 一年内实现回笼
        FROM data_wide_dws_s_s_gsfkylbmxb fk
        INNER JOIN data_wide_s_RoomoVerride room
            ON fk.roomguid = room.roomguid
        INNER JOIN #xtxmld xt
            ON room.bldguid = xt.产品楼栋GUID
        GROUP BY xt.本次新推量价承诺ID, xt.产品楼栋GUID   
    ) hk
        ON hk.本次新推量价承诺ID = xt.本次新推量价承诺ID
        AND hk.产品楼栋GUID = xt.产品楼栋GUID
    -- 关联销售业绩表，获取签约金额、面积等
    LEFT JOIN (
        SELECT 
            xt.本次新推量价承诺ID, 
            xt.产品楼栋GUID,
            SUM(CASE WHEN DATEDIFF(YEAR, sf.StatisticalDate, GETDATE()) = 0
                     THEN ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)
                     ELSE 0 END) AS 一年内签约金额, -- 一年内签约金额
            SUM(CASE WHEN DATEDIFF(YEAR, sf.StatisticalDate, GETDATE()) = 0
                     THEN ISNULL(sf.CNetArea, 0) + ISNULL(sf.SpecialCNetArea, 0)
                     ELSE 0 END) AS 一年内签约面积, -- 一年内签约面积
            SUM(CASE WHEN DATEDIFF(YEAR, sf.StatisticalDate, GETDATE()) = 0
                     THEN ISNULL(sf.CNetCount, 0) + ISNULL(sf.SpecialCNetCount, 0)
                     ELSE 0 END) AS 一年内签约套数, -- 一年内签约套数
            SUM(ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)) AS 含税签约金额, -- 含税签约金额
            SUM(ISNULL(sf.CNetArea, 0) + ISNULL(sf.SpecialCNetArea, 0)) AS 已售面积,         -- 已售面积
            sum(isnull(sf.CNetCount,0) + isnull(sf.SpecialCNetCount,0)) as 已售套数,
            SUM(ISNULL(sf.CNetAmountNotTax, 0) + ISNULL(sf.SpecialCNetAmountNotTax, 0)) AS 不含税签约金额 -- 不含税签约金额
        FROM data_wide_dws_s_SalesPerf sf
        INNER JOIN #xtxmld xt
            ON sf.bldguid = xt.产品楼栋GUID
        GROUP BY xt.本次新推量价承诺ID, xt.产品楼栋GUID
    ) sf ON sf.本次新推量价承诺ID = xt.本次新推量价承诺ID AND sf.产品楼栋GUID = xt.产品楼栋GUID
    -- -- 销净率 统计
    -- left join #m002 ljm002 on xt.项目GUID =ljm002.projguid and ljm002.versionType ='累计版'  
    --                           and bd.TopProductTypeName =ljm002.产品类型 
    --                           and bd.ProductTypeName = ljm002.产品名称
    --                           and bd.CommodityType = ljm002.商品类型
    --                           and bd.ZxBz = ljm002.装修标准
    -- left join #m002 bnm002 on xt.项目GUID =bnm002.projguid and bnm002.versionType ='本年版'  
    --                           and bd.TopProductTypeName =bnm002.产品类型 
    --                           and bd.ProductTypeName = bnm002.产品名称
    --                           and bd.CommodityType = bnm002.商品类型
    --                           and bd.ZxBz = bnm002.装修标准
    left join #fy_ys fy on xt.项目GUID =fy.projguid
    left join #Dss_cashflow dss on xt.项目GUID =dss.projguid
    

    /***********************************************************************
    步骤5：清理历史数据，仅保留必要快照
    说明：
        - 保留当天数据
        - 仅保留以下特殊快照，其余超过7天的历史数据将被删除：
            1. 每周一
            2. 每月1号
            3. 每月最后一天
            4. 每年最后一天
    ***********************************************************************/
    DELETE FROM s_集团开工申请新推量价承诺明细表智能体数据提取
    WHERE
        (
            -- 非每周一
            DATENAME(WEEKDAY, 清洗日期) <> '星期一'
            -- 非每月1号
            AND DATEPART(DAY, 清洗日期) <> 1
            -- 非每年最后一天
            AND DATEDIFF(DAY, 清洗日期, CONVERT(VARCHAR(4), YEAR(清洗日期)) + '-12-31') <> 0
            -- 非每月最后一天
            AND DATEDIFF(DAY, 清洗日期, DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗日期) + 1, 0))) <> 0
            -- 距今超过7天
            AND DATEDIFF(DAY, 清洗日期, GETDATE()) > 7
        )

    /***********************************************************************
    步骤6：查询当天数据，供后续分析或校验
    说明：
        - 返回当天清洗后的明细数据，便于后续分析或校验
    ***********************************************************************/
    SELECT *
    FROM s_集团开工申请新推量价承诺明细表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0
    ORDER BY 项目名称, 业态

    /***********************************************************************
    步骤7：删除临时表，释放资源
    说明：
        - 删除临时表#Commitment、#xtxmld，释放内存
    ***********************************************************************/
    DROP TABLE #Commitment, #xtxmld,#Dss_cashflow

END