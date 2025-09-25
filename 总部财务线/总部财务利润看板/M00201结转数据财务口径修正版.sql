USE [ERP25]
GO

/****** Object:  StoredProcedure [dbo].[usp_s_m00201当年签约结转数据_盈利规划单方锁定版调整]    Script Date: 2025/7/3 10:34:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

alter   PROC [dbo].[usp_s_m00201当年签约结转数据_盈利规划单方锁定版调整]
(
    @var_buGUID VARCHAR(MAX),
    @var_bgndate DATETIME,
    @var_enddate DATETIME
)
AS

/*  
  exec [usp_s_m00201当年签约结转数据_盈利规划单方锁定版调整] '6CBA0828-D863-4EA8-B594-DE3E11DDF573','2025-1-1','2025-05-31'
  1、增加26年及27年结转数据
*/
BEGIN

    --SELECT projGUID FROM ERP25.dbo.mdm_LbProject WHERE LbProject ='tgid' GROUP BY projGUID HAVING COUNT(1)>1
    --缓存项目
    SELECT p.ProjGUID,
           p.DevelopmentCompanyGUID,
           p.ProjCode
    INTO #p
    FROM erp25.dbo.mdm_Project p
    WHERE p.Level = 2
          AND 1 = 1
          AND p.developmentcompanyguid IN (
                                              SELECT Value FROM [ERP25].[dbo].[fn_Split2](@var_buGUID, ',')
                                          );
    --and p.ProjCode='0571032' 
    --and p.ProjGUID='841AD0CB-B9D9-E711-80BA-E61F13C57837'


    --缓存楼栋底表
    SELECT a.ProjGUID,
           a.SaleBldGUID,
           a.ProductType,
           a.ProductName,
           a.Standard,
           a.BusinessType,
           CONVERT(VARCHAR(MAX), p.ProjCode) + '_' + ISNULL(a.ProductType, '') + '_' + ISNULL(a.ProductName, '') + '_'
           + ISNULL(a.BusinessType, '') + '_' + ISNULL(a.Standard, '') Product,
           ISNULL(a.ProductType, '') + '_' + ISNULL(a.ProductName, '') + '_' + ISNULL(a.BusinessType, '') + '_'
           + ISNULL(a.Standard, '') Productnocode,
           SJjgbadate,
           ISNULL(JzjfSjdate, JzjfYjdate) jzjfdate
    INTO #db
    FROM erp25.dbo.p_lddbamj a
         INNER JOIN #p p ON a.ProjGUID = p.ProjGUID
    WHERE DATEDIFF(DAY, a.QXDate, GETDATE()) = 0;

    --缓存房间
    SELECT db.ProjGUID,
           r.ProjGUID fqprojguid,
           r.RoomGUID,
           r.BldGUID,
           db.ProductType,
           db.ProductName,
           db.Standard,
           db.BusinessType,
           db.Product,
           CASE
               WHEN db.ProductType = '地下室/车库' THEN
                    1
               ELSE r.BldArea
           END BldArea,
           1 Ts,
           db.jzjfdate,
           db.SJjgbadate
    INTO #room
    FROM erp25.dbo.p_room r
         INNER JOIN erp25.dbo.p_Project p ON r.ProjGUID = p.ProjGUID
         INNER JOIN erp25.dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
         INNER JOIN #db db ON db.SaleBldGUID = r.BldGUID
    WHERE r.IsVirtualRoom = 0
          AND r.Status IN ( '认购', '签约' );


    --缓存处理过期特殊业绩，①关联房间认购创建日期在取消业绩发起日期前，以特殊业绩认定日期作为业绩判断日期；②关联房间认购创建日期在取消业绩发起日期后，按正常认购日期作为业绩判断日期
    --先获取对应的特殊业绩关联的清单
    SELECT a.PerformanceAppraisalGUID,
           s.rddate,
           r.roomguid,
           r.bldarea
    INTO #tsRoomAll
    FROM S_PerformanceAppraisalBuildings a
         LEFT JOIN p_building b ON a.BldGUID = b.BldGUID
         LEFT JOIN p_room r ON b.BldGUID = r.BldGUID
         INNER JOIN S_PerformanceAppraisal s ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
		 WHERE (s.auditstatus in ('过期审核中','已过期')
			OR (s.auditstatus = '作废' and s.CancelAuditTime>='2024-01-01'))
			and s.PerformanceAppraisalGUID <> 'CDF2A700-1117-EE11-B3A3-F40270D39969'
    UNION
    SELECT r.PerformanceAppraisalGUID,
           s.rddate,
           p.roomguid,
           p.bldarea
    FROM S_PerformanceAppraisalRoom r
         LEFT JOIN p_room p ON r.roomguid = p.roomguid
         INNER JOIN S_PerformanceAppraisal s ON r.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
		 WHERE (s.auditstatus in ('过期审核中','已过期')
			OR (s.auditstatus = '作废' and s.CancelAuditTime>='2024-01-01'))
			and s.PerformanceAppraisalGUID <> 'CDF2A700-1117-EE11-B3A3-F40270D39969';



    --如果多重对接的话，取去重的数据
    SELECT roomguid,
           PerformanceAppraisalGUID,
           ROW_NUMBER() OVER (PARTITION BY roomguid ORDER BY rddate DESC) num,
           bldarea
    INTO #tsRoomAllr
    FROM #tsRoomAll;

    --关联特殊业绩认定信息
    SELECT s.*,
           a.RoomGUID
    INTO #tsRoomAllrsroom
    FROM #tsRoomAllr a
         INNER JOIN S_PerformanceAppraisal s ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
			AND (s.auditstatus IN ( '已过期', '过期审核中' ) 
					OR (s.auditstatus = '作废' and s.CancelAuditTime>='2024-01-01')
				)
    WHERE a.num = 1
          AND s.yjtype NOT IN( '物业公司车位代销','经营类(溢价款)')


    --缓存认购
    SELECT a.ProjGUID,
           a.OrderGUID,
           a.TradeGUID,
           a.OrderType,
           a.BldArea,
           1 TS,
           a.JyTotal,
           a.RoomGUID,
           a.CloseReason,
             CASE
           WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate), ISNULL(b.SetGqAuditTime, isnull(b.CancelAuditTime,'1900-01-01'))) > 0 THEN
                b.rddate
           ELSE a.QSDate
       END QSDate,
           a.Status,
           a.CloseDate
    INTO #s_order
    FROM erp25.dbo.s_Order a
         INNER JOIN #room r ON r.RoomGUID = a.RoomGUID 
		left join #tsRoomAllrsroom b on a.roomguid = b.roomguid
    WHERE (
              a.Status = '激活'
              OR a.CloseReason = '转签约'
          )
          AND DATEDIFF(DAY, @var_bgndate, a.QSDate) >= 0
          AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0;

    --缓存签约
    SELECT a.ProjGUID,
           a.ContractGUID,
           a.TradeGUID,
           a.BldArea,
           1 TS,
           a.JyTotal,
           a.RoomGUID,
           a.CloseReason,
         CASE
           WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate), ISNULL(b.SetGqAuditTime, isnull(b.CancelAuditTime,'1900-01-01'))) > 0 THEN
                b.rddate
           ELSE a.QSDate
       END QSDate,
           a.Status
    INTO #s_Contract
    FROM erp25.dbo.s_Contract a
         INNER JOIN #room r ON r.RoomGUID = a.RoomGUID 
		left join #tsRoomAllrsroom b on a.roomguid = b.roomguid
    WHERE a.Status = '激活'
          AND DATEDIFF(DAY, @var_bgndate, a.QSDate) >= 0
          AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0;

    --税率
    SELECT DISTINCT
           vt.ProjGUID,
           VATRate,
           RoomGUID
    INTO #vrt
    FROM erp25.dbo.s_VATSet vt
         INNER JOIN #room r ON vt.ProjGUID = r.fqprojguid
    WHERE VATScope = '整个项目'
          AND AuditState = 1
          AND RoomGUID NOT IN (
                                  SELECT DISTINCT
                                         vtr.RoomGUID
                                  FROM erp25.dbo.s_VATSet vt ---------  
                                       INNER JOIN erp25.dbo.s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
                                       INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
                                  WHERE VATScope = '特定房间'
                                        AND AuditState = 1
                              )
    UNION ALL
    SELECT DISTINCT
           vt.ProjGUID,
           vt.VATRate,
           vtr.RoomGUID
    FROM erp25.dbo.s_VATSet vt ---------  
         INNER JOIN erp25.dbo.s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
         INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
    WHERE VATScope = '特定房间'
          AND AuditState = 1;


    --认购
    SELECT r.ProjGUID,
           r.ProductType,
           r.ProductName,
           r.Standard,
           r.BusinessType,
           r.Product,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           r.BldArea
                      ELSE 0
                  END
              ) AS bqrgmj,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           r.Ts
                      ELSE 0
                  END
              ) AS bqrgts,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           a.JyTotal
                      ELSE 0
                  END
              ) AS BqrgJe,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           a.JyTotal / (1 + ISNULL(VATRate, 0) / 100)
                      ELSE 0
                  END
              ) AS bqrgjeNotax
    INTO #ord
    FROM #s_order a
         INNER JOIN #room r ON a.RoomGUID = r.RoomGUID
         LEFT JOIN erp25.dbo.s_Contract e ON a.TradeGUID = e.TradeGUID
                                             AND e.CloseReason NOT IN ( '变更价格', '重置认购' )
         LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
    WHERE OrderType = '认购'
          AND
          (
              a.Status = '激活'
              OR
              (
                  a.Status = '关闭'
                  AND a.CloseReason = '转签约'
                  AND e.CloseReason NOT IN ( '作废', '换房', '挞定', '折扣变更' )
              )
          )
          AND NOT EXISTS
    (
        SELECT 1
        FROM erp25.dbo.S_PerformanceAppraisalRoom sr
             INNER JOIN erp25.dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                              AND s.AuditStatus = '已审核'
                                                              AND s.YjType <> '经营类(溢价款)'
        WHERE r.RoomGUID = sr.RoomGUID
    )
          AND NOT EXISTS
    (
        SELECT 1
        FROM erp25.dbo.S_PerformanceAppraisalBuildings sr
             INNER JOIN erp25.dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                              AND s.AuditStatus = '已审核'
                                                              AND s.YjType <> '经营类(溢价款)'
        WHERE r.BldGUID = sr.BldGUID
    )
    GROUP BY r.ProjGUID,
             r.Product,
             r.ProductType,
             r.ProductName,
             r.Standard,
             r.BusinessType;

    --签约
    SELECT r.ProjGUID,
           r.ProductType,
           r.ProductName,
           r.Standard,
           r.BusinessType,
           r.Product,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           r.BldArea
                      ELSE 0
                  END
              ) AS bqrgmj,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           r.Ts
                      ELSE 0
                  END
              ) AS bqrgTs,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0))
                      ELSE 0
                  END
              ) AS BqRgJe,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)
                      ELSE 0
                  END
              ) AS bqRgjeNotax,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           r.BldArea
                      ELSE 0
                  END
              ) AS bqQymj,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                           r.Ts
                      ELSE 0
                  END
              ) AS bqQyts,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0))
                      ELSE 0
                  END
              ) AS BqQyJe,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)
                      ELSE 0
                  END
              ) AS bqQyjeNotax,
                                  --20240530新增产成品签约情况 
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, r.SJjgbadate, @var_enddate) > 0 THEN
                           r.BldArea
                      ELSE 0
                  END
              ) AS BqccpQymj,     --本期产成品签约面积
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, r.SJjgbadate, @var_enddate) > 0 THEN
                           r.Ts
                      ELSE 0
                  END
              ) AS BqccpQyts,     --本期产成品签约套数
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, r.SJjgbadate, @var_enddate) > 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0))
                      ELSE 0
                  END
              ) AS BqccpQyje,     --本期产成品签约金额
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.QSDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, r.SJjgbadate, @var_enddate) > 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)
                      ELSE 0
                  END
              ) AS BqccpQyjeNotax --本期产成品签约金额不含税
    INTO #con
    FROM #s_Contract a
         INNER JOIN #room r ON a.RoomGUID = r.RoomGUID
         LEFT JOIN erp25.dbo.s_Order d ON a.TradeGUID = d.TradeGUID
                                          AND ISNULL(d.CloseReason, '') = '转签约'
         LEFT JOIN
         (
             SELECT f.TradeGUID,
                    SUM(Amount) amount
             FROM erp25.dbo.s_Fee f
                  INNER JOIN #s_Contract c ON f.TradeGUID = c.TradeGUID
             WHERE f.ItemName LIKE '%补差%'
             GROUP BY f.TradeGUID
         ) f ON a.TradeGUID = f.TradeGUID
         LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
    WHERE a.Status = '激活'
          AND NOT EXISTS
    (
        SELECT 1
        FROM erp25.dbo.S_PerformanceAppraisalRoom sr
             INNER JOIN erp25.dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                              AND s.AuditStatus = '已审核'
                                                              AND s.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' )
        WHERE r.RoomGUID = sr.RoomGUID
    )
          AND NOT EXISTS
    (
        SELECT 1
        FROM erp25.dbo.S_PerformanceAppraisalBuildings sr
             INNER JOIN erp25.dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                              AND s.AuditStatus = '已审核'
                                                              AND s.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' )
        WHERE r.BldGUID = sr.BldGUID
    )
    GROUP BY r.ProjGUID,
             r.Product,
             r.ProductType,
             r.ProductName,
             r.Standard,
             r.BusinessType;


    --设置税率表
    SELECT CONVERT(DATE, '1999-01-01') AS bgnDate,
           CONVERT(DATE, '2016-03-31') AS endDate,
           0 AS rate
    INTO #tmp_tax UNION ALL
    SELECT CONVERT(DATE, '2016-04-01') AS bgnDate,
           CONVERT(DATE, '2018-04-30') AS endDate,
           0.11 AS rate
    UNION ALL
    SELECT CONVERT(DATE, '2018-05-01') AS bgnDate,
           CONVERT(DATE, '2019-03-31') AS endDate,
           0.1 AS rate
    UNION ALL
    SELECT CONVERT(DATE, '2019-04-01') AS bgnDate,
           CONVERT(DATE, '2099-01-01') AS endDate,
           0.09 AS rate;

    --合作业绩
    SELECT c.ProjGUID,
           CONVERT(DATE, b.DateYear + '-' + b.DateMonth + '-27') AS [BizDate],
           b.*
    INTO #hzyj
    FROM erp25.dbo.s_YJRLProducteDetail b
         INNER JOIN erp25.dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
         INNER JOIN #p mp ON c.ProjGUID = mp.ProjGUID
    WHERE b.Shenhe = '审核';

    SELECT a.ProjGUID,
           b.ProductType,
           b.ProductName,
           b.zxbz standard,
           b.RoomType BusinessType,
           f.ProjCode + '_' + b.ProductType + '_' + b.ProductName + '_' + b.RoomType + '_' + b.zxbz Product,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0 THEN
                           CASE
                               WHEN b.ProductType = '地下室/车库' THEN
                                    b.Taoshu
                               ELSE b.Area
                           END
                      ELSE 0
                  END
              ) Hzmj,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0 THEN
                           b.Taoshu
                      ELSE 0
                  END
              ) HzTs,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0 THEN
                           b.Amount
                      ELSE 0
                  END
              ) * 10000 hzje,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0 THEN
                           b.Amount
                      ELSE 0
                  END
              ) / (1 + tax.rate) * 10000 hzjeNotax,
              CONVERT(decimal(18,2), 0)  BqccpQymj,
           CONVERT(decimal(18,2), 0) BqccpQyts,
           CONVERT(decimal(18,2), 0)  BqccpQyje,
           CONVERT(decimal(18,2), 0)  BqccpQyjeNotax
    INTO #h
    FROM #hzyj a
         LEFT JOIN erp25.dbo.s_YJRLProducteDescript b ON a.ProducteDetailGUID = b.ProducteDetailGUID
         --LEFT JOIN s_YJRLBuildingDescript bb ON a.ProducteDetailGUID = bb.ProducteDetailGUID
         LEFT JOIN #p f ON a.ProjGUID = f.ProjGUID
         LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.BizDate, tax.bgnDate) <= 0
                                   AND DATEDIFF(DAY, a.BizDate, tax.endDate) >= 0
    -- LEFT JOIN #db db ON bb.bldGUID = db.SaleBldGUID
    GROUP BY a.ProjGUID,
             tax.rate,
             f.ProjCode + '_' + b.ProductType + '_' + b.ProductName + '_' + b.RoomType + '_' + b.zxbz,
             b.ProductType,
             b.ProductName,
             b.zxbz,
             b.RoomType;

    ---0530合作业绩加产成品

    SELECT a.ProjGUID,
           db.ProductType,
           db.ProductName,
           db.standard standard,
           db.BusinessType BusinessType,
           f.ProjCode + '_' + db.ProductType + '_' + db.ProductName + '_' + db.BusinessType + '_' + db.standard Product,

           --20240530新增产成品签约情况
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, db.SJjgbadate, @var_enddate) > 0 THEN
                           CASE
                               WHEN db.ProductType = '地下室/车库' THEN
                                    bb.Taoshu
                               ELSE bb.Area
                           END
                      ELSE 0
                  END
              ) BqccpQymj,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, db.SJjgbadate, @var_enddate) > 0 THEN
                           bb.Taoshu
                      ELSE 0
                  END
              ) BqccpQyts,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, db.SJjgbadate, @var_enddate) > 0 THEN
                           bb.Amount
                      ELSE 0
                  END
              ) * 10000 BqccpQyje,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.BizDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.BizDate, @var_enddate) >= 0
                           AND DATEDIFF(yy, db.SJjgbadate, @var_enddate) > 0 THEN
                           bb.Amount
                      ELSE 0
                  END
              ) / (1 + tax.rate) * 10000 BqccpQyjeNotax
    INTO #hh
    FROM #hzyj a
         LEFT JOIN erp25.dbo.s_YJRLBuildingDescript bb ON a.ProducteDetailGUID = bb.ProducteDetailGUID
         LEFT JOIN #p f ON a.ProjGUID = f.ProjGUID
         LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.BizDate, tax.bgnDate) <= 0
                                   AND DATEDIFF(DAY, a.BizDate, tax.endDate) >= 0
         LEFT JOIN #db db ON bb.bldGUID = db.SaleBldGUID
    GROUP BY a.ProjGUID,
             tax.rate,
             f.ProjCode + '_' + db.ProductType + '_' + db.ProductName + '_' + db.BusinessType + '_' + db.standard,
             db.ProductType,
             db.ProductName,
             db.standard,
             db.BusinessType;


    UPDATE a
    SET a.BqccpQymj = CONVERT(decimal(18,2), b.BqccpQymj)  ,
        a.BqccpQyts = CONVERT(decimal(18,2), b.BqccpQyts)      ,
        a.BqccpQyje =CONVERT(decimal(18,2), b.BqccpQyje)   ,
        a.BqccpQyjeNotax =  CONVERT(decimal(18,2), b.BqccpQyjeNotax)   
    FROM #h a
         INNER JOIN #hh b ON a.projguid = b.projguid
                             AND a.Product = b.Product;

    --特殊业绩
    SELECT a.*,
           a.TotalAmount / (1 + tax.rate) TotalAmountnotax,
           tax.rate
    INTO #s_PerformanceAppraisal
    FROM erp25.dbo.S_PerformanceAppraisal a
         INNER JOIN #p mp ON a.ManagementProjectGUID = mp.ProjGUID
         LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.RdDate, tax.bgnDate) <= 0
                                   AND DATEDIFF(DAY, a.RdDate, tax.endDate) >= 0;


    SELECT a.ManagementProjectGUID Projguid,
           db.ProductType,
           db.ProductName,
           db.Standard,
           db.BusinessType,
           db.Product,
           SUM(   CASE
                      WHEN (a.YjType <> '经营类(溢价款)')
                           AND DATEDIFF(DAY, a.RdDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.RdDate, @var_enddate) >= 0 THEN
                           CASE
                               WHEN db.ProductType = '地下室/车库' THEN
                                    b.AffirmationNumber
                               ELSE b.areatotal
                           END
                      ELSE 0
                  END
              ) TsMJ,
           SUM(   CASE
                      WHEN (a.YjType <> '经营类(溢价款)')
                           AND DATEDIFF(DAY, a.RdDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.RdDate, @var_enddate) >= 0 THEN
                           b.AffirmationNumber
                      ELSE 0
                  END
              ) TsTs,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.RdDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.RdDate, @var_enddate) >= 0 THEN
                           b.totalamount
                      ELSE 0
                  END
              ) * 10000 TsJE,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.RdDate, @var_bgndate) <= 0
                           AND DATEDIFF(DAY, a.RdDate, @var_enddate) >= 0 THEN
                           b.totalamount / (1 + a.rate)
                      ELSE 0
                  END
              ) * 10000 TsJEnotax
    INTO #t
    FROM #s_PerformanceAppraisal a
         LEFT JOIN
         (
             SELECT PerformanceAppraisalGUID,
                    BldGUID,
                    AffirmationNumber,
                    IdentifiedArea areatotal,
                    AmountDetermined totalamount
             FROM erp25.dbo.S_PerformanceAppraisalBuildings
             UNION ALL
             SELECT PerformanceAppraisalGUID,
                    r.ProductBldGUID BldGUID,
                    SUM(1) AffirmationNumber,
                    SUM(a.IdentifiedArea),
                    SUM(a.AmountDetermined)
             FROM erp25.dbo.S_PerformanceAppraisalRoom a
                  LEFT JOIN MyCost_Erp352.dbo.md_Room r ON a.RoomGUID = r.RoomGUID
             GROUP BY PerformanceAppraisalGUID,
                      r.ProductBldGUID
         ) b ON a.PerformanceAppraisalGUID = b.PerformanceAppraisalGUID
         LEFT JOIN #db db ON b.BldGUID = db.SaleBldGUID
    WHERE 1 = 1
          AND a.AuditStatus = '已审核'
          AND a.YjType IN (
                              SELECT TsyjTypeName
                              FROM erp25.dbo.s_TsyjType
                              WHERE IsRelatedBuildingsRoom = 1
                          )
          AND a.YjType IN ( '整体销售', '其他销售', '经营类(溢价款)', '回购', '包销', '代建类' )
    GROUP BY a.ManagementProjectGUID,
             db.Product,
             db.ProductType,
             db.ProductName,
             db.Standard,
             db.BusinessType;

    --取手工维护的匹配关系
    SELECT 项目guid,
           T.基础数据主键,
           T.盈利规划系统自动匹对主键,
           CASE
               WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN
                    T.盈利规划系统自动匹对主键
               ELSE CASE
                        WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                             T.盈利规划主键
                        ELSE T.基础数据主键
                    END
           END 盈利规划主键,
           MAX(T.[营业成本单方(元/平方米)]) AS 营业成本单方,
           MAX(T.[营销费用单方(元/平方米)]) AS 营销费用单方,
           MAX(T.[综合管理费单方(元/平方米)]) AS 综合管理费单方,
           MAX(T.[股权溢价单方(元/平方米)]) AS 股权溢价单方,
           MAX(T.[税金及附加单方(元/平方米)]) AS 税金及附加单方,
           MAX(T.[除地价外直投单方(元/平方米)]) AS 除地价外直投单方,
           MAX(T.[土地款单方(元/平方米)]) AS 土地款单方,
           MAX(T.[资本化利息单方(元/平方米)]) AS 资本化利息单方,
           MAX(T.[开发间接费单方(元/平方米)]) AS 开发间接费单方
    INTO #key
    FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 T
         INNER JOIN
         (
             SELECT ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM,
                    FillHistoryGUID
             FROM dss.dbo.nmap_F_FillHistory a
             WHERE EXISTS
             (
                 SELECT FillHistoryGUID,
                        SUM(   CASE
                                   WHEN 项目guid IS NULL
                                        OR 项目guid = '' THEN
                                        0
                                   ELSE 1
                               END
                           ) AS num
                 FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 b
                 WHERE a.FillHistoryGUID = b.FillHistoryGUID
                 GROUP BY FillHistoryGUID
                 HAVING SUM(   CASE
                                   WHEN 项目guid IS NULL THEN
                                        0
                                   ELSE 1
                               END
                           ) > 0
             )
         ) V ON T.FillHistoryGUID = V.FillHistoryGUID
                AND V.NUM = 1
    WHERE ISNULL(T.项目guid, '') <> ''
    GROUP BY 项目guid,
             T.基础数据主键,
             T.盈利规划系统自动匹对主键,
             CASE
                 WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN
                      T.盈利规划系统自动匹对主键
                 ELSE CASE
                          WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                               T.盈利规划主键
                          ELSE T.基础数据主键
                      END
             END;

    SELECT db.ProjGUID,
           db.Product MyProduct,
           db.ProductType,
           db.ProductName,
           db.Standard,
           db.BusinessType,
           ISNULL(dss.盈利规划主键, db.Product) Product,
           SUM(ISNULL(s.bqrgmj, 0)) bqrgmj,
           SUM(ISNULL(s.bqrgts, 0)) bqrgTS,
           SUM(ISNULL(s.BqrgJe, 0)) BqRgJe,
           SUM(ISNULL(s.bqrgjeNotax, 0)) bqRgjeNotax,
           SUM(ISNULL(s.bqqymj, 0)) bqQymj,
           SUM(ISNULL(s.bqqyts, 0)) bqQyTS,
           SUM(ISNULL(s.bqqyje, 0)) BqQyJe,
           SUM(ISNULL(s.bqqyjeNotax, 0)) bqQyjeNotax,
           --20240530新增产成品签约情况
           SUM(ISNULL(s.BqccpQymj, 0)) BqccpQymj,
           SUM(ISNULL(s.BqccpQyts, 0)) BqccpQyts,
           SUM(ISNULL(s.BqccpQyje, 0)) BqccpQyje,
           SUM(ISNULL(s.bqccpQyjeNotax, 0)) bqccpQyjeNotax
    INTO #sale
    FROM
    (
        SELECT DISTINCT
               db.ProjGUID,
               db.Product,
               db.ProductType,
               db.ProductName,
               db.Standard,
               db.BusinessType
        FROM #db db
    ) db
    LEFT JOIN
    (
        SELECT a.ProjGUID,
               a.Product,
               a.ProductType,
               a.ProductName,
               a.Standard,
               a.BusinessType,
               a.bqrgmj,
               a.bqrgts,
               a.BqrgJe,
               a.bqrgjeNotax,
               0 bqqymj,
               0 bqqyts,
               0 bqqyje,
               0 bqqyjeNotax,
               --20240530新增产成品签约情况
               0 BqccpQymj,
               0 BqccpQyts,
               0 BqccpQyje,
               0 bqccpQyjeNotax
        FROM #ord a
        UNION ALL
        SELECT a.ProjGUID,
               a.Product,
               a.ProductType,
               a.ProductName,
               a.Standard,
               a.BusinessType,
               a.bqrgmj,
               a.bqrgTs,
               a.BqRgJe,
               a.bqRgjeNotax,
               a.bqQymj,
               a.bqQyts,
               a.BqQyJe,
               a.bqQyjeNotax,
               --20240530新增产成品签约情况
               a.BqccpQymj,
               a.BqccpQyts,
               a.BqccpQyje,
               a.BqccpQyjeNotax
        FROM #con a
        UNION ALL
        SELECT a.ProjGUID,
               a.Product,
               a.ProductType,
               a.ProductName,
               a.standard,
               a.BusinessType,
               a.Hzmj,
               a.HzTs,
               a.hzje,
               a.hzjeNotax,
               a.Hzmj,
               a.HzTs,
               a.hzje,
               a.hzjeNotax,
               --20240530新增产成品签约情况
               a.BqccpQymj,
               a.BqccpQyts,
               a.BqccpQyje,
               a.BqccpQyjeNotax
        FROM #h a
        UNION ALL
        SELECT a.Projguid,
               a.Product,
               a.ProductType,
               a.ProductName,
               a.Standard,
               a.BusinessType,
               a.TsMJ,
               a.TsTs,
               a.TsJE,
               a.TsJEnotax,
               a.TsMJ,
               a.TsTs,
               a.TsJE,
               a.TsJEnotax,
               --20240530新增产成品签约情况
               0 BqccpQymj,
               0 BqccpQyts,
               0 BqccpQyje,
               0 bqccpQyjeNotax
        FROM #t a
    ) s ON db.ProjGUID = s.ProjGUID
           AND db.Product = s.Product
    LEFT JOIN
    (SELECT DISTINCT k.项目guid, k.基础数据主键, k.盈利规划主键 FROM #key k) dss ON dss.项目guid = db.ProjGUID
                                                                      AND dss.基础数据主键 = db.Product --业态匹配
    GROUP BY db.ProjGUID,
             db.Product,
             db.ProductType,
             db.ProductName,
             db.Standard,
             db.BusinessType,
             ISNULL(dss.盈利规划主键, db.Product);


    --盈利规划
    -- 营业成本单方 	 其中：地价单方 	 其中：除地价外直投单方 	 其中：开发间接费单方 	 其中：资本化利息单方 	 
    --股权溢价单方 	 营销费用单方 	 综合管理费用单方 	 税金及附加单方 

    --OrgGuid,平台公司,项目guid,项目名称,项目代码,投管代码,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,匹配主键,
    --总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,盈利规划营业成本单方,税金及附加单方,股权溢价单方,
    --管理费用单方,营销费用单方,资本化利息单方,开发间接费单方,总投资不含税单方 ,盈利规划车位数
    SELECT DISTINCT
           k.[项目guid], -- 避免重复
           ISNULL(k.盈利规划主键, ylgh.匹配主键) 业态组合键,
           ISNULL(ylgh.总可售面积, 0) AS 盈利规划总可售面积,
           CASE
               WHEN ISNULL(k.营业成本单方, 0) = 0 THEN
                    ISNULL(ylgh.盈利规划营业成本单方, 0)
               ELSE ISNULL(k.营业成本单方, 0)
           END AS 盈利规划营业成本单方,
           CASE
               WHEN ISNULL(k.土地款单方, 0) = 0 THEN
                    ISNULL(ylgh.土地款_单方, 0)
               ELSE k.土地款单方
           END 土地款_单方,
           CASE
               WHEN ISNULL(k.除地价外直投单方, 0) = 0 THEN
                    ISNULL(ylgh.除地外直投_单方, 0)
               ELSE k.除地价外直投单方
           END AS 除地外直投_单方,
           CASE
               WHEN ISNULL(k.开发间接费单方, 0) = 0 THEN
                    ISNULL(ylgh.开发间接费单方, 0)
               ELSE k.开发间接费单方
           END AS 开发间接费单方,
           CASE
               WHEN ISNULL(k.资本化利息单方, 0) = 0 THEN
                    ISNULL(ylgh.资本化利息单方, 0)
               ELSE k.资本化利息单方
           END AS 资本化利息单方,
           CASE
               WHEN ISNULL(k.股权溢价单方, 0) = 0 THEN
                    ISNULL(ylgh.股权溢价单方, 0)
               ELSE k.股权溢价单方
           END AS 盈利规划股权溢价单方,
           CASE
               WHEN ISNULL(k.营销费用单方, 0) = 0 THEN
                    ISNULL(ylgh.营销费用单方, 0)
               ELSE k.营销费用单方
           END AS 盈利规划营销费用单方,
           CASE
               WHEN ISNULL(k.综合管理费单方, 0) = 0 THEN
                    ISNULL(ylgh.管理费用单方, 0)
               ELSE k.综合管理费单方
           END AS 盈利规划综合管理费单方协议口径,
           CASE
               WHEN ISNULL(k.税金及附加单方, 0) = 0 THEN
                    ISNULL(ylgh.税金及附加单方, 0)
               ELSE k.税金及附加单方
           END AS 盈利规划税金及附加单方
    INTO #ylgh
    FROM #key k
         LEFT JOIN dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh ON ylgh.匹配主键 = k.盈利规划主键
                                                          AND ylgh.[项目guid] = k.项目guid
         INNER JOIN #p p ON k.项目guid = p.ProjGUID;



    --select * from #ylgh

  --------------------按照盈利规划锁定版本进行单方等比例缩小放大逻辑 begin--------------------------------  
    -- select 
    --     a.项目guid,
    --     a.业态组合键,
    --     case when isnull(b.除地外直投_单方,0) < 1 then  0 else  a.除地外直投_单方 / b.除地外直投_单方  end as  除地价外直投变动率,
    --     case when isnull(b.管理费用单方,0) <1 then  0 else  a.盈利规划综合管理费单方协议口径 / b.管理费用单方  end as  管理费用变动率,
    --     case when isnull(b.营销费用单方,0) <1 then  0 else  a.盈利规划营销费用单方 / b.营销费用单方  end as  营销费用变动率,
    --     case when isnull(b.股权溢价单方,0) <1 then  0 else  a.盈利规划股权溢价单方 / b.股权溢价单方  end as  股权溢价单方变动率
    -- into #bdl
    -- from #ylgh a
    -- inner join dss.dbo.s_F066项目毛利率销售底表_盈利规划单方锁定版 b on a.项目guid = b.项目guid and a.业态组合键 = b.匹配主键



    -- UPDATE p 
    -- SET p.盈利规划营业成本单方 = p.除地外直投_单方 * (1 + 除地价外直投变动率) + 
    --                                 p.土地款_单方 + 
    --                                 p.开发间接费单方 + 
    --                                 p.资本化利息单方, --如果是在指定项目分期的范围内，营业成本 = 除地价外直投+土地款+开发间接费+资本化利息
    --     p.除地外直投_单方 = p.除地外直投_单方 * (1 + 除地价外直投变动率), --增加指定项目的除地价外直投单方变动率
    --     p.盈利规划综合管理费单方协议口径 = p.盈利规划综合管理费单方协议口径 * (1 + 管理费用变动率), --增加指定项目的管理费用单方变动率
    --     p.盈利规划营销费用单方 = p.盈利规划营销费用单方 * (1 + 营销费用变动率), --增加指定项目的营销费用单方变动率
    --     p.盈利规划股权溢价单方 = p.盈利规划股权溢价单方 * (1 + 股权溢价单方变动率) --增加指定项目的股权溢价单方变动率
    -- FROM #ylgh p
    -- INNER JOIN #bdl b 
    --     ON b.项目guid = p.项目guid and b.业态组合键 = p.业态组合键

  --------------------按照盈利规划锁定版本进行单方等比例缩小放大逻辑 end--------------------------------  


    --计算项目成本
    SELECT a.ProjGUID,
           a.MyProduct,
           a.Product,
           a.ProductType,
           a.ProductName,
           a.Standard,
           a.BusinessType,
           y.盈利规划营业成本单方,
           y.土地款_单方,
           y.除地外直投_单方,
           y.开发间接费单方,
           y.资本化利息单方,
           y.盈利规划股权溢价单方,
           y.盈利规划营销费用单方,
           y.盈利规划综合管理费单方协议口径,
           y.盈利规划税金及附加单方,
           SUM(ISNULL(a.bqrgmj, 0)) bqrgmj,
           SUM(ISNULL(a.bqrgTS, 0)) bqrgTS,
           SUM(ISNULL(a.BqRgJe, 0)) BqRgJe,
           SUM(ISNULL(a.bqRgjeNotax, 0)) bqRgjeNotax,
           SUM(ISNULL(a.bqQymj, 0)) bqQymj,
           SUM(ISNULL(a.bqQyTS, 0)) bqQyTS,
           SUM(ISNULL(a.BqQyJe, 0)) BqQyJe,
           SUM(ISNULL(a.bqQyjeNotax, 0)) bqQyjeNotax,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.bqrgmj, 0)) 盈利规划营业成本认购,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.bqrgmj, 0)) 盈利规划股权溢价认购,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.bqrgmj, 0)) 盈利规划营销费用认购,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.bqrgmj, 0)) 盈利规划综合管理费认购,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.bqrgmj, 0)) 盈利规划税金及附加认购,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.bqQymj, 0)) 盈利规划营业成本签约,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.bqQymj, 0)) 盈利规划股权溢价签约,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.bqQymj, 0)) 盈利规划营销费用签约,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.bqQymj, 0)) 盈利规划综合管理费签约,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.bqQymj, 0)) 盈利规划税金及附加签约,
           --20240530新增产成品签约情况
           SUM(ISNULL(a.BqccpQymj, 0)) BqccpQymj,
           SUM(ISNULL(a.BqccpQyts, 0)) BqccpQyts,
           SUM(ISNULL(a.BqccpQyje, 0)) BqccpQyje,
           SUM(ISNULL(a.bqccpQyjeNotax, 0)) bqccpQyjeNotax,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.BqccpQymj, 0)) 盈利规划营业成本产成品签约,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.BqccpQymj, 0)) 盈利规划股权溢价产成品签约,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.BqccpQymj, 0)) 盈利规划营销费用产成品签约,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.BqccpQymj, 0)) 盈利规划综合管理费产成品签约,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.BqccpQymj, 0)) 盈利规划税金及附加产成品签约
    INTO #cost
    FROM #sale a
         LEFT JOIN #ylgh y ON a.ProjGUID = y.[项目guid]
                              AND a.Product = y.业态组合键
    GROUP BY a.ProjGUID,
             a.Product,
             a.MyProduct,
             a.ProductType,
             a.ProductName,
             a.Standard,
             a.BusinessType,
             y.盈利规划营业成本单方,
             y.土地款_单方,
             y.除地外直投_单方,
             y.开发间接费单方,
             y.资本化利息单方,
             y.盈利规划股权溢价单方,
             y.盈利规划营销费用单方,
             y.盈利规划综合管理费单方协议口径,
             y.盈利规划税金及附加单方;

    SELECT c.ProjGUID,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                          ) / 100000000
                      )
              ) 项目税前利润认购,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                          ) / 100000000
                      )
              ) 项目税前利润签约,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本产成品签约, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用产成品签约, 0) - ISNULL(c.盈利规划综合管理费产成品签约, 0) - ISNULL(c.盈利规划税金及附加产成品签约, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润产成品签约
    INTO #xm
    FROM #cost c
    GROUP BY c.ProjGUID;

    -- 项目代码（投管） 	 明源代码 	 子公司  认购面积 	 认购金额 	 认购金额（不含税) 	 营业成本 	 股权溢价 	 毛利 	 毛利率 	 营销费用 	 管理费用 	 税金及附加 	 税前利润 	 所得税 	 净利润 	 销售净利率 

    SELECT -- NEWID() versionguid,
        p.DevelopmentCompanyGUID OrgGuid,
        p.ProjGUID,
        f.平台公司,
        f.项目名,
        f.推广名,
        f.项目代码,
        f.投管代码,
        f.盈利规划上线方式,
        c.ProductType 产品类型,
        c.ProductName 产品名称,
        c.Standard 装修标准,
        c.BusinessType 商品类型,
        c.MyProduct 明源匹配主键,
        c.Product 业态组合键,
        ISNULL(c.ProductType, '') + '_' + ISNULL(c.ProductName, '') + '_' + ISNULL(c.BusinessType, '') + '_'
        + ISNULL(c.Standard, '') Productnocode,
        CONVERT(   DECIMAL(36, 8),
                   CASE
                       WHEN c.Product LIKE '%地下室/车库%' THEN
                            c.bqrgmj
                       ELSE c.bqrgmj / 10000
                   END
               ) 当期认购面积,
        CONVERT(DECIMAL(36, 9), c.BqRgJe) / 100000000.0 当期认购金额,
        CONVERT(DECIMAL(36, 9), c.bqRgjeNotax) / 100000000.0 当期认购金额不含税,
        CONVERT(   DECIMAL(36, 8),
                   CASE
                       WHEN c.Product LIKE '%地下室/车库%' THEN
                            c.bqQymj
                       ELSE c.bqQymj / 10000
                   END
               ) 当期签约面积,
        CONVERT(DECIMAL(36, 9), c.BqQyJe) / 100000000.0 当期签约金额,
        CONVERT(DECIMAL(36, 9), c.bqQyjeNotax) / 100000000.0 当期签约金额不含税,
        c.盈利规划营业成本单方,
        c.土地款_单方,
        c.除地外直投_单方,
        c.开发间接费单方,
        c.资本化利息单方,
        c.盈利规划股权溢价单方,
        c.盈利规划营销费用单方,
        c.盈利规划综合管理费单方协议口径,
        c.盈利规划税金及附加单方,
        CONVERT(DECIMAL(36, 8), c.盈利规划营业成本认购 / 100000000) 盈利规划营业成本认购,
        CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价认购 / 100000000) 盈利规划股权溢价认购,
        CONVERT(
                   DECIMAL(36, 8),
                   (ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0) - ISNULL(c.盈利规划股权溢价认购, 0)) / 100000000
               ) 毛利认购,
        CONVERT(
                   DECIMAL(36, 8),
                   CASE
                       WHEN ISNULL(c.bqRgjeNotax, 0) <> 0 THEN
                   (ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0) - ISNULL(c.盈利规划股权溢价认购, 0))
                   / ISNULL(c.bqRgjeNotax, 0)
                   END
               ) 毛利率认购,
        CONVERT(DECIMAL(36, 8), c.盈利规划营销费用认购 / 100000000) 盈利规划营销费用认购,
        CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费认购 / 100000000) 盈利规划综合管理费认购,
        CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加认购 / 100000000) 盈利规划税金及附加认购,
        CONVERT(
                   DECIMAL(36, 8),
                   ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/) - ISNULL(c.盈利规划营销费用认购, 0)
                    - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                   ) / 100000000
               ) 税前利润认购,
        CASE
            WHEN x.项目税前利润认购 > 0 THEN
                 CONVERT(
                            DECIMAL(36, 8),
                            ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/)
                             - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                            )
                            / 100000000 * 0.25
                        )
            ELSE 0.0
        END 所得税认购,
        CONVERT(
                   DECIMAL(36, 8),
                   ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0) - ISNULL(c.盈利规划股权溢价认购, 0))
                    - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - c.盈利规划税金及附加认购
                   ) / 100000000
               )
        - CASE
              WHEN x.项目税前利润认购 > 0 THEN
                   CONVERT(
                              DECIMAL(36, 8),
                              ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/)
                               - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                              )
                              / 100000000 * 0.25
                          )
              ELSE 0.0
          END 净利润认购,
        CONVERT(
                   DECIMAL(36, 8),
                   CASE
                       WHEN ISNULL(c.bqRgjeNotax, 0) <> 0 THEN
                   (CONVERT(
                               DECIMAL(36, 8),
                               ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0) - ISNULL(c.盈利规划股权溢价认购, 0))
                                - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                               )
                           )
                    - CASE
                          WHEN x.项目税前利润认购 > 0 THEN
                               CONVERT(
                                          DECIMAL(36, 8),
                                          ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/)
                                           - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0)
                                           - ISNULL(c.盈利规划税金及附加认购, 0)
                                          ) * 0.25
                                      )
                          ELSE 0.0
                      END
                   ) / ISNULL(c.bqRgjeNotax, 0)
                   END
               ) 销售净利率认购,
        CONVERT(DECIMAL(36, 8), c.盈利规划营业成本签约 / 100000000) 盈利规划营业成本签约,
        CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价签约 / 100000000) 盈利规划股权溢价签约,
        CONVERT(
                   DECIMAL(36, 8),
                   (ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0) - ISNULL(c.盈利规划股权溢价签约, 0)) / 100000000
               ) 毛利签约,
        CONVERT(
                   DECIMAL(36, 8),
                   CASE
                       WHEN ISNULL(c.bqQyjeNotax, 0) <> 0 THEN
                   (ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0) - ISNULL(c.盈利规划股权溢价签约, 0))
                   / ISNULL(c.bqQyjeNotax, 0)
                   END
               ) 毛利率签约,
        CONVERT(DECIMAL(36, 8), c.盈利规划营销费用签约 / 100000000) 盈利规划营销费用签约,
        CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费签约 / 100000000) 盈利规划综合管理费签约,
        CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加签约 / 100000000) 盈利规划税金及附加签约,
        CONVERT(
                   DECIMAL(36, 8),
                   ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价签约 */) - ISNULL(c.盈利规划营销费用签约, 0)
                    - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                   ) / 100000000
               ) 税前利润签约,
        CASE
            WHEN x.项目税前利润签约 > 0 THEN
                 CONVERT(
                            DECIMAL(36, 8),
                            ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价签约 */)
                             - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                            )
                            / 100000000 * 0.25
                        )
            ELSE 0.0
        END 所得税签约,
        CONVERT(
                   DECIMAL(36, 8),
                   ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0) - ISNULL(c.盈利规划股权溢价签约, 0))
                    - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                   ) / 100000000
               )
        - CASE
              WHEN x.项目税前利润签约 > 0 THEN
                   CONVERT(
                              DECIMAL(36, 8),
                              ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价签约 */)
                               - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                              )
                              / 100000000 * 0.25
                          )
              ELSE 0.0
          END 净利润签约,
        CONVERT(
                   DECIMAL(36, 8),
                   CASE
                       WHEN ISNULL(c.bqQyjeNotax, 0) <> 0 THEN
                   (CONVERT(
                               DECIMAL(36, 8),
                               ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0) - ISNULL(c.盈利规划股权溢价签约, 0))
                                - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                               )
                           )
                    - CASE
                          WHEN x.项目税前利润签约 > 0 THEN
                               CONVERT(
                                          DECIMAL(36, 8),
                                          ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价签约 */)
                                           - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0)
                                           - ISNULL(c.盈利规划税金及附加签约, 0)
                                          ) * 0.25
                                      )
                          ELSE 0.0
                      END
                   ) / ISNULL(c.bqQyjeNotax, 0)
                   END
               ) 销售净利率签约,
        c.bqrgTS 当期认购套数,
        c.bqQyTS 当期签约套数,
        --20240530新增产成品签约情况
        CONVERT(DECIMAL(36, 9), c.BqccpQyje) / 100000000.0 当期产成品签约金额,
        CONVERT(DECIMAL(36, 9), c.bqccpQyjeNotax) / 100000000.0 当期产成品签约金额不含税,
        CONVERT(
                   DECIMAL(36, 8),
                   ((ISNULL(c.bqccpQyjeNotax, 0) - ISNULL(c.盈利规划营业成本产成品签约, 0) - ISNULL(c.盈利规划股权溢价产成品签约, 0))
                    - ISNULL(c.盈利规划营销费用产成品签约, 0) - ISNULL(c.盈利规划综合管理费产成品签约, 0) - ISNULL(c.盈利规划税金及附加产成品签约, 0)
                   )
                   / 100000000
               )
        - CASE
              WHEN x.项目税前利润产成品签约 > 0 THEN
                   CONVERT(
                              DECIMAL(36, 8),
                              ((ISNULL(c.bqccpQyjeNotax, 0) - ISNULL(c.盈利规划营业成本产成品签约, 0)/*- c.盈利规划股权溢价签约 */)
                               - ISNULL(c.盈利规划营销费用产成品签约, 0) - ISNULL(c.盈利规划综合管理费产成品签约, 0) - ISNULL(c.盈利规划税金及附加产成品签约, 0)
                              )
                              / 100000000 * 0.25
                          )
              ELSE 0.0
          END 产成品净利润签约,
        CONVERT(
                   DECIMAL(36, 8),
                   CASE
                       WHEN ISNULL(c.bqccpQyjeNotax, 0) <> 0 THEN
                   (CONVERT(
                               DECIMAL(36, 8),
                               ((ISNULL(c.bqccpQyjeNotax, 0) - ISNULL(c.盈利规划营业成本产成品签约, 0) - ISNULL(c.盈利规划股权溢价产成品签约, 0))
                                - ISNULL(c.盈利规划营销费用产成品签约, 0) - ISNULL(c.盈利规划综合管理费产成品签约, 0)
                                - ISNULL(c.盈利规划税金及附加产成品签约, 0)
                               )
                           )
                    - CASE
                          WHEN x.项目税前利润签约 > 0 THEN
                               CONVERT(
                                          DECIMAL(36, 8),
                                          ((ISNULL(c.bqccpQyjeNotax, 0) - ISNULL(c.盈利规划营业成本产成品签约, 0)/*- c.盈利规划股权溢价签约 */)
                                           - ISNULL(c.盈利规划营销费用产成品签约, 0) - ISNULL(c.盈利规划综合管理费产成品签约, 0)
                                           - ISNULL(c.盈利规划税金及附加产成品签约, 0)
                                          ) * 0.25
                                      )
                          ELSE 0.0
                      END
                   ) / ISNULL(c.bqccpQyjeNotax, 0)
                   END
               ) 产成品销售净利率签约
    INTO #m002
    FROM #p p
         LEFT JOIN erp25.dbo.vmdm_projectFlag f ON p.ProjGUID = f.ProjGUID
         INNER JOIN #cost c ON c.ProjGUID = p.ProjGUID
         LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_proj_expense tax ON tax.ProjGUID = p.ProjGUID
                                                                                         AND tax.IsBase = 1
         LEFT JOIN #xm x ON x.ProjGUID = p.ProjGUID
    ORDER BY f.平台公司,
             f.项目代码;



    --————————————————————————————————////////////////取结转数据开始//////////////////////////———————————————————————————————————————
    SELECT a.ProjGUID,
           a.ContractGUID,
           a.TradeGUID,
           a.BldArea,
           1 TS,
           a.JyTotal,
           a.RoomGUID,
           a.CloseReason,
           a.QSDate,
           a.Status,
           a.jfdate,
           sf.lastDate,
           t.jzdate,
           CASE
               WHEN t.jzdate IS NOT NULL THEN
                    t.jzdate
               WHEN sf.lastDate > r.jzjfdate THEN
                    sf.lastDate
               ELSE r.jzjfdate
           END gsdate
    INTO #con1
    FROM erp25.dbo.s_Contract a
         INNER JOIN #room r ON r.RoomGUID = a.RoomGUID
         LEFT JOIN erp25.dbo.s_trade t ON a.tradeguid = t.tradeguid
         LEFT JOIN
         (
             SELECT TradeGUID,
                    MAX(Sequence) AS Sequence
             FROM erp25.dbo.s_fee
             WHERE ItemType IN ( '贷款类房款', '非贷款类房款' )
                   AND (NOT ItemName LIKE '%补差%')
             GROUP BY TradeGUID
         ) AS s ON s.TradeGUID = a.TradeGUID
         LEFT JOIN erp25.dbo.s_Fee AS sf ON s.TradeGUID = sf.TradeGUID
                                            AND s.Sequence = sf.Sequence
    WHERE a.Status = '激活'
          AND a.qsdate
          BETWEEN @var_bgndate AND @var_enddate;


    SELECT c.ProjGUID,
        c.ContractGUID,
        c.TradeGUID,
        c.JyTotal,
        c.roomguid,
        c.Status,
        CASE
            WHEN t.jzdate IS NOT NULL THEN
                    t.jzdate
            ELSE CASE
                        WHEN DATEDIFF(qq, gsdate, GETDATE()) > 0 THEN
                            GETDATE()
                        ELSE gsdate
                    END
        END gsdate
    INTO #s_contract1
    FROM #con1 c
        LEFT JOIN s_trade t ON c.tradeguid = t.tradeguid;


    SELECT r.ProjGUID, r.ProductType, r.ProductName, r.Standard, r.BusinessType, r.Product,
           SUM(r.BldArea) AS bnqymj,
           SUM(a.JyTotal + ISNULL(f.amount, 0)) bnqyje,
           SUM((a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)) bnqyjenotax,
           -- 2024年结转
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-01-01') = 0 THEN r.BldArea ELSE 0 END) mj2401, 
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-01-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2401, 
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-01-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2401, 
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-04-01') = 0 THEN r.BldArea ELSE 0 END) mj2402,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-04-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2402,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-04-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2402,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-07-01') = 0 THEN r.BldArea ELSE 0 END) mj2403,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-07-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2403,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-07-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2403,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-10-01') = 0 THEN r.BldArea ELSE 0 END) mj2404,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-10-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2404,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2024-10-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2404,
           -- 2025结转
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-01-01') = 0 THEN r.BldArea ELSE 0 END) mj2501,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-01-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2501,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-01-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2501,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-04-01') = 0 THEN r.BldArea ELSE 0 END) mj2502,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-04-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2502,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-04-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2502,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-07-01') = 0 THEN r.BldArea ELSE 0 END) mj2503,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-07-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2503,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-07-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2503,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-10-01') = 0 THEN r.BldArea ELSE 0 END) mj2504,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-10-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2504,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2025-10-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2504,
           -- 2026年结转
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-01-01') = 0 THEN r.BldArea ELSE 0 END) mj2601,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-01-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2601,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-01-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2601,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-04-01') = 0 THEN r.BldArea ELSE 0 END) mj2602,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-04-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2602,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-04-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2602,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-07-01') = 0 THEN r.BldArea ELSE 0 END) mj2603,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-07-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2603,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-07-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2603,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-10-01') = 0 THEN r.BldArea ELSE 0 END) mj2604,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-10-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2604,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2026-10-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2604,

           -- 2027年结转
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-01-01') = 0 THEN r.BldArea ELSE 0 END) mj2701,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-01-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2701,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-01-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2701,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-04-01') = 0 THEN r.BldArea ELSE 0 END) mj2702,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-04-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2702,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-04-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2702,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-07-01') = 0 THEN r.BldArea ELSE 0 END) mj2703,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-07-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2703,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-07-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2703,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-10-01') = 0 THEN r.BldArea ELSE 0 END) mj2704,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-10-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je2704,
           SUM(CASE WHEN DATEDIFF(qq, a.gsdate, '2027-10-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax2704,

           -- 26年结转
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2026-01-01') = 0 THEN r.BldArea ELSE 0 END) mj26,
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2026-01-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je26,
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2026-01-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax26,
           -- 27年结转
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2027-01-01') = 0 THEN r.BldArea ELSE 0 END) mj27,
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2027-01-01') = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je27,
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2027-01-01') = 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax27,
           -- 28年及之后结转
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2028-01-01') <= 0 THEN r.BldArea ELSE 0 END) mj28plus,
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2028-01-01') <= 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) je28plus,
           SUM(CASE WHEN DATEDIFF(year, a.gsdate, '2028-01-01') <= 0 THEN (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100) ELSE 0 END) jenotax28plus
    INTO #con2
    FROM #s_contract1 a
         INNER JOIN #room r ON a.RoomGUID = r.RoomGUID
         LEFT JOIN erp25.dbo.s_Order d ON a.TradeGUID = d.TradeGUID AND ISNULL(d.CloseReason, '') = '转签约'
         LEFT JOIN (SELECT f.TradeGUID, SUM(Amount) amount FROM erp25.dbo.s_Fee f
                  INNER JOIN #s_Contract c ON f.TradeGUID = c.TradeGUID
             WHERE f.ItemName LIKE '%补差%' GROUP BY f.TradeGUID) f ON a.TradeGUID = f.TradeGUID
         LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
    WHERE a.Status = '激活'
          AND NOT EXISTS (SELECT 1 FROM erp25.dbo.S_PerformanceAppraisalRoom sr
             INNER JOIN erp25.dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                              AND s.AuditStatus = '已审核'
                                                              AND s.YjType NOT IN ('经营类(溢价款)', '物业公司车位代销')
        WHERE r.RoomGUID = sr.RoomGUID)
          AND NOT EXISTS (SELECT 1 FROM erp25.dbo.S_PerformanceAppraisalBuildings sr
             INNER JOIN erp25.dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                              AND s.AuditStatus = '已审核'
                                                              AND s.YjType NOT IN ('经营类(溢价款)', '物业公司车位代销')
        WHERE r.BldGUID = sr.BldGUID)
    GROUP BY r.ProjGUID, r.Product, r.ProductType, r.ProductName, r.Standard, r.BusinessType;



    SELECT a.ProjGUID,
           db.ProductType,
           db.ProductName,
           db.Standard,
           db.BusinessType,
           db.Product,
           a.BizDate,
           db.jzjfdate,
           b.taoshu,
           b.area,
           b.amount * 10000 amount,
           b.Amount / (1 + tax.rate) * 10000 amountnotax
    INTO #hzyjresult1
    FROM #hzyj a
         LEFT JOIN erp25.dbo.s_YJRLBuildingDescript b ON a.ProducteDetailGUID = b.ProducteDetailGUID
         INNER JOIN #db db ON b.bldguid = db.SaleBldGUID
         LEFT JOIN #p f ON a.ProjGUID = f.ProjGUID
         LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.BizDate, tax.bgnDate) <= 0
                                   AND DATEDIFF(DAY, a.BizDate, tax.endDate) >= 0
    WHERE a.BizDate
    BETWEEN @var_bgndate AND @var_enddate;


    SELECT h.ProjGUID,
           h.ProductType,
           h.ProductName,
           h.Standard,
           h.BusinessType,
           h.Product,
           h.BizDate,
           h.jzjfdate,
           h.taoshu * ISNULL(ISNULL(kq.kql, kq1.kql), 1) as  taoshu,
           h.area * ISNULL(ISNULL(kq.kql, kq1.kql), 1) as area,
           h.amount * ISNULL(ISNULL(kq.kql, kq1.kql), 1) amount,
           h.amountnotax * ISNULL(ISNULL(kq.kql, kq1.kql), 1) amountnotax
    INTO #hzyjresult
    FROM #hzyjresult1 h
         LEFT JOIN erp25.dbo.p_project p ON h.projguid = p.projguid
         LEFT JOIN erp25.dbo.s_kq kq ON p.buguid = kq.buguid
                                        AND h.Product = kq.Product
         LEFT JOIN erp25.dbo.s_kql kq1 ON p.buguid = kq1.buguid
                                          AND h.producttype = kq1.producttype;




    SELECT ProjGUID, ProductType, ProductName, Standard, BusinessType, Product,
           SUM(CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END) AS bnqymj,
           SUM(amount) bnqyje, SUM(amountnotax) bnqyjenotax,
           --2024年
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-01-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2401,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-01-01') = 0 THEN amount ELSE 0 END) je2401,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-01-01') = 0 THEN amountnotax ELSE 0 END) jenotax2401,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-04-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2402,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-04-01') = 0 THEN amount ELSE 0 END) je2402,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-04-01') = 0 THEN amountnotax ELSE 0 END) jenotax2402,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-07-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2403,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-07-01') = 0 THEN amount ELSE 0 END) je2403,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-07-01') = 0 THEN amountnotax ELSE 0 END) jenotax2403,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-10-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2404,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-10-01') = 0 THEN amount ELSE 0 END) je2404,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2024-10-01') = 0 THEN amountnotax ELSE 0 END) jenotax2404,
           --2025年
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-01-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2501,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-01-01') = 0 THEN amount ELSE 0 END) je2501,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-01-01') = 0 THEN amountnotax ELSE 0 END) jenotax2501,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-04-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2502,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-04-01') = 0 THEN amount ELSE 0 END) je2502,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-04-01') = 0 THEN amountnotax ELSE 0 END) jenotax2502,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-07-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2503,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-07-01') = 0 THEN amount ELSE 0 END) je2503,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-07-01') = 0 THEN amountnotax ELSE 0 END) jenotax2503,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-10-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2504,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-10-01') = 0 THEN amount ELSE 0 END) je2504,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2025-10-01') = 0 THEN amountnotax ELSE 0 END) jenotax2504,
           -- 26年结转数据
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-01-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2601,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-01-01') = 0 THEN amount ELSE 0 END) je2601,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-01-01') = 0 THEN amountnotax ELSE 0 END) jenotax2601,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-04-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2602,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-04-01') = 0 THEN amount ELSE 0 END) je2602,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-04-01') = 0 THEN amountnotax ELSE 0 END) jenotax2602,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-07-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2603,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-07-01') = 0 THEN amount ELSE 0 END) je2603,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-07-01') = 0 THEN amountnotax ELSE 0 END) jenotax2603,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-10-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2604,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-10-01') = 0 THEN amount ELSE 0 END) je2604,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2026-10-01') = 0 THEN amountnotax ELSE 0 END) jenotax2604,
           -- 27年结转数据
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-01-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2701,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-01-01') = 0 THEN amount ELSE 0 END) je2701,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-01-01') = 0 THEN amountnotax ELSE 0 END) jenotax2701,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-04-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2702,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-04-01') = 0 THEN amount ELSE 0 END) je2702,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-04-01') = 0 THEN amountnotax ELSE 0 END) jenotax2702,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-07-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2703,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-07-01') = 0 THEN amount ELSE 0 END) je2703,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-07-01') = 0 THEN amountnotax ELSE 0 END) jenotax2703,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-10-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj2704,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-10-01') = 0 THEN amount ELSE 0 END) je2704,
           SUM(CASE WHEN DATEDIFF(qq, jzjfdate, '2027-10-01') = 0 THEN amountnotax ELSE 0 END) jenotax2704,
           
           --26年结转
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2026-01-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj26,
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2026-01-01') = 0 THEN amount ELSE 0 END) je26,
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2026-01-01') = 0 THEN amountnotax ELSE 0 END) jenotax26,
           --27年结转
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2027-01-01') = 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj27,
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2027-01-01') = 0 THEN amount ELSE 0 END) je27,
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2027-01-01') = 0 THEN amountnotax ELSE 0 END) jenotax27,
           --28年及之后结转
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2028-01-01') <= 0 THEN CASE WHEN ProductType = '地下室/车库' THEN Taoshu ELSE Area END ELSE 0 END) mj28plus,
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2028-01-01') <= 0 THEN amount ELSE 0 END) je28plus,
           SUM(CASE WHEN DATEDIFF(year, jzjfdate, '2028-01-01') <= 0 THEN amountnotax ELSE 0 END) jenotax28plus
    INTO #h1
    FROM #hzyjresult
    GROUP BY ProjGUID, ProductType, ProductName, Standard, BusinessType, Product




    --取手工维护的匹配关系
    SELECT 项目guid,
           T.基础数据主键,
           T.盈利规划系统自动匹对主键,
           CASE
               WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN
                    T.盈利规划系统自动匹对主键
               ELSE CASE
                        WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                             T.盈利规划主键
                        ELSE T.基础数据主键
                    END
           END 盈利规划主键,
           MAX(T.[营业成本单方(元/平方米)]) AS 营业成本单方,
           MAX(T.[营销费用单方(元/平方米)]) AS 营销费用单方,
           MAX(T.[综合管理费单方(元/平方米)]) AS 综合管理费单方,
           MAX(T.[股权溢价单方(元/平方米)]) AS 股权溢价单方,
           MAX(T.[税金及附加单方(元/平方米)]) AS 税金及附加单方,
           MAX(T.[除地价外直投单方(元/平方米)]) AS 除地价外直投单方,
           MAX(T.[土地款单方(元/平方米)]) AS 土地款单方,
           MAX(T.[资本化利息单方(元/平方米)]) AS 资本化利息单方,
           MAX(T.[开发间接费单方(元/平方米)]) AS 开发间接费单方
    INTO #key1
    FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 T
         INNER JOIN
         (
             SELECT ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM,
                    FillHistoryGUID
             FROM dss.dbo.nmap_F_FillHistory a
             WHERE EXISTS
             (
                 SELECT FillHistoryGUID,
                        SUM(   CASE
                                   WHEN 项目guid IS NULL
                                        OR 项目guid = '' THEN
                                        0
                                   ELSE 1
                               END
                           ) AS num
                 FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 b
                 WHERE a.FillHistoryGUID = b.FillHistoryGUID
                 GROUP BY FillHistoryGUID
                 HAVING SUM(   CASE
                                   WHEN 项目guid IS NULL THEN
                                        0
                                   ELSE 1
                               END
                           ) > 0
             )
         ) V ON T.FillHistoryGUID = V.FillHistoryGUID
                AND V.NUM = 1
    WHERE ISNULL(T.项目guid, '') <> ''
    GROUP BY 项目guid,
             T.基础数据主键,
             T.盈利规划系统自动匹对主键,
             CASE
                 WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN
                      T.盈利规划系统自动匹对主键
                 ELSE CASE
                          WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                               T.盈利规划主键
                          ELSE T.基础数据主键
                      END
             END;


    SELECT db.ProjGUID,
           db.Product MyProduct,
           db.ProductType,
           db.ProductName,
           db.Standard,
           db.BusinessType,
           ISNULL(dss.盈利规划主键, db.Product) Product,
           SUM(ISNULL(s.bnqymj, 0)) bnqymj,
           SUM(ISNULL(s.bnqyje, 0)) bnqyje,
           SUM(ISNULL(s.bnqyjenotax, 0)) bnqyjenotax,
           SUM(ISNULL(s.mj2401, 0)) mj2401,
           SUM(ISNULL(s.je2401, 0)) je2401,
           SUM(ISNULL(s.jenotax2401, 0)) jenotax2401,
           SUM(ISNULL(s.mj2402, 0)) mj2402,
           SUM(ISNULL(s.je2402, 0)) je2402,
           SUM(ISNULL(s.jenotax2402, 0)) jenotax2402,
           SUM(ISNULL(s.mj2403, 0)) mj2403,
           SUM(ISNULL(s.je2403, 0)) je2403,
           SUM(ISNULL(s.jenotax2403, 0)) jenotax2403,
           SUM(ISNULL(s.mj2404, 0)) mj2404,
           SUM(ISNULL(s.je2404, 0)) je2404,
           SUM(ISNULL(s.jenotax2404, 0)) jenotax2404,
           -- 25年结转数据
           SUM(ISNULL(s.mj2501, 0)) mj2501,
           SUM(ISNULL(s.je2501, 0)) je2501,
           SUM(ISNULL(s.jenotax2501, 0)) jenotax2501,
           SUM(ISNULL(s.mj2502, 0)) mj2502,
           SUM(ISNULL(s.je2502, 0)) je2502,
           SUM(ISNULL(s.jenotax2502, 0)) jenotax2502,
           SUM(ISNULL(s.mj2503, 0)) mj2503,
           SUM(ISNULL(s.je2503, 0)) je2503,
           SUM(ISNULL(s.jenotax2503, 0)) jenotax2503,
           SUM(ISNULL(s.mj2504, 0)) mj2504,
           SUM(ISNULL(s.je2504, 0)) je2504,
           SUM(ISNULL(s.jenotax2504, 0)) jenotax2504,
           -- 26年结转数据
           SUM(ISNULL(s.mj2601, 0)) mj2601,
           SUM(ISNULL(s.je2601, 0)) je2601,
           SUM(ISNULL(s.jenotax2601, 0)) jenotax2601,
           SUM(ISNULL(s.mj2602, 0)) mj2602,
           SUM(ISNULL(s.je2602, 0)) je2602,
           SUM(ISNULL(s.jenotax2602, 0)) jenotax2602,
           SUM(ISNULL(s.mj2603, 0)) mj2603,
           SUM(ISNULL(s.je2603, 0)) je2603,
           SUM(ISNULL(s.jenotax2603, 0)) jenotax2603,
           SUM(ISNULL(s.mj2604, 0)) mj2604,
           SUM(ISNULL(s.je2604, 0)) je2604,
           SUM(ISNULL(s.jenotax2604, 0)) jenotax2604,
           -- 27年结转数据
           SUM(ISNULL(s.mj2701, 0)) mj2701,
           SUM(ISNULL(s.je2701, 0)) je2701,
           SUM(ISNULL(s.jenotax2701, 0)) jenotax2701,
           SUM(ISNULL(s.mj2702, 0)) mj2702,
           SUM(ISNULL(s.je2702, 0)) je2702,
           SUM(ISNULL(s.jenotax2702, 0)) jenotax2702,
           SUM(ISNULL(s.mj2703, 0)) mj2703,
           SUM(ISNULL(s.je2703, 0)) je2703,
           SUM(ISNULL(s.jenotax2703, 0)) jenotax2703,
           SUM(ISNULL(s.mj2704, 0)) mj2704,
           SUM(ISNULL(s.je2704, 0)) je2704,
           SUM(ISNULL(s.jenotax2704, 0)) jenotax2704,
           --26年结转数据
           SUM(ISNULL(s.mj26, 0)) mj26,
           SUM(ISNULL(s.je26, 0)) je26,
           SUM(ISNULL(s.jenotax26, 0)) jenotax26,
           --27年结转数据
           SUM(ISNULL(s.mj27, 0)) mj27,
           SUM(ISNULL(s.je27, 0)) je27,
           SUM(ISNULL(s.jenotax27, 0)) jenotax27,
           --28年及之后结转数据
           SUM(ISNULL(s.mj28plus, 0)) mj28plus,
           SUM(ISNULL(s.je28plus, 0)) je28plus,
           SUM(ISNULL(s.jenotax28plus, 0)) jenotax28plus
    INTO #sale1
    FROM
    (
        SELECT DISTINCT
               db.ProjGUID,
               db.Product,
               db.ProductType,
               db.ProductName,
               db.Standard,
               db.BusinessType
        FROM #db db
    ) db
    INNER JOIN
    (
        SELECT a.ProjGUID,
               a.Product,
               a.ProductType,
               a.ProductName,
               a.Standard,
               a.BusinessType,
               a.bnqymj,
               a.bnqyje,
               a.bnqyjenotax,
               a.mj2401,
               a.je2401,
               a.jenotax2401,
               a.mj2402,
               a.je2402,
               a.jenotax2402,
               a.mj2403,
               a.je2403,
               a.jenotax2403,
               a.mj2404,
               a.je2404,
               a.jenotax2404,
               a.mj2501,
               a.je2501,
               a.jenotax2501,
               a.mj2502,
               a.je2502,
               a.jenotax2502,
               a.mj2503,
               a.je2503,
               a.jenotax2503,
               a.mj2504,
               a.je2504,
               a.jenotax2504,
               -- 26年结转数据
               a.mj2601,
               a.je2601,
               a.jenotax2601,
               a.mj2602,
               a.je2602,
               a.jenotax2602,
               a.mj2603,
               a.je2603,
               a.jenotax2603,
               a.mj2604,
               a.je2604,
               a.jenotax2604,
               -- 27年结转数据
               a.mj2701,
               a.je2701,
               a.jenotax2701,
               a.mj2702,
               a.je2702,
               a.jenotax2702,
               a.mj2703,
               a.je2703,
               a.jenotax2703,
               a.mj2704,
               a.je2704,
               a.jenotax2704,
               --26年结转数据
               a.mj26,
               a.je26,
               a.jenotax26,
               --27年结转数据
               a.mj27,
               a.je27,
               a.jenotax27,
               --28年及之后结转数据
               a.mj28plus,
               a.je28plus,
               a.jenotax28plus
        FROM #con2 a
        UNION ALL
        SELECT a.ProjGUID,
               a.Product,
               a.ProductType,
               a.ProductName,
               a.Standard,
               a.BusinessType,
               a.bnqymj,
               a.bnqyje,
               a.bnqyjenotax,
               a.mj2401,
               a.je2401,
               a.jenotax2401,
               a.mj2402,
               a.je2402,
               a.jenotax2402,
               a.mj2403,
               a.je2403,
               a.jenotax2403,
               a.mj2404,
               a.je2404,
               a.jenotax2404,
               -- 25年结转数据
               a.mj2501,
               a.je2501,
               a.jenotax2501,
               a.mj2502,
               a.je2502,
               a.jenotax2502,
               a.mj2503,
               a.je2503,
               a.jenotax2503,
               a.mj2504,
               a.je2504,
               a.jenotax2504,
               -- 26年结转数据
               a.mj2601,
               a.je2601,
               a.jenotax2601,
               a.mj2602,
               a.je2602,
               a.jenotax2602,
               a.mj2603,
               a.je2603,
               a.jenotax2603,
               a.mj2604,
               a.je2604,
               a.jenotax2604,
               -- 27年结转数据  
               a.mj2701,
               a.je2701,
               a.jenotax2701,
               a.mj2702,
               a.je2702,
               a.jenotax2702,
               a.mj2703,    
               a.je2703,
               a.jenotax2703,
               a.mj2704,
               a.je2704,
               a.jenotax2704,
               --26年结转数据
               a.mj26,
               a.je26,
               a.jenotax26,
               --27年结转数据
               a.mj27,
               a.je27,
               a.jenotax27,
               --28年及之后结转数据
               a.mj28plus,
               a.je28plus,
               a.jenotax28plus
        FROM #h1 a
    ) s ON db.ProjGUID = s.ProjGUID   AND db.Product = s.Product
    LEFT JOIN
    (SELECT DISTINCT k.项目guid, k.基础数据主键, k.盈利规划主键 FROM #key1 k) dss ON dss.项目guid = db.ProjGUID AND dss.基础数据主键 = db.Product --业态匹配
    GROUP BY db.ProjGUID,
             db.Product,
             db.ProductType,
             db.ProductName,
             db.Standard,
             db.BusinessType,
             ISNULL(dss.盈利规划主键, db.Product);


    --盈利规划
    -- 营业成本单方 	 其中：地价单方 	 其中：除地价外直投单方 	 其中：开发间接费单方 	 其中：资本化利息单方 	 
    --股权溢价单方 	 营销费用单方 	 综合管理费用单方 	 税金及附加单方 

    --OrgGuid,平台公司,项目guid,项目名称,项目代码,投管代码,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,匹配主键,
    --总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,盈利规划营业成本单方,税金及附加单方,股权溢价单方,
    --管理费用单方,营销费用单方,资本化利息单方,开发间接费单方,总投资不含税单方 ,盈利规划车位数
    SELECT DISTINCT
           k.[项目guid], -- 避免重复
           ISNULL(k.盈利规划主键, ylgh.匹配主键) 业态组合键,
           ISNULL(ylgh.总可售面积, 0) AS 盈利规划总可售面积,
           CASE
               WHEN ISNULL(k.营业成本单方, 0) = 0 THEN
                    ISNULL(ylgh.盈利规划营业成本单方, 0)
               ELSE ISNULL(k.营业成本单方, 0)
           END AS 盈利规划营业成本单方,
           CASE
               WHEN ISNULL(k.土地款单方, 0) = 0 THEN
                    ISNULL(ylgh.土地款_单方, 0)
               ELSE k.土地款单方
           END 土地款_单方,
           CASE
               WHEN ISNULL(k.除地价外直投单方, 0) = 0 THEN
                    ISNULL(ylgh.除地外直投_单方, 0)
               ELSE k.除地价外直投单方
           END AS 除地外直投_单方,
           CASE
               WHEN ISNULL(k.开发间接费单方, 0) = 0 THEN
                    ISNULL(ylgh.开发间接费单方, 0)
               ELSE k.开发间接费单方
           END AS 开发间接费单方,
           CASE
               WHEN ISNULL(k.资本化利息单方, 0) = 0 THEN
                    ISNULL(ylgh.资本化利息单方, 0)
               ELSE k.资本化利息单方
           END AS 资本化利息单方,
           CASE
               WHEN ISNULL(k.股权溢价单方, 0) = 0 THEN
                    ISNULL(ylgh.股权溢价单方, 0)
               ELSE k.股权溢价单方
           END AS 盈利规划股权溢价单方,
           CASE
               WHEN ISNULL(k.营销费用单方, 0) = 0 THEN
                    ISNULL(ylgh.营销费用单方, 0)
               ELSE k.营销费用单方
           END AS 盈利规划营销费用单方,
           CASE
               WHEN ISNULL(k.综合管理费单方, 0) = 0 THEN
                    ISNULL(ylgh.管理费用单方, 0)
               ELSE k.综合管理费单方
           END AS 盈利规划综合管理费单方协议口径,
           CASE
               WHEN ISNULL(k.税金及附加单方, 0) = 0 THEN
                    ISNULL(ylgh.税金及附加单方, 0)
               ELSE k.税金及附加单方
           END AS 盈利规划税金及附加单方
    INTO #ylgh1
    FROM #key1 k
         LEFT JOIN dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh ON ylgh.匹配主键 = k.盈利规划主键
                                                          AND ylgh.[项目guid] = k.项目guid
         INNER JOIN #p p ON k.项目guid = p.ProjGUID;


--------------------按照盈利规划锁定版本进行单方等比例缩小放大逻辑 begin--------------------------------  
    -- select 
    --     a.项目guid,
    --     a.业态组合键,
    --     case when isnull(b.除地外直投_单方,0) <1 then  0 else  a.除地外直投_单方 / b.除地外直投_单方  end as  除地价外直投变动率,
    --     case when isnull(b.管理费用单方,0) <1 then  0 else  a.盈利规划综合管理费单方协议口径 / b.管理费用单方  end as  管理费用变动率,
    --     case when isnull(b.营销费用单方,0) <1 then  0 else  a.盈利规划营销费用单方 / b.营销费用单方  end as  营销费用变动率,
    --     case when isnull(b.股权溢价单方,0) <1 then  0 else  a.盈利规划股权溢价单方 / b.股权溢价单方  end as  股权溢价单方变动率
    -- into #bdl1
    -- from #ylgh1 a
    -- inner join dss.dbo.s_F066项目毛利率销售底表_盈利规划单方锁定版 b on a.项目guid = b.项目guid and a.业态组合键 = b.匹配主键



    -- UPDATE p 
    -- SET p.盈利规划营业成本单方 = p.除地外直投_单方 * (1 + 除地价外直投变动率) + 
    --                                 p.土地款_单方 + 
    --                                 p.开发间接费单方 + 
    --                                 p.资本化利息单方, --如果是在指定项目分期的范围内，营业成本 = 除地价外直投+土地款+开发间接费+资本化利息
    --     p.除地外直投_单方 = p.除地外直投_单方 * (1 + 除地价外直投变动率), --增加指定项目的除地价外直投单方变动率
    --     p.盈利规划综合管理费单方协议口径 = p.盈利规划综合管理费单方协议口径 * (1 + 管理费用变动率), --增加指定项目的管理费用单方变动率
    --     p.盈利规划营销费用单方 = p.盈利规划营销费用单方 * (1 + 营销费用变动率), --增加指定项目的营销费用单方变动率
    --     p.盈利规划股权溢价单方 = p.盈利规划股权溢价单方 * (1 + 股权溢价单方变动率) --增加指定项目的股权溢价单方变动率
    -- FROM #ylgh1 p
    -- INNER JOIN #bdl1 b ON b.项目guid = p.项目guid and b.业态组合键 = p.业态组合键

  --------------------按照盈利规划锁定版本进行单方等比例缩小放大逻辑 end--------------------------------  

    --计算项目成本
    SELECT a.ProjGUID,
           a.MyProduct,
           a.Product,
           a.ProductType,
           a.ProductName,
           a.Standard,
           a.BusinessType,
           y.盈利规划营业成本单方,
           y.土地款_单方,
           y.除地外直投_单方,
           y.开发间接费单方,
           y.资本化利息单方,
           y.盈利规划股权溢价单方,
           y.盈利规划营销费用单方,
           y.盈利规划综合管理费单方协议口径,
           y.盈利规划税金及附加单方,
           SUM(ISNULL(a.bnqymj, 0)) bnqymj,
           SUM(ISNULL(a.bnqyje, 0)) bnqyje,
           SUM(ISNULL(a.bnqyjenotax, 0)) bnqyjenotax,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.bnqymj, 0)) 盈利规划营业成本本年签约,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.bnqymj, 0)) 盈利规划股权溢价本年签约,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.bnqymj, 0)) 盈利规划营销费用本年签约,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.bnqymj, 0)) 盈利规划综合管理费本年签约,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.bnqymj, 0)) 盈利规划税金及附加本年签约,

           ---2024年
           SUM(ISNULL(a.mj2401, 0)) mj2401,
           SUM(ISNULL(a.je2401, 0)) je2401,
           SUM(ISNULL(a.jenotax2401, 0)) jenotax2401,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2401, 0)) 盈利规划营业成本2401,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2401, 0)) 盈利规划股权溢价2401,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2401, 0)) 盈利规划营销费用2401,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2401, 0)) 盈利规划综合管理费2401,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2401, 0)) 盈利规划税金及附加2401,
           SUM(ISNULL(a.mj2402, 0)) mj2402,
           SUM(ISNULL(a.je2402, 0)) je2402,
           SUM(ISNULL(a.jenotax2402, 0)) jenotax2402,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2402, 0)) 盈利规划营业成本2402,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2402, 0)) 盈利规划股权溢价2402,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2402, 0)) 盈利规划营销费用2402,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2402, 0)) 盈利规划综合管理费2402,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2402, 0)) 盈利规划税金及附加2402,
           SUM(ISNULL(a.mj2403, 0)) mj2403,
           SUM(ISNULL(a.je2403, 0)) je2403,
           SUM(ISNULL(a.jenotax2403, 0)) jenotax2403,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2403, 0)) 盈利规划营业成本2403,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2403, 0)) 盈利规划股权溢价2403,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2403, 0)) 盈利规划营销费用2403,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2403, 0)) 盈利规划综合管理费2403,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2403, 0)) 盈利规划税金及附加2403,
           SUM(ISNULL(a.mj2404, 0)) mj2404,
           SUM(ISNULL(a.je2404, 0)) je2404,
           SUM(ISNULL(a.jenotax2404, 0)) jenotax2404,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2404, 0)) 盈利规划营业成本2404,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2404, 0)) 盈利规划股权溢价2404,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2404, 0)) 盈利规划营销费用2404,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2404, 0)) 盈利规划综合管理费2404,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2404, 0)) 盈利规划税金及附加2404,

           ---2025年
           SUM(ISNULL(a.mj2501, 0)) mj2501,
           SUM(ISNULL(a.je2501, 0)) je2501,
           SUM(ISNULL(a.jenotax2501, 0)) jenotax2501,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2501, 0)) 盈利规划营业成本2501,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2501, 0)) 盈利规划股权溢价2501,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2501, 0)) 盈利规划营销费用2501,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2501, 0)) 盈利规划综合管理费2501,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2501, 0)) 盈利规划税金及附加2501,
           SUM(ISNULL(a.mj2502, 0)) mj2502,
           SUM(ISNULL(a.je2502, 0)) je2502,
           SUM(ISNULL(a.jenotax2502, 0)) jenotax2502,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2502, 0)) 盈利规划营业成本2502,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2502, 0)) 盈利规划股权溢价2502,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2502, 0)) 盈利规划营销费用2502,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2502, 0)) 盈利规划综合管理费2502,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2502, 0)) 盈利规划税金及附加2502,
           SUM(ISNULL(a.mj2503, 0)) mj2503,
           SUM(ISNULL(a.je2503, 0)) je2503,
           SUM(ISNULL(a.jenotax2503, 0)) jenotax2503,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2503, 0)) 盈利规划营业成本2503,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2503, 0)) 盈利规划股权溢价2503,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2503, 0)) 盈利规划营销费用2503,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2503, 0)) 盈利规划综合管理费2503,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2503, 0)) 盈利规划税金及附加2503,
           SUM(ISNULL(a.mj2504, 0)) mj2504,
           SUM(ISNULL(a.je2504, 0)) je2504,
           SUM(ISNULL(a.jenotax2504, 0)) jenotax2504,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2504, 0)) 盈利规划营业成本2504,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2504, 0)) 盈利规划股权溢价2504,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2504, 0)) 盈利规划营销费用2504,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2504, 0)) 盈利规划综合管理费2504,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2504, 0)) 盈利规划税金及附加2504,

           ---26年数据  
           SUM(ISNULL(a.mj2601, 0)) mj2601,
           SUM(ISNULL(a.je2601, 0)) je2601,
           SUM(ISNULL(a.jenotax2601, 0)) jenotax2601,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2601, 0)) 盈利规划营业成本2601,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2601, 0)) 盈利规划股权溢价2601,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2601, 0)) 盈利规划营销费用2601,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2601, 0)) 盈利规划综合管理费2601,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2601, 0)) 盈利规划税金及附加2601,
           SUM(ISNULL(a.mj2602, 0)) mj2602,
           SUM(ISNULL(a.je2602, 0)) je2602,
           SUM(ISNULL(a.jenotax2602, 0)) jenotax2602,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2602, 0)) 盈利规划营业成本2602,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2602, 0)) 盈利规划股权溢价2602,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2602, 0)) 盈利规划营销费用2602,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2602, 0)) 盈利规划综合管理费2602,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2602, 0)) 盈利规划税金及附加2602,
           SUM(ISNULL(a.mj2603, 0)) mj2603,
           SUM(ISNULL(a.je2603, 0)) je2603,
           SUM(ISNULL(a.jenotax2603, 0)) jenotax2603,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2603, 0)) 盈利规划营业成本2603,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2603, 0)) 盈利规划股权溢价2603,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2603, 0)) 盈利规划营销费用2603,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2603, 0)) 盈利规划综合管理费2603,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2603, 0)) 盈利规划税金及附加2603,
           SUM(ISNULL(a.mj2604, 0)) mj2604,
           SUM(ISNULL(a.je2604, 0)) je2604,
           SUM(ISNULL(a.jenotax2604, 0)) jenotax2604,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2604, 0)) 盈利规划营业成本2604,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2604, 0)) 盈利规划股权溢价2604,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2604, 0)) 盈利规划营销费用2604,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2604, 0)) 盈利规划综合管理费2604,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2604, 0)) 盈利规划税金及附加2604,
           -- 27年结转数据
           SUM(ISNULL(a.mj2701, 0)) mj2701,
           SUM(ISNULL(a.je2701, 0)) je2701,
           SUM(ISNULL(a.jenotax2701, 0)) jenotax2701,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2701, 0)) 盈利规划营业成本2701,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2701, 0)) 盈利规划股权溢价2701,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2701, 0)) 盈利规划营销费用2701,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2701, 0)) 盈利规划综合管理费2701,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2701, 0)) 盈利规划税金及附加2701,
           SUM(ISNULL(a.mj2702, 0)) mj2702,
           SUM(ISNULL(a.je2702, 0)) je2702,
           SUM(ISNULL(a.jenotax2702, 0)) jenotax2702,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2702, 0)) 盈利规划营业成本2702,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2702, 0)) 盈利规划股权溢价2702,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2702, 0)) 盈利规划营销费用2702,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2702, 0)) 盈利规划综合管理费2702,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2702, 0)) 盈利规划税金及附加2702,
           SUM(ISNULL(a.mj2703, 0)) mj2703,
           SUM(ISNULL(a.je2703, 0)) je2703,
           SUM(ISNULL(a.jenotax2703, 0)) jenotax2703,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2703, 0)) 盈利规划营业成本2703,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2703, 0)) 盈利规划股权溢价2703,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2703, 0)) 盈利规划营销费用2703,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2703, 0)) 盈利规划综合管理费2703,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2703, 0)) 盈利规划税金及附加2703,
           SUM(ISNULL(a.mj2704, 0)) mj2704,
           SUM(ISNULL(a.je2704, 0)) je2704,
           SUM(ISNULL(a.jenotax2704, 0)) jenotax2704,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj2704, 0)) 盈利规划营业成本2704,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj2704, 0)) 盈利规划股权溢价2704,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj2704, 0)) 盈利规划营销费用2704,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj2704, 0)) 盈利规划综合管理费2704,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj2704, 0)) 盈利规划税金及附加2704,

           --26年结转数据
           SUM(ISNULL(a.mj26, 0)) mj26,
           SUM(ISNULL(a.je26, 0)) je26,
           SUM(ISNULL(a.jenotax26, 0)) jenotax26,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj26, 0)) 盈利规划营业成本26,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj26, 0)) 盈利规划股权溢价26,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj26, 0)) 盈利规划营销费用26,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj26, 0)) 盈利规划综合管理费26,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj26, 0)) 盈利规划税金及附加26,

           --27年结转数据
           SUM(ISNULL(a.mj27, 0)) mj27,
           SUM(ISNULL(a.je27, 0)) je27,
           SUM(ISNULL(a.jenotax27, 0)) jenotax27,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj27, 0)) 盈利规划营业成本27,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj27, 0)) 盈利规划股权溢价27,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj27, 0)) 盈利规划营销费用27,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj27, 0)) 盈利规划综合管理费27,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj27, 0)) 盈利规划税金及附加27,

           --28年及之后结转数据
           SUM(ISNULL(a.mj28plus, 0)) mj28plus,
           SUM(ISNULL(a.je28plus, 0)) je28plus,
           SUM(ISNULL(a.jenotax28plus, 0)) jenotax28plus,
           SUM(ISNULL(y.盈利规划营业成本单方, 0) * ISNULL(a.mj28plus, 0)) 盈利规划营业成本28plus,
           SUM(ISNULL(y.盈利规划股权溢价单方, 0) * ISNULL(a.mj28plus, 0)) 盈利规划股权溢价28plus,
           SUM(ISNULL(y.盈利规划营销费用单方, 0) * ISNULL(a.mj28plus, 0)) 盈利规划营销费用28plus,
           SUM(ISNULL(y.盈利规划综合管理费单方协议口径, 0) * ISNULL(a.mj28plus, 0)) 盈利规划综合管理费28plus,
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.mj28plus, 0)) 盈利规划税金及附加28plus
    INTO #cost1
    FROM #sale1 a
         LEFT JOIN #ylgh1 y ON a.ProjGUID = y.[项目guid]
                               AND a.Product = y.业态组合键
    GROUP BY a.ProjGUID,
             a.Product,
             a.MyProduct,
             a.ProductType,
             a.ProductName,
             a.Standard,
             a.BusinessType,
             y.盈利规划营业成本单方,
             y.土地款_单方,
             y.除地外直投_单方,
             y.开发间接费单方,
             y.资本化利息单方,
             y.盈利规划股权溢价单方,
             y.盈利规划营销费用单方,
             y.盈利规划综合管理费单方协议口径,
             y.盈利规划税金及附加单方;


   -- 计算项目税前利润
    SELECT c.ProjGUID,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.bnqyjenotax, 0) - ISNULL(c.盈利规划营业成本本年签约, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用本年签约, 0) - ISNULL(c.盈利规划综合管理费本年签约, 0) - ISNULL(c.盈利规划税金及附加本年签约, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润本年签约,
           ---24年数据
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2401, 0) - ISNULL(c.盈利规划营业成本2401, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2401, 0) - ISNULL(c.盈利规划综合管理费2401, 0) - ISNULL(c.盈利规划税金及附加2401, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2401,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2402, 0) - ISNULL(c.盈利规划营业成本2402, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2402, 0) - ISNULL(c.盈利规划综合管理费2402, 0) - ISNULL(c.盈利规划税金及附加2402, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2402,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2403, 0) - ISNULL(c.盈利规划营业成本2403, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2403, 0) - ISNULL(c.盈利规划综合管理费2403, 0) - ISNULL(c.盈利规划税金及附加2403, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2403,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2404, 0) - ISNULL(c.盈利规划营业成本2404, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2404, 0) - ISNULL(c.盈利规划综合管理费2404, 0) - ISNULL(c.盈利规划税金及附加2404, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2404,

           --25年数据 
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2501, 0) - ISNULL(c.盈利规划营业成本2501, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2501, 0) - ISNULL(c.盈利规划综合管理费2501, 0) - ISNULL(c.盈利规划税金及附加2501, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2501,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2502, 0) - ISNULL(c.盈利规划营业成本2502, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2502, 0) - ISNULL(c.盈利规划综合管理费2502, 0) - ISNULL(c.盈利规划税金及附加2502, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2502,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2503, 0) - ISNULL(c.盈利规划营业成本2503, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2503, 0) - ISNULL(c.盈利规划综合管理费2503, 0) - ISNULL(c.盈利规划税金及附加2503, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2503,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2504, 0) - ISNULL(c.盈利规划营业成本2504, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2504, 0) - ISNULL(c.盈利规划综合管理费2504, 0) - ISNULL(c.盈利规划税金及附加2504, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2504,
        --26年数据 
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2601, 0) - ISNULL(c.盈利规划营业成本2601, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2601, 0) - ISNULL(c.盈利规划综合管理费2601, 0) - ISNULL(c.盈利规划税金及附加2601, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2601,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2602, 0) - ISNULL(c.盈利规划营业成本2602, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2602, 0) - ISNULL(c.盈利规划综合管理费2602, 0) - ISNULL(c.盈利规划税金及附加2602, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2602,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2603, 0) - ISNULL(c.盈利规划营业成本2603, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2603, 0) - ISNULL(c.盈利规划综合管理费2603, 0) - ISNULL(c.盈利规划税金及附加2603, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2603,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2604, 0) - ISNULL(c.盈利规划营业成本2604, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2604, 0) - ISNULL(c.盈利规划综合管理费2604, 0) - ISNULL(c.盈利规划税金及附加2604, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2604,
         --27年数据 
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2701, 0) - ISNULL(c.盈利规划营业成本2701, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2701, 0) - ISNULL(c.盈利规划综合管理费2701, 0) - ISNULL(c.盈利规划税金及附加2701, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2701,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2702, 0) - ISNULL(c.盈利规划营业成本2702, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2702, 0) - ISNULL(c.盈利规划综合管理费2702, 0) - ISNULL(c.盈利规划税金及附加2702, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2702,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2703, 0) - ISNULL(c.盈利规划营业成本2703, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2703, 0) - ISNULL(c.盈利规划综合管理费2703, 0) - ISNULL(c.盈利规划税金及附加2703, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2703,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax2704, 0) - ISNULL(c.盈利规划营业成本2704, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用2704, 0) - ISNULL(c.盈利规划综合管理费2704, 0) - ISNULL(c.盈利规划税金及附加2704, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润2704,

        -- 26年结转利润
        SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax26, 0) - ISNULL(c.盈利规划营业成本26, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用26, 0) - ISNULL(c.盈利规划综合管理费26, 0) - ISNULL(c.盈利规划税金及附加26, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润26,

        -- 27年结转利润
        SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax27, 0) - ISNULL(c.盈利规划营业成本27, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用27, 0) - ISNULL(c.盈利规划综合管理费27, 0) - ISNULL(c.盈利规划税金及附加27, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润27,
        -- 28年及之后结转利润
        SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.jenotax28plus, 0) - ISNULL(c.盈利规划营业成本28plus, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用28plus, 0) - ISNULL(c.盈利规划综合管理费28plus, 0) - ISNULL(c.盈利规划税金及附加28plus, 0)
                          )
                          / 100000000
                      )
              ) 项目税前利润28plus
    INTO #xm1
    FROM #cost1 c
    GROUP BY c.ProjGUID;

    -- 项目代码（投管） 	 明源代码 	 子公司  认购面积 	 认购金额 	 认购金额（不含税) 	 营业成本 	 股权溢价 	 毛利 	 毛利率 	 营销费用 	 管理费用 	 税金及附加 	 税前利润 	 所得税 	 净利润 	 销售净利率 
    SELECT p.ProjGUID,
           f.平台公司,
           f.项目名,
           f.推广名,
           f.项目代码,
           f.投管代码,
           f.项目权益比率,
           f.盈利规划上线方式,
           f.是否录入合作业绩,
           c.ProductType 产品类型,
           c.ProductName 产品名称,
           c.Standard 装修标准,
           c.BusinessType 商品类型,
           c.MyProduct 明源匹配主键,
           c.Product 业态组合键,
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.bnqymj
                          ELSE c.bnqymj / 10000
                      END
                  ) 当年签约面积,
           CONVERT(DECIMAL(36, 9), c.bnqyje) / 100000000.0 本年签约金额,
           CONVERT(DECIMAL(36, 9), c.bnqyjenotax) / 100000000.0 本年签约金额不含税,
           c.盈利规划营业成本单方,
           --c.土地款_单方,
           --c.除地外直投_单方,
           --c.开发间接费单方,
           --c.资本化利息单方,
           --c.盈利规划股权溢价单方,
           c.盈利规划营销费用单方,
           c.盈利规划综合管理费单方协议口径,
           c.盈利规划税金及附加单方,
           CONVERT(DECIMAL(36, 8), c.盈利规划营业成本本年签约 / 100000000) 盈利规划营业成本本年签约,
           CONVERT(DECIMAL(36, 8), c.盈利规划营销费用本年签约 / 100000000) 盈利规划营销费用本年签约,
           CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费本年签约 / 100000000) 盈利规划综合管理费本年签约,
           CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加本年签约 / 100000000) 盈利规划税金及附加本年签约,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.bnqyjenotax, 0) - ISNULL(c.盈利规划营业成本本年签约, 0) - ISNULL(c.盈利规划股权溢价本年签约, 0))
                       - ISNULL(c.盈利规划营销费用本年签约, 0) - ISNULL(c.盈利规划综合管理费本年签约, 0) - c.盈利规划税金及附加本年签约
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润本年签约 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.bnqyjenotax, 0) - ISNULL(c.盈利规划营业成本本年签约, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用本年签约, 0) - ISNULL(c.盈利规划综合管理费本年签约, 0) - ISNULL(c.盈利规划税金及附加本年签约, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 本年签约利润,

          ---按季度结转数据2401
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2401
                          ELSE c.mj2401 / 10000
                      END
                  ) 结转面积2401,
           CONVERT(DECIMAL(36, 9), c.je2401) / 100000000.0 结转金额2401,
           CONVERT(DECIMAL(36, 9), c.jenotax2401) / 100000000.0 结转金额不含税2401,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2401, 0) - ISNULL(c.盈利规划营业成本2401, 0) - ISNULL(c.盈利规划股权溢价2401, 0))
                       - ISNULL(c.盈利规划营销费用2401, 0) - ISNULL(c.盈利规划综合管理费2401, 0) - c.盈利规划税金及附加2401
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2401 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2401, 0) - ISNULL(c.盈利规划营业成本2401, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2401, 0) - ISNULL(c.盈利规划综合管理费2401, 0) - ISNULL(c.盈利规划税金及附加2401, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2401,


           ---按季度结转数据2402
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2402
                          ELSE c.mj2402 / 10000
                      END
                  ) 结转面积2402,
           CONVERT(DECIMAL(36, 9), c.je2402) / 100000000.0 结转金额2402,
           CONVERT(DECIMAL(36, 9), c.jenotax2402) / 100000000.0 结转金额不含税2402,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2402, 0) - ISNULL(c.盈利规划营业成本2402, 0) - ISNULL(c.盈利规划股权溢价2402, 0))
                       - ISNULL(c.盈利规划营销费用2402, 0) - ISNULL(c.盈利规划综合管理费2402, 0) - c.盈利规划税金及附加2402
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2402 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2402, 0) - ISNULL(c.盈利规划营业成本2402, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2402, 0) - ISNULL(c.盈利规划综合管理费2402, 0) - ISNULL(c.盈利规划税金及附加2402, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2402,

           ---按季度结转数据2403
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2403
                          ELSE c.mj2403 / 10000
                      END
                  ) 结转面积2403,
           CONVERT(DECIMAL(36, 9), c.je2403) / 100000000.0 结转金额2403,
           CONVERT(DECIMAL(36, 9), c.jenotax2403) / 100000000.0 结转金额不含税2403,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2403, 0) - ISNULL(c.盈利规划营业成本2403, 0) - ISNULL(c.盈利规划股权溢价2403, 0))
                       - ISNULL(c.盈利规划营销费用2403, 0) - ISNULL(c.盈利规划综合管理费2403, 0) - c.盈利规划税金及附加2403
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2403 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2403, 0) - ISNULL(c.盈利规划营业成本2403, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2403, 0) - ISNULL(c.盈利规划综合管理费2403, 0) - ISNULL(c.盈利规划税金及附加2403, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2403,

           ---按季度结转数据2404
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2404
                          ELSE c.mj2404 / 10000
                      END
                  ) 结转面积2404,
           CONVERT(DECIMAL(36, 9), c.je2404) / 100000000.0 结转金额2404,
           CONVERT(DECIMAL(36, 9), c.jenotax2404) / 100000000.0 结转金额不含税2404,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2404, 0) - ISNULL(c.盈利规划营业成本2404, 0) - ISNULL(c.盈利规划股权溢价2404, 0))
                       - ISNULL(c.盈利规划营销费用2404, 0) - ISNULL(c.盈利规划综合管理费2404, 0) - c.盈利规划税金及附加2404
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2404 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2404, 0) - ISNULL(c.盈利规划营业成本2404, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2404, 0) - ISNULL(c.盈利规划综合管理费2404, 0) - ISNULL(c.盈利规划税金及附加2404, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2404,


           ---按季度结转数据2501
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2501
                          ELSE c.mj2501 / 10000
                      END
                  ) 结转面积2501,
           CONVERT(DECIMAL(36, 9), c.je2501) / 100000000.0 结转金额2501,
           CONVERT(DECIMAL(36, 9), c.jenotax2501) / 100000000.0 结转金额不含税2501,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2501, 0) - ISNULL(c.盈利规划营业成本2501, 0) - ISNULL(c.盈利规划股权溢价2501, 0))
                       - ISNULL(c.盈利规划营销费用2501, 0) - ISNULL(c.盈利规划综合管理费2501, 0) - c.盈利规划税金及附加2501
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2501 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2501, 0) - ISNULL(c.盈利规划营业成本2501, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2501, 0) - ISNULL(c.盈利规划综合管理费2501, 0) - ISNULL(c.盈利规划税金及附加2501, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2501,


           ---按季度结转数据2502
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2502
                          ELSE c.mj2502 / 10000
                      END
                  ) 结转面积2502,
           CONVERT(DECIMAL(36, 9), c.je2502) / 100000000.0 结转金额2502,
           CONVERT(DECIMAL(36, 9), c.jenotax2502) / 100000000.0 结转金额不含税2502,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2502, 0) - ISNULL(c.盈利规划营业成本2502, 0) - ISNULL(c.盈利规划股权溢价2502, 0))
                       - ISNULL(c.盈利规划营销费用2502, 0) - ISNULL(c.盈利规划综合管理费2502, 0) - c.盈利规划税金及附加2502
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2502 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2502, 0) - ISNULL(c.盈利规划营业成本2502, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2502, 0) - ISNULL(c.盈利规划综合管理费2502, 0) - ISNULL(c.盈利规划税金及附加2502, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2502,

           ---按季度结转数据2503
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2503
                          ELSE c.mj2503 / 10000
                      END
                  ) 结转面积2503,
           CONVERT(DECIMAL(36, 9), c.je2503) / 100000000.0 结转金额2503,
           CONVERT(DECIMAL(36, 9), c.jenotax2503) / 100000000.0 结转金额不含税2503,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2503, 0) - ISNULL(c.盈利规划营业成本2503, 0) - ISNULL(c.盈利规划股权溢价2503, 0))
                       - ISNULL(c.盈利规划营销费用2503, 0) - ISNULL(c.盈利规划综合管理费2503, 0) - c.盈利规划税金及附加2503
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2503 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2503, 0) - ISNULL(c.盈利规划营业成本2503, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2503, 0) - ISNULL(c.盈利规划综合管理费2503, 0) - ISNULL(c.盈利规划税金及附加2503, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2503,

           ---按季度结转数据2504
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2504
                          ELSE c.mj2504 / 10000
                      END
                  ) 结转面积2504,
           CONVERT(DECIMAL(36, 9), c.je2504) / 100000000.0 结转金额2504,
           CONVERT(DECIMAL(36, 9), c.jenotax2504) / 100000000.0 结转金额不含税2504,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2504, 0) - ISNULL(c.盈利规划营业成本2504, 0) - ISNULL(c.盈利规划股权溢价2504, 0))
                       - ISNULL(c.盈利规划营销费用2504, 0) - ISNULL(c.盈利规划综合管理费2504, 0) - c.盈利规划税金及附加2504
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2504 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2504, 0) - ISNULL(c.盈利规划营业成本2504, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2504, 0) - ISNULL(c.盈利规划综合管理费2504, 0) - ISNULL(c.盈利规划税金及附加2504, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2504,
          --26年数据 
          ---按季度结转数据2601
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2601
                          ELSE c.mj2601 / 10000
                      END
                  ) 结转面积2601,
           CONVERT(DECIMAL(36, 9), c.je2601) / 100000000.0 结转金额2601,
           CONVERT(DECIMAL(36, 9), c.jenotax2601) / 100000000.0 结转金额不含税2601,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2601, 0) - ISNULL(c.盈利规划营业成本2601, 0) - ISNULL(c.盈利规划股权溢价2601, 0))
                       - ISNULL(c.盈利规划营销费用2601, 0) - ISNULL(c.盈利规划综合管理费2601, 0) - c.盈利规划税金及附加2601
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2601 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2601, 0) - ISNULL(c.盈利规划营业成本2601, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2601, 0) - ISNULL(c.盈利规划综合管理费2601, 0) - ISNULL(c.盈利规划税金及附加2601, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2601,

           ---按季度结转数据2602
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2602
                          ELSE c.mj2602 / 10000
                      END
                  ) 结转面积2602,
           CONVERT(DECIMAL(36, 9), c.je2602) / 100000000.0 结转金额2602,
           CONVERT(DECIMAL(36, 9), c.jenotax2602) / 100000000.0 结转金额不含税2602,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2602, 0) - ISNULL(c.盈利规划营业成本2602, 0) - ISNULL(c.盈利规划股权溢价2602, 0))
                       - ISNULL(c.盈利规划营销费用2602, 0) - ISNULL(c.盈利规划综合管理费2602, 0) - c.盈利规划税金及附加2602
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2602 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2602, 0) - ISNULL(c.盈利规划营业成本2602, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2602, 0) - ISNULL(c.盈利规划综合管理费2602, 0) - ISNULL(c.盈利规划税金及附加2602, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2602,

           ---按季度结转数据2603
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2603
                          ELSE c.mj2603 / 10000
                      END
                  ) 结转面积2603,
           CONVERT(DECIMAL(36, 9), c.je2603) / 100000000.0 结转金额2603,
           CONVERT(DECIMAL(36, 9), c.jenotax2603) / 100000000.0 结转金额不含税2603,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2603, 0) - ISNULL(c.盈利规划营业成本2603, 0) - ISNULL(c.盈利规划股权溢价2603, 0))
                       - ISNULL(c.盈利规划营销费用2603, 0) - ISNULL(c.盈利规划综合管理费2603, 0) - c.盈利规划税金及附加2603
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2603 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2603, 0) - ISNULL(c.盈利规划营业成本2603, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2603, 0) - ISNULL(c.盈利规划综合管理费2603, 0) - ISNULL(c.盈利规划税金及附加2603, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2603,

           ---按季度结转数据2604
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2604
                          ELSE c.mj2604 / 10000
                      END
                  ) 结转面积2604,
           CONVERT(DECIMAL(36, 9), c.je2604) / 100000000.0 结转金额2604,
           CONVERT(DECIMAL(36, 9), c.jenotax2604) / 100000000.0 结转金额不含税2604,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2604, 0) - ISNULL(c.盈利规划营业成本2604, 0) - ISNULL(c.盈利规划股权溢价2604, 0))
                       - ISNULL(c.盈利规划营销费用2604, 0) - ISNULL(c.盈利规划综合管理费2604, 0) - c.盈利规划税金及附加2604
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2604 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2604, 0) - ISNULL(c.盈利规划营业成本2604, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2604, 0) - ISNULL(c.盈利规划综合管理费2604, 0) - ISNULL(c.盈利规划税金及附加2604, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2604,   

          ---按季度结转数据2701
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2701
                          ELSE c.mj2701 / 10000
                      END
                  ) 结转面积2701,
           CONVERT(DECIMAL(36, 9), c.je2701) / 100000000.0 结转金额2701,
           CONVERT(DECIMAL(36, 9), c.jenotax2701) / 100000000.0 结转金额不含税2701,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2701, 0) - ISNULL(c.盈利规划营业成本2701, 0) - ISNULL(c.盈利规划股权溢价2701, 0))
                       - ISNULL(c.盈利规划营销费用2701, 0) - ISNULL(c.盈利规划综合管理费2701, 0) - c.盈利规划税金及附加2701
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2701 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2701, 0) - ISNULL(c.盈利规划营业成本2701, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2701, 0) - ISNULL(c.盈利规划综合管理费2701, 0) - ISNULL(c.盈利规划税金及附加2701, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2701,

           ---按季度结转数据2702
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2702
                          ELSE c.mj2702 / 10000
                      END
                  ) 结转面积2702,
           CONVERT(DECIMAL(36, 9), c.je2702) / 100000000.0 结转金额2702,
           CONVERT(DECIMAL(36, 9), c.jenotax2702) / 100000000.0 结转金额不含税2702,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2702, 0) - ISNULL(c.盈利规划营业成本2702, 0) - ISNULL(c.盈利规划股权溢价2702, 0))
                       - ISNULL(c.盈利规划营销费用2702, 0) - ISNULL(c.盈利规划综合管理费2702, 0) - c.盈利规划税金及附加2702
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2702 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2702, 0) - ISNULL(c.盈利规划营业成本2702, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2702, 0) - ISNULL(c.盈利规划综合管理费2702, 0) - ISNULL(c.盈利规划税金及附加2702, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2702,

           ---按季度结转数据2703
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2703
                          ELSE c.mj2703 / 10000
                      END
                  ) 结转面积2703,
           CONVERT(DECIMAL(36, 9), c.je2703) / 100000000.0 结转金额2703,
           CONVERT(DECIMAL(36, 9), c.jenotax2703) / 100000000.0 结转金额不含税2703,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2703, 0) - ISNULL(c.盈利规划营业成本2703, 0) - ISNULL(c.盈利规划股权溢价2703, 0))
                       - ISNULL(c.盈利规划营销费用2703, 0) - ISNULL(c.盈利规划综合管理费2703, 0) - c.盈利规划税金及附加2703
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2703 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2703, 0) - ISNULL(c.盈利规划营业成本2703, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2703, 0) - ISNULL(c.盈利规划综合管理费2703, 0) - ISNULL(c.盈利规划税金及附加2703, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2703,

           ---按季度结转数据2704
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj2704
                          ELSE c.mj2704 / 10000
                      END
                  ) 结转面积2704,
           CONVERT(DECIMAL(36, 9), c.je2704) / 100000000.0 结转金额2704,
           CONVERT(DECIMAL(36, 9), c.jenotax2704) / 100000000.0 结转金额不含税2704,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax2704, 0) - ISNULL(c.盈利规划营业成本2704, 0) - ISNULL(c.盈利规划股权溢价2704, 0))
                       - ISNULL(c.盈利规划营销费用2704, 0) - ISNULL(c.盈利规划综合管理费2704, 0) - c.盈利规划税金及附加2704
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润2704 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax2704, 0) - ISNULL(c.盈利规划营业成本2704, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用2704, 0) - ISNULL(c.盈利规划综合管理费2704, 0) - ISNULL(c.盈利规划税金及附加2704, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润2704,

             --26年结转数据 2601
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj26
                          ELSE c.mj26 / 10000
                      END
                  ) 结转面积26,
           CONVERT(DECIMAL(36, 9), c.je26) / 100000000.0 结转金额26,
           CONVERT(DECIMAL(36, 9), c.jenotax26) / 100000000.0 结转金额不含税26,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax26, 0) - ISNULL(c.盈利规划营业成本26, 0) - ISNULL(c.盈利规划股权溢价26, 0))
                       - ISNULL(c.盈利规划营销费用26, 0) - ISNULL(c.盈利规划综合管理费26, 0) - c.盈利规划税金及附加26
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润26 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax26, 0) - ISNULL(c.盈利规划营业成本26, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用26, 0) - ISNULL(c.盈利规划综合管理费26, 0) - ISNULL(c.盈利规划税金及附加26, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
             END 结转利润26,
          -- 27年结转数据 
          CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj27
                          ELSE c.mj27 / 10000
                      END
                  ) 结转面积27,
           CONVERT(DECIMAL(36, 9), c.je27) / 100000000.0 结转金额27,
           CONVERT(DECIMAL(36, 9), c.jenotax27) / 100000000.0 结转金额不含税27,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax27, 0) - ISNULL(c.盈利规划营业成本27, 0) - ISNULL(c.盈利规划股权溢价27, 0))
                       - ISNULL(c.盈利规划营销费用27, 0) - ISNULL(c.盈利规划综合管理费27, 0) - c.盈利规划税金及附加27
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润27 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax27, 0) - ISNULL(c.盈利规划营业成本27, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用27, 0) - ISNULL(c.盈利规划综合管理费27, 0) - ISNULL(c.盈利规划税金及附加27, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
            END 结转利润27,
            -- 28年及之后结转数据
            CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.mj28plus
                          ELSE c.mj28plus / 10000
                      END
                  ) 结转面积28plus,
           CONVERT(DECIMAL(36, 9), c.je28plus) / 100000000.0 结转金额28plus,
           CONVERT(DECIMAL(36, 9), c.jenotax28plus) / 100000000.0 结转金额不含税28plus,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.jenotax28plus, 0) - ISNULL(c.盈利规划营业成本28plus, 0) - ISNULL(c.盈利规划股权溢价28plus, 0))
                       - ISNULL(c.盈利规划营销费用28plus, 0) - ISNULL(c.盈利规划综合管理费28plus, 0) - c.盈利规划税金及附加28plus
                      ) / 100000000
                  )
           - CASE
                 WHEN x.项目税前利润28plus > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.jenotax28plus, 0) - ISNULL(c.盈利规划营业成本28plus, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用28plus, 0) - ISNULL(c.盈利规划综合管理费28plus, 0) - ISNULL(c.盈利规划税金及附加28plus, 0)
                                 )
                                 / 100000000 * 0.25
                             )
                 ELSE 0.0
            END 结转利润28plus
    INTO #jzlr
    FROM #p p
         LEFT JOIN erp25.dbo.vmdm_projectFlag f ON p.ProjGUID = f.ProjGUID
         INNER JOIN #cost1 c ON c.ProjGUID = p.ProjGUID
         LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_proj_expense tax ON tax.ProjGUID = p.ProjGUID
                                                                                         AND tax.IsBase = 1
         LEFT JOIN #xm1 x ON x.ProjGUID = p.ProjGUID
    ORDER BY f.平台公司,
             f.项目代码;


    SELECT   a.projguid,
             SUM(   
              ISNULL(b.结转金额不含税2401, 0) + ISNULL(b.结转金额不含税2402, 0) + ISNULL(b.结转金额不含税2403, 0) + ISNULL(b.结转金额不含税2404, 0)
              - CASE
                    WHEN a.产品类型 = '地下室/车库' THEN
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划营业成本单方 / 100000000
                    ELSE
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划营业成本单方 / 10000
                END
              - CASE
                    WHEN a.产品类型 = '地下室/车库' THEN
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划营销费用单方 / 100000000
                    ELSE
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划营销费用单方 / 10000
                END
              - CASE
                    WHEN a.产品类型 = '地下室/车库' THEN
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划综合管理费单方协议口径 / 100000000
                    ELSE
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划综合管理费单方协议口径 / 10000
                END
              - CASE
                    WHEN a.产品类型 = '地下室/车库' THEN
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划税金及附加单方 / 100000000
                    ELSE
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划税金及附加单方 / 10000
                END
              - CASE
                    WHEN a.产品类型 = '地下室/车库' THEN
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划股权溢价单方 / 100000000
                    ELSE
              (ISNULL(b.结转面积2401, 0) + ISNULL(b.结转面积2402, 0) + ISNULL(b.结转面积2403, 0) + ISNULL(b.结转面积2404, 0))
              * a.盈利规划股权溢价单方 / 10000
                END
          ) lr
INTO #xmlrhz
FROM #m002 a
     LEFT JOIN #jzlr b ON a.明源匹配主键 = b.明源匹配主键
GROUP BY a.projguid



    SELECT a.*,
           ISNULL(ISNULL(kq.kql, kq1.kql), 1) 平均款清率,
           ISNULL(b.结转面积2401, 0) 结转面积2401,
           ISNULL(b.结转金额2401, 0) 结转金额2401,
           ISNULL(b.结转金额不含税2401, 0) 结转金额不含税2401,
           ISNULL(b.结转利润2401, 0) 结转利润2401,
           ISNULL(b.结转面积2402, 0) 结转面积2402,
           ISNULL(b.结转金额2402, 0) 结转金额2402,
           ISNULL(b.结转金额不含税2402, 0) 结转金额不含税2402,
           ISNULL(b.结转利润2402, 0) 结转利润2402,
           ISNULL(b.结转面积2403, 0) 结转面积2403,
           ISNULL(b.结转金额2403, 0) 结转金额2403,
           ISNULL(b.结转金额不含税2403, 0) 结转金额不含税2403,
           ISNULL(b.结转利润2403, 0) 结转利润2403,
           ISNULL(b.结转面积2404, 0) 结转面积2404,
           ISNULL(b.结转金额2404, 0) 结转金额2404,
           ISNULL(b.结转金额不含税2404, 0) 结转金额不含税2404,
           ISNULL(b.结转利润2404, 0) 结转利润2404,


           -- 25年结转数据
           ISNULL(b.结转面积2501, 0) 结转面积2501,
           ISNULL(b.结转金额2501, 0) 结转金额2501,
           ISNULL(b.结转金额不含税2501, 0) 结转金额不含税2501,
           ISNULL(b.结转利润2501, 0) 结转利润2501,
           ISNULL(b.结转面积2502, 0) 结转面积2502,
           ISNULL(b.结转金额2502, 0) 结转金额2502,
           ISNULL(b.结转金额不含税2502, 0) 结转金额不含税2502,
           ISNULL(b.结转利润2502, 0) 结转利润2502,
           ISNULL(b.结转面积2503, 0) 结转面积2503,
           ISNULL(b.结转金额2503, 0) 结转金额2503,
           ISNULL(b.结转金额不含税2503, 0) 结转金额不含税2503,
           ISNULL(b.结转利润2503, 0) 结转利润2503,
           ISNULL(b.结转面积2504, 0) 结转面积2504,
           ISNULL(b.结转金额2504, 0) 结转金额2504,
           ISNULL(b.结转金额不含税2504, 0) 结转金额不含税2504,
           ISNULL(b.结转利润2504, 0) 结转利润2504,
           -- 26年结转数据
           ISNULL(b.结转面积2601, 0) 结转面积2601,
           ISNULL(b.结转金额2601, 0) 结转金额2601,
           ISNULL(b.结转金额不含税2601, 0) 结转金额不含税2601,
           ISNULL(b.结转利润2601, 0) 结转利润2601,
           ISNULL(b.结转面积2602, 0) 结转面积2602,
           ISNULL(b.结转金额2602, 0) 结转金额2602,
           ISNULL(b.结转金额不含税2602, 0) 结转金额不含税2602,
           ISNULL(b.结转利润2602, 0) 结转利润2602,
           ISNULL(b.结转面积2603, 0) 结转面积2603,
           ISNULL(b.结转金额2603, 0) 结转金额2603,
           ISNULL(b.结转金额不含税2603, 0) 结转金额不含税2603,
           ISNULL(b.结转利润2603, 0) 结转利润2603,
           ISNULL(b.结转面积2604, 0) 结转面积2604,
           ISNULL(b.结转金额2604, 0) 结转金额2604,
           ISNULL(b.结转金额不含税2604, 0) 结转金额不含税2604,
           ISNULL(b.结转利润2604, 0) 结转利润2604,
           -- 27年结转数据
           ISNULL(b.结转面积2701, 0) 结转面积2701,
           ISNULL(b.结转金额2701, 0) 结转金额2701,
           ISNULL(b.结转金额不含税2701, 0) 结转金额不含税2701,
           ISNULL(b.结转利润2701, 0) 结转利润2701,
           ISNULL(b.结转面积2702, 0) 结转面积2702,
           ISNULL(b.结转金额2702, 0) 结转金额2702,
           ISNULL(b.结转金额不含税2702, 0) 结转金额不含税2702,
           ISNULL(b.结转利润2702, 0) 结转利润2702,
           ISNULL(b.结转面积2703, 0) 结转面积2703,
           ISNULL(b.结转金额2703, 0) 结转金额2703,
           ISNULL(b.结转金额不含税2703, 0) 结转金额不含税2703,
           ISNULL(b.结转利润2703, 0) 结转利润2703,
           ISNULL(b.结转面积2704, 0) 结转面积2704,
           ISNULL(b.结转金额2704, 0) 结转金额2704,
           ISNULL(b.结转金额不含税2704, 0) 结转金额不含税2704,
           ISNULL(b.结转利润2704, 0) 结转利润2704,
           -- 26年结转数据
           ISNULL(b.结转面积26, 0) 结转面积26,
           ISNULL(b.结转金额26, 0) 结转金额26,
           ISNULL(b.结转金额不含税26, 0) 结转金额不含税26,
           ISNULL(b.结转利润26, 0) 结转利润26,
           -- 27年结转数据
           ISNULL(b.结转面积27, 0) 结转面积27,
           ISNULL(b.结转金额27, 0) 结转金额27,
           ISNULL(b.结转金额不含税27, 0) 结转金额不含税27,
           ISNULL(b.结转利润27, 0) 结转利润27,
           -- 28年结转数据
           ISNULL(b.结转面积28plus, 0) 结转面积28plus,
           ISNULL(b.结转金额28plus, 0) 结转金额28plus,
           ISNULL(b.结转金额不含税28plus, 0) 结转金额不含税28plus,
           ISNULL(b.结转利润28plus, 0) 结转利润28plus,

		   ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0)  当期签约结转面积,
		   ISNULL(b.结转金额2501, 0) +ISNULL(b.结转金额2502, 0) +ISNULL(b.结转金额2503, 0) +ISNULL(b.结转金额2504, 0)  当期签约结转金额,
		   ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0)  当期签约结转金额不含税,
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/10000 END 当期签约结转成本,
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划股权溢价单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划股权溢价单方/10000 END 当期签约结转溢价签约,
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/10000 END 当期签约结转营销费,
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/10000 END 当期签约结转管理费,
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/10000 END 当期签约结转税金及签约,
            ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0) -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/10000 END-
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/10000 END  当期签约结转税前利润,

        CASE WHEN  l.lr <0 THEN 0 ELSE 
        (ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0) -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/10000 END-
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/10000 END )*0.25 END 当期签约结转所得税,
        
        ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0) -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/10000 END-
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/10000 END-
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划股权溢价单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划股权溢价单方/10000 END
        -CASE WHEN  l.lr <0 THEN 0 ELSE 
        (ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0) -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/10000 END-
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/10000 END )*0.25 END 当期签约结转净利润,

        CASE WHEN   ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0) >0
        THEN ( ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0) -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营业成本单方/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划营销费用单方/10000 END-
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划综合管理费单方协议口径/10000 END -
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划税金及附加单方/10000 END-
        CASE WHEN a.产品类型='地下室/车库' THEN   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划股权溢价单方/100000000
        ELSE   (ISNULL(b.结转面积2501, 0) +ISNULL(b.结转面积2502, 0) +ISNULL(b.结转面积2503, 0) +ISNULL(b.结转面积2504, 0))* a.盈利规划股权溢价单方/10000 END )/(  ISNULL(b.结转金额不含税2501, 0) +ISNULL(b.结转金额不含税2502, 0) +ISNULL(b.结转金额不含税2503, 0) +ISNULL(b.结转金额不含税2504, 0) )
        ELSE 0 END 当期签约结转净利率,
        -- case when bdl.项目guid is null then '否' else '是' end 是否调整单方比例
        null as 是否调整单方比例
    FROM #m002 a
         LEFT JOIN #jzlr b ON a.明源匹配主键 = b.明源匹配主键
		 LEFT JOIN #xmlrhz l ON a.projguid=l.projguid
         LEFT JOIN erp25.dbo.p_project p ON a.projguid = p.projguid
         LEFT JOIN erp25.dbo.s_kq kq ON p.buguid = kq.buguid
                                        AND a.Productnocode = kq.Product
         LEFT JOIN erp25.dbo.s_kql kq1 ON p.buguid = kq1.buguid AND a.产品类型 = kq1.producttype
         -- LEFT JOIN #bdl1 bdl ON a.projguid = bdl.项目guid  and a.业态组合键 =b.业态组合键
    ORDER BY a.平台公司,
             a.项目名;


    DROP TABLE #p,
               #db,
               #room,
               #s_order,
               #s_Contract,
               #vrt,
               #ord,
               #con,
               #tmp_tax,
               #hzyj,
               #h,
               #hh,
               #s_PerformanceAppraisal,
               #t,
               #key,
               #sale,
               #ylgh,
               #cost,
               #xm,
               #m002,
               #con1,
               #s_contract1,
               #con2,
               #hzyjresult1,
               #hzyjresult,
               #h1,
               #key1,
               #sale1,
               #ylgh1,
               #cost1,
               #xm1,
               #jzlr,#xmlrhz,#tsRoomAll,
			   #tsRoomAllr,
			   #tsRoomAllrsroom
END;
GO


