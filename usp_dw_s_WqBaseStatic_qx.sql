USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_dw_s_WqBaseStatic_qx]    Script Date: 2024/10/23 10:52:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[usp_dw_s_WqBaseStatic_qx] as
/*
用途：将宽表进行每天存档，并进行存档数据清理
author：lintx
date:20240905

涉及宽表：
湾区公司底表组织架构信息：Data_Wide_Dws_s_WqBaseStatic_Organization 
湾区公司底表基本信息：data_wide_dws_s_WqBaseStatic_BaseInfo 
湾区公司底表货值信息：data_wide_dws_s_WqBaseStatic_salevalueInfo		 
湾区公司底表产成品货值信息：data_wide_dws_s_WqBaseStatic_ProductedHZInfo 
湾区公司底表计划节点信息：data_wide_dws_s_WqBaseStatic_ScheduleInfo	
湾区公司底表产销信息:data_wide_dws_s_WqBaseStatic_ProdMarkInfo		
湾区公司底表产销信息_树形结构:data_wide_dws_s_WqBaseStatic_ProdMarkInfo_month		
湾区公司底表成本信息:data_wide_dws_s_WqBaseStatic_CbInfo		
湾区公司底表立项定位信息:data_wide_dws_s_WqBaseStatic_LxdwInfo		
湾区公司底表销售信息:data_wide_dws_s_WqBaseStatic_tradeInfo		
湾区公司底表回笼信息:data_wide_dws_s_WqBaseStatic_returnInfo		
湾区公司底表动态签约利润信息:data_wide_dws_s_WqBaseStatic_ProfitInfo		
湾区公司底表现金流信息：data_wide_dws_s_WqBaseStatic_cashflowInfo
湾区公司底表盈利规划信息:data_wide_dws_s_WqBaseStatic_ylghInfo	

将表进行压缩存储
ALTER TABLE [dbo].[dw_s_WqBaseStatic_Organization] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_BaseInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_salevalueInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_ProductedHZInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_ScheduleInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_ProdMarkInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_ProdMarkInfo_month] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_CbInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_LxdwInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_tradeInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_returnInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_ProfitInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_cashflowInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [dbo].[dw_s_WqBaseStatic_ylghInfo] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)

modify chenjw  date 20241017 
1、dw_s_WqBaseStatic_CbInfo 清洗表增加已发生、待发生、已支付和合同性成本字段
2、dw_s_WqBaseStatic_CbInfo 清洗表增加降本任务目标字段
*/
BEGIN
	declare @date_id int ;
	select  @date_id =convert(int,REPLACE(convert(varchar(10),getdate(),120),'-',''))

	------------------同步开始 
	--湾区公司底表组织架构信息：Data_Wide_Dws_s_WqBaseStatic_Organization 
	delete from dw_s_WqBaseStatic_Organization where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_Organization 
	select newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		 [组织架构父级ID], [组织架构类型],[组织架构类型名称],[组织架构ID], [组织架构编码],  [组织架构名称], [平台公司GUID],[平台公司名称], [项目代码], [项目guid],[项目名称], [分期id], [分期名称], [业态], [产品名称],[商业类型], [装修标准], [工程楼栋ID], [工程楼栋名称],[产品楼栋ID], [产品楼栋名称],  [户型], [房], [厅], [卫], [阳台]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization 

	-- 湾区公司底表基本信息：data_wide_dws_s_WqBaseStatic_BaseInfo 
	delete from dw_s_WqBaseStatic_BaseInfo where 清洗时间id = @date_id
	insert into  dw_s_WqBaseStatic_BaseInfo 
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		 [组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称], [产品楼栋], [产品名称],[地价],地块名, [地上计容面积], [地上建筑面积], [地下建筑面积], [工程楼栋], [股权比例], [合作方], [户数], [获取方式], [获取时间], [可售车库面积], [可售车位个数], [可售面积], [明源代码], [区域], [人防车库面积], [人防车位个数], [容积率], [是否并表], [是否操盘], [所属镇街], [投管代码], [项目guid], [项目标签], [项目名称], [项目所属城市], [项目推广名], [销售片区], [业态], [占地面积], [自持面积], [总计容面积], [总建筑面积],[工程状态], [项目数量], [在建项目数量], [在建建筑面积], [注册资本], [可售楼面价], [董事], [董事长], [总经理], [法定代表人], [监事], [项目公司名], [保利方认缴资本], [实缴资本], [成立日期], [项目状态], [营销操盘方], [工程操盘方], [成本操盘方], [技术操盘方], [开发操盘方], [物业操盘方], [客关操盘方], [并表方], [住宅总可售户数], [自持地上面积], [自持地下面积不含车库], [自持车位面积], [自持车位个数], [配套车位个数], [配套车位面积], [存量增量]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_BaseInfo 

	-- 湾区公司底表货值信息：data_wide_dws_s_WqBaseStatic_salevalueInfo	
	delete from dw_s_WqBaseStatic_salevalueInfo	 where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_salevalueInfo	
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		 [组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称], [本年可售货值金额], [本年可售货值面积], [产成品获证待推金额], [产成品已推未售金额], [当前可售货值金额], [当前可售货值面积], [动态总资源], [获证待推金额], [获证待推面积], [具备条件未领证金额], [具备条件未领证面积], [累计签约货值], [年初产成品获证待推金额], [年初产成品已推未售金额], [年初动态货值], [年初动态货值面积], [年初获证待推金额], [年初获证待推面积], [年初具备条件未领证金额], [年初具备条件未领证面积], [年初可售货值金额], [年初可售货值面积], [年初剩余货值], [年初剩余货值面积], [年初已推未售金额], [年初已推未售面积], [年初正常获证待推金额], [年初正常已推未售金额], [年初准产成品获证待推金额], [年初准产成品已推未售金额], [剩余货值单价], [剩余货值金额], [剩余货值面积], [已推未售金额], [已推未售面积], [正常获证待推金额], [正常已推未售金额], [准产成品获证待推金额], [准产成品已推未售金额],[Apr预计货量金额], [Aug预计货量金额], [Dec预计货量金额], [Feb预计货量金额], [Jan预计货量金额], [July预计货量金额], [Jun预计货量金额], [Mar预计货量金额], [May预计货量金额], [Nov预计货量金额], [Oct预计货量金额], [Sep预计货量金额], [本年新增货量], [后年Apr预计货量金额], [后年Aug预计货量金额], [后年Dec预计货量金额], [后年Feb预计货量金额], [后年Jan预计货量金额], [后年July预计货量金额], [后年Jun预计货量金额], [后年Mar预计货量金额], [后年May预计货量金额], [后年Nov预计货量金额], [后年Oct预计货量金额], [后年Sep预计货量金额], [后年新增货量], [明年Apr预计货量金额], [明年Aug预计货量金额], [明年Dec预计货量金额], [明年Feb预计货量金额], [明年Jan预计货量金额], [明年July预计货量金额], [明年Jun预计货量金额], [明年Mar预计货量金额], [明年May预计货量金额], [明年Nov预计货量金额], [明年Oct预计货量金额], [明年Sep预计货量金额], [明年新增货量], [总货值面积], [累计签约面积], [剩余货值金额_三年内不开工], [剩余货值面积_三年内不开工], [未开工剩余货值面积], [未开工剩余货值金额], [在途剩余货值面积], [在途剩余货值金额], [组织架构父级ID], [剩余货值预估去化面积], [剩余货值预估去化金额], [累计签约套数], [Apr实际货量金额], [Aug实际货量金额], [Dec实际货量金额], [Feb实际货量金额], [Jan实际货量金额], [July实际货量金额], [Jun实际货量金额], [Mar实际货量金额], [May实际货量金额], [Nov实际货量金额], [Oct实际货量金额], [Sep实际货量金额], [剩余货值预估去化面积_按月份差], [剩余货值预估去化金额_按月份差], [年初剩余货值_年初清洗版], [年初剩余货值面积_年初清洗版], [年初取证未售货值_年初清洗版], [年初取证未售面积_年初清洗版], [本年已售货值_截止上月底清洗版], [本年已售面积_截止上月底清洗版], [本年取证剩余货值_截止上月底清洗版], [本年取证剩余面积_截止上月底清洗版], [预估本年取证新增货值], [预估本年取证新增面积], [停工缓建剩余货值金额], [停工缓建剩余货值面积], [停工缓建剩余货值套数], [停工缓建工程达到可售未拿证货值金额], [停工缓建工程达到可售未拿证货值面积], [停工缓建获证未推货值金额], [停工缓建获证未推货值面积], [停工缓建已推未售货值金额], [停工缓建剩余可售货值面积], [停工缓建剩余可售货值金额], [停工缓建已推未售货值面积], [停工缓建在途剩余货值金额], [停工缓建在途剩余货值面积],
		 总货值套数,剩余货值套数,剩余货值套数_三年内不开工,未开工剩余货值套数,在途剩余货值套数,停工缓建在途剩余货值套数,剩余可售货值套数,工程达到可售未拿证货值套数,停工缓建工程达到可售未拿证货值套数,获证未推货值套数,停工缓建获证未推货值套数,已推未售货值套数,停工缓建已推未售货值套数 ,停工缓建剩余可售货值套数
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_salevalueInfo	
 
	-- 湾区公司底表产成品货值信息：data_wide_dws_s_WqBaseStatic_ProductedHZInfo 
	delete from dw_s_WqBaseStatic_ProductedHZInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_ProductedHZInfo 
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称], [本年已售产成品金额], [本年已售产成品面积], [本年已售准产成品金额], [本年已售准产成品面积], [动态产成品货值金额], [动态产成品货值面积], [动态准产成品货值金额], [动态准产成品货值面积], [年初产成品剩余货值金额], [年初产成品剩余货值面积], [年初准产成品剩余货值金额], [年初准产成品剩余货值面积], [预估去化产成品金额], [预估去化产成品面积], [预估去化准产成品金额], [预估去化准产成品面积], [预计年底产成品货值金额], [预计年底产成品货值面积], [预计年底明年准产成品货值金额], [预计年底明年准产成品货值面积], [动态产成品货值金额_集团考核版], [动态产成品货值面积_集团考核版], [动态准产成品货值金额_含本年竣工版], [动态准产成品货值面积_含本年竣工版]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_ProductedHZInfo 

	-- 湾区公司底表计划节点信息：data_wide_dws_s_WqBaseStatic_ScheduleInfo	
	delete from dw_s_WqBaseStatic_ScheduleInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_ScheduleInfo 
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		 [组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称],[本年计划竣工面积], [本年计划开工面积], [本年计划在建面积], [本年实际竣工面积], [本年实际开工面积], [本年实际在建面积], [本月计划竣工面积], [本月计划开工面积], [本月计划在建面积], [本月实际竣工面积], [本月实际开工面积], [本月实际在建面积], [集中交付计划完成时间], [集中交付实际完成时间], [集中交付预计完成时间], [竣工备案集团里程碑时间], [竣工备案计划完成时间], [竣工备案实际完成时间], [竣工备案预计完成时间], [累计计划竣工面积], [累计计划开工面积], [累计计划在建面积], [累计实际竣工面积], [累计实际开工面积], [累计实际在建面积], [明年计划竣工面积], [明年计划开工面积], [明年计划在建面积], [实际开工集团里程碑时间], [实际开工计划完成时间], [实际开工实际完成时间], [实际开工预计完成时间], [收回股东投资集团里程碑时间], [收回股东投资实际完成时间], [现金流回正集团里程碑时间], [现金流回正实际完成时间], [项目开盘计划完成时间], [项目开盘实际完成时间], [预售办理集团里程碑时间], [预售办理计划完成时间], [预售办理实际完成时间], [预售办理预计完成时间], [预售形象集团里程碑时间], [预售形象计划完成时间], [预售形象实际完成时间], [预售形象预计完成时间], [正式开工集团里程碑时间], [正式开工计划完成时间], [正式开工实际完成时间], [正式开工预计完成时间],  [项目开盘预计完成时间], [是否停工]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_ScheduleInfo

	-- 湾区公司底表产销信息:data_wide_dws_s_WqBaseStatic_ProdMarkInfo	
	delete from dw_s_WqBaseStatic_ProdMarkInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_ProdMarkInfo
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构ID], [组织架构父级id], [组织架构类型], [组织架构名称], [动态10月存货货值面积], [动态10月已开工未售面积], [动态11月存货货值面积], [动态11月已开工未售面积], [动态12月存货货值面积], [动态12月已开工未售面积], [动态1月存货货值面积], [动态1月已开工未售面积], [动态2月存货货值面积], [动态2月已开工未售面积], [动态3月存货货值面积], [动态3月已开工未售面积], [动态4月存货货值面积], [动态4月已开工未售面积], [动态5月存货货值面积], [动态5月已开工未售面积], [动态6月存货货值面积], [动态6月已开工未售面积], [动态7月存货货值面积], [动态7月已开工未售面积], [动态8月存货货值面积], [动态8月已开工未售面积], [动态9月存货货值面积], [动态9月已开工未售面积], [近3月平均签约流速], [动态1月预计新增已开工未售面积], [动态2月预计新增已开工未售面积], [动态3月预计新增已开工未售面积], [动态4月预计新增已开工未售面积], [动态5月预计新增已开工未售面积], [动态6月预计新增已开工未售面积], [动态7月预计新增已开工未售面积], [动态8月预计新增已开工未售面积], [动态9月预计新增已开工未售面积], [动态10月预计新增已开工未售面积], [动态11月预计新增已开工未售面积], [动态12月预计新增已开工未售面积], [动态1月预计新增存货货值面积], [动态2月预计新增存货货值面积], [动态3月预计新增存货货值面积], [动态4月预计新增存货货值面积], [动态5月预计新增存货货值面积], [动态6月预计新增存货货值面积], [动态7月预计新增存货货值面积], [动态8月预计新增存货货值面积], [动态9月预计新增存货货值面积], [动态10月预计新增存货货值面积], [动态11月预计新增存货货值面积], [动态12月预计新增存货货值面积], [当前存货面积], [当前已开工未售面积]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_ProdMarkInfo	

	-- 湾区公司底表产销信息_树形结构:data_wide_dws_s_WqBaseStatic_ProdMarkInfo_month
	delete from dw_s_WqBaseStatic_ProdMarkInfo_month where 清洗时间id = @date_id
	insert into  dw_s_WqBaseStatic_ProdMarkInfo_month 
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构ID], [组织架构父级ID], [组织架构类型], [组织架构名称],[本月预计新增存货面积], [本月预计新增已开工未售面积], [存货货值面积], [近3月平均签约流速], [已开工未售面积], [月份], [月份差],  [当前存货面积], [当前已开工未售面积]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_ProdMarkInfo_month

	-- 湾区公司底表成本信息:data_wide_dws_s_WqBaseStatic_CbInfo	
	delete from dw_s_WqBaseStatic_CbInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_CbInfo
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称],[动态成本], [动态成本财务费用], [动态成本除地价外直投], [动态成本管理费用], [动态成本营销费用], [动态成本直投], [目标成本], [目标成本财务费用], [目标成本除地价外直投], [目标成本管理费用], [目标成本营销费用], [目标成本直投], [年初目标成本], [年初目标成本财务费用], [年初目标成本除地价外直投], [年初目标成本管理费用], [年初目标成本营销费用], [年初目标成本直投],已发生成本,已发生成本直投,已发生成本除地价外直投,已发生成本营销费用,已发生成本管理费用,已发生成本财务费用,待发生成本,待发生成本直投,待发生成本除地价外直投,待发生成本营销费用,待发生成本管理费用,待发生成本财务费用,已支付成本,已支付成本直投,已支付成本除地价外直投,已支付成本营销费用,已支付成本管理费用,已支付成本财务费用,合同性成本,合同性成本直投,合同性成本除地价外直投,合同性成本营销费用,合同性成本管理费用,合同性成本财务费用,降本任务,直投降本任务,除地价外直投降本任务,营销费用降本任务,管理费用降本任务 ,财务费用降本任务,
		合同总金额,总变更率,现场签证累计发生比例,现场签证累计发生金额,设计变更累计发生比例,设计变更累计发生金额,总包合同总金额,总包总变更率,总包现场签证累计发生比例,总包现场签证累计发生金额,总包设计变更累计发生比例,总包设计变更累计发生金额,变更总金额,合同金额,总包变更总金额,总包合同金额,装修合同总金额,装修总变更率,装修变更总金额,装修合同金额,装修现场签证累计发生比例,装修现场签证累计发生金额,装修设计变更累计发生比例,装修设计变更累计发生金额,园林合同总金额,园林总变更率,园林变更总金额,园林合同金额,园林现场签证累计发生比例,园林现场签证累计发生金额,园林设计变更累计发生比例,园林设计变更累计发生金额,其他合同总金额,其他总变更率,其他变更总金额,其他合同金额,其他现场签证累计发生比例,其他现场签证累计发生金额,其他设计变更累计发生比例,其他设计变更累计发生金额
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_CbInfo
 
	-- 湾区公司底表立项定位信息:data_wide_dws_s_WqBaseStatic_LxdwInfo
	delete from dw_s_WqBaseStatic_LxdwInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_LxdwInfo
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称], [定位IRR], [定位财务费用], [定位除地价外直投], [定位贷款金额], [定位贷款利息], [定位单价], [定位地下建筑面积], [定位股东借款利息], [定位固定资产], [定位管理费用], [定位货值], [定位可售面积], [定位批复版IRR], [定位批复版财务费用计划口径], [定位批复版财务费用账面口径], [定位批复版除地价外直投], [定位批复版贷款金额], [定位批复版贷款利息], [定位批复版单价], [定位批复版地下建筑面积], [定位批复版股东借款利息], [定位批复版固定资产], [定位批复版管理费用], [定位批复版货值], [定位批复版可售面积], [定位批复版收回股东投资时间], [定位批复版首开时间], [定位批复版税后利润], [定位批复版税后现金利润], [定位批复版税前成本利润率], [定位批复版税前利润], [定位批复版现金流回正时间], [定位批复版营销费用], [定位批复版总建筑面积], [定位批复版总投资], [定位收回股东投资时间], [定位首开时间], [定位税后利润], [定位税后现金利润], [定位税前成本利润率], [定位税前利润], [定位现金流回正时间], [定位营销费用], [定位总建筑面积], [定位总投资], [立项IRR], [立项财务费用账面], [立项除地价外直投], [立项贷款金额], [立项单价], [立项地下建筑面积], [立项固定资产], [立项管理费用], [立项货值], [立项可售面积_非车位], [立项收回股东投资时间], [立项首开时间], [立项税后利润], [立项税后现金利润], [立项税前成本利润率账面], [立项税前利润], [立项现金流回正时间], [立项营销费用], [立项总建筑面积], [立项总投资], [定位批复版土地款], [定位最新版财务费用账面口径], [定位最新版除地价外直投], [定位最新版贷款金额], [定位最新版贷款利息], [定位最新版地下建筑面积], [定位最新版定位单价], [定位最新版股东借款利息], [定位最新版管理费用], [定位最新版可售面积], [定位最新版货值], [定位最新版税后利润], [定位最新版税后现金利润], [定位最新版税前成本利润率], [定位最新版税前利润], [定位最新版土地款], [定位最新版营销费用], [定位最新版总投资], [定位最新版总建筑面积], [立项土地款], [定位土地款], [定位最新版IRR], [定位最新版收回股东投资时间], [定位最新版首开时间], [定位最新版固定资产], [定位最新版现金流回正时间], [定位最新版财务费用计划口径], [组织架构父级ID], [立项可售住宅户数], [立项可售车位面积], [立项可售车位个数], [立项自有资金内部收益率], [立项实际开工时间], [立项竣工时间], [立项交付时间], [定位财务费用账面]
		 ,立项套数  ,定位套数 , 定位批复版套数 ,定位最新版套数 
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_LxdwInfo		

	-- 湾区公司底表销售信息:data_wide_dws_s_WqBaseStatic_tradeInfo	
	delete from dw_s_WqBaseStatic_tradeInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_tradeInfo
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
	   [组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称],[本年签约均价], [本年签约任务], [本年认购金额], [本年认购均价], [本年认购面积], [本年认购任务], [本年认购套数], [本年退房金额], [本年退房套数], [本年已签约金额], [本年已签约面积], [本年已签约套数], [本日签约金额], [本日签约面积], [本日签约套数], [本日认购金额], [本日认购面积], [本日认购套数], [本月签约金额], [本月签约均价], [本月签约面积], [本月签约套数], [本月认购金额], [本月认购均价], [本月认购面积], [本月认购套数], [本月退房金额], [本月退房套数], [本周签约金额], [本周签约均价], [本周签约面积], [本周签约套数], [本周认购金额], [本周认购均价], [本周认购面积], [本周认购套数], [本周退房金额], [本周退房套数], [今日退房金额], [今日退房套数], [近三个月均价], [近三个月流速_金额], [近三个月流速_面积], [累计签约均价], [累计认购金额], [累计认购均价], [累计认购面积], [累计认购套数], [累计已签约金额], [累计已签约面积], [累计已签约套数], [明年签约任务], [已认购未签约金额],  [本年10月签约金额], [本年10月认购金额], [本年11月签约金额], [本年11月认购金额], [本年12月签约金额], [本年12月认购金额], [本年1月签约金额], [本年1月认购金额], [本年2月签约金额], [本年2月认购金额], [本年3月签约金额], [本年3月认购金额], [本年4月签约金额], [本年4月认购金额], [本年5月签约金额], [本年5月认购金额], [本年6月签约金额], [本年6月认购金额], [本年7月签约金额], [本年7月认购金额], [本年8月签约金额], [本年8月认购金额], [本年9月签约金额], [本年9月认购金额], [累计待收款], [累计未正签按揭待收款], [累计未正签待收款], [累计未正签非按揭待收款], [累计未正签非按揭待收款本月到期], [累计未正签非按揭待收款本月完成], [累计未正签非按揭待收款下月到期], [累计正签待收款], [正签非按揭待收款], [正签非按揭待收款本月到期], [正签非按揭待收款本月完成], [正签非按揭待收款下月到期], [正签公积金贷款待收款], [正签商业贷款待收款], [正签商业贷款待收款本月到期], [正签商业贷款待收款本月完成], [正签商业贷款待收款下月到期], [去年认购套数], [去年认购任务], [去年认购金额], [去年认购面积], [去年认购均价], [去年已签约套数], [去年签约任务], [去年已签约金额], [去年已签约面积], [去年签约均价], [本月认购任务], [本月签约任务], [今日退房面积], [本周退房面积], [本月退房面积], [本年退房面积]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_tradeInfo
 
	-- 湾区公司底表回笼信息:data_wide_dws_s_WqBaseStatic_returnInfo	
	delete from dw_s_WqBaseStatic_returnInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_returnInfo
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称],[本年10月回笼金额], [本年11月回笼金额], [本年12月回笼金额], [本年1月回笼金额], [本年2月回笼金额], [本年3月回笼金额], [本年4月回笼金额], [本年5月回笼金额], [本年6月回笼金额], [本年7月回笼金额], [本年8月回笼金额], [本年9月回笼金额], [本年回笼金额], [本年回笼任务], [本年签约本年回笼], [本日回笼金额], [本月回笼金额], [本周回笼金额], [累计已回笼金额], [年初待收款], [年初待收款回笼], [去年回笼金额], [去年回笼任务],  [本月回笼任务], [待收款金额], [本年权益回笼任务], [本月权益回笼任务], [本月权益回笼金额], [本年权益回笼金额]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_returnInfo	
 
	-- 湾区公司底表动态签约利润信息:data_wide_dws_s_WqBaseStatic_ProfitInfo	
	delete from dw_s_WqBaseStatic_ProfitInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_ProfitInfo 
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构id], [组织架构父级ID], [组织架构类型], [组织架构名称],[本年费用合计], [本年签约单价], [本年签约金额], [本年签约金额不含税], [本年签约面积], [本年税前利润], [本年所得税], [本年销售净利率账面], [本年销售净利润账面], [本年销售毛利率账面], [本年销售毛利润账面], [本年销售盈利规划税金及附加], [本年预计费用合计], [本年预计签约单价], [本年预计签约金额], [本年预计签约金额不含税], [本年预计签约面积], [本年预计税前利润], [本年预计所得税], [本年预计销售净利率账面], [本年预计销售净利润账面], [本年预计销售毛利率账面], [本年预计销售毛利润账面], [本年预计销售盈利规划税金及附加], [累计费用合计], [累计签约单价], [累计签约金额], [累计签约金额不含税], [累计签约面积], [累计税前利润], [累计所得税], [累计销售净利率账面], [累计销售净利润账面], [累计销售毛利率账面], [累计销售毛利润账面], [累计销售盈利规划税金及附加], [去年费用合计], [去年签约单价], [去年签约金额], [去年签约金额不含税], [去年签约面积], [去年税前利润], [去年所得税], [去年销售净利率账面], [去年销售净利润账面], [去年销售毛利率账面], [去年销售毛利润账面], [去年销售盈利规划税金及附加],  [剩余货值不含税], [剩余货值税前利润], [剩余货值净利润], [剩余货值所得税], [剩余货值销售净利率账面], [剩余货值销售毛利率账面], [剩余货值销售毛利润账面], [剩余货值销售盈利规划税金及附加], [剩余货值销售盈利规划综合管理费], [剩余货值销售盈利规划营销费用], [剩余面积], [剩余货值单价], [剩余货值金额], [本年签约金额不含车位], [本年签约面积不含车位], [本年预计签约金额不含车位], [本年预计签约面积不含车位], [去年签约金额不含车位], [去年签约面积不含车位], [累计签约金额不含车位], [累计签约面积不含车位], [剩余货值金额不含车位], [剩余面积不含车位], [盈利规划营业成本单方], [盈利规划费用单方], [盈利规划税金及附加单方], [本年销售盈利规划营业成本], [本年预计销售盈利规划营业成本], [去年销售盈利规划营业成本], [累计销售盈利规划营业成本], [剩余货值销售盈利规划营业成本], [累计销售盈利规划营业成本不含车位], [累计费用合计不含车位], [累计销售盈利规划税金及附加不含车位], [剩余货值销售盈利规划营业成本不含车位], [剩余货值销售盈利规划营销费用不含车位], [剩余货值销售盈利规划综合管理费不含车位], [剩余货值销售盈利规划税金及附加不含车位], [剩余货值实际流速版净利润], [剩余货值实际流速版签约金额], [剩余货值实际流速版签约金额不含税], [剩余货值实际流速版签约面积], [剩余货值实际流速版税前利润], [剩余货值实际流速版所得税], [剩余货值实际流速版销售净利率账面], [剩余货值实际流速版销售毛利率账面], [剩余货值实际流速版销售毛利润账面], [剩余货值实际流速版销售盈利规划税金及附加], [剩余货值实际流速版销售盈利规划营销费用], [剩余货值实际流速版销售盈利规划营业成本], [剩余货值实际流速版销售盈利规划综合管理费], [往年签约本年退房净利润], [往年签约本年退房签约金额], [往年签约本年退房签约面积], [往年签约本年退房签约金额不含税], [往年签约本年退房税前利润], [往年签约本年退房所得税], [往年签约本年退房销售净利率账面], [往年签约本年退房销售毛利率账面], [往年签约本年退房销售毛利润账面], [往年签约本年退房销售盈利规划税金及附加], [往年签约本年退房销售盈利规划营销费用], [往年签约本年退房销售盈利规划营业成本], [往年签约本年退房销售盈利规划综合管理费], [预估全年净利润], [预估全年签约金额], [预估全年签约金额不含税], [预估全年签约面积], [预估全年税前利润], [预估全年所得税], [预估全年销售净利率账面], [预估全年销售毛利率账面], [预估全年销售毛利润账面], [预估全年销售盈利规划税金及附加], [预估全年销售盈利规划营销费用], [预估全年销售盈利规划综合管理费], [预估全年销售盈利规划营业成本], [剩余货值实际流速版签约金额不含车位], [剩余货值实际流速版签约面积不含车位], [预估全年签约金额不含车位], [预估全年签约面积不含车位], [往年签约本年退房签约金额不含车位], [往年签约本年退房签约面积不含车位], [剩余货值实际流速版单价], [预估全年签约单价], [往年签约本年退房签约单价], [盈利规划除地价外直投单方], [盈利规划开发间接费单方], [盈利规划资本化利息单方], [盈利规划股权溢价单方], [累计销售盈利规划除地价外直投], [累计销售盈利规划股权溢价], [累计销售盈利规划开发间接费], [累计销售盈利规划综合管理费], [累计销售盈利规划除地价外直投不含车位], [累计销售盈利规划开发间接费不含车位], [累计销售盈利规划资本化利息不含车位], [累计销售盈利规划股权溢价不含车位], [剩余货值销售盈利规划除地价外直投不含车位], [剩余货值销售盈利规划开发间接费不含车位], [剩余货值销售盈利规划股权溢价不含车位], [剩余货值销售盈利规划资本化利息不含车位], [本月认购金额], [本月认购金额不含税], [本月认购净利率账面], [本月认购毛利率账面], [本月认购毛利润账面], [本月认购面积], [本月认购税前利润], [本月认购所得税], [本月认购盈利规划税金及附加], [本月认购盈利规划营销费用], [本月认购盈利规划营业成本], [本月认购盈利规划综合管理费], [本月净利润认购], [本月签约面积], [本月签约金额不含税], [本月签约金额], [本月净利润签约], [本月税前利润], [本月所得税], [本月销售净利率账面], [本月销售毛利率账面], [本月销售毛利润账面], [本月销售盈利规划税金及附加], [本月销售盈利规划营销费用], [本月销售盈利规划营业成本], [本月销售盈利规划综合管理费], [本月认购单价], [本月签约单价], [本月签约金额不含车位], [本月签约面积不含车位], [本月认购金额不含车位], [本月认购面积不含车位]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_ProfitInfo	
 
	-- 湾区公司底表现金流信息：data_wide_dws_s_WqBaseStatic_cashflowInfo
	delete from dw_s_WqBaseStatic_cashflowInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_cashflowInfo
	select  newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构id], [组织架构父级ID], [组织架构类型], [组织架构名称], [本年除地价外直投发生], [本年地价支出], [本年股东现金流], [本年经营性现金流], [本年实际拓展金额], [本年税金支出], [本年拓展任务], [本年现金流出], [本年现金流入], [本月除地价外直投发生], [本月地价支出], [本月经营性现金流], [本月税金支出], [本月现金流出], [本月现金流入], [贷款余额], [供应链融资余额], [累计除地价外直投发生], [累计地价支出], [累计股东现金流], [累计经营性现金流], [累计税金支出], [累计现金流出], [累计现金流入], [本年除地价外直投任务], [去年除地价外直投任务], [去年除地价外直投发生], [本年财务费支出], [本年管理费支出], [保利方投入余额], [本月财务费支出], [本年营销费支出], [本年我司股东净投入], [本月管理费支出], [本月营销费支出], [股东投入余额], [监控款余额], [累计财务费支出], [累计管理费支出], [累计营销费支出], [我司资金占用], [账面可动用资金], [本年净增贷款], [本月贷款金额], [本月股东现金流], [账面可动用资金并表口径], [监控款余额并表口径], [贷款余额并表口径], [我司资金占用并表口径], [股东投入余额并表口径], [供应链融资余额并表口径], [本月除地价外直投任务], [本月三费任务], [本月税金任务], [本月土地任务], [本年经营性现金流目标], [本年股东投资现金流目标], [本月股东投资现金流目标], [本月经营性现金流目标], [本年贷款任务], [本月贷款任务]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_cashflowInfo
 
	-- 湾区公司底表盈利规划信息:data_wide_dws_s_WqBaseStatic_ylghInfo	
	delete from dw_s_WqBaseStatic_ylghInfo where 清洗时间id = @date_id
	insert into dw_s_WqBaseStatic_ylghInfo
	select newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
		[组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称],[上版本盈利规划税金及附加单方], [上版本盈利规划营销费用单方], [上版本盈利规划营业成本单方], [上版本盈利规划综合管理费用单方], [盈利规划不含税计划总成本], [盈利规划不含税销售收入], [盈利规划不含税账面总成本], [盈利规划财务费用计划口径], [盈利规划费用化利息], [盈利规划固定资产], [盈利规划含税计划总成本], [盈利规划含税销售收入], [盈利规划含税账面总成本], [盈利规划签约面积], [盈利规划上个版本签约面积], [盈利规划上个版本税金及附加], [盈利规划上个版本营销费用], [盈利规划上个版本营业成本], [盈利规划上个版本综合管理费协议口径], [盈利规划税后利润计划], [盈利规划税后利润账面扣减股权溢价], [盈利规划税后现金利润账面], [盈利规划税金及附加], [盈利规划税金及附加单方], [盈利规划税前成本利润率计划], [盈利规划税前成本利润率账面], [盈利规划税前利润计划], [盈利规划税前利润账面扣减股权溢价], [盈利规划税前销售利润率账面], [盈利规划土增税], [盈利规划销售均价], [盈利规划营销费用], [盈利规划营销费用单方], [盈利规划营业成本], [盈利规划营业成本单方], [盈利规划资本化利息], [盈利规划综合管理费协议口径], [盈利规划综合管理费用单方],  [盈利规划本年签约金额不含税], [盈利规划本年签约金额含税], [盈利规划本年签约均价], [盈利规划本年签约面积], [盈利规划去年签约金额不含税], [盈利规划去年签约金额含税], [盈利规划去年签约均价], [盈利规划去年签约面积], [盈利规划本年销售净利率], [盈利规划本年销售净利润], [盈利规划本年销售毛利率], [盈利规划本年销售毛利润], [盈利规划去年销售净利率], [盈利规划去年销售净利润], [盈利规划去年销售毛利率], [盈利规划去年销售毛利润]
	from highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_ylghInfo


------------------同步结束 

------------------存档清理开始
--缓存2023年上线以来：近30天数据+节假日+每月的月初月末的时间
--近30天数据
select distinct date_id
into #d_day
from (select date_id
from highdata_prod.dbo.dw_d_date
where Date_DataDIFDay between 0 and 29
union all 
--节假日
SELECT t.date_id
FROM highdata_prod.dbo.dw_d_date t 
inner join [172.16.4.141].[MyCost_Erp352].dbo.myWorkflowSpecialDay d on t.date_date BETWEEN d.BeginDate and d.enddate
WHERE (1=1) and  isworkday = 0 and buguid  = '248B1E17-AACB-E511-80B8-E41F13C51836'
and t.date_year>='2023年'
union all
--每月月初
select min(date_id) as date_id
from highdata_prod.dbo.dw_d_date
where Date_DataDIFDay>0  and date_year>='2023年'
group by Date_YearMonth
union all
--每月月末
select max(date_id) as date_id
from highdata_prod.dbo.dw_d_date
where Date_DataDIFDay>0 and date_year>='2023年'
group by Date_YearMonth) t

--开始清理
delete t from dw_s_WqBaseStatic_Organization t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_BaseInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_salevalueInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_ProductedHZInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_ScheduleInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_ProdMarkInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_ProdMarkInfo_month t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_CbInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_LxdwInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null     
delete t from dw_s_WqBaseStatic_tradeInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null  
delete t from dw_s_WqBaseStatic_returnInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 
delete t from dw_s_WqBaseStatic_ProfitInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null   
delete t from dw_s_WqBaseStatic_cashflowInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null   	  	 	 
delete t from dw_s_WqBaseStatic_ylghInfo t left join  #d_day d on  t.清洗时间id = d.date_id where d.date_id is null 

------------------存档清理结束
end 