--DSS平台公司现金流
--Dss平台公司现金流改成从报表代码BA005取数，之前
SELECT   
        x.BusinessGUID AS ProjGUID ,
        x.[一级项目名称] AS ProjName , 
        x.年份 AS year ,
        x.月份 AS month ,
        ISNULL(sum(x.项目_累计总投资), 0) AS InvestmentAmountTotal ,
		ISNULL(sum(x.项目_本年总投资), 0) AS YearInvestmentAmount ,
		ISNULL(sum(x.项目_本月总投资), 0) AS MonthInvestmentAmount ,
		ISNULL(sum(x.项目_本月直接投资), 0) AS MonthDirectInvestment ,
		ISNULL(sum(x.项目_本月直接投资土地费用), 0) AS MonthLandCost ,
		ISNULL(sum(x.项目_本月直接建安投资), 0) AS MonthJaInvestment ,
		ISNULL(sum(x.项目_本年直接投资), 0) AS YearDirectInvestment ,
		ISNULL(sum(x.项目_本年直接投资土地费用), 0) AS YearLandCost ,
		ISNULL(sum(x.项目_本年直接建安投资), 0) AS YearJaInvestment , 
		ISNULL(sum(x.项目_累计直接投资), 0) AS DirectInvestmentTotal ,
		ISNULL(sum(x.项目_累计直接投资其中土地费用), 0) AS LandCostTotal ,
		ISNULL(sum(x.项目_累计直接建安投资), 0) AS JaInvestmentTotal ,

		ISNULL(sum(x.我方_累计总投资), 0) AS InvestmentAmountTotal_own ,
		ISNULL(sum(x.我方_本年总投资), 0) AS YearInvestmentAmount_own ,
		ISNULL(sum(x.我方_本月总投资), 0) AS MonthInvestmentAmount_own ,
		ISNULL(sum(x.我方_本月直接投资), 0) AS MonthDirectInvestment_own ,
		ISNULL(sum(x.我方_本月直接投资土地费用), 0) AS MonthLandCost_own ,
		ISNULL(sum(x.我方_本月直接建安投资), 0) AS MonthJaInvestment_own ,
		ISNULL(sum(x.我方_本年直接投资), 0) AS YearDirectInvestment_own ,
		ISNULL(sum(x.我方_本年直接投资土地费用), 0) AS YearLandCost_own ,
		ISNULL(sum(x.我方_本年直接建安投资), 0) AS YearJaInvestment_own , 
		ISNULL(sum(x.我方_累计直接投资), 0) AS DirectInvestmentTotal_own ,
		ISNULL(sum(x.我方_累计直接投资其中土地费用), 0) AS LandCostTotal_own ,
		ISNULL(sum(x.我方_累计直接建安投资), 0) AS JaInvestmentTotal_own ,

		ISNULL(sum(x.[累计税金]), 0) AS TaxTotal ,
		ISNULL(sum(x.[本年税金]), 0) AS YearTax ,
		ISNULL(sum(x.[本月税金]), 0) AS MonthTax , 
        ISNULL(sum(x.累计结转), 0) AS JzTotal ,
		ISNULL(sum(x.本年结转), 0) AS YearJzTotal , 
        ISNULL(sum(x.[累计回笼]), 0) AS CollectionAmountTotal , 
        ISNULL(sum(x.[本年回笼]), 0) AS YearCollectionAmount ,
		ISNULL(sum(x.[本月回笼]), 0) AS MonthCollectionAmount ,
		ISNULL(sum(x.[累计权益回笼]), 0) AS CollectionAmountTotal_qy , 
        ISNULL(sum(x.[本年权益回笼]), 0) AS YearCollectionAmount_qy,

		null AS PayedJaTotal ,
		null AS PayedQtTotal ,
		isnull(sum(本年支付收购对价),0) AS YearPayedSGDJ , 
        null AS YearPayedLand ,
		null AS YearPayedJa , 
        null AS YearPayedYj , 
        null AS YearPayedQt ,
		null AS PayedYjTotal , 
        null AS GQDJ,
		null AS ZQDJ , 
        isnull(sum(收购对价),0) as SGDJ ,
        ISNULL(sum(本月贷款金额),0) AS MonthLoanBalance,
		ISNULL(sum(本年贷款金额),0) AS YearLoanBalance,
		ISNULL(sum(本月净增贷款),0) AS MonthNetIncreaseLoan,
		ISNULL(sum(本年净增贷款),0) AS YearNetIncreaseLoan,
		ISNULL(sum(贷款余额),0) AS LoanBalanceTotal,
		isnull(sum(累计三费),0) AS ExpenseTotal ,
		isnull(sum(本年三费),0) AS YearExpense ,
		isnull(sum(本月三费),0) AS MonthExpense,
					 isnull(sum(本月支付收购对价),0) as MonthPayedSGDJ
FROM    
( 
	SELECT  YEAR(b.EndDate) AS 年份 ,
			MONTH(b.EndDate) AS 月份 ,  
			BusinessGUID, 
			[一级项目名称], 

			[项目-本月总投资（万元）] AS 项目_本月总投资,  
			[项目-本年总投资（万元）] AS 项目_本年总投资, 
			[项目-累计总投资（万元）] AS 项目_累计总投资, 
			[项目-本月直接投资（万元）] 项目_本月直接投资,  
			[项目-本月直接投资土地费用（万元）] AS 项目_本月直接投资土地费用, 
			[项目-本月直接建安投资（万元）] AS 项目_本月直接建安投资,  
			[项目-本年直接投资（万元）] AS 项目_本年直接投资, 
			[项目-本年直接投资土地费用（万元）] AS 项目_本年直接投资土地费用, 
			[项目-本年直接建安投资（万元）] AS 项目_本年直接建安投资, 
			[项目-累计直接投资（万元）] AS 项目_累计直接投资, 
			[项目-累计直接投资其中土地费用（万元）] AS 项目_累计直接投资其中土地费用, 
			[项目-累计直接建安投资（万元）] AS 项目_累计直接建安投资, 

			[我方-本月总投资（万元）] AS 我方_本月总投资, 
			[我方-本年总投资（万元）] AS 我方_本年总投资, 
			[我方-累计总投资（万元）] AS 我方_累计总投资, 
			[我方-本月直接投资（万元）] AS 我方_本月直接投资, 
			[我方-本月直接投资土地费用（万元）] AS 我方_本月直接投资土地费用, 
			[我方-本月直接建安投资（万元）] AS 我方_本月直接建安投资, 
			[我方-本年直接投资（万元）] AS 我方_本年直接投资, 
			[我方-本年直接投资土地费用（万元）] AS 我方_本年直接投资土地费用, 
			[我方-本年直接建安投资（万元）] AS 我方_本年直接建安投资, 
			[我方-累计直接投资（万元）] AS 我方_累计直接投资, 
			[我方-累计直接投资其中土地费用（万元）] AS 我方_累计直接投资其中土地费用, 
			[我方-累计直接建安投资（万元）] AS 我方_累计直接建安投资, 

			[本月税金（万元）] AS 本月税金, 
			[本年税金（万元）] AS 本年税金, 
			[累计税金（万元）] as 累计税金,  
			[本年结转（万元）] as 本年结转, 
			[累计结转（万元）] as 累计结转, 
			[本年回笼（万元）] as 本年回笼, 
			[累计回笼（万元）] as 累计回笼, 
			[a].[本月回笼（万元）] AS 本月回笼,
			[本年权益回笼（万元）] AS 本年权益回笼, 
			[累计权益回笼（万元）] AS 累计权益回笼,
			[a].[本月回笼（万元）] AS 本月回款,
			[本月贷款金额(万元)] AS 本月贷款金额,
			[本年贷款金额(万元)] AS 本年贷款金额,
			[本月净增贷款(万元)] AS 本月净增贷款,
			[本年净增贷款(万元)] AS 本年净增贷款,
			[贷款余额(万元)] AS 贷款余额, 
           ISNULL(a.[项目-累计总投资（万元）] , 0) - ISNULL(a.[项目-累计直接投资（万元）], 0) AS  累计三费,
           ISNULL(a.[项目-本年总投资（万元）], 0) - ISNULL(a.[项目-本年直接投资（万元）], 0) AS  本年三费,
           ISNULL(a.[项目-本月总投资（万元）], 0) - ISNULL(a.[项目-本月直接投资（万元）], 0) AS  本月三费,
					 0 as 本年支付收购对价,
					 0 as 本月支付收购对价,
					 0 as 收购对价
  --FROM [nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2019] a
  from  [dbo].[nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2021] a
  INNER JOIN nmap_F_FillHistory b ON a.FillHistoryGUID = b.FillHistoryGUID
  WHERE   [项目-累计总投资（万元）]<>0  
	--合并BA006取数
	union ALL
		SELECT  YEAR(b.EndDate) AS 年份 ,
			MONTH(b.EndDate) AS 月份 ,  
			BusinessGUID, 
			[一级项目名称], 

			[项目-本月总投资（万元）] AS 项目_本月总投资,  
			[项目-本年总投资（万元）] AS 项目_本年总投资, 
			[项目-累计总投资（万元）] AS 项目_累计总投资, 
			[项目-本月直接投资（万元）] 项目_本月直接投资,  
			[项目-本月直接投资土地费用（万元）] AS 项目_本月直接投资土地费用, 
			0 AS 项目_本月直接建安投资,  
			[项目-本年直接投资（万元）] AS 项目_本年直接投资, 
			[项目-本年直接投资土地费用（万元）] AS 项目_本年直接投资土地费用, 
			0 AS 项目_本年直接建安投资, 
			[项目-累计直接投资（万元）] AS 项目_累计直接投资, 
			[项目-累计直接投资土地费用（万元）] AS 项目_累计直接投资其中土地费用, 
			0 AS 项目_累计直接建安投资, 

			[除收购对价外支付-我方-本月总投资（万元）] AS 我方_本月总投资, 
			[除收购对价外支付-我方-本年总投资（万元）] AS 我方_本年总投资, 
			[除收购对价外支付-我方-累计总投资（万元）] AS 我方_累计总投资, 
			[除收购对价外支付-我方-本月直接投资（万元）] AS 我方_本月直接投资, 
			[除收购对价外支付-我方-本月直接投资土地费用（万元）] AS 我方_本月直接投资土地费用, 
			0 AS 我方_本月直接建安投资, 
			[除收购对价外支付-我方-本年直接投资（万元）] AS 我方_本年直接投资, 
			[除收购对价外支付-我方-本年直接投资土地费用（万元）] AS 我方_本年直接投资土地费用, 
			0 AS 我方_本年直接建安投资, 
			[除收购对价外支付-我方-累计直接投资（万元）] AS 我方_累计直接投资, 
			[除收购对价外支付-我方-累计直接投资土地费用（万元）] AS 我方_累计直接投资其中土地费用, 
			0 AS 我方_累计直接建安投资, 

			[项目-本月税金（万元）] AS 本月税金, 
			[项目-本年税金（万元）] AS 本年税金, 
			[项目-累计税金（万元）] as 累计税金,  
			[本年结转（万元）] as 本年结转, 
			[累计结转（万元）] as 累计结转, 
			[本年回笼（万元）] as 本年回笼, 
			[累计回笼（万元）] as 累计回笼, 
			[a].[本月回笼（万元）] AS 本月回笼,
			[本年权益回笼（万元）] AS 本年权益回笼, 
			[累计权益回笼（万元）] AS 累计权益回笼,
			[a].[本月回笼（万元）] AS 本月回款,
			[本月贷款金额(万元)] AS 本月贷款金额,
			[本年贷款金额(万元)] AS 本年贷款金额,
			[本月净增贷款(万元)] AS 本月净增贷款,
			[本年净增贷款(万元)] AS 本年净增贷款,
			[贷款余额(万元)] AS 贷款余额, 
           ISNULL(a.[项目-累计总投资（万元）] , 0) - ISNULL(a.[项目-累计直接投资（万元）], 0) AS  累计三费,
           ISNULL(a.[项目-本年总投资（万元）], 0) - ISNULL(a.[项目-本年直接投资（万元）], 0) AS  本年三费,
           ISNULL(a.[项目-本月总投资（万元）], 0) - ISNULL(a.[项目-本月直接投资（万元）], 0) AS  本月三费,
					 a.[本年支付收购对价（万元）] as 本年支付收购对价,
					 a.[本月支付收购对价（万元）] as 本月支付收购对价,
					 a.[收购对价（万元）] as 收购对价
  --FROM [nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2019] a
  from  [dbo].[nmap_F_收购项目投资、结转、回笼、贷款情况表_2021] a
  INNER JOIN nmap_F_FillHistory b ON a.FillHistoryGUID = b.FillHistoryGUID
  WHERE   [项目-累计总投资（万元）]<>0  	AND NOT EXISTS (
		SELECT 1 FROM [dbo].[nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2021] c 
		WHERE c.BusinessGUID = a.BusinessGUID and year(c.EndDate) = YEAR(a.EndDate) and month(c.EndDate) =month(a.EndDate) )
) x 
group by 
x.BusinessGUID,
        x.[一级项目名称], 
        x.年份,
        x.月份
/*20240914注释改成05+06取数
--DSS平台公司现金流
--Dss平台公司现金流改成从报表代码BA005取数，之前
SELECT   
        x.BusinessGUID AS ProjGUID ,
        x.[一级项目名称] AS ProjName , 
        x.年份 AS year ,
        x.月份 AS month ,
        ISNULL(x.项目_累计总投资, 0) AS InvestmentAmountTotal ,
		ISNULL(x.项目_本年总投资, 0) AS YearInvestmentAmount ,
		ISNULL(x.项目_本月总投资, 0) AS MonthInvestmentAmount ,
		ISNULL(x.项目_本月直接投资, 0) AS MonthDirectInvestment ,
		ISNULL(x.项目_本月直接投资土地费用, 0) AS MonthLandCost ,
		ISNULL(x.项目_本月直接建安投资, 0) AS MonthJaInvestment ,
		ISNULL(x.项目_本年直接投资, 0) AS YearDirectInvestment ,
		ISNULL(x.项目_本年直接投资土地费用, 0) AS YearLandCost ,
		ISNULL(x.项目_本年直接建安投资, 0) AS YearJaInvestment , 
		ISNULL(x.项目_累计直接投资, 0) AS DirectInvestmentTotal ,
		ISNULL(x.项目_累计直接投资其中土地费用, 0) AS LandCostTotal ,
		ISNULL(x.项目_累计直接建安投资, 0) AS JaInvestmentTotal ,

		ISNULL(x.我方_累计总投资, 0) AS InvestmentAmountTotal_own ,
		ISNULL(x.我方_本年总投资, 0) AS YearInvestmentAmount_own ,
		ISNULL(x.我方_本月总投资, 0) AS MonthInvestmentAmount_own ,
		ISNULL(x.我方_本月直接投资, 0) AS MonthDirectInvestment_own ,
		ISNULL(x.我方_本月直接投资土地费用, 0) AS MonthLandCost_own ,
		ISNULL(x.我方_本月直接建安投资, 0) AS MonthJaInvestment_own ,
		ISNULL(x.我方_本年直接投资, 0) AS YearDirectInvestment_own ,
		ISNULL(x.我方_本年直接投资土地费用, 0) AS YearLandCost_own ,
		ISNULL(x.我方_本年直接建安投资, 0) AS YearJaInvestment_own , 
		ISNULL(x.我方_累计直接投资, 0) AS DirectInvestmentTotal_own ,
		ISNULL(x.我方_累计直接投资其中土地费用, 0) AS LandCostTotal_own ,
		ISNULL(x.我方_累计直接建安投资, 0) AS JaInvestmentTotal_own ,

		ISNULL(x.[累计税金], 0) AS TaxTotal ,
		ISNULL(x.[本年税金], 0) AS YearTax ,
		ISNULL(x.[本月税金], 0) AS MonthTax , 
        ISNULL(x.累计结转, 0) AS JzTotal ,
		ISNULL(x.本年结转, 0) AS YearJzTotal , 
        ISNULL(x.[累计回笼], 0) AS CollectionAmountTotal , 
        ISNULL(x.[本年回笼], 0) AS YearCollectionAmount ,
		ISNULL(x.[本月回笼], 0) AS MonthCollectionAmount ,
		ISNULL(x.[累计权益回笼], 0) AS CollectionAmountTotal_qy , 
        ISNULL(x.[本年权益回笼], 0) AS YearCollectionAmount_qy,

		null AS PayedJaTotal ,
		null AS PayedQtTotal ,
		null AS YearPayedSGDJ , 
        null AS YearPayedLand ,
		null AS YearPayedJa , 
        null AS YearPayedYj , 
        null AS YearPayedQt ,
		null AS PayedYjTotal , 
        null AS GQDJ,
		null AS ZQDJ , 
        null AS SGDJ ,
        ISNULL(本月贷款金额,0) AS MonthLoanBalance,
		ISNULL(本年贷款金额,0) AS YearLoanBalance,
		ISNULL(本月净增贷款,0) AS MonthNetIncreaseLoan,
		ISNULL(本年净增贷款,0) AS YearNetIncreaseLoan,
		ISNULL(贷款余额,0) AS LoanBalanceTotal,
		isnull(累计三费,0) AS ExpenseTotal ,
		isnull(本年三费,0) AS YearExpense ,
		isnull(本月三费,0) AS MonthExpense 
FROM    
( 
	SELECT  YEAR(b.EndDate) AS 年份 ,
			MONTH(b.EndDate) AS 月份 ,  
			BusinessGUID, 
			[一级项目名称], 

			[项目-本月总投资（万元）] AS 项目_本月总投资,  
			[项目-本年总投资（万元）] AS 项目_本年总投资, 
			[项目-累计总投资（万元）] AS 项目_累计总投资, 
			[项目-本月直接投资（万元）] 项目_本月直接投资,  
			[项目-本月直接投资土地费用（万元）] AS 项目_本月直接投资土地费用, 
			[项目-本月直接建安投资（万元）] AS 项目_本月直接建安投资,  
			[项目-本年直接投资（万元）] AS 项目_本年直接投资, 
			[项目-本年直接投资土地费用（万元）] AS 项目_本年直接投资土地费用, 
			[项目-本年直接建安投资（万元）] AS 项目_本年直接建安投资, 
			[项目-累计直接投资（万元）] AS 项目_累计直接投资, 
			[项目-累计直接投资其中土地费用（万元）] AS 项目_累计直接投资其中土地费用, 
			[项目-累计直接建安投资（万元）] AS 项目_累计直接建安投资, 

			[我方-本月总投资（万元）] AS 我方_本月总投资, 
			[我方-本年总投资（万元）] AS 我方_本年总投资, 
			[我方-累计总投资（万元）] AS 我方_累计总投资, 
			[我方-本月直接投资（万元）] AS 我方_本月直接投资, 
			[我方-本月直接投资土地费用（万元）] AS 我方_本月直接投资土地费用, 
			[我方-本月直接建安投资（万元）] AS 我方_本月直接建安投资, 
			[我方-本年直接投资（万元）] AS 我方_本年直接投资, 
			[我方-本年直接投资土地费用（万元）] AS 我方_本年直接投资土地费用, 
			[我方-本年直接建安投资（万元）] AS 我方_本年直接建安投资, 
			[我方-累计直接投资（万元）] AS 我方_累计直接投资, 
			[我方-累计直接投资其中土地费用（万元）] AS 我方_累计直接投资其中土地费用, 
			[我方-累计直接建安投资（万元）] AS 我方_累计直接建安投资, 

			[本月税金（万元）] AS 本月税金, 
			[本年税金（万元）] AS 本年税金, 
			[累计税金（万元）] as 累计税金,  
			[本年结转（万元）] as 本年结转, 
			[累计结转（万元）] as 累计结转, 
			[本年回笼（万元）] as 本年回笼, 
			[累计回笼（万元）] as 累计回笼, 
			[a].[本月回笼（万元）] AS 本月回笼,
			[本年权益回笼（万元）] AS 本年权益回笼, 
			[累计权益回笼（万元）] AS 累计权益回笼,
			[a].[本月回笼（万元）] AS 本月回款,
			[本月贷款金额(万元)] AS 本月贷款金额,
			[本年贷款金额(万元)] AS 本年贷款金额,
			[本月净增贷款(万元)] AS 本月净增贷款,
			[本年净增贷款(万元)] AS 本年净增贷款,
			[贷款余额(万元)] AS 贷款余额, 
           ISNULL(a.[项目-累计总投资（万元）] , 0) - ISNULL(a.[项目-累计直接投资（万元）], 0) AS  累计三费,
           ISNULL(a.[项目-本年总投资（万元）], 0) - ISNULL(a.[项目-本年直接投资（万元）], 0) AS  本年三费,
           ISNULL(a.[项目-本月总投资（万元）], 0) - ISNULL(a.[项目-本月直接投资（万元）], 0) AS  本月三费
  --FROM [nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2019] a
  from  [dbo].[nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2021] a
  INNER JOIN nmap_F_FillHistory b ON a.FillHistoryGUID = b.FillHistoryGUID
  WHERE   [项目-累计总投资（万元）]<>0  
) x */
 /*
UNION ALL
SELECT   
        x.BusinessGUID AS ProjGUID ,
        x.[一级项目名称] AS ProjName , 
        x.年份 AS year ,
        x.月份 AS month ,
        ISNULL(x.项目_累计总投资, 0) AS InvestmentAmountTotal ,
		ISNULL(x.项目_本年总投资, 0) AS YearInvestmentAmount ,
		ISNULL(x.项目_本月总投资, 0) AS MonthInvestmentAmount ,
		ISNULL(x.项目_本月直接投资, 0) AS MonthDirectInvestment ,
		ISNULL(x.项目_本月直接投资土地费用, 0) AS MonthLandCost ,
		ISNULL(x.项目_本月直接建安投资, 0) AS MonthJaInvestment ,
		ISNULL(x.项目_本年直接投资, 0) AS YearDirectInvestment ,
		ISNULL(x.项目_本年直接投资土地费用, 0) AS YearLandCost ,
		ISNULL(x.项目_本年直接建安投资, 0) AS YearJaInvestment , 
		ISNULL(x.项目_累计直接投资, 0) AS DirectInvestmentTotal ,
		ISNULL(x.项目_累计直接投资其中土地费用, 0) AS LandCostTotal ,
		ISNULL(x.项目_累计直接建安投资, 0) AS JaInvestmentTotal ,

		ISNULL(x.我方_累计总投资, 0) AS InvestmentAmountTotal_own ,
		ISNULL(x.我方_本年总投资, 0) AS YearInvestmentAmount_own ,
		ISNULL(x.我方_本月总投资, 0) AS MonthInvestmentAmount_own ,
		ISNULL(x.我方_本月直接投资, 0) AS MonthDirectInvestment_own ,
		ISNULL(x.我方_本月直接投资土地费用, 0) AS MonthLandCost_own ,
		ISNULL(x.我方_本月直接建安投资, 0) AS MonthJaInvestment_own ,
		ISNULL(x.我方_本年直接投资, 0) AS YearDirectInvestment_own ,
		ISNULL(x.我方_本年直接投资土地费用, 0) AS YearLandCost_own ,
		ISNULL(x.我方_本年直接建安投资, 0) AS YearJaInvestment_own , 
		ISNULL(x.我方_累计直接投资, 0) AS DirectInvestmentTotal_own ,
		ISNULL(x.我方_累计直接投资其中土地费用, 0) AS LandCostTotal_own ,
		ISNULL(x.我方_累计直接建安投资, 0) AS JaInvestmentTotal_own ,

		ISNULL(x.[累计税金], 0) AS TaxTotal ,
		ISNULL(x.[本年税金], 0) AS YearTax ,
		ISNULL(x.[本月税金], 0) AS MonthTax , 
        ISNULL(x.累计结转, 0) AS JzTotal ,
		ISNULL(x.本年结转, 0) AS YearJzTotal , 
        ISNULL(x.[累计回笼], 0) AS CollectionAmountTotal , 
        ISNULL(x.[本年回笼], 0) AS YearCollectionAmount ,
		ISNULL(x.[本月回笼], 0) AS MonthCollectionAmount ,
		ISNULL(x.[累计权益回笼], 0) AS CollectionAmountTotal_qy , 
        ISNULL(x.[本年权益回笼], 0) AS YearCollectionAmount_qy,

		ISNULL(x.累计已付建安, 0) AS PayedJaTotal ,
		ISNULL(x.累计已付其他, 0) AS PayedQtTotal ,
		ISNULL(x.本年支付收购对价, 0) AS YearPayedSGDJ , 
        ISNULL(x.本年已付地价, 0) AS YearPayedLand ,
		ISNULL(x.本年已付建安, 0) AS YearPayedJa , 
        ISNULL(x.本年已付溢价, 0) AS YearPayedYj , 
        ISNULL(x.本年已付其他, 0) AS YearPayedQt ,
		ISNULL(x.累计已付溢价, 0) AS PayedYjTotal , 
        ISNULL(x.股权对价, 0) AS GQDJ,
		ISNULL(x.债权对价, 0) AS ZQDJ , 
        ISNULL(x.收购对价, 0) AS SGDJ ,
        ISNULL(本月贷款金额,0) AS MonthLoanBalance,
		ISNULL(本年贷款金额,0) AS YearLoanBalance,
		ISNULL(本月净增贷款,0) AS MonthNetIncreaseLoan,
		ISNULL(本年净增贷款,0) AS YearNetIncreaseLoan,
		ISNULL(贷款余额,0) AS LoanBalanceTotal,
		isnull(累计三费,0) AS ExpenseTotal ,
		isnull(本年三费,0) AS YearExpense ,
		isnull(本月三费,0) AS MonthExpense 
FROM    
( 
	SELECT  YEAR(b.EndDate) AS 年份 ,
			MONTH(b.EndDate) AS 月份 ,  
			BusinessGUID, 
			[一级项目名称], 

			[除收购对价外支付-项目-本月总投资（万元）] AS 项目_本月总投资,  
			[除收购对价外支付-项目-本年总投资（万元）] AS 项目_本年总投资, 
			[除收购对价外支付-项目-累计总投资（万元）] AS 项目_累计总投资, 
			[除收购对价外支付-项目-本月直接投资（万元）] 项目_本月直接投资,  
			[除收购对价外支付-项目-本月直接投资土地费用（万元）] AS 项目_本月直接投资土地费用, 
			[除收购对价外支付-项目-本月直接投资建安投资（万元）] AS 项目_本月直接建安投资,  
			[除收购对价外支付-项目-本年直接投资（万元）] AS 项目_本年直接投资, 
			[除收购对价外支付-项目-本年直接投资土地费用（万元）] AS 项目_本年直接投资土地费用, 
			[除收购对价外支付-项目-本年直接投资建安投资（万元）] AS 项目_本年直接建安投资, 
			[除收购对价外支付-项目-累计直接投资（万元）] AS 项目_累计直接投资, 
			[除收购对价外支付-项目-累计直接投资土地费用（万元）] AS 项目_累计直接投资其中土地费用, 
			[除收购对价外支付-项目-累计直接投资建安投资（万元）] AS 项目_累计直接建安投资, 

			[除收购对价外支付-我方-本月总投资（万元）] AS 我方_本月总投资, 
			[除收购对价外支付-我方-本年总投资（万元）] AS 我方_本年总投资, 
			[除收购对价外支付-我方-累计总投资（万元）] AS 我方_累计总投资, 
			[除收购对价外支付-我方-本月直接投资（万元）] AS 我方_本月直接投资, 
			[除收购对价外支付-我方-本月直接投资土地费用（万元）] AS 我方_本月直接投资土地费用, 
			[除收购对价外支付-我方-本月直接投资建安投资（万元）] AS 我方_本月直接建安投资, 
			[除收购对价外支付-我方-本年直接投资（万元）] AS 我方_本年直接投资, 
			[除收购对价外支付-我方-本年直接投资土地费用（万元）] AS 我方_本年直接投资土地费用, 
			[除收购对价外支付-我方-本年直接投资建安投资（万元）] AS 我方_本年直接建安投资, 
			[除收购对价外支付-我方-累计直接投资（万元）] AS 我方_累计直接投资, 
			[除收购对价外支付-我方-累计直接投资土地费用（万元）] AS 我方_累计直接投资其中土地费用, 
			[除收购对价外支付-我方-累计直接投资建安投资（万元）] AS 我方_累计直接建安投资, 

			[项目-本月税金（万元）] AS 本月税金, 
			[项目-本年税金（万元）] AS 本年税金, 
			[项目-累计税金（万元）] as 累计税金,  
			[本年结转（万元）] as 本年结转, 
			[累计结转（万元）] as 累计结转, 
			[本年回笼（万元）] as 本年回笼, 
			[本月回笼（万元）] as 本月回笼, 
			[累计回笼（万元）] as 累计回笼, 
			[本年权益回笼（万元）] AS 本年权益回笼, 
			[累计权益回笼（万元）] AS 累计权益回笼,

			[其中：累计已付建安（万元）] AS 累计已付建安,
			[其中：累计已付其他（万元）] AS 累计已付其他,
			[本年支付收购对价（万元）] AS 本年支付收购对价,
			[其中：本年已付地价（万元）] as 本年已付地价,
			[其中：本年已付建安（万元）] as 本年已付建安,
			[其中：本年已付溢价（万元）] as 本年已付溢价,
			[其中：本年已付其他（万元）] as 本年已付其他,
			[其中：累计已付溢价（万元）] as 累计已付溢价,
			[股权对价（万元）] as 股权对价,
			[债权对价（万元）] as 债权对价,
			[收购对价（万元）] as 收购对价,
			[其中：累计已付地价（万元）] AS 累计已付地价 ,
			
			[本月贷款金额(万元)] AS 本月贷款金额,
			[本年贷款金额(万元)] AS 本年贷款金额,
			[本月净增贷款(万元)] AS 本月净增贷款,
			[本年净增贷款(万元)] AS 本年净增贷款,
			[贷款余额(万元)] AS 贷款余额, 
           ISNULL(a.[除收购对价外支付-项目-累计总投资（万元）] , 0) - ISNULL(a.[除收购对价外支付-项目-累计直接投资（万元）], 0) AS  累计三费,
           ISNULL(a.[除收购对价外支付-项目-本年总投资（万元）], 0) - ISNULL(a.[除收购对价外支付-项目-本年直接投资（万元）], 0) AS  本年三费,
           ISNULL(a.[除收购对价外支付-项目-本月总投资（万元）], 0) - ISNULL(a.[除收购对价外支付-项目-本月直接投资（万元）], 0) AS  本月三费
  FROM [dbo].[nmap_F_收购项目投资、结转、回笼、贷款情况表_2019] a
  INNER JOIN nmap_F_FillHistory b ON a.FillHistoryGUID = b.FillHistoryGUID
  WHERE [除收购对价外支付-项目-累计总投资（万元）]<>0  
) x 
*/

