-- 取100个项目的明源成本系统动态成本拍照、二次分摊、盈利规划最新落盘三个版本的除地价外直投、除地价外直投单方
 
--项目清单
select projguid,projname,tgprojcode,spreadname
into #p
from [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project 
where level = 2 and (spreadname in (
'合肥龙川瑧悦',
'芜湖保利和光瑞府',
'合肥海上瑧悦',
'合肥琅悦',
'北京嘉华天珺',
'北京璟山和煦',
'北京颐璟和煦',
'北京保利锦上二期',
'大连保利东港天珺',
'福州保利天瓒',
'福州保利屏西天悦',
'莆田绶溪保利瑧悦',
'莆田保利建发棠颂和府',
'兰州保利天汇',
'兰州保利公园698',
'广州保利华创．都荟天珺',
'广州保利珠江天悦；广州保利珠江印象',
'广州保利天瑞',
'广州保利燕语堂悦',
'广州保利招商华发中央公馆',
'广州中海保利朗阅',
'广州保利棠馨花园',
'广州保利翔龙天汇',
'广州保利湖光悦色',
'三亚保利．栖山雨茗;保利．伴山瑧悦',
'三亚保利．海晏',
'厦门沁原二期',
'泉州清源瑧悦',
'厦门天琴',
'维景天珺',
'华晨天奕',
'石家庄保利维明天珺',
'石家庄保利天汇',
'郑州保利大都汇',
'郑州保利海德公园',
'武汉保利涧山观奕',
'武汉阅江台A包',
'长沙保利天瑞',
'长沙保利梅溪天珺',
'长沙保利北中心保利时代',
'和光晨樾',
'佛山保利天瓒',
'佛山保利湖光里',
'佛山保利阅江台.江缦',
'佛山保利湖映琅悦',
'佛山保利德胜天汇',
'佛山保利琅悦',
'佛山保利珺悦府',
'佛山保利灯湖天珺',
'佛山保利秀台天珺',
'佛山保利天汇',
'徐州保利学府',
'徐州水沐玖悦府',
'徐州保利建发天瑞',
'江韵瑧悦',
'南京.保利荷雨瑧悦',
'南京 璟上',
'南昌保利天汇三期',
'南昌保利天珺',
'大连保利时代金地城',
'沈阳保利和光屿湖',
'沈阳保利天汇（公园壹号）',
'济南市保利琅悦',
'青岛保利青铁和著理想地',
'青岛市城阳区虹桥路项目',
'太原保利龙城天珺',
'太原保利龙城璞悦',
'太原保利和光尘樾',
'太原保利和悦华锦',
'长兴璞悦',
'西安保利天珺二期',
'西安保利云谷和著',
'西安保利咏山和颂',
'西安市保利未央璞悦',
'上海保利外滩序45Bund',
'上海保利海上瑧悦',
'上海保利光合上城',
'上海保利世博天悦',
'成都保利花照天珺',
'成都保利.新川天珺',
'成都保利.天府瑧悦',
'成都保利.天府和颂二期',
'成都保利怡心和颂',
'成都中粮保利天府时区',
'苏州保利天汇',
'苏州昆山和光璀璨',
'苏州昆山保利拾锦东方',
'苏州园区天朗汇庭',
'苏州保利瑧悦',
'天津保利西棠和煦二期',
'天津保利·和光尘樾',
'东莞南城保利天珺',
'汕尾保利时代',
'江门保利琅悦',
'珠海九洲保利天和',
'江门保利大都汇',
'江门保利西海岸',
'中山保利天珺',
'昆明市保利天珺项目',
'西双版纳保利雨林澜山',
'长春保利和煦项目',
'长春保利·朗阅三期',
'宁波保利东方瑧悦府',
'宁波保利明州瑧悦府',
'宁波保利海晏天珺',
'温州保利招商天樾玺二期',
'台州保利凤起云城',
'重庆中粮保利天玺壹号（134）',
'重庆保利拾光年',
'贵阳保利大国璟') or (TgProjCode in ('1417','3925','3924','725', '1856','4922','8711')))
 
--取动态成本拍照的版本
select t.projguid,max(CurVersion)  CurVersion
into #cbbb
from [172.16.4.161].highdata_prod.dbo.data_wide_cb_MonthlyReview T
inner join [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj on t.projguid = pj.projguid 
inner join #p p on p.projguid = pj.parentguid
where CreateUserName <> '系统管理员'
group by t.projguid

select t.projguid,CurVersion,版本,sum(除地价外直投不含税_非现金) as 除地价外直投不含税_非现金,sum(除地价外直投含税_非现金) as 除地价外直投含税_非现金, 
sum(除地价外直投不含税) as 除地价外直投不含税,sum(除地价外直投含税) as 除地价外直投含税
into #cb
from (
select t.projguid, t.CurVersion,'回顾版：'+t.CurVersion as 版本,
sum(case when t.AccountCode = '5001' then isnull(CurDynamicCostNonTax_fxj
,0) else 0 end)-
sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCostNonTax_fxj
,0) else 0 end)  as 除地价外直投不含税_非现金,
sum(case when t.AccountCode = '5001' then isnull(CurDynamicCost_fxj
,0) else 0 end)-
sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCost_fxj
,0) else 0 end)  as 除地价外直投含税_非现金, 
sum(case when t.AccountCode = '5001' then isnull(CurDynamicCostNonTax
,0) else 0 end)-
sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCostNonTax
,0) else 0 end)  as 除地价外直投不含税,
sum(case when t.AccountCode = '5001' then isnull(CurDynamicCost
,0) else 0 end)-
sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCost
,0) else 0 end)  as 除地价外直投含税
from [172.16.4.161].highdata_prod.dbo.data_wide_cb_MonthlyReview t 
inner join #cbbb bb on t.CurVersion = bb.CurVersion and t.projguid = bb.projguid 
where t.AccountCode in ('5001','5001.10','5001.09','5001.11','5001.01') 
group by t.projguid,t.CurVersion)t 
group by t.projguid,CurVersion,版本

--获取所有二次成本分摊数据
--获取标准科目设置的分摊规则
select
    ItemShortName,
    ItemCode,
    ParentCode,
    IsEndCost,
    CostLevel,
    FtTypeName as SjFtModel,
    case
        when FtTypeName like '%自持%'
        and FtTypeName like '%可售%' then '自持+可售'
        when FtTypeName like '%自持%' then '自持面积'
        when FtTypeName like '%建筑%' then '建筑面积'
        when FtTypeName like '%计容%' then '计容面积'
        when FtTypeName like '%可售%' then '可售面积'
    end as 分摊规则,
    IsCwFt 
    into #standCost
from MyCost_Erp352.dbo.p_BzItem
WHERE ItemType = '控制科目'
    and ItemShortName not in ('中间科目', '除地价外直投')
    and IsEndCost = 1

/*缓存二次成本情况，并通过汇总+明细两种不同分摊模式分别算出对应的业态占比:
 一、分摊模式
 1、汇总模式下，若组合键跟基础数据组合键能完全对上，则直接取各业态组合键的二次成本算出对应的占比
 2、汇总模式下，若组合键跟基础数据组合键存在对不上的情况，则需要按照分摊规则进行分摊
 3、明细模式下，需要按照分摊规则进行分摊
 
 二、分摊规则
 1、若分摊规则为标准分摊(分摊规则为系统设定的"自持+可售"、"建筑面积"、"计容面积"、"自持面积"、"可售面积")，则按照对应的面积进行分摊
 2、若分摊规则不为标准分摊，则按照标准科目设置的分摊规则进行分摊
 */
--获取所有二次成本分摊数据
 

select pkcbr.projguid, 
    sum(dtl.buildcost) as 除地价外直投 
into #Ecft
from [172.16.4.132].TaskCenterData.dbo.[cb_ProductKsCbRecollect] pkcbr
    inner join [172.16.4.132].TaskCenterData.dbo.[cb_ProductKsCbDtlRecollect] dtl on dtl.ProductKsCbRecollectGUID = pkcbr.ProductKsCbRecollectGUID
    INNER JOIN(
        SELECT
            a.ProductCostRecollectGUID,
            a.ProjGUID,
            a.UpVersion,
            a.CurVersion,
            a.ImportVersionName,
            a.RecollectTime,
            ROW_NUMBER() OVER (
                PARTITION BY a.ProjGUID
                ORDER BY
                    a.RecollectTime DESC
            ) AS num
        FROM [172.16.4.132].TaskCenterData.dbo.cb_ProductCostRecollect a
        WHERE a.ApproveState = '已审核'
    ) pcr ON pcr.ProductCostRecollectGUID = pkcbr.ProductCostRecollectGUID AND pcr.num = 1
    left join #standCost sta on sta.ItemCode = pkcbr.costcode 
    inner join [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj on pkcbr.projguid = pj.projguid 
    inner join #p p on p.projguid = pj.parentguid
where  IsCost = 1 and costcode not like '5001.09%' and costcode not like '5001.10%' and costcode not like '5001.01%'
and costcode not like '5001.11%'
    and isendcost = 1
    and buildcost <> 0 
	group by pkcbr.projguid
  

--盈利规划    
select  t.YLGHProjGUID as projguid, sum(除地价外直投不含税) as 盈利规划除地价外直接投资,
sum(除地价外直投含税) as 盈利规划除地价外直接投资含税
into #ylgh
from ( 
select  pj.YLGHProjGUID,
sum(case when 报表预测项目科目 = '除地价外直投（含税）' then convert(decimal(16,2),value_string) else 0 end) as 除地价外直投含税,
sum(case when 报表预测项目科目 = '除地价外直投（不含税）' then convert(decimal(16,2),value_string) else 0 end) as 除地价外直投不含税
from [172.16.4.161].highdata_prod.dbo.data_wide_qt_F080005 f08
inner join  [172.16.4.161].highdata_prod.dbo.data_wide_dws_ys_ProjGUID pj on f08.实体分期 = pj.YLGHProjGUID and pj.isbase = 1 and pj.BusinessEdition = f08.版本 
and pj.Level = 3
inner join #p p on p.projguid = pj.projguid
where 报表预测项目科目 in ('除地价外直投（不含税）' ,'除地价外直投（含税）')
and CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0 
group by pj.YLGHProjGUID ) t  
group by  t.YLGHProjGUID

----判断是否存在全分期的情况
--select * from #ylgh where len(projguid) > 36 
--select * from [172.16.4.161].highdata_prod.dbo.test where len(projguid) > 36 

--drop table #res
--合并所有指标 
select 
bu.BUName,p.tgprojcode as 投管代码, p.spreadname as 推广名称,p.ProjGUID as 项目guid, pj.projguid, cbp.ProjName as 分期名,
cb.CurVersion,
cb.版本,
cb.除地价外直投不含税_非现金 as 动态成本除地价外直投不含税_非现金,
cb.除地价外直投含税_非现金 as 动态成本除地价外直投含税_非现金,
cb.除地价外直投不含税 as 动态成本除地价外直投不含税,
cb.除地价外直投含税 as 动态成本除地价外直投含税,
ecft.除地价外直投 as 二次成本分摊除地价外直投,
ylgh.盈利规划除地价外直接投资含税 as 盈利规划除地价外直投含税,
ylgh.盈利规划除地价外直接投资 as 盈利规划除地价外直投不含税
into #res
from [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj 
inner join myBusinessUnit bu on bu.BUGUID = pj.buguid
inner join p_Project cbp on pj.projguid = cbp.ProjGUID
inner join #p p on p.projguid = pj.parentguid 
left join  #ylgh ylgh on ylgh.projguid = pj.projguid and len(ylgh.projguid) = 36
-- left join [172.16.4.161].highdata_prod.dbo.test ylgh on ylgh.projguid = pj.projguid and len(ylgh.projguid) = 36
left join #Ecft ecft on ecft.projguid = pj.projguid 
left join #cb cb on cb.projguid = pj.projguid
union all 
select bu.BUName,pj.tgprojcode as 投管代码, pj.spreadname  as 推广名称, p.ProjGUID as 项目guid,p.projguid,  pj.projname+'全分期', 
null CurVersion,
null 版本,
null as 动态成本除地价外直投不含税_非现金,
null as 动态成本除地价外直投含税_非现金,
null as 动态成本除地价外直投不含税,
null as 动态成本除地价外直投含税,
null as 二次成本分摊除地价外直投,
ylgh.盈利规划除地价外直接投资含税 as 盈利规划除地价外直投含税,
ylgh.盈利规划除地价外直接投资 as 盈利规划除地价外直投不含税 
from  [172.16.4.161].highdata_prod.dbo.test ylgh  
inner join [172.16.4.161].highdata_prod.dbo.data_wide_dws_ys_ProjGUID p on ylgh.projguid = p.ylghprojguid and p.isbase = 1 and p.level = 3
inner join [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj on pj.projguid = p.projguid
inner join myBusinessUnit bu on bu.BUGUID = pj.buguid
where len(ylgh.projguid) > 36

SELECT BUName,
       投管代码,
       推广名称,
       项目guid, 
       sum(isnull(动态成本除地价外直投不含税_非现金,0)) as 动态成本除地价外直投不含税_非现金, 
       sum(isnull(动态成本除地价外直投含税_非现金,0)) as 动态成本除地价外直投含税_非现金, 
       sum(isnull(动态成本除地价外直投不含税,0)) as 动态成本除地价外直投不含税, 
       sum(isnull(动态成本除地价外直投含税,0)) as 动态成本除地价外直投含税, 
       sum(isnull(二次成本分摊除地价外直投,0)) as 二次成本分摊除地价外直投, 
       sum(isnull(盈利规划除地价外直投含税,0)) as 盈利规划除地价外直投含税, 
       sum(isnull(盈利规划除地价外直投不含税,0)) as 盈利规划除地价外直投不含税 
FROM #res
	   group by BUName,
       投管代码,
       推广名称,
       项目guid
	   order by BUName,投管代码
