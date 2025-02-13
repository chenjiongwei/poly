-- 月度进度计划审批表单 2025-01-06


-- 查询工程楼栋信息
-- 创建临时表存储工程楼栋信息
declare @ProjGUID varchar(50) ='05F4D8C6-6B3B-E711-80BA-E61F13C57837'
SELECT *
INTO #GCbuild
FROM
(
    -- 查询预售查丈版和竣工验收版的楼栋信息
    SELECT 
        ISNULL(p.ProjName, '') + '-' + ISNULL(gc.BldName, '') AS BldName,  -- 完整楼栋名称(项目名-楼栋名)
        gc.BldName AS ShortBldName,                                         -- 楼栋简称
        gc.SumBuildArea,                                                    -- 总建筑面积
        BldGUID,                                                           -- 楼栋GUID
        gc.ProjGUID,                                                       -- 项目GUID
        gc.BldCode,                                                        -- 楼栋编码
        gc.CurVersion,                                                     -- 当前版本
        gc.CreateDate,                                                     -- 创建日期
        gc.BldKeyGUID,                                                     -- 楼栋关键GUID
        gc.SumJrArea,                                                      -- 计容面积
        gc.SumSaleArea,                                                    -- 可售面积
        gc.UpNum,                                                          -- 地上层数
        gc.DownNum                                                         -- 地下层数
    FROM dbo.md_GCBuild gc
        LEFT JOIN
        (
            -- 获取最新项目信息
            SELECT *
            FROM
            (
                SELECT *,
                       ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowno
                FROM dbo.md_Project
            ) t
            WHERE t.rowno = 1
        ) p
            ON gc.ProjGUID = p.ProjGUID
    WHERE gc.CurVersion IN ( '预售查丈版', '竣工验收版' )
          AND gc.IsActive = 1
          AND gc.ProjGUID = @ProjGUID

    UNION
    -- 查询其他版本(立项版、定位版等)的楼栋信息
    SELECT 
        ISNULL(t.ProjName, '') + '-' + ISNULL(t.BldName, '') AS BldName,  -- 完整楼栋名称
        t.BldName AS ShortBldName,                                         -- 楼栋简称
        ISNULL(t.SumBuildArea, 0) AS SumBuildArea,                        -- 总建筑面积
        t.BldGUID,
        t.ProjGUID,
        t.BldCode,
        t.CurVersion,
        t.CreateDate,
        t.BldKeyGUID,
        t.SumJrArea,
        t.SumSaleArea,
        t.UpNum,
        t.DownNum
    FROM
    (
        SELECT p.ProjName,
               gc.*
        FROM md_GCBuild gc
            INNER JOIN
            (
                -- 获取最新已审核的项目信息
                SELECT *
                FROM
                (
                    SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
                           *
                    FROM dbo.md_Project
                    WHERE ApproveState = '已审核'
                          AND ISNULL(CreateReason, '') <> '补录'
                          AND CurVersion IN ( '立项版', '定位版', '修详规版', '建规证版' )
                ) x
                WHERE x.rowmo = 1
            ) p
                ON p.VersionGUID = gc.VersionGUID
        -- 排除已有预售查丈版或竣工验收版的楼栋
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.md_GCBuild
            WHERE CurVersion IN ( '预售查丈版', '竣工验收版' )
                  AND md_GCBuild.IsActive = 1
                  AND md_GCBuild.BldGUID = gc.BldGUID
        )
              AND gc.ProjGUID = @ProjGUID
    ) t
) a

-- 1. 项目基本信息
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
INNER JOIN mybusinessunit bu  ON bu.buguid = p.buguid
INNER JOIN ERP25_test.dbo.mdm_project mp  ON mp.projguid = p.ProjGUID
INNER JOIN ERP25_test.dbo.mdm_project mpp ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw  ON sw.ProjGUID = p.ProjGUID
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
LEFT JOIN
     (
         SELECT DISTINCT
                d.ObjectID,
                tg.TgType
         from
         (
             select ROW_NUMBER() OVER (PARTITION BY tg.PlanID ORDER BY ApplicationTime DESC) num,
                    tg.PlanID,
                    tg.Type TgType
             from dbo.jd_StopOrReturnWork tg
             where tg.ApplyState = '已审核'
         ) tg
         left join  jd_ProjectPlanTaskExecute f ON f.PlanID = tg.PlanID AND f.Level = 1
         left join  jd_ProjectPlanExecute d ON d.ID = f.PlanID AND d.PlanType = 103
         WHERE tg.num = 1 AND d.ObjectID IS NOT NULL
     ) cyj On cyj.ObjectID = pw.BuildGUID
WHERE p.IfEnd = 1 
AND jp.PlanType = 103
AND jp.IsExamin = 1
-- and  jdo.OutValueViewGUID = [业务GUID]
-- and  jdo.OutValueViewGUID ='39FA8EC0-3B43-4CD1-A9AD-EF103A39D18C'

select  
    jdo.OutValueViewGUID as [月度产值回顾审批GUID],
    mp.ParentProjGUID as [一级项目GUID],
    sum(isnull(JzArea_Total,0)) as [总建筑面积], -- 项目立项指标-技术表-总建筑面积
    -- F054报表“工程状态”（同项目信息管理系统中的“工程状态”）为“在建”的项目建筑面积
    sum(case when  mp.ConstructStatus ='在建' then isnull(工程楼栋建筑面积,0) else 0 end ) as [累计开工面积], 

    --sum(isnull(SumBuildArea,0)) as 本年开工面积, --项目（分期、组团、楼栋）完成打桩或者基础垫层施工且获取施工证时间在当年的工程楼栋建筑面积合计（取实际开工完成时间在本年的产品楼栋建筑面积汇总）
    sum(case when  mp.ConstructStatus ='在建' then isnull(ld.本年开工面积,0) else 0 end ) as [本年开工面积],
    sum(case when  mp.ConstructStatus ='已完工' then isnull(工程楼栋建筑面积,0) else 0 end ) as [累计竣工面积], --F054报表“工程状态”（同项目信息管理系统中的“工程状态”）为“已完工”的项目建筑面积
    --sum(isnull(SumBuildArea,0)) as 本年竣工面积, --获取竣工备案表时间在当年的工程楼栋建筑面积合计
    sum(case when  mp.ConstructStatus ='已完工' then isnull(ld.本年竣工面积,0) else 0 end ) as [本年竣工面积],
    --sum(isnull(SumBuildArea,0)) as 当前在建面积, --累计开工面积-累计竣工面积：① 若无开工面积，有竣工面积，按照累计开工面积处理 ②剔除停工部分
    case when sum(case when  mp.ConstructStatus ='在建' then isnull(工程楼栋建筑面积,0) else 0 end ) =0
            then sum(case when  mp.ConstructStatus ='在建' then isnull(工程楼栋建筑面积,0) else 0 end ) - sum( isnull(当前停工面积,0) )
            else sum(case when  mp.ConstructStatus ='在建' then isnull(工程楼栋建筑面积,0) else 0 end ) - sum(case when  mp.ConstructStatus ='已完工' then isnull(工程楼栋建筑面积,0) else 0 end ) - sum( isnull(当前停工面积,0) )
    end as [当前在建面积], 
    --sum(isnull(SumBuildArea,0)) as 当前停工面积 --取组团01表中，状态为停工，“实际开工日期”不为空且实际竣工备案时间不为空的组团的建筑面积之和
    sum( isnull(当前停工面积,0) ) as [当前停工面积] 
from jd_OutValueView jdo
inner join erp25_test.dbo.mdm_Project  mp on mp.ProjGUID =jdo.ProjGUID
inner join erp25_test.dbo.mdm_TechTarget tt on  tt.ProjGUID =mp.ParentProjGUID
left join (
    select 分期GUID,
	  sum(isnull(工程楼栋建筑面积,0)) as 工程楼栋建筑面积,
      -- 取组团01表中，状态为停工，“实际开工日期”不为空且实际竣工备案时间不为空的组团的建筑面积之和
      sum( case when  是否停工 = '停工' and 实际开工实际完成时间 is not null and 竣工备案实际完成时间 is not null then isnull(工程楼栋建筑面积,0) else 0 end ) as 当前停工面积,
      sum( case when  datediff(year,getdate(),实际开工实际完成时间) =0 then isnull(工程楼栋建筑面积,0) else 0 end ) as 本年开工面积,
      sum( case when  datediff(year,getdate(),竣工备案实际完成时间) =0 then isnull(工程楼栋建筑面积,0) else 0 end ) as 本年竣工面积  
    from #ld
    group by 分期GUID
) ld on ld.分期GUID = mp.ProjGUID
where and  jdo.OutValueViewGUID = [业务GUID]
-- where jdo.OutValueViewGUID ='39FA8EC0-3B43-4CD1-A9AD-EF103A39D18C'
group by jdo.OutValueViewGUID,mp.ParentProjGUID

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
into #ld
FROM dbo.p_Project p 
inner join jd_OutValueView jdo on jdo.ProjGUID = p.ProjGUID
INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
INNER JOIN erp25.dbo.mdm_project mp  ON mp.projguid = p.ProjGUID
INNER JOIN erp25.dbo.mdm_project mpp ON mp.ParentProjGUID = mpp.projguid
INNER JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = p.ProjGUID
INNER JOIN pw  ON pw.BidGUID = sw.BidGUID
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
    INNER JOIN erp25.dbo.mdm_GCBuild gc  ON gc.GCBldGUID = a.BuildingGUID
    GROUP BY a.BudGUID
) wk ON wk.BudGUID = pw.BuildGUID
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

select  [分期GUID],
max([项目获取计划完成时间]) as [项目获取计划完成日期],
max([项目获取实际完成时间]) as [项目获取实际完成日期],
min([实际开工计划完成时间]) as [实际开工计划完成日期],
min([实际开工实际完成时间]) as [实际开工实际完成日期],
max([开盘销售计划完成时间]) as [开盘销售计划完成日期],
max([开盘销售实际完成时间]) as [开盘销售实际完成日期],
min([竣工备案计划完成时间]) as [竣工备案计划完成日期],
min([竣工备案实际完成时间]) as [竣工备案实际完成日期],
max([竣工备案计划完成时间]) as [竣工备案计划完成日期],
max([竣工备案实际完成时间]) as [竣工备案实际完成日期]
from  #ld
group by [分期GUID]




-- 3. 本月进度回顾情况



SELECT 
       bu.buname AS [公司名称],
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
outer  apply (
    select top  1  d.ObjectID, tg.Type as TgType 
    from jd_StopOrReturnWork tg
    left join jd_ProjectPlanTaskExecute f ON f.PlanID = tg.PlanID AND f.Level = 1
    left join jd_ProjectPlanExecute d ON d.ID = f.PlanID AND d.PlanType = 103
    where tg.ApplyState = '已审核'  and  d.ObjectID = pw.BuildGUID
	order by tg.ReturnTime desc 
) cyj 
LEFT JOIN (
    SELECT projguid,
           NodeNum,
           TaskStateNum,
           CASE 
               WHEN ISNULL(NodeNum,0) = ISNULL(TaskStateNum,0) THEN '是' 
               ELSE '否' 
           END AS isCompare
    FROM (
        SELECT jpe.projguid,
               COUNT(1) AS NodeNum,
               SUM(CASE 
                   WHEN enumTask.EnumerationName IN ('按期完成','延期完成') THEN 1 
                   ELSE 0 
               END) AS TaskStateNum
        FROM jd_ProjectPlanTaskExecute jpte
        left JOIN jd_EnumerationDictionary enumTask   ON enumTask.EnumerationType = '工作状态枚举' AND enumTask.EnumerationValue = jpte.TaskState
		inner  join jd_ProjectPlanExecute jpe on jpe.ID =jpte.PlanID
        GROUP BY jpe.projguid
    ) jppt
) gc ON gc.projguid = p.ProjGUID
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

SELECT  a.OutValueViewGUID as [OutValueViewGUID],
        ReportDate AS [汇报日期],
        b.ProjName AS [项目名称],
        b.ProjName + '(' + REPLACE(CONVERT(VARCHAR(100), a.ReportDate, 23), '-', '.') + ')形象进度回顾报告' AS [名称标题],
        c.UserName AS [创建人],
        pp.ProjName as [一级项目名称],
        pp.ProjGUID as [一级项目GUID],
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
    LEFT JOIN dbo.p_Project b ON a.ProjGUID = b.ProjGUID
    left join dbo.p_Project pp on pp.ProjCode =b.ParentCode and  pp.Level=2
    LEFT JOIN dbo.myUser c  ON c.UserGUID = a.CreatedOn
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
            sum( case when  [是否停工] = '停工'  and [实际开工实际完成时间] is not null  then isnull([工程楼栋建筑面积],0) else 0 end ) as [当前停工面积],
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
WHERE a.OutValueViewGUID = [业务GUID]


--
