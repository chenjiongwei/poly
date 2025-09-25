drop  table s_集团开工申请本次新推承诺表智能体数据提取
CREATE TABLE s_集团开工申请本次新推承诺表智能体数据提取 (
    本次新推量价承诺ID uniqueidentifier,
    投管代码	varchar(200),
    项目名称	varchar(200),
    推广名称	Varchar(200),
    项目GUID	uniqueidentifier,
    承诺时间	Datetime,
    类型	varchar(200),
    产品楼栋GUID	uniqueidentifier,
    产品楼栋编码	uniqueidentifier,
    产品楼栋名称	varchar(200),
    本批开工可售面积	decimal(38,10),
    本批开工货值	decimal(38,10),
    供货周期	decimal(38,10),
    去化周期	decimal(38,10),
    本批开工后的项目累计签约回笼	decimal(38,10),
    本批开工后的项目累计除地价外直投及费用	decimal(38,10),
    本批开工后的项目累计贡献现金流	decimal(38,10),
    本批开工后的一年内实现签约	decimal(38,10),
    本批开工后的一年内实现回笼	decimal(38,10),
    本批开工后的一年内除地价外直投及费用	decimal(38,10),
    本批开工后的一年内贡献现金流	decimal(38,10),
    未开工楼栋地价	decimal(38,10),
    本次开工可收回地价	decimal(38,10),
    回收股东占压资金	decimal(38,10),
    本批开工的销售均价	decimal(18,6),
    本批开工的可售单方成本	decimal(18,6),
    本批开工的税后净利润	decimal(38,10),
    本批开工的销净率	decimal(18,6),
    清洗日期	Datetime
)

-- 接口请求地址：http://172.16.8.137:8001/kg_bcxtcnb/		


SELECT [本次新推量价承诺ID]
      ,[投管代码]
      ,[项目名称]
      ,[推广名称]
      ,[项目GUID]
      ,[承诺时间]
      ,[类型]
      ,[产品楼栋GUID]
      ,[产品楼栋编码]
      ,[产品楼栋名称]
      ,[本批开工可售面积]
      ,[本批开工货值]
      ,[供货周期]
      ,[去化周期]
      ,[本批开工后的项目累计签约回笼]
      ,[本批开工后的项目累计除地价外直投及费用]
      ,[本批开工后的项目累计贡献现金流]
      ,[本批开工后的一年内实现签约]
      ,[本批开工后的一年内实现回笼]
      ,[本批开工后的一年内除地价外直投及费用]
      ,[本批开工后的一年内贡献现金流]
      ,[未开工楼栋地价]
      ,[本次开工可收回地价]
      ,[回收股东占压资金]
      ,[本批开工的销售均价]
      ,[本批开工的可售单方成本]
      ,[本批开工的税后净利润]
      ,[本批开工的销净率]
      ,[清洗日期]
  FROM [dbo].[s_集团开工申请本次新推承诺表智能体数据提取]
  WHERE DATEDIFF(DAY, 清洗日期, @ChangeDate) = 0
     AND (
            @ProjGUID IS NULL
            OR 项目GUID IN (
                SELECT [Value]
                FROM dbo.fn_Split1(@ProjGUID, ',')
            )
        )