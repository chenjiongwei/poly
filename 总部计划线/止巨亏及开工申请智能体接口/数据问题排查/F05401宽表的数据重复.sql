USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_F054各项目基础信息系统取数原始表单_测试版]    Script Date: 2025/11/19 11:18:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_s_F054各项目基础信息系统取数原始表单_测试版]
(
    @var_buguid VARCHAR(MAX),
    @Date DATETIME = NULL,
    @VersionGUID VARCHAR(40) = '',
    @IsNew INT = 0
)
AS
/***********************************************                            
*函数功能:F054各项目基础信息系统取数原始表单                      
*输入参数:                            
    @var_buguid，界面选择的平台公司GUID                                          
     exec [usp_s_F054各项目基础信息系统取数原始表单_测试版] '7DF92561-3B0D-E711-80BA-E61F13C57837','2023-01-17','',0
Create by yp 20201017

modified by lintx 20250106
1、新增指标：自持面积、住宅类产品自持面积、商办类产品自持面积、预计整体竣工时间、实际整体竣工时间、供应链余额、累计结转成本、已完成产值金额、
合同约定应付金额、累计支付金额、应付未付、股东投入余额、账面资金余额、监管资金余额
2、口径调整：产值未付

modified by lintx 20250318
1、新增指标：定位总可售面积、暂不开发可售面积、住宅类产品暂不开发可售面积、商办类产品暂不开发可售面积、盈利规划预计总货值、未售部分占压投资
2、口径调整：累计结转面积、累计结转收入、累计结转成本

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
        PRINT '查看拍照版';

        SELECT OrgGuid,
               VersionGuid,
               公司名称,
               明源系统代码,
               项目代码,
               所属地块,
               项目名称,
               项目推广名,
               城市,
               所属行政区域,
               项目获取方式,
               项目获取日期,
               是否重难点项目,
               项目类型,
               销售状态,
               工程状态,
               获取总成本,
               地上可售楼面地价,
               我方股权比例,
               我方出资比例,
               我方收益比例,
               合作方,
               操盘方式,
               营销操盘方,
               工程操盘方,
               成本操盘方,
               技术操盘方,
               开发操盘方,
               物业操盘方,
               并表方式,
               净用地面积,
               总用地面积,
               总建筑面积,
               地上建筑面积,
               地下建筑面积,
               总可售面积,
               总计容面积,
               容积率,
               计容可售面积,
               累计开工面积,
               累计地上开工面积,
               累计竣工面积,
               累计地上竣工面积,
               在建面积,
               开工时间,
               首开时间,
               首开时长,
               竣工时间,
               完工时间,
               总货值,
               非车位货值,
               动态待售面积,
               动态待售金额,
               累计认购面积,
               累计认购金额,
               累计签约面积,
               除地下室签约面积,
               累计签约金额,
               除地下室签约金额,
               [累计回笼（万元）],
               定位总投资,
               [累计总投资（万元）],
               [累计直接投资其中土地费用（万元）],
               除地价外直接投资,
               [累计税金（万元）],
               [贷款余额（万元）],
               [累计结转面积（平方米）],
               [累计结转收入（万元）],
               经营性现金流,
               收回股东投资,
               收回股东投资时间,
               收回股东投资时长,
               实现正现金流时间,
               实现正现金流时长,
               目前预计税前利润,
               目前预计税前成本利润率,
               目前全投IRR,
               用友系统代码,
               管理方式,
               是否清算,
               是否纳入统计,
               用地性质,
               股权结构,
               并表方,
               项目公司,
               合并项目名称,
               合并项目代码,
               是否开发受限项目,
               是否合作受阻项目,
               是否待返还资金项目,
               住宅类产品可售面积,
               商办类产品可售面积,
               预计首期开工时间,
               预计首推时间,
               预计首批竣工时间,
               预计首批完工交付时间,
               动态住宅待售面积,
               动态住宅待售金额,
               动态商办待售面积,
               动态商办待售金额,
               总投资,
               税后现金利润,
               税后净现金,
               固定资产,
               总成本含税计划,
               资本化利息,
               财务费用计划,
               税前利润账面,
               结转口径税前成本利润率,
               税前利润计划,
               税后利润计划,
               反算税前成本利润率,
               城市能级,
               版块能级,
               累计已售面积,
               除地下室已售面积,
               累计已售金额,
               除地下室已售金额,
               总货量,
               项目五分类,
               城市六分化,
               客关操盘方,
               产值未付, --20250106口径调整
               停工面积,
               是否资金风险类项目,
                --20250106新增指标
                自持面积,
                住宅类产品自持面积,
                商办类产品自持面积,
                预计整体竣工时间,
                实际整体竣工时间,
                开发贷余额,
                供应链余额,
                累计结转成本,
                已完成产值金额,
                合同约定应付金额,
                累计支付金额,
                应付未付,
                股东投入余额,
                账面资金余额,
                监管资金余额,
                未售部分占压投资,
                盈利规划预计总货值,
                暂不开发可售货值,
                暂不开发类待售货值,
                住宅类暂不开发类待售货值,
                商办类类暂不开发类待售货值,
                暂不开发可售面积,
                住宅类产品暂不开发可售面积,
                商办类产品暂不开发可售面积,
                定位总可售面积
        FROM [dss].dbo.nmap_s_F05401各项目基础信息系统取数原始表单
        WHERE VersionGuid = @VersionGUID
              AND OrgGuid IN (
                                 SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                             );
    END;
    --实收获取报表的数据逻辑
    ELSE
    BEGIN
        --DECLARE @var_buguid VARCHAR(max)

        --SET @var_buguid='AADC0FA7-9546-49C9-B64B-825056C828ED'
        SET @VersionGUID = NEWID();

        SELECT p.*,gq.ShareRate
        INTO #p
        FROM mdm_Project p
        left join ( 
            -- select distinct 
            --     p.ProjGUID,
            --     s.ShareholderGUID,
            --     xmgs.DevelopmentCompanyGUID,
            --     s.ShareRate,-- 保利方股权比例最大值
            --     lb.LbProjectValue as 投管代码,
            --     s.Collaborator as 合作方简称 -- 多个合作方简称拼在一起
            -- from mdm_project p
            -- left join mdm_LbProject lb ON lb.projguid = p.projguid AND lb.LbProject = 'tgid'
            -- left join p_DevelopmentCompany xmgs on xmgs.DevelopmentCompanyGUID = p.ProjCompanyGUID
            -- left join p_ProjShareholder sh on sh.ProjCompanyGUID = xmgs.DevelopmentCompanyGUID 
            -- left join p_Shareholder s on sh.ShareholderGUID = s.ShareholderGUID and s.DevelopmentCompanyGUID = xmgs.DevelopmentCompanyGUID
            -- where p.Level = 2 and isnull(s.Collaborator,'') =''
           	SELECT 
                sh.ProjGUID,
                投管代码,
                DevelopmentCompanyGUID,
				max(case when 合作方简称 IS NULL then  ShareholderGUID end ) as ShareholderGUID,
                MAX(CASE WHEN 合作方简称 IS NULL THEN ShareRate END) AS ShareRate,
                STRING_AGG(合作方简称, ';') AS 合作方简称
            FROM (
                SELECT DISTINCT 
                    p.ProjGUID,
                    s.ShareholderGUID,
                    xmgs.DevelopmentCompanyGUID,
                    s.ShareRate,
                    lb.LbProjectValue AS 投管代码,
                    s.Collaborator AS 合作方简称
                FROM mdm_project p
                LEFT JOIN mdm_LbProject lb 
                    ON lb.projguid = p.projguid 
                    AND lb.LbProject = 'tgid'
                LEFT JOIN p_DevelopmentCompany xmgs 
                    ON xmgs.DevelopmentCompanyGUID = p.ProjCompanyGUID
                LEFT JOIN p_ProjShareholder sh 
                    ON sh.ProjCompanyGUID = xmgs.DevelopmentCompanyGUID 
                LEFT JOIN p_Shareholder s 
                    ON sh.ShareholderGUID = s.ShareholderGUID 
                    AND s.DevelopmentCompanyGUID = xmgs.DevelopmentCompanyGUID
                WHERE 
                    p.Level = 2 
                    AND ISNULL(s.Collaborator, '') = ''
            ) sh 
            GROUP BY 
                sh.ProjGUID,
                投管代码,
                DevelopmentCompanyGUID
        ) gq on gq.ProjGUID = p.ProjGUID
        WHERE p.Level = 2
              AND p.DevelopmentCompanyGUID IN (
                                                  SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                                              );

        --获取合作方简称         
        select STRING_AGG(hzf.Partners,';') as Partners,p.ProjGUID
        into #hzf
        from #p p
        cross apply (select value from fn_Split2(PartnerGUID,';'))t 
        inner join p_DevelopmentCompany hzf on hzf.DevelopmentCompanyGUID = t.Value and isnull(t.Value,'')<>''       
		group by p.ProjGUID

        --获取并表方简称     
        select STRING_AGG(hzf.Partners,';') as bbf ,p.ProjGUID
        into #bbf
        from #p p
        cross apply (select value from fn_Split2(BbfGUIDs,';'))t 
        inner join p_DevelopmentCompany hzf on hzf.DevelopmentCompanyGUID = t.Value and isnull(t.Value,'')<>''   
		group by p.ProjGUID

        --获取项目对应的基础数据定位总可售面积
        select projguid,SumSaleArea as 定位总可售面积
        into #dw_salearea 
        from (SELECT p.*,ROW_NUMBER() OVER (PARTITION BY pj.ProjGUID ORDER BY pj.CreateDate DESC) AS ranknum
                FROM vmd_DwProject352 pj
                inner join MyCost_Erp352.dbo.md_Project p on p.VersionGUID = pj.VersionGUID
        ) t where t.ranknum = 1 and t.level = 2

        SELECT DISTINCT
               p.ProjGUID,
               (
                   SELECT STUFF(
                          (
                              SELECT ';' + CONVERT(VARCHAR(200), ShareholderName)
                              FROM data_wide_s_ProjShareholder ps
                              WHERE ps.ProjGUID = p.ProjGUID
                              FOR XML PATH('')
                          ),
                          1,
                          1,
                          ''
                               )
               ) AS 项目公司,
               (
                   SELECT STUFF(
                          (
                              SELECT ';'
                                     + CASE
                                           WHEN ShareRate = 100 THEN
                                                ShareholderName + ':'
                                                + CONVERT(VARCHAR(200), CONVERT(DECIMAL(18, 2), ROUND(ShareRate * 1.0, 2)))
                                           ELSE ShareholderName + ':'
                                                + CONVERT(VARCHAR(200), CONVERT(DECIMAL(18, 2), ROUND(ShareRate * 1.0, 2)))
                                       END
                              FROM data_wide_s_ProjShareholder ps
                              WHERE ps.ProjGUID = p.ProjGUID
                              FOR XML PATH('')
                          ),
                          1,
                          1,
                          ''
                               )
               ) AS 股权比例
        INTO #gq
        FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Project p with (nolock)
             INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_Dimension_Organization do with (nolock) ON p.BUGUID = do.OrgGUID
                                                                                                      AND do.IsEndCompany = 1
            -- LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ys_DssCashFlowData dd with (nolock) ON dd.ProjGUID = p.ProjGUID
             INNER JOIN #p pp ON p.ProjGUID = pp.ProjGUID
        WHERE p.Level = 2
              AND ISNULL(p.TgProjCode, '') <> '';

        --取盈利规划
        SELECT pj.ProjGUID,
                SUM(   CASE
                          WHEN F08.[报表预测项目科目] in ('营业税下收入','增值税下含税收入') THEN
                               CAST(ISNULL(F08.VALUE_STRING, '0') AS DECIMAL(32, 6))
                      END
                  ) / 100000000 AS 销售收入含税,
               SUM(   CASE
                          WHEN F08.[报表预测项目科目] = '总成本（含税，计划）' THEN
                               CAST(ISNULL(F08.VALUE_STRING, '0') AS DECIMAL(32, 6))
                      END
                  ) / 100000000 AS 总成本含税计划,
               SUM(   CASE
                          WHEN F08.[报表预测项目科目] = '财务费用（计划）' THEN
                               CAST(ISNULL(F08.VALUE_STRING, '0') AS DECIMAL(32, 6))
                      END
                  ) / 100000000 AS 财务费用计划,
               SUM(   CASE
                          WHEN F08.[报表预测项目科目] = '资本化利息' THEN
                               CAST(ISNULL(F08.VALUE_STRING, '0') AS DECIMAL(32, 6))
                      END
                  ) / 100000000 AS 资本化利息,
               SUM(   CASE
                          WHEN F08.[报表预测项目科目] = '税前利润（账面）' THEN
                               CAST(ISNULL(F08.VALUE_STRING, '0') AS DECIMAL(32, 6))
                      END
                  ) / 100000000 税前利润账面
        INTO #f08
        FROM #p pj
             LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID p with (nolock) ON p.ProjGUID = pj.ProjGUID
                                                                                       AND p.isbase = 1
                                                                                       AND p.Level = 3
             LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_qt_F080004 F08 with (nolock) ON F08.实体分期 = p.YLGHProjGUID and  p.BusinessEdition = f08.版本
        WHERE CHARINDEX('e', ISNULL(F08.VALUE_STRING, '0')) = 0
              AND F08.[报表预测项目科目] IN ( '总成本（含税，计划）', '结转成本', '财务费用（计划）', '资本化利息', '总成本（不含税，账面）', '税前利润（账面）','营业税下收入','增值税下含税收入' )
              AND F08.明细说明 = '总价'
              AND F08.业态 = '不区分业态'
        GROUP BY pj.ProjGUID;

        --F06
        SELECT pj.ProjGUID,
               SUM(   CASE
                          WHEN F06.[报表预测项目科目] = '税前利润（计划）' THEN
                               CAST(ISNULL(F06.VALUE_STRING, '0') AS DECIMAL(32, 6))
                      END
                  ) / 100000000 AS 税前利润计划,
               SUM(   CASE
                          WHEN F06.[报表预测项目科目] = '税后利润（计划）' THEN
                               CAST(ISNULL(F06.VALUE_STRING, '0') AS DECIMAL(32, 6))
                      END
                  ) / 100000000 AS 税后利润计划,
               CASE
                   WHEN SUM(   CASE
                                   WHEN F06.[报表预测项目科目] = '总投资（计划含税）' THEN
                                        CAST(ISNULL(F06.VALUE_STRING, '0') AS DECIMAL(32, 6))
                               END
                           ) <> 0 THEN
                        SUM(   CASE
                                   WHEN F06.[报表预测项目科目] = '税后利润（计划）' THEN
                                        CAST(ISNULL(F06.VALUE_STRING, '0') AS DECIMAL(32, 6))
                               END
                           ) / SUM(   CASE
                                          WHEN F06.[报表预测项目科目] = '总投资（计划含税）' THEN
                                               CAST(ISNULL(F06.VALUE_STRING, '0') AS DECIMAL(32, 6))
                                      END
                                  ) / 0.75
               END 反算税前成本利润率
        INTO #f06
        FROM #p pj
             LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID p with (nolock) ON p.ProjGUID = pj.ProjGUID
                                                                                       AND p.isbase = 1
                                                                                       AND p.Level = 3
             LEFT JOIN [172.16.4.161].HighData_prod.dbo.data_wide_qt_F080006 F06 with (nolock) ON F06.实体分期 = p.YLGHProjGUID AND p.businessedition = F06.版本
        WHERE CHARINDEX('e', ISNULL(F06.VALUE_STRING, '0')) = 0
              AND F06.[报表预测项目科目] IN ( '税前利润（计划）', '总投资（计划含税）', '税后利润（计划）' )
              AND F06.明细说明 = '调整后'
        GROUP BY pj.ProjGUID;

        --取总建面
        SELECT ISNULL(mp1.projguid, mp.projguid) projguid,
               SUM(ISNULL(sb.UpBuildArea, 0)) UpBuildArea,
               SUM(ISNULL(sb.DownBuildArea, 0)) DownBuildArea,
               SUM(ISNULL(sb.UpBuildArea, 0) + ISNULL(sb.DownBuildArea, 0)) bldarea,
               SUM(CASE WHEN mdp.ProductType IN ( '住宅', '别墅', '高级住宅' ) THEN sb.SaleArea ELSE 0 END)  住宅类产品可售面积,
               SUM(CASE WHEN mdp.ProductType IN ( '公寓', '商业', '写字楼', '企业会所', '酒店' ) THEN sb.SaleArea ELSE 0 END)  商办类产品可售面积,
               SUM(CASE WHEN BuildTagValue like 'B%' or BuildTagValue like 'C%' THEN sb.SaleArea ELSE 0 END)  暂不开发可售面积,	
               SUM(CASE WHEN mdp.ProductType IN ( '住宅', '别墅', '高级住宅' ) and (BuildTagValue like 'B%' or BuildTagValue like 'C%') THEN sb.SaleArea ELSE 0 END)  住宅类产品暂不开发可售面积,
               SUM(CASE WHEN mdp.ProductType IN ('公寓', '商业', '写字楼', '企业会所', '酒店') and (BuildTagValue like 'B%' or BuildTagValue like 'C%') THEN sb.SaleArea ELSE 0 END) 商办类产品暂不开发可售面积
        INTO #zjm
        FROM mdm_SaleBuild sb
             LEFT JOIN mdm_gcbuild gb ON sb.GCBldGUID = gb.GCBldGUID
             LEFT JOIN mdm_project mp ON gb.projguid = mp.projguid
             LEFT JOIN mdm_project mp1 ON mp.ParentProjGUID = mp1.projguid
             LEFT JOIN dbo.mdm_Product mdp ON sb.ProductGUID = mdp.ProductGUID
             left join mdm_BuildTag tag on tag.salebldguid = sb.salebldguid and tag.BuildTag = 'SDT'
             INNER JOIN #p p ON mp1.projguid = p.projguid
        GROUP BY ISNULL(mp1.projguid, mp.projguid);

        ---停工
        SELECT 投管项目编码,
               SUM(ISNULL(计划组团建筑面积, 0)) 计划组团建筑面积
        INTO #tgmj
        FROM mycost_erp352.dbo.jd_PlanTaskExecuteObjectForReport
        WHERE 实际开工实际完成时间 IS NOT NULL
              AND 竣工备案实际完成时间 IS NULL
              AND 是否停工 = '停工'
        GROUP BY 投管项目编码;
 
        --基础数据中间表的自持面积 
        SELECT  b.ParentProjGUID projguid,  
        sum(a.HoldArea)/ 10000.0 自持面积, 
        SUM(CASE WHEN ld.ProductType IN ( '住宅', '别墅', '高级住宅' ) THEN a.HoldArea ELSE 0 END ) / 10000.0 住宅类产品自持面积,
        SUM(CASE WHEN ld.ProductType IN ( '公寓', '商业', '写字楼', '企业会所', '酒店' ) THEN a.HoldArea ELSE 0 END ) / 10000.0 商办类产品自持面积
        into #zs_area
        FROM mycost_erp352.dbo.vs_md_productbuild_getAreaAndSpaceNumInfo a
            inner JOIN erp25.dbo.mdm_Project b ON a.ProjGUID = b.ProjGUID  
            inner join #p p on b.ParentProjGUID = p.projguid 
            left join erp25.dbo.p_lddb ld on ld.SaleBldGUID =a.ProductBuildGUID and datediff(dd,qxdate,getdate()) = 0
        group BY b.ParentProjGUID

        --获取最后一个楼栋竣工时间
        select p.projguid, 
        max(ld.yjjgbadate) as 最后一个楼栋计划竣工时间
        into #last_ld_yjjgbadate
        from p_lddb ld 
        inner join #p p on ld.projguid = p.projguid
        where datediff(dd,ld.qxdate,getdate()) = 0
        group by p.projguid

        --获取开发结转成本的最新版本
        select * 
        into #CarryOverDbb
        from (
        select projguid,ROW_NUMBER() over(PARTITION BY projguid order by ApproveDate desc) as RowNum,CarryOverDevelopGUID 
        from  [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelop with (nolock) where ApproverState = '已审核') t where t.RowNum = 1

        --获取主营业务成本
        select * 
        into #CarryOverMbb
        from (
        select projguid,ROW_NUMBER() over(PARTITION BY projguid order by ApproveDate desc) as RowNum,CarryOverMainGUID 
        from [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain  with (nolock) where ApproverState = '已审核') t where t.RowNum = 1

        select p.parentprojguid as projguid,sum(t.TotalMoney)/10000.0 as TotalMoney 
        into #Jzcb
        from (
        --结转开发成本
        select 
        gc.ProjGUID,
        sum(CASE WHEN e.ProductCostRecollectName IS NOT NULL AND e.ProductCostRecollectName <> ''
        THEN ISNULL(d.TotalMoney,0) ELSE ISNULL(b.TotalMoney, 0) END) AS TotalMoney 
        from  erp25.dbo.mdm_SaleBuild ld
        inner join erp25.dbo.mdm_GCBuild gc on gc.GCBldGUID = ld.GCBldGUID
        inner join mdm_project p on p.projguid = gc.projguid
        inner join #p pj on pj.projguid = p.parentprojguid
        left join #CarryOverDbb bb on bb.projguid = gc.projguid
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelopSetBldDtl b with (nolock) ON  ld.SaleBldGUID = b.BldGUID AND  b.Subject = 4
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelopSet c with (nolock) on b.CarryOverDevelopSetGUID = c.CarryOverDevelopSetGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelopBldDtl  d with (nolock) ON  ld.SaleBldGUID = d.BldGUID AND d.Subject = 4 and d.CarryOverDevelopGUID = bb.CarryOverDevelopGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverDevelop e with (nolock) on d.CarryOverDevelopGUID = e.CarryOverDevelopGUID
        -- where gc.ProjGUID = '116A20D9-2A43-E811-80BA-E61F13C57837'
		group by gc.ProjGUID
        union all
        --结转开发成本
        select 
        gc.ProjGUID,
        sum(CASE WHEN e.CarryOverMainGUID IS NOT NULL THEN ISNULL(d.TotalMoney,0) ELSE  ISNULL(b.TotalMoney, 0) END) AS TotalMoney 
        from  erp25.dbo.mdm_SaleBuild ld
        inner join erp25.dbo.mdm_GCBuild gc on gc.GCBldGUID = ld.GCBldGUID
        inner join mdm_project p on p.projguid = gc.projguid
        inner join #p pj on pj.projguid = p.parentprojguid
        left join #CarryOverMbb bb on bb.projguid = gc.projguid
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSetBldDtl b with (nolock) ON  ld.SaleBldGUID = b.BldGUID AND  b.Subject = 4
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainSet c with (nolock) on b.CarryOverMainSetGUID = c.CarryOverMainSetGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMainBldDtl d with (nolock) ON  ld.SaleBldGUID = d.BldGUID AND d.Subject = 4 and d.CarryOverMainGUID = bb.CarryOverMainGUID
        left join [172.16.4.131].[TaskCenterData].dbo.cb_CarryOverMain e with (nolock) on d.CarryOverMainGUID = e.CarryOverMainGUID
        -- where gc.ProjGUID = '116A20D9-2A43-E811-80BA-E61F13C57837'
		group by gc.ProjGUID
        ) t
        inner join erp25.dbo.mdm_Project p on t.projguid = p.ProjGUID
        group by p.parentprojguid

        --账面资金取数---开始
        select max(business_date) as business_date 
        into #d_date
        from [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_fund_detail with (nolock)
        where  balance >0 and business_date <  CONVERT(datetime, CONVERT(varchar, GETDATE(), 112))

        --缓存项目公司跟项目的映射情况 
        /*select cltProjectCode,cltProjectName,project_company,TgProjCode my_tgprojcode,pj.ProjGUID,account_nature,capital_nature,balance
        into #dw_proj_com
        from [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_fund_detail t with (nolock)
        left join [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj with (nolock) on (pj.TgProjCode = t.cltProjectCode or cltProjectName = projname)  and pj.level = 2
        inner join #p p on pj.projguid = p.ProjGUID
        inner join #d_date dd on 1=1
        where datediff(dd,t.business_date,dd.business_date) = 0
		*/
		--性能优化 tangqn01 20250701
		select cltProjectCode,cltProjectName,project_company,TgProjCode my_tgprojcode,pj.ProjGUID,account_nature,capital_nature,balance
        into #dw_proj_com
        from [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_fund_detail  t with (nolock)
		inner join #d_date dd on t.business_date = dd.business_date
        left join [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_project pj with (nolock) on (pj.TgProjCode = t.cltProjectCode or cltProjectName = projname)  and pj.level = 2
        inner join #p p on pj.projguid = p.ProjGUID   
		where  1 = 1

        --缓存项目公司及项目的映射关系
        select  project_company,ProjGUID
        into #com_proj
        from #dw_proj_com
        group by project_company,ProjGUID
        
        select project_company,count(distinct projguid) as proj_num
        into #proj_num
        from #com_proj
        where projguid is not null 
        group by project_company

        --缓存项目公司的资金情况
        select project_company,account_nature,capital_nature,sum(balance) as 项目公司资金
        into #zj
        from #dw_proj_com
        group by project_company,account_nature,capital_nature
        
        --如果是项目公司跟项目数量是一比一的，把对应项目公司的所有户都归到这个项目上
        select cp.ProjGUID, t.项目公司资金 期末账面资金余额, 
        case when account_nature = '监控房款户' then t.项目公司资金 else 0 end  as 期末监管资金余额
        into #tmp_result
        from #zj t 
        inner join #proj_num proj on t.project_company = proj.project_company
        inner join #com_proj cp on t.project_company = cp.project_company
        where proj.proj_num = 1

        --存在项目公司有多个项目的情况：
        --获取项目的本年回笼金额,对比项目公司中项目的回笼金额 
        select t.*,本年回笼金额,row_number() over(PARTITION BY t.project_company order by isnull(本年回笼金额,0) desc )  as rn
        into #hl
        from #com_proj t
        left join (
        select 项目GUID,sum(本年回笼金额) as  本年回笼金额  
        from [172.16.4.161].highdata_prod.dbo.dw_f_TopProject_getin with (nolock)
        group by 项目guid
        ) hl on t.projguid = hl.项目guid

        insert into #tmp_result
        select cp.ProjGUID,
        t.项目公司资金 期末账面资金余额, 
        case when cp.rn = 1 then  t.项目公司资金 else 0 end as 期末监管资金余额 
        from #zj t 
        inner join #proj_num proj on t.project_company = proj.project_company
        inner join  #hl cp on t.project_company = cp.project_company
        where proj.proj_num > 1 --and cp.ProjGUID = 'FE4A0198-9B8C-E711-80BA-E61F13C57837'

        select pj.ProjGUID,pj.ProjName,pj.TgProjCode, pj.level,
        sum(t.期末监管资金余额)/10000.0 as 期末监管资金余额,sum(t.期末账面资金余额)/10000.0 as 期末账面资金余额
        into #jhx
        from #tmp_result t
        inner join [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project pj on t.ProjGUID = pj.ProjGUID
        group by pj.ProjGUID,pj.ProjName,pj.TgProjCode,pj.Level

        --账面资金取数---结束

        --股东投入余额
        select p.项目guid,sum(isnull(截止目前股东合作方投入余额C,0))/10000  as 股东投入余额
        into #gd
        from [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_Shareholder_investment t with (nolock)
        inner join [172.16.4.161].highdata_prod.dbo.data_wide_ys_nmap_F_FillHistory fill with (nolock) on t.[FillHistoryGUID] = fill.[FillHistoryGUID]
        inner join [172.16.4.161].highdata_prod.dbo.dw_d_topproject p on p.投管明源系统项目代码 = t.明源代码
        inner join #p pj on pj.projguid = p.项目guid
        inner join (
        select  max(fill.BeginDate) as BeginDate
        from [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_Shareholder_investment t with (nolock)
        inner join [172.16.4.161].highdata_prod.dbo.data_wide_ys_nmap_F_FillHistory fill with (nolock) on t.[FillHistoryGUID] = fill.[FillHistoryGUID]
        where 截止目前股东合作方投入余额C >0
        ) tt on datediff(dd,tt.BeginDate,fill.begindate) = 0
        group by p.项目guid

        --获取产值月度回顾情况
        --获取项目已审核的最晚回顾时间记录
        select * 
        into #OutputValuebb
        from (
        select projguid,ROW_NUMBER() over(PARTITION BY projguid order by ReviewDate desc) as RowNum,OutputValueMonthReviewGUID 
        from MyCost_Erp352.dbo.cb_OutputValueMonthReview where ApproveState in ('已审核','审核中')) t where t.RowNum = 1

        SELECT  pp.projguid, 
                sum(ydhg.YfsOutputValue)/10000.0 as 已完成产值金额, 
                sum(ydhg.LjyfAmount)/10000.0 AS 合同约定应付金额,
                sum(ydhg.LjsfAmount)/10000.0 as 累计支付金额, 
                sum(ydhg.YfwfAmount)/10000.0 as 应付未付 
        into #OutputValue
        FROM    MyCost_Erp352.dbo.cb_OutputValueMonthReview ydhg
                inner join #OutputValuebb bb on ydhg.OutputValueMonthReviewGUID = bb.OutputValueMonthReviewGUID
                inner join erp25.dbo.mdm_Project p on p.ProjGUID = bb.ProjGUID
                inner join #p pp on p.ParentProjGUID = pp.ProjGUID
        group by pp.projguid

        SELECT db.ProjGUID,
               MIN(db.YJzskgdate) yjkgdate,
               MIN(db.SJzskgdate) kgdate,
               MIN(db.YJkpxsDate) yjskdate,
               MIN(db.SJkpxsDate) skdate,
               MIN(db.YJjgbadate) yjjgdate,
               MIN(db.SJjgbadate) jgdate,
               MIN(   CASE
                          WHEN db.JzjfYjdate <= db.YJjgbadate THEN
                               db.JzjfYjdate
                          ELSE db.YJjgbadate
                      END
                  ) yjfinishdate,
               MIN(   CASE
                          WHEN db.JzjfSjdate <= db.SJjgbadate THEN
                               db.JzjfSjdate
                          ELSE db.SJjgbadate
                      END
                  ) finishdate,
               SUM(db.zksmj) zksmj,
               SUM(db.zhz) zhz,
               SUM(   CASE
                          WHEN db.ProductType = '地下室/车库' THEN
                               0
                          ELSE db.zhz
                      END
                  ) fcwHz,
               SUM(db.zksmj - db.ysmj) - ISNULL(hz.hzarea, 0) dtdsmj,
               SUM(db.zhz - db.ysje) - ISNULL(hz.hzje, 0) dtdsje,
               SUM(db.ysmj) + ISNULL(hz.hzarea, 0) ysmj,
               SUM(   CASE
                          WHEN db.ProductType <> '地下室/车库' THEN
                               db.ysmj
                          ELSE 0
                      END
                ) + ISNULL(hz.HzFcwYsmj, 0) FcwYsmj,
                SUM(db.ysje) + ISNULL(hz.hzje, 0) ysje,
                SUM(   CASE
                           WHEN db.ProductType <> '地下室/车库' THEN
                                db.ysje
                           ELSE 0
                       END
                   ) + ISNULL(hz.HzFcwYsje, 0) FcwYsJe,
                SUM(   CASE
                           WHEN db.ProductType IN ( '住宅', '别墅', '高级住宅' ) THEN
                                db.zksmj - db.ysmj
                           ELSE 0
                       END
                   ) - ISNULL(hz.hzzzarea, 0) dtzzdsmj,
                SUM(   CASE
                           WHEN db.ProductType IN ( '住宅', '别墅', '高级住宅' ) THEN
                                db.zhz - db.ysje
                           ELSE 0
                       END
                   ) - ISNULL(hz.hzzzje, 0) dtzzdsje,
                SUM(   CASE
                           WHEN db.ProductType IN ( '公寓', '商业', '写字楼', '企业会所', '酒店' ) THEN
                                db.zksmj - db.ysmj
                           ELSE 0
                       END
                   ) - ISNULL(hz.hzsbarea, 0) dtsbdsmj,
                SUM(   CASE
                           WHEN db.ProductType IN ( '公寓', '商业', '写字楼', '企业会所', '酒店' ) THEN
                                db.zhz - db.ysje
                           ELSE 0
                       END
                   ) - ISNULL(hz.hzsbje, 0) dtsbdsje,
                max(lld.最后一个楼栋计划竣工时间) as 预计整体竣工时间,
                max(case when datediff(dd,db.yjjgbadate,lld.最后一个楼栋计划竣工时间) = 0 then db.SJjgbadate else null end) as 实际整体竣工时间,
                sum(case when tag.BuildTagValue like 'B%' or tag.BuildTagValue like 'C%' then zhz else 0 end) 暂不开发可售货值,
                sum(case when tag.BuildTagValue like 'B%' or tag.BuildTagValue like 'C%' then db.zhz - db.ysje else 0 end) 暂不开发类待售货值,
                sum(case when (tag.BuildTagValue like 'B%' or tag.BuildTagValue like 'C%') and db.ProductType IN ('住宅', '别墅', '高级住宅') then db.zhz - db.ysje else 0 end) 住宅类暂不开发类待售货值,
                sum(case when (tag.BuildTagValue like 'B%' or tag.BuildTagValue like 'C%') and db.ProductType IN ('公寓', '商业', '写字楼', '企业会所', '酒店') then db.zhz - db.ysje else 0 end) 商办类类暂不开发类待售货值
                 into #lddbamj
                 FROM dbo.p_lddbamj db
                      INNER JOIN #p p ON p.ProjGUID = db.ProjGUID
                      left join #last_ld_yjjgbadate lld on p.projguid = lld.projguid
                      left join mdm_BuildTag tag on tag.SaleBldGUID = db.SaleBldGUID and  tag.BuildTag = 'SDT'
                      LEFT JOIN
                      (
                          SELECT p.ProjGUID,
                                 SUM(b.Area) hzarea,
                                 SUM(b.Amount * 10000) hzje,
                                 SUM(   CASE
                                            WHEN b.producttype <> '地下室/车库' THEN
                                                 b.area
                                            ELSE 0
                                        END
                                    ) HzFcwYsmj,
                                 SUM(   CASE
                                            WHEN b.producttype <> '地下室/车库' THEN
                                                 b.Amount * 10000
                                            ELSE 0
                                        END
                                    ) HzFcwYsje,
                                 SUM(   CASE
                                            WHEN b.ProductType IN ( '住宅', '别墅', '高级住宅' ) THEN
                                                 b.Area
                                            ELSE 0
                                        END
                                    ) hzzzarea,
                                 SUM(   CASE
                                            WHEN b.ProductType IN ( '住宅', '别墅', '高级住宅' ) THEN
                                                 b.Amount * 10000
                                            ELSE 0
                                        END
                                    ) hzzzje,
                                 SUM(   CASE
                                            WHEN b.ProductType IN ( '公寓', '商业', '写字楼', '企业会所', '酒店' ) THEN
                                                 b.Area
                                            ELSE 0
                                        END
                                    ) hzsbarea,
                                 SUM(   CASE
                                            WHEN b.ProductType IN ( '公寓', '商业', '写字楼', '企业会所', '酒店' ) THEN
                                                 b.Amount * 10000
                                            ELSE 0
                                        END
                                    ) hzsbje
                          FROM s_YJRLProducteDetail a
                               INNER JOIN s_YJRLProjSet s ON a.ProjSetGUID = s.ProjSetGUID
                               LEFT JOIN s_YJRLProducteDescript b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                               INNER JOIN #p p ON s.ProjGUID = p.ProjGUID
                          WHERE 1 = 1
                                AND a.Shenhe = '审核'
                                AND NOT EXISTS
                          (
                              SELECT 1
                              FROM s_YJRLBuildingDescript bb
                                   INNER JOIN s_YJRLProducteDetail dd ON bb.ProducteDetailGUID = dd.ProducteDetailGUID
                              WHERE dd.Shenhe = '审核'
                                    AND dd.ProjSetGUID = s.ProjSetGUID
                          ) --过滤掉录入到楼栋的
                          GROUP BY p.ProjGUID
                      ) hz ON hz.ProjGUID = db.ProjGUID
                 WHERE DATEDIFF(DAY, QXDate, GETDATE()) = 0
                 GROUP BY db.ProjGUID,
                          ISNULL(hz.hzarea, 0),
                          ISNULL(hz.hzje, 0),
                          ISNULL(hz.hzzzarea, 0),
                          ISNULL(hz.hzzzje, 0),
                          ISNULL(hz.hzsbarea, 0),
                          ISNULL(hz.hzsbje, 0),
                          ISNULL(hz.HzFcwYsje, 0),
                          ISNULL(hz.HzFcwYsmj, 0)

        SELECT dv.DevelopmentCompanyGUID OrgGUID,
               @VersionGUID VersionGUID,
               dv.DevelopmentCompanyName 公司名称,
               p.ProjCode 明源系统代码,
               lb.LbProjectValue 项目代码,
               所属地块 = STUFF(
                      (
                          SELECT ';' + b.LandName
                          FROM dbo.mdm_Project2Land a
                               LEFT JOIN dbo.p_LandInfo b ON b.LandGUID = a.LandGUID
                          WHERE a.ProjGUID = p.ProjGUID
                          FOR XML PATH('')
                      ),
                      1,
                      1,
                      ''
                           ),
               p.ProjName 项目名称,
               p.SpreadName 项目推广名,
               city.ParamValue 城市,
               area.ParamValue 所属行政区域,
               p.XMHQFS 项目获取方式,
               p.AcquisitionDate 项目获取日期,
               p.IsZNDProj 是否重难点项目,
               p.ProjStatus 项目类型,
               p.SaleStatus 销售状态,
               p.ConstructStatus 工程状态,
               p.TotalLandPrice / 100000000 获取总成本,
               p.SaleLMDJ 地上可售楼面地价,
               case when isnull(p.GQRatio,0)= 0 then p.ShareRate else p.GQRatio end 我方股权比例,
               p.TZRatio 我方出资比例,
               p.EquityRatio 我方收益比例,
            --    p.PartnerName 合作方,
               hzf.Partners 合作方, --改成合作方简称
               p.TradersWay 操盘方式,
               p.YXCpf 营销操盘方,
               p.GCCpf 工程操盘方,
               p.CBCpf 成本操盘方,
               p.JSCpf 技术操盘方,
               p.KFCpf 开发操盘方,
               p.WYCpf 物业操盘方,
               p.BbWay 并表方式,
               md.Jarea / 10000 净用地面积,
               md.TotalArea / 10000 总用地面积,
               ISNULL(zjm.bldarea, md.SumBuildArea) / 10000 总建筑面积,
               ISNULL(zjm.UpBuildArea, md.SumUpArea) / 10000 地上建筑面积,
               ISNULL(zjm.DownBuildArea, md.SumDownArea) / 10000 地下建筑面积,
               md.SumSaleArea / 10000 总可售面积,
               md.SumJrArea / 10000 总计容面积,
               md.VolumeRate 容积率,
               md.JrSaleArea / 10000 计容可售面积,
               kg.ljkgArea / 10000 累计开工面积,
               kg.ljdskgArea / 10000 累计地上开工面积,
               kg.ljjgArea / 10000 累计竣工面积,
               kg.ljdsjgArea / 10000 累计地上竣工面积,
               kg.zjArea / 10000 在建面积,
               s.kgdate 开工时间,
               --s.skdate  首开时间,
               sk.skdate 首开时间,
               DATEDIFF(DAY, p.AcquisitionDate, sk.skdate) / 30 首开时长,
               s.jgdate 竣工时间,
               s.finishdate 完工时间,
               s.zhz / 10000 总货值,
               s.fcwHz / 10000 非车位货值,
               s.dtdsmj / 10000 动态待售面积,
               s.dtdsje / 10000 动态待售金额,
               rgqy.累计认购面积,
               rgqy.累计认购金额,
               rgqy.累计签约面积,
               rgqy.除地下室签约面积,
               rgqy.累计签约金额,
               rgqy.除地下室签约金额,
               dss.[累计回笼（万元）] 累计回笼,
               CASE
                   WHEN ISNULL(hd.ZTZDWPF, 0) <> 0 THEN
                        hd.ZTZDWPF
                   WHEN ISNULL(hd.ZTZDWSB, 0) <> 0 THEN
                        hd.ZTZDWSB
               END * 10000 定位总投资,
               dss.[累计总投资（万元）] 累计总投资,
               dss.[累计直接投资其中土地费用（万元）] 累计直接投资其中土地费用,
               dss.除地价外直接投资,
               dss.[累计税金（万元）] 累计税金,
               dss.[贷款余额（万元）] 贷款余额,
               dss.[累计结转面积（平方米）] 累计结转面积,
               dss.[累计结转收入（万元）] 累计结转收入,
               dss.经营性现金流,
               dss.收回股东投资,
               t.ShgdtzFactDate 收回股东投资时间,
               DATEDIFF(DAY, p.AcquisitionDate, t.ShgdtzFactDate) / 30 收回股东投资时长,
               t.SjzxjlFactDate 实现正现金流时间,
               DATEDIFF(DAY, p.AcquisitionDate, t.SjzxjlFactDate) / 30 实现正现金流时长,
               pro.税前利润 * 10000 目前预计税前利润,
               hd.DtTaxCostRatio 目前预计税前成本利润率,
               hd.DtIRR 目前全投IRR,
               NULL 用友系统代码,
               p.ManageModeName 管理方式,
               qs.LbProjectValue 是否清算,
               tj.LbProjectValue 是否纳入统计,
               用地性质 = STUFF(
                      (
                          SELECT ';' + b.LandType
                          FROM dbo.mdm_Project2Land a
                               LEFT JOIN dbo.p_LandInfo b ON b.LandGUID = a.LandGUID
                          WHERE a.ProjGUID = p.ProjGUID
                          FOR XML PATH('')
                      ),
                      1,
                      1,
                      ''
                           ),
               gq.股权比例 股权结构,
               bbf.Bbf 并表方,
               项目公司 = ISNULL(
                                STUFF(
                                (
                                    SELECT DISTINCT
                                           ';' + bp.DevelopmentCompanyName
                                    FROM dbo.mdm_Project ap
                                         LEFT JOIN dbo.p_DevelopmentCompany bp ON bp.DevelopmentCompanyGUID = ap.ProjCompanyGUID
                                    WHERE ap.ParentProjGUID = p.ProjGUID
                                    FOR XML PATH('')
                                ),
                                1,
                                1,
                                ''
                                     ),
                                pj.DevelopmentCompanyName
                            ),
               hbxmmc.LbProjectValue 合并项目名称,
               hbxmtgdm.LbProjectValue 合并项目代码,
               ---如下是新增加的字段
               lb1.LbProjectValue 是否开发受限项目,
               lb2.LbProjectValue 是否合作受阻项目,
               lb3.LbProjectValue 是否待返还资金项目,
               zjm.住宅类产品可售面积/10000.0 住宅类产品可售面积,
               zjm.商办类产品可售面积/10000.0 商办类产品可售面积,
               s.yjkgdate 预计首期开工时间,
               s.yjskdate 预计首推时间,
               s.yjjgdate 预计首批竣工时间,
               s.yjfinishdate 预计首批完工交付时间,
               s.dtzzdsmj / 10000 动态住宅待售面积,
               s.dtzzdsje / 10000 动态住宅待售金额,
               s.dtsbdsmj / 10000 动态商办待售面积,
               s.dtsbdsje / 10000 动态商办待售金额,
               lrr.总投资 * 10000 总投资,
               lrr.税后现金利润 * 10000 税后现金利润,
               lrr.税后现金利润不含所得税 * 10000 税后净现金,
               lrr.固定资产 * 10000 固定资产,
               f08.总成本含税计划,
               f08.资本化利息,
               f08.财务费用计划,
               f08.税前利润账面,
               CASE
                   WHEN (f08.总成本含税计划 - f08.财务费用计划 + f08.资本化利息) <> 0 THEN
                        f08.税前利润账面 / (f08.总成本含税计划 - f08.财务费用计划 + f08.资本化利息)
               END 结转口径税前成本利润率,
               f06.税前利润计划,
               f06.税后利润计划,
               f06.反算税前成本利润率,
               lb4.LbProjectValue 城市能级,
               lb5.LbProjectValue 版块能级,
               s.ysmj / 10000 累计已售面积,
               s.FcwYsmj / 10000 除地下室已售面积,
               s.ysje / 10000 累计已售金额,
               s.FcwYsJe / 10000 除地下室已售金额,
               s.zksmj / 10000 总货量,
               lb6.LbProjectValue 项目五分类,
               lb7.LbProjectValue 城市六分化,
               p.kgcpf 客关操盘方,
               isnull(ov.已完成产值金额,0)-isnull(ov.累计支付金额,0) 产值未付,
               isnull(tgmj.计划组团建筑面积,0) 停工面积,
               zjfx.LbProjectValue 是否资金风险类项目,
               zs.自持面积,
               zs.住宅类产品自持面积,
               zs.商办类产品自持面积,
               s.预计整体竣工时间,
               s.实际整体竣工时间,
               dss.开发贷余额,
               dss.供应链余额,
               isnull(jzcb.TotalMoney,0) 累计结转成本,
               ov.已完成产值金额,
               ov.合同约定应付金额,
               ov.累计支付金额,
               ov.应付未付,
               gd.股东投入余额,
               jhx.期末账面资金余额 账面资金余额,
               jhx.期末监管资金余额 监管资金余额,
               null 未售部分占压投资,
               f08.销售收入含税 as 盈利规划预计总货值,
               s.暂不开发可售货值/ 10000.0 as 暂不开发可售货值,
               s.暂不开发类待售货值/ 10000.0 as 暂不开发类待售货值,
               s.住宅类暂不开发类待售货值/ 10000.0 as 住宅类暂不开发类待售货值,
               s.商办类类暂不开发类待售货值/ 10000.0 as 商办类类暂不开发类待售货值,
               zjm.暂不开发可售面积/10000.0 as 暂不开发可售面积,
               zjm.住宅类产品暂不开发可售面积/10000.0 as 住宅类产品暂不开发可售面积,
               zjm.商办类产品暂不开发可售面积/10000.0 as 商办类产品暂不开发可售面积,
               dwsale.定位总可售面积/10000.0 as 定位总可售面积
        FROM #p p
             LEFT JOIN #gq gq ON p.projguid = gq.projguid
             left join #zs_area zs on p.projguid = zs.projguid
             LEFT JOIN
             (
                 SELECT projguid,
                        总投资,
                        税后现金利润,
                        税后现金利润不含所得税,
                        固定资产
                 FROM vhighdata_ProjProfit
             ) lrr ON p.projguid = lrr.projguid
             LEFT JOIN mdm_LbProject hbxmmc ON hbxmmc.projguid = p.projguid
                                               AND hbxmmc.LbProject = 'hbxmmc'
             LEFT JOIN mdm_LbProject hbxmtgdm ON hbxmtgdm.projguid = p.projguid
                                                 AND hbxmtgdm.LbProject = 'hbxmtgdm'
             LEFT JOIN mdm_LbProject lb ON lb.projguid = p.projguid
                                           AND lb.LbProject = 'tgid'
             LEFT JOIN mdm_LbProject lb1 ON lb1.projguid = p.projguid
                                            AND lb1.LbProject = 'kfsx'
             LEFT JOIN mdm_LbProject lb2 ON lb2.projguid = p.projguid
                                            AND lb2.LbProject = 'hzsx'
             LEFT JOIN mdm_LbProject lb3 ON lb3.projguid = p.projguid
                                            AND lb3.LbProject = 'dfhzj'
             LEFT JOIN mdm_LbProject lb4 ON lb4.projguid = p.projguid
                                            AND lb4.LbProject = 'csnj'
             LEFT JOIN mdm_LbProject lb5 ON lb5.projguid = p.projguid
                                            AND lb5.LbProject = 'bknj'
             LEFT JOIN mdm_LbProject lb6 ON lb6.projguid = p.projguid
                                            AND lb6.LbProject = 'xmwfl'
             LEFT JOIN mdm_LbProject lb7 ON lb7.projguid = p.projguid
                                            AND lb7.LbProject = 'cslfh'
             LEFT JOIN mdm_LbProject qs ON qs.projguid = p.projguid
                                           AND qs.LbProject = 'sfqs'
             LEFT JOIN mdm_LbProject tj ON tj.projguid = p.projguid
                                           AND tj.LbProject = 'sfnrtj'
             LEFT JOIN dbo.myBizParamOption city ON city.ParamName = 'td_city'
                                                    AND city.ParamGUID = p.CityGUID
             LEFT JOIN dbo.myBizParamOption area ON area.ParamName = 'td_city'
                                                    AND area.ParamGUID = p.BelongAreaGUID
             LEFT JOIN dbo.p_DevelopmentCompany dv ON dv.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
             LEFT JOIN dbo.vmd_Project352_YP md ON md.projguid = p.projguid
             LEFT JOIN #zjm zjm ON p.projguid = zjm.projguid
             LEFT JOIN
             (
                 SELECT p1.ProjGUID,
                        SUM(   CASE
                                   WHEN gc.BldStatus IN ( '在建', '已完工' ) THEN
                                        ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)
                               END
                           ) ljkgArea,
                        SUM(   CASE
                                   WHEN gc.BldStatus IN ( '在建', '已完工' ) THEN
                                        ISNULL(gc.UpBuildArea, 0)
                               END
                           ) ljdskgArea,
                        SUM(   CASE
                                   WHEN gc.BldStatus IN ( '已完工' ) THEN
                                        ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)
                               END
                           ) ljjgArea,
                        SUM(   CASE
                                   WHEN gc.BldStatus IN ( '已完工' ) THEN
                                        ISNULL(gc.UpBuildArea, 0)
                               END
                           ) ljdsjgArea,
                        SUM(   CASE
                                   WHEN gc.BldStatus IN ( '在建' ) THEN
                                        ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)
                               END
                           ) zjArea
                 FROM dbo.mdm_GCBuild gc
                      INNER JOIN mdm_Project mp ON mp.ProjGUID = gc.ProjGUID
                      INNER JOIN #p p1 ON mp.ParentProjGUID = p1.ProjGUID
                 GROUP BY p1.ProjGUID
             ) kg ON kg.projguid = p.projguid
             LEFT JOIN #lddbamj s ON s.projguid = p.projguid
             --首开
             LEFT JOIN
             (
                 SELECT mp.ProjGUID,
                        MIN(o.ThDate) skdate
                 FROM dbo.p_room o
                      INNER JOIN dbo.p_Project p ON p.ProjGUID = o.ProjGUID
                      INNER JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
                      INNER JOIN #p mp ON p1.ProjGUID = ISNULL(mp.ImportSaleProjGUID, mp.ProjGUID) 
                 GROUP BY mp.ProjGUID
             ) sk ON sk.projguid = p.projguid
             LEFT JOIN
             (
                 SELECT p.ProjGUID,
                        SUM(sa.累计认购面价) / 10000 累计认购面积,
                        SUM(sa.累计认购金额) 累计认购金额,
                        SUM(sa.累计签约面积) / 10000 累计签约面积,
                        SUM(   CASE
                                   WHEN sa.产品类型 = '地下室/车库' THEN
                                        0
                                   ELSE sa.累计签约面积
                               END
                           ) / 10000 除地下室签约面积,
                        SUM(sa.累计签约金额) 累计签约金额,
                        SUM(   CASE
                                   WHEN sa.产品类型 = '地下室/车库' THEN
                                        0
                                   ELSE sa.累计签约金额
                               END
                           ) 除地下室签约金额
                 FROM dbo.S_08ZYXSQYJB_HHZTSYJ sa
                      INNER JOIN #p p ON sa.项目代码 = p.ProjCode
                 WHERE DATEDIFF(DAY, sa.qxDate, GETDATE()) = 0
                 GROUP BY p.ProjGUID
             ) rgqy ON rgqy.projguid = p.projguid
             ---表七
             LEFT JOIN
             (
                 SELECT p.ProjGUID,
                        a.[累计回笼（万元）],
                        a.[累计总投资（万元）],
                        a.[累计直接投资其中土地费用（万元）],
                        a.[累计直接投资（万元）] - a.[累计直接投资其中土地费用（万元）] 除地价外直接投资,
                        a.[累计税金（万元）],
                        a.[贷款余额（万元）],
                        a.[累计结转面积（平方米）],
                        a.[累计结转收入（万元）],
                        a.[累计回笼（万元）] - a.[累计税金（万元）] - a.[累计总投资（万元）] 经营性现金流,
                        a.[累计回笼（万元）] + a.[贷款余额（万元）] - a.[累计税金（万元）] - a.[累计总投资（万元）] 收回股东投资,
                        a.[开发贷款余额（万元）] as 开发贷余额,
                        a.[供应链融资余额（万元）] as 供应链余额
                 FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a
                      INNER JOIN #p p ON a.BusinessGUID = p.ProjGUID
                      INNER JOIN
                      (
                          SELECT TOP 1
                                 a.FillHistoryGUID
                          FROM dss.dbo.[nmap_F_各项目投资、结转、回笼、贷款情况月报表] a
                               INNER JOIN dss.dbo.nmap_F_FillHistory b ON a.FillHistoryGUID = b.FillHistoryGUID
                          WHERE b.ApproveStatus = '已审核'
                          ORDER BY b.BeginDate DESC
                      ) F ON F.FillHistoryGUID = a.FillHistoryGUID
             ) dss ON dss.projguid = p.projguid
             LEFT JOIN mdm_ProjTimeIndex t ON t.projguid = p.projguid
             LEFT JOIN dbo.mdm_ProjLxDWDeviation hd ON hd.projguid = p.projguid
             LEFT JOIN vhighdata_ProjProfit pro ON pro.projguid = p.projguid
             LEFT JOIN dbo.p_DevelopmentCompany pj ON p.ProjCompanyGUID = pj.DevelopmentCompanyGUID
             LEFT JOIN #f08 f08 ON f08.projguid = p.projguid
             LEFT JOIN #f06 f06 ON f06.projguid = p.projguid
             LEFT JOIN #tgmj tgmj ON tgmj.投管项目编码 = p.projcode
             LEFT JOIN mdm_LbProject zjfx ON zjfx.projguid = p.projguid
                                             AND zjfx.LbProject = 'zjfx'
             LEFT JOIN #Jzcb jzcb ON jzcb.projguid = p.projguid
             left join #jhx jhx on jhx.projguid = p.projguid
             left join #gd gd on gd.项目GUID = p.projguid
             left join #OutputValue ov on ov.projguid = p.projguid
             left join #hzf hzf on hzf.projguid = p.projguid
             left join #bbf bbf on bbf.projguid = p.projguid 
             left join #dw_salearea dwsale on dwsale.projguid = p.projguid
			 order by 公司名称

        DROP TABLE #p,
                   #f08,
                   #f06,
                   #gq,
                   #zjm,
                   #tgmj,
                   #OutputValue,
                   #jhx,
                   #gd,
                   #Jzcb;
    END;
END; 


