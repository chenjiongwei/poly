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
				a.ytwsje,
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
        WHERE   a.Status = '����' AND YEAR(a.QSDate) = YEAR(@zedate) 
				and DATEDIFF(dd,a.QSDate,@zedate) >= 0 
				AND EXISTS (SELECT 1 FROM  #db db WHERE db.SaleBldGUID = r.BldGUID)
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
        WHERE   (a.Status = '����' or (a.CloseReason ='תǩԼ' and d.Status = '����'))  AND YEAR(a.QSDate) = YEAR(@zedate) 
				and DATEDIFF(dd,a.QSDate,@zedate) >= 0 
				AND EXISTS (SELECT 1 FROM  #db db WHERE db.SaleBldGUID = r.BldGUID)
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
        WHERE   b.Shenhe = '���' 
				and DATEDIFF(dd,b.CreateDate,@zedate) >= 0 ;

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
				and DATEDIFF(dd,a.rddate,@zedate) >= 0
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
				
                y.ӯ���滮Ӫҵ�ɱ����� * ISNULL(a.sBzmjNew, 0) ӯ���滮Ӫҵ�ɱ����� ,
                y.ӯ���滮��Ȩ��۵��� * ISNULL(a.sBzmjNew, 0) ӯ���滮��Ȩ������� ,
                y.ӯ���滮Ӫ�����õ��� * ISNULL(a.sBzmjNew, 0) ӯ���滮Ӫ���������� ,
                y.ӯ���滮�ۺϹ���ѵ���Э��ھ� * ISNULL(a.sBzmjNew, 0) ӯ���滮�ۺϹ�������� ,
                y.ӯ���滮˰�𼰸��ӵ��� * ISNULL(a.sBzmjNew, 0) ӯ���滮˰�𼰸������� ,

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
                SUM(CONVERT(DECIMAL(18, 8), ((c.sBzJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ�������) - c.ӯ���滮Ӫ���������� - c.ӯ���滮�ۺϹ�������� - c.ӯ���滮˰�𼰸�������) / 100000000)) ��Ŀ˰ǰ�������� ,
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
				
                ((c.sBzJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ�������) - c.ӯ���滮Ӫ���������� - c.ӯ���滮�ۺϹ�������� - c.ӯ���滮˰�𼰸�������)
                - CASE WHEN x.��Ŀ˰ǰ�������� > 0 THEN ((c.sBzJeNotax - c.ӯ���滮Ӫҵ�ɱ����� - c.ӯ���滮��Ȩ�������) - c.ӯ���滮Ӫ���������� - c.ӯ���滮�ۺϹ�������� - c.ӯ���滮˰�𼰸�������) * 0.25 ELSE 0 END ������ǩԼ��ӦǩԼ������ ,

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
		'1' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlbz
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, @zbdate) = 0
	and (datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 )
	and	year(f.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'1' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #shlbz
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, @szbdate) = 0
	and (datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 )
	and	year(f.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'1' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlby
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-05-01') = 0
	and 
	(datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 --����Ʒ��ʵ�ʿ�������ʱ��������
	--or 
	--(datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ) --׼����Ʒ��ʵ�ʿ�����ƻ������ڱ���
	)
	and	year(f.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'1' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlyjd
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-01-01') = 0
	and 
	(datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 --����Ʒ��ʵ�ʿ�������ʱ��������
	--or 
	--(datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ) --׼����Ʒ��ʵ�ʿ�����ƻ������ڱ���
	)
	and	year(f.��ȡʱ��) <= 2021

	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'1' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlejd
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-04-01') = 0
	and 
	(datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 --����Ʒ��ʵ�ʿ�������ʱ��������
	--or 
	--(datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ) --׼����Ʒ��ʵ�ʿ�����ƻ������ڱ���
	)
	and	year(f.��ȡʱ��) <= 2021

	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'1' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlbn
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-01-01') = 0
	and 
	(datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 --����Ʒ��ʵ�ʿ�������ʱ��������
	--or 
	--(datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ) --׼����Ʒ��ʵ�ʿ�����ƻ������ڱ���
	)
	and	year(f.��ȡʱ��) <= 2021

	select a.buguid,
	a.num,
	a.�ھ�,
	a.��� ���ܽ��,
	a.��� �±��ܽ��,
	sa.��� ���ܽ��,
	c.��� ���½��,
	d.��� һ���Ƚ��,
	e.��� �����Ƚ��,
	f.��� ������
	into #sumccphl
	from #hlbz a
	left join #shlbz sa on 1=1
	left join #hlbz b on 1=1
	left join #hlby c on 1=1
	left join #hlyjd d on 1=1
	left join #hlejd e on 1=1
	left join #hlbn f on 1=1

select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'2' num,
		'�Ϲ����' �ھ�,
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

select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'3' num,
		'ǩԼ���' �ھ�,
		sum(������ǩԼ���)/100000000 ���ܽ��,
		sum(�±�����ǩԼ���)/100000000 �±��ܽ��,
		sum(������ǩԼ���)/100000000 ���ܽ��,
		sum(������ǩԼ���)/100000000 ���½��,
		sum(һ������ǩԼ���)/100000000 һ���Ƚ��,
		sum(��������ǩԼ���)/100000000 �����Ƚ��,
		sum(������ǩԼ���)/100000000 ������
	into #sumccpqy
	FROM #ccpqyjll a
	where a.isccp = '����Ʒ'
	and year(a.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'4' num,
		'ǩԼ������' �ھ�,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���ܽ��,
		case when sum(�±�����ǩԼ����˰) = 0 then 0 else 
			sum(�±�����ǩԼ��ӦǩԼ������)/sum(�±�����ǩԼ����˰) end �±��ܽ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���ܽ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���½��,
		case when sum(һ������ǩԼ����˰) = 0 then 0 else 
			sum(һ������ǩԼ��ӦǩԼ������)/sum(һ������ǩԼ����˰) end һ���Ƚ��,
		case when sum(��������ǩԼ����˰) = 0 then 0 else 
			sum(��������ǩԼ��ӦǩԼ������)/sum(��������ǩԼ����˰) end �����Ƚ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ������
	into #sumccpqyjll
	FROM #ccpqyjll a
	where a.isccp = '����Ʒ'
	and year(a.��ȡʱ��) <= 2021
	


select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'5' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlbzzccp
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, @zbdate) = 0
	and ((datediff(dd,a.SJjgbadate,'2024-12-31') <0 or a.SJjgbadate is null ) and (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ))
	and	year(f.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'5' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #shlbzzccp
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, @szbdate) = 0
	and ((datediff(dd,a.SJjgbadate,'2024-12-31') <0 or a.SJjgbadate is null ) and (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ))
	and	year(f.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'5' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlbyzccp
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-05-01') = 0
	and 
	((datediff(dd,a.SJjgbadate,'2024-12-31') <0 or a.SJjgbadate is null ) and (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ))
	and	year(f.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'5' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlyjdzccp
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-01-01') = 0
	and 
	((datediff(dd,a.SJjgbadate,'2024-12-31') <0 or a.SJjgbadate is null ) and (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ))
	and	year(f.��ȡʱ��) <= 2021

	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'5' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlejdzccp
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-04-01') = 0
	and 
	((datediff(dd,a.SJjgbadate,'2024-12-31') <0 or a.SJjgbadate is null ) and (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ))
	and	year(f.��ȡʱ��) <= 2021

	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'5' num,
		'�������' �ھ�,
		sum(a.zhz - a.ysje)/100000000 ���
	into #hlbnzccp
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, '2025-01-01') = 0
	and 
	((datediff(dd,a.SJjgbadate,'2024-12-31') <0 or a.SJjgbadate is null ) and (datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 ))
	and	year(f.��ȡʱ��) <= 2021

	select a.buguid,
	a.num,
	a.�ھ�,
	a.��� ���ܽ��,
	a.��� �±��ܽ��,
	sa.��� ���ܽ��,
	c.��� ���½��,
	d.��� һ���Ƚ��,
	e.��� �����Ƚ��,
	f.��� ������
	into #sumzccphl
	from #hlbzzccp a
	left join #hlbzzccp sa on 1=1
	left join #hlbzzccp b on 1=1
	left join #hlbyzccp c on 1=1
	left join #hlyjdzccp d on 1=1
	left join #hlejdzccp e on 1=1
	left join #hlbnzccp f on 1=1


select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'6' num,
		'�Ϲ����' �ھ�,
		sum(BzJe)/100000000 ���ܽ��,
		sum(newBzJe)/100000000 �±��ܽ��,
		sum(sBzJe)/100000000 ���ܽ��,
		sum(Byje)/100000000 ���½��,
		sum(yjdJe)/100000000 һ���Ƚ��,
		sum(ejdje)/100000000 �����Ƚ��,
		sum(bnje)/100000000 ������
	into #sumzccprg
	FROM #saleord a
	left join vmdm_projectflag f on a.projguid = f.projguid
	where a.isccp = '׼����Ʒ'
	and year(f.��ȡʱ��) <= 2021

select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'7' num,
		'ǩԼ���' �ھ�,
		sum(������ǩԼ���)/100000000 ���ܽ��,
		sum(�±�����ǩԼ���)/100000000 �±��ܽ��,
		sum(������ǩԼ���)/100000000 ���ܽ��,
		sum(������ǩԼ���)/100000000 ���½��,
		sum(һ������ǩԼ���)/100000000 һ���Ƚ��,
		sum(��������ǩԼ���)/100000000 �����Ƚ��,
		sum(������ǩԼ���)/100000000 ������
	into #sumzccpqy
	FROM #ccpqyjll a
	where a.isccp = '׼����Ʒ'
	and year(a.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'8' num,
		'ǩԼ������' �ھ�,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���ܽ��,
		case when sum(�±�����ǩԼ����˰) = 0 then 0 else 
			sum(�±�����ǩԼ��ӦǩԼ������)/sum(�±�����ǩԼ����˰) end �±��ܽ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���ܽ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���½��,
		case when sum(һ������ǩԼ����˰) = 0 then 0 else 
			sum(һ������ǩԼ��ӦǩԼ������)/sum(һ������ǩԼ����˰) end һ���Ƚ��,
		case when sum(��������ǩԼ����˰) = 0 then 0 else 
			sum(��������ǩԼ��ӦǩԼ������)/sum(��������ǩԼ����˰) end �����Ƚ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ������
	into #sumzccpqyjll
	FROM #ccpqyjll a
	where a.isccp = '׼����Ʒ'
	and year(a.��ȡʱ��) <= 2021

	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'10' num,
		'ǩԼ���' �ھ�,
		sum(������ǩԼ���)/100000000 ���ܽ��,
		sum(�±�����ǩԼ���)/100000000 �±��ܽ��,
		sum(������ǩԼ���)/100000000 ���ܽ��,
		sum(������ǩԼ���)/100000000 ���½��,
		sum(һ������ǩԼ���)/100000000 һ���Ƚ��,
		sum(��������ǩԼ���)/100000000 �����Ƚ��,
		sum(������ǩԼ���)/100000000 ������
	into #sumqy
	FROM #ccpqyjll a
	where a.isccp in ('׼����Ʒ','����Ʒ')
	and year(a.��ȡʱ��) <= 2021
	
select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		'12' num,
		'ǩԼ������' �ھ�,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���ܽ��,
		case when sum(�±�����ǩԼ����˰) = 0 then 0 else 
			sum(�±�����ǩԼ��ӦǩԼ������)/sum(�±�����ǩԼ����˰) end �±��ܽ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���ܽ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ���½��,
		case when sum(һ������ǩԼ����˰) = 0 then 0 else 
			sum(һ������ǩԼ��ӦǩԼ������)/sum(һ������ǩԼ����˰) end һ���Ƚ��,
		case when sum(��������ǩԼ����˰) = 0 then 0 else 
			sum(��������ǩԼ��ӦǩԼ������)/sum(��������ǩԼ����˰) end �����Ƚ��,
		case when sum(������ǩԼ����˰) = 0 then 0 else 
			sum(������ǩԼ��ӦǩԼ������)/sum(������ǩԼ����˰) end ������
	into #sumqyjll
	FROM #ccpqyjll a
	where a.isccp in ('׼����Ʒ','����Ʒ')
	and year(a.��ȡʱ��) <= 2021

        /* SaleBldGUID	ƽ̨��˾	��Ŀ����	Ͷ�ܴ���	��Ŀ��	�ƹ���	����	��Ŀ�����	��Ŀ���ֻ�	��ȡʱ��	��Ŀ״̬	����ʽ	��˾�ɱ�	�Ƿ�¼�����ҵ��	
���̷�ʽ	����ʽ	��Ʒ����	��Ʒ����	��Ʒ����	װ�ޱ�׼	����¥������	��Ʒ¥������	����¥��	ʵ�ʿ�����������	��������	�����������ʱ��	
���������ƻ����ʱ��	�Ƿ�����	�Ƿ����	�Ƿ��Գ�	��̬�ܿ�������	��̬�ܿ������	��̬�ܿ��ۻ�ֵ	ʣ���ܿ�������	ʣ���ܿ������	ʣ���ܿ��ۻ�ֵ	���ʣ���������	
���ʣ��������	���ʣ����ۻ�ֵ	������ǩԼ����	������ǩԼ���	������ǩԼ�������λ��������	������ǩԼ���	������ǩԼ����˰	������ǩԼ����	������ǩԼ���	
������ǩԼ�������λ��������	������ǩԼ���	������ǩԼ����˰	Ԥ�ⵥ��	����ǩԼ����	����ǩԼ����	�ۼ�ǩԼ����	Ԥ�Ʊ���ǩԼ�������λ��������	Ԥ�Ʊ���ǩԼ���	
ҵ̬��ϼ�_ҵ̬	dssƥ��ӯ���滮ҵ̬��ϼ�	Ӫҵ�ɱ�����	ӯ���滮��Ȩ��۵���	ӯ���滮Ӫ�����õ���	ӯ���滮�ۺϹ���ѵ���Э��ھ�	ӯ���滮˰�𼰸��ӵ���	������ǩԼ����˰	
������ǩԼ��ӦǩԼë����	������ǩԼ��ӦǩԼ������	������ǩԼ����˰	������ǩԼ��ӦǩԼë����	������ǩԼ��ӦǩԼ������
*/

select * from #sumccphl 
union all 
select * from #sumccprg 
union all 
select * from #sumccpqy 
union all 
select * from #sumccpqyjll 
union all 
select * from #sumzccphl 
union all 
select * from #sumzccprg 
union all 
select * from #sumzccpqy 
union all 
select * from #sumzccpqyjll
union all
select * from #sumqy
union all
select * from #sumqyjll



select '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
		case when datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 then '1'
				 when datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 then '2'
				 when a.SJzskgdate is not null then '3'
				 else '4' 
				 end num,
		case when datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 then '����Ʒ'
				 when datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 then '׼����Ʒ'
				 when a.SJzskgdate is not null then '�����ѿ�������'
				 else 'δ��������' 
				 end �ھ�,
		sum(case when year(f.��ȡʱ��) <= 2021 then a.zhz - a.ysje else 0 end)/100000000 ������Ŀ,
		sum(case when year(f.��ȡʱ��) > 2021 and year(f.��ȡʱ��)<2024 then a.zhz - a.ysje else 0 end)/100000000 ������Ŀ,
		sum(case when year(f.��ȡʱ��) >= 2024 then a.zhz - a.ysje else 0 end)/100000000 ��������Ŀ
	into #hl
	FROM  p_lddbamj a
	INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
	left join vmdm_projectFlag f on a.ProjGUID = f.projguid
	WHERE   DATEDIFF(DAY, a.QXDate, @zbdate) = -1
	group by case when datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 then '1'
				 when datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 then '2'
				 when a.SJzskgdate is not null then '3'
				 else '4' 
				 end,
				 case when datediff(dd,a.SJjgbadate,'2024-12-31') >= 0 then '����Ʒ'
				 when datediff(YEAR,a.SJjgbadate,getdate()) = 0 or datediff(YEAR,a.YJjgbadate,getdate()) = 0 then '׼����Ʒ'
				 when a.SJzskgdate is not null then '�����ѿ�������'
				 else 'δ��������' 
				 end

				 
				 select * from #hl
				 order by num

        DROP TABLE #ccpqyjll,#con,#cost,#db,#h,#hlbn,#hlbnzccp,#hlby,#hlbyzccp,#hlbz,#hlbzzccp,#hlejd,#hlejdzccp,#hlyjd,#hlyjdzccp,#hzyj,#key,#ord,#p,#room,#s_PerformanceAppraisal,#sale,#saleord,
		#sumccphl,#sumccpqy,#sumccpqyjll,#sumccprg,#sumzccphl,#sumzccpqy,#sumzccpqyjll,#sumzccprg,#t,#tmp_tax,#vrt,#xm,#ylgh,#hl,#shlbz,#shlbzzccp,#sumqy,#sumqyjll;
    END;
