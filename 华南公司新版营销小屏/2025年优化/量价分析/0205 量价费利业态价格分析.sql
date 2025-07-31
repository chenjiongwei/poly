--获取前台变量，按照区域、项目、组团来进行统计
select pj.projguid,pj.spreadname,
case when ${var_biz}  = pj.spreadname then 1 else 0 end  as 是否选择单项目 --若是项目单选，则可以取对应的一盘一策价
into #p
from data_wide_dws_mdm_project pj 
inner join data_tb_hn_yxpq t on pj.projguid = t.项目Guid  
where 1=1
and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
or (${var_biz} = t.营销片区) --前台选择了具体某个组团
or (${var_biz}  = pj.spreadname)) --前台选择了具体某个项目
--按照每个人的项目权限再进行过滤
and pj.projguid in ${proj} 
and pj.level = 2

--任务信息
select CASE WHEN rw.业态 IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN rw.业态
when rw.业态 = '别墅' then '高级住宅' ELSE '其他' END  业态,
sum(年度签约任务)*10000 as 本年签约任务,
sum(月度签约任务)*10000 as 本月签约任务
into #rw
from data_tb_hnyx_jdfxtb rw 
inner join #p p on rw.projguid = p.projguid 
group by CASE WHEN rw.业态 IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN rw.业态
when rw.业态 = '别墅' then '高级住宅' ELSE '其他' END
union all 
select '全口径' 业态,
sum(年度签约任务)*10000 as 本年签约任务,
sum(月度签约任务)*10000 as 本月签约任务
from data_tb_hnyx_jdfxtb rw 
inner join #p p on rw.projguid = p.projguid 

/*
剔除特殊业绩部分统计
select CASE WHEN TopProductTypeName IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN TopProductTypeName
when TopProductTypeName = '别墅' then '高级住宅' ELSE '其他' END as 业态,
--获取去年签约情况
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) else 0 end)  AS 去年签约金额 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) else 0 end) 去年签约套数 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 去年签约面积 ,
--获取本年签约情况
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) else 0 end)  AS 本年签约金额 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) else 0 end) 本年签约套数 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 本年签约面积 ,
--获取上月签约情况
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) else 0 end)  AS 上月签约金额 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) else 0 end) 上月签约套数 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 上月签约面积 ,
--获取本月签约情况 
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) else 0 end)  AS 本月签约金额 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) else 0 end) 本月签约套数 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 本月签约面积 ,
--近一月
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)ELSE 0 END)  AS 近一月签约金额 ,
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) AS 近一月签约套数,
SUM(case when Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() then  ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 近一月签约面积,
--近三月
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)ELSE 0 END)  AS 近三月签约金额 ,
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) AS 近三月签约套数,
SUM(case when Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() then  ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 近三月签约面积
into #sale1
from data_wide_dws_s_salesperf sale 
inner join #p pj on sale.parentprojguid = pj.ProjGUID
group by  CASE WHEN TopProductTypeName IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN TopProductTypeName
when TopProductTypeName = '别墅' then '高级住宅' ELSE '其他' END
*/

select 
CASE WHEN TopProductTypeName IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN TopProductTypeName
when TopProductTypeName = '别墅' then '高级住宅' ELSE '其他' END as 业态,
--获取去年签约情况
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetAmount, 0)  else 0 end)  AS 去年签约金额 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetCount, 0)  else 0 end) 去年签约套数 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetArea, 0)  else 0 end) 去年签约面积 ,
--获取本年签约情况
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetAmount, 0)  else 0 end)  AS 本年签约金额 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetCount, 0)  else 0 end) 本年签约套数 ,
SUM(case when datediff(yy, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetArea, 0)  else 0 end) 本年签约面积 ,
--获取上月签约情况
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetAmount, 0)  else 0 end)  AS 上月签约金额 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetCount, 0)  else 0 end) 上月签约套数 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =-1 then  ISNULL(Sale.CNetArea, 0)  else 0 end) 上月签约面积 ,
--获取本月签约情况 
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetAmount, 0)  else 0 end)  AS 本月签约金额 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetCount, 0)  else 0 end) 本月签约套数 ,
SUM(case when datediff(mm, getdate(), Sale.StatisticalDate) =0 then  ISNULL(Sale.CNetArea, 0)  else 0 end) 本月签约面积 ,
--近一月
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetAmount, 0)  ELSE 0 END)  AS 近一月签约金额 ,
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetCount, 0)  ELSE 0 END) AS 近一月签约套数,
SUM(case when Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() then  ISNULL(Sale.CNetArea, 0)  else 0 end) 近一月签约面积,
--近三月
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetAmount, 0)  ELSE 0 END)  AS 近三月签约金额 ,
SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) AS 近三月签约套数,
SUM(case when Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() then  ISNULL(Sale.CNetArea, 0)  else 0 end) 近三月签约面积
into #sale1
from data_wide_dws_s_salesperf sale 
inner join #p pj on sale.parentprojguid = pj.ProjGUID
group by  CASE WHEN TopProductTypeName IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN TopProductTypeName
when TopProductTypeName = '别墅' then '高级住宅' ELSE '其他' END

--获取各业态的价格情况
select
t.业态,本年签约金额,本月签约金额,
case when 业态 = '地下室/车库' and 去年签约套数<> 0 then 去年签约金额/去年签约套数 when 去年签约面积<> 0 then 去年签约金额/去年签约面积 else 0 end  去年签约价格,
case when 业态 = '地下室/车库' and 本年签约套数<> 0 then 本年签约金额/本年签约套数 when 本年签约面积<> 0 then 本年签约金额/本年签约面积 else 0 end 本年签约价格,
case when 业态 = '地下室/车库' and 上月签约套数<> 0 then 上月签约金额/上月签约套数 when 上月签约面积<> 0 then 上月签约金额/上月签约面积 else 0 end 上月签约价格,
case when 业态 = '地下室/车库' and 本月签约套数<> 0 then 本月签约金额/本月签约套数 when 本月签约面积<> 0 then 本月签约金额/本月签约面积 else 0 end 本月签约价格,
case when 业态 = '地下室/车库' and 近一月签约套数<> 0 then 近一月签约金额/近一月签约套数 when 近一月签约面积<> 0 then 近一月签约金额/近一月签约面积 else 0 end 近一月价格,
case when 业态 = '地下室/车库' and 近三月签约套数<> 0 then 近三月签约金额/近三月签约套数 when 近三月签约面积<> 0 then 近三月签约金额/近三月签约面积 else 0 end 近三月价格
into #sale
from #sale1 t
union all
select '全口径' 业态,sum(本年签约金额) as 本年签约金额, sum(本月签约金额) as 本月签约金额,
case when sum(isnull(去年签约面积,0))<> 0 then sum(isnull(去年签约金额,0))/sum(isnull(去年签约面积,0)) else 0 end  去年签约价格,
case when sum(isnull(本年签约面积,0))<> 0 then sum(isnull(本年签约金额,0))/sum(isnull(本年签约面积,0)) else 0 end 本年签约价格,
case when sum(isnull(上月签约面积,0))<> 0 then sum(isnull(上月签约金额,0))/sum(isnull(上月签约面积,0)) else 0 end 上月价格,
case when sum(isnull(本月签约面积,0))<> 0 then sum(isnull(本月签约金额,0))/sum(isnull(本月签约面积,0)) else 0 end 本月价格,
case when sum(isnull(近一月签约面积,0))<> 0 then sum(isnull(近一月签约金额,0))/sum(isnull(近一月签约面积,0)) else 0 end 近一月价格,
case when sum(isnull(近三月签约面积,0))<> 0 then sum(isnull(近三月签约金额,0))/sum(isnull(近三月签约面积,0)) else 0 end 近三月价格
from #sale1 t


--获取整盘价格情况
select  CASE WHEN topproductname IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN topproductname
when topproductname = '别墅' then '高级住宅' ELSE '其他' END as 业态,
sum(总货值金额) as 总货值,
sum(总货值面积) 总货值面积,
sum(总货值套数) as 总货值套数,
sum(已售金额) as 已售金额,
sum(已售面积) as 已售面积,
sum(已售套数) as 已售套数,
sum(未完工_已推未售货值金额+已完工_已推未售货值金额) 已推未售金额,
sum(未完工_已推未售货量面积+已完工_已推未售货量面积) 已推未售面积,
sum(未完工_已推未售套数+已完工_已推未售套数) 已推未售套数
into #hz1
from data_wide_dws_jh_YtHzOverview hz
inner join #p p on p.projguid = hz.projguid 
group by CASE WHEN topproductname IN ( '住宅', '高级住宅', '公寓', '商业', '写字楼','地下室/车库' ) THEN topproductname
when topproductname = '别墅' then '高级住宅' ELSE '其他' END

select 业态,
-- case when 业态 = '地下室/车库' and 总货值套数<> 0 then 总货值/总货值套数 when 总货值面积 = 0 then 0 else 总货值/总货值面积 end as 整盘去化均价,
case when 业态 = '地下室/车库' and 已售套数<> 0 then 已售金额/已售套数 when 已售面积 = 0 then 0 else 已售金额/已售面积 end as 整盘去化均价,
case when 业态 = '地下室/车库' and 已推未售套数<> 0 then 已推未售金额/已推未售套数 when 已推未售面积 = 0 then 0 else 已推未售金额/已推未售面积 end 已推未售去化均价
into #hz
from #hz1 t
union all 
select '全口径' 业态,
-- case when sum(总货值面积 )= 0 then 0 else sum(总货值)/sum(总货值面积) end as 整盘去化均价,
case when sum(已售面积) = 0 then 0 else sum(已售金额)/sum(已售面积) end as 整盘去化均价,
case when sum(已推未售面积) = 0 then 0 else sum(已推未售金额)/sum(已推未售面积) end 已推未售去化均价 
from #hz1 t

--获取一盘一策、盈亏平衡价、-30%价格线填报价格
SELECT p.projguid,
       yt.ytname,
       CASE 
           WHEN yt.ytname = '住宅' THEN ISNULL(yx.住宅价格规划, 0)
           WHEN yt.ytname IN ('别墅', '高级住宅') THEN ISNULL(yx.别墅价格规划, 0)
           WHEN yt.ytname = '公寓' THEN ISNULL(yx.公寓价格规划, 0)
           WHEN yt.ytname = '商业' THEN ISNULL(yx.商业价格规划, 0)
           WHEN yt.ytname = '地下室/车库' THEN ISNULL(yx.车位价格规划, 0)
           WHEN yt.ytname = '其他' THEN ISNULL(yx.其它价格规划, 0)
           WHEN yt.ytname = '写字楼' THEN ISNULL(yx.写字楼价格规划, 0)
           ELSE 0 
       END AS 一盘一策价,
       CASE 
           WHEN yt.ytname = '住宅' THEN ISNULL(yx.住宅盈亏平衡价, 0)
           WHEN yt.ytname IN ('别墅', '高级住宅') THEN ISNULL(yx.高级住宅盈亏平衡价, 0)
           WHEN yt.ytname = '公寓' THEN ISNULL(yx.公寓盈亏平衡价, 0)
           WHEN yt.ytname = '商业' THEN ISNULL(yx.商业盈亏平衡价, 0)
           WHEN yt.ytname = '地下室/车库' THEN ISNULL(yx.车位盈亏平衡价, 0)
           WHEN yt.ytname = '其他' THEN ISNULL(yx.其它盈亏平衡价, 0)
           WHEN yt.ytname = '写字楼' THEN ISNULL(yx.写字楼盈亏平衡价, 0)
           ELSE 0 
       END AS 盈亏平衡价,
       CASE 
           WHEN yt.ytname = '住宅' THEN ISNULL(yx.住宅负百分之三十价格线, 0)
           WHEN yt.ytname IN ('别墅', '高级住宅') THEN ISNULL(yx.高级住宅负百分之三十价格线, 0)
           WHEN yt.ytname = '公寓' THEN ISNULL(yx.公寓负百分之三十价格线, 0)
           WHEN yt.ytname = '商业' THEN ISNULL(yx.商业负百分之三十价格线, 0)
           WHEN yt.ytname = '地下室/车库' THEN ISNULL(yx.车位负百分之三十价格线, 0)
           WHEN yt.ytname = '其他' THEN ISNULL(yx.其他负百分之三十价格线, 0)
           WHEN yt.ytname = '写字楼' THEN ISNULL(yx.写字楼负百分之三十价格线, 0)
           ELSE 0 
       END AS 负百分之三十价格线
INTO #ypyc
FROM #p p 
LEFT JOIN data_tb_hn_yxpq yx ON p.projguid = yx.项目guid
INNER JOIN (
    SELECT '住宅' ytname 
    UNION ALL SELECT '高级住宅' 
    UNION ALL SELECT '公寓' 
    UNION ALL SELECT '商业'
    UNION ALL SELECT '写字楼'
    UNION ALL SELECT '地下室/车库'
    UNION ALL SELECT '其他'    
) yt ON 1=1
WHERE 是否选择单项目 = 1

--获取定位价格
SELECT 
    CASE 
        WHEN YtName IN ('住宅', '高级住宅', '公寓', '商业', '写字楼', '地下室/车库') THEN YtName
        WHEN YtName = '别墅' THEN '高级住宅' 
        ELSE '其他' 
    END AS YtName,
    CASE 
        WHEN SUM(ISNULL(zksmj, 0)) = 0 THEN 0 
        ELSE SUM(ISNULL(zhz, 0)) * 1.0 / SUM(ISNULL(zksmj, 0)) 
    END AS 定位价
INTO #dw
FROM data_wide_dws_ys_SumOperatingProfitDataLXDWByYt T
INNER JOIN #p p ON p.projguid = t.projguid 
WHERE EditonType = '定位版' AND IsBase = 1 AND 是否选择单项目 = 1
GROUP BY 
    CASE 
        WHEN YtName IN ('住宅', '高级住宅', '公寓', '商业', '写字楼', '地下室/车库') THEN YtName
        WHEN YtName = '别墅' THEN '高级住宅' 
        ELSE '其他' 
    END
UNION ALL  
SELECT 
    '全口径' AS ytname,
    CASE 
        WHEN SUM(ISNULL(zksmj, 0)) = 0 THEN 0 
        ELSE SUM(ISNULL(totalsaleamount, 0)) * 1.0 / SUM(ISNULL(zksmj, 0)) 
    END AS 定位价
FROM data_wide_dws_ys_SumOperatingProfitDataLXDWBfYt t
INNER JOIN #p p ON p.projguid = t.projguid
WHERE EditonType = '定位版' AND IsBase = 1 AND 是否选择单项目 = 1


--汇总结果
SELECT 
    t.*,
    CASE 
        WHEN t.本年签约完成率 >= t.本年时间分摊比 THEN '量：已达时间进度' 
        ELSE '!量：未达时间进度' 
    END 本年签约金额预警, 
    CASE 
        WHEN t.本月签约完成率 >= t.本月时间分摊比 THEN '量：已达时间进度' 
        ELSE '!量：未达时间进度' 
    END 本月签约金额预警, 
    CASE 
        WHEN 去年签约价格同比 = 0 THEN '价：同比去年不变' 
        ELSE 
            CASE 
                WHEN 本年签约价格 > 去年签约价格 THEN '↑价：同比去年提升' 
                ELSE '↓价：同比去年下降' 
            END + CONVERT(VARCHAR(10), CONVERT(DECIMAL(16, 2), ABS(去年签约价格同比) * 100)) + '%' 
    END 本年签约价格预警, 
    CASE 
        WHEN 上月签约价格环比 = 0 THEN '价：环比上月不变' 
        ELSE 
            CASE 
                WHEN 本月签约价格 > 上月签约价格 THEN '↑价：环比上月提升' 
                ELSE '↓价：环比上月下降' 
            END + CONVERT(VARCHAR(10), CONVERT(DECIMAL(16, 2), ABS(上月签约价格环比) * 100)) + '%' 
    END 本月签约价格预警
FROM (
    SELECT 
        hz.业态, 
        s.本年签约金额,
        s.本月签约金额,
        s.去年签约价格,
        s.本年签约价格,
        s.上月签约价格,
        s.本月签约价格,
        s.近一月价格,
        s.近三月价格,
        hz.整盘去化均价,
        hz.已推未售去化均价,
        ypyc.一盘一策价,
        ypyc.盈亏平衡价,
        ypyc.负百分之三十价格线,
        dw.定位价,
        DATEDIFF(DAY, DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0), GETDATE()) * 1.00 / 365 本年时间分摊比,
        DATEDIFF(DAY, DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0), GETDATE()) * 1.00 / 30 AS 本月时间分摊比,
        CASE 
            WHEN 去年签约价格 = 0 THEN 0 
            ELSE (本年签约价格 - 去年签约价格) / 去年签约价格 
        END 去年签约价格同比,
        CASE 
            WHEN 上月签约价格 = 0 THEN 0 
            ELSE (本月签约价格 - 上月签约价格) / 上月签约价格 
        END 上月签约价格环比,
        CASE 
            WHEN 本年签约任务 = 0 THEN 0 
            ELSE 本年签约金额 / 本年签约任务 
        END AS 本年签约完成率,
        CASE 
            WHEN 本月签约任务 = 0 THEN 0 
            ELSE 本月签约金额 / 本月签约任务 
        END AS 本月签约完成率
    FROM 
        #hz hz 
        LEFT JOIN #sale s ON hz.业态 = s.业态
        LEFT JOIN #ypyc ypyc ON ypyc.ytname = hz.业态
        LEFT JOIN #dw dw ON dw.YtName = hz.业态
        LEFT JOIN #rw rw ON rw.业态 = hz.业态
) t

drop table #hz,#p,#sale,#ypyc,#dw,#hz1,#rw,#sale1