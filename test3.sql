
-- 动态经营结果显示
-- 总收入
select projguid, '总收入' as '分项',  [总货值-立项版] as '立项', isnull(lczy.[总货值-动态版], sale.[总货值-动态版]) as '动态', isnull(已售货值,0) as '已实现', 
    case when  isnull(lczy.[总货值-动态版], sale.[总货值-动态版])  =0  then  0 else  isnull(已售货值,0) / isnull(lczy.[总货值-动态版], sale.[总货值-动态版])  end  as '已实现比例', 
    isnull(lczy.[总货值-动态版], sale.[总货值-动态版]) -  isnull(已售货值,0)   as '未来实现'
from zb_jyjhtjkb_SaleIncome sale
left join  data_tb_ylss_lczy lczy on  sale.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate} ) = 0
union all
-- 价格：住宅
select projguid, '价格：住宅' as '分项', sale.[住宅销售均价-立项版] as '立项', 
     case when isnull(lczy.[住宅总可售面积], sale.[住宅总可售面积]) =0  then 0 else  isnull(lczy.[住宅总货值金额],sale.[住宅总货值金额]) *10000.0  / isnull(lczy.[住宅总可售面积], sale.[住宅总可售面积]) end  as '动态',
    isnull(lczy.[住宅截止本月已售均价], sale.[住宅截止本月已售均价])  as '已实现', null as '已实现比例', null as '未来实现'
from zb_jyjhtjkb_SaleIncome sale
left join  data_tb_ylss_lczy lczy on  sale.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 价格：办公
select projguid, '价格：办公' as '分项', [商办销售均价-立项版] as '立项',
   case when isnull([商办总可售面积],0) =0  then 0 else  isnull([商办总货值金额],0)  *10000.0 / isnull([商办总可售面积],0) end  as '动态', 
   [商办截止本月已售均价] as '已实现', null as '已实现比例', null as '未来实现'
from zb_jyjhtjkb_SaleIncome
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 价格：商业
select projguid, '价格：商业' as '分项', [商办销售均价-立项版] as '立项',
   case when isnull([商办总可售面积],0) =0  then 0 else  isnull([商办总货值金额],0)  *10000.0 / isnull([商办总可售面积],0) end  as '动态', 
   [商办截止本月已售均价] as '已实现', null as '已实现比例', null as '未来实现'
from zb_jyjhtjkb_SaleIncome
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 车位/个
select projguid, '车位/个' as '分项', [车位销售均价-立项版] /10000.0 as '立项',
    case when  isnull([车位总可售套数],0) =0 then 0  else  isnull([车位总货值金额],0) *10000.0 / isnull([车位总可售套数],0) end as '动态', 
    [车位截止本月已售均价] /10000.0 as '已实现', 
    null as '已实现比例', null as '未来实现'
from zb_jyjhtjkb_SaleIncome
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 总投资
select projguid, '总投资' as '分项', [总投资_立项版] as '立项',isnull(lczy.[总投资-动态版], ti.[总投资_动态版]) as '动态', 
    isnull(lczy.[已发生总投资_动态版], ti.[已发生总投资_动态版]) as '已实现', 
  case when  isnull(lczy.[总投资-动态版], ti.[总投资_动态版]) =0 then 0 
       else isnull(lczy.[已发生总投资_动态版], ti.[已发生总投资_动态版]) / isnull(lczy.[总投资-动态版], ti.[总投资_动态版]) end  as '已实现比例', 
    isnull(lczy.[总投资-动态版], ti.[总投资_动态版]) - isnull(lczy.[已发生总投资_动态版], ti.[已发生总投资_动态版]) as '未来实现'
from zb_jyjhtjkb_TotalInvestment ti
left join   data_tb_ylss_lczy lczy on  Ti.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 除地价外直投
select projguid, '除地价外直投' as '分项', [除地价外直投_立项版] as '立项',isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] ) as '动态',
 isnull(lczy.[已发生除地价外直投], ti.[已发生除地价外直投]) as '已实现', 
case when  isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] )  = 0 then 0  
   else  isnull(lczy.[已发生除地价外直投], ti.[已发生除地价外直投]) / isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] )  end  as '已实现比例',
    isnull(lczy.[除地价外直投本月拍照版],ti.[除地价外直投本月拍照版] )  - isnull(lczy.[已发生除地价外直投], ti.[已发生除地价外直投])  as '未来实现'
from zb_jyjhtjkb_TotalInvestment Ti
left join   data_tb_ylss_lczy lczy on  Ti.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 财务费用(单利)
select projguid, '财务费用(单利)' as '分项', [财务费用(单利)_立项版] as '立项',isnull(lczy.[财务费用(单利)截止本月], ti.[财务费用(单利)截止本月] ) as '动态',
  isnull(lczy.[已发生财务费用（单利）],ti.[已发生财务费用（单利）]) as '已实现', 
  case when  isnull(lczy.[财务费用(单利)截止本月], ti.[财务费用(单利)截止本月] )  = 0  then  0  else   
     isnull(lczy.[已发生财务费用（单利）],ti.[已发生财务费用（单利）]) / isnull(lczy.[财务费用(单利)截止本月], ti.[财务费用(单利)截止本月] )  end as '已实现比例', 
    isnull(lczy.[财务费用(单利)截止本月], ti.[财务费用(单利)截止本月] ) - isnull(lczy.[已发生财务费用（单利）],ti.[已发生财务费用（单利）])  as '未来实现'
from zb_jyjhtjkb_TotalInvestment  Ti
left join   data_tb_ylss_lczy lczy on  Ti.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 营销费用
select projguid, '营销费用' as '分项', [营销费用_立项版] as '立项',isnull(lczy.[营销费用-动态版], ti.[营销费用_动态版]) as '动态', 
  isnull(lczy.[已发生营销费用], ti.[已发生营销费用]) as '已实现', 
  case when  isnull(lczy.[营销费用-动态版], ti.[营销费用_动态版]) =0  then  0  else isnull(lczy.[已发生营销费用], ti.[已发生营销费用]) / isnull(lczy.[营销费用-动态版], ti.[营销费用_动态版]) end  as '已实现比例', 
  isnull(lczy.[营销费用-动态版], ti.[营销费用_动态版])- isnull(lczy.[已发生营销费用], ti.[已发生营销费用])   as '未来实现'
from zb_jyjhtjkb_TotalInvestment Ti
left join   data_tb_ylss_lczy lczy on  Ti.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 管理费用
select projguid, '管理费用' as '分项',[管理费用_立项版] as '立项', isnull(lczy.[管理费用-动态版], ti.[管理费用_动态版]) as '动态',
   isnull(lczy.[已发生管理费用], ti.[已发生管理费用]) as '已实现', 
   case when  isnull(lczy.[管理费用-动态版],ti.[管理费用_动态版])  =0  then  0  else isnull(lczy.[已发生管理费用], ti.[已发生管理费用]) / isnull(lczy.[管理费用-动态版],ti.[管理费用_动态版])  end as '已实现比例', 
   isnull(lczy.[管理费用-动态版],ti.[管理费用_动态版]) - isnull(lczy.[已发生管理费用], ti.[已发生管理费用])   as '未来实现'
from zb_jyjhtjkb_TotalInvestment Ti
left join   data_tb_ylss_lczy lczy on  Ti.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 增值税及附加
select projguid, '增值税及附加' as '分项', [增值税及附加_立项版] as '立项',isnull(lczy.[增值税及附加-动态版], ti.[增值税及附加_动态版] ) as '动态', 
    isnull(lczy.[已发生增值税及附加-动态版], ti.[已发生增值税及附加-动态版])  as '已实现', 
    case when  isnull(lczy.[增值税及附加-动态版], ti.[增值税及附加_动态版])  =0  then  0  
      else isnull(lczy.[已发生增值税及附加-动态版], ti.[已发生增值税及附加-动态版]) / isnull(lczy.[增值税及附加-动态版], ti.[增值税及附加_动态版])  end as '已实现比例', 
    isnull(lczy.[待发生增值税及附加-动态版], ti.[待发生增值税及附加-动态版]) as '未来实现'
from zb_jyjhtjkb_TotalInvestment ti
left join data_tb_ylss_lczy lczy on ti.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 税前成本利润率
select projguid, '税前成本利润率' as '分项', [税前成本利润率_立项版] as '立项', isnull(lczy.[税前成本利润率-动态版], pf.[税前成本利润率_动态版] )  as '动态', null as '已实现', null as '已实现比例', null as '未来实现'
from zb_jyjhtjkb_Profit pf
left join   data_tb_ylss_lczy lczy on  pf.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 税后利润
select projguid, '税后利润' as '分项', [税后现金利润_立项版] as '立项',isnull(lczy.[税后利润-动态版], pf.[税后利润_动态版]) as '动态', [已实现税后利润_动态版] as '已实现', 
    case when  isnull(lczy.[税后利润-动态版], pf.[税后利润_动态版])  =0  then  0  else isnull([已实现税后利润_动态版],0) / isnull(lczy.[税后利润-动态版], pf.[税后利润_动态版])  end as  '已实现比例', 
   isnull(lczy.[税后利润-动态版], pf.[税后利润_动态版]) - isnull([已实现税后利润_动态版],0) as '未来实现'
from zb_jyjhtjkb_Profit pf
left join   data_tb_ylss_lczy lczy on  pf.projguid =lczy.项目GUID
WHERE DATEDIFF(DAY, 清洗日期, ${qxDate}) = 0
union all
-- 税后现金利润
select pf.projguid, '税后现金利润' as '分项',[税后现金利润_立项版]  as '立项',isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] ) as '动态', 
   isnull(pf.[已实现税后利润_动态版],0) - isnull(zc.[留存资产],0)  as '已实现', 
   case when  isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] )  =0 then 0 else  isnull(pf.[已实现税后利润_动态版],0) - isnull(zc.[留存资产],0) /  isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] )  end  as '已实现比例', 
   isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] ) - isnull(pf.[已实现税后利润_动态版],0) - isnull(zc.[留存资产],0) as '未来实现'
from zb_jyjhtjkb_Profit pf
left join   data_tb_ylss_lczy lczy on  pf.projguid =lczy.项目GUID
left join  zb_jyjhtjkb_BalanceSheet zc on pf.projguid = zc.projguid and datediff(day,pf.清洗日期,zc.清洗日期) =0
WHERE DATEDIFF(DAY, pf.清洗日期, ${qxDate}) = 0
union all
-- 税后现金利润
select pf.projguid, '持有资产' as '分项',[税后现金利润_立项版]  as '立项',isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] ) as '动态', 
   isnull(pf.[已实现税后利润_动态版],0) - isnull(zc.[留存资产],0)  as '已实现', 
   case when  isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] )  =0 then 0 else  isnull(pf.[已实现税后利润_动态版],0) - isnull(zc.[留存资产],0) /  isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] )  end  as '已实现比例', 
   isnull(lczy.[税后现金利润-动态版], pf.[税后现金利润_动态版] ) - isnull(pf.[已实现税后利润_动态版],0) - isnull(zc.[留存资产],0) as '未来实现'
from zb_jyjhtjkb_Profit pf
left join   data_tb_ylss_lczy lczy on  pf.projguid =lczy.项目GUID
left join  zb_jyjhtjkb_BalanceSheet zc on pf.projguid = zc.projguid and datediff(day,pf.清洗日期,zc.清洗日期) =0
WHERE DATEDIFF(DAY, pf.清洗日期, ${qxDate}) = 0