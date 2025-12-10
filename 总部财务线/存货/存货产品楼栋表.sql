/*
 EXEC usp_cb_产品楼栋存货分析报表 '275B7A4E-4AB3-408E-A43A-1BA6AC5B0321'
*/


 create or  alter  PROC [dbo].[usp_cb_产品楼栋存货分析报表] (
    @var_buguid VARCHAR(MAX) -- 平台公司GUID，多个用逗号分隔
)
AS
BEGIN
        SELECT p.*, 
		p.AcquisitionDate as   获取时间
        INTO #p
        FROM erp25.dbo.mdm_Project p
        WHERE 1 = 1
              --AND p.DevelopmentCompanyGUID IN (
              --                                    SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
              --                                )
              AND p.Level = 2;    


			
  --缓存产品楼栋
 SELECT DISTINCT 
            dc.DevelopmentCompanyName,
            p.DevelopmentCompanyGUID,
            ms.SaleBldGUID,
            gc.GCBldGUID,
            p.ParentProjGUID,
			pp.ProjName as Projname,
            p.ProjName fqName,
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
            c.ztguid,
            c.是否停工,
            ms.HouseNum,
			concat(gc.BldName,'-',ms.BldName) as BldName
			-- star.BuildStarLogo
       INTO #ms
        FROM erp25.dbo.mdm_SaleBuild ms
        INNER JOIN  erp25.dbo.mdm_Product pr ON pr.ProductGUID = ms.ProductGUID
        INNER JOIN erp25.dbo.mdm_GCBuild gc ON gc.GCBldGUID = ms.GCBldGUID
		inner join  erp25.dbo.mdm_Project p on p.ProjGUID =gc.ProjGUID
		left join   erp25.dbo.mdm_Project pp on pp.ProjGUID =p.ParentProjGUID
		inner join erp25.dbo.p_DevelopmentCompany dc on dc.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
        -- INNER JOIN #p0 p ON p.ProjGUID = gc.ProjGUID
       --  LEFT JOIN #st st ON ISNULL(ms.ImportSaleBldGUID, ms.SaleBldGUID) = st.BldGUID
        LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b ON ms.GCBldGUID = b.BuildingGUID
        LEFT JOIN MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport c ON b.budguid = c.ztguid 

    -- 已审核的拍照版本找到引入成本的计提土地款、资本化利息、开发间接费金额
    SELECT 
        mp.ParentProjGUID as ProjGUID, -- 项目GUID
        sum(isnull(jt.Tdk,0)) / 10000.0 as Tdk, -- 土地款
        sum(isnull(jt.zbhlxje,0)) / 10000.0 as zbhlxje, -- 资本化利息
        sum(isnull(jt.kfjjfje,0)) / 10000.0 as kfjjfje-- 开发间接费 
    into #jt
    FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockJt jt with (nolock)
    INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = jt.ProjGUID
    INNER JOIN [172.16.4.131].[TaskCenterData].dbo.cb_StockFtProjVersionZbPhoto zb   ON jt.StockJtGUID = zb.StockJtGUID
    INNER JOIN (
          -- ProjGUID存在多个数据用;拼接的情况，需要拆分
              SELECT  
                        ROW_NUMBER() OVER (
                            PARTITION BY ProjGUID ORDER BY PhotoDate DESC
                        ) AS num, -- 取每个项目最新的审核版本
                        VersionGUID,
                        ProjGUID AS ProjGUID,   -- 拆分后的ProjGUID
                        ProjName,
                        PhotoDate,
                        DateSource
                    FROM
                    (
                        SELECT 
                            VersionGUID,
                            ProjName,
                            PhotoDate,
                            DateSource,
                            SplitProjGUIDs.AllItem as ProjGUID
                        FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtProjVersionPhoto with (nolock)
                        CROSS APPLY (
                            SELECT AllItem 
                            FROM fn_Split(ProjGUID, ';')
                        ) SplitProjGUIDs
                        WHERE ApproveState = '已审核'  and  DateSource ='线上分摊'     -- 只取已审核的版本
                    ) t
    ) vr 
        ON zb.VersionGUID = vr.VersionGUID 
        AND jt.ProjGUID = vr.ProjGUID 
        AND vr.num = 1
        inner join #p pj on pj.projguid = mp.ParentProjGUID
        group by  mp.ParentProjGUID


        -- 存货分摊项目分期拍照表 cb_StockFtCostImportPhoto
        SELECT
            mp.ParentProjGUID as ProjGUID, -- 项目GUID
            --  ftCostimp.ProjName,
            SUM(ftCostimp.JacbSf) / 10000.0 AS JacbSf, -- 建安成本-实付
            SUM(ftCostimp.JacbJt) / 10000.0 AS JacbJt, -- 建安成本-计提
            SUM(ftCostimp.Jacb)  / 10000.0 AS Jacb      -- 建安成本-Jacb
        into #jacb 
        FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtCostImportPhoto ftCostimp with (nolock)
        INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = ftCostimp.ProjGUID
        INNER JOIN (
               -- ProjGUID存在多个数据用;拼接的情况，需要拆分
              SELECT  
                        ROW_NUMBER() OVER (
                            PARTITION BY ProjGUID ORDER BY PhotoDate DESC
                        ) AS num, -- 取每个项目最新的审核版本
                        VersionGUID,
                        ProjGUID AS ProjGUID,   -- 拆分后的ProjGUID
                        ProjName,
                        PhotoDate,
                        DateSource
                    FROM
                    (
                        SELECT 
                            VersionGUID,
                            ProjName,
                            PhotoDate,
                            DateSource,
                            SplitProjGUIDs.AllItem as ProjGUID
                        FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtProjVersionPhoto with (nolock)
                        CROSS APPLY (
                            SELECT AllItem 
                            FROM fn_Split(ProjGUID, ';')
                        ) SplitProjGUIDs
                        WHERE ApproveState = '已审核'  and  DateSource ='线上分摊'     -- 只取已审核的版本
                    ) t
        ) vr
            ON ftCostimp.VersionGUID = vr.VersionGUID
            AND ftCostimp.ProjGUID = vr.ProjGUID
            AND vr.num = 1
        inner join #p pj on pj.projguid = mp.ParentProjGUID
        group by mp.ParentProjGUID

        -- 获取产值月度评审数据
        SELECT 
                bld.OutputValueMonthReviewGUID,          -- 产值月度评审GUID
                mp.ParentProjGUID as ProjGUID,
                vr.ProjGUID as fqProjGUID,
                bld.ProductType,
                bld.ProductName,
                bld.BusinessType,
                bld.Standard,
                bld.BldGUID,                             -- 楼栋GUID
                bld.BldName,                             -- 楼栋名称
                bld.ProdBldGUID,                         -- 产品楼栋GUID
                bld.ProdBldName,                         -- 产品楼栋名称
                bld.Zcz /10000.0 as Zcz,                                 -- 总产值
                bld.Xmpdljwccz /10000.0 as Xmpdljwccz                           -- 项目累计已完成产值
            INTO #czld
            FROM MyCost_Erp352.dbo.cb_OutputValueReviewProdBld bld with (nolock)
            INNER JOIN (
                SELECT 
                    ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY ReviewDate DESC) AS num, -- 取每个项目最新的审核版本
                    OutputValueMonthReviewGUID,
                    ProjGUID,
                    ReviewDate
                FROM MyCost_Erp352.[dbo].[cb_OutputValueMonthReview] with (nolock)
                WHERE ApproveState = '已审核'            -- 只取已审核的版本
            ) vr 
                ON vr.OutputValueMonthReviewGUID = bld.OutputValueMonthReviewGUID 
                AND vr.num = 1        
            inner join erp25.dbo.mdm_Project mp with (nolock) on mp.ProjGUID =vr.ProjGUID
            inner join #p pj on pj.projguid = mp.ParentProjGUID  -- 关联项目
       
       -- 存货楼栋明细
            SELECT  
                *,
                CASE 
                    WHEN SUM(IsBuildKg) OVER(PARTITION BY fqProjGUID) <> 0 
                            AND COUNT(IsBuildKg) OVER(PARTITION BY fqProjGUID) = SUM(IsBuildKg) OVER(PARTITION BY fqProjGUID)
                    THEN 1 
                    ELSE 0 
                END AS isAllBuildKg,
                case when  SUM(IsBuildKg) OVER(PARTITION BY fqProjGUID) =0 then 1 else  0  end  as isAllBuildNotKg, -- 所有楼栋都没有开工
                CASE 
                    WHEN SUM(TotalCost) OVER (PARTITION BY ProjGUID) = 0 
                        THEN 0 
                        ELSE TotalCost / SUM(TotalCost) OVER (PARTITION BY ProjGUID) 
                END AS TotalCostSumRate
            INTO #chld
            FROM (
                SELECT 
                    DISTINCT
                    mp.ParentProjGUID              AS ProjGUID,            -- 项目GUID
                    sfp.ProjGUID                   AS fqProjGUID,          -- 分期GUID
                    vr.VersionGUID,
                    vr.PhotoDate,
                    vr.DateSource,      -- 存货分摊导入模式：线下分摊/线上分摊 
                    sfp.BldGUID,                                         -- 楼栋GUID
                    sfp.BldName,                                         -- 楼栋名称
                    sfp.ProductBldGUID,                                   -- 产品楼栋GUID
                    sfp.ProductBldName,                                   -- 产品楼栋名称
                    pt.ProductType,                                       -- 产品类型
                    pt.ProductName,                                       -- 产品名称
                    pt.BusinessType,                                      -- 商品类型
                    pt.Standard,                                          -- 状态标准
                    sfp.IsKg,                                             -- 是否开工
                    sfp.IsYsxx,                                           -- 是否达预算形象
                    sfp.IsGb,                                             -- 是否竣工备案      
                    sfp.IsJz,                                             -- 是否已结转 
                    sfp.IsCost,                                           -- 是否存成本                    
                    CASE WHEN sfp.IsKg = N'是' THEN 1 ELSE 0 END AS IsBuildKg,    --（1-是 0-未开工）
                    case when sfp.IsYsxx = N'是' then 1 else 0 end as IsBuildYsxx,    --（1-是 0-未达预算形象）
                    case when sfp.IsGb = N'是' then 1 else 0 end as IsBuildGb,    --（1-是 0-未竣工备案）
                    --    case when IsJz = N'是' then 1 else 0 end as IsBuildJz,    --（1-是 0-未已结转）
                    sfp.TotalCost,                                        -- 存货成本总数
                    sfp.Tdk,                                              -- 土地款
                    sfp.Kfjjfje,                                          --  开发间接费
                    sfp.Zbhlxje,                                          -- 资本化利息 
                    sfp.Tdk_cejz,	-- 二次分摊-土地款-差额已结转
                    sfp.Zbhlxje_cejz,	-- 二次分摊-资本化利息金额-差额已结转

                    isnull(sfp.Tdk,0) /10000.0 as 土地款,
                    isnull(sfp.Kfjjfje,0) /10000.0 as 开发间接费,
                    isnull(sfp.Zbhlxje,0) /10000.0  as 资本化利息,
                    case when DateSource ='线上分摊' and  sfp.IsJz=1 then sfp.Tdk_cejz else 0  end /10000.0 as 土地款倒挤差额,
                    case when DateSource ='线上分摊' and  sfp.IsJz=1 then sfp.Zbhlxje_cejz else 0  end /10000.0 as 资本化利息倒挤差额,

                    sfp.Zjm,                                              -- 建筑面积
                        -- 若为线上分摊，取二次分摊处的结转总金额；
                        -- 若为线下导入，取合作项目导入处的累计已结转开发产品金额
                    case when DateSource = '线下分摊' then sfp.Totaldevmj else  sfp.jz_mjgs end  as jz_mjgs,                                          -- 已结转面积套数
                    case when DateSource = '线下分摊' then sfp.Totaldevje else  sfp.jz_TotalCost end as jz_TotalCost,                                      -- 已结转总成本 
                    sfp.Wkgtdje,                                           -- 存货结果输出-未开工土地金额，需要增加判断逻辑，如果当前分期下的所有楼栋都没有开工，采取存货拍照表上的未开工分期的土地款金额
                    sfip.jacbjt,                                            -- 建安成本计提
                    sfip.JacbSf,                                            -- 建安成本实付
                    -- 线下分摊模式，判断楼栋是否竣备，如果已经竣备按照100%分摊，如果未竣备按照70%分摊
                    case when DateSource ='线下分摊' and  isnull(sfp.IsGb,'否') ='否' then ISNULL(sfp.TotalCost, 0) * 0.7
                        when DateSource = '线下分摊' and isnull(sfp.IsGb,'否') ='是' then ISNULL(sfp.TotalCost, 0) end   / 10000.0 as 线下分摊_实际已付,

                    -- 新增字段 2025-12-03  
                    isnull(sfp.Xmpdljwccz,0) / 10000.0 as 产品楼栋产值,
                    isnull(sfp.Jacb,0)  / 10000.0 as  产品楼栋建安存货金额,
                    isnull(sfp.Jacb_cejz,0) /10000.0 as 建安成本倒减差额
                FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtCostPhoto sfp with (nolock)
                INNER JOIN erp25.dbo.mdm_SaleBuild sb  with (nolock) ON sfp.ProductBldGUID = sb.SaleBldGUID
                INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = sfp.ProjGUID
                LEFT JOIN erp25.dbo.mdm_Product pt with (nolock) ON pt.ProductGUID = sb.ProductGUID
                INNER JOIN (
                    -- ProjGUID存在多个数据用;拼接的情况，需要拆分
                    SELECT  
                        ROW_NUMBER() OVER (
                            PARTITION BY ProjGUID ORDER BY PhotoDate DESC
                        ) AS num, -- 取每个项目最新的审核版本
                        VersionGUID,
                        ProjGUID AS ProjGUID,   -- 拆分后的ProjGUID
                        ProjName,
                        PhotoDate,
                        DateSource
                    FROM
                    (
                        SELECT 
                            VersionGUID,
                            ProjName,
                            PhotoDate,
                            DateSource,
                            SplitProjGUIDs.AllItem as ProjGUID
                        FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtProjVersionPhoto with (nolock)
                        CROSS APPLY (
                            SELECT AllItem 
                            FROM fn_Split(ProjGUID, ';')
                        ) SplitProjGUIDs
                        WHERE ApproveState = '已审核'    -- 只取已审核的版本
                    ) t
                   ) vr  ON vr.VersionGUID = sfp.VersionGUID 
                    AND sfp.ProjGUID = vr.ProjGUID 
                    AND vr.num = 1                                     -- 只取最新版本
                    left join [172.16.4.131].[TaskCenterData].dbo.cb_StockFtCostImportPhoto sfip with (nolock) on 
                                                                                  sfip.projguid =sfp.projguid 
                                                                                and sfip.VersionGUID =vr.VersionGUID
                                                                                and sfip.ProductBldGUID =sfp.ProductBldGUID
                    inner join #p pj on pj.projguid = mp.ParentProjGUID  -- 关联项目
                ) t


				    -- 取M002汇总表
    SELECT DISTINCT
        m002.projguid, 
        m002.versionType,
        产品类型,
        产品名称,
        商品类型,
        装修标准,
        盈利规划营业成本单方,
        盈利规划股权溢价单方,
        盈利规划营销费用单方,
        盈利规划综合管理费单方协议口径,
        盈利规划税金及附加单方
    INTO #M002
    FROM [172.16.4.161].[HighData_prod].[dbo].data_wide_dws_qt_M002项目业态级毛利净利表 m002 with (nolock)
    inner join #p pj on pj.projguid = m002.projguid
    WHERE  versionType='累计版' -- versionType IN ('累计版', '本年版');

      print '取M002汇总表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

 -- 取F056项目 拍照版本的
    SELECT DISTINCT
        mp.ParentProjGUID as ProjGUID, -- 项目GUID
        mp.projguid as FqProjGUID,
        salebldguid,
        赛道图标签,
        产品类型,
        产品名称,
        装修标准,
        商品类型,
        总建面,
        总可售面积 * 10000 as 总可售面积,
        已售货值,
        已售货值不含税,
        已售面积 * 10000.0 as 已售面积,
        已售套数,
        待售货值,
        未售货值不含税,
        待售面积 *10000.0 as 待售面积,
        待售套数,
        实际开工完成日期,
        正式开工预计完成时间,
        达到预售形象完成日期,
        竣工备案完成日期,
        是否持有,
        是否停工,
        是否可售,
        持有面积 *10000.0 as 持有面积,
        case when isnull(saleld.已建房间数量,0) > 0 then  '是' else '否' end  as  是否建房间,
        ( case when isnull(F056.总建面,0)<>0 and  isnull(f056.总可售面积,0) =0 and isnull(F056.持有面积,0) =0  then 1 else 
              case when (isnull(F056.总可售面积,0) + isnull(F056.持有面积,0))=0  then  0 
                  else ( isnull(F056.待售面积,0)+ isnull(F056.持有面积,0) ) / (isnull(F056.总可售面积,0) + isnull(F056.持有面积,0))  end 
        end  ) as 未售面积占比
    into #F06Ld
    FROM [172.16.4.161].[HighData_prod].[dbo].[data_wide_dws_qt_F05601] F056 with (nolock)
    INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = F056.ProjGUID
    left join (
        select  BldGUID,count(1) 已建房间数量 
        from erp25.dbo.p_room
        where  IsVirtualRoom =0
        group by  BldGUID
    ) saleld on F056.salebldguid= saleld.BldGUID
    INNER JOIN #p pj  ON pj.projguid = mp.ParentProjGUID


--  SELECT  
--         ProjGUID,
--         产品类型,
--         产品名称,
--         装修标准,
--         商品类型,
--         sum(总建面) as 总建面,        
--         SUM(已售货值) AS 已售货值,
--         SUM(已售面积) AS 已售面积,
--         SUM(已售套数) AS 已售套数

--         -- sum(近六月签约金额不含税) as 近六月签约金额不含税,
--         -- sum(近六月签约金额均价不含税) as 近六月签约金额均价不含税,
--         -- sum(近六月签约面积) as 近六月签约面积,
--         -- sum(近三月签约金额不含税) as 近三月签约金额不含税,
--         -- sum(近三月签约金额均价不含税) as 近三月签约金额均价不含税,
--         -- sum(近三月签约面积) as 近三月签约面积
--     INTO #F056
--     FROM #F06Ld with (nolock)
--     GROUP BY 
--         ProjGUID,
--         产品类型,
--         产品名称,
--         装修标准,
--         商品类型

	   -- 按楼栋统计近三个月销售情况
    SELECT 
        Sale.ParentProjGUID, 
        Sale.BldGUID as BuildingGUID,
        -- 近三月签约金额（万元）
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                ELSE 0
            END
        ) / 10000.0 AS 近三月签约金额,  -- 万元

        -- 近三月签约套数
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                ELSE 0
            END
        ) AS 近三月签约套数
    into #SaleBld
    FROM 
        [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_SalesPerf Sale  with (nolock)      -- 销售合同明细表
        -- INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_Building] pb with (nolock) ON Sale.BldGUID = pb.BuildingGUID AND pb.BldType = '产品楼栋'
        INNER JOIN #p pj ON pj.projguid = Sale.ParentProjGUID
    where  Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
    GROUP BY 
        Sale.ParentProjGUID, 
        Sale.BldGUID  -- 父项目GUID


	 -- 开发贷
    SELECT 
        ProductBldGUID, 
        SUM(ISNULL(放款金额, 0)) AS 放款金额,
        sum(isnull(贷款合同期限,0)) as 贷款合同期限,
        sum(isnull(本年计划还款金额,0)) as 本年计划还款金额,
        sum(isnull(本年实际还款金额,0)) as 本年实际还款金额
    into #BldKfd
    FROM (
        SELECT DISTINCT
            ProjGUID AS 项目GUID,             -- 项目GUID
            ProductBldGUID ,   -- 产品楼栋GUID
            Fkje AS 放款金额,                 -- 放款金额
            DkContractCode AS 贷款合同名称,   -- 贷款合同名称
            DkContractDate AS 贷款合同日期,    -- 贷款合同日期
            datediff(day,DkContractDate,getdate()) /365.0 as 贷款合同期限, -- 按年统计
            CurYearPlanAmount as 本年计划还款金额,
            CurYearPayAmount as 本年实际还款金额
        FROM 
            md_ProductBldKfd with (nolock)
    ) AS bldkfd
    GROUP BY 
        ProductBldGUID
   print '开发贷' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

 -- 汇总存货信息
    SELECT  
        ProjGUID,
        ProductType,
        ProductName,
        BusinessType,
        ProductBldGUID,

        导入方式,
        Standard,
        TotalCost, --存货成本总数,
        线下分摊_实际已付,
        Wkgtdje,
        建安成本实付,
        建安成本计提,

        土地款,
        开发间接费,
        资本化利息,
        土地款倒挤差额,
        资本化利息倒挤差额,

        未开工分期_未开工楼栋面积,
        未开工分期_未开工楼栋存货金额,

        未开工土地账龄,
        已开工分期_未开工楼栋面积,
        已开工分期_未开工楼栋存货金额,
        已开工分期_已开工未达可售条件楼栋面积,
        已开工分期_已开工未达可售条件楼栋存货金额,
        已开工分期_已达预售条件未竣备楼栋面积,
        已开工分期_已达预售条件未竣备楼栋存货金额,
        已开工分期_已竣备面积,
        已开工分期_已竣备存货金额,
        已开工分期_已开工分期未售存货计划转经营面积,
        已开工分期_已开工分期未售存货计划转经营金额,
        已开工分期_已开工分期已经营资产面积,
        已开工分期_已开工分期已经营资产存货金额,
        已开工分期_已开工分期未售存货不存成本面积,
        已开工分期_已开工分期未售存货不存成本未经营面积,
        拟退存货面积,
        拟退存货金额,
        拟换存货面积,
        拟换存货金额,
        拟调存货面积,
        拟调存货金额,

        -- 新增字段
        --结转开发产品面积,
        --结转开发产品金额,
        --结转主营业务成本面积,
        --结转主营业务成本金额,

        NULL   AS 存货按工程进度分类_经营资产存成本经营资产面积,
        NULL   AS 存货按工程进度分类_经营资产存成本经营资产金额,
        存货按工程进度分类_经营资产不存成本经营资产面积,

        -- 已结转存货
        存货按工程进度分类_成本结转面积,
        存货按工程进度分析_成本结转金额,

        存货按工程进度分类_已售金额,
        存货利润分析_已售金额,
        存货利润分析_已售金额不含税,
        存货利润分析_已售存货成本,
        存货利润分析_已售股权溢价,
        存货利润分析_已售费用,
        存货利润分析_已售税金,

        存货利润分析_未售金额,
        存货利润分析_未售金额不含税,
        存货利润分析_未售存货成本,
        存货利润分析_未售股权溢价,
        存货利润分析_未售费用,
        存货利润分析_未售税金,

        实际开工完成日期,
        正式开工预计完成时间,
        达到预售形象完成日期,
        竣工备案完成日期,

        已开工未达可售存货质量分析_账龄面积,
        已达可售条件未竣备但未售存货的质量分析_账龄面积,
        已竣备未售存货的质量分析_账龄面积,
        已竣备未售存货的质量分析按竣备起算_账龄面积,


        已达可售条件未竣备但未售存货的质量分析_存货套数,
        已达可售条件未竣备但未售存货的质量分析_存货面积,
        已达可售条件未竣备但未售存货的质量分析_存货金额,

        已达可售条件未竣备但未售存货的质量分析_冰冻存货套数,
        已达可售条件未竣备但未售存货的质量分析_冰冻存货面积,
        已达可售条件未竣备但未售存货的质量分析_冰冻存货金额,

        已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数,
        已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积,
        已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额,
        
        --已达可售条件未竣备但未售存货的质量分析_顶底存货套数,
        --已达可售条件未竣备但未售存货的质量分析_顶底存货面积,
        --已达可售条件未竣备但未售存货的质量分析_顶底存货金额,

        --已达可售条件未竣备但未售存货的质量分析_合计存货套数,
        --已达可售条件未竣备但未售存货的质量分析_合计存货面积,
        --已达可售条件未竣备但未售存货的质量分析_合计存货金额,

        已竣备未售存货的质量分析_存货套数,
        已竣备未售存货的质量分析_存货面积,
        已竣备未售存货的质量分析_存货金额,

        (isnull(已开工未达可售存货_总产值,0) + isnull(已开工未达可售存货_土地款,0) + isnull(已开工未达可售存货_开发间接费,0) + isnull(已开工未达可售存货_资本化利息,0)  + isnull(已开工未达可售存货_土地款倒挤差额,0) + isnull(已开工未达可售存货_资本化利息倒挤差额,0) )
        - ( isnull(已开工未达可售存货_存货余额,0) )
        - ( isnull(已开工未达可售存货_已完工产值,0) + isnull(已开工未达可售存货_土地款,0) + isnull(已开工未达可售存货_开发间接费,0) + isnull(已开工未达可售存货_资本化利息,0) +  isnull(已开工未达可售存货_土地款倒挤差额,0) + isnull(已开工未达可售存货_资本化利息倒挤差额,0) - isnull(已开工未达可售存货_存货余额,0) )  as 已开工未达可售存货质量分析_竣备待发生成本,
        已开工未达可售存货_存货余额 as 已开工未达可售存货质量分析_存货余额,
        已开工未达可售存货_土地款 as  已开工未达可售存货质量分析_土地款,
        已开工未达可售存货_开发间接费 as 已开工未达可售存货质量分析_开发间接费,
        已开工未达可售存货_资本化利息 as 已开工未达可售存货质量分析_资本化利息,
        已开工未达可售存货_土地款倒挤差额 as 已开工未达可售存货质量分析_土地款倒挤差额,
        已开工未达可售存货_资本化利息倒挤差额 as 已开工未达可售存货质量分析_资本化利息倒挤差额,
        已开工未达可售存货_总产值 as 已开工未达可售存货质量分析_总产值,
        已开工未达可售存货_已完工产值 as 已开工未达可售存货质量分析_已完工产值,

        融资余额_开发贷,
        融资余额_开发贷本年计划还款金额,
        融资期限_贷款合同期限,

        sum(融资期限_贷款合同期限) over(partition by ProjGUID) as 贷款合同期限_合计,
        sum(融资余额_开发贷) over(partition by ProjGUID) as 融资余额_开发贷_合计,

        SUM(TotalCost) OVER (PARTITION BY ProjGUID) AS TotalCostSum,
        CASE 
            WHEN SUM(TotalCost) OVER (PARTITION BY ProjGUID) = 0 
                THEN 0 
                ELSE TotalCost / SUM(TotalCost) OVER (PARTITION BY ProjGUID) 
        END AS TotalCostSumRate
    INTO #ch  
    FROM (

        SELECT 
            chld.ProjGUID,                                 -- 项目GUID
            chld.ProductType,                              -- 产品类型
            chld.ProductName,                              -- 产品名称
            chld.BusinessType,                             -- 商品类型
            chld.Standard,                                 -- 状态标准
            chld.ProductBldGUID,
            -- 导入方式字段修订：SQLServer中STRING_AGG写法有最低版本要求；部分环境需改为FOR XML PATH解决兼容性
            导入方式 = 
                STUFF((
                    SELECT ',' + ISNULL(t2.DateSource, '')
                    FROM #chld t2
                    WHERE 
                        t2.ProjGUID = chld.ProjGUID AND
                        t2.ProductType = chld.ProductType AND
                        t2.ProductName = chld.ProductName AND
                        t2.BusinessType = chld.BusinessType AND
                        t2.Standard = chld.Standard
                    GROUP BY t2.DateSource
                    FOR XML PATH('')
                ), 1, 1, ''),
            max(实际开工完成日期) as 实际开工完成日期,        --实际开工完成日期
            max(正式开工预计完成时间) as 正式开工预计完成时间, --正式开工预计完成时间
            max(达到预售形象完成日期) as 达到预售形象完成日期,
            max(竣工备案完成日期) as 竣工备案完成日期, --竣工备案完成日期

            sum(isnull(chld.Tdk,0)) /10000.0 as 土地款,
            sum(isnull(chld.Kfjjfje,0)) /10000.0 as 开发间接费,
            sum(isnull(chld.Zbhlxje,0)) /10000.0  as 资本化利息,
            sum(case when chld.DateSource ='线上分摊' and  chld.IsJz=1 then chld.Tdk_cejz else 0  end )/10000.0 as 土地款倒挤差额,
            sum(case when chld.DateSource ='线上分摊' and  chld.IsJz=1 then chld.Zbhlxje_cejz else 0  end )/10000.0 as 资本化利息倒挤差额,
         
            -- sum(isnull(chld.Tdk_cejz,0)) / 10000.0 as 土地款差额已结转,
            -- sum(isnull(chld.Zbhlxje_cejz,0)) /10000.0 as 资本化利息金额差额已结转,

            count(chld.ProductBldGUID) as 楼栋数量,
            sum( case when 实际开工完成日期 is not null and 达到预售形象完成日期 is null   then   datediff(day,实际开工完成日期,getdate()) / 365.0 end * isnull(Zjm,0))  AS 已开工未达可售存货质量分析_账龄面积, -- 该楼栋的账龄*该楼栋的建面
            sum( case when 竣工备案完成日期 is null   and  实际开工完成日期 is not null   then   datediff(day,实际开工完成日期,getdate()) / 365.0 end * isnull(Zjm,0))  AS 已达可售条件未竣备但未售存货的质量分析_账龄面积, -- 现在时间-开工时间
            sum( case when 竣工备案完成日期 is not null and  实际开工完成日期 is not null then   datediff(day,实际开工完成日期,getdate()) / 365.0 end * isnull(Zjm,0 ) )  AS 已竣备未售存货的质量分析_账龄面积,-- 现在时间-开工时间
            sum( case when 竣工备案完成日期 is not null then   datediff(day,竣工备案完成日期,getdate()) / 365.0 end * isnull(Zjm,0 ) )   AS 已竣备未售存货的质量分析按竣备起算_账龄面积,-- 现在时间-竣备时间  
          
            SUM(ISNULL(TotalCost, 0)) / 10000.0 AS TotalCost, -- 存货成本总数  
            max(case when IsBuildKg =0 then DATEDIFF(day, pj.获取时间, GETDATE()) / 365.0 end ) 未开工土地账龄,
            -- 若存货分摊为线下导入，按存货比例计算，未竣备*70%  已竣备*100%
            sum( case when DateSource ='线下分摊' and  isnull(IsBuildGb,0) =0 then ISNULL(TotalCost, 0) * 0.7
                      when DateSource = '线下分摊' and isnull(IsBuildGb,0) =1 then ISNULL(TotalCost, 0) end  ) / 10000.0 as 线下分摊_实际已付,
            
            sum( isnull(Wkgtdje,0)  ) /10000.0 as Wkgtdje,  -- 未开工的土地款

            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B1-退地' then isnull(Zjm,0) else 0 end ) as 拟退存货面积,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B1-退地' then isnull(Wkgtdje,0) else 0 end ) /10000.0 as 拟退存货金额,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B2-换地' then isnull(Zjm,0) else 0 end ) as 拟换存货面积,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B2-换地' then isnull(Wkgtdje,0) else 0 end ) /10000.0 as 拟换存货金额,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B3-调规' then isnull(Zjm,0) else 0 end ) as 拟调存货面积,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B3-调规' then isnull(Wkgtdje,0) else 0 end ) /10000.0 as 拟调存货金额,

            -- 新增字段
            --sum(case when  DateSource ='线上分摊' then isnull(jzDevelopcb.已结转开发产品成本面积,0) else  chld.Totaldevmj end ) as    结转开发产品面积,
            --sum(case when  DateSource ='线上分摊' then isnull(jzDevelopcb.已结转开发产品成本金额,0) else chld.Totaldevje /10000.0 end ) as    结转开发产品金额,
            --sum(case when  DateSource ='线上分摊' then isnull(jzMaincb.已结转主营业务成本面积,0) else chld.Totalmainmj  end  ) as    结转主营业务成本面积,
            --sum(case when  DateSource ='线上分摊' then isnull(jzMaincb.已结转主营业务成本金额,0) else chld.Totalmainje /10000.0 end ) as    结转主营业务成本金额,

            sum(case  when isAllBuildNotKg = 1 then isnull(Zjm,0) else 0 end )  as 未开工分期_未开工楼栋面积,  -- 项目下所有楼栋均为开工
            -- sum(case  when isAllBuildNotKg = 1 then isnull(TotalCost,0) else 0 end ) /10000.0 as 未开工分期_未开工楼栋存货金额,  -- 项目下所有楼栋均为开工
            sum(case  when isAllBuildNotKg = 1 then isnull(Wkgtdje,0) else 0 end ) /10000.0 as 未开工分期_未开工楼栋存货金额,  -- 项目下所有楼栋均为开工的土地款

            -- 已开工的分期的未售存货统一乘以未售面积占比，公建业态的未售面积占比等于1
            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =0 then 
                isnull(Zjm,0) * F056ld.未售面积占比
                else 0 end )  as 已开工分期_未开工楼栋面积,  -- 已开工的分期未售存货面积
            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =0 then 
                isnull(TotalCost,0) * F056ld.未售面积占比
                else 0 end ) /10000.0 as 已开工分期_未开工楼栋存货金额,  -- 已开工的分期未售存货金额
            -- ②-⑦ 若楼栋下有房间数据，则取房间的可售+自持面积汇总到产品楼栋；若楼底下无房间数据，则取产品楼栋的建筑面积
            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =0 
                and ( F056ld.赛道图标签 not in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') )  then 
                 case when F056ld.是否建房间 ='是' then isnull(F056ld.总可售面积,0) + isnull(F056ld.持有面积,0) else  isnull(Zjm,0) end 
                 * F056ld.未售面积占比
               else 0 end )  as 已开工分期_已开工未达可售条件楼栋面积,  -- 已开工的分期未售存货面积
            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =0 
                and ( F056ld.赛道图标签 not in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') ) then 
                 isnull(TotalCost,0) * F056ld.未售面积占比
                else 0 end ) /10000.0 as 已开工分期_已开工未达可售条件楼栋存货金额,  -- 已开工的分期未售存货金额
            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =0  then 
                  case when F056ld.是否建房间 ='是' then isnull(F056ld.总可售面积,0) + isnull(F056ld.持有面积,0) else  isnull(Zjm,0) end 
                * F056ld.未售面积占比
              else 0 end )  as 已开工分期_已达预售条件未竣备楼栋面积, -- 已开工的分期已达预售条件未竣备
            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =0  then 
               isnull(TotalCost,0) * F056ld.未售面积占比
               else 0 end ) /10000.0 as 已开工分期_已达预售条件未竣备楼栋存货金额,-- 已开工的分期已达预售条件未竣备

            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =1  and F056ld.是否可售 ='是' 
                  and ( F056ld.赛道图标签 not in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') ) 
                  then case when F056ld.是否建房间 ='是' then isnull(F056ld.总可售面积,0) + isnull(F056ld.持有面积,0) else  isnull(Zjm,0) end  
                  * F056ld.未售面积占比
                else 0 end )  as 已开工分期_已竣备面积, -- 已竣备可售
            sum(case  when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =1  and F056ld.是否可售 ='是' 
                  and ( F056ld.赛道图标签 not in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') ) then  
                isnull(TotalCost,0) * F056ld.未售面积占比
               else 0 end ) /10000.0 as 已开工分期_已竣备存货金额,-- 已竣备可售
            --计划转经营标签=①赛道图标签为“D类"；②或者是否自持属性为是，③或者产品楼栋的持有面积不为空
            sum(case when  isAllBuildNotKg = 0 and  IsBuildKg =1  and IsBuildGb =1  and F056ld.是否可售 ='否' and F056ld.是否持有 ='是'
               and ( F056ld.赛道图标签 not in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') ) then
               case when F056ld.是否建房间 ='是' then isnull(F056ld.总可售面积,0) + isnull(F056ld.持有面积,0) else  isnull(Zjm,0) end 
               * F056ld.未售面积占比
              else 0 end ) as 已开工分期_已开工分期未售存货计划转经营面积, -- 已竣备-计划转经营
            sum(case when  isAllBuildNotKg = 0 and  IsBuildKg =1  and IsBuildGb =1  and F056ld.是否可售 ='否' and F056ld.是否持有 ='是'
               and ( F056ld.赛道图标签 not  in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') )  then 
               isnull(TotalCost,0) * F056ld.未售面积占比
               else 0 end ) /10000.0 as 已开工分期_已开工分期未售存货计划转经营金额, -- 已竣备-计划转经营
            
            sum(case  when  isAllBuildNotKg = 0 and  IsBuildKg =1 and IsBuildGb =1 and ( F056ld.是否可售 ='是' or  (F056ld.是否可售 ='否' and F056ld.是否持有 ='是' ) )
               and ( F056ld.赛道图标签 in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') )  then  
               case when F056ld.是否建房间 ='是' then isnull(F056ld.总可售面积,0) + isnull(F056ld.持有面积,0) else  isnull(Zjm,0) end   
               * F056ld.未售面积占比
               else 0 end ) as 已开工分期_已开工分期已经营资产面积,
            sum(case  when  isAllBuildNotKg = 0 and  IsBuildKg =1 and IsBuildGb =1 and ( F056ld.是否可售 ='是' or  (F056ld.是否可售 ='否' and F056ld.是否持有 ='是' ) )
               and ( F056ld.赛道图标签 in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') )  then  
               isnull(TotalCost,0) * F056ld.未售面积占比 
               else 0 end ) /10000.0  as 已开工分期_已开工分期已经营资产存货金额,
        
        
            sum(case  when  isAllBuildNotKg = 0 and  IsBuildKg =1 and IsBuildGb =1 and ( F056ld.是否可售 ='否' and F056ld.是否持有 ='否' ) 
                then case when F056ld.是否建房间 ='是' then isnull(F056ld.总可售面积,0) + isnull(F056ld.持有面积,0) else  isnull(Zjm,0) end  
                 * F056ld.未售面积占比
                else 0 end ) as 已开工分期_已开工分期未售存货不存成本面积,
            sum(case  when  isAllBuildNotKg = 0 and  IsBuildKg =1 and IsBuildGb =1 and ( F056ld.是否可售 ='否' and F056ld.是否持有 ='否' ) 
                and ( F056ld.赛道图标签 not  in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') ) 
                then case when F056ld.是否建房间 ='是' then isnull(F056ld.总可售面积,0) + isnull(F056ld.持有面积,0) else  isnull(Zjm,0) end  
                 *  F056ld.未售面积占比
                else 0 end ) as 已开工分期_已开工分期未售存货不存成本未经营面积,
            
            sum((1.0-F056ld.未售面积占比 ) * isnull(TotalCost,0)) /10000.0 as 存货按工程进度分类_已售金额,
            -- 存货利润分析  
            sum(F056ld.已售货值) as 存货利润分析_已售金额,
            sum(F056ld.已售货值不含税) as 存货利润分析_已售金额不含税,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * isnull(m002.盈利规划营业成本单方,0)
                           else  isnull(已售面积,0) * isnull(m002.盈利规划营业成本单方,0)  end ) /10000.0 as    存货利润分析_已售存货成本,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * isnull(m002.盈利规划股权溢价单方,0) 
                           else  isnull(已售面积,0) * isnull(m002.盈利规划股权溢价单方,0)  end ) /10000.0 as  存货利润分析_已售股权溢价,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * (isnull(m002.盈利规划营销费用单方,0) + isnull(m002.盈利规划综合管理费单方协议口径,0))
                           else  isnull(已售面积,0) * (isnull(m002.盈利规划营销费用单方,0) + isnull(m002.盈利规划综合管理费单方协议口径,0))  end ) /10000.0 as 存货利润分析_已售费用,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * isnull(m002.盈利规划税金及附加单方,0) 
                           else  isnull(已售面积,0) * isnull(m002.盈利规划税金及附加单方,0)  end ) /10000.0 as  存货利润分析_已售税金,

            -- 存货利润分析_已售净利润,
            sum(F056ld.待售货值 ) as 存货利润分析_未售金额,
            sum(F056ld.未售货值不含税) as 存货利润分析_未售金额不含税,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) * isnull(m002.盈利规划营业成本单方,0)
                           else  isnull(待售面积,0) * isnull(m002.盈利规划营业成本单方,0)  end ) /10000.0 as    存货利润分析_未售存货成本,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) * isnull(m002.盈利规划股权溢价单方,0) 
                           else  isnull(待售面积,0) * isnull(m002.盈利规划股权溢价单方,0)  end ) /10000.0 as  存货利润分析_未售股权溢价,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) *(isnull(m002.盈利规划营销费用单方,0) + isnull(m002.盈利规划综合管理费单方协议口径,0))
                           else  isnull(待售面积,0) * (isnull(m002.盈利规划营销费用单方,0) + isnull(m002.盈利规划综合管理费单方协议口径,0))  end ) /10000.0 as 存货利润分析_未售费用,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) * isnull(m002.盈利规划税金及附加单方,0) 
                           else  isnull(待售面积,0) * isnull(m002.盈利规划税金及附加单方,0)  end ) /10000.0 as  存货利润分析_未售税金,
        
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then   F056ld.待售套数  else 0 end )  AS 已达可售条件未竣备但未售存货的质量分析_存货套数,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then   F056ld.待售面积  else 0 end )  AS 已达可售条件未竣备但未售存货的质量分析_存货面积,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then   F056ld.待售货值  else 0 end )  AS 已达可售条件未竣备但未售存货的质量分析_存货金额,

            -- 存货按工程进度分类
            NULL   AS 存货按工程进度分类_经营资产存成本经营资产面积,
            NULL   AS 存货按工程进度分类_经营资产存成本经营资产金额,
            -- F05603表不存成本业态+无可售面积+已竣备的建筑面积
            sum( case when isnull(IsCost,0) =0 and  isnull(F056ld.待售面积,0)<0 and  isnull(IsBuildGb,0) =1 then isnull(Zjm,0) else 0 end ) AS 存货按工程进度分类_经营资产不存成本经营资产面积,
            --  已结转
            sum( chld.jz_mjgs )  as 存货按工程进度分类_成本结转面积,
            sum( chld.jz_TotalCost  )  /10000.0 as 存货按工程进度分析_成本结转金额,
            -- 冰冻存货
            NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货套数,
            NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货面积,
            NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货金额,

            -- 2025-12-02 为计算【 已开工未达可售存货质量分析_竣备待发生成本】新增字段   
            SUM(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1  then ISNULL(TotalCost, 0) else  0  end ) / 10000.0 AS 已开工未达可售存货_存货余额, -- 存货成本总数   
            sum(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1  then isnull(chld.Tdk,0) else  0  end) /10000.0   已开工未达可售存货_土地款,
            sum(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1  then isnull(chld.Kfjjfje,0) else 0 end) /10000.0 as 已开工未达可售存货_开发间接费,
            sum(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1  then  isnull(chld.Zbhlxje,0) else 0  end) /10000.0 as 已开工未达可售存货_资本化利息,
            sum(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1   and chld.DateSource ='线上分摊' and  chld.IsJz=1  then chld.Tdk_cejz else 0  end )/10000.0 as  已开工未达可售存货_土地款倒挤差额,
            sum(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1   and chld.DateSource ='线上分摊' and  chld.IsJz=1  then chld.Zbhlxje_cejz else 0  end )/10000.0  as 已开工未达可售存货_资本化利息倒挤差额,
            sum(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1 then isnull(czld.Zcz,0) else 0 end )  AS 已开工未达可售存货_总产值,
            sum(case when isAllBuildNotKg = 0 and IsBuildKg =1  and  IsBuildYsxx =1 then isnull(czld.Xmpdljwccz,0) else 0 end )  AS 已开工未达可售存货_已完工产值,
            
            -- 近3个月无流速存货
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 and  isnull(sb.近三月签约套数,0)<=0 then  F056ld.待售套数 else  0 end  ) AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 and  isnull(sb.近三月签约套数,0)<=0 then  F056ld.待售面积 else  0 end  ) AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 and  isnull(sb.近三月签约套数,0)<=0 then  F056ld.待售货值 else  0 end  ) AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额,
            ---- 顶底存货
            --sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then isnull(LHF.[楼层天地层未售住宅套数],0) else  0  end    ) as 已达可售条件未竣备但未售存货的质量分析_顶底存货套数,
            --sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then isnull(LHF.[楼层天地层未售住宅面积],0) else  0  end    ) AS 已达可售条件未竣备但未售存货的质量分析_顶底存货面积,
            --sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then isnull(LHF.[楼层天地层未售住宅金额],0) /10000.0 else  0  end    ) AS 已达可售条件未竣备但未售存货的质量分析_顶底存货金额,

            ---- （按1冰冻存货、2顶底存货、3近三个月物流速存货、4一线判断低质量 的优先顺序判断）
            --sum( case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then 
            --        case when  isnull(sb.近三月签约套数,0) <=0 then F056ld.待售套数 else  isnull(LHF.[楼层天地层未售住宅套数],0) end  end )  AS 已达可售条件未竣备但未售存货的质量分析_合计存货套数,
            --sum( case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then 
            --       case when  isnull(sb.近三月签约套数,0)<=0 then F056ld.待售面积 else  isnull(LHF.[楼层天地层未售住宅面积],0) end  end ) AS 已达可售条件未竣备但未售存货的质量分析_合计存货面积,
            --sum( case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then 
            --       case when  isnull(sb.近三月签约套数,0)<=0 then F056ld.待售货值 else  isnull(LHF.[楼层天地层未售住宅金额],0) /10000.0   end  end ) AS 已达可售条件未竣备但未售存货的质量分析_合计存货金额,


            sum(case when IsBuildGb =1  then  F056ld.待售套数 else  0 end   )  AS 已竣备未售存货的质量分析_存货套数,
            sum(case when IsBuildGb =1  then  isnull(F056ld.待售面积,0) else  0 end   )  AS 已竣备未售存货的质量分析_存货面积,
            sum(case when IsBuildGb =1  then  isnull(F056ld.待售货值,0) else  0 end   )  AS 已竣备未售存货的质量分析_存货金额,

            sum(bldkfd.放款金额) as 融资余额_开发贷,
            sum(bldkfd.本年计划还款金额) as 融资余额_开发贷本年计划还款金额,
            sum(bldkfd.贷款合同期限) as 融资期限_贷款合同期限,

            sum(chld.jacbjt ) /10000.0 as 建安成本计提,                                            -- 建安成本计提
            sum(chld.JacbSf ) /10000.0 as 建安成本实付                                             -- 建安成本实付             
        FROM #chld chld with (nolock) 
        left join  #czld czld  on czld.ProdBldGUID = chld.ProductBldGUID
        left join  #F06Ld F056ld with (nolock) on F056ld.salebldguid = chld.ProductBldGUID
        --left join  #jzDevelopcb jzDevelopcb on jzDevelopcb.bldguid = chld.ProductBldGUID
        --left join  #jzMaincb jzMaincb on jzMaincb.bldguid = chld.ProductBldGUID
        --left join  #LHFloorBldHz LHF with (nolock) on LHF.BldGUID=chld.ProductBldGUID
        left join #SaleBld sb with (nolock) on sb.BuildingGUID = chld.ProductBldGUID
        left join #BldKfd bldkfd with (nolock) on bldkfd.ProductBldGUID = chld.ProductBldGUID
        left join #M002 m002 with (nolock)  on m002.projguid = chld.ProjGUID 
                              and m002.产品类型 = chld.ProductType 
                              and m002.产品名称 = chld.ProductName 
                              and m002.商品类型 = chld.BusinessType 
                              and m002.装修标准 = chld.Standard
        INNER JOIN #p pj ON pj.projguid = chld.ProjGUID 
        GROUP BY 
            chld.ProjGUID, 
            chld.ProductType, 
            chld.ProductName, 
            chld.BusinessType, 
            chld.Standard,
            chld.ProductBldGUID
    ) t

        /*-----------------2025-12-01新增存货财务支付口径相关指标结束----------------------------------------*/
TRUNCATE Table cb_产品楼栋存货分析报表

insert into cb_产品楼栋存货分析报表
-- 查询最终结果
SELECT 
    ms.DevelopmentCompanyGUID, -- 平台公司GUID
    ms.DevelopmentCompanyName,
    ms.Projname         AS 项目名称,
    ms.fqName           AS 分期,
    chld.ProjGUID       AS 项目GUID,         -- 项目GUID
    ms.BldCode          AS 产品楼栋编码,
    ms.BldName          AS 产品楼栋名称,
    ms.gcBldName        AS 工程楼栋名称,
    ms.zjm              AS 建筑面积,
    ch.导入方式,
    ms.dsjm             AS 地上建筑面积,
    ms.dxjm             AS 地下建筑面积,
    chld.ProductBldGUID as 产品楼栋GUID,
    chld.ProductType    AS 产品类型,          -- 产品类型
    chld.ProductName    AS 产品名称,          -- 产品名称
    chld.BusinessType   AS 商品类型,          -- 商品类型
    chld.Standard       AS 装修标准,           -- 状态标准


     ISNULL(chld.TotalCost, 0) / 10000.0   as   存货结构_存货余额,
            case when isnull(chld.线下分摊_实际已付,0) <> 0  then chld.线下分摊_实际已付 
                else  
                (
                     -- 线上分摊实际已付
                    ISNULL(jacb.JacbSf, 0) --项目 建安成本实付金额
                    + ISNULL(jt.Tdk, 0) -- 项目计提的土地款
                    + ISNULL(jt.zbhlxje, 0) -- 项目计提的资本化利息
                    + ISNULL(jt.kfjjfje, 0) -- 项目计提的开发间接费
                ) * chld.TotalCostSumRate  end  as   存货结构_实际已付,
            ISNULL(chld.TotalCost, 0) / 10000.0 
            - case when isnull(chld.线下分摊_实际已付,0) <> 0  then chld.线下分摊_实际已付 
                else   
                (
                    -- 线上分摊实际已付
                    ISNULL(jacb.JacbSf, 0)
                    + ISNULL(jt.Tdk, 0)
                    + ISNULL(jt.zbhlxje, 0)
                    + ISNULL(jt.kfjjfje, 0)
                ) * chld.TotalCostSumRate  end  as  存货结构_账面计提,

            (ISNULL(czld.Zcz, 0)  + isnull(chld.土地款,0) + isnull(chld.开发间接费,0) + isnull(chld.资本化利息,0) + isnull(chld.土地款倒挤差额,0) + isnull(chld.资本化利息倒挤差额,0) )  as 存货结构_总产值,
            isnull(czld.Xmpdljwccz,0) + isnull(chld.土地款,0) + isnull(chld.开发间接费,0) + isnull(chld.资本化利息,0) + isnull(chld.土地款倒挤差额,0) + isnull(chld.资本化利息倒挤差额,0) as  存货结构_已达产值,
            isnull(czld.Xmpdljwccz,0) + isnull(chld.土地款,0) + isnull(chld.开发间接费,0) + isnull(chld.资本化利息,0) + isnull(chld.土地款倒挤差额,0) + isnull(chld.资本化利息倒挤差额,0)
               - ISNULL(chld.TotalCost, 0) / 10000.0  as   存货结构_已达产值但未计提存货,
            (ISNULL(czld.Zcz, 0)  + isnull(chld.土地款,0) + isnull(chld.开发间接费,0) + isnull(chld.资本化利息,0) + isnull(chld.土地款倒挤差额,0) + isnull(chld.资本化利息倒挤差额,0) )
            - ISNULL(chld.TotalCost, 0) 
            - ( isnull(czld.Xmpdljwccz,0) + isnull(chld.土地款,0) + isnull(chld.开发间接费,0) 
                + isnull(chld.资本化利息,0) + isnull(chld.土地款倒挤差额,0) + isnull(chld.资本化利息倒挤差额,0) - ISNULL(chld.TotalCost, 0)  ) AS   存货结构_项目竣备待发生成本,
        
    ch.Wkgtdje  AS 存货按工程进度分类_未开工土地金额,
    ch.未开工分期_未开工楼栋面积,
    ch.未开工分期_未开工楼栋存货金额,
    isnull(ch.已开工分期_未开工楼栋存货金额,0) 
    +isnull(ch.已开工分期_已开工未达可售条件楼栋存货金额,0) 
    +isnull(ch.已开工分期_已达预售条件未竣备楼栋存货金额,0) 
    +isnull(ch.已开工分期_已竣备存货金额,0) 
    +isnull(ch.已开工分期_已开工分期未售存货计划转经营金额,0)     
    +isnull(ch.已开工分期_已开工分期已经营资产存货金额,0)   
    AS 存货按工程进度分类_已开工分期未售存货金额合计,-- 1+2+3+4+5+6
    isnull(ch.已开工分期_未开工楼栋面积,0) 
    +isnull(ch.已开工分期_已开工未达可售条件楼栋面积,0) 
    +isnull(ch.已开工分期_已达预售条件未竣备楼栋面积,0) 
    +isnull(ch.已开工分期_已竣备面积,0) 
    +isnull(ch.已开工分期_已开工分期未售存货计划转经营面积,0)  
    +isnull(ch.已开工分期_已开工分期已经营资产面积,0)
    +isnull(ch.已开工分期_已开工分期未售存货不存成本面积,0)                       
    AS 存货按工程进度分类_已开工分期未售存货面积合计,--1+2+3+4+5+6+7

    ch.已开工分期_未开工楼栋面积 AS 存货按工程进度分类_已开工分期未售存货未开工楼栋面积,-- ①未开工楼栋面积
    ch.已开工分期_未开工楼栋存货金额 AS 存货按工程进度分类_已开工分期未售存货未开工楼栋金额,-- ①未开工楼栋面积
    ch.已开工分期_已开工未达可售条件楼栋面积 AS 存货按工程进度分类_已开工分期未售存货已开工未达可售条件面积, -- ②已开工未达可售条件
    ch.已开工分期_已开工未达可售条件楼栋存货金额 AS 存货按工程进度分类_已开工分期未售存货已开工未达可售条件金额,-- ②已开工未达可售条件
    ch.已开工分期_已达预售条件未竣备楼栋面积 AS 存货按工程进度分类_已开工分期未售存货已达可售条件未竣备面积,-- ③已达可售条件未竣备
    ch.已开工分期_已达预售条件未竣备楼栋存货金额 AS 存货按工程进度分类_已开工分期未售存货已达可售条件未竣备金额, --  ③已达可售条件未竣备
    ch.已开工分期_已竣备面积 AS 存货按工程进度分类_已开工分期未售存货已竣备面积, -- ④已竣备面积
    ch.已开工分期_已竣备存货金额 AS 存货按工程进度分类_已开工分期未售存货已竣备金额, -- ④已竣备面积
    ch.已开工分期_已开工分期未售存货计划转经营面积  AS 存货按工程进度分类_已开工分期未售存货计划转经营面积,-- ⑤计划转经营标签=①赛道图标签为“D类"；
    ch.已开工分期_已开工分期未售存货计划转经营金额   AS 存货按工程进度分类_已开工分期未售存货计划转经营金额,-- ⑤计划转经营标签=①赛道图标签为“D类"； 
    ch.已开工分期_已开工分期已经营资产面积 as 存货按工程进度分类_已开工分期已经营资产面积, -- ⑥
    ch.已开工分期_已开工分期已经营资产存货金额 as 存货按工程进度分类_已开工分期已经营资产存货金额, --⑥
    ch.已开工分期_已开工分期未售存货不存成本面积  AS 存货按工程进度分类_已开工分期未售存货不存成本面积, -- ⑦
    ch.已开工分期_已开工分期未售存货不存成本未经营面积 as 存货按工程进度分类_已开工分期未售存货不存成本未经营面积, -- ⑦

    F056ld.已售面积               AS 存货按工程进度分类_已售面积,
        -- F056.已售货值               AS 存货按工程进度分类_已售金额,
    ch.存货按工程进度分类_已售金额 as 存货按工程进度分类_已售金额
-- into cb_产品楼栋存货分析报表
FROM 
    #chld chld
    INNER JOIN #ms ms ON chld.ProductBldGUID = ms.SaleBldGUID
    inner join #ch ch on ch.ProductBldGUID =chld.ProductBldGUID
    left join #czld czld on czld.ProdBldGUID = ms.salebldguid
    left join #jacb jacb on jacb.projguid = ms.ParentProjGUID
    left join #jt jt on jt.projguid = ms.ParentProjGUID
    left join  #F06Ld F056ld with (nolock) on F056ld.salebldguid = chld.ProductBldGUID


end 