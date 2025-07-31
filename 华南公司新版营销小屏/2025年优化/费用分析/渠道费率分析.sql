-- 渠道费用包括：老带新、全民营销、二手、数字营销
-- 老带新：营销费用科目等于“获客渠道-老带新”；
-- 全民营销：营销费用科目等于“获客渠道-全民营销”
-- 二手：营销费用科目等于“获客渠道-第三方分销”
-- 数字营销：营销费用科目等于“获客渠道-数字营销”
SELECT 
        p.ProjGUID as ProjGUID,
        SUM(case when a.month <= MONTH(GETDATE())  then FactAmount else 0 end) AS 已发生费用, -- 渠道整体 -- 已发生费用
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='老带新' then FactAmount else 0 end) as 老带新已发生费用,
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='全民营销' then FactAmount else 0 end) as 全民营销已发生费用,
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='数字营销' then FactAmount else 0 end) as 数字营销已发生费用,
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='第三方分销' then FactAmount else 0 end) as 第三方分销已发生费用,
       -- sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='其他渠道专属费用' then FactAmount else 0 end) as 其他渠道专属费用已发生费用,

        SUM(ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0)) AS 本年费用预算,  -- 渠道整体
        sum(case when   CostShortName ='老带新' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 老带新本年费用预算,
        sum(case when   CostShortName ='全民营销' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 全民营销本年费用预算,
        sum(case when   CostShortName ='数字营销' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 数字营销本年费用预算,
        sum(case when   CostShortName ='第三方分销' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 第三方分销本年费用预算
        -- sum(case when   CostShortName ='其他渠道专属费用' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 其他渠道专属费用本年费用预算
INTO #fy
FROM    data_wide_dws_fy_MonthPlanDtl a 
inner join data_wide_dws_mdm_project p on a.ProjGUID = p.ProjGUID
inner join data_tb_hn_yxpq t on p.projguid = t.项目Guid 
WHERE   a.Year = YEAR(GETDATE())
        AND CostShortName in ('第三方分销','老带新','全民营销','数字营销','其他渠道专属费用')
        AND a.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        and  p.level =2
        and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
        or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
        or (${var_biz} = t.营销片区) --前台选择了具体某个组团
        or (${var_biz}  = p.spreadname)) --前台选择了具体某个项目
group by p.ProjGUID

-- 获取第三方分销签约金额
SELECT  
     sf.ParentProjGUID as ProjGUID, -- 项目GUID
     sum(QdQyAmount) as 本年渠道整体签约金额,
     sum(case when  sf.FourthSaleCostName ='第三方分销' then QdQyAmount else 0 end) as 本年第三方分销签约金额,
     sum(case when  sf.FourthSaleCostName ='老带新' then QdQyAmount else 0 end) as 本年老带新签约金额,
     sum(case when  sf.FourthSaleCostName ='全民营销' then QdQyAmount else 0 end) as 本年全民营销签约金额,
     sum(case when  sf.FourthSaleCostName ='数字营销' then QdQyAmount else 0 end) as 本年数字营销签约金额
into #qdqy_channel
FROM  dbo.data_wide_s_CstSourceRoominfo sf
INNER JOIN  data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 
and  sf.FourthSaleCostName in ('第三方分销','老带新','全民营销','数字营销','销售代理')
-- and  FourthSaleCostName ='第三方分销'
-- 剔除联动房签约金额
and not exists (select 1 from dbo.data_wide_s_LdfSaleDtl ld where ld.roomguid = sf.roomguid )
GROUP BY sf.ParentProjGUID

-- 统计项目层级数据
SELECT  '渠道整体' AS 渠道, case when sum(本年渠道整体签约金额) =0  then 0 else  sum(已发生费用) / sum(本年渠道整体签约金额) end  as 整体占比,null as 占比
INTO #qd
from  #fy fy
inner join #qdqy_channel q on fy.projguid = q.projguid
UNION ALL 
SELECT '老带新' AS 渠道, NULL 整体占比, case when sum(本年老带新签约金额) =0  then 0 else  sum(老带新已发生费用) / sum(本年老带新签约金额) end  as 占比
from  #fy fy
inner join #qdqy_channel q on fy.projguid = q.projguid
UNION ALL       
SELECT '全民营销' AS 渠道, NULL 整体占比, case when sum(本年全民营销签约金额) =0  then 0 else  sum(全民营销已发生费用) / sum(本年全民营销签约金额) end  as 占比
from  #fy fy
inner join #qdqy_channel q on fy.projguid = q.projguid
UNION ALL
SELECT '第三方分销' AS 渠道,NULL 整体占比, case when sum(本年第三方分销签约金额) =0  then 0 else  sum(第三方分销已发生费用) / sum(本年第三方分销签约金额) end  as 占比
from  #fy fy
inner join #qdqy_channel q on fy.projguid = q.projguid
UNION ALL 
SELECT '数字营销' AS 渠道,NULL 整体占比, case when sum(本年数字营销签约金额) =0  then 0 else  sum(数字营销已发生费用) / sum(本年数字营销签约金额) end  as 占比
from  #fy fy
inner join #qdqy_channel q on fy.projguid = q.projguid


-- 查询结果
SELECT 渠道, 整体占比,占比  AS 渠道费率
FROM #qd

-- 删除临时表
drop table  #fy
drop table  #qd

