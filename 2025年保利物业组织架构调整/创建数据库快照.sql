-- 创建费用系统数据库快照
CREATE DATABASE [dotnet_erp60_fy_0331_snapshot] ON
( NAME = N'dotnet_erp60', FILENAME = N'E:\Mysoft_DB\dotnet_erp60_fy_snapshot\dotnet_erp60_snapshot.mdf'  )
AS SNAPSHOT OF dotnet_erp60_fy
go 



-- 创建采招系统数据库快照
CREATE DATABASE [dotnet_erp60_cz_0331_snapshot] ON
( NAME = N'dotnet_erp60', FILENAME = N'E:\Mysoft\database\dotnet_erp60_cz_snapshot\dotnet_erp60_snapshot.mdf'  )
AS SNAPSHOT OF dotnet_erp60_cz
go 


-- 创建工作流数据库快照
