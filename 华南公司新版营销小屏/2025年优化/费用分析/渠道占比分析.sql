
-- 本年渠道签约金额 不含车位 
SELECT 
       csr.buguid,
       fourthsalecostname,
       COUNT(1) AS 套数,
       SUM(csr.qdqyamount) AS 签约金额,
       SUM(csr.qdqybldarea) AS 签约面积
into #qdqy
FROM data_wide_s_CstSourceRoominfo csr
INNER JOIN data_wide_s_RoomoVerride r ON csr.roomguid = r.RoomGUID
inner join data_wide_dws_mdm_project p on csr.ParentProjGUID = p.projguid
inner join data_tb_hn_yxpq t on csr.parentprojguid = t.项目Guid 
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
    or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
    or (${var_biz} = t.营销片区) --前台选择了具体某个组团
    or (${var_biz}  = p.spreadname)) --前台选择了具体某个项目
GROUP BY csr.buguid,fourthsalecostname


-- 自然来访签约金额统计 年度总签约-渠道签约
SELECT  p.buguid, 
        SUM(ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0))  AS 本年签约金额,
        SUM(ISNULL(sf.CNetCount, 0) + ISNULL(sf.SpecialCNetCount, 0))  AS 本年签约套数,  
        SUM(CASE 
                WHEN MONTH(sf.StatisticalDate) = MONTH(getdate()) THEN
                    ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)
                ELSE
                    0
            END)  AS 本月签约金额 
INTO #qy
FROM dbo.data_wide_dws_s_SalesPerf sf
INNER JOIN data_wide_dws_mdm_Project p ON sf.parentprojguid = p.ProjGUID
inner join data_tb_hn_yxpq t on sf.parentprojguid = t.项目Guid 
WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
and   sf.TopProductTypeName<>'地下室/车库'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
    and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
    or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
    or (${var_biz} = t.营销片区) --前台选择了具体某个组团
    or (${var_biz}  = p.spreadname)) --前台选择了具体某个项目
GROUP BY p.buguid

-- 统计非项目实际签约金额
SELECT  buguid,
        sum(isnull(非项目本年实际签约金额,0) *10000.0 ) as 非项目本年实际签约金额,
        sum(isnull(非项目本月实际签约金额,0) *10000.0 ) as 非项目本月实际签约金额
INTO #fxmqy
FROM    data_tb_hnyx_jdfxtb a
inner join data_wide_dws_mdm_project p on a.projguid = p.projguid
inner join data_tb_hn_yxpq t on p.projguid = t.项目Guid 
where 业态<>'地下室/车库'
    and p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
    and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
    or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
    or (${var_biz} = t.营销片区) --前台选择了具体某个组团
    or (${var_biz}  = p.spreadname)) --前台选择了具体某个项目
GROUP BY buguid



-- 渠道费用
SELECT  p.buguid,
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
GROUP BY p.buguid,CostShortName


--第三方渠道控制费用
select p.buguid,
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
group by p.buguid

-- 0206 渠道占比分析
SELECT 
'自然来访' 渠道大类, '自然来访' AS 渠道,
isnull(a.本年签约金额,0) + isnull(c.非项目本年实际签约金额,0) -isnull(b.签约金额,0) as 金额, 
isnull(a.本年签约套数,0) -isnull(b.套数,0) as  套数,
'' as 费用超标预警
from #qy a
inner join (select buguid,sum(签约金额) as 签约金额,sum(套数) as 套数 from  #qdqy group by  buguid ) b on a.buguid = b.buguid
left join #fxmqy c on a.buguid = c.buguid
UNION ALL 
select '渠道' 渠道大类, a.fourthsalecostname as 渠道,  a.签约金额 as 金额,  a.套数, 
-- isnull(b.已发生费用,0) as 已发生费用  , isnull(c.第三方分销管控值,0) as 第三方分销管控值,
    case when c.BUGUID is not null and  isnull(b.已发生费用,0)  - isnull(c.第三方分销管控值,0) > 0 then '渠道费用已超标' else '' end as 费用超标预警
from   #qdqy a
inner join #fy b on a.buguid = b.buguid and a.fourthsalecostname = b.CostShortName
left join #fxfxs c on a.buguid = c.buguid and a.fourthsalecostname = c.渠道名称



--删除临时表
drop table #qdqy
drop table #qy
drop table #fy
drop table #fxmqy
drop table #fxfxs
