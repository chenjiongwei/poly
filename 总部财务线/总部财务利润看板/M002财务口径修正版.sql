USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整]    Script Date: 2025/6/13 11:56:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER    PROC [dbo].[usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整]
(
    @var_buguid VARCHAR(MAX),
    @var_bgndate DATE = NULL,
    @var_enddate DATE = NULL,
    @Date DATETIME = NULL,
    @VersionGUID VARCHAR(40) = '',
    @IsNew INT = 0
)
AS /*
存储过程名：usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整

参数：@var_buguid  平台公司
	  @var_bgndate 开始时间
	  @var_enddate 结束时间
示例： exec [usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整] '6CBA0828-D863-4EA8-B594-DE3E11DDF573','2025-1-1','2025-05-31'

--jiangst 修改业态单方成本版本取值，若本月没填报则取上个月的

modified by lintx 20231201
1、由于很多新项目没有在盈利规划中维护，因此需要在dss中进行填报，如果有填报的话，就优先取填报值，没有的话，就取盈利规划系统

modified by lintx 20250507
1、增加了指定分期的除地价外直投变动率进行等比例缩小放大

modified by lintx 20250530
1、盈利规划单方锁定版等比例放大缩小
*/

BEGIN

    IF @VersionGUID = '默认值'
       OR @VersionGUID = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SET @VersionGUID = NULL;
    END;

    IF (ISNULL(@VersionGUID, '') <> '' AND @IsNew = 0)
    BEGIN
        SELECT [versionguid],
               [OrgGuid],
               [ProjGUID],
               [平台公司],
               [项目名],
               [推广名],
               [项目代码],
               [投管代码],
               [盈利规划上线方式],
               [产品类型],
               [产品名称],
               [装修标准],
               [商品类型],
               [明源匹配主键],
               [业态组合键],
               [当期认购面积],
               [当期认购金额],
               [当期认购金额不含税],
               [当期签约面积],
               [当期签约金额],
               [当期签约金额不含税],
               [盈利规划营业成本单方],
               [土地款_单方],
               [除地外直投_单方],
               [开发间接费单方],
               [资本化利息单方],
               [盈利规划股权溢价单方],
               [盈利规划营销费用单方],
               [盈利规划综合管理费单方协议口径],
               [盈利规划税金及附加单方],
               [盈利规划营业成本认购],
               [盈利规划股权溢价认购],
               [毛利认购],
               [毛利率认购],
               [盈利规划营销费用认购],
               [盈利规划综合管理费认购],
               [盈利规划税金及附加认购],
               [税前利润认购],
               [所得税认购],
               [净利润认购],
               [销售净利率认购],
               [盈利规划营业成本签约],
               [盈利规划股权溢价签约],
               [毛利签约],
               [毛利率签约],
               [盈利规划营销费用签约],
               [盈利规划综合管理费签约],
               [盈利规划税金及附加签约],
               [税前利润签约],
               [所得税签约],
               [净利润签约],
               [销售净利率签约],
               [当期认购套数],
               [当期签约套数],
               [当期产成品签约金额],
               [当期产成品签约金额不含税],
               [产成品净利润签约],
               [产成品销售净利率签约],
               null 是否调整单方比例
        FROM [dss].[dbo].[nmap_s_M002项目业态级毛利净利表]
        WHERE versionguid = @VersionGUID
              AND OrgGuid IN (
                                 SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                             );
    END;

    ELSE
    BEGIN

        --declare @var_buguid varchar(max)='31DCD27E-1605-EA11-80B8-0A94EF7517DD', 
        --		@var_bgndate DATE ='2022-01-01',
        --		@var_enddate DATE ='2022-10-31'

        --缓存项目
        SELECT p.ProjGUID,
               p.DevelopmentCompanyGUID,
               p.ProjCode
        INTO #p
        FROM mdm_Project p
        WHERE p.Level = 2
              AND 1 = 1
              AND p.DevelopmentCompanyGUID IN (
                                                  SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                                              );

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
			  WHERE  (s.auditstatus in ('过期审核中','已过期')
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
			  WHERE  (s.auditstatus in ('过期审核中','已过期')
			OR (s.auditstatus = '作废' and s.CancelAuditTime>='2024-01-01'))
			and s.PerformanceAppraisalGUID <> 'CDF2A700-1117-EE11-B3A3-F40270D39969'



		--如果多重对接的话，取去重的数据
		SELECT roomguid,
			   PerformanceAppraisalGUID,
			   ROW_NUMBER() OVER (PARTITION BY roomguid ORDER BY rddate DESC) num,
			   bldarea
		INTO #r
		FROM #tsRoomAll;

		--关联特殊业绩认定信息
		SELECT s.*,
			   a.RoomGUID
		INTO #sroom
		FROM #r a
			 INNER JOIN S_PerformanceAppraisal s ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
													AND (s.auditstatus IN ( '已过期', '过期审核中' ) 
					OR (s.auditstatus = '作废' and s.CancelAuditTime>='2024-01-01')
				)
		WHERE a.num = 1
			  AND s.yjtype NOT IN( '物业公司车位代销','经营类(溢价款)')

        --缓存楼栋底表
        SELECT a.ProjGUID,
               a.SaleBldGUID,
               a.ProductType,
               a.ProductName,
               a.Standard,
               a.BusinessType,
               CONVERT(VARCHAR(MAX), p.ProjCode) + '_' + ISNULL(a.ProductType, '') + '_' + ISNULL(a.ProductName, '')
               + '_' + ISNULL(a.BusinessType, '') + '_' + ISNULL(a.Standard, '') Product,
               SJjgbadate
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
               1 Ts,
               db.SJjgbadate
        INTO #room
        FROM p_room r
             INNER JOIN p_Project p ON r.ProjGUID = p.ProjGUID
             INNER JOIN p_Project p1 ON p.ParentCode = p1.ProjCode
             INNER JOIN #db db ON db.SaleBldGUID = r.BldGUID
        WHERE r.IsVirtualRoom = 0
              AND r.Status IN ( '认购', '签约' );

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
					WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate),  ISNULL(sr.SetGqAuditTime, isnull(sr.CancelAuditTime,'1900-01-01'))) > 0 THEN
						sr.rddate
					ELSE a.QSDate
				END QSDate,
               a.Status,
               a.CloseDate
        INTO #s_order
        FROM s_Order a
             INNER JOIN #room r ON r.RoomGUID = a.RoomGUID
			 LEFT JOIN #sroom sr ON sr.RoomGUID = a.RoomGUID
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
					WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate), ISNULL(sr.SetGqAuditTime, isnull(sr.CancelAuditTime,'1900-01-01'))) > 0 THEN
						sr.rddate
					ELSE a.QSDate
				END QSDate,
               a.Status
        INTO #s_Contract
        FROM dbo.s_Contract a
             INNER JOIN #room r ON r.RoomGUID = a.RoomGUID
			 LEFT JOIN #sroom sr ON sr.RoomGUID = a.RoomGUID
        WHERE a.Status = '激活'
              AND DATEDIFF(DAY, @var_bgndate, a.QSDate) >= 0
              AND DATEDIFF(DAY, a.QSDate, @var_bgndate) <= 0;

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
        FROM s_YJRLProducteDetail b
             INNER JOIN s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
             INNER JOIN #p mp ON c.ProjGUID = mp.ProjGUID
        WHERE b.Shenhe = '审核';

        SELECT a.ProjGUID,tax.rate,
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
               convert(decimal(16,2),  0.0) BqccpQymj,
               convert(decimal(16,2),  0.0) BqccpQyts,
               convert(decimal(16,2),  0.0) BqccpQyje,
               convert(decimal(16,2),  0.0) BqccpQyjeNotax
        INTO #h
        FROM #hzyj a
             LEFT JOIN s_YJRLProducteDescript b ON a.ProducteDetailGUID = b.ProducteDetailGUID
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
        SELECT a.ProjGUID,tax.rate,
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
                  ) / (1 + ISNULL(tax.rate,0)) * 10000 BqccpQyjeNotax
        INTO #hh
        FROM #hzyj a
             LEFT JOIN s_YJRLBuildingDescript bb ON a.ProducteDetailGUID = bb.ProducteDetailGUID
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
        SET a.BqccpQymj = ISNULL(b.BqccpQymj, 0),
            a.BqccpQyts = ISNULL(b.BqccpQyts, 0),
            a.BqccpQyje = ISNULL(b.BqccpQyje, 0),
            a.BqccpQyjeNotax = ISNULL(b.BqccpQyjeNotax, 0)
        FROM #h a
             INNER JOIN #hh b ON a.projguid = b.projguid
                                 AND a.Product = b.Product
								 AND a.rate = b.rate;


								  



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
              AND a.YjType IN (
                                  SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom = 1
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
               END  AS 除地外直投_单方, 
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
        FROM (
             select 
             项目guid,
             盈利规划主键,
             max(营业成本单方) as 营业成本单方,
             max(土地款单方) as 土地款单方,
			 max(除地价外直投单方) as 除地价外直投单方,
             max(开发间接费单方) as 开发间接费单方,
			 max(资本化利息单方) as 资本化利息单方,
             max(股权溢价单方) as 股权溢价单方,
			 max(营销费用单方) as 营销费用单方,
             max(综合管理费单方) as 综合管理费单方,
			 max(税金及附加单方) as 税金及附加单方 
			 from #key 
			 group by 项目guid,盈利规划主键
            ) k
             LEFT JOIN dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh ON ylgh.匹配主键 = k.盈利规划主键 AND ylgh.[项目guid] = k.项目guid
             INNER JOIN #p p ON k.项目guid = p.ProjGUID ;

            

        --指定分期做除地价外直投单方等比例缩小放大逻辑 begin--------------------------------  
        --计算项目层级的除地价外直投变动率
        -- SELECT b.项目guid,
        --        最新的动态成本,
        --        盈利规划除地价外直投含税,
        --        CASE
        --            WHEN 盈利规划除地价外直投含税 = 0 THEN
        --                 0
        --            ELSE (最新的动态成本 - 盈利规划除地价外直投含税) * 1.000000 / 盈利规划除地价外直投含税
        --        END 除地价外直投变动率
        -- INTO #bdl
        -- FROM
        -- (
        --     SELECT t.项目guid,
        --            SUM(CASE
        --                    WHEN 取数版本 = '动态成本' THEN
        --                         动态成本除地价外直投含税
        --                    ELSE 盈利规划除地价外直投含税
        --                END) 最新的动态成本,
        --            SUM(盈利规划除地价外直投含税) AS 盈利规划除地价外直投含税
        --     FROM dss.dbo.nmap_F_M002指定项目分期成本取数版本填报 t
        --     WHERE FillHistoryGUID IN
        --     (
        --         SELECT TOP 1 a.FillHistoryGUID
        --         FROM dss.dbo.nmap_F_FillHistory a
        --         WHERE FillDataGUID =
        --         (
        --             SELECT FillDataGUID
        --             FROM dss.dbo.nmap_F_FillData
        --             WHERE FillName = 'M002指定项目分期成本取数版本填报'
        --         )
        --               AND FillHistoryGUID IN
        --               (
        --                   SELECT DISTINCT FillHistoryGUID
        --                   FROM dss.dbo.nmap_F_M002指定项目分期成本取数版本填报
        --                   WHERE ISNULL(项目guid, '') <> ''
        --               )
        --         ORDER BY EndDate DESC
        --     )
        --     GROUP BY t.项目guid
        -- ) b;

       -- 判断盈利规划单方如果小于1，则不进行调整
        -- select 
        --     a.项目guid,
        --     a.业态组合键,
        --     case when isnull(b.除地外直投_单方,0) <1 then  0 else  a.除地外直投_单方 / b.除地外直投_单方  end as  除地价外直投变动率,
        --     case when isnull(b.管理费用单方,0) <1 then  0 else  a.盈利规划综合管理费单方协议口径 / b.管理费用单方  end as  管理费用变动率,
        --     case when isnull(b.营销费用单方,0) <1 then  0 else  a.盈利规划营销费用单方 / b.营销费用单方  end as  营销费用变动率,
        --     case when isnull(b.股权溢价单方,0) <1 then  0 else  a.盈利规划股权溢价单方 / b.股权溢价单方  end as  股权溢价单方变动率
        -- into #bdl
        -- from #ylgh a
        -- inner join dss.dbo.s_F066项目毛利率销售底表_盈利规划单方锁定版 b on a.项目guid = b.项目guid and a.业态组合键 = b.匹配主键



        -- UPDATE p 
        -- SET p.盈利规划营业成本单方 = p.除地外直投_单方 * (1 + 除地价外直投变动率) + 
        --                              p.土地款_单方 + 
        --                              p.开发间接费单方 + 
        --                              p.资本化利息单方, --如果是在指定项目分期的范围内，营业成本 = 除地价外直投+土地款+开发间接费+资本化利息
        --     p.除地外直投_单方 = p.除地外直投_单方 * (1 + 除地价外直投变动率), --增加指定项目的除地价外直投单方变动率
        --     p.盈利规划综合管理费单方协议口径 = p.盈利规划综合管理费单方协议口径 * (1 + 管理费用变动率), --增加指定项目的管理费用单方变动率
        --     p.盈利规划营销费用单方 = p.盈利规划营销费用单方 * (1 + 营销费用变动率), --增加指定项目的营销费用单方变动率
        --     p.盈利规划股权溢价单方 = p.盈利规划股权溢价单方 * (1 + 股权溢价单方变动率) --增加指定项目的股权溢价单方变动率
        -- FROM #ylgh p
        -- INNER JOIN #bdl b ON b.项目guid = p.项目guid and b.业态组合键 = p.业态组合键

        --指定分期做除地价外直投单方等比例缩小放大逻辑 end----------------------------------   
         
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
                              )
                              / 100000000
                          )
                  ) 项目税前利润认购,
               SUM(CONVERT(
                              DECIMAL(36, 8),
                              ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价认购*/)
                               - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
                              )
                              / 100000000
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

        SELECT NEWID() versionguid,
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
                          ((ISNULL(c.bqRgjeNotax, 0) - ISNULL(c.盈利规划营业成本认购, 0)/*- c.盈利规划股权溢价认购*/)
                           - ISNULL(c.盈利规划营销费用认购, 0) - ISNULL(c.盈利规划综合管理费认购, 0) - ISNULL(c.盈利规划税金及附加认购, 0)
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
                          ((ISNULL(c.bqQyjeNotax, 0) - ISNULL(c.盈利规划营业成本签约, 0)/*- c.盈利规划股权溢价签约 */)
                           - ISNULL(c.盈利规划营销费用签约, 0) - ISNULL(c.盈利规划综合管理费签约, 0) - ISNULL(c.盈利规划税金及附加签约, 0)
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
                          ) / 100000000
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
                                       - ISNULL(c.盈利规划营销费用产成品签约, 0) - ISNULL(c.盈利规划综合管理费产成品签约, 0) - ISNULL(c.盈利规划税金及附加产成品签约, 0)
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
                      ) 产成品销售净利率签约,
               --  case when b.项目guid is null then '否' else '是' end 是否调整单方比例
               null as 是否调整单方比例
        FROM #p p
             LEFT JOIN vmdm_projectFlag f ON p.ProjGUID = f.ProjGUID
             INNER JOIN #cost c ON c.ProjGUID = p.ProjGUID
             LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_proj_expense tax ON tax.ProjGUID = p.ProjGUID
                                                                                             AND tax.IsBase = 1
             LEFT JOIN #xm x ON x.ProjGUID = p.ProjGUID
             -- EFT join #bdl b on b.项目guid = p.projguid and c.Product =b.业态组合键
        ORDER BY f.平台公司,
                 f.项目代码;

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
				   #hh,
                   #tmp_tax,
                   #db,
                   #ylgh,
                   #cost,
                   #key,
                   #xm;

    END;


END;
