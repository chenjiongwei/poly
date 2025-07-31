--获取前台变量，按照区域、项目、组团来进行统计
select pj.projguid,pj.buguid,pj.spreadname,
DATEDIFF(DAY, DATEADD(yy, DATEDIFF(yy, 0, getdate()), 0), getdate()) * 1.00 / 365 本年时间分摊比 ,
DATEDIFF(DAY, DATEADD(mm, DATEDIFF(mm, 0, getdate()), 0), getdate()) * 1.00 / 30 AS 本月时间分摊比
into #p1
from data_wide_dws_mdm_project pj 
inner join data_tb_hn_yxpq t on pj.projguid = t.项目Guid 
where 1=1
and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
or (${var_biz} = t.营销片区) --前台选择了具体某个组团
or (${var_biz}  = pj.spreadname)) --前台选择了具体某个项目
--按照每个人的项目权限再进行过滤
and pj.projguid in ${proj} 
and pj.level = 2

--判断是否拥有公司全项目权限，若大于等于138个项目，则视为有公司项目权限
select pj.* ,case when t.项目个数 >=138 then  pj.buguid
when ${var_biz}  = pj.spreadname then pj.projguid else null end 统计维度
into #p
from #p1 pj
inner join (select count(distinct projguid) as 项目个数 from #p1) t on 1=1

--获取营销费情况
--获取项目对应的营销费用数据
select  
sum(t.本年签约任务)/10000.0 as 本年签约任务,
case when sum(t.本年签约金额/10000.0) = 0 then 0 else 
sum(case when cost.本年实际发生费用 = 0 then t.本年实际发生费用/10000.0 else cost.本年实际发生费用 end)/sum(t.本年签约金额/10000.0) end 本年营销费率
into #fy
from fy_Dept_Analysis T
--获取华南填报的四级科目情况
left join (
select c.DeptCostGUID, c.projguid,c.四级科目,是否展示在看板,
sum(case when p.统计维度 = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then isnull(c.项目本年实际发生费用,0)+isnull(c.非项目本年实际发生费用,0)
else isnull(c.项目本年实际发生费用,0) end) as 本年实际发生费用
from data_tb_hnyxxp_FourdeptCost c
inner join #p p on p.ProjGUID = c.projguid
group by c.DeptCostGUID, c.projguid,c.四级科目,是否展示在看板) cost on t.DeptCostGUID = cost.DeptCostGUID and cost.projguid = t.项目guid
inner join #p p on p.ProjGUID = t.项目GUid 
where 公司名称 = '华南公司' and 是否展示在看板 = '是'
and datediff(dd,qxdate,getdate()) = 0

-- 获取各项目的填报任务
select SUM(ISNULL(年度签约任务, 0)) AS 本年签约任务,SUM(ISNULL(月度签约任务, 0)) AS 本月签约任务
into #task
from data_tb_hnyx_jdfxtb rw  
 inner join #p p on rw.projguid = p.projguid

--获取营销费率管控数据
--非公司层级，优先取填报数据，否则取系统数据；公司层级取系统数的额度
select sum(case when p.统计维度 = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then t2.本年营销费用额度 --公司层级取系统数
when t1.本年营销费用额度 = 0 then t2.本年营销费用额度 else t1.本年营销费用额度 end)/10000.0 as 本年营销费用目标 --非公司层级优先取填报，否则取系统数
into #fy_task
--填报额度
from #p p
left join (select jd.projguid,sum(isnull(本年营销费用额度,0))*10000 as 本年营销费用额度
from data_tb_hnyx_jdfxtb jd group by jd.projguid ) t1 on p.projguid = t1.projguid
--系统数据
left join (
select t.项目GUid,sum(t.本年费用总额) as 本年营销费用额度
from fy_Dept_Analysis T
--获取华南填报的四级科目情况
left join data_tb_hnyxxp_FourdeptCost cost on t.DeptCostGUID = cost.DeptCostGUID and cost.projguid = t.项目guid
inner join #p p on p.ProjGUID = t.项目GUid
where 公司名称 = '华南公司' and 是否展示在看板 = '是'
and datediff(dd,qxdate,getdate()) = 0
group by t.项目GUid) t2 on p.projguid = t2.项目GUid

--汇总结果，并得出预警结论
select fy.*,
case when p.统计维度 = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' and fy.本年签约任务 <> 0 then ft.本年营销费用目标/fy.本年签约任务
when (p.统计维度 <> '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' or p.统计维度 is null) and task.本年签约任务 <> 0 then ft.本年营销费用目标/task.本年签约任务 
else 0 end as 本年营销费率目标
into #tmp_result
from #fy fy 
left join #fy_task ft on 1=1
left join #task task on 1=1
left join (select distinct 统计维度 from #p) p on 1=1

select t.* ,
case when 本年营销费率<=本年营销费率目标 then '费：达管控要求' else '费：未达管控要求' end
+convert(varchar(10),convert(decimal(16,2),abs(本年营销费率目标)*100))+'%'  本年营销费率预警
from #tmp_result t

drop table #fy,#fy_task,#tmp_result,#p