declare @date_id varchar(8) = convert(varchar(8),getdate(),112)
-------------------------02 现金流情况_1---------------------------------
--缓存项目/镇街/片区统计维度，通过项目的组织架构类型3来向上汇总镇街及片区的数据
select '3' as 组织架构类型, '项目' as 统计维度
into #dw02
union all 
select '3' as 组织架构类型, '镇街' as 统计维度
union all 
select '3' as 组织架构类型, '片区' as 统计维度

--预处理时间维度
select '已实现' as 时间
into #date02
union all 
select '本年' as 时间
union all 
select '本月' as 时间
union all
select '未实现' as 时间
union all 
select '全盘' as 时间

--清空当天数据
--delete from wqzydtBi_cashflowinfo where datediff(dd,清洗时间,getdate()) = 0
 
--insert into wqzydtBi_cashflowinfo 
--预处理现金流数据
select 
org.清洗时间,
case when org.组织架构类型 = 1 then '公司'  when org.组织架构类型= 2 then '城市' else d.统计维度 end 统计维度, 
'湾区公司' 公司名称,
case when org.组织架构类型 = 2 then org.组织架构名称 else org.区域 end 城市,
case when org.组织架构类型 in (1,2) then null else org.销售片区 end 片区,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'') = '片区' then null else org.所属镇街 end 镇街,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.项目推广名 end 项目名称,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('项目') then org.组织架构名称 
when isnull(d.统计维度,'')='镇街' then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') 
else org.区域+'_'+isnull(org.销售片区,'无') end 外键关联,
da.时间,
sum(case when da.时间 = '已实现' then org.累计经营性现金流 
         when da.时间 = '本年' then org.本年经营性现金流 
         when da.时间 = '本月' then org.本月经营性现金流 
         when da.时间 = '全盘' then isnull(org.全盘现金流入,0) - isnull(org.全盘现金流出,0)
         when da.时间 = '未实现' then ( isnull(org.全盘现金流入,0) -  isnull(org.累计现金流入,0) ) - ( isnull(org.全盘现金流出,0) -  isnull(org.累计现金流出,0) ) else 0
         end) as 经营性现金流,	
sum(case when da.时间 = '已实现' then org.累计现金流入 
         when da.时间  = '本年' then org.本年现金流入 
         when da.时间  ='本月' then  org.本月现金流入 
         when da.时间 = '全盘' then isnull(org.全盘现金流入,0) 
         when da.时间 = '未实现' then  isnull(org.全盘现金流入,0) -  isnull(org.累计现金流入,0)  else 0
         end)  现金流入,	
sum(case when da.时间 = '已实现' then org.累计现金流出 
         when da.时间 = '本年' then org.本年现金流出 
         when da.时间  ='本月' then  org.本月现金流出 
         when da.时间 = '全盘' then isnull(org.全盘现金流出,0) 
         when da.时间 = '未实现' then  isnull(org.全盘现金流出,0) -  isnull(org.累计现金流出,0)  else 0
         end) 现金流出,	
sum(case when da.时间 = '已实现' then org.累计地价支出 
         when da.时间 = '本年' then org.本年地价支出 
         when da.时间  ='本月' then  org.本月地价支出 
         when da.时间 = '全盘' then isnull(org.全盘地价支出,0) 
         when da.时间 = '未实现' then  isnull(org.全盘地价支出,0) -  isnull(org.累计地价支出,0)  else 0
         end) 地价,	
sum(case when da.时间 = '已实现' then org.累计除地价外直投发生 
         when da.时间 = '本年' then org.本年除地价外直投发生 
         when da.时间  ='本月' then  org.本月除地价外直投发生 
         when da.时间 = '全盘' then isnull(org.全盘除地价外直投发生,0) 
         when da.时间 = '未实现' then  isnull(org.全盘除地价外直投发生,0) -  isnull(org.累计除地价外直投发生,0)  else 0
         end) 直投,	

sum(case when da.时间 = '已实现' then org.累计费用发生 
         when da.时间 = '本年' then org.本年费用发生 
         when da.时间  ='本月' then  org.本月费用发生 
         when da.时间 = '全盘' then isnull(org.全盘营销费用,0)  + isnull(org.全盘财务费用,0) + isnull(org.全盘管理费用,0)
         when da.时间 = '未实现' then  isnull(org.全盘营销费用,0) + isnull(org.全盘财务费用,0) + isnull(org.全盘管理费用,0) -  isnull(org.累计费用发生,0)  else 0
         end) 费用,	
sum(case when da.时间 = '已实现' then org.累计税金支出 
         when da.时间 = '本年' then org.本年税金支出 
         when da.时间  ='本月' then  org.本月税金支出 
         when da.时间 = '全盘' then isnull(org.全盘税金,0) 
         when da.时间 = '未实现' then  isnull(org.全盘税金,0) -  isnull(org.累计税金支出,0)  else 0
         end) 税金,	
sum(case when da.时间 = '已实现' then org.累计贷款余额 
         when da.时间 = '本年' then org.本年净增贷款 
         when da.时间  ='本月' then  org.本月贷款金额 
         when da.时间 = '全盘' then isnull(org.全盘贷款,0) 
         when da.时间 = '未实现' then  isnull(org.全盘贷款,0) -  isnull(org.累计贷款余额,0)  else 0
         end) 贷款,	
sum(case when da.时间 = '已实现' then org.累计股东现金流 
         when da.时间 = '本年' then org.本年股东现金流 
         when da.时间  ='本月' then  org.本月股东现金流 
         when da.时间 = '全盘' then isnull(org.全盘现金流入,0) - isnull(org.全盘现金流出,0) + isnull(org.全盘贷款,0)
         when da.时间 = '未实现' then  isnull(org.全盘现金流入,0) - isnull(org.全盘现金流出,0) + isnull(org.全盘贷款,0) - isnull(org.累计股东现金流,0) else 0
         end) 股东现金流,
-- 新增
sum(case when da.时间 = '已实现' then org.累计营销费支出 
         when da.时间 = '本年' then org.本年营销费支出 
         when da.时间  ='本月' then  org.本月营销费支出 
         when da.时间 = '全盘' then isnull(org.全盘营销费用,0) 
         when da.时间 = '未实现' then  isnull(org.全盘营销费用,0) -  isnull(org.累计营销费支出,0)  else 0
         end) 营销费用,	
sum(case when da.时间 = '已实现' then org.累计财务费支出 
         when da.时间 = '本年' then org.本年财务费支出 
         when da.时间  ='本月' then  org.本月财务费支出 
         when da.时间 = '全盘' then isnull(org.全盘财务费用,0) 
         when da.时间 = '未实现' then  isnull(org.全盘财务费用,0) -  isnull(org.累计财务费支出,0)  else 0
         end) 财务费用,	
sum(case when da.时间 = '已实现' then org.累计管理费支出 
         when da.时间 = '本年' then org.本年管理费支出 
         when da.时间  ='本月' then  org.本月管理费支出 
         when da.时间 = '全盘' then isnull(org.全盘管理费用,0) 
         when da.时间 = '未实现' then  isnull(org.全盘管理费用,0) -  isnull(org.累计管理费支出,0)  else 0
         end) 管理费用
from s_WqBaseStatic_summary org
left join #dw02 d on org.组织架构类型 = d.组织架构类型
inner join #date02 da on 1=1
where org.组织架构类型 in (1,2,3) and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by org.清洗时间,
case when org.组织架构类型 = 1 then '公司'  when org.组织架构类型= 2 then '城市' else d.统计维度 end, 
case when org.组织架构类型 = 2 then org.组织架构名称 else org.区域 end ,
case when org.组织架构类型 in (1,2) then null else org.销售片区 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'') = '片区' then null else org.所属镇街 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.项目推广名 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('项目') then org.组织架构名称 
when isnull(d.统计维度,'')='镇街' then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') 
else org.区域+'_'+isnull(org.销售片区,'无') end ,
da.时间

drop table  #dw02, #date02