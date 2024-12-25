-- /*
-- 2024-12-03 特殊业绩宽表
-- 1.其他业绩关联的房间【认购录入日期】在【取消业绩发起时间】之前，视为其他业绩
-- 2.其他业绩关联的房间【认购录入日期】在【取消业绩发起时间】之后，视为普通业绩
-- */
-- SELECT SalesGUID ,
--        PerformanceAppraisalGUID ,
--        BUGUID ,
--        ParentProjGUID ,
--        BldGUID ,
--        RoomGUID ,
--        YJMode,
--        TsyjType ,
--        StatisticalDate ,
--        SetGqAuditTime,
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
-- 	           b.YJMode YJMode,
--                   a.YjType AS TsyjType ,
--                   a.RdDate AS StatisticalDate ,
--                   a.SetGqAuditTime, --过期日期
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
-- 		    c.YJMode YJMode,
--                   a.YjType AS TsyjType ,
--                   a.RdDate AS StatisticalDate ,
--                   a.SetGqAuditTime, --过期日期
--                   ISNULL(b.AmountDetermined, 0) AS OCjAmount ,
--                   ISNULL(b.IdentifiedArea, 0) AS OCjArea ,
--                   ISNULL(b.AffirmationNumber, 0) AS OCjCount ,
--                   ISNULL(b.AmountDetermined, 0) AS CCjAmount ,
--                   ISNULL(b.IdentifiedArea, 0) AS CCjArea ,
--                   ISNULL(b.AffirmationNumber, 0) AS CCjCount
--            FROM   S_PerformanceAppraisal a
-- 		    inner join s_TsyjType c on a.YjType = c.TsyjTypeName
--                   INNER JOIN S_PerformanceAppraisalBuildings b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
--            --LEFT JOIN S_PerformanceAppraisalRoom c ON c.PerformanceAppraisalGUID=a.PerformanceAppraisalGUID
--            WHERE  ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
--                   AND a.AuditStatus = '已审核'
--                   --AND c.PerformanceAppraisalGUID IS NULL
--                   AND b.BldGUID NOT IN (  SELECT r.BldGUID
--                                           FROM   S_PerformanceAppraisalRoom c
-- 					       inner join S_PerformanceAppraisal s on c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
--                                           INNER JOIN dbo.p_room r ON c.RoomGUID = r.RoomGUID
-- 						where s.AuditStatus  in ('已审核','已过期') )
--            UNION ALL
--            SELECT c.RGUID AS SalesGUID ,
--                   a.PerformanceAppraisalGUID ,
--                   a.DevelopmentCompanyGUID AS BUGUID ,
--                   a.ManagementProjectGUID AS ParentProjGUID ,
--                   ISNULL(rm.BldGUID,r.ProductBldGUID) AS BldGUID ,
--                   c.RoomGUID AS RoomGUID ,
-- 		    b.YJMode YJMode,
--                   a.YjType AS TsyjType ,
--                   a.RdDate AS StatisticalDate ,
--                   a.SetGqAuditTime, --过期日期
--                   ISNULL(c.AmountDetermined, 0) AS OCjAmount ,
--                   ISNULL(c.IdentifiedArea, 0) AS OCjArea ,
--                   ISNULL(c.AffirmationNumber, 0) AS OCjCount ,
--                   ISNULL(c.AmountDetermined, 0) AS CCjAmount ,
--                   ISNULL(c.IdentifiedArea, 0) AS CCjArea ,
--                   ISNULL(c.AffirmationNumber, 0) AS CCjCount
--            FROM   S_PerformanceAppraisal a
-- 		   inner join s_TsyjType b on a.YjType = b.TsyjTypeName
--             INNER JOIN S_PerformanceAppraisalRoom c ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
--             LEFT JOIN dbo.p_room rm ON rm.RoomGUID = c.RoomGUID
--             -- 存在允许关联房间的情况
--             LEFT JOIN (SELECT roomguid,ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom GROUP BY roomguid,ProductBldGUID ) r ON c.RoomGUID = r.RoomGUID
--             WHERE  ISNULL(a.YjType, '') NOT IN  (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
--                   AND a.AuditStatus in ( '已审核','已过期' )
--             --  剔除 其他业绩关联的房间【认购录入日期】在【取消业绩发起时间】之后
--             and  not  exists ( 
--                      select  con.RoomGUID,isnull(o.CreatedOn,con.CreatedOn ) as  CreatedOn
--                      from  s_Contract con
--                      inner join  S_PerformanceAppraisalRoom performanceRoom on performanceRoom.RoomGUID =con.RoomGUID
--                      left join s_Order o on o.OrderType ='认购' and  con.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
--                      where con.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
--                      and con.roomguid = c.RoomGUID  
--                      and performanceRoom.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
--                      and  (isnull(o.CreatedOn,con.CreatedOn ) > a.SetGqAuditTime  and  a.SetGqAuditTime is not null )  
--                      union all 
--                      select  o.RoomGUID,o.CreatedOn from  s_Order o 
--                      inner join  S_PerformanceAppraisalRoom performanceRoom on performanceRoom.RoomGUID =o.RoomGUID
--                      where  o.Status ='激活' and  OrderType ='认购'
--                      and o.roomguid = c.RoomGUID   
--                      and performanceRoom.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
--                      and  ( o.CreatedOn > a.SetGqAuditTime and a.SetGqAuditTime is not null ) 
--              )
--     ) appraisa


-- 查询特殊业绩房间的影响
          SELECT  c.RGUID AS SalesGUID ,
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
                  ISNULL(c.AffirmationNumber, 0) AS CCjCount,
                  sale.CreatedOn, --认购录入日期
                  case when ( sale.CreatedOn < a.SetGqAuditTime and a.SetGqAuditTime is not null  ) or   a.SetGqAuditTime is null  then '是' else '否' end as IsOtherYj
           into #SpecialPerformance
           FROM   S_PerformanceAppraisal a  with(nolock)
	    inner join s_TsyjType b with(nolock) on a.YjType = b.TsyjTypeName
            INNER JOIN S_PerformanceAppraisalRoom c with(nolock) ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
            LEFT JOIN dbo.p_room rm with(nolock) ON rm.RoomGUID = c.RoomGUID
           outer apply   ( 
                     select  con.RoomGUID,isnull(o.CreatedOn,con.CreatedOn ) as  CreatedOn
                     from  s_Contract con with(nolock)
                     inner join  S_PerformanceAppraisalRoom performanceRoom with(nolock) on performanceRoom.RoomGUID =con.RoomGUID
                     left join s_Order o on o.OrderType ='认购' and  con.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
                     where con.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
                     and con.roomguid = c.RoomGUID  
                     and performanceRoom.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                     -- and  ( (isnull(o.CreatedOn,con.CreatedOn ) < a.SetGqAuditTime  and  a.SetGqAuditTime is not null ) or  a.SetGqAuditTime is null  )
                     union all 
                     select  o.RoomGUID,o.CreatedOn 
                     from  s_Order o  with(nolock)
                     inner join  S_PerformanceAppraisalRoom performanceRoom with(nolock) on performanceRoom.RoomGUID =o.RoomGUID
                     where  o.Status ='激活' and  OrderType ='认购'
                     and o.roomguid = c.RoomGUID   
                     and performanceRoom.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                     -- and  ( ( o.CreatedOn < a.SetGqAuditTime and a.SetGqAuditTime is not null ) or   a.SetGqAuditTime is  null )
             ) sale 
            -- 存在允许关联房间的情况
            LEFT JOIN (SELECT roomguid,ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom GROUP BY roomguid,ProductBldGUID ) r ON c.RoomGUID = r.RoomGUID
            WHERE  ISNULL(a.YjType, '') NOT IN  (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0)
                  AND a.AuditStatus in ( '已审核','已过期' )

-- 查询其他业绩房间明细
select * from #SpecialPerformance
-- 统计其他业绩房间的影响
select IsOtherYj,sum(OCjCount) as OCjCount, sum(CCjCount) as CCjCount, sum(OCjAmount) as OCjAmount, sum(CCjAmount) as CCjAmount 
from  #SpecialPerformance 
group by    IsOtherYj    


 select PerformanceAppraisalGUID,RoomGUID  from   #S_PerformanceAppraisal  
 except
 select  PerformanceAppraisalGUID,RoomGUID from   [172.16.4.161].[HighData_prod].dbo.data_wide_s_SpecialPerformance

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



    --缓存处理过期特殊业绩，
    --①关联房间认购创建日期在取消业绩发起日期前，以特殊业绩认定日期作为业绩判断日期；
    --②关联房间认购创建日期在取消业绩发起日期后，按正常认购日期作为业绩判断日期
    --先获取对应的特殊业绩关联的清单
    SELECT a.PerformanceAppraisalGUID,
           s.rddate,
           r.roomguid,
           r.bldarea
    INTO #tsRoomAll
      FROM S_PerformanceAppraisalBuildings a
      LEFT JOIN p_building b  ON a.BldGUID                  = b.BldGUID
      LEFT JOIN p_room r  ON b.BldGUID                  = r.BldGUID
     INNER JOIN S_PerformanceAppraisal s
        ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
    UNION
    SELECT r.PerformanceAppraisalGUID,
           s.rddate,
           p.roomguid,
           p.bldarea
      FROM S_PerformanceAppraisalRoom r
      LEFT JOIN p_room p  ON r.roomguid                 = p.roomguid
     INNER JOIN S_PerformanceAppraisal s
        ON r.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID;



    --如果多重对接的话，取去重的数据
    SELECT roomguid,
           PerformanceAppraisalGUID,
           ROW_NUMBER() OVER (PARTITION BY roomguid ORDER BY rddate) num,
           bldarea
    INTO   #r
      FROM #tsRoomAll;

    --关联特殊业绩认定信息
    SELECT s.*,
           a.RoomGUID
    INTO   #sroom 
    FROM #r a
    INNER JOIN S_PerformanceAppraisal s  ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
AND s.auditstatus IN ( '已过期', '过期审核中' )
     WHERE a.num = 1
       AND s.yjtype NOT IN ( '物业公司车位代销', '经营类(溢价款)' );



    --处理认购表签署日期
    SELECT a.ProjGUID,
           a.OrderGUID,
           a.TradeGUID,
           a.RoomGUID,
           a.OrderType,
           CASE
                WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate), ISNULL(b.SetGqAuditTime, '1900-01-01')) > 0 THEN
                    b.rddate
                ELSE a.QSDate END QSDate,
           a.Status,
           a.JyTotal,
           a.CloseDate,
           a.CloseReason
    INTO   #s_order_new
      FROM s_order a
      LEFT JOIN #sroom b
        ON a.roomguid = b.roomguid;

    --处理签约表签署日期
    SELECT a.ProjGUID,
           a.ContractGUID,
           a.TradeGUID,
           a.RoomGUID,
           a.Httype,
           CASE
                WHEN DATEDIFF(DAY, ISNULL(a.CreatedOn, a.qsdate), ISNULL(b.SetGqAuditTime, '1900-01-01')) > 0 THEN
                    b.rddate
                ELSE a.QSDate END QSDate,
           a.Status,
           a.JyTotal,
           a.CloseDate,
           a.CloseReason
    INTO   #s_Contract_new
      FROM s_Contract a
      LEFT JOIN #sroom b
        ON a.roomguid = b.roomguid;

 ----20241216 chenjw 特殊业绩宽表调整——------------------------------------------------------------------       

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
						where s.AuditStatus  in ('已审核') )
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
                  AND a.AuditStatus in ( '已审核')
            ---- 其他业绩关联房间【认购录入日期】在【取消业绩发起时间】之前，视为其他业绩 
            --and  exists ( 
            --         select  con.RoomGUID,isnull(o.CreatedOn,con.CreatedOn ) as  CreatedOn
            --         from  s_Contract con
            --         inner join  S_PerformanceAppraisalRoom performanceRoom on performanceRoom.RoomGUID =con.RoomGUID
            --         left join s_Order o on o.OrderType ='认购' and  con.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
            --         where con.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
            --         and con.roomguid = c.RoomGUID  
            --         and performanceRoom.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
            --         and  ( (isnull(o.CreatedOn,con.CreatedOn ) < a.SetGqAuditTime  and  a.SetGqAuditTime is not null ) or  a.SetGqAuditTime is null  )
            --         union all 
            --         select  o.RoomGUID,o.CreatedOn from  s_Order o 
            --         inner join  S_PerformanceAppraisalRoom performanceRoom on performanceRoom.RoomGUID =o.RoomGUID
            --         where  o.Status ='激活' and  OrderType ='认购'
            --         and o.roomguid = c.RoomGUID   
            --         and performanceRoom.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
            --         and  ( ( o.CreatedOn < a.SetGqAuditTime and a.SetGqAuditTime is not null ) or   a.SetGqAuditTime is  null )
            -- )
    ) appraisa
