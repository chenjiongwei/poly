USE [ERP25]
GO

/*********************************************************************
 功能：盈利规划楼栋签约数据产品维度调用接口，传递项目分期GUID，返回产品楼栋签约表（产品维度）
 示例：exec usp_ylgh_ProjProductContractInfo '18409189-6E34-EF11-B3A4-F40270D39969','2025-09'
 exec usp_ylgh_ProjProductContractInfo '7e0636d1-b649-eb11-b398-f40270d39969', '2025-10'

 usp_ylgh_ProjProductContractInfo  'fbf40d1f-baae-ea11-80b8-0a94ef7517dd','2025-10'
 -- 18409189-6E34-EF11-B3A4-F40270D39969 -- 合肥龙川瑧悦
**********************************************************************/
Create or  ALTER  PROC [dbo].[usp_ylgh_ProjProductContractInfo]
(
    @var_projguid VARCHAR(MAX),  -- 项目GUID，多个项目用逗号分隔
    @var_tqrq varchar(7)  -- 统计截止月份，格式如YYYY-MM
)
AS
BEGIN

	SET NOCOUNT ON;  -- 禁止显示受影响的行数信息
    -- declare  @tqrq datetime =convert(datetime,@var_tqrq+'-01');

    -- 1. 创建临时表用于存放楼栋维度的签约数据
    CREATE TABLE #ylgh_ProjBLdContractInfo
    (
        [项目名称]                  VARCHAR(200),
        [项目GUID]                  UNIQUEIDENTIFIER,
        [分期名称]                  VARCHAR(200),
        [分期GUID]                  UNIQUEIDENTIFIER,
        [产品楼栋名称]              VARCHAR(200),
        [产品楼栋GUID]              UNIQUEIDENTIFIER,
        [产品类型]                  VARCHAR(50),
        [产品名称]                  VARCHAR(50),
        [经营属性]                  VARCHAR(20),
        [是否车位]                  VARCHAR(20),
        [套数]                      INT,
        [年份]                      INT,
        [月份]                      INT,
        [年月]                      VARCHAR(7),


        [本月销售面积（签约）]     DECIMAL(32, 8),
        [本月销售金额（签约）]      DECIMAL(32, 8),
        [本月销售均价（签约）]      DECIMAL(32, 8),
        [本月签约套数]       DECIMAL(32, 8)
    )

    -- 2. 调用楼栋维度的签约数据存储过程，将结果插入临时表
    INSERT INTO #ylgh_ProjBLdContractInfo 
    EXEC usp_ylgh_ProjBLdContractInfo @var_projguid,@var_tqrq

    -- 3. 按产品维度进行汇总查询
    SELECT 
        项目名称,
        LOWER(项目GUID) AS 项目GUID,
        分期名称,
        LOWER(分期GUID) AS 分期GUID,
        产品类型,
        产品名称,
        经营属性,
        是否车位,
        套数,
        年份,
        月份,
        年月,
        SUM(ISNULL([本月销售面积（签约）], 0)) AS [本月销售面积（签约）],
        SUM(ISNULL([本月销售金额（签约）], 0)) AS [本月销售金额（签约）], 
        CASE
        WHEN SUM(ISNULL([本月销售面积（签约）], 0)) = 0 THEN 0
        ELSE SUM(ISNULL([本月销售金额（签约）], 0)) / SUM(ISNULL([本月销售面积（签约）], 0))
        END AS [本月销售均价（签约）], -- 等于“本月销售金额（签约）”/“本月销售面积（签约）”
        SUM(ISNULL([本月签约套数], 0)) AS [本月签约套数]    
    FROM #ylgh_ProjBLdContractInfo 
    -- 可根据需要添加筛选条件
    -- WHERE 年份 < YEAR(@var_tqrq) OR (年份 = YEAR(@var_tqrq) AND 月份 <= MONTH(@var_tqrq))
    GROUP BY 
        项目名称,
        LOWER(项目GUID) ,
        分期名称,
        LOWER(分期GUID) ,
        产品类型,
        产品名称,
        经营属性,
        是否车位,
        套数,
        年份,
        月份,
        年月

    -- 4. 删除临时表，释放资源
    DROP TABLE #ylgh_ProjBLdContractInfo
END
