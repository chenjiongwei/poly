USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_dw_f_TopProj_Filltab_Fact]    Script Date: 2025/5/27 9:50:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_dw_f_TopProj_Filltab_Fact]
AS
/*
表名：项目填报实际值汇总表
用途：收集项目填报情况,用于保利自定义分析

author:lintx
date:20210603

modified by lintx 2022-11-30
1、调整取最新填报版本的数据

运行样例：usp_dw_f_TopProj_Filltab_Fact

modified by chenjw 2025-05-22
1、如果集团 当AA001报表10号还没上线时，就先取BA005和BA006的数据，总部已经三个月没更AA001
data_wide_dws_ys_ys_DssCashFlowData -- 总部填报表版本
data_wide_dws_ys_DssCashFlowDataCompany  -- 平台公司填报版本

modified by chenjw 2025-05-27
累计建安费用、本年建安费用、本月建安费用 的取数口径，直接从data_wide_dws_ys_DssCashFlowDataCompany表中取数
*/

BEGIN

    --创建临时表 
    SELECT *
    INTO #tmp_dw_f_TopProj_Filltab_Fact
    FROM dw_f_TopProj_Filltab_Fact
    WHERE 1 = 2;

	---获取总部填报数据
	 SELECT NEWID() 项目填报Guid,
		   pj.ProjGUID 项目Guid,
		   pj.SpreadName 项目名称,
		   year 年,
		   month 月,
		   YLBFullInvestmentIRR  AS 三年盈利项目全投资IRR,
		   InvestmentAmountTotal  AS 累计总投资金额,
		   LoanBalanceTotal  AS 累计贷款余额,
		   CollectionAmountTotal  AS 累计回笼金额,
		   LandCostTotal  AS 累计直接投资土地费用,
		   DirectInvestmentTotal  AS 累计直接投资,
		   TaxTotal  AS 累计税金,
		   ExpenseTotal  AS 累计三费,
		   YearInvestmentAmount   AS 本年总投资金额,
		   YearLoanBalance   AS 本年贷款金额,
		   YearCollectionAmount   AS 本年回笼金额,
		   YearDirectInvestment   AS 本年累计直接投资,
		   YearLandCost   AS 本年直接投资土地费用,
		   YearTax   AS 本年税金,
		   YearExpense   AS 本年三费,
		   MonthInvestmentAmount   AS 本月总投资金额,
		   MonthLoanBalance   AS 本月贷款金额,
		   MonthCollectionAmount   AS 本月回笼金额,
		   MonthDirectInvestment   AS 本月累计直接投资,
		   MonthLandCost   AS 本月直接投资土地费用,
		   MonthTax   AS 本月税金,
		   MonthExpense   AS 本月三费,
		   YearNetIncreaseLoan   AS 本年净增贷款,
		   YearfinancingAmount   AS 本年实际融资,
		   BuyProjAmount  AS 收购对价,
		   ActualOFCFReturnabilityDate  AS 实际现金流回正日期,
		   ActualOCFRetDate  AS 实际收回股东投资日期,
		   YLBOwnFundsIRR  AS 三年盈利项目自有资金IRR,
		   SjSgdj  AS 实际收购对价,
		   MonthNetIncreaseLoan   AS 本月净增贷款,
		   r.JaInvestmentAmount as 累计建安费用,
		   r.YearJaInvestmentAmount as 本年建安费用,
		   r.MonthJaInvestmentAmount as 本月建安费用,
		   (ISNULL(CollectionAmountTotal, 0)
                     - ISNULL(DirectInvestmentTotal, 0)
                      - ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0)) as 累计经营性现金流,
		   ISNULL(YearCollectionAmount, 0)
                     - ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0)
                     - ISNULL(YearExpense, 0)  as 本年经营性现金流,
		   ISNULL(MonthCollectionAmount, 0)
                     - ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0)
                     - ISNULL(MonthExpense, 0)  as 本月经营性现金流,
			(ISNULL(CollectionAmountTotal, 0)
                     - ISNULL(DirectInvestmentTotal, 0)
                     - ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0))*pj.EquityRatio/100.0 as 累计权益经营性现金流,
		   (ISNULL(YearCollectionAmount, 0)
                     - ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0)
                     - ISNULL(YearExpense, 0))*pj.EquityRatio/100.0 as 本年权益经营性现金流,
		   (ISNULL(MonthCollectionAmount, 0)
                     - ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0)
                     - ISNULL(MonthExpense, 0))*pj.EquityRatio/100.0  as 本月权益经营性现金流,
		   (ISNULL(CollectionAmountTotal, 0)
                     + ISNULL(LoanBalanceTotal, 0)
                     - ISNULL(DirectInvestmentTotal, 0)
                     - ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0)) as 累计股东投资回收金额,
		   ISNULL(YearCollectionAmount, 0)
                     + ISNULL(YearNetIncreaseLoan, 0)
                     - ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0)
                     - ISNULL(YearExpense, 0)   as 本年股东投资回收金额,
		   ISNULL(MonthCollectionAmount, 0)
                     + ISNULL(MonthNetIncreaseLoan, 0)
                     - ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0)
                     - ISNULL(MonthExpense, 0) as 本月股东投资回收金额,
		   r.DevelopmentLoans as 开发贷款余额,
		   r.SupplyChainLoan as 供应链融资余额,
		   r.yearDevelopmentLoans as 本年净增开发贷,
		   r.yearSupplyChainLoan as 本年净增供应链融资
	into #zbtb
	FROM HighData_prod.dbo.data_wide_dws_mdm_Project pj
		inner JOIN HighData_prod.dbo.data_wide_dws_ys_ys_DssCashFlowData r ON pj.ProjGUID = r.ProjGUID
		where r.VersionGUID = (SELECT TOP 1   VersionGUID
                                     FROM   dbo.data_wide_dws_ys_ys_DssCashFlowData cf
                                            INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = cf.ProjGUID
                                     --WHERE  p.BUGUID NOT IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', 'B2770421-F2D0-421C-B210-E6C7EF71B270' )
                                     GROUP BY VersionGUID ,
                                              Year ,
                                              CONVERT(INT, Month)
                                     HAVING SUM(DirectInvestmentTotal) > 0
                                     ORDER BY Year DESC ,
                                              CONVERT(INT, Month) DESC);  

    -- 获取平台公司填报数据
	SELECT 
		NEWID() 项目填报Guid,
		pj.ProjGUID 项目Guid,
		pj.SpreadName 项目名称,
		r.year 年,
		r.month 月,
		null  AS 三年盈利项目全投资IRR,
		InvestmentAmountTotal  AS 累计总投资金额,
		LoanBalanceTotal  AS 累计贷款余额,
		CollectionAmountTotal  AS 累计回笼金额,
		LandCostTotal  AS 累计直接投资土地费用,
		DirectInvestmentTotal  AS 累计直接投资,
		TaxTotal  AS 累计税金,
		ExpenseTotal  AS 累计三费,
		YearInvestmentAmount   AS 本年总投资金额,
		YearLoanBalance   AS 本年贷款金额,
		YearCollectionAmount   AS 本年回笼金额,
		YearDirectInvestment   AS 本年累计直接投资,
		YearLandCost   AS 本年直接投资土地费用,
		YearTax   AS 本年税金,
		YearExpense   AS 本年三费,
		MonthInvestmentAmount   AS 本月总投资金额,
		MonthLoanBalance   AS 本月贷款金额,
		MonthCollectionAmount   AS 本月回笼金额,
		MonthDirectInvestment   AS 本月累计直接投资,
		MonthLandCost   AS 本月直接投资土地费用,
		MonthTax   AS 本月税金,
		MonthExpense   AS 本月三费,
		YearNetIncreaseLoan   AS 本年净增贷款,
		null  AS 本年实际融资,
		null  AS 收购对价,
		null   AS 实际现金流回正日期,
		null  AS 实际收回股东投资日期,
		null  AS 三年盈利项目自有资金IRR,
		null  AS 实际收购对价,
		MonthNetIncreaseLoan   AS 本月净增贷款,
		r.JaInvestmentTotal as 累计建安费用,
		r.YearJaInvestment as 本年建安费用,
		r.MonthJaInvestment as 本月建安费用,
		(ISNULL(CollectionAmountTotal, 0)
					- ISNULL(DirectInvestmentTotal, 0)
					- ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0)) as 累计经营性现金流,
		ISNULL(YearCollectionAmount, 0)
					- ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0)
					- ISNULL(YearExpense, 0)  as 本年经营性现金流,
		ISNULL(MonthCollectionAmount, 0)
					- ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0)
					- ISNULL(MonthExpense, 0)  as 本月经营性现金流,
		(ISNULL(CollectionAmountTotal, 0)
					- ISNULL(DirectInvestmentTotal, 0)
					- ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0))*pj.EquityRatio/100.0 as 累计权益经营性现金流,
		(ISNULL(YearCollectionAmount, 0)
					- ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0)
					- ISNULL(YearExpense, 0))*pj.EquityRatio/100.0 as 本年权益经营性现金流,
		(ISNULL(MonthCollectionAmount, 0)
					- ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0)
					- ISNULL(MonthExpense, 0))*pj.EquityRatio/100.0  as 本月权益经营性现金流,
		(ISNULL(CollectionAmountTotal, 0)
					+ ISNULL(LoanBalanceTotal, 0)
					- ISNULL(DirectInvestmentTotal, 0)
					- ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0)) as 累计股东投资回收金额,
		ISNULL(YearCollectionAmount, 0)
					+ ISNULL(YearNetIncreaseLoan, 0)
					- ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0)
					- ISNULL(YearExpense, 0)   as 本年股东投资回收金额,
		ISNULL(MonthCollectionAmount, 0)
					+ ISNULL(MonthNetIncreaseLoan, 0)
					- ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0)
					- ISNULL(MonthExpense, 0) as 本月股东投资回收金额,
		null  as 开发贷款余额,
		null  as 供应链融资余额,
		null  as 本年净增开发贷,
		null  as 本年净增供应链融资
	into #companytb
	FROM HighData_prod.dbo.data_wide_dws_mdm_Project pj
		-- 关联平台公司填报数据
		INNER JOIN HighData_prod.dbo.data_wide_dws_ys_DssCashFlowDataCompany r 
			ON pj.ProjGUID = r.ProjGUID
		-- 关联最新填报版本
		INNER JOIN (
			-- 按业务单元分组,获取最新填报月份
			SELECT 
				ROW_NUMBER() OVER(PARTITION BY BUGUID ORDER BY Year DESC, CONVERT(INT, Month) DESC) AS rn,
				*
			FROM (
				-- 获取有直接投资数据的填报记录
				SELECT  
					p.BUGUID, 
					Year,
					CONVERT(INT, Month) AS Month
				FROM dbo.data_wide_dws_ys_DssCashFlowDataCompany cf
					INNER JOIN data_wide_dws_mdm_Project p 
						ON p.ProjGUID = cf.ProjGUID
				GROUP BY 
					p.BUGUID,
					Year,
					CONVERT(INT, Month)
				HAVING SUM(DirectInvestmentTotal) > 0
			) px
		) px 
			ON pj.BUGUID = px.buguid 
			AND px.Year = r.Year 
			AND px.Month = CONVERT(INT, r.Month) 
			AND px.rn = 1
	-- WHERE pj.BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'

	--获取数据
	INSERT INTO #tmp_dw_f_TopProj_Filltab_Fact
	(
		项目填报Guid,
		项目Guid,
		项目名称,
		年,
		月,
		三年盈利项目全投资IRR,
		累计总投资金额,
		累计贷款余额,
		累计回笼金额,
		累计直接投资土地费用,
		累计直接投资,
		累计税金,
		累计三费,
		本年总投资金额,
		本年贷款金额,
		本年回笼金额,
		本年累计直接投资,
		本年直接投资土地费用,
		本年税金,
		本年三费,
		本月总投资金额,
		本月贷款金额,
		本月回笼金额,
		本月累计直接投资,
		本月直接投资土地费用,
		本月税金,
		本月三费,
		本年净增贷款,
		本年实际融资,
		收购对价,
		实际现金流回正日期,
		实际收回股东投资日期,
		三年盈利项目自有资金IRR,
		实际收购对价,
		本月净增贷款,
		累计建安费用 ,
		本年建安费用 ,
		本月建安费用 ,
		累计经营性现金流,
		本年经营性现金流,
		本月经营性现金流,
		累计权益经营性现金流 ,
		本年权益经营性现金流 ,
		本月权益经营性现金流 ,
		累计股东投资回收金额 ,
		本年股东投资回收金额 ,
		本月股东投资回收金额 ,
		开发贷款余额,
		供应链融资余额,
		本年净增开发贷,
		本年净增供应链融资
	)
    select  
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.项目填报Guid else a.项目填报Guid end as 项目填报Guid,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.项目Guid else a.项目Guid end as 项目Guid,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.项目名称 else a.项目名称 end as 项目名称,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.年 else a.年 end as 年,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.月 else a.月 end as 月,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.三年盈利项目全投资IRR else a.三年盈利项目全投资IRR end as 三年盈利项目全投资IRR,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计总投资金额 else a.累计总投资金额 end as 累计总投资金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计贷款余额 else a.累计贷款余额 end as 累计贷款余额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计回笼金额 else a.累计回笼金额 end as 累计回笼金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计直接投资土地费用 else a.累计直接投资土地费用 end as 累计直接投资土地费用,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计直接投资 else a.累计直接投资 end as 累计直接投资,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计税金 else a.累计税金 end as 累计税金,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计三费 else a.累计三费 end as 累计三费,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年总投资金额 else a.本年总投资金额 end as 本年总投资金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年贷款金额 else a.本年贷款金额 end as 本年贷款金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年回笼金额 else a.本年回笼金额 end as 本年回笼金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年累计直接投资 else a.本年累计直接投资 end as 本年累计直接投资,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年直接投资土地费用 else a.本年直接投资土地费用 end as 本年直接投资土地费用,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年税金 else a.本年税金 end as 本年税金,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年三费 else a.本年三费 end as 本年三费,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月总投资金额 else a.本月总投资金额 end as 本月总投资金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月贷款金额 else a.本月贷款金额 end as 本月贷款金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月回笼金额 else a.本月回笼金额 end as 本月回笼金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月累计直接投资 else a.本月累计直接投资 end as 本月累计直接投资,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月直接投资土地费用 else a.本月直接投资土地费用 end as 本月直接投资土地费用,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月税金 else a.本月税金 end as 本月税金,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月三费 else a.本月三费 end as 本月三费,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年净增贷款 else a.本年净增贷款 end as 本年净增贷款,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年实际融资 else a.本年实际融资 end as 本年实际融资,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.收购对价 else a.收购对价 end as 收购对价,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.实际现金流回正日期 else a.实际现金流回正日期 end as 实际现金流回正日期,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.实际收回股东投资日期 else a.实际收回股东投资日期 end as 实际收回股东投资日期,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.三年盈利项目自有资金IRR else a.三年盈利项目自有资金IRR end as 三年盈利项目自有资金IRR,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.实际收购对价 else a.实际收购对价 end as 实际收购对价,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月净增贷款 else a.本月净增贷款 end as 本月净增贷款,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计建安费用 else a.累计建安费用 end as 累计建安费用,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年建安费用 else a.本年建安费用 end as 本年建安费用,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月建安费用 else a.本月建安费用 end as 本月建安费用,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计经营性现金流 else a.累计经营性现金流 end as 累计经营性现金流,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年经营性现金流 else a.本年经营性现金流 end as 本年经营性现金流,

        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月经营性现金流 else a.本月经营性现金流 end as 本月经营性现金流,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计权益经营性现金流 else a.累计权益经营性现金流 end as 累计权益经营性现金流,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年权益经营性现金流 else a.本年权益经营性现金流 end as 本年权益经营性现金流,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月权益经营性现金流 else a.本月权益经营性现金流 end as 本月权益经营性现金流,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.累计股东投资回收金额 else a.累计股东投资回收金额 end as 累计股东投资回收金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年股东投资回收金额 else a.本年股东投资回收金额 end as 本年股东投资回收金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本月股东投资回收金额 else a.本月股东投资回收金额 end as 本月股东投资回收金额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.开发贷款余额 else a.开发贷款余额 end as 开发贷款余额,
        case when convert(int,b.年) >= convert(int,b.年) and convert(int,b.月) >= convert(int,a.月) then b.供应链融资余额 else a.供应链融资余额 end as 供应链融资余额,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年净增开发贷 else a.本年净增开发贷 end as 本年净增开发贷,
        case when convert(int,b.年) >= convert(int,a.年) and convert(int,b.月) >= convert(int,a.月) then b.本年净增供应链融资 else a.本年净增供应链融资 end as 本年净增供应链融资
    from  #zbtb a
    left join #companytb b on a.项目guid = b.项目guid
    where 1=1

				 
 
    --插入正式表数据
    DELETE FROM dw_f_TopProj_Filltab_Fact
    WHERE 1 = 1;

    INSERT INTO dw_f_TopProj_Filltab_Fact
    SELECT *
    FROM #tmp_dw_f_TopProj_Filltab_Fact;

    --删除临时表
    DROP TABLE #tmp_dw_f_TopProj_Filltab_Fact;
	DROP table #zbtb
	drop table #companytb
	 
END;

 

 
