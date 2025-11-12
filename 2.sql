USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_dw_f_TopProJect_ProfitCost_ylgh]    Script Date: 2025/10/29 10:21:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  PROC [dbo].[usp_dw_f_TopProJect_ProfitCost_ylgh]
AS
/*
表名：盈利规划项目成本收益数据
用途：收集盈利规划项目成本收益情况,用于保利自定义分析

author:lintx
date:20221130

运行样例：
[usp_dw_f_TopProJect_ProfitCost_ylgh]

modified by lintx  date:2022-12-06
1、新增财务口径指标，税后净现金、irr、固定资产等12个指标，用于战投报表-项目运营情况跟进表
2、增加股东口径的指标共22个

modified by lintx  date:2025-01-17
1、增加除地价外直投含税口径
*/

BEGIN

    --创建临时表 
    SELECT *
    INTO #tmp_dw_f_TopProJect_ProfitCost_ylgh
    FROM dw_f_TopProJect_ProfitCost_ylgh
    WHERE 1 = 2;

    --缓存F08表的数据
    select  
    F08.* 
    into #f08
    from 
    data_wide_qt_F080004 f08
    inner join data_wide_dws_ys_ProjGUID pj on f08.实体分期 = pj.YLGHProjGUID and pj.isbase = 1 and pj.BusinessEdition = f08.版本
	and pj.Level = 3
    where CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0
    AND F08.明细说明 = '总价' 
   
   --缓存F030002表的数据
    select f03.* 
    into #f0302
    from 
    data_wide_qt_F030002  F03
    inner join data_wide_dws_ys_ProjGUID pj on F03.实体分期 = pj.YLGHProjGUID and pj.isbase = 1 and pj.BusinessEdition = F03.版本 and pj.Level = 3
    where f03.明细说明 = '账务口径不含税留存成本' and CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0
   
    --缓存F030008表的数据
    select f03.* 
    into #f0308
    from 
    data_wide_qt_F030008  F03
    inner join data_wide_dws_ys_ProjGUID pj on F03.实体分期 = pj.YLGHProjGUID and pj.isbase = 1 and pj.BusinessEdition = F03.版本 and pj.Level = 3
    where f03.明细说明 = '账务口径不含税总成本'and CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0

    --缓存F030010表的数据
    select f03.*,pj.ProjGUID
    into #f0310
    from data_wide_qt_F030010  F03
    inner join data_wide_dws_ys_ProjGUID pj on F03.实体分期 = pj.YLGHProjGUID and pj.isbase = 1 and pj.BusinessEdition = F03.版本 
	and pj.Level = 3
	where  明细说明 = '含税金额' and CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 and 成本预测科目 = '累计除地价外直投调整后' 

    select f03.ProjGUID,sum(CONVERT(decimal(16,2),value_string)) as 除地价外直投含税
    into #f0310_cdjwzt
    from #F0310 f03
    inner join 
    (
    select 实体分期,max(年+case when len(期间) = 2 then '0'+期间 else 期间 end)  as 最大年月
        from  #F0310
    group by 实体分期) t on f03.实体分期 = t.实体分期 and 年+case when len(期间) = 2 then '0'+期间 else 期间 end = t.最大年月
    --where f03.ProjGUID = 'CDFB9004-2C85-EE11-B3A4-F40270D39969'
    group by f03.ProjGUID

	--缓存F080008Calc_IRRNPV表的数据
	select sum(convert(decimal(32,6),irr.value_string))value_string ,isnull(pp.projguid,p.projguid)projguid
	into #f08_Calc
	from data_wide_qt_F080008Calc_IRRNPV irr
	inner join data_wide_dws_ys_ProjGUID pj on irr.实体分期无聚合 = pj.YLGHProjGUID and pj.isbase = 1 and pj.Level = 2 and pj.BusinessEdition = irr.版本
	left join data_wide_dws_mdm_Project p on pj.YLGHProjGUID = p.projguid 
	left join data_wide_dws_mdm_Project pp on p.parentguid = pp.projguid and pp.level =2
    where irr.IRRNPV科目 = '全投资IRR' and CHARINDEX('e', ISNULL(irr.VALUE_STRING, '0')) = 0
	group by isnull(pp.projguid,p.projguid)
	
	--缓存自有资金IRR
	select isnull(pp.projguid,p.projguid)projguid,sum(convert(decimal(32,6),irr.value_string))value_string
	into #f08_zyIRR
	from data_wide_qt_F080008Calc_IRRNPV irr
	inner join data_wide_dws_ys_ProjGUID pj on irr.实体分期无聚合 = pj.YLGHProjGUID and pj.isbase = 1 and pj.Level = 2 and pj.BusinessEdition = irr.版本
	left join data_wide_dws_mdm_Project p on pj.YLGHProjGUID = p.projguid 
	left join data_wide_dws_mdm_Project pp on p.parentguid = pp.projguid and pp.level =2
    where irr.IRRNPV科目 = '自有资金IRR' and CHARINDEX('e', ISNULL(irr.VALUE_STRING, '0')) = 0
	group by isnull(pp.projguid,p.projguid)
	
	--缓存F080006的数据，取保利方的利润情况
	select pj.ProjGUID,
	sum(case when 报表预测项目科目 = '总投资（计划含税）' then convert(decimal(32,6),VALUE_STRING) else 0 end) 股东总成本含税计划口径,
	sum(case when 报表预测项目科目 = '总投资（财务不含税）' then convert(decimal(32,6),VALUE_STRING) else 0 end) 股东总成本不含税财务口径,
	sum(case when 报表预测项目科目 = '留置资产' then convert(decimal(32,6),VALUE_STRING) else 0 end) 股东固定资产计划口径,
	sum(case when 报表预测项目科目 = '税后利润（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) 股东税后利润计划口径,
	sum(case when 报表预测项目科目 = '税前利润（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) 股东税前利润计划口径,
	sum(case when 报表预测项目科目 = '净现金' then convert(decimal(32,6),VALUE_STRING) else 0 end) 股东税后净现金计划口径
	into #f0806
	from data_wide_qt_F080006 f0806
	inner join data_wide_dws_ys_ProjGUID pj on f0806.实体分期 = pj.YLGHProjGUID and pj.isbase = 1  and pj.BusinessEdition = f0806.版本 and pj.Level = 3
	where 报表预测项目科目 in ( '总投资（计划含税）','留置资产','税后利润（计划） ','税前利润（计划）','净现金' )
	and 明细说明 = '调整后' and CHARINDEX('e', ISNULL(VALUE_STRING, '0')) = 0
	group by  pj.ProjGUID 
	
	--缓存F080006的数据，取保利方调整额的利润情况
	select pj.ProjGUID,
	sum(case when 报表预测项目科目 = '总投资（计划含税）' then convert(decimal(32,6),VALUE_STRING) else 0 end) 保利方总投资含税计划调整项,
	sum(case when 报表预测项目科目 = '留置资产' then convert(decimal(32,6),VALUE_STRING) else 0 end) 保利方固定资产调整项,
	sum(case when 报表预测项目科目 = '税后利润（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) 保利方税后利润计划调整项,
	sum(case when 报表预测项目科目 = '税前利润（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) 保利方税前利润计划调整项,
	sum(case when 报表预测项目科目 = '净现金' then convert(decimal(32,6),VALUE_STRING) else 0 end) 保利方净现金调整项
	into #f0806_tze
	from data_wide_qt_F080006 f0806
	inner join data_wide_dws_ys_ProjGUID pj on f0806.实体分期 = pj.YLGHProjGUID and pj.isbase = 1  and pj.BusinessEdition = f0806.版本 and pj.Level = 3
	where 报表预测项目科目 in ( '总投资（计划含税）','留置资产','税后利润（计划） ','税前利润（计划）','净现金' )
	and 明细说明 = '调整额' and CHARINDEX('e', ISNULL(VALUE_STRING, '0')) = 0
	group by  pj.ProjGUID 

	 
	 --获取基础收益数据
	 select 
	 yt.ProjGUID [项目guid],
	 sum(case when 报表预测项目科目 = '结转面积' and 综合维 = '合计' then convert(decimal(32,6),VALUE_STRING) else 0 end) [面积_算单方], 
	 sum(case when 报表预测项目科目 = '结转面积' and 综合维 = '合计' and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) in ('住宅','别墅','高级住宅') then convert(decimal(32,6),VALUE_STRING) else 0 end) 住宅结转面积,
	 sum(case when 报表预测项目科目 = '结转面积' and 综合维 = '合计' and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) in ('地下室/车库') then convert(decimal(32,6),VALUE_STRING) else 0 end) 车位结转面积,
	 sum(case when 报表预测项目科目 = '结转面积' and 综合维 = '合计' and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) not in ('住宅','别墅','高级住宅','地下室/车库') then convert(decimal(32,6),VALUE_STRING) else 0 end) 商办结转面积,
	 sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '结转面积' then convert(decimal(32,6),VALUE_STRING) else 0 end) [总可售面积], 
	 sum(case when 综合维 = '经营产品' and 报表预测项目科目 = '结转面积' then convert(decimal(32,6),VALUE_STRING) else 0 end) [自持面积],
	 --收益数据：F080004
	 sum(case when 综合维 = '合计' and 报表预测项目科目 in ('营业税下收入','增值税下含税收入') then convert(decimal(32,6),VALUE_STRING) else 0 end) [销售收入含税], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '销售收入(不含税）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [销售收入不含税], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '结转成本' then convert(decimal(32,6),VALUE_STRING) else 0 end) [营业成本], 
	 sum(CASE WHEN [报表预测项目科目] in ('结转成本') AND 综合维 = '经营产品'  then CAST(ISNULL(F08.VALUE_STRING,'0') AS decimal(32,6)) END) AS 结转成本,
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '总成本（含税，计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [总成本含税计划口径], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '总成本（不含税，计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [总成本不含税计划口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '总成本（不含税，账面）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [总成本不含税账面口径], 
	 sum(CASE WHEN [报表预测项目科目] ='总成本（不含税，计划）' AND f08.[综合维]='经营产品' then  convert(decimal(32,6),VALUE_STRING) else 0 end)  AS 固定资产计划口径,	
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '资本化利息' then convert(decimal(32,6),VALUE_STRING) else 0 end) [资本化利息], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '费用化利息' then convert(decimal(32,6),VALUE_STRING) else 0 end) 费用化利息, 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '财务费用（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [财务费用计划口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '营销费用' then convert(decimal(32,6),VALUE_STRING) else 0 end) [营销费用], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '综合管理费用-协议口径' then convert(decimal(32,6),VALUE_STRING) else 0 end) [综合管理费协议口径], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '综合管理费用-管控口径' then convert(decimal(32,6),VALUE_STRING) else 0 end) [综合管理费管控口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 in ('土地增值税','增值税下附加税','营业税下营业税、附加税','其他税费','印花税') then convert(decimal(32,6),VALUE_STRING) else 0 end) [税金及附加], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '土地增值税' then convert(decimal(32,6),VALUE_STRING) else 0 end) [土地增值税],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '增值税下附加税' then convert(decimal(32,6),VALUE_STRING) else 0 end) [增值税下附加税], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '营业税下营业税、附加税' then convert(decimal(32,6),VALUE_STRING) else 0 end) [营业税下营业税附加税], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税前利润（账面）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [税前利润账面口径], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税前利润（账面）扣减股权溢价' then convert(decimal(32,6),VALUE_STRING) else 0 end) [税前利润账面口径扣减股权溢价], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税前利润（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [税前利润计划口径], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税后现金利润（账面）'  then convert(decimal(32,6),VALUE_STRING) else 0 end)  [税后现金利润账面口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税后现金利润（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end)  [税后现金利润计划口径],
	 sum(case when 综合维 = '合计' and  报表预测项目科目 = '股权溢价' then convert(decimal(32,6),VALUE_STRING) else 0 end) [股权溢价], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税后利润（账面）'  then convert(decimal(32,6),VALUE_STRING) else 0 end) [税后利润账面口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税后利润（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [税后利润计划口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '毛利率' then convert(decimal(32,6),VALUE_STRING) else 0 end) [毛利率], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '毛利率(扣股权溢价)' then convert(decimal(32,6),VALUE_STRING) else 0 end) [毛利率_扣除股权溢价], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税前成本利润率（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [税前成本利润率_计划口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税前销售利润率（账面）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [税前销售利润率_账面口径], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '销售净利率（账面）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [销售净利率_账面口径],
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '税后成本利润率（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [税后成本利润率_计划口径], 
	 sum(case when 综合维 = '合计' and 报表预测项目科目 = '销售净利率（计划）' then convert(decimal(32,6),VALUE_STRING) else 0 end) [销售净利率_计划口径]
	 ,sum(case when 综合维 = '合计' and 报表预测项目科目 = '所得税' then convert(decimal(32,6),VALUE_STRING) else 0 end) [所得税]
	 into #lr
	 from #f08 f08 
	 inner JOIN data_wide_dws_ys_projguid yt ON  f08.实体分期 = yt.YLGHProjGUID and yt.Level = 3  and yt.isbase = 1
	 left join data_wide_dws_ys_SumProjProductYt syt on syt.ProjGUID = f08.实体分期 and syt.IsBase = 1 and syt.YtName = f08.业态
	 left join (select HierarchyName,ParentName,rank() over(partition by HierarchyName order by ParentName desc) as rn from data_wide_mdm_ProductType) ty ON syt.ProductType = ty.HierarchyName and ty.rn = 1
	 group by yt.ProjGUID 

    --获取成本数据
    select 
    项目guid,
    sum(总成本财务口径不含税_财务分摊) as 总成本财务口径不含税_财务分摊,
    sum(土地款不含税_财务分摊) [土地款不含税_财务分摊],
	sum(住宅土地款不含税_财务分摊) [住宅土地款不含税_财务分摊],
	sum(商办土地款不含税_财务分摊) [商办土地款不含税_财务分摊],
	sum(车位土地款不含税_财务分摊) [车位土地款不含税_财务分摊],
    sum(总成本财务口径不含税_财务分摊)-sum(土地款不含税_财务分摊)-sum(开发间接费不含税_财务分摊)-sum(资本化利息不含税_财务分摊) [除地价外直投不含税_财务分摊],
    sum(开发前期费不含税_财务分摊) [开发前期费不含税_财务分摊],
    sum(建筑安装工程费不含税_财务分摊) [建筑安装工程费不含税_财务分摊],
    sum(室内精装工程不含税_财务分摊) [室内精装工程不含税_财务分摊],
    sum(红线内配套费不含税_财务分摊) [红线内配套费不含税_财务分摊],
    sum(园林绿化工程不含税_财务分摊) [园林绿化工程不含税_财务分摊],
    sum(政府收费不含税_财务分摊) [政府收费不含税_财务分摊], 
    sum(不可预见费不含税_财务分摊) [不可预见费不含税_财务分摊], 
    sum(公建分摊_土地不含税_财务分摊) [公建分摊_土地不含税_财务分摊],
    sum(公建分摊_利息不含税_财务分摊) [公建分摊_利息不含税_财务分摊],
    sum(公建分摊_其他不含税_财务分摊) [公建分摊_其他不含税_财务分摊],
    sum(开发间接费不含税_财务分摊) [开发间接费不含税_财务分摊] ,
    sum(资本化利息不含税_财务分摊) [资本化利息不含税_财务分摊] 
    into #cb
    from (
    --自持不可售
    select yt.ProjGUID [项目guid], 
    sum(convert(decimal(32,6),value_string)) [总成本财务口径不含税_财务分摊], 
    sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') then convert(decimal(32,6),value_string) else 0 end) [土地款不含税_财务分摊],
    sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') 
	and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) in ('住宅','别墅','高级住宅') then convert(decimal(32,6),value_string) else 0 end) [住宅土地款不含税_财务分摊],
	sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') 
	and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) in ('地下室/车库') then convert(decimal(32,6),value_string) else 0 end) [车位土地款不含税_财务分摊],
	sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') 
	and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) not in ('住宅','别墅','高级住宅','地下室/车库') then convert(decimal(32,6),value_string) else 0 end) [商办土地款不含税_财务分摊],
	0 [除地价外直投不含税_财务分摊],
    sum(case when 成本预测科目 in ('初勘、详勘','其它勘察费','概念、规划设计','方案至施工图设计','室内设计','园林绿化工程设计','施工图审查','其它设计费','咨询费、评估费','环评费','招投标代理费','其它委托费用','管线迁移','临时用电','临时用水','其它临时设施费','其他开发前期费') then convert(decimal(32,6),value_string) else 0 end) [开发前期费不含税_财务分摊],
    sum(case when 成本预测科目 in ('大型土石方工程','桩基础工程','基坑支护工程','土建结构工程','幕墙工程','外墙涂料、砖等','外墙门窗','栏杆','防火门','入户门等','防水工程','保温工程','其他零星土建工程','室内精装工程','公共部位装修','水电安装工程','甲供水电材料及设备','消防工程','电梯工程','空调工程','人防设备及安装','供暖设备','其他专业安装工程','工程检测费','工程监理费','其它建筑安装工程') then convert(decimal(32,6),value_string) else 0 end) [建筑安装工程费不含税_财务分摊],
    sum(case when 成本预测科目 = '室内精装工程' then convert(decimal(32,6),value_string) else 0 end) [室内精装工程不含税_财务分摊],
    sum(case when 成本预测科目 in ('永水工程','永电工程','智能化工程','煤气工程','市政工程','园林绿化工程','供暖工程','有线电视及电信工程','标识系统工程','其它红线内配套工程') then convert(decimal(32,6),value_string) else 0 end) [红线内配套费不含税_财务分摊],
    sum(case when 成本预测科目 = '园林绿化工程' then convert(decimal(32,6),value_string) else 0 end) [园林绿化工程不含税_财务分摊],
    sum(case when 成本预测科目 in ('市政配套费','物业维修基金','其它政府收费') then convert(decimal(32,6),value_string) else 0 end) [政府收费不含税_财务分摊], 
    sum(case when 成本预测科目 = '不可预见费' then convert(decimal(32,6),value_string) else 0 end) [不可预见费不含税_财务分摊], 
    sum(case when 成本预测科目 = '土地' then convert(decimal(32,6),value_string) else 0 end) [公建分摊_土地不含税_财务分摊],
    sum(case when 成本预测科目 = '利息' then convert(decimal(32,6),value_string) else 0 end) [公建分摊_利息不含税_财务分摊],
    sum(case when 成本预测科目 = '其他' then convert(decimal(32,6),value_string) else 0 end) [公建分摊_其他不含税_财务分摊],
    sum(case when 成本预测科目 = '开发间接费' then convert(decimal(32,6),value_string) else 0 end) [开发间接费不含税_财务分摊], 
    sum(case when 成本预测科目 = '资本化利息' then convert(decimal(32,6),value_string) else 0 end) [资本化利息不含税_财务分摊]
    from #f0302  F03 
    LEFT JOIN data_wide_dws_ys_projguid yt ON  f03.实体分期 = yt.YLGHProjGUID and yt.Level = 3  and yt.isbase = 1   
	inner join data_wide_dws_ys_SumProjProductYt syt on syt.ProjGUID = f03.实体分期 and syt.IsBase = 1 and syt.YtName = f03.业态
	left join (select HierarchyName,ParentName,rank() over(partition by HierarchyName order by ParentName desc) as rn from data_wide_mdm_ProductType) ty ON syt.ProductType = ty.HierarchyName and ty.rn = 1
    group by  yt.ProjGUID
    union all 
    --可售不自持
    select  yt.ProjGUID [项目guid], 
    sum(convert(decimal(32,6),value_string)) [总成本财务口径不含税_财务分摊], 
    sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') then convert(decimal(32,6),value_string) else 0 end) [土地款不含税_财务分摊],
      sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') 
	and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) in ('住宅','别墅','高级住宅') then convert(decimal(32,6),value_string) else 0 end) [住宅土地款不含税_财务分摊],
	sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') 
	and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) in ('地下室/车库') then convert(decimal(32,6),value_string) else 0 end) [车位土地款不含税_财务分摊],
	sum(case when 成本预测科目 in ('国土出让金','土地转让金','原始成本','股权溢价','拆迁补偿费','土地抵减税金','契税','其它土地款') 
	and isnull(ty.parentname,isnull(ty.HierarchyName,'别墅')) not in ('住宅','别墅','高级住宅','地下室/车库') then convert(decimal(32,6),value_string) else 0 end) [商办土地款不含税_财务分摊],
	0 [除地价外直投不含税_财务分摊],
    sum(case when 成本预测科目 in ('初勘、详勘','其它勘察费','概念、规划设计','方案至施工图设计','室内设计','园林绿化工程设计','施工图审查','其它设计费','咨询费、评估费','环评费','招投标代理费','其它委托费用','管线迁移','临时用电','临时用水','其它临时设施费','其他开发前期费') then convert(decimal(32,6),value_string) else 0 end) [开发前期费不含税_财务分摊],
    sum(case when 成本预测科目 in ('大型土石方工程','桩基础工程','基坑支护工程','土建结构工程','幕墙工程','外墙涂料、砖等','外墙门窗','栏杆','防火门','入户门等','防水工程','保温工程','其他零星土建工程','室内精装工程','公共部位装修','水电安装工程','甲供水电材料及设备','消防工程','电梯工程','空调工程','人防设备及安装','供暖设备','其他专业安装工程','工程检测费','工程监理费','其它建筑安装工程') then convert(decimal(32,6),value_string) else 0 end) [建筑安装工程费不含税_财务分摊],
    sum(case when 成本预测科目 = '室内精装工程' then convert(decimal(32,6),value_string) else 0 end) [室内精装工程不含税_财务分摊],
    sum(case when 成本预测科目 in ('永水工程','永电工程','智能化工程','煤气工程','市政工程','园林绿化工程','供暖工程','有线电视及电信工程','标识系统工程','其它红线内配套工程') then convert(decimal(32,6),value_string) else 0 end) [红线内配套费不含税_财务分摊],
    sum(case when 成本预测科目 = '园林绿化工程' then convert(decimal(32,6),value_string) else 0 end) [园林绿化工程不含税_财务分摊],
    sum(case when 成本预测科目 in ('市政配套费','物业维修基金','其它政府收费') then convert(decimal(32,6),value_string) else 0 end) [政府收费不含税_财务分摊], 
    sum(case when 成本预测科目 = '不可预见费' then convert(decimal(32,6),value_string) else 0 end) [不可预见费不含税_财务分摊], 
    sum(case when 成本预测科目 = '土地' then convert(decimal(32,6),value_string) else 0 end) [公建分摊_土地不含税_财务分摊],
    sum(case when 成本预测科目 = '利息' then convert(decimal(32,6),value_string) else 0 end) [公建分摊_利息不含税_财务分摊],
    sum(case when 成本预测科目 = '其他' then convert(decimal(32,6),value_string) else 0 end) [公建分摊_其他不含税_财务分摊],
    sum(case when 成本预测科目 = '开发间接费' then convert(decimal(32,6),value_string) else 0 end) [开发间接费不含税_财务分摊], 
    sum(case when 成本预测科目 = '资本化利息' then convert(decimal(32,6),value_string) else 0 end) [资本化利息不含税_财务分摊]
    from #f0308  F03
    LEFT JOIN data_wide_dws_ys_projguid yt ON  f03.实体分期 = yt.YLGHProjGUID and yt.Level = 3  and yt.isbase = 1    
	inner join data_wide_dws_ys_SumProjProductYt syt on syt.ProjGUID = f03.实体分期 and syt.IsBase = 1 and syt.YtName = f03.业态
	left join (select HierarchyName,ParentName,rank() over(partition by HierarchyName order by ParentName desc) as rn from data_wide_mdm_ProductType) ty ON syt.ProductType = ty.HierarchyName and ty.rn = 1
    group by yt.ProjGUID)t
    group by 项目guid

    INSERT INTO #tmp_dw_f_TopProJect_ProfitCost_ylgh
  (  
    --基础数据：F080004
    [项目guid], 
	项目名称,
	项目推广名,
    [总可售面积], 
    [自持面积],
    --收益数据：F080004
    [销售收入含税], 
    [销售收入不含税], 
    [营业成本], 
    [总成本含税计划口径], 
    [总成本不含税计划口径],
    [总成本不含税账面口径], 
    [资本化利息], 
    [财务费用计划口径],
    [营销费用], 
    [综合管理费协议口径], 
    [综合管理费管控口径],
    [税金及附加], 
    [土地增值税],
    [增值税下附加税], 
    [营业税下营业税附加税], 
    [税前利润账面口径], 
    [税前利润计划口径], 
    [税后现金利润账面口径],
    [税后现金利润计划口径],
    [股权溢价], 
    [税后利润账面口径],

    [税后利润计划口径],
    [毛利率], 
    [毛利率_扣除股权溢价], 
    [税前成本利润率_计划口径],
    [税前销售利润率_账面口径], 
    [销售净利率_账面口径],
    [税后成本利润率_计划口径], 
    [销售净利率_计划口径],
    
    ----成本数据：不含税
    [总成本财务口径不含税_财务分摊], 
    [土地款不含税_财务分摊],
    [除地价外直投不含税_财务分摊],
    [除地价外直投含税],
    [开发前期费不含税_财务分摊],
    [建筑安装工程费不含税_财务分摊],
    [室内精装工程不含税_财务分摊],
    [红线内配套费不含税_财务分摊],
    [园林绿化工程不含税_财务分摊],
    [政府收费不含税_财务分摊], 
    [不可预见费不含税_财务分摊], 
    [公建分摊_土地不含税_财务分摊],
    [公建分摊_利息不含税_财务分摊],
    [公建分摊_其他不含税_财务分摊],
    [开发间接费不含税_财务分摊],   

    --收益单方
    [销售收入含税单方], 
    [销售收入不含税单方], 
    [营业成本单方], 
    [总成本含税单方计划口径],
    [总成本不含税单方计划口径],
    [总成本不含税单方账面口径],
    [资本化利息单方],
    [财务费用单方计划口径], 
    [营销费用单方], 
    [综合管理费单方协议口径], 
    [综合管理费单方管控口径], 
    [税金及附加单方], 
    [土地增值税单方],
    [增值税下附加税单方],
    [营业税下营业税附加税单方], 
    [税前利润单方账面口径], 
    [税前利润单方计划口径], 
    [税后现金利润单方账面口径], 
    [税后现金利润单方计划口径],
    [股权溢价单方], 
    [税后利润单方账面口径],
    [税后利润单方计划口径],  
    --成本单方
    [总成本财务口径不含税单方_财务分摊], 
    [土地款不含税单方_财务分摊], 
    [除地价外直投不含税单方_财务分摊], 
    [除地价外直投含税单方],
    [开发前期费不含税单方_财务分摊], 
    [建筑安装工程费不含税单方_财务分摊],
    [室内精装工程不含税单方_财务分摊], 
    [红线内配套费不含税单方_财务分摊], 
    [园林绿化工程不含税单方_财务分摊],
    [政府收费不含税单方_财务分摊], 
    [不可预见费不含税单方_财务分摊], 
    [公建分摊_土地不含税单方_财务分摊],
    [公建分摊_利息不含税单方_财务分摊], 
    [公建分摊_其他不含税单方_财务分摊], 
    [开发间接费不含税单方_财务分摊],
    [资本化利息不含税单方_财务分摊] ,

	--2022-12-06新增
	税后净现金计划口径   ,
	固定资产计划口径     ,
	全投资IRR计划口径  ,
	税前成本利润率_账面口径 , 
	总成本含税账面口径 , 
	除地价外直投不含税_财务分摊账面口径  ,
    [除地价外直投含税_账面口径],
	财务费用账面口径    ,
	营销费用账面口径    ,
	综合管理费协议口径_账面口径  , 
	税后净现金账面口径       ,
	固定资产账面口径     ,
	全投资IRR账面 ,

	--------------股东层面
	--计划口径
	股东税前成本利润率_计划口径,
	股东税前利润计划口径,
	股东总成本含税计划口径,
	股东除地价外直投不含税_财务分摊 ,
	股东除地价外直投含税,
	股东财务费用计划口径    ,
	股东营销费用      ,
	股东综合管理费协议口径   ,
	股东税后利润计划口径     ,
	股东税后净现金计划口径       ,  --税后现金利润
	股东固定资产计划口径     ,
	股东全投资IRR计划口径 ,

	 
	--财务口径
	股东税前成本利润率_账面口径,
	股东税前利润账面口径,
	股东总成本含税账面口径, --等于含税总投资计划- 财务
	股东除地价外直投不含税_财务分摊账面口径 ,
    股东除地价外直投含税_账面口径,
	股东财务费用账面口径    ,
	股东营销费用账面口径    ,
	股东综合管理费协议口径_账面口径  ,
	股东税后利润账面口径     ,
	股东税后净现金账面口径       ,
	股东固定资产账面口径     ,
	股东全投资IRR账面 ,

	--20221216 新增
	[住宅土地款不含税_财务分摊],
	[住宅土地款不含税单方_财务分摊],
	[住宅结转面积],
	[车位土地款不含税_财务分摊],
	[车位土地款不含税单方_财务分摊],
	[车位结转面积],
	[商办土地款不含税_财务分摊],
	[商办土地款不含税单方_财务分摊],
	[商办结转面积],
	[税前利润账面口径扣减股权溢价],
	股东总成本不含税财务口径
	,所得税
	,结转成本
      )
    
    select 
    --基础数据：F080004
    pj.ProjGUID [项目guid], 
	pj.ProjName as 项目名称,
	pj.SpreadName as 项目推广名,
    f08.总可售面积 [总可售面积], 
    f08.自持面积 [自持面积],
    --收益数据：F080004
    f08.[销售收入含税], 
    f08.[销售收入不含税], 
    f08.[营业成本], 
    f08.[总成本含税计划口径], 
    f08.[总成本不含税计划口径],
    f08.[总成本不含税账面口径], 
    f08.[资本化利息], 
    f08.[财务费用计划口径],
    f08.[营销费用], 
    f08.[综合管理费协议口径], 
    f08.[综合管理费管控口径],
    f08.[税金及附加], 
    f08.[土地增值税],
    f08.[增值税下附加税], 
    f08.[营业税下营业税附加税], 
    f08.[税前利润账面口径], 
    f08.[税前利润计划口径], 
    f08.[税后现金利润账面口径],
    f08.[税后现金利润计划口径],
    f08.[股权溢价], 
    f08.[税后利润账面口径],
	
    f08.[税后利润计划口径],
    case when f08.销售收入不含税 = 0 then 0 else 1-f08.营业成本/f08.[销售收入不含税] end [毛利率], --(1-营业成本)/销售收入不含税
    case when f08.销售收入不含税 = 0 then 0 else 1-(f08.[营业成本]-f08.[股权溢价])/f08.[销售收入不含税] end [毛利率_扣除股权溢价], --（1-营销成本-股权溢价）/销售收入不含税
    case when f08.总成本含税计划口径 = 0 then 0 else f08.税前利润计划口径/f08.[总成本含税计划口径] end [税前成本利润率_计划口径], --税前利润（计划）/总成本（含税，计划）
    case when f08.销售收入不含税 = 0 then 0 else f08.税前利润账面口径/f08.[销售收入不含税] end [税前销售利润率_账面口径], --税前利润（账面）/销售收入不含税
    case when f08.销售收入不含税 = 0 then 0 else f08.税后利润账面口径/f08.[销售收入不含税] end [销售净利率_账面口径], --税后利润（账面）/销售收入不含税
    case when f08.总成本含税计划口径 = 0 then 0 else f08.[税后利润计划口径]/f08.[总成本含税计划口径] end [税后成本利润率_计划口径], --税后利润（计划）/总成本（含税，计划）
    case when f08.销售收入不含税 = 0 then 0 else f08.税后利润计划口径/f08.[销售收入不含税] end [销售净利率_计划口径], --税后利润（计划）/销售收入不含税
  
    ----成本数据：不含税
    f03.[总成本财务口径不含税_财务分摊], 
    f03.[土地款不含税_财务分摊],
    f03.[除地价外直投不含税_财务分摊],
    f0310.[除地价外直投含税],
    f03.[开发前期费不含税_财务分摊],
    f03.[建筑安装工程费不含税_财务分摊],
    f03.[室内精装工程不含税_财务分摊],
    f03.[红线内配套费不含税_财务分摊],
    f03.[园林绿化工程不含税_财务分摊],
    f03.[政府收费不含税_财务分摊], 
    f03.[不可预见费不含税_财务分摊], 
    f03.[公建分摊_土地不含税_财务分摊],
    f03.[公建分摊_利息不含税_财务分摊],
    f03.[公建分摊_其他不含税_财务分摊],
    f03.[开发间接费不含税_财务分摊], 

    --收益单方
    case when f08.面积_算单方 = 0 then 0 else f08.销售收入含税/f08.面积_算单方 end [销售收入含税单方], 
    case when f08.面积_算单方 = 0 then 0 else f08.销售收入不含税/f08.面积_算单方 end [销售收入不含税单方], 
    case when f08.面积_算单方=0 then 0 else f08.营业成本/f08.面积_算单方 end  [营业成本单方], 
    case when f08.面积_算单方=0 then 0 else f08.总成本含税计划口径/f08.面积_算单方 end  [总成本含税单方计划口径],
    case when f08.面积_算单方=0 then 0 else f08.总成本不含税计划口径/f08.面积_算单方 end  [总成本不含税单方计划口径],
    case when f08.面积_算单方=0 then 0 else f08.总成本不含税账面口径/f08.面积_算单方 end  [总成本不含税单方账面口径],
    case when f08.面积_算单方=0 then 0 else f08.资本化利息/f08.面积_算单方 end  [资本化利息单方],
    case when f08.面积_算单方=0 then 0 else f08.财务费用计划口径/f08.面积_算单方 end  [财务费用单方计划口径], 
    case when f08.面积_算单方=0 then 0 else f08.营销费用/f08.面积_算单方 end  [营销费用单方], 
    case when f08.面积_算单方=0 then 0 else f08.综合管理费协议口径/f08.面积_算单方 end  [综合管理费单方协议口径], 
    case when f08.面积_算单方=0 then 0 else f08.综合管理费管控口径/f08.面积_算单方 end  [综合管理费单方管控口径], 
    case when f08.面积_算单方=0 then 0 else f08.税金及附加/f08.面积_算单方 end  [税金及附加单方], 
    case when f08.面积_算单方=0 then 0 else f08.土地增值税/f08.面积_算单方 end  [土地增值税单方],
    case when f08.面积_算单方=0 then 0 else f08.增值税下附加税/f08.面积_算单方 end  [增值税下附加税单方],
    case when f08.面积_算单方=0 then 0 else f08.营业税下营业税附加税/f08.面积_算单方 end  [营业税下营业税附加税单方], 
    case when f08.面积_算单方=0 then 0 else f08.税前利润账面口径/f08.面积_算单方 end  [税前利润单方账面口径], 
    case when f08.面积_算单方=0 then 0 else f08.税前利润计划口径/f08.面积_算单方 end  [税前利润单方计划口径], 
    case when f08.面积_算单方=0 then 0 else f08.税后现金利润账面口径/f08.面积_算单方 end  [税后现金利润单方账面口径], 
    case when f08.面积_算单方=0 then 0 else f08.税后现金利润计划口径/f08.面积_算单方 end  [税后现金利润单方计划口径],
    case when f08.面积_算单方=0 then 0 else f08.股权溢价/f08.面积_算单方 end  [股权溢价单方], 
    case when f08.面积_算单方=0 then 0 else f08.税后利润账面口径/f08.面积_算单方 end  [税后利润单方账面口径],
    case when f08.面积_算单方=0 then 0 else f08.税后利润计划口径/f08.面积_算单方 end  [税后利润单方计划口径],  
    --成本单方
    case when f08.面积_算单方=0 then 0 else f03.总成本财务口径不含税_财务分摊/f08.面积_算单方 end  [总成本财务口径不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.土地款不含税_财务分摊/f08.面积_算单方 end   [土地款不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.除地价外直投不含税_财务分摊/f08.面积_算单方 end   [除地价外直投不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f0310.[除地价外直投含税]/f08.面积_算单方 end   [除地价外直投含税单方], 
    case when f08.面积_算单方=0 then 0 else f03.开发前期费不含税_财务分摊/f08.面积_算单方 end   [开发前期费不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.建筑安装工程费不含税_财务分摊/f08.面积_算单方 end   [建筑安装工程费不含税单方_财务分摊],
    case when f08.面积_算单方=0 then 0 else f03.室内精装工程不含税_财务分摊/f08.面积_算单方 end   [室内精装工程不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.红线内配套费不含税_财务分摊/f08.面积_算单方 end   [红线内配套费不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.园林绿化工程不含税_财务分摊/f08.面积_算单方 end   [园林绿化工程不含税单方_财务分摊],
    case when f08.面积_算单方=0 then 0 else f03.政府收费不含税_财务分摊/f08.面积_算单方 end   [政府收费不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.不可预见费不含税_财务分摊/f08.面积_算单方 end   [不可预见费不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.公建分摊_土地不含税_财务分摊/f08.面积_算单方 end   [公建分摊_土地不含税单方_财务分摊],
    case when f08.面积_算单方=0 then 0 else f03.公建分摊_利息不含税_财务分摊/f08.面积_算单方 end   [公建分摊_利息不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.公建分摊_其他不含税_财务分摊/f08.面积_算单方 end   [公建分摊_其他不含税单方_财务分摊], 
    case when f08.面积_算单方=0 then 0 else f03.开发间接费不含税_财务分摊/f08.面积_算单方 end   [开发间接费不含税单方_财务分摊],
    case when f08.面积_算单方=0 then 0 else f03.资本化利息不含税_财务分摊/f08.面积_算单方 end   [资本化利息不含税单方_财务分摊] ,
	--2022-12-06新增
	f08.税后现金利润计划口径 税后净现金计划口径   , 
	固定资产计划口径 固定资产计划口径     ,
	convert(decimal(32,6),irr.value_string) 全投资IRR计划口径  , 
	
	--case when f08.[总成本含税计划口径]-f08.[财务费用计划口径]=0 then 0 else f08.[税前利润账面口径]/(f08.[总成本含税计划口径]-f08.[财务费用计划口径]) end 税前成本利润率_账面口径 , 
	case when f08.[总成本含税计划口径]=0 then 0 else f08.[税前利润账面口径]/(f08.[总成本含税计划口径]) end 税前成本利润率_账面口径 , 
	f08.[总成本含税计划口径] 总成本含税账面口径 , --等于含税总投资计划- 财务
	--f08.[总成本含税计划口径]-f08.[财务费用计划口径] 总成本含税账面口径 , --等于含税总投资计划- 财务
	f03.除地价外直投不含税_财务分摊 除地价外直投不含税_财务分摊账面口径  ,
    f0310.[除地价外直投含税] 除地价外直投含税_账面口径  ,
	isnull(f08.资本化利息,0)+isnull(f08.费用化利息,0) 财务费用账面口径    ,
	f08.[营销费用] 营销费用账面口径    , --跟计划口径一致
	f08.[综合管理费协议口径] 综合管理费协议口径_账面口径  ,  --跟计划口径一致
	f08.税后现金利润账面口径 税后净现金账面口径       ,--等于税后现金利润
	固定资产计划口径 固定资产账面口径     , --跟计划口径一致
	convert(decimal(32,6),irr.value_string) 全投资IRR账面 ,--跟计划口径一致

	--------------股东层面
	--计划口径
	case when f0806.股东总成本含税计划口径 = 0 then 0 else f0806.股东税前利润计划口径/f0806.股东总成本含税计划口径 end 股东税前成本利润率_计划口径,
	f0806.股东税前利润计划口径,
	f0806.股东总成本含税计划口径,
	f03.除地价外直投不含税_财务分摊*pj.EquityRatio/100.0 股东除地价外直投不含税_财务分摊 ,--除地价外直投*权益比例
    f0310.[除地价外直投含税]*pj.EquityRatio/100.0 股东除地价外直投含税 ,--除地价外直投*权益比例
	f08.[财务费用计划口径]*pj.EquityRatio/100.0 股东财务费用计划口径    ,
	f08.[营销费用]*pj.EquityRatio/100.0 股东营销费用      ,
	f08.[综合管理费协议口径]*pj.EquityRatio/100.0 股东综合管理费协议口径   ,
	f0806.股东税后利润计划口径  ,
	f0806.股东税后净现金计划口径 , 
	--f0806.股东固定资产计划口径     ,
	(isnull(f0806.股东税后利润计划口径,0)-isnull(f0806.股东税后净现金计划口径,0))as 股东固定资产计划口径,
	--convert(decimal(32,6),irr.value_string)*pj.EquityRatio/100.0 股东全投资IRR计划口径 , --项目irr*权益比例
	convert(decimal(32,6),zyirr.value_string) 股东全投资IRR计划口径 , --项目irr*权益比例
	
	 
	--财务口径:用项目层级的财务口径*权益比例
	--case when (f08.[总成本含税计划口径]-f08.[财务费用计划口径])=0 then 0 else f08.税前利润账面口径/(f08.[总成本含税计划口径]-f08.[财务费用计划口径]) end 股东税前成本利润率_账面口径,
	--case when f08.[总成本含税计划口径]=0 then 0 else f08.税前利润账面口径*pj.EquityRatio/f08.[总成本含税计划口径]) end 股东税前成本利润率_账面口径,
	ISNULL(((f08.税后利润账面口径+isnull(f0806_tze.保利方税后利润计划调整项,0))*pj.EquityRatio/100.0/0.75)/NULLIF((((f08.[总成本含税计划口径])+isnull(f0806_tze.保利方总投资含税计划调整项,0))*pj.EquityRatio/100.0),0),0)as 股东税前成本利润率_账面口径,
	--ISNULL(((f08.税后利润账面口径+isnull(f0806_tze.保利方税后利润计划调整项,0))*pj.EquityRatio/100.0*0.75)/NULLIF(((f08.[总成本含税计划口径])+isnull(f0806_tze.保利方总投资含税计划调整项,0)*pj.EquityRatio/100.0),0),0) 股东税前成本利润率_账面口径,
	--f08.税前利润账面口径*pj.EquityRatio/100.0 股东税前利润账面口径,
	(f08.税后利润账面口径+isnull(f0806_tze.保利方税后利润计划调整项,0))*pj.EquityRatio/100.0/0.75 股东税前利润账面口径,
	((f08.[总成本含税计划口径])+isnull(f0806_tze.保利方总投资含税计划调整项,0))*pj.EquityRatio/100.0 股东总成本含税账面口径, 
	--(f08.[总成本含税计划口径]-f08.[财务费用计划口径])*pj.EquityRatio/100.0 股东总成本含税账面口径, --等于含税总投资计划-财务
	f03.除地价外直投不含税_财务分摊*pj.EquityRatio/100.0 股东除地价外直投不含税_财务分摊账面口径 ,
	f0310.[除地价外直投含税]*pj.EquityRatio/100.0 股东除地价外直投含税_账面口径 ,
	(isnull(f08.资本化利息,0)+isnull(f08.费用化利息,0))*pj.EquityRatio/100.0 股东财务费用账面口径    , --用资本化利息+费用化利息
	f08.[营销费用]*pj.EquityRatio/100.0 股东营销费用账面口径    ,
	f08.[综合管理费协议口径]*pj.EquityRatio/100.0 股东综合管理费协议口径_账面口径  ,
	--f08.税后利润账面口径*pj.EquityRatio/100.0 股东税后利润账面口径     ,
	(f08.税后利润账面口径+isnull(f0806_tze.保利方税后利润计划调整项,0))*pj.EquityRatio/100.0 股东税后利润账面口径     ,
	--f08.税后现金利润账面口径*pj.EquityRatio/100.0 股东税后净现金账面口径       ,
	(f08.税后现金利润账面口径+isnull(f0806_tze.保利方净现金调整项,0))*pj.EquityRatio/100.0 股东税后净现金账面口径       ,
	--固定资产计划口径*pj.EquityRatio/100.0 股东固定资产账面口径     ,
	(
	(f08.税后利润账面口径+isnull(f0806_tze.保利方税后利润计划调整项,0))-(f08.税后现金利润账面口径+isnull(f0806_tze.保利方净现金调整项,0))
	)*pj.EquityRatio/100.0 股东固定资产账面口径     ,
	convert(decimal(32,6),irr.value_string)*pj.EquityRatio/100.0 股东全投资IRR账面,  --项目的财务固定资产*权益比例

	住宅土地款不含税_财务分摊,
	case when isnull(住宅结转面积,0) =0 then 0 else 住宅土地款不含税_财务分摊/住宅结转面积 end [住宅土地款不含税单方_财务分摊],
	[住宅结转面积],
	[车位土地款不含税_财务分摊],
	case when isnull(车位结转面积,0) =0 then 0 else 车位土地款不含税_财务分摊/车位结转面积 end [车位土地款不含税单方_财务分摊],
	[车位结转面积],
	[商办土地款不含税_财务分摊],
	case when isnull(商办结转面积,0) =0 then 0 else 商办土地款不含税_财务分摊/商办结转面积 end [商办土地款不含税单方_财务分摊],
	[商办结转面积],
	f08.[税前利润账面口径扣减股权溢价],
	f0806.股东总成本不含税财务口径
	,f08.所得税
	,f08.结转成本
	from data_wide_dws_mdm_Project pj 
	left join #lr f08 on pj.ProjGUID =f08.项目guid
    left join #cb f03 on pj.ProjGUID =f03.项目guid
	left join #f08_Calc irr on irr.projguid = pj.ProjGUID	
	left join #f08_zyIRR zyirr on zyirr.ProjGUID = pj.ProjGUID	
	left join #f0806 f0806 on f0806.ProjGUID = pj.ProjGUID
	left join #f0806_tze f0806_tze on f0806_tze.ProjGUID = pj.ProjGUID
    left join #f0310_cdjwzt f0310 on f0310.ProjGUID = pj.ProjGUID
	where pj.Level = 2;
   
     
    --插入正式表数据
    DELETE FROM [dw_f_TopProJect_ProfitCost_ylgh]
    WHERE 1 = 1;

    INSERT INTO [dw_f_TopProJect_ProfitCost_ylgh]
    SELECT * 
    FROM #tmp_dw_f_TopProJect_ProfitCost_ylgh;

	select * from [dw_f_TopProJect_ProfitCost_ylgh] 

    --删除临时表
    DROP TABLE #tmp_dw_f_TopProJect_ProfitCost_ylgh;


END;


 
 
 