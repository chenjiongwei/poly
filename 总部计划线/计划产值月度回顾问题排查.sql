-- 洞哥 有三个个调整点抽空帮忙看看哈。 @陈炯蔚  
-- 1、进度计划系统报表调整：新增展示未审核和审核中的数据
-- 2、形象进度回顾业务对象：【分期当前停工面积】新增识别楼栋实际开工节点汇报情况下，才纳入统计，未汇报开工完成的停工楼栋不纳入统计。

-- 然后有个问题：
-- 1、宜昌山海大观-二期，分期当前停工面积应该为0，它属于历史有停工，后面已复工了，现在没有停工面积。

SELECT bu.buname AS [公司名称],
       mpp.projname AS [一级项目名称],
       p.projname AS [分期名称],
	   p.ProjGUID as [分期GUID],
	   jp.id,
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
and  jdo.OutValueViewGUID = 'A33026B2-14E3-46CD-9810-8FD2F802B091'



SELECT ReportDate AS [汇报日期],
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
       where  jdo.OutValueViewGUID = 'A33026B2-14E3-46CD-9810-8FD2F802B091'
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
WHERE OutValueViewGUID = 'A33026B2-14E3-46CD-9810-8FD2F802B091'
