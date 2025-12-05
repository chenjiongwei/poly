-- nmap_F_存货去化承诺表
USE [dss]
GO

-- EXEC usp_nmap_F_存货去化承诺表 '2025-11-05','erp25.dbo.','4558527E-7EA2-4568-8113-80C7D90AB69C',1
create  or alter   PROC [dbo].[usp_nmap_F_存货去化承诺表]
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
                             WHERE  FILLNAME = '存货去化承诺表'
                           )
    ORDER BY ENDDATE DESC;

	-- 如果不是最新版本，不更新
	IF @FILLHISTORYGUID <> @FILLHISTORYGUIDNEW
	BEGIN
		PRINT '该版本不是最新版本，故不更新'
		RETURN;
	END


	-- -- 若当前版本有数据的话，不刷新组织架构
	SELECT @COUNTNUM = COUNT(1) 
	FROM nmap_F_存货去化承诺表 
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
                             WHERE  FILLNAME = '存货去化承诺表'
                           )
			AND FILLHISTORYGUID IN (SELECT DISTINCT FILLHISTORYGUID FROM nmap_F_存货去化承诺表
			WHERE ISNULL(项目名称,'') <> '')
    ORDER BY ENDDATE DESC;	

    
	-- 刷新组织架构
	-- 存货表。公司简称、推广名称、已开工未售产品楼栋编码及名称（有【实际开工完成日期】且【产品类型为住宅或高级住宅】且【已售套数>0】且【待售套数>0】）未自动带出。
	
	SELECT 
		mp.ParentGUID as 项目GUID,
		mp.ParentName as 项目名称,
		STRING_AGG(CAST(f056.SaleBldGUID AS VARCHAR(36)), ';') AS 产品楼栋GUID列表,
		STRING_AGG(f056.产品楼栋名称, ';') AS 产品楼栋名称列表
	into  #ch
	FROM [172.16.4.161].[HighData_prod].dbo.data_wide_dws_qt_F05601 f056
	INNER JOIN [172.16.4.161].[HighData_prod].dbo.data_wide_dws_mdm_Project mp ON mp.ProjGUID = f056.ProjGUID
	WHERE f056.产品类型 IN ('住宅', '高级住宅')
		AND f056.实际开工完成日期 IS NOT NULL
		AND ISNULL(f056.已售套数, 0) > 0
		AND ISNULL(f056.待售套数, 0) > 0
	GROUP BY mp.ParentGUID, mp.ParentName


	SELECT
		newid() AS [存货去化承诺表GUID],
		@FILLHISTORYGUID AS [FillHistoryGUID],
		c.CompanyGUID AS [BusinessGUID],
        c.CompanyName AS [公司简称],
		flg.投管代码 AS [投管代码],
		a.projguid AS [项目GUID],
		a.projname AS [项目名称],
		newid() as [存货去化承诺ID],
		-- CASE WHEN d.[承诺时间] IS NOT NULL THEN d.[承诺时间] ELSE NULL END AS [承诺时间],
		-- CASE WHEN d.[已开工未售部分的的产品楼栋编码] IS NOT NULL THEN d.[已开工未售部分的的产品楼栋编码] ELSE NULL END AS [已开工未售部分的的产品楼栋编码],
		-- CASE WHEN d.[已开工未售部分的的产品楼栋名称] IS NOT NULL THEN d.[已开工未售部分的的产品楼栋名称] ELSE NULL END AS [已开工未售部分的的产品楼栋名称],

		ch.产品楼栋GUID列表 AS [已开工未售部分的的产品楼栋编码],
		ch.产品楼栋名称列表 AS [已开工未售部分的的产品楼栋名称],
		-- CASE WHEN d.[已开工未售部分的售罄时间] IS NOT NULL THEN d.[已开工未售部分的售罄时间] ELSE NULL END AS [已开工未售部分的售罄时间],
		-- CASE WHEN d.[已开工未售部分的销售均价] IS NOT NULL THEN d.[已开工未售部分的销售均价] ELSE NULL END AS [已开工未售部分的销售均价],
		-- CASE WHEN d.[已开工未售部分的去化周期] IS NOT NULL THEN d.[已开工未售部分的去化周期] ELSE NULL END AS [已开工未售部分的去化周期],
		-- CASE WHEN d.[已开工未售部分的税后净利润] IS NOT NULL THEN d.[已开工未售部分的税后净利润] ELSE NULL END AS [已开工未售部分的税后净利润],
		-- CASE WHEN d.[已开工未售部分的销净率] IS NOT NULL THEN d.[已开工未售部分的销净率] ELSE NULL END AS [已开工未售部分的销净率],
		flg.推广名 AS [推广名称]

		-- CASE WHEN d.[历史供货周期] IS NOT NULL THEN d.[历史供货周期] ELSE NULL END AS [历史供货周期],
		-- CASE WHEN d.[户型最大产销比] IS NOT NULL THEN d.[户型最大产销比] ELSE NULL END AS [户型最大产销比],
		-- CASE WHEN d.[原户型去化周期] IS NOT NULL THEN d.[原户型去化周期] ELSE NULL END AS [原户型去化周期],
		-- CASE WHEN d.[现户型去化周期] IS NOT NULL THEN d.[现户型去化周期] ELSE NULL END AS [现户型去化周期],
		-- CASE WHEN d.[存货焕新力数量] IS NOT NULL THEN d.[存货焕新力数量] ELSE NULL END AS [存货焕新力数量],
		-- CASE WHEN d.[存货焕新方案内容] IS NOT NULL THEN d.[存货焕新方案内容] ELSE NULL END AS [存货焕新方案内容],
		-- CASE WHEN d.[最后导入人] IS NOT NULL THEN d.[最后导入人] ELSE NULL END AS [最后导入人],
		-- CASE WHEN d.[最后导入时间] IS NOT NULL THEN d.[最后导入时间] ELSE GETDATE() END AS [最后导入时间]
	INTO #TempData
	FROM erp25.dbo.mdm_project a
		LEFT JOIN erp25.dbo.vmdm_projectFlagnew flg ON a.projguid = flg.projguid
		INNER JOIN erp25.dbo.p_DevelopmentCompany b ON a.DevelopmentCompanyGUID = b.DevelopmentCompanyGUID
		INNER JOIN nmap_N_CompanyToTerraceBusiness c2b ON b.DevelopmentCompanyGUID = c2b.DevelopmentCompanyGUID
		INNER JOIN nmap_N_Company c ON c2b.CompanyGUID = c.CompanyGUID
		inner join #ch  ch on ch.项目GUID =a.projguid
		-- -- 查询上一版的数据进行继承
		-- LEFT JOIN (
		-- 	SELECT DISTINCT * FROM nmap_F_存货去化承诺表
		-- 	WHERE FILLHISTORYGUID = @FILLHISTORYGUIDLAST AND ISNULL(项目GUID,'') <> ''
		-- ) d ON a.ProjGUID = d.[项目GUID]
    where  a.level =2



-- --删除旧数据  
    DELETE  FROM nmap_F_存货去化承诺表
    WHERE   FillHistoryGUID = @FillHistoryGUID;  

	 -- 将数据插入到当前版本
	INSERT INTO nmap_F_存货去化承诺表 (
		[存货去化承诺表GUID],
		[FillHistoryGUID],
		[BusinessGUID],
		[投管代码],
		[项目GUID],
		[项目名称],
		[存货去化承诺ID],
		[推广名称],
		[公司简称],
		-- [承诺时间],
		[已开工未售部分的的产品楼栋编码],
		[已开工未售部分的的产品楼栋名称]
		-- [已开工未售部分的售罄时间],
		-- [已开工未售部分的销售均价],
		-- [已开工未售部分的去化周期],
		-- [已开工未售部分的税后净利润],
		-- [已开工未售部分的销净率],


		-- [历史供货周期],
		-- [户型最大产销比],
		-- [原户型去化周期],
		-- [现户型去化周期],
		-- [存货焕新力数量],
		-- [存货焕新方案内容],
		-- [最后导入人],
		-- [最后导入时间],

	    -- [存货焕新方案-美学力],
		-- [存货焕新方案-功能力],
		-- [存货焕新方案-质量力],
		-- [存货焕新方案-智能力],
		-- [存货焕新方案-交通力],
		-- [存货焕新方案-教育力],
		-- [存货焕新方案-商业力],
		-- [存货焕新方案-休闲力],
		-- [存货焕新方案-医疗力],
		-- [存货焕新方案-安全力],
		-- [存货焕新方案-便捷力],
		-- [存货焕新方案-舒适力],
		-- [存货焕新方案-社群力],
		-- [存货焕新方案-焕新力]	
	)
	SELECT
		[存货去化承诺表GUID],
		[FillHistoryGUID],
		[BusinessGUID],
		[投管代码],
		[项目GUID],
		[项目名称],
		[存货去化承诺ID],
		[推广名称],
		[公司简称],
		-- [承诺时间],
		[已开工未售部分的的产品楼栋编码],
		[已开工未售部分的的产品楼栋名称]
		-- [已开工未售部分的售罄时间],
		-- [已开工未售部分的销售均价],
		-- [已开工未售部分的去化周期],
		-- [已开工未售部分的税后净利润],
		-- [已开工未售部分的销净率],


		-- [历史供货周期],
		-- [户型最大产销比],
		-- [原户型去化周期],
		-- [现户型去化周期],
		-- [存货焕新力数量],
		-- [存货焕新方案内容],
		-- [最后导入人],
		-- [最后导入时间],

		-- [存货焕新方案-美学力],
		-- [存货焕新方案-功能力],
		-- [存货焕新方案-质量力],
		-- [存货焕新方案-智能力],
		-- [存货焕新方案-交通力],
		-- [存货焕新方案-教育力],
		-- [存货焕新方案-商业力],
		-- [存货焕新方案-休闲力],
		-- [存货焕新方案-医疗力],
		-- [存货焕新方案-安全力],
		-- [存货焕新方案-便捷力],
		-- [存货焕新方案-舒适力],
		-- [存货焕新方案-社群力],
		-- [存货焕新方案-焕新力]
	FROM #TempData;

    	 -- 删除临时表
	 DROP TABLE #TempData,#ch

end 