-- 平台公司存量项目未开发土地


-- 创建存储过程
create  PROC [dbo].[usp_nmap_F_平台公司存量项目未开发土地]
    (
      @CLEANDATE DATETIME , -- 清洗日期
      @DATABASENAME VARCHAR(100) , -- 数据库地址
      @FILLHISTORYGUID UNIQUEIDENTIFIER , -- 填报批次
      @ISCURRFILLHISTORY BIT -- 是否当前批次
    )
AS


-- 存储过程的功能和创建者
/*
	参数：@CLEANDATE  清洗日期
		  @DATABASENAME 数据库地址
		  @FILLHISTORYGUID 填报批次
		  @ISCURRFILLHISTORY 是否当前批次
	功能：待转化资源导入
	创建者：CHENJW
	创建日期：2025-03-27

--填报清洗规则表
INSERT  INTO dbo.nmap_S_FillDataSynchRule
        ( FillDataSynchRuleGUID ,
          FillName ,
          SynchTableName ,
          SynchStorName ,
          SystemType ,
          SynchOrder
        )
VALUES  ( NEWID() ,
          '平台公司存量项目未开发土地' ,
          'nmap_F_平台公司存量项目未开发土地' ,
          'usp_nmap_F_平台公司存量项目未开发土地' ,
          '9999' ,   --数据库标识
          '999905'   --数据库标识加上排序
        );
go



EXEC usp_nmap_F_平台公司存量项目未开发土地 '2025-03-27','erp25.dbo.','E122693F-3FFC-4F14-841B-2D9A0C5E39A8',1

*/

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
                             WHERE  FILLNAME = '平台公司存量项目未开发土地'
                           )
    ORDER BY ENDDATE DESC;

	-- 如果不是最新版本，不更新
	IF @FILLHISTORYGUID <> @FILLHISTORYGUIDNEW
	BEGIN
		PRINT '该版本不是最新版本，故不更新'
		RETURN;
	END

	-- 当是当前批次时,刷新组织纬度,即根据填报类型(自定义/公司级/项目级)生成对应的组织架构信息
	-- 若当前版本有数据的话，不刷新组织架构
	SELECT @COUNTNUM=COUNT(1) FROM nmap_F_平台公司存量项目未开发土地 
	WHERE ISNULL(项目名称,'') <> '' AND FILLHISTORYGUID = @FILLHISTORYGUID;

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
                             WHERE  FILLNAME = '平台公司存量项目未开发土地'
                           )
			AND FILLHISTORYGUID IN (SELECT DISTINCT FILLHISTORYGUID FROM nmap_F_平台公司存量项目未开发土地
			WHERE ISNULL(项目名称,'') <> '')
    ORDER BY ENDDATE DESC;	


	-- 刷新组织架构
	SELECT  
	  newid() as  [平台公司存量项目未开发土地GUID]
      ,@FILLHISTORYGUID as [FillHistoryGUID]
      ,c.CompanyGUID  as [BusinessGUID]
      ,c.CompanyName as [公司简称]
      ,isnull(d.[区域],a.[区域]) as [区域]
      ,isnull(d.[我司股比],a.[我司股比]) as [我司股比]
      ,isnull(d.[是否并表],a.[是否并表]) as [是否并表]
      ,isnull(d.[最后导入人],null) as [最后导入人]
      ,isnull(d.[最后导入时间],getdate()) as [最后导入时间]
      ,null as [RowID]
      ,isnull(d.[项目代码],a.[项目代码]) as [项目代码]
      ,isnull(d.[处置方向],a.[处置方向]) as [处置方向]
      ,isnull(d.[未开工计容面积（万平）],a.[未开工计容面积（万平）]) as [未开工计容面积（万平）]
      ,isnull(d.[项目名称],a.[项目名称]) as [项目名称]
      ,isnull(d.[未开工原因说明],a.[未开工原因说明]) as [未开工原因说明]
      ,isnull(d.[全口径占压资金（万元）],a.[全口径占压资金（万元）]) as [全口径占压资金（万元）]
      ,isnull(d.[权益占压资金（万元）],a.[权益占压资金_（万元）]) as [权益占压资金（万元）]
      ,isnull(d.[并表口径占压资金（万元）],a.[并表口径占压资金_（万元）]) as [并表口径占压资金（万元）]
      ,isnull(d.[建议是否纳入年度任务书],a.[建议是否_纳入年度任务书]) as [建议是否纳入年度任务书]
      ,isnull(d.[2025年计划完成的重要节点或目标-底线],a.[2025年计划完成的重要节点或目标-底线]) as [2025年计划完成的重要节点或目标-底线]
      ,isnull(d.[底线对应盘活资金（全口径，万元）],a.[底线对应盘活资金（全口径，万元）]) as [底线对应盘活资金（全口径，万元）]
      ,isnull(d.[底线对应盘活资金（权益口径，万元）],a.[底线对应盘活资金（权益口径，万元）]) as [底线对应盘活资金（权益口径，万元）]
      ,isnull(d.[2025年计划完成的重要节点或目标-争取],a.[2025年计划完成的重要节点或目标-争取]) as [2025年计划完成的重要节点或目标-争取]
      ,isnull(d.[争取对应盘活资金（全口径，万元）],a.[争取对应盘活资金（全口径，万元）]) as [争取对应盘活资金（全口径，万元）]
      ,isnull(d.[争取对应盘活资金（权益口径，万元）],a.[争取对应盘活资金（权益口径，万元）]) as [争取对应盘活资金（权益口径，万元）]
      ,isnull(d.[争取对应盘活资金（并表口径，万元）],a.[争取对应盘活资金（并表口径，万元）]) as [争取对应盘活资金（并表口径，万元）]
      ,isnull(d.[一季度节点1],a.[一季度节点1]) as [一季度节点1]
      ,isnull(d.[一季度盘活资金（并表口径）],a.[一季度盘活资金]) as [一季度盘活资金（并表口径）]
      ,isnull(d.[二季度节点2],a.[二季度节点2]) as [二季度节点2]
      ,isnull(d.[二季度盘活资金（并表口径）],a.[二季度盘活资金]) as [二季度盘活资金（并表口径）]
      ,isnull(d.[三季度节点3],a.[三季度节点3]) as [三季度节点3]
      ,isnull(d.[三季度盘活资金（并表口径）],a.[三季度盘活资金]) as [三季度盘活资金（并表口径）]
      ,isnull(d.[四季度节点4],a.[四季度节点4]) as [四季度节点4]
      ,isnull(d.[四季度盘活资金（并表口径）],a.[四季度盘活资金]) as [四季度盘活资金（并表口径）]
      ,isnull(d.[是否可以在25年签约],a.[是否可以在25年签约]) as [是否可以在25年签约]
      ,isnull(d.[25年预计供货时间],a.[25年预计供货时间]) as [25年预计供货时间]
      ,isnull(d.[25年预计签约（亿元）],a.[25年预计签约_（亿元）]) as [25年预计签约（亿元）]
      ,isnull(d.[是否已在2025年1月2日版本中铺排签约],a.[是否已在2025年1月2日版本中铺排签约]) as [是否已在2025年1月2日版本中铺排签约]
      ,isnull(d.[26年预计盘活资金（全口径，万元）],a.[26年预计盘活资金（全口径，万元）]) as [26年预计盘活资金（全口径，万元）]
      ,isnull(d.[27年预计盘活资金（全口径，万元）],a.[27年预计盘活资金（全口径，万元）]) as [27年预计盘活资金（全口径，万元）]
      ,isnull(d.[28年及以后盘活资金（全口径，万元）],a.[28年及以后盘活资金（全口径，万元）]) as [28年及以后盘活资金（全口径，万元）]
      ,isnull(d.[推进及盘活思路],a.[推进及盘活思路]) as [推进及盘活思路]
      ,isnull(d.[备注],a.[备注]) as [备注]
      ,isnull(d.[上月工作进展],a.[上月工作进展]) as [上月工作进展]
      ,isnull(d.[本月工作进展],a.[本月工作进展]) as [本月工作进展]
      ,isnull(d.[预计本季度工作计划是否按节点达成],a.[预计本季度工作计划是否按节点达成]) as [预计本季度工作计划是否按节点达成]
      ,isnull(d.[未按节点达成事项],a.[未按节点达成事项]) as [未按节点达成事项]
      ,isnull(d.[盘活资金比例（低于应盘活比例百分之70，推送预警）],a.[盘活资金比例_（低于应盘活比例70%，推送预警）]) as [盘活资金比例（低于应盘活比例百分之70，推送预警）]
	INTO #TempData
	from  存量项目未开发土地 a
	left join erp25.dbo.p_DevelopmentCompany b on  case when a.公司 = '东北公司' then '辽宁公司' else a.公司 end = b.DevelopmentCompanyName
	left join nmap_N_CompanyToTerraceBusiness c2b on b.DevelopmentCompanyGUID = c2b.DevelopmentCompanyGUID
	left join nmap_N_Company c on c2b.CompanyGUID = c.CompanyGUID
	-- 查询上一版的数据进行继承
	left join (
           select  distinct * from  nmap_F_平台公司存量项目未开发土地
		   where  FILLHISTORYGUID = @FILLHISTORYGUIDLAST and isnull(项目名称,'') <> ''
	) d on a.[项目名称] = d.[项目名称]


-- --删除旧数据  
    DELETE  FROM nmap_F_平台公司存量项目未开发土地
    WHERE   FillHistoryGUID = @FillHistoryGUID;  

	 -- 将数据插入到当前版本
	 INSERT INTO nmap_F_平台公司存量项目未开发土地
	 SELECT * FROM #TempData;

	 -- 删除临时表
	 DROP TABLE #TempData;