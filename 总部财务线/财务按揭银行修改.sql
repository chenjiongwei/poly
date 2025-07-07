select  * from  es_Contract where RoomInfo ='揭阳市产业园区玉都项目-二期-A6栋-高层住宅-2-2601' and  Status ='激活'

39B2BF62-E8A7-EF11-B3A5-F40270D39969

744E2D57-43B5-4E26-BC51-BEE39AA9782B

select * from s_Getin where  SaleGUID ='744E2D57-43B5-4E26-BC51-BEE39AA9782B'

select  * from s_Voucher where  SaleGUID ='744E2D57-43B5-4E26-BC51-BEE39AA9782B' 

select ajbank,v.VouchType,g.SaleGUID,g.SaleType,v.VouchGUID, * 
from  s_Getin g 
inner join  s_Voucher v on g.VouchGUID =v.VouchGUID
where  g.SaleGUID ='744E2D57-43B5-4E26-BC51-BEE39AA9782B'  and  isnull(ajbank,'')<>'' and  g.SaleType ='交易'

select  
a.RoomGUID,a.ProjGUID,a.BUGUID,a.TradeGUID,a.CstName,a.RoomInfo,b.[商贷银行],b.[商贷支行]
into #UpdateAjbank
from  es_Contract a
inner join  [待修改房间] b on a.RoomInfo =b.[房间信息]
where  a.Status ='激活'


--drop   table #UpdateAjbank
 
 select  RoomInfo from #UpdateAjbank group by RoomGUID having count(1)>1

 --揭阳市产业园区玉都项目-二期-A6栋-高层住宅-2-301

select  v.* into s_Voucher_bak20250520
--
select aj.RoomInfo, ajbank,aj.[商贷支行],v.VouchType,g.SaleGUID,g.SaleType,v.VouchGUID
from  s_Getin g 
inner join  s_Voucher v on g.VouchGUID =v.VouchGUID
inner  join  #UpdateAjbank aj on aj.TradeGUID =g.SaleGUID
where     g.SaleGUID ='73A1458C-CF25-484B-96F2-8E0E2E6AD345'
order by aj.RoomInfo

农商银行揭东支行


update v set  v.ajbank =aj.商贷支行
--select aj.RoomInfo, ajbank,aj.[商贷支行],v.VouchType,g.SaleGUID,g.SaleType,v.VouchGUID
from  s_Getin g 
inner join  s_Voucher v on g.VouchGUID =v.VouchGUID
inner  join  #UpdateAjbank aj on aj.TradeGUID =g.SaleGUID
where   isnull(ajbank,'')<>'' and  g.SaleType ='交易' and ajbank <>  aj.[商贷支行]
