
-- 项目层级签约利润对比
-- 插入项目临时表
SELECT 
    --a.清洗时间,
    --a.清洗版本,
    c.DevelopmentCompanyGUID as 平台公司GUID,
    a.公司,
    a.投管代码,
    a.项目GUID,
    a.项目,
    a.推广名,
    a.获取日期,
    a.我方股比,
    a.是否并表,
    a.合作方,
    a.是否风险合作方,
    a.地上总可售面积,
    a.项目地价
INTO #proj 
FROM 业态签约利润对比表 a
inner join data_wide_dws_mdm_Project b on a.项目GUID = b.ProjGUID
inner join data_wide_dws_s_Dimension_Organization c on b.buguid = c.OrgGUID
inner join [172.16.4.141].erp25.dbo.vmdm_projectFlagnew d on a.项目GUID = d.projGUID
WHERE datediff(day, a.清洗时间, getdate()) = 0 and isnull(d.是否纳入动态利润分析,'') <> '否'
GROUP BY     
    -- a.清洗时间,
    -- a.清洗版本,
    c.DevelopmentCompanyGUID,
    a.公司,
    a.投管代码,
    a.项目GUID,
    a.项目,
    a.推广名,
    a.获取日期,
    a.我方股比,
    a.是否并表,
    a.合作方,
    a.是否风险合作方,
    a.地上总可售面积,
    a.项目地价

-- 签约利润
SELECT 
    a.项目GUID,
    -- 25年签约利润
    SUM(a.签约_25年签约) AS 签约_25年签约,
    SUM(a.签约不含税_25年签约) AS 签约不含税_25年签约,
    SUM(a.净利润_25年签约) AS 净利润_25年签约,
    SUM(CASE WHEN a.是否并表 = '我司并表' THEN a.净利润_25年签约 ELSE ISNULL(a.我方股比, 0) /100.0 * a.净利润_25年签约 END) AS 报表利润_25年签约,
    CASE WHEN SUM(a.签约不含税_25年签约) = 0 THEN 0
         ELSE SUM(a.净利润_25年签约) / SUM(a.签约不含税_25年签约) END AS 净利率_25年签约,
    
    -- 本月签约利润
    SUM(a.签约_本月实际) AS 签约_本月实际,
    SUM(a.签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(a.净利润_本月实际) AS 净利润_本月实际,
    SUM(CASE WHEN a.是否并表 = '我司并表' THEN a.净利润_本月实际 ELSE ISNULL(a.我方股比, 0) /100.0 * a.净利润_本月实际 END) AS 报表利润_本月实际,
    CASE WHEN SUM(a.签约不含税_本月实际) = 0 THEN 0
         ELSE SUM(a.净利润_本月实际) / SUM(a.签约不含税_本月实际) END AS 净利率_本月实际,
    
    -- 利润预算
    SUM(a.签约_25年预算) AS 签约_25年预算,
    SUM(a.签约不含税_25年预算) AS 签约不含税_25年预算,
    SUM(a.净利润_25年预算) AS 净利润_25年预算,
    SUM(CASE WHEN a.是否并表 = '我司并表' THEN a.净利润_25年预算 ELSE ISNULL(a.我方股比, 0) /100.0 * a.净利润_25年预算 END) AS 报表利润_25年预算,
    CASE WHEN SUM(a.签约不含税_25年预算) = 0 THEN 0
         ELSE SUM(a.净利润_25年预算) / SUM(a.签约不含税_25年预算) END AS 净利率_25年预算
INTO #lr
FROM 业态签约利润对比表 a
WHERE DATEDIFF(DAY, a.清洗时间, GETDATE()) = 0
GROUP BY a.项目GUID


-- 查询最终结果
SELECT  
    -- p.清洗时间,
    --p.清洗版本,
    p.平台公司GUID,
    p.公司,
    p.投管代码,
    p.项目GUID,
    p.项目,
    p.推广名,
    p.获取日期,
    p.我方股比,
    p.是否并表,
    p.合作方,
    p.是否风险合作方,
    p.地上总可售面积,
    p.项目地价,

    -- 25年签约利润
    lr.签约_25年签约,
    lr.签约不含税_25年签约,
    lr.净利润_25年签约,
    lr.报表利润_25年签约,
    lr.净利率_25年签约,
    -- 本月签约利润
    lr.签约_本月实际,
    lr.签约不含税_本月实际,
    lr.净利润_本月实际,
    lr.报表利润_本月实际,
    lr.净利率_本月实际,
    -- 预算利润
    lr.签约_25年预算,
    lr.签约不含税_25年预算,
    lr.净利润_25年预算,
    lr.报表利润_25年预算,
    lr.净利率_25年预算
INTO #lr_proj
FROM #proj p
LEFT JOIN #lr lr ON p.项目GUID = lr.项目GUID
WHERE 1=1

-- 1、实际净利率较预算变化分类
SELECT 
    p.平台公司GUID,
    p.公司,
    '一' AS 序号,
    '总数' AS 分类,
    null AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
-- WHERE isnull(签约_25年预算,0) <> 0 and  净利率_25年签约 < 净利率_25年预算 - 0.3
GROUP BY p.公司,p.平台公司GUID
UNION ALL

-- 1.1净利率下降超30个百分点
SELECT 
    p.平台公司GUID,
    p.公司,
    '一' AS 序号,
    '实际净利率较预算变化分类' AS 分类,
    '净利率下降超30个百分点' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE isnull(签约_25年预算,0) <> 0 and  净利率_25年签约 < 净利率_25年预算 - 0.3
GROUP BY p.公司,p.平台公司GUID

UNION ALL

-- 1.2净利率下降超10-30个百分点
SELECT 
    p.平台公司GUID,
    p.公司,
    '一' AS 序号,
    '实际净利率较预算变化分类' AS 分类,
    '净利率下降超10-30个百分点' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE isnull(签约_25年预算,0) <> 0 and  净利率_25年签约 < 净利率_25年预算 - 0.1 AND 净利率_25年签约 >= 净利率_25年预算 - 0.3
GROUP BY p.公司,p.平台公司GUID

UNION ALL 

-- 1.3净利率下降超5-10个百分点
SELECT 
    p.平台公司GUID,
    p.公司,
    '一' AS 序号,
    '实际净利率较预算变化分类' AS 分类,
    '净利率下降10个百分点以内' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE isnull(签约_25年预算,0) <> 0 and  净利率_25年签约 < 净利率_25年预算 - 0.05 AND 净利率_25年签约 >= 净利率_25年预算 - 0.1
GROUP BY p.公司,p.平台公司GUID

UNION ALL 

-- 1.4基本一致(下降超0-5个百分点)
SELECT 
    p.平台公司GUID,
    p.公司,
    '一' AS 序号,
    '实际净利率较预算变化分类' AS 分类,
    '基本一致' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE isnull(签约_25年预算,0) <> 0 and  净利率_25年签约 <= 净利率_25年预算 AND 净利率_25年签约 >= 净利率_25年预算 - 0.05
GROUP BY p.公司,p.平台公司GUID

UNION ALL 

-- 1.5净利润率较预算提升
SELECT 
    p.平台公司GUID,
    p.公司,
    '一' AS 序号,
    '实际净利率较预算变化分类' AS 分类,
    '净利润率较预算提升' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE isnull(签约_25年预算,0) <> 0 and   净利率_25年签约 > 净利率_25年预算 
GROUP BY p.公司,p.平台公司GUID

UNION ALL 

-- 1.6无预算
SELECT 
    p.平台公司GUID,
    p.公司,
    '一' AS 序号,
    '实际净利率较预算变化分类' AS 分类,
    '无预算' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE isnull(签约_25年预算,0) = 0
GROUP BY p.公司,p.平台公司GUID

-- 2、按获取时间分类
union all 
-- 2.1 25年获取
SELECT 
    p.平台公司GUID,
    p.公司,
    '二' AS 序号,
    '按获取时间分类' AS 分类,
    '25年获取' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE year(p.获取日期) = 2025
GROUP BY p.公司,p.平台公司GUID

union all 
-- 2.2 24年获取
SELECT 
    p.平台公司GUID,
    p.公司,
    '二' AS 序号,
    '按获取时间分类' AS 分类,
    '24年获取' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE year(p.获取日期) = 2024
GROUP BY p.公司,p.平台公司GUID

union all
-- 2.3 新增量
SELECT 
    p.平台公司GUID,
    p.公司,
    '二' AS 序号,
    '按获取时间分类' AS 分类,
    '新增量' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE year(p.获取日期) =2023
GROUP BY p.公司,p.平台公司GUID
union all
-- 2.4 增量
SELECT 
    p.平台公司GUID,
    p.公司,
    '二' AS 序号,
    '按获取时间分类' AS 分类,
    '增量' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE year(p.获取日期) =  2022
GROUP BY p.公司,p.平台公司GUID
union all
-- 2.5 存量
SELECT 
    p.平台公司GUID,
    p.公司,
    '二' AS 序号,
    '按获取时间分类' AS 分类,
    '存量' AS 明细分类,
    -- 本年实际签约
    COUNT(DISTINCT 项目GUID) AS 项目个数_本年实际,
    SUM(签约_25年签约) AS 签约_本年实际,
    SUM(签约不含税_25年签约) AS 签约不含税_本年实际,
    SUM(净利润_25年签约) AS 净利润_本年实际,
    SUM(报表利润_25年签约) AS 报表利润_本年实际,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END AS 净利率_本年实际,
    -- 年度预算数
    SUM(签约_25年预算) AS 签约_预算,
    SUM(签约不含税_25年预算) AS 签约不含税_预算,
    SUM(净利润_25年预算) AS 净利润_预算,
    CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率_预算,
    -- 较预算变化
    CASE WHEN SUM(签约_25年预算) = 0 THEN 0 ELSE SUM(签约_25年签约) / SUM(签约_25年预算) END AS 签约完成率,
    CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
    - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 净利率偏差率,  -- (实际-预算)/预算
    -- 本月签约利润
    SUM(签约_本月实际) AS 签约_本月,
    SUM(签约不含税_本月实际) AS 签约不含税_本月实际,
    SUM(净利润_本月实际) AS 净利润_本月,
    SUM(报表利润_本月实际) AS 报表利润_本月,
    CASE WHEN SUM(签约不含税_本月实际) = 0 THEN 0 ELSE SUM(净利润_本月实际) / SUM(签约不含税_本月实际) END AS 净利率_本月
FROM #lr_proj p
WHERE year(p.获取日期) < 2022 or p.获取日期 is null
GROUP BY p.公司,p.平台公司GUID



-- 删除临时表
DROP TABLE #proj
DROP TABLE #lr
drop table #lr_proj
