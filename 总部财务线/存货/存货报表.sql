USE [MyCost_Erp352]
GO

/*
  存货分析报表
  测试项目：
  线上分摊：广州市天河区员村二横路以西720、721地块-一期 --F0BC641F-B8C8-EF11-B3A6-F40270D39969  
  广州市天河区员村二横路以西720、721地块 项目GUID 1BCF8FE5-46C7-EF11-B3A6-F40270D39969
  线下分摊：广州大塱村项目-二期 --A9CB63B1-A930-E711-80BA-E61F13C57837  
   EXEC usp_cb_存货分析报表 'AADC0FA7-9546-49C9-B64B-825056C828ED' -- 华南公司
 EXEC usp_cb_存货分析报表 '275B7A4E-4AB3-408E-A43A-1BA6AC5B0321'
*/

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
 
     print  '步骤1：获取项目基本信息' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


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

     print  '取一级项目的已投资未落实字段' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


    -- 步骤2：获取存货楼栋排查最新数
   SELECT  
       *,
       CASE 
           WHEN SUM(IsBuildKg) OVER(PARTITION BY fqProjGUID) <> 0 
                AND COUNT(IsBuildKg) OVER(PARTITION BY fqProjGUID) = SUM(IsBuildKg) OVER(PARTITION BY fqProjGUID)
           THEN 1 
           ELSE 0 
       END AS isAllBuildKg,
       case when  SUM(IsBuildKg) OVER(PARTITION BY ProjGUID) =0 then 1 else  0  end  as isAllBuildNotKg -- 所有楼栋都没有开工
   INTO #chld
   FROM (
       SELECT distinct
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
           sfp.Zjm,                                              -- 建筑面积
            -- 若为线上分摊，取二次分摊处的结转总金额；
            -- 若为线下导入，取合作项目导入处的累计已结转开发产品金额
           case when DateSource = '线下分摊' then sfp.Totaldevmj else  sfp.jz_mjgs end  as jz_mjgs,                                          -- 已结转面积套数
           case when DateSource = '线下分摊' then sfp.Totaldevje else  sfp.jz_TotalCost end as jz_TotalCost,                                      -- 已结转总成本 
           sfp.Wkgtdje,                                           -- 存货结果输出-未开工土地金额，需要增加判断逻辑，如果当前分期下的所有楼栋都没有开工，采取存货拍照表上的未开工分期的土地款金额
           sfip.jacbjt,                                            -- 建安成本计提
           sfip.JacbSf,                                            -- 建安成本实付
           case when DateSource ='线下分摊' then  sfp.Totaldevmj else  0 end Totaldevmj, -- 累计已结转开发产品面积
           case when DateSource ='线下分摊' then  sfp.Totaldevje else  0 end Totaldevje, -- 累计已结转开发产品金额
           case when DateSource ='线下分摊' then  sfp.Totalmainmj else  0 end Totalmainmj, -- 累计已结转主营业务成本面积
           case when DateSource ='线下分摊' then  sfp.Totalmainje else  0 end Totalmainje -- 累计已结转主营业务成本金额
       FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtCostPhoto sfp with (nolock)
       INNER JOIN erp25.dbo.mdm_SaleBuild sb  with (nolock) ON sfp.ProductBldGUID = sb.SaleBldGUID
       INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = sfp.ProjGUID
       LEFT JOIN erp25.dbo.mdm_Product pt with (nolock) ON pt.ProductGUID = sb.ProductGUID
       INNER JOIN (
                    -- ProjGUID存在多个数据用;拼接的情况，需要拆分
                    SELECT  
                        ROW_NUMBER() OVER (
                            PARTITION BY ProjGUID ORDER BY photodate DESC
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
                ) vr 
           ON vr.VersionGUID = sfp.VersionGUID 
           AND sfp.ProjGUID = vr.ProjGUID 
           AND vr.num = 1                                     -- 只取最新版本
     left join [172.16.4.131].[TaskCenterData].dbo.cb_StockFtCostImportPhoto sfip with (nolock) on 
                                                                   sfip.projguid =sfp.projguid and
                                                                   sfip.VersionGUID =vr.VersionGUID
                                                                   and sfip.ProductBldGUID =sfp.ProductBldGUID
     inner join #proj pj on pj.项目GUID = mp.ParentProjGUID
   ) t

   print '步骤2：获取存货楼栋排查最新数' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

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
   FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockJt jt with (nolock)
   INNER JOIN erp25.dbo.mdm_Project mp with (nolock) ON mp.ProjGUID = jt.ProjGUID
   left  join (
      SELECT 
          StockJtGUID,
          SUM(CASE WHEN CostName = '土地款' THEN LjSfJeCur ELSE 0 END) AS 累计实付土地款,
          SUM(CASE WHEN CostName = '建安成本' THEN LjSfJeCurNotTax ELSE 0 END) AS 累计实付建安成本,
          sum(case when  costname in ('土地款','建安成本') then LjSfJeCur else 0 end)累计实付直投
      FROM [172.16.4.131].TaskCenterData.dbo.cb_StockJtDtl jtdtl with (nolock)
      GROUP BY StockJtGUID
   ) jtdtl on jt.StockJtGUID = jtdtl.StockJtGUID
   INNER JOIN [172.16.4.131].[TaskCenterData].dbo.cb_StockFtProjVersionZbPhoto zb   ON jt.StockJtGUID = zb.StockJtGUID
   INNER JOIN (
    --    SELECT  
    --        ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY PhotoDate DESC) AS num, -- 取每个项目最新的审核版本
    --        VersionGUID,
    --        ProjGUID,
    --        ProjName,
    --        PhotoDate
    --    FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtProjVersionPhoto  with (nolock)
    --    WHERE ApproveState = '已审核' and  DateSource ='线上分摊'            -- 只取已审核的版本
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
                    WHERE ApproveState = '已审核'  and  DateSource ='线上分摊'  -- 只取已审核的版本
                ) t
   ) vr 
       ON zb.VersionGUID = vr.VersionGUID 
       AND jt.ProjGUID = vr.ProjGUID 
       AND vr.num = 1
    inner join #proj pj on pj.项目GUID = mp.ParentProjGUID
    group by  mp.ParentProjGUID

   print '已审核的拍照版本找到引入成本的计提土地款、资本化利息、开发间接费金额' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

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
    --    SELECT
    --        ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY PhotoDate DESC) AS num, -- 取每个项目最新的审核版本
    --        VersionGUID,
    --        ProjGUID,
    --        ProjName,
    --        PhotoDate
    --    FROM [172.16.4.131].[TaskCenterData].dbo.cb_StockFtProjVersionPhoto with (nolock)
    --    WHERE ApproveState = '已审核' and  DateSource ='线上分摊'  -- 只取已审核的版本
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
                    WHERE ApproveState = '已审核'  and  DateSource ='线上分摊'  -- 只取已审核的版本
                ) t
   ) vr
       ON ftCostimp.VersionGUID = vr.VersionGUID
       AND ftCostimp.ProjGUID = vr.ProjGUID
       AND vr.num = 1
   inner join #proj pj on pj.项目GUID = mp.ParentProjGUID
   group by mp.ParentProjGUID


   print '存货分摊项目分期拍照表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

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
    INNER JOIN #proj pj  ON pj.项目GUID = mp.ParentProjGUID

   print '取F056项目 拍照版本的' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
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
    FROM #F06Ld with (nolock)
    GROUP BY 
        ProjGUID,
        产品类型,
        产品名称,
        装修标准,
        商品类型

   print '将F056汇总到项目、产品类型、产品名称、装修标准、商品类型层级' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
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

      print '取M002汇总表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

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

   print '统计天地楼层的楼栋' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
 
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
        INNER JOIN #proj pj
            ON pj.项目GUID = Sale.ParentProjGUID
    where  Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(10), DATEADD(MONTH, -3, GETDATE()), 121) AND GETDATE()
    GROUP BY 
        Sale.ParentProjGUID, 
        Sale.BldGUID  -- 父项目GUID

  print '按楼栋统计近三个月销售情况' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
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

   print '股东投入余额' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

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

   -- 获取楼栋的结转开发产品和开发成本
        -- 结转主营业务成本
            SELECT 
                *  INTO #CarryOverMbb
            FROM (
                SELECT 
                    a.projguid,
                    d.BldGUID,
                    ROW_NUMBER() OVER (
                        PARTITION BY a.projguid, d.BldGUID 
                        ORDER BY a.ApproveDate DESC
                    ) AS RowNum,
                    a.CarryOverMainGUID 
                FROM 
                    [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain a WITH(NOLOCK)
                LEFT JOIN 
                    [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d WITH(NOLOCK) 
                    ON d.Subject = 4 
                    AND d.CarryOverMainGUID = a.CarryOverMainGUID
                WHERE a.ApproverState = '已审核'
            ) t 
            WHERE  t.RowNum = 1;
        
        -- 有已结转成本拍照版本的记录从拍照版本中取
        SELECT
            mp.ParentProjGUID AS Projguid,
            gc.ProjGUID AS fqProjGUID,
            ld.SaleBldGUID AS bldguid,
            SUM(ISNULL(d.TotalArea, 0)) AS 已结转主营业务成本面积,
            -- SUM(ISNULL(d.TotalMoney, 0)),
            -- SUM(ISNULL(b.TotalMoney, 0)),
            SUM(
                CASE
                    WHEN e.CarryOverMainGUID IS NOT NULL THEN ISNULL(d.TotalMoney, 0)
                    ELSE ISNULL(b.TotalMoney, 0)
                END
            ) / 10000.0 AS 已结转主营业务成本金额
        INTO #jzMaincb
        FROM erp25.dbo.mdm_SaleBuild ld WITH (NOLOCK)
            INNER JOIN erp25.dbo.mdm_GCBuild gc WITH (NOLOCK)
                ON gc.GCBldGUID = ld.GCBldGUID
            INNER JOIN erp25.dbo.mdm_project mp
                ON mp.projguid = gc.projguid
            LEFT JOIN #CarryOverMbb bb WITH (NOLOCK)
                ON bb.projguid = gc.projguid
                AND bb.BldGUID = ld.SaleBldGUID
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSetBldDtl b WITH (NOLOCK)
                ON ld.SaleBldGUID = b.BldGUID
                AND b.Subject = 4
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSet c WITH (NOLOCK)
                ON b.CarryOverMainSetGUID = c.CarryOverMainSetGUID
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d WITH (NOLOCK)
                ON ld.SaleBldGUID = d.BldGUID
                AND d.Subject = 4
                AND d.CarryOverMainGUID = bb.CarryOverMainGUID
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain e WITH (NOLOCK)
                ON d.CarryOverMainGUID = e.CarryOverMainGUID
        -- WHERE gc.ProjGUID = '116A20D9-2A43-E811-80BA-E61F13C57837'
        GROUP BY
            mp.ParentProjGUID,
            gc.ProjGUID,
            ld.SaleBldGUID



          -- 结转产品成本
            SELECT 
                *  INTO #CarryOverDevelop
            FROM (
                SELECT 
                    a.projguid,
                    d.BldGUID,
                    ROW_NUMBER() OVER (
                        PARTITION BY a.projguid, d.BldGUID 
                        ORDER BY a.ApproveDate DESC
                    ) AS RowNum,
                    a.CarryOverDevelopGUID 
                FROM 
                    [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelop a WITH(NOLOCK)
                LEFT JOIN 
                    [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelopBldDtl d WITH(NOLOCK) 
                    ON d.Subject = 4 
                    AND d.CarryOverDevelopGUID = a.CarryOverDevelopGUID
                WHERE a.ApproverState = '已审核'
            ) t 
            WHERE  t.RowNum = 1;

        -- 有已结转成本拍照版本的记录从拍照版本中取
        SELECT
            mp.ParentProjGUID AS Projguid,
            gc.ProjGUID AS fqProjGUID,
            ld.SaleBldGUID AS bldguid,
            SUM(ISNULL(d.TotalArea, 0)) AS 已结转开发产品成本面积,
            -- SUM(ISNULL(d.TotalMoney, 0)),
            -- SUM(ISNULL(b.TotalMoney, 0)),
            SUM(
                CASE
                    WHEN e.CarryOverDevelopGUID IS NOT NULL THEN ISNULL(d.TotalMoney, 0)
                    ELSE ISNULL(b.TotalMoney, 0)
                END
            ) / 10000.0 AS 已结转开发产品成本金额
        INTO #jzDevelopcb
        FROM erp25.dbo.mdm_SaleBuild ld WITH (NOLOCK)
            INNER JOIN erp25.dbo.mdm_GCBuild gc WITH (NOLOCK) ON gc.GCBldGUID = ld.GCBldGUID
            INNER JOIN erp25.dbo.mdm_project mp ON mp.projguid = gc.projguid
            LEFT JOIN #CarryOverDevelop bb WITH (NOLOCK) ON bb.projguid = gc.projguid AND bb.BldGUID = ld.SaleBldGUID
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelopSetBldDtl b WITH (NOLOCK) ON ld.SaleBldGUID = b.BldGUID AND b.Subject = 4
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelopSet c WITH (NOLOCK) ON b.[CarryOverDevelopSetGUID] = c.[CarryOverDevelopSetGUID]
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelopBldDtl d WITH (NOLOCK)
                ON ld.SaleBldGUID = d.BldGUID
                AND d.Subject = 4
                AND d.CarryOverDevelopGUID = bb.CarryOverDevelopGUID
            LEFT JOIN [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelop e WITH (NOLOCK) ON d.CarryOverDevelopGUID = e.CarryOverDevelopGUID
        -- WHERE gc.ProjGUID = '116A20D9-2A43-E811-80BA-E61F13C57837'
        GROUP BY
            mp.ParentProjGUID,
            gc.ProjGUID,
            ld.SaleBldGUID

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
            bld.Xmpdljwccz /10000.0 as Xmpdljwccz                          -- 项目累计已完成产值
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

    print '步骤3：获取产值月度评审数据' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- 汇总存货信息
    SELECT  
        ProjGUID,
        ProductType,
        ProductName,
        BusinessType,
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
        结转开发产品面积,
        结转开发产品金额,
        结转主营业务成本面积,
        结转主营业务成本金额,

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
        
        已达可售条件未竣备但未售存货的质量分析_顶底存货套数,
        已达可售条件未竣备但未售存货的质量分析_顶底存货面积,
        已达可售条件未竣备但未售存货的质量分析_顶底存货金额,

        已达可售条件未竣备但未售存货的质量分析_合计存货套数,
        已达可售条件未竣备但未售存货的质量分析_合计存货面积,
        已达可售条件未竣备但未售存货的质量分析_合计存货金额,

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
            sum(case when  DateSource ='线上分摊' then isnull(jzDevelopcb.已结转开发产品成本面积,0) else  chld.Totaldevmj end ) as    结转开发产品面积,
            sum(case when  DateSource ='线上分摊' then isnull(jzDevelopcb.已结转开发产品成本金额,0) else chld.Totaldevje /10000.0 end ) as    结转开发产品金额,
            sum(case when  DateSource ='线上分摊' then isnull(jzMaincb.已结转主营业务成本面积,0) else chld.Totalmainmj  end  ) as    结转主营业务成本面积,
            sum(case when  DateSource ='线上分摊' then isnull(jzMaincb.已结转主营业务成本金额,0) else chld.Totalmainje /10000.0 end ) as    结转主营业务成本金额,

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
        
            -- sum(case  when  isAllBuildKg = 1 and  IsBuildKg =1 and IsBuildGb =1 and ( F056ld.是否可售 ='否' and F056ld.是否持有 ='否' ) 
            --     then isnull(F056ld.总建面,0) -isnull(F056ld.总可售面积,0) else 0 end ) as 已开工分期_已开工分期未售存货不存成本面积,
            -- sum(case  when  isAllBuildKg = 1 and  IsBuildKg =1 and IsBuildGb =1 and ( F056ld.是否可售 ='否' and F056ld.是否持有 ='否' ) 
            --     and ( F056ld.赛道图标签 not  in ('D1-已开业未融资','D2-已开业已融资','D3-未开业') ) 
            --     then isnull(F056ld.总建面,0) -isnull(F056ld.总可售面积,0) else 0 end ) as 已开工分期_已开工分期未售存货不存成本未经营面积,
        
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
            sum(case when IsBuildGb =1  then  isnull(F056ld.待售面积,0) else  0 end   )  AS 已竣备未售存货的质量分析_存货面积,
            sum(case when IsBuildGb =1  then  isnull(F056ld.待售货值,0) else  0 end   )  AS 已竣备未售存货的质量分析_存货金额,

            sum(bldkfd.放款金额) as 融资余额_开发贷,
            sum(bldkfd.本年计划还款金额) as 融资余额_开发贷本年计划还款金额,
            sum(bldkfd.贷款合同期限) as 融资期限_贷款合同期限,

            sum(chld.jacbjt ) /10000.0 as 建安成本计提,                                            -- 建安成本计提
            sum(chld.JacbSf ) /10000.0 as 建安成本实付                                             -- 建安成本实付
        -- NULL AS 已竣备未售存货的质量分析_冰冻存货面积,
        -- NULL AS 已竣备未售存货的质量分析_冰冻存货金额,
        -- NULL AS 已竣备未售存货的质量分析_冰冻存货待发生成本,
             
        FROM #chld chld with (nolock) 
        left join  #czld czld  on czld.ProdBldGUID = chld.ProductBldGUID
        left join  #F06Ld F056ld with (nolock) on F056ld.salebldguid = chld.ProductBldGUID
        left join  #jzDevelopcb jzDevelopcb on jzDevelopcb.bldguid = chld.ProductBldGUID
        left join  #jzMaincb jzMaincb on jzMaincb.bldguid = chld.ProductBldGUID
        left join  #LHFloorBldHz LHF with (nolock) on LHF.BldGUID=chld.ProductBldGUID
        left join #SaleBld sb with (nolock) on sb.BuildingGUID = chld.ProductBldGUID
        left join #BldKfd bldkfd with (nolock) on bldkfd.ProductBldGUID = chld.ProductBldGUID
        left join #M002 m002 with (nolock)  on m002.projguid = chld.ProjGUID 
                              and m002.产品类型 = chld.ProductType 
                              and m002.产品名称 = chld.ProductName 
                              and m002.商品类型 = chld.BusinessType 
                              and m002.装修标准 = chld.Standard
        INNER JOIN #proj pj ON pj.项目GUID = chld.ProjGUID 
        GROUP BY 
            chld.ProjGUID, 
            chld.ProductType, 
            chld.ProductName, 
            chld.BusinessType, 
            chld.Standard
    ) t

    print '汇总存货信息' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
  
   

    -- 取楼栋的保理余额
    SELECT 
        bld.ProductBldGUID, 
        SUM(isnull(bld.BlYe, 0)) /10000.0 AS 保理余额
    into #bld_bl
    FROM 
        [172.16.4.131].[TaskCenterData].dbo.cb_StockProjHzCzReview AS CzReview with (nolock)
        INNER JOIN #czld AS czld 
            ON czld.OutputValueMonthReviewGUID = CzReview.OutputValueMonthReviewGUID
        INNER JOIN [172.16.4.131].[TaskCenterData].dbo.cb_StockProdBldReviewHzCzDtl AS bld  with (nolock)
            ON bld.ProductBldGUID = czld.ProdBldGUID 
            AND bld.ReviewGUID = CzReview.ReviewGUID
    GROUP BY 
        bld.ProductBldGUID
    print '取楼栋的保理余额' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

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

    print '按照项目类型、产品类型、产品名称、商品类型、装修标准汇总' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

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
    where  b.CostShortName in ('总投资合计','管理费用','营销费用','财务费用','除地价外投资合计','土地款')
    GROUP BY 
        a.ProjGUID
        -- pd.ProductType,
        -- pd.ProductName,
        -- pd.BusinessType,
        -- pd.Standard;
     print '步骤4：获取立项指标成本数据（按产品类型、产品名称、商品类型、状态标准分组）' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


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
    INNER JOIN #proj pj  ON pj.项目GUID = b.ProjGUID
    -- WHERE b.projguid = '1BCF8FE5-46C7-EF11-B3A6-F40270D39969' -- 测试用，可注释
    GROUP BY 
        b.ProjGUID
        -- b.ProductType,
        -- b.ProductName,
        -- b.BusinessType,
        -- b.Standard;

     print '步骤5：获取利润指标数据' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
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

     print '用于统计各项目及业态的近12个月、近6个月、近3个月的签约金额、签约套数、签约面积' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
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
     print '回笼统计' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
    ------------------------------------------------------------------------------------------
    -- 查询账面监管资金和账面资金余额（最新一日，余额大于0的数据），并关联到项目
    ------------------------------------------------------------------------------------------
    -- 1. 获取明细表最大业务日期（保证取最新的数据）
    SELECT 
        MIN(business_date) AS business_date
    INTO #d_date
    FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_fund_detail WITH (NOLOCK)
    WHERE 
        balance > 0
        AND datediff(day, business_date ,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) ) =0 -- 取本月初
        --AND business_date < CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 112)); -- 取今天之前
    

    -- 2. 提取项目公司资金明细，关联到项目GUID
    SELECT 
        t.cltProjectCode,                                -- 项目公司代码
        t.cltProjectName,                                -- 项目公司名称
        t.project_company,                               -- 公司名称
        -- t.TgProjCode          AS my_tgprojcode,       -- 投管项目编码
        pj.ProjGUID,                                     -- 匹配到的项目GUID
        t.account_nature,                                -- 账户性质（如监管户）
        t.capital_nature,                                -- 资金性质
        t.balance                                       -- 账户余额
    INTO #dw_proj_com
    FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_fund_detail t WITH (NOLOCK)
        INNER JOIN #d_date dd ON t.business_date = dd.business_date      -- 匹配最新业务日期
        LEFT JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj WITH (NOLOCK)
            ON (pj.TgProjCode = t.cltProjectCode OR cltProjectName = projname)   -- 项目投管编码或名称匹配
            AND pj.level = 2                                           -- 只取项目级别为 2
      INNER JOIN #proj p  ON p.项目GUID = pj.projguid
    WHERE 1 = 1;   -- 便于后续扩展条件

    -- 3. 生成项目公司与项目映射关系临时表
    SELECT 
        project_company,
        ProjGUID
    INTO #com_proj
    FROM #dw_proj_com with (nolock)
    GROUP BY project_company, ProjGUID;

    -- 4. 统计每个项目公司对应的项目数，供后面分配使用
    SELECT
        project_company,
        COUNT(DISTINCT ProjGUID) AS proj_num
    INTO #proj_num
    FROM #com_proj with (nolock)
    WHERE ProjGUID IS NOT NULL
    GROUP BY project_company;

    -- 5. 汇总每个项目公司按账户、资金性质的总余额，作为待分配的项目公司总资金
    SELECT
        project_company,
        account_nature,
        capital_nature,
        SUM(balance) AS 项目公司资金
    INTO #zj
    FROM #dw_proj_com with (nolock)
    GROUP BY project_company, account_nature, capital_nature;

    -- 6. 如果项目公司只对应一个项目，则全部资金都归到该项目下
    SELECT 
        cp.ProjGUID,                                                 -- 项目GUID
        sum(t.项目公司资金) /10000.0 AS 期初账面资金余额,                            -- 账面资金余额（全部余额）
        sum(CASE 
            WHEN account_nature = '监控房款户' 
                THEN t.项目公司资金 
            ELSE 0 
        END)  /10000.0 AS 期初监管资金余额                                        -- 监管户余额（只统计监管户）
    INTO #zmzj
    FROM #zj t with (nolock)
        INNER JOIN #proj_num proj with (nolock) ON t.project_company = proj.project_company
        INNER JOIN #com_proj cp  with (nolock) ON t.project_company = cp.project_company
    WHERE proj.proj_num = 1                                         -- 只分配给唯一项目
    group by cp.ProjGUID

    -- 7. 如果一个项目公司对应多个项目（大于1），则将资金均分到每个关联项目
    INSERT INTO #zmzj
    SELECT 
        cp.ProjGUID,                                                      -- 项目GUID
        sum(CASE 
            WHEN proj.proj_num = 0 THEN 0 
            ELSE t.项目公司资金 / proj.proj_num 
        END ) / 10000.0  AS 期初账面资金余额,                                           -- 账面资金余额均分 万元
        sum(CASE 
            WHEN account_nature = '监控房款户'  THEN 
            CASE 
                WHEN proj.proj_num = 0 THEN 0 
                ELSE t.项目公司资金 / proj.proj_num 
            END else  0
        END ) / 10000.0 AS 期初监管资金余额                                            -- 监管户余额均分 万元
    FROM #zj t with (nolock)
        INNER JOIN #proj_num proj with (nolock) ON t.project_company = proj.project_company
        INNER JOIN #com_proj cp with (nolock)   ON t.project_company = cp.project_company
    WHERE proj.proj_num > 1                                           -- 多项目归属的资金均分
    group by  cp.ProjGUID

    -- 合并数据保证数据不重复
    SELECT 
        ProjGUID, 
        SUM(ISNULL(期初账面资金余额, 0)) AS 期初账面资金余额,
        SUM(ISNULL(期初监管资金余额, 0)) AS 期初监管资金余额
    INTO #zmzjSum
    FROM #zmzj
    GROUP BY ProjGUID;
    print '查询账面监管资金和账面资金余额' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
    ------------------------------------------------------------------------------------------
    -- 账面资金取数处理结束，结果在 #tmp_result 表，按项目GUID输出监管资金及账面资金余额
    ------------------------------------------------------------------------------------------
    -- 查询最终结果
    SELECT
        pj.项目GUID,
        pj.平台公司                AS 公司,
        pj.DevelopmentCompanyGUID as 平台公司GUID,
        pj.投管代码,
        pj.项目名                  AS 项目名称,
        pj.并表方式 as 并表方式,
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
        ch.导入方式,

        -- 存货结构-按支付口径
        ch.TotalCost   AS 存货结构_存货余额,
        case when isnull(ch.线下分摊_实际已付,0) <> 0  then ch.线下分摊_实际已付 
        else   -- 线上分摊实际已付
        (
            ISNULL(jacb.JacbSf, 0)
            + ISNULL(jt.Tdk, 0)
            + ISNULL(jt.zbhlxje, 0)
            + ISNULL(jt.kfjjfje, 0)
        ) * ch.TotalCostSumRate  end    AS 存货结构_实际已付,
        -- ISNULL(jacb.JacbJt, 0) * ch.TotalCostSumRate AS 存货结构_账面计提,
        isnull(ch.TotalCost,0) 
            -case when isnull(ch.线下分摊_实际已付,0) <> 0  then ch.线下分摊_实际已付 
            else   -- 线上分摊实际已付
            (
                ISNULL(jacb.JacbSf, 0)
                + ISNULL(jt.Tdk, 0)
                + ISNULL(jt.zbhlxje, 0)
                + ISNULL(jt.kfjjfje, 0)
            ) * ch.TotalCostSumRate  end AS 存货结构_账面计提,
        /*
          3、已完工产值-Q列：
            ①合作项目导入：取该产品楼栋的产值+土地款存货+开发间接费存货+资本化利息存货
            ②线上分摊、该项目存成本业态的产品楼栋未全部结转：取该产品楼栋的已完工产值+土地款存货+开发间接费存货+资本化利息存货
            ③线上分摊、该项目存成本业态的产品楼栋全部结转：取产品楼栋的已完工产值+土地款存货+资本化利息存货+开发间接费存货+土地款倒挤差额+资本化利息倒减差额 
        */  
        (ISNULL(cz.Zcz, 0)  + isnull(ch.土地款,0) + isnull(ch.开发间接费,0) + isnull(ch.资本化利息,0) + isnull(ch.土地款倒挤差额,0) + isnull(资本化利息倒挤差额,0) )  as 存货结构_总产值,
        isnull(cz.Xmpdljwccz,0) + isnull(ch.土地款,0) + isnull(ch.开发间接费,0) + isnull(ch.资本化利息,0) + isnull(ch.土地款倒挤差额,0) + isnull(资本化利息倒挤差额,0) as 存货结构_已达产值,
        isnull(cz.Xmpdljwccz,0) + isnull(ch.土地款,0) + isnull(ch.开发间接费,0) + isnull(ch.资本化利息,0) + isnull(ch.土地款倒挤差额,0) + isnull(资本化利息倒挤差额,0) - ISNULL(ch.TotalCost, 0) AS 存货结构_已达产值但未计提存货,
        
        (ISNULL(cz.Zcz, 0)  + isnull(ch.土地款,0) + isnull(ch.开发间接费,0) + isnull(ch.资本化利息,0) + isnull(ch.土地款倒挤差额,0) + isnull(资本化利息倒挤差额,0) )
         - ISNULL(ch.TotalCost, 0) 
         - ( isnull(cz.Xmpdljwccz,0) + isnull(ch.土地款,0) + isnull(ch.开发间接费,0) + isnull(ch.资本化利息,0) + isnull(ch.土地款倒挤差额,0) + isnull(资本化利息倒挤差额,0) - ISNULL(ch.TotalCost, 0)  ) AS 存货结构_项目竣备待发生成本,

        -- 存货按工程进度分类
        NULL                       AS 存货按工程进度分类_已投资未落实金额,-- 战投的填报报表F016_2-往来部分 直接放到已投资未落实的行中展示
        ch.Wkgtdje                 AS 存货按工程进度分类_未开工土地金额,
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


        ch.结转开发产品面积,
        ch.结转开发产品金额,
        ch.结转主营业务成本面积,
        ch.结转主营业务成本金额,

        F056.已售面积               AS 存货按工程进度分类_已售面积,
        -- F056.已售货值               AS 存货按工程进度分类_已售金额,
        ch.存货按工程进度分类_已售金额 as 存货按工程进度分类_已售金额,

        NULL                       AS 存货按工程进度分类_经营资产存成本经营资产面积, --该业态下资产卡片的面积（风险：跨业态建资产卡片）
        NULL                       AS 存货按工程进度分类_经营资产存成本经营资产金额, --该业态下资产卡片的面积（风险：跨业态建资产卡片）
        ch.存货按工程进度分类_经营资产不存成本经营资产面积 AS 存货按工程进度分类_经营资产不存成本经营资产面积,
        ch.存货按工程进度分类_成本结转面积,
        ch.存货按工程进度分析_成本结转金额,

        -- 未开工土地存货质量分析
        ch.Wkgtdje                 AS 未开工土地存货质量分析_存货金额,
        -- DATEDIFF(day, pj.获取时间, GETDATE()) / 365.0 AS 未开工土地存货质量分析_未开工土地账龄, -- 项目获取时间到报表统计时间
        ch.未开工土地账龄 as  未开工土地存货质量分析_未开工土地账龄, -- 项目获取时间到报表统计时间，仅需展示未开工土地的数据，已开工的业态不用展示
        ch.拟退存货面积             AS 未开工土地存货质量分析_拟退存货面积,
        ch.拟退存货金额             AS 未开工土地存货质量分析_拟退存货金额,
        ch.拟换存货面积             AS 未开工土地存货质量分析_拟换存货面积,
        ch.拟换存货金额             AS 未开工土地存货质量分析_拟换存货金额,
        ch.拟调存货面积             AS 未开工土地存货质量分析_拟调存货面积,
        ch.拟调存货金额             AS 未开工土地存货质量分析_拟调存货金额,

        -- 已开工未达可售存货质量分析
        isnull(ch.已开工分期_未开工楼栋存货金额,0) +isnull(ch.已开工分期_已开工未达可售条件楼栋存货金额,0) AS 已开工未达可售存货质量分析_存货金额,-- ①未开工楼栋金额+②已开工未达可售条件金额
        -- case when ch.实际开工完成日期 is not null then   datediff(day,ch.实际开工完成日期,getdate()) / 365.0 end  AS 已开工未达可售存货质量分析_账龄, -- 现在时间-开工时间
        case when (isnull(ch.已开工分期_未开工楼栋面积,0) +  isnull(已开工分期_已开工未达可售条件楼栋面积,0) ) =0 then 0
           else   ch.已开工未达可售存货质量分析_账龄面积 *1.0 / (isnull(ch.已开工分期_未开工楼栋面积,0) +  isnull(已开工分期_已开工未达可售条件楼栋面积,0) ) end as 已开工未达可售存货质量分析_账龄,

        -- ISNULL(cz.Zcz, 0) - ISNULL(ch.TotalCost, 0)
        --     - (isnull(cz.Xmpdljwccz,0) + isnull(ch.土地款,0) + isnull(ch.开发间接费,0) + isnull(ch.资本化利息,0) - ISNULL(ch.TotalCost, 0))  AS 已开工未达可售存货质量分析_竣备待发生成本,
        ch.已开工未达可售存货质量分析_竣备待发生成本 as 已开工未达可售存货质量分析_竣备待发生成本,
        NULL                       AS 已开工未达可售存货质量分析_冰冻存货面积, -- 增加产品楼栋的标签，历史数据处理
        NULL                       AS 已开工未达可售存货质量分析_冰冻存货金额, --冰冻标签下产品楼栋的金额
        NULL                       AS 已开工未达可售存货质量分析_冰冻存货待发生成本, --冰冻标签下产品楼栋的金额

        -- 已达可售条件未竣备但未售存货的质量分析
        ch.已达可售条件未竣备但未售存货的质量分析_存货套数 AS 已达可售条件未竣备但未售存货的质量分析_存货套数,
        ch.已达可售条件未竣备但未售存货的质量分析_存货面积 AS 已达可售条件未竣备但未售存货的质量分析_存货面积,
        ch.已达可售条件未竣备但未售存货的质量分析_存货金额 AS 已达可售条件未竣备但未售存货的质量分析_存货金额,
        -- case when  ch.竣工备案完成日期 is null   and  ch.实际开工完成日期 is not null 
        --     then   datediff(day,ch.实际开工完成日期,getdate()) / 365.0 end  AS 已达可售条件未竣备但未售存货的质量分析_账龄, -- 现在时间-开工时间
        case when  isnull(ch.已达可售条件未竣备但未售存货的质量分析_存货面积,0) =0 then  0
            else isnull(ch.已达可售条件未竣备但未售存货的质量分析_账龄面积,0) / isnull(ch.已达可售条件未竣备但未售存货的质量分析_存货面积,0) end 已达可售条件未竣备但未售存货的质量分析_账龄,  

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
        -- case when ch.竣工备案完成日期 is not null and  ch.实际开工完成日期 is not null then   datediff(day,ch.实际开工完成日期,getdate()) / 365.0 end  AS 已竣备未售存货的质量分析_账龄,-- 现在时间-开工时间
        -- case when ch.竣工备案完成日期 is not null then   datediff(day,ch.竣工备案完成日期,getdate()) / 365.0 end  AS 已竣备未售存货的质量分析按竣备起算_账龄,-- 现在时间-竣备时间
        case when isnull(ch.已竣备未售存货的质量分析_存货面积,0) =0 then  0 else  isnull(ch.已竣备未售存货的质量分析_账龄面积,0) / isnull(ch.已竣备未售存货的质量分析_存货面积,0) end   as  已竣备未售存货的质量分析_账龄,
        case when isnull(ch.已竣备未售存货的质量分析_存货面积,0) =0 then  0 else  isnull(ch.已竣备未售存货的质量分析按竣备起算_账龄面积,0) / isnull(ch.已竣备未售存货的质量分析_存货面积,0) end  as  已竣备未售存货的质量分析按竣备起算_账龄,
        
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
        --isnull(jt.累计实付直投,0) * ch.TotalCostSumRate AS 存货现金流风险分析_项目经营现金流_已支付直投, 
        ISNULL(jt.Tdk, 0) * ch.TotalCostSumRate +  isnull(ch.建安成本实付,0) as 存货现金流风险分析_项目经营现金流_已支付直投,
        isnull(F056.已售货值,0) -isnull(hl.回笼金额,0) AS 存货现金流风险分析_项目经营现金流_已签约待回笼, -- 已签约-已回笼
        --isnull(cz.Xmpdljwccz,0) -  isnull(jt.累计实付直投,0) * ch.TotalCostSumRate  AS 存货现金流风险分析_项目经营现金流_已发生产值待支付, -- 产值月度回顾中的已发生产值-已支付直投
        (isnull(cz.Xmpdljwccz,0) + isnull(ch.土地款,0) + isnull(ch.开发间接费,0) + isnull(ch.资本化利息,0))  
          - (ISNULL(jt.Tdk, 0) * ch.TotalCostSumRate +  isnull(ch.建安成本实付,0) )  AS 存货现金流风险分析_项目经营现金流_已发生产值待支付, -- 产值月度回顾中的已发生产值-已支付直投
        
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
        END AS 存货利润分析_未售存货_净利率,
        zmzj.期初监管资金余额 *ch.TotalCostSumRate  as 项目月初监管资金, -- 按照各业态的存货余额占比进行拆分
        zmzj.期初账面资金余额 *ch.TotalCostSumRate  as 项目月初可动用资金 -- 按照各业态的存货余额占比进行拆分
    into #result
    FROM #ch ch
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
        LEFT JOIN #jacb jacb  ON jacb.ProjGUID = ch.ProjGUID
        LEFT JOIN #jt jt ON jt.ProjGUID = ch.ProjGUID
        LEFT JOIN #lx_cb lx_cb  ON lx_cb.ProjGUID = ch.ProjGUID
        LEFT JOIN #lx_lr lx_lr ON lx_lr.ProjGUID = ch.ProjGUID
        left join #Shareholder_investment si on si.ProjGUID = ch.ProjGUID
        left join #zmzjSum zmzj on zmzj.projguid =ch.projguid 
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
        r1.[平台公司GUID],
        r1.[投管代码],                                        -- 投管代码
        r1.[项目名称],                                        -- 项目名称
        r1.[并表方式],
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
        null as 导入方式,

        -- 以下所有补充字段除“已投资未落实金额”外均为NULL作占位，便于后续汇总拼接
        NULL AS [存货结构_存货余额],
        NULL AS [存货结构_实际已付],
        NULL AS [存货结构_账面计提],
        0.0 as [存货结构_总产值],
        0.0 as [存货结构_已达产值],
        NULL AS [存货结构_已达产值但未计提存货],
        NULL AS [存货结构_项目竣备待发生成本],

        -- 仅此一项为实际取值：对应工程进度分类-已投资未落实金额
        ISNULL(f016.已投资未落实金额, 0) AS [存货按工程进度分类_已投资未落实金额],

        -- 其它“存货按工程进度分类”相关字段
        NULL AS [存货按工程进度分类_未开工土地金额],
        null as 未开工分期_未开工楼栋面积,
        null as 未开工分期_未开工楼栋存货金额,
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
        NULL as 存货按工程进度分类_已开工分期已经营资产面积, -- ⑥
        NULL as 存货按工程进度分类_已开工分期已经营资产存货金额, --⑥
        NULL AS 存货按工程进度分类_已开工分期未售存货不存成本面积, -- ⑦
        NULL as 存货按工程进度分类_已开工分期未售存货不存成本未经营面积, -- ⑦

        NULL as 结转开发产品面积,
        NULL as 结转开发产品金额,
        NULL as 结转主营业务成本面积,
        NULL as 结转主营业务成本金额,

        NULL AS [存货按工程进度分类_已售面积],
        NULL AS [存货按工程进度分类_已售金额],
        NULL AS [存货按工程进度分类_经营资产存成本经营资产面积],
        NULL AS [存货按工程进度分类_经营资产存成本经营资产金额],
        NULL AS [存货按工程进度分类_经营资产不存成本经营资产面积],
        NULL AS [存货按工程进度分类_成本结转面积],
        NULL AS  [存货按工程进度分析_成本结转金额],


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
        0.0 AS [存货现金流风险分析_项目经营现金流_已支付直投],
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
        NULL AS [存货利润分析_未售存货_净利率],

        null as  项目月初监管资金,
        null as 项目月初可动用资金
    FROM (
        -- 只取一次每个项目（去重），避免出现在#result已有多行造成重复插入
        SELECT DISTINCT
            [平台公司GUID], 
            [项目GUID],
            [公司],
            [投管代码],
            [项目名称],
            [并表方式],
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

    -- 清理数据
    TRUNCATE TABLE cb_存货分析报表;
    -- 查询最终结果
    INSERT INTO cb_存货分析报表
    SELECT *
    FROM #result;
    print '插入清洗表数据成功'
    -- 查询数据
    SELECT * FROM #result;

    -- 删除临时表
    DROP TABLE #proj, #ch, #chld, #cz, #czld, #lx_cb, #lx_lr, #sale,#SaleBld, #F056,#jt,#jacb,#F016,#result,#Shareholder_investment,#HL,#zmzj,#zmzjSum

END
