-- 声明变量
declare @buguid varchar(max) = '4A1E877C-A0B2-476D-9F19-B5C426173C38'  -- 公司GUID
declare @dev varchar(max) = '5A4B2DEF-E803-49F8-9FE2-308735E7233D'     -- 开发公司GUID

-- 1. 取加成签约情况
select
    -- 本月加成签约数据
    convert(decimal(16,2), sum(isnull(本月加成签约金额,0))/10000.0) 本月金额,
    convert(decimal(16,2), sum(case when 产品类型 in ('公寓','商业','办公楼') then isnull(本月加成签约金额,0) else 0 end)/10000.0) 公商办加成签约金额,
    convert(decimal(16,2), sum(case when 产品类型 = '地下室/车库' then isnull(本月加成签约金额,0) else 0 end)/10000.0) 车位加成签约金额,
    convert(decimal(16,2), sum(isnull(本月签约金额,0))/10000.0) 签约金额
into #jcqy
from s_jcyj 
where datediff(dd,qxdate,getdate()) = 0
    and 平台公司 = '湖南公司'

-- 2. 取回笼数据
SELECT 
    convert(decimal(16,2), (本年实际回笼全口径)/10000.0) as 本年回笼金额,
    convert(decimal(16,2), (
        CASE 
            WHEN MONTH(GETDATE()) = 1 THEN 本年实际回笼全口径 
            ELSE 本年实际回笼全口径 - 上个月本年实际回笼全口径 
        END
    )/10000.0) as 本月回笼金额,
    convert(decimal(16,2), (昨天本年实际回笼全口径 - 前天本年实际回笼全口径)/10000.0) as 本日回笼金额  
into #hl
FROM (
    SELECT
        -- 本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) + ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
        END) AS 本年实际回笼全口径,
        
        -- 昨天本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, GETDATE() - 1) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) + ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
        END) AS 昨天本年实际回笼全口径,
        
        -- 前天本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, GETDATE() - 2) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) + ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
        END) AS 前天本年实际回笼全口径,
        
        -- 上个月本年实际回笼全口径
        SUM(CASE 
            WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + 
                ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + 
                ISNULL(hl.本年特殊业绩关联房间, 0) + ISNULL(hl.本年特殊业绩未关联房间, 0)
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

-- 3. 取销净率
select
    convert(decimal(16,2),
        CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                SUM(本月净利润签约) / SUM(本月签约金额不含税) * 100
            ELSE 0
        END
    ) 本月净利润率
into #lv
FROM s_M002项目级毛利净利汇总表New a
WHERE DATEDIFF(DAY, qxdate, GETDATE()) = 0
    AND a.OrgGuid = @dev
            
-- 4. 获取签约任务
SELECT 
    convert(decimal(16,2),
        sum(
            isnull(a.[住宅-签约加成任务（亿元）],0) + 
            isnull(a.[商铺-签约加成任务（亿元）],0) + 
            isnull(a.[公寓-签约加成任务（亿元）],0) + 
            isnull(a.[写字楼-签约加成任务（亿元）],0) + 
            isnull(a.[车位-签约加成任务（亿元）],0)
        )
    ) qyrw 
INTO #rw
FROM dss.dbo.[nmap_F_平台公司项目层级月度任务填报] a
INNER JOIN dss.dbo.nmap_F_FillHistory f 
    ON f.FillHistoryGUID = a.FillHistoryGUID 
INNER JOIN erp25.dbo.mdm_Project p 
    ON p.ProjGUID = a.BusinessGUID
WHERE DATEDIFF(MONTH, f.BeginDate, GETDATE()) = 0 
    and p.DevelopmentCompanyGUID = @dev

-- 5. 计算签约任务完成率
SELECT 
    CASE 
        WHEN r.qyrw = 0 THEN 0  
        ELSE j.本月金额 / r.qyrw
    END 签约任务完成率
into #rwwcl
FROM #rw r, #jcqy j

-- 6. 最终输出
select 
    t.header + '<br>' +
    '1、本月任务：加成签约（净利率>0，公商x2，车x4，办x8）' + 
    convert(varchar,isnull(本月金额,0)) + '亿，（其中公商办' + 
    convert(varchar,isnull(公商办加成签约金额,0)) + '亿，车位' + 
    convert(varchar,isnull(车位加成签约金额,0)) + '亿），回笼' + 
    convert(varchar,isnull(本月回笼金额,0)) + '亿，销净率' + 
    convert(varchar,isnull(本月净利润率,0)) + '%，加成签约任务完成率' + 
    convert(varchar,convert(decimal(5,1),isnull(签约任务完成率,0)*100)) + '%'
as 其他情况
from (select '三、其他情况' as header) t 
left join #jcqy on 1=1
left join #hl on 1=1
left join #lv on 1=1
left join #rw on 1=1
left join #rwwcl on 1=1

-- 清理临时表
drop table #jcqy, #hl, #lv, #rw, #rwwcl
