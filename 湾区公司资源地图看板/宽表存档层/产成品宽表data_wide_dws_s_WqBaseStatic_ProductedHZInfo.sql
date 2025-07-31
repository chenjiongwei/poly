  --获取近三个月的平均签约金额
  --判断项目首次签约时间
  SELECT sp.ParentProjGUID,MIN(ISNULL(sp.StatisticalDate,'2099-12-31')) AS skdate 
  INTO #sk
  FROM HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
  GROUP BY sp.ParentProjGUID
  
  --优先取近三个月签约均价，如果没有的话，就取货值单价
  select ld.salebldguid as bldguid,
  近三个月平均日流速_面积,近三月平均签约金额,近三个月平均签约面积,
  case when isnull(近三个月平均签约面积,0) = 0 then ld.hzdj else 近三月平均签约金额/近三个月平均签约面积 end 近三个月签约均价
  INTO #avg_mj
  from data_wide_dws_s_p_lddbamj ld 
  left join (SELECT sp.BldGUID,
  SUM(ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,getdate()) in (0,1) THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,getdate()) = 2 THEN 2.0
  ELSE 3.0 END)/30  近三个月平均日流速_面积,
  SUM(ISNULL(sp.SpecialCNetAmount,0)+ISNULL(sp.CNetAmount,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,getdate()) in (0,1) THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,getdate()) = 2 THEN 2.0
  ELSE 3.0 END) 近三月平均签约金额,
    SUM(ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,getdate()) in (0,1) THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,getdate()) = 2 THEN 2.0
  ELSE 3.0 END) 近三个月平均签约面积
  FROM HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
  INNER JOIN #sk sk ON sk.ParentProjGUID = sp.ParentProjGUID
    WHERE DATEDIFF(mm,sp.StatisticalDate,getdate()) BETWEEN 0 AND 3
  GROUP BY sp.BldGUID,sk.skdate) t on ld.salebldguid = t.bldguid
  where datediff(dd,ld.qxdate,getdate()) = 0;


--预处理产成品类型
/*
年初产成品:实际竣工备案时间在去年及以前
年初准产成品：（实际竣备时间为空或实际竣备时间在今年）且（预计＞计划竣备时间在今年内）+ 预计竣备时间在去年，但是实际竣备时间在今年
动态产成品：当前已竣备的剩余货值（含准产成品转化为产成品）
动态准产成品：计划竣备时间在今年且未竣备
*/
select salebldguid,
case when datediff(yy,getdate(),isnull(ld.SJjgbadate,'2099-12-31'))<0 then '年初产成品' 
when  (datediff(yy,getdate(),isnull(ld.SJjgbadate,getdate()))=0 and datediff(yy,getdate(),isnull(ld.Yjjgbadate,'2099-12-31'))=0 ) or 
( datediff(yy,getdate(),isnull(ld.Sjjgbadate,'2099-12-31'))=0 and  datediff(yy,getdate(),isnull(ld.Yjjgbadate,'2099-12-31'))=-1  )
then '年初准产成品' 
else '其他' end as 产成品类型
into #Cpptype
 from data_wide_dws_s_p_lddbamj ld
 inner join data_wide_dws_mdm_project pj on ld.projguid = pj.projguid
where datediff(dd,QXDate,getdate()) = 0 and pj.ManageModeName <> '代建' and ld.producttype <>'地下室/车库'

select 
ld.ProjGUID,
ld.SaleBldGUID,
case when t.产成品类型 = '年初产成品' then isnull(ThisYearSaleJeQY,0)+isnull(syhz,0) else 0 end as 年初产成品剩余货值金额,  --实际竣工备案时间在去年及以前的剩余货值+本年产成品销售的金额
case when t.产成品类型 = '年初产成品' then isnull(ThisYearSaleMjQY,0)+isnull(ytwsmj,0)+isnull(wtmj,0) else 0 end as 年初产成品剩余货值面积,
case when t.产成品类型 = '年初准产成品' then isnull(ThisYearSaleJeQY,0)+isnull(syhz,0) else 0 end as 年初准产成品剩余货值金额, --（实际竣备时间为空或实际竣备时间在今年）且（预计＞计划竣备时间在今年内）的年初剩余货值+ 预计竣备时间在去年，但是实际竣备时间在今年的年初剩余货值
case when t.产成品类型 = '年初准产成品' then isnull(ThisYearSaleMjQY,0)+isnull(ytwsmj,0)+isnull(wtmj,0) else 0 end as 年初准产成品剩余货值面积, 
case when t.产成品类型 = '年初产成品' then isnull(ThisYearSaleJeQY,0) else 0 end as 本年已售产成品金额, --实际竣工备案时间在去年及之前的本年销售金额
case when t.产成品类型 = '年初产成品' then isnull(ThisYearSaleMjQY,0) else 0 end as 本年已售产成品面积,
case when t.产成品类型 = '年初准产成品' then isnull(ThisYearSaleJeQY,0) else 0 end as 本年已售准产成品金额, --实际竣工备案时间在去年及之前的本年销售金额+实际竣工备案时间在今年且计划竣工时间在去年的本年销售金额
case when t.产成品类型 = '年初准产成品' then isnull(ThisYearSaleMjQY,0) else 0 end as 本年已售准产成品面积,

case when t.产成品类型 = '年初产成品'  then 
case when datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 > (isnull(ytwsmj,0)+isnull(wtmj,0))
then (isnull(ytwsmj,0)+isnull(wtmj,0)) else  datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 end
else 0 end*isnull(hzdj,0)  as 预估去化产成品金额, --预估截止到年底还有多少天，根据近三个月流速/30预估还能卖掉多少

case when t.产成品类型 = '年初产成品' then 
case when datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 > (isnull(ytwsmj,0)+isnull(wtmj,0))
then (isnull(ytwsmj,0)+isnull(wtmj,0)) else  datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 end
else 0 end as 预估去化产成品面积, 

case when --datediff(yy,getdate(),isnull(ld.SJjgbadate,getdate()))=0 and datediff(yy,getdate(),isnull(ld.Yjjgbadate,getdate()))=0  
t.产成品类型 = '年初准产成品' then 
case when datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 > (isnull(ytwsmj,0)+isnull(wtmj,0))
then (isnull(ytwsmj,0)+isnull(wtmj,0)) else  datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 end
else 0 end*isnull(hzdj,0)  as 预估去化准产成品金额, --预估截止到年底还有多少天，根据近三个月流速/30预估还能卖掉多少
case when t.产成品类型 = '年初准产成品'--datediff(yy,getdate(),isnull(ld.SJjgbadate,getdate()))=0 and datediff(yy,getdate(),isnull(ld.Yjjgbadate,getdate()))=0   
then case when datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 > (isnull(ytwsmj,0)+isnull(wtmj,0))
then (isnull(ytwsmj,0)+isnull(wtmj,0)) else  datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31') * qh.近三个月平均日流速_面积 end
else 0 end as 预估去化准产成品面积, 
case when ld.SJjgbadate is null and datediff(yy,getdate(),isnull(ld.Yjjgbadate,'2099-12-31'))=1 then isnull(syhz,0) else 0 end as 预计年底明年准产成品货值金额, -- 实际>预计>计划: 竣工备案时间在明年的剩余货值
case when ld.SJjgbadate is null and datediff(yy,getdate(),isnull(ld.Yjjgbadate,'2099-12-31'))=1 then isnull(ytwsmj,0)+isnull(wtmj,0) else 0 end as 预计年底明年准产成品货值面积,
case when SJjgbadate is not null then isnull(syhz,0) else 0 end as 动态产成品货值金额, -- 当前已竣备的剩余货值（含准产成品转化为产成品）
case when SJjgbadate is not null then isnull(ytwsmj,0)+isnull(wtmj,0) else 0 end as 动态产成品货值面积,
case when SJjgbadate is null and datediff(yy,getdate(),isnull(ld.Yjjgbadate,'2099-12-31'))=0 then isnull(syhz,0) else 0 end as 动态准产成品货值金额, -- 计划竣备时间在今年且未竣备的剩余货值
case when SJjgbadate is null and datediff(yy,getdate(),isnull(ld.Yjjgbadate,'2099-12-31'))=0 then isnull(ytwsmj,0)+isnull(wtmj,0) else 0 end as 动态准产成品货值面积,
--实际竣工备案在年前的
CASE WHEN ld.SJjgbadate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) THEN ISNULL(ld.syhz, 0) ELSE 0 END as 动态产成品货值金额_集团考核版,
CASE WHEN ld.SJjgbadate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) ELSE 0 END as 动态产成品货值面积_集团考核版,
--（实际竣备时间为空或实际竣备时间在今年）且（预计＞计划竣备时间在今年内）+ 预计竣备时间在去年，但是实际竣备时间在今年的剩余货值 
CASE WHEN datediff(yy,getdate(),isnull(ld.SJjgbadate,getdate()))=0 and datediff(yy,getdate(),isnull(ld.YJjgbadate,'2099-12-31'))=0 
THEN ISNULL(ld.syhz, 0) ELSE 0 END + CASE WHEN datediff(yy,getdate(),isnull(ld.SJjgbadate,'2099-12-31'))=0 and datediff(yy,getdate(),isnull(ld.YJjgbadate,'2099-12-31'))=-1 
THEN ISNULL(ld.syhz, 0) ELSE 0 END as 动态准产成品货值金额_含本年竣工版,
CASE WHEN datediff(yy,getdate(),isnull(ld.SJjgbadate,getdate()))=0 and datediff(yy,getdate(),isnull(ld.YJjgbadate,'2099-12-31'))=0 
THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) ELSE 0 END + CASE WHEN datediff(yy,getdate(),isnull(ld.SJjgbadate,'2099-12-31'))=0 and datediff(yy,getdate(),isnull(ld.YJjgbadate,'2099-12-31'))=-1 
THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) ELSE 0 END as 动态准产成品货值面积_含本年竣工版
into #tmp
from data_wide_dws_s_p_lddbamj ld 
left join #Cpptype t on ld.salebldguid = t.salebldguid
left join #avg_mj qh on qh.BldGUID = ld.SaleBldGUID 
inner join data_wide_dws_mdm_project pj on ld.projguid = pj.projguid
where datediff(dd,QXDate,getdate()) = 0 and pj.ManageModeName <> '代建' and ld.producttype <>'地下室/车库'

--金额调整为面积*近三个月签约价均价
select 
do.组织架构ID
,do.组织架构名称
,do.组织架构类型
,do.组织架构编码
--,年初产成品剩余货值金额/10000 as 年初产成品剩余货值金额 
,年初产成品剩余货值面积*jj.近三个月签约均价/10000.0 年初产成品剩余货值金额
,年初产成品剩余货值面积
--,年初准产成品剩余货值金额 /10000 as 年初准产成品剩余货值金额
,年初准产成品剩余货值面积*jj.近三个月签约均价/10000.0 年初准产成品剩余货值金额
,年初准产成品剩余货值面积
,本年已售产成品金额 /10000 as 本年已售产成品金额
--,本年已售产成品面积*jj.近三个月签约均价/10000.0 本年已售产成品金额
,本年已售产成品面积
,本年已售准产成品金额 /10000 as 本年已售准产成品金额
--,本年已售准产成品面积*jj.近三个月签约均价/10000.0 本年已售准产成品金额
,本年已售准产成品面积
--,预估去化产成品金额 /10000 as 预估去化产成品金额
,预估去化产成品面积*jj.近三个月签约均价/10000.0 预估去化产成品金额
,预估去化产成品面积
--,预估去化准产成品金额 /10000 as 预估去化准产成品金额
,预估去化准产成品面积*jj.近三个月签约均价/10000.0 预估去化准产成品金额
,预估去化准产成品面积
-- ,(isnull(年初产成品剩余货值金额,0)+isnull(年初准产成品剩余货值金额,0)-isnull(本年已售产成品金额,0)-isnull(本年已售准产成品金额,0)-isnull(预估去化产成品金额,0)-
-- isnull(预估去化准产成品金额,0))/10000 as 预计年底产成品货值金额  
,(isnull(年初产成品剩余货值面积,0)+isnull(年初准产成品剩余货值面积,0)-isnull(预估去化产成品面积,0)-isnull(预估去化准产成品面积,0))*jj.近三个月签约均价/10000.0 
 -本年已售准产成品金额 /10000 -本年已售产成品金额 /10000  预计年底产成品货值金额
,isnull(年初产成品剩余货值面积,0)+isnull(年初准产成品剩余货值面积,0)-isnull(本年已售产成品面积,0)-isnull(本年已售准产成品面积,0)-
isnull(预估去化产成品面积,0)-isnull(预估去化准产成品面积,0) 预计年底产成品货值面积
-- ,预计年底明年准产成品货值金额/10000 as 预计年底明年准产成品货值金额
,预计年底明年准产成品货值面积*jj.近三个月签约均价/10000.0 预计年底明年准产成品货值金额
,预计年底明年准产成品货值面积
-- ,动态产成品货值金额/10000 as 动态产成品货值金额
,动态产成品货值面积*jj.近三个月签约均价/10000.0 动态产成品货值金额
,动态产成品货值面积
-- ,动态准产成品货值金额/10000 as 动态准产成品货值金额
,动态准产成品货值面积*jj.近三个月签约均价/10000.0 动态准产成品货值金额
,动态准产成品货值面积
,动态产成品货值金额_集团考核版/10000 as 动态产成品货值金额_集团考核版
,动态产成品货值面积_集团考核版 
,动态准产成品货值金额_含本年竣工版/10000 as 动态准产成品货值金额_含本年竣工版
,动态准产成品货值面积_含本年竣工版
into #baseinfo  
from #tmp t
left join #avg_mj jj on t.SaleBldGUID = jj.bldguid
inner join dbo.Data_Wide_Dws_s_WqBaseStatic_Organization do on t.SaleBldGUID = do.组织架构id


--从产品楼栋一直往上进行汇总
DECLARE @baseinfo int 
set @baseinfo = 7
while(@baseinfo >0)
begin
    insert into #baseinfo 
    select do1.组织架构ID
        ,do1.组织架构名称
        ,do1.组织架构类型
        ,do1.组织架构编码
        ,sum(isnull(年初产成品剩余货值金额,0)) as 年初产成品剩余货值金额
        ,sum(isnull(年初产成品剩余货值面积,0)) as 年初产成品剩余货值面积
        ,sum(isnull(年初准产成品剩余货值金额,0)) as 年初准产成品剩余货值金额
        ,sum(isnull(年初准产成品剩余货值面积,0)) as 年初准产成品剩余货值面积
        ,sum(isnull(本年已售产成品金额,0)) as 本年已售产成品金额
        ,sum(isnull(本年已售产成品面积,0)) as 本年已售产成品面积
        ,sum(isnull(本年已售准产成品金额,0)) as 本年已售准产成品金额
        ,sum(isnull(本年已售准产成品面积,0)) as 本年已售准产成品面积
        ,sum(isnull(预估去化产成品金额,0)) as 预估去化产成品金额
        ,sum(isnull(预估去化产成品面积,0)) as 预估去化产成品面积
        ,sum(isnull(预估去化准产成品金额,0)) as 预估去化准产成品金额 
        ,sum(isnull(预估去化准产成品面积,0)) as 预估去化准产成品面积 
        ,sum(isnull(预计年底产成品货值金额,0)) as 预计年底产成品货值金额   
        ,sum(isnull(预计年底产成品货值面积,0)) as 预计年底产成品货值面积 
        ,sum(isnull(预计年底明年准产成品货值金额,0)) as 预计年底明年准产成品货值金额
        ,sum(isnull(预计年底明年准产成品货值面积,0)) as 预计年底明年准产成品货值面积
        ,sum(isnull(动态产成品货值金额,0)) as 动态产成品货值金额
        ,sum(isnull(动态产成品货值面积,0)) as 动态产成品货值面积
        ,sum(isnull(动态准产成品货值金额,0)) as 动态准产成品货值金额
        ,sum(isnull(动态准产成品货值面积,0)) as 动态准产成品货值面积
        ,sum(isnull(动态产成品货值金额_集团考核版,0)) as 动态产成品货值金额_集团考核版
        ,sum(isnull(动态产成品货值面积_集团考核版,0)) as 动态产成品货值面积_集团考核版 
        ,sum(isnull(动态准产成品货值金额_含本年竣工版,0)) as 动态准产成品货值金额_含本年竣工版
        ,sum(isnull(动态准产成品货值面积_含本年竣工版,0)) as 动态准产成品货值面积_含本年竣工版
    from #baseinfo t 
    inner join Data_Wide_Dws_s_WqBaseStatic_Organization do on t.组织架构id = do.组织架构id
    inner join .Data_Wide_Dws_s_WqBaseStatic_Organization do1 on do1.组织架构id = do.组织架构父级id
	where do1.组织架构类型 = @baseinfo
    group by do1.组织架构ID ,do1.组织架构名称 ,do1.组织架构类型 ,do1.组织架构编码
        
    set @baseinfo = @baseinfo - 1 
end

select *  from #baseinfo 

drop table #avg_mj,#baseinfo,#tmp
