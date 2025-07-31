-- 统计400万以上招标项目明细
select
  distinct bu.buname as 平台公司,
  c.ContractCode as 合同编号,
  c.contractname as 合同名称,
  pp.ProjName as 所属项目,
  convert(decimal(18, 2), c.htamount / 10000.0) as [合同金额(万元)],
  convert(varchar(7), c.signdate, 121) as [签约时间(年月)],
  case
    when isnull(c.BfProviderName, '') <> '' then c.YfProviderName + ';' + c.BfProviderName
    else c.YfProviderName
  end as 签约供应商名称,
  c.jfProviderName as 招标主体名称,
  c.ProjectNameList as 招标项目或标段名称,
  null as 项目组织形式,
  -- 委托代理机构名称（如有）
  c.[SignMode] as 采购方式,
  convert(decimal(18, 2), win.WinBidPrice / 10000.0) as [定标金额(万元)],
  convert(varchar(7), win.SJWCConfirmBidDate, 121) as [定标时间(年月)],
  win.ProviderName as 中标供应商名称
from
  cb_contract c
  inner join cb_contractproj cp on c.contractguid = cp.contractguid
  inner join p_project p on p.ProjGUID = cp.ProjGUID
  and p.level = 3
  inner join p_project pp on pp.projcode = p.ParentCode
  inner join dbo.[myBusinessUnit] bu on bu.buguid = c.buguid
  left join (
    select
      c2c.Contract2CgProcGUID,
      crb.ProviderGUID,
      p.providername as ProviderName,
      WinBidPrice,
      slt.SJWCConfirmBidDate
    from
      cg_Contract2CgProc c2c
      inner join cg_CgSolution slt on c2c.CgSolutionGUID = slt.CgSolutionGUID
      inner join Cg_CgProcReturnBid crb on c2c.CgSolutionGUID = crb.CgSolutionGUID
      left join p_Provider p on p.ProviderGUID = crb.ProviderGUID
    where
      isnull(crb.IsZF, '否') not in ('是', '1')
      and crb.WinBid = 1
  ) win on c.Contract2CgProcGUID = win.Contract2CgProcGUID
where
  c.[ApproveState] = '已审核'
  and c.BfProviderName is not null
  and IfDdhs <> 0
  and c.htamount > 4000000.0
  and  year(c.signdate) >=2013
  -- and c.contractcode ='武汉保利新武昌合20180151'
order by
  bu.buname,
  pp.ProjName,
  c.[SignMode] desc 
  
  
  --   select Contract2CgProcGUID, * from  cb_contract
  -- select * from  cg_Contract2CgProc where  Contract2CgProcGUID ='07F46289-6C40-EB11-B398-F40270D39969'
  --   select SJWCConfirmBidDate from  cg_CgSolution
  -- select IsZF,WinBid,WinBidPrice,ProviderGUID,* from  Cg_CgProcReturnBid where isnull(IsZF,'否') not in ('是','1') and CgSolutionGUID ='54846033-B45E-EA11-A6CC-005056AC55B5'
  -- select  * from p_Provider where  ProviderGUID='94DC3AB2-84D2-4906-8BBF-E152E73B0FEF'
  --   select  * from p_Provider where  ProviderGUID='94DC3AB2-84D2-4906-8BBF-E152E73B0FEF'
  -- select SJWCConfirmBidDate from  cg_CgSolution