-- select  * from s_AreaBcFaSet  

-- 289A694A-E5D1-4F02-BFEF-8510E4B6C6A0	齐鲁公司
-- BC0235CB-1137-4488-8192-E55DC27ACCD7	山东公司

-- select  * from  s_AreaBcFaSet where BUGUID ='289A694A-E5D1-4F02-BFEF-8510E4B6C6A0'
-- select  * from [dbo].[s_AreaBcDetail]
-- select  * from  myBusinessUnit where  BUName  in ('山东公司','齐鲁公司')


-- select  *  into  s_AreaBcFaSet_bak20250425 from  s_AreaBcFaSet --where BUGUID ='289A694A-E5D1-4F02-BFEF-8510E4B6C6A0'

update a set a.BUGUID ='BC0235CB-1137-4488-8192-E55DC27ACCD7'   
from  s_AreaBcFaSet a
where BUGUID ='289A694A-E5D1-4F02-BFEF-8510E4B6C6A0'