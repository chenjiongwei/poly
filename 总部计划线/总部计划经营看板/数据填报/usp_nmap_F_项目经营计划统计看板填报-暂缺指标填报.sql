CREATE OR ALTER PROC [dbo].[usp_nmap_F_项目经营计划统计看板填报]
(
    @CLEANDATE DATETIME,                -- 清理日期
    @DATABASENAME VARCHAR(100),         -- 数据库名称
    @FILLHISTORYGUID UNIQUEIDENTIFIER,  -- 当前填报历史版本GUID
    @ISCURRFILLHISTORY BIT              -- 是否为当前批次（1为当前，0为历史）
)
AS
BEGIN
    -- 打印输入参数，便于调试和日志追踪
    PRINT @CLEANDATE; 
    PRINT @DATABASENAME;  
    PRINT @FILLHISTORYGUID; 
    PRINT @ISCURRFILLHISTORY; 

    DECLARE @STRSQL VARCHAR(MAX);   -- 预留动态SQL变量（当前未使用）
    DECLARE @COUNTNUM INT;          -- 计数变量

    -- 1. 判断是否为最新版本，若不是则不进行后续操作
    DECLARE @FILLHISTORYGUIDNEW UNIQUEIDENTIFIER;
    SELECT TOP 1 
        @FILLHISTORYGUIDNEW = A.FILLHISTORYGUID
    FROM NMAP_F_FILLHISTORY A
    WHERE FILLDATAGUID = (
            SELECT FILLDATAGUID
            FROM NMAP_F_FILLDATA
            WHERE FILLNAME = '项目经营计划统计看板填报'
        )
    ORDER BY ENDDATE DESC;

    IF @FILLHISTORYGUID <> @FILLHISTORYGUIDNEW
    BEGIN
        PRINT N'该版本不是最新版本，故不更新';
        RETURN;
    END

    -- 2. 判断当前版本是否已有数据，若有则不刷新组织架构
    SELECT @COUNTNUM = COUNT(1)
    FROM NMAP_F_项目经营计划统计看板填报
    WHERE ISNULL(投管代码, '') <> ''
      AND FILLHISTORYGUID = @FILLHISTORYGUID;

    IF @COUNTNUM > 0
    BEGIN
        PRINT N'当前版本有数据，不刷新组织架构信息';
        RETURN;
    END

    -- 3. 若为当前批次且无数据，则刷新组织纬度（组织架构）
    SELECT @COUNTNUM = COUNT(1)
    FROM NMAP_F_项目经营计划统计看板填报
    WHERE ISNULL(项目名称, '') <> ''
      AND FILLHISTORYGUID = @FILLHISTORYGUID;

    IF @ISCURRFILLHISTORY = 1 AND @COUNTNUM = 0
    BEGIN
        PRINT N'新生成版本需要重新刷新组织架构信息';
        EXEC dbo.USP_NMAP_S_FILLDATASYNCH_RECREATEBATCH @FILLHISTORYGUID = @FILLHISTORYGUID;
    END

    -- 4. 获取截至日期最后且有数据的历史版本GUID，用于数据继承
    DECLARE @FILLHISTORYGUIDLAST UNIQUEIDENTIFIER;
    SELECT TOP 1
        @FILLHISTORYGUIDLAST = A.FILLHISTORYGUID
    FROM NMAP_F_FILLHISTORY A
    WHERE FILLDATAGUID = (
            SELECT FILLDATAGUID
            FROM NMAP_F_FILLDATA
            WHERE FILLNAME = '项目经营计划统计看板填报'
        )
      AND FILLHISTORYGUID IN (
            SELECT DISTINCT FILLHISTORYGUID
            FROM NMAP_F_项目经营计划统计看板填报
            WHERE ISNULL(投管代码, '') <> ''
        )
      -- 可根据需要启用审核状态过滤
      -- AND A.APPROVESTATUS = '已审核'
      -- AND A.FILLHISTORYGUID <> @FILLHISTORYGUID
    ORDER BY ENDDATE DESC;

    -- 5. 生成临时表，准备插入新数据
    SELECT 
        NEWID() AS [项目经营计划统计看板填报GUID],         -- 新主键
        @FILLHISTORYGUID AS [FillHistoryGUID],              -- 当前版本GUID
        c.CompanyGUID AS [BusinessGUID],                    -- 业务公司GUID
        c.CompanyName AS [公司简称],                        -- 公司简称
        ISNULL(d.项目名称, proj.项目名) AS [项目名称],       -- 项目名称（优先继承历史数据）
        ISNULL(d.项目GUID, proj.projguid) AS [项目GUID],    -- 项目GUID
        ISNULL(d.项目代码, proj.项目代码) AS [项目代码],    -- 项目代码
        ISNULL(d.投管代码, proj.投管代码) AS [投管代码],    -- 投管代码

        -- 投资假定条件偏差（动态版同立项版偏差）
        ISNULL(d.[首开去化套数_立项版], NULL) AS [首开去化套数_立项版],
        ISNULL(d.[续销流速累计套数_立项版], NULL) AS [续销流速累计套数_立项版],
        ISNULL(d.[续销流速累计本月套数_立项版], NULL) AS [续销流速累计本月套数_立项版],
        ISNULL(d.[续销流速累计本月金额_立项版], NULL) AS [续销流速累计本月金额_立项版],

        -- 总收入指标
        ISNULL(d.[住宅总可售单方成本(真实版)], NULL) AS [住宅总可售单方成本(真实版)],
        ISNULL(d.[住宅已签约销净率(真实版）], NULL) AS [住宅已签约销净率(真实版）],
        ISNULL(d.[商办总可售单方成本(真实版)], NULL) AS [商办总可售单方成本(真实版)],
        ISNULL(d.[商办已签约销净率(真实版)], NULL) AS [商办已签约销净率(真实版)],
        ISNULL(d.[车位总可售单方成本(真实版)], NULL) AS [车位总可售单方成本(真实版)],
        ISNULL(d.[车位已签约销净率(真实版)], NULL) AS [车位已签约销净率(真实版)],

        -- 总投资指标
        ISNULL(d.[财务费用(复利）截止本月], NULL) AS [财务费用(复利）截止本月],
        ISNULL(d.[财务费用(复利）截止上月], NULL) AS [财务费用(复利）截止上月],
        ISNULL(d.[已发生财务费用（单利）], NULL) AS [已发生财务费用（单利）],

        -- 现金流指标
        ISNULL(d.[股东投资峰值_立项版], NULL) AS [股东投资峰值_立项版],
        ISNULL(d.[股东投资峰值_动态版], NULL) AS [股东投资峰值_动态版],
        ISNULL(d.[机会成本损失], NULL) AS [机会成本损失],
        ISNULL(d.[机会成本损失对应单方成本], NULL) AS [机会成本损失对应单方成本],

        -- 资产负债情况
        ISNULL(d.[原始股东投入], NULL) AS [原始股东投入],
        ISNULL(d.[贷款还款计划], NULL) AS [贷款还款计划],

        -- 系统信息
        ISNULL(d.[最后导入人], N'系统管理员') AS [最后导入人],
        ISNULL(d.[最后导入时间], GETDATE()) AS [最后导入时间],
        NULL AS [RowID]   -- 预留RowID字段
    INTO #TempData
    FROM erp25.dbo.vmdm_projectFlagnew proj
        LEFT JOIN erp25.dbo.p_DevelopmentCompany b
            ON proj.平台公司 = b.DevelopmentCompanyName
        LEFT JOIN nmap_N_CompanyToTerraceBusiness c2b
            ON b.DevelopmentCompanyGUID = c2b.DevelopmentCompanyGUID
        LEFT JOIN nmap_N_Company c
            ON c2b.CompanyGUID = c.CompanyGUID
        -- 查询上一版的数据进行继承
        LEFT JOIN (
            SELECT DISTINCT *
            FROM NMAP_F_项目经营计划统计看板填报
            WHERE FILLHISTORYGUID = @FILLHISTORYGUIDLAST
              AND ISNULL(投管代码, '') <> ''
        ) d
            ON d.项目GUID = proj.projguid

    -- 6. 删除当前版本的旧数据，避免重复
    DELETE FROM NMAP_F_项目经营计划统计看板填报
    WHERE FillHistoryGUID = @FillHistoryGUID;

    -- 7. 插入新数据到正式表
    INSERT INTO NMAP_F_项目经营计划统计看板填报 (
        [项目经营计划统计看板填报GUID],
        [FillHistoryGUID],
        [BusinessGUID],
        [公司简称],
        [项目名称],
        [项目GUID],
        [项目代码],
        [投管代码],
        [首开去化套数_立项版],
        [续销流速累计套数_立项版],
        [续销流速累计本月套数_立项版],
        [续销流速累计本月金额_立项版],
        [住宅总可售单方成本(真实版)],
        [住宅已签约销净率(真实版）],
        [商办总可售单方成本(真实版)],
        [商办已签约销净率(真实版)],
        [车位总可售单方成本(真实版)],
        [车位已签约销净率(真实版)],
        [财务费用(复利）截止本月],
        [财务费用(复利）截止上月],
        [已发生财务费用（单利）],
        [股东投资峰值_立项版],
        [股东投资峰值_动态版],
        [机会成本损失],
        [机会成本损失对应单方成本],
        [原始股东投入],
        [贷款还款计划],
        [最后导入人],
        [最后导入时间],
        [RowID]
    )
    SELECT * FROM #TempData;

END
