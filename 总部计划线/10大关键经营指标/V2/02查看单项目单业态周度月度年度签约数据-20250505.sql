DECLARE @zbdate DATETIME;
DECLARE @zedate DATETIME;
DECLARE @newzbdate DATETIME;
DECLARE @newzedate DATETIME;

SET @zbdate = '2025-07-07';
SET @zedate = '2025-07-13';
SET @newzbdate = '2025-07-07';
SET @newzedate = '2025-07-13';



--��������ë����
SELECT f.ƽ̨��˾,
       f.��Ŀ��,
       f.�ƹ���,
	   f.����,
       f.��Ŀ����,
       f.Ͷ�ܴ���,
       f.��ȡʱ��,
       a.��Ʒ����,
       SUM(ISNULL(a.����ǩԼ����, 0) - ISNULL(b.����ǩԼ����, 0)) ����ǩԼ����,
       SUM(ISNULL(a.����ǩԼ���, 0) - ISNULL(b.����ǩԼ���, 0)) ����ǩԼ���,
       SUM(ISNULL(a.����ǩԼ���, 0) - ISNULL(b.����ǩԼ���, 0)) ����ǩԼ���,
       SUM(ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0)) ����ǩԼ����˰,
       SUM(ISNULL(a.���꾻����ǩԼ, 0) - ISNULL(b.���꾻����ǩԼ, 0)) ���ܾ�����ǩԼ,
       CASE
           WHEN SUM(ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0)) > 0 THEN
                SUM(ISNULL(a.���꾻����ǩԼ, 0) - ISNULL(b.���꾻����ǩԼ, 0)) / SUM(ISNULL(a.����ǩԼ����˰, 0) - ISNULL(b.����ǩԼ����˰, 0))
           ELSE 0
       END ���ܾ�����,
       SUM(ISNULL(c.����ǩԼ����, 0) - ISNULL(bb.����ǩԼ����, 0)) �±���ǩԼ����,
       SUM(ISNULL(c.����ǩԼ���, 0) - ISNULL(bb.����ǩԼ���, 0)) �±���ǩԼ���,
       SUM(ISNULL(c.����ǩԼ���, 0) - ISNULL(bb.����ǩԼ���, 0)) �±���ǩԼ���,
       SUM(ISNULL(c.����ǩԼ����˰, 0) - ISNULL(bb.����ǩԼ����˰, 0)) �±���ǩԼ����˰,
       SUM(ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(bb.���꾻����ǩԼ, 0)) �±��ܾ�����ǩԼ,
       CASE
           WHEN SUM(ISNULL(c.����ǩԼ����˰, 0) - ISNULL(bb.����ǩԼ����˰, 0)) > 0 THEN
                SUM(ISNULL(c.���꾻����ǩԼ, 0) - ISNULL(bb.���꾻����ǩԼ, 0)) / SUM(ISNULL(c.����ǩԼ����˰, 0) - ISNULL(bb.����ǩԼ����˰, 0))
           ELSE 0
       END �±��ܾ�����,
       SUM(ISNULL(d.����ǩԼ����, 0)) һ����ǩԼ����,
       SUM(ISNULL(d.����ǩԼ���, 0)) һ����ǩԼ���,
       SUM(ISNULL(d.����ǩԼ���, 0)) һ����ǩԼ���,
       SUM(ISNULL(d.����ǩԼ����˰, 0)) һ����ǩԼ����˰,
       SUM(ISNULL(d.���꾻����ǩԼ, 0)) һ���Ⱦ�����ǩԼ,
       CASE
           WHEN SUM(ISNULL(d.����ǩԼ����˰, 0)) > 0 THEN
                SUM(ISNULL(d.���꾻����ǩԼ, 0)) / SUM(ISNULL(d.����ǩԼ����˰, 0))
           ELSE 0
       END һ���Ⱦ�����,
       SUM(ISNULL(c.����ǩԼ����, 0)) ����ǩԼ����,
       SUM(ISNULL(c.����ǩԼ���, 0)) ����ǩԼ���,
       SUM(ISNULL(c.����ǩԼ���, 0)) ����ǩԼ���,
       SUM(ISNULL(c.����ǩԼ����˰, 0)) ����ǩԼ����˰,
       SUM(ISNULL(c.���¾�����ǩԼ, 0)) ���¾�����ǩԼ,
       CASE
           WHEN SUM(ISNULL(c.����ǩԼ����˰, 0)) > 0 THEN
                SUM(ISNULL(c.���¾�����ǩԼ, 0)) / SUM(ISNULL(c.����ǩԼ����˰, 0))
           ELSE 0
       END ���¾�����,
       SUM(ISNULL(a.����ǩԼ����, 0)) ����ǩԼ����,
       SUM(ISNULL(a.����ǩԼ���, 0)) ����ǩԼ���,
       SUM(ISNULL(a.����ǩԼ���, 0)) ����ǩԼ���,
       SUM(ISNULL(a.����ǩԼ����˰, 0)) ����ǩԼ����˰,
       SUM(ISNULL(a.���꾻����ǩԼ, 0)) ���꾻����ǩԼ,
       CASE
           WHEN SUM(ISNULL(a.����ǩԼ����˰, 0)) > 0 THEN
                SUM(ISNULL(a.���꾻����ǩԼ, 0)) / SUM(ISNULL(a.����ǩԼ����˰, 0))
           ELSE 0
       END ���꾻����
FROM
(
    SELECT projguid,
           ��Ʒ����,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @zedate) = 0
    GROUP BY projguid,
             ��Ʒ����
) a
LEFT JOIN vmdm_projectflag f ON a.projguid = f.projguid
LEFT JOIN
(
    SELECT projguid,
           ��Ʒ����,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @zbdate) = 1
    GROUP BY projguid,
             ��Ʒ����
) b ON a.projguid = b.projguid
       AND a.��Ʒ���� = b.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
           ��Ʒ����,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @newzbdate) = 1
    GROUP BY projguid,
             ��Ʒ����
) bb ON a.projguid = bb.projguid
       AND a.��Ʒ���� = bb.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
           ��Ʒ����,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, @newzedate) = 0
    GROUP BY projguid,
             ��Ʒ����
) c ON a.projguid = c.projguid
       AND a.��Ʒ���� = c.��Ʒ����
LEFT JOIN
(
    SELECT projguid,
           ��Ʒ����,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����) ����ǩԼ����,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ���) ����ǩԼ���,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���¾�����ǩԼ) ���¾�����ǩԼ,
           SUM(����ǩԼ����˰) ����ǩԼ����˰,
           SUM(���꾻����ǩԼ) ���꾻����ǩԼ
    FROM s_M002��Ŀ��ë���������ܱ�New
    WHERE DATEDIFF(DAY, qxdate, '2025-03-31') = 0
    GROUP BY projguid,
             ��Ʒ����
) d ON a.projguid = d.projguid
       AND a.��Ʒ���� = d.��Ʒ����
GROUP BY f.ƽ̨��˾,
         f.��Ŀ��,
         f.�ƹ���,
	   f.����,
         f.��Ŀ����,
         f.Ͷ�ܴ���,
         f.��ȡʱ��,
         a.��Ʒ����
HAVING (SUM(ISNULL(a.����ǩԼ���, 0))) > 0
ORDER BY f.ƽ̨��˾,
         f.��Ŀ����,
         a.��Ʒ����;
