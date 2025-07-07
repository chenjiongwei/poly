-- ////////////////////1、整体费率偏差榜单////////////////////
-- 包含字段：项目、营销经理、费率偏差、评分、目标费率、实际费率、签约金额
-- 入榜规则：有签约任务目标，任务完成进度达时间进度进红榜；任务完成进度不达时间进度进黑榜；
-- 目标费率填报表：data_tb_TargetSaleMarketingRate
-- 获取本年截止到当前月份的已发生金额
SELECT  buguid,
        ProjGUID, -- 项目guid
        SUM(FactAmount) AS 已发生费用  -- 已发生费用
INTO #fy
FROM    data_wide_dws_fy_MonthPlanDtl a 
WHERE   a.Year = YEAR(GETDATE())
        -- AND CostShortName = '营销费用'
        and IsEndCost =1 and  CostType ='营销类'  -- 需要剔除掉客服类费用
        and costshortname not in  ('政府相关收费','法律诉讼费用','租赁费','其他','大宗交易')
        AND a.month <= MONTH(GETDATE()) 
        AND BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY buguid, ProjGUID
 
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
FROM dbo.data_wide_dws_s_SalesPerf sf
INNER JOIN data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY sf.ParentProjGUID;

-- 获取联动房的销售情况
SELECT  ldf.ParentProjGUID AS projguid,
        SUM(ldf.QyAmount) AS 联动房本年签约金额,
        SUM(CASE WHEN MONTH(ldf.QyQsDate) = MONTH(GETDATE()) THEN ldf.QyAmount ELSE 0 END) AS 联动房本月签约金额
INTO    #ldf
FROM    data_wide_s_LdfSaleDtl ldf
WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 
AND     QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31' 
GROUP BY ldf.ParentProjGUID



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
            FROM    data_wide_dws_mdm_Building
            WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
            GROUP BY ParentProjGUID 
        ) t 
INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = t.ParentProjGUID
WHERE   YEAR(ldscrgdate_hhzts) = YEAR(GETDATE()) --  or  year(ldscrgdate) =year(getdate())

-- 获取本年本月的签约任务
SELECT  projguid,
        SUM(ISNULL(年度签约任务, 0)) *10000.0 AS 年度签约任务, -- 单位：元
        SUM(ISNULL(月度签约任务, 0)) *10000.0 AS 月度签约任务, -- 单位：元
        sum(isnull(非项目本年实际签约金额,0) *10000.0 ) as 非项目本年实际签约金额,
        sum(isnull(非项目本月实际签约金额,0) *10000.0 ) as 非项目本月实际签约金额
INTO #qyrw
FROM    data_tb_hnyx_jdfxtb 
GROUP BY projguid



-- 查询结果
SELECT *,
         /*
        红榜评分规则：
        优秀：实际费率-目标费率≤（-1%）
        良好：（-1%）＜实际费率-目标费率≤（-0.5%）
        及格：（-0.5%）＜实际费率-目标费率≤0
        黑榜评分规则：
        及格：实际费率-目标费率≤0
        严重不及格：实际费率-目标费率＞1%
        不及格：0<实际费率-目标费率≤1%
        */
        case when 本年任务完成率 >= 时间进度 and  费率偏差 <=0  then 
           -- 红榜评分
            case 
                when  费率偏差 <=0  and  费率偏差 >-0.005 then '及格'
                when  费率偏差 <=-0.01 then '优秀'
                when  费率偏差 <=-0.005 and 费率偏差> -0.01  then '良好'        
                -- when  费率偏差 >0.01 then '严重不及格'
                -- when  费率偏差 >0 and 费率偏差 <=0.01  then '不及格'
            end 
         else 
            -- 黑榜评分
            case  
                when  费率偏差 <=0  then '及格'
                when  费率偏差 >0.01 then '严重不及格'
                when  费率偏差 >0 and 费率偏差 <=0.01  then '不及格'
            end 
         end    as 评分,
     case when  本年任务完成率 >= 时间进度  and  费率偏差 <=0 then '红榜' else '黑榜' end 红黑榜
into #ztfl
FROM  (
    SELECT  tb.项目GUID, tb.项目编码, tb.推广名称 ,tb.营销事业部,tb.营销片区, tb.项目名称, tb.项目简称, tb.项目负责人, tb.组团负责人, tb.区域负责人, tr.费用分档,
            tr.目标费率 AS 目标费率, 
            CASE WHEN ( ISNULL(qy.本年签约金额, 0) - isnull(ldf.联动房本年签约金额,0) ) = 0 THEN 0 
            ELSE ISNULL(fy.已发生费用, 0) /(ISNULL(qy.本年签约金额, 0) - isnull(ldf.联动房本年签约金额,0)) END AS 实际费率, --  计算费率需要剔除掉联动房签约金额
            ISNULL(qyrw.年度签约任务, 0) AS 本年签约任务,
            ISNULL(qyrw.月度签约任务, 0) AS 本月签约任务,
            ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) -isnull(ldf.联动房本年签约金额,0) AS 本年签约金额,
            ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) -isnull(ldf.联动房本月签约金额,0) AS 本月签约金额,
            case  when  ISNULL(qyrw.年度签约任务, 0) =0  then  0 else  (ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) -isnull(ldf.联动房本年签约金额,0) )/ISNULL(qyrw.年度签约任务, 0) end as 本年任务完成率,
            case  when  ISNULL(qyrw.月度签约任务, 0) =0  then  0 else  (ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) -isnull(ldf.联动房本月签约金额,0) )/ISNULL(qyrw.月度签约任务, 0) end as 本月任务完成率,
            case  when rg.projguid is null then  datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365
               else datediff(day,rg.ldscrgdate_hhzts,getdate()) *1.0/ datediff(day,rg.ldscrgdate_hhzts,convert(varchar(4),year(getdate()))+'-12-31' ) end  as  时间进度,
            ISNULL(fy.已发生费用, 0) AS 已发生费用,
            CASE WHEN ( ISNULL(qy.本年签约金额, 0) - isnull(ldf.联动房本年签约金额,0) ) = 0 THEN 0 ELSE ISNULL(fy.已发生费用, 0)/(ISNULL(qy.本年签约金额, 0) - isnull(ldf.联动房本年签约金额,0))  
            -  ISNULL(tr.目标费率, 0) END    AS 费率偏差 -- 实际费率-目标费率
            --CASE WHEN ISNULL(fy.已发生费用, 0)/ISNULL(qy.本年签约金额, 0) > ISNULL(tr.目标费率, 0) THEN 1 ELSE 0 END AS 评分
    FROM data_tb_hn_yxpq tb
    inner join data_wide_dws_mdm_Project p on tb.项目GUID = p.ProjGUID
    LEFT JOIN #fy fy ON tb.项目GUID = fy.ProjGUID
    LEFT JOIN #qy qy ON tb.项目GUID = qy.ProjGUID
    LEFT JOIN #qyrw qyrw ON tb.项目GUID = qyrw.projguid
    LEFT JOIN #ldf ldf ON tb.项目GUID = ldf.projguid
    LEFT JOIN data_tb_TargetSaleMarketingRate tr ON tb.项目GUID = tr.项目GUID
    left join #rgDate rg on rg.ProjGUID = p.ProjGUID
    WHERE 1 = 1 and  ISNULL(qyrw.年度签约任务, 0) <> 0 and isnull(fy.已发生费用,0) <> 0
) ztfl

-- 排序
SELECT  
        t.*,
        CASE 
            WHEN 正序 = 1 THEN 1 
            WHEN 正序 = 2 THEN 2
            WHEN 正序 = 3 THEN 3
            WHEN 倒序 = 3 THEN 4
            WHEN 倒序 = 2 THEN 5
            WHEN 倒序 = 1 THEN 6
            WHEN 正序 > 3 THEN 正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 排序,
        CASE 
            WHEN 倒序 = 1 THEN '倒数第一'
            WHEN 倒序 = 2 THEN '倒数第二'   
            WHEN 倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 正序) 
        END AS 序号,
        CASE 
            WHEN 分档正序 = 1 THEN 1 
            WHEN 分档正序 = 2 THEN 2
            WHEN 分档正序 = 3 THEN 3
            WHEN 分档倒序 = 3 THEN 4
            WHEN 分档倒序 = 2 THEN 5
            WHEN 分档倒序 = 1 THEN 6
            WHEN 分档正序 > 3 THEN 分档正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 分档排序,
        CASE 
            WHEN 分档倒序 = 1 THEN '倒数第一'
            WHEN 分档倒序 = 2 THEN '倒数第二'   
            WHEN 分档倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 分档正序) 
        END AS 分档序号

FROM (
    SELECT 
            *,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 DESC , 费率偏差 ) AS 正序,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 ,费率偏差 DESC ) AS 倒序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 DESC , 费率偏差 ) AS 分档正序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 ,费率偏差 DESC ) AS 分档倒序
    FROM #ztfl 
) t
where 1=1
       and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
       or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
       or (${var_biz} = t.营销片区) --前台选择了具体某个组团
       or (${var_biz}  = t.推广名称)) --前台选择了具体某个项目 

-- 删除临时表
DROP TABLE #fy
DROP TABLE #qy  
DROP TABLE #qyrw
DROP TABLE #ztfl
drop table #rgDate 
drop table #ldf



-- ////////////////////2、整体费用使用偏差榜单////////////////////
-- 包含字段：项目、营销经理、费用偏差、评分、费用预算、已发生、费用使用率、签约金额、任务完成率
-- 入榜规则：有签约任务目标且有费用预算，任务完成进度达时间进度进红榜；任务完成进度不达时间进度进黑榜；
SELECT  buguid,
        ProjGUID, -- 项目guid
        sum(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) as 费用预算, -- 年度调整后预算
        SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end) AS 已发生费用,  -- 已发生费用，截止到当前月份
        case when  
		    sum(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) = 0 
            then 0 else SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end)
        /SUM(isnull(PlanAmount,0) + isnull(AdjustAmount,0)) end as 费用使用率 -- 费用使用率
INTO #fy
FROM    data_wide_dws_fy_MonthPlanDtl a 
WHERE   a.Year = YEAR(GETDATE())
        -- AND CostShortName = '营销费用'
        AND IsEndCost =1 and  CostType ='营销类'
        and costshortname not in  ('政府相关收费','法律诉讼费用','租赁费','其他','大宗交易')
        -- AND a.month <= MONTH(GETDATE()) 
        AND BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY buguid, ProjGUID

-- 获取联动房的销售情况
SELECT  ldf.ParentProjGUID AS projguid,
        SUM(ldf.QyAmount) AS 联动房本年签约金额,
        SUM(CASE WHEN MONTH(ldf.QyQsDate) = MONTH(GETDATE()) THEN ldf.QyAmount ELSE 0 END) AS 联动房本月签约金额
INTO    #ldf
FROM    data_wide_s_LdfSaleDtl ldf
WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 
AND     QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31' 
GROUP BY ldf.ParentProjGUID

 
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
FROM dbo.data_wide_dws_s_SalesPerf sf
INNER JOIN data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY sf.ParentProjGUID;

-- 获取本年本月的签约任务
SELECT  projguid,
        SUM(ISNULL(年度签约任务, 0)) *10000.0 AS 年度签约任务, -- 单位：元
        SUM(ISNULL(月度签约任务, 0)) *10000.0 AS 月度签约任务,-- 单位：元
        sum(isnull(非项目本年实际签约金额,0) *10000.0 ) as 非项目本年实际签约金额,
        sum(isnull(非项目本月实际签约金额,0) *10000.0 ) as 非项目本月实际签约金额
INTO #qyrw
FROM    data_tb_hnyx_jdfxtb 
GROUP BY projguid

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
            FROM    data_wide_dws_mdm_Building
            WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
            GROUP BY ParentProjGUID 
        ) t 
INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = t.ParentProjGUID
WHERE   YEAR(ldscrgdate_hhzts) = YEAR(GETDATE()) --  or  year(ldscrgdate) =year(getdate())



-- 查询结果
SELECT *,
         /*
        评分规则：
            优秀：任务完成率-费用使用率≥20%
            良好：10%≤任务完成率-费用使用率＜20%
            及格：0%≤任务完成率-费用使用率＜10%
            严重不及格：任务完成率-费用使用率≤-10%
            不及格：（-10%）≤任务完成率-费用使用率＜0%
        */
        case when  本年任务完成率 >= 时间进度  and  费率偏差 >=0 then 
            -- 红榜评分
            case when  费率偏差 >=0.2 then '优秀'
                when  费率偏差 >=0.1 and 费率偏差 <0.2  then '良好'        
                when  费率偏差 >=0 and 费率偏差 <0.1  then '及格'
                -- when  费率偏差 <-0.1  then '严重不及格'  
                -- when  费率偏差 >=-0.1 and  费率偏差 < 0  then '不及格'  
            end 
        else 
            -- 黑榜评分
            case when  费率偏差 >=0 then '及格'
                 when  费率偏差 >=-0.1 and  费率偏差 < 0  then '不及格'  
                 when  费率偏差 <-0.1  then '严重不及格'  
            end 
     end as 评分,
     case when  本年任务完成率 >= 时间进度 and 费率偏差 >=0 then '红榜' else '黑榜' end 红黑榜
into #ztfl
FROM  (
    SELECT  tb.项目GUID, tb.项目编码, tb.推广名称 ,tb.营销事业部,tb.营销片区, tb.项目名称, tb.项目简称, tb.项目负责人, tb.组团负责人, tb.区域负责人, tr.费用分档,
            --CASE WHEN ISNULL(qy.本年签约金额, 0) = 0 THEN 0 ELSE ISNULL(fy.已发生费用, 0)/ISNULL(qy.本年签约金额, 0) END AS 实际费率,
            ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0) AS 本年签约金额,
            ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0) AS 本月签约金额,
            isnull(qyrw.年度签约任务,0) as 本年签约任务,
            isnull(qyrw.月度签约任务,0) as 本月签约任务,
            case  when  ISNULL(qyrw.年度签约任务, 0) =0  then  0 else  (ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0))/ISNULL(qyrw.年度签约任务, 0) end as 本年任务完成率,
            case  when  ISNULL(qyrw.月度签约任务, 0) =0  then  0 else  (ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0))/ISNULL(qyrw.月度签约任务, 0) end as 本月任务完成率,

            -- datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365 as  时间进度,
            case  when rg.projguid is null then  datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365
               else datediff(day,rg.ldscrgdate_hhzts,getdate()) *1.0/ datediff(day,rg.ldscrgdate_hhzts,convert(varchar(4),year(getdate()))+'-12-31' ) end  as  时间进度,
            isnull(fy.费用使用率,0) as 费用使用率,
            ISNULL(fy.已发生费用, 0) AS 已发生费用,
            isnull(fy.费用预算,0) as 费用预算,
            case  when  ISNULL(qyrw.年度签约任务, 0) =0  then  0 else  (ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0))/ISNULL(qyrw.年度签约任务, 0) -  ISNULL(isnull(fy.费用使用率,0), 0) end  AS 费率偏差 -- 任务完成率-费用使用率
    FROM data_tb_hn_yxpq tb
    LEFT JOIN #fy fy ON tb.项目GUID = fy.ProjGUID
    LEFT JOIN #qy qy ON tb.项目GUID = qy.ProjGUID
    LEFT JOIN #ldf ldf ON tb.项目GUID = ldf.projguid
    LEFT JOIN #qyrw qyrw ON tb.项目GUID = qyrw.projguid
    LEFT JOIN data_tb_TargetSaleMarketingRate tr ON tb.项目GUID = tr.项目GUID
    left join  #rgDate rg on rg.projguid = fy.projguid
    WHERE 1 = 1 and  ISNULL(qyrw.年度签约任务, 0) <> 0 and  isnull(fy.费用预算,0) <> 0
) ztfl

-- 排序
SELECT  
        t.*,
        CASE 
            WHEN 正序 = 1 THEN 1 
            WHEN 正序 = 2 THEN 2
            WHEN 正序 = 3 THEN 3
            WHEN 倒序 = 3 THEN 4
            WHEN 倒序 = 2 THEN 5
            WHEN 倒序 = 1 THEN 6
            WHEN 正序 > 3 THEN 正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 排序,
        CASE 
            WHEN 倒序 = 1 THEN '倒数第一'
            WHEN 倒序 = 2 THEN '倒数第二'   
            WHEN 倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 正序) 
        END AS 序号,
        CASE 
            WHEN 分档正序 = 1 THEN 1 
            WHEN 分档正序 = 2 THEN 2
            WHEN 分档正序 = 3 THEN 3
            WHEN 分档倒序 = 3 THEN 4
            WHEN 分档倒序 = 2 THEN 5
            WHEN 分档倒序 = 1 THEN 6
            WHEN 分档正序 > 3 THEN 分档正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 分档排序,
        CASE 
            WHEN 分档倒序 = 1 THEN '倒数第一'
            WHEN 分档倒序 = 2 THEN '倒数第二'   
            WHEN 分档倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 分档正序) 
        END AS 分档序号
FROM (
    SELECT 
            *,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 DESC , 费率偏差 desc  ) AS 正序,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 ,费率偏差  ) AS 倒序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 DESC , 费率偏差 desc  ) AS 分档正序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 ,费率偏差  ) AS 分档倒序
    FROM #ztfl 
) t
where 1=1
        and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
        or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
        or (${var_biz} = t.营销片区) --前台选择了具体某个组团
        or (${var_biz}  = t.推广名称)) --前台选择了具体某个项目 

-- 删除临时表
DROP TABLE #fy
DROP TABLE #qy  
DROP TABLE #qyrw
DROP TABLE #ztfl
drop table #rgDate
drop table #ldf



--////////////////////3、固定费用使用偏差榜单////////////////////
--  包含字段：项目、营销经理、费用偏差、评分、费用预算、已发生、费用使用率、签约金额、时间进度
-- 入榜规则：有固定费用预算；任务完成进度达时间进度进红榜；任务完成进度不达时间进度进黑榜；
-- 固定费用目标费用预算如果有填报数取填报数据，没有则取系统中的本年预算金额
SELECT  buguid,
        ProjGUID, -- 项目guid
        SUM(case when a.month <= MONTH(GETDATE()) then FactAmount else 0 end) AS 已发生费用,  -- 已发生费用
        SUM(ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0)) AS 费用预算
INTO #fy
FROM    data_wide_dws_fy_MonthPlanDtl a 
WHERE   a.Year = YEAR(GETDATE())
        -- 费用科目包括媒介广告、营销活动、拓展/巡展、销售道具
        and (a.ParentCode in  ('C.01.03','C.01.04','C.01.06') or a.CostCode ='C.01.08.02')
        AND BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY buguid, ProjGUID

-- 获取联动房的销售情况 
SELECT  ldf.ParentProjGUID AS projguid,
        SUM(ldf.QyAmount) AS 联动房本年签约金额,
        SUM(CASE WHEN MONTH(ldf.QyQsDate) = MONTH(GETDATE()) THEN ldf.QyAmount ELSE 0 END) AS 联动房本月签约金额
INTO    #ldf
FROM    data_wide_s_LdfSaleDtl ldf
WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 
AND     QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31' 
GROUP BY ldf.ParentProjGUID

-- 获取项目实际签约情况
SELECT  sf.ParentProjGUID AS ProjGUID, --  项目guid
        SUM(ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0))  AS 本年签约金额, 
        SUM(CASE 
                WHEN MONTH(sf.StatisticalDate) = MONTH(getdate()) THEN
                    ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)
                ELSE
                    0
            END)  AS 本月签约金额 
INTO #qy
FROM dbo.data_wide_dws_s_SalesPerf sf
INNER JOIN data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY sf.ParentProjGUID;



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
            FROM    data_wide_dws_mdm_Building
            WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
            GROUP BY ParentProjGUID 
        ) t 
INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = t.ParentProjGUID
WHERE   YEAR(ldscrgdate_hhzts) = YEAR(GETDATE()) --  or  year(ldscrgdate) =year(getdate())

-- 获取本年本月的签约任务
SELECT  projguid,
        SUM(ISNULL(年度签约任务, 0)) *10000.0 AS 年度签约任务, 
        SUM(ISNULL(月度签约任务, 0)) *10000.0 AS 月度签约任务,
        sum(isnull(非项目本年实际签约金额,0) *10000.0 ) as 非项目本年实际签约金额,
        sum(isnull(非项目本月实际签约金额,0) *10000.0 ) as 非项目本月实际签约金额
INTO #qyrw
FROM    data_tb_hnyx_jdfxtb 
GROUP BY projguid


-- 查询结果
SELECT *,
         /*
        评分规则：
            优秀：费用使用率-时间进度≤（-10%）
            良好：（-10%）＜费用使用率-时间进度≤（-5%）
            及格：（-5%＜）费用使用率-时间进度≤0%
            不及格：费用使用率-时间进度＞0%
        */
     case when  本年任务完成率 >= 时间进度 and 费用偏差 <=0 then 
        -- 红榜评分
              case when  费用偏差 <=-0.1 then '优秀'
                when  费用偏差 >-0.1 and  费用偏差 <=-0.05 then '良好'
                when  费用偏差 >-0.05 and  费用偏差 <=0 then '及格'
                -- when  费用偏差 >0 then '不及格'
              end 
      else 
        -- 黑榜评分
        case when  费用偏差 <=0 then '及格'
             when  费用偏差 >0 then '不及格'
        end 
     end as 评分,
     case when  本年任务完成率 >= 时间进度 and 费用偏差 <=0 then '红榜' else '黑榜' end 红黑榜
into #qdfl
FROM  (
    SELECT  tb.项目GUID, tb.项目编码, tb.推广名称 ,tb.营销事业部,tb.营销片区, tb.项目名称, tb.项目简称, tb.项目负责人, tb.组团负责人, tb.区域负责人, tr.费用分档,
           --  case when  ISNULL(tr.固定费用预算, 0) <> 0  then ISNULL(tr.固定费用预算, 0) *10000.0 else  isnull(fy.费用预算,0)  END AS 固定费用预算, 
            isnull(fy.费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0  AS 固定费用预算,
            ISNULL(fy.已发生费用, 0) AS 已发生费用,
            CASE WHEN  (isnull(fy.费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 )  = 0 
                THEN 0 ELSE ISNULL(fy.已发生费用, 0)/(isnull(fy.费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 ) 
            END AS 费用使用率,
            ISNULL(qyrw.年度签约任务, 0) AS 本年签约任务,
            ISNULL(qyrw.月度签约任务, 0) AS 本月签约任务,
            ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0) AS 本年签约金额,
            ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0) AS 本月签约金额,

            case  when  ISNULL(qyrw.年度签约任务, 0) =0  then  0 else  (ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0))/ISNULL(qyrw.年度签约任务, 0) end as 本年任务完成率,
            case  when  ISNULL(qyrw.月度签约任务, 0) =0  then  0 else  (ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0))/ISNULL(qyrw.月度签约任务, 0) end as 本月任务完成率,      
           -- datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365 as  时间进度,
            case  when rg.projguid is null then  datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365
               else datediff(day,rg.ldscrgdate_hhzts,getdate()) *1.0/ datediff(day,rg.ldscrgdate_hhzts,convert(varchar(4),year(getdate()))+'-12-31' ) end  as  时间进度,       
            CASE WHEN  (isnull(fy.费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 )  = 0 
                THEN 0 ELSE ISNULL(fy.已发生费用, 0)/(isnull(fy.费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 ) 
            END
            - case  when rg.projguid is null then  datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365
               else datediff(day,rg.ldscrgdate_hhzts,getdate()) *1.0/ datediff(day,rg.ldscrgdate_hhzts,convert(varchar(4),year(getdate()))+'-12-31' ) end  AS 费用偏差 -- 费用使用率-时间进度
    FROM data_tb_hn_yxpq tb
    LEFT JOIN #fy fy ON tb.项目GUID = fy.ProjGUID
    LEFT JOIN #qy qy ON tb.项目GUID = qy.ProjGUID
    LEFT JOIN #ldf ldf ON tb.项目GUID = ldf.projguid
    LEFT JOIN #qyrw qyrw ON tb.项目GUID = qyrw.projguid
    LEFT JOIN data_tb_TargetSaleMarketingRate tr ON tb.项目GUID = tr.项目GUID --目标费率填报
    left join #rgDate rg on rg.projguid = fy.projguid 
    WHERE 1 = 1 and  ISNULL(qyrw.年度签约任务, 0) <> 0 
    and (isnull(fy.费用预算,0) - isnull(tr.固定费用预算, 0) *10000.0 ) <> 0
) qdfl

-- 排序
SELECT  
        t.*,
        CASE 
            WHEN 正序 = 1 THEN 1 
            WHEN 正序 = 2 THEN 2
            WHEN 正序 = 3 THEN 3
            WHEN 倒序 = 3 THEN 4
            WHEN 倒序 = 2 THEN 5
            WHEN 倒序 = 1 THEN 6
            WHEN 正序 > 3 THEN 正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 排序,
        CASE 
            WHEN 倒序 = 1 THEN '倒数第一'
            WHEN 倒序 = 2 THEN '倒数第二'   
            WHEN 倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 正序) 
        END AS 序号,
        CASE 
            WHEN 分档正序 = 1 THEN 1 
            WHEN 分档正序 = 2 THEN 2
            WHEN 分档正序 = 3 THEN 3
            WHEN 分档倒序 = 3 THEN 4
            WHEN 分档倒序 = 2 THEN 5
            WHEN 分档倒序 = 1 THEN 6
            WHEN 分档正序 > 3 THEN 分档正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 分档排序,
        CASE 
            WHEN 分档倒序 = 1 THEN '倒数第一'
            WHEN 分档倒序 = 2 THEN '倒数第二'   
            WHEN 分档倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 分档正序) 
        END AS 分档序号
FROM (
    SELECT 
            *,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 DESC , 费用偏差 ) AS 正序,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 ,费用偏差 DESC ) AS 倒序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 DESC , 费用偏差 desc  ) AS 分档正序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 ,费用偏差  ) AS 分档倒序
    FROM #qdfl 
) t
where 1=1
        and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
        or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
        or (${var_biz} = t.营销片区) --前台选择了具体某个组团
        or (${var_biz}  = t.推广名称)) --前台选择了具体某个项目 

-- 删除临时表
DROP TABLE #fy
DROP TABLE #qy  
DROP TABLE #qyrw
DROP TABLE #qdfl
drop table #rgDate
drop table #ldf



--////////////////////4、渠道费用使用偏差榜单////////////////////
-- 包含字段：项目、营销经理、费率偏差、评分、目标费率、实际费率、渠道签约金额
-- 入榜规则：有渠道费用发生项目；任务完成进度达时间进度进红榜；任务完成进度不达时间进度进黑榜；
SELECT  buguid,
        ProjGUID, -- 项目guid
        SUM(case when  a.month <= MONTH(GETDATE())  then FactAmount else 0 end) AS 已发生费用,  -- 已发生费用
        SUM(ISNULL(PlanAmount,0) + ISNULL(AdjustAmount,0)) AS 本年费用预算
INTO #fy
FROM    data_wide_dws_fy_MonthPlanDtl a 
WHERE   a.Year = YEAR(GETDATE())
        AND CostShortName in ('自建渠道','第三方分销','老带新','全民营销','数字营销','其他渠道专属费用')
        -- AND a.month <= MONTH(GETDATE()) 
        AND BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY buguid, ProjGUID

-- 获取联动房的销售情况 
SELECT  ldf.ParentProjGUID AS projguid,
        SUM(ldf.QyAmount) AS 联动房本年签约金额,
        SUM(CASE WHEN MONTH(ldf.QyQsDate) = MONTH(GETDATE()) THEN ldf.QyAmount ELSE 0 END) AS 联动房本月签约金额
INTO    #ldf
FROM    data_wide_s_LdfSaleDtl ldf
WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 
AND     QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31' 
GROUP BY ldf.ParentProjGUID

-- 获取项目实际签约情况
SELECT  sf.ParentProjGUID AS ProjGUID, --  项目guid
        SUM(ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0))  AS 本年签约金额, 
        SUM(CASE 
                WHEN MONTH(sf.StatisticalDate) = MONTH(getdate()) THEN
                    ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)
                ELSE
                    0
            END)  AS 本月签约金额 
INTO #qy
FROM dbo.data_wide_dws_s_SalesPerf sf
INNER JOIN data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY sf.ParentProjGUID;


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
            FROM    data_wide_dws_mdm_Building
            WHERE   BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
            GROUP BY ParentProjGUID 
        ) t 
INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = t.ParentProjGUID
WHERE   YEAR(ldscrgdate_hhzts) = YEAR(GETDATE()) --  or  year(ldscrgdate) =year(getdate())

-- 获取渠道签约金额
SELECT  sf.ParentProjGUID as ProjGUID, -- 项目GUID
     sum(QdQyAmount) as 渠道签约金额
into #qdqy
FROM data_wide_s_CstSourceRoominfo sf
INNER JOIN data_wide_dws_mdm_Project p ON sf.ProjGUID = p.ProjGUID
WHERE QyQsDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
AND p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY sf.ParentProjGUID

-- 获取本年本月的签约任务
SELECT  projguid,
        SUM(ISNULL(年度签约任务, 0)) *10000.0 AS 年度签约任务, 
        SUM(ISNULL(月度签约任务, 0)) *10000.0 AS 月度签约任务,
        sum(isnull(非项目本年实际签约金额,0) *10000.0 ) as 非项目本年实际签约金额,
        sum(isnull(非项目本月实际签约金额,0) *10000.0 ) as 非项目本月实际签约金额
INTO #qyrw
FROM    data_tb_hnyx_jdfxtb 
GROUP BY projguid


-- 查询结果
SELECT *,
         /*
        评分规则：
        优秀：实际费率-目标费率≤（-1%）
        良好：（-1%）≤实际费率-目标费率＜（-0.5%）
        及格：（-0.5%）≤实际费率-目标费率≤0
        不及格：实际费率-目标费率＞0
        */

    case when  本年任务完成率 >= 时间进度 and 费率偏差 <=0 then 
      -- 红榜评分
        case when  费率偏差 <=0  and  费率偏差 >-0.005 then '及格'
            when  费率偏差 <=-0.01 then '优秀'
            when  费率偏差 <=-0.005 and 费率偏差> -0.01  then '良好'        
            -- when  费率偏差 >0 then '不及格'
        end 
    else 
        -- 黑榜评分
        case when  费率偏差 <=0 then '及格'   
            when  费率偏差 >0 then '不及格'
        end 
    end  as 评分,
    case when  本年任务完成率 >= 时间进度 and 费率偏差 <=0 then '红榜' else '黑榜' end 红黑榜
into #qdfl
FROM  (
    SELECT  tb.项目GUID, tb.项目编码, tb.推广名称 ,tb.营销事业部,tb.营销片区, tb.项目名称, tb.项目简称, tb.项目负责人, tb.组团负责人, tb.区域负责人, tr.费用分档,
            tr.渠道目标费率 AS 目标费率,
            CASE WHEN ISNULL(fy.本年费用预算, 0) = 0 THEN 0 ELSE ISNULL(fy.已发生费用, 0)/ISNULL(fy.本年费用预算, 0) END AS 实际费率,
            isnull(fy.本年费用预算,0) as 本年费用预算,
            ISNULL(qyrw.年度签约任务, 0) AS 本年签约任务,
            ISNULL(qyrw.月度签约任务, 0) AS 本月签约任务,
            ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0) AS 本年签约金额,
            ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0) AS 本月签约金额,

            isnull(qdqy.渠道签约金额,0) as 渠道签约金额,    -- 渠道签约金额
            case  when  ISNULL(qyrw.年度签约任务, 0) =0  then  0 else  (ISNULL(qy.本年签约金额, 0) + isnull(qyrw.非项目本年实际签约金额,0) - isnull(ldf.联动房本年签约金额,0))/ISNULL(qyrw.年度签约任务, 0) end as 本年任务完成率,
            case  when  ISNULL(qyrw.月度签约任务, 0) =0  then  0 else  (ISNULL(qy.本月签约金额, 0) + isnull(qyrw.非项目本月实际签约金额,0) - isnull(ldf.联动房本月签约金额,0))/ISNULL(qyrw.月度签约任务, 0) end as 本月任务完成率,
           -- datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365 as  时间进度,
            case  when rg.projguid is null then  datediff(day,convert(varchar(4),year(getdate()))+'-01-01',getdate()) *1.0 /365
               else datediff(day,rg.ldscrgdate_hhzts,getdate()) *1.0/ datediff(day,rg.ldscrgdate_hhzts,convert(varchar(4),year(getdate()))+'-12-31' ) end  as  时间进度,   
            ISNULL(fy.已发生费用, 0) AS 已发生费用,
            CASE WHEN ISNULL(fy.本年费用预算, 0) = 0 THEN 0 ELSE ISNULL(fy.已发生费用, 0)/ISNULL(fy.本年费用预算, 0) -  ISNULL(tr.渠道目标费率, 0)   END AS 费率偏差 -- 实际费率-目标费率
            --CASE WHEN ISNULL(fy.已发生费用, 0)/ISNULL(qy.本年签约金额, 0) > ISNULL(tr.目标费率, 0) THEN 1 ELSE 0 END AS 评分
    FROM data_tb_hn_yxpq tb
    LEFT JOIN #fy fy ON tb.项目GUID = fy.ProjGUID
    LEFT JOIN #qy qy ON tb.项目GUID = qy.ProjGUID
    LEFT JOIN #ldf ldf ON tb.项目GUID = ldf.projguid
    LEFT JOIN #qyrw qyrw ON tb.项目GUID = qyrw.projguid
    LEFT JOIN #qdqy qdqy ON tb.项目GUID = qdqy.ProjGUID 
    LEFT JOIN data_tb_TargetSaleMarketingRate tr ON tb.项目GUID = tr.项目GUID --目标费率填报
    left join #rgDate rg on rg.projguid =fy.projguid
    WHERE 1 = 1 and  ISNULL(qyrw.年度签约任务, 0) <> 0 and isnull(fy.本年费用预算,0) <> 0
) qdfl

-- 排序
SELECT  
        t.*,
        CASE 
            WHEN 正序 = 1 THEN 1 
            WHEN 正序 = 2 THEN 2
            WHEN 正序 = 3 THEN 3
            WHEN 倒序 = 3 THEN 4
            WHEN 倒序 = 2 THEN 5
            WHEN 倒序 = 1 THEN 6
            WHEN 正序 > 3 THEN 正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 排序,
        CASE 
            WHEN 倒序 = 1 THEN '倒数第一'
            WHEN 倒序 = 2 THEN '倒数第二'   
            WHEN 倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 正序) 
        END AS 序号,
        CASE 
            WHEN 分档正序 = 1 THEN 1 
            WHEN 分档正序 = 2 THEN 2
            WHEN 分档正序 = 3 THEN 3
            WHEN 分档倒序 = 3 THEN 4
            WHEN 分档倒序 = 2 THEN 5
            WHEN 分档倒序 = 1 THEN 6
            WHEN 分档正序 > 3 THEN 分档正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 分档排序,
        CASE 
            WHEN 分档倒序 = 1 THEN '倒数第一'
            WHEN 分档倒序 = 2 THEN '倒数第二'   
            WHEN 分档倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 分档正序) 
        END AS 分档序号
FROM (
    SELECT 
            *,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 DESC , 费率偏差 ) AS 正序,
            ROW_NUMBER() OVER(ORDER BY 红黑榜 ,费率偏差 DESC ) AS 倒序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 DESC , 费率偏差 desc  ) AS 分档正序,
            ROW_NUMBER() OVER(PARTITION BY 费用分档 ORDER BY 红黑榜 ,费率偏差  ) AS 分档倒序
    FROM #qdfl 
) t
where 1=1
        and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
        or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
        or (${var_biz} = t.营销片区) --前台选择了具体某个组团
        or (${var_biz}  = t.推广名称)) --前台选择了具体某个项目 

-- 删除临时表
DROP TABLE #fy
DROP TABLE #qy  
DROP TABLE #qyrw
DROP TABLE #qdfl
DROP TABLE #qdqy
drop table #ldf