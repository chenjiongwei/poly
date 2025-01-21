--/////////////////////////////////创建数据库快照/////////////////////////////////////////////
--EERP25
USE master
GO
--备份ERP25数据库
CREATE DATABASE ERP25_0121_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'D:\MSSQL\snapshot0121\erp25\ERP25_snapshot.mdf'  ),
( NAME = N'dotnet_crm50sp1_1', FILENAME = N'D:\MSSQL\snapshot0121\erp25\ERP25_0_snapshot.ndf'  ),
( NAME = N'dotnet_crm50sp1_2', FILENAME = N'D:\MSSQL\snapshot0121\erp25\ERP25_1_snapshot.ndf' ),
( NAME = N'dotnet_crm50sp1_3', FILENAME = N'D:\MSSQL\snapshot0121\erp25\ERP25_2_snapshot.ndf' ), 
 --FILEGROUP [secondary] 
( NAME = N'erp25_2', FILENAME = N'D:\MSSQL\snapshot0121\erp25\ERP25_3_snapshot.NDF'  ),
( NAME = N'erp25_2_1', FILENAME = N'D:\MSSQL\snapshot0121\erp25\ERP25_4_snapshot.ndf'  ),
( NAME = N'erp25_2_2', FILENAME = N'D:\MSSQL\snapshot0121\erp25\ERP25_5_snapshot.ndf' )
AS SNAPSHOT OF ERP25_test;
GO
 
 --ERP352 D:\MSSQL\snapshot0613\ERP352DB
 USE master
GO
--备份ERP352数据库
CREATE DATABASE MyCost_Erp352_0121_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'D:\MSSQL\snapshot0121\erp352\MyCost_Erp352_snapshot.mdf'  ),
( NAME = N'dotnet_crm352sp2', FILENAME = N'D:\MSSQL\snapshot0121\erp352\MyCost_Erp352_0_snapshot.ndf' )
AS SNAPSHOT OF MyCost_Erp352_ceshi;
GO

--ERP60 D:\MSSQL\snapshot0613\ERP60DB
 USE master
GO
CREATE DATABASE  dotnet_erp60_0121_snapshot ON
( NAME = N'dotnet_erp60', FILENAME = N'D:\MSSQL\snapshot0121\dotnet_erp60\dotnet_erp60_snapshot.mdf'  )
AS SNAPSHOT OF dotnet_erp60;
GO


--CRE_ERP_202_SYZLDB  D:\MSSQL\snapshot0613\CRE_ERP_202_SYZLDB
 USE master
GO
CREATE DATABASE CRE_ERP_202_SYZL_0121_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'D:\MSSQL\snapshot0121\CRE_ERP_202_SYZL\CRE_ERP_202_SYZL_snapshot.mdf' )
AS SNAPSHOT OF CRE_ERP_202_SYZL
GO

--/////////////////////////////////还原数据库快照///////////////////////////////////////////////
--ERP25
ALTER DATABASE ERP25_test SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
 
RESTORE DATABASE ERP25_test FROM DATABASE_SNAPSHOT = 'ERP25_0121_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('ERP25_test');
EXEC(@SQL);
ALTER DATABASE ERP25_test SET MULTI_USER;
GO

--ERP352
ALTER DATABASE MyCost_Erp352_ceshi SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
 
RESTORE DATABASE MyCost_Erp352_ceshi FROM DATABASE_SNAPSHOT = 'MyCost_Erp352_0121_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('MyCost_Erp352_ceshi');
EXEC(@SQL);
ALTER DATABASE MyCost_Erp352_ceshi SET MULTI_USER;
GO

--ERP60
ALTER DATABASE dotnet_erp60 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
 
RESTORE DATABASE dotnet_erp60 FROM DATABASE_SNAPSHOT = 'dotnet_erp60_0121_snapshot'
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
RESTORE DATABASE CRE_ERP_202_SYZL FROM DATABASE_SNAPSHOT = 'CRE_ERP_202_SYZL_0121_snapshot'
go

DECLARE @SQL VARCHAR(MAX);
SET @SQL=''
SELECT @SQL=@SQL+'; KILL '+RTRIM(SPID)
FROM master..sysprocesses
WHERE dbid=DB_ID('CRE_ERP_202_SYZL');
EXEC(@SQL);
ALTER DATABASE CRE_ERP_202_SYZL SET MULTI_USER;
GO