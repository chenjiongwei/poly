/*
modify chenjw  date 20241104 
1、增加盈利规划土地款单方、营销费用单方、综合管理费单方字段
*/

--获产品层级数据
select 
o.组织架构父级ID,
o.组织架构id,
o.组织架构名称,
o.组织架构类型,
--单方
盈利规划营业成本单方,
盈利规划综合管理费单方协议口径+盈利规划营销费用单方 as 盈利规划费用单方, 
盈利规划税金及附加单方,
除地外直投_单方	 盈利规划除地价外直投单方,
开发间接费单方	 盈利规划开发间接费单方,
资本化利息单方	 盈利规划资本化利息单方,
盈利规划股权溢价单方 盈利规划股权溢价单方,

盈利规划营销费用单方  as 盈利规划营销费用单方,
盈利规划综合管理费单方协议口径  as 盈利规划综合管理费单方,
土地款_单方 as 盈利规划土地款单方

--本年
,lr.本年签约金额
,lr.本年签约面积
,case when lr.本年签约面积 = 0 then 0 else lr.本年签约金额*10000.0 / lr.本年签约面积 end 本年签约单价
,lr.本年签约金额不含税
,lr.本年销售毛利润账面
,lr.本年销售毛利率账面
,lr.本年销售盈利规划营业成本
,isnull(lr.本年销售盈利规划营销费用,0)+isnull(本年销售盈利规划综合管理费,0) 本年费用合计
,lr.本年销售盈利规划税金及附加
,lr.本年税前利润
,lr.本年所得税
,lr.本年净利润签约 本年销售净利润账面
,lr.本年销售净利率账面
--本月
,lr.本月签约金额
,lr.本月签约面积
,case when lr.本月签约面积 = 0 then 0 else lr.本月签约金额*10000.0 / lr.本月签约面积 end 本月签约单价
,lr.本月签约金额不含税
,lr.本月销售毛利润账面
,lr.本月销售毛利率账面
,lr.本月销售盈利规划营业成本
,lr.本月销售盈利规划营销费用
,lr.本月销售盈利规划综合管理费
,lr.本月销售盈利规划税金及附加
,lr.本月税前利润
,lr.本月所得税
,lr.本月净利润签约
,lr.本月销售净利率账面
--本月认购
,lr.本月认购金额
,lr.本月认购面积
,case when lr.本月认购面积 = 0 then 0 else lr.本月认购金额*10000.0 / lr.本月认购面积 end 本月认购单价
,lr.本月认购金额不含税
,lr.本月认购毛利润账面
,lr.本月认购毛利率账面
,lr.本月认购盈利规划营业成本
,lr.本月认购盈利规划营销费用
,lr.本月认购盈利规划综合管理费
,lr.本月认购盈利规划税金及附加
,lr.本月认购税前利润
,lr.本月认购所得税
,lr.本月净利润认购
,lr.本月认购净利率账面
--本年预计
,lr.本年预计签约金额
,lr.本年预计签约面积
,case when lr.本年预计签约面积 = 0 then 0 else lr.本年预计签约金额*10000.0 / lr.本年预计签约面积 end 本年预计签约单价
,lr.本年预计签约金额不含税
,lr.本年预计销售毛利润账面
,lr.本年预计销售毛利率账面
,lr.本年预计销售盈利规划营业成本
,isnull(lr.本年预计销售盈利规划营销费用,0)+isnull(本年预计销售盈利规划综合管理费,0) 本年预计费用合计
,lr.本年预计销售盈利规划税金及附加
,lr.本年预计税前利润
,lr.本年预计所得税
,lr.本年预计净利润签约 本年预计销售净利润账面
,lr.本年预计销售净利率账面
--去年
,lr.去年签约金额
,lr.去年签约面积
,case when lr.去年签约面积 = 0 then 0 else lr.去年签约金额*10000.0 / lr.去年签约面积 end 去年签约单价
,lr.去年签约金额不含税
,lr.去年销售毛利润账面
,lr.去年销售毛利率账面
,lr.去年销售盈利规划营业成本
,isnull(lr.去年销售盈利规划营销费用,0)+isnull(去年销售盈利规划综合管理费,0) 去年费用合计
,lr.去年销售盈利规划税金及附加
,lr.去年税前利润
,lr.去年所得税
,lr.去年净利润签约 去年销售净利润账面
,lr.去年销售净利率账面
--累计
,lr.累计签约金额
,lr.累计签约面积
,case when lr.累计签约面积 = 0 then 0 else lr.累计签约金额*10000.0 / lr.累计签约面积 end 累计签约单价
,lr.累计签约金额不含税
,lr.累计销售毛利润账面
,lr.累计销售毛利率账面
,lr.累计销售盈利规划营业成本
,isnull(lr.累计销售盈利规划营销费用,0)+isnull(累计销售盈利规划综合管理费,0) 累计费用合计
,lr.累计销售盈利规划税金及附加
,lr.累计税前利润
,lr.累计所得税
,lr.累计净利润签约 累计销售净利润账面
,lr.累计销售净利率账面
--剩余货值
,lr.剩余货值金额
,lr.剩余面积
,case when lr.剩余面积 = 0 then 0 else lr.剩余货值金额*10000.0 / lr.剩余面积 end  剩余货值单价
,lr.剩余货值不含税
,lr.剩余货值销售毛利润账面
,lr.剩余货值销售毛利率账面
,lr.剩余货值销售盈利规划营业成本
,lr.剩余货值销售盈利规划营销费用
,lr.剩余货值销售盈利规划综合管理费
,lr.剩余货值销售盈利规划税金及附加
,lr.剩余货值税前利润
,lr.剩余货值所得税
,lr.剩余货值净利润
,lr.剩余货值销售净利率账面
--剩余货值实际流速版
,lr.剩余货值实际流速版签约金额
,lr.剩余货值实际流速版签约面积
,case when lr.剩余货值实际流速版签约面积 = 0 then 0 else lr.剩余货值实际流速版签约金额*10000.0 / lr.剩余货值实际流速版签约面积 end  剩余货值实际流速版单价
,lr.剩余货值实际流速版签约金额不含税
,lr.剩余货值实际流速版销售毛利润账面
,lr.剩余货值实际流速版销售毛利率账面
,lr.剩余货值实际流速版销售盈利规划营业成本
,lr.剩余货值实际流速版销售盈利规划营销费用
,lr.剩余货值实际流速版销售盈利规划综合管理费
,lr.剩余货值实际流速版销售盈利规划税金及附加
,lr.剩余货值实际流速版税前利润
,lr.剩余货值实际流速版所得税
,lr.剩余货值实际流速版净利润
,lr.剩余货值实际流速版销售净利率账面
--预估全年
,lr.预估全年签约金额
,lr.预估全年签约面积
,case when lr.预估全年签约面积 = 0 then 0 else lr.预估全年签约金额*10000.0 / lr.预估全年签约面积 end  预估全年签约单价
,lr.预估全年签约金额不含税
,lr.预估全年销售毛利润账面
,lr.预估全年销售毛利率账面
,lr.预估全年销售盈利规划营业成本
,lr.预估全年销售盈利规划营销费用
,lr.预估全年销售盈利规划综合管理费
,lr.预估全年销售盈利规划税金及附加
,lr.预估全年税前利润
,lr.预估全年所得税
,lr.预估全年净利润
,lr.预估全年销售净利率账面
--往年签约本年退房
,lr.往年签约本年退房签约金额
,lr.往年签约本年退房签约面积
,case when lr.往年签约本年退房签约面积 = 0 then 0 else lr.往年签约本年退房签约金额*10000.0 / lr.往年签约本年退房签约面积 end  往年签约本年退房签约单价
,lr.往年签约本年退房签约金额不含税
,lr.往年签约本年退房销售毛利润账面
,lr.往年签约本年退房销售毛利率账面
,lr.往年签约本年退房销售盈利规划营业成本
,lr.往年签约本年退房销售盈利规划营销费用
,lr.往年签约本年退房销售盈利规划综合管理费
,lr.往年签约本年退房销售盈利规划税金及附加
,lr.往年签约本年退房税前利润
,lr.往年签约本年退房所得税
,lr.往年签约本年退房净利润 
,lr.往年签约本年退房销售净利率账面 
--算单价需剔除车位
,case when o.业态 = '地下室/车库' then 0 else lr.本年签约金额 end as 本年签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.本年签约面积 end as 本年签约面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.本月签约金额 end as 本月签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.本月签约面积 end as 本月签约面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.本月认购金额 end as 本月认购金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.本月认购面积 end as 本月认购面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.本年预计签约金额 end as 本年预计签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.本年预计签约面积 end as 本年预计签约面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.去年签约金额 end as 去年签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.去年签约面积 end as 去年签约面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计签约金额 end as 累计签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计签约面积 end as 累计签约面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值金额 end as 剩余货值金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余面积 end as 剩余面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值实际流速版签约金额 end as 剩余货值实际流速版签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值实际流速版签约面积 end as 剩余货值实际流速版签约面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.预估全年签约金额 end as 预估全年签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.预估全年签约面积 end as 预估全年签约面积不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.往年签约本年退房签约金额 end as 往年签约本年退房签约金额不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.往年签约本年退房签约面积 end as 往年签约本年退房签约面积不含车位

,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划营业成本 end as 累计销售盈利规划营业成本不含车位
,case when o.业态 = '地下室/车库' then 0 else isnull(lr.累计销售盈利规划营销费用,0)+isnull(累计销售盈利规划综合管理费,0) end as 累计费用合计不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划税金及附加 end as 累计销售盈利规划税金及附加不含车位

,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划税金及附加 end as 累计销售盈利规划除地价外直投不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划税金及附加 end as 累计销售盈利规划开发间接费不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划税金及附加 end as 累计销售盈利规划资本化利息不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划税金及附加 end as 累计销售盈利规划股权溢价不含车位

,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划营销费用 end as 累计销售盈利规划营销费用不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划综合管理费 end as 累计销售盈利规划综合管理费不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.累计销售盈利规划土地款 end as 累计销售盈利规划土地款不含车位

 ,case when o.业态 = '地下室/车库' then 0 else isnull(lr.剩余货值销售盈利规划营业成本,0)  end  as 剩余货值销售盈利规划营业成本不含车位
,case when o.业态 = '地下室/车库' then 0 else isnull(lr.剩余货值销售盈利规划综合管理费,0) end as 剩余货值销售盈利规划综合管理费不含车位
,case when o.业态 = '地下室/车库' then 0 else isnull(lr.剩余货值销售盈利规划税金及附加,0) end  as 剩余货值销售盈利规划税金及附加不含车位
,case when o.业态 = '地下室/车库' then 0 else isnull(lr.剩余货值销售盈利规划营销费用,0) end as 剩余货值销售盈利规划营销费用不含车位 

,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值销售盈利规划除地价外直投 end as 剩余货值销售盈利规划除地价外直投不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值销售盈利规划开发间接费 end as 剩余货值销售盈利规划开发间接费不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值销售盈利规划资本化利息 end as 剩余货值销售盈利规划资本化利息不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值销售盈利规划股权溢价 end as 剩余货值销售盈利规划股权溢价不含车位
,case when o.业态 = '地下室/车库' then 0 else lr.剩余货值销售盈利规划土地款 end as 剩余货值销售盈利规划土地款不含车位
into #temp_result
from [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_Organization o
left join s_M002业态级净利汇总表_数仓用  lr on o.项目guid = lr.projguid and isnull(lr.产品类型,'') = o.业态 and isnull(o.产品名称,'') = lr.产品名称 and o.装修标准 = lr.装修标准 and o.商业类型 = lr.商品类型 
and datediff(dd,qxdate,getdate()) = 0 
where o.组织架构类型 =5
 
 

--插入业态层级数据，并循环更新项目->区域->公司的数据
insert into #temp_result
select
    o.组织架构父级ID,
    o.组织架构id,
    o.组织架构名称,
    o.组织架构类型,
    null 盈利规划营业成本单方,
    null 盈利规划费用单方, 
    null 盈利规划税金及附加单方,
    null 盈利规划除地价外直投单方,
    null 盈利规划开发间接费单方,
    null 盈利规划资本化利息单方,
    null 盈利规划股权溢价单方,
    null as 盈利规划营销费用单方,
    null as 盈利规划综合管理费单方,
    null as 盈利规划土地款单方
    --本年
    ,sum(isnull(lr.本年签约金额,0)) as 本年签约金额
    ,sum(isnull(lr.本年签约面积,0)) as 本年签约面积
    ,case when sum(isnull(lr.本年签约面积,0)) = 0 then 0 else sum(isnull(lr.本年签约金额,0))*10000.0 / sum(isnull(lr.本年签约面积,0)) end 本年签约单价
    ,sum(isnull(lr.本年签约金额不含税,0)) as 本年签约金额不含税
    ,sum(isnull(lr.本年销售毛利润账面,0)) as 本年销售毛利润账面
    ,case when sum(isnull(lr.本年签约金额不含税,0))=0 then 0 else sum(isnull(lr.本年销售毛利润账面,0))/sum(isnull(lr.本年签约金额不含税,0)) end 本年销售毛利率账面
    ,sum(isnull(lr.本年销售盈利规划营业成本,0)) as 本年销售盈利规划营业成本
    ,sum(isnull(lr.本年费用合计,0)) 本年费用合计
    ,sum(isnull(lr.本年销售盈利规划税金及附加,0)) as 本年销售盈利规划税金及附加
    ,sum(isnull(lr.本年税前利润,0)) as 本年税前利润
    ,sum(isnull(lr.本年所得税,0)) as 本年所得税
    ,sum(isnull(lr.本年销售净利润账面,0)) 本年销售净利润账面
    ,case when sum(isnull(lr.本年签约金额不含税,0))=0 then 0 else sum(isnull(lr.本年销售净利润账面,0))/sum(isnull(lr.本年签约金额不含税,0)) end 本年销售净利率账面
    --本月
    ,sum(isnull(lr.本月签约金额,0)) as 本月签约金额
    ,sum(isnull(lr.本月签约面积,0)) as 本月签约面积
    ,case when sum(isnull(lr.本月签约面积,0)) = 0 then 0 else sum(isnull(lr.本月签约金额,0))*10000.0 / sum(isnull(lr.本月签约面积,0)) end 本月签约单价
    ,sum(isnull(lr.本月签约金额不含税,0)) as 本月签约金额不含税
    ,sum(isnull(lr.本月销售毛利润账面,0)) as 本月销售毛利润账面
    ,case when sum(isnull(lr.本月签约金额不含税,0))=0 then 0 else sum(isnull(lr.本月销售毛利润账面,0))/sum(isnull(lr.本月签约金额不含税,0)) end as 本月销售毛利率账面
    ,sum(isnull(lr.本月销售盈利规划营业成本,0)) as 本月销售盈利规划营业成本
    ,sum(isnull(lr.本月销售盈利规划营销费用,0)) as 本月销售盈利规划营销费用
    ,sum(isnull(lr.本月销售盈利规划综合管理费,0)) as 本月销售盈利规划综合管理费
    ,sum(isnull(lr.本月销售盈利规划税金及附加,0)) as 本月销售盈利规划税金及附加
    ,sum(isnull(lr.本月税前利润,0)) as 本月税前利润
    ,sum(isnull(lr.本月所得税,0)) as 本月所得税
    ,sum(isnull(lr.本月净利润签约,0)) as 本月净利润签约
    ,case when sum(isnull(lr.本月签约金额不含税,0))=0 then 0 else sum(isnull(lr.本月净利润签约,0))/sum(isnull(lr.本月签约金额不含税,0)) end  as 本月销售净利率账面
    --本月认购
    ,sum(isnull(lr.本月认购金额,0)) as 本月认购金额
    ,sum(isnull(lr.本月认购面积,0)) as 本月认购面积
    ,case when sum(isnull(lr.本月认购面积,0))  = 0 then 0 else sum(isnull(lr.本月认购金额,0))*10000.0 / sum(isnull(lr.本月认购面积,0)) end 本月认购单价
    ,sum(isnull(lr.本月认购金额不含税,0)) as 本月认购金额不含税
    ,sum(isnull(lr.本月认购毛利润账面,0)) as 本月认购毛利润账面
    ,case when sum(isnull(lr.本月认购金额不含税,0))=0 then 0 else sum(isnull(lr.本月认购毛利润账面,0))/sum(isnull(lr.本月认购金额不含税,0)) end as 本月认购毛利率账面
    ,sum(isnull(lr.本月认购盈利规划营业成本,0)) as 本月认购盈利规划营业成本
    ,sum(isnull(lr.本月认购盈利规划营销费用,0)) as 本月认购盈利规划营销费用
    ,sum(isnull(lr.本月认购盈利规划综合管理费,0)) as 本月认购盈利规划综合管理费
    ,sum(isnull(lr.本月认购盈利规划税金及附加,0)) as 本月认购盈利规划税金及附加
    ,sum(isnull(lr.本月认购税前利润,0)) as 本月认购税前利润
    ,sum(isnull(lr.本月认购所得税,0)) as 本月认购所得税
    ,sum(isnull(lr.本月净利润认购,0)) as 本月净利润认购
    ,case when sum(isnull(lr.本月认购金额不含税,0))=0 then 0 else sum(isnull(lr.本月净利润认购,0))/sum(isnull(lr.本月认购金额不含税,0)) end as 本月认购净利率账面 

    --本年预计
    ,isnull(yt.本年预计签约金额,0)  as 本年预计签约金额
    ,isnull(yt.本年预计签约面积,0)  as 本年预计签约面积
    ,case when isnull(yt.本年预计签约面积,0) = 0 then 0 else isnull(yt.本年预计签约金额,0)*10000.0 / isnull(yt.本年预计签约面积,0) end 本年预计签约单价
    ,isnull(yt.本年预计签约金额不含税,0)  as 本年预计签约金额不含税
    ,isnull(yt.本年预计销售毛利润账面,0)  as 本年预计销售毛利润账面
    ,case when isnull(yt.本年预计签约金额不含税,0)=0 then 0 else isnull(yt.本年预计销售毛利润账面,0)/isnull(yt.本年预计签约金额不含税,0) end 本年预计销售毛利率账面
    ,isnull(yt.本年预计销售盈利规划营业成本,0) as 本年预计销售盈利规划营业成本
    ,isnull(yt.本年预计销售盈利规划营销费用,0)+isnull(yt.本年预计销售盈利规划综合管理费,0) 本年预计费用合计
    ,isnull(yt.本年预计销售盈利规划税金及附加,0) as 本年预计销售盈利规划税金及附加
    ,isnull(yt.本年预计税前利润,0) as 本年预计税前利润
    ,isnull(yt.本年预计所得税,0) as 本年预计所得税
    ,isnull(yt.本年预计净利润签约,0) 本年预计销售净利润账面
    ,case when isnull(yt.本年预计签约金额不含税,0)=0 then 0 else isnull(yt.本年预计净利润签约,0)/isnull(yt.本年预计签约金额不含税,0)  end 本年预计销售净利率账面
    --去年
    ,sum(isnull(lr.去年签约金额,0)) as 去年签约金额
    ,sum(isnull(lr.去年签约面积,0)) as 去年签约面积
    ,case when sum(isnull(lr.去年签约面积,0)) = 0 then 0 else sum(isnull(lr.去年签约金额,0))*10000.0 / sum(isnull(lr.去年签约面积,0)) end 去年签约单价
    ,sum(isnull(lr.去年签约金额不含税,0)) as 去年签约金额不含税
    ,sum(isnull(lr.去年销售毛利润账面,0)) as 去年销售毛利润账面
    ,case when sum(isnull(lr.去年签约金额不含税,0))=0 then 0 else sum(isnull(lr.去年销售毛利润账面,0))/sum(isnull(lr.去年签约金额不含税,0)) end 去年销售毛利率账面
    ,sum(isnull(lr.去年销售盈利规划营业成本,0)) 去年销售盈利规划营业成本
    ,sum(isnull(lr.去年费用合计,0)) 去年费用合计
    ,sum(isnull(lr.去年销售盈利规划税金及附加,0)) as 去年销售盈利规划税金及附加
    ,sum(isnull(lr.去年税前利润,0)) as 去年税前利润
    ,sum(isnull(lr.去年所得税,0)) as 去年所得税
    ,sum(isnull(lr.去年销售净利润账面,0)) 去年销售净利润账面
    ,case when sum(isnull(lr.去年签约金额不含税,0))=0 then 0 else sum(isnull(lr.去年销售净利润账面,0))/sum(isnull(lr.去年签约金额不含税,0)) end 去年销售净利率账面
    --累计
    ,sum(isnull(lr.累计签约金额,0)) as 累计签约金额
    ,sum(isnull(lr.累计签约面积,0)) as 累计签约面积
    ,case when sum(isnull(lr.累计签约面积,0)) = 0 then 0 else sum(isnull(lr.累计签约金额,0))*10000.0 / sum(isnull(lr.累计签约面积,0)) end 累计签约单价
    ,sum(isnull(lr.累计签约金额不含税,0)) as 累计签约金额不含税
    ,sum(isnull(lr.累计销售毛利润账面,0)) as 累计销售毛利润账面
    ,case when sum(isnull(lr.累计签约金额不含税,0))=0 then 0 else sum(isnull(lr.累计销售毛利润账面,0))/sum(isnull(lr.累计签约金额不含税,0)) end 累计销售毛利率账面
    ,sum(isnull(lr.累计销售盈利规划营业成本,0)) 累计销售盈利规划营业成本
    ,sum(isnull(lr.累计费用合计,0)) 累计费用合计
    ,sum(isnull(lr.累计销售盈利规划税金及附加,0)) as 累计销售盈利规划税金及附加
    ,sum(isnull(lr.累计税前利润,0)) as 累计税前利润
    ,sum(isnull(lr.累计所得税,0)) as 累计所得税
    ,sum(isnull(lr.累计销售净利润账面,0)) 累计销售净利润账面
    ,case when sum(isnull(lr.累计签约金额不含税,0))=0 then 0 else sum(isnull(lr.累计销售净利润账面,0))/sum(isnull(lr.累计签约金额不含税,0)) end 累计销售净利率账面
    --剩余货值
    ,isnull(yt.剩余货值金额,0) as 剩余货值金额
    ,isnull(yt.剩余面积,0) as 剩余面积
    ,case when isnull(yt.剩余面积,0)= 0 then 0 else isnull(yt.剩余货值金额,0)*10000.0 / isnull(yt.剩余面积,0)  end  剩余货值单价
    ,isnull(yt.剩余货值不含税,0) as 剩余货值不含税
    ,isnull(yt.剩余货值销售毛利润账面,0) as  剩余货值销售毛利润账面
    ,case when isnull(yt.剩余货值不含税,0)=0 then 0 else isnull(yt.剩余货值销售毛利润账面,0)/isnull(yt.剩余货值不含税,0) end 剩余货值销售毛利率账面
    ,isnull(yt.剩余货值销售盈利规划营业成本,0) 剩余货值销售盈利规划营业成本
    ,isnull(yt.剩余货值销售盈利规划营销费用,0) as 剩余货值销售盈利规划营销费用
    ,isnull(yt.剩余货值销售盈利规划综合管理费,0) as 剩余货值销售盈利规划综合管理费
    ,isnull(yt.剩余货值销售盈利规划税金及附加,0) as 剩余货值销售盈利规划税金及附加
    ,isnull(yt.剩余货值税前利润,0) as 剩余货值税前利润
    ,isnull(yt.剩余货值所得税,0) as 剩余货值所得税
    ,isnull(yt.剩余货值净利润,0) as 剩余货值净利润
    ,case when isnull(yt.剩余货值不含税,0)=0 then 0 else isnull(yt.剩余货值净利润,0)/isnull(yt.剩余货值不含税,0) end 剩余货值销售净利率账面
    --剩余货值实际流速版
    ,isnull(yt.剩余货值实际流速版签约金额,0) as 剩余货值实际流速版签约金额
    ,isnull(yt.剩余货值实际流速版签约面积,0) as 剩余货值实际流速版签约面积
    ,case when isnull(yt.剩余货值实际流速版签约面积,0) = 0 then 0 else isnull(yt.剩余货值实际流速版签约金额,0)*10000.0 / isnull(yt.剩余货值实际流速版签约面积,0) end  剩余货值实际流速版单价
    ,isnull(yt.剩余货值实际流速版签约金额不含税,0) as 剩余货值实际流速版签约金额不含税
    ,isnull(yt.剩余货值实际流速版销售毛利润账面,0) as 剩余货值实际流速版销售毛利润账面
    ,isnull(yt.剩余货值实际流速版销售毛利率账面,0) as 剩余货值实际流速版销售毛利率账面
    ,isnull(yt.剩余货值实际流速版销售盈利规划营业成本,0) as 剩余货值实际流速版销售盈利规划营业成本
    ,isnull(yt.剩余货值实际流速版销售盈利规划营销费用,0) as 剩余货值实际流速版销售盈利规划营销费用
    ,isnull(yt.剩余货值实际流速版销售盈利规划综合管理费,0) as 剩余货值实际流速版销售盈利规划综合管理费
    ,isnull(yt.剩余货值实际流速版销售盈利规划税金及附加,0) as 剩余货值实际流速版销售盈利规划税金及附加
    ,isnull(yt.剩余货值实际流速版税前利润,0) as 剩余货值实际流速版税前利润
    ,isnull(yt.剩余货值实际流速版所得税,0) as 剩余货值实际流速版所得税
    ,isnull(yt.剩余货值实际流速版净利润,0) as 剩余货值实际流速版净利润
    ,isnull(yt.剩余货值实际流速版销售净利率账面,0) as 剩余货值实际流速版销售净利率账面
    --预估全年
    ,sum(isnull(lr.预估全年签约金额,0)) as 预估全年签约金额
    ,sum(isnull(lr.预估全年签约面积,0)) as 预估全年签约面积
    ,case when sum(isnull(lr.预估全年签约面积,0)) = 0 then 0 else sum(isnull(lr.预估全年签约金额,0))*10000.0 / sum(isnull(lr.预估全年签约面积,0)) end  预估全年签约单价
    ,sum(isnull(lr.预估全年签约金额不含税,0)) as 预估全年签约金额不含税
    ,sum(isnull(lr.预估全年销售毛利润账面,0)) as 预估全年销售毛利润账面
    ,sum(isnull(lr.预估全年销售毛利率账面,0)) as 预估全年销售毛利率账面
    ,sum(isnull(lr.预估全年销售盈利规划营业成本,0)) as 预估全年销售盈利规划营业成本
    ,sum(isnull(lr.预估全年销售盈利规划营销费用,0)) as 预估全年销售盈利规划营销费用
    ,sum(isnull(lr.预估全年销售盈利规划综合管理费,0)) as 预估全年销售盈利规划综合管理费
    ,sum(isnull(lr.预估全年销售盈利规划税金及附加,0)) as 预估全年销售盈利规划税金及附加
    ,sum(isnull(lr.预估全年税前利润,0)) as 预估全年税前利润
    ,sum(isnull(lr.预估全年所得税,0)) as 预估全年所得税
    ,sum(isnull(lr.预估全年净利润,0)) as 预估全年净利润
    ,sum(isnull(lr.预估全年销售净利率账面,0)) as 预估全年销售净利率账面
    --往年签约本年退房
    ,sum(isnull(lr.往年签约本年退房签约金额,0)) as 往年签约本年退房签约金额
    ,sum(isnull(lr.往年签约本年退房签约面积,0)) as 往年签约本年退房签约面积
    ,case when sum(isnull(lr.往年签约本年退房签约面积,0)) = 0 then 0 else sum(isnull(lr.往年签约本年退房签约金额,0))*10000.0 / sum(isnull(lr.往年签约本年退房签约面积,0)) end  往年签约本年退房签约单价
    ,sum(isnull(lr.往年签约本年退房签约金额不含税,0)) as 往年签约本年退房签约金额不含税
    ,sum(isnull(lr.往年签约本年退房销售毛利润账面,0)) as 往年签约本年退房销售毛利润账面
    ,sum(isnull(lr.往年签约本年退房销售毛利率账面,0)) as 往年签约本年退房销售毛利率账面
    ,sum(isnull(lr.往年签约本年退房销售盈利规划营业成本,0)) as 往年签约本年退房销售盈利规划营业成本
    ,sum(isnull(lr.往年签约本年退房销售盈利规划营销费用,0)) as 往年签约本年退房销售盈利规划营销费用
    ,sum(isnull(lr.往年签约本年退房销售盈利规划综合管理费,0)) as 往年签约本年退房销售盈利规划综合管理费
    ,sum(isnull(lr.往年签约本年退房销售盈利规划税金及附加,0)) as 往年签约本年退房销售盈利规划税金及附加
    ,sum(isnull(lr.往年签约本年退房税前利润,0)) as 往年签约本年退房税前利润
    ,sum(isnull(lr.往年签约本年退房所得税,0)) as 往年签约本年退房所得税
    ,sum(isnull(lr.往年签约本年退房净利润,0)) as 往年签约本年退房净利润 
    ,sum(isnull(lr.往年签约本年退房销售净利率账面,0)) as 往年签约本年退房销售净利率账面 
    
    --算单价需剔除车位
    ,sum(isnull(本年签约金额不含车位,0)) as 本年签约金额不含车位
    ,sum(isnull(本年签约面积不含车位,0)) as 本年签约面积不含车位
    ,sum(isnull(本月签约金额不含车位,0)) as 本月签约金额不含车位
    ,sum(isnull(本月签约面积不含车位,0)) as 本月签约面积不含车位
    ,sum(isnull(本月认购金额不含车位,0)) as 本月认购金额不含车位
    ,sum(isnull(本月认购面积不含车位,0)) as 本月认购面积不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.本年预计签约金额,0) end as 本年预计签约金额不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.本年预计签约面积,0) end as 本年预计签约面积不含车位
    ,sum(isnull(去年签约金额不含车位,0)) as 去年签约金额不含车位
    ,sum(isnull(去年签约面积不含车位,0)) as 去年签约面积不含车位
    ,sum(isnull(累计签约金额不含车位,0)) as 累计签约金额不含车位
    ,sum(isnull(累计签约面积不含车位,0)) as 累计签约面积不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值金额,0) end  as 剩余货值金额不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余面积,0) end as 剩余面积不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值实际流速版签约金额,0) end as 剩余货值实际流速版签约金额不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值实际流速版签约面积,0) end as 剩余货值实际流速版签约面积不含车位
    ,sum(isnull(预估全年签约金额不含车位,0)) as 预估全年签约金额不含车位
    ,sum(isnull(预估全年签约面积不含车位,0)) as 预估全年签约面积不含车位
    ,sum(isnull(往年签约本年退房签约金额不含车位,0)) as 往年签约本年退房签约金额不含车位
    ,sum(isnull(往年签约本年退房签约面积不含车位,0)) as 往年签约本年退房签约面积不含车位
    

    ,sum(isnull(累计销售盈利规划营业成本不含车位,0)) as 累计销售盈利规划营业成本不含车位
    ,sum(isnull(累计费用合计不含车位,0)) as 累计费用合计不含车位
    ,sum(isnull(累计销售盈利规划税金及附加不含车位,0)) as 累计销售盈利规划税金及附加不含车位 
    ,sum(isnull(累计销售盈利规划除地价外直投不含车位,0)) as 累计销售盈利规划除地价外直投不含车位 
    ,sum(isnull(累计销售盈利规划开发间接费不含车位,0)) as 累计销售盈利规划开发间接费不含车位 
    ,sum(isnull(累计销售盈利规划资本化利息不含车位,0)) as 累计销售盈利规划资本化利息不含车位 
    ,sum(isnull(累计销售盈利规划股权溢价不含车位,0)) as 累计销售盈利规划股权溢价不含车位  
    ,sum(isnull(累计销售盈利规划营销费用不含车位,0)) as  累计销售盈利规划营销费用不含车位
    ,sum(isnull(累计销售盈利规划综合管理费不含车位,0)) as 累计销售盈利规划综合管理费不含车位
    ,sum(isnull(累计销售盈利规划土地款不含车位,0)) as 累计销售盈利规划土地款不含车位


    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划营业成本,0)  end  as 剩余货值销售盈利规划营业成本不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划综合管理费,0) end as 剩余货值销售盈利规划综合管理费不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划税金及附加,0) end  as 剩余货值销售盈利规划税金及附加不含车位
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划营销费用,0) end as 剩余货值销售盈利规划营销费用不含车位 
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划除地价外直投,0) end as 剩余货值销售盈利规划除地价外直投不含车位 
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划开发间接费,0) end as 剩余货值销售盈利规划开发间接费不含车位 
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划资本化利息,0) end as 剩余货值销售盈利规划资本化利息不含车位 
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划股权溢价,0) end as 剩余货值销售盈利规划股权溢价不含车位 
    ,case when o.组织架构名称 = '地下室/车库' then 0 else isnull(yt.剩余货值销售盈利规划土地款,0) end as 剩余货值销售盈利规划土地款不含车位 
from [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_Organization o
    left join #temp_result lr on o.组织架构id  = lr.组织架构父级id 
    --本年预计/剩余货值的业态层级不能直接从产品级中进行汇总，需单独处理
    left join (
	select yt.projguid, yt.产品类型,  
     sum(isnull(yt.本年预计签约金额,0))   as 本年预计签约金额
    ,sum(isnull(yt.本年预计签约面积,0))  as 本年预计签约面积
    ,sum(isnull(yt.本年预计签约金额不含税,0)) as 本年预计签约金额不含税
    ,sum(isnull(yt.本年预计销售毛利润账面,0)) as 本年预计销售毛利润账面
    ,sum(isnull(yt.本年预计销售盈利规划营业成本,0)) 本年预计销售盈利规划营业成本
    ,sum(isnull(yt.本年预计销售盈利规划营销费用,0)) 本年预计销售盈利规划营销费用
   , sum(isnull(yt.本年预计销售盈利规划综合管理费,0)) 本年预计销售盈利规划综合管理费 
    ,sum(isnull(yt.本年预计销售盈利规划税金及附加,0)) as 本年预计销售盈利规划税金及附加
    ,sum(isnull(yt.本年预计税前利润,0)) as 本年预计税前利润
    ,sum(isnull(yt.本年预计所得税,0)) as 本年预计所得税
    ,sum(isnull(yt.本年预计净利润签约,0)) 本年预计净利润签约 
    ,sum(isnull(yt.剩余货值金额,0)) as 剩余货值金额
    ,sum(isnull(yt.剩余面积,0)) as 剩余面积
    ,sum(isnull(yt.剩余货值不含税,0)) as 剩余货值不含税
    ,sum(isnull(yt.剩余货值销售毛利润账面,0)) as  剩余货值销售毛利润账面
    ,sum(isnull(yt.剩余货值销售盈利规划营业成本,0)) as 剩余货值销售盈利规划营业成本
    ,sum(isnull(yt.剩余货值销售盈利规划营销费用,0)) as 剩余货值销售盈利规划营销费用
    ,sum(isnull(yt.剩余货值销售盈利规划综合管理费,0)) as 剩余货值销售盈利规划综合管理费
    ,sum(isnull(yt.剩余货值销售盈利规划税金及附加,0)) as 剩余货值销售盈利规划税金及附加
    ,sum(isnull(yt.剩余货值销售盈利规划除地价外直投,0)) as 剩余货值销售盈利规划除地价外直投
    ,sum(isnull(yt.剩余货值销售盈利规划开发间接费,0)) as 剩余货值销售盈利规划开发间接费
    ,sum(isnull(yt.剩余货值销售盈利规划资本化利息,0)) as 剩余货值销售盈利规划资本化利息
    ,sum(isnull(yt.剩余货值销售盈利规划股权溢价,0)) as 剩余货值销售盈利规划股权溢价
    ,sum(isnull(yt.剩余货值销售盈利规划土地款,0)) as 剩余货值销售盈利规划土地款

    ,sum(isnull(yt.剩余货值税前利润,0)) as 剩余货值税前利润
    ,sum(isnull(yt.剩余货值所得税,0)) as 剩余货值所得税
    ,sum(isnull(yt.剩余货值净利润,0)) as 剩余货值净利润
    ,sum(isnull(yt.剩余货值实际流速版签约金额,0)) as 剩余货值实际流速版签约金额
    ,sum(isnull(yt.剩余货值实际流速版签约面积,0)) as 剩余货值实际流速版签约面积
    ,sum(isnull(yt.剩余货值实际流速版签约金额不含税,0)) as 剩余货值实际流速版签约金额不含税
    ,sum(isnull(yt.剩余货值实际流速版销售毛利润账面,0)) as 剩余货值实际流速版销售毛利润账面
    ,sum(isnull(yt.剩余货值实际流速版销售毛利率账面,0)) as 剩余货值实际流速版销售毛利率账面
    ,sum(isnull(yt.剩余货值实际流速版销售盈利规划营业成本,0)) as 剩余货值实际流速版销售盈利规划营业成本
    ,sum(isnull(yt.剩余货值实际流速版销售盈利规划营销费用,0)) as 剩余货值实际流速版销售盈利规划营销费用
    ,sum(isnull(yt.剩余货值实际流速版销售盈利规划综合管理费,0)) as 剩余货值实际流速版销售盈利规划综合管理费
    ,sum(isnull(yt.剩余货值实际流速版销售盈利规划税金及附加,0)) as 剩余货值实际流速版销售盈利规划税金及附加
    ,sum(isnull(yt.剩余货值实际流速版税前利润,0)) as 剩余货值实际流速版税前利润
    ,sum(isnull(yt.剩余货值实际流速版所得税,0)) as 剩余货值实际流速版所得税
    ,sum(isnull(yt.剩余货值实际流速版净利润,0)) as 剩余货值实际流速版净利润
    ,sum(isnull(yt.剩余货值实际流速版销售净利率账面,0)) as 剩余货值实际流速版销售净利率账面
  from s_M002业态级净利汇总表_数仓用 yt where DATEDIFF(dd,qxdate,getdate()) = 0
  group by yt.ProjGUID,yt.产品类型  
  )  yt on  yt.projguid = o.项目guid and o.组织架构名称 =yt.产品类型  
where o.组织架构类型 = 4
group by o.组织架构父级ID, o.组织架构id, o.组织架构名称,o.组织架构类型 
,isnull(yt.本年预计签约金额,0) 
,isnull(yt.本年预计签约面积,0)  
,isnull(yt.本年预计签约金额不含税,0)   
,isnull(yt.本年预计销售毛利润账面,0)  
,isnull(yt.本年预计销售盈利规划营业成本,0) 
,isnull(yt.本年预计销售盈利规划营销费用,0)+isnull(yt.本年预计销售盈利规划综合管理费,0)  
,isnull(yt.本年预计销售盈利规划税金及附加,0) 
,isnull(yt.本年预计税前利润,0)  
,isnull(yt.本年预计所得税,0)  
,isnull(yt.本年预计净利润签约,0)   
,isnull(yt.剩余货值金额,0) 
,isnull(yt.剩余面积,0)   
,isnull(yt.剩余货值不含税,0) 
,isnull(yt.剩余货值销售毛利润账面,0)  
,isnull(yt.剩余货值销售盈利规划营业成本,0)  
,isnull(yt.剩余货值销售盈利规划营销费用,0)  
,isnull(yt.剩余货值销售盈利规划综合管理费,0) 
,isnull(yt.剩余货值销售盈利规划税金及附加,0)  
,isnull(yt.剩余货值销售盈利规划除地价外直投,0)
,isnull(yt.剩余货值销售盈利规划开发间接费,0)
,isnull(yt.剩余货值销售盈利规划资本化利息,0)
,isnull(yt.剩余货值销售盈利规划股权溢价,0)
,isnull(yt.剩余货值销售盈利规划土地款,0)
,isnull(yt.剩余货值税前利润,0)  
,isnull(yt.剩余货值所得税,0)  
,isnull(yt.剩余货值净利润,0) 
,isnull(yt.剩余货值实际流速版签约金额,0)
,isnull(yt.剩余货值实际流速版签约面积,0)
,isnull(yt.剩余货值实际流速版签约金额不含税,0)
,isnull(yt.剩余货值实际流速版销售毛利润账面,0)
,isnull(yt.剩余货值实际流速版销售毛利率账面,0)
,isnull(yt.剩余货值实际流速版销售盈利规划营业成本,0)
,isnull(yt.剩余货值实际流速版销售盈利规划营销费用,0)
,isnull(yt.剩余货值实际流速版销售盈利规划综合管理费,0)
,isnull(yt.剩余货值实际流速版销售盈利规划税金及附加,0)
,isnull(yt.剩余货值实际流速版税前利润,0)
,isnull(yt.剩余货值实际流速版所得税,0)
,isnull(yt.剩余货值实际流速版净利润,0)
,isnull(yt.剩余货值实际流速版销售净利率账面,0)

--循环更新数据
DECLARE @baseinfo INT;
set @baseinfo =3; 

while(@baseinfo>0)
BEGIN 
insert into #temp_result
select
    o.组织架构父级ID,
    o.组织架构id,
    o.组织架构名称,
    o.组织架构类型,
    --单方
    case when sum(lr.剩余面积不含车位) = 0 
       then (
         case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划营业成本不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end) 
    else sum((isnull(剩余货值销售盈利规划营业成本不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end 盈利规划营业成本单方,

    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计费用合计不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划营销费用不含车位,0)+isnull(剩余货值销售盈利规划综合管理费不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end  盈利规划费用单方, 

    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划税金及附加不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划税金及附加不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end  盈利规划税金及附加单方,
    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划除地价外直投不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划除地价外直投不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end 盈利规划除地价外直投单方,
    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划开发间接费不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划开发间接费不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end 盈利规划开发间接费单方,
    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划资本化利息不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划资本化利息不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end 盈利规划资本化利息单方,
    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划股权溢价不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划股权溢价不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end 盈利规划股权溢价单方,
    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划土地款不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划土地款不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end 盈利规划土地款单方,

    case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划营销费用不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划营销费用不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end as 盈利规划营销费用单方,
     case when sum(lr.剩余面积不含车位) = 0 then (
    case when sum(lr.累计签约面积不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划综合管理费不含车位,0))*10000.0/sum(lr.累计签约面积不含车位) end
    ) else sum((isnull(剩余货值销售盈利规划综合管理费不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end as 盈利规划综合管理费单方


    --本年
    ,sum(isnull(lr.本年签约金额,0)) as 本年签约金额
    ,sum(isnull(lr.本年签约面积不含车位,0)) as 本年签约面积
    ,case when sum(isnull(lr.本年签约面积不含车位,0)) = 0 then 0 else sum(isnull(lr.本年签约金额不含车位,0))*10000.0 / sum(isnull(lr.本年签约面积不含车位,0)) end 本年签约单价
    ,sum(isnull(lr.本年签约金额不含税,0)) as 本年签约金额不含税
    ,sum(isnull(lr.本年销售毛利润账面,0)) as 本年销售毛利润账面
    ,case when sum(isnull(lr.本年签约金额不含税,0))=0 then 0 else sum(isnull(lr.本年销售毛利润账面,0))/sum(isnull(lr.本年签约金额不含税,0)) end 本年销售毛利率账面
    ,sum(isnull(lr.本年销售盈利规划营业成本,0)) 本年销售盈利规划营业成本
    ,sum(isnull(lr.本年费用合计,0)) 本年费用合计
    ,sum(isnull(lr.本年销售盈利规划税金及附加,0)) as 本年销售盈利规划税金及附加
    ,sum(isnull(lr.本年税前利润,0)) as 本年税前利润
    ,sum(isnull(lr.本年所得税,0)) as 本年所得税
    ,sum(isnull(lr.本年销售净利润账面,0)) 本年销售净利润账面
    ,case when sum(isnull(lr.本年签约金额不含税,0))=0 then 0 else sum(isnull(lr.本年销售净利润账面,0))/sum(isnull(lr.本年签约金额不含税,0)) end 本年销售净利率账面
    --本月
    ,sum(isnull(lr.本月签约金额,0)) as 本月签约金额
    ,sum(isnull(lr.本月签约面积,0)) as 本月签约面积
    ,case when sum(isnull(lr.本月签约面积,0)) = 0 then 0 else sum(isnull(lr.本月签约金额,0))*10000.0 / sum(isnull(lr.本月签约面积,0)) end 本月签约单价
    ,sum(isnull(lr.本月签约金额不含税,0)) as 本月签约金额不含税
    ,sum(isnull(lr.本月销售毛利润账面,0)) as 本月销售毛利润账面
    ,case when sum(isnull(lr.本月签约金额不含税,0))=0 then 0 else sum(isnull(lr.本月销售毛利润账面,0))/sum(isnull(lr.本月签约金额不含税,0)) end as 本月销售毛利率账面
    ,sum(isnull(lr.本月销售盈利规划营业成本,0)) as 本月销售盈利规划营业成本
    ,sum(isnull(lr.本月销售盈利规划营销费用,0)) as 本月销售盈利规划营销费用
    ,sum(isnull(lr.本月销售盈利规划综合管理费,0)) as 本月销售盈利规划综合管理费
    ,sum(isnull(lr.本月销售盈利规划税金及附加,0)) as 本月销售盈利规划税金及附加
    ,sum(isnull(lr.本月税前利润,0)) as 本月税前利润
    ,sum(isnull(lr.本月所得税,0)) as 本月所得税
    ,sum(isnull(lr.本月净利润签约,0)) as 本月净利润签约
    ,case when sum(isnull(lr.本月签约金额不含税,0))=0 then 0 else sum(isnull(lr.本月净利润签约,0))/sum(isnull(lr.本月签约金额不含税,0)) end  as 本月销售净利率账面
    --本月认购
    ,sum(isnull(lr.本月认购金额,0)) as 本月认购金额
    ,sum(isnull(lr.本月认购面积,0)) as 本月认购面积
    ,case when sum(isnull(lr.本月认购面积,0))  = 0 then 0 else sum(isnull(lr.本月认购金额,0))*10000.0 / sum(isnull(lr.本月认购面积,0)) end 本月认购单价
    ,sum(isnull(lr.本月认购金额不含税,0)) as 本月认购金额不含税
    ,sum(isnull(lr.本月认购毛利润账面,0)) as 本月认购毛利润账面
    ,case when sum(isnull(lr.本月认购金额不含税,0))=0 then 0 else sum(isnull(lr.本月认购毛利润账面,0))/sum(isnull(lr.本月认购金额不含税,0)) end as 本月认购毛利率账面
    ,sum(isnull(lr.本月认购盈利规划营业成本,0)) as 本月认购盈利规划营业成本
    ,sum(isnull(lr.本月认购盈利规划营销费用,0)) as 本月认购盈利规划营销费用
    ,sum(isnull(lr.本月认购盈利规划综合管理费,0)) as 本月认购盈利规划综合管理费
    ,sum(isnull(lr.本月认购盈利规划税金及附加,0)) as 本月认购盈利规划税金及附加
    ,sum(isnull(lr.本月认购税前利润,0)) as 本月认购税前利润
    ,sum(isnull(lr.本月认购所得税,0)) as 本月认购所得税
    ,sum(isnull(lr.本月净利润认购,0)) as 本月净利润认购
    ,case when sum(isnull(lr.本月认购金额不含税,0))=0 then 0 else sum(isnull(lr.本月净利润认购,0))/sum(isnull(lr.本月认购金额不含税,0)) end as 本月认购净利率账面 
    --本年预计
    ,sum(isnull(lr.本年预计签约金额,0)) as 本年预计签约金额
    ,sum(isnull(lr.本年预计签约面积不含车位,0)) as 本年预计签约面积
    ,case when sum(isnull(lr.本年预计签约面积不含车位,0)) = 0 then 0 else sum(isnull(lr.本年预计签约金额不含车位,0))*10000.0 / sum(isnull(lr.本年预计签约面积不含车位,0)) end 本年预计签约单价
    ,sum(isnull(lr.本年预计签约金额不含税,0)) as 本年预计签约金额不含税
    ,sum(isnull(lr.本年预计销售毛利润账面,0)) as 本年预计销售毛利润账面
    ,case when sum(isnull(lr.本年预计签约金额不含税,0))=0 then 0 else sum(isnull(lr.本年预计销售毛利润账面,0))/sum(isnull(lr.本年预计签约金额不含税,0)) end 本年预计销售毛利率账面
    ,sum(isnull(lr.本年预计销售盈利规划营业成本,0)) 本年预计销售盈利规划营业成本
    ,sum(isnull(lr.本年预计费用合计,0)) 本年预计费用合计
    ,sum(isnull(lr.本年预计销售盈利规划税金及附加,0)) as 本年预计销售盈利规划税金及附加
    ,sum(isnull(lr.本年预计税前利润,0)) as 本年预计税前利润
    ,sum(isnull(lr.本年预计所得税,0)) as 本年预计所得税
    ,sum(isnull(lr.本年预计销售净利润账面,0)) 本年预计销售净利润账面
    ,case when sum(isnull(lr.本年预计签约金额不含税,0))=0 then 0 else sum(isnull(lr.本年预计销售净利润账面,0))/sum(isnull(lr.本年预计签约金额不含税,0)) end 本年预计销售净利率账面
    --去年
    ,sum(isnull(lr.去年签约金额,0)) as 去年签约金额
    ,sum(isnull(lr.去年签约面积不含车位,0)) as 去年签约面积
    ,case when sum(isnull(lr.去年签约面积不含车位,0)) = 0 then 0 else sum(isnull(lr.去年签约金额不含车位,0))*10000.0 / sum(isnull(lr.去年签约面积不含车位,0)) end 去年签约单价
    ,sum(isnull(lr.去年签约金额不含税,0)) as 去年签约金额不含税
    ,sum(isnull(lr.去年销售毛利润账面,0)) as 去年销售毛利润账面
    ,case when sum(isnull(lr.去年签约金额不含税,0))=0 then 0 else sum(isnull(lr.去年销售毛利润账面,0))/sum(isnull(lr.去年签约金额不含税,0)) end 去年销售毛利率账面
    ,sum(isnull(lr.去年销售盈利规划营业成本,0)) 去年销售盈利规划营业成本
    ,sum(isnull(lr.去年费用合计,0)) 去年费用合计
    ,sum(isnull(lr.去年销售盈利规划税金及附加,0)) as 去年销售盈利规划税金及附加
    ,sum(isnull(lr.去年税前利润,0)) as 去年税前利润
    ,sum(isnull(lr.去年所得税,0)) as 去年所得税
    ,sum(isnull(lr.去年销售净利润账面,0)) 去年销售净利润账面
    ,case when sum(isnull(lr.去年签约金额不含税,0))=0 then 0 else sum(isnull(lr.去年销售净利润账面,0))/sum(isnull(lr.去年签约金额不含税,0)) end 去年销售净利率账面
    --累计
    ,sum(isnull(lr.累计签约金额,0)) as 累计签约金额
    ,sum(isnull(lr.累计签约面积不含车位,0)) as 累计签约面积
    ,case when sum(isnull(lr.累计签约面积不含车位,0)) = 0 then 0 else sum(isnull(lr.累计签约金额不含车位,0))*10000.0 / sum(isnull(lr.累计签约面积不含车位,0)) end 累计签约单价
    ,sum(isnull(lr.累计签约金额不含税,0)) as 累计签约金额不含税
    ,sum(isnull(lr.累计销售毛利润账面,0)) as 累计销售毛利润账面
    ,case when sum(isnull(lr.累计签约金额不含税,0))=0 then 0 else sum(isnull(lr.累计销售毛利润账面,0))/sum(isnull(lr.累计签约金额不含税,0)) end 累计销售毛利率账面
    ,sum(isnull(lr.累计销售盈利规划营业成本,0)) 累计销售盈利规划营业成本
    ,sum(isnull(lr.累计费用合计,0)) 累计费用合计
    ,sum(isnull(lr.累计销售盈利规划税金及附加,0)) as 累计销售盈利规划税金及附加
    ,sum(isnull(lr.累计税前利润,0)) as 累计税前利润
    ,sum(isnull(lr.累计所得税,0)) as 累计所得税
    ,sum(isnull(lr.累计销售净利润账面,0)) 累计销售净利润账面
    ,case when sum(isnull(lr.累计签约金额不含税,0))=0 then 0 else sum(isnull(lr.累计销售净利润账面,0))/sum(isnull(lr.累计签约金额不含税,0)) end 累计销售净利率账面
    --剩余货值
    ,sum(isnull(lr.剩余货值金额,0)) as 剩余货值金额
    ,sum(isnull(lr.剩余面积不含车位,0)) as 剩余面积
    ,case when sum(isnull(lr.剩余面积不含车位,0))  = 0 then 0 else sum(isnull(lr.剩余货值金额不含车位,0))*10000.0 / sum(isnull(lr.剩余面积不含车位,0))  end  剩余货值单价
    ,sum(isnull(lr.剩余货值不含税,0)) as 剩余货值不含税
    ,sum(isnull(lr.剩余货值销售毛利润账面,0)) as  剩余货值销售毛利润账面
    ,case when sum(isnull(lr.剩余货值不含税,0))=0 then 0 else sum(isnull(lr.剩余货值销售毛利润账面,0))/sum(isnull(lr.剩余货值不含税,0)) end 剩余货值销售毛利率账面
    ,sum(isnull(lr.剩余货值销售盈利规划营业成本,0)) 剩余货值销售盈利规划营业成本
    ,sum(isnull(lr.剩余货值销售盈利规划营销费用,0)) as 剩余货值销售盈利规划营销费用
    ,sum(isnull(lr.剩余货值销售盈利规划综合管理费,0)) as 剩余货值销售盈利规划综合管理费
    ,sum(isnull(lr.剩余货值销售盈利规划税金及附加,0)) as 剩余货值销售盈利规划税金及附加
    ,sum(isnull(lr.剩余货值税前利润,0)) as 剩余货值税前利润
    ,sum(isnull(lr.剩余货值所得税,0)) as 剩余货值所得税
    ,sum(isnull(lr.剩余货值净利润,0)) as 剩余货值净利润
    ,case when sum(isnull(lr.剩余货值不含税,0))=0 then 0 else sum(isnull(lr.剩余货值净利润,0))/sum(isnull(lr.剩余货值不含税,0)) end 剩余货值销售净利率账面
    
    --剩余货值实际流速版
    ,sum(isnull(lr.剩余货值实际流速版签约金额,0)) as 剩余货值实际流速版签约金额
    ,sum(isnull(lr.剩余货值实际流速版签约面积不含车位,0)) as 剩余货值实际流速版签约面积
    ,case when sum(isnull(lr.剩余货值实际流速版签约面积不含车位,0))  = 0 then 0 else sum(isnull(lr.剩余货值实际流速版签约金额不含车位,0))*10000.0 / sum(isnull(lr.剩余货值实际流速版签约面积不含车位,0))  end  剩余货值实际流速版签约单价
    ,sum(isnull(lr.剩余货值实际流速版签约金额不含税,0)) as 剩余货值实际流速版签约金额不含税
    ,sum(isnull(lr.剩余货值实际流速版销售毛利润账面,0)) as  剩余货值实际流速版销售毛利润账面
    ,case when sum(isnull(lr.剩余货值实际流速版签约金额不含税,0))=0 then 0 else sum(isnull(lr.剩余货值实际流速版销售毛利润账面,0))/sum(isnull(lr.剩余货值实际流速版签约金额不含税,0)) end 剩余货值实际流速版销售毛利率账面
    ,sum(isnull(lr.剩余货值实际流速版销售盈利规划营业成本,0)) 剩余货值实际流速版销售盈利规划营业成本
    ,sum(isnull(lr.剩余货值实际流速版销售盈利规划营销费用,0)) as 剩余货值实际流速版销售盈利规划营销费用
    ,sum(isnull(lr.剩余货值实际流速版销售盈利规划综合管理费,0)) as 剩余货值实际流速版销售盈利规划综合管理费
    ,sum(isnull(lr.剩余货值实际流速版销售盈利规划税金及附加,0)) as 剩余货值实际流速版销售盈利规划税金及附加
    ,sum(isnull(lr.剩余货值实际流速版税前利润,0)) as 剩余货值实际流速版税前利润
    ,sum(isnull(lr.剩余货值实际流速版所得税,0)) as 剩余货值实际流速版所得税
    ,sum(isnull(lr.剩余货值实际流速版净利润,0)) as 剩余货值实际流速版净利润
    ,case when sum(isnull(lr.剩余货值实际流速版签约金额不含税,0))=0 then 0 else sum(isnull(lr.剩余货值实际流速版净利润,0))/sum(isnull(lr.剩余货值实际流速版签约金额不含税,0)) end 剩余货值实际流速版销售净利率账面
    
    --预估全年
    ,sum(isnull(lr.预估全年签约金额,0)) as 预估全年签约金额
    ,sum(isnull(lr.预估全年签约面积不含车位,0)) as 预估全年签约面积
    ,case when sum(isnull(lr.预估全年签约面积不含车位,0))  = 0 then 0 else sum(isnull(lr.预估全年签约金额不含车位,0))*10000.0 / sum(isnull(lr.预估全年签约面积不含车位,0))  end  预估全年签约单价
    ,sum(isnull(lr.预估全年签约金额不含税,0)) as 预估全年签约金额不含税
    ,sum(isnull(lr.预估全年销售毛利润账面,0)) as  预估全年销售毛利润账面
    ,case when sum(isnull(lr.预估全年签约金额不含税,0))=0 then 0 else sum(isnull(lr.预估全年销售毛利润账面,0))/sum(isnull(lr.预估全年签约金额不含税,0)) end 预估全年销售毛利率账面
    ,sum(isnull(lr.预估全年销售盈利规划营业成本,0)) 预估全年销售盈利规划营业成本
    ,sum(isnull(lr.预估全年销售盈利规划营销费用,0)) as 预估全年销售盈利规划营销费用
    ,sum(isnull(lr.预估全年销售盈利规划综合管理费,0)) as 预估全年销售盈利规划综合管理费
    ,sum(isnull(lr.预估全年销售盈利规划税金及附加,0)) as 预估全年销售盈利规划税金及附加
    ,sum(isnull(lr.预估全年税前利润,0)) as 预估全年税前利润
    ,sum(isnull(lr.预估全年所得税,0)) as 预估全年所得税
    ,sum(isnull(lr.预估全年净利润,0)) as 预估全年净利润
    ,case when sum(isnull(lr.预估全年签约金额不含税,0))=0 then 0 else sum(isnull(lr.预估全年净利润,0))/sum(isnull(lr.预估全年签约金额不含税,0)) end 预估全年销售净利率账面
 
    --往年签约本年退房
    ,sum(isnull(lr.往年签约本年退房签约金额,0)) as 往年签约本年退房签约金额
    ,sum(isnull(lr.往年签约本年退房签约面积不含车位,0)) as 往年签约本年退房签约面积
    ,case when sum(isnull(lr.往年签约本年退房签约面积不含车位,0)) = 0 then 0 else sum(isnull(lr.往年签约本年退房签约金额不含车位,0))*10000.0 / sum(isnull(lr.往年签约本年退房签约面积不含车位,0)) end  往年签约本年退房签约单价
    ,sum(isnull(lr.往年签约本年退房签约金额不含税,0)) as 往年签约本年退房签约金额不含税
    ,sum(isnull(lr.往年签约本年退房销售毛利润账面,0)) as 往年签约本年退房销售毛利润账面
    ,sum(isnull(lr.往年签约本年退房销售毛利率账面,0)) as 往年签约本年退房销售毛利率账面
    ,sum(isnull(lr.往年签约本年退房销售盈利规划营业成本,0)) as 往年签约本年退房销售盈利规划营业成本
    ,sum(isnull(lr.往年签约本年退房销售盈利规划营销费用,0)) as 往年签约本年退房销售盈利规划营销费用
    ,sum(isnull(lr.往年签约本年退房销售盈利规划综合管理费,0)) as 往年签约本年退房销售盈利规划综合管理费
    ,sum(isnull(lr.往年签约本年退房销售盈利规划税金及附加,0)) as 往年签约本年退房销售盈利规划税金及附加
    ,sum(isnull(lr.往年签约本年退房税前利润,0)) as 往年签约本年退房税前利润
    ,sum(isnull(lr.往年签约本年退房所得税,0)) as 往年签约本年退房所得税
    ,sum(isnull(lr.往年签约本年退房净利润,0)) as 往年签约本年退房净利润 
    ,case when sum(isnull(lr.往年签约本年退房签约金额不含税,0))=0 then 0 else sum(isnull(lr.往年签约本年退房净利润,0))/sum(isnull(lr.往年签约本年退房签约金额不含税,0)) end 往年签约本年退房销售净利率账面
 
    --不含车位
    ,sum(isnull(本年签约金额不含车位,0)) as 本年签约金额不含车位
    ,sum(isnull(本年签约面积不含车位,0)) as 本年签约面积不含车位
    ,sum(isnull(本月签约金额不含车位,0)) as 本月签约金额不含车位
    ,sum(isnull(本月签约面积不含车位,0)) as 本月签约面积不含车位
    ,sum(isnull(本月认购金额不含车位,0)) as 本月认购金额不含车位
    ,sum(isnull(本月认购面积不含车位,0)) as 本月认购面积不含车位
    ,sum(isnull(本年预计签约金额不含车位,0)) as 本年预计签约金额不含车位
    ,sum(isnull(本年预计签约面积不含车位,0)) as 本年预计签约面积不含车位
    ,sum(isnull(去年签约金额不含车位,0)) as 去年签约金额不含车位
    ,sum(isnull(去年签约面积不含车位,0)) as 去年签约面积不含车位
    ,sum(isnull(累计签约金额不含车位,0)) as 累计签约金额不含车位
    ,sum(isnull(累计签约面积不含车位,0)) as 累计签约面积不含车位
    ,sum(isnull(剩余货值金额不含车位,0)) as 剩余货值金额不含车位
    ,sum(isnull(剩余面积不含车位,0)) as 剩余面积不含车位

    ,sum(isnull(剩余货值实际流速版签约金额不含车位,0)) as 剩余货值实际流速版签约金额不含车位
    ,sum(isnull(剩余货值实际流速版签约面积不含车位,0)) as 剩余货值实际流速版签约面积不含车位
    ,sum(isnull(预估全年签约金额不含车位,0)) as 预估全年签约金额不含车位
    ,sum(isnull(预估全年签约面积不含车位,0)) as 预估全年签约面积不含车位
    ,sum(isnull(往年签约本年退房签约金额不含车位,0)) as 往年签约本年退房签约金额不含车位
    ,sum(isnull(往年签约本年退房签约面积不含车位,0)) as 往年签约本年退房签约面积不含车位

    ,sum(isnull(累计销售盈利规划营业成本不含车位,0)) as 累计销售盈利规划营业成本不含车位
    ,sum(isnull(累计费用合计不含车位,0)) as 累计费用合计不含车位
    ,sum(isnull(累计销售盈利规划税金及附加不含车位,0)) as 累计销售盈利规划税金及附加不含车位 

	,sum(isnull(累计销售盈利规划除地价外直投不含车位,0)) as 累计销售盈利规划除地价外直投不含车位 
	,sum(isnull(累计销售盈利规划开发间接费不含车位,0)) as 累计销售盈利规划开发间接费不含车位 
	,sum(isnull(累计销售盈利规划资本化利息不含车位,0)) as 累计销售盈利规划资本化利息不含车位 
	,sum(isnull(累计销售盈利规划股权溢价不含车位,0)) as 累计销售盈利规划股权溢价不含车位
    ,sum(isnull(累计销售盈利规划营销费用不含车位,0)) as  累计销售盈利规划营销费用不含车位
    ,sum(isnull(累计销售盈利规划综合管理费不含车位,0)) as 累计销售盈利规划综合管理费不含车位
    ,sum(isnull(累计销售盈利规划土地款不含车位,0)) as 累计销售盈利规划土地款不含车位

    ,sum(isnull(剩余货值销售盈利规划营业成本不含车位,0)) as 剩余货值销售盈利规划营业成本不含车位
    ,sum(isnull(剩余货值销售盈利规划综合管理费,0)) as 剩余货值销售盈利规划综合管理费 
    ,sum(isnull(剩余货值销售盈利规划营销费用,0)) as 剩余货值销售盈利规划营销费用 
    ,sum(isnull(剩余货值销售盈利规划税金及附加不含车位,0)) as 剩余货值销售盈利规划税金及附加不含车位
	,sum(isnull(剩余货值销售盈利规划除地价外直投不含车位,0)) as 剩余货值销售盈利规划除地价外直投不含车位
	,sum(isnull(剩余货值销售盈利规划开发间接费不含车位,0)) as 剩余货值销售盈利规划开发间接费不含车位
	,sum(isnull(剩余货值销售盈利规划资本化利息不含车位,0)) as 剩余货值销售盈利规划资本化利息不含车位
	,sum(isnull(剩余货值销售盈利规划股权溢价不含车位,0)) as 剩余货值销售盈利规划股权溢价不含车位
    ,sum(isnull(剩余货值销售盈利规划土地款不含车位,0)) as 剩余货值销售盈利规划土地款不含车位
from [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_Organization o
    left join #temp_result lr on o.组织架构id  = lr.组织架构父级id 
   where o.组织架构类型 = @baseinfo 
group by o.组织架构父级ID, o.组织架构id, o.组织架构名称,o.组织架构类型
 
SET @baseinfo = @baseinfo - 1;
END

select * from #temp_result

drop table #temp_result
