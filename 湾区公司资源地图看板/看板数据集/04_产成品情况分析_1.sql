select
    t.清洗时间,
    t.统计维度,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联,
    case when isnull(t.项目名称,'') = '' then t.业态 else t.项目名称 end as 项目名称,
    t.业态,
    t.id,
    t.parentid,
    t.是否加背景色,
    t.二级科目,
    isnull(t.总货值面积,0) as 总货值面积,
    isnull(t.剩余货值面积,0) as 剩余货值面积,
    isnull(t.已开工剩余货值金额面积,0) as 已开工剩余货值金额面积,
    isnull(t.年初产成品剩余货值面积,0) as 年初产成品剩余货值面积,
    isnull(t.年初准产成品剩余货值面积,0) as 年初准产成品剩余货值面积,
    isnull(t.本年已售产成品面积,0) as 本年已售产成品面积,
    isnull(t.本年已售准产成品面积,0) as 本年已售准产成品面积,
    isnull(t.预估去化产成品面积,0) as 预估去化产成品面积,
    isnull(t.预估去化准产成品面积,0) as 预估去化准产成品面积,
    isnull(t.预计年底产成品货值面积,0) as 预计年底产成品货值面积,
    isnull(t.预计年底明年准产成品货值面积,0) as 预计年底明年准产成品货值面积,
    isnull(t.动态产成品货值面积,0) as 动态产成品货值面积,
    isnull(t.动态准产成品货值面积,0) as 动态准产成品货值面积,
    case
        when pj.projguid is null
        or 是否加背景色 = 1 then 0
        else 1
    end as 是否过滤, --项目层级去掉项目数据，只保留项目汇总数据 
	rank() over(partition by 外键关联 order by 是否加背景色 desc,case when t.业态 = '业态合计' then '1' else t.业态 end, 
	case when 二级科目 = '面积（万㎡）' then 1 when 二级科目 = '货值（亿元）' then 2 else 3 end,年初产成品剩余货值面积 desc ,case when isnull(t.项目名称,'') = '' then t.业态 else t.项目名称 end ) 排序
from wqzydtBi_productedinfo t
    left join data_wide_dws_mdm_project pj on t.外键关联 = pj.spreadname 
where  datediff(year,t.清洗时间,getdate()) = 0
-- where (
--     datediff(day, t.清洗时间, getdate()) <= 30 -- 最近7天的数据
--     or (
--         year(t.清洗时间) = year(getdate()) -- 本年数据
--         and (
--             day(t.清洗时间) = 1 -- 月初
--             or day(t.清洗时间) = dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(t.清洗时间), t.清洗时间))) -- 月末
--         )
--     )
-- )