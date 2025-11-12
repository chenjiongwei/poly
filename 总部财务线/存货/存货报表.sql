USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_存货分析报表]    Script Date: 2025/11/11 15:26:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 ALTER   PROC [dbo].[usp_cb_存货分析报表] (
    @var_buguid VARCHAR(MAX) -- 平台公司GUID，多个用逗号分隔
)
AS
BEGIN
    -- 项目分类说明
    -- 存量 就是 "存量项目"
    -- 增量 就是 "增量项目、⑦增量项目、已投资未落实"
    -- 但是其他的标签他还没说要归纳到哪里，销售日报的我先把其他的归纳到"其他"

    -- 步骤1：获取项目基本信息
    SELECT 
        flg.projguid AS 项目GUID,                -- 项目唯一标识
        flg.DevelopmentCompanyGUID,              -- 开发公司GUID
        flg.平台公司,                            -- 平台公司名称
        flg.推广名,                              -- 推广名
        flg.项目名,                              -- 项目名称
        flg.项目代码,                            -- 项目代码
        flg.投管代码,                            -- 投管代码
        flg.获取时间,                            -- 获取时间
        flg.并表方式,                            -- 并表方式（我司并表/不并表等）
        flg.项目五分类,                          -- 项目五分类
        CASE 
            WHEN flg.项目五分类 IN ('增量项目','⑦增量项目','已投资未落实') THEN '增量'
            WHEN flg.项目五分类 IN ('存量项目') THEN '存量'
            ELSE '其他' 
        END AS 存量增量分类
        -- flg.存量增量                          -- 存量增量标识（暂不使用）
    INTO #proj
    FROM erp25.dbo.vmdm_projectFlagnew flg with (nolock)
    INNER JOIN erp25.dbo.mdm_project p with (nolock) ON flg.projguid = p.projguid
    WHERE p.level = 2                            -- 只取二级项目
      AND flg.DevelopmentCompanyGUID IN (SELECT value FROM dbo.fn_Split2(@var_buguid, ',')) -- 按传入的公司GUID筛选



    -- 取一级项目的已投资未落实字段
    SELECT 
        pj.项目GUID, 
        b.VersionGuid,
        b.StartTime,-- 版本开始时间
        F016.项目代码, 
        ISNULL(累计投资_小计E_亿元, 0) * 10000.0 AS 已投资未落实金额   -- 万元
    into #F016
    FROM  
        dss.[dbo].[nmap_s_F016_表9已投资未落实] F016 with (nolock)
        INNER JOIN (
            -- 取2个月前当月最新的版本
            SELECT TOP 1
                ver.VersionGuid,      -- 版本唯一标识
                ver.StartTime         -- 版本开始时间
            FROM
                dss.[dbo].[nmap_RptVersion] ver with (nolock)
            WHERE
                ver.RptID = 'B593DEF7_B031_445C_9129_63026BADA454'
            ORDER BY 
                ver.StartTime DESC
        ) b ON b.VersionGuid = F016.VersionGuid
        INNER JOIN #proj pj ON pj.投管代码 = F016.项目代码

    -- 步骤2：获取存货楼栋排查最新数
   SELECT  
       *,
       CASE 
           WHEN SUM(IsBuildKg) OVER(PARTITION BY fqProjGUID) <> 0 
                AND COUNT(IsBuildKg) OVER(PARTITION BY fqProjGUID) = SUM(IsBuildKg) OVER(PARTITION BY fqProjGUID)
           THEN 1 
           ELSE 0 
       END AS isAllBuildKg
   INTO #chld
   FROM (
       SELECT 
           mp.ParentProjGUID              AS ProjGUID,            -- 项目GUID
           sfp.ProjGUID                   AS fqProjGUID,          -- 分期GUID
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
           case when IsGb = N'是' then 1 else 0 end as IsBuildGb,    --（1-是 0-未竣工备案）
        --    case when IsJz = N'是' then 1 else 0 end as IsBuildJz,    --（1-是 0-未已结转）
           sfp.TotalCost,                                        -- 存货成本总数
           sfp.Zjm,                                              -- 建筑面积
           sfp.jz_mjgs,                                          -- 已结转面积套数
           sfp.jz_TotalCost,                                      -- 已结转总成本 
           sfp.Wkgtdje                                           -- 存货结果输出-未开工土地金额，需要增加判断逻辑，如果当前分期下的所有楼栋都没有开工，采取存货拍照表上的未开工分期的土地款金额
       FROM [TaskCenterData].dbo.cb_StockFtCostPhoto sfp with (nolock)
       INNER JOIN erp25.dbo.mdm_SaleBuild sb  with (nolock) ON sfp.ProductBldGUID = sb.SaleBldGUID
       INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = sfp.ProjGUID
       LEFT JOIN erp25.dbo.mdm_Product pt with (nolock) ON pt.ProductGUID = sb.ProductGUID
       INNER JOIN (
           SELECT  
               ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY PhotoDate DESC) AS num, -- 取每个项目最新的审核版本
               VersionGUID,
               ProjGUID,
               ProjName,
               PhotoDate
           FROM [TaskCenterData].dbo.cb_StockFtProjVersionPhoto with (nolock)
           WHERE ApproveState = '已审核'    -- 只取已审核的版本
       ) vr 
           ON vr.VersionGUID = sfp.VersionGUID 
           AND sfp.ProjGUID = vr.ProjGUID 
           AND vr.num = 1                                     -- 只取最新版本
   ) t

    -- 已审核的拍照版本找到引入成本的计提土地款、资本化利息、开发间接费金额
   SELECT 
       mp.ParentProjGUID as ProjGUID, -- 项目GUID
    --    jt.ProjName,
       sum(isnull(jt.Tdk,0)) / 10000.0 as Tdk, -- 土地款
       sum(isnull(jt.zbhlxje,0)) / 10000.0 as zbhlxje, -- 资本化利息
       sum(isnull(jt.kfjjfje,0)) / 10000.0 as kfjjfje,-- 开发间接费 
       sum(isnull(jtdtl.累计实付土地款,0)) / 10000.0 as 累计实付土地款, --  万元
       sum(isnull(jtdtl.累计实付建安成本,0)) / 10000.0 as 累计实付建安成本, -- 万元
       sum(isnull(jtdtl.累计实付直投,0)) / 10000.0 as 累计实付直投 -- 万元
   into #jt
   FROM [TaskCenterData].dbo.cb_StockJt jt with (nolock)
   INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = jt.ProjGUID
   left  join (
      SELECT 
          StockJtGUID,
          SUM(CASE WHEN CostName = '土地款' THEN LjSfJeCur ELSE 0 END) AS 累计实付土地款,
          SUM(CASE WHEN CostName = '建安成本' THEN LjSfJeCurNotTax ELSE 0 END) AS 累计实付建安成本,
          sum(case when  costname in ('土地款','建安成本') then LjSfJeCur else 0 end)累计实付直投
      FROM TaskCenterData.dbo.cb_StockJtDtl jtdtl with (nolock)
      GROUP BY StockJtGUID
   ) jtdtl on jt.StockJtGUID = jtdtl.StockJtGUID
   INNER JOIN [TaskCenterData].dbo.cb_StockFtProjVersionZbPhoto zb   ON jt.StockJtGUID = zb.StockJtGUID
   INNER JOIN (
       SELECT  
           ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY PhotoDate DESC) AS num, -- 取每个项目最新的审核版本
           VersionGUID,
           ProjGUID,
           ProjName,
           PhotoDate
       FROM [TaskCenterData].dbo.cb_StockFtProjVersionPhoto  with (nolock)
       WHERE ApproveState = '已审核'            -- 只取已审核的版本
   ) vr 
       ON zb.VersionGUID = vr.VersionGUID 
       AND jt.ProjGUID = vr.ProjGUID 
       AND vr.num = 1
    inner join #proj pj on pj.项目GUID = mp.ParentProjGUID
    group by  mp.ParentProjGUID

    -- 统计财务计提中的土地款和建安成本实付
--     select  CostName='建安成本'  LjSfJeCurNotTax
-- from  cb_StockJtDtl

    -- 存货分摊项目分期拍照表 cb_StockFtCostImportPhoto
   SELECT
       mp.ParentProjGUID as ProjGUID, -- 项目GUID
      --  ftCostimp.ProjName,
       SUM(ftCostimp.JacbSf) / 10000.0 AS JacbSf, -- 建安成本-实付
       SUM(ftCostimp.JacbJt) / 10000.0 AS JacbJt, -- 建安成本-计提
       SUM(ftCostimp.Jacb)  / 10000.0 AS Jacb      -- 建安成本-Jacb
   into #jacb 
   FROM [TaskCenterData].dbo.cb_StockFtCostImportPhoto ftCostimp with (nolock)
   INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = ftCostimp.ProjGUID
   INNER JOIN (
       SELECT
           ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY PhotoDate DESC) AS num, -- 取每个项目最新的审核版本
           VersionGUID,
           ProjGUID,
           ProjName,
           PhotoDate
       FROM [TaskCenterData].dbo.cb_StockFtProjVersionPhoto with (nolock)
       WHERE ApproveState = '已审核' -- 只取已审核的版本
   ) vr
       ON ftCostimp.VersionGUID = vr.VersionGUID
       AND ftCostimp.ProjGUID = vr.ProjGUID
       AND vr.num = 1
   inner join #proj pj on pj.项目GUID = mp.ParentProjGUID
    group by mp.ParentProjGUID

--引入存货成本
--  select  * from  [TaskCenterData].dbo.cb_StockFtCostImport where  ProjGUID ='F0BC641F-B8C8-EF11-B3A6-F40270D39969'
--  select  * from  cb_StockFtProjVersion where  ProjGUID ='F0BC641F-B8C8-EF11-B3A6-F40270D39969'

--  select  * from  [TaskCenterData].dbo.cb_StockJt where  ProjGUID ='F0BC641F-B8C8-EF11-B3A6-F40270D39969'

--  select  * from  cb_StockFtProjVersionZb where  ProjGUID ='F0BC641F-B8C8-EF11-B3A6-F40270D39969'
--   select  * from  cb_StockFtProjVersionZbPhoto where  ProjGUID ='F0BC641F-B8C8-EF11-B3A6-F40270D39969'

    -- 取F056项目 拍照版本的
    SELECT 
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
        待售面积*10000.0 as 待售面积,
        待售套数,
        实际开工完成日期,
        正式开工预计完成时间,
        竣工备案完成日期,
        是否持有,
        持有面积  
    into #F06Ld
    FROM [172.16.4.161].[HighData_prod].[dbo].[data_wide_dws_qt_F05601] F056 with (nolock)
    INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = F056.ProjGUID
    INNER JOIN #proj pj  ON pj.项目GUID = mp.ParentProjGUID

    -- 将F056汇总到项目、产品类型、产品名称、装修标准、商品类型层级
    SELECT  
        ProjGUID,
        产品类型,
        产品名称,
        装修标准,
        商品类型,
        sum(总建面) as 总建面,        
        SUM(已售货值) AS 已售货值,
        SUM(已售面积) AS 已售面积,
        SUM(已售套数) AS 已售套数
        -- sum(近六月签约金额不含税) as 近六月签约金额不含税,
        -- sum(近六月签约金额均价不含税) as 近六月签约金额均价不含税,
        -- sum(近六月签约面积) as 近六月签约面积,
        -- sum(近三月签约金额不含税) as 近三月签约金额不含税,
        -- sum(近三月签约金额均价不含税) as 近三月签约金额均价不含税,
        -- sum(近三月签约面积) as 近三月签约面积
    INTO #F056
    FROM #F06Ld
    GROUP BY 
        ProjGUID,
        产品类型,
        产品名称,
        装修标准,
        商品类型

    -- 取M002汇总表
    SELECT DISTINCT
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
    INTO #M002
    FROM [172.16.4.161].[HighData_prod].[dbo].data_wide_dws_qt_M002项目业态级毛利净利表 with (nolock)
    inner join #proj pj on pj.项目GUID = projguid
    WHERE  versionType='累计版' -- versionType IN ('累计版', '本年版');

    -- 统计天地楼层的楼栋
    SELECT
        [ProjGUID],
        [BldGUID],
        [楼层总住宅套数],
        [楼层总已售住宅套数],
        [楼层非天地层未售住宅套数],
        [楼层非天地层未售住宅面积],
        [楼层非天地层未售住宅金额],
        [楼层天地层未售住宅套数],
        [楼层天地层未售住宅面积],
        [楼层天地层未售住宅金额]
    INTO #LHFloorBldHz
    FROM [172.16.4.161].[HighData_prod].[dbo].[data_wide_dws_s_LHFloorBldHz] with (nolock)


    -- 按楼栋统计近三个月销售情况
    SELECT 
        Sale.ParentProjGUID, 
        pb.BuildingGUID,
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
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_Building] pb with (nolock) -- 产品楼栋维度表
            ON Sale.BldGUID = pb.BuildingGUID
            AND pb.BldType = '产品楼栋'
        INNER JOIN #proj pj
            ON pj.项目GUID = Sale.ParentProjGUID

    GROUP BY 
        Sale.ParentProjGUID, 
        pb.BuildingGUID  -- 父项目GUID

   --- 股东投入余额
    SELECT 
        p.projguid,
        p.projname,
        SUM( ISNULL(oa.截止目前股东合作方投入余额C, 0) ) /10000.0 AS 截止目前股东投入余额, -- 万元
        sum( case when  isnull(oa.股东合作方简称,'') <> '' then ISNULL(oa.截止目前股东合作方投入余额C, 0) end ) /10000.0 AS 截止目前合作方投入余额, --万元
        SUM( case when  isnull(oa.股东合作方简称,'') = '' then ISNULL(oa.截止目前股东合作方投入余额C, 0) end ) /10000.0 AS 截止目前保利方投入余额 --万元
    INTO #Shareholder_investment 
    FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project p with (nolock)
    OUTER APPLY (
        SELECT 
            si.截止目前股东合作方投入余额C,
			si.股东合作方简称
        FROM 
            [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_Shareholder_investment si with (nolock)
        WHERE 
            si.明源代码 = p.ProjCode
            AND si.FillHistoryGUID IN (
                SELECT TOP 1 FillHistoryGUID
                FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_Shareholder_investment
                ORDER BY FillDate DESC
            )
    ) oa
    WHERE p.level = 2  -- 只统计二级项目
    GROUP BY p.projguid, p.projname

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

    -- 汇总存货信息
    SELECT  
        ProjGUID,
        ProductType,
        ProductName,
        BusinessType,
        Standard,
        TotalCost,
        Wkgtdje,
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
        已开工分期_已开工分期未售存货不存成本面积,
        拟退存货面积,
        拟退存货金额,
        拟换存货面积,
        拟换存货金额,
        拟调存货面积,
        拟调存货金额,

        NULL   AS 存货按工程进度分类_经营资产存成本经营资产面积,
        NULL   AS 存货按工程进度分类_经营资产存成本经营资产金额,
        存货按工程进度分类_经营资产不存成本经营资产面积,

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
        竣工备案完成日期,

        已达可售条件未竣备但未售存货的质量分析_存货套数,
        已达可售条件未竣备但未售存货的质量分析_存货面积,
        已达可售条件未竣备但未售存货的质量分析_存货金额,

        已达可售条件未竣备但未售存货的质量分析_冰冻存货套数,
        已达可售条件未竣备但未售存货的质量分析_冰冻存货面积,
        已达可售条件未竣备但未售存货的质量分析_冰冻存货金额,

        已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数,
        已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积,
        已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额,
        
        已达可售条件未竣备但未售存货的质量分析_顶底存货套数,
        已达可售条件未竣备但未售存货的质量分析_顶底存货面积,
        已达可售条件未竣备但未售存货的质量分析_顶底存货金额,

        已达可售条件未竣备但未售存货的质量分析_合计存货套数,
        已达可售条件未竣备但未售存货的质量分析_合计存货面积,
        已达可售条件未竣备但未售存货的质量分析_合计存货金额,

        已竣备未售存货的质量分析_存货套数,
        已竣备未售存货的质量分析_存货面积,
        已竣备未售存货的质量分析_存货金额,

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
            max(实际开工完成日期) as 实际开工完成日期,        --实际开工完成日期
            max(正式开工预计完成时间) as 正式开工预计完成时间, --正式开工预计完成时间
            max(竣工备案完成日期) as 竣工备案完成日期, --竣工备案完成日期
            SUM(ISNULL(TotalCost, 0)) / 10000.0 AS TotalCost, -- 存货成本总数  
            sum(case  when isAllBuildKg = 0 then isnull(Wkgtdje,0) else 0 end ) /10000.0 as Wkgtdje,  -- 未开工的土地款
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B1-退地' then isnull(Zjm,0) else 0 end ) as 拟退存货面积,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B1-退地' then isnull(Wkgtdje,0) else 0 end ) /10000.0 as 拟退存货金额,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B2-换地' then isnull(Zjm,0) else 0 end ) as 拟换存货面积,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B2-换地' then isnull(Wkgtdje,0) else 0 end ) /10000.0 as 拟换存货金额,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B3-调规' then isnull(Zjm,0) else 0 end ) as 拟调存货面积,
            sum(case  when isAllBuildKg= 0 and F056ld.赛道图标签 ='B3-调规' then isnull(Wkgtdje,0) else 0 end ) /10000.0 as 拟调存货金额,

            sum(case  when isAllBuildKg = 1 and IsBuildKg =0 then isnull(Zjm,0) else 0 end )  as 已开工分期_未开工楼栋面积,  -- 已开工的分期未售存货面积
            sum(case  when isAllBuildKg = 1 and IsBuildKg =0 then isnull(TotalCost,0) else 0 end ) /10000.0 as 已开工分期_未开工楼栋存货金额,  -- 已开工的分期未售存货金额
            sum(case  when isAllBuildKg = 1 and IsBuildKg =1  and  IsBuildYsxx =0 then isnull(Zjm,0) else 0 end )  as 已开工分期_已开工未达可售条件楼栋面积,  -- 已开工的分期未售存货面积
            sum(case  when isAllBuildKg = 1 and IsBuildKg =1  and  IsBuildYsxx =0 then isnull(TotalCost,0) else 0 end ) /10000.0 as 已开工分期_已开工未达可售条件楼栋存货金额,  -- 已开工的分期未售存货金额
            sum(case  when isAllBuildKg = 1 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =0 then isnull(Zjm,0) else 0 end )  as 已开工分期_已达预售条件未竣备楼栋面积,
            sum(case  when isAllBuildKg = 1 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =0 then isnull(TotalCost,0) else 0 end ) /10000.0 as 已开工分期_已达预售条件未竣备楼栋存货金额,
            sum(case  when isAllBuildKg = 1 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =1 then case when  isnull(IsJz,0) =1 then isnull(jz_mjgs,0)  else isnull(Zjm,0) end else 0 end )  as 已开工分期_已竣备面积,
            sum(case  when isAllBuildKg = 1 and IsBuildKg =1  and  IsBuildYsxx =1 and IsBuildGb =1 then case when  isnull(isjz,0) =1 then isnull(jz_TotalCost,0) else  isnull(TotalCost,0)  end   else 0 end ) /10000.0 as 已开工分期_已竣备存货金额,

            --计划转经营标签=①赛道图标签为“D类"；②或者是否自持属性为是，③或者产品楼栋的持有面积不为空
            sum(case when  isAllBuildKg = 1 and ( F056ld.赛道图标签 in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') 
                  or  F056ld.是否持有='是' or  isnull(F056ld.持有面积,0) >0 ) then isnull(Zjm,0) else 0 end ) as 已开工分期_已开工分期未售存货计划转经营面积,
            sum(case when  isAllBuildKg = 1 and ( F056ld.赛道图标签 in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') 
                  or  F056ld.是否持有='是' or   isnull(F056ld.持有面积,0) >0 )  then isnull(TotalCost,0) else 0 end ) /10000.0 as 已开工分期_已开工分期未售存货计划转经营金额,
            sum(case  when  isAllBuildKg = 1 and ( F056ld.赛道图标签 in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') 
            or  F056ld.是否持有='是' or   isnull(F056ld.持有面积,0) >0 ) and isnull(IsCost,0) =0 then isnull(F056ld.总建面,0) -isnull(F056ld.总可售面积,0) else 0 end ) as 已开工分期_已开工分期未售存货不存成本面积,
            -- 存货利润分析  
            sum(F056ld.已售货值 ) as 存货利润分析_已售金额,
            sum(F056ld.已售货值不含税) as 存货利润分析_已售金额不含税,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * isnull(m002.盈利规划营业成本单方,0)
                           else  isnull(已售面积,0) * isnull(m002.盈利规划营业成本单方,0)  end ) /10000.0 as    存货利润分析_已售存货成本,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * isnull(m002.盈利规划营业成本单方,0) 
                           else  isnull(已售面积,0) * isnull(m002.盈利规划股权溢价单方,0)  end ) /10000.0 as  存货利润分析_已售股权溢价,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * isnull(m002.盈利规划营业成本单方,0) 
                           else  isnull(已售面积,0) * (isnull(m002.盈利规划营销费用单方,0) + isnull(m002.盈利规划综合管理费单方协议口径,0))  end ) /10000.0 as 存货利润分析_已售费用,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(已售套数,0) * isnull(m002.盈利规划营业成本单方,0) 
                           else  isnull(已售面积,0) * isnull(m002.盈利规划税金及附加单方,0)  end ) /10000.0 as  存货利润分析_已售税金,
            -- 存货利润分析_已售净利润,
            -- 存货利润分析_已售净利率,
            
            sum(F056ld.待售货值 ) as 存货利润分析_未售金额,
            sum(F056ld.未售货值不含税) as 存货利润分析_未售金额不含税,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) * isnull(m002.盈利规划营业成本单方,0)
                           else  isnull(待售面积,0) * isnull(m002.盈利规划营业成本单方,0)  end ) /10000.0 as    存货利润分析_未售存货成本,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) * isnull(m002.盈利规划营业成本单方,0) 
                           else  isnull(待售面积,0) * isnull(m002.盈利规划股权溢价单方,0)  end ) /10000.0 as  存货利润分析_未售股权溢价,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) * isnull(m002.盈利规划营业成本单方,0) 
                           else  isnull(待售面积,0) * (isnull(m002.盈利规划营销费用单方,0) + isnull(m002.盈利规划综合管理费单方协议口径,0))  end ) /10000.0 as 存货利润分析_未售费用,
            sum(case when F056ld.产品类型 ='地下室/车库' then  isnull(待售套数,0) * isnull(m002.盈利规划营业成本单方,0) 
                           else  isnull(待售面积,0) * isnull(m002.盈利规划税金及附加单方,0)  end ) /10000.0 as  存货利润分析_未售税金,
        
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then   F056ld.待售套数  else 0 end )  AS 已达可售条件未竣备但未售存货的质量分析_存货套数,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then   F056ld.待售面积  else 0 end )  AS 已达可售条件未竣备但未售存货的质量分析_存货面积,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then   F056ld.待售货值  else 0 end )  AS 已达可售条件未竣备但未售存货的质量分析_存货金额,

            -- 存货按工程进度分类
            NULL   AS 存货按工程进度分类_经营资产存成本经营资产面积,
            NULL   AS 存货按工程进度分类_经营资产存成本经营资产金额,
            -- F05603表不存成本业态+无可售面积+已竣备的建筑面积
            sum( case when isnull(IsCost,0) =0 and  isnull(F056ld.待售面积,0)<0 and  isnull(IsBuildGb,0) =1 then isnull(Zjm,0) else 0 end ) AS 存货按工程进度分类_经营资产不存成本经营资产面积,
            -- 冰冻存货
            NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货套数,
            NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货面积,
            NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货金额,
            -- 近3个月无流速存货
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 and  isnull(sb.近三月签约套数,0)<=0 then  F056ld.待售套数 else  0 end  ) AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 and  isnull(sb.近三月签约套数,0)<=0 then  F056ld.待售面积 else  0 end  ) AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 and  isnull(sb.近三月签约套数,0)<=0 then  F056ld.待售货值 else  0 end  ) AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额,
            -- 顶底存货
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then isnull(LHF.[楼层天地层未售住宅套数],0) else  0  end    ) as 已达可售条件未竣备但未售存货的质量分析_顶底存货套数,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then isnull(LHF.[楼层天地层未售住宅面积],0) else  0  end    ) AS 已达可售条件未竣备但未售存货的质量分析_顶底存货面积,
            sum(case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then isnull(LHF.[楼层天地层未售住宅金额],0) /10000.0 else  0  end    ) AS 已达可售条件未竣备但未售存货的质量分析_顶底存货金额,

            -- （按1冰冻存货、2顶底存货、3近三个月物流速存货、4一线判断低质量 的优先顺序判断）
            sum( case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then 
                    case when  isnull(sb.近三月签约套数,0) <=0 then F056ld.待售套数 else  isnull(LHF.[楼层天地层未售住宅套数],0) end  end )  AS 已达可售条件未竣备但未售存货的质量分析_合计存货套数,
            sum( case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then 
                   case when  isnull(sb.近三月签约套数,0)<=0 then F056ld.待售面积 else  isnull(LHF.[楼层天地层未售住宅面积],0) end  end ) AS 已达可售条件未竣备但未售存货的质量分析_合计存货面积,
            sum( case when isnull(IsBuildGb,0) =0  and   isnull(IsBuildYsxx,0) =1 then 
                   case when  isnull(sb.近三月签约套数,0)<=0 then F056ld.待售货值 else  isnull(LHF.[楼层天地层未售住宅金额],0) /10000.0   end  end ) AS 已达可售条件未竣备但未售存货的质量分析_合计存货金额,


            sum(case when IsBuildGb =1  then  F056ld.待售套数 else  0 end   )  AS 已竣备未售存货的质量分析_存货套数,
            sum(case when IsBuildGb =1  then  F056ld.待售面积 else  0 end   )  AS 已竣备未售存货的质量分析_存货面积,
            sum(case when IsBuildGb =1  then  F056ld.待售货值 else  0 end   )  AS 已竣备未售存货的质量分析_存货金额,

            sum(bldkfd.放款金额) as 融资余额_开发贷,
            sum(bldkfd.本年计划还款金额) as 融资余额_开发贷本年计划还款金额,
            sum(bldkfd.贷款合同期限) as 融资期限_贷款合同期限

        -- NULL AS 已竣备未售存货的质量分析_冰冻存货面积,
        -- NULL AS 已竣备未售存货的质量分析_冰冻存货金额,
        -- NULL AS 已竣备未售存货的质量分析_冰冻存货待发生成本,
        FROM #chld chld
        left join  #F06Ld F056ld on F056ld.salebldguid = chld.ProductBldGUID
        left join  #LHFloorBldHz LHF on LHF.BldGUID=chld.ProductBldGUID
        left join #SaleBld sb on sb.BuildingGUID = chld.ProductBldGUID
        left join #BldKfd bldkfd on bldkfd.ProductBldGUID = chld.ProductBldGUID
        left join #M002 m002  on m002.projguid = chld.ProjGUID 
                              and m002.产品类型 = chld.ProductType 
                              and m002.产品名称 = chld.ProductName 
                              and m002.商品类型 = chld.BusinessType 
                              and m002.装修标准 = chld.Standard
        GROUP BY 
            chld.ProjGUID, 
            chld.ProductType, 
            chld.ProductName, 
            chld.BusinessType, 
            chld.Standard
    ) t

  
    -- 步骤3：获取产值月度评审数据
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
        FROM cb_OutputValueReviewProdBld bld with (nolock)
        INNER JOIN (
            SELECT 
                ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY ReviewDate DESC) AS num, -- 取每个项目最新的审核版本
                OutputValueMonthReviewGUID,
                ProjGUID,
                ReviewDate
            FROM [dbo].[cb_OutputValueMonthReview] with (nolock)
            WHERE ApproveState = '已审核'            -- 只取已审核的版本
        ) vr 
            ON vr.OutputValueMonthReviewGUID = bld.OutputValueMonthReviewGUID 
            AND vr.num = 1        
        inner join erp25.dbo.mdm_Project mp with (nolock) on mp.ProjGUID =vr.ProjGUID
        inner join #proj pj on pj.项目GUID = mp.ParentProjGUID

    -- 取楼栋的保理余额
    SELECT 
        bld.ProductBldGUID, 
        SUM(isnull(bld.BlYe, 0)) /10000.0 AS 保理余额
    into #bld_bl
    FROM 
        [TaskCenterData].dbo.cb_StockProjHzCzReview AS CzReview with (nolock)
        INNER JOIN #czld AS czld 
            ON czld.OutputValueMonthReviewGUID = CzReview.OutputValueMonthReviewGUID
        INNER JOIN [TaskCenterData].dbo.cb_StockProdBldReviewHzCzDtl AS bld  with (nolock)
            ON bld.ProductBldGUID = czld.ProdBldGUID 
            AND bld.ReviewGUID = CzReview.ReviewGUID
    GROUP BY 
        bld.ProductBldGUID


    -- 按照项目类型、产品类型、产品名称、商品类型、装修标准汇总
     SELECT 
         czld.ProjGUID,
         czld.ProductType,
         czld.ProductName,
         czld.BusinessType,
         czld.Standard,
         SUM(bld_bl.保理余额) AS 保理余额,
         SUM(Zcz) AS Zcz,                -- 总产值
         SUM(Xmpdljwccz) AS Xmpdljwccz   -- 累计已完成产值
     INTO #cz
     FROM #czld czld
     left join #bld_bl bld_bl on bld_bl.ProductBldGUID = czld.ProdBldGUID
     GROUP BY 
         czld.ProjGUID,
         czld.ProductType,
         czld.ProductName,
         czld.BusinessType,
         czld.Standard


    -- 步骤4：获取立项指标成本数据（按产品类型、产品名称、商品类型、状态标准分组）
    SELECT 
        a.ProjGUID,                              -- 项目GUID
        -- pd.ProductType AS 产品类型,              -- 产品类型
        -- pd.ProductName AS 产品名称,              -- 产品名称
        -- pd.BusinessType AS 商品类型,             -- 商品类型
        -- pd.Standard AS 状态标准,                 -- 状态标准
        SUM(CASE WHEN b.CostShortName IN ('总投资合计') THEN a.CostMoney ELSE 0 END) AS 总投资, -- 总投资金额
        -- MAX(CASE WHEN b.CostShortName IN ('总投资合计') THEN a.BuildAreaCostMoney ELSE 0 END) AS 总投资建筑单方, -- 含税
        
        -- 直投 = 总投资 - 三费(管理费用、营销费用、财务费用)
        ISNULL(SUM(CASE WHEN b.CostShortName = '总投资合计' THEN a.CostMoney ELSE 0 END), 0) 
         - ISNULL(SUM(CASE WHEN b.CostShortName IN ('管理费用','营销费用','财务费用') THEN a.CostMoney ELSE 0 END), 0) AS 直投,
        
        SUM(CASE WHEN b.CostShortName = '土地款' THEN a.CostMoney ELSE 0 END) AS 土地款, -- 土地款金额
        
        -- 除地价外直投 = 除地价外投资合计 - 三费(管理费用、营销费用、财务费用)
        ISNULL(SUM(CASE WHEN b.CostShortName = '除地价外投资合计' THEN a.CostMoney ELSE 0 END), 0) 
         - ISNULL(SUM(CASE WHEN b.CostShortName IN ('管理费用','营销费用','财务费用') THEN a.CostMoney ELSE 0 END), 0) AS 除地价外直投,
        
        -- 三费明细
        SUM(CASE WHEN b.CostShortName IN ('管理费用') THEN a.CostMoney ELSE 0 END) AS 管理费用,
        SUM(CASE WHEN b.CostShortName IN ('营销费用') THEN a.CostMoney ELSE 0 END) AS 营销费用,
        SUM(CASE WHEN b.CostShortName IN ('财务费用') THEN a.CostMoney ELSE 0 END) AS 财务费用
    INTO #lx_cb -- 暂时不需要存入临时表
    FROM erp25.dbo.mdm_ProjProductCostIndex a with (nolock)
    INNER JOIN erp25.dbo.mdm_TechTargetProduct pd with (nolock)
        ON a.ProjGUID = pd.ProjGUID
        AND a.ProductGUID = pd.ProductGUID
    INNER JOIN erp25.dbo.mdm_CostIndex b with (nolock)
        ON a.CostGuid = b.CostGUID
    INNER JOIN #proj pj  ON pj.项目GUID = a.ProjGUID
    GROUP BY 
        a.ProjGUID
        -- pd.ProductType,
        -- pd.ProductName,
        -- pd.BusinessType,
        -- pd.Standard;
    
    -- 步骤5：获取利润指标数据
    SELECT 
        b.ProjGUID,                              -- 项目GUID
        -- b.ProductType AS 产品类型,               -- 产品类型
        -- b.ProductName AS 产品名称,               -- 产品名称
        -- b.BusinessType AS 商品类型,              -- 商品类型
        -- b.Standard AS 状态标准,                  -- 状态标准
        SUM(ISNULL(TotalInvestmentTax, 0)) AS 总投资,       -- 总投资（含税） 
        -- 税前成本利润率 = 税前利润/总投资
        CASE WHEN SUM(ISNULL(TotalInvestmentTax, 0)) = 0 THEN 0 
             ELSE SUM(ISNULL(PreTaxProfit, 0)) / SUM(ISNULL(TotalInvestmentTax, 0)) 
        END AS 税前成本利润率,
        
        SUM(ISNULL(CashInflowTax, 0)) AS 总货值,            -- 总货值（含税现金流入）
        SUM(ISNULL(PreTaxProfit, 0)) AS 税前利润,           -- 税前利润（重复，可考虑删除）
        SUM(ISNULL(AfterTaxProfit, 0)) AS 税后利润,         -- 税后利润（净利润）
        SUM(ISNULL(CashProfit, 0)) AS 税后现金利润,         -- 税后现金利润
        SUM(ISNULL(FixedAssetsOne, 0)) AS 固定资产,         -- 固定资产    
        -- 税费 = 土地增值税 + 流转税附加
        SUM(ISNULL(LandAddedTax, 0)) + SUM(ISNULL(TurnoverTaxPlus, 0)) AS 税费,
        SUM(ISNULL(LandAddedTax, 0)) AS 土地增值税,         -- 土地增值税
        SUM(ISNULL(TurnoverTaxPlus, 0)) AS 流转税附加       -- 流转税附加
    INTO #lx_lr -- 暂时不需要存入临时表
    FROM erp25.dbo.mdm_ProjectIncomeIndex a with (nolock)
    INNER JOIN erp25.dbo.mdm_TechTargetProduct b with (nolock)
        ON a.ProjGUID = b.ProjGUID
        AND a.ProductGUID = b.ProductGUID
    INNER JOIN #proj pj    ON pj.项目GUID = b.ProjGUID
    -- WHERE b.projguid = '1BCF8FE5-46C7-EF11-B3A6-F40270D39969' -- 测试用，可注释
    GROUP BY 
        b.ProjGUID
        -- b.ProductType,
        -- b.ProductName,
        -- b.BusinessType,
        -- b.Standard;

    /*
        本段SQL用于统计各项目及业态的近12个月、近6个月、近3个月的签约金额、签约套数、签约面积
        依据销售明细（Sale）及楼栋信息（pb）进行统计，按产品层级进行分组

        字段说明：
        - ParentProjGUID    ：父项目GUID，用于区分项目
        - TopProductTypeName：顶层产品类型名称，如：住宅、公寓、商铺等
        - ProductTypeName   ：产品类型名称，如：高层、洋房等
        - ZxBz              ：装修标准
        - CommodityType     ：商品类型，如：住宅/商业/公寓等
        - 近十二月签约金额   ：近12个月签约金额（万元）
        - 近十二月签约套数   ：近12个月签约套数
        - 近十二月签约面积   ：近12个月签约面积（平方米）
        - 近三月签约金额     ：近3个月签约金额（万元）
        - 近三月签约套数     ：近3个月签约套数
        - 近三月签约面积     ：近3个月签约面积（平方米）
        - 近六月签约金额     ：近6个月签约金额（万元）
        - 近六月签约套数     ：近6个月签约套数
        - 近六月签约面积     ：近6个月签约面积（平方米）
    */

    SELECT 
        sale.ParentProjGUID,                             -- 父项目GUID
        pb.TopProductTypeName,                           -- 顶层产品类型名称
        pb.ProductTypeName,                              -- 产品类型名称
        pb.ZxBz,                                         -- 装修标准
        pb.CommodityType,                                -- 商品类型

        -- 近12个月签约金额（万元）: 仅统计12个月内的签约金额，非空相加，单位转换为万元
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121) AND GETDATE() 
                    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                ELSE 0
            END
        ) / 10000.0 AS 近十二月签约金额,          -- 万元

        -- 近12个月签约套数
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                ELSE 0
            END
        ) AS 近十二月签约套数,

        -- 近12个月签约面积（平方米）
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                ELSE 0
            END
        ) AS 近十二月签约面积,

        -- 近三月签约金额（万元）
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                ELSE 0
            END
        ) / 10000.0 AS 近三月签约金额,            -- 万元

        -- 近三月签约套数
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                ELSE 0
            END
        ) AS 近三月签约套数,

        -- 近三月签约面积（平方米）
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                ELSE 0
            END
        ) AS 近三月签约面积,

        -- 近六月签约金额（万元）
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                ELSE 0
            END
        ) / 10000.0 AS 近六月签约金额,            -- 万元

        -- 近六月签约套数
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)
                ELSE 0
            END
        ) AS 近六月签约套数,

        -- 近六月签约面积
        SUM(
            CASE 
                WHEN Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -6, GETDATE()), 121) AND GETDATE()
                    THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)
                ELSE 0
            END
        ) AS 近六月签约面积

    INTO #sale  -- 将结果存入临时表#sale
    FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_SalesPerf Sale  with (nolock)            -- 销售合同明细表
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_Building] pb with (nolock) -- 产品楼栋维度表
            ON Sale.BldGUID = pb.BuildingGUID
            AND pb.BldType = '产品楼栋'
    INNER JOIN #proj pj   ON pj.项目GUID = sale.ParentProjGUID
    where Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -12, GETDATE()), 121) AND GETDATE() 
    GROUP BY
        sale.ParentProjGUID,        -- 父项目GUID
        pb.TopProductTypeName,      -- 顶层产品类型名称
        pb.ProductTypeName,         -- 产品类型名称
        pb.ZxBz,                    -- 装修标准
        pb.CommodityType            -- 商品类型

    -- 回笼统计
    SELECT
        hl.projguid,
        pb.TopProductTypeName,   -- 顶层产品类型名称
        pb.ProductTypeName,      -- 产品类型名称
        pb.ZxBz,                 -- 装修标准
        pb.CommodityType,        -- 商品类型
        SUM(ISNULL(hl.回笼金额, 0)) /10000.0 AS 回笼金额
        into #HL
    FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_cpldhl hl with (nolock)
        INNER JOIN [172.16.4.161].highdata_prod.dbo.[data_wide_dws_mdm_Building] pb  with (nolock) -- 产品楼栋维度表
            ON hl.BldGUID = pb.BuildingGUID
            AND pb.BldType = '产品楼栋'
        INNER JOIN #proj pj  ON pj.项目GUID = hl.projguid
    GROUP BY
        hl.projguid,
        pb.TopProductTypeName,   -- 顶层产品类型名称
        pb.ProductTypeName,      -- 产品类型名称
        pb.ZxBz,                 -- 装修标准
        pb.CommodityType         -- 商品类型

    

    -- 查询最终结果
    SELECT
        pj.项目GUID,
        pj.平台公司                AS 公司,
        pj.投管代码,
        pj.项目名                  AS 项目名称,
        pj.存量增量分类,

        -- 立项指标
        lx_lr.总货值               AS 立项指标_货值,
        lx_cb.直投                 AS 立项指标_直投,
        lx_cb.除地价外直投         AS 立项指标_除地价外直投,
        ISNULL(lx_cb.管理费用, 0)
        + ISNULL(lx_cb.营销费用, 0)
        + ISNULL(lx_cb.财务费用, 0) AS 立项指标_费用,
        lx_lr.税费                 AS 立项指标_税金,
        lx_lr.税后利润             AS 立项指标_净利润,
        lx_lr.税前成本利润率       AS 立项指标_税前成本利润率,

        ch.ProductType             AS 业态类型,  -- 产品类型
        ch.ProductName + '-' + ch.Standard + '-' + ch.BusinessType AS 业态, -- 产品名称+装修标准+商品类型

        -- 存货结构-按支付口径
        ch.TotalCost               AS 存货结构_存货余额,
        (
            ISNULL(jacb.JacbSf, 0)
            + ISNULL(jt.Tdk, 0)
            + ISNULL(jt.zbhlxje, 0)
            + ISNULL(jt.kfjjfje, 0)
        ) * ch.TotalCostSumRate     AS 存货结构_实际已付,
        ISNULL(jacb.JacbJt, 0) * ch.TotalCostSumRate AS 存货结构_账面计提,
        isnull(cz.Xmpdljwccz,0)  as 存货结构_已达产值,
        ISNULL(cz.Xmpdljwccz, 0) - ISNULL(ch.TotalCost, 0) AS 存货结构_已达产值但未计提存货,
        ISNULL(cz.Zcz, 0) - ISNULL(ch.TotalCost, 0)
            - (ISNULL(cz.Xmpdljwccz, 0) - ISNULL(ch.TotalCost, 0)) AS 存货结构_项目竣备待发生成本,

        -- 存货按工程进度分类
        NULL                       AS 存货按工程进度分类_已投资未落实金额,-- 战投的填报报表F016_2-往来部分 直接放到已投资未落实的行中展示
        ch.Wkgtdje                 AS 存货按工程进度分类_未开工土地金额,
        isnull(ch.已开工分期_未开工楼栋存货金额,0) 
           +isnull(ch.已开工分期_已开工未达可售条件楼栋存货金额,0) 
           +isnull(ch.已开工分期_已达预售条件未竣备楼栋存货金额,0) 
           +isnull(ch.已开工分期_已竣备存货金额,0) 
           +isnull(ch.已开工分期_已开工分期未售存货计划转经营金额,0)        
           AS 存货按工程进度分类_已开工分期未售存货金额合计,-- 1+2+3+4+5
        isnull(ch.已开工分期_未开工楼栋面积,0) 
           +isnull(ch.已开工分期_已开工未达可售条件楼栋面积,0) 
           +isnull(ch.已开工分期_已达预售条件未竣备楼栋面积,0) 
           +isnull(ch.已开工分期_已竣备面积,0) 
           +isnull(ch.已开工分期_已开工分期未售存货计划转经营面积,0)  
           +isnull(ch.已开工分期_已开工分期未售存货不存成本面积,0)                       
           AS 存货按工程进度分类_已开工分期未售存货面积合计,--1+2+3+4+5+6

        ch.已开工分期_未开工楼栋面积 AS 存货按工程进度分类_已开工分期未售存货未开工楼栋面积,
        ch.已开工分期_未开工楼栋存货金额 AS 存货按工程进度分类_已开工分期未售存货未开工楼栋金额,
        ch.已开工分期_已开工未达可售条件楼栋面积 AS 存货按工程进度分类_已开工分期未售存货已开工未达可售条件面积,
        ch.已开工分期_已开工未达可售条件楼栋存货金额 AS 存货按工程进度分类_已开工分期未售存货已开工未达可售条件金额,
        ch.已开工分期_已达预售条件未竣备楼栋面积 AS 存货按工程进度分类_已开工分期未售存货已达可售条件未竣备面积,
        ch.已开工分期_已达预售条件未竣备楼栋存货金额 AS 存货按工程进度分类_已开工分期未售存货已达可售条件未竣备金额,
        ch.已开工分期_已竣备面积 AS 存货按工程进度分类_已开工分期未售存货已竣备面积,
        ch.已开工分期_已竣备存货金额 AS 存货按工程进度分类_已开工分期未售存货已竣备金额,
        ch.已开工分期_已开工分期未售存货计划转经营面积  AS 存货按工程进度分类_已开工分期未售存货计划转经营面积,-- 计划转经营标签=①赛道图标签为“D类"；②或者是否自持属性为是，③或者产品楼栋的持有面积不为空
        ch.已开工分期_已开工分期未售存货计划转经营金额   AS 存货按工程进度分类_已开工分期未售存货计划转经营金额,-- 计划转经营标签=①赛道图标签为“D类"；②或者是否自持属性为是，③或者产品楼栋的持有面积不为空
        ch.已开工分期_已开工分期未售存货不存成本面积  AS 存货按工程进度分类_已开工分期未售存货不存成本面积,

        F056.已售面积               AS 存货按工程进度分类_已售面积,
        F056.已售货值               AS 存货按工程进度分类_已售金额,

        NULL                       AS 存货按工程进度分类_经营资产存成本经营资产面积, --该业态下资产卡片的面积（风险：跨业态建资产卡片）
        NULL                       AS 存货按工程进度分类_经营资产存成本经营资产金额, --该业态下资产卡片的面积（风险：跨业态建资产卡片）
        ch.存货按工程进度分类_经营资产不存成本经营资产面积 AS 存货按工程进度分类_经营资产不存成本经营资产面积,

        -- 未开工土地存货质量分析
        ch.Wkgtdje                 AS 未开工土地存货质量分析_存货金额,
        DATEDIFF(day, pj.获取时间, GETDATE()) / 365.0 AS 未开工土地存货质量分析_未开工土地账龄, -- 项目获取时间到报表统计时间
        ch.拟退存货面积             AS 未开工土地存货质量分析_拟退存货面积,
        ch.拟退存货金额             AS 未开工土地存货质量分析_拟退存货金额,
        ch.拟换存货面积             AS 未开工土地存货质量分析_拟换存货面积,
        ch.拟换存货金额             AS 未开工土地存货质量分析_拟换存货金额,
        ch.拟调存货面积             AS 未开工土地存货质量分析_拟调存货面积,
        ch.拟调存货金额             AS 未开工土地存货质量分析_拟调存货金额,

        -- 已开工未达可售存货质量分析
        isnull(ch.已开工分期_未开工楼栋存货金额,0) +isnull(ch.已开工分期_已开工未达可售条件楼栋存货金额,0) AS 已开工未达可售存货质量分析_存货金额,-- ①未开工楼栋金额+②已开工未达可售条件金额
        case when ch.实际开工完成日期 is not null then   datediff(day,ch.实际开工完成日期,getdate()) / 365.0 end  AS 已开工未达可售存货质量分析_账龄, -- 现在时间-开工时间
        ISNULL(cz.Zcz, 0) - ISNULL(ch.TotalCost, 0)
            - (ISNULL(cz.Xmpdljwccz, 0) - ISNULL(ch.TotalCost, 0))                        AS 已开工未达可售存货质量分析_竣备待发生成本,
        NULL                       AS 已开工未达可售存货质量分析_冰冻存货面积, -- 增加产品楼栋的标签，历史数据处理
        NULL                       AS 已开工未达可售存货质量分析_冰冻存货金额, --冰冻标签下产品楼栋的金额
        NULL                       AS 已开工未达可售存货质量分析_冰冻存货待发生成本, --冰冻标签下产品楼栋的金额

        -- 已达可售条件未竣备但未售存货的质量分析
        ch.已达可售条件未竣备但未售存货的质量分析_存货套数 AS 已达可售条件未竣备但未售存货的质量分析_存货套数,
        ch.已达可售条件未竣备但未售存货的质量分析_存货面积 AS 已达可售条件未竣备但未售存货的质量分析_存货面积,
        ch.已达可售条件未竣备但未售存货的质量分析_存货金额 AS 已达可售条件未竣备但未售存货的质量分析_存货金额,
        case when  ch.竣工备案完成日期 is null and  ch.实际开工完成日期 is not null then   datediff(day,ch.实际开工完成日期,getdate()) / 365.0 end  AS 已达可售条件未竣备但未售存货的质量分析_账龄, -- 现在时间-开工时间
        NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_冰冻存货金额,

        ch.已达可售条件未竣备但未售存货的质量分析_顶底存货套数 AS 已达可售条件未竣备但未售存货的质量分析_顶底存货套数,
        ch.已达可售条件未竣备但未售存货的质量分析_顶底存货面积 AS 已达可售条件未竣备但未售存货的质量分析_顶底存货面积,
        ch.已达可售条件未竣备但未售存货的质量分析_顶底存货金额 AS 已达可售条件未竣备但未售存货的质量分析_顶底存货金额,

        ch.已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数 AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数,
        ch.已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积 AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积,
        ch.已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额 AS 已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货套数,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货面积,
        NULL AS 已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货金额,

        ch.已达可售条件未竣备但未售存货的质量分析_合计存货套数 AS 已达可售条件未竣备但未售存货的质量分析_合计存货套数,
        ch.已达可售条件未竣备但未售存货的质量分析_合计存货面积 AS 已达可售条件未竣备但未售存货的质量分析_合计存货面积,
        ch.已达可售条件未竣备但未售存货的质量分析_合计存货金额 AS 已达可售条件未竣备但未售存货的质量分析_合计存货金额,

        -- 已竣备未售存货的质量分析
        ch.已竣备未售存货的质量分析_存货套数 AS 已竣备未售存货的质量分析_存货套数,
        ch.已竣备未售存货的质量分析_存货面积 AS 已竣备未售存货的质量分析_存货面积,
        ch.已竣备未售存货的质量分析_存货金额 AS 已竣备未售存货的质量分析_存货金额,
        case when ch.竣工备案完成日期 is not null and  ch.实际开工完成日期 is not null then   datediff(day,ch.实际开工完成日期,getdate()) / 365.0 end  AS 已竣备未售存货的质量分析_账龄,-- 现在时间-开工时间
        case when ch.竣工备案完成日期 is not null then   datediff(day,ch.竣工备案完成日期,getdate()) / 365.0 end  AS 已竣备未售存货的质量分析按竣备起算_账龄,-- 现在时间-竣备时间
        NULL AS 已竣备未售存货的质量分析_冰冻存货面积,
        NULL AS 已竣备未售存货的质量分析_冰冻存货金额,
        NULL AS 已竣备未售存货的质量分析_冰冻存货待发生成本,

        -- 存货近期销售情况
        isnull(sale.近三月签约套数,0)/3.0 AS 存货近期销售情况_近3个月销售流速,
        isnull(sale.近三月签约金额,0)/3.0 AS 存货近期销售情况_近3个月销售签约,
        case when ch.ProductType ='地下室/车库' then  
              case when  isnull(sale.近三月签约套数,0) =0 then  0 else 
                  isnull(sale.近三月签约金额,0) *10000.0 / isnull(sale.近三月签约套数,0) end 
            else  
               case when  isnull(sale.近三月签约面积,0) =0 then  0 else 
                  isnull(sale.近三月签约金额,0) *10000.0 / isnull(sale.近三月签约面积,0) end 
        end   AS 存货近期销售情况_近3个月销售签约均价,
        isnull(sale.近六月签约套数,0)/6.0 AS 存货近期销售情况_近6个月销售流速,
        isnull(sale.近六月签约金额,0)/6.0 AS 存货近期销售情况_近6个月销售签约,
        case when ch.ProductType ='地下室/车库' then  
              case when  isnull(sale.近六月签约套数,0) =0 then  0 else 
                  isnull(sale.近六月签约金额,0) *10000.0 / isnull(sale.近六月签约套数,0) end 
            else  
               case when  isnull(sale.近六月签约面积,0) =0 then  0 else 
                  isnull(sale.近六月签约金额,0) *10000.0 / isnull(sale.近六月签约面积,0) end 
        end  AS 存货近期销售情况_近6个月销售签约均价,
        isnull(sale.近十二月签约套数,0)/12.0 AS 存货近期销售情况_近12个月销售流速,
        isnull(sale.近十二月签约金额,0)/12.0 AS 存货近期销售情况_近12个月销售签约,
        case when ch.ProductType ='地下室/车库' then  
              case when  isnull(sale.近十二月签约套数,0) =0 then  0 else 
                  isnull(sale.近十二月签约金额,0) *10000.0 / isnull(sale.近十二月签约套数,0) end 
            else  
               case when  isnull(sale.近十二月签约面积,0) =0 then  0 else 
                  isnull(sale.近十二月签约金额,0) *10000.0 / isnull(sale.近十二月签约面积,0) end 
        end  AS 存货近期销售情况_近12个月销售签约均价,

        -- 经营资产质量分析
        NULL AS 经营资产质量分析_资产面积,
        NULL AS 经营资产质量分析_净值, -- 
        NULL AS 经营资产质量分析_原值, -- 留存物业中的资产原值
        NULL AS 经营资产质量分析_累计折旧, -- 折旧
        NULL AS 经营资产质量分析_二次改造装修成本, -- 二次改造费用
        NULL AS 经营资产质量分析_NPI回报率, -- 系统无次字段
        NULL AS 经营资产质量分析_EBITDA, --系统无次字段
        NULL AS 经营资产质量分析_净利润, --系统无次字段

        -- 存货现金流风险分析
        isnull(hl.回笼金额,0) AS 存货现金流风险分析_项目经营现金流_已回笼, -- 正常项目的有，但是合作项目、其他业绩无法到业态
        isnull(jt.累计实付直投,0) * ch.TotalCostSumRate AS 存货现金流风险分析_项目经营现金流_已支付直投, 
        isnull(F056.已售货值,0) -isnull(hl.回笼金额,0) AS 存货现金流风险分析_项目经营现金流_已签约待回笼, -- 已签约-已回笼
        isnull(cz.Xmpdljwccz,0) -  isnull(jt.累计实付直投,0) * ch.TotalCostSumRate  AS 存货现金流风险分析_项目经营现金流_已发生产值待支付, -- 产值月度回顾中的已发生产值-已支付直投
        
        isnull(ch.融资余额_开发贷,0) + isnull(cz.保理余额,0) AS 存货现金流风险分析_融资余额_合计, --开发贷+保理+经营贷
        ch.融资余额_开发贷 AS 存货现金流风险分析_融资余额_开发贷,
        cz.保理余额 AS 存货现金流风险分析_融资余额_保理,
        NULL AS 存货现金流风险分析_融资余额_经营贷,

        isnull(ch.融资期限_贷款合同期限,0) * case when isnull(ch.贷款合同期限_合计,0) =0  then  0 else  isnull(ch.融资期限_贷款合同期限,0) /isnull(ch.贷款合同期限_合计,0)  end  
        * case when isnull(ch.融资余额_开发贷_合计,0) =0  then  0 else  isnull(ch.融资余额_开发贷,0) /isnull(ch.融资余额_开发贷_合计,0)  end    AS 存货现金流风险分析_融资期限_合计, -- 按照业态进行加权平均
        isnull(ch.融资期限_贷款合同期限,0) * case when isnull(ch.贷款合同期限_合计,0) =0  then  0 else  isnull(ch.融资期限_贷款合同期限,0) /isnull(ch.贷款合同期限_合计,0)  end  
        * case when isnull(ch.融资余额_开发贷_合计,0) =0  then  0 else  isnull(ch.融资余额_开发贷,0) /isnull(ch.融资余额_开发贷_合计,0)  end  AS 存货现金流风险分析_融资期限_开发贷,
        NULL AS 存货现金流风险分析_融资期限_经营贷,

        isnull(ch.融资余额_开发贷本年计划还款金额,0) + isnull(cz.保理余额,0)  AS 存货现金流风险分析_其中一年内到期融资_合计,
        ch.融资余额_开发贷本年计划还款金额 AS 存货现金流风险分析_其中一年内到期融资_开发贷,
        cz.保理余额 AS 存货现金流风险分析_其中一年内到期融资_保理,
        NULL AS 存货现金流风险分析_其中一年内到期融资_经营贷,

        si.截止目前股东投入余额 AS 存货现金流风险分析_股东投入余额_合计,
        si.截止目前保利方投入余额 AS 存货现金流风险分析_股东投入余额_我方,
        si.截止目前合作方投入余额 AS 存货现金流风险分析_股东投入余额_合作方,

        -- 存货利润分析
        ch.存货利润分析_已售金额      AS 存货利润分析_已售存货_货值,
        ch.存货利润分析_已售存货成本   AS 存货利润分析_已售存货_成本,
        ch.存货利润分析_已售股权溢价    AS 存货利润分析_已售存货_股权溢价,
        ch.存货利润分析_已售费用        AS 存货利润分析_已售存货_费用,
        ch.存货利润分析_已售税金        AS 存货利润分析_已售存货_税金,
        ISNULL(ch.存货利润分析_已售金额不含税, 0)
            - ISNULL(ch.存货利润分析_已售存货成本, 0)
            - ISNULL(ch.存货利润分析_已售股权溢价, 0)
            - ISNULL(ch.存货利润分析_已售费用, 0)
            - ISNULL(ch.存货利润分析_已售税金, 0)
            - CASE
                  WHEN ysp.存货利润分析_已售税前利润 > 0 THEN
                      (ISNULL(ch.存货利润分析_已售金额不含税, 0)
                      - ISNULL(ch.存货利润分析_已售存货成本, 0)
                      - ISNULL(ch.存货利润分析_已售费用, 0)
                      - ISNULL(ch.存货利润分析_已售税金, 0)
                      ) * 0.25
                  ELSE 0.0
              END                        AS 存货利润分析_已售存货_净利润,
        CASE
            WHEN ISNULL(ch.存货利润分析_已售金额不含税,0) <> 0 THEN
                (
                    ISNULL(ch.存货利润分析_已售金额不含税, 0)
                    - ISNULL(ch.存货利润分析_已售存货成本, 0)
                    - ISNULL(ch.存货利润分析_已售股权溢价, 0)
                    - ISNULL(ch.存货利润分析_已售费用, 0)
                    - ISNULL(ch.存货利润分析_已售税金, 0)
                    - CASE
                        WHEN ysp.存货利润分析_已售税前利润 > 0 THEN
                            (
                                ISNULL(ch.存货利润分析_已售金额不含税, 0)
                                - ISNULL(ch.存货利润分析_已售存货成本, 0)
                                - ISNULL(ch.存货利润分析_已售费用, 0)
                                - ISNULL(ch.存货利润分析_已售税金, 0)
                            ) * 0.25
                        ELSE 0.0
                      END
                ) / ISNULL(ch.存货利润分析_已售金额不含税,0)
        END AS 存货利润分析_已售存货_净利率,

        ch.存货利润分析_未售金额           AS 存货利润分析_未售存货_货值,
        ch.存货利润分析_未售存货成本       AS 存货利润分析_未售存货_成本,
        ch.存货利润分析_未售股权溢价       AS 存货利润分析_未售存货_股权溢价,
        ch.存货利润分析_未售费用           AS 存货利润分析_未售存货_费用,
        ch.存货利润分析_未售税金           AS 存货利润分析_未售存货_税金,
        ISNULL(ch.存货利润分析_未售金额不含税, 0)
            - ISNULL(ch.存货利润分析_未售存货成本, 0)
            - ISNULL(ch.存货利润分析_未售股权溢价, 0)
            - ISNULL(ch.存货利润分析_未售费用, 0)
            - ISNULL(ch.存货利润分析_未售税金, 0)
            - CASE
                  WHEN ysp.存货利润分析_未售税前利润 > 0 THEN
                      (
                        ISNULL(ch.存货利润分析_未售金额不含税, 0)
                        - ISNULL(ch.存货利润分析_未售存货成本, 0)
                        - ISNULL(ch.存货利润分析_未售费用, 0)
                        - ISNULL(ch.存货利润分析_未售税金, 0)
                      ) * 0.25
                  ELSE 0.0
              END    AS 存货利润分析_未售存货_净利润,
        CASE
            WHEN ISNULL(存货利润分析_未售金额不含税,0) <> 0 THEN
                (
                    ISNULL(ch.存货利润分析_未售金额不含税, 0)
                    - ISNULL(ch.存货利润分析_未售存货成本, 0)
                    - ISNULL(ch.存货利润分析_未售股权溢价, 0)
                    - ISNULL(ch.存货利润分析_未售费用, 0)
                    - ISNULL(ch.存货利润分析_未售税金, 0)
                    - CASE
                        WHEN ysp.存货利润分析_未售税前利润 > 0 THEN
                            (
                                ISNULL(ch.存货利润分析_未售金额不含税, 0)
                                - ISNULL(ch.存货利润分析_未售存货成本, 0)
                                - ISNULL(ch.存货利润分析_未售费用, 0)
                                - ISNULL(ch.存货利润分析_未售税金, 0)
                            ) * 0.25
                        ELSE 0.0
                      END
                ) / ISNULL(存货利润分析_未售金额不含税,0)
        END AS 存货利润分析_未售存货_净利率
    into #result
    FROM
        #ch ch
        INNER JOIN #proj pj ON pj.项目GUID = ch.ProjGUID
        LEFT JOIN (
            SELECT
                ProjGUID,
                SUM(
                    ISNULL(存货利润分析_已售金额不含税, 0)
                    - ISNULL(存货利润分析_已售存货成本, 0)
                    - ISNULL(存货利润分析_已售费用, 0)
                    - ISNULL(存货利润分析_已售税金, 0)
                ) AS 存货利润分析_已售税前利润,
                SUM(
                    ISNULL(存货利润分析_未售金额不含税, 0)
                    - ISNULL(存货利润分析_未售存货成本, 0)
                    - ISNULL(存货利润分析_未售费用, 0)
                    - ISNULL(存货利润分析_未售税金, 0)
                ) AS 存货利润分析_未售税前利润
            FROM
                #ch
            GROUP BY
                ProjGUID
        ) ysp ON ysp.ProjGUID = ch.ProjGUID
        LEFT JOIN #cz cz
            ON cz.ProjGUID = ch.ProjGUID
            AND cz.ProductType = ch.ProductType
            AND cz.ProductName = ch.ProductName
            AND cz.BusinessType = ch.BusinessType
            AND cz.Standard = ch.Standard
        LEFT JOIN #F056 f056
            ON f056.ProjGUID = ch.ProjGUID
            AND f056.产品类型 = ch.ProductType
            AND f056.产品名称 = ch.ProductName
            AND f056.装修标准 = ch.Standard
            AND f056.商品类型 = ch.BusinessType
        left join #sale sale on sale.ParentProjGUID = ch.ProjGUID 
                             and sale.TopProductTypeName = ch.ProductType 
                             and sale.ProductTypeName = ch.ProductName 
                             and sale.ZxBz = ch.Standard 
                             and sale.CommodityType = ch.BusinessType
        left join #HL hl on hl.projguid = ch.ProjGUID
                         and hl.TopProductTypeName = ch.ProductType
                         and hl.ProductTypeName = ch.ProductName
                         and hl.ZxBz = ch.Standard
                         and hl.CommodityType = ch.BusinessType
        LEFT JOIN #jacb jacb
            ON jacb.ProjGUID = ch.ProjGUID
        LEFT JOIN #jt jt
            ON jt.ProjGUID = ch.ProjGUID
        LEFT JOIN #lx_cb lx_cb
            ON lx_cb.ProjGUID = ch.ProjGUID
        LEFT JOIN #lx_lr lx_lr ON lx_lr.ProjGUID = ch.ProjGUID
        left join #Shareholder_investment si on si.ProjGUID = ch.ProjGUID
    ORDER BY
        pj.平台公司,
        pj.项目名,
        pj.存量增量分类,
        ch.ProductType DESC,
        ch.ProductName + '-' + ch.Standard + '-' + ch.BusinessType;


    -- =========================================================================
    -- 将所有项目补一行“已投资未落实”，插入到最终结果表 #result
    -- 该操作用于保证每个项目都存在一条名为“已投资未落实”的业态类型数据
    -- =========================================================================
    INSERT INTO #result
    SELECT 
        -- 基本项目信息
        r1.[项目GUID],                                        -- 项目唯一标识
        r1.[公司],                                            -- 所属公司
        r1.[投管代码],                                        -- 投管代码
        r1.[项目名称],                                        -- 项目名称
        r1.[存量增量分类],                                    -- 存量/增量分类
        
        -- 立项指标相关字段
        r1.[立项指标_货值],                                   -- 立项货值
        r1.[立项指标_直投],                                   -- 立项直投
        r1.[立项指标_除地价外直投],                           -- 立项除地价外直投
        r1.[立项指标_费用],                                   -- 立项费用
        r1.[立项指标_税金],                                   -- 立项税金
        r1.[立项指标_净利润],                                 -- 立项净利润
        r1.[立项指标_税前成本利润率],                         -- 立项税前成本利润率
        
        -- 固定为“已投资未落实”的业态类型和业态
        '已投资未落实' AS [业态类型],
        '已投资未落实' AS [业态],

        -- 以下所有补充字段除“已投资未落实金额”外均为NULL作占位，便于后续汇总拼接
        NULL AS [存货结构_存货余额],
        NULL AS [存货结构_实际已付],
        NULL AS [存货结构_账面计提],
        0.0 as [存货结构_已达产值],
        NULL AS [存货结构_已达产值但未计提存货],
        NULL AS [存货结构_项目竣备待发生成本],

        -- 仅此一项为实际取值：对应工程进度分类-已投资未落实金额
        ISNULL(f016.已投资未落实金额, 0) AS [存货按工程进度分类_已投资未落实金额],

        -- 其它“存货按工程进度分类”相关字段
        NULL AS [存货按工程进度分类_未开工土地金额],
        NULL AS [存货按工程进度分类_已开工分期未售存货金额合计],
        NULL AS [存货按工程进度分类_已开工分期未售存货面积合计],
        NULL AS [存货按工程进度分类_已开工分期未售存货未开工楼栋面积],
        NULL AS [存货按工程进度分类_已开工分期未售存货未开工楼栋金额],
        NULL AS [存货按工程进度分类_已开工分期未售存货已开工未达可售条件面积],
        NULL AS [存货按工程进度分类_已开工分期未售存货已开工未达可售条件金额],
        NULL AS [存货按工程进度分类_已开工分期未售存货已达可售条件未竣备面积],
        NULL AS [存货按工程进度分类_已开工分期未售存货已达可售条件未竣备金额],
        NULL AS [存货按工程进度分类_已开工分期未售存货已竣备面积],
        NULL AS [存货按工程进度分类_已开工分期未售存货已竣备金额],
        NULL AS [存货按工程进度分类_已开工分期未售存货计划转经营面积],
        NULL AS [存货按工程进度分类_已开工分期未售存货计划转经营金额],
        NULL AS [存货按工程进度分类_已开工分期未售存货不存成本面积],
        NULL AS [存货按工程进度分类_已售面积],
        NULL AS [存货按工程进度分类_已售金额],
        NULL AS [存货按工程进度分类_经营资产存成本经营资产面积],
        NULL AS [存货按工程进度分类_经营资产存成本经营资产金额],
        NULL AS [存货按工程进度分类_经营资产不存成本经营资产面积],

        -- 未开工土地存货质量分析相关字段
        NULL AS [未开工土地存货质量分析_存货金额],
        NULL AS [未开工土地存货质量分析_未开工土地账龄],
        NULL AS [未开工土地存货质量分析_拟退存货面积],
        NULL AS [未开工土地存货质量分析_拟退存货金额],
        NULL AS [未开工土地存货质量分析_拟换存货面积],
        NULL AS [未开工土地存货质量分析_拟换存货金额],
        NULL AS [未开工土地存货质量分析_拟调存货面积],
        NULL AS [未开工土地存货质量分析_拟调存货金额],

        -- 已开工未达可售存货质量分析相关字段
        NULL AS [已开工未达可售存货质量分析_存货金额],
        NULL AS [已开工未达可售存货质量分析_账龄],
        NULL AS [已开工未达可售存货质量分析_竣备待发生成本],
        NULL AS [已开工未达可售存货质量分析_冰冻存货面积],
        NULL AS [已开工未达可售存货质量分析_冰冻存货金额],
        NULL AS [已开工未达可售存货质量分析_冰冻存货待发生成本],

        -- 已达可售条件未竣备但未售存货的质量分析相关字段
        NULL AS [已达可售条件未竣备但未售存货的质量分析_存货套数],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_存货面积],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_存货金额],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_账龄],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_冰冻存货套数],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_冰冻存货面积],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_冰冻存货金额],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_顶底存货套数],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_顶底存货面积],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_顶底存货金额],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货套数],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货面积],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_近3个月无流速存货金额],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货套数],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货面积],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_一线判断低质量存货金额],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_合计存货套数],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_合计存货面积],
        NULL AS [已达可售条件未竣备但未售存货的质量分析_合计存货金额],

        -- 已竣备未售存货的质量分析相关字段
        NULL AS [已竣备未售存货的质量分析_存货套数],
        NULL AS [已竣备未售存货的质量分析_存货面积],
        NULL AS [已竣备未售存货的质量分析_存货金额],
        NULL AS [已竣备未售存货的质量分析_账龄],
        NULL as [已竣备未售存货的质量分析按竣备起算_账龄],
        NULL AS [已竣备未售存货的质量分析_冰冻存货面积],
        NULL AS [已竣备未售存货的质量分析_冰冻存货金额],
        NULL AS [已竣备未售存货的质量分析_冰冻存货待发生成本],

        -- 存货近期销售情况相关字段
        NULL AS [存货近期销售情况_近3个月销售流速],
        NULL AS [存货近期销售情况_近3个月销售签约],
        NULL AS [存货近期销售情况_近3个月销售签约均价],
        NULL AS [存货近期销售情况_近6个月销售流速],
        NULL AS [存货近期销售情况_近6个月销售签约],
        NULL AS [存货近期销售情况_近6个月销售签约均价],
        NULL AS [存货近期销售情况_近12个月销售流速],
        NULL AS [存货近期销售情况_近12个月销售签约],
        NULL AS [存货近期销售情况_近12个月销售签约均价],

        -- 经营资产质量分析相关字段
        NULL AS [经营资产质量分析_资产面积],
        NULL AS [经营资产质量分析_净值],
        NULL AS [经营资产质量分析_原值],
        NULL AS [经营资产质量分析_累计折旧],
        NULL AS [经营资产质量分析_二次改造装修成本],
        NULL AS [经营资产质量分析_NPI回报率],
        NULL AS [经营资产质量分析_EBITDA],
        NULL AS [经营资产质量分析_净利润],

        -- 存货现金流风险分析相关字段
        0.0  AS [存货现金流风险分析_项目经营现金流_已回笼],
        NULL AS [存货现金流风险分析_项目经营现金流_已支付直投],
        NULL AS [存货现金流风险分析_项目经营现金流_已签约待回笼],
        NULL AS [存货现金流风险分析_项目经营现金流_已发生产值待支付],
        NULL AS [存货现金流风险分析_融资余额_合计],
        NULL AS [存货现金流风险分析_融资余额_开发贷],
        NULL AS [存货现金流风险分析_融资余额_保理],
        NULL AS [存货现金流风险分析_融资余额_经营贷],
        NULL AS [存货现金流风险分析_融资期限_合计],
        NULL AS [存货现金流风险分析_融资期限_开发贷],
        NULL AS [存货现金流风险分析_融资期限_经营贷],
        NULL AS [存货现金流风险分析_其中一年内到期融资_合计],
        NULL AS [存货现金流风险分析_其中一年内到期融资_开发贷],
        NULL AS [存货现金流风险分析_其中一年内到期融资_保理],
        NULL AS [存货现金流风险分析_其中一年内到期融资_经营贷],
        NULL AS [存货现金流风险分析_股东投入余额_合计],
        NULL AS [存货现金流风险分析_股东投入余额_我方],
        NULL AS [存货现金流风险分析_股东投入余额_合作方],

        -- 存货利润分析相关字段
        NULL AS [存货利润分析_已售存货_货值],
        NULL AS [存货利润分析_已售存货_成本],
        NULL AS [存货利润分析_已售存货_股权溢价],
        NULL AS [存货利润分析_已售存货_费用],
        NULL AS [存货利润分析_已售存货_税金],
        NULL AS [存货利润分析_已售存货_净利润],
        NULL AS [存货利润分析_已售存货_净利率],
        NULL AS [存货利润分析_未售存货_货值],
        NULL AS [存货利润分析_未售存货_成本],
        NULL AS [存货利润分析_未售存货_股权溢价],
        NULL AS [存货利润分析_未售存货_费用],
        NULL AS [存货利润分析_未售存货_税金],
        NULL AS [存货利润分析_未售存货_净利润],
        NULL AS [存货利润分析_未售存货_净利率]

    FROM (
        -- 只取一次每个项目（去重），避免出现在#result已有多行造成重复插入
        SELECT DISTINCT
            [项目GUID],
            [公司],
            [投管代码],
            [项目名称],
            [存量增量分类],
            [立项指标_货值],
            [立项指标_直投],
            [立项指标_除地价外直投],
            [立项指标_费用],
            [立项指标_税金],
            [立项指标_净利润],
            [立项指标_税前成本利润率]
        FROM #result
    ) r1
    -- 用项目GUID连接临时表#F016获取“已投资未落实金额”
    LEFT JOIN #F016 f016 ON f016.项目GUID = r1.[项目GUID]

    -- 查询最终结果
    select * from #result


    -- 删除临时表
    DROP TABLE #proj, #ch, #chld, #cz, #czld, #lx_cb, #lx_lr, #sale,#SaleBld, #F056,#jt,#jacb,#F016,#result,#Shareholder_investment,#HL

END
