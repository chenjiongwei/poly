
http://172.16.8.132/Cbgl/HYGH/BudgetView_Grid.aspx?projGUID=88de444d-5e7d-495c-bc97-4a3a5eedab24&Type=ALL&funcid=02010205&projCode=0048.0024024.002&BudgetName=

USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_F056各项目产品楼栋表系统取数原始表单]    Script Date: 2025/4/24 17:07:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_s_F056各项目产品楼栋表系统取数原始表单]
(
    @var_buguid VARCHAR(MAX),
    @Date DATETIME = NULL,
    @VersionGUID VARCHAR(40) = '',
    @IsNew INT = 0
)
AS
/***********************************************                            
*函数功能:F056各项目产品楼栋表系统取数原始表单                      
*输入参数:                            
    @var_buguid，界面选择的平台公司GUID                                          
     exec [usp_s_F056各项目产品楼栋表系统取数原始表单] '5A4B2DEF-E803-49F8-9FE2-308735E7233D'
Create by yp

modified by lintx 20240813
增加首开指标：首开标识、首开30天内签约/认购面积、套数、金额

modified by lintx 20250327
增加经营成本单方

modified by lintx 20250402
1、新增指标:
产值信息：已完成产值金额，合同约定应付金额，累计支付金额，产值未付，应付未付
持有信息：持有套数	持有面积
占压投资：土地分摊金额	除地价外直投分摊金额	已发生营销费用摊分金额	已发生管理费用摊分金额	已发生财务费用费用摊分金额	已发生税金分摊
结转信息：已结转套数	已结转面积	已结转收入	已结转成本
***********************************************/
BEGIN
    --首先判断是否存在版本，如果是实时查询就是默认值，如果点击拍照版本，就不是默认值
    IF @VersionGUID = '默认值'
       OR @VersionGUID = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SET @VersionGUID = NULL;
    END;

    --判断查询日期，是否存在拍照数据，如果存在，则获取拍照版本表中的版本数据，不存在则实收获取
    IF (ISNULL(@VersionGUID, '') <> '' AND @IsNew = 0)
    BEGIN
        SELECT OrgGuid,
               VersionGuid,
               平台公司,
               项目名称,
               项目推广名,
               明源系统代码,
               项目代码,
               获取时间,
               总地价,
               是否合作项目,
               分期名称,
               产品楼栋名称,
               SaleBldGUID,
               GCBldGUID,
               工程楼栋名称,
               产品类型,
               产品名称,
               商品类型,
               是否可售,
               是否持有,
               装修标准,
               地上层数,
               地下层数,
               达到预售形象的条件,
               实际开工计划日期,
               实际开工完成日期,
               达到预售形象计划日期,
               达到预售形象完成日期,
               预售办理计划日期,
               预售办理完成日期,
               竣工备案计划日期,
               竣工备案完成日期,
               集中交付计划日期,
               集中交付完成日期,
               立项均价,
               立项货值,
               定位均价,
               定位货值,
               总建面,
               地上建面,
               地下建面,
               总可售面积,
               动态总货值,
               整盘均价,
               已售面积,
               已售货值,
               已售均价,
               待售面积,
               待售货值,
               预测单价,
               年初可售面积,
               年初可售货值,
               本年签约面积,
               本年签约金额,
               本年签约均价,
               本月签约面积,
               本月签约金额,
               本月签约均价,
               本年预计签约面积,
               本年预计签约金额,
               正式开工实际完成时间,
               正式开工预计完成时间,
               待售套数,
               总可售套数,
               首推时间,
               --新增字段
               业态组合键,
               营业成本单方,
               土地款单方,
               除地价外直投单方,
               资本化利息单方,
               开发间接费单方,
               营销费用单方,
               综合管理费单方,
               税金及附加单方,
               股权溢价单方,
               总成本不含税单方,
               已售对应总成本,
               已售货值不含税,
               已售净利润签约,
               未售对应总成本,
               近三月签约金额均价不含税,
               近六月签约金额均价不含税,
               立项单价,
               定位单价,
               已售均价不含税,
               货量铺排均价计算方式,
               未售货值不含税,
               未售净利润签约,
               项目已售税前利润签约,
               项目未售税前利润签约,
               项目整盘利润,
               货值铺排均价不含税,
               --20240524新增字段
               已售套数,
               近三月签约金额不含税,
               近三月签约面积,
               近六月签约金额不含税,
               近六月签约面积,
			   ztguid,
			   是否停工,
               --20240813新增指标 
               项目首推时间,
               首开楼栋标签,
               首开30天签约套数,
               首开30天签约面积,
               首开30天签约金额,
               首开30天认购套数,
               首开30天认购面积,
               首开30天认购金额, 
               --20250402新增指标
               已完成产值,
               合同约定应付金额,
               累计支付金额,
               产值未付,
               应付未付,
               持有套数,
               持有面积,
               土地分摊金额,
               除地价外直投分摊金额,
               已发生营销费用摊分金额,
               已发生管理费用摊分金额,
               已发生财务费用费用摊分金额,
               已发生税金分摊,
               已结转套数,
               已结转面积,
               已结转收入,
               已结转成本,
               签约套数2024年,	
               签约面积2024年,	
               签约金额2024年,	
               签约均价2024年,
               经营成本单方,
               赛道图标签
        FROM [dss].dbo.nmap_s_F056各项目产品楼栋表系统取数原始表单
        WHERE VersionGuid = @VersionGUID
              AND OrgGuid IN (
                                 SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                             );
    END;
    --实收获取报表的数据逻辑
    ELSE
    BEGIN
		--declare @VersionGUID VARCHAR(40)
        SET @VersionGUID = NEWID();
       -- DECLARE @var_buguid VARCHAR(MAX) = '5A4B2DEF-E803-49F8-9FE2-308735E7233D';

        SELECT p.*
        INTO #p
        FROM mdm_Project p
        WHERE 1 = 1
              AND p.DevelopmentCompanyGUID IN (
                                                  SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                                              )
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
FROM dbo.mdm_SaleBuild ms
     INNER JOIN mdm_Product pr ON pr.ProductGUID = ms.ProductGUID
     INNER JOIN mdm_GCBuild gc ON gc.GCBldGUID = ms.GCBldGUID
     INNER JOIN #p0 p ON p.ProjGUID = gc.ProjGUID
     LEFT JOIN #st st ON ISNULL(ms.ImportSaleBldGUID, ms.SaleBldGUID) = st.BldGUID
     LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b ON ms.GCBldGUID = b.BuildingGUID
     LEFT JOIN MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport c ON b.budguid = c.ztguid;
 
        --货值
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
               CASE
                   WHEN ld.zksmj = 0 THEN
                        0
                   ELSE ld.zhz / ld.zksmj
               END 整盘均价,
               ld.ysmj * 1.0 已售面积,
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
               ld.zksmj * 1.0 - ld.ysmj * 1.0 待售面积,
               ld.syhz 待售货值,
			   CASE when isnull(ldr.VATRate,isnull(pdr.VATRate,''))<>'' then ld.syhz / (1 + isnull(ldr.VATRate,isnull(pdr.VATRate,'')))
                   ELSE ld.syhz / (1 + 0.09)
               END as 待售货值不含税, 
               ld.YcPrice 预测单价,
               ld.BeginYearSaleMj,
               ld.BeginYearSaleJe,
               ld.ThisYearSaleMjQY,
               ld.ThisYearSaleJeQY,
               CASE
                   WHEN ld.ThisYearSaleMjQY = 0 THEN
                        0
                   ELSE ld.ThisYearSaleJeQY / ld.ThisYearSaleMjQY
               END 本年签约均价,
               ld.ThisMonthSaleMjQY,
               ld.ThisMonthSaleJeQY,
               CASE
                   WHEN ld.ThisMonthSaleMjQY = 0 THEN
                        0
                   ELSE ld.ThisMonthSaleJeQY / ld.ThisMonthSaleMjQY
               END 本月签约均价
        INTO #hz
        FROM dbo.p_lddbamj ld
            INNER JOIN #p p ON p.ProjGUID = ld.ProjGUID
			left join #ld_rate ldr on ldr.BldGUID = ld.SaleBldGUID
            left join #proj_rate pdr on pdr.projguid = ld.projguid
        WHERE DATEDIFF(d, QXDate, GETDATE()) = 0;

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
            AND a.AuditStatus = '已审核'	  and datediff(dd,ld.st,a.RdDate) between 0 and 30
        group by ld.bldguid,ld.st) T
        group by t.bldguid	 ,t.st

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

		--获取项目已审核的最晚回顾时间记录
        select * 
        into #OutputValuebb
        from (
        select projguid,ROW_NUMBER() over(PARTITION BY projguid order by ReviewDate desc) as RowNum,OutputValueMonthReviewGUID 
        from MyCost_Erp352.dbo.cb_OutputValueMonthReview where ApproveState in ('已审核','审核中')) t where t.RowNum = 1

        SELECT ISNULL(a.Xmpdljwccz, 0)*分摊比例 AS 已完成产值, 
        ISNULL(a.Ljyfkje, 0)*分摊比例 AS 合同约定应付金额,
        ISNULL(a.Ljsfk, 0)*分摊比例 AS 累计支付金额,
        (isnull(a.Xmpdljwccz,0) - ISNULL(a.Ljsfk, 0))*分摊比例 AS 产值未付,
        ISNULL(a.Ljyfkje, 0)*分摊比例 - ISNULL(a.Ljsfk, 0)*分摊比例 AS 应付未付,
        r.salebldguid as bldguid
        into #ldcz
        FROM (
            SELECT   
                    SUM(ISNULL(b.Xmpdljwccz, 0)) AS Xmpdljwccz, 
                    SUM(ISNULL(b.Ljyfkje, 0)) AS Ljyfkje,
                    SUM(ISNULL(b.Ljsfk, 0)) AS Ljsfk,
                    BldGUID
            FROM mycost_erp352.dbo.cb_OutputValueReviewDetail a with(nolock) 
                INNER JOIN mycost_erp352.dbo.cb_OutputValueReviewBld b with(nolock) ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
				inner join #OutputValuebb t on t.OutputValueMonthReviewGUID = a.OutputValueMonthReviewGUID
            WHERE (1=1) AND (2=2) 
            GROUP BY b.BldGUID
        ) a  
        inner join #cz_rate r on a.bldguid = r.GCBldGUID 
        inner join #ms ms with(nolock) on ms.SaleBldGUID = r.SaleBldGUID  

        SELECT a.ProductBldGUID as bldguid,  
        sum(a.bldarea)/10000.0 持有面积, 
        count(1) 持有套数
        into #zs_area
        FROM mycost_erp352.dbo.md_Room a with(nolock)
        inner join #ms ms with(nolock) on ms.SaleBldGUID = a.ProductBldGUID
        where isnull(UseProperty,'') in ('经营','留存自用')
        group BY a.ProductBldGUID
        union all 
        select ms.SaleBldGUID,
        sum(zjm) as 持有面积,
        sum(HouseNum) as 持有套数 
        from #ms ms with(nolock)
        where IsHold = '是' and not exists (select 1 from mycost_erp352.dbo.md_Room where ProductBldGUID = ms.SaleBldGUID)
		group by  ms.SaleBldGUID

        --取基础数据中间表对应的可售面积及自持面积情况 
        SELECT ms.TopProjGuid projguid,  ms.salebldguid,
        sum(a.HoldArea) 自持面积, 
        sum(a.SaleArea) 可售面积
        into #mj
        FROM mycost_erp352.dbo.vs_md_productbuild_getAreaAndSpaceNumInfo a with(nolock) 
        inner join #ms ms with(nolock) on ms.SaleBldGUID = a.ProductBuildGUID 
        group BY ms.TopProjGuid,ms.salebldguid

        --获取表七的三费+税金情况
        SELECT p.ProjGUID,
        a.[累计管理费用（万元）] as 累计管理费用,
        a.[累计营销费用（万元）] as 累计营销费用,
        a.[累计财务费用（万元）] as 累计财务费用,
        a.[累计税金（万元）] as 累计税金
        into #sftax
        FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a with(nolock)
        INNER JOIN #p p with(nolock) ON a.BusinessGUID = p.ProjGUID
        INNER JOIN ( SELECT TOP 1 a.FillHistoryGUID
                          FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a with(nolock)
                               INNER JOIN dss.dbo.nmap_F_FillHistory b with(nolock) ON a.FillHistoryGUID = b.FillHistoryGUID
                          WHERE b.ApproveStatus = '已审核'
                          ORDER BY b.BeginDate DESC
                      ) F ON F.FillHistoryGUID = a.FillHistoryGUID
        
        --获取楼栋的销售结转情况
        select r.BldGUID, count(1) as 已结转套数,
        sum(r.BldArea)/10000.0 as 已结转面积,
        sum(JzAmount)/10000.0 as 已结转收入
        into #xsjz
        from erp25.dbo.s_Trade st with(nolock)
        inner join erp25.dbo.p_room r with(nolock) on st.RoomGUID = r.RoomGUID
        inner join #ms ms with(nolock) on ms.SaleBldGUID = r.BldGUID
        where jzdate is not null and isnull(YJ_TradeStatus,'')='激活'
        group by r.BldGUID
    
        --获取主营业务成本
        select * 
        into #CarryOverMbb
        from (
        select projguid,ROW_NUMBER() over(PARTITION BY projguid order by ApproveDate desc) as RowNum,CarryOverMainGUID 
        from [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain with(nolock) where ApproverState = '已审核') t where t.RowNum = 1
 
        select  ld.SaleBldGUID as bldguid,
        sum(CASE WHEN e.CarryOverMainGUID IS NOT NULL THEN ISNULL(d.TotalMoney,0) ELSE  ISNULL(b.TotalMoney, 0) END)/10000.0 AS 已结转成本 
        into #jzcb
        from  erp25.dbo.mdm_SaleBuild ld with(nolock)
        inner join erp25.dbo.mdm_GCBuild gc with(nolock) on gc.GCBldGUID = ld.GCBldGUID
        left join #CarryOverMbb bb with(nolock) on bb.projguid = gc.projguid
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSetBldDtl b with(nolock) ON  ld.SaleBldGUID = b.BldGUID AND  b.Subject = 4
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSet c with(nolock) on b.CarryOverMainSetGUID = c.CarryOverMainSetGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d with(nolock) ON  ld.SaleBldGUID = d.BldGUID AND d.Subject = 4 and d.CarryOverMainGUID = bb.CarryOverMainGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain e with(nolock) on d.CarryOverMainGUID = e.CarryOverMainGUID
        -- where gc.ProjGUID = '116A20D9-2A43-E811-80BA-E61F13C57837'
		group by ld.SaleBldGUID


        SELECT dv.DevelopmentCompanyGUID OrgGUID,
               @VersionGUID VersionGUID,
               dv.DevelopmentCompanyName 平台公司,
               p.ProjName 项目名称,
               p.SpreadName 项目推广名,
               CONVERT(VARCHAR(100), p.ProjCode) 明源系统代码,
               CONVERT(VARCHAR(100), lb.LbProjectValue) 项目代码,
               p.AcquisitionDate 获取时间,
               p.TotalLandPrice / 100000000 总地价,
               CASE
                   WHEN ISNULL(p.PartnerName, '') = ''
                        OR p.PartnerName LIKE '%保利%' THEN
                        '否'
                   ELSE '是'
               END 是否合作项目,
               ms.fq 分期名称,
               ms.BldCode 产品楼栋名称,
               ms.SaleBldGUID,
               ms.GCBldGUID,
               ms.gcBldName 工程楼栋名称,
               ms.ProductType 产品类型,
               ms.ProductName 产品名称,
               ms.BusinessType 商品类型,
               ms.IsSale 是否可售,
               ms.IsHold 是否持有,
               ms.Standard 装修标准,
               ms.UpNum 地上层数,
               ms.DownNum 地下层数,
               jd.达到预售形象的条件,
               hz.YJzskgdate 实际开工计划日期,
               hz.SJzskgdate 实际开工完成日期,
               hz.YjDdysxxDate 达到预售形象计划日期,
               hz.SjDdysxxDate 达到预售形象完成日期,
               hz.YjYsblDate 预售办理计划日期,
               hz.SjYsblDate 预售办理完成日期,
               hz.YJjgbadate 竣工备案计划日期,
               hz.SJjgbadate 竣工备案完成日期,
               hz.JzjfYjdate 集中交付计划日期,
               hz.JzjfSjdate 集中交付完成日期,
               hz.LxPrice 立项均价,
               hz.lxHz / 10000 立项货值,
               hz.DwPrice 定位均价,
               hz.dwHz / 10000 定位货值,
               ms.zjm 总建面,
               ms.dsjm 地上建面,
               ms.dxjm 地下建面,
               hz.总可售面积 / 10000.0 总可售面积,
               hz.动态总货值 / 10000 动态总货值,
               hz.整盘均价,
               hz.已售面积 / 10000.0 已售面积,
               hz.已售货值 / 10000 已售货值,
               hz.已售均价,
               hz.待售面积 / 10000.0 待售面积,
               hz.待售货值 / 10000 待售货值,
               hz.预测单价,
               hz.BeginYearSaleMj / 10000 年初可售面积,
               hz.BeginYearSaleJe / 10000 年初可售货值,
               hz.ThisYearSaleMjQY / 10000 本年签约面积,
               hz.ThisYearSaleJeQY / 10000 本年签约金额,
               hz.本年签约均价,
               hz.ThisMonthSaleMjQY / 10000 本月签约面积,
               hz.ThisMonthSaleJeQY / 10000 本月签约金额,
               hz.本月签约均价,
                case when ms.ProductType='地下室/车库' then bnqy.本年签约面积 else bnqy.本年签约面积 / 10000  end 本年预计签约面积 ,
               bnqy.本年签约金额 / 10000 本年预计签约金额,
               hz.SGZsjdate 正式开工实际完成时间,
               hz.SGZyjdate 正式开工预计完成时间,
               hz.待售套数,
               hz.总可售套数,
               ms.st 首推时间,
               --新增字段
               BA.盈利规划主键 业态组合键,
               BA.营业成本单方,
               BA.土地款单方,
               BA.除地价外直投单方,
               BA.资本化利息单方,
               BA.开发间接费单方,
               BA.营销费用单方,
               BA.综合管理费单方,
               BA.税金及附加单方,
               BA.股权溢价单方,
               BA.总成本不含税 总成本不含税单方,
               BA.已售对应总成本 / 10000.0 已售对应总成本,
               BA.已售货值不含税 / 10000.0 已售货值不含税,
               jlr.已售净利润签约 / 10000.0 已售净利润签约,
               BA.未售对应总成本 / 10000.0 未售对应总成本,
               BA.近三月签约金额均价不含税,
               BA.近六月签约金额均价不含税,
               BA.立项单价,
               BA.定位单价,
               BA.已售均价不含税,
               BA.货量铺排均价计算方式,
               BA.未售货值不含税 / 10000.0 未售货值不含税,
               jlr.未售净利润签约 / 10000.0 未售净利润签约,
               xm.项目已售税前利润签约 / 10000.0 项目已售税前利润签约,
               xm.项目未售税前利润签约 / 10000.0 项目未售税前利润签约,
               (ISNULL(xm.项目已售税前利润签约, 0) + ISNULL(xm.项目未售税前利润签约, 0)) / 10000.0 AS 项目整盘利润,
               BA.货值铺排均价不含税,
               --20240524新增字段
               hz.已售套数,
               BA.近三月签约金额不含税,
               BA.近三月签约面积,
               BA.近六月签约金额不含税,
               BA.近六月签约面积,
			   ms.ztguid,
			   ms.是否停工,
               ldst.st 项目首推时间,
               case when ldlist.bldguid is null then '否' else '是' end 首开楼栋标签,
               ldst.首开30天签约套数,
               ldst.首开30天签约面积/ 10000 as 首开30天签约面积,
               ldst.首开30天签约金额/ 10000 as 首开30天签约金额,
               ldst.首开30天认购套数,
               ldst.首开30天认购面积/ 10000 as 首开30天认购面积,
               ldst.首开30天认购金额/ 10000 as 首开30天认购金额,

               ldcz.已完成产值,
               ldcz.合同约定应付金额,
               ldcz.累计支付金额,
               ldcz.产值未付,
               ldcz.应付未付,
               zs.持有套数,
               zs.持有面积,
               BA.土地款单方*(mj.自持面积+mj.可售面积)/10000.0 土地分摊金额,
               ldcz.累计支付金额 除地价外直投分摊金额,
               case when pro_mj.可售面积 = 0 then 0 else sftax.累计营销费用*mj.可售面积/pro_mj.可售面积 end 已发生营销费用摊分金额,
               case when pro_mj.可售面积 = 0 then 0 else sftax.累计管理费用*mj.可售面积/pro_mj.可售面积 end 已发生管理费用摊分金额,
               case when pro_mj.可售面积 = 0 then 0 else sftax.累计财务费用*mj.可售面积/pro_mj.可售面积 end 已发生财务费用费用摊分金额,
               case when pro_mj.可售面积 = 0 then 0 else sftax.累计税金*mj.可售面积/pro_mj.可售面积 end  已发生税金分摊,
               xsjz.已结转套数,
               xsjz.已结转面积,
               xsjz.已结转收入,
               jzcb.已结转成本,

			   con.ts 签约套数2024年,
			   con.bldarea 签约面积2024年,
			   con.total 签约金额2024年,
			   case when con.bldarea = 0 then 0 else con.total / con.bldarea*1.00 end 签约均价2024年,
               ba.经营成本单方,
               tag.BuildTagValue as 赛道图标签
        FROM #ms ms
             LEFT JOIN #bnqy bnqy ON ms.SaleBldGUID = bnqy.SaleBldGUID
             LEFT JOIN #p p ON ms.TopProjGuid = p.ProjGUID
             LEFT JOIN dbo.p_DevelopmentCompany dv ON dv.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
             LEFT JOIN dbo.myBizParamOption city ON city.ParamGUID = p.CityGUID
                                                    AND city.ParamName = 'td_city'
             LEFT JOIN mdm_LbProject lb ON lb.projGUID = p.ProjGUID
                                           AND lb.LbProject = 'tgid'
             LEFT JOIN #hz hz ON hz.SaleBldGUID = ms.SaleBldGUID
             LEFT JOIN #jd jd ON jd.GCBldGUID = ms.GCBldGUID
             LEFT JOIN #base BA ON BA.SaleBldGUID = ms.SaleBldGUID
             LEFT JOIN #jlr jlr ON jlr.SaleBldGUID = ms.SaleBldGUID
             LEFT JOIN #xm xm ON ms.TopProjGuid = xm.ProjGUID
             LEFT JOIN #ld_st_sale ldst on ldst.bldguid = ms.salebldguid
             left join #bld_lst ldlist on ldlist.bldguid = ms.salebldguid
			 left join #con con on con.BldGUID = ms.SaleBldGUID
             left join #ldcz ldcz on ldcz.bldguid = ms.salebldguid
             left join #zs_area zs on zs.bldguid = ms.salebldguid
             left join #mj mj on mj.salebldguid = ms.salebldguid
             left join (select projguid,sum(自持面积) AS 自持面积 ,sum(可售面积) AS 可售面积 from #mj group by projguid) pro_mj on pro_mj.projguid = ms.TopProjGuid
             left join #sftax sftax on sftax.projguid = ms.TopProjGuid
             left join #xsjz xsjz on xsjz.bldguid = ms.salebldguid
             left join #jzcb jzcb on jzcb.bldguid = ms.salebldguid
             left join mdm_BuildTag tag on tag.SaleBldGUID = ms.salebldguid and buildtag = 'SDT' 
        ORDER BY dv.DevelopmentCompanyName,
                 p.ProjCode;

				
        DROP TABLE #jd,#p,#p0,#hz,#ms,#st,#base,#bnqy,#df,#hlpp_bld,#hlpp_product,#jlr,#key,#xm,
                   #dfhz,#bld_lst,#bld_st,#con,#con2024,#feebck,#hz_st,#ld_rate,#ld_st_sale,
				   #proj_rate,#proj_st,#qy_st,#rg_st,#t,#ts_st,#vrt;
    END;
END;