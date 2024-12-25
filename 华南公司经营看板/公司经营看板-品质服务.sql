select do.ParentOrganizationName as 推广名称,
    sum(isnull(jt.PlanKFCount_ZZ,0)) as 本年应交付户数,
    sum(isnull(jt.RealJFCount_ZZ,0)) as 本年实际交付户数,
    sum(case when month(jt.DeliveryBatchDate) =month(getdate()) then isnull(jt.PlanKFCount_ZZ,0) end) as 本月应交付户数,
    sum(case when month(jt.DeliveryBatchDate) =month(getdate()) then isnull(jt.RealJFCount_ZZ,0) end) as 本月实际交付户数
into #收楼率
from data_wide_dws_s_JfPlan_Task jt
inner join data_wide_dws_mdm_Project pro on jt.ProjGUID=pro.ProjGUID
inner join data_tb_hn_yxpq pq on pro.parentguid=pq.项目guid
inner join data_wide_dws_s_dimension_organization do on pro.XMSSCSGSGUID = do.OrgGUID
where year(jt.DeliveryBatchDate) =year(getdate())
and datediff(dd,jt.DeliveryBatchDate,getdate())>=0
group by do.ParentOrganizationName


	select 
	  do.ParentOrganizationName as 推广名称,
		sum(1) as 本年问题数,
		count(distinct gd.tsroomguid) as 本年问题户数,
		sum(case when month(gd.ProcessingTime)=month(getdate())  then 1 end) as 本月问题数,
		count(distinct case when month(gd.ProcessingTime)=month(getdate())  then gd.tsroomguid end) as 本月问题户数
	into #户均问题
	from data_wide_dws_s_work_order gd
	inner join data_wide_dws_mdm_Project pro on gd.TsProjGUID=pro.ProjGUID
	inner join data_tb_hn_yxpq pq on pro.parentguid=pq.项目guid
  inner join data_wide_dws_s_dimension_organization do on pro.XMSSCSGSGUID = do.OrgGUID
	where gd.ProblemSource='日常投诉'
	AND ISNULL(gd.ClsType,'')<>'作废'
	AND gd.ReceptType in ('投诉','报修')
	AND year(gd.ProcessingTime)=year(getdate()) 
	and datediff(dd,gd.ProcessingTime,getdate())>=0
	group by 
	   do.ParentOrganizationName
		 
 
 SELECT
    pq.推广名称 as 组织名称,
    case when sum(hj.本年问题户数)=0 then 0 else 1.0*sum(hj.本年问题数)/sum(hj.本年问题户数) end as 本年户均问题,
    case when sum(hj.本月问题户数)=0 then 0 else 1.0*sum(hj.本月问题数)/sum(hj.本月问题户数) end as 本月户均问题,
    case when sum(sl.本年应交付户数)=0 then 0 else 1.0*sum(sl.本年实际交付户数)/sum(sl.本年应交付户数) end as 本年收楼率,
    case when sum(sl.本月应交付户数)=0 then 0 else 1.0*sum(sl.本月实际交付户数)/sum(sl.本月应交付户数) end as 本月收楼率
 from 
 (select distinct ParentOrganizationName as 推广名称 from data_wide_dws_s_dimension_organization where DevelopmentCompanyName='华南公司' and level=3) pq
 left join #收楼率 sl on pq.推广名称=sl.推广名称
 left join #户均问题 hj on pq.推广名称=hj.推广名称
 group by pq.推广名称
union all 
 SELECT
    '全部区事' as 组织名称,
    case when sum(hj.本年问题户数)=0 then 0 else 1.0*sum(hj.本年问题数)/sum(hj.本年问题户数) end as 本年户均问题,
    case when sum(hj.本月问题户数)=0 then 0 else 1.0*sum(hj.本月问题数)/sum(hj.本月问题户数) end as 本月户均问题,
    case when sum(sl.本年应交付户数)=0 then 0 else 1.0*sum(sl.本年实际交付户数)/sum(sl.本年应交付户数) end as 本年收楼率,
    case when sum(sl.本月应交付户数)=0 then 0 else 1.0*sum(sl.本月实际交付户数)/sum(sl.本月应交付户数) end as 本月收楼率
 from 
 (select distinct ParentOrganizationName as 推广名称 from data_wide_dws_s_dimension_organization where DevelopmentCompanyName='华南公司' and level=3) pq
 left join #收楼率 sl on pq.推广名称=sl.推广名称
 left join #户均问题 hj on pq.推广名称=hj.推广名称 
 
 drop table #收楼率,#户均问题


 -- 06工单明细核对表
 	select 
		do.ParentOrganizationName as 公司名称,
	    pq.推广名称 as 项目名称,
		gd.TsRoom as 投诉房号,
		gd.TsRoomGUID as 投诉房间GUID,
		sr.roominfo as 房间名称,
		gd.ReceptType as 工单类型,
		gd.ClassName as 工单大类,
		gd.ProDetail as 工单描述,
		gd.ProcessingTime as 工单应关闭日期,
		gd.ClsDate as 工单实际关闭日期,
		gd.ClsUser as 关闭人,
		gd.ClsMemo as 关闭备注
	from data_wide_dws_s_work_order gd
	left join data_wide_s_RoomoVerride sr on gd.tsroomguid=sr.roomguid
	inner join data_wide_dws_mdm_Project pro on gd.TsProjGUID=pro.ProjGUID
	inner join data_tb_hn_yxpq pq on pro.parentguid=pq.项目guid
	inner join data_wide_dws_s_dimension_organization do on pro.XMSSCSGSGUID = do.OrgGUID
	where gd.ProblemSource='日常投诉'
	AND ISNULL(gd.ClsType,'')<>'作废'
	AND gd.ReceptType in ('投诉','报修')
	AND year(gd.ProcessingTime)=year(getdate()) 
	and datediff(dd,gd.ProcessingTime,getdate())>=0
	-- and do.ParentOrganizationName not in ('一级整理','非我司操盘')