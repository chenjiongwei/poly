USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_M002业态级净利汇总表_数仓用]    Script Date: 2025/1/6 11:07:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_s_M002业态级净利汇总表_数仓用](@qxdate datetime = null)  AS 
/*
运行样例：usp_s_M002业态级净利汇总表_数仓用  '2024-12-11'
author:lintx
用途：用于清洗业态层级的利润数据，用于湾区看板

全年任务：
①本年实际签约金额≥本年货量铺排任务的项目，取项目的实际签约金额和实际签约面积。
②本年实际签约金额＜本年货量铺排任务的项目，用全公司货量铺排任务的差额分摊到未完成签约任务的项目及产品中，具体分摊规则如下：
A、项目层级任务金额：
【项目全年签约任务】=项目已签约+项目预计签约
【项目已签约】=项目本年实际签约金额
【项目预计签约】=(公司本年签约任务金额-公司本年实际签约金额)*(本项目的任务金额/未超全年任务项目的任务金额合计)
B、产品层级任务金额：
【产品全年签约金额】=产品已签约金额+产品预计签约金额
【产品已签约金额】=本年已签约金额
【产品预计签约金额】=(本项目分摊后的签约任务金额-本项目本年实际签约金额)*(产品原货量铺排任务/未超全年任务产品的任务金额合计)
C、产品层级任务面积：
【产品全年签约面积】=产品已签约面积+产品预计签约面积
【产品已签约面积】=本年已签约面积
【产品预计签约面积】=产品预计签约金额/近三个月均价，如果近三个月均价为空，则取全年已签约均价计算。

modified by lintx 20231227
1、增加单方信息以及营业成本信息

modified by lintx 20240116
1、增加本年预估利润、往年签约本年退房利润以及剩余货值实际流速版等42个字段

modified by lintx 20240337
增加除地外直投单方,开发间接费单方,资本化利息单方,盈利规划股权溢价单方

modified by lintx 20240415
1、增加累计销售盈利规划除地价外直投、累计销售盈利规划开发间接费、累计销售盈利规划资本化利息、累计销售盈利规划股权溢价、
剩余货值盈利规划除地价外直投、剩余货值盈利规划开发间接费、剩余货值盈利规划资本化利息、剩余货值盈利规划股权溢价

modified by lintx 20240829
增加本月认购

modified by lintx 20241211
增加留置单方情况
*/

BEGIN 

declare @DevelopmentCompanyGUID  varchar(max) 
--湾区公司、湖南公司、上海公司、浙南公司
set @DevelopmentCompanyGUID ='C69E89BB-A2DB-E511-80B8-E41F13C51836,461889DC-E991-4238-9D7C-B29E0AA347BB,5A4B2DEF-E803-49F8-9FE2-308735E7233D,7DF92561-3B0D-E711-80BA-E61F13C57837'  

--select * from p_DevelopmentCompany where DevelopmentCompanyName = '湖南公司'

--累计
select orgguid,
    平台公司,
    projguid,
    [产品类型],
    产品名称,	
    装修标准,	
    商品类型,
    盈利规划营业成本单方,
    盈利规划营销费用单方,
    盈利规划综合管理费单方协议口径,
    盈利规划税金及附加单方,
    除地外直投_单方,	
    开发间接费单方,	
    资本化利息单方,	
	土地款_单方,
    盈利规划股权溢价单方
    ,sum(isnull(当期签约金额,0)) as 累计签约金额
    ,sum(isnull(当期签约面积,0)) as 累计签约面积
    ,sum(isnull(当期签约金额不含税, 0)) 累计签约金额不含税
    ,sum(isnull(毛利签约, 0)) 累计销售毛利润账面
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(毛利率签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 累计销售毛利率账面
    ,sum(isnull(盈利规划营业成本签约, 0)) 累计销售盈利规划营业成本
    ,sum(isnull(盈利规划营销费用签约, 0)) 累计销售盈利规划营销费用
    ,sum(isnull(盈利规划综合管理费签约, 0)) 累计销售盈利规划综合管理费
    ,sum(isnull(盈利规划税金及附加签约, 0)) 累计销售盈利规划税金及附加
    ,sum(isnull(除地外直投_单方, 0)*case when 产品类型 = '地下室/车库' then isnull(当期签约面积,0) else  isnull(当期签约面积,0)*10000 end)/100000000.0 累计销售盈利规划除地价外直投
    ,sum(isnull(开发间接费单方, 0)*case when 产品类型 = '地下室/车库' then isnull(当期签约面积,0) else  isnull(当期签约面积,0)*10000 end)/100000000.0 累计销售盈利规划开发间接费
    ,sum(isnull(资本化利息单方, 0)*case when 产品类型 = '地下室/车库' then isnull(当期签约面积,0) else  isnull(当期签约面积,0)*10000 end)/100000000.0 累计销售盈利规划资本化利息
	,sum(isnull(土地款_单方, 0)*case when 产品类型 = '地下室/车库' then isnull(当期签约面积,0) else  isnull(当期签约面积,0)*10000 end)/100000000.0 累计销售盈利规划土地款
    ,sum(isnull(盈利规划股权溢价单方, 0)*case when 产品类型 = '地下室/车库' then isnull(当期签约面积,0) else  isnull(当期签约面积,0)*10000 end)/100000000.0 累计销售盈利规划股权溢价 
    ,sum(isnull(税前利润签约, 0)) 累计税前利润
    ,sum(isnull(所得税签约, 0)) 累计所得税
    ,sum(isnull(净利润签约, 0)) 累计净利润签约
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(净利润签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 累计销售净利率账面 
    into #lj
from s_M002业态净利毛利大底表
where versionType = '累计版' --and (当期签约金额 <> 0 or 盈利规划营业成本单方 <> 0)
group by orgguid, 平台公司, projguid,[产品类型],
    产品名称,	
    装修标准,	
    商品类型,
    盈利规划营业成本单方,
    盈利规划营销费用单方,
    盈利规划综合管理费单方协议口径,
    盈利规划税金及附加单方,
    除地外直投_单方,	
    开发间接费单方,	
    资本化利息单方,	
	土地款_单方,
    盈利规划股权溢价单方 

--insert into #lj
----考虑到部分业态可能同时存在销售及留置的情况，只需补充非销售的留置单方即可
--select do.DevelopmentCompanyGUID orgguid,
--    do.DevelopmentCompanyName 平台公司,
--    t.项目guid projguid,
--    t.[产品类型],
--    t.产品名称,	
--    t.装修标准,	
--    t.商品类型,
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(营业成本,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 盈利规划营业成本单方,
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(营销费用,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 盈利规划营销费用单方,
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(综合管理费协议口径,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 盈利规划综合管理费单方协议口径,
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(税金及附加,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 盈利规划税金及附加单方,
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(除地价外直投不含税_财务分摊,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 除地外直投_单方, 
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(开发间接费不含税_财务分摊,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 开发间接费单方,	
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(资本化利息,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 资本化利息单方,	
--	case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(土地款不含税_财务分摊,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 土地款_单方,
--    case when sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) = 0 then 0 else sum(isnull(股权溢价,0))/sum(isnull(case when t.产品类型= '地下室/车库' then  自持车位个数 else 自持面积 end,0)) end 盈利规划股权溢价单方 
--    ,0 as 累计签约金额
--    ,0 as 累计签约面积
--    ,0 as 累计签约金额不含税
--    ,0 as 累计销售毛利润账面
--    ,0 as 累计销售毛利率账面
--    ,0 as 累计销售盈利规划营业成本
--    ,0 as 累计销售盈利规划营销费用
--    ,0 as 累计销售盈利规划综合管理费
--    ,0 as 累计销售盈利规划税金及附加
--    ,0 as 累计销售盈利规划除地价外直投
--    ,0 as 累计销售盈利规划开发间接费
--    ,0 as 累计销售盈利规划资本化利息
--	,0 as 累计销售盈利规划土地款
--    ,0 as 累计销售盈利规划股权溢价 
--    ,0 as 累计税前利润
--    ,0 as 累计所得税
--    ,0 as 累计净利润签约
--    ,0 as 累计销售净利率账面  
--from [172.16.4.161].[highdata_prod].[dbo].[dw_f_ProfitCost_byyt_ylgh] t
--inner join [172.16.4.161].[highdata_prod].[dbo].data_wide_dws_mdm_Project pj on t.项目guid = pj.ProjGUID
--inner join [172.16.4.161].[highdata_prod].[dbo].data_wide_dws_s_Dimension_Organization do on do.OrgGUID = pj.BUGUID
--left join #lj lj on t.项目guid = lj.projguid and isnull(lj.产品类型,0) = isnull(t.产品类型,0) and isnull(lj.产品名称,0) = isnull(t.产品名称,0) 
--and isnull(lj.装修标准,0) = isnull(t.装修标准,0) and isnull(lj.商品类型,0) = isnull(t.商品类型,0) -- 过滤已经在销售数据中出现的单方
--where (isnull(t.自持面积,0) <>0 or isnull(自持车位个数,0)<>0) and lj.ProjGUID is null  
--group by do.DevelopmentCompanyGUID,
--    do.DevelopmentCompanyName,
--    t.项目guid,
--    t.[产品类型],
--    t.产品名称,	
--    t.装修标准,	
--    t.商品类型
 
--本年
 select
    orgguid,
    平台公司,
    projguid,
    [产品类型],
    产品名称,	
    装修标准,	
    商品类型
    ,sum(isnull(当期签约金额,0)) as 本年签约金额
    ,sum(isnull(当期签约面积,0)) as 本年签约面积
    ,sum(isnull(当期签约金额不含税, 0)) 本年签约金额不含税
    ,sum(isnull(毛利签约, 0)) 本年销售毛利润账面
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(毛利率签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 本年销售毛利率账面
    ,sum(isnull(盈利规划营业成本签约, 0)) 本年销售盈利规划营业成本
    ,sum(isnull(盈利规划营销费用签约, 0)) 本年销售盈利规划营销费用
    ,sum(isnull(盈利规划综合管理费签约, 0)) 本年销售盈利规划综合管理费
    ,sum(isnull(盈利规划税金及附加签约, 0)) 本年销售盈利规划税金及附加
    ,sum(isnull(税前利润签约, 0)) 本年税前利润
    ,sum(isnull(所得税签约, 0)) 本年所得税
    ,sum(isnull(净利润签约, 0)) 本年净利润签约
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(净利润签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 本年销售净利率账面 
into #bn
from s_M002业态净利毛利大底表
where versionType = '本年版'
group by orgguid, 平台公司, projguid,产品类型 ,
    产品名称,	
    装修标准,	
    商品类型

--去年 
select
    orgguid,
    平台公司,
    projguid,
    [产品类型],
    产品名称,	
    装修标准,	
    商品类型
    ,sum(isnull(当期签约金额,0)) as 去年签约金额
    ,sum(isnull(当期签约面积,0)) as 去年签约面积
    ,sum(isnull(当期签约金额不含税, 0)) 去年签约金额不含税
    ,sum(isnull(毛利签约, 0)) 去年销售毛利润账面
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(毛利率签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 去年销售毛利率账面
    ,sum(isnull(盈利规划营业成本签约, 0)) 去年销售盈利规划营业成本
    ,sum(isnull(盈利规划营销费用签约, 0)) 去年销售盈利规划营销费用
    ,sum(isnull(盈利规划综合管理费签约, 0)) 去年销售盈利规划综合管理费
    ,sum(isnull(盈利规划税金及附加签约, 0)) 去年销售盈利规划税金及附加
    ,sum(isnull(税前利润签约, 0)) 去年税前利润
    ,sum(isnull(所得税签约, 0)) 去年所得税
    ,sum(isnull(净利润签约, 0)) 去年净利润签约
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(净利润签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 去年销售净利率账面 
into #qn
from s_M002业态净利毛利大底表
where versionType = '去年版'
group by orgguid, 平台公司, projguid,产品类型 ,
    产品名称,	
    装修标准,	
    商品类型

--本月
select
    orgguid,
    平台公司,
    projguid,
    [产品类型],
    产品名称,	
    装修标准,	
    商品类型
    ,sum(isnull(当期签约金额,0)) as 本月签约金额
    ,sum(isnull(当期签约面积,0)) as 本月签约面积
    ,sum(isnull(当期签约金额不含税, 0)) 本月签约金额不含税
    ,sum(isnull(毛利签约, 0)) 本月销售毛利润账面
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(毛利率签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 本月销售毛利率账面
    ,sum(isnull(盈利规划营业成本签约, 0)) 本月销售盈利规划营业成本
    ,sum(isnull(盈利规划营销费用签约, 0)) 本月销售盈利规划营销费用
    ,sum(isnull(盈利规划综合管理费签约, 0)) 本月销售盈利规划综合管理费
    ,sum(isnull(盈利规划税金及附加签约, 0)) 本月销售盈利规划税金及附加
    ,sum(isnull(税前利润签约, 0)) 本月税前利润
    ,sum(isnull(所得税签约, 0)) 本月所得税
    ,sum(isnull(净利润签约, 0)) 本月净利润签约
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(净利润签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 本月销售净利率账面 
into #by
from s_M002业态净利毛利大底表
where versionType = '本月版'
group by orgguid, 平台公司,  projguid ,产品类型,
    产品名称,	
    装修标准,	
    商品类型

--本月认购版
select orgguid,
    平台公司,
    projguid,
    [产品类型],
    产品名称,	
    装修标准,	
    商品类型
    ,sum(isnull(当期认购金额,0)) as 本月认购金额
    ,sum(isnull(当期认购面积,0)) as 本月认购面积
    ,sum(isnull(当期认购金额不含税, 0)) 本月认购金额不含税
    ,sum(isnull(毛利认购, 0)) 本月认购毛利润账面
    ,case when sum(isnull(当期认购金额不含税, 0))  = 0 then 0 else sum(isnull(毛利率认购, 0))/sum(isnull(当期认购金额不含税, 0)) end 本月认购毛利率账面
    ,sum(isnull(盈利规划营业成本认购, 0)) 本月认购盈利规划营业成本
    ,sum(isnull(盈利规划营销费用认购, 0)) 本月认购盈利规划营销费用
    ,sum(isnull(盈利规划综合管理费认购, 0)) 本月认购盈利规划综合管理费
    ,sum(isnull(盈利规划税金及附加认购, 0)) 本月认购盈利规划税金及附加
    ,sum(isnull(税前利润认购, 0)) 本月认购税前利润
    ,sum(isnull(所得税认购, 0)) 本月认购所得税
    ,sum(isnull(净利润认购, 0)) 本月净利润认购
    ,case when sum(isnull(当期认购金额不含税, 0))  = 0 then 0 else sum(isnull(净利润认购, 0))/sum(isnull(当期认购金额不含税, 0)) end 本月认购净利率账面 
into #byrg
from s_M002业态净利毛利大底表
where versionType = '本月版'
group by orgguid, 平台公司,  projguid ,产品类型,
    产品名称,	
    装修标准,	
    商品类型

--上月
select orgguid,
    平台公司,
    projguid,
    [产品类型],
    产品名称,	
    装修标准,	
    商品类型
    ,sum(isnull(当期签约金额,0)) as 上月签约金额
    ,sum(isnull(当期签约面积,0)) as 上月签约面积
    ,sum(isnull(当期签约金额不含税, 0)) 上月签约金额不含税
    ,sum(isnull(毛利签约, 0)) 上月销售毛利润账面
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(毛利率签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 上月销售毛利率账面
    ,sum(isnull(盈利规划营业成本签约, 0)) 上月销售盈利规划营业成本
    ,sum(isnull(盈利规划营销费用签约, 0)) 上月销售盈利规划营销费用
    ,sum(isnull(盈利规划综合管理费签约, 0)) 上月销售盈利规划综合管理费
    ,sum(isnull(盈利规划税金及附加签约, 0)) 上月销售盈利规划税金及附加
    ,sum(isnull(税前利润签约, 0)) 上月税前利润
    ,sum(isnull(所得税签约, 0)) 上月所得税
    ,sum(isnull(净利润签约, 0)) 上月净利润签约
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(净利润签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 上月销售净利率账面 
into #lastmonth
from s_M002业态净利毛利大底表
where versionType = '拍照版' and datediff(mm, StartTime, getdate()) = 1
group by orgguid, 平台公司, projguid ,产品类型,
    产品名称,	
    装修标准,	
    商品类型

--昨日 
select
    orgguid,
    平台公司,
    projguid,
    [产品类型],
    产品名称,	
    装修标准,	
    商品类型
    ,sum(isnull(当期签约金额,0)) as 昨日签约金额
    ,sum(isnull(当期签约面积,0)) as 昨日签约面积
    ,sum(isnull(当期签约金额不含税, 0)) 昨日签约金额不含税
    ,sum(isnull(毛利签约, 0)) 昨日销售毛利润账面
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(毛利率签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 昨日销售毛利率账面
    ,sum(isnull(盈利规划营业成本签约, 0)) 昨日销售盈利规划营业成本
    ,sum(isnull(盈利规划营销费用签约, 0)) 昨日销售盈利规划营销费用
    ,sum(isnull(盈利规划综合管理费签约, 0)) 昨日销售盈利规划综合管理费
    ,sum(isnull(盈利规划税金及附加签约, 0)) 昨日销售盈利规划税金及附加
    ,sum(isnull(税前利润签约, 0)) 昨日税前利润
    ,sum(isnull(所得税签约, 0)) 昨日所得税
    ,sum(isnull(净利润签约, 0)) 昨日净利润签约
    ,case when sum(isnull(当期签约金额不含税, 0))  = 0 then 0 else sum(isnull(净利润签约, 0))/sum(isnull(当期签约金额不含税, 0)) end 昨日销售净利率账面 
into #zr
from s_M002业态净利毛利大底表
where versionType = '昨日版' 
group by orgguid, 平台公司, projguid,产品类型,
    产品名称,	
    装修标准,	
    商品类型

----------------------------------------------获取本年预计及剩余货值的毛利净利情况 bengin --------------------------------------------
--缓存项目信息表
select * 
into #mdm_project
from mdm_project 
where DevelopmentCompanyGUID IN ( SELECT Value FROM dbo.fn_Split2(@DevelopmentCompanyGUID, ','))

--取手工维护的产品匹配关系
SELECT 项目guid,
       T.基础数据主键,
       T.盈利规划系统自动匹对主键,
       CASE WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN T.盈利规划系统自动匹对主键 ELSE
        CASE WHEN ISNULL(T.盈利规划主键, '') <> '' THEN T.盈利规划主键 ELSE T.基础数据主键 END END 盈利规划主键,
        max(T.[营业成本单方(元/平方米)]) as 营业成本单方,
        max(T.[营销费用单方(元/平方米)]) as 营销费用单方,
        max(T.[综合管理费单方(元/平方米)]) as 综合管理费单方,
        max(T.[股权溢价单方(元/平方米)]) as 股权溢价单方,
        max(T.[税金及附加单方(元/平方米)]) as 税金及附加单方,
        max(T.[除地价外直投单方(元/平方米)]) as 除地价外直投单方,
        max(T.[土地款单方(元/平方米)]) as 土地款单方,
        max(T.[资本化利息单方(元/平方米)]) as 资本化利息单方,
        max(T.[开发间接费单方(元/平方米)]) as 开发间接费单方
INTO #key
FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 T
INNER JOIN
(
     SELECT ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM,
            FillHistoryGUID
     FROM dss.dbo.nmap_F_FillHistory a
     WHERE EXISTS
     (
         SELECT ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM,
            FillHistoryGUID
     FROM dss.dbo.nmap_F_FillHistory a
     WHERE EXISTS
     (
          select FillHistoryGUID,sum(case when 项目guid is null or  项目guid='' then 0 else 1 end )as num from dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 b				 		       
		 where a.FillHistoryGUID = b.FillHistoryGUID
	 group by FillHistoryGUID
	 having sum(case when 项目guid is null then 0 else 1 end )>0
     )
     )
 ) V ON T.FillHistoryGUID = V.FillHistoryGUID
        AND V.NUM = 1
where isnull(T.项目guid,'')<> ''
group by 项目guid,
       T.基础数据主键,
       T.盈利规划系统自动匹对主键,
       CASE WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN T.盈利规划系统自动匹对主键 ELSE
        CASE WHEN ISNULL(T.盈利规划主键, '') <> '' THEN T.盈利规划主键 ELSE T.基础数据主键 END END;


--设置税率表
SELECT CONVERT(DATE, '1999-01-01') AS bgnDate,
       CONVERT(DATE, '2016-03-31') AS endDate,
       0 AS rate
INTO #tmp_tax 
UNION ALL
SELECT CONVERT(DATE, '2016-04-01') AS bgnDate,
       CONVERT(DATE, '2018-04-30') AS endDate,
       0.11 AS rate
UNION ALL
SELECT CONVERT(DATE, '2018-05-01') AS bgnDate,
       CONVERT(DATE, '2019-03-31') AS endDate,
       0.1 AS rate
UNION ALL
SELECT CONVERT(DATE, '2019-04-01') AS bgnDate,
       CONVERT(DATE, '2099-01-01') AS endDate,
       0.09 AS rate;

--获取近三月签约均价
select t.ProjGUID,
t.ProductType,t.Product,t.近三个月平均签约流速,t.近三个月平均签约流速_面积,
case when isnull(近三个月平均签约流速_面积,0) = 0 then 0 else isnull(近三个月平均签约流速,0)*10000/
isnull(近三个月平均签约流速_面积,0)end as 近三月平均签约均价,
本年已签约面积,本年已签约金额,
case when isnull(本年已签约面积,0) = 0 then 0 else isnull(本年已签约金额,0)*10000/isnull(本年已签约面积,0)end as 本年已签约均价
into #qyjj
from (
select pj.ProjGUID,
    ld.ProductType,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + ld.ProductType + '_' + ld.ProductName + '_' + ld.BusinessType + '_' + ld.Standard Product,
    sum(case when ld.ProductType = '地下室/车库' then isnull(近三个月平均签约流速_套数,0) else isnull(近三个月平均签约流速_面积,0) end) as 近三个月平均签约流速_面积,
    sum(isnull(近三个月平均签约流速,0)) as 近三个月平均签约流速,
    sum(case when ld.ProductType = '地下室/车库' then isnull(本年已签约套数,0) else isnull(本年已签约面积,0) end) as 本年已签约面积,
    sum(isnull(本年已签约金额,0)) as 本年已签约金额
from ydkb_dthz_wq_deal_tradeinfo t 
inner join p_lddbamj ld on t.组织架构id = ld.salebldguid 
inner join #mdm_project pj on pj.projguid = ld.projguid
where 组织架构类型 = 6 and datediff(dd,qxdate,getdate()) = 0 
group by pj.ProjGUID,ld.ProductType,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + ld.ProductType + '_' + ld.ProductName + '_' + ld.BusinessType + '_' + ld.Standard
) t

--获取楼栋的货值单价
select a.ProjGUID,
    a.ProductType,
    a.ProductName,
    a.Standard,
    a.BusinessType,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + a.ProductType + '_' + a.ProductName + '_' + a.BusinessType + '_' + a.Standard Product,
	sum(isnull(a.syhz,0)) as 剩余货值,
	sum(case when a.ProductType = '地下室/车库' then isnull(a.zksts,0)-isnull(ysts,0) else isnull(a.zksmj,0)-isnull(ysmj,0) end) as 剩余面积
	into #hzdj
from p_lddb a
inner join #mdm_project pj on pj.ProjGUID = a.ProjGUID
where datediff(dd,qxdate,getdate()) = 0
group by a.ProjGUID,
    a.ProductType,
    a.ProductName,
    a.Standard,pj.ProjCode,
    a.BusinessType

--汇总单价情况：近三月签约均价>本年签约均价>货值单价 
select hz.ProjGUID,hz.Product,
case when isnull(近三月平均签约均价,0) = 0 then case when isnull(本年已签约均价,0) = 0 then 
(case when hz.剩余面积 = 0 then 0 else hz.剩余货值/hz.剩余面积 end)
else 本年已签约均价 end else 近三月平均签约均价 end as 签约均价, --近三月签约均价>本年签约均价>货值单价 
近三月平均签约均价  
into #final_jj_product
from  #hzdj hz
left join #qyjj qy on hz.ProjGUID = qy.ProjGUID and hz.Product = qy.Product

select hz.ProjGUID,hz.ProductType,
case when isnull(t.签约均价,0) = 0 then (case when hz.剩余面积 = 0 then 0 else hz.剩余货值/hz.剩余面积 end)  else 签约均价 end 签约均价,
近三月平均签约均价
into #final_jj_yt
from (select projguid,ProductType,sum(剩余货值) as 剩余货值,sum(剩余面积) as 剩余面积 from #hzdj group by projguid,ProductType) hz
left join (select projguid,producttype,
case when 近三月平均签约均价 = 0 then 本年已签约均价 else 近三月平均签约均价 end as 签约均价,
近三月平均签约均价
 from (
select projguid,producttype,
case when sum(isnull(本年已签约面积,0)) = 0 then 0 else sum(isnull(本年已签约金额,0))*10000/sum(isnull(本年已签约面积,0)) end as 本年已签约均价,
case when sum(isnull(近三个月平均签约流速_面积,0)) = 0 then 0 else sum(isnull(近三个月平均签约流速,0))*10000/sum(isnull(近三个月平均签约流速_面积,0)) end as 近三月平均签约均价
 from #qyjj group by projguid,producttype)t) t on hz.projguid = t.projguid and hz.ProductType = t.ProductType

--------------------------------------获取明源的剩余货值、货量铺排本年预计情况 begin -----------------------------
--统计维度，业态组合；时间维度：本年预计、剩余货值
--缓存业态组合键
SELECT  a.ProjGUID,
    a.ProductType,
    a.ProductName,
    a.Standard,
    a.BusinessType,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + a.ProductType + '_' + a.ProductName + '_' + a.BusinessType + '_' + a.Standard Product,
    sum(isnull(syhz,0)) as 楼栋底表剩余货值,
    sum(case when a.ProductType = '地下室/车库' then isnull(zksts,0) - isnull(ysts,0) else isnull(zksmj,0) - isnull(ysmj,0) end) as 楼栋底表剩余面积
into #db
FROM p_lddbamj a
inner join #mdm_project pj on pj.ProjGUID = a.projguid
WHERE DATEDIFF(DAY, a.QXDate, GETDATE()) = 0 
group by  a.ProjGUID,
    a.ProductType,
    a.ProductName,
    a.Standard,
    a.BusinessType,
	pj.ProjCode

--存在部分业态会在货量铺排中调整的情况
insert into #db
select distinct t.ProjGUID,
    t.ProductType,
    t.ProductName,
    t.BusinessType,
    t.Standard,
    t.product,
    0 as 楼栋底表剩余货值,
    0 as 楼栋底表剩余面积
from (
select distinct  pj.ProjGUID,
    pj.projcode,
    t.ProductType,
    t.ProductName,
    t.BusinessType,
    t.Standard,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + t.ProductType + '_' + t.ProductName + '_' + t.BusinessType + '_' + t.Standard Product
from s_SaleValueBuildLayout t
    inner join #mdm_project pj on pj.ProjGUID = t.projguid
union ALL
select distinct pj.ProjGUID,
    pj.projcode,
    t.ProductType,
    t.ProductName,
    t.BusinessType,
    t.Standard,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + t.ProductType + '_' + t.ProductName + '_' + t.BusinessType + '_' + t.Standard Product
from s_SaleValueBuildLayoutHistory t
    inner join #mdm_project pj on pj.ProjGUID = t.projguid
)t 
left join #db  d on t.ProjGUID = d.ProjGUID and t.Product = d.Product
where d.projguid is null

 --1、获取剩余货值情况，自动铺排从楼栋底表取，手工铺排要考虑合作特殊业绩情况，直接从湾区底表取数
SELECT a.ProjGUID,
    a.ProductType,
    a.ProductName,
    a.Standard,
    a.BusinessType,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + a.ProductType + '_' + a.ProductName + '_' + a.BusinessType + '_' + a.Standard Product,
    sum(isnull(剩余货值金额, 0)*10000) as 剩余金额,
    sum(isnull(剩余货值金额, 0)*10000) /(1 + rate) as 剩余金额不含税,
    sum(case when a.ProductType = '地下室/车库' then 剩余货值套数  else 剩余货值面积 end) as 剩余面积
INTO #ldhz_zzpp
FROM ydkb_dthz_wq_deal_salevalueinfo ld
    inner join p_lddbamj a on ld.组织架构id = a.salebldguid
    inner join #mdm_project pj on pj.ProjGUID = a.projguid
    inner join #tmp_tax on  a.QXDate BETWEEN bgnDate and endDate
WHERE ld.组织架构类型 = 6 and  DATEDIFF(DAY, a.QXDate, GETDATE()) = 0 
and ld.projguid not IN ( SELECT ProjGUID FROM s_SaleValuePlanSet WHERE  IsPricePrediction = 2 )
group by a.ProjGUID, a.ProductType,a.ProductName,a.Standard,a.BusinessType,pj.ProjCode,rate

SELECT a.组织架构父级id,
    a.组织架构名称,
    sum(isnull(剩余货值金额, 0)*10000) as 剩余金额,
    sum(isnull(剩余货值金额, 0)*10000) /(1 + rate) as 剩余金额不含税,
    sum(case when a.组织架构名称 = '地下室/车库' then 剩余货值套数  else 剩余货值面积 end) as 剩余面积
INTO #ythz_sgpp
FROM ydkb_dthz_wq_deal_salevalueinfo a
    inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate
WHERE a.组织架构类型 = 4 and a.projguid IN ( SELECT ProjGUID FROM s_SaleValuePlanSet WHERE  IsPricePrediction = 2 )
group by a.组织架构父级id, a.组织架构名称,rate

--2、获取本年预计签约情况：手工铺排+自动铺排 
--获取项目版本
select projguid,SaleValuePlanVersionGUID,isdr,ROW_NUMBER() over(partition by projguid order by approvedate desc) rn
into #ver
from s_SaleValuePlanVersion
where ApproveState = '已审核'
and  ProjGUID NOT IN ( SELECT ProjGUID FROM s_SaleValuePlanSet WHERE  IsPricePrediction = 3 )

--自动铺排，可以到产品层级
select pj.ProjGUID,
    pj.projcode,
    t.ProductType,
    t.ProductName,
    t.BusinessType,
    t.Standard,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + t.ProductType + '_' + t.ProductName + '_' + t.BusinessType + '_' + t.Standard Product,
    sum(ThisMonthSaleMoneyQy) as 本年预计签约金额,
    sum(ThisMonthSaleMoneyQy)/(1+rate) as 本年预计签约金额不含税,
    sum(ThisMonthSaleAreaQy) as 本年预计签约面积 
    into #zdpp_tmp 
from s_SaleValueBuildLayout t
    inner join #mdm_project pj on pj.ProjGUID = t.projguid
    inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate
	inner join #ver ver on ver.ProjGUID =t.ProjGUID and ver.SaleValuePlanVersionGUID = t.SaleValuePlanVersionGUID and ver.rn = 1 
where SaleValuePlanYear =year(getdate()) and IsDr = 0
    --  AND t.ProjGUID NOT IN ( SELECT ProjGUID FROM   s_SaleValuePlanSet WHERE  IsPricePrediction = 2 )--铺排方式为自动铺排
group by pj.ProjGUID,pj.projcode,t.ProductType, t.ProductName, t.BusinessType, t.Standard,rate
union all 
select pj.ProjGUID,
    pj.projcode,
    t.ProductType,
    t.ProductName,
    t.BusinessType,
    t.Standard,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + t.ProductType + '_' + t.ProductName + '_' + t.BusinessType + '_' + t.Standard Product,
    sum(ThisMonthSaleMoneyQy) as 本年预计签约金额,
    sum(ThisMonthSaleMoneyQy)/(1+rate) as 本年预计签约金额不含税,
    sum(ThisMonthSaleAreaQy) as 本年预计签约面积  
from s_SaleValueBuildLayoutHistory t
    inner join #mdm_project pj on pj.ProjGUID = t.projguid
    inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate
	inner join #ver ver on ver.ProjGUID =t.ProjGUID and ver.SaleValuePlanVersionGUID = t.SaleValuePlanVersionGUID and ver.rn = 1 
where SaleValuePlanYear =year(getdate()) and IsDr = 0
   --   AND t.ProjGUID NOT IN ( SELECT ProjGUID FROM   s_SaleValuePlanSet WHERE  IsPricePrediction = 2 )--铺排方式为自动铺排
group by pj.ProjGUID,pj.projcode,t.ProductType, t.ProductName, t.BusinessType, t.Standard,rate

--手工铺排,只能到业态层级
select pj.ProjGUID,
    pj.projcode,
    t.ProductType, 
    sum(ThisMonthSaleMoneyQy) as 本年预计签约金额,
    sum(ThisMonthSaleMoneyQy)/(1+rate) as 本年预计签约金额不含税,
    sum(ThisMonthSaleAreaQy ) as 本年预计签约面积
into #sgpp_tmp
from s_SaleValuePlan t
    inner join #mdm_project pj on pj.ProjGUID = t.projguid
    inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate 
	inner join #ver ver on ver.ProjGUID =t.ProjGUID and ver.SaleValuePlanVersionGUID = t.SaleValuePlanVersionGUID and ver.rn = 1 
where SaleValuePlanYear =year(getdate()) and IsDr =1
     -- AND t.ProjGUID IN ( SELECT ProjGUID FROM   s_SaleValuePlanSet WHERE  IsPricePrediction = 2 )--铺排方式为手工铺排
group by pj.ProjGUID, pj.projcode, t.ProductType,rate
union all 
select pj.ProjGUID,
    pj.projcode,
    t.ProductType, 
    sum(ThisMonthSaleMoneyQy) as 本年预计签约金额,
    sum(ThisMonthSaleMoneyQy)/(1+rate) as 本年预计签约金额不含税,
    sum(ThisMonthSaleAreaQy ) as 本年预计签约面积 
from s_SaleValuePlanHistory t
    inner join #mdm_project pj on pj.ProjGUID = t.projguid
    inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate 
	inner join #ver ver on ver.ProjGUID =t.ProjGUID and ver.SaleValuePlanVersionGUID = t.SaleValuePlanVersionGUID and ver.rn = 1 
where SaleValuePlanYear =year(getdate())  and IsDr =1
     -- AND t.ProjGUID IN ( SELECT ProjGUID FROM   s_SaleValuePlanSet WHERE  IsPricePrediction = 2 )--铺排方式为手工铺排
group by pj.ProjGUID, pj.projcode, t.ProductType,rate

--3、获取往年签约本年退房签约情况
select ld.ProjGUID,
    ld.ProductType,
    ld.ProductName,
    ld.Standard,
    ld.BusinessType,
    CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + ld.ProductType + '_' + ld.ProductName + '_' + ld.BusinessType + '_' + ld.Standard Product,
    sum(isnull(JyTotal, 0)) as 往年签约本年退房签约金额,
    sum(isnull(JyTotal, 0)/(1 + rate))  as 往年签约本年退房签约金额不含税,
    sum(case when ld.ProductType = '地下室/车库' then 1  else bldarea end) as 往年签约本年退房签约面积
INTO #tfsale
from dbo.s_SaleModiApply a
    inner JOIN dbo.myWorkflowProcessEntity w ON a.SaleModiApplyGUID = w.BusinessGUID
    inner join dbo.es_Contract c ON a.SaleGUID = c.ContractGUID
    inner join #mdm_project p on p.projguid = c.projguid
    inner join #mdm_project pj on pj.projguid = p.parentprojguid
    inner join p_lddbamj ld on ld.salebldguid = c.BldGUID and datediff(dd,qxdate,getdate()) = 0
    inner join #tmp_tax tax on c.qsdate BETWEEN tax.bgnDate and tax.endDate
where w.ProcessStatus IN ('0', '1', '2')
    and a.ApplyType = '退房'
    AND w.ProcessGUID IS NOT NULL
    AND datediff(yy, getdate(), a.ExecDate) = 0 
    and datediff(yy, c.QSDate, getdate()) > 0
group by ld.ProjGUID,
    ld.ProductType,
    ld.ProductName,
    ld.Standard,
    ld.BusinessType,
    pj.projcode

--4、获取剩余货值实际流速版
select a.ProjGUID,
    a.ProductType,
    a.ProductName,
    a.Standard,
    a.BusinessType,
    a.Product,
    a.剩余面积 *jj.签约均价 as 剩余金额,
    a.剩余面积*jj.签约均价 /(1 + rate) as 剩余金额不含税,
    a.剩余面积 as 剩余面积 
into #ldhz_lsb
from #ldhz_zzpp a
inner join #final_jj_product jj on a.projguid = jj.projguid and a.product = jj.product
inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate

select a.组织架构父级id,
    a.组织架构名称,
    a.剩余面积 *jj.签约均价 as 剩余金额,
    a.剩余面积*jj.签约均价 /(1 + rate) as 剩余金额不含税,
    a.剩余面积 as 剩余面积 
into #ythz_lsb
from #ythz_sgpp a
inner join #final_jj_yt jj on a.组织架构父级id = jj.projguid and a.组织架构名称 = jj.producttype
inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate

--5、获取全年预估情况：预估全年签约=本年已签约+近三个月流速预估到年底签约
--获取预估到年底的签约情况
select db.projguid,db.product,
case when isnull(yj.预估年底签约面积,0)>db.楼栋底表剩余面积 then db.楼栋底表剩余货值 else isnull(yj.预估年底签约金额,0) end+isnull(bn.本年签约金额,0) 预估全年签约金额, --本年已售+预估年底签约
(case when isnull(yj.预估年底签约面积,0)>db.楼栋底表剩余面积 then db.楼栋底表剩余货值 else isnull(yj.预估年底签约金额,0) end+ isnull(bn.本年签约金额,0))/(1+rate) 预估全年签约金额不含税,
case when isnull(yj.预估年底签约面积,0)>db.楼栋底表剩余面积 then db.楼栋底表剩余面积 else isnull(yj.预估年底签约面积,0) end+isnull(bn.本年签约面积,0) 预估全年签约面积 
into #qnyg
from #db db
left join (
    select ProjGUID,产品类型,产品名称,装修标准,商品类型,
    本年签约金额*100000000 as 本年签约金额,
    case when 产品类型 = '地下室/车库' then 本年签约面积 else 本年签约面积*10000 end as 本年签约面积
    from #bn )bn on db.ProjGUID = bn.ProjGUID and db.ProductType = bn.产品类型 and db.ProductName = bn.产品名称 
    and db.Standard = bn.装修标准
    and db.BusinessType = bn.商品类型
left join (
select a.ProjGUID,a.Product,
isnull(近三个月平均签约流速,0)/30*10000*datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') 预估年底签约金额, 
近三个月平均签约流速_面积/30*datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') 预估年底签约面积
from #qyjj a) yj on db.projguid = yj.projguid and db.product = yj.product
inner join #tmp_tax on getdate() BETWEEN bgnDate and endDate

--------------------------------判断什么时候取实际签约，什么时候取货量铺排任务 begin-----------------------------
-- 全年任务：
-- ①本年实际签约金额≥本年货量铺排任务的项目，取项目的实际签约金额和实际签约面积。
-- ②本年实际签约金额＜本年货量铺排任务的项目，用全公司货量铺排任务的差额分摊到未完成签约任务的项目及产品中，具体分摊规则如下：
-- A、项目层级任务金额：
-- 【项目全年签约任务】=项目已签约+项目预计签约
-- 【项目已签约】=项目本年实际签约金额
-- 【项目预计签约】=(公司本年签约任务金额-公司本年实际签约金额)*(本项目的任务金额/未超全年任务项目的任务金额合计)
-- B、产品层级任务金额：
-- 【产品全年签约金额】=产品已签约金额+产品预计签约金额
-- 【产品已签约金额】=本年已签约金额
-- 【产品预计签约金额】=(本项目分摊后的签约任务金额-本项目本年实际签约金额)*(产品原货量铺排任务/未超全年任务产品的任务金额合计)
-- C、产品层级任务面积：
-- 【产品全年签约面积】=产品已签约面积+产品预计签约面积
-- 【产品已签约面积】=本年已签约面积
-- 【产品预计签约面积】=产品预计签约金额/近三个月均价，如果近三个月均价为空，则取全年已签约均价计算。


--提炼信息：产品、业态、项目的本年实际签约金额面积/本年预计签约金额面积,产品、业态的任务占比,产品、业态的近三月签约均价
--项目层级的本年实际/预计签约金额
select pj.DevelopmentCompanyGUID,
    pj.projguid,
    bn.本年签约金额 项目本年实际签约金额,
    isnull(zd.本年预计签约金额, 0) + isnull(sg.本年预计签约金额, 0) 项目本年预计签约金额,
    case when bn.本年签约金额 < isnull(zd.本年预计签约金额, 0) + isnull(sg.本年预计签约金额, 0) then isnull(zd.本年预计签约金额, 0) + isnull(sg.本年预计签约金额, 0)
        else 0 end as 未超本年预计签约金额合计
into  #proj_qy_tmp 
from #mdm_project pj 
left join (select projguid, sum(本年签约金额) * 100000000 as 本年签约金额
    from #bn group by projguid) bn on bn.projguid = pj.projguid
left join ( select  projguid, sum(本年预计签约金额) as 本年预计签约金额
    from #zdpp_tmp group by projguid) zd on zd.projguid = pj.projguid
left join (select projguid,  sum(本年预计签约金额) as 本年预计签约金额
    from #sgpp_tmp group by projguid) sg on sg.projguid = pj.projguid
where pj.level = 2

--获取分摊后的本年预计签约金额
select t.projguid, 项目本年实际签约金额,项目本年预计签约金额 as 项目本年预计签约金额_分摊前,
case when 项目本年实际签约金额>=项目本年预计签约金额 then 项目本年实际签约金额 else 
(公司本年预计签约金额 - 公司本年实际签约金额) *(项目本年预计签约金额*1.0/hj.未超本年预计签约金额合计)+项目本年实际签约金额 end 项目本年预计签约金额_分摊后
into #proj_qy
from  #proj_qy_tmp T
left join (select DevelopmentCompanyGUID,sum(项目本年实际签约金额) as 公司本年实际签约金额,
sum(项目本年预计签约金额) as 公司本年预计签约金额,
sum(未超本年预计签约金额合计) 未超本年预计签约金额合计 from  #proj_qy_tmp
group by DevelopmentCompanyGUID) hj on t.DevelopmentCompanyGUID=hj.DevelopmentCompanyGUID

--获取产品层级对应的本年签约金额/面积、任务占比
--缓存各项目产品对应的未超任务的产品任务金额汇总值
select a.projguid,sum(case when a.本年预计签约金额 > bn.本年签约金额*100000000 then a.本年预计签约金额 else 0 end) as 未超本年预计签约金额产品合计
into #cp_hj_qy
from #zdpp_tmp A
left join #bn bn on a.ProjGUID = bn.ProjGUID and a.ProductType = bn.产品类型 and a.ProductName = bn.产品名称 
    and a.Standard = bn.装修标准
    and a.BusinessType = bn.商品类型
group by a.projguid

select a.projguid,
    a.product,
    proj.项目本年实际签约金额,
    proj.项目本年预计签约金额_分摊前,
    proj.项目本年预计签约金额_分摊后,
    a.本年预计签约金额,
    a.本年预计签约金额不含税,
    a.本年预计签约面积,
    bn.本年签约金额 * 100000000 as 本年实际签约金额,
    bn.本年签约金额不含税 * 100000000 as 本年实际签约金额不含税,
    case when a.producttype = '地下室/车库' then bn.本年签约面积 else bn.本年签约面积*10000 end as 本年实际签约面积,
    case when isnull(proj.项目本年预计签约金额_分摊前, 0) = 0 or a.本年预计签约金额<= bn.本年签约金额*100000000 then 0 
	else a.本年预计签约金额*1.00000000 / cphj.未超本年预计签约金额产品合计 end as 任务占比,
    case when isnull(a.本年预计签约金额, 0) < isnull(bn.本年签约金额, 0) * 100000000 then 1 else 0 end as 存在实际大于任务
    into #zdpp_tmp1
from #zdpp_tmp A
    left join #proj_qy proj on proj.projguid = a.projguid
	left join #cp_hj_qy cphj on cphj.ProjGUID = a.ProjGUID
    left join #bn bn on a.ProjGUID = bn.ProjGUID and a.ProductType = bn.产品类型 and a.ProductName = bn.产品名称 
    and a.Standard = bn.装修标准
    and a.BusinessType = bn.商品类型

--获取业态层级对应的本年签约金额/面积、任务占比
--缓存各项目业态对应的未超任务的业态任务金额汇总值
select a.projguid,sum(case when a.本年预计签约金额 > bn.本年签约金额*100000000 then a.本年预计签约金额 else 0 end) as 未超本年预计签约金额产品合计
into #yt_hj_qy
from #sgpp_tmp A
left join (select projguid,产品类型,sum(本年签约面积) as 本年签约面积,sum(本年签约金额) as 本年签约金额,
	sum(本年签约金额不含税) as 本年签约金额不含税 
    from #bn group by projguid,产品类型) bn on a.projguid = bn.projguid and a.ProductType = bn.产品类型
group by a.projguid

select a.projguid,
    a.ProductType,
    proj.项目本年实际签约金额,
    proj.项目本年预计签约金额_分摊前,
    proj.项目本年预计签约金额_分摊后,
    a.本年预计签约金额,
    a.本年预计签约金额不含税,
    a.本年预计签约面积,
    bn.本年签约金额 * 100000000 as 本年实际签约金额,
    bn.本年签约金额不含税 * 100000000 as 本年实际签约金额不含税,
    case when a.producttype = '地下室/车库' then bn.本年签约面积 else bn.本年签约面积*10000 end as 本年实际签约面积,
    case when isnull(proj.项目本年预计签约金额_分摊前, 0) = 0 or isnull(a.本年预计签约金额,0)<= isnull(bn.本年签约金额 * 100000000,0)
	then 0 else a.本年预计签约金额*1.00000000  / ythj.未超本年预计签约金额产品合计 end as 任务占比,
    case when isnull(a.本年预计签约金额, 0) < isnull(bn.本年签约金额, 0) * 100000000 then 1 else 0 end as 存在实际大于任务
    into #sgpp_tmp1
from #sgpp_tmp A
	left join #yt_hj_qy ythj on ythj.ProjGUID = a.ProjGUID
    left join #proj_qy proj on proj.projguid = a.projguid
    left join (select projguid,产品类型,sum(本年签约面积) as 本年签约面积,sum(本年签约金额) as 本年签约金额,
	sum(本年签约金额不含税) as 本年签约金额不含税 
    from #bn group by projguid,产品类型) bn on a.projguid = bn.projguid and a.ProductType = bn.产品类型 


--汇总以上情况进行最终判定取值
 --产品
select t.projguid, t.product,
case when t.项目本年实际签约金额>=t.项目本年预计签约金额_分摊前 then t.本年实际签约金额 
--本年实际签约金额＜本年货量铺排任务的项目
when t.本年实际签约金额>=t.本年预计签约金额 then t.本年实际签约金额
else t.本年实际签约金额+(t.项目本年预计签约金额_分摊后-t.项目本年实际签约金额)*t.任务占比 end 本年预计签约金额,
case when t.项目本年实际签约金额>=t.项目本年预计签约金额_分摊前 then t.本年实际签约金额不含税
--本年实际签约金额＜本年货量铺排任务的项目
when t.本年实际签约金额>=t.本年预计签约金额 then t.本年实际签约金额不含税
else t.本年实际签约金额不含税+(t.项目本年预计签约金额_分摊后-t.项目本年实际签约金额)*t.任务占比/(1.09) end 本年预计签约金额不含税,
case when t.项目本年实际签约金额>=t.项目本年预计签约金额_分摊前 then t.本年实际签约面积
--本年实际签约金额＜本年货量铺排任务的项目
when t.本年实际签约金额>=t.本年预计签约金额 then t.本年实际签约面积
else t.本年实际签约面积+case when jj.签约均价 = 0 then 0 else (t.项目本年预计签约金额_分摊后-t.项目本年实际签约金额)*t.任务占比/jj.签约均价 end end 本年预计签约面积 
into #zdpp
from #zdpp_tmp1 t
left join #final_jj_product jj on t.projguid = jj.projguid and t.product = jj.product
union all
--补充尾盘不铺排的场景，但是产生了实际签约金额的数据
select bn.projguid, 
CONVERT(VARCHAR(MAX), pj.ProjCode) + '_' + bn.产品类型 + '_' + bn.产品名称 + '_' + bn.商品类型 + '_' + bn.装修标准 product,
bn.本年签约金额 * 100000000 本年预计签约金额,
bn.本年签约金额不含税 * 100000000 本年预计签约金额不含税,
case when bn.产品类型 = '地下室/车库' then bn.本年签约面积 else bn.本年签约面积*10000 end  本年预计签约面积
from #bn bn
inner join #mdm_project pj on bn.projguid = pj.projguid
where bn.本年签约金额<> 0 and bn.ProjGUID IN ( SELECT ProjGUID FROM   s_SaleValuePlanSet WHERE  IsPricePrediction = 3 )


--业态
select t.projguid, t.producttype,
case when t.项目本年实际签约金额>=t.项目本年预计签约金额_分摊前 then t.本年实际签约金额 
--本年实际签约金额＜本年货量铺排任务的项目
when t.本年实际签约金额>=t.本年预计签约金额 then t.本年实际签约金额
else t.本年实际签约金额+(t.项目本年预计签约金额_分摊后-t.项目本年实际签约金额)*t.任务占比 end 本年预计签约金额,
case when t.项目本年实际签约金额>=t.项目本年预计签约金额_分摊前 then t.本年实际签约金额不含税
--本年实际签约金额＜本年货量铺排任务的项目
when t.本年实际签约金额>=t.本年预计签约金额 then t.本年实际签约金额不含税
else t.本年实际签约金额不含税+(t.项目本年预计签约金额_分摊后-t.项目本年实际签约金额)*t.任务占比/(1.09) end 本年预计签约金额不含税,
case when t.项目本年实际签约金额>=t.项目本年预计签约金额_分摊前 then t.本年实际签约面积
--本年实际签约金额＜本年货量铺排任务的项目
when t.本年实际签约金额>=t.本年预计签约金额 then t.本年实际签约面积
else t.本年实际签约面积+case when jj.签约均价 = 0 then 0 else (t.项目本年预计签约金额_分摊后-t.项目本年实际签约金额)*t.任务占比/jj.签约均价 end end 本年预计签约面积 
into #sgpp
from #sgpp_tmp1 t
left join #final_jj_yt jj on t.projguid = jj.projguid and t.producttype = jj.ProductType
--判断是否存在业态的实际签约金额大于货量铺排任务的
left join (select distinct projguid from #sgpp_tmp1 where 存在实际大于任务 = 1) yt on yt.projguid = t.projguid


--------------------------------判断什么时候取实际签约，什么时候取货量铺排任务 end-----------------------------

--汇总情况
  select a.projguid,'自动铺排' 统计维度, a.ProductType,
    a.ProductName, a.Standard, a.BusinessType,
    ISNULL(dss.盈利规划主键, a.Product) as Product,
    sum(isnull(剩余金额,0)) as 剩余金额,
    sum(isnull(剩余金额不含税,0)) as 剩余金额不含税,
    sum(isnull(剩余面积,0)) as 剩余面积 ,
    sum(isnull(本年预计签约金额,0)) as 本年预计签约金额,
    sum(isnull(本年预计签约金额不含税,0)) as 本年预计签约金额不含税,
    sum(isnull(本年预计签约面积,0)) as 本年预计签约面积,
    sum(isnull(预估全年签约金额,0)) as 预估全年签约金额,
    sum(isnull(预估全年签约金额不含税,0)) as 预估全年签约金额不含税,
    sum(isnull(预估全年签约面积,0)) as 预估全年签约面积,
    sum(isnull(往年签约本年退房签约金额,0)) as 往年签约本年退房签约金额,
    sum(isnull(往年签约本年退房签约金额不含税,0)) as 往年签约本年退房签约金额不含税,
    sum(isnull(往年签约本年退房签约面积,0)) as 往年签约本年退房签约面积,
    sum(isnull(剩余货值实际流速版签约金额,0)) as 剩余货值实际流速版签约金额,
    sum(isnull(剩余货值实际流速版签约金额不含税,0)) as 剩余货值实际流速版签约金额不含税,
    sum(isnull(剩余货值实际流速版签约面积,0)) as 剩余货值实际流速版签约面积
into #sale
from (select a.projguid,
    a.ProductType,
    a.ProductName,
    a.Standard,
    a.BusinessType,
    a.Product, 
    sum(isnull(hz.剩余金额,0)) as 剩余金额,
    sum(isnull(hz.剩余金额不含税,0)) as 剩余金额不含税,
    sum(isnull(hz.剩余面积,0)) as 剩余面积 ,
    sum(isnull(zd.本年预计签约金额,0)) as 本年预计签约金额,
    sum(isnull(zd.本年预计签约金额不含税,0)) as 本年预计签约金额不含税,
    sum(isnull(zd.本年预计签约面积,0)) as 本年预计签约面积,
    sum(isnull(tf.往年签约本年退房签约金额,0)) as 往年签约本年退房签约金额,
    sum(isnull(tf.往年签约本年退房签约金额不含税,0)) as 往年签约本年退房签约金额不含税,
    sum(isnull(tf.往年签约本年退房签约面积,0)) as 往年签约本年退房签约面积,
    sum(isnull(lsb.剩余金额,0)) as 剩余货值实际流速版签约金额,
    sum(isnull(lsb.剩余金额不含税,0)) as 剩余货值实际流速版签约金额不含税,
    sum(isnull(lsb.剩余面积,0)) as 剩余货值实际流速版签约面积,
    sum(isnull(yg.预估全年签约金额,0)) as 预估全年签约金额,
    sum(isnull(yg.预估全年签约金额不含税,0)) as 预估全年签约金额不含税,
    sum(isnull(yg.预估全年签约面积,0)) as 预估全年签约面积
from #db a
left join #zdpp  zd on a.projguid = zd.projguid and a.product = zd.product
left join #ldhz_zzpp hz on hz.projguid = a.projguid and a.product = hz.product
left join #ldhz_lsb lsb on lsb.projguid = a.projguid and a.product = lsb.product
left join #tfsale tf on a.projguid = tf.projguid and a.product = tf.product
left join #qnyg yg on a.projguid = yg.projguid and a.product = yg.product
group by a.projguid,
    a.ProductType,
    a.ProductName,
    a.Standard,
    a.BusinessType,
    a.Product 
	) a
LEFT JOIN ( SELECT  distinct k.项目guid, k.基础数据主键, k.盈利规划主键
        FROM #key k) dss ON dss.项目guid = a.ProjGUID AND dss.基础数据主键 = a.Product 
group by a.projguid, a.ProductType,  a.ProductName,  a.Standard,  a.BusinessType,ISNULL(dss.盈利规划主键, a.Product)
union all 
select a.projguid, '手工铺排' 统计维度,a.ProductType,
    null ProductName, null Standard, null BusinessType, 
    a.ProductType as Product,
    sum(isnull(剩余金额,0)) as 剩余金额,
    sum(isnull(剩余金额不含税,0)) as 剩余金额不含税,
    sum(isnull(剩余面积,0)) as 剩余面积 ,
    sum(isnull(本年预计签约金额,0)) as 本年预计签约金额,
    sum(isnull(本年预计签约金额不含税,0)) as 本年预计签约金额不含税,
    sum(isnull(本年预计签约面积,0)) as 本年预计签约面积,
    0 as 预估全年签约金额,
    0 as 预估全年签约金额不含税,
    0 as 预估全年签约面积,
    0 as 往年签约本年退房签约金额,
    0 as 往年签约本年退房签约金额不含税,
    0 as 往年签约本年退房签约面积,
    sum(isnull(剩余货值实际流速版签约金额,0)) as 剩余货值实际流速版签约金额,
    sum(isnull(剩余货值实际流速版签约金额不含税,0)) as 剩余货值实际流速版签约金额不含税,
    sum(isnull(剩余货值实际流速版签约面积,0)) as 剩余货值实际流速版签约面积
from (select a.projguid,
    a.ProductType,
    isnull(hz.剩余金额,0) as 剩余金额,
    isnull(hz.剩余金额不含税,0) as 剩余金额不含税,
    isnull(hz.剩余面积,0) as 剩余面积 ,
    isnull(sg.本年预计签约金额,0) as 本年预计签约金额,
    isnull(sg.本年预计签约金额不含税,0) as 本年预计签约金额不含税,
    isnull(sg.本年预计签约面积,0) as 本年预计签约面积,
    isnull(lsb.剩余金额,0) as 剩余货值实际流速版签约金额,
    isnull(lsb.剩余金额不含税,0) as 剩余货值实际流速版签约金额不含税,
    isnull(lsb.剩余面积,0) as 剩余货值实际流速版签约面积
from (select projguid,ProductType from #db group by projguid,ProductType) a 
left join #sgpp sg on a.projguid = sg.projguid and a.ProductType = sg.ProductType
left join #ythz_sgpp hz on a.projguid = hz.组织架构父级ID and a.ProductType = hz.组织架构名称 
left join #ythz_lsb lsb on a.projguid = lsb.组织架构父级ID and a.ProductType = lsb.组织架构名称 
) a
group by a.projguid, a.ProductType


--------------------------------------获取明源的剩余货值、货量铺排本年预计情况 end   -----------------------------  

--------------------------------------获取盈利规划的单方信息 begin -----------------------------

--获取产品层级的单方信息
SELECT DISTINCT k.[项目guid], -- 避免重复
       ylgh.产品类型, 
       k.盈利规划主键 业态组合键,
       ylgh.总可售面积 AS 盈利规划总可售面积,
       case when isnull(k.营业成本单方,0) = 0 then ylgh.盈利规划营业成本单方 else k.营业成本单方 end as 盈利规划营业成本单方,
       case when isnull(k.土地款单方,0) = 0 then ylgh.土地款_单方 else k.土地款单方 end  土地款_单方,
       case when isnull(k.除地价外直投单方,0) = 0 then ylgh.除地外直投_单方  else k.除地价外直投单方 end as 除地外直投_单方,
       case when isnull(k.开发间接费单方,0) = 0 then ylgh.开发间接费单方 else k.开发间接费单方 end as 开发间接费单方,
       case when isnull(k.资本化利息单方,0) = 0 then ylgh.资本化利息单方 else k.资本化利息单方 end  as 资本化利息单方,
       case when isnull(k.股权溢价单方,0) = 0 then ylgh.股权溢价单方 else k.股权溢价单方 end as 盈利规划股权溢价单方,
       case when isnull(k.营销费用单方,0) = 0 then ylgh.营销费用单方 else k.营销费用单方 end as 盈利规划营销费用单方,
       case when isnull(k.综合管理费单方,0) = 0 then ylgh.管理费用单方 else k.综合管理费单方 end as 盈利规划综合管理费单方协议口径,
       case when isnull(k.税金及附加单方,0) = 0 then ylgh.税金及附加单方 else k.税金及附加单方 end as  盈利规划税金及附加单方
INTO #df
FROM #key k
     LEFT JOIN dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh ON ylgh.匹配主键 = k.盈利规划主键
                         AND ylgh.[项目guid] = k.项目guid

--获取业态层级的单方信息，通过产品层级的费用汇总之后再除以总可售面积
insert into #df
SELECT ylgh.[项目guid], -- 避免重复 
       ylgh.产品类型,
       ylgh.产品类型,
       sum(isnull(ylgh.盈利规划总可售面积,0)) AS 盈利规划总可售面积,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.盈利规划营业成本单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end as 盈利规划营业成本单方,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.土地款_单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 土地款单方,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.除地外直投_单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 除地外直投_单方,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.开发间接费单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 开发间接费单方,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.资本化利息单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 资本化利息单方,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.盈利规划股权溢价单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 盈利规划股权溢价单方,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.盈利规划营销费用单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 盈利规划营销费用单方,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.盈利规划综合管理费单方协议口径,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 盈利规划综合管理费单方协议口径,
       case when sum(isnull(ylgh.盈利规划总可售面积,0)) = 0 then 0 else sum(isnull(ylgh.盈利规划税金及附加单方,0)*isnull(ylgh.盈利规划总可售面积,0))/sum(ylgh.盈利规划总可售面积) end  as 盈利规划税金及附加单方
FROM #df ylgh
group by ylgh.[项目guid], ylgh.产品类型
--------------------------------------获取盈利规划的单方信息 end -----------------------------     

--------------------------------------计算成本情况 begin -----------------------------
--计算项目成本
SELECT a.ProjGUID,
       --a.MyProduct,
       a.Product,
       a.ProductType,
       a.ProductName,
       a.Standard,
       a.BusinessType,
       a.统计维度,
       y.盈利规划营业成本单方,
       y.土地款_单方,
       y.除地外直投_单方,
       y.开发间接费单方,
       y.资本化利息单方,
       y.盈利规划股权溢价单方,
       y.盈利规划营销费用单方,
       y.盈利规划综合管理费单方协议口径,
       y.盈利规划税金及附加单方,
       a.剩余金额,
       a.剩余金额不含税,
       a.剩余面积 ,
       a.本年预计签约金额,
       a.本年预计签约金额不含税,
       a.本年预计签约面积,
       a.预估全年签约金额,
       a.预估全年签约金额不含税,
       a.预估全年签约面积,
       a.往年签约本年退房签约金额,
       a.往年签约本年退房签约金额不含税,
       a.往年签约本年退房签约面积,
       a.剩余货值实际流速版签约金额,
       a.剩余货值实际流速版签约金额不含税,
       a.剩余货值实际流速版签约面积,

       y.盈利规划营业成本单方 * ISNULL(a.剩余面积, 0) 盈利规划营业成本剩余货值,
       y.盈利规划股权溢价单方 * ISNULL(a.剩余面积, 0) 盈利规划股权溢价剩余货值,
       y.盈利规划营销费用单方 * ISNULL(a.剩余面积, 0) 盈利规划营销费用剩余货值,
       y.盈利规划综合管理费单方协议口径 * ISNULL(a.剩余面积, 0) 盈利规划综合管理费剩余货值,
       y.除地外直投_单方 * ISNULL(a.剩余面积, 0) 盈利规划除地价外直投剩余货值,
       y.开发间接费单方 * ISNULL(a.剩余面积, 0) 盈利规划开发间接费剩余货值,
       y.资本化利息单方 * ISNULL(a.剩余面积, 0) 盈利规划资本化利息剩余货值, 
	   y.土地款_单方 * ISNULL(a.剩余面积, 0) 盈利规划土地款剩余货值, 

       y.盈利规划税金及附加单方 * ISNULL(a.剩余面积, 0) 盈利规划税金及附加剩余货值,
       y.盈利规划营业成本单方 * ISNULL(a.本年预计签约面积, 0) 盈利规划营业成本本年预计,
       y.盈利规划股权溢价单方 * ISNULL(a.本年预计签约面积, 0) 盈利规划股权溢价本年预计,
       y.盈利规划营销费用单方 * ISNULL(a.本年预计签约面积, 0) 盈利规划营销费用本年预计,
       y.盈利规划综合管理费单方协议口径 * ISNULL(a.本年预计签约面积, 0) 盈利规划综合管理费本年预计,
       y.盈利规划税金及附加单方 * ISNULL(a.本年预计签约面积, 0) 盈利规划税金及附加本年预计,
	   y.土地款_单方 * ISNULL(a.本年预计签约面积, 0) 盈利规划土地款本年预计,
       
       y.盈利规划营业成本单方 * ISNULL(a.预估全年签约面积, 0) 盈利规划营业成本预估全年,
       y.盈利规划股权溢价单方 * ISNULL(a.预估全年签约面积, 0) 盈利规划股权溢价预估全年,
       y.盈利规划营销费用单方 * ISNULL(a.预估全年签约面积, 0) 盈利规划营销费用预估全年,
       y.盈利规划综合管理费单方协议口径 * ISNULL(a.预估全年签约面积, 0) 盈利规划综合管理费预估全年,
       y.盈利规划税金及附加单方 * ISNULL(a.预估全年签约面积, 0) 盈利规划税金及附加预估全年,
	   y.土地款_单方 * ISNULL(a.预估全年签约面积, 0) 盈利规划土地款预估全年,
       
       y.盈利规划营业成本单方 * ISNULL(a.往年签约本年退房签约面积, 0) 盈利规划营业成本往年签约本年退房,
       y.盈利规划股权溢价单方 * ISNULL(a.往年签约本年退房签约面积, 0) 盈利规划股权溢价往年签约本年退房,
       y.盈利规划营销费用单方 * ISNULL(a.往年签约本年退房签约面积, 0) 盈利规划营销费用往年签约本年退房,
       y.盈利规划综合管理费单方协议口径 * ISNULL(a.往年签约本年退房签约面积, 0) 盈利规划综合管理费往年签约本年退房,
       y.盈利规划税金及附加单方 * ISNULL(a.往年签约本年退房签约面积, 0) 盈利规划税金及附加往年签约本年退房, 
	   y.土地款_单方 * ISNULL(a.往年签约本年退房签约面积, 0) 盈利规划土地款往年签约本年退房,

       y.盈利规划营业成本单方 * ISNULL(a.剩余货值实际流速版签约面积, 0) 盈利规划营业成本剩余货值实际流速版,
       y.盈利规划股权溢价单方 * ISNULL(a.剩余货值实际流速版签约面积, 0) 盈利规划股权溢价剩余货值实际流速版,
       y.盈利规划营销费用单方 * ISNULL(a.剩余货值实际流速版签约面积, 0) 盈利规划营销费用剩余货值实际流速版,
       y.盈利规划综合管理费单方协议口径 * ISNULL(a.剩余货值实际流速版签约面积, 0) 盈利规划综合管理费剩余货值实际流速版,
       y.盈利规划税金及附加单方 * ISNULL(a.剩余货值实际流速版签约面积, 0) 盈利规划税金及附加剩余货值实际流速版,
	   y.土地款_单方 * ISNULL(a.剩余货值实际流速版签约面积, 0) 盈利规划土地款剩余货值实际流速版
INTO #cost
FROM #sale a
     LEFT JOIN #df y ON a.ProjGUID = y.[项目guid]  AND a.Product = y.业态组合键  
 
 
SELECT c.ProjGUID,
       SUM(CONVERT( DECIMAL(36, 8),((isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0)) - isnull(c.盈利规划营销费用剩余货值,0)
        - isnull(c.盈利规划综合管理费剩余货值,0) - isnull(c.盈利规划税金及附加剩余货值,0)))) 项目税前利润剩余货值,
       SUM(CONVERT( DECIMAL(36, 8),((isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0)) - isnull(c.盈利规划营销费用本年预计,0)
        - isnull(c.盈利规划综合管理费本年预计,0) - isnull(c.盈利规划税金及附加本年预计,0)))) 项目税前利润本年预计,
       
       SUM(CONVERT( DECIMAL(36, 8),((isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0)) - isnull(c.盈利规划营销费用预估全年,0)
        - isnull(c.盈利规划综合管理费预估全年,0) - isnull(c.盈利规划税金及附加预估全年,0)))) 项目税前利润预估全年,
       SUM(CONVERT( DECIMAL(36, 8),((isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0)) - isnull(c.盈利规划营销费用往年签约本年退房,0)
        - isnull(c.盈利规划综合管理费往年签约本年退房,0) - isnull(c.盈利规划税金及附加往年签约本年退房,0)))) 项目税前利润往年签约本年退房,
        SUM(CONVERT( DECIMAL(36, 8),((isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0)) - isnull(c.盈利规划营销费用剩余货值实际流速版,0)
        - isnull(c.盈利规划综合管理费剩余货值实际流速版,0) - isnull(c.盈利规划税金及附加剩余货值实际流速版,0)))) 项目税前利润剩余货值实际流速版
INTO #xm
FROM #cost c --统计项目层级的税前利润
GROUP BY c.ProjGUID;     
--------------------------------------计算成本情况 end -------------------------------

--------------------------------------计算利润情况 begin -------------------------------
SELECT p.DevelopmentCompanyGUID OrgGuid,
    p.ProjGUID, 
    c.ProductType 产品类型,
    c.ProductName 产品名称,
    c.Standard 装修标准,
    c.BusinessType 商品类型,
    --c.MyProduct 明源匹配主键,
    c.Product 业态组合键,
    --收入
    CONVERT(   DECIMAL(36, 8),
               CASE
                   WHEN c.Product LIKE '%地下室/车库%' THEN c.剩余面积 ELSE c.剩余面积 / 10000 END
           ) 剩余面积,
    CONVERT(DECIMAL(36, 8), c.剩余金额 / 100000000) 当期剩余货值金额,
    CONVERT(DECIMAL(36, 8), c.剩余金额不含税 / 100000000) 当期剩余货值金额不含税,
    CONVERT(   DECIMAL(36, 8),
               CASE
                   WHEN c.Product LIKE '%地下室/车库%' THEN c.本年预计签约面积 ELSE c.本年预计签约面积 / 10000 END
           ) 当期本年预计面积,
    CONVERT(DECIMAL(36, 8), c.本年预计签约金额 / 100000000) 当期本年预计金额,
    CONVERT(DECIMAL(36, 8), c.本年预计签约金额不含税 / 100000000) 当期本年预计金额不含税,

    CONVERT(   DECIMAL(36, 8),
               CASE
                   WHEN c.Product LIKE '%地下室/车库%' THEN c.预估全年签约面积 ELSE c.预估全年签约面积 / 10000 END
           ) 预估全年签约面积,
    CONVERT(DECIMAL(36, 8), c.预估全年签约金额 / 100000000) 当期预估全年签约金额,
    CONVERT(DECIMAL(36, 8), c.预估全年签约金额不含税 / 100000000) 当期预估全年签约金额不含税,

    CONVERT(   DECIMAL(36, 8),
               CASE
                   WHEN c.Product LIKE '%地下室/车库%' THEN c.往年签约本年退房签约面积 ELSE c.往年签约本年退房签约面积 / 10000 END
           ) 往年签约本年退房签约面积,
    CONVERT(DECIMAL(36, 8), c.往年签约本年退房签约金额 / 100000000) 当期往年签约本年退房签约金额,
    CONVERT(DECIMAL(36, 8), c.往年签约本年退房签约金额不含税 / 100000000) 当期往年签约本年退房签约金额不含税,
    
    CONVERT(   DECIMAL(36, 8),
               CASE
                   WHEN c.Product LIKE '%地下室/车库%' THEN c.剩余货值实际流速版签约面积 ELSE c.剩余货值实际流速版签约面积 / 10000 END
           ) 剩余货值实际流速版签约面积,
    CONVERT(DECIMAL(36, 8), c.剩余货值实际流速版签约金额 / 100000000) 当期剩余货值实际流速版签约金额,
    CONVERT(DECIMAL(36, 8), c.剩余货值实际流速版签约金额不含税 / 100000000) 当期剩余货值实际流速版签约金额不含税, 
    --单方
    c.盈利规划营业成本单方,
    c.土地款_单方,
    c.除地外直投_单方,
    c.开发间接费单方,
    c.资本化利息单方,
    c.盈利规划股权溢价单方,
    c.盈利规划营销费用单方,
    c.盈利规划综合管理费单方协议口径,
    c.盈利规划税金及附加单方,
    --剩余货值成本利润
    CONVERT(DECIMAL(36, 8), c.盈利规划营业成本剩余货值 / 100000000) 盈利规划营业成本剩余货值,
    CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价剩余货值 / 100000000) 盈利规划股权溢价剩余货值,
    CONVERT(DECIMAL(36, 8), (isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0) - isnull(c.盈利规划股权溢价剩余货值,0)) / 100000000) 毛利剩余货值,
    CONVERT( DECIMAL(36, 8),  CASE WHEN c.剩余金额不含税 <> 0 THEN
               (isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0) - isnull(c.盈利规划股权溢价剩余货值,0)) / isnull(c.剩余金额不含税,0) END
           ) 毛利率剩余货值,
    CONVERT(DECIMAL(36, 8), c.盈利规划营销费用剩余货值 / 100000000) 盈利规划营销费用剩余货值,
    CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费剩余货值 / 100000000) 盈利规划综合管理费剩余货值,
    CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加剩余货值 / 100000000) 盈利规划税金及附加剩余货值, 

    CONVERT(DECIMAL(36, 8), c.盈利规划除地价外直投剩余货值 / 100000000) 盈利规划除地价外直投剩余货值,
    CONVERT(DECIMAL(36, 8), c.盈利规划开发间接费剩余货值 / 100000000) 盈利规划开发间接费剩余货值,
    CONVERT(DECIMAL(36, 8), c.盈利规划资本化利息剩余货值 / 100000000) 盈利规划资本化利息剩余货值,  
	CONVERT(DECIMAL(36, 8), c.盈利规划土地款剩余货值 / 100000000) 盈利规划土地款剩余货值, 

    CONVERT( DECIMAL(36, 8),
            ((isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0)) - isnull(c.盈利规划营销费用剩余货值,0) - 
            isnull(c.盈利规划综合管理费剩余货值,0) - isnull(c.盈利规划税金及附加剩余货值,0)) / 100000000 ) 税前利润剩余货值,
    CASE WHEN isnull(x.项目税前利润剩余货值,0) > 0 THEN CONVERT(DECIMAL(36, 8),
                ((isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0)) - isnull(c.盈利规划营销费用剩余货值,0)
                 - isnull(c.盈利规划综合管理费剩余货值,0) - isnull(c.盈利规划税金及附加剩余货值,0)) / 100000000 * 0.25 ) ELSE 0.0 END 所得税剩余货值,
    CONVERT(DECIMAL(36, 8),
            ((isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0) - isnull(c.盈利规划股权溢价剩余货值,0))
             - isnull(c.盈利规划营销费用剩余货值,0) - isnull(c.盈利规划综合管理费剩余货值,0) - isnull(c.盈利规划税金及附加剩余货值,0))
            / 100000000) - CASE WHEN isnull(x.项目税前利润剩余货值,0) > 0 THEN CONVERT( DECIMAL(36, 8),
        ((isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0)) - isnull(c.盈利规划营销费用剩余货值,0) - 
        isnull(c.盈利规划综合管理费剩余货值,0) - isnull(c.盈利规划税金及附加剩余货值,0) ) / 100000000 * 0.25 ) ELSE 0.0 END 净利润剩余货值,
    CONVERT( DECIMAL(36, 8), CASE WHEN isnull(c.剩余金额不含税,0) <> 0 THEN (CONVERT(DECIMAL(36, 8),
        ((isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0) - isnull(c.盈利规划股权溢价剩余货值,0)) - isnull(c.盈利规划营销费用剩余货值,0)
         - isnull(c.盈利规划综合管理费剩余货值,0) - isnull(c.盈利规划税金及附加剩余货值,0))) - CASE WHEN isnull(x.项目税前利润剩余货值,0) > 0 THEN
         CONVERT( DECIMAL(36, 8), ((isnull(c.剩余金额不含税,0) - isnull(c.盈利规划营业成本剩余货值,0)) - isnull(c.盈利规划营销费用剩余货值,0)-
          isnull(c.盈利规划综合管理费剩余货值,0) - isnull(c.盈利规划税金及附加剩余货值,0)) * 0.25) ELSE 0.0 END ) / isnull(c.剩余金额不含税,0) END ) 销售净利率剩余货值,
    --本年预计成本利润
    CONVERT(DECIMAL(36, 8), isnull(c.盈利规划营业成本本年预计,0) / 100000000) 盈利规划营业成本本年预计,
    CONVERT(DECIMAL(36, 8), isnull(c.盈利规划股权溢价本年预计,0) / 100000000) 盈利规划股权溢价本年预计,
    CONVERT(DECIMAL(36, 8), (isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0) - isnull(c.盈利规划股权溢价本年预计,0)) / 100000000) 毛利本年预计,
    CONVERT(DECIMAL(36, 8),CASE WHEN isnull(c.本年预计签约金额不含税,0) <> 0 THEN (isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0) - isnull(c.盈利规划股权溢价本年预计,0)) / isnull(c.本年预计签约金额不含税,0) END ) 毛利率本年预计,
    CONVERT(DECIMAL(36, 8), isnull(c.盈利规划营销费用本年预计,0) / 100000000) 盈利规划营销费用本年预计,
    CONVERT(DECIMAL(36, 8), isnull(c.盈利规划综合管理费本年预计,0) / 100000000) 盈利规划综合管理费本年预计,
    CONVERT(DECIMAL(36, 8), isnull(c.盈利规划税金及附加本年预计,0) / 100000000) 盈利规划税金及附加本年预计,
    CONVERT(DECIMAL(36, 8),((isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0)) - isnull(c.盈利规划营销费用本年预计,0) - isnull(c.盈利规划综合管理费本年预计,0) 
    - isnull(c.盈利规划税金及附加本年预计,0)) / 100000000) 税前利润本年预计,
    CASE WHEN isnull(x.项目税前利润本年预计,0) > 0 THEN CONVERT(DECIMAL(36, 8),
        ((isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0)) - isnull(c.盈利规划营销费用本年预计,0) - 
        isnull(c.盈利规划综合管理费本年预计,0) - isnull(c.盈利规划税金及附加本年预计,0)) / 100000000 * 0.25) ELSE 0.0 END 所得税本年预计,
    CONVERT(DECIMAL(36, 8),
        ((isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0) - isnull(c.盈利规划股权溢价本年预计,0) ) -
         isnull(c.盈利规划营销费用本年预计,0) - isnull(c.盈利规划综合管理费本年预计,0) - isnull(c.盈利规划税金及附加本年预计,0))/ 100000000)
    - CASE WHEN isnull(x.项目税前利润本年预计,0) > 0 THEN CONVERT( DECIMAL(36, 8),
            ((isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0) ) - isnull(c.盈利规划营销费用本年预计,0) 
            - isnull(c.盈利规划综合管理费本年预计,0) - isnull(c.盈利规划税金及附加本年预计,0)  ) / 100000000 * 0.25 ) ELSE 0.0 END 净利润本年预计,
    CONVERT(DECIMAL(36, 8),CASE WHEN isnull(c.本年预计签约金额不含税,0) <> 0 THEN
        (CONVERT(DECIMAL(36, 8),((isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0) - isnull(c.盈利规划股权溢价本年预计,0) ) 
        - isnull(c.盈利规划营销费用本年预计,0) - isnull(c.盈利规划综合管理费本年预计,0)  - isnull(c.盈利规划税金及附加本年预计,0)))
        - CASE WHEN isnull(x.项目税前利润本年预计,0) > 0 THEN CONVERT( DECIMAL(36, 8),
        ((isnull(c.本年预计签约金额不含税,0) - isnull(c.盈利规划营业成本本年预计,0)) - isnull(c.盈利规划营销费用本年预计,0) 
        - isnull(c.盈利规划综合管理费本年预计,0)  - isnull(c.盈利规划税金及附加本年预计,0) ) * 0.25 ) ELSE 0.0 END  ) / c.本年预计签约金额不含税 END ) 销售净利率本年预计,
    --预估全年成本利润
    CONVERT(DECIMAL(36, 8), c.盈利规划营业成本预估全年 / 100000000) 盈利规划营业成本预估全年,
    CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价预估全年 / 100000000) 盈利规划股权溢价预估全年,
    CONVERT(DECIMAL(36, 8), (isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0) - isnull(c.盈利规划股权溢价预估全年,0)) / 100000000) 毛利预估全年,
    CONVERT( DECIMAL(36, 8),  CASE WHEN c.预估全年签约金额不含税 <> 0 THEN
               (isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0) - isnull(c.盈利规划股权溢价预估全年,0)) / isnull(c.预估全年签约金额不含税,0) END
           ) 毛利率预估全年,
    CONVERT(DECIMAL(36, 8), c.盈利规划营销费用预估全年 / 100000000) 盈利规划营销费用预估全年,
    CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费预估全年 / 100000000) 盈利规划综合管理费预估全年,
    CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加预估全年 / 100000000) 盈利规划税金及附加预估全年, 
    CONVERT( DECIMAL(36, 8),
            ((isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0)) - isnull(c.盈利规划营销费用预估全年,0) - 
            isnull(c.盈利规划综合管理费预估全年,0) - isnull(c.盈利规划税金及附加预估全年,0)) / 100000000 ) 税前利润预估全年,
    CASE WHEN isnull(x.项目税前利润预估全年,0) > 0 THEN CONVERT(DECIMAL(36, 8),
                ((isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0)) - isnull(c.盈利规划营销费用预估全年,0)
                 - isnull(c.盈利规划综合管理费预估全年,0) - isnull(c.盈利规划税金及附加预估全年,0)) / 100000000 * 0.25 ) ELSE 0.0 END 所得税预估全年,
    CONVERT(DECIMAL(36, 8),
            ((isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0) - isnull(c.盈利规划股权溢价预估全年,0))
             - isnull(c.盈利规划营销费用预估全年,0) - isnull(c.盈利规划综合管理费预估全年,0) - isnull(c.盈利规划税金及附加预估全年,0))
            / 100000000) - CASE WHEN isnull(x.项目税前利润预估全年,0) > 0 THEN CONVERT( DECIMAL(36, 8),
        ((isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0)) - isnull(c.盈利规划营销费用预估全年,0) - 
        isnull(c.盈利规划综合管理费预估全年,0) - isnull(c.盈利规划税金及附加预估全年,0) ) / 100000000 * 0.25 ) ELSE 0.0 END 净利润预估全年,
    CONVERT( DECIMAL(36, 8), CASE WHEN isnull(c.预估全年签约金额不含税,0) <> 0 THEN (CONVERT(DECIMAL(36, 8),
        ((isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0) - isnull(c.盈利规划股权溢价预估全年,0)) - isnull(c.盈利规划营销费用预估全年,0)
         - isnull(c.盈利规划综合管理费预估全年,0) - isnull(c.盈利规划税金及附加预估全年,0))) - CASE WHEN isnull(x.项目税前利润预估全年,0) > 0 THEN
         CONVERT( DECIMAL(36, 8), ((isnull(c.预估全年签约金额不含税,0) - isnull(c.盈利规划营业成本预估全年,0)) - isnull(c.盈利规划营销费用预估全年,0)-
          isnull(c.盈利规划综合管理费预估全年,0) - isnull(c.盈利规划税金及附加预估全年,0)) * 0.25) ELSE 0.0 END ) / isnull(c.预估全年签约金额不含税,0) END ) 销售净利率预估全年,
 --往年签约本年退房签约成本利润
    CONVERT(DECIMAL(36, 8), c.盈利规划营业成本往年签约本年退房 / 100000000) 盈利规划营业成本往年签约本年退房,
    CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价往年签约本年退房 / 100000000) 盈利规划股权溢价往年签约本年退房,
    CONVERT(DECIMAL(36, 8), (isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0) - isnull(c.盈利规划股权溢价往年签约本年退房,0)) / 100000000) 毛利往年签约本年退房,
    CONVERT( DECIMAL(36, 8),  CASE WHEN c.往年签约本年退房签约金额不含税 <> 0 THEN
               (isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0) - isnull(c.盈利规划股权溢价往年签约本年退房,0)) / isnull(c.往年签约本年退房签约金额不含税,0) END
           ) 毛利率往年签约本年退房,
    CONVERT(DECIMAL(36, 8), c.盈利规划营销费用往年签约本年退房/ 100000000) 盈利规划营销费用往年签约本年退房,
    CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费往年签约本年退房 / 100000000) 盈利规划综合管理费往年签约本年退房,
    CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加往年签约本年退房 / 100000000) 盈利规划税金及附加往年签约本年退房, 
    CONVERT( DECIMAL(36, 8),
            ((isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0)) - isnull(c.盈利规划营销费用往年签约本年退房,0) - 
            isnull(c.盈利规划综合管理费往年签约本年退房,0) - isnull(c.盈利规划税金及附加往年签约本年退房,0)) / 100000000 ) 税前利润往年签约本年退房,
    CASE WHEN isnull(x.项目税前利润往年签约本年退房,0) > 0 THEN CONVERT(DECIMAL(36, 8),
                ((isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0)) - isnull(c.盈利规划营销费用往年签约本年退房,0)
                 - isnull(c.盈利规划综合管理费往年签约本年退房,0) - isnull(c.盈利规划税金及附加往年签约本年退房,0)) / 100000000 * 0.25 ) ELSE 0.0 END 所得税往年签约本年退房,
    CONVERT(DECIMAL(36, 8),
            ((isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0) - isnull(c.盈利规划股权溢价往年签约本年退房,0))
             - isnull(c.盈利规划营销费用往年签约本年退房,0) - isnull(c.盈利规划综合管理费往年签约本年退房,0) - isnull(c.盈利规划税金及附加往年签约本年退房,0))
            / 100000000) - CASE WHEN isnull(x.项目税前利润往年签约本年退房,0) > 0 THEN CONVERT( DECIMAL(36, 8),
        ((isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0)) - isnull(c.盈利规划营销费用往年签约本年退房,0) - 
        isnull(c.盈利规划综合管理费往年签约本年退房,0) - isnull(c.盈利规划税金及附加往年签约本年退房,0) ) / 100000000 * 0.25 ) ELSE 0.0 END 净利润往年签约本年退房,
    CONVERT( DECIMAL(36, 8), CASE WHEN isnull(c.往年签约本年退房签约金额不含税,0) <> 0 THEN (CONVERT(DECIMAL(36, 8),
        ((isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0) - isnull(c.盈利规划股权溢价往年签约本年退房,0)) - isnull(c.盈利规划营销费用往年签约本年退房,0)
         - isnull(c.盈利规划综合管理费往年签约本年退房,0) - isnull(c.盈利规划税金及附加往年签约本年退房,0))) - CASE WHEN isnull(x.项目税前利润往年签约本年退房,0) > 0 THEN
         CONVERT( DECIMAL(36, 8), ((isnull(c.往年签约本年退房签约金额不含税,0) - isnull(c.盈利规划营业成本往年签约本年退房,0)) - isnull(c.盈利规划营销费用往年签约本年退房,0)-
          isnull(c.盈利规划综合管理费往年签约本年退房,0) - isnull(c.盈利规划税金及附加往年签约本年退房,0)) * 0.25) ELSE 0.0 END ) / isnull(c.往年签约本年退房签约金额不含税,0) END ) 销售净利率往年签约本年退房,
    --剩余货值实际流速版成本利润
    CONVERT(DECIMAL(36, 8), c.盈利规划营业成本剩余货值实际流速版 / 100000000) 盈利规划营业成本剩余货值实际流速版,
    CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价剩余货值实际流速版 / 100000000) 盈利规划股权溢价剩余货值实际流速版,
    CONVERT(DECIMAL(36, 8), (isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0) - isnull(c.盈利规划股权溢价剩余货值实际流速版,0)) / 100000000) 毛利剩余货值实际流速版,
    CONVERT( DECIMAL(36, 8),  CASE WHEN c.剩余货值实际流速版签约金额不含税 <> 0 THEN
               (isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0) - isnull(c.盈利规划股权溢价剩余货值实际流速版,0)) / isnull(c.剩余货值实际流速版签约金额不含税,0) END
           ) 毛利率剩余货值实际流速版,
    CONVERT(DECIMAL(36, 8), c.盈利规划营销费用剩余货值实际流速版 / 100000000) 盈利规划营销费用剩余货值实际流速版,
    CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费剩余货值实际流速版 / 100000000) 盈利规划综合管理费剩余货值实际流速版,
    CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加剩余货值实际流速版 / 100000000) 盈利规划税金及附加剩余货值实际流速版, 
    CONVERT( DECIMAL(36, 8),
            ((isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0)) - isnull(c.盈利规划营销费用剩余货值实际流速版,0) - 
            isnull(c.盈利规划综合管理费剩余货值实际流速版,0) - isnull(c.盈利规划税金及附加剩余货值实际流速版,0)) / 100000000 ) 税前利润剩余货值实际流速版,
    CASE WHEN isnull(x.项目税前利润剩余货值实际流速版,0) > 0 THEN CONVERT(DECIMAL(36, 8),
                ((isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0)) - isnull(c.盈利规划营销费用剩余货值实际流速版,0)
                 - isnull(c.盈利规划综合管理费剩余货值实际流速版,0) - isnull(c.盈利规划税金及附加剩余货值实际流速版,0)) / 100000000 * 0.25 ) ELSE 0.0 END 所得税剩余货值实际流速版,
    CONVERT(DECIMAL(36, 8),
            ((isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0) - isnull(c.盈利规划股权溢价剩余货值实际流速版,0))
             - isnull(c.盈利规划营销费用剩余货值实际流速版,0) - isnull(c.盈利规划综合管理费剩余货值实际流速版,0) - isnull(c.盈利规划税金及附加剩余货值实际流速版,0))
            / 100000000) - CASE WHEN isnull(x.项目税前利润剩余货值实际流速版,0) > 0 THEN CONVERT( DECIMAL(36, 8),
        ((isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0)) - isnull(c.盈利规划营销费用剩余货值实际流速版,0) - 
        isnull(c.盈利规划综合管理费剩余货值实际流速版,0) - isnull(c.盈利规划税金及附加剩余货值实际流速版,0) ) / 100000000 * 0.25 ) ELSE 0.0 END 净利润剩余货值实际流速版,
    CONVERT( DECIMAL(36, 8), CASE WHEN isnull(c.剩余货值实际流速版签约金额不含税,0) <> 0 THEN (CONVERT(DECIMAL(36, 8),
        ((isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0) - isnull(c.盈利规划股权溢价剩余货值实际流速版,0)) - isnull(c.盈利规划营销费用剩余货值实际流速版,0)
         - isnull(c.盈利规划综合管理费剩余货值实际流速版,0) - isnull(c.盈利规划税金及附加剩余货值实际流速版,0))) - CASE WHEN isnull(x.项目税前利润剩余货值实际流速版,0) > 0 THEN
         CONVERT( DECIMAL(36, 8), ((isnull(c.剩余货值实际流速版签约金额不含税,0) - isnull(c.盈利规划营业成本剩余货值实际流速版,0)) - isnull(c.盈利规划营销费用剩余货值实际流速版,0)-
          isnull(c.盈利规划综合管理费剩余货值实际流速版,0) - isnull(c.盈利规划税金及附加剩余货值实际流速版,0)) * 0.25) ELSE 0.0 END ) / isnull(c.剩余货值实际流速版签约金额不含税,0) END ) 销售净利率剩余货值实际流速版
into #sy_bnyj
FROM #mdm_project p 
     INNER JOIN #cost c ON c.ProjGUID = p.ProjGUID 
     LEFT JOIN #xm x ON x.ProjGUID = p.ProjGUID
     where p.level = 2 

--------------------------------------计算利润情况 end ---------------------------------
------------------------------------------------------------获取本年预计及剩余货值的毛利净利情况 end    -----------------------------------------
 select
    a.OrgGuid,
    a.ProjGUID,
    a.平台公司,
    a.产品类型, 
    a.产品名称,	
    a.装修标准,	
    a.商品类型,
	a.土地款_单方,
    a.盈利规划营业成本单方,
    a.盈利规划营销费用单方,
    a.盈利规划综合管理费单方协议口径,
    a.盈利规划税金及附加单方, 
    a.除地外直投_单方,	
    a.开发间接费单方,	
    a.资本化利息单方,	
    a.盈利规划股权溢价单方,
    --累计
    a.累计签约金额,
    a.累计签约面积,
    a.累计签约金额不含税,
    a.累计销售毛利润账面,
    a.累计销售毛利率账面,
    a.累计销售盈利规划营业成本,
    a.累计销售盈利规划营销费用,
    a.累计销售盈利规划综合管理费,
    a.累计销售盈利规划税金及附加,
    a.累计销售盈利规划除地价外直投,
    a.累计销售盈利规划开发间接费,
    a.累计销售盈利规划资本化利息,
	a.累计销售盈利规划土地款,
    a.累计销售盈利规划股权溢价,
    a.累计税前利润,
    a.累计所得税,
    a.累计净利润签约,
    a.累计销售净利率账面,
    --本年
    b.本年签约金额,
    b.本年签约面积,
    b.本年签约金额不含税,
    b.本年销售毛利润账面,
    b.本年销售毛利率账面,
    b.本年销售盈利规划营业成本,
    b.本年销售盈利规划营销费用,
    b.本年销售盈利规划综合管理费,
    b.本年销售盈利规划税金及附加,
    b.本年税前利润,
    b.本年所得税,
    b.本年净利润签约,
    b.本年销售净利率账面,
    --本年预计
    sb.当期本年预计金额 本年预计签约金额,
    sb.当期本年预计面积 本年预计签约面积,
    sb.当期本年预计金额不含税 本年预计签约金额不含税,
    sb.毛利本年预计  本年预计销售毛利润账面,
    sb.毛利率本年预计  本年预计销售毛利率账面,
    sb.盈利规划营业成本本年预计 本年预计销售盈利规划营业成本,
    sb.盈利规划营销费用本年预计 本年预计销售盈利规划营销费用,
    sb.盈利规划综合管理费本年预计  本年预计销售盈利规划综合管理费,
    sb.盈利规划税金及附加本年预计  本年预计销售盈利规划税金及附加,
    sb.税前利润本年预计 本年预计税前利润,
    sb.所得税本年预计  本年预计所得税,
    sb.净利润本年预计  本年预计净利润签约,
    sb.销售净利率本年预计  本年预计销售净利率账面,
    --去年
    qn.去年签约金额,
    qn.去年签约面积,
    qn.去年签约金额不含税,
    qn.去年销售毛利润账面,
    qn.去年销售毛利率账面,
    qn.去年销售盈利规划营业成本,
    qn.去年销售盈利规划营销费用,
    qn.去年销售盈利规划综合管理费,
    qn.去年销售盈利规划税金及附加,
    qn.去年税前利润,
    qn.去年所得税,
    qn.去年净利润签约,
    qn.去年销售净利率账面,
    --本月
    c.本月签约金额,
    c.本月签约面积,
    c.本月签约金额不含税,
    c.本月销售毛利润账面,
    c.本月销售毛利率账面,
    c.本月销售盈利规划营业成本,
    c.本月销售盈利规划营销费用,
    c.本月销售盈利规划综合管理费,
    c.本月销售盈利规划税金及附加,
    c.本月税前利润,
    c.本月所得税,
    c.本月净利润签约,
    c.本月销售净利率账面,
    --上月
    l.上月签约金额,
    l.上月签约面积,
    l.上月签约金额不含税,
    l.上月销售毛利润账面,
    l.上月销售毛利率账面,
    l.上月销售盈利规划营业成本,
    l.上月销售盈利规划营销费用,
    l.上月销售盈利规划综合管理费,
    l.上月销售盈利规划税金及附加,
    l.上月税前利润,
    l.上月所得税,
    l.上月净利润签约,
    l.上月销售净利率账面,
    --昨日
    zr.昨日签约金额,
    zr.昨日签约面积,
    zr.昨日签约金额不含税,
    zr.昨日销售毛利润账面,
    zr.昨日销售毛利率账面,
    zr.昨日销售盈利规划营业成本,
    zr.昨日销售盈利规划营销费用,
    zr.昨日销售盈利规划综合管理费,
    zr.昨日销售盈利规划税金及附加,
    zr.昨日税前利润,
    zr.昨日所得税,
    zr.昨日净利润签约,
    zr.昨日销售净利率账面,     
    --剩余货值
	sb.当期剩余货值金额,
    sb.剩余面积,
    sb.当期剩余货值金额不含税 剩余货值不含税,
    sb.毛利剩余货值  剩余货值销售毛利润账面,
    sb.毛利率剩余货值  剩余货值销售毛利率账面,
    sb.盈利规划营业成本剩余货值 剩余货值销售盈利规划营业成本,
    sb.盈利规划营销费用剩余货值 剩余货值销售盈利规划营销费用,
    sb.盈利规划综合管理费剩余货值  剩余货值销售盈利规划综合管理费,
    sb.盈利规划税金及附加剩余货值  剩余货值销售盈利规划税金及附加,
    sb.盈利规划除地价外直投剩余货值 剩余货值销售盈利规划除地价外直投,
	sb.盈利规划开发间接费剩余货值 剩余货值销售盈利规划开发间接费,
	sb.盈利规划资本化利息剩余货值 剩余货值销售盈利规划资本化利息,
	sb.盈利规划股权溢价剩余货值 剩余货值销售盈利规划股权溢价, 
	sb.盈利规划土地款剩余货值 剩余货值销售盈利规划土地款, 
    sb.税前利润剩余货值 剩余货值税前利润,
    sb.所得税剩余货值  剩余货值所得税,
    sb.净利润剩余货值  剩余货值净利润,
    sb.销售净利率剩余货值  剩余货值销售净利率账面, 
    --剩余货值实际流速版
	sb.当期剩余货值实际流速版签约金额,
    sb.剩余货值实际流速版签约面积,
    sb.当期剩余货值实际流速版签约金额不含税 剩余货值实际流速版签约金额不含税,
    sb.毛利剩余货值实际流速版  剩余货值实际流速版销售毛利润账面,
    sb.毛利率剩余货值实际流速版  剩余货值实际流速版销售毛利率账面,
    sb.盈利规划营业成本剩余货值实际流速版 剩余货值实际流速版销售盈利规划营业成本,
    sb.盈利规划营销费用剩余货值实际流速版 剩余货值实际流速版销售盈利规划营销费用,
    sb.盈利规划综合管理费剩余货值实际流速版  剩余货值实际流速版销售盈利规划综合管理费,
    sb.盈利规划税金及附加剩余货值实际流速版  剩余货值实际流速版销售盈利规划税金及附加,
    sb.税前利润剩余货值实际流速版 剩余货值实际流速版税前利润,
    sb.所得税剩余货值实际流速版  剩余货值实际流速版所得税,
    sb.净利润剩余货值实际流速版  剩余货值实际流速版净利润,
    sb.销售净利率剩余货值实际流速版  剩余货值实际流速版销售净利率账面, 
    --预估全年
	sb.当期预估全年签约金额,
    sb.预估全年签约面积,
    sb.当期预估全年签约金额不含税 预估全年签约金额不含税,
    sb.毛利预估全年  预估全年销售毛利润账面,
    sb.毛利率预估全年  预估全年销售毛利率账面,
    sb.盈利规划营业成本预估全年 预估全年销售盈利规划营业成本,
    sb.盈利规划营销费用预估全年 预估全年销售盈利规划营销费用,
    sb.盈利规划综合管理费预估全年  预估全年销售盈利规划综合管理费,
    sb.盈利规划税金及附加预估全年  预估全年销售盈利规划税金及附加,
    sb.税前利润预估全年 预估全年税前利润,
    sb.所得税预估全年  预估全年所得税,
    sb.净利润预估全年  预估全年净利润,
    sb.销售净利率预估全年  预估全年销售净利率账面, 
    --往年签约本年退房
	sb.当期往年签约本年退房签约金额,
    sb.往年签约本年退房签约面积,
    sb.当期往年签约本年退房签约金额不含税 往年签约本年退房签约不含税,
    sb.毛利往年签约本年退房  往年签约本年退房销售毛利润账面,
    sb.毛利率往年签约本年退房  往年签约本年退房销售毛利率账面,
    sb.盈利规划营业成本往年签约本年退房 往年签约本年退房销售盈利规划营业成本,
    sb.盈利规划营销费用往年签约本年退房 往年签约本年退房销售盈利规划营销费用,
    sb.盈利规划综合管理费往年签约本年退房  往年签约本年退房销售盈利规划综合管理费,
    sb.盈利规划税金及附加往年签约本年退房  往年签约本年退房销售盈利规划税金及附加,
    sb.税前利润往年签约本年退房 往年签约本年退房税前利润,
    sb.所得税往年签约本年退房  往年签约本年退房所得税,
    sb.净利润往年签约本年退房  往年签约本年退房净利润,
    sb.销售净利率往年签约本年退房  往年签约本年退房销售净利率账面,
    --本月认购 
    byrg.本月认购金额,
    byrg.本月认购面积,
    byrg.本月认购金额不含税,
    byrg.本月认购毛利润账面,
    byrg.本月认购毛利率账面,
    byrg.本月认购盈利规划营业成本,
    byrg.本月认购盈利规划营销费用,
    byrg.本月认购盈利规划综合管理费,
    byrg.本月认购盈利规划税金及附加,
    byrg.本月认购税前利润,
    byrg.本月认购所得税,
    byrg.本月净利润认购,
    byrg.本月认购净利率账面 
	into #tmp_result
from #lj a 
    left join #bn b on a.ProjGUID = b.ProjGUID and a.产品类型 = b.产品类型 and a.产品名称 = b.产品名称 and a.装修标准 = b.装修标准 and a.商品类型 = b.商品类型 
    left join #by c on a.ProjGUID = c.ProjGUID  and a.产品类型 = c.产品类型 and a.产品名称 = c.产品名称 and a.装修标准 = c.装修标准 and a.商品类型 = c.商品类型 
    left join #byrg byrg on a.ProjGUID = byrg.ProjGUID  and a.产品类型 = byrg.产品类型 and a.产品名称 = byrg.产品名称 and a.装修标准 = byrg.装修标准 and a.商品类型 = byrg.商品类型 
    left join #lastmonth l on a.ProjGUID = l.ProjGUID   and a.产品类型 = l.产品类型 and a.产品名称 = l.产品名称 and a.装修标准 = l.装修标准 and a.商品类型 = l.商品类型 
    left join #zr zr on zr.ProjGUID=a.ProjGUID  and a.产品类型 = zr.产品类型 and a.产品名称 = zr.产品名称 and a.装修标准 = zr.装修标准 and a.商品类型 = zr.商品类型 
    left join #qn qn on qn.ProjGUID=a.ProjGUID  and a.产品类型 = qn.产品类型 and a.产品名称 = qn.产品名称 and a.装修标准 = qn.装修标准 and a.商品类型 = qn.商品类型 
    left join #sy_bnyj sb on a.ProjGUID = sb.ProjGUID and a.产品类型 = sb.产品类型 and a.产品名称 = sb.产品名称 and a.装修标准 = sb.装修标准 and a.商品类型 = sb.商品类型 
union all    
--本年预计的业态层级要单独计算,是因为分为了手工铺排以及自动铺排。这里只有手工铺排的项目数据
select
    a.OrgGuid,
    a.ProjGUID,
    p.DevelopmentCompanyName 平台公司,
    a.产品类型, 
    a.产品名称,	
    a.装修标准,	
    a.商品类型, 
	a.土地款_单方,
    a.盈利规划营业成本单方,
    a.盈利规划营销费用单方,
    a.盈利规划综合管理费单方协议口径,
    a.盈利规划税金及附加单方, 
    a.除地外直投_单方,	
    a.开发间接费单方,	
    a.资本化利息单方,	 
    a.盈利规划股权溢价单方,
    --累计
    0 累计签约金额,
    0 累计签约面积,
    0 累计签约金额不含税,
    0 累计销售毛利润账面,
    0 累计销售毛利率账面,
    0 累计销售盈利规划营业成本,
    0 累计销售盈利规划营销费用,
    0 累计销售盈利规划综合管理费,
    0 累计销售盈利规划税金及附加,
    0 累计销售盈利规划除地价外直投,
    0 累计销售盈利规划开发间接费,
    0 累计销售盈利规划资本化利息,
	0 累计销售盈利规划土地款,
    0 累计销售盈利规划股权溢价,
    0 累计税前利润,
    0 累计所得税,
    0 累计净利润签约,
    0 累计销售净利率账面,
    --本年
    0 本年签约金额,
    0 本年签约面积,
    0 本年签约金额不含税,
    0 本年销售毛利润账面,
    0 本年销售毛利率账面,
    0 本年销售盈利规划营业成本,
    0 本年销售盈利规划营销费用,
    0 本年销售盈利规划综合管理费,
    0 本年销售盈利规划税金及附加,
    0 本年税前利润,
    0 本年所得税,
    0 本年净利润签约,
    0 本年销售净利率账面,
     --本年预计
    a.当期本年预计金额 本年预计签约金额,
    a.当期本年预计面积 本年预计签约面积,
    a.当期本年预计金额不含税 本年预计签约金额不含税,
    a.毛利本年预计  本年预计销售毛利润账面,
    a.毛利率本年预计  本年预计销售毛利率账面,
    a.盈利规划营业成本本年预计 本年预计销售盈利规划营业成本,
    a.盈利规划营销费用本年预计 本年预计销售盈利规划营销费用,
    a.盈利规划综合管理费本年预计  本年预计销售盈利规划综合管理费,
    a.盈利规划税金及附加本年预计  本年预计销售盈利规划税金及附加,
    a.税前利润本年预计 本年预计税前利润,
    a.所得税本年预计  本年预计所得税,
    a.净利润本年预计  本年预计净利润签约,
    a.销售净利率本年预计  本年预计销售净利率账面,
    --去年
    0 去年签约金额,
    0 去年签约面积,
    0 去年签约金额不含税,
    0 去年销售毛利润账面,
    0 去年销售毛利率账面,
    0 去年销售盈利规划营业成本,
    0 去年销售盈利规划营销费用,
    0 去年销售盈利规划综合管理费,
    0 去年销售盈利规划税金及附加,
    0 去年税前利润,
    0 去年所得税,
    0 去年净利润签约,
    0 去年销售净利率账面,
    --本月
    0 本月签约金额,
    0 本月签约面积,
    0 本月签约金额不含税,
    0 本月销售毛利润账面,
    0 本月销售毛利率账面,
    0 本月销售盈利规划营业成本,
    0 本月销售盈利规划营销费用,
    0 本月销售盈利规划综合管理费,
    0 本月销售盈利规划税金及附加,
    0 本月税前利润,
    0 本月所得税,
    0 本月净利润签约,
    0 本月销售净利率账面,
    --上月
    0 上月签约金额,
    0 上月签约面积,
    0 上月签约金额不含税,
    0 上月销售毛利润账面,
    0 上月销售毛利率账面,
    0 上月销售盈利规划营业成本,
    0 上月销售盈利规划营销费用,
    0 上月销售盈利规划综合管理费,
    0 上月销售盈利规划税金及附加,
    0 上月税前利润,
    0 上月所得税,
    0 上月净利润签约,
    0 上月销售净利率账面,
    --昨日
    0 昨日签约金额,
    0 昨日签约面积,
    0 昨日签约金额不含税,
    0 昨日销售毛利润账面,
    0 昨日销售毛利率账面,
    0 昨日销售盈利规划营业成本,
    0 昨日销售盈利规划营销费用,
    0 昨日销售盈利规划综合管理费,
    0 昨日销售盈利规划税金及附加,
    0 昨日税前利润,
    0 昨日所得税,
    0 昨日净利润签约,
    0 昨日销售净利率账面,     
    a.当期剩余货值金额,
    a.剩余面积,
    a.当期剩余货值金额不含税 剩余货值不含税,
    a.毛利剩余货值  剩余货值销售毛利润账面,
    a.毛利率剩余货值  剩余货值销售毛利率账面,
    a.盈利规划营业成本剩余货值 剩余货值销售盈利规划营业成本,
    a.盈利规划营销费用剩余货值 剩余货值销售盈利规划营销费用,
    a.盈利规划综合管理费剩余货值  剩余货值销售盈利规划综合管理费,
    a.盈利规划税金及附加剩余货值  剩余货值销售盈利规划税金及附加,
    a.盈利规划除地价外直投剩余货值 剩余货值销售盈利规划除地价外直投,
	a.盈利规划开发间接费剩余货值 剩余货值销售盈利规划开发间接费,
	a.盈利规划资本化利息剩余货值 剩余货值销售盈利规划资本化利息,
	a.盈利规划股权溢价剩余货值 剩余货值销售盈利规划股权溢价, 
	a.盈利规划土地款剩余货值 剩余货值销售盈利规划土地款,  
    a.税前利润剩余货值 剩余货值税前利润,
    a.所得税剩余货值  剩余货值所得税,
    a.净利润剩余货值  剩余货值净利润,
    a.销售净利率剩余货值  剩余货值销售净利率账面,

    --剩余货值实际流速版
	a.当期剩余货值实际流速版签约金额,
    a.剩余货值实际流速版签约面积,
    a.当期剩余货值实际流速版签约金额不含税 剩余货值实际流速版签约金额不含税,
    a.毛利剩余货值实际流速版  剩余货值实际流速版销售毛利润账面,
    a.毛利率剩余货值实际流速版  剩余货值实际流速版销售毛利率账面,
    a.盈利规划营业成本剩余货值实际流速版 剩余货值实际流速版销售盈利规划营业成本,
    a.盈利规划营销费用剩余货值实际流速版 剩余货值实际流速版销售盈利规划营销费用,
    a.盈利规划综合管理费剩余货值实际流速版  剩余货值实际流速版销售盈利规划综合管理费,
    a.盈利规划税金及附加剩余货值实际流速版  剩余货值实际流速版销售盈利规划税金及附加,
    a.税前利润剩余货值实际流速版 剩余货值实际流速版税前利润,
    a.所得税剩余货值实际流速版  剩余货值实际流速版所得税,
    a.净利润剩余货值实际流速版  剩余货值实际流速版净利润,
    a.销售净利率剩余货值实际流速版  剩余货值实际流速版销售净利率账面, 
    --预估全年
	0 as 当期预估全年签约金额,
    0 as 预估全年签约面积,
    0 as 预估全年签约金额不含税,
    0 as 预估全年销售毛利润账面,
    0 as 预估全年销售毛利率账面,
    0 as 预估全年销售盈利规划营业成本,
    0 as 预估全年销售盈利规划营销费用,
    0 as 预估全年销售盈利规划综合管理费,
    0 as 预估全年销售盈利规划税金及附加,
    0 as 预估全年税前利润,
    0 as 预估全年所得税,
    0 as 预估全年净利润,
    0 as 预估全年销售净利率账面, 
    --往年签约本年退房
	0 as 当期往年签约本年退房签约金额,
    0 as 往年签约本年退房签约面积,
    0 as 往年签约本年退房签约不含税,
    0 as 往年签约本年退房销售毛利润账面,
    0 as 往年签约本年退房销售毛利率账面,
    0 as 往年签约本年退房销售盈利规划营业成本,
    0 as 往年签约本年退房销售盈利规划营销费用,
    0 as 往年签约本年退房销售盈利规划综合管理费,
    0 as 往年签约本年退房销售盈利规划税金及附加,
    0 as 往年签约本年退房税前利润,
    0 as 往年签约本年退房所得税,
    0 as 往年签约本年退房净利润,
    0 as 往年签约本年退房销售净利率账面,
    --本月认购 
    0 as 本月认购金额,
    0 as 本月认购面积,
    0 as 本月认购金额不含税,
    0 as 本月认购毛利润账面,
    0 as 本月认购毛利率账面,
    0 as 本月认购盈利规划营业成本,
    0 as 本月认购盈利规划营销费用,
    0 as 本月认购盈利规划综合管理费,
    0 as 本月认购盈利规划税金及附加,
    0 as 本月认购税前利润,
    0 as 本月认购所得税,
    0 as 本月净利润认购,
    0 as 本月认购净利率账面   
from #sy_bnyj a
inner join p_DevelopmentCompany p on a.OrgGuid = p.DevelopmentCompanyGUID
where 产品名称 is null 

delete from s_M002业态级净利汇总表_数仓用 where datediff(dd, qxdate, @qxdate) = 0

--只保留每个月月底的版本
--delete from s_M002业态级净利汇总表_数仓用 where datediff(dd,qxdate,dateadd(ms, -3, DATEADD(mm, DATEDIFF(m, 0, qxdate) + 1, 0))) <> 0
 
 
insert into s_M002业态级净利汇总表_数仓用(
        [OrgGuid],
        [ProjGUID],
        [平台公司],
        产品类型, 
        产品名称,	
        装修标准,	
        商品类型,
        --单方
		土地款_单方,
        盈利规划营业成本单方,
        盈利规划营销费用单方,
        盈利规划综合管理费单方协议口径,
        盈利规划税金及附加单方, 
        除地外直投_单方,	
        开发间接费单方,	
        资本化利息单方,	
        盈利规划股权溢价单方,
        --累计
        累计签约金额,
        累计签约面积,
        累计签约金额不含税,
        累计销售毛利润账面,
        累计销售毛利率账面,
        累计销售盈利规划营业成本,
        累计销售盈利规划营销费用,
        累计销售盈利规划综合管理费,
        累计销售盈利规划税金及附加,
        累计销售盈利规划除地价外直投,
        累计销售盈利规划开发间接费,
        累计销售盈利规划资本化利息,
        累计销售盈利规划股权溢价,
		累计销售盈利规划土地款,
        累计税前利润,
        累计所得税,
        累计净利润签约,
        累计销售净利率账面,

        --本年
        本年签约金额,
        本年签约面积,
        本年签约金额不含税,
        本年销售毛利润账面,
        本年销售毛利率账面,
        本年销售盈利规划营业成本,
        本年销售盈利规划营销费用,   
        本年销售盈利规划综合管理费,
        本年销售盈利规划税金及附加,
        本年税前利润,
        本年所得税,
        本年净利润签约,
        本年销售净利率账面,
        --本年预计
        本年预计签约金额,
        本年预计签约面积,
        本年预计签约金额不含税,
        本年预计销售毛利润账面,
        本年预计销售毛利率账面,
        本年预计销售盈利规划营业成本,
        本年预计销售盈利规划营销费用,
        本年预计销售盈利规划综合管理费,
        本年预计销售盈利规划税金及附加,
        本年预计税前利润,
        本年预计所得税,
        本年预计净利润签约,
        本年预计销售净利率账面,
        --去年
        去年签约金额,
        去年签约面积,
        去年签约金额不含税,
        去年销售毛利润账面,
        去年销售毛利率账面,
        去年销售盈利规划营业成本, 		
        去年销售盈利规划营销费用,
        去年销售盈利规划综合管理费,
        去年销售盈利规划税金及附加,
        去年税前利润,
        去年所得税,
        去年净利润签约,
        去年销售净利率账面,
        --本月
        本月签约金额,
        本月签约面积,
        本月签约金额不含税,
        本月销售毛利润账面,
        本月销售毛利率账面,
        本月销售盈利规划营业成本, 
        本月销售盈利规划营销费用,
        本月销售盈利规划综合管理费,
        本月销售盈利规划税金及附加,
        本月税前利润,
        本月所得税,
        本月净利润签约,
        本月销售净利率账面,
        --上月
        上月签约金额,
        上月签约面积,
        上月签约金额不含税,
        上月销售毛利润账面,
        上月销售毛利率账面,
        上月销售盈利规划营业成本,
        上月销售盈利规划营销费用,
        上月销售盈利规划综合管理费,
        上月销售盈利规划税金及附加,
        上月税前利润,
        上月所得税,
        上月净利润签约,
        上月销售净利率账面,
        --昨日
        昨日签约金额,
        昨日签约面积,
        昨日签约金额不含税,
        昨日销售毛利润账面,
        昨日销售毛利率账面,
        昨日销售盈利规划营业成本,  
        昨日销售盈利规划营销费用,
        昨日销售盈利规划综合管理费,
        昨日销售盈利规划税金及附加,
        昨日税前利润,
        昨日所得税,
        昨日净利润签约,
        昨日销售净利率账面,

        qxdate,
        versionguid,
        --剩余货值 
        剩余面积,
	    剩余货值不含税,
	    剩余货值销售毛利润账面,
	    剩余货值销售毛利率账面,
        剩余货值销售盈利规划营业成本,
	    剩余货值销售盈利规划营销费用,
	    剩余货值销售盈利规划综合管理费,
	    剩余货值销售盈利规划税金及附加,
        剩余货值销售盈利规划除地价外直投,
	    剩余货值销售盈利规划开发间接费,
	    剩余货值销售盈利规划资本化利息,
	    剩余货值销售盈利规划股权溢价, 
		剩余货值销售盈利规划土地款,
	    剩余货值税前利润,
	    剩余货值所得税,
	    剩余货值净利润,
	    剩余货值销售净利率账面,
	    剩余货值金额,
        --剩余货值实际流速版
        剩余货值实际流速版签约面积,
	    剩余货值实际流速版签约金额不含税,
	    剩余货值实际流速版销售毛利润账面,
	    剩余货值实际流速版销售毛利率账面,
        剩余货值实际流速版销售盈利规划营业成本,
	    剩余货值实际流速版销售盈利规划营销费用,
	    剩余货值实际流速版销售盈利规划综合管理费,
	    剩余货值实际流速版销售盈利规划税金及附加,
	    剩余货值实际流速版税前利润,
	    剩余货值实际流速版所得税,
	    剩余货值实际流速版净利润,
	    剩余货值实际流速版销售净利率账面,
	    剩余货值实际流速版签约金额,
        --预估全年
        预估全年签约面积,
	    预估全年签约金额不含税,
	    预估全年销售毛利润账面,
	    预估全年销售毛利率账面,
        预估全年销售盈利规划营业成本,
	    预估全年销售盈利规划营销费用,
	    预估全年销售盈利规划综合管理费,
	    预估全年销售盈利规划税金及附加,
	    预估全年税前利润,
	    预估全年所得税,
	    预估全年净利润,
	    预估全年销售净利率账面,
	    预估全年签约金额,
        --往年签约本年退房
        往年签约本年退房签约面积,
	    往年签约本年退房签约金额不含税,
	    往年签约本年退房销售毛利润账面,
	    往年签约本年退房销售毛利率账面,
        往年签约本年退房销售盈利规划营业成本,
	    往年签约本年退房销售盈利规划营销费用,
	    往年签约本年退房销售盈利规划综合管理费,
	    往年签约本年退房销售盈利规划税金及附加,
	    往年签约本年退房税前利润,
	    往年签约本年退房所得税,
	    往年签约本年退房净利润,
	    往年签约本年退房销售净利率账面,
	    往年签约本年退房签约金额,
        --本月认购
        本月认购金额,
        本月认购面积,
        本月认购金额不含税,
        本月认购毛利润账面,
        本月认购毛利率账面,
        本月认购盈利规划营业成本,
        本月认购盈利规划营销费用,
        本月认购盈利规划综合管理费,
        本月认购盈利规划税金及附加,
        本月认购税前利润,
        本月认购所得税,
        本月净利润认购,
        本月认购净利率账面   
    )
select
    t.OrgGuid,
    t.ProjGUID,
    t.平台公司,
    t.产品类型, 
    t.产品名称,	
    t.装修标准,	
    t.商品类型,
    --单方
	t.土地款_单方,
    t.盈利规划营业成本单方,
    t.盈利规划营销费用单方,
    t.盈利规划综合管理费单方协议口径,
    t.盈利规划税金及附加单方, 
    t.除地外直投_单方,	
    t.开发间接费单方,	
    t.资本化利息单方,	
    t.盈利规划股权溢价单方,
    --累计
    sum(t.累计签约金额) as 累计签约金额,
    sum(t.累计签约面积) as 累计签约面积,
    sum(t.累计签约金额不含税) as 累计签约金额不含税,
    sum(t.累计销售毛利润账面) as 累计销售毛利润账面,
    case when sum(t.累计签约金额不含税)=0 then 0 else  sum(t.累计销售毛利润账面)/sum(t.累计签约金额不含税) end  as 累计销售毛利率账面,
    sum(t.累计销售盈利规划营业成本) as 累计销售盈利规划营业成本,
    sum(t.累计销售盈利规划营销费用) as 累计销售盈利规划营销费用,
    sum(t.累计销售盈利规划综合管理费) as 累计销售盈利规划综合管理费,
    sum(t.累计销售盈利规划税金及附加) as 累计销售盈利规划税金及附加,
    sum(t.累计销售盈利规划除地价外直投) as 累计销售盈利规划除地价外直投,
    sum(t.累计销售盈利规划开发间接费) as 累计销售盈利规划开发间接费,
    sum(t.累计销售盈利规划资本化利息) as 累计销售盈利规划资本化利息,
    sum(t.累计销售盈利规划股权溢价) as 累计销售盈利规划股权溢价,
	sum(t.累计销售盈利规划土地款) as 累计销售盈利规划土地款,
    sum(t.累计税前利润) as 累计税前利润,
    sum(t.累计所得税) as 累计所得税,
    sum(t.累计净利润签约) as 累计净利润签约,
    case when sum(t.累计签约金额不含税)=0 then 0 else  sum(t.累计净利润签约)/sum(t.累计签约金额不含税) end  as 累计销售净利率账面,
    --本年
    sum(t.本年签约金额) as 本年签约金额,
    sum(t.本年签约面积) as 本年签约面积,
    sum(t.本年签约金额不含税) as 本年签约金额不含税,
    sum(t.本年销售毛利润账面) as 本年销售毛利润账面,
    case when sum(t.本年签约金额不含税)=0 then 0 else  sum(t.本年销售毛利润账面)/sum(t.本年签约金额不含税) end as 本年销售毛利率账面,
    sum(t.本年销售盈利规划营业成本) as 本年销售盈利规划营业成本,
    sum(t.本年销售盈利规划营销费用) as 本年销售盈利规划营销费用,
    sum(t.本年销售盈利规划综合管理费) as 本年销售盈利规划综合管理费,
    sum(t.本年销售盈利规划税金及附加) as 本年销售盈利规划税金及附加,
    sum(t.本年税前利润) as 本年税前利润,
    sum(t.本年所得税) as 本年所得税,
    sum(t.本年净利润签约) as 本年净利润签约,
    case when sum(t.本年签约金额不含税)=0 then 0 else sum(t.本年净利润签约)/sum(t.本年签约金额不含税) end as 本年销售净利率账面,
    --本年预计
    t.本年预计签约金额 as 本年预计签约金额,
    t.本年预计签约面积 as 本年预计签约面积,
    t.本年预计签约金额不含税 as 本年预计签约金额不含税,
    t.本年预计销售毛利润账面 as 本年预计销售毛利润账面,
    case when t.本年预计签约金额不含税=0 then 0 else t.本年预计销售毛利润账面/t.本年预计签约金额不含税 end as 本年预计销售毛利率账面,
    t.本年预计销售盈利规划营业成本 as 本年预计销售盈利规划营业成本,
    t.本年预计销售盈利规划营销费用 as 本年预计销售盈利规划营销费用,
    t.本年预计销售盈利规划综合管理费 as 本年预计销售盈利规划综合管理费,
    t.本年预计销售盈利规划税金及附加 as 本年预计销售盈利规划税金及附加,
    t.本年预计税前利润 as 本年预计税前利润,
    t.本年预计所得税 as 本年预计所得税,
    t.本年预计净利润签约 as 本年预计净利润签约,
    case when t.本年预计签约金额不含税=0 then 0 else t.本年预计净利润签约/t.本年预计签约金额不含税 end  as 本年预计销售净利率账面,
    --去年
    sum(t.去年签约金额) as 去年签约金额,
    sum(t.去年签约面积) as 去年签约面积,
    sum(t.去年签约金额不含税) as 去年签约金额不含税,
    sum(t.去年销售毛利润账面) as 去年销售毛利润账面,
    case when sum(t.去年签约金额不含税)=0 then 0 else sum(t.去年销售毛利润账面)/sum(t.去年签约金额不含税) end as 去年销售毛利率账面,
    sum(t.去年销售盈利规划营业成本) as 去年销售盈利规划营业成本,
    sum(t.去年销售盈利规划营销费用) as 去年销售盈利规划营销费用,
    sum(t.去年销售盈利规划综合管理费) as 去年销售盈利规划综合管理费,
    sum(t.去年销售盈利规划税金及附加) as 去年销售盈利规划税金及附加,
    sum(t.去年税前利润) as 去年税前利润,
    sum(t.去年所得税) as 去年所得税,
    sum(t.去年净利润签约) as 去年净利润签约,
    case when sum(t.去年签约金额不含税)=0 then 0 else sum(t.去年净利润签约)/sum(t.去年签约金额不含税) end as 去年销售净利率账面,
    --本月
    sum(t.本月签约金额) as 本月签约金额,
    sum(t.本月签约面积) as 本月签约面积,
    sum(t.本月签约金额不含税) as 本月签约金额不含税,
    sum(t.本月销售毛利润账面) as 本月销售毛利润账面,
    case when sum(t.本月签约金额不含税)=0 then 0 else sum(t.本月销售毛利润账面)/sum(t.本月签约金额不含税) end  as 本月销售毛利率账面,
    sum(t.本月销售盈利规划营业成本) as 本月销售盈利规划营业成本,
    sum(t.本月销售盈利规划营销费用) as 本月销售盈利规划营销费用,
    sum(t.本月销售盈利规划综合管理费) as 本月销售盈利规划综合管理费,
    sum(t.本月销售盈利规划税金及附加) as 本月销售盈利规划税金及附加,
    sum(t.本月税前利润) as 本月税前利润,
    sum(t.本月所得税) as 本月所得税,
    sum(t.本月净利润签约) as 本月净利润签约,
    case when sum(t.本月签约金额不含税)=0 then 0 else sum(t.本月净利润签约)/sum(t.本月签约金额不含税) end  as 本月销售净利率账面,
    --上月
    sum(t.上月签约金额) as 上月签约金额,
    sum(t.上月签约面积) as 上月签约面积,
    sum(t.上月签约金额不含税) as 上月签约金额不含税,
    sum(t.上月销售毛利润账面) as 上月销售毛利润账面,
    case when sum(t.上月签约金额不含税)=0 then 0 else sum(t.上月销售毛利润账面)/sum(t.上月签约金额不含税) end as 上月销售毛利率账面,
    sum(t.上月销售盈利规划营业成本) as 上月销售盈利规划营业成本,
    sum(t.上月销售盈利规划营销费用) as 上月销售盈利规划营销费用,
    sum(t.上月销售盈利规划综合管理费) as 上月销售盈利规划综合管理费,
    sum(t.上月销售盈利规划税金及附加) as 上月销售盈利规划税金及附加,
    sum(t.上月税前利润) as 上月税前利润,
    sum(t.上月所得税) as 上月所得税,
    sum(t.上月净利润签约) as 上月净利润签约,
    case when sum(t.上月签约金额不含税)=0 then 0 else sum(t.上月净利润签约)/sum(t.上月签约金额不含税) end as 上月销售净利率账面,
    --昨日
    sum(t.昨日签约金额) as 昨日签约金额,
    sum(t.昨日签约面积) as 昨日签约面积,
    sum(t.昨日签约金额不含税) as 昨日签约金额不含税,
    sum(t.昨日销售毛利润账面) as 昨日销售毛利润账面,
    case when sum(t.昨日签约金额不含税)=0 then 0 else sum(t.昨日销售毛利润账面)/sum(t.昨日签约金额不含税) end as 昨日销售毛利率账面,
    sum(t.昨日销售盈利规划营业成本) as 昨日销售盈利规划营业成本,
    sum(t.昨日销售盈利规划营销费用) as 昨日销售盈利规划营销费用,
    sum(t.昨日销售盈利规划综合管理费) as 昨日销售盈利规划综合管理费,
    sum(t.昨日销售盈利规划税金及附加) as 昨日销售盈利规划税金及附加,
    sum(t.昨日税前利润) as 昨日税前利润,
    sum(t.昨日所得税) as 昨日所得税,
    sum(t.昨日净利润签约) as 昨日净利润签约,
    case when sum(t.昨日签约金额不含税)=0 then 0 else sum(t.昨日净利润签约)/sum(t.昨日签约金额不含税) end as 昨日销售净利率账面,    
    convert(varchar(10),@qxdate,120),
    newid(), 
    --剩余货值
    t.剩余面积 as 剩余面积,
	t.剩余货值不含税 as 剩余货值不含税,
	t.剩余货值销售毛利润账面 as 剩余货值销售毛利润账面,
	case when t.剩余货值不含税=0 then 0 else t.剩余货值销售毛利润账面/t.剩余货值不含税 end as 剩余货值销售毛利率账面,
    t.剩余货值销售盈利规划营业成本 as 剩余货值盈利规划营业成本,
	t.剩余货值销售盈利规划营销费用 as 剩余货值销售盈利规划营销费用,
	t.剩余货值销售盈利规划综合管理费 as 剩余货值销售盈利规划综合管理费,
	t.剩余货值销售盈利规划税金及附加 as 剩余货值销售盈利规划税金及附加,
    
    t.剩余货值销售盈利规划除地价外直投 as 剩余货值盈利规划除地价外直投,
	t.剩余货值销售盈利规划开发间接费 as 剩余货值盈利规划开发间接费,
	t.剩余货值销售盈利规划资本化利息 as 剩余货值盈利规划资本化利息,
	t.剩余货值销售盈利规划股权溢价 as 剩余货值盈利规划股权溢价, 
	t.剩余货值销售盈利规划土地款 as 剩余货值盈利规划土地款, 
	t.剩余货值税前利润 as 剩余货值税前利润,
	t.剩余货值所得税 as 剩余货值所得税,
	t.剩余货值净利润 as 剩余货值净利润,
	case when t.剩余货值不含税=0 then 0 else t.剩余货值净利润/t.剩余货值不含税 end as 剩余货值销售净利率账面 ,
	当期剩余货值金额 as  当期剩余货值金额 ,
    --剩余货值实际流速版
    t.剩余货值实际流速版签约面积,
	t.剩余货值实际流速版签约金额不含税,
	t.剩余货值实际流速版销售毛利润账面,
	t.剩余货值实际流速版销售毛利率账面,
    t.剩余货值实际流速版销售盈利规划营业成本,
	t.剩余货值实际流速版销售盈利规划营销费用,
	t.剩余货值实际流速版销售盈利规划综合管理费,
	t.剩余货值实际流速版销售盈利规划税金及附加,
	t.剩余货值实际流速版税前利润,
	t.剩余货值实际流速版所得税,
	t.剩余货值实际流速版净利润,
	t.剩余货值实际流速版销售净利率账面,
	t.当期剩余货值实际流速版签约金额,
    --预估全年
    sum(预估全年签约面积) as 预估全年签约面积,
	sum(预估全年签约金额不含税) as 预估全年签约金额不含税,
	sum(预估全年销售毛利润账面) as 预估全年销售毛利润账面,
	case when sum(t.预估全年签约金额不含税)=0 then 0 else sum(t.预估全年销售毛利润账面)/sum(t.预估全年签约金额不含税) end as 预估全年销售毛利率账面,
    sum(预估全年销售盈利规划营业成本) as 预估全年销售盈利规划营业成本,
	sum(预估全年销售盈利规划营销费用) as 预估全年销售盈利规划营销费用,
	sum(预估全年销售盈利规划综合管理费) as 预估全年销售盈利规划综合管理费,
	sum(预估全年销售盈利规划税金及附加) as 预估全年销售盈利规划税金及附加,
	sum(预估全年税前利润) as 预估全年税前利润,
	sum(预估全年所得税) as 预估全年所得税,
	sum(预估全年净利润) as 预估全年净利润,
	case when sum(t.预估全年签约金额不含税)=0 then 0 else sum(t.预估全年净利润)/sum(t.预估全年签约金额不含税) end as 预估全年销售净利率账面,
	sum(当期预估全年签约金额) as 预估全年签约金额,
    --往年签约本年退房
    sum(t.往年签约本年退房签约面积) as 往年签约本年退房签约面积,
	sum(t.往年签约本年退房签约不含税) as 往年签约本年退房签约不含税,
	sum(t.往年签约本年退房销售毛利润账面)*-1 as 往年签约本年退房销售毛利润账面,
	case when sum(t.往年签约本年退房签约不含税)=0 then 0 else sum(t.往年签约本年退房销售毛利润账面)*-1/sum(t.往年签约本年退房签约不含税) end as 往年签约本年退房销售毛利率账面,
    sum(t.往年签约本年退房销售盈利规划营业成本) as 往年签约本年退房销售盈利规划营业成本,
	sum(t.往年签约本年退房销售盈利规划营销费用) as 往年签约本年退房销售盈利规划营销费用,
	sum(t.往年签约本年退房销售盈利规划综合管理费) as 往年签约本年退房销售盈利规划综合管理费,
	sum(t.往年签约本年退房销售盈利规划税金及附加) as 往年签约本年退房销售盈利规划税金及附加,
	sum(t.往年签约本年退房税前利润)*-1 as 往年签约本年退房税前利润,
	sum(t.往年签约本年退房所得税) as 往年签约本年退房所得税,
	sum(t.往年签约本年退房净利润)*-1 as 往年签约本年退房净利润,
	case when sum(t.往年签约本年退房签约不含税)=0 then 0 else sum(t.往年签约本年退房净利润)*-1/sum(t.往年签约本年退房签约不含税) end as 往年签约本年退房销售净利率账面,
	sum(t.当期往年签约本年退房签约金额) as 往年签约本年退房签约金额,
    --本月认购
    sum(t.本月认购金额) as 本月认购金额,
    sum(t.本月认购面积) as 本月认购面积,
    sum(t.本月认购金额不含税) as 本月认购金额不含税,
    sum(t.本月认购毛利润账面) as 本月认购毛利润账面,
    case when sum(t.本月认购金额不含税)=0 then 0 else sum(t.本月认购毛利润账面)/sum(t.本月认购金额不含税) end as 本月认购毛利率账面,
    sum(t.本月认购盈利规划营业成本) as 本月认购盈利规划营业成本,
    sum(t.本月认购盈利规划营销费用) as 本月认购盈利规划营销费用,
    sum(t.本月认购盈利规划综合管理费) as 本月认购盈利规划综合管理费,
    sum(t.本月认购盈利规划税金及附加) as 本月认购盈利规划税金及附加,
    sum(t.本月认购税前利润) as 本月认购税前利润,
    sum(t.本月认购所得税) as 本月认购所得税,
    sum(t.本月净利润认购) as 本月净利润认购,
    case when sum(t.本月认购金额不含税)=0 then 0 else sum(t.本月净利润认购)/sum(t.本月认购金额不含税) end as 本月认购净利率账面  
from #tmp_result t
group by t.OrgGuid,
    t.ProjGUID,
    t.平台公司,
    t.产品类型, 
    t.产品名称,	
    t.装修标准,	
    t.商品类型,
	t.本年预计签约金额,
    t.本年预计签约面积,
    t.本年预计签约金额不含税,
    t.本年预计销售毛利润账面,
    t.本年预计销售盈利规划营销费用,
    t.本年预计销售盈利规划综合管理费,
    t.本年预计销售盈利规划税金及附加,
    t.本年预计税前利润,
	t.本年预计销售盈利规划营业成本,
    t.本年预计所得税,
    t.本年预计净利润签约,
    t.盈利规划营业成本单方,
    t.盈利规划营销费用单方,
    t.盈利规划综合管理费单方协议口径,
    t.盈利规划税金及附加单方,
    t.除地外直投_单方,	
    t.开发间接费单方,	
    t.资本化利息单方,	
	t.土地款_单方,
    t.盈利规划股权溢价单方,
    t.剩余面积,
	t.剩余货值不含税,
	t.剩余货值销售毛利润账面, 
    t.剩余货值销售盈利规划营业成本,
	t.剩余货值销售盈利规划营销费用,
	t.剩余货值销售盈利规划综合管理费,
	t.剩余货值销售盈利规划税金及附加,
    t.剩余货值销售盈利规划除地价外直投,
    t.剩余货值销售盈利规划开发间接费,
    t.剩余货值销售盈利规划资本化利息,
    t.剩余货值销售盈利规划股权溢价,
	t.剩余货值销售盈利规划土地款,
	t.剩余货值税前利润,
	t.剩余货值所得税,
	t.剩余货值净利润, 
	t.当期剩余货值金额,
    t.剩余货值实际流速版签约面积,
	t.剩余货值实际流速版签约金额不含税,
	t.剩余货值实际流速版销售毛利润账面,
	t.剩余货值实际流速版销售毛利率账面,
    t.剩余货值实际流速版销售盈利规划营业成本,
	t.剩余货值实际流速版销售盈利规划营销费用,
	t.剩余货值实际流速版销售盈利规划综合管理费,
	t.剩余货值实际流速版销售盈利规划税金及附加,
	t.剩余货值实际流速版税前利润,
	t.剩余货值实际流速版所得税,
	t.剩余货值实际流速版净利润,
	t.剩余货值实际流速版销售净利率账面,
	t.当期剩余货值实际流速版签约金额  
    
drop table #bn,#by,#cost,#db,#df,#key,#lastmonth,#lj,#qn,#sale,#sgpp,#sy_bnyj,#tmp_result,#tmp_tax,#xm,#zdpp,#zr,#ver,#byrg

END; 