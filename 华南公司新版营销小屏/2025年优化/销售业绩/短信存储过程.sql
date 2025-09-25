USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_hnyxxp_CompayDaySaleReport]    Script Date: 2025/8/27 15:45:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
功能：华南公司营销日报简讯清洗存储过程
调用时间：每天早上7点50分和下午19点50分执行一次，早上清洗时取昨天截止昨天的数据，晚上执行时取今天的数据
格式如下
华南公司营销日报简讯

【本日】来访267组，认购33套6492万，签约35套2675万

【本月】认购8.95亿（含特殊业绩重售0.15亿），签约4.54亿，认购未签6.09亿，内控20亿完成22.69%，集团18亿完成25.21%
【存量】认购5.46亿，签约3.01亿，集团7.5亿完成40.13%
【增量】认购1.53亿，签约0.79亿，集团2.5亿完成31.60%
【新增量】认购1.95亿，签约0.74亿，集团8亿完成9.25%
【商办】签约0.13亿，内控0.69亿完成19.09%
【车位】签约181套0.24亿，内控0.39亿完成60.09%

【本年】签约17.67亿，内控340亿完成5.20%，集团315亿完成5.61%
【存量】签约11.95亿，集团117亿完成10.21%
【增量】签约2.33亿，集团47亿完成4.96%
【新增量】签约3.39亿，集团91亿完成3.73%
【商办】签约0.70亿，内控18.71亿完成3.74%
【车位】签约1312套0.85亿，内控12.34亿完成6.88%

执行存储过程
declare @var_date datetime =dateadd(day,-1, getdate())
exec usp_s_hnyxxp_CompayDaySaleReport @var_date

declare @var_date datetime =getdate()
exec usp_s_hnyxxp_CompayDaySaleReport @var_date


2024-05-16 调整：
1、现在已经在填报表里面加了非项目本年实际签约金额、非项目本月实际签约金额、非项目本年实际认购金额、非项目本月实际认购金额这四个指标了，要分别在项目、区域、组团层级减去这四部分业绩，但是公司层级的不变；
2025-08-27 chenjw 调整：
1、销售业绩包含非项目的业绩，平衡处理中的物业代销车位以及非项目的签约金额业绩也需要考虑
*/

ALTER PROC [dbo].[usp_s_hnyxxp_CompayDaySaleReport](@var_date DATETIME)
AS
    BEGIN

		DECLARE @DayText VARCHAR(20) = '本日';
		DECLARE @MonthText VARCHAR(20) = '本月';
		DECLARE @YearText VARCHAR(20) = '本年';

		--依据传参日期判断今日还是昨日，如果是每月第一天则显示上月，如果每年的第一天则显示上年
		IF DATEDIFF(DAY, @var_date, GETDATE()) >= 1
			BEGIN
				SET @DayText = '昨日';
			END;

		IF DATEDIFF(MONTH,@var_date,GETDATE() ) >= 1
			BEGIN
				SET @MonthText = '上月';
			END;

		IF DATEDIFF(YEAR,@var_date,GETDATE()) > = 1 
			BEGIN
				SET @YearText = '上年';
			END;

        --CREATE  TABLE  s_hnyxxp_CompayDaySaleReport
        --(
        --    qxDate DATETIME, -- 清洗日期
        -- VersionGUID  UNIQUEIDENTIFIER, --清洗版本GUID
        -- VersionName  VARCHAR(200), --清洗版本名称
        -- 公司GUID UNIQUEIDENTIFIER , -- 公司GUID
        -- 公司名称 VARCHAR(200), --公司名称
        -- -- 本日
        -- 本日来访数 INT,
        -- 本日认购套数 INT,
        -- 本日认购金额 DECIMAL(18,4),
        -- 本日签约套数 INT,
        -- 本日签约金额 DECIMAL(18,4),
        -- -- 本月
        -- 本月认购套数 INT,
        -- 本月认购金额 DECIMAL(18,4),
        -- 本月其他业绩认购套数 INT,
        -- 本月其他业绩认购金额 DECIMAL(18,4),
        -- 认购未签约套数 int ,
        -- 认购未签约金额 DECIMAL(18,4),
        -- -- 本月签约
        -- 本月签约套数 INT,
        -- 本月签约金额 DECIMAL(18,4),
        -- 本月其他业绩签约套数 INT,
        -- 本月其他业绩签约金额 DECIMAL(18,4),
        -- --本月任务完成率
        -- 本月内控任务金额 DECIMAL(18,4),
        -- 本月内控任务完成率 DECIMAL(18,4),
        -- 本月集团下达任务金额 DECIMAL(18,4),
        -- 本月集团下达任务完成率 DECIMAL(18,4),

        -- --本月存量
        -- 本月存量认购套数 INT,
        -- 本月存量认购金额 DECIMAL(18,4),
        -- 本月存量其他业绩认购套数 INT,
        -- 本月存量其他业绩认购金额 DECIMAL(18,4),
        -- 本月存量签约套数 INT,
        -- 本月存量签约金额 DECIMAL(18,4),
        -- 本月存量其他业绩签约套数 INT,
        -- 本月存量其他业绩签约金额 DECIMAL(18,4),
        -- 本月存量集团下达任务金额 DECIMAL(18,4),
        -- 本月存量集团下达任务完成率 DECIMAL(18,4),
        -- --本月增量
        -- 本月增量认购套数 INT,
        -- 本月增量认购金额 DECIMAL(18,4),
        -- 本月增量其他业绩认购套数 INT,
        -- 本月增量其他业绩认购金额 DECIMAL(18,4),
        -- 本月增量签约套数 INT,
        -- 本月增量签约金额 DECIMAL(18,4),
        -- 本月增量其他业绩签约套数 INT,
        -- 本月增量其他业绩签约金额 DECIMAL(18,4),
        -- 本月增量集团下达任务金额 DECIMAL(18,4),
        -- 本月增量集团下达任务完成率 DECIMAL(18,4),

        -- --本月新增量
        -- 本月新增量认购套数 INT,
        -- 本月新增量认购金额 DECIMAL(18,4),
        -- 本月新增量其他业绩认购套数 INT,
        -- 本月新增量其他业绩认购金额 DECIMAL(18,4),
        -- 本月新增量签约套数 INT,
        -- 本月新增量签约金额 DECIMAL(18,4),
        -- 本月新增量其他业绩签约套数 INT,
        -- 本月新增量其他业绩签约金额 DECIMAL(18,4),
        -- 本月新增量集团下达任务金额 DECIMAL(18,4),
        -- 本月新增量集团下达任务完成率 DECIMAL(18,4),

        -- -- 本年
        -- 本年认购套数 INT,
        -- 本年认购金额 DECIMAL(18,4),
        -- 本年其他业绩认购套数 INT,
        -- 本年其他业绩认购金额 DECIMAL(18,4),

        -- -- 本年签约
        -- 本年签约套数 INT,
        -- 本年签约金额 DECIMAL(18,4),
        -- 本年其他业绩签约套数 INT,
        -- 本年其他业绩签约金额 DECIMAL(18,4),
        -- --本年任务完成率
        -- 本年内控任务金额 DECIMAL(18,4),
        -- 本年内控任务完成率 DECIMAL(18,4),
        -- 本年集团下达任务金额 DECIMAL(18,4),
        -- 本年集团下达任务完成率 DECIMAL(18,4),

        -- --本年存量
        -- 本年存量认购套数 INT,
        -- 本年存量认购金额 DECIMAL(18,4),
        -- 本年存量其他业绩认购套数 INT,
        -- 本年存量其他业绩认购金额 DECIMAL(18,4),
        -- 本年存量签约套数 INT,
        -- 本年存量签约金额 DECIMAL(18,4),
        -- 本年存量其他业绩签约套数 INT,
        -- 本年存量其他业绩签约金额 DECIMAL(18,4),
        -- 本年存量集团下达任务金额 DECIMAL(18,4),
        -- 本年存量集团下达任务完成率 DECIMAL(18,4),
        -- --本年增量
        -- 本年增量认购套数 INT,
        -- 本年增量认购金额 DECIMAL(18,4),
        -- 本年增量其他业绩认购套数 INT,
        -- 本年增量其他业绩认购金额 DECIMAL(18,4),
        -- 本年增量签约套数 INT,
        -- 本年增量签约金额 DECIMAL(18,4),
        -- 本年增量其他业绩签约套数 INT,
        -- 本年增量其他业绩签约金额 DECIMAL(18,4),
        -- 本年增量集团下达任务金额 DECIMAL(18,4),
        -- 本年增量集团下达任务完成率 DECIMAL(18,4),

        -- --本年新增量
        -- 本年新增量认购套数 INT,
        -- 本年新增量认购金额 DECIMAL(18,4),
        -- 本年新增量其他业绩认购套数 INT,
        -- 本年新增量其他业绩认购金额 DECIMAL(18,4),
        -- 本年新增量签约套数 INT,
        -- 本年新增量签约金额 DECIMAL(18,4),
        -- 本年新增量其他业绩签约套数 INT,
        -- 本年新增量其他业绩签约金额 DECIMAL(18,4),
        -- 本年新增量集团下达任务金额 DECIMAL(18,4),
        -- 本年新增量集团下达任务完成率 DECIMAL(18,4)
        --)

        --本日来访数
        DECLARE @brLfNum INT = 0;

        --获取华南公司的所有楼栋一级产品类型信息
        SELECT  ParentProjGUID ,
                p.ProjName AS ParentProjName ,
                TopProductTypeName ,
                TopProductTypeGUID ,
                -- 佛山市顺德区华侨中学扩建工程等7所学校代 代建项目特殊处理，归入到其它类，不要在新增量分类中出现
                MAX(CASE WHEN ISNULL(tb.营销事业部, '') = '其他' OR ISNULL(tb.营销片区, '') = '其他' THEN '其它'
                         ELSE CASE WHEN YEAR(p.BeginDate) > 2022 THEN '新增量' WHEN YEAR(p.BeginDate) = 2022 THEN '增量' ELSE '存量' END
                    END) AS 存量增量 ,
                DATEDIFF(DAY, DATEADD(yy, DATEDIFF(yy, 0, @var_date), 0), @var_date) * 1.00 / 365 本年时间分摊比 ,
                DATEDIFF(DAY, DATEADD(mm, DATEDIFF(mm, 0, @var_date), 0), @var_date) * 1.00 / 30 AS 本月时间分摊比
        INTO    #TopProduct
        FROM    data_wide_dws_mdm_Building bd
                INNER JOIN data_wide_dws_mdm_Project p ON bd.ParentProjGUID = p.ProjGUID AND   p.Level = 2
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
        WHERE   bd.BldType = '产品楼栋' AND bd.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        GROUP BY ParentProjGUID ,
                 p.ProjName ,
                 TopProductTypeName ,
                 TopProductTypeGUID;

        ---删除发送底表
        TRUNCATE TABLE s_hnyxxp_CompayDaySaleReport;

        --创建临时表
        SELECT  *
        INTO    #s_hnyxxp_projSaleNewTemp
        FROM    s_hnyxxp_projSaleNew
        WHERE   1 <> 1;

        SELECT  * INTO  #s_hnyxxp_projSaleNew FROM  s_hnyxxp_projSaleNew WHERE  1 <> 1;

        --调用华南营销看板的业绩统计存储过程计算今天的数据 或者是每个月1号凌晨进行重算
        IF DATEDIFF(DAY, @var_date, GETDATE()) = 0 OR DAY( DATEADD(DAY,1, @var_date) ) =1
            BEGIN
                --如果是清洗日期是今日则调用看板业绩统计存储过程重新计算并将结果插入临时表 #s_hnyxxp_projSaleNew
                INSERT INTO #s_hnyxxp_projSaleNewTemp EXEC usp_s_hnyxxp_projSaleNew @var_date;

                --将区域层级数据插入到临时表
                INSERT INTO #s_hnyxxp_projSaleNew
                SELECT  *
                FROM    #s_hnyxxp_projSaleNewTemp
                WHERE   DATEDIFF(DAY, @var_date, 数据清洗日期) = 0 AND 层级 = '营销大区' AND  层级名称 = '全部区域' --and  层级名称显示 <>'平衡处理'

                --获取本日来访数
                SELECT  @brLfNum = SUM(ISNULL([newVisitNum], 0) + ISNULL([oldVisitNum], 0))
                FROM    [172.16.4.141].erp25.dbo.s_YHJVisitNum a
                        INNER JOIN data_wide_dws_mdm_Project p ON a.[managementProjectGuid] = p.ProjGUID
                WHERE   p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' AND   DATEDIFF(DAY, bizdate, @var_date) = 0
                GROUP BY p.BUGUID;

            ----查询当天的数据存入临时表
            --SELECT  *
            --INTO    #s_hnyxxp_projSaleNewToday
            --FROM    #s_hnyxxp_projSaleNew
            --WHERE   层级 = '区域' AND   层级名称 = '全部区域' AND   DATEDIFF(DAY, 数据清洗日期, @var_date) = 0;

            ----查询昨天的数据存入临时表
            --SELECT  *
            --INTO    #s_hnyxxp_projSaleNewNextDay
            --FROM    s_hnyxxp_projSaleNew
            --WHERE   层级 = '区域' AND   层级名称 = '全部区域' AND   DATEDIFF(DAY, 数据清洗日期, DATEADD(DAY, -1, @var_date)) = 0;
            END;
        ELSE IF DATEDIFF(DAY, @var_date, GETDATE()) >= 1 
                 BEGIN
                     --如果清洗日期是昨天，则直接用看板存储的结果表的数据插入到临时表 #s_hnyxxp_projSaleNew
                     INSERT INTO    #s_hnyxxp_projSaleNew
                     SELECT *
                     FROM   s_hnyxxp_projSaleNew
                     WHERE  DATEDIFF(DAY, @var_date, 数据清洗日期) = 0 AND 层级 = '营销大区' AND  层级名称 = '全部区域' -- and  层级名称显示 <>'平衡处理'


                     SELECT @brLfNum = SUM(ISNULL([newVisitNum], 0) + ISNULL([oldVisitNum], 0)) --当日来访数 = 新客+旧客
                     FROM   [172.16.4.141].erp25.dbo.s_YHJVisitNum a
                            INNER JOIN data_wide_dws_mdm_Project p ON a.[managementProjectGuid] = p.ProjGUID
                     WHERE  p.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' AND   DATEDIFF(DAY, bizdate, @var_date) = 0
                     GROUP BY p.BUGUID;
                 END;

        --插入简讯结果表
        WITH #s_hnyxxp_CompayDaySaleReport AS (SELECT   @var_date AS [qxDate] ,
                                                        NEWID() AS [VersionGUID] ,
                                                        MAX( case when datediff(day,td.数据清洗日期,getdate() ) =0  then CONVERT(VARCHAR(19), td.数据清洗日期, 121)
														  else convert(varchar(10),dateadd(day,-1, getdate()),121) + ' 24:00:00' end)  AS [VersionName] ,
                                                        p.BUGUID AS [公司GUID] ,
                                                        '华南公司' AS [公司名称] ,
                                                        @brLfNum AS [本日来访数] ,
                                                        SUM( CASE WHEN  td.业态 <> '车位'  THEN   ISNULL(td.本日认购套数, 0) ELSE  0  END  ) AS [本日认购套数] ,
                                                        SUM(  ISNULL(td.本日认购金额, 0)  ) AS [本日认购金额] ,             -- 万元
                                                        SUM(ISNULL(td.本日签约套数, 0)) AS [本日签约套数] ,
                                                        SUM(ISNULL(td.本日签约金额, 0)) AS [本日签约金额] ,             -- 万元
                                                        SUM(ISNULL(td.本月认购套数, 0)) AS [本月认购套数] ,
                                                        SUM( ISNULL(td.本月认购金额, 0) ) / 10000.0 AS [本月认购金额] ,   --亿元
                                                        SUM(ISNULL(其他业绩本月认购套数, 0)) AS [本月其他业绩认购套数] ,
                                                        SUM(ISNULL(其他业绩本月认购金额, 0)) / 10000.0 AS [本月其他业绩认购金额] ,
                                                        SUM(ISNULL(已认购未签约套数, 0)) AS [认购未签约套数] ,
                                                        SUM(ISNULL(已认购未签约金额, 0)) / 10000.0 AS [认购未签约金额] ,   --亿元
                                                        SUM(ISNULL(本月签约套数, 0)) AS [本月签约套数] ,
                                                        SUM(ISNULL(本月签约金额, 0) ) / 10000.0 AS [本月签约金额] ,      --亿元
                                                        0 AS [本月其他业绩签约套数] ,
                                                        0 AS [本月其他业绩签约金额] ,
                                                        SUM(ISNULL(本月任务, 0)) / 10000.0 AS [本月内控任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本月任务, 0)) = 0 THEN 0 ELSE 
														   CONVERT(DECIMAL(18,2),    SUM( ISNULL(本月签约金额, 0)  )/ 10000.0 ) / SUM(ISNULL(本月任务, 0) /10000.0 )END AS [本月内控任务完成率] ,

                                                        SUM(ISNULL(本月存量任务, 0) + ISNULL(本月增量任务, 0) + ISNULL(本月新增量任务, 0)) / 10000.0 AS [本月集团下达任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本月存量任务, 0) + ISNULL(本月增量任务, 0) + ISNULL(本月新增量任务, 0)) = 0 THEN 0
                                                             ELSE 
															   CONVERT(DECIMAL(18,2),  SUM(ISNULL(本月签约金额, 0) ) /10000.0 )  / SUM( (ISNULL(本月存量任务, 0) + ISNULL(本月增量任务, 0) + ISNULL(本月新增量任务, 0)) /10000.0  )
                                                        END AS [本月集团下达任务完成率] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本月认购套数, 0)ELSE 0 END) AS [本月存量认购套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本月认购金额, 0 )   ELSE 0 END) / 10000.0 AS [本月存量认购金额] ,
                                                        0 AS [本月存量其他业绩认购套数] ,
                                                        0 AS [本月存量其他业绩认购金额] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本月签约套数, 0)ELSE 0 END) AS [本月存量签约套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本月签约金额, 0)  ELSE 0 END) / 10000.0 AS [本月存量签约金额] ,
                                                        0 AS [本月存量其他业绩签约套数] ,
                                                        0 AS [本月存量其他业绩签约金额] ,
                                                        SUM(ISNULL(本月存量任务, 0)) / 10000.0 AS [本月存量集团下达任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本月存量任务, 0)) = 0 
														    THEN 0 
														    ELSE 
															CONVERT(DECIMAL(18,2), SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本月签约金额, 0)  ELSE 0 END) /10000.0 )  /  SUM(ISNULL(本月存量任务, 0) / 10000.0 )  END 
														AS [本月存量集团下达任务完成率] ,
                                                        SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本月认购套数, 0)  ELSE 0 END) AS [本月增量认购套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本月认购金额, 0)  ELSE 0 END) / 10000.0 AS [本月增量认购金额] ,
                                                        0 AS [本月增量其他业绩认购套数] ,
                                                        0 AS [本月增量其他业绩认购金额] ,
                                                        SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本月签约套数, 0)  ELSE 0 END) AS [本月增量签约套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本月签约金额, 0)  ELSE 0 END) / 10000.0 AS [本月增量签约金额] ,
                                                        0 AS [本月增量其他业绩签约套数] ,
                                                        0 AS [本月增量其他业绩签约金额] ,
                                                        SUM(ISNULL(本月增量任务, 0)) / 10000.0 AS [本月增量集团下达任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本月增量任务, 0)) = 0 THEN 0 
														    ELSE  CONVERT(DECIMAL(18,2),  SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本月签约金额, 0)    ELSE 0 END)/10000.0)  / 
															   SUM(ISNULL(本月增量任务, 0)/ 10000.0)END AS [本月增量集团下达任务完成率] ,

                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本月认购套数, 0) ELSE 0 END) AS [本月新增量认购套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本月认购金额, 0) ELSE 0 END) / 10000.0 AS [本月新增量认购金额] ,
                                                        0 AS [本月新增量其他业绩认购套数] ,
                                                        0 AS [本月新增量其他业绩认购金额] ,
                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本月签约套数, 0)  ELSE 0 END) AS [本月新增量签约套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本月签约金额, 0)  ELSE 0 END) / 10000.0 AS [本月新增量签约金额] ,
                                                        0 AS [本月新增量其他业绩签约套数] ,
                                                        0 AS [本月新增量其他业绩签约金额] ,
                                                        SUM(ISNULL(本月新增量任务, 0)) / 10000.0 AS [本月新增量集团下达任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本月新增量任务, 0)) = 0 THEN 0 
														    ELSE 
															  CONVERT(DECIMAL(18,2),  SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本月签约金额, 0)  ELSE 0 END ) /10000.0) /  SUM(ISNULL(本月新增量任务, 0) /10000.0 )
															END AS [本月新增量集团下达任务完成率] ,
                                                        SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本月任务, 0)ELSE 0 END) / 10000.0 AS [本月商办内控任务金额] ,
                                                        SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本月签约金额, 0)   ELSE 0 END) / 10000.0 AS [本月商办签约金额] ,
                                                        CASE WHEN SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本月任务, 0)ELSE 0 END) = 0 THEN 0
                                                             ELSE CONVERT(DECIMAL(18,2),   SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本月签约金额, 0)   ELSE 0 END) /10000.0)  
															    /  SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本月任务, 0) /10000.0 ELSE 0 END)
                                                        END AS [本月商办签约完成率] ,
                                                        SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本月任务, 0)ELSE 0 END) / 10000.0 AS [本月车位内控任务金额] ,
                                                        SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本月签约金额, 0)   ELSE 0 END) / 10000.0 AS [本月车位签约金额] ,
                                                        SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本月签约套数, 0)ELSE 0 END) AS [本月车位签约套数] ,
                                                        CASE WHEN SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本月任务, 0)ELSE 0 END) = 0 THEN 0
                                                             ELSE CONVERT(DECIMAL(18,2),  SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本月签约金额, 0)  ELSE 0 END)  /10000.0 ) /   SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本月任务, 0) /10000.0 ELSE 0 END)
                                                        END AS [本月车位签约完成率] ,
														
														--本年
                                                        SUM(ISNULL(本年认购套数, 0)) AS [本年认购套数] ,
                                                        SUM(ISNULL(本年认购金额, 0)) / 10000.0 AS [本年认购金额] ,
                                                        0 AS [本年其他业绩认购套数] ,
                                                        0 AS [本年其他业绩认购金额] ,
                                                        SUM(ISNULL(本年签约套数, 0)) AS [本年签约套数] ,
                                                        SUM(ISNULL(本年签约金额, 0)) / 10000.0 AS [本年签约金额] ,
                                                        0 AS [本年其他业绩签约套数] ,
                                                        0 AS [本年其他业绩签约金额] ,
                                                        SUM(ISNULL(本年任务, 0)) / 10000.0 AS [本年内控任务金额] ,      --亿元
                                                        CASE WHEN SUM(ISNULL(本年任务, 0)) = 0 THEN 0 
														   ELSE CONVERT(DECIMAL(18,2),  SUM(ISNULL(本年签约金额, 0)) /10000.0) / SUM(ISNULL(本年任务, 0) /10000.0) END AS [本年内控任务完成率] ,
                                                        SUM(ISNULL(本年存量任务, 0) + ISNULL(本年增量任务, 0) + ISNULL(本年新增量任务, 0)) / 10000.0 AS [本年集团下达任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本年存量任务, 0) + ISNULL(本年增量任务, 0) + ISNULL(本年新增量任务, 0)) = 0 THEN 0
                                                             ELSE CONVERT(DECIMAL(18,2),  SUM( ISNULL(本年签约金额, 0))/10000.0) / SUM( ( ISNULL(本年存量任务, 0) + ISNULL(本年增量任务, 0) + ISNULL(本年新增量任务, 0)) /10000.0 )
                                                        END AS [本年集团下达任务完成率] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本年认购套数, 0)ELSE 0 END) AS [本年存量认购套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本年认购金额, 0)  ELSE 0 END) / 10000.0 AS [本年存量认购金额] ,
                                                        0 AS [本年存量其他业绩认购套数] ,
                                                        0 AS [本年存量其他业绩认购金额] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本年签约套数, 0)ELSE 0 END) AS [本年存量签约套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本年签约金额, 0)  ELSE 0 END) / 10000.0 AS [本年存量签约金额] ,
                                                        0 AS [本年存量其他业绩签约套数] ,
                                                        0 AS [本年存量其他业绩签约金额] ,
                                                        SUM(ISNULL(本年存量任务, 0)) / 10000.0 AS [本年存量集团下达任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本年存量任务, 0)) = 0 THEN 0 
														    ELSE CONVERT(DECIMAL(18,2),  SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本年签约金额, 0)   ELSE 0 END)/10000.0 ) /  SUM(ISNULL(本年存量任务, 0) /10000.0 ) END AS [本年存量集团下达任务完成率] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本年认购套数, 0) ELSE 0 END) AS [本年增量认购套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '存量' THEN ISNULL(td.本年认购金额, 0) ELSE 0 END) / 10000.0 AS [本年增量认购金额] ,
                                                        0 AS [本年增量其他业绩认购套数] ,
                                                        0 AS [本年增量其他业绩认购金额] ,
                                                        SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本年签约套数, 0)ELSE 0 END) AS [本年增量签约套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本年签约金额, 0)   ELSE 0 END) / 10000.0 AS [本年增量签约金额] ,
                                                        0 AS [本年增量其他业绩签约套数] ,
                                                        0 AS [本年增量其他业绩签约金额] ,
                                                        SUM(ISNULL(本年增量任务, 0)) / 10000.0 AS [本年增量集团下达任务金额] ,
                                                        CASE WHEN SUM(ISNULL(本年增量任务, 0)) = 0 THEN 0 ELSE 
														      CONVERT(DECIMAL(18,2),  SUM(CASE WHEN td.存量增量 = '增量' THEN ISNULL(td.本年签约金额, 0)   ELSE 0 END ) /10000.0 )   / SUM( ISNULL(本年增量任务, 0)  /10000.0 ) END AS [本年增量集团下达任务完成率] ,
                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本年认购套数, 0)ELSE 0 END) AS [本年新增量认购套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本年认购金额, 0)  ELSE 0 END) / 10000.0 AS [本年新增量认购金额] ,
                                                        0 AS [本年新增量其他业绩认购套数] ,
                                                        0 AS [本年新增量其他业绩认购金额] ,
                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本年签约套数, 0)ELSE 0 END) AS [本年新增量签约套数] ,
                                                        SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本年签约金额, 0)   ELSE 0 END) / 10000.0 AS [本年新增量签约金额] ,
                                                        0 AS [本年新增量其他业绩签约套数] ,
                                                        0 AS [本年新增量其他业绩签约金额] ,
                                                        SUM(ISNULL(本年新增量任务, 0)) / 10000.0 AS [本年新增量集团下达任务金额] ,
                                                        CASE WHEN  SUM(ISNULL(本年新增量任务, 0)) = 0 THEN 0 ELSE 
														    CONVERT(DECIMAL(18,2),   SUM(CASE WHEN td.存量增量 = '新增量' THEN ISNULL(td.本年签约金额, 0)   ELSE 0 END) /10000.0 )  /  SUM(ISNULL(本年新增量任务, 0) /10000.0 )END AS [本年新增量集团下达任务完成率] ,
                                                        SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本年任务, 0)ELSE 0 END) / 10000.0 AS [本年商办内控任务金额] ,
                                                        SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本年签约金额, 0)  ELSE 0 END) / 10000.0 AS [本年商办签约金额] ,
                                                        CASE WHEN SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本年任务, 0)ELSE 0 END) = 0 THEN 0
                                                             ELSE CONVERT(DECIMAL(18,2),  SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本年签约金额, 0) ELSE 0 END)/10000.0)  / SUM(CASE WHEN td.业态 = '商办' THEN ISNULL(本年任务, 0) /10000.0 ELSE 0 END)
                                                        END AS [本年商办签约完成率] ,
                                                        SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本年任务, 0)ELSE 0 END) / 10000.0 AS [本年车位内控任务金额] ,
                                                        SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本年签约金额, 0)   ELSE 0 END) / 10000.0 AS [本年车位签约金额] ,
                                                        SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本年签约套数, 0)ELSE 0 END) AS [本年车位签约套数] ,
                                                        CASE WHEN SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本年任务, 0)ELSE 0 END) = 0 THEN 0
                                                             ELSE CONVERT(DECIMAL(18,2),  SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本年签约金额, 0)  ELSE 0 END)/10000.0) /  SUM(CASE WHEN td.业态 = '车位' THEN ISNULL(本年任务, 0) /10000.0 ELSE 0 END)
                                                        END AS [本年车位签约完成率],
														sum(ISNULL(td.非项目本年实际签约金额,0 )) AS 非项目本年实际签约金额,
														sum(ISNULL(td.非项目本月实际签约金额,0 )) AS 非项目本月实际签约金额,
														sum(ISNULL(td.非项目本年实际认购金额,0 )) AS 非项目本年实际认购金额,
														sum(ISNULL(td.非项目本月实际认购金额,0 )) AS 非项目本月实际认购金额
                                               FROM data_wide_dws_mdm_Project p
                                                    INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                                                    LEFT JOIN #s_hnyxxp_projSaleNew td ON p.projguid = td.项目GUID AND pt.TopProductTypeName = td.产品类型
                                               GROUP BY p.BUGUID)

        INSERT INTO s_hnyxxp_CompayDaySaleReport
        SELECT  * ,
                '【'+@DayText +'】来访' + CONVERT(VARCHAR(20), 本日来访数) + '组，认购' + CONVERT(VARCHAR(20), 本日认购套数) + '套' + CONVERT( VARCHAR(20), CONVERT(DECIMAL(18,0), ROUND( 本日认购金额, 0) ) ) + '万，签约' + CONVERT(VARCHAR(20),本日签约套数)+'套' + CONVERT( VARCHAR(20), CONVERT(DECIMAL(18,0), ROUND(本日签约金额, 0) ) )  +'万<br/>' +
                + '【'+@MonthText +'】认购'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月认购金额, 2))) +'亿（含特殊业绩重售'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月其他业绩认购金额, 2))) +'亿），签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月签约金额, 2)))
			    +'亿，认购未签'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(认购未签约金额, 2)))  +'亿,华南'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月内控任务金额, 2)))+'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月内控任务完成率*100, 2))) +'%，集团'+  CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月集团下达任务金额, 2)))  +'亿完成'+CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月集团下达任务完成率*100, 2))) +'%<br/>'
                +'【存量】认购'+CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月存量认购金额, 2)))  +'亿，签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月存量签约金额, 2))) +'亿，集团'+CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月存量集团下达任务金额, 2)))+'亿完成' +CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月存量集团下达任务完成率*100, 2))) + '%<br/>' 
				+ '【增量】认购'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月增量认购金额, 2))) +'亿，签约'+  CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月增量签约金额, 2))) +'亿，集团'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月增量集团下达任务金额, 2))) +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月增量集团下达任务完成率*100, 2)))  +'%<br/>'
                + '【新增量】认购'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月新增量认购金额, 2))) +'亿，签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月新增量签约金额, 2)))  +'亿，集团'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月新增量集团下达任务金额, 2))) +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月新增量集团下达任务完成率*100, 2)))   +'%<br/>' 
				+ '【商办】签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月商办签约金额, 2))) +'亿，华南'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月商办内控任务金额, 2)))  +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月商办签约完成率*100, 2)))+'%<br/>'
                + '【车位】签约'+ CONVERT(VARCHAR(20), 本月车位签约套数)  +'套'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月车位签约金额, 2)))  +'亿，华南'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月车位内控任务金额, 2))) +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本月车位签约完成率*100, 2)))   +'%<br/><br/>' 
				
				+ '【'+ @YearText +'】签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年签约金额, 2)))  +'亿，华南'+  CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,0), ROUND(本年内控任务金额, 0))) +'亿完成'+  CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年内控任务完成率*100, 2))) +'%，集团'+  CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,0), ROUND(本年集团下达任务金额, 0)))  +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年集团下达任务完成率*100, 2)))  +'%<br/>'
                + '【存量】签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年存量签约金额, 2)))  +'亿，集团'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,0), ROUND(本年存量集团下达任务金额, 0)))  +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年存量集团下达任务完成率*100, 2)))  +'%<br/>' 
				+ '【增量】签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年增量签约金额, 2)))  +'亿，集团'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,0), ROUND(本年增量集团下达任务金额, 0))) +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年增量集团下达任务完成率*100, 2))) +'%<br/>'
                + '【新增量】签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年新增量签约金额, 2))) +'亿，集团'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,0), ROUND(本年新增量集团下达任务金额, 0))) +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年新增量集团下达任务完成率*100, 2)))  +'%<br/>' 
				+ '【商办】签约'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年商办签约金额, 2)))   +'亿，华南'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年商办内控任务金额, 2)))  +'亿完成'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年商办签约完成率*100, 2)))  +'%<br/>'
                + '【车位】签约'+ CONVERT(VARCHAR(20), 本年车位签约套数) +'套'+CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年车位签约金额, 2)))  +'亿，华南'+ CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年车位内控任务金额, 2))) +'亿完成'+CONVERT(VARCHAR(20), CONVERT(DECIMAL(18,2), ROUND(本年车位签约完成率*100, 2))) +'%<br/>' 
				AS 简讯内容,@DayText AS 日显示文本, @MonthText AS 月显示文本,@YearText AS 年显示文本
        FROM    #s_hnyxxp_CompayDaySaleReport;

		-- 将短信发送的内容存储到s_hnyxxp_CompayDaySaleReportHistory表中,方便后续导出
		insert into  s_hnyxxp_CompayDaySaleReportHistory
		select  * from  s_hnyxxp_CompayDaySaleReport  

        --查询简讯
        SELECT  * FROM  s_hnyxxp_CompayDaySaleReport;

        --删除临时表
        DROP TABLE #s_hnyxxp_projSaleNew ,
                   #s_hnyxxp_projSaleNewTemp;
    END;
