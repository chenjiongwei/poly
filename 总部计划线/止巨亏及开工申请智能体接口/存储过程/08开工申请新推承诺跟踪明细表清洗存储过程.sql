-- 开工申请新推承诺量价明细表清洗存储过程
-- ============================================
-- 存储过程名称：[usp_s_集团开工申请新推承诺量价明细表智能体数据提取]
-- 创建人: chenjw 2025-09-09
-- 作用：清洗并提取集团开工申请新推量价承诺跟踪明细表数据，供智能体使用
-- ============================================
CREATE OR ALTER PROC [dbo].[usp_s_集团开工申请新推承诺量价明细表智能体数据提取]
AS
BEGIN

    /***********************************************************************
    步骤1：提取承诺主表数据，存入临时表#Commitment
    说明：
        - 从[本次新推承诺表]提取承诺主数据
        - 关联项目表获取推广名称
        - 字段说明见注释
    ***********************************************************************/
    SELECT  
        xt.本次新推量价承诺ID         AS [本次新推量价承诺ID],      -- 唯一主键
        xt.投管代码                  AS [投管代码],               -- 投管系统项目代码
        xt.项目GUID                  AS [项目GUID],               -- 项目唯一标识
        xt.项目名称                  AS [项目名称],               -- 项目名称
        p.SpreadName                 AS [推广名称],               -- 推广名称
        xt.承诺时间                  AS [承诺时间],               -- 承诺时间
        xt.本批开工的产品楼栋GUID      as [本批开工的产品楼栋GUID],
        xt.本批开工的产品楼栋编码        AS [本批开工的产品楼栋编码],     -- 楼栋编码（分号分隔）
        xt.本批开工的产品楼栋名称        AS [本批开工的产品楼栋名称]      -- 楼栋名称
    INTO #Commitment
    FROM [172.16.4.141].[MyCost_Erp352].dbo.本次新推承诺表 xt
    INNER JOIN data_wide_dws_mdm_Project p
        ON xt.项目GUID = p.projguid

    /***********************************************************************
    步骤2：拆分产品楼栋GUID，便于明细处理
    说明：
        - 一条承诺可能对应多个楼栋，楼栋GUID以分号分隔
        - 使用自定义拆分函数fn_Split1，将每个楼栋GUID拆分为单独一行
        - 结果存入临时表#ld
    ***********************************************************************/
    SELECT  
        a.本次新推量价承诺ID,
        a.投管代码,
        a.项目GUID,
        a.项目名称,
        a.推广名称,
        a.承诺时间,
        value AS 产品楼栋GUID
    INTO #ld
    FROM #Commitment a
    CROSS APPLY dbo.fn_Split1(a.本批开工的产品楼栋GUID, ';')
    WHERE ISNULL(a.本批开工的产品楼栋GUID, '') <> ''

    /***********************************************************************
    步骤2.1：生成承诺明细临时表#xtxmld
    说明：
        - 以拆分后的楼栋GUID为基础，生成明细表
        - 可后续补充与明细表的关联
    ***********************************************************************/
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
        AND ld.产品楼栋GUID = chdtl.产品楼栋GUID


     -- M002表的成本单方数据
        SELECT 
            distinct
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
        into  #M002
        FROM data_wide_dws_qt_M002项目业态级毛利净利表 
        WHERE versionType IN ('累计版', '本年版')

    /***********************************************************************
    步骤3：删除当天已存在的数据，避免重复插入
    说明：
        - 以清洗日期为准，删除当天数据
        - 保证数据唯一性
    ***********************************************************************/
    DELETE FROM s_集团开工申请新推量价承诺明细表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

    /***********************************************************************
    步骤4：插入最新清洗结果数据
    说明：
        - 从#xtxmld及相关表汇总数据，插入目标表
        - 部分字段暂未计算，后续可补充
        - 字段含义详见注释
    ***********************************************************************/
    INSERT INTO s_集团开工申请新推量价承诺明细表智能体数据提取 (
        [本次新推量价承诺ID],
        [投管代码],
        [项目名称],
        [推广名称],
        [项目GUID],
        [业态],
        [产品楼栋GUID],
        [产品楼栋编码],
        [产品楼栋名称],
        [首开日期],
        [可售面积],
        [开工货值],
        [供货周期],
        [去化周期],
        [累计签约回笼],
        [累计除地价外直投及费用],
        [累计贡献现金流],
        [一年内签约金额],
        [一年内回笼金额],
        [一年内除地价外直投及费用],
        [一年内贡献现金流],
        [含税签约金额],
        [已售面积],
        [不含税签约金额],
        [清洗日期]
    )
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
        -- 供货周期=楼栋实际达预售形象汇报完成时间-楼栋实际开工汇报完成时间（月）
        DATEDIFF(MONTH, lddb.SJzskgdate, lddb.SjDdysxxDate) AS [供货周期],
        -- 去化周期=楼栋下最后一个房间的签约时间-第一个房间的认购时间（月）
        CASE 
            WHEN sk.售罄日期 IS NOT NULL THEN DATEDIFF(MONTH, sk.首开日期, sk.售罄日期)
        END AS [去化周期],
        hk.累计回笼金额 / 100000000.0 AS [累计签约回笼], -- 累计签约回笼（单位：亿元）
        --- 取M002表楼栋对应业态组合键(产品类型+产品名称+商品类型+装修标准)的“盈利规划营业成本单方”+“”+“盈利规划股权溢价单方”+“盈利规划营销费用单方”+“盈利规划综合管理费单方协议口径”+“盈利规划税金及附加单方”*一年内楼栋的销售面积
        case when bd.TopProductTypeName ='地下室/车库' then 
                    (isnull(ljm002.盈利规划营业成本单方,0) 
                    +isnull(ljm002.盈利规划股权溢价单方,0)
                    +isnull(ljm002.盈利规划营销费用单方,0)
                    +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售套数,0) 
        else 
               (isnull(ljm002.盈利规划营业成本单方,0) 
                    +isnull(ljm002.盈利规划股权溢价单方,0)
                    +isnull(ljm002.盈利规划营销费用单方,0)
                    +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售面积,0)
        end / 100000000.0 AS [累计除地价外直投及费用],                -- 预留，后续补充
        isnull(hk.累计回笼金额,0) / 100000000.0  -
        case when bd.TopProductTypeName ='地下室/车库' then 
                    (isnull(ljm002.盈利规划营业成本单方,0) 
                    +isnull(ljm002.盈利规划股权溢价单方,0)
                    +isnull(ljm002.盈利规划营销费用单方,0)
                    +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售套数,0) 
        else 
               (isnull(ljm002.盈利规划营业成本单方,0) 
                    +isnull(ljm002.盈利规划股权溢价单方,0)
                    +isnull(ljm002.盈利规划营销费用单方,0)
                    +isnull(ljm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(ljm002.盈利规划税金及附加单方,0) ) * isnull(sf.已售面积,0)
        end / 100000000.0   AS [累计贡献现金流],                        -- 累计签约回笼（亿）X1 - 累计除地价外直投及费用（亿）Y1
        sf.一年内签约金额 / 100000000.0 AS [一年内签约金额], -- 一年内签约金额（单位：亿元）
        hk.累计本年回笼金额 / 100000000.0 AS [一年内回笼金额], -- 一年内回笼金额（单位：亿元）
        case when bd.TopProductTypeName ='地下室/车库' then 
                    (isnull(bnm002.盈利规划营业成本单方,0) 
                    +isnull(bnm002.盈利规划股权溢价单方,0)
                    +isnull(bnm002.盈利规划营销费用单方,0)
                    +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约套数,0) 
        else 
               (isnull(bnm002.盈利规划营业成本单方,0) 
                    +isnull(bnm002.盈利规划股权溢价单方,0)
                    +isnull(bnm002.盈利规划营销费用单方,0)
                    +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约面积,0)
        end  / 100000000.0 AS [一年内除地价外直投及费用],              -- 预留，后续补充
        
        hk.累计本年回笼金额 / 100000000.0 - 
        case when bd.TopProductTypeName ='地下室/车库' then 
                    (isnull(bnm002.盈利规划营业成本单方,0) 
                    +isnull(bnm002.盈利规划股权溢价单方,0)
                    +isnull(bnm002.盈利规划营销费用单方,0)
                    +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约套数,0) 
        else 
               (isnull(bnm002.盈利规划营业成本单方,0) 
                    +isnull(bnm002.盈利规划股权溢价单方,0)
                    +isnull(bnm002.盈利规划营销费用单方,0)
                    +isnull(bnm002.盈利规划综合管理费单方协议口径,0)
                    +isnull(bnm002.盈利规划税金及附加单方,0) ) * isnull(sf.一年内签约面积,0)
        end  / 100000000.0 AS [一年内贡献现金流],                      -- 一年内实现回笼（亿）X2 - 一年内除地价外直投及费用（亿）Y2
        sf.含税签约金额 / 100000000.0 AS [含税签约金额], -- 含税签约金额（单位：亿元）
        sf.已售面积 / 10000.0 AS [已售面积],             -- 已售面积（单位：万㎡）
        sf.不含税签约金额 / 100000000.0 AS [不含税签约金额], -- 不含税签约金额（单位：亿元）
        GETDATE() AS [清洗日期]                          -- 当前清洗日期
    FROM #xtxmld xt
    -- 关联楼栋主数据，获取编码、名称
    inner JOIN data_wide_dws_mdm_Building bd ON bd.BuildingGUID = xt.产品楼栋GUID  AND bd.BldType = '产品楼栋'
    -- 关联楼栋底表，获取业态、面积、开工等信息
    LEFT JOIN data_wide_dws_s_p_lddbamj lddb  ON lddb.SaleBldGUID = xt.产品楼栋GUID
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
            sum(isnull(sf.CNetCount,0) + isnull(sf.SpecialCNetCount,0)) as 已售套数,
            SUM(ISNULL(sf.CNetAmountNotTax, 0) + ISNULL(sf.SpecialCNetAmountNotTax, 0)) AS 不含税签约金额 -- 不含税签约金额
        FROM data_wide_dws_s_SalesPerf sf
        INNER JOIN #xtxmld xt
            ON sf.bldguid = xt.产品楼栋GUID
        GROUP BY xt.本次新推量价承诺ID, xt.产品楼栋GUID
    ) sf ON sf.本次新推量价承诺ID = xt.本次新推量价承诺ID AND sf.产品楼栋GUID = xt.产品楼栋GUID
    -- 销净率 统计
    left join #m002 ljm002 on xt.项目GUID =ljm002.projguid and ljm002.versionType ='累计版'  
                              and bd.TopProductTypeName =ljm002.产品类型 
                              and bd.ProductTypeName = ljm002.产品名称
                              and bd.CommodityType = ljm002.商品类型
                              and bd.ZxBz = ljm002.装修标准
    left join #m002 bnm002 on xt.项目GUID =bnm002.projguid and bnm002.versionType ='本年版'  
                              and bd.TopProductTypeName =bnm002.产品类型 
                              and bd.ProductTypeName = bnm002.产品名称
                              and bd.CommodityType = bnm002.商品类型
                              and bd.ZxBz = bnm002.装修标准
    /***********************************************************************
    步骤5：清理历史数据，仅保留必要快照
    说明：
        - 保留当天数据
        - 仅保留以下特殊快照，其余超过7天的历史数据将被删除：
            1. 每周一
            2. 每月1号
            3. 每月最后一天
            4. 每年最后一天
    ***********************************************************************/
    DELETE FROM s_集团开工申请新推量价承诺明细表智能体数据提取
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

    /***********************************************************************
    步骤6：查询当天数据，供后续分析或校验
    说明：
        - 返回当天清洗后的明细数据，便于后续分析或校验
    ***********************************************************************/
    SELECT *
    FROM s_集团开工申请新推量价承诺明细表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0
    ORDER BY 项目名称, 业态

    /***********************************************************************
    步骤7：删除临时表，释放资源
    说明：
        - 删除临时表#Commitment、#xtxmld，释放内存
    ***********************************************************************/
    DROP TABLE #Commitment, #xtxmld,#M002

END