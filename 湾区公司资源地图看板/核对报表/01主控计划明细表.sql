select  
	xmb.organizationname as 区域,	
	p.spreadname as 项目名称,	
	fq.projname as 分期名称,
	p.TgProjCode as 项目投管代码,
	zt.组团名称,	
    jh.tasktypename as 节点类型, 
	jh.TaskName as 节点名称,
    jh.keynodename as 关键节点,
	jh.DutyBUName as 责任部门,	
    jh.DutyUserName as 责任人,
    case  when jh.TaskStateName in  ('按期完成','延期完成') then '已完成' else  '未完成' end as 工作项完成状态,
	jh.FinishTime as 计划完成时间,	
	jh.ExpectedFinishDate as 预计完成时间,	
	jh.ActualFinishTime as 实际完成时间,
	jh.PeriodGUID,
	jh.groupname as 楼栋名称
into #计划节点
from data_wide_jh_TaskDetail jh
left join data_tb_wq_yxpqtb tb on jh.projguid=tb.项目GUID
left join data_wide_dws_mdm_Project fq on jh.PeriodGUID=fq.projguid
left join data_wide_dws_mdm_Project p on jh.projguid=p.projguid
left join data_wide_dws_s_Dimension_Organization xmb on p.XMSSCSGSGUID=xmb.OrgGUID
left join 
(
	select 
		t.PeriodGUID,
		string_agg(t.BuildingGuids,'、') as BuildingGuids,
		string_agg(t.groupname,'、') as 组团名称
	from 
	(
		select
			jh.PeriodGUID,
			jh.buildingguids,
			jh.groupname,
			string_agg(jh.KeyNodeName,',') within group(order by jh.KeyNodeName) as 关键节点,
			string_agg(convert(varchar(10),jh.FinishTime,23),',') within group(order by jh.KeyNodeName) as 计划完成时间
		from data_wide_jh_TaskDetail jh
		where jh.buname ='湾区公司'
		and jh.level =1
		and jh.PlanType = 103
		and jh.KeyNodeName is not null
		group by 
			jh.PeriodGUID,
			jh.buildingguids,
			jh.groupname
	) t 
	group by 
		t.PeriodGUID,
		t.关键节点,
		t.计划完成时间
) zt on jh.PeriodGUID=zt.PeriodGUID and charindex(cast(jh.BuildingGuids as varchar(4069)),zt.BuildingGuids)>0
where jh.buname ='湾区公司'
and jh.level =1
and jh.PlanType = 103
and jh.BuildingGuids is not null
-- and  p.TgProjCode ='3137'

select distinct
    a.PeriodGUID,
	a.区域,	
	a.项目名称,	
	a.分期名称,
	a.项目投管代码,
	a.组团名称,	
    a.节点类型, 
	a.节点名称,
    a.关键节点,
	a.责任部门,	
	a.责任人,
    a.工作项完成状态,
	a.计划完成时间,	
	a.预计完成时间,	
	a.实际完成时间,
	b.组团名称单节点
-- into  #计划节点去重
from #计划节点 a 
left join 
(
	select
		PeriodGUID,
		实际完成时间,
		节点名称,
		组团名称,
		string_agg(楼栋名称,'、') as 组团名称单节点
	from #计划节点 
	group by 
		PeriodGUID,
		实际完成时间,
		节点名称,
		组团名称
) b on a.PeriodGUID=b.PeriodGUID and a.节点名称=b.节点名称 and isnull(a.实际完成时间,'1900-01-01')=isnull(b.实际完成时间,'1900-01-01') and a.组团名称=b.组团名称

-- -- 去重
-- select 
--     a.PeriodGUID,
-- 	a.区域,	
-- 	a.项目名称,	
-- 	a.分期名称,
-- 	a.项目投管代码,
-- 	-- a.组团名称,	
--     a.节点类型, 
-- 	a.节点名称,
--     a.关键节点,
-- 	a.责任部门,	
-- 	a.责任人,
-- 	a.计划完成时间,	
-- 	a.预计完成时间,	
-- 	a.实际完成时间,

-- 	CAST(
--         (SELECT STRING_AGG(value, '、') WITHIN GROUP (ORDER BY value)
--         FROM (
--             SELECT DISTINCT value
--             FROM STRING_SPLIT(
--                 (
--                     SELECT STRING_AGG(CAST(组团名称 AS NVARCHAR(MAX)), '、') WITHIN GROUP (ORDER BY 组团名称)
--                     FROM #计划节点去重
--                     WHERE PeriodGUID = a.PeriodGUID and 节点名称 = a.节点名称
--                 ), '、'
--             )
--         ) AS unique_values) AS NVARCHAR(MAX)
--     ) AS 组团名称,
--     CAST(
--         (SELECT STRING_AGG(value, '、') WITHIN GROUP (ORDER BY value)
--         FROM (
--             SELECT DISTINCT value
--             FROM STRING_SPLIT(
--                 (
--                     SELECT STRING_AGG(CAST(组团名称单节点 AS NVARCHAR(MAX)), '、') WITHIN GROUP (ORDER BY 组团名称单节点)
--                     FROM #计划节点去重
--                     WHERE PeriodGUID = a.PeriodGUID and 节点名称 = a.节点名称
--                 ), '、'
--             )
--         ) AS unique_values) AS NVARCHAR(MAX)
--     ) AS 组团名称单节点
-- from #计划节点去重 a
-- group by 
--     a.PeriodGUID,
--     a.区域,	
-- 	a.项目名称,	
-- 	a.分期名称,
-- 	a.项目投管代码,
-- 	-- a.组团名称,	
--     a.节点类型, 
-- 	a.节点名称,
--     a.关键节点,
-- 	a.责任部门,	
-- 	a.责任人,
-- 	a.计划完成时间,	
-- 	a.预计完成时间,	
-- 	a.实际完成时间
-- 	--b.组团名称单节点 


-- 删除临时表
drop table #计划节点
-- drop table #计划节点去重