
-- 项目层级签约利润对比
-- 插入项目临时表
SELECT 
    --a.清洗时间,
    --a.清洗版本,
    a.公司,
    a.投管代码,
    a.项目GUID,
    a.项目,
    a.推广名,
    a.获取日期,
    a.我方股比,
    a.是否并表,
    a.合作方,
    a.是否风险合作方,
    a.地上总可售面积,
    a.项目地价
INTO #proj 
FROM 业态签约利润对比表 a
inner join [172.16.4.141].erp25.dbo.vmdm_projectFlagnew b on a.项目GUID = b.projGUID
where datediff(day,a.清洗时间,getdate()) =0 and isnull(b.是否纳入动态利润分析,'') <> '否'
GROUP BY     
    -- a.清洗时间,
    -- a.清洗版本,
    a.公司,
    a.投管代码,
    a.项目GUID,
    a.项目,
    a.推广名,
    a.获取日期,
    a.我方股比,
    a.是否并表,
    a.合作方,
    a.是否风险合作方,
    a.地上总可售面积,
    a.项目地价


-- 统计项目货值信息
SELECT  p.ProjGUID,
        SUM(ISNULL(zhz, 0)) / 100000000.0 AS 总货值,
        SUM(ISNULL(ysje, 0)) / 100000000.0 AS 其中已售货值,
        SUM(ISNULL(zhz, 0)) / 100000000.0 - SUM(ISNULL(ysje, 0)) / 100000000.0 AS 其中未售货值,
        SUM(CASE WHEN SJzskgdate IS NOT NULL THEN syhz ELSE 0 END) / 100000000.0 AS 其中已开工未售货值,
        SUM(CASE WHEN producttype NOT IN ('地下室/车库') THEN ISNULL(wtmj, 0) + ISNULL(ytwsmj, 0) ELSE 0 END) / 10000.0 AS 未售面积地上, --地上
        SUM(CASE WHEN SJzskgdate IS NOT NULL AND producttype NOT IN ('地下室/车库') THEN ISNULL(wtmj, 0) + ISNULL(ytwsmj, 0) ELSE 0 END) / 10000.0 AS 已开工未售面积地上
into #hzProj
FROM data_wide_dws_s_p_lddbamj a
INNER JOIN data_wide_dws_mdm_Project p ON a.ProjGUID = p.ProjGUID
WHERE DATEDIFF(day, QXDate, GETDATE()) = 0 AND p.Level = 2
GROUP BY p.ProjGUID

-- 统计项目立项信息    
    -- 立项货值,
    -- 立项地价,
    -- 立项建安,
    -- 立项营销费用,
    -- 立项土增税,
    -- 立项税后账面利润,
    -- 立项税后现金利润,
    -- 立项销售净利率,
SELECT 
    a.ProjGUID,
    SUM(ISNULL(a.CashInflowTax, 0)) /10000.0 AS 立项总货值, -- 现金流入（含税）
    -- sum(isnull(a.LandCost,0)) as 立项地价,
    -- sum(isnull(a.LandCost,0)) as 立项建安,
    -- sum(isnull(a.MarketingCost,0)) as 立项营销费用,
    sum(isnull(a.LandAddedTax,0)) /10000.0 as 立项土增税,
    SUM(ISNULL(a.AfterTaxProfit, 0)) /10000.0 AS 立项税后账面利润, -- 账面利润
    sum(isnull(a.CashProfit,0)) /10000.0 as 立项税后现金利润, --税后现金利润    
    MAX(ISNULL(a.SalesNetInterestRate, 0)) AS 立项销售净利率
INTO #lxindx
FROM [172.16.4.141].erp25.dbo.mdm_ProjectIncomeIndex a
where  a.ProductGUID ='00000000-0000-0000-0000-000000000000'
-- and a.ProjGUID ='5463ee81-a411-ee11-b3a3-f40270d39969'
-- WHERE a.projguid = '7125eda8-fcc1-e711-80ba-e61f13c57837'
GROUP BY     
    a.ProjGUID

select a.ProjGUID,
	   SUM(CASE WHEN b.CostShortName IN ( '总投资合计' ) THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项总投资,
        SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项土地款,
        -- SUM(CASE WHEN b.CostShortName IN ( '除地价外投资合计' ) THEN a.CostMoney ELSE 0 END) AS 除地价外直投,
        --除地价外投资合计-三费
        ISNULL(SUM(CASE WHEN b.CostShortName = '除地价外投资合计' THEN a.CostMoney ELSE 0 END), 0)  /10000.0 - 
		ISNULL(SUM(CASE WHEN b.CostShortName in ('管理费用','营销费用','财务费用') THEN a.CostMoney ELSE 0 END), 0)  /10000.0 AS 立项除地价外直投,
        SUM(CASE WHEN b.CostShortName = '开发前期费' THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项开发前期费,
        SUM(CASE WHEN b.CostShortName = '建筑安装工程费' THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项建筑安装工程费,
        SUM(CASE WHEN b.CostShortName = '红线内配套费' THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项红线内配套费,
        SUM(CASE WHEN b.CostShortName = '政府收费' THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项政府收费,
        SUM(CASE WHEN b.CostShortName = '不可预见费' THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项不可预见费,  
        SUM(CASE WHEN b.CostShortName IN ( '管理费用' ) THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项管理费用,
        SUM(CASE WHEN b.CostShortName IN ( '营销费用' ) THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项营销费用,
        SUM(CASE WHEN b.CostShortName IN ( '财务费用' ) THEN a.CostMoney ELSE 0 END)  /10000.0 AS 立项财务费用
into #lxindx_cost
fROM [172.16.4.141].erp25.dbo.mdm_ProjProductCostIndex a
     INNER JOIN [172.16.4.141].erp25.dbo.mdm_CostIndex b ON a.CostGuid = b.CostGUID
WHERE a.ProductGUID = '00000000-0000-0000-0000-000000000000' --and ProjGUID ='e0f9973a-daa2-ee11-b3a4-f40270d39969'
    GROUP BY a.ProjGUID

    
-- 24年签约利润
SELECT 
    a.项目GUID,
    SUM(a.签约_24年签约) AS 签约_24年签约,
    SUM(a.签约不含税_24年签约) AS 签约不含税_24年签约,
    sum(case when a.产品类型<>'地下室/车库' then a.签约面积_24年签约 else 0 end) as 签约面积_24年签约不含车位,

    SUM(a.净利润_24年签约) AS 净利润_24年签约,
    CASE WHEN SUM(a.签约不含税_24年签约) = 0 THEN 0
    ELSE SUM(a.净利润_24年签约) / SUM(a.签约不含税_24年签约) END AS 净利率_24年签约,
    
    SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.签约_24年签约 ELSE 0 END) AS 其中住宅签约_24年签约,
    CASE WHEN SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.签约不含税_24年签约 ELSE 0 END) = 0 THEN 0
    ELSE SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.净利润_24年签约 ELSE 0 END)  
         / SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.签约不含税_24年签约 ELSE 0 END) END AS 住宅净利率_24年签约,
    
    SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.签约_24年签约 ELSE 0 END) AS 其中商办签约_24年签约,
    CASE WHEN SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.签约不含税_24年签约 ELSE 0 END) = 0 THEN 0
    ELSE SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.净利润_24年签约 ELSE 0 END)  
         / SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.签约不含税_24年签约 ELSE 0 END) END AS 商办净利率_24年签约,
    
    -- 25年签约利润
    SUM(a.签约_25年签约) AS 签约_25年签约,
    SUM(a.签约不含税_25年签约) AS 签约不含税_25年签约,
    sum(case when a.产品类型<>'地下室/车库' then a.签约面积_25年签约 else 0 end) as 签约面积_25年签约不含车位,
    CASE WHEN SUM(a.签约不含税_25年签约) = 0 THEN 0
    ELSE SUM(a.净利润_25年签约) / SUM(a.签约不含税_25年签约) END AS 净利率_25年签约,
    sum(a.报表利润_25年签约) as 报表净利润_25年签约,
    SUM(a.净利润_25年签约) AS 净利润_25年签约,
    
    SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.签约_25年签约 ELSE 0 END) AS 其中住宅签约_25年签约,
    CASE WHEN SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.签约不含税_25年签约 ELSE 0 END) = 0 THEN 0
    ELSE SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.净利润_25年签约 ELSE 0 END)  
         / SUM(CASE WHEN a.产品类型 IN ('高级住宅', '住宅', '别墅') THEN a.签约不含税_25年签约 ELSE 0 END) END AS 住宅净利率_25年签约,
    
    SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.签约_25年签约 ELSE 0 END) AS 其中商办签约_25年签约,
    CASE WHEN SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.签约不含税_25年签约 ELSE 0 END) = 0 THEN 0
    ELSE SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.净利润_25年签约 ELSE 0 END)  
         / SUM(CASE WHEN a.产品类型 NOT IN ('高级住宅', '住宅', '别墅', '地下室/车库') THEN a.签约不含税_25年签约 ELSE 0 END) END AS 商办净利率_25年签约,

     -- 本月签约利润 
    sum(a.签约_本月实际) as 签约_本月实际,
    sum(a.签约不含税_本月实际) as 签约不含税_本月实际,
    sum(case when a.产品类型<>'地下室/车库' then a.签约面积_本月实际 else 0 end) as 签约面积_本月实际不含车位,
    sum(a.净利润_本月实际) as 净利润_本月实际,
    case when sum(a.签约不含税_本月实际) = 0 then 0 else sum(a.净利润_本月实际) / sum(a.签约不含税_本月实际) end as 净利率_本月实际,

    -- 利润预算
    SUM(a.净利润_25年预算) AS 净利润_25年预算,
    SUM(a.签约_25年预算) AS 签约_25年预算,
    SUM(a.签约不含税_25年预算) AS 签约不含税_25年预算,
    CASE WHEN SUM(a.签约不含税_25年预算) = 0 THEN 0
    ELSE SUM(a.净利润_25年预算) / SUM(a.签约不含税_25年预算) END AS 净利率_25年预算,

    -- sum(case when a.签约均价_25年签约 <> 0  and isnull(a.签约均价_25年预算, a.签约均价_24年签约) <> 0  and a.签约面积_25年签约 <> 0
    --        then  (a.签约均价_25年签约 - isnull(a.签约均价_25年预算, a.签约均价_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end) as 售价下降,
    -- sum(case when a.营业成本单方_25年签约 <> 0  and  isnull(a.营业成本单方_25年预算, a.营业成本单方_24年签约) <> 0  and a.签约面积_25年签约 <> 0
    --        then  (a.营业成本单方_25年签约 - isnull(a.营业成本单方_25年预算, a.营业成本单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end) as 成本增加,
    -- sum(case when a.营销费用单方_25年签约 <> 0  and isnull(a.营销费用单方_25年预算, a.营销费用单方_24年签约) <> 0  and a.签约面积_25年签约 <> 0
    --        then  (a.营销费用单方_25年签约 - isnull(a.营销费用单方_25年预算, a.营销费用单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end) as 营销费用增加,
    -- sum(case when a.管理费用单方_25年签约 <> 0  and isnull(a.管理费用单方_25年预算, a.管理费用单方_24年签约) <> 0  and a.签约面积_25年签约 <> 0
    --        then  (a.管理费用单方_25年签约 - isnull(a.管理费用单方_25年预算, a.管理费用单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end) as 管理费用增加,
    -- sum(case when a.税金单方_25年签约 <> 0  and isnull(a.税金单方_25年预算, a.税金单方_24年签约) <> 0  and a.签约面积_25年签约 <> 0
    --        then  (a.税金单方_25年签约 - isnull(a.税金单方_25年预算, a.税金单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end) as 税金增加,
    -- null as 其他
   
     -- 判断是否有预算
     sum(case when b.项目是否有利润预算 = '是' and a.签约均价_25年预算 <> 0 then 
            case when a.签约均价_25年签约 <> 0 and a.签约均价_25年预算 <> 0 and a.签约面积_25年签约 <> 0
                then (isnull(a.签约均价_25年签约, 0) - isnull(a.签约均价_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        -- 没有预算，取24年签约
        when b.项目是否有利润预算 = '否' and a.签约均价_24年签约 <> 0 then 
            case when a.签约均价_25年签约 <> 0 and a.签约均价_24年签约 <> 0 and a.签约面积_25年签约 <> 0
                then (isnull(a.签约均价_25年签约, 0) - isnull(a.签约均价_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        else 0 end ) as 售价下降, --单位亿元
       
       sum(case when b.项目是否有利润预算 = '是' and a.营业成本单方_25年预算 <> 0 then 
            case when a.营业成本单方_25年签约 <> 0 and a.营业成本单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0 
                then (isnull(a.营业成本单方_25年签约, 0) - isnull(a.营业成本单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        when b.项目是否有利润预算 = '否' and a.营业成本单方_24年签约 <> 0 then 
            case when a.营业成本单方_25年签约 <> 0 and a.营业成本单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0 
                then (isnull(a.营业成本单方_25年签约, 0) - isnull(a.营业成本单方_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0 end ) as 成本增加, --单位亿元
       
       sum(case when b.项目是否有利润预算 = '是' and a.营销费用单方_25年预算 <> 0 then 
            case when a.营销费用单方_25年签约 <> 0 and a.营销费用单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.营销费用单方_25年签约, 0) - isnull(a.营销费用单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        when b.项目是否有利润预算 = '否' and a.营销费用单方_24年签约 <> 0 then 
            case when a.营销费用单方_25年签约 <> 0 and a.营销费用单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.营销费用单方_25年签约,0) - isnull(a.营销费用单方_24年签约,0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0 end ) as 营销费用增加, --单位亿元

       sum(case when b.项目是否有利润预算 = '是' and a.管理费用单方_25年预算 <> 0 then 
            case when a.管理费用单方_25年签约 <> 0 and a.管理费用单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.管理费用单方_25年签约, 0) - isnull(a.管理费用单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        when b.项目是否有利润预算 = '否' and a.管理费用单方_24年签约 <> 0 then 
            case when a.管理费用单方_25年签约 <> 0 and a.管理费用单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.管理费用单方_25年签约, 0) - isnull(a.管理费用单方_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0  end ) as 管理费用增加, --单位亿元
       
       sum(case when b.项目是否有利润预算 = '是' and a.税金单方_25年预算 <> 0 then 
            case when a.税金单方_25年签约 <> 0 and a.税金单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.税金单方_25年签约, 0) - isnull(a.税金单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
          when b.项目是否有利润预算 = '否' and a.税金单方_24年签约 <> 0 then 
            case when a.税金单方_25年签约 <> 0 and a.税金单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.税金单方_25年签约, 0) - isnull(a.税金单方_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0 end ) as 税金增加, --单位亿元
        
       null as 其他
INTO #lr
FROM 业态签约利润对比表 a
    LEFT JOIN (
        SELECT  
            项目GUID,
            CASE WHEN SUM(净利润_25年预算) <> 0 THEN '是' ELSE '否' END AS 项目是否有利润预算,
            CASE WHEN SUM(净利润_24年签约) <> 0 THEN '是' ELSE '否' END AS 项目是否有24年利润
        FROM 业态签约利润对比表  
        WHERE DATEDIFF(DAY, GETDATE(), 清洗时间) = 0
        GROUP BY 项目GUID
    ) b ON a.项目GUID = b.项目GUID -- AND a.业态组合键 = b.业态组合键
WHERE DATEDIFF(DAY, a.清洗时间, GETDATE()) = 0
GROUP BY a.项目GUID


-- 利润执行偏差预警
SELECT a.*,
    -- 较预算比较（有预算）
    CASE WHEN a.净利润_25年预算 <> 0 THEN '是' ELSE '否' END AS 项目是否有年度预算,
    CASE WHEN a.净利润_25年预算 <> 0 THEN a.净利率_25年预算 END AS 预算净利率,
    CASE WHEN a.净利润_25年预算 <> 0 THEN a.净利率_25年签约 - a.净利率_25年预算 END AS 实际较预算偏差,
    -- 较24年或立项对比(无预算)
    CASE WHEN a.净利润_25年预算 = 0 THEN a.净利率_25年签约 - a.净利率_24年签约 END AS 实际较24年偏差对比,
    CASE WHEN a.净利润_25年预算 = 0 THEN a.净利率_25年签约 - lxindx.立项销售净利率 END AS 实际较立项偏差对比

    -- --较预算/24年利润率偏差原因分类汇总
    -- 售价下降 AS 售价下降,
    -- 成本增加 AS 成本增加,
    -- 营销费用增加 AS 营销费用增加,
    -- 管理费用增加 AS 管理费用增加,
    -- 税金增加 AS 税金增加,
    -- 其他 AS 其他
INTO #lr_pc 
FROM #lr a 
left join #lxindx lxindx on a.项目GUID = lxindx.ProjGUID



-- 查询最终结果
SELECT  
    -- p.清洗时间,
    --p.清洗版本,
    p.公司,
    p.投管代码,
    p.项目GUID,
    p.项目,
    p.推广名,
    p.获取日期,
    p.我方股比,
    p.是否并表,
    p.合作方,
    p.是否风险合作方,
    p.地上总可售面积 /10000.0 as 地上总可售面积, -- 单位万平米
    p.项目地价 /100000000.0 as 项目地价, -- 单位亿元
    -- 货值情况
    hz.总货值,
    hz.其中已售货值,
    hz.其中未售货值,
    hz.其中已开工未售货值,
    hz.未售面积地上, --地上
    hz.已开工未售面积地上,

    --立项利润
    lxindx.立项总货值,
    lxindx_cost.立项土地款,
    lxindx_cost.立项除地价外直投,
    lxindx_cost.立项开发前期费,
    lxindx_cost.立项建筑安装工程费,
    lxindx_cost.立项红线内配套费,
    lxindx_cost.立项政府收费,
    lxindx_cost.立项不可预见费,
    lxindx_cost.立项管理费用,
    lxindx_cost.立项营销费用,
    lxindx_cost.立项财务费用,

    lxindx.立项土增税,
    lxindx.立项税后账面利润,
    lxindx.立项税后现金利润,
    lxindx.立项销售净利率,
    
    -- 项目整盘利润情况
    NULL AS 税后利润,
    NULL AS 税后现金利润,
    NULL AS 其中已结转利润,
    NULL AS 其中已售未结转利润,
    NULL AS 其中未售利润,

    lr.签约_24年签约,
    lr.签约不含税_24年签约,
    lr.签约面积_24年签约不含车位,
    lr.净利润_24年签约,
    lr.净利率_24年签约,
    
    lr.其中住宅签约_24年签约,
    lr.住宅净利率_24年签约,
    lr.其中商办签约_24年签约,
    lr.商办净利率_24年签约,
    -- 25年签约利润
    lr.签约_25年签约,
    lr.签约不含税_25年签约,
    lr.签约面积_25年签约不含车位,
    lr.净利率_25年签约,
    lr.净利润_25年签约,
    lr.报表净利润_25年签约,
    lr.其中住宅签约_25年签约,
    lr.住宅净利率_25年签约,
    lr.其中商办签约_25年签约,
    lr.商办净利率_25年签约,

    -- 本月签约利润
    lr.签约_本月实际,
    lr.签约不含税_本月实际,
    lr.签约面积_本月实际不含车位,
    lr.净利润_本月实际,
    lr.净利率_本月实际,

    -- 利润预算
    lr.净利润_25年预算,
    lr.净利率_25年预算,
    lr.签约_25年预算,
    lr.签约不含税_25年预算,
    -- 利润执行偏差预警
    lr_pc.项目是否有年度预算,
    lr_pc.预算净利率,
    lr_pc.实际较预算偏差,
    lr_pc.实际较24年偏差对比,
    lr_pc.实际较立项偏差对比,
    lr_pc.售价下降,
    lr_pc.成本增加,
    lr_pc.营销费用增加,
    lr_pc.管理费用增加,
    lr_pc.税金增加,
    lr_pc.其他
FROM #proj p
LEFT JOIN #hzProj hz ON p.项目GUID = hz.ProjGUID
LEFT JOIN #lr lr ON p.项目GUID = lr.项目GUID
LEFT JOIN #lr_pc lr_pc ON p.项目GUID = lr_pc.项目GUID
LEFT JOIN #lxindx lxindx ON p.项目GUID = lxindx.ProjGUID
LEFT JOIN #lxindx_cost lxindx_cost ON p.项目GUID = lxindx_cost.ProjGUID
WHERE 1=1


-- 删除临时表
DROP TABLE #proj
DROP TABLE #lr
DROP TABLE #lr_pc
drop table #lxindx
drop table #hzProj
drop table #lxindx_cost