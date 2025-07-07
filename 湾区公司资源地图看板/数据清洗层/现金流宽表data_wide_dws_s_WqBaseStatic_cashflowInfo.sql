--缓存成本系统本月实付款情况
SELECT  cp.ContractGUID ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '01%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月地价支出 ,
        SUM(CASE WHEN cb.HtTypeCode NOT LIKE '01%' AND  cb.HtTypeCode NOT LIKE '09%' AND cb.HtTypeCode NOT LIKE '08%' AND   cb.HtTypeCode NOT LIKE '07%' THEN PayAmount
                 ELSE 0
            END) / 10000.0 AS 本月除地价外直投发生 ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '07%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月营销费支出 ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '08%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月管理费支出 ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '09%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月财务费支出
INTO    #confk
FROM    [172.16.4.141].MyCost_Erp352.dbo.cb_Pay cp
        INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.vcb_contract cb ON cp.ContractGUID = cb.ContractGUID
WHERE   DATEDIFF(mm, PayDate, GETDATE()) = 0
GROUP BY cp.ContractGUID;

--获取合同项目信息
SELECT  t.contractguid ,
        t.projguid ,
        ROW_NUMBER() OVER (PARTITION BY t.contractguid ORDER BY t.projguid) AS rn
INTO    #conproj
FROM(SELECT con.contractguid ,
            par.projguid
     FROM   #confk con
            INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.cb_contractproj cpj ON con.contractguid = cpj.contractguid
            INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.p_project pj ON pj.projguid = cpj.projguid
            INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.p_project par ON par.projcode = pj.parentcode
     GROUP BY con.contractguid ,
              par.projguid) t;

--按照项目数据来均分项目
SELECT  pj.projguid ,
        SUM(CONVERT(DECIMAL(16, 4), 本月地价支出 * 1.0 / rn.rn)) AS 本月地价支出 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月除地价外直投发生 * 1.0 / rn.rn)) AS 本月除地价外直投发生 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月营销费支出 * 1.0 / rn.rn)) AS 本月营销费支出 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月管理费支出 * 1.0 / rn.rn)) AS 本月管理费支出 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月财务费支出 * 1.0 / rn.rn)) AS 本月财务费支出
INTO    #byfk
FROM    #confk fk
        INNER JOIN #conproj pj ON pj.contractguid = fk.ContractGUID
        INNER JOIN(SELECT   contractguid, MAX(rn) AS rn FROM    #conproj GROUP BY contractguid) rn ON rn.contractguid = fk.ContractGUID
GROUP BY pj.projguid;

--缓存销售系统本月回笼情况
-- SELECT  TopProjGUID ,
--         SUM(ISNULL(hl.应退未退本月金额, 0) + ISNULL(hl.本月回笼金额认购, 0) + ISNULL(hl.本月回笼金额签约, 0) + ISNULL(hl.关闭交易本月退款金额, 0) + ISNULL(hl.本月特殊业绩关联房间, 0) + ISNULL(hl.本月特殊业绩未关联房间, 0)) AS 本月实际回笼全口径
-- INTO    #byhl
-- FROM    data_wide_dws_s_gsfkylbhzb hl
-- WHERE   DATEDIFF(DAY, qxDate, GETDATE()) = 0
-- GROUP BY TopProjGUID;

SELECT   TopProjGUID  ,
CASE WHEN MONTH(GETDATE()) = 1 THEN 本年实际回笼全口径 ELSE 本年实际回笼全口径 - 上个月本年实际回笼全口径 END AS 本月实际回笼全口径 
INTO    #byhl
FROM (SELECT TopProjGUID ,
       SUM(
       CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                + ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
       END) AS 本年实际回笼全口径 ,
       SUM(
       CASE WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                + ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
       END) AS 上个月本年实际回笼全口径 
FROM   data_wide_dws_s_gsfkylbhzb hl
GROUP BY TopProjGUID) t

-- 获取项目分期的动态成本直投及总投
SELECT  
        ParentProjGUID,
        ProjGUID ,
        -- SUM(CASE WHEN CostShortName = '项目总投资' THEN ISNULL(DynamicCost_hfxj, 0) ELSE 0 END) /10000.0 AS 总投含非现金,
        -- SUM(CASE WHEN CostShortName = '项目总投资' THEN ISNULL(DynamicCost, 0) ELSE 0 END) /10000.0 AS 总投不含非现金,

        SUM(CASE WHEN CostShortName = '土地款' THEN ISNULL(DynamicCost_hfxj, 0) ELSE 0 END) /10000.0 AS 土地款动态成本含非现金含税,
        SUM(CASE WHEN CostShortName = '土地款' THEN ISNULL(DynamicCost, 0) ELSE 0 END) /10000.0 AS 土地款动态成本不含非现金含税,

        SUM(CASE WHEN CostShortName = '项目总投资' THEN ISNULL(DynamicCost_hfxj, 0) ELSE 0 END) /10000.0
        - SUM(CASE WHEN CostShortName IN ('土地款', '营销费用', '管理费用', '财务费用') THEN ISNULL(DynamicCost_hfxj, 0) ELSE 0 END) /10000.0 AS 除地价直投含非现金含税
        -- SUM(CASE WHEN CostShortName = '项目总投资' THEN ISNULL(DynamicCost, 0) ELSE 0 END) /10000.0
        -- - SUM(CASE WHEN CostShortName IN ('土地款', '营销费用', '管理费用', '财务费用') THEN ISNULL(DynamicCost, 0) ELSE 0 END) /10000.0 AS 除地价直投不含非现金含税
into #qpDtCost_fq
FROM    data_wide_cb_ProjCostAccount c
WHERE   c.CostShortName IN ('土地款', '营销费用', '管理费用', '财务费用', '项目总投资')
GROUP BY ParentProjGUID,ProjGUID



--缓存F08表的数据
-- select  
-- F08.* 
-- into #f08
-- from  data_wide_qt_F080004 f08
-- inner join data_wide_dws_ys_ProjGUID pj on f08.实体分期 = pj.YLGHProjGUID and pj.isbase = 1 and pj.BusinessEdition = f08.版本
-- and pj.Level = 3
-- where CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0
-- AND F08.明细说明 = '总价' 


-- select 
--     yt.YLGHProjGUID,
--     sum(case when 综合维 = '合计' and 报表预测项目科目 = '总成本（含税，计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) /10000.0 [总成本含税计划口径], 
--     sum(case when 综合维 = '合计' and 报表预测项目科目 = '总成本（不含税，计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end)  /10000.0 [总成本不含税计划口径],
--     sum(case when 综合维 = '合计' and 报表预测项目科目 = '总成本（不含税，账面）' then convert(decimal(32,6),VALUE_STRING) else 0 end) /10000.0 [总成本不含税账面口径],
--     sum(case when 综合维 = '合计' and 报表预测项目科目 = '资本化利息' then convert(decimal(32,6),VALUE_STRING) else 0 end) /10000.0 [资本化利息], 
--     sum(case when 综合维 = '合计' and 报表预测项目科目 = '营销费用' then convert(decimal(32,6),VALUE_STRING) else 0 end) /10000.0 [营销费用], 
--     sum(case when 综合维 = '合计' and 报表预测项目科目 in ('土地增值税','增值税下附加税','营业税下营业税、附加税','其他税费','印花税') then convert(decimal(32,6),VALUE_STRING) else 0 end) /10000.0 [税金及附加],
--     sum(case when 综合维 = '合计' and 报表预测项目科目 = '综合管理费用-管控口径' then convert(decimal(32,6),VALUE_STRING) else 0 end) /10000.0 [综合管理费管控口径]
-- into #qpylgh_fq
-- from #f08 f08 
-- inner JOIN data_wide_dws_ys_projguid yt ON  f08.实体分期 = yt.YLGHProjGUID and yt.Level = 3  and yt.isbase = 1
-- left join data_wide_dws_ys_SumProjProductYt syt on syt.ProjGUID = f08.实体分期 and syt.IsBase = 1 and syt.YtName = f08.业态
-- left join (select HierarchyName,ParentName,rank() over(partition by HierarchyName order by ParentName desc) as rn from data_wide_mdm_ProductType) ty ON syt.ProductType = ty.HierarchyName and ty.rn = 1
-- where   len(yt.YLGHProjGUID)<=36
-- group by yt.YLGHProjGUID 


 -- 取盈利规划分期的土地款、除代价外直投数据
SELECT 
    projguid as 项目guid, 
    分期guid,
    土地款
INTO #qpylgh_fq_land_invest
FROM (
--     SELECT 
--         pj.projguid, 
--         pj.YLGHProjGUID AS 分期guid,
--        --  业态,
--         SUM(CASE 
--             WHEN 成本预测科目 IN ('国土出让金', '原始成本', '契税', '其它土地款', 
--                                    '土地转让金', '土地抵减税金', '股权溢价', '拆迁补偿费') 
--             THEN CONVERT(DECIMAL(32, 4), value_string) 
--             ELSE 0 
--         END) /10000.0 AS 土地款,
--         SUM(CONVERT(DECIMAL(16, 4), value_string)) AS 总成本,
--         SUM(CASE 
--             WHEN 成本预测科目 IN ('资本化利息') 
--             THEN CONVERT(DECIMAL(32, 4), value_string) 
--             ELSE 0 
--         END) /10000.0 AS 资本化利息,
--         SUM(CASE 
--             WHEN 成本预测科目 IN ('开发间接费') 
--             THEN CONVERT(DECIMAL(32, 4), value_string) 
--             ELSE 0 
--         END) /10000.0 AS 开发间接费
--     FROM HighData_prod.dbo.data_wide_qt_F030008 f03
--     INNER JOIN HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
--         ON f03.实体分期 = pj.YLGHProjGUID
--            AND pj.isbase = 1
--            AND pj.Level = 3
--            AND f03.版本 = pj.BusinessEdition
--     WHERE 明细说明 = '账务口径不含税总成本'  AND CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 
--     GROUP BY pj.projguid, pj.YLGHProjGUID

    SELECT 
        pj.projguid, 
        pj.YLGHProjGUID AS 分期guid,
       --  业态,
        SUM(CASE 
            WHEN 成本预测科目 IN ('国土出让金', '原始成本', '契税', '其它土地款', 
                                   '土地转让金', '土地抵减税金', '股权溢价', '拆迁补偿费') 
            THEN CONVERT(DECIMAL(32, 4), value_string) 
            ELSE 0 
        END) /10000.0 AS 土地款
    FROM HighData_prod.dbo.data_wide_qt_F030003 f03
    INNER JOIN HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f03.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
           AND f03.版本 = pj.BusinessEdition
    WHERE  CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 
    GROUP BY pj.projguid, pj.YLGHProjGUID
) t;

-- 获取盈利规划除地价外直投
-- select  * from  [dbo].[data_wide_qt_F03000102] where  实体分期 ='54965A5F-7EEA-4652-B914-4BAE6B17A63E' and 版本='202503版' and  明细说明='含税金额' and  综合维='动态成本'
-- and  业态='不区分业态'
-- 对应落盘中间表 F03000102 除地价直投科目
SELECT 
    projguid as 项目guid, 
    分期guid,
    除地价外直投含税
INTO #qpylgh_fq_zt
FROM (
    SELECT 
        pj.projguid, 
        pj.YLGHProjGUID AS 分期guid,
       --  业态,
        SUM(CASE 
            WHEN 成本预测科目 not in  ('国土出让金', '原始成本', '契税', '其它土地款', 
                                   '土地转让金', '土地抵减税金', '股权溢价', '拆迁补偿费', '开发间接费','资本化利息','销售、租赁代理费','综合管理费用') 
            THEN CONVERT(DECIMAL(32, 4), value_string) 
            ELSE 0 
        END) /10000.0 AS 除地价外直投含税
    FROM HighData_prod.dbo.data_wide_qt_F03000102 f0102
    INNER JOIN HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f0102.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
           AND f0102.版本 = pj.BusinessEdition
           and f0102.明细说明='含税金额'
           and f0102.综合维='动态成本'
           and f0102.业态='不区分业态'
    WHERE  CHARINDEX('e', ISNULL(f0102.VALUE_STRING, '0')) = 0  
    GROUP BY pj.projguid, pj.YLGHProjGUID
) t

-- 取盈利规划现金流表的管理费用科目
-- 管理费用（协议口径）在F040005 
SELECT 
    projguid, 
    分期guid,
    管理费用协议口径含税
INTO #qpylgh_fq_glfy
FROM (
    SELECT 
        pj.projguid, 
        pj.YLGHProjGUID AS 分期guid,
       --  业态,
        SUM(CASE 
            WHEN 费用科目 = '管理费用-协议口径（含税）'
            THEN CONVERT(DECIMAL(32, 4), value_string) 
            ELSE 0 
        END) /10000.0 AS 管理费用协议口径含税
    FROM HighData_prod.dbo.data_wide_qt_F040005 f040005
    INNER JOIN HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f040005.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
           AND f040005.版本 = pj.BusinessEdition
    WHERE  CHARINDEX('e', ISNULL(f040005.VALUE_STRING, '0')) = 0  
    GROUP BY pj.projguid, pj.YLGHProjGUID
) t


-- 如果动态成本分期的总成本没有数据则取盈利规划的总成本
-- 全盘的流出数据不对，无动态成本的分期没有取盈利规划数据（以5707汕尾金町湾三期为例）
select  a.ParentProjGUID as ProjGUID,
        -- sum(总投含非现金) as 总投含非现金,
        -- sum(总投不含非现金) as 总投不含非现金,
        -- sum( case when  isnull(土地款动态成本含非现金含税,0) =0  then  isnull(c.土地款,0) else 土地款动态成本含非现金含税 end   ) as 土地款动态成本含非现金含税,
        -- sum( case when  isnull(土地款动态成本不含非现金含税,0) =0  then  isnull(c.土地款,0) else 土地款动态成本不含非现金含税 end ) as 土地款动态成本不含非现金含税,
        sum( case when isnull(除地价直投含非现金含税,0) =0  then  isnull(d.除地价外直投含税,0) else  isnull(除地价直投含非现金含税,0)  end   ) as 除地价直投含非现金含税
        -- sum(case when isnull(除地价直投含非现金含税,0) =0  then  
        --   isnull(b.总成本含税计划口径,0) - isnull(c.土地款,0) - isnull(b.资本化利息,0)   -isnull(b.营销费用,0)  -isnull(b.税金及附加,0) - isnull(b.综合管理费管控口径,0)  
        -- else 除地价直投含非现金含税 end   ) as 除地价直投含非现金含税
into #qpDtCost     
from  #qpDtCost_fq a
-- left join #qpylgh_fq b on a.projguid =b.YLGHProjGUID
-- left join #qpylgh_fq_land_invest c on a.ProjGUID =c.分期guid -- 土地款
left join #qpylgh_fq_zt d on a.projguid = d.分期GUID  -- 除地价外直投
group by ParentProjGUID


-- 获取盈利规划 营销费用 管理费用 财务费用 税金
-- SELECT  项目guid,
--         SUM(ISNULL(资本化利息, 0)) /10000.0 AS 财务费用, -- 单位万元
--         SUM(ISNULL(营销费用, 0)) /10000.0 AS 营销费用,
--         SUM(ISNULL(税金及附加, 0)) /10000.0 AS 税金,
--         SUM(ISNULL(综合管理费管控口径, 0)) /10000.0 AS 管理费用
--         -- sum(isnull([总成本含税计划口径],0)) /10000.0 AS 总成本含税计划口径
-- INTO    #qpylgh
-- FROM    dw_f_TopProJect_ProfitCost_ylgh
-- GROUP BY 项目guid

-- 取盈利规划分期的总成本数据的股东借款利息、税金合计、营销费用、贷款利息数据
SELECT 
    projguid as 项目guid, 
    分期guid,
    股东借款利息,
    税金合计,
    营销费用,
    贷款利息
INTO #qpylgh_fq
FROM (
    SELECT 
        pj.projguid, 
        pj.YLGHProjGUID AS 分期guid,
       --  业态,
        SUM(CASE 
            WHEN 报表预测项目科目 = '股东借款利息'
            THEN CONVERT(DECIMAL(32, 4), value_string) 
            ELSE 0 
        END) /10000.0 AS 股东借款利息,
        SUM(CASE 
            WHEN 报表预测项目科目 in ('缴纳城建税及教育费附加','缴纳其他税费','缴纳企业所得税','缴纳土地增值税','缴纳印花税','缴纳营业税','缴纳增值税')
            THEN CONVERT(DECIMAL(32, 4), value_string) 
            ELSE 0 
        END) /10000.0 AS 税金合计,
        SUM(CASE 
            WHEN 报表预测项目科目 = '销售费用'
            THEN CONVERT(DECIMAL(32, 4), value_string) 
            ELSE 0 
        END) /10000.0 AS 营销费用,
        SUM(CASE 
            WHEN 报表预测项目科目 = '贷款利息'
            THEN CONVERT(DECIMAL(32, 4), value_string) 
            ELSE 0 
        END) /10000.0 AS 贷款利息
    FROM HighData_prod.dbo.data_wide_qt_F080005 f080005
    INNER JOIN HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f080005.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
           AND f080005.版本 = pj.BusinessEdition
    WHERE  CHARINDEX('e', ISNULL(f080005.VALUE_STRING, '0')) = 0  
    and f080005.报表预测项目科目 in ('股东借款利息','缴纳城建税及教育费附加','缴纳其他税费','缴纳企业所得税','缴纳土地增值税','缴纳印花税','缴纳营业税','缴纳增值税','销售费用','贷款利息')
    GROUP BY pj.projguid, pj.YLGHProjGUID
) t

select  a.项目guid,
        sum(isnull(b.土地款,0)) as 土地款动态成本含非现金含税,
        sum(isnull(a.营销费用,0))as 营销费用,
        sum(isnull(d.管理费用协议口径含税,0))as 管理费用,
        sum(isnull(a.股东借款利息,0) + isnull(a.贷款利息,0))as 财务费用,
        sum(isnull(a.税金合计,0))as 税金
into #qpylgh
from #qpylgh_fq a
left join #qpylgh_fq_land_invest b on a.分期GUID = b.分期guid
left join #qpylgh_fq_glfy d on a.分期GUID = d.分期guid
group by a.项目guid


-- 取明源系统项目的动态总货值
SELECT  组织架构id as 项目GUID,
        总货值金额 AS 动态总货值金额 -- 单位万元
into #qpdthz
FROM    [172.16.4.141].erp25.dbo.ydkb_dthz_wq_deal_salevalueinfo 
WHERE   组织架构类型 = 3 
        --and 组织架构id ='C66ED2CC-4166-E911-80B7-0A94EF7517DD'

--获取项目层级的现金流数据，并循环更新区域公司->公司的数据
SELECT  o.组织架构父级ID ,
        o.组织架构id ,
        o.组织架构名称 ,
        3 AS 组织架构类型 ,

        /* 统计全盘现金流数据*/
        isnull(dthz.动态总货值金额,0) as 全盘现金流入,
        isnull(ylgh.土地款动态成本含非现金含税,0) + isnull(dtcost.除地价直投含非现金含税,0)  + isnull(ylgh.营销费用,0) + isnull(ylgh.管理费用,0) + isnull(ylgh.财务费用,0) + isnull(ylgh.税金,0)  as 全盘现金流出 ,  --全盘地价支出+直投+三费+税金
        isnull(ylgh.土地款动态成本含非现金含税,0) AS 全盘地价支出 , --源动态成本土地款含非现金含税
        isnull(dtcost.除地价直投含非现金含税,0) AS 全盘除地价外直投发生 , -- 明源动态成本除地价外直投含非现金含税
        isnull(ylgh.营销费用,0) AS 全盘营销费用, -- 盈利规划系统 营销费用
        isnull(ylgh.管理费用,0) AS 全盘管理费用, -- 盈利规划系统 管理费协议口径 
        isnull(ylgh.财务费用,0) AS 全盘财务费用, -- 盈利规划系统 资本化利息
        isnull(ylgh.税金,0) AS 全盘税金, -- 盈利规划系统 税金及附加
        0 as 全盘贷款, -- 贷款 默认0

        /* 统计累计现金流数据  */
        --dss累计现金流+成本本月实时现金流
        xjl.累计经营性现金流 +(isnull(byhl.本月实际回笼全口径,0) - (isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) 
        + isnull(byfk.本月管理费支出,0) + isnull(byfk.本月财务费支出,0)))  AS 累计经营性现金流 ,
        isnull(xjl.累计回笼金额,0)+isnull(byhl.本月实际回笼全口径,0) AS 累计现金流入 ,
        
        isnull(xjl.累计直接投资土地费用,0) + isnull(xjl.累计建安费用,0) + isnull(sanf.累计营销费支出,0) + isnull(sanf.累计管理费支出,0) 
        + isnull(sanf.累计财务费支出,0) + isnull(xjl.累计税金,0)+
        isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) + isnull(byfk.本月管理费支出,0) 
        + isnull(byfk.本月财务费支出,0) AS 累计现金流出 ,
        isnull(xjl.累计直接投资土地费用,0)+isnull(byfk.本月地价支出,0) AS 累计地价支出 ,
        isnull(xjl.累计建安费用,0)+isnull(byfk.本月除地价外直投发生,0) AS 累计除地价外直投发生 ,
 
        isnull(sanf.累计营销费支出,0)+isnull(byfk.本月营销费支出,0) as 累计营销费支出,
        isnull(sanf.累计管理费支出,0)+isnull(byfk.本月管理费支出,0) as 累计管理费支出,
        isnull(sanf.累计财务费支出,0)+isnull(byfk.本月财务费支出,0) as  累计财务费支出,
        xjl.累计税金 AS 累计税金支出 ,
        --dss本年现金流+成本本月实时现金流
        xjl.本年经营性现金流+(isnull(byhl.本月实际回笼全口径,0) - (isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) 
        + isnull(byfk.本月管理费支出,0) + isnull(byfk.本月财务费支出,0))) AS 本年经营性现金流 ,
        tb.本年我司股东净投入 ,
        isnull(xjl.本年回笼金额,0)+isnull(byhl.本月实际回笼全口径,0) AS 本年现金流入 ,
        isnull(xjl.本年直接投资土地费用,0) + isnull(xjl.本年建安费用,0) + isnull(sanf.本年营销费支出,0) + isnull(sanf.本年管理费支出,0) 
        + isnull(sanf.本年财务费支出,0) + isnull(xjl.本年税金,0)+isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) + isnull(byfk.本月管理费支出,0) 
        + isnull(byfk.本月财务费支出,0) AS 本年现金流出 ,
        isnull(xjl.本年直接投资土地费用,0)+isnull(byfk.本月地价支出,0) AS 本年地价支出 ,
        isnull(xjl.本年建安费用,0)+isnull(byfk.本月除地价外直投发生,0) AS 本年除地价外直投发生 ,
        rw.ZtPlanTotal / 10000.0 AS 本年除地价外直投任务 ,
        qnrw.ZtPlanTotal / 10000.0 AS 去年除地价外直投任务 ,
        qnzt.YearJaInvestmentAmount AS 去年除地价外直投发生 ,
        byrw.ZtPlanTotal / 10000.0 AS 本月除地价外直投任务 ,
        byrw.PlanThreeInvestment / 10000.0 AS 本月三费任务 ,
        byrw.PlanTaxAmount / 10000.0 AS 本月税金任务 ,
        byrw.getLandAmount / 10000.0 AS 本月土地任务 ,
		byrw.LoanTaskAmount/ 10000.0 AS 本月贷款任务,
        isnull(sanf.本年营销费支出,0)+isnull(byfk.本月营销费支出,0) as 本年营销费支出,
        isnull(sanf.本年管理费支出,0)+isnull(byfk.本月管理费支出,0) as 本年管理费支出,
        isnull(sanf.本年财务费支出,0)+isnull(byfk.本月财务费支出,0) as 本年财务费支出,
        xjl.本年税金 AS 本年税金支出 ,
        rw.PlanInvestmentAmount / 10000.0 AS 本年拓展任务 ,
        rw.RealInvestmentAmount AS 本年实际拓展金额 ,
	    rw.LoanTaskAmount /  10000.0 AS 本年贷款任务,
        --本月情况要取成本的
        isnull(byhl.本月实际回笼全口径,0) - (isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) 
        + isnull(byfk.本月管理费支出,0) + isnull(byfk.本月财务费支出,0)) AS 本月经营性现金流 ,
        byhl.本月实际回笼全口径 AS 本月现金流入 ,
        isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) + isnull(byfk.本月管理费支出,0) 
        + isnull(byfk.本月财务费支出,0) AS 本月现金流出 ,
        byfk.本月地价支出 ,
        byfk.本月除地价外直投发生 ,
        byfk.本月营销费支出 ,
        byfk.本月管理费支出 ,
        byfk.本月财务费支出 ,
        0 AS 本月税金支出 ,                           --税金取不了，留空
        0 AS 本月贷款金额 ,                           --贷款金额取不了，留空
        isnull(byhl.本月实际回笼全口径,0)-(isnull(byfk.本月地价支出,0)+isnull(byfk.本月除地价外直投发生,0)+isnull(byfk.本月营销费支出,0)
        +isnull(byfk.本月管理费支出,0)+isnull(byfk.本月财务费支出,0)) AS 本月股东现金流 ,
        tb.保利方投入余额 我司资金占用 ,
        tb.账面可动用资金 ,
        tb.监控款余额 ,
        xjl.供应链融资余额 ,
        xjl.本年净增贷款 ,
        xjl.累计贷款余额 AS 贷款余额 ,
        isnull(xjl.累计股东投资回收金额,0)+(isnull(byhl.本月实际回笼全口径,0)-(isnull(byfk.本月地价支出,0)+isnull(byfk.本月除地价外直投发生,0)+isnull(byfk.本月营销费支出,0)
        +isnull(byfk.本月管理费支出,0)+isnull(byfk.本月财务费支出,0))) AS 累计股东现金流 ,
        isnull(xjl.本年股东投资回收金额,0)+(isnull(byhl.本月实际回笼全口径,0)-(isnull(byfk.本月地价支出,0)+isnull(byfk.本月除地价外直投发生,0)+isnull(byfk.本月营销费支出,0)
        +isnull(byfk.本月管理费支出,0)+isnull(byfk.本月财务费支出,0))) AS 本年股东现金流 ,
        tb.股东投入余额 ,
        tb.保利方投入余额 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.账面可动用资金 ELSE 0 END 账面可动用资金并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.监控款余额 ELSE 0 END 监控款余额并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN xjl.累计贷款余额 ELSE 0 END 贷款余额并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.保利方投入余额 ELSE 0 END 我司资金占用并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.股东投入余额 ELSE 0 END 股东投入余额并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN xjl.供应链融资余额 ELSE 0 END 供应链融资余额并表口径 ,
        rw.PlanCashFlowAmount / 10000.0 AS 本年经营性现金流目标 ,   --万元
        rw.ShareholdersInvestmentsTask / 10000.0 AS 本年股东投资现金流目标 ,
        byrw.PlanCashFlowAmount / 10000.0 AS 本月经营性现金流目标 , --万元
        byrw.ShareholdersInvestmentsTask / 10000.0 AS 本月股东投资现金流目标
INTO    #temp_result
FROM    data_wide_dws_s_WqBaseStatic_Organization o
        INNER JOIN data_wide_dws_mdm_project pj ON pj.projguid = o.组织架构id
        --获取现金流数据
        LEFT JOIN dw_f_TopProj_Filltab_Fact xjl ON o.组织架构id = xjl.项目guid
        --获取本年拓展、现金流任务数据
        LEFT JOIN data_wide_dws_s_SalesBudgetVerride rw ON rw.BudgetDimension = '年度' AND   rw.BudgetDimensionValue = YEAR(GETDATE()) AND   rw.OrganizationGUID = o.组织架构id
        --获取去年的直投任务
        LEFT JOIN data_wide_dws_s_SalesBudgetVerride qnrw ON qnrw.BudgetDimension = '年度' AND   qnrw.BudgetDimensionValue = YEAR(GETDATE()) - 1 AND qnrw.OrganizationGUID = o.组织架构id
        --获取本月的直投、三费、土地、税金、现金流任务
        LEFT JOIN data_wide_dws_s_SalesBudgetVerride byrw ON byrw.BudgetDimension = '月度' AND   byrw.BudgetDimensionValue = SUBSTRING(CONVERT(NVARCHAR(7), GETDATE(), 120), 1, 7)
                                                             AND   byrw.OrganizationGUID = o.组织架构id
        --获取去年的直投发生数
        LEFT JOIN(SELECT    ProjGUID ,
                            YearJaInvestmentAmount
                  FROM  data_wide_dws_ys_ys_DssCashFlowData
                  WHERE Year = YEAR(GETDATE()) - 1 AND month = 12) qnzt ON qnzt.projguid = o.组织架构id
        --获取三费
        LEFT JOIN(SELECT    组织架构id ,
                            本月营销费支出 ,
                            本月管理费支出 ,
                            本月财务费支出 ,
                            本年营销费支出 ,
                            本年管理费支出 ,
                            本年财务费支出 ,
                            累计营销费支出 ,
                            累计管理费支出 ,
                            累计财务费支出
                  FROM  [172.16.4.141].erp25.dbo.ydkb_dthz_wq_deal_cbinfo
                  WHERE 组织架构类型 = 3) sanf ON sanf.组织架构id = o.组织架构id
        --获取填报内容
        LEFT JOIN(SELECT    组织架构ID ,
                            我司资金占用 ,
                            本年我司股东净投入 ,
                            股东投入余额 ,
                            保利方投入余额 ,
                            账面可动用资金 ,
                            监控款余额
                  FROM  data_tb_WqBaseStatic_Projinfo) tb ON tb.组织架构id = o.组织架构id
        --获取本月回笼金额
        LEFT JOIN #byhl byhl ON byhl.topprojguid = o.组织架构id
        --获取本月实付款数据
        LEFT JOIN #byfk byfk ON byfk.projguid = o.组织架构id
        --获取项目动态成本直投及总投
        left join #qpDtCost dtcost On dtcost.projguid = o.组织架构id
        left join #qpylgh ylgh on ylgh.项目guid = o.组织架构id
        left join #qpdthz dthz on dthz.项目GUID =o.组织架构id
WHERE   o.组织架构类型 = 3;

--select  * from  #temp_result where 本月税金支出 is null 

--循环更新数据
DECLARE @baseinfo INT;

SET @baseinfo = 2;

WHILE(@baseinfo > 0)
    BEGIN
        INSERT INTO #temp_result
        SELECT  o.组织架构父级ID ,
                o.组织架构id ,
                o.组织架构名称,
                o.组织架构类型,
                sum(isnull(j.全盘现金流入,0)) as 全盘现金流入,
                sum(isnull(j.全盘现金流出,0)) as 全盘现金流出,
                sum(isnull(j.全盘地价支出,0)) as 全盘地价支出,
                sum(isnull(j.全盘除地价外直投发生,0)) as 全盘除地价外直投发生,
                sum(isnull(j.全盘营销费用,0)) as 全盘营销费用,
                sum(isnull(j.全盘管理费用,0)) as 全盘管理费用,
                sum(isnull(j.全盘财务费用,0)) as 全盘财务费用,
                sum(isnull(j.全盘税金,0)) as 全盘税金,
                sum(isnull(j.全盘贷款,0)) as 全盘贷款,

                SUM(isnull(j.累计经营性现金流,0)) AS 累计经营性现金流 ,
                SUM(isnull(j.累计现金流入,0)) AS 累计现金流入 ,
                SUM(isnull(j.累计现金流出,0)) AS 累计现金流出 ,
                SUM(isnull(j.累计地价支出,0)) AS 累计地价支出 ,
                SUM(isnull(j.累计除地价外直投发生,0)) AS 累计除地价外直投发生 ,
                SUM(isnull(j.累计营销费支出,0)) AS 累计营销费支出 ,
                SUM(isnull(j.累计管理费支出,0)) AS 累计管理费支出 ,
                SUM(isnull(j.累计财务费支出,0)) AS 累计财务费支出 ,
                SUM(isnull(j.累计税金支出,0)) AS 累计税金支出 ,
                SUM(isnull(j.本年经营性现金流,0)) AS 本年经营性现金流 ,
                SUM(isnull(j.本年我司股东净投入,0)) AS 本年我司股东净投入 ,
                SUM(isnull(j.本年现金流入,0)) AS 本年现金流入 ,
                SUM(isnull(j.本年现金流出,0)) AS 本年现金流出 ,
                SUM(isnull(j.本年地价支出,0)) AS 本年地价支出 ,
                SUM(isnull(j.本年除地价外直投发生,0)) AS 本年除地价外直投发生 ,
                SUM(isnull(j.本年除地价外直投任务,0)) AS 本年除地价外直投任务 ,
                SUM(isnull(j.去年除地价外直投任务,0)) AS 去年除地价外直投任务 ,
                SUM(isnull(j.去年除地价外直投发生,0)) AS 去年除地价外直投发生 ,
                SUM(isnull(j.本月除地价外直投任务,0)) AS 本月除地价外直投任务 ,
                SUM(isnull(j.本月三费任务,0)) AS 本月三费任务 ,
                SUM(isnull(j.本月税金任务,0)) AS 本月税金任务 ,
                SUM(isnull(j.本月土地任务,0)) AS 本月土地任务 ,
                SUM(isnull(j.本月贷款任务,0)) AS 本月贷款任务 ,
                SUM(isnull(j.本年营销费支出,0)) AS 本年营销费支出 ,
                SUM(isnull(j.本年管理费支出,0)) AS 本年管理费支出 ,
                SUM(isnull(j.本年财务费支出,0)) AS 本年财务费支出 ,
                SUM(isnull(j.本年税金支出,0)) AS 本年税金支出 ,
                SUM(isnull(j.本年拓展任务,0)) AS 本年拓展任务 ,
                SUM(isnull(j.本年实际拓展金额,0)) AS 本年实际拓展金额 ,
		        SUM(isnull(j.本年贷款任务,0)) AS 本年贷款任务,
                SUM(isnull(j.本月经营性现金流,0)) AS 本月经营性现金流 ,
                SUM(isnull(j.本月现金流入,0)) AS 本月现金流入 ,
                SUM(isnull(j.本月现金流出,0)) AS 本月现金流出 ,
                SUM(isnull(j.本月地价支出,0)) AS 本月地价支出 ,
                SUM(isnull(j.本月除地价外直投发生,0)) AS 本月除地价外直投发生 ,
                SUM(isnull(j.本月营销费支出,0)) AS 本月营销费支出 ,
                SUM(isnull(j.本月管理费支出,0)) AS 本月管理费支出 ,
                SUM(isnull(j.本月财务费支出,0)) AS 本月财务费支出 ,
                SUM(isnull(j.本月税金支出,0)) AS 本月税金支出 ,
                SUM(isnull(j.本月贷款金额,0)) AS 本月贷款金额 ,
                SUM(isnull(j.本月股东现金流,0)) AS 本月股东现金流 ,
                SUM(isnull(j.我司资金占用,0)) AS 我司资金占用 ,
                SUM(isnull(j.账面可动用资金,0)) AS 账面可动用资金 ,
                SUM(isnull(j.监控款余额,0)) AS 监控款余额 ,
                SUM(isnull(j.供应链融资余额,0)) AS 供应链融资余额 ,
                SUM(isnull(j.本年净增贷款,0)) AS 本年净增贷款 ,
                SUM(isnull(j.贷款余额,0)) AS 贷款余额 ,
                SUM(isnull(j.累计股东现金流,0)) AS 累计股东现金流 ,
                SUM(isnull(j.本年股东现金流,0)) AS 本年股东现金流 ,
                SUM(isnull(j.股东投入余额,0)) AS 股东投入余额 ,
                SUM(isnull(j.保利方投入余额,0)) AS 保利方投入余额 ,
                SUM(isnull(j.账面可动用资金并表口径,0)) AS 账面可动用资金并表口径 ,
                SUM(isnull(j.监控款余额并表口径,0)) AS 监控款余额并表口径 ,
                SUM(isnull(j.贷款余额并表口径,0)) AS 贷款余额并表口径 ,
                SUM(isnull(j.我司资金占用并表口径,0)) AS 我司资金占用并表口径 ,
                SUM(isnull(j.股东投入余额并表口径,0)) AS 股东投入余额并表口径 ,
                SUM(isnull(j.供应链融资余额并表口径,0)) AS 供应链融资余额并表口径 ,
                SUM(isnull(j.本年经营性现金流目标,0)) AS 本年经营性现金流目标 ,
                SUM(isnull(j.本年股东投资现金流目标,0)) AS 本年股东投资现金流目标 ,
                SUM(isnull(j.本月经营性现金流目标,0)) AS 本月经营性现金流目标 ,
                SUM(isnull(j.本月股东投资现金流目标,0)) AS 本月股东投资现金流目标
        FROM    data_wide_dws_s_WqBaseStatic_Organization o
                LEFT JOIN #temp_result j ON o.组织架构id = j.组织架构父级id
                LEFT JOIN data_wide_dws_mdm_project p ON p.ProjGUID = o.组织架构id
        WHERE   o.组织架构类型 = @baseinfo
        GROUP BY o.组织架构父级ID ,
                 o.组织架构id ,
                 o.组织架构名称 ,
                 o.组织架构类型;

        SET @baseinfo = @baseinfo - 1;
    END

SELECT  * FROM  #temp_result

DROP TABLE #temp_result ,
           #byfk ,
           #byhl ,
           #confk ,
           #conproj,
           #qpDtCost,
           #qpylgh,
           #qpdthz,
           #qpylgh_fq_land_invest,
           #qpDtCost_fq,
           #qpylgh_fq,
           #qpylgh_fq_zt
