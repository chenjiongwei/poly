USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_00fangjianmaolilv]    Script Date: 2025/3/13 15:06:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_s_00fangjianmaolilv]
(
    @var_buguid VARCHAR(MAX),
    @datetime DATETIME
)
AS /*
存储过程名：
      usp_s_00fangjianmaolilv
  功能：
     --房间毛利率
	  
  参数：
      @var_buguid       查询的公司 
	  @var_bgndate		起始时间 
  说明：
     --本存储过程示例  
     usp_s_00fangjianmaolilv '512381FE-A9CB-E511-80B8-E41F13C51836','2023-11-29' 
         
*/
BEGIN
    SET NOCOUNT ON;


    --缓存项目
    SELECT p.ProjGUID,
           p.DevelopmentCompanyGUID,
           p.ProjCode
    INTO #p
    FROM mdm_Project p
        -- LEFT JOIN p_project p1 ON p.projguid = p1.projguid
    WHERE p.Level = 2
          AND 1 = 1
          AND p.DevelopmentCompanyGUID IN (
                               SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                           );
    --and p.ProjCode='0571032'
    --AND p.DevelopmentCompanyGUID IN (
    --                                    SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
    --                                );
    --and p.ProjGUID='841AD0CB-B9D9-E711-80BA-E61F13C57837'


    --缓存楼栋底表
    SELECT a.ProjGUID,
           a.SaleBldGUID,
           a.ProductType,
           a.ProductName,
           a.Standard,
           a.BusinessType,
           CONVERT(VARCHAR(MAX), p.ProjCode) + '_' + a.ProductType + '_' + a.ProductName + '_' + a.BusinessType + '_'
           + a.Standard Product
    INTO #db
    FROM p_lddbamj a
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
           1 Ts
    INTO #room
    FROM p_room r
         INNER JOIN p_Project p ON r.ProjGUID = p.ProjGUID
         INNER JOIN p_Project p1 ON p.ParentCode = p1.ProjCode
         INNER JOIN #db db ON db.SaleBldGUID = r.BldGUID
    WHERE r.IsVirtualRoom = 0
          AND r.Status IN ( '认购', '签约' );

    --缓存认购
    SELECT a.ProjGUID,
           r.bldguid,
           a.OrderGUID,
           a.TradeGUID,
           a.OrderType,
           a.BldArea,
           1 TS,
           a.JyTotal,
           a.RoomGUID,
           a.CloseReason,
           a.QSDate,
           a.Status,
           a.CloseDate
    INTO #s_order
    FROM s_Order a
         INNER JOIN #room r ON r.RoomGUID = a.RoomGUID
    WHERE (
              a.Status = '激活'
              OR a.CloseReason = '转签约'
          )
		  AND CreatedOn >=CAST(CONVERT(VARCHAR(100), DATEADD(DAY, -1, @datetime), 23) + ' 20:50:00' AS DATETIME)
		  AND CreatedOn< CAST(CONVERT(VARCHAR(100), @datetime, 23) + ' 20:50:00' AS DATETIME)
          --AND DATEDIFF(DAY, a.QSDate, @datetime) = 0;
    --AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0;

    --缓存签约
    SELECT a.ProjGUID,
           r.bldguid,
           a.ContractGUID,
           a.TradeGUID,
           a.BldArea,
           1 TS,
           a.JyTotal,
           a.RoomGUID,
           a.CloseReason,
           a.QSDate,
           a.Status
    INTO #s_Contract
    FROM dbo.s_Contract a
         INNER JOIN #room r ON r.RoomGUID = a.RoomGUID
    WHERE a.Status = '激活'
		  AND CreatedOn >=CAST(CONVERT(VARCHAR(100), DATEADD(DAY, -1, @datetime), 23) + ' 20:50:00' AS DATETIME)
		  AND CreatedOn< CAST(CONVERT(VARCHAR(100), @datetime, 23) + ' 20:50:00' AS DATETIME)
          --AND DATEDIFF(DAY, a.QSDate, @datetime) = 0;
    --AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0;

    --税率
    SELECT DISTINCT
           vt.ProjGUID,
           VATRate,
           RoomGUID
    INTO #vrt
    FROM s_VATSet vt
         INNER JOIN #room r ON vt.ProjGUID = r.fqprojguid
    WHERE VATScope = '整个项目'
          AND AuditState = 1
          AND RoomGUID NOT IN (
                                  SELECT DISTINCT
                                         vtr.RoomGUID
                                  FROM s_VATSet vt ---------  
                                       INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
                                       INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
                                  WHERE VATScope = '特定房间'
                                        AND AuditState = 1
                              )
    UNION ALL
    SELECT DISTINCT
           vt.ProjGUID,
           vt.VATRate,
           vtr.RoomGUID
    FROM s_VATSet vt ---------  
         INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
         INNER JOIN #room r ON vtr.RoomGUID = r.RoomGUID
    WHERE VATScope = '特定房间'
          AND AuditState = 1;


    --认购
    SELECT r.ProjGUID,
           '认购' yjtype,
           r.bldguid,
           r.roomguid,
           r.ProductType,
           r.ProductName,
           r.Standard,
           r.BusinessType,
           r.Product,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           r.BldArea
                      ELSE 0
                  END
              ) AS bqrgmj,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           r.Ts
                      ELSE 0
                  END
              ) AS bqrgts,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           a.JyTotal
                      ELSE 0
                  END
              ) AS BqrgJe,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           a.JyTotal / (1 + ISNULL(VATRate, 0) / 100)
                      ELSE 0
                  END
              ) AS bqrgjeNotax
    INTO #ord
    FROM #s_order a
         INNER JOIN #room r ON a.RoomGUID = r.RoomGUID
         LEFT JOIN s_Contract e ON a.TradeGUID = e.TradeGUID
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
        FROM dbo.S_PerformanceAppraisalRoom sr
             INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                        AND s.AuditStatus = '已审核'
                                                        AND s.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' )
        WHERE r.RoomGUID = sr.RoomGUID
    )
          AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.S_PerformanceAppraisalBuildings sr
             INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                        AND s.AuditStatus = '已审核'
                                                        AND s.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' )
        WHERE r.BldGUID = sr.BldGUID
    )
    GROUP BY r.ProjGUID,
             r.bldguid,
             r.roomguid,
             r.ProductType,
             r.ProductName,
             r.Standard,
             r.BusinessType,
             r.Product;

    --签约
    SELECT r.ProjGUID,
           '签约' yjtype,
           r.bldguid,
           r.roomguid,
           r.ProductType,
           r.ProductName,
           r.Standard,
           r.BusinessType,
           r.Product,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           r.BldArea
                      ELSE 0
                  END
              ) AS bqrgmj,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           r.Ts
                      ELSE 0
                  END
              ) AS bqrgTs,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0))
                      ELSE 0
                  END
              ) AS BqRgJe,
           SUM(   CASE
                      WHEN d.OrderGUID IS NULL
                           AND DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)
                      ELSE 0
                  END
              ) AS bqRgjeNotax,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           r.BldArea
                      ELSE 0
                  END
              ) AS bqQymj,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                           r.Ts
                      ELSE 0
                  END
              ) AS bqQyts,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0))
                      ELSE 0
                  END
              ) AS BqQyJe,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.QSDate, @datetime) = 0 THEN
                  (a.JyTotal + ISNULL(f.amount, 0)) / (1 + ISNULL(VATRate, 0) / 100)
                      ELSE 0
                  END
              ) AS bqQyjeNotax
    INTO #con
    FROM #s_Contract a
         INNER JOIN #room r ON a.RoomGUID = r.RoomGUID
         LEFT JOIN s_Order d ON a.TradeGUID = d.TradeGUID
                                AND ISNULL(d.CloseReason, '') = '转签约'
         LEFT JOIN
         (
             SELECT f.TradeGUID,
                    SUM(Amount) amount
             FROM s_Fee f
                  INNER JOIN #s_Contract c ON f.TradeGUID = c.TradeGUID
             WHERE f.ItemName LIKE '%补差%'
             GROUP BY f.TradeGUID
         ) f ON a.TradeGUID = f.TradeGUID
         LEFT JOIN #vrt vrt ON vrt.RoomGUID = r.RoomGUID
    WHERE a.Status = '激活'
          AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.S_PerformanceAppraisalRoom sr
             INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                        AND s.AuditStatus = '已审核'
                                                        AND s.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' )
        WHERE r.RoomGUID = sr.RoomGUID
    )
          AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.S_PerformanceAppraisalBuildings sr
             INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                        AND s.AuditStatus = '已审核'
                                                        AND s.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' )
        WHERE r.BldGUID = sr.BldGUID
    )
    GROUP BY r.ProjGUID,
             r.bldguid,
             r.roomguid,
             r.ProductType,
             r.ProductName,
             r.Standard,
             r.BusinessType,
             r.Product;


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
    FROM s_YJRLProducteDetail b
         INNER JOIN s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
         INNER JOIN #p mp ON c.ProjGUID = mp.ProjGUID
    WHERE b.Shenhe = '审核'
          AND b.DateYear = YEAR(@datetime)
          AND b.DateMonth = MONTH(@datetime);


    SELECT a.ProjGUID,
           '合作业绩' yjtype,
           b.bldguid,
           b.bldguid roomguid,
           db.ProductType,
           db.ProductName,
           db.standard,
           db.BusinessType,
           db.Product Product,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.BizDate, @datetime) = 0 THEN
                           CASE
                               WHEN b.ProductType = '地下室/车库' THEN
                                    b.Taoshu
                               ELSE b.Area
                           END
                      ELSE 0
                  END
              ) Hzmj,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.BizDate, @datetime) = 0 THEN
                           b.Taoshu
                      ELSE 0
                  END
              ) HzTs,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.BizDate, @datetime) = 0 THEN
                           b.Amount
                      ELSE 0
                  END
              ) * 10000 hzje,
           SUM(   CASE
                      WHEN DATEDIFF(mm, a.BizDate, @datetime) = 0 THEN
                           b.Amount
                      ELSE 0
                  END
              ) / (1 + tax.rate) * 10000 hzjeNotax
    INTO #h
    FROM #hzyj a
         LEFT JOIN s_YJRLBuildingDescript b ON a.ProducteDetailGUID = b.ProducteDetailGUID
         LEFT JOIN #db db ON b.bldguid = db.salebldguid
         LEFT JOIN #p f ON a.ProjGUID = f.ProjGUID
         LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.BizDate, tax.bgnDate) <= 0
                                   AND DATEDIFF(DAY, a.BizDate, tax.endDate) >= 0
    WHERE b.taoshu > 0
    GROUP BY a.ProjGUID,
             tax.rate,
             b.bldguid,
             db.ProductType,
             db.ProductName,
             db.standard,
             db.BusinessType,
             db.Product;



    --特殊业绩
    SELECT a.*,
           a.TotalAmount / (1 + tax.rate) TotalAmountnotax,
           tax.rate
    INTO #s_PerformanceAppraisal
    FROM S_PerformanceAppraisal a
         INNER JOIN #p mp ON a.ManagementProjectGUID = mp.ProjGUID
         LEFT JOIN #tmp_tax tax ON DATEDIFF(DAY, a.RdDate, tax.bgnDate) <= 0
                                   AND DATEDIFF(DAY, a.RdDate, tax.endDate) >= 0;


    SELECT a.ManagementProjectGUID Projguid,
           '特殊业绩' yjtype,
           b.BldGUID,
           b.bldguid roomguid,
           db.ProductType,
           db.ProductName,
           db.Standard,
           db.BusinessType,
           db.Product,
           SUM(   CASE
                      WHEN (a.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' ))
                           AND DATEDIFF(DAY, a.RdDate, @datetime) = 0 THEN
                           CASE
                               WHEN db.ProductType = '地下室/车库' THEN
                                    b.AffirmationNumber
                               ELSE b.areatotal
                           END
                      ELSE 0
                  END
              ) TsMJ,
           SUM(   CASE
                      WHEN (a.YjType NOT IN ( '经营类(溢价款)', '物业公司车位代销' ))
                           AND DATEDIFF(DAY, a.RdDate, @datetime) = 0 THEN
                           b.AffirmationNumber
                      ELSE 0
                  END
              ) TsTs,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.RdDate, @datetime) = 0 THEN
                           b.totalamount
                      ELSE 0
                  END
              ) * 10000 TsJE,
           SUM(   CASE
                      WHEN DATEDIFF(DAY, a.RdDate, @datetime) = 0 THEN
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
             FROM dbo.S_PerformanceAppraisalBuildings
             UNION ALL
             SELECT PerformanceAppraisalGUID,
                    r.ProductBldGUID BldGUID,
                    SUM(1) AffirmationNumber,
                    SUM(a.IdentifiedArea),
                    SUM(a.AmountDetermined)
             FROM dbo.S_PerformanceAppraisalRoom a
                  LEFT JOIN MyCost_Erp352.dbo.md_Room r ON a.RoomGUID = r.RoomGUID
             GROUP BY PerformanceAppraisalGUID,
                      r.ProductBldGUID
         ) b ON a.PerformanceAppraisalGUID = b.PerformanceAppraisalGUID
         LEFT JOIN #db db ON b.BldGUID = db.SaleBldGUID
    WHERE 1 = 1
          AND a.AuditStatus = '已审核'
          AND DATEDIFF(mm, a.RdDate, @datetime) = 0 
		  AND AuditTime >=CAST(CONVERT(VARCHAR(100), DATEADD(DAY, -1, @datetime), 23) + ' 20:50:00' AS DATETIME)
		  AND AuditTime< CAST(CONVERT(VARCHAR(100), @datetime, 23) + ' 20:50:00' AS DATETIME)


          AND a.YjType IN (
                              SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom = 1
                          )
          AND a.YjType IN ( '整体销售', '其他销售', '经营类(溢价款)', '回购', '包销', '代建类' )
    GROUP BY a.ManagementProjectGUID,
             b.BldGUID,
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
           s.yjtype,
           s.bldguid,
           s.roomguid,
           db.Product MyProduct,
           db.ProductType,
           db.ProductName,
           db.Standard,
           db.BusinessType,
           ISNULL(dss.盈利规划主键, db.Product) Product,
           SUM(s.bqrgmj) bqrgmj,
           SUM(s.bqrgts) bqrgTS,
           SUM(s.BqrgJe) BqRgJe,
           SUM(s.bqrgjeNotax) bqRgjeNotax,
           SUM(s.bqqymj) bqQymj,
           SUM(s.bqqyts) bqQyTS,
           SUM(s.bqqyje) BqQyJe,
           SUM(s.bqqyjeNotax) bqQyjeNotax
    INTO #sale
    FROM
    (
        SELECT a.ProjGUID,
               a.yjtype,
               a.bldguid,
               a.roomguid,
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
               0 bqqyjeNotax
        FROM #ord a
        UNION ALL
        SELECT a.ProjGUID,
               a.yjtype,
               a.bldguid,
               a.roomguid,
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
               a.bqQyjeNotax
        FROM #con a
        UNION ALL
        SELECT a.ProjGUID,
               a.yjtype,
               a.bldguid,
               a.roomguid,
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
               a.hzjeNotax
        FROM #h a
        UNION ALL
        SELECT a.Projguid,
               a.yjtype,
               a.bldguid,
               a.roomguid,
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
               a.TsJEnotax
        FROM #t a
    ) s
    LEFT JOIN
    (
        SELECT DISTINCT
               db.ProjGUID,
               db.Product,
               db.ProductType,
               db.ProductName,
               db.Standard,
               db.BusinessType
        FROM #db db
    ) db ON db.ProjGUID = s.ProjGUID
            AND db.Product = s.Product
    LEFT JOIN
    (SELECT DISTINCT k.项目guid, k.基础数据主键, k.盈利规划主键 FROM #key k) dss ON dss.项目guid = db.ProjGUID
                                                                      AND dss.基础数据主键 = db.Product --业态匹配
    GROUP BY db.ProjGUID,
             s.yjtype,
             s.bldguid,
             s.roomguid,
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

    --计算项目成本
    SELECT a.ProjGUID,
           a.yjtype,
           a.bldguid,
           a.roomguid,
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
           SUM(ISNULL(y.盈利规划税金及附加单方, 0) * ISNULL(a.bqQymj, 0)) 盈利规划税金及附加签约
    INTO #cost
    FROM #sale a
         LEFT JOIN #ylgh y ON a.ProjGUID = y.[项目guid]
                              AND a.Product = y.业态组合键
    GROUP BY a.ProjGUID,
             a.yjtype,
             a.bldguid,
             a.roomguid,
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
                          )
                      )
              ) 项目税前利润认购,
           SUM(CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                          )
                      )
              ) 项目税前利润签约
    INTO #xm
    FROM #cost c
    GROUP BY c.ProjGUID;

    -- 项目代码（投管） 	 明源代码 	 子公司  认购面积 	 认购金额 	 认购金额（不含税) 	 营业成本 	 股权溢价 	 毛利 	 毛利率 	 营销费用 	 管理费用 	 税金及附加 	 税前利润 	 所得税 	 净利润 	 销售净利率 

    SELECT NEWID() versionguid,
           p.DevelopmentCompanyGUID OrgGuid,
           p.ProjGUID,
           f.平台公司,
           f.项目名,
           f.推广名,
           f.项目代码,
           f.投管代码,
           f.盈利规划上线方式,
           c.yjtype 业绩类型,
           c.bldguid,
           c.roomguid,
           pb.bldfullname 楼栋名称,
           ISNULL(r.roominfo, pb.bldfullname) 房间,
           c.ProductType 产品类型,
           c.ProductName 产品名称,
           c.Standard 装修标准,
           c.BusinessType 商品类型,
           c.MyProduct 明源匹配主键,
           c.Product 业态组合键,
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.bqrgmj
                          ELSE c.bqrgmj
                      END
                  ) 当期认购面积,
           CONVERT(DECIMAL(36, 8), c.BqRgJe) 当期认购金额,
           CONVERT(DECIMAL(36, 8), c.bqRgjeNotax) 当期认购金额不含税,
           CONVERT(   DECIMAL(36, 8),
                      CASE
                          WHEN c.Product LIKE '%地下室/车库%' THEN
                               c.bqQymj
                          ELSE c.bqQymj
                      END
                  ) 当期签约面积,
           CONVERT(DECIMAL(36, 8), c.BqQyJe) 当期签约金额,
           CONVERT(DECIMAL(36, 8), c.bqQyjeNotax) 当期签约金额不含税,
           c.盈利规划营业成本单方,
           c.土地款_单方,
           c.除地外直投_单方,
           c.开发间接费单方,
           c.资本化利息单方,
           c.盈利规划股权溢价单方,
           c.盈利规划营销费用单方,
           c.盈利规划综合管理费单方协议口径,
           c.盈利规划税金及附加单方,
           CONVERT(DECIMAL(36, 8), c.盈利规划营业成本认购) 盈利规划营业成本认购,
           CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价认购) 盈利规划股权溢价认购,
           CONVERT(DECIMAL(36, 8), (ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0) - ISNULL(c.盈利规划股权溢价认购, 0))) 毛利认购,
           CONVERT(
                      DECIMAL(36, 8),
                      CASE
                          WHEN ISNULL(c.bqRgjeNotax, 0) <> 0 THEN
                      (ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0) - ISNULL(c.盈利规划股权溢价认购, 0))
                      / ISNULL(c.bqRgjeNotax, 0)
                      END
                  ) 毛利率认购,
           CONVERT(DECIMAL(36, 8), c.盈利规划营销费用认购) 盈利规划营销费用认购,
           CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费认购) 盈利规划综合管理费认购,
           CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加认购) 盈利规划税金及附加认购,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/) - ISNULL(c.盈利规划营销费用认购, 0)
                       - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                      )
                  ) 税前利润认购,
           CASE
               WHEN x.项目税前利润认购 > 0 THEN
                    CONVERT(
                               DECIMAL(36, 8),
                               ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/)
                                - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                               ) * 0.25
                           )
               ELSE 0.0
           END 所得税认购,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0) - ISNULL(c.盈利规划股权溢价认购, 0))
                       - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - c.盈利规划税金及附加认购
                      )
                  )
           - CASE
                 WHEN x.项目税前利润认购 > 0 THEN
                      CONVERT(
                                 DECIMAL(36, 8),
                                 ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/)
                                  - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
                                 )
                                 * 0.25
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
           CONVERT(DECIMAL(36, 8), c.盈利规划营业成本签约) 盈利规划营业成本签约,
           CONVERT(DECIMAL(36, 8), c.盈利规划股权溢价签约) 盈利规划股权溢价签约,
           CONVERT(DECIMAL(36, 8), (ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0) - ISNULL(c.盈利规划股权溢价签约, 0))) 毛利签约,
           CONVERT(
                      DECIMAL(36, 8),
                      CASE
                          WHEN ISNULL(c.bqQyjeNotax, 0) <> 0 THEN
                      (ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0) - ISNULL(c.盈利规划股权溢价签约, 0))
                      / ISNULL(c.bqQyjeNotax, 0)
                      END
                  ) 毛利率签约,
           CONVERT(DECIMAL(36, 8), c.盈利规划营销费用签约) 盈利规划营销费用签约,
           CONVERT(DECIMAL(36, 8), c.盈利规划综合管理费签约) 盈利规划综合管理费签约,
           CONVERT(DECIMAL(36, 8), c.盈利规划税金及附加签约) 盈利规划税金及附加签约,
           CONVERT(
                      DECIMAL(36, 8),
                      ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价签约 */)
                       - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                      )
                  ) 税前利润签约,
           CASE
               WHEN x.项目税前利润签约 > 0 THEN
                    CONVERT(
                               DECIMAL(36, 8),
                               ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价签约 */)
                                - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                               ) * 0.25
                           )
               ELSE 0.0
           END 所得税签约,
           CONVERT(
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
                                  - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                                 )
                                 * 0.25
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
           c.bqQyTS 当期签约套数
    FROM #p p
         LEFT JOIN vmdm_projectFlag f ON p.ProjGUID = f.ProjGUID
         INNER JOIN #cost c ON c.ProjGUID = p.ProjGUID
         LEFT JOIN ep_room r ON c.roomguid = r.roomguid
         LEFT JOIN p_building pb ON c.bldguid = pb.bldguid
         LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_proj_expense tax ON tax.ProjGUID = p.ProjGUID
                                                                                         AND tax.IsBase = 1
         LEFT JOIN #xm x ON x.ProjGUID = p.ProjGUID
    ORDER BY f.平台公司,
             f.项目代码;

   -- 删除临时表
    DROP TABLE #p,
               #room,
               #s_order,
               #s_Contract,
               #ord,
               #con,
               #vrt,
               #s_PerformanceAppraisal,
               #hzyj,
               #t,
               #sale,
               #h,
               #tmp_tax,
               #db,
               #ylgh,
               #cost,
               #key,
               #xm;



END;
