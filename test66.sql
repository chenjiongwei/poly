-- 获取项目首推时间
SELECT 
    t.projguid, 
    MIN(SJkpxsDate) AS SJkpxsDate 
INTO #stDate
FROM (
    -- 获取房间认购的时间
    SELECT 
        parentprojguid AS projguid, 
        MIN(qsdate) AS SJkpxsDate 
    FROM data_wide_s_SaleHsData 
    GROUP BY parentprojguid

    -- 获取特殊业绩计算货量的录入时间
    UNION ALL 
    SELECT 
        ParentProjGUID AS projguid,
        MIN(StatisticalDate) AS SJkpxsDate
    FROM data_wide_s_SpecialPerformance
    WHERE TsyjType IN (
        SELECT TsyjTypeName 
        FROM [172.16.4.141].erp25.dbo.s_TsyjType t 
        WHERE IsCalcYSHL = 1
    )
    GROUP BY ParentProjGUID

    -- 合作业绩录入不为0
    UNION ALL 
    SELECT 
        ParentProjGUID AS projguid,
        MIN(StatisticalDate) AS SJkpxsDate
    FROM data_wide_s_NoControl
    WHERE CCjTotal > 0
    GROUP BY ParentProjGUID
) t
INNER JOIN data_wide_dws_mdm_project pj 
    ON t.projguid = pj.projguid 
GROUP BY t.projguid


select
    pj.项目guid projguid,
    pj.项目名称 projname,
    -----------------技术指标
    --动态
    pj.总建筑面积 动态总建面积,
    pj.地上建筑面积 动态地上建筑面积,
    pj.地下建筑面积 动态地下建筑面积,
    pj.计容建筑面积 动态计容面积,
    ks.动态车位可售面积,
    ks.动态非车位可售面积,
    --立项
    t.BldArea 立项总建面积,
    t.UpBldArea 立项地上建筑面积,
    t.DownBldArea 立项地下建筑面积,
    t.JrArea 立项计容面积,
    lxks.立项车位可售面积,
    lxks.立项非车位可售面积,
    --偏差
    isnull(pj.总建筑面积,0) - isnull(t.BldArea,0) as 总建面积偏差,
    isnull(pj.地上建筑面积,0) - isnull(t.UpBldArea,0) 地上建筑面积偏差,
    isnull(pj.地下建筑面积,0) - isnull(t.DownBldArea,0) 地下建筑面积偏差,
    isnull(pj.计容建筑面积,0) - isnull(t.JrArea,0) 计容面积偏差,
    isnull(ks.动态车位可售面积,0) -   isnull(lxks.立项车位可售面积,0) 车位可售面积偏差,
    isnull(ks.动态非车位可售面积,0) - isnull(lxks.立项非车位可售面积,0) 非车位可售面积偏差,
    ----------------成本指标
    --动态
    ylgh.土地款不含税_财务分摊 动态土地款,
    null 动态土地分摊方式, --留空
    ylgh.除地价外直投不含税_财务分摊 动态除地价外直投,
    ylgh.营销费用账面口径 动态营销费用,
    case when isnull(ylgh.销售收入含税,0) = 0 then 0 else isnull( ylgh.营销费用账面口径,0)/isnull(ylgh.销售收入含税,0) end 动态营销费率, --营销费用/总货值
    ylgh.财务费用账面口径 动态财务费用,
    ylgh.综合管理费协议口径_账面口径 动态管理费用,
    case when isnull(ylgh.除地价外直投不含税_财务分摊,0)+isnull(ylgh.土地款不含税_财务分摊,0) = 0 then 0 
    else isnull(ylgh.综合管理费协议口径_账面口径,0)/(isnull(ylgh.除地价外直投不含税_财务分摊,0)+isnull(ylgh.土地款不含税_财务分摊,0)) end 动态管理费率, --管理费用/直接投资
    --立项
    t.LandAmount 立项土地款,
    null 立项土地分摊方式, --留空
    t.除地价外直投 立项除地价外直投,
    t.YxExpenses 立项营销费用,
    case when isnull(totalsaleamount,0) = 0 then 0 else  isnull(t.YxExpenses,0)/t.totalsaleamount end 立项营销费率, --营销费用/总货值
    t.CwExpenses 立项财务费用,
    t.GlExpenses 立项管理费用,
    case when isnull(t.DirectInvestment,0) = 0 then 0 else isnull(t.GlExpenses,0)/isnull(t.DirectInvestment,0) end 立项管理费率, --管理费用/直接投资
    --偏差
    isnull(ylgh.土地款不含税_财务分摊,0) -isnull(t.LandAmount,0)  土地款偏差,
    null 土地分摊方式偏差, --留空
    isnull(ylgh.除地价外直投不含税_财务分摊,0) -isnull(t.除地价外直投,0) 除地价外直投偏差,
    isnull(ylgh.营销费用账面口径,0) -isnull(t.YxExpenses,0) 营销费用偏差,
    case when isnull(ylgh.销售收入含税,0) = 0 then 0 else isnull( ylgh.营销费用账面口径,0)/isnull(ylgh.销售收入含税,0) end
    -case when isnull(totalsaleamount,0) = 0 then 0 else  isnull(t.YxExpenses,0)/t.totalsaleamount end 营销费率偏差, --营销费用/总货值
    isnull(ylgh.财务费用账面口径,0) -isnull(t.CwExpenses,0) 财务费用偏差,
    isnull(ylgh.综合管理费协议口径_账面口径,0) -isnull(t.GlExpenses,0) 管理费用偏差,
    case when isnull(ylgh.除地价外直投不含税_财务分摊,0)+isnull(ylgh.土地款不含税_财务分摊,0) = 0 then 0 
    else isnull(ylgh.综合管理费协议口径_账面口径,0)/(isnull(ylgh.除地价外直投不含税_财务分摊,0)+isnull(ylgh.土地款不含税_财务分摊,0)) end - 
    case when isnull(t.DirectInvestment,0) = 0 then 0 else isnull(t.GlExpenses,0)/isnull(t.DirectInvestment,0) end 管理费率偏差, --管理费用/直接投资
    ------------------节点指标				
    --动态
    st.sjkpxsdate 动态首开时间,		
    jd.竣工备案表最早完成日期_实际 动态首次竣备时间,		
    jd.集中交付最早完成日期_实际 动态首期交付时间,
    --立项
    convert(varchar(10),t.FirstOpenDate,120) 立项首开时间,		
    convert(varchar(10),t.SqfinishDate,120) 立项首次竣备时间,		
    convert(varchar(10),t.SqjzDate,120) 立项首期交付时间,
    --偏差
    case when t.FirstOpenDate is null then 0 else datediff(dd,t.FirstOpenDate,isnull(st.sjkpxsdate,getdate())) end 首开时间偏差,		
    case when t.SqfinishDate is null then 0 else datediff(dd,t.SqfinishDate,isnull(jd.竣工备案表最早完成日期_实际,getdate())) end 首次竣备时间偏差,		
    case when t.SqjzDate is null then 0 else datediff(dd,t.SqjzDate,isnull(jd.集中交付最早完成日期_实际,getdate())) end 首期交付时间偏差,
    ------------------收益指标
    --动态
    ylgh.销售收入含税 动态总货值,							
    ylgh.固定资产账面口径 动态固定资产,							
    ylgh.土地增值税 动态土增税,		
    ylgh.增值税下附加税 动态增值税及附加,		
    ylgh.所得税 动态所得税,				
    ylgh.股权溢价 动态股权溢价,		
    ylgh.税前利润账面口径 动态税前利润,		
    ylgh.税后利润账面口径 动态税后利润,
    ylgh.税后净现金账面口径 动态税后净现金,		
    ylgh.税前成本利润率_账面口径 动态税前成本利润率,		
    ylgh.销售净利率_账面口径 动态销售净利率, 
    --立项
    t.totalsaleamount 立项总货值,							
    t.FixedAssetsTwo 立项固定资产,							
    t.LandAddedTax 立项土增税,		
    t.UnderVATSurcharge 立项增值税及附加,		
    t.IncomeTax 立项所得税,				
    t.gqyjAmount 立项股权溢价,		
    t.BeforeProfit 立项税前利润,		
    t.AfterTaxProfit 立项税后利润,
    t.AfterTaxCash 立项税后净现金,		
    t.PreTaxCostProfitRate 立项税前成本利润率,		
    t.SalesNetInterestRate 立项销售净利率,
    --偏差
    isnull(ylgh.销售收入含税,0) - isnull(t.totalsaleamount,0) 总货值偏差,							
    isnull(ylgh.固定资产账面口径,0) - isnull(t.FixedAssetsTwo,0) 固定资产偏差,							
    isnull(ylgh.土地增值税,0) - isnull(t.LandAddedTax,0) 土增税偏差,		
    isnull(ylgh.增值税下附加税,0) - isnull(t.UnderVATSurcharge,0) 增值税及附加偏差,		
    isnull(ylgh.所得税,0) - isnull(t.IncomeTax,0) 所得税偏差,				
    isnull(ylgh.股权溢价,0) - isnull(t.gqyjAmount,0) 股权溢价偏差,		
    isnull(ylgh.税前利润账面口径,0) - isnull(t.BeforeProfit,0) 税前利润偏差,		
    isnull(ylgh.税后利润账面口径,0) - isnull(t.AfterTaxProfit,0) 税后利润偏差,
    isnull(ylgh.税后净现金账面口径,0) - isnull(t.AfterTaxCash,0) 税后净现金偏差,		
    isnull(ylgh.税前成本利润率_账面口径,0) - isnull(t.PreTaxCostProfitRate,0) 税前成本利润率偏差,		
    isnull(ylgh.销售净利率_账面口径,0) - isnull(t.SalesNetInterestRate,0) 销售净利率偏差
from dw_d_topproject pj 
left join data_wide_dws_ys_SumOperatingProfitDataLXDWBfYt t on t.projguid = pj.项目guid
and  EditonType = '立项版'
left join (select projguid,sum(case when YtName = '地下室/车库' then zksmj else 0 end) 立项车位可售面积, 
sum(case when YtName = '地下室/车库' then 0 else zksmj end) 立项非车位可售面积 from data_wide_dws_ys_SumOperatingProfitDataLXDWByYt 
where EditonType = '立项版'
group by projguid
) lxks on pj.项目guid = lxks.projguid
left join (
    select 项目guid,sum(case when 产品类型 = '地下室/车库' then isnull(地上可售面积,0)+isnull(地下可售面积,0)  else 0 end) 动态车位可售面积, 
sum(case when 产品类型 = '地下室/车库' then 0 else  isnull(地上可售面积,0)+isnull(地下可售面积,0) end) 动态非车位可售面积 from dw_d_salebuild sb
group by 项目GUID
) ks on pj.项目guid = ks.项目guid
left join dw_f_TopProJect_ProfitCost_ylgh ylgh on pj.项目guid = ylgh.项目guid
left join #stDate st on st.projguid = pj.项目guid
left join dw_f_TopProject_Schedule jd on jd.项目guid = pj.项目guid
 