USE [dss]
GO

-- -- exec [usp_s_F066项目毛利率销售底表_盈利规划单方] ''
-- ALTER PROC [dbo].[usp_s_F066项目毛利率销售底表_盈利规划单方] 
-- (
--     @var_buguid VARCHAR(MAX),
--    -- @var_edate VARCHAR(200),
--     @Date DATETIME = NULL,
--     @VersionGUID VARCHAR(40) = '',
--     @IsNew INT = 0
-- )
-- AS
-- BEGIN
--   IF @VersionGUID = '默认值'
--        OR @VersionGUID = '00000000-0000-0000-0000-000000000000'
--     BEGIN
--         SET @VersionGUID = NULL;
--     END;

--     --判断查询日期，是否存在拍照数据，如果存在，则获取拍照版本表中的版本数据，不存在则实收获取
--     IF (ISNULL(@VersionGUID, '') <> '' AND @IsNew = 0)
--     BEGIN
--         SELECT VersionGUID,
--                OrgGuid,
--                平台公司,
--                项目guid,
--                项目名称,
--                项目代码,
--                投管代码,
--                盈利规划上线方式,
--                产品类型,
--                产品名称,
--                装修标准,
--                商品类型,
--                匹配主键,
--                总可售面积,
--                总可售金额,
--                除地外直投_单方,
--                土地款_单方,
--                资本化利息_综合管理费_单方,
--                盈利规划营业成本单方,
--                税金及附加单方,
--                股权溢价单方,
-- 			   营销费用单方,
-- 			   管理费用单方,
-- 			   资本化利息单方,
-- 			   开发间接费单方,
-- 			   总投资不含税单方
--         FROM [dss].dbo.[nmap_s_F066项目毛利率销售底表_盈利规划单方]
--         WHERE VersionGuid = @VersionGUID
--               AND orgguid IN (
--                                  SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
--                              );
--     END;
	 
--     ELSE
--     BEGIN
--         SET NOCOUNT ON;
--         SET @VersionGUID = NEWID()

--     SELECT	@VersionGUID VersionGUID,
-- 	        OrgGuid,
--             平台公司,
--             项目guid,
--             项目名称,
--             项目代码,
--             投管代码,
--             盈利规划上线方式,
--             产品类型,
--             产品名称,
--             装修标准,
--             商品类型,
--             匹配主键,
--             总可售面积,
--             总可售金额,
--             除地外直投_单方,
--             土地款_单方,
--             资本化利息_综合管理费_单方,
--             盈利规划营业成本单方,
--             税金及附加单方,
--             股权溢价单方,
-- 			营销费用单方,
-- 			管理费用单方,
-- 			资本化利息单方,
-- 			开发间接费单方,
-- 			总投资不含税单方
--     FROM s_F066项目毛利率销售底表_盈利规划单方
--     WHERE OrgGuid IN (
--                          SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
--                      )
--     ORDER BY 平台公司,
--              项目代码;

-- END;

-- END;




USE [dss]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_F066项目毛利率销售底表_盈利规划单方_清洗]    Script Date: 2025/11/7 10:55:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER  PROC [dbo].[usp_s_F066项目毛利率销售底表_盈利规划单方_清洗] 
AS
/*

modified by lintx
date 20220906
1、增加总投资（不含税）单方 = 营业成本单方+综合管理费单方+营销费单方
2、调整动态成本口径为分摊口径，涉及指标如下：
土地款单方、除地价外直投单方、资本化利息单方、综合管理费单方、开发间接费单方
3、资本化利息_管理费 调整为F080004可售单方的管理费用_协议口径

modified by lintx  date 20230903
1、增加分期维度单方信息,由于担心明源系统跟盈利规划系统分期不一致导致数据异常，故项目和分期的逻辑分开来取值

modified by lintx  date 20250327
增加经营成本单方信息
*/

BEGIN
--------------------------------------------------项目层级单方取数 begin--------------------------------------

--获取盈利规划业态基础信息
SELECT DISTINCT
       do.DevelopmentCompanyGUID AS 公司Guid,
       do.OrganizationName AS 公司名称,
       pj.ProjGUID AS 项目Guid,
       pj.SpreadName AS 项目推广名,
       pj1.ProjCode AS 项目代码,
       pj.TgProjCode AS 项目投管代码,
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
           AND p.isbase = 1
           AND p.Level = 3
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Project pj
        ON p.ProjGUID = pj.ProjGUID
    INNER JOIN ERP25.dbo.mdm_Project pj1
        ON pj1.ProjGUID = pj.ProjGUID
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_Dimension_Organization do
        ON pj.BUGUID = do.OrgGUID
    --获取一级产品类型
    LEFT JOIN
    (
        SELECT ProductTypeName,
               TopProductTypeName,
               ROW_NUMBER() OVER (PARTITION BY pr.ProductTypeName ORDER BY ProductTypeName) AS num
        FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Product pr
    ) pr
        ON pr.num = 1
           AND pr.ProductTypeName = yt.ProductType
WHERE yt.IsBase = 1
      AND pj.Level = 2 
      AND yt.YtName <> '不区分业态';

--获取盈利规划系统数据情况
--总可售金额跟面积
SELECT pj.ProjGUID AS projguid,
       yt.YtName,
       SUM(ISNULL(TotalSaleValueArea, 0)) 总可售面积,
       SUM(ISNULL(TotalSaleValueAmountNotTax, 0)) 总可售金额不含税
INTO #mj
FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SaleValueByYt yt
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON yt.ProjGUID = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
	INNER JOIN erp25.dbo.mdm_project p ON pj.ProjGUID = p.projguid
WHERE yt.IsBase = 1  
GROUP BY pj.ProjGUID,
         yt.YtName;


--单方数据1
SELECT pj.ProjGUID AS projguid,
       yt.YtName,
       SUM(ISNULL(HuNum, 0)) 户数,
       SUM(ISNULL(OperatingCost, 0)) AS 营业成本,
       SUM(ISNULL(FinanceCost, 0)) AS 资本化利息_综合管理费,
       SUM(ISNULL(TaxeAndSurcharges, 0)) AS 税金及附加,
       SUM(ISNULL(EquityPremium, 0)) AS 股权溢价,
	--   SUM(ISNULL(yt.managementCost, 0)) AS 管理费用,
	   SUM(ISNULL(yt.Marketingcost, 0)) AS 营销费用,
       SUM(ISNULL(yt.TotalInvestment, 0)) AS 总成本含税
INTO #df
FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_expenses_yt yt
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON yt.ProjGUID = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
	INNER JOIN erp25.dbo.mdm_project p ON pj.ProjGUID = p.projguid
WHERE yt.IsBase = 1  
GROUP BY pj.ProjGUID,
         yt.YtName;
 
--单方数据2，分摊口径：土地款单方、除地价外直投单方、资本化利息单方、综合管理费单方、开发间接费单方
--SELECT pj.ProjGUID,
--       yt.YtName,
--       SUM(ISNULL(YtZtAmount, 0) - ISNULL(YtLandAmount, 0)) AS 除地价外直投,
--       SUM(ISNULL(YtLandAmount, 0)) AS 土地款
--INTO #df2
--FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SumOperatingProfitDataByYt yt
--    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
--        ON yt.ProjGUID = pj.YLGHProjGUID
--           AND pj.isbase = 1
--           AND pj.Level = 3
--	INNER JOIN erp25.dbo.mdm_project p ON pj.ProjGUID = p.projguid
--WHERE yt.IsBase = 1  
--GROUP BY pj.ProjGUID,
--         yt.YtName;

select projguid, 
业态 as ytname,
土地款,总成本 - 土地款-资本化利息-开发间接费 as 除地价外直投,
资本化利息, 
开发间接费
into #df2
from (
select pj.projguid,
业态,
sum(case when 成本预测科目 in ('国土出让金','原始成本','契税','其它土地款',
'土地转让金','土地抵减税金','股权溢价','拆迁补偿费') then convert(decimal(32,4),value_string)  else 0 end) as 土地款,
sum( convert(decimal(16,4),value_string) ) as 总成本,
sum(case when 成本预测科目 in ('资本化利息') then convert(decimal(32,4),value_string)  else 0 end) as 资本化利息,
sum(case when 成本预测科目 in ('开发间接费') then convert(decimal(32,4),value_string)  else 0 end) as 开发间接费
from  [172.16.4.161].HighData_prod.dbo.data_wide_qt_F030008 f03
INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f03.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3 and f03.版本 = pj.BusinessEdition
where   明细说明 = '账务口径不含税总成本' and  CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 
--and len(substring(value_string,0,charindex('.',value_string)+5))<15
group by pj.projguid,
业态 ) t

--单方数据3
select pj.projguid,
业态 as ytname, 
sum(case when 报表预测项目科目 = '结转成本' and 综合维 = '经营产品' then convert(decimal(32,4),value_string) else 0 end ) as 经营成本,
sum(case when 报表预测项目科目 = '综合管理费用-协议口径' and 综合维 = '可售产品' then convert(decimal(32,4),value_string) else 0 end ) as 管理费用 
into #df3
from  [172.16.4.161].HighData_prod.dbo.data_wide_qt_F080004 f03
INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f03.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3 and f03.版本 = pj.BusinessEdition
where  CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 
and 明细说明 = '总价'
group by pj.projguid,业态 

 
--汇总数据
SELECT t.公司Guid,
       t.公司名称 AS 平台公司,
       t.项目Guid,
       t.项目推广名 AS 项目名称,
       t.项目代码,
       t.项目投管代码,
       t.盈利规划上线方式,
       t.产品类型,
       t.产品名称,
       t.装修标准,
       t.商品类型,
       t.匹配主键,
       t.总可售面积,
       t.总可售金额不含税 AS 总可售金额,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.除地价外直投 / t.总可售面积
       END AS 除地外直投_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.土地款 / t.总可售面积
       END AS 土地款_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.资本化利息_综合管理费 / t.总可售面积
       END AS 资本化利息_综合管理费_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.营业成本 / t.总可售面积
       END AS 盈利规划营业成本单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.税金及附加 / t.总可售面积
       END AS 税金及附加单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.股权溢价 / t.总可售面积
       END AS 股权溢价单方,
	   CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.管理费用 / t.总可售面积
       END AS 管理费用单方,
	   CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.营销费用 / t.总可售面积
       END AS 营销费用单方,
	   CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.资本化利息 / t.总可售面积
       END AS 资本化利息_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.开发间接费 / t.总可售面积
       END AS 开发间接费_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.总成本含税 / t.总可售面积
       END AS 总成本含税单方,
	   convert(decimal(16,2),0.0) as 总投资不含税单方,
	   盈利规划车位数,
	   CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.经营成本 / t.总可售面积
       END AS 经营成本单方
	   INTO #res
FROM
(
    SELECT base.*,
           SUM(ISNULL(mj.总可售金额不含税, 0)) AS 总可售金额不含税,
           SUM(   CASE
                      WHEN base.产品类型 = '地下室/车库' THEN
                          ISNULL(df.户数, 0)
                      ELSE
                          ISNULL(mj.总可售面积, 0)
                  END
              ) AS 总可售面积,
		   sum(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0) else 0 end) as 盈利规划车位数, 
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
    GROUP BY base.公司名称,
             base.项目Guid,
             base.项目推广名,
             base.项目代码,
             base.项目投管代码,
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
update #res set 总投资不含税单方 = convert(decimal(16,2),盈利规划营业成本单方+管理费用单方+营销费用单方)
 
--插入正式表
TRUNCATE TABLE s_F066项目毛利率销售底表_盈利规划单方;

INSERT INTO s_F066项目毛利率销售底表_盈利规划单方(
OrgGuid,平台公司,项目guid,项目名称,项目代码,投管代码,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,匹配主键,
总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,盈利规划营业成本单方,税金及附加单方,股权溢价单方,
管理费用单方,营销费用单方,资本化利息单方,开发间接费单方,总投资不含税单方 ,盈利规划车位数,总成本含税单方,经营成本单方
)
SELECT 公司Guid,平台公司,项目Guid,项目名称,项目代码,项目投管代码,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,
匹配主键,总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,
盈利规划营业成本单方,税金及附加单方	,股权溢价单方,管理费用单方,营销费用单方,资本化利息_单方,开发间接费_单方,总投资不含税单方,盈利规划车位数,
总成本含税单方,经营成本单方
FROM #res;

SELECT * FROM s_F066项目毛利率销售底表_盈利规划单方 

DROP TABLE #base,
           #df,
           #df2,
           #mj,#df3;
--------------------------------------------------项目层级单方取数 end ---------------------------------------

--------------------------------------------------分期层级单方取数 begin--------------------------------------
--获取盈利规划业态基础信息
SELECT DISTINCT
       do.DevelopmentCompanyGUID AS 公司Guid,
       do.OrganizationName AS 公司名称,
       pj.ProjGUID AS 项目Guid,
       pj.SpreadName AS 项目推广名,
       pj1.ProjCode AS 项目代码,
       pj.TgProjCode AS 项目投管代码,
       fq.spreadname as 分期,
       fq.projguid as 分期guid,
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
       isnull(fq.spreadname,'')+'_'+isnull(pj1.ProjCode,'') + '_' + isnull(pr.TopProductTypeName,'') + '_' + isnull(yt.YtName,'') 匹配主键,
       yt.YtName
INTO #base_fq
FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SumProjProductYt yt
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID p
        ON p.YLGHProjGUID = yt.ProjGUID
           AND p.isbase = 1
           AND p.Level = 3
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Project pj
        ON p.ProjGUID = pj.ProjGUID
    INNER JOIN ERP25.dbo.mdm_Project pj1
        ON pj1.ProjGUID = pj.ProjGUID
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Project fq
        ON p.YLGHProjGUID = fq.ProjGUID
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_Dimension_Organization do
        ON pj.BUGUID = do.OrgGUID
    --获取一级产品类型
    LEFT JOIN
    (
        SELECT ProductTypeName,
               TopProductTypeName,
               ROW_NUMBER() OVER (PARTITION BY pr.ProductTypeName ORDER BY ProductTypeName) AS num
        FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Product pr
    ) pr
        ON pr.num = 1
           AND pr.ProductTypeName = yt.ProductType
WHERE yt.IsBase = 1
      AND pj.Level = 2 
      AND yt.YtName <> '不区分业态';

--获取盈利规划系统数据情况
--总可售金额跟面积
SELECT pj.ProjGUID AS projguid,
       fq.projguid as 分期guid,
       yt.YtName,
       SUM(ISNULL(TotalSaleValueArea, 0)) 总可售面积,
       SUM(ISNULL(TotalSaleValueAmountNotTax, 0)) 总可售金额不含税
INTO #mj_fq
FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SaleValueByYt yt
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON yt.ProjGUID = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
	INNER JOIN erp25.dbo.mdm_project p ON pj.ProjGUID = p.projguid
    INNER JOIN erp25.dbo.mdm_project fq ON pj.YLGHProjGUID = fq.projguid
WHERE yt.IsBase = 1  
GROUP BY pj.ProjGUID,fq.projguid,yt.YtName;

--单方数据1
SELECT pj.ProjGUID AS projguid,
       fq.projguid as 分期guid,
       yt.YtName,
       SUM(ISNULL(HuNum, 0)) 户数,
       SUM(ISNULL(OperatingCost, 0)) AS 营业成本,
       SUM(ISNULL(FinanceCost, 0)) AS 资本化利息_综合管理费,
       SUM(ISNULL(TaxeAndSurcharges, 0)) AS 税金及附加,
       SUM(ISNULL(EquityPremium, 0)) AS 股权溢价,
	   SUM(ISNULL(yt.Marketingcost, 0)) AS 营销费用
INTO #df_fq
FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_expenses_yt yt
    INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON yt.ProjGUID = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3
	INNER JOIN erp25.dbo.mdm_project p ON pj.ProjGUID = p.projguid
    INNER JOIN erp25.dbo.mdm_project fq ON pj.YLGHProjGUID = fq.projguid
WHERE yt.IsBase = 1  
GROUP BY pj.ProjGUID,fq.projguid,yt.YtName;

select projguid, 分期guid,
业态 as ytname,
土地款,总成本 - 土地款-资本化利息-开发间接费 as 除地价外直投,
资本化利息, 
开发间接费
into #df2_fq
from (
select pj.projguid, pj.YLGHProjGUID as 分期guid,
业态,
sum(case when 成本预测科目 in ('国土出让金','原始成本','契税','其它土地款',
'土地转让金','土地抵减税金','股权溢价','拆迁补偿费') then convert(decimal(32,4),value_string)  else 0 end) as 土地款,
sum( convert(decimal(16,4),value_string) ) as 总成本,
sum(case when 成本预测科目 in ('资本化利息') then convert(decimal(32,4),value_string)  else 0 end) as 资本化利息,
sum(case when 成本预测科目 in ('开发间接费') then convert(decimal(32,4),value_string)  else 0 end) as 开发间接费
from  [172.16.4.161].HighData_prod.dbo.data_wide_qt_F030008 f03
INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f03.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3 and f03.版本 = pj.BusinessEdition
where   明细说明 = '账务口径不含税总成本' and  CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 
--and len(substring(value_string,0,charindex('.',value_string)+5))<15
group by pj.projguid,pj.YLGHProjGUID,业态 ) t

--单方数据3
select pj.projguid,pj.YLGHProjGUID as 分期guid,
业态 as ytname, 
sum( convert(decimal(32,4),value_string) ) as 管理费用 
into #df3_fq
from  [172.16.4.161].HighData_prod.dbo.data_wide_qt_F080004 f03
INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON f03.实体分期 = pj.YLGHProjGUID
           AND pj.isbase = 1
           AND pj.Level = 3 and f03.版本 = pj.BusinessEdition
where 报表预测项目科目 = '综合管理费用-协议口径'
and 综合维 = '可售产品' and CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 
group by pj.projguid,pj.YLGHProjGUID,业态 
 
--汇总数据
SELECT t.公司Guid,
       t.公司名称 AS 平台公司,
       t.项目Guid,
       t.项目推广名 AS 项目名称,
       t.项目代码,
       t.项目投管代码,
       t.分期,
       t.分期guid,
       t.盈利规划上线方式,
       t.产品类型,
       t.产品名称,
       t.装修标准,
       t.商品类型,
       t.匹配主键,
       t.总可售面积,
       t.总可售金额不含税 AS 总可售金额,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.除地价外直投 / t.总可售面积
       END AS 除地外直投_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.土地款 / t.总可售面积
       END AS 土地款_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.资本化利息_综合管理费 / t.总可售面积
       END AS 资本化利息_综合管理费_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.营业成本 / t.总可售面积
       END AS 盈利规划营业成本单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.税金及附加 / t.总可售面积
       END AS 税金及附加单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.股权溢价 / t.总可售面积
       END AS 股权溢价单方,
	   CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.管理费用 / t.总可售面积
       END AS 管理费用单方,
	   CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.营销费用 / t.总可售面积
       END AS 营销费用单方,
	   CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.资本化利息 / t.总可售面积
       END AS 资本化利息_单方,
       CASE
           WHEN t.总可售面积 = 0 THEN
               0
           ELSE
               t.开发间接费 / t.总可售面积
       END AS 开发间接费_单方,
	   convert(decimal(16,2),0.0) as 总投资不含税单方,
	   盈利规划车位数
	   INTO #res_fq
FROM
(
    SELECT base.*,
           SUM(ISNULL(mj.总可售金额不含税, 0)) AS 总可售金额不含税,
           SUM(   CASE
                      WHEN base.产品类型 = '地下室/车库' THEN
                          ISNULL(df.户数, 0)
                      ELSE
                          ISNULL(mj.总可售面积, 0)
                  END
              ) AS 总可售面积,
		   sum(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0) else 0 end) as 盈利规划车位数, 
           SUM(ISNULL(df.营业成本, 0)) AS 营业成本,
           SUM(ISNULL(df.资本化利息_综合管理费, 0)) AS 资本化利息_综合管理费,
           SUM(ISNULL(df.税金及附加, 0)) AS 税金及附加,
           SUM(ISNULL(df.股权溢价, 0)) AS 股权溢价,
           SUM(ISNULL(df1.除地价外直投, 0)) AS 除地价外直投,
           SUM(ISNULL(df1.土地款, 0)) AS 土地款,
		   SUM(ISNULL(df3.管理费用, 0)) AS 管理费用,
		   SUM(ISNULL(df.营销费用, 0)) AS 营销费用,
		   SUM(ISNULL(df1.资本化利息, 0)) AS 资本化利息,
           SUM(ISNULL(df1.开发间接费, 0)) AS 开发间接费
    FROM #base_fq base
        LEFT JOIN #mj_fq mj
            ON base.分期guid = mj.分期guid
               AND base.YtName = mj.YtName
        LEFT JOIN #df_fq df
            ON df.分期guid = base.分期guid
               AND df.YtName = base.YtName
        LEFT JOIN #df2_fq df1
            ON df1.分期guid = base.分期guid
               AND df1.YtName = base.YtName
		 LEFT JOIN #df3_fq df3
            ON df3.分期guid = base.分期guid
               AND df3.YtName = base.YtName
    GROUP BY base.公司名称,
             base.项目Guid,
             base.项目推广名,
             base.项目代码,
             base.项目投管代码,
             base.盈利规划上线方式,
             base.产品类型,
             base.产品名称,
             base.装修标准,
             base.商品类型,
             base.匹配主键,
             base.YtName,
             base.公司Guid,
             base.分期,base.分期guid
) t;

--更新总投资不含税单方为 营业成本单方+综合管理费单方+营销费单方
update #res_fq set 总投资不含税单方 = convert(decimal(16,2),盈利规划营业成本单方+管理费用单方+营销费用单方)
 
--插入正式表
TRUNCATE TABLE s_F066项目毛利率销售底表_盈利规划分期单方;

INSERT INTO s_F066项目毛利率销售底表_盈利规划分期单方(
OrgGuid,平台公司,项目guid,项目名称,项目代码,投管代码,分期,分期guid,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,匹配主键,
总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,盈利规划营业成本单方,税金及附加单方,股权溢价单方,
管理费用单方,营销费用单方,资本化利息单方,开发间接费单方,总投资不含税单方 ,盈利规划车位数
)
SELECT 公司Guid,平台公司,项目Guid,项目名称,项目代码,项目投管代码,分期,分期guid,盈利规划上线方式,产品类型,产品名称,装修标准,商品类型,
匹配主键,总可售面积,总可售金额,除地外直投_单方,土地款_单方,资本化利息_综合管理费_单方,
盈利规划营业成本单方,税金及附加单方	,股权溢价单方,管理费用单方,营销费用单方,资本化利息_单方,开发间接费_单方,总投资不含税单方,盈利规划车位数
FROM #res_fq;

SELECT * FROM s_F066项目毛利率销售底表_盈利规划分期单方 

DROP TABLE #base_fq, #df_fq, #df2_fq,  #mj_fq,#df3_fq;
--------------------------------------------------分期层级单方取数 end  --------------------------------------

END 
 


 


