/*
select 清洗时间,统计维度,公司,城市,片区,镇街,项目,外键关联,id,parentid,产品名称,户型,
    CASE WHEN (户型 is not null) THEN 户型 ELSE (case when (产品名称 is not null) then 产品名称 ELSE 业态 end) END as 业态 ,
    convert(varchar(20),convert(decimal(16,2),近三月流速)) as 近三月流速,
    convert(varchar(20),convert(decimal(16,2),当前存货面积)) as 当前存货面积,
    convert(varchar(20),convert(decimal(16,2),当前已开工未售面积))  as 当前已开工未售面积,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = 0 then 存销比 else 0 end))  ) as 动态1月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = 0 then 产销比 else 0 end)) ) as 动态1月产销比,  
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -1 then 存销比 else 0 end))) as 动态2月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -1 then 产销比 else 0 end))) as 动态2月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -2 then 存销比 else 0 end))) as 动态3月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -2 then 产销比 else 0 end))) as 动态3月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -3 then 存销比 else 0 end))) as 动态4月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -3 then 产销比 else 0 end))) as 动态4月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -4 then 存销比 else 0 end))) as 动态5月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -4 then 产销比 else 0 end))) as 动态5月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -5 then 存销比 else 0 end))) as 动态6月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -5 then 产销比 else 0 end))) as 动态6月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -6 then 存销比 else 0 end))) as 动态7月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -6 then 产销比 else 0 end))) as 动态7月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -7 then 存销比 else 0 end))) as 动态8月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -7 then 产销比 else 0 end))) as 动态8月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -8 then 存销比 else 0 end))) as 动态9月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -8 then 产销比 else 0 end))) as 动态9月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -9 then 存销比 else 0 end))) as 动态10月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -9 then 产销比 else 0 end))) as 动态10月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -10 then 存销比 else 0 end))) as 动态11月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -10 then 产销比 else 0 end))) as 动态11月产销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -11 then 存销比 else 0 end))) as 动态12月存销比,
    convert(varchar(20),convert(decimal(16,2),max(case when 月份差 = -11 then 产销比 else 0 end))) as 动态12月产销比 ,
    0 是否表头 --用于设置表头样式
into #t
from wqzydtBi_product_rest
where  (统计维度 = '项目' or (统计维度<>'项目' and 户型 is null)) --非项目层级不需要到户型
and  datediff(year,清洗时间,getdate()) =0
group by 清洗时间,统计维度,公司,城市,片区,镇街,项目,外键关联,id,parentid,产品名称,户型,业态 ,
convert(varchar(20),convert(decimal(16,2),近三月流速)),
convert(varchar(20),convert(decimal(16,2),当前存货面积)),
convert(varchar(20),convert(decimal(16,2),当前已开工未售面积)) 
union all 
select 清洗时间,统计维度,公司,城市,片区,镇街,项目,外键关联,null id,null parentid, 
    '产品名称','户型','业态' ,'近三月流速','当前存货面积','当前已开工未售面积',
    convert(varchar(7),清洗时间,120) as 动态1月存销比,
    convert(varchar(7),清洗时间,120) as 动态1月产销比,
    convert(varchar(7),dateadd(mm,1,清洗时间),120) as 动态2月存销比,
    convert(varchar(7),dateadd(mm,1,清洗时间),120) as 动态2月产销比,
    convert(varchar(7),dateadd(mm,2,清洗时间),120) as 动态3月存销比,
    convert(varchar(7),dateadd(mm,2,清洗时间),120) as 动态3月产销比,
    convert(varchar(7),dateadd(mm,3,清洗时间),120) as 动态4月存销比,
    convert(varchar(7),dateadd(mm,3,清洗时间),120) as 动态4月产销比,
    convert(varchar(7),dateadd(mm,4,清洗时间),120) as 动态5月存销比,
    convert(varchar(7),dateadd(mm,4,清洗时间),120) as 动态5月产销比,
    convert(varchar(7),dateadd(mm,5,清洗时间),120) as 动态6月存销比,
    convert(varchar(7),dateadd(mm,5,清洗时间),120) as 动态6月产销比,
    convert(varchar(7),dateadd(mm,6,清洗时间),120) as 动态7月存销比,
    convert(varchar(7),dateadd(mm,6,清洗时间),120) as 动态7月产销比,
    convert(varchar(7),dateadd(mm,7,清洗时间),120) as 动态8月存销比,
    convert(varchar(7),dateadd(mm,7,清洗时间),120) as 动态8月产销比,
    convert(varchar(7),dateadd(mm,8,清洗时间),120) as 动态9月存销比,
    convert(varchar(7),dateadd(mm,8,清洗时间),120) as 动态9月产销比,
    convert(varchar(7),dateadd(mm,9,清洗时间),120) as 动态10月存销比,
    convert(varchar(7),dateadd(mm,9,清洗时间),120) as 动态10月产销比,
    convert(varchar(7),dateadd(mm,10,清洗时间),120)  as 动态11月存销比,
    convert(varchar(7),dateadd(mm,10,清洗时间),120)  as 动态11月产销比,
    convert(varchar(7),dateadd(mm,11,清洗时间),120)  as 动态12月存销比,
    convert(varchar(7),dateadd(mm,11,清洗时间),120)  as 动态12月产销比 ,
    1 as 是否表头
from wqzydtBi_product_rest
where (统计维度 = '项目' or (统计维度<>'项目' and 户型 is null))
and  datediff(year,清洗时间,getdate()) =0
group by  清洗时间,统计维度,公司,城市,片区,镇街,项目,外键关联
 
select  清洗时间,统计维度,公司,城市,片区,镇街,项目,外键关联,id,parentid,产品名称,户型,业态 ,
    近三月流速,当前存货面积,当前已开工未售面积,
    case when 近三月流速 = '0.00' then '/' else 动态1月存销比 end as 动态1月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态1月产销比 end as 动态1月产销比,  
    case when 近三月流速 = '0.00' then '/' else 动态2月存销比 end as 动态2月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态2月产销比 end as 动态2月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态3月存销比 end as 动态3月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态3月产销比 end as 动态3月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态4月存销比 end as 动态4月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态4月产销比 end as 动态4月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态5月存销比 end as 动态5月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态5月产销比 end as 动态5月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态6月存销比 end as 动态6月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态6月产销比 end as 动态6月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态7月存销比 end as 动态7月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态7月产销比 end as 动态7月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态8月存销比 end as 动态8月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态8月产销比 end as 动态8月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态9月存销比 end as 动态9月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态9月产销比 end as 动态9月产销比,
    case when 近三月流速 = '0.00' then '/' else 动态10月存销比 end as 动态10月存销比,
    case when 近三月流速 = '0.00' then '/' else 动态10月产销比 end as 动态10月产销比,
    case when 近三月流速 = '0.00' then '/' else  动态11月存销比 end  as 动态11月存销比,
    case when 近三月流速 = '0.00' then '/' else  动态11月产销比 end  as 动态11月产销比,
    case when 近三月流速 = '0.00' then '/' else  动态12月存销比 end  as 动态12月存销比,
    case when 近三月流速 = '0.00' then '/' else  动态12月产销比 end  as 动态12月产销比 ,
    是否表头 --用于设置表头样式
from #t 
where 业态<> '后勤区'
and  datediff(year,清洗时间,getdate()) =0
*/


-- 使用CTE优化查询结构
WITH FilteredData AS (
    SELECT 
        清洗时间, 统计维度, 公司, 城市, 片区, 镇街, 项目, 外键关联, id, parentid, 产品名称, 户型, 业态,
        近三月流速, 当前存货面积, 当前已开工未售面积, 月份差, 存销比, 产销比
    FROM wqzydtBi_product_rest WITH (NOLOCK)
    WHERE (统计维度 = '项目' OR (统计维度 <> '项目' AND 户型 IS NULL))
      AND 业态 <> '后勤区'
      AND DATEDIFF(YEAR, 清洗时间, GETDATE()) = 0
),
MainData AS (
    SELECT 
        清洗时间, 统计维度, 公司, 城市, 片区, 镇街, 项目, 外键关联, id, parentid, 产品名称, 户型,
        CASE WHEN 户型 IS NOT NULL THEN 户型 ELSE (CASE WHEN 产品名称 IS NOT NULL THEN 产品名称 ELSE 业态 END) END AS 业态,
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 近三月流速)) AS 近三月流速,
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 当前存货面积)) AS 当前存货面积,
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 当前已开工未售面积)) AS 当前已开工未售面积,
        MAX(CASE WHEN 月份差 = 0 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态1月存销比,
        MAX(CASE WHEN 月份差 = 0 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态1月产销比,
        MAX(CASE WHEN 月份差 = -1 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态2月存销比,
        MAX(CASE WHEN 月份差 = -1 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态2月产销比,
        MAX(CASE WHEN 月份差 = -2 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态3月存销比,
        MAX(CASE WHEN 月份差 = -2 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态3月产销比,
        MAX(CASE WHEN 月份差 = -3 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态4月存销比,
        MAX(CASE WHEN 月份差 = -3 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态4月产销比,
        MAX(CASE WHEN 月份差 = -4 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态5月存销比,
        MAX(CASE WHEN 月份差 = -4 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态5月产销比,
        MAX(CASE WHEN 月份差 = -5 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态6月存销比,
        MAX(CASE WHEN 月份差 = -5 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态6月产销比,
        MAX(CASE WHEN 月份差 = -6 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态7月存销比,
        MAX(CASE WHEN 月份差 = -6 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态7月产销比,
        MAX(CASE WHEN 月份差 = -7 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态8月存销比,
        MAX(CASE WHEN 月份差 = -7 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态8月产销比,
        MAX(CASE WHEN 月份差 = -8 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态9月存销比,
        MAX(CASE WHEN 月份差 = -8 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态9月产销比,
        MAX(CASE WHEN 月份差 = -9 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态10月存销比,
        MAX(CASE WHEN 月份差 = -9 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态10月产销比,
        MAX(CASE WHEN 月份差 = -10 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态11月存销比,
        MAX(CASE WHEN 月份差 = -10 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态11月产销比,
        MAX(CASE WHEN 月份差 = -11 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 存销比)) ELSE '0' END) AS 动态12月存销比,
        MAX(CASE WHEN 月份差 = -11 THEN CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 产销比)) ELSE '0' END) AS 动态12月产销比,
        0 AS 是否表头
    FROM FilteredData WITH (NOLOCK)
    GROUP BY 
        清洗时间, 统计维度, 公司, 城市, 片区, 镇街, 项目, 外键关联, id, parentid, 产品名称, 户型, 业态,
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 近三月流速)),
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 当前存货面积)),
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(16,2), 当前已开工未售面积))
),
HeaderData AS (
    SELECT DISTINCT
        清洗时间, 统计维度, 公司, 城市, 片区, 镇街, 项目, 外键关联, 
        NULL AS id, NULL AS parentid,
        '产品名称' AS 产品名称, '户型' AS 户型, '业态' AS 业态,
        '近三月流速' AS 近三月流速, '当前存货面积' AS 当前存货面积, '当前已开工未售面积' AS 当前已开工未售面积,
        CONVERT(VARCHAR(7), 清洗时间, 120) AS 动态1月存销比,
        CONVERT(VARCHAR(7), 清洗时间, 120) AS 动态1月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 1, 清洗时间), 120) AS 动态2月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 1, 清洗时间), 120) AS 动态2月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 2, 清洗时间), 120) AS 动态3月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 2, 清洗时间), 120) AS 动态3月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 3, 清洗时间), 120) AS 动态4月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 3, 清洗时间), 120) AS 动态4月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 4, 清洗时间), 120) AS 动态5月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 4, 清洗时间), 120) AS 动态5月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 5, 清洗时间), 120) AS 动态6月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 5, 清洗时间), 120) AS 动态6月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 6, 清洗时间), 120) AS 动态7月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 6, 清洗时间), 120) AS 动态7月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 7, 清洗时间), 120) AS 动态8月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 7, 清洗时间), 120) AS 动态8月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 8, 清洗时间), 120) AS 动态9月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 8, 清洗时间), 120) AS 动态9月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 9, 清洗时间), 120) AS 动态10月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 9, 清洗时间), 120) AS 动态10月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 10, 清洗时间), 120) AS 动态11月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 10, 清洗时间), 120) AS 动态11月产销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 11, 清洗时间), 120) AS 动态12月存销比,
        CONVERT(VARCHAR(7), DATEADD(MM, 11, 清洗时间), 120) AS 动态12月产销比,
        1 AS 是否表头
    FROM FilteredData WITH (NOLOCK)
),
CombinedData AS (
    SELECT * FROM MainData WITH (NOLOCK)
    UNION ALL
    SELECT * FROM HeaderData WITH (NOLOCK)
)

-- 最终结果集
SELECT 
    清洗时间, 统计维度, 公司, 城市, 片区, 镇街, 项目, 外键关联, id, parentid, 产品名称, 户型, 业态,
    近三月流速, 当前存货面积, 当前已开工未售面积,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态1月存销比 END AS 动态1月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态1月产销比 END AS 动态1月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态2月存销比 END AS 动态2月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态2月产销比 END AS 动态2月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态3月存销比 END AS 动态3月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态3月产销比 END AS 动态3月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态4月存销比 END AS 动态4月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态4月产销比 END AS 动态4月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态5月存销比 END AS 动态5月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态5月产销比 END AS 动态5月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态6月存销比 END AS 动态6月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态6月产销比 END AS 动态6月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态7月存销比 END AS 动态7月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态7月产销比 END AS 动态7月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态8月存销比 END AS 动态8月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态8月产销比 END AS 动态8月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态9月存销比 END AS 动态9月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态9月产销比 END AS 动态9月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态10月存销比 END AS 动态10月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态10月产销比 END AS 动态10月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态11月存销比 END AS 动态11月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态11月产销比 END AS 动态11月产销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态12月存销比 END AS 动态12月存销比,
    CASE WHEN 近三月流速 = '0.00' THEN '/' ELSE 动态12月产销比 END AS 动态12月产销比,
    是否表头
FROM CombinedData WITH (NOLOCK)
