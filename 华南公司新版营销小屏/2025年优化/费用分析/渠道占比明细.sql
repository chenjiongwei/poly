-- 渠道费用
SELECT  p.buguid,
		    p.projguid, -- 项目GUID
		    CostShortName, --渠道名称
        SUM(case when  a.month <= MONTH(GETDATE())  then FactAmount else 0 end) AS 已发生费用,  -- 已发生费用
        SUM(ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0)) AS 本年费用预算
INTO #fy
FROM    data_wide_dws_fy_MonthPlanDtl a 
inner join data_wide_dws_mdm_project p on a.projguid = p.projguid
inner join data_tb_hn_yxpq t on p.projguid = t.项目Guid 
WHERE   a.Year = YEAR(GETDATE())
        AND CostShortName in ('自建渠道','第三方分销','老带新','全民营销','数字营销','其他渠道专属费用')
        -- AND a.month <= MONTH(GETDATE()) 
        AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
        or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
        or (${var_biz} = t.营销片区) --前台选择了具体某个组团
        or (${var_biz}  = p.spreadname)) --前台选择了具体某个项目
GROUP BY p.buguid,p.projguid,CostShortName


--第三方渠道控制费用
select p.buguid,
       p.projguid, --项目GUID
       '第三方分销' as 渠道名称,
       sum(isnull(a.第三方分销管控值,0)*10000.0) as 第三方分销管控值
into #fxfxs
from  data_tb_TargetSaleMarketingRate a
inner join data_wide_dws_mdm_project p on a.项目GUID = p.projguid
inner join data_tb_hn_yxpq t on p.projguid = t.项目Guid 
where  p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
    and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
    or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
    or (${var_biz} = t.营销片区) --前台选择了具体某个组团
    or (${var_biz}  = p.spreadname)) --前台选择了具体某个项目
group by p.buguid,p.projguid


-- 本年渠道签约金额 不含车位 
SELECT 
       csr.buguid,
       csr.fourthsalecostname,
      --  csr.projguid,
       tb.项目GUID, tb.项目编码, tb.推广名称 ,tb.营销事业部,tb.营销片区, tb.项目名称, tb.项目简称, tb.项目负责人, 
       csr.fourthsalecostname as 渠道名称,
       COUNT(1) AS 套数,
       SUM(csr.qdqyamount) AS 签约金额,
       SUM(csr.qdqybldarea) AS 签约面积
into #qdqy
FROM data_wide_s_CstSourceRoominfo csr
INNER JOIN data_wide_s_RoomoVerride r ON csr.roomguid = r.RoomGUID
inner join data_wide_dws_mdm_project p on csr.ParentProjGUID = p.projguid
inner join data_tb_hn_yxpq tb on csr.parentprojguid = tb.项目Guid 
WHERE csr.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
  and csr.fourthsalecostname <> '销售代理'
  AND qyqsDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
  AND r.ProductTypeName NOT IN (
      '地上车位',
      '普通地下车位',
      '人防车位',
      '露天车位',
      '机械停车位',
      '地下储藏室',
      '室内地上车库',
      '人防车库',
      '普通地下车库'
  )
    and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
    or (${var_biz} = tb.营销事业部) --前台选择了具体某个区域
    or (${var_biz} = tb.营销片区) --前台选择了具体某个组团
    or (${var_biz}  = p.spreadname)) --前台选择了具体某个项目
GROUP BY csr.buguid,fourthsalecostname,
       tb.项目GUID, tb.项目编码, tb.推广名称 ,tb.营销事业部,tb.营销片区, tb.项目名称, tb.项目简称, tb.项目负责人

  -- 查询结果
select a.buguid,
       a.fourthsalecostname,
       a.项目GUID, a.项目编码, a.推广名称 ,a.营销事业部,a.营销片区, a.项目名称, a.项目简称, a.项目负责人, 
       a.渠道名称,
       a.套数,
       a.签约金额,
       a.签约面积,
       b.已发生费用,
       c.第三方分销管控值,
       b.本年费用预算,
       case when c.buguid is not null and  isnull(b.已发生费用,0)  - isnull(c.第三方分销管控值,0) > 0 then '渠道费用已超标' else '' end as 费用超标预警
from #qdqy a
left join #fy b on a.项目GUID = b.projguid and a.fourthsalecostname = b.CostShortName
left join #fxfxs c on a.项目GUID = c.projguid and a.fourthsalecostname = c.渠道名称
where  1=1

-- 删除临时表
drop table #fy
drop table #fxfxs
drop table #qdqy