--改成层级关系
select
    t.清洗时间,
    t.统计维度_1,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联,
    t.统计时间 + '合计' id,
    null parentid,
    t.统计时间,
    '合计' 统计维度,
    sum(isnull(t.计划开工, 0)) as 计划开工,
    sum(isnull(t.计划竣工, 0)) as 计划竣工,
    sum(isnull(t.计划在建, 0)) as 计划在建,
    sum(isnull(t.动态开工, 0)) as 动态开工,
    sum(isnull(t.动态竣工, 0)) as 动态竣工,
    sum(isnull(t.动态在建, 0)) as 动态在建
from
    wqzydtBi_scheduleinfo t
where
    datediff(year, 清洗时间, getdate()) = 0 -- and t.外键关联 = '湾区公司'
group by
    t.清洗时间,
    t.统计维度_1,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联,
    t.统计时间
union
all
select
    t.清洗时间,
    t.统计维度_1,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联,
    t.统计时间 + t.统计维度 id,
    t.统计时间 + '合计' parentid,
    t.统计时间,
    t.统计维度,
    sum(isnull(t.计划开工, 0)) as 计划开工,
    sum(isnull(t.计划竣工, 0)) as 计划竣工,
    sum(isnull(t.计划在建, 0)) as 计划在建,
    sum(isnull(t.动态开工, 0)) as 动态开工,
    sum(isnull(t.动态竣工, 0)) as 动态竣工,
    sum(isnull(t.动态在建, 0)) as 动态在建
from
    wqzydtBi_scheduleinfo t
where
    datediff(year, 清洗时间, getdate()) = 0 -- and t.外键关联 = '湾区公司'
group by
    t.清洗时间,
    t.统计维度_1,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联,
    t.统计时间,
    t.统计维度