USE [dss]
GO


CREATE TABLE [dbo].[nmap_F_本次新推价量承诺表](
	[本次新推价量承诺表GUID] [uniqueidentifier] NOT NULL,
	[FillHistoryGUID] [uniqueidentifier] NULL,
	[BusinessGUID] [uniqueidentifier] NULL,
	[公司简称] [varchar](400) NULL,
	[投管代码] [varchar](400) NULL,
	[项目名称] [varchar](400) NULL,
	[项目GUID] [varchar](400) NULL,
	[推广名称] [varchar](400) NULL,
	[承诺时间] [datetime] NULL,
	[产品楼栋编码] [varchar](4000) NULL,
	[产品楼栋名称] [varchar](4000) NULL,
	[本批开工可售面积（万平方米）] [varchar](400) NULL,
	[本批开工货值（亿元）] [varchar](400) NULL,
	[供货周期（月）] [varchar](400) NULL,
	[去化周期（月）] [varchar](400) NULL,
	[本批开工后的项目累计签约回笼（亿元）] [varchar](400) NULL,
	[本批开工后的项目累计除地价外直投及费用（亿元）] [varchar](400) NULL,
	[本批开工后的项目累计贡献现金流（亿元）] [varchar](400) NULL,
	[本批开工后的一年内实现签约（亿元）] [varchar](400) NULL,
	[本批开工后的一年内实现回笼（亿元）] [varchar](400) NULL,
	[本批开工后的一年内除地价外直投及费用（亿元）] [varchar](400) NULL,
	[本批开工后的一年内贡献现金流（亿元）] [varchar](400) NULL,
	[未开工楼栋地价（亿元）] [varchar](400) NULL,
	[本次开工可收回地价（百分比）] [varchar](400) NULL,
	[回收股东占压资金（亿元）] [varchar](400) NULL,
	[本批开工的销售均价（元）] [varchar](400) NULL,
	[本批开工的可售单方成本（亿元）] [varchar](400) NULL,
	[本批开工的税后净利润（亿元）] [varchar](400) NULL,
	[本批开工的销净率（百分比）] [varchar](400) NULL,
	[本次新推量价承诺ID] [varchar](400) NULL,
	[新开类型] [varchar](400) NULL,
	[被动开工原因] [varchar](400) NULL,
	[开工后整盘销净率（百分比）] [varchar](400) NULL,
	[新开焕新力数量] [varchar](400) NULL,
	[新开焕新方案-户型力] [varchar](400) NULL,
	[最后导入人] [varchar](400) NULL,
	[最后导入时间] [datetime] NULL,
	[RowID] [int] NULL,
	[新开焕新方案-美学力] [varchar](400) NULL,
	[新开焕新方案-功能力] [varchar](400) NULL,
	[新开焕新方案-质量力] [varchar](400) NULL,
	[新开焕新方案-智能力] [varchar](400) NULL,
	[新开焕新方案-交通力] [varchar](400) NULL,
	[新开焕新方案-教育力] [varchar](400) NULL,
	[新开焕新方案-商业力] [varchar](400) NULL,
	[新开焕新方案-休闲力] [varchar](400) NULL,
	[新开焕新方案-医疗力] [varchar](400) NULL,
	[新开焕新方案-安全力] [varchar](400) NULL,
	[新开焕新方案-便捷力] [varchar](400) NULL,
	[新开焕新方案-舒适力] [varchar](400) NULL,
	[新开焕新方案-社群力] [varchar](400) NULL,
	[新开焕新方案-焕新力] [varchar](400) NULL,
PRIMARY KEY CLUSTERED 
(
	[本次新推价量承诺表GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


