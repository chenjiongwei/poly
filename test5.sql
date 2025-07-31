USE [TaskCenterData]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_InitJGKFCB_BuildView]    Script Date: 2025/7/21 21:38:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	[172.16.4.132].MyCost_Erp352 改为对应环境下352数据库名
	[172.16.4.132].ERP25 改为对应环境下25数据库名
*/
ALTER PROC [dbo].[usp_cb_InitJGKFCB_BuildView]
    @ProjGUID UNIQUEIDENTIFIER ,         -- 分期GUID	
    @Filter VARCHAR(MAX),
	@ProductCostRecollectGUID UNIQUEIDENTIFIER
AS
    BEGIN
	--DECLARE @ProjGUID UNIQUEIDENTIFIER  = '549daa98-eabf-4bcd-ad10-7541a66f0dbb'
	--DECLARE @Filter VARCHAR(max) =NULL
	--DECLARE @ProductCostRecollectGUID UNIQUEIDENTIFIER
        IF @Filter = ''
            OR @Filter IS NULL
            BEGIN
                SET @Filter = '1=1';
            END;
DECLARE @iFtModeSet INT
SELECT @iFtModeSet=FtModeSet FROM dbo.cb_ProductCostRecollect WHERE ProductCostRecollectGUID=@ProductCostRecollectGUID
    --
	--SELECT * FROM dbo.md_ProductBuild
	--
        CREATE TABLE #MianDate
            (
              ProjGUID UNIQUEIDENTIFIER , --项目GUID
              BldGUID UNIQUEIDENTIFIER , --楼栋GUID
              ProductBuildGUID UNIQUEIDENTIFIER ,--产品楼栋GUID
              SaleArea MONEY , --可售面积
              SaleCwSum VARCHAR(50) , --可售车位个数
              ProductType VARCHAR(200) , --产品类型
              ProductName VARCHAR(200) ,--产品名称
              BusinessType VARCHAR(200) ,--BusinessType
              YtName VARCHAR(100) , --业态名称
              Zxbz VARCHAR(10) ,--装修标准
              IsSale VARCHAR(10) ,--是否可售
              IsHold VARCHAR(10) , --是否自持                       
              Area MONEY , --建筑面积
              JzAllArea MONEY ,--结转总面积
              JzCwSum VARCHAR(50) ,--结转车位个数
              Cost MONEY ,--总成本
              DFJSMS VARCHAR(20) ,--单方计算模式
              BldName VARCHAR(300) ,--楼栋名称
              VersionName VARCHAR(20) ,--当前版本
              JBZDate DATETIME , --获取竣备证日期
              Subject INT , --科目
		--ToLastYearArea MONEY,--截止上年已结转主营业务成本面积
		--ThisYearArea MONEY,--本年已结转主营业务成本面积
              BldCode VARCHAR(50) ,--楼栋Code
              ProductGUID UNIQUEIDENTIFIER,--产品GUID
	        );

        CREATE TABLE #SubjectData
            (
              ProductBuildGUID UNIQUEIDENTIFIER ,--产品楼栋GUID
              Subject INT
            );


	-- 1、取出最新已审核的产品楼栋信息
	-- a、取出分期下基础数据已审核最新（排除补录版本）的产品信息
        SELECT  *
        INTO    #temp_project
        FROM    ( SELECT    ROW_NUMBER() OVER ( ORDER BY CreateDate DESC ) AS RowNo ,
                            *
                  FROM      [172.16.4.132].MyCost_Erp352.dbo.md_Project
                  WHERE     ProjGUID = @ProjGUID
                            AND CreateReason <> '补录'
                            AND ApproveState = '已审核'
                ) t
        WHERE   RowNo = 1;

        SELECT  pb.*
        INTO    #temp_ProductBuild_proj
        FROM    #temp_project p
                INNER JOIN [172.16.4.132].MyCost_Erp352.dbo.md_ProductBuild pb ON p.VersionGUID = pb.VersionGUID;

	-- b、取出部分工程楼栋为激活的预售查丈、竣工验收版本的产品楼栋
        SELECT  pb.*
        INTO    #temp_ProductBuild_GCBuild
        FROM    [172.16.4.132].MyCost_Erp352.dbo.md_GCBuild gb
                INNER JOIN [172.16.4.132].MyCost_Erp352.dbo.md_ProductBuild pb ON gb.VersionGUID = pb.VersionGUID AND gb.BldGUID=pb.BldGUID	
        WHERE   IsActive = 1
                AND pb.ProjGUID = @ProjGUID
                AND gb.CurVersion IN ( '预售查丈版', '竣工验收版' );
 
	-- c、取出最新已审核的产品楼栋信息(有激活的预售查丈、竣工验收版本的产品楼栋，就取激活版本)
        SELECT  ROW_NUMBER() OVER ( ORDER BY ProductBuildGUID ) AS hh ,
                *
        INTO    #temp_ProductBuild_All
        FROM    ( SELECT DISTINCT
                            t.VersionGUID ,
                            t.ProjGUID ,
                            t.BldGUID ,
                            t.ProductBuildGUID ,
                            t.BldCode ,
                            t.SaleArea ,
                            pd.ProductType ,
                            pd.ProductName ,
                            pd.BusinessType ,
							 (CASE WHEN @iFtModeSet=0 THEN md_ProjYtSet.YtName ELSE ISNULL(pd.ProductName, '') + '-'  
                                    + ISNULL(pd.ProductType, '') + '-'  
                                    + ISNULL(pd.BusinessType, '') + '-'  
                                    + ISNULL(md_ProjYtSet.YtName, '') + '-'  
                                    + ISNULL(t.Zxbz,'')+ '-'  
                                    + ISNULL(t.IsHold, '') End ) AS FtYtName,
                            md_ProjYtSet.YtName ,
							t.Zxbz Zxbz ,
                            CASE WHEN ISNULL(t.IsSale, '否') = '是' THEN '可售'
                                 ELSE '不可售'
                            END AS IsSale ,
                            CASE WHEN ISNULL(t.IsHold, '否') = '是' THEN '持有'
                                 ELSE '不持有'
                            END AS IsHold ,
                            t.BuildArea ,
                            t.BldName ,
                            pd.ProductGUID ,
                            t.HbgNum
                  FROM      ( SELECT    *
                              FROM      #temp_ProductBuild_proj a
                              WHERE     NOT EXISTS ( SELECT b.ProductBuildGUID
                                                     FROM   #temp_ProductBuild_GCBuild b
                                                     WHERE  a.ProductBuildGUID = b.ProductBuildGUID )
                            ) t
                            LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.md_Product pd ON pd.ProductGUID = t.ProductGUID
                                                              AND t.VersionGUID = pd.VersionGUID
                            LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.md_Project md_Project ON md_Project.VersionGUID = pd.VersionGUID
                            LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.md_ProjYtSet md_ProjYtSet ON md_ProjYtSet.YtCode = pd.YtCode
                                                              AND md_ProjYtSet.ProjGUID = md_Project.ParentProjGUID
                  UNION ALL
                  SELECT DISTINCT
                            t.VersionGUID ,
                            t.ProjGUID ,
                            t.BldGUID ,
                            t.ProductBuildGUID ,
                            t.BldCode ,
                            t.SaleArea ,
                            pd.ProductType ,
                            pd.ProductName ,
                            pd.BusinessType ,
							 (CASE WHEN @iFtModeSet=0 THEN md_ProjYtSet.YtName ELSE ISNULL(pd.ProductName, '') + '-'  
                                    + ISNULL(pd.ProductType, '') + '-'  
                                    + ISNULL(pd.BusinessType, '') + '-'  
                                    + ISNULL(md_ProjYtSet.YtName, '') + '-'  
                                    + ISNULL(t.Zxbz,'')+ '-'  
                                    + ISNULL(t.IsHold, '') End ) AS FtYtName,
                            md_ProjYtSet.YtName ,
                            t.Zxbz Zxbz ,
                            CASE WHEN ISNULL(t.IsSale, '否') = '是' THEN '可售'
                                 ELSE '不可售'
                            END AS IsSale ,
                            CASE WHEN ISNULL(t.IsHold, '否') = '是' THEN '持有'
                                 ELSE '不持有'
                            END AS IsHold ,
                            t.BuildArea ,
                            t.BldName ,
                            pd.ProductGUID ,
                            t.HbgNum
                  FROM      ( SELECT    *
                              FROM      #temp_ProductBuild_GCBuild
                            ) t
                            LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.md_Product pd ON pd.ProductGUID = t.ProductGUID
                                                              AND t.VersionGUID = pd.VersionGUID
                            LEFT JOIN ( SELECT DISTINCT
                                                ProjGUID ,
                                                ParentProjGUID
                                        FROM    [172.16.4.132].MyCost_Erp352.dbo.md_Project
                                      ) p1 ON p1.ProjGUID = pd.ProjGUID
                            LEFT JOIN ( SELECT DISTINCT
                                                ProjGUID
                                        FROM    [172.16.4.132].MyCost_Erp352.dbo.md_Project
                                      ) pp1 ON pp1.ProjGUID = p1.ParentProjGUID
                            LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.md_ProjYtSet md_ProjYtSet ON md_ProjYtSet.YtCode = pd.YtCode
                                                              AND md_ProjYtSet.ProjGUID = pp1.ProjGUID
                ) q;

	-- 2、取出楼栋对应的计划时间
        SELECT  a.ProjGUID ,
                jcjh.BuildingGUID AS GCBldGUID ,
                MAX(CASE WHEN a.KeyNodeName = '竣工备案' THEN a.ActualFinish  --实际完成时间
                         ELSE NULL
                    END) JGBAActualFinish ,
                MAX(CASE WHEN a.KeyNodeName = '集中交付' THEN a.ActualFinish
                         ELSE NULL
                    END) JZZFActualFinish ,
                MAX(CASE WHEN a.KeyNodeName = '竣工备案' THEN a.Finish --计划完成时间
                         ELSE NULL
                    END) JGBAFinish ,
                MAX(CASE WHEN a.KeyNodeName = '集中交付' THEN a.Finish
                         ELSE NULL
                    END) JZZCFinish ,
                MAX(CASE WHEN a.KeyNodeName = '竣工备案' THEN a.ExpectedFinishDate --预计完成时间
                         ELSE NULL
                    END) JGBAExpectedFinishDate ,
                MAX(CASE WHEN a.KeyNodeName = '集中交付' THEN a.ExpectedFinishDate
                         ELSE NULL
                    END) JZZCExpectedFinishDate
        INTO    #temp_Plane
        FROM    ( SELECT    c.ObjectID ,
                            tc.Finish ,
                            tc.ActualFinish ,
                            tc.ExpectedFinishDate ,
                            kn.KeyNodeName ,
                            kn.KeyNodeCode ,
                            c.ProjGUID
                  FROM      [172.16.4.132].MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute tc
                            INNER JOIN [172.16.4.132].MyCost_Erp352.dbo.jd_ProjectPlanExecute c ON c.ID = tc.PlanID
                            INNER JOIN [172.16.4.132].MyCost_Erp352.dbo.jd_KeyNode kn ON kn.KeyNodeGUID = tc.KeyNodeID
                  WHERE     c.PlanType = 103
                            AND c.IsExamin = 1
                            AND kn.KeyNodeName IN ( '竣工备案', '集中交付' )
                            AND c.ProjGUID = @ProjGUID
                ) a
                LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.p_HkbBiddingBuildingWork jhbld ON a.ObjectID = jhbld.BuildGUID
                LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork jcjh ON jcjh.BudGUID = jhbld.BuildGUID
        GROUP BY jcjh.BuildingGUID ,
                a.ProjGUID;


--3.取出【当前版本】 根据房间的实测和预测面积来判断，并且将科目插入取出来,并且将数据插入#MianDate
		--a.--根据楼栋将科目插入表中
        DECLARE @SumCont INT; 
        DECLARE @i INT = 1;
        SELECT  @SumCont = COUNT(0)
        FROM    #temp_ProductBuild_All;
        DECLARE @ProductBuildGUID UNIQUEIDENTIFIER;
        WHILE @i <= @SumCont
            BEGIN
                SELECT  @ProductBuildGUID = ProductBuildGUID
                FROM    #temp_ProductBuild_All
                WHERE   hh = @i;
                INSERT  INTO #SubjectData
                        ( ProductBuildGUID, Subject )
                VALUES  ( @ProductBuildGUID, 1 ),
                        ( @ProductBuildGUID, 2 ),
                        ( @ProductBuildGUID, 3 ),
                        ( @ProductBuildGUID, 4 );
                SET @i = @i + 1;
            END;

		--b.取出【动态建筑单方】 计算总成本
	   --实际分摊模式（合同+合约）	
	  CREATE TABLE #TableSjFtMode
				(
				  CostGUID UNIQUEIDENTIFIER ,
				  SjFtModel VARCHAR(100)
				);    
	  --插入科目信息      
	  CREATE TABLE #TableData
				(
				  Id INT IDENTITY ,
				  ProductKsCbRecollectGUID UNIQUEIDENTIFIER ,
				  CostGUID UNIQUEIDENTIFIER ,
				  CostName VARCHAR(100) ,
				  CostAllName VARCHAR(500) ,
				  CostCode VARCHAR(100) ,
				  CostLevel TINYINT ,
				  IfEndCost TINYINT ,
				  DtCost MONEY DEFAULT 0 ,
				  CDtCost MONEY DEFAULT 0 ,
				  CDtAdjusCost MONEY DEFAULT 0 ,
				  CDtAdjusSumCost MONEY DEFAULT 0 ,
				  BCDtCost MONEY DEFAULT 0 ,
				  SjFtModel VARCHAR(100)
				);    

	--DECLARE @ProductCostRecollectGUID UNIQUEIDENTIFIER
 --   --获取已审核最新的成本分摊拍照列表
 --   SELECT TOP 1 @ProductCostRecollectGUID = ProductCostRecollectGUID FROM cb_ProductCostRecollect WHERE ProjGUID = @ProjGUID AND ApproveState = '已审核' order by RecollectTime DESC

         --实际分摊模式（合同+合约）
        INSERT  INTO #TableSjFtMode
                ( CostGUID ,
                  SjFtModel
                )
                SELECT DISTINCT
                        cp.CostGUID ,
                        ISNULL(cp.SjFtModel, '')
                FROM    cb_ProductCbFtRecollect cp
                WHERE   cp.ProductCostRecollectGUID = @ProductCostRecollectGUID;


	  INSERT  INTO #TableData
					( ProductKsCbRecollectGUID ,
					  CostGUID ,
					  CostName ,
					  CostAllName ,
					  CostCode ,
					  CostLevel ,
					  IfEndCost ,
					  DtCost ,
					  CDtCost ,
					  CDtAdjusCost ,
					  CDtAdjusSumCost ,
					  BCDtCost ,
					  SjFtModel    
					)
		 SELECT  a.ProductKsCbRecollectGUID ,
							a.CostGUID ,
							a.CostShortName ,
							a.CostShortName + '(' + a.CostCode + ')' AS CostAllName ,
							a.CostCode ,
							a.CostLevel ,
							a.IfEndCost ,
							ISNULL(a.DtCost, 0.00) AS DtCost ,
							ISNULL(a.CDtCost, 0.00) AS CDtCost ,
							ISNULL(a.CDtAdjusCost, 0.00) AS CDtAdjusCost ,
							ISNULL(a.CDtAdjusSumCost, 0.00) AS CDtAdjusSumCost ,
							ISNULL(a.BCDtCost, 0.00) AS BCDtCost ,
							CASE WHEN a.IfEndCost = 1
								 THEN CASE WHEN b.SumCount = 1
										   THEN ( SELECT TOP 1
															SjFtModel
												  FROM      #TableSjFtMode
												  WHERE     CostGUID = a.CostGUID
												)
										   ELSE ''
									  END
								 ELSE ''
							END AS SjFtModel
					FROM    cb_ProductKsCbRecollect a
							LEFT JOIN ( SELECT  CostGUID ,
												COUNT(1) AS SumCount
										FROM    #TableSjFtMode
										GROUP BY #TableSjFtMode.CostGUID
									  ) b ON a.CostGUID = b.CostGUID
					WHERE   a.ProductCostRecollectGUID = @ProductCostRecollectGUID AND  CostCode = '5001'		
					ORDER BY CostCode;    


		SELECT  *
			INTO    #cb_ProductKsCbDtlRecollect
			FROM    dbo.cb_ProductKsCbDtlRecollect
			WHERE   ProductKsCbRecollectGUID IN (
					SELECT  ProductKsCbRecollectGUID
					FROM    #TableData );    

		DECLARE @ProductKsCbRecollectGUID UNIQUEIDENTIFIER
		SELECT @ProductKsCbRecollectGUID = ProductKsCbRecollectGUID FROM #TableData WHERE CostCode = '5001'			
		SELECT YtCode,YtName,BuildDf INTO #DTCostRecollect FROM #cb_ProductKsCbDtlRecollect WHERE ProductKsCbRecollectGUID = @ProductKsCbRecollectGUID ORDER BY ProductKsCbRecollectGUID

        --DECLARE @RecollectGUID UNIQUEIDENTIFIER;
        --SELECT TOP 1
        --        @RecollectGUID = RecollectGUID
        --FROM    [172.16.4.132].MyCost_Erp352.dbo.cb_DTCostRecollect
        --WHERE   ProjectGUID = @ProjGUID
        --        AND ApproveState = '已审核'
        --ORDER BY RecollectDate DESC;
        --SELECT  dtr.RecollectGUID ,
        --        yt.YtCode ,
        --        yt.YtName ,
        --        ISNULL(dtr.ExcludingTaxJzDf, 0) AS BuildDf
        --INTO    #DTCostRecollect
        --FROM    [172.16.4.132].MyCost_Erp352.dbo.cb_DtCostRecollectDetails dtr
        --        LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.vcb_CostProductIndex yt ON yt.YtGUID = dtr.YtGUID
        --                                                      AND yt.ProjGUID = @ProjGUID
        --        LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.cb_Cost cost ON cost.CostGUID = dtr.CostGUID
        --        LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.p_BzItem item ON item.ItemCode = dtr.CostCode
        --WHERE   dtr.RecollectGUID = @RecollectGUID
        --        AND dtr.[Type] = '科目'
        --        AND item.ItemType = '控制科目'
        --        AND item.IsCwFt = 1
        --        AND dtr.CostCode = '5001'
        --        AND yt.YtCode IS NOT NULL
        --ORDER BY dtr.CostCode;  


		--c.关联数据插入
        INSERT  INTO #MianDate
                ( ProjGUID , --项目GUID
                  BldGUID , --楼栋GUID
                  ProductBuildGUID ,--产品楼栋GUID
                  SaleArea , --可售面积
                  ProductType , --产品类型
                  ProductName ,--产品名称
                  BusinessType ,--BusinessType
                  YtName , --业态名称
                  Zxbz ,--装修标准
                  IsSale ,--是否可售
                  IsHold , --是否自持                       
                  Area , --建筑面积
                  JzAllArea ,--结转总面积
                  JzCwSum ,--结转车位个数
                  Cost ,--总成本
                  DFJSMS ,--单方计算模式
                  BldName ,--楼栋名称
                  VersionName ,--当前版本
                  JBZDate , --获取竣备证日期
                  SaleCwSum ,   --可售车位个数
                  Subject ,   --科目
                  BldCode ,   --楼栋Code
                  ProductGUID   --产品GUID
		        )
                SELECT  t1.ProjGUID ,
                        t1.BldGUID ,
                        t1.ProductBuildGUID ,
                        t3.SaleArea ,
                        t1.ProductType ,
                        t1.ProductName ,
                        t1.BusinessType ,
                        t1.YtName ,
                        t1.Zxbz ,
                        t1.IsSale ,
                        t1.IsHold ,
                        ISNULL(t1.BuildArea, 0) ,
                        ISNULL(t3.SaleArea, 0) + ISNULL(t3.HoldArea, 0) ,
                        CASE WHEN ( ISNULL(t1.ProductType, '') + '-'
                                    + ISNULL(t1.ProductName, '') + '-'
                                    + ISNULL(t1.BusinessType, '') + '-'
                                    + ISNULL(t1.YtName, '') + '-'
                                    + ISNULL(t1.Zxbz, '') + '-'
                                    + ISNULL(t1.IsSale, '') + '-'
                                    + ISNULL(t1.IsHold, '') LIKE '%车位%'
                                    OR ISNULL(t1.ProductType, '') + '-'
                                    + ISNULL(t1.ProductName, '') + '-'
                                    + ISNULL(t1.BusinessType, '') + '-'
                                    + ISNULL(t1.YtName, '') + '-'
                                    + ISNULL(t1.Zxbz, '') + '-'
                                    + ISNULL(t1.IsSale, '') + '-'
                                    + ISNULL(t1.IsHold, '') LIKE '%车库%'
                                  )
                             THEN CAST(ISNULL(t3.SaleSpaceNum, 0)
                                  + ISNULL(t3.HoldSpaceNum, 0) AS VARCHAR(50))
			--WHEN 
			--	(ISNULL(t1.ProductType,'')+'-'+ISNULL(t1.ProductName,'')+'-'+ISNULL(t1.BusinessType,'')+'-'+ISNULL(t1.YtName,'')+'-'+ISNULL(t1.Zxbz,'')+'-'+ISNULL(t1.IsSale,'')+'-'+ ISNULL(t1.IsHold,'') LIKE '%车位%' 
			--	OR 
			--	ISNULL(t1.ProductType,'')+'-'+ISNULL(t1.ProductName,'')+'-'+ISNULL(t1.BusinessType,'')+'-'+ISNULL(t1.YtName,'')+'-'+ISNULL(t1.Zxbz,'')+'-'+ISNULL(t1.IsSale,'')+'-'+ ISNULL(t1.IsHold,'') LIKE '%车库%' 
			--	)  
			--	AND t2.roomSum<=0 THEN CAST(t1.HbgNum AS VARCHAR(50)) 
                             ELSE '--'
                        END AS JzCwSum ,
                        ROUND((ISNULL(t3.SaleArea, 0) + ISNULL(t3.HoldArea, 0)) * ISNULL(t6.BuildDf, 0),
                              2) AS Cost ,
                        CASE WHEN ( ISNULL(t1.ProductType, '') + '-'
                                    + ISNULL(t1.ProductName, '') + '-'
                                    + ISNULL(t1.BusinessType, '') + '-'
                                    + ISNULL(t1.YtName, '') + '-'
                                    + ISNULL(t1.Zxbz, '') + '-'
                                    + ISNULL(t1.IsSale, '') + '-'
                                    + ISNULL(t1.IsHold, '') LIKE '%车位%'
                                    OR ISNULL(t1.ProductType, '') + '-'
                                    + ISNULL(t1.ProductName, '') + '-'
                                    + ISNULL(t1.BusinessType, '') + '-'
                                    + ISNULL(t1.YtName, '') + '-'
                                    + ISNULL(t1.Zxbz, '') + '-'
                                    + ISNULL(t1.IsSale, '') + '-'
                                    + ISNULL(t1.IsHold, '') LIKE '%车库%'
                                  ) THEN '按车位面积/个数'
                             ELSE '--'
                        END AS DFJSMS ,
                        t1.BldName ,
                        CASE WHEN t2.ScBldArea > 0 THEN '实测面积'
                             WHEN t2.YsBldArea > 0
                                  AND t2.ScBldArea <= 0 THEN '预测面积'
                             ELSE p.CurVersion
                        END AS VersionName ,
                        CASE WHEN t4.JGBAActualFinish IS NOT NULL
                             THEN CONVERT(VARCHAR(100), t4.JGBAActualFinish, 23)
                             WHEN t4.JGBAActualFinish IS  NULL
                             THEN CASE WHEN t4.JGBAExpectedFinishDate IS NOT NULL
                                       THEN CONVERT(VARCHAR(100), t4.JGBAExpectedFinishDate, 23)
                                       WHEN t4.JGBAExpectedFinishDate IS  NULL
                                       THEN CONVERT(VARCHAR(100), t4.JGBAFinish, 23)
                                  END
                        END AS JGBADate ,
                        CASE WHEN ( ISNULL(t1.ProductType, '') + '-'
                                    + ISNULL(t1.ProductName, '') + '-'
                                    + ISNULL(t1.BusinessType, '') + '-'
                                    + ISNULL(t1.YtName, '') + '-'
                                    + ISNULL(t1.Zxbz, '') + '-'
                                    + ISNULL(t1.IsSale, '') + '-'
                                    + ISNULL(t1.IsHold, '') LIKE '%车位%'
                                    OR ISNULL(t1.ProductType, '') + '-'
                                    + ISNULL(t1.ProductName, '') + '-'
                                    + ISNULL(t1.BusinessType, '') + '-'
                                    + ISNULL(t1.YtName, '') + '-'
                                    + ISNULL(t1.Zxbz, '') + '-'
                                    + ISNULL(t1.IsSale, '') + '-'
                                    + ISNULL(t1.IsHold, '') LIKE '%车库%'
                                  )
                             THEN CAST(ISNULL(t3.SaleSpaceNum, 0) AS VARCHAR(50))
                             ELSE '--'
                        END AS SaleCwSum ,
                        t5.Subject ,
                        t1.BldCode ,
                        t1.ProductGUID
                FROM    #temp_ProductBuild_All t1
                        LEFT JOIN ( SELECT  r.ProductBldGUID ,
                                            SUM(ISNULL(r.ScBldArea, 0)) AS ScBldArea ,
                                            SUM(ISNULL(r.YsBldArea, 0)) AS YsBldArea ,
                                            COUNT(0) AS roomSum
                                    FROM    [172.16.4.132].MyCost_Erp352.dbo.md_Room r
                                            INNER JOIN #temp_ProductBuild_All b ON r.ProductBldGUID = b.ProductBuildGUID
                                    GROUP BY r.ProductBldGUID
                                  ) t2 ON t1.ProductBuildGUID = t2.ProductBldGUID
                        LEFT JOIN #temp_project p ON p.ProjGUID = t1.ProjGUID
                        LEFT JOIN [172.16.4.132].MyCost_Erp352.dbo.vs_md_productbuild_getAreaAndSpaceNumInfo t3 ON t3.BldGUID = t1.BldGUID
                                                              AND t3.ProductBuildGUID = t1.ProductBuildGUID
                                                              AND t3.ProjGUID = t1.ProjGUID
                        LEFT JOIN #temp_Plane t4 ON t4.GCBldGUID = t1.BldGUID
                        LEFT JOIN #SubjectData t5 ON t5.ProductBuildGUID = t1.ProductBuildGUID
                        LEFT JOIN #DTCostRecollect t6 ON t6.YtName = t1.FtYtName;

		-- SELECT * FROM #temp_ProductBuild_All
	--4.跨库取出销售结转 除本年的面积和本年的面积总和

		----a.取出当前年份的
		--	SELECT a.ProjGUID,
		--		   c.BldGUID,
		--		   SUM(ISNULL(c.BldArea, 0)) AS BldArea,
		--		   COUNT(0) RoomSUM
		--	INTO #BldItem1
		--	FROM [172.16.4.132].ERP25.dbo.s_Contract a
		--		INNER JOIN [172.16.4.132].ERP25.dbo.s_Trade b ON a.TradeGUID = b.TradeGUID
		--		LEFT JOIN [172.16.4.132].ERP25.dbo.p_Room c ON b.RoomGUID = c.RoomGUID
		--		LEFT JOIN [172.16.4.132].ERP25.dbo.p_Building d ON c.BldGUID = d.BldGUID
		--	WHERE a.[Status] = '激活'
		--		  AND b.JzDate IS NOT NULL
		--		  AND a.ProjGUID = @ProjGUID
		--		  AND YEAR(b.JzDate) = YEAR(GETDATE())
		--	GROUP BY c.BldGUID,
		--			 a.ProjGUID;

		--	----b.取出当前年份之前的 
		--	SELECT 
		--		a.ProjGUID,
		--		c.BldGUID,
		--		SUM(ISNULL(c.BldArea, 0)) AS YEARBldArea,
		--		COUNT(0) AS YEARRoomSUM
		--	INTO #BldItem2
		--	FROM [172.16.4.132].ERP25.dbo.s_Contract a
		--	INNER JOIN [172.16.4.132].ERP25.dbo.s_Trade b ON a.TradeGUID = b.TradeGUID
		--	LEFT  JOIN [172.16.4.132].ERP25.dbo.p_Room c ON b.RoomGUID = c.RoomGUID
		--	LEFT  JOIN [172.16.4.132].ERP25.dbo.p_Building d ON c.BldGUID = d.BldGUID
		--	WHERE	a.[Status] = '激活'
		--			AND b.JzDate IS NOT NULL
		--			AND YEAR(b.JzDate) < YEAR(GETDATE())
		--			AND a.ProjGUID = @ProjGUID
		--	GROUP BY c.BldGUID,
		--	a.ProjGUID;

		----c.将当前年和非当前年之前的更新到表#MianDate中
		--  UPDATE #MianDate SET ToLastYearArea=ISNULL(b2.YEARBldArea,0),ThisYearArea=ISNULL(b1.BldArea,0)
		--  FROM #BldItem1 b1
		--  LEFT JOIN  #BldItem2 b2 ON b2.ProjGUID = b1.ProjGUID AND b2.BldGUID = b1.BldGUID
		--  WHERE #MianDate.ProjGUID=b1.ProjGUID AND #MianDate.ProductBuildGUID=b1.BldGUID
	 
        DECLARE @SQL VARCHAR(MAX);
		  --5.输出


		declare @CarryOverDevelopGUID UNIQUEIDENTIFIER
        --已审核最新的结转单
		select top 1 @CarryOverDevelopGUID = CarryOverDevelopGUID from cb_CarryOverDevelop where ApproverState = '已审核' and projguid = @ProjGUID order by ApproveDate desc 

		
        SELECT  CarryOverDevelopSetBldDtlGUID ,
                ProductBuildGUID ,
                BldName ,
                YtFullName ,
                VersionName ,
                CONVERT(VARCHAR(100), JBZDate, 23) JBZDate ,
                ISNULL(JzAllArea, 0) AS JzAllArea ,
                JzCwSum ,
                ISNULL(Area, 0) AS Area ,
                ISNULL(SaleArea, 0) AS SaleArea ,
                SaleCwSum ,
                ISNULL(Cost, 0) AS Cost ,
                DFJSMS ,
                Subject1 ,
                ProductType ,
                ProductName ,
                BusinessType ,
                YtName ,
                Zxbz ,
                IsSale ,
                IsHold ,
                BldCode ,
                ProductGUID ,
                TotalArea ,
                TotalMoney ,
                TotalDF ,
                ToLastYearArea ,
                ToLastYearMoney ,
                ToLastYearDF ,
                ThisYearArea ,
                ThisYearMoney ,
                ThisYearDF ,
                DArea ,
                DMoney ,
                DDF,
				ProductCostRecollectName
        INTO    #MianDate1
        FROM    ( SELECT    ISNULL(b.CarryOverDevelopSetBldDtlGUID, NEWID()) AS CarryOverDevelopSetBldDtlGUID ,
                            a.ProductBuildGUID ,
                            a.BldName ,
                            ISNULL(a.ProductType, '') + '-'
                            + ISNULL(a.ProductName, '') + '-'
                            + ISNULL(a.BusinessType, '') + '-'
                            + ISNULL(a.YtName, '') + '-' + ISNULL(a.Zxbz, '')
                            + '-' + ISNULL(a.IsSale, '') + '-'
                            + ISNULL(a.IsHold, '') AS YtFullName ,
                            a.VersionName ,
                            a.JBZDate ,
                            a.JzAllArea ,
                            a.JzCwSum ,
                            a.Area ,
                            a.SaleArea ,
                            a.SaleCwSum ,
                            CASE WHEN e.CarryOverDevelopGUID IS NOT NULL THEN ISNULL(d.ZCB,0)  WHEN c.CarryOverDevelopSetGUID IS NOT NULL THEN a.Cost ELSE 0 END AS Cost,
                            CASE WHEN e.CarryOverDevelopGUID IS NOT NULL THEN d.DFJSMS WHEN c.CarryOverDevelopSetGUID IS NOT NULL THEN b.DFJSMS ELSE a.DFJSMS END AS DFJSMS ,
                            a.Subject AS Subject1 ,
                            a.ProductType ,
                            a.ProductName ,
                            a.BusinessType ,
                            a.YtName ,
                            a.Zxbz ,
                            a.IsSale ,
                            a.IsHold ,
                            a.BldCode ,
                            a.ProductGUID ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.TotalArea,0) ELSE  ISNULL(b.TotalArea, 0) END  AS TotalArea ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.TotalMoney,0) ELSE ISNULL(b.TotalMoney, 0) END  AS TotalMoney ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.TotalDF,0) ELSE ISNULL(b.TotalDF, 0) END  AS TotalDF ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.ToLastYearArea,0) ELSE ISNULL(b.ToLastYearArea, 0) END AS ToLastYearArea ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.ToLastYearMoney, 0) ELSE ISNULL(b.ToLastYearMoney, 0) END  AS ToLastYearMoney ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.ToLastYearDF, 0) ELSE  ISNULL(b.ToLastYearDF, 0) END  AS ToLastYearDF ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.ThisYearArea, 0) ELSE  ISNULL(b.ThisYearArea, 0) END  AS ThisYearArea ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.ThisYearMoney, 0) ELSE  ISNULL(b.ThisYearMoney, 0) END  AS ThisYearMoney ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(d.ThisYearDF, 0) ELSE  ISNULL(b.ThisYearDF, 0) END  AS ThisYearDF ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(a.JzAllArea, 0) - ISNULL(d.TotalArea, 0) else ISNULL(a.JzAllArea, 0) - ISNULL(b.TotalArea, 0) END AS DArea ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN ISNULL(( CASE WHEN e.CarryOverDevelopGUID IS NOT NULL THEN ISNULL(d.ZCB,0)  WHEN c.CarryOverDevelopSetGUID IS NOT NULL THEN a.Cost ELSE 0 END), 0) - ISNULL(d.TotalMoney, 0) ELSE  ISNULL(( CASE WHEN e.CarryOverDevelopGUID IS NOT NULL THEN ISNULL(d.ZCB,0)  WHEN c.CarryOverDevelopSetGUID IS NOT NULL THEN a.Cost ELSE 0 END), 0) - ISNULL(b.TotalMoney, 0) END AS DMoney ,
                            CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> '' THEN   ( ISNULL(a.Cost, 0) - ISNULL(d.TotalMoney, 0) )
                            / NULLIF(( ISNULL(a.JzAllArea, 0)
                                       - ISNULL(d.TotalArea, 0) ), 0)
							ELSE 
							   ( ISNULL(a.Cost, 0) - ISNULL(b.TotalMoney, 0) )
                            / NULLIF(( ISNULL(a.JzAllArea, 0)
                                       - ISNULL(b.TotalArea, 0) ), 0) END  AS DDF,
							case when e.ProductCostRecollectName is not null and e.ProductCostRecollectName <> ''  
									  then e.ProductCostRecollectName 
							     when c.ProductCostRecollectName is not null and c.ProductCostRecollectName <> '' 
									  then c.ProductCostRecollectName 
								  else '　' end as ProductCostRecollectName
                  FROM      #MianDate a
                            LEFT JOIN dbo.cb_CarryOverDevelopSetBldDtl b ON a.ProjGUID = b.ProjGUID
                                                              AND a.ProductBuildGUID = b.BldGUID
                                                              AND a.Subject = b.Subject
                            left join cb_CarryOverDevelopSet c on b.CarryOverDevelopSetGUID = c.CarryOverDevelopSetGUID
						    left join cb_CarryOverDevelopBldDtl d ON a.ProjGUID = d.ProjGUID
                                                              AND a.ProductBuildGUID = d.BldGUID
                                                              AND a.Subject = d.Subject and d.CarryOverDevelopGUID = @CarryOverDevelopGUID
							left join cb_CarryOverDevelop e on d.CarryOverDevelopGUID = e.CarryOverDevelopGUID
                ) s;  


		--更新待结转
        UPDATE  a
        SET     a.DMoney = b.DMoney ,
                a.DArea = b.DArea ,
                a.DDF = b.DDF
        FROM    #MianDate1 a
                LEFT JOIN ( SELECT  s.ProductBuildGUID ,
                                    s.DMoney ,
                                    s.DArea ,
                                    s.DDF
                            FROM    #MianDate1 s
                            WHERE   s.Subject1 = 4
                          ) b ON b.ProductBuildGUID = a.ProductBuildGUID;

        SET @SQL = '
		SELECT 
			CarryOverDevelopSetBldDtlGUID,
			ProductBuildGUID,
			BldName,
			YtFullName ,
			VersionName,
			CONVERT(varchar(100),JBZDate, 23) JBZDate,
			ISNULL(JzAllArea,0) AS JzAllArea,
			JzCwSum,
			ISNULL(Area,0) AS Area ,
			ISNULL(SaleArea,0) AS SaleArea ,
			SaleCwSum,
			ISNULL(Cost,0) AS Cost ,
			DFJSMS,
			CASE 
			 WHEN Subject1=1 THEN ''土地款'' 
			 WHEN Subject1=2 THEN ''资本化利息'' 
			 WHEN Subject1=3 THEN ''其他（除地价外直投、开发间接费）'' 
			 WHEN Subject1=4 THEN ''开发产品金额合计'' 
			END AS  Subject , 
			ProductType,
			ProductName,
			BusinessType,
			YtName,
			Zxbz,
			IsSale,
			IsHold,
			BldCode,
			ProductGUID,
			TotalArea ,
			TotalMoney ,
			TotalDF ,
			ToLastYearArea,
			ToLastYearMoney,
			ToLastYearDF,
			ThisYearArea,
			ThisYearMoney ,
			ThisYearDF,
			DArea,
			DMoney,
			DDF,
			ProductCostRecollectName
		FROM #MianDate1
		WHERE ' + @Filter + '
		ORDER BY BldName,YtFullName,Subject1 ASC
		';
        EXEC (@SQL);

	-- 5、删除临时表		
        DROP TABLE #temp_project;
        DROP TABLE #temp_ProductBuild_proj;
        DROP TABLE #temp_ProductBuild_GCBuild;
        DROP TABLE #temp_ProductBuild_All;
        DROP TABLE #temp_Plane;
        DROP TABLE #MianDate;
        DROP TABLE #MianDate1;
        DROP TABLE #SubjectData;
        DROP TABLE #DTCostRecollect;
		Drop table #TableSjFtMode;
		drop table #TableData;
		drop table #cb_ProductKsCbDtlRecollect;
    END; 

