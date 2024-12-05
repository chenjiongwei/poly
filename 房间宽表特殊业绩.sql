
-- 判断房间是否为特殊业绩房间
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
		   GROUP BY roomguid