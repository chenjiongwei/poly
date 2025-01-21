-- SQLBook: Code
select top 10 * from p_Provider2ServiceCompany
select  * from p_ProviderGrade 

select * from data_dict where table_name = 'p_Provider2ServiceCompany'

--判断一个供应商是否存在粤东以及湾区公司中存在不同的等级

select * from p_Provider where  providername = '汕尾中燃城市燃气发展有限公司'

--找出湾区不合格/潜在的供应商范围
drop table #wq

select pg.GradeName,ppsc.* 
into #wq
from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
inner join p_ProviderGrade pg on pg.ProviderGradeGUID = ppsc.ServiceCompanyGradeGUID
inner join p_Provider pv on pv.ProviderGUID = ppsc.ProviderGUID 
where BUname in ('湾区公司') and GradeName in ('潜在','不合格','C级','D级') and isnull(ppsc.IsBlacklist,0) = 0 
and isnull(pv.IsBlacklist,0) = 0 

--找出在湾区公司不合格,但是在粤东公司不为潜在/不合格的供应商
drop table #yd

select pg.GradeName,ppsc.* 
into #yd
from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
inner join p_ProviderGrade pg on pg.ProviderGradeGUID = ppsc.ServiceCompanyGradeGUID
inner join (select Provider2ServiceGUID from #wq) t on t.Provider2ServiceGUID = ppsc.Provider2ServiceGUID
inner join p_Provider pv on pv.ProviderGUID = ppsc.ProviderGUID 
where BUname in ('粤东公司') and GradeName not in ('潜在','不合格','C级','D级') and isnull(ppsc.IsBlacklist,0) = 0 
and isnull(pv.IsBlacklist,0) = 0 

--通过粤东公司的等级刷新湾区公司的等级
--备份
select ppsc.* into p_Provider2ServiceCompany_bak20230222
from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
where BUname in ('湾区公司')

--更新
update ppsc set ppsc.ServiceCompanyGradeGUID = yd.ServiceCompanyGradeGUID from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
inner join #wq wq on wq.Provider2ServiceCompanyGUID = ppsc.Provider2ServiceCompanyGUID
inner join #yd yd on wq.Provider2ServiceGUID = yd.Provider2ServiceGUID
where BUname in ('湾区公司')

 
  


 