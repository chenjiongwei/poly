USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_集团止巨亏智能数据提取]    Script Date: 2025/8/22 10:39:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[usp_s_集团止巨亏智能数据提取] as 
begin 
/*
用途：用于给集团AI助手调用取数的
时间：20250421
清洗作业：[集团止巨亏数据提取]
清洗频率：按天清洗，保留最近一个月的版本
*/
    -- 设置变量
    declare @bn int = year(getdate())
    declare @mn int = year(getdate())+1

    -- 预处理盈利规划现金流的数据
    SELECT 
        pj.ProjGUID,
        LEFT(年, 4) AS 年,
        报表预测项目科目,
        SUM(CONVERT(DECIMAL(16, 2), value_string)) AS value_string
    INTO #ylgh_xjl
    FROM data_wide_qt_f080005 b
    INNER JOIN data_wide_dws_ys_ProjGUID pj 
        ON b.实体分期 = pj.YLGHProjGUID 
        AND pj.Level = 3 
        AND pj.isbase = 1 
        AND pj.BusinessEdition = b.版本
        AND LEFT(年, 4) BETWEEN @bn AND @mn
        AND CHARINDEX('不区分年', 年) = 0 
        AND CHARINDEX('e', value_string) = 0
        AND b.报表预测项目科目 IN (
            '销售回款',
            '其他经营收入',
            '新增贷款',
            '土地费用',
            '除地价外直投（含税）',
            '销售费用',
            '管理费用-协议口径（含税）',
            '缴纳营业税',
            '缴纳增值税',
            '缴纳城建税及教育费附加',
            '缴纳土地增值税',
            '缴纳企业所得税',
            '缴纳印花税',
            '缴纳其他税费',
            '贷款利息',
            '支出调整项',
            '偿还本金',
            '经营性现金流量',
            '自有资金现金流量',
            '股东投入余额（不计息）',
            '76983',
            '股东投入余额（计息）'
        )
    GROUP BY 
        pj.ProjGUID,
        LEFT(年, 4),
        报表预测项目科目;

    --预处理盈利规划净利率的数据
    --预处理盈利规划净利率的数据
    select pj.ProjGUID, 报表预测项目科目, yt.topproducttype, 
    sum(convert(decimal(16,2),value_string)) as value_string
    into #ylgh_lv
    from data_wide_qt_F08000202 b
    inner join data_wide_dws_ys_ProjGUID pj on b.实体分期 = pj.YLGHProjGUID 
    and pj.Level = 3 and pj.isbase = 1 and pj.BusinessEdition = b.版本 
    left join data_wide_dws_ys_SumProjProductYt yt on b.业态 = yt.YtName  and b.实体分期 = yt.ProjGUID and yt.IsBase = 1
    where  期间='全周期' and charindex('e',value_string) =  0
    and b.报表预测项目科目 in ('计划净利润（减股权溢价减土增税）','销售收入(不含税）') 
    and  left(年,4) =@bn
    group by pj.ProjGUID,报表预测项目科目,topproducttype;

    --预处理盈利规划签约数据
    select  pj.ProjGUID,left(年,4) as 年,sum(convert(decimal(16,2),value_string)) as 签约金额
    into #ylgh_qy
    from data_wide_qt_F09000501 b
    inner join data_wide_dws_ys_ProjGUID pj on b.实体分期 = pj.YLGHProjGUID 
    and pj.Level = 3 and pj.isbase = 1 and pj.edition = b.版本 
    where 报表预测公司科目='签约金额（全口径）' --and 实体分期 = '0419AF39-AFB2-EF11-B3A5-F40270D39969'
    and left(年,4)  between @bn  and @mn
    and charindex('e',value_string) =  0
    group by  pj.ProjGUID,left(年,4);

    --获取合作方简称       
    /*  
    select STRING_AGG(hzf.Partners,';') as Partners,p.ProjGUID
    into #hzf
    from [172.16.4.141].erp25.dbo.mdm_project p
    cross apply (select value from fn_Split2(PartnerGUID,';'))t 
    inner join [172.16.4.141].erp25.dbo.p_DevelopmentCompany hzf on hzf.DevelopmentCompanyGUID = t.Value and isnull(t.Value,'')<>''       
    group by p.ProjGUID
    */

    SELECT 
        p.ProjGUID,
        STRING_AGG(isnull(ssssssss.Collaborator,isnull(sssssss.Collaborator,isnull(ssssss.Collaborator,isnull(sssss.Collaborator,isnull(ssss.Collaborator,isnull(sss.Collaborator,isnull(ss.Collaborator,s.Collaborator))))))),'、') as Partners
    into #hzf
    FROM [172.16.4.141].erp25.dbo.mdm_project p
    INNER JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany c on p.ProjCompanyGUID = c.DevelopmentCompanyGUID
    INNER JOIN [172.16.4.141].erp25.dbo.p_Shareholder s ON s.DevelopmentCompanyGUID = c.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany cc ON s.ShareholderGUID = cc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_Shareholder ss ON ss.DevelopmentCompanyGUID = cc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany ccc on ccc.DevelopmentCompanyGUID = ss.ShareholderGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_Shareholder sss ON sss.DevelopmentCompanyGUID = ccc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany cccc on cccc.DevelopmentCompanyGUID = sss.ShareholderGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_Shareholder ssss ON ssss.DevelopmentCompanyGUID = cccc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany ccccc on ccccc.DevelopmentCompanyGUID = ssss.ShareholderGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_Shareholder sssss ON sssss.DevelopmentCompanyGUID = ccccc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany cccccc on cccccc.DevelopmentCompanyGUID = sssss.ShareholderGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_Shareholder ssssss ON ssssss.DevelopmentCompanyGUID = cccccc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany ccccccc on ccccccc.DevelopmentCompanyGUID = ssssss.ShareholderGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_Shareholder sssssss ON sssssss.DevelopmentCompanyGUID = ccccccc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany cccccccc on cccccccc.DevelopmentCompanyGUID = sssssss.ShareholderGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_Shareholder ssssssss ON ssssssss.DevelopmentCompanyGUID = cccccccc.DevelopmentCompanyGUID
    LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany ccccccccc on ccccccccc.DevelopmentCompanyGUID = ssssssss.ShareholderGUID
    WHERE ISNULL(ccc.DevelopmentCompanyName,'') <> '保利发展控股集团股份有限公司'
    AND ISNULL(cccc.DevelopmentCompanyName,'') <> '保利发展控股集团股份有限公司'
    AND ISNULL(ccccc.DevelopmentCompanyName,'') <> '保利发展控股集团股份有限公司'
    AND ISNULL(cccccc.DevelopmentCompanyName,'') <> '保利发展控股集团股份有限公司'
    AND ISNULL(ccccccc.DevelopmentCompanyName,'') <> '保利发展控股集团股份有限公司'
    AND ISNULL(cccccccc.DevelopmentCompanyName,'') <> '保利发展控股集团股份有限公司'
    AND ISNULL(ccccccccc.DevelopmentCompanyName,'') <> '保利发展控股集团股份有限公司'
    GROUP BY p.ProjGUID;


    select ProjGUID, STRING_AGG(CASE WHEN ShareRate = 100 THEN ShareholderName + ':' + CONVERT(VARCHAR(200), CONVERT(DECIMAL(18, 2), ROUND(ShareRate * 1.0, 2)))
    ELSE ShareholderName + ':'  + CONVERT(VARCHAR(200), CONVERT(DECIMAL(18, 2), ROUND(ShareRate * 1.0, 2))) END,';') as GQRatio
    into #gq 
    from data_wide_s_ProjShareholder
    group by ProjGUID ;   


    --账面资金余额清洗数据（t+1） 监管资金余额
    --取数来源参考 项目总屏-项目经营分析_V3.0的同名指标
    -- 取余额的时候，是按项目公司取的，所以要加几个判断因素：
    -- 1、先看项目对应的项目公司（如果一个项目对照多个项目公司，则多个都要取过来）
    -- 2、把对应项目公司的所有户都归到这个项目上，不管是否有投管代码
    -- 3、监管户按照监管户的数据到每个项目去，其他户的话，按照一个规则全部归到某个项目去：
    -- 目前的规则是：比较这几个项目当年回笼金额，直接归到回笼最高的项目中

    --取资金表的最新同步日期
    select max(business_date) as business_date 
    into #d_date
    from data_wide_dws_qt_fund_detail
    where  balance >0

    --缓存项目公司跟项目的映射情况 
    select cltProjectCode,cltProjectName,project_company,TgProjCode my_tgprojcode,ProjGUID,account_nature,capital_nature,balance
    into #dw_proj_com
    from data_wide_dws_qt_fund_detail t
    left join data_wide_dws_mdm_project pj on (pj.TgProjCode = t.cltProjectCode or cltProjectName = projname)  and pj.level = 2
    inner join #d_date dd on 1=1
    where datediff(dd,t.business_date,dd.business_date) = 0

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
    from dw_f_TopProject_getin
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

    select pj.ProjGUID,pj.ProjName,pj.TgProjCode, pj.level,sum(t.期末监管资金余额) as 监管资金余额,sum(t.期末账面资金余额) as 期末账面资金余额
    into #jhx
    from #tmp_result t
    inner join data_wide_dws_mdm_Project pj on t.ProjGUID = pj.ProjGUID
    group by pj.ProjGUID,pj.ProjName,pj.TgProjCode,pj.Level

    drop table #d_date,#com_proj,#dw_proj_com,#hl,#tmp_result,#proj_num,#zj

    -------------------结束账面资金、监管资金余额的取数

    --本年累计直投支付:成本系统除地价外直投对应合同的付款
    --本年累计直投支付-开始取数
    select
        pj.ParentGUID as ProjGUID,
        sum(本年实付金额) as 本年累计直投支付
    into #bnztzf
    from data_wide_dws_cb_CostStructureReport r
    inner join data_wide_dws_mdm_Project pj on r.项目GUID = pj.ProjGUID
    group by pj.ParentGUID

    --本年累计直投支付-结束取数

    --流出2： 本年贷款待还款计划数:原取自盈利规划，拟改取明源数仓NC数据，按年汇总
    SELECT dd.ProjGUID,
        dd.ProjName AS 项目名称,
        dd.Year AS 年份,
        sum(isnull(YearInvestmentAmount,0)) 本年总投资金额,
        sum(isnull(YearTax,0)) 本年税金, 
        sum(isnull(YearNetIncreaseLoan,0)) 本年净增贷款,
        sum(isnull(InvestmentAmountTotal,0)) 累计总投资金额,
        sum(isnull(TaxTotal,0)) 累计税金, 
        sum(isnull(LoanBalanceTotal,0)) 累计贷款余额,
        sum(isnull(DevelopmentLoans,0)) as 开发贷款余额,
        null as 供应链融资余额
    INTO #bndkhkjh
    FROM data_wide_dws_ys_ys_DssCashFlowData dd
    WHERE dd.Year = Year(getdate())
    group by dd.ProjGUID,dd.ProjName,dd.Year

    --流出3： 本年供应链待还款计划数
    select
        pj.ParentGUID as ProjGUID,
        sum(dfamount) as 本年供应链待还款计划数
    into #gyl
    from data_wide_dws_cb_BLFKApply r
    inner join data_wide_dws_mdm_Project pj on r.ProjGUID = pj.ProjGUID
    group by pj.ParentGUID

    --2、 本年累计土地款支付 :成本系统本年截止统计期末土地类合同支付金额
    select 
        pj.ParentGUID as ProjGUID,
        sum(CurYearPayAmount) as 本年累计土地款支付
    into #tdkzf
    from data_wide_dws_cb_tdhtjsf td
    inner join data_wide_dws_mdm_Project pj on td.ProjGUID = pj.ProjGUID
    group by pj.ParentGUID  
    /*
    SELECT p.buguid, p.ProjGUID,p.ProjName,c.ContractCode,c.ContractName,c.TotalAmount,
        SUM(e.PayAmount) AS PayAmount,
        SUM(case when year(e.PayDate) = year(getdate()) then e.PayAmount else 0 end) as CurYearPayAmount
    FROM MyCost_Erp352.dbo.cb_htfkapply a
    LEFT JOIN MyCost_Erp352.dbo.cb_pay e ON e.htfkapplyGUID = a.htfkapplyGUID
    INNER JOIN MyCost_Erp352.dbo.cb_contract c ON a.ContractGUID = c.ContractGUID
    LEFT JOIN MyCost_Erp352.dbo.p_Project p ON p.ProjCode = CASE WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) < 1 THEN c.ProjectCodeList
                                                WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) >= 1 THEN LEFT(ProjectCodeList, CHARINDEX(';', c.ProjectCodeList) - 1)
                                                ELSE NULL END
    WHERE a.ApplyState = '已审核'
        AND (
                c.HtTypeCode LIKE '01%'
            )
        AND c.IfDdhs=1
        AND c.IsFyControl = 0
        AND c.htclass NOT LIKE '%非合同%'
    group by p.buguid,p.ProjGUID,p.ProjName,c.ContractCode,c.ContractName,c.TotalAmount
    */

    --流入1：本年已销售待回款:取自明源系统供款表信息，与盈利规划取数逻辑一致
    --公司房款一览表 data_wide_dws_s_gsfkylbhzb
    select 
        TopProjGUID as ProjGUID,
        sum(isnull(本年签约金额,0))-sum(isnull(本年签约本年回笼回笼合计,0)) as 本年已销售待回款
    into #bndhl
    from data_wide_dws_s_gsfkylbhzb
    where DATEDIFF(DAY, qxDate, getdate()) = 0
    group by TopProjGUID

    --截止目前股东合作方投入余额:DSS填报表bc001
    --股东投入余额
    select p.项目guid as ProjGUID,
        sum(isnull(截止目前股东合作方投入余额C,0))  as 截止目前股东合作方投入余额
    into #gd
    from data_wide_dws_qt_Shareholder_investment t with (nolock)
    inner join data_wide_ys_nmap_F_FillHistory fill with (nolock) on t.[FillHistoryGUID] = fill.[FillHistoryGUID]
    inner join dw_d_topproject p on p.投管明源系统项目代码 = t.明源代码
    inner join (
    select  max(BeginDate) as BeginDate
    from data_wide_dws_qt_Shareholder_investment t with (nolock)
    inner join data_wide_ys_nmap_F_FillHistory fill with (nolock) on t.[FillHistoryGUID] = fill.[FillHistoryGUID]
    where 截止目前股东合作方投入余额C > 0
    ) tt on datediff(dd,tt.BeginDate,fill.begindate) = 0
    group by p.项目guid

    --f5603占压资金按项目合计:明源数据接口，更新F05603里开发受限、已投资未落实的占压资金
    select 
        pj.ParentGUID as ProjGUID,
        sum(isnull(zyzj.占压资金_全口径,0)+isnull(zyzj.已投资未落实_占压资金_全口径,0)+isnull(zyzj.开发受限_占压资金_并表口径,0)) as 占压资金  
    into #zyzj
    from data_wide_dws_s_资源情况 zyzj
    inner join data_wide_dws_mdm_Project pj on zyzj.ProjGUID = pj.ProjGUID
    group by pj.ParentGUID

    --f05401“物业操盘方”:明源数据接口 --已取
    --销售系统各产品未售套数:明源数据接口 -已取
    --f05601月均去化流速:明源数据接口，F05601增加近六月签约套数
    select 
        项目guid as ProjGUID,
        sum(近六月签约套数)/6 as 月均去化流速
    into #yjqhls
    from data_wide_dws_s_product_salevalue
    WHERE DATEDIFF(mm, 月份, GETDATE()) = 0
    group by 项目guid;
    --f05601去化周期:明源数据接口，F05601 剩余套数/月均去化流速(套数)



    with proj as (
        select do.DevelopmentCompanyName 平台公司,
            pj.ProjCode_25 项目代码,
            pj.TgProjCode 投管代码,
            pj.ProjName 项目名,
            pj.spreadname 推广名,
            pj.XMHQFS 获取方式,
            pj.BeginDate 获取时间,
            pj.TotalLandPrice 获取总成本,
            pj.LMDJ 可售楼面价,
            gq.GQRatio 股权结构,
            pj.DiskType 操盘方式,
            pj.YXCpf 其中营销操盘方,
            pj.GenreTableType 并表方式,
            pj.EquityRatio 项目权益比率,
            hzf.Partners 合作方,
            pj.GQRatio 股权比例,
            pj.WYCpf 物业操盘方,
            pj.SaleStatus as 销售状态,
            pj.ManageModeName as 管理方式,    
            case when year(pj.BeginDate) >=2024 then '新增量'
                when year(pj.BeginDate) >=2022 and year(pj.BeginDate) < 2024 then '增量'
                else '存量' end as 项目类型,
            pj.City as 城市,
            pj.projguid 
        from data_wide_dws_mdm_Project pj 
        inner join data_wide_dws_s_Dimension_Organization do on do.OrgGUID = pj.BUGUID
        left join #gq gq on gq.projguid = pj.projguid
        left join #hzf hzf on hzf.projguid = pj.projguid
        where pj.level = 2
    ),
    hz as (
    select hz.项目GUID, 
        hz.动态总货量面积 总可售面积,
        hz.动态总货值金额 总可售货值,
        hz.住宅总可售面积,
        hz.住宅总可售货值,
        hz.商办总可售面积,
        hz.商办总可售货值,
        hz.车位总可售面积,
        hz.车位总可售货值,
        hz.动态未售货量面积 总未售面积,
        hz.动态未售货值金额 总未售货值,
        hz.住宅剩余可售面积 住宅总未售面积,
        hz.住宅剩余货值 住宅总未售货值,
        hz.商办剩余可售面积 商办总未售面积,
        hz.商办剩余货值 商办总未售货值,
        hz.车位剩余可售面积 车位总未售面积,
        hz.车位剩余货值 车位总未售货值,
        (hz.住宅剩余可售面积+hz.商办剩余可售面积+hz.车位剩余可售面积)-(hz.住宅剩余可售面积未开工+hz.商办剩余可售面积未开工+hz.车位剩余可售面积未开工) 已开工未售面积,
        (hz.住宅剩余货值+hz.商办剩余货值+hz.车位剩余货值)-(hz.住宅剩余货值未开工+hz.商办剩余货值未开工+hz.车位剩余货值未开工) 已开工未售货值,
        hz.住宅剩余可售面积-hz.住宅剩余可售面积未开工 住宅已开工未售面积,
        hz.住宅剩余货值-hz.住宅剩余货值未开工 住宅已开工未售货值,
        hz.商办剩余可售面积-hz.商办剩余可售面积未开工 商办已开工未售面积,
        hz.商办剩余货值-hz.商办剩余货值未开工 商办已开工未售货值,
        hz.车位剩余可售面积-hz.车位剩余可售面积未开工 车位已开工未售面积,
        hz.车位剩余货值-hz.车位剩余货值未开工 车位已开工未售货值,
        hz.住宅剩余可售面积产成品+hz.商办剩余可售面积产成品+hz.车位剩余可售面积产成品 产成品面积,
        hz.住宅剩余货值产成品+hz.商办剩余货值产成品+hz.车位剩余货值产成品 产成品金额,
        hz.住宅剩余可售面积产成品 住宅产成品面积,
        hz.住宅剩余货值产成品 住宅产成品金额,
        hz.商办剩余可售面积产成品 商办产成品面积,
        hz.商办剩余货值产成品 商办产成品金额,
        hz.车位剩余可售面积产成品 车位产成品面积,
        hz.车位剩余货值产成品 车位产成品金额,
        hz.住宅准产成品面积+hz.商办准产成品面积+hz.车位准产成品面积 as  准产成品面积,
        hz.住宅准产成品金额+hz.商办准产成品金额+hz.车位准产成品金额 准产成品金额,
        hz.住宅准产成品面积 住宅准产成品面积,
        hz.住宅准产成品金额 住宅准产成品金额,
        hz.商办准产成品面积 商办准产成品面积,
        hz.商办准产成品金额 商办准产成品金额,
        hz.车位准产成品面积 车位准产成品面积,
        hz.车位准产成品金额 车位准产成品金额,
        hz.住宅未卖散楼栋产成品面积+hz.商办未卖散楼栋产成品面积 未卖散楼栋产成品面积,
        hz.住宅未卖散楼栋产成品金额+hz.商办未卖散楼栋产成品金额 未卖散楼栋产成品金额,
        hz.住宅未卖散楼栋产成品面积 住宅未卖散楼栋产成品面积,
        hz.住宅未卖散楼栋产成品金额 住宅未卖散楼栋产成品金额,
        hz.商办未卖散楼栋产成品面积 商办未卖散楼栋产成品面积,
        hz.商办未卖散楼栋产成品金额 商办未卖散楼栋产成品金额,
        hz.住宅剩余可售套数 住宅剩余可售套数,
        hz.商办剩余可售套数 商办剩余可售套数,
        hz.车位剩余可售个数 车位剩余可售个数,
        hz.住宅剩余可售套数+hz.商办剩余可售套数+hz.车位剩余可售个数 as 剩余可售套数,
        hz.住宅剩余可售套数 - hz.住宅剩余可售个数未开工 as 住宅已开工未售套数
    from dw_f_TopProject_SaleValue hz 
    
    ),
    m002_qn as (
        select t.*,
        case when 去年住宅签约金额不含税 = 0 then 0 else 去年住宅净利润/去年住宅签约金额不含税 end 去年住宅净利率,
        case when 去年商办签约金额不含税 = 0 then 0 else 去年商办净利润/去年商办签约金额不含税 end 去年商办净利率,
        case when 去年车位签约金额不含税 = 0 then 0 else 去年车位净利润/去年车位签约金额不含税 end 去年车位净利率
        from (
            select a.ProjGUID,
                sum(case when 产品类型 in ('住宅', '高级住宅', '别墅') then 净利润签约 else 0 end)  去年住宅净利润,
                sum(case when 产品类型 not in ('住宅', '高级住宅', '别墅','地下室/车库') then 净利润签约 else 0 end) 去年商办净利润,
                sum(case when 产品类型 in ('地下室/车库') then 净利润签约 else 0 end) 去年车位净利润,
                sum(case when 产品类型 in ('住宅', '高级住宅', '别墅') then 当期签约金额不含税 else 0 end)  去年住宅签约金额不含税,
                sum(case when 产品类型 not in ('住宅', '高级住宅', '别墅','地下室/车库') then 当期签约金额不含税 else 0 end) 去年商办签约金额不含税,
                sum(case when 产品类型 in ('地下室/车库') then 当期签约金额不含税 else 0 end) 去年车位签约金额不含税
            from data_wide_dws_qt_M002项目业态级毛利净利表 a
            where year(StartTime) = year(GETDATE())-1 and MONTH(StartTime) = 12  and versionType = '拍照版'
            group by a.ProjGUID) t
    ),
    m002_bn as (
        select t.*,
        case when 本年住宅签约金额不含税 = 0 then 0 else 本年住宅净利润/本年住宅签约金额不含税 end 本年住宅净利率,
        case when 本年商办签约金额不含税 = 0 then 0 else 本年商办净利润/本年商办签约金额不含税 end 本年商办净利率,
        case when 本年车位签约金额不含税 = 0 then 0 else 本年车位净利润/本年车位签约金额不含税 end 本年车位净利率,
        case when 本年住宅签约金额不含税 = 0 then 0 else 本年住宅毛利/本年住宅签约金额不含税   end 本年住宅毛利率,
        case when 本年商办签约金额不含税 = 0 then 0 else 本年商办毛利/本年商办签约金额不含税   end 本年商办毛利率,
        case when 本年车位签约金额不含税 = 0 then 0 else 本年车位毛利/本年车位签约金额不含税   end 本年车位毛利率
        from (
            select a.ProjGUID,
                sum(case when 产品类型 in ('住宅', '高级住宅', '别墅') then 净利润签约 else 0 end)  本年住宅净利润,
                sum(case when 产品类型 not in ('住宅', '高级住宅', '别墅','地下室/车库') then 净利润签约 else 0 end) 本年商办净利润,
                sum(case when 产品类型 in ('地下室/车库') then 净利润签约 else 0 end) 本年车位净利润,
                sum(case when 产品类型 in ('住宅', '高级住宅', '别墅') then 毛利签约 else 0 end)  本年住宅毛利,
                sum(case when 产品类型 not in ('住宅', '高级住宅', '别墅','地下室/车库') then 毛利签约 else 0 end) 本年商办毛利,
                sum(case when 产品类型 in ('地下室/车库') then 毛利签约 else 0 end) 本年车位毛利,
                sum(case when 产品类型 in ('住宅', '高级住宅', '别墅') then 当期签约金额不含税 else 0 end)  本年住宅签约金额不含税,
                sum(case when 产品类型 not in ('住宅', '高级住宅', '别墅','地下室/车库') then 当期签约金额不含税 else 0 end) 本年商办签约金额不含税,
                sum(case when 产品类型 in ('地下室/车库') then 当期签约金额不含税 else 0 end) 本年车位签约金额不含税
            from data_wide_dws_qt_M002项目业态级毛利净利表 a
            where year(StartTime) = year(GETDATE())  and versionType = '本年版'
            group by a.ProjGUID) t
    ),
    ylgh_jlv_bn as (
        select projguid,
        case when 本年住宅签约金额不含税 = 0 then 0 else 本年住宅净利润/本年住宅签约金额不含税 end 本年住宅净利率,
        case when 本年商办签约金额不含税 = 0 then 0 else 本年商办净利润/本年商办签约金额不含税 end 本年商办净利率,
        case when 本年车位签约金额不含税 = 0 then 0 else 本年车位净利润/本年车位签约金额不含税 end 本年车位净利率
        from (
            select ProjGUID,
                sum(case when topproducttype in ('住宅', '高级住宅', '别墅') and 报表预测项目科目 = '计划净利润（减股权溢价减土增税）' then value_string else 0 end)  本年住宅净利润,
                sum(case when topproducttype not in ('住宅', '高级住宅', '别墅','地下室/车库') and 报表预测项目科目 = '计划净利润（减股权溢价减土增税）' then value_string else 0 end) 本年商办净利润,
                sum(case when topproducttype in ('地下室/车库') and 报表预测项目科目 = '计划净利润（减股权溢价减土增税）' then value_string else 0 end) 本年车位净利润,
                sum(case when topproducttype in ('住宅', '高级住宅', '别墅') and 报表预测项目科目 = '销售收入(不含税）' then value_string else 0 end)  本年住宅签约金额不含税,
                sum(case when topproducttype not in ('住宅', '高级住宅', '别墅','地下室/车库') and 报表预测项目科目 = '销售收入(不含税）' then value_string else 0 end) 本年商办签约金额不含税,
                sum(case when topproducttype in ('地下室/车库')  and 报表预测项目科目 = '销售收入(不含税）' then value_string else 0 end) 本年车位签约金额不含税
            from #ylgh_lv
            group by ProjGUID 
        ) t
    ),
    ylgh_cashflow_bn as(
        select ProjGUID,
            --null 本年现金流入_签约,  
            sum(case when 报表预测项目科目 = '销售回款' then value_string else 0 end ) 本年现金流入_回款,  --销售回款
            sum(case when 报表预测项目科目 = '其他经营收入' then value_string else 0 end ) 本年现金流入_其他流入, --其他经营收入
            sum(case when 报表预测项目科目 = '新增贷款' then value_string else 0 end ) 本年现金流入_新增贷款, --新增贷款
            -- null 本年现金流入_新增供应链,跟新增贷款进行合并
            sum(case when 报表预测项目科目 = '土地费用' then value_string else 0 end ) 本年现金流出_土地款, --土地费用
            sum(case when 报表预测项目科目 = '除地价外直投（含税）' then value_string else 0 end ) 本年现金流出_地价外直投, --除地价外直投（含税）
            sum(case when 报表预测项目科目 = '销售费用' then value_string else 0 end ) 本年现金流出_营销费, --销售费用
            sum(case when 报表预测项目科目 = '管理费用-协议口径（含税）' then value_string else 0 end ) 本年现金流出_管理费, --管理费用-协议口径（含税）
            sum(case when 报表预测项目科目 in ('缴纳营业税','缴纳增值税','缴纳城建税及教育费附加','缴纳土地增值税','缴纳企业所得税','缴纳印花税','缴纳其他税费')  then value_string else 0 end ) 本年现金流出_支付税金, --经营税金：缴纳营业税、缴纳增值税、缴纳城建税及教育费附加、缴纳土地增值税、缴纳企业所得税、缴纳印花税、缴纳其他税费
            sum(case when 报表预测项目科目 = '贷款利息' then value_string else 0 end ) 本年现金流出_支付利息, --贷款利息
            sum(case when 报表预测项目科目 = '支出调整项' then value_string else 0 end ) 本年现金流出_其他支出, --支出调整项
            sum(case when 报表预测项目科目 = '偿还本金' then value_string else 0 end ) 本年现金流出_归还贷款, --偿还本金
            -- null 本年现金流出_归还供应链,跟归还贷款进行合并
            sum(case when 报表预测项目科目 = '经营性现金流量' then value_string else 0 end ) 本年当期经营现金流, --经营性现金流量
            sum(case when 报表预测项目科目 = '自有资金现金流量' then value_string else 0 end ) 本年当期现金流含融资, --自有资金现金流量
            sum(case when 报表预测项目科目 in ('股东投入余额（不计息）','76983','股东投入余额（计息）') then value_string else 0 end ) 本年期末净资金 --股东投入余额（不计息）+76983：股东投入余额（计息）
            -- null 本年期末净资金_其中可动用资金 --取不到
            from  #ylgh_xjl
            where 年 = @bn 
            group by ProjGUID
    ),
    ylgh_cashflow_mn as (
        select projguid,
            --null 明年现金流入_签约,
            sum(case when 报表预测项目科目 = '销售回款' then value_string else 0 end ) 明年现金流入_回款,  --销售回款
            sum(case when 报表预测项目科目 = '其他经营收入' then value_string else 0 end ) 明年现金流入_其他流入, --其他经营收入
            sum(case when 报表预测项目科目 = '新增贷款' then value_string else 0 end ) 明年现金流入_新增贷款, --新增贷款
            -- null 明年现金流入_新增供应链,跟新增贷款进行合并
            sum(case when 报表预测项目科目 = '土地费用' then value_string else 0 end ) 明年现金流出_土地款, --土地费用
            sum(case when 报表预测项目科目 = '除地价外直投（含税）' then value_string else 0 end ) 明年现金流出_地价外直投, --除地价外直投（含税）
            sum(case when 报表预测项目科目 = '销售费用' then value_string else 0 end ) 明年现金流出_营销费, --销售费用
            sum(case when 报表预测项目科目 = '管理费用-协议口径（含税）' then value_string else 0 end ) 明年现金流出_管理费, --管理费用-协议口径（含税）
            sum(case when 报表预测项目科目 in ('缴纳营业税','缴纳增值税','缴纳城建税及教育费附加','缴纳土地增值税','缴纳企业所得税','缴纳印花税','缴纳其他税费')  then value_string else 0 end ) 明年现金流出_支付税金, --经营税金：缴纳营业税、缴纳增值税、缴纳城建税及教育费附加、缴纳土地增值税、缴纳企业所得税、缴纳印花税、缴纳其他税费
            sum(case when 报表预测项目科目 = '贷款利息' then value_string else 0 end ) 明年现金流出_支付利息, --贷款利息
            sum(case when 报表预测项目科目 = '支出调整项' then value_string else 0 end ) 明年现金流出_其他支出, --支出调整项
            sum(case when 报表预测项目科目 = '偿还本金' then value_string else 0 end ) 明年现金流出_归还贷款, --偿还本金
            -- null 明年现金流出_归还供应链,跟归还贷款进行合并
            sum(case when 报表预测项目科目 = '经营性现金流量' then value_string else 0 end ) 明年当期经营现金流, --经营性现金流量
            sum(case when 报表预测项目科目 = '自有资金现金流量' then value_string else 0 end ) 明年当期现金流含融资, --自有资金现金流量
            sum(case when 报表预测项目科目 in ('股东投入余额（不计息）','76983','股东投入余额（计息）') then value_string else 0 end ) 明年期末净资金  --股东投入余额（不计息）+76983：股东投入余额（计息）
            -- null 明年期末净资金_其中可动用资金 --取不到
            from   #ylgh_xjl
            where 年 = @mn 
            group by ProjGUID
            
    )
    select 
        p.平台公司, 
        p.项目代码,
        p.投管代码,
        p.项目名,
        p.推广名,
        p.获取方式,
        p.获取时间,
        p.获取总成本,
        p.可售楼面价,
        p.股权结构,
        p.操盘方式,
        p.其中营销操盘方,
        p.并表方式,
        p.项目权益比率,
        hzf.Partners as 合作方,
        p.股权比例,
        hz.总可售面积,
        hz.总可售货值,
        hz.住宅总可售面积,
        hz.住宅总可售货值,
        hz.商办总可售面积,
        hz.商办总可售货值,
        hz.车位总可售面积,
        hz.车位总可售货值,
        hz.总未售面积,
        hz.总未售货值,
        hz.住宅总未售面积,
        hz.住宅总未售货值,
        hz.商办总未售面积,
        hz.商办总未售货值,
        hz.车位总未售面积,
        hz.车位总未售货值,
        hz.已开工未售面积,
        hz.已开工未售货值,
        hz.住宅已开工未售面积,
        hz.住宅已开工未售货值,
        hz.商办已开工未售面积,
        hz.商办已开工未售货值,
        hz.车位已开工未售面积,
        hz.车位已开工未售货值,
        hz.产成品面积,
        hz.产成品金额,
        hz.住宅产成品面积,
        hz.住宅产成品金额,
        hz.商办产成品面积,
        hz.商办产成品金额,
        hz.车位产成品面积,
        hz.车位产成品金额,
        hz.准产成品面积,
        hz.准产成品金额,
        hz.住宅准产成品面积,
        hz.住宅准产成品金额,
        hz.商办准产成品面积,
        hz.商办准产成品金额,
        hz.车位准产成品面积,
        hz.车位准产成品金额,
        hz.未卖散楼栋产成品面积,
        hz.未卖散楼栋产成品金额,
        hz.住宅未卖散楼栋产成品面积,
        hz.住宅未卖散楼栋产成品金额,
        hz.商办未卖散楼栋产成品面积,
        hz.商办未卖散楼栋产成品金额,
        mqn.去年住宅净利率,
        mqn.去年商办净利率,
        mqn.去年车位净利率,
        jlv.本年住宅净利率, 
        jlv.本年商办净利率, 
        jlv.本年车位净利率, 
        bnqy.签约金额 本年现金流入_签约, 
        bn.本年现金流入_回款, 
        bn.本年现金流入_其他流入, 
        bn.本年现金流入_新增贷款, 
        -- bn.本年现金流入_新增供应链, 
        bn.本年现金流出_土地款, 
        bn.本年现金流出_地价外直投, 
        bn.本年现金流出_营销费, 
        bn.本年现金流出_管理费, 
        bn.本年现金流出_支付税金, 
        bn.本年现金流出_支付利息, 
        bn.本年现金流出_其他支出, 
        bn.本年现金流出_归还贷款, 
        -- bn.本年现金流出_归还供应链, 
        bn.本年当期经营现金流, 
        bn.本年当期现金流含融资, 
        bn.本年期末净资金, 
        --bn.本年期末净资金_其中可动用资金,
        mnqy.签约金额 明年现金流入_签约,
        mn.明年现金流入_回款,
        mn.明年现金流入_其他流入,
        mn.明年现金流入_新增贷款,
        -- mn.明年现金流入_新增供应链,
        mn.明年现金流出_土地款,
        mn.明年现金流出_地价外直投,
        mn.明年现金流出_营销费,
        mn.明年现金流出_管理费,
        mn.明年现金流出_支付税金,
        mn.明年现金流出_支付利息,
        mn.明年现金流出_其他支出,
        mn.明年现金流出_归还贷款,
        -- mn.明年现金流出_归还供应链,
        mn.明年当期经营现金流,
        mn.明年当期现金流含融资,
        mn.明年期末净资金 ,
        --20250813 新增    
        jhx.监管资金余额,
        jhx.期末账面资金余额,
        bnztzf.本年累计直投支付,
        gyl.本年供应链待还款计划数,
        bndkhkjh.开发贷款余额 AS 本年贷款待还款计划数,
        tdkzf.本年累计土地款支付 AS 本年累计土地款支付,
        bndhl.本年已销售待回款 AS 本年已销售待回款,
        gd.截止目前股东合作方投入余额 as 截止目前股东合作方投入余额,
        zyzj.占压资金 as 占压资金,
        p.物业操盘方,
        hz.住宅剩余可售套数,
        hz.商办剩余可售套数,
        hz.车位剩余可售个数,
        yjqhls.月均去化流速,
        case when isnull(yjqhls.月均去化流速,0) = 0 then 0 else hz.剩余可售套数/yjqhls.月均去化流速 end as 去化周期,
        p.销售状态,
        p.管理方式,
        p.项目类型,
        p.城市,
        hz.住宅已开工未售套数,
        jlv.本年住宅毛利率,
        jlv.本年商办毛利率,
        jlv.本年车位毛利率,
        p.ProjGUID
    into #res
    from proj p 
    left join hz on p.projguid = hz.项目guid
    left join m002_qn mqn on mqn.projguid = p.projguid
    left join m002_bn jlv on jlv.projguid = p.projguid
    --left join ylgh_jlv_bn jlv on jlv.projguid = p.projguid --净利率改为从M002取数
    left join ylgh_cashflow_bn bn on bn.projguid = p.projguid
    left join ylgh_cashflow_mn mn on mn.projguid = p.projguid
    left join #ylgh_qy bnqy on bnqy.projguid = p.projguid and bnqy.年 = @bn
    left join #ylgh_qy mnqy on mnqy.projguid = p.projguid and mnqy.年 = @mn
    LEFT JOIN #jhx jhx on jhx.ProjGUID =p.projguid
    LEFT JOIN #bnztzf bnztzf on bnztzf.ProjGUID =p.projguid
    LEFT JOIN #bndkhkjh bndkhkjh on bndkhkjh.ProjGUID = p.projguid
    LEFT JOIN #tdkzf tdkzf on tdkzf.ProjGUID = p.projguid
    LEFT JOIN #bndhl bndhl on bndhl.ProjGUID = p.projguid
    LEFT JOIN #gd gd on gd.ProjGUID = p.projguid
    LEFT JOIN #zyzj zyzj on zyzj.ProjGUID = p.projguid
    LEFT JOIN #hzf hzf on hzf.ProjGUID = p.projguid
    LEFT JOIN #yjqhls yjqhls on yjqhls.ProjGUID = p.projguid
    LEFT JOIN #gyl gyl on gyl.ProjGUID = p.projguid;



    --插入正式数据
    delete from s_集团止巨亏智能数据提取 where datediff(dd,清洗时间,getdate()) = 0
    
    insert into s_集团止巨亏智能数据提取
    select getdate() as 清洗时间
    ,平台公司
    ,项目代码
    ,投管代码
    ,项目名
    ,推广名
    ,获取方式
    ,获取时间
    ,获取总成本
    ,可售楼面价
    ,股权结构
    ,操盘方式
    ,其中营销操盘方
    ,并表方式
    ,项目权益比率
    ,合作方
    ,股权比例
    ,总可售面积
    ,总可售货值
    ,住宅总可售面积
    ,住宅总可售货值
    ,商办总可售面积
    ,商办总可售货值
    ,车位总可售面积
    ,车位总可售货值
    ,总未售面积
    ,总未售货值
    ,住宅总未售面积
    ,住宅总未售货值
    ,商办总未售面积
    ,商办总未售货值
    ,车位总未售面积
    ,车位总未售货值
    ,已开工未售面积
    ,已开工未售货值
    ,住宅已开工未售面积
    ,住宅已开工未售货值
    ,商办已开工未售面积
    ,商办已开工未售货值
    ,车位已开工未售面积
    ,车位已开工未售货值
    ,产成品面积
    ,产成品金额
    ,住宅产成品面积
    ,住宅产成品金额
    ,商办产成品面积
    ,商办产成品金额
    ,车位产成品面积
    ,车位产成品金额
    ,准产成品面积
    ,准产成品金额
    ,住宅准产成品面积
    ,住宅准产成品金额
    ,商办准产成品面积
    ,商办准产成品金额
    ,车位准产成品面积
    ,车位准产成品金额
    ,未卖散楼栋产成品面积
    ,未卖散楼栋产成品金额
    ,住宅未卖散楼栋产成品面积
    ,住宅未卖散楼栋产成品金额
    ,商办未卖散楼栋产成品面积
    ,商办未卖散楼栋产成品金额
    ,去年住宅净利率
    ,去年商办净利率
    ,去年车位净利率
    ,本年住宅净利率
    ,本年商办净利率
    ,本年车位净利率
    ,本年现金流入_签约
    ,本年现金流入_回款
    ,本年现金流入_其他流入
    ,本年现金流入_新增贷款
    ,本年现金流出_土地款
    ,本年现金流出_地价外直投
    ,本年现金流出_营销费
    ,本年现金流出_管理费
    ,本年现金流出_支付税金
    ,本年现金流出_支付利息
    ,本年现金流出_其他支出
    ,本年现金流出_归还贷款
    ,本年当期经营现金流
    ,本年当期现金流含融资
    ,本年期末净资金
    ,明年现金流入_签约
    ,明年现金流入_回款
    ,明年现金流入_其他流入
    ,明年现金流入_新增贷款
    ,明年现金流出_土地款
    ,明年现金流出_地价外直投
    ,明年现金流出_营销费
    ,明年现金流出_管理费
    ,明年现金流出_支付税金
    ,明年现金流出_支付利息
    ,明年现金流出_其他支出
    ,明年现金流出_归还贷款
    ,明年当期经营现金流
    ,明年当期现金流含融资
    ,明年期末净资金
    ,projguid
    ,监管资金余额
    ,期末账面资金余额
    ,本年累计直投支付
    ,本年供应链待还款计划数
    ,本年贷款待还款计划数
    ,本年累计土地款支付
    ,本年已销售待回款
    ,截止目前股东合作方投入余额
    ,占压资金
    ,物业操盘方
    ,住宅剩余可售套数
    ,商办剩余可售套数
    ,车位剩余可售个数
    ,月均去化流速
    ,去化周期
    ,销售状态
    ,管理方式
    ,项目类型
    ,城市
    ,住宅已开工未售套数
    ,本年住宅毛利率
    ,本年商办毛利率
    ,本年车位毛利率
    from #res
    
    select * from s_集团止巨亏智能数据提取  where datediff(dd,清洗时间,getdate()) = 0
    order by 平台公司,投管代码

    /*
        说明：
        1. 仅保留当天数据（通常为最新数据）。
        2. 对于历史数据，满足以下全部条件的数据将被删除：
            - 不是周一
            - 不是每月1号
            - 不是每年最后一天
            - 不是每月最后一天
            - 距离当前日期超过7天
        3. 这样可以保留每周一、每月1号、每月最后一天、每年最后一天的快照数据，便于后续数据分析和追溯。
    */
    DELETE FROM s_集团止巨亏智能数据提取 
    WHERE 
        -- -- 1. 保留当天数据
        -- DATEDIFF(DAY, 清洗时间, GETDATE()) <> 0
        -- OR
        (
            -- 2. 保留非每周一、非每月1号、非每年最后一天、非每月最后一天且距离当前超过7天的数据将被删除
            DATENAME(WEEKDAY, 清洗时间) <> '星期一'  -- 非周一
            AND DATEPART(DAY, 清洗时间) <> 1        -- 非每月1号
            AND DATEDIFF(DAY, 清洗时间, CONVERT(VARCHAR(4), YEAR(qxdate)) + '-12-31') <> 0  -- 非每年最后一天
            AND DATEDIFF(DAY, 清洗时间, DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, qxdate) + 1, 0))) <> 0 -- 非每月最后一天
            AND DATEDIFF(DAY, 清洗时间, GETDATE()) > 7  -- 距今超过7天
        );

    -- 删除临时表
    DROP TABLE 
        #gq,
        #hzf,
        #ylgh_lv,
        #ylgh_qy,
        #ylgh_xjl,
        #res,
        #jhx,
        #bnztzf,
        #bndkhkjh,
        #tdkzf,
        #bndhl,
        #gd,
        #zyzj,
        #yjqhls,
        #gyl;

end

 



 




