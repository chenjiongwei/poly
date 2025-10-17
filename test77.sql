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
            WHEN lddb.SJzskgdate IS NOT NULL THEN lddb.zhz --lddb.syhz 
            ELSE 0  
        END / 100000000.0 AS [开工货值],

        -- 供货周期=楼栋实际达预售形象汇报完成时间-楼栋实际开工汇报完成时间（月）
        DATEDIFF(MONTH, isnull(lddb.SJzskgdate, lddb.YJzskgdate), isnull(lddb.SjDdysxxDate, lddb.YjDdysxxDate)) AS [供货周期],
        -- 去化周期=楼栋下最后一个房间的签约时间-第一个房间的认购时间（月）
        -- CASE WHEN    sk.售罄日期 IS NOT NULL 
        --     THEN DATEDIFF(MONTH, sk.首开日期, sk.售罄日期)
        -- END AS [去化周期],
        case when datediff(day,getdate(),isnull(sk.售罄日期,'1900-01-01')) >= 0 then
           datediff(day,sk.首开日期,isnull(sk.售罄日期,'1900-01-01')) / 30.0 
          when datediff(day,getdate(),isnull(sk.售罄日期,'1900-01-01')) <0 then
            datediff(day,sk.首开日期,getdate()) / 30.0 end  AS [去化周期],  

        hk.累计回笼金额 / 100000000.0 AS [累计签约回笼], -- 累计签约回笼（单位：亿元）
      
        isnull(dss.ManageAmount,0) / 10000 as 管理费用,
        isnull(dss.Financial,0) / 10000 as 财务费用,
        fy.整盘营销费用系统已发生费率,

        isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.含税签约金额 / 100000000.0 ) * fy.整盘营销费用系统已发生费率
        + (isnull(dss.ManageAmount,0) + isnull(dss.Financial,0)) / 10000 * jzmj.楼栋在建面积占比      as 累计除地价外直投及费用,
        isnull(hk.累计回笼金额 / 100000000.0,0) 
        -(isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.含税签约金额 / 100000000.0 ) * fy.整盘营销费用系统已发生费率
        + (isnull(dss.ManageAmount,0) + isnull(dss.Financial,0)) / 10000 * jzmj.楼栋在建面积占比  )    as 累计贡献现金流, -- 累计签约回笼-累计除地价外直投及费用
        sf.一年内签约金额 / 100000000.0 AS [一年内签约金额], -- 一年内签约金额（单位：亿元）
        hk.累计本年回笼金额 / 100000000.0 AS [一年内回笼金额], -- 一年内回笼金额（单位：亿元）
  
         isnull(cz.累计已完成产值 / 100000000.0 ,0)  as 累计已完成产值,
        fy.本年营销费用系统已发生费率,
        jzmj.楼栋在建面积占比,
        isnull(dss.YearManageAmount,0) / 10000 as 本年管理费用,
        isnull(dss.YearFinancial,0) / 10000 as 本年财务费用,
        isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.一年内签约金额 / 100000000.0 ) * fy.本年营销费用系统已发生费率
        + (isnull(dss.YearManageAmount,0) + isnull(dss.YearFinancial,0)) / 10000 * jzmj.楼栋在建面积占比    as  [一年内除地价外直投及费用],
        isnull(hk.累计本年回笼金额 / 100000000.0,0) - 
        (
        isnull(cz.累计已完成产值 / 100000000.0 ,0) 
        + ( sf.一年内签约金额 / 100000000.0 ) * fy.本年营销费用系统已发生费率
        + (isnull(dss.YearManageAmount,0) + isnull(dss.YearFinancial,0)) / 10000 * jzmj.楼栋在建面积占比  
        )  as  [一年内贡献现金流],     --本年回笼-本年除地价外直投及费用
        sf.含税签约金额 / 100000000.0 AS [含税签约金额], -- 含税签约金额（单位：亿元）
        sf.已售面积 / 10000.0 AS [已售面积],             -- 已售面积（单位：万㎡）
        sf.不含税签约金额 / 100000000.0 AS [不含税签约金额], -- 不含税签约金额（单位：亿元）
        GETDATE() AS [清洗日期]                          -- 当前清洗日期
    FROM #xtxmld xt
    -- 关联楼栋主数据，获取编码、名称
    inner JOIN data_wide_dws_mdm_Building bd ON bd.BuildingGUID = xt.产品楼栋GUID  AND bd.BldType = '产品楼栋'
    -- 关联楼栋底表，获取业态、面积、开工等信息
    LEFT JOIN data_wide_dws_s_p_lddbamj lddb  ON lddb.SaleBldGUID = xt.产品楼栋GUID
    left  join #cz cz  on cz.ProdBldGUID = xt.产品楼栋GUID
    left join #Jzmj jzmj on jzmj.BuildingGUID =xt.产品楼栋GUID
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
    ) sk  ON sk.本次新推量价承诺ID = xt.本次新推量价承诺ID  AND sk.产品楼栋GUID = xt.产品楼栋GUID
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
    left join #fy_ys fy on xt.项目GUID =fy.projguid
    left join #Dss_cashflow dss on xt.项目GUID =dss.projguid