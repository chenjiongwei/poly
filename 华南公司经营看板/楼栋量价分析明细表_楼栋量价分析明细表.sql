-- declare @var_date datetime = '2024-12-31'
-- 楼栋价量分析明细表
-- 创建临时表存储销售数据
select *,
    -- 计算认购均价：地下室/车库按套数计算，其他按面积计算
    case when TopProductTypeName='地下室/车库' 
        then ISNULL(认购金额/NULLIF(认购套数,0),0) 
        else ISNULL(认购金额/NULLIF(认购面积,0),0) 
    end as 认购均价,
    -- 计算签约均价：地下室/车库按套数计算，其他按面积计算
    case when TopProductTypeName='地下室/车库' 
        then ISNULL(签约金额/NULLIF(签约套数,0),0) 
        else ISNULL(签约金额/NULLIF(签约面积,0),0) 
    end as 签约均价
into #sale
from (
    -- 按楼栋、年月、产品类型统计销售数据
    select 
        BldGUID,
        TopProductTypeName,
        convert(Varchar(7),StatisticalDate ,121) 年月,
        sum(isnull(ONetAmount,0)+isnull(SpecialCNetAmount,0)) 认购金额,
        sum(isnull(ONetArea,0)+isnull(SpecialCNetArea,0)) 认购面积,
        sum(isnull(ONetCount,0)+isnull(SpecialCNetCount,0)) 认购套数,
        sum(isnull(cNetAmount,0)+isnull(SpecialCNetAmount,0)) 签约金额,
        sum(isnull(cNetArea,0)+isnull(SpecialCNetArea,0)) 签约面积,
        sum(isnull(cNetCount,0)+isnull(SpecialCNetCount,0)) 签约套数
    from [172.16.4.161].[HighData_prod].dbo.data_wide_dws_s_SalesPerf s
    inner join [172.16.4.161].[HighData_prod].dbo.data_wide_dws_mdm_Project p  on s.ParentProjGUID = p.ProjGUID
    where p.BUGUID ='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
    group by BldGUID,convert(Varchar(7),StatisticalDate ,121),TopProductTypeName
) t
where 认购金额>0 or 签约金额>0

-- 查询项目销售明细数据
select 
    o.orgguid,
    a.DevelopmentCompanyGUID,
    o.organizationname 平台公司,
    case when cp.ParentProjGUID is not null then '是' else '否' end as 是否合作项目,
    pp.ProjCode_25 明源系统代码,
    pp.tgprojcode 投管代码,
    pp.projname 项目名称,
    pp.spreadname 项目推广名,
    p.spreadname 分期,
    a.ProductType 产品类型,
    a.ProductName 产品名称,
    BldCode 产品楼栋名称,
    b.GCBldname 工程楼栋名称,
    SaleBldName 销售楼栋名称,
    a.YjDdysxxDate 预计达到预售形象日期,
    a.SjDdysxxDate 实际达到预售形象日期,
    a.YjYsblDate 预计预售办理日期,
    a.SjYsblDate 实际预售办理日期,
    a.YJzskgdate 预计开工日期,
    a.SJzskgdate 实际开工日期,
    a.YJkpxsDate 预计开盘销售日期,
    a.SJkpxsDate 实际开盘销售日期,
    a.YJjgbadate 预计竣工备案日期,
    a.SJjgbadate 实际竣工备案日期,
    b.FactOpenDate 首推日期,
    b.isStopWork 是否停工,
    a.SaleBldGUID 产品楼栋GUID,
    s.年月,
    isnull(s.认购金额,0) 认购金额,
    isnull(s.认购面积,0) 认购面积,
    isnull(s.认购套数,0) 认购套数,
    isnull(s.认购均价,0) 认购均价,
    isnull(s.签约金额,0) 签约金额,
    isnull(s.签约面积,0) 签约面积,
    isnull(s.签约套数,0) 签约套数,
    isnull(s.签约均价,0) 签约均价
from [172.16.4.161].[HighData_prod].dbo.data_wide_dws_s_p_lddbamj a 
inner join [172.16.4.161].[HighData_prod].dbo.data_wide_dws_mdm_Building b 
    on a.SaleBldGUID = b.buildingguid        
inner join [172.16.4.161].[HighData_prod].dbo.data_wide_dws_mdm_Project p 
    on b.projguid = p.projguid 
inner join [172.16.4.161].[HighData_prod].dbo.data_wide_dws_mdm_Project pp 
    on p.parentguid = pp.projguid 
inner join [172.16.4.161].[HighData_prod].dbo.data_wide_dws_s_Dimension_Organization o 
    on a.DevelopmentCompanyGUID = o.DevelopmentCompanyGUID
left join (
    select distinct ParentProjGUID 
    from [172.16.4.161].[HighData_prod].dbo.data_wide_s_NoControl
) cp on cp.ParentProjGUID = a.projguid
left join #sale s on a.SaleBldGUID = s.BldGUID
where datediff(dd,qxdate,getdate())=0
    and o.orgguid ='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
--and pp.SpreadName ='佛山映月湖保利天珺'
order by 投管代码        

-- 删除临时表
drop table #sale