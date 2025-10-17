-- exec  [172.16.4.141].erp25.dbo.usp_正常补货项目清单 

create proc usp_正常补货项目清单
as 
BEGIN
    --首先判断是否存在版本，如果是实时查询就是默认值，如果点击拍照版本，就不是默认值
    BEGIN
        --declare @VersionGUID VARCHAR(40)
       -- DECLARE @var_buguid VARCHAR(MAX) = '5A4B2DEF-E803-49F8-9FE2-308735E7233D';

        SELECT p.*
        INTO #p
        FROM mdm_Project p
        WHERE 1 = 1
        --      AND p.DevelopmentCompanyGUID IN (
        --                                          SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
        --                                      )
              AND p.Level = 2;

        SELECT p.ProjGUID,
               p.ProjName,
               p.ParentProjGUID TopProjGuid
        INTO #p0
        FROM mdm_Project p
             INNER JOIN #p p1 ON p.ParentProjGUID = p1.ProjGUID;


        SELECT SaleBldGUID,
               SUM(ThisMonthSaleAreaQy) 本年签约面积,
               SUM(ThisMonthSaleMoneyQy) 本年签约金额
        INTO #bnqy
        FROM dbo.s_SaleValueBuildLayout
        WHERE SaleValuePlanYear = YEAR(GETDATE())
        GROUP BY SaleBldGUID;

        SELECT r.BldGUID,
               MIN(o.QSDate) st
        INTO #st
        FROM dbo.s_Order o
             LEFT JOIN p_room r ON o.RoomGUID = r.RoomGUID
        WHERE o.Status = '激活'
              OR o.CloseReason = '转签约'
        GROUP BY r.BldGUID;

        -----找楼栋的对应税率 begin ------------------
        --找到房间税率
        SELECT DISTINCT
               vt.ProjGUID,
               VATRate,
               RoomGUID,
               r.bldguid
        INTO #vrt
        FROM s_VATSet vt -----  
             INNER JOIN p_room r ON vt.ProjGUID = r.ProjGUID
        WHERE VATScope = '整个项目'
              AND AuditState = 1
              AND r.IsVirtualRoom = 0
              AND RoomGUID NOT IN ( SELECT DISTINCT
                                             vtr.RoomGUID
                                      FROM s_VATSet vt ---------  
                                           INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
                                           INNER JOIN p_room r ON vtr.RoomGUID = r.RoomGUID
                                      WHERE VATScope = '特定房间'
                                            AND AuditState = 1
                                            AND r.IsVirtualRoom = 0
                                  )
        union all 
        SELECT
            DISTINCT vt.ProjGUID,
            VATRate,
            bldguid,
            r.bldguid
        FROM s_VATSet vt -----  
            INNER JOIN p_building r ON vt.ProjGUID = r.ProjGUID
        WHERE VATScope = '整个项目'
            AND AuditState = 1
        UNION ALL
        SELECT DISTINCT
               vt.ProjGUID,
               vt.VATRate,
               vtr.RoomGUID,
               r.bldguid
        FROM s_VATSet vt ---------  
             INNER JOIN s_VAT2RoomScope vtr ON vt.VATGUID = vtr.VATGUID
             INNER JOIN p_room r ON vtr.RoomGUID = r.RoomGUID
        WHERE VATScope = '特定房间'
              AND AuditState = 1
              AND r.IsVirtualRoom = 0;


        --找到去重后的楼栋的税率
        SELECT DISTINCT
               projguid,
               bldguid,
               VATRate
        INTO #t
        FROM #vrt;

        --随机取一个汇率，找到楼栋税率
        SELECT projguid,bldguid,VATRate/100 as VATRate
        into #ld_rate
        FROM
        (
            SELECT projguid,
                   bldguid,
                   VATRate,
                   ROW_NUMBER() OVER (PARTITION BY bldguid ORDER BY VATRate DESC) rownum
            FROM #t
        ) a
        WHERE rownum = 1;

        --项目随机找到一个税率
        SELECT projguid,VATRate/100 as VATRate
        into #proj_rate
        FROM
        (
            SELECT pj.ParentProjGUID projguid,
                   VATRate,
                   ROW_NUMBER() OVER (PARTITION BY pj.ParentProjGUID ORDER BY VATRate DESC) rownum
            FROM #t t 
            inner join mdm_project pj on t.projguid = pj.projguid
        ) a
        WHERE rownum = 1;

        -----找楼栋的对应税率 end ---------------------
  
        --缓存产品楼栋
        SELECT ms.SaleBldGUID,
            gc.GCBldGUID,
            p.TopProjGuid,
            p.ProjName fq,
            ms.BldCode,
            gc.BldName gcBldName,
            ISNULL(ms.UpBuildArea, 0) + ISNULL(ms.DownBuildArea, 0) zjm,
            ms.UpBuildArea dsjm,
            ms.DownBuildArea dxjm,
            isnull(pr.ProductType,c1.ProductType) as ProductType,
            isnull(pr.ProductName,c1.ProductName) as ProductName,
            isnull(pr.BusinessType,c1.BusinessType) as BusinessType,
            isnull(pr.IsSale,c1.IsSale) as IsSale,
            isnull(pr.IsHold,case when c1.HoldRate > 0 then '是' else '否' end) as IsHold,
            isnull(pr.Standard,ProductBuild.Zxbz) as STANDARD,
            ms.UpNum,
            ms.DownNum,
            st.st,
            c.ztguid,
            c.是否停工,
            ms.HouseNum
        INTO #ms
        FROM dbo.mdm_SaleBuild ms
        LEFT JOIN mdm_Product pr ON pr.ProductGUID = ms.ProductGUID
        LEFT JOIN mdm_GCBuild gc ON gc.GCBldGUID = ms.GCBldGUID
        left join MyCost_Erp352.dbo.md_ProductBuild ProductBuild WITH(NOLOCK) on ms.ProductGUID = ProductBuild.ProductBuildGUID
        left join (SELECT VersionGUID, ProjGUID,ParentProjGUID,projname,ROW_NUMBER() OVER ( PARTITION BY ProjGUID ORDER BY CreateDate DESC ) rowno 
                 FROM  MyCost_Erp352.dbo.md_Project where IsActive = 1) a on  ProductBuild.VersionGUID =a.VersionGUID and ProductBuild.ProjGUID = a.ProjGUID and a.rowno=1 --项目必须要有激活版，否则排除掉
        left join erp25.dbo.vmdm_ProjectInfoEx  pj on pj.projguid = a.ParentProjGUID 
        left  join  MyCost_Erp352.dbo.[vmd_Product_Work] c1 ON ProductBuild.ProductKeyGUID=c1.ProductKeyGUID and  a.VersionGUID=c1.VersionGUID and  c1.ProjGUID=a.ProjGUID 
        INNER JOIN #p0 p ON p.ProjGUID = ISNULL(pj.projguid,gc.ProjGUID)
        LEFT JOIN #st st ON ISNULL(ms.ImportSaleBldGUID, ms.SaleBldGUID) = st.BldGUID
        LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b ON ms.GCBldGUID = b.BuildingGUID
        LEFT JOIN MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport c ON b.budguid = c.ztguid
        where isnull(pr.ProductType,c1.ProductType) in ('住宅','高级住宅')
        ;
    
    --产品标准工期
    select 公司名称,城市名称,业态,min(首开整体工期) 首开整体工期 
    into #bzgq 
    from x_s_bzgq a 
    group by 公司名称,城市名称,业态

        --货值
        SELECT ld.projguid,
               ld.ProductType + '_' + ld.ProductName + '_' + ld.BusinessType + '_' + ld.Standard yt,
               p.projcode + '_' + ld.ProductType + '_' + ld.ProductName + '_' + ld.BusinessType + '_' + ld.Standard ytid,
               ld.ProductType,
               ld.ProductName,
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
               case when b.PhyAddress = '地上' then ld.zksmj else 0 end 地上总可售面积,
               ld.zhz 动态总货值,
               CASE
                   WHEN ld.zksmj = 0 THEN
                        0
                   ELSE ld.zhz / ld.zksmj
               END 整盘均价,
               ld.ysmj * 1.0 已售面积,
               case when b.PhyAddress = '地上' then ld.ysmj * 1.0 else 0 end 地上已售面积,
               ld.ysje 已售货值,
              CASE when isnull(ldr.VATRate,isnull(pdr.VATRate,''))<>'' then ld.ysje / (1 + isnull(ldr.VATRate,isnull(pdr.VATRate,'')))
                   ELSE ld.ysje / (1 + 0.09)
               END as 已售货值不含税, --如果系统上设置了税率的，以系统为准；否则按照1.09来计算
               ld.ysts 已售套数,
               CASE
                   WHEN ld.ysmj = 0 THEN
                        0
                   ELSE ld.ysje / ld.ysmj
               END 已售均价,
               ld.zksts - ld.ysts 待售套数,
               case when b.PhyAddress = '地上' then ld.zksts - ld.ysts else 0 end 地上待售套数,
               ld.zksmj * 1.0 - ld.ysmj * 1.0 待售面积,
               case when b.PhyAddress = '地上' then ld.zksmj * 1.0 - ld.ysmj * 1.0 else 0 end 地上待售面积,
               ld.syhz 待售货值,
               CASE when isnull(ldr.VATRate,isnull(pdr.VATRate,''))<>'' then ld.syhz / (1 + isnull(ldr.VATRate,isnull(pdr.VATRate,'')))
                   ELSE ld.syhz / (1 + 0.09)
               END as 待售货值不含税, 
               ld.YcPrice 预测单价,
               ld.BeginYearSaleMj,
               ld.BeginYearSaleJe,
               ld.ThisYearSaleMjQY,
               ld.ThisYearSaleJeQY,
               ld.ThisYearSaleTsQY,
               CASE
                   WHEN ld.ThisYearSaleMjQY = 0 THEN
                        0
                   ELSE ld.ThisYearSaleJeQY / ld.ThisYearSaleMjQY
               END 本年签约均价,
               ld.ThisMonthSaleMjQY,
               ld.ThisMonthSaleJeQY,
               ld.ThisMonthSaleTsQY,
               CASE
                   WHEN ld.ThisMonthSaleMjQY = 0 THEN
                        0
                   ELSE ld.ThisMonthSaleJeQY / ld.ThisMonthSaleMjQY
               END 本月签约均价,
               b.PhyAddress,
               c.首开整体工期,
               f.城市
        INTO #hz
        FROM dbo.p_lddbamj ld
            INNER JOIN #p p ON p.ProjGUID = ld.ProjGUID
            left join #ld_rate ldr on ldr.BldGUID = ld.SaleBldGUID
            left join #proj_rate pdr on pdr.projguid = ld.projguid
            left join MyCost_Erp352.dbo.md_ProductNameModule b on ld.ProductType = b.ProductType and ld.ProductName = b.ProductName
            left join vmdm_projectFlag f on ld.ProjGUID = f.ProjGUID
            left join #bzgq c on f.平台公司 = c.公司名称 and (case when ld.ProductType = '高级住宅' and f.平台公司 not in ('湖北公司','湖南公司','湾区公司','粤中公司') then '小高层住宅' else ld.ProductName end ) = c.业态
             and f.城市 = c.城市名称
        WHERE DATEDIFF(d, QXDate, GETDATE()) = 0
        and ld.ProductType in ('住宅','高级住宅')
        ;

        --单方
        SELECT 项目guid,
               T.基础数据主键,
               --T.盈利规划系统自动匹对主键,
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
        FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 T
             INNER JOIN
             (
                 SELECT ROW_NUMBER() OVER (PARTITION BY a.FillDataGUID ORDER BY EndDate DESC) NUM,
                        FillHistoryGUID
                 FROM dss.dbo.nmap_F_FillHistory a
                 WHERE EXISTS
                 (
                     SELECT FillHistoryGUID,
                            SUM(   CASE
                                       WHEN 项目guid IS NULL
                                            OR 项目guid = '' THEN
                                            0
                                       ELSE 1
                                   END
                               ) AS num
                     FROM dss.dbo.nmap_F_明源及盈利规划业态单方沉淀表 b
                     WHERE a.FillHistoryGUID = b.FillHistoryGUID
                     GROUP BY FillHistoryGUID
                     HAVING SUM(   CASE
                                       WHEN 项目guid IS NULL THEN
                                            0
                                       ELSE 1
                                   END
                               ) > 0
                 )
             ) V ON T.FillHistoryGUID = V.FillHistoryGUID
                    AND V.NUM = 1
        WHERE ISNULL(T.项目guid, '') <> ''
        GROUP BY 项目guid,
                 T.基础数据主键,
                 --T.盈利规划系统自动匹对主键,
                 CASE
                     WHEN ISNULL(T.盈利规划系统自动匹对主键, '') <> '' THEN
                          T.盈利规划系统自动匹对主键
                     ELSE CASE
                              WHEN ISNULL(T.盈利规划主键, '') <> '' THEN
                                   T.盈利规划主键
                              ELSE T.基础数据主键
                          END
                 END;
        --总成本单方计算

        SELECT t.*, 营业成本单方 + 营销费用单方 + 综合管理费单方 + 股权溢价单方 + 税金及附加单方 AS 总成本不含税
        INTO #dfhz
        FROM
        (
            SELECT DISTINCT
                   k.[项目guid], -- 避免重复
                   k.基础数据主键,
                   ISNULL(k.盈利规划主键, ylgh.匹配主键) 盈利规划主键,
                   ISNULL(ylgh.总可售面积, 0) AS 盈利规划总可售面积,
                   CASE
                       WHEN ISNULL(k.营业成本单方, 0) = 0 THEN
                            ISNULL(ylgh.盈利规划营业成本单方, 0)
                       ELSE ISNULL(k.营业成本单方, 0)
                   END AS 营业成本单方,
                   CASE
                       WHEN ISNULL(k.土地款单方, 0) = 0 THEN
                            ISNULL(ylgh.土地款_单方, 0)
                       ELSE k.土地款单方
                   END 土地款单方,
                   CASE
                       WHEN ISNULL(k.除地价外直投单方, 0) = 0 THEN
                            ISNULL(ylgh.除地外直投_单方, 0)
                       ELSE k.除地价外直投单方
                   END AS 除地价外直投单方,
                   CASE
                       WHEN ISNULL(k.开发间接费单方, 0) = 0 THEN
                            ISNULL(ylgh.开发间接费单方, 0)
                       ELSE k.开发间接费单方
                   END AS 开发间接费单方,
                   CASE
                       WHEN ISNULL(k.资本化利息单方, 0) = 0 THEN
                            ISNULL(ylgh.资本化利息单方, 0)
                       ELSE k.资本化利息单方
                   END AS 资本化利息单方,
                   CASE
                       WHEN ISNULL(k.股权溢价单方, 0) = 0 THEN
                            ISNULL(ylgh.股权溢价单方, 0)
                       ELSE k.股权溢价单方
                   END AS 股权溢价单方,
                   CASE
                       WHEN ISNULL(k.营销费用单方, 0) = 0 THEN
                            ISNULL(ylgh.营销费用单方, 0)
                       ELSE k.营销费用单方
                   END AS 营销费用单方,
                   CASE
                       WHEN ISNULL(k.综合管理费单方, 0) = 0 THEN
                            ISNULL(ylgh.管理费用单方, 0)
                       ELSE k.综合管理费单方
                   END AS 综合管理费单方,
                   CASE
                       WHEN ISNULL(k.税金及附加单方, 0) = 0 THEN
                            ISNULL(ylgh.税金及附加单方, 0)
                       ELSE k.税金及附加单方
                   END AS 税金及附加单方,
                   ylgh.经营成本单方
            FROM #key k
                 LEFT JOIN dss.dbo.s_F066项目毛利率销售底表_盈利规划单方 ylgh ON ylgh.匹配主键 = k.盈利规划主键
                                                                  AND ylgh.[项目guid] = k.项目guid
        ) t;

        SELECT *
        INTO #df
        FROM
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY 基础数据主键 ORDER BY 盈利规划主键 DESC) rownum,
                   *
            FROM #dfhz
        ) a
        WHERE a.rownum = 1;

        --业态铺排
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
        FROM s_product_salevalue
        WHERE DATEDIFF(mm, 月份, GETDATE()) = 0;
        --楼栋铺排
        SELECT 项目guid,
               CONCAT(产品类型, '_', 产品名称, '_', 商品房, '_', 装修标准) 业态组合键,
               产品楼栋guid,
             --  累计签约金额不含税,
               累计签约不含税均价 累计签约均价不含税,
               铺排价格 / (1 + 0.09) AS 铺排价格不含税,
               均价计算方式 货量铺排均价计算方式
        INTO #hlpp_bld
        FROM s_bld_salevalue2
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


        --汇总        
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
               (CASE
                    WHEN hz.ProductType = '地下室/车库' THEN
                         已售套数
                    ELSE 已售面积
                END
               ) * df.总成本不含税 已售对应总成本,
               hz.已售货值不含税,
               --ld.累计签约金额不含税 已售货值不含税,
               (CASE
                    WHEN hz.ProductType = '地下室/车库' THEN
                         待售套数
                    ELSE 待售面积
                END
               ) * df.总成本不含税 未售对应总成本,
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
               --(CASE
               --     WHEN hz.ProductType = '地下室/车库' THEN
               --          待售套数
               --     ELSE 待售面积
               -- END
               --) * 未售货值均价 未售货值不含税,
               hz.待售货值不含税 as 未售货值不含税,
               CASE
                   WHEN hz.ProductType = '地下室/车库' THEN
                        已售套数
                   ELSE 已售面积
               END AS 已售面积,
               CASE
                   WHEN hz.ProductType = '地下室/车库' THEN
                        待售套数
                   ELSE 待售面积
               END AS 待售面积
        INTO #base
        FROM #hz hz
             LEFT JOIN #df df ON hz.ytid = df.基础数据主键
             LEFT JOIN #hlpp_bld ld ON ld.项目guid = hz.projguid
                                       AND hz.SaleBldGUID = ld.产品楼栋guid
                                       AND ld.业态组合键 = hz.yt
             LEFT JOIN #hlpp_product pro ON hz.projguid = pro.项目guid
                                            AND hz.yt = pro.业态组合键
             --LEFT JOIN #price pr ON pr.产品楼栋guid = hz.SaleBldGUID; 

        --项目净利润
        SELECT c.ProjGUID,
               SUM(CONVERT(
                              DECIMAL(36, 8),
                              ((ISNULL(c.已售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.已售面积, 0)/*- c.盈利规划股权溢价认购*/)
                               - ISNULL(c.营销费用单方, 0) * ISNULL(c.已售面积, 0) - ISNULL(c.综合管理费单方, 0) * ISNULL(c.已售面积, 0)
                               - ISNULL(c.税金及附加单方, 0) * ISNULL(c.已售面积, 0)
                              )
                          )
                  ) 项目已售税前利润签约,
               SUM(CONVERT(
                              DECIMAL(36, 8),
                              ((ISNULL(c.未售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.待售面积, 0)/*- c.盈利规划股权溢价认购*/)
                               - ISNULL(c.营销费用单方, 0) * ISNULL(c.待售面积, 0) - ISNULL(c.综合管理费单方, 0) * ISNULL(c.待售面积, 0)
                               - ISNULL(c.税金及附加单方, 0) * ISNULL(c.待售面积, 0)
                              )
                          )
                  ) 项目未售税前利润签约
        INTO #xm
        FROM #base c
        --inner join #wshz ws on c.projguid = ws.projguid and c.业态组合 = ws.yt
        GROUP BY c.ProjGUID;


        --楼栋净利润
        SELECT c.SaleBldGUID,
               CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.未售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.待售面积, 0) - ISNULL(c.股权溢价单方, 0)
                            * ISNULL(c.待售面积, 0)
                           ) - ISNULL(c.营销费用单方, 0) * ISNULL(c.待售面积, 0) - ISNULL(c.综合管理费单方, 0)
                           * ISNULL(c.待售面积, 0) - ISNULL(c.税金及附加单方, 0) * ISNULL(c.待售面积, 0)
                          )
                      )
               - CASE
                     WHEN ISNULL(x.项目未售税前利润签约, 0) + ISNULL(x.项目已售税前利润签约, 0) > 0 THEN
                          CONVERT(
                                     DECIMAL(36, 8),
                                     ((ISNULL(c.未售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.待售面积, 0))
                                      - ISNULL(c.营销费用单方, 0) * ISNULL(c.待售面积, 0) - ISNULL(c.综合管理费单方, 0)
                                      * ISNULL(c.待售面积, 0) - ISNULL(c.税金及附加单方, 0) * ISNULL(c.待售面积, 0)
                                     ) * 0.25
                                 )
                     ELSE 0.0
                 END 未售净利润签约,
               CONVERT(
                          DECIMAL(36, 8),
                          ((ISNULL(c.已售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.已售面积, 0) - ISNULL(c.股权溢价单方, 0)
                            * ISNULL(c.已售面积, 0)
                           ) - ISNULL(c.营销费用单方, 0) * ISNULL(c.已售面积, 0) - ISNULL(c.综合管理费单方, 0)
                           * ISNULL(c.已售面积, 0) - ISNULL(c.税金及附加单方, 0) * ISNULL(c.已售面积, 0)
                          )
                      )
               - CASE
                     WHEN ISNULL(x.项目未售税前利润签约, 0) + ISNULL(x.项目已售税前利润签约, 0) > 0 THEN
                          CONVERT(
                                     DECIMAL(36, 8),
                                     ((ISNULL(c.已售货值不含税, 0) - ISNULL(c.营业成本单方, 0) * ISNULL(c.已售面积, 0))
                                      - ISNULL(c.营销费用单方, 0) * ISNULL(c.已售面积, 0) - ISNULL(c.综合管理费单方, 0)
                                      * ISNULL(c.已售面积, 0) - ISNULL(c.税金及附加单方, 0) * ISNULL(c.已售面积, 0)
                                     ) * 0.25
                                 )
                     ELSE 0.0
                 END 已售净利润签约
        INTO #jlr
        FROM #base c
             LEFT JOIN #xm x ON c.projguid = x.projguid;

        --节点
        SELECT p.TopProjGuid,
               zt.PreSaleProgress 达到预售形象的条件,
               zt.CheckStandard 验收标准,
               zt.DeliverStandard 交付标准,
               jcjh.BuildingGUID GCBldGUID
        INTO #jd
        FROM MyCost_Erp352.dbo.p_HkbBiddingBuildingWork zt
             INNER JOIN MyCost_Erp352.dbo.p_BiddingSection bd ON bd.BidGUID = zt.BidGUID
             INNER JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork jcjh ON jcjh.BudGUID = zt.BuildGUID
             INNER JOIN #p0 p ON p.ProjGUID = bd.ProjGuid;

        -----获取首开数据 begin ------------------ 
        --获取认购的最早录入时间
        SELECT r.BldGUID,
            MIN(o.QSDate) st
        INTO #rg_st
        FROM dbo.s_Order o
            inner JOIN p_room r ON o.RoomGUID = r.RoomGUID
            inner join #ms ms on ms.SaleBldGUID = r.bldguid 
        WHERE o.Status = '激活'
            OR o.CloseReason = '转签约'
        GROUP BY r.BldGUID;

        --获取签约的最早录入时间
        select r.BldGUID,
            MIN(sc.QSDate) st 
        into #qy_st
        from dbo.s_contract sc 
        inner JOIN p_room r ON sc.RoomGUID = r.RoomGUID
        inner join #ms ms on ms.SaleBldGUID = r.bldguid 
        left join #rg_st rg on r.bldguid = rg.bldguid 
        WHERE sc.Status = '激活' and rg.bldguid is null 
        group by r.BldGUID

        --获取合作业绩的最早录入时间 
        SELECT b.bldguid,
            min(CONVERT(VARCHAR(100), CAST(a.DateYear + '-' + a.DateMonth + '-01' AS DATETIME), 23)) AS st 
        into #hz_st
        FROM s_YJRLProducteDetail a
        INNER JOIN s_YJRLBuildingDescript b ON b.ProducteDetailGUID = a.ProducteDetailGUID
        inner join #ms ms on ms.SaleBldGUID = b.bldguid 
        WHERE a.Shenhe = '审核' and b.Amount>0
        group by b.bldguid

        --获取特殊业绩的最早录入时间
        SELECT BldGUID , 
            min(StatisticalDate) as  st
        into #ts_st
        FROM (SELECT b.BldGUID AS BldGUID , 
                a.RdDate AS StatisticalDate 
        FROM   S_PerformanceAppraisal a
        inner join s_TsyjType c on a.YjType = c.TsyjTypeName
        INNER JOIN S_PerformanceAppraisalBuildings b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID 
        inner join #ms ms on ms.SaleBldGUID = b.bldguid 
        WHERE  ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0 or IsCalcYSHL = 0)
                AND a.AuditStatus = '已审核' 
                AND b.BldGUID NOT IN (  SELECT r.BldGUID
                                        FROM   S_PerformanceAppraisalRoom c
                                        inner join S_PerformanceAppraisal s on c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
                                                INNER JOIN dbo.p_room r ON c.RoomGUID = r.RoomGUID
                                                where s.AuditStatus='已审核' )
        UNION ALL
        SELECT ISNULL(rm.BldGUID,r.ProductBldGUID) AS BldGUID ,
                a.RdDate AS StatisticalDate 
        FROM   S_PerformanceAppraisal a
        inner join s_TsyjType b on a.YjType = b.TsyjTypeName
        INNER JOIN S_PerformanceAppraisalRoom c ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
        LEFT JOIN dbo.p_room rm ON rm.RoomGUID = c.RoomGUID
        inner join #ms ms on ms.SaleBldGUID = rm.bldguid 
        --存在允许关联房间的情况
            LEFT JOIN (SELECT roomguid,ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom GROUP BY roomguid,ProductBldGUID ) r ON c.RoomGUID = r.RoomGUID
        WHERE  ISNULL(a.YjType, '') NOT IN  (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0 or IsCalcYSHL = 0)
                AND a.AuditStatus = '已审核'
        ) appraisa
        group by BldGUID

 
        --判断楼栋的首开时间
        select t.bldguid, min(st) as st 
        into #bld_st
        from (
        select bldguid,st from #rg_st
        union 
        select bldguid,st from #qy_st
        union 
        select bldguid,st from #hz_st
        union 
        select bldguid,st from #ts_st) t
        group by bldguid;

 
        --判断项目层级的楼栋首开
        select pj.parentprojguid as projguid,min(st.st) as st 
        into #proj_st 
        from mdm_salebuild sb 
        inner join mdm_gcbuild gc on sb.GCBldGUID = gc.GCBldGUID
        inner join mdm_project pj on pj.projguid = gc.projguid
        left join #bld_st st on sb.SaleBldGUID = st.bldguid
        group by pj.parentprojguid

 
        --获取首开楼栋的范围
        select bld.bldguid,proj.st 
        into #bld_lst
        from #bld_st bld 
        inner join mdm_salebuild sb on sb.SaleBldGUID =bld.BldGUID
        inner join mdm_gcbuild gc on sb.GCBldGUID = gc.GCBldGUID
        inner join mdm_project pj on pj.projguid = gc.projguid
        inner join #proj_st proj on proj.projguid = pj.parentprojguid
        where datediff(dd,proj.st, bld.st) = 0

 
        --获取首开楼栋的销售情况
        select t.bldguid,t.st,
        sum(isnull(首开30天签约套数,0)) as 首开30天签约套数,
        sum(isnull(首开30天签约面积,0)) as 首开30天签约面积,
        sum(isnull(首开30天签约金额,0)) as 首开30天签约金额,
        sum(isnull(首开30天认购套数,0)) as 首开30天认购套数,
        sum(isnull(首开30天认购面积,0)) as 首开30天认购面积,
        sum(isnull(首开30天认购金额,0)) as 首开30天认购金额
        into #ld_st_sale
        from (
        select ld.bldguid, ld.st,
            0 首开30天签约套数,
            0 首开30天签约面积,
            0 首开30天签约金额,
            count(1) 首开30天认购套数,
            sum(r.bldarea) 首开30天认购面积,
            sum(o.jytotal) 首开30天认购金额 
        from #bld_lst ld
        inner JOIN p_room r ON ld.bldguid = r.bldguid
        left join dbo.s_Order o on r.roomguid = o.roomguid 
        WHERE (o.Status = '激活'
            OR o.CloseReason = '转签约') and datediff(dd,ld.st,o.qsdate) BETWEEN 0 and 30
        group by ld.bldguid,ld.st
        union all 
        select ld.bldguid,ld.st,
            count(1) 首开30天签约套数,
            sum(r.bldarea) 首开30天签约面积,
            sum(sc.jytotal) 首开30天签约金额,
            0 首开30天认购套数,
            0 首开30天认购面积,
            0 首开30天认购金额 
        from #bld_lst ld
        inner JOIN p_room r ON ld.bldguid = r.bldguid
        left join dbo.s_contract sc on r.roomguid = sc.roomguid 
        WHERE sc.Status = '激活' and datediff(dd,ld.st,sc.qsdate) BETWEEN 0 and 30
        group by ld.bldguid,ld.st
        union all 
        --获取合作业绩的最早录入时间 
        SELECT ld.bldguid,ld.st,
            sum(b.Taoshu) 首开30天签约套数,
            sum(b.Area) 首开30天签约面积,
            sum(b.amount*10000.0) 首开30天签约金额,
            sum(b.Taoshu) 首开30天认购套数,
            sum(b.Area) 首开30天认购面积,
            sum(b.amount*10000.0) 首开30天认购金额
        FROM #bld_lst ld
        INNER JOIN s_YJRLBuildingDescript b on ld.bldguid = b.bldguid
        inner join s_YJRLProducteDetail a ON b.ProducteDetailGUID = a.ProducteDetailGUID
        WHERE a.Shenhe = '审核' and datediff(dd,ld.st,CONVERT(VARCHAR(100), CAST(a.DateYear + '-' + a.DateMonth + '-01' AS DATETIME), 23)) between 0 and 30
        group by ld.bldguid,ld.st
        --获取特殊业绩的
        union all 
        SELECT ld.bldguid,ld.st,
            sum(b.AffirmationNumber) 首开30天签约套数,
            sum(b.IdentifiedArea) 首开30天签约面积,
            sum(b.AmountDetermined*10000.0) 首开30天签约金额,
            sum(b.AffirmationNumber) 首开30天认购套数,
            sum(b.IdentifiedArea) 首开30天认购面积,
            sum(b.AmountDetermined*10000.0) 首开30天认购金额
        FROM  #bld_lst ld
        inner join S_PerformanceAppraisalBuildings B on ld.bldguid = b.bldguid
        inner join S_PerformanceAppraisal a ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID 
        inner join s_TsyjType c on a.YjType = c.TsyjTypeName
        WHERE  ISNULL(a.YjType, '') NOT IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0 or IsCalcYSHL = 0)
        AND a.AuditStatus = '已审核' 
        AND b.BldGUID NOT IN (  SELECT r.BldGUID
                                    FROM   S_PerformanceAppraisalRoom c
                                inner join S_PerformanceAppraisal s on c.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
                                        INNER JOIN dbo.p_room r ON c.RoomGUID = r.RoomGUID
                                        where s.AuditStatus='已审核' )
        and datediff(dd,ld.st,a.RdDate) between 0 and 30
        group by ld.bldguid,ld.st
        UNION ALL
        SELECT ld.bldguid,ld.st,
            sum(c.AffirmationNumber) 首开30天签约套数,
            sum(c.IdentifiedArea) 首开30天签约面积,
            sum(c.AmountDetermined*10000.0) 首开30天签约金额,
            sum(c.AffirmationNumber) 首开30天认购套数,
            sum(c.IdentifiedArea) 首开30天认购面积,
            sum(c.AmountDetermined*10000.0) 首开30天认购金额
        FROM  #bld_lst ld
        inner JOIN dbo.p_room rm on ld.bldguid = rm.bldguid
        INNER JOIN S_PerformanceAppraisalRoom c  ON rm.RoomGUID = c.RoomGUID
        inner join  S_PerformanceAppraisal a ON c.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
        inner join s_TsyjType b on a.YjType = b.TsyjTypeName
        --存在允许关联房间的情况
        LEFT JOIN (SELECT roomguid,ProductBldGUID FROM dbo.md_PerformanceAppraisalRoom GROUP BY roomguid,ProductBldGUID ) r ON c.RoomGUID = r.RoomGUID
        WHERE  ISNULL(a.YjType, '') NOT IN  (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom =0 or IsCalcYSHL = 0)
            AND a.AuditStatus = '已审核'     and datediff(dd,ld.st,a.RdDate) between 0 and 30
        group by ld.bldguid,ld.st) T
        group by t.bldguid   ,t.st

        -----获取首开数据   end ------------------
        
        -----2024年签约数据 begin
            select c.TradeGUID
            INTO #con2024
            from s_contract c 
            where YEAR(c.QSDate) = 2024
            and c.Status = '激活'

            SELECT v.TradeGUID,
            SUM(CASE WHEN ItemName LIKE '%补差%' THEN Amount ELSE 0 END) bck
            INTO #feebck
            FROM s_Fee s
            INNER JOIN #con2024 v ON s.TradeGUID = v.TradeGUID
            WHERE s.ItemType = '非贷款类房款'
            GROUP BY v.TradeGUID;
            
            select r.BldGUID ,
            count(*) ts,
            sum(a.bldarea)/10000 bldarea,
            sum(a.jytotal+isnull(c.bck,0))/10000 total
            INTO #con
            from s_contract a 
            left join p_room r on a.RoomGUID = r.RoomGUID
            inner join #con2024 b on a.TradeGUID = b.TradeGUID
            left join #feebck c on a.TradeGUID = c.TradeGUID
            where a.Status = '激活'
            GROUP BY r.BldGUID 
        ------2024年签约数据 end

        --产值
        --先计算出每个产品楼栋按建筑面积分摊的比例
        select sb.SaleBldGUID, sb.GCBldGUID, 
        convert(decimal(16,8),case when (isnull(gc.UpBuildArea,0)+isnull(gc.DownBuildArea,0)) =0 then 0
          else (sb.UpBuildArea+sb.DownBuildArea)*1.0 / (isnull(gc.UpBuildArea,0)+isnull(gc.DownBuildArea,0)) end) as 分摊比例
        into #cz_rate
        from mdm_salebuild sb 
        inner join mdm_GCBuild gc on sb.GCBldGUID = gc.GCBldGUID

        
        SELECT l.projguid,
        r.BldGUID ,
        sum(r.bldarea) / 3 近三月签约面积平均,
        sum(r.bldarea) 近三月签约面积,
        sum(case when hz.PhyAddress = '地上' then r.bldarea else 0 end ) 近三月地上签约面积
        into #BASE2
        from s_Contract a
        left join p_room r on a.RoomGUID = r.RoomGUID
        LEFT JOIN p_lddb l ON r.bldguid=l.salebldguid AND DATEDIFF(dd,qxdate,GETDATE()) =0 
        left JOIN #hz hz on hz.ProjGUID = l.ProjGUID and hz.SaleBldGUID = l.SaleBldGUID
        where (1=1)
        and a.Status = '激活'
        and datediff(dd,a.qsdate,getdate()) <= 180
        and r.IsVirtualRoom = 0
        group by  l.projguid,
        r.BldGUID 

        SELECT --dv.DevelopmentCompanyGUID OrgGUID,
               --@VersionGUID VersionGUID,
               p.ProjGUID,
               ms.SaleBldGUID,
               CONVERT(VARCHAR(100), lb.LbProjectValue) 投管代码,
               p.ProjName 项目名称,
               p.ProjStatus 项目类型,
               dv.DevelopmentCompanyName 平台公司,
               hz.城市,
               p.GQRatio 项目股权比例,
               p.TradersWay 操盘方式,
               p.BbWay 并表方式,
               convert(varchar(10),p.AcquisitionDate,120) 获取时间,
               ms.gcBldName 工程楼栋名称,
               ms.ProductType 产品类型,
               ms.ProductName 产品名称,
               convert(varchar(10),hz.SJzskgdate,120) 实际开工完成日期,
               convert(varchar(10),hz.SjDdysxxDate,120) 达到预售形象完成日期,
               convert(varchar(10),hz.SJjgbadate,120) 竣工备案完成日期,
               ms.zjm 项目总建筑面积,
               ms.dsjm 项目地上总建筑面积,
               hz.总可售面积,
               hz.地上总可售面积 项目地上总可售面积,
               hz.地上已售面积 项目地上已售面积,
               hz.地上待售面积 项目地上未售面积,
               case when hz.SJzskgdate is null --未开工
                    then hz.地上待售面积 
                    else 0 
                    end 未开工地上待售面积,
                    
                    case when ms.ProductType in ('住宅','高级住宅') then 
                        case when hz.SJzskgdate is null --未开工
                            then hz.地上待售面积 
                            else 0 
                            end 
                    else 0 end 未开工地上待售面积住宅,

                
                    case when ms.ProductType not in ('住宅','高级住宅') then 
                        case when hz.SJzskgdate is null --未开工
                            then hz.地上待售面积 
                            else 0 
                            end 
                    else 0 end 未开工地上待售面积商办及其他业态,

                tag.BuildTagValue 赛道标签,

               case when hz.SJzskgdate is not null --已开工
                        and hz.SjDdysxxDate is null --未达预售
                    then hz.地上待售面积 
                    else 0 
                    end 已开工未达预售地上待售面积,

               case when hz.SJzskgdate is not null --已开工
                        and hz.SjDdysxxDate is not null --已达预售
                        and hz.SJjgbadate is null --未完工
                    then hz.地上待售面积 
                    else 0 
                    end 已达预售未完工地上待售面积,

               case when hz.SJzskgdate is not null --已开工
                        and hz.SjDdysxxDate is not null --已达预售
                        and hz.SJjgbadate is not null --已竣工
                    then hz.地上待售面积 
                    else 0 
                    end 已竣备地上待售面积,
                hz.地上待售面积 - 
                (case when hz.SJzskgdate is null --未开工
                    then hz.地上待售面积 
                    else 0 
                    end) 已开工待售地上面积,
               BA.近三月地上签约面积,
               BA.近三月地上签约面积/6 近三月平均流速,
               case when (BA.近三月地上签约面积/6) = 0 
                    then 0
                    else (hz.地上待售面积 - 
                            (case when hz.SJzskgdate is null --未开工
                                then hz.地上待售面积 
                                else 0 
                                end)
                            )/(BA.近三月地上签约面积/6)
                    end 产销比,
               case when isnull(hz.总可售面积,0) = 0 then 0 else datediff(dd,hz.SJzskgdate,hz.SjDdysxxDate)/30.0 end 历史供货周期,

               hz.首开整体工期 标准工期历史供货周期,
               case when
                (case when isnull(hz.总可售面积,0) = 0 then 0 else datediff(dd,hz.SJzskgdate,hz.SjDdysxxDate)/30.0 end)  is null
                or abs( (case when isnull(hz.总可售面积,0) = 0 then 0 else datediff(dd,hz.SJzskgdate,hz.SjDdysxxDate)/30.0 end) 
                - hz.首开整体工期 ) >2 then '是' 
                else '否' 
                end 汇报时间是否存在异常,
                case when 
                (case when isnull(hz.总可售面积,0) = 0 then 0 else datediff(dd,hz.SJzskgdate,hz.SjDdysxxDate)/30.0 end)  is null
                or abs( (case when isnull(hz.总可售面积,0) = 0 then 0 else datediff(dd,hz.SJzskgdate,hz.SjDdysxxDate)/30.0 end) 
                - hz.首开整体工期 ) >2 then hz.首开整体工期 
                else (case when isnull(hz.总可售面积,0) = 0 then 0 else datediff(dd,hz.SJzskgdate,hz.SjDdysxxDate)/30.0 end)  
                end 最终历史供货周期,
               case when (
                case when (BA.近三月地上签约面积/6) = 0 
                    then 0
                    else (hz.地上待售面积 - 
                            (case when hz.SJzskgdate is null --未开工
                                then hz.地上待售面积 
                                else 0 
                                end)
                            )/(BA.近三月地上签约面积/6)
                    end
               )<= datediff(dd,hz.SJzskgdate,hz.SjDdysxxDate) then '是' 
               else '否'
               end 项目是否存在缺货
        into #result
        FROM #ms ms
             LEFT JOIN #p p ON ms.TopProjGuid = p.ProjGUID
             LEFT JOIN dbo.p_DevelopmentCompany dv ON dv.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
             LEFT JOIN mdm_LbProject lb ON lb.projGUID = p.ProjGUID
                                           AND lb.LbProject = 'tgid'
             LEFT JOIN #hz hz ON hz.SaleBldGUID = ms.SaleBldGUID
             LEFT JOIN #BASE2 BA ON BA.BldGUID = ms.SaleBldGUID
             left join mdm_BuildTag tag on tag.SaleBldGUID = ms.salebldguid and buildtag = 'SDT' 
        ORDER BY dv.DevelopmentCompanyName,p.ProjCode;
        
        select ProjGUID,count(*) totalnum
        into #bldtotal
        from #result 
        where 实际开工完成日期 is null --未开工
        group by 
        ProjGUID

        select a.ProjGUID,case when isnull(赛道标签,'') = '' then '无标签' else 赛道标签 end 赛道标签,
        case when isnull(赛道标签,'') = '' then '无标签' else 赛道标签 end+' '+
        convert(varchar,cast(count(*)*1.0 /b.totalnum*1.0 * 100 as decimal(18,0)) ) + '%' 赛道占比
        into #tag
        from #result a
        left join #bldtotal b on a.ProjGUID = b.ProjGUID
        where a.实际开工完成日期 is null --未开工
        group by 
        a.ProjGUID,
        case when isnull(赛道标签,'') = '' then '无标签' else 赛道标签 end ,b.totalnum
        order by a.ProjGUID
--      drop table #result,#tag,#bldtotal
    
       -- 清理数据
       TRUNCATE TABLE 正常补货项目清单
      -- 查询项目明细
      insert into  正常补货项目清单
        select 
            ProjGUID,
            投管代码,
            项目名称,
            项目类型,
            平台公司,
            城市,
            项目股权比例,
            操盘方式,
            并表方式,
            获取时间,
            sum(项目总建筑面积) 项目总建筑面积,
            sum(项目地上总建筑面积) 项目地上总建筑面积,
            sum(项目地上总可售面积) 项目地上总可售面积,
            sum(项目地上已售面积) 项目地上已售面积,
            sum(项目地上未售面积) 项目地上未售面积,
            sum(未开工地上待售面积) 未开工地上待售面积,
            case when sum(未开工地上待售面积) = 0 then 0 
                 else sum(未开工地上待售面积住宅)/sum(未开工地上待售面积) 
            end 未开工地上待售面积住宅占比,
            case when sum(未开工地上待售面积) = 0 then 0 
                 else sum(未开工地上待售面积商办及其他业态)/sum(未开工地上待售面积) 
            end 未开工地上待售面积商办及其他业态占比,
            (select 赛道占比+';' from #tag a where a.ProjGUID = #result.ProjGUID order by 赛道标签 for xml path('')) 未开工楼栋赛道标签占比,
            sum(已开工未达预售地上待售面积) 已开工未达预售地上待售面积,
            sum(已达预售未完工地上待售面积) 已达预售未完工地上待售面积,
            sum(已竣备地上待售面积) 已竣备地上待售面积,
            sum(项目地上未售面积) - sum(未开工地上待售面积) 已开工待售地上面积,
            sum(近三月地上签约面积) 近三月地上签约面积,
            sum(近三月地上签约面积)/6 近三月平均流速,
            case when sum(近三月地上签约面积)/6 = 0 then 0 
                 else (sum(项目地上未售面积) - sum(未开工地上待售面积)) / (sum(近三月地上签约面积)/6)
            end 产销比,

            case when sum(case when isnull(总可售面积,0) = 0 then 0 else 1 end) = 0 then 0 
                 else sum(case when isnull(总可售面积,0) = 0 then 0 else 历史供货周期 end)/
                      sum(case when isnull(总可售面积,0) = 0 or 历史供货周期 is null then 0 else 1 end) 
            end 历史供货周期,
            case when sum(case when isnull(总可售面积,0) = 0 then 0 else 1 end) = 0 then 0 
                 else sum(case when isnull(总可售面积,0) = 0 then 0 else 标准工期历史供货周期 end)/
                      sum(case when isnull(总可售面积,0) = 0 or 标准工期历史供货周期 is null then 0 else 1 end) 
            end 标准工期历史供货周期,
            case when sum(case when isnull(总可售面积,0) = 0 then 0 else 1 end) = 0 then 0 
                 else sum(case when isnull(总可售面积,0) = 0 then 0 else 最终历史供货周期 end)/
                      sum(case when isnull(总可售面积,0) = 0 or 最终历史供货周期 is null then 0 else 1 end) 
            end 最终历史供货周期,
            case when (
                    case when sum(近三月地上签约面积)/6 = 0 then 0 
                         else (sum(项目地上未售面积) - sum(未开工地上待售面积)) / (sum(近三月地上签约面积)/6)
                    end
                ) <= sum(最终历史供货周期)/count(工程楼栋名称) 
                 then '是'
                 else '否'
            end 项目是否存在缺货,
            case when (select 1 
                       from #tag a 
                       where a.ProjGUID = #result.ProjGUID 
                         and a.赛道标签 not in ('A-销售','B3-调规') 
                       order by 赛道标签 
                       for xml path('')) is not null 
                 then '是' 
                 else '否' 
            end 是否含存在异常标签
        -- into 正常补货项目清单
        from #result 
        where isnull(项目地上未售面积,0) <> 0
        group by 
            projguid,
            投管代码,
            项目名称,
            项目类型,
            平台公司,
            城市,
            项目股权比例,
            操盘方式,
            并表方式,
            获取时间

        -- 清理数据
        TRUNCATE TABLE 正常补货项目产品楼栋清单
        -- 查询楼栋明细
        insert into 正常补货项目产品楼栋清单
        select * 
       --  into 正常补货项目产品楼栋清单 
        from #result
       -- DROP TABLE #jd,#p,#p0,#hz,#ms,#st,#base,#bnqy,#df,#hlpp_bld,#hlpp_product,#jlr,#key,#xm,
       --            #dfhz,#bld_lst,#bld_st,#con,#con2024,#feebck,#hz_st,#ld_rate,#ld_st_sale,
                   --#proj_rate,#proj_st,#qy_st,#rg_st,#t,#ts_st,#vrt,#cz_rate,#BASE2,#bldtotal,#result,#tag;
                   
    END;
END;
