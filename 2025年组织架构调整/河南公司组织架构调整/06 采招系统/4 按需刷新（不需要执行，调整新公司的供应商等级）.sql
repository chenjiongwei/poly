-- SQLBook: Code
-- 查询p_Provider2ServiceCompany表的前10条记录
select top 10 * from p_Provider2ServiceCompany
-- 查询p_ProviderGrade表的所有记录
select  * from p_ProviderGrade 

-- 查询data_dict表中table_name为'p_Provider2ServiceCompany'的所有记录
select * from data_dict where table_name = 'p_Provider2ServiceCompany'

-- 判断一个供应商是否存在粤东以及湾区公司中存在不同的等级
-- 查询providername为'汕尾中燃城市燃气发展有限公司'的供应商信息
select * from p_Provider where  providername = '汕尾中燃城市燃气发展有限公司'

-- 找出湾区不合格/潜在的供应商范围
-- 临时表#wq用于存储湾区不合格/潜在的供应商信息
drop table #wq

-- 查询湾区不合格/潜在的供应商信息
select pg.GradeName,ppsc.* 
into #wq
from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
inner join p_ProviderGrade pg on pg.ProviderGradeGUID = ppsc.ServiceCompanyGradeGUID
inner join p_Provider pv on pv.ProviderGUID = ppsc.ProviderGUID 
where BUname in ('湾区公司') and GradeName in ('潜在','不合格','C级','D级') and isnull(ppsc.IsBlacklist,0) = 0 
and isnull(pv.IsBlacklist,0) = 0 

-- 找出在湾区公司不合格,但是在粤东公司不为潜在/不合格的供应商
-- 临时表#yd用于存储在湾区公司不合格,但是在粤东公司不为潜在/不合格的供应商信息
drop table #yd

-- 查询在湾区公司不合格,但是在粤东公司不为潜在/不合格的供应商信息
select pg.GradeName,ppsc.* 
into #yd
from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
inner join p_ProviderGrade pg on pg.ProviderGradeGUID = ppsc.ServiceCompanyGradeGUID
inner join (select Provider2ServiceGUID from #wq) t on t.Provider2ServiceGUID = ppsc.Provider2ServiceGUID
inner join p_Provider pv on pv.ProviderGUID = ppsc.ProviderGUID 
where BUname in ('粤东公司') and GradeName not in ('潜在','不合格','C级','D级') and isnull(ppsc.IsBlacklist,0) = 0 
and isnull(pv.IsBlacklist,0) = 0 

-- 通过粤东公司的等级刷新湾区公司的等级
-- 备份湾区公司的供应商服务信息
select ppsc.* into p_Provider2ServiceCompany_bak20230222
from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
where BUname in ('湾区公司')

-- 更新湾区公司的供应商服务信息
update ppsc set ppsc.ServiceCompanyGradeGUID = yd.ServiceCompanyGradeGUID from p_Provider2ServiceCompany ppsc
inner join myBusinessUnit bu on bu.BUGUID = ppsc.BUGUID
inner join #wq wq on wq.Provider2ServiceCompanyGUID = ppsc.Provider2ServiceCompanyGUID
inner join #yd yd on wq.Provider2ServiceGUID = yd.Provider2ServiceGUID
where BUname in ('湾区公司')

-- 4674A41A-81C3-4A20-8B5C-E52319022195 淮海公司
-- 8A08A706-0273-48BA-A1D4-6AB783024D42	江苏公司
-- 备份表
select * into  cg_DocArchive_bak20250429 from  cg_DocArchive where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195' 
select * into  cg_CgApply_bak20250429 from  cg_CgApply where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
select * into  cg_CgPlan_bak20250429 from  cg_CgPlan where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
select * into  cg_CgSolution_bak20250429 from  cg_CgSolution where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
select * into  cg_PG2Contract_bak20250429 from  cg_PG2Contract where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
select * into  cg_PGPlan_bak20250429 from  cg_PGPlan where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
select * into  Cg_CgPlanSp_bak20250429 from  Cg_CgPlanSp where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
select * into  Cg_CgPlan_OriginSp_bak20250429 from  Cg_CgPlan_OriginSp where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
select * into  Cg_CgPlan_Origin_bak20250429 from  Cg_CgPlan_Origin where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'


-- 更新表
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  cg_DocArchive a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195' 
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  cg_CgApply a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  cg_CgPlan a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  cg_CgSolution a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  cg_PG2Contract a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  cg_PGPlan a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  Cg_CgPlanSp a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  Cg_CgPlan_OriginSp a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'
update  a set a.buguid ='8A08A706-0273-48BA-A1D4-6AB783024D42' from  Cg_CgPlan_Origin a where  buguid ='4674A41A-81C3-4A20-8B5C-E52319022195'







