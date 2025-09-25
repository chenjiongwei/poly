-- 现金流指标清洗存储过程
CREATE OR ALTER PROC usp_zb_jyjhtjkb_CashFlow
AS
BEGIN
    /**************************************************************
    * 1. 获取盈利规划系统全投资IRR（动态版）
    *    说明：从data_wide_dws_ys_proj_expense表中筛选IsBase=1的基础版本，
    *    并将每个项目的最新动态IRR存入临时表#FullIRR_dt
    ***************************************************************/
    SELECT 
        ProjGUID,           -- 项目GUID
        FullIRR             -- 全投资IRR（动态版）
    INTO #FullIRR_dt
    FROM data_wide_dws_ys_proj_expense
    WHERE IsBase = 1;       -- 只取基础版本

    /**************************************************************
    * 2. 获取经营计划填报相关指标
    *    说明：从data_wide_dws_qt_Jyjhtjkb表中获取最新一次填报的相关字段，
    *    包括股东投资峰值、机会成本损失等，存入临时表#JyjhtjkbTb
    ***************************************************************/
    SELECT 
        jytb.项目GUID,
        jytb.股东投资峰值_立项版,
        jytb.股东投资峰值_动态版,
        jytb.机会成本损失,
        jytb.机会成本损失对应单方成本
    INTO #JyjhtjkbTb
    FROM data_wide_dws_qt_Jyjhtjkb jytb
    WHERE jytb.FillHistoryGUID IN (
        SELECT TOP 1 FillHistoryGUID
        FROM data_wide_dws_qt_Jyjhtjkb
        ORDER BY FillDate DESC
    );

    /**************************************************************
    * 3. 获取项目填报事实表最新版本数据
    *    说明：从dw_f_Proj_Filltab_Fact表中，按versionguid、年、月分组，
    *    只保留累计直接投资大于0的最新一条数据，存入临时表#dw_f_Proj_Filltab_Fact
    ***************************************************************/
    SELECT 
        fact.*
    INTO #dw_f_Proj_Filltab_Fact
    FROM [dw_f_Proj_Filltab_Fact] fact
    INNER JOIN (
        SELECT 
            versionguid,
            年,
            月,
            ROW_NUMBER() OVER (ORDER BY 年 DESC, 月 DESC) AS num
        FROM dw_f_Proj_Filltab_Fact
        GROUP BY versionguid, 年, 月
        HAVING SUM(累计直接投资) > 0
    ) bb 
        ON fact.versionguid = bb.versionguid 
        AND bb.num = 1;

    /**************************************************************
    * 4. 计算累计经营性现金流
    *    说明：累计经营性现金流 = (累计回笼金额/10000 - 累计总投资金额 - 累计税金)/10000
    *    结果存入临时表#xjl
    ***************************************************************/
    SELECT 
        pj.projguid,
        (
            ISNULL(hl.累计回笼金额, 0) / 10000.0 
            - ISNULL(a.累计总投资金额, 0) 
            - ISNULL(a.累计税金, 0)
        ) / 10000.0 AS 累计经营性现金流 -- 单位：万元
    INTO #xjl
    FROM data_wide_dws_mdm_Project pj
    LEFT JOIN #dw_f_Proj_Filltab_Fact a ON pj.ProjGUID = a.项目guid
    LEFT JOIN dw_f_TopProject_getin hl ON hl.项目guid = pj.ProjGUID
    WHERE pj.level = 2; -- 只统计二级项目

    /**************************************************************
    * 5. 获取立项全投资IRR（立项版）
    *    说明：从F076项目运营情况跟进表中，按EndTime倒序取最新一条，
    *    并计算现金流回正时长（立项版、动态版），存入临时表#FullIRR_lx
    ***************************************************************/
    SELECT 
        f076.项目GUID,                                   -- 项目GUID
        p.BeginDate AS 项目获取时间,                     -- 项目获取时间
        f076.立项全投资IRR,                              -- 全投资IRR（立项版）
        f076.立项全投资现金流回正时间,                   -- 立项全投资现金流回正时间
        f076.动态全投资现金流回正,                       -- 动态全投资现金流回正时间
        DATEDIFF(MONTH, p.BeginDate, f076.立项全投资现金流回正时间) AS 现金流回正时长立项版,   -- 立项版现金流回正时长（月）
        DATEDIFF(MONTH, p.BeginDate, f076.动态全投资现金流回正) AS 现金流回正时长动态版         -- 动态版现金流回正时长（月）
    INTO #FullIRR_lx
    FROM data_wide_dws_qt_nmap_s_F076项目运营情况跟进表 f076
    INNER JOIN data_wide_dws_mdm_Project p 
        ON f076.项目GUID = p.projguid AND p.level = 2
    WHERE versionguid IN (
        SELECT TOP 1 versionguid
        FROM data_wide_dws_qt_nmap_s_F076项目运营情况跟进表
        ORDER BY EndTime DESC
    );

    /**************************************************************
    * 6. 删除当天已存在的数据，避免重复插入
    ***************************************************************/
    DELETE FROM zb_jyjhtjkb_CashFlow
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    /**************************************************************
    * 7. 汇总各项数据，插入现金流指标表
    *    说明：将各临时表数据汇总，插入到目标表zb_jyjhtjkb_CashFlow
    ***************************************************************/
    INSERT INTO zb_jyjhtjkb_CashFlow
    (
        [buguid],                        -- 事业部GUID
        [projguid],                      -- 项目GUID
        [清洗日期],                      -- 当前清洗日期
        [全投资IRR_动态版],               -- 盈利规划系统全投资IRR
        [全投资IRR_立项版],               -- 立项全投资IRR
        [现金流回正时间_立项版],           -- 立项版现金流回正时间
        [现金流回正时长_立项版],           -- 立项版现金流回正时长
        [现金流回正时间_动态版],           -- 动态版现金流回正时间
        [现金流回正时长_动态版],           -- 动态版现金流回正时长
        [截止目前经营性现金流余额],         -- 截止目前经营性现金流余额
        [股东投资峰值_立项版],             -- 股东投资峰值_立项版
        [股东投资峰值_动态版],             -- 股东投资峰值_动态版
        [机会成本损失],                   -- 机会成本损失
        [机会成本损失对应单方成本],         -- 机会成本损失对应单方成本
        [项目获取日期]
    )
    SELECT
        p.buguid AS [buguid],                                -- 事业部GUID
        p.projguid AS [projguid],                            -- 项目GUID
        GETDATE() AS [清洗日期],                             -- 当前清洗日期
        irr_dt.FullIRR AS [全投资IRR_动态版],                 -- 盈利规划系统全投资IRR
        irr_lx.立项全投资IRR AS [全投资IRR_立项版],           -- 立项全投资IRR
        irr_lx.立项全投资现金流回正时间 AS [现金流回正时间_立项版],      -- 立项版现金流回正时间
        irr_lx.现金流回正时长立项版 AS [现金流回正时长_立项版],          -- 立项版现金流回正时长
        irr_lx.动态全投资现金流回正 AS [现金流回正时间_动态版],          -- 动态版现金流回正时间
        irr_lx.现金流回正时长动态版 AS [现金流回正时长_动态版],          -- 动态版现金流回正时长
        xjl.累计经营性现金流 AS [截止目前经营性现金流余额],             -- 截止目前经营性现金流余额
        tb.[股东投资峰值_立项版] AS [股东投资峰值_立项版],              -- 股东投资峰值_立项版
        tb.[股东投资峰值_动态版] AS [股东投资峰值_动态版],              -- 股东投资峰值_动态版
        tb.[机会成本损失] AS [机会成本损失],                          -- 机会成本损失
        tb.[机会成本损失对应单方成本] AS [机会成本损失对应单方成本],      -- 机会成本损失对应单方成本
        irr_lx.项目获取时间 AS [项目获取日期]
    FROM data_wide_dws_mdm_Project p
        LEFT JOIN #FullIRR_dt irr_dt ON irr_dt.ProjGUID = p.projguid
        LEFT JOIN #FullIRR_lx irr_lx ON irr_lx.项目GUID = p.projguid
        LEFT JOIN #JyjhtjkbTb tb ON tb.项目GUID = p.projguid
        LEFT JOIN #xjl xjl ON xjl.projguid = p.projguid
    WHERE p.level = 2; -- 只统计二级项目

    /**************************************************************
    * 8. 查询当天插入的最终数据，便于校验
    ***************************************************************/
    SELECT
        [buguid],
        [projguid],
        [清洗日期],
        [全投资IRR_动态版],
        [全投资IRR_立项版],
        [现金流回正时间_立项版],
        [现金流回正时长_立项版],
        [现金流回正时间_动态版],
        [现金流回正时长_动态版],
        [截止目前经营性现金流余额],
        [股东投资峰值_立项版],
        [股东投资峰值_动态版],
        [机会成本损失],
        [机会成本损失对应单方成本],
        [项目获取日期]
    FROM zb_jyjhtjkb_CashFlow
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    /**************************************************************
    * 9. 删除临时表，释放资源
    ***************************************************************/
    DROP TABLE #FullIRR_dt;
    DROP TABLE #FullIRR_lx;
    DROP TABLE #JyjhtjkbTb;
    DROP TABLE #xjl;

END



SELECT
    [buguid],
    [projguid],
    [清洗日期],
    [项目获取日期],
    isnull(lczy.[全投资IRR-动态版], cf.[全投资IRR_动态版] ) as  [全投资IRR_动态版],
    [全投资IRR_立项版],
    CASE 
        WHEN [全投资IRR_立项版] IS NOT NULL 
             AND isnull(lczy.[全投资IRR-动态版], cf.[全投资IRR_动态版] ) IS NOT NULL
        THEN  isnull(lczy.[全投资IRR-动态版], cf.[全投资IRR_动态版] ) - ISNULL([全投资IRR_立项版], 0) 
    END AS [全投资IRR偏差],
    CONVERT(VARCHAR(10), [现金流回正时间_立项版], 121) AS [现金流回正时间_立项版],
    CONVERT(VARCHAR(10),  isnull(lczy.[现金流回正时间-动态版], cf.[现金流回正时间_动态版] ), 121) AS [现金流回正时间_动态版],
    [现金流回正时长_立项版],
    -- isnull(lczy.[现金流回正时长-动态版], cf.[现金流回正时长_动态版] ) as [现金流回正时长_动态版],
    datediff(month,cf.[项目获取日期],isnull(lczy.[现金流回正时间-动态版],cf.[现金流回正时间_立项版])) as [现金流回正时长_动态版],
    CASE 
        WHEN [现金流回正时长_立项版] IS NOT NULL 
             AND datediff(month,cf.[项目获取日期],isnull(lczy.[现金流回正时间-动态版],cf.[现金流回正时间_立项版]))  IS NOT NULL
        THEN datediff(month,cf.[项目获取日期],isnull(lczy.[现金流回正时间-动态版],cf.[现金流回正时间_立项版])) - ISNULL([现金流回正时长_立项版], 0)    
    END AS [现金流回正时长偏差],
    [截止目前经营性现金流余额],
    [股东投资峰值_立项版],
    [股东投资峰值_动态版],
    CASE 
        WHEN [股东投资峰值_立项版] IS NOT NULL 
             AND [股东投资峰值_动态版] IS NOT NULL
        THEN ISNULL([股东投资峰值_动态版], 0) -ISNULL([股东投资峰值_立项版], 0) 
    END AS [股东投资峰值偏差],
    [机会成本损失],
    [机会成本损失对应单方成本]
FROM
    zb_jyjhtjkb_CashFlow cf
    left join  data_tb_ylss_lczy lczy on cf.projguid =lczy.项目GUID
WHERE
    DATEDIFF(DAY, [清洗日期], ${qxDate} ) = 0

-- -- data_tb_ylss_lczy


-- 住宅总货值金额
-- 车位总货值金额
-- 总货值-动态版
-- 除地价外直投本月拍照版
-- 除地价外直投可售单方成本-动态版
-- 财务费用(单利)截止本月
-- 营销费用-动态版
-- 管理费用-动态版
-- 总投资-动态版
-- 增值税及附加-动态版
-- 税前成本利润率-动态版
-- 税前利润-动态版
-- 销售净利率-动态版
-- 税后利润-动态版
-- 税后现金利润-动态版
-- 全投资IRR-动态版
-- 现金流回正时间-动态版
-- 现金流回正时长-动态版