--http://172.16.8.135/DecisionPub/NavInfoSettings/Project/TopProject.aspx?funcid=03030203


select  * from [dbo].[nmap_N_TopProject] where  TopProjName like  '%徐州%'

select  * from erp25.dbo. 32620488-7FD7-4AFD-B6B7-3F2D6ECE57D1 

select  * from  [dbo].[nmap_N_Company] where  CompanyGUID ='32620488-7FD7-4AFD-B6B7-3F2D6ECE57D1'
select  * from  [dbo].[nmap_N_p_DevelopmentCompany] where DevelopmentCompanyName ='江苏公司'  --DevelopmentCompanyGUID ='7926285B-3B0D-E711-80BA-E61F13C57837'

select * from  erp25.dbo.p_DevelopmentCompany where  DevelopmentCompanyGUID ='152990B8-14F5-46CF-A7D6-C8AD3A9363DB'


select  * into [nmap_N_TopProject_bak20250508]  from  [nmap_N_TopProject]

update b  
   set  b.CompanyGUID =a.CompanyGUID,
       b.DevelopmentCompanyGUID='152990B8-14F5-46CF-A7D6-C8AD3A9363DB'
--select b.*,cp2.CompanyName,cp1.CompanyName
from  [dbo].[nmap_N_Project] a
inner join [nmap_N_Company] cp1 on cp1.CompanyGUID =a.CompanyGUID
inner join [nmap_N_TopProject] b on a.ProjGUID =b.TopProjGUID
inner join [nmap_N_Company] cp2 on cp2.CompanyGUID =b.CompanyGUID
where  a.CompanyGUID <> b.CompanyGUID and cp1.CompanyName ='江苏'

--update a set a.CompanyGUID ='371C153C-12E8-46BB-9198-A38F181B10FE',DevelopmentCompanyGUID='152990B8-14F5-46CF-A7D6-C8AD3A9363DB'
----select  * 
--from  [nmap_N_TopProject] a 
----where  TopProjName ='徐州市经济开发区和平路北地块'
--where  CompanyGUID = '32620488-7FD7-4AFD-B6B7-3F2D6ECE57D1'

--select  * from [nmap_N_Company] where  CompanyGUID= '32620488-7FD7-4AFD-B6B7-3F2D6ECE57D1'
--select  * from [nmap_N_Company] where  CompanyGUID= '41B16CC1-5954-4D24-876F-2AB61845F08C'
--371C153C-12E8-46BB-9198-A38F181B10FE	江苏
--32620488-7FD7-4AFD-B6B7-3F2D6ECE57D1	苏北公司
--select  * from [nmap_N_Company] where  CompanyName ='苏北'

 --齐鲁公司迁移到山东公司
 2AFC0FB8-B63E-423C-B40D-324631563BFD	京津冀公司
 B86DFFB0-54C3-49E1-AF21-4B1CC6898D09	青岛
 select  * from  nmap_N_Company where  CompanyName ='京津冀'
  select  * from  nmap_N_Company where  CompanyName ='青岛'
select  * from  [dbo].[nmap_N_p_DevelopmentCompany] where DevelopmentCompanyName ='山东公司' 

update a set a.CompanyGUID ='B86DFFB0-54C3-49E1-AF21-4B1CC6898D09',DevelopmentCompanyGUID='48F8AD43-40A4-4471-A511-1A9D56EEB576'
--select * 
from  nmap_N_TopProject a
where   CompanyGUID = '2AFC0FB8-B63E-423C-B40D-324631563BFD'

-- 浙南公司迁移到浙江公司
6E4E5C67-4838-48D2-AA0F-B7990FAB0830	浙南公司
0884B062-1DDF-4094-9690-1D3FC29776C2	浙江
 select  * from  nmap_N_Company where  CompanyName ='浙南'
  select  * from  nmap_N_Company where  CompanyName ='浙江'
  select  * from  [dbo].[nmap_N_p_DevelopmentCompany] where DevelopmentCompanyName ='浙江公司' 

update a set a.CompanyGUID ='0884B062-1DDF-4094-9690-1D3FC29776C2',DevelopmentCompanyGUID='BDCA956B-B31D-4FEC-8992-A9898BEE4949'
--select  * 
from  nmap_N_TopProject a
where   CompanyGUID = '6E4E5C67-4838-48D2-AA0F-B7990FAB0830'

-- 长春公司迁移到辽宁公司
3BA402DA-5298-4B86-A2AB-E3867A19E978	长春
78AD7ECA-5B99-404C-8B3F-9DEA209E25DA	辽宁
 select  * from  nmap_N_Company where  CompanyName ='长春'
  select  * from  nmap_N_Company where  CompanyName ='辽宁'
    select  * from  [dbo].[nmap_N_p_DevelopmentCompany] where DevelopmentCompanyName ='东北公司' 

  update a set a.CompanyGUID ='78AD7ECA-5B99-404C-8B3F-9DEA209E25DA',DevelopmentCompanyGUID='BFAB07FD-3BE5-4543-BA33-81C07DE6A5EC'
--select  * 
from  nmap_N_TopProject a
where   CompanyGUID = '3BA402DA-5298-4B86-A2AB-E3867A19E978'


-- 大连公司迁移到辽宁公司
D9DF705D-0CDA-4E0A-992B-3EDC02F1C251	大连
78AD7ECA-5B99-404C-8B3F-9DEA209E25DA	辽宁
 select  * from  nmap_N_Company where  CompanyName ='大连'
  select  * from  nmap_N_Company where  CompanyName ='辽宁'
    select  * from  [dbo].[nmap_N_p_DevelopmentCompany] where DevelopmentCompanyName ='东北公司' 

  update a set a.CompanyGUID ='78AD7ECA-5B99-404C-8B3F-9DEA209E25DA',DevelopmentCompanyGUID='BFAB07FD-3BE5-4543-BA33-81C07DE6A5EC'
--select  * 
from  nmap_N_TopProject a
where   CompanyGUID = 'D9DF705D-0CDA-4E0A-992B-3EDC02F1C251'




		select  * from  nmap_N_Project p
		inner join ERP25.dbo.p_Project  pp on p.projguid = pp.projguid
        where p.buguid<> pp.buguid


		select  * from  nmap_N_Project p
		inner join nmap_N_TopProject  pp on p.projguid = pp.topprojguid
        inner join 
        where p.buguid<> pp.buguid

        
		update p  set 
        p.buguid = pp.buguid
        from   nmap_N_Project p
		inner join ERP25.dbo.p_Project  pp on p.projguid = pp.projguid
        where p.buguid<> pp.buguid


		select  a.projguid,a.projname,a.buguid,a.CompanyGUID,c1.CompanyName, a1.BUGUID,a1.CompanyGUID,c2.CompanyName,a2.BUGUID,a2.CompanyGUID
		from  nmap_N_Project a
		inner join  nmap_N_CompanyToBusinessUnit a1 on a1.BUGUID =a.BUGUID
        inner join nmap_N_Company c1 on a1.CompanyGUID =c1.CompanyGUID
        inner join nmap_N_CompanyToBusinessUnit a2 on a2.CompanyGUID =a1.CompanyGUID
        inner join nmap_N_Company c2 on a2.CompanyGUID =c2.CompanyGUID
        where  a1.buguid <>a2.buguid


		inner join  nmap_N_Company   b on a.CompanyGUID =b.CompanyGUID
		inner join  nmap_N_Company  bb on bb.CompanyGUID =a1.CompanyGUID
		inner join erp25.dbo.myBusinessUnit bu  on bu.BUGUID =a.BUGUID
			where a.ProjGUID='9B37F481-81E1-ED11-B3A3-F40270D39969'


      
update p  set  p.BUGUID ='2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5'
--select  * 
from nmap_N_Project  p
where  BUGUID ='31120F08-22C4-4220-8ED2-DCAD398C823C'

2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5	浙江公司
31120F08-22C4-4220-8ED2-DCAD398C823C	浙南公司
select  * from  erp25.dbo.myBusinessUnit where  BUName  in ('浙江公司','浙南公司')


289A694A-E5D1-4F02-BFEF-8510E4B6C6A0	齐鲁公司
BC0235CB-1137-4488-8192-E55DC27ACCD7	山东公司
select  * from  erp25.dbo.myBusinessUnit where  BUName  in ('齐鲁公司','山东公司')

update p  set  p.BUGUID ='BC0235CB-1137-4488-8192-E55DC27ACCD7'
--select  * 
from nmap_N_Project  p
where  BUGUID ='289A694A-E5D1-4F02-BFEF-8510E4B6C6A0'

select  * from  erp25.dbo.myBusinessUnit where  BUName  in ('长春公司','东北公司')
528CA87C-F7AF-4FDD-BD05-79641D9F67FB	东北公司
A8E2ACA1-508E-46F3-B764-8E2114255B4B	长春公司

update p  set  p.BUGUID ='528CA87C-F7AF-4FDD-BD05-79641D9F67FB'
--select  * 
from nmap_N_Project  p
where  BUGUID ='A8E2ACA1-508E-46F3-B764-8E2114255B4B'

528CA87C-F7AF-4FDD-BD05-79641D9F67FB	东北公司
CEBF9C18-CF48-49FD-B490-A86E3D9F10D4	大连公司

select  * from  erp25.dbo.myBusinessUnit where  BUName  in ('大连公司','东北公司')

update p  set  p.BUGUID ='528CA87C-F7AF-4FDD-BD05-79641D9F67FB'
--select  * 
from nmap_N_Project  p
where  BUGUID ='CEBF9C18-CF48-49FD-B490-A86E3D9F10D4'