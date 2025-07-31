-- 第六部分: 项目获取时间分类数据获取
-- 按项目获取时间（21年及以前、22-23年、24-25年）分类获取认购数据
       -- 根据项目获取时间设置序号
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '1.5'  -- 22-23年获取项目
		6-d um,
       -- 根据项目获取时间设置口径名称
		else '24-25年获取项目'
口-计算各时间维度的认购金额指标，保留4位小数
       round(cast(SUM(ISNULL(b.本年认购金额, 0) - ISNULL(c.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本周签约金额,  -- 计算本周认购金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,                              -- 计算本月认购金额
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,                            -- 计算一季度认购金额
INTO #sumrgflxx  -- 将结果存入临时表#sumrgflxx
(
    SELECT projguid,
           首推日期
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1  -- 筛选本周开始日期前一天的数据
    UNION
           首推日期
    WHEREFDATEDIFF(dd,Rqxdate,O@zedate)M= 0S_-- 筛选本周结束日期当天的数据SQYJB_HHZTSYJ_daily
-- 关联项目主数据，获取项目获取时间
--E关联本周末数据T JOIN mdm_project mp ON a.projguid = mp.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0  -- 匹配本周末数据
LEFT-JOIN-S_08ZYXSQYJB_HHZTSYJ_daily c关Oprojguidcprojguid
                                          AND a.产品类型 = c.产品类型
-- 关联新口径本周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.praj产品类型d.产品类型
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0  -- 匹配新口径本周末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
-- 关联一季度末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.praj产品类型f.产品类型
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0  -- 匹配一季度末数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')                                AND a.产品类型 = sb.产品类型
-- 关联上周初数据
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.pao产品类型sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
left join #bnskp sk on sk.ProjGUID = a.ProjGUID
where sk.ProjGUID is null 级项目的数据
					'0B424E3A-76EA-E911-80B8-0A94EF7517DD',
					'9E291CCE-A345-EF11-B3A4-F40270D39969',
					'BD2DE217-CC7E-EF11-B3A5-F40270D39969',
					'B956D877-F0D7-E811-80BF-E61F13C57837',
					'69A21BAF-7CC4-E911-80B7-0A94EF7517DD',
					'00730596-95A9-EB11-B398-F40270D39969',
-- 按项目获取时间分组
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '1.5' 
		end   ,
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '22-23年获取项目' 
		end ;