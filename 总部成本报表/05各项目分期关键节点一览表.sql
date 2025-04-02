USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_项目分期成本关键节点一览表]    Script Date: 2025/4/1 15:36:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_rpt_项目分期成本关键节点一览表](@var_buguid VARCHAR(MAX))
AS
/*
存储过程功能：成本系统 项目分期成本关键节点一览表

存储过程示例：usp_rpt_项目分期成本关键节点一览表 '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8'

备注：
--20230414 经常要核对口径，为了方便修改，封装成存储过程

create by yp v1.0
*/
BEGIN
SELECT  b.ProjGUID,
		d.BUName AS '平台公司' ,
        b1.ProjShortName+'-'+b.ProjShortName AS '项目名称' ,
		mp.ProjCode AS '基础数据项目编号',
        b.ProjCode AS '项目编号' ,
		p.ProjCode 明源系统代码,
		lb.投管代码,
        b.ProjShortName AS '项目分期' ,
		CASE WHEN june.TradersWay = '我司操盘' THEN '是' ELSE '否'  END AS '是否操盘',
        c.BuildArea AS '建筑面积' ,
        c.UpperBuildArea AS '地上建筑面积' ,
        c.UnderBuildArea AS '地下建筑面积' ,
        isnull(CASE WHEN f.xmhq is null  THEN NULL ELSE f.xmhq END,lb.获取时间) AS '项目获取时间' ,
        CASE WHEN f.dwbg is null THEN NULL ELSE f.dwbg END AS '定位报告时间' ,
        CASE WHEN f.zskg is null THEN NULL ELSE f.zskg END AS '正式开工' ,
        CASE WHEN f.sjkg is null THEN NULL ELSE f.sjkg END AS '实际开工' ,
        CASE WHEN f.kpxs is null THEN NULL ELSE f.kpxs END AS '开盘销售' ,
        CASE WHEN f.ztjgfd is null THEN NULL ELSE f.ztjgfd END AS '主体结构封顶' ,
        CASE WHEN f.nbzxwc is null THEN NULL ELSE f.nbzxwc END AS '内部装修工程完成' ,
        CASE WHEN f.jgba is null THEN NULL ELSE f.jgba END  '竣工备案' ,
        DATEADD(YY, 1, (CASE WHEN f.jgba is null THEN NULL ELSE f.jgba END)) AS '竣工备案满一年' ,

        isnull(CASE WHEN f.sjxmhq is null THEN NULL ELSE f.sjxmhq END,lb.获取时间) AS '项目获取时间01' ,
        CASE WHEN f.sjdwbg is null THEN NULL ELSE f.sjdwbg END AS '定位报告时间01' ,
        CASE WHEN f.sjzskg is null THEN NULL ELSE f.sjzskg END AS '正式开工01' ,
        CASE WHEN f.sjsjkg is null THEN NULL ELSE f.sjsjkg END AS '实际开工01' ,
        CASE WHEN f.sjkpxs is null THEN NULL ELSE f.sjkpxs END AS '开盘销售01' ,
        CASE WHEN f.sjztjgfd is null THEN NULL ELSE f.sjztjgfd END AS '主体结构封顶01' ,
        CASE WHEN f.sjnbzxwc is null THEN NULL ELSE f.sjnbzxwc END AS '内部装修工程完成01' ,
        CASE WHEN f.sjjgba is null THEN NULL ELSE f.sjjgba END AS '竣工备案01' ,
        DATEADD(YY, 1, (CASE WHEN f.sjjgba is null THEN NULL ELSE f.sjjgba END)) AS '竣工备案满一年01'
FROM  p_project b  
	left join mybusinessunit d on b.buguid=d.buguid 
	LEFT JOIN ERP25.dbo.mdm_Project p ON p.ProjGUID = b.ProjGUID
	LEFT JOIN ERP25.dbo.vmdm_projectFlag lb ON lb.projGUID = ISNULL(p.ParentProjGUID,p.ProjGUID)
    left join p_Project b1 on b.ParentCode=b1.ProjCode 
	LEFT JOIN md_project mp ON mp.ProjGUID = b.ProjGUID AND mp.IsActive = '1'
    left join cb_HkbProjectIndexWork c on b.projguid=c.RefGUID 
	left join (SELECT c.projguid as projguid,
			            min(case when wh.KeyNodeName='项目获取' then b.Finish else null end) as xmhq ,
			            min(case when wh.KeyNodeName='定位报告' then b.Finish else null end) as dwbg ,
			            min(case when wh.KeyNodeName='正式开工' then b.Finish else null end) as zskg ,
			            min(case when wh.KeyNodeName='实际开工' then b.Finish else null end) as sjkg ,
			            min(case when wh.KeyNodeName='开盘销售' then b.Finish else null end) as kpxs ,
			            min(case when wh.KeyNodeName='主体结构封顶' then b.Finish else null end) as ztjgfd ,
						MAX(case when wh.KeyNodeName='内部装修工程完成' then b.Finish else null end) as nbzxwc ,
			            max(case when wh.KeyNodeName='竣工备案' then b.Finish else null end) as jgba , 
			                         
						min(case when wh.KeyNodeName='项目获取' then b.ActualFinish else null end) as sjxmhq ,
			            min(case when wh.KeyNodeName='定位报告' then b.ActualFinish else null end) as sjdwbg ,
			            min(case when wh.KeyNodeName='正式开工' then b.ActualFinish else null end) as sjzskg ,
			            min(case when wh.KeyNodeName='实际开工' then b.ActualFinish else null end) as sjsjkg ,
						min(case when wh.KeyNodeName='开盘销售' then b.ActualFinish else null end) as sjkpxs ,
			            min(case when wh.KeyNodeName='主体结构封顶' then b.ActualFinish else null end) as sjztjgfd ,
						MAX(case when wh.KeyNodeName='内部装修工程完成' then b.ActualFinish else null end) as sjnbzxwc ,
						MAX(case when wh.KeyNodeName='竣工备案' then b.ActualFinish else null end) as sjjgba
				FROM p_project c
				LEFT JOIN  p_BiddingSection pbb ON pbb.ProjGuid = c.ProjGUID
				LEFT JOIN  p_BiddingBuilding pb ON pb.BidGUID = pbb.BidGUID
				LEFT JOIN  jd_ProjectPlanExecute a ON a.ObjectID = pb.BuildGUID
				LEFT JOIN  jd_ProjectPlanTaskExecute	  b ON   b.PlanID = a.ID 
				LEFT JOIN  jd_KeyNode wh ON wh.KeyNodeGUID = b.KeyNodeID                 
				WHERE a.PlanType = '103'
				GROUP BY c.projguid ) f on b.projguid=f.projguid 
	left join (SELECT c.projguid as projguid, 
			            sum(case when b.PlanID is null then 1 else 0 end) as jgbacnt 
				FROM  p_BiddingBuilding pb   left JOIN dbo.jd_ProjectPlanExecute a on a.ObjectID=pb.BuildGUID
											left JOIN jd_ProjectPlanTaskExecute  b ON b.PlanID = a.ID and b.TaskName='竣工备案'
						                    left JOIN p_BiddingSection pbb ON pb.BidGUID=pbb.BidGUID 
							                left join p_project c on pbb.projguid=c.projguid 
				GROUP BY c.projguid ) f2 on b.projguid=f2.projguid 
	LEFT JOIN  (
			SELECT bbb.ProjCode , aaa.TradersWay ,aaa.BbWay FROM erp25..mdm_Project aaa
				LEFT JOIN dbo.p_Project bbb ON aaa.ProjGUID = bbb.ProjGUID
			WHERE aaa.level = '2'
				)june ON june.ProjCode = b.ParentCode
WHERE (1=1) 
and b.buguid in (select value from fn_Split2(@var_buguid,',') )   AND b.Level = '3'
ORDER BY   f.xmhq ASC
END