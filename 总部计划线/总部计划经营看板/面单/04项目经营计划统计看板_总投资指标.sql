USE [HighData_prod]
GO

-- 2025-09-20 chenjw 用于总部计划经营看板的 总投资指标存储过程

CREATE  or  ALTER   PROC [dbo].[usp_zb_jyjhtjkb_TotalInvestment]
AS
BEGIN
    ----------------------------------------------------------------------
    -- 1. 创建总投资指标表（如表已存在，实际应先判断并删除或跳过，此处为示例）
    ----------------------------------------------------------------------
    -- CREATE TABLE zb_jyjhtjkb_TotalInvestment
    -- (
    --     [buguid] UNIQUEIDENTIFIER,                          -- 组织GUID
    --     [projguid] UNIQUEIDENTIFIER,                        -- 项目GUID
    --     [清洗日期] DATETIME,                                 -- 清洗日期

    --     -- 投资相关字段
    --     [除地价外直投本月拍照版] DECIMAL(32, 10),             -- 本月直投（不含地价）
    --     [除地价外直投上月拍照版] DECIMAL(32, 10),             -- 上月直投（不含地价）
    --     [除地价外直投_立项版] DECIMAL(32, 10),                -- 立项版直投（不含地价）

    --     [开发前期费用本月拍照版] DECIMAL(32, 10),             -- 本月开发前期费用
    --     [建筑安装工程费本月拍照版] DECIMAL(32, 10),           -- 本月建筑安装工程费
    --     [红线内配套费本月拍照版] DECIMAL(32, 10),             -- 本月红线内配套费
    --     [政府收费及不可预见费本月拍照版] DECIMAL(32, 10),     -- 本月政府收费及不可预见费

    --     [开发前期费用_立项版] DECIMAL(32, 10),                -- 立项版开发前期费用
    --     [建筑安装工程费_立项版] DECIMAL(32, 10),              -- 立项版建筑安装工程费
    --     [红线内配套费_立项版] DECIMAL(32, 10),                -- 立项版红线内配套费

    --     -- 财务费用相关
    --     [财务费用(单利)_立项版] DECIMAL(32, 10),              -- 立项版财务费用（单利）Ww
    --     [财务费用(单利)截止本月] DECIMAL(32, 10),             -- 截止本月财务费用（单利）
    --     [财务费用(复利)可售单方_截止本月] DECIMAL(32, 10),    -- 复利可售单方（截止本月）
    --     [财务费用(复利）_截止本月] DECIMAL(32, 10),           -- 复利（截止本月）
    --     [财务费用(复利）_截止上月] DECIMAL(32, 10),           -- 复利（截止上月）
    --     [应付未付股东借款利息] DECIMAL(32, 10),               -- 应付未付股东借款利息

    --     -- 费用相关
    --     [营销费用_动态版] DECIMAL(32, 10),                    -- 动态版营销费用
    --     [营销费用_立项版] DECIMAL(32, 10),                    -- 立项版营销费用
    --     [管理费用_动态版] DECIMAL(32, 10),                    -- 动态版管理费用
    --     [管理费用_立项版] DECIMAL(32, 10),                    -- 立项版管理费用

    --     -- 已发生相关
    --     [已发生总投资_动态版] DECIMAL(32, 10),                -- 动态版已发生总投资
    --     [已发生除地价外直投] DECIMAL(32, 10),                 -- 已发生除地价外直投
    --     [已发生财务费用（单利）] DECIMAL(32, 10),            -- 已发生财务费用（单利）
    --     [已发生产值] DECIMAL(32, 10),                         -- 已发生产值
    --     [已发生营销费用] DECIMAL(32, 10),                     -- 已发生营销费用
    --     [已发生管理费用] DECIMAL(32, 10),                     -- 已发生管理费用
    --     [总投资_立项版] DECIMAL(32, 10),                      -- 立项版总投资

    --     -- 税金相关
    --     [已发生增值税及附加-动态版] DECIMAL(32, 10),          -- 已发生增值税及附加（动态版）
    --     [待发生增值税及附加-动态版] DECIMAL(32, 10)           -- 待发生增值税及附加（动态版）
    -- )

    ----------------------------------------------------------------------
    -- 2. 删除当天已存在的数据，避免重复插入
    ----------------------------------------------------------------------
    DELETE FROM zb_jyjhtjkb_TotalInvestment
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    ----------------------------------------------------------------------
    -- 3. 汇总各项数据，插入总投资指标表
    --    说明：此处仅为结构示例，实际业务数据需补充
    ----------------------------------------------------------------------
    select *
    into #cbbb 
    from (
        
        select 
            projguid,
            CurVersion as CurVersion,
            CreateUserName,
            convert(varchar(6),ReviewDate,112) as RecollectDate,
            ApproveState,
            ROW_NUMBER() over(PARTITION by projguid 
                order by 
                    px asc,
                    convert(varchar(6),ReviewDate,112) desc) as rn    --判断是自动拍照还是手工审核
        from (
            --1、最近一次动态成本回顾（有审批记录）
            select 
                ProjectGUID as projguid,
                CurVersion,
                CreateUserName,
                RecollectDate as ReviewDate,
                ApproveState,
                1 as px
            from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCostRecollect
            where ApproveState ='已审核' 
            group by ProjectGUID,
                CurVersion,
                CreateUserName,
                RecollectDate,
                ApproveState   
            --2、最近一次动态成本补录（有审批记录）  
            union all       
            select 
                t.ProjectGUID,
                t.CurVersion,
                t.CreateUserName,
                t.RecollectDate,
                t.ApproveState,
                2 as px
            from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollect t
            where t.ApproveState = '已审核'
            group by 
                t.ProjectGUID,
                t.CurVersion,
                t.CreateUserName,
                t.RecollectDate,
                t.ApproveState
            union all 
            --3、最近一次动态成本回顾（自动拍照）
            select 
                ProjectGUID,
                CurVersion,
                CreateUserName,
                RecollectDate,
                ApproveState,
                3 as px
            from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCostRecollect
            where ApproveState <>'已审核'
                and CreateUserName = '系统管理员'
            group by ProjectGUID,
                CurVersion,
                CreateUserName,
                RecollectDate,
                ApproveState        
            --4、最近一次动态成本补录（自动拍照）
            union all       
            select 
                t.ProjectGUID,
                t.CurVersion,
                t.CreateUserName,
                t.RecollectDate,
                t.ApproveState,
                4 as px
            from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollect t
            where t.ApproveState <> '已审核'
                and t.CreateUserName = '系统管理员'
            group by 
                t.ProjectGUID,
                t.CurVersion,
                t.CreateUserName,
                t.RecollectDate,
                t.ApproveState
        ) t
    ) t where t.rn in (1, 2);

    --取动态成本回顾手工审核版
    select 
        t.projguid,
        CurVersion,
        版本,
        rn,
        sum(t.总投资) as 总投资,
        sum(t.最新动态成本) as 最新动态成本,
        sum(t.最新动态成本含税) as 最新动态成本含税,
        SUM(t.开发前期费用) as 开发前期费用,
        SUM(t.建筑安装工程费) as 建筑安装工程费,
        SUM(t.红线内配套费) as 红线内配套费,
        SUM(t.政府收费及不可预见费) as 政府收费及不可预见费
    into #cb
    from (
        select 
            t.projguid,
            t.CurVersion,'回顾版：'+t.CurVersion as 版本,
            bb.rn,
            sum(case when t.AccountCode = '5001' then isnull(CurDynamicCostNonTax_fxj,0) else 0 end) as 总投资,
            sum(case when t.AccountCode = '5001' then isnull(CurDynamicCostNonTax_fxj
            ,0) else 0 end)-
            sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCostNonTax_fxj
            ,0) else 0 end)  as 最新动态成本,
            sum(case when t.AccountCode = '5001.02' then isnull(CurDynamicCostNonTax_fxj,0) else 0 end) as 开发前期费用,
            sum(case when t.AccountCode = '5001.03' then isnull(CurDynamicCostNonTax_fxj,0) else 0 end) as 建筑安装工程费,
            sum(case when t.AccountCode = '5001.04' then isnull(CurDynamicCostNonTax_fxj,0) else 0 end) as 红线内配套费,
            sum(case when t.AccountCode IN ('5001.05','5001.08') then isnull(t.CurDynamicCostNonTax_fxj,0) else 0 end) as 政府收费及不可预见费,
            sum(case when t.AccountCode = '5001' then isnull(CurDynamicCost_fxj
            ,0) else 0 end)-
            sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCost_fxj
            ,0) else 0 end)  as 最新动态成本含税
        from highdata_prod.dbo.data_wide_cb_MonthlyReview t 
        inner join #cbbb bb on t.CurVersion = bb.CurVersion and t.projguid = bb.projguid 
        --where t.AccountCode in ('5001','5001.10','5001.09','5001.11','5001.01')
        --and t.CreateUserName <> '系统管理员'
        group by t.projguid,t.CurVersion,bb.rn
    )t 
    group by t.projguid,CurVersion,版本,rn
	
    -- 填报数据
    SELECT 
        jytb.项目GUID,
        jytb.财务费用_复利_一盘一策版
    INTO #JyjhtjkbTb
    FROM data_wide_dws_qt_Jyjhtjkb jytb
    WHERE jytb.FillHistoryGUID IN (
        SELECT TOP 1 FillHistoryGUID
        FROM data_wide_dws_qt_Jyjhtjkb
        ORDER BY FillDate DESC
    )

select 
    f076.项目GUID, 
    f076.立项除地价外直投 as [除地价外直投-一盘一策版],
    null as  [土地费用-一盘一策版],
    f076.财务费用计划口径 as [财务费用(单利)-一盘一策版],
    f076.营销费用 as [营销费用-一盘一策版],
    f076.立项管理费用 as [管理费用-一盘一策版]
INTO #f076
FROM data_wide_dws_qt_nmap_s_F076项目运营情况跟进表 f076
INNER JOIN data_wide_dws_mdm_Project p ON f076.项目GUID = p.projguid AND p.level = 2
WHERE versionguid IN (
    SELECT TOP 1 versionguid
    FROM data_wide_dws_qt_nmap_s_F076项目运营情况跟进表
    ORDER BY EndTime DESC)

    --手工补录版
    insert into #cb
    select t.projguid,
        t.CurVersion,
        t.版本,
        t.rn,
        sum(t.总投资) as 总投资,
        sum(t.动态成本) as 最新动态成本,
        sum(t.动态成本含税) as 最新动态成本含税,
        SUM(t.开发前期费用) as 开发前期费用,
        SUM(t.建筑安装工程费) as 建筑安装工程费,
        SUM(t.红线内配套费) as 红线内配套费,
        SUM(t.政府收费及不可预见费) as 政府收费及不可预见费
    from (
        select 
            t.ProjectGUID as projguid,
            t.CurVersion,'补录版：'+t.CurVersion as 版本,
            bb.rn,
            sum(case when dtl.CostCode = '5001' then isnull(dtl.NoTaxAmount,0) else 0 end) as 总投资,
            sum(case when dtl.CostCode = '5001' then isnull(dtl.NoTaxAmount,0) else 0 end)-
            sum(case when dtl.CostCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(dtl.NoTaxAmount,0) else 0 end) as 动态成本,
            sum(case when dtl.CostCode = '5001.02' then isnull(dtl.NoTaxAmount,0) else 0 end) as 开发前期费用,
            sum(case when dtl.CostCode = '5001.03' then isnull(dtl.NoTaxAmount,0) else 0 end) as 建筑安装工程费,
            sum(case when dtl.CostCode = '5001.04' then isnull(dtl.NoTaxAmount,0) else 0 end) as 红线内配套费,
            sum(case when dtl.CostCode IN ('5001.05','5001.08') then isnull(dtl.NoTaxAmount,0) else 0 end) as 政府收费及不可预见费,
            sum(case when dtl.CostCode = '5001' then isnull(dtl.amount,0) else 0 end)-
            sum(case when dtl.CostCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(dtl.amount,0) else 0 end) as 动态成本含税
        from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollect t
        inner join [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollectDtl dtl on t.RecollectGUID = dtl.RecollectGUID
        inner join #cbbb bb on t.CurVersion = bb.CurVersion and t.ProjectGUID = bb.projguid 
        --inner join #cbbb_manu bb on t.CurVersion = bb.CurVersion and t.ProjectGUID = bb.ProjectGUID
        group by t.ProjectGUID,t.CurVersion,bb.rn
    ) t 
    group by t.projguid,t.CurVersion,t.rn,t.版本

    INSERT INTO zb_jyjhtjkb_TotalInvestment (
        [buguid],
        [projguid],
        [清洗日期],
        [除地价外直投本月拍照版],
        [除地价外直投上月拍照版],
        [除地价外直投_立项版],
        [开发前期费用本月拍照版],
        [建筑安装工程费本月拍照版],
        [红线内配套费本月拍照版],
        [政府收费及不可预见费本月拍照版],
        [开发前期费用_立项版],
        [建筑安装工程费_立项版],
        [红线内配套费_立项版],
        [政府收费及不可预见费_立项版],
        [财务费用(单利)_立项版],
        [财务费用(单利)截止本月],
        [财务费用(复利)可售单方_截止本月],
        [财务费用(复利）_截止本月],
        [财务费用(复利）_截止上月],

        [财务费用(复利)-立项版] ,
        [财务费用(复利)可售单方-立项版] ,
        [财务费用(单利)可售单方_截止本月], 

        [应付未付股东借款利息],
        [营销费用_动态版],
        [营销费用_立项版],
        [管理费用_动态版],
        [管理费用_立项版],
        [已发生总投资_动态版],
        [已发生除地价外直投],
        [已发生财务费用（单利）],
        [已发生产值],
        [已发生营销费用],
        [已发生管理费用],
        [总投资_动态版],
        [总投资_立项版],
        [已发生增值税及附加-动态版],
        [待发生增值税及附加-动态版],
        [增值税及附加_立项版],
        [增值税及附加_动态版],
        [除地价外直投-一盘一策版],
        [土地费用-一盘一策版],
        [财务费用(单利)-一盘一策版],
        [财务费用(复利)-一盘一策版],
        [营销费用-一盘一策版],
        [管理费用-一盘一策版],
        [总投资-一盘一策版],
        [增值税及附加-一盘一策版],
        [已发生土地费用],
        [已支付土地费用],
        [待发生土地费用]
    )
    SELECT
        p.buguid AS [buguid],                -- 事业部GUID
        p.projguid AS [projguid],            -- 项目GUID
        GETDATE() AS [清洗日期],             -- 当前清洗日期

        -- 以下字段实际应为业务汇总结果，此处全部为NULL占位
        cbpz.除地价外直投本月拍照版 AS [除地价外直投本月拍照版],
        cbpz.除地价外直投上月拍照版 AS [除地价外直投上月拍照版],
        f076.立项除地价外直投 AS [除地价外直投_立项版],
        cbpz.开发前期费用本月拍照版 AS [开发前期费用本月拍照版],
        cbpz.建筑安装工程费本月拍照版 AS [建筑安装工程费本月拍照版],
        cbpz.红线内配套费本月拍照版 AS [红线内配套费本月拍照版],
        cbpz.政府收费及不可预见费本月拍照版 AS [政府收费及不可预见费本月拍照版],
        NULL AS [开发前期费用_立项版],
        NULL AS [建筑安装工程费_立项版],
        NULL AS [红线内配套费_立项版],
        NULL AS [政府收费及不可预见费_立项版],
        lx.财务费用_立项版 AS [财务费用(单利)_立项版],
        -- [财务费用(单利)_立项版] --- 需要填报
        f076.财务费用计划口径 AS [财务费用(单利)截止本月],
        jytb.财务费用_复利_可售单方_截止本月   AS [财务费用(复利)可售单方_截止本月],
        jytb.财务费用_复利_截止本月 AS [财务费用(复利）_截止本月],
        jytb.财务费用_复利_截止上月 AS [财务费用(复利）_截止上月],

        jytb.[财务费用_复利_立项版] ,
        jytb.[财务费用_复利_可售单方_立项版] ,
        jytb.[财务费用_单利_可售单方_截止本月], 

        NULL AS [应付未付股东借款利息], -- 取数口径不清楚
        yxfy.预算金额 AS [营销费用_动态版],
        lx.营销费用_立项版 AS [营销费用_立项版],
        ylgh.综合管理费协议口径_账面口径/100000000 AS [管理费用_动态版],
        lx.管理费用_立项版 AS [管理费用_立项版],
        yfs.YfsZtzCost AS [已发生总投资_动态版],
        yfs.YfsCost AS [已发生除地价外直投],
        jytb.[已发生财务费用_单利] AS [已发生财务费用（单利）],
        cz.已发生产值_亿 AS [已发生产值],
        yxfy.已发生费用 AS [已发生营销费用],
        NULL AS [已发生管理费用], -- 取数口径有疑问
        cbpz.总投资 AS [总投资_动态版],
        lx.总投资含税_收益表 AS [总投资_立项版],
        NULL AS [已发生增值税及附加-动态版], -- 可以取数
        NULL AS [待发生增值税及附加-动态版],
        lx.立项增值税及附加 AS [增值税及附加_立项版],
        ylgh.增值税下附加税/100000000 AS [增值税及附加_动态版],
        f076.除地价外直投含税 as [除地价外直投-一盘一策版],
        f076.土地费用 as [土地费用-一盘一策版],
        f076.财务费用计划口径 as [财务费用(单利)-一盘一策版],
        jb.财务费用_复利_一盘一策版 as [财务费用(复利)-一盘一策版],
        f076.营销费用 as [营销费用-一盘一策版],
        f076.综合管理费协议口径 as [管理费用-一盘一策版],
        f076.总成本含税计划口径 as [总投资-一盘一策版],
        ylgh.增值税下附加税/100000000 as [增值税及附加-一盘一策版],
        td.LandCostTotal as [已发生土地费用],
        td.LandCostTotal as [已支付土地费用],
        isnull(f076.土地费用,0) - isnull(td.LandCostTotal,0) as [待发生土地费用]
    FROM data_wide_dws_mdm_Project p
    LEFT JOIN (
        select p.ParentGUID,
                sum(case when t.rn = 1 then t.总投资 end)/100000000 as 总投资,
                sum(case when t.rn = 1 then t.最新动态成本 end)/100000000 as 除地价外直投本月拍照版,
                sum(case when t.rn = 2 then t.最新动态成本 end)/100000000 as 除地价外直投上月拍照版,
                sum(case when t.rn = 1 then t.开发前期费用 end)/100000000 as 开发前期费用本月拍照版,
                sum(case when t.rn = 1 then t.建筑安装工程费 end)/100000000 as 建筑安装工程费本月拍照版,
                sum(case when t.rn = 1 then t.红线内配套费 end)/100000000 as 红线内配套费本月拍照版,
                sum(case when t.rn = 1 then t.政府收费及不可预见费 end)/100000000 as 政府收费及不可预见费本月拍照版
        from #cb t
        left join data_wide_dws_mdm_Project p on t.projguid = p.projguid
        group by p.ParentGUID
    ) cbpz on cbpz.ParentGUID = p.projguid
    LEFT JOIN (
          SELECT 
            f076.项目GUID,                                   -- 项目GUID
            f076.立项除地价外直投,
            f076.除地价外直投含税,
            f076.总成本含税计划口径,
            isnull(f076.总成本含税计划口径,0) - isnull(f076.除地价外直投含税,0) - isnull(f076.财务费用计划口径,0) - isnull(f076.营销费用,0) 
              - isnull(f076.综合管理费协议口径,0) as 土地费用,
            f076.财务费用计划口径,
            f076.营销费用,
            f076.综合管理费协议口径
        FROM data_wide_dws_qt_nmap_s_F076项目运营情况跟进表 f076
        INNER JOIN data_wide_dws_mdm_Project p ON f076.项目GUID = p.projguid AND p.level = 2
        WHERE versionguid IN (
            SELECT TOP 1 versionguid
            FROM data_wide_dws_qt_nmap_s_F076项目运营情况跟进表
            ORDER BY EndTime DESC
        )
    ) f076 on f076.项目GUID = p.projguid
    left join (
        SELECT 
        ProjGUID,
        projname,
        LandCostTotal/10000 as LandCostTotal  
    FROM data_wide_dws_ys_ys_DssCashFlowData
    WHERE isbase = 1
    ) td on td.ProjGUID = p.projguid
    LEFT JOIN (
        SELECT  
            t.projguid,                                       -- 项目GUID
            t.CwExpenses /100000000   as 财务费用_立项版,
            t.YxExpenses/100000000 AS 营销费用_立项版,
            t.GlExpenses/100000000 AS 管理费用_立项版,
            t.TotalInvestmentTax/100000000 AS 总投资含税_收益表,
            t.UnderVATSurcharge/100000000 立项增值税及附加 
        FROM data_wide_dws_ys_SumOperatingProfitDataLXDWBfYt t
        WHERE EditonType = '立项版'
    ) lx on lx.projguid = p.projguid
    LEFT JOIN (
        SELECT 
            jytb.项目GUID,
            jytb.财务费用_复利_截止本月,
            jytb.财务费用_复利_截止上月,
            jytb.[财务费用_复利_立项版] ,
            jytb.[财务费用_复利_可售单方_截止本月], 
            jytb.[财务费用_复利_可售单方_立项版] ,
            jytb.[财务费用_单利_可售单方_截止本月],
            jytb.[已发生财务费用_单利]
        FROM data_wide_dws_qt_Jyjhtjkb jytb
        WHERE jytb.FillHistoryGUID IN (
            SELECT TOP 1 FillHistoryGUID
            FROM data_wide_dws_qt_Jyjhtjkb
            ORDER BY FillDate DESC
        )
    ) jytb  ON jytb.项目GUID = p.projguid
    LEFT JOIN (
        select 
            a.BUGUID,
            bu.BUName,
            a.ProjGUID,
            p.ProjName,
            sum(b.PlanAmount)/100000000	预算金额,
            sum(b.OccurredAmount)/100000000	已发生费用
        from [172.16.4.141].MyCost_Erp352.dbo.ys_OverAllPlan a 
        INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.ys_OverAllPlanDtl b ON a.OverAllPlanGUID = b.OverAllPlanGUID
        INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.p_Project p ON p.ProjGUID = a.ProjGUID
        left join [172.16.4.141].MyCost_Erp352.dbo.myBusinessUnit bu on bu.BUGUID = a.BUGUID
        where    PlanDate ='0' 
            and b.CostCode  in ('C.01.001-营销类','C.01.002-客服类')
            and b.isendCost = 1
        group by a.BUGUID,
            bu.BUName,
            a.ProjGUID,
            p.ProjName
    ) yxfy on yxfy.ProjGUID = p.projguid
    left join dw_f_TopProJect_ProfitCost_ylgh ylgh on ylgh.项目guid = p.projguid
    left join (
        select ParentGUID,
            sum(case when AccountCode not in ('5001.01','5001.09','5001.11','5001.10') then YfsCost end)/100000000 as YfsCost,
            sum(YfsCost)/100000000 as YfsZtzCost
        from data_wide_cb_CostAccount 
        where  AccountLevel = 2 
        group by ParentGUID
    ) yfs on yfs.ParentGUID = p.projguid
    left join (
        select 项目GUID,sum(已发生产值) as 已发生产值_亿 
        from data_wide_dws_cb_cxf 
        group by 项目GUID
    ) cz on cz.项目GUID = p.projguid
        LEFT JOIN #JyjhtjkbTb jb  
            ON jb.项目GUID = p.projguid
    WHERE p.level = 2; -- 只统计二级项目

    ----------------------------------------------------------------------
    -- 4. 查询当天插入的最终数据，便于校验
    ----------------------------------------------------------------------
    SELECT
        [buguid],
        [projguid],
        [清洗日期],
        除地价外直投本月拍照版,
        除地价外直投上月拍照版,
        除地价外直投_立项版,
        [开发前期费用本月拍照版],
        [建筑安装工程费本月拍照版],
        [红线内配套费本月拍照版],
        [政府收费及不可预见费本月拍照版],
        [开发前期费用_立项版],
        [建筑安装工程费_立项版],
        [红线内配套费_立项版],
        [政府收费及不可预见费_立项版],
        [财务费用(单利)_立项版],
        [财务费用(单利)截止本月],
        [财务费用(复利)可售单方_截止本月],
        [财务费用(复利）_截止本月],
        [财务费用(复利）_截止上月],
        [应付未付股东借款利息],
        [营销费用_动态版],
        [营销费用_立项版],
        [管理费用_动态版],
        [管理费用_立项版],
        [已发生总投资_动态版],
        [已发生除地价外直投],
        [已发生财务费用（单利）],
        [已发生产值],
        [已发生营销费用],
        [已发生管理费用],
        [总投资_动态版],
        [总投资_立项版],
        [已发生增值税及附加-动态版],
        [待发生增值税及附加-动态版],
        [增值税及附加_立项版],
        [增值税及附加_动态版],
        [除地价外直投-一盘一策版],
        [土地费用-一盘一策版],
        [财务费用(单利)-一盘一策版],
        [财务费用(复利)-一盘一策版],
        [营销费用-一盘一策版],
        [管理费用-一盘一策版],
        [总投资-一盘一策版],
        [增值税及附加-一盘一策版],
        [已发生土地费用],
        [已支付土地费用],
        [待发生土地费用]
    FROM zb_jyjhtjkb_TotalInvestment
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    drop table #cbbb,#cb;
    ----------------------------------------------------------------------
    -- 5. 删除临时表（如有临时表可在此处清理）
    ----------------------------------------------------------------------
END



-- SELECT
--         [buguid],
--         [projguid],
--         [清洗日期],
--         isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] ) as [除地价外直投本月拍照版],
--         [除地价外直投上月拍照版],
--         [除地价外直投_立项版],
--         case when  [除地价外直投_立项版]  is not null  and isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] ) is not null then  
--              isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] )  - isnull([除地价外直投_立项版],0)  end as  [除地价外直投偏差],
--         case when   isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] ) is  not  null and [除地价外直投上月拍照版] is not null then
--              isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] ) - isnull([除地价外直投上月拍照版],0)  end as  [除地价外直投环比提降],
--         isnull(lczy.[开发前期费用本月拍照版],ti.[开发前期费用本月拍照版] ) as [开发前期费用本月拍照版],
--         isnull(lczy.[建筑安装工程费本月拍照版],ti.[建筑安装工程费本月拍照版] ) as [建筑安装工程费本月拍照版],
--         isnull(lczy.[红线内配套费本月拍照版],ti.[红线内配套费本月拍照版] ) as [红线内配套费本月拍照版],
--         isnull(lczy.[政府收费及不可预见费本月拍照版],ti.[政府收费及不可预见费本月拍照版] ) as [政府收费及不可预见费本月拍照版],
--         [开发前期费用_立项版],
--         ti.[建筑安装工程费_立项版]  as [建筑安装工程费_立项版],
--         [红线内配套费_立项版],
--         [财务费用(单利)_立项版],
--         [财务费用(复利)-立项版] as [财务费用(复利)_立项版],
--         case when  [财务费用(复利)-立项版] is  not null and  [财务费用(复利）_截止本月]  is not null 
--            then  isnull( [财务费用(复利）_截止本月],0) - isnull( [财务费用(复利)-立项版],0)   end   as [财务费用(复利)偏差],
--         isnull(lczy.[财务费用(单利)截止本月], ti.[财务费用(单利)截止本月] ) as [财务费用(单利)截止本月] ,
--         isnull(lczy.[财务费用(单利)可售单方-截止本月], ti.[财务费用(单利)可售单方_截止本月] ) as [财务费用(单利)可售单方_截止本月],
--         ti.[财务费用(复利)可售单方-立项版] as [财务费用(复利)可售单方_立项版],
--         [财务费用(复利)可售单方_截止本月],
--         0 as [财务费用(复利)可售单方偏差],
--         [财务费用(复利）_截止本月],
--         [财务费用(复利）_截止上月],
--         case when [财务费用(复利）_截止本月] is not null and [财务费用(复利）_截止上月] is not null then 
--            isnull([财务费用(复利）_截止本月] ,0)  - isnull([财务费用(复利）_截止上月],0 )   end  as   [财务费用(复利)环比提降], 
        
--         [应付未付股东借款利息],
--         [营销费用_动态版],
--         [营销费用_立项版],
--         [管理费用_动态版],
--         [管理费用_立项版],
--         isnull(lczy.[已发生总投资_动态版], ti.[已发生总投资_动态版]) as [已发生总投资_动态版],
--         isnull(lczy.[已发生除地价外直投], ti.[已发生除地价外直投]) as [已发生除地价外直投],
--         isnull(lczy.[已发生财务费用（单利）],ti.[已发生财务费用（单利）] ) as [已发生财务费用（单利）],
--         [已发生产值],
--         isnull(lczy.[已发生营销费用], ti.[已发生营销费用]) as [已发生营销费用],
--         isnull(lczy.[已发生管理费用], ti.[已发生管理费用]) as [已发生管理费用],
--         [总投资_立项版],
--         isnull(lczy.[已发生增值税及附加-动态版],ti.[已发生增值税及附加-动态版]) as [已发生增值税及附加-动态版],
--         isnull(lczy.[待发生增值税及附加-动态版],ti.[待发生增值税及附加-动态版]) as [待发生增值税及附加-动态版]
--     FROM zb_jyjhtjkb_TotalInvestment ti  
--     left join data_tb_ylss_lczy lczy on ti.projguid =lczy.项目GUID
--     WHERE DATEDIFF(DAY, [清洗日期], ${qxDate} ) = 0


