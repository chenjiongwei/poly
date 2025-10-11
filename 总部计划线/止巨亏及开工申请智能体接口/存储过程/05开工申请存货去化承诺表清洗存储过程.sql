USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_集团开工申请存货去化承诺表智能体数据提取]    Script Date: 2025/9/25 14:54:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 开工申请存货去化承诺清洗存储过程
-- ============================================
-- 存储过程名称：usp_s_集团开工申请存货去化承诺表智能体数据提取
-- 创建人: chenjw 2025-09-02
-- 作用：清洗并提取集团开工申请存货去化承诺表数据，供智能体使用
-- ============================================
ALTER     PROC [dbo].[usp_s_集团开工申请存货去化承诺表智能体数据提取]
AS
BEGIN
    -- 执行明细表存储过程
    exec usp_s_集团开工申请存货去化承诺跟踪明细表智能体数据提取;

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
    步骤1：查询承诺值数据，存入临时表#Commitment
    说明：从源表[存货去化承诺表]提取相关字段，类型统一标记为'承诺值'
    ***********************************************************************/
    SELECT  
        ch.存货去化承诺ID                              AS [存货去化承诺ID],              -- 唯一主键
        ch.投管代码                                   AS [投管代码],                   -- 投管系统项目代码
        ch.项目GUID                                   AS [项目GUID],                   -- 项目唯一标识
        ch.项目名称                                   AS [项目名称],                   -- 项目名称

        ch.承诺时间                                   AS [承诺时间],                   -- 承诺时间
        '承诺值'                                      AS [类型],                       -- 数据类型标记
        ch.已开工未售部分的的产品楼栋编码              AS [已开工未售部分的的产品楼栋编码], -- 楼栋编码
        ch.已开工未售部分的的产品楼栋名称              AS [已开工未售部分的的产品楼栋名称], -- 楼栋名称
        convert(varchar(7),ch.已开工未售部分的_售罄时间,121)  AS [已开工未售部分的售罄时间],     -- 售罄时间
        ch.已开工未售部分的销售均价                   AS [已开工未售部分的销售均价],     -- 销售均价
        ch.已开工未售部分的去化周期                   AS [已开工未售部分的去化周期],     -- 去化周期
        ch.已开工未售部分的税后净利润                 AS [已开工未售部分的税后净利润],   -- 税后净利润
        ch.已开工未售部分的销净率                     AS [已开工未售部分的销净率]        -- 销净率
    INTO #Commitment
    FROM [172.16.4.141].[MyCost_Erp352].dbo.存货去化承诺表 ch

    /***********************************************************************
    步骤2：查询结算动态值（预留，待实现）
    ***********************************************************************/
    -- TODO: 结算动态值相关逻辑待补充
    -- 将承诺产品楼栋编码GUID拆分
    SELECT  
        a.存货去化承诺ID,
        a.投管代码,
        a.项目GUID,
        a.承诺时间,
        value AS 产品楼栋GUID
    INTO #cmtld
    FROM #Commitment a
    CROSS APPLY dbo.fn_Split1(a.已开工未售部分的的产品楼栋编码, ';')
    WHERE ISNULL(a.已开工未售部分的的产品楼栋编码, '') <> ''

    -- 已开工未售部分的售罄时间
    -- 已开工未售部分的去化周期,
    SELECT 
        存货去化承诺ID, 
        case when ISNULL(salebld.TotalRoomCount, 0) = ISNULL(salebld.QyRoomCount, 0) then lastQyDate end as lastQyDate , -- 已开工未售部分的售罄时间
        TotalRoomCount,
        QyRoomCount
    into #LastQyDate
    FROM (
        SELECT 
            ld.存货去化承诺ID,
            MAX(
                CASE 
                    WHEN Status = '签约' AND specialFlag <> '是' THEN QSDate
                    when Status = '签约'  then ISNULL(TsRoomQSDate, QSDate) 
                END
            ) AS lastQyDate,
            COUNT(1) AS TotalRoomCount,
            SUM(CASE WHEN Status = '签约' THEN 1 ELSE 0 END) AS QyRoomCount
        FROM data_wide_s_RoomoVerride room
        inner join #cmtld ld on ld.产品楼栋GUID =room.BldGUID
        inner join data_wide_dws_s_p_lddbamj lddb on  lddb.SaleBldGUID = ld.产品楼栋GUID
        where  lddb.SJzskgdate is not null
        GROUP BY ld.存货去化承诺ID
    ) salebld
    WHERE ISNULL(salebld.TotalRoomCount, 0) > 0  
    -- 已开工未售部分的销售均价,
    -- 已开工未售部分的税后净利润,
    -- 已开工未售部分的销净率


    /***********************************************************************
    步骤3：删除当天已存在的数据，避免重复插入
    说明：以清洗日期为准，删除当天数据
    ***********************************************************************/
    DELETE FROM s_集团开工申请存货去化承诺智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

    /***********************************************************************
    步骤4：插入最新清洗结果数据
    说明：将临时表#Commitment中的数据插入目标表，并补充清洗日期
    ***********************************************************************/
    INSERT INTO s_集团开工申请存货去化承诺智能体数据提取
    (
        [存货去化承诺ID],
        [投管代码],
        [项目GUID],
        [项目名称],
        [推广名称],
        [承诺时间],
        [类型],
        [已开工未售部分的的产品楼栋编码],
        [已开工未售部分的的产品楼栋名称],
        [已开工未售部分的售罄时间],
        [已开工未售部分的销售均价],
        [已开工未售部分的去化周期],
        [已开工未售部分的税后净利润],
        [已开工未售部分的销净率],
        [清洗日期]
    )
    SELECT 
        cmt.[存货去化承诺ID],
        cmt.[投管代码],
        cmt.[项目GUID],
        cmt.[项目名称],
        p.SpreadName [推广名称],
        cmt.[承诺时间],
        '承诺值' as [类型],
        cmt.[已开工未售部分的的产品楼栋编码],
        cmt.[已开工未售部分的的产品楼栋名称],
        cmt.[已开工未售部分的售罄时间],
        cmt.[已开工未售部分的销售均价],
        cmt.[已开工未售部分的去化周期],
        cmt.[已开工未售部分的税后净利润],
        cmt.[已开工未售部分的销净率] *100  as [已开工未售部分的销净率],
        GETDATE() AS [清洗日期]
    FROM #Commitment cmt 
    inner join  data_wide_dws_mdm_Project p on p.projguid = cmt.项目GUID
    UNION ALL
    SELECT
        cmt.[存货去化承诺ID],
        cmt.[投管代码],
        cmt.[项目GUID],
        cmt.[项目名称],
        p.SpreadName as  [推广名称],
        cmt.[承诺时间],
        '动态值' AS [类型],
        cmt.[已开工未售部分的的产品楼栋编码],
        cmt.[已开工未售部分的的产品楼栋名称],
        CASE 
            WHEN dt.lastQyDate IS NOT NULL 
                THEN CONVERT(VARCHAR(7), dt.lastQyDate, 121) 
            END AS [已开工未售部分的售罄时间], -- 年月
        -- 动态值：取“存货去化承诺跟踪明细表的（N2列-N1列）/(M2列-M1列)
       case when (isnull(sale.承诺后累计含税签约面积,0)- isnull(sale.承诺日累计签约面积,0) ) =0  then  0  else 
        (isnull(sale.承诺后累计含税签约金额,0)- isnull(sale.承诺日累计签约金额,0) ) *10000.0 
        / (isnull(sale.承诺后累计含税签约面积,0)- isnull(sale.承诺日累计签约面积,0) ) end as 已开工未售部分的销售均价,
        -- 取当期日期-承诺日，直至当前日期=售罄日（本承诺内所有组团）
        CASE 
            WHEN DATEDIFF(DAY, GETDATE(), isnull(dt.lastQyDate,'1900-01-01') ) >= 0 
                THEN DATEDIFF(DAY, cmt.[承诺时间], GETDATE()) / 30.0 
			WHEN DATEDIFF(DAY, GETDATE(), isnull(dt.lastQyDate,'1900-01-01') )< 0 -- and  dt.lastQyDate is not null 
			    THEN  DATEDIFF(DAY, cmt.[承诺时间],GETDATE()) / 30.0 
         END    AS [已开工未售部分的去化周期],
        -- 动态值：取“存货去化承诺跟踪明细表的（本承诺内所有组团），X=P2列-单方（含税费）*M2列
        sale.已开工未售部分的税后净利润 AS [已开工未售部分的税后净利润],
        -- 动态值：取”存货去化承诺跟踪明细表的 X列/ （本承诺内所有组团的不含税签约金额）
        case when  isnull(sale.承诺后累计不含税签约金额,0) = 0  then  0  else
          isnull(sale.已开工未售部分的税后净利润,0) / isnull(sale.承诺后累计不含税签约金额,0) end *100 AS [已开工未售部分的销净率],
        GETDATE() AS [清洗日期]
    FROM #Commitment cmt
    inner join  data_wide_dws_mdm_Project p on p.projguid = cmt.项目GUID
    left join (
          SELECT 
              项目GUID,
              存货去化承诺ID,
              SUM(ISNULL(承诺日累计签约面积, 0))        AS 承诺日累计签约面积,
              SUM(ISNULL(承诺日累计签约金额, 0))        AS 承诺日累计签约金额,
              SUM(ISNULL(承诺后累计含税签约面积, 0))    AS 承诺后累计含税签约面积,
              SUM(ISNULL(承诺后累计含税签约金额, 0))    AS 承诺后累计含税签约金额,
              sum(isnull(xm.承诺后累计不含税签约金额,0)) as 承诺后累计不含税签约金额,
              -- 需要成本单方
              (sum(isnull(xm.承诺后累计不含税签约金额,0)) *10000.0 - sum(ISNULL(df.营业成本单方含税费, 0) * isnull(xm.承诺后累计含税签约面积,0))) /10000.0   AS 已开工未售部分的税后净利润
          FROM s_集团开工申请存货去化承诺跟踪明细表智能体数据提取 xm
          left join ( 
                SELECT DISTINCT
                    bld.ParentProjGUID,
                    bld.BuildingGUID,
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
            ) df on df.BuildingGUID = xm.已开工未售部分的的产品楼栋编码 and df.ParentProjGUID = xm.项目GUID
          WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0
          GROUP BY 项目GUID, 存货去化承诺ID
    ) sale on  sale.项目GUID = cmt.项目GUID and sale.存货去化承诺ID = cmt.存货去化承诺ID
    LEFT JOIN #LastQyDate dt 
        ON cmt.存货去化承诺ID = dt.存货去化承诺ID

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
    DELETE FROM s_集团开工申请存货去化承诺智能体数据提取
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
    ***********************************************************************/
    SELECT *
    FROM s_集团开工申请存货去化承诺智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0
    ORDER BY 项目名称,类型

    -- 删除临时表
    drop  table  #cmtld ,#Commitment,#M002

END