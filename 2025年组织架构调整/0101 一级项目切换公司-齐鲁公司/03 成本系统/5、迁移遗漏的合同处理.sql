select
    *
from
    cb_contract
where
    contractcode = '温州市瓯海区绿轴G41c地块合2025-0017'
    and contractname = '温州市天珺项目大区精装修工程承包合同'
select
    *
from
    [dbo].[myBusinessUnit]
where
    buguid = '31120F08-22C4-4220-8ED2-DCAD398C823C' -- 浙南公司

-- 将迁移遗漏的合同迁移到对应正确的公司
    declare @oldBuGuid varchar(50) 
    declare @newBuGuid varchar(50)
select
    @oldBuGuid = buguid
from
    myBusinessUnit
where
    buname = '浙南公司';

select
    @newBuGuid = buguid
from
    myBusinessUnit
where
    buname = '浙江公司';

-- 1、备份合同
select
    * into cb_contract_bak20250811_zn
from  cb_contract
where
    buguid = @oldBuGuid 

-- 迁移合同
    -- 修改所属公司

-- 将迁移遗漏的合同迁移到对应正确的公司
    declare @oldBuGuid varchar(50) 
    declare @newBuGuid varchar(50)
select
    @oldBuGuid = buguid
from
    myBusinessUnit
where
    buname = '浙南公司';

select
    @newBuGuid = buguid
from
    myBusinessUnit
where
    buname = '浙江公司';

update a
set
    a.buguid = @newBuGuid,
    deptguid = @newBuGuid
from
    cb_contract a
    inner join  cb_contract_bak20250811_zn b on a.contractguid =b.contractguid
where buguid = @oldBuGuid -- 修改合同类别信息


-- 修改合同类别
-- 备份
   select  a.* into  cb_Contract2HTType_bak20250811_zn from  cb_Contract2HTType a
    inner join cb_contract_bak20250811_zn b on a.contractguid =b.contractguid


	update b set b.buguid =a.buguid ,b.httypeguid =d.httypeguid
	--select b.*
	from  cb_contract a
	inner join  [dbo].[cb_Contract2HTType] b on a.contractguid =b.contractguid
	inner join  cb_httype c on c.httypeguid =b.httypeguid
	inner join  cb_httype d on d.httypecode =c.httypecode and  d.buguid =a.buguid
    inner join cb_contract_bak20250811_zn zn on zn.contractguid=a.contractguid
	where
    a.contractcode = '温州市瓯海区绿轴G41c地块合2025-0017'
    and a.contractname = '温州市天珺项目大区精装修工程承包合同'


-- 备份
	select a.* into cg_Contract2CgProc_bak20250811_zn
     from  cg_Contract2CgProc a
	inner join cb_contract_bak20250811_zn b on a.Contract2CgProcGUID =b.Contract2CgProcGUID


-- 修改
    declare @oldBuGuid varchar(50) 
    declare @newBuGuid varchar(50)
    select  @oldBuGuid = buguid from myBusinessUnit where  buname = '浙南公司';
    select @newBuGuid = buguid from myBusinessUnit where buname = '浙江公司';

   --备份
	select  c.* into  cg_CgSolution_bak20250811_zn 
     from  cg_Contract2CgProc a
	inner join cb_contract_bak20250811_zn b on a.Contract2CgProcGUID =b.Contract2CgProcGUID
	inner join cg_CgSolution c on c.[CgSolutionGUID] =a.[CgSolutionGUID]

    --更改
    update c set c.buguid = @newBuGuid
     from  cg_Contract2CgProc a
	inner join cb_contract_bak20250811_zn b on a.Contract2CgProcGUID =b.Contract2CgProcGUID
	inner join cg_CgSolution c on c.[CgSolutionGUID] =a.[CgSolutionGUID]
    where c.buguid =@oldBuGuid



    --备份
	select a.* into cg_CgPlan_bak20250811_zn  from cg_CgPlan a
	inner join cg_CgSolutionLinkedPlan b on b.CgPlanAdjustGUID =a.CgPlanAdjustGUID
	inner join  cg_CgSolution_bak20250811_zn c on c.CgSolutionGUID =b.CgSolutionGUID

    declare @oldBuGuid varchar(50) 
    declare @newBuGuid varchar(50)
    select  @oldBuGuid = buguid from myBusinessUnit where  buname = '浙南公司';
    select @newBuGuid = buguid from myBusinessUnit where buname = '浙江公司';

    update a set a.buguid = @newBuGuid
    -- select a.* into cg_CgPlan_bak20250811_zn  
    from cg_CgPlan a
	inner join cg_CgSolutionLinkedPlan b on b.CgPlanAdjustGUID =a.CgPlanAdjustGUID
	inner join  cg_CgSolution_bak20250811_zn c on c.CgSolutionGUID =b.CgSolutionGUID
     where a.buguid =@oldBuGuid