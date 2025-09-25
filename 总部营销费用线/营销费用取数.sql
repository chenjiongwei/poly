 /************************************************************************
-- 费用方面：
-- 总体费率：
-- 24年1-8月 保利发展下所有项目 已发生营销类费用/已签约金额=费率
-- 25年1-8月 保利发展下所有项目 已发生营销类费用/已签约金额=费率
-- 24年全年   保利发展下所有项目 已发生营销类费用/已签约金额=费率
**************************************************************************/

with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类' and  IsEndCost =1
    group by  BUGUID,ProjGUID,ProjName
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
#con202408 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2024-08-31') =0
),
#con2024 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2024-12-31') =0
),
#con202508 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2025-08-31') =0
)

-- 查询结果
select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
) fy
inner join (
    select '24年1-8月' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con202408 con
)con  on fy.年月=con.年月

union all 
select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '25年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
) fy
inner join (
    select '25年1-8月' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con202508 con
)con  on fy.年月=con.年月

union all 
select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24全年' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
) fy
inner join (
    select '24全年' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con2024 con
)con  on fy.年月=con.年月


 /************************************************************************
-- 一线城市营销费率:
-- 24年1-8月 北京公司+上海公司+广州公司 已发生营销类费用/已签约金额=费率
-- 25年1-8月 北京公司+上海公司+广州公司 已发生营销类费用/已签约金额=费率
-- 24年全年   北京公司+上海公司+广州公司  已发生营销类费用/已签约金额=费率
**************************************************************************/

with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
#con202408 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2024-08-31') =0
),
#con2024 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2024-12-31') =0
),
#con202508 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2025-08-31') =0
), 
#bu as (
  select '5054E880-C6D5-488A-92DF-812E52E2712B' as  buguid ,'北京公司' as buname 
  union all 
  select '4975B69C-9953-4DD0-A65E-9A36DB8C66DF' as buguid,'上海公司' as buname
  union all
  select '512381FE-A9CB-E511-80B8-E41F13C51836' as buguid,'广东公司' as buname
)

-- -- 查询结果
-- select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
-- from (
--     select '24年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
--     from  #fy202408 fy
--     inner join #bu bu on fy.buguid =bu.buguid
-- ) fy
-- inner join (
--     select '24年1-8月' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
--     from  #con202408 con
--     inner join #bu bu on con.buguid =bu.buguid
-- )con  on fy.年月=con.年月

-- union all 
-- select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
-- from (
--     select '25年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
--     from  #fy202508 fy
--     inner join #bu bu  on fy.buguid =bu.buguid
-- ) fy
-- inner join (
--     select '25年1-8月' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
--     from  #con202508 con
--     inner join #bu bu  on con.buguid =bu.buguid
-- )con  on fy.年月=con.年月

-- union all 
-- select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
-- from (
--     select '24全年' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
--     from  #fy2024 fy
--     inner join #bu bu on fy.buguid =bu.buguid
-- ) fy
-- inner join (
--     select '24全年' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
--     from  #con2024 con
--     inner join #bu bu  on con.buguid =bu.buguid
-- )con  on fy.年月=con.年月

-- 查询各公司的情况
select  fy. 年月,fy.公司名称,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24年1-8月' as 年月, bu.buguid, buname as 公司名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
    inner join #bu bu on fy.buguid =bu.buguid
    group by  bu.buguid,buname
) fy
inner join (
    select '24年1-8月' as 年月, bu.buguid, buname as 公司名称,sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con202408 con
    inner join #bu bu on con.buguid =bu.buguid
    group by  bu.buguid,buname
)con  on fy.年月=con.年月 and fy.buguid =con.buguid

union all 
select  fy. 年月,fy.公司名称,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '25年1-8月' as 年月, bu.buguid, buname as 公司名称, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
    inner join #bu bu  on fy.buguid =bu.buguid
        group by  bu.buguid,buname
) fy
inner join (
    select '25年1-8月' as 年月, bu.buguid, buname as 公司名称, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con202508 con
    inner join #bu bu  on con.buguid =bu.buguid
        group by  bu.buguid,buname
)con  on fy.年月=con.年月 and fy.buguid =con.buguid

union all 
select  fy. 年月,fy.公司名称,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24全年' as 年月, bu.buguid, buname as 公司名称, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
    inner join #bu bu on fy.buguid =bu.buguid
        group by  bu.buguid,buname
) fy
inner join (
    select '24全年' as 年月,bu.buguid, buname as 公司名称, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con2024 con
    inner join #bu bu  on con.buguid =bu.buguid
        group by  bu.buguid,buname
)con  on fy.年月=con.年月 and  fy.buguid =con.buguid

 /************************************************************************
-- 新增量项目营销费率：
-- 24年1-8月 获取时间为23-24年的项目  已发生营销类费用/已签约金额=费率
-- 25年1-8月 获取时间为24-25年的项目  已发生营销类费用/已签约金额=费率
-- 24年全年    获取时间为23-24年的项目  已发生营销类费用/已签约金额=费率
**************************************************************************/
with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    group by  BUGUID,ProjGUID,ProjName
),
#con202408 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2024-08-31') =0
),
#con2024 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2024-12-31') =0
),
#con202508 as (
    select buguid,projguid,本年签约金额 
    from [172.16.4.141].erp25.dbo.S_08ZYXSQYJB_HHZTSYJ_daily  where  datediff(day,qxDate,'2025-08-31') =0
)

-- 查询结果
-- 24年1-8月 获取时间为23-24年的项目  已发生营销类费用/已签约金额=费率
select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy 
    inner join data_wide_dws_mdm_Project p on fy.projguid =p.projguid 
    where year(p.BeginDate) in (2023,2024) 
) fy
inner join (
    select '24年1-8月' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con202408 con
    inner join  data_wide_dws_mdm_Project p on con.projguid =p.projguid
    where  year(p.BeginDate) in (2023,2024)
)con  on fy.年月=con.年月

union all 
-- 25年1-8月 获取时间为24-25年的项目  已发生营销类费用/已签约金额=费率
select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '25年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
    inner join data_wide_dws_mdm_Project p on fy.projguid =p.projguid 
    where  year(p.BeginDate) in (2024,2025) 
) fy
inner join (
    select '25年1-8月' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con202508 con
    inner join  data_wide_dws_mdm_Project p on con.projguid =p.projguid
    where  year(p.BeginDate) in (2024,2025)
)con  on fy.年月=con.年月

union all 
-- 24年全年    获取时间为23-24年的项目  已发生营销类费用/已签约金额=费率
select  fy. 年月,fy.已发生营销类费用,con.已签约金额,case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24全年' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
    inner join data_wide_dws_mdm_Project p on fy.projguid =p.projguid 
    where  year(p.BeginDate) in (2023,2024) 
) fy
inner join (
    select '24全年' as 年月, sum(isnull(本年签约金额,0))/10000.0 as  已签约金额
    from  #con2024 con
    inner join  data_wide_dws_mdm_Project p on con.projguid =p.projguid
    where  year(p.BeginDate) in (2023,2024)
)con  on fy.年月=con.年月


 /************************************************************************
-- 转化统计
-- 24年1-8月转化：销售代理+营销活动+客户维护物料科目下 合同已发生金额
-- 25年1-8月转化：销售代理+营销活动+客户维护物料科目下 合同已发生金额
-- 24年转化：          销售代理+营销活动+客户维护物料科目下 合同已发生金额
**************************************************************************/
with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.01.%' or costcode like 'C.01.04.%'  or  costcode like 'C.01.05.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    and ( costcode like 'C.01.01.%' or costcode like 'C.01.04.%'  or  costcode like 'C.01.05.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.01.%' or costcode like 'C.01.04.%'  or  costcode like 'C.01.05.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fycost as (
    
       select  'C.01.01' as costcode, '销售代理' as costname
       union 
       select 'C.01.04' as costcode, '活动公司费用' as costname
       union 
       select 'C.01.05' as costcode, '客户维护物料' as costname
) 
-- 查询结果
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24年1-8月' as 年月, cost.costname as 科目名称 ,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '25年1-8月' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24全年' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

 /************************************************************************
-- 24年1-8月获客：获客渠道+媒介广告+拓展/巡展科目下 合同已发生 合同已发生金额
-- 25年1-8月获客：获客渠道+媒介广告+拓展/巡展科目下 合同已发生 合同已发生金额
-- 24年获客：          获客渠道+媒介广告+拓展/巡展科目下 合同已发生 合同已发生金额
**************************************************************************/

with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.02.%' or costcode like 'C.01.03.%'  or  costcode like 'C.01.06.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    and ( costcode like 'C.01.02.%' or costcode like 'C.01.03.%'  or  costcode like 'C.01.06.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.02.%' or costcode like 'C.01.03.%'  or  costcode like 'C.01.06.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fycost as (
-- C.01.02 获客渠道
-- C.01.03 媒介广告
-- C.01.06 拓展/巡展
       select  'C.01.02' as costcode, '获客渠道' as costname
       union 
       select 'C.01.03' as costcode, '媒介广告' as costname
       union 
       select 'C.01.06' as costcode, '拓展/巡展' as costname
) 

-- 查询结果
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24年1-8月' as 年月, cost.costname as 科目名称 ,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '25年1-8月' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24全年' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

 /************************************************************************
-- 24年1-8月固定：销售场所包装+销售道具+销售工具+销售场所维护 合同已发生金额
-- 25年1-8月固定：销售场所包装+销售道具+销售工具+销售场所维护 合同已发生金额
-- 24年固定：          销售场所包装+销售道具+销售工具+销售场所维护 合同已发生金额
**************************************************************************/

with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.07.%' or costcode like 'C.01.08.%'  or  costcode like 'C.01.09.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    and ( costcode like 'C.01.07.%' or costcode like 'C.01.08.%'  or  costcode like 'C.01.09.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.07.%' or costcode like 'C.01.08.%'  or  costcode like 'C.01.09.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fycost as (
       select  'C.01.07' as costcode, '销售场所包装' as costname
       union 
       select 'C.01.08' as costcode, '销售道具' as costname
       union 
       select 'C.01.09' as costcode, '销售场所维护' as costname
) 

-- 查询结果
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24年1-8月' as 年月, cost.costname as 科目名称 ,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '25年1-8月' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24全年' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

 /************************************************************************
-- 24年1-8月其他：专业服务费+招商运营+其他 合同已发生金额
-- 25年1-8月其他：专业服务费+招商运营+其他 合同已发生金额
-- 24年其他：          专业服务费+招商运营+其他 合同已发生金额
**************************************************************************/

with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.10.%' or costcode like 'C.01.11.%'  or  costcode like 'C.01.12.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    and ( costcode like 'C.01.10.%' or costcode like 'C.01.11.%'  or  costcode like 'C.01.12.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and ( costcode like 'C.01.10.%' or costcode like 'C.01.11.%'  or  costcode like 'C.01.12.%' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fycost as (
       select  'C.01.10' as costcode, '专业服务费' as costname
       union 
       select 'C.01.11' as costcode, '招商运营' as costname
       union 
       select 'C.01.12' as costcode, '其他' as costname
) 

-- 查询结果
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24年1-8月' as 年月, cost.costname as 科目名称 ,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '25年1-8月' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

union all 
select  fy. 年月,fy.科目名称, fy.已发生营销类费用
from (
    select '24全年' as 年月, cost.costname as 科目名称,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
    inner join  #fycost cost on fy.ParentCode =cost.costcode
    group by cost.costcode,cost.costname
) fy

 /************************************************************************
-- 分销渠道费率：
-- 24年1-8月：第三方分销类合同已发生金额/已签约金额 = 费率
-- 25年1-8月：第三方分销类合同已发生金额/已签约金额 = 费率
-- 24年全年   ：第三方分销类合同已发生金额/已签约金额 = 费率
**************************************************************************/

with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and  costshortname ='第三方分销'
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    and  costshortname ='第三方分销'
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8) and  CostType ='营销类'
    and  costshortname ='第三方分销'
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#con202408 as (
    select buguid, ParentProjGUID as projguid,sum(isnull(QdQyAmount,0)) as 本年签约金额 
    from  data_wide_s_CstSourceRoominfo 
    where CstSource ='渠道分销' and  year(QyQsDate) =2024 and  month(QyQsDate) <=8
    group by  buguid, ParentProjGUID
),
#con2024 as (
    select buguid, ParentProjGUID as projguid,sum(isnull(QdQyAmount,0)) as 本年签约金额 
    from  data_wide_s_CstSourceRoominfo 
    where CstSource ='渠道分销' and  year(QyQsDate) =2024 
    group by  buguid, ParentProjGUID
),
#con202508 as (
    select buguid, ParentProjGUID as projguid,sum(isnull(QdQyAmount,0)) as 本年签约金额 
    from  data_wide_s_CstSourceRoominfo 
    where CstSource ='渠道分销' and  year(QyQsDate) =2025 and  month(QyQsDate) <=8
    group by  buguid, ParentProjGUID
)

-- 查询结果
select  fy. 年月,fy.已发生营销类费用,con.第三方分销类合同已发生金额,
case when isnull(con.第三方分销类合同已发生金额,0) =0 then 0 else fy.已发生营销类费用 / con.第三方分销类合同已发生金额 end as 费率
from (
    select '24年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
) fy
inner join (
    select '24年1-8月' as 年月, sum(isnull(本年签约金额,0))/100000000 as  第三方分销类合同已发生金额
    from  #con202408 con
)con  on fy.年月=con.年月

union all 
select  fy. 年月,fy.已发生营销类费用,con.第三方分销类合同已发生金额,
case when isnull(con.第三方分销类合同已发生金额,0) =0 then 0 else fy.已发生营销类费用 / con.第三方分销类合同已发生金额 end as 费率
from (
    select '25年1-8月' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
) fy
inner join (
    select '25年1-8月' as 年月, sum(isnull(本年签约金额,0))/100000000 as  第三方分销类合同已发生金额
    from  #con202508 con
)con  on fy.年月=con.年月

union all 
select  fy. 年月,fy.已发生营销类费用,con.第三方分销类合同已发生金额,
case when isnull(con.第三方分销类合同已发生金额,0) =0 then 0 else fy.已发生营销类费用 / con.第三方分销类合同已发生金额 end as 费率
from (
    select '24全年' as 年月, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
) fy
inner join (
    select '24全年' as 年月, sum(isnull(本年签约金额,0))/100000000 as  第三方分销类合同已发生金额
    from  #con2024 con
)con  on fy.年月=con.年月

 /************************************************************************
-- 自主获客费率：
-- 24年1-8月：老带新、全民营销、数字营销类合同已发生金额/已签约金额 = 费率（每个科目分类的合同分别计算费率）
-- 25年1-8月：老带新、全民营销、数字营销类合同已发生金额/已签约金额 = 费率（每个科目分类的合同分别计算费率）
-- 24年全年   ：老带新、全民营销、数字营销类合同已发生金额/已签约金额 = 费率（每个科目分类的合同分别计算费率）
**************************************************************************/

with #fy202408  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2024 and month in (1,2,3,4,5,6,7,8) and   CostType ='营销类'
    and  costshortname in ('老带新','全民营销','数字营销' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
 #fy2024  as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year =2024 and  CostType ='营销类'
    and  costshortname in ('老带新','全民营销','数字营销' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#fy202508 as (
    select  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname,sum(isnull(FactAmount,0) ) as FactAmount
    from data_wide_dws_fy_MonthPlanDtl 
    where Year = 2025 and month in (1,2,3,4,5,6,7,8)   and  CostType ='营销类' 
    and  costshortname in ('老带新','全民营销','数字营销' )
    group by  BUGUID,ProjGUID,ProjName,ParentCode,costcode,costshortname
),
#con202408 as (
    select buguid, ParentProjGUID as projguid,CstSource,sum(isnull(QdQyAmount,0)) as 本年签约金额 
    from  data_wide_s_CstSourceRoominfo 
    where CstSource in ('老带新','全民营销','数字营销') and  year(QyQsDate) =2024 and  month(QyQsDate) <=8
    group by  buguid, ParentProjGUID,CstSource
),
#con2024 as (
    select buguid, ParentProjGUID as projguid,CstSource,sum(isnull(QdQyAmount,0)) as 本年签约金额 
    from  data_wide_s_CstSourceRoominfo 
    where CstSource in ('老带新','全民营销','数字营销')  and  year(QyQsDate) =2024 
    group by  buguid, ParentProjGUID,CstSource
),
#con202508 as (
    select buguid, ParentProjGUID as projguid,CstSource,sum(isnull(QdQyAmount,0)) as 本年签约金额 
    from  data_wide_s_CstSourceRoominfo 
    where CstSource in ('老带新','全民营销','数字营销')  and  year(QyQsDate) =2025 and  month(QyQsDate) <=8
    group by  buguid, ParentProjGUID,CstSource
)

-- 查询结果
select  fy. 年月,fy.费用科目,fy.已发生营销类费用,con.已签约金额,
case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24年1-8月' as 年月,costshortname as 费用科目, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202408 fy
    group by  costshortname
) fy
inner join (
    select '24年1-8月' as 年月, CstSource as  客户来源,sum(isnull(本年签约金额,0))/100000000 as  已签约金额
    from  #con202408 con
    group by CstSource
)con  on fy.年月=con.年月 and  fy.费用科目 = con.客户来源

union all 
select  fy. 年月,fy.费用科目,fy.已发生营销类费用,con.已签约金额,
case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '25年1-8月' as 年月,costshortname as 费用科目, sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy202508 fy
    group by  costshortname
) fy
inner join (
    select '25年1-8月' as 年月,CstSource as  客户来源, sum(isnull(本年签约金额,0))/100000000 as  已签约金额
    from  #con202508 con
	group by CstSource
)con  on fy.年月=con.年月  and  fy.费用科目 = con.客户来源

union all 
select  fy. 年月,fy.费用科目,fy.已发生营销类费用,con.已签约金额,
case when isnull(con.已签约金额,0) =0 then 0 else fy.已发生营销类费用 / con.已签约金额 end as 费率
from (
    select '24全年' as 年月, costshortname as 费用科目,sum(isnull(FactAmount,0))/100000000.0 as  已发生营销类费用
    from  #fy2024 fy
    group by  costshortname
) fy
inner join (
    select '24全年' as 年月, CstSource as  客户来源,sum(isnull(本年签约金额,0))/100000000 as  已签约金额
    from  #con2024 con
    group by CstSource
)con  on fy.年月=con.年月 and  fy.费用科目 = con.客户来源


