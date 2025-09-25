
drop  table  s_集团开工申请索引表智能体数据提取 
CREATE TABLE s_集团开工申请索引表智能体数据提取
(
    投管代码	Varchar(200),
    项目GUID	uniqueidentifier,
    项目名称	Varchar(200),
    推广名称    Varchar(200),
    审批单号	Varchar(200),
    审批单名称   Varchar(1000),
    存货去化承诺ID	uniqueidentifier,
    本次新推量价承诺ID	uniqueidentifier,
    是否为当前最新版	Varchar(10),
    承诺时间	datetime,
    归档时间	datetime,
    责任人	Varchar(200),
    联系电话	Varchar(200)
)




-- 接口查询脚本
SELECT [投管代码]
      ,[项目GUID]
      ,[项目名称]
      ,[推广名称]
      ,[审批单号]
      ,[审批单名称]
      ,[存货去化承诺ID]
      ,[本次新推量价承诺ID]
      ,[是否为当前最新版]
      ,[承诺时间]
      ,[归档时间]
      ,[责任人]
      ,[联系电话]
  FROM [dbo].[s_集团开工申请索引表智能体数据提取]
  where (
            @ProjGUID IS NULL
            OR 项目GUID IN (
                SELECT [Value]
                FROM dbo.fn_Split1(@ProjGUID, ',')
            )
        )