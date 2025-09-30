--  从F05603表中获取数据，并添加字段
USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_F056各项目产品楼栋表系统取数原始表单_测试版]    Script Date: 2025/9/29 19:31:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_s_F056各项目产品楼栋表系统取数原始表单_测试版]
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
     exec [usp_s_F056各项目产品楼栋表系统取数原始表单_测试版] '5A4B2DEF-E803-49F8-9FE2-308735E7233D'
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

modify by tangqn01 20250722
1、增加跨分期合同的分摊逻辑

modify by tangqn01 20250807
1、增加回笼字段，累计回笼、当年回笼、当月回笼
2、增加指标字段，建筑面积（已有）、用地面积、可售面积、计容面积、自持面积、（自持+可售）面积、地上可售面积、地上自持面积、地上可售面积+地上自持面积
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
			   总产值,
               已完成产值,
			   待发生产值,
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
               赛道图标签,
			   占压资金,
			   --20250807新增指标
               累计回笼金额,
               累计本年回笼金额,
               累计本月回笼金额,
               用地面积,
               可售面积,
               计容面积,
               自持面积,
               自持可售面积,
               地上可售面积,
               地上自持面积,
               地上可售面积地上自持面积
        FROM [dss].dbo.nmap_s_F05603各项目产品楼栋表系统取数原始表单
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
        
        --增加 用地面积、可售面积、计容面积、自持面积、（自持+可售）面积、、地上可售面积、地上自持面积、地上可售面积+地上自持面积 edity by tangqn01 20250807
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
               CASE WHEN ld.zksmj = 0 THEN 0 ELSE ld.zhz / ld.zksmj END 整盘均价,
               ld.ysmj * 1.0 已售面积,
               ld.ysje 已售货值,
              CASE when isnull(ldr.VATRate,isnull(pdr.VATRate,''))<>'' then ld.ysje / (1 + isnull(ldr.VATRate,isnull(pdr.VATRate,'')))
                   ELSE ld.ysje / (1 + 0.09)
               END as 已售货值不含税, --如果系统上设置了税率的，以系统为准；否则按照1.09来计算
               ld.ysts 已售套数,
               CASE WHEN ld.ysmj = 0 THEN 0 ELSE ld.ysje / ld.ysmj END 已售均价,
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
               CASE WHEN ld.ThisYearSaleMjQY = 0 THEN 0 ELSE ld.ThisYearSaleJeQY / ld.ThisYearSaleMjQY END 本年签约均价,
               ld.ThisMonthSaleMjQY,
               ld.ThisMonthSaleJeQY,
               CASE WHEN ld.ThisMonthSaleMjQY = 0 THEN 0 ELSE ld.ThisMonthSaleJeQY / ld.ThisMonthSaleMjQY END 本月签约均价
        INTO #hz
        FROM dbo.p_lddbamj ld
        INNER JOIN #p p ON p.ProjGUID = ld.ProjGUID
        left join #ld_rate ldr on ldr.BldGUID = ld.SaleBldGUID
        left join #proj_rate pdr on pdr.projguid = ld.projguid
        WHERE DATEDIFF(d, QXDate, GETDATE()) = 0;

        --单方
        SELECT 
            项目guid,
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

        SELECT 
            v.TradeGUID,
            SUM(CASE WHEN ItemName LIKE '%补差%' THEN Amount ELSE 0 END) bck
        INTO #feebck
        FROM s_Fee s
        INNER JOIN #con2024 v ON s.TradeGUID = v.TradeGUID
        WHERE s.ItemType = '非贷款类房款'
        GROUP BY v.TradeGUID;
        
        select 
            r.BldGUID ,
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
        /*
        20250609 tangqn01 产值口径调整: 已竣备项目产值取值错误
        已竣备项目：
        总产值：
        1、回顾人员为明源软件或未回顾项目：取【动态成本金额（不含非现金）】，当【动态成本金额（不含非现金）】小于【合同现场累计产值】，取【合同现场累计产值】

        已发生产值：
        1、回顾人员为明源软件或未回顾项目：取【合同现场累计产值】
        2、回顾人员不为明源软件：回顾已发生产值

        累计应付：
        1、回顾人员为明源软件或未回顾项目：取【合同-累计付款申请】
        2、回顾人员不为明源软件：成本月度回顾-项目盘点累计应付款

        05603涉及字段调整：
        1、已完成产值金额
        2、合同约定应付金额
        3、累计支付金额
        4、除地价外直投分摊金额

        产值分摊至工程楼栋规则：
        识别工程楼栋是否存在地上建筑面积、地下建筑面积，
        存在地上建筑面积则按照地上建面分摊，
        存在地下建筑面积则按照地下建筑面积分摊，
        同时存在地上及地下面积，则按照总建筑面积分摊。

        工程楼栋分摊规则：
        工程楼栋A，总产值假设是100万，要先把工程楼栋的总产值，后台拆成两个数
        土建类产值：100万*土建部分工程费占除地价外直投目标成本占比（假设=60%）=60万
        非土建类产值：100万*非土建部分工程费占除地价外直投目标成本占比（假设=40%）=40万

        拆分比例：土建部分工程费占除低价外直投目标成本占比（最新版目标成本）

        备注：除地价外直投=全科目-土地款-营销费-管理费-财务费

        这个时候假设工程楼栋A下面有3个产品楼栋，分别为
        A1产品楼：地上建面800平、地下建面200平，总建面1000平
        A2产品楼：地上建面0平、地下建面1000平，总建面1000平
        A3产品楼：地上建面200平、地下建面800平，总建面1000平

        土建类产值的60万，就按总建面分，分到A1产品楼20万、A2产品楼20万，A3产品楼20万
        非土建类产值的40万，就按地上建面分，分到A1产品楼32万、A2产品楼0万，A3产品楼8万

        所以最终进到F056-03表，三个产品楼的总产值分别是：
        A1：20+32=52万
        A2：20+0=20万
        A3：20+8=28万
        */

        --产值分摊规则 tangqn01 2025-06-10
        --第一步 获取分期的总产值，按地上建筑面积+地下建筑面积分摊到工程楼栋
        --第二步 将工程楼栋的总产值根据土建的比例拆分为土建类和非土建类
        --第三步 土建类产值按产品楼栋的总建面分摊，非土建类产值按产品楼栋的地上建筑面积分摊  
        --获取工程楼栋建筑面积分摊比例      
        select 
            gc_zjm.projguid,
            gc_zjm.GCBldGUID,
            gc_zjm.zjm,
            case when stage_zjm.total_zjm = 0 then 0 else gc_zjm.zjm * 1.0 / stage_zjm.total_zjm end as gczjm_ratio
        into #gcbld_rate
        from (
            select 
                gc.projguid,
                gc.GCBldGUID,
                isnull(gc.UpBuildArea,0)+isnull(gc.DownBuildArea,0) as zjm
            from mdm_GCBuild gc
        ) gc_zjm
        inner join (
            select 
                projguid,
                sum(isnull(UpBuildArea,0)+isnull(DownBuildArea,0)) as total_zjm
            from mdm_GCBuild
            group by projguid
        ) stage_zjm on gc_zjm.projguid = stage_zjm.projguid

        -- 获取目标成本的土建类占比
        SELECT 
            *
        INTO #tj_Rate
        FROM (
            SELECT
                ex.buguid,
                ex.projguid,
                ex.targetcost,
                ex.tj_targetcost,
                CASE WHEN ex.targetcost = 0 THEN 0 ELSE ex.tj_targetcost/ex.targetcost END AS tjRate,
                ex.dtcostNotFxj,
                ex.targetstage2projectguid,
                trg2p.TargetStageVersion,
                trg2p.approvedate,
                -- 按审核日期倒序排序
                ROW_NUMBER() OVER (PARTITION BY ex.projguid ORDER BY trg2p.approvedate DESC) AS rn
            FROM (
                -- 汇总执行版目标成本
                SELECT  
                    cost.buguid,
                    trg2cost.ProjGUID,
                    trg2cost.targetstage2projectguid,
                    SUM(CASE WHEN cost.costcode LIKE '5001.03.01%' then cost.targetcost ELSE 0 END) AS tj_targetcost, --土建部分工程费
                    SUM(cost.targetcost) AS targetcost, --目标成本
                    sum( ISNULL(cost.YfsCost, 0) + ISNULL(cost.DfsCost, 0) - ISNULL(cost.FxjCost, 0) ) AS  dtcostNotFxj --'动态成本_含税_不含非现金'
                FROM MyCost_Erp352.dbo.cb_cost cost WITH(NOLOCK)
                INNER JOIN MyCost_Erp352.dbo.cb_TargetStage2Cost trg2cost WITH(NOLOCK)
                    ON trg2cost.costguid = cost.costguid 
                    AND trg2cost.ProjCode = cost.ProjectCode
                WHERE cost.costcode NOT LIKE '5001.01.%' 
                    AND cost.costcode NOT LIKE '5001.09.%'
                    AND cost.costcode NOT LIKE '5001.10.%' 
                    AND cost.costcode NOT LIKE '5001.11%' 
                    AND cost.ifendcost = 1
                GROUP BY cost.buguid, trg2cost.projguid, trg2cost.targetstage2projectguid
            ) ex
            INNER JOIN MyCost_Erp352.dbo.cb_TargetCostRevise_KH trg2p  WITH(NOLOCK) ON trg2p.projguid = ex.projguid 
            WHERE 1=1  --AND  ex.projguid in ( 'A260CA9E-B657-E711-80BA-E61F13C57837')
        ) t WHERE t.rn = 1
        
        --获取产品楼栋的地上分摊比例和建筑面积分摊比例
        select 
            cp_zjm.GCBldGUID,
            cp_zjm.SaleBldGUID,
            cp_zjm.zjm,
            case when stage_zjm.total_zjm = 0 then 0 else cp_zjm.zjm * 1.0 / stage_zjm.total_zjm end as zjm_ratio,
            case when stage_zjm.UpBuildArea = 0 then 0 else cp_zjm.UpBuildArea*1.0/stage_zjm.UpBuildArea end as UpBuildArea_rate
        into #cpbld_rate
        from (
            select 
                cp.GCBldGUID,
                cp.SaleBldGUID,
                isnull(cp.UpBuildArea,0) as UpBuildArea,
                isnull(cp.UpBuildArea,0)+isnull(cp.DownBuildArea,0) as zjm
            from mdm_salebuild cp
        ) cp_zjm
        inner join (
            select 
                cp.GCBldGUID,
                sum(isnull(cp.UpBuildArea,0)) as UpBuildArea,
                sum(isnull(cp.UpBuildArea,0)+isnull(cp.DownBuildArea,0)) as total_zjm
            from mdm_salebuild cp
            group by GCBldGUID
        ) stage_zjm on cp_zjm.GCBldGUID = stage_zjm.GCBldGUID

        --获取项目已审核的最晚回顾时间记录
        select t.*
        into #vor
        from (
            select row_number() over(partition by projguid order by reviewdate desc) as rn,* 
            from MyCost_Erp352.dbo.cb_outputvaluemonthreview
            where ApproveState in ('已审核','审核中')
        ) t
        where t.rn = 1

        --取执行版目标成本 除地价外直投（不含非现金）
        SELECT 
        * 
        INTO #hygh_new
        FROM (
        SELECT  
            ex.buguid,  
            ex.projguid,  
            ex.targetcost,  
            ex.dtcostNotFxj,  
            ex.targetstage2projectguid,  
            trg2p.TargetStageVersion,  
            trg2p.approvedate,  
            -- 按审核日期倒序排序  
            ROW_NUMBER() OVER (PARTITION BY ex.projguid ORDER BY trg2p.approvedate DESC) AS rn    
        FROM (  
            -- 汇总执行版目标成本  
            SELECT    
                cost.buguid,  
                trg2cost.ProjGUID,  
                trg2cost.targetstage2projectguid,  
                SUM(cost.targetcost) AS targetcost,  
                sum( ISNULL(cost.YfsCost, 0) + ISNULL(cost.DfsCost, 0) - ISNULL(cost.FxjCost, 0) ) AS  dtcostNotFxj --'动态成本_含税_不含非现金'  
            FROM MyCost_Erp352.dbo.cb_cost cost WITH(NOLOCK)  
            LEFT JOIN MyCost_Erp352.dbo.cb_TargetStage2Cost trg2cost WITH(NOLOCK)  
                ON trg2cost.costguid = cost.costguid   
                AND trg2cost.ProjCode = cost.ProjectCode  
            WHERE cost.costcode NOT LIKE '5001.01.%'   
                AND cost.costcode NOT LIKE '5001.09.%'  
                AND cost.costcode NOT LIKE '5001.10.%'   
                AND cost.costcode NOT LIKE '5001.11%'   
                AND cost.ifendcost = 1  
            GROUP BY cost.buguid, trg2cost.projguid, trg2cost.targetstage2projectguid  
        ) ex  
        INNER JOIN MyCost_Erp352.dbo.cb_TargetCostRevise_KH trg2p  WITH(NOLOCK) ON trg2p.projguid = ex.projguid         
        WHERE 1=1
        AND ex.buguid in (SELECT value FROM fn_Split2(@var_buguid, ','))
        ) t where t.rn = 1;

        --新增合同按分期分摊比例
        select 
            t.ProjGUID,
            t.ContractGUID,
            t.UsedAmount/sum(t.UsedAmount) over(partition by t.ContractGUID) as Rate
        INTO #htrate
        from (
            select 
                p.ProjGUID,
                c.ContractGUID,
                sum(b.UsedAmount) as UsedAmount
            FROM  MyCost_Erp352.dbo.cb_BudgetUse a WITH(NOLOCK)
            INNER JOIN MyCost_Erp352.dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = a.BudgetGUID 
            INNER JOIN MyCost_Erp352.dbo.cb_Contract c WITH(NOLOCK) ON c.ContractGUID=a.RefGUID
            INNER JOIN MyCost_Erp352.dbo.p_Project p WITH(NOLOCK) ON a.ProjectCode=p.ProjCode
            where  a.IsApprove= 1  -- 审核中或已审核
                AND	c.IfDdhs=1  -- 是否单独核算    
                AND c.approvestate = '已审核'
            group by 
                p.ProjGUID,
                c.ContractGUID
        ) t	
		where t.UsedAmount > 0
        union all 
        select 
            t.ProjGUID,
            t.ContractGUID,            
            1.0/count(1) over(partition by t.ContractGUID) as Rate
        from (
            SELECT
                c.ContractGUID,p.ProjGUID,AllItem
            FROM MyCost_Erp352.dbo.cb_Contract c 
            LEFT JOIN MyCost_Erp352.dbo.cb_BudgetUse a ON c.ContractGUID=a.RefGUID
            CROSS APPLY MyCost_Erp352.dbo.fn_Split(c.ProjectCodeList,';')
            LEFT JOIN MyCost_Erp352.dbo.p_Project p on p.ProjCode = AllItem
            WHERE c.IfDdhs=1
                AND c.approvestate = '已审核' 
                AND a.BudgetGUID IS NULL
            group by c.ContractGUID,p.ProjGUID,AllItem
        ) t ;
	
	    create index idx_htrate on #htrate(ContractGUID,ProjGUID);

        --合约规划    
        --3、 合约规划:除地价外直投 合同大类：

        ----已签约的合约规划:合约规划GUID  
        SELECT  p.ProjGUID,bt.ExecutingBudgetGUID 
        INTO  #Budget
        FROM MyCost_Erp352.dbo.cb_Budget bt 
        INNER JOIN MyCost_Erp352.dbo.cb_BudgetUse bu ON bu.BudgetGUID=bt.BudgetGUID
        INNER JOIN MyCost_Erp352.dbo.cb_Contract ct ON ct.ContractGUID=bu.RefGUID
        INNER JOIN MyCost_Erp352.dbo.p_Project p ON p.ProjCode=bu.ProjectCode
        --INNER JOIN #projectbase on #projectbase.ProjGUID = p.ProjGUID
        INNER JOIN MyCost_Erp352.dbo.cb_Budget_Executing e ON e.ExecutingBudgetGUID=bt.ExecutingBudgetGUID
        LEFT JOIN  MyCost_Erp352.dbo.cb_HtType c ON c.HtTypeGUID=e.BigHTTypeGUID
        WHERE   bu.IsApprove=1 
        AND   ISNULL( c.HtTypeName,'') NOT IN ('土地类','营销费','管理费','财务费')
        GROUP BY p.ProjGUID,bt.ExecutingBudgetGUID
        

        --已发生
        SELECT bt.ProjGUID,ISNULL(SUM(f.CfAmount ),0)   AS YfsCost
        INTO #yfs
        FROM  MyCost_Erp352.dbo.cb_BudgetUse f  
        INNER JOIN MyCost_Erp352.dbo.cb_Budget b ON b.BudgetGUID = f.BudgetGUID
        INNER JOIN MyCost_Erp352.dbo.p_Project p ON p.ProjCode=f.ProjectCode
        INNER JOIN #Budget bt ON bt.ExecutingBudgetGUID=b.ExecutingBudgetGUID and bt.ProjGUID = p.ProjGUID
        WHERE  f.IsApprove = 1 
        AND ISNULL(f.IsFromXyl,0)=0
        --AND p.ProjGUID=@ProjGUID  
        GROUP BY bt.ProjGUID

        --预留金额-余额
        SELECT c.ProjGUID,ISNULL(SUM(a.CfAmount),0)  AS YgYeAmount
        into #yjl
        FROM MyCost_Erp352.dbo.cb_YgAlter2Budget a
        INNER JOIN MyCost_Erp352.dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID
        INNER JOIN MyCost_Erp352.dbo.p_Project p ON p.ProjGUID= b.ProjectGUID
        INNER JOIN  #Budget c ON b.ExecutingBudgetGUID = c.ExecutingBudgetGUID and c.ProjGUID = p.ProjGUID
        group by c.ProjGUID

        SELECT  
            a.ProjectGUID AS ProjGUID,
            ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS  NULL THEN a.BudgetAmount else 0 END),0)   AS BudgetAmount  --合约规划总金额（万元）
            ,COUNT(1) AS BudgetCnt --总合约规划数量        
            ,ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS NOT NULL THEN 1 else 0 END  ),0)  AS ContractCnt  --已签合同数量
            ,ROUND(ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS  NULL THEN a.BudgetAmount else 0 END),0)/10000,2) AS  DyqAmount --待签合同规划金额（万元）
            ,COUNT(1)-ISNULL(SUM(CASE WHEN b.ExecutingBudgetGUID IS NOT NULL THEN 1 else 0 END  ),0) AS DyqCnt  --待签合同数量
        INTO #hy
        FROM MyCost_Erp352.dbo.cb_Budget_Executing a
        --INNER JOIN #projectbase p on a.ProjectGUID = p.ProjGUID
        LEFT JOIN  #Budget b ON b.ExecutingBudgetGUID = a.ExecutingBudgetGUID and b.ProjGUID = a.ProjectGUID
        LEFT JOIN  MyCost_Erp352.dbo.cb_HtType c ON c.HtTypeGUID=a.BigHTTypeGUID
        WHERE ISNULL( c.HtTypeName,'') NOT IN ('土地类','营销费','管理费','财务费')
        GROUP BY a.ProjectGUID

        SELECT 
            a.ProjGUID AS ProjGUID,
            ISNULL(yfs.YfsCost,0) + ISNULL(ylj.YgYeAmount,0) +ISNULL(a.BudgetAmount,0)  AS BudgetAmount  --合约规划总金额（万元）
            ,a.BudgetCnt AS BudgetCnt --总合约规划数量
            ,ROUND((ISNULL(yfs.YfsCost,0) + ISNULL(ylj.YgYeAmount,0))/10000,2)  AS ContractDtCost --合约规划动态成本（非现金）金额汇总
            ,a.ContractCnt  AS ContractCnt  --已签合同数量
            ,a.DyqAmount AS  DyqAmount --待签合同规划金额（万元）
            ,a.DyqCnt AS DyqCnt  --待签合同数量
        into #hygh
        FROM #hy a
        --INNER JOIN #projectbase p on a.ProjGUID = p.ProjGUID
        LEFT JOIN #yfs yfs on yfs.ProjGUID = a.ProjGUID
        LEFT JOIN #yjl ylj on ylj.ProjGUID = a.ProjGUID

        select  cbp.projguid,
            sum(isnull(cb.htamount,0)*isnull(htrate.Rate,1)) as htamountnotfee,  -- 合同金额
            sum(isnull(yljze,0)*isnull(htrate.Rate,1)) as yljzenotfee, -- 预留金金额
            sum(isnull(cbz.jfljywccz,0)*isnull(htrate.Rate,1)) as jfljywccznotfee, -- 甲方审核-现场累计产值
            sum(case when cb.jsstate = '结算' 
                    then cb.jsamount_bz*isnull(htrate.Rate,1)
                    else isnull(cb.htamount, 0)*isnull(htrate.Rate,1) + isnull(cb.sumalteramount, 0)*isnull(htrate.Rate,1)
                end - isnull(cbz.jfljywccz, 0)*isnull(htrate.Rate,1)) as wfqcznotfee, -- 未发起产值金额
            sum(isnull(pay.payamount,0)*isnull(htrate.Rate,1)) as payamountnotfee, -- 合同-累计付款登记（不含土地+三费）    
            sum(isnull(pay.payamount202502,0)*isnull(htrate.Rate,1)) as payamount202502notfee, -- 合同-累计付款登记（不含土地+三费）截止今年2月28日
            sum(isnull(pay.nopayamount,0)*isnull(htrate.Rate,1)) as nopayamountnotfee, -- 合同-累计付款登记不含税（不含土地+三费）
            sum(isnull(pay.jhfkamountnotax,0)*isnull(htrate.Rate,1)) as jhfkamountnotaxnotfee, -- 合同-累计付款登记不含可抵扣税   （不含土地+三费）        
            sum(isnull(htapply.applyamount,0)*isnull(htrate.Rate,1)) as applyamountnotfee, -- 合同-累计付款申请金额（含土地+三费）
            sum(isnull(balance.balanceamount,0)*isnull(htrate.Rate,1)) as balanceamountnotfee -- 合同-结算金额
        into #htnotfee
        from  MyCost_Erp352.dbo.cb_contract cb with(nolock)
        inner  join MyCost_Erp352.dbo.cb_httype ty with(nolock) on ty.httypecode =cb.httypecode and  ty.buguid =cb.buguid
        inner join MyCost_Erp352.dbo.cb_contractproj cbp with(nolock) on cbp.contractguid = cb.contractguid
        LEFT JOIN #htrate htrate on htrate.ContractGUID =cb.ContractGUID and htrate.ProjGUID =cbp.ProjGUID
        left join MyCost_Erp352.dbo.cb_contractcz cbz with(nolock) on cbz.contractguid = cb.contractguid
        left join MyCost_Erp352.dbo.p_project p on cbp.projguid = p.projguid
        left join (
            select  contractguid,
                    sum(isnull(cfamount,0)) as yljze -- 预留金金额
            from    MyCost_Erp352.[dbo].[cb_ygalter2budget] with(nolock)
            group by contractguid
        ) ylj on ylj.contractguid = cb.contractguid
        left join (
            select contractguid,
                -- sum(isnull(applyamount,0)) as applyamount 
                sum(yfamount) as applyamount
            from  MyCost_Erp352.dbo.cb_htfkapply with(nolock)
            where  applystate ='已审核'
            group by contractguid
        ) htapply on htapply.contractguid = cb.contractguid
        left join (
            select  contractguid,
                sum(isnull(payamount,0)) as payamount,
                -- 付款日期截止到2025年2月28日
                sum(case  when datediff(day,paydate, '2025-02-28') >= 0 then isnull(payamount,0) else 0 end) as payamount202502,
                sum(isnull(nopayamount,0)) as nopayamount,
                sum(isnull(jhfkamountnotax,0)) as jhfkamountnotax
            from  MyCost_Erp352.dbo.cb_pay with(nolock)
            group by contractguid
        ) pay on pay.contractguid = cb.contractguid      
        -- 合同-结算金额
        left join (
            select contractguid,sum(isnull(balanceamount,0)) as  balanceamount 
            from  MyCost_Erp352.dbo.cb_htbalance with(nolock)
            where  balancetype ='结算'
            group by  contractguid
        ) balance on balance.contractguid = cb.contractguid     
        where   cb.approvestate = '已审核' AND	 cb.IfDdhs=1  -- 是否单独核算   

        -- 不含土地款及管理费、营销费、财务费合同
        and  ty.httypecode not in ('01','01.01','01.02','01.03','01.04','01.05',
                                    '07','07.01','07.02','07.03','07.04','07.05',
                                    '07.06','07.07','07.08','07.09','07.10','07.11',
                                    '07.12','07.13','07.14','08','08.01','09','09.01')
        group by cbp.projguid


        -- 主查询
        select  
            bu.buname as '公司名称',                                                      -- 合同的归属公司
            p.projname as '所属项目',                                                    -- 合同的所属项目
            flg.投管代码 as '投管代码',
            pp.projcode as '项目代码',
            p.projcode as '分期代码',
            p.ProjGUID,
            flg.推广名 as '推广名',
            mp.acquisitiondate as '项目获取时间',
            case when year(mp.acquisitiondate) >=2024 then '新增量'
                when year(mp.acquisitiondate) >=2022 and year(mp.acquisitiondate) < 2024 then '增量'
                else '存量' end as '项目类型',
            flg.工程操盘方 as '工程操盘方',
            flg.成本操盘方 as '成本操盘方',
            mp.projstatus as '项目状态',
            mp.constructstatus as '工程状态',
            
            ovr.OutputValueMonthReviewGUID,
            CASE WHEN isnull(ovr.createon,'明源软件') = '明源软件' THEN 1 
                 WHEN isnull(ovr.createon,'明源软件') <> '明源软件' THEN 0 END AS 回顾标志,--1为取动态数据，0为取拍照数据
            --面积信息
            
            --产值数据
           --产值数据
            /*总产值：
            1、回顾人员为明源软件或未回顾项目：取【动态成本金额（不含非现金）】，当【动态成本金额（不含非现金）】小于【合同现场累计产值】，取【合同现场累计产值】
            2、回顾人员不为明源软件：总产值
            3、若1、2未取到数据，则取合约规划金额 --20250722
            
            round(case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.htamountnotfee,0) < isnull(htnotfee.jfljywccznotfee,0) 
                then isnull(htnotfee.jfljywccznotfee,0) 
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.htamountnotfee,0) > isnull(htnotfee.jfljywccznotfee,0) 
                then isnull(htnotfee.htamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.totaloutputvalue,0) 
            end,2) as '总产值',
            */
            round(case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.jfljywccznotfee,0) <= isnull(hyn.targetcost,0)  
                then isnull(hyn.targetcost,0) 
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.jfljywccznotfee,0) > isnull(hyn.targetcost,0)  
                then isnull(htnotfee.jfljywccznotfee,0)
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.totaloutputvalue,0) 
                else isnull(hy.BudgetAmount,0)
            end,2) as '总产值',
            
            /*
            已发生产值：
            甲方审核-现场累计产值 jfljywccznotfee
            合同-累计付款申请金额（含土地+三费） applyamountnotfee
            合同-累计付款登记（不含土地+三费）  payamountnotfee
            1、回顾人员为明源软件或未回顾项目：取【合同现场累计产值】，合同现场累计产值小于累计应付时，取累计应付，累计应付小于累计实付时，取累计实付
            2、回顾人员不为明源软件：回顾下的已发生产值
            */
            round(case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.jfljywccznotfee,0) >= isnull(htnotfee.applyamountnotfee,0) and isnull(htnotfee.jfljywccznotfee,0) >= isnull(htnotfee.payamountnotfee,0)  then isnull(htnotfee.jfljywccznotfee,0)
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.applyamountnotfee,0) >= isnull(htnotfee.jfljywccznotfee,0) and isnull(htnotfee.applyamountnotfee,0) >= isnull(htnotfee.payamountnotfee,0)  then isnull(htnotfee.applyamountnotfee,0)
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.payamountnotfee,0) >= isnull(htnotfee.jfljywccznotfee,0) and  isnull(htnotfee.payamountnotfee,0) >= isnull(htnotfee.applyamountnotfee,0) then isnull(htnotfee.payamountnotfee,0)
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.yfsoutputvalue,0) 
            end,2) as '已发生产值',
            /*待发生产值=总产值-已发生产值*/
            round((case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.jfljywccznotfee,0) <= isnull(hyn.targetcost,0)  
                then isnull(hyn.targetcost,0) 
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.jfljywccznotfee,0) > isnull(hyn.targetcost,0)  
                then isnull(htnotfee.jfljywccznotfee,0)
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.totaloutputvalue,0) 
                else isnull(hy.BudgetAmount,0)
            end
            - 
            case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.jfljywccznotfee,0) >= isnull(htnotfee.applyamountnotfee,0) and isnull(htnotfee.jfljywccznotfee,0) >= isnull(htnotfee.payamountnotfee,0)  then isnull(htnotfee.jfljywccznotfee,0)
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.applyamountnotfee,0) >= isnull(htnotfee.jfljywccznotfee,0) and isnull(htnotfee.applyamountnotfee,0) >= isnull(htnotfee.payamountnotfee,0)  then isnull(htnotfee.applyamountnotfee,0)
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.payamountnotfee,0) >= isnull(htnotfee.jfljywccznotfee,0) and  isnull(htnotfee.payamountnotfee,0) >= isnull(htnotfee.applyamountnotfee,0) then isnull(htnotfee.payamountnotfee,0)
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.yfsoutputvalue,0) 
            end),2) as '待发生产值',
            --付款数据   
             /*
            累计应付：
            1、回顾人员为明源软件或未回顾项目：取【合同-累计付款申请】，累计付款申请小于累计实付时，取累计实付
            2、回顾人员不为明源软件：成本月度回顾-项目盘点累计应付款
            */     
            round(case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.payamountnotfee,0)  >= isnull(htnotfee.applyamountnotfee,0)  then isnull(htnotfee.payamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.payamountnotfee,0)  < isnull(htnotfee.applyamountnotfee,0)  then isnull(htnotfee.applyamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' and isnull(ovr.ljyfamount ,0)  >= isnull(ovr.ljsfamount ,0)  then isnull(ovr.ljyfamount ,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' and isnull(ovr.ljyfamount ,0)  < isnull(ovr.ljsfamount ,0)  then isnull(ovr.ljsfamount ,0) 
            end,2) as '累计应付',
            round(case when isnull(ovr.createon,'明源软件') = '明源软件' 
                then isnull(htnotfee.payamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.ljsfamount ,0) 
            end,2) as '累计实付',
            --已发生产值-累计实付
            round((case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.jfljywccznotfee,0) >= isnull(htnotfee.applyamountnotfee,0) and isnull(htnotfee.jfljywccznotfee,0) >= isnull(htnotfee.payamountnotfee,0)  then isnull(htnotfee.jfljywccznotfee,0)
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.applyamountnotfee,0) >= isnull(htnotfee.jfljywccznotfee,0) and isnull(htnotfee.applyamountnotfee,0) >= isnull(htnotfee.payamountnotfee,0)  then isnull(htnotfee.applyamountnotfee,0)
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.payamountnotfee,0) >= isnull(htnotfee.jfljywccznotfee,0) and  isnull(htnotfee.payamountnotfee,0) >= isnull(htnotfee.applyamountnotfee,0) then isnull(htnotfee.payamountnotfee,0)
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.yfsoutputvalue,0) 
            end - case when isnull(ovr.createon,'明源软件') = '明源软件' 
                then isnull(htnotfee.payamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.ljsfamount ,0) 
            end),2) as '已达产值未付',
            round((case when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.payamountnotfee,0)  >= isnull(htnotfee.applyamountnotfee,0)  then isnull(htnotfee.payamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') = '明源软件' and isnull(htnotfee.payamountnotfee,0)  < isnull(htnotfee.applyamountnotfee,0)  then isnull(htnotfee.applyamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' and isnull(ovr.ljyfamount ,0)  >= isnull(ovr.ljsfamount ,0)  then isnull(ovr.ljyfamount ,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' and isnull(ovr.ljyfamount ,0)  < isnull(ovr.ljsfamount ,0)  then isnull(ovr.ljsfamount ,0) 
            end - case when isnull(ovr.createon,'明源软件') = '明源软件' 
                then isnull(htnotfee.payamountnotfee,0) 
                when isnull(ovr.createon,'明源软件') <> '明源软件' then isnull(ovr.ljsfamount ,0) 
            end),2) as '应付未付'
        INTO #fqcz                
        FROM MyCost_Erp352.dbo.p_project p WITH(NOLOCK)
        LEFT JOIN MyCost_Erp352.dbo.p_project pp WITH(NOLOCK) ON pp.ProjCode = p.ParentCode AND pp.Level = 2
        INNER JOIN MyCost_Erp352.dbo.mybusinessunit bu WITH(NOLOCK) ON p.buguid = bu.buguid
        INNER JOIN ERP25.dbo.mdm_project mp WITH(NOLOCK) ON mp.projguid = p.ProjGUID
        LEFT JOIN erp25.dbo.vmdm_projectFlag flg ON flg.projguid = mp.ParentProjGUID
        LEFT JOIN #vor ovr ON ovr.projguid = p.projguid AND ovr.RN = 1
        LEFT JOIN #htNotfee htNotfee ON htNotfee.ProjGUID = p.ProjGUID
        left join #hygh_new hyn on hyn.ProjGUID = p.ProjGUID
        LEFT JOIN #hygh hy ON hy.ProjGUID = p.ProjGUID
        WHERE 1 = 1
            AND p.level = 3    
        ORDER BY bu.buname, p.ProjName 

        /*
        SELECT 
            fq.ProjGUID,
            gc.GCBldGUID,	
			gc.BldName,		
			gc.zjm,
            gc.gczjm_ratio,
            tj.tjRate,
            cp.SaleBldGUID as bldguid,
			cp.BldName,
			cp.ProductName,
			cp.zjm,
			cp.UpBuildArea,
            cp.zjm_ratio,
            cp.UpBuildArea_rate,
			fq.总产值,
			fq.总产值*gc.gczjm_ratio as 工程楼栋产值,
			fq.总产值*gc.gczjm_ratio*tj.tjRate 工程楼栋土建产值,
			fq.总产值*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio 产品楼栋土建产值,
			fq.总产值*gc.gczjm_ratio*(1-tj.tjRate) 工程楼栋非土建产值,
			fq.总产值*gc.gczjm_ratio*(1-tj.tjRate)*cp.UpBuildArea_rate 产品楼栋非土建产值,
            fq.总产值*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio+fq.总产值*gc.gczjm_ratio*(1-isnull(tj.tjRate,0))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 总产值,
            fq.已发生产值*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio+fq.已发生产值*gc.gczjm_ratio*(1-isnull(tj.tjRate,0))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 已完成产值,
            fq.待发生产值*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio+fq.待发生产值*gc.gczjm_ratio*(1-isnull(tj.tjRate,0))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 待发生产值,
            fq.累计应付*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio+fq.累计应付*gc.gczjm_ratio*(1-isnull(tj.tjRate,0))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 合同约定应付金额,
            fq.累计实付*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio+fq.累计实付*gc.gczjm_ratio*(1-isnull(tj.tjRate,0))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 累计支付金额,
            fq.已达产值未付*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio+fq.已达产值未付*gc.gczjm_ratio*(1-isnull(tj.tjRate,0))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 产值未付,
            fq.应付未付*gc.gczjm_ratio*tj.tjRate*cp.zjm_ratio+fq.应付未付*gc.gczjm_ratio*(1-isnull(tj.tjRate,0))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 应付未付
      
		FROM #fqcz fq 
        INNER JOIN #gcbld_rate gc on fq.ProjGUID = gc.StegeGUID
        INNER JOIN #tj_Rate tj on tj.projguid = fq.projguid
        INNER JOIN #cpbld_rate cp on cp.GCBldGUID = gc.GCBldGUID
        */

        SELECT 
            fq.ProjGUID,
            cp.GCBldGUID,
            gc.gczjm_ratio,
            tj.tjRate,
            cp.SaleBldGUID as bldguid,
            cp.zjm_ratio,
            cp.UpBuildArea_rate,
            --土建比例为null
            fq.总产值*gc.gczjm_ratio*ISNULL(tj.tjRate,1)*cp.zjm_ratio+fq.总产值*gc.gczjm_ratio*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 总产值,
            fq.已发生产值*gc.gczjm_ratio*ISNULL(tj.tjRate,1)*cp.zjm_ratio+fq.已发生产值*gc.gczjm_ratio*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 已完成产值,
            fq.待发生产值*gc.gczjm_ratio*ISNULL(tj.tjRate,1)*cp.zjm_ratio+fq.待发生产值*gc.gczjm_ratio*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 待发生产值,
            fq.累计应付*gc.gczjm_ratio*ISNULL(tj.tjRate,1)*cp.zjm_ratio+fq.累计应付*gc.gczjm_ratio*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 合同约定应付金额,
            fq.累计实付*gc.gczjm_ratio*ISNULL(tj.tjRate,1)*cp.zjm_ratio+fq.累计实付*gc.gczjm_ratio*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 累计支付金额,
            fq.已达产值未付*gc.gczjm_ratio*ISNULL(tj.tjRate,1)*cp.zjm_ratio+fq.已达产值未付*gc.gczjm_ratio*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 产值未付,
            fq.应付未付*gc.gczjm_ratio*ISNULL(tj.tjRate,1)*cp.zjm_ratio+fq.应付未付*gc.gczjm_ratio*(1-isnull(tj.tjRate,1))*case when cp.UpBuildArea_rate > 0 then cp.UpBuildArea_rate else cp.zjm_ratio end as 应付未付
        INTO #ldcz
		FROM #fqcz fq
        LEFT JOIN #gcbld_rate gc on fq.ProjGUID = gc.projguid
        LEFT JOIN #tj_Rate tj on tj.projguid = fq.projguid
        INNER JOIN #cpbld_rate cp on cp.GCBldGUID = gc.GCBldGUID
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
        --先计算出每个产品楼栋按建筑面积分摊的比例
        /*
        select 
            sb.SaleBldGUID, 
            sb.GCBldGUID,
            convert(decimal(16,8),case when (isnull(gc.UpBuildArea,0)+isnull(gc.DownBuildArea,0)) =0 then 0
          else (sb.UpBuildArea+sb.DownBuildArea)*1.0 / (isnull(gc.UpBuildArea,0)+isnull(gc.DownBuildArea,0)) end) as 分摊比例
        into #cz_rate
        from mdm_salebuild sb 
        inner join mdm_GCBuild gc on sb.GCBldGUID = gc.GCBldGUID    

		--获取项目已审核的最晚回顾时间记录
        select * 
        into #OutputValuebb
        from (
            select 
                projguid,
                ROW_NUMBER() over(PARTITION BY projguid order by ReviewDate desc) as RowNum,
                OutputValueMonthReviewGUID 
            from MyCost_Erp352.dbo.cb_OutputValueMonthReview 
            where ApproveState in ('已审核','审核中')
        ) t where t.RowNum = 1

        SELECT 
            ISNULL(a.Xmpdljwccz, 0)*分摊比例 AS 已完成产值, 
            ISNULL(a.Ljyfkje, 0)*分摊比例 AS 合同约定应付金额,
            ISNULL(a.Ljsfk, 0)*分摊比例 AS 累计支付金额,
            (isnull(a.Xmpdljwccz,0) - ISNULL(a.Ljsfk, 0))*分摊比例 AS 产值未付,
            ISNULL(a.Ljyfkje, 0)*分摊比例 - ISNULL(a.Ljsfk, 0)*分摊比例 AS 应付未付,
            r.salebldguid as bldguid
        into #ldcz
        FROM (
            SELECT   
                    SUM(ISNULL(b.Xmpdljwccz, 0)) AS Xmpdljwccz, --已完成产值金额
                    SUM(ISNULL(b.Ljyfkje, 0)) AS Ljyfkje, --累计应付款
                    SUM(ISNULL(b.Ljsfk, 0)) AS Ljsfk,   --累计实付款
                    BldGUID
            FROM mycost_erp352.dbo.cb_OutputValueReviewDetail a with(nolock) 
            INNER JOIN mycost_erp352.dbo.cb_OutputValueReviewBld b with(nolock) ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
            inner join #OutputValuebb t on t.OutputValueMonthReviewGUID = a.OutputValueMonthReviewGUID
            WHERE (1=1) AND (2=2) 
            GROUP BY b.BldGUID
        ) a  
        inner join #cz_rate r on a.bldguid = r.GCBldGUID 
        inner join #ms ms with(nolock) on ms.SaleBldGUID = r.SaleBldGUID  
        */
        
        SELECT 
            a.ProductBldGUID as bldguid,  
            sum(a.bldarea)/10000.0 持有面积, 
            count(1) 持有套数
        into #zs_area
        FROM mycost_erp352.dbo.md_Room a with(nolock)
        inner join #ms ms with(nolock) on ms.SaleBldGUID = a.ProductBldGUID
        where isnull(UseProperty,'') in ('经营','留存自用')
        group BY a.ProductBldGUID
        union all 
        select 
            ms.SaleBldGUID,
            sum(zjm)/10000.0 as 持有面积,
            sum(HouseNum) as 持有套数 
        from #ms ms with(nolock)
        where IsHold = '是' and not exists (select 1 from mycost_erp352.dbo.md_Room where ProductBldGUID = ms.SaleBldGUID)
		group by  ms.SaleBldGUID

        --取基础数据中间表对应的可售面积及自持面积情况 
		-- --建筑面积（已有）、用地面积、可售面积、计容面积、自持面积、（自持+可售）面积、、地上可售面积、地上自持面积、地上可售面积+地上自持面积
        SELECT 
            ms.TopProjGuid projguid,  
            ms.salebldguid,
			a.YdArea as 用地面积,
			a.SaleArea as 可售面积,
			a.jrArea as 计容面积,
            a.HoldArea as 自持面积, 
            isnull(a.HoldArea,0)+isnull(a.SaleArea,0) as 自持可售面积,
			case when a.PhyAddress ='地上' then isnull(a.SaleArea,0) else 0 end as 地上可售面积,
			case when a.PhyAddress ='地上' then isnull(a.HoldArea,0) else 0 end as 地上自持面积,
			case when a.PhyAddress ='地上' then isnull(a.SaleArea,0)+ isnull(a.HoldArea,0) else 0 end as 地上自持可售面积		
			
        into #mj
        FROM mycost_erp352.dbo.vs_md_productbuild_getAreaAndSpaceNumInfo a with(nolock) 
        inner join #ms ms with(nolock) on ms.SaleBldGUID = a.ProductBuildGUID 
        --group BY ms.TopProjGuid,ms.salebldguid,a.PhyAddress

		create index idx_mj on #mj(salebldguid);

        --获取表七的三费+税金情况
        SELECT 
            p.ProjGUID,
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
        select 
            r.BldGUID, count(1) as 已结转套数,
            sum(r.BldArea)/10000.0 as 已结转面积,
            sum(JzAmount)/10000.0 as 已结转收入
        into #xsjz
        from erp25.dbo.s_Trade st with(nolock)
        inner join erp25.dbo.p_room r with(nolock) on st.RoomGUID = r.RoomGUID
        inner join #ms ms with(nolock) on ms.SaleBldGUID = r.BldGUID
        where jzdate is not null and isnull(YJ_TradeStatus,'')='激活'
        group by r.BldGUID
    
        --获取主营业务成本
        /*
        select * 
        into #CarryOverMbb
        from (
            select projguid,
                ROW_NUMBER() over(PARTITION BY projguid order by ApproveDate desc) as RowNum,
                CarryOverMainGUID 
            from [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain with(nolock) where ApproverState = '已审核'
        ) t where t.RowNum = 1
        */

        --获取主营业务成本
        --业务上同一个分期  1号楼、 2号楼，可以分别进行审批,按分期取最新版本存在漏数
        select * 
        into #CarryOverMbb
        from (
                select a.projguid,d.BldGUID,ROW_NUMBER() over(PARTITION BY a.projguid ,d.BldGUID ORDER by a.ApproveDate desc) as RowNum,a.CarryOverMainGUID 
                from [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain a with(nolock)
                left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d with(nolock) ON  d.Subject = 4 and d.CarryOverMainGUID = a.CarryOverMainGUID
                WHERE a.ApproverState = '已审核'
        ) t where t.RowNum = 1;
 
        select  ld.SaleBldGUID as bldguid,
        sum(CASE WHEN e.CarryOverMainGUID IS NOT NULL THEN ISNULL(d.TotalMoney,0) ELSE  ISNULL(b.TotalMoney, 0) END)/10000.0 AS 已结转成本 
        into #jzcb
        from  erp25.dbo.mdm_SaleBuild ld with(nolock)
        inner join erp25.dbo.mdm_GCBuild gc with(nolock) on gc.GCBldGUID = ld.GCBldGUID
        left join #CarryOverMbb bb with(nolock) on bb.projguid = gc.projguid and bb.BldGUID = ld.SaleBldGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSetBldDtl b with(nolock) ON  ld.SaleBldGUID = b.BldGUID AND  b.Subject = 4
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSet c with(nolock) on b.CarryOverMainSetGUID = c.CarryOverMainSetGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d with(nolock) ON  ld.SaleBldGUID = d.BldGUID AND d.Subject = 4 and d.CarryOverMainGUID = bb.CarryOverMainGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain e with(nolock) on d.CarryOverMainGUID = e.CarryOverMainGUID
        -- where gc.ProjGUID = '116A20D9-2A43-E811-80BA-E61F13C57837'
		group by ld.SaleBldGUID

		--select SaleBldGUID,占压资金_全口径 into #zy from dss.dbo.nmap_s_资源情况 ;
		select SaleBldGUID,isnull(占压资金_全口径,0)+isnull(已投资未落实_占压资金_全口径,0)+isnull(开发受限_占压资金_并表口径,0) as 占压资金_全口径  
		into #zy
		from dss.dbo.nmap_s_资源情况 

        --增加回笼字段，累计回笼、当年回笼、当月回笼
        SELECT 
            bd.BldGUID,
            sum(r.累计回笼金额) as 累计回笼金额,
            sum(r.累计本年回笼金额) as 累计本年回笼金额,
            sum(r.累计本月回笼金额) as 累计本月回笼金额
        INTO #ljhl
        FROM dbo.s_gsfkylbmxb r
        INNER JOIN dbo.p_room r1 ON r1.RoomGUID = r.RoomGUID
        LEFT JOIN dbo.p_Building bd ON bd.BldGUID = r1.BldGUID
        WHERE DATEDIFF(DAY, qxDate, getdate()) = 0
        GROUP BY bd.BldGUID


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

			ldcz.总产值/10000 as 总产值,
            ldcz.已完成产值/10000 as 已完成产值,
			ldcz.待发生产值/10000 as 待发生产值,
            ldcz.合同约定应付金额/10000 as 合同约定应付金额,
            ldcz.累计支付金额/10000 as 累计支付金额,
            ldcz.产值未付/10000 as 产值未付,
            ldcz.应付未付/10000 as 应付未付,
            zs.持有套数,
            zs.持有面积,
            BA.土地款单方*(mj.自持面积+mj.可售面积)/10000.0 土地分摊金额,
            ldcz.累计支付金额/10000 除地价外直投分摊金额,
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
            tag.BuildTagValue as 赛道图标签,
			zy.占压资金_全口径 as 占压资金,

            --20250805 
            --增加回笼字段，累计回笼、当年回笼、当月回笼
            hl.累计回笼金额/10000 as 累计回笼金额,
            hl.累计本年回笼金额/10000 as 累计本年回笼金额,
            hl.累计本月回笼金额/10000 as 累计本月回笼金额,

            --用地面积、可售面积、计容面积、自持面积、（自持+可售）面积、、地上可售面积、地上自持面积、地上可售面积+地上自持面积
            isnull(mj.用地面积,0)*isnull(cp_rate.zjm_ratio,1) as 用地面积,
            isnull(mj.可售面积,0) as 可售面积,
            isnull(mj.计容面积,0) as 计容面积,
            isnull(mj.自持面积,0) as 自持面积,
            isnull(mj.自持可售面积,0)  as 自持可售面积,
            isnull(mj.地上可售面积,0) as 地上可售面积,
            isnull(mj.地上自持面积,0) as 地上自持面积,
            isnull(mj.地上自持可售面积,0) as 地上可售面积地上自持面积
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
		left join #zy zy on zy.SaleBldGUID = ms.SaleBldGUID
        left join #ljhl hl on hl.BldGUID = ms.SaleBldGUID
        left join #cpbld_rate cp_rate on cp_rate.SaleBldGUID = ms.SaleBldGUID
        ORDER BY dv.DevelopmentCompanyName,
                 p.ProjCode;

				
        DROP TABLE #jd,#p,#p0,#hz,#ms,#st,#base,#bnqy,#df,#hlpp_bld,#hlpp_product,#jlr,#key,#xm,
                   #dfhz,#bld_lst,#bld_st,#con,#con2024,#feebck,#hz_st,#ld_rate,#ld_st_sale,
				   #proj_rate,#proj_st,#qy_st,#rg_st,#t,#ts_st,#vrt,#gcbld_rate,#tj_Rate,#cpbld_rate,
                   #vor,#htnotfee,#fqcz,#ldcz,#htrate,#zy,#ljhl,#zs_area,#mj,#sftax,#xsjz,#jzcb,#CarryOverMbb,
                   #Budget,#yfs,#yjl,#hy,#hygh,#hygh_new;
    END;
END