declare @ThisDate datetime =getdate() --'2025-07-31' -- 今天

declare @buguid varchar(max) = '4A1E877C-A0B2-476D-9F19-B5C426173C38'
declare @dev varchar(max) = '5A4B2DEF-E803-49F8-9FE2-308735E7233D'

--获取本月1号是第几周
declare @month_1 varchar(10) = convert(varchar(7),@ThisDate,121)+'-01' --本月1号
declare @week_1 int = DATEPART(WEEK, @month_1) --本月1号是当前的第几周
--如果1号是在周一的话，那么本周就算在本月，否则算在上月
declare @week_name varchar(1)  =  DATEPART(WEEK, @ThisDate)-@week_1 + case when DATEPART(dw,@week_1) = 2 then 1 else  0 end

--获取周一的时间
declare @lastw varchar(10) = convert(varchar(10),DATEADD(WEEK, DATEDIFF(WEEK, 0, CONVERT(DATETIME, @ThisDate, 120) - 1), 0),121) 
declare @lastw_m varchar(2) = convert(varchar(2),month(@lastw)) -- 上周月份
declare @lastw_r varchar(2) = convert(varchar(2),DAY(@lastw));  -- 上周日期

--获取周日的时间
declare @w1 varchar(10) = convert(varchar(10),DATEADD(DAY, 6, DATEADD(WEEK, DATEDIFF(WEEK, 0, CONVERT(DATETIME, @ThisDate, 120) - 1), 0)),121)
declare @by varchar(2) = convert(varchar(2),month(@w1))
declare @br varchar(2) = convert(varchar(2),DAY(@w1));

 -- 如果周日=本月最后一天则等于周日，否则等于本月最后一天
declare @ThisMonthLastDay datetime = case when datediff(month, dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@lastw)+1, 0)), @w1) = 0 then   @w1 else 
     dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@lastw)+1, 0)) end 

Print @ThisMonthLastDay

CREATE TABLE #sale_bz( 
	[公司名称] [varchar](100) NULL,
	[BUGUID] [uniqueidentifier] NULL,
	[项目名称] [varchar](400) NULL,
	[投管项目名称] [varchar](500) NULL,
	[投管推广名] [varchar](500) NULL,
	[操盘方式] [varchar](200) NULL,
	[并表方式] [varchar](200) NULL,
	[项目权益比例] [money] NULL,
	[项目代码] [varchar](200) NULL,
	[产品类型] [varchar](400) NULL,
	[首推日期] [datetime] NULL,
	[获取时间] [datetime] NULL,
	[项目类型] [varchar](200) NULL,
	[本期认购套数] [int] NULL,
	[本期认购面积] [money] NULL,
	[本期认购金额] [money] NULL,
	[本期签约套数] [int] NULL,
	[本期签约面积] [money] NULL,
	[本期签约金额] [money] NULL,
	[本月认购套数] [int] NULL,
	[本年认购套数] [int] NULL,
	[累计认购套数] [int] NULL,
	[本月认购面价] [money] NULL,
	[本年认购面价] [money] NULL,
	[累计认购面价] [money] NULL,
	[本月认购金额] [money] NULL,
	[本年认购金额] [money] NULL,
	[累计认购金额] [money] NULL,
	[本月签约套数] [int] NULL,
	[本年签约套数] [int] NULL,
	[累计签约套数] [int] NULL,
	[本月签约面积] [money] NULL,
	[本年签约面积] [money] NULL,
	[累计签约面积] [money] NULL,
	[本月签约金额] [money] NULL,
	[本年签约金额] [money] NULL,
	[累计签约金额] [money] NULL,
	[本年签约权益面积] [money] NULL,
	[本年签约权益金额] [money] NULL,
	[本期认购均价] [money] NULL,
	[本月认购均价] [money] NULL,
	[本年认购均价] [money] NULL,
	[累计认购均价] [money] NULL,
	[本期签约均价] [money] NULL,
	[本月签约均价] [money] NULL,
	[本年签约均价] [money] NULL,
	[累计签约均价] [money] NULL,
	[投管代码] [varchar](200) NULL,
	[未签约套数] [money] NULL,
	[未签约面积] [money] NULL,
	[未签约金额] [money] NULL,
	[本日预认购套数] [money] NULL,
	[本日预认购面积] [money] NULL,
	[本日预认购金额] [money] NULL,
	[本月预认购套数] [money] NULL,
	[本月预认购面积] [money] NULL,
	[本月预认购金额] [money] NULL,
	[本年预认购套数] [money] NULL,
	[本年预认购面积] [money] NULL,
	[本年预认购金额] [money] NULL,
	[累计预认购套数] [money] NULL,
	[累计预认购面积] [money] NULL,
	[累计预认购金额] [money] NULL,
	[本日实际认购套数] [money] NULL,
	[本日实际认购面积] [money] NULL,
	[本日实际认购金额] [money] NULL,
	[本月实际认购套数] [money] NULL,
	[本月实际认购面积] [money] NULL,
	[本月实际认购金额] [money] NULL,
	[本年实际认购套数] [money] NULL,
	[本年实际认购面积] [money] NULL,
	[本年实际认购金额] [money] NULL,
	[累计实际认购套数] [money] NULL,
	[累计实际认购面积] [money] NULL,
	[累计实际认购金额] [money] NULL
)

--获取本周的签约认购数据
insert into #sale_bz  
exec [usp_S_08ZYXSQYJB_HHZTSYJ]   @buguid ,@lastw,@w1;

-- 取当天认购签约情况
WITH s_br AS (
   
    select  
    t1.buguid,
    t1.本年认购金额,
    t1.本年车位认购金额,
    t1.本年公商办认购金额,
    t1.本年签约金额,
    t1.本周认购金额,
    t1.本周车位认购金额,
    t1.本周签约金额,
    t2.本月认购金额,
    t2.本月车位认购金额,
    t2.本月公商办认购金额,
    t2.本月签约金额
    from  (
	       SELECT
            buguid,
        -- SUM(ISNULL(本月实际认购金额, 0)) / 10000.0 AS 本月认购金额,
        -- SUM(CASE WHEN 产品类型 = '地下室/车库' THEN ISNULL(本月实际认购金额, 0) ELSE 0 END) / 10000.0 AS 本月车位认购金额,
        --  SUM(CASE WHEN 产品类型 IN ('公寓', '商业', '办公楼') THEN ISNULL(本月实际认购金额, 0) ELSE 0 END) / 10000.0 AS 本月公商办认购金额,
            SUM(ISNULL(本年实际认购金额, 0)) / 10000.0 AS 本年认购金额,
            SUM(CASE WHEN 产品类型 = '地下室/车库' THEN ISNULL(本年认购金额, 0) ELSE 0 END) / 10000.0 AS 本年车位认购金额,
            SUM(CASE WHEN 产品类型 IN ('公寓', '商业', '办公楼') THEN ISNULL(本年认购金额, 0) ELSE 0 END) / 10000.0 AS 本年公商办认购金额,
        --SUM(ISNULL(本月签约金额, 0)) / 10000.0 AS 本月签约金额,
            SUM(ISNULL(本年签约金额, 0)) / 10000.0 AS 本年签约金额,
            SUM(ISNULL(本期认购金额, 0)) / 10000.0 AS 本周认购金额,
            SUM(CASE WHEN 产品类型 = '地下室/车库' THEN ISNULL(本期认购金额, 0) ELSE 0 END) / 10000.0 AS 本周车位认购金额,
            SUM(ISNULL(本期签约金额, 0)) / 10000.0 AS 本周签约金额
        FROM #sale_bz
        group by buguid 
    ) t1 
    left join  (
        select 
            buguid,
            SUM(ISNULL(本月认购金额, 0)) / 10000.0 AS 本月认购金额,
            SUM(CASE WHEN 产品类型 = '地下室/车库' THEN ISNULL(本月认购金额, 0) ELSE 0 END) / 10000.0 AS 本月车位认购金额,
            SUM(CASE WHEN 产品类型 IN ('公寓', '商业', '办公楼') THEN ISNULL(本月认购金额, 0) ELSE 0 END) / 10000.0 AS 本月公商办认购金额,
            -SUM(ISNULL(本月签约金额, 0)) / 10000.0 AS 本月签约金额
        from  S_08ZYXSQYJB_HHZTSYJ_daily where 公司名称 ='湖南公司'  
        and DATEDIFF(day,qxDate, @ThisMonthLastDay) =0
        group by buguid
    ) t2 on t1.buguid = t2.buguid
)
SELECT
    CONVERT(DECIMAL(16, 2), s.本月认购金额) AS 本月认购金额,
    CONVERT(DECIMAL(16, 2), s.本月车位认购金额) AS 本月车位认购金额,
    CONVERT(DECIMAL(16, 2), s.本月公商办认购金额) AS 本月公商办认购金额,
    CONVERT(DECIMAL(16, 2), s.本年认购金额) AS 本年认购金额,
    CONVERT(DECIMAL(16, 2), s.本年车位认购金额) AS 本年车位认购金额,
    CONVERT(DECIMAL(16, 2), s.本年公商办认购金额) AS 本年公商办认购金额,
    CONVERT(DECIMAL(16, 2), s.本月签约金额) AS 本月签约金额,
    CONVERT(DECIMAL(16, 2), s.本年签约金额) AS 本年签约金额,
    CONVERT(DECIMAL(16, 2), s.本周认购金额) AS 本周认购金额,
    CONVERT(DECIMAL(16, 2), s.本周车位认购金额) AS 本周车位认购金额,
    CONVERT(DECIMAL(16, 2), s.本周签约金额) AS 本周签约金额
INTO #qy
FROM s_br s

-- 取回笼
SELECT 
    CONVERT(DECIMAL(16, 2), (本年实际回笼全口径) / 10000.0) AS 本年回笼金额,
    CONVERT(DECIMAL(16, 2), (
        CASE 
            WHEN MONTH(@ThisDate) = 1 
                THEN 本年实际回笼全口径 
                ELSE 本年实际回笼全口径 - 上个月本年实际回笼全口径 
        END
    ) / 10000.0) AS 本月回笼金额,
    CONVERT(DECIMAL(16, 2), (本年实际回笼全口径 - 七天前本年实际回笼全口径) / 10000.0) AS 本周回笼金额
INTO #hl
FROM (
    SELECT
        SUM(
            CASE 
                WHEN DATEDIFF(dd, qxDate, @ThisDate) = 0 THEN
                    ISNULL(hl.应退未退本年金额, 0) 
                    + ISNULL(hl.本年回笼金额认购, 0) 
                    + ISNULL(hl.本年回笼金额签约, 0) 
                    + ISNULL(hl.关闭交易本年退款金额, 0) 
                    + ISNULL(hl.本年特殊业绩关联房间, 0)
                    + ISNULL(hl.本年特殊业绩未关联房间, 0)
                ELSE 0
            END
        ) AS 本年实际回笼全口径,
        SUM(
            CASE 
                WHEN DATEDIFF(dd, qxDate, @lastw) = 0 THEN
                    ISNULL(hl.应退未退本年金额, 0) 
                    + ISNULL(hl.本年回笼金额认购, 0) 
                    + ISNULL(hl.本年回笼金额签约, 0) 
                    + ISNULL(hl.关闭交易本年退款金额, 0) 
                    + ISNULL(hl.本年特殊业绩关联房间, 0)
                    + ISNULL(hl.本年特殊业绩未关联房间, 0)
                ELSE 0
            END
        ) AS 七天前本年实际回笼全口径,
        SUM(
            CASE 
                WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, @ThisMonthLastDay) - 1, -1)) = 0 THEN
                    ISNULL(hl.应退未退本年金额, 0) 
                    + ISNULL(hl.本年回笼金额认购, 0) 
                    + ISNULL(hl.本年回笼金额签约, 0) 
                    + ISNULL(hl.关闭交易本年退款金额, 0) 
                    + ISNULL(hl.本年特殊业绩关联房间, 0)
                    + ISNULL(hl.本年特殊业绩未关联房间, 0)
                ELSE 0
            END
        ) AS 上个月本年实际回笼全口径,
        SUM(
            CASE 
                WHEN DATEDIFF(dd, qxDate, @ThisMonthLastDay) = 0 THEN
                    ISNULL(hl.本年签约本年回笼非按揭回笼, 0) 
                    + ISNULL(本年签约本年回笼按揭回笼, 0)
                ELSE 0
            END
        ) AS 本年签约本年回笼
    FROM s_gsfkylbhzb hl
    WHERE hl.buguid = @buguid
) t;

-- 统计利润率
WITH jlv AS (
    SELECT 
        t1.平台公司,
        t1.本周签约金额不含税,
        t1.本年签约金额不含税,
        t1.本周净利润签约,
        t1.本年净利润签约,
        t2.本月签约金额不含税,
        t2.本月净利润签约
    FROM (
        SELECT 
            平台公司,
            SUM(CASE WHEN versionType = '本周版(周一开始)' THEN 当期签约金额不含税 ELSE 0 END) AS 本周签约金额不含税,
            -- SUM(CASE WHEN versionType = '本月版' THEN 当期签约金额不含税 ELSE 0 END) AS 本月签约金额不含税,
            SUM(CASE WHEN versionType = '本年版' THEN 当期签约金额不含税 ELSE 0 END) AS 本年签约金额不含税,
            SUM(CASE WHEN versionType = '本周版(周一开始)' THEN 净利润签约 ELSE 0 END) AS 本周净利润签约,
            -- SUM(CASE WHEN versionType = '本月版' THEN 净利润签约 ELSE 0 END) AS 本月净利润签约,
            SUM(CASE WHEN versionType = '本年版' THEN 净利润签约 ELSE 0 END) AS 本年净利润签约
        FROM s_M002业态净利毛利大底表 
        WHERE 平台公司 = '湖南公司'  
            AND versionType IN ('本周版(周一开始)', '本年版', '本月版')
        GROUP BY 平台公司 
    ) t1
    LEFT JOIN (
        SELECT 
            平台公司,
            SUM(本月签约金额不含税) AS 本月签约金额不含税,
            SUM(本月净利润签约) AS 本月净利润签约
        FROM [dbo].[s_M002业态级净利汇总表_数仓用] 
        WHERE DATEDIFF(day, qxdate, @ThisMonthLastDay) = 0 
            AND 平台公司 = '湖南公司'
        GROUP BY 平台公司
    ) t2 ON t1.平台公司 = t2.平台公司
)
-- 计算净利率
SELECT 
    CONVERT(decimal(16,2), 
        CASE 
            WHEN SUM(本周签约金额不含税) > 0 THEN 
                SUM(本周净利润签约) / SUM(本周签约金额不含税) 
            ELSE 0 
        END * 100
    ) AS 本周净利润率,
    CONVERT(decimal(16,2), 
        CASE 
            WHEN SUM(本月签约金额不含税) > 0 THEN 
                SUM(本月净利润签约) / SUM(本月签约金额不含税) 
            ELSE 0 
        END * 100
    ) AS 本月净利润率,
    CONVERT(decimal(16,2), 
        CASE 
            WHEN SUM(本年签约金额不含税) > 0 THEN 
                SUM(本年净利润签约) / SUM(本年签约金额不含税) 
            ELSE 0 
        END * 100
    ) AS 本年净利润率
INTO #lv
FROM jlv


-- 汇总情况
SELECT 
    t.header + '<br>' +
    '一、本周经营情况' + '<br>' +

    '【认购】本周' + CONVERT(varchar, ISNULL(本周认购金额, 0)) + '亿，其中车位' + CONVERT(varchar, ISNULL(本周车位认购金额, 0)) + '亿；月' +
    CONVERT(varchar, ISNULL(本月认购金额, 0)) + '亿，其中车位' + CONVERT(varchar, ISNULL(本月车位认购金额, 0)) + '亿，公商办' + CONVERT(varchar, ISNULL(本月公商办认购金额, 0)) +
    '亿；年' + CONVERT(varchar, ISNULL(本年认购金额, 0)) + '亿，其中车位' + CONVERT(varchar, ISNULL(本年车位认购金额, 0)) + '亿，公商办' + CONVERT(varchar, ISNULL(本年公商办认购金额, 0)) + '亿；' + '<br>' +

    '【签约】本周' + CONVERT(varchar, ISNULL(本周签约金额, 0)) + '亿，月' + CONVERT(varchar, ISNULL(本月签约金额, 0)) + '亿，年' + CONVERT(varchar, ISNULL(本年签约金额, 0)) + '亿；' + '<br>' +
    '【回笼】本周' + CONVERT(varchar, ISNULL(本周回笼金额, 0)) + '亿，月' + CONVERT(varchar, ISNULL(本月回笼金额, 0)) + '亿，年' + CONVERT(varchar, ISNULL(本年回笼金额, 0)) + '亿；' + '<br>' +
    '【销净率】本周' + CONVERT(varchar, ISNULL(本周净利润率, 0)) + '%，月' + CONVERT(varchar, ISNULL(本月净利润率, 0)) + '%，年' + CONVERT(varchar, ISNULL(本年净利润率, 0)) + '%。' 
    AS 经营任务情况
FROM (
    SELECT 
        '各位领导，以下为湖南公司' + @lastw_m + '月第' + @week_name + '周（' + @lastw_m + '.' + @lastw_r + '-' + @by + '.' + @br + '）经营简报，烦请查阅：' 
        AS header
) t
LEFT JOIN #qy ON 1 = 1
LEFT JOIN #hl ON 1 = 1
LEFT JOIN #lv ON 1 = 1

-- 删除临时表
DROP TABLE #qy, #hl, #lv, #sale_bz


/*
declare @buguid varchar(max) = '4A1E877C-A0B2-476D-9F19-B5C426173C38'
declare @dev varchar(max) = '5A4B2DEF-E803-49F8-9FE2-308735E7233D'

--获取本月1号是第几周
declare @month_1 varchar(10) = convert(varchar(7),GETDATE(),121)+'-01' --本月1号
declare @week_1 int = DATEPART(WEEK, @month_1) --本月1号是当前的第几周
--如果1号是在周一的话，那么本周就算在本月，否则算在上月
declare @week_name varchar(1)  =  DATEPART(WEEK, getdate())-@week_1+ case when DATEPART(dw,@week_1) = 2 then 1 else  0 end

--获取周一的时间
declare @lastw varchar(10) = convert(varchar(10),DATEADD(WEEK, DATEDIFF(WEEK, 0, CONVERT(DATETIME, getdate(), 120) - 1), 0),121) 
declare @lastw_m varchar(2) = convert(varchar(2),month(@lastw))
declare @lastw_r varchar(2) = convert(varchar(2),DAY(@lastw));

--获取周日的时间
declare @w1 varchar(10) = convert(varchar(10),DATEADD(DAY, 6, DATEADD(WEEK, DATEDIFF(WEEK, 0, CONVERT(DATETIME, getdate(), 120) - 1), 0)),121)
declare @by varchar(2) = convert(varchar(2),month(@w1))
declare @br varchar(2) = convert(varchar(2),DAY(@w1));


CREATE TABLE #sale_bz( 
	[公司名称] [varchar](100) NULL,
	[BUGUID] [uniqueidentifier] NULL,
	[项目名称] [varchar](400) NULL,
	[投管项目名称] [varchar](500) NULL,
	[投管推广名] [varchar](500) NULL,
	[操盘方式] [varchar](200) NULL,
	[并表方式] [varchar](200) NULL,
	[项目权益比例] [money] NULL,
	[项目代码] [varchar](200) NULL,
	[产品类型] [varchar](400) NULL,
	[首推日期] [datetime] NULL,
	[获取时间] [datetime] NULL,
	[项目类型] [varchar](200) NULL,
	[本期认购套数] [int] NULL,
	[本期认购面积] [money] NULL,
	[本期认购金额] [money] NULL,
	[本期签约套数] [int] NULL,
	[本期签约面积] [money] NULL,
	[本期签约金额] [money] NULL,
	[本月认购套数] [int] NULL,
	[本年认购套数] [int] NULL,
	[累计认购套数] [int] NULL,
	[本月认购面价] [money] NULL,
	[本年认购面价] [money] NULL,
	[累计认购面价] [money] NULL,
	[本月认购金额] [money] NULL,
	[本年认购金额] [money] NULL,
	[累计认购金额] [money] NULL,
	[本月签约套数] [int] NULL,
	[本年签约套数] [int] NULL,
	[累计签约套数] [int] NULL,
	[本月签约面积] [money] NULL,
	[本年签约面积] [money] NULL,
	[累计签约面积] [money] NULL,
	[本月签约金额] [money] NULL,
	[本年签约金额] [money] NULL,
	[累计签约金额] [money] NULL,
	[本年签约权益面积] [money] NULL,
	[本年签约权益金额] [money] NULL,
	[本期认购均价] [money] NULL,
	[本月认购均价] [money] NULL,
	[本年认购均价] [money] NULL,
	[累计认购均价] [money] NULL,
	[本期签约均价] [money] NULL,
	[本月签约均价] [money] NULL,
	[本年签约均价] [money] NULL,
	[累计签约均价] [money] NULL,
	[投管代码] [varchar](200) NULL,
	[未签约套数] [money] NULL,
	[未签约面积] [money] NULL,
	[未签约金额] [money] NULL,
	[本日预认购套数] [money] NULL,
	[本日预认购面积] [money] NULL,
	[本日预认购金额] [money] NULL,
	[本月预认购套数] [money] NULL,
	[本月预认购面积] [money] NULL,
	[本月预认购金额] [money] NULL,
	[本年预认购套数] [money] NULL,
	[本年预认购面积] [money] NULL,
	[本年预认购金额] [money] NULL,
	[累计预认购套数] [money] NULL,
	[累计预认购面积] [money] NULL,
	[累计预认购金额] [money] NULL,
	[本日实际认购套数] [money] NULL,
	[本日实际认购面积] [money] NULL,
	[本日实际认购金额] [money] NULL,
	[本月实际认购套数] [money] NULL,
	[本月实际认购面积] [money] NULL,
	[本月实际认购金额] [money] NULL,
	[本年实际认购套数] [money] NULL,
	[本年实际认购面积] [money] NULL,
	[本年实际认购金额] [money] NULL,
	[累计实际认购套数] [money] NULL,
	[累计实际认购面积] [money] NULL,
	[累计实际认购金额] [money] NULL
)

--获取本周的签约认购数据
insert into #sale_bz  
exec [usp_S_08ZYXSQYJB_HHZTSYJ]   @buguid ,@lastw,@w1;

--取当天认购签约情况
with s_br as (select 
sum(isnull(本月实际认购金额,0))/10000.0 本月认购金额,
sum(case when 产品类型 = '地下室/车库' then isnull(本月实际认购金额,0) else 0 end)/10000.0 本月车位认购金额,
sum(case when 产品类型 in ('公寓','商业','办公楼') then isnull(本月实际认购金额,0) else 0 end)/10000.0 本月公商办认购金额,
sum(isnull(本年实际认购金额,0))/10000.0 本年认购金额,
sum(case when 产品类型 = '地下室/车库' then isnull(本年认购金额,0) else 0 end)/10000.0 本年车位认购金额,
sum(case when 产品类型 in ('公寓','商业','办公楼') then isnull(本年认购金额,0) else 0 end)/10000.0 本年公商办认购金额,
sum(isnull(本月签约金额,0))/10000.0 本月签约金额, 
sum(isnull(本年签约金额,0))/10000.0 本年签约金额,
sum(isnull(本期认购金额,0))/10000.0 本周认购金额,
sum(case when 产品类型 = '地下室/车库' then isnull(本期认购金额,0) else 0 end)/10000.0 本周车位认购金额,
sum(isnull(本期签约金额,0))/10000.0 本周签约金额 
from #sale_bz   ) 
select 
convert(decimal(16,2),s.本月认购金额) as 本月认购金额,
convert(decimal(16,2),s.本月车位认购金额) as 本月车位认购金额,
convert(decimal(16,2),s.本月公商办认购金额) as 本月公商办认购金额,
convert(decimal(16,2),s.本年认购金额) as 本年认购金额,
convert(decimal(16,2),s.本年车位认购金额) as 本年车位认购金额,
convert(decimal(16,2),s.本年公商办认购金额) as 本年公商办认购金额,
convert(decimal(16,2),s.本月签约金额) as 本月签约金额,
convert(decimal(16,2),s.本年签约金额) as 本年签约金额,
convert(decimal(16,2),s.本周认购金额) 本周认购金额,
convert(decimal(16,2),s.本周车位认购金额) 本周车位认购金额,
convert(decimal(16,2),s.本周签约金额) 本周签约金额
into #qy
from s_br s 

--取回笼
SELECT convert(decimal(16,2),(本年实际回笼全口径)/10000.0) as 本年回笼金额 ,
convert(decimal(16,2),(CASE WHEN MONTH(GETDATE()) = 1 THEN 本年实际回笼全口径 ELSE 本年实际回笼全口径 - 上个月本年实际回笼全口径 END)/10000.0) as 本月回笼金额 ,
convert(decimal(16,2),(本年实际回笼全口径 - 七天前本年实际回笼全口径)/10000.0) as 本周回笼金额  
into #hl
FROM (SELECT
SUM( CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN
         ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
         + ISNULL(hl.本年特殊业绩未关联房间, 0)
     ELSE 0
END) AS 本年实际回笼全口径 ,
SUM(
CASE WHEN DATEDIFF(dd,qxDate,@lastw) = 0 THEN
        ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
         + ISNULL(hl.本年特殊业绩未关联房间, 0)
     ELSE 0
END) AS 七天前本年实际回笼全口径 , 
SUM(
CASE WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0 THEN
         ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
         + ISNULL(hl.本年特殊业绩未关联房间, 0)
     ELSE 0
END) AS 上个月本年实际回笼全口径 ,
SUM(CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN ISNULL(hl.本年签约本年回笼非按揭回笼, 0) + ISNULL(本年签约本年回笼按揭回笼, 0)ELSE 0 END) AS 本年签约本年回笼
FROM   s_gsfkylbhzb hl
WHERE  hl.buguid = @buguid  ) t ; 

with jlv as (
select 
sum(case when versionType = '本周版(周一开始)' then 当期签约金额不含税 else 0 end) as 本周签约金额不含税,
sum(case when versionType = '本月版' then 当期签约金额不含税 else 0 end) as 本月签约金额不含税,
sum(case when versionType = '本年版' then 当期签约金额不含税 else 0 end) as 本年签约金额不含税,
sum(case when versionType = '本周版(周一开始)' then 净利润签约 else 0 end) as 本周净利润签约,
sum(case when versionType = '本月版' then 净利润签约 else 0 end) as 本月净利润签约,
sum(case when versionType = '本年版' then 净利润签约 else 0 end) as 本年净利润签约
from s_M002业态净利毛利大底表 
where  平台公司 = '湖南公司' 
and versionType in ('本周版(周一开始)','本年版','本月版')
)
select convert(decimal(16,2),CASE
           WHEN SUM(本周签约金额不含税) > 0 THEN
                SUM(本周净利润签约) / SUM(本周签约金额不含税)
           ELSE 0
       END*100)  本周净利润率,
convert(decimal(16,2),CASE
           WHEN SUM(本月签约金额不含税) > 0 THEN
                SUM(本月净利润签约) / SUM(本月签约金额不含税)
           ELSE 0
       END*100)  本月净利润率,
       convert(decimal(16,2),CASE
           WHEN SUM(本年签约金额不含税) > 0 THEN
                SUM(本年净利润签约) / SUM(本年签约金额不含税)
           ELSE 0
       END*100) 本年净利润率
into #lv
from jlv

--汇总情况
select t.header+'<br>'+
'一、本周经营情况'+'<br>'+

'【认购】本周'+convert(varchar,isnull(本周认购金额,0))+'亿，其中车位'+convert(varchar,isnull(本周车位认购金额,0))+'亿；月'
+convert(varchar,isnull(本月认购金额,0))+'亿，其中车位'+convert(varchar,isnull(本月车位认购金额,0))+'亿，公商办'+convert(varchar,isnull(本月公商办认购金额,0))
+'亿；年'+convert(varchar,isnull(本年认购金额,0))+'亿，其中车位'+convert(varchar,isnull(本年车位认购金额,0))+'亿，公商办'+convert(varchar,isnull(本年公商办认购金额,0))+'亿；'+'<br>'+

'【签约】本周'+convert(varchar,isnull(本周签约金额,0))+'亿，月'+convert(varchar,isnull(本月签约金额,0))+'亿，年'+convert(varchar,isnull(本年签约金额,0))+'亿；'+'<br>'+
'【回笼】本周'+convert(varchar,isnull(本周回笼金额,0))+'亿，月'+convert(varchar,isnull(本月回笼金额,0))+'亿，年'+convert(varchar,isnull(本年回笼金额,0))+'亿；'+'<br>'+
'【销净率】本周'+convert(varchar,isnull(本周净利润率,0))+'%，月'+convert(varchar,isnull(本月净利润率,0))+'%，年'+convert(varchar,isnull(本年净利润率,0))+'%。' as 经营任务情况
from (select '各位领导，以下为湖南公司'+@by+'月第'+@week_name+'周（'+@lastw_m+'.'+@lastw_r+'-'+@by+'.'+@br+'）经营简报，烦请查阅：' as header ) t 
left join #qy on 1=1
left join #hl on 1=1 
left join #lv on 1=1

drop table #qy, #hl, #lv,#sale_bz
*/