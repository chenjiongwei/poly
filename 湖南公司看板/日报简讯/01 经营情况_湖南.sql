-- 声明变量
declare @buguid varchar(max) = '4A1E877C-A0B2-476D-9F19-B5C426173C38'  -- 公司GUID
declare @dev varchar(max) = '5A4B2DEF-E803-49F8-9FE2-308735E7233D'     -- 开发公司GUID

-- 1. 取认购签约情况
select  
    -- 本日认购数据
    convert(decimal(16,2), sum(isnull(本日实际认购金额,0))/10000.0) 本日认购金额,
    convert(decimal(16,2), sum(case when 产品类型 = '地下室/车库' then isnull(本日实际认购金额,0) else 0 end)) 本日车位认购金额,
    convert(decimal(16,2), sum(case when 产品类型 in ('公寓','商业','办公楼') then isnull(本日实际认购金额,0) else 0 end)) 本日公商办认购金额,
    
    -- 本月认购数据
    convert(decimal(16,2), sum(isnull(本月实际认购金额,0))/10000.0) 本月认购金额,
    convert(decimal(16,2), sum(case when 产品类型 = '地下室/车库' then isnull(本月实际认购金额,0) else 0 end)/10000.0) 本月车位认购金额,
    convert(decimal(16,2), sum(case when 产品类型 in ('公寓','商业','办公楼') then isnull(本月实际认购金额,0) else 0 end)/10000.0) 本月公商办认购金额,
    
    -- 本年认购数据
    convert(decimal(16,2), sum(isnull(本年实际认购金额,0))/10000.0) 本年认购金额,
    convert(decimal(16,2), sum(case when 产品类型 = '地下室/车库' then isnull(本年认购金额,0) else 0 end)/10000.0) 本年车位认购金额,
    convert(decimal(16,2), sum(case when 产品类型 in ('公寓','商业','办公楼') then isnull(本年认购金额,0) else 0 end)/10000.0) 本年公商办认购金额,
    
    -- 签约数据
    -- convert(decimal(16,2), sum(isnull(本日签约金额,0))/10000.0) 本日签约金额,  -- 已注释
    convert(decimal(16,2), sum(isnull(本月签约金额,0))/10000.0) 本月签约金额, 
    convert(decimal(16,2), sum(isnull(本年签约金额,0))/10000.0) 本年签约金额
into #qy
from S_08ZYXSQYJB_HHZTSYJ 
where datediff(dd,qxdate,getdate()) = 0
    and BUGUID = @buguid

-- 2. 取本日签约金额
select 
    convert(decimal(16,2), sum(isnull(c.JyTotal,0))/100000000.0) 本日签约金额 
into #brqy
from s_Contract c
left join dbo.s_Order so 
    on ISNULL(so.TradeGUID, '') = ISNULL(c.TradeGUID, '')
where datediff(dd,c.qsdate,getdate()) = 0
    and c.status = '激活'
    and (
        (so.Status = '关闭' AND so.CloseReason = '转签约')
        OR so.TradeGUID IS NULL
    )
    and c.BUGUID = @buguid

-- 3. 取回笼数据
SELECT 
    convert(decimal(16,2),(本年实际回笼全口径)/10000.0) as 本年回笼金额,
    convert(decimal(16,2),(
        CASE 
            WHEN MONTH(GETDATE()) = 1 THEN 本年实际回笼全口径 
            ELSE 本年实际回笼全口径 - 上个月本年实际回笼全口径 
        END
    )/10000.0) as 本月回笼金额,
    convert(decimal(16,2),(昨天本年实际回笼全口径 - 前天本年实际回笼全口径)/10000.0) as 本日回笼金额  
into #hl
FROM (
    SELECT
        -- 本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + 
                ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + 
                ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) +
                ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
        END) AS 本年实际回笼全口径,
        
        -- 昨天本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, GETDATE() - 1) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + 
                ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + 
                ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) +
                ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
        END) AS 昨天本年实际回笼全口径,
        
        -- 前天本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, GETDATE() - 2) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + 
                ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + 
                ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) +
                ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
        END) AS 前天本年实际回笼全口径,
        
        -- 上个月本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + 
                ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + 
                ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) +
                ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
        END) AS 上个月本年实际回笼全口径,
        
        -- 本年签约本年回笼
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN 
                ISNULL(hl.本年签约本年回笼非按揭回笼, 0) + ISNULL(本年签约本年回笼按揭回笼, 0)
            ELSE 0 
        END) AS 本年签约本年回笼
    FROM s_gsfkylbhzb hl
    WHERE hl.buguid = @buguid
) t 

-- 4. 取来访数据
select 
    sum(isnull(newVisitNum,0) + isnull(oldVisitNum,0)) as 本日来访情况,
    sum(case 
        when sk.ProjGUID is null then isnull(newVisitNum,0) + isnull(oldVisitNum,0) 
        else 0 
    end) as 本日续销项目来访情况
into #lf
from s_YHJVisitNum v 
inner join mdm_Project pj 
    on v.managementProjectGuid = pj.ProjGUID
-- 判断是否续销，只有当月开盘的项目，才算首开，其他情况都算是续销
left join (
    select 
        ProjGUID,
        min(isnull(SJkpxsDate,isnull(YJkpxsDate,'2099-12-31'))) as skdate 
    from p_lddb 
    where DATEDIFF(dd,qxdate,getdate()) = 0
        and DevelopmentCompanyGUID = @dev
    group by ProjGUID
) sk  on sk.ProjGUID = v.managementProjectGuid  and DATEDIFF(mm,sk.skdate,getdate()) = 0
where DATEDIFF(DAY, bizdate, getdate()) = 0 and DevelopmentCompanyGUID = @dev

-- 5. 取销净率
SELECT 
    -- 本日净利润率
    convert(decimal(16,2),
        CASE
            WHEN SUM(本日签约金额不含税) > 0 THEN
                SUM(本日净利润签约) / SUM(本日签约金额不含税) * 100
            ELSE 0
        END
    ) 本日净利润率,
    
    -- 本月净利润率
    convert(decimal(16,2),
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                SUM(本月净利润签约) / SUM(本月签约金额不含税) * 100
            ELSE 0
        END
    ) 本月净利润率,
    
    -- 本年净利润率
    convert(decimal(16,2),
        CASE
            WHEN SUM(本年签约金额不含税) > 0 THEN
                SUM(本年净利润签约) / SUM(本年签约金额不含税) * 100
            ELSE 0
        END
    ) 本年净利润率
into #lv
FROM s_M002项目级毛利净利汇总表New a
WHERE DATEDIFF(DAY, qxdate, GETDATE()) = 0 AND a.OrgGuid = @dev

-- 6. 汇总情况
select 
    t.header + '<br>' +
    '一、当日经营情况' + '<br>' +
    
    -- 认购情况
    '【认购】日' + convert(varchar,isnull(本日认购金额,0)) + '亿，其中车位' + 
    convert(varchar,isnull(本日车位认购金额,0)) + '万，公商办' + 
    convert(varchar,isnull(本日公商办认购金额,0)) + '万；月' + 
    convert(varchar,isnull(本月认购金额,0)) + '亿，其中车位' + 
    convert(varchar,isnull(本月车位认购金额,0)) + '亿，公商办' + 
    convert(varchar,isnull(本月公商办认购金额,0)) + '亿；年' + 
    convert(varchar,isnull(本年认购金额,0)) + '亿，其中车位' + 
    convert(varchar,isnull(本年车位认购金额,0)) + '亿，公商办' + 
    convert(varchar,isnull(本年公商办认购金额,0)) + '亿；' + '<br>' +
    
    -- 签约情况
    '【签约】日' + convert(varchar,isnull(本日签约金额,0)) + '亿，月' + 
    convert(varchar,isnull(本月签约金额,0)) + '亿，年' + 
    convert(varchar,isnull(本年签约金额,0)) + '亿；' + '<br>' +
    
    -- 回笼情况
    '【回笼】日' + convert(varchar,isnull(本日回笼金额,0)) + '亿，月' + 
    convert(varchar,isnull(本月回笼金额,0)) + '亿，年' + 
    convert(varchar,isnull(本年回笼金额,0)) + '亿；' + '<br>' +
    
    -- 销净率情况
    '【销净率】日' + convert(varchar,isnull(本日净利润率,0)) + '%，月' + 
    convert(varchar,isnull(本月净利润率,0)) + '%，年' + 
    convert(varchar,isnull(本年净利润率,0)) + '%；' + '<br>' +
    
    -- 来访情况
    '【来访】' + convert(varchar,isnull(本日来访情况,0)) + '批，其中续销项目来访' + 
    convert(varchar,isnull(本日续销项目来访情况,0)) + '批；' as 经营任务情况
from (
    select '【湖南公司经营日报简讯】（' + 
           convert(varchar(2),month(getdate())) + '月' + 
           convert(varchar(2),day(getdate())) + '日）：' as header 
) t 
left join #qy on 1=1
left join #brqy on 1=1
left join #hl on 1=1
left join #lf on 1=1
left join #lv on 1=1

-- 清理临时表
drop table #qy,#brqy,#hl,#lf,#lv
