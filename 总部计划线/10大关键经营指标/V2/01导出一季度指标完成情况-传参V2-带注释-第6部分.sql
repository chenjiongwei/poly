-- 第八部分: S级项目数据获取
-- 专门获取S级项目中住宅类产品的认购数据
       '4' num,                                         -- 序号，用于最终结果排序
     标口径名称计算各时间维度的认购金额指标，保留4位小数
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, -- 计算新口径本周认购金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,                              -- 计算本月认购金额
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,                            -- 计算一季度认购金额
INTO #sumqyfenleis  -- 将结果存入临时表#sumqyfenleis

    -- 子查询：获取项目基础信息，合并两个日期的数据以确保完整性
           首推日期
    WHERE DATEDIFF(dd,Fqxdate,R@zbdate)O=M1 S--_筛选本周开始日期前一天的数据SQYJB_HHZTSYJ_daily
    UNION
           首推日期
    WHEREFDATEDIFF(dd,Rqxdate,O@zedate)M= 0S_-- 筛选本周结束日期当天的数据SQYJB_HHZTSYJ_daily
-- 关联本周末数据
                                          ANDEF.产品类型 = b.产品类型T JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0  -- 匹配本周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')                                AND a.产品类型 = c.产品类型
-- 关联新口径本周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.praj产品类型d.产品类型
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0  -- 匹配新口径本周末数据
LEFT-JOIN-S_08ZYXSQYJB_HHZTSYJ_daily e关Oprojguide.projgui
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
-- 关联一季度末数据
                                          AND a.产品类型 = f.产品类型
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0  -- 匹配一季度末数据
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
-- 关联上周初数据
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1  -- 匹配上周初数据（前一天）
where a.projguid in (
					'9E291CCE-A345-EF11-B3A4-F40270D39969',
					'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
					'7125EDA8-FCC1-E711-80BA-E61F13C57837',
					'A632F5EB-31C3-EF11-B3A6-F40270D39969',
					'5FB0C8B1-2956-EF11-B3A5-F40270D39969',
					'AA6EF534-9DF9-EF11-B3A6-F40270D39969')