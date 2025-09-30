drop table s_集团开工申请新推量价承诺明细表智能体数据提取
create table s_集团开工申请新推量价承诺明细表智能体数据提取
(
    本次新推量价承诺ID uniqueidentifier,
    投管代码	varchar(200),
    项目名称	varchar(200),
    推广名称	varchar(200),
    项目GUID	uniqueidentifier,
    业态	varchar(200),
    产品楼栋GUID	uniqueidentifier,
    产品楼栋编码	varchar(200),
    产品楼栋名称	varchar(200),
    首开日期	Datetime,
    可售面积	decimal(38,10),
    开工货值	decimal(38,10),
    供货周期	decimal(38,10),
    去化周期	decimal(38,10),
    累计签约回笼	decimal(38,10),
    累计除地价外直投及费用	decimal(38,10),
    累计贡献现金流	decimal(38,10),
    一年内签约金额	decimal(38,10),
    一年内回笼金额	decimal(38,10),
    一年内除地价外直投及费用	decimal(38,10),
    一年内贡献现金流	decimal(38,10),
    含税签约金额	decimal(38,10),
    已售面积	decimal(38,10),
    不含税签约金额	decimal(38,10),
    清洗日期	Datetime
)


-- 接口请求地址：http://172.16.8.137:8001/kg_bcxtcnb_lj/	
SELECT [本次新推量价承诺ID]
      ,[投管代码]
      ,[项目名称]
      ,[推广名称]
      ,[项目GUID]
      ,[业态]
      ,[产品楼栋GUID]
      ,[产品楼栋编码]
      ,[产品楼栋名称]
      ,[首开日期]
      ,[可售面积]
      ,[开工货值]
      ,[供货周期]
      ,[去化周期]
      ,[累计签约回笼]
      ,[累计除地价外直投及费用]
      ,[累计贡献现金流]
      ,[一年内签约金额]
      ,[一年内回笼金额]
      ,[一年内除地价外直投及费用]
      ,[一年内贡献现金流]
      ,[含税签约金额]
      ,[已售面积]
      ,[不含税签约金额]
      ,[清洗日期]
  FROM [dbo].[s_集团开工申请新推量价承诺明细表智能体数据提取]
  WHERE DATEDIFF(DAY, 清洗日期, @ChangeDate) = 0
     AND (
            @ProjGUID IS NULL
            OR 项目GUID IN (
                SELECT [Value]
                FROM dbo.fn_Split1(@ProjGUID, ',')
            )
        )