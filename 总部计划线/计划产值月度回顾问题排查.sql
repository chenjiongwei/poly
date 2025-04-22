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




--- 湾区公司利率预警简讯配置
-- drop table #s_M002项目级毛利净利汇总表New

--获取符合小于-25%的签约和认购利润数据
SELECT a.projguid,
	  产品类型,
       产品名称,
       '签约' as 类型,
       SUM(本月净利润签约) * 10000 本月销售净利润,
       CASE
           WHEN SUM(本月签约金额不含税) > 0 THEN
                SUM(本月净利润签约) / SUM(本月签约金额不含税)
           ELSE 0
       END 本月净利润率,
       sum(本月净利润签约) as 本月销售利润,
       sum(本月签约套数)  as 本月销售套数,
       sum(本月签约面积) as 本月销售面积,
       sum(本月签约金额)*10000 as 本月销售金额,
       case when sum(本月签约面积) = 0 then 0 else sum(本月签约金额) / sum(本月签约面积) end*10000 as 本月销售均价
INTO #s_M002项目级毛利净利汇总表New
FROM s_M002项目级毛利净利汇总表New a 
WHERE DATEDIFF(DAY, qxdate, getdate()) = 0
AND a.OrgGuid = 'C69E89BB-A2DB-E511-80B8-E41F13C51836'
GROUP BY a.projguid,
         产品名称,
		 产品类型
HAVING (CASE
            WHEN SUM(本月签约金额不含税) > 0 THEN
                 SUM(本月净利润签约) / SUM(本月签约金额不含税)
            ELSE 0
        END
       ) <= -0.25
union all 
SELECT a.projguid,
	   产品类型,
       产品名称,
       '认购' as 类型,
       SUM(本月净利润认购) * 10000 本月销售净利润,
       CASE
           WHEN SUM(本月认购金额不含税) > 0 THEN
                SUM(本月净利润认购) / SUM(本月认购金额不含税)
           ELSE 0
       END 本月净利润率,
       sum(本月净利润认购) as 本月销售利润,
       sum(本月认购套数)  as 本月销售套数,
       sum(本月认购面积) as 本月销售面积,
       sum(本月认购金额)*10000 as 本月销售金额,
       case when sum(本月认购面积) = 0 then 0 else sum(本月认购金额) / sum(本月认购面积) end*10000  as 本月销售均价 
FROM s_M002项目级毛利净利汇总表New a 
WHERE DATEDIFF(DAY, qxdate, getdate()) = 0
AND a.OrgGuid = 'C69E89BB-A2DB-E511-80B8-E41F13C51836'
GROUP BY a.projguid,
         产品名称,
		 产品类型
HAVING (CASE
            WHEN SUM(本月认购金额不含税) > 0 THEN
                 SUM(本月净利润认购) / SUM(本月认购金额不含税)
            ELSE 0
        END
       ) <=  -0.25; 

--若签约认购数据是一致的话，只统计签约的情况
select projguid,产品名称,产品类型,本月销售金额,本月销售套数,本月销售均价,本月销售利润,本月净利润率,count(类型) as rn
into #tc
from #s_M002项目级毛利净利汇总表New 
group by projguid,产品名称,产品类型,本月销售金额,本月销售套数,本月销售均价,本月销售利润,本月净利润率
having count(类型) > 1


-- drop table #cb
--获取成本情况
select t.projguid,
       t.产品名称,
       t.产品类型,
       max(盈利规划营业成本单方+盈利规划营销费用单方+盈利规划综合管理费单方协议口径+盈利规划税金及附加单方) as 成本单方 
into #cb
 from s_M002业态净利毛利大底表 t
where OrgGuid = 'C69E89BB-A2DB-E511-80B8-E41F13C51836'
and versionType = '本月版' 
and exists (select 1 from #s_M002项目级毛利净利汇总表New a where a.projguid = t.projguid and a.产品名称 = t.产品名称)
group by t.projguid,
         t.产品名称,
	    t.产品类型;

-- drop table #res_业态合并;
--预处理业态结论数据
with res as (
select p.推广名,
t.产品类型,
t.产品名称,
t.类型,
convert(decimal(16,1),t.本月销售金额) as 本月销售金额,
convert(int,t.本月销售套数) as 本月销售套数, 
convert(int,cb.成本单方) as 成本单方,
convert(decimal(16,2),t.本月销售利润) as 本月销售利润, 
convert(decimal(16,0),t.本月净利润率*100) as 本月净利润率,
convert(int,case when t.产品类型 = '地下室/车库' then 10000 else 1 end * t.本月销售均价) as 本月销售均价
from #s_M002项目级毛利净利汇总表New t 
left join vmdm_projectFlag p on t.projguid = p.projguid
left join #cb cb on t.projguid = cb.projguid and t.产品名称 = cb.产品名称 and t.产品类型 = cb.产品类型
left join #tc tc on t.projguid = tc.projguid and t.产品名称 = tc.产品名称 and t.产品类型 = tc.产品类型 and t.类型 = '认购'
where tc.rn is null --剔除当日认购转签约的情况，以签约的为准
)
select 
 推广名,业态结论=STUFF((
        SELECT ';' + 产品名称 + '本月' + 类型 + 
            convert(varchar,本月销售金额) + '万元(' +
            convert(varchar,本月销售套数) + '套、均价' +
            convert(varchar,本月销售均价) + '元，成本单方' +
            convert(varchar,成本单方) + '元），销售利润' +
            convert(varchar,本月销售利润) + 
            '亿（销净率' + convert(varchar,本月净利润率) + '%）'
        FROM res r2
        WHERE r2.推广名 = res.推广名
        ORDER BY r2.本月净利润率 DESC
        FOR XML PATH('')
    ), 1, 1, ''),
	row_number() over(order by max(本月净利润率)) as 排序
into #res_业态合并
from res
group by 推广名  

--输出最终结论
select '248B1E17-AACB-E511-80B8-E41F13C51836' buguid,
case when t.利率结论 is null then 结论2 else 结论1+char(13)+char(10)+isnull(利率结论,'') end as 利润率通报情况
from 
(select '各位领导,截止今日19点湾区公司本月成交销净率低于-25%的项目有：' as 结论1,
'各位领导， 截止今日19点湾区公司无本月成交销净率低于-25%的项目。' as 结论2) as a
left join (select STRING_AGG(convert(varchar,t.排序)+'、'+t.推广名+t.业态结论+';',char(13)+char(10)) as 利率结论 
from #res_业态合并 t) t on 1=1 

drop table #res_业态合并,#cb,#tc,#s_M002项目级毛利净利汇总表New



-- //Version 1.0.0.1
SELECT bu.buname AS [公司名称],
       mpp.projname AS [一级项目名称],
       p.projname AS [分期名称],
	   p.ProjGUID as [分期GUID],
	   p.ProjGUID as [项目GUID],
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
        where    jpte.TaskName like '%竣工备案%'
        GROUP BY jpe.projguid
    ) jppt
) gc ON gc.projguid = p.ProjGUID
WHERE p.IfEnd = 1  
AND jp.PlanType = 103
AND jp.IsExamin = 1
and  jdo.OutValueViewGUID = [业务GUID]

SELECT  
       a.OutValueViewGUID as [月度产值回顾审批GUID],
       ReportDate AS [汇报日期],
       b.ProjName AS [项目名称],
       b.ProjName + '(' + REPLACE(CONVERT(VARCHAR(100), a.ReportDate, 23), '-', '.') + ')形象进度回顾报告' AS [名称标题],
       c.UserName AS [创建人],
        pp.ProjName as [一级项目名称],
        pp.ProjGUID as [一级项目GUID],
        [分期GUID],
        [分期GUID] as [项目GUID],
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
WHERE OutValueViewGUID = [业务GUID]
