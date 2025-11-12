-- nmap_F_本次新推价量承诺表
-- 本次新推价量承诺表
USE [dss]
GO
  
--   EXEC usp_nmap_F_本次新推价量承诺表 '2025-11-05','erp25.dbo.','BA3010EF-1C15-4EC8-8DFD-81E026226104',1
create  or alter   PROC [dbo].[usp_nmap_F_本次新推价量承诺表]
    (
      @CLEANDATE DATETIME ,
      @DATABASENAME VARCHAR(100) ,
      @FILLHISTORYGUID UNIQUEIDENTIFIER ,
      @ISCURRFILLHISTORY BIT
    )
AS
begin 
    -- 打印参数
    PRINT @CLEANDATE; 
    PRINT @DATABASENAME;  
    PRINT @FILLHISTORYGUID; 
    PRINT @ISCURRFILLHISTORY; 

    -- 声明变量
    DECLARE @STRSQL VARCHAR(MAX); 
	DECLARE @COUNTNUM INT;

	-- 若为历史版本，则不刷新
	DECLARE @FILLHISTORYGUIDNEW UNIQUEIDENTIFIER;
	SELECT TOP 1 @FILLHISTORYGUIDNEW= A.FILLHISTORYGUID
    FROM    NMAP_F_FILLHISTORY A
    WHERE   FILLDATAGUID = ( SELECT FILLDATAGUID
                             FROM   NMAP_F_FILLDATA
                             WHERE  FILLNAME = '本次新推价量承诺表'
                           )
    ORDER BY ENDDATE DESC;

	-- 如果不是最新版本，不更新
	IF @FILLHISTORYGUID <> @FILLHISTORYGUIDNEW
	BEGIN
		PRINT '该版本不是最新版本，故不更新'
		RETURN;
	END


	-- 若当前版本有数据的话，不刷新组织架构
	SELECT @COUNTNUM = COUNT(1) 
	FROM nmap_F_本次新推价量承诺表 
	WHERE ISNULL(项目GUID,'') <> '' 
	  AND FILLHISTORYGUID = @FILLHISTORYGUID;

	IF @COUNTNUM > 0
	BEGIN
		PRINT '当前版本有数据，不刷新组织架构信息'
		RETURN;
	END

	-- 如果是当前批次且没有数据，重新刷新组织架构信息
	IF @ISCURRFILLHISTORY = 1 AND @COUNTNUM = 0
        BEGIN
			PRINT '新生成版本需要重新刷新组织架构信息'
            EXEC dbo.USP_NMAP_S_FILLDATASYNCH_RECREATEBATCH @FILLHISTORYGUID = @FILLHISTORYGUID;
        END;

	-- 截至日期最后,且有数据 的版本号
    DECLARE @FILLHISTORYGUIDLAST UNIQUEIDENTIFIER;
  
    SELECT TOP 1
            @FILLHISTORYGUIDLAST = A.FILLHISTORYGUID
    FROM    NMAP_F_FILLHISTORY A
    WHERE   FILLDATAGUID = ( SELECT FILLDATAGUID
                             FROM   NMAP_F_FILLDATA
                             WHERE  FILLNAME = '本次新推价量承诺表'
                           )
			AND FILLHISTORYGUID IN (SELECT DISTINCT FILLHISTORYGUID FROM nmap_F_本次新推价量承诺表
			WHERE ISNULL(项目名称,'') <> '')
    ORDER BY ENDDATE DESC;	


	-- 刷新组织架构
	SELECT
		NEWID() AS [本次新推价量承诺表GUID],
		@FILLHISTORYGUID AS [FillHistoryGUID],
		c.CompanyGUID AS [BusinessGUID],
		c.CompanyName AS [公司简称],
		flg.投管代码 AS [投管代码],
		a.projguid AS [项目GUID],
		a.projname AS [项目名称],
        flg.推广名 AS [推广名称],
		CASE WHEN d.[承诺时间] IS NOT NULL THEN d.[承诺时间] ELSE NULL END AS [承诺时间],
		CASE WHEN d.[产品楼栋编码] IS NOT NULL THEN d.[产品楼栋编码] ELSE NULL END AS [产品楼栋编码],
		CASE WHEN d.[产品楼栋名称] IS NOT NULL THEN d.[产品楼栋名称] ELSE NULL END AS [产品楼栋名称],
		CASE WHEN d.[本批开工可售面积] IS NOT NULL THEN d.[本批开工可售面积] ELSE NULL END AS [本批开工可售面积],
		CASE WHEN d.[本批开工货值] IS NOT NULL THEN d.[本批开工货值] ELSE NULL END AS [本批开工货值],
		CASE WHEN d.[供货周期] IS NOT NULL THEN d.[供货周期] ELSE NULL END AS [供货周期],
		CASE WHEN d.[去化周期] IS NOT NULL THEN d.[去化周期] ELSE NULL END AS [去化周期],
		CASE WHEN d.[本批开工后的项目累计签约回笼] IS NOT NULL THEN d.[本批开工后的项目累计签约回笼] ELSE NULL END AS [本批开工后的项目累计签约回笼],
		CASE WHEN d.[本批开工后的项目累计除地价外直投及费用] IS NOT NULL THEN d.[本批开工后的项目累计除地价外直投及费用] ELSE NULL END AS [本批开工后的项目累计除地价外直投及费用],
		CASE WHEN d.[本批开工后的项目累计贡献现金流] IS NOT NULL THEN d.[本批开工后的项目累计贡献现金流] ELSE NULL END AS [本批开工后的项目累计贡献现金流],
		CASE WHEN d.[本批开工后的一年内实现签约] IS NOT NULL THEN d.[本批开工后的一年内实现签约] ELSE NULL END AS [本批开工后的一年内实现签约],
		CASE WHEN d.[本批开工后的一年内实现回笼] IS NOT NULL THEN d.[本批开工后的一年内实现回笼] ELSE NULL END AS [本批开工后的一年内实现回笼],
		CASE WHEN d.[本批开工后的一年内除地价外直投及费用] IS NOT NULL THEN d.[本批开工后的一年内除地价外直投及费用] ELSE NULL END AS [本批开工后的一年内除地价外直投及费用],
		CASE WHEN d.[本批开工后的一年内贡献现金流] IS NOT NULL THEN d.[本批开工后的一年内贡献现金流] ELSE NULL END AS [本批开工后的一年内贡献现金流],
		CASE WHEN d.[未开工楼栋地价] IS NOT NULL THEN d.[未开工楼栋地价] ELSE NULL END AS [未开工楼栋地价],
		CASE WHEN d.[本次开工可收回地价] IS NOT NULL THEN d.[本次开工可收回地价] ELSE NULL END AS [本次开工可收回地价],
		CASE WHEN d.[回收股东占压资金] IS NOT NULL THEN d.[回收股东占压资金] ELSE NULL END AS [回收股东占压资金],
		CASE WHEN d.[本批开工的销售均价] IS NOT NULL THEN d.[本批开工的销售均价] ELSE NULL END AS [本批开工的销售均价],
		CASE WHEN d.[本批开工的可售单方成本] IS NOT NULL THEN d.[本批开工的可售单方成本] ELSE NULL END AS [本批开工的可售单方成本],
		CASE WHEN d.[本批开工的税后净利润] IS NOT NULL THEN d.[本批开工的税后净利润] ELSE NULL END AS [本批开工的税后净利润],
		CASE WHEN d.[本批开工的销净率] IS NOT NULL THEN d.[本批开工的销净率] ELSE NULL END AS [本批开工的销净率],
		NEWID() AS [本次新推量价承诺ID],
		CASE WHEN d.[新开类型] IS NOT NULL THEN d.[新开类型] ELSE NULL END AS [新开类型],
		CASE WHEN d.[被动开工原因] IS NOT NULL THEN d.[被动开工原因] ELSE NULL END AS [被动开工原因],
		CASE WHEN d.[开工后整盘销净率] IS NOT NULL THEN d.[开工后整盘销净率] ELSE NULL END AS [开工后整盘销净率],
		CASE WHEN d.[新开焕新力数量] IS NOT NULL THEN d.[新开焕新力数量] ELSE NULL END AS [新开焕新力数量],
		CASE WHEN d.[新开焕新力数量内容] IS NOT NULL THEN d.[新开焕新力数量内容] ELSE NULL END AS [新开焕新力数量内容],
		CASE WHEN d.[最后导入人] IS NOT NULL THEN d.[最后导入人] ELSE NULL END AS [最后导入人],
		CASE WHEN d.[最后导入时间] IS NOT NULL THEN d.[最后导入时间] ELSE GETDATE() END AS [最后导入时间],
		NULL AS [RowID]
	INTO #TempData
	FROM erp25.dbo.mdm_project a
		LEFT JOIN erp25.dbo.vmdm_projectFlagnew flg ON a.projguid = flg.projguid
		INNER JOIN erp25.dbo.p_DevelopmentCompany b ON a.DevelopmentCompanyGUID = b.DevelopmentCompanyGUID
		INNER JOIN nmap_N_CompanyToTerraceBusiness c2b ON b.DevelopmentCompanyGUID = c2b.DevelopmentCompanyGUID
		INNER JOIN nmap_N_Company c ON c2b.CompanyGUID = c.CompanyGUID
		-- 查询上一版的数据进行继承
		LEFT JOIN (
			SELECT DISTINCT *
			FROM nmap_F_本次新推价量承诺表
			WHERE FILLHISTORYGUID = @FILLHISTORYGUIDLAST AND ISNULL(项目GUID,'') <> ''
		) d ON a.ProjGUID = d.[项目GUID]
	WHERE a.level = 2




-- --删除旧数据  
    DELETE  FROM nmap_F_本次新推价量承诺表
    WHERE   FillHistoryGUID = @FillHistoryGUID;  

	 -- 将数据插入到当前版本
	INSERT INTO nmap_F_本次新推价量承诺表 (
	    [本次新推价量承诺表GUID]
      ,[FillHistoryGUID]
      ,[BusinessGUID]
      ,[公司简称]
      ,[投管代码]
      ,[项目名称]
      ,[项目GUID]
      ,[推广名称]
      ,[承诺时间]
      ,[产品楼栋编码]
      ,[产品楼栋名称]
      ,[本批开工可售面积]
      ,[本批开工货值]
      ,[供货周期]
      ,[去化周期]
      ,[本批开工后的项目累计签约回笼]
      ,[本批开工后的项目累计除地价外直投及费用]
      ,[本批开工后的项目累计贡献现金流]
      ,[本批开工后的一年内实现签约]
      ,[本批开工后的一年内实现回笼]
      ,[本批开工后的一年内除地价外直投及费用]
      ,[本批开工后的一年内贡献现金流]
      ,[未开工楼栋地价]
      ,[本次开工可收回地价]
      ,[回收股东占压资金]
      ,[本批开工的销售均价]
      ,[本批开工的可售单方成本]
      ,[本批开工的税后净利润]
      ,[本批开工的销净率]
      ,[本次新推量价承诺ID]
      ,[新开类型]
      ,[被动开工原因]
      ,[开工后整盘销净率]
      ,[新开焕新力数量]
      ,[新开焕新力数量内容]
      ,[最后导入人]
      ,[最后导入时间]
      ,[RowID]
	)
	SELECT
	   [本次新推价量承诺表GUID]
      ,[FillHistoryGUID]
      ,[BusinessGUID]
      ,[公司简称]
      ,[投管代码]
      ,[项目名称]
      ,[项目GUID]
      ,[推广名称]
      ,[承诺时间]
      ,[产品楼栋编码]
      ,[产品楼栋名称]
      ,[本批开工可售面积]
      ,[本批开工货值]
      ,[供货周期]
      ,[去化周期]
      ,[本批开工后的项目累计签约回笼]
      ,[本批开工后的项目累计除地价外直投及费用]
      ,[本批开工后的项目累计贡献现金流]
      ,[本批开工后的一年内实现签约]
      ,[本批开工后的一年内实现回笼]
      ,[本批开工后的一年内除地价外直投及费用]
      ,[本批开工后的一年内贡献现金流]
      ,[未开工楼栋地价]
      ,[本次开工可收回地价]
      ,[回收股东占压资金]
      ,[本批开工的销售均价]
      ,[本批开工的可售单方成本]
      ,[本批开工的税后净利润]
      ,[本批开工的销净率]
      ,[本次新推量价承诺ID]
      ,[新开类型]
      ,[被动开工原因]
      ,[开工后整盘销净率]
      ,[新开焕新力数量]
      ,[新开焕新力数量内容]
      ,[最后导入人]
      ,[最后导入时间]
      ,[RowID]
	FROM #TempData;


   	 -- 删除临时表
	 DROP TABLE #TempData; 

end 




