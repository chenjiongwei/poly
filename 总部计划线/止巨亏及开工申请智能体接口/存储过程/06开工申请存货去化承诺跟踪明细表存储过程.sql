USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_集团开工申请存货去化承诺跟踪明细表智能体数据提取]    Script Date: 2025/9/25 14:52:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================
-- 存储过程名称：usp_s_集团开工申请存货去化承诺跟踪明细表智能体数据提取ByTb
-- 创建人: chenjw 2025-11-23
-- 作用： 从Dss系统填报<存货去化承诺表>取数,清洗并提取集团开工申请存货去化承诺跟踪明细表数据，供智能体使用
-- ============================================
create  or  ALTER   PROC [dbo].[usp_s_集团开工申请存货去化承诺跟踪明细表智能体数据提取ByTb]
AS
BEGIN

    /***********************************************************************
    步骤1：查询承诺值数据，存入临时表#Commitment
    说明：从源表[存货去化承诺表]提取相关字段，类型统一标记为'承诺值'
    ***********************************************************************/


    -- SELECT  
    --     ch.存货去化承诺ID                                 AS [存货去化承诺ID],              -- 唯一主键
    --     ch.投管代码                                       AS [投管代码],                   -- 投管系统项目代码
    --     ch.项目GUID                                       AS [项目GUID],                   -- 项目唯一标识
    --     ch.项目名称                                       AS [项目名称],                   -- 项目名称
    --     p.SpreadName                                      AS [推广名称],                   -- 推广名称
    --     ch.承诺时间                                       AS [承诺时间],                   -- 承诺时间
    --     ch.已开工未售部分的的产品楼栋编码                 AS [已开工未售部分的的产品楼栋编码], -- 楼栋编码
    --     ch.已开工未售部分的的产品楼栋名称                 AS [已开工未售部分的的产品楼栋名称]  -- 楼栋名称
    -- INTO #Commitment
    -- FROM [172.16.4.141].[MyCost_Erp352].dbo.存货去化承诺表 ch
    -- INNER JOIN data_wide_dws_mdm_Project p ON ch.项目GUID = p.projguid

    -- 从填报表从提取需要分析的最新的项目及开工楼栋信息
    
        SELECT 
            a.存货去化承诺ID,
            a.投管代码,
            a.项目GUID,
            a.项目名称,
            a.推广名称,
            a.承诺时间,
            a.已开工未售部分的的产品楼栋编码,
            a.已开工未售部分的的产品楼栋名称
        INTO #Commitment
        FROM [172.16.4.141].dss.[dbo].nmap_F_存货去化承诺表 a
        INNER JOIN [172.16.4.141].dss.[dbo].[nmap_F_FillHistory] b  
            ON a.[FillHistoryGUID] = b.[FillHistoryGUID]
        WHERE a.[FillHistoryGUID] IN (
            SELECT TOP 1 [FillHistoryGUID]
            FROM [172.16.4.141].dss.[dbo].nmap_F_存货去化承诺表
            ORDER BY [FillDate] DESC
        )

    /***********************************************************************
    步骤2：将承诺产品楼栋编码GUID拆分，便于后续明细处理
    说明：一条承诺可能对应多个楼栋，用分号分隔，需拆分为多行
    ***********************************************************************/
    SELECT  
        a.存货去化承诺ID,
        a.投管代码,
        a.项目GUID,
        a.项目名称,
        a.推广名称,
        a.承诺时间,
        value AS 产品楼栋GUID
    INTO #ld
    FROM #Commitment a
    CROSS APPLY dbo.fn_Split1(a.已开工未售部分的的产品楼栋编码, ';')
    WHERE ISNULL(a.已开工未售部分的的产品楼栋编码, '') <> ''

    -- 插入承诺明细临时表
    -- SELECT 
    --     ld.存货去化承诺ID,
    --     ld.投管代码,
    --     ld.项目GUID,
    --     ld.项目名称,
    --     ld.推广名称,
    --     ld.承诺时间,
    --     ld.产品楼栋GUID,
    --     chdtl.承诺日累计签约面积, -- 万平方米
    --     chdtl.承诺日累计签约金额, -- 亿元
    --     chdtl.承诺日累计不含税签约金额 -- 亿元
    -- INTO #cmtld
    -- FROM #ld ld
    -- LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.[存货去化承诺明细表] chdtl
    --     ON ld.存货去化承诺ID = chdtl.存货去化承诺ID
    --     AND ld.产品楼栋GUID = chdtl.产品楼栋GUID
 
    -- 插入承诺明细临时表
    SELECT 
        ld.存货去化承诺ID,
        ld.投管代码,
        ld.项目GUID,
        ld.项目名称,
        ld.推广名称,
        ld.承诺时间,
        ld.产品楼栋GUID,
        chdtl.承诺日累计签约面积,         -- 万平方米
        chdtl.承诺日累计签约金额,         -- 亿元
        chdtl.承诺日累计不含税签约金额     -- 亿元
    INTO #cmtld
    FROM #ld ld
    left  join  (
        SELECT  
            sf.ParentProjGUID as 项目GUID,
            sf.BldGUID as 产品楼栋GUID,
            SUM(
                CASE 
                    WHEN DATEDIFF(DAY, chld.承诺时间, StatisticalDate) >= 0 
                        THEN ISNULL(sf.CNetAmount, 0) + ISNULL(sf.SpecialCNetAmount, 0) 
                    ELSE 0 
                END
            ) / 100000000.0 AS 承诺日累计签约金额,
            SUM(
                CASE 
                    WHEN DATEDIFF(DAY, chld.承诺时间, StatisticalDate) >= 0 
                        THEN ISNULL(sf.CNetAmountNotTax, 0) + ISNULL(sf.SpecialCNetAmountNotTax, 0) 
                    ELSE 0 
                END
            ) / 100000000.0 AS 承诺日累计不含税签约金额,
            SUM(
                CASE 
                    WHEN DATEDIFF(DAY, chld.承诺时间, StatisticalDate) >= 0 
                        THEN ISNULL(sf.CNetArea, 0) + ISNULL(sf.SpecialCNetArea, 0) 
                    ELSE 0 
                END
            ) / 10000.0 AS 承诺日累计签约面积
        FROM data_wide_dws_s_SalesPerf sf 
        INNER JOIN #ld  chld  ON sf.bldguid = chld.产品楼栋GUID --and sf.ParentProjGUID =chld.项目GUID
        WHERE  DATEDIFF(DAY, chld.承诺时间, StatisticalDate) >= 0 
        GROUP BY sf.ParentProjGUID , sf.BldGUID
    ) chdtl ON ld.项目GUID = chdtl.项目GUID
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
            业态组合键,
            明源匹配主键,
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
    说明：以清洗日期为准，删除当天数据
    ***********************************************************************/
    DELETE FROM s_集团开工申请存货去化承诺跟踪明细表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

    /***********************************************************************
    步骤4：插入最新清洗结果数据
    说明：将临时表#cmtld中的数据插入目标表，部分字段暂未计算，后续可补充
    ***********************************************************************/
    INSERT INTO s_集团开工申请存货去化承诺跟踪明细表智能体数据提取 (
        [存货去化承诺ID],
        [投管代码],
        [项目GUID],
        [项目名称],
        [推广名称],
        [业态],
        [已开工未售部分的的产品楼栋编码],
        [已开工未售部分的的产品楼栋名称],
        [承诺日],
        [售罄日],
        [存货去化周期],
        [近六个月去化面积],
        [剩余可售面积],
        [承诺日累计签约面积],
        [承诺日累计签约金额],
        [承诺日累计签约面积_动态版],
        [承诺日累计签约金额_动态版],
        [承诺日累计签约金额不含税_动态版],
        [承诺后累计含税签约面积],
        [承诺后累计含税签约金额],
        [承诺日不含税签约金额],
        [承诺后累计不含税签约金额],
        [清洗日期],
        [项目获取日期],
        [盈利规划营业成本单方],
        [盈利规划股权溢价单方],
        [盈利规划营销费用单方],
        [盈利规划综合管理费单方协议口径],
        [盈利规划税金及附加单方],
        [营业成本单方含税费],
        [承诺后营业成本含税费],
        [业态组合键],
        [明源匹配主键],
        [首开日期],
        [月均去化面积]
    )
    SELECT 
        ch.存货去化承诺ID    AS [存货去化承诺ID],         -- 唯一主键
        ch.投管代码        AS [投管代码],              -- 投管系统项目代码
        ch.项目GUID        AS [项目GUID],              -- 项目唯一标识
        ch.项目名称        AS [项目名称],              -- 项目名称
        ch.推广名称        AS [推广名称],              -- 推广名称
        CASE 
            WHEN lddb.ProductType IN ('住宅', '高级住宅', '别墅') THEN '住宅'
            WHEN lddb.ProductType = '地下室/车库' THEN '车位'
            ELSE '商办'
        END                AS [业态],                 -- 业态
        ch.产品楼栋GUID     AS [已开工未售部分的的产品楼栋编码], -- 楼栋编码
        bd.BuildingName    AS [已开工未售部分的的产品楼栋名称], -- 楼栋名称，后续可补充
        ch.承诺时间        AS [承诺日],                -- 承诺日
        CASE  
            WHEN qh.lastQyDate IS NOT NULL THEN CONVERT(VARCHAR(7), qh.lastQyDate, 121) 
        END                AS [售罄日],                -- 售罄日
        
        -- 口径调整：当前日期-承诺日+当前剩余或预计去化周期（楼栋对应剩余货量面积/近半年月均去化面积）
        CASE 
            WHEN  qh.lastQyDate is null and  isnull(sf.近六个月去化面积,0) <>0
                THEN DATEDIFF(DAY, ch.[承诺时间], GETDATE()) / 30.0 + 
                   ( (ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ) / 
                      case when datediff(month,qh.首开日期,getdate()) > 6 
                             then ( sf.近六个月去化面积 / 6.0 ) 
                        else (sf.近六个月去化面积/ (datediff(day,qh.首开日期,getdate()) /30.0) )   
                      end       
                   )
			when DATEDIFF(DAY, GETDATE(), qh.lastQyDate) < 0 and  qh.lastQyDate is not null 
			    then  DATEDIFF(DAY, ch.[承诺时间],qh.lastQyDate) / 30.0 
        END             AS [存货去化周期],         
        sf.近六个月去化面积/10000.0 as 近六个月去化面积,
        (ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ) /10000.0 as 剩余可售面积,
        ch.承诺日累计签约面积               AS [承诺日累计签约面积],    -- 承诺日累计签约面积，后续可补充
        ch.承诺日累计签约金额               AS [承诺日累计签约金额],    -- 承诺日累计签约金额，后续可补充
        sf.承诺日累计签约面积_动态版               AS [承诺日累计签约面积_动态版], -- 动态版签约面积，后续可补充
        sf.承诺日累计签约金额_动态版               AS [承诺日累计签约金额_动态版], -- 动态版签约金额，后续可补充
        sf.承诺日累计签约金额不含税_动态版               as   [承诺日累计签约金额不含税_动态版],
        sf.承诺后累计含税签约面积               AS [承诺后累计含税签约面积], -- 承诺后累计含税签约面积，后续可补充
        sf.承诺后累计含税签约金额               AS [承诺后累计含税签约金额], -- 承诺后累计含税签约金额，后续可补充
        ch.承诺日累计不含税签约金额              AS [承诺日不含税签约金额],  -- 承诺日不含税签约金额，后续可补充
        sf.承诺后累计不含税签约金额               AS [承诺后累计不含税签约金额], -- 承诺后累计不含税签约金额，后续可补充
        GETDATE()   AS [清洗日期],               -- 当前清洗日期
        mp.BeginDate as 项目获取日期,
        ISNULL(cb.盈利规划营业成本单方, 0) as 盈利规划营业成本单方,
        ISNULL(cb.盈利规划股权溢价单方, 0) as 盈利规划股权溢价单方,
        ISNULL(cb.盈利规划营销费用单方, 0) as 盈利规划营销费用单方,
        ISNULL(cb.盈利规划综合管理费单方协议口径, 0) as 盈利规划综合管理费单方协议口径,
        ISNULL(cb.盈利规划税金及附加单方, 0) as 盈利规划税金及附加单方,
        isnull(cb.营业成本单方含税费,0) as 营业成本单方含税费,
        isnull(cb.营业成本单方含税费,0) * isnull(承诺后累计含税签约面积,0) /10000.0 as 承诺后营业成本含税费,
        cb.业态组合键,
        cb.明源匹配主键,
        qh.首开日期,
        case when isnull(sf.近六个月去化面积,0) <>0 then 
                      case when datediff(month,qh.首开日期,getdate()) > 6 
                             then ( sf.近六个月去化面积 / 6.0 ) 
                        else (sf.近六个月去化面积/ datediff(month,qh.首开日期,getdate()) )   
                      end 
                          
        end /10000.0 as 月均去化面积
    FROM #cmtld ch
    inner join data_wide_dws_mdm_Project mp on mp.projguid = ch.项目GUID and  mp.level =2
    LEFT JOIN data_wide_dws_s_p_lddbamj lddb   ON lddb.SaleBldGUID = ch.产品楼栋GUID
    LEFT JOIN data_wide_dws_mdm_Building bd   ON bd.BuildingGUID = ch.产品楼栋GUID AND bd.BldType = '产品楼栋' 
    -- 动态版
    left join (
        SELECT 
            sale.ParentProjGUID,
            sale.BldGUID,
            SUM(
                CASE 
                    WHEN DATEDIFF(DAY, chld.承诺时间, StatisticalDate) >= 0 
                        THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) 
                    ELSE 0 
                END
            ) / 100000000.0 AS 承诺日累计签约金额_动态版,
            SUM(
                CASE 
                    WHEN DATEDIFF(DAY, chld.承诺时间, StatisticalDate) >= 0 
                        THEN ISNULL(Sale.CNetAmountNotTax, 0) + ISNULL(Sale.SpecialCNetAmountNotTax, 0) 
                    ELSE 0 
                END
            ) / 100000000.0 AS 承诺日累计签约金额不含税_动态版,
            SUM(
                CASE 
                    WHEN DATEDIFF(DAY, chld.承诺时间, StatisticalDate) >= 0 
                        THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) 
                    ELSE 0 
                END
            ) / 10000.0 AS 承诺日累计签约面积_动态版,

            SUM(
                ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) 
            ) / 100000000.0 AS 承诺后累计含税签约金额,
            SUM(
                ISNULL(Sale.CNetAmountNotTax, 0) + ISNULL(Sale.SpecialCNetAmountNotTax, 0) 
            ) / 100000000.0 AS 承诺后累计不含税签约金额,
            SUM(
                     ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) 
            ) / 10000.0 AS 承诺后累计含税签约面积,
            -- 近6个月去化面积
            SUM( case when StatisticalDate between DATEADD(MONTH, -6, GETDATE()) and GETDATE() then 
                     ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) 
                     else 0 
                 end
            )  AS 近六个月去化面积
        FROM data_wide_dws_s_SalesPerf Sale
        INNER JOIN #cmtld chld 
            ON Sale.bldguid = chld.产品楼栋GUID and sale.ParentProjGUID =chld.项目GUID
        GROUP BY sale.ParentProjGUID, sale.BldGUID
    ) sf On sf.bldguid =ch.产品楼栋GUID and  sf.ParentProjGUID = ch.项目GUID
    left  join  (
               SELECT DISTINCT
                    bld.ParentProjGUID,
                    bld.BuildingGUID,
                    业态组合键,
                    明源匹配主键,
                    ISNULL(ljm002.盈利规划营业成本单方, 0) as 盈利规划营业成本单方,
                    ISNULL(ljm002.盈利规划股权溢价单方, 0) as 盈利规划股权溢价单方,
                    ISNULL(ljm002.盈利规划营销费用单方, 0) as 盈利规划营销费用单方,
                    ISNULL(ljm002.盈利规划综合管理费单方协议口径, 0) as 盈利规划综合管理费单方协议口径,
                    ISNULL(ljm002.盈利规划税金及附加单方, 0) as 盈利规划税金及附加单方,
                    (
                        ISNULL(ljm002.盈利规划营业成本单方, 0)
                        + ISNULL(ljm002.盈利规划股权溢价单方, 0)
                        + ISNULL(ljm002.盈利规划营销费用单方, 0)
                        + ISNULL(ljm002.盈利规划综合管理费单方协议口径, 0)
                        + ISNULL(ljm002.盈利规划税金及附加单方, 0)
                    ) AS 营业成本单方含税费
                FROM data_wide_dws_mdm_Building bld
                LEFT JOIN #M002 ljm002
                    ON ljm002.projguid = bld.ParentProjGUID
                    AND bld.TopProductTypeName = ljm002.产品类型
                    AND bld.ProductTypeName = ljm002.产品名称
                    AND bld.CommodityType = ljm002.商品类型
                    AND bld.ZxBz = ljm002.装修标准
                WHERE bld.BldType = '产品楼栋'   
    ) cb On cb.BuildingGUID =ch.产品楼栋GUID and  cb.ParentProjGUID =ch.项目GUID
    LEFT JOIN (
        SELECT 
            存货去化承诺ID, 
            产品楼栋GUID,
            首开日期,
            CASE 
                WHEN ISNULL(salebld.TotalRoomCount, 0) = ISNULL(salebld.QyRoomCount, 0) 
                    THEN lastQyDate 
            END AS lastQyDate, -- 已开工未售部分的售罄时间
            TotalRoomCount,
            QyRoomCount
        FROM (
            SELECT 
                ld.存货去化承诺ID,
                ld.产品楼栋GUID,
                -- 首开日期：第一个认购/签约房间的认购/签约日期
                MIN(
                    CASE 
                        WHEN Status IN ('认购', '签约') AND specialFlag <> '是' THEN ISNULL(RgQsDate, QSDate)
                        WHEN Status IN ('认购', '签约') THEN ISNULL(TsRoomQSDate, ISNULL(RgQsDate, QSDate))
                    END
                ) AS 首开日期,
                MAX(
                    CASE 
                        WHEN Status = '签约' AND specialFlag <> '是' THEN QSDate
                        WHEN Status = '签约' THEN ISNULL(TsRoomQSDate, QSDate) 
                    END
                ) AS lastQyDate,
                COUNT(1) AS TotalRoomCount,
                SUM(CASE WHEN Status = '签约' THEN 1 ELSE 0 END) AS QyRoomCount
            FROM data_wide_s_RoomoVerride room
            INNER JOIN #cmtld ld  ON ld.产品楼栋GUID = room.BldGUID
            INNER JOIN data_wide_dws_s_p_lddbamj lddb 
                ON lddb.SaleBldGUID = ld.产品楼栋GUID
            WHERE lddb.SJzskgdate IS NOT NULL
            GROUP BY ld.存货去化承诺ID, ld.产品楼栋GUID
        ) salebld
        WHERE ISNULL(salebld.TotalRoomCount, 0) > 0  
    ) qh ON qh.存货去化承诺ID = ch.存货去化承诺ID 
        AND qh.产品楼栋GUID = ch.产品楼栋GUID

    /***********************************************************************
    步骤5：清理历史数据，仅保留必要快照
    说明：
        1. 保留当天数据
        2. 仅保留以下特殊快照，其余超过7天的历史数据将被删除：
            - 每周一
            - 每月1号
            - 每月最后一天
            - 每年最后一天
    ***********************************************************************/
    DELETE FROM s_集团开工申请存货去化承诺跟踪明细表智能体数据提取
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
    说明：返回当天清洗后的明细数据，便于后续分析或校验
    ***********************************************************************/
    SELECT *
    FROM s_集团开工申请存货去化承诺跟踪明细表智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0
    ORDER BY 项目名称, 业态

    /***********************************************************************
    步骤7：删除临时表，释放资源
    ***********************************************************************/
    DROP TABLE #Commitment, #cmtld

END