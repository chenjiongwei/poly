--0203 量价费利营销费率
--获取前台变量，按照区域、项目、组团来进行统计
select 
    pj.projguid,pj.buguid,pj.spreadname,
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
-- and pj.projguid in ${proj} 
and pj.level = 2

--判断是否拥有公司全项目权限，若大于等于138个项目，则视为有公司项目权限
select 
    pj.* , 
    case when t.项目个数 >=138 then  pj.buguid
    when ${var_biz}  = pj.spreadname then pj.projguid else null end 统计维度
into #p
from #p1 pj
inner join (select count(distinct projguid) as 项目个数 from #p1) t on 1=1

-- 获取各项目的填报任务
select SUM(ISNULL(年度签约任务, 0)) AS 本年签约任务,SUM(ISNULL(月度签约任务, 0)) AS 本月签约任务
into #task 
from data_tb_hnyx_jdfxtb rw  
inner join #p p on rw.projguid =p.projguid
 

--获取项目对应的营销费用数据
select 
    t.* ,
    fy.本年费用预算,
    fy.本年已发生费用,
    fy.本年费用预算使用率,
    fy.本月费用预算,
    fy.本月已发生费用,
    fy.本月费用预算使用率,
    case when t.本年签约任务 = 0 then 0 else t.本年签约金额/t.本年签约任务 end 本年签约进度,
    case when t.本月签约任务 = 0 then 0 else t.本月签约金额/t.本月签约任务 end 本月签约进度,
    case when t.本年费用总额 = 0 then 0 else 本年实际发生费用/t.本年费用总额 end 本年费用使用率, -- 本年实际发生费用/本年费用预算总额
    case when qy.本年签约金额 = 0 then 0 else 本年实际发生费用/qy.本年签约金额 end 本年营销费率, --本年实际发生/本年签约金额
    case when t.本月费用总额 = 0 then 0 else t.本月实际发生费用/本月费用总额 end 本月费用使用率,
    case when qy.本月签约金额 = 0 then 0 else t.本月实际发生费用/qy.本月签约金额 end 本月营销费率
from (
    select  
        cost.四级科目 ,
        sum(t.本年费用总额)/10000.0 as 本年费用总额,
        --公司层级直接取系统数据，项目/区域/组团：有项目填报数，直接取项目填报数，否则取系统实际发生数 - 填报的非项目实际发生数
        sum(case when p.统计维度='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then t.本年实际发生费用/10000.0
        when isnull(cost.本年实际发生费用,0)<> 0 then cost.本年实际发生费用 else t.本年实际发生费用/10000.0-cost.非项目本年实际发生费用 end) as 本年实际发生费用,
        case when p.统计维度='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then  sum(t.本年签约任务/10000.0) 
        when  cost.四级科目= '代理佣金' then task.本年签约任务   else 0 end as 本年签约任务,
        sum(t.本年签约金额)/10000.0 as 本年签约金额,
        sum(t.本年合同发生费用)/10000.0 本年合同发生费用,
        case when sum(t.本年费用总额/10000.0) = 0 then 0 else sum(t.本年合同发生费用/10000.0)/sum(t.本年费用总额/10000.0) end 本年合同使用率,
        sum(t.本月费用总额)/10000.0 本月费用总额,
        sum(case when p.统计维度='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then t.本月实际发生费用/10000.0
        when isnull(cost.本月实际发生费用,0)<> 0 then cost.本月实际发生费用 else t.本月实际发生费用/10000.0-cost.非项目本月实际发生费用 end) as 本月实际发生费用,
        case when p.统计维度='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then sum(t.本月签约任务/10000.0) 
        when  cost.四级科目= '代理佣金' then task.本月签约任务   else 0 end  as 本月签约任务,
        -- sum(t.本月签约任务)/10000.0 as 本月签约任务,
        sum(t.本月签约金额)/10000.0 as 本月签约金额,
        sum(t.本月实际发生费用/10000.0) 本月合同发生费用,
        case when sum(t.本月费用总额/10000.0) = 0 then 0 else sum(t.本月实际发生费用/10000.0)/sum(t.本月费用总额/10000.0) end 本月合同使用率,
        '-' as 本年营销费率预警,
        '-' as 本月营销费率预警
    from fy_Dept_Analysis T
    --获取华南填报的四级科目情况
    left join (
        select c.科目名称, c.projguid, c.四级科目, c.是否展示在看板,
            sum(isnull(项目本年实际发生费用, 0)) as 本年实际发生费用,
            sum(isnull(项目本月实际发生费用, 0)) as 本月实际发生费用,
            sum(isnull(非项目本年实际发生费用, 0)) as 非项目本年实际发生费用,
            sum(isnull(非项目本月实际发生费用, 0)) as 非项目本月实际发生费用
        from data_tb_hnyxxp_FourdeptCost c
        inner join #p p on p.ProjGUID = c.projguid
        group by c.科目名称, c.projguid, c.四级科目,c.是否展示在看板
    ) cost on t.CostShortName = cost.科目名称 and cost.projguid = t.项目guid
    inner join #p p on p.ProjGUID = t.项目GUid 
    left join #task task on 1=1 --公司层级的签约任务直接取费用表的，否则取当前的任务汇总值，并将该任务放在任一科目上，避免汇总时候会导致数据重复
    where 公司名称 = '华南公司' and 是否展示在看板 = '是' 
    and datediff(dd, qxdate, getdate()) = 0
    group by cost.四级科目 ,p.统计维度, task.本年签约任务, task.本月签约任务
    union ALL
    select  
        '整体' as 四级科目 ,
        sum(t.本年费用总额)/10000.0 as 本年费用总额,
        --公司层级直接取系统数据，项目/区域/组团：有项目填报数，直接取项目填报数，否则取系统实际发生数 - 填报的非项目实际发生数
        sum(t.本年实际发生费用 )  /10000.0 as 本年实际发生费用,
        case when p.统计维度='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then  task.本年签约任务 else sum(t.本年签约任务/10000.0)  end as 本年签约任务,
        sum(t.本年签约金额 )/10000.0 as 本年签约金额,
        sum(t.本年合同发生费用 )/10000.0 本年合同发生费用,
        case when sum(t.本年费用总额/10000.0) = 0 then 0 else sum(t.本年合同发生费用/10000.0)/sum(t.本年费用总额/10000.0) end 本年合同使用率,
        sum(t.本月费用总额)/10000.0 本月费用总额,
        sum(t.本月实际发生费用 )/10000.0 as 本月实际发生费用,
        case when p.统计维度='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' then task.本月签约任务 else sum(t.本月签约任务/10000.0)  end  as 本月签约任务,
        -- sum(t.本月签约任务)/10000.0 as 本月签约任务,
        sum(t.本月签约金额)/10000.0 as 本月签约金额,
        sum(t.本月实际发生费用/10000.0) 本月合同发生费用,
        case when sum(t.本月费用总额/10000.0) = 0 then 0 else sum(t.本月实际发生费用/10000.0)/sum(t.本月费用总额/10000.0) end 本月合同使用率,
        '-' as 本年营销费率预警,
        '-' as 本月营销费率预警
    from fy_Dept_Analysis T
    inner join #p p on p.ProjGUID = t.项目GUid 
    left join #task task on 1=1 --公司层级的签约任务直接取费用表的，否则取当前的任务汇总值，并将该任务放在任一科目上，避免汇总时候会导致数据重复
    where 公司名称 = '华南公司' -- and 是否展示在看板 = '是' 
    and datediff(dd, qxdate, getdate()) = 0
    group by p.统计维度, task.本年签约任务, task.本月签约任务
) t
--本月签约金额取项目层级的
left join (
    select sum(本年签约金额)/10000 as 本年签约金额,sum(本月签约金额)/10000 as 本月签约金额
    from fy_Dept_Analysis T
    inner join #p p on p.ProjGUID = t.项目GUid 
) qy on 1=1
left join (
        SELECT  
                sum(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) /10000.0  as 本年费用预算, -- 年度调整后预算
                SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end)  /10000.0 AS 本年已发生费用,  -- 已发生费用，截止到当前月份
                case when  
                    sum(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) = 0 
                    then 0 else SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end)
                /SUM(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) end as 本年费用预算使用率, -- 费用使用率
                sum(case when a.month = MONTH(GETDATE()) then isnull(PlanAmount,0) + isnull(AdjustAmount,0) else 0 end) /10000.0 as 本月费用预算, --月度调整后预算
                SUM(case when a.month = MONTH(GETDATE()) then FactAmount else 0 end) /10000.0 AS 本月已发生费用,  -- 已发生费用，截止到当前月份
                case when  sum(case when a.month = MONTH(GETDATE()) then isnull(PlanAmount,0) + isnull(AdjustAmount,0) else 0 end) = 0 
                    then 0 else SUM(case when a.month = MONTH(GETDATE()) then FactAmount else 0 end)
                /SUM(case when a.month = MONTH(GETDATE()) then isnull(PlanAmount,0) + isnull(AdjustAmount,0) else 0 end) end as 本月费用预算使用率 -- 费用使用率
        FROM    data_wide_dws_fy_MonthPlanDtl a 
        inner join #p p on p.ProjGUID = a.ProjGUID
        WHERE   a.Year = YEAR(GETDATE())
                -- AND CostShortName = '营销费用'
                and a.IsEndCost =1 and  a.CostType ='营销类'  -- 需要剔除掉客服类费用
                and a.costshortname not in  ('政府相关收费','法律诉讼费用','租赁费','其他','大宗交易')
                -- AND a.month <= MONTH(GETDATE()) 
                AND a.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
) fy on 1=1
 

--汇总数据
drop table #p,#p1,#task

