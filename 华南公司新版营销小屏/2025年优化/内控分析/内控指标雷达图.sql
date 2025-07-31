/*
内控指标实际得分公式：
特批、更名、延期、退房：100-比例*1000
换房：比例大于10%，0
机打认购数：小于90%，0；大于90%：比例*1000-900


*/
--获取前台变量，按照区域、项目、组团来进行统计
SELECT 
    pj.projguid,
    pj.spreadname
INTO #p
FROM data_wide_dws_mdm_project pj 
INNER JOIN data_tb_hn_yxpq t 
    ON pj.projguid = t.项目Guid 
    AND 营销片区 NOT IN ('一级整理及其他','合作项目')
WHERE 
    ((${var_biz} IN ('全部区域','全部项目','全部组团')) --若前台选择"全部区域"、"全部项目"、"全部组团"，则按照公司来统计
    OR (${var_biz} = t.营销事业部) --前台选择了具体某个区域
    OR (${var_biz} = t.营销片区) --前台选择了具体某个组团
    OR (${var_biz} = pj.spreadname)) --前台选择了具体某个项目
    --按照每个人的项目权限再进行过滤
    AND pj.projguid IN ${proj}

--统计换房的数据

SELECT '换房' 指标名称,
CASE WHEN SUM(本年认购套数) = 0 THEN 0 ELSE SUM(本年换房套数) * 1.0 / SUM(本年认购套数) END 本年比例,
CASE WHEN SUM(本月认购套数) = 0 THEN 0 ELSE SUM(本月换房套数) * 1.0 / SUM(本月认购套数) END 本月比例
INTO #nk_01
FROM dbo.s_hnyxkb_nkongStatistic t 
inner join #p p on t.项目guid = p.projguid
where DATEDIFF(dd,qxdate,GETDATE())=0
UNION ALL
SELECT '更名' 指标名称,
CASE WHEN SUM(本年认购套数) = 0 THEN 0 ELSE SUM(本年更名套数) * 1.0 / SUM(本年认购套数) END 本年比例,
CASE WHEN SUM(本月认购套数) = 0 THEN 0 ELSE SUM(本月更名套数) * 1.0 / SUM(本月认购套数) END 本月比例
FROM dbo.s_hnyxkb_nkongStatistic t 
inner join #p p on t.项目guid = p.projguid
where  DATEDIFF(dd,qxdate,GETDATE())=0 
UNION ALL
SELECT '延期签约' 指标名称,
CASE WHEN SUM(本年认购套数) = 0 THEN 0 ELSE SUM(本年延期套数) * 1.0 / SUM(本年认购套数) END 本年比例,
CASE WHEN SUM(本月认购套数) = 0 THEN 0 ELSE SUM(本月延期套数) * 1.0 / SUM(本月认购套数) END 本月比例
FROM dbo.s_hnyxkb_nkongStatistic t 
inner join #p p on t.项目guid = p.projguid
where  DATEDIFF(dd,qxdate,GETDATE())=0 
UNION ALL
SELECT '跨年退换房' 指标名称,
CASE WHEN SUM(本年认购套数) = 0 THEN 0 ELSE SUM(本年退房套数) * 1.0 / SUM(本年认购套数) END 本年比例,
CASE WHEN SUM(本月认购套数) = 0 THEN 0 ELSE SUM(本月退房套数) * 1.0 / SUM(本月认购套数) END 本月比例
FROM dbo.s_hnyxkb_nkongStatistic t 
inner join #p p on t.项目guid = p.projguid
where  DATEDIFF(dd,qxdate,GETDATE())=0 
union ALL
SELECT '退房率' 指标名称,
CASE WHEN SUM(总签约套数) = 0 THEN 0 ELSE SUM(签约后退房套数) * 1.0 / SUM(总签约套数) END 本年比例,
CASE WHEN SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总签约套数 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 签约后退房套数 ELSE 0 END) * 1.0 / SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总签约套数 ELSE 0 END) END 本月比例
FROM dbo.data_wide_dws_s_nkfx t 
inner join #p p on t.推广名 = p.spreadname
where 年份 = year(getdate()) 
union ALL
SELECT '逾期录入' 指标名称,
CASE WHEN SUM(总认购套数) = 0 THEN 0 ELSE SUM(逾期录入套数) * 1.0 / SUM(总认购套数) END 本年比例,
CASE WHEN SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总认购套数 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 逾期录入套数 ELSE 0 END) * 1.0 / SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总认购套数 ELSE 0 END) END 本月比例
FROM dbo.data_wide_dws_s_nkfx t 
inner join #p p on t.推广名 = p.spreadname
where 年份 = year(getdate()) 
union ALL
SELECT '逾期签约' 指标名称,
CASE WHEN SUM(总认购套数) = 0 THEN 0 ELSE SUM(逾期签约套数) * 1.0 / SUM(总认购套数) END 本年比例,
CASE WHEN SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总认购套数 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 逾期签约套数 ELSE 0 END) * 1.0 / SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总认购套数 ELSE 0 END) END 本月比例
FROM dbo.data_wide_dws_s_nkfx t 
inner join #p p on t.推广名 = p.spreadname
where 年份 = year(getdate()) 
union ALL
SELECT '线上认购' 指标名称,
CASE WHEN SUM(总认购套数) = 0 THEN 0 ELSE SUM(线上认购套数) * 1.0 / SUM(总认购套数) END 本年比例,
CASE WHEN SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总认购套数 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 线上认购套数 ELSE 0 END) * 1.0 / SUM(CASE WHEN 月份 = MONTH(GETDATE()) THEN 总认购套数 ELSE 0 END) END 本月比例
FROM dbo.data_wide_dws_s_nkfx t 
inner join #p p on t.推广名 = p.spreadname
where 年份 = year(getdate()) 


-- 得分计算：
-- 退房率：（10%-比例）*1000
-- 逾期签约：（20%-比例）*1000/2
-- 逾期录入：（20%-比例）*1000/2
-- 换房：（10%-比例）*1000
-- 跨年退换房：（100%-比例）*100
-- 延期签约：（10%-比例）*1000
-- 更名：（10%-比例）*1000
-- 线上认购：比例*100


SELECT 指标名称,
       本年比例,
       本月比例,
       CASE 
           WHEN 指标名称 IN ('退房率', '换房', '延期签约','更名') AND 本年比例 > 0.1 THEN 0 
           when 指标名称 in ('逾期签约','逾期录入') and 本年比例>0.2 then 0
           when 指标名称 in ('跨年退换房') and 本年比例>1 then 0

           WHEN 指标名称 IN ('退房率', '换房', '延期签约','更名') AND 本年比例 <= 0.1 THEN (0.1 - 本年比例) * 1000 
           when 指标名称 in ('逾期签约','逾期录入')  AND 本年比例 <= 0.2 THEN (0.2 - 本年比例) * 1000/2
           when 指标名称 in ('跨年退换房') and 本年比例 <= 1 THEN (1 - 本年比例) * 100 
           when 指标名称 in ('线上认购') THEN  本年比例 * 100
           ELSE 本年比例 * 100 - 90 
       END AS 本年实际得分,
       CASE 
           WHEN 指标名称 IN ('退房率', '换房', '延期签约','更名') AND 本月比例 > 0.1 THEN 0 
           when 指标名称 in ('逾期签约','逾期录入') and 本月比例>0.2 then 0
           when 指标名称 in ('跨年退换房') and 本月比例>1 then 0
           WHEN 指标名称 IN ('退房率', '换房', '延期签约','更名') AND 本月比例 <= 0.1 THEN (0.1 - 本月比例) * 1000 
           when 指标名称 in ('逾期签约','逾期录入')  AND 本月比例 <= 0.2 THEN (0.2 - 本月比例) * 1000/2
           when 指标名称 in ('跨年退换房') and 本月比例 <= 1 THEN (1 - 本月比例) * 100 
           when 指标名称 in ('线上认购') THEN  本月比例 * 100
        ELSE 本月比例 * 100 - 90 
       END AS 本月实际得分
FROM #nk_01 

DROP TABLE #nk_01,#p;


退房率：满分0%,0分10%
逾期签约：满分0%,0分20%
逾期录入：满分0%,0分20%
换房：满分0%,0分10%
跨年退换房：满分0%,0分100%
延期签约：满分0%,0分10%
更名：满分0%,0分10%
线上认购：满分100%,0分0%

得分计算：
退房率：（10%-比例）*1000
逾期签约：（20%-比例）*1000/2
逾期录入：（20%-比例）*1000/2
换房：（10%-比例）*1000
跨年退换房：（100%-比例）*100
延期签约：（10%-比例）*1000
更名：（10%-比例）*1000
线上认购：比例*100