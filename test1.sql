
    -- 利用子查询提前筛选需要的日期范围数据，减少聚合计算量，提高查询性能
    WITH FilteredSales AS (
        SELECT
            Sale.ParentProjGUID,
            Sale.BldGUID,
            Sale.StatisticalDate,
            Sale.CNetAmount,
            Sale.SpecialCNetAmount,
            Sale.CNetCount,
            Sale.SpecialCNetCount,
            Sale.CNetArea,
            Sale.SpecialCNetArea
        FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_SalesPerf Sale WITH (NOLOCK)
        WHERE 
            -- 只筛选近12个月（因为包含6, 3个月统计）
            Sale.StatisticalDate >= CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121)
    )
    SELECT 
        fs.ParentProjGUID,                             -- 父项目GUID
        pb.TopProductTypeName,                         -- 顶层产品类型名称
        pb.ProductTypeName,                            -- 产品类型名称
        pb.ZxBz,                                       -- 装修标准
        pb.CommodityType,                              -- 商品类型
        -- 近12个月签约金额（万元）: 仅统计12个月内的签约金额，非空相加，单位转换为万元
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121) AND GETDATE() 
                    THEN ISNULL(fs.CNetAmount, 0) + ISNULL(fs.SpecialCNetAmount, 0)
                ELSE 0
            END
        ) / 10000.0 AS 近十二月签约金额,          
        -- 近12个月签约套数
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetCount, 0) + ISNULL(fs.SpecialCNetCount, 0)
                ELSE 0
            END
        ) AS 近十二月签约套数,
        -- 近12个月签约面积（平方米）
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetArea, 0) + ISNULL(fs.SpecialCNetArea, 0)
                ELSE 0
            END
        ) AS 近十二月签约面积,
        -- 近三月签约金额（万元）
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetAmount, 0) + ISNULL(fs.SpecialCNetAmount, 0)
                ELSE 0
            END
        ) / 10000.0 AS 近三月签约金额,            
        -- 近三月签约套数
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetCount, 0) + ISNULL(fs.SpecialCNetCount, 0)
                ELSE 0
            END
        ) AS 近三月签约套数,
        -- 近三月签约面积（平方米）
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetArea, 0) + ISNULL(fs.SpecialCNetArea, 0)
                ELSE 0
            END
        ) AS 近三月签约面积,
        -- 近六月签约金额（万元）
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetAmount, 0) + ISNULL(fs.SpecialCNetAmount, 0)
                ELSE 0
            END
        ) / 10000.0 AS 近六月签约金额,            
        -- 近六月签约套数
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetCount, 0) + ISNULL(fs.SpecialCNetCount, 0)
                ELSE 0
            END
        ) AS 近六月签约套数,
        -- 近六月签约面积
        SUM(
            CASE 
                WHEN fs.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(fs.CNetArea, 0) + ISNULL(fs.SpecialCNetArea, 0)
                ELSE 0
            END
        ) AS 近六月签约面积
    INTO #sale  -- 将结果存入临时表#sale
    FROM FilteredSales fs
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_Building] pb WITH (NOLOCK)
            ON fs.BldGUID = pb.BuildingGUID
            AND pb.BldType = '产品楼栋'
        INNER JOIN #proj pj ON pj.项目GUID = fs.ParentProjGUID
    GROUP BY
        fs.ParentProjGUID,
        pb.TopProductTypeName,
        pb.ProductTypeName,
        pb.ZxBz,
        pb.CommodityType
