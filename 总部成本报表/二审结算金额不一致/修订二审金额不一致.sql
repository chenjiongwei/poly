-- 修订：二审金额和结转金额 同二审结转工作流审批单上不一致的情况

-- 查询需要修订的合同结算单据
select
    b.* 
into cb_HTBalance_bak20250724
from
    cb_contract a
inner  join cb_HTBalance  b on a.contractguid =b.contractguid
where
    a.contractcode in (
        '赣州市经开区金坪130-131地块合20220033',
        '青云谱时光印象合20200003',
        '沈阳市沈抚新区沈中线东侧3号地块合20230039',
        '抚州文化综合体项目合20200136',
        '海西公司-龙岩市新罗区龙腾北路2021拍-2号地块-2021-0033',
        '佛山市顺德区陈村阅江台东侧034号地块-工程施工类-土建工程类-2024-0079',
        '舟山市定海区舟山新城体育路[2021]02号地块合2022-0012',
        '海西公司-晋江中航城-2025-0269'
    )

-- 修改合同结算单据上的结算金额和二审金额
select 
    a.HTBalanceGUID,
    a.EsAmountBz, -- 二审金额含税
    a.ExcludingTaxEsAmountBz, -- 二审金额不含税
    a.InputTaxEsAmountBz, -- 二审进项税额
    a.BalanceAmount_Bz, --结算金额含税
    a.ExcludingTaxBalanceAmount_Bz, --结算金额不含税
    a.InputTaxBalanceAmount_Bz -- 结算进项税额
from cb_HTBalance  a
inner join cb_HTBalance_bak20250724 b on a.HTBalanceGUID = b.HTBalanceGUID


-- CREATE TABLE [dbo].[待处理结算](
-- 	[公司名称] [nvarchar](255) NULL,
-- 	[合同名称] [nvarchar](255) NULL,
-- 	[合同编号] [nvarchar](255) NULL,
-- 	[结算类型] [nvarchar](255) NULL,
-- 	[结算日期] [datetime] NULL,
-- 	[结算金额] [float] NULL,
-- 	[二审结算金额] [float] NULL,
-- 	[表单_二审金额（含税）] [float] NULL,
-- 	[合同结算调整流程名称] [nvarchar](255) NULL,
-- 	[表单_调整后结算金额（含税）] [nvarchar](255) NULL,
-- 	[合同实付金额] [float] NULL,
-- 	[二审金额同流程表单是否一致] [nvarchar](255) NULL,
-- 	[结算调整金额是否通过结算金额一致] [nvarchar](255) NULL
-- ) ON [PRIMARY]

-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'南昌公司', N'赣州市保利天汇项目一期三标段住宅户内及公共区域精装修工程承包合同', N'赣州市经开区金坪130-131地块合20220033', N'结算', CAST(N'2025-04-22 00:00:00.000' AS DateTime), 14983347.1, 0, 14795223.52, N'', N'', 12518818.54, N'否', N'无调整')
-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'南昌公司', N'南昌青云谱区022地块全过程造价咨询工程', N'青云谱时光印象合20200003', N'结算', CAST(N'2025-05-14 00:00:00.000' AS DateTime), 787355.58, 0, 786111.97, N'', N'', 762732, N'否', N'无调整')
-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'东北公司', N'保利城一期项目自维及柴发低压返出设计合同', N'沈阳市沈抚新区沈中线东侧3号地块合20230039', N'结算', CAST(N'2025-05-16 00:00:00.000' AS DateTime), 119920.96, 0, 11920.96, N'', N'', 119920.96, N'否', N'无调整')
-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'南昌公司', N'抚州保利华章学府香颂S2地块项目铝合金门窗及百叶制作安装工程合同', N'抚州文化综合体项目合20200136', N'结算', CAST(N'2025-05-21 00:00:00.000' AS DateTime), 1752979.41, 0, 1751206.13, N'', N'', 1464000, N'否', N'无调整')
-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'海西公司', N'龙岩保利和院项目展示区园林工程', N'海西公司-龙岩市新罗区龙腾北路2021拍-2号地块-2021-0033', N'结算', CAST(N'2025-05-26 00:00:00.000' AS DateTime), 6550868.26, 0, 6531772.21, N'', N'', 6248296.62, N'否', N'无调整')
-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'华南公司', N'佛山市保利阅江台江缦项目首开会所、下沉庭院幕墙工程施工承包合同', N'佛山市顺德区陈村阅江台东侧034号地块-工程施工类-土建工程类-2024-0079', N'结算', CAST(N'2025-05-26 00:00:00.000' AS DateTime), 4042362.02, 0, 4008539.17, N'', N'', 3863732.01, N'否', N'无调整')
-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'浙江公司', N'舟山市锦上府项目大区（一标）精装修工程承包合同', N'舟山市定海区舟山新城体育路[2021]02号地块合2022-0012', N'结算', CAST(N'2025-06-10 00:00:00.000' AS DateTime), 18656120.85, 0, 18621657.81, N'', N'', 15979736.21, N'否', N'无调整')
-- GO
-- INSERT [dbo].[待处理结算] ([公司名称], [合同名称], [合同编号], [结算类型], [结算日期], [结算金额], [二审结算金额], [表单_二审金额（含税）], [合同结算调整流程名称], [表单_调整后结算金额（含税）], [合同实付金额], [二审金额同流程表单是否一致], [结算调整金额是否通过结算金额一致]) VALUES (N'海西公司', N'中航城．天玺别墅展示区（9-A、9-B、10-A、10-B）外墙石材供货及安装工程', N'海西公司-晋江中航城-2025-0269', N'结算', CAST(N'2025-06-18 00:00:00.000' AS DateTime), 2923888.47, NULL, 2491245.89, N'', N'', NULL, N'否', N'无调整')
-- GO


select 
    a.HTBalanceGUID,
    a.AverageTaxRate, -- 综合税率
    df.[表单_二审金额（含税）],
    df.[表单_二审金额（含税）] / (1+a.AverageTaxRate/100.0) as 表单_二审金额不含税,
    df.[表单_二审金额（含税）] / (1+a.AverageTaxRate/100.0) * a.AverageTaxRate/100.0 as 表单_二审进项税额,

    a.EsAmountBz, -- 二审金额含税
    a.ExcludingTaxEsAmountBz, -- 二审金额不含税
    a.InputTaxEsAmountBz, -- 二审进项税额
    a.BalanceAmount_Bz, --结算金额含税
    a.ExcludingTaxBalanceAmount_Bz, --结算金额不含税
    a.InputTaxBalanceAmount_Bz -- 结算进项税额
from cb_HTBalance  a
inner join cb_HTBalance_bak20250724 b on a.HTBalanceGUID = b.HTBalanceGUID
inner join cb_contract c on c.contractguid = a.contractguid
inner join  [待处理结算] df on df.合同编号 =c.contractcode

-- 修改数据
update a 
   set  a.EsAmountBz =df.[表单_二审金额（含税）] , -- 二审金额含税
        a.ExcludingTaxEsAmountBz = df.[表单_二审金额（含税）] / (1+a.AverageTaxRate/100.0)  , -- 二审金额不含税
        a.InputTaxEsAmountBz= df.[表单_二审金额（含税）] / (1+a.AverageTaxRate/100.0) * a.AverageTaxRate/100.0 , -- 二审进项税额
        a.BalanceAmount_Bz =df.[表单_二审金额（含税）], --结算金额含税
        a.ExcludingTaxBalanceAmount_Bz = df.[表单_二审金额（含税）] / (1+a.AverageTaxRate/100.0) , --结算金额不含税
        a.InputTaxBalanceAmount_Bz =df.[表单_二审金额（含税）] / (1+a.AverageTaxRate/100.0) * a.AverageTaxRate/100.0 -- 结算进项税额
from cb_HTBalance  a
inner join cb_HTBalance_bak20250724 b on a.HTBalanceGUID = b.HTBalanceGUID
inner join cb_contract c on c.contractguid = a.contractguid
inner join  [待处理结算] df on df.合同编号 =c.contractcode



