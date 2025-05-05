/*
 * 项目名称: 除地价外直投对比分析
 * 功能描述: 获取100个项目的明源成本系统动态成本拍照、二次分摊、盈利规划最新落盘三个版本的除地价外直投数据
 * 创建日期: [日期]
 * 作者: [作者]
 */

-- =============================================
-- 1. 获取项目清单
-- 说明: 从项目主数据中筛选出100个指定项目
-- =============================================
SELECT 
    projguid,
    projname,
    tgprojcode,
    spreadname
INTO #p
FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project 
WHERE level = 2 
AND (
    spreadname IN (
        '合肥龙川瑧悦',
        '芜湖保利和光瑞府',
        '合肥海上瑧悦',
        '合肥琅悦',
        '北京嘉华天珺',
        '北京璟山和煦',
        '北京颐璟和煦',
        '北京保利锦上二期',
        '大连保利东港天珺',
        '福州保利天瓒',
        '福州保利屏西天悦',
        '莆田绶溪保利瑧悦',
        '莆田保利建发棠颂和府',
        '兰州保利天汇',
        '兰州保利公园698',
        '广州保利华创．都荟天珺',
        '广州保利珠江天悦；广州保利珠江印象',
        '广州保利天瑞',
        '广州保利燕语堂悦',
        '广州保利招商华发中央公馆',
        '广州中海保利朗阅',
        '广州保利棠馨花园',
        '广州保利翔龙天汇',
        '广州保利湖光悦色',
        '三亚保利．栖山雨茗;保利．伴山瑧悦',
        '三亚保利．海晏',
        '厦门沁原二期',
        '泉州清源瑧悦',
        '厦门天琴',
        '维景天珺',
        '华晨天奕',
        '石家庄保利维明天珺',
        '石家庄保利天汇',
        '郑州保利大都汇',
        '郑州保利海德公园',
        '武汉保利涧山观奕',
        '武汉阅江台A包',
        '长沙保利天瑞',
        '长沙保利梅溪天珺',
        '长沙保利北中心保利时代',
        '和光晨樾',
        '佛山保利天瓒',
        '佛山保利湖光里',
        '佛山保利阅江台.江缦',
        '佛山保利湖映琅悦',
        '佛山保利德胜天汇',
        '佛山保利琅悦',
        '佛山保利珺悦府',
        '佛山保利灯湖天珺',
        '佛山保利秀台天珺',
        '佛山保利天汇',
        '徐州保利学府',
        '徐州水沐玖悦府',
        '徐州保利建发天瑞',
        '江韵瑧悦',
        '南京.保利荷雨瑧悦',
        '南京 璟上',
        '南昌保利天汇三期',
        '南昌保利天珺',
        '大连保利时代金地城',
        '沈阳保利和光屿湖',
        '沈阳保利天汇（公园壹号）',
        '济南市保利琅悦',
        '青岛保利青铁和著理想地',
        '青岛市城阳区虹桥路项目',
        '太原保利龙城天珺',
        '太原保利龙城璞悦',
        '太原保利和光尘樾',
        '太原保利和悦华锦',
        '长兴璞悦',
        '西安保利天珺二期',
        '西安保利云谷和著',
        '西安保利咏山和颂',
        '西安市保利未央璞悦',
        '上海保利外滩序45Bund',
        '上海保利海上瑧悦',
        '上海保利光合上城',
        '上海保利世博天悦',
        '成都保利花照天珺',
        '成都保利.新川天珺',
        '成都保利.天府瑧悦',
        '成都保利.天府和颂二期',
        '成都保利怡心和颂',
        '成都中粮保利天府时区',
        '苏州保利天汇',
        '苏州昆山和光璀璨',
        '苏州昆山保利拾锦东方',
        '苏州园区天朗汇庭',
        '苏州保利瑧悦',
        '天津保利西棠和煦二期',
        '天津保利·和光尘樾',
        '东莞南城保利天珺',
        '汕尾保利时代',
        '江门保利琅悦',
        '珠海九洲保利天和',
        '江门保利大都汇',
        '江门保利西海岸',
        '中山保利天珺',
        '昆明市保利天珺项目',
        '西双版纳保利雨林澜山',
        '长春保利和煦项目',
        '长春保利·朗阅三期',
        '宁波保利东方瑧悦府',
        '宁波保利明州瑧悦府',
        '宁波保利海晏天珺',
        '温州保利招商天樾玺二期',
        '台州保利凤起云城',
        '重庆中粮保利天玺壹号（134）',
        '重庆保利拾光年',
        '贵阳保利大国璟'
    ) 
    OR TgProjCode IN ('1417','3925','3924','725', '1856','4922','8711')
);

-- =============================================
-- 2. 获取动态成本拍照版本
-- 说明: 获取每个项目最新的动态成本拍照版本
-- =============================================
SELECT 
    t.projguid,
    MAX(CurVersion) AS CurVersion
INTO #cbbb
FROM [172.16.4.161].highdata_prod.dbo.data_wide_cb_MonthlyReview T
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj 
    ON t.projguid = pj.projguid 
INNER JOIN #p p 
    ON p.projguid = pj.parentguid
WHERE CreateUserName <> '系统管理员'
GROUP BY t.projguid;

-- =============================================
-- 3. 计算动态成本数据
-- 说明: 计算除地价外直投相关指标
-- =============================================
SELECT 
    t.projguid,
    CurVersion,
    版本,
    SUM(除地价外直投不含税_非现金) AS 除地价外直投不含税_非现金,
    SUM(除地价外直投含税_非现金) AS 除地价外直投含税_非现金, 
    SUM(除地价外直投不含税) AS 除地价外直投不含税,
    SUM(除地价外直投含税) AS 除地价外直投含税
INTO #cb
FROM (
    SELECT 
        t.projguid, 
        t.CurVersion,
        '回顾版：' + t.CurVersion AS 版本,
        -- 计算除地价外直投不含税_非现金
        SUM(CASE WHEN t.AccountCode = '5001' THEN ISNULL(CurDynamicCostNonTax_fxj, 0) ELSE 0 END) -
        SUM(CASE WHEN t.AccountCode IN ('5001.10','5001.09','5001.11','5001.01') 
            THEN ISNULL(CurDynamicCostNonTax_fxj, 0) ELSE 0 END) AS 除地价外直投不含税_非现金,
        -- 计算除地价外直投含税_非现金
        SUM(CASE WHEN t.AccountCode = '5001' THEN ISNULL(CurDynamicCost_fxj, 0) ELSE 0 END) -
        SUM(CASE WHEN t.AccountCode IN ('5001.10','5001.09','5001.11','5001.01') 
            THEN ISNULL(CurDynamicCost_fxj, 0) ELSE 0 END) AS 除地价外直投含税_非现金, 
        -- 计算除地价外直投不含税
        SUM(CASE WHEN t.AccountCode = '5001' THEN ISNULL(CurDynamicCostNonTax, 0) ELSE 0 END) -
        SUM(CASE WHEN t.AccountCode IN ('5001.10','5001.09','5001.11','5001.01') 
            THEN ISNULL(CurDynamicCostNonTax, 0) ELSE 0 END) AS 除地价外直投不含税,
        -- 计算除地价外直投含税
        SUM(CASE WHEN t.AccountCode = '5001' THEN ISNULL(CurDynamicCost, 0) ELSE 0 END) -
        SUM(CASE WHEN t.AccountCode IN ('5001.10','5001.09','5001.11','5001.01') 
            THEN ISNULL(CurDynamicCost, 0) ELSE 0 END) AS 除地价外直投含税
    FROM [172.16.4.161].highdata_prod.dbo.data_wide_cb_MonthlyReview t 
    INNER JOIN #cbbb bb 
        ON t.CurVersion = bb.CurVersion 
        AND t.projguid = bb.projguid 
    WHERE t.AccountCode IN ('5001','5001.10','5001.09','5001.11','5001.01') 
    GROUP BY t.projguid, t.CurVersion
) t 
GROUP BY t.projguid, CurVersion, 版本;

-- =============================================
-- 4. 获取标准科目设置的分摊规则
-- 说明: 从标准科目表中获取分摊规则配置
-- =============================================
SELECT
    ItemShortName,
    ItemCode,
    ParentCode,
    IsEndCost,
    CostLevel,
    FtTypeName AS SjFtModel,
    CASE
        WHEN FtTypeName LIKE '%自持%' AND FtTypeName LIKE '%可售%' THEN '自持+可售'
        WHEN FtTypeName LIKE '%自持%' THEN '自持面积'
        WHEN FtTypeName LIKE '%建筑%' THEN '建筑面积'
        WHEN FtTypeName LIKE '%计容%' THEN '计容面积'
        WHEN FtTypeName LIKE '%可售%' THEN '可售面积'
    END AS 分摊规则,
    IsCwFt 
INTO #standCost
FROM MyCost_Erp352.dbo.p_BzItem
WHERE ItemType = '控制科目'
    AND ItemShortName NOT IN ('中间科目', '除地价外直投')
    AND IsEndCost = 1;

-- =============================================
-- 5. 获取二次成本分摊数据
-- 说明: 获取项目的二次成本分摊数据
-- =============================================
SELECT 
    pkcbr.projguid, 
    SUM(dtl.buildcost) AS 除地价外直投 
INTO #Ecft
FROM [172.16.4.132].TaskCenterData.dbo.[cb_ProductKsCbRecollect] pkcbr
INNER JOIN [172.16.4.132].TaskCenterData.dbo.[cb_ProductKsCbDtlRecollect] dtl 
    ON dtl.ProductKsCbRecollectGUID = pkcbr.ProductKsCbRecollectGUID
INNER JOIN (
    SELECT
        a.ProductCostRecollectGUID,
        a.ProjGUID,
        a.UpVersion,
        a.CurVersion,
        a.ImportVersionName,
        a.RecollectTime,
        ROW_NUMBER() OVER (
            PARTITION BY a.ProjGUID
            ORDER BY a.RecollectTime DESC
        ) AS num
    FROM [172.16.4.132].TaskCenterData.dbo.cb_ProductCostRecollect a
    WHERE a.ApproveState = '已审核'
) pcr 
    ON pcr.ProductCostRecollectGUID = pkcbr.ProductCostRecollectGUID 
    AND pcr.num = 1
LEFT JOIN #standCost sta 
    ON sta.ItemCode = pkcbr.costcode 
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj 
    ON pkcbr.projguid = pj.projguid 
INNER JOIN #p p 
    ON p.projguid = pj.parentguid
WHERE IsCost = 1 
    AND costcode NOT LIKE '5001.09%' 
    AND costcode NOT LIKE '5001.10%' 
    AND costcode NOT LIKE '5001.01%'
    AND costcode NOT LIKE '5001.11%'
    AND isendcost = 1
    AND buildcost <> 0 
GROUP BY pkcbr.projguid;

-- =============================================
-- 6. 获取盈利规划数据
-- 说明: 获取项目的盈利规划数据
-- =============================================
SELECT  
    t.YLGHProjGUID AS projguid, 
    SUM(除地价外直投不含税) AS 盈利规划除地价外直接投资,
    SUM(除地价外直投含税) AS 盈利规划除地价外直接投资含税
INTO #ylgh
FROM ( 
    SELECT  
        pj.YLGHProjGUID,
        SUM(CASE WHEN 报表预测项目科目 = '除地价外直投（含税）' 
            THEN CONVERT(DECIMAL(16,2), value_string) ELSE 0 END) AS 除地价外直投含税,
        SUM(CASE WHEN 报表预测项目科目 = '除地价外直投（不含税）' 
            THEN CONVERT(DECIMAL(16,2), value_string) ELSE 0 END) AS 除地价外直投不含税
    FROM [172.16.4.161].highdata_prod.dbo.data_wide_qt_F080005 f08
    INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_ys_ProjGUID pj 
        ON f08.实体分期 = pj.YLGHProjGUID 
        AND pj.isbase = 1 
        AND pj.BusinessEdition = f08.版本 
        AND pj.Level = 3
    INNER JOIN #p p 
        ON p.projguid = pj.projguid
    WHERE 报表预测项目科目 IN ('除地价外直投（不含税）', '除地价外直投（含税）')
        AND CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0 
    GROUP BY pj.YLGHProjGUID 
) t  
GROUP BY t.YLGHProjGUID;

-- =============================================
-- 7. 合并所有指标
-- 说明: 将各个来源的数据合并为最终结果
-- =============================================
SELECT 
    bu.BUName,
    p.tgprojcode AS 投管代码, 
    p.spreadname AS 推广名称, 
    pj.projguid, 
    cbp.ProjName AS 分期名,
    cb.CurVersion,
    cb.版本,
    cb.除地价外直投不含税_非现金 AS 动态成本除地价外直投不含税_非现金,
    cb.除地价外直投含税_非现金 AS 动态成本除地价外直投含税_非现金,
    cb.除地价外直投不含税 AS 动态成本除地价外直投不含税,
    cb.除地价外直投含税 AS 动态成本除地价外直投含税,
    ecft.除地价外直投 AS 二次成本分摊除地价外直投,
    ylgh.盈利规划除地价外直接投资含税 AS 盈利规划除地价外直投含税,
    ylgh.盈利规划除地价外直接投资 AS 盈利规划除地价外直投不含税
FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj 
INNER JOIN myBusinessUnit bu  ON bu.BUGUID = pj.buguid
INNER JOIN p_Project cbp  ON pj.projguid = cbp.ProjGUID
INNER JOIN #p p  ON p.projguid = pj.parentguid 
LEFT JOIN [172.16.4.161].highdata_prod.dbo.test ylgh 
    ON ylgh.projguid = pj.projguid 
    AND LEN(ylgh.projguid) = 36
LEFT JOIN #Ecft ecft 
    ON ecft.projguid = pj.projguid 
LEFT JOIN #cb cb 
    ON cb.projguid = pj.projguid

UNION ALL 

SELECT 
    bu.BUName,
    pj.tgprojcode AS 投管代码, 
    pj.spreadname AS 推广名称, 
    p.projguid, 
    pj.projname + '全分期' AS 分期名, 
    NULL AS CurVersion,
    NULL AS 版本,
    NULL AS 动态成本除地价外直投不含税_非现金,
    NULL AS 动态成本除地价外直投含税_非现金,
    NULL AS 动态成本除地价外直投不含税,
    NULL AS 动态成本除地价外直投含税,
    NULL AS 二次成本分摊除地价外直投,
    ylgh.盈利规划除地价外直接投资含税 AS 盈利规划除地价外直投含税,
    ylgh.盈利规划除地价外直接投资 AS 盈利规划除地价外直投不含税
FROM [172.16.4.161].highdata_prod.dbo.test ylgh  
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_ys_ProjGUID p 
    ON ylgh.projguid = p.ylghprojguid 
    AND p.isbase = 1 
    AND p.level = 3
INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj 
    ON pj.projguid = p.projguid
INNER JOIN myBusinessUnit bu 
    ON bu.BUGUID = pj.buguid
WHERE LEN(ylgh.projguid) > 36;




