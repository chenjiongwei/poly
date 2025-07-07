select  
    org.清洗时间, 
    case when  tj.统计维度 in ('公司') then '湾区公司'
    when tj.统计维度 in ('城市') then org.区域
    when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
    when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
    else org.项目推广名 end 外键关联,
    tax.是否含税,
    sum(动态总货值金额*10000/case when tax.是否含税 = '含税' then 1 else 1.06 end) 总货值,
    sum(已售货值金额*10000/case when tax.是否含税 = '含税' then 1 else 1.06 end) 已售货值
into #base
from s_WqBaseStatic_summary org
inner join (select '公司' 统计维度 union all select '城市' 统计维度 union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
inner join (select '含税' as 是否含税 union all select '不含税' as 是否含税) tax on 1=1
where org.组织架构类型=3 and org.平台公司名称 = '湾区公司'
and  datediff(year, org.清洗时间, getdate()) = 0
group by org.清洗时间, 
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.项目推广名 end,
tax.是否含税

select t.清洗时间,
    t.统计维度,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联id,
    t.外键关联父级id,
    t.外键关联,
    t.id,
    t.pid,
    t.组织架构名称,
    t.科目,
    t.获取时间,
    t.科目排序,
    isnull(t.立项目标成本,0) as 立项目标成本,
    isnull(t.定位目标成本,0) as 定位目标成本,
    isnull(t.执行版目标成本,0) as 执行版目标成本,
    isnull(t.总成本,0) as 总成本,
    -- 预目标成本差额 动态成本-执行目标成本
    isnull(t.总成本,0)-isnull(t.执行版目标成本,0) as 预目标成本差额,
    isnull(t.已实现,0) as 已实现,
    isnull(t.已签合同,0) as 已签合同,
    isnull(t.已支付,0) as 已支付,
    -- 已支付比例 已支付科目 / 科目动态总成本
    isnull(case when isnull(t.总成本,0) = 0 then 0 else t.已支付/t.总成本 end,0) as 已支付比例,
    isnull(t.已发生待支付,0) as 已发生待支付,
    isnull(t.待实现,0) as 待实现,
    --【待支付】=已删除的【已发生待支付】+【待实现】
    isnull(t.已发生待支付,0)+isnull(t.待实现,0) as 待支付,
    isnull(t.总成本降本目标,0) as 总成本降本目标,
    isnull(t.已实现降本金额,0) as 已实现降本金额,
    isnull(t.达成率,0) as 达成率,
    t.是否含税,
    t.排序 
into #res
from wqzydtBi_dtcostinfo t 
where ( 总成本 <> 0 or 执行版目标成本 <> 0 )  and  datediff(year, t.清洗时间, getdate()) = 0
union all 
-- 营销费占签约额比    
select t.清洗时间,
    t.统计维度,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联id,
    t.外键关联父级id,
    t.外键关联,
    replace(t.id,'营销费','营销费占签约额比') as id,
    t.pid,
    t.组织架构名称,
    '营销费占签约额比' 科目,
    t.获取时间,
    t.科目排序,
    isnull(case when b.总货值 = 0 then 0 else t.立项目标成本/b.总货值 end,0) 立项目标成本,
    isnull(case when b.总货值 = 0 then 0 else t.定位目标成本/b.总货值 end,0) 定位目标成本,
    isnull(case when b.总货值 = 0 then 0 else t.执行版目标成本/b.总货值 end,0) 执行版目标成本, --目标比例
    isnull(case when b.总货值 = 0 then 0 else t.总成本/b.总货值 end,0) 总成本, --动态比例
    -- 预目标成本差额 动态成本-执行目标成本
    isnull(case when b.总货值 = 0 then 0 else t.总成本/b.总货值 end,0)-isnull(case when b.总货值 = 0 then 0 else t.执行版目标成本/b.总货值 end,0) 预目标成本差额,
    0 已实现,
    0 已签合同,
    isnull(case when b.已售货值 = 0 then 0 else t.已支付/b.已售货值 end,0) 已支付,
    -- 已支付比例 已支付科目 / 科目动态总成本
    isnull(case when isnull(t.总成本,0) = 0 then 0 else t.已支付/t.总成本 end,0) as 已支付比例,
    0 已发生待支付,
    0 待实现,
    0 待支付,
    isnull(t.总成本降本目标,0) as 总成本降本目标,
    isnull(t.已实现降本金额,0) as 已实现降本金额,
    isnull(t.达成率,0) as 达成率,
    t.是否含税,
    t.排序 
from wqzydtBi_dtcostinfo t
    left join #base b on t.外键关联 = b.外键关联 and t.清洗时间 = b.清洗时间  and t.是否含税 = b.是否含税
where ( 总成本 <> 0 or 执行版目标成本 <> 0 ) and t.科目 = '营销费'  and  datediff(year, t.清洗时间, getdate()) = 0
union all 
-- 管理费占签约额比    
select t.清洗时间,
    t.统计维度,
    t.公司,
    t.城市,
    t.片区,
    t.镇街,
    t.项目,
    t.外键关联id,
    t.外键关联父级id,
    t.外键关联,
    replace(t.id,'管理费','管理费占签约额比') as id ,
    t.pid,
    t.组织架构名称,
    '管理费占签约额比' 科目,
    t.获取时间,
    t.科目排序,
    isnull(case when b.总货值 = 0 then 0 else t.立项目标成本/b.总货值 end,0) 立项目标成本,
    isnull(case when b.总货值 = 0 then 0 else t.定位目标成本/b.总货值 end,0) 定位目标成本,
    isnull(case when b.总货值 = 0 then 0 else t.执行版目标成本/b.总货值 end,0) 执行版目标成本,
    isnull(case when b.总货值 = 0 then 0 else t.总成本/b.总货值 end,0) 总成本,
    -- 预目标成本差额 动态成本-执行目标成本
    isnull(case when b.总货值 = 0 then 0 else t.总成本/b.总货值 end,0)-isnull(case when b.总货值 = 0 then 0 else t.执行版目标成本/b.总货值 end,0) 预目标成本差额,
    0 已实现,
    0 已签合同,
    isnull(case when b.已售货值 = 0 then 0 else t.已支付/b.已售货值 end,0) 已支付,
    -- 已支付比例 已支付科目 / 科目动态总成本
    isnull(case when isnull(t.总成本,0) = 0 then 0 else t.已支付/t.总成本 end,0) as 已支付比例,
    0 已发生待支付,
    0 待实现,
    0 待支付,
    isnull(t.总成本降本目标,0) as 总成本降本目标,
    isnull(t.已实现降本金额,0) as 已实现降本金额,
    isnull(t.达成率,0) as 达成率,
    t.是否含税,
    t.排序 
from wqzydtBi_dtcostinfo t
    left join #base b on t.外键关联 = b.外键关联 and t.清洗时间 = b.清洗时间  and t.是否含税 = b.是否含税
where ( 总成本 <> 0 or 执行版目标成本 <> 0 ) and t.科目 = '管理费' and  datediff(year, t.清洗时间, getdate()) = 0

select * from #res t --where  t.外键关联 = '河源保利阅江台' and datediff(dd, 清洗时间, getdate()) = 0

drop table #base,#res