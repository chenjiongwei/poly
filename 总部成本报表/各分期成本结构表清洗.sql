USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_CostStructureReport_Clean]    Script Date: 2025/6/9 19:06:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      chenjw
-- Create date: 2025-04-27
-- Description: 清洗各分期成本结构表数据，插入到 cb_CostStructureReport_qx
-- 执行实例：exec [usp_cb_CostStructureReport_Clean] '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8','2025-04-28'
-- 执行实例：exec [usp_cb_CostStructureReport_Clean] '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23','2025-05-27'

-- =============================================
ALTER PROCEDURE [dbo].[usp_cb_CostStructureReport_Clean]
(
    @buguid  varchar(max)=null, -- 公司GUID
    @qxDate datetime --  查询日期
)
AS
BEGIN

    -- 如果查询日期与当天日期相差大于0，直接返回查询日期的清洗结果数据
    if ( datediff(day,@qxDate,getdate()) > 0  and @buguid is not null )
    begin
       if  EXISTS ( select  1 from  cb_CostStructureReport_qx 
        where datediff(day,清洗日期,@qxDate) = 0 
        and 公司guid in (select value from dbo.fn_Split1(@buguid,','))
        )
        print '存在清洗版本，直接返回清洗版本数据'
        return
    end

    -- 声明变量用于存储所有公司GUID（逗号分隔）
    -- DECLARE @buguid VARCHAR(MAX);
    if @buguid is null or @buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23'
    begin
            -- 获取所有公司GUID，拼接成逗号分隔字符串
        SELECT @buguid = STUFF(
            (
                SELECT distinct RTRIM(',' + CONVERT(VARCHAR(MAX), unit.buguid))
                FROM myBusinessUnit unit
                INNER JOIN p_project p ON unit.buguid = p.buguid
                WHERE IsEndCompany = 1 AND IsCompany = 1
                FOR XML PATH('')
            ), 1, 1, ''
        )
    end

    -- 创建临时表，结构与目标表一致
    CREATE TABLE #cb_CostStructureReport_temp
    (
        公司guid UNIQUEIDENTIFIER,
        公司名称 NVARCHAR(100),
        项目分期名称 NVARCHAR(100),
        项目guid UNIQUEIDENTIFIER,
        投管代码 NVARCHAR(100),
        明源系统代码 NVARCHAR(100),
        操盘方式 NVARCHAR(100),
        拿地时间 DATETIME,
        计划开工时间 DATETIME,
        实际开工时间 DATETIME,
        计划竣备时间 DATETIME,
        实际竣备时间 DATETIME,
        总建筑面积 DECIMAL(18,2),
        总可售面积 DECIMAL(18,2),
        总成本情况_考核版目标成本版本名称 NVARCHAR(100),
        总成本情况_考核版目标成本 DECIMAL(18,2),
        总成本情况_当前执行版目标成本版本名称 NVARCHAR(100),
        总成本情况_当前执行版目标成本 DECIMAL(18,2),
        总成本情况_动态成本 DECIMAL(18,2),
        总成本情况_余量池 DECIMAL(18,2),
        预留金_总预留金 DECIMAL(18,2),
        预留金_已发生预留金 DECIMAL(18,2),
        预留金_待发生预留金 DECIMAL(18,2),
        产值及支付_已完成产值 DECIMAL(18,2),
        产值及支付_已付款 DECIMAL(18,2),
        合同签订情况_已签合同数 DECIMAL(18,2),
        合同签订情况_已签合同金额 DECIMAL(18,2),
        合同签订情况_未结算的已签合同金额 DECIMAL(18,2),
        合同签订情况_未签合同数 DECIMAL(18,2),
        合同签订情况_未签合同金额 DECIMAL(18,2),
        结算_合同数 DECIMAL(18,2),
        结算_首次签约金额 DECIMAL(18,2),
        结算_结算金额 DECIMAL(18,2),
        -- 预留成本
        结算_已结算最新合约规划金额 DECIMAL(18,2),

        总价合同_首次签约为总价包干_最新合约规划金额 DECIMAL(18,2),
        总价合同_首次签约为总价包干_合同数 DECIMAL(18,2),
        总价合同_首次签约为总价包干_首次签约金额 DECIMAL(18,2),
        总价合同_首次签约为总价包干_未结算的已签合同金额 DECIMAL(18,2),
        总价合同_首次签约为总价包干_负数补协_不含暂转固 DECIMAL(18,2),
        总价合同_首次签约为总价包干_总预留金 DECIMAL(18,2),
        总价合同_首次签约为总价包干_预留金已发生 DECIMAL(18,2),
        总价合同_首次签约为总价包干_预留金待发生 DECIMAL(18,2),

        总价合同_首次签约为单价合同_目前已转总_最新合约规划金额 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_合同数 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_首次签约金额 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_暂转固金额 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_负数补协_不含暂转固 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_总预留金 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_预留金已发生 DECIMAL(18,2),
        总价合同_首次签约为单价合同_目前已转总_预留金待发生 DECIMAL(18,2),

        单价合同_首次签约为单价合同且未完成转总_最新合约规划金额 DECIMAL(18,2),
        单价合同_首次签约为单价合同且未完成转总_合同数 DECIMAL(18,2),
        单价合同_首次签约为单价合同且未完成转总_首次签约金额 DECIMAL(18,2),
        单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额 DECIMAL(18,2),
        单价合同_首次签约为单价合同且未完成转总_负数补协_不含暂转固 DECIMAL(18,2),
        单价合同_首次签约为单价合同且未完成转总_总预留金 DECIMAL(18,2),
        单价合同_首次签约为单价合同且未完成转总_预留金已发生 DECIMAL(18,2),
        单价合同_首次签约为单价合同且未完成转总_预留金待发生 DECIMAL(18,2),
        待签约_合同数 DECIMAL(18,2),
        待签约_合约规划金额 DECIMAL(18,2),
        待签约_待发生预留金 DECIMAL(18,2),
        非现金 DECIMAL(18,2),
        已发生预留金_已结算 DECIMAL(18,2),
        已发生预留金_未结算 DECIMAL(18,2)
    );

    -- 调用报表生成存储过程，将结果插入临时表
    INSERT INTO #cb_CostStructureReport_temp
    EXEC usp_rpt_cb_CostStructureReport @buguid;

    -- 删除当天已存在的清洗数据，避免重复
    DELETE FROM cb_CostStructureReport_qx
    WHERE DATEDIFF(DAY, 清洗日期, @qxDate) = 0;

    -- 插入新清洗数据，记录清洗日期
    INSERT INTO cb_CostStructureReport_qx
    SELECT GETDATE() AS 清洗日期, * FROM #cb_CostStructureReport_temp;

    -- -- 查询清洗结果
    -- SELECT * 
    -- FROM cb_CostStructureReport_qx 
    -- WHERE DATEDIFF(DAY, 清洗日期, @qxDate) = 0;

    -- 删除临时表，释放资源
    DROP TABLE #cb_CostStructureReport_temp;
END;

-- USE [MyCost_Erp352]
-- GO

-- /****** Object:  Table [dbo].[cb_CostStructureReport_qx]    Script Date: 2025/4/28 11:27:48 ******/
-- SET ANSI_NULLS ON
-- GO

-- SET QUOTED_IDENTIFIER ON
-- GO

-- CREATE TABLE [dbo].[cb_CostStructureReport_qx](
-- 	[清洗日期] [datetime] NULL,
-- 	[公司guid] [uniqueidentifier] NULL,
-- 	[公司名称] [nvarchar](100) NULL,
-- 	[项目分期名称] [nvarchar](100) NULL,
-- 	[项目guid] [uniqueidentifier] NULL,
-- 	[投管代码] [nvarchar](100) NULL,
-- 	[明源系统代码] [nvarchar](100) NULL,
-- 	[操盘方式] [nvarchar](100) NULL,
-- 	[拿地时间] [datetime] NULL,
-- 	[计划开工时间] [datetime] NULL,
-- 	[实际开工时间] [datetime] NULL,
-- 	[计划竣备时间] [datetime] NULL,
-- 	[实际竣备时间] [datetime] NULL,
-- 	[总建筑面积] [decimal](18, 2) NULL,
-- 	[总可售面积] [decimal](18, 2) NULL,
-- 	[总成本情况_考核版目标成本版本名称] [nvarchar](100) NULL,
-- 	[总成本情况_考核版目标成本] [decimal](18, 2) NULL,
-- 	[总成本情况_当前执行版目标成本版本名称] [nvarchar](100) NULL,
-- 	[总成本情况_当前执行版目标成本] [decimal](18, 2) NULL,
-- 	[总成本情况_动态成本] [decimal](18, 2) NULL,
-- 	[总成本情况_余量池] [decimal](18, 2) NULL,
-- 	[预留金_总预留金] [decimal](18, 2) NULL,
-- 	[预留金_已发生预留金] [decimal](18, 2) NULL,
-- 	[预留金_待发生预留金] [decimal](18, 2) NULL,
-- 	[产值及支付_已完成产值] [decimal](18, 2) NULL,
-- 	[产值及支付_已付款] [decimal](18, 2) NULL,
-- 	[合同签订情况_已签合同数] [decimal](18, 2) NULL,
-- 	[合同签订情况_已签合同金额] [decimal](18, 2) NULL,
-- 	[合同签订情况_未结算的已签合同金额] [decimal](18, 2) NULL,
-- 	[合同签订情况_未签合同数] [decimal](18, 2) NULL,
-- 	[合同签订情况_未签合同金额] [decimal](18, 2) NULL,
-- 	[结算_合同数] [decimal](18, 2) NULL,
-- 	[结算_首次签约金额] [decimal](18, 2) NULL,
-- 	[结算_结算金额] [decimal](18, 2) NULL,
-- 	[结算_已结算最新合约规划金额] [decimal](18, 2) NULL,

-- 	[总价合同_首次签约为总价包干_最新合约规划金额] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为总价包干_合同数] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为总价包干_首次签约金额] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为总价包干_未结算的已签合同金额] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为总价包干_负数补协_不含暂转固] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为总价包干_总预留金] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为总价包干_预留金已发生] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为总价包干_预留金待发生] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_最新合约规划金额] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_合同数] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_首次签约金额] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_暂转固金额] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_负数补协_不含暂转固] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_总预留金] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_预留金已发生] [decimal](18, 2) NULL,
-- 	[总价合同_首次签约为单价合同_目前已转总_预留金待发生] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_最新合约规划金额] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_合同数] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_首次签约金额] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_负数补协_不含暂转固] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_总预留金] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_预留金已发生] [decimal](18, 2) NULL,
-- 	[单价合同_首次签约为单价合同且未完成转总_预留金待发生] [decimal](18, 2) NULL,
-- 	[待签约_合同数] [decimal](18, 2) NULL,
-- 	[待签约_合约规划金额] [decimal](18, 2) NULL,
-- 	[待签约_待发生预留金] [decimal](18, 2) NULL,
-- 	[非现金] [decimal](18, 2) NULL
-- ) ON [PRIMARY]
-- GO


