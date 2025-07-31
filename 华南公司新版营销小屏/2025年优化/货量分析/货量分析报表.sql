--缓存项目基本信息
SELECT  pj.projguid ,
        pj.projcode_25 AS 项目代码 ,
		pj.TgProjCode AS 投管代码,
        t.营销事业部 AS 公司事业部 ,
        t.营销片区 AS 组团 ,
        pj.spreadname AS 项目名称 ,
        t.项目负责人 营销经理 ,
        pj.city 城市 ,
        CASE WHEN YEAR(pj.BeginDate) > 2022 THEN '新增量' WHEN YEAR(pj.BeginDate) = 2022 THEN '增量' ELSE '存量' END AS 项目获取状态
INTO    #p
FROM    [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_project] pj
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_tb_hn_yxpq] t ON pj.projguid = t.项目Guid
WHERE   1 = 1 AND   pj.level = 2  and  pj.buguid ='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' AND  pj.projguid IN  (@var_ProjGUID)

--获取销售情况：业态及产成品
SELECT  p.projguid ,
        CASE WHEN pb.FactFinishDate IS NULL THEN 0 ELSE 1 END AS 是否产成品 ,
        CASE WHEN Sale.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' WHEN Sale.TopProductTypeName IN ('地下室/车库') THEN '车位' ELSE '商办' END AS 指标类型 ,
        SUM(ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)) 累计签约套数 ,
        SUM(ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)) 累计签约面积 ,
        SUM(ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)) / 10000 累计签约金额 ,
        -- 本年
        SUM(case when datediff(yy,Sale.StatisticalDate,getdate()) =0 then ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) else 0 end) 本年签约套数 ,
        SUM(case when datediff(yy,Sale.StatisticalDate,getdate()) =0 then ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 本年签约面积 ,
        SUM(case when datediff(yy,Sale.StatisticalDate,getdate()) =0 then ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) else 0 end) / 10000 本年签约金额 ,
        -- 本月
        SUM(case when datediff(mm,Sale.StatisticalDate,getdate()) =0 then ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) else 0 end) 本月签约套数 ,
        SUM(case when datediff(mm,Sale.StatisticalDate,getdate()) =0 then ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) else 0 end) 本月签约面积 ,
        SUM(case when datediff(mm,Sale.StatisticalDate,getdate()) =0 then ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) else 0 end) / 10000 本月签约金额 ,

        --近一月
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -1, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                 ELSE 0
            END) / 10000.0 AS 近一月去化货值 ,
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -1, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                 ELSE 0
            END) AS 近一月去化套数 ,
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -1, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                 ELSE 0
            END) 近一月去化面积 ,
        --近三月
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                 ELSE 0
            END) / 10000.0 AS 近三月去化货值 ,
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                 ELSE 0
            END) AS 近三月去化套数 ,
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                 ELSE 0
            END) 近三月去化面积 ,
        --近六月
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                 ELSE 0
            END) / 10000.0 AS 近六月去化货值 ,
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                 ELSE 0
            END) AS 近六月去化套数 ,
        SUM(CASE WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE() THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                 ELSE 0
            END) 近六月去化面积
INTO    #sale
FROM    [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_SalesPerf Sale
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_Building] pb ON Sale.GCBldGUID = pb.BuildingGUID AND pb.BldType = '工程楼栋'
        INNER JOIN #p p ON Sale.parentprojguid = p.projguid
GROUP BY p.projguid ,
         CASE WHEN pb.FactFinishDate IS NULL THEN 0 ELSE 1 END ,
         CASE WHEN Sale.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' WHEN Sale.TopProductTypeName IN ('地下室/车库') THEN '车位' ELSE '商办' END;

--获取项目货值情况：业态及产成品
SELECT  hz.projguid ,
        CASE WHEN FactFinishDate IS NULL THEN 0 ELSE 1 END AS 是否产成品 ,
        CASE WHEN hz.topproductname IN ('高级住宅', '住宅', '别墅') THEN '住宅' WHEN hz.topproductname IN ('地下室/车库') THEN '车位' ELSE '商办' END AS 业态 ,
        SUM(ISNULL(已完工_已推未售套数, 0) + ISNULL(未完工_已推未售套数, 0)) 已推未售套数 ,
        SUM(ISNULL(已完工_已推未售货量面积, 0) + ISNULL(未完工_已推未售货量面积, 0)) 已推未售面积 ,
        SUM(ISNULL(已完工_已推未售货值金额, 0) + ISNULL(未完工_已推未售货值金额, 0)) / 10000.0 已推未售货值 ,
        SUM(ISNULL(总货值套数, 0)) - SUM(ISNULL(已完工_已推未售套数, 0) + ISNULL(未完工_已推未售套数, 0)) - SUM(ISNULL(已售套数, 0)) 未推套数 ,    --总货值 - 已推未售 - 已售
        SUM(ISNULL(总货值面积, 0)) - SUM(ISNULL(已完工_已推未售货量面积, 0) + ISNULL(未完工_已推未售货量面积, 0)) - SUM(ISNULL(已售面积, 0)) 未推面积 ,
        SUM(ISNULL(总货值金额, 0)) / 10000.0 - SUM(ISNULL(已完工_已推未售货值金额, 0) + ISNULL(未完工_已推未售货值金额, 0)) / 10000.0 - SUM(ISNULL(已售金额, 0)) / 10000.0 未推货值
INTO    #hz
FROM    [172.16.4.161].highdata_prod.dbo.[data_wide_dws_jh_ldHzOverview] hz
        INNER JOIN #p p ON hz.projguid = p.projguid
GROUP BY hz.projguid ,
         CASE WHEN FactFinishDate IS NULL THEN 0 ELSE 1 END ,
         CASE WHEN hz.topproductname IN ('高级住宅', '住宅', '别墅') THEN '住宅' WHEN hz.topproductname IN ('地下室/车库') THEN '车位' ELSE '商办' END;

--获取面积段对应的销售及货值情况
SELECT  p.projguid ,
        tb.面积段显示名称 指标类型 ,
        SUM(CASE WHEN r.Status = '签约' THEN 1 ELSE 0 END) 累计签约套数 ,
        SUM(CASE WHEN r.Status = '签约' THEN CjBldArea ELSE 0 END) 累计签约面积 ,
        SUM(CASE WHEN r.Status = '签约' THEN r.CjRmbTotal ELSE 0 END) / 10000.00 累计签约金额 ,

        -- 本年
        SUM(CASE WHEN r.Status = '签约' and datediff(year,QsDate,getdate()) =0 THEN 1 ELSE 0 END) 本年签约套数,
        SUM(CASE WHEN r.Status = '签约' and datediff(year,QsDate,getdate()) =0 THEN CjBldArea ELSE 0 END) 本年签约面积,
        SUM(CASE WHEN r.Status = '签约' and datediff(year,QsDate,getdate()) =0 THEN r.CjRmbTotal ELSE 0 END) / 10000.00 本年签约金额,
        -- 本月
        SUM(CASE WHEN r.Status = '签约' and datediff(month,QsDate,getdate()) =0 THEN 1 ELSE 0 END) 本月签约套数,
        SUM(CASE WHEN r.Status = '签约' and datediff(month,QsDate,getdate()) =0 THEN CjBldArea ELSE 0 END) 本月签约面积,
        SUM(CASE WHEN r.Status = '签约' and datediff(month,QsDate,getdate()) =0 THEN r.CjRmbTotal ELSE 0 END) / 10000.00 本月签约金额,
        --近一月
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -1, GETDATE()), 121) AND GETDATE() THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 近一月去化货值 ,
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -1, GETDATE()), 121) AND GETDATE() THEN 1 ELSE 0 END) AS 近一月去化套数 ,
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -1, GETDATE()), 121) AND GETDATE() THEN CjBldArea ELSE 0 END) 近一月去化面积 ,
        --近三月
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE() THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 近三月去化货值 ,
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE() THEN 1 ELSE 0 END) AS 近三月去化套数 ,
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE() THEN CjBldArea ELSE 0 END) 近三月去化面积 ,
        --近六月
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE() THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 近六月去化货值 ,
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE() THEN 1 ELSE 0 END) AS 近六月去化套数 ,
        SUM(CASE WHEN r.Status = '签约' AND   r.QsDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE() THEN CjBldArea ELSE 0 END) 近六月去化面积 ,
        SUM(CASE WHEN FangPanTime IS NULL OR r.Status = '签约' THEN 0 ELSE 1 END) 已推未售套数 ,
        SUM(CASE WHEN FangPanTime IS NULL OR r.Status = '签约' THEN 0 ELSE bldarea END) 已推未售面积 ,
        SUM(CASE WHEN FangPanTime IS NULL OR r.Status = '签约' THEN 0 ELSE total END) / 10000.0 已推未售货值 ,
        SUM(CASE WHEN FangPanTime IS NULL AND   r.Status <> '签约' THEN 0 ELSE 1 END) 未推套数 ,
        SUM(CASE WHEN FangPanTime IS NULL AND   r.Status <> '签约' THEN 0 ELSE bldarea END) 未推面积 ,
        SUM(CASE WHEN FangPanTime IS NULL AND   r.Status <> '签约' THEN 0 ELSE total END) / 10000.0 未推货值
INTO    #hx
FROM    [172.16.4.161].highdata_prod.dbo.[data_wide_s_RoomoVerride] r
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_Building] bld ON bld.BuildingGUID = r.BldGUID
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_tb_hnyx_areasection] tb ON bld.TopProductTypeName = tb.业态 AND r.bldarea >= tb.开始面积 AND   r.bldarea < tb.截止面积
        INNER JOIN #p p ON r.parentprojguid = p.projguid
WHERE   r.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY p.projguid ,
         tb.面积段显示名称;

--汇总结果
--业态
SELECT  pj.ProjGUID 项目guid ,
        pj.项目代码 ,
		pj.投管代码,
        pj.公司事业部 ,
        pj.组团 ,
        pj.项目名称 ,
        pj.营销经理 ,
        pj.城市 ,
        pj.项目获取状态 ,
        hz.业态 ,
        SUM(ISNULL(累计签约套数, 0)) AS 累计签约套数 ,
        SUM(ISNULL(累计签约面积, 0)) AS 累计签约面积 ,
        SUM(ISNULL(累计签约金额, 0)) AS 累计签约金额 ,
        SUM(ISNULL(本年签约套数, 0)) AS 本年签约套数 ,
        SUM(ISNULL(本年签约面积, 0)) AS 本年签约面积 ,
        SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额 ,
        SUM(ISNULL(本月签约套数, 0)) AS 本月签约套数 ,
        SUM(ISNULL(本月签约面积, 0)) AS 本月签约面积 ,
        SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额 ,
        SUM(ISNULL(已推未售套数, 0)) AS 已推未售套数 ,
        SUM(ISNULL(已推未售面积, 0)) AS 已推未售面积 ,
        SUM(ISNULL(已推未售货值, 0)) AS 已推未售金额 ,
        SUM(ISNULL(未推套数, 0)) AS 未推货量套数 ,
        SUM(ISNULL(未推面积, 0)) AS 未推货量面积 ,
        SUM(ISNULL(未推货值, 0)) AS 未推货量金额 ,
        SUM(ISNULL(近一月去化套数, 0)) AS 近一个月套数 ,
        SUM(ISNULL(近一月去化面积, 0)) AS 近一个月面积 ,
        SUM(ISNULL(近一月去化货值, 0)) AS 近一个月金额 ,
        SUM(ISNULL(近三月去化套数, 0)) AS 近三个月套数 ,
        SUM(ISNULL(近三月去化面积, 0)) AS 近三个月面积 ,
        SUM(ISNULL(近三月去化货值, 0)) AS 近三个月金额 ,
        SUM(ISNULL(近六月去化套数, 0)) AS 近六个月套数 ,
        SUM(ISNULL(近六月去化面积, 0)) AS 近六个月面积 ,
        SUM(ISNULL(近六月去化货值, 0)) AS 近六个月金额
FROM    #p pj
        INNER JOIN #hz hz ON pj.projguid = hz.projguid
        LEFT JOIN #sale s ON s.projguid = hz.projguid AND  s.指标类型 = hz.业态 AND  s.是否产成品 = hz.是否产成品
GROUP BY pj.ProjGUID ,
         pj.项目代码 ,
		 pj.投管代码,
         pj.公司事业部 ,
         pj.组团 ,
         pj.项目名称 ,
         pj.营销经理 ,
         pj.城市 ,
         pj.项目获取状态 ,
         hz.业态
UNION ALL
SELECT  pj.ProjGUID ,
        pj.项目代码 ,
		pj.投管代码,
        pj.公司事业部 ,
        pj.组团 ,
        pj.项目名称 ,
        pj.营销经理 ,
        pj.城市 ,
        pj.项目获取状态 ,
        '产成品' 指标分类 ,
        SUM(ISNULL(累计签约套数, 0)) AS 累计签约套数 ,
        SUM(ISNULL(累计签约面积, 0)) AS 累计签约面积 ,
        SUM(ISNULL(累计签约金额, 0)) AS 累计签约金额 ,
        SUM(ISNULL(本年签约套数, 0)) AS 本年签约套数 ,
        SUM(ISNULL(本年签约面积, 0)) AS 本年签约面积 ,
        SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额 ,
        SUM(ISNULL(本月签约套数, 0)) AS 本月签约套数 ,
        SUM(ISNULL(本月签约面积, 0)) AS 本月签约面积 ,
        SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额 ,
        SUM(ISNULL(已推未售套数, 0)) AS 已推未售套数 ,
        SUM(ISNULL(已推未售面积, 0)) AS 已推未售面积 ,
        SUM(ISNULL(已推未售货值, 0)) AS 已推未售金额 ,
        SUM(ISNULL(未推套数, 0)) AS 未推货量套数 ,
        SUM(ISNULL(未推面积, 0)) AS 未推货量面积 ,
        SUM(ISNULL(未推货值, 0)) AS 未推货量金额 ,
        SUM(ISNULL(近一月去化套数, 0)) AS 近一个月套数 ,
        SUM(ISNULL(近一月去化面积, 0)) AS 近一个月面积 ,
        SUM(ISNULL(近一月去化货值, 0)) AS 近一个月金额 ,
        SUM(ISNULL(近三月去化套数, 0)) AS 近三个月套数 ,
        SUM(ISNULL(近三月去化面积, 0)) AS 近三个月面积 ,
        SUM(ISNULL(近三月去化货值, 0)) AS 近三个月金额 ,
        SUM(ISNULL(近六月去化套数, 0)) AS 近六个月套数 ,
        SUM(ISNULL(近六月去化面积, 0)) AS 近六个月面积 ,
        SUM(ISNULL(近六月去化货值, 0)) AS 近六个月金额
FROM    #p pj
        INNER JOIN #hz hz ON pj.projguid = hz.projguid
        LEFT JOIN #sale s ON s.projguid = hz.projguid AND  s.指标类型 = hz.业态 AND  s.是否产成品 = hz.是否产成品
WHERE   hz.是否产成品 = 1
GROUP BY pj.projguid ,
         pj.项目代码 ,
		 pj.投管代码,
         pj.公司事业部 ,
         pj.组团 ,
         pj.项目名称 ,
         pj.营销经理 ,
         pj.城市 ,
         pj.项目获取状态  
UNION ALL
SELECT  pj.ProjGUID ,
        pj.项目代码 ,
		pj.投管代码,
        pj.公司事业部 ,
        pj.组团 ,
        pj.项目名称 ,
        pj.营销经理 ,
        pj.城市 ,
        pj.项目获取状态 ,
        hx.指标类型 ,
        SUM(ISNULL(累计签约套数, 0)) AS 累计签约套数 ,
        SUM(ISNULL(累计签约面积, 0)) AS 累计签约面积 ,
        SUM(ISNULL(累计签约金额, 0)) AS 累计签约金额 ,
        SUM(ISNULL(本年签约套数, 0)) AS 本年签约套数 ,
        SUM(ISNULL(本年签约面积, 0)) AS 本年签约面积 ,
        SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额 ,
        SUM(ISNULL(本月签约套数, 0)) AS 本月签约套数 ,
        SUM(ISNULL(本月签约面积, 0)) AS 本月签约面积 ,
        SUM(ISNULL(本月签约金额, 0)) AS 本月签约金额 ,
        SUM(ISNULL(已推未售套数, 0)) AS 已推未售套数 ,
        SUM(ISNULL(已推未售面积, 0)) AS 已推未售面积 ,
        SUM(ISNULL(已推未售货值, 0)) AS 已推未售金额 ,
        SUM(ISNULL(未推套数, 0)) AS 未推货量套数 ,
        SUM(ISNULL(未推面积, 0)) AS 未推货量面积 ,
        SUM(ISNULL(未推货值, 0)) AS 未推货量金额 ,
        SUM(ISNULL(近一月去化套数, 0)) AS 近一个月套数 ,
        SUM(ISNULL(近一月去化面积, 0)) AS 近一个月面积 ,
        SUM(ISNULL(近一月去化货值, 0)) AS 近一个月金额 ,
        SUM(ISNULL(近三月去化套数, 0)) AS 近三个月套数 ,
        SUM(ISNULL(近三月去化面积, 0)) AS 近三个月面积 ,
        SUM(ISNULL(近三月去化货值, 0)) AS 近三个月金额 ,
        SUM(ISNULL(近六月去化套数, 0)) AS 近六个月套数 ,
        SUM(ISNULL(近六月去化面积, 0)) AS 近六个月面积 ,
        SUM(ISNULL(近六月去化货值, 0)) AS 近六个月金额
FROM    #p pj
        INNER JOIN #hx hx ON pj.projguid = hx.ProjGUID
GROUP BY pj.ProjGUID ,
         pj.项目代码 ,
		 pj.投管代码,
         pj.公司事业部 ,
         pj.组团 ,
         pj.项目名称 ,
         pj.营销经理 ,
         pj.城市 ,
         pj.项目获取状态 ,
         hx.指标类型;

DROP TABLE #hz ,
           #p ,
           #sale ,
           #hx;