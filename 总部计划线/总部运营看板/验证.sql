
-- version 1.0
SELECT bu.buname AS [公司名称],
       mpp.projname AS [一级项目名称],
       p.projname AS [分期名称],
	   p.ProjGUID as [分期GUID],
       sw.Name AS [标段名称],
       pw.Name AS [计划组团名称],
       wk.buildingname AS [工程楼栋名称],
       mp.ConstructStatus AS [分期建设状态],
       wk.BuildArea as [工程楼栋建筑面积],
       CASE
           WHEN cyj.TgType = '停工' THEN
                '停工'
           WHEN cyj.TgType = '缓建' THEN
                '缓建'
           ELSE '正常'
       END AS [是否停工],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') AS [项目获取计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '预计完成时间') AS [项目获取预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') AS [项目获取实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '计划完成时间') AS [实际开工计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '预计完成时间') AS [实际开工预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间') AS [实际开工实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') AS [竣工备案计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '预计完成时间') AS [竣工备案预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') AS [竣工备案实际完成时间]
into #ld
FROM dbo.p_Project p 
inner join jd_OutValueView jdo on jdo.ProjGUID = p.ProjGUID
INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
INNER JOIN erp25_test.dbo.mdm_project mp  ON mp.projguid = p.ProjGUID
INNER JOIN erp25_test.dbo.mdm_project mpp ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = p.ProjGUID
INNER JOIN p_HkbBiddingBuildingWork pw  ON pw.BidGUID = sw.BidGUID
INNER JOIN jd_ProjectPlanExecute jp  ON jp.ObjectID = pw.BuildGUID
LEFT JOIN (
    SELECT a.BudGUID,
           SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea,
           SUM(ISNULL(gc.UpBuildArea, 0)) AS UpBuild,
           SUM(ISNULL(gc.DownBuildArea, 0)) AS DownBuildArea,
           (SELECT STUFF((SELECT ';' + BuildingName
                         FROM p_HkbBiddingBuilding2BuildingWork
                         WHERE a.BudGUID = p_HkbBiddingBuilding2BuildingWork.BudGUID
                         FOR XML PATH('')), 1, 1, '')) AS buildingname
    FROM dbo.p_HkbBiddingBuilding2BuildingWork a 
    INNER JOIN erp25_test.dbo.mdm_GCBuild gc  ON gc.GCBldGUID = a.BuildingGUID
    GROUP BY a.BudGUID
) wk ON wk.BudGUID = pw.BuildGUID
left join (
    select  d.ObjectID, tg.Type as TgType 
    from jd_StopOrReturnWork tg
    left join jd_ProjectPlanTaskExecute f ON f.PlanID = tg.PlanID AND f.Level = 1
    left join jd_ProjectPlanExecute d ON d.ID = f.PlanID AND d.PlanType = 103
    where tg.ApplyState = '已审核' 
) cyj on  cyj.ObjectID = pw.BuildGUID
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

select  
[月度产值回顾审批GUID],
[一级项目GUID],
[工程楼栋建筑面积],
[累计竣工面积],
[本年竣工面积],
[累计开工面积],
[本年开工面积],
[当前停工面积],
case when isnull([累计开工面积],0) =0 then [累计开工面积] else [累计开工面积]-[累计竣工面积]-[当前停工面积] end as [当前在建面积]
from  (
      select  
        jdo.OutValueViewGUID as [月度产值回顾审批GUID],
        mp.ParentProjGUID as [一级项目GUID],
        sum(case when  mp.ConstructStatus ='已完工' then isnull([本年竣工面积],0) else 0 end ) as [本年竣工面积],
        sum([工程楼栋建筑面积]) as [工程楼栋建筑面积],
        sum(case when  mp.ConstructStatus ='已完工' then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计竣工面积],


        sum(case when  mp.ConstructStatus ='在建' then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计开工面积],

        sum(case when  mp.ConstructStatus ='在建' then isnull([本年开工面积],0) else 0 end ) as [本年开工面积],
        sum( isnull([当前停工面积],0) ) as [当前停工面积] 
    from jd_OutValueView jdo
    inner join erp25.dbo.mdm_Project  mp on mp.ProjGUID =jdo.ProjGUID
    inner join erp25.dbo.mdm_TechTarget tt on  tt.ProjGUID =mp.ParentProjGUID
    left join (
        select [分期GUID],
        sum( isnull([工程楼栋建筑面积],0) ) as [工程楼栋建筑面积],
        sum( case when  datediff(year,getdate(),[实际开工实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年开工面积],
        sum( case when  [是否停工] = '停工' and [实际开工实际完成时间] is not null and [竣工备案实际完成时间] is not null then isnull([工程楼栋建筑面积],0) else 0 end ) as [当前停工面积],
        sum( case when  datediff(year,getdate(),[竣工备案实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年竣工面积]
        from #ld
        group by [分期GUID]
    ) ld on ld.[分期GUID] = mp.ProjGUID
     where  jdo.OutValueViewGUID = [业务GUID]
    group by jdo.OutValueViewGUID,mp.ParentProjGUID
) a


-- version 2.0
-- 1、项目基本信息
SELECT bu.buname AS [公司名称],
       mpp.projname AS [一级项目名称],
       p.projname AS [分期名称],
	   p.ProjGUID as [分期GUID],
       sw.Name AS [标段名称],
       pw.Name AS [计划组团名称],
       wk.buildingname AS [工程楼栋名称],
       mp.ConstructStatus AS [分期建设状态],
       wk.BuildArea as [工程楼栋建筑面积],
       CASE
           WHEN cyj.TgType = '停工' THEN
                '停工'
           WHEN cyj.TgType = '缓建' THEN
                '缓建'
           ELSE '正常'
       END AS [是否停工],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') AS [项目获取计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '预计完成时间') AS [项目获取预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') AS [项目获取实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '计划完成时间') AS [实际开工计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '预计完成时间') AS [实际开工预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间') AS [实际开工实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') AS [竣工备案计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '预计完成时间') AS [竣工备案预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') AS [竣工备案实际完成时间]
into #ld
FROM dbo.p_Project p 
inner join jd_OutValueView jdo on jdo.ProjGUID = p.ProjGUID
INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
INNER JOIN ERP25_test.dbo.mdm_project mp  ON mp.projguid = p.ProjGUID
INNER JOIN ERP25_test.dbo.mdm_project mpp ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = p.ProjGUID
INNER JOIN p_HkbBiddingBuildingWork pw  ON pw.BidGUID = sw.BidGUID
INNER JOIN jd_ProjectPlanExecute jp  ON jp.ObjectID = pw.BuildGUID
LEFT JOIN (
    SELECT a.BudGUID,
           SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea,
           SUM(ISNULL(gc.UpBuildArea, 0)) AS UpBuild,
           SUM(ISNULL(gc.DownBuildArea, 0)) AS DownBuildArea,
           (SELECT STUFF((SELECT ';' + BuildingName
                         FROM p_HkbBiddingBuilding2BuildingWork
                         WHERE a.BudGUID = p_HkbBiddingBuilding2BuildingWork.BudGUID
                         FOR XML PATH('')), 1, 1, '')) AS buildingname
    FROM dbo.p_HkbBiddingBuilding2BuildingWork a 
    INNER JOIN ERP25_test.dbo.mdm_GCBuild gc  ON gc.GCBldGUID = a.BuildingGUID
    GROUP BY a.BudGUID
) wk ON wk.BudGUID = pw.BuildGUID
left join (
    select  d.ObjectID, tg.Type as TgType 
    from jd_StopOrReturnWork tg
    left join jd_ProjectPlanTaskExecute f ON f.PlanID = tg.PlanID AND f.Level = 1
    left join jd_ProjectPlanExecute d ON d.ID = f.PlanID AND d.PlanType = 103
    where tg.ApplyState = '已审核' 
) cyj on  cyj.ObjectID = pw.BuildGUID
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

select  
[月度产值回顾审批GUID],
[分期GUID],
[总建筑面积],
[累计开工面积],
[本年开工面积],
[累计竣工面积],
[本年竣工面积],
[当前停工面积],
case when isnull([累计开工面积],0) =0 then [累计开工面积] else [累计开工面积]-[累计竣工面积]-[当前停工面积] end as [当前在建面积]
from  (
    select  
        jdo.OutValueViewGUID as [月度产值回顾审批GUID],
        mp.ProjGUID as [分期GUID],
        sum(case when  mp.ConstructStatus ='已完工' then isnull([本年竣工面积],0) else 0 end ) as [本年竣工面积],
        sum([工程楼栋建筑面积]) as [总建筑面积],
        sum(case when  mp.ConstructStatus ='已完工' then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计竣工面积],


        sum(case when  mp.ConstructStatus ='在建' then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计开工面积],

        sum(case when  mp.ConstructStatus ='在建' then isnull([本年开工面积],0) else 0 end ) as [本年开工面积],
        sum( isnull([当前停工面积],0) ) as [当前停工面积] 
    from jd_OutValueView jdo
    inner join ERP25_test.dbo.mdm_Project  mp on mp.ProjGUID =jdo.ProjGUID
    left join (
        select [分期GUID],
        sum( isnull([工程楼栋建筑面积],0) ) as [工程楼栋建筑面积],
        sum( case when  datediff(year,getdate(),[实际开工实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年开工面积],
        sum( case when  [是否停工] = '停工' and [实际开工实际完成时间] is not null and [竣工备案实际完成时间] is not null then isnull([工程楼栋建筑面积],0) else 0 end ) as [当前停工面积],
        sum( case when  datediff(year,getdate(),[竣工备案实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年竣工面积]
        from #ld
        group by [分期GUID]
    ) ld on ld.[分期GUID] = mp.ProjGUID
     where  jdo.OutValueViewGUID = [业务GUID]
    group by jdo.OutValueViewGUID,mp.ProjGUID
) a

-- 2. 项目进度计划
SELECT bu.buname AS [公司名称],
       mpp.projname AS [一级项目名称],
       p.projname AS [分期名称],
	   p.ProjGUID as [分期GUID],
       sw.Name AS [标段名称],
       pw.Name AS [计划组团名称],
       wk.buildingname AS [工程楼栋名称],
       mp.ConstructStatus AS [分期建设状态],
       wk.BuildArea as [工程楼栋建筑面积],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') AS [项目获取计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '预计完成时间') AS [项目获取预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') AS [项目获取实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '计划完成时间') AS [实际开工计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '预计完成时间') AS [实际开工预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间') AS [实际开工实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') AS [竣工备案计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '预计完成时间') AS [竣工备案预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') AS [竣工备案实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '计划完成时间') AS [开盘销售计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '预计完成时间') AS [开盘销售预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '实际完成时间') AS [开盘销售实际完成时间]
into #ld2
FROM dbo.p_Project p 
inner join jd_OutValueView jdo on jdo.ProjGUID = p.ProjGUID
INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
INNER JOIN erp25_test.dbo.mdm_project mp  ON mp.projguid = p.ProjGUID
INNER JOIN erp25_test.dbo.mdm_project mpp ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = p.ProjGUID
INNER JOIN p_HkbBiddingBuildingWork pw  ON pw.BidGUID = sw.BidGUID
INNER JOIN jd_ProjectPlanExecute jp  ON jp.ObjectID = pw.BuildGUID
LEFT JOIN (
    SELECT a.BudGUID,
           SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea,
           SUM(ISNULL(gc.UpBuildArea, 0)) AS UpBuild,
           SUM(ISNULL(gc.DownBuildArea, 0)) AS DownBuildArea,
           (SELECT STUFF((SELECT ';' + BuildingName
                         FROM p_HkbBiddingBuilding2BuildingWork
                         WHERE a.BudGUID = p_HkbBiddingBuilding2BuildingWork.BudGUID
                         FOR XML PATH('')), 1, 1, '')) AS buildingname
    FROM dbo.p_HkbBiddingBuilding2BuildingWork a 
    INNER JOIN erp25_test.dbo.mdm_GCBuild gc  ON gc.GCBldGUID = a.BuildingGUID
    GROUP BY a.BudGUID
) wk ON wk.BudGUID = pw.BuildGUID
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

select  [分期GUID],
max([项目获取计划完成时间]) as [项目获取计划完成日期],
max([项目获取实际完成时间]) as [项目获取实际完成日期],
min([实际开工计划完成时间]) as [首批实际开工计划完成日期],
min([实际开工实际完成时间]) as [首批实际开工实际完成日期],
max([开盘销售计划完成时间]) as [开盘销售计划完成日期],
max([开盘销售实际完成时间]) as [开盘销售实际完成日期],
min([竣工备案计划完成时间]) as [首批竣工备案计划完成日期],
min([竣工备案实际完成时间]) as [首批竣工备案实际完成日期],
max([竣工备案计划完成时间]) as [末批竣工备案计划完成日期],
max([竣工备案实际完成时间]) as [末批竣工备案实际完成日期]
from  #ld2
group by [分期GUID]

-- v3.0
SELECT bu.buname AS [公司名称],
       mpp.projname AS [一级项目名称],
       p.projname AS [分期名称],
	   p.ProjGUID as [分期GUID],
       sw.Name AS [标段名称],
       pw.Name AS [计划组团名称],
       wk.buildingname AS [工程楼栋名称],
       mp.ConstructStatus AS [分期建设状态],
       wk.BuildArea as [工程楼栋建筑面积],
       CASE
           WHEN cyj.TgType = '停工' THEN
                '停工'
           WHEN cyj.TgType = '缓建' THEN
                '缓建'
           ELSE '正常'
       END AS [是否停工],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') AS [项目获取计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '预计完成时间') AS [项目获取预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') AS [项目获取实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '计划完成时间') AS [实际开工计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '预计完成时间') AS [实际开工预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间') AS [实际开工实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') AS [竣工备案计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '预计完成时间') AS [竣工备案预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') AS [竣工备案实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '计划完成时间') AS [开盘销售计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '预计完成时间') AS [开盘销售预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '实际完成时间') AS [开盘销售实际完成时间]
into #ld
FROM dbo.p_Project p 
inner join jd_OutValueView jdo on jdo.ProjGUID = p.ProjGUID
INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
INNER JOIN ERP25_test.dbo.mdm_project mp  ON mp.projguid = p.ProjGUID
INNER JOIN ERP25_test.dbo.mdm_project mpp ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = p.ProjGUID
INNER JOIN p_HkbBiddingBuildingWork pw  ON pw.BidGUID = sw.BidGUID
INNER JOIN jd_ProjectPlanExecute jp  ON jp.ObjectID = pw.BuildGUID
LEFT JOIN (
    SELECT a.BudGUID,
           SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea,
           SUM(ISNULL(gc.UpBuildArea, 0)) AS UpBuild,
           SUM(ISNULL(gc.DownBuildArea, 0)) AS DownBuildArea,
           (SELECT STUFF((SELECT ';' + BuildingName
                         FROM p_HkbBiddingBuilding2BuildingWork
                         WHERE a.BudGUID = p_HkbBiddingBuilding2BuildingWork.BudGUID
                         FOR XML PATH('')), 1, 1, '')) AS buildingname
    FROM dbo.p_HkbBiddingBuilding2BuildingWork a 
    INNER JOIN ERP25_test.dbo.mdm_GCBuild gc  ON gc.GCBldGUID = a.BuildingGUID
    GROUP BY a.BudGUID
) wk ON wk.BudGUID = pw.BuildGUID
left join (
    select  d.ObjectID, tg.Type as TgType 
    from jd_StopOrReturnWork tg
    left join jd_ProjectPlanTaskExecute f ON f.PlanID = tg.PlanID AND f.Level = 1
    left join jd_ProjectPlanExecute d ON d.ID = f.PlanID AND d.PlanType = 103
    where tg.ApplyState = '已审核' 
) cyj on  cyj.ObjectID = pw.BuildGUID
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

SELECT ReportDate AS [汇报日期],
       b.ProjName AS [项目名称],
       b.ProjName + '(' + REPLACE(CONVERT(VARCHAR(100), a.ReportDate, 23), '-', '.') + ')形象进度回顾报告' AS [名称标题],
       c.UserName AS [创建人],
        [分期GUID],
        [总建筑面积],
        [累计开工面积],
        [本年开工面积],
        [累计竣工面积],
        [本年竣工面积],
        [当前停工面积],   
        case when isnull([累计开工面积],0) =0 then [累计开工面积] else [累计开工面积]-[累计竣工面积]-[当前停工面积] end as [当前在建面积],
        [项目获取计划完成日期],
        [项目获取实际完成日期],
        [首批实际开工计划完成日期],
        [首批实际开工实际完成日期],
        [开盘销售计划完成日期],
        [开盘销售实际完成日期],
        [首批竣工备案计划完成日期],
        [首批竣工备案实际完成日期],
        [末批竣工备案计划完成日期],
        [末批竣工备案实际完成日期]
FROM jd_OutValueView a
    LEFT JOIN dbo.p_Project b
        ON a.ProjGUID = b.ProjGUID
    LEFT JOIN dbo.myUser c
        ON c.UserGUID = a.CreatedOn
    LEFT JOIN (
        select  
            jdo.OutValueViewGUID as [月度产值回顾审批GUID],
            mp.ProjGUID as [分期GUID],
            sum(case when  mp.ConstructStatus ='已完工' then isnull([本年竣工面积],0) else 0 end ) as [本年竣工面积],
            sum([工程楼栋建筑面积]) as [总建筑面积],
            sum(case when  mp.ConstructStatus ='已完工' then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计竣工面积],


            sum(case when  mp.ConstructStatus ='在建' then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计开工面积],

            sum(case when  mp.ConstructStatus ='在建' then isnull([本年开工面积],0) else 0 end ) as [本年开工面积],
            sum( isnull([当前停工面积],0) ) as [当前停工面积] 
        from jd_OutValueView jdo
        inner join ERP25_test.dbo.mdm_Project  mp on mp.ProjGUID =jdo.ProjGUID
        left join (
            select [分期GUID],
            sum( isnull([工程楼栋建筑面积],0) ) as [工程楼栋建筑面积],
            sum( case when  datediff(year,getdate(),[实际开工实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年开工面积],
            sum( case when  [是否停工] = '停工' and [实际开工实际完成时间] is not null and [竣工备案实际完成时间] is not null then isnull([工程楼栋建筑面积],0) else 0 end ) as [当前停工面积],
            sum( case when  datediff(year,getdate(),[竣工备案实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年竣工面积]
            from #ld
            group by [分期GUID]
        ) ld on ld.[分期GUID] = mp.ProjGUID
       where  jdo.OutValueViewGUID = [业务GUID]
        group by jdo.OutValueViewGUID,mp.ProjGUID
    ) d on d.[分期GUID] = b.ProjGUID
    left  join (
        select [分期GUID] as [分期ProjGUID],
        max([项目获取计划完成时间]) as [项目获取计划完成日期],
        max([项目获取实际完成时间]) as [项目获取实际完成日期],
        min([实际开工计划完成时间]) as [首批实际开工计划完成日期],
        min([实际开工实际完成时间]) as [首批实际开工实际完成日期],
        min([开盘销售计划完成时间]) as [开盘销售计划完成日期],
        min([开盘销售实际完成时间]) as [开盘销售实际完成日期],
        min([竣工备案计划完成时间]) as [首批竣工备案计划完成日期],
        min([竣工备案实际完成时间]) as [首批竣工备案实际完成日期],
        max([竣工备案计划完成时间]) as [末批竣工备案计划完成日期],
        max([竣工备案实际完成时间]) as [末批竣工备案实际完成日期]
        from #ld 
        group by [分期GUID]
    ) e on e.[分期ProjGUID] = b.ProjGUID
WHERE OutValueViewGUID = [业务GUID]

----------------- version 4.0 ------------------------------------------------------------------------------
/*
好的，都改了。包括昨天的两个问题
1、本年开工、本年竣工、累计开工、累计竣工，不判断分期的工程状态；
2、末批准备的实际日期；
3、分期总建筑面积
*/


SELECT bu.buname AS [公司名称],
       mpp.projname AS [一级项目名称],
       p.projname AS [分期名称],
	   p.ProjGUID as [分期GUID],
       sw.Name AS [标段名称],
       pw.Name AS [计划组团名称],
       wk.buildingname AS [工程楼栋名称],
       mp.ConstructStatus AS [分期建设状态],
       wk.BuildArea as [工程楼栋建筑面积],
       CASE
           WHEN cyj.TgType = '停工' THEN
                '停工'
           WHEN cyj.TgType = '缓建' THEN
                '缓建'
           ELSE '正常'
       END AS [是否停工],
        gc.isCompare as [是否按期完成],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') AS [项目获取计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '预计完成时间') AS [项目获取预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') AS [项目获取实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '计划完成时间') AS [实际开工计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '预计完成时间') AS [实际开工预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间') AS [实际开工实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') AS [竣工备案计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '预计完成时间') AS [竣工备案预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') AS [竣工备案实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '计划完成时间') AS [开盘销售计划完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '预计完成时间') AS [开盘销售预计完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '实际完成时间') AS [开盘销售实际完成时间],
        dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '工作项状态') AS [竣工备案工作项状态]
into #ld
FROM dbo.p_Project p 
inner join jd_OutValueView jdo on jdo.ProjGUID = p.ProjGUID
INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
INNER JOIN ERP25.dbo.mdm_project mp  ON mp.projguid = p.ProjGUID
INNER JOIN ERP25.dbo.mdm_project mpp ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = p.ProjGUID
INNER JOIN p_HkbBiddingBuildingWork pw  ON pw.BidGUID = sw.BidGUID
INNER JOIN jd_ProjectPlanExecute jp  ON jp.ObjectID = pw.BuildGUID
LEFT JOIN (
    SELECT a.BudGUID,
           SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea,
           SUM(ISNULL(gc.UpBuildArea, 0)) AS UpBuild,
           SUM(ISNULL(gc.DownBuildArea, 0)) AS DownBuildArea,
           (SELECT STUFF((SELECT ';' + BuildingName
                         FROM p_HkbBiddingBuilding2BuildingWork
                         WHERE a.BudGUID = p_HkbBiddingBuilding2BuildingWork.BudGUID
                         FOR XML PATH('')), 1, 1, '')) AS buildingname
    FROM dbo.p_HkbBiddingBuilding2BuildingWork a 
    INNER JOIN ERP25.dbo.mdm_GCBuild gc  ON gc.GCBldGUID = a.BuildingGUID
    GROUP BY a.BudGUID
) wk ON wk.BudGUID = pw.BuildGUID
left join (
    select  d.ObjectID, tg.Type as TgType 
    from jd_StopOrReturnWork tg
    left join jd_ProjectPlanTaskExecute f ON f.PlanID = tg.PlanID AND f.Level = 1
    left join jd_ProjectPlanExecute d ON d.ID = f.PlanID AND d.PlanType = 103
    where tg.ApplyState = '已审核' 
) cyj on  cyj.ObjectID = pw.BuildGUID
LEFT JOIN (
    SELECT PlanID,
           NodeNum,
           TaskStateNum,
           CASE 
               WHEN ISNULL(NodeNum,0) = ISNULL(TaskStateNum,0) THEN '是' 
               ELSE '否' 
           END AS isCompare
    FROM (
        SELECT PlanID,
               COUNT(1) AS NodeNum,
               SUM(CASE 
                   WHEN enumTask.EnumerationName IN ('按期完成','延期完成') THEN 1 
                   ELSE 0 
               END) AS TaskStateNum
        FROM jd_ProjectPlanTaskExecute jpte
        LEFT JOIN jd_EnumerationDictionary enumTask   ON enumTask.EnumerationType = '工作状态枚举' AND enumTask.EnumerationValue = jpte.TaskState
        GROUP BY PlanID
    ) jppt
) gc ON gc.PlanID = jp.id
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

SELECT ReportDate AS [汇报日期],
       b.ProjName AS [项目名称],
       b.ProjName + '(' + REPLACE(CONVERT(VARCHAR(100), a.ReportDate, 23), '-', '.') + ')形象进度回顾报告' AS [名称标题],
       c.UserName AS [创建人],
        [分期GUID],
        [总建筑面积],
        [累计开工面积],
        [本年开工面积],
        [累计竣工面积],
        [本年竣工面积],
        [当前停工面积],   
        case when isnull([累计开工面积],0) =0 then [累计开工面积] else [累计开工面积]-[累计竣工面积]-[当前停工面积] end as [当前在建面积],
        [项目获取计划完成日期],
        [项目获取实际完成日期],
        [首批实际开工计划完成日期],
        [首批实际开工实际完成日期],
        [开盘销售计划完成日期],
        [开盘销售实际完成日期],
        [首批竣工备案计划完成日期],
        [首批竣工备案实际完成日期],
        [末批竣工备案计划完成日期],
        [末批竣工备案实际完成日期]
FROM jd_OutValueView a
    LEFT JOIN dbo.p_Project b
        ON a.ProjGUID = b.ProjGUID
    LEFT JOIN dbo.myUser c
        ON c.UserGUID = a.CreatedOn
    LEFT JOIN (
        select  
            jdo.OutValueViewGUID as [月度产值回顾审批GUID],
            mp.ProjGUID as [分期GUID],
            mproj.SumBuildArea as [总建筑面积],
            sum( isnull([本年竣工面积],0) ) as [本年竣工面积],

            sum( isnull([累计竣工建筑面积],0)  ) as [累计竣工面积],


            sum( isnull([累计开工建筑面积],0) ) as [累计开工面积],

            sum( isnull([本年开工面积],0)  ) as [本年开工面积],
            sum( isnull([当前停工面积],0) ) as [当前停工面积] 
        from jd_OutValueView jdo
        inner join ERP25.dbo.mdm_Project  mp on mp.ProjGUID =jdo.ProjGUID
        left join (
                  SELECT x.ProjGUID,x.SumBuildArea
                    FROM
                    (
                        SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
                                *
                        FROM dbo.md_Project
                        WHERE ApproveState = '已审核'
                                AND ISNULL(CreateReason, '') <> '补录'
                    ) x
                    WHERE x.rowmo = 1
        ) mproj on mproj.ProjGUID = mp.ProjGUID
        left join (
            select [分期GUID],
            sum(case when [实际开工实际完成时间] is not null then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计开工建筑面积],
            sum(case when [竣工备案实际完成时间] is not null then isnull([工程楼栋建筑面积],0) else 0 end ) as [累计竣工建筑面积],
            sum( isnull([工程楼栋建筑面积],0) ) as [工程楼栋建筑面积],
            sum( case when  datediff(year,getdate(),[实际开工实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年开工面积],
            sum( case when  [是否停工] = '停工' and [实际开工实际完成时间] is not null and [竣工备案实际完成时间] is not null then isnull([工程楼栋建筑面积],0) else 0 end ) as [当前停工面积],
            sum( case when  datediff(year,getdate(),[竣工备案实际完成时间]) =0 then isnull([工程楼栋建筑面积],0) else 0 end ) as [本年竣工面积]
            from #ld
            group by [分期GUID]
        ) ld on ld.[分期GUID] = mp.ProjGUID
       where  jdo.OutValueViewGUID = [业务GUID]
        group by jdo.OutValueViewGUID,mp.ProjGUID,mproj.SumBuildArea
    ) d on d.[分期GUID] = b.ProjGUID
    left  join (
        select [分期GUID] as [分期ProjGUID],[是否按期完成] as [是否按期完成],
        max([项目获取计划完成时间]) as [项目获取计划完成日期],
        max([项目获取实际完成时间]) as [项目获取实际完成日期],
        min([实际开工计划完成时间]) as [首批实际开工计划完成日期],
        min([实际开工实际完成时间]) as [首批实际开工实际完成日期],
        min([开盘销售计划完成时间]) as [开盘销售计划完成日期],
        min([开盘销售实际完成时间]) as [开盘销售实际完成日期],
        min([竣工备案计划完成时间]) as [首批竣工备案计划完成日期],
        min([竣工备案实际完成时间]) as [首批竣工备案实际完成日期],
        max([竣工备案计划完成时间]) as [末批竣工备案计划完成日期],
        case when [是否按期完成] = '是' then max([竣工备案实际完成时间]) else null end as [末批竣工备案实际完成日期]
        from #ld 
        group by [分期GUID],[是否按期完成]
    ) e on e.[分期ProjGUID] = b.ProjGUID
WHERE OutValueViewGUID = [业务GUID]



-- 月度进度计划审批表单-楼栋建设状态
select  
a.OutValueJsztGUID as [主键GUID],
a.BusinessName as [组团/楼栋],
a.YtName as  [业态名称],
a.KeyNodeName as [已完成最新关键节点],
b.status as  [楼栋建设状态名称],
ld.Name as [组团名称]
from  jd_OutValueJszt a
inner join jd_BuildConstruction b on a.BuildConstructionGUID =b.BuildConstructionGUID
left join (
	SELECT p.ProjName,p.ProjGUID,
		gc.BldGUID,
		a1.BuildingName,
		a1.BudGUID,
		pw.BidGUID,
		pw.Name
	FROM md_GCBuild gc
	INNER JOIN
	(
		SELECT *
		FROM
		(
			SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
					*
			FROM dbo.md_Project
			WHERE ApproveState = '已审核'
					AND ISNULL(CreateReason, '') <> '补录'
				   --  AND CurVersion IN ( '立项版', '定位版', '修详规版', '建规证版' )
		) x
		WHERE x.rowmo = 1
	) p  ON p.VersionGUID = gc.VersionGUID and  p.ProjGUID =gc.ProjGUID
	inner join p_BiddingBuilding2Building a1 on a1.BuildingGUID =gc.BldGUID
	left join  p_HkbBiddingBuildingWork pw on pw.BuildGUID =a1.BudGUID
) ld on ld.BldGUID =a.BldGUID
where a.OutValueViewGUID = [业务GUID]
