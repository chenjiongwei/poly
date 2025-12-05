USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_S_08ZYXSQYJB_HHZTSYJ]    Script Date: 2025/12/2 14:34:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_S_08ZYXSQYJB_HHZTSYJ](@var_buguid VARCHAR(MAX) ,
                                        @var_bgndate VARCHAR(200) ,
                                        @var_enddate VARCHAR(200))
AS /*
存储过程名：
      usp_S_08ZYXSQYJB_HHZTSYJ_NEW20241211
  功能：
      销售_集团报表-品牌中心报表《08周月销售签约简报(含合作、特殊业绩)》
	  
  参数：
      @var_buguid       查询的公司 
	  @var_bgndate		起始时间
	  @var_enddate		截止时间
  说明：
     --本存储过程示例  
     usp_S_08ZYXSQYJB_HHZTSYJ_NEW20241211 '512381FE-A9CB-E511-80B8-E41F13C51836','2022-01-01','2022-09-20'
        
  Create by ： LP  2017-10-31  V 1.0
  
  --增加权益口径
  --增加特殊业绩 -by yp  当特殊业绩类型为一级开发类，不关联楼栋，增加一种产品类型是一级开发。
  --修改特殊业绩取数逻辑， 房间录入签约和特殊业绩后，只取特殊业绩 yp 2019-11-26
  --增加预认购、实际认购（预认购+ 剔除预认购的认购+合作+特殊） yp 20220920
  --特殊业绩 溢价款改为按参数 yp 20221225
*/
    BEGIN
        SET NOCOUNT ON;

        SELECT  BUGUID ,
                ThDate ,
                ProjGUID ,
                ProductType ,
                RoomGUID ,
                BldGUID ,
                BProductTypeCode ,
                BldArea
        INTO    #room
        FROM    ep_room
        WHERE   BUGUID IN(SELECT    Value FROM  [dbo].[fn_Split2](@var_buguid, ',') );

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



    --处理认购表签署日期
    SELECT a.ProjGUID,
           a.OrderGUID,
           a.TradeGUID,
           a.RoomGUID,
           a.OrderType,
       CASE
           WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate), ISNULL(b.SetGqAuditTime, isnull(b.CancelAuditTime,'1900-01-01'))) > 0 THEN
                b.rddate
           ELSE a.QSDate
       END QSDate,
           a.Status,
           a.JyTotal,
           a.CloseDate,
           a.CloseReason
    INTO #s_order_new
    FROM s_order a
         LEFT JOIN #sroom b ON a.roomguid = b.roomguid;
		 
    --处理签约表签署日期
    SELECT a.ProjGUID,
           a.ContractGUID,
           a.TradeGUID,
           a.RoomGUID,
           a.Httype,
       CASE
           WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate), ISNULL(b.SetGqAuditTime, isnull(b.CancelAuditTime,'1900-01-01'))) > 0 THEN
                b.rddate
           ELSE a.QSDate
       END QSDate,
           a.Status,
           a.JyTotal,
           a.CloseDate,
           a.CloseReason
    INTO #s_Contract_new
    FROM s_Contract a
         LEFT JOIN #sroom b ON a.roomguid = b.roomguid;

		--预认购明细
		SELECT  a.BUGUID ,
				p1.ProjGUID,
				a.RoomGUID ,
				CJAmount ,
				CJDate ,
				r.BldArea,
				r.ProductType
		INTO    #pre
		FROM    dbo.s_PreOrder a
				INNER JOIN #room r ON r.RoomGUID = a.RoomGUID
				LEFT JOIN dbo.p_Project p ON r.ProjGUID = p.ProjGUID
                LEFT JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
		WHERE   1 = 1 
		AND  a.ApproveState = '已审核'

              
        --缓存特殊业绩 为1的是溢价款 双算，2是其他 只算特殊业绩
        select b.YJMode,a.*
		into #S_PerformanceAppraisal
        from S_PerformanceAppraisal a
        inner join s_TsyjType b on a.YjType = b.TsyjTypeName
		inner join mdm_project mp on a.ManagementProjectGUID = mp.ProjGUID
		where a.AuditStatus='已审核'
		and mp.OrgCompanyGUID in (select value from dbo.fn_Split2(@var_buguid,','))

		--预认购汇总
		SELECT  CASE WHEN a.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                     WHEN a.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                     WHEN a.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                     WHEN a.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                     WHEN a.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                         '东北公司'
                     WHEN a.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                     WHEN a.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                     WHEN a.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                     WHEN a.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                     WHEN a.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                     ELSE BUName
                END buname ,
				a.ProjGUID,
				a.ProductType,
				SUM(CASE WHEN DATEDIFF(DAY, a.CJDate, @var_enddate) = 0 THEN 1 ELSE 0 END) 本日预认购套数 ,
				SUM(CASE WHEN DATEDIFF(DAY, a.CJDate, @var_enddate) = 0 THEN a.BldArea ELSE 0 END) 本日预认购面积 ,
				SUM(CASE WHEN DATEDIFF(DAY, a.CJDate, @var_enddate) = 0 THEN a.CJAmount ELSE 0 END)  本日预认购金额 ,
				SUM(CASE WHEN DATEDIFF(MONTH, a.CJDate, @var_enddate) = 0 THEN 1 ELSE 0 END) 本月预认购套数 ,
				SUM(CASE WHEN DATEDIFF(MONTH, a.CJDate, @var_enddate) = 0 THEN a.BldArea ELSE 0 END) 本月预认购面积 ,
				SUM(CASE WHEN DATEDIFF(MONTH, a.CJDate, @var_enddate) = 0 THEN a.CJAmount ELSE 0 END)  本月预认购金额 ,
				SUM(CASE WHEN DATEDIFF(YEAR, a.CJDate,@var_enddate) = 0 THEN 1 ELSE 0 END) 本年预认购套数 ,
				SUM(CASE WHEN DATEDIFF(YEAR, a.CJDate,@var_enddate) = 0 THEN a.BldArea ELSE 0 END) 本年预认购面积 ,
				SUM(CASE WHEN DATEDIFF(YEAR, a.CJDate,@var_enddate) = 0 THEN a.CJAmount ELSE 0 END)  本年预认购金额,
				SUM(1) 累计预认购套数,
				SUM(a.BldArea) 累计预认购面积 ,
				SUM(a.CJAmount)  累计预认购金额
		INTO    #yrg
		FROM    #pre a
		LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = a.BUGUID
		GROUP BY CASE WHEN a.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                 WHEN a.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                 WHEN a.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                 WHEN a.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                 WHEN a.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                 '东北公司'
                 WHEN a.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                 WHEN a.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                 WHEN a.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                 WHEN a.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                 WHEN a.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                 ELSE BUName
                 END ,
                 a.ProjGUID ,
                 a.ProductType;

        --缓存认购未签约
        SELECT  CASE WHEN r.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                     WHEN r.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                     WHEN r.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                     WHEN r.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                     WHEN r.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                         '东北公司'
                     WHEN r.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                     WHEN r.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                     WHEN r.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                     WHEN r.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                     WHEN r.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                     ELSE BUName
                END buname ,
                ISNULL(p1.ProjName, p.ProjName) projname ,
                ISNULL(p1.ProjGUID, p.ProjGUID) projguid ,
                r.ProductType ,
                COUNT(1) ts ,
                SUM(r.BldArea) mj ,
                SUM(o.JyTotal) / 10000 je
        INTO    #rgwqy
        FROM    #room r
                INNER JOIN #s_order_new o ON r.RoomGUID = o.RoomGUID AND o.Status = '激活'
                LEFT JOIN dbo.p_Project p ON r.ProjGUID = p.ProjGUID
                LEFT JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
                LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = r.BUGUID
        WHERE   NOT EXISTS (SELECT 1
                            FROM    dbo.S_PerformanceAppraisalRoom sr
                                    INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND  s.YJMode <> 1
                            WHERE   r.RoomGUID = sr.RoomGUID)
                AND   NOT EXISTS (SELECT  1
                                  FROM  dbo.S_PerformanceAppraisalBuildings sr
                                        INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND  s.YJMode <> 1
                                  WHERE   r.BldGUID = sr.BldGUID)
        GROUP BY CASE WHEN r.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                      WHEN r.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                      WHEN r.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                      WHEN r.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                      WHEN r.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                          '东北公司'
                      WHEN r.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                      WHEN r.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                      WHEN r.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                      WHEN r.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                      WHEN r.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                      ELSE buname
                 END ,
                 ISNULL(p1.ProjName, p.ProjName) ,
                 ISNULL(p1.ProjGUID, p.ProjGUID) ,
                 r.ProductType;

        ---缓存推货日期
        SELECT  CASE WHEN r.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                     WHEN r.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                     WHEN r.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                     WHEN r.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                     WHEN r.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                         '东北公司'
                     WHEN r.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                     WHEN r.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                     WHEN r.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                     WHEN r.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                     WHEN r.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                     ELSE BUName
                END buname ,
                ISNULL(p1.ProjName, p.ProjName) projname ,
                ISNULL(p1.ProjGUID, p.ProjGUID) projguid ,
                r.ProductType ,
                MIN(r.ThDate) thdate
        INTO    #th
        FROM    #room r
                LEFT JOIN dbo.p_Project p ON r.ProjGUID = p.ProjGUID
                LEFT JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
                LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = r.BUGUID
        GROUP BY CASE WHEN r.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                      WHEN r.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                      WHEN r.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                      WHEN r.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                      WHEN r.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                          '东北公司'
                      WHEN r.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                      WHEN r.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                      WHEN r.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                      WHEN r.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                      WHEN r.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                      ELSE buname
                 END ,
                 ISNULL(p1.ProjName, p.ProjName) ,
                 ISNULL(p1.ProjGUID, p.ProjGUID) ,
                 r.ProductType;


        --正常的认购签约
        SELECT  a.buname AS '公司名称' ,
                a.BUGUID ,
                a.projname AS '项目名称' ,
                a.tzprojname AS '投管项目名称' ,
                a.tzspreadname AS '投管推广名' ,
                a.TradersWay AS '操盘方式' ,
                a.BbWay AS '并表方式' ,
                a.EquityRatio AS '项目权益比例' ,
                a.ProjCode AS '项目代码' ,
                a.LbProjectValue AS '投管代码' ,
                a.bproducttypename AS '产品类型' ,
                #th.thdate AS '首推日期' ,
				a.AcquisitionDate AS '获取时间',
				a.xmfl AS '项目分类',
                ISNULL(b.bqrgts, 0) - ISNULL(bqrgtfts, 0) + ISNULL(c.bqqyts01, 0) AS '本期认购套数' ,
                ISNULL(b.bqrgmj, 0) - ISNULL(bqrgtfmj, 0) + ISNULL(c.bqqymj01, 0) AS '本期认购面积' ,
                (ISNULL(b.bqrgje, 0) - ISNULL(b.bqrgtfje, 0) + ISNULL(c.bqqyje01, 0)) * 1.00 / 10000 AS '本期认购金额' ,
                ISNULL(c.bqqyts, 0) AS '本期签约套数' ,
                ISNULL(c.bqqymj, 0) AS '本期签约面积' ,
                ISNULL((c.bqqyje) * 1.00 / 10000, 0) AS '本期签约金额' ,
                ISNULL(b.byrgts, 0) - ISNULL(b.byrgtfts, 0) + ISNULL(c.byqyts01, 0) AS '本月认购套数' ,
                ISNULL(b.bnrgts, 0) - ISNULL(b.bnrgtfts, 0) + ISNULL(c.bnqyts01, 0) AS '本年认购套数' ,
                ISNULL(b.ljrgts, 0) - ISNULL(b.ljrgtfts, 0) + ISNULL(c.ljqyts01, 0) AS '累计认购套数' ,
                ISNULL(b.byrgmj, 0) - ISNULL(b.byrgtfmj, 0) + ISNULL(c.byqymj01, 0) AS '本月认购面积' ,
                ISNULL(b.bnrgmj, 0) - ISNULL(b.bnrgtfmj, 0) + ISNULL(c.bnqymj01, 0) AS '本年认购面积' ,
                ISNULL(b.ljrgmj, 0) - ISNULL(b.ljrgtfmj, 0) + ISNULL(c.ljqymj01, 0) AS '累计认购面积' ,
                (ISNULL(b.byrgje, 0) - ISNULL(b.byrgtfje, 0) + ISNULL(c.byqyje01, 0)) * 1.00 / 10000 AS '本月认购金额' ,
                (ISNULL(b.bnrgje, 0) - ISNULL(b.bnrgtfje, 0) + ISNULL(c.bnqyje01, 0)) * 1.00 / 10000 AS '本年认购金额' ,
                (ISNULL(b.ljrgje, 0) - ISNULL(b.ljrgtfje, 0) + ISNULL(c.ljqyje01, 0)) * 1.00 / 10000 AS '累计认购金额' ,
                ISNULL(c.byqyts, 0) AS '本月签约套数' ,
                ISNULL(c.bnqyts, 0) AS '本年签约套数' ,
                ISNULL(c.ljqyts, 0) AS '累计签约套数' ,
                ISNULL(c.byqymj, 0) AS '本月签约面积' ,
                ISNULL(c.bnqymj, 0) AS '本年签约面积' ,
                ISNULL(c.ljqymj, 0) AS '累计签约面积' ,
                ISNULL((c.byqyje) * 1.00 / 10000, 0) AS '本月签约金额' ,
                ISNULL((c.bnqyje) * 1.00 / 10000, 0) AS '本年签约金额' ,
                ISNULL((c.ljqyje) * 1.00 / 10000, 0) AS '累计签约金额' ,
                ISNULL(c.bnqymj, 0) * ISNULL(a.EquityRatio, 0) / 100 AS '本年签约权益面积' ,
                ISNULL((c.bnqyje) * 1.00 / 10000, 0) * ISNULL(a.EquityRatio, 0) / 100 AS '本年签约权益金额' ,
                0 本期认购均价 ,
                0 本月认购均价 ,
                0 本年认购均价 ,
                0 累计认购均价 ,
                0 本期签约均价 ,
                0 本月签约均价 ,
                0 本年签约均价 ,
                0 累计签约均价 ,
                ISNULL(#rgwqy.ts, 0) 未签约套数 ,
                ISNULL(#rgwqy.mj, 0) 未签约面积 ,
                ISNULL(#rgwqy.je, 0) 未签约金额 ,
                isnull(yrg.本日预认购套数,0) 本日预认购套数,
                isnull(yrg.本日预认购面积,0) 本日预认购面积,
                isnull(yrg.本日预认购金额,0) * 1.00 / 10000 本日预认购金额,
                isnull(yrg.本月预认购套数,0) 本月预认购套数,
                isnull(yrg.本月预认购面积,0) 本月预认购面积,
                isnull(yrg.本月预认购金额,0) * 1.00 / 10000 本月预认购金额,
                isnull(yrg.本年预认购套数,0) 本年预认购套数,
                isnull(yrg.本年预认购面积,0) 本年预认购面积,
                isnull(yrg.本年预认购金额,0) * 1.00 / 10000 本年预认购金额,
                isnull(yrg.累计预认购套数,0) 累计预认购套数,
                isnull(yrg.累计预认购面积,0) 累计预认购面积,
                isnull(yrg.累计预认购金额,0) * 1.00 / 10000 累计预认购金额,
				isnull(yrg.本日预认购套数,0) + ISNULL(b.SjBrrgTs,0)+ isnull(c.Sjbrqyts01,0) 本日实际认购套数,
				isnull(yrg.本日预认购面积,0) + ISNULL(b.SjBrrgMj,0)+ isnull(c.SjbrqyMj01,0) 本日实际认购面积,
				(ISNULL(yrg.本日预认购金额,0) + ISNULL(b.SjBrrgJe,0)+ isnull(c.SjbrqyJe01,0)) * 1.00 / 10000 本日实际认购金额,
				isnull(yrg.本月预认购套数,0) + ISNULL(b.SjbyrgTs,0)+ isnull(c.Sjbyqyts01,0) 本月实际认购套数,
				isnull(yrg.本月预认购面积,0) + ISNULL(b.SjbyrgMj,0)+ isnull(c.SjbyqyMj01,0) 本月实际认购面积,
				(ISNULL(yrg.本月预认购金额,0) + ISNULL(b.SjbyrgJe,0)+ isnull(c.SjbyqyJe01,0)) * 1.00 / 10000 本月实际认购金额,
				isnull(yrg.本年预认购套数,0) + ISNULL(b.SjbnrgTs,0)+ isnull(c.Sjbnqyts01,0) 本年实际认购套数,
				isnull(yrg.本年预认购面积,0) + ISNULL(b.SjbnrgMj,0)+ isnull(c.SjbnqyMj01,0) 本年实际认购面积,
				(ISNULL(yrg.本年预认购金额,0) + ISNULL(b.SjbnrgJe,0)+ isnull(c.SjbnqyJe01,0)) * 1.00 / 10000 本年实际认购金额,
				isnull(yrg.累计预认购套数,0) + ISNULL(b.SjLjrgTs,0)+ isnull(c.SjLjqyts01,0) 累计实际认购套数,
				isnull(yrg.累计预认购面积,0) + ISNULL(b.SjLjrgMj,0)+ isnull(c.SjLjqyMj01,0) 累计实际认购面积,
				(ISNULL(yrg.累计预认购金额,0) + ISNULL(b.SjLjrgJe,0)+ isnull(c.SjLjqyJe01,0)) * 1.00 / 10000 累计实际认购金额
        INTO    #t
        FROM(SELECT buname ,
                    BUGUID ,
                    projguid ,
                    projname ,
                    tzprojname ,
                    t.tzspreadname ,
                    t.TradersWay ,
                    t.BbWay ,
                    t.EquityRatio ,
                    ProjCode ,
                    LbProjectValue ,
                    bproducttypename,
					AcquisitionDate,
					xmfl
             FROM   (SELECT CASE WHEN a.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                                 WHEN a.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                                 WHEN a.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                                 WHEN a.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                                 WHEN a.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F' ,
                                                   '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN '东北公司'
                                 WHEN a.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                                 WHEN a.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                                 WHEN a.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                                 WHEN a.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                                 WHEN a.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                                 ELSE BUName
                            END buname ,
                            a.BUGUID ,
                            ISNULL(p1.ProjGUID, b.ProjGUID) AS projguid ,
                            ISNULL(p1.ProjName, b.ProjName) AS projname ,
                            mp.ProjName AS tzprojname ,
                            mp.SpreadName AS tzspreadname ,
                            mp.TradersWay ,
                            mp.BbWay ,
                            mp.ProjCode ,
                            mdp.LbProjectValue ,
                            mp.EquityRatio ,
                            c.BProductTypeName AS bproducttypename,
							mp.AcquisitionDate,
							xmfl.LbProjectValue xmfl
                     FROM   #room a
                            LEFT JOIN p_Project b ON a.ProjGUID = b.ProjGUID
                            LEFT JOIN p_Project p1 ON p1.ProjCode = b.ParentCode AND b.Level = 3 AND p1.ApplySys LIKE '%0101%'
                            LEFT JOIN dbo.mdm_Project mp ON ISNULL(p1.ProjGUID, b.ProjGUID) = mp.ImportSaleProjGUID
                            LEFT JOIN mdm_LbProject mdp ON mp.ProjGUID = mdp.projGUID AND   mdp.LbProject = 'tgid'
                            LEFT JOIN mdm_LbProject xmfl ON mp.ProjGUID = xmfl.projGUID AND   xmfl.LbProject = 'xmwfl'
                            LEFT JOIN p_BuildProductType c ON a.BProductTypeCode = c.BProductTypeCode
                            LEFT JOIN myBusinessUnit ON a.BUGUID = myBusinessUnit.BUGUID
                     WHERE 1 = 1
                           AND   NOT EXISTS (SELECT     1
                                             FROM   dbo.S_PerformanceAppraisalRoom sr
                                                    INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                               AND  s.YJMode <> 1
                                             WHERE   a.RoomGUID = sr.RoomGUID)
                           AND   NOT EXISTS (SELECT     1
                                             FROM   dbo.S_PerformanceAppraisalBuildings sr
                                                    INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                               AND  s.YJMode <> 1
                                             WHERE   a.BldGUID = sr.BldGUID)) t
             GROUP BY buname ,
                      BUGUID ,
                      projguid ,
                      projname ,
                      tzprojname ,
                      t.tzspreadname ,
                      t.TradersWay ,
                      t.BbWay ,
                      t.EquityRatio ,
                      ProjCode ,
                      LbProjectValue ,
                      bproducttypename,
					  AcquisitionDate,
					  xmfl) a
            LEFT JOIN #th ON a.buname = #th.buname AND  a.projguid = #th.projguid AND   a.bproducttypename = #th.ProductType
            LEFT JOIN #rgwqy ON a.buname = #rgwqy.buname AND a.projguid = #rgwqy.projguid AND   a.bproducttypename = #rgwqy.ProductType
			LEFT JOIN #yrg yrg ON yrg.buname = a.buname AND yrg.ProjGUID = a.projguid AND yrg.ProductType = a.bproducttypename
            LEFT JOIN(SELECT    ISNULL(p2.ProjGUID, p1.ProjGUID) AS projguid ,
                                c.BProductTypeName AS bproducttypename ,
                                SUM(CASE WHEN a.QSDate BETWEEN @var_bgndate AND @var_enddate AND   a.Status = '激活' THEN 1 ELSE 0 END) AS bqrgts ,
                                SUM(CASE WHEN DATEDIFF(mm, a.QSDate, @var_enddate) = 0 AND a.Status = '激活' THEN 1 ELSE 0 END) AS byrgts ,
                                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @var_enddate) = 0 AND a.Status = '激活' THEN 1 ELSE 0 END) AS bnrgts ,
                                SUM(CASE WHEN a.Status = '激活' THEN 1 ELSE 0 END) AS ljrgts ,
                                SUM(CASE WHEN a.QSDate BETWEEN @var_bgndate AND @var_enddate AND   a.Status = '激活' THEN b.BldArea ELSE 0 END) AS bqrgmj ,
                                SUM(CASE WHEN DATEDIFF(mm, a.QSDate, @var_enddate) = 0 AND a.Status = '激活' THEN b.BldArea ELSE 0 END) AS byrgmj ,
                                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @var_enddate) = 0 AND a.Status = '激活' THEN b.BldArea ELSE 0 END) AS bnrgmj ,
                                SUM(CASE WHEN a.Status = '激活' THEN b.BldArea ELSE 0 END) AS ljrgmj ,
                                SUM(CASE WHEN a.QSDate BETWEEN @var_bgndate AND @var_enddate AND   a.Status = '激活' THEN a.JyTotal ELSE 0 END) AS bqrgje ,
                                SUM(CASE WHEN DATEDIFF(mm, a.QSDate, @var_enddate) = 0 AND a.Status = '激活' THEN a.JyTotal ELSE 0 END) AS byrgje ,
                                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @var_enddate) = 0 AND a.Status = '激活' THEN a.JyTotal ELSE 0 END) AS bnrgje ,
                                SUM(CASE WHEN a.Status = '激活' THEN a.JyTotal ELSE 0 END) AS ljrgje ,
                                SUM(CASE WHEN d.QSDate BETWEEN @var_bgndate AND @var_enddate AND   a.CloseDate BETWEEN @var_bgndate AND @var_enddate THEN 1 ELSE 0 END) AS bqrgtfts ,
                                SUM(CASE WHEN DATEDIFF(mm, d.QSDate, @var_enddate) = 0 AND DATEDIFF(mm, a.CloseDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS byrgtfts ,
                                SUM(CASE WHEN DATEDIFF(yy, d.QSDate, @var_enddate) = 0 AND DATEDIFF(yy, a.CloseDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS bnrgtfts ,
                                SUM(CASE WHEN d.ContractGUID IS NOT NULL THEN 1 ELSE 0 END) AS ljrgtfts ,
                                SUM(CASE WHEN d.QSDate BETWEEN @var_bgndate AND @var_enddate AND   a.CloseDate BETWEEN @var_bgndate AND @var_enddate THEN b.BldArea ELSE 0 END) AS bqrgtfmj ,
                                SUM(CASE WHEN DATEDIFF(mm, d.QSDate, @var_enddate) = 0 AND DATEDIFF(mm, a.CloseDate, @var_enddate) = 0 THEN b.BldArea ELSE 0 END) AS byrgtfmj ,
                                SUM(CASE WHEN DATEDIFF(yy, d.QSDate, @var_enddate) = 0 AND DATEDIFF(yy, a.CloseDate, @var_enddate) = 0 THEN b.BldArea ELSE 0 END) AS bnrgtfmj ,
                                SUM(CASE WHEN d.ContractGUID IS NOT NULL THEN b.BldArea ELSE 0 END) AS ljrgtfmj ,
                                SUM(CASE WHEN d.QSDate BETWEEN @var_bgndate AND @var_enddate AND   a.CloseDate BETWEEN @var_bgndate AND @var_enddate THEN a.JyTotal ELSE 0 END) AS bqrgtfje ,
                                SUM(CASE WHEN DATEDIFF(mm, d.QSDate, @var_enddate) = 0 AND DATEDIFF(mm, a.CloseDate, @var_enddate) = 0 THEN a.JyTotal ELSE 0 END) AS byrgtfje ,
                                SUM(CASE WHEN DATEDIFF(yy, d.QSDate, @var_enddate) = 0 AND DATEDIFF(yy, a.CloseDate, @var_enddate) = 0 THEN a.JyTotal ELSE 0 END) AS bnrgtfje ,
                                SUM(CASE WHEN d.ContractGUID IS NOT NULL THEN a.JyTotal ELSE 0 END) AS ljrgtfje,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(day,a.qsdate,@var_endDate)=0 THEN  1 ELSE 0 END) SjBrrgTs,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(day,a.qsdate,@var_endDate)=0 THEN  b.bldarea ELSE 0 END) SjBrrgMj,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(day,a.qsdate,@var_endDate)=0 THEN  A.Jytotal ELSE 0 END) SjBrrgJe,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(MONTH,a.qsdate,@var_endDate)=0  THEN  1 ELSE 0 END) SjByrgTs,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(MONTH,a.qsdate,@var_endDate)=0  THEN  b.bldarea ELSE 0 END) SjByrgMj,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(MONTH,a.qsdate,@var_endDate)=0  THEN  A.Jytotal ELSE 0 END) SjByrgJe,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(YEAR,a.qsdate,@var_endDate) =0 THEN  1 ELSE 0 END) SjBNrgTs,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(YEAR,a.qsdate,@var_endDate) =0 THEN  b.bldarea ELSE 0 END) SjBNrgMj,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' and datediff(YEAR,a.qsdate,@var_endDate) =0 THEN  A.Jytotal ELSE 0 END) SjBNrgJe,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' THEN  1 ELSE 0 END) SjLjrgTs,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' THEN  b.bldarea ELSE 0 END) SjLjrgMj,
								SUM(CASE WHEN pre.RoomGUID IS NULL and a.status='激活' THEN  A.Jytotal ELSE 0 END) SjLjrgJe
                      FROM  #s_order_new a
                            INNER JOIN #room b ON a.RoomGUID = b.RoomGUID
                            LEFT JOIN p_BuildProductType c ON b.BProductTypeCode = c.BProductTypeCode
                            LEFT JOIN #s_Contract_new d ON a.TradeGUID = d.TradeGUID AND d.CloseReason = '退房'
                            LEFT JOIN #s_Contract_new e ON a.TradeGUID = e.TradeGUID AND e.CloseReason NOT IN ('变更价格', '重置认购')
                            LEFT JOIN p_Project p1 ON a.ProjGUID = p1.ProjGUID
                            LEFT JOIN p_Project p2 ON p2.ProjCode = p1.ParentCode AND   p1.Level = 3
							LEFT JOIN #pre pre ON pre.RoomGUID = a.RoomGUID
                      WHERE a.OrderType = '认购' AND  (a.Status = '激活' OR (a.Status = '关闭' AND a.CloseReason = '转签约' AND  e.CloseReason NOT IN ('作废', '换房', '挞定', '折扣变更'))) AND   d.TradeGUID IS NULL
                            AND NOT EXISTS (SELECT  1
                                            FROM    dbo.S_PerformanceAppraisalRoom sr
                                                    INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '已审核'
                                                                                               AND  s.YJMode <> 1
                                            WHERE   b.RoomGUID = sr.RoomGUID)
                            AND   NOT EXISTS (SELECT  1
                                              FROM  dbo.S_PerformanceAppraisalBuildings sr
                                                    INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID AND s.AuditStatus = '已审核'
                                                                                               AND  s.YJMode <> 1
                                              WHERE   b.BldGUID = sr.BldGUID)
                      GROUP BY ISNULL(p2.ProjGUID, p1.ProjGUID) ,
                               c.BProductTypeName) b ON a.projguid = b.projguid AND ISNULL(a.bproducttypename, '') = ISNULL(b.bproducttypename, '')
            LEFT JOIN(
                       SELECT    ISNULL(p2.ProjGUID, p1.ProjGUID) AS projguid ,
                                c.BProductTypeName AS bproducttypename ,
                                SUM(CASE WHEN (a.QSDate BETWEEN @var_bgndate AND @var_enddate) THEN 1 ELSE 0 END) AS bqqyts ,
                                SUM(CASE WHEN (d.QSDate BETWEEN @var_bgndate AND @var_enddate) THEN 1 ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND  (a.QSDate BETWEEN @var_bgndate AND @var_enddate) THEN 1 ELSE 0 END) AS bqqyts01 ,
                                SUM(CASE WHEN DATEDIFF(mm, a.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS byqyts ,
                                SUM(CASE WHEN DATEDIFF(mm, d.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND  DATEDIFF(mm, a.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS byqyts01 ,
                                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS bnqyts ,
                                SUM(CASE WHEN DATEDIFF(yy, d.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND  DATEDIFF(yy, a.QSDate, @var_enddate) = 0 AND a.QSDate <= @var_enddate THEN 1 ELSE 0 END) AS bnqyts01 ,
                                COUNT(1) AS ljqyts ,
                                COUNT(1) AS ljqyts01 ,
                                SUM(CASE WHEN a.QSDate BETWEEN @var_bgndate AND @var_enddate THEN b.BldArea ELSE 0 END) AS bqqymj ,
                                SUM(CASE WHEN (d.QSDate BETWEEN @var_bgndate AND @var_enddate) THEN b.BldArea ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND  (a.QSDate BETWEEN @var_bgndate AND @var_enddate) THEN b.BldArea ELSE 0 END) AS bqqymj01 ,
                                SUM(CASE WHEN DATEDIFF(mm, a.QSDate, @var_enddate) = 0 THEN b.BldArea ELSE 0 END) AS byqymj ,
                                SUM(CASE WHEN DATEDIFF(mm, d.QSDate, @var_enddate) = 0 THEN b.BldArea ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND  DATEDIFF(mm, a.QSDate, @var_enddate) = 0 THEN b.BldArea ELSE 0 END) AS byqymj01 ,
                                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @var_enddate) = 0 THEN b.BldArea ELSE 0 END) AS bnqymj ,
                                SUM(CASE WHEN DATEDIFF(yy, d.QSDate, @var_enddate) = 0 THEN b.BldArea ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND  DATEDIFF(yy, a.QSDate, @var_enddate) = 0 AND a.QSDate <= @var_enddate THEN b.BldArea ELSE 0 END) AS bnqymj01 ,
                                SUM(b.BldArea) AS ljqymj ,
                                SUM(b.BldArea) AS ljqymj01 ,
                                SUM(CASE WHEN a.QSDate BETWEEN @var_bgndate AND @var_enddate THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END) AS bqqyje ,
                                SUM(CASE WHEN (d.QSDate BETWEEN @var_bgndate AND @var_enddate) THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND (a.QSDate BETWEEN @var_bgndate AND @var_enddate) THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END) AS bqqyje01 ,
                                SUM(CASE WHEN DATEDIFF(mm, a.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END) AS byqyje ,
                                SUM(CASE WHEN DATEDIFF(mm, d.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND DATEDIFF(mm, a.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END) AS byqyje01 ,
                                SUM(CASE WHEN DATEDIFF(yy, a.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END) AS bnqyje ,
                                SUM(CASE WHEN DATEDIFF(yy, d.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END)
                                + SUM(CASE WHEN d.OrderGUID IS NULL AND DATEDIFF(yy, a.QSDate, @var_enddate) = 0 AND a.QSDate <= @var_enddate THEN a.JyTotal + ISNULL(f.amount, 0)ELSE 0 END) AS bnqyje01 ,
                                SUM(a.JyTotal + ISNULL(f.amount, 0)) AS ljqyje ,
                                SUM(a.JyTotal + ISNULL(f.amount, 0)) AS ljqyje01,

								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(day, d.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(DAY, a.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS Sjbrqyts01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(day, d.QSDate, @var_enddate) = 0 THEN b.bldarea ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(DAY, a.QSDate, @var_enddate) = 0 THEN b.bldarea ELSE 0 END) AS SjbrqyMj01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(day, d.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(DAY, a.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) AS SjbrqyJe01 ,

								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(MONTH, d.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(MONTH, a.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS Sjbyqyts01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(MONTH, d.QSDate, @var_enddate) = 0 THEN b.bldarea ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(MONTH, a.QSDate, @var_enddate) = 0 THEN b.bldarea ELSE 0 END) AS SjbyqyMj01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(MONTH, d.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(MONTH, a.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) AS SjbyqyJe01 ,

								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(year, d.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(year, a.QSDate, @var_enddate) = 0 THEN 1 ELSE 0 END) AS Sjbnqyts01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(year, d.QSDate, @var_enddate) = 0 THEN b.bldarea ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(year, a.QSDate, @var_enddate) = 0 THEN b.bldarea ELSE 0 END) AS SjbnqyMj01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL and DATEDIFF(year, d.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END)
                                + SUM(CASE WHEN pre.RoomGUID IS NULL AND d.OrderGUID IS NULL AND  DATEDIFF(year, a.QSDate, @var_enddate) = 0 THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) AS SjbnqyJe01 ,

								SUM(CASE WHEN pre.RoomGUID IS NULL THEN 1 ELSE 0 END) AS Sjljqyts01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL THEN b.bldarea ELSE 0 END) AS SjljqyMj01 ,
								SUM(CASE WHEN pre.RoomGUID IS NULL THEN a.JyTotal + ISNULL(f.amount, 0) ELSE 0 END) AS SjljqyJe01
                      FROM  #s_Contract_new a
                            INNER JOIN #room b ON a.RoomGUID = b.RoomGUID
                            LEFT JOIN(SELECT    TradeGUID ,
                                                SUM(Amount) amount
                                      FROM  s_Fee f
                                      WHERE ItemName LIKE '%补差%'
                                      GROUP BY TradeGUID) f ON a.TradeGUID = f.TradeGUID
                            LEFT JOIN p_BuildProductType c ON b.BProductTypeCode = c.BProductTypeCode
                            LEFT JOIN #s_order_new d ON a.TradeGUID = d.TradeGUID AND ISNULL(d.CloseReason, '') = '转签约'
							LEFT JOIN #pre pre ON pre.RoomGUID = a.RoomGUID
                            LEFT JOIN p_Project p1 ON a.ProjGUID = p1.ProjGUID
                            LEFT JOIN p_Project p2 ON p2.ProjCode = p1.ParentCode AND   p1.Level = 3
                      WHERE a.Status = '激活'
                            AND NOT EXISTS (SELECT  1
                                            FROM    dbo.S_PerformanceAppraisalRoom sr
                                                    INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                               AND  s.YJMode <> 1
                                            WHERE   b.RoomGUID = sr.RoomGUID)
                            AND   NOT EXISTS (SELECT  1
                                              FROM  dbo.S_PerformanceAppraisalBuildings sr
                                                    INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                               AND  s.YJMode <> 1
                                              WHERE   b.BldGUID = sr.BldGUID)
                      GROUP BY ISNULL(p2.ProjGUID, p1.ProjGUID) ,
                               c.BProductTypeName) c ON a.projguid = c.projguid AND ISNULL(a.bproducttypename, '') = ISNULL(c.bproducttypename, '')
        WHERE(1 = 1)
        ORDER BY a.buname ,
                 a.projname;

        SELECT  CONVERT(DATETIME, b.DateYear + '-' + b.DateMonth + '-27') AS [BizDate] ,
                b.*
        INTO    #hzyj
        FROM    s_YJRLProducteDetail b
                INNER JOIN s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
        WHERE   c.BUGuid IN(SELECT  Value FROM  [dbo].[fn_Split2](@var_buguid, ',') );

        SELECT  CASE WHEN m.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                     WHEN m.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                     WHEN m.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                     WHEN m.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                     WHEN m.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                         '东北公司'
                     WHEN m.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                     WHEN m.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                     WHEN m.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                     WHEN m.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                     WHEN m.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                     ELSE m.BUName
                END BUName ,
                m.BUGUID ,
                ISNULL(p1.ProjName, p.ProjName) ProjName ,
                p.ProjName tzprojname ,
                p.SpreadName tzspreadname ,
                p.TradersWay ,
                p.BbWay ,
                p.EquityRatio ,
                p.ProjCode ,
                mdp.LbProjectValue ,
                b.ProductType ,
				p.AcquisitionDate,
				xmfl.LbProjectValue xmfl,
                SUM(b.Taoshu) LJTS ,
                SUM(b.Area) LJMJ ,
                SUM(b.Amount) LJJE ,
				SUM(b.ThisMonthOrderTaoshu) LJRGTS,
				SUM(b.ThisMonthOrderArea) LJRGMJ,
				SUM(b.ThisMonthOrderAmount) LJRGJE,
                SUM(CASE WHEN datediff(day,a.BizDate,@var_enddate)=0 THEN b.Taoshu ELSE 0 END) BRTS ,
                SUM(CASE WHEN datediff(day,a.BizDate,@var_enddate)=0 THEN b.Area   ELSE 0 END) BRMJ ,
                SUM(CASE WHEN datediff(day,a.BizDate,@var_enddate)=0 THEN b.Amount ELSE 0 END) BRJE ,
                SUM(CASE WHEN datediff(day,a.BizDate,@var_enddate)=0 THEN b.ThisMonthOrderTaoshu ELSE 0 END) BRRGTS ,
                SUM(CASE WHEN datediff(day,a.BizDate,@var_enddate)=0 THEN b.ThisMonthOrderArea   ELSE 0 END) BRRGMJ ,
                SUM(CASE WHEN datediff(day,a.BizDate,@var_enddate)=0 THEN b.ThisMonthOrderAmount ELSE 0 END) BRRGJE ,
                SUM(CASE WHEN a.BizDate BETWEEN @var_bgndate AND @var_enddate THEN b.Taoshu ELSE 0 END) BQTS ,
                SUM(CASE WHEN a.BizDate BETWEEN @var_bgndate AND @var_enddate THEN b.Area ELSE 0 END) BQMJ ,
                SUM(CASE WHEN a.BizDate BETWEEN @var_bgndate AND @var_enddate THEN b.Amount ELSE 0 END) BQJE ,
                SUM(CASE WHEN a.BizDate BETWEEN @var_bgndate AND @var_enddate THEN b.ThisMonthOrderTaoshu ELSE 0 END) BQRGTS ,
                SUM(CASE WHEN a.BizDate BETWEEN @var_bgndate AND @var_enddate THEN b.ThisMonthOrderArea ELSE 0 END) BQRGMJ ,
                SUM(CASE WHEN a.BizDate BETWEEN @var_bgndate AND @var_enddate THEN b.ThisMonthOrderAmount ELSE 0 END) BQRGJE ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) THEN b.Taoshu ELSE 0 END) BNTS ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) THEN b.Area ELSE 0 END) BNMJ ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) THEN b.Amount ELSE 0 END) BNJE ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) THEN b.ThisMonthOrderTaoshu ELSE 0 END) BNRGTS ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) THEN b.ThisMonthOrderArea ELSE 0 END) BNRGMJ ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) THEN b.ThisMonthOrderAmount ELSE 0 END) BNRGJE ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) AND   a.DateMonth = MONTH(@var_enddate) THEN b.Taoshu ELSE 0 END) BYTS ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) AND   a.DateMonth = MONTH(@var_enddate) THEN b.Area ELSE 0 END) BYMJ ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) AND   a.DateMonth = MONTH(@var_enddate) THEN b.Amount ELSE 0 END) BYJE,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) AND   a.DateMonth = MONTH(@var_enddate) THEN b.ThisMonthOrderTaoshu ELSE 0 END) BYRGTS ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) AND   a.DateMonth = MONTH(@var_enddate) THEN b.ThisMonthOrderArea ELSE 0 END) BYRGMJ ,
                SUM(CASE WHEN a.DateYear = YEAR(@var_enddate) AND   a.DateMonth = MONTH(@var_enddate) THEN b.ThisMonthOrderAmount ELSE 0 END) BYRGJE
        INTO    #t1
        FROM    #hzyj a
                LEFT JOIN dbo.s_YJRLProducteDescript b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                INNER JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = a.ProjSetGUID
                LEFT JOIN dbo.mdm_Project p ON p.ProjGUID = c.ProjGUID
                LEFT JOIN mdm_LbProject mdp ON p.ProjGUID = mdp.projGUID AND   mdp.LbProject = 'tgid'
				LEFT JOIN mdm_LbProject xmfl ON p.ProjGUID = xmfl.projGUID AND   xmfl.LbProject = 'xmwfl'
                LEFT JOIN dbo.p_Project p1 ON p.ProjGUID = p1.ProjGUID
                LEFT JOIN dbo.myBusinessUnit m ON m.BUGUID = c.BUGuid
        WHERE   1 = 1 AND   a.Shenhe = '审核'
        GROUP BY CASE WHEN m.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                      WHEN m.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                      WHEN m.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                      WHEN m.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                      WHEN m.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                          '东北公司'
                      WHEN m.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                      WHEN m.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                      WHEN m.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                      WHEN m.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                      WHEN m.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                      ELSE m.BUName
                 END ,
                 m.BUGUID ,
                 ISNULL(p1.ProjName, p.ProjName) ,
                 p.ProjName ,
                 p.SpreadName ,
                 p.TradersWay ,
                 p.BbWay ,
                 p.EquityRatio ,
                 p.ProjCode ,
                 mdp.LbProjectValue ,
                 b.ProductType,
				p.AcquisitionDate,
				xmfl.LbProjectValue;

        ----加上特殊业绩
        SELECT  CASE WHEN m.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                     WHEN m.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                     WHEN m.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                     WHEN m.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                     WHEN m.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                         '东北公司'
                     WHEN m.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                     WHEN m.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                     WHEN m.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                     WHEN m.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                     WHEN m.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                     ELSE m.BUName
                END buname ,
                m.BUGUID ,
                p1.ProjName ,
                p.ProjName tzprojname ,
                p.SpreadName tzspreadname ,
                p.TradersWay ,
                p.BbWay ,
                p.EquityRatio ,
                p.ProjCode ,
                mdp.LbProjectValue ,
                '一级开发类' ProductType ,
                NULL thdate ,
				p.AcquisitionDate,
				xmfl.LbProjectValue xmfl ,
                SUM(a.AggregateNumber) LJTS ,
                SUM(a.AreaTotal) LJMJ ,
                SUM(a.TotalAmount) LJJE ,
                SUM(CASE WHEN datediff(day,a.RdDate,@var_enddate)=0 THEN a.AggregateNumber ELSE 0 END) BRTS ,
                SUM(CASE WHEN datediff(day,a.RdDate,@var_enddate)=0 THEN a.AreaTotal ELSE 0 END) BRMJ ,
                SUM(CASE WHEN datediff(day,a.RdDate,@var_enddate)=0 THEN a.TotalAmount ELSE 0 END) BRJE ,
                SUM(CASE WHEN a.RdDate BETWEEN @var_bgndate AND @var_enddate THEN a.AggregateNumber ELSE 0 END) BQTS ,
                SUM(CASE WHEN a.RdDate BETWEEN @var_bgndate AND @var_enddate THEN a.AreaTotal ELSE 0 END) BQMJ ,
                SUM(CASE WHEN a.RdDate BETWEEN @var_bgndate AND @var_enddate THEN a.TotalAmount ELSE 0 END) BQJE ,
                SUM(CASE WHEN YEAR(a.RdDate) = YEAR(@var_enddate) THEN a.AggregateNumber ELSE 0 END) BNTS ,
                SUM(CASE WHEN YEAR(a.RdDate) = YEAR(@var_enddate) THEN a.AreaTotal ELSE 0 END) BNMJ ,
                SUM(CASE WHEN YEAR(a.RdDate) = YEAR(@var_enddate) THEN a.TotalAmount ELSE 0 END) BNJE ,
                SUM(CASE WHEN DATEDIFF(m, ISNULL(RdDate, a.CreationTime), @var_enddate) = 0 THEN a.AggregateNumber ELSE 0 END) BYTS ,
                SUM(CASE WHEN DATEDIFF(m, ISNULL(RdDate, a.CreationTime), @var_enddate) = 0 THEN a.AreaTotal ELSE 0 END) BYMJ ,
                SUM(CASE WHEN DATEDIFF(m, ISNULL(RdDate, a.CreationTime), @var_enddate) = 0 THEN a.TotalAmount ELSE 0 END) BYJE
        INTO    #tsyj
        FROM    #S_PerformanceAppraisal a
                LEFT JOIN mdm_Project p ON p.ProjGUID = a.ManagementProjectGUID
                LEFT JOIN mdm_LbProject mdp ON p.ProjGUID = mdp.projGUID AND   mdp.LbProject = 'tgid'
				LEFT JOIN mdm_LbProject xmfl ON p.ProjGUID = xmfl.projGUID AND   xmfl.LbProject = 'xmwfl'
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ImportSaleProjGUID
                INNER JOIN dbo.myBusinessUnit m ON m.BUGUID = p1.BUGUID
        WHERE   1=1
                AND   a.YjType IN(SELECT    TsyjTypeName FROM   s_TsyjType WHERE IsRelatedBuildingsRoom = 0)
        GROUP BY CASE WHEN m.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                      WHEN m.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                      WHEN m.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                      WHEN m.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                      WHEN m.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                          '东北公司'
                      WHEN m.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                      WHEN m.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                      WHEN m.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                      WHEN m.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                      WHEN m.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                      ELSE m.BUName
                 END ,
                 m.BUGUID ,
                 p.ProjName ,
                 p1.ProjName ,
                 p.SpreadName ,
                 p.TradersWay ,
                 p.BbWay ,
                 p.EquityRatio ,
                 p.ProjCode ,
                 mdp.LbProjectValue,
				p.AcquisitionDate,
				xmfl.LbProjectValue
        UNION ALL
        SELECT  CASE WHEN m.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                     WHEN m.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                     WHEN m.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                     WHEN m.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                     WHEN m.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                         '东北公司'
                     WHEN m.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                     WHEN m.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                     WHEN m.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                     WHEN m.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                     WHEN m.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                     ELSE m.BUName
                END buname ,
                m.BUGUID ,
                p1.ProjName ,
                p.ProjName tzprojname ,
                p.SpreadName tzspreadname ,
                p.TradersWay ,
                p.BbWay ,
                p.EquityRatio ,
                p.ProjCode ,
                mdp.LbProjectValue ,
                pr.ProductType ,
                t.thdate ,
				p.AcquisitionDate,
				xmfl.LbProjectValue xmfl,
                SUM(CASE WHEN a.YJMode = 1 THEN 0 ELSE b.AggregateNumber END) LJTS ,
                SUM(CASE WHEN a.YJMode = 1 THEN 0 ELSE b.areatotal END) LJMJ ,
                SUM(b.totalamount) LJJE ,
                SUM(CASE WHEN datediff(day,a.RdDate,@var_enddate)=0 THEN b.AggregateNumber ELSE 0 END) BRTS ,
                SUM(CASE WHEN datediff(day,a.RdDate,@var_enddate)=0 THEN b.AreaTotal ELSE 0 END) BRMJ ,
                SUM(CASE WHEN datediff(day,a.RdDate,@var_enddate)=0 THEN b.TotalAmount ELSE 0 END) BRJE ,
                SUM(CASE WHEN a.YJMode <> 1 AND  (a.RdDate BETWEEN @var_bgndate AND @var_enddate) THEN b.AggregateNumber ELSE 0 END) BQTS ,
                SUM(CASE WHEN a.YJMode <> 1 AND  (a.RdDate BETWEEN @var_bgndate AND @var_enddate) THEN b.areatotal ELSE 0 END) BQMJ ,
                SUM(CASE WHEN a.RdDate BETWEEN @var_bgndate AND @var_enddate THEN b.totalamount ELSE 0 END) BQJE ,
                SUM(CASE WHEN a.YJMode <> 1 AND  (YEAR(a.RdDate) = YEAR(@var_enddate)) THEN b.AggregateNumber ELSE 0 END) BNTS ,
                SUM(CASE WHEN a.YJMode <> 1 AND  (YEAR(a.RdDate) = YEAR(@var_enddate)) THEN b.areatotal ELSE 0 END) BNMJ ,
                SUM(CASE WHEN YEAR(a.RdDate) = YEAR(@var_enddate) THEN b.totalamount ELSE 0 END) BNJE ,
                SUM(CASE WHEN a.YJMode <> 1 AND  (DATEDIFF(m, ISNULL(RdDate, a.CreationTime), @var_enddate) = 0) THEN b.AggregateNumber ELSE 0 END) BYTS ,
                SUM(CASE WHEN a.YJMode <> 1 AND  (DATEDIFF(m, ISNULL(RdDate, a.CreationTime), @var_enddate) = 0) THEN b.areatotal ELSE 0 END) BYMJ ,
                SUM(CASE WHEN DATEDIFF(m, ISNULL(RdDate, a.CreationTime), @var_enddate) = 0 THEN b.totalamount ELSE 0 END) BYJE
        FROM    #S_PerformanceAppraisal a
                LEFT JOIN(SELECT    PerformanceAppraisalGUID ,
                                    BldGUID ,
                                    IdentifiedArea areatotal ,
                                    AffirmationNumber AggregateNumber ,
                                    AmountDetermined totalamount
                          FROM  dbo.S_PerformanceAppraisalBuildings
                          -- WHERE BldGUID NOT IN (SELECT BldGUID FROM  p_room WHERE Status IN ('认购','签约'))---排除掉已经有认购签约的楼栋
                          UNION ALL
                          SELECT    PerformanceAppraisalGUID ,
                                    r.ProductBldGUID BldGUID ,
                                    SUM(a.IdentifiedArea) ,
                                    SUM(a.AffirmationNumber) ,
                                    SUM(a.AmountDetermined)
                          FROM  dbo.S_PerformanceAppraisalRoom a
                                LEFT JOIN MyCost_Erp352.dbo.md_Room r ON a.RoomGUID = r.RoomGUID    --AND r.Status NOT IN ('认购','签约')---排除掉已经有认购签约的房间
                          GROUP BY PerformanceAppraisalGUID ,
                                   r.ProductBldGUID) b ON a.PerformanceAppraisalGUID = b.PerformanceAppraisalGUID
                LEFT JOIN dbo.mdm_SaleBuild sb ON sb.SaleBldGUID = b.BldGUID
                LEFT JOIN dbo.mdm_Product pr ON pr.ProductGUID = sb.ProductGUID
                LEFT JOIN mdm_Project p ON p.ProjGUID = a.ManagementProjectGUID
                LEFT JOIN mdm_LbProject mdp ON p.ProjGUID = mdp.projGUID AND   mdp.LbProject = 'tgid'
				LEFT JOIN mdm_LbProject xmfl ON p.ProjGUID = xmfl.projGUID AND   xmfl.LbProject = 'xmwfl'
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ImportSaleProjGUID
                INNER JOIN dbo.myBusinessUnit m ON m.BUGUID = p1.BUGUID
                LEFT JOIN #th t ON t.buname = CASE WHEN m.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                                                   WHEN m.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                                                   WHEN m.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                                                   WHEN m.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                                                   WHEN m.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F' ,
                                                                     '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN '东北公司'
                                                   WHEN m.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                                                   WHEN m.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                                                   WHEN m.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                                                   WHEN m.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                                                   WHEN m.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                                                   ELSE m.BUName
                                              END AND  t.ProductType = pr.ProductType AND  t.projguid = p.ProjGUID
        WHERE   m.BUGUID IN(SELECT  Value FROM  [dbo].[fn_Split2](@var_buguid, ',') ) AND   a.AuditStatus = '已审核'
                AND   a.YjType IN(SELECT    TsyjTypeName FROM   s_TsyjType WHERE IsRelatedBuildingsRoom = 1)
        GROUP BY CASE WHEN m.BUGUID IN ('32560BCA-D251-4F93-BFE1-3809F94D5183', '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715', 'B35CDDA9-43AC-40AE-8E1B-2711B960BF39') THEN '广东公司'
                      WHEN m.BUGUID IN ('309C8C32-78FF-409F-8B52-E82E583BEE33', '5054E880-C6D5-488A-92DF-812E52E2712B') THEN '北京公司'
                      WHEN m.BUGUID IN ('3CDA8172-4E8A-E411-9927-E41F13C5183A') THEN '甘肃公司'
                      WHEN m.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', '4F3B4F6A-0ED9-468A-8158-3F1559C5F2E4') THEN '华南公司'
                      WHEN m.BUGUID IN ('528CA87C-F7AF-4FDD-BD05-79641D9F67FB', '1A0D7025-356E-4344-9074-C9BC416E6E66', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996') THEN
                          '东北公司'
                      WHEN m.BUGUID = '2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5' THEN '浙江公司'
                      WHEN m.BUGUID = 'A8DF0CF2-6D79-4E44-B169-45784CE13437' THEN '江西公司'
                      WHEN m.BUGUID = '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' THEN '安徽公司'
                      WHEN m.BUGUID IN ('B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '26AC8E14-EBAF-4557-8953-1293B058518B') THEN '福建公司'
                      WHEN m.BUGUID IN ('863D7F7C-53B4-4AFA-9A6F-BEA44BFB8598', '8412A5B2-0147-4AA3-813B-CC41D5D3D55B') THEN '海西公司'
                      ELSE m.BUName
                 END ,
                 m.BUGUID ,
                 p1.ProjName ,
                 p.ProjName ,
                 p.SpreadName ,
                 p.TradersWay ,
                 p.BbWay ,
                 p.EquityRatio ,
                 p.ProjCode ,
                 mdp.LbProjectValue ,
                 pr.ProductType ,
                 t.thdate,
				p.AcquisitionDate,
				xmfl.LbProjectValue;

        SELECT  公司名称 ,
                BUGUID ,
                项目名称 ,
                投管项目名称 ,
                投管推广名 ,
                操盘方式 ,
                并表方式 ,
                项目权益比例 ,
                项目代码 ,
                产品类型 ,
                首推日期 ,
				获取时间,
				项目分类 '项目类型',
                SUM(ISNULL(本期认购套数, 0)) 本期认购套数 ,
                SUM(ISNULL(本期认购面积, 0)) 本期认购面积 ,
                SUM(ISNULL(本期认购金额, 0)) 本期认购金额 ,
                SUM(ISNULL(本期签约套数, 0)) 本期签约套数 ,
                SUM(ISNULL(本期签约面积, 0)) 本期签约面积 ,
                SUM(ISNULL(本期签约金额, 0)) 本期签约金额 ,
                SUM(ISNULL(本月认购套数, 0)) 本月认购套数 ,
                SUM(ISNULL(本年认购套数, 0)) 本年认购套数 ,
                SUM(ISNULL(累计认购套数, 0)) 累计认购套数 ,
                SUM(ISNULL(本月认购面积, 0)) 本月认购面价 ,
                SUM(ISNULL(本年认购面积, 0)) 本年认购面价 ,
                SUM(ISNULL(累计认购面积, 0)) 累计认购面价 ,
                SUM(ISNULL(本月认购金额, 0)) 本月认购金额 ,
                SUM(ISNULL(本年认购金额, 0)) 本年认购金额 ,
                SUM(ISNULL(累计认购金额, 0)) 累计认购金额 ,
                SUM(ISNULL(本月签约套数, 0)) 本月签约套数 ,
                SUM(ISNULL(本年签约套数, 0)) 本年签约套数 ,
                SUM(ISNULL(累计签约套数, 0)) 累计签约套数 ,
                SUM(ISNULL(本月签约面积, 0)) 本月签约面积 ,
                SUM(ISNULL(本年签约面积, 0)) 本年签约面积 ,
                SUM(ISNULL(累计签约面积, 0)) 累计签约面积 ,
                SUM(ISNULL(本月签约金额, 0)) 本月签约金额 ,
                SUM(ISNULL(本年签约金额, 0)) 本年签约金额 ,
                SUM(ISNULL(累计签约金额, 0)) 累计签约金额 ,
                SUM(ISNULL(本年签约权益面积, 0)) 本年签约权益面积 ,
                SUM(ISNULL(本年签约权益金额, 0)) 本年签约权益金额 ,
                CASE WHEN SUM(ISNULL(本期认购面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本期认购金额, 0)) * 1.00 / SUM(本期认购面积)END * 10000 AS '本期认购均价' ,
                CASE WHEN SUM(ISNULL(本月认购面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本月认购金额, 0)) * 1.00 / SUM(本月认购面积)END * 10000 AS '本月认购均价' ,
                CASE WHEN SUM(ISNULL(本年认购面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年认购金额, 0)) * 1.00 / SUM(本年认购面积)END * 10000 AS '本年认购均价' ,
                CASE WHEN SUM(ISNULL(累计认购面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(累计认购金额, 0)) * 1.00 / SUM(累计认购面积)END * 10000 AS '累计认购均价' ,
                CASE WHEN SUM(ISNULL(本期签约面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本期签约金额, 0)) * 1.00 / SUM(本期签约面积)END * 10000 AS '本期签约均价' ,
                CASE WHEN SUM(ISNULL(本月签约面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本月签约金额, 0)) * 1.00 / SUM(本月签约面积)END * 10000 AS '本月签约均价' ,
                CASE WHEN SUM(ISNULL(本年签约面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年签约金额, 0)) * 1.00 / SUM(本年签约面积)END * 10000 AS '本年签约均价' ,
                CASE WHEN SUM(ISNULL(累计签约面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(累计签约金额, 0)) * 1.00 / SUM(累计签约面积)END * 10000 AS '累计签约均价' ,
                投管代码 ,
                SUM(ISNULL(未签约套数, 0)) 未签约套数 ,
                SUM(ISNULL(未签约面积, 0)) 未签约面积 ,
                SUM(ISNULL(未签约金额, 0)) 未签约金额 ,
				SUM(ISNULL(本日预认购套数  ,0))  本日预认购套数  ,
				SUM(ISNULL(本日预认购面积  ,0))  本日预认购面积  ,
				SUM(ISNULL(本日预认购金额  ,0))  本日预认购金额  ,
				SUM(ISNULL(本月预认购套数  ,0))  本月预认购套数  ,
				SUM(ISNULL(本月预认购面积  ,0))  本月预认购面积  ,
				SUM(ISNULL(本月预认购金额  ,0))  本月预认购金额  ,
				SUM(ISNULL(本年预认购套数  ,0))  本年预认购套数  ,
				SUM(ISNULL(本年预认购面积  ,0))  本年预认购面积  ,
				SUM(ISNULL(本年预认购金额  ,0))  本年预认购金额  ,
				SUM(ISNULL(累计预认购套数  ,0))  累计预认购套数  ,
				SUM(ISNULL(累计预认购面积  ,0))  累计预认购面积  ,
				SUM(ISNULL(累计预认购金额  ,0))  累计预认购金额  ,
				SUM(ISNULL(本日实际认购套数,0))  本日实际认购套数,
				SUM(ISNULL(本日实际认购面积,0))  本日实际认购面积,
				SUM(ISNULL(本日实际认购金额,0))  本日实际认购金额,
				SUM(ISNULL(本月实际认购套数,0))  本月实际认购套数,
				SUM(ISNULL(本月实际认购面积,0))  本月实际认购面积,
				SUM(ISNULL(本月实际认购金额,0))  本月实际认购金额,
				SUM(ISNULL(本年实际认购套数,0))  本年实际认购套数,
				SUM(ISNULL(本年实际认购面积,0))  本年实际认购面积,
				SUM(ISNULL(本年实际认购金额,0))  本年实际认购金额,
				SUM(ISNULL(累计实际认购套数,0))  累计实际认购套数,
				SUM(ISNULL(累计实际认购面积,0))  累计实际认购面积,
				SUM(ISNULL(累计实际认购金额,0))  累计实际认购金额
        FROM(SELECT 公司名称 ,
                    BUGUID ,
                    项目名称 ,
                    投管项目名称 ,
                    投管推广名 ,
                    操盘方式 ,
                    并表方式 ,
                    项目权益比例 ,
                    项目代码 ,
                    产品类型 ,
                    首推日期 ,
					获取时间 ,
					项目分类 ,
                    本期认购套数 ,
                    本期认购面积 ,
                    本期认购金额 ,
                    本期签约套数 ,
                    本期签约面积 ,
                    本期签约金额 ,
                    本月认购套数 ,
                    本年认购套数 ,
                    累计认购套数 ,
                    本月认购面积 ,
                    本年认购面积 ,
                    累计认购面积 ,
                    本月认购金额 ,
                    本年认购金额 ,
                    累计认购金额 ,
                    本月签约套数 ,
                    本年签约套数 ,
                    累计签约套数 ,
                    本月签约面积 ,
                    本年签约面积 ,
                    累计签约面积 ,
                    本月签约金额 ,
                    本年签约金额 ,
                    累计签约金额 ,
                    本年签约权益面积 ,
                    本年签约权益金额 ,
                    本期认购均价 ,
                    本月认购均价 ,
                    本年认购均价 ,
                    累计认购均价 ,
                    本期签约均价 ,
                    本月签约均价 ,
                    本年签约均价 ,
                    累计签约均价 ,
                    投管代码 ,
                    未签约套数 ,
                    未签约面积 ,
                    未签约金额 ,
					本日预认购套数,
					本日预认购面积,
					本日预认购金额,
					本月预认购套数,
					本月预认购面积,
					本月预认购金额,
					本年预认购套数,
					本年预认购面积,
					本年预认购金额,
					累计预认购套数,
					累计预认购面积,
					累计预认购金额,
					本日实际认购套数,
					本日实际认购面积,
					本日实际认购金额,
					本月实际认购套数,
					本月实际认购面积,
					本月实际认购金额,
					本年实际认购套数,
					本年实际认购面积,
					本年实际认购金额,
					累计实际认购套数,
					累计实际认购面积,
					累计实际认购金额
             FROM   #t
             UNION ALL
             SELECT BUName ,
                    BUGUID ,
                    ProjName ,
                    tzprojname ,
                    tzspreadname ,
                    TradersWay ,
                    BbWay ,
                    EquityRatio ,
                    ProjCode ,
                    ProductType ,
                    NULL ,
					AcquisitionDate,
					xmfl ,
                    BQRGTS ,
                    BQRGMJ ,
                    BQRGJE ,
                    BQTS ,
                    BQMJ ,
                    BQJE ,
                    BYRGTS ,
                    BNRGTS ,
                    LJRGTS ,
                    BYRGMJ ,
                    BNRGMJ ,
                    LJRGMJ ,
                    BYRGJE * 1.00 ,
                    BNRGJE * 1.00 ,
                    LJRGJE * 1.00 ,
                    BYTS ,
                    BNTS ,
                    LJTS ,
                    BYMJ ,
                    BNMJ ,
                    LJMJ ,
                    BYJE * 1.00 ,
                    BNJE * 1.00 ,
                    LJJE * 1.00 ,
                    BNMJ * 1.00 * ISNULL(EquityRatio, 0) / 100 ,
                    BNJE * 1.00 * ISNULL(EquityRatio, 0) / 100 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    LbProjectValue ,
                    0 ,
                    0 ,
                    0 ,
					0 本日预认购套数,
					0 本日预认购面积,
					0 本日预认购金额,
					0 本月预认购套数,
					0 本月预认购面积,
					0 本月预认购金额,
					0 本年预认购套数,
					0 本年预认购面积,
					0 本年预认购金额,
					0 累计预认购套数,
					0 累计预认购面积,
					0 累计预认购金额,
					BRRGTS 本日实际认购套数,
					BRRGMJ 本日实际认购面积,
					BRRGJE 本日实际认购金额,
					BYRGTS 本月实际认购套数,
					BYRGMJ 本月实际认购面积,
					BYRGJE 本月实际认购金额,
					BNRGTS 本年实际认购套数,
					BNRGMJ 本年实际认购面积,
					BNRGJE 本年实际认购金额,
					LJRGTS 累计实际认购套数,
					LJRGMJ 累计实际认购面积,
					LJRGJE 累计实际认购金额
             FROM   #t1
             UNION ALL
             SELECT buname ,
                    BUGUID ,
                    ProjName ,
                    tzprojname ,
                    tzspreadname ,
                    TradersWay ,
                    BbWay ,
                    EquityRatio ,
                    ProjCode ,
                    ProductType ,
                    thdate ,
					AcquisitionDate ,
					xmfl ,
                    BQTS ,
                    BQMJ ,
                    BQJE ,
                    BQTS ,
                    BQMJ ,
                    BQJE ,
                    BYTS ,
                    BNTS ,
                    LJTS ,
                    BYMJ ,
                    BNMJ ,
                    LJMJ ,
                    BYJE * 1.00 ,
                    BNJE * 1.00 ,
                    LJJE * 1.00 ,
                    BYTS ,
                    BNTS ,
                    LJTS ,
                    BYMJ ,
                    BNMJ ,
                    LJMJ ,
                    BYJE * 1.00 ,
                    BNJE * 1.00 ,
                    LJJE * 1.00 ,
                    BNMJ * 1.00 * ISNULL(EquityRatio, 0) / 100 ,
                    BNJE * 1.00 * ISNULL(EquityRatio, 0) / 100 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    0 ,
                    LbProjectValue ,
                    0 ,
                    0 ,
                    0 ,
					0 本日预认购套数,
					0 本日预认购面积,
					0 本日预认购金额,
					0 本月预认购套数,
					0 本月预认购面积,
					0 本月预认购金额,
					0 本年预认购套数,
					0 本年预认购面积,
					0 本年预认购金额,
					0 累计预认购套数,
					0 累计预认购面积,
					0 累计预认购金额,
					BRTS 本日实际认购套数,
					BRMJ 本日实际认购面积,
					BRJE 本日实际认购金额,
					BYTS 本月实际认购套数,
					BYMJ 本月实际认购面积,
					BYJE 本月实际认购金额,
					BNTS 本年实际认购套数,
					BNMJ 本年实际认购面积,
					BNJE 本年实际认购金额,
					LJTS 累计实际认购套数,
					LJMJ 累计实际认购面积,
					LJJE 累计实际认购金额
             FROM   #tsyj) A
        GROUP BY 公司名称 ,
                 BUGUID ,
                 项目名称 ,
                 投管项目名称 ,
                 投管推广名 ,
                 操盘方式 ,
                 并表方式 ,
                 项目权益比例 ,
                 项目代码 ,
                 产品类型 ,
                 首推日期 ,
                 投管代码 ,
				 获取时间,
				 项目分类
        ORDER BY A.公司名称 ,
                 A.项目名称;

        DROP TABLE #th;
        DROP TABLE #t;
        DROP TABLE #t1;
        DROP TABLE #hzyj;
        DROP TABLE #tsyj;
        DROP TABLE #room;
        DROP TABLE #rgwqy;
		drop table #pre;
		drop table #S_PerformanceAppraisal;
		drop table #yrg
    END;
