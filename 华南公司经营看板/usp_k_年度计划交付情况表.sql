USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_k_年度计划交付情况表]    Script Date: 2024/12/23 15:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[usp_k_年度计划交付情况表] (
@var_buguid VARCHAR(MAX),
@bgndate DATETIME,
@enddate DATETIME)
AS /*
存储过程名：
      [usp_k_年度计划交付情况表]
  参数：
      @var_buguid       查询的公司
	  @bgndate          开始时间
	  @enddate          结束时间
  说明：
     --本存储过程示例  
     usp_k_年度计划交付情况表 '275B7A4E-4AB3-408E-A43A-1BA6AC5B0321','2022-03-01','2022-03-31'

  Create by ： mc2 2022-04-13  V 1.0

*/
BEGIN

    ---缓存项目信息
    SELECT      p1.ProjGUID ToProjguid,
                p1.ProjName ToProjname,
                p1.ProjShortName shprojname,
                p.ProjGUID,
                p.ParentCode,
                p.ProjName
      INTO      #svb_Proje
      FROM      p_Project p
      LEFT JOIN p_Project p1
        ON p.ParentCode                               = p1.ProjCode
      LEFT JOIN dbo.mdm_Project mp
        ON ISNULL(mp.ImportSaleProjGUID, mp.ProjGUID) = p1.ProjGUID
     WHERE      p.Level = 3
       AND      mp.DevelopmentCompanyGUID IN ( SELECT Value FROM [dbo].[fn_Split2](@var_buguid, ',') );

    --取合作项目的年度交付计划
    SELECT      p.ProjGUID,
                '是' AS '是否合作项目',
                a.YearJLPlanCode,
                a.RealJFCount,
                CASE
                     WHEN a.PlanKFCount = 0 THEN ISNULL(a.PlanKFCountHand, 0)
                     ELSE a.PlanKFCount END AS PLankfcount
      INTO      #hzxm
      FROM      k_HZXMJFLR a
     INNER JOIN #svb_Proje p
        ON a.ProjGUID          = p.ProjGUID
      LEFT JOIN k_DeliveryBatch C
        ON a.DeliveryBatchGUID = C.DeliveryBatchGUID;
    --	where a.YearJLPlanCode='202012081429'


    --取非合作项目年度交付计划
    SELECT      p.ProjGUID,
                '否' AS '是否合作项目',
                a.YearJLPlanCode,
                (   SELECT COUNT(1)
                      FROM vp_ContractQDByRoom
                     WHERE QRSDate IS NOT NULL
                       AND DeliveryBatch = C.DeliveryBatchName) RealJFCount,
                CASE
                     WHEN a.PlanKFCount = 0 THEN ISNULL(a.PlanKFCountHand, 0)
                     ELSE a.PlanKFCount END AS PLankfcount
      INTO      #fhzxm
      FROM      s_YearJLPlan a
     INNER JOIN #svb_Proje p
        ON a.ProjGUID          = p.ProjGUID
      LEFT JOIN k_DeliveryBatch C
        ON a.DeliveryBatchGUID = C.DeliveryBatchGUID
     WHERE      a.YearJLPlanCode NOT IN ( SELECT hzxm.YearJLPlanCode FROM #hzxm hzxm );

    --取出所有的年度交付计划
    SELECT a.*
      INTO #NDJH
      FROM (   SELECT ProjGUID,
                      是否合作项目,
                      YearJLPlanCode,
                      RealJFCount,
                      PLankfcount
                 FROM #hzxm
               UNION ALL
               SELECT *
                 FROM #fhzxm) a;
    --	where YearJLPlanCode='202012081429'

	--取年度交付计划的不同房间（不知道为啥这表里有重复房间GUID）
	SELECT DISTINCT a.YearJLPlanGUID,a.Roomguid INTO #planroom FROM s_YearJLPlanRoom a
	inner JOIN s_YearJLPlan b ON a.YearJLPlanGUID=b.YearJLPlanGUID
	INNER JOIN #svb_Proje c ON b.ProjGUID=c.ProjGUID

    --缓存款清合同的最后一笔款缴费日期
    SELECT *
      INTO #LAST
      FROM (   SELECT      ROW_NUMBER() OVER (PARTITION BY c.ContractGUID
                                                  ORDER BY s.CreatedOn DESC,
                                                           g.GetDate DESC) AS id,
                           c.ContractGUID,
                           r.RoomGUID,
                           g.GetDate
                 FROM      #planroom a
                INNER JOIN s_YearJLPlan yjl
                   ON a.YearJLPlanGUID    = yjl.YearJLPlanGUID
                INNER JOIN dbo.ep_room r
                   ON a.RoomGUID          = r.RoomGUID
                INNER JOIN k_DeliveryBatch k
                   ON r.ProjGUID          = k.ProjGUID
                  AND k.DeliveryBatchName = REPLACE(r.DeliveryBatch, '?', '·')
                 LEFT JOIN s_Contract c
                   ON r.RoomGUID          = c.RoomGUID
                  AND c.Status            = '激活'
                 LEFT JOIN dbo.s_Getin g
                   ON g.SaleGUID          = c.TradeGUID
                 LEFT JOIN dbo.s_Voucher s
                   ON g.VouchGUID         = s.VouchGUID
                WHERE      1      = 1
                  AND      s.YwType NOT IN ( '诚意金转定金', '换房转账' )
                  AND      s.VouchType <> '换票单'
                  AND      r.Status    = '签约'
                  AND      r.RoomGUID IN (   SELECT RoomGUID
                                               FROM dbo.s_Contract tr
                                              WHERE tr.Status = '激活'
                                                AND NOT EXISTS (   SELECT 1
                                                                     FROM s_Fee fe
                                                                    WHERE tr.TradeGUID     = fe.TradeGUID
                                                                     -- AND (   (   ItemType IN ( '非贷款类房款', '贷款类房款' )
                                                                     --       AND   ItemName <> '房款补差款')
                                                                     --    OR   (   ItemType   = '其它'
                                                                     --       AND   ItemName   = '滞纳金'))
                                                                      AND RmbYe            > 0))
                  -- and a.YearJLPlanGUID='d4cd7648-1d39-eb11-b398-f40270d39969'
                  AND      ISNULL(k.DeliveryBatchDate, '') BETWEEN @bgndate AND @enddate
				  AND  ISNULL(r.DeliveryBatch,'') <> '') s
     WHERE s.id = 1;
    --非合作项目住宅应交和实交套数
    SELECT      k.DeliveryBatchGUID,
                SUM(CASE
                         WHEN DATEDIFF(DAY, k.DeliveryBatchDate, l.GetDate) < 30 THEN 1
                         ELSE 0 END) 住宅一个月应交套数,
                SUM(CASE
                         WHEN DATEDIFF(DAY, k.DeliveryBatchDate, l.GetDate) < 30
                          AND r.BlRhDate IS NOT NULL
                          AND DATEDIFF(DAY, c.JFDate, r.BlRhDate) <= 30 THEN 1
                         ELSE 0 END) 住宅一个月交付数,
                SUM(CASE
                         WHEN l.GetDate < GETDATE() THEN 1
                         ELSE 0 END) 住宅类累计应交套数,
                SUM(CASE
                         WHEN l.GetDate < GETDATE()
                          AND r.BlRhDate IS NOT NULL THEN 1
                         ELSE 0 END) 住宅类累计实际交付
      INTO      #Onemonth
      FROM      #planroom a
     INNER JOIN dbo.ep_room r
        ON a.RoomGUID          = r.RoomGUID
     INNER JOIN s_YearJLPlan y
        ON a.YearJLPlanGUID    = y.YearJLPlanGUID
     INNER JOIN k_DeliveryBatch k
        ON r.ProjGUID          = k.ProjGUID
       AND k.DeliveryBatchName = REPLACE(r.DeliveryBatch, '?', '·')
      LEFT JOIN #LAST l
        ON a.RoomGUID          = l.RoomGUID
      LEFT JOIN s_Contract c
        ON a.RoomGUID          = c.RoomGUID
       AND c.Status            = '激活'
     WHERE      y.ProductType = '住宅类（住宅、高层住宅、高级住宅）'
       AND      ISNULL(k.DeliveryBatchDate, '') BETWEEN @bgndate AND @enddate
     --and a.YearJLPlanGUID='d4cd7648-1d39-eb11-b398-f40270d39969'
	 AND  ISNULL(r.DeliveryBatch,'') <> ''
     GROUP BY k.DeliveryBatchGUID;


    --汇总查询其他数据
    SELECT      CASE
                     WHEN bu.BUName IN ( '包头公司', '北京公司' ) THEN '北京公司'
                     WHEN bu.BUName IN ( '福州公司', '福建公司' ) THEN '福建公司'
                     WHEN bu.BUName IN ( '漳州公司', '海西公司' ) THEN '海西公司'
                     WHEN bu.BUName IN ( '济南公司', '京津翼公司' ) THEN '京津翼公司'
                     WHEN bu.BUName IN ( '丹东公司', '通化公司', '营口公司', '沈阳公司' ) THEN '辽宁公司'
                     WHEN bu.BUName IN ( '贵阳', '四川公司' ) THEN '四川公司'
                     WHEN bu.BUName IN ( '南昌公司' ) THEN '江西公司'
                     ELSE bu.BUName END AS '平台公司',
                city.ParamValue 城市,
                p.shprojname 项目简称,
                p.ToProjname 项目名称,
                LB.LbProjectValue 投管代码,
                a.ProjName 分期名称,
                jh.是否合作项目 是否合作项目,
                a.YearJLPlanCode 年度交付计划编号,
                C.DeliveryBatchName 实际交付批次名称,
                C.DeliveryBatchDate 实际交付时间时间,
                ISNULL(a.ProductType, '') 产品类型,
                jh.PLankfcount 计划交付户数,
                jh.RealJFCount 实际交付户数,
                CASE
                     WHEN jh.PLankfcount = 0 THEN 0
                     ELSE (jh.RealJFCount * 1.0 / jh.PLankfcount) END AS '实际交付率',
                one.住宅一个月应交套数 住宅一个月应交套数,
                one.住宅一个月交付数 住宅一个月交付数,
                CASE
                     WHEN one.住宅一个月应交套数 = 0 THEN 0
                     ELSE (one.住宅一个月交付数 * 1.0 / one.住宅一个月应交套数) END AS '住宅类一个月交付率',
                one.住宅类累计应交套数 住宅类累计应交套数,
                one.住宅类累计实际交付 住宅类累计实际交付,
                CASE
                     WHEN one.住宅类累计应交套数 = 0 THEN 0
                     ELSE (one.住宅类累计实际交付 * 1.0 / one.住宅类累计应交套数) END AS '住宅类实际交付率',
                p.ProjGUID
      FROM      s_YearJLPlan a
      INNER JOIN #NDJH jh
        ON a.YearJLPlanCode    = jh.YearJLPlanCode
      LEFT JOIN k_DeliveryBatch C
        ON a.DeliveryBatchGUID = C.DeliveryBatchGUID
      LEFT JOIN #Onemonth one
        ON C.DeliveryBatchGUID = one.DeliveryBatchGUID
      LEFT JOIN dbo.myBusinessUnit bu
        ON bu.BUGUID           = a.BUGUID
     INNER JOIN #svb_Proje p
        ON p.ProjGUID          = a.ProjGUID
      LEFT JOIN dbo.mdm_Project mp
        ON p.ToProjguid        = mp.ProjGUID
      LEFT JOIN dbo.myBizParamOption city
        ON city.ParamGUID      = mp.CityGUID
       AND city.ParamName      = 'td_city'
      LEFT JOIN dbo.mdm_LbProject LB
        ON mp.ProjGUID         = LB.projGUID
       AND LB.LbProject        = 'tgid'
     WHERE      1 = 1
       AND      ISNULL(C.DeliveryBatchDate, '') BETWEEN @bgndate AND @enddate
     -- and a.YearJLPlanGUID='d4cd7648-1d39-eb11-b398-f40270d39969'
     ORDER BY CASE
                   WHEN bu.BUName IN ( '包头公司', '北京公司' ) THEN '北京公司'
                   WHEN bu.BUName IN ( '福州公司', '福建公司' ) THEN '福建公司'
                   WHEN bu.BUName IN ( '漳州公司', '海西公司' ) THEN '海西公司'
                   WHEN bu.BUName IN ( '济南公司', '京津翼公司' ) THEN '京津翼公司'
                   WHEN bu.BUName IN ( '丹东公司', '通化公司', '营口公司', '沈阳公司' ) THEN '辽宁公司'
                   WHEN bu.BUName IN ( '贵阳', '四川公司' ) THEN '四川公司'
                   WHEN bu.BUName IN ( '南昌公司' ) THEN '江西公司'
                   ELSE bu.BUName END,
              city.ParamValue,
              mp.ProjName,
              a.ProjName,
              a.YearJLPlanCode;

    DROP TABLE #fhzxm;
    DROP TABLE #hzxm;
    DROP TABLE #NDJH;
    DROP TABLE #svb_Proje;
    DROP TABLE #LAST;
    DROP TABLE #Onemonth;
	DROP TABLE #planroom;

END;