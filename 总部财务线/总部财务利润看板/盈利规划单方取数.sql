USE [dss]
GO

CREATE OR ALTER PROC [dbo].[usp_s_F066项目毛利率销售底表_盈利规划单方锁定板_清洗] 
(
    @ylghbb varchar(50) = '2024年四季度集团表1' -- 盈利规划锁定版本
)
AS
/*
create by chenjw
date 20250530
功能：取盈利规划年初落盘锁定版本的单方数据，用于动态利润计算，按照盈利规划单方等比例缩放
*/
BEGIN
--------------------------------------------------项目层级单方取数 begin--------------------------------------

    --declare @ylghbb varchar(50) = '2024年四季度集团表1' -- 盈利规划锁定版本
    --获取盈利规划业态基础信息
    SELECT DISTINCT
        do.DevelopmentCompanyGUID AS 公司Guid,
        do.OrganizationName AS 公司名称,
        pj.ProjGUID AS 项目Guid,
        pj.SpreadName AS 项目推广名,
        pj1.ProjCode AS 项目代码,
        pj.TgProjCode AS 项目投管代码,
        p.edition as 盈利规划版本,
        p.BusinessEdition as 盈利规划业务版本,
        pj1.Ylghsxfs AS 盈利规划上线方式,
        pr.TopProductTypeName 产品类型,
        SUBSTRING(YtName, 0, CHARINDEX('_', YtName)) 产品名称,
        SUBSTRING(
            SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100),
            CHARINDEX('_', SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100)) + 1,
            100
        ) 装修标准,
        SUBSTRING(
            SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100),
            0,
            CHARINDEX('_', SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100))
        ) 商品类型,
        isnull(pj1.ProjCode,'') + '_' + isnull(pr.TopProductTypeName,'') + '_' + isnull(yt.YtName,'') 匹配主键,
        yt.YtName
    INTO #base
    FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SumProjProductYt yt
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID p
            ON p.YLGHProjGUID = yt.ProjGUID
            AND p.edition = @ylghbb
            AND p.BusinessEdition = yt.BusinessEdition
            AND p.Level = 3
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Project pj
            ON p.ProjGUID = pj.ProjGUID
        INNER JOIN ERP25.dbo.mdm_Project pj1
            ON pj1.ProjGUID = pj.ProjGUID
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_Dimension_Organization do
            ON pj.BUGUID = do.OrgGUID
        LEFT JOIN (
            SELECT 
                ProductTypeName,
                TopProductTypeName,
                ROW_NUMBER() OVER (PARTITION BY pr.ProductTypeName ORDER BY ProductTypeName) AS num
            FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Product pr
        ) pr ON pr.num = 1 AND pr.ProductTypeName = yt.ProductType
    WHERE 1=1
        AND pj.Level = 2 
        AND yt.YtName <> '不区分业态';

    -- 缓存盈利规划F08表
    SELECT 
        ProjGUID,
        Bb,
        YtName,
        SUM(TotalSaleValueAmount) AS TotalSaleValueAmount,
        SUM(TotalSaleValueArea) AS TotalSaleValueArea,
        SUM(BusinessCost) AS BusinessCost,
        SUM(SaleIncome) AS SaleIncome
    INTO #f08
    FROM (
        SELECT 
            ([实体分期]) AS ProjGUID,
            f08.[版本] AS Bb,
            f08.[业态] AS YtName,
            CASE
                WHEN f08.[报表预测项目科目] IN ('营业税下收入', '增值税下含税收入')
                    AND f08.[明细说明] = '总价'
                    AND f08.[综合维] = '可售产品' 
                THEN CAST(ISNULL(f08.VALUE_STRING, '0') AS DECIMAL(32, 6))
            END AS TotalSaleValueAmount,
            CASE
                WHEN f08.[报表预测项目科目] = '结转面积'
                    AND f08.[明细说明] = '总价'
                    AND f08.[综合维] = '可售产品' 
                THEN CAST(ISNULL(f08.VALUE_STRING, '0') AS DECIMAL(32, 6))
            END AS TotalSaleValueArea,
            CASE
                WHEN f08.[报表预测项目科目] = '结转成本'
                    AND f08.[明细说明] = '总价'
                    AND f08.[综合维] = '可售产品' 
                THEN CAST(ISNULL(f08.VALUE_STRING, '0') AS DECIMAL(32, 6))
            END AS BusinessCost,
            CASE
                WHEN f08.[报表预测项目科目] = '销售收入(不含税）'
                    AND f08.[明细说明] = '总价'
                    AND f08.[综合维] = '可售产品' 
                THEN CAST(ISNULL(f08.VALUE_STRING, '0') AS DECIMAL(32, 6))
            END AS SaleIncome
        FROM [172.16.4.161].HighData_prod.dbo.data_wide_qt_F080004 f08
            INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SumProjYt ProjYt
                ON (f08.[实体分期]) = ProjYt.ProjGUID
                AND (f08.[版本] = ProjYt.[版本])
                AND ProjYt.[业态] = f08.[业态]
        WHERE CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0
            AND f08.[报表预测项目科目] IN ('营业税下收入', '增值税下含税收入', '结转面积', '结转成本', '销售收入(不含税）')
    ) temp
    GROUP BY 
        ProjGUID,
        Bb,
        YtName;

    SELECT 
        pj.ProjGUID AS projguid,
        yt.YtName,
        SUM(ISNULL(TotalSaleValueArea, 0)) 总可售面积,
        SUM(ISNULL(SaleIncome, 0)) 总可售金额不含税
    INTO #mj
    FROM #f08 yt
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
            ON yt.ProjGUID = pj.YLGHProjGUID
            AND pj.edition = @ylghbb
            AND pj.BusinessEdition = yt.Bb
            AND pj.Level = 3
        INNER JOIN erp25.dbo.mdm_project p 
            ON pj.ProjGUID = p.projguid
    WHERE 1=1 
        AND yt.YtName <> '不区分业态'
    GROUP BY 
        pj.ProjGUID,
        yt.YtName;

    --单方数据1
    SELECT 
        pj.ProjGUID AS projguid,
        yt.YtName,
        SUM(ISNULL(HuNum, 0)) 户数,
        SUM(ISNULL(OperatingCost, 0)) AS 营业成本,
        SUM(ISNULL(FinanceCost, 0)) AS 资本化利息_综合管理费,
        SUM(ISNULL(TaxeAndSurcharges, 0)) AS 税金及附加,
        SUM(ISNULL(EquityPremium, 0)) AS 股权溢价,
        SUM(ISNULL(yt.Marketingcost, 0)) AS 营销费用,
        SUM(ISNULL(yt.TotalInvestment, 0)) AS 总成本含税
    INTO #df
    FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_expenses_yt yt
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
            ON yt.ProjGUID = pj.YLGHProjGUID
            AND pj.edition = @ylghbb
            AND pj.BusinessEdition = yt.BusinessEdition
            AND pj.Level = 3
        INNER JOIN erp25.dbo.mdm_project p 
            ON pj.ProjGUID = p.projguid
    WHERE 1=1
    GROUP BY 
        pj.ProjGUID,
        yt.YtName;

    --单方数据2，分摊口径：土地款单方、除地价外直投单方、资本化利息单方、综合管理费单方、开发间接费单方
    SELECT 
        projguid,
        业态 AS ytname,
        土地款,
        总成本 - 土地款 - 资本化利息 - 开发间接费 AS 除地价外直投,
        资本化利息,
        开发间接费
    INTO #df2
    FROM (
        SELECT 
            pj.projguid,
            业态,
            SUM(CASE
                WHEN 成本预测科目 IN ('国土出让金', '原始成本', '契税', '其它土地款',
                    '土地转让金', '土地抵减税金', '股权溢价', '拆迁补偿费')
                THEN CONVERT(DECIMAL(32, 4), value_string)
                ELSE 0
            END) AS 土地款,
            SUM(CONVERT(DECIMAL(16, 4), value_string)) AS 总成本,
            SUM(CASE
                WHEN 成本预测科目 IN ('资本化利息')
                THEN CONVERT(DECIMAL(32, 4), value_string)
                ELSE 0
            END) AS 资本化利息,
            SUM(CASE
                WHEN 成本预测科目 IN ('开发间接费')
                THEN CONVERT(DECIMAL(32, 4), value_string)
                ELSE 0
            END) AS 开发间接费
        FROM [172.16.4.161].HighData_prod.dbo.data_wide_qt_F030008 f03
            INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
                ON f03.实体分期 = pj.YLGHProjGUID
                AND pj.edition = @ylghbb
                AND pj.Level = 3
                AND f03.版本 = pj.BusinessEdition
        WHERE 明细说明 = '账务口径不含税总成本'
            AND CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0
        GROUP BY 
            pj.projguid,
            业态
    ) t;

    --单方数据3
    SELECT 
        pj.projguid,
        业态 AS ytname,
        SUM(CASE 
            WHEN 报表预测项目科目 = '结转成本' 
                AND 综合维 = '经营产品' 
            THEN CONVERT(DECIMAL(32,4), value_string) 
            ELSE 0 
        END) AS 经营成本,
        SUM(CASE 
            WHEN 报表预测项目科目 = '综合管理费用-协议口径' 
                AND 综合维 = '可售产品' 
            THEN CONVERT(DECIMAL(32,4), value_string) 
            ELSE 0 
        END) AS 管理费用
    INTO #df3
    FROM [172.16.4.161].HighData_prod.dbo.data_wide_qt_F080004 f03
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
            ON f03.实体分期 = pj.YLGHProjGUID
            AND pj.edition = @ylghbb
            AND pj.Level = 3 
            AND f03.版本 = pj.BusinessEdition
    WHERE CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0
        AND 明细说明 = '总价'
    GROUP BY 
        pj.projguid,
        业态;

    --汇总数据
    SELECT 
        t.公司Guid,
        t.公司名称 AS 平台公司,
        t.项目Guid,
        t.项目推广名 AS 项目名称,
        t.项目代码,
        t.项目投管代码,
        t.盈利规划版本,
        t.盈利规划业务版本,
        t.盈利规划上线方式,
        t.产品类型,
        t.产品名称,
        t.装修标准,
        t.商品类型,
        t.匹配主键,
        t.总可售面积,
        t.总可售金额不含税 AS 总可售金额,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.除地价外直投 / t.总可售面积
        END AS 除地外直投_单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.土地款 / t.总可售面积
        END AS 土地款_单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.资本化利息_综合管理费 / t.总可售面积
        END AS 资本化利息_综合管理费_单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.营业成本 / t.总可售面积
        END AS 盈利规划营业成本单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.税金及附加 / t.总可售面积
        END AS 税金及附加单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.股权溢价 / t.总可售面积
        END AS 股权溢价单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.管理费用 / t.总可售面积
        END AS 管理费用单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.营销费用 / t.总可售面积
        END AS 营销费用单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.资本化利息 / t.总可售面积
        END AS 资本化利息_单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.开发间接费 / t.总可售面积
        END AS 开发间接费_单方,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.总成本含税 / t.总可售面积
        END AS 总成本含税单方,
        convert(decimal(16,2),0.0) as 总投资不含税单方,
        盈利规划车位数,
        CASE
            WHEN t.总可售面积 = 0 THEN 0
            ELSE t.经营成本 / t.总可售面积
        END AS 经营成本单方
    INTO #res
    FROM (
        SELECT 
            base.*,
            SUM(ISNULL(mj.总可售金额不含税, 0)) AS 总可售金额不含税,
            SUM(CASE
                WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)
                ELSE ISNULL(mj.总可售面积, 0)
            END) AS 总可售面积,
            sum(CASE 
                WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0) 
                ELSE 0 
            END) as 盈利规划车位数, 
            SUM(ISNULL(df.营业成本, 0)) AS 营业成本,
            SUM(ISNULL(df.资本化利息_综合管理费, 0)) AS 资本化利息_综合管理费,
            SUM(ISNULL(df.税金及附加, 0)) AS 税金及附加,
            SUM(ISNULL(df.股权溢价, 0)) AS 股权溢价,
            SUM(ISNULL(df1.除地价外直投, 0)) AS 除地价外直投,
            SUM(ISNULL(df1.土地款, 0)) AS 土地款,
            SUM(ISNULL(df3.管理费用, 0)) AS 管理费用,
            SUM(ISNULL(df.营销费用, 0)) AS 营销费用,
            SUM(ISNULL(df1.资本化利息, 0)) AS 资本化利息,
            SUM(ISNULL(df1.开发间接费, 0)) AS 开发间接费,
            SUM(ISNULL(df.总成本含税, 0)) AS 总成本含税,
            SUM(ISNULL(df3.经营成本, 0)) AS 经营成本
        FROM #base base
            LEFT JOIN #mj mj
                ON base.项目Guid = mj.projguid
                AND base.YtName = mj.YtName
            LEFT JOIN #df df
                ON df.projguid = base.项目Guid
                AND df.YtName = base.YtName
            LEFT JOIN #df2 df1
                ON df1.ProjGUID = base.项目Guid
                AND df1.YtName = base.YtName
            LEFT JOIN #df3 df3
                ON df3.ProjGUID = base.项目Guid
                AND df3.YtName = base.YtName
        GROUP BY 
            base.公司名称,
            base.项目Guid,
            base.项目推广名,
            base.项目代码,
            base.项目投管代码,
            base.盈利规划版本,
            base.盈利规划业务版本,
            base.盈利规划上线方式,
            base.产品类型,
            base.产品名称,
            base.装修标准,
            base.商品类型,
            base.匹配主键,
            base.YtName,
            base.公司Guid
    ) t;

    --更新总投资不含税单方为 营业成本单方+综合管理费单方+营销费单方
    UPDATE #res 
    SET 总投资不含税单方 = convert(decimal(16,2),盈利规划营业成本单方+管理费用单方+营销费用单方);

    --插入正式表
    TRUNCATE TABLE s_F066项目毛利率销售底表_盈利规划单方锁定版;

    INSERT INTO s_F066项目毛利率销售底表_盈利规划单方锁定版(
        OrgGuid,平台公司,项目guid,项目名称,项目代码,投管代码,盈利规划版本,盈利规划业务版本,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,匹配主键,
        总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,盈利规划营业成本单方,税金及附加单方,股权溢价单方,
        管理费用单方,营销费用单方,资本化利息单方,开发间接费单方,总投资不含税单方,盈利规划车位数,总成本含税单方,经营成本单方
    )
    SELECT 
        公司Guid,平台公司,项目Guid,项目名称,项目代码,项目投管代码,盈利规划版本,盈利规划业务版本,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,
        匹配主键,总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,
        盈利规划营业成本单方,税金及附加单方,股权溢价单方,管理费用单方,营销费用单方,资本化利息_单方,开发间接费_单方,总投资不含税单方,盈利规划车位数,
        总成本含税单方,经营成本单方
    FROM #res;

    SELECT * FROM s_F066项目毛利率销售底表_盈利规划单方锁定版;     

    -- 删除临时表
    DROP TABLE #base,
        #df,
        #df2,
        #mj,
        #df3,
        #f08;

--------------------------------------------------项目层级单方取数 end ---------------------------------------

END;