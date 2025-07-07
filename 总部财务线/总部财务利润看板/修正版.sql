USE [HighData_prod]
GO

/****** Object:  StoredProcedure [dbo].[usp_cb_集团成本降压分期填报底表_修正前]    Script Date: 2025/5/29 11:14:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
存储过程说明:
用于生成集团成本降压分期填报底表数据

修改记录:
modified by lintx 20250313
1、增加 地上可售面积，地下可售面积，本年计划结转地上面积，本年计划结转地下面积， 本年已结转地上面积，本年已结转车位面积 
2、可售面积改成从中间表取可售+自持面积 

modified by lintx 20250426
最新版的取数逻辑优先级
1、最近一次动态成本回顾（有审批记录）
2、最近一次动态成本补录（有审批记录）
3、最近一次动态成本回顾（自动拍照）
4、最近一次动态成本补录（自动拍照）
*/

ALTER proc [dbo].[usp_cb_集团成本降压分期填报底表_修正前] as 
begin 

-- 获取盈利规划信息: 版本：2024年4季度公司表
-- 预处理要获取的版本信息
declare @ylghbb varchar(50) = '2024年四季度公司表1'

-- 汇总手工录入以及自动取数的除地价外直投数据
select  
    t.YLGHProjGUID as projguid, 
    sum(除地价外直投不含税) as 盈利规划除地价外直接投资,
    sum(除地价外直投含税) as 盈利规划除地价外直接投资含税
into #zt
from (
    select  
        pj.YLGHProjGUID,
        sum(case when 报表预测项目科目 = '除地价外直投（含税）' then convert(decimal(16,2),value_string) else 0 end) as 除地价外直投含税,
        sum(case when 报表预测项目科目 = '除地价外直投（不含税）' then convert(decimal(16,2),value_string) else 0 end) as 除地价外直投不含税
    from data_wide_qt_F080005 f08
    inner join data_wide_dws_ys_ProjGUID pj 
        on f08.实体分期 = pj.YLGHProjGUID 
        and pj.edition = @ylghbb 
        and pj.BusinessEdition = f08.版本 
        and pj.Level = 3
    where 报表预测项目科目 in ('除地价外直投（不含税）' ,'除地价外直投（含税）')
        and CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0 
    group by pj.YLGHProjGUID 
) t  
group by t.YLGHProjGUID

-- 获取当前的计划结转面积
select 
    pj.YLGHProjGUID as projguid,
    sum(CONVERT(decimal(16,2),value_string)) as 本年计划结转面积
into #jzmj
from data_wide_qt_F080001 F03
inner join data_wide_dws_ys_ProjGUID pj 
    on F03.实体分期 = pj.YLGHProjGUID 
    and pj.IsBase = 1 
    and pj.BusinessEdition = F03.版本 
    and pj.Level = 3 
    and 年 = '2025年'
where 报表预测项目科目='结转面积' 
    and CHARINDEX('e', ISNULL(f03.VALUE_STRING, '0')) = 0 
group by pj.YLGHProjGUID

-- 动态成本回顾：取本年以前的最新版本 
-- 获取每个分期对应的年初回顾版本信息
select
    projguid,
    max(CurVersion) as CurVersion
into #ncbb
from highdata_prod.dbo.data_wide_cb_MonthlyReview
where year(ReviewDate) < year(getdate())
group by projguid 

select 
    projectguid,
    max(t.CurVersion) as CurVersion
into #nccb_manu
from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollect t
left join #ncbb nc on nc.projguid = t.projectguid
where year(RecollectDate) < year(getdate()) 
    and ApproveState = '已审核' 
    and nc.projguid is null 
group by projectguid 

-- 取年初动态成本数据
select 
    t.projguid,
    CurVersion,版本, 
    sum(t.动态成本) as 动态成本, 
    sum(t.动态成本含税) as 动态成本含税 
into #nccb
from (
    select 
        t.projguid,
        t.CurVersion, '回顾版：'+t.CurVersion 版本,
        sum(case when t.AccountCode = '5001' then isnull(CurDynamicCostNonTax_fxj,0) else 0 end)-
        sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCostNonTax_fxj,0) else 0 end) as 动态成本,
        sum(case when t.AccountCode = '5001' then isnull(CurDynamicCost_fxj,0) else 0 end)-
        sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCost_fxj,0) else 0 end) as 动态成本含税
    from highdata_prod.dbo.data_wide_cb_MonthlyReview t 
    inner join #ncbb bb on t.CurVersion = bb.CurVersion and t.projguid = bb.projguid
    where t.AccountCode in ('5001','5001.10','5001.09','5001.11','5001.01')
    group by t.projguid,t.CurVersion
    union all 
    select 
        t.ProjectGUID as projguid,
        t.CurVersion,'补录版：'+t.CurVersion 版本,
        sum(case when dtl.CostCode = '5001' then isnull(dtl.NoTaxAmount,0) else 0 end)-
        sum(case when dtl.CostCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(dtl.NoTaxAmount,0) else 0 end) as 动态成本,
        sum(case when dtl.CostCode = '5001' then isnull(dtl.amount,0) else 0 end)-
        sum(case when dtl.CostCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(dtl.amount,0) else 0 end) as 动态成本含税
    from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollect t
    inner join [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollectDtl dtl 
        on t.RecollectGUID = dtl.RecollectGUID
    inner join #nccb_manu bb 
        on t.CurVersion = bb.CurVersion 
        and t.ProjectGUID = bb.ProjectGUID
    group by t.ProjectGUID,t.CurVersion
) t 
group by t.projguid,CurVersion,版本

-- 获取每个分期的最新回顾版本信息：动态成本回顾手工审核版>手工补录版>动态成本回顾自动拍照版
-- 按月份维度
-- 1、最近一次动态成本回顾（有审批记录）
-- 2、最近一次动态成本补录（有审批记录）
-- 3、最近一次动态成本回顾（自动拍照）
-- 4、最近一次动态成本补录（自动拍照）
-- 动态成本回顾
select *
into #cbbb 
from (
    select 
        projguid,
        CurVersion as CurVersion,
        CreateUserName,
        convert(varchar(6),ReviewDate,112) as RecollectDate,
        ApproveState,
        ROW_NUMBER() over(PARTITION by projguid 
        order by 
            convert(varchar(6),ReviewDate,112) desc,
            case when ApproveState ='已审核' then 2 else 1 end desc,            
            case when CreateUserName = '系统管理员' then 1 else 2 end desc,
            CurVersion desc) as rn    --判断是自动拍照还是手工审核
    from (
        select 
            projguid,
            CurVersion,
            CreateUserName,
            ReviewDate,
            ApproveState
        from highdata_prod.dbo.data_wide_cb_MonthlyReview 
        group by projguid,
            CurVersion,
            CreateUserName,
            ReviewDate,
            ApproveState
        union all 
        select 
            ProjectGUID,
            CurVersion,
            CreateUserName,
            RecollectDate,
            ApproveState
        from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollect t
        group by 
            ProjectGUID,
            CurVersion,
            CreateUserName,
            RecollectDate,
            ApproveState
        ) t
) t 
where rn = 1;

-- 取动态成本回顾手工审核版
select 
    t.projguid,
    CurVersion,版本,
    sum(最新动态成本) as 最新动态成本,
    sum(最新动态成本含税) as 最新动态成本含税 
into #cb
from (
    select 
        t.projguid,
        t.CurVersion,'回顾版：'+t.CurVersion as 版本,
        sum(case when t.AccountCode = '5001' then isnull(CurDynamicCostNonTax_fxj,0) else 0 end)-
        sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCostNonTax_fxj,0) else 0 end)  as 最新动态成本,
        sum(case when t.AccountCode = '5001' then isnull(CurDynamicCost_fxj,0) else 0 end)-
        sum(case when t.AccountCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(CurDynamicCost_fxj,0) else 0 end)  as 最新动态成本含税
    from highdata_prod.dbo.data_wide_cb_MonthlyReview t 
    inner join #cbbb bb on t.CurVersion = bb.CurVersion and t.projguid = bb.projguid 
    where t.AccountCode in ('5001','5001.10','5001.09','5001.11','5001.01')
    group by t.projguid,t.CurVersion
)t 
group by t.projguid,CurVersion,版本

-- 手工补录版
insert into #cb
select t.projguid,t.CurVersion,t.版本,sum(t.动态成本) as 最新动态成本,sum(t.动态成本含税) as 最新动态成本含税 
from (
    select 
        t.ProjectGUID as projguid,
        t.CurVersion,'补录版：'+t.CurVersion as 版本,
        sum(case when dtl.CostCode = '5001' then isnull(dtl.NoTaxAmount,0) else 0 end)-
        sum(case when dtl.CostCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(dtl.NoTaxAmount,0) else 0 end) as 动态成本,
        sum(case when dtl.CostCode = '5001' then isnull(dtl.amount,0) else 0 end)-
        sum(case when dtl.CostCode in ('5001.10','5001.09','5001.11','5001.01') then isnull(dtl.amount,0) else 0 end) as 动态成本含税
    from [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollect t
    inner join [172.16.4.141].MyCost_Erp352.dbo.cb_DTCBManualEntryRecollectDtl dtl 
        on t.RecollectGUID = dtl.RecollectGUID
    inner join #cbbb bb 
        on t.CurVersion = bb.CurVersion 
        and t.ProjectGUID = bb.projguid 
    group by t.ProjectGUID,t.CurVersion
) t 
left join #cb cb on t.projguid = cb.projguid 
where cb.projguid is null 
group by t.projguid,t.CurVersion,t.版本

-- 分期合同结算率:成本系统06公司产值表中对应分期的已结算合同有效签约金额/分期所有合同有效签约金额
SELECT DISTINCT ContractGUID
INTO #zz
FROM
( SELECT cf.ContractGUID
    FROM [172.16.4.141].[MyCost_Erp352].dbo.cb_CfDtl cf
         LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.vcb_contract vc 
            ON cf.ContractGUID = vc.ContractGUID
    WHERE ( cf.costcode LIKE '5001.02%'
              OR cf.costcode LIKE '5001.03%'
              OR cf.costcode LIKE '5001.04%'
              OR cf.costcode LIKE '5001.05%'
              OR cf.costcode LIKE '5001.07%'
              OR cf.costcode LIKE '5001.08%' )
    UNION
    SELECT vc.ContractGUID
    FROM [172.16.4.141].[MyCost_Erp352].dbo.vcb_contract vc
         LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.cb_HtType v 
            ON vc.HtTypeGUID = v.HtTypeGUID
    WHERE ( v.HtTypeCode LIKE '02%'
              OR v.HtTypeCode LIKE '03%'
              OR v.HtTypeCode LIKE '04%'
              OR v.HtTypeCode LIKE '05%'
              OR v.HtTypeCode LIKE '06%' )
) zz;

SELECT p.projguid,
       a.JsState AS '结算状态',
       sum(CASE
           WHEN a.JsState = '结算' THEN
                a.JsAmount_Bz
           ELSE a.htamount + ISNULL(zz.htamount, 0)
       END) AS '有效签约金额含补协'
into #jsl
FROM [172.16.4.141].[MyCost_Erp352].dbo.cb_Contract a
    inner join [172.16.4.141].[MyCost_Erp352].dbo.cb_contractproj p 
        on a.contractguid = p.contractguid
    LEFT JOIN ( 
        SELECT z.MasterContractGUID,
               SUM(z.HtAmount) htamount
        FROM [172.16.4.141].[MyCost_Erp352].dbo.cb_Contract z
        WHERE z.MasterContractGUID IS NOT NULL
              AND z.ApproveState IN ( '审核中', '已审核' )
              AND z.HtProperty = '补充合同'
              AND z.IfDdhs = 0
        GROUP BY z.MasterContractGUID
    ) zz ON a.ContractGUID = zz.MasterContractGUID
    LEFT JOIN [172.16.4.141].[MyCost_Erp352].dbo.cb_Contract y 
        ON a.ContractGUID = y.ContractGUID
    LEFT OUTER JOIN [172.16.4.141].[MyCost_Erp352].dbo.cb_HtType AS c
        ON a.BUGUID = c.BUGUID
           AND a.HtTypeCode = c.HtTypeCode
WHERE (1 = 1)
      AND a.IsFyControl = 0 
      AND a.HtClass = '已定合同'
      AND HtTypeName NOT LIKE '%土地类%'
      AND a.ContractGUID IN ( SELECT ContractGUID FROM #zz ) 
      AND ( a.HtProperty IN ( '多方合同', '三方合同', '直接合同' ) OR y.IfDdhs = 1 ) 
group by p.projguid,
         a.JsState

select projguid,
       case when sum(有效签约金额含补协) = 0 then 0 
            else sum(case when 结算状态 = '结算' then 有效签约金额含补协 else 0 end) /sum(有效签约金额含补协) 
       end  as 分期合同结算率
into #jsl_fq
from #jsl 
group by projguid

-- 判断本年是否有结转
-- 分别按照项目、分期层级判断
select ProjGUID
into #isjz
from data_wide_dws_mdm_project pj 
inner join (
    select distinct nc.明源项目guid 
    from data_tb_集团财务结转填报表 t
    inner join data_tb_NC明源项目对照填报表 nc 
        on t.NC项目编号 = isnull(nc.NC项目代码手填,nc.NC项目代码)
    where isnull(明源代码手填,明源代码) is not null 
        and nc.是否分期 = '分期' 
) nc on nc.明源项目guid = pj.projguid
union all 
select ProjGUID
from data_wide_dws_mdm_project pj 
inner join (
    select distinct nc.明源项目guid 
    from data_tb_集团财务结转填报表 t
    inner join data_tb_NC明源项目对照填报表 nc 
        on t.NC项目编号 = isnull(nc.NC项目代码手填,nc.NC项目代码)
    where isnull(明源代码手填,明源代码) is not null 
        and nc.是否分期 = '项目' 
) nc on nc.明源项目guid = pj.ParentGUID

-- 获取明源中间表的自持且可售车位个数以及自持且可售面积，剔除代建项目   
SELECT a.projguid,
    sum(isnull(a.HoldArea,0)+isnull(a.SaleArea,0)) 可售或自持面积,
    sum(case when mdp.producttype = '地下室/车库' then 0 
             else isnull(a.HoldArea,0)+isnull(a.SaleArea,0) end) 地上可售或自持面积,
    sum(case when mdp.producttype = '地下室/车库' then isnull(a.HoldArea,0)+isnull(a.SaleArea,0) 
             else 0 end)  地下可售或自持面积  
into #fq_area
FROM [172.16.4.141].mycost_erp352.dbo.vs_md_productbuild_getAreaAndSpaceNumInfo a 
LEFT JOIN [172.16.4.141].erp25.dbo.mdm_saleBuild mdm 
    ON mdm.SaleBldGUID = a.ProductBuildGUID
LEFT JOIN [172.16.4.141].erp25.dbo.mdm_product mdp 
    ON mdm.productguid = mdp.productguid
group by a.projguid

-- 汇总所有结果
select 
    do.orgguid as 公司guid , 
    do.organizationname 平台公司,	
    p.projcode_25 项目代码,	
    p.ProjName 项目名称,	
    p.spreadname 项目推广名,	
    pj.projcode_25 分期代码,	
    pj.ProjName 分期名称,
    zt.盈利规划除地价外直接投资,
    fqa.可售或自持面积 as 可售面积,
    nccb.动态成本 明源动态成本拍照,	
    jz.本年计划结转面积,	
    cb.最新动态成本,	
    jsl.分期合同结算率,	
    case when jsl.分期合同结算率 = 1 then 0 else 1 end 是否纳入计算,	
    case when isjz.projguid is null then '否' else '是' end 项目是否本年有结转,
    pj.projguid as 分期guid,
    zt.盈利规划除地价外直接投资含税,
    nccb.动态成本含税 明源动态成本含税拍照,
    cb.最新动态成本含税,
    fqa.地上可售或自持面积 as 地上可售面积,
    fqa.地下可售或自持面积 as 地下可售面积,
    nccb.CurVersion as 明源动态成本拍照版本号,
    nccb.版本 明源动态成本拍照版本,
    cb.CurVersion 最新动态成本版本号,	
    cb.版本 最新动态成本版本
into #res
from data_wide_dws_mdm_project pj
inner join data_wide_dws_mdm_project p 
    on pj.ParentGUID = p.projguid
inner join data_wide_dws_s_dimension_organization do 
    on do.orgguid = pj.buguid
left join #zt zt 
    on zt.projguid = pj.projguid
left join #jzmj jz 
    on jz.projguid = pj.projguid
left join #jsl_fq jsl 
    on jsl.projguid = pj.projguid
left join #nccb nccb 
    on nccb.projguid = pj.projguid
left join #cb cb 
    on cb.projguid = pj.projguid
left join (
    select projguid 
    from #isjz 
    group by projguid
) isjz on isjz.projguid = pj.projguid 
left join #fq_area fqa 
    on fqa.projguid = pj.projguid
where pj.level = 3
order by do.organizationname,p.ProjName 

-- 补丁：全分期的数据要放在其中一个分期上
select ParentGUID,projguid,projname 
into #fq_list
from (
    select ParentGUID,ProjGUID,projname,
           rank() over(partition by parentguid order by projcode) as rn  
    from data_wide_dws_mdm_Project
    where level = 3
) t
where rn= 1

update res 
set res.盈利规划除地价外直接投资 = isnull(res.盈利规划除地价外直接投资,0)+isnull(zt.盈利规划除地价外直接投资,0),
    res.盈利规划除地价外直接投资含税 = isnull(res.盈利规划除地价外直接投资含税,0)+isnull(zt.盈利规划除地价外直接投资含税,0)
from #res res 
inner join (
    select fq.ProjGUID,zt.盈利规划除地价外直接投资,zt.盈利规划除地价外直接投资含税 
    from #zt zt
    inner join #fq_list fq 
        on zt.projguid = fq.ParentGUID
    where len(zt.projguid)>36
) zt on zt.ProjGUID = res.分期guid

update res 
set res.本年计划结转面积 = isnull(res.本年计划结转面积,0)+isnull(jz.本年计划结转面积,0)
from #res res 
inner join (
    select fq.ProjGUID,jz.本年计划结转面积 
    from #jzmj jz
    inner join #fq_list fq 
        on jz.projguid = fq.ParentGUID
    where len(jz.projguid)>36
) jz on jz.ProjGUID = res.分期guid
 
delete from dbo.cb_集团成本降压分期填报底表_修正前 

insert into cb_集团成本降压分期填报底表_修正前
select * from #res

select * from cb_集团成本降压分期填报底表_修正前

-- 清理临时表
drop table #cb,#cbbb,#isjz,#jsl,#jsl_fq,#jzmj,#ncbb,#nccb,#zt,#zz,#fq_list,#res,#fq_area,#nccb_manu

end
