USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_业态结转利润对比表_盈利规划单方锁定版调整]    Script Date: 2025/10/11 16:48:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
  功能：用于清洗《业态结转利润对比表》 用于总部财务动态利润监控看板,每天刷新
  create by chenjw  2025-06-11
   exec usp_s_业态结转利润对比表_盈利规划单方锁定版调整
*/

ALTER    procedure [dbo].[usp_s_业态结转利润对比表_盈利规划单方锁定版调整]
as
Begin 
-- alter table  业态结转利润对比表 add [本月结转签约面积_实际] [decimal](18, 2) NULL,
--         [本月结转签约_实际] [decimal](18, 2) NULL,
--         [本月结转签约不含税_实际] [decimal](18, 2) NULL,
--         [本月结转净利润_实际] [decimal](18, 2) NULL,
--         [本月结转报表利润_实际] [decimal](18, 2) NULL,
--         [本月结转净利率_实际] [decimal](18, 2) NULL,
--         [本月结转签约均价_实际] [decimal](18, 2) NULL,
--         [本月结转营业成本单方_实际] [decimal](18, 2) NULL,
--         [本月结转营销费用单方_实际] [decimal](18, 2) NULL,
--         [本月结转管理费用单方_实际] [decimal](18, 2) NULL,
--         [本月结转税金单方_实际] [decimal](18, 2) NULL
        
    -- DROP TABLE [dbo].[业态结转利润对比表]
    -- CREATE TABLE [dbo].[业态结转利润对比表](
    --     [清洗时间] [datetime] NULL,
    --     [清洗版本] [uniqueidentifier] NULL,
    --     [公司] [varchar](500) NULL,
    --     [项目GUID] [varchar](500) NULL,
    --     [投管代码] [varchar](500) NULL,
    --     [项目] [varchar](500) NULL,
    --     [推广名] [varchar](500) NULL,
    --     [获取日期] [datetime] NULL,
    --     [我方股比] [decimal](18, 2) NULL,
    --     [是否并表] [varchar](500) NULL,
    --     [合作方] [varchar](500) NULL,
    --     [是否风险合作方] [varchar](500) NULL,
    --     [地上总可售面积] [decimal](32, 2) NULL,
    --     [项目地价] [decimal](32, 2) NULL,
    --     [盈利规划上线方式] [varchar](500) NULL,
    --     [产品类型] [varchar](500) NULL,
    --     [产品名称] [varchar](500) NULL,
    --     [装修标准] [varchar](500) NULL,
    --     [商品类型] [varchar](500) NULL,
    --     [明源匹配主键] [varchar](2000) NULL,
    --     [业态组合键] [varchar](2000) NULL,
    --     [立项货值] [decimal](32, 2) NULL,
    --     [税后利润] [decimal](32, 2) NULL,
    --     [销售净利率] [decimal](18, 2) NULL,


    --     -- 预算数据
    --     [本年结转签约均价_预算] [decimal](18, 2) NULL,
    --     [营业成本单方_预算] [decimal](18, 2) NULL,
    --     [营销费用单方_预算] [decimal](18, 2) NULL,
    --     [管理费用单方_预算] [decimal](18, 2) NULL,
    --     [税金单方_预算] [decimal](18, 2) NULL,

    --     [本年结转签约面积_预算] [decimal](18, 2) NULL,
    --     [本年结转签约个数_预算] [decimal](18, 2) NULL,
    --     [本年结转签约_预算] [decimal](18, 2) NULL,
    --     [本年结转签约不含税_预算] [decimal](18, 2) NULL,
    --     [本年结转毛利_预算] [decimal](18, 2) NULL,
    --     [本年结转税前利润_预算] [decimal](18, 2) NULL,
    --     [本年结转净利润_预算] [decimal](18, 2) NULL,
    --     [本年结转净利率_预算] [decimal](18, 2) NULL,

    --     [第二年结转签约面积_预算] [decimal](18, 2) NULL,
    --     [第二年结转签约个数_预算] [decimal](18, 2) NULL,
    --     [第二年结转签约_预算] [decimal](18, 2) NULL,
    --     [第二年结转签约不含税_预算] [decimal](18, 2) NULL,
    --     [第二年结转毛利_预算] [decimal](18, 2) NULL,
    --     [第二年结转税前利润_预算] [decimal](18, 2) NULL,
    --     [第二年结转净利润_预算] [decimal](18, 2) NULL,
    --     [第二年结转净利率_预算] [decimal](18, 2) NULL,

    --     [第三年结转签约面积_预算] [decimal](18, 2) NULL,
    --     [第三年结转签约个数_预算] [decimal](18, 2) NULL,
    --     [第三年结转签约_预算] [decimal](18, 2) NULL,
    --     [第三年结转签约不含税_预算] [decimal](18, 2) NULL,
    --     [第三年结转毛利_预算] [decimal](18, 2) NULL,
    --     [第三年结转税前利润_预算] [decimal](18, 2) NULL,
    --     [第三年结转净利润_预算] [decimal](18, 2) NULL,
    --     [第三年结转净利率_预算] [decimal](18, 2) NULL,
    -- --     -- 实际结转数据
    --     [本年结转签约面积_实际] [decimal](18, 2) NULL,
    --     [本年结转签约_实际] [decimal](18, 2) NULL,
    --     [本年结转签约不含税_实际] [decimal](18, 2) NULL,
    --     [本年结转净利润_实际] [decimal](18, 2) NULL,
    --     [本年结转报表利润_实际] [decimal](18, 2) NULL,
    --     [本年结转净利率_实际] [decimal](18, 2) NULL,
    --     [本年结转签约均价_实际] [decimal](18, 2) NULL,
    --     [本年结转营业成本单方_实际] [decimal](18, 2) NULL,
    --     [本年结转营销费用单方_实际] [decimal](18, 2) NULL,
    --     [本年结转管理费用单方_实际] [decimal](18, 2) NULL,
    --     [本年结转税金单方_实际] [decimal](18, 2) NULL
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
    CASE WHEN 产品类型='地下室/车库' THEN 
       case when isnull(本年结转签约个数_修正版,0) =0 then  0  else  isnull(本年结转签约_修正版,0) *100000000.0 / isnull(本年结转签约个数_修正版,0) end
     ELSE 
      case when isnull(本年结转签约面积_修正版,0) =0 then  0  else  isnull(本年结转签约_修正版,0) *10000.0 / isnull(本年结转签约面积_修正版,0) end
    END AS 本年结转签约均价_预算, -- 车位按照套数计算
    isnull(营业成本单方_修正版,0) as 营业成本单方_预算,
    isnull(营销费用单方_修正版,0) as 营销费用单方_预算,
    isnull(综合管理费单方协议口径_修正版,0) as 管理费用单方_预算,
    isnull(税金及附加单方_修正版,0) as 税金单方_预算,

    -- 本年结转
    本年结转签约面积_修正版 AS 本年结转签约面积_预算,
    本年结转签约个数_修正版 AS 本年结转签约个数_预算,
    本年结转签约_修正版 AS 本年结转签约_预算,
    本年结转签约不含税_修正版 AS 本年结转签约不含税_预算,
    本年结转毛利_修正版 AS 本年结转毛利_预算,
    本年结转税前利润_修正版 AS 本年结转税前利润_预算,
    本年结转净利润_修正版 AS 本年结转净利润_预算,
    case when isnull(本年结转签约不含税_修正版,0) =0 then  0  else  isnull(本年结转净利润_修正版,0)  / isnull(本年结转签约不含税_修正版,0) end AS 本年结转净利率_预算,
    -- 第二年结转
    第二年结转签约面积_修正版 AS 第二年结转签约面积_预算,
    第二年结转签约个数_修正版 AS 第二年结转签约个数_预算,
    第二年结转签约_修正版 AS 第二年结转签约_预算,
    第二年结转签约不含税_修正版 AS 第二年结转签约不含税_预算,
    第二年结转毛利_修正版 AS 第二年结转毛利_预算,
    第二年结转税前利润_修正版 AS 第二年结转税前利润_预算,
    第二年结转净利润_修正版 AS 第二年结转净利润_预算,
    case when isnull(第二年结转签约不含税_修正版,0) =0 then  0  else  isnull(第二年结转净利润_修正版,0)  / isnull(第二年结转签约不含税_修正版,0) end  AS 第二年结转净利率_预算,
    -- 第三年结转   
    第三年结转签约面积_修正版 AS 第三年结转签约面积_预算,
    第三年结转签约个数_修正版 AS 第三年结转签约个数_预算,
    第三年结转签约_修正版 AS 第三年结转签约_预算,
    第三年结转签约不含税_修正版 AS 第三年结转签约不含税_预算,
    第三年结转毛利_修正版 AS 第三年结转毛利_预算,
    第三年结转税前利润_修正版 AS 第三年结转税前利润_预算,
    第三年结转净利润_修正版 AS 第三年结转净利润_预算,
    case when isnull(第三年结转签约不含税_修正版,0) =0 then  0  else  isnull(第三年结转净利润_修正版,0)  / isnull(第三年结转签约不含税_修正版,0) end  AS 第三年结转净利率_预算
 INTO #ylghbase
FROM data_tb_ylghProfit;

-- 统计项目层级的立项利润
SELECT 
    b.ProjGUID,
    b.ProductType,
    b.ProductName,
    b.BusinessType,
    b.Standard,
    SUM(ISNULL(a.CashInflowTax*10000.0, 0)) AS 立项总货值, -- 现金流入（含税）
    SUM(ISNULL(a.AfterTaxProfit*10000.0, 0)) AS 税后利润,
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
    
    -- 创建临时表
    CREATE TABLE #ylghjzlr
    (
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
        Productnocode varchar(500),
        当期认购面积 decimal(18, 8),
        当期认购金额 decimal(18, 8),
        当期认购金额不含税 decimal(18, 8),
        当期签约面积 decimal(18, 8),
        当期签约金额 decimal(18, 8),
        当期签约金额不含税 decimal(18, 8),
        盈利规划营业成本单方 decimal(18, 8),
        土地款_单方 decimal(18, 8),
        除地外直投_单方 decimal(18, 8),
        开发间接费单方 decimal(18, 8),
        资本化利息单方 decimal(18, 8),
        盈利规划股权溢价单方 decimal(18, 8),
        盈利规划营销费用单方 decimal(18, 8),
        盈利规划综合管理费单方协议口径 decimal(18, 8),
        盈利规划税金及附加单方 decimal(18, 8),
        盈利规划营业成本认购 decimal(18, 8),
        盈利规划股权溢价认购 decimal(18, 8),
        毛利认购 decimal(18, 8),
        毛利率认购 decimal(18, 8),
        盈利规划营销费用认购 decimal(18, 8),
        盈利规划综合管理费认购 decimal(18, 8),
        盈利规划税金及附加认购 decimal(18, 8),
        税前利润认购 decimal(18, 8),
        所得税认购 decimal(18, 8),
        净利润认购 decimal(18, 8),
        销售净利率认购 decimal(18, 8),
        盈利规划营业成本签约 decimal(18, 8),
        盈利规划股权溢价签约 decimal(18, 8),
        毛利签约 decimal(18, 8),
        毛利率签约 decimal(18, 8),
        盈利规划营销费用签约 decimal(18, 8),
        盈利规划综合管理费签约 decimal(18, 8),
        盈利规划税金及附加签约 decimal(18, 8),
        税前利润签约 decimal(18, 8),
        所得税签约 decimal(18, 8),
        净利润签约 decimal(18, 8),
        销售净利率签约 decimal(18, 8),
        当期认购套数 decimal(18, 8),
        当期签约套数 decimal(18, 8),
        当期产成品签约金额 decimal(18, 8),
        当期产成品签约金额不含税 decimal(18, 8),
        产成品净利润签约 decimal(18, 8),
        产成品销售净利率签约 decimal(18, 8),
        平均款清率 decimal(18, 8),
        结转面积2401 decimal(18, 8),
        结转金额2401 decimal(18, 8),
        结转金额不含税2401 decimal(18, 8),
        结转利润2401 decimal(18, 8),
        结转面积2402 decimal(18, 8),
        结转金额2402 decimal(18, 8),
        结转金额不含税2402 decimal(18, 8),
        结转利润2402 decimal(18, 8),
        结转面积2403 decimal(18, 8),
        结转金额2403 decimal(18, 8),
        结转金额不含税2403 decimal(18, 8),
        结转利润2403 decimal(18, 8),
        结转面积2404 decimal(18, 8),
        结转金额2404 decimal(18, 8),
        结转金额不含税2404 decimal(18, 8),
        结转利润2404 decimal(18, 8),
        -- 25年结转数据
        结转面积2501 decimal(18, 8),
        结转金额2501 decimal(18, 8),
        结转金额不含税2501 decimal(18, 8),
        结转利润2501 decimal(18, 8),
        结转面积2502 decimal(18, 8),
        结转金额2502 decimal(18, 8),
        结转金额不含税2502 decimal(18, 8),
        结转利润2502 decimal(18, 8),
        结转面积2503 decimal(18, 8),
        结转金额2503 decimal(18, 8),
        结转金额不含税2503 decimal(18, 8),
        结转利润2503 decimal(18, 8),
        结转面积2504 decimal(18, 8),
        结转金额2504 decimal(18, 8),
        结转金额不含税2504 decimal(18, 8),
        结转利润2504 decimal(18, 8),
        -- 26年结转数据
        结转面积2601 decimal(18, 8),
        结转金额2601 decimal(18, 8),
        结转金额不含税2601 decimal(18, 8),
        结转利润2601 decimal(18, 8),
        结转面积2602 decimal(18, 8),
        结转金额2602 decimal(18, 8),
        结转金额不含税2602 decimal(18, 8),
        结转利润2602 decimal(18, 8),
        结转面积2603 decimal(18, 8),
        结转金额2603 decimal(18, 8),
        结转金额不含税2603 decimal(18, 8),
        结转利润2603 decimal(18, 8),
        结转面积2604 decimal(18, 8),
        结转金额2604 decimal(18, 8),
        结转金额不含税2604 decimal(18, 8),
        结转利润2604 decimal(18, 8),
        -- 27年结转数据
        结转面积2701 decimal(18, 8),
        结转金额2701 decimal(18, 8),
        结转金额不含税2701 decimal(18, 8),
        结转利润2701 decimal(18, 8),
        结转面积2702 decimal(18, 8),
        结转金额2702 decimal(18, 8),
        结转金额不含税2702 decimal(18, 8),
        结转利润2702 decimal(18, 8),
        结转面积2703 decimal(18, 8),
        结转金额2703 decimal(18, 8),
        结转金额不含税2703 decimal(18, 8),
        结转利润2703 decimal(18, 8),
        结转面积2704 decimal(18, 8),
        结转金额2704 decimal(18, 8),
        结转金额不含税2704 decimal(18, 8),
        结转利润2704 decimal(18, 8),

        结转面积26 decimal(18, 8),
        结转金额26 decimal(18, 8),
        结转金额不含税26 decimal(18, 8),
        结转利润26 decimal(18, 8),
        结转面积27 decimal(18, 8),
        结转金额27 decimal(18, 8),
        结转金额不含税27 decimal(18, 8),
        结转利润27 decimal(18, 8),
        结转面积28plus decimal(18, 8),
        结转金额28plus decimal(18, 8),
        结转金额不含税28plus decimal(18, 8),
        结转利润28plus decimal(18, 8),

        当期签约结转面积 decimal(18, 8),
        当期签约结转金额 decimal(18, 8),
        当期签约结转金额不含税 decimal(18, 8),
        当期签约结转成本 decimal(18, 8),
        当期签约结转溢价签约 decimal(18, 8),
        当期签约结转营销费 decimal(18, 8),
        当期签约结转管理费 decimal(18, 8),
        当期签约结转税金及签约 decimal(18, 8),
        当期签约结转税前利润 decimal(18, 8),
        当期签约结转所得税 decimal(18, 8),
        当期签约结转净利润 decimal(18, 8),
        当期签约结转净利率 decimal(18, 8),
        是否调整单方比例 varchar(500)
    );
    --本月结转数据
 CREATE TABLE #ylghjzlrby
    (
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
        Productnocode varchar(500),
        当期认购面积 decimal(18, 8),
        当期认购金额 decimal(18, 8),
        当期认购金额不含税 decimal(18, 8),
        当期签约面积 decimal(18, 8),
        当期签约金额 decimal(18, 8),
        当期签约金额不含税 decimal(18, 8),
        盈利规划营业成本单方 decimal(18, 8),
        土地款_单方 decimal(18, 8),
        除地外直投_单方 decimal(18, 8),
        开发间接费单方 decimal(18, 8),
        资本化利息单方 decimal(18, 8),
        盈利规划股权溢价单方 decimal(18, 8),
        盈利规划营销费用单方 decimal(18, 8),
        盈利规划综合管理费单方协议口径 decimal(18, 8),
        盈利规划税金及附加单方 decimal(18, 8),
        盈利规划营业成本认购 decimal(18, 8),
        盈利规划股权溢价认购 decimal(18, 8),
        毛利认购 decimal(18, 8),
        毛利率认购 decimal(18, 8),
        盈利规划营销费用认购 decimal(18, 8),
        盈利规划综合管理费认购 decimal(18, 8),
        盈利规划税金及附加认购 decimal(18, 8),
        税前利润认购 decimal(18, 8),
        所得税认购 decimal(18, 8),
        净利润认购 decimal(18, 8),
        销售净利率认购 decimal(18, 8),
        盈利规划营业成本签约 decimal(18, 8),
        盈利规划股权溢价签约 decimal(18, 8),
        毛利签约 decimal(18, 8),
        毛利率签约 decimal(18, 8),
        盈利规划营销费用签约 decimal(18, 8),
        盈利规划综合管理费签约 decimal(18, 8),
        盈利规划税金及附加签约 decimal(18, 8),
        税前利润签约 decimal(18, 8),
        所得税签约 decimal(18, 8),
        净利润签约 decimal(18, 8),
        销售净利率签约 decimal(18, 8),
        当期认购套数 decimal(18, 8),
        当期签约套数 decimal(18, 8),
        当期产成品签约金额 decimal(18, 8),
        当期产成品签约金额不含税 decimal(18, 8),
        产成品净利润签约 decimal(18, 8),
        产成品销售净利率签约 decimal(18, 8),
        平均款清率 decimal(18, 8),
        结转面积2401 decimal(18, 8),
        结转金额2401 decimal(18, 8),
        结转金额不含税2401 decimal(18, 8),
        结转利润2401 decimal(18, 8),
        结转面积2402 decimal(18, 8),
        结转金额2402 decimal(18, 8),
        结转金额不含税2402 decimal(18, 8),
        结转利润2402 decimal(18, 8),
        结转面积2403 decimal(18, 8),
        结转金额2403 decimal(18, 8),
        结转金额不含税2403 decimal(18, 8),
        结转利润2403 decimal(18, 8),
        结转面积2404 decimal(18, 8),
        结转金额2404 decimal(18, 8),
        结转金额不含税2404 decimal(18, 8),
        结转利润2404 decimal(18, 8),
        结转面积2501 decimal(18, 8),
        结转金额2501 decimal(18, 8),
        结转金额不含税2501 decimal(18, 8),
        结转利润2501 decimal(18, 8),
        结转面积2502 decimal(18, 8),
        结转金额2502 decimal(18, 8),
        结转金额不含税2502 decimal(18, 8),
        结转利润2502 decimal(18, 8),
        结转面积2503 decimal(18, 8),
        结转金额2503 decimal(18, 8),
        结转金额不含税2503 decimal(18, 8),
        结转利润2503 decimal(18, 8),
        结转面积2504 decimal(18, 8),
        结转金额2504 decimal(18, 8),
        结转金额不含税2504 decimal(18, 8),
        结转利润2504 decimal(18, 8),
        -- 26年结转数据
        结转面积2601 decimal(18, 8),
        结转金额2601 decimal(18, 8),
        结转金额不含税2601 decimal(18, 8),
        结转利润2601 decimal(18, 8),
        结转面积2602 decimal(18, 8),
        结转金额2602 decimal(18, 8),
        结转金额不含税2602 decimal(18, 8),
        结转利润2602 decimal(18, 8),
        结转面积2603 decimal(18, 8),
        结转金额2603 decimal(18, 8),
        结转金额不含税2603 decimal(18, 8),
        结转利润2603 decimal(18, 8),
        结转面积2604 decimal(18, 8),
        结转金额2604 decimal(18, 8),
        结转金额不含税2604 decimal(18, 8),
        结转利润2604 decimal(18, 8),
        -- 27年结转数据
        结转面积2701 decimal(18, 8),
        结转金额2701 decimal(18, 8),
        结转金额不含税2701 decimal(18, 8),
        结转利润2701 decimal(18, 8),
        结转面积2702 decimal(18, 8),
        结转金额2702 decimal(18, 8),
        结转金额不含税2702 decimal(18, 8),
        结转利润2702 decimal(18, 8),
        结转面积2703 decimal(18, 8),
        结转金额2703 decimal(18, 8),
        结转金额不含税2703 decimal(18, 8),
        结转利润2703 decimal(18, 8),
        结转面积2704 decimal(18, 8),
        结转金额2704 decimal(18, 8),
        结转金额不含税2704 decimal(18, 8),
        结转利润2704 decimal(18, 8),

        结转面积26 decimal(18, 8),
        结转金额26 decimal(18, 8),
        结转金额不含税26 decimal(18, 8),
        结转利润26 decimal(18, 8),
        结转面积27 decimal(18, 8),
        结转金额27 decimal(18, 8),
        结转金额不含税27 decimal(18, 8),
        结转利润27 decimal(18, 8),
        结转面积28plus decimal(18, 8),
        结转金额28plus decimal(18, 8),
        结转金额不含税28plus decimal(18, 8),
        结转利润28plus decimal(18, 8),

        当期签约结转面积 decimal(18, 8),
        当期签约结转金额 decimal(18, 8),
        当期签约结转金额不含税 decimal(18, 8),
        当期签约结转成本 decimal(18, 8),
        当期签约结转溢价签约 decimal(18, 8),
        当期签约结转营销费 decimal(18, 8),
        当期签约结转管理费 decimal(18, 8),
        当期签约结转税金及签约 decimal(18, 8),
        当期签约结转税前利润 decimal(18, 8),
        当期签约结转所得税 decimal(18, 8),
        当期签约结转净利润 decimal(18, 8),
        当期签约结转净利率 decimal(18, 8),
        是否调整单方比例 varchar(500)
    );

    -- 定义时间变量
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

    -- 执行存储过程
    insert into #ylghjzlr
    exec [172.16.4.141].erp25.dbo.usp_s_m00201当年签约结转数据_盈利规划单方锁定版调整 @buguid ,@Thisyear_start,@lastmonth_end
    --exec [172.16.4.141].erp25.dbo.usp_s_m00201当年签约结转数据_盈利规划单方锁定版调整 @buguid ,@Thisyear_start,'2025-09-28'
    -- 本月结转数据
    insert into #ylghjzlrby
    exec [172.16.4.141].erp25.dbo.usp_s_m00201当年签约结转数据_盈利规划单方锁定版调整 @buguid ,@lastmonth_start,@lastmonth_end
   -- exec [172.16.4.141].erp25.dbo.usp_s_m00201当年签约结转数据_盈利规划单方锁定版调整 @buguid ,'2025-09-01','2025-09-28'

    -- 删除当天的数据避免数据重复   
    delete from 业态结转利润对比表 where datediff(day,清洗时间,getdate()) = 0
    
    -- 定义清洗版本
    declare @清洗版本 uniqueidentifier = newid()

    -- 查询结果数据
    -- 将业态签约利润基础数据与立项指标数据关联，形成最终的业态签约利润对比表
    --插入结果表
    insert into 业态结转利润对比表(
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
      
        -- 预算数据
        本年结转签约均价_预算,
        营业成本单方_预算,
        营销费用单方_预算,
        管理费用单方_预算,
        税金单方_预算,
        -- 本年结转预算
        本年结转签约面积_预算,
        本年结转签约个数_预算,
        本年结转签约_预算,
        本年结转签约不含税_预算,
        本年结转毛利_预算,
        本年结转税前利润_预算,
        本年结转净利润_预算,
        本年结转净利率_预算,
        -- 第二年结转预算
        第二年结转签约面积_预算,
        第二年结转签约个数_预算,
        第二年结转签约_预算,
        第二年结转签约不含税_预算,
        第二年结转毛利_预算,
        第二年结转税前利润_预算,
        第二年结转净利润_预算,
        第二年结转净利率_预算,
        -- 第三年结转预算
        第三年结转签约面积_预算,
        第三年结转签约个数_预算,
        第三年结转签约_预算,
        第三年结转签约不含税_预算,
        第三年结转毛利_预算,
        第三年结转税前利润_预算,
        第三年结转净利润_预算,
        第三年结转净利率_预算,

        -- 实际结转数据
        [本年结转签约面积_实际] ,
        [本年结转签约_实际] ,
        [本年结转签约不含税_实际] ,
        [本年结转净利润_实际] ,
        [本年结转报表利润_实际] ,
        [本年结转净利率_实际] ,
        [本年结转签约均价_实际] ,
        [本年结转营业成本单方_实际] ,
        [本年结转营销费用单方_实际] ,
        [本年结转管理费用单方_实际] ,
        [本年结转税金单方_实际],

        [本月结转签约面积_实际] ,
        [本月结转签约_实际] ,
        [本月结转签约不含税_实际] ,
        [本月结转净利润_实际] ,
        [本月结转报表利润_实际] ,
        [本月结转净利率_实际] ,
        [本月结转签约均价_实际] ,
        [本月结转营业成本单方_实际] ,
        [本月结转营销费用单方_实际] ,
        [本月结转管理费用单方_实际] ,
        [本月结转税金单方_实际],

        [第二年结转面积_实际] ,
        [第二年结转金额_实际] ,
        [第二年结转金额不含税_实际] ,
        [第二年结转利润_实际] ,

        [第三年结转面积_实际] ,
        [第三年结转金额_实际] ,
        [第三年结转金额不含税_实际] ,
        [第三年结转利润_实际] ,

        [第四年及之后结转面积_实际] ,
        [第四年及之后结转金额_实际] ,
        [第四年及之后结转金额不含税_实际] ,
        [第四年及之后结转利润_实际] 
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
        a.我方股比,              -- 我方持股比例
        a.是否并表,              -- 是否纳入合并报表范围
        a.合作方,                -- 合作方名称
        '' AS 是否风险合作方,    -- 是否风险合作方（预留字段）
        a.地上总可售面积,        -- 项目地上总可售面积
        a.项目地价,              -- 项目地价
        a.盈利规划上线方式,      -- 盈利规划上线方式
        a.产品类型,              -- 产品类型
        a.产品名称,              -- 产品名称
        a.装修标准,              -- 装修标准
        a.商品类型,              -- 商品类型
        a.明源匹配主键,          -- 明源系统匹配主键
        a.业态组合键,            -- 业态组合键
        -- 立项利润
        b.立项总货值,            -- 立项阶段预计总货值
        b.税后利润,              -- 立项阶段预计税后利润
        b.销售净利率,             -- 立项阶段预计销售净利率

        -- 预算数据
        a.本年结转签约均价_预算,
        a.营业成本单方_预算,
        a.营销费用单方_预算,
        a.管理费用单方_预算,
        a.税金单方_预算,
        a.本年结转签约面积_预算,
        a.本年结转签约个数_预算,
        a.本年结转签约_预算,
        a.本年结转签约不含税_预算,
        a.本年结转毛利_预算,
        a.本年结转税前利润_预算,
        a.本年结转净利润_预算,
        a.本年结转净利率_预算,

        -- 第二年结转预算
        a.第二年结转签约面积_预算,
        a.第二年结转签约个数_预算,
        a.第二年结转签约_预算,
        a.第二年结转签约不含税_预算,
        a.第二年结转毛利_预算,
        a.第二年结转税前利润_预算,
        a.第二年结转净利润_预算,
        a.第二年结转净利率_预算,

        -- 第三年结转预算
        a.第三年结转签约面积_预算,
        a.第三年结转签约个数_预算,
        a.第三年结转签约_预算,
        a.第三年结转签约不含税_预算,
        a.第三年结转毛利_预算,
        a.第三年结转税前利润_预算,
        a.第三年结转净利润_预算,
        a.第三年结转净利率_预算,
        -- 实际结转数据
        c.当期签约结转面积 as 本年结转签约面积_实际,
        c.当期签约结转金额 as 本年结转签约_实际,
        c.当期签约结转金额不含税 as 本年结转签约不含税_实际,
        c.当期签约结转净利润 as 本年结转净利润_实际,
        convert(decimal(18,8), case when a.是否并表='我司并表' then c.当期签约结转净利润 else isnull(c.当期签约结转净利润,0) * a.我方股比 /100.0 end) as [本年结转报表利润_实际] ,
        c.当期签约结转净利率 as 本年结转净利率_实际,
        convert(decimal(18,8), case when c.产品类型='地下室/车库' then
            case when  isnull(c.当期签约结转面积,0) = 0 then 0 else c.当期签约结转金额 / c.当期签约结转面积 *100000000.0 end
        else
            case when  isnull(c.当期签约结转面积,0) = 0 then 0 else c.当期签约结转金额 / c.当期签约结转面积 *10000.0 end
        end) as   [本年结转签约均价_实际] ,
        c.盈利规划营业成本单方 as [本年结转营业成本单方_实际] ,
        c.盈利规划营销费用单方 as [本年结转营销费用单方_实际] ,
        c.盈利规划综合管理费单方协议口径 as [本年结转管理费用单方_实际] ,
        c.盈利规划税金及附加单方 as [本年结转税金单方_实际],

        -- 本月实际结转数据
        d.当期签约结转面积 as 本月结转签约面积_实际,
        d.当期签约结转金额 as 本月结转签约_实际,
        d.当期签约结转金额不含税 as 本月结转签约不含税_实际,
        d.当期签约结转净利润 as 本月结转净利润_实际,
        convert(decimal(18,8), case when a.是否并表='我司并表' then d.当期签约结转净利润 else isnull(d.当期签约结转净利润,0) * a.我方股比 /100.0 end) as [本月结转报表利润_实际] ,
        d.当期签约结转净利率 as 本月结转净利率_实际,
        convert(decimal(18,8), case when d.产品类型='地下室/车库' then
            case when  isnull(d.当期签约结转面积,0) = 0 then 0 else d.当期签约结转金额 / d.当期签约结转面积 *100000000.0 end
        else
            case when  isnull(d.当期签约结转面积,0) = 0 then 0 else d.当期签约结转金额 / d.当期签约结转面积 *10000.0 end
        end) as   [本月结转签约均价_实际] ,
        d.盈利规划营业成本单方 as [本月结转营业成本单方_实际] ,
        d.盈利规划营销费用单方 as [本月结转营销费用单方_实际] ,
        d.盈利规划综合管理费单方协议口径 as [本月结转管理费用单方_实际] ,
        d.盈利规划税金及附加单方 as [本月结转税金单方_实际],

        c.结转面积26 as [第二年结转面积_实际] ,
        c.结转金额26 as [第二年结转金额_实际] ,
        c.结转金额不含税26 as [第二年结转金额不含税_实际] ,
        c.结转利润26 as [第二年结转利润_实际] ,

        c.结转面积27 as [第三年结转面积_实际] ,
        c.结转金额27 as [第三年结转金额_实际] ,
        c.结转金额不含税27 as [第三年结转金额不含税_实际] ,
        c.结转利润27 as [第三年结转利润_实际] ,

        c.结转面积28plus as [第四年及之后结转面积_实际] ,
        c.结转金额28plus as [第四年及之后结转金额_实际] ,
        c.结转金额不含税28plus as [第四年及之后结转金额不含税_实际] ,
        c.结转利润28plus as [第四年及之后结转利润_实际] 
    FROM #ylghbase a             -- 业态签约利润基础数据临时表
    LEFT JOIN #lxindx b          -- 立项指标数据临时表
        ON a.项目GUID = b.ProjGUID           -- 通过项目GUID关联
        AND a.产品类型 = b.ProductType       -- 通过产品类型关联
        AND a.产品名称 = b.ProductName       -- 通过产品名称关联
        AND a.装修标准 = b.Standard          -- 通过装修标准关联
        AND a.商品类型 = b.BusinessType     -- 通过商品类型关联
    left join #ylghjzlr c on a.项目GUID = c.ProjGUID and convert(varchar(2000),a.明源匹配主键) = c.明源匹配主键
    left join #ylghjzlrby d on a.项目GUID = d.ProjGUID and convert(varchar(2000),a.明源匹配主键) = d.明源匹配主键
    -- left join #ylgh25 d on a.项目GUID = d.ProjGUID and convert(varchar(2000),a.明源匹配主键) = d.明源匹配主键


end 