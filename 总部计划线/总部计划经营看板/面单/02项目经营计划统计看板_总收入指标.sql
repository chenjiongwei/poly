-- -- 02 总收入指标
-- 测试数据 18409189-6E34-EF11-B3A4-F40270D39969 龙川臻悦
Create or ALTER   proc   [dbo].[usp_zb_jyjhtjkb_SaleIncome]
as 
begin

    ----------------------------------------------------------------------
    -- 1. 创建总收入指标表（如表已存在，实际应先判断并删除或跳过，此处为示例）
    ----------------------------------------------------------------------
    -- CREATE TABLE zb_jyjhtjkb_SaleIncome
    -- (
    --     [buguid] UNIQUEIDENTIFIER,                          -- 组织GUID
    --     [projguid] UNIQUEIDENTIFIER,                        -- 项目GUID
    --     [清洗日期] DATETIME,                                 -- 清洗日期
    --     [住宅截止本月已售均价] DECIMAL(32, 10),
    --     [住宅截止上月已售均价] DECIMAL(32, 10),
    --     [住宅截止本月已售均价-立项版] DECIMAL(32, 10),
    --     [住宅总货值金额] DECIMAL(32, 10),
    --     [住宅总可售面积] DECIMAL(32, 10),
    --     [住宅总可售单方成本(真实版)-动态版] DECIMAL(32, 10),
    --     [住宅总可售单方成本(账面版)-动态版] DECIMAL(32, 10),
    --     [住宅已签约销净率(真实版）] DECIMAL(32, 10),
    --     [住宅已签约销净率(账面版）] DECIMAL(32, 10),
    --     [住宅累计销售金额] DECIMAL(32, 10),
    --     [住宅销售均价-立项版] DECIMAL(32, 10),
    --     [商办销售均价-立项版] DECIMAL(32, 10),
    --     [车位销售均价-立项版] DECIMAL(32, 10),
    --     [待售货值] DECIMAL(32, 10),
    --     [住宅待售均价] DECIMAL(32, 10),
    --     [商办待售均价] DECIMAL(32, 10),
    --     [车位待售均价] DECIMAL(32, 10)
            -- 总货值-动态版
            -- 总货值-立项版
            -- 已售货值
    -- )
    DECLARE  @lastMonth datetime = dateadd(ms,-3,DATEADD(mm, DATEDIFF(mm,0,getdate()), 0))   -- 上月最后一天
    DECLARE  @thisMonth datetime = dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,getdate())+1, 0))    -- 本月最后一天

    -- 分业态立项指标表
    ----------------------------------------------------------------------
    -- 1. 生成分业态立项指标临时表 #lxzb
    ----------------------------------------------------------------------
    SELECT 
        yt.projguid,
        yt.projname,
        sum(zhz) as 总可售货值_立项版,
        SUM(CASE WHEN ytname IN ('住宅', '高级住宅') THEN zhz ELSE 0 END) AS 住宅总可售货值_立项版,
        SUM(CASE WHEN ytname IN ('住宅', '高级住宅') THEN zksmj ELSE 0 END) AS 住宅总可售面积_立项版,
        SUM(CASE WHEN ytname NOT IN ('住宅', '高级住宅', '地下室/车库') THEN zhz ELSE 0 END) AS 商办总可售货值_立项版,
        SUM(CASE WHEN ytname NOT IN ('住宅', '高级住宅', '地下室/车库') THEN zksmj ELSE 0 END) AS 商办总可售面积_立项版,
        SUM(CASE WHEN ytname = '地下室/车库' THEN zhz ELSE 0 END) AS 车位总可售货值_立项版,
        SUM(CASE WHEN ytname = '地下室/车库' THEN carnum ELSE 0 END) AS 车位总可售套数_立项版
    INTO #lxzb
    FROM data_wide_dws_ys_SumOperatingProfitDataLXDWByYt yt
    WHERE EditonType = '立项版' 
      AND IsBase = 1
    GROUP BY yt.projguid, yt.projname;
    ----------------------------------------------------------------------
    -- 2. 计算分业态立项均价
    ----------------------------------------------------------------------
    SELECT 
        lxzb.projguid,
        lxzb.projname,
        CASE 
            WHEN ISNULL(lxzb.住宅总可售面积_立项版, 0) = 0 THEN 0
            ELSE lxzb.住宅总可售货值_立项版 *100000000.0 / lxzb.住宅总可售面积_立项版
        END AS [住宅销售均价-立项版],
        CASE 
            WHEN ISNULL(lxzb.商办总可售面积_立项版, 0) = 0 THEN 0
            ELSE lxzb.商办总可售货值_立项版 *100000000.0 / lxzb.商办总可售面积_立项版
        END AS [商办销售均价-立项版],
        CASE 
            WHEN ISNULL(lxzb.车位总可售套数_立项版, 0) = 0 THEN 0
            ELSE lxzb.车位总可售货值_立项版 *100000000.0 / lxzb.车位总可售套数_立项版
        END AS [车位销售均价-立项版]
    into #lx
    FROM #lxzb lxzb;


   -- 已售货值
       SELECT 
           Sale.ParentProjGUID AS projguid,
           SUM( ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0) )  AS 已售货值,
           -- 截止本月
           SUM(
               CASE 
                   WHEN TopProductTypeName IN ('住宅', '高级住宅') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                   ELSE 0
               END
           )  AS 住宅截止本月已售金额,
           SUM(
               CASE 
                   WHEN TopProductTypeName IN ('住宅', '高级住宅') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                   ELSE 0
               END
           )  AS 住宅截止本月已售面积,
           SUM(
               CASE 
                   WHEN TopProductTypeName IN ('住宅', '高级住宅') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                   ELSE 0
               END
           ) AS 住宅截止本月已售套数,

           SUM(
               CASE 
                   WHEN TopProductTypeName NOT IN ('住宅', '高级住宅', '地下室/车库') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                   ELSE 0
               END
           )  AS 商办截止本月已售金额,
           SUM(
               CASE 
                   WHEN TopProductTypeName NOT IN ('住宅', '高级住宅', '地下室/车库') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                   ELSE 0
               END
           )  AS 商办截止本月已售面积,
           SUM(
               CASE 
                   WHEN TopProductTypeName NOT IN ('住宅', '高级住宅', '地下室/车库') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                   ELSE 0
               END
           ) AS 商办截止本月已售套数,

           SUM(
               CASE 
                   WHEN TopProductTypeName = '地下室/车库' 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                   ELSE 0
               END
           )  AS 车位截止本月已售金额,
           SUM(
               CASE 
                   WHEN TopProductTypeName = '地下室/车库' 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                   ELSE 0
               END
           )  AS 车位截止本月已售面积,
           SUM(
               CASE 
                   WHEN TopProductTypeName = '地下室/车库' 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @thisMonth) >= 0
                   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                   ELSE 0
               END
           ) AS 车位截止本月已售套数,
           -- 截止上月
         SUM(
               CASE 
                   WHEN TopProductTypeName IN ('住宅', '高级住宅') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                   ELSE 0
               END
           )  AS 住宅截止上月已售金额,
           SUM(
               CASE 
                   WHEN TopProductTypeName IN ('住宅', '高级住宅') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                   ELSE 0
               END
           )  AS 住宅截止上月已售面积,
           SUM(
               CASE 
                   WHEN TopProductTypeName IN ('住宅', '高级住宅') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                   ELSE 0
               END
           ) AS 住宅截止上月已售套数,

           SUM(
               CASE 
                   WHEN TopProductTypeName NOT IN ('住宅', '高级住宅', '地下室/车库') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                   ELSE 0
               END
           )  AS 商办截止上月已售金额,
           SUM(
               CASE 
                   WHEN TopProductTypeName NOT IN ('住宅', '高级住宅', '地下室/车库') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                   ELSE 0
               END
           )  AS 商办截止上月已售面积,
           SUM(
               CASE 
                   WHEN TopProductTypeName NOT IN ('住宅', '高级住宅', '地下室/车库') 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                   ELSE 0
               END
           ) AS 商办截止上月已售套数,

           SUM(
               CASE 
                   WHEN TopProductTypeName = '地下室/车库' 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                   ELSE 0
               END
           )  AS 车位截止上月已售金额,
           SUM(
               CASE 
                   WHEN TopProductTypeName = '地下室/车库' 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                   ELSE 0
               END
           )  AS 车位截止上月已售面积,
           SUM(
               CASE 
                   WHEN TopProductTypeName = '地下室/车库' 
                        AND DATEDIFF(DAY, Sale.StatisticalDate, @lastMonth) >= 0
                   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                   ELSE 0
               END
           ) AS 车位截止上月已售套数
       into  #salezb
       FROM data_wide_dws_s_SalesPerf Sale
       GROUP BY Sale.ParentProjGUID
      
       -- 统计已售均价
    SELECT 
        salezb.projguid,
        -- 本月均价
        CASE 
            WHEN ISNULL(salezb.住宅截止本月已售面积, 0) = 0 THEN 0
            ELSE salezb.住宅截止本月已售金额 / salezb.住宅截止本月已售面积
        END AS [住宅截止本月已售均价],
        CASE 
            WHEN ISNULL(salezb.商办截止本月已售面积, 0) = 0 THEN 0
            ELSE salezb.商办截止本月已售金额 / salezb.商办截止本月已售面积
        END AS [商办截止本月已售均价],
        CASE 
            WHEN ISNULL(salezb.车位截止本月已售套数, 0) = 0 THEN 0
            ELSE salezb.车位截止本月已售金额 / salezb.车位截止本月已售套数
        END AS [车位截止本月已售均价],
        -- 上月均价
        CASE 
            WHEN ISNULL(salezb.住宅截止上月已售面积, 0) = 0 THEN 0
            ELSE salezb.住宅截止上月已售金额  / salezb.住宅截止上月已售面积
        END AS [住宅截止上月已售均价],
        CASE 
            WHEN ISNULL(salezb.商办截止上月已售面积, 0) = 0 THEN 0
            ELSE salezb.商办截止上月已售金额 / salezb.商办截止上月已售面积
        END AS [商办截止上月已售均价],
        CASE 
            WHEN ISNULL(salezb.车位截止上月已售套数, 0) = 0 THEN 0
            ELSE salezb.车位截止上月已售金额  / salezb.车位截止上月已售套数
        END AS [车位截止上月已售均价]
    into #sale 
    FROM #salezb salezb


    -- 货值指标
    SELECT  
        p.ParentGUID AS projguid,                         -- 项目GUID（父项目）
        SUM(ISNULL(动态总货值, 0) ) / 10000.0 AS 总货值金额,  -- 动态总货值（万元） 
        SUM(case  when  产品类型 in ('住宅', '高级住宅') then  ISNULL(动态总货值, 0) else  0  end  ) / 10000.0 AS 住宅总货值金额,  -- 动态总货值（万元）
        SUM(case  when  产品类型 in ('住宅', '高级住宅') then  ISNULL(总可售面积, 0) else  0  end  ) 住宅总可售面积,
        SUM(case  when  产品类型 not in ('住宅', '高级住宅', '地下室/车库') then  ISNULL(动态总货值, 0) else  0  end  ) / 10000.0 AS 商办总货值金额,  -- 动态总货值（万元）
        SUM(case  when  产品类型 not in ('住宅', '高级住宅', '地下室/车库') then  ISNULL(总可售面积, 0) else  0  end  ) 商办总可售面积,
        SUM(case  when  产品类型 ='地下室/车库' then  ISNULL(动态总货值, 0) else  0  end  ) / 10000.0 AS 车位总货值金额,  -- 动态总货值（万元）
        SUM(case  when  产品类型 ='地下室/车库' then  ISNULL(总可售面积, 0) else  0  end  ) 车位总可售面积,
        sum(case  when  产品类型 ='地下室/车库' then  isnull(总可售套数,0) else 0 end )  车位总可售套数
    INTO #F056
    FROM data_wide_dws_qt_F05601 F056
    INNER JOIN data_wide_dws_mdm_Project p  ON F056.projguid = p.projguid 
    GROUP BY p.ParentGUID

    ----------------------------------------------------------------------
    -- 2. 删除当天已存在的数据，避免重复插入
    ----------------------------------------------------------------------
    DELETE FROM zb_jyjhtjkb_SaleIncome
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    ----------------------------------------------------------------------
    -- 3. 汇总各项数据，插入总收入指标表
    --    说明：此处仅为结构示例，实际业务数据需补充
    ----------------------------------------------------------------------
    INSERT INTO zb_jyjhtjkb_SaleIncome (
        [buguid],
        [projguid],
        [清洗日期],
        [住宅截止本月已售均价],
        [住宅截止上月已售均价],
        [住宅截止本月已售均价-立项版],
        [住宅总货值金额],
        [住宅总可售面积],
        [住宅总可售单方成本(真实版)-动态版],
        [住宅总可售单方成本(账面版)-动态版],
        [住宅已签约销净率(真实版）],
        [住宅已签约销净率(账面版）],
        [住宅累计销售金额],
        [住宅销售均价-立项版],
        [商办销售均价-立项版],
        [车位销售均价-立项版],
        [待售货值],
        [住宅待售均价],
        [商办待售均价],
        [车位待售均价],
        [总货值-动态版],
        [总货值-立项版],
        [已售货值],
        [商办总货值金额],
        [商办总可售面积],
        [车位总货值金额],
        [车位总可售面积],
        [车位总可售套数],
        [车位总可售套数-立项版],
        [车位截止本月已售套数],
        [商办截止本月已售均价],
        [车位截止本月已售均价]
    )
    SELECT
        p.buguid AS [buguid],                -- 事业部GUID
        p.projguid AS [projguid],            -- 项目GUID
        GETDATE() AS [清洗日期],             -- 当前清洗日期

        -- 以下字段实际应为业务汇总结果，此处全部为NULL占位
        sb.住宅截止本月已售均价 AS [住宅截止本月已售均价],
        sb.住宅截止上月已售均价 AS [住宅截止上月已售均价],
        lx.[住宅销售均价-立项版] / 100000000.0  AS [住宅截止本月已售均价-立项版],
        f056.住宅总货值金额  AS [住宅总货值金额],
        f056.住宅总可售面积  AS [住宅总可售面积],
        NULL AS [住宅总可售单方成本(真实版)-动态版],
        NULL AS [住宅总可售单方成本(账面版)-动态版],
        NULL AS [住宅已签约销净率(真实版）],
        NULL AS [住宅已签约销净率(账面版）],
        NULL AS [住宅累计销售金额],
        lx.[住宅销售均价-立项版] / 100000000.0 AS [住宅销售均价-立项版],
        lx.[商办销售均价-立项版] / 100000000.0 AS [商办销售均价-立项版],
        lx.[车位销售均价-立项版] / 100000000.0 AS [车位销售均价-立项版],
        NULL AS [待售货值],
        NULL AS [住宅待售均价],
        NULL AS [商办待售均价],
        NULL AS [车位待售均价],
        f056.总货值金额 as  [总货值-动态版],
        lxzb.总可售货值_立项版 / 100000000.0  as [总货值-立项版],
        sbzb.已售货值 / 100000000.0 as  已售货值,
        f056.商办总货值金额  as [商办总货值金额],
        f056.商办总可售面积  as [商办总可售面积],
        f056.车位总货值金额  as [车位总货值金额],
        f056.车位总可售面积  as  [车位总可售面积],
        f056.车位总可售套数 as  [车位总可售套数],
        lxzb.车位总可售套数_立项版 as [车位总可售套数-立项版],
        sbzb.车位截止本月已售套数 as  [车位截止本月已售套数],
        sb.商办截止本月已售均价 as [商办截止本月已售均价],
        sb.车位截止本月已售均价 as [车位截止本月已售均价]
    FROM data_wide_dws_mdm_Project p
    left  join #lx  lx  on lx.projguid = p.projguid
    left  join #lxzb  lxzb on  lxzb.projguid = p.projguid
    left  join #sale  sb on sb.projguid =p.projguid
	left  join   #salezb  sbzb  on  sbzb.projguid =p.projguid
    left join #F056  f056 on f056.projguid =p.projguid
    WHERE p.level = 2; -- 只统计二级项目

    ----------------------------------------------------------------------
    -- 4. 查询当天插入的最终数据，便于校验
    ----------------------------------------------------------------------
    SELECT
        [buguid],
        [projguid],
        [清洗日期],
        [住宅截止本月已售均价],
        [住宅截止上月已售均价],
        [住宅截止本月已售均价-立项版],
        [住宅总货值金额],
        [住宅总可售面积],
        [住宅总可售单方成本(真实版)-动态版],
        [住宅总可售单方成本(账面版)-动态版],
        [住宅已签约销净率(真实版）],
        [住宅已签约销净率(账面版）],
        [住宅累计销售金额],
        [住宅销售均价-立项版],
        [商办销售均价-立项版],
        [车位销售均价-立项版],
        [待售货值],
        [住宅待售均价],
        [商办待售均价],
        [车位待售均价],
        [总货值-动态版],
        [总货值-立项版],
        [已售货值],
        [商办总货值金额],
        [商办总可售面积],
        [车位总货值金额],
        [车位总可售面积],
        [车位总可售套数],
        [车位总可售套数-立项版],
        [车位截止本月已售套数],
        [商办截止本月已售均价],
        [车位截止本月已售均价]
    FROM zb_jyjhtjkb_SaleIncome
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    -- 删除临时表
    drop  TABLE  #lx,#lxzb,#sale,#F056
end 



 SELECT
        [buguid],
        [projguid],
        [清洗日期],
        isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) as [住宅截止本月已售均价],
        [住宅截止上月已售均价],
        [住宅截止本月已售均价-立项版],
        case when  isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) is not null and [住宅截止本月已售均价-立项版] is not null then 
            isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) - isnull([住宅截止本月已售均价-立项版],0) end as [住宅截止本月已售均价偏差],
        case when   isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) is not null and [住宅截止上月已售均价] is not null then 
            isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) - isnull( [住宅截止上月已售均价],0 )  end  [住宅截止本月已售均价环比提降],
        isnull(lczy.[住宅总货值金额], sale.[住宅总货值金额]) as [住宅总货值金额],
        isnull(lczy.[住宅总可售面积], sale.[住宅总可售面积]) as [住宅总可售面积],
        isnull(lczy.[住宅总可售单方成本(真实版)-动态版], sale.[住宅总可售单方成本(真实版)-动态版]) as [住宅总可售单方成本(真实版)-动态版],
        [住宅总可售单方成本(账面版)-动态版],
        [住宅已签约销净率(真实版）],
        [住宅已签约销净率(账面版）],
        isnull(lczy.[住宅累计销售金额], sale.[住宅累计销售金额]) as [住宅累计销售金额],
        [住宅销售均价-立项版],
        [商办销售均价-立项版],
        [车位销售均价-立项版],
        [待售货值],
        [住宅待售均价],
        [商办待售均价],
        [车位待售均价]
    FROM zb_jyjhtjkb_SaleIncome sale
    left join  data_tb_ylss_lczy lczy on  sale.projguid =lczy.项目GUID
    WHERE DATEDIFF(DAY, [清洗日期], ${qxDate} ) = 0