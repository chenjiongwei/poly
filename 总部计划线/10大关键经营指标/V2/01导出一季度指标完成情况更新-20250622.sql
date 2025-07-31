DECLARE @zbdate DATETIME;
DECLARE @zedate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;
DECLARE @szbdate DATETIME;
DECLARE @szedate DATETIME;
--���յ��������������ϵ���
SET @zbdate = '2025-07-07';
SET @zedate = '2025-07-13';
SET @newzbdate = '2025-07-07';
SET @newzedate = '2025-07-13';
SET @szbdate = '2025-06-30';
SET @szedate = '2025-07-06';

---SUM(FactAmount1+ FactAmount2 ) / 100000000 AS '�����ѷ�������' ����ط���3�·�Ҫ��FactAmount3

-----����������������������������������ȡ�ɽ�����
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       10 num,
       '��ǩԼ' �ھ�,
       SUM(ISNULL(b.����ǩԼ���, 0) - ISNULL(c.����ǩԼ���, 0)) / 10000 ����ǩԼ���,
       SUM(ISNULL(d.����ǩԼ���, 0) - ISNULL(e.����ǩԼ���, 0)) / 10000 �±���ǩԼ���,
       SUM(ISNULL(sb.����ǩԼ���, 0) - ISNULL(sc.����ǩԼ���, 0)) / 10000 ����ǩԼ���,
       SUM(ISNULL(d.����ǩԼ���, 0)) / 10000 ����ǩԼ���,
       SUM(ISNULL(f.����ǩԼ���, 0)) / 10000 һ����ǩԼ���,
       SUM(ISNULL(d.����ǩԼ���, 0) - ISNULL(f.����ǩԼ���, 0)) / 10000 ������ǩԼ���,
       SUM(ISNULL(b.����ǩԼ���, 0)) / 10000 ����ǩԼ���
INTO #sumqy
FROM
(
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.��Ʒ���� = b.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(b.��������, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.��Ʒ���� = c.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(c.��������, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.��Ʒ���� = d.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(d.��������, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.��Ʒ���� = e.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(e.��������, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.��Ʒ���� = f.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(f.��������, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.��Ʒ���� = sb.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sb.��������, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.��Ʒ���� = sc.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sc.��������, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1;


-----����������������������������������ȡ�ɽ�����
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       1 num,
       '���Ϲ�' �ھ�,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0) - ISNULL(c.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(e.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) �±���ǩԼ���, ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(sb.�����Ϲ����, 0) - ISNULL(sc.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,
       round(cast(SUM(ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) һ����ǩԼ���,
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ������ǩԼ���,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���
INTO #sumrg
FROM
(
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.��Ʒ���� = b.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(b.��������, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.��Ʒ���� = c.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(c.��������, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.��Ʒ���� = d.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(d.��������, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.��Ʒ���� = e.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(e.��������, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.��Ʒ���� = f.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(f.��������, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.��Ʒ���� = sb.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sb.��������, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.��Ʒ���� = sc.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sc.��������, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1;

select pp.projguid,min(QSDate) skdate
into #skp
from p_Project pp
left join p_Project p on pp.ProjCode = p.ParentCode
left join s_Order o on o.ProjGUID = p.ProjGUID and (o.Status = '����' or o.CloseReason = 'תǩԼ')
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
       case when sk.ProjGUID is not null then '�׿���Ŀ'
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
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969') then 'S����Ŀ'
		else '����������Ŀ' 
		end �ھ�,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0) - ISNULL(c.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(e.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) �±���ǩԼ���, ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(sb.�����Ϲ����, 0) - ISNULL(sc.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,
       round(cast(SUM(ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) һ����ǩԼ���,
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ������ǩԼ���,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���
INTO #sumrgfl
FROM
(
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.��Ʒ���� = b.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(b.��������, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.��Ʒ���� = c.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(c.��������, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.��Ʒ���� = d.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(d.��������, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.��Ʒ���� = e.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(e.��������, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.��Ʒ���� = f.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(f.��������, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.��Ʒ���� = sb.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sb.��������, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.��Ʒ���� = sc.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sc.��������, '')
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
       case when sk.ProjGUID is not null then '�׿���Ŀ'
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
						'AA6EF534-9DF9-EF11-B3A6-F40270D39969') then 'S����Ŀ'
		else '����������Ŀ' 
		end ;	

		
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       case when year(mp.AcquisitionDate) <= 2021 then '1.4'
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '1.5' 
		else '1.6'
		end   num,
       case when year(mp.AcquisitionDate) <= 2021 then '���У�21�꼰��ǰ��ȡ��Ŀ��������'
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '22-23���ȡ��Ŀ' 
		else '24-25���ȡ��Ŀ'
		end �ھ�,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0) - ISNULL(c.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(e.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) �±���ǩԼ���, ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(sb.�����Ϲ����, 0) - ISNULL(sc.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,
       round(cast(SUM(ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) һ����ǩԼ���,
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ������ǩԼ���,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���
INTO #sumrgflxx
FROM
(
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN mdm_project mp ON a.projguid = mp.projguid
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.��Ʒ���� = b.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(b.��������, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.��Ʒ���� = c.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(c.��������, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.��Ʒ���� = d.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(d.��������, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.��Ʒ���� = e.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(e.��������, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.��Ʒ���� = f.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(f.��������, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.��Ʒ���� = sb.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sb.��������, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.��Ʒ���� = sc.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sc.��������, '')
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
       case when year(mp.AcquisitionDate) <= 2021 then '���У�21�꼰��ǰ��ȡ��Ŀ��������'
		when year(mp.AcquisitionDate) >2021 and year(mp.AcquisitionDate) < 2024 then '22-23���ȡ��Ŀ' 
		else '24-25���ȡ��Ŀ'
		end ;		  

-----����������������������������������ȡ�ɽ�����
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       CASE
           WHEN a.��Ʒ���� IN ( 'סլ', '�߼�סլ' ) THEN
                '3'
           WHEN a.��Ʒ���� = '��ҵ' THEN
                '5'
           WHEN a.��Ʒ���� = '��Ԣ' THEN
                '6'
           WHEN a.��Ʒ���� = 'д��¥' THEN
                '7'
           WHEN a.��Ʒ���� = '������/����' THEN
                '8'
           ELSE '9'
       END num,
       CASE
           WHEN a.��Ʒ���� IN ( 'סլ', '�߼�סլ' ) THEN
                'סլ'
           WHEN a.��Ʒ���� = '��ҵ' THEN
                '��ҵ'
           WHEN a.��Ʒ���� = '��Ԣ' THEN
                '��Ԣ'
           WHEN a.��Ʒ���� = 'д��¥' THEN
                'д��¥'
           WHEN a.��Ʒ���� = '������/����' THEN
                '��λ'
           ELSE '����'
       END �ھ�,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0) - ISNULL(c.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(e.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) �±���ǩԼ���, ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(sb.�����Ϲ����, 0) - ISNULL(sc.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,
       round(cast(SUM(ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) һ����ǩԼ���,
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ������ǩԼ���,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���
INTO #sumqyfenlei
FROM
(
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.��Ʒ���� = b.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(b.��������, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.��Ʒ���� = c.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(c.��������, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.��Ʒ���� = d.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(d.��������, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.��Ʒ���� = e.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(e.��������, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.��Ʒ���� = f.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(f.��������, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.��Ʒ���� = sb.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sb.��������, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.��Ʒ���� = sc.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sc.��������, '')
                                          AND DATEDIFF(dd, sc.qxdate, @szbdate) = 1
GROUP BY CASE
           WHEN a.��Ʒ���� IN ( 'סլ', '�߼�סլ' ) THEN
                '3'
           WHEN a.��Ʒ���� = '��ҵ' THEN
                '5'
           WHEN a.��Ʒ���� = '��Ԣ' THEN
                '6'
           WHEN a.��Ʒ���� = 'д��¥' THEN
                '7'
           WHEN a.��Ʒ���� = '������/����' THEN
                '8'
           ELSE '9'
       END ,
       CASE
           WHEN a.��Ʒ���� IN ( 'סլ', '�߼�סլ' ) THEN
                'סլ'
           WHEN a.��Ʒ���� = '��ҵ' THEN
                '��ҵ'
           WHEN a.��Ʒ���� = '��Ԣ' THEN
                '��Ԣ'
           WHEN a.��Ʒ���� = 'д��¥' THEN
                'д��¥'
           WHEN a.��Ʒ���� = '������/����' THEN
                '��λ'
           ELSE '����'
       END;


SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       '4' num,
       '���У�S����Ŀ' �ھ�,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0) - ISNULL(c.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(e.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) �±���ǩԼ���, ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(sb.�����Ϲ����, 0) - ISNULL(sc.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,  ---��ʱ�޸ı���ǩԼ���
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���,
       round(cast(SUM(ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) һ����ǩԼ���,
       round(cast(SUM(ISNULL(d.�����Ϲ����, 0) - ISNULL(f.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ������ǩԼ���,
       round(cast(SUM(ISNULL(b.�����Ϲ����, 0)) / 10000.00 as decimal(18,4)),4) ����ǩԼ���
INTO #sumqyfenleis
FROM
(
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zbdate) = 1
    UNION
    SELECT projguid,
           ��Ʒ����,
           ��������
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, @zedate) = 0
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.��Ʒ���� = b.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(b.��������, '')
                                          AND DATEDIFF(dd, b.qxdate, @zedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.��Ʒ���� = c.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(c.��������, '')
                                          AND DATEDIFF(dd, c.qxdate, @zbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily d ON a.projguid = d.projguid
                                          AND a.��Ʒ���� = d.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(d.��������, '')
                                          AND DATEDIFF(dd, d.qxdate, @newzedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily e ON a.projguid = e.projguid
                                          AND a.��Ʒ���� = e.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(e.��������, '')
                                          AND DATEDIFF(dd, e.qxdate, @newzbdate) = 1
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily f ON a.projguid = f.projguid
                                          AND a.��Ʒ���� = f.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(f.��������, '')
                                          AND DATEDIFF(dd, f.qxdate, '2025-03-31') = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sb ON a.projguid = sb.projguid
                                          AND a.��Ʒ���� = sb.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sb.��������, '')
                                          AND DATEDIFF(dd, sb.qxdate, @szedate) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily sc ON a.projguid = sc.projguid
                                          AND a.��Ʒ���� = sc.��Ʒ����
                                          AND ISNULL(a.��������, '') = ISNULL(sc.��������, '')
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
and a.��Ʒ���� IN ( 'סլ', '�߼�סլ' ) 




--��������ë����
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       12 num,
       'ȫ��ǩԼ������' �ھ�,
       CASE
           WHEN ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0) > 0 THEN
       (ISNULL(a.���꾻����ǩԼ, 0) - ISNULL(b.���꾻����ǩԼ, 0)) / (ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0))
           ELSE 0
       END ����ǩԼ���,
       CASE
           WHEN ISNULL(c.����ǩԼ����˰, 0) - ISNULL(d.����ǩԼ����˰, 0) > 0 THEN
       (ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(d.���꾻����ǩԼ, 0)) / (ISNULL(c.����ǩԼ����˰, 0) - ISNULL(d.����ǩԼ����˰, 0))
           ELSE 0
       END �±���ǩԼ���,
       CASE
           WHEN ISNULL(sa.����ǩԼ����˰, 0) - ISNULL(sb.����ǩԼ����˰, 0) > 0 THEN
       (ISNULL(sa.���꾻����ǩԼ, 0) - ISNULL(sb.���꾻����ǩԼ, 0)) / (ISNULL(sa.����ǩԼ����˰, 0) - ISNULL(sb.����ǩԼ����˰, 0))
           ELSE 0
       END ����ǩԼ���,
       CASE
           WHEN ISNULL(c.����ǩԼ����˰, 0) > 0 THEN
                ISNULL(c.���¾�����ǩԼ, 0) / ISNULL(c.����ǩԼ����˰, 0)
           ELSE 0
       END ����ǩԼ���,
       CASE
           WHEN ISNULL(e.����ǩԼ����˰, 0) > 0 THEN
                ISNULL(e.���꾻����ǩԼ, 0) / ISNULL(e.����ǩԼ����˰, 0)
           ELSE 0
       END һ����ǩԼ���,
       CASE
           WHEN ISNULL(c.����ǩԼ����˰, 0) - ISNULL(e.����ǩԼ����˰, 0) > 0 THEN
       (ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(e.���꾻����ǩԼ, 0)) / (ISNULL(c.����ǩԼ����˰, 0) - ISNULL(e.����ǩԼ����˰, 0))
           ELSE 0
       END ������ǩԼ���,
       CASE
           WHEN ISNULL(a.����ǩԼ����˰, 0) > 0 THEN
                ISNULL(a.���꾻����ǩԼ, 0) / ISNULL(a.����ǩԼ����˰, 0)
           ELSE 0
       END ����������
INTO #sumxjl
FROM
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
) a
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
) b ON a.buguid = b.buguid
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
) c ON a.buguid = c.buguid
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
) d ON a.buguid = d.buguid
LEFT JOIN 
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
) e ON a.buguid = e.buguid
LEFT JOIN 
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @szedate) = 0
) sa ON a.buguid = sa.buguid
LEFT JOIN
(
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @szbdate) = 1
) sb ON a.buguid = sb.buguid;


--��������ë����
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       '13' num,
       '������޿���Ŀ��Ӧ����������' �ھ�,
       sum(case when 
		   CASE
			   WHEN ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0) > 0 THEN
		   (ISNULL(a.���꾻����ǩԼ, 0) - ISNULL(b.���꾻����ǩԼ, 0)) / (ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(a.���꾻����ǩԼ, 0) - ISNULL(b.���꾻����ǩԼ, 0))	   
	   else 0 end) ����ǩԼ���,
       sum(case when 
		   CASE
			   WHEN ISNULL(c.����ǩԼ����˰, 0) - ISNULL(d.����ǩԼ����˰, 0) > 0 THEN
		   (ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(d.���꾻����ǩԼ, 0)) / (ISNULL(c.����ǩԼ����˰, 0) - ISNULL(d.����ǩԼ����˰, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(d.���꾻����ǩԼ, 0))
	   else 0 end) �±���ǩԼ���,
       sum(case when 
		   CASE
			   WHEN ISNULL(sa.����ǩԼ����˰, 0) - ISNULL(sb.����ǩԼ����˰, 0) > 0 THEN
		   (ISNULL(sa.���꾻����ǩԼ, 0) - ISNULL(sb.���꾻����ǩԼ, 0)) / (ISNULL(sa.����ǩԼ����˰, 0) - ISNULL(sb.����ǩԼ����˰, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(sa.���꾻����ǩԼ, 0) - ISNULL(sb.���꾻����ǩԼ, 0))	   
	   else 0 end) ����ǩԼ���,
       sum(case when 
		   CASE
			   WHEN ISNULL(c.����ǩԼ����˰, 0) > 0 THEN
					ISNULL(c.���¾�����ǩԼ, 0) / ISNULL(c.����ǩԼ����˰, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(c.���¾�����ǩԼ, 0)
	   else 0 end) ����ǩԼ���,
       sum(case when 
		   CASE
			   WHEN ISNULL(e.����ǩԼ����˰, 0) > 0 THEN
					ISNULL(e.���꾻����ǩԼ, 0) / ISNULL(e.����ǩԼ����˰, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(e.���꾻����ǩԼ, 0)
	   else 0 end) һ����ǩԼ���,
       sum(case when 
		   CASE
			   WHEN ISNULL(c.����ǩԼ����˰, 0) - ISNULL(e.����ǩԼ����˰, 0) > 0 THEN
		   (ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(e.���꾻����ǩԼ, 0)) / (ISNULL(c.����ǩԼ����˰, 0) - ISNULL(e.����ǩԼ����˰, 0))
			   ELSE 0
		   END < -0.3 then (ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(e.���꾻����ǩԼ, 0))
	   else 0 end) ������ǩԼ���,
       sum(case when 
		   CASE
			   WHEN ISNULL(a.����ǩԼ����˰, 0) > 0 THEN
					ISNULL(a.���꾻����ǩԼ, 0) / ISNULL(a.����ǩԼ����˰, 0)
			   ELSE 0
		   END < -0.3 then ISNULL(a.���꾻����ǩԼ, 0)
	   else 0 end) ����������
INTO #sumjk
FROM
(
    SELECT a.ProjGUID ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0 
	and ISNULL(f.�ض���Ŀ��ǩ, '') <> '����'
	group by a.ProjGUID
) a
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
	and ISNULL(f.�ض���Ŀ��ǩ, '') <> '����'
	group by a.ProjGUID
) b ON a.ProjGUID = b.ProjGUID
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
	and ISNULL(f.�ض���Ŀ��ǩ, '') <> '����'
	group by a.ProjGUID
) c ON a.ProjGUID = c.ProjGUID
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
	and ISNULL(f.�ض���Ŀ��ǩ, '') <> '����'
	group by a.ProjGUID
) d ON a.ProjGUID = d.ProjGUID
LEFT JOIN 
(
    SELECT a.ProjGUID ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
	and ISNULL(f.�ض���Ŀ��ǩ, '') <> '����'
	group by a.ProjGUID
) e ON a.ProjGUID = e.ProjGUID
LEFT JOIN 
(
    SELECT a.ProjGUID ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @szedate) = 0 
	and ISNULL(f.�ض���Ŀ��ǩ, '') <> '����'
	group by a.ProjGUID
) sa ON a.ProjGUID = sa.ProjGUID
LEFT JOIN
(
    SELECT a.ProjGUID ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New a
    LEFT JOIN vmdm_projectflag f ON a.ProjGUID = f.projguid
    WHERE DATEDIFF(DAY, qxdate, @szbdate) = 1
	and ISNULL(f.�ض���Ŀ��ǩ, '') <> '����'
	group by a.ProjGUID
) sb ON a.ProjGUID = sb.ProjGUID;

--��������������������������������������������������������Ӫ�����á���������������������������������������������������������������

--���Ԥ��&��ȷ���������ǩԼ����ɸ��˾��Ԥ�㷶Χ			
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(FactAmount1 + FactAmount2 + FactAmount3 ) / 100000000 AS 'һ�����ѷ�������',
       SUM(FactAmount4 + FactAmount5) / 100000000 AS '�������ѷ�������',
       SUM(FactAmount1 + FactAmount2 + FactAmount3 +FactAmount4 +FactAmount5) / 100000000 AS '�����ѷ�������'
--SUM(FactAmount1 + FactAmount2 + FactAmount3 + FactAmount4 + FactAmount5 + FactAmount6 + FactAmount7
--    + FactAmount8 + FactAmount9 + FactAmount10 + FactAmount11 + FactAmount12
--   ) / 100000000 AS '�����ѷ�������'
INTO #fy
FROM MyCost_Erp352.dbo.ys_YearPlanDept2Cost a
     INNER JOIN MyCost_Erp352.dbo.ys_DeptCost b ON b.DeptCostGUID = a.costguid
                                                   AND a.YEAR = b.YEAR
     INNER JOIN MyCost_Erp352.dbo.ys_SpecialBusinessUnit u ON a.DeptGUID = u.SpecialUnitGUID
     INNER JOIN MyCost_Erp352.dbo.ys_fy_DimCost dim ON dim.costguid = a.costguid
                                                       AND dim.year = a.year
                                                       AND dim.IsEndCost = 1
WHERE a.year = YEAR(GETDATE())
      AND b.costtype = 'Ӫ����';


SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       11 num,
       'Ӫ������' �ھ�,
       0 ���ܷ���,
       0 �±��ܷ���,
       0 ���ܷ���,
       0 ���·���,
       CASE
           WHEN q.һ����ǩԼ��� > 0 THEN
                f.[һ�����ѷ�������] / q.һ����ǩԼ���
           ELSE 0
       END һ���ȷ���,
       CASE
           WHEN q.������ǩԼ��� > 0 THEN
                f.[�������ѷ�������] / q.������ǩԼ���
           ELSE 0
       END �����ȷ���,
       CASE
           WHEN q.����ǩԼ��� > 0 THEN
                f.[�����ѷ�������] / q.����ǩԼ���
           ELSE 0
       END �������
INTO #sumfeiyong
FROM mybusinessunit bu
     LEFT JOIN #fy f ON bu.buguid = f.buguid
     LEFT JOIN #sumqy q ON bu.buguid = q.buguid
WHERE bu.buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23';




    BEGIN
        --declare	 @var_jgdate date=@zedate
        --������Ŀ
        SELECT  p.ProjGUID ,
                p.ProjCode
        INTO    #p
        FROM    mdm_Project p
        WHERE   1 = 1
                --AND p.ProjCode='4690004'
                AND p.Level = 2 
				--AND p.DevelopmentCompanyGUID IN(SELECT  Value FROM  fn_Split2(@var_buguid, ',') );

        --����¥��
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
				case when datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 then '����Ʒ'
				 when datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 then '׼����Ʒ'
				 else '����' end isccp
        INTO    #db
        FROM    p_lddbamj a
                INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
        WHERE   DATEDIFF(DAY, a.QXDate, getdate()) = 0
		and 
		(datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 --����Ʒ��ʵ�ʿ�������ʱ��������
		 or 
		 (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ) --׼����Ʒ��ʵ�ʿ�����ƻ������ڱ���
		)
		;

        SELECT  r.RoomGUID ,
                r.ProjGUID fqprojguid ,
                r.BldGUID ,
                r.ThDate
        INTO    #room
        FROM    p_room r
                INNER JOIN #db d ON r.BldGUID = d.SaleBldGUID
        WHERE   r.Status = 'ǩԼ' AND EXISTS (SELECT  1
                                            FROM    s_Contract c
                                            WHERE   c.Status = '����' AND YEAR(c.QSDate) = YEAR(@zedate) AND c.RoomGUID = r.RoomGUID);

        --˰��
        SELECT  DISTINCT vt.ProjGUID ,
                         VATRate ,
                         RoomGUID
        INTO    #vrt
        FROM    s_VATSet vt
                INNER JOIN #room r ON vt.ProjGUID = r.fqprojguid
        WHERE   VATScope = '������Ŀ' AND   AuditState = 1 AND  RoomGUID NOT IN(SELECT  DISTINCT vtr.RoomGUID
                                                                            FROM    s_VATSet vt ---------  
                                                                                    INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
                                                                                    INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
                                                                            WHERE   VATScope = '�ض�����' AND   AuditState = 1)
        UNION ALL
        SELECT  DISTINCT vt.ProjGUID ,
                         vt.VATRate ,
                         vtr.RoomGUID
        FROM    s_VATSet vt ---------  
                INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
                INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
        WHERE   VATScope = '�ض�����' AND   AuditState = 1;

        --ǩԼ
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
                LEFT JOIN s_Order d ON a.TradeGUID = d.TradeGUID AND   ISNULL(d.CloseReason, '') = 'תǩԼ'
                LEFT JOIN(SELECT    TradeGUID ,
                                    SUM(Amount) amount
                          FROM  s_Fee f
                          WHERE ItemName LIKE '%����%'
                          GROUP BY TradeGUID) f ON a.TradeGUID = f.TradeGUID
                LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
        WHERE   a.Status = '����' AND YEAR(a.QSDate) = YEAR(@zedate) AND EXISTS (SELECT 1 FROM  #db db WHERE db.SaleBldGUID = r.BldGUID)
                AND NOT EXISTS (SELECT  1
                                FROM    dbo.S_PerformanceAppraisalRoom sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '�����' AND   s.YjType not in ('��Ӫ��(��ۿ�)','��ҵ��˾��λ����')
                                WHERE  r.RoomGUID = sr.RoomGUID)
                AND   NOT EXISTS (SELECT    1
                                  FROM  dbo.S_PerformanceAppraisalBuildings sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '�����' AND  s.YjType not in ('��Ӫ��(��ۿ�)','��ҵ��˾��λ����')
                                  WHERE   r.BldGUID = sr.BldGUID)
        GROUP BY r.BldGUID;
		

        --�Ϲ�
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
                LEFT JOIN s_Contract d ON a.TradeGUID = d.TradeGUID AND   ISNULL(a.CloseReason, '') = 'תǩԼ' and d.Status = '����'
                LEFT JOIN(SELECT    TradeGUID ,
                                    SUM(Amount) amount
                          FROM  s_Fee f
                          WHERE ItemName LIKE '%����%'
                          GROUP BY TradeGUID) f ON a.TradeGUID = f.TradeGUID
                LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
        WHERE   (a.Status = '����' or (a.CloseReason ='תǩԼ' and d.Status = '����')) AND YEAR(a.QSDate) = YEAR(@zedate) AND EXISTS (SELECT 1 FROM  #db db WHERE db.SaleBldGUID = r.BldGUID)
                AND NOT EXISTS (SELECT  1
                                FROM    dbo.S_PerformanceAppraisalRoom sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '�����' AND   s.YjType not in ('��Ӫ��(��ۿ�)','��ҵ��˾��λ����')
                                WHERE  r.RoomGUID = sr.RoomGUID)
                AND   NOT EXISTS (SELECT    1
                                  FROM  dbo.S_PerformanceAppraisalBuildings sr
                                        INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '�����' AND  s.YjType not in ('��Ӫ��(��ۿ�)','��ҵ��˾��λ����')
                                  WHERE   r.BldGUID = sr.BldGUID)
        GROUP BY r.BldGUID;

        --����˰�ʱ�
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

        --����ҵ��
        SELECT  c.ProjGUID ,
                CONVERT(DATE, b.DateYear + '-' + b.DateMonth + '-27') AS [BizDate] ,
                b.*
        INTO    #hzyj
        FROM    s_YJRLProducteDetail b
                INNER JOIN s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
                INNER JOIN #p mp ON c.ProjGUID = mp.ProjGUID
        WHERE   b.Shenhe = '���';

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

        --����ҵ��
        SELECT  a.* ,
                a.TotalAmount / (1 + tax.rate) TotalAmountnotax ,
                tax.rate
        INTO    #s_PerformanceAppraisal
        FROM    S_PerformanceAppraisal a
                INNER JOIN #p mp ON a.ManagementProjectGUID = mp.ProjGUID
                LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.RdDate, tax.bgnDate) <= 0 AND DATEDIFF(DAY, a.RdDate, tax.endDate) >= 0;

        SELECT  db.SaleBldGUID ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.AffirmationNumber ELSE 0 END) BzTs ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.areatotal ELSE 0 END) BzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.totalamount ELSE 0 END) * 10000 BzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @zbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @zedate) >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 BzJeNotax ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.AffirmationNumber ELSE 0 END) newBzTs ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.areatotal ELSE 0 END) newBzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.totalamount ELSE 0 END) * 10000 newBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @newzbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @newzedate) >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 newBzJeNotax ,
				
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.AffirmationNumber ELSE 0 END) sBzTs ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.areatotal ELSE 0 END) sBzMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.totalamount ELSE 0 END) * 10000 sBzJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, @szbdate) <= 0 and DATEDIFF(DAY, a.RdDate, @szedate) >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 sBzJeNotax ,
				
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.AffirmationNumber ELSE 0 END) ByTs ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.areatotal ELSE 0 END) ByMj ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.totalamount ELSE 0 END) * 10000 ByJe ,
                SUM(CASE WHEN DATEDIFF(MONTH, a.RdDate, @zedate) = 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 ByJeNotax ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.AffirmationNumber ELSE 0 END) yjdTs ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.areatotal ELSE 0 END) yjdMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.totalamount ELSE 0 END) * 10000 yjdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-01-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-03-31') >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 yjdJeNotax ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.AffirmationNumber ELSE 0 END) ejdTs ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.areatotal ELSE 0 END) ejdMj ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.totalamount ELSE 0 END) * 10000 ejdJe ,
                SUM(CASE WHEN DATEDIFF(DAY, a.RdDate, '2025-04-01') <= 0 and DATEDIFF(DAY, a.RdDate, '2025-06-30') >= 0 THEN b.totalamount / (1 + a.rate)ELSE 0 END) * 10000 ejdJeNotax ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)') AND  DATEDIFF(yy, a.RdDate, @zedate) = 0  THEN b.AffirmationNumber ELSE 0 END) BNTs ,
                SUM(CASE WHEN (a.YjType <> '��Ӫ��(��ۿ�)')  AND  DATEDIFF(yy, a.RdDate, @zedate) = 0  THEN b.areatotal ELSE 0 END) BNMj ,
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
        WHERE   1 = 1 AND   YEAR(a.RdDate) = YEAR(@zedate) AND a.AuditStatus = '�����' AND  a.YjType IN(SELECT  TsyjTypeName FROM   s_TsyjType WHERE IsRelatedBuildingsRoom = 1)
                AND a.YjType IN ('��������', '��������', '��Ӫ��(��ۿ�)', '�ع�', '����', '������','��ҵ��˾��λ����')
        GROUP BY db.SaleBldGUID;

        --ȡ�ֹ�ά����ƥ���ϵ
        SELECT  ��Ŀguid ,
                T.������������ ,
                CASE WHEN ISNULL(T.ӯ���滮ϵͳ�Զ�ƥ������, '') <> '' THEN T.ӯ���滮ϵͳ�Զ�ƥ������ ELSE CASE WHEN ISNULL(T.ӯ���滮����, '') <> '' THEN T.ӯ���滮���� ELSE T.������������ END END ӯ���滮����
        INTO    #key
        FROM    dss.dbo.nmap_F_��Դ��ӯ���滮ҵ̬��������� T
                INNER JOIN(SELECT   ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM ,
                                    FillHistoryGUID
                           FROM dss.dbo.nmap_F_FillHistory a
                           WHERE   EXISTS (SELECT   1
                                           FROM dss.dbo.nmap_F_��Դ��ӯ���滮ҵ̬��������� b
                                           WHERE   a.FillHistoryGUID = b.FillHistoryGUID)) V ON T.FillHistoryGUID = V.FillHistoryGUID AND  V.NUM = 1
		where isnull(t.��Ŀguid,'')<>''; --ltx���� 2023-08-02

        SELECT  db.SaleBldGUID ,
                db.ProjGUID ,
                db.Product MyProduct ,
                ISNULL(dss.ӯ���滮����, db.Product) Product ,
                SUM(s.BzTs) BzTs ,
                SUM(s.BzMj) BzMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.BzTs ELSE s.BzMj END) BzmjNew ,
                SUM(s.BzJe) Bzje ,
                SUM(s.BzJeNotax) BzJeNotax ,
                SUM(s.newBzTs) newBzTs ,
                SUM(s.newBzMj) newBzMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.newBzTs ELSE s.newBzMj END) newBzmjNew ,
                SUM(s.newBzJe) newBzje ,
                SUM(s.newBzJeNotax) newBzJeNotax ,
				
                SUM(s.sBzTs) sBzTs ,
                SUM(s.sBzMj) sBzMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.sBzTs ELSE s.sBzMj END) sBzmjNew ,
                SUM(s.sBzJe) sBzje ,
                SUM(s.sBzJeNotax) sBzJeNotax ,
				
                SUM(s.ByTs) ByTs ,
                SUM(s.ByMJ) ByMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.ByTs ELSE s.ByMJ END) BymjNew ,
                SUM(s.ByJe) Byje ,
                SUM(s.ByJeNotax) ByJeNotax ,
                SUM(s.yjdTs) yjdTs ,
                SUM(s.yjdMj) yjdMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.yjdTs ELSE s.yjdMj END) yjdmjNew ,
                SUM(s.yjdJe) yjdJe ,
                SUM(s.yjdJeNotax) yjdJeNotax ,
                SUM(s.ejdTs) ejdTs ,
                SUM(s.ejdMj) ejdMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.ejdTs ELSE s.ejdMj END) ejdmjNew ,
                SUM(s.ejdJe) ejdJe ,
                SUM(s.ejdJeNotax) ejdJeNotax ,
                SUM(s.BnTs) BnTs ,
                SUM(s.BnMJ) BnMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.BnTs ELSE s.BnMJ END) BNmjNew ,
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
                LEFT JOIN(SELECT    DISTINCT k.��Ŀguid, k.������������, k.ӯ���滮���� FROM  #key k) dss ON dss.��Ŀguid = db.ProjGUID AND dss.������������ = db.Product  --ҵ̬ƥ��
        GROUP BY db.SaleBldGUID ,
                 db.Product ,
                 ISNULL(dss.ӯ���滮����, db.Product) ,
                 db.ProjGUID;


        SELECT  db.SaleBldGUID ,
                db.ProjGUID ,
                db.Product MyProduct ,
                ISNULL(dss.ӯ���滮����, db.Product) Product ,
				db.isccp,
                SUM(s.BzTs) BzTs ,
                SUM(s.BzMj) BzMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.BzTs ELSE s.BzMj END) BzmjNew ,
                SUM(s.BzJe) Bzje ,
                SUM(s.BzJeNotax) BzJeNotax ,
                SUM(s.newBzTs) newBzTs ,
                SUM(s.newBzMj) newBzMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.newBzTs ELSE s.newBzMj END) newBzmjNew ,
                SUM(s.newBzJe) newBzje ,
                SUM(s.newBzJeNotax) newBzJeNotax ,
				
                SUM(s.sBzTs) sBzTs ,
                SUM(s.sBzMj) sBzMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.sBzTs ELSE s.sBzMj END) sBzmjNew ,
                SUM(s.sBzJe) sBzje ,
                SUM(s.sBzJeNotax) sBzJeNotax ,
				
                SUM(s.ByTs) ByTs ,
                SUM(s.ByMJ) ByMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.ByTs ELSE s.ByMJ END) BymjNew ,
                SUM(s.ByJe) Byje ,
                SUM(s.ByJeNotax) ByJeNotax ,
                SUM(s.yjdTs) yjdTs ,
                SUM(s.yjdMj) yjdMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.yjdTs ELSE s.yjdMj END) yjdmjNew ,
                SUM(s.yjdJe) yjdJe ,
                SUM(s.yjdJeNotax) yjdJeNotax ,
                SUM(s.ejdTs) ejdTs ,
                SUM(s.ejdMj) ejdMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.ejdTs ELSE s.ejdMj END) ejdmjNew ,
                SUM(s.ejdJe) ejdJe ,
                SUM(s.ejdJeNotax) ejdJeNotax ,
                SUM(s.BnTs) BnTs ,
                SUM(s.BnMJ) BnMj ,
                SUM(CASE WHEN db.ProductType = '������/����' THEN s.BnTs ELSE s.BnMJ END) BNmjNew ,
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
                LEFT JOIN(SELECT    DISTINCT k.��Ŀguid, k.������������, k.ӯ���滮���� FROM  #key k) dss ON dss.��Ŀguid = db.ProjGUID AND dss.������������ = db.Product  --ҵ̬ƥ��
        GROUP BY db.SaleBldGUID ,
                 db.Product ,
                 ISNULL(dss.ӯ���滮����, db.Product) ,
                 db.ProjGUID,
				 db.isccp;


        --ӯ���滮
        -- Ӫҵ�ɱ����� 	 ���У��ؼ۵��� 	 ���У����ؼ���ֱͶ���� 	 ���У�������ӷѵ��� 	 ���У��ʱ�����Ϣ���� 	 
        --��Ȩ��۵��� 	 Ӫ�����õ��� 	 �ۺϹ�����õ��� 	 ˰�𼰸��ӵ��� 

        --OrgGuid,ƽ̨��˾,��Ŀguid,��Ŀ����,��Ŀ����,Ͷ�ܴ���,ӯ���滮���߷�ʽ,��Ʒ����,��Ʒ����,װ�ޱ�׼,��Ʒ����,ƥ������,
        --�ܿ������,�ܿ��۽��,������ֱͶ_����,���ؿ�_����,�ʱ�����Ϣ_�ۺϹ����_����,ӯ���滮Ӫҵ�ɱ�����,˰�𼰸��ӵ���,��Ȩ��۵���,
        --������õ���,Ӫ�����õ���,�ʱ�����Ϣ����,������ӷѵ���,��Ͷ�ʲ���˰���� ,ӯ���滮��λ��
        SELECT  ylgh.[��Ŀguid] ,
                ylgh.ƥ������ ҵ̬��ϼ� ,
                ylgh.�ܿ������ AS ӯ���滮�ܿ������ ,
                ylgh.ӯ���滮Ӫҵ�ɱ����� ,
                ylgh.���ؿ�_���� ,
                ylgh.������ֱͶ_���� ,
                ylgh.������ӷѵ��� ,
                ylgh.�ʱ�����Ϣ���� ,
                ylgh.��Ȩ��۵��� ӯ���滮��Ȩ��۵��� ,
                ylgh.Ӫ�����õ��� ӯ���滮Ӫ�����õ��� ,
                ylgh.������õ��� ӯ���滮�ۺϹ���ѵ���Э��ھ� ,
                ylgh.˰�𼰸��ӵ��� AS ӯ���滮˰�𼰸��ӵ���
        INTO    #ylgh
        FROM    dss.dbo.s_F066��Ŀë�������۵ױ�_ӯ���滮���� ylgh
                INNER JOIN #p p ON ylgh.��Ŀguid = p.ProjGUID;

        --select * from #ylgh

        --������Ŀ�ɱ�
        SELECT  a.SaleBldGUID ,
                a.ProjGUID ,
                a.MyProduct ,
                a.Product ,
                y.ӯ���滮Ӫҵ�ɱ����� ,
                y.���ؿ�_���� ,
                y.������ֱͶ_���� ,
                y.������ӷѵ��� ,
                y.�ʱ�����Ϣ���� ,
                y.ӯ���滮��Ȩ��۵��� ,
                y.ӯ���滮Ӫ�����õ��� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� ,
                y.ӯ���滮˰�𼰸��ӵ��� ,
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
                y.ӯ���滮Ӫҵ�ɱ����� * ISNULL(a.BzmjNew, 0) ӯ���滮Ӫҵ�ɱ����� ,
                y.ӯ���滮��Ȩ��۵��� * ISNULL(a.BzmjNew, 0) ӯ���滮��Ȩ��۱��� ,
                y.ӯ���滮Ӫ�����õ��� * ISNULL(a.BzmjNew, 0) ӯ���滮Ӫ�����ñ��� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� * ISNULL(a.BzmjNew, 0) ӯ���滮�ۺϹ���ѱ��� ,
                y.ӯ���滮˰�𼰸��ӵ��� * ISNULL(a.BzmjNew, 0) ӯ���滮˰�𼰸��ӱ��� ,
                y.ӯ���滮Ӫҵ�ɱ����� * ISNULL(a.newBzmjNew, 0) ӯ���滮Ӫҵ�ɱ��±��� ,
                y.ӯ���滮��Ȩ��۵��� * ISNULL(a.newBzmjNew, 0) ӯ���滮��Ȩ����±��� ,
                y.ӯ���滮Ӫ�����õ��� * ISNULL(a.newBzmjNew, 0) ӯ���滮Ӫ�������±��� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� * ISNULL(a.newBzmjNew, 0) ӯ���滮�ۺϹ�����±��� ,
                y.ӯ���滮˰�𼰸��ӵ��� * ISNULL(a.newBzmjNew, 0) ӯ���滮˰�𼰸����±��� ,
                y.ӯ���滮Ӫҵ�ɱ����� * ISNULL(a.BymjNew, 0) ӯ���滮Ӫҵ�ɱ����� ,
                y.ӯ���滮��Ȩ��۵��� * ISNULL(a.BymjNew, 0) ӯ���滮��Ȩ��۱��� ,
                y.ӯ���滮Ӫ�����õ��� * ISNULL(a.BymjNew, 0) ӯ���滮Ӫ�����ñ��� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� * ISNULL(a.BymjNew, 0) ӯ���滮�ۺϹ���ѱ��� ,
                y.ӯ���滮˰�𼰸��ӵ��� * ISNULL(a.BymjNew, 0) ӯ���滮˰�𼰸��ӱ��� ,
                y.ӯ���滮Ӫҵ�ɱ����� * ISNULL(a.yjdmjNew, 0) ӯ���滮Ӫҵ�ɱ�һ���� ,
                y.ӯ���滮��Ȩ��۵��� * ISNULL(a.yjdmjNew, 0) ӯ���滮��Ȩ���һ���� ,
                y.ӯ���滮Ӫ�����õ��� * ISNULL(a.yjdmjNew, 0) ӯ���滮Ӫ������һ���� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� * ISNULL(a.yjdmjNew, 0) ӯ���滮�ۺϹ����һ���� ,
                y.ӯ���滮˰�𼰸��ӵ��� * ISNULL(a.ejdmjNew, 0) ӯ���滮˰�𼰸���һ���� ,
                y.ӯ���滮Ӫҵ�ɱ����� * ISNULL(a.ejdmjNew, 0) ӯ���滮Ӫҵ�ɱ������� ,
                y.ӯ���滮��Ȩ��۵��� * ISNULL(a.ejdmjNew, 0) ӯ���滮��Ȩ��۶����� ,
                y.ӯ���滮Ӫ�����õ��� * ISNULL(a.ejdmjNew, 0) ӯ���滮Ӫ�����ö����� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� * ISNULL(a.yjdmjNew, 0) ӯ���滮�ۺϹ���Ѷ����� ,
                y.ӯ���滮˰�𼰸��ӵ��� * ISNULL(a.ejdmjNew, 0) ӯ���滮˰�𼰸��Ӷ����� ,
                y.ӯ���滮Ӫҵ�ɱ����� * ISNULL(a.BNmjNew, 0) ӯ���滮Ӫҵ�ɱ����� ,
                y.ӯ���滮��Ȩ��۵��� * ISNULL(a.BNmjNew, 0) ӯ���滮��Ȩ��۱��� ,
                y.ӯ���滮Ӫ�����õ��� * ISNULL(a.BNmjNew, 0) ӯ���滮Ӫ�����ñ��� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� * ISNULL(a.BNmjNew, 0) ӯ���滮�ۺϹ���ѱ��� ,
                y.ӯ���滮˰�𼰸��ӵ��� * ISNULL(a.BNmjNew, 0) ӯ���滮˰�𼰸��ӱ���
        INTO    #cost
        FROM    #sale a
                LEFT JOIN #ylgh y ON a.ProjGUID = y.[��Ŀguid] AND   a.Product = y.ҵ̬��ϼ�;

        SELECT  c.ProjGUID ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.BzJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���) / 100000000)) ��Ŀ˰ǰ������ ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.newBzJeNotax - c.ӯ���滮Ӫҵ�ɱ��±��� - c.ӯ���滮��Ȩ����±���) - c.ӯ���滮Ӫ�������±��� - c.ӯ���滮�ۺϹ�����±��� - c.ӯ���滮˰�𼰸����±���) / 100000000)) ��Ŀ˰ǰ�����±��� ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.ByJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���) / 100000000)) ��Ŀ˰ǰ������ ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.yjdJeNotax - c.ӯ���滮Ӫҵ�ɱ�һ���� - c.ӯ���滮��Ȩ���һ����) - c.ӯ���滮Ӫ������һ���� - c.ӯ���滮�ۺϹ����һ���� - c.ӯ���滮˰�𼰸���һ����) / 100000000)) ��Ŀ˰ǰ����һ���� ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.ejdJeNotax - c.ӯ���滮Ӫҵ�ɱ������� - c.ӯ���滮��Ȩ��۶�����) - c.ӯ���滮Ӫ�����ö����� - c.ӯ���滮�ۺϹ���Ѷ����� - c.ӯ���滮˰�𼰸��Ӷ�����) / 100000000)) ��Ŀ˰ǰ��������� ,
                SUM(CONVERT(DECIMAL(18, 8), ((c.BnJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���) / 100000000)) ��Ŀ˰ǰ������
        INTO    #xm
        FROM    #cost c
        GROUP BY c.ProjGUID;

        /* SaleBldGUID	ƽ̨��˾	��Ŀ����	Ͷ�ܴ���	��Ŀ��	�ƹ���	����	��Ŀ�����	��Ŀ���ֻ�	��ȡʱ��	��Ŀ״̬	����ʽ	��˾�ɱ�	�Ƿ�¼�����ҵ��	
���̷�ʽ	����ʽ	��Ʒ����	��Ʒ����	��Ʒ����	װ�ޱ�׼	����¥������	��Ʒ¥������	����¥��	ʵ�ʿ�����������	��������	�����������ʱ��	
���������ƻ����ʱ��	�Ƿ�����	�Ƿ����	�Ƿ��Գ�	��̬�ܿ�������	��̬�ܿ������	��̬�ܿ��ۻ�ֵ	ʣ���ܿ�������	ʣ���ܿ������	ʣ���ܿ��ۻ�ֵ	���ʣ���������	
���ʣ��������	���ʣ����ۻ�ֵ	������ǩԼ����	������ǩԼ���	������ǩԼ�������λ��������	������ǩԼ���	������ǩԼ����˰	������ǩԼ����	������ǩԼ���	
������ǩԼ�������λ��������	������ǩԼ���	������ǩԼ����˰	Ԥ�ⵥ��	����ǩԼ����	����ǩԼ����	�ۼ�ǩԼ����	Ԥ�Ʊ���ǩԼ�������λ��������	Ԥ�Ʊ���ǩԼ���	
ҵ̬��ϼ�_ҵ̬	dssƥ��ӯ���滮ҵ̬��ϼ�	Ӫҵ�ɱ�����	ӯ���滮��Ȩ��۵���	ӯ���滮Ӫ�����õ���	ӯ���滮�ۺϹ���ѵ���Э��ھ�	ӯ���滮˰�𼰸��ӵ���	������ǩԼ����˰	
������ǩԼ��ӦǩԼë����	������ǩԼ��ӦǩԼ������	������ǩԼ����˰	������ǩԼ��ӦǩԼë����	������ǩԼ��ӦǩԼ������
*/
        SELECT  NEWID() VersionGUID,
				A.DevelopmentCompanyGUID OrgGUID,
				a.SaleBldGUID ,
                f.ƽ̨��˾ ,
                f.��Ŀ���� ,
                f.Ͷ�ܴ��� ,
                f.��Ŀ�� ,
                f.�ƹ��� ,
                f.���� ,
                f.��Ŀ����� ,
                f.�������ֻ� ,
                f.��ȡʱ�� ,
                f.��Ŀ״̬ ,
                f.����ʽ ,
                f.��Ŀ��Ȩ���� ,
                f.�Ƿ�¼�����ҵ�� ,
                a.ProductType ��Ʒ���� ,
                a.ProductName ��Ʒ���� ,
                a.BusinessType ��Ʒ���� ,
                a.Standard װ�ޱ�׼ ,
                gc.BldName ����¥������ ,
                a.BldCode ��Ʒ¥������ ,
                pb.BldName ����¥�� ,
                th.thdate ʵ�ʿ����������� ,
                a.SJjgbadate �����������ʱ�� ,
                a.YJjgbadate ���������ƻ����ʱ�� ,
                c.BzTs ������ǩԼ���� ,
                c.BzMj ������ǩԼ��� ,
                c.BzmjNew [������ǩԼ�����λ������] ,
                c.Bzje ������ǩԼ��� ,
                c.BzJeNotax ������ǩԼ����˰ ,
                c.newBzTs �±�����ǩԼ���� ,
                c.newBzMj �±�����ǩԼ��� ,
                c.newBzmjNew [�±�����ǩԼ�����λ������] ,
                c.newBzje �±�����ǩԼ��� ,
                c.newBzJeNotax �±�����ǩԼ����˰ ,
                c.sBzTs ������ǩԼ���� ,
                c.sBzMj ������ǩԼ��� ,
                c.sBzmjNew [������ǩԼ�����λ������] ,
                c.sBzje ������ǩԼ��� ,
                c.sBzJeNotax ������ǩԼ����˰ ,
                c.ByTs ������ǩԼ���� ,
                c.ByMj ������ǩԼ��� ,
                c.BymjNew [������ǩԼ�����λ������] ,
                c.Byje ������ǩԼ��� ,
                c.ByJeNotax ������ǩԼ����˰ ,
                c.yjdTs һ������ǩԼ���� ,
                c.yjdMj һ������ǩԼ��� ,
                c.yjdmjNew [һ������ǩԼ�����λ������] ,
                c.yjdje һ������ǩԼ��� ,
                c.yjdJeNotax һ������ǩԼ����˰ ,
                c.ejdTs ��������ǩԼ���� ,
                c.ejdMj ��������ǩԼ��� ,
                c.ejdmjNew [��������ǩԼ�����λ������] ,
                c.ejdje ��������ǩԼ��� ,
                c.ejdJeNotax ��������ǩԼ����˰ ,
                c.BnTs ������ǩԼ���� ,
                c.BnMj ������ǩԼ��� ,
                c.BNmjNew [������ǩԼ�����λ������] ,
                c.BnJe ������ǩԼ��� ,
                c.BnJeNotax ������ǩԼ����˰ ,
                c.MyProduct ҵ̬��ϼ�_ҵ̬ ,
                c.Product dssƥ��ӯ���滮ҵ̬��ϼ� ,
                ((c.BzJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���)
                - CASE WHEN x.��Ŀ˰ǰ������ > 0 THEN ((c.BzJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���) * 0.25 ELSE 0 END ������ǩԼ��ӦǩԼ������ ,
                ((c.newBzJeNotax - c.ӯ���滮Ӫҵ�ɱ��±��� - c.ӯ���滮��Ȩ����±���) - c.ӯ���滮Ӫ�������±��� - c.ӯ���滮�ۺϹ�����±��� - c.ӯ���滮˰�𼰸����±���)
                - CASE WHEN x.��Ŀ˰ǰ�����±��� > 0 THEN ((c.newBzJeNotax - c.ӯ���滮Ӫҵ�ɱ��±��� - c.ӯ���滮��Ȩ����±���) - c.ӯ���滮Ӫ�������±��� - c.ӯ���滮�ۺϹ�����±��� - c.ӯ���滮˰�𼰸����±���) * 0.25 ELSE 0 END �±�����ǩԼ��ӦǩԼ������ ,
                ((c.ByJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���)
                - CASE WHEN x.��Ŀ˰ǰ������ > 0 THEN ((c.ByJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���) * 0.25 ELSE 0 END ������ǩԼ��ӦǩԼ������ ,
                ((c.yjdJeNotax - c.ӯ���滮Ӫҵ�ɱ�һ���� - c.ӯ���滮��Ȩ���һ����) - c.ӯ���滮Ӫ������һ���� - c.ӯ���滮�ۺϹ����һ���� - c.ӯ���滮˰�𼰸���һ����)
                - CASE WHEN x.��Ŀ˰ǰ����һ���� > 0 THEN ((c.yjdJeNotax - c.ӯ���滮Ӫҵ�ɱ�һ���� - c.ӯ���滮��Ȩ���һ����) - c.ӯ���滮Ӫ������һ���� - c.ӯ���滮�ۺϹ����һ���� - c.ӯ���滮˰�𼰸���һ����) * 0.25 ELSE 0 END һ������ǩԼ��ӦǩԼ������ ,
                ((c.ejdJeNotax - c.ӯ���滮Ӫҵ�ɱ������� - c.ӯ���滮��Ȩ��۶�����) - c.ӯ���滮Ӫ�����ö����� - c.ӯ���滮�ۺϹ���Ѷ����� - c.ӯ���滮˰�𼰸��Ӷ�����)
                - CASE WHEN x.��Ŀ˰ǰ��������� > 0 THEN ((c.ejdJeNotax - c.ӯ���滮Ӫҵ�ɱ������� - c.ӯ���滮��Ȩ��۶�����) - c.ӯ���滮Ӫ�����ö����� - c.ӯ���滮�ۺϹ���Ѷ����� - c.ӯ���滮˰�𼰸��Ӷ�����) * 0.25 ELSE 0 END ��������ǩԼ��ӦǩԼ������ ,
                ((c.BnJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���)
                - CASE WHEN x.��Ŀ˰ǰ������ > 0 THEN ((c.BnJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ��۱���) - c.ӯ���滮Ӫ�����ñ��� - c.ӯ���滮�ۺϹ���ѱ��� - c.ӯ���滮˰�𼰸��ӱ���) * 0.25 ELSE 0 END ������ǩԼ��ӦǩԼ������,
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
        ORDER BY f.ƽ̨��˾ ,
                 f.��Ŀ����;

        --and a.SaleBldGUId='A6EDF7D5-3F21-4F3C-809A-4A20049FAF44'

select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'2' num,
		'����21�꼰��ǰ��ȡ��Ŀ����Ʒ�Ϲ�' �ھ�,
		sum(BzJe)/100000000 ���ܽ��,
		sum(newBzJe)/100000000 �±��ܽ��,
		sum(sBzJe)/100000000 ���ܽ��,
		sum(Byje)/100000000 ���½��,
		sum(yjdJe)/100000000 һ���Ƚ��,
		sum(ejdje)/100000000 �����Ƚ��,
		sum(bnje)/100000000 ������
	into #sumccprg
	FROM #saleord a
	left join vmdm_projectflag f on a.projguid = f.projguid
	where a.isccp = '����Ʒ'
	and year(f.��ȡʱ��) <= 2021

        /* SaleBldGUID	ƽ̨��˾	��Ŀ����	Ͷ�ܴ���	��Ŀ��	�ƹ���	����	��Ŀ�����	��Ŀ���ֻ�	��ȡʱ��	��Ŀ״̬	����ʽ	��˾�ɱ�	�Ƿ�¼�����ҵ��	
���̷�ʽ	����ʽ	��Ʒ����	��Ʒ����	��Ʒ����	װ�ޱ�׼	����¥������	��Ʒ¥������	����¥��	ʵ�ʿ�����������	��������	�����������ʱ��	
���������ƻ����ʱ��	�Ƿ�����	�Ƿ����	�Ƿ��Գ�	��̬�ܿ�������	��̬�ܿ������	��̬�ܿ��ۻ�ֵ	ʣ���ܿ�������	ʣ���ܿ������	ʣ���ܿ��ۻ�ֵ	���ʣ���������	
���ʣ��������	���ʣ����ۻ�ֵ	������ǩԼ����	������ǩԼ���	������ǩԼ�������λ��������	������ǩԼ���	������ǩԼ����˰	������ǩԼ����	������ǩԼ���	
������ǩԼ�������λ��������	������ǩԼ���	������ǩԼ����˰	Ԥ�ⵥ��	����ǩԼ����	����ǩԼ����	�ۼ�ǩԼ����	Ԥ�Ʊ���ǩԼ�������λ��������	Ԥ�Ʊ���ǩԼ���	
ҵ̬��ϼ�_ҵ̬	dssƥ��ӯ���滮ҵ̬��ϼ�	Ӫҵ�ɱ�����	ӯ���滮��Ȩ��۵���	ӯ���滮Ӫ�����õ���	ӯ���滮�ۺϹ���ѵ���Э��ھ�	ӯ���滮˰�𼰸��ӵ���	������ǩԼ����˰	
������ǩԼ��ӦǩԼë����	������ǩԼ��ӦǩԼ������	������ǩԼ����˰	������ǩԼ��ӦǩԼë����	������ǩԼ��ӦǩԼ������
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
         �ھ�;



DROP TABLE 

           #sumqy,
           #sumqyfenlei,
           #sumxjl,
           #fy,
           #sumfeiyong,
		   #sumrg,
		   #ccpqyjll,#ord,#saleord,#sumccprg,#sumjk,#sumqyfenleis,
		   #bnskp,#skp,#sumrgfl,#sumrgflxx;