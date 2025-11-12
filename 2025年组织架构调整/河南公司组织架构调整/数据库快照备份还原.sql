
USE [master]
GO
-- 备份ERP25数据库快照
CREATE DATABASE ERP25_1024_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'G:\snapshot\ERP25\ERP25_snapshot.mdf' ),
( NAME = N'dotnet_crm50sp1_1', FILENAME = N'G:\snapshot\ERP25\ERP25_0_snapshot.ndf'  ),
( NAME = N'dotnet_crm50sp1_2', FILENAME = N'G:\snapshot\ERP25\ERP25_1_snapshot.ndf'  ),
( NAME = N'dotnet_crm50sp1_3', FILENAME = N'G:\snapshot\ERP25\ERP25_2_snapshot.ndf'  ), 
--  FILEGROUP [secondary] 
( NAME = N'erp25_2', FILENAME = N'G:\snapshot\ERP25\ERP25_3_snapshot.NDF'  ),
( NAME = N'erp25_2_1', FILENAME = N'G:\snapshot\ERP25\ERP25_4_snapshot.ndf'  ),
( NAME = N'erp25_2_2', FILENAME = N'G:\snapshot\ERP25\ERP25_5_snapshot.ndf' )
AS SNAPSHOT OF ERP25;
GO

USE [master]
GO
-- 备份ERP25数据库快照
CREATE DATABASE ERP25_1024_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'M:\MSSQL\snapshot\ERP25_test_snapshot.mdf'  ),
( NAME = N'dotnet_crm50sp1_1', FILENAME = N'M:\MSSQL\snapshot\ERP25_test_0_snapshot.ndf' ),
( NAME = N'dotnet_crm50sp1_2', FILENAME = N'M:\MSSQL\snapshot\ERP25_test_1_snapshot.ndf'  ),
( NAME = N'dotnet_crm50sp1_3', FILENAME = N'M:\MSSQL\snapshot\ERP25_test_2_snapshot.ndf' ), 
 --FILEGROUP [secondary] 
( NAME = N'erp25_2', FILENAME = N'M:\MSSQL\snapshot\ERP25_test_3_snapshot.NDF' ),
( NAME = N'erp25_2_1', FILENAME = N'M:\MSSQL\snapshot\ERP25_test_4_snapshot.ndf' ),
( NAME = N'erp25_2_2', FILENAME = N'M:\MSSQL\snapshot\ERP25_test_5_snapshot.ndf' )
AS SNAPSHOT OF ERP25_test;
GO

USE master
GO
-- 备份ERP352数据库快照
CREATE DATABASE MyCost_Erp352_1024_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'G:\snapshot\ERP352\MyCost_Erp352_snapshot.mdf' ),
( NAME = N'dotnet_crm352sp2', FILENAME = N'G:\snapshot\ERP352\MyCost_Erp352_0_snapshot.ndf' )
AS SNAPSHOT OF MyCost_Erp352;
GO

CREATE DATABASE MyCost_Erp352_1024_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'M:\MSSQL\snapshot\ERP352\MyCost_Erp352_snapshot.mdf' ),
( NAME = N'dotnet_crm352sp2', FILENAME = N'M:\MSSQL\snapshot\ERP352\MyCost_Erp352_0_snapshot.ndf' )
AS SNAPSHOT OF [MyCost_Erp352_ceshi];
GO


USE master
GO
-- 备份ERP60数据库快照
CREATE DATABASE  dotnet_erp60_1024_snapshot ON
( NAME = N'dotnet_erp60', FILENAME = N'M:\MSSQL\snapshot\ERP60\dotnet_erp60_snapshot.mdf'  )
AS SNAPSHOT OF dotnet_erp60;
GO

USE master
GO
CREATE DATABASE CRE_ERP_202_SYZL_1024_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'M:\MSSQL\snapshot\CRE_ERP_202_SYZL\CRE_ERP_202_SYZL_snapshot.mdf' )
AS SNAPSHOT OF CRE_ERP_202_SYZL
GO


USE master
GO
-- 备份TaskCenterData数据库快照
CREATE DATABASE TaskCenterData_1024_snapshot ON
( NAME = N'TaskCenterData', FILENAME = N'M:\MSSQL\snapshot\TaskCenterData\TaskCenterData_snapshot.mdf' )
AS SNAPSHOT OF TaskCenterData
GO

USE master
GO
-- 备份TaskCenterData数据库快照
CREATE DATABASE TaskCenterData_1024_snapshot ON
( NAME = N'TaskCenterData_test', FILENAME = N'M:\MSSQL\snapshot\TaskCenterData\TaskCenterData_snapshot.mdf' )
AS SNAPSHOT OF TaskCenterData_test
GO
-- 快照还原 ----------
--/////////////////////////////////还原数据库快照///////////////////////////////////////////////
--ERP25
ALTER DATABASE ERP25 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
 
RESTORE DATABASE ERP25 FROM DATABASE_SNAPSHOT = 'ERP25_1024_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('ERP25');
EXEC(@SQL);
ALTER DATABASE ERP25 SET MULTI_USER;
GO

--ERP352
ALTER DATABASE MyCost_Erp352 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
 
RESTORE DATABASE MyCost_Erp352 FROM DATABASE_SNAPSHOT = 'MyCost_Erp352_1024_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('MyCost_Erp352');
EXEC(@SQL);
ALTER DATABASE MyCost_Erp352 SET MULTI_USER;
GO

--ERP60
ALTER DATABASE dotnet_erp60 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
 
RESTORE DATABASE dotnet_erp60 FROM DATABASE_SNAPSHOT = 'dotnet_erp60_1024_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('dotnet_erp60');
EXEC(@SQL);
ALTER DATABASE dotnet_erp60 SET MULTI_USER;
GO


--[CRE_ERP_202_SYZL]
ALTER DATABASE CRE_ERP_202_SYZL SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE CRE_ERP_202_SYZL FROM DATABASE_SNAPSHOT = 'CRE_ERP_202_SYZL_1024_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('CRE_ERP_202_SYZL');
EXEC(@SQL);
ALTER DATABASE CRE_ERP_202_SYZL SET MULTI_USER;
GO


--[TaskCenterData]
ALTER DATABASE TaskCenterData SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE TaskCenterData FROM DATABASE_SNAPSHOT = 'TaskCenterData_1024_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('TaskCenterData');
EXEC(@SQL);
ALTER DATABASE TaskCenterData SET MULTI_USER;
GO
