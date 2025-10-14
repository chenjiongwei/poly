
use erp25
go
-- =============================================
-- 湾区公司楼栋资源情况底表F05603数据清洗脚本
-- 功能：生成湾区公司公司资源宽表data_wide_dws_s_WqBaseStatic_CompanyResource
-- 作者：chenjw
-- 创建时间：2025年
-- 最后修改：2025-10-13
-- =============================================

BEGIN
    -- =============================================
    -- 第一部分：基础数据准备
    -- =============================================
    
    -- 声明变量：湾区公司GUID
    DECLARE @var_buguid VARCHAR(MAX) = 'C69E89BB-A2DB-E511-80B8-E41F13C51836';

    -- 获取湾区公司下的所有项目（Level=2的项目）
    -- 用途：作为后续数据过滤的基础条件
    SELECT p.*,flg.项目股权比例,flg.城市
    INTO #p
    FROM mdm_Project p WITH(NOLOCK)
    left join  vmdm_projectFlagnew flg on p.projguid =flg.projguid
    WHERE 1 = 1
          AND p.DevelopmentCompanyGUID IN (
                                              SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                                          )
          AND p.Level = 2;    

    -- 获取湾区公司下的所有分期项目（Level=3的项目）
    -- 用途：作为楼栋数据关联的基础
    SELECT p.ProjGUID,
           p.ProjName,
           p.ParentProjGUID TopProjGuid
    INTO #p0
    FROM mdm_Project p WITH(NOLOCK)
    INNER JOIN #p p1 ON p.ParentProjGUID = p1.ProjGUID;


    -- 获取本年签约数据汇总
    -- 用途：计算各楼栋的本年签约面积和金额
    SELECT SaleBldGUID,
           SUM(ThisMonthSaleAreaQy) 本年签约面积,
           SUM(ThisMonthSaleMoneyQy) 本年签约金额
    INTO #bnqy
    FROM dbo.s_SaleValueBuildLayout WITH(NOLOCK)
    WHERE SaleValuePlanYear = YEAR(GETDATE())
    GROUP BY SaleBldGUID;

    -- 获取楼栋首推时间
    -- 用途：计算楼栋的首次推盘时间，用于后续首开分析
    SELECT r.BldGUID,
           MIN(o.QSDate) st
    INTO #st
    FROM dbo.s_Order o WITH(NOLOCK)
    INNER JOIN p_room r WITH(NOLOCK) ON o.RoomGUID = r.RoomGUID
    INNER JOIN #p0 p ON p.projguid = o.projguid
    WHERE o.Status = '激活'
          OR o.CloseReason = '转签约'
    GROUP BY r.BldGUID;

    -- =============================================
    -- 第二部分：税率计算
    -- =============================================
    
    -- 获取房间税率信息
    -- 业务说明：税率设置分为"整个项目"和"特定房间"两种范围
    -- 1. 整个项目税率：适用于项目下所有房间
    -- 2. 特定房间税率：仅适用于指定的房间
    -- 优先级：特定房间税率 > 整个项目税率
    SELECT DISTINCT
           vt.ProjGUID,
           VATRate,
           RoomGUID,
           r.bldguid
    INTO #vrt
    FROM s_VATSet vt WITH(NOLOCK)
    INNER JOIN p_room r WITH(NOLOCK) ON vt.ProjGUID = r.ProjGUID
    WHERE VATScope = '整个项目'
          AND AuditState = 1
          AND r.IsVirtualRoom = 0
          AND RoomGUID NOT IN ( 
              SELECT DISTINCT vtr.RoomGUID
              FROM s_VATSet vt WITH(NOLOCK)
              INNER JOIN s_VAT2RoomScope vtr WITH(NOLOCK) ON vt.VATGUID = vtr.VATGUID
              INNER JOIN p_room r WITH(NOLOCK) ON vtr.RoomGUID = r.RoomGUID
              WHERE VATScope = '特定房间'
                    AND AuditState = 1
                    AND r.IsVirtualRoom = 0
          )
    UNION ALL 
    -- 获取楼栋级别的整个项目税率
    SELECT DISTINCT vt.ProjGUID,
           VATRate,
           bldguid,
           r.bldguid
    FROM s_VATSet vt WITH(NOLOCK)
    INNER JOIN p_building r WITH(NOLOCK) ON vt.ProjGUID = r.ProjGUID
    WHERE VATScope = '整个项目'
          AND AuditState = 1
    UNION ALL
    -- 获取特定房间的税率
    SELECT DISTINCT
           vt.ProjGUID,
           vt.VATRate,
           vtr.RoomGUID,
           r.bldguid
    FROM s_VATSet vt WITH(NOLOCK)
    INNER JOIN s_VAT2RoomScope vtr WITH(NOLOCK) ON vt.VATGUID = vtr.VATGUID
    INNER JOIN p_room r WITH(NOLOCK) ON vtr.RoomGUID = r.RoomGUID
    WHERE VATScope = '特定房间'
          AND AuditState = 1
          AND r.IsVirtualRoom = 0;


    -- 去重楼栋税率
    -- 业务说明：一个楼栋可能有多个税率设置，取最高税率作为楼栋税率
    SELECT DISTINCT
           projguid,
           bldguid,
           VATRate
    INTO #t
    FROM #vrt;

    -- 获取楼栋税率（取最高税率）
    -- 业务说明：当楼栋有多个税率时，选择最高的税率
    SELECT projguid,
           bldguid,
           VATRate/100 as VATRate
    INTO #ld_rate
    FROM (
        SELECT projguid,
               bldguid,
               VATRate,
               ROW_NUMBER() OVER (PARTITION BY bldguid ORDER BY VATRate DESC) rownum
        FROM #t
    ) a
    WHERE rownum = 1;

    -- 获取项目税率（取最高税率）
    -- 业务说明：当项目有多个税率时，选择最高的税率
    SELECT projguid,
           VATRate/100 as VATRate
    INTO #proj_rate
    FROM (
        SELECT pj.ParentProjGUID projguid,
               VATRate,
               ROW_NUMBER() OVER (PARTITION BY pj.ParentProjGUID ORDER BY VATRate DESC) rownum
        FROM #t t 
        INNER JOIN mdm_project pj WITH(NOLOCK) ON t.projguid = pj.projguid
    ) a
    WHERE rownum = 1;

    -- =============================================
    -- 第三部分：产品楼栋基础信息获取
    -- =============================================
    
    -- 获取产品楼栋基础信息
    -- 业务说明：包含楼栋的基本属性、产品信息、工程信息等
    -- 新增字段：用地面积、可售面积、计容面积、自持面积等 edity by tangqn01 20250807
    SELECT ms.SaleBldGUID,
           gc.GCBldGUID,
           p.TopProjGuid,
           p.ProjName fq,
           ms.BldCode,
           gc.BldName gcBldName,
           ISNULL(ms.UpBuildArea, 0) + ISNULL(ms.DownBuildArea, 0) zjm,
           ms.UpBuildArea dsjm,
           ms.DownBuildArea dxjm,
           case when  pr.ProductType ='住宅' then '住宅'
                when pr.ProductType ='公寓' then '公寓'
                when pr.ProductType ='商业' then '商业'
                when pr.ProductType ='写字楼' then '写字楼'
                when pr.ProductType ='地下室/车库' then '地下室/车库'
                when pr.ProductType ='高级住宅' then '高级住宅'
                else '其他' end as 业态六分类,
           pr.ProductType,
           pr.ProductName,
           pr.BusinessType,
           pr.IsSale,
           pr.IsHold,
           pr.STANDARD,
           ms.UpNum,
           ms.DownNum,
           st.st,
           c.ztguid,
           c.是否停工,
           ms.HouseNum
    INTO #ms
    FROM dbo.mdm_SaleBuild ms WITH(NOLOCK)
    INNER JOIN mdm_Product pr WITH(NOLOCK) ON pr.ProductGUID = ms.ProductGUID
    INNER JOIN mdm_GCBuild gc WITH(NOLOCK) ON gc.GCBldGUID = ms.GCBldGUID
    INNER JOIN #p0 p ON p.ProjGUID = gc.ProjGUID
    LEFT JOIN #st st ON ISNULL(ms.ImportSaleBldGUID, ms.SaleBldGUID) = st.BldGUID
    LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b WITH(NOLOCK) ON ms.GCBldGUID = b.BuildingGUID
    LEFT JOIN MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport c WITH(NOLOCK) ON b.budguid = c.ztguid;      
        
 
    -- =============================================
    -- 第四部分：货值计算
    -- =============================================
    
    -- 获取楼栋货值数据
    -- 业务说明：从楼栋面积表获取销售相关的货值信息
    -- 包含：立项货值、定位货值、已售货值、待售货值等
    SELECT ld.projguid,
           ld.ProductType + '_' + ld.ProductName + '_' + ld.BusinessType + '_' + ld.Standard yt,
           p.projcode + '_' + ld.ProductType + '_' + ld.ProductName + '_' + ld.BusinessType + '_' + ld.Standard ytid,
           ld.ProductType,
           ld.SaleBldGUID,
           ld.YJzskgdate,
           ld.SJzskgdate,
           ld.YjDdysxxDate,
           ld.SjDdysxxDate,
           ld.YjYsblDate,
           ld.SjYsblDate,
           ld.YJjgbadate,
           ld.SJjgbadate,
           ld.JzjfYjdate,
           ld.JzjfSjdate,
           ld.SGZsjdate,
           ld.SGZyjdate,
           ld.LxPrice,
           ld.LxPrice / (1 + 0.09) LxPrice_bhs,
           ld.LxPrice * ld.zksmj lxHz,
           ld.DwPrice,
           ld.DwPrice / (1 + 0.09) DwPrice_bhs,
           ld.DwPrice * ld.zksmj dwHz,
           ld.zksts 总可售套数,
           ld.zksmj 总可售面积,
           ld.zhz 动态总货值,
           CASE WHEN ld.zksmj = 0 THEN 0 ELSE ld.zhz / ld.zksmj END 整盘均价,
           ld.ysmj * 1.0 已售面积,
           ld.ysje 已售货值,
           -- 已售货值不含税计算：优先使用系统设置的税率，否则使用默认9%税率
           CASE WHEN ISNULL(ldr.VATRate, ISNULL(pdr.VATRate, '')) <> '' 
                THEN ld.ysje / (1 + ISNULL(ldr.VATRate, ISNULL(pdr.VATRate, '')))
                ELSE ld.ysje / (1 + 0.09)
           END AS 已售货值不含税,
           ld.ysts 已售套数,
           CASE WHEN ld.ysmj = 0 THEN 0 ELSE ld.ysje / ld.ysmj END 已售均价,
           ld.zksts - ld.ysts 待售套数,
           ld.zksmj * 1.0 - ld.ysmj * 1.0 待售面积,
           ld.syhz 待售货值,
           -- 待售货值不含税计算：优先使用系统设置的税率，否则使用默认9%税率
           CASE WHEN ISNULL(ldr.VATRate, ISNULL(pdr.VATRate, '')) <> '' 
                THEN ld.syhz / (1 + ISNULL(ldr.VATRate, ISNULL(pdr.VATRate, '')))
                ELSE ld.syhz / (1 + 0.09)
           END AS 待售货值不含税, 
           ld.YcPrice 预测单价,
           ld.BeginYearSaleMj,
           ld.BeginYearSaleJe,
           ld.ThisYearSaleMjQY,
           ld.ThisYearSaleJeQY,
           CASE WHEN ld.ThisYearSaleMjQY = 0 THEN 0 ELSE ld.ThisYearSaleJeQY / ld.ThisYearSaleMjQY END 本年签约均价,
           ld.ThisMonthSaleMjQY,
           ld.ThisMonthSaleJeQY,
           CASE WHEN ld.ThisMonthSaleMjQY = 0 THEN 0 ELSE ld.ThisMonthSaleJeQY / ld.ThisMonthSaleMjQY END 本月签约均价,
           case when  sum( ld.ysmj * 1.0) over( PARTITION BY ld.projguid, ld.ProductType )  =0  then 0
              else sum( ld.ysje) over( PARTITION BY ld.projguid, ld.ProductType )/
             sum( ld.ysmj * 1.0 ) over( PARTITION BY ld.projguid, ld.ProductType ) end as 业态均价      -- 业态均价：同项目同产品类型的已售均价
    INTO #hz
    FROM dbo.p_lddbamj ld WITH(NOLOCK)
    INNER JOIN #p p ON p.ProjGUID = ld.ProjGUID
    LEFT JOIN #ld_rate ldr ON ldr.BldGUID = ld.SaleBldGUID
    LEFT JOIN #proj_rate pdr ON pdr.projguid = ld.projguid
    WHERE DATEDIFF(d, QXDate, GETDATE()) = 0;

    -- =============================================
    -- 第五部分：单方成本计算
    -- =============================================
    
    -- 获取业态单方成本数据
    -- 业务说明：从填报系统中获取各业态的成本单方数据
    -- 包含：营业成本、营销费用、管理费、股权溢价、税金等单方成本
    SELECT 
        项目guid,
        T.基础数据主键,
        -- 盈利规划主键优先级：系统自动匹对 > 手动匹对 > 基础数据主键
        CASE
            WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN
                T.盈利规划系统自动匹对主键
            ELSE CASE
                    WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                            T.盈利规划主键
                    ELSE T.基础数据主键
                END
        END 盈利规划主键,
        MAX(T.[营业成本单方(元/平方米)]) AS 营业成本单方,
        MAX(T.[营销费用单方(元/平方米)]) AS 营销费用单方,
        MAX(T.[综合管理费单方(元/平方米)]) AS 综合管理费单方,
        MAX(T.[股权溢价单方(元/平方米)]) AS 股权溢价单方,
        MAX(T.[税金及附加单方(元/平方米)]) AS 税金及附加单方,
        MAX(T.[除地价外直投单方(元/平方米)]) AS 除地价外直投单方,
        MAX(T.[土地款单方(元/平方米)]) AS 土地款单方,
        MAX(T.[资本化利息单方(元/平方米)]) AS 资本化利息单方,
        MAX(T.[开发间接费单方(元/平方米)]) AS 开发间接费单方
    INTO #key
    FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 T WITH(NOLOCK)
    INNER JOIN (
        -- 获取最新的填报历史记录
        SELECT ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM,
               FillHistoryGUID
        FROM dss.dbo.nmap_F_FillHistory a WITH(NOLOCK)
        WHERE EXISTS (
            -- 确保填报记录中有项目数据
            SELECT FillHistoryGUID,
                   SUM(CASE WHEN 项目guid IS NULL OR 项目guid = '' THEN 0 ELSE 1 END) AS num
            FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 b WITH(NOLOCK)
            WHERE a.FillHistoryGUID = b.FillHistoryGUID
            GROUP BY FillHistoryGUID
            HAVING SUM(CASE WHEN 项目guid IS NULL THEN 0 ELSE 1 END) > 0
        )
    ) V ON T.FillHistoryGUID = V.FillHistoryGUID AND V.NUM = 1
    WHERE ISNULL(T.项目guid, '') <> ''
    GROUP BY 项目guid,
             T.基础数据主键,
             CASE
                 WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN
                      T.盈利规划系统自动匹对主键
                 ELSE CASE
                          WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                               T.盈利规划主键
                          ELSE T.基础数据主键
                      END
             END;
    -- 计算总成本单方
    -- 业务说明：将各项成本单方汇总，并与盈利规划数据进行匹配
    -- 优先级：填报数据 > 盈利规划数据
    SELECT t.*, 
           营业成本单方 + 营销费用单方 + 综合管理费单方 + 股权溢价单方 + 税金及附加单方 AS 总成本不含税
    INTO #dfhz
    FROM (
        SELECT DISTINCT
               k.[项目guid],
               k.基础数据主键,
               ISNULL(k.盈利规划主键, ylgh.匹配主键) 盈利规划主键,
               ISNULL(ylgh.总可售面积, 0) AS 盈利规划总可售面积,
               -- 成本单方优先级：填报数据 > 盈利规划数据
               CASE WHEN ISNULL(k.营业成本单方, 0) = 0 THEN ISNULL(ylgh.盈利规划营业成本单方, 0)
                    ELSE ISNULL(k.营业成本单方, 0) END AS 营业成本单方,
               CASE WHEN ISNULL(k.土地款单方, 0) = 0 THEN ISNULL(ylgh.土地款_单方, 0)
                    ELSE k.土地款单方 END 土地款单方,
               CASE WHEN ISNULL(k.除地价外直投单方, 0) = 0 THEN ISNULL(ylgh.除地外直投_单方, 0)
                    ELSE k.除地价外直投单方 END AS 除地价外直投单方,
               CASE WHEN ISNULL(k.开发间接费单方, 0) = 0 THEN ISNULL(ylgh.开发间接费单方, 0)
                    ELSE k.开发间接费单方 END AS 开发间接费单方,
               CASE WHEN ISNULL(k.资本化利息单方, 0) = 0 THEN ISNULL(ylgh.资本化利息单方, 0)
                    ELSE k.资本化利息单方 END AS 资本化利息单方,
               CASE WHEN ISNULL(k.股权溢价单方, 0) = 0 THEN ISNULL(ylgh.股权溢价单方, 0)
                    ELSE k.股权溢价单方 END AS 股权溢价单方,
               CASE WHEN ISNULL(k.营销费用单方, 0) = 0 THEN ISNULL(ylgh.营销费用单方, 0)
                    ELSE k.营销费用单方 END AS 营销费用单方,
               CASE WHEN ISNULL(k.综合管理费单方, 0) = 0 THEN ISNULL(ylgh.管理费用单方, 0)
                    ELSE k.综合管理费单方 END AS 综合管理费单方,
               CASE WHEN ISNULL(k.税金及附加单方, 0) = 0 THEN ISNULL(ylgh.税金及附加单方, 0)
                    ELSE k.税金及附加单方 END AS 税金及附加单方,
               ylgh.经营成本单方
        FROM #key k
        LEFT JOIN dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh WITH(NOLOCK) 
            ON ylgh.匹配主键 = k.盈利规划主键 AND ylgh.[项目guid] = k.项目guid
    ) t;

    -- 去重处理：每个基础数据主键只保留一条记录
    SELECT *
    INTO #df
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY 基础数据主键 ORDER BY 盈利规划主键 DESC) rownum,
               *
        FROM #dfhz
    ) a
    WHERE a.rownum = 1;

    -- =============================================
    -- 第六部分：业态铺排数据
    -- =============================================
    
    -- 获取业态铺排数据（产品级别）
    -- 业务说明：获取各业态的近三月、近六月的签约情况和铺排价格
    SELECT id,
           项目guid,
           业态组合键,
           近三月签约金额均价不含税,
           近六月签约金额均价不含税,
           近三月签约金额不含税,
           近三月签约面积,
           近六月签约金额不含税,
           近六月签约面积,
           立项单价,
           定位单价,
           动态单价,
           累计签约金额均价不含税,
           铺排价格 / (1 + 0.09) AS 铺排价格不含税
    INTO #hlpp_product
    FROM s_product_salevalue WITH(NOLOCK)
    WHERE DATEDIFF(mm, 月份, GETDATE()) = 0;
    
    -- 获取楼栋铺排数据
    -- 业务说明：获取各楼栋的累计签约情况和铺排价格
    SELECT 项目guid,
           CONCAT(产品类型, '_', 产品名称, '_', 商品房, '_', 装修标准) 业态组合键,
           产品楼栋guid,
           累计签约不含税均价 累计签约均价不含税,
           铺排价格 / (1 + 0.09) AS 铺排价格不含税,
           均价计算方式 货量铺排均价计算方式
    INTO #hlpp_bld
    FROM s_bld_salevalue2 WITH(NOLOCK)
    WHERE DATEDIFF(mm, 铺排月份, GETDATE()) = 0;
        --均价获取
        --SELECT ld.产品楼栋guid,
        --       (CASE
        --            WHEN ISNULL(pro.近三月签约金额均价不含税, 0) <> 0 THEN
        --                 pro.近三月签约金额均价不含税
        --            ELSE CASE
        --                     WHEN ISNULL(pro.近六月签约金额均价不含税, 0) <> 0 THEN
        --                          pro.近六月签约金额均价不含税
        --                     ELSE CASE
        --                              WHEN ISNULL(ld.累计签约均价不含税, 0) <> 0 THEN
        --                                   ld.累计签约均价不含税
        --                              ELSE CASE
        --                                       WHEN ISNULL(ld.铺排价格不含税, 0) <> 0 THEN
        --                                            ld.铺排价格不含税
        --                                       ELSE CASE
        --                                                WHEN ISNULL(hz.LxPrice_bhs, 0) <> 0 THEN
        --                                                     hz.LxPrice
        --                                                ELSE CASE
        --                                                         WHEN ISNULL(hz.DwPrice_bhs, 0) <> 0 THEN
        --                                                              hz.DwPrice
        --                                                     END
        --                                            END
        --                                   END
        --                          END
        --                 END
        --        END
        --       ) 未售货值均价
        --INTO #price
        --FROM #hlpp_bld ld
        --     LEFT JOIN #hlpp_product pro ON ld.项目guid = pro.项目guid
        --                                    AND ld.业态组合键 = pro.业态组合键
        --     LEFT JOIN #hz hz ON hz.SaleBldGUID = ld.产品楼栋guid;


    -- =============================================
    -- 第七部分：基础数据汇总
    -- =============================================
    
    -- 汇总基础数据
    -- 业务说明：将货值、单方成本、铺排数据等进行汇总
    SELECT hz.SaleBldGUID,
           hz.projguid,
           df.盈利规划主键,
           df.营业成本单方,
           df.土地款单方,
           df.除地价外直投单方,
           df.资本化利息单方,
           df.开发间接费单方,
           df.营销费用单方,
           df.综合管理费单方,
           df.税金及附加单方,
           df.股权溢价单方,
           df.总成本不含税,
           df.经营成本单方,
           -- 已售对应总成本：根据产品类型选择面积或套数
           (CASE WHEN hz.ProductType = '地下室/车库' THEN 已售套数 ELSE 已售面积 END) * df.总成本不含税 AS 已售对应总成本,
           hz.已售货值不含税,
           -- 未售对应总成本：根据产品类型选择面积或套数
           (CASE WHEN hz.ProductType = '地下室/车库' THEN 待售套数 ELSE 待售面积 END) * df.总成本不含税 AS 未售对应总成本,
           pro.近三月签约金额均价不含税,
           pro.近三月签约金额不含税,
           pro.近三月签约面积,
           pro.近六月签约金额均价不含税,
           pro.近六月签约金额不含税,
           pro.近六月签约面积,
           hz.LxPrice_bhs 立项单价,
           hz.DwPrice_bhs 定位单价,
           ld.累计签约均价不含税 已售均价不含税,
           ld.铺排价格不含税 货值铺排均价不含税,
           ld.货量铺排均价计算方式,
           hz.待售货值不含税 AS 未售货值不含税,
           -- 已售面积：根据产品类型选择面积或套数
           CASE WHEN hz.ProductType = '地下室/车库' THEN 已售套数 ELSE 已售面积 END AS 已售面积,
           -- 待售面积：根据产品类型选择面积或套数
           CASE WHEN hz.ProductType = '地下室/车库' THEN 待售套数 ELSE 待售面积 END AS 待售面积
    INTO #base
    FROM #hz hz
    LEFT JOIN #df df ON hz.ytid = df.基础数据主键
    LEFT JOIN #hlpp_bld ld ON ld.项目guid = hz.projguid
                            AND hz.SaleBldGUID = ld.产品楼栋guid
                            AND ld.业态组合键 = hz.yt
    LEFT JOIN #hlpp_product pro ON hz.projguid = pro.项目guid
                                AND hz.yt = pro.业态组合键; 

    -- =============================================
    -- 第八部分：利润计算
    -- =============================================
    
    -- 计算项目净利润
    -- 业务说明：计算项目已售和未售的税前利润
    -- 利润 = 货值 - 各项成本（营业成本、营销费用、管理费、税金等）
    SELECT c.ProjGUID,
           SUM(CONVERT(DECIMAL(36, 8),
               ((ISNULL(c.已售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.已售面积, 0))
                - ISNULL(c.营销费用单方, 0) * ISNULL(c.已售面积, 0) 
                - ISNULL(c.综合管理费单方, 0) * ISNULL(c.已售面积, 0)
                - ISNULL(c.税金及附加单方, 0) * ISNULL(c.已售面积, 0))
               )) AS 项目已售税前利润签约,
           SUM(CONVERT(DECIMAL(36, 8),
               ((ISNULL(c.未售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.待售面积, 0))
                - ISNULL(c.营销费用单方, 0) * ISNULL(c.待售面积, 0) 
                - ISNULL(c.综合管理费单方, 0) * ISNULL(c.待售面积, 0)
                - ISNULL(c.税金及附加单方, 0) * ISNULL(c.待售面积, 0))
               )) AS 项目未售税前利润签约
    INTO #xm
    FROM #base c
    GROUP BY c.ProjGUID;


    -- 计算楼栋净利润
    -- 业务说明：计算楼栋已售和未售的净利润
    -- 净利润 = 税前利润 - 所得税（25%）
    SELECT c.SaleBldGUID,
           -- 未售净利润计算
           CONVERT(DECIMAL(36, 8),
               ((ISNULL(c.未售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.待售面积, 0) 
                 - ISNULL(c.股权溢价单方, 0) * ISNULL(c.待售面积, 0))
                - ISNULL(c.营销费用单方, 0) * ISNULL(c.待售面积, 0) 
                - ISNULL(c.综合管理费单方, 0) * ISNULL(c.待售面积, 0) 
                - ISNULL(c.税金及附加单方, 0) * ISNULL(c.待售面积, 0))
               )
           - CASE WHEN ISNULL(x.项目未售税前利润签约, 0) + ISNULL(x.项目已售税前利润签约, 0) > 0 THEN
                 CONVERT(DECIMAL(36, 8),
                     ((ISNULL(c.未售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.待售面积, 0))
                      - ISNULL(c.营销费用单方, 0) * ISNULL(c.待售面积, 0) 
                      - ISNULL(c.综合管理费单方, 0) * ISNULL(c.待售面积, 0) 
                      - ISNULL(c.税金及附加单方, 0) * ISNULL(c.待售面积, 0)) * 0.25)
             ELSE 0.0 END AS 未售净利润签约,
           -- 已售净利润计算
           CONVERT(DECIMAL(36, 8),
               ((ISNULL(c.已售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.已售面积, 0) 
                 - ISNULL(c.股权溢价单方, 0) * ISNULL(c.已售面积, 0))
                - ISNULL(c.营销费用单方, 0) * ISNULL(c.已售面积, 0) 
                - ISNULL(c.综合管理费单方, 0) * ISNULL(c.已售面积, 0) 
                - ISNULL(c.税金及附加单方, 0) * ISNULL(c.已售面积, 0))
               )
           - CASE WHEN ISNULL(x.项目未售税前利润签约, 0) + ISNULL(x.项目已售税前利润签约, 0) > 0 THEN
                 CONVERT(DECIMAL(36, 8),
                     ((ISNULL(c.已售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.已售面积, 0))
                      - ISNULL(c.营销费用单方, 0) * ISNULL(c.已售面积, 0) 
                      - ISNULL(c.综合管理费单方, 0) * ISNULL(c.已售面积, 0) 
                      - ISNULL(c.税金及附加单方, 0) * ISNULL(c.已售面积, 0)) * 0.25)
             ELSE 0.0 END AS 已售净利润签约
    INTO #jlr
    FROM #base c
    LEFT JOIN #xm x ON c.projguid = x.projguid;

    -- =============================================
    -- 第九部分：节点信息获取
    -- =============================================
    
    -- 获取工程节点信息
    -- 业务说明：获取楼栋的预售条件、验收标准、交付标准等节点信息
    SELECT p.TopProjGuid,
           zt.PreSaleProgress 达到预售形象的条件,
           zt.CheckStandard 验收标准,
           zt.DeliverStandard 交付标准,
           jcjh.BuildingGUID GCBldGUID
    INTO #jd
    FROM MyCost_Erp352.dbo.p_HkbBiddingBuildingWork zt WITH(NOLOCK)
    INNER JOIN MyCost_Erp352.dbo.p_BiddingSection bd WITH(NOLOCK) ON bd.BidGUID = zt.BidGUID
    INNER JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork jcjh WITH(NOLOCK) ON jcjh.BudGUID = zt.BuildGUID
    INNER JOIN #p0 p ON p.ProjGUID = bd.ProjGuid;

    -- =============================================
    -- 第十部分：首开数据获取
    -- =============================================
    
    -- 获取认购的最早录入时间
    -- 业务说明：计算楼栋首次认购的时间，用于首开分析
    SELECT r.BldGUID,
           MIN(o.QSDate) st
    INTO #rg_st
    FROM dbo.s_Order o WITH(NOLOCK)
    INNER JOIN p_room r WITH(NOLOCK) ON o.RoomGUID = r.RoomGUID
    INNER JOIN #ms ms ON ms.SaleBldGUID = r.bldguid 
    WHERE o.Status = '激活'
          OR o.CloseReason = '转签约'
    GROUP BY r.BldGUID;

    -- 获取签约的最早录入时间
    -- 业务说明：计算楼栋首次签约的时间，用于首开分析
    SELECT r.BldGUID,
           MIN(sc.QSDate) st 
    INTO #qy_st
    FROM dbo.s_contract sc WITH(NOLOCK)
    INNER JOIN p_room r WITH(NOLOCK) ON sc.RoomGUID = r.RoomGUID
    INNER JOIN #ms ms ON ms.SaleBldGUID = r.bldguid 
    LEFT JOIN #rg_st rg ON r.bldguid = rg.bldguid 
    WHERE sc.Status = '激活' 
          AND rg.bldguid IS NULL 
    GROUP BY r.BldGUID;

    -- 获取合作业绩的最早录入时间
    -- 业务说明：计算楼栋首次合作业绩的时间，用于首开分析
    SELECT b.bldguid,
           MIN(CONVERT(VARCHAR(100), CAST(a.DateYear + '-' + a.DateMonth + '-01' AS DATETIME), 23)) AS st 
    INTO #hz_st
    FROM s_YJRLProducteDetail a WITH(NOLOCK)
    INNER JOIN s_YJRLBuildingDescript b WITH(NOLOCK) ON b.ProducteDetailGUID = a.ProducteDetailGUID
    INNER JOIN #ms ms ON ms.SaleBldGUID = b.bldguid 
    WHERE a.Shenhe = '审核' 
          AND b.Amount > 0
    GROUP BY b.bldguid;

    -- 获取特殊业绩的最早录入时间
    -- 业务说明：计算楼栋首次特殊业绩的时间，用于首开分析
    SELECT BldGUID, 
           MIN(StatisticalDate) AS st
    INTO #ts_st
    FROM (
        -- 楼栋级别的特殊业绩
        SELECT b.BldGUID AS BldGUID, 
               a.RdDate AS StatisticalDate 
        FROM S_PerformanceAppraisal a WITH(NOLOCK)
        INNER JOIN s_TsyjType c WITH(NOLOCK) ON a.YjType = c.TsyjTypeName
        INNER JOIN S_PerformanceAppraisalBuildings b WITH(NOLOCK) ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID 
        INNER JOIN #ms ms ON ms.SaleBldGUID = b.bldguid 
        WHERE ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WITH(NOLOCK) WHERE IsRelatedBuildingsRoom = 0 OR IsCalcYSHL = 0)
              AND a.AuditStatus = '已审核' 
              AND b.BldGUID NOT IN (  
                  SELECT r.BldGUID
                  FROM S_PerformanceAppraisalRoom c WITH(NOLOCK)
                  INNER JOIN S_PerformanceAppraisal s WITH(NOLOCK) ON c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
                  INNER JOIN dbo.p_room r WITH(NOLOCK) ON c.RoomGUID = r.RoomGUID
                  WHERE s.AuditStatus = '已审核' 
              )
        UNION ALL
        -- 房间级别的特殊业绩
        SELECT ISNULL(rm.BldGUID, r.ProductBldGUID) AS BldGUID,
               a.RdDate AS StatisticalDate 
        FROM S_PerformanceAppraisal a WITH(NOLOCK)
        INNER JOIN s_TsyjType b WITH(NOLOCK) ON a.YjType = b.TsyjTypeName
        INNER JOIN S_PerformanceAppraisalRoom c WITH(NOLOCK) ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
        LEFT JOIN dbo.p_room rm WITH(NOLOCK) ON rm.RoomGUID = c.RoomGUID
        INNER JOIN #ms ms ON ms.SaleBldGUID = rm.bldguid 
        -- 存在允许关联房间的情况
        LEFT JOIN (SELECT roomguid, ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom WITH(NOLOCK) GROUP BY roomguid, ProductBldGUID) r 
            ON c.RoomGUID = r.RoomGUID
        WHERE ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WITH(NOLOCK) WHERE IsRelatedBuildingsRoom = 0 OR IsCalcYSHL = 0)
              AND a.AuditStatus = '已审核'
    ) appraisa
    GROUP BY BldGUID;

 
    -- 判断楼栋的首开时间
    -- 业务说明：综合认购、签约、合作业绩、特殊业绩的最早时间作为楼栋首开时间
    SELECT t.bldguid, 
           MIN(st) AS st 
    INTO #bld_st
    FROM (
        SELECT bldguid, st FROM #rg_st
        UNION 
        SELECT bldguid, st FROM #qy_st
        UNION 
        SELECT bldguid, st FROM #hz_st
        UNION 
        SELECT bldguid, st FROM #ts_st
    ) t
    GROUP BY t.bldguid;

    -- 判断项目层级的楼栋首开
    -- 业务说明：计算项目下所有楼栋的最早首开时间
    SELECT pj.parentprojguid AS projguid,
           MIN(st.st) AS st 
    INTO #proj_st 
    FROM mdm_salebuild sb WITH(NOLOCK)
    INNER JOIN mdm_gcbuild gc WITH(NOLOCK) ON sb.GCBldGUID = gc.GCBldGUID
    INNER JOIN mdm_project pj WITH(NOLOCK) ON pj.projguid = gc.projguid
    LEFT JOIN #bld_st st ON sb.SaleBldGUID = st.bldguid
    GROUP BY pj.parentprojguid;

    -- 获取首开楼栋的范围
    -- 业务说明：找出与项目首开时间相同的楼栋
    SELECT bld.bldguid,
           proj.st 
    INTO #bld_lst
    FROM #bld_st bld 
    INNER JOIN mdm_salebuild sb WITH(NOLOCK) ON sb.SaleBldGUID = bld.BldGUID
    INNER JOIN mdm_gcbuild gc WITH(NOLOCK) ON sb.GCBldGUID = gc.GCBldGUID
    INNER JOIN mdm_project pj WITH(NOLOCK) ON pj.projguid = gc.projguid
    INNER JOIN #proj_st proj ON proj.projguid = pj.parentprojguid
    WHERE DATEDIFF(dd, proj.st, bld.st) = 0;

 
    -- 获取首开楼栋的销售情况
    -- 业务说明：计算首开楼栋在首开30天内的销售情况（认购、签约、合作业绩、特殊业绩）
    SELECT t.bldguid,
           t.st,
           SUM(ISNULL(首开30天签约套数, 0)) AS 首开30天签约套数,
           SUM(ISNULL(首开30天签约面积, 0)) AS 首开30天签约面积,
           SUM(ISNULL(首开30天签约金额, 0)) AS 首开30天签约金额,
           SUM(ISNULL(首开30天认购套数, 0)) AS 首开30天认购套数,
           SUM(ISNULL(首开30天认购面积, 0)) AS 首开30天认购面积,
           SUM(ISNULL(首开30天认购金额, 0)) AS 首开30天认购金额
    INTO #ld_st_sale
    FROM (
        -- 认购数据
        SELECT ld.bldguid, 
               ld.st,
               0 首开30天签约套数,
               0 首开30天签约面积,
               0 首开30天签约金额,
               COUNT(1) 首开30天认购套数,
               SUM(r.bldarea) 首开30天认购面积,
               SUM(o.jytotal) 首开30天认购金额 
        FROM #bld_lst ld
        INNER JOIN p_room r WITH(NOLOCK) ON ld.bldguid = r.bldguid
        LEFT JOIN dbo.s_Order o WITH(NOLOCK) ON r.roomguid = o.roomguid 
        WHERE (o.Status = '激活' OR o.CloseReason = '转签约') 
              AND DATEDIFF(dd, ld.st, o.qsdate) BETWEEN 0 AND 30
        GROUP BY ld.bldguid, ld.st
        UNION ALL 
        -- 签约数据
        SELECT ld.bldguid,
               ld.st,
               COUNT(1) 首开30天签约套数,
               SUM(r.bldarea) 首开30天签约面积,
               SUM(sc.jytotal) 首开30天签约金额,
               0 首开30天认购套数,
               0 首开30天认购面积,
               0 首开30天认购金额 
        FROM #bld_lst ld
        INNER JOIN p_room r WITH(NOLOCK) ON ld.bldguid = r.bldguid
        LEFT JOIN dbo.s_contract sc WITH(NOLOCK) ON r.roomguid = sc.roomguid 
        WHERE sc.Status = '激活' 
              AND DATEDIFF(dd, ld.st, sc.qsdate) BETWEEN 0 AND 30
        GROUP BY ld.bldguid, ld.st
        UNION ALL 
        -- 合作业绩数据
        SELECT ld.bldguid,
               ld.st,
               SUM(b.Taoshu) 首开30天签约套数,
               SUM(b.Area) 首开30天签约面积,
               SUM(b.amount * 10000.0) 首开30天签约金额,
               SUM(b.Taoshu) 首开30天认购套数,
               SUM(b.Area) 首开30天认购面积,
               SUM(b.amount * 10000.0) 首开30天认购金额
        FROM #bld_lst ld
        INNER JOIN s_YJRLBuildingDescript b WITH(NOLOCK) ON ld.bldguid = b.bldguid
        INNER JOIN s_YJRLProducteDetail a WITH(NOLOCK) ON b.ProducteDetailGUID = a.ProducteDetailGUID
        WHERE a.Shenhe = '审核' 
              AND DATEDIFF(dd, ld.st, CONVERT(VARCHAR(100), CAST(a.DateYear + '-' + a.DateMonth + '-01' AS DATETIME), 23)) BETWEEN 0 AND 30
        GROUP BY ld.bldguid, ld.st
        UNION ALL 
        -- 特殊业绩数据（楼栋级别）
        SELECT ld.bldguid,
               ld.st,
               SUM(b.AffirmationNumber) 首开30天签约套数,
               SUM(b.IdentifiedArea) 首开30天签约面积,
               SUM(b.AmountDetermined * 10000.0) 首开30天签约金额,
               SUM(b.AffirmationNumber) 首开30天认购套数,
               SUM(b.IdentifiedArea) 首开30天认购面积,
               SUM(b.AmountDetermined * 10000.0) 首开30天认购金额
        FROM #bld_lst ld
        INNER JOIN S_PerformanceAppraisalBuildings b WITH(NOLOCK) ON ld.bldguid = b.bldguid
        INNER JOIN S_PerformanceAppraisal a WITH(NOLOCK) ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID 
        INNER JOIN s_TsyjType c WITH(NOLOCK) ON a.YjType = c.TsyjTypeName
        WHERE ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WITH(NOLOCK) WHERE IsRelatedBuildingsRoom = 0 OR IsCalcYSHL = 0)
              AND a.AuditStatus = '已审核' 
              AND b.BldGUID NOT IN (  
                  SELECT r.BldGUID
                  FROM S_PerformanceAppraisalRoom c WITH(NOLOCK)
                  INNER JOIN S_PerformanceAppraisal s WITH(NOLOCK) ON c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
                  INNER JOIN dbo.p_room r WITH(NOLOCK) ON c.RoomGUID = r.RoomGUID
                  WHERE s.AuditStatus = '已审核' 
              )
              AND DATEDIFF(dd, ld.st, a.RdDate) BETWEEN 0 AND 30
        GROUP BY ld.bldguid, ld.st
        UNION ALL
        -- 特殊业绩数据（房间级别）
        SELECT ld.bldguid,
               ld.st,
               SUM(c.AffirmationNumber) 首开30天签约套数,
               SUM(c.IdentifiedArea) 首开30天签约面积,
               SUM(c.AmountDetermined * 10000.0) 首开30天签约金额,
               SUM(c.AffirmationNumber) 首开30天认购套数,
               SUM(c.IdentifiedArea) 首开30天认购面积,
               SUM(c.AmountDetermined * 10000.0) 首开30天认购金额
        FROM #bld_lst ld
        INNER JOIN dbo.p_room rm WITH(NOLOCK) ON ld.bldguid = rm.bldguid
        INNER JOIN S_PerformanceAppraisalRoom c WITH(NOLOCK) ON rm.RoomGUID = c.RoomGUID
        INNER JOIN S_PerformanceAppraisal a WITH(NOLOCK) ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
        INNER JOIN s_TsyjType b WITH(NOLOCK) ON a.YjType = b.TsyjTypeName
        -- 存在允许关联房间的情况
        LEFT JOIN (SELECT roomguid, ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom WITH(NOLOCK) GROUP BY roomguid, ProductBldGUID) r 
            ON c.RoomGUID = r.RoomGUID
        WHERE ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WITH(NOLOCK) WHERE IsRelatedBuildingsRoom = 0 OR IsCalcYSHL = 0)
              AND a.AuditStatus = '已审核'	  
              AND DATEDIFF(dd, ld.st, a.RdDate) BETWEEN 0 AND 30
        GROUP BY ld.bldguid, ld.st
    ) T
    GROUP BY t.bldguid, t.st;
		
    -- =============================================
    -- 第十一部分：2024年签约数据
    -- =============================================
    
    -- 获取2024年签约数据
    -- 业务说明：统计2024年的签约情况，用于年度对比分析
    SELECT c.TradeGUID
    INTO #con2024
    FROM s_contract c WITH(NOLOCK)
    WHERE YEAR(c.QSDate) = 2024
          AND c.Status = '激活';

    -- 获取2024年签约的补差费用
    -- 业务说明：计算签约中的补差费用，用于准确计算签约金额
    SELECT v.TradeGUID,
           SUM(CASE WHEN ItemName LIKE '%补差%' THEN Amount ELSE 0 END) bck
    INTO #feebck
    FROM s_Fee s WITH(NOLOCK)
    INNER JOIN #con2024 v ON s.TradeGUID = v.TradeGUID
    WHERE s.ItemType = '非贷款类房款'
    GROUP BY v.TradeGUID;
    
    -- 汇总2024年签约数据
    -- 业务说明：按楼栋汇总2024年的签约套数、面积、金额
    SELECT r.BldGUID,
           COUNT(*) ts,
           SUM(a.bldarea) / 10000 bldarea,
           SUM(a.jytotal + ISNULL(c.bck, 0)) / 10000 total
    INTO #con
    FROM s_contract a WITH(NOLOCK)
    LEFT JOIN p_room r WITH(NOLOCK) ON a.RoomGUID = r.RoomGUID
    INNER JOIN #con2024 b ON a.TradeGUID = b.TradeGUID
    LEFT JOIN #feebck c ON a.TradeGUID = c.TradeGUID
    WHERE a.Status = '激活'
    GROUP BY r.BldGUID;
    -- =============================================
    -- 第十二部分：产值分摊计算
    -- =============================================
    
    /*
    产值口径调整说明 (20250609 tangqn01)：
    
    已竣备项目产值取值规则：
    1. 总产值：
       - 回顾人员为明源软件或未回顾项目：取【动态成本金额（不含非现金）】
       - 当【动态成本金额（不含非现金）】小于【合同现场累计产值】时，取【合同现场累计产值】
    
    2. 已发生产值：
       - 回顾人员为明源软件或未回顾项目：取【合同现场累计产值】
       - 回顾人员不为明源软件：取回顾已发生产值
    
    3. 累计应付：
       - 回顾人员为明源软件或未回顾项目：取【合同-累计付款申请】
       - 回顾人员不为明源软件：取成本月度回顾-项目盘点累计应付款
    
    产值分摊至工程楼栋规则：
    1. 识别工程楼栋是否存在地上建筑面积、地下建筑面积
    2. 存在地上建筑面积则按照地上建面分摊
    3. 存在地下建筑面积则按照地下建筑面积分摊
    4. 同时存在地上及地下面积，则按照总建筑面积分摊
    
    工程楼栋分摊规则：
    1. 将工程楼栋的总产值根据土建的比例拆分为土建类和非土建类
    2. 土建类产值按产品楼栋的总建面分摊
    3. 非土建类产值按产品楼栋的地上建筑面积分摊
    
    拆分比例：土建部分工程费占除地价外直投目标成本占比（最新版目标成本）
    备注：除地价外直投 = 全科目 - 土地款 - 营销费 - 管理费 - 财务费
    */
    
    -- 获取工程楼栋建筑面积分摊比例
    -- 业务说明：计算工程楼栋在分期中的建筑面积占比
    SELECT gc_zjm.projguid,
           gc_zjm.GCBldGUID,
           gc_zjm.zjm,
           CASE WHEN stage_zjm.total_zjm = 0 THEN 0 
                ELSE gc_zjm.zjm * 1.0 / stage_zjm.total_zjm END AS gczjm_ratio
    INTO #gcbld_rate
    FROM (
        SELECT gc.projguid,
               gc.GCBldGUID,
               ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0) AS zjm
        FROM mdm_GCBuild gc WITH(NOLOCK)
    ) gc_zjm
    INNER JOIN (
        SELECT projguid,
               SUM(ISNULL(UpBuildArea, 0) + ISNULL(DownBuildArea, 0)) AS total_zjm
        FROM mdm_GCBuild WITH(NOLOCK)
        GROUP BY projguid
    ) stage_zjm ON gc_zjm.projguid = stage_zjm.projguid;

    -- 获取目标成本的土建类占比
    -- 业务说明：计算土建部分工程费占除地价外直投目标成本的占比
    SELECT *
    INTO #tj_Rate
    FROM (
        SELECT ex.buguid,
               ex.projguid,
               ex.targetcost,
               ex.tj_targetcost,
               CASE WHEN ex.targetcost = 0 THEN 0 ELSE ex.tj_targetcost / ex.targetcost END AS tjRate,
               ex.dtcostNotFxj,
               ex.targetstage2projectguid,
               trg2p.TargetStageVersion,
               trg2p.approvedate,
               -- 按审核日期倒序排序，取最新版本
               ROW_NUMBER() OVER (PARTITION BY ex.projguid ORDER BY trg2p.approvedate DESC) AS rn
        FROM (
            -- 汇总执行版目标成本
            SELECT cost.buguid,
                   trg2cost.ProjGUID,
                   trg2cost.targetstage2projectguid,
                   SUM(CASE WHEN cost.costcode LIKE '5001.03.01%' THEN cost.targetcost ELSE 0 END) AS tj_targetcost, -- 土建部分工程费
                   SUM(cost.targetcost) AS targetcost, -- 目标成本
                   SUM(ISNULL(cost.YfsCost, 0) + ISNULL(cost.DfsCost, 0) - ISNULL(cost.FxjCost, 0)) AS dtcostNotFxj -- 动态成本_含税_不含非现金
            FROM MyCost_Erp352.dbo.cb_cost cost WITH(NOLOCK)
            INNER JOIN MyCost_Erp352.dbo.cb_TargetStage2Cost trg2cost WITH(NOLOCK)
                ON trg2cost.costguid = cost.costguid 
                AND trg2cost.ProjCode = cost.ProjectCode
            WHERE cost.costcode NOT LIKE '5001.01.%'  -- 排除土地款
                  AND cost.costcode NOT LIKE '5001.09.%'  -- 排除营销费
                  AND cost.costcode NOT LIKE '5001.10.%'  -- 排除管理费
                  AND cost.costcode NOT LIKE '5001.11%'   -- 排除财务费
                  AND cost.ifendcost = 1
            GROUP BY cost.buguid, trg2cost.projguid, trg2cost.targetstage2projectguid
        ) ex
        INNER JOIN MyCost_Erp352.dbo.cb_TargetCostRevise_KH trg2p WITH(NOLOCK) ON trg2p.projguid = ex.projguid 
    ) t 
    WHERE t.rn = 1;
        
    -- 获取产品楼栋的地上分摊比例和建筑面积分摊比例
    -- 业务说明：计算产品楼栋在工程楼栋中的建筑面积和地上建筑面积占比
    SELECT cp_zjm.GCBldGUID,
           cp_zjm.SaleBldGUID,
           cp_zjm.zjm,
           CASE WHEN stage_zjm.total_zjm = 0 THEN 0 
                ELSE cp_zjm.zjm * 1.0 / stage_zjm.total_zjm END AS zjm_ratio,
           CASE WHEN stage_zjm.UpBuildArea = 0 THEN 0 
                ELSE cp_zjm.UpBuildArea * 1.0 / stage_zjm.UpBuildArea END AS UpBuildArea_rate
    INTO #cpbld_rate
    FROM (
        SELECT cp.GCBldGUID,
               cp.SaleBldGUID,
               ISNULL(cp.UpBuildArea, 0) AS UpBuildArea,
               ISNULL(cp.UpBuildArea, 0) + ISNULL(cp.DownBuildArea, 0) AS zjm
        FROM mdm_salebuild cp WITH(NOLOCK)
    ) cp_zjm
    INNER JOIN (
        SELECT cp.GCBldGUID,
               SUM(ISNULL(cp.UpBuildArea, 0)) AS UpBuildArea,
               SUM(ISNULL(cp.UpBuildArea, 0) + ISNULL(cp.DownBuildArea, 0)) AS total_zjm
        FROM mdm_salebuild cp WITH(NOLOCK)
        GROUP BY GCBldGUID
    ) stage_zjm ON cp_zjm.GCBldGUID = stage_zjm.GCBldGUID;

    -- 获取项目已审核的最晚回顾时间记录
    -- 业务说明：获取项目最新的产值回顾记录，用于判断产值数据来源
    SELECT t.*
    INTO #vor
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY projguid ORDER BY reviewdate DESC) AS rn,
               *
        FROM MyCost_Erp352.dbo.cb_outputvaluemonthreview WITH(NOLOCK)
        WHERE ApproveState IN ('已审核', '审核中')
    ) t
    WHERE t.rn = 1;

    -- 获取执行版目标成本（除地价外直投不含非现金）
    -- 业务说明：获取项目最新的目标成本数据，用于产值计算
    SELECT * 
    INTO #hygh_new
    FROM (
        SELECT ex.buguid,  
               ex.projguid,  
               ex.targetcost,  
               ex.dtcostNotFxj,  
               ex.targetstage2projectguid,  
               trg2p.TargetStageVersion,  
               trg2p.approvedate,  
               -- 按审核日期倒序排序，取最新版本
               ROW_NUMBER() OVER (PARTITION BY ex.projguid ORDER BY trg2p.approvedate DESC) AS rn    
        FROM (  
            -- 汇总执行版目标成本  
            SELECT cost.buguid,  
                   trg2cost.ProjGUID,  
                   trg2cost.targetstage2projectguid,  
                   SUM(cost.targetcost) AS targetcost,  
                   SUM(ISNULL(cost.YfsCost, 0) + ISNULL(cost.DfsCost, 0) - ISNULL(cost.FxjCost, 0)) AS dtcostNotFxj -- 动态成本_含税_不含非现金  
            FROM MyCost_Erp352.dbo.cb_cost cost WITH(NOLOCK)  
            LEFT JOIN MyCost_Erp352.dbo.cb_TargetStage2Cost trg2cost WITH(NOLOCK)  
                ON trg2cost.costguid = cost.costguid   
                AND trg2cost.ProjCode = cost.ProjectCode  
            WHERE cost.costcode NOT LIKE '5001.01.%'   -- 排除土地款
                  AND cost.costcode NOT LIKE '5001.09.%'  -- 排除营销费
                  AND cost.costcode NOT LIKE '5001.10.%'   -- 排除管理费
                  AND cost.costcode NOT LIKE '5001.11%'    -- 排除财务费
                  AND cost.ifendcost = 1  
            GROUP BY cost.buguid, trg2cost.projguid, trg2cost.targetstage2projectguid  
        ) ex  
        INNER JOIN MyCost_Erp352.dbo.cb_TargetCostRevise_KH trg2p WITH(NOLOCK) 
            ON trg2p.projguid = ex.projguid   
        INNER JOIN #p0 p ON p.projguid = ex.projguid       
        WHERE 1 = 1 
    ) t 
    WHERE t.rn = 1;

    -- 新增合同按分期分摊比例
    -- 业务说明：计算合同在不同分期中的分摊比例
    SELECT t.ProjGUID,
           t.ContractGUID,
           t.UsedAmount / SUM(t.UsedAmount) OVER (PARTITION BY t.ContractGUID) AS Rate
    INTO #htrate
    FROM (
        SELECT p.ProjGUID,
               c.ContractGUID,
               SUM(b.UsedAmount) AS UsedAmount
        FROM MyCost_Erp352.dbo.cb_BudgetUse a WITH(NOLOCK)
        INNER JOIN MyCost_Erp352.dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = a.BudgetGUID 
        INNER JOIN MyCost_Erp352.dbo.cb_Contract c WITH(NOLOCK) ON c.ContractGUID = a.RefGUID
        INNER JOIN MyCost_Erp352.dbo.p_Project p WITH(NOLOCK) ON a.ProjectCode = p.ProjCode
        WHERE a.IsApprove = 1  -- 审核中或已审核
              AND c.IfDdhs = 1  -- 是否单独核算    
              AND c.approvestate = '已审核'
        GROUP BY p.ProjGUID, c.ContractGUID
    ) t	
    WHERE t.UsedAmount > 0
    UNION ALL 
    -- 处理没有预算使用的合同，按项目数量平均分摊
    SELECT t.ProjGUID,
           t.ContractGUID,            
           1.0 / COUNT(1) OVER (PARTITION BY t.ContractGUID) AS Rate
    FROM (
        SELECT c.ContractGUID,
               p.ProjGUID,
               AllItem
        FROM MyCost_Erp352.dbo.cb_Contract c WITH(NOLOCK)
        LEFT JOIN MyCost_Erp352.dbo.cb_BudgetUse a WITH(NOLOCK) ON c.ContractGUID = a.RefGUID
        CROSS APPLY MyCost_Erp352.dbo.fn_Split(c.ProjectCodeList, ';')
        LEFT JOIN MyCost_Erp352.dbo.p_Project p WITH(NOLOCK) ON p.ProjCode = AllItem
        WHERE c.IfDdhs = 1
              AND c.approvestate = '已审核' 
              AND a.BudgetGUID IS NULL
        GROUP BY c.ContractGUID, p.ProjGUID, AllItem
    ) t;
	
	    -- create index idx_htrate on #htrate(ContractGUID,ProjGUID);

    -- 合约规划：除地价外直投合同大类
    -- 业务说明：获取已签约的合约规划数据，排除土地类、营销费、管理费、财务费
    
    -- 已签约的合约规划GUID
    SELECT p.ProjGUID,
           bt.ExecutingBudgetGUID 
    INTO #Budget
    FROM MyCost_Erp352.dbo.cb_Budget bt WITH(NOLOCK)
    INNER JOIN MyCost_Erp352.dbo.cb_BudgetUse bu WITH(NOLOCK) ON bu.BudgetGUID = bt.BudgetGUID
    INNER JOIN MyCost_Erp352.dbo.cb_Contract ct WITH(NOLOCK) ON ct.ContractGUID = bu.RefGUID
    INNER JOIN MyCost_Erp352.dbo.p_Project p WITH(NOLOCK) ON p.ProjCode = bu.ProjectCode
    INNER JOIN MyCost_Erp352.dbo.cb_Budget_Executing e WITH(NOLOCK) ON e.ExecutingBudgetGUID = bt.ExecutingBudgetGUID
    LEFT JOIN MyCost_Erp352.dbo.cb_HtType c WITH(NOLOCK) ON c.HtTypeGUID = e.BigHTTypeGUID
    WHERE bu.IsApprove = 1 
          AND ISNULL(c.HtTypeName, '') NOT IN ('土地类', '营销费', '管理费', '财务费')
    GROUP BY p.ProjGUID, bt.ExecutingBudgetGUID;
        

    -- 已发生成本
    -- 业务说明：计算已签约合约规划的已发生成本
    SELECT bt.ProjGUID,
           ISNULL(SUM(f.CfAmount), 0) AS YfsCost
    INTO #yfs
    FROM MyCost_Erp352.dbo.cb_BudgetUse f WITH(NOLOCK)
    INNER JOIN MyCost_Erp352.dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = f.BudgetGUID
    INNER JOIN MyCost_Erp352.dbo.p_Project p WITH(NOLOCK) ON p.ProjCode = f.ProjectCode
    INNER JOIN #Budget bt ON bt.ExecutingBudgetGUID = b.ExecutingBudgetGUID 
                          AND bt.ProjGUID = p.ProjGUID
    WHERE f.IsApprove = 1 
          AND ISNULL(f.IsFromXyl, 0) = 0
    GROUP BY bt.ProjGUID;

    -- 预留金额-余额
    -- 业务说明：计算合约规划的预留金额余额
    SELECT c.ProjGUID,
           ISNULL(SUM(a.CfAmount), 0) AS YgYeAmount
    INTO #yjl
    FROM MyCost_Erp352.dbo.cb_YgAlter2Budget a WITH(NOLOCK)
    INNER JOIN MyCost_Erp352.dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = a.BudgetGUID
    INNER JOIN MyCost_Erp352.dbo.p_Project p WITH(NOLOCK) ON p.ProjGUID = b.ProjectGUID
    INNER JOIN #Budget c ON b.ExecutingBudgetGUID = c.ExecutingBudgetGUID 
                        AND c.ProjGUID = p.ProjGUID
    GROUP BY c.ProjGUID;

    -- 合约规划汇总统计
    -- 业务说明：统计合约规划的总金额、数量、已签合同数量、待签合同数量等
    SELECT a.ProjectGUID AS ProjGUID,
           ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS NULL THEN a.BudgetAmount ELSE 0 END), 0) AS BudgetAmount,  -- 合约规划总金额（万元）
           COUNT(1) AS BudgetCnt,  -- 总合约规划数量        
           ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS NOT NULL THEN 1 ELSE 0 END), 0) AS ContractCnt,  -- 已签合同数量
           ROUND(ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS NULL THEN a.BudgetAmount ELSE 0 END), 0) / 10000, 2) AS DyqAmount,  -- 待签合同规划金额（万元）
           COUNT(1) - ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS NOT NULL THEN 1 ELSE 0 END), 0) AS DyqCnt  -- 待签合同数量
    INTO #hy
    FROM MyCost_Erp352.dbo.cb_Budget_Executing a WITH(NOLOCK)
    LEFT JOIN #Budget b ON b.ExecutingBudgetGUID = a.ExecutingBudgetGUID 
                       AND b.ProjGUID = a.ProjectGUID
    LEFT JOIN MyCost_Erp352.dbo.cb_HtType c WITH(NOLOCK) ON c.HtTypeGUID = a.BigHTTypeGUID
    WHERE ISNULL(c.HtTypeName, '') NOT IN ('土地类', '营销费', '管理费', '财务费')
    GROUP BY a.ProjectGUID;

    -- 合约规划最终汇总
    -- 业务说明：合并已发生成本、预留金额和合约规划金额，计算动态成本
    SELECT a.ProjGUID AS ProjGUID,
           ISNULL(yfs.YfsCost, 0) + ISNULL(ylj.YgYeAmount, 0) + ISNULL(a.BudgetAmount, 0) AS BudgetAmount,  -- 合约规划总金额（万元）
           a.BudgetCnt AS BudgetCnt,  -- 总合约规划数量
           ROUND((ISNULL(yfs.YfsCost, 0) + ISNULL(ylj.YgYeAmount, 0)) / 10000, 2) AS ContractDtCost,  -- 合约规划动态成本（非现金）金额汇总
           a.ContractCnt AS ContractCnt,  -- 已签合同数量
           a.DyqAmount AS DyqAmount,  -- 待签合同规划金额（万元）
           a.DyqCnt AS DyqCnt  -- 待签合同数量
    INTO #hygh
    FROM #hy a
    LEFT JOIN #yfs yfs ON yfs.ProjGUID = a.ProjGUID
    LEFT JOIN #yjl ylj ON ylj.ProjGUID = a.ProjGUID;

    -- 合同数据汇总（不含土地款及三费）
    -- 业务说明：汇总合同金额、产值、付款等数据，按分期分摊
    SELECT cbp.projguid,
           SUM(ISNULL(cb.htamount, 0) * ISNULL(htrate.Rate, 1)) AS htamountnotfee,  -- 合同金额
           SUM(ISNULL(yljze, 0) * ISNULL(htrate.Rate, 1)) AS yljzenotfee,  -- 预留金金额
           SUM(ISNULL(cbz.jfljywccz, 0) * ISNULL(htrate.Rate, 1)) AS jfljywccznotfee,  -- 甲方审核-现场累计产值
           SUM(CASE WHEN cb.jsstate = '结算' 
                    THEN cb.jsamount_bz * ISNULL(htrate.Rate, 1)
                    ELSE ISNULL(cb.htamount, 0) * ISNULL(htrate.Rate, 1) + ISNULL(cb.sumalteramount, 0) * ISNULL(htrate.Rate, 1)
                END - ISNULL(cbz.jfljywccz, 0) * ISNULL(htrate.Rate, 1)) AS wfqcznotfee,  -- 未发起产值金额
           SUM(ISNULL(pay.payamount, 0) * ISNULL(htrate.Rate, 1)) AS payamountnotfee,  -- 合同-累计付款登记（不含土地+三费）    
           SUM(ISNULL(pay.payamount202502, 0) * ISNULL(htrate.Rate, 1)) AS payamount202502notfee,  -- 合同-累计付款登记（不含土地+三费）截止今年2月28日
           SUM(ISNULL(pay.nopayamount, 0) * ISNULL(htrate.Rate, 1)) AS nopayamountnotfee,  -- 合同-累计付款登记不含税（不含土地+三费）
           SUM(ISNULL(pay.jhfkamountnotax, 0) * ISNULL(htrate.Rate, 1)) AS jhfkamountnotaxnotfee,  -- 合同-累计付款登记不含可抵扣税（不含土地+三费）        
           SUM(ISNULL(htapply.applyamount, 0) * ISNULL(htrate.Rate, 1)) AS applyamountnotfee,  -- 合同-累计付款申请金额（含土地+三费）
           SUM(ISNULL(balance.balanceamount, 0) * ISNULL(htrate.Rate, 1)) AS balanceamountnotfee  -- 合同-结算金额
    INTO #htnotfee
    FROM MyCost_Erp352.dbo.cb_contract cb WITH(NOLOCK)
    INNER JOIN MyCost_Erp352.dbo.cb_httype ty WITH(NOLOCK) ON ty.httypecode = cb.httypecode 
                                                           AND ty.buguid = cb.buguid
    INNER JOIN MyCost_Erp352.dbo.cb_contractproj cbp WITH(NOLOCK) ON cbp.contractguid = cb.contractguid
    LEFT JOIN #htrate htrate ON htrate.ContractGUID = cb.ContractGUID 
                             AND htrate.ProjGUID = cbp.ProjGUID
    LEFT JOIN MyCost_Erp352.dbo.cb_contractcz cbz WITH(NOLOCK) ON cbz.contractguid = cb.contractguid
    LEFT JOIN MyCost_Erp352.dbo.p_project p WITH(NOLOCK) ON cbp.projguid = p.projguid
    LEFT JOIN (
        -- 预留金金额
        SELECT contractguid,
               SUM(ISNULL(cfamount, 0)) AS yljze
        FROM MyCost_Erp352.[dbo].[cb_ygalter2budget] WITH(NOLOCK)
        GROUP BY contractguid
    ) ylj ON ylj.contractguid = cb.contractguid
    LEFT JOIN (
        -- 付款申请金额
        SELECT contractguid,
               SUM(yfamount) AS applyamount
        FROM MyCost_Erp352.dbo.cb_htfkapply WITH(NOLOCK)
        WHERE applystate = '已审核'
        GROUP BY contractguid
    ) htapply ON htapply.contractguid = cb.contractguid
    LEFT JOIN (
        -- 付款登记金额
        SELECT contractguid,
               SUM(ISNULL(payamount, 0)) AS payamount,
               -- 付款日期截止到2025年2月28日
               SUM(CASE WHEN DATEDIFF(day, paydate, '2025-02-28') >= 0 THEN ISNULL(payamount, 0) ELSE 0 END) AS payamount202502,
               SUM(ISNULL(nopayamount, 0)) AS nopayamount,
               SUM(ISNULL(jhfkamountnotax, 0)) AS jhfkamountnotax
        FROM MyCost_Erp352.dbo.cb_pay WITH(NOLOCK)
        GROUP BY contractguid
    ) pay ON pay.contractguid = cb.contractguid      
    LEFT JOIN (
        -- 合同-结算金额
        SELECT contractguid,
               SUM(ISNULL(balanceamount, 0)) AS balanceamount 
        FROM MyCost_Erp352.dbo.cb_htbalance WITH(NOLOCK)
        WHERE balancetype = '结算'
        GROUP BY contractguid
    ) balance ON balance.contractguid = cb.contractguid     
    WHERE cb.approvestate = '已审核' 
          AND cb.IfDdhs = 1  -- 是否单独核算   
          -- 不含土地款及管理费、营销费、财务费合同
          AND ty.httypecode NOT IN ('01', '01.01', '01.02', '01.03', '01.04', '01.05',
                                    '07', '07.01', '07.02', '07.03', '07.04', '07.05',
                                    '07.06', '07.07', '07.08', '07.09', '07.10', '07.11',
                                    '07.12', '07.13', '07.14', '08', '08.01', '09', '09.01')
    GROUP BY cbp.projguid;


    -- =============================================
    -- 第十三部分：分期产值数据汇总
    -- =============================================
    
    -- 分期产值数据汇总
    -- 业务说明：根据产值口径调整规则计算总产值、已发生产值、待发生产值等
    SELECT bu.buname AS '公司名称',  -- 合同的归属公司
           p.projname AS '所属项目',  -- 合同的所属项目
           flg.投管代码 AS '投管代码',
           pp.projcode AS '项目代码',
           p.projcode AS '分期代码',
           p.ProjGUID,
           flg.推广名 AS '推广名',
           mp.acquisitiondate AS '项目获取时间',
           CASE WHEN YEAR(mp.acquisitiondate) >= 2024 THEN '新增量'
                WHEN YEAR(mp.acquisitiondate) >= 2022 AND YEAR(mp.acquisitiondate) < 2024 THEN '增量'
                ELSE '存量' END AS '项目类型',
           flg.工程操盘方 AS '工程操盘方',
           flg.成本操盘方 AS '成本操盘方',
           mp.projstatus AS '项目状态',
           mp.constructstatus AS '工程状态',
           ovr.OutputValueMonthReviewGUID,
           CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' THEN 1 
                WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' THEN 0 END AS 回顾标志,  -- 1为取动态数据，0为取拍照数据
           -- 总产值计算规则：
           -- 1. 回顾人员为明源软件或未回顾项目：取【动态成本金额（不含非现金）】，当【动态成本金额（不含非现金）】小于【合同现场累计产值】，取【合同现场累计产值】
           -- 2. 回顾人员不为明源软件：总产值
           -- 3. 若1、2未取到数据，则取合约规划金额
           ROUND(CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                           AND ISNULL(htnotfee.jfljywccznotfee, 0) <= ISNULL(hyn.targetcost, 0)  
                      THEN ISNULL(hyn.targetcost, 0) 
                      WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                           AND ISNULL(htnotfee.jfljywccznotfee, 0) > ISNULL(hyn.targetcost, 0)  
                      THEN ISNULL(htnotfee.jfljywccznotfee, 0)
                      WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                      THEN ISNULL(ovr.totaloutputvalue, 0) 
                      ELSE ISNULL(hy.BudgetAmount, 0)
                 END, 2) AS '总产值',
            
           -- 已发生产值计算规则：
           -- 1. 回顾人员为明源软件或未回顾项目：取【合同现场累计产值】，合同现场累计产值小于累计应付时，取累计应付，累计应付小于累计实付时，取累计实付
           -- 2. 回顾人员不为明源软件：回顾下的已发生产值
           ROUND(CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                           AND ISNULL(htnotfee.jfljywccznotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0) 
                           AND ISNULL(htnotfee.jfljywccznotfee, 0) >= ISNULL(htnotfee.payamountnotfee, 0)  
                      THEN ISNULL(htnotfee.jfljywccznotfee, 0)
                      WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                           AND ISNULL(htnotfee.applyamountnotfee, 0) >= ISNULL(htnotfee.jfljywccznotfee, 0) 
                           AND ISNULL(htnotfee.applyamountnotfee, 0) >= ISNULL(htnotfee.payamountnotfee, 0)  
                      THEN ISNULL(htnotfee.applyamountnotfee, 0)
                      WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                           AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.jfljywccznotfee, 0) 
                           AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0) 
                      THEN ISNULL(htnotfee.payamountnotfee, 0)
                      WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                      THEN ISNULL(ovr.yfsoutputvalue, 0) 
                 END, 2) AS '已发生产值',
           -- 待发生产值 = 总产值 - 已发生产值
           ROUND((CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.jfljywccznotfee, 0) <= ISNULL(hyn.targetcost, 0)  
                       THEN ISNULL(hyn.targetcost, 0) 
                       WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.jfljywccznotfee, 0) > ISNULL(hyn.targetcost, 0)  
                       THEN ISNULL(htnotfee.jfljywccznotfee, 0)
                       WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                       THEN ISNULL(ovr.totaloutputvalue, 0) 
                       ELSE ISNULL(hy.BudgetAmount, 0)
                  END
                  - 
                  CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.jfljywccznotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0) 
                            AND ISNULL(htnotfee.jfljywccznotfee, 0) >= ISNULL(htnotfee.payamountnotfee, 0)  
                       THEN ISNULL(htnotfee.jfljywccznotfee, 0)
                       WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.applyamountnotfee, 0) >= ISNULL(htnotfee.jfljywccznotfee, 0) 
                            AND ISNULL(htnotfee.applyamountnotfee, 0) >= ISNULL(htnotfee.payamountnotfee, 0)  
                       THEN ISNULL(htnotfee.applyamountnotfee, 0)
                       WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.jfljywccznotfee, 0) 
                            AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0) 
                       THEN ISNULL(htnotfee.payamountnotfee, 0)
                       WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                       THEN ISNULL(ovr.yfsoutputvalue, 0) 
                  END), 2) AS '待发生产值',
           -- 付款数据计算规则：
           -- 累计应付：1. 回顾人员为明源软件或未回顾项目：取【合同-累计付款申请】，累计付款申请小于累计实付时，取累计实付
           --          2. 回顾人员不为明源软件：成本月度回顾-项目盘点累计应付款
           ROUND(CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                           AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0)  
                      THEN ISNULL(htnotfee.payamountnotfee, 0) 
                      WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                           AND ISNULL(htnotfee.payamountnotfee, 0) < ISNULL(htnotfee.applyamountnotfee, 0)  
                      THEN ISNULL(htnotfee.applyamountnotfee, 0) 
                      WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                           AND ISNULL(ovr.ljyfamount, 0) >= ISNULL(ovr.ljsfamount, 0)  
                      THEN ISNULL(ovr.ljyfamount, 0) 
                      WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                           AND ISNULL(ovr.ljyfamount, 0) < ISNULL(ovr.ljsfamount, 0)  
                      THEN ISNULL(ovr.ljsfamount, 0) 
                 END, 2) AS '累计应付',
           ROUND(CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                      THEN ISNULL(htnotfee.payamountnotfee, 0) 
                      WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                      THEN ISNULL(ovr.ljsfamount, 0) 
                 END, 2) AS '累计实付',
           -- 已达产值未付 = 已发生产值 - 累计实付
           ROUND((CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.jfljywccznotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0) 
                            AND ISNULL(htnotfee.jfljywccznotfee, 0) >= ISNULL(htnotfee.payamountnotfee, 0)  
                       THEN ISNULL(htnotfee.jfljywccznotfee, 0)
                       WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.applyamountnotfee, 0) >= ISNULL(htnotfee.jfljywccznotfee, 0) 
                            AND ISNULL(htnotfee.applyamountnotfee, 0) >= ISNULL(htnotfee.payamountnotfee, 0)  
                       THEN ISNULL(htnotfee.applyamountnotfee, 0)
                       WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.jfljywccznotfee, 0) 
                            AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0) 
                       THEN ISNULL(htnotfee.payamountnotfee, 0)
                       WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                       THEN ISNULL(ovr.yfsoutputvalue, 0) 
                  END 
                  - 
                  CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                       THEN ISNULL(htnotfee.payamountnotfee, 0) 
                       WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                       THEN ISNULL(ovr.ljsfamount, 0) 
                  END), 2) AS '已达产值未付',
           -- 应付未付 = 累计应付 - 累计实付
           ROUND((CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.payamountnotfee, 0) >= ISNULL(htnotfee.applyamountnotfee, 0)  
                       THEN ISNULL(htnotfee.payamountnotfee, 0) 
                       WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                            AND ISNULL(htnotfee.payamountnotfee, 0) < ISNULL(htnotfee.applyamountnotfee, 0)  
                       THEN ISNULL(htnotfee.applyamountnotfee, 0) 
                       WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                            AND ISNULL(ovr.ljyfamount, 0) >= ISNULL(ovr.ljsfamount, 0)  
                       THEN ISNULL(ovr.ljyfamount, 0) 
                       WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                            AND ISNULL(ovr.ljyfamount, 0) < ISNULL(ovr.ljsfamount, 0)  
                       THEN ISNULL(ovr.ljsfamount, 0) 
                  END 
                  - 
                  CASE WHEN ISNULL(ovr.createon, '明源软件') = '明源软件' 
                       THEN ISNULL(htnotfee.payamountnotfee, 0) 
                       WHEN ISNULL(ovr.createon, '明源软件') <> '明源软件' 
                       THEN ISNULL(ovr.ljsfamount, 0) 
                  END), 2) AS '应付未付'
    INTO #fqcz                
    FROM MyCost_Erp352.dbo.p_project p WITH(NOLOCK)
    LEFT JOIN MyCost_Erp352.dbo.p_project pp WITH(NOLOCK) ON pp.ProjCode = p.ParentCode AND pp.Level = 2
    INNER JOIN MyCost_Erp352.dbo.mybusinessunit bu WITH(NOLOCK) ON p.buguid = bu.buguid
    INNER JOIN ERP25.dbo.mdm_project mp WITH(NOLOCK) ON mp.projguid = p.ProjGUID
    LEFT JOIN erp25.dbo.vmdm_projectFlag flg WITH(NOLOCK) ON flg.projguid = mp.ParentProjGUID
    LEFT JOIN #vor ovr ON ovr.projguid = p.projguid AND ovr.RN = 1
    LEFT JOIN #htNotfee htNotfee ON htNotfee.ProjGUID = p.ProjGUID
    LEFT JOIN #hygh_new hyn ON hyn.ProjGUID = p.ProjGUID
    LEFT JOIN #hygh hy ON hy.ProjGUID = p.ProjGUID
    WHERE 1 = 1
          AND p.level = 3    
    ORDER BY bu.buname, p.ProjName; 

    -- =============================================
    -- 第十四部分：楼栋产值分摊计算
    -- =============================================
    
    -- 楼栋产值分摊计算
    -- 业务说明：将分期产值按建筑面积和土建比例分摊到各个产品楼栋
    SELECT fq.ProjGUID,
           cp.GCBldGUID,
           gc.gczjm_ratio,
           tj.tjRate,
           cp.SaleBldGUID AS bldguid,
           cp.zjm_ratio,
           cp.UpBuildArea_rate,
           -- 土建比例为null时使用默认值1
           fq.总产值 * gc.gczjm_ratio * ISNULL(tj.tjRate, 1) * cp.zjm_ratio + 
           fq.总产值 * gc.gczjm_ratio * (1 - ISNULL(tj.tjRate, 1)) * 
           CASE WHEN cp.UpBuildArea_rate > 0 THEN cp.UpBuildArea_rate ELSE cp.zjm_ratio END AS 总产值,
           fq.已发生产值 * gc.gczjm_ratio * ISNULL(tj.tjRate, 1) * cp.zjm_ratio + 
           fq.已发生产值 * gc.gczjm_ratio * (1 - ISNULL(tj.tjRate, 1)) * 
           CASE WHEN cp.UpBuildArea_rate > 0 THEN cp.UpBuildArea_rate ELSE cp.zjm_ratio END AS 已完成产值,
           fq.待发生产值 * gc.gczjm_ratio * ISNULL(tj.tjRate, 1) * cp.zjm_ratio + 
           fq.待发生产值 * gc.gczjm_ratio * (1 - ISNULL(tj.tjRate, 1)) * 
           CASE WHEN cp.UpBuildArea_rate > 0 THEN cp.UpBuildArea_rate ELSE cp.zjm_ratio END AS 待发生产值,
           fq.累计应付 * gc.gczjm_ratio * ISNULL(tj.tjRate, 1) * cp.zjm_ratio + 
           fq.累计应付 * gc.gczjm_ratio * (1 - ISNULL(tj.tjRate, 1)) * 
           CASE WHEN cp.UpBuildArea_rate > 0 THEN cp.UpBuildArea_rate ELSE cp.zjm_ratio END AS 合同约定应付金额,
           fq.累计实付 * gc.gczjm_ratio * ISNULL(tj.tjRate, 1) * cp.zjm_ratio + 
           fq.累计实付 * gc.gczjm_ratio * (1 - ISNULL(tj.tjRate, 1)) * 
           CASE WHEN cp.UpBuildArea_rate > 0 THEN cp.UpBuildArea_rate ELSE cp.zjm_ratio END AS 累计支付金额,
           fq.已达产值未付 * gc.gczjm_ratio * ISNULL(tj.tjRate, 1) * cp.zjm_ratio + 
           fq.已达产值未付 * gc.gczjm_ratio * (1 - ISNULL(tj.tjRate, 1)) * 
           CASE WHEN cp.UpBuildArea_rate > 0 THEN cp.UpBuildArea_rate ELSE cp.zjm_ratio END AS 产值未付,
           fq.应付未付 * gc.gczjm_ratio * ISNULL(tj.tjRate, 1) * cp.zjm_ratio + 
           fq.应付未付 * gc.gczjm_ratio * (1 - ISNULL(tj.tjRate, 1)) * 
           CASE WHEN cp.UpBuildArea_rate > 0 THEN cp.UpBuildArea_rate ELSE cp.zjm_ratio END AS 应付未付
    INTO #ldcz
    FROM #fqcz fq
    LEFT JOIN #gcbld_rate gc ON fq.ProjGUID = gc.projguid
    LEFT JOIN #tj_Rate tj ON tj.projguid = fq.projguid
    INNER JOIN #cpbld_rate cp ON cp.GCBldGUID = gc.GCBldGUID;
        /*WHERE fq.回顾标志 = 0
        UNION ALL 
        select    
            fq.ProjGUID,
            b.GCBldGUID,
            null,
            tj.tjRate,
            cp.SaleBldGUID as bldguid,
            cp.zjm_ratio,
            cp.UpBuildArea_rate,
            b.BudgetAmount*ISNULL(tj.tjRate,1)*cp.zjm_ratio+b.BudgetAmount*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 总产值,
            b.Xmpdljwccz*ISNULL(tj.tjRate,1)*cp.zjm_ratio+b.Xmpdljwccz*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 已完成产值,
            b.Dfscz*ISNULL(tj.tjRate,1)*cp.zjm_ratio+b.Dfscz*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 待发生产值,
            b.Ljyfkje*ISNULL(tj.tjRate,1)*cp.zjm_ratio+b.Ljyfkje*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 合同约定应付金额,
            b.LjsfkNoFxj*ISNULL(tj.tjRate,1)*cp.zjm_ratio+b.LjsfkNoFxj*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 累计支付金额,
            b.Ydczwzfje*ISNULL(tj.tjRate,1)*cp.zjm_ratio+b.Ydczwzfje*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 产值未付,
            b.Yfwfje*ISNULL(tj.tjRate,1)*cp.zjm_ratio+b.Yfwfje*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 应付未付
		from  #fqcz fq 
        LEFT JOIN (
                select    
                    a.OutputValueMonthReviewGUID, 
                    gc.GCBldGUID,
                    b.BldName,
                    b.Jszt,
                    b.BldArea,
                    SUM(ISNULL(b.BudgetAmount, 0)) AS BudgetAmount, --总产值
                    SUM(ISNULL(b.HtAmount, 0)) AS OldHtAmount,
                    SUM(ISNULL(b.BcxyAmount, 0)) AS BcxyAmount,
                    SUM(ISNULL(b.HtylAmount, 0)) AS HtylAmount,
                    SUM(ISNULL(b.Sgdwysbcz, 0)) AS Sgdwysbcz,
                    SUM(ISNULL(b.Xmpdljwccz, 0)) AS Xmpdljwccz,--项目盘点累计已完成产值
                    SUM(ISNULL(b.Dfscz, 0)) AS Dfscz,--待发生产值
                    SUM(ISNULL(b.Ljyfkje, 0)) AS Ljyfkje,--累计应付金额
                    SUM(ISNULL(b.Ljsfk, 0)) AS Ljsfk,--累计实付款（含保理）
                    SUM(ISNULL(b.LjsfkNoFxj, 0)) AS LjsfkNoFxj,--累计实付款（不含非现金）
                    SUM(ISNULL(b.BlPayAmount, 0)) AS BlPayAmount, --保理拆分金额
                    SUM(ISNULL(b.Xmpdljwccz, 0)) -  SUM(ISNULL(b.LjsfkNoFxj, 0)) AS Ydczwzfje,--已达产值未付金额
                    SUM(ISNULL(b.Ljyfkje, 0)) -SUM(ISNULL(b.LjsfkNoFxj, 0)) AS Yfwfje --应付未付金额
                from  MyCost_Erp352.dbo.cb_OutputValueReviewDetail a WITH(NOLOCK)
                inner JOIN MyCost_Erp352.dbo.cb_OutputValueReviewBld b  WITH(NOLOCK) ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
                inner join erp25.dbo.mdm_GCBuild  gc on b.bldguid =gc.GCBldGUID
                inner join MyCost_Erp352.dbo.p_Project p on gc.ProjGUID =p.ProjGUID
                where b.BldGUID is  Not NULL   -- and p.BUGUID IN ( @buguid )
                group by  a.OutputValueMonthReviewGUID, 
                    gc.GCBldGUID,
                    b.BldName,
                    b.Jszt,
                    b.BldArea
        ) b ON fq.OutputValueMonthReviewGUID = b.OutputValueMonthReviewGUID
        LEFT JOIN #tj_Rate tj on tj.projguid = fq.projguid
        INNER JOIN #cpbld_rate cp on cp.GCBldGUID = b.GCBldGUID
        WHERE fq.回顾标志 = 1
        */
    -- =============================================
    -- 第十五部分：辅助数据表
    -- =============================================
    
    -- 自持面积统计
    -- 业务说明：统计楼栋的自持面积和套数
    SELECT a.ProductBldGUID AS bldguid,  
           SUM(a.bldarea) / 10000.0 AS 持有面积, 
           COUNT(1) AS 持有套数
    INTO #zs_area
    FROM mycost_erp352.dbo.md_Room a WITH(NOLOCK)
    INNER JOIN #ms ms WITH(NOLOCK) ON ms.SaleBldGUID = a.ProductBldGUID
    WHERE ISNULL(UseProperty, '') IN ('经营', '留存自用')
    GROUP BY a.ProductBldGUID
    UNION ALL 
    SELECT ms.SaleBldGUID,
           SUM(zjm) / 10000.0 AS 持有面积,
           SUM(HouseNum) AS 持有套数 
    FROM #ms ms WITH(NOLOCK)
    WHERE IsHold = '是' 
          AND NOT EXISTS (SELECT 1 FROM mycost_erp352.dbo.md_Room WHERE ProductBldGUID = ms.SaleBldGUID)
    GROUP BY ms.SaleBldGUID;

    -- 面积信息统计
    -- 业务说明：获取楼栋的用地面积、可售面积、计容面积、自持面积等详细信息
    SELECT ms.TopProjGuid AS projguid,  
           ms.salebldguid,
           a.YdArea AS 用地面积,
           a.SaleArea AS 可售面积,
           a.jrArea AS 计容面积,
           a.HoldArea AS 自持面积, 
           ISNULL(a.HoldArea, 0) + ISNULL(a.SaleArea, 0) AS 自持可售面积,
           CASE WHEN a.PhyAddress = '地上' THEN ISNULL(a.SaleArea, 0) ELSE 0 END AS 地上可售面积,
           CASE WHEN a.PhyAddress = '地上' THEN ISNULL(a.HoldArea, 0) ELSE 0 END AS 地上自持面积,
           CASE WHEN a.PhyAddress = '地上' THEN ISNULL(a.SaleArea, 0) + ISNULL(a.HoldArea, 0) ELSE 0 END AS 地上自持可售面积		
    INTO #mj
    FROM mycost_erp352.dbo.vs_md_productbuild_getAreaAndSpaceNumInfo a WITH(NOLOCK) 
    INNER JOIN #ms ms WITH(NOLOCK) ON ms.SaleBldGUID = a.ProductBuildGUID;

    -- 三费+税金情况
    -- 业务说明：获取项目的累计管理费用、营销费用、财务费用、税金等
    SELECT p.ProjGUID,
           a.[累计管理费用（万元）] AS 累计管理费用,
           a.[累计营销费用（万元）] AS 累计营销费用,
           a.[累计财务费用（万元）] AS 累计财务费用,
           a.[累计税金（万元）] AS 累计税金
    INTO #sftax
    FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a WITH(NOLOCK)
    INNER JOIN #p p WITH(NOLOCK) ON a.BusinessGUID = p.ProjGUID
    INNER JOIN ( 
        SELECT TOP 1 a.FillHistoryGUID
        FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a WITH(NOLOCK)
        INNER JOIN dss.dbo.nmap_F_FillHistory b WITH(NOLOCK) ON a.FillHistoryGUID = b.FillHistoryGUID
        WHERE b.ApproveStatus = '已审核'
        ORDER BY b.BeginDate DESC
    ) F ON F.FillHistoryGUID = a.FillHistoryGUID;
        
    -- 楼栋销售结转情况
    -- 业务说明：统计楼栋的已结转套数、面积、收入
    SELECT r.BldGUID, 
           COUNT(1) AS 已结转套数,
           SUM(r.BldArea) / 10000.0 AS 已结转面积,
           SUM(JzAmount) / 10000.0 AS 已结转收入
    INTO #xsjz
    FROM erp25.dbo.s_Trade st WITH(NOLOCK)
    INNER JOIN erp25.dbo.p_room r WITH(NOLOCK) ON st.RoomGUID = r.RoomGUID
    INNER JOIN #ms ms WITH(NOLOCK) ON ms.SaleBldGUID = r.BldGUID
    WHERE jzdate IS NOT NULL 
          AND ISNULL(YJ_TradeStatus, '') = '激活'
    GROUP BY r.BldGUID;
    
    -- 主营业务成本
    -- 业务说明：获取楼栋的主营业务成本数据，按分期和楼栋取最新版本
    SELECT * 
    INTO #CarryOverMbb
    FROM (
        SELECT a.projguid,
               d.BldGUID,
               ROW_NUMBER() OVER (PARTITION BY a.projguid, d.BldGUID ORDER BY a.ApproveDate DESC) AS RowNum,
               a.CarryOverMainGUID 
        FROM [172.16.4.132].[TaskCenterData].dbo.cb_CarryOverMain a WITH(NOLOCK)
        LEFT JOIN [172.16.4.132].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d WITH(NOLOCK) 
            ON d.Subject = 4 AND d.CarryOverMainGUID = a.CarryOverMainGUID
        WHERE a.ApproverState = '已审核'
    ) t 
    WHERE t.RowNum = 1;
 
    -- 已结转成本
    -- 业务说明：计算楼栋的已结转成本，优先使用审批后的数据
    SELECT ld.SaleBldGUID AS bldguid,
           SUM(CASE WHEN e.CarryOverMainGUID IS NOT NULL THEN ISNULL(d.TotalMoney, 0) ELSE ISNULL(b.TotalMoney, 0) END) / 10000.0 AS 已结转成本 
    INTO #jzcb
    FROM erp25.dbo.mdm_SaleBuild ld WITH(NOLOCK)
    INNER JOIN erp25.dbo.mdm_GCBuild gc WITH(NOLOCK) ON gc.GCBldGUID = ld.GCBldGUID
    LEFT JOIN #CarryOverMbb bb WITH(NOLOCK) ON bb.projguid = gc.projguid AND bb.BldGUID = ld.SaleBldGUID
    LEFT JOIN [172.16.4.132].[TaskCenterData].dbo.cb_CarryOverMainSetBldDtl b WITH(NOLOCK) 
        ON ld.SaleBldGUID = b.BldGUID AND b.Subject = 4
    LEFT JOIN [172.16.4.132].[TaskCenterData].dbo.cb_CarryOverMainSet c WITH(NOLOCK) 
        ON b.CarryOverMainSetGUID = c.CarryOverMainSetGUID
    LEFT JOIN [172.16.4.132].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d WITH(NOLOCK) 
        ON ld.SaleBldGUID = d.BldGUID AND d.Subject = 4 AND d.CarryOverMainGUID = bb.CarryOverMainGUID
    LEFT JOIN [172.16.4.132].[TaskCenterData].dbo.cb_CarryOverMain e WITH(NOLOCK) 
        ON d.CarryOverMainGUID = e.CarryOverMainGUID
    GROUP BY ld.SaleBldGUID;

    -- 占压资金数据
    -- 业务说明：获取楼栋的占压资金信息
    SELECT SaleBldGUID,
           ISNULL(占压资金_全口径, 0) + ISNULL(已投资未落实_占压资金_全口径, 0) + ISNULL(开发受限_占压资金_并表口径, 0) AS 占压资金_全口径  
    INTO #zy
    FROM dss.dbo.nmap_s_资源情况 WITH(NOLOCK);

    -- 回笼数据
    -- 业务说明：统计楼栋的累计回笼、当年回笼、当月回笼金额
    SELECT r1.BldGUID,
           SUM(r.累计回笼金额) AS 累计回笼金额,
           SUM(r.累计本年回笼金额) AS 累计本年回笼金额,
           SUM(r.累计本月回笼金额) AS 累计本月回笼金额
    INTO #ljhl
    FROM dbo.s_gsfkylbmxb r WITH(NOLOCK)
    INNER JOIN dbo.p_room r1 WITH(NOLOCK) ON r1.RoomGUID = r.RoomGUID
    INNER JOIN #p0 p ON p.projguid = r1.projguid
    WHERE DATEDIFF(DAY, qxDate, GETDATE()) = 0 
    GROUP BY r1.BldGUID;


    -- 查询处置前后的填报数据，取最新版本的数据
    SELECT  czfl.batch_id,
           czfl.[产品名称],
           czfl.[赛道图楼栋标签],
           czfl.[工程楼栋名称],
           czfl.[是否停工],
           czfl.[产品楼栋名称],
           czfl.[处置前五类],
           czfl.[产品类型],
           czfl.[投管代码],
           czfl.[分期名称],
           czfl.[项目代码],
           czfl.[处置后去向],
           czfl.[产品楼栋GUID],
           czfl.[工程楼栋GUID],
           czfl.[项目推广名]
    INTO #czfl
    FROM  [172.16.4.161].HighData_prod.dbo.data_tb_wq_czfl  czfl
    INNER JOIN  (
        SELECT  batch_id,
                ROW_NUMBER() OVER(PARTITION BY batch_id ORDER BY batch_update_time DESC) AS rum_num
        FROM  [172.16.4.161].HighData_prod.dbo.data_tb_wq_czfl vr
    ) vr ON czfl.batch_id = vr.batch_id AND vr.rum_num = 1

    -- =============================================
    -- 第十六部分：最终查询结果
    -- =============================================
    
    -- 查询最终结果
    -- 业务说明：汇总所有数据，生成湾区公司楼栋资源情况底表
    SELECT dv.DevelopmentCompanyGUID AS OrgGUID,
           dv.DevelopmentCompanyName AS 平台公司,
           p.ProjGUID AS 项目GUID,
           p.ProjName AS 项目名称,
           p.SpreadName AS 项目推广名,
           p.项目股权比例 as 股权比例,
           p.城市 as 所属城市,
           CONVERT(VARCHAR(100), p.ProjCode) AS 明源系统代码,
           CONVERT(VARCHAR(100), lb.LbProjectValue) AS 项目代码,
           p.AcquisitionDate AS 获取时间,
           p.TotalLandPrice / 100000000 AS 总地价,
           CASE WHEN ISNULL(p.PartnerName, '') = '' OR p.PartnerName LIKE '%保利%' THEN '否'
                ELSE '是' END AS 是否合作项目,
           ms.fq AS 分期名称, 
           ms.BldCode AS 产品楼栋名称,
           ms.SaleBldGUID,
           ms.GCBldGUID,
           ms.gcBldName AS 工程楼栋名称,
           ms.ProductType AS 产品类型,
           ms.ProductName AS 产品名称,
           ms.业态六分类  as 业态六分类,
           ms.BusinessType AS 商品类型,
           ms.IsSale AS 是否可售,
           ms.IsHold AS 是否持有,
           ms.Standard AS 装修标准,
           ms.UpNum AS 地上层数,
           ms.DownNum AS 地下层数,
           jd.达到预售形象的条件,
           hz.YJzskgdate AS 实际开工计划日期,
           hz.SJzskgdate AS 实际开工完成日期,
           hz.YjDdysxxDate AS 达到预售形象计划日期,
           hz.SjDdysxxDate AS 达到预售形象完成日期,
           hz.YjYsblDate AS 预售办理计划日期,
           hz.SjYsblDate AS 预售办理完成日期,
           hz.YJjgbadate AS 竣工备案计划日期,
           hz.SJjgbadate AS 竣工备案完成日期,
           hz.JzjfYjdate AS 集中交付计划日期,
           hz.JzjfSjdate AS 集中交付完成日期,
           hz.LxPrice AS 立项均价,
           hz.lxHz / 10000 AS 立项货值,
           hz.DwPrice AS 定位均价,
           hz.dwHz / 10000 AS 定位货值,
           ms.zjm AS 总建面,
           ms.dsjm AS 地上建面,
           ms.dxjm AS 地下建面,
           hz.总可售面积 / 10000.0 AS 总可售面积,
           hz.动态总货值 / 10000.0 AS 动态总货值,
           hz.整盘均价,
           hz.已售面积 / 10000.0 AS 已售面积,
           hz.已售货值 / 10000 AS 已售货值,
           hz.已售均价,
           hz.待售面积 / 10000.0 AS 待售面积,
           hz.待售货值 / 10000 AS 待售货值,
           hz.预测单价,
           hz.BeginYearSaleMj / 10000 AS 年初可售面积,
           hz.BeginYearSaleJe / 10000 AS 年初可售货值,
           hz.ThisYearSaleMjQY / 10000 AS 本年签约面积,
           hz.ThisYearSaleJeQY / 10000 AS 本年签约金额,
           hz.本年签约均价,
           hz.ThisMonthSaleMjQY / 10000 AS 本月签约面积,
           hz.ThisMonthSaleJeQY / 10000 AS 本月签约金额,
           hz.本月签约均价,
           CASE WHEN ms.ProductType = '地下室/车库' THEN bnqy.本年签约面积 
                ELSE bnqy.本年签约面积 / 10000 END AS 本年预计签约面积,
           bnqy.本年签约金额 / 10000 AS 本年预计签约金额,
           hz.SGZsjdate AS 正式开工实际完成时间,
           hz.SGZyjdate AS 正式开工预计完成时间,
           hz.待售套数,
           hz.总可售套数,
           ms.st AS 首推时间,
           -- 新增字段
           BA.盈利规划主键 AS 业态组合键,
           BA.营业成本单方,
           BA.土地款单方,
           BA.除地价外直投单方,
           BA.资本化利息单方,
           BA.开发间接费单方,
           BA.营销费用单方,
           BA.综合管理费单方,
           BA.税金及附加单方,
           BA.股权溢价单方,
           BA.总成本不含税 AS 总成本不含税单方,
           BA.已售对应总成本 / 10000.0 AS 已售对应总成本,
           BA.已售货值不含税 / 10000.0 AS 已售货值不含税,
           jlr.已售净利润签约 / 10000.0 AS 已售净利润签约,
           BA.未售对应总成本 / 10000.0 AS 未售对应总成本,
           BA.近三月签约金额均价不含税,
           BA.近六月签约金额均价不含税,
           BA.立项单价,
           BA.定位单价,
           BA.已售均价不含税,
           BA.货量铺排均价计算方式,
           BA.未售货值不含税 / 10000.0 AS 未售货值不含税,
           jlr.未售净利润签约 / 10000.0 AS 未售净利润签约,
           xm.项目已售税前利润签约 / 10000.0 AS 项目已售税前利润签约,
           xm.项目未售税前利润签约 / 10000.0 AS 项目未售税前利润签约,
           (ISNULL(xm.项目已售税前利润签约, 0) + ISNULL(xm.项目未售税前利润签约, 0)) / 10000.0 AS 项目整盘利润,
           BA.货值铺排均价不含税,
           -- 20240524新增字段
           hz.已售套数,
           BA.近三月签约金额不含税,
           BA.近三月签约面积,
           BA.近六月签约金额不含税,
           BA.近六月签约面积,
           ms.ztguid,
           ms.是否停工,
           ldst.st AS 项目首推时间,
           CASE WHEN ldlist.bldguid IS NULL THEN '否' ELSE '是' END AS 首开楼栋标签,
           ldst.首开30天签约套数,
           ldst.首开30天签约面积 / 10000 AS 首开30天签约面积,
           ldst.首开30天签约金额 / 10000 AS 首开30天签约金额,
           ldst.首开30天认购套数,
           ldst.首开30天认购面积 / 10000 AS 首开30天认购面积,
           ldst.首开30天认购金额 / 10000 AS 首开30天认购金额,

           ldcz.总产值 / 10000 AS 总产值, 
           ldcz.已完成产值 / 10000 AS 已完成产值,
           ldcz.待发生产值 / 10000 AS 待发生产值,
           ldcz.合同约定应付金额 / 10000 AS 合同约定应付金额,
           ldcz.累计支付金额 / 10000 AS 累计支付金额,
           ldcz.产值未付 / 10000 AS 产值未付,
           ldcz.应付未付 / 10000 AS 应付未付,
           -- 持有信息
           zs.持有套数,
           zs.持有面积,
           -- 同项目同业态的已售均价
           hz.业态均价 as 业态均价,
           --持有货值:持有面积*平年签约均价或业态均价 
           case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end as 持有货值,

           BA.土地款单方 * (mj.自持面积 + mj.可售面积) / 10000.0 AS 土地分摊金额,
           ldcz.累计支付金额 / 10000 AS 除地价外直投分摊金额,
           CASE WHEN pro_mj.可售面积 = 0 THEN 0 
                ELSE sftax.累计营销费用 * mj.可售面积 / pro_mj.可售面积 END AS 已发生营销费用摊分金额,
           CASE WHEN pro_mj.可售面积 = 0 THEN 0 
                ELSE sftax.累计管理费用 * mj.可售面积 / pro_mj.可售面积 END AS 已发生管理费用摊分金额,
           CASE WHEN pro_mj.可售面积 = 0 THEN 0 
                ELSE sftax.累计财务费用 * mj.可售面积 / pro_mj.可售面积 END AS 已发生财务费用费用摊分金额,
           CASE WHEN pro_mj.可售面积 = 0 THEN 0 
                ELSE sftax.累计税金 * mj.可售面积 / pro_mj.可售面积 END AS 已发生税金分摊,
           xsjz.已结转套数,
           xsjz.已结转面积,
           xsjz.已结转收入,
           jzcb.已结转成本,
           con.ts AS 签约套数2024年,
           con.bldarea AS 签约面积2024年,
           con.total AS 签约金额2024年,
           CASE WHEN con.bldarea = 0 THEN 0 
                ELSE con.total / con.bldarea * 1.00 END AS 签约均价2024年,
           ba.经营成本单方,
           tag.BuildTagValue AS 赛道图标签,
           zy.占压资金_全口径 AS 占压资金,
           -- 20250805 增加回笼字段，累计回笼、当年回笼、当月回笼
           hl.累计回笼金额 / 10000 AS 累计回笼金额,
           hl.累计本年回笼金额 / 10000 AS 累计本年回笼金额,
           hl.累计本月回笼金额 / 10000 AS 累计本月回笼金额,
           -- 用地面积、可售面积、计容面积、自持面积、（自持+可售）面积、地上可售面积、地上自持面积、地上可售面积+地上自持面积
           ISNULL(mj.用地面积, 0) * ISNULL(cp_rate.zjm_ratio, 1) AS 用地面积,
           ISNULL(mj.可售面积, 0) AS 可售面积,
           ISNULL(mj.计容面积, 0) AS 计容面积,
           ISNULL(mj.自持面积, 0) AS 自持面积,
           ISNULL(mj.自持可售面积, 0) AS 自持可售面积,
           ISNULL(mj.地上可售面积, 0) AS 地上可售面积,
           ISNULL(mj.地上自持面积, 0) AS 地上自持面积,
           ISNULL(mj.地上自持可售面积, 0) AS 地上可售面积地上自持面积,

           -- 反算总货值
           isnull(hz.动态总货值 / 10000.0, 0 ) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) as 反算总货值_总货值, -- 动态总可售货值+持有货值
           isnull(hz.总可售面积 / 10000.0,0) + isnull(zs.持有面积,0) as 反算总货值_总面积, --动态总可售面积+持有面积
           isnull(hz.待售货值 / 10000,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 )   as 反算总货值_剩余货值, -- 待售货值+持有货值
           isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0)  as 反算总货值_剩余面积, -- 待售面积+持有面积

           -- 已开工情况
            case when  hz.SJzskgdate is not null then  
               isnull(hz.动态总货值 / 10000.0, 0 ) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) else  0 end as 已开工情况_已开工货值, -- 已开工的反算总货值
            case when  hz.SJzskgdate is not null then 
                 isnull(hz.总可售面积 / 10000.0,0) + isnull(zs.持有面积,0)  else  0 end  as 已开工情况_已开工面积, -- 已开工的反算总面积
            case when hz.SJzskgdate is not null then hz.已售货值 / 10000.0 else 0 end as 已开工情况_已开工已售货值,
            case when hz.SJzskgdate is not null then hz.已售面积 / 10000.0 else 0 end as 已开工情况_已开工已售面积,
            case when hz.SJzskgdate is not null then isnull(hz.待售货值 / 10000.0,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) else 0 end as 已开工情况_已开工未售货值, --已开工的反算剩余货值
            case when hz.SJzskgdate is not null then isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0)  else 0 end as 已开工情况_已开工未售面积, --已开工的反算剩余面积
           
           -- 存货情况
           case when hz.SJzskgdate is not null and hz.SjDdysxxDate is not NULL then isnull(hz.待售货值 / 10000.0,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) else 0 end as  存货情况_存货货值, -- 达形象形象的反算剩余货值
           case when hz.SJzskgdate is not null and hz.SjDdysxxDate is not NULL then isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0)  else 0 end as 存货情况_存货面积, -- 达形象形象的反算剩余货值

           -- 自持情况
           case  when tag.BuildTagValue in ('D1-已开业未融资','D2-已开业已融资','D3-未开业')  then  
               isnull(hz.待售货值 / 10000,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 )  else 0 end  
           + case when  tag.BuildTagValue not  in ('D1-已开业未融资','D2-已开业已融资','D3-未开业')  then
               case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end else 0  end as 自持情况_总自持资产货值, 
           case when  tag.BuildTagValue in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') then
              isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0) else  0 end
           + case when  tag.BuildTagValue not in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') then
               isnull(zs.持有面积,0) else  0 end  as 自持情况_总自持资产面积,-- 赛道图楼栋标签为D1/D2/D3的反算剩余面积，或赛道图楼栋标签不为D1/D2/D3的持有面积
           case  when tag.BuildTagValue in ('D1-已开业未融资','D2-已开业已融资','D3-未开业')  then  
               isnull(hz.待售货值 / 10000,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 )  else 0 end as 自持情况_已转经营货值,	-- 赛道图楼栋标签为D1/D2/D3的反算剩余货值
           case when  tag.BuildTagValue in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') then
              isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0) else  0 end as 自持情况_已转经营面积, -- 赛道图楼栋标签为D1/D2/D3的反算剩余面积

           -- 在途情况
           case when hz.SJzskgdate is not null and hz.SjDdysxxDate is null then isnull(hz.待售货值 / 10000.0,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) else 0 end as 在途情况_在途货值, -- 已开工未达形象的反算剩余货值
           case when hz.SJzskgdate is not null and hz.SjDdysxxDate is null then isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0)  else 0 end as 在途情况_在途面积, -- 已开工未达形象的反算剩余面积
           -- 未开工情况
           case when hz.SJzskgdate is NULL then isnull(hz.待售货值 / 10000.0,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) else 0 end as 未开工情况_未开工货值, -- 尚未开工的反算剩余货值
           case when hz.SJzskgdate is NULL then isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0)  else 0 end as 未开工情况_未开工面积, -- 尚未开工的反算剩余面积
           
           -- 分货情况
           case when  czfl.[处置后去向] ='分货' then
             case when  czfl.[赛道图楼栋标签] in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') then
               isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0) else  0 end * isnull(p.项目股权比例,0)
           else 0 end as 分货转经营面积,	-- 处置后去向标签为分货的反算剩余面积*我司股比
           case when  czfl.[处置后去向] ='分货' then
             case when  czfl.[赛道图楼栋标签] in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') then
               isnull(hz.待售货值 / 10000.0,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) else  0 end * isnull(p.项目股权比例,0)
           else 0 end as 分货转经营金额,	-- 处置后去向标签为分货的反算剩余货值*我司股比
           case when  czfl.[处置后去向] ='分货' then
             case when  czfl.[赛道图楼栋标签] in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') then
               isnull(hz.待售面积 / 10000.0,0) + isnull(zs.持有面积,0) else  0 end * ( 1- isnull(p.项目股权比例,0) )
           else 0 end as 分货销售面积,  -- 处置后去向标签为分货的反算剩余面积*非我司股比
           case when  czfl.[处置后去向] ='分货' then
             case when  czfl.[赛道图楼栋标签] in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') then
               isnull(hz.待售货值 / 10000.0,0) + isnull(case  when isnull(hz.本年签约均价,0) <>0 then  isnull(zs.持有面积,0) * isnull(hz.本年签约均价,0) 
                 else isnull(zs.持有面积,0) * isnull(hz.业态均价,0) end ,0 ) else  0 end * ( 1- isnull(p.项目股权比例,0) )
           else 0 end as 分货销售金额,	--处置后去向标签为分货的反算剩余货值*非我司股比

           -- 标签划分
           case when hz.SJzskgdate is not null then '是' else '否' end as 是否开工,
           case when ms.st is not null then '是' else  '否' end as 推售状态,-- 是否已推售
           case when hz.SJjgbadate  is not NULL  then '是' else  '否' end  as 竣备情况,
           czfl.[处置前五类] as 处置前五类,
           czfl.[处置后去向] as 处置后去向
    FROM #ms ms
    LEFT JOIN #bnqy bnqy ON ms.SaleBldGUID = bnqy.SaleBldGUID
    LEFT JOIN #p p ON ms.TopProjGuid = p.ProjGUID
    LEFT JOIN dbo.p_DevelopmentCompany dv ON dv.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
    LEFT JOIN dbo.myBizParamOption city ON city.ParamGUID = p.CityGUID AND city.ParamName = 'td_city'
    LEFT JOIN mdm_LbProject lb ON lb.projGUID = p.ProjGUID AND lb.LbProject = 'tgid'
    LEFT JOIN #hz hz ON hz.SaleBldGUID = ms.SaleBldGUID
    LEFT JOIN #jd jd ON jd.GCBldGUID = ms.GCBldGUID
    LEFT JOIN #base BA ON BA.SaleBldGUID = ms.SaleBldGUID
    LEFT JOIN #jlr jlr ON jlr.SaleBldGUID = ms.SaleBldGUID
    LEFT JOIN #xm xm ON ms.TopProjGuid = xm.ProjGUID
    LEFT JOIN #ld_st_sale ldst ON ldst.bldguid = ms.salebldguid
    LEFT JOIN #bld_lst ldlist ON ldlist.bldguid = ms.salebldguid
    LEFT JOIN #con con ON con.BldGUID = ms.SaleBldGUID
    LEFT JOIN #ldcz ldcz ON ldcz.bldguid = ms.salebldguid
    LEFT JOIN #zs_area zs ON zs.bldguid = ms.salebldguid
    LEFT JOIN #mj mj ON mj.salebldguid = ms.salebldguid
    LEFT JOIN (SELECT projguid, SUM(自持面积) AS 自持面积, SUM(可售面积) AS 可售面积 FROM #mj GROUP BY projguid) pro_mj ON pro_mj.projguid = ms.TopProjGuid
    LEFT JOIN #sftax sftax ON sftax.projguid = ms.TopProjGuid
    LEFT JOIN #xsjz xsjz ON xsjz.bldguid = ms.salebldguid
    LEFT JOIN #jzcb jzcb ON jzcb.bldguid = ms.salebldguid
    LEFT JOIN mdm_BuildTag tag ON tag.SaleBldGUID = ms.salebldguid AND buildtag = 'SDT' 
    LEFT JOIN #zy zy ON zy.SaleBldGUID = ms.SaleBldGUID
    LEFT JOIN #ljhl hl ON hl.BldGUID = ms.SaleBldGUID
    LEFT JOIN #cpbld_rate cp_rate ON cp_rate.SaleBldGUID = ms.SaleBldGUID
    left join #czfl czfl ON czfl.产品楼栋GUID = ms.SaleBldGUID
    ORDER BY dv.DevelopmentCompanyName, p.ProjCode

    -- =============================================
    -- 第十七部分：清理临时表
    -- =============================================
    
    -- 清理所有临时表
    DROP TABLE #jd, #p, #p0, #hz, #ms, #st, #base, #bnqy, #df, #hlpp_bld, #hlpp_product, #jlr, #key, #xm,
               #dfhz, #bld_lst, #bld_st, #con, #con2024, #feebck, #hz_st, #ld_rate, #ld_st_sale,
               #proj_rate, #proj_st, #qy_st, #rg_st, #t, #ts_st, #vrt, #gcbld_rate, #tj_Rate, #cpbld_rate,
               #vor, #htnotfee, #fqcz, #ldcz, #htrate, #zy, #ljhl, #zs_area, #mj, #sftax, #xsjz, #jzcb, #CarryOverMbb,
               #Budget, #yfs, #yjl, #hy, #hygh, #hygh_new,#czfl

END