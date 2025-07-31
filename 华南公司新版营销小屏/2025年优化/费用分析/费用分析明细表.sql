-- 获取本年截止到当前月份的已发生金额
SELECT  buguid,
        ProjGUID, -- 项目guid
        sum(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) as  本年费用预算, -- 年度调整后预算
        sum(case when a.month = MONTH(GETDATE()) then isnull(PlanAmount,0) + isnull(AdjustAmount,0) else 0 end) AS 本月费用预算, 
        SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end) AS 本年已发生费用,  -- 已发生费用
        sum(case when a.month = MONTH(GETDATE()) then FactAmount else 0 end) as 本月已发生费用,
        case when  sum(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) = 0 
            then 0 else SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end) /SUM(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) end as 费用使用率 -- 费用使用率  as 费用使用率
INTO #fy
FROM    [172.16.4.161].highdata_prod.dbo.data_wide_dws_fy_MonthPlanDtl a 
WHERE   a.Year = YEAR(GETDATE())
        -- AND CostShortName = '营销费用'
        and IsEndCost =1 and  CostType ='营销类'  -- 需要剔除掉客服类费用
        and costshortname not in  ('政府相关收费','法律诉讼费用','租赁费','其他','大宗交易')
        -- AND a.month <= MONTH(GETDATE()) 
        AND BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY buguid, ProjGUID


-- 本年首次签约项目
SELECT  p.TgProjCode,
        p.ProjGUID,
        p.ProjName,
        p.SpreadName, 
        ldscrgdate_hhzts  --首次认购日期_含特殊业绩 --,ldscrgdate as 首次认购日期
into #rgDate
FROM    (
            SELECT  ParentProjGUID, 
                    MIN(ldscrgdate_hhzts) AS ldscrgdate_hhzts --,min(ldscrgdate) as ldscrgdate
            FROM    [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Building
            WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
            GROUP BY ParentProjGUID 
        ) t 
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project p ON p.ProjGUID = t.ParentProjGUID
WHERE   YEAR(ldscrgdate_hhzts) = YEAR(GETDATE()) --  or  year(ldscrgdate) =year(getdate())

-- 获取项目实际签约情况
SELECT  sf.ParentProjGUID AS ProjGUID, --  项目guid
        SUM(ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0))  AS 本年签约金额, -- 单位：元
        SUM(CASE 
                WHEN MONTH(sf.StatisticalDate) = MONTH(getdate()) THEN
                    ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)
                ELSE
                    0
            END)  AS 本月签约金额 -- 单位：元
INTO #qy
FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_SalesPerf sf
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY sf.ParentProjGUID;


-- 获取联动房的销售情况
SELECT  ldf.ParentProjGUID AS projguid,
        SUM(ldf.QyAmount) AS 联动房本年签约金额,
        SUM(CASE WHEN MONTH(ldf.QyQsDate) = MONTH(GETDATE()) THEN ldf.QyAmount ELSE 0 END) AS 联动房本月签约金额
INTO    #ldf
FROM    [172.16.4.161].highdata_prod.dbo.data_wide_s_LdfSaleDtl ldf
WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 
AND     QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31' 
GROUP BY ldf.ParentProjGUID

-- 获取本年本月的签约任务
SELECT  projguid,
        SUM(ISNULL(年度签约任务, 0)) *10000.0 AS 年度签约任务, -- 单位：元
        SUM(ISNULL(月度签约任务, 0)) *10000.0 AS 月度签约任务, -- 单位：元
        sum(isnull(非项目本年实际签约金额,0) *10000.0 ) as 非项目本年实际签约金额,
        sum(isnull(非项目本月实际签约金额,0) *10000.0 ) as 非项目本月实际签约金额
INTO #qyrw
FROM    [172.16.4.161].highdata_prod.dbo.data_tb_hnyx_jdfxtb 
GROUP BY projguid


-- 固定费用
SELECT  buguid,
        ProjGUID, -- 项目guid
        SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end) AS 本年已发生固定费用,  -- 已发生费用
        SUM(ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0)) AS 本年固定费用预算
INTO #fy_fixed
FROM    [172.16.4.161].highdata_prod.dbo.data_wide_dws_fy_MonthPlanDtl a 
WHERE   a.Year = YEAR(GETDATE())
        -- 费用科目包括媒介广告、营销活动、拓展/巡展、销售道具
        and (a.ParentCode in  ('C.01.03','C.01.04','C.01.06') or a.CostCode ='C.01.08.02')
        AND BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY buguid, ProjGUID


-- 第三方分销费用
SELECT  buguid,
        ProjGUID, -- 项目guid
        SUM(case when a.month <= MONTH(GETDATE())  then FactAmount else 0 end) AS 本年已发生渠道整体费用, -- 渠道整体 -- 已发生费用
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='老带新' then FactAmount else 0 end) as 本年已发生老带新费用,
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='全民营销' then FactAmount else 0 end) as 本年已发生全民营销费用,
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='数字营销' then FactAmount else 0 end) as 本年已发生数字营销费用,
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='第三方分销' then FactAmount else 0 end) as 本年已发生第三方分销费用,
        sum(case when a.month <= MONTH(GETDATE())  and  CostShortName ='其他渠道专属费用' then FactAmount else 0 end) as 本年已发生其他渠道专属费用,

        SUM(ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0)) AS 本年渠道整体费用预算,  -- 渠道整体
        sum(case when   CostShortName ='老带新' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 本年老带新费用预算,
        sum(case when   CostShortName ='全民营销' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 本年全民营销费用预算,
        sum(case when   CostShortName ='数字营销' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 本年数字营销费用预算,
        sum(case when   CostShortName ='第三方分销' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 本年第三方分销费用预算,
        sum(case when   CostShortName ='其他渠道专属费用' then  ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0) else 0 end) as 本年其他渠道专属费用预算
INTO #fy_channel
FROM    [172.16.4.161].highdata_prod.dbo.data_wide_dws_fy_MonthPlanDtl a 
WHERE   a.Year = YEAR(GETDATE())
        AND CostShortName in ('第三方分销','老带新','全民营销','数字营销','其他渠道专属费用')
        -- AND a.month <= MONTH(GETDATE()) 
        AND BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY buguid, ProjGUID




-- 获取第三方分销签约金额
SELECT  
     sf.ParentProjGUID as ProjGUID, -- 项目GUID
     count(sf.roomguid) as 本年渠道整体签约套数,
     sum(QdQyAmount) as 本年渠道整体签约金额,

     count(case when sf.FourthSaleCostName ='第三方分销' then sf.roomguid else null end) as 本年第三方分销签约套数,
     sum(case when sf.FourthSaleCostName ='第三方分销' then QdQyAmount else 0 end) as 本年第三方分销签约金额,

     count(case when sf.FourthSaleCostName ='老带新' then sf.roomguid else null end) as 本年老带新签约套数,
     sum(case when sf.FourthSaleCostName ='老带新' then QdQyAmount else 0 end) as 本年老带新签约金额,

     count(case when sf.FourthSaleCostName ='全民营销' then sf.roomguid else null end) as 本年全民营销签约套数,
     sum(case when sf.FourthSaleCostName ='全民营销' then QdQyAmount else 0 end) as 本年全民营销签约金额,

     count(case when sf.FourthSaleCostName ='数字营销' then sf.roomguid else null end) as 本年数字营销签约套数,
     sum(case when sf.FourthSaleCostName ='数字营销' then QdQyAmount else 0 end) as 本年数字营销签约金额
into #qdqy_channel
FROM [172.16.4.161].highdata_prod.dbo.data_wide_s_CstSourceRoominfo sf
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_s_RoomoVerride r ON sf.roomguid = r.roomguid
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'-- and  FourthSaleCostName ='第三方分销'
 and sf.FourthSaleCostName <> '销售代理'
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
-- 剔除联动房签约金额
and not exists (select 1 from [172.16.4.161].highdata_prod.dbo.data_wide_s_LdfSaleDtl ld where ld.roomguid = sf.roomguid )
GROUP BY sf.ParentProjGUID


-- 查询结果
select 
        p.projguid as 项目guid,
        tb.项目编码 as  项目代码,
        p.tgprojcode as 投管代码,
        tb.营销事业部 as 公司事业部,
        tb.营销片区 as 组团,
        tb.项目名称,
        tb.推广名称,    
        tb.项目负责人 as 营销经理,
        tb.城市 as 城市,
        CASE WHEN YEAR(p.BeginDate) > 2022 THEN '新增量' WHEN YEAR(p.BeginDate) = 2022 THEN '增量' ELSE '存量' END as 项目获取状态,

        -- 本月费用
        fy.本月费用预算 as 本月费用总额,
        fy.本月已发生费用 as 本月实际发生费用,
        CASE WHEN ( ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0) ) = 0 THEN 0 
                ELSE ISNULL(fy.本月已发生费用, 0) /(ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0)) END AS 本月营销费率,
        -- 本年费用
        fy.本年费用预算 as 本年费用总额,
        fy.本年已发生费用 as 本年实际发生费用,
        CASE WHEN ( ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0) ) = 0 THEN 0 
                ELSE ISNULL(fy.本年已发生费用, 0) /(ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0)) END  as 本年营销费率,    
        
        -- 费率偏差
        CASE WHEN ( ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0) ) = 0 THEN 0 
              ELSE ISNULL(fy.本年已发生费用, 0)/(ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0))  
                -  ISNULL(tr.目标费率, 0) END  as 费率偏差,

        -- 费用进度偏差
        CASE WHEN  ISNULL(qyrw.年度签约任务, 0) =0  then  0 
         else  (ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0)) /ISNULL(qyrw.年度签约任务, 0) -  ISNULL(isnull(fy.费用使用率,0), 0) end  as 费用进度偏差, -- 任务完成率-费用使用率

        -- 固定费用偏差
        CASE WHEN  (isnull(fy_fixed.本年固定费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 )  = 0 
                       THEN 0 ELSE ISNULL(fy_fixed.本年已发生固定费用, 0)/(isnull(fy_fixed.本年固定费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 ) 
        END  
        - CASE WHEN rg.projguid is null then  datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365
                      else datediff(day,rg.ldscrgdate_hhzts,getdate()) *1.0/ datediff(day,rg.ldscrgdate_hhzts,convert(varchar(4),year(getdate()))+'-12-31' ) end  as 固定费用偏差, -- 费用使用率-时间进度
                
        -- 中介渠道费率偏差
        CASE WHEN ( ISNULL(qdqy_channel.本年第三方分销签约金额, 0) ) = 0 THEN 0 ELSE ISNULL(fy_channel.本年已发生第三方分销费用, 0)/(ISNULL(qdqy_channel.本年第三方分销签约金额, 0)) END  - tr.渠道目标费率 as 中介渠道费率偏差, -- 实际费率-目标费率

        -- 目标费率
        tr.目标费率 as 目标费率,
        CASE WHEN ( ISNULL(qy.本年签约金额, 0) - isnull(ldf.联动房本年签约金额,0) ) = 0 THEN 0 ELSE ISNULL(fy.本年已发生费用, 0)/(ISNULL(qy.本年签约金额, 0) - isnull(ldf.联动房本年签约金额,0)) END  as 实际费率,
        case  when  ISNULL(qyrw.年度签约任务, 0) =0  then  0 else  (ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) -isnull(ldf.联动房本年签约金额,0) )/ISNULL(qyrw.年度签约任务, 0) end  任务完成率,
        case  when rg.projguid is null then  datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365
                else datediff(day,rg.ldscrgdate_hhzts,getdate()) *1.0/ datediff(day,rg.ldscrgdate_hhzts,convert(varchar(4),year(getdate()))+'-12-31' ) end  时间进度,
        fy_fixed.本年固定费用预算 - isnull(tr.固定费用预算, 0) *10000.0 as 固定费用预算, -- 注意要减去固定费用预算扣减金额
        fy_fixed.本年已发生固定费用 as 固定费用已发生,
        CASE WHEN  (isnull(fy_fixed.本年固定费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 )  = 0 
                        THEN 0 ELSE ISNULL(fy_fixed.本年已发生固定费用, 0)/(isnull(fy_fixed.本年固定费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 ) 
        END  as 固定费用使用率,
        
        tr.渠道目标费率 as 中介渠道目标费率,
        CASE WHEN ( ISNULL(qdqy_channel.本年第三方分销签约金额, 0) ) = 0 THEN 0 ELSE ISNULL(fy_channel.本年已发生第三方分销费用, 0)/(ISNULL(qdqy_channel.本年第三方分销签约金额, 0)) END  as 中介渠道实际费率,
        qdqy_channel.本年第三方分销签约金额 as 中介渠道签约金额,
        fy_channel.本年已发生第三方分销费用 as 中介渠道已发生费用,

        case when  isnull(fy_channel.本年渠道整体费用预算,0) =0  then 0 else  isnull(fy_channel.本年已发生渠道整体费用,0) / isnull(fy_channel.本年渠道整体费用预算,0) end  as 整体渠道费率,
        case when  isnull(fy_channel.本年老带新费用预算,0) =0  then 0 else  isnull(fy_channel.本年已发生老带新费用,0) / isnull(fy_channel.本年老带新费用预算,0) end  as 老带新费率,
        case when  isnull(fy_channel.本年数字营销费用预算,0) =0  then 0 else  isnull(fy_channel.本年已发生数字营销费用,0) / isnull(fy_channel.本年数字营销费用预算,0) end  as 数字营销费率,
        case when  isnull(fy_channel.本年全民营销费用预算,0) =0  then 0 else  isnull(fy_channel.本年已发生全民营销费用,0) / isnull(fy_channel.本年全民营销费用预算,0) end  as 全民营销费率,
        case when  isnull(fy_channel.本年第三方分销费用预算,0) =0  then 0 else  isnull(fy_channel.本年已发生第三方分销费用,0) / isnull(fy_channel.本年第三方分销费用预算,0) end  as 第三方分销费率,
        qdqy_channel.本年渠道整体签约套数 as 整体成交套数,
        qdqy_channel.本年渠道整体签约金额 as 整体成交金额,
        qdqy_channel.本年老带新签约套数 as 老带新成交套数,
        qdqy_channel.本年老带新签约金额 as 老带新成交金额,
        qdqy_channel.本年数字营销签约套数 as 数字营销成交套数,
        qdqy_channel.本年数字营销签约金额 as 数字营销成交金额,
        qdqy_channel.本年全民营销签约套数 as 全民营销成交套数,    
        qdqy_channel.本年全民营销签约金额 as 全民营销成交金额,
        qdqy_channel.本年第三方分销签约套数 as 第三方分销成交套数,
        qdqy_channel.本年第三方分销签约金额 as 第三方分销成交金额
FROM  
        [172.16.4.161].highdata_prod.dbo.data_tb_hn_yxpq tb
        INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project p 
            ON tb.项目GUID = p.ProjGUID
        LEFT JOIN #fy fy 
            ON tb.项目GUID = fy.ProjGUID
        LEFT JOIN #qy qy 
            ON tb.项目GUID = qy.ProjGUID
        LEFT JOIN #qyrw qyrw 
            ON tb.项目GUID = qyrw.projguid
        LEFT JOIN #ldf ldf 
            ON tb.项目GUID = ldf.projguid
        LEFT JOIN [172.16.4.161].highdata_prod.dbo.data_tb_TargetSaleMarketingRate tr 
            ON tb.项目GUID = tr.项目GUID -- 目标费率
        LEFT JOIN #fy_fixed fy_fixed 
            ON tb.项目GUID = fy_fixed.ProjGUID
        LEFT JOIN #fy_channel fy_channel 
            ON tb.项目GUID = fy_channel.ProjGUID
        LEFT JOIN #qdqy_channel qdqy_channel 
            ON tb.项目GUID = qdqy_channel.ProjGUID
        LEFT JOIN #rgDate rg 
            ON rg.projguid = fy.projguid
WHERE  p.projguid IN (@var_ProjGUID)
ORDER BY tb.营销事业部, tb.营销片区


-- 删除临时表
drop table #fy
drop table #qy
drop table #qyrw
drop table #ldf
drop table #fy_fixed
drop table #fy_channel
drop table #qdqy_channel
drop table #rgDate