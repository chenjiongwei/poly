DECLARE @zbdate DATETIME;
DECLARE @zedate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;
DECLARE @szbdate DATETIME;
DECLARE @szedate DATETIME;
--周日到周六，周日早上导出
SET @zbdate = '2025-07-07';
SET @zedate = '2025-07-13';
SET @newzbdate = '2025-07-07';
SET @newzedate = '2025-07-13';
SET @szbdate = '2025-06-30';
SET @szedate = '2025-07-06';

---SUM(FactAmount1+ FactAmount2 ) / 100000000 AS '本年已发生费用' 这个地方到3月份要加FactAmount3

-----————————————————获取成交数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       10 num,
       '总签约' 口径,
       SUM(ISNULL(b.本年签约金额, 0) - ISNULL(c.本年签约金额, 0)) / 10000 本周签约金额,
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(e.本年签约金额, 0)) / 10000 新本周签约金额,
       SUM(ISNULL(sb.本年签约金额, 0) - ISNULL(sc.本年签约金额, 0)) / 10000 上周签约金额,
       SUM(ISNULL(d.本月签约金额, 0)) / 10000 本月签约金额,
       SUM(ISNULL(f.本年签约金额, 0)) / 10000 一季度签约金额,
       SUM(ISNULL(d.本年签约金额, 0) - ISNULL(f.本年签约金额, 0)) / 10000 二季度签约金额,
       SUM(ISNULL(b.本年签约金额, 0)) / 10000 本年签约金额
INTO #sumqy
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.产品类型 = sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1;


-----————————————————获取成交数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       1 num,
       '总认购' 口径,
       round(cast(SUM(ISNULL(b.本年认购金额, 0) - ISNULL(c.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, ---临时修改本年签约金额
       round(cast(SUM(ISNULL(sb.本年认购金额, 0) - ISNULL(sc.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 上周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 二季度签约金额,
       round(cast(SUM(ISNULL(b.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本年签约金额
INTO #sumrg
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.产品类型 = sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1;

select pp.projguid,min(QSDate) skdate
into #skp
from p_Project pp
left join p_Project p on pp.ProjCode = p.ParentCode
left join s_Order o on o.ProjGUID = p.ProjGUID and (o.Status = '激活' or o.CloseReason = '转签约')
where pp.ApplySys like '%0101%'
group by pp.ProjGUID


select f.ProjGUID,p.skdate 
into #bnskp
from vmdm_projectFlag f 
left join #skp p on f.ProjGUID = p.ProjGUID
where p.skdate >= '2025-01-01'	


SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       case when sk.ProjGUID is not null then 1.1
		when a.projguid in (
						'0B424E3A-76EA-E911-80B8-0A94EF7517DD',
						'1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
						'9E291CCE-A345-EF11-B3A4-F40270D39969',
						'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
						'BD2DE217-CC7E-EF11-B3A5-F40270D39969',
						'7125EDA8-FCC1-E711-80BA-E61F13C57837',
						'B956D877-F0D7-E811-80BF-E61F13C57837',
						'A632F5EB-31C3-EF11-B3A6-F40270D39969',
						'69A21BAF-7CC4-E911-80B7-0A94EF7517DD',
						'5FB0C8B1-2956-EF11-B3A5-F40270D39969',
						'00730596-95A9-EB11-B398-F40270D39969',
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969') then 1.2
		else 1.3 
		end  num,
       case when sk.ProjGUID is not null then '首开项目'
		when a.projguid in (
						'0B424E3A-76EA-E911-80B8-0A94EF7517DD',
						'1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
						'9E291CCE-A345-EF11-B3A4-F40270D39969',
						'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
						'BD2DE217-CC7E-EF11-B3A5-F40270D39969',
						'7125EDA8-FCC1-E711-80BA-E61F13C57837',
						'B956D877-F0D7-E811-80BF-E61F13C57837',
						'A632F5EB-31C3-EF11-B3A6-F40270D39969',
						'69A21BAF-7CC4-E911-80B7-0A94EF7517DD',
						'5FB0C8B1-2956-EF11-B3A5-F40270D39969',
						'00730596-95A9-EB11-B398-F40270D39969',
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969') then 'S级项目'
		else '其他续销项目' 
		end 口径,
       round(cast(SUM(ISNULL(b.本年认购金额, 0) - ISNULL(c.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, ---临时修改本年签约金额
       round(cast(SUM(ISNULL(sb.本年认购金额, 0) - ISNULL(sc.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 上周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 二季度签约金额,
       round(cast(SUM(ISNULL(b.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本年签约金额
INTO #sumrgfl
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.产品类型 = sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1
left join #bnskp sk on sk.ProjGUID = a.ProjGUID
group by case when sk.ProjGUID is not null then 1.1
		when a.projguid in (
						'0B424E3A-76EA-E911-80B8-0A94EF7517DD',
						'1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
						'9E291CCE-A345-EF11-B3A4-F40270D39969',
						'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
						'BD2DE217-CC7E-EF11-B3A5-F40270D39969',
						'7125EDA8-FCC1-E711-80BA-E61F13C57837',
						'B956D877-F0D7-E811-80BF-E61F13C57837',
						'A632F5EB-31C3-EF11-B3A6-F40270D39969',
						'69A21BAF-7CC4-E911-80B7-0A94EF7517DD',
						'5FB0C8B1-2956-EF11-B3A5-F40270D39969',
						'00730596-95A9-EB11-B398-F40270D39969',
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969') then 1.2
		else 1.3 
		end  ,
       case when sk.ProjGUID is not null then '首开项目'
		when a.projguid in (
						'0B424E3A-76EA-E911-80B8-0A94EF7517DD',
						'1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
						'9E291CCE-A345-EF11-B3A4-F40270D39969',
						'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
						'BD2DE217-CC7E-EF11-B3A5-F40270D39969',
						'7125EDA8-FCC1-E711-80BA-E61F13C57837',
						'B956D877-F0D7-E811-80BF-E61F13C57837',
						'A632F5EB-31C3-EF11-B3A6-F40270D39969',
						'69A21BAF-7CC4-E911-80B7-0A94EF7517DD',
						'5FB0C8B1-2956-EF11-B3A5-F40270D39969',
						'00730596-95A9-EB11-B398-F40270D39969',
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969') then 'S级项目'
		else '其他续销项目' 
		end ;	

		
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       case when year(mp.AcquisitionDate) <= 2021 then '1.4'
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '1.5' 
		else '1.6'
		end   num,
       case when year(mp.AcquisitionDate) <= 2021 then '其中：21年及以前获取项目（存量）'
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '22-23年获取项目' 
		else '24-25年获取项目'
		end 口径,
       round(cast(SUM(ISNULL(b.本年认购金额, 0) - ISNULL(c.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, ---临时修改本年签约金额
       round(cast(SUM(ISNULL(sb.本年认购金额, 0) - ISNULL(sc.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 上周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 二季度签约金额,
       round(cast(SUM(ISNULL(b.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本年签约金额
INTO #sumrgflxx
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN mdm_project mp ON a.projguid = mp.projguid
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.产品类型 = sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1
left join #bnskp sk on sk.ProjGUID = a.ProjGUID
where sk.ProjGUID is null 
and a.projguid not in (
						'0B424E3A-76EA-E911-80B8-0A94EF7517DD',
						'1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
						'9E291CCE-A345-EF11-B3A4-F40270D39969',
						'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
						'BD2DE217-CC7E-EF11-B3A5-F40270D39969',
						'7125EDA8-FCC1-E711-80BA-E61F13C57837',
						'B956D877-F0D7-E811-80BF-E61F13C57837',
						'A632F5EB-31C3-EF11-B3A6-F40270D39969',
						'69A21BAF-7CC4-E911-80B7-0A94EF7517DD',
						'5FB0C8B1-2956-EF11-B3A5-F40270D39969',
						'00730596-95A9-EB11-B398-F40270D39969',
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969')
group by case when year(mp.AcquisitionDate) <= 2021 then '1.4'
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '1.5' 
		else '1.6'
		end   ,
       case when year(mp.AcquisitionDate) <= 2021 then '其中：21年及以前获取项目（存量）'
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '22-23年获取项目' 
		else '24-25年获取项目'
		end ;		  

-----————————————————获取成交数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       CASE
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                '3'
           WHEN a.产品类型 = '商业' THEN
                '5'
           WHEN a.产品类型 = '公寓' THEN
                '6'
           WHEN a.产品类型 = '写字楼' THEN
                '7'
           WHEN a.产品类型 = '地下室/车库' THEN
                '8'
           ELSE '9'
       END num,
       CASE
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                '住宅'
           WHEN a.产品类型 = '商业' THEN
                '商业'
           WHEN a.产品类型 = '公寓' THEN
                '公寓'
           WHEN a.产品类型 = '写字楼' THEN
                '写字楼'
           WHEN a.产品类型 = '地下室/车库' THEN
                '车位'
           ELSE '其他'
       END 口径,
       round(cast(SUM(ISNULL(b.本年认购金额, 0) - ISNULL(c.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, ---临时修改本年签约金额
       round(cast(SUM(ISNULL(sb.本年认购金额, 0) - ISNULL(sc.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 上周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 二季度签约金额,
       round(cast(SUM(ISNULL(b.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本年签约金额
INTO #sumqyfenlei
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.产品类型 = sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1
GROUP BY CASE
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                '3'
           WHEN a.产品类型 = '商业' THEN
                '5'
           WHEN a.产品类型 = '公寓' THEN
                '6'
           WHEN a.产品类型 = '写字楼' THEN
                '7'
           WHEN a.产品类型 = '地下室/车库' THEN
                '8'
           ELSE '9'
       END ,
       CASE
           WHEN a.产品类型 IN ( '住宅', '高级住宅' ) THEN
                '住宅'
           WHEN a.产品类型 = '商业' THEN
                '商业'
           WHEN a.产品类型 = '公寓' THEN
                '公寓'
           WHEN a.产品类型 = '写字楼' THEN
                '写字楼'
           WHEN a.产品类型 = '地下室/车库' THEN
                '车位'
           ELSE '其他'
       END;


SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       '4' num,
       '其中：S级项目' 口径,
       round(cast(SUM(ISNULL(b.本年认购金额, 0) - ISNULL(c.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(e.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 新本周签约金额, ---临时修改本年签约金额
       round(cast(SUM(ISNULL(sb.本年认购金额, 0) - ISNULL(sc.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 上周签约金额,  ---临时修改本年签约金额
       round(cast(SUM(ISNULL(d.本月认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本月签约金额,
       round(cast(SUM(ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 一季度签约金额,
       round(cast(SUM(ISNULL(d.本年认购金额, 0) - ISNULL(f.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 二季度签约金额,
       round(cast(SUM(ISNULL(b.本年认购金额, 0)) / 10000.00 as decimal(18,4)),4) 本年签约金额
INTO #sumqyfenleis
FROM
(
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.产品类型 = d.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(d.首推日期, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.产品类型 = e.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(e.首推日期, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.产品类型 = f.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(f.首推日期, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.产品类型 = sb.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sb.首推日期, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.产品类型 = sc.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(sc.首推日期, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1
where a.projguid in (
						'0B424E3A-76EA-E911-80B8-0A94EF7517DD',
						'1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
						'9E291CCE-A345-EF11-B3A4-F40270D39969',
						'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
						'BD2DE217-CC7E-EF11-B3A5-F40270D39969',
						'7125EDA8-FCC1-E711-80BA-E61F13C57837',
						'B956D877-F0D7-E811-80BF-E61F13C57837',
						'A632F5EB-31C3-EF11-B3A6-F40270D39969',
						'69A21BAF-7CC4-E911-80B7-0A94EF7517DD',
						'5FB0C8B1-2956-EF11-B3A5-F40270D39969',
						'00730596-95A9-EB11-B398-F40270D39969',
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969')
and a.产品类型 IN ( '住宅', '高级住宅' ) 




--本日销售毛利率
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       12 num,
       '全年签约净利率' 口径,
       CASE
           WHEN ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) > 0 THEN
       (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / (ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
           ELSE 0
       END 本周签约金额,
       CASE
           WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0) > 0 THEN
       (ISNULL(c.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0))
           ELSE 0
       END 新本周签约金额,
       CASE
           WHEN ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0) > 0 THEN
       (ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0)) / (ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0))
           ELSE 0
       END 上周签约金额,
       CASE
           WHEN ISNULL(c.本月签约金额不含税, 0) > 0 THEN
                ISNULL(c.本月净利润签约, 0) / ISNULL(c.本月签约金额不含税, 0)
           ELSE 0
       END 本月签约金额,
       CASE
           WHEN ISNULL(e.本年签约金额不含税, 0) > 0 THEN
                ISNULL(e.本年净利润签约, 0) / ISNULL(e.本年签约金额不含税, 0)
           ELSE 0
       END 一季度签约金额,
       CASE
           WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0) > 0 THEN
       (ISNULL(c.本年净利润签约, 0) - ISNULL(e.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0))
           ELSE 0
       END 二季度签约金额,
       CASE
           WHEN ISNULL(a.本年签约金额不含税, 0) > 0 THEN
                ISNULL(a.本年净利润签约, 0) / ISNULL(a.本年签约金额不含税, 0)
           ELSE 0
       END 本年销净率
INTO #sumxjl
FROM
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
) a
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
) b ON a.buguid = b.buguid
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
) c ON a.buguid = c.buguid
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
) d ON a.buguid = d.buguid
LEFT JOIN 
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
) e ON a.buguid = e.buguid
LEFT JOIN 
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @szedate) = 0
) sa ON a.buguid = sa.buguid
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New
    WHERE DATEDIFF(DAY, qxdate, @szbdate) = 1
) sb ON a.buguid = sb.buguid;


--本日销售毛利率
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       '13' num,
       '不合理巨亏项目对应亏损净利润金额' 口径,
       sum(case when 
		   CASE
			   WHEN ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0)) / (ISNULL(a.本年签约金额不含税, 0) - ISNULL(b.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(a.本年净利润签约, 0) - ISNULL(b.本年净利润签约, 0))	   
	   else 0 end) 本周签约金额,
       sum(case when 
		   CASE
			   WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(c.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(d.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(c.本年净利润签约, 0) - ISNULL(d.本年净利润签约, 0))
	   else 0 end) 新本周签约金额,
       sum(case when 
		   CASE
			   WHEN ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0)) / (ISNULL(sa.本年签约金额不含税, 0) - ISNULL(sb.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(sa.本年净利润签约, 0) - ISNULL(sb.本年净利润签约, 0))	   
	   else 0 end) 上周签约金额,
       sum(case when 
		   CASE
			   WHEN ISNULL(c.本月签约金额不含税, 0) > 0 THEN
					ISNULL(c.本月净利润签约, 0) / ISNULL(c.本月签约金额不含税, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(c.本月净利润签约, 0)
	   else 0 end) 本月签约金额,
       sum(case when 
		   CASE
			   WHEN ISNULL(e.本年签约金额不含税, 0) > 0 THEN
					ISNULL(e.本年净利润签约, 0) / ISNULL(e.本年签约金额不含税, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(e.本年净利润签约, 0)
	   else 0 end) 一季度签约金额,
       sum(case when 
		   CASE
			   WHEN ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0) > 0 THEN
		   (ISNULL(c.本年净利润签约, 0) - ISNULL(e.本年净利润签约, 0)) / (ISNULL(c.本年签约金额不含税, 0) - ISNULL(e.本年签约金额不含税, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(c.本年净利润签约, 0) - ISNULL(e.本年净利润签约, 0))
	   else 0 end) 二季度签约金额,
       sum(case when 
		   CASE
			   WHEN ISNULL(a.本年签约金额不含税, 0) > 0 THEN
					ISNULL(a.本年净利润签约, 0) / ISNULL(a.本年签约金额不含税, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(a.本年净利润签约, 0)
	   else 0 end) 本年销净率
INTO #sumjk
FROM
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0 
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) a
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) b ON a.ProjGUID = b.ProjGUID
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) c ON a.ProjGUID = c.ProjGUID
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) d ON a.ProjGUID = d.ProjGUID
LEFT JOIN 
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) e ON a.ProjGUID = e.ProjGUID
LEFT JOIN 
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @szedate) = 0 
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) sa ON a.ProjGUID = sa.ProjGUID
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(本月签约金额不含税) 本月签约金额不含税,
           SUM(本月净利润签约) 本月净利润签约,
           SUM(本年签约金额不含税) 本年签约金额不含税,
           SUM(本年净利润签约) 本年净利润签约
    FROM s_M002项目级毛利净利汇总表New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @szbdate) = 1
	and ISNULL(f.特定项目标签, '') <> '合理'
	group by a.ProjGUID
) sb ON a.ProjGUID = sb.ProjGUID;

--————————————————————————————营销费用————————————————————————————————

--年度预算&年度发生（费用签约）已筛公司、预算范围			
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(FactAmount1 + FactAmount2 + FactAmount3 ) / 100000000 AS '一季度已发生费用',
       SUM(FactAmount4 + FactAmount5) / 100000000 AS '二季度已发生费用',
       SUM(FactAmount1 + FactAmount2 + FactAmount3 +FactAmount4 +FactAmount5) / 100000000 AS '本年已发生费用'
--SUM(FactAmount1 + FactAmount2 + FactAmount3 + FactAmount4 + FactAmount5 + FactAmount6 + FactAmount7
--    + FactAmount8 + FactAmount9 + FactAmount10 + FactAmount11 + FactAmount12
--   ) / 100000000 AS '本年已发生费用'
INTO #fy
FROM MyCost_Erp352.dbo.ys_YearPlanDept2Cost a
     INNER JOIN MyCost_Erp352.dbo.ys_DeptCost b ON b.DeptCostGUID = a.costguid
                                                   AND a.YEAR = b.YEAR
     INNER JOIN MyCost_Erp352.dbo.ys_SpecialBusinessUnit u ON a.DeptGUID = u.SpecialUnitGUID
     INNER JOIN MyCost_Erp352.dbo.ys_fy_DimCost dim ON dim.costguid = a.costguid
                                                       AND dim.year = a.year
                                                       AND dim.IsEndCost = 1
WHERE a.year = YEAR(GETDATE())
      AND b.costtype = '营销类';


SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       11 num,
       '营销费率' 口径,
       0 本周费率,
       0 新本周费率,
       0 上周费率,
       0 本月费率,
       CASE
           WHEN q.一季度签约金额 > 0 THEN
                f.[一季度已发生费用] / q.一季度签约金额
           ELSE 0
       END 一季度费率,
       CASE
           WHEN q.二季度签约金额 > 0 THEN
                f.[二季度已发生费用] / q.二季度签约金额
           ELSE 0
       END 二季度费率,
       CASE
           WHEN q.本年签约金额 > 0 THEN
                f.[本年已发生费用] / q.本年签约金额
           ELSE 0
       END 本年费率
INTO #sumfeiyong
FROM mybusinessunit bu
     LEFT JOIN #fy f ON bu.buguid = f.buguid
     LEFT JOIN #sumqy q ON bu.buguid = q.buguid
WHERE bu.buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23';




    BEGIN
        --declare	 @var_jgdate date=@zedate
        --缓存项目
        SELECT  p.ProjGUID ,
                p.ProjCode
        INTO    #p
        FROM    mdm_Project p
        WHERE   1 = 1
                --AND p.ProjCode='4690004'
                AND p.Level = 2 
				--AND p.DevelopmentCompanyGUID IN(SELECT  Value FROM  fn_Split2(@var_buguid, ',') );

        --缓存楼栋
        SELECT  a.SaleBldGUID ,
				A.DevelopmentCompanyGUID,
                a.GCBldGUID ,
                a.ProjGUID ,
                CONVERT(VARCHAR(MAX), p.ProjCode) + '_' + a.ProductType + '_' + a.ProductName + '_' + a.BusinessType + '_' + a.Standard Product ,
                a.ProductType ,
                a.ProductName ,
                a.BusinessType ,
                a.Standard ,
                a.IsSale ,
                a.IsHold ,
                a.BldCode ,
                a.SJkpxsDate ,
                a.YJjgbadate ,
                a.SJjgbadate ,
                a.zksmj ,
                a.ysmj ,
                a.zksts ,
                a.ysts ,
                a.zhz ,
                a.ysje ,
                a.syhz ,
                a.YcPrice ,
                a.qyjj ,
                a.BeginYearSaleJe ,
                a.BeginYearSaleMj ,
                a.BeginYearSaleTs,
				case when datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 then '产成品'
				 when datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 then '准产成品'
				 else '其他' end isccp
        INTO    #db
        FROM    p_lddbamj a
                INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
        WHERE   DATEDIFF(DAY, a.QXDate, getdate()) = 0
		and 
		(datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 --产成品，实际竣工备案时间在往年
		 or 
		 (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ) --准产成品，实际竣工或计划竣工在本年
		)
		;

        SELECT  r.RoomGUID ,
                r.ProjGUID fqprojguid ,
                r.BldGUID ,
                r.ThDate
        INTO    #room
        FROM    p_room r
                INNER JOIN #db d ON r.BldGUID = d.SaleBldGUID
        WHERE   r.Status = '签约' AND EXISTS (SELECT  1
                                            FROM    s_Contract c
                                            WHERE   c.Status = '激活' AND YEAR(c.QSDate) = YEAR(@zedate) AND c.RoomGUID = r.RoomGUID);

        --税率
        SELECT  DISTINCT vt.ProjGUID ,
                         VATRate ,
                         RoomGUID
        INTO    #vrt
        FROM    s_VATSet vt
                INNER JOIN #room r ON vt.ProjGUID = r.fqprojguid
        WHERE   VATScope = '整个项目' AND   AuditState = 1 AND  RoomGUID NOT IN(SELECT  DISTINCT vtr.RoomGUID
                                                                            FROM    s_VATSet vt ---------  
                                                                                    INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
                                                                                    INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
                                                                            WHERE   VATScope = '特定房间' AND   AuditState = 1)
        UNION ALL
        SELECT  DISTINCT vt.ProjGUID ,
                         vt.VATRate ,
                         vtr.RoomGUID
        FROM    s_VATSet vt ---------  
                INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
                INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
        WHERE   VATScope = '特定房间' AND   AuditState = 1;

        --签约
        SELECT  r.BldGUID salebldguid ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN r.BldArea ELSE 0  END) BzMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN 1 END) BzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) BzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) BzJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN r.BldArea ELSE 0  END) newBzMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN 1 END) newBzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) newBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) newBzJeNotax ,
				
				
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN r.BldArea ELSE 0  END) sBzMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN 1 END) sBzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) sBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) sBzJeNotax ,
				
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN r.BldArea ELSE 0  END) ByMJ ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN 1 END) ByTs ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) ByJe ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) ByJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN r.BldArea ELSE 0  END) yjdMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN 1 END) yjdTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) yjdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) yjdJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN r.BldArea ELSE 0  END) ejdMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN 1 END) ejdTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) ejdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) ejdJeNotax ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN r.BldArea ELSE 0 END ) BnMJ ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN 1 ELSE 0 END ) BnTs ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN  (a.JyTotal + ISNULL(f.amount, 0)) ELSE 0 END ) BnJe ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN  (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END ) BnJeNotax
        INTO    #con
        FROM    s_Contract a
                INNER JOIN p_room r ON a.RoomGUID = r.RoomGUID
                LEFT JOIN s_Order d ON a.TradeGUID = d.TradeGUID AND   ISNULL(d.CloseReason, '') = '转签约'
                LEFT JOIN(SELECT    TradeGUID ,
                                    SUM(Amount) amount
                          FROM  s_Fee f
                          WHERE ItemName LIKE '%补差%'
                          GROUP BY TradeGUID) f ON a.TradeGUID = f.TradeGUID
                LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
        WHERE   a.Status = '激活' AND YEAR(a.QSDate) = YEAR(@zedate) AND EXISTS (SELECT 1 FROM  #db db WHERE db.SaleBldGUID = r.BldGUID)
                AND NOT EXISTS (SELECT  1
                                FROM    dbo.S_PerformanceAppraisalRoom sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '已审核' AND   s.YjType not in ('经营类(溢价款)','物业公司车位代销')
                                WHERE  r.RoomGUID = sr.RoomGUID)
                AND   NOT EXISTS (SELECT    1
                                  FROM  dbo.S_PerformanceAppraisalBuildings sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '已审核' AND  s.YjType not in ('经营类(溢价款)','物业公司车位代销')
                                  WHERE   r.BldGUID = sr.BldGUID)
        GROUP BY r.BldGUID;
		

        --认购
        SELECT  r.BldGUID salebldguid ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN r.BldArea ELSE 0  END) BzMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN 1 END) BzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) BzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @zbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @zedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) BzJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN r.BldArea ELSE 0  END) newBzMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN 1 END) newBzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) newBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @newzedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) newBzJeNotax ,
				
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN r.BldArea ELSE 0  END) sBzMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN 1 END) sBzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) sBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, @szbdate) <= 0 and DATEDIFF(DAY, a.QSDate, @szedate) >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) sBzJeNotax ,
				
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN r.BldArea ELSE 0  END) ByMJ ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN 1 END) ByTs ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) ByJe ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.QSDate, @zedate) = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) ByJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN r.BldArea ELSE 0  END) yjdMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN 1 END) yjdTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) yjdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-03-31') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) yjdJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN r.BldArea ELSE 0  END) ejdMJ ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN 1 END) ejdTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0))ELSE 0 END) ejdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.QSDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.QSDate, '2025-06-30') >= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)ELSE 0 END) ejdJeNotax ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN r.BldArea ELSE 0 END ) BnMJ ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN 1 ELSE 0 END ) BnTs ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN  (a.JyTotal + ISNULL(f.amount, 0)) ELSE 0 END ) BnJe ,
                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @zedate) = 0 THEN  (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END ) BnJeNotax
        INTO    #ord
        FROM    s_Order a
                INNER JOIN p_room r ON a.RoomGUID = r.RoomGUID
                LEFT JOIN s_Contract d ON a.TradeGUID = d.TradeGUID AND   ISNULL(a.CloseReason, '') = '转签约' and d.Status = '激活'
                LEFT JOIN(SELECT    TradeGUID ,
                                    SUM(Amount) amount
                          FROM  s_Fee f
                          WHERE ItemName LIKE '%补差%'
                          GROUP BY TradeGUID) f ON a.TradeGUID = f.TradeGUID
                LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
        WHERE   (a.Status = '激活' or (a.CloseReason ='转签约' and d.Status = '激活')) AND YEAR(a.QSDate) = YEAR(@zedate) AND EXISTS (SELECT 1 FROM  #db db WHERE db.SaleBldGUID = r.BldGUID)
                AND NOT EXISTS (SELECT  1
                                FROM    dbo.S_PerformanceAppraisalRoom sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '已审核' AND   s.YjType not in ('经营类(溢价款)','物业公司车位代销')
                                WHERE  r.RoomGUID = sr.RoomGUID)
                AND   NOT EXISTS (SELECT    1
                                  FROM  dbo.S_PerformanceAppraisalBuildings sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '已审核' AND  s.YjType not in ('经营类(溢价款)','物业公司车位代销')
                                  WHERE   r.BldGUID = sr.BldGUID)
        GROUP BY r.BldGUID;

        --设置税率表
        SELECT  CONVERT(DATE, '1999-01-01') AS bgnDate ,
                CONVERT(DATE, '2016-03-31') AS endDate ,
                0 AS rate
        INTO    #tmp_tax UNION ALL
        SELECT  CONVERT(DATE, '2016-04-01') AS bgnDate ,
                CONVERT(DATE, '2018-04-30') AS endDate ,
                0.11 AS rate
        UNION ALL
        SELECT  CONVERT(DATE, '2018-05-01') AS bgnDate ,
                CONVERT(DATE, '2019-03-31') AS endDate ,
                0.1 AS rate
        UNION ALL
        SELECT  CONVERT(DATE, '2019-04-01') AS bgnDate ,
                CONVERT(DATE, '2099-01-01') AS endDate ,
                0.09 AS rate;

        --合作业绩
        SELECT  c.ProjGUID ,
                CONVERT(DATE, b.DateYear + '-' + b.DateMonth + '-27') AS [BizDate] ,
                b.*
        INTO    #hzyj
        FROM    s_YJRLProducteDetail b
                INNER JOIN s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
                INNER JOIN #p mp ON c.ProjGUID = mp.ProjGUID
        WHERE   b.Shenhe = '审核';

        SELECT  db.SaleBldGUID ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @zbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @zedate) >= 0 THEN b.Taoshu END) BzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @zbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @zedate) >= 0 THEN b.Area END) BzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @zbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @zedate) >= 0 THEN b.Amount END) * 10000 Bzje ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @zbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @zedate) >= 0 THEN b.Amount / (1 + tax.rate)END) * 10000 BzJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @newzedate) >= 0 THEN b.Taoshu END) newBzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @newzedate) >= 0 THEN b.Area END) newBzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @newzedate) >= 0 THEN b.Amount END) * 10000 newBzje ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @newzedate) >= 0 THEN b.Amount / (1 + tax.rate)END) * 10000 newBzJeNotax ,
				
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @szbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @szedate) >= 0 THEN b.Taoshu END) sBzTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @szbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @szedate) >= 0 THEN b.Area END) sBzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @szbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @szedate) >= 0 THEN b.Amount END) * 10000 sBzje ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, @szbdate) <= 0 and DATEDIFF(DAY, a.BizDate, @szedate) >= 0 THEN b.Amount / (1 + tax.rate)END) * 10000 sBzJeNotax ,
				
                SUM(CASE WHEN DATEDIFF(MONTH, a.BizDate, @zedate) = 0 THEN b.Taoshu END) ByTs ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.BizDate, @zedate) = 0 THEN b.Area END) ByMj ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.BizDate, @zedate) = 0 THEN b.Amount END) * 10000 Byje ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.BizDate, @zedate) = 0 THEN b.Amount / (1 + tax.rate)END) * 10000 ByJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-03-31') >= 0 THEN b.Taoshu END) yjdTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-03-31') >= 0 THEN b.Area END) yjdMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-03-31') >= 0 THEN b.Amount END) * 10000 yjdje ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-03-31') >= 0 THEN b.Amount / (1 + tax.rate)END) * 10000 yjdJeNotax ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-06-30') >= 0 THEN b.Taoshu END) ejdTs ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-06-30') >= 0 THEN b.Area END) ejdMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-06-30') >= 0 THEN b.Amount END) * 10000 ejdje ,
                SUM(CASE WHEN DATEDIFF(DAY, a.BizDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.BizDate, '2025-06-30') >= 0 THEN b.Amount / (1 + tax.rate)END) * 10000 ejdJeNotax ,
                SUM(CASE WHEN DATEDIFF(yy, a.BizDate, @zedate) = 0 THEN  b.Taoshu ELSE 0 END ) BnTs ,
                SUM(CASE WHEN DATEDIFF(yy, a.BizDate, @zedate) = 0 THEN  b.Area ELSE 0 END ) BnMj ,
                SUM(CASE WHEN DATEDIFF(yy, a.BizDate, @zedate) = 0 THEN  b.Amount ELSE 0 END ) * 10000 BnJe ,
                SUM(CASE WHEN DATEDIFF(yy, a.BizDate, @zedate) = 0 THEN  b.Amount / (1 + tax.rate) ELSE 0 END )*10000 BnJeNotax
        INTO    #h
        FROM    #hzyj a
                INNER JOIN s_YJRLBuildingDescript b ON a.ProducteDetailGUID = b.ProducteDetailGUID
                INNER JOIN #db db ON b.BldGUID = db.SaleBldGUID
                LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.BizDate, tax.bgnDate) <= 0 AND   DATEDIFF(DAY, a.BizDate, tax.endDate) >= 0
        GROUP BY db.SaleBldGUID;

        --特殊业绩
        SELECT  a.* ,
                a.TotalAmount / (1 + tax.rate) TotalAmountnotax ,
                tax.rate
        INTO    #s_PerformanceAppraisal
        FROM    S_PerformanceAppraisal a
                INNER JOIN #p mp ON a.ManagementProjectGUID = mp.ProjGUID
                LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.RdDate, tax.bgnDate) <= 0 AND DATEDIFF(DAY, a.RdDate, tax.endDate) >= 0;

        SELECT  db.SaleBldGUID ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.AffirmationNumber ELSE 0 END) BzTs ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.areatotal ELSE 0 END) BzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.totalamount ELSE 0 END) * 10000 BzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 BzJeNotax ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.AffirmationNumber ELSE 0 END) newBzTs ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.areatotal ELSE 0 END) newBzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.totalamount ELSE 0 END) * 10000 newBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 newBzJeNotax ,
				
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.AffirmationNumber ELSE 0 END) sBzTs ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.areatotal ELSE 0 END) sBzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.totalamount ELSE 0 END) * 10000 sBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 sBzJeNotax ,
				
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.AffirmationNumber ELSE 0 END) ByTs ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.areatotal ELSE 0 END) ByMj ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.totalamount ELSE 0 END) * 10000 ByJe ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 ByJeNotax ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.AffirmationNumber ELSE 0 END) yjdTs ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.areatotal ELSE 0 END) yjdMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.totalamount ELSE 0 END) * 10000 yjdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 yjdJeNotax ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.AffirmationNumber ELSE 0 END) ejdTs ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.areatotal ELSE 0 END) ejdMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.totalamount ELSE 0 END) * 10000 ejdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 ejdJeNotax ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)') AND  DATEDIFF(yy, a.RdDate, @zedate) = 0  THEN b.AffirmationNumber ELSE 0 END) BNTs ,
                SUM(CASE WHEN (a.YjType <> '经营类(溢价款)')  AND  DATEDIFF(yy, a.RdDate, @zedate) = 0  THEN b.areatotal ELSE 0 END) BNMj ,
                SUM(CASE WHEN DATEDIFF(yy, a.RdDate, @zedate) = 0  THEN  b.totalamount ELSE 0 END ) * 10000 BNJe ,
                SUM(CASE WHEN DATEDIFF(yy, a.RdDate, @zedate) = 0  THEN  b.totalamount / (1 + a.rate) ELSE 0 END ) * 10000 BNJeNotax
        INTO    #t
        FROM    #s_PerformanceAppraisal a
                INNER JOIN(SELECT   PerformanceAppraisalGUID ,
                                    BldGUID ,
                                    AffirmationNumber ,
                                    IdentifiedArea areatotal ,
                                    AmountDetermined totalamount
                           FROM dbo.S_PerformanceAppraisalBuildings
                           UNION ALL
                           SELECT   PerformanceAppraisalGUID ,
                                    r.ProductBldGUID BldGUID ,
                                    SUM(1) AffirmationNumber ,
                                    SUM(a.IdentifiedArea) ,
                                    SUM(a.AmountDetermined)
                           FROM dbo.S_PerformanceAppraisalRoom a
                                LEFT JOIN MyCost_Erp352.dbo.md_Room r ON a.RoomGUID = r.RoomGUID
                           GROUP BY PerformanceAppraisalGUID ,
                                    r.ProductBldGUID) b ON a.PerformanceAppraisalGUID = b.PerformanceAppraisalGUID
                INNER JOIN #db db ON b.BldGUID = db.SaleBldGUID
        WHERE   1 = 1 AND   YEAR(a.RdDate) = YEAR(@zedate) AND a.AuditStatus = '已审核' AND  a.YjType IN(SELECT  TsyjTypeName FROM   s_TsyjType WHERE IsRelatedBuildingsRoom = 1)
                AND a.YjType IN ('整体销售', '其他销售', '经营类(溢价款)', '回购', '包销', '代建类','物业公司车位代销')
        GROUP BY db.SaleBldGUID;

        --取手工维护的匹配关系
        SELECT  项目guid ,
                T.基础数据主键 ,
                CASE WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN T.盈利规划系统自动匹对主键 ELSE CASE WHEN ISNULL(T.盈利规划主键, '') <> '' THEN T.盈利规划主键 ELSE T.基础数据主键 END END 盈利规划主键
        INTO    #key
        FROM    dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 T
                INNER JOIN(SELECT   ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM ,
                                    FillHistoryGUID
                           FROM dss.dbo.nmap_F_FillHistory a
                           WHERE   EXISTS (SELECT   1
                                           FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 b
                                           WHERE   a.FillHistoryGUID = b.FillHistoryGUID)) V ON T.FillHistoryGUID = V.FillHistoryGUID AND  V.NUM = 1
		where isnull(t.项目guid,'')<>''; --ltx造孽 2023-08-02

        SELECT  db.SaleBldGUID ,
                db.ProjGUID ,
                db.Product MyProduct ,
                ISNULL(dss.盈利规划主键, db.Product) Product ,
                SUM(s.BzTs) BzTs ,
                SUM(s.BzMj) BzMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.BzTs ELSE s.BzMj END) BzmjNew ,
                SUM(s.BzJe) Bzje ,
                SUM(s.BzJeNotax) BzJeNotax ,
                SUM(s.newBzTs) newBzTs ,
                SUM(s.newBzMj) newBzMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.newBzTs ELSE s.newBzMj END) newBzmjNew ,
                SUM(s.newBzJe) newBzje ,
                SUM(s.newBzJeNotax) newBzJeNotax ,
				
                SUM(s.sBzTs) sBzTs ,
                SUM(s.sBzMj) sBzMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.sBzTs ELSE s.sBzMj END) sBzmjNew ,
                SUM(s.sBzJe) sBzje ,
                SUM(s.sBzJeNotax) sBzJeNotax ,
				
                SUM(s.ByTs) ByTs ,
                SUM(s.ByMJ) ByMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.ByTs ELSE s.ByMJ END) BymjNew ,
                SUM(s.ByJe) Byje ,
                SUM(s.ByJeNotax) ByJeNotax ,
                SUM(s.yjdTs) yjdTs ,
                SUM(s.yjdMj) yjdMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.yjdTs ELSE s.yjdMj END) yjdmjNew ,
                SUM(s.yjdJe) yjdJe ,
                SUM(s.yjdJeNotax) yjdJeNotax ,
                SUM(s.ejdTs) ejdTs ,
                SUM(s.ejdMj) ejdMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.ejdTs ELSE s.ejdMj END) ejdmjNew ,
                SUM(s.ejdJe) ejdJe ,
                SUM(s.ejdJeNotax) ejdJeNotax ,
                SUM(s.BnTs) BnTs ,
                SUM(s.BnMJ) BnMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.BnTs ELSE s.BnMJ END) BNmjNew ,
                SUM(s.BnJe) BnJe ,
                SUM(s.BnJeNotax) BnJeNotax
        INTO    #sale
        FROM    #db db
                LEFT JOIN(SELECT    a.salebldguid ,
                                    a.BzTs ,
                                    a.BzMJ ,
                                    a.BzJe ,
                                    a.BzJeNotax ,
                                    a.newBzTs ,
                                    a.newBzMJ ,
                                    a.newBzJe ,
                                    a.newBzJeNotax ,
                                    a.sBzTs ,
                                    a.sBzMJ ,
                                    a.sBzJe ,
                                    a.sBzJeNotax ,
                                    a.ByTs ,
                                    a.ByMJ ,
                                    a.ByJe ,
                                    a.ByJeNotax ,
                                    a.yjdTs ,
                                    a.yjdMJ ,
                                    a.yjdJe ,
                                    a.yjdJeNotax ,
                                    a.ejdTs ,
                                    a.ejdMJ ,
                                    a.ejdJe ,
                                    a.ejdJeNotax ,
                                    a.BnTs ,
                                    a.BnMJ ,
                                    a.BnJe ,
                                    a.BnJeNotax
                          FROM  #con a
                          UNION ALL
                          SELECT    a.SaleBldGUID ,
                                    a.BzTs ,
                                    a.BzMJ ,
                                    a.BzJe ,
                                    a.BzJeNotax ,
                                    a.newBzTs ,
                                    a.newBzMJ ,
                                    a.newBzJe ,
                                    a.newBzJeNotax ,
                                    a.sBzTs ,
                                    a.sBzMJ ,
                                    a.sBzJe ,
                                    a.sBzJeNotax ,
                                    a.ByTs ,
                                    a.ByMj ,
                                    a.Byje ,
                                    a.ByJeNotax ,
                                    a.yjdTs ,
                                    a.yjdMJ ,
                                    a.yjdJe ,
                                    a.yjdJeNotax ,
                                    a.ejdTs ,
                                    a.ejdMJ ,
                                    a.ejdJe ,
                                    a.ejdJeNotax ,
                                    a.BnTs ,
                                    a.BnMj ,
                                    a.BnJe ,
                                    a.BnJeNotax
                          FROM  #h a
                          UNION ALL
                          SELECT    a.SaleBldGUID ,
                                    a.BzTs ,
                                    a.BzMJ ,
                                    a.BzJe ,
                                    a.BzJeNotax ,
                                    a.newBzTs ,
                                    a.newBzMJ ,
                                    a.newBzJe ,
                                    a.newBzJeNotax ,
                                    a.sBzTs ,
                                    a.sBzMJ ,
                                    a.sBzJe ,
                                    a.sBzJeNotax ,
                                    a.ByTs ,
                                    a.ByMj ,
                                    a.Byje ,
                                    a.ByJeNotax ,
                                    a.yjdTs ,
                                    a.yjdMJ ,
                                    a.yjdJe ,
                                    a.yjdJeNotax ,
                                    a.ejdTs ,
                                    a.ejdMJ ,
                                    a.ejdJe ,
                                    a.ejdJeNotax ,
                                    a.BNTs ,
                                    a.BNMj ,
                                    a.BNJe ,
                                    a.BNJeNotax
                          FROM  #t a) s ON s.salebldguid = db.SaleBldGUID
                LEFT JOIN(SELECT    DISTINCT k.项目guid, k.基础数据主键, k.盈利规划主键 FROM  #key k) dss ON dss.项目guid = db.ProjGUID AND dss.基础数据主键 = db.Product  --业态匹配
        GROUP BY db.SaleBldGUID ,
                 db.Product ,
                 ISNULL(dss.盈利规划主键, db.Product) ,
                 db.ProjGUID;


        SELECT  db.SaleBldGUID ,
                db.ProjGUID ,
                db.Product MyProduct ,
                ISNULL(dss.盈利规划主键, db.Product) Product ,
				db.isccp,
                SUM(s.BzTs) BzTs ,
                SUM(s.BzMj) BzMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.BzTs ELSE s.BzMj END) BzmjNew ,
                SUM(s.BzJe) Bzje ,
                SUM(s.BzJeNotax) BzJeNotax ,
                SUM(s.newBzTs) newBzTs ,
                SUM(s.newBzMj) newBzMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.newBzTs ELSE s.newBzMj END) newBzmjNew ,
                SUM(s.newBzJe) newBzje ,
                SUM(s.newBzJeNotax) newBzJeNotax ,
				
                SUM(s.sBzTs) sBzTs ,
                SUM(s.sBzMj) sBzMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.sBzTs ELSE s.sBzMj END) sBzmjNew ,
                SUM(s.sBzJe) sBzje ,
                SUM(s.sBzJeNotax) sBzJeNotax ,
				
                SUM(s.ByTs) ByTs ,
                SUM(s.ByMJ) ByMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.ByTs ELSE s.ByMJ END) BymjNew ,
                SUM(s.ByJe) Byje ,
                SUM(s.ByJeNotax) ByJeNotax ,
                SUM(s.yjdTs) yjdTs ,
                SUM(s.yjdMj) yjdMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.yjdTs ELSE s.yjdMj END) yjdmjNew ,
                SUM(s.yjdJe) yjdJe ,
                SUM(s.yjdJeNotax) yjdJeNotax ,
                SUM(s.ejdTs) ejdTs ,
                SUM(s.ejdMj) ejdMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.ejdTs ELSE s.ejdMj END) ejdmjNew ,
                SUM(s.ejdJe) ejdJe ,
                SUM(s.ejdJeNotax) ejdJeNotax ,
                SUM(s.BnTs) BnTs ,
                SUM(s.BnMJ) BnMj ,
                SUM(CASE WHEN db.ProductType = '地下室/车库' THEN s.BnTs ELSE s.BnMJ END) BNmjNew ,
                SUM(s.BnJe) BnJe ,
                SUM(s.BnJeNotax) BnJeNotax
        INTO    #saleord
        FROM    #db db
                LEFT JOIN(SELECT    a.salebldguid ,
                                    a.BzTs ,
                                    a.BzMJ ,
                                    a.BzJe ,
                                    a.BzJeNotax ,
                                    a.newBzTs ,
                                    a.newBzMJ ,
                                    a.newBzJe ,
                                    a.newBzJeNotax ,
                                    a.sBzTs ,
                                    a.sBzMJ ,
                                    a.sBzJe ,
                                    a.sBzJeNotax ,
                                    a.ByTs ,
                                    a.ByMJ ,
                                    a.ByJe ,
                                    a.ByJeNotax ,
                                    a.yjdTs ,
                                    a.yjdMJ ,
                                    a.yjdJe ,
                                    a.yjdJeNotax ,
                                    a.ejdTs ,
                                    a.ejdMJ ,
                                    a.ejdJe ,
                                    a.ejdJeNotax ,
                                    a.BnTs ,
                                    a.BnMJ ,
                                    a.BnJe ,
                                    a.BnJeNotax
                          FROM  #ord a
                          UNION ALL
                          SELECT    a.SaleBldGUID ,
                                    a.BzTs ,
                                    a.BzMJ ,
                                    a.BzJe ,
                                    a.BzJeNotax ,
                                    a.newBzTs ,
                                    a.newBzMJ ,
                                    a.newBzJe ,
                                    a.newBzJeNotax ,
                                    a.sBzTs ,
                                    a.sBzMJ ,
                                    a.sBzJe ,
                                    a.sBzJeNotax ,
                                    a.ByTs ,
                                    a.ByMj ,
                                    a.Byje ,
                                    a.ByJeNotax ,
                                    a.yjdTs ,
                                    a.yjdMJ ,
                                    a.yjdJe ,
                                    a.yjdJeNotax ,
                                    a.ejdTs ,
                                    a.ejdMJ ,
                                    a.ejdJe ,
                                    a.ejdJeNotax ,
                                    a.BnTs ,
                                    a.BnMj ,
                                    a.BnJe ,
                                    a.BnJeNotax
                          FROM  #h a
                          UNION ALL
                          SELECT    a.SaleBldGUID ,
                                    a.BzTs ,
                                    a.BzMJ ,
                                    a.BzJe ,
                                    a.BzJeNotax ,
                                    a.newBzTs ,
                                    a.newBzMJ ,
                                    a.newBzJe ,
                                    a.newBzJeNotax ,
                                    a.sBzTs ,
                                    a.sBzMJ ,
                                    a.sBzJe ,
                                    a.sBzJeNotax ,
                                    a.ByTs ,
                                    a.ByMj ,
                                    a.Byje ,
                                    a.ByJeNotax ,
                                    a.yjdTs ,
                                    a.yjdMJ ,
                                    a.yjdJe ,
                                    a.yjdJeNotax ,
                                    a.ejdTs ,
                                    a.ejdMJ ,
                                    a.ejdJe ,
                                    a.ejdJeNotax ,
                                    a.BNTs ,
                                    a.BNMj ,
                                    a.BNJe ,
                                    a.BNJeNotax
                          FROM  #t a) s ON s.salebldguid = db.SaleBldGUID
                LEFT JOIN(SELECT    DISTINCT k.项目guid, k.基础数据主键, k.盈利规划主键 FROM  #key k) dss ON dss.项目guid = db.ProjGUID AND dss.基础数据主键 = db.Product  --业态匹配
        GROUP BY db.SaleBldGUID ,
                 db.Product ,
                 ISNULL(dss.盈利规划主键, db.Product) ,
                 db.ProjGUID,
				 db.isccp;


        --盈利规划
        -- 营业成本单方 	 其中：地价单方 	 其中：除地价外直投单方 	 其中：开发间接费单方 	 其中：资本化利息单方 	 
        --股权溢价单方 	 营销费用单方 	 综合管理费用单方 	 税金及附加单方 

        --OrgGuid,平台公司,项目guid,项目名称,项目代码,投管代码,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,匹配主键,
        --总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,盈利规划营业成本单方,税金及附加单方,股权溢价单方,
        --管理费用单方,营销费用单方,资本化利息单方,开发间接费单方,总投资不含税单方 ,盈利规划车位数
        SELECT  ylgh.[项目guid] ,
                ylgh.匹配主键 业态组合键 ,
                ylgh.总可售面积 AS 盈利规划总可售面积 ,
                ylgh.盈利规划营业成本单方 ,
                ylgh.土地款_单方 ,
                ylgh.除地外直投_单方 ,
                ylgh.开发间接费单方 ,
                ylgh.资本化利息单方 ,
                ylgh.股权溢价单方 盈利规划股权溢价单方 ,
                ylgh.营销费用单方 盈利规划营销费用单方 ,
                ylgh.管理费用单方 盈利规划综合管理费单方协议口径 ,
                ylgh.税金及附加单方 AS 盈利规划税金及附加单方
        INTO    #ylgh
        FROM    dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh
                INNER JOIN #p p ON ylgh.项目guid = p.ProjGUID;

        --select * from #ylgh

        --计算项目成本
        SELECT  a.SaleBldGUID ,
                a.ProjGUID ,
                a.MyProduct ,
                a.Product ,
                y.盈利规划营业成本单方 ,
                y.土地款_单方 ,
                y.除地外直投_单方 ,
                y.开发间接费单方 ,
                y.资本化利息单方 ,
                y.盈利规划股权溢价单方 ,
                y.盈利规划营销费用单方 ,
                y.盈利规划综合管理费单方协议口径 ,
                y.盈利规划税金及附加单方 ,
                a.BzTs ,
                a.BzMj ,
                a.BzmjNew ,
                a.Bzje ,
                a.BzJeNotax ,
                a.newBzTs ,
                a.newBzMj ,
                a.newBzmjNew ,
                a.newBzje ,
                a.newBzJeNotax ,
                a.sBzTs ,
                a.sBzMj ,
                a.sBzmjNew ,
                a.sBzje ,
                a.sBzJeNotax ,
                a.ByTs ,
                a.ByMj ,
                a.BymjNew ,
                a.Byje ,
                a.ByJeNotax ,
                a.yjdTs ,
                a.yjdMj ,
                a.yjdmjNew ,
                a.yjdje ,
                a.yjdJeNotax ,
                a.ejdTs ,
                a.ejdMj ,
                a.ejdmjNew ,
                a.ejdje ,
                a.ejdJeNotax ,
                a.BnTs ,
                a.BnMj ,
                a.BNmjNew ,
                a.BnJe ,
                a.BnJeNotax ,
                y.盈利规划营业成本单方 * ISNULL(a.BzmjNew, 0) 盈利规划营业成本本周 ,
                y.盈利规划股权溢价单方 * ISNULL(a.BzmjNew, 0) 盈利规划股权溢价本周 ,
                y.盈利规划营销费用单方 * ISNULL(a.BzmjNew, 0) 盈利规划营销费用本周 ,
                y.盈利规划综合管理费单方协议口径 * ISNULL(a.BzmjNew, 0) 盈利规划综合管理费本周 ,
                y.盈利规划税金及附加单方 * ISNULL(a.BzmjNew, 0) 盈利规划税金及附加本周 ,
                y.盈利规划营业成本单方 * ISNULL(a.newBzmjNew, 0) 盈利规划营业成本新本周 ,
                y.盈利规划股权溢价单方 * ISNULL(a.newBzmjNew, 0) 盈利规划股权溢价新本周 ,
                y.盈利规划营销费用单方 * ISNULL(a.newBzmjNew, 0) 盈利规划营销费用新本周 ,
                y.盈利规划综合管理费单方协议口径 * ISNULL(a.newBzmjNew, 0) 盈利规划综合管理费新本周 ,
                y.盈利规划税金及附加单方 * ISNULL(a.newBzmjNew, 0) 盈利规划税金及附加新本周 ,
                y.盈利规划营业成本单方 * ISNULL(a.BymjNew, 0) 盈利规划营业成本本月 ,
                y.盈利规划股权溢价单方 * ISNULL(a.BymjNew, 0) 盈利规划股权溢价本月 ,
                y.盈利规划营销费用单方 * ISNULL(a.BymjNew, 0) 盈利规划营销费用本月 ,
                y.盈利规划综合管理费单方协议口径 * ISNULL(a.BymjNew, 0) 盈利规划综合管理费本月 ,
                y.盈利规划税金及附加单方 * ISNULL(a.BymjNew, 0) 盈利规划税金及附加本月 ,
                y.盈利规划营业成本单方 * ISNULL(a.yjdmjNew, 0) 盈利规划营业成本一季度 ,
                y.盈利规划股权溢价单方 * ISNULL(a.yjdmjNew, 0) 盈利规划股权溢价一季度 ,
                y.盈利规划营销费用单方 * ISNULL(a.yjdmjNew, 0) 盈利规划营销费用一季度 ,
                y.盈利规划综合管理费单方协议口径 * ISNULL(a.yjdmjNew, 0) 盈利规划综合管理费一季度 ,
                y.盈利规划税金及附加单方 * ISNULL(a.ejdmjNew, 0) 盈利规划税金及附加一季度 ,
                y.盈利规划营业成本单方 * ISNULL(a.ejdmjNew, 0) 盈利规划营业成本二季度 ,
                y.盈利规划股权溢价单方 * ISNULL(a.ejdmjNew, 0) 盈利规划股权溢价二季度 ,
                y.盈利规划营销费用单方 * ISNULL(a.ejdmjNew, 0) 盈利规划营销费用二季度 ,
                y.盈利规划综合管理费单方协议口径 * ISNULL(a.yjdmjNew, 0) 盈利规划综合管理费二季度 ,
                y.盈利规划税金及附加单方 * ISNULL(a.ejdmjNew, 0) 盈利规划税金及附加二季度 ,
                y.盈利规划营业成本单方 * ISNULL(a.BNmjNew, 0) 盈利规划营业成本本年 ,
                y.盈利规划股权溢价单方 * ISNULL(a.BNmjNew, 0) 盈利规划股权溢价本年 ,
                y.盈利规划营销费用单方 * ISNULL(a.BNmjNew, 0) 盈利规划营销费用本年 ,
                y.盈利规划综合管理费单方协议口径 * ISNULL(a.BNmjNew, 0) 盈利规划综合管理费本年 ,
                y.盈利规划税金及附加单方 * ISNULL(a.BNmjNew, 0) 盈利规划税金及附加本年
        INTO    #cost
        FROM    #sale a
                LEFT JOIN #ylgh y ON a.ProjGUID = y.[项目guid] AND   a.Product = y.业态组合键;

        SELECT  c.ProjGUID ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.BzJeNotax - c.盈利规划营业成本本周 - c.盈利规划股权溢价本周) - c.盈利规划营销费用本周 - c.盈利规划综合管理费本周 - c.盈利规划税金及附加本周) / 100000000)) 项目税前利润本周 ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.newBzJeNotax - c.盈利规划营业成本新本周 - c.盈利规划股权溢价新本周) - c.盈利规划营销费用新本周 - c.盈利规划综合管理费新本周 - c.盈利规划税金及附加新本周) / 100000000)) 项目税前利润新本周 ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.ByJeNotax - c.盈利规划营业成本本月 - c.盈利规划股权溢价本月) - c.盈利规划营销费用本月 - c.盈利规划综合管理费本月 - c.盈利规划税金及附加本月) / 100000000)) 项目税前利润本月 ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.yjdJeNotax - c.盈利规划营业成本一季度 - c.盈利规划股权溢价一季度) - c.盈利规划营销费用一季度 - c.盈利规划综合管理费一季度 - c.盈利规划税金及附加一季度) / 100000000)) 项目税前利润一季度 ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.ejdJeNotax - c.盈利规划营业成本二季度 - c.盈利规划股权溢价二季度) - c.盈利规划营销费用二季度 - c.盈利规划综合管理费二季度 - c.盈利规划税金及附加二季度) / 100000000)) 项目税前利润二季度 ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.BnJeNotax - c.盈利规划营业成本本年 - c.盈利规划股权溢价本年) - c.盈利规划营销费用本年 - c.盈利规划综合管理费本年 - c.盈利规划税金及附加本年) / 100000000)) 项目税前利润本年
        INTO    #xm
        FROM    #cost c
        GROUP BY c.ProjGUID;

        /* SaleBldGUID	平台公司	项目代码	投管代码	项目名	推广名	城市	项目五分类	项目六分化	获取时间	项目状态	管理方式	我司股比	是否录入合作业绩	
操盘方式	并表方式	产品类型	产品名称	商品类型	装修标准	工程楼栋名称	产品楼栋名称	销售楼栋	实际开盘销售日期	竣备类型	竣工备案完成时间	
竣工备案计划完成时间	是否锁定	是否可售	是否自持	动态总可售套数	动态总可售面积	动态总可售货值	剩余总可售套数	剩余总可售面积	剩余总可售货值	年初剩余可售套数	
年初剩余可售面积	年初剩余可售货值	本月已签约套数	本月已签约面积	本月已签约面积（车位按套数）	本月已签约金额	本月已签约金额不含税	本年已签约套数	本年已签约面积	
本年已签约面积（车位按套数）	本年已签约金额	本年已签约金额不含税	预测单价	本月签约均价	本年签约均价	累计签约均价	预计本年签约面积（车位按套数）	预计本年签约金额	
业态组合键_业态	dss匹配盈利规划业态组合键	营业成本单方	盈利规划股权溢价单方	盈利规划营销费用单方	盈利规划综合管理费单方协议口径	盈利规划税金及附加单方	本月已签约所得税	
本月已签约对应签约毛利润	本月已签约对应签约净利润	本年已签约所得税	本年已签约对应签约毛利润	本年已签约对应签约净利润
*/
        SELECT  NEWID() VersionGUID,
				A.DevelopmentCompanyGUID OrgGUID,
				a.SaleBldGUID ,
                f.平台公司 ,
                f.项目代码 ,
                f.投管代码 ,
                f.项目名 ,
                f.推广名 ,
                f.城市 ,
                f.项目五分类 ,
                f.城市六分化 ,
                f.获取时间 ,
                f.项目状态 ,
                f.管理方式 ,
                f.项目股权比例 ,
                f.是否录入合作业绩 ,
                a.ProductType 产品类型 ,
                a.ProductName 产品名称 ,
                a.BusinessType 商品类型 ,
                a.Standard 装修标准 ,
                gc.BldName 工程楼栋名称 ,
                a.BldCode 产品楼栋名称 ,
                pb.BldName 销售楼栋 ,
                th.thdate 实际开盘销售日期 ,
                a.SJjgbadate 竣工备案完成时间 ,
                a.YJjgbadate 竣工备案计划完成时间 ,
                c.BzTs 本周已签约套数 ,
                c.BzMj 本周已签约面积 ,
                c.BzmjNew [本周已签约面积车位按套数] ,
                c.Bzje 本周已签约金额 ,
                c.BzJeNotax 本周已签约金额不含税 ,
                c.newBzTs 新本周已签约套数 ,
                c.newBzMj 新本周已签约面积 ,
                c.newBzmjNew [新本周已签约面积车位按套数] ,
                c.newBzje 新本周已签约金额 ,
                c.newBzJeNotax 新本周已签约金额不含税 ,
                c.sBzTs 上周已签约套数 ,
                c.sBzMj 上周已签约面积 ,
                c.sBzmjNew [上周已签约面积车位按套数] ,
                c.sBzje 上周已签约金额 ,
                c.sBzJeNotax 上周已签约金额不含税 ,
                c.ByTs 本月已签约套数 ,
                c.ByMj 本月已签约面积 ,
                c.BymjNew [本月已签约面积车位按套数] ,
                c.Byje 本月已签约金额 ,
                c.ByJeNotax 本月已签约金额不含税 ,
                c.yjdTs 一季度已签约套数 ,
                c.yjdMj 一季度已签约面积 ,
                c.yjdmjNew [一季度已签约面积车位按套数] ,
                c.yjdje 一季度已签约金额 ,
                c.yjdJeNotax 一季度已签约金额不含税 ,
                c.ejdTs 二季度已签约套数 ,
                c.ejdMj 二季度已签约面积 ,
                c.ejdmjNew [二季度已签约面积车位按套数] ,
                c.ejdje 二季度已签约金额 ,
                c.ejdJeNotax 二季度已签约金额不含税 ,
                c.BnTs 本年已签约套数 ,
                c.BnMj 本年已签约面积 ,
                c.BNmjNew [本年已签约面积车位按套数] ,
                c.BnJe 本年已签约金额 ,
                c.BnJeNotax 本年已签约金额不含税 ,
                c.MyProduct 业态组合键_业态 ,
                c.Product dss匹配盈利规划业态组合键 ,
                ((c.BzJeNotax - c.盈利规划营业成本本周 - c.盈利规划股权溢价本周) - c.盈利规划营销费用本周 - c.盈利规划综合管理费本周 - c.盈利规划税金及附加本周)
                - CASE WHEN x.项目税前利润本周 > 0 THEN ((c.BzJeNotax - c.盈利规划营业成本本周 - c.盈利规划股权溢价本周) - c.盈利规划营销费用本周 - c.盈利规划综合管理费本周 - c.盈利规划税金及附加本周) * 0.25 ELSE 0 END 本周已签约对应签约净利润 ,
                ((c.newBzJeNotax - c.盈利规划营业成本新本周 - c.盈利规划股权溢价新本周) - c.盈利规划营销费用新本周 - c.盈利规划综合管理费新本周 - c.盈利规划税金及附加新本周)
                - CASE WHEN x.项目税前利润新本周 > 0 THEN ((c.newBzJeNotax - c.盈利规划营业成本新本周 - c.盈利规划股权溢价新本周) - c.盈利规划营销费用新本周 - c.盈利规划综合管理费新本周 - c.盈利规划税金及附加新本周) * 0.25 ELSE 0 END 新本周已签约对应签约净利润 ,
                ((c.ByJeNotax - c.盈利规划营业成本本月 - c.盈利规划股权溢价本月) - c.盈利规划营销费用本月 - c.盈利规划综合管理费本月 - c.盈利规划税金及附加本月)
                - CASE WHEN x.项目税前利润本月 > 0 THEN ((c.ByJeNotax - c.盈利规划营业成本本月 - c.盈利规划股权溢价本月) - c.盈利规划营销费用本月 - c.盈利规划综合管理费本月 - c.盈利规划税金及附加本月) * 0.25 ELSE 0 END 本月已签约对应签约净利润 ,
                ((c.yjdJeNotax - c.盈利规划营业成本一季度 - c.盈利规划股权溢价一季度) - c.盈利规划营销费用一季度 - c.盈利规划综合管理费一季度 - c.盈利规划税金及附加一季度)
                - CASE WHEN x.项目税前利润一季度 > 0 THEN ((c.yjdJeNotax - c.盈利规划营业成本一季度 - c.盈利规划股权溢价一季度) - c.盈利规划营销费用一季度 - c.盈利规划综合管理费一季度 - c.盈利规划税金及附加一季度) * 0.25 ELSE 0 END 一季度已签约对应签约净利润 ,
                ((c.ejdJeNotax - c.盈利规划营业成本二季度 - c.盈利规划股权溢价二季度) - c.盈利规划营销费用二季度 - c.盈利规划综合管理费二季度 - c.盈利规划税金及附加二季度)
                - CASE WHEN x.项目税前利润二季度 > 0 THEN ((c.ejdJeNotax - c.盈利规划营业成本二季度 - c.盈利规划股权溢价二季度) - c.盈利规划营销费用二季度 - c.盈利规划综合管理费二季度 - c.盈利规划税金及附加二季度) * 0.25 ELSE 0 END 二季度已签约对应签约净利润 ,
                ((c.BnJeNotax - c.盈利规划营业成本本年 - c.盈利规划股权溢价本年) - c.盈利规划营销费用本年 - c.盈利规划综合管理费本年 - c.盈利规划税金及附加本年)
                - CASE WHEN x.项目税前利润本年 > 0 THEN ((c.BnJeNotax - c.盈利规划营业成本本年 - c.盈利规划股权溢价本年) - c.盈利规划营销费用本年 - c.盈利规划综合管理费本年 - c.盈利规划税金及附加本年) * 0.25 ELSE 0 END 本年已签约对应签约净利润,
				a.isccp
		into #ccpqyjll
        FROM    #db a
                LEFT JOIN vmdm_projectFlag f ON a.ProjGUID = f.ProjGUID
                LEFT JOIN mdm_GCBuild gc ON a.GCBldGUID = gc.GCBldGUID
                LEFT JOIN p_Building pb ON pb.BldGUID = a.SaleBldGUID
                LEFT JOIN s_ccpsuodingbld sd ON sd.SaleBldGUID = a.SaleBldGUID
                LEFT JOIN #cost c ON c.SaleBldGUID = a.SaleBldGUID
                LEFT JOIN #xm x ON x.ProjGUID = a.ProjGUID
                LEFT JOIN(SELECT    r.BldGUID, MIN(r.ThDate) thdate FROM    #room r GROUP BY r.BldGUID) th ON th.BldGUID = a.SaleBldGUID
                LEFT JOIN(SELECT    la.SaleBldGUID ,
                                    SUM(la.ThisMonthSaleAreaQy) qymj ,
                                    SUM(la.ThisMonthSaleMoneyQy) qyje
                          FROM  dbo.s_SaleValueBuildLayout la
                          WHERE NOT EXISTS (SELECT  1
                                            FROM    dbo.s_SaleValuePlanHistory h
                                            WHERE  la.SaleValuePlanVersionGUID = h.SaleValuePlanVersionGUID) AND   la.SaleValuePlanYear = YEAR(@zedate)
                          GROUP BY la.SaleBldGUID) yj ON yj.SaleBldGUID = a.SaleBldGUID
        WHERE   1 = 1
        ORDER BY f.平台公司 ,
                 f.项目代码;

        --and a.SaleBldGUId='A6EDF7D5-3F21-4F3C-809A-4A20049FAF44'

select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'2' num,
		'其中21年及以前获取项目产成品认购' 口径,
		sum(BzJe)/100000000 本周金额,
		sum(newBzJe)/100000000 新本周金额,
		sum(sBzJe)/100000000 上周金额,
		sum(Byje)/100000000 本月金额,
		sum(yjdJe)/100000000 一季度金额,
		sum(ejdje)/100000000 二季度金额,
		sum(bnje)/100000000 本年金额
	into #sumccprg
	FROM #saleord a
	left join vmdm_projectflag f on a.projguid = f.projguid
	where a.isccp = '产成品'
	and year(f.获取时间) <= 2021

        /* SaleBldGUID	平台公司	项目代码	投管代码	项目名	推广名	城市	项目五分类	项目六分化	获取时间	项目状态	管理方式	我司股比	是否录入合作业绩	
操盘方式	并表方式	产品类型	产品名称	商品类型	装修标准	工程楼栋名称	产品楼栋名称	销售楼栋	实际开盘销售日期	竣备类型	竣工备案完成时间	
竣工备案计划完成时间	是否锁定	是否可售	是否自持	动态总可售套数	动态总可售面积	动态总可售货值	剩余总可售套数	剩余总可售面积	剩余总可售货值	年初剩余可售套数	
年初剩余可售面积	年初剩余可售货值	本月已签约套数	本月已签约面积	本月已签约面积（车位按套数）	本月已签约金额	本月已签约金额不含税	本年已签约套数	本年已签约面积	
本年已签约面积（车位按套数）	本年已签约金额	本年已签约金额不含税	预测单价	本月签约均价	本年签约均价	累计签约均价	预计本年签约面积（车位按套数）	预计本年签约金额	
业态组合键_业态	dss匹配盈利规划业态组合键	营业成本单方	盈利规划股权溢价单方	盈利规划营销费用单方	盈利规划综合管理费单方协议口径	盈利规划税金及附加单方	本月已签约所得税	
本月已签约对应签约毛利润	本月已签约对应签约净利润	本年已签约所得税	本年已签约对应签约毛利润	本年已签约对应签约净利润
*/
        DROP TABLE #p ,
                   #con ,
                   #cost ,
                   #db ,
                   #h ,
                   #hzyj ,
                   #key ,
                   #s_PerformanceAppraisal ,
                   #sale ,
                   #t ,
                   #tmp_tax ,
                   #vrt ,
                   #xm ,
                   #ylgh ,
                   #room;
    END;

SELECT *
FROM
(
    SELECT *
    FROM #sumqy
    UNION
    SELECT *
    FROM #sumrg
    UNION
    SELECT *
    FROM #sumrgfl
    UNION
    SELECT *
    FROM #sumrgflxx
    UNION
    SELECT *
    FROM #sumqyfenlei
    UNION
    SELECT *
    FROM #sumxjl
    UNION
    SELECT *
    FROM #sumfeiyong
    UNION
    SELECT *
    FROM #sumjk
    UNION
    SELECT *
    FROM #sumccprg
    UNION
    SELECT *
    FROM #sumqyfenleis

) a
ORDER BY a.num,
         口径;



DROP TABLE 

           #sumqy,
           #sumqyfenlei,
           #sumxjl,
           #fy,
           #sumfeiyong,
		   #sumrg,
		   #ccpqyjll,#ord,#saleord,#sumccprg,#sumjk,#sumqyfenleis,
		   #bnskp,#skp,#sumrgfl,#sumrgflxx;