/*
2024-12-03 特殊业绩宽表
1.其他业绩关联的房间【认购录入日期】在【取消业绩发起时间】之前，视为其他业绩
2.其他业绩关联的房间【认购录入日期】在【取消业绩发起时间】之后，视为普通业绩
*/

SELECT SalesGUID ,
       PerformanceAppraisalGUID ,
       BUGUID ,
       ParentProjGUID ,
       BldGUID ,
       RoomGUID ,
       YJMode,
       TsyjType ,
       StatisticalDate ,
       SetGqAuditTime,
       OCjAmount ,
       OCjArea ,
       OCjCount ,
       CCjAmount ,
       CCjArea ,
       CCjCount
FROM   (   SELECT a.PerformanceAppraisalGUID AS SalesGUID ,
                  a.PerformanceAppraisalGUID ,
                  a.DevelopmentCompanyGUID AS BUGUID ,
                  a.ManagementProjectGUID AS ParentProjGUID ,
                  NULL AS BldGUID ,
                  NULL AS RoomGUID ,
				  b.YJMode YJMode,
                  a.YjType AS TsyjType ,
                  a.RdDate AS StatisticalDate ,
                  a.SetGqAuditTime, --过期日期
                  ISNULL(a.TotalAmount, 0) AS OCjAmount ,
                  ISNULL(a.AreaTotal, 0) AS OCjArea ,
                  ISNULL(a.AggregateNumber, 0) AS OCjCount ,
                  ISNULL(a.TotalAmount, 0) AS CCjAmount ,
                  ISNULL(a.AreaTotal, 0) AS CCjArea ,
                  ISNULL(a.AggregateNumber, 0) AS CCjCount
           FROM   S_PerformanceAppraisal a
		   inner join s_TsyjType b on a.YjType = b.TsyjTypeName
           WHERE  a.YjType IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
                  AND a.AuditStatus = '已审核'
           UNION ALL
           SELECT b.BGUID AS SalesGUID ,
                  a.PerformanceAppraisalGUID ,
                  a.DevelopmentCompanyGUID AS BUGUID ,
                  a.ManagementProjectGUID AS ParentProjGUID ,
                  b.BldGUID AS BldGUID ,
                  NULL AS RoomGUID ,
				  c.YJMode YJMode,
                  a.YjType AS TsyjType ,
                  a.RdDate AS StatisticalDate ,
                  a.SetGqAuditTime, --过期日期
                  ISNULL(b.AmountDetermined, 0) AS OCjAmount ,
                  ISNULL(b.IdentifiedArea, 0) AS OCjArea ,
                  ISNULL(b.AffirmationNumber, 0) AS OCjCount ,
                  ISNULL(b.AmountDetermined, 0) AS CCjAmount ,
                  ISNULL(b.IdentifiedArea, 0) AS CCjArea ,
                  ISNULL(b.AffirmationNumber, 0) AS CCjCount
           FROM   S_PerformanceAppraisal a
		    inner join s_TsyjType c on a.YjType = c.TsyjTypeName
                  INNER JOIN S_PerformanceAppraisalBuildings b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
           --LEFT JOIN S_PerformanceAppraisalRoom c ON c.PerformanceAppraisalGUID=a.PerformanceAppraisalGUID
           WHERE  ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
                  AND a.AuditStatus = '已审核'
                  --AND c.PerformanceAppraisalGUID IS NULL
                  AND b.BldGUID NOT IN (  SELECT r.BldGUID
                                           FROM   S_PerformanceAppraisalRoom c
										   inner join S_PerformanceAppraisal s on c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
                                                  INNER JOIN dbo.p_room r ON c.RoomGUID = r.RoomGUID
												  where s.AuditStatus='已审核' )
           UNION ALL
           SELECT c.RGUID AS SalesGUID ,
                  a.PerformanceAppraisalGUID ,
                  a.DevelopmentCompanyGUID AS BUGUID ,
                  a.ManagementProjectGUID AS ParentProjGUID ,
                  ISNULL(rm.BldGUID,r.ProductBldGUID) AS BldGUID ,
                  c.RoomGUID AS RoomGUID ,
		    b.YJMode YJMode,
                  a.YjType AS TsyjType ,
                  a.RdDate AS StatisticalDate ,
                  a.SetGqAuditTime, --过期日期
                  ISNULL(c.AmountDetermined, 0) AS OCjAmount ,
                  ISNULL(c.IdentifiedArea, 0) AS OCjArea ,
                  ISNULL(c.AffirmationNumber, 0) AS OCjCount ,
                  ISNULL(c.AmountDetermined, 0) AS CCjAmount ,
                  ISNULL(c.IdentifiedArea, 0) AS CCjArea ,
                  ISNULL(c.AffirmationNumber, 0) AS CCjCount
           FROM   S_PerformanceAppraisal a
		   inner join s_TsyjType b on a.YjType = b.TsyjTypeName
            INNER JOIN S_PerformanceAppraisalRoom c ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
            LEFT JOIN dbo.p_room rm ON rm.RoomGUID = c.RoomGUID
            -- 存在允许关联房间的情况
            LEFT JOIN (SELECT roomguid,ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom GROUP BY roomguid,ProductBldGUID ) r ON c.RoomGUID = r.RoomGUID
            WHERE  ISNULL(a.YjType, '') NOT IN  (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
                  AND a.AuditStatus in ( '已审核','已过期' )
            -- 其他业绩关联房间【认购录入日期】在【取消业绩发起时间】之前，视为其他业绩 
            and  exists ( 
                     select  con.RoomGUID,isnull(o.CreatedOn,con.CreatedOn ) as  CreatedOn
                     from  s_Contract con
                     --inner join  S_PerformanceAppraisalRoom performanceRoom on performanceRoom.RoomGUID =c.RoomGUID
                     left join s_Order o on o.OrderType ='认购' and  con.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
                     where con.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
                     and con.roomguid = c.RoomGUID  
                     and  ( (isnull(o.CreatedOn,con.CreatedOn ) < a.SetGqAuditTime  and  a.SetGqAuditTime is not null ) or  a.SetGqAuditTime is null  )
                     union all 
                     select  o.RoomGUID,o.CreatedOn from  s_Order o 
                     where  o.Status ='激活' and  OrderType ='认购'
                     and o.roomguid = c.RoomGUID   
                     and  ( ( o.CreatedOn < a.SetGqAuditTime and a.SetGqAuditTime is not null ) or   a.SetGqAuditTime is  null )
             )
    ) appraisa


--取认购录入时间
select  c.RoomGUID,isnull(o.CreatedOn,c.CreatedOn ) as  CreatedOn
from  s_Contract c
inner join  S_PerformanceAppraisalRoom r on r.RoomGUID =c.RoomGUID
left join s_Order o on o.OrderType ='认购' and  c.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
where c.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
union all 
select  o.RoomGUID,o.CreatedOn from  s_Order o 
inner join  S_PerformanceAppraisalRoom r on r.RoomGUID =o.RoomGUID
where  o.Status ='激活' and  OrderType ='认购'

---/////////////////////////////////////////////////////////////----------
-- --- 特殊业绩宽表新增清洗规则备份
-- SELECT SalesGUID ,
--        PerformanceAppraisalGUID ,
--        BUGUID ,
--        ParentProjGUID ,
--        BldGUID ,
--        RoomGUID ,
-- 	   YJMode,
--        TsyjType ,
--        StatisticalDate ,
--        OCjAmount ,
--        OCjArea ,
--        OCjCount ,
--        CCjAmount ,
--        CCjArea ,
--        CCjCount
-- FROM   (   SELECT a.PerformanceAppraisalGUID AS SalesGUID ,
--                   a.PerformanceAppraisalGUID ,
--                   a.DevelopmentCompanyGUID AS BUGUID ,
--                   a.ManagementProjectGUID AS ParentProjGUID ,
--                   NULL AS BldGUID ,
--                   NULL AS RoomGUID ,
-- 				  b.YJMode YJMode,
--                   a.YjType AS TsyjType ,
--                   a.RdDate AS StatisticalDate ,
--                   ISNULL(a.TotalAmount, 0) AS OCjAmount ,
--                   ISNULL(a.AreaTotal, 0) AS OCjArea ,
--                   ISNULL(a.AggregateNumber, 0) AS OCjCount ,
--                   ISNULL(a.TotalAmount, 0) AS CCjAmount ,
--                   ISNULL(a.AreaTotal, 0) AS CCjArea ,
--                   ISNULL(a.AggregateNumber, 0) AS CCjCount
--            FROM   S_PerformanceAppraisal a
-- 		   inner join s_TsyjType b on a.YjType = b.TsyjTypeName
--            WHERE  a.YjType IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
--                   AND a.AuditStatus = '已审核'
--            UNION ALL
--            SELECT b.BGUID AS SalesGUID ,
--                   a.PerformanceAppraisalGUID ,
--                   a.DevelopmentCompanyGUID AS BUGUID ,
--                   a.ManagementProjectGUID AS ParentProjGUID ,
--                   b.BldGUID AS BldGUID ,
--                   NULL AS RoomGUID ,
-- 				  c.YJMode YJMode,
--                   a.YjType AS TsyjType ,
--                   a.RdDate AS StatisticalDate ,
--                   ISNULL(b.AmountDetermined, 0) AS OCjAmount ,
--                   ISNULL(b.IdentifiedArea, 0) AS OCjArea ,
--                   ISNULL(b.AffirmationNumber, 0) AS OCjCount ,
--                   ISNULL(b.AmountDetermined, 0) AS CCjAmount ,
--                   ISNULL(b.IdentifiedArea, 0) AS CCjArea ,
--                   ISNULL(b.AffirmationNumber, 0) AS CCjCount
--            FROM   S_PerformanceAppraisal a
-- 		   inner join s_TsyjType c on a.YjType = c.TsyjTypeName
--                   INNER JOIN S_PerformanceAppraisalBuildings b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
--            --LEFT JOIN S_PerformanceAppraisalRoom c ON c.PerformanceAppraisalGUID=a.PerformanceAppraisalGUID
--            WHERE  ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
--                   AND a.AuditStatus = '已审核'
--                   --AND c.PerformanceAppraisalGUID IS NULL
--                   AND b.BldGUID NOT IN (  SELECT r.BldGUID
--                                            FROM   S_PerformanceAppraisalRoom c
-- 										   inner join S_PerformanceAppraisal s on c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
--                                                   INNER JOIN dbo.p_room r ON c.RoomGUID = r.RoomGUID
-- 												  where s.AuditStatus='已审核' )
--            UNION ALL
--            SELECT c.RGUID AS SalesGUID ,
--                   a.PerformanceAppraisalGUID ,
--                   a.DevelopmentCompanyGUID AS BUGUID ,
--                   a.ManagementProjectGUID AS ParentProjGUID ,
--                   ISNULL(rm.BldGUID,r.ProductBldGUID) AS BldGUID ,
--                   c.RoomGUID AS RoomGUID ,
-- 				  b.YJMode YJMode,
--                   a.YjType AS TsyjType ,
--                   a.RdDate AS StatisticalDate ,
--                   ISNULL(c.AmountDetermined, 0) AS OCjAmount ,
--                   ISNULL(c.IdentifiedArea, 0) AS OCjArea ,
--                   ISNULL(c.AffirmationNumber, 0) AS OCjCount ,
--                   ISNULL(c.AmountDetermined, 0) AS CCjAmount ,
--                   ISNULL(c.IdentifiedArea, 0) AS CCjArea ,
--                   ISNULL(c.AffirmationNumber, 0) AS CCjCount
--            FROM   S_PerformanceAppraisal a
-- 		   inner join s_TsyjType b on a.YjType = b.TsyjTypeName
--                   INNER JOIN S_PerformanceAppraisalRoom c ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
-- 				  LEFT JOIN dbo.p_room rm ON rm.RoomGUID = c.RoomGUID
--                   --存在允许关联房间的情况
--             LEFT JOIN (SELECT roomguid,ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom GROUP BY roomguid,ProductBldGUID ) r ON c.RoomGUID = r.RoomGUID
--            WHERE  ISNULL(a.YjType, '') NOT IN  (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
--                   AND a.AuditStatus = '已审核'
-- 				   ) appraisa

