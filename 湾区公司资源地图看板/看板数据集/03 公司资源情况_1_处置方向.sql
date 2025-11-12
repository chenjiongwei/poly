-- 按照业态的处置方向
select 
    t.*,
    null as '反算总货量',
    null as '反算已开工货量',
    null as '反算已售货量',
    null as '反算剩余货量',
    null as '反算存货货量',
    null as '反算在途货量',
    null as '反算未开工货量',

    null as '当前处置临时冻结合计',
    null as '当前处置其中：合作受阻',
    null as '当前处置其中：开发受限',
    null as '当前处置其中：停工缓建',
    null as '当前处置其中：投资未落实',

    null as '当前处置退换调转',
    null as '当前处置正常销售',
    null as '当前处置转经营',
    null as '尾盘',
    null as '处置后临时冻结合计',
    null as '处置后其中：合作受阻',
    null as '处置后其中：开发受限',
    null as '处置后其中：停工缓建',
    null as '处置后其中：投资未落实',
    null as '处置后退换调转',
    null as '处置后正常销售',
    null as '处置后转经营',
    null as '已开工剩余货量已推未售',
    null as '已开工剩余货量获证待推',
    null as '已开工剩余货量达形象未取证',
    null as '已开工剩余货量正常在途',
    null as '已开工剩余货量停工缓建在途',
    null as '未开工剩余货量停工缓建',
    null as '未开工剩余货量预计三年内开工',
    null as '未开工剩余货量预计三年后开工',
    null as '已竣备',
    null as '形象未达竣备',
    null as '开工未达形象',
    null as '停工缓建'
from 
    wqzydtBi_resourseinfo t
where 
    datediff(day, 清洗时间, getdate()) = 0




    delete  from  dw_s_WqBaseStatic_CompanyResource where 清洗时间id = @date_id

	select newid() as 主键, convert(varchar(10),getdate(),120) as 清洗时间, @date_id 清洗时间id, 
	 [组织架构ID], [组织架构编码], [组织架构类型], [组织架构名称],
	 反算总货值_总货值 as 反算总货量_总货值,
	 反算总货值_总面积 as 反算总货量_总面积,
	 已开工情况_已开工货值 as 反算已开工货值,
	 已开工情况_已开工面积 as 反算已开工面积,
	 反算总货值_剩余货值 as 反算剩余货量_剩余货值,
	 反算总货值_剩余面积 as 反算剩余货量_剩余面积,
     存货情况_存货货值 as 反算存货货量_存货货值,
     存货情况_存货面积 as 反算存货货量_存货面积,
	 在途情况_在途货值 as 反算在途货量_在途货值,
	 在途情况_在途面积 as 反算在途货量_在途面积,
	 未开工情况_未开工货值 as 反算未开工货量_未开工货值,
	 未开工情况_未开工面积 as 反算未开工货量_未开工面积
	 from highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_CompanyResource

     CREATE TABLE dw_s_WqBaseStatic_CompanyResource (
         主键 UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
         清洗时间 DATETIME,
         清洗时间id INT,
         组织架构ID UNIQUEIDENTIFIER,
         组织架构编码 VARCHAR(100),
         组织架构类型 INT,
         组织架构名称 VARCHAR(400),
         反算总货量_总货值 DECIMAL(38, 4),
         反算总货量_总面积 DECIMAL(38, 4),
         反算已开工货值 DECIMAL(38, 4),
         反算已开工面积 DECIMAL(38, 4),
         反算剩余货量_剩余货值 DECIMAL(38, 4),
         反算剩余货量_剩余面积 DECIMAL(38, 4),
         反算存货货量_存货货值 DECIMAL(38, 4),
         反算存货货量_存货面积 DECIMAL(38, 4),
         反算在途货量_在途货值 DECIMAL(38, 4),
         反算在途货量_在途面积 DECIMAL(38, 4),
         反算未开工货量_未开工货值 DECIMAL(38, 4),
         反算未开工货量_未开工面积 DECIMAL(38, 4)
     );




SELECT
      [OrgGUID]
      ,[平台公司]
      ,[项目名称]
      ,[项目推广名]
      ,[明源系统代码]
      ,[项目代码]
      ,[获取时间]
      ,[总地价]
      ,[是否合作项目]
      ,[分期名称]
      ,[产品楼栋名称]
      ,[SaleBldGUID]
      ,[GCBldGUID]
      ,[工程楼栋名称]
      ,[产品类型]
      ,[产品名称]
      ,[商品类型]
      ,[是否可售]
      ,[是否持有]
      ,[装修标准]
      ,[地上层数]
      ,[地下层数]
      ,[达到预售形象的条件]
      ,[实际开工计划日期]
      ,[实际开工完成日期]
      ,[达到预售形象计划日期]
      ,[达到预售形象完成日期]
      ,[预售办理计划日期]
      ,[预售办理完成日期]
      ,[竣工备案计划日期]
      ,[竣工备案完成日期]
      ,[集中交付计划日期]
      ,[集中交付完成日期]
      ,[立项均价]
      ,[立项货值]
      ,[定位均价]
      ,[定位货值]
      ,[总建面]
      ,[地上建面]
      ,[地下建面]
      ,[总可售面积]
      ,[动态总货值]
      ,[整盘均价]
      ,[已售面积]
      ,[已售货值]
      ,[已售均价]
      ,[待售面积]
      ,[待售货值]
      ,[预测单价]
      ,[年初可售面积]
      ,[年初可售货值]
      ,[本年签约面积]
      ,[本年签约金额]
      ,[本年签约均价]
      ,[本月签约面积]
      ,[本月签约金额]
      ,[本月签约均价]
      ,[本年预计签约面积]
      ,[本年预计签约金额]
      ,[正式开工实际完成时间]
      ,[正式开工预计完成时间]
      ,[待售套数]
      ,[总可售套数]
      ,[首推时间]
      ,[业态组合键]
      ,[营业成本单方]
      ,[土地款单方]
      ,[除地价外直投单方]
      ,[资本化利息单方]
      ,[开发间接费单方]
      ,[营销费用单方]
      ,[综合管理费单方]
      ,[税金及附加单方]
      ,[股权溢价单方]
      ,[总成本不含税单方]
      ,[已售对应总成本]
      ,[已售货值不含税]
      ,[已售净利润签约]
      ,[未售对应总成本]
      ,[近三月签约金额均价不含税]
      ,[近六月签约金额均价不含税]
      ,[立项单价]
      ,[定位单价]
      ,[已售均价不含税]
      ,[货量铺排均价计算方式]
      ,[未售货值不含税]
      ,[未售净利润签约]
      ,[项目已售税前利润签约]
      ,[项目未售税前利润签约]
      ,[项目整盘利润]
      ,[货值铺排均价不含税]
      ,[已售套数]
      ,[近三月签约金额不含税]
      ,[近三月签约面积]
      ,[近六月签约金额不含税]
      ,[近六月签约面积]
      ,[ztguid]
      ,[是否停工]
      ,[项目首推时间]
      ,[首开楼栋标签]
      ,[首开30天签约套数]
      ,[首开30天签约面积]
      ,[首开30天签约金额]
      ,[首开30天认购套数]
      ,[首开30天认购面积]
      ,[首开30天认购金额]
      ,[总产值]
      ,[已完成产值]
      ,[待发生产值]
      ,[合同约定应付金额]
      ,[累计支付金额]
      ,[产值未付]
      ,[应付未付]
      ,[持有套数]
      ,[业态均价]
      ,[持有面积]
      ,[土地分摊金额]
      ,[除地价外直投分摊金额]
      ,[已发生营销费用摊分金额]
      ,[已发生管理费用摊分金额]
      ,[已发生财务费用费用摊分金额]
      ,[已发生税金分摊]
      ,[已结转套数]
      ,[已结转面积]
      ,[已结转收入]
      ,[已结转成本]
      ,[签约套数2024年]
      ,[签约面积2024年]
      ,[签约金额2024年]
      ,[签约均价2024年]
      ,[经营成本单方]
      ,[赛道图标签]
      ,[占压资金]
      ,[累计回笼金额]
      ,[累计本年回笼金额]
      ,[累计本月回笼金额]
      ,[用地面积]
      ,[可售面积]
      ,[计容面积]
      ,[自持面积]
      ,[自持可售面积]
      ,[地上可售面积]
      ,[地上自持面积]
      ,[地上可售面积地上自持面积]
      ,[项目GUID]
      ,[股权比例]
      ,[所属城市]
      ,[持有货值]
      ,[反算总货值_总货值]
      ,[反算总货值_总面积]
      ,[反算总货值_剩余货值]
      ,[反算总货值_剩余面积]
      ,[已开工情况_已开工货值]
      ,[已开工情况_已开工面积]
      ,[已开工情况_已开工已售货值]
      ,[已开工情况_已开工已售面积]
      ,[已开工情况_已开工未售货值]
      ,[已开工情况_已开工未售面积]
      ,[存货情况_存货货值]
      ,[存货情况_存货面积]
      ,[自持情况_总自持资产货值]
      ,[自持情况_总自持资产面积]
      ,[自持情况_已转经营货值]
      ,[自持情况_已转经营面积]
      ,[在途情况_在途货值]
      ,[在途情况_在途面积]
      ,[未开工情况_未开工货值]
      ,[未开工情况_未开工面积]
      ,[分货转经营面积]
      ,[分货转经营金额]
      ,[分货销售面积]
      ,[分货销售金额]
      ,[是否开工]
      ,[推售状态]
      ,[竣备情况]
      ,[处置前五类]
      ,[处置后去向]
      ,[业态六分类]
  FROM [dbo].[data_wide_dws_s_WqBaseStatic_CompanyResource]
  where 组织架构类型 =7  and  平台公司='湾区公司'


 '反算总货量',
 '反算已开工货量',
 '反算已售货量',
 '反算剩余货量',
 '反算存货货量',
 '反算在途货量',
 '反算未开工货量',
 '当前处置临时冻结合计',
 '当前处置其中：合作受阻',
 '当前处置其中：开发受限',
 '当前处置其中：停工缓建',
 '当前处置其中：投资未落实',

 '当前处置退换调转',
 '当前处置正常销售',
 '当前处置转经营',
 '尾盘',
 '处置后临时冻结合计',
 '处置后其中：合作受阻',
 '处置后其中：开发受限',
 '处置后其中：停工缓建',
 '处置后其中：投资未落实',
 '处置后退换调转',
 '处置后正常销售',
 '处置后转经营',
 '已开工剩余货量已推未售',
 '已开工剩余货量获证待推',
 '已开工剩余货量达形象未取证',
 '已开工剩余货量正常在途',
 '已开工剩余货量停工缓建在途',
 '未开工剩余货量停工缓建',
 '未开工剩余货量预计三年内开工',
 '未开工剩余货量预计三年后开工',
 '已竣备',
 '形象未达竣备',
 '开工未达形象',
 '停工缓建'



反算总货值_套数
反算剩余套数
反算存货套数
反算在途套数
反算未开工套数

-- 按照业态的处置方向
select 
    t.*,
    已售  as '反算已售货量',


    null as '当前处置临时冻结合计',
    null as '当前处置其中：合作受阻',
    null as '当前处置其中：开发受限',
    null as '当前处置其中：停工缓建',
    null as '当前处置其中：投资未落实',
    null as '当前处置退换调转',
    null as '当前处置正常销售',
    null as '当前处置转经营',
    null as '尾盘',
    null as '处置后临时冻结合计',
    null as '处置后其中：合作受阻',
    null as '处置后其中：开发受限',
    null as '处置后其中：停工缓建',
    null as '处置后其中：投资未落实',
    null as '处置后退换调转',
    null as '处置后正常销售',
    null as '处置后转经营',
    null as '已开工剩余货量已推未售',
    null as '已开工剩余货量获证待推',
    null as '已开工剩余货量达形象未取证',
    null as '已开工剩余货量正常在途',
    null as '已开工剩余货量停工缓建在途',
    null as '未开工剩余货量停工缓建',
    null as '未开工剩余货量预计三年内开工',
    null as '未开工剩余货量预计三年后开工',
    null as '已竣备',
    null as '形象未达竣备',
    null as '开工未达形象',
    null as '停工缓建'
from 
    wqzydtBi_resourseinfo t
where 
    datediff(day, 清洗时间, getdate()) = 0


alter table wqzydtBi_resourseinfo add 
        反算总货量 decimal(38,4) null,
        反算已开工货量 decimal(38,4) null,
        反算剩余货量 decimal(38,4) null,
        反算存货货量 decimal(38,4) null,
        反算在途货量 decimal(38,4) null,
        反算未开工货量 decimal(38,4) null

alter table wqzydtBi_resourseinfo add 
    [反算总货量] decimal(38,4) null,
    [反算已开工货量] decimal(38,4) null,
    [反算已售货量] decimal(38,4) null,
    [反算剩余货量] decimal(38,4) null,
    [反算存货货量] decimal(38,4) null,
    [反算在途货量] decimal(38,4) null,
    [反算未开工货量] decimal(38,4) null,
    [当前处置临时冻结合计] decimal(38,4) null,
    [当前处置其中：合作受阻] decimal(38,4) null,
    [当前处置其中：开发受限] decimal(38,4) null,
    [当前处置其中：停工缓建] decimal(38,4) null,
    [当前处置其中：投资未落实] decimal(38,4) null,
    [当前处置退换调转] decimal(38,4) null,
    [当前处置正常销售] decimal(38,4) null,
    [当前处置转经营] decimal(38,4) null,
    [尾盘] decimal(38,4) null,
    [处置后临时冻结合计] decimal(38,4) null,
    [处置后其中：合作受阻] decimal(38,4) null,
    [处置后其中：开发受限] decimal(38,4) null,
    [处置后其中：停工缓建] decimal(38,4) null,
    [处置后其中：投资未落实] decimal(38,4) null,
    [处置后退换调转] decimal(38,4) null,
    [处置后正常销售] decimal(38,4) null,
    [处置后转经营] decimal(38,4) null,
    [已开工剩余货量已推未售] decimal(38,4) null,
    [已开工剩余货量获证待推] decimal(38,4) null,
    [已开工剩余货量达形象未取证] decimal(38,4) null,
    [已开工剩余货量正常在途] decimal(38,4) null,
    [已开工剩余货量停工缓建在途] decimal(38,4) null,
    [未开工剩余货量停工缓建] decimal(38,4) null,
    [未开工剩余货量预计三年内开工] decimal(38,4) null,
    [未开工剩余货量预计三年后开工] decimal(38,4) null,
    [已竣备] decimal(38,4) null,
    [形象未达竣备] decimal(38,4) null,
    [开工未达形象] decimal(38,4) null,
    [停工缓建] decimal(38,4) null




-- CREATE TABLE [dbo].[wqzydtBi_resourseinfo](
-- 	[清洗时间] [datetime] NOT NULL,
-- 	[统计维度] [varchar](4) NOT NULL,
-- 	[公司] [varchar](8) NOT NULL,
-- 	[城市] [nvarchar](256) NULL,
-- 	[片区] [nvarchar](64) NULL,
-- 	[镇街] [nvarchar](128) NULL,
-- 	[项目] [nvarchar](512) NULL,
-- 	[外键关联] [nvarchar](512) NULL,
-- 	[业态] [nvarchar](512) NULL,
-- 	[二级科目] [varchar](12) NOT NULL,
-- 	[id] [nvarchar](516) NULL,
-- 	[parentid] [nvarchar](516) NULL,
-- 	[是否加背景色] [int] NOT NULL,
-- 	[立项] [decimal](38, 4) NULL,
-- 	[定位] [decimal](38, 4) NULL,
-- 	[总货量] [decimal](38, 4) NULL,
-- 	[总货量_除3年不开工] [decimal](38, 4) NULL,
-- 	[已售] [decimal](38, 4) NULL,
-- 	[存货合计] [numeric](38, 13) NULL,
-- 	[达形象未取证剩余货量] [numeric](38, 13) NULL,
-- 	[获证待推剩余货量] [numeric](38, 13) NULL,
-- 	[已推未售] [numeric](38, 13) NULL,
-- 	[在途] [decimal](38, 4) NULL,
-- 	[未开工] [decimal](38, 4) NULL,
-- 	[预计三年内不开工] [decimal](38, 4) NULL,
-- 	[停工缓建剩余货值] [money] NULL,
-- 	[未售合计] [money] NULL,
-- 	[存货合计含停工缓建] [money] NULL,
-- 	[存货停工缓建] [money] NULL,
-- 	[在途合计] [money] NULL,
-- 	[在途停工缓建] [money] NULL,
-- 	[三年内开工] [money] NULL
-- ) ON [PRIMARY]
-- GO




-- ALTER TABLE [dbo].[wqzydtBi_resourseinfo] 
--     DROP COLUMN 
--         [反算总货量],
--         [反算已开工货量],
--         [反算已售货量],
--         [反算剩余货量],
--         [反算存货货量],
--         [反算在途货量],
--         [反算未开工货量],
--         [当前处置临时冻结合计],
--         [当前处置其中：合作受阻],
--         [当前处置其中：开发受限],
--         [当前处置其中：停工缓建],
--         [当前处置其中：投资未落实],
--         [当前处置退换调转],
--         [当前处置正常销售],
--         [当前处置转经营],
--         [尾盘],
--         [处置后临时冻结合计],
--         [处置后其中：合作受阻],
--         [处置后其中：开发受限],
--         [处置后其中：停工缓建],
--         [处置后其中：投资未落实],
--         [处置后退换调转],
--         [处置后正常销售],
--         [处置后转经营],
--         [已开工剩余货量已推未售],
--         [已开工剩余货量获证待推],
--         [已开工剩余货量达形象未取证],
--         [已开工剩余货量正常在途],
--         [已开工剩余货量停工缓建在途],
--         [未开工剩余货量停工缓建],
--         [未开工剩余货量预计三年内开工],
--         [未开工剩余货量预计三年后开工],
--         [已竣备],
--         [形象未达竣备],
--         [开工未达形象],
--         [停工缓建];

alter table dw_s_WqBaseStatic_CompanyResource add 
    处置前临时冻结面积合计 decimal(38, 4) null,
    处置前临时冻结_合作受阻冻结面积 decimal(38, 4) null,
    处置前临时冻结_开发受限冻结面积 decimal(38, 4) null,
    处置前临时冻结_停工缓建冻结面积 decimal(38, 4) null,
    处置前临时冻结_投资未落实冻结面积 decimal(38, 4) null,

    处置前临时冻结货值合计 decimal(38, 4) null,
    处置前临时冻结_合作受阻冻结货值 decimal(38, 4) null,
    处置前临时冻结_开发受限冻结货值 decimal(38, 4) null,
    处置前临时冻结_停工缓建冻结货值 decimal(38, 4) null,
    处置前临时冻结_投资未落实冻结货值 decimal(38, 4) null,

    处置前临时冻结套数合计 decimal(38, 4) null,
    处置前临时冻结_合作受阻冻结套数 decimal(38, 4) null,
    处置前临时冻结_开发受限冻结套数 decimal(38, 4) null,
    处置前临时冻结_停工缓建冻结套数 decimal(38, 4) null,
    处置前临时冻结_投资未落实冻结套数 decimal(38, 4) null,

    处置前退换调转剩余面积 decimal(38, 4) null,
    处置前退换调转剩余货值 decimal(38, 4) null,
    处置前退换调转剩余套数 decimal(38, 4) null,

    处置前正常销售剩余面积 decimal(38, 4) null,
    处置前正常销售剩余货值 decimal(38, 4) null,
    处置前正常销售剩余套数 decimal(38, 4) null,

    处置前转经营剩余面积 decimal(38, 4) null,
    处置前转经营售剩余货值 decimal(38, 4) null,
    处置前转经营剩余套数 decimal(38, 4) null,

    处置前尾盘剩余面积 decimal(38, 4) null,
    处置前尾盘剩余货值 decimal(38, 4) null,
    处置前尾盘剩余套数 decimal(38, 4) null,

    -- 处置后
    处置后临时冻结面积合计 decimal(38, 4) null,
    处置后临时冻结_合作受阻冻结面积 decimal(38, 4) null,
    处置后临时冻结_开发受限冻结面积 decimal(38, 4) null,
    处置后临时冻结_停工缓建冻结面积 decimal(38, 4) null,
    处置后临时冻结_投资未落实冻结面积 decimal(38, 4) null,

    处置后临时冻结货值合计 decimal(38, 4) null,
    处置后临时冻结_合作受阻冻结货值 decimal(38, 4) null,
    处置后临时冻结_开发受限冻结货值 decimal(38, 4) null,
    处置后临时冻结_停工缓建冻结货值 decimal(38, 4) null,
    处置后临时冻结_投资未落实冻结货值 decimal(38, 4) null,

    处置后临时冻结套数合计 decimal(38, 4) null,
    处置后临时冻结_合作受阻冻结套数 decimal(38, 4) null,
    处置后临时冻结_开发受限冻结套数 decimal(38, 4) null,
    处置后临时冻结_停工缓建冻结套数 decimal(38, 4) null,
    处置后临时冻结_投资未落实冻结套数 decimal(38, 4) null,

    处置后退换调转剩余面积 decimal(38, 4) null,
    处置后退换调转剩余货值 decimal(38, 4) null,
    处置后退换调转剩余套数 decimal(38, 4) null,

    处置后正常销售剩余面积 decimal(38, 4) null,
    处置后正常销售剩余货值 decimal(38, 4) null,
    处置后正常销售剩余套数 decimal(38, 4) null,

    处置后转经营剩余面积 decimal(38, 4) null,
    处置后转经营售剩余货值 decimal(38, 4) null,
    处置后转经营剩余套数 decimal(38, 4) null,

    处置后尾盘剩余面积 decimal(38, 4) null,
    处置后尾盘剩余货值 decimal(38, 4) null,
    处置后尾盘剩余套数 decimal(38, 4) null





alter table wqzydtBi_resourseinfo drop column 
    处置前临时冻结面积合计,
    处置前临时冻结_合作受阻冻结面积,
    处置前临时冻结_开发受限冻结面积,
    处置前临时冻结_停工缓建冻结面积,
    处置前临时冻结_投资未落实冻结面积,
    处置前临时冻结货值合计,
    处置前临时冻结_合作受阻冻结货值,
    处置前临时冻结_开发受限冻结货值,
    处置前临时冻结_停工缓建冻结货值,
    处置前临时冻结_投资未落实冻结货值,
    处置前临时冻结套数合计,
    处置前临时冻结_合作受阻冻结套数,
    处置前临时冻结_开发受限冻结套数,
    处置前临时冻结_停工缓建冻结套数,
    处置前临时冻结_投资未落实冻结套数,
    处置前退换调转剩余面积,
    处置前退换调转剩余货值,
    处置前退换调转剩余套数,
    处置前正常销售剩余面积,
    处置前正常销售剩余货值,
    处置前正常销售剩余套数,
    处置前转经营剩余面积,
    处置前转经营售剩余货值,
    处置前转经营剩余套数,
    处置前尾盘剩余面积,
    处置前尾盘剩余货值,
    处置前尾盘剩余套数,
    处置后临时冻结面积合计,
    处置后临时冻结_合作受阻冻结面积,
    处置后临时冻结_开发受限冻结面积,
    处置后临时冻结_停工缓建冻结面积,
    处置后临时冻结_投资未落实冻结面积,
    处置后临时冻结货值合计,
    处置后临时冻结_合作受阻冻结货值,
    处置后临时冻结_开发受限冻结货值,
    处置后临时冻结_停工缓建冻结货值,
    处置后临时冻结_投资未落实冻结货值,
    处置后临时冻结套数合计,
    处置后临时冻结_合作受阻冻结套数,
    处置后临时冻结_开发受限冻结套数,
    处置后临时冻结_停工缓建冻结套数,
    处置后临时冻结_投资未落实冻结套数,
    处置后退换调转剩余面积,
    处置后退换调转剩余货值,
    处置后退换调转剩余套数,
    处置后正常销售剩余面积,
    处置后正常销售剩余货值,
    处置后正常销售剩余套数,
    处置后转经营剩余面积,
    处置后转经营售剩余货值,
    处置后转经营剩余套数,
    处置后尾盘剩余面积,
    处置后尾盘剩余货值,
    处置后尾盘剩余套数;



alter table wqzydtBi_resourseinfo_area  add 
    [反算总货量] [decimal](38, 4) NULL,
	[反算已开工货量] [decimal](38, 4) NULL,
	[反算剩余货量] [decimal](38, 4) NULL,
	[反算存货货量] [decimal](38, 4) NULL,
	[反算在途货量] [decimal](38, 4) NULL,
	[反算未开工货量] [decimal](38, 4) NULL,
	[当前处置临时冻结合计] [decimal](38, 4) NULL,
	[当前处置其中：合作受阻] [decimal](38, 4) NULL,
	[当前处置其中：开发受限] [decimal](38, 4) NULL,
	[当前处置其中：停工缓建] [decimal](38, 4) NULL,
	[当前处置其中：投资未落实] [decimal](38, 4) NULL,
	[当前处置退换调转] [decimal](38, 4) NULL,
	[当前处置正常销售] [decimal](38, 4) NULL,
	[当前处置转经营] [decimal](38, 4) NULL,
	[尾盘] [decimal](38, 4) NULL,
	[处置后临时冻结合计] [decimal](38, 4) NULL,
	[处置后其中：合作受阻] [decimal](38, 4) NULL,
	[处置后其中：开发受限] [decimal](38, 4) NULL,
	[处置后其中：停工缓建] [decimal](38, 4) NULL,
	[处置后其中：投资未落实] [decimal](38, 4) NULL,
	[处置后退换调转] [decimal](38, 4) NULL,
	[处置后正常销售] [decimal](38, 4) NULL,
	[处置后转经营] [decimal](38, 4) NULL,
	[处置后尾盘] [decimal](38, 4) NULL


    -- 新增字段至dw_s_WqBaseStatic_CompanyResource表

    ALTER TABLE dw_s_WqBaseStatic_CompanyResource ADD
        已开工剩余货量_已推未售剩余面积 DECIMAL(38, 4) NULL,
        已开工剩余货量_已推未售剩余货值 DECIMAL(38, 4) NULL,
        已开工剩余货量_已推未售剩余套数 DECIMAL(38, 4) NULL,

        已开工剩余货量_获证待推剩余面积 DECIMAL(38, 4) NULL,
        已开工剩余货量_获证待推剩余货值 DECIMAL(38, 4) NULL,
        已开工剩余货量_获证待推剩余套数 DECIMAL(38, 4) NULL,
        
        已开工剩余货量_达形象未取证剩余面积 DECIMAL(38, 4) NULL,
        已开工剩余货量_达形象未取证剩余货值 DECIMAL(38, 4) NULL,
        已开工剩余货量_达形象未取证剩余套数 DECIMAL(38, 4) NULL,
         
        已开工剩余货量_正常在途剩余面积 DECIMAL(38, 4) NULL,
        已开工剩余货量_正常在途剩余货值 DECIMAL(38, 4) NULL,
        已开工剩余货量_正常在途剩余套数 DECIMAL(38, 4) NULL,

        已开工剩余货量_停工缓建在途剩余面积 DECIMAL(38, 4) NULL,
        已开工剩余货量_停工缓建在途剩余货值 DECIMAL(38, 4) NULL,
        已开工剩余货量_停工缓建在途剩余套数 DECIMAL(38, 4) NULL,

        未开工剩余货量_停工缓建剩余面积 DECIMAL(38, 4) NULL,
        未开工剩余货量_停工缓建剩余货值 DECIMAL(38, 4) NULL,
        未开工剩余货量_停工缓建剩余套数 DECIMAL(38, 4) NULL,

        未开工剩余货量_预计三年内开工剩余面积 DECIMAL(38, 4) NULL,
        未开工剩余货量_预计三年内开工剩余货值 DECIMAL(38, 4) NULL,
        未开工剩余货量_预计三年内开工剩余套数 DECIMAL(38, 4) NULL,

        未开工剩余货量_预计三年后开工剩余面积 DECIMAL(38, 4) NULL,
        未开工剩余货量_预计三年后开工剩余货值 DECIMAL(38, 4) NULL,
        未开工剩余货量_预计三年后开工剩余套数 DECIMAL(38, 4) NULL;




        ALTER TABLE wqzydtBi_resourseinfo ADD
            [已开工剩余货量已推未售] DECIMAL(38, 4) NULL,
            [已开工剩余货量获证待推] DECIMAL(38, 4) NULL,
            [已开工剩余货量达形象未取证] DECIMAL(38, 4) NULL,
            [已开工剩余货量正常在途] DECIMAL(38, 4) NULL,
            [已开工剩余货量停工缓建在途] DECIMAL(38, 4) NULL,
            [未开工剩余货量停工缓建] DECIMAL(38, 4) NULL,
            [未开工剩余货量预计三年内开工] DECIMAL(38, 4) NULL,
            [未开工剩余货量预计三年后开工] DECIMAL(38, 4) NULL;


ALTER TABLE wqzydtBi_resourseinfo ADD
    [已竣备] DECIMAL(38, 4) NULL,
    [形象未达竣备] DECIMAL(38, 4) NULL,
    [开工未达形象] DECIMAL(38, 4) NULL,
    [停工缓建] DECIMAL(38, 4) NULL


ALTER TABLE dw_s_WqBaseStatic_CompanyResource ADD
    建设状态_已竣备剩余面积 DECIMAL(38, 4) NULL,
    建设状态_已竣备剩余货值 DECIMAL(38, 4) NULL,
    建设状态_已竣备剩余套数 DECIMAL(38, 4) NULL,

    建设状态_已达形象未达竣备剩余面积 DECIMAL(38, 4) NULL,
    建设状态_已达形象未达竣备剩余货值 DECIMAL(38, 4) NULL,
    建设状态_已达形象未达竣备剩余套数 DECIMAL(38, 4) NULL,

    建设状态_已开工未达形象剩余面积 DECIMAL(38, 4) NULL,
    建设状态_已开工未达形象剩余货值 DECIMAL(38, 4) NULL,
    建设状态_已开工未达形象剩余套数 DECIMAL(38, 4) NULL,

    建设状态_停工缓建剩余面积 DECIMAL(38, 4) NULL,
    建设状态_停工缓建剩余货值 DECIMAL(38, 4) NULL,
    建设状态_停工缓建剩余套数 DECIMAL(38, 4) NULL;

    FROM highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_CompanyResource



ALTER TABLE wqzydtBi_resourseinfo_area ADD
    [已竣备] DECIMAL(38, 4) NULL,
    [形象未达竣备] DECIMAL(38, 4) NULL,
    [开工未达形象] DECIMAL(38, 4) NULL,
    [停工缓建] DECIMAL(38, 4) NULL