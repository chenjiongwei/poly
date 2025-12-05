USE [dss]
GO


CREATE TABLE [dbo].[nmap_F_存货去化承诺表](
	[存货去化承诺表GUID] [uniqueidentifier] NOT NULL,
	[FillHistoryGUID] [uniqueidentifier] NULL,
	[BusinessGUID] [uniqueidentifier] NULL,
	[投管代码] [varchar](400) NULL,
	[项目GUID] [varchar](400) NULL,
	[项目名称] [varchar](400) NULL,
	[承诺时间] [datetime] NULL,
	[已开工未售部分的的产品楼栋编码] [varchar](4000) NULL,
	[已开工未售部分的的产品楼栋名称] [varchar](4000) NULL,
	[已开工未售部分的销售均价（元）] [varchar](400) NULL,
	[已开工未售部分的去化周期（月）] [varchar](400) NULL,
	[已开工未售部分的税后净利润（亿元）] [varchar](400) NULL,
	[已开工未售部分的销净率（百分比）] [varchar](400) NULL,
	[推广名称] [varchar](400) NULL,
	[存货去化承诺ID] [varchar](400) NULL,
	[历史供货周期（月）] [varchar](400) NULL,
	[户型最大产销比] [varchar](400) NULL,
	[原户型去化周期（月）] [varchar](400) NULL,
	[现户型去化周期（月）] [varchar](400) NULL,
	[存货焕新力数量] [varchar](400) NULL,
	[存货焕新方案-户型力] [varchar](400) NULL,
	[最后导入人] [varchar](400) NULL,
	[最后导入时间] [datetime] NULL,
	[公司简称] [varchar](400) NULL,
	[RowID] [int] NULL,
	[已开工未售部分的售罄时间] [datetime] NULL,
	[存货焕新方案-美学力] [varchar](400) NULL,
	[存货焕新方案-功能力] [varchar](400) NULL,
	[存货焕新方案-质量力] [varchar](400) NULL,
	[存货焕新方案-智能力] [varchar](400) NULL,
	[存货焕新方案-交通力] [varchar](400) NULL,
	[存货焕新方案-教育力] [varchar](400) NULL,
	[存货焕新方案-商业力] [varchar](400) NULL,
	[存货焕新方案-休闲力] [varchar](400) NULL,
	[存货焕新方案-医疗力] [varchar](400) NULL,
	[存货焕新方案-安全力] [varchar](400) NULL,
	[存货焕新方案-便捷力] [varchar](400) NULL,
	[存货焕新方案-舒适力] [varchar](400) NULL,
	[存货焕新方案-社群力] [varchar](400) NULL,
	[存货焕新方案-焕新力] [varchar](400) NULL,
PRIMARY KEY CLUSTERED 
(
	[存货去化承诺表GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


