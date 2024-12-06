-- 判断房间是否为特殊业绩房间
SELECT room.RoomGUID, 
(CASE WHEN ISNULL(t.IsTsRoom,'否')='否' AND ISNULL(p.IsTsBld,'否')='否' THEN '否' ELSE '是' END) AS specialFlag
from p_Room room with(nolock)
LEFT JOIN 
(
    SELECT RoomGUID,(CASE WHEN COUNT(1)>=1 THEN '是' ELSE '否' END) AS IsTsRoom  
    FROM S_PerformanceAppraisalRoom t1  with(nolock) 
    INNER JOIN S_PerformanceAppraisal t2 with(nolock) ON t1.PerformanceAppraisalGUID = t2.PerformanceAppraisalGUID
    WHERE t2.AuditStatus in ('已审核','已取消')
    and not  exists (
            --  剔除 其他业绩关联的房间【认购录入日期】在【取消业绩发起时间】之后
            select  con.RoomGUID,isnull(o.CreatedOn,con.CreatedOn ) as  CreatedOn
            from  s_Contract con with(nolock)
            inner join  S_PerformanceAppraisalRoom performanceRoom with(nolock) on performanceRoom.RoomGUID =con.RoomGUID
            left join s_Order o with(nolock) on o.OrderType ='认购' and  con.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
            where con.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
            and con.roomguid =  t1.RoomGUID  
            and performanceRoom.PerformanceAppraisalGUID = t2.PerformanceAppraisalGUID
            and  (isnull(o.CreatedOn,con.CreatedOn ) > t2.SetGqAuditTime  and  t2.SetGqAuditTime is not null ) 
            union all 
            select  o.RoomGUID,o.CreatedOn from  s_Order o  with(nolock)
            inner join  S_PerformanceAppraisalRoom performanceRoom with(nolock) on performanceRoom.RoomGUID =o.RoomGUID
            where  o.Status ='激活' and  OrderType ='认购'
            and o.roomguid = t1.RoomGUID   
            and performanceRoom.PerformanceAppraisalGUID = t2.PerformanceAppraisalGUID
            and  ( o.CreatedOn > t2.SetGqAuditTime and t2.SetGqAuditTime is not null ) 
    )
    GROUP BY RoomGUID
) t ON t.RoomGUID = room.RoomGUID
LEFT JOIN 
(
 SELECT BldGUID,(CASE WHEN COUNT(1)>=1 THEN '是' ELSE '否' END) AS IsTsBld  
 FROM S_PerformanceAppraisalBuildings t1 with(nolock) 
 INNER JOIN S_PerformanceAppraisal t2 with(nolock) ON t1.PerformanceAppraisalGUID = t2.PerformanceAppraisalGUID
 WHERE t2.AuditStatus = '已审核'
 and  t1.BldGUID NOT IN (  
                SELECT r.BldGUID
                FROM   S_PerformanceAppraisalRoom c with(nolock)
                inner join S_PerformanceAppraisal s  with(nolock) on c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
                INNER JOIN dbo.p_room r ON c.RoomGUID = r.RoomGUID
                where s.AuditStatus in ('已审核','已取消') 
         )
 GROUP BY BldGUID
) p ON p.BldGUID = room.BldGUID
where room.IsVirtualRoom = 0


-- 获取特殊业绩溢价款
SELECT  roomguid,
        SUM(房间溢价款) specialYj 
FROM    (
        SELECT  sr.RoomGUID,
                SUM(sr.AmountDetermined) 房间溢价款
        FROM    dbo.S_PerformanceAppraisalRoom sr
                INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                    AND s.AuditStatus in ('已审核','已取消')
                    AND s.YjType = '经营类(溢价款)'
        where not  exists (
            -- 剔除 其他业绩关联的房间【认购录入日期】在【取消业绩发起时间】之后
            select  con.RoomGUID,isnull(o.CreatedOn,con.CreatedOn ) as  CreatedOn
            from  s_Contract con with(nolock)
            inner join  S_PerformanceAppraisalRoom performanceRoom with(nolock) on performanceRoom.RoomGUID =con.RoomGUID
            left join s_Order o with(nolock) on o.OrderType ='认购' and  con.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
            where con.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
            and con.roomguid =  sr.RoomGUID  
            and performanceRoom.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
            and   (isnull(o.CreatedOn,con.CreatedOn ) > s.SetGqAuditTime  and  s.SetGqAuditTime is not null ) 
            union all 
            select  o.RoomGUID,o.CreatedOn from  s_Order o  with(nolock)
            inner join  S_PerformanceAppraisalRoom performanceRoom with(nolock) on performanceRoom.RoomGUID =o.RoomGUID
            where  o.Status ='激活' and  OrderType ='认购'
            and o.roomguid = sr.RoomGUID   
            and performanceRoom.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
            and   ( o.CreatedOn > s.SetGqAuditTime and s.SetGqAuditTime is not null )
         )
        GROUP BY roomguid   
        UNION ALL 
        SELECT  r.RoomGUID,
                SUM(r.BldArea / (sb.UpBuildArea + sb.DownBuildArea) * AmountDetermined) AS 房间溢价款
        FROM    dbo.p_room r
                INNER JOIN mdm_SaleBuild sb ON r.BldGUID = sb.SaleBldGUID
                INNER JOIN S_PerformanceAppraisalBuildings pb ON sb.SaleBldGUID = pb.BldGUID
                INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = pb.PerformanceAppraisalGUID
                    AND s.AuditStatus = '已审核' AND s.YjType = '经营类(溢价款)'
        where   pb.BldGUID NOT IN (  
                SELECT r.BldGUID
                FROM   S_PerformanceAppraisalRoom c
                inner join S_PerformanceAppraisal s on c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
                INNER JOIN dbo.p_room r ON c.RoomGUID = r.RoomGUID
                where s.AuditStatus in ('已审核','已取消') 
         )
        GROUP BY r.RoomGUID
) t 
GROUP BY roomguid

 --///// 房间特殊业绩清洗规则备份////////////////////////////////////////////////////////////////////
/*-- 判断房间是否为特殊业绩房间
SELECT room.RoomGUID, 
(CASE WHEN ISNULL(t.IsTsRoom,'否')='否' AND ISNULL(p.IsTsBld,'否')='否' THEN '否' ELSE '是' END) AS specialFlag
from p_Room room with(nolock)
LEFT JOIN 
(
    SELECT RoomGUID,(CASE WHEN COUNT(1)>=1 THEN '是' ELSE '否' END) AS IsTsRoom  
    FROM S_PerformanceAppraisalRoom t1  with(nolock) 
    INNER JOIN S_PerformanceAppraisal t2 with(nolock) ON t1.PerformanceAppraisalGUID = t2.PerformanceAppraisalGUID
    WHERE t2.AuditStatus = '已审核'
    GROUP BY RoomGUID
) t ON t.RoomGUID = room.RoomGUID
LEFT JOIN 
(
 SELECT BldGUID,(CASE WHEN COUNT(1)>=1 THEN '是' ELSE '否' END) AS IsTsBld  
 FROM S_PerformanceAppraisalBuildings t1 with(nolock) 
 INNER JOIN S_PerformanceAppraisal t2 with(nolock) ON t1.PerformanceAppraisalGUID = t2.PerformanceAppraisalGUID
 WHERE t2.AuditStatus = '已审核'
 GROUP BY BldGUID
) p ON p.BldGUID = room.BldGUID
where room.IsVirtualRoom = 0


-- 获取特殊业绩溢价款
SELECT roomguid,SUM(房间溢价款) specialYj FROM (
SELECT sr.RoomGUID,SUM(sr.AmountDetermined) 房间溢价款
FROM dbo.S_PerformanceAppraisalRoom sr
    INNER JOIN dbo.S_PerformanceAppraisal s
        ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
           AND s.AuditStatus = '已审核'
           AND s.YjType = '经营类(溢价款)'
		   GROUP BY roomguid 
UNION ALL 
SELECT r.RoomGUID,
       SUM(r.BldArea / (sb.UpBuildArea + sb.DownBuildArea) * AmountDetermined) AS 房间溢价款
FROM dbo.p_room r
    INNER JOIN mdm_SaleBuild sb
        ON r.BldGUID = sb.SaleBldGUID
    INNER JOIN S_PerformanceAppraisalBuildings pb
        ON sb.SaleBldGUID = pb.BldGUID
    INNER JOIN dbo.S_PerformanceAppraisal s
        ON s.PerformanceAppraisalGUID = pb.PerformanceAppraisalGUID
           AND s.AuditStatus = '已审核'
           AND s.YjType = '经营类(溢价款)'
		   GROUP BY r.RoomGUID) t 
		   GROUP BY roomguid       */