USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_集团开工申请本次新推承诺表智能体数据提取]    Script Date: 2025/9/18 12:59:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 开工申请新推承诺量价承诺表清洗存储过程
-- ============================================
-- 存储过程名称：[usp_s_集团开工申请本次新推承诺表智能体数据提取]
-- 创建人: chenjw 2025-09-09
-- 作用：清洗并提取集团开工申请新推量价承诺表数据，供智能体使用
-- ============================================
ALTER   PROC [dbo].[usp_s_集团开工申请本次新推承诺表智能体数据提取]
AS
BEGIN
    /**************************************************************
    步骤1：提取承诺表主数据，生成临时表#Commitment
    ***************************************************************/
    SELECT 
        xt.本次新推量价承诺ID AS [本次新推量价承诺ID],         -- 唯一主键
        xt.投管代码           AS [投管代码],                 -- 投管系统项目代码
        xt.项目GUID           AS [项目GUID],                 -- 项目唯一标识
        xt.项目名称           AS [项目名称],                 -- 项目名称
        p.SpreadName         AS [推广名称],                  -- 推广名称
        xt.承诺时间           AS [承诺时间],                 -- 承诺时间
        xt.本批开工的产品楼栋GUID  AS [本批开工的产品楼栋GUID], -- 产品楼栋GUID（分号分隔）
        xt.本批开工的产品楼栋编码 AS [本批开工的产品楼栋编码], -- 楼栋编码（分号分隔）
        xt.本批开工的产品楼栋名称 AS [本批开工的产品楼栋名称], -- 楼栋名称
        xt.[本批开工可售面积] AS [本批开工可售面积],         -- 本批开工可售面积
        xt.[本批开工货值]     AS [本批开工货值],             -- 本批开工货值
        xt.[供货周期]         AS [供货周期],                 -- 供货周期
        xt.[去化周期]         AS [去化周期],                 -- 去化周期
        xt.[本批开工后的项目累计签约回笼]           AS [本批开工后的项目累计签约回笼],           -- 累计签约回笼
        xt.[本批开工后的项目累计除地价外直投及费用]   AS [本批开工后的项目累计除地价外直投及费用],   -- 累计除地价外直投及费用
        xt.[本批开工后的项目累计贡献现金流]         AS [本批开工后的项目累计贡献现金流],         -- 累计贡献现金流
        xt.[本批开工后的一年内实现签约]             AS [本批开工后的一年内实现签约],             -- 一年内实现签约
        xt.[本批开工后的一年内实现回笼]             AS [本批开工后的一年内实现回笼],             -- 一年内实现回笼
        xt.[本批开工后的一年内除地价外直投及费用]     AS [本批开工后的一年内除地价外直投及费用],     -- 一年内除地价外直投及费用
        xt.[本批开工后的一年内贡献现金流]             AS [本批开工后的一年内贡献现金流],             -- 一年内贡献现金流
        xt.[未开工楼栋地价]                         AS [未开工楼栋地价],                         -- 未开工楼栋地价
        xt.[本次开工可收回地价]                     AS [本次开工可收回地价],                     -- 本次开工可收回地价
        xt.[回收股东占压资金]                       AS [回收股东占压资金],                       -- 回收股东占压资金
        xt.[本批开工的销售均价]                   AS [本批开工的销售均价],                   -- 本批开工的销售均价
        xt.[本批开工的可售单方成本]                 AS [本批开工的可售单方成本],                 -- 本批开工的可售单方成本
        xt.[本批开工的税后净利润]                 AS [本批开工的税后净利润],                 -- 本批开工的税后净利润
        xt.[本批开工的销净率]                     AS [本批开工的销净率],                     -- 本批开工的销净率
        xt.[业态销售均价及销净率承诺]               AS [业态销售均价及销净率承诺]               -- 业态销售均价及销净率承诺
    INTO #Commitment
    FROM [172.16.4.141].[MyCost_Erp352].dbo.本次新推承诺表 xt
    INNER JOIN data_wide_dws_mdm_Project p ON xt.项目GUID = p.projguid;

    /**************************************************************
    步骤2：拆分产品楼栋GUID，生成#ld临时表
    ***************************************************************/
    SELECT  
        a.本次新推量价承诺ID,
        a.投管代码,
        a.项目GUID,
        a.项目名称,
        a.推广名称,
        a.承诺时间,
        value AS 产品楼栋GUID -- 拆分后的单个楼栋GUID
    INTO #ld
    FROM #Commitment a
    CROSS APPLY dbo.fn_Split1(a.本批开工的产品楼栋GUID, ';')
    WHERE ISNULL(a.本批开工的产品楼栋GUID, '') <> '';

    /**************************************************************
    步骤3：生成#xtxmld临时表，补充明细表信息
    ***************************************************************/
    SELECT 
        ld.本次新推量价承诺ID,
        ld.投管代码,
        ld.项目GUID,
        ld.项目名称,
        ld.推广名称,
        ld.承诺时间,
        ld.产品楼栋GUID
    INTO #xtxmld
    FROM #ld ld
    LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.[本次新推承诺明细表] chdtl
        ON ld.本次新推量价承诺ID = chdtl.本次新推量价承诺ID
        AND ld.产品楼栋GUID = chdtl.产品楼栋GUID;

    /**************************************************************
    步骤4：提取M002表的成本单方数据，生成#M002临时表
    ***************************************************************/
    SELECT DISTINCT
        projguid, 
        versionType,
        产品类型,
        产品名称,
        商品类型,
        装修标准,
        盈利规划营业成本单方,
        盈利规划股权溢价单方,
        盈利规划营销费用单方,
        盈利规划综合管理费单方协议口径,
        盈利规划税金及附加单方
    INTO #M002
    FROM data_wide_dws_qt_M002项目业态级毛利净利表 
    WHERE versionType IN ('累计版', '本年版');

    /**************************************************************
    步骤5：楼栋维度动态数据统计，生成#xtld临时表
    ***************************************************************/
    SELECT 
        xt.本次新推量价承诺ID,                        -- 唯一主键
        xt.投管代码,                                 -- 投管系统项目代码
        xt.项目名称,                                 -- 项目名称
        xt.推广名称,                                 -- 推广名称
        xt.项目GUID,                                 -- 项目唯一标识
        -- 业态分类，住宅/车位/商办
        CASE 
            WHEN lddb.ProductType IN ('住宅', '高级住宅', '别墅') THEN '住宅'
            WHEN lddb.ProductType = '地下室/车库' THEN '车位'
            ELSE '商办'
        END AS [业态],
        xt.产品楼栋GUID,                             -- 楼栋GUID
        bd.Code AS [产品楼栋编码],                   -- 楼栋编码
        bd.BuildingName AS [产品楼栋名称],           -- 楼栋名称
        sk.首开日期,                                -- 首开日期（楼栋下第一个房间的认购/签约日期）
        lddb.zksmj / 10000.0 AS [可售面积],          -- 楼栋总可售面积（单位：万㎡）
        -- 开工货值，实际开工节点的实际完成时间不为空的未售货值含税（单位：亿元）
        CASE 
            WHEN lddb.SJzskgdate IS NOT NULL THEN lddb.syhz 
            ELSE 0  
        END / 100000000.0 AS [开工货值],
        lddb.SJzskgdate  as [实际正式开工日期],
        lddb.SjDdysxxDate as [实际达预售形象日期],
        sk.售罄日期,
        -- -- 供货周期=楼栋实际达预售形象汇报完成时间-楼栋实际开工汇报完成时间（月）
        -- DATEDIFF(MONTH, lddb.SJzskgdate, lddb.SjDdysxxDate) AS [供货周期],
        -- 去化周期=楼栋下最后一个房间的签约时间-第一个房间的认购时间（月）
        CASE 
            WHEN sk.售罄日期 IS NOT NULL THEN DATEDIFF(MONTH, sk.首开日期, sk.售罄日期)
        END AS [去化周期],
        hk.累计回笼金额 / 100000000.0 AS [累计签约回笼], -- 累计签约回笼（单位：亿元）
        -- 累计除地价外直投及费用（区分车位/非车位，面积/套数）
        CASE 
            WHEN bd.TopProductTypeName = '地下室/车库' THEN 
                (ISNULL(ljm002.盈利规划营业成本单方,0) 
                + ISNULL(ljm002.盈利规划股权溢价单方,0)
                + ISNULL(ljm002.盈利规划营销费用单方,0)
                + ISNULL(ljm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(ljm002.盈利规划税金及附加单方,0)) * ISNULL(sf.已售套数,0)
            ELSE
                (ISNULL(ljm002.盈利规划营业成本单方,0) 
                + ISNULL(ljm002.盈利规划股权溢价单方,0)
                + ISNULL(ljm002.盈利规划营销费用单方,0)
                + ISNULL(ljm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(ljm002.盈利规划税金及附加单方,0)) * ISNULL(sf.已售面积,0)
        END / 100000000.0 AS [累计除地价外直投及费用], -- 预留，后续补充
        -- 累计贡献现金流 = 累计签约回笼 - 累计除地价外直投及费用
        ISNULL(hk.累计回笼金额,0) / 100000000.0 -
        CASE 
            WHEN bd.TopProductTypeName = '地下室/车库' THEN 
                (ISNULL(ljm002.盈利规划营业成本单方,0) 
                + ISNULL(ljm002.盈利规划股权溢价单方,0)
                + ISNULL(ljm002.盈利规划营销费用单方,0)
                + ISNULL(ljm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(ljm002.盈利规划税金及附加单方,0)) * ISNULL(sf.已售套数,0)
            ELSE
                (ISNULL(ljm002.盈利规划营业成本单方,0) 
                + ISNULL(ljm002.盈利规划股权溢价单方,0)
                + ISNULL(ljm002.盈利规划营销费用单方,0)
                + ISNULL(ljm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(ljm002.盈利规划税金及附加单方,0)) * ISNULL(sf.已售面积,0)
        END / 100000000.0 AS [累计贡献现金流], -- 累计签约回笼（亿）X1 - 累计除地价外直投及费用（亿）Y1
        sf.一年内签约金额 / 100000000.0 AS [一年内签约金额], -- 一年内签约金额（单位：亿元）
        hk.累计本年回笼金额 / 100000000.0 AS [一年内回笼金额], -- 一年内回笼金额（单位：亿元）
        -- 一年内除地价外直投及费用
        CASE 
            WHEN bd.TopProductTypeName = '地下室/车库' THEN 
                (ISNULL(bnm002.盈利规划营业成本单方,0) 
                + ISNULL(bnm002.盈利规划股权溢价单方,0)
                + ISNULL(bnm002.盈利规划营销费用单方,0)
                + ISNULL(bnm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(bnm002.盈利规划税金及附加单方,0)) * ISNULL(sf.一年内签约套数,0)
            ELSE
                (ISNULL(bnm002.盈利规划营业成本单方,0) 
                + ISNULL(bnm002.盈利规划股权溢价单方,0)
                + ISNULL(bnm002.盈利规划营销费用单方,0)
                + ISNULL(bnm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(bnm002.盈利规划税金及附加单方,0)) * ISNULL(sf.一年内签约面积,0)
        END / 100000000.0 AS [一年内除地价外直投及费用], -- 预留，后续补充
        -- 一年内贡献现金流 = 一年内回笼金额 - 一年内除地价外直投及费用
        hk.累计本年回笼金额 / 100000000.0 -
        CASE 
            WHEN bd.TopProductTypeName = '地下室/车库' THEN 
                (ISNULL(bnm002.盈利规划营业成本单方,0) 
                + ISNULL(bnm002.盈利规划股权溢价单方,0)
                + ISNULL(bnm002.盈利规划营销费用单方,0)
                + ISNULL(bnm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(bnm002.盈利规划税金及附加单方,0)) * ISNULL(sf.一年内签约套数,0)
            ELSE
                (ISNULL(bnm002.盈利规划营业成本单方,0) 
                + ISNULL(bnm002.盈利规划股权溢价单方,0)
                + ISNULL(bnm002.盈利规划营销费用单方,0)
                + ISNULL(bnm002.盈利规划综合管理费单方协议口径,0)
                + ISNULL(bnm002.盈利规划税金及附加单方,0)) * ISNULL(sf.一年内签约面积,0)
        END / 100000000.0 AS [一年内贡献现金流], -- 一年内实现回笼（亿）X2 - 一年内除地价外直投及费用（亿）Y2
        sf.含税签约金额 / 100000000.0 AS [含税签约金额], -- 含税签约金额（单位：亿元）
        sf.已售面积 / 10000.0 AS [已售面积],             -- 已售面积（单位：万㎡）
        sf.不含税签约金额 / 100000000.0 AS [不含税签约金额] -- 不含税签约金额（单位：亿元）
    INTO #xtld
    FROM #xtxmld xt
    -- 关联楼栋主数据，获取编码、名称
    INNER JOIN data_wide_dws_mdm_Building bd 
        ON bd.BuildingGUID = xt.产品楼栋GUID AND bd.BldType = '产品楼栋'
    -- 关联楼栋底表，获取业态、面积、开工等信息
    LEFT JOIN data_wide_dws_s_p_lddbamj lddb  
        ON lddb.SaleBldGUID = xt.产品楼栋GUID
    -- 计算首开日期、售罄日期
    LEFT JOIN (
        SELECT 
            本次新推量价承诺ID,
            产品楼栋GUID,
            首开日期,
            CASE 
                WHEN ISNULL(sale.TotalRoomCount, 0) = ISNULL(sale.QyRoomCount, 0) 
                    THEN lastQyDate 
            END AS 售罄日期
        FROM (
            SELECT 
                xt.本次新推量价承诺ID,
                xt.产品楼栋GUID,
                -- 首开日期：第一个认购/签约房间的认购/签约日期
                MIN(
                    CASE 
                        WHEN Status IN ('认购', '签约') AND specialFlag <> '是' THEN ISNULL(RgQsDate, QSDate)
                        WHEN Status IN ('认购', '签约') THEN ISNULL(TsRoomQSDate, ISNULL(RgQsDate, QSDate))
                    END
                ) AS 首开日期,
                -- 售罄日期：最后一个签约房间的签约日期
                MAX(
                    CASE 
                        WHEN Status = '签约' AND specialFlag <> '是' THEN QSDate
                        WHEN Status = '签约' THEN ISNULL(TsRoomQSDate, QSDate) 
                    END
                ) AS lastQyDate,
                COUNT(1) AS TotalRoomCount, -- 房间总数
                SUM(CASE WHEN Status = '签约' THEN 1 ELSE 0 END) AS QyRoomCount -- 签约房间数
            FROM data_wide_s_RoomoVerride room
            INNER JOIN #xtxmld xt 
                ON room.bldguid = xt.产品楼栋GUID
            GROUP BY xt.本次新推量价承诺ID, xt.产品楼栋GUID
        ) sale 
        WHERE ISNULL(sale.TotalRoomCount, 0) > 0
    ) sk
        ON sk.本次新推量价承诺ID = xt.本次新推量价承诺ID
        AND sk.产品楼栋GUID = xt.产品楼栋GUID
    -- 关联房款一览表，获取累计回笼金额
    LEFT JOIN (
        SELECT  
            xt.本次新推量价承诺ID,
            xt.产品楼栋GUID,
            SUM(ISNULL(fk.累计回笼金额,0)) AS 累计回笼金额,         -- 累计签约回笼
            SUM(ISNULL(fk.累计本年回笼金额,0)) AS 累计本年回笼金额   -- 一年内实现回笼
        FROM data_wide_dws_s_s_gsfkylbmxb fk
        INNER JOIN data_wide_s_RoomoVerride room
            ON fk.roomguid = room.roomguid
        INNER JOIN #xtxmld xt
            ON room.bldguid = xt.产品楼栋GUID
        GROUP BY xt.本次新推量价承诺ID, xt.产品楼栋GUID   
    ) hk
        ON hk.本次新推量价承诺ID = xt.本次新推量价承诺ID
        AND hk.产品楼栋GUID = xt.产品楼栋GUID
    -- 关联销售业绩表，获取签约金额、面积等
    LEFT JOIN (
        SELECT 
            xt.本次新推量价承诺ID, 
            xt.产品楼栋GUID,
            SUM(CASE WHEN DATEDIFF(YEAR, sf.StatisticalDate, GETDATE()) = 0
                     THEN ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)
                     ELSE 0 END) AS 一年内签约金额, -- 一年内签约金额
            SUM(CASE WHEN DATEDIFF(YEAR, sf.StatisticalDate, GETDATE()) = 0
                     THEN ISNULL(sf.CNetArea, 0) + ISNULL(sf.SpecialCNetArea, 0)
                     ELSE 0 END) AS 一年内签约面积, -- 一年内签约面积
            SUM(CASE WHEN DATEDIFF(YEAR, sf.StatisticalDate, GETDATE()) = 0
                     THEN ISNULL(sf.CNetCount, 0) + ISNULL(sf.SpecialCNetCount, 0)
                     ELSE 0 END) AS 一年内签约套数, -- 一年内签约套数
            SUM(ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0)) AS 含税签约金额, -- 含税签约金额
            SUM(ISNULL(sf.CNetArea, 0) + ISNULL(sf.SpecialCNetArea, 0)) AS 已售面积,         -- 已售面积
            SUM(ISNULL(sf.CNetCount,0) + ISNULL(sf.SpecialCNetCount,0)) AS 已售套数,         -- 已售套数
            SUM(ISNULL(sf.CNetAmountNotTax, 0) + ISNULL(sf.SpecialCNetAmountNotTax, 0)) AS 不含税签约金额 -- 不含税签约金额
        FROM data_wide_dws_s_SalesPerf sf
        INNER JOIN #xtxmld xt
            ON sf.bldguid = xt.产品楼栋GUID
        GROUP BY xt.本次新推量价承诺ID, xt.产品楼栋GUID
    ) sf 
        ON sf.本次新推量价承诺ID = xt.本次新推量价承诺ID 
        AND sf.产品楼栋GUID = xt.产品楼栋GUID
    -- 关联M002累计版
    LEFT JOIN #m002 ljm002 
        ON xt.项目GUID = ljm002.projguid 
        AND ljm002.versionType = '累计版'  
        AND bd.TopProductTypeName = ljm002.产品类型 
        AND bd.ProductTypeName = ljm002.产品名称
        AND bd.CommodityType = ljm002.商品类型
        AND bd.ZxBz = ljm002.装修标准
    -- 关联M002本年版
    LEFT JOIN #m002 bnm002 
        ON xt.项目GUID = bnm002.projguid 
        AND bnm002.versionType = '本年版'  
        AND bd.TopProductTypeName = bnm002.产品类型 
        AND bd.ProductTypeName = bnm002.产品名称
        AND bd.CommodityType = bnm002.商品类型
        AND bd.ZxBz = bnm002.装修标准;

    /**************************************************************
    步骤6：删除当天已存在的数据，避免重复
    ***************************************************************/
    DELETE FROM s_集团开工申请本次新推承诺表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

    /**************************************************************
    步骤7：插入承诺值和动态值数据
    ***************************************************************/
    INSERT INTO s_集团开工申请本次新推承诺表智能体数据提取
    (
        [本次新推量价承诺ID],
        [投管代码],
        [项目名称],
        [推广名称],
        [项目GUID],
        [承诺时间],
        [类型],
        [产品楼栋GUID],
        [产品楼栋编码],
        [产品楼栋名称],
        [本批开工可售面积],
        [本批开工货值],
        [供货周期],
        [去化周期],
        [本批开工后的项目累计签约回笼],
        [本批开工后的项目累计除地价外直投及费用],
        [本批开工后的项目累计贡献现金流],
        [本批开工后的一年内实现签约],
        [本批开工后的一年内实现回笼],
        [本批开工后的一年内除地价外直投及费用],
        [本批开工后的一年内贡献现金流],
        [未开工楼栋地价],
        [本次开工可收回地价],
        [回收股东占压资金],
        [本批开工的销售均价],
        [本批开工的可售单方成本],
        [本批开工的税后净利润],
        [本批开工的销净率],
        [清洗日期]
    )
    -- 插入承诺值
    SELECT 
        cmt.[本次新推量价承诺ID],
        cmt.[投管代码],
        cmt.[项目名称],
        cmt.[推广名称],
        cmt.[项目GUID],
        cmt.[承诺时间],
        '承诺值' AS [类型],
        cmt.[本批开工的产品楼栋GUID],
        cmt.[本批开工的产品楼栋编码],
        cmt.[本批开工的产品楼栋名称],
        cmt.[本批开工可售面积],
        cmt.[本批开工货值],
        cmt.[供货周期],
        cmt.[去化周期],
        cmt.[本批开工后的项目累计签约回笼],
        cmt.[本批开工后的项目累计除地价外直投及费用],
        cmt.[本批开工后的项目累计贡献现金流],
        cmt.[本批开工后的一年内实现签约],
        cmt.[本批开工后的一年内实现回笼],
        cmt.[本批开工后的一年内除地价外直投及费用],
        cmt.[本批开工后的一年内贡献现金流],
        cmt.[未开工楼栋地价],
        cmt.[本次开工可收回地价],
        cmt.[回收股东占压资金],
        cmt.[本批开工的销售均价],
        cmt.[本批开工的可售单方成本],
        cmt.[本批开工的税后净利润],
        cmt.[本批开工的销净率],
        GETDATE() AS [清洗日期]
    FROM #Commitment cmt
    -- 动态值
    UNION ALL
    SELECT
        cmt.[本次新推量价承诺ID],
        cmt.[投管代码],
        cmt.[项目名称],
        cmt.[推广名称],
        cmt.[项目GUID],
        cmt.[承诺时间],
        '动态值' AS [类型],
        cmt.[本批开工的产品楼栋GUID],
        cmt.[本批开工的产品楼栋编码],
        cmt.[本批开工的产品楼栋名称],
        xt.可售面积 AS [本批开工可售面积],
        xt.开工货值 AS [本批开工货值],
        xt.供货周期 AS [供货周期], 
        xt.去化周期 AS [去化周期],  
        xt.累计签约回笼 AS [本批开工后的项目累计签约回笼],
        xt.累计除地价外直投及费用 AS [本批开工后的项目累计除地价外直投及费用],
        xt.累计贡献现金流 AS [本批开工后的项目累计贡献现金流],
        xt.一年内签约金额 AS [本批开工后的一年内实现签约],
        xt.一年内回笼金额 AS [本批开工后的一年内实现回笼],
        xt.一年内除地价外直投及费用 AS [本批开工后的一年内除地价外直投及费用],
        xt.一年内贡献现金流 AS [本批开工后的一年内贡献现金流],
        NULL AS [未开工楼栋地价], --本批次级自己算
        NULL AS [本次开工可收回地价], --本批次级自己算
        NULL AS [回收股东占压资金], --本批次级自己算
        case when  isnull(已售面积,0) =0  then  0  else isnull(含税签约金额,0) *10000.0 / isnull(已售面积,0) end  AS [本批开工的销售均价], -- 含税签约金额/ 已售面积
        case when  isnull(已售面积,0) =0  then  0  else isnull(xt.累计除地价外直投及费用,0) *10000.0 / isnull(已售面积,0) end AS [本批开工的可售单方成本], -- M=单方（含税费）*明细表F
        isnull(xt.不含税签约金额,0) - isnull(xt.累计除地价外直投及费用,0) AS [本批开工的税后净利润],
        case when isnull(xt.不含税签约金额,0) =0 then  0 
          else   ( isnull(xt.不含税签约金额,0) - isnull(xt.累计除地价外直投及费用,0) )  / isnull(xt.不含税签约金额,0) end  AS [本批开工的销净率],
        GETDATE() AS [清洗日期]
    FROM #Commitment cmt
    LEFT JOIN (
        SELECT
            本次新推量价承诺ID,
            max(实际达预售形象日期) as 实际达预售形象日期,
            min(实际正式开工日期) as 实际正式开工日期,
            case when   max(实际达预售形象日期) is not null then  datediff(month, min(实际正式开工日期), max(实际达预售形象日期) ) end  as 供货周期, -- 供货周期=楼栋最晚实际达预售形象汇报完成时间-楼栋最早实际开工汇报完成时间
            min(首开日期) as 首开日期,
            max(售罄日期) as 售罄日期,
            case when  max(售罄日期) is not NULL then  datediff(month, min(首开日期), max(售罄日期)) end as  去化周期, -- 取楼栋下最后一个房间的签约时间 - 取楼栋下第一个房间的认购时间
            SUM(ISNULL(可售面积, 0)) AS 可售面积,
            SUM(ISNULL(开工货值, 0)) AS 开工货值,
            SUM(ISNULL(累计签约回笼, 0)) AS 累计签约回笼,
            SUM(ISNULL(累计除地价外直投及费用, 0)) AS 累计除地价外直投及费用,
            SUM(ISNULL(累计贡献现金流, 0)) AS 累计贡献现金流,
            SUM(ISNULL(一年内签约金额, 0)) AS 一年内签约金额,
            SUM(ISNULL(一年内回笼金额, 0)) AS 一年内回笼金额,
            SUM(ISNULL(一年内除地价外直投及费用, 0)) AS 一年内除地价外直投及费用,
            SUM(ISNULL(一年内贡献现金流, 0)) AS 一年内贡献现金流,
            SUM(ISNULL(含税签约金额, 0)) AS 含税签约金额,
            SUM(ISNULL(已售面积, 0)) AS 已售面积,
            SUM(ISNULL(不含税签约金额, 0)) AS 不含税签约金额
        FROM #xtld 
        GROUP BY 本次新推量价承诺ID
    ) xt ON cmt.本次新推量价承诺ID = xt.本次新推量价承诺ID

    /**************************************************************
    步骤8：清理历史数据，仅保留必要快照
    说明：
        - 保留当天数据
        - 仅保留以下特殊快照，其余超过7天的历史数据将被删除：
            1. 每周一
            2. 每月1号
            3. 每月最后一天
            4. 每年最后一天
    ***************************************************************/
    DELETE FROM s_集团开工申请本次新推承诺表智能体数据提取
    WHERE
        (
            -- 非每周一
            DATENAME(WEEKDAY, 清洗日期) <> '星期一'
            -- 非每月1号
            AND DATEPART(DAY, 清洗日期) <> 1
            -- 非每年最后一天
            AND DATEDIFF(DAY, 清洗日期, CONVERT(VARCHAR(4), YEAR(清洗日期)) + '-12-31') <> 0
            -- 非每月最后一天
            AND DATEDIFF(DAY, 清洗日期, DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗日期) + 1, 0))) <> 0
            -- 距今超过7天
            AND DATEDIFF(DAY, 清洗日期, GETDATE()) > 7
        )

    /**************************************************************
    步骤9：输出当天数据
    ***************************************************************/
    SELECT *
    FROM s_集团开工申请本次新推承诺表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0
    ORDER BY 项目名称, 类型

    /**************************************************************
    步骤10：删除临时表，释放资源
    ***************************************************************/
    DROP TABLE #Commitment, #xtxmld, #M002, #xtld

END