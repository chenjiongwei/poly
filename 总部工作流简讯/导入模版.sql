USE [dss]
GO
/****** Object:  StoredProcedure [dbo].[usp_nmap_F_明源及盈利规划业态单方沉淀表]    Script Date: 2025/3/27 17:21:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[usp_nmap_F_明源及盈利规划业态单方沉淀表]
    (
      @CleanDate DATETIME ,
      @DataBaseName VARCHAR(100) ,
      @FillHistoryGUID UNIQUEIDENTIFIER ,
      @IsCurrFillHistory BIT
    )
AS /*

	参数：@CleanDate  清洗日期
		  @DataBaseName 数据库地址
		  @FillHistoryGUID 填报批次
		  @IsCurrFillHistory 是否当前批次
	功能：明源及盈利规划业态单方沉淀表
	创建者：lintx
	创建日期：2022-09-22

	运行样例：
	SELECT TOP 1
            a.FillHistoryGUID
    FROM    nmap_F_FillHistory a
    WHERE   FillDataGUID = ( SELECT FillDataGUID
                             FROM   nmap_F_FillData
                             WHERE  FillName = '明源及盈利规划业态单方沉淀表'
                           )
			and FillHistoryGUID in (select distinct FillHistoryGUID from nmap_F_明源及盈利规划业态单方沉淀表
					where isnull(盈利规划主键,'') <> '')
    ORDER BY EndDate DESC;

	EXEC [usp_nmap_F_明源及盈利规划业态单方沉淀表] '2023-09-04 15:13:22','[172.16.4.161].[highdata_prod].dbo.','3F462F8A-0ED4-4818-988A-B7EEAB48A644',1


	modify：lintx  date：20230227
	1、主键增加产品类型
	2、修改盈利规划跟明源的连接方式为映射后的业态

	modify：lintx date:20230902
	1、沉淀表增加分期维度
*/

    PRINT @CleanDate; 
    PRINT @DataBaseName;  
    PRINT @FillHistoryGUID; 
    PRINT @IsCurrFillHistory; 

    DECLARE @strSql VARCHAR(MAX); 
	declare @Countnum int;


	--若为历史版本，则不刷新
	DECLARE @FillHistoryGUIDNew UNIQUEIDENTIFIER;
	SELECT TOP 1 @FillHistoryGUIDNew= a.FillHistoryGUID
    FROM    nmap_F_FillHistory a
    WHERE   FillDataGUID = ( SELECT FillDataGUID
                             FROM   nmap_F_FillData
                             WHERE  FillName = '明源及盈利规划业态单方沉淀表'
                           )
    ORDER BY EndDate DESC;

	if @FillHistoryGUID <> @FillHistoryGUIDNew
	begin
		print '该版本不是最新版本，故不更新'
		return;
	end

	--当是当前批次时,刷新组织纬度,即根据填报类型(自定义/公司级/项目级)生成对应的组织架构信息
	--若当前版本有数据的话，不刷新组织架构
	select @Countnum=count(1) from nmap_F_明源及盈利规划业态单方沉淀表 
	where isnull(盈利规划主键,'') <> '' and FillHistoryGUID = @FillHistoryGUID;
    
	IF @IsCurrFillHistory = 1 and @Countnum = 0
        BEGIN
			print '新生成版本需要重新刷新组织架构信息'
            EXEC dbo.usp_nmap_S_FillDataSynch_ReCreateBatch @FillHistoryGUID = @FillHistoryGUID;
        END;
		 
 --#my 获取基础数据基本情况 
    CREATE TABLE #my
        (
          公司guid UNIQUEIDENTIFIER , 
		  项目guid UNIQUEIDENTIFIER ,
		  项目名称 varchar(500) ,
		  项目代码 varchar(20) ,
          项目投管代码 varchar(20) ,
          分期guid UNIQUEIDENTIFIER ,
		  分期 varchar(500) ,
		  盈利规划上线方式 varchar(20) ,
		  基础数据产品类型 varchar(20) ,
          基础数据产品名称 varchar(20) ,
		  基础数据商品类型 varchar(20) ,
		  基础数据装修标准 varchar(20) ,
          基础数据主键 varchar(200) ,
          基础数据分期主键 varchar(200)   
	    );

	 SET @strSql = ' 
	 insert into #my(公司guid,项目guid,项目名称,项目代码,项目投管代码,分期guid,分期,盈利规划上线方式,基础数据产品类型,基础数据产品名称,基础数据商品类型,基础数据装修标准,基础数据主键,基础数据分期主键)
	 select distinct 
	 do.DevelopmentCompanyGUID as 公司guid, 
	 pj.ProjGUID as 项目guid,
	 pj.SpreadName as 项目名称,
	 pj.projcode_25 as 项目代码,
	 pj.TgProjCode as 项目投管代码,
     fq.projguid as 分期guid,
     fq.spreadname as 分期,
	 pj.ylghsxfs as 盈利规划上线方式,
	 isnull(pd.TopProductTypeName,'''') as 基础数据产品类型,
	 isnull(pd.ProductName,'''') as 基础数据产品名称,
	 isnull(pd.BusinessType,'''') as 基础数据商品类型,
	 isnull(pd.Standard,'''') as 基础数据装修标准,
     isnull(pj.projcode_25,'''')+''_''+isnull(pd.topproducttypename,'''')+''_''+isnull(pd.ProductName,'''')+''_''+isnull(pd.BusinessType,'''')+''_''+isnull(pd.Standard,'''') as 基础数据主键 ,
	 isnull(fq.spreadname,'''')+''_''+isnull(pj.projcode_25,'''')+''_''+isnull(pd.topproducttypename,'''')+''_''+isnull(pd.ProductName,'''')+''_''+isnull(pd.BusinessType,'''')+''_''+isnull(pd.Standard,'''') as 基础数据分期主键 
	 from  ' + @DataBaseName + 'data_wide_dws_mdm_Project pj 
	 inner join  ' + @DataBaseName + 'data_wide_dws_s_Dimension_Organization do on do.OrgGUID = pj.BUGUID
	 inner join  ' + @DataBaseName + 'data_wide_dws_mdm_Project fq on pj.ProjGUID = fq.ParentGUID
	 inner join ' + @DataBaseName + 'data_wide_dws_mdm_Product pd on fq.ProjGUID = pd.ProjectGuid
	 where pj.Level = 2;' 
    
	
    PRINT 0;
    EXEC(@strSql);
 
 --#ylgh 获取盈利规划基本情况 
	
    CREATE TABLE #ylgh
        (
          公司Guid UNIQUEIDENTIFIER ,  
		      项目guid UNIQUEIDENTIFIER ,
		      项目名称 varchar(500) ,
		      项目代码 varchar(20) ,
          项目投管代码 varchar(20) ,
          分期guid UNIQUEIDENTIFIER ,
		      分期 varchar(500) ,
		      盈利规划主键 varchar(200),
          盈利规划主键_明源 varchar(200) , 
          盈利规划分期主键 varchar(200),
          盈利规划分期主键_明源 varchar(200)  
	    );
		  
    SET @strSql = ' 
    insert into #ylgh(公司Guid,项目guid,项目名称,项目代码,项目投管代码,分期guid,分期,盈利规划主键,盈利规划主键_明源,盈利规划分期主键,盈利规划分期主键_明源) 
    SELECT distinct  
           do.DevelopmentCompanyGUID  AS 公司Guid,
           pj.ProjGUID AS 项目Guid,
           pj.SpreadName AS 项目名称,
           pj.projcode_25 AS 项目代码,
           pj.TgProjCode AS 项目投管代码, 
           fq.projguid as 分期guid,
           fq.spreadname as 分期,
           isnull(pj.projcode_25,'''')+''_''+isnull(yt.topproducttype,'''')+''_''+isnull(yt.ytname,'''') 盈利规划主键 ,
           isnull(pj.projcode_25,'''')+''_''+isnull(yt.topproducttype,'''')+''_''+isnull(yt.ytname_my,'''') 盈利规划主键_明源,
           isnull(fq.spreadname,'''')+''_''+isnull(pj.projcode_25,'''')+''_''+isnull(yt.topproducttype,'''')+''_''+isnull(yt.ytname,'''') 盈利规划分期主键 ,
           isnull(fq.spreadname,'''')+''_''+isnull(pj.projcode_25,'''')+''_''+isnull(yt.topproducttype,'''')+''_''+isnull(yt.ytname_my,'''') 盈利规划分期主键_明源
    FROM  ' + @DataBaseName + 'data_wide_dws_ys_SumProjProductYt yt
    INNER JOIN  ' + @DataBaseName + 'data_wide_dws_ys_ProjGUID p ON p.YLGHProjGUID = yt.ProjGUID
    AND p.isbase = 1
    AND p.Level = 3
    INNER JOIN ' + @DataBaseName + 'data_wide_dws_mdm_Project fq ON p.YLGHProjGUID = fq.ProjGUID 
    INNER JOIN ' + @DataBaseName + 'data_wide_dws_mdm_Project pj ON p.ProjGUID = pj.ProjGUID 
    INNER JOIN ' + @DataBaseName + 'data_wide_dws_s_Dimension_Organization DO ON pj.BUGUID = DO.OrgGUID
    WHERE yt.IsBase = 1
      AND pj.Level = 2
      AND yt.YtName <> ''不区分业态''; ';
    PRINT 1;
    EXEC(@strSql);
	 
       
           
    --DECLARE @Drr AS VARCHAR(500);  
    --DECLARE @DrDate AS DATETIME;  
    --SELECT TOP 1
    --        @Drr = [最后导入人] ,
    --        @DrDate = [最后导入时间]
    --FROM    [nmap_F_明源及盈利规划业态单方沉淀表]
    --WHERE   FillHistoryGUID = @FillHistoryGUID; 
  
    CREATE TABLE #TempData
        (   明源及盈利规划业态单方沉淀表GUID UNIQUEIDENTIFIER,	
			FillHistoryGUID UNIQUEIDENTIFIER,	
			BusinessGUID UNIQUEIDENTIFIER,	
			公司简称 VARCHAR(400),	
			项目guid VARCHAR(400),	
			项目名称 VARCHAR(400),	
			项目代码 VARCHAR(400),	
			项目投管代码 VARCHAR(400),	
			盈利规划上线方式 VARCHAR(400),	
			基础数据产品类型 VARCHAR(400),	
			基础数据产品名称 VARCHAR(400),	
			基础数据商品类型 VARCHAR(400),
			基础数据装修标准 VARCHAR(400),	
			基础数据主键 VARCHAR(400),	
			盈利规划系统自动匹对主键 VARCHAR(400),	
			盈利规划主键 VARCHAR(400),	
			[营业成本单方(元/平方米)]	MONEY,
			[营销费用单方(元/平方米)]	MONEY,
			[综合管理费单方(元/平方米)] MONEY,	
			[股权溢价单方(元/平方米)] MONEY,	
			[税金及附加单方(元/平方米)] MONEY,	
			[除地价外直投单方(元/平方米)]	MONEY,
			[土地款单方(元/平方米)] MONEY,	
			[资本化利息单方(元/平方米)] MONEY,	
			[开发间接费单方(元/平方米)] MONEY,	
			最后导入人 VARCHAR(400),	
			最后导入时间 datetime ,
			RowID  INT ,
            [分期] [varchar](400) ,
	        [基础数据分期主键] [varchar](400) ,
	        [盈利规划系统自动匹配分期主键] [varchar](400) ,
	        [盈利规划分期主键] [varchar](400) ,
	        [分期营业成本单方(元/平方米)] [money] ,
	        [分期营销费用单方(元/平方米)] [money] ,
	        [分期综合管理费单方(元/平方米)] [money] ,
	        [分期股权溢价单方(元/平方米)] [money] ,
	        [分期税金及附加单方(元/平方米)] [money] ,
	        [分期除地价外直投单方(元/平方米)] [money] ,
	        [分期土地款单方(元/平方米)] [money] ,
	        [分期资本化利息单方(元/平方米)] [money] ,
	        [分期开发间接费单方(元/平方米)] [money] 
        );

    PRINT 2;
  
	--截至日期最后,且有数据 的版本号
    DECLARE @FillHistoryGUIDLast UNIQUEIDENTIFIER;
  
    SELECT TOP 1
            @FillHistoryGUIDLast = a.FillHistoryGUID
    FROM    nmap_F_FillHistory a
    WHERE   FillDataGUID = ( SELECT FillDataGUID
                             FROM   nmap_F_FillData
                             WHERE  FillName = '明源及盈利规划业态单方沉淀表'
                           )
			and FillHistoryGUID in (select distinct FillHistoryGUID from nmap_F_明源及盈利规划业态单方沉淀表
					where isnull(盈利规划主键,'') <> '')
            --AND a.ApproveStatus = '已审核' 
			--and a.FillHistoryGUID <> @FillHistoryGUID
    ORDER BY EndDate DESC;
  
    SET @strSql = ' 
      insert into  #TempData ( 明源及盈利规划业态单方沉淀表GUID, 
      FillHistoryGUID,  
      BusinessGUID, 
      公司简称,  

      项目guid, 
      项目名称, 
      项目代码, 
      项目投管代码, 
      盈利规划上线方式, 
      基础数据产品类型, 
      基础数据产品名称, 
	  基础数据商品类型,
      基础数据装修标准, 
      基础数据主键, 
      盈利规划系统自动匹对主键, 
      盈利规划主键, 
      [营业成本单方(元/平方米)] ,
      [营销费用单方(元/平方米)] ,
      [综合管理费单方(元/平方米)], 
      [股权溢价单方(元/平方米)],  
      [税金及附加单方(元/平方米)], 
      [除地价外直投单方(元/平方米)] ,
      [土地款单方(元/平方米)], 
      [资本化利息单方(元/平方米)], 
      [开发间接费单方(元/平方米)], 
      最后导入人,  
      最后导入时间 ,

      [分期] ,
	  [基础数据分期主键] ,
	  [盈利规划分期主键]  ,
	  [盈利规划系统自动匹配分期主键],
	  [分期营业成本单方(元/平方米)] ,
	  [分期营销费用单方(元/平方米)] ,
	  [分期综合管理费单方(元/平方米)] ,
	  [分期股权溢价单方(元/平方米)] ,
	  [分期税金及附加单方(元/平方米)] ,
	  [分期除地价外直投单方(元/平方米)] ,
	  [分期土地款单方(元/平方米)],
	  [分期资本化利息单方(元/平方米)] ,
	  [分期开发间接费单方(元/平方米)] 

      )
     SELECT  NEWID() [明源及盈利规划业态单方沉淀表GUID] ,
            ' + ( CASE WHEN @FillHistoryGUID IS NULL THEN 'NULL'
                       ELSE '''' + CAST(@FillHistoryGUID AS VARCHAR(50))
                            + ''''
                  END ) + ' FillHistoryGUID ,
            B.CompanyGUID [BusinessGUID] ,
            B.CompanyName [公司简称] ,

            my.项目guid, 
            my.项目名称, 
            my.项目代码, 
            my.项目投管代码, 
            my.盈利规划上线方式, 
            my.基础数据产品类型, 
            my.基础数据产品名称, 
			my.基础数据商品类型,
            my.基础数据装修标准, 
            my.基础数据主键 ,
			isnull(ylgh.盈利规划主键,ylgh1.盈利规划主键) as 盈利规划系统自动匹对主键,

            A.盈利规划主键, 
            A.[营业成本单方(元/平方米)] ,
            A.[营销费用单方(元/平方米)] ,
            A.[综合管理费单方(元/平方米)], 
            A.[股权溢价单方(元/平方米)],  
            A.[税金及附加单方(元/平方米)], 
            A.[除地价外直投单方(元/平方米)] ,
            A.[土地款单方(元/平方米)], 
            A.[资本化利息单方(元/平方米)], 
            A.[开发间接费单方(元/平方米)], 
			A.[最后导入人] ,
            A.[最后导入时间],

            my.[分期] ,
	        my.[基础数据分期主键] ,
			A.[盈利规划分期主键]  ,
			ylgh.盈利规划分期主键 as [盈利规划系统自动匹配分期主键],
			A.[分期营业成本单方(元/平方米)] ,
			A.[分期营销费用单方(元/平方米)] ,
			A.[分期综合管理费单方(元/平方米)] ,
			A.[分期股权溢价单方(元/平方米)] ,
			A.[分期税金及附加单方(元/平方米)] ,
			A.[分期除地价外直投单方(元/平方米)] ,
			A.[分期土地款单方(元/平方米)],
			A.[分期资本化利息单方(元/平方米)] ,
			A.[分期开发间接费单方(元/平方米)] 
    FROM    #my my
			      left join #ylgh ylgh  on my.基础数据分期主键 = ylgh.盈利规划分期主键_明源
            left join (select 盈利规划主键_明源,盈利规划主键 from #ylgh group by 盈利规划主键_明源,盈利规划主键) ylgh1 on my.基础数据主键=ylgh1.盈利规划主键_明源
            LEFT JOIN dbo.nmap_N_CompanyToTerraceBusiness AS C ON C.DevelopmentCompanyGUID = my.公司guid
            LEFT JOIN [nmap_N_Company] AS B ON B.CompanyGUID = C.CompanyGUID
            LEFT JOIN ( SELECT distinct  [公司简称] ,
                               BusinessGUID ,
                               基础数据分期主键,
                               盈利规划主键,  
                               [营业成本单方(元/平方米)] ,
                               [营销费用单方(元/平方米)] ,
                               [综合管理费单方(元/平方米)], 
                               [股权溢价单方(元/平方米)],  
                               [税金及附加单方(元/平方米)], 
                               [除地价外直投单方(元/平方米)] ,
                               [土地款单方(元/平方米)], 
                               [资本化利息单方(元/平方米)], 
                               [开发间接费单方(元/平方米)],
							   [最后导入人],
							   [最后导入时间],
	                           [盈利规划分期主键]  ,
	                           [分期营业成本单方(元/平方米)] ,
	                           [分期营销费用单方(元/平方米)] ,
	                           [分期综合管理费单方(元/平方米)] ,
	                           [分期股权溢价单方(元/平方米)] ,
	                           [分期税金及附加单方(元/平方米)] ,
	                           [分期除地价外直投单方(元/平方米)] ,
	                           [分期土地款单方(元/平方米)],
	                           [分期资本化利息单方(元/平方米)] ,
	                           [分期开发间接费单方(元/平方米)]  
                        FROM    [nmap_F_明源及盈利规划业态单方沉淀表]
                        WHERE   FillHistoryGUID = '
        + CASE WHEN @FillHistoryGUIDLast IS NULL THEN 'NULL'
               ELSE '''' + CAST(@FillHistoryGUIDLast AS VARCHAR(50)) + ''''
          END + '
                      ) AS A ON  my.基础数据分期主键 = A.基础数据分期主键
        '
           
    EXEC (@strSql); 
	
    PRINT 3;

--删除旧数据  
    DELETE  FROM nmap_F_明源及盈利规划业态单方沉淀表
    WHERE   FillHistoryGUID = @FillHistoryGUID;  
   
--插入新数据
    INSERT  INTO nmap_F_明源及盈利规划业态单方沉淀表
            ( 明源及盈利规划业态单方沉淀表GUID,	
			FillHistoryGUID,	
			BusinessGUID,	
			公司简称,	
			项目guid,	
			项目名称,	
			项目代码,	
			项目投管代码,	
			盈利规划上线方式,	
			基础数据产品类型,	
			基础数据产品名称,	
			基础数据商品类型,
			基础数据装修标准,	
			基础数据主键,	
			盈利规划系统自动匹对主键,	
			盈利规划主键,	
			[营业成本单方(元/平方米)]	,
			[营销费用单方(元/平方米)]	,
			[综合管理费单方(元/平方米)],	
			[股权溢价单方(元/平方米)],	
			[税金及附加单方(元/平方米)],	
			[除地价外直投单方(元/平方米)]	,
			[土地款单方(元/平方米)],	
			[资本化利息单方(元/平方米)],	
			[开发间接费单方(元/平方米)],	
			最后导入人,	
			最后导入时间	,
			RowID ,
            [分期] ,
	        [基础数据分期主键] ,
	        [盈利规划分期主键]  ,
            [盈利规划系统自动匹配分期主键],
	        [分期营业成本单方(元/平方米)] ,
	        [分期营销费用单方(元/平方米)] ,
	        [分期综合管理费单方(元/平方米)] ,
	        [分期股权溢价单方(元/平方米)] ,
	        [分期税金及附加单方(元/平方米)] ,
	        [分期除地价外直投单方(元/平方米)] ,
	        [分期土地款单方(元/平方米)],
	        [分期资本化利息单方(元/平方米)] ,
	        [分期开发间接费单方(元/平方米)] 
            )
            SELECT  明源及盈利规划业态单方沉淀表GUID,	
			FillHistoryGUID,	
			BusinessGUID,	
			公司简称,	
			项目guid,	
			项目名称,	
			项目代码,	
			项目投管代码,	
			盈利规划上线方式,	
			基础数据产品类型,	
			基础数据产品名称,	
			基础数据商品类型,
			基础数据装修标准,	
			基础数据主键,	
			盈利规划系统自动匹对主键,	
			盈利规划主键,	
			[营业成本单方(元/平方米)]	,
			[营销费用单方(元/平方米)]	,
			[综合管理费单方(元/平方米)],	
			[股权溢价单方(元/平方米)],	
			[税金及附加单方(元/平方米)],	
			[除地价外直投单方(元/平方米)]	,
			[土地款单方(元/平方米)],	
			[资本化利息单方(元/平方米)],	
			[开发间接费单方(元/平方米)],	
			最后导入人,	
			最后导入时间	, 
            ROW_NUMBER() OVER ( ORDER BY 公司简称, 项目投管代码 , 盈利规划上线方式 , 基础数据主键,基础数据分期主键 ) AS [RowID]  ,
            [分期] ,
	        [基础数据分期主键] ,
	        [盈利规划分期主键]  ,
            [盈利规划系统自动匹配分期主键],
	        [分期营业成本单方(元/平方米)] ,
	        [分期营销费用单方(元/平方米)] ,
	        [分期综合管理费单方(元/平方米)] ,
	        [分期股权溢价单方(元/平方米)] ,
	        [分期税金及附加单方(元/平方米)] ,
	        [分期除地价外直投单方(元/平方米)] ,
	        [分期土地款单方(元/平方米)],
	        [分期资本化利息单方(元/平方米)] ,
	        [分期开发间接费单方(元/平方米)] 
            FROM  #TempData;
 
    DROP TABLE #my; 
    DROP TABLE #ylgh; 
    DROP TABLE #TempData;
 




USE [dss]
GO
/****** Object:  StoredProcedure [dbo].[usp_nmap_F_价格填报]    Script Date: 05/15/2017 21:02:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[usp_nmap_F_价格填报]
    (
      @CleanDate DATETIME ,
      @DataBaseName VARCHAR(100) ,
      @FillHistoryGUID UNIQUEIDENTIFIER ,
      @IsCurrFillHistory BIT
    )
AS /*

	参数：@CleanDate  清洗日期
		  @DataBaseName 数据库地址
		  @FillHistoryGUID 填报批次
		  @IsCurrFillHistory 是否当前批次
	功能：价格填报
	创建者：lifs
	创建日期：2016-10-27
*/

    PRINT @CleanDate; 
    PRINT @DataBaseName;  
    PRINT @FillHistoryGUID; 
    PRINT @IsCurrFillHistory; 

    DECLARE @strSql VARCHAR(MAX); 
	--当是当前批次时,刷新组织纬度
    IF @IsCurrFillHistory = 1
        BEGIN
            EXEC dbo.usp_nmap_S_FillDataSynch_ReCreateBatch @FillHistoryGUID = @FillHistoryGUID;
        END;

 --SBB
    CREATE TABLE #sbb
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          已售货量万元 MONEY ,
          已售面积 MONEY ,
          待售面积 MONEY,
	    );
    SET @strSql = ' 
    insert into #sbb(SaleBldGUID,已售货量万元,已售面积,待售面积)
    SELECT  sb.SaleBldGUID ,
            SUM(ISNULL(bd.cjtotal, 0)) 已售货量万元 ,
            SUM(CASE WHEN ProductType=''地下室/车库'' AND p.ProductName<> ''地下储藏室'' THEN 1 else ISNULL(bd.ysmjtotal, 0) end) 已售面积 ,
            SUM(CASE WHEN ProductType=''地下室/车库'' AND p.ProductName<> ''地下储藏室'' THEN 1 ELSE ISNULL(bd.mjtotal, ISNULL(sb.SaleArea, 0)) end) 待售面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ( SELECT  b.BldGUID ,
                                --pt.BProductTypeName ProductName ,
                                
                                SUM(ISNULL(t.RmbCjTotal, 0)) cjtotal ,
                                
                                SUM(CASE WHEN r.Status IN ( ''签约'', ''认购'' )
                                         THEN r.BldArea
                                         ELSE 0
                                    END) ysmjtotal ,
                                    SUM(CASE WHEN ( r.Status IN ( ''待售'', ''预约'' )
                                                OR ( r.Status = ''销控'' )
                                              ) THEN r.BldArea
                                         ELSE 0
                                    END) mjtotal
                        FROM    ' + @DataBaseName + 'p_Building b
                        LEFT JOIN ' + @DataBaseName
        + 'p_Room r ON r.BldGUID = b.BldGUID
                       
                       LEFT JOIN ( SELECT  RoomGUID ,RmbCjTotal , JfDate
                                            FROM    ' + @DataBaseName
        + 's_Order o
                                            WHERE   o.Status = ''激活''
                                                    AND o.OrderType = ''认购''
                                            UNION ALL
                                            SELECT  RoomGUID ,
                                                    RmbHtTotal rmbcjtotal ,
                                                    JFDate
                                            FROM    ' + @DataBaseName
        + 's_Contract c
                                            WHERE   c.Status = ''激活''
                                          ) t ON t.RoomGUID = r.RoomGUID
                        GROUP BY b.BldGUID 
                      ) bd ON sb.ImportSaleBldGUID = bd.BldGUID
                             
    GROUP BY SaleBldGUID;';
    PRINT 0;
    EXEC(@strSql);
 
 --SBB1 三个月
	
    CREATE TABLE #sbb1
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM待售房间标准总价 MONEY ,
          CRM近三月成交总价 MONEY ,
          CRM近三月成交对应的房间总价 MONEY,
	    );
    SET @strSql = ' 
    insert into #sbb1(SaleBldGUID,CRM待售房间标准总价,CRM近三月成交总价,CRM近三月成交对应的房间总价)
    SELECT sb.SaleBldGUID ,
            SUM(CASE WHEN r.Status NOT IN ( ''认购'', ''签约'' )
                     THEN ISNULL(r.Total, 0)
                     ELSE 0
                END) CRM待售房间标准总价 ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM近三月成交总价 ,
            SUM(CASE WHEN o.OrderGUID IS NOT NULL
                          OR sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.Total, 0)
                     ELSE 0
                END) CRM近三月成交对应的房间总价
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_BuildProductType bp ON r.BProductTypeCode = bp.BProductTypeCode
            LEFT JOIN ' + @DataBaseName
        + 's_Order o ON r.RoomGUID = o.RoomGUID
                                                              AND o.Status = ''激活''
                                                              AND OrderType = ''认购''
                                                              AND DATEDIFF(DD,
                                                              o.QSDate,
                                                              GETDATE()) < 90
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
                                                              AND DATEDIFF(DD,
                                                              sc.QSDate,
                                                              GETDATE()) < 90
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID; ';
    PRINT 1;
    EXEC(@strSql);
                    
--SBB2  一个月   
    CREATE TABLE #sbb2
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM近一月成交总价 MONEY ,
          CRM近一月成交对应的房间面积 MONEY,
	    ); 
    SET @strSql = '
     insert into #sbb2(SaleBldGUID,CRM近一月成交总价,CRM近一月成交对应的房间面积)
     SELECT  sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM近一月成交总价 ,
            SUM(CASE WHEN p.ProductType = ''地下室/车库'' AND p.ProductName <> ''地下储藏室'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM近一月成交对应的房间面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
			LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
                                                              AND DATEDIFF(MM,
                                                              sc.QSDate,
                                                              GETDATE()) = 0
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID; ';
    PRINT 2;
    EXEC(@strSql);  

 --SBB3  一个年
    CREATE TABLE #sbb3
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM近一年成交总价 MONEY ,
          CRM近一年成交对应的房间面积 MONEY,
	    );             
    SET @strSql = '
    insert into #sbb3(SaleBldGUID,CRM近一年成交总价,CRM近一年成交对应的房间面积)
    SELECT sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM近一年成交总价 ,
            SUM(CASE WHEN p.ProductType = ''地下室/车库'' AND p.ProductName <> ''地下储藏室'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM近一年成交对应的房间面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
		LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
                                                              AND DATEDIFF(yyyy,
                                                              sc.QSDate,
                                                              GETDATE()) = 0
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID;  '; 
    PRINT 3;
    EXEC(@strSql);              
--SBB4 累计   
    CREATE TABLE #sbb4
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM累计成交总价 MONEY ,
          CRM累计成交对应的房间面积 MONEY,
	    );            
    SET @strSql = '  
        insert into #sbb4(SaleBldGUID,CRM累计成交总价,CRM累计成交对应的房间面积)
        SELECT sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM累计成交总价 ,
            SUM(CASE WHEN p.ProductType = ''地下室/车库'' AND p.ProductName <> ''地下储藏室'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM累计成交对应的房间面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
			LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID;   ';
    
    PRINT 4;
    EXEC(@strSql);  
           
    DECLARE @Drr AS VARCHAR(500);  
    DECLARE @DrDate AS DATETIME;  
    SELECT TOP 1
            @Drr = [最后导入人] ,
            @DrDate = [最后导入时间]
    FROM    [nmap_F_价格填报]
    WHERE   FillHistoryGUID = @FillHistoryGUID; 
  
    CREATE TABLE #TempData
        (
          价格填报GUID UNIQUEIDENTIFIER ,
          FillHistoryGUID UNIQUEIDENTIFIER ,
          BusinessGUID UNIQUEIDENTIFIER ,
          项目代码 VARCHAR(400) ,
          项目名称 VARCHAR(400) ,
          产品类型 VARCHAR(400) ,
          产品名称 VARCHAR(400) ,
          单价 MONEY ,
          累计签约均价 MONEY ,
          本年签约均价 MONEY ,
          本月签约均价 MONEY ,
          立项价 MONEY ,
          定位价 MONEY ,
          动态销售单价 MONEY ,
          动态销售面积 MONEY ,
          目标成本单方 MONEY ,
          动态成本单方 MONEY ,
          装修标准 VARCHAR(400) ,
          最后导入人 VARCHAR(400) ,
          最后导入时间 DATETIME ,
          公司简称 VARCHAR(400) ,
          RowID INT ,
          ProductGuid UNIQUEIDENTIFIER ,
          BusinessType VARCHAR(200) ,
          Remark VARCHAR(500)
        );
    PRINT 5;
  
--截至日期最后,且有数据 的版本号
    DECLARE @FillHistoryGUIDLast UNIQUEIDENTIFIER;
  
    SELECT TOP 1
            @FillHistoryGUIDLast = a.FillHistoryGUID
    FROM    nmap_F_FillHistory a
    WHERE   FillDataGUID = ( SELECT FillDataGUID
                             FROM   nmap_F_FillData
                             WHERE  FillName = '价格填报'
                           )
            AND a.ApproveStatus = '已审核'
    ORDER BY EndDate DESC;
  
  
    SET @strSql = ' 
     insert into  #TempData (价格填报GUID ,
                    FillHistoryGUID ,
                    BusinessGUID ,
                    公司简称,
                    项目代码 ,
                    项目名称 ,
                    产品类型 ,
                    产品名称 ,
                    单价 ,
                    累计签约均价 ,
                    本年签约均价 ,
                    本月签约均价 ,
                    立项价 ,
                    定位价 ,
                    动态销售单价 ,
                    动态销售面积 ,
                    目标成本单方 ,
                    动态成本单方 ,
                    装修标准 ,
                    最后导入人 ,
                    最后导入时间,
                    ProductGuid,
                    BusinessType,
                    Remark
                     )
     SELECT  NEWID() [价格填报GUID] ,
            ' + ( CASE WHEN @FillHistoryGUID IS NULL THEN 'NULL'
                       ELSE '''' + CAST(@FillHistoryGUID AS VARCHAR(50))
                            + ''''
                  END ) + ' FillHistoryGUID ,
            B.CompanyGUID [BusinessGUID] ,
            B.CompanyName [公司简称] ,
            ISNULL(p.ProjCode, p1.ProjCode) 项目代码 ,
            ISNULL(p.SpreadName, p1.SpreadName) + ''-'' +
            CASE WHEN p.ProjName IS NULL THEN ''''
                   ELSE p1.ProjName
              END 项目名称 ,
            pd.ProductType 产品类型 ,
            pd.ProductName 产品名称 ,
            ISNULL(A.单价, 0.00) [单价] ,
            CASE WHEN SUM(sb.CRM累计成交对应的房间面积) = 0 THEN 0
                 ELSE SUM(sb.CRM累计成交总价) / SUM(sb.CRM累计成交对应的房间面积)
            END AS 累计签约均价 ,
            CASE WHEN SUM(sb.CRM近一年成交对应的房间面积) = 0 THEN 0
                 ELSE SUM(sb.CRM近一年成交总价) / SUM(sb.CRM近一年成交对应的房间面积)
            END AS 本年签约均价 ,
            CASE WHEN SUM(sb.CRM近一月成交对应的房间面积) = 0 THEN 0
                 ELSE SUM(sb.CRM近一月成交总价) / SUM(sb.CRM近一月成交对应的房间面积)
            END AS 本月签约均价 ,
            ISNULL(A.立项价, 0.00) [立项价] ,
            ISNULL(A.定位价, 0.00) [定位价] ,
            CASE WHEN SUM(sb.动态销售面积) = 0 THEN 0
                 ELSE SUM(sb.[动态销售总价 ]) / SUM(sb.动态销售面积)
            END AS 动态销售单价 ,
            SUM(sb.动态销售面积) AS 动态销售面积 ,
            ISNULL(A.目标成本单方, 0.00) [目标成本单方] ,
            ISNULL(A.动态成本单方, 0.00) [动态成本单方] ,
            ISNULL(A.装修标准, '''') [装修标准] ,
            ' + ( CASE WHEN @Drr IS NULL THEN 'NULL'
                       ELSE '''' + @Drr + ''''
                  END ) + '  [最后导入人] ,
            ' + ( CASE WHEN @DrDate IS NULL THEN 'NULL'
                       ELSE '''' + CONVERT(VARCHAR, @DrDate, 120) + ''''
                  END )
        + ' [最后导入时间],
            pd.ProductGuid,
            pd.BusinessType,
            pd.Remark
    FROM    ( SELECT    sb.SaleBldGUID ,
                        sb.ProductGUID ,
                        sb.GCBldGUID ,
                        CASE WHEN ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积, 0) ) = 0
                             THEN ISNULL(sb.SaleArea, 0)
                             ELSE ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积, 0) )
                        END AS ''动态销售面积'' ,
                        CASE WHEN ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                + ISNULL(sbb.待售面积, 0) ) = 0
                                         THEN ISNULL(sb.SaleArea, 0)
                                         ELSE ( ISNULL(sbb.已售面积, 0)
                                                + ISNULL(sbb.待售面积, 0) )
                                    END ) = 0 THEN 0
                             ELSE ( CASE WHEN ( ISNULL(sbb.已售货量万元, 0)
                                                + ISNULL(CASE WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                         END, 0) ) = 0
                                         THEN sb.PlanSaleTotal
                                         ELSE ( ISNULL(sbb.已售货量万元, 0)
                                                + ISNULL(CASE WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                         END, 0) )
                                    END )
                                  / ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                  + ISNULL(sbb.待售面积, 0) ) = 0
                                           THEN sb.SaleArea
                                           ELSE ( ISNULL(sbb.已售面积, 0)
                                                  + ISNULL(sbb.待售面积, 0) )
                                      END )
                        END AS ''动态销售单价'' ,
                        ( ( CASE WHEN ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积,
                                                              0) ) = 0
                                 THEN ISNULL(sb.SaleArea, 0)
                                 ELSE ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积,
                                                              0) )
                            END )
                          * ( CASE WHEN ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                      + ISNULL(sbb.待售面积, 0) ) = 0
                                               THEN ISNULL(sb.SaleArea, 0)
                                               ELSE ( ISNULL(sbb.已售面积, 0)
                                                      + ISNULL(sbb.待售面积, 0) )
                                          END ) = 0 THEN 0
                                   ELSE ( CASE WHEN ( ISNULL(sbb.已售货量万元, 0)
                                                      + ISNULL(CASE
                                                              WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                              END, 0) ) = 0
                                               THEN sb.PlanSaleTotal
                                               ELSE ( ISNULL(sbb.已售货量万元, 0)
                                                      + ISNULL(CASE
                                                              WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                              END, 0) )
                                          END )
                                        / ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                        + ISNULL(sbb.待售面积, 0) ) = 0
                                                 THEN ISNULL(sb.SaleArea, 0)
                                                 ELSE ( ISNULL(sbb.已售面积, 0)
                                                        + ISNULL(sbb.待售面积, 0) )
                                            END )
                              END ) ) AS ''动态销售总价 '' ,
                        ISNULL(sbb2.CRM近一月成交总价, 0) AS ''CRM近一月成交总价'' ,
                        ISNULL(sbb2.CRM近一月成交对应的房间面积, 0) AS ''CRM近一月成交对应的房间面积'' ,
                        ISNULL(sbb3.CRM近一年成交总价, 0) AS ''CRM近一年成交总价'' ,
                        ISNULL(sbb3.CRM近一年成交对应的房间面积, 0) AS ''CRM近一年成交对应的房间面积'' ,
                        ISNULL(sbb4.CRM累计成交总价, 0) AS ''CRM累计成交总价'' ,
                        ISNULL(sbb4.CRM累计成交对应的房间面积, 0) AS ''CRM累计成交对应的房间面积''
              FROM      ' + @DataBaseName
        + 'mdm_SaleBuild sb
                        LEFT JOIN #sbb sbb ON sbb.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb1 sbb1 ON sbb1.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb2 sbb2 ON sbb2.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb3 sbb3 ON sbb3.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb4 sbb4 ON sbb4.SaleBldGUID = sb.SaleBldGUID
            ) sb
            LEFT JOIN ' + @DataBaseName
        + 'mdm_GCBuild gb ON sb.GCBldGUID = gb.GCBldGUID
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Project p1 ON gb.ProjGUID = p1.ProjGUID
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Project p ON p1.ParentProjGUID = p.ProjGUID
                                                              AND p.Level = 2
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Product pd ON sb.ProductGUID = pd.ProductGUID
            LEFT JOIN dbo.nmap_N_CompanyToTerraceBusiness AS C ON C.DevelopmentCompanyGUID = p1.DevelopmentCompanyGUID
            LEFT JOIN [nmap_N_Company] AS B ON B.CompanyGUID = C.CompanyGUID
            LEFT JOIN ( SELECT  [公司简称] ,
                                BusinessGUID ,
                                产品类型 ,
                                产品名称 ,
                                项目代码 ,
                                项目名称 ,
                                ISNULL([单价], 0.00) [单价] ,
                                ISNULL([立项价], 0.00) [立项价] ,
                                ISNULL([定位价], 0.00) [定位价] ,
                                ISNULL([目标成本单方], 0.00) [目标成本单方] ,
                                ISNULL([动态成本单方], 0.00) [动态成本单方] ,
                                ISNULL([装修标准], '''') [装修标准]
                        FROM    [nmap_F_价格填报]
                        WHERE   FillHistoryGUID = '
        + CASE WHEN @FillHistoryGUIDLast IS NULL THEN 'NULL'
               ELSE '''' + CAST(@FillHistoryGUIDLast AS VARCHAR(50)) + ''''
          END + '
                      ) AS A ON A.BusinessGUID = B.CompanyGUID
                                AND A.[公司简称] = B.CompanyName
                                AND A.项目代码 = ISNULL(p.ProjCode, p1.ProjCode)
                                AND A.项目名称 = ISNULL(p.SpreadName,
                                                    p1.SpreadName)  + ''-'' +
                                CASE WHEN p.ProjName IS NULL THEN ''''
                                       ELSE p1.ProjName
                                  END
                                AND A.产品类型 = pd.ProductType
                                AND A.产品名称 = pd.ProductName
		   GROUP BY
            B.CompanyGUID  ,
            B.CompanyName  ,
            ISNULL(p.ProjCode, p1.ProjCode)  ,
            ISNULL(p.SpreadName, p1.SpreadName) + ''-'' +
            CASE WHEN p.ProjName IS NULL THEN ''''
                   ELSE p1.ProjName
            END ,
            pd.ProductType  ,
            pd.ProductName ,
            ISNULL(A.单价, 0.00) , 
            ISNULL(A.立项价, 0.00)  ,
            ISNULL(A.定位价, 0.00) ,
            ISNULL(A.目标成本单方, 0.00) ,
            ISNULL(A.动态成本单方, 0.00)  ,
            ISNULL(A.装修标准, ''''),  
            pd.ProductGuid,
            pd.BusinessType,
            pd.Remark '
           
    EXEC (@strSql);
		

--删除旧数据  
    DELETE  FROM nmap_F_价格填报
    WHERE   FillHistoryGUID = @FillHistoryGUID;  
 
--插入新数据
    INSERT  INTO nmap_F_价格填报
            ( 价格填报GUID ,
              FillHistoryGUID ,
              BusinessGUID ,
              项目代码 ,
              项目名称 ,
              产品类型 ,
              产品名称 ,
              单价 ,
              累计签约均价 ,
              本年签约均价 ,
              本月签约均价 ,
              立项价 ,
              定位价 ,
              动态销售单价 ,
              动态销售面积 ,
              目标成本单方 ,
              动态成本单方 ,
              装修标准 ,
              最后导入人 ,
              最后导入时间 ,
              公司简称 ,
              RowID ,
              产品GUID,
              商品类型 ,
              备注
              
            )
            SELECT  价格填报GUID ,
                    FillHistoryGUID ,
                    BusinessGUID ,
                    项目代码 ,
                    项目名称 ,
                    产品类型 ,
                    产品名称 ,
                    单价 ,
                    累计签约均价 ,
                    本年签约均价 ,
                    本月签约均价 ,
                    立项价 ,
                    定位价 ,
                    动态销售单价 ,
                    动态销售面积 ,
                    目标成本单方 ,
                    动态成本单方 ,
                    装修标准 ,
                    最后导入人 ,
                    最后导入时间 ,
                    公司简称 ,
                    ROW_NUMBER() OVER ( ORDER BY 公司简称, BusinessGUID , 项目代码 , 项目名称 , 产品类型 , 产品名称 ) AS [RowID] ,
                    ProductGuid ,
                    BusinessType ,
                    Remark
            FROM    #TempData;
 
    DROP TABLE #sbb; 
    DROP TABLE #sbb1; 
    DROP TABLE #sbb2;
    DROP TABLE #sbb3; 
    DROP TABLE #sbb4;
    DROP TABLE #TempData;
 