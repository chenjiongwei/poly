use erp25
go

/*********************************************************************
 功能：盈利规划楼栋签约数据产品维度调用接口，传递项目分期GUID，返回产品楼栋签约表（产品维度）
 示例：exec usp_ylgh_ProjProductContractInfo '18409189-6E34-EF11-B3A4-F40270D39969','2025-09'
 -- 18409189-6E34-EF11-B3A4-F40270D39969 -- 合肥龙川瑧悦
**********************************************************************/

create or  ALTER   PROC [dbo].[usp_ylgh_ProjProductContractInfo]
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

        [去年及之前销售面积（签约）]      DECIMAL(32, 8),
        [去年及之前销售金额（签约）]      DECIMAL(32, 8),
        [去年及之前销售均价（签约）]      DECIMAL(32, 8),
        [去年及之前签约套数]            INT,

        [本年1月销售面积（签约）]        DECIMAL(32, 8),
        [本年2月销售面积（签约）]        DECIMAL(32, 8),
        [本年3月销售面积（签约）]        DECIMAL(32, 8),
        [本年4月销售面积（签约）]        DECIMAL(32, 8),
        [本年5月销售面积（签约）]        DECIMAL(32, 8),
        [本年6月销售面积（签约）]        DECIMAL(32, 8),
        [本年7月销售面积（签约）]        DECIMAL(32, 8),
        [本年8月销售面积（签约）]        DECIMAL(32, 8),
        [本年9月销售面积（签约）]        DECIMAL(32, 8),
        [本年10月销售面积（签约）]       DECIMAL(32, 8),
        [本年11月销售面积（签约）]       DECIMAL(32, 8),
        [本年12月销售面积（签约）]       DECIMAL(32, 8),

        [本年1月销售金额（签约）]        DECIMAL(32, 8),
        [本年2月销售金额（签约）]        DECIMAL(32, 8),
        [本年3月销售金额（签约）]        DECIMAL(32, 8),
        [本年4月销售金额（签约）]        DECIMAL(32, 8),
        [本年5月销售金额（签约）]        DECIMAL(32, 8),
        [本年6月销售金额（签约）]        DECIMAL(32, 8),
        [本年7月销售金额（签约）]        DECIMAL(32, 8),
        [本年8月销售金额（签约）]        DECIMAL(32, 8),
        [本年9月销售金额（签约）]        DECIMAL(32, 8),
        [本年10月销售金额（签约）]       DECIMAL(32, 8),
        [本年11月销售金额（签约）]       DECIMAL(32, 8),
        [本年12月销售金额（签约）]       DECIMAL(32, 8),

        [本年1月销售均价（签约）]        DECIMAL(32, 8),
        [本年2月销售均价（签约）]        DECIMAL(32, 8),
        [本年3月销售均价（签约）]        DECIMAL(32, 8),
        [本年4月销售均价（签约）]        DECIMAL(32, 8),
        [本年5月销售均价（签约）]        DECIMAL(32, 8),
        [本年6月销售均价（签约）]        DECIMAL(32, 8),
        [本年7月销售均价（签约）]        DECIMAL(32, 8),
        [本年8月销售均价（签约）]        DECIMAL(32, 8),
        [本年9月销售均价（签约）]        DECIMAL(32, 8),
        [本年10月销售均价（签约）]       DECIMAL(32, 8),
        [本年11月销售均价（签约）]       DECIMAL(32, 8),
        [本年12月销售均价（签约）]       DECIMAL(32, 8),

        [本年1月签约套数]                INT,
        [本年2月签约套数]                INT,
        [本年3月签约套数]                INT,
        [本年4月签约套数]                INT,
        [本年5月签约套数]                INT,
        [本年6月签约套数]                INT,
        [本年7月签约套数]                INT,
        [本年8月签约套数]                INT,
        [本年9月签约套数]                INT,
        [本年10月签约套数]               INT,
        [本年11月签约套数]               INT,
        [本年12月签约套数]               INT
    )



    -- 2. 调用楼栋维度的签约数据存储过程，将结果插入临时表
    INSERT INTO #ylgh_ProjBLdContractInfo 
    EXEC usp_ylgh_ProjBLdContractInfo @var_projguid,@var_tqrq

    -- 3. 按产品维度进行汇总查询
    SELECT 
        项目名称,
        项目GUID,
        分期名称,
        分期GUID,
        产品类型,
        经营属性,
        是否车位,
        SUM(ISNULL(套数, 0)) AS 套数,

        SUM(ISNULL([去年及之前销售面积（签约）], 0)) AS [去年及之前销售面积（签约）],
        SUM(ISNULL([去年及之前销售金额（签约）], 0)) AS [去年及之前销售金额（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([去年及之前签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([去年及之前销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([去年及之前签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([去年及之前销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([去年及之前销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([去年及之前销售面积（签约）], 0)), 0)
                END
        END AS [去年及之前销售均价（签约）],
        SUM(ISNULL([去年及之前签约套数], 0)) AS [去年及之前签约套数],

        -- 本年各月销售面积（签约）
        SUM(ISNULL([本年1月销售面积（签约）], 0)) AS [本年1月销售面积（签约）],
        SUM(ISNULL([本年2月销售面积（签约）], 0)) AS [本年2月销售面积（签约）],
        SUM(ISNULL([本年3月销售面积（签约）], 0)) AS [本年3月销售面积（签约）],
        SUM(ISNULL([本年4月销售面积（签约）], 0)) AS [本年4月销售面积（签约）],
        SUM(ISNULL([本年5月销售面积（签约）], 0)) AS [本年5月销售面积（签约）],
        SUM(ISNULL([本年6月销售面积（签约）], 0)) AS [本年6月销售面积（签约）],
        SUM(ISNULL([本年7月销售面积（签约）], 0)) AS [本年7月销售面积（签约）],
        SUM(ISNULL([本年8月销售面积（签约）], 0)) AS [本年8月销售面积（签约）],
        SUM(ISNULL([本年9月销售面积（签约）], 0)) AS [本年9月销售面积（签约）],
        SUM(ISNULL([本年10月销售面积（签约）], 0)) AS [本年10月销售面积（签约）],
        SUM(ISNULL([本年11月销售面积（签约）], 0)) AS [本年11月销售面积（签约）],
        SUM(ISNULL([本年12月销售面积（签约）], 0)) AS [本年12月销售面积（签约）],

        -- 本年各月销售金额（签约）
        SUM(ISNULL([本年1月销售金额（签约）], 0)) AS [本年1月销售金额（签约）],
        SUM(ISNULL([本年2月销售金额（签约）], 0)) AS [本年2月销售金额（签约）],
        SUM(ISNULL([本年3月销售金额（签约）], 0)) AS [本年3月销售金额（签约）],
        SUM(ISNULL([本年4月销售金额（签约）], 0)) AS [本年4月销售金额（签约）],
        SUM(ISNULL([本年5月销售金额（签约）], 0)) AS [本年5月销售金额（签约）],
        SUM(ISNULL([本年6月销售金额（签约）], 0)) AS [本年6月销售金额（签约）],
        SUM(ISNULL([本年7月销售金额（签约）], 0)) AS [本年7月销售金额（签约）],
        SUM(ISNULL([本年8月销售金额（签约）], 0)) AS [本年8月销售金额（签约）],
        SUM(ISNULL([本年9月销售金额（签约）], 0)) AS [本年9月销售金额（签约）],
        SUM(ISNULL([本年10月销售金额（签约）], 0)) AS [本年10月销售金额（签约）],
        SUM(ISNULL([本年11月销售金额（签约）], 0)) AS [本年11月销售金额（签约）],
        SUM(ISNULL([本年12月销售金额（签约）], 0)) AS [本年12月销售金额（签约）],

        -- 本年各月销售均价（签约）
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年1月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年1月销售金额（签约）], 0)) *10000.0 / NULLIF(SUM(ISNULL([本年1月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年1月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年1月销售金额（签约）], 0)) *10000.0 / NULLIF(SUM(ISNULL([本年1月销售面积（签约）], 0)), 0)
                END
        END AS [本年1月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年2月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年2月销售金额（签约）], 0)) *10000.0 / NULLIF(SUM(ISNULL([本年2月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年2月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年2月销售金额（签约）], 0)) *10000.0 / NULLIF(SUM(ISNULL([本年2月销售面积（签约）], 0)), 0)
                END
        END AS [本年2月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年3月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年3月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年3月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年3月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年3月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年3月销售面积（签约）], 0)), 0)
                END
        END AS [本年3月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年4月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年4月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年4月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年4月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年4月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年4月销售面积（签约）], 0)), 0)
                END
        END AS [本年4月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年5月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年5月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年5月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年5月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年5月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年5月销售面积（签约）], 0)), 0)
                END
        END AS [本年5月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年6月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年6月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年6月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年6月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年6月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年6月销售面积（签约）], 0)), 0)
                END
        END AS [本年6月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年7月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年7月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年7月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年7月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年7月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年7月销售面积（签约）], 0)), 0)
                END
        END AS [本年7月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年8月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年8月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年8月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年8月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年8月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年8月销售面积（签约）], 0)), 0)
                END
        END AS [本年8月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年9月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年9月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年9月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年9月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年9月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年9月销售面积（签约）], 0)), 0)
                END
        END AS [本年9月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年10月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年10月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年10月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年10月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年10月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年10月销售面积（签约）], 0)), 0)
                END
        END AS [本年10月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年11月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年11月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年11月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年11月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年11月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年11月销售面积（签约）], 0)), 0)
                END
        END AS [本年11月销售均价（签约）],
        CASE 
            WHEN 产品类型 = '地下室/车库' THEN
                CASE WHEN SUM(ISNULL([本年12月签约套数], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年12月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年12月签约套数], 0)), 0)
                END
            ELSE
                CASE WHEN SUM(ISNULL([本年12月销售面积（签约）], 0)) = 0 THEN 0
                     ELSE SUM(ISNULL([本年12月销售金额（签约）], 0)) *10000.0/ NULLIF(SUM(ISNULL([本年12月销售面积（签约）], 0)), 0)
                END
        END AS [本年12月销售均价（签约）],

        -- 本年各月签约套数
        SUM(ISNULL([本年1月签约套数], 0)) AS [本年1月签约套数],
        SUM(ISNULL([本年2月签约套数], 0)) AS [本年2月签约套数],
        SUM(ISNULL([本年3月签约套数], 0)) AS [本年3月签约套数],
        SUM(ISNULL([本年4月签约套数], 0)) AS [本年4月签约套数],
        SUM(ISNULL([本年5月签约套数], 0)) AS [本年5月签约套数],
        SUM(ISNULL([本年6月签约套数], 0)) AS [本年6月签约套数],
        SUM(ISNULL([本年7月签约套数], 0)) AS [本年7月签约套数],
        SUM(ISNULL([本年8月签约套数], 0)) AS [本年8月签约套数],
        SUM(ISNULL([本年9月签约套数], 0)) AS [本年9月签约套数],
        SUM(ISNULL([本年10月签约套数], 0)) AS [本年10月签约套数],
        SUM(ISNULL([本年11月签约套数], 0)) AS [本年11月签约套数],
        SUM(ISNULL([本年12月签约套数], 0)) AS [本年12月签约套数]

    FROM #ylgh_ProjBLdContractInfo 
    -- 可根据需要添加筛选条件
    -- WHERE 年份 < YEAR(@var_tqrq) OR (年份 = YEAR(@var_tqrq) AND 月份 <= MONTH(@var_tqrq))
    GROUP BY 
        项目名称,
        项目GUID,
        分期名称,
        分期GUID,
        产品类型,
        经营属性,
        是否车位

    -- 4. 删除临时表，释放资源
    DROP TABLE #ylgh_ProjBLdContractInfo
END
