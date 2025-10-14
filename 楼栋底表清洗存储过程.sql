USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_P_LDDBamj]    Script Date: 2025/10/14 10:18:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---注意：脚本中需要将MyCost_Erp352改成对应352的数据库名
--需要将MyCost_Erp352改成对应352的数据库名

ALTER PROC [dbo].[usp_P_LDDBamj]
AS
/*  
存储过程名：  
      [usp_p_lddbamj]   
  功能：  
      按照新货值取数口径，清洗楼栋底表  
    
  说明：  
     --本存储过程示例    
    exec [usp_p_lddbamj]  
      
    select * from p_lddbamj where datediff(day,qxdate,getdate())=0 
          
  Create by ： LP  2018-12-04  V 1.0 
  ----2019-07-03 附属房间推货日期为空直接与主房间签约,不能计入未推面积---
  ----2019-07-09 预售形象不取进度系统开盘销售日期------
  ----2019-08-30 梳理预计/实际完成日期。
  ----2019-09-04 预售形象、预售办理改为货量铺排一致 by 杨平
  ----2019-11-26 已售增加特殊业绩  by 杨平
  ----2019-12-25 预售形象 最末级取工程楼栋
  ----2020-01-07 取价格时 过滤掉重复的楼栋
  ----2020-01-08 已售取特殊业绩 逻辑调整
  ----2020-04-15 不做项目过滤
  ----2020-04-26 特殊业绩的房间打标识
  ----2020-05-20 最新一版如果是线下 则不取楼栋
  ----2020-07-08 价格预测取最新审核版，防止在做货量铺排的过程中 取不到数据 
  ----2020-09-14 立项定位价取数 
					vmdm_DwProductPrice --定位产品价格
					vmdm_LxProductPrice --立项产品价格
  ----2020-09-28 预测价取价格预测/货量模块最新数据
  ----2020-10-27 缓存所有楼栋
  ----2020-11-11 当产品类型为车库时，关联立项定位价 不考虑商品类型
  ----2021-07-15 增加未容错的实际预售形象预售办理 by yp
  ----2021-12-06 参考usp_SalesValueBuding_Export
		1、留置车位-去化比例货量货值计算
		2、已售货量认购口径调整为签约口径
		3、隐藏认购（考虑很多地方取楼栋底表，如果没有认购字段会报错，先置为0） ---这个未做处理，不影响。
		4、合作项目录入到楼栋取值
  ----2022-01-19 未转属性的车位如果录入了特殊业绩，也要算入已售
  ----20220617 对于车位逻辑调整为与货量铺排一致
  --20220704 保留每月1号的数据
  --29221214 特殊业绩考虑参数
  --20230420 增加推货容错版的实际预售形象预售办理 by yp
  --20240418 调整车位的15000的判断为100 by z
  --20240828 调整合作业绩楼栋业绩双算 by z
*/
BEGIN

    SET NOCOUNT ON;
    --缓存房间信息表
    SELECT r.RoomGUID,
           r.MainRoomGUID,
           r.ThDate,
           r.BldArea,
           ISNULL(r.HSZJ, 0) HSZJ,
           ISNULL(r.HLTotal, Total) Total,
           r.Status,
           r.BldGUID,
		   0 isHZYJ
    INTO #svb_Room
    FROM dbo.p_room r
    WHERE 1 = 1
          AND r.IsVirtualRoom = 0;

    ----补上销售系统外的所有房间
    --INSERT INTO #svb_Room ( RoomGUID, ThDate, BldArea, HSZJ, Total, Status, BldGUID )
    --            SELECT r.RoomGUID ,
    --                   NULL ,
    --                   r.BldArea ,
    --                   0 ,
    --                   0 ,
    --                   '' ,
    --                   r.ProductBldGUID
    --            FROM   MyCost_Erp352.dbo.md_Room r
    --            WHERE  NOT EXISTS ( SELECT 1 FROM p_room b WHERE r.RoomGUID = b.RoomGUID )
    --                   AND (   EXISTS (   SELECT 1
    --                                      FROM   dbo.S_PerformanceAppraisalRoom sr
    --                                             INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
    --                                                                                        AND s.AuditStatus = '已审核'
    --                                                                                        AND sr.RoomGUID = r.RoomGUID )
    --                           OR EXISTS (   SELECT 1
    --                                         FROM   dbo.S_PerformanceAppraisalBuildings sr
    --                                                INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
    --                                                                                           AND s.AuditStatus = '已审核'
    --                                                                                           AND sr.BldGUID = r.ProductBldGUID )
    --                           OR EXISTS (   SELECT 1
    --                                         FROM   s_YJRLProducteDetail a
    --                                                INNER JOIN s_YJRLBuildingDescript b ON a.ProducteDetailGUID = b.ProducteDetailGUID
    --                                         WHERE  1 = 1
    --                                                AND b.BldGUID = r.ProductBldGUID
    --                                                AND a.Shenhe = '审核' ))
    --                   AND ISNULL(r.UseProperty, '') <> ''; --把不在销售系统，但是被特殊业绩关联的房间存进去


    --缓存所有房间到信息表
    SELECT *
    INTO #sy_Room
    FROM
    (
        SELECT RoomGUID,
               BldGUID,
               BldArea,
               0 BsRoomSx --标识房间不同属性 
        FROM #svb_Room
        UNION
        SELECT a.RoomGUID,
               a.ProductBldGUID AS BldGUID,
               a.BldArea,
               (CASE
                    WHEN ISNULL(a.UseProperty, '') = '' THEN
                         2
                    ELSE 1
                END
               ) AS BsRoomSx
        FROM MyCost_Erp352.dbo.md_Room a
        WHERE 1 = 1
              AND NOT EXISTS
        (
            SELECT 1 FROM #svb_Room b WHERE a.RoomGUID = b.RoomGUID
        )   --避免重复
              AND
              (
                  a.UseProperty = '留存自用'
                  OR a.UseProperty = '经营'
                  OR a.UseProperty = '公配化房间'
                  OR ISNULL(a.UseProperty, '') = ''
              )
    ) AS Room;

    --获取楼栋合作业绩临时数据
    SELECT b.ProjGUID,
           b.BldGUID AS SaleBldGUID,
           b.Taoshu AS ysts,
           b.Area AS ysmj,
           b.Amount * 10000 AS ysje,
           CONVERT(DATE, a.DateYear + '-' + a.DateMonth + '-27') AS RdDate,
           b.ProductType
    INTO #s_YJRLBuildingDescript
    FROM s_YJRLProducteDetail a
         INNER JOIN s_YJRLBuildingDescript b ON a.ProducteDetailGUID = b.ProducteDetailGUID
    WHERE 1 = 1
          AND a.Shenhe = '审核';

    --获取楼栋合作业绩汇总数据
    SELECT SaleBldGUID,
           ProjGUID,
           SUM(ysts) AS ysts,
           SUM(ysmj) AS ysmj,
           SUM(ysje) AS ysje,
           0 AS wtmj,
           0 AS wtts,
           MIN(RdDate) AS StDate
    INTO #HZYJ
    FROM #s_YJRLBuildingDescript
    WHERE DATEDIFF(m, RdDate, GETDATE()) >= 0
    GROUP BY ProjGUID,
             SaleBldGUID;

	update #svb_Room set isHZYJ = 1 where BldGUID in (select SaleBldGUID from #HZYJ);

    --先缓存计入已售货量的特殊业绩
    SELECT s.*
    INTO #S_PerformanceAppraisal
    FROM S_PerformanceAppraisal s
    WHERE 1 = 1
          AND s.AuditStatus = '已审核'
          AND s.yjtype IN (
                              SELECT TsyjTypeName FROM s_TsyjType t WHERE IsCalcYSHL = 1
                          ); --是否计入已售货量为是

    --获取特殊业绩房间数据
    SELECT sr.RoomGUID,
           sr.RGUID,
           s.RdDate,
           s.CreationTime,
           r.ProjGUID,
           sr.AmountDetermined,
           ISNULL(s.YjType, '') AS YjType,
           r.ProductBldGUID BldGUID,
           s.ManagementProjectGUID
    INTO #S_PerformanceAppraisalRoom
    FROM dbo.S_PerformanceAppraisalRoom sr
         INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
         INNER JOIN MyCost_Erp352.dbo.md_Room r ON sr.RoomGUID = r.RoomGUID
    WHERE 1 = 1
          AND s.AuditStatus = '已审核'
          AND DATEDIFF(DAY, ISNULL(s.RdDate, s.CreationTime), GETDATE()) >= 0
    --      AND NOT EXISTS
    --(
    --    SELECT 1 FROM #HZYJ h WHERE h.SaleBldGUID = r.ProductBldGUID
    --); --排除合作业绩楼栋     ---取消合作业绩过滤20240829

    --缓存溢价款特殊业绩房间数据
    SELECT BldGUID,
           ManagementProjectGUID AS ProjGUID,
           AmountDetermined * 10000 ysje,
           RdDate
    INTO #tsyj_RoomYjk
    FROM #S_PerformanceAppraisalRoom
    WHERE DATEDIFF(m, ISNULL(RdDate, CreationTime), GETDATE()) >= 0
          AND YjType IN (
                            SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 1
                        ); --业绩双算;

    --获取特殊业绩楼栋数据
    SELECT sr.BldGUID,
           sr.AmountDetermined,
           s.RdDate,
           s.CreationTime,
           s.ManagementProjectGUID,
           ISNULL(s.YjType, '') AS YjType
    INTO #S_PerformanceAppraisalBuildings
    FROM dbo.S_PerformanceAppraisalBuildings sr
         INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
         INNER JOIN dbo.p_Building b ON b.BldGUID = sr.BldGUID
    WHERE 1 = 1
          AND s.AuditStatus = '已审核'
          AND DATEDIFF(DAY, ISNULL(s.RdDate, s.CreationTime), GETDATE()) >= 0
    --      AND NOT EXISTS
    --(
    --    SELECT 1 FROM #HZYJ h WHERE h.SaleBldGUID = sr.BldGUID
    --); --排除合作业绩楼栋    ---取消合作业绩过滤20240829

    --缓存认购信息表                        
    SELECT b.OrderType AS saletype,
           b.JyTotal + ISNULL(t.tsje, 0) JyTotal,
           b.TradeGUID,
           b.RoomGUID,
           b.Status,
           b.QSDate,
           b.ProjGUID,
           b.OrderGUID,
           b.CloseReason
    INTO #svb_Order
    FROM dbo.s_Order b
         INNER JOIN p_room a ON a.RoomGUID = b.RoomGUID
         LEFT JOIN
         (
             SELECT roomguid,
                    SUM(AmountDetermined) tsje
             FROM #S_PerformanceAppraisalRoom
             WHERE YjType IN (
                                 SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 1
                             )
             GROUP BY RoomGUID
         ) t ON t.RoomGUID = a.RoomGUID
    WHERE 1 = 1
          AND b.OrderType = '认购'
          AND DATEDIFF(m, QSDate, GETDATE()) >= 0
          AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.S_PerformanceAppraisalRoom sr
             INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                     AND s.AuditStatus = '已审核'
                                                     AND sr.RoomGUID = a.RoomGUID
                                                     AND s.yjtype IN (
                                                                         SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                                                                     )
    )
          AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.S_PerformanceAppraisalBuildings sr
             INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                     AND s.AuditStatus = '已审核'
                                                     AND sr.BldGUID = a.BldGUID
                                                     AND s.yjtype IN (
                                                                         SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                                                                     )
    )
    --      AND NOT EXISTS
    --(
    --    SELECT 1 FROM #HZYJ h WHERE h.SaleBldGUID = a.BldGUID
    --)    ---取消合作业绩过滤20240829
    ---加上特殊业绩
    UNION ALL
    SELECT '认购' AS saletype,
           a.AmountDetermined * 10000,
           a.RGUID,
           a.RoomGUID,
           '关闭',
           a.RdDate,
           a.ProjGUID,
           a.RGUID,
           '转签约'
    FROM #S_PerformanceAppraisalRoom a
    WHERE YjType IN (
                        SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                    ); --业绩单算

    --缓存合同信息表                          
    SELECT '合同' AS saletype,
           b.JyTotal + ISNULL(t.tsje, 0) JyTotal,
           b.TradeGUID,
           b.RoomGUID,
           b.Status,
           b.QSDate,
           b.ProjGUID,
           b.LastSaleGUID
    INTO #svb_Contract
    FROM dbo.s_Contract b
         LEFT JOIN p_room a ON a.RoomGUID = b.RoomGUID
         LEFT JOIN
         (
             SELECT roomguid,
                    SUM(AmountDetermined) tsje
             FROM #S_PerformanceAppraisalRoom
             WHERE YjType IN (
                                 SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 1
                             )
             GROUP BY RoomGUID
         ) t ON t.RoomGUID = a.RoomGUID
    WHERE 1 = 1 --b.ProjGUID IN ( SELECT ProjGUID FROM dbo.#svb_Proje ) 
          AND DATEDIFF(m, QSDate, GETDATE()) >= 0
          AND a.RoomGUID NOT IN (
                                    SELECT sr.RoomGUID
                                    FROM dbo.S_PerformanceAppraisalRoom sr
                                         INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                 AND s.AuditStatus = '已审核'
                                                                                 AND s.yjtype IN (
                                                                                                     SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                                                                                                 )
                                )
          AND a.BldGUID NOT IN (
                                   SELECT sr.BldGUID
                                   FROM dbo.S_PerformanceAppraisalBuildings sr
                                        INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                AND s.AuditStatus = '已审核'
                                                                                AND s.yjtype IN (
                                                                                                    SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                                                                                                )
                               )
    --      AND NOT EXISTS
    --(
    --    SELECT 1 FROM #HZYJ h WHERE h.SaleBldGUID = a.BldGUID
    --)   ---20240829取消合租业绩过滤
    ---加上特殊业绩
    UNION ALL
    SELECT '合同',
           a.AmountDetermined * 10000,
           a.RGUID,
           a.RoomGUID,
           '激活',
           a.RdDate,
           a.ProjGUID,
           a.RGUID
    FROM #S_PerformanceAppraisalRoom a
    WHERE a.YjType IN (
                          SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                      );

    --缓存补差款收款信息表  
    SELECT Amount,
           TradeGUID
    INTO #svb_Fee
    FROM dbo.s_Fee
    WHERE TradeGUID IN (
                           SELECT TradeGUID
                           FROM #svb_Contract
                           WHERE Status = '激活'
                           UNION
                           SELECT TradeGUID
                           FROM #svb_Order
                           WHERE Status = '激活'
                       )
          AND ItemName IN ( '补差款', '房款补差款' );

    --缓存存在可售房间的投管产品楼栋信息(不管楼栋属性)
    SELECT dv.DevelopmentCompanyName,
           mp1.SpreadName,
           mp1.ProjGUID,
           cp.ProductType,
           cp.ProductName,
           cp.BusinessType,
           cp.Standard,
           cp.Remark,
           cp.YtCode,
           sb.SaleBldGUID,
           sb.BldCode,
           sb.IsSale,
           cp.IsHold,
           sb.ProductGUID,
           ---楼栋可售面积取房间面积汇总
           (
               SELECT SUM(BldArea)
               FROM p_room
               WHERE BldGUID = ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID)
                     AND IsVirtualRoom = 0
           ) SaleArea,
           ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID) ImportSaleBldGUID,
           sb.GCBldGUID,
           dv.DevelopmentCompanyGUID,
           sb.HaveSaleConditionDate,
           sb.YszGetDate,
           sb.PlanPrice,
           ---楼栋户个数取房间套数汇总
           (
               SELECT COUNT(1)
               FROM p_room
               WHERE BldGUID = ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID)
                     AND IsVirtualRoom = 0
           ) HouseNum,
           ISNULL(sb.HouseNum, 0) AS BldHouseNum,
           ISNULL(qh.QHRate, 100) / 100 AS QHRate,
           ISNULL(rc.RoomCount, 0) AS RoomCount,
           CASE
               WHEN rc.SaleRoomCount > 0 THEN
                    ISNULL(rc.RoomArea, 0)
               ELSE 0
           END AS RoomArea,
           ISNULL(rc.SaleRoomCount, 0) AS SaleRoomCount
    INTO #svb_ld
    FROM dbo.mdm_SaleBuild sb
         LEFT JOIN mdm_GCBuild gc ON sb.GCBldGUID = gc.GCBldGUID
         LEFT JOIN dbo.mdm_Product cp ON cp.ProductGUID = sb.ProductGUID
         LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = gc.ProjGUID
         LEFT JOIN dbo.mdm_Project mp1 ON mp.ParentProjGUID = mp1.ProjGUID
         LEFT JOIN dbo.p_DevelopmentCompany dv ON dv.DevelopmentCompanyGUID = mp1.DevelopmentCompanyGUID
         LEFT JOIN
         (
             SELECT BldGUID,
                    COUNT(1) RoomCount,
                    SUM(   CASE
                               WHEN BsRoomSx = 0 THEN
                                    1
                               ELSE 0
                           END
                       ) AS SaleRoomCount,
                    SUM(   CASE
                               WHEN BsRoomSx = 0 THEN
                                    BldArea
                               ELSE 0
                           END
                       ) AS SaleArea,
                    SUM(   CASE
                               WHEN BsRoomSx = 1 THEN
                                    BldArea
                               ELSE 0
                           END
                       ) AS Zchlmj,
                    SUM(BldArea) AS RoomArea
             FROM #sy_Room
             GROUP BY BldGUID
         ) rc ON ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID) = rc.BldGUID
         LEFT JOIN vmd_ProductBuild_QHRate qh ON sb.SaleBldGUID = qh.ProductBuildGUID
    WHERE mp.ProjGUID IS NOT NULL
          AND ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID) IN (
                                                                  SELECT BldGUID FROM #sy_Room r
                                                              );

    --缓存不存在房间,属性为可售、非自持的投管产品楼栋信息  
    INSERT INTO #svb_ld
    SELECT dv.DevelopmentCompanyName,
           mp1.SpreadName,
           mp1.ProjGUID,
           cp.ProductType,
           cp.ProductName,
           cp.BusinessType,
           cp.Standard,
           cp.Remark,
           cp.YtCode,
           sb.SaleBldGUID,
           sb.BldCode,
           sb.IsSale,
           cp.IsHold,
           sb.ProductGUID,
           CASE
               WHEN sb.IsSale = 1
                    AND cp.IsHold = '否' THEN
                    sb.SaleArea
               ELSE 0
           END salearea,
           ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID) ImportSaleBldGUID,
           sb.GCBldGUID,
           dv.DevelopmentCompanyGUID,
           sb.HaveSaleConditionDate,
           sb.YszGetDate,
           sb.PlanPrice,
           CASE
               WHEN sb.IsSale = 1
                    AND cp.IsHold = '否' THEN
                    sb.HouseNum
               ELSE 0
           END HouseNum,
           ISNULL(sb.HouseNum, 0) AS BldHouseNum,
           ISNULL(qh.QHRate, 100) / 100 AS QHRate,
           0 AS RoomCount,
           0 AS RoomArea,
           0 AS SaleRoomCount
    FROM dbo.mdm_SaleBuild sb
         LEFT JOIN mdm_GCBuild gc ON sb.GCBldGUID = gc.GCBldGUID
         LEFT JOIN dbo.mdm_Product cp ON cp.ProductGUID = sb.ProductGUID
         LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = gc.ProjGUID
         LEFT JOIN dbo.mdm_Project mp1 ON mp.ParentProjGUID = mp1.ProjGUID
         LEFT JOIN dbo.p_DevelopmentCompany dv ON dv.DevelopmentCompanyGUID = mp1.DevelopmentCompanyGUID
         LEFT JOIN vmd_ProductBuild_QHRate qh ON sb.SaleBldGUID = qh.ProductBuildGUID
    WHERE mp.ProjGUID IS NOT NULL
          ----不存在房间
          AND NOT EXISTS
    (
        SELECT 1
        FROM #sy_Room sy
        WHERE sy.BldGUID = ISNULL(sb.ImportSaleBldGUID, '11111111-1111-1111-1111-111111111111')
              OR sy.BldGUID = sb.SaleBldGUID
    );


    --按房间月份分组汇总特殊业绩房间
    SELECT RoomGUID,
           (SUM(AmountDetermined) * 10000) AS ysje,
           YjType,
           BldGUID,
           ManagementProjectGUID AS ProjGUID,
           YEAR(RdDate) AS RdDateYear,
           MONTH(RdDate) AS RdDateMonth,
           MIN(RdDate) AS RdDate,
           0 AS ysmj,
           CAST('' AS VARCHAR(200)) AS ProductType
    INTO #Tsyj_Room
    FROM #S_PerformanceAppraisalRoom a
    WHERE DATEDIFF(m, ISNULL(RdDate, CreationTime), GETDATE()) >= 0
    GROUP BY RoomGUID,
             YjType,
             BldGUID,
             ManagementProjectGUID,
             YEAR(RdDate),
             MONTH(RdDate);

    --修改特殊业绩房间面积
    UPDATE a
    SET ProductType = b.ProductType,
        ysmj = (CASE
                    WHEN t.RoomGUID IS NULL THEN
                         0
                    ELSE r.BldArea
                END
               )
    FROM #Tsyj_Room a
         LEFT JOIN
         (
             SELECT RoomGUID,
                    MIN(RdDate) AS RdDate
             FROM #Tsyj_Room
             GROUP BY RoomGUID
         ) t ON a.RoomGUID = t.RoomGUID
                AND a.RdDateYear = YEAR(t.RdDate)
                AND a.RdDateMonth = MONTH(t.RdDate)
         INNER JOIN #svb_ld b ON a.BldGUID = b.ImportSaleBldGUID
         INNER JOIN #svb_Room r ON r.RoomGUID = a.RoomGUID;

    --缓存特殊业绩房间数据
    SELECT BldGUID,
           SUM(ysje) AS ysje,
           SUM(ysmj) AS ysmj
    INTO #Tsyj_RoomSum
    FROM #Tsyj_Room
    WHERE YjType IN (
                        SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                    )
          AND RdDateYear = YEAR(GETDATE())
    GROUP BY BldGUID;

    --按楼栋分组汇总特殊业绩楼栋
    SELECT a.BldGUID AS SaleBldGUID,
           (SUM(a.AmountDetermined) * 10000) AS ysje,
           a.ManagementProjectGUID AS projguid,
           a.YjType,
           YEAR(a.RdDate) AS RdDateYear,
           MONTH(a.RdDate) AS RdDateMonth,
           MIN(a.RdDate) AS RdDate,
           sb.SaleArea AS ysmj,
           sb.HouseNum ysts,
           sb.ProductType AS ProductType
    INTO #Tsyj_Buildings
    FROM #S_PerformanceAppraisalBuildings a
         INNER JOIN #svb_ld sb ON a.BldGUID = sb.SaleBldGUID
    WHERE DATEDIFF(m, ISNULL(RdDate, CreationTime), GETDATE()) >= 0
    GROUP BY YEAR(a.RdDate),
             MONTH(a.RdDate),
             a.BldGUID,
             a.ManagementProjectGUID,
             a.YjType,
             sb.SaleArea,
             sb.HouseNum,
             sb.ProductType;


    ---缓存特殊业绩直接关联楼栋部分
    SELECT SaleBldGUID,
           projguid,
           ysts,
           ysmj,
           0 ytwsmj,
           0 ytwsts,
           0 wtmj,
           0 wtts,
           ysmj AS zksmj,
           ysje,
           0 ytwsje,
           0 rgwqyts,
           0 rgwqymj,
           0 rgwqyje,
           RdDateYear,
           RdDateMonth,
           ProductType
    INTO #tsyj
    FROM #Tsyj_Buildings
    WHERE YjType IN (
                        SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                    );

    SELECT SaleBldGUID,
           projguid,
           ysje,
           ysts,
           ysmj,
           RdDateYear,
           RdDateMonth,
           ProductType
    INTO #tsyj_Yjk
    FROM #Tsyj_Buildings
    WHERE YjType IN (
                        SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 1
                    );

    --修改合作业绩未推面积数据
    UPDATE a
    SET wtmj = ISNULL(b.SaleArea, 0) - ISNULL(a.ysmj, 0),
        wtts = ISNULL(b.HouseNum, 0) - ISNULL(a.ysts, 0)
    FROM #HZYJ a
         INNER JOIN #svb_ld b ON a.SaleBldGUID = b.ImportSaleBldGUID;

    ---把特殊业绩房间设置为签约（防止取到未推里去）
    UPDATE r
    SET Status = '签约'
    FROM #svb_Room r
    WHERE EXISTS
    (
        SELECT 1
        FROM #S_PerformanceAppraisalRoom sr
        WHERE sr.RoomGUID = r.RoomGUID
    )
          OR EXISTS
    (
        SELECT 1 FROM #tsyj ts WHERE ts.SaleBldGUID = r.BldGUID
    );

    ---取货值单价

    --项目下各产品签约均价  
    SELECT mp1.ProjGUID,
           cp.ProductType,
           SUM(c.JyTotal) JyTotal,
           SUM(c.BldArea) BldArea,
           SUM(c.JyTotal) / CASE
                                WHEN SUM(c.BldArea) = 0 THEN
                                     1
                                ELSE SUM(c.BldArea)
                            END qyjj
    INTO #jj
    FROM
    (
        SELECT r.BldGUID,
               SUM(r.BldArea) BldArea,
               SUM(c.JyTotal) JyTotal
        FROM dbo.#svb_Contract c
             LEFT JOIN dbo.p_room r ON r.RoomGUID = c.RoomGUID
        WHERE r.RoomGUID NOT IN (
                                    SELECT sr.RoomGUID
                                    FROM dbo.S_PerformanceAppraisalRoom sr
                                         INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                 AND s.AuditStatus = '已审核'
                                                                                 AND s.yjtype IN (
                                                                                                     SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                                                                                                 )
                                )
              AND r.BldGUID NOT IN (
                                       SELECT sr.BldGUID
                                       FROM dbo.S_PerformanceAppraisalBuildings sr
                                            INNER JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                                    AND s.AuditStatus = '已审核'
                                                                                    AND s.yjtype IN (
                                                                                                        SELECT TsyjTypeName FROM s_TsyjType t WHERE YjMode = 2
                                                                                                    )
                                   )
              AND c.Status = '激活'
        GROUP BY r.BldGUID
        UNION ALL
        SELECT tsyj.BldGUID,
               SUM(tsyj.areatotal) BldArea,
               SUM(tsyj.totalamount) JyTotal
        FROM
        (
            SELECT BldGUID,
                   SUM(IdentifiedArea) areatotal,
                   SUM(AmountDetermined * 10000) totalamount
            FROM dbo.S_PerformanceAppraisalBuildings sp
                 LEFT JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sp.PerformanceAppraisalGUID
            WHERE s.AuditStatus = '已审核'
            GROUP BY BldGUID
            UNION ALL
            SELECT r.ProductBldGUID,
                   SUM(a.IdentifiedArea),
                   SUM(a.AmountDetermined * 10000)
            FROM dbo.S_PerformanceAppraisalRoom a
                 LEFT JOIN MyCost_Erp352.dbo.md_Room r ON r.RoomGUID = a.RoomGUID
                 LEFT JOIN #S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
            WHERE s.AuditStatus = '已审核'
            GROUP BY r.ProductBldGUID
        ) tsyj
        GROUP BY tsyj.BldGUID
        UNION ALL
        SELECT h.SaleBldGUID,
               SUM(h.ysmj),
               SUM(h.ysje)
        FROM #HZYJ h
        GROUP BY h.SaleBldGUID
    ) c
    LEFT JOIN dbo.mdm_SaleBuild sb ON c.BldGUID = ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID)
    LEFT JOIN dbo.mdm_Product cp ON cp.ProductGUID = sb.ProductGUID
    LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = cp.ProjGUID
    LEFT JOIN dbo.mdm_Project mp1 ON mp.ParentProjGUID = mp1.ProjGUID
    GROUP BY mp1.ProjGUID,
             cp.ProductType;

    --楼栋货值价计算（预测>定位>立项>预计）      
    SELECT sb.SaleBldGUID,
           ISNULL(a.YcPrice, 0) ycprice,
           jj.qyjj,
           ISNULL(lx.lxPrice, 0) lxprice,
           ISNULL(dw.DwPrice, 0) dwprice,
           sb.PlanPrice,
           ---对于车位 个数单价 需转换成面积单价 排除掉 0.01/1的情况
           CASE
               WHEN ISNULL(a.YcPrice, 0) <> 0 THEN
                    a.YcPrice
               WHEN ISNULL(dw.DwPrice, 0) <> 0 THEN
                    dw.DwPrice
               WHEN ISNULL(lx.lxPrice, 0) <> 0 THEN
                    lx.lxPrice
               WHEN ISNULL(sb.PlanPrice, 0) <> 0 THEN
                    sb.PlanPrice
               ELSE jj.qyjj
           END hzdj
    INTO #dj
    FROM #svb_ld sb
         LEFT JOIN dbo.mdm_Product cp ON cp.ProductGUID = sb.ProductGUID
         LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = cp.ProjGUID
         LEFT JOIN dbo.mdm_Project mp1 ON mp.ParentProjGUID = mp1.ProjGUID
         LEFT JOIN #jj jj ON jj.ProjGUID = mp1.ProjGUID
                             AND cp.ProductType = jj.ProductType
         LEFT JOIN
         (
             SELECT a.SaleBldGUID,
                    ROW_NUMBER() OVER (PARTITION BY a.SaleBldGUID ORDER BY a.ApproveDate DESC) num,
                    a.YcPrice
             FROM
             (
                 SELECT pd.SaleBldGUID,
                        p.ApproveDate,
                        ISNULL(pd.YcPrice, 0) YcPrice
                 FROM s_PredictedPriceDtl pd
                      INNER JOIN s_PredictedPrice p ON p.PredictedPriceGUID = pd.PredictedPriceGUID
                                                       AND p.ApproveState IN ( '已审核', '已阅' )
                 UNION ALL
                 SELECT sb.SaleBldGUID,
                        step.ApproveDate,
                        ISNULL(sb.YcPrice, 0) ycprice
                 FROM dbo.s_SaleValueBuilding sb
                      INNER JOIN dbo.s_SaleValueVersionStep step ON step.SaleValuePlanVersionGUID = sb.SaleValuePlanVersionGUID
                                                                    AND step.ApproveState = '已审核'
                                                                    AND step.Step = 1
             ) a
         ) a ON a.SaleBldGUID = sb.SaleBldGUID
                AND a.num = 1
         LEFT JOIN
         (
             SELECT pr.SaleBldGUID,
                    AVG(dw.DwPrice) DwPrice
             FROM #svb_ld pr
                  INNER JOIN dbo.vmdm_dwproductPrice dw ON pr.ProjGUID = dw.ProjGUID
                                                           AND dw.ProductType = pr.ProductType
                                                           AND CASE
                                                                   WHEN dw.BusinessType = '地下室/车库' THEN
                                                                        ''
                                                                   ELSE dw.BusinessType
                                                               END = CASE
                                                                         WHEN pr.BusinessType = '地下室/车库' THEN
                                                                              ''
                                                                         ELSE pr.BusinessType
                                                                     END
                                                           AND REPLACE(dw.ProductName, '普通地下车位', '普通地下车库') = REPLACE(
                                                                                                                        pr.ProductName,
                                                                                                                        '普通地下车位',
                                                                                                                        '普通地下车库'
                                                                                                                    )
                                                           AND dw.Standard = pr.Standard
                                                           AND dw.IsSale = '是'
                                                           AND dw.IsHold = '否'
             GROUP BY pr.SaleBldGUID
         ) dw ON dw.SaleBldGUID = sb.SaleBldGUID
         LEFT JOIN
         (
             SELECT pr.SaleBldGUID,
                    AVG(lx.lxPrice) lxPrice
             FROM #svb_ld pr
                  INNER JOIN dbo.vmdm_lxproductPrice lx ON pr.ProjGUID = lx.ProjGUID
                                                           AND lx.ProductType = pr.ProductType
                                                           AND CASE
                                                                   WHEN lx.BusinessType = '地下室/车库' THEN
                                                                        ''
                                                                   ELSE lx.BusinessType
                                                               END = CASE
                                                                         WHEN pr.BusinessType = '地下室/车库' THEN
                                                                              ''
                                                                         ELSE pr.BusinessType
                                                                     END
                                                           AND REPLACE(lx.ProductName, '普通地下车位', '普通地下车库') = REPLACE(
                                                                                                                        pr.ProductName,
                                                                                                                        '普通地下车位',
                                                                                                                        '普通地下车库'
                                                                                                                    )
                                                           AND lx.Standard = pr.Standard
                                                           AND lx.IsSale = '是'
                                                           AND lx.IsHold = '否'
             GROUP BY pr.SaleBldGUID
         ) lx ON lx.SaleBldGUID = sb.SaleBldGUID;

	SELECT r.BldGUID,
                        SUM(   CASE
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.Status IN ( '签约' ) THEN
                                        1
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND pr.RoomGUID IS NOT NULL
                                        AND r.Status IN ( '签约' ) THEN
                                        1 --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) ysts,
                        SUM(   CASE
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.Status IN ( '签约' ) THEN
                                        r.BldArea
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND pr.RoomGUID IS NOT NULL
                                        AND r.Status IN ( '签约' ) THEN
                                        r.BldArea --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) ysmj,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN (r.Status NOT IN ( '认购', '签约' ))
                                        AND r.ThDate IS NOT NULL THEN
                                        r.BldArea
                                   ELSE 0
                               END
                           ) ytwsmj,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN (r.Status NOT IN ( '认购', '签约' ))
                                        AND r.ThDate IS NOT NULL THEN
                                        1
                                   ELSE 0
                               END
                           ) ytwsts,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' ) THEN
                                        r.BldArea
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' )
                                        AND pr.RoomGUID IS NOT NULL THEN
                                        r.BldArea --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) wtmj,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' ) THEN
                                        1
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' )
                                        AND pr.RoomGUID IS NOT NULL THEN
                                        1 --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) wtts,
                        SUM(   CASE
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.Status IN ( '签约' ) THEN
                                        ISNULL(t.JyTotal, 0) + ISNULL(bc.bc, 0)
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND r.Status IN ( '签约' )
                                        AND pr.RoomGUID IS NOT NULL THEN
                                        ISNULL(t.JyTotal, 0) + ISNULL(bc.bc, 0) --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) ysje,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN (
                                            t.TradeGUID IS NULL
                                            AND r.Status NOT IN ( '签约' )
                                        )
                                        AND r.ThDate IS NOT NULL THEN
                                        CASE
                                            WHEN ISNULL(r.HSZJ, 0) < 1000 THEN
                                                 r.Total
                                            ELSE r.HSZJ
                                        END
                                   ELSE 0
                               END
                           ) ytwsje,
                        SUM(   CASE
                                   WHEN r.Status = '认购' THEN
                                        1
                                   ELSE 0
                               END
                           ) rgwqyts,
                        SUM(   CASE
                                   WHEN r.Status = '认购' THEN
                                        r.BldArea
                                   ELSE 0
                               END
                           ) rgwqymj,
                        SUM(   CASE
                                   WHEN t.saletype = '认购' THEN
                                        ISNULL(t.JyTotal, 0) + ISNULL(bc.bc, 0)
                                   ELSE 0
                               END
                           ) rgwqyje
				 into #svb_room1
                 FROM #svb_Room r
                      LEFT JOIN p_room pr ON r.RoomGUID = pr.RoomGUID
                      LEFT JOIN
                      (
                          SELECT TradeGUID,
                                 RoomGUID,
                                 saletype,
                                 JyTotal
                          FROM #svb_Contract
                          WHERE Status = '激活'
                          UNION
                          SELECT TradeGUID,
                                 RoomGUID,
                                 saletype,
                                 JyTotal
                          FROM #svb_Order
                          WHERE Status = '激活'
                      ) t ON r.RoomGUID = t.RoomGUID
                             AND t.saletype IN ( '认购', '合同' )
                      LEFT JOIN
                      (SELECT TradeGUID, SUM(Amount) bc FROM #svb_Fee GROUP BY TradeGUID) bc ON bc.TradeGUID = t.TradeGUID
                      LEFT JOIN #svb_ld vl ON vl.ImportSaleBldGUID = r.BldGUID
                      LEFT JOIN #dj d ON d.SaleBldGUID = vl.SaleBldGUID
                 WHERE r.BldGUID NOT IN (
                                            SELECT SaleBldGUID FROM #tsyj
                                        )
                       --AND r.BldGUID NOT IN (
                       --                         SELECT SaleBldGUID FROM #HZYJ
                       --                     )    ---取消合作业绩过滤20240829
                 GROUP BY r.BldGUID

				 
    UPDATE a
    SET a.wtmj = isnull(a.wtmj,0) - isnull(b.ysmj,0),
        a.wtts = ISNULL(a.wtts, 0) - ISNULL(b.ysts, 0)
    FROM #HZYJ a
         INNER JOIN #svb_Room1 b ON a.SaleBldGUID = b.BldGUID;


    --已售、已推未售、未推、总可售、认购未签约，   
    ----20190420 lirui 附属房间需要判断  
    SELECT cpld.SaleBldGUID,
           cpld.ProductType,
           SUM(ISNULL(cpld.HouseNum, 0)) HouseNum,
           SUM(ISNULL(cpld.BldHouseNum, 0)) AS BldHouseNum,
           SUM(ISNULL(cpld.QHRate, 0)) QHRate,
           SUM(ISNULL(cpld.RoomCount, 0)) RoomCount,
           SUM(ISNULL(cpld.SaleRoomCount, 0)) SaleRoomCount,
           SUM(ISNULL(b.ysts, 0)) ysts,
           SUM(ISNULL(b.ysmj, 0)) ysmj,
           SUM(ISNULL(b.ytwsmj, 0) + ISNULL(b.rgwqymj, 0)) ytwsmj,
           SUM(ISNULL(b.ytwsts, 0) + ISNULL(b.rgwqyts, 0)) ytwsts,
           SUM(   CASE
                      WHEN ISNULL(b.ysmj, 0) + ISNULL(b.ytwsmj, 0) + ISNULL(b.rgwqymj, 0) + ISNULL(b.wtmj, 0) <> 0 THEN
                           ISNULL(b.wtmj, 0)
                      ELSE ISNULL(cpld.SaleArea, 0) * cpld.QHRate
                  END
              ) wtmj,
           SUM(   CASE
                      WHEN ISNULL(b.ysts, 0) + ISNULL(b.ytwsts, 0) + ISNULL(b.rgwqyts, 0) + ISNULL(b.wtts, 0) <> 0 THEN
                           ISNULL(b.wtts, 0)
                      ELSE (cpld.HouseNum) * cpld.QHRate
                  END
              ) wtts,
           SUM(   CASE
                      WHEN cpld.ProductType = '地下室/车库' THEN
                           0
                      ELSE
                  (CASE
                       WHEN ISNULL(b.ysmj, 0) + ISNULL(b.ytwsmj, 0) + ISNULL(b.rgwqymj, 0) + ISNULL(b.wtmj, 0) <> 0 THEN
                            ISNULL(b.wtmj, 0)
                       ELSE ISNULL(cpld.SaleArea, 0)
                   END
                  ) * ISNULL(d.ycprice, 0)
                  END
              ) wtje,
           SUM(   CASE
                      WHEN cpld.ProductType = '地下室/车库' THEN
                           CASE
                               WHEN cpld.RoomCount = 0 --判断是否有房间
                  THEN
                                    CEILING(cpld.SaleArea * cpld.QHRate) --楼栋面积×楼栋去化率
                               WHEN cpld.RoomCount > 0
                                    AND cpld.SaleRoomCount > 0 THEN
                                    cpld.RoomArea * cpld.QHRate          --房间面积×楼栋去化率
                               ELSE 0
                           END
                      ELSE ISNULL(b.ysmj, 0) + ISNULL(b.ytwsmj, 0) + ISNULL(b.rgwqymj, 0)
                           + CASE
                                 WHEN ISNULL(b.ysmj, 0) + ISNULL(b.ytwsmj, 0) + ISNULL(b.rgwqymj, 0)
                                      + ISNULL(b.wtmj, 0) <> 0 THEN
                                      ISNULL(b.wtmj, 0)
                                 ELSE ISNULL(cpld.SaleArea, 0)
                             END
                  END
              ) zksmj,
           SUM(   CASE
                      WHEN cpld.ProductType = '地下室/车库' THEN
                           CASE
                               WHEN cpld.RoomCount = 0 --判断是否有房间
                  THEN
                                    CEILING(cpld.HouseNum * cpld.QHRate)  --楼栋户个数×楼栋去化率
                               WHEN cpld.RoomCount > 0
                                    AND cpld.SaleRoomCount > 0 THEN
                                    CEILING(cpld.RoomCount * cpld.QHRate) --楼栋房间个数×楼栋去化率
                               ELSE 0
                           END
                      ELSE ISNULL(b.ysts, 0) + ISNULL(b.ytwsts, 0) + ISNULL(b.rgwqyts, 0)
                           + CASE
                                 WHEN ISNULL(b.ysts, 0) + ISNULL(b.ytwsts, 0) + ISNULL(b.rgwqyts, 0)
                                      + ISNULL(b.wtts, 0) <> 0 THEN
                                      ISNULL(b.wtts, 0)
                                 ELSE ISNULL(cpld.HouseNum, 0)
                             END
                  END
              ) zksts,
           SUM(   ISNULL(b.ysje, 0) + ISNULL(ty.ysje, 0) + ISNULL(tyr.ysje, 0) + ISNULL(b.ytwsje, 0)
                  + ISNULL(b.rgwqyje, 0)
                  + --已推未售金额(包含认购未签约金额)
                  ((CASE
                        WHEN ISNULL(b.ysmj, 0) + ISNULL(b.ytwsmj, 0) + ISNULL(b.rgwqymj, 0) + ISNULL(b.wtmj, 0) <> 0 THEN
                             CASE
                                 WHEN cpld.ProductType = '地下室/车库' THEN
                                      ISNULL(b.wtts, 0)
                                 ELSE ISNULL(b.wtmj, 0)
                             END --有房间取未推房间 × 预测价
                        ELSE (CASE
                                  WHEN cpld.ProductType = '地下室/车库' THEN
                                       ISNULL(cpld.HouseNum, 0) * cpld.QHRate
                                  ELSE ISNULL(cpld.SaleArea, 0)
                              END
                             )
                    END
                   ) * ISNULL(d.hzdj, 0) --未推面积*预测价=未推金额
                  )
              ) AS Zhz,
           SUM(ISNULL(b.ysje, 0) + ISNULL(ty.ysje, 0) + ISNULL(tyr.ysje, 0)) ysje,
           SUM(ISNULL(b.ytwsje, 0) + ISNULL(b.rgwqyje, 0)) AS ytwsje,
           SUM(ISNULL(b.rgwqyts, 0)) rgwqyts,
           SUM(ISNULL(b.rgwqymj, 0)) rgwqymj,
           SUM(ISNULL(b.rgwqyje, 0)) rgwqyje
    INTO #svb_mj
    FROM #svb_ld cpld
         LEFT JOIN #dj d ON d.SaleBldGUID = cpld.SaleBldGUID
         LEFT JOIN
         (
             SELECT t.BldGUID,
                    SUM(t.ysts) ysts,
                    SUM(t.ysmj) ysmj,
                    SUM(t.ytwsmj) ytwsmj,
                    SUM(t.ytwsts) ytwsts,
                    SUM(t.wtmj) wtmj,
                    SUM(t.wtts) wtts,
                    SUM(t.ysje) ysje,
                    SUM(t.ytwsje) ytwsje,
                    SUM(t.rgwqyts) rgwqyts,
                    SUM(t.rgwqymj) rgwqymj,
                    SUM(t.rgwqyje) rgwqyje
             FROM
             (
                 SELECT r.BldGUID,
                        SUM(   CASE
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.Status IN ( '签约' ) THEN
                                        1
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND pr.RoomGUID IS NOT NULL
                                        AND r.Status IN ( '签约' ) THEN
                                        1 --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) ysts,
                        SUM(   CASE
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.Status IN ( '签约' ) THEN
                                        r.BldArea
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND pr.RoomGUID IS NOT NULL
                                        AND r.Status IN ( '签约' ) THEN
                                        r.BldArea --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) ysmj,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN (r.Status NOT IN ( '认购', '签约' ))
                                        AND r.ThDate IS NOT NULL THEN
                                        r.BldArea
                                   ELSE 0
                               END
                           ) ytwsmj,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN (r.Status NOT IN ( '认购', '签约' ))
                                        AND r.ThDate IS NOT NULL THEN
                                        1
                                   ELSE 0
                               END
                           ) ytwsts,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' ) THEN
                                        r.BldArea
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' )
                                        AND pr.RoomGUID IS NOT NULL THEN
                                        r.BldArea --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) wtmj,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' ) THEN
                                        1
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND r.ThDate IS NULL
                                        AND r.Status NOT IN ( '认购', '签约' )
                                        AND pr.RoomGUID IS NOT NULL THEN
                                        1 --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) wtts,
                        SUM(   CASE
                                   WHEN vl.ProductType = '地下室/车库'
                                        AND r.Status IN ( '签约' ) THEN
                                        ISNULL(t.JyTotal, 0) + ISNULL(bc.bc, 0)
                                   WHEN vl.ProductType <> '地下室/车库'
                                        AND r.Status IN ( '签约' )
                                        AND pr.RoomGUID IS NOT NULL THEN
                                        ISNULL(t.JyTotal, 0) + ISNULL(bc.bc, 0) --非车位必须是销售房间
                                   ELSE 0
                               END
                           ) ysje,
                        SUM(   CASE
									when r.isHZYJ = 1 then 0 
                                   WHEN (
                                            t.TradeGUID IS NULL
                                            AND r.Status NOT IN ( '签约' )
                                        )
                                        AND r.ThDate IS NOT NULL THEN
                                        CASE
                                            WHEN ISNULL(r.HSZJ, 0) < 1000 THEN
                                                 r.Total
                                            ELSE r.HSZJ
                                        END
                                   ELSE 0
                               END
                           ) ytwsje,
                        SUM(   CASE
                                   WHEN r.Status = '认购' THEN
                                        1
                                   ELSE 0
                               END
                           ) rgwqyts,
                        SUM(   CASE
                                   WHEN r.Status = '认购' THEN
                                        r.BldArea
                                   ELSE 0
                               END
                           ) rgwqymj,
                        SUM(   CASE
                                   WHEN t.saletype = '认购' THEN
                                        ISNULL(t.JyTotal, 0) + ISNULL(bc.bc, 0)
                                   ELSE 0
                               END
                           ) rgwqyje
                 FROM #svb_Room r
                      LEFT JOIN p_room pr ON r.RoomGUID = pr.RoomGUID
                      LEFT JOIN
                      (
                          SELECT TradeGUID,
                                 RoomGUID,
                                 saletype,
                                 JyTotal
                          FROM #svb_Contract
                          WHERE Status = '激活'
                          UNION
                          SELECT TradeGUID,
                                 RoomGUID,
                                 saletype,
                                 JyTotal
                          FROM #svb_Order
                          WHERE Status = '激活'
                      ) t ON r.RoomGUID = t.RoomGUID
                             AND t.saletype IN ( '认购', '合同' )
                      LEFT JOIN
                      (SELECT TradeGUID, SUM(Amount) bc FROM #svb_Fee GROUP BY TradeGUID) bc ON bc.TradeGUID = t.TradeGUID
                      LEFT JOIN #svb_ld vl ON vl.ImportSaleBldGUID = r.BldGUID
                      LEFT JOIN #dj d ON d.SaleBldGUID = vl.SaleBldGUID
                 WHERE r.BldGUID NOT IN (
                                            SELECT SaleBldGUID FROM #tsyj
                                        )
                       --AND r.BldGUID NOT IN (
                       --                         SELECT SaleBldGUID FROM #HZYJ
                       --                     )    ---取消合作业绩过滤20240829
                 GROUP BY r.BldGUID
                 ---加上特殊业绩直接关联楼栋的部分
                 UNION ALL
                 SELECT SaleBldGUID,
                        SUM(ysts) AS ysts,
                        SUM(ysmj) AS ysmj,
                        SUM(ytwsmj) AS ytwsmj,
                        SUM(ytwsts) AS ytwsts,
                        SUM(wtmj) AS wtmj,
                        SUM(wtts) AS wtts,
                        SUM(ysje) AS ysje,
                        SUM(ytwsje) AS ytwsje,
                        SUM(rgwqyts) AS rgwqyts,
                        SUM(rgwqymj) AS rgwqymj,
                        SUM(rgwqyje) AS rgwqyje
                 FROM #tsyj t
                 GROUP BY SaleBldGUID
                 ---加上合作业绩关联楼栋的部分
                 UNION ALL
                 SELECT SaleBldGUID,
                        SUM(ysts) ysts,
                        SUM(ysmj) ysmj,
                        0 ytwsmj,
                        0 ytwsts,
                        SUM(wtmj) wtmj,
                        SUM(wtts) wtts,
                        --SUM(case when hz.ProjGUID in ('76FA0D74-6EC4-E711-80BA-E61F13C57837','D6251BC8-C82D-E811-80BA-E61F13C57837') then wtmj-ysmj else wtmj end) wtmj,
                        --SUM(case when hz.ProjGUID in ('76FA0D74-6EC4-E711-80BA-E61F13C57837','D6251BC8-C82D-E811-80BA-E61F13C57837') then wtts-ysts else wtts end) wtts,
                        SUM(ysje) ysje,
                        0 ytwsje,
                        0 rgwqyts,
                        0 rgwqymj,
                        0 rgwqyje
                 FROM #HZYJ hz
                 GROUP BY hz.SaleBldGUID
             ) t
             GROUP BY t.BldGUID
         ) b ON cpld.ImportSaleBldGUID = b.BldGUID
         LEFT JOIN
         (
             SELECT SaleBldGUID,
                    SUM(ysje) ysje
             FROM #tsyj_Yjk
             GROUP BY SaleBldGUID
         ) ty ON cpld.ImportSaleBldGUID = ty.SaleBldGUID
         LEFT JOIN
         (SELECT BldGUID, SUM(ysje) ysje FROM #tsyj_RoomYjk GROUP BY BldGUID) tyr ON cpld.ImportSaleBldGUID = tyr.BldGUID
    GROUP BY cpld.SaleBldGUID,
             cpld.ProductType;

    --有房间的重算总货值
    UPDATE a
    SET Zhz = (CASE
                   WHEN b.RoomCount = 0 THEN
                        CEILING(b.HouseNum * b.QHRate) * d.ycprice
                   ELSE Zhz / NULLIF(b.SaleRoomCount, 0) * CEILING(b.RoomCount * b.QHRate)
               END
              )
    FROM #svb_mj a
         INNER JOIN #svb_ld b ON b.SaleBldGUID = a.SaleBldGUID
         LEFT JOIN #dj d ON d.SaleBldGUID = b.SaleBldGUID
    WHERE a.ProductType = '地下室/车库'
          AND a.zksts <> a.ysts; --有未售的才重算

    --更新已推未售套数、面积金额,未推面积、金额
    UPDATE #svb_mj
    SET wtmj = (CASE
                    WHEN RoomCount = 0 THEN
                         zksmj - (ysmj)
                    ELSE (CASE
                              WHEN ytwsmj >= zksmj - (ysmj) THEN
                                   0
                              ELSE zksmj - (ysmj) - (ytwsmj)
                          END
                         )
                END
               ),
        wtts = (CASE
                    WHEN RoomCount = 0 THEN
                         zksts - (ysts)
                    ELSE (CASE
                              WHEN ytwsts >= zksts - (ysts) THEN
                                   0
                              ELSE zksts - (ysts) - (ytwsts)
                          END
                         )
                END
               ),
        ytwsmj = (CASE
                      WHEN RoomCount = 0 THEN
                           0
                      ELSE (CASE
                                WHEN ytwsmj >= zksmj - (ysmj) THEN
                                     zksmj - (ysmj)
                                ELSE ytwsmj
                            END
                           )
                  END
                 ),
        ytwsts = (CASE
                      WHEN RoomCount = 0 THEN
                           0
                      ELSE (CASE
                                WHEN ytwsts >= zksts - (ysts) THEN
                                     zksts - (ysts)
                                ELSE ytwsts
                            END
                           )
                  END
                 ),
        ytwsje = (CASE
                      WHEN RoomCount = 0 THEN
                           0
                      ELSE (CASE
                                WHEN ytwsmj >= zksmj - (ysmj) THEN
                                     Zhz - (ysje)
                                ELSE ytwsje
                            END
                           )
                  END
                 ),
        wtje = Zhz - (ysje) - (CASE
                                   WHEN RoomCount = 0 THEN
                                        0
                                   ELSE (CASE
                                             WHEN ytwsmj >= zksmj - (ysmj) THEN
                                                  Zhz - (ysje)
                                             ELSE ytwsje
                                         END
                                        )
                               END
                              )
    WHERE ProductType = '地下室/车库';

    --获取各楼栋最早推货时间 
    SELECT rr.ProjGUID,
           rr.BldGUID,
           MIN(Thdate) Thdate
    INTO #ldth
    FROM
    (
        SELECT p1.ProjGUID,
               r.BldGUID,
               MIN(ISNULL(r.ThDate, m.ThDate)) Thdate
        FROM p_room r
             LEFT JOIN p_room m ON r.MainRoomGUID = m.RoomGUID
             INNER JOIN p_Project p ON p.ProjGUID = r.ProjGUID
             INNER JOIN p_Project p1 ON p.ParentCode = p1.ProjCode and p1.ApplySys like '%0101%'
        --INNER JOIN #p mp ON mp.ProjGUID = p1.ProjGUID
        WHERE 1 = 1
              AND r.IsVirtualRoom = 0
        GROUP BY p1.ProjGUID,
                 r.BldGUID
        UNION ALL
        SELECT c.ProjGUID,
               a.BldGUID,
               MIN(CONVERT(DATE, b.DateYear + '-' + b.DateMonth + '-27')) thdate
        FROM dbo.s_YJRLBuildingDescript a
             INNER JOIN dbo.s_YJRLProducteDetail b ON b.ProducteDetailGUID = a.ProducteDetailGUID
             INNER JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
        --INNER JOIN #p p ON p.ProjGUID = c.ProjGUID
        WHERE b.Shenhe = '审核'
        GROUP BY c.ProjGUID,
                 a.BldGUID
        UNION ALL
        SELECT b.ManagementProjectGUID,
               a.BldGUID,
               MIN(b.RdDate) thdate
        FROM dbo.S_PerformanceAppraisalBuildings a
             INNER JOIN dbo.S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
        --INNER JOIN #p p ON b.ManagementProjectGUID = p.ProjGUID
        WHERE b.AuditStatus = '已审核'
        GROUP BY b.ManagementProjectGUID,
                 a.BldGUID
        UNION ALL
        SELECT b.ManagementProjectGUID,
               r.ProductBldGUID,
               MIN(b.RdDate) thdate
        FROM dbo.S_PerformanceAppraisalRoom a
             INNER JOIN MyCost_Erp352.dbo.md_Room r ON r.RoomGUID = a.RoomGUID
             INNER JOIN dbo.S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
        --INNER JOIN #p p ON b.ManagementProjectGUID = p.ProjGUID
        WHERE b.AuditStatus = '已审核'
        GROUP BY b.ManagementProjectGUID,
                 r.ProductBldGUID
    ) rr
    GROUP BY rr.ProjGUID,
             rr.BldGUID;

    --各楼栋最新节点  预售办理预售形象 优先取进度，如果进度没有 就取投管
    SELECT sb.SaleBldGUID,
           ISNULL(ISNULL(   jd.ddysxxDate,
                            CASE
                                WHEN jd.ddysxxjhDate IS NULL
                                     AND jd.ddysxxyjDate IS NULL
                                     AND sb.HaveSaleConditionDate < GETDATE() THEN
                                     sb.HaveSaleConditionDate
                            END
                        ),
                  r.ThDate
                 ) ddysxxDate,
           ISNULL(ISNULL(ISNULL(   jd.ysblDate,
                                   CASE
                                       WHEN jd.ysblyjDate IS NULL
                                            AND jd.ysbljhDate IS NULL
                                            AND sb.YszGetDate < GETDATE() THEN
                                            sb.YszGetDate
                                   END
                               ),
                         r.ThDate
                        ),
                  gb.JgbabFactDate
                 ) ysblDate,
           ISNULL(
                     ISNULL(jd.ddysxxyjDate, jd.ddysxxjhDate),
                     CASE
                         WHEN ISNULL(sb.HaveSaleConditionDate, CAST('2999-01-01' AS DATETIME)) > GETDATE() THEN
                              sb.HaveSaleConditionDate
                         ELSE gb.SgzgcysjdPlanDate
                     END
                 ) ddysxxyjDate,
           ISNULL(
                     ISNULL(jd.ysblyjDate, jd.ysbljhDate),
                     CASE
                         WHEN ISNULL(sb.YszGetDate, CAST('2999-01-01' AS DATETIME)) > GETDATE() THEN
                              sb.YszGetDate
                         ELSE gb.YszPlanDate
                     END
                 ) ysblyjDate,

           ----增加未容错的实际节点 by yp
           ISNULL(   jd.ddysxxDate,
                     CASE
                         WHEN jd.ddysxxjhDate IS NULL
                              AND jd.ddysxxDate IS NULL
                              AND sb.HaveSaleConditionDate < GETDATE() THEN
                              sb.HaveSaleConditionDate
                     END
                 ) Realysxx,
           ISNULL(   jd.ysblDate,
                     CASE
                         WHEN jd.ysblDate IS NULL
                              AND jd.ysbljhDate IS NULL
                              AND sb.YszGetDate < GETDATE() THEN
                              sb.YszGetDate
                     END
                 ) Realysbl,
           ------------------------------------------改为货量铺排逻辑 end ----------------------------------------------------------------
           ISNULL(a.zskgDate, gb.BuildBeginFactDate) zskgdate,
           ISNULL(ISNULL(a.zskgyjDate, a.zskgjhDate), gb.BuildBeginPlanDate) zskgyjdate,
           ISNULL(a.jgbaDate, gb.JgbabFactDate) jgbadate,
           ISNULL(ISNULL(a.jgbayjDate, a.jgbajhDate), gb.JgbabPlanDate) jgbayjdate,
           --ISNULL(r.ThDate, a.kpxsDate) kpxsDate ,
           a.kpxsDate,
           ISNULL(a.kpxsyjDate, a.kpxsjhDate) kpxsyjDate,
           a.jzjfyjdate,
           a.jzjfsjdate,
           a.SgzZf0yj,
           a.SgzZf0sj,
           a.ShgdtzYjdate,
           a.ShgdtzSjdate,
           a.XjlhzYjdate,
           a.XjlhzSjdate,
           ISNULL(a.SGZsjdate, gb.SgzFactDate) SGZsjdate,
           ISNULL(ISNULL(a.SGZyjdate, a.SGZjhdate), gb.SgzPlanDate) SGZyjdate
    INTO #svb_jd
    FROM #svb_ld sb
         LEFT JOIN #ldth t ON t.BldGUID = sb.SaleBldGUID
         LEFT JOIN
         (SELECT BldGUID, MIN(ThDate) ThDate FROM #svb_Room GROUP BY BldGUID) r ON r.BldGUID = sb.ImportSaleBldGUID
         LEFT JOIN mdm_GCBuild gb ON sb.GCBldGUID = gb.GCBldGUID
         LEFT JOIN
         (
             SELECT jcjh.BuildingGUID,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '正式开工' THEN
                                    a.ActualFinish --实际完成时间  
                               ELSE NULL
                           END
                       ) SGZsjdate,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '正式开工' THEN
                                    a.ExpectedFinishDate
                               ELSE NULL
                           END
                       ) SGZyjdate,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '正式开工' THEN
                                    a.Finish
                               ELSE NULL
                           END
                       ) SGZjhdate,    --预计完成时间
                    MAX(   CASE
                               WHEN a.KeyNodeName = '实际开工' THEN
                                    a.ActualFinish --实际完成时间  
                               ELSE NULL
                           END
                       ) zskgDate,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '实际开工' THEN
                                    a.Finish
                               ELSE NULL
                           END
                       ) zskgjhDate,   --预计完成时间  
                    MAX(   CASE
                               WHEN a.KeyNodeName = '实际开工' THEN
                                    a.ExpectedFinishDate
                               ELSE NULL
                           END
                       ) zskgyjDate,   --汇报预计完成时间      
                    MAX(   CASE
                               WHEN a.KeyNodeName = '开盘销售' THEN
                                    a.ActualFinish --实际完成时间  
                               ELSE NULL
                           END
                       ) kpxsDate,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '开盘销售' THEN
                                    a.Finish
                               ELSE NULL
                           END
                       ) kpxsjhDate,   --预计完成时间  
                    MAX(   CASE
                               WHEN a.KeyNodeName = '开盘销售' THEN
                                    a.ExpectedFinishDate
                               ELSE NULL
                           END
                       ) kpxsyjDate,   --汇报预计完成时间   
                    MAX(   CASE
                               WHEN a.KeyNodeName = '竣工备案' THEN
                                    a.ActualFinish --实际完成时间  
                               ELSE NULL
                           END
                       ) jgbaDate,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '竣工备案' THEN
                                    a.Finish
                               ELSE NULL
                           END
                       ) jgbajhDate,   --预计完成时间  
                    MAX(   CASE
                               WHEN a.KeyNodeName = '竣工备案' THEN
                                    a.ExpectedFinishDate
                               ELSE NULL
                           END
                       ) jgbayjDate,   --汇报预计完成时间 
                    MAX(   CASE
                               WHEN a.KeyNodeName = '集中交付' THEN
                                    ISNULL(a.ExpectedFinishDate, a.Finish)
                               ELSE NULL
                           END
                       ) jzjfyjdate,   --预计完成时间  
                    MAX(   CASE
                               WHEN a.KeyNodeName = '集中交付' THEN
                                    a.ActualFinish
                               ELSE NULL
                           END
                       ) jzjfsjdate,   ---实际完成时间 
                    MAX(   CASE
                               WHEN a.KeyNodeName = '地下结构完成' THEN
                                    ISNULL(a.ExpectedFinishDate, a.Finish)
                               ELSE NULL
                           END
                       ) SgzZf0yj,     --预计完成时间  
                    MAX(   CASE
                               WHEN a.KeyNodeName = '地下结构完成' THEN
                                    a.ActualFinish
                               ELSE NULL
                           END
                       ) SgzZf0sj,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '收回股东投资' THEN
                                    ISNULL(a.ExpectedFinishDate, a.Finish)
                               ELSE NULL
                           END
                       ) ShgdtzYjdate, --预计完成时间  
                    MAX(   CASE
                               WHEN a.KeyNodeName = '收回股东投资' THEN
                                    a.ActualFinish
                               ELSE NULL
                           END
                       ) ShgdtzSjdate,
                    MAX(   CASE
                               WHEN a.KeyNodeName = '现金流回正' THEN
                                    ISNULL(a.ExpectedFinishDate, a.Finish)
                               ELSE NULL
                           END
                       ) XjlhzYjdate,  --预计完成时间  
                    MAX(   CASE
                               WHEN a.KeyNodeName = '现金流回正' THEN
                                    a.ActualFinish
                               ELSE NULL
                           END
                       ) XjlhzSjdate
             FROM
             (
                 SELECT c.ObjectID,
                        tc.Finish,
                        tc.ActualFinish,
                        tc.ExpectedFinishDate,
                        kn.KeyNodeName,
                        kn.KeyNodeCode,
                        c.ProjGUID
                 FROM MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute tc
                      INNER JOIN MyCost_Erp352.dbo.jd_ProjectPlanExecute c ON c.ID = tc.PlanID
                      INNER JOIN MyCost_Erp352.dbo.jd_KeyNode kn ON kn.KeyNodeGUID = tc.KeyNodeID
                 WHERE c.PlanType = 103
                       AND c.IsExamin = 1
                       AND kn.KeyNodeName IN ( '达到预售形象', '预售办理', '正式开工', '实际开工', '开盘销售', '竣工备案', '集中交付', '地下结构完成',
                                               '收回股东投资', '现金流回正'
                                             )
             ) a
             LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuildingWork jhbld ON a.ObjectID = jhbld.BuildGUID
             LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork jcjh ON jcjh.BudGUID = jhbld.BuildGUID
             GROUP BY jcjh.BuildingGUID
         ) a ON a.BuildingGUID = sb.GCBldGUID
         LEFT JOIN
         (
             SELECT tc.SaleBldGUID,
                    MAX(   CASE
                               WHEN kn.KeyNodeName = '达到预售形象' THEN
                                    tc.ActualFinish --实际完成时间  
                               ELSE NULL
                           END
                       ) ddysxxDate,
                    MAX(   CASE
                               WHEN kn.KeyNodeName = '达到预售形象' THEN
                                    tc.Finish
                               ELSE NULL
                           END
                       ) ddysxxjhDate, --计划完成时间  
                    MAX(   CASE
                               WHEN kn.KeyNodeName = '达到预售形象' THEN
                                    tc.ExpectedFinishDate
                               ELSE NULL
                           END
                       ) ddysxxyjDate, --汇报预计完成时间      
                    MAX(   CASE
                               WHEN kn.KeyNodeName = '预售办理' THEN
                                    tc.ActualFinish
                               ELSE NULL
                           END
                       ) ysblDate,
                    MAX(   CASE
                               WHEN kn.KeyNodeName = '预售办理' THEN
                                    tc.Finish
                               ELSE NULL
                           END
                       ) ysbljhDate,
                    MAX(   CASE
                               WHEN kn.KeyNodeName = '预售办理' THEN
                                    tc.ExpectedFinishDate
                               ELSE NULL
                           END
                       ) ysblyjDate    --汇报预计完成时间  
             FROM MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute tc
                  INNER JOIN MyCost_Erp352.dbo.jd_ProjectPlanExecute c ON c.ID = tc.PlanID
                  INNER JOIN MyCost_Erp352.dbo.jd_KeyNode kn ON kn.KeyNodeGUID = tc.KeyNodeID
             WHERE c.PlanType = 103
                   AND c.IsExamin = 1
                   AND tc.Level = 2
                   AND kn.KeyNodeName IN ( '达到预售形象', '预售办理' )
             GROUP BY tc.SaleBldGUID
         ) jd ON jd.SaleBldGUID = sb.SaleBldGUID;

    --本月、本年认购面积、金额      
    SELECT SUM(b.byts) AS ThisMonthSaleTsRg,
           SUM(b.bymj) AS ThisMonthSaleMjRg,
           SUM(b.byje) AS ThisMonthSaleJeRg,
           SUM(b.ts) AS ThisYearSaleTsRg,
           SUM(b.mj) AS ThisYearSaleMjRg,
           SUM(b.je) AS ThisYearSaleJeRg,
           a.ProjGUID,
           a.SaleBldGUID
    INTO #ThisYearSaleRg
    FROM #svb_ld a
         LEFT JOIN
         (
             SELECT sb.ProjGUID,
                    sb.SaleBldGUID,
                    SUM(   CASE
                               WHEN MONTH(QSDate) = MONTH(GETDATE()) THEN
                                    1
                               ELSE 0
                           END
                       ) byts,
                    SUM(   CASE
                               WHEN MONTH(QSDate) = MONTH(GETDATE()) THEN
                                    r.BldArea
                               ELSE 0
                           END
                       ) bymj,
                    SUM(   CASE
                               WHEN MONTH(QSDate) = MONTH(GETDATE()) THEN
                                    a.JyTotal
                               ELSE 0
                           END
                       ) byje,
                    SUM(1) ts,
                    SUM(r.BldArea) mj,
                    SUM(a.JyTotal) je
             FROM
             (
                 SELECT o.RoomGUID,
                        o.QSDate,
                        ISNULL(o.JyTotal, 0) + ISNULL(f.bc, 0) JyTotal
                 FROM #svb_Order o
                      LEFT JOIN
                      (
                          SELECT f.TradeGUID,
                                 SUM(f.Amount) bc
                          FROM #svb_Fee f
                          GROUP BY f.TradeGUID
                      ) f ON f.TradeGUID = o.TradeGUID
                      LEFT JOIN #svb_Contract c ON c.TradeGUID = o.TradeGUID ---用lastsaleguid关联 有问题
                 WHERE 1 = 1
                       AND
                       (
                           o.Status = '激活'
                           OR
                           (
                               o.CloseReason = '转签约'
                               AND c.Status = '激活'
                           )
                       )
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
             ) a
             LEFT JOIN #svb_Room r ON r.RoomGUID = a.RoomGUID
             LEFT JOIN #svb_ld sb ON r.BldGUID = ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID)
             LEFT JOIN #dj dj ON dj.SaleBldGUID = sb.SaleBldGUID
             GROUP BY sb.ProjGUID,
                      sb.SaleBldGUID
             --加特殊业绩
             UNION ALL
             SELECT projguid,
                    SaleBldGUID,
                    SUM(   CASE
                               WHEN t.RdDateMonth = MONTH(GETDATE()) THEN
                                    t.ysts
                               ELSE 0
                           END
                       ) byts,
                    SUM(   CASE
                               WHEN t.RdDateMonth = MONTH(GETDATE()) THEN
                                    t.ysmj
                               ELSE 0
                           END
                       ) bymj,
                    SUM(   CASE
                               WHEN t.RdDateMonth = MONTH(GETDATE()) THEN
                                    t.ysje
                               ELSE 0
                           END
                       ) byje,
                    SUM(ISNULL(t.ysts, 0)) ts,
                    SUM(ISNULL(t.ysmj, 0)) mj,
                    SUM(ISNULL(t.ysje, 0)) je
             FROM #tsyj t
             WHERE t.RdDateYear = YEAR(GETDATE())
             GROUP BY t.projguid,
                      t.SaleBldGUID
             --加合作业绩
             UNION ALL
             SELECT ProjGUID,
                    SaleBldGUID,
                    SUM(   CASE
                               WHEN DATEDIFF(m, RdDate, GETDATE()) = 0 THEN
                                    ysts
                               ELSE 0
                           END
                       ) byts,
                    SUM(   CASE
                               WHEN DATEDIFF(m, RdDate, GETDATE()) = 0 THEN
                                    ysmj
                               ELSE 0
                           END
                       ) bymj,
                    SUM(   CASE
                               WHEN DATEDIFF(m, RdDate, GETDATE()) = 0 THEN
                                    ysje
                               ELSE 0
                           END
                       ) byje,
                    SUM(ysts) ts,
                    SUM(ysmj) mj,
                    SUM(ysje) je
             FROM #s_YJRLBuildingDescript hz
             WHERE DATEDIFF(YEAR, RdDate, GETDATE()) = 0
             GROUP BY ProjGUID,
                      SaleBldGUID
         ) b ON a.ProjGUID = b.ProjGUID
                AND a.SaleBldGUID = b.SaleBldGUID
    GROUP BY a.ProjGUID,
             a.SaleBldGUID;


    --本月、本年签约面积、金额                
    SELECT SUM(b.byts) AS ThisMonthSaleTsQY,
           SUM(b.bymj) AS ThisMonthSaleMjQY,
           SUM(b.byje) AS ThisMonthSaleJeQY,
           SUM(b.ts) AS ThisYearSaleTsQY,
           SUM(b.mj) AS ThisYearSaleMjQY,
           SUM(b.je) AS ThisYearSaleJeQY,
           a.ProjGUID,
           a.SaleBldGUID
    INTO #ThisYearSaleQY
    FROM #svb_ld a
         LEFT JOIN
         (
             SELECT sb.ProjGUID,
                    sb.SaleBldGUID,
                    SUM(   CASE
                               WHEN MONTH(QSDate) = MONTH(GETDATE()) THEN
                                    1
                               ELSE 0
                           END
                       ) byts,
                    SUM(   CASE
                               WHEN MONTH(QSDate) = MONTH(GETDATE()) THEN
                                    r.BldArea
                               ELSE 0
                           END
                       ) bymj,
                    SUM(   CASE
                               WHEN MONTH(QSDate) = MONTH(GETDATE()) THEN
                                    a.JyTotal
                               ELSE 0
                           END
                       ) byje,
                    SUM(1) ts,
                    SUM(r.BldArea) mj,
                    SUM(a.JyTotal) je
             FROM
             (
                 SELECT o.RoomGUID,
                        o.QSDate,
                        ISNULL(o.JyTotal, 0) + ISNULL(f.bc, 0) JyTotal
                 FROM #svb_Contract o
                      LEFT JOIN
                      (
                          SELECT f.TradeGUID,
                                 SUM(f.Amount) bc
                          FROM #svb_Fee f
                          GROUP BY f.TradeGUID
                      ) f ON f.TradeGUID = o.TradeGUID
                 WHERE 1 = 1
                       AND o.Status = '激活'
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
             ) a
             LEFT JOIN #svb_Room r ON r.RoomGUID = a.RoomGUID
             LEFT JOIN #svb_ld sb ON r.BldGUID = ISNULL(sb.ImportSaleBldGUID, sb.SaleBldGUID)
             LEFT JOIN #dj dj ON dj.SaleBldGUID = sb.SaleBldGUID
             GROUP BY sb.ProjGUID,
                      sb.SaleBldGUID
             --加特殊业绩
             UNION ALL
             SELECT projguid,
                    SaleBldGUID,
                    SUM(   CASE
                               WHEN t.RdDateMonth = MONTH(GETDATE()) THEN
                                    t.ysts
                               ELSE 0
                           END
                       ) byts,
                    SUM(   CASE
                               WHEN t.RdDateMonth = MONTH(GETDATE()) THEN
                                    t.ysmj
                               ELSE 0
                           END
                       ) bymj,
                    SUM(   CASE
                               WHEN t.RdDateMonth = MONTH(GETDATE()) THEN
                                    t.ysje
                               ELSE 0
                           END
                       ) byje,
                    SUM(ISNULL(t.ysts, 0)) ts,
                    SUM(ISNULL(t.ysmj, 0)) mj,
                    SUM(ISNULL(t.ysje, 0)) je
             FROM #tsyj t
             WHERE t.RdDateYear = YEAR(GETDATE())
             GROUP BY t.projguid,
                      t.SaleBldGUID
             --加合作业绩
             UNION ALL
             SELECT ProjGUID,
                    SaleBldGUID,
                    SUM(   CASE
                               WHEN DATEDIFF(m, RdDate, GETDATE()) = 0 THEN
                                    ysts
                               ELSE 0
                           END
                       ) byts,
                    SUM(   CASE
                               WHEN DATEDIFF(m, RdDate, GETDATE()) = 0 THEN
                                    ysmj
                               ELSE 0
                           END
                       ) bymj,
                    SUM(   CASE
                               WHEN DATEDIFF(m, RdDate, GETDATE()) = 0 THEN
                                    ysje
                               ELSE 0
                           END
                       ) byje,
                    SUM(ysts) ts,
                    SUM(ysmj) mj,
                    SUM(ysje) je
             FROM #s_YJRLBuildingDescript hz
             WHERE DATEDIFF(YEAR, RdDate, GETDATE()) = 0
             GROUP BY ProjGUID,
                      SaleBldGUID
         ) b ON a.ProjGUID = b.ProjGUID
                AND a.SaleBldGUID = b.SaleBldGUID
    GROUP BY a.ProjGUID,
             a.SaleBldGUID;


    --删除除周一外七天前的数据,保留每月1号的数据,保留每年年底的数据              
    DELETE FROM dbo.p_lddbamj
    WHERE DATEDIFF(DAY, QXDate, GETDATE()) = 0
          OR
          (
              DATENAME(WEEKDAY, QXDate) <> '星期一'
              AND DATEPART(DAY, QXDate) <> 1
              AND DATEDIFF(DAY, QXDate, CONVERT(VARCHAR(4), YEAR(qxdate)) + '-12-31') <> 0
			  and datediff(day,QXDate,dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,qxdate)+1, 0)) ) <>0
              AND DATEDIFF(DAY, QXDate, GETDATE()) > 7
          );



    --插入数据到楼栋底表(临时表)  
    INSERT INTO dbo.p_lddbamj
    (
        DevelopmentCompanyGUID,
        ProjGUID,
        SaleBldGUID,
        ProductGUID,
        GCBldGUID,
        ProductType,
        ProductName,
        BusinessType,
        Standard,
        YtName,
        YtCode,
        BldCode,
        zksmj,
        zksts,
        ysts,
        ysmj,
        ysje,
        ytwsts,
        ytwsmj,
        ytwsje,
        wtmj,
        rgwqyts,
        rgwqymj,
        rgwqyje,
        LxPrice,
        DwPrice,
        YcPrice,
        PlanPrice,
        qyjj,
        hzdj,
        zhz,
        syhz,
        ThisYearSaleTsRg,
        ThisYearSaleMjRg,
        ThisYearSaleJeRg,
        ThisMonthSaleTsRg,
        ThisMonthSaleMjRg,
        ThisMonthSaleJeRg,
        ThisYearSaleTsQY,
        ThisYearSaleMjQY,
        ThisYearSaleJeQY,
        ThisMonthSaleTsQY,
        ThisMonthSaleMjQY,
        ThisMonthSaleJeQY,
        BeginYearSaleMj,
        BeginYearSaleTs,
        BeginYearSaleJe,
        YjDdysxxDate,
        SjDdysxxDate,
        YjYsblDate,
        SjYsblDate,
        YJzskgdate,
        SJzskgdate,
        YJkpxsDate,
        SJkpxsDate,
        YJjgbadate,
        SJjgbadate,
        JzjfYjdate,
        JzjfSjdate,
        SgzZf0yj,
        SgzZf0sj,
        ShgdtzYjdate,
        ShgdtzSjdate,
        XjlhzYjdate,
        XjlhzSjdate,
        QXDate,
        IsSale,
        IsHold,
        Realysxx,
        Realysbl,
        SGZsjdate,
        SGZyjdate,
        Realysxx_th,
        Realysbl_th
    )
    SELECT sb.DevelopmentCompanyGUID,
           sb.ProjGUID,
           sb.SaleBldGUID,
           sb.ProductGUID,
           sb.GCBldGUID,
           sb.ProductType,
           sb.ProductName,
           sb.BusinessType,
           sb.[Standard],
           sb.Remark YtName,
           sb.YtCode,
           sb.BldCode,
           ISNULL(mj.zksmj, 0),
           mj.zksts,
           mj.ysts,
           mj.ysmj,
           mj.ysje,
           mj.ytwsts,
           mj.ytwsmj,
           mj.ytwsje,
           mj.wtmj,
           mj.rgwqyts,
           mj.rgwqymj,
           mj.rgwqyje,
           dj.lxprice AS LxPrice,
           dj.dwprice AS DwPrice,
           dj.ycprice AS YcPrice,
           dj.PlanPrice AS PlanPrice,
           dj.qyjj AS bnqyjj,
           dj.hzdj AS hzdj,
           ---计算货量逻辑调整 >100 认为是套价，<100时 认为是面积价
           CASE
               WHEN sb.ProductType = '地下室/车库'
                    AND dj.hzdj > 100 THEN
                    ISNULL(mj.ysje, 0) + ISNULL(mj.ytwsje, 0) + ISNULL(mj.wtts, 0) * ISNULL(dj.hzdj, 0)
               ELSE ISNULL(mj.ysje, 0) + ISNULL(mj.ytwsje, 0) + ISNULL(mj.wtmj, 0) * ISNULL(dj.hzdj, 0)
           END AS zhz,
           CASE
               WHEN sb.ProductType = '地下室/车库'
                    AND dj.hzdj > 100 THEN
                    ISNULL(mj.ytwsje, 0) + ISNULL(mj.wtts, 0) * ISNULL(dj.hzdj, 0)
               ELSE ISNULL(mj.ytwsje, 0) + ISNULL(mj.wtmj, 0) * ISNULL(dj.hzdj, 0)
           END AS syhz,
           ISNULL(ys.ThisYearSaleTsRg, 0) AS ThisYearSaleTsRg,
           ISNULL(ys.ThisYearSaleMjRg, 0) AS ThisYearSaleMjRg,
           ISNULL(ys.ThisYearSaleJeRg, 0) AS ThisYearSaleJeRg,
           ISNULL(ys.ThisMonthSaleTsRg, 0) AS ThisMonthSaleTsRg,
           ISNULL(ys.ThisMonthSaleMjRg, 0) AS ThisMonthSaleMjRg,
           ISNULL(ys.ThisMonthSaleJeRg, 0) AS ThisMonthSaleJeRg,
           ISNULL(qy.ThisYearSaleTsQY, 0) AS ThisYearSaleTsQY,
           ISNULL(qy.ThisYearSaleMjQY, 0) AS ThisYearSaleMjQY,
           ISNULL(qy.ThisYearSaleJeQY, 0) AS ThisYearSaleJeQY,
           ISNULL(qy.ThisMonthSaleTsQY, 0) AS ThisMonthSaleTsQY,
           ISNULL(qy.ThisMonthSaleMjQY, 0) AS ThisMonthSaleMjQY,
           ISNULL(qy.ThisMonthSaleJeQY, 0) AS ThisMonthSaleJeQY,
           ISNULL(mj.wtmj, 0) + ISNULL(mj.ytwsmj, 0) + ISNULL(qy.ThisYearSaleMjQY, 0) AS BeginYearSaleMj,
           ISNULL(mj.wtts, 0) + ISNULL(mj.ytwsts, 0) + ISNULL(qy.ThisYearSaleTsQY, 0) AS BeginYearSalets,
           ---年初可售 做车位套价判断
           CASE
               WHEN sb.ProductType = '地下室/车库'
                    AND dj.hzdj > 100 THEN
                    ISNULL(mj.ytwsje, 0) + ISNULL(mj.wtts, 0) * ISNULL(dj.hzdj, 0) + ISNULL(qy.ThisYearSaleJeQY, 0)
               ELSE ISNULL(mj.ytwsje, 0) + ISNULL(mj.wtmj, 0) * ISNULL(dj.hzdj, 0) + ISNULL(qy.ThisYearSaleJeQY, 0)
           END AS BeginYearSaleJe,
           jd.ddysxxyjDate AS YjDdysxxDate,
           jd.ddysxxDate AS SjDdysxxDate,
           jd.ysblyjDate AS YjYsblDate,
           jd.ysblDate AS SjYsblDate,
           jd.zskgyjdate,
           jd.zskgdate,
           jd.kpxsyjDate,
           jd.kpxsDate,
           jd.jgbayjdate,
           jd.jgbadate,
           jd.jzjfyjdate,
           jd.jzjfsjdate,
           jd.SgzZf0yj,
           jd.SgzZf0sj,
           jd.ShgdtzYjdate,
           jd.ShgdtzSjdate,
           jd.XjlhzYjdate,
           jd.XjlhzSjdate,
           GETDATE(),
           sb.IsSale,
           sb.IsHold,
           jd.Realysxx,
           jd.Realysbl,
           jd.SGZsjdate,
           jd.SGZyjdate,
           ------------------------------------------实际预售形象达到需考虑销售推货的节点----------------------------------------
           CASE
               WHEN t.Thdate <= ISNULL(jd.ddysxxDate, jd.ddysxxyjDate) THEN
                    t.Thdate
               WHEN jd.ddysxxDate <= ISNULL(t.Thdate, GETDATE()) THEN
                    jd.ddysxxDate
               WHEN jd.ddysxxDate IS NULL
                    AND DATEDIFF(DAY, jd.ddysxxyjDate, GETDATE()) <= 0 THEN
                    jd.ddysxxyjDate
           END Realysxx_th,
           CASE
               WHEN ISNULL(t.Thdate, '2099-12-31') < Realysbl THEN
                    t.Thdate
               ELSE Realysbl
           END Realysbl_th
    FROM #svb_ld sb
         LEFT JOIN #svb_mj mj ON mj.SaleBldGUID = sb.SaleBldGUID
         LEFT JOIN #svb_jd jd ON jd.SaleBldGUID = sb.SaleBldGUID
         LEFT JOIN #dj dj ON dj.SaleBldGUID = sb.SaleBldGUID
         LEFT JOIN #ThisYearSaleRg ys ON sb.SaleBldGUID = ys.SaleBldGUID
         LEFT JOIN #ThisYearSaleQY qy ON sb.SaleBldGUID = qy.SaleBldGUID
         LEFT JOIN #ldth t ON t.BldGUID = sb.SaleBldGUID;

    DROP TABLE #dj,
               #HZYJ,
               #jj,
               #svb_Contract,
               #svb_Fee,
               #svb_jd,
               #svb_ld,
               #svb_mj,
               #svb_Order,
               #svb_Room,
               #sy_Room,
               #S_PerformanceAppraisalBuildings,
               #S_PerformanceAppraisalRoom,
               #s_YJRLBuildingDescript,
               #ThisYearSaleQY,
               #ThisYearSaleRg,
               #tsyj,
               #Tsyj_Buildings,
               #Tsyj_Room,
               #Tsyj_RoomSum,
               #tsyj_RoomYjk,
               #tsyj_Yjk,
               #S_PerformanceAppraisal,
               #ldth;

END;

