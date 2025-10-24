select  a.BUGUID,count(1)
--a.BUGUID,con.BUGUID,c.ContractGUID
from cb_BLRepayBatch  a
inner join  cb_BLRepayBatchDtl b on a.BLRepayBatchGUID =b.BLRepayBatchGUID
--inner join  cb_BLFKApply b on a.BLRepayBatchGUID =b.BLRepayBatchGUID
--left join cb_BLFKApplyDtl c on c.BLFKApplyGUID =b.BLFKApplyGUID
left join cb_Contract con on con.ContractGUID =b.ContractGUID
where  --a.BLRepayBatchGUID ='08B644BF-307D-4F90-978C-001FD996C6DE'  and 
a.BUGUID <>con.BUGUID
group by  a.BUGUID

select * into cb_BLRepayBatch_bak20250423 from  cb_BLRepayBatch

update a  
set  a.BUGUID = con.BUGUID
from cb_BLRepayBatch  a
inner join  cb_BLRepayBatchDtl b on a.BLRepayBatchGUID =b.BLRepayBatchGUID
left join cb_Contract con on con.ContractGUID =b.ContractGUID
where a.BUGUID <>con.BUGUID