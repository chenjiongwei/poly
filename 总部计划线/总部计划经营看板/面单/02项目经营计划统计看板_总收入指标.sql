USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_zb_jyjhtjkb_SaleIncome]    Script Date: 2025/11/6 22:51:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- -- 02 总收入指标
-- 测试数据 18409189-6E34-EF11-B3A4-F40270D39969 龙川臻悦
ALTER    proc   [dbo].[usp_zb_jyjhtjkb_SaleIncome]
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
        sum(case  when  产品类型 in ('住宅', '高级住宅') then  isnull(动态总货值,0)*isnull(总可售面积,0) else 0 end )  住宅累计销售金额,
        sum(case  when  产品类型 in ('住宅', '高级住宅') then  case when isnull(待售面积,0) =0  then  0 else  isnull(待售货值,0)/isnull(待售面积,0)  end  else 0 end )  住宅待售均价,

        SUM(case  when  产品类型 not in ('住宅', '高级住宅', '地下室/车库') then  ISNULL(动态总货值, 0) else  0  end  ) / 10000.0 AS 商办总货值金额,  -- 动态总货值（万元）
        SUM(case  when  产品类型 not in ('住宅', '高级住宅', '地下室/车库') then  ISNULL(总可售面积, 0) else  0  end  ) 商办总可售面积,
        sum(case  when  产品类型 not in ('住宅', '高级住宅', '地下室/车库') then  case when isnull(待售面积,0) =0  then  0 else  isnull(待售货值,0)/isnull(待售面积,0)  end  else 0 end )  商办待售均价,

        SUM(case  when  产品类型 ='地下室/车库' then  ISNULL(动态总货值, 0) else  0  end  ) / 10000.0 AS 车位总货值金额,  -- 动态总货值（万元）
        SUM(case  when  产品类型 ='地下室/车库' then  ISNULL(总可售面积, 0) else  0  end  ) 车位总可售面积,
        sum(case  when  产品类型 ='地下室/车库' then  isnull(总可售套数,0) else 0 end )  车位总可售套数,
        sum(case  when  产品类型 ='地下室/车库' then  case when isnull(待售面积,0) =0  then  0 else  isnull(待售货值,0)/isnull(待售面积,0)  end  else 0 end )  车位待售均价,
        sum(case  when  产品类型 ='地下室/车库' then  case when isnull(总可售套数,0) =0 then  0  else  isnull(已售套数,0)/isnull(总可售套数,0) end  else 0 end )  车位去化率,

        sum(case  when  产品类型 ='商业' and 产品名称 = '商铺' then  isnull(已售货值,0)/nullif(已售面积, 0) else 0 end )  商业截止本月已售均价,
        sum(case  when  产品类型 ='商业' and 产品名称 = '商铺' then  isnull(动态总货值,0) else 0 end )/ 10000.0  商业总货值金额,
        sum(case  when  产品类型 ='商业' and 产品名称 = '商铺' then  isnull(总可售面积,0) else 0 end )  商业总可售面积,
        sum(case  when  产品类型 ='商业' and 产品名称 = '商铺' then  isnull(动态总货值,0)*isnull(总可售面积,0) else 0 end )  商业累计销售金额,
        sum(case  when  产品类型 ='商业' and 产品名称 = '商铺' then  isnull(待售货值,0) else 0 end )  商业待售货值,
        sum(case  when  产品类型 ='商业' and 产品名称 = '商铺' then  case when isnull(待售面积,0) =0  then  0 else  isnull(待售货值,0)/isnull(待售面积,0)  end  else 0 end )  商业待售均价,
        
        sum(case  when  产品类型 ='写字楼' then  isnull(已售货值,0)/nullif(已售面积, 0) else 0 end )  办公截止本月已售均价,
        sum(case  when  产品类型 ='写字楼' then  isnull(动态总货值,0) else 0 end ) / 10000.0  办公总货值金额,
        sum(case  when  产品类型 ='写字楼' then  isnull(总可售面积,0) else 0 end )  办公总可售面积,
        sum(case  when  产品类型 ='写字楼' then  isnull(动态总货值,0)*isnull(总可售面积,0) else 0 end )  办公累计销售金额,
        sum(case  when  产品类型 ='写字楼' then  isnull(待售货值,0) else 0 end )  办公待售货值,
        sum(case  when  产品类型 ='写字楼' then case when  isnull(待售面积,0) =0  then  0 else  isnull(待售货值,0)/isnull(待售面积,0)  end  else 0 end )  办公待售均价

    INTO #F056
    FROM data_wide_dws_qt_F05601 F056
    INNER JOIN data_wide_dws_mdm_Project p  ON F056.projguid = p.projguid 
    GROUP BY p.ParentGUID

    -- 填报数据
    SELECT 
        jytb.项目GUID,
        jytb.住宅总可售单方成本_真实版,
        jytb.住宅已签约销净率_真实版
    INTO #JyjhtjkbTb
    FROM data_wide_dws_qt_Jyjhtjkb jytb
    WHERE jytb.FillHistoryGUID IN (
        SELECT TOP 1 FillHistoryGUID
        FROM data_wide_dws_qt_Jyjhtjkb
        ORDER BY FillDate DESC
    )

    -- 车位去化率
    select 
    projguid,
    车位去化率_按套数
    INTO #Ytqbz
    from data_wide_dws_s_Ytqbz 

    select  distinct 
    projguid, 
    天地非天地极差 as 顶底非顶底极差,
    楼层非天地去化率 as 非顶底去化率,
    楼层天地去化率 as 顶底去化率,
    case when  abs(楼层天地去化率 - 楼层非天地去化率)>0.2 then '不达标' else  '达标' end as 楼层齐步走
    into #Ddqbz 
    from  
    data_wide_dws_s_Ddqbz 

    -- 户型去化率
    select  DISTINCT  projguid,
    最大去化率 as 户型最大去化率,
    最小去化率 as 户型最小去化率,
    户型去化率极差 as 户型去化率极差,
    case when  abs(户型去化率极差)>0.2 then '不达标' else  '达标' end as 户型齐步走
    into #hxqbz 
    from  data_wide_dws_s_Hxqbz


    -- 盈利规划F0203
    SELECT
        bld.ParentProjGUID AS 项目GUID,
        SUM(
            CASE
                WHEN a.销售预测科目 = '累计签约金额'
                    THEN CONVERT(DECIMAL(22, 2), a.VALUE_STRING)
                ELSE 0
            END
        ) AS 住宅截止本月已售金额_一盘一策版,
        SUM(
            CASE
                WHEN a.销售预测科目 = '累计签约面积'
                    THEN CONVERT(DECIMAL(22, 2), a.VALUE_STRING)
                ELSE 0
            END
        ) AS 住宅截止本月已售面积_一盘一策版,
        CASE
            WHEN SUM(CASE WHEN a.销售预测科目 = '累计签约面积' THEN CONVERT(DECIMAL(22, 2), a.VALUE_STRING) ELSE 0 END) = 0
                THEN 0
            ELSE
                SUM(CASE WHEN a.销售预测科目 = '累计签约金额' THEN CONVERT(DECIMAL(22, 2), a.VALUE_STRING) ELSE 0 END)
                /
                SUM(CASE WHEN a.销售预测科目 = '累计签约面积' THEN CONVERT(DECIMAL(22, 2), a.VALUE_STRING) ELSE 0 END)
        END AS 住宅截止本月已售均价_一盘一策版
    INTO #F0203
    FROM
        data_wide_qt_F020004 a
        INNER JOIN data_wide_dws_mdm_Building bld
            ON bld.BldType = '产品楼栋'
            AND a.实体楼栋 = CONVERT(VARCHAR(50), bld.BuildingGUID)
        INNER JOIN data_wide_dws_ys_ProjGUID ylghProj
            ON ylghProj.ProjGUID = bld.ParentProjGUID
            AND ylghProj.isbase = 1
            AND ylghProj.BusinessEdition = a.版本
            AND ylghProj.Level = 2
    WHERE
        a.销售预测科目 IN ('累计签约金额', '累计签约面积')
        AND a.年 = CONVERT(VARCHAR(10), YEAR(GETDATE())) + '年'
        AND a.期间 = CONVERT(VARCHAR(10), MONTH(GETDATE())) + '月'
        AND bld.TopProductTypeName = '住宅'
        AND CHARINDEX('e', ISNULL(a.VALUE_STRING, '0')) = 0
        AND (
            CONVERT(DECIMAL(22, 2), a.VALUE_STRING) > 0.01
            OR CONVERT(DECIMAL(22, 2), a.VALUE_STRING) < -0.01
        )
    GROUP BY
        bld.ParentProjGUID


    -- --单方数据3
    -- SELECT 
    --     pj.projguid,
    --     业态 AS ytname,
    --     SUM(CASE 
    --         WHEN 报表预测项目科目 = '结转成本' 
    --             AND 综合维 = '可售产品' 
    --         THEN CONVERT(DECIMAL(32,4), value_string) 
    --         ELSE 0 
    --     END) AS 经营成本,
    --     SUM(CASE 
    --         WHEN 报表预测项目科目 = '综合管理费用-协议口径' 
    --             AND 综合维 = '可售产品' 
    --         THEN CONVERT(DECIMAL(32,4), value_string) 
    --         ELSE 0 
    --     END) AS 管理费用
    -- INTO #df3
    -- FROM [172.16.4.161].HighData_prod.dbo.data_wide_qt_F080004 f03
    --     INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
    --         ON f03.实体分期 = pj.YLGHProjGUID
    --         AND pj.edition = @ylghbb
    --         AND pj.Level = 3 
    --         AND f03.版本 = pj.BusinessEdition
    -- WHERE CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0
    --     AND 明细说明 = '总价' 
    -- GROUP BY 
    --     pj.projguid,
    --     业态;

    -- --缓存F08000202表的数据
    SELECT F08.*
    INTO #F08000202
    FROM HighData_prod.dbo.data_wide_qt_F08000202 F08
    INNER JOIN HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON F08.实体分期 = pj.YLGHProjGUID
        and   pj.isbase = 1
            AND pj.Level = 3 
            AND F08.版本 = pj.BusinessEdition
    WHERE CHARINDEX('e', ISNULL(F08.VALUE_STRING, '0')) = 0
        AND left(年,4) <=  YEAR(getdate())
        AND 报表预测项目科目 IN ( '签约面积', '签约收入（含税）', '销售收入(不含税）' )
        AND 期间 = '全周期';

    -- 缓存业态信息
    SELECT DISTINCT
        yt.ProjGUID,
        pj.projguid AS 项目guid,
        p.projcode_25 + '_' + ISNULL(ty.ParentName, ty.HierarchyName) + '_' + yt.ytname AS [业态组合键_业态],
        yt.ytname,
        ISNULL(ty.ParentName, ty.HierarchyName) AS [产品类型],
        LEFT(yt.ytname, CHARINDEX('_', yt.ytname) - 1) AS [产品名称],
        LEFT(
            SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100),
            CHARINDEX('_', SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100)) - 1
        ) AS [商品类型],
        SUBSTRING(
            SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100),
            CHARINDEX('_', SUBSTRING(yt.ytname, CHARINDEX('_', yt.ytname) + 1, 100)) + 1,
            100
        ) AS [装修标准]
    INTO #yt
    FROM HighData_prod.dbo.data_wide_dws_ys_SumProjProductYt yt
    INNER JOIN HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj
        ON yt.ProjGUID = pj.YLGHProjGUID
        AND pj.isbase = 1
        AND pj.level = 3
    INNER JOIN HighData_prod.dbo.data_wide_dws_mdm_project p
        ON p.projguid = pj.ProjGUID
    LEFT JOIN (
        SELECT
            ty.ParentName,
            ty.HierarchyName,
            ROW_NUMBER() OVER (PARTITION BY HierarchyName ORDER BY HierarchyName DESC) AS rn
        FROM HighData_prod.dbo.data_wide_mdm_ProductType ty
    ) ty
        ON yt.ProductType = ty.HierarchyName
        AND rn = 1
    WHERE yt.isbase = 1
        AND yt.YtName <> '不区分业态'
        AND (p.projcode_25 + '_' + ISNULL(ty.ParentName, ty.HierarchyName) + '_' + yt.ytname) IS NOT NULL;

    -- 获取盈利规划销售铺排情况
    SELECT
        yt.项目guid,
        f08.业态,
        yt.产品类型,
        yt.产品名称,
        yt.商品类型,
        yt.装修标准,
        -- SUM(
        --     CASE WHEN 报表预测项目科目 = '签约收入（含税）'
        --         THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END
        -- ) AS 盈利规划总货值,
        -- SUM(
        --     CASE WHEN 报表预测项目科目 = '签约面积'
        --         THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END
        -- ) AS 盈利规划总货值面积,
        -- -- SUM(CASE WHEN 年 = CONVERT(VARCHAR(4), YEAR(GETDATE())) + '年' AND 报表预测项目科目 = '签约收入（含税）' THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END) AS 盈利规划本年签约均价,
        -- SUM(
        --     CASE WHEN 报表预测项目科目 = '销售收入(不含税）'
        --         THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END
        -- ) AS 盈利规划总货值不含税,
        
        SUM(
            CASE WHEN 报表预测项目科目 = '签约收入（含税）'
               
                THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END
        ) AS 盈利规划已售货值,
        SUM(
            CASE WHEN 报表预测项目科目 = '签约面积'
                THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END
        ) AS 盈利规划已售货值面积,
        -- SUM(CASE WHEN 年 = CONVERT(VARCHAR(4), YEAR(GETDATE())) + '年' AND 报表预测项目科目 = '签约收入（含税）' THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END) AS 盈利规划本年签约均价,
        SUM(
            CASE WHEN 报表预测项目科目 = '销售收入(不含税）'
                THEN CONVERT(DECIMAL(36, 8), value_string) ELSE 0 END
        ) AS 盈利规划已售货值不含税
    INTO #F0802_tmp1
    FROM #F08000202 f08
    INNER JOIN #yt yt ON f08.业态 = yt.YtName AND f08.实体分期 = yt.ProjGUID
    GROUP BY yt.项目guid,f08.业态,yt.产品类型,
        yt.产品名称,
        yt.商品类型,
        yt.装修标准

    -- 查询总货值、住宅、办公、商业、车位一盘一策版的数据
    SELECT  t.项目guid,
        SUM(ISNULL(盈利规划总货值, 0)) AS [总货值-一盘一策版],

        SUM(CASE WHEN 产品类型 = '住宅' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END) AS [住宅总货值-一盘一策版],
        CASE 
            WHEN SUM(CASE WHEN 产品类型 = '住宅' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END) = 0 THEN 0
            ELSE SUM(CASE WHEN 产品类型 = '住宅' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END) 
                / SUM(CASE WHEN 产品类型 = '住宅' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END) 
        END AS [住宅销售均价-一盘一策版],

        SUM(CASE WHEN 产品类型 = '办公' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END) AS [办公总货值-一盘一策版],
        CASE 
            WHEN SUM(CASE WHEN 产品类型 = '办公' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END) = 0 THEN 0
            ELSE SUM(CASE WHEN 产品类型 = '办公' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END)
                / SUM(CASE WHEN 产品类型 = '办公' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END)
        END AS [办公销售均价-一盘一策版],

        SUM(CASE WHEN 产品类型 ='商业' and 产品名称 = '商铺' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END) AS [商业总货值-一盘一策版],
        CASE 
            WHEN SUM(CASE WHEN 产品类型 ='商业' and 产品名称 = '商铺' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END) = 0 THEN 0
            ELSE SUM(CASE WHEN 产品类型 ='商业' and 产品名称 = '商铺' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END)
                / SUM(CASE WHEN 产品类型 ='商业' and 产品名称 = '商铺' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END)
        END AS [商业销售均价-一盘一策版],

        SUM(CASE WHEN 产品类型 IN ('商业','办公') THEN ISNULL(盈利规划总货值, 0) ELSE 0 END) AS [商办总货值-一盘一策版],
        CASE 
            WHEN SUM(CASE WHEN 产品类型 IN ('商业','办公') THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END) = 0 THEN 0
            ELSE SUM(CASE WHEN 产品类型 IN ('商业','办公') THEN ISNULL(盈利规划总货值, 0) ELSE 0 END)
                / SUM(CASE WHEN 产品类型 IN ('商业','办公') THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END)
        END AS [商办销售均价-一盘一策版],

        SUM(CASE WHEN 产品类型 = '车位' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END) AS [车位总货值-一盘一策版],
        CASE 
            WHEN SUM(CASE WHEN 产品类型 = '车位' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END) = 0 THEN 0
            ELSE SUM(CASE WHEN 产品类型 = '车位' THEN ISNULL(盈利规划总货值, 0) ELSE 0 END)
                / SUM(CASE WHEN 产品类型 = '车位' THEN ISNULL(盈利规划总货值面积, 0) ELSE 0 END)
        END AS [车位销售均价-一盘一策版]
    into #F0802_tmp2
    FROM  #F0802_tmp1 t 
    left join (select 项目guid,产品名称+'_'+商品类型+'_'+装修标准 业态组合键_业态,sum(销售收入含税) as 盈利规划总货值,sum(总可售面积) as 盈利规划总货值面积 
	from dw_f_ProfitCost_byyt_ylgh
	group by 项目guid, 产品名称+'_'+商品类型+'_'+装修标准
	) ylgh on ylgh.项目guid=t.项目guid
	and ylgh.业态组合键_业态 = t.业态 
    GROUP BY 
        t.项目guid
    

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
        [车位截止本月已售均价],
        [住宅截止本月已售均价-一盘一策版],
        -- 新增字段
        [总货值-一盘一策版],
        [住宅总货值-一盘一策版],
        [住宅销售均价-一盘一策版],
        [办公总货值-一盘一策版],
        [办公销售均价-一盘一策版],
        [商业总货值-一盘一策版],
        [商业销售均价-一盘一策版],
        [商办总货值-一盘一策版],
        [商办销售均价-一盘一策版],
        [车位总货值-一盘一策版],
        [车位销售均价-一盘一策版],
        [商业截止本月已售均价],
        [商业总货值金额],
        [商业总可售面积],
        [商业累计销售金额],
        [办公截止本月已售均价],
        [办公总货值金额],
        [办公总可售面积],
        [办公累计销售金额],
        [车位去化率],
        [顶底去化率],
        [商业待售货值],
        [商业待售均价],
        [办公待售货值],
        [办公待售均价],
        [部分户型最小去化率],
        [是否齐步走]
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
        jb.住宅总可售单方成本_真实版 AS [住宅总可售单方成本(真实版)-动态版],
        NULL AS [住宅总可售单方成本(账面版)-动态版],
        jb.住宅已签约销净率_真实版 AS [住宅已签约销净率(真实版）],
        NULL AS [住宅已签约销净率(账面版）],
        住宅累计销售金额 AS [住宅累计销售金额],
        lx.[住宅销售均价-立项版] / 100000000.0 AS [住宅销售均价-立项版],
        lx.[商办销售均价-立项版] / 100000000.0 AS [商办销售均价-立项版],
        lx.[车位销售均价-立项版] / 100000000.0 AS [车位销售均价-立项版],
        isnull(f056.总货值金额,0) - isnull(sbzb.已售货值 / 100000000.0,0) AS [待售货值],
        f056.住宅待售均价 AS [住宅待售均价],
        f056.商办待售均价 AS [商办待售均价],
        f056.车位待售均价 AS [车位待售均价],
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
        sb.车位截止本月已售均价 as [车位截止本月已售均价],
        f0203.住宅截止本月已售均价_一盘一策版 as [住宅截止本月已售均价-一盘一策版],
        -- 新增字段 
        F08.[总货值-一盘一策版]/ 100000000.0 as [总货值-一盘一策版],
        F08.[住宅总货值-一盘一策版] / 100000000.0 as [住宅总货值-一盘一策版],
        F08.[住宅销售均价-一盘一策版] as [住宅销售均价-一盘一策版],
        F08.[办公总货值-一盘一策版]/ 100000000.0 as [办公总货值-一盘一策版],
        F08.[办公销售均价-一盘一策版] as [办公销售均价-一盘一策版],
        F08.[商业总货值-一盘一策版]/ 100000000.0 as [商业总货值-一盘一策版],
        F08.[商业销售均价-一盘一策版] as [商业销售均价-一盘一策版],
        F08.[商办总货值-一盘一策版] / 100000000.0 as [商办总货值-一盘一策版],
        F08.[商办销售均价-一盘一策版] as [商办销售均价-一盘一策版],
        F08.[车位总货值-一盘一策版] / 100000000.0 as [车位总货值-一盘一策版],
        F08.[车位销售均价-一盘一策版] as [车位销售均价-一盘一策版],
        f056.商业截止本月已售均价 as [商业截止本月已售均价],
        f056.商业总货值金额 as [商业总货值金额],
        f056.商业总可售面积 as [商业总可售面积],
        f056.商业累计销售金额 as [商业累计销售金额],
        f056.办公截止本月已售均价 as [办公截止本月已售均价],
        f056.办公总货值金额 as [办公总货值金额],
        f056.办公总可售面积 as [办公总可售面积],
        f056.办公累计销售金额 as [办公累计销售金额],
        ytqbz.车位去化率_按套数 as [车位去化率],
        ddqbz.顶底去化率 as [顶底去化率],
        f056.商业待售货值 as [商业待售货值],
        f056.商业待售均价 as [商业待售均价],
        f056.办公待售货值 as [办公待售货值],
        f056.办公待售均价 as [办公待售均价],
        hxqbz.户型最小去化率 as 部分户型最小去化率,
        case when   ddqbz.[楼层齐步走] = '不达标' then '楼层未齐步走 ' else  '楼层齐步走'  end 
        + case when  hxqbz.[户型齐步走] = '不达标' then '户型未齐步走 ' else  '户型齐步走' end  as 是否齐步走
    FROM data_wide_dws_mdm_Project p
    left  join #lx  lx  on lx.projguid = p.projguid
    left  join #lxzb  lxzb on  lxzb.projguid = p.projguid
    left  join #sale  sb on sb.projguid =p.projguid
	left  join #salezb  sbzb  on  sbzb.projguid =p.projguid
    left join #F056  f056 on f056.projguid =p.projguid
    left join #F0203  f0203 on f0203.项目GUID =p.projguid
    left join #F0802_tmp2  F08 on F08.项目guid = p.ProjGUID
    left join #Ytqbz ytqbz on ytqbz.projguid = p.projguid
    left join #Ddqbz ddqbz on ddqbz.projguid = p.projguid
    left join #hxqbz hxqbz on hxqbz.projguid = p.projguid
    left join #JyjhtjkbTb  jb on jb.项目GUID =p.projguid
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
        [车位截止本月已售均价],
        [住宅截止本月已售均价-一盘一策版],
        [总货值-一盘一策版],
        [住宅总货值-一盘一策版],
        [住宅销售均价-一盘一策版],
        [办公总货值-一盘一策版],
        [办公销售均价-一盘一策版],
        [商业总货值-一盘一策版],
        [商业销售均价-一盘一策版],
        [商办总货值-一盘一策版],
        [商办销售均价-一盘一策版],
        [车位总货值-一盘一策版],
        [车位销售均价-一盘一策版],
        [商业截止本月已售均价],
        [商业总货值金额],
        [商业总可售面积],
        [商业累计销售金额],
        [办公截止本月已售均价],
        [办公总货值金额],
        [办公总可售面积],
        [办公累计销售金额],
        [车位去化率],
        [顶底去化率],
        [商业待售货值],
        [商业待售均价],
        [办公待售货值],
        [办公待售均价],
        [部分户型最小去化率],
        [是否齐步走]
    FROM zb_jyjhtjkb_SaleIncome
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    -- 删除临时表
    drop  TABLE  #lx,#lxzb,#sale,#F056,#F0203,#F08000202,#F0802_tmp1,#F0802_tmp2, #ddqbz, #ytqbz
end 






--  SELECT
--         [buguid],
--         [projguid],
--         [清洗日期],
--         isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) as [住宅截止本月已售均价],
--         [住宅截止上月已售均价],
--         [住宅截止本月已售均价-立项版],
--         case when  isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) is not null and [住宅截止本月已售均价-立项版] is not null then 
--             isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) - isnull([住宅截止本月已售均价-立项版],0) end as [住宅截止本月已售均价偏差],
        
--         case when  isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) is not null and [住宅截止本月已售均价-一盘一策版] is not null then 
--             isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) - isnull([住宅截止本月已售均价-一盘一策版],0) end as [住宅截止本月已售均价偏差_存量],

--         case when   isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) is not null and [住宅截止上月已售均价] is not null then 
--             isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价]) - isnull( [住宅截止上月已售均价],0 )  end  [住宅截止本月已售均价环比提降],
--         isnull(lczy.[住宅总货值金额], sale.[住宅总货值金额]) as [住宅总货值金额],
--         isnull(lczy.[住宅总可售面积], sale.[住宅总可售面积]) as [住宅总可售面积],
--         isnull(lczy.[住宅总可售单方成本(真实版)-动态版], sale.[住宅总可售单方成本(真实版)-动态版]) as [住宅总可售单方成本(真实版)-动态版],
--         [住宅总可售单方成本(账面版)-动态版],
--         [住宅已签约销净率(真实版）],
--         [住宅已签约销净率(账面版）],
--         isnull(lczy.[住宅累计销售金额], sale.[住宅累计销售金额]) as [住宅累计销售金额],
--         [住宅销售均价-立项版],
--         [商办销售均价-立项版],
--         [车位销售均价-立项版],
--         [待售货值],
--         [住宅待售均价],
--         [商办待售均价],
--         [车位待售均价],
--         [住宅截止本月已售均价-一盘一策版],
--         [总货值-一盘一策版],
--         [住宅总货值-一盘一策版],
--         [住宅销售均价-一盘一策版],
--         [办公总货值-一盘一策版],
--         [办公销售均价-一盘一策版],
--         [商业总货值-一盘一策版],
--         [商业销售均价-一盘一策版],
--         [商办总货值-一盘一策版],
--         [商办销售均价-一盘一策版],
--         [车位总货值-一盘一策版],
--         [车位销售均价-一盘一策版],
--         [商业截止本月已售均价],
--         [商业总货值金额],
--         [商业总可售面积],
--         [商业累计销售金额],
--         [办公截止本月已售均价],
--         [办公总货值金额],
--         [办公总可售面积],
--         [办公累计销售金额],
--         [车位去化率],
--         [顶底去化率],
--         [商业待售货值],
--         [商业待售均价],
--         [办公待售货值],
--         [办公待售均价],
--         [部分户型最小去化率],
--         [是否齐步走]
--     FROM zb_jyjhtjkb_SaleIncome sale
--     left join  data_tb_ylss_lczy lczy on  sale.projguid =lczy.项目GUID
--     WHERE DATEDIFF(DAY, [清洗日期], ${qxDate} ) = 0