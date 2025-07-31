SELECT projguid,
       SUM(����ǩԼ���) / 10000 ����ǩԼ���
INTO #qy
FROM S_08ZYXSQYJB_HHZTSYJ_daily
WHERE DATEDIFF(dd, qxdate,GETDATE()) = 1
GROUP BY projguid;




--���Ԥ��&��ȷ���������ǩԼ����ɸ��˾��Ԥ�㷶Χ			
SELECT pj.projguid,
       SUM(FactAmount1 ) / 100000000 AS '�����̯һ���ѷ�������',
       SUM(FactAmount1+ FactAmount2 ) / 100000000 AS '�����̯һ�¶����ѷ�������',
       SUM(FactAmount1+ FactAmount2+FactAmount3) / 100000000 AS '�����̯һ�µ������ѷ�������',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4) / 100000000 AS '�����̯һ�µ������ѷ�������',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4+FactAmount5) / 100000000 AS '�����̯һ�µ������ѷ�������',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4+FactAmount5+FactAmount6) / 100000000 AS '�����̯һ�µ������ѷ�������',
       SUM(FactAmount1+ FactAmount2+FactAmount3+FactAmount4+FactAmount5+FactAmount6+FactAmount7) / 100000000 AS '�����̯һ�µ������ѷ�������',
       SUM(FactAmount1 + FactAmount2 + FactAmount3 + FactAmount4 + FactAmount5 + FactAmount6 + FactAmount7
           + FactAmount8 + FactAmount9 + FactAmount10 + FactAmount11 + FactAmount12
          ) / 100000000 AS '�����ѷ�������'
INTO #fy
FROM MyCost_Erp352.dbo.ys_YearPlanDept2Cost a
     INNER JOIN MyCost_Erp352.dbo.ys_DeptCost b ON b.DeptCostGUID = a.costguid
                                                   AND a.YEAR = b.YEAR
     INNER JOIN MyCost_Erp352.dbo.ys_SpecialBusinessUnit u ON a.DeptGUID = u.SpecialUnitGUID
     INNER JOIN p_project p ON u.ProjGUID = p.ProjGUID
     INNER JOIN erp25.dbo.vmdm_projectFlag pj ON p.projguid = pj.projguid
     INNER JOIN MyCost_Erp352.dbo.ys_fy_DimCost dim ON dim.costguid = a.costguid
                                                       AND dim.year = a.year
                                                       AND dim.IsEndCost = 1
WHERE a.year = YEAR(GETDATE())
AND  b.costtype = 'Ӫ����'
GROUP BY pj.projguid;



SELECT f.projguid,
       f.ƽ̨��˾,
       f.��Ŀ����,
       f.Ͷ�ܴ���,
       f.��Ŀ��,
       f.�ƹ���,
       f.��ȡʱ��,
       f.���̷�ʽ,
       f.Ӫ�����̷�,
       ISNULL(qy.����ǩԼ���, 0) ����ǩԼ���,
       ISNULL(fy.�����̯һ���ѷ�������, 0) �����̯һ���ѷ�������,
       ISNULL(fy.�����̯һ�¶����ѷ�������, 0) �����̯һ�¶����ѷ�������,
       ISNULL(fy.�����̯һ�µ������ѷ�������, 0) �����̯һ�µ������ѷ�������,
       ISNULL(fy.�����̯һ�µ������ѷ�������, 0) �����̯һ�µ������ѷ�������,
       ISNULL(fy.�����̯һ�µ������ѷ�������, 0) �����̯һ�µ������ѷ�������,
       ISNULL(fy.�����̯һ�µ������ѷ�������, 0) �����̯һ�µ������ѷ�������,
       ISNULL(fy.�����̯һ�µ������ѷ�������, 0) �����̯һ�µ������ѷ�������,
       ISNULL(fy.�����ѷ�������, 0) �����ѷ�������
FROM vmdm_projectflag f
     LEFT JOIN #qy qy ON f.projguid = qy.projguid
     LEFT JOIN #fy fy ON f.projguid = fy.projguid
ORDER BY f.ƽ̨��˾,
         f.��Ŀ����;

DROP TABLE #fy,
           #qy;
