/* 2024-12-17 特殊业绩房间宽表修改备份
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
*/
   
    --①关联房间认购创建日期在取消业绩发起日期前，以特殊业绩认定日期作为业绩判断日期；
    --②关联房间认购创建日期在取消业绩发起日期后，按正常认购日期作为业绩判断日期
    --先获取对应的特殊业绩关联的清单
SELECT room.RoomGUID, 
      case when  p.auditstatus ='已审核'  and  p.yjtype NOT IN ( '物业公司车位代销', '经营类(溢价款)' ) then  '是' else '否' end  as specialFlag,
      CASE WHEN  p.auditstatus In ('已过期', '过期审核中')  and  p.yjtype NOT IN ( '物业公司车位代销', '经营类(溢价款)' ) 
              and DATEDIFF(DAY, ISNULL(ord.CreatedOn, ord.qsdate), ISNULL(p.SetGqAuditTime, '1900-01-01')) > 0 THEN
                    p.rddate
                ELSE NULL  END TsRoomQSDate --特殊业绩房间认定日期
from p_Room room with(nolock)
LEFT JOIN 
(
    select 
           per.PerformanceAppraisalGUID,
           per.rddate,
           per.roomguid,
           per.bldarea,
           per.auditstatus,
           per.yjtype,
           per.SetGqAuditTime,
           ROW_NUMBER() OVER (PARTITION BY per.roomguid ORDER BY rddate desc) num
    from (
            SELECT a.PerformanceAppraisalGUID,
                s.rddate,
                r.roomguid,
                r.bldarea,
                s.auditstatus,
                s.yjtype,
                s.SetGqAuditTime
            FROM S_PerformanceAppraisalBuildings a with(nolock)
            LEFT JOIN p_building b  with(nolock)  ON a.BldGUID = b.BldGUID
            LEFT JOIN p_room r  with(nolock)  ON b.BldGUID = r.BldGUID
            INNER JOIN S_PerformanceAppraisal s with(nolock)  ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
            where  s.auditstatus in ('已审核', '已过期', '过期审核中')
            UNION
            SELECT r.PerformanceAppraisalGUID,
                s.rddate,
                p.roomguid,
                p.bldarea,
                s.auditstatus,
                s.yjtype,
                s.SetGqAuditTime
            FROM S_PerformanceAppraisalRoom r with(nolock)
            LEFT JOIN p_room p  with(nolock) ON r.roomguid = p.roomguid
            INNER JOIN S_PerformanceAppraisal s with(nolock) ON r.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
            where  s.auditstatus  in ('已审核', '已过期', '过期审核中')
    ) per 
) p ON p.RoomGUID = room.RoomGUID and  p.num = 1
left join (
        -- 合同认购创建日期  没有认购的，以合同创建日期为准
        select  con.RoomGUID,isnull(o.CreatedOn,con.CreatedOn ) as  CreatedOn,isnull(o.QSDate,con.QSDate ) as  QSDate
        from  s_Contract con with(nolock)
        left join s_Order o on o.OrderType ='认购' and  con.TradeGUID =o.TradeGUID and    ( o.Status ='关闭' and  o.CloseReason ='转签约' ) 
        where con.Status ='激活'  and  (( o.Status ='关闭' and  o.CloseReason ='转签约' ) or o.OrderGUID  is null )
        union all 
        -- 订单认购创建日期
        select  o.RoomGUID,o.CreatedOn,o.QSDate
        from  s_Order o  with(nolock)
        where  o.Status ='激活' and  OrderType ='认购'
) ord on ord.roomguid = room.roomguid
where room.IsVirtualRoom = 0