-- 创建备份表

DECLARE @StartTime DATETIME
DECLARE @EndTime DATETIME

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_BaseInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_BaseInfo;
SET @EndTime = GETDATE()
PRINT 'BaseInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_cashflowInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_cashflowInfo;
SET @EndTime = GETDATE()
PRINT 'CashflowInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_CbInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_CbInfo;
SET @EndTime = GETDATE()
PRINT 'CbInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_LxdwInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_LxdwInfo;
SET @EndTime = GETDATE()
PRINT 'LxdwInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_Organization_bak20250106 FROM dbo.dw_s_WqBaseStatic_Organization;
SET @EndTime = GETDATE()
PRINT 'Organization backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_ProdMarkInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_ProdMarkInfo;
SET @EndTime = GETDATE()
PRINT 'ProdMarkInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_ProdMarkInfo_month_bak20250106 FROM dbo.dw_s_WqBaseStatic_ProdMarkInfo_month;
SET @EndTime = GETDATE()
PRINT 'ProdMarkInfo_month backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_ProductedHZInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_ProductedHZInfo;
SET @EndTime = GETDATE()
PRINT 'ProductedHZInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_ProfitInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_ProfitInfo;
SET @EndTime = GETDATE()
PRINT 'ProfitInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_returnInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_returnInfo;
SET @EndTime = GETDATE()
PRINT 'ReturnInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_salevalueInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_salevalueInfo;
SET @EndTime = GETDATE()
PRINT 'SalevalueInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_ScheduleInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_ScheduleInfo;
SET @EndTime = GETDATE()
PRINT 'ScheduleInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_tradeInfo_bak20250106 FROM dbo.dw_s_WqBaseStatic_tradeInfo;
SET @EndTime = GETDATE()
PRINT 'TradeInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.dw_s_WqBaseStatic_ylghInfo_bak20250106 FROM [dbo].[dw_s_WqBaseStatic_ylghInfo];
SET @EndTime = GETDATE()
PRINT 'YlglInfo backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'

SET @StartTime = GETDATE()
SELECT * INTO dbo.s_WqBaseStatic_summary_his_bak20250106 FROM dbo.s_WqBaseStatic_summary_his;
SET @EndTime = GETDATE()
PRINT 'Summary_his backup took ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS VARCHAR) + ' seconds'


-- 还原数据库
--删除表
truncate table dbo.dw_s_WqBaseStatic_BaseInfo;
truncate table dbo.dw_s_WqBaseStatic_cashflowInfo;
truncate table dbo.dw_s_WqBaseStatic_CbInfo;
truncate table dbo.dw_s_WqBaseStatic_LxdwInfo;
truncate table dbo.dw_s_WqBaseStatic_Organization;
truncate table dbo.dw_s_WqBaseStatic_ProdMarkInfo;
truncate table dbo.dw_s_WqBaseStatic_ProdMarkInfo_month;
truncate table dbo.dw_s_WqBaseStatic_ProductedHZInfo;
truncate table dbo.dw_s_WqBaseStatic_ProfitInfo;
truncate table dbo.dw_s_WqBaseStatic_returnInfo;
truncate table dbo.dw_s_WqBaseStatic_salevalueInfo;
truncate table dbo.dw_s_WqBaseStatic_ScheduleInfo;
truncate table dbo.dw_s_WqBaseStatic_tradeInfo;
truncate table dbo.dw_s_WqBaseStatic_ylghInfo;
truncate table dbo.s_WqBaseStatic_summary_his;

drop table dbo.dw_s_WqBaseStatic_BaseInfo;
drop table dbo.dw_s_WqBaseStatic_cashflowInfo;
drop table dbo.dw_s_WqBaseStatic_CbInfo;
drop table dbo.dw_s_WqBaseStatic_LxdwInfo;
drop table dbo.dw_s_WqBaseStatic_Organization;
drop table dbo.dw_s_WqBaseStatic_ProdMarkInfo;
drop table dbo.dw_s_WqBaseStatic_ProdMarkInfo_month;
drop table dbo.dw_s_WqBaseStatic_ProductedHZInfo;
drop table dbo.dw_s_WqBaseStatic_ProfitInfo;
drop table dbo.dw_s_WqBaseStatic_returnInfo;
drop table dbo.dw_s_WqBaseStatic_salevalueInfo;
drop table dbo.dw_s_WqBaseStatic_ScheduleInfo;
drop table dbo.dw_s_WqBaseStatic_tradeInfo;
drop table dbo.dw_s_WqBaseStatic_ylghInfo;
drop table dbo.s_WqBaseStatic_summary_his;


SELECT * INTO dbo.dw_s_WqBaseStatic_BaseInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_BaseInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_cashflowInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_cashflowInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_CbInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_CbInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_LxdwInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_LxdwInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_Organization FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_Organization;
SELECT * INTO dbo.dw_s_WqBaseStatic_ProdMarkInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_ProdMarkInfo;      
SELECT * INTO dbo.dw_s_WqBaseStatic_ProdMarkInfo_month FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_ProdMarkInfo_month;
SELECT * INTO dbo.dw_s_WqBaseStatic_ProductedHZInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_ProductedHZInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_ProfitInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_ProfitInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_returnInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_returnInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_salevalueInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_salevalueInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_ScheduleInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_ScheduleInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_tradeInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_tradeInfo;
SELECT * INTO dbo.dw_s_WqBaseStatic_ylghInfo FROM [172.16.4.129].[HighData_prod].dbo.dw_s_WqBaseStatic_ylghInfo;
SELECT * INTO dbo.s_WqBaseStatic_summary_his FROM [172.16.4.129].[HighData_prod].dbo.s_WqBaseStatic_summary_his;