
-- 创建存储过程
alter   PROC [dbo].[usp_nmap_F_平台公司待返还资金]
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
          '平台公司待返还资金' ,
          'nmap_F_平台公司待返还资金' ,
          'usp_nmap_F_平台公司待返还资金' ,
          '9999' ,   --数据库标识
          '999904'   --数据库标识加上排序
        );
go

EXEC usp_nmap_F_平台公司待返还资金 '2025-03-27','erp25.dbo.','E122693F-3FFC-4F14-841B-2D9A0C5E39A8',1



CREATE TABLE [dbo].[nmap_F_平台公司待返还资金](
	[平台公司待返还资金GUID] [uniqueidentifier] NOT NULL,
	[FillHistoryGUID] [uniqueidentifier] NULL,
	[BusinessGUID] [uniqueidentifier] NULL,
	[公司简称] [varchar](400) NULL,
	[区域] [varchar](400) NULL,
	[项目代码] [varchar](400) NULL,
	[我司股比] [varchar](400) NULL,
	[是否并表] [varchar](400) NULL,
	[挂图问题类型] [varchar](400) NULL,
	[项目名称] [varchar](400) NULL,
	[最后导入人] [varchar](400) NULL,
	[最后导入时间] [datetime] NULL,
	[RowID] [int] NULL,
	[合同或立项约定的返还节点、金额] [varchar](400) NULL,
	[全口径应回收资金总额（万元）] [varchar](400) NULL,
	[权益应回收资金总额（万元）] [varchar](400) NULL,
	[并表口径应回收资金总额（万元）] [varchar](400) NULL,
	[全口径已收回资金总额（万元）] [varchar](400) NULL,
	[权益已回收资金总额（万元）] [varchar](400) NULL,
	[并表口径已回收资金总额（万元）] [varchar](400) NULL,
	[全口径未回收资金总额（万元）] [varchar](400) NULL,
	[其中：逾期未收回资金（全口径，万元）] [varchar](400) NULL,
	[左列勾稽检查1] [varchar](400) NULL,
	[权益未回收资金总额（万元）] [varchar](400) NULL,
	[其中：逾期未收回资金（权益，万元）] [varchar](400) NULL,
	[左列勾稽检查2] [varchar](400) NULL,
	[并表口径未回收资金总额（万元）] [varchar](400) NULL,
	[其中：逾期未收回资金（并表，万元）] [varchar](400) NULL,
	[年新增到期资金-全口径（万元，不含24年逾期资金）] [varchar](400) NULL,
	[2025年资金到期情况] [varchar](400) NULL,
	[2025年新增到期资金-权益（万元，不含24年逾期资金）] [varchar](400) NULL,
	[2025年新增到期资金-并表（万元，不含24年逾期资金）] [varchar](400) NULL,
	[2025年应收回-全口径（逾期加25年到期）] [varchar](400) NULL,
	[2025年应收回-权益口径（逾期加25年到期）] [varchar](400) NULL,
	[2025年应收回-并表口径（逾期加25年到期）] [varchar](400) NULL,
	[2025年全年预计收回资金-全口径（万元）] [varchar](400) NULL,
	[2025年全年预计收回资金-权益（万元）] [varchar](400) NULL,
	[一季度] [varchar](400) NULL,
	[二季度] [varchar](400) NULL,
	[三季度] [varchar](400) NULL,
	[四季度] [varchar](400) NULL,
	[2025年全年预计收回资金-并表（万元）] [varchar](400) NULL,
	[check] [varchar](400) NULL,
	[拟置换地块基本情况] [varchar](400) NULL,
	[是否可以在25年签约] [varchar](400) NULL,
	[25年预计供货时间] [varchar](400) NULL,
	[25年预计签约_（亿元）] [varchar](400) NULL,
	[是否已在2025年1月2日版本中铺排签约] [varchar](400) NULL,
	[26年预计收回（全口径）] [varchar](400) NULL,
	[27年预计收回（全口径）] [varchar](400) NULL,
	[28年及以后预计收回（全口径）] [varchar](400) NULL,
	[推进及盘活思路] [varchar](400) NULL,
	[上月工作进展] [varchar](400) NULL,
	[下月工作计划] [varchar](400) NULL,
	[预计本季度工作计划是否按节点达成] [varchar](400) NULL,
	[未按节点达成事项] [varchar](400) NULL,
	[盘活资金比例（低于应盘活比例百分之70，推送预警）] [varchar](400) NULL,
	[本季度已收回金额（并表口径、单位万元）] [varchar](400) NULL,
	[全年累计收回任务（并表口径、单位万元）] [varchar](400) NULL,
	[全年累计收回金额（并表口径、单位万元）] [varchar](400) NULL,
	[剩余全口径占压金额（单位万元）] [varchar](400) NULL,
	[剩余权益口径占压金额（单位万元）] [varchar](400) NULL,
	[剩余并表口径占压金额（单位万元）] [varchar](400) NULL,
	[全年累计签约金额（全口径、单位万元）] [varchar](400) NULL,
PRIMARY KEY CLUSTERED 
(
	[平台公司待返还资金GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

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
                             WHERE  FILLNAME = '平台公司待返还资金'
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
	SELECT @COUNTNUM=COUNT(1) FROM nmap_F_平台公司待返还资金 
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
                             WHERE  FILLNAME = '平台公司待返还资金'
                           )
			AND FILLHISTORYGUID IN (SELECT DISTINCT FILLHISTORYGUID FROM nmap_F_平台公司待返还资金
			WHERE ISNULL(项目名称,'') <> '')
    ORDER BY ENDDATE DESC;	


	-- 刷新组织架构
	SELECT  
	  newid() as  [平台公司待返还资金GUID]
      ,@FILLHISTORYGUID as [FillHistoryGUID]
      ,c.CompanyGUID as [BusinessGUID]
      ,c.CompanyName as [公司简称]
      ,isnull(d.[区域],a.[区域]) as [区域]
      ,isnull(d.[项目代码],a.[项目代码]) as [项目代码]
      ,isnull(d.[我司股比],a.[我司股比]) as [我司股比]
      ,isnull(d.[是否并表],a.[是否并表]) as [是否并表]
      ,isnull(d.[挂图问题类型],a.[挂图问题类型]) as [挂图问题类型]
      ,isnull(d.[项目名称],a.[项目名称]) as [项目名称]
      ,isnull(d.[最后导入人],null) as [最后导入人]
      ,isnull(d.[最后导入时间],getdate()) as [最后导入时间]
      ,null as [RowID]
      ,isnull(d.[合同或立项约定的返还节点、金额],a.[合同或立项约定的返还节点、金额]) as [合同或立项约定的返还节点、金额]
      ,isnull(d.[全口径应回收资金总额（万元）],a.[全口径应回收资金总额（万元）]) as [全口径应回收资金总额（万元）]
      ,isnull(d.[权益应回收资金总额（万元）],a.[权益应回收资金总额（万元）]) as [权益应回收资金总额（万元）]
      ,isnull(d.[并表口径应回收资金总额（万元）],a.[并表口径应回收资金总额（万元）]) as [并表口径应回收资金总额（万元）]
      ,isnull(d.[全口径已收回资金总额（万元）],a.[全口径已收回资金总额（万元）]) as [全口径已收回资金总额（万元）]
      ,isnull(d.[权益已回收资金总额（万元）],a.[权益已回收资金总额（万元）]) as [权益已回收资金总额（万元）]
      ,isnull(d.[并表口径已回收资金总额（万元）],a.[并表口径已回收资金总额（万元）]) as [并表口径已回收资金总额（万元）]
      ,isnull(d.[全口径未回收资金总额（万元）],a.[全口径未回收资金总额（万元）]) as [全口径未回收资金总额（万元）]
      ,isnull(d.[其中：逾期未收回资金（全口径，万元）],a.[其中：逾期未收回资金（全口径，万元）]) as [其中：逾期未收回资金（全口径，万元）]
      ,isnull(d.[左列勾稽检查1],a.[左列勾稽检查1]) as [左列勾稽检查1]
      ,isnull(d.[权益未回收资金总额（万元）],a.[权益未回收资金总额（万元）]) as [权益未回收资金总额（万元）]
      ,isnull(d.[其中：逾期未收回资金（权益，万元）],a.[其中：逾期未收回资金（权益，万元）]) as [其中：逾期未收回资金（权益，万元）]
      ,isnull(d.[左列勾稽检查2],a.[左列勾稽检查2]) as [左列勾稽检查2]
      ,isnull(d.[并表口径未回收资金总额（万元）],a.[并表口径未回收资金总额（万元）]) as [并表口径未回收资金总额（万元）]
      ,isnull(d.[其中：逾期未收回资金（并表，万元）],a.[其中：逾期未收回资金（并表，万元）]) as [其中：逾期未收回资金（并表，万元）]
      ,isnull(d.[年新增到期资金-全口径（万元，不含24年逾期资金）],a.[2025年新增到期资金-全口径（万元，不含24年逾期资金）]) as [年新增到期资金-全口径（万元，不含24年逾期资金）]
      ,isnull(d.[2025年资金到期情况],a.[2025年资金到期情况]) as [2025年资金到期情况]
      ,isnull(d.[2025年新增到期资金-权益（万元，不含24年逾期资金）],a.[2025年新增到期资金-权益（万元，不含24年逾期资金）]) as [2025年新增到期资金-权益（万元，不含24年逾期资金）]
      ,isnull(d.[2025年新增到期资金-并表（万元，不含24年逾期资金）],a.[2025年新增到期资金-并表（万元，不含24年逾期资金）]) as [2025年新增到期资金-并表（万元，不含24年逾期资金）]
      ,isnull(d.[2025年应收回-全口径（逾期加25年到期）],a.[2025年应收回-全口径（逾期+25年到期）]) as [2025年应收回-全口径（逾期加25年到期）]
      ,isnull(d.[2025年应收回-权益口径（逾期加25年到期）],a.[2025年应收回-权益口径（逾期+25年到期）]) as [2025年应收回-权益口径（逾期加25年到期）]
      ,isnull(d.[2025年应收回-并表口径（逾期加25年到期）],a.[2025年应收回-并表口径（逾期+25年到期）]) as [2025年应收回-并表口径（逾期加25年到期）]
      ,isnull(d.[2025年全年预计收回资金-全口径（万元）],a.[2025年全年预计收回资金-全口径（万元）]) as [2025年全年预计收回资金-全口径（万元）]
      ,isnull(d.[2025年全年预计收回资金-权益（万元）],a.[2025年全年预计收回资金-权益（万元）]) as [2025年全年预计收回资金-权益（万元）]
      ,isnull(d.[一季度],a.[一季度]) as [一季度]
      ,isnull(d.[二季度],a.[二季度]) as [二季度]
      ,isnull(d.[三季度],a.[三季度]) as [三季度]
      ,isnull(d.[四季度],a.[四季度]) as [四季度]
      ,isnull(d.[2025年全年预计收回资金-并表（万元）],a.[2025年全年预计收回资金-并表（万元）]) as [2025年全年预计收回资金-并表（万元）]
      ,isnull(d.[check],a.[check]) as [check]
      ,isnull(d.[拟置换地块基本情况],a.[拟置换地块基本情况]) as [拟置换地块基本情况]
      ,isnull(d.[是否可以在25年签约],a.[是否可以在25年签约]) as [是否可以在25年签约]
      ,isnull(d.[25年预计供货时间],a.[25年预计供货时间]) as [25年预计供货时间]
      ,isnull(d.[25年预计签约_（亿元）],a.[25年预计签约_（亿元）]) as [25年预计签约]
      ,isnull(d.[是否已在2025年1月2日版本中铺排签约],a.[是否已在2025年1月2日版本中铺排签约]) as [是否已在2025年1月2日版本中铺排签约]
      ,isnull(d.[26年预计收回（全口径）],a.[26年预计收回（全口径）]) as [26年预计收回（全口径）]
      ,isnull(d.[27年预计收回（全口径）],a.[27年预计收回（全口径）]) as [27年预计收回（全口径）]
      ,isnull(d.[28年及以后预计收回（全口径）],a.[28年及以后预计收回（全口径）]) as [28年及以后预计收回（全口径）]
      ,isnull(d.[推进及盘活思路],a.[推进及盘活思路]) as [推进及盘活思路]
      ,isnull(d.[上月工作进展],a.[上月工作进展]) as [上月工作进展]
      ,isnull(d.[下月工作计划],a.[下月工作计划]) as [下月工作计划]
      ,isnull(d.[预计本季度工作计划是否按节点达成],a.[预计本季度工作计划是否按节点达成]) as [预计本季度工作计划是否按节点达成]
      ,isnull(d.[未按节点达成事项],a.[未按节点达成事项]) as [未按节点达成事项]
      ,isnull(d.[盘活资金比例（低于应盘活比例百分之70，推送预警）],a.[盘活资金比例_（低于应盘活比例70%，推送预警）]) as [盘活资金比例（低于应盘活比例百分之70，推送预警）]
      ,isnull(d.[本季度已收回金额（并表口径、单位万元）],a.[本季度已收回金额（并表口径、单位万元）]) as [本季度已收回金额（并表口径、单位万元）]
	    ,isnull(d.[全年累计收回任务（并表口径、单位万元）],a.[全年累计收回任务（并表口径、单位万元）]) as [全年累计收回任务（并表口径、单位万元）]
	    ,isnull(d.[全年累计收回金额（并表口径、单位万元）],a.[全年累计收回金额（并表口径、单位万元）]) as [全年累计收回金额（并表口径、单位万元）]
	    ,isnull(d.[剩余全口径占压金额（单位万元）],a.[剩余全口径占压金额（单位万元）]) as [剩余全口径占压金额（单位万元）]
	    ,isnull(d.[剩余权益口径占压金额（单位万元）],a.[剩余权益口径占压金额（单位万元）]) as [剩余权益口径占压金额（单位万元）]
	    ,isnull(d.[剩余并表口径占压金额（单位万元）],a.[剩余并表口径占压金额（单位万元）]) as [剩余并表口径占压金额（单位万元）]
	    ,isnull(d.[全年累计签约金额（全口径、单位万元）],a.[全年累计签约金额（全口径、单位万元）]) as [全年累计签约金额（全口径、单位万元）]
	INTO #TempData
	from  待返还资金 a
	left join erp25.dbo.p_DevelopmentCompany b on  case when a.公司 = '东北公司' then '辽宁公司' else a.公司 end = b.DevelopmentCompanyName
	left join nmap_N_CompanyToTerraceBusiness c2b on b.DevelopmentCompanyGUID = c2b.DevelopmentCompanyGUID
	left join nmap_N_Company c on c2b.CompanyGUID = c.CompanyGUID
	-- 查询上一版的数据进行继承
	left join (
           select  distinct * from  nmap_F_平台公司待返还资金  
		   where  FILLHISTORYGUID = @FILLHISTORYGUIDLAST and isnull(项目名称,'') <> ''
	) d on a.[项目名称] = d.[项目名称]



-- --删除旧数据  
    DELETE  FROM nmap_F_平台公司待返还资金
    WHERE   FillHistoryGUID = @FillHistoryGUID;  

	 -- 将数据插入到当前版本
	 INSERT INTO nmap_F_平台公司待返还资金
	 SELECT * FROM #TempData;

	 -- 删除临时表
	 DROP TABLE #TempData;
