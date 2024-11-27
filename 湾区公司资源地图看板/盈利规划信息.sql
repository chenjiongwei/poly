--缓存业态信息
SELECT DISTINCT
    yt.ProjGUID,
    pj.projguid AS 项目guid,
    p.projcode_25 + '_' + ISNULL(ty.ParentName, ty.HierarchyName) + '_' + yt.ytname [业态组合键_业态],
    yt.ytname,
    ISNULL(ty.ParentName, ty.HierarchyName) [产品类型],
    LEFT(yt.ytname, CHARINDEX('_', yt.ytname) - 1) AS [产品名称],
    LEFT(SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100), CHARINDEX('_', SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100)) - 1) AS [商品类型],
    SUBSTRING(SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100), CHARINDEX('_', SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100)) + 1, 100) [装修标准]
INTO #yt
  FROM data_wide_dws_ys_SumProjProductYt yt
 INNER JOIN data_wide_dws_ys_ProjGUID pj
     ON yt.ProjGUID = pj.YLGHProjGUID
        AND pj.isbase = 1
        AND pj.level = 3
 INNER JOIN data_wide_dws_mdm_project p
     ON p.projguid = pj.ProjGUID
  LEFT JOIN
       (
           SELECT ty.ParentName,
               ty.HierarchyName,
               ROW_NUMBER() OVER (PARTITION BY HierarchyName ORDER BY HierarchyName DESC) AS rn
             FROM data_wide_mdm_ProductType ty
       ) ty
      ON yt.ProductType = ty.HierarchyName
         AND rn = 1
  WHERE yt.isbase = 1
        AND YtName <> '不区分业态'
        AND (p.projcode_25 + '_' + ISNULL(ty.ParentName, ty.HierarchyName) + '_' + yt.ytname) IS NOT NULL;

--缓存盈利规划的当前版本以及上个版本：rowno=1为当前版本，rowno=2为上个版本
SELECT 
    t.版本,
    t.实体分期,
    t.rowno,
    t.value_string
INTO #bb
  FROM
  (
      SELECT ROW_NUMBER() OVER (PARTITION BY f2.实体分期 ORDER BY f2.value_string DESC) rowno,
          f2.*,
          f4.value_string AS valuestring
        FROM data_wide_qt_F200003 f2
       INNER JOIN data_wide_qt_f400003年度版本实际数月份 f4
           ON f4.版本 = f2.版本
        WHERE f4.指标库明细说明 = '版本实际数月份'
              AND f2.轮循归档科目 = '归档源版本'
  ) t;

--缓存F08表的数据
SELECT 
    F08.* ,bb.rowno
INTO  #f0804
FROM   data_wide_qt_F080004 f08
inner join #bb bb on f08.实体分期 = bb.实体分期 and (f08.版本 = bb.版本 or f08.版本 = bb.value_string)
WHERE    CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0 

--获取盈利规划销售收入及成本信息
select 
    yt.项目guid,
    f08.业态,
	--  盈利规划当前版本
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '结转面积' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划签约面积,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 in ('营业税下收入','增值税下含税收入') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划含税销售收入,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '销售收入（不含税）' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划不含税销售收入,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '总成本（含税，计划）' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划含税计划总成本,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '总成本（不含税，计划）' and 明细说明 = '总价'  and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划不含税计划总成本,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '总成本（不含税，账面）' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划不含税账面总成本,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '结转成本' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划营业成本,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '资本化利息' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划资本化利息,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '费用化利息' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划费用化利息,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '财务费用（计划）' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划财务费用计划口径,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '综合管理费用-协议口径' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划综合管理费协议口径,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '营销费用' and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划营销费用,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 in ('土地增值税','增值税下附加税','营业税下营业税、附加税','印花税','其他税费') 
	    and 明细说明 = '总价' and f08.rowno = 1 then convert(decimal(36, 8), value_string) else 0 end) 盈利规划税金及附加,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 in ('土地增值税') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划土增税,
    
	--盈利规划上个版本
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '结转面积' and 明细说明 = '总价' and f08.rowno = 2
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划上个版本签约面积,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '结转成本' and 明细说明 = '总价' and f08.rowno = 2
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划上个版本营业成本,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '营销费用' and 明细说明 = '总价' and f08.rowno =2
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划上个版本营销费用,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 = '综合管理费用-协议口径' and 明细说明 = '总价' and f08.rowno = 2
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划上个版本综合管理费协议口径,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 in ('土地增值税','增值税下附加税','营业税下营业税、附加税','印花税','其他税费') 
    and 明细说明 = '总价' and f08.rowno = 2 then convert(decimal(36, 8), value_string) else 0 end) 盈利规划上个版本税金及附加,
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 in ('税前利润（账面）扣减股权溢价') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划税前利润账面扣减股权溢价,	
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 in ('税前利润（计划）') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划税前利润计划,	
    sum(case when 综合维 = '合计' and 报表预测项目科目 in ('税后利润（账面）扣减股权溢价') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划税后利润账面扣减股权溢价,	
    sum(case when 综合维 = '可售产品' and 报表预测项目科目 in ('税后现金利润（账面）') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划税后现金利润账面,	
    sum(case when 综合维 = '经营产品' and 报表预测项目科目 in ('总成本（不含税，账面）') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划固定资产,	
    sum(case when 综合维 = '合计' and 报表预测项目科目 in ('税后利润（计划）') and 明细说明 = '总价' and f08.rowno = 1
        then convert(decimal(36, 8), value_string) else 0 end) 盈利规划税后利润计划	
into #F0804_tmp
FROM  #f0804 f08 
    INNER JOIN #yt yt ON f08.业态 = yt.YtName AND f08.实体分期 = yt.ProjGUID
GROUP BY  yt.项目guid,f08.业态

--获取盈利规划的结转情况   --缺少中间表

-------------------------获取盈利规划的铺排数据 
-- --缓存F08000202表的数据
SELECT F08.*
INTO #F08000202
  FROM data_wide_qt_F08000202 F08
 INNER JOIN #bb bb
     ON F08.实体分期 = bb.实体分期
        AND
        (
            F08.版本 = bb.版本
            OR F08.版本 = bb.value_string
        )
  WHERE CHARINDEX('e', ISNULL(F08.VALUE_STRING, '0')) = 0
        AND bb.rowno = 1
        AND 年 IN ( CONVERT(VARCHAR(4), YEAR(GETDATE())) + '年', CONVERT(VARCHAR(4), YEAR(GETDATE()) - 1) + '年' )
        AND 报表预测项目科目 IN ( '签约面积', '签约收入（含税）', '销售收入(不含税）' )
        AND 期间 = '全周期';

--获取盈利规划销售铺排情况
select yt.项目guid,
    f08.业态,
    yt.业态组合键_业态,
    sum(case when 年 = convert(varchar(4),year(getdate()))+'年' and 报表预测项目科目='签约收入（含税）' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划本年签约金额含税,
    sum(case when 年 = convert(varchar(4),year(getdate()))+'年' and 报表预测项目科目='签约面积' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划本年签约面积,
    -- sum(case when 年 = convert(varchar(4),year(getdate()))+'年' and 报表预测项目科目='签约收入（含税）' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划本年签约均价,
    sum(case when 年 = convert(varchar(4),year(getdate()))+'年' and 报表预测项目科目='销售收入(不含税）' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划本年签约金额不含税,
    sum(case when 年 = convert(varchar(4),year(getdate())-1)+'年' and 报表预测项目科目='签约收入（含税）' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划去年签约金额含税,
    sum(case when 年 = convert(varchar(4),year(getdate())-1)+'年' and 报表预测项目科目='签约面积' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划去年签约面积,
    -- sum(case when 年 = convert(varchar(4),year(getdate()))+'年' and 报表预测项目科目='签约收入（含税）' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划去年签约均价,
    sum(case when 年 = convert(varchar(4),year(getdate())-1)+'年' and 报表预测项目科目='销售收入(不含税）' then convert(decimal(36, 8), value_string) else 0 end) 盈利规划去年签约金额不含税
into #F0802_tmp1
from #F08000202 f08 
    inner JOIN #yt yt ON f08.业态 = yt.YtName AND f08.实体分期 = yt.ProjGUID
group by yt.项目guid,f08.业态,yt.业态组合键_业态

--通过单方反算今年及去年的利润情况
 --取手工维护的匹配关系
SELECT  项目guid,
       T.基础数据主键,
       T.盈利规划系统自动匹对主键,
       CASE
           WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN T.盈利规划系统自动匹对主键 ELSE
                                                                         CASE WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                                                                                  T.盈利规划主键 ELSE T.基础数据主键 END END 盈利规划主键,
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
FROM [172.16.4.141].dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 T
     INNER JOIN
     ( SELECT ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM, FillHistoryGUID
         FROM [172.16.4.141].dss.dbo.nmap_F_FillHistory a
         WHERE EXISTS
         ( select FillHistoryGUID,sum(case when 项目guid is null or  项目guid='' then 0 else 1 end )as num from [172.16.4.141].dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 b				 		       
		    where a.FillHistoryGUID = b.FillHistoryGUID
		    group by FillHistoryGUID
		    having sum(case when 项目guid is null then 0 else 1 end )>0
         )
     ) V ON T.FillHistoryGUID = V.FillHistoryGUID AND V.NUM = 1
	where isnull(T.项目guid,'')<> ''
	group by 项目guid, T.基础数据主键, T.盈利规划系统自动匹对主键,CASE WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN T.盈利规划系统自动匹对主键 ELSE CASE WHEN ISNULL(T.盈利规划主键, '') <> '' THEN  T.盈利规划主键 ELSE T.基础数据主键 END END

--有DSS填报的优先取DSS填报
SELECT DISTINCT k.[项目guid], -- 避免重复
    isnull(k.盈利规划主键,ylgh.匹配主键) 业态组合键,
    isnull(ylgh.总可售面积,0) AS 盈利规划总可售面积,
    case when isnull(k.营业成本单方,0) = 0 then isnull(ylgh.盈利规划营业成本单方,0) else isnull(k.营业成本单方,0) end as 盈利规划营业成本单方,
    case when isnull(k.土地款单方,0) = 0 then isnull(ylgh.土地款_单方,0) else k.土地款单方 end  土地款_单方,
    case when isnull(k.除地价外直投单方,0) = 0 then isnull(ylgh.除地外直投_单方,0)  else k.除地价外直投单方 end as 除地外直投_单方,
    case when isnull(k.开发间接费单方,0) = 0 then isnull(ylgh.开发间接费单方,0) else k.开发间接费单方 end as 开发间接费单方,
    case when isnull(k.资本化利息单方,0) = 0 then isnull(ylgh.资本化利息单方,0) else k.资本化利息单方 end  as 资本化利息单方,
    case when isnull(k.股权溢价单方,0) = 0 then isnull(ylgh.股权溢价单方,0) else k.股权溢价单方 end as 盈利规划股权溢价单方,
    case when isnull(k.营销费用单方,0) = 0 then isnull(ylgh.营销费用单方,0) else k.营销费用单方 end as 盈利规划营销费用单方,
    case when isnull(k.综合管理费单方,0) = 0 then isnull(ylgh.管理费用单方,0) else k.综合管理费单方 end as 盈利规划综合管理费单方协议口径,
    case when isnull(k.税金及附加单方,0) = 0 then isnull(ylgh.税金及附加单方,0) else k.税金及附加单方 end as  盈利规划税金及附加单方
INTO #ylgh
FROM #key k 
     LEFT JOIN [172.16.4.141].dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh  ON ylgh.匹配主键 = k.盈利规划主键 AND ylgh.[项目guid] = k.项目guid    

--计算成本情况
select f0802.项目guid,
    f0802.业态,
    sum(f0802.盈利规划本年签约金额含税) as 盈利规划本年签约金额含税,
    sum(f0802.盈利规划本年签约面积) as 盈利规划本年签约面积, 
    sum(f0802.盈利规划本年签约金额不含税) as 盈利规划本年签约金额不含税,
    sum(f0802.盈利规划去年签约金额含税) as 盈利规划去年签约金额含税,
    sum(f0802.盈利规划去年签约面积) as 盈利规划去年签约面积,
    sum(f0802.盈利规划去年签约金额不含税) as 盈利规划去年签约金额不含税,
    --成本
    SUM(isnull(y.盈利规划营业成本单方,0) * ISNULL(f0802.盈利规划本年签约面积, 0)) 盈利规划营业成本本年签约,
    SUM(isnull(y.盈利规划股权溢价单方,0) * ISNULL(f0802.盈利规划本年签约面积, 0)) 盈利规划股权溢价本年签约,
    SUM(isnull(y.盈利规划营销费用单方,0) * ISNULL(f0802.盈利规划本年签约面积, 0)) 盈利规划营销费用本年签约,
    SUM(isnull(y.盈利规划综合管理费单方协议口径,0) * ISNULL(f0802.盈利规划本年签约面积, 0)) 盈利规划综合管理费本年签约,
    SUM(isnull(y.盈利规划税金及附加单方,0) * ISNULL(f0802.盈利规划本年签约面积, 0)) 盈利规划税金及附加本年签约,

    SUM(isnull(y.盈利规划营业成本单方,0) * ISNULL(f0802.盈利规划去年签约面积, 0)) 盈利规划营业成本去年签约,
    SUM(isnull(y.盈利规划股权溢价单方,0) * ISNULL(f0802.盈利规划去年签约面积, 0)) 盈利规划股权溢价去年签约,
    SUM(isnull(y.盈利规划营销费用单方,0) * ISNULL(f0802.盈利规划去年签约面积, 0)) 盈利规划营销费用去年签约,
    SUM(isnull(y.盈利规划综合管理费单方协议口径,0) * ISNULL(f0802.盈利规划去年签约面积, 0)) 盈利规划综合管理费去年签约,
    SUM(isnull(y.盈利规划税金及附加单方,0) * ISNULL(f0802.盈利规划去年签约面积, 0)) 盈利规划税金及附加去年签约
into #cost
from #F0802_tmp1 f0802
LEFT JOIN #ylgh y ON f0802.项目guid = y.[项目guid] AND f0802.业态组合键_业态 = y.业态组合键
group by f0802.项目guid,f0802.业态

--计算项目层级的税前利润
SELECT c.项目guid,
    SUM(CONVERT(DECIMAL(36, 8),
        ((isnull(c.盈利规划本年签约金额不含税,0) - isnull(c.盈利规划营业成本本年签约,0)) - 
        isnull(c.盈利规划营销费用本年签约,0) - isnull(c.盈利规划综合管理费本年签约,0) - isnull(c.盈利规划税金及附加本年签约,0)
        ))) 项目税前利润本年签约,
    SUM(CONVERT(DECIMAL(36, 8),
        ((isnull(c.盈利规划去年签约金额不含税,0) - isnull(c.盈利规划营业成本去年签约,0)) - 
        isnull(c.盈利规划营销费用去年签约,0) - isnull(c.盈利规划综合管理费去年签约,0) - isnull(c.盈利规划税金及附加去年签约,0)
        ))) 项目税前利润去年签约
INTO #xm
FROM #cost c
GROUP BY c.项目guid;

--计算利润情况
select f0802.项目guid,
    f0802.业态,
    sum(f0802.盈利规划本年签约金额含税) as 盈利规划本年签约金额含税,
    sum(f0802.盈利规划本年签约面积) as 盈利规划本年签约面积,
    sum(f0802.盈利规划本年签约金额不含税) as 盈利规划本年签约金额不含税,
    sum(f0802.盈利规划去年签约金额含税) as 盈利规划去年签约金额含税,
    sum(f0802.盈利规划去年签约面积) as 盈利规划去年签约面积,
    sum(f0802.盈利规划去年签约金额不含税) as 盈利规划去年签约金额不含税,
    sum(CONVERT(DECIMAL(36, 8),(isnull(f0802.盈利规划本年签约金额不含税,0)-isnull(f0802.盈利规划营业成本本年签约,0)-isnull(f0802.盈利规划股权溢价本年签约,0)))) 盈利规划本年销售毛利润, 
    sum(CONVERT(DECIMAL(36, 8),((isnull(f0802.盈利规划本年签约金额不含税,0)-isnull(f0802.盈利规划营业成本本年签约,0)-isnull(f0802.盈利规划股权溢价本年签约,0) ) -
        isnull(f0802.盈利规划营销费用本年签约,0) - isnull(f0802.盈利规划综合管理费本年签约,0) -  isnull(f0802.盈利规划税金及附加本年签约,0)))
        - CASE WHEN x.项目税前利润本年签约 > 0 THEN
        CONVERT(DECIMAL(36, 8),((isnull(f0802.盈利规划本年签约金额不含税,0)-isnull(f0802.盈利规划营业成本本年签约,0))-isnull(f0802.盈利规划营销费用本年签约,0) -  
        isnull(f0802.盈利规划综合管理费本年签约,0)-isnull(f0802.盈利规划税金及附加本年签约,0))*0.25) ELSE 0.0 END) 盈利规划本年销售净利润, 
    sum(CONVERT(DECIMAL(36, 8),(isnull(f0802.盈利规划去年签约金额不含税,0)-isnull(f0802.盈利规划营业成本去年签约,0)-isnull(f0802.盈利规划股权溢价去年签约,0)))) 盈利规划去年销售毛利润, 
    sum(CONVERT(DECIMAL(36, 8),((isnull(f0802.盈利规划去年签约金额不含税,0)-isnull(f0802.盈利规划营业成本去年签约,0)-isnull(f0802.盈利规划股权溢价去年签约,0) ) -
        isnull(f0802.盈利规划营销费用去年签约,0) - isnull(f0802.盈利规划综合管理费去年签约,0) -  isnull(f0802.盈利规划税金及附加去年签约,0)))
        - CASE WHEN x.项目税前利润去年签约 > 0 THEN
        CONVERT(DECIMAL(36, 8),((isnull(f0802.盈利规划去年签约金额不含税,0)-isnull(f0802.盈利规划营业成本去年签约,0))-isnull(f0802.盈利规划营销费用去年签约,0) -  
        isnull(f0802.盈利规划综合管理费去年签约,0)-isnull(f0802.盈利规划税金及附加去年签约,0))*0.25) ELSE 0.0 END) 盈利规划去年销售净利润 
into #F0802_tmp 
from #cost f0802
LEFT JOIN #xm x ON x.项目guid = f0802.项目guid
group by f0802.项目guid, f0802.业态

----------------汇总业态组合键情况
select 
    org.组织架构ID,
	org.组织架构名称,
	org.组织架构类型,
	org.组织架构编码,
	sum(f0804.盈利规划签约面积) as 盈利规划签约面积,
	sum(f0804.盈利规划含税销售收入)/10000.0 as 盈利规划含税销售收入,
	sum(f0804.盈利规划不含税销售收入)/10000.0 as 盈利规划不含税销售收入,
	case when sum(f0804.盈利规划签约面积) = 0 then 0 else sum(f0804.盈利规划含税销售收入)/sum(f0804.盈利规划签约面积) end as 盈利规划销售均价,
	sum(f0804.盈利规划含税计划总成本)/10000.0 as 盈利规划含税计划总成本,
	sum(f0804.盈利规划不含税计划总成本)/10000.0 as 盈利规划不含税计划总成本, 
	sum(f0804.盈利规划含税计划总成本-f0804.盈利规划费用化利息+f0804.盈利规划资本化利息)/10000.0 as 盈利规划含税账面总成本,
	sum(f0804.盈利规划不含税账面总成本)/10000.0 as 盈利规划不含税账面总成本,
	sum(f0804.盈利规划营业成本)/10000.0 as 盈利规划营业成本,
	sum(f0804.盈利规划资本化利息)/10000.0 as 盈利规划资本化利息,
	sum(f0804.盈利规划费用化利息)/10000.0 as 盈利规划费用化利息,
	sum(f0804.盈利规划财务费用计划口径)/10000.0 as 盈利规划财务费用计划口径,
	sum(f0804.盈利规划营销费用)/10000.0 as 盈利规划营销费用,
	sum(f0804.盈利规划综合管理费协议口径)/10000.0 as 盈利规划综合管理费协议口径,
	sum(f0804.盈利规划税金及附加)/10000.0 as 盈利规划税金及附加,
	sum(f0804.盈利规划土增税)/10000.0 as 盈利规划土增税,
	sum(f0804.盈利规划上个版本签约面积) as 盈利规划上个版本签约面积,
	sum(f0804.盈利规划上个版本营业成本)/10000.0 as 盈利规划上个版本营业成本,
	sum(f0804.盈利规划上个版本营销费用)/10000.0 as 盈利规划上个版本营销费用,
	sum(f0804.盈利规划上个版本综合管理费协议口径)/10000.0 as 盈利规划上个版本综合管理费协议口径,
	sum(f0804.盈利规划上个版本税金及附加)/10000.0 as 盈利规划上个版本税金及附加,
	case when sum(f0804.盈利规划签约面积) = 0 then 0 else sum(f0804.盈利规划营业成本)/sum(f0804.盈利规划签约面积) end 盈利规划营业成本单方,
	case when sum(f0804.盈利规划签约面积) = 0 then 0 else sum(f0804.盈利规划营销费用)/sum(f0804.盈利规划签约面积) end 盈利规划营销费用单方,
	case when sum(f0804.盈利规划签约面积) = 0 then 0 else sum(f0804.盈利规划综合管理费协议口径)/sum(f0804.盈利规划签约面积) end 盈利规划综合管理费用单方,
	case when sum(f0804.盈利规划签约面积) = 0 then 0 else sum(f0804.盈利规划税金及附加)/sum(f0804.盈利规划签约面积) end 盈利规划税金及附加单方,
	case when sum(f0804.盈利规划上个版本签约面积) = 0 then 0 else sum(f0804.盈利规划上个版本营业成本)/sum(f0804.盈利规划上个版本签约面积) end 上版本盈利规划营业成本单方,
	case when sum(f0804.盈利规划上个版本签约面积) = 0 then 0 else sum(f0804.盈利规划上个版本营销费用)/sum(f0804.盈利规划上个版本签约面积) end 上版本盈利规划营销费用单方,
	case when sum(f0804.盈利规划上个版本签约面积) = 0 then 0 else sum(f0804.盈利规划上个版本综合管理费协议口径)/sum(f0804.盈利规划上个版本签约面积) end 上版本盈利规划综合管理费用单方,
	case when sum(f0804.盈利规划上个版本签约面积) = 0 then 0 else sum(f0804.盈利规划上个版本税金及附加)/sum(f0804.盈利规划上个版本签约面积) end 上版本盈利规划税金及附加单方,
	sum(f0804.盈利规划税前利润账面扣减股权溢价)/10000.0 as 盈利规划税前利润账面扣减股权溢价,
	sum(f0804.盈利规划税前利润计划)/10000.0 as 盈利规划税前利润计划,
	sum(f0804.盈利规划税后利润账面扣减股权溢价)/10000.0 as 盈利规划税后利润账面扣减股权溢价,
	sum(f0804.盈利规划税后现金利润账面)/10000.0 as 盈利规划税后现金利润账面,
	sum(f0804.盈利规划固定资产)/10000.0 as 盈利规划固定资产,
	sum(f0804.盈利规划税后利润计划)/10000.0 as 盈利规划税后利润计划,
	case when sum(f0804.盈利规划含税计划总成本-f0804.盈利规划费用化利息+f0804.盈利规划资本化利息) = 0 then 0 else sum(f0804.盈利规划税前利润账面扣减股权溢价)/sum(f0804.盈利规划含税计划总成本-f0804.盈利规划费用化利息+f0804.盈利规划资本化利息) end 盈利规划税前成本利润率账面, --税前利润账面/总成本含税账面
	case when sum(f0804.盈利规划含税计划总成本) = 0 then 0 else sum(f0804.盈利规划税前利润计划)/sum(f0804.盈利规划含税计划总成本) end 盈利规划税前成本利润率计划, --税前利润计划/总成本含税计划
	case when sum(f0804.盈利规划不含税销售收入) = 0 then 0 else sum(f0804.盈利规划税前利润账面扣减股权溢价)/sum(f0804.盈利规划不含税销售收入) end 盈利规划税前销售利润率账面, --税前利润账面/销售收入不含税
	sum(f0802.盈利规划本年签约金额含税)/10000.0 as 盈利规划本年签约金额含税,
	sum(f0802.盈利规划本年签约面积) as 盈利规划本年签约面积,
	case when sum(f0802.盈利规划本年签约面积) =0 then 0 else  sum(f0802.盈利规划本年签约金额含税)/sum(f0802.盈利规划本年签约面积) end as 盈利规划本年签约均价,
	sum(f0802.盈利规划本年签约金额不含税)/10000.0 as 盈利规划本年签约金额不含税,
	sum(f0802.盈利规划去年签约金额含税)/10000.0 as 盈利规划去年签约金额含税,
	sum(f0802.盈利规划去年签约面积) as 盈利规划去年签约面积,
	case when sum(f0802.盈利规划去年签约面积) =0 then 0 else  sum(f0802.盈利规划去年签约金额含税)/sum(f0802.盈利规划去年签约面积) end  as 盈利规划去年签约均价,
	sum(f0802.盈利规划去年签约金额不含税)/10000.0 as 盈利规划去年签约金额不含税,

	sum(f0802.盈利规划本年销售毛利润)/10000.0 as 盈利规划本年销售毛利润,
	case when sum(f0802.盈利规划本年签约金额不含税) =0 then 0 else sum(f0802.盈利规划本年销售毛利润)/sum(f0802.盈利规划本年签约金额不含税) end 盈利规划本年销售毛利率,
	sum(f0802.盈利规划本年销售净利润)/10000.0 as 盈利规划本年销售净利润,
	case when sum(f0802.盈利规划本年签约金额不含税) =0 then 0 else sum(f0802.盈利规划本年销售净利润)/sum(f0802.盈利规划本年签约金额不含税) end 盈利规划本年销售净利率,
	sum(f0802.盈利规划去年销售毛利润)/10000.0 as 盈利规划去年销售毛利润,
	case when sum(f0802.盈利规划去年签约金额不含税) =0 then 0 else sum(f0802.盈利规划去年销售毛利润)/sum(f0802.盈利规划去年签约金额不含税) end 盈利规划去年销售毛利率,
	sum(f0802.盈利规划去年销售净利润)/10000.0 as 盈利规划去年销售净利润,
	case when sum(f0802.盈利规划去年签约金额不含税) =0 then 0 else sum(f0802.盈利规划去年销售毛利润)/sum(f0802.盈利规划去年签约金额不含税) end 盈利规划去年销售净利率
into #tmp_result 
from Data_Wide_Dws_s_WqBaseStatic_Organization org 
left join #F0804_tmp f0804 on f0804.项目guid = org.项目guid and f0804.业态 = org.组织架构名称
left join #F0802_tmp f0802 on f0802.项目guid = org.项目guid and f0802.业态 = org.组织架构名称
where org.组织架构类型 = 5
group by org.组织架构ID,
org.组织架构名称,
org.组织架构类型,
org.组织架构编码

--循环更新:通过产品组合层级数据，循环更新业态、项目、区域、公司的数据 
DECLARE @baseinfo int;
set @baseinfo = 5

while (@baseinfo >1)
BEGIN
		insert into #tmp_result 
		select bi2.组织架构ID,
		bi2.组织架构名称,
		bi2.组织架构类型,
		bi2.组织架构编码,
		sum(t.盈利规划签约面积) as 盈利规划签约面积,
		sum(t.盈利规划含税销售收入) as 盈利规划含税销售收入,
		sum(t.盈利规划不含税销售收入) as 盈利规划不含税销售收入,
		case when sum(t.盈利规划签约面积) = 0 then 0 else sum(t.盈利规划含税销售收入)*10000.0/sum(t.盈利规划签约面积) end as 盈利规划销售均价,
		sum(t.盈利规划含税计划总成本) as 盈利规划含税计划总成本,
		sum(t.盈利规划不含税计划总成本) as 盈利规划不含税计划总成本, 
		sum(t.盈利规划含税计划总成本-t.盈利规划费用化利息+t.盈利规划资本化利息) as 盈利规划含税账面总成本,
		sum(t.盈利规划不含税账面总成本) as 盈利规划不含税账面总成本,
		sum(t.盈利规划营业成本) as 盈利规划营业成本,
		sum(t.盈利规划资本化利息) as 盈利规划资本化利息,
		sum(t.盈利规划费用化利息) as 盈利规划费用化利息,
		sum(t.盈利规划财务费用计划口径) as 盈利规划财务费用计划口径,
		sum(t.盈利规划营销费用) as 盈利规划营销费用,
		sum(t.盈利规划综合管理费协议口径) as 盈利规划综合管理费协议口径,
		sum(t.盈利规划税金及附加) as 盈利规划税金及附加,
		sum(t.盈利规划土增税) as 盈利规划土增税,
		sum(t.盈利规划上个版本签约面积) as 盈利规划上个版本签约面积,
		sum(t.盈利规划上个版本营业成本) as 盈利规划上个版本营业成本,
		sum(t.盈利规划上个版本营销费用) as 盈利规划上个版本营销费用,
		sum(t.盈利规划上个版本综合管理费协议口径) as 盈利规划上个版本综合管理费协议口径,
		sum(t.盈利规划上个版本税金及附加) as 盈利规划上个版本税金及附加,
		case when sum(t.盈利规划签约面积) = 0 then 0 else sum(t.盈利规划营业成本)*10000.0/sum(t.盈利规划签约面积) end 盈利规划营业成本单方,
		case when sum(t.盈利规划签约面积) = 0 then 0 else sum(t.盈利规划营销费用)*10000.0/sum(t.盈利规划签约面积) end 盈利规划营销费用单方,
		case when sum(t.盈利规划签约面积) = 0 then 0 else sum(t.盈利规划综合管理费协议口径)*10000.0/sum(t.盈利规划签约面积) end 盈利规划综合管理费用单方,
		case when sum(t.盈利规划签约面积) = 0 then 0 else sum(t.盈利规划税金及附加)*10000.0/sum(t.盈利规划签约面积) end 盈利规划税金及附加单方,
		case when sum(t.盈利规划上个版本签约面积) = 0 then 0 else sum(t.盈利规划上个版本营业成本)*10000.0/sum(t.盈利规划上个版本签约面积) end 上版本盈利规划营业成本单方,
		case when sum(t.盈利规划上个版本签约面积) = 0 then 0 else sum(t.盈利规划上个版本营销费用)*10000.0/sum(t.盈利规划上个版本签约面积) end 上版本盈利规划营销费用单方,
		case when sum(t.盈利规划上个版本签约面积) = 0 then 0 else sum(t.盈利规划上个版本综合管理费协议口径)*10000.0/sum(t.盈利规划上个版本签约面积) end 上版本盈利规划综合管理费用单方,
		case when sum(t.盈利规划上个版本签约面积) = 0 then 0 else sum(t.盈利规划上个版本税金及附加)*10000.0/sum(t.盈利规划上个版本签约面积) end 上版本盈利规划税金及附加单方,
		sum(t.盈利规划税前利润账面扣减股权溢价) as 盈利规划税前利润账面扣减股权溢价,
		sum(t.盈利规划税前利润计划) as 盈利规划税前利润计划,
		sum(t.盈利规划税后利润账面扣减股权溢价) as 盈利规划税后利润账面扣减股权溢价,
		sum(t.盈利规划税后现金利润账面) as 盈利规划税后现金利润账面,
		sum(t.盈利规划固定资产) as 盈利规划固定资产,
		sum(t.盈利规划税后利润计划) as 盈利规划税后利润计划,
		case when sum(t.盈利规划含税计划总成本-t.盈利规划费用化利息+t.盈利规划资本化利息) = 0 then 0 else sum(t.盈利规划税前利润账面扣减股权溢价)/sum(t.盈利规划含税计划总成本-t.盈利规划费用化利息+t.盈利规划资本化利息) end 盈利规划税前成本利润率账面, --税前利润账面/总成本含税账面
		case when sum(t.盈利规划含税计划总成本) = 0 then 0 else sum(t.盈利规划税前利润计划)/sum(t.盈利规划含税计划总成本) end 盈利规划税前成本利润率计划, --税前利润计划/总成本含税计划
		case when sum(t.盈利规划不含税销售收入) = 0 then 0 else sum(t.盈利规划税前利润账面扣减股权溢价)/sum(t.盈利规划不含税销售收入) end 盈利规划税前销售利润率账面, --税前利润账面/销售收入不含税
		sum(t.盈利规划本年签约金额含税) as 盈利规划本年签约金额含税,
		sum(t.盈利规划本年签约面积) as 盈利规划本年签约面积,
		case when sum(t.盈利规划本年签约面积) =0 then 0 else  sum(t.盈利规划本年签约金额含税)*10000.0/sum(t.盈利规划本年签约面积) end as 盈利规划本年签约均价,
		sum(t.盈利规划本年签约金额不含税) as 盈利规划本年签约金额不含税,
		sum(t.盈利规划去年签约金额含税) as 盈利规划去年签约金额含税,
		sum(t.盈利规划去年签约面积) as 盈利规划去年签约面积,
		case when sum(t.盈利规划去年签约面积) =0 then 0 else  sum(t.盈利规划去年签约金额含税)*10000.0/sum(t.盈利规划去年签约面积) end  as 盈利规划去年签约均价,
		sum(t.盈利规划去年签约金额不含税) as 盈利规划去年签约金额不含税,

		sum(t.盈利规划本年销售毛利润)/10000.0 as 盈利规划本年销售毛利润,
		case when sum(t.盈利规划本年签约金额不含税) =0 then 0 else sum(t.盈利规划本年销售毛利润)/sum(t.盈利规划本年签约金额不含税) end 盈利规划本年销售毛利率,
		sum(t.盈利规划本年销售净利润)/10000.0 as 盈利规划本年销售净利润,
		case when sum(t.盈利规划本年签约金额不含税) =0 then 0 else sum(t.盈利规划本年销售净利润)/sum(t.盈利规划本年签约金额不含税) end 盈利规划本年销售净利率,
		sum(t.盈利规划去年销售毛利润)/10000.0 as 盈利规划去年销售毛利润,
		case when sum(t.盈利规划去年签约金额不含税) =0 then 0 else sum(t.盈利规划去年销售毛利润)/sum(t.盈利规划去年签约金额不含税) end 盈利规划去年销售毛利率,
		sum(t.盈利规划去年销售净利润)/10000.0 as 盈利规划去年销售净利润,
		case when sum(t.盈利规划去年签约金额不含税) =0 then 0 else sum(t.盈利规划去年销售毛利润)/sum(t.盈利规划去年签约金额不含税) end 盈利规划去年销售净利率

		from #tmp_result t
		inner join highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization bi on t.组织架构id = bi.组织架构id
		inner join highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization bi2 on bi2.组织架构id  = bi.组织架构父级id
		where t.组织架构类型 =@baseinfo
		group by  bi2.组织架构ID
		,bi2.组织架构名称
		,bi2.组织架构类型
		,bi2.组织架构编码

		SET  @baseinfo = @baseinfo - 1
END

--查询结果  
SELECT * FROM #tmp_result;

--删除临时表
DROP TABLE #tmp_result,
    #bb,
    #F08000202,
    #F0802_tmp,
    #f0804,
    #F0804_tmp,
    #yt,
    #F0802_tmp1;
