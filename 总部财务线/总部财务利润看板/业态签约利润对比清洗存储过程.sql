USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_业态签约利润对比表_盈利规划单方锁定版调整]    Script Date: 2025/7/1 14:39:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
  功能：用于清洗《业态签约利润对比表》 用于总部财务动态利润监控看板,每天刷新
  create by chenjw  2025-06-10
  0769045_住宅_超高层住宅_商品房_装修

*/

ALTER  procedure [dbo].[usp_s_业态签约利润对比表_盈利规划单方锁定版调整]
as
Begin 
-- DROP TABLE [dbo].[业态签约利润对比表]
-- CREATE TABLE [dbo].[业态签约利润对比表](
-- 	[清洗时间] [datetime] NULL,
-- 	[清洗版本] [uniqueidentifier] NULL,
-- 	[公司] [varchar](500) NULL,
-- 	[项目GUID] [varchar](500) NULL,
-- 	[投管代码] [varchar](500) NULL,
-- 	[项目] [varchar](500) NULL,
-- 	[推广名] [varchar](500) NULL,
-- 	[获取日期] [datetime] NULL,
-- 	[我方股比] [decimal](18, 8) NULL,
-- 	[是否并表] [varchar](500) NULL,
-- 	[合作方] [varchar](500) NULL,
-- 	[是否风险合作方] [varchar](500) NULL,
-- 	[地上总可售面积] [decimal](18, 8) NULL,
-- 	[项目地价] [decimal](18, 8) NULL,
-- 	[盈利规划上线方式] [varchar](500) NULL,
-- 	[产品类型] [varchar](500) NULL,
-- 	[产品名称] [varchar](500) NULL,
-- 	[装修标准] [varchar](500) NULL,
-- 	[商品类型] [varchar](500) NULL,
-- 	[明源匹配主键] [varchar](2000) NULL,
-- 	[业态组合键] [varchar](2000) NULL,
-- 	[立项货值] [decimal](18, 8) NULL,
-- 	[税后利润] [decimal](18, 8) NULL,
-- 	[销售净利率] [decimal](18, 8) NULL,
-- 	[签约_24年签约] [decimal](18, 8) NULL,
-- 	[签约不含税_24年签约] [decimal](18, 8) NULL,
-- 	[签约面积_24年签约] [decimal](18, 8) NULL,
-- 	[净利润_24年签约] [decimal](18, 8) NULL,
-- 	[报表利润_24年签约] [decimal](18, 8) NULL,
-- 	[净利率_24年签约] [decimal](18, 8) NULL,
-- 	[签约均价_24年签约] [decimal](18, 8) NULL,
-- 	[营业成本单方_24年签约] [decimal](18, 8) NULL,
-- 	[营销费用单方_24年签约] [decimal](18, 8) NULL,
-- 	[管理费用单方_24年签约] [decimal](18, 8) NULL,
-- 	[税金单方_24年签约] [decimal](18, 8) NULL,
-- 	[签约_25年预算] [decimal](18, 8) NULL,
-- 	[签约不含税_25年预算] [decimal](18, 8) NULL,
-- 	[签约面积_25年预算] [decimal](18, 8) NULL,
-- 	[签约个数_25年预算] [decimal](18, 8) NULL,
-- 	[净利润_25年预算] [decimal](18, 8) NULL,
-- 	[报表利润_25年预算] [decimal](18, 8) NULL,
-- 	[净利率_25年预算] [decimal](18, 8) NULL,
-- 	[签约均价_25年预算] [decimal](18, 8) NULL,
-- 	[营业成本单方_25年预算] [decimal](18, 8) NULL,
-- 	[营销费用单方_25年预算] [decimal](18, 8) NULL,
-- 	[管理费用单方_25年预算] [decimal](18, 8) NULL,
-- 	[税金单方_25年预算] [decimal](18, 8) NULL,
-- 	[签约_25年签约] [decimal](18, 8) NULL,
-- 	[签约不含税_25年签约] [decimal](18, 8) NULL,
-- 	[签约面积_25年签约] [decimal](18, 8) NULL,
-- 	[净利润_25年签约] [decimal](18, 8) NULL,
-- 	[报表利润_25年签约] [decimal](18, 8) NULL,
-- 	[净利率_25年签约] [decimal](18, 8) NULL,
-- 	[签约均价_25年签约] [decimal](18, 8) NULL,
-- 	[营业成本单方_25年签约] [decimal](18, 8) NULL,
-- 	[营销费用单方_25年签约] [decimal](18, 8) NULL,
-- 	[管理费用单方_25年签约] [decimal](18, 8) NULL,
-- 	[税金单方_25年签约] [decimal](18, 8) NULL,
-- 	[签约_本月实际] [decimal](18, 8) NULL,
-- 	[签约不含税_本月实际] [decimal](18, 8) NULL,
-- 	[签约面积_本月实际] [decimal](18, 8) NULL,
-- 	[签约均价_本月实际] [decimal](18, 8) NULL,
-- 	[认购_本月实际] [decimal](18, 8) NULL,
-- 	[认购不含税_本月实际] [decimal](18, 8) NULL,
-- 	[认购面积_本月实际] [decimal](18, 8) NULL,
-- 	[认购均价_本月实际] [decimal](18, 8) NULL,
-- 	[净利润_本月实际] [decimal](18, 8) NULL,
-- 	[净利率_本月实际] [decimal](18, 8) NULL,
-- 	[签约_上月实际] [decimal](18, 8) NULL,
-- 	[签约不含税_上月实际] [decimal](18, 8) NULL,
-- 	[签约面积_上月实际] [decimal](18, 8) NULL,
-- 	[签约均价_上月实际] [decimal](18, 8) NULL,
-- 	[认购_上月实际] [decimal](18, 8) NULL,
-- 	[认购不含税_上月实际] [decimal](18, 8) NULL,
-- 	[认购面积_上月实际] [decimal](18, 8) NULL,
-- 	[认购均价_上月实际] [decimal](18, 8) NULL,
-- 	[净利润_上月实际] [decimal](18, 8) NULL,
-- 	[净利率_上月实际] [decimal](18, 8) NULL,
-- 	[签约_上上月实际] [decimal](18, 8) NULL,
-- 	[签约不含税_上上月实际] [decimal](18, 8) NULL,
-- 	[签约面积_上上月实际] [decimal](18, 8) NULL,
-- 	[签约均价_上上月实际] [decimal](18, 8) NULL,
-- 	[净利润_上上月实际] [decimal](18, 8) NULL,
-- 	[净利率_上上月实际] [decimal](18, 8) NULL
-- ) ON [PRIMARY]
-- GO

-- 统计项目基本信息
SELECT 
    公司,
    项目GUID,
    投管代码,
    项目,
    推广名,
    获取日期,
    我方股比,
    是否并表,
    合作方,
    '' AS 是否风险合作方,
    地上总可售面积,
    项目地价,
    盈利规划上线方式,
    产品类型,
    产品名称,
    装修标准,
    商品类型,
    明源匹配主键,
    业态组合键,
    -- 预算数据
  /*  isnull(签约_修正版,签约) as 签约_25年预算,
    isnull(签约不含税_修正版,签约不含税) as 签约不含税_25年预算,
    isnull(净利润_修正版,净利润) as 净利润_25年预算,
    case when 是否并表='我司并表' then isnull(净利润_修正版,净利润) else isnull(净利润_修正版,净利润) * 我方股比 /100.0 end as 报表利润_25年预算, --预留字段
    CASE WHEN ISNULL(isnull(签约不含税_修正版,签约不含税),0) = 0 THEN 0 
    ELSE ISNULL(isnull(净利润_修正版,净利润),0) / ISNULL(isnull(签约不含税_修正版,签约不含税),0) END AS 净利率_25年预算, -- 净利润/签约金额不含税
    isnull(签约个数_修正版,签约个数) as 签约个数_25年预算,
    isnull(签约面积_修正版,签约面积) as 签约面积_25年预算,
    CASE WHEN 产品类型='地下室/车库' THEN 
       case when isnull(签约个数_修正版,签约个数) =0 then  0  else  isnull(签约_修正版,签约) *100000000.0 / isnull(签约个数_修正版,签约个数) end
     ELSE 
      case when isnull(签约面积_修正版,签约面积) =0 then  0  else  isnull(签约_修正版,签约) *10000.0 / isnull(签约面积_修正版,签约面积) end
    END AS 签约均价_25年预算, -- 车位按照套数计算
    isnull(营业成本单方_修正版,营业成本单方) as 营业成本单方_25年预算,
    isnull(营销费用单方_修正版,营销费用单方) as 营销费用单方_25年预算,
    isnull(综合管理费单方协议口径_修正版,综合管理费单方协议口径) as 管理费用单方_25年预算,
    isnull(税金及附加_修正版,税金及附加) as 税金单方_25年预算 */

    isnull(签约_修正版,0) as 签约_25年预算,
    isnull(签约不含税_修正版,0) as 签约不含税_25年预算,
    isnull(净利润_修正版,0) as 净利润_25年预算,
    case when 是否并表='我司并表' then isnull(净利润_修正版,0) else isnull(净利润_修正版,0) * 我方股比 /100.0 end as 报表利润_25年预算, --预留字段
    CASE WHEN ISNULL(isnull(签约不含税_修正版,0),0) = 0 THEN 0 
    ELSE ISNULL(isnull(净利润_修正版,0),0) / ISNULL(isnull(签约不含税_修正版,0),0) END AS 净利率_25年预算, -- 净利润/签约金额不含税
    isnull(签约个数_修正版,0) as 签约个数_25年预算,
    isnull(签约面积_修正版,0) as 签约面积_25年预算,
    CASE WHEN 产品类型='地下室/车库' THEN 
       case when isnull(签约个数_修正版,0) =0 then  0  else  isnull(签约_修正版,0) *100000000.0 / isnull(签约个数_修正版,0) end
     ELSE 
      case when isnull(签约面积_修正版,0) =0 then  0  else  isnull(签约_修正版,0) *10000.0 / isnull(签约面积_修正版,0) end
    END AS 签约均价_25年预算, -- 车位按照套数计算
    isnull(营业成本单方_修正版,0) as 营业成本单方_25年预算,
    isnull(营销费用单方_修正版,0) as 营销费用单方_25年预算,
    isnull(综合管理费单方协议口径_修正版,0) as 管理费用单方_25年预算,
    isnull(税金及附加单方_修正版,0) as 税金单方_25年预算 
 INTO #ylghbase
FROM data_tb_ylghProfit;

-- 统计项目层级的立项利润
SELECT 
    b.ProjGUID,
    b.ProductType,
    b.ProductName,
    b.BusinessType,
    b.Standard,
    SUM(ISNULL(a.CashInflowTax*10000.0, 0))  AS 立项总货值, -- 现金流入（含税）
    SUM(ISNULL(a.AfterTaxProfit*10000.0, 0))   AS 税后利润,
    MAX(ISNULL(a.SalesNetInterestRate, 0)) AS 销售净利率
INTO #lxindx
FROM [172.16.4.141].erp25.dbo.mdm_ProjectIncomeIndex a
INNER JOIN [172.16.4.141].erp25.dbo.mdm_TechTargetProduct b
    ON a.ProjGUID = b.ProjGUID
    AND a.ProductGUID = b.ProductGUID
-- WHERE a.projguid = '7125eda8-fcc1-e711-80ba-e61f13c57837'
GROUP BY     
    b.ProjGUID,
    b.ProductType,
    b.ProductName,
    b.BusinessType,
    b.Standard;




    -- 定义变量
    -- DECLARE @bgyear DATETIME; --本年开始日期
    -- DECLARE @endyear DATETIME; --本年截止日期
    DECLARE @buguid VARCHAR(MAX);

    -- SET @bgyear = DATEADD(yy, DATEDIFF(yy, 0, getdate()), 0);
    --SET @endyear = @qxdate;
    -- SET @endyear = DATEADD(month, datediff(month, -1,getdate()), -1)   --0112改为月底最后一天

    SELECT @buguid = STUFF(
                    (SELECT RTRIM(',' + CONVERT(VARCHAR(MAX), devCom.DevelopmentCompanyGUID))
                    FROM [172.16.4.141].erp25.dbo.myBusinessUnit unit
                         LEFT JOIN [172.16.4.141].erp25.dbo.companyjoin comJoin ON unit.BUGUID = comJoin.BUGUID
                         LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany devCom ON devCom.DevelopmentCompanyGUID = comJoin.DevelopmentCompanyGUID
                         INNER JOIN (SELECT DISTINCT DevelopmentCompanyGUID FROM [172.16.4.141].erp25.dbo.mdm_Project) p ON p.DevelopmentCompanyGUID = devCom.DevelopmentCompanyGUID
                    WHERE IsEndCompany = 1 
                      AND IsCompany = 1 
                      AND unit.BUGUID <> '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715'
                      AND unit.BUGUID NOT IN ('bbd25c3a-209d-4f67-8ff2-d7f7ba39d0db', 
                                             '32560bca-d251-4f93-bfe1-3809f94d5183', 
                                             '669afb34-13e4-e411-b873-e41f13c51836',
                                             'dfe03264-02f8-41a0-9d06-7b03582f7cf2', 
                                             'bc5ba7b5-c677-43d7-ae24-3645b9482394', 
                                             'b35cdda9-43ac-40ae-8e1b-2711b960bf39',
                                             '8412A5B2-0147-4AA3-813B-CC41D5D3D55B',    --福州公司、营口公司、丹东公司、通化公司
                                             'B0F2292B-95B5-47DE-B50D-F1E61BDF4692', 
                                             '75B65764-C79A-429B-9086-427BB923294F', 
                                             '7220E82B-A68D-4444-8B4D-1BD5FB8C1996',
                                             '1A0D7025-356E-4344-9074-C9BC416E6E66')
                    FOR XML PATH('')), 1, 1, '');
    
    -- -- 创建临时表
    -- CREATE TABLE #ylgh24
    -- (
    --     versionguid uniqueidentifier,
    --     OrgGuid uniqueidentifier,
    --     ProjGUID uniqueidentifier,
    --     平台公司 varchar(500),
    --     项目名 varchar(500),
    --     推广名 varchar(500),
    --     项目代码 varchar(500),
    --     投管代码 varchar(500),
    --     盈利规划上线方式 varchar(500),
    --     产品类型 varchar(500),
    --     产品名称 varchar(500),
    --     装修标准 varchar(500),
    --     商品类型 varchar(500),
    --     明源匹配主键 varchar(2000),
    --     业态组合键 varchar(2000),
    --     当期认购面积 decimal(18,8),
    --     当期认购金额 decimal(18,8),
    --     当期认购金额不含税 decimal(18,8),
    --     当期签约面积 decimal(18,8),
    --     当期签约金额 decimal(18,8),
    --     当期签约金额不含税 decimal(18,8),
    --     盈利规划营业成本单方 decimal(18,8),
    --     土地款_单方 decimal(18,8),
    --     除地外直投_单方 decimal(18,8),
    --     开发间接费单方 decimal(18,8),
    --     资本化利息单方 decimal(18,8),
    --     盈利规划股权溢价单方 decimal(18,8),
    --     盈利规划营销费用单方 decimal(18,8),
    --     盈利规划综合管理费单方协议口径 decimal(18,8),
    --     盈利规划税金及附加单方 decimal(18,8),
    --     盈利规划营业成本认购 decimal(18,8),
    --     盈利规划股权溢价认购 decimal(18,8),
    --     毛利认购 decimal(18,8),
    --     毛利率认购 decimal(18,8),
    --     盈利规划营销费用认购 decimal(18,8),
    --     盈利规划综合管理费认购 decimal(18,8),
    --     盈利规划税金及附加认购 decimal(18,8),
    --     税前利润认购 decimal(18,8),
    --     所得税认购 decimal(18,8),
    --     净利润认购 decimal(18,8),
    --     销售净利率认购 decimal(18,8),
    --     盈利规划营业成本签约 decimal(18,8),
    --     盈利规划股权溢价签约 decimal(18,8),
    --     毛利签约 decimal(18,8),
    --     毛利率签约 decimal(18,8),
    --     盈利规划营销费用签约 decimal(18,8),
    --     盈利规划综合管理费签约 decimal(18,8),
    --     盈利规划税金及附加签约 decimal(18,8),
    --     税前利润签约 decimal(18,8),
    --     所得税签约 decimal(18,8),
    --     净利润签约 decimal(18,8),
    --     销售净利率签约 decimal(18,8),
    --     当期认购套数 decimal(18,8),
    --     当期签约套数 decimal(18,8),
    --     当期产成品签约金额 decimal(18,8),
    --     当期产成品签约金额不含税 decimal(18,8),
    --     产成品净利润签约 decimal(18,8),
    --     产成品销售净利率签约 decimal(18,8),
    --     是否调整单方比例 varchar(50)
    -- );

   CREATE TABLE #ylgh25
    (
        versionguid uniqueidentifier,
        OrgGuid uniqueidentifier,
        ProjGUID uniqueidentifier,
        平台公司 varchar(500),
        项目名 varchar(500),
        推广名 varchar(500),
        项目代码 varchar(500),
        投管代码 varchar(500),
        盈利规划上线方式 varchar(500),
        产品类型 varchar(500),
        产品名称 varchar(500),
        装修标准 varchar(500),
        商品类型 varchar(500),
        明源匹配主键 varchar(2000),
        业态组合键 varchar(2000),
        当期认购面积 decimal(18,8),
        当期认购金额 decimal(18,8),
        当期认购金额不含税 decimal(18,8),
        当期签约面积 decimal(18,8),
        当期签约金额 decimal(18,8),
        当期签约金额不含税 decimal(18,8),
        盈利规划营业成本单方 decimal(18,8),
        土地款_单方 decimal(18,8),
        除地外直投_单方 decimal(18,8),
        开发间接费单方 decimal(18,8),
        资本化利息单方 decimal(18,8),
        盈利规划股权溢价单方 decimal(18,8),
        盈利规划营销费用单方 decimal(18,8),
        盈利规划综合管理费单方协议口径 decimal(18,8),
        盈利规划税金及附加单方 decimal(18,8),
        盈利规划营业成本认购 decimal(18,8),
        盈利规划股权溢价认购 decimal(18,8),
        毛利认购 decimal(18,8),
        毛利率认购 decimal(18,8),
        盈利规划营销费用认购 decimal(18,8),
        盈利规划综合管理费认购 decimal(18,8),
        盈利规划税金及附加认购 decimal(18,8),
        税前利润认购 decimal(18,8),
        所得税认购 decimal(18,8),
        净利润认购 decimal(18,8),
        销售净利率认购 decimal(18,8),
        盈利规划营业成本签约 decimal(18,8),
        盈利规划股权溢价签约 decimal(18,8),
        毛利签约 decimal(18,8),
        毛利率签约 decimal(18,8),
        盈利规划营销费用签约 decimal(18,8),
        盈利规划综合管理费签约 decimal(18,8),
        盈利规划税金及附加签约 decimal(18,8),
        税前利润签约 decimal(18,8),
        所得税签约 decimal(18,8),
        净利润签约 decimal(18,8),
        销售净利率签约 decimal(18,8),
        当期认购套数 decimal(18,8),
        当期签约套数 decimal(18,8),
        当期产成品签约金额 decimal(18,8),
        当期产成品签约金额不含税 decimal(18,8),
        产成品净利润签约 decimal(18,8),
        产成品销售净利率签约 decimal(18,8),
        是否调整单方比例 varchar(50)
    );


    CREATE TABLE #ylgh_thismonth
    (
        versionguid uniqueidentifier,
        OrgGuid uniqueidentifier,
        ProjGUID uniqueidentifier,
        平台公司 varchar(500),
        项目名 varchar(500),
        推广名 varchar(500),
        项目代码 varchar(500),
        投管代码 varchar(500),
        盈利规划上线方式 varchar(500),
        产品类型 varchar(500),
        产品名称 varchar(500),
        装修标准 varchar(500),
        商品类型 varchar(500),
        明源匹配主键 varchar(2000),
        业态组合键 varchar(2000),
        当期认购面积 decimal(18,8),
        当期认购金额 decimal(18,8),
        当期认购金额不含税 decimal(18,8),
        当期签约面积 decimal(18,8),
        当期签约金额 decimal(18,8),
        当期签约金额不含税 decimal(18,8),
        盈利规划营业成本单方 decimal(18,8),
        土地款_单方 decimal(18,8),
        除地外直投_单方 decimal(18,8),
        开发间接费单方 decimal(18,8),
        资本化利息单方 decimal(18,8),
        盈利规划股权溢价单方 decimal(18,8),
        盈利规划营销费用单方 decimal(18,8),
        盈利规划综合管理费单方协议口径 decimal(18,8),
        盈利规划税金及附加单方 decimal(18,8),
        盈利规划营业成本认购 decimal(18,8),
        盈利规划股权溢价认购 decimal(18,8),
        毛利认购 decimal(18,8),
        毛利率认购 decimal(18,8),
        盈利规划营销费用认购 decimal(18,8),
        盈利规划综合管理费认购 decimal(18,8),
        盈利规划税金及附加认购 decimal(18,8),
        税前利润认购 decimal(18,8),
        所得税认购 decimal(18,8),
        净利润认购 decimal(18,8),
        销售净利率认购 decimal(18,8),
        盈利规划营业成本签约 decimal(18,8),
        盈利规划股权溢价签约 decimal(18,8),
        毛利签约 decimal(18,8),
        毛利率签约 decimal(18,8),
        盈利规划营销费用签约 decimal(18,8),
        盈利规划综合管理费签约 decimal(18,8),
        盈利规划税金及附加签约 decimal(18,8),
        税前利润签约 decimal(18,8),
        所得税签约 decimal(18,8),
        净利润签约 decimal(18,8),
        销售净利率签约 decimal(18,8),
        当期认购套数 decimal(18,8),
        当期签约套数 decimal(18,8),
        当期产成品签约金额 decimal(18,8),
        当期产成品签约金额不含税 decimal(18,8),
        产成品净利润签约 decimal(18,8),
        产成品销售净利率签约 decimal(18,8),
        是否调整单方比例 varchar(50)
    );
    
    CREATE TABLE #ylgh_lastmonth
    (
         versionguid uniqueidentifier,
        OrgGuid uniqueidentifier,
        ProjGUID uniqueidentifier,
        平台公司 varchar(500),
        项目名 varchar(500),
        推广名 varchar(500),
        项目代码 varchar(500),
        投管代码 varchar(500),
        盈利规划上线方式 varchar(500),
        产品类型 varchar(500),
        产品名称 varchar(500),
        装修标准 varchar(500),
        商品类型 varchar(500),
        明源匹配主键 varchar(2000),
        业态组合键 varchar(2000),
        当期认购面积 decimal(18,8),
        当期认购金额 decimal(18,8),
        当期认购金额不含税 decimal(18,8),
        当期签约面积 decimal(18,8),
        当期签约金额 decimal(18,8),
        当期签约金额不含税 decimal(18,8),
        盈利规划营业成本单方 decimal(18,8),
        土地款_单方 decimal(18,8),
        除地外直投_单方 decimal(18,8),
        开发间接费单方 decimal(18,8),
        资本化利息单方 decimal(18,8),
        盈利规划股权溢价单方 decimal(18,8),
        盈利规划营销费用单方 decimal(18,8),
        盈利规划综合管理费单方协议口径 decimal(18,8),
        盈利规划税金及附加单方 decimal(18,8),
        盈利规划营业成本认购 decimal(18,8),
        盈利规划股权溢价认购 decimal(18,8),
        毛利认购 decimal(18,8),
        毛利率认购 decimal(18,8),
        盈利规划营销费用认购 decimal(18,8),
        盈利规划综合管理费认购 decimal(18,8),
        盈利规划税金及附加认购 decimal(18,8),
        税前利润认购 decimal(18,8),
        所得税认购 decimal(18,8),
        净利润认购 decimal(18,8),
        销售净利率认购 decimal(18,8),
        盈利规划营业成本签约 decimal(18,8),
        盈利规划股权溢价签约 decimal(18,8),
        毛利签约 decimal(18,8),
        毛利率签约 decimal(18,8),
        盈利规划营销费用签约 decimal(18,8),
        盈利规划综合管理费签约 decimal(18,8),
        盈利规划税金及附加签约 decimal(18,8),
        税前利润签约 decimal(18,8),
        所得税签约 decimal(18,8),
        净利润签约 decimal(18,8),
        销售净利率签约 decimal(18,8),
        当期认购套数 decimal(18,8),
        当期签约套数 decimal(18,8),
        当期产成品签约金额 decimal(18,8),
        当期产成品签约金额不含税 decimal(18,8),
        产成品净利润签约 decimal(18,8),
        产成品销售净利率签约 decimal(18,8),
        是否调整单方比例 varchar(50)
    );

    -- CREATE TABLE #ylgh_lastlastmonth
    -- (
    --     versionguid uniqueidentifier,
    --     OrgGuid uniqueidentifier,
    --     ProjGUID uniqueidentifier,
    --     平台公司 varchar(500),
    --     项目名 varchar(500),
    --     推广名 varchar(500),
    --     项目代码 varchar(500),
    --     投管代码 varchar(500),
    --     盈利规划上线方式 varchar(500),
    --     产品类型 varchar(500),
    --     产品名称 varchar(500),
    --     装修标准 varchar(500),
    --     商品类型 varchar(500),
    --     明源匹配主键 varchar(2000),
    --     业态组合键 varchar(2000),
    --     当期认购面积 decimal(18,8),
    --     当期认购金额 decimal(18,8),
    --     当期认购金额不含税 decimal(18,8),
    --     当期签约面积 decimal(18,8),
    --     当期签约金额 decimal(18,8),
    --     当期签约金额不含税 decimal(18,8),
    --     盈利规划营业成本单方 decimal(18,8),
    --     土地款_单方 decimal(18,8),
    --     除地外直投_单方 decimal(18,8),
    --     开发间接费单方 decimal(18,8),
    --     资本化利息单方 decimal(18,8),
    --     盈利规划股权溢价单方 decimal(18,8),
    --     盈利规划营销费用单方 decimal(18,8),
    --     盈利规划综合管理费单方协议口径 decimal(18,8),
    --     盈利规划税金及附加单方 decimal(18,8),
    --     盈利规划营业成本认购 decimal(18,8),
    --     盈利规划股权溢价认购 decimal(18,8),
    --     毛利认购 decimal(18,8),
    --     毛利率认购 decimal(18,8),
    --     盈利规划营销费用认购 decimal(18,8),
    --     盈利规划综合管理费认购 decimal(18,8),
    --     盈利规划税金及附加认购 decimal(18,8),
    --     税前利润认购 decimal(18,8),
    --     所得税认购 decimal(18,8),
    --     净利润认购 decimal(18,8),
    --     销售净利率认购 decimal(18,8),
    --     盈利规划营业成本签约 decimal(18,8),
    --     盈利规划股权溢价签约 decimal(18,8),
    --     毛利签约 decimal(18,8),
    --     毛利率签约 decimal(18,8),
    --     盈利规划营销费用签约 decimal(18,8),
    --     盈利规划综合管理费签约 decimal(18,8),
    --     盈利规划税金及附加签约 decimal(18,8),
    --     税前利润签约 decimal(18,8),
    --     所得税签约 decimal(18,8),
    --     净利润签约 decimal(18,8),
    --     销售净利率签约 decimal(18,8),
    --     当期认购套数 decimal(18,8),
    --     当期签约套数 decimal(18,8),
    --     当期产成品签约金额 decimal(18,8),
    --     当期产成品签约金额不含税 decimal(18,8),
    --     产成品净利润签约 decimal(18,8),
    --     产成品销售净利率签约 decimal(18,8),
    --     是否调整单方比例 varchar(50)
    -- );

    -- 定义变量
    -- DECLARE @lastyear DATETIME; --去年
    -- DECLARE @lastyear_start DATETIME; --去年开始日期
    -- DECLARE @lastyear_end DATETIME; --去年结束日期

    --DECLARE @Thisyear DATETIME; --本年
    DECLARE @Thisyear_start DATETIME; --本年开始日期
    DECLARE @Thisyear_end DATETIME; --本年结束日期

    --DECLARE @Thismonth DATETIME; --本月
    DECLARE @Thismonth_start DATETIME; --本月开始日期
    DECLARE @Thismonth_end DATETIME; --本月结束日期

    --DECLARE @lastmonth DATETIME; --上月
    DECLARE @lastmonth_start DATETIME; --上月开始日期
    DECLARE @lastmonth_end DATETIME; --上月结束日期

    --DECLARE @lastlastmonth DATETIME; -- 上上月
    DECLARE @lastlastmonth_start DATETIME; --上上月开始日期
    DECLARE @lastlastmonth_end DATETIME; --上上月结束日期
    
    -- 设置日期
    -- SET @lastyear_start = DATEADD(yy, DATEDIFF(yy, 0, getdate()) - 1, 0);
    -- SET @lastyear_end =  dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))  

    SET @Thisyear_start = DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)  
    SET @Thisyear_end = dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate())+1, 0))  
    
    SET @Thismonth_start = DATEADD(month, DATEDIFF(month, 0, getdate()), 0);
    SET @Thismonth_end = DATEADD(ms, -3, DATEADD(month, DATEDIFF(month, 0, getdate()) + 1, 0));
    
    SET @lastmonth_start = DATEADD(mm,DATEDIFF(mm,0,dateadd(mm,-1,getdate())),0)
    SET @lastmonth_end =  DATEADD(ms,-3,DATEADD(mm,DATEDIFF(m,0,getdate()),0))
    
    SET @lastlastmonth_start = DATEADD(mm, DATEDIFF(mm, 0, DATEADD(mm, -2, GETDATE())), 0);
    SET @lastlastmonth_end = DATEADD(ms, -3, DATEADD(mm, DATEDIFF(mm, 0, DATEADD(mm, -1, GETDATE())), 0));

    -- -- 查询24年实际签约利润
    -- INSERT INTO #ylgh24
    -- -- 执行查询24年实际签约利润
    -- EXEC [172.16.4.141].erp25.dbo.[usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整] @buguid,@lastyear_start,@lastyear_end;

    INSERT INTO #ylgh25
    -- 执行查询25年签约利润
    EXEC [172.16.4.141].erp25.dbo.[usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整] @buguid,@Thisyear_start,'2025-06-30';

    INSERT INTO #ylgh_thismonth
    -- 执行查询本月实际签约利润
    EXEC [172.16.4.141].erp25.dbo.[usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整] @buguid,@lastmonth_start,@lastmonth_end;;

    -- 执行查询上月实际签约利润
    INSERT INTO #ylgh_lastmonth
    -- 执行查询上月实际签约利润
    EXEC [172.16.4.141].erp25.dbo.[usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整] @buguid,@lastlastmonth_start,@lastlastmonth_end;

    -- INSERT INTO #ylgh_lastlastmonth
    -- -- 执行查询上月实际签约利润
    -- EXEC [172.16.4.141].erp25.dbo.[usp_s_M002项目业态级毛利净利表_盈利规划单方锁定版调整] @buguid


    -- 删除当天的数据避免数据重复
    delete from 业态签约利润对比表 where datediff(day,清洗时间,getdate()) = 0
       -- 定义清洗版本
    declare @清洗版本 uniqueidentifier = newid()

    -- 查询结果数据
    -- 将业态签约利润基础数据与立项指标数据关联，形成最终的业态签约利润对比表
    --插入结果表
    insert into 业态签约利润对比表(
        清洗时间,
        清洗版本,
        -- 1、项目基础信息
        公司,
        项目GUID,
        投管代码,
        项目,
        推广名,
        获取日期,
        我方股比,
        是否并表,
        合作方,
        是否风险合作方,
        地上总可售面积,
        项目地价,
        盈利规划上线方式,
        产品类型,
        产品名称,
        装修标准,
        商品类型,
        明源匹配主键,
        业态组合键,
         -- 立项利润
        立项货值,
        税后利润,
        销售净利率,
        -- 24年签约利润
        签约_24年签约,
        签约不含税_24年签约,
        签约面积_24年签约,
        净利润_24年签约,
        报表利润_24年签约,
        净利率_24年签约,
        签约均价_24年签约,
        营业成本单方_24年签约,
        营销费用单方_24年签约,
        管理费用单方_24年签约,
        税金单方_24年签约,
        -- 25年度预算
        签约_25年预算,
        签约不含税_25年预算,
        签约面积_25年预算,
        签约个数_25年预算,
        净利润_25年预算,
        报表利润_25年预算,
        净利率_25年预算,
        签约均价_25年预算,
        营业成本单方_25年预算,
        营销费用单方_25年预算,
        管理费用单方_25年预算,
        税金单方_25年预算,
        -- 25年实际签约利润
        签约_25年签约,
        签约不含税_25年签约,
        签约面积_25年签约,
        净利润_25年签约,
        报表利润_25年签约,
        净利率_25年签约,
        签约均价_25年签约,
        营业成本单方_25年签约,
        营销费用单方_25年签约,
        管理费用单方_25年签约,
        税金单方_25年签约,

         --本月实际签约
        签约_本月实际,
        签约不含税_本月实际,
        签约面积_本月实际,
        签约均价_本月实际,
        认购_本月实际,
        认购不含税_本月实际,
        认购面积_本月实际,
        认购均价_本月实际,
        净利润_本月实际,
        净利率_本月实际,

        -- 上月实际签约
        签约_上月实际,
        签约不含税_上月实际,
        签约面积_上月实际,
        签约均价_上月实际,
        认购_上月实际,
        认购不含税_上月实际,
        认购面积_上月实际,
        认购均价_上月实际,
        净利润_上月实际,
        净利率_上月实际,

        -- 上上月实际签约
        签约_上上月实际,
        签约不含税_上上月实际,
        签约面积_上上月实际,
        签约均价_上上月实际,
        净利润_上上月实际,
        净利率_上上月实际
    )
    SELECT 
        getdate() as 清洗时间,
         @清洗版本 as 清洗版本,
        -- 1、项目基础信息
        a.公司,                  -- 公司名称
        a.项目GUID,              -- 项目唯一标识符
        a.投管代码,              -- 投资管理代码
        a.项目,                  -- 项目名称
        a.推广名,                -- 项目推广名称
        a.获取日期,              -- 项目获取日期
        a.我方股比 as 我方股比,              -- 我方持股比例
        a.是否并表,              -- 是否纳入合并报表范围
        a.合作方,                -- 合作方名称
        '' AS 是否风险合作方,    -- 是否风险合作方（预留字段）
        a.地上总可售面积 as 地上总可售面积,        -- 项目地上总可售面积
        a.项目地价 as 项目地价,              -- 项目地价
        a.盈利规划上线方式,      -- 盈利规划上线方式
        a.产品类型,              -- 产品类型
        a.产品名称,              -- 产品名称
        a.装修标准,              -- 装修标准
        a.商品类型,              -- 商品类型
        a.明源匹配主键,          -- 明源系统匹配主键
        a.业态组合键,            -- 业态组合键
        -- 立项利润
        b.立项总货值 as 立项总货值,            -- 立项阶段预计总货值
        b.税后利润 as 税后利润,              -- 立项阶段预计税后利润
        b.销售净利率 as 销售净利率,             -- 立项阶段预计销售净利率

        --24年实际签约利润
        c.签约_24年签约 as 签约_24年签约,
        c.签约不含税_24年签约 as 签约不含税_24年签约,
        null as 签约面积_24年签约,
        c.净利润_24年签约 as 净利润_24年签约,
        c.报表利润_24年签约 as 报表利润_24年签约,
        c.净利率_24年签约 as 净利率_24年签约 ,
        c.签约均价_24年签约 as  签约均价_24年签约,
        c.营业成本单方_24年签约 as 营业成本单方_24年签约,
        c.营销费用单方_24年签约 as 营销费用单方_24年签约,
        c.管理费用单方_24年签约 as 管理费用单方_24年签约,
        c.税金单方_24年签约 as 税金单方_24年签约,

        -- 25年预算数据
        a.签约_25年预算,
        a.签约不含税_25年预算,
        a.签约面积_25年预算,
        a.签约个数_25年预算,
        a.净利润_25年预算,
        convert(decimal(18,8), a.报表利润_25年预算) as 报表利润_25年预算,
        convert(decimal(18,8), a.净利率_25年预算) as 净利率_25年预算,
        convert(decimal(18,8), case when a.产品类型='地下室/车库' then
            case when  isnull(a.签约个数_25年预算,0) = 0 then 0 else isnull(a.签约_25年预算,0) / isnull(a.签约个数_25年预算,0) *100000000.0 end
        else
            case when  isnull(a.签约面积_25年预算,0) = 0 then 0 else isnull(a.签约_25年预算,0) / isnull(a.签约面积_25年预算,0) *10000.0 end
        end) as 签约均价_25年预算,
        a.营业成本单方_25年预算,
        a.营销费用单方_25年预算,
        a.管理费用单方_25年预算,
        a.税金单方_25年预算,   
        --25年实际签约利润
        d.当期签约金额 as 签约_25年签约,
        d.当期签约金额不含税 as 签约不含税_25年签约,
        d.当期签约面积 as 签约面积_25年签约,
        d.净利润签约 as 净利润_25年签约,
        convert(decimal(18,8), case when a.是否并表='我司并表' then d.净利润签约 else isnull(d.净利润签约,0) * a.我方股比 /100.0 end) as 报表利润_25年签约,
        d.销售净利率签约 as 净利率_25年签约 ,
        convert(decimal(18,8), case when d.产品类型='地下室/车库' then
            case when  isnull(d.当期签约面积,0) = 0 then 0 else d.当期签约金额 / d.当期签约面积 *100000000.0 end
        else
            case when  isnull(d.当期签约面积,0) = 0 then 0 else d.当期签约金额 / d.当期签约面积 *10000.0 end
        end) as 签约均价_25年签约,
        d.盈利规划营业成本单方 as 营业成本单方_25年签约,
        d.盈利规划营销费用单方 as 营销费用单方_25年签约,
        d.盈利规划综合管理费单方协议口径 as 管理费用单方_25年签约,
        d.盈利规划税金及附加单方 as 税金单方_25年签约,

        --本月实际签约
        e.当期签约金额 as 签约_本月实际,
        e.当期签约金额不含税 as 签约不含税_本月实际,
        e.当期签约面积 as 签约面积_本月实际,
        convert(decimal(18,8), case when e.产品类型='地下室/车库' then
            case when  isnull(e.当期签约面积,0) = 0 then 0 else e.当期签约金额 / e.当期签约面积 *100000000.0 end
        else
            case when  isnull(e.当期签约面积,0) = 0 then 0 else e.当期签约金额 / e.当期签约面积 *10000.0 end
        end) as 签约均价_本月实际,
        e.当期认购金额 as 认购_本月实际,
        e.当期认购金额不含税 as 认购不含税_本月实际,
        e.当期认购面积 as 认购面积_本月实际,
        convert(decimal(18,8), case when e.产品类型='地下室/车库' then
            case when  isnull(e.当期签约面积,0) = 0 then 0 else e.当期签约金额 / e.当期签约面积 *100000000.0 end
        else
            case when  isnull(e.当期签约面积,0) = 0 then 0 else e.当期签约金额 / e.当期签约面积 *10000.0 end
        end) as 认购均价_本月实际,
        e.净利润签约 as 净利润_本月实际,
        e.销售净利率签约 as 净利率_本月实际,

        -- 上月实际签约
        f.当期签约金额 as 签约_上月实际,
        f.当期签约金额不含税 as 签约不含税_上月实际,
        f.当期签约面积 as 签约面积_上月实际,
        convert(decimal(18,8), case when f.产品类型='地下室/车库' then
            case when  isnull(f.当期签约面积,0) = 0 then 0 else f.当期签约金额 / f.当期签约面积 *100000000.0 end
        else
            case when  isnull(f.当期签约面积,0) = 0 then 0 else f.当期签约金额 / f.当期签约面积 *10000.0 end
        end ) as 签约均价_上月实际,
        f.当期认购金额 as 认购_上月实际,
        f.当期认购金额不含税 as 认购不含税_上月实际,
        f.当期认购面积 as 认购面积_上月实际,
        convert(decimal(18,8), case when f.产品类型='地下室/车库' then
            case when  isnull(f.当期签约面积,0) = 0 then 0 else f.当期签约金额 / f.当期签约面积 *100000000.0 end
        else
            case when  isnull(f.当期签约面积,0) = 0 then 0 else f.当期签约金额 / f.当期签约面积 *10000.0 end
        end ) as 认购均价_上月实际,
        f.净利润签约 as 净利润_上月实际,
        f.销售净利率签约 as 净利率_上月实际,


        -- -- 上上月实际签约
        -- g.当期签约金额 as 签约_上上月实际,
        -- g.当期签约金额不含税 as 签约不含税_上上月实际,
        -- g.当期签约面积 as 签约面积_上上月实际,
        -- case when g.产品类型='地下室/车库' then
        --     case when  isnull(g.当期签约面积,0) = 0 then 0 else g.当期签约金额 / g.当期签约面积 *100000000.0 end
        -- else
        --     case when  isnull(g.当期签约面积,0) = 0 then 0 else g.当期签约金额 / g.当期签约面积 *10000.0 end
        -- end as 签约均价_上上月实际,
        -- g.净利润签约 as 净利润_上上月实际,
        -- g.销售净利率签约 as 净利率_上上月实际

        --  上上月实际签约
        NULL as 签约_上上月实际,
        NULL as 签约不含税_上上月实际,
        NULL as 签约面积_上上月实际,
        NULL as 签约均价_上上月实际,
        NULL as 净利润_上上月实际,
        NULL as 净利率_上上月实际

        -- 本次建安成本,
        -- 年初建安成本,
        -- 本次营销费用,
        -- 年初营销费用,
        -- 本次税金,
        -- 年初税金      
    FROM #ylghbase a             -- 业态签约利润基础数据临时表
    LEFT JOIN #lxindx b          -- 立项指标数据临时表
        ON a.项目GUID = b.ProjGUID           -- 通过项目GUID关联
        AND a.产品类型 = b.ProductType       -- 通过产品类型关联
        AND a.产品名称 = b.ProductName       -- 通过产品名称关联
        AND a.装修标准 = b.Standard          -- 通过装修标准关联
        AND a.商品类型 = b.BusinessType     -- 通过商品类型关联
    -- left join #ylgh24 c on a.项目GUID = c.ProjGUID and convert(varchar(2000),a.明源匹配主键) = c.明源匹配主键
    left join [24年签约利润] c on  a.项目GUID = c.项目GUID and convert(varchar(2000),a.明源匹配主键) = c.明源匹配主键
    left join #ylgh25 d on a.项目GUID = d.ProjGUID and convert(varchar(2000),a.明源匹配主键) = d.明源匹配主键
    left join #ylgh_thismonth e on a.项目GUID = e.ProjGUID and convert(varchar(2000),a.明源匹配主键) = e.明源匹配主键
    left join #ylgh_lastmonth f on a.项目GUID = f.ProjGUID and convert(varchar(2000),a.明源匹配主键) = f.明源匹配主键
    -- left join #ylgh_lastlastmonth g on a.项目GUID = g.ProjGUID and convert(varchar(2000),a.明源匹配主键) = g.明源匹配主键

end 



