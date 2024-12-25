	-- 投诉报修情况_华南
    --查询各区域公司、区事、项目投诉报修情况
    select 
		'区事' as 组织类型,
		null as 父级组织,
	    do.ParentOrganizationName as 组织名称,
		sum(case when gd.ReceptType='报修' then 1 else 0 end) as 本年应关闭报修单,
		sum(case when gd.ReceptType='报修' and gd.ClsDate is not null then 1 else 0 end) as 本年报修单已关闭条数,	
        sum(case when gd.ReceptType='报修' and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本年报修单及时关闭条数,
		sum(case when gd.ReceptType='投诉' then 1 else 0 end) as 本年应关闭投诉单,
		sum(case when gd.ReceptType='投诉' and gd.ClsDate is not null then 1 else 0 end) as 本年投诉单已关闭条数,	
        sum(case when gd.ReceptType='投诉' and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本年投诉单及时关闭条数,				
		sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) then 1 else 0 end) as 本月应关闭报修单,
		sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) and gd.ClsDate is not null then 1 else 0 end) as 本月报修单已关闭条数,	
       sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本月报修单及时关闭条数,
		sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) then 1 else 0 end) as 本月应关闭投诉单,
		sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) and gd.ClsDate is not null then 1 else 0 end) as 本月投诉单已关闭条数,	
    sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本月投诉单及时关闭条数
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
  union all 
	select 
		'区事' as 组织类型,
		null as 父级组织,
	    '全部区事' as 组织名称,
		sum(case when gd.ReceptType='报修' then 1 else 0 end) as 本年应关闭报修单,
		sum(case when gd.ReceptType='报修' and gd.ClsDate is not null then 1 else 0 end) as 本年报修单已关闭条数,	
        sum(case when gd.ReceptType='报修' and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本年报修单及时关闭条数,
		sum(case when gd.ReceptType='投诉' then 1 else 0 end) as 本年应关闭投诉单,
		sum(case when gd.ReceptType='投诉' and gd.ClsDate is not null then 1 else 0 end) as 本年投诉单已关闭条数,	
        sum(case when gd.ReceptType='投诉' and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本年投诉单及时关闭条数,				
		sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) then 1 else 0 end) as 本月应关闭报修单,
		sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) and gd.ClsDate is not null then 1 else 0 end) as 本月报修单已关闭条数,	
        sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本月报修单及时关闭条数,
		sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) then 1 else 0 end) as 本月应关闭投诉单,
		sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) and gd.ClsDate is not null then 1 else 0 end) as 本月投诉单已关闭条数,	
    sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本月投诉单及时关闭条数
	from data_wide_dws_s_work_order gd
	inner join data_wide_dws_mdm_Project pro on gd.TsProjGUID=pro.ProjGUID
	inner join data_tb_hn_yxpq pq on pro.parentguid=pq.项目guid
	inner join data_wide_dws_s_dimension_organization do on pro.XMSSCSGSGUID = do.OrgGUID
	where gd.ProblemSource='日常投诉'
	AND ISNULL(gd.ClsType,'')<>'作废'
	AND gd.ReceptType in ('投诉','报修')
    AND year(gd.ProcessingTime)=year(getdate()) 
	AND datediff(dd,gd.ProcessingTime,getdate())>=0
  union all 
	select 
		'项目' as 组织类型,
		do.ParentOrganizationName as 父级组织,
	    pq.推广名称 as 组织名称,
		sum(case when gd.ReceptType='报修' then 1 else 0 end) as 本年应关闭报修单,
		sum(case when gd.ReceptType='报修' and gd.ClsDate is not null then 1 else 0 end) as 本年报修单已关闭条数,	
        sum(case when gd.ReceptType='报修' and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本年报修单及时关闭条数,
		sum(case when gd.ReceptType='投诉' then 1 else 0 end) as 本年应关闭投诉单,
		sum(case when gd.ReceptType='投诉' and gd.ClsDate is not null then 1 else 0 end) as 本年投诉单已关闭条数,	
        sum(case when gd.ReceptType='投诉' and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本年投诉单及时关闭条数,				
		sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) then 1 else 0 end) as 本月应关闭报修单,
		sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) and gd.ClsDate is not null then 1 else 0 end) as 本月报修单已关闭条数,	
        sum(case when gd.ReceptType='报修' and month(gd.ProcessingTime)=month(getdate()) and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本月报修单及时关闭条数,
		sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) then 1 else 0 end) as 本月应关闭投诉单,
		sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) and gd.ClsDate is not null then 1 else 0 end) as 本月投诉单已关闭条数,	
    sum(case when gd.ReceptType='投诉' and month(gd.ProcessingTime)=month(getdate()) and datediff(dd,gd.ProcessingTime,gd.ClsDate)<=0 then 1 else 0 end) as 本月投诉单及时关闭条数
	from data_wide_dws_s_work_order gd
	inner join data_wide_dws_mdm_Project pro on gd.TsProjGUID=pro.ProjGUID
	inner join data_tb_hn_yxpq pq on pro.parentguid=pq.项目guid
	inner join data_wide_dws_s_dimension_organization do on pro.XMSSCSGSGUID = do.OrgGUID
	where gd.ProblemSource='日常投诉'
	AND ISNULL(gd.ClsType,'')<>'作废'
	AND gd.ReceptType in ('投诉','报修')
	AND year(gd.ProcessingTime)=year(getdate()) 
	and datediff(dd,gd.ProcessingTime,getdate())>=0
	and do.ParentOrganizationName not in ('一级整理','非我司操盘')
	group by 
	   pq.推广名称,do.ParentOrganizationName