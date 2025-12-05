-- 开工申请存储过程清洗存储过程

-- ============================================
-- 存储过程名称：usp_s_集团开工申请索引表智能体数据提取
-- 创建人:chenjw 2025-09-02
-- 作用：清洗并提取集团开工申请索引表数据，供智能体使用
-- ============================================
CREATE OR ALTER PROC [dbo].[usp_s_集团开工申请索引表智能体数据提取]
AS
BEGIN
    -- ==========================================================
    -- 步骤1：从项目主数据表中筛选level=2的项目，插入临时表#index
    -- 说明：只保留集团层级的项目，其他字段暂时置为NULL
    -- ==========================================================
       SELECT 
            ROW_NUMBER() OVER (PARTITION BY a.项目GUID ORDER BY a.承诺时间 DESC) AS rownum,
            a.存货去化承诺ID,
            a.投管代码,
            a.项目GUID,
            a.项目名称,
            a.推广名称,
            a.承诺时间,
            '承诺值' AS [类型],
            b.FillDate as [填报日期],
            a.已开工未售部分的的产品楼栋编码,
            a.已开工未售部分的的产品楼栋名称,
            CONVERT(VARCHAR(7), a.已开工未售部分的售罄时间, 121) AS [已开工未售部分的售罄时间]
        INTO #chtb
        FROM [172.16.4.141].dss.[dbo].nmap_F_存货去化承诺表 a
        INNER JOIN [172.16.4.141].dss.[dbo].[nmap_F_FillHistory] b
            ON a.[FillHistoryGUID] = b.[FillHistoryGUID]
        WHERE a.[FillHistoryGUID] IN (
                SELECT TOP 1 [FillHistoryGUID]
                FROM [172.16.4.141].dss.[dbo].nmap_F_存货去化承诺表
                ORDER BY [FillDate] DESC
            )

       SELECT 
            a.本次新推量价承诺ID AS [本次新推量价承诺ID], 
            a.投管代码 AS [投管代码],
            a.项目GUID AS [项目GUID],
            a.项目名称 AS [项目名称],
            a.推广名称 as [推广名称] ,
            a.承诺时间 as  [承诺时间],
            b.FillDate as [填报日期],
            a.产品楼栋编码 as 本批开工的产品楼栋GUID,
            a.产品楼栋编码 as 本批开工的产品楼栋编码,
            a.产品楼栋名称 as 本批开工的产品楼栋名称
        --   a.[业态销售均价及销净率承诺]               AS [业态销售均价及销净率承诺]               -- 业态销售均价及销净率承诺      
        INTO #xttb
        FROM [172.16.4.141].dss.[dbo].[nmap_F_本次新推价量承诺表] a
        INNER JOIN [172.16.4.141].dss.[dbo].[nmap_F_FillHistory] b  
            ON a.[FillHistoryGUID] = b.[FillHistoryGUID]
        WHERE a.[FillHistoryGUID] IN (
            SELECT TOP 1 [FillHistoryGUID]
            FROM [172.16.4.141].dss.[dbo].[nmap_F_本次新推价量承诺表]
            ORDER BY [FillDate] DESC
        ) 


    SELECT 
        p.TgProjCode                                 AS [投管代码],             -- 投管系统项目代码
        p.projguid                                  AS [项目GUID],             -- 项目唯一标识
        p.ProjName                                  AS [项目名称],             -- 项目名称
        p.SpreadName                                AS [推广名称],             -- 推广名称
        -- 7216-2025-09-02
        -- “审批单号”格式为“7216-2025-09-02”,四位流水号+填报日期
        p.TgProjCode + '-' + 
        ISNULL(
            CONVERT(varchar(10), ISNULL(ch.填报日期, xt.填报日期),  23), 
            ''
        ) AS [审批单号],                                -- 审批单号，流水号+填报日期
        -- 徐州学府项目（徐州市铜山XT2023-17凤凰路南大学路东地块）_开工申请单_20250902
        -- 审批单名称 = 推广名称 + 项目名称 + _开工申请单_ + 填报日期(格式20250902)
        ISNULL( p.SpreadName, '') + '(' + ISNULL(p.ProjName, '') + ')_开工申请单_' + 
        ISNULL(
            REPLACE(CONVERT(VARCHAR(8), ISNULL(ch.填报日期, xt.填报日期), 112), '-', ''), 
            ''
        ) AS [审批单名称],           -- 审批单名称，推广名称+项目名称+开工申请单+填报日期
        ch.存货去化承诺ID                           AS [存货去化承诺ID],       -- 存货去化承诺ID，后续补充
        xt.本次新推量价承诺ID                       AS [本次新推量价承诺ID],   -- 本次新推量价承诺ID，后续补充
        CASE 
            WHEN ch.rownum = 1 THEN '是' 
            ELSE '否' 
        END                                         AS [是否为当前最新版],     -- 是否为当前最新版，后续补充
        ch.承诺时间                                 AS [承诺时间],             -- 承诺时间，后续补充
        NULL                                        AS [归档时间],             -- 归档时间，后续补充
        '系统管理员'                                 AS [责任人],               -- 责任人，后续补充
        '13900000000'                               AS [联系电话]              -- 联系电话，后续补充
    INTO #index
    FROM 
        data_wide_dws_mdm_Project p
        left join #chtb ch on ch.项目GUID =p.projguid
        left join #xttb xt on xt.项目GUID = p.projguid
        -- LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.存货去化承诺表 ch  ON ch.项目GUID = p.projguid
        -- LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.本次新推承诺表 xt  ON xt.项目GUID = p.projguid
        -- LEFT JOIN (
        --     SELECT  
        --         ROW_NUMBER() OVER (PARTITION BY 项目GUID ORDER BY 承诺时间 DESC) AS rownum,
        --         存货去化承诺ID  
        --     FROM  
        --         [172.16.4.141].[MyCost_Erp352].dbo.存货去化承诺表 
        -- ) px ON px.存货去化承诺ID = ch.存货去化承诺ID
    WHERE 
        p.level = 2 
        AND (
            xt.本次新推量价承诺ID IS NOT NULL 
            OR ch.存货去化承诺ID IS NOT NULL
        )

    -- ==========================================================
    -- 步骤2：清空目标表，准备插入最新数据
    -- 说明：每日全量覆盖，避免历史脏数据残留
    -- ==========================================================
    TRUNCATE TABLE s_集团开工申请索引表智能体数据提取

    -- ==========================================================
    -- 步骤3：将临时表#index中的数据插入目标表
    -- 说明：字段一一对应，后续可根据业务需求补充字段
    -- ==========================================================
    INSERT INTO s_集团开工申请索引表智能体数据提取
    (
        [投管代码],
        [项目GUID],
        [项目名称],
        [推广名称],
        [审批单号],
        [审批单名称],
        [存货去化承诺ID],
        [本次新推量价承诺ID],
        [是否为当前最新版],
        [承诺时间],
        [归档时间],
        [责任人],
        [联系电话]
    )
    SELECT  
        [投管代码],
        [项目GUID],
        [项目名称],
        [推广名称],
        [审批单号],
        [审批单名称],
        [存货去化承诺ID],
        [本次新推量价承诺ID],
        [是否为当前最新版],
        [承诺时间],
        [归档时间],
        [责任人],
        [联系电话]
    FROM #index

    -- ==========================================================
    -- 步骤4：历史数据清理（如需启用，取消注释）
    -- 说明：可根据清洗日期保留当天及特殊快照，删除7天前的普通历史数据
    -- ==========================================================
    /*
    DELETE FROM s_集团开工申请索引表智能体数据提取 
    WHERE 
        -- 1. 保留当天数据
        -- DATEDIFF(DAY, 清洗日期, GETDATE()) <> 0
        -- OR
        (
            -- 2. 保留以下特殊快照，其余超过7天的历史数据将被删除
            DATENAME(WEEKDAY, 清洗日期) <> '星期一'  -- 非周一
            AND DATEPART(DAY, 清洗日期) <> 1        -- 非每月1号
            AND DATEDIFF(DAY, 清洗日期, CONVERT(VARCHAR(4), YEAR(清洗日期)) + '-12-31') <> 0  -- 非每年最后一天
            AND DATEDIFF(DAY, 清洗日期, DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗日期) + 1, 0))) <> 0 -- 非每月最后一天
            AND DATEDIFF(DAY, 清洗日期, GETDATE()) > 7  -- 距今超过7天
        );
    */

    -- ==========================================================
    -- 步骤5：查询结果，供后续流程或人工核查
    -- 说明：按项目名称降序排列，便于查找
    -- ==========================================================
    SELECT *
    FROM s_集团开工申请索引表智能体数据提取  
    -- WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0  -- 如需仅查当天数据可启用
    ORDER BY 项目名称 DESC

END