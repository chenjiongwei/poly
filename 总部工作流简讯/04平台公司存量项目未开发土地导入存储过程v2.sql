USE [dss]
GO
/****** Object:  StoredProcedure [dbo].[usp_nmap_F_平台公司存量项目未开发土地]    Script Date: 2025/6/4 10:18:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 平台公司存量项目未开发土地

-- 创建存储过程
alter  PROC [dbo].[usp_nmap_F_平台公司存量项目未开发土地V2]
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
	创建日期：2025-07-07

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
          '平台公司存量项目未开发土地V2' ,
          'nmap_F_平台公司存量项目未开发土地V2' ,
          'usp_nmap_F_平台公司存量项目未开发土地V2' ,
          '9999' ,   --数据库标识
          '999907'   --数据库标识加上排序
        );
go
EXEC usp_nmap_F_平台公司存量项目未开发土地V2 '2025-07-07','erp25.dbo.','983C3FD4-9412-4388-B3F4-E91B3752255A',1

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
                             WHERE  FILLNAME = '平台公司存量项目未开发土地V2'
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
	FROM nmap_F_平台公司存量项目未开发土地V2 
	WHERE ISNULL(上月工作进展,'') <> '' 
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
                             WHERE  FILLNAME = '平台公司存量项目未开发土地V2'
                           )
			AND FILLHISTORYGUID IN (SELECT DISTINCT FILLHISTORYGUID FROM nmap_F_平台公司存量项目未开发土地V2
			WHERE ISNULL(项目名称,'') <> '')
    ORDER BY ENDDATE DESC;	


	-- 刷新组织架构
	SELECT  
	  newid() as  [平台公司存量项目未开发土地GUID]
      ,@FILLHISTORYGUID as [FillHistoryGUID]
      ,c.CompanyGUID  as [BusinessGUID]
      ,isnull(d.[最后导入人],null) as [最后导入人]
      ,isnull(d.[最后导入时间],getdate()) as [最后导入时间]
      ,c.CompanyName as [公司简称]
	   ,null as [RowID]
      ,isnull(d.[公司],a.[公司]) as [公司]
      ,isnull(d.[我司股比],a.[我司股比]) as [我司股比]
      ,isnull(d.[是否并表],a.[是否并表]) as [是否并表]

      ,isnull(d.[项目代码],a.[项目代码]) as [项目代码]
      ,isnull(d.[处置方向],a.[处置方向]) as [处置方向]
      ,isnull(d.[未开工计容面积（万平）],a.[未开工计容面积（万平）]) as [未开工计容面积（万平）]
      ,isnull(d.[项目名称],a.[项目名称]) as [项目名称]
      ,isnull(d.[项目直接责任人],a.[项目直接责任人]) as [项目直接责任人]
      ,isnull(d.[未开工原因说明],a.[未开工原因说明]) as [未开工原因说明]

      ,isnull(d.[年初全口径占压资金（万元）],a.[年初全口径占压资金（万元）]) as [年初全口径占压资金（万元）]
      ,isnull(d.[年初权益占压资金（万元）],a.[年初权益占压资金（万元）]) as [年初权益占压资金（万元）]
      ,isnull(d.[年初并表口径占压资金（万元）],a.[年初并表口径占压资金（万元）]) as [年初并表口径占压资金（万元）]
      ,isnull(d.[2025年计划完成的重要节点或目标-争取],a.[2025年计划完成的重要节点或目标-争取]) as [2025年计划完成的重要节点或目标-争取]
      ,isnull(d.[对应盘活资金（全口径，万元）],a.[对应盘活资金（全口径，万元）]) as [对应盘活资金（全口径，万元）]
      ,isnull(d.[对应盘活资金（权益口径，万元）],a.[对应盘活资金（权益口径，万元）]) as [对应盘活资金（权益口径，万元）]
      ,isnull(d.[对应盘活资金（并表口径，万元）],a.[对应盘活资金（并表口径，万元）]) as [对应盘活资金（并表口径，万元）]
      ,isnull(d.[一季度节点1],a.[一季度节点1]) as [一季度节点1]
      ,isnull(d.[一季度盘活资金（并表口径）],a.[一季度盘活资金（并表口径）]) as [一季度盘活资金（并表口径）]
      ,isnull(d.[二季度节点2],a.[二季度节点2]) as [二季度节点2]
      ,isnull(d.[二季度盘活资金（并表口径）],a.[二季度盘活资金（并表口径）]) as [二季度盘活资金（并表口径）]
      ,isnull(d.[三季度节点3],a.[三季度节点3]) as [三季度节点3]
      ,isnull(d.[三季度盘活资金（并表口径）],a.[三季度盘活资金（并表口径）]) as [三季度盘活资金（并表口径）]
      ,isnull(d.[四季度节点4],a.[四季度节点4]) as [四季度节点4]
      ,isnull(d.[四季度盘活资金（并表口径）],a.[四季度盘活资金（并表口径）]) as [四季度盘活资金（并表口径）]
      ,isnull(d.[7月新排计划],a.[7月新排计划]) as [7月新排计划]
      ,isnull(d.[7月盘活金额],a.[7月盘活金额]) as [7月盘活金额]
      ,isnull(d.[8月新排计划],a.[8月新排计划]) as [8月新排计划]
      ,isnull(d.[8月盘活金额],a.[8月盘活金额]) as [8月盘活金额]
      ,isnull(d.[9月新排计划],a.[9月新排计划]) as [9月新排计划]
      ,isnull(d.[9月盘活金额],a.[9月盘活金额]) as [9月盘活金额]
      ,isnull(d.[10月新排计划],a.[10月新排计划]) as [10月新排计划]
      ,isnull(d.[10月盘活金额],a.[10月盘活金额]) as [10月盘活金额]
      ,isnull(d.[11月新排计划],a.[11月新排计划]) as [11月新排计划]
      ,isnull(d.[11月盘活金额],a.[11月盘活金额]) as [11月盘活金额]
      ,isnull(d.[12月新排计划],a.[12月新排计划]) as [12月新排计划]
      ,isnull(d.[12月盘活金额],a.[12月盘活金额]) as [12月盘活金额]
      ,isnull(d.[2026年盘活计划],a.[2026年盘活计划]) as [2026年盘活计划]
      ,isnull(d.[2026年盘活金额],a.[2026年盘活金额]) as [2026年盘活金额]
      ,isnull(d.[2026年盘活面积],a.[2026年盘活面积]) as [2026年盘活面积]
      ,isnull(d.[2027年盘活计划],a.[2027年盘活计划]) as [2027年盘活计划]
      ,isnull(d.[2027年盘活金额],a.[2027年盘活金额]) as [2027年盘活金额]
      ,isnull(d.[2027年盘活面积],a.[2027年盘活面积]) as [2027年盘活面积]

      ,'' as [上月工作进展]
      ,'' as [下月工作计划]
      ,'' as [预计本季度工作计划是否按节点达成]
      ,'' as [未按节点达成事项]   

      ,'' as [本季度已盘活金额（并表口径、单位万元）] 
      ,'' as [全年累计盘活任务（并表口径、单位万元）] 
      ,'' as [全年累计盘活金额（并表口径、单位万元）] 
      ,'' as [盘活资金比例]
      ,'' as [剩余全口径占压金额（单位万元）]
      ,'' as [剩余权益口径占压金额（单位万元）] 
      ,'' as [剩余并表口径占压金额（单位万元）] 

      ,'' as [全年累计签约金额（全口径、单位万元）]
      ,'' as [存货]
      ,'' as [其他应收款]
      ,'' as [预付账款]
      ,'' as [长期股权投资]
      ,'' as [差额]
      ,'' as [有差额的填写原因]    
	INTO #TempData
	from  存量项目未开发土地V4 a
	inner join erp25.dbo.p_DevelopmentCompany b on  a.公司  = b.DevelopmentCompanyName
	inner join nmap_N_CompanyToTerraceBusiness c2b on b.DevelopmentCompanyGUID = c2b.DevelopmentCompanyGUID
	inner join nmap_N_Company c on c2b.CompanyGUID = c.CompanyGUID
	-- 查询上一版的数据进行继承
	left join (
       select  distinct * from  nmap_F_平台公司存量项目未开发土地V2
		   where  FILLHISTORYGUID = @FILLHISTORYGUIDLAST and isnull(项目名称,'') <> ''
	) d on a.[项目名称] = d.[项目名称] and  a.项目代码 =  d.项目代码


-- --删除旧数据   
    DELETE  FROM nmap_F_平台公司存量项目未开发土地V2
    WHERE   FillHistoryGUID = @FillHistoryGUID;  

	 -- 将数据插入到当前版本
	 INSERT INTO nmap_F_平台公司存量项目未开发土地V2
	 SELECT * FROM #TempData;

	 -- 删除临时表
	 DROP TABLE #TempData;



