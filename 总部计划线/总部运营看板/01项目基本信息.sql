--获取项目首推时间
select 
	t.projguid, 
	min(SJkpxsDate) as SJkpxsDate 
into #stDate
from (
	--获取房间认购的时间
	select 
    	parentprojguid projguid, 
    	min(qsdate) as SJkpxsDate 
	from data_wide_s_SaleHsData 
    group by parentprojguid
	--having sum(isnull(RoomTotal,0))<>0
	--获取特殊业绩计算货量的录入时间
	union all 
	select 
    	ParentProjGUID,
    	min(StatisticalDate) as SJkpxsDate
	from data_wide_s_SpecialPerformance
	where TsyjType in 
    	(select TsyjTypeName from 
     	[172.16.4.141].erp25.dbo.s_TsyjType t 
         where IsCalcYSHL =1)
	group by ParentProjGUID
	--合作业绩录入不为0
	union all 
	select 
    	ParentProjGUID,
    	min(StatisticalDate) as SJkpxsDate
	from data_wide_s_NoControl
	where  CCjTotal>0
	group by ParentProjGUID
) t
	inner join data_wide_dws_mdm_project pj 
	on t.projguid = pj.projguid 
	group by t.projguid

--获取项目的节点信息 
select 
	ld.projguid,
	min(isnull(xs.SJkpxsDate,'2099-12-31')) as  SJkpxsDate,
	sum(case when sjjgbadate is null 
        and datediff(dd,yjjgbadate,getdate())>0 
        then zksmj else 0 end) as 已延期竣工面积 
into #jd
from data_wide_dws_s_p_lddbamj ld 
left join  #stDate xs 
	on xs.projguid = ld.projguid
where datediff(dd,qxdate,getdate()) = 0
group by ld.projguid 

--已延期竣工面积
select 
	pj.项目guid,
	sum(isnull(pb.buildarea,0)) 已延期竣工面积
into #jg
from data_wide_dws_mdm_building pb 
inner join data_wide_dws_mdm_building gc 
on pb.gcbldguid = gc.buildingguid
inner join [172.16.4.141].MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport zt 
on zt.ztguid = gc.BudGUID 
inner join dw_d_topproject pj 
on pj.项目guid = pb.parentprojguid 
where datediff(dd,gc.planfinishdate,getdate())>0 
	and pj.项目状态= '正常' 
	and pj.项目管理方式 in ('二级开发','收益权合作') 
	and pb.BldType = '产品楼栋' 
	AND gc.BldType = '工程楼栋' 
	and isnull(zt.是否停工,'') not in ('停工','缓建') 
	and isnull(pj.开发受限,'')<>'否' 
	and gc.factfinishdate is null
group by pj.项目guid

--项目的任一楼栋到合约交付时间，但仍未获取竣工备案表，且未发出交楼通知书或未实际交付，则把该项目纳入统计
--取销售系统
select  
	ld.projguid,
	a.bldguid,
	a.jfdate jzjfjhwcdate,
	ld.sjjgbadate
into #bld
FROM [172.16.4.141].erp25.dbo.p_building a 
INNER JOIN data_wide_dws_s_p_lddbamj ld 
ON a.bldguid = ld.SaleBldGUID
WHERE 1=1  
	AND DATEDIFF(d, ld.QXDate, GETDATE()) = 0 
	AND ld.ProductType IN ( '住宅', '高级住宅');

SELECT 
	pj.ParentGUID projguid,
	count(distinct case when b.sjjgbadate is null 
             and a.JFDate is null 
             and r.BlRhDate is null  
             and datediff(dd,b.jzjfjhwcdate,getdate())>0
		then pj.ParentGUID else null end) 已延期交付项目数,
 	SUM( CASE WHEN 
            DATEDIFF(DAY, a.JFDate, b.jzjfjhwcdate) = 0
            AND DATEDIFF(DAY, isnull(r.BlRhDate,'2099-01-01'), 	
            CONVERT(varchar(4),YEAR(GETDATE()))+'-12-31') >= 0 
            THEN 1 ELSE 0 END) +
    SUM( CASE WHEN 
         DATEDIFF(DAY, a.JFDate, isnull(b.jzjfjhwcdate,'1999-01-01')) <> 0
         AND DATEDIFF(DAY, isnull(r.BlRhDate,'2099-01-01'),   
         CONVERT(varchar(4),YEAR(GETDATE()))+'-12-31') >= 0 
         THEN 1 ELSE 0 END) 本年交付套数,  
    SUM( CASE WHEN DATEDIFF(DAY, a.JFDate, b.jzjfjhwcdate) = 0
         AND DATEDIFF(DAY, isnull(r.BlRhDate,'2099-01-01'),  
         CONVERT(varchar(4),YEAR(GETDATE()))+'-12-31') >= 0 
         THEN r.bldarea ELSE 0 END)+
    SUM( CASE WHEN DATEDIFF(DAY, a.JFDate, 
                            isnull(b.jzjfjhwcdate,'1999-01-01')) <> 0
         AND DATEDIFF(DAY, isnull(r.BlRhDate,'2099-01-01'), 
         CONVERT(varchar(4),YEAR(GETDATE()))+'-12-31') >= 0 
         THEN r.bldarea ELSE 0 END) 本年交付面积
into #jf
FROM data_wide_dws_mdm_project pj
left join [172.16.4.141].erp25.dbo.s_Contract a 
	on pj.projguid = a.projguid
	and a.Status = '激活' 
	and  a.JFDate 
		between CONVERT(varchar(4),YEAR(GETDATE()))+'-01-01' 
		and CONVERT(varchar(4),YEAR(GETDATE()))+'-12-31'
left JOIN [172.16.4.141].erp25.dbo.ep_room r 
	ON a.RoomGUID = r.RoomGUID 
	AND r.ProductType IN ( '住宅', '高级住宅' ) 
LEFT JOIN #bld b 
	ON  r.BldGUID =b.BldGUID
group by pj.ParentGUID


select 
	pj.增量存量分类,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        then 1 else 0 end ) 项目总数,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and pj.建设状态 = '在建' 
        then 1 else 0 end ) 在建项目个数,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and pj.建设状态 = '拟建' 
        then 1 else 0 end ) 未开工项目数,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and pj.建设状态 = '已完工' 
        then 1 else 0 end ) 已完工项目数,
	sum(isnull(本年开工总面积_实际,0)) 本年开工面积,
	sum(isnull(本年竣备总面积_实际,0)) 本年竣工面积,
	sum(isnull(累计在建总面积,0) - isnull(累计在建总面积_非停工,0)) 当前停工面积,
	sum(isnull(累计在建总面积_非停工,0)) 当前在建面积,
	sum(isnull(jf.本年交付套数,0)) as 本年交付套数,
	sum(isnull(jf.本年交付面积,0)) as 本年交付面积,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and (jd.SJkpxsDate<>'2099-12-31' or pj.销售状态 = '售罄') 
        then 1 else 0 end)  已开盘项目个数,
	(sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        then 1 else 0 end )-
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and (jd.SJkpxsDate<>'2099-12-31' or pj.销售状态 = '售罄')  
        then 1 else 0 end)) 未开盘项目个数,
	sum(case when datediff(yy,SckpDate,getdate() ) =0 
        and SJkpxsDate = '2099-12-31' 
        then 1 else 0 end) 本年剩余时间计划开盘数,
	sum(case when datediff(dd,SckpDate,getdate() ) >0 
        and SJkpxsDate = '2099-12-31' 
        then 1 else 0 end) 开盘滞后项目数,
	sum(isnull(jg.已延期竣工面积,0)) as 已延期竣工面积,
	sum(isnull(jf.已延期交付项目数,0)) as 已延期交付项目数
from dw_d_TopProject pj
LEFT JOIN dbo.dw_f_TopProject_SaleValue hz 
	ON hz.项目GUID = pj.项目GUID
left join #jf jf 
	on jf.projguid = pj.项目guid
left join #jd jd 
	on jd.ProjGUID = pj.项目guid
left join #jg jg 
	on jg.项目guid = pj.项目guid
left join [172.16.4.141].erp25.dbo.mdm_ProjectNodeIndex lxjd 
	on lxjd.projguid = pj.项目guid
where pj.项目状态 = '正常' 
	and pj.项目管理方式 in ('二级开发','收益权合作') 
	and isnull(pj.开发受限,'')<>'否' 
group by pj.增量存量分类
union all 
select 
	'全项目' 增量存量分类,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        then 1 else 0 end ) 项目总数,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and pj.建设状态 = '在建' 
        then 1 else 0 end ) 在建项目个数,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and pj.建设状态 = '拟建' 
        then 1 else 0 end ) 未开工项目数,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and pj.建设状态 = '已完工' 
        then 1 else 0 end ) 已完工项目数,
	sum(isnull(本年开工总面积_实际,0)) 本年开工面积,
	sum(isnull(本年竣备总面积_实际,0)) 本年竣工面积,
	sum(isnull(累计在建总面积,0) - isnull(累计在建总面积_非停工,0)) 当前停工面积,
	sum(isnull(累计在建总面积_非停工,0)) 当前在建面积,
	sum(isnull(jf.本年交付套数,0)) as 本年交付套数,
	sum(isnull(jf.本年交付面积,0)) as 本年交付面积,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and (jd.SJkpxsDate<>'2099-12-31' or pj.销售状态 = '售罄')
        then 1 else 0 end)  已开盘项目个数,
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        then 1 else 0 end )-
	sum(case when pj.项目状态 = '正常' 
        and pj.项目管理方式 in ('二级开发','收益权合作') 
        and (jd.SJkpxsDate<>'2099-12-31' or pj.销售状态 = '售罄')
        then 1 else 0 end) 未开盘项目个数,
	sum(case when datediff(yy,isnull(SckpDate,'2099-12-31'),getdate() ) =0 
        and SJkpxsDate = '2099-12-31' 
        then 1 else 0 end) 本年剩余时间计划开盘数,
	sum(case when datediff(dd,isnull(SckpDate,'2099-12-31'),getdate() ) >0 
        and SJkpxsDate = '2099-12-31' 
        then 1 else 0 end) 开盘滞后项目数,
	sum(isnull(jg.已延期竣工面积,0)) as 已延期竣工面积,
	sum(isnull(jf.已延期交付项目数,0)) as 已延期交付项目数
from dw_d_TopProject pj
LEFT JOIN dbo.dw_f_TopProject_SaleValue hz  ON hz.项目GUID = pj.项目GUID
left join #jf jf  on jf.projguid = pj.项目guid
left join #jd jd  on jd.ProjGUID = pj.项目guid
left join #jg jg  on jg.项目guid = pj.项目guid
left join [172.16.4.141].erp25.dbo.mdm_ProjectNodeIndex lxjd  on lxjd.projguid = pj.项目guid
where pj.项目状态 = '正常' 
	and pj.项目管理方式 in ('二级开发','收益权合作') 
	and isnull(pj.开发受限,'')<>'否' 

DROP TABLE #jf,#bld,#jd,#jg,#stDate