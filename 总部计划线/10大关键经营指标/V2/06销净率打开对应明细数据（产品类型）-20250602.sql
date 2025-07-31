DECLARE @zedate DATETIME;
DECLARE @zbdate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;
DECLARE @szedate DATETIME;
DECLARE @szbdate DATETIME;
--�����������յ��������������վ�������������Ӧ����ϴ���ݲ�
SET @zbdate = '2025-07-07';
SET @zedate = '2025-07-13';
SET @newzbdate = '2025-07-07';
SET @newzedate = '2025-07-13';
SET @szbdate = '2025-06-30';
SET @szedate = '2025-07-06';


SELECT projguid,
		ProductType,
       SUM(zksmj - ysmj) / 10000 symj
INTO #symj
FROM p_lddbamj
WHERE DATEDIFF(dd, qxdate, '2024-12-31') = 0
      AND producttype <> '������/����'
GROUP BY projguid,
		ProductType;


--��ȡ24��ľ�����
SELECT a.projguid,
       p.AcquisitionDate,
		 a.��Ʒ����,
       SUM(����ǩԼ���) ����ǩԼ���,
       SUM(����ǩԼ����˰) ����ǩԼ����˰,
       SUM(���꾻����ǩԼ) ���꾻����ǩԼ,
       CASE
           WHEN SUM(����ǩԼ����˰) <> 0 THEN
                SUM(���꾻����ǩԼ) / SUM(����ǩԼ����˰)
           ELSE 0
       END ����������
INTO #jjl
FROM s_M002��Ŀ��ë���������ܱ�New a
     LEFT JOIN mdm_project p ON a.projguid = p.projguid
WHERE DATEDIFF(DAY, qxdate, '2024-12-31') = 0
GROUP BY a.projguid,
         p.AcquisitionDate,
		 a.��Ʒ����;

--��ȡ24���ۼ�ǩԼ
SELECT projguid,
		 ��Ʒ����,
       SUM(�ۼ�ǩԼ���) �ۼ�ǩԼ���
INTO #ljqy24
FROM S_08ZYXSQYJB_HHZTSYJ_daily
WHERE DATEDIFF(DAY, qxdate, '2024-12-31') = 0
GROUP BY projguid,
		 ��Ʒ����;


--��ȡ���ܱ�������
SELECT a.projguid,
		a.��Ʒ����,
       ISNULL(a.����ǩԼ���, 0) - ISNULL(b.����ǩԼ���, 0) ����ǩԼ���,
       ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0) ����ǩԼ����˰,
       ISNULL(a.���꾻����ǩԼ, 0) - ISNULL(b.���꾻����ǩԼ, 0) ���ܾ�����ǩԼ,
       CASE
           WHEN ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0) <> 0 THEN
       (ISNULL(a.���꾻����ǩԼ, 0) - ISNULL(b.���꾻����ǩԼ, 0)) / (ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0))
           ELSE 0
       END ���ܾ�����,
       ISNULL(c.����ǩԼ���, 0) - ISNULL(bb.����ǩԼ���, 0) �±���ǩԼ���,
       ISNULL(c.����ǩԼ����˰, 0) - ISNULL(bb.����ǩԼ����˰, 0) �±���ǩԼ����˰,
       ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(bb.���꾻����ǩԼ, 0) �±��ܾ�����ǩԼ,
       CASE
           WHEN ISNULL(c.����ǩԼ����˰, 0) - ISNULL(bb.����ǩԼ����˰, 0) <> 0 THEN
       (ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(bb.���꾻����ǩԼ, 0)) / (ISNULL(c.����ǩԼ����˰, 0) - ISNULL(bb.����ǩԼ����˰, 0))
           ELSE 0
       END �±��ܾ�����,
       ISNULL(sa.����ǩԼ���, 0) - ISNULL(sb.����ǩԼ���, 0) ����ǩԼ���,
       ISNULL(sa.����ǩԼ����˰, 0) - ISNULL(sb.����ǩԼ����˰, 0) ����ǩԼ����˰,
       ISNULL(sa.���꾻����ǩԼ, 0) - ISNULL(sb.���꾻����ǩԼ, 0) ���ܾ�����ǩԼ,
       CASE
           WHEN ISNULL(sa.����ǩԼ����˰, 0) - ISNULL(sb.����ǩԼ����˰, 0) <> 0 THEN
       (ISNULL(sa.���꾻����ǩԼ, 0) - ISNULL(sb.���꾻����ǩԼ, 0)) / (ISNULL(sa.����ǩԼ����˰, 0) - ISNULL(sb.����ǩԼ����˰, 0))
           ELSE 0
       END ���ܾ�����,
       ISNULL(c.����ǩԼ���, 0) ����ǩԼ���,
       ISNULL(c.����ǩԼ����˰, 0) ����ǩԼ����˰,
       ISNULL(c.���¾�����ǩԼ, 0) ���¾�����ǩԼ,
       c.���¾�����,
       c.����������,
       ISNULL(d.����ǩԼ���, 0) һ����ǩԼ���,
       ISNULL(d.����ǩԼ����˰, 0) һ����ǩԼ����˰,
       ISNULL(d.���꾻����ǩԼ, 0) һ���Ⱦ�����ǩԼ,
       d.���������� һ���Ⱦ�����,
       ISNULL(e.����ǩԼ���, 0) ����ǩԼ���,
       ISNULL(e.����ǩԼ����˰, 0) ����ǩԼ����˰,
       ISNULL(e.���¾�����ǩԼ, 0) ���¾�����ǩԼ,
       e.���¾����� ���¾�����,
       ISNULL(f.����ǩԼ���, 0) ����ǩԼ���,
       ISNULL(f.����ǩԼ����˰, 0) ����ǩԼ����˰,
       ISNULL(f.���¾�����ǩԼ, 0) ���¾�����ǩԼ,
       f.���¾����� ���¾�����
INTO #benzhou
FROM
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���¾�����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ���¾�����
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
    GROUP BY projguid,
		 ��Ʒ����
) a
LEFT JOIN
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
    GROUP BY projguid,
		 ��Ʒ����
) b ON a.projguid = b.projguid and a.��Ʒ���� = b.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
    GROUP BY projguid,
		 ��Ʒ����
) bb ON a.projguid = bb.projguid and a.��Ʒ���� = bb.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���¾�����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ���¾�����,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���꾻����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ����������
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
    GROUP BY projguid,
		 ��Ʒ����
) c ON a.projguid = c.projguid and a.��Ʒ���� = c.��Ʒ����

LEFT JOIN
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���¾�����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ���¾�����,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���꾻����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ����������
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
    GROUP BY projguid,
		 ��Ʒ����
) d ON a.projguid = d.projguid and a.��Ʒ���� = d.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���¾�����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ���¾�����,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���꾻����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ����������
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, '2025-04-30') = 0
    GROUP BY projguid,
		 ��Ʒ����
) e ON a.projguid = e.projguid and a.��Ʒ���� = e.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���¾�����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ���¾�����,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���꾻����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ����������
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, '2025-04-30') = 0
    GROUP BY projguid,
		 ��Ʒ����
) f ON a.projguid = f.projguid and a.��Ʒ���� = f.��Ʒ����
LEFT JOIN 
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ,
           CASE
               WHEN SUM(����ǩԼ����˰) <> 0 THEN
                    SUM(���¾�����ǩԼ) / SUM(����ǩԼ����˰)
               ELSE 0
           END ���¾�����
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @szedate) = 0
    GROUP BY projguid,
		 ��Ʒ����
) sa ON a.projguid = sa.projguid and a.��Ʒ���� = sa.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
		 ��Ʒ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @szbdate) = 1
    GROUP BY projguid,
		 ��Ʒ����
) sb ON a.projguid = sb.projguid and a.��Ʒ���� = sb.��Ʒ����;


SELECT f.projguid,
       f.ƽ̨��˾,
       f.��Ŀ����,
       f.Ͷ�ܴ���,
       f.��Ŀ��,
       f.�ƹ���,
       f.��ȡʱ��,
	   f.��Ŀ״̬,
       CASE
           WHEN YEAR(f.��ȡʱ��) IN ( '2024', '2025' ) THEN
                '24��25���ȡ'
           WHEN YEAR(f.��ȡʱ��) IN ( '2022', '2023' ) THEN
                '22��23���ȡ'
           ELSE '������21�꼰֮ǰ��ȡ��'
       END ��Ŀ����,
	   a.��Ʒ����,
       CASE
           WHEN YEAR(f.��ȡʱ��) IN ( '2024', '2025' ) THEN
                '8'
           WHEN YEAR(f.��ȡʱ��) IN ( '2022', '2023' ) THEN
                '7'
           ELSE CASE
                    WHEN j.���������� >= 0 THEN
                         '1'
                    WHEN j.���������� >= -0.1
                         AND j.���������� < 0 THEN
                         '2'
                    WHEN j.���������� >= -0.2
                         AND j.���������� < -0.1 THEN
                         '3'
                    WHEN j.���������� >= -0.3
                         AND j.���������� < -0.2 THEN
                         '4'
                    ELSE '5'
                END
       END num,
       CASE
           WHEN YEAR(f.��ȡʱ��) IN ( '2024', '2025' ) THEN
                '24��25���ȡ'
           WHEN YEAR(f.��ȡʱ��) IN ( '2022', '2023' ) THEN
                '22��23���ȡ'
           ELSE CASE
                    WHEN j.���������� >= 0 THEN
                         '��0%'
                    WHEN j.���������� >= -0.1
                         AND j.���������� < 0 THEN
                         '-10%��0%'
                    WHEN j.���������� >= -0.2
                         AND j.���������� < -0.1 THEN
                         '-20%��-10%'
                    WHEN j.���������� >= -0.3
                         AND j.���������� < -0.2 THEN
                         '-30%��-20%'
                    ELSE '��-30%'
                END
       END [24����Ŀ����],
       CASE
           WHEN YEAR(f.��ȡʱ��) IN ( '2024', '2025' ) THEN
                '24��25���ȡ'
           WHEN YEAR(f.��ȡʱ��) IN ( '2022', '2023' ) THEN
                '22��23���ȡ'
           ELSE CASE
                    WHEN a.���������� >= 0 THEN
                         '��0%'
                    WHEN a.���������� >= -0.1
                         AND a.���������� < 0 THEN
                         '-10%��0%'
                    WHEN a.���������� >= -0.2
                         AND a.���������� < -0.1 THEN
                         '-20%��-10%'
                    WHEN a.���������� >= -0.3
                         AND a.���������� < -0.2 THEN
                         '-30%��-20%'
                    ELSE '��-30%'
                END
       END [25����Ŀ����],
       s.symj '24�����ʣ�����',
       l.�ۼ�ǩԼ��� '��ֹ24���ǩԼ���',
       j.����ǩԼ��� '24��ǩԼ���',
       j.����ǩԼ����˰ '24��ǩԼ����˰',
       j.���꾻����ǩԼ '24�꾻����ǩԼ',
       j.���������� * 1.00 '24�꾻����',
       a.���������� * 1.00 '���꾻����',
       a.����ǩԼ���,
       a.����ǩԼ����˰,
       a.���ܾ�����ǩԼ,
       a.���ܾ�����,
       a.�±���ǩԼ���,
       a.�±���ǩԼ����˰,
       a.�±��ܾ�����ǩԼ,
       a.�±��ܾ�����,
       a.����ǩԼ���,
       a.����ǩԼ����˰,
       a.���ܾ�����ǩԼ,
       a.���ܾ�����,
       a.һ����ǩԼ���,
       a.һ����ǩԼ����˰,
       a.һ���Ⱦ�����ǩԼ,
       a.����ǩԼ���,
       a.����ǩԼ����˰,
       a.���¾�����ǩԼ,
       a.����ǩԼ���,
       a.����ǩԼ����˰,
       a.���¾�����ǩԼ,
       a.����ǩԼ���,
       a.����ǩԼ����˰,
       a.���¾�����ǩԼ,
       a.���¾����� * 1.00 ���¾�����,
       CASE
           WHEN f.��ȡʱ�� IS NOT NULL
                AND
                (
                    (
                        YEAR(f.��ȡʱ��) < 2024
                        AND s.symj >= 1
                    )
                    OR ISNULL(s.symj, 1) >= 1
                ) THEN
                '��'
           ELSE '��'
       END �Ƿ�ͳ��
FROM #benzhou a
     LEFT JOIN #jjl j ON a.projguid = j.projguid and j.��Ʒ���� = a.��Ʒ����
     LEFT JOIN #ljqy24 l ON a.projguid = l.projguid and l.��Ʒ���� = a.��Ʒ����
     LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
     LEFT JOIN #symj s ON a.projguid = s.projguid and s.ProductType = a.��Ʒ����
ORDER BY f.ƽ̨��˾,
         f.��Ŀ����;



DROP TABLE #benzhou,
           #jjl,
           #ljqy24,
           #symj;
