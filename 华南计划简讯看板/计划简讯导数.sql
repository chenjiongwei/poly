
-- 计划简讯导数 chenjw 2025-01-02
Use  MyCost_Erp352
go 

SELECT bu.buname AS 公司名称,
       mpp.projname AS 一级项目名称,
       p.projname AS 分期名称,
       sw.Name AS 标段名称,
       pw.Name AS 计划组团名称,
       wk.buildingname AS 工程楼栋名称,
       mp.ConstructStatus AS 分期建设状态,
       CASE 
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '二阶段展示开放', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 二阶段展示开放,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '消防工程完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 消防工程完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '房屋确权', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 房屋确权,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基坑支护完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 基坑支护完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '室内电梯安装完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 室内电梯安装完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '砌筑工程完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 砌筑工程完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '门窗及幕墙工程完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 门窗及幕墙工程完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '外架拆除完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 外架拆除完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '室内装修湿作业完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 室内装修湿作业完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '室内装修吊顶完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 室内装修吊顶完成,
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '精装修部品安装完成', '计划完成时间') IS NOT NULL THEN '有'
           ELSE '无'
       END AS 精装修部品安装完成
FROM dbo.p_Project p WITH (NOLOCK)
INNER JOIN mybusinessunit bu WITH (NOLOCK) ON bu.buguid = p.buguid
INNER JOIN erp25.dbo.mdm_project mp WITH (NOLOCK) ON mp.projguid = p.ProjGUID
INNER JOIN erp25.dbo.mdm_project mpp WITH (NOLOCK) ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw WITH (NOLOCK) ON sw.ProjGUID = p.ProjGUID
INNER JOIN p_HkbBiddingBuildingWork pw WITH (NOLOCK) ON pw.BidGUID = sw.BidGUID
INNER JOIN jd_ProjectPlanExecute jp WITH (NOLOCK) ON jp.ObjectID = pw.BuildGUID
LEFT JOIN (
    SELECT a.BudGUID,
           SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea,
           SUM(ISNULL(gc.UpBuildArea, 0)) AS UpBuild,
           SUM(ISNULL(gc.DownBuildArea, 0)) AS DownBuildArea,
           (SELECT STUFF((SELECT ';' + BuildingName
                         FROM p_HkbBiddingBuilding2BuildingWork
                         WHERE a.BudGUID = p_HkbBiddingBuilding2BuildingWork.BudGUID
                         FOR XML PATH('')), 1, 1, '')) AS buildingname
    FROM dbo.p_HkbBiddingBuilding2BuildingWork a WITH (NOLOCK)
    INNER JOIN ERP25.dbo.mdm_GCBuild gc WITH (NOLOCK) ON gc.GCBldGUID = a.BuildingGUID
    GROUP BY a.BudGUID
) wk ON wk.BudGUID = pw.BuildGUID
WHERE p.IfEnd = 1
AND jp.PlanType = 103
AND jp.IsExamin = 1;