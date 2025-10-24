
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

USE master
GO
-- 备份ERP352数据库快照
CREATE DATABASE MyCost_Erp352_1024_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'G:\snapshot\ERP352\MyCost_Erp352_snapshot.mdf' ),
( NAME = N'dotnet_crm352sp2', FILENAME = N'G:\snapshot\ERP352\MyCost_Erp352_0_snapshot.ndf' )
AS SNAPSHOT OF MyCost_Erp352;
GO


USE master
GO
-- 备份ERP60数据库快照
CREATE DATABASE  dotnet_erp60_1024_snapshot ON
( NAME = N'dotnet_erp60', FILENAME = N'G:\snapshot\ERP60\dotnet_erp60_snapshot.mdf'  )
AS SNAPSHOT OF dotnet_erp60;
GO

USE master
GO
CREATE DATABASE CRE_ERP_202_SYZL_1024_snapshot ON
( NAME = N'dotnet_crm50sp1', FILENAME = N'G:\snapshot\CRE_ERP_202_SYZL\CRE_ERP_202_SYZL_snapshot.mdf' )
AS SNAPSHOT OF CRE_ERP_202_SYZL
GO


USE master
GO
-- 备份TaskCenterData数据库快照
CREATE DATABASE TaskCenterData_1024_snapshot ON
( NAME = N'TaskCenterData', FILENAME = N'G:\snapshot\TaskCenterData\TaskCenterData_snapshot.mdf' )
AS SNAPSHOT OF TaskCenterData
GO