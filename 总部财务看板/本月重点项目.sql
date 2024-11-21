
-- 创建临时表存储成交数据
-----————————————————获取成交数据----
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       -- 根据存量增量和首开情况区分业绩类型
       CASE
           WHEN f.存量增量 = '新增量' AND f.是否本月首开 = '是' THEN '新增量首开'
           WHEN f.存量增量 = '新增量' AND f.是否本月首开 <> '是' THEN '新增量续销'
           WHEN f.存量增量 = '增量' THEN '增量续销'
           WHEN f.存量增量 = '存量' AND f.projguid <> '7125EDA8-FCC1-E711-80BA-E61F13C57837' THEN '存量续销'
           ELSE '上海世博'
       END 业绩区分,
       f.平台公司,
       f.项目名,
       -- 计算本日认购套数(不含地下室/车库/仓库)
       SUM(CASE
           WHEN a.产品类型 NOT in ('地下室/车库','仓库') THEN
               CASE
                   WHEN DAY(GETDATE()) = 1 THEN ISNULL(b.本月认购套数, 0)
                   ELSE ISNULL(b.本月认购套数, 0) - ISNULL(c.本月认购套数, 0)
               END
           ELSE 0
       END) 本日认购套数,
       -- 计算本日认购面积
       SUM(CASE
           WHEN DAY(GETDATE()) = 1 THEN ISNULL(b.本月认购面价, 0)
           ELSE ISNULL(b.本月认购面价, 0) - ISNULL(c.本月认购面价, 0)
       END) 本日认购面积,
       -- 计算本日认购面积(不含车位)
       SUM(CASE
           WHEN a.产品类型 <> '地下室/车库' THEN
               CASE
                   WHEN DAY(GETDATE()) = 1 THEN ISNULL(b.本月认购面价, 0)
                   ELSE ISNULL(b.本月认购面价, 0) - ISNULL(c.本月认购面价, 0)
               END
           ELSE 0
       END) 本日认购面积非车位,
       -- 计算本日认购金额
       SUM(CASE
           WHEN DAY(GETDATE()) = 1 THEN ISNULL(b.本月认购金额, 0)
           ELSE ISNULL(b.本月认购金额, 0) - ISNULL(c.本月认购金额, 0)
       END) 本日认购金额
INTO #yj
FROM (
    -- 获取今天和昨天的项目数据
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, GETDATE()) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, GETDATE()) = 1
) a
LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
-- 关联今天的数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, GETDATE()) = 0
-- 关联昨天的数据                                          
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, GETDATE()) = 1
GROUP BY CASE
             WHEN f.存量增量 = '新增量' AND f.是否本月首开 = '是' THEN '新增量首开'
             WHEN f.存量增量 = '新增量' AND f.是否本月首开 <> '是' THEN '新增量续销'
             WHEN f.存量增量 = '增量' THEN '增量续销'
             WHEN f.存量增量 = '存量' AND f.projguid <> '7125EDA8-FCC1-E711-80BA-E61F13C57837' THEN '存量续销'
             ELSE '上海世博'
         END,
         f.平台公司,
         f.项目名;

-- 查询重点项目(认购套数>=20或认购金额>20000)
SELECT ISNULL(buguid,'') buguid,
       ISNULL(业绩区分,'') 业绩区分,
       ISNULL(replace(平台公司,'公司',''),'') 公司,
       ISNULL(项目名,'') 项目名,
       ISNULL(本日认购套数,0) 本日认购套数,
       ISNULL(本日认购面积,0) 本日认购面积,
       ISNULL(本日认购金额,0) 本日认购金额,
       ISNULL(本日认购金额*10000 / NULLIF(本日认购面积,0),0) 认购均价
FROM #yj
WHERE 本日认购套数 >= 20
      OR 本日认购金额 > 20000
UNION ALL
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       '暂无数据' 业绩区分,
       '暂无数据' 公司,
       '暂无数据' 项目名,
       0 本日认购套数,
       0 本日认购面积,
       0 本日认购金额,
       0 认购均价
WHERE NOT EXISTS (
    SELECT 1 FROM #yj 
    WHERE 本日认购套数 >= 20 
          OR 本日认购金额 > 20000
)
ORDER BY 公司,
         项目名;

-- 清理临时表
DROP TABLE #yj;