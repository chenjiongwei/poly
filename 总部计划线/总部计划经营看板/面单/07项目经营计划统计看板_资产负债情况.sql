
-- 资产负债情况统计存储过程
-- 用于清洗并汇总各项目的资产负债相关数据，最终写入zb_jyjhtjkb_BalanceSheet表

CREATE or  alter  PROC [dbo].[usp_zb_jyjhtjkb_BalanceSheet]
AS
BEGIN
    /********************************************************************
    * 1. 汇总股东投资信息，生成#Shareholder_investment临时表
    *    来源：data_wide_dws_qt_Shareholder_investment
    *    逻辑：取每个项目最新一次填报的“截止目前股东合作方投入余额C”，
    *         并按项目聚合
    ********************************************************************/
    SELECT 
        p.projguid,
        p.projname,
        SUM( ISNULL(oa.截止目前股东合作方投入余额C, 0) ) /100000000.0 AS 截止目前股东投入余额,
        SUM( case when  isnull(oa.股东合作方简称,'') = '' then ISNULL(oa.截止目前股东合作方投入余额C, 0) end ) /100000000.0 AS 截止目前保利方投入余额
    INTO #Shareholder_investment
    FROM data_wide_dws_mdm_Project p
    OUTER APPLY (
        SELECT 
            si.截止目前股东合作方投入余额C,
			si.股东合作方简称
        FROM 
            data_wide_dws_qt_Shareholder_investment si
        WHERE 
            si.明源代码 = p.ProjCode
            AND si.FillHistoryGUID IN (
                SELECT TOP 1 FillHistoryGUID
                FROM data_wide_dws_qt_Shareholder_investment
                ORDER BY FillDate DESC
            )
    ) oa
    WHERE p.level = 2  -- 只统计二级项目
    GROUP BY p.projguid, p.projname

    /********************************************************************
    * 2. 汇总现金流数据，生成#DssCashFlowData临时表
    *    来源：data_wide_dws_ys_ys_DssCashFlowData
    *    逻辑：只取isbase=1的记录，提取银行贷款余额和供应链贷款余额
    ********************************************************************/
    SELECT 
        ProjGUID,
        projname,
        LoanBalanceTotal /10000.0 AS 截止目前银行贷款余额, -- 单位：亿元
        SupplyChainLoan /10000.0 AS 截止目前供应链余额 -- 单位：亿元
    INTO #DssCashFlowData
    FROM data_wide_dws_ys_ys_DssCashFlowData
    WHERE isbase = 1

    /********************************************************************
    * 3. 获取经营计划统计看板表最新数据，生成#JyjhtjkbTb临时表
    *    来源：data_wide_dws_qt_Jyjhtjkb
    *    逻辑：每个项目只取最新一次填报
    ********************************************************************/
    SELECT 
        jytb.项目GUID,
        jytb.原始股东投入,
        jytb.贷款还款计划
    INTO #JyjhtjkbTb
    FROM data_wide_dws_qt_Jyjhtjkb jytb
    WHERE jytb.FillHistoryGUID IN (
        SELECT TOP 1 FillHistoryGUID
        FROM data_wide_dws_qt_Jyjhtjkb
        ORDER BY FillDate DESC
    )

    /********************************************************************
    * 4. 汇总产值报表数据，生成#cb_cxf临时表
    *    来源：data_wide_dws_cb_cxf
    *    逻辑：按父级项目（ParentGUID）聚合分期的应付未付和已达产值未付
    ********************************************************************/
    SELECT 
        p.ParentGUID AS projguid,
        SUM(ISNULL(cz.应付未付, 0)) AS 应付未付,
        SUM(ISNULL(cz.已达产值未付, 0)) AS 已达产值未付
    INTO #cb_cxf
    FROM data_wide_dws_cb_cxf cz
    INNER JOIN data_wide_dws_mdm_Project p ON p.projguid = cz.分期GUID
    WHERE p.level = 3  -- 只统计三级分期
    GROUP BY p.ParentGUID

    
     SELECT 
         p.ParentGUID AS projguid,
         SUM(CASE WHEN 正式开工实际完成时间 IS NOT NULL THEN 未售对应总成本 ELSE 0 END) / 10000.0 AS 已开工未售占压成本,
         CASE 
             WHEN SUM(ISNULL(总建面, 0)) = 0 THEN 0
             ELSE SUM(ISNULL(持有面积, 0)) / SUM(ISNULL(总建面, 0))
         END AS 持有比例, -- 持有比例
         SUM(占压资金) AS 占压资金,  -- F056已开工未售占压成本
         CASE 
             WHEN SUM(ISNULL(总建面, 0)) = 0 THEN 0
             ELSE SUM(ISNULL(持有面积, 0)) / SUM(ISNULL(总建面, 0))
         END * SUM(占压资金) AS 留存资产 -- F056持有面积对应占压成本
     INTO #F056
     FROM data_wide_dws_qt_F05601 f056
     INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = f056.ProjGUID
     WHERE p.Level = 3
     GROUP BY p.ParentGUID

     -- M002表的单方
     SELECT DISTINCT
         projguid,
         versionType,
         产品类型,
         产品名称,
         商品类型,
         装修标准,
         土地款_单方
     INTO #M002
     FROM data_wide_dws_qt_M002项目业态级毛利净利表
     WHERE versionType IN ('累计版');

     SELECT
         jr.projguid,
         SUM(ISNULL(jr.未开工计容面积, 0) * ISNULL(ljm002.土地款_单方, 0))  /100000000.0   AS 未开工占压地价 -- M002土地单方成本*未开工计容面积
     into #wkgzydj
     FROM (
         SELECT
             ParentGUID AS projguid,
             产品类型,
             产品名称,
             商品类型,
             装修标准,
             SUM(CASE WHEN 正式开工实际完成时间 IS NULL THEN 计容面积 ELSE 0 END) AS 未开工计容面积
         FROM data_wide_dws_qt_F05601 F056
         INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = f056.ProjGUID
         WHERE p.level = 3
         GROUP BY
             ParentGUID,
             产品类型,
             产品名称,
             商品类型,
             装修标准
     ) jr
     LEFT JOIN #M002 ljm002
         ON jr.projguid = ljm002.projguid
         AND jr.产品类型 = ljm002.产品类型
         AND jr.产品名称 = ljm002.产品名称
         AND jr.商品类型 = ljm002.商品类型
         AND jr.装修标准 = ljm002.装修标准
    group by  jr.projguid
     
     /*******************************************************************
    -- 项目大屏——账面资金余额
    -- 取资金表的最新同步日期
    *******************************************************************/

    SELECT 
        MAX(business_date) AS business_date
    INTO #d_date
    FROM data_wide_dws_qt_fund_detail
    WHERE balance > 0;

    -- 缓存项目公司跟项目的映射情况
    SELECT 
        cltProjectCode,
        cltProjectName,
        project_company,
        TgProjCode AS my_tgprojcode,
        ProjGUID,
        account_nature,
        capital_nature,
        balance
    INTO #dw_proj_com
    FROM data_wide_dws_qt_fund_detail t
    LEFT JOIN data_wide_dws_mdm_project pj 
        ON (pj.TgProjCode = t.cltProjectCode OR cltProjectName = projname) 
        AND pj.level = 2
    INNER JOIN #d_date dd ON 1 = 1
    WHERE DATEDIFF(dd, t.business_date, dd.business_date) = 0;

    -- 缓存项目公司及项目的映射关系
    SELECT 
        project_company,
        ProjGUID
    INTO #com_proj
    FROM #dw_proj_com
    GROUP BY project_company, ProjGUID;

    -- 统计每个项目公司对应的项目数量
    SELECT 
        project_company,
        COUNT(DISTINCT projguid) AS proj_num
    INTO #proj_num
    FROM #com_proj
    WHERE projguid IS NOT NULL
    GROUP BY project_company;

    -- 缓存项目公司的资金情况
    SELECT 
        project_company,
        account_nature,
        capital_nature,
        SUM(balance) AS 项目公司资金
    INTO #zj
    FROM #dw_proj_com
    GROUP BY project_company, account_nature, capital_nature;

    -- 如果是项目公司跟项目数量是一比一的，把对应项目公司的所有户都归到这个项目上
    SELECT 
        cp.ProjGUID, 
        t.项目公司资金 AS 期末账面资金余额,
        CASE 
            WHEN account_nature = '监控房款户' THEN t.项目公司资金 
            ELSE 0 
        END AS 期末监管资金余额
    INTO #tmp_result
    FROM #zj t
    INNER JOIN #proj_num proj ON t.project_company = proj.project_company
    INNER JOIN #com_proj cp ON t.project_company = cp.project_company
    WHERE proj.proj_num = 1;

    -- 存在项目公司有多个项目的情况：
    -- 获取项目的本年回笼金额,对比项目公司中项目的回笼金额
    SELECT 
        t.*,
        本年回笼金额,
        ROW_NUMBER() OVER (PARTITION BY t.project_company ORDER BY ISNULL(本年回笼金额, 0) DESC) AS rn
    INTO #hl
    FROM #com_proj t
    LEFT JOIN (
        SELECT 
            项目GUID,
            SUM(本年回笼金额) AS 本年回笼金额
        FROM dw_f_TopProject_getin
        GROUP BY 项目guid
    ) hl ON t.projguid = hl.项目guid;

    INSERT INTO #tmp_result
    SELECT 
        cp.ProjGUID,
        t.项目公司资金 AS 期末账面资金余额,
        CASE 
            WHEN cp.rn = 1 THEN t.项目公司资金 
            ELSE 0 
        END AS 期末监管资金余额
    FROM #zj t
    INNER JOIN #proj_num proj ON t.project_company = proj.project_company
    INNER JOIN #hl cp ON t.project_company = cp.project_company
    WHERE proj.proj_num > 1;
    
    -- 汇总项目的账面资金余额和监管资金余额，单位：亿元
    SELECT 
        pj.ProjGUID,
        pj.ProjName,
        pj.TgProjCode,
        pj.level,
        SUM(t.期末监管资金余额) / 100000000.0 AS 期末监管资金余额,   -- 单位：亿元
        SUM(t.期末账面资金余额) / 100000000.0 AS 期末账面资金余额    -- 单位：亿元
    INTO #jhx
    FROM #tmp_result t
    INNER JOIN data_wide_dws_mdm_Project pj ON t.ProjGUID = pj.ProjGUID
    GROUP BY pj.ProjGUID, pj.ProjName, pj.TgProjCode, pj.Level;

    -- -----------------结束账面资金的取数------------------------


    /********************************************************************
    * 5. 删除当天已存在的数据，避免重复插入
    ********************************************************************/
    DELETE FROM zb_jyjhtjkb_BalanceSheet
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

    /********************************************************************
    * 6. 汇总各项数据，插入资产负债情况表
    *    说明：部分字段暂无数据，填NULL
    ********************************************************************/
    INSERT INTO zb_jyjhtjkb_BalanceSheet
    (
        buguid,
        projguid,
        清洗日期,
        原始股东投入,
        截止目前股东投入余额,
        截止目前保利方投入余额,
        截止目前银行贷款余额,
        截止目前供应链余额,
        应付未付工程款,
        已发生产值未付,
        贷款还款计划,
        货币资金,
        未开工占压地价,
        已开工未售占压成本,
        留存资产
    )
    SELECT 
        p.buguid AS [buguid],                                    -- 事业部GUID
        p.projguid AS [projguid],                                -- 项目GUID
        GETDATE() AS [清洗日期],                                 -- 当前清洗日期
        tb.[原始股东投入],                                       -- 原始股东投入
        si.截止目前股东投入余额 AS [截止目前股东投入余额], -- 截止目前股东投入余额
        si.截止目前保利方投入余额 AS [截止目前保利方投入余额],                        -- 保利方投入余额（暂无数据）
        cf.截止目前银行贷款余额 AS [截止目前银行贷款余额],         -- 银行贷款余额
        cf.截止目前供应链余额 AS [截止目前供应链余额],             -- 供应链贷款余额
        cz.应付未付 AS [应付未付工程款],                         -- 应付未付工程款
        cz.已达产值未付 AS [已发生产值未付],                     -- 已发生产值未付
        tb.[贷款还款计划],                                       -- 贷款还款计划
        jhx.期末账面资金余额  AS [货币资金],                                      -- 项目大屏-账面资金余额
        wkg.未开工占压地价 AS [未开工占压地价],                                -- M002土地单方成本*未开工计容面积
        F056.已开工未售占压成本 AS [已开工未售占压成本],                            -- F056已开工未售占压成本
        F056.留存资产 AS [留存资产]                                       -- F056持有面积对应占压成本
    FROM data_wide_dws_mdm_Project p
        LEFT JOIN #Shareholder_investment si ON si.projguid = p.projguid
        LEFT JOIN #DssCashFlowData cf ON cf.ProjGUID = p.projguid
        LEFT JOIN #JyjhtjkbTb tb ON tb.项目GUID = p.projguid
        LEFT JOIN #cb_cxf cz ON cz.projguid = p.projguid
        left join  #F056 F056 on f056.projguid =p.projguid
        left join #jhx jhx on jhx.projguid = p.projguid
        left join #wkgzydj  wkg on wkg.projguid =p.projguid
    WHERE p.level = 2  -- 只统计二级项目

    /********************************************************************
    * 7. 查询当天插入的最终数据，便于校验
    ********************************************************************/
    SELECT * 
    FROM zb_jyjhtjkb_BalanceSheet
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

    /********************************************************************
    * 8. 删除临时表，释放资源
    ********************************************************************/
    DROP TABLE #JyjhtjkbTb;
    DROP TABLE #DssCashFlowData;
    DROP TABLE #Shareholder_investment;
    drop  TABLE #cb_cxf;
    drop  TABLE  #F056;
END
