
drop  table s_集团开工申请存货去化承诺跟踪明细表智能体数据提取
CREATE TABLE s_集团开工申请存货去化承诺跟踪明细表智能体数据提取
(
    存货去化承诺ID uniqueidentifier,
    投管代码	Varchar(200),
    项目GUID	uniqueidentifier,
    项目名称	Varchar(200),
    推广名称  Varchar(200),
    业态	Varchar(200),
    已开工未售部分的的产品楼栋编码	Varchar(max),
    已开工未售部分的的产品楼栋名称	Varchar(max),
    承诺日	Varchar(20),
    售罄日	Varchar(20),
    存货去化周期	Varchar(20),
    承诺日累计签约面积	decimal(38,10),
    承诺日累计签约金额	decimal(38,10),
    承诺日累计签约面积_动态版	decimal(38,10),
    承诺日累计签约金额_动态版	decimal(38,10),
    承诺日累计签约金额不含税_动态版 decimal(38,10),
    承诺后累计含税签约面积	decimal(38,10),
    承诺后累计含税签约金额	decimal(38,10),
    承诺日不含税签约金额	decimal(38,10),
    承诺后累计不含税签约金额	decimal(38,10),
    清洗日期	Datetime
)

-- 接口清单
SELECT [存货去化承诺ID]
      ,[投管代码]
      ,[项目GUID]
      ,[项目名称]
      ,[推广名称]
      ,[业态]
      ,[已开工未售部分的的产品楼栋编码]
      ,[已开工未售部分的的产品楼栋名称]
      ,[承诺日]
      ,[售罄日]
      ,[存货去化周期]
      ,[承诺日累计签约面积]
      ,[承诺日累计签约金额]
      ,[承诺日累计签约面积_动态版]
      ,[承诺日累计签约金额_动态版]
      ,[承诺日累计签约金额不含税_动态版]
      ,[承诺后累计含税签约面积]
      ,[承诺后累计含税签约金额]
      ,[承诺日不含税签约金额]
      ,[承诺后累计不含税签约金额]
      ,[清洗日期]
  FROM [dbo].[s_集团开工申请存货去化承诺跟踪明细表智能体数据提取]
  WHERE DATEDIFF(DAY, 清洗日期, @ChangeDate) = 0
     AND (
            @ProjGUID IS NULL
            OR 项目GUID IN (
                SELECT [Value]
                FROM dbo.fn_Split1(@ProjGUID, ',')
            )
        )