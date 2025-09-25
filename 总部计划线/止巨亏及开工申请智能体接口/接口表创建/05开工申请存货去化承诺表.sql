-- 新开工去化承诺表
drop  table s_集团开工申请存货去化承诺智能体数据提取 
CREATE TABLE s_集团开工申请存货去化承诺智能体数据提取
(
    存货去化承诺ID uniqueidentifier,   
    投管代码	Varchar(200),
    项目GUID	uniqueidentifier,
    项目名称	Varchar(200),
    推广名称   Varchar(200),
    承诺时间	Datetime,
    类型	Varchar(200),
    已开工未售部分的的产品楼栋编码	Varchar(max),
    已开工未售部分的的产品楼栋名称	Varchar(max),
    已开工未售部分的售罄时间	Varchar(20),
    已开工未售部分的销售均价	decimal(18,6),
    已开工未售部分的去化周期	decimal(18,6),
    已开工未售部分的税后净利润	decimal(38,10),
    已开工未售部分的销净率	decimal(18,6),
    清洗日期	Datetime
)


-- 接口查询
SELECT [存货去化承诺ID]
      ,[投管代码]
      ,[项目GUID]
      ,[项目名称]
      ,[推广名称]
      ,[承诺时间]
      ,[类型]
      ,[已开工未售部分的的产品楼栋编码]
      ,[已开工未售部分的的产品楼栋名称]
      ,[已开工未售部分的售罄时间]
      ,[已开工未售部分的销售均价]
      ,[已开工未售部分的去化周期]
      ,[已开工未售部分的税后净利润]
      ,[已开工未售部分的销净率]
      ,[清洗日期]
  FROM [dbo].[s_集团开工申请存货去化承诺智能体数据提取]
  WHERE DATEDIFF(DAY, 清洗日期, @ChangeDate) = 0
     AND (
            @ProjGUID IS NULL
            OR 项目GUID IN (
                SELECT [Value]
                FROM dbo.fn_Split1(@ProjGUID, ',')
            )
        )