
-- 统计平台公司的现金流
SELECT  
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 ,
        sale.本月签约任务 ,
        sale.本月签约金额 ,
        hl.本月回笼任务 ,
        hl.本月回笼金额 ,
        cash.本月土地任务 AS 本月地价任务 ,
        cash.本月地价支出 ,
		cash.本月除地价外直投任务,
        cash.本月除地价外直投发生 ,
        cash.本月营销费支出 ,
        cash.本月管理费支出 ,
        cash.本月财务费支出 ,
        cash.本月三费任务  AS 本月三费任务 ,
        ISNULL(cash.本月营销费支出, 0) + ISNULL(cash.本月管理费支出, 0) + ISNULL(cash.本月财务费支出, 0) AS 本月三费金额 ,
        cash.本月税金支出 ,
        cash.本月经营性现金流目标 AS 本月经营性现金流任务 ,
        cash.本月经营性现金流 ,
        cash.本月经营性现金流目标 AS 本年经营性现金流任务 ,
        cash.本年经营性现金流 ,
        cash.本年股东投资现金流目标 AS 本年股东现金流任务 ,
        cash.本年股东现金流
INTO    #SubCompayMonthCshflow
FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
        -- LEFT JOIN highdata_prod.dw_s_WqBaseStatic_baseinfo base ON org.组织架构id = base.组织架构id and  org.清洗时间id = base.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and org.清洗时间id = sale.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and org.清洗时间id = hl.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_cashflowInfo cash ON cash.组织架构id = org.组织架构id and org.清洗时间id = cash.清洗时间id
WHERE   1 = 1 AND   org.组织架构类型 = 2 AND  org.平台公司名称 = '湾区公司'

--查询结果集
--签约指标
SELECT  convert(datetime, a.清洗时间 ) as 清洗时间,
        '本月' DType ,
        '签约' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月签约任务 ELSE 0 END) AS 东莞第一项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月签约金额 ELSE 0 END) AS 东莞第一项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月签约任务 ELSE 0 END) AS 东莞第二项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月签约金额 ELSE 0 END) AS 东莞第二项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月签约任务 ELSE 0 END) AS 汕揭梅城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月签约金额 ELSE 0 END) AS 汕揭梅城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月签约任务 ELSE 0 END) AS 汕尾城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月签约金额 ELSE 0 END) AS 汕尾城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月签约任务 ELSE 0 END) AS 河惠城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月签约金额 ELSE 0 END) AS 河惠城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月签约任务 ELSE 0 END) AS 深圳项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月签约金额 ELSE 0 END) AS 深圳项目部月度金额 ,
        SUM(ISNULL(本月签约任务, 0)) AS 湾区公司月度任务 ,
        SUM(ISNULL(本月签约金额, 0)) AS 湾区公司月度金额
FROM    #SubCompayMonthCshflow a
group by convert(datetime, a.清洗时间 )
UNION ALL
--回笼指标
SELECT  
         convert(datetime, a.清洗时间 ) as 清洗时间,
        '本月' DType ,
        '回笼' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月回笼任务 ELSE 0 END) AS 东莞第一项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月回笼金额 ELSE 0 END) AS 东莞第一项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月回笼任务 ELSE 0 END) AS 东莞第二项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月回笼金额 ELSE 0 END) AS 东莞第二项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月回笼任务 ELSE 0 END) AS 汕揭梅城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月回笼金额 ELSE 0 END) AS 汕揭梅城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月回笼任务 ELSE 0 END) AS 汕尾城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月回笼金额 ELSE 0 END) AS 汕尾城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月回笼任务 ELSE 0 END) AS 河惠城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月回笼金额 ELSE 0 END) AS 河惠城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月回笼任务 ELSE 0 END) AS 深圳项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月回笼金额 ELSE 0 END) AS 深圳项目部月度金额 ,
        SUM(ISNULL(本月回笼任务, 0)) AS 湾区公司月度任务 ,
        SUM(ISNULL(本月回笼金额, 0)) AS 湾区公司月度金额
FROM    #SubCompayMonthCshflow a
group by  convert(datetime, a.清洗时间 ) 
UNION ALL
--地价指标
SELECT  
        convert(datetime, a.清洗时间 ) as 清洗时间,
        '本月' DType ,
        '地价' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月地价任务 ELSE 0 END) AS 东莞第一项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月地价支出 ELSE 0 END) AS 东莞第一项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月地价任务 ELSE 0 END) AS 东莞第二项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月地价支出 ELSE 0 END) AS 东莞第二项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月地价任务 ELSE 0 END) AS 汕揭梅城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月地价支出 ELSE 0 END) AS 汕揭梅城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月地价任务 ELSE 0 END) AS 汕尾城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月地价支出 ELSE 0 END) AS 汕尾城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月地价任务 ELSE 0 END) AS 河惠城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月地价支出 ELSE 0 END) AS 河惠城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月地价任务 ELSE 0 END) AS 深圳项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月地价支出 ELSE 0 END) AS 深圳项目部月度金额 ,
        SUM(ISNULL(本月地价任务, 0)) AS 湾区公司月度任务 ,
        SUM(ISNULL(本月地价支出, 0)) AS 湾区公司月度金额
FROM    #SubCompayMonthCshflow a
group by convert(datetime, a.清洗时间 )
UNION ALL 
--除地价外直投
SELECT  
        convert(datetime, a.清洗时间 ) as 清洗时间,
        '本月' DType ,
        '除地价外直投' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月除地价外直投任务 ELSE 0 END) AS 东莞第一项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月除地价外直投发生 ELSE 0 END) AS 东莞第一项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月除地价外直投任务 ELSE 0 END) AS 东莞第二项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月除地价外直投发生 ELSE 0 END) AS 东莞第二项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月除地价外直投任务 ELSE 0 END) AS 汕揭梅城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月除地价外直投发生 ELSE 0 END) AS 汕揭梅城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月除地价外直投任务 ELSE 0 END) AS 汕尾城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月除地价外直投发生 ELSE 0 END) AS 汕尾城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月除地价外直投任务 ELSE 0 END) AS 河惠城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月除地价外直投发生 ELSE 0 END) AS 河惠城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月除地价外直投任务 ELSE 0 END) AS 深圳项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月除地价外直投发生 ELSE 0 END) AS 深圳项目部月度金额 ,
        SUM(ISNULL(本月除地价外直投任务, 0)) AS 湾区公司月度任务 ,
        SUM(ISNULL(本月除地价外直投发生, 0)) AS 湾区公司月度金额
FROM    #SubCompayMonthCshflow a
group by convert(datetime, a.清洗时间 )
--三费税金指标
UNION ALL
SELECT  
        convert(datetime, a.清洗时间 ) as 清洗时间,
        '本月' DType ,
        '三费税金' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月三费任务 ELSE 0 END) AS 东莞第一项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月三费金额 ELSE 0 END) AS 东莞第一项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月三费任务 ELSE 0 END) AS 东莞第二项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月三费金额 ELSE 0 END) AS 东莞第二项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月三费任务 ELSE 0 END) AS 汕揭梅城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月三费金额 ELSE 0 END) AS 汕揭梅城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月三费任务 ELSE 0 END) AS 汕尾城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月三费金额 ELSE 0 END) AS 汕尾城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月三费任务 ELSE 0 END) AS 河惠城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月三费金额 ELSE 0 END) AS 河惠城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月三费任务 ELSE 0 END) AS 深圳项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月三费金额 ELSE 0 END) AS 深圳项目部月度金额 ,
        SUM(ISNULL(本月三费任务, 0)) AS 湾区公司月度任务 ,
        SUM(ISNULL(本月三费金额, 0)) AS 湾区公司月度金额
FROM    #SubCompayMonthCshflow a
group by convert(datetime, a.清洗时间 )
--经营性现金流指标
UNION ALL
SELECT  
        convert(datetime, a.清洗时间 ) as 清洗时间,
        '本月' DType ,
        '经营性现金' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月经营性现金流任务 ELSE 0 END) AS 东莞第一项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本月经营性现金流 ELSE 0 END) AS 东莞第一项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月经营性现金流任务 ELSE 0 END) AS 东莞第二项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本月经营性现金流 ELSE 0 END) AS 东莞第二项目部月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月经营性现金流任务 ELSE 0 END) AS 汕揭梅城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本月经营性现金流 ELSE 0 END) AS 汕揭梅城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月经营性现金流任务 ELSE 0 END) AS 汕尾城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本月经营性现金流 ELSE 0 END) AS 汕尾城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月经营性现金流任务 ELSE 0 END) AS 河惠城市公司月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本月经营性现金流 ELSE 0 END) AS 河惠城市公司月度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月经营性现金流任务 ELSE 0 END) AS 深圳项目部月度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本月经营性现金流 ELSE 0 END) AS 深圳项目部月度金额 ,
        SUM(ISNULL(本月经营性现金流任务, 0)) AS 湾区公司月度任务 ,
        SUM(ISNULL(本月经营性现金流, 0)) AS 湾区公司月度金额
FROM    #SubCompayMonthCshflow a
group by convert(datetime, a.清洗时间 )
UNION ALL 
--本年现金流统计
SELECT  
        convert(datetime, a.清洗时间 ) as 清洗时间,
        '本年' DType ,
        '经营性现金' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本年经营性现金流任务 ELSE 0 END) AS 东莞第一项目部年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本年经营性现金流 ELSE 0 END) AS 东莞第一项目部年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本年经营性现金流任务 ELSE 0 END) AS 东莞第二项目部年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本年经营性现金流 ELSE 0 END) AS 东莞第二项目部年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本年经营性现金流任务 ELSE 0 END) AS 汕揭梅城市公司年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本年经营性现金流 ELSE 0 END) AS 汕揭梅城市公司年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本年经营性现金流任务 ELSE 0 END) AS 汕尾城市公司年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本年经营性现金流 ELSE 0 END) AS 汕尾城市公司年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本年经营性现金流任务 ELSE 0 END) AS 河惠城市公司年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本年经营性现金流 ELSE 0 END) AS 河惠城市公司年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本年经营性现金流任务 ELSE 0 END) AS 深圳项目部年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本年经营性现金流 ELSE 0 END) AS 深圳项目部年度金额 ,
        SUM(ISNULL(本年经营性现金流任务, 0)) AS 湾区公司年度任务 ,
        SUM(ISNULL(本年经营性现金流, 0)) AS 湾区公司年度金额
FROM    #SubCompayMonthCshflow a
group by convert(datetime, a.清洗时间 )
UNION ALL 
--本年现金流统计
SELECT  
         convert(datetime, a.清洗时间 ) as 清洗时间,
        '本年' DType ,
        '股东投资现金流' AS 关键指标 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本年股东现金流任务 ELSE 0 END) AS 东莞第一项目部年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第一项目部' THEN 本年股东现金流 ELSE 0 END) AS 东莞第一项目部年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本年股东现金流任务 ELSE 0 END) AS 东莞第二项目部年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '东莞第二项目部' THEN 本年股东现金流 ELSE 0 END) AS 东莞第二项目部年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本年股东现金流任务 ELSE 0 END) AS 汕揭梅城市公司年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕揭梅城市公司' THEN 本年股东现金流 ELSE 0 END) AS 汕揭梅城市公司年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本年股东现金流任务 ELSE 0 END) AS 汕尾城市公司年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '汕尾城市公司' THEN 本年股东现金流 ELSE 0 END) AS 汕尾城市公司年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本年股东现金流任务 ELSE 0 END) AS 河惠城市公司年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '河惠城市公司' THEN 本年股东现金流 ELSE 0 END) AS 河惠城市公司年度金额 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本年股东现金流任务 ELSE 0 END) AS 深圳项目部年度任务 ,
        SUM(CASE WHEN 组织架构名称 = '深圳项目部' THEN 本年股东现金流 ELSE 0 END) AS 深圳项目部年度金额 ,
        SUM(ISNULL(本年股东现金流任务, 0)) AS 湾区公司年度任务 ,
        SUM(ISNULL(本年股东现金流, 0)) AS 湾区公司年度金额
FROM    #SubCompayMonthCshflow a
group by convert(datetime, a.清洗时间 )


--删除临时表
DROP TABLE #SubCompayMonthCshflow;
