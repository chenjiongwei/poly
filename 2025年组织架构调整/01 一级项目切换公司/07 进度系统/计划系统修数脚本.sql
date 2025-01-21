--计划系统修数

--jd_ProjectPlanTemplate
select * into jd_ProjectPlanTemplate_20220225 from jd_ProjectPlanTemplate

select *
into delete_jd_ProjectPlanTemplate
 from (
select *,row_number()over( partition by name,code order by id) rn from jd_ProjectPlanTemplate where buguid in (
select newbuguid from dqy_proj_20220124
)) t where t.rn>1

delete from jd_ProjectPlanTemplate where id in (
select id from (
select *,row_number()over( partition by name,code order by id) rn from jd_ProjectPlanTemplate where buguid in (
select newbuguid from dqy_proj_20220124
)) t where t.rn>1);

--jd_ProjectPlanTemplateTask

 select * 
 into jd_ProjectPlanTemplateTask_delete
 from jd_ProjectPlanTemplateTask where ProjectPlanTemplateID in (
select id from delete_jd_ProjectPlanTemplate
)

delete from jd_ProjectPlanTemplateTask where ProjectPlanTemplateID in (
select id from delete_jd_ProjectPlanTemplate
)

--jd_ProjectPlanExecute

select distinct a.id from jd_ProjectPlanExecute a
inner join jd_ProjectPlanExecute_bak_20220223 b on a.id = b.id 
where a.TemplatePlanID <> b.TemplatePlanID


select * into jd_ProjectPlanExecute_20220225 from jd_ProjectPlanExecute


update jd set jd.TemplatePlanID = ne.id from jd_ProjectPlanExecute jd
inner join delete_jd_ProjectPlanTemplate t on jd.TemplatePlanID = t.id
inner join jd_ProjectPlanTemplate ne on ne.name = t.name and ne.buguid = jd.buguid
where jd.id in (
select distinct a.id from jd_ProjectPlanExecute a
inner join jd_ProjectPlanExecute_bak_20220223 b on a.id = b.id 
where a.TemplatePlanID <> b.TemplatePlanID
) 

--jd_DeptExaminePeriod




select * into jd_DeptExaminePeriod_20220225 from jd_DeptExaminePeriod

select *
into delete_jd_DeptExaminePeriod
 from (
select *,row_number()over( partition by buguid,day order by id) rn from jd_DeptExaminePeriod where buguid in (
select newbuguid from dqy_proj_20220124
)) t where t.rn>1

select * from jd_DeptExaminePeriod

delete from jd_DeptExaminePeriod where id in (
select id from (
select *,row_number()over( partition by buguid,day order by id) rn from jd_DeptExaminePeriod  where buguid in (
select newbuguid from dqy_proj_20220124
)) t where t.rn>1);