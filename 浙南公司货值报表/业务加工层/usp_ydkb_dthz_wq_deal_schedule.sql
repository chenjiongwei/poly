USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_dthz_wq_deal_schedule]    Script Date: 2025/1/6 10:45:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
author:ltx date:20220503

运行样例：[usp_ydkb_dthz_wq_deal_schedule]
*/

ALTER PROC [dbo].[usp_ydkb_dthz_wq_deal_schedule]
AS
BEGIN

    ---------------------参数设置------------------------
    DECLARE @bnYear VARCHAR(4);
    SET @bnYear = YEAR(GETDATE());
    DECLARE @byMonth VARCHAR(2);
    SET @byMonth = MONTH(GETDATE());
    DECLARE @buguid VARCHAR(max) = '248B1E17-AACB-E511-80B8-E41F13C51836,4975b69c-9953-4dd0-a65e-9a36db8c66df,4A1E877C-A0B2-476D-9F19-B5C426173C38,31120F08-22C4-4220-8ED2-DCAD398C823C';
    DECLARE @developmentguid VARCHAR(max) = 'C69E89BB-A2DB-E511-80B8-E41F13C51836,461889dc-e991-4238-9d7c-b29e0aa347bb,5A4B2DEF-E803-49F8-9FE2-308735E7233D,7DF92561-3B0D-E711-80BA-E61F13C57837';
     
    --获取产品楼栋的楼栋计划节点信息
    SELECT sb.SaleBldGUID,
           MAX(   case when tc.ID is null then case when DATEDIFF(DAY, sb.HaveSaleConditionDate, GETDATE()) > 0 then sb.HaveSaleConditionDate else null end
		          else CASE
                      WHEN kn.KeyNodeName = '达到预售形象' THEN
                          tc.ActualFinish --实际完成时间  
                      ELSE
                          NULL
                  END end 
              ) 达到预售形象实际完成时间,
           MAX(   case when tc.ID is null then sb.HaveSaleConditionDate
		   else CASE 
                      WHEN kn.KeyNodeName = '达到预售形象' THEN
                          tc.Finish
                      ELSE
                          NULL
                  END end
              ) 达到预售形象计划完成时间,     --计划完成时间  
           MAX(   CASE
                      WHEN kn.KeyNodeName = '达到预售形象' THEN
                          tc.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) 达到预售形象预计完成时间,     
           MAX(  case when tc.ID is null then case when DATEDIFF(DAY, sb.YszGetDate, GETDATE()) > 0 then sb.YszGetDate else null end
		          else CASE
                      WHEN kn.KeyNodeName = '预售办理' THEN
                          tc.ActualFinish
                      ELSE
                          NULL
                  END end 
              ) 预售办理实际完成时间,
           MAX(   case when tc.ID is null then sb.YszGetDate
		   else CASE
                      WHEN kn.KeyNodeName = '预售办理' THEN
                          tc.Finish
                      ELSE
                          NULL
                  END end
              ) 预售办理计划完成时间,
           MAX(   CASE
                      WHEN kn.KeyNodeName = '预售办理' THEN
                          tc.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) 预售办理预计完成时间 
    INTO #cpjd
    FROM mdm_SaleBuild sb 
	left join MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute tc on sb.SaleBldGUID = tc.SaleBldGUID  AND tc.Level = 2
    left JOIN MyCost_Erp352.dbo.jd_ProjectPlanExecute c ON c.ID = tc.PlanID and c.PlanType = 103 AND c.IsExamin = 1
    left JOIN MyCost_Erp352.dbo.jd_KeyNode kn  ON kn.KeyNodeGUID = tc.KeyNodeID AND kn.KeyNodeName IN ( '达到预售形象', '预售办理' )    
    GROUP BY sb.SaleBldGUID;


    --获取工程楼栋的楼栋计划节点信息
    SELECT jcjh.BuildingGUID,
           jcjh.BuildingName,
           MAX(   CASE
                      WHEN KeyNodeName = '实际开工' THEN
                          ppte.finish
                      ELSE
                          NULL
                  END 
              ) AS 实际开工计划完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '实际开工' THEN
                          ppte.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) AS 实际开工预计完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '实际开工' THEN
                          ppte.ActualFinish
                      ELSE
                          NULL
                  END
              ) AS 实际开工实际完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '正式开工' THEN
                          ppte.finish
                      ELSE
                          NULL
                  END
              ) AS 正式开工计划完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '正式开工' THEN
                          ppte.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) AS 正式开工预计完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '正式开工' THEN
                          ppte.ActualFinish
                      ELSE
                          NULL
                  END
              ) AS 正式开工实际完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '达到预售形象' THEN
                          ppte.finish
                      ELSE
                          NULL
                  END
              ) AS 达到预售形象计划完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '达到预售形象' THEN
                          ppte.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) AS 达到预售形象预计完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '达到预售形象' THEN
                          ppte.ActualFinish
                      ELSE
                          NULL
                  END
              ) AS 达到预售形象实际完成时间, 
           MAX(   CASE
                      WHEN KeyNodeName = '预售办理' THEN
                          ppte.finish
                      ELSE
                          NULL
                  END
              ) AS 预售办理计划完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '预售办理' THEN
                          ppte.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) AS 预售办理预计完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '预售办理' THEN
                          ppte.ActualFinish
                      ELSE
                          NULL
                  END
              ) AS 预售办理实际完成时间, 
           MAX(   CASE
                      WHEN KeyNodeName = '开盘销售' THEN
                          ppte.finish
                      ELSE
                          NULL
                  END
              ) AS 开盘销售计划完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '开盘销售' THEN
                          ppte.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) AS 开盘销售预计完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '开盘销售' THEN
                          ppte.ActualFinish
                      ELSE
                          NULL
                  END
              ) AS 开盘销售实际完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '竣工备案' THEN
                          ppte.finish
                      ELSE
                          NULL
                  END
              ) AS 竣工备案计划完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '竣工备案' THEN
                          ppte.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) AS 竣工备案预计完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '竣工备案' THEN
                          ppte.ActualFinish
                      ELSE
                          NULL
                  END
              ) AS 竣工备案实际完成时间, 
           MAX(   CASE
                      WHEN KeyNodeName = '集中交付' THEN
                          ppte.finish
                      ELSE
                          NULL
                  END
              ) AS 集中交付计划完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '集中交付' THEN
                          ppte.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) AS 集中交付预计完成时间,
           MAX(   CASE
                      WHEN KeyNodeName = '集中交付' THEN
                          ppte.ActualFinish
                      ELSE
                          NULL
                  END
              ) AS 集中交付实际完成时间
    INTO #gcjd
    FROM MyCost_Erp352.dbo.jd_ProjectPlanExecute ppe
        INNER JOIN MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute ppte
            ON ppe.id = ppte.PlanID
        INNER JOIN MyCost_Erp352.dbo.jd_KeyNode kn
            ON ppte.KeyNodeID = kn.KeyNodeGUID
        LEFT JOIN MyCost_Erp352.dbo.jd_ProjectKeyNodePlanExecute knp
            ON knp.PlanID = ppte.KeyNodePlanID
        LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuildingWork jhbld
            ON ppe.objectid = jhbld.BuildGUID
        LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork jcjh
            ON jcjh.BudGUID = jhbld.BuildGUID
    WHERE KeyNodeName IN ( '实际开工', '正式开工', '达到预售形象', '预售办理', '开盘销售', '竣工备案', '集中交付' )
          AND ppe.PlanType = 103
          AND ppte.LEVEL = 1
          AND ppe.BUGUID  IN ( SELECT Value FROM dbo.fn_Split2(@buguid, ','))
    GROUP BY jcjh.BuildingGUID,
             jcjh.BuildingName;

	--计划系统没有的话，需要取投管系统的节点信息
	insert into #gcjd
	select gc.GCBldGUID,
           gc.BldName,
           gc.BuildBeginPlanDate AS 实际开工计划完成时间,
           null AS 实际开工预计完成时间,
           gc.BuildBeginFactDate AS 实际开工实际完成时间,
           SgzPlanDate AS 正式开工计划完成时间,
           null AS 正式开工预计完成时间,
           SgzFactDate AS 正式开工实际完成时间,
           SgzgcysjdPlanDate AS 达到预售形象计划完成时间,
           null AS 达到预售形象预计完成时间,
           SgzgcysjdFactDate AS 达到预售形象实际完成时间, 
           YszPlanDate AS 预售办理计划完成时间,
           null AS 预售办理预计完成时间,
           null AS 预售办理实际完成时间,
           null AS 开盘销售计划完成时间, 
           null AS 开盘销售预计完成时间,
           null AS 开盘销售实际完成时间,
           JgbabPlanDate AS 竣工备案计划完成时间,
           null AS 竣工备案预计完成时间,
           JgbabFactDate AS 竣工备案实际完成时间, 
           HyjlPlanDate AS 集中交付计划完成时间,
           null AS 集中交付预计完成时间,
           HyjlFactDate AS 集中交付实际完成时间
	from mdm_GCBuild gc 
	left join #gcjd gcjd on gc.GCBldGUID = gcjd.BuildingGUID
	where gcjd.BuildingGUID is null;
			    
    --项目节点信息
    SELECT c.ProjGUID,
           MAX(   CASE
                      WHEN kn.KeyNodeName = '现金流回正' THEN
                          tc.ActualFinish --实际完成时间  
                      ELSE
                          NULL
                  END
              ) 现金流回正实际完成时间,
           MAX(   CASE
                      WHEN kn.KeyNodeName = '现金流回正' THEN
                          tc.Finish
                      ELSE
                          NULL
                  END
              ) 现金流回正计划完成时间,     --计划完成时间  
           MAX(   CASE
                      WHEN kn.KeyNodeName = '现金流回正' THEN
                          tc.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) 现金流回正预计完成时间,  
           MAX(   CASE
                      WHEN kn.KeyNodeName = '收回股东投资' THEN
                          tc.ActualFinish
                      ELSE
                          NULL
                  END
              ) 收回股东投资实际完成时间,
           MAX(   CASE
                      WHEN kn.KeyNodeName = '收回股东投资' THEN
                          tc.Finish
                      ELSE
                          NULL
                  END
              ) 收回股东投资计划完成时间,
           MAX(   CASE
                      WHEN kn.KeyNodeName = '收回股东投资' THEN
                          tc.ExpectedFinishDate
                      ELSE
                          NULL
                  END
              ) 收回股东投资预计完成时间 
    INTO #xmjd
    FROM MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute tc
        INNER JOIN MyCost_Erp352.dbo.jd_ProjectPlanExecute c
            ON c.ID = tc.PlanID
        INNER JOIN MyCost_Erp352.dbo.jd_KeyNode kn
            ON kn.KeyNodeGUID = tc.KeyNodeID
        LEFT JOIN MyCost_Erp352.dbo.jd_ProjectKeyNodePlanExecute knp
            ON knp.PlanID = tc.KeyNodePlanID
    WHERE c.PlanType = 101
          AND c.IsExamin = 1
		  and c.BUGUID  IN ( SELECT Value FROM dbo.fn_Split2(@buguid, ','))
          AND kn.KeyNodeName IN ( '收回股东投资', '现金流回正' )
    GROUP BY c.ProjGUID;

	--获取里程碑节点信息
	--将关联楼栋进行拆分
	--SELECT c.*,
	--	   t.Value AS gcbldguid
	--INTO #jd_ProjectKeyNodePlanCompile
	--FROM MyCost_Erp352.dbo.jd_ProjectKeyNodePlanCompile c
	--	OUTER APPLY
	--(SELECT Value FROM dbo.fn_Split2(c.RelaBuildingGUID, ';') ) t
	--WHERE c.BUGUID IN (
 --                                           SELECT Value FROM dbo.fn_Split2(@buguid, ',')
 --                                       );

   select c.*,d.BuildingGUID as gcbldguid 
   INTO #jd_ProjectKeyNodePlanCompile
   from MyCost_Erp352.dbo.jd_ProjectKeyNodePlanCompile c
   left join MyCost_Erp352.dbo.p_BiddingBuilding2Building d on c.BuildGUID = d.BudGUID
   WHERE c.BUGUID IN ( SELECT Value FROM dbo.fn_Split2(@buguid, ',') );

	SELECT DISTINCT a.ParentProjGUID ProjGUID,
       a.gcbldguid, 
       CASE
           WHEN b.ApproveState = 2 THEN
               c.OfficiallyStartedDate
           ELSE
               a.OfficiallyStartedDate
       END AS 正式开工集团里程碑时间,
       CASE
           WHEN b.ApproveState = 2 THEN
               c.PreSaleConditionDate
           ELSE
               a.PreSaleConditionDate
       END AS 预售办理集团里程碑时间,
       CASE
           WHEN b.ApproveState = 2 THEN
               c.CompletionRecordDate
           ELSE
               a.CompletionRecordDate
       END AS 竣工备案集团里程碑时间,
       CASE
           WHEN b.ApproveState = 2 THEN
               c.ShgdtzDate
           ELSE
               a.ShgdtzDate
       END AS  收回股东投资集团里程碑时间,
       CASE
           WHEN b.ApproveState = 2 THEN
               c.XjlhzDate
           ELSE
               a.XjlhzDate
       END AS 现金流回正集团里程碑时间,
       CASE
           WHEN b.ApproveState = 2 THEN
               c.FactStartWorkDate
           ELSE
               a.FactStartWorkDate
       END AS 实际开工集团里程碑时间,
       CASE
           WHEN b.ApproveState = 2 THEN
               c.PreSaleImageDate
           ELSE
               a.PreSaleImageDate
       END AS 达到预售形象集团里程碑时间
	   INTO #keynode
	FROM #jd_ProjectKeyNodePlanCompile a
		LEFT JOIN MyCost_Erp352.dbo.jd_ProjectPlanCompile b
			ON b.ID = a.PlanID
		LEFT JOIN MyCost_Erp352.dbo.jd_ProjectKeyNodePlanExecute c
			ON c.PlanID = a.PlanID
			   AND c.BuildGUID = a.BuildGUID
			   AND c.ProjGUID = a.ProjGUID
			   AND c.BidGUID = a.BidGUID 
	WHERE (1 = 1)  

	    ---------------------产品楼栋粒度统计--------------------- 
    SELECT SaleBldGUID,
           ProjGUID,
           ProductType,
           GCBldGUID,
           累计开工面积,
           累计竣工面积,
           本年初在建面积,
           本年新开工面积,
           本年竣工面积,
           本年初在建面积 + 本年预计新开工面积 - 本年预计竣工面积 本年底在建面积,
           明年新开工面积,
           明年竣工面积,
           本年初在建面积 + 本年预计新开工面积+本年新开工面积 - 本年预计竣工面积 + t.明年预计新开工面积 - t.明年预计竣工面积 明年底在建面积
    INTO #hzmj
    FROM
    (
        SELECT SaleBldGUID,
               pj.ParentProjGUID ProjGUID,
               pr.ProductType ProductType,
               sb.GCBldGUID,
               CASE
                   WHEN jd.实际开工实际完成时间 IS NOT NULL THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 累计开工面积,
               CASE
                   WHEN jd.竣工备案实际完成时间 IS NOT NULL THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 累计竣工面积, 
               CASE
                   WHEN DATEDIFF(yy, ISNULL(实际开工实际完成时间,'2099-12-31'), GETDATE()) > 0
                        AND DATEDIFF(yy, ISNULL(竣工备案实际完成时间,'2099-12-31'), GETDATE()) <= 0  THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 本年初在建面积, --实际开工是在去年12月31日号前完成，但是实际竣工完成时间在12月31号之后或者是为空
               CASE
                   WHEN DATEDIFF(yy, ISNULL(实际开工实际完成时间,'2099-12-31'), GETDATE()) = 0 THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 本年新开工面积,
               CASE
                   WHEN DATEDIFF(yy, ISNULL(竣工备案实际完成时间,'2099-12-31'), GETDATE()) = 0 THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 本年竣工面积,
               CASE
                   WHEN DATEDIFF(yy, ISNULL(jd.实际开工计划完成时间,'2099-12-31'), GETDATE()) = 0 
				   and 实际开工实际完成时间 is null  THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 本年预计新开工面积,
               CASE
                   WHEN DATEDIFF(yy, ISNULL(jd.竣工备案计划完成时间,'2099-12-31'), GETDATE()) = 0 and 竣工备案实际完成时间 is null THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 本年预计竣工面积,
               CASE
                   WHEN DATEDIFF(yy, ISNULL(jd.实际开工计划完成时间,'2099-12-31'), GETDATE()) = -1 and 实际开工实际完成时间 is null THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 明年新开工面积,  --去掉已完成的开工时间
               CASE
                   WHEN DATEDIFF(yy, ISNULL(jd.竣工备案计划完成时间,'2099-12-31'), GETDATE()) = -1 and 竣工备案实际完成时间 is null THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 明年竣工面积,
               CASE
                   WHEN DATEDIFF(yy, ISNULL(jd.实际开工计划完成时间,'2099-12-31'), GETDATE()) = -1 and 实际开工实际完成时间 is null THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 明年预计新开工面积,
               CASE
                   WHEN DATEDIFF(yy, ISNULL(jd.竣工备案计划完成时间,'2099-12-31'), GETDATE()) = -1 and 竣工备案实际完成时间 is null THEN
                       ISNULL(sb.UpBuildArea,0)+ ISNULL(sb.DownBuildArea,0)
                   ELSE
                       0
               END 明年预计竣工面积
        FROM dbo.mdm_SaleBuild sb
		INNER JOIN #gcjd jd ON sb.GCBldGUID = jd.BuildingGUID
		INNER JOIN dbo.mdm_GCBuild gc ON gc.GCBldGUID = sb.GCBldGUID
		INNER JOIN dbo.mdm_Project pj ON pj.ProjGUID = gc.ProjGUID
		INNER JOIN dbo.mdm_Product pr ON pr.ProductGUID = sb.ProductGUID 
    ) t;

    IF EXISTS
    (
        SELECT *
        FROM dbo.sysobjects
        WHERE id = OBJECT_ID(N'ydkb_dthz_wq_deal_schedule')
              AND OBJECTPROPERTY(id, 'IsTable') = 1
    )
    BEGIN
        DROP TABLE ydkb_dthz_wq_deal_schedule;
    END;

    --湾区PC端节点报表
    CREATE TABLE ydkb_dthz_wq_deal_schedule
    (
        组织架构父级ID UNIQUEIDENTIFIER,
        组织架构ID UNIQUEIDENTIFIER,
        组织架构名称 VARCHAR(400),
        组织架构编码 [VARCHAR](100),
        组织架构类型 [INT],
        累计开工面积 MONEY,
        累计竣工面积 MONEY,
        本年初在建面积 MONEY,
        本年新开工面积 MONEY,
        本年竣工面积 MONEY,
        本年底在建面积 MONEY,
        明年新开工面积 MONEY,
        明年竣工面积 MONEY,
        明年底在建面积 MONEY,
        实际开工计划完成时间 DATETIME,
        实际开工预计完成时间 DATETIME,
        实际开工实际完成时间 DATETIME,
        实际开工集团里程碑时间 DATETIME,
        正式开工计划完成时间 DATETIME,
        正式开工预计完成时间 DATETIME,
        正式开工实际完成时间 DATETIME,
        正式开工集团里程碑时间 DATETIME,
        预售形象计划完成时间 DATETIME,
        预售形象预计完成时间 DATETIME,
        预售形象实际完成时间 DATETIME,
        预售形象集团里程碑时间 DATETIME,
        预售办理计划完成时间 DATETIME,
        预售办理预计完成时间 DATETIME,
        预售办理实际完成时间 DATETIME,
        预售办理集团里程碑时间 DATETIME,
        项目开盘计划完成时间 DATETIME,
        项目开盘预计完成时间 datetime,
        项目开盘实际完成时间 DATETIME,
        竣工备案计划完成时间 DATETIME,
        竣工备案预计完成时间 DATETIME,
        竣工备案实际完成时间 DATETIME,
        竣工备案集团里程碑时间 DATETIME,
        集中交付计划完成时间 DATETIME,
        集中交付预计完成时间 DATETIME,
        集中交付实际完成时间 DATETIME,
        收回股东投资集团里程碑时间 DATETIME,
        收回股东投资实际完成时间 DATETIME,
        现金流回正集团里程碑时间 DATETIME,
        现金流回正实际完成时间 DATETIME
    );

    INSERT INTO ydkb_dthz_wq_deal_schedule
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        累计开工面积,
        累计竣工面积,
        本年初在建面积,
        本年新开工面积,
        本年竣工面积,
        本年底在建面积,
        明年新开工面积,
        明年竣工面积,
        明年底在建面积,
        实际开工计划完成时间,
        实际开工预计完成时间,
        实际开工实际完成时间,
        实际开工集团里程碑时间,
        正式开工计划完成时间,
        正式开工预计完成时间,
        正式开工实际完成时间,
        正式开工集团里程碑时间,
        预售形象计划完成时间,
        预售形象预计完成时间,
        预售形象实际完成时间,
        预售形象集团里程碑时间,
        预售办理计划完成时间,
        预售办理预计完成时间,
        预售办理实际完成时间,
        预售办理集团里程碑时间,
        项目开盘计划完成时间,
        项目开盘预计完成时间,
        项目开盘实际完成时间,
        竣工备案计划完成时间,
        竣工备案预计完成时间,
        竣工备案实际完成时间,
        竣工备案集团里程碑时间,
        集中交付计划完成时间,
        集中交付预计完成时间,
        集中交付实际完成时间,
        收回股东投资集团里程碑时间,
        收回股东投资实际完成时间,
        现金流回正集团里程碑时间,
        现金流回正实际完成时间
    )
    SELECT sb.GCBldGUID 组织架构父级ID,
           bi.组织架构ID,
           bi.组织架构名称,
           bi.组织架构编码,
           6 组织架构类型,
           mj.累计开工面积,
           mj.累计竣工面积,
           mj.本年初在建面积,
           mj.本年新开工面积,
           mj.本年竣工面积,
           mj.本年底在建面积,
           mj.明年新开工面积,
           mj.明年竣工面积,
           mj.明年底在建面积,
           f.实际开工计划完成时间,
           f.实际开工预计完成时间,
           f.实际开工实际完成时间,
           NULL 实际开工集团里程碑时间,
           f.正式开工计划完成时间,
           f.正式开工预计完成时间,
           f.正式开工实际完成时间,
           NULL 正式开工集团里程碑时间,
           ld.达到预售形象计划完成时间,
           ld.达到预售形象预计完成时间,
           ld.达到预售形象实际完成时间,
           NULL 达到预售形象集团里程碑时间,
           ld.预售办理计划完成时间,
           ld.预售办理预计完成时间,
           ld.预售办理实际完成时间,
           NULL 预售办理集团里程碑时间,
           f.开盘销售计划完成时间,
           f.开盘销售预计完成时间,
           f.开盘销售实际完成时间,
           竣工备案计划完成时间,
           竣工备案预计完成时间,
           竣工备案实际完成时间,
           NULL 竣工备案集团里程碑时间,
           集中交付计划完成时间,
           集中交付预计完成时间,
           集中交付实际完成时间,
           NULL 收回股东投资集团里程碑时间,
           NULL 收回股东投资实际完成时间,
           NULL 现金流回正集团里程碑时间,
           NULL 现金流回正实际完成时间
    FROM ydkb_BaseInfo bi
        LEFT JOIN #hzmj mj
            ON mj.SaleBldGUID = bi.组织架构ID
        LEFT JOIN #cpjd ld
            ON ld.SaleBldGUID = bi.组织架构ID
        inner JOIN mdm_saleBuild sb
            ON sb.SaleBldGUID = bi.组织架构ID
        LEFT JOIN #gcjd f
            ON f.BuildingGUID = sb.GCBldGUID
    WHERE bi.组织架构类型 = 5
          AND bi.平台公司GUID IN (
                                 SELECT Value FROM dbo.fn_Split2(@developmentguid, ',')
                             );

    --插入工程楼栋的值
    INSERT INTO ydkb_dthz_wq_deal_schedule
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        累计开工面积,
        累计竣工面积,
        本年初在建面积,
        本年新开工面积,
        本年竣工面积,
        本年底在建面积,
        明年新开工面积,
        明年竣工面积,
        明年底在建面积,
        实际开工计划完成时间,
        实际开工预计完成时间,
        实际开工实际完成时间,
        实际开工集团里程碑时间,
        正式开工计划完成时间,
        正式开工预计完成时间,
        正式开工实际完成时间,
        正式开工集团里程碑时间,
        预售形象计划完成时间,
        预售形象预计完成时间,
        预售形象实际完成时间,
        预售形象集团里程碑时间,
        预售办理计划完成时间,
        预售办理预计完成时间,
        预售办理实际完成时间,
        预售办理集团里程碑时间,
        项目开盘计划完成时间,
        项目开盘预计完成时间,
        项目开盘实际完成时间,
        竣工备案计划完成时间,
        竣工备案预计完成时间,
        竣工备案实际完成时间,
        竣工备案集团里程碑时间,
        集中交付计划完成时间,
        集中交付预计完成时间,
        集中交付实际完成时间,
        收回股东投资集团里程碑时间,
        收回股东投资实际完成时间,
        现金流回正集团里程碑时间,
        现金流回正实际完成时间
    )
    SELECT bi.组织架构父级ID,
           sb.GCBldGUID 组织架构ID,
           gc.BldName 组织架构名称,
           bi.组织架构编码,
           5 组织架构类型,
           SUM(累计开工面积) AS 累计开工面积,
           SUM(累计竣工面积) AS 累计竣工面积,
           SUM(本年初在建面积) AS 本年初在建面积,
           SUM(本年新开工面积) AS 本年新开工面积,
           SUM(本年竣工面积) 本年竣工面积,
           SUM(本年底在建面积) AS 本年底在建面积,
           SUM(明年新开工面积) AS 明年新开工面积,
           SUM(明年竣工面积) AS 明年竣工面积,
           SUM(明年底在建面积) AS 明年底在建面积,
           MAX(f.实际开工计划完成时间) AS 实际开工计划完成时间,
           MAX(f.实际开工预计完成时间) AS 实际开工预计完成时间,
           MAX(f.实际开工实际完成时间) AS 实际开工实际完成时间,
           MAX(kn.实际开工集团里程碑时间) AS 实际开工集团里程碑时间,
           MAX(f.正式开工计划完成时间) AS 正式开工计划完成时间,
           MAX(f.正式开工预计完成时间) AS 正式开工预计完成时间,
           MAX(f.正式开工实际完成时间) AS 正式开工实际完成时间,
           MAX(kn.正式开工集团里程碑时间) AS 正式开工集团里程碑时间,
           MAX(f.达到预售形象计划完成时间) AS 达到预售形象计划完成时间,
           MAX(f.达到预售形象预计完成时间) AS 达到预售形象预计完成时间,
           MAX(f.达到预售形象实际完成时间) AS 达到预售形象实际完成时间,
           MAX(kn.达到预售形象集团里程碑时间) AS 达到预售形象集团里程碑时间,
           MAX(f.预售办理计划完成时间) AS 预售办理计划完成时间,
           MAX(f.预售办理预计完成时间) AS 预售办理预计完成时间,
           MAX(f.预售办理实际完成时间) AS 预售办理实际完成时间,
           MAX(kn.预售办理集团里程碑时间) AS 预售办理集团里程碑时间,
           MAX(f.开盘销售计划完成时间) AS 开盘销售计划完成时间,
           MAX(f.开盘销售预计完成时间) AS 开盘销售预计完成时间,
           MAX(f.开盘销售实际完成时间) AS 开盘销售实际完成时间,
           MAX(竣工备案计划完成时间) AS 竣工备案计划完成时间,
           MAX(竣工备案预计完成时间) AS 竣工备案预计完成时间,
           MAX(竣工备案实际完成时间) AS 竣工备案实际完成时间,
           MAX(竣工备案集团里程碑时间) AS 竣工备案集团里程碑时间,
           MAX(集中交付计划完成时间) AS 集中交付计划完成时间,
           MAX(集中交付预计完成时间) AS 集中交付预计完成时间,
           MAX(集中交付实际完成时间) AS 集中交付实际完成时间,
           NULL 收回股东投资集团里程碑时间,
           NULL 收回股东投资实际完成时间,
           NULL 现金流回正集团里程碑时间,
           NULL 现金流回正实际完成时间
    FROM ydkb_BaseInfo bi
        LEFT JOIN #hzmj mj
            ON mj.SaleBldGUID = bi.组织架构ID
        LEFT JOIN #cpjd ld
            ON ld.SaleBldGUID = bi.组织架构ID
        inner JOIN mdm_saleBuild sb
            ON sb.SaleBldGUID = bi.组织架构ID
		inner join mdm_GCBuild gc on gc.GCBldGUID = sb.GCBldGUID
        LEFT JOIN #gcjd f
            ON f.BuildingGUID = sb.GCBldGUID
		LEFT JOIN #keynode kn ON kn.gcbldguid = sb.GCBldGUID
    WHERE bi.组织架构类型 = 5  AND bi.平台公司GUID IN (
                                 SELECT Value FROM dbo.fn_Split2(@developmentguid, ',')
                             )
    GROUP BY bi.组织架构父级ID,
             sb.GCBldGUID,
             gc.BldName,
             bi.组织架构编码;

    --插入业态的值	 
    INSERT INTO ydkb_dthz_wq_deal_schedule
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        累计开工面积,
        累计竣工面积,
        本年初在建面积,
        本年新开工面积,
        本年竣工面积,
        本年底在建面积,
        明年新开工面积,
        明年竣工面积,
        明年底在建面积,
        实际开工计划完成时间,
        实际开工预计完成时间,
        实际开工实际完成时间,
        实际开工集团里程碑时间,
        正式开工计划完成时间,
        正式开工预计完成时间,
        正式开工实际完成时间,
        正式开工集团里程碑时间,
        预售形象计划完成时间,
        预售形象预计完成时间,
        预售形象实际完成时间,
        预售形象集团里程碑时间,
        预售办理计划完成时间,
        预售办理预计完成时间,
        预售办理实际完成时间,
        预售办理集团里程碑时间,
        项目开盘计划完成时间,
        项目开盘预计完成时间,
        项目开盘实际完成时间,
        竣工备案计划完成时间,
        竣工备案预计完成时间,
        竣工备案实际完成时间,
        竣工备案集团里程碑时间,
        集中交付计划完成时间,
        集中交付预计完成时间,
        集中交付实际完成时间,
        收回股东投资集团里程碑时间,
        收回股东投资实际完成时间,
        现金流回正集团里程碑时间,
        现金流回正实际完成时间
    )
    SELECT bi2.组织架构父级ID,
           bi2.组织架构ID,
           bi2.组织架构名称,
           bi2.组织架构编码,
           bi2.组织架构类型,
           SUM(累计开工面积) AS 累计开工面积,
           SUM(累计竣工面积) AS 累计竣工面积,
           SUM(本年初在建面积) AS 本年初在建面积,
           SUM(本年新开工面积) AS 本年新开工面积,
           SUM(本年竣工面积) 本年竣工面积,
           SUM(本年底在建面积) AS 本年底在建面积,
           SUM(明年新开工面积) AS 明年新开工面积,
           SUM(明年竣工面积) AS 明年竣工面积,
           SUM(明年底在建面积) AS 明年底在建面积,
           NULL AS 实际开工计划完成时间,
           NULL AS 实际开工预计完成时间,
           NULL AS 实际开工实际完成时间,
           NULL AS 实际开工集团里程碑时间,
           NULL AS 正式开工计划完成时间,
           NULL AS 正式开工预计完成时间,
           NULL AS 正式开工实际完成时间,
           NULL AS 正式开工集团里程碑时间,
           NULL AS 达到预售形象计划完成时间,
           NULL AS 达到预售形象预计完成时间,
           NULL AS 达到预售形象实际完成时间,
           NULL AS 达到预售形象集团里程碑时间,
           NULL AS 预售办理计划完成时间,
           NULL AS 预售办理预计完成时间,
           NULL AS 预售办理实际完成时间,
           NULL AS 预售办理集团里程碑时间,
           NULL AS 开盘销售计划完成时间,
           NULL as 开盘销售预计完成时间,
           NULL AS 开盘销售实际完成时间,
           NULL AS 竣工备案计划完成时间,
           NULL AS 竣工备案预计完成时间,
           NULL AS 竣工备案实际完成时间,
           NULL AS 竣工备案集团里程碑时间,
           NULL AS 集中交付计划完成时间,
           NULL AS 集中交付预计完成时间,
           NULL AS 集中交付实际完成时间,
           NULL 收回股东投资集团里程碑时间,
           NULL 收回股东投资实际完成时间,
           NULL 现金流回正集团里程碑时间,
           NULL 现金流回正实际完成时间
    FROM ydkb_BaseInfo bi2
        LEFT JOIN #hzmj mj
            ON mj.ProjGUID = bi2.组织架构父级ID
               AND mj.ProductType = bi2.组织架构名称
    WHERE bi2.组织架构类型 = 4  AND bi2.平台公司GUID IN (
                                 SELECT Value FROM dbo.fn_Split2(@developmentguid, ',')
                             )
    GROUP BY bi2.组织架构父级ID,
             bi2.组织架构ID,
             bi2.组织架构名称,
             bi2.组织架构编码,
             bi2.组织架构类型;

    --循环插入项目，城市公司，平台公司的值   
    DECLARE @baseinfo INT;
    SET @baseinfo = 4;

    WHILE (@baseinfo > 1)
    BEGIN

        INSERT INTO ydkb_dthz_wq_deal_schedule
        (
            组织架构父级ID,
            组织架构ID,
            组织架构名称,
            组织架构编码,
            组织架构类型,
            累计开工面积,
            累计竣工面积,
            本年初在建面积,
            本年新开工面积,
            本年竣工面积,
            本年底在建面积,
            明年新开工面积,
            明年竣工面积,
            明年底在建面积,
            实际开工计划完成时间,
            实际开工预计完成时间,
            实际开工实际完成时间,
            实际开工集团里程碑时间,
            正式开工计划完成时间,
            正式开工预计完成时间,
            正式开工实际完成时间,
            正式开工集团里程碑时间,
            预售形象计划完成时间,
            预售形象预计完成时间,
            预售形象实际完成时间,
            预售形象集团里程碑时间,
            预售办理计划完成时间,
            预售办理预计完成时间,
            预售办理实际完成时间,
            预售办理集团里程碑时间,
            项目开盘计划完成时间,
            项目开盘预计完成时间,
            项目开盘实际完成时间,
            竣工备案计划完成时间,
            竣工备案预计完成时间,
            竣工备案实际完成时间,
            竣工备案集团里程碑时间,
            集中交付计划完成时间,
            集中交付预计完成时间,
            集中交付实际完成时间,
            收回股东投资集团里程碑时间,
            收回股东投资实际完成时间,
            现金流回正集团里程碑时间,
            现金流回正实际完成时间
        )
        SELECT bi.组织架构父级ID,
               bi.组织架构ID,
               bi.组织架构名称,
               bi.组织架构编码,
               bi.组织架构类型,
               SUM(累计开工面积) AS 累计开工面积,
               SUM(累计竣工面积) AS 累计竣工面积,
               SUM(本年初在建面积) AS 本年初在建面积,
               SUM(本年新开工面积) AS 本年新开工面积,
               SUM(本年竣工面积) 本年竣工面积,
               SUM(本年底在建面积) AS 本年底在建面积,
               SUM(明年新开工面积) AS 明年新开工面积,
               SUM(明年竣工面积) AS 明年竣工面积,
               SUM(明年底在建面积) AS 明年底在建面积,
               NULL AS 实际开工计划完成时间,
               NULL AS 实际开工预计完成时间,
               NULL AS 实际开工实际完成时间,
               NULL AS 实际开工集团里程碑时间,
               NULL AS 正式开工计划完成时间,
               NULL AS 正式开工预计完成时间,
               NULL AS 正式开工实际完成时间,
               NULL AS 正式开工集团里程碑时间,
               NULL AS 达到预售形象计划完成时间,
               NULL AS 达到预售形象预计完成时间,
               NULL AS 达到预售形象实际完成时间,
               NULL AS 达到预售形象集团里程碑时间,
               NULL AS 预售办理计划完成时间,
               NULL AS 预售办理预计完成时间,
               NULL AS 预售办理实际完成时间,
               NULL AS 预售办理集团里程碑时间,
               NULL AS 开盘销售计划完成时间,
               NULL as 开盘销售预计完成时间,
               NULL AS 开盘销售实际完成时间,
               NULL AS 竣工备案计划完成时间,
               NULL AS 竣工备案预计完成时间,
               NULL AS 竣工备案实际完成时间,
               NULL AS 竣工备案集团里程碑时间,
               NULL AS 集中交付计划完成时间,
               NULL AS 集中交付预计完成时间,
               NULL AS 集中交付实际完成时间,
               NULL 收回股东投资集团里程碑时间,
               NULL 收回股东投资实际完成时间,
               NULL 现金流回正集团里程碑时间,
               NULL 现金流回正实际完成时间
        FROM ydkb_dthz_wq_deal_schedule b
            INNER JOIN ydkb_BaseInfo bi
                ON bi.组织架构ID = b.组织架构父级ID
        WHERE b.组织架构类型 = @baseinfo
        GROUP BY bi.组织架构父级ID,
                 bi.组织架构ID,
                 bi.组织架构名称,
                 bi.组织架构编码,
                 bi.组织架构类型;

        SET @baseinfo = @baseinfo - 1;
    END;

    --更新项目节点信息
    UPDATE t
    SET t.现金流回正实际完成时间 = jd.现金流回正实际完成时间,
        t.现金流回正集团里程碑时间 = kn.现金流回正集团里程碑时间,
        t.收回股东投资实际完成时间 = jd.收回股东投资实际完成时间,
        t.收回股东投资集团里程碑时间 = kn.收回股东投资集团里程碑时间
    FROM dbo.ydkb_dthz_wq_deal_schedule t
        left JOIN #xmjd jd
            ON t.组织架构ID = jd.ProjGUID
		LEFT JOIN (SELECT DISTINCT kn.ProjGUID,kn.收回股东投资集团里程碑时间,kn.现金流回正集团里程碑时间 FROM #keynode kn) kn ON t.组织架构ID = kn.ProjGUID 
    WHERE 组织架构类型 = 3;

    SELECT * FROM dbo.ydkb_dthz_wq_deal_schedule;

    --删除临时表
    DROP TABLE #cpjd,#gcjd,#hzmj,#xmjd,#jd_ProjectKeyNodePlanCompile,#keynode;

END;
 

  
 
  