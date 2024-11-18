select 
cb.组织架构ID 组织架构ID
,cb.组织架构名称 组织架构名称
,cb.组织架构类型 组织架构类型
,cb.组织架构编码 组织架构编码
,isnull(cb.目标成本,0) 目标成本
,ISNULL(目标成本直投, 0) 目标成本直投
,ISNULL(目标成本除地价外直投, 0) 目标成本除地价外直投
,ISNULL(目标成本营销费用, 0) 目标成本营销费用
,ISNULL(目标成本管理费用, 0) 目标成本管理费用
,ISNULL(目标成本财务费用, 0) 目标成本财务费用  
,ISNULL(动态成本, 0) 动态成本
,ISNULL(动态成本直投, 0) 动态成本直投
,ISNULL(动态成本除地价外直投, 0) 动态成本除地价外直投
,ISNULL(动态成本营销费用, 0) 动态成本营销费用
,ISNULL(动态成本管理费用, 0) 动态成本管理费用
,ISNULL(动态成本财务费用, 0) 动态成本财务费用 
,ISNULL(年初目标成本, 0) 年初目标成本
,ISNULL(年初目标成本直投, 0) 年初目标成本直投
,ISNULL(年初目标成本除地价外直投, 0) 年初目标成本除地价外直投
,ISNULL(年初目标成本营销费用, 0) 年初目标成本营销费用
,ISNULL(年初目标成本管理费用, 0) 年初目标成本管理费用
,ISNULL(年初目标成本财务费用, 0) 年初目标成本财务费用  
from ydkb_dthz_wq_deal_cbinfo cb
where cb.组织架构类型 <> 4
union all 
select 
bi.组织架构ID 组织架构ID
,bi.组织架构名称 组织架构名称
,4 组织架构类型
,bi.组织架构编码 组织架构编码
,isnull(cb.目标成本,0) 目标成本
,ISNULL(目标成本直投, 0) 目标成本直投
,ISNULL(目标成本除地价外直投, 0) 目标成本除地价外直投
,ISNULL(目标成本营销费用, 0) 目标成本营销费用
,ISNULL(目标成本管理费用, 0) 目标成本管理费用
,ISNULL(目标成本财务费用, 0) 目标成本财务费用  
,ISNULL(动态成本, 0) 动态成本
,ISNULL(动态成本直投, 0) 动态成本直投
,ISNULL(动态成本除地价外直投, 0) 动态成本除地价外直投
,ISNULL(动态成本营销费用, 0) 动态成本营销费用
,ISNULL(动态成本管理费用, 0) 动态成本管理费用
,ISNULL(动态成本财务费用, 0) 动态成本财务费用 
,ISNULL(年初目标成本, 0) 年初目标成本
,ISNULL(年初目标成本直投, 0) 年初目标成本直投
,ISNULL(年初目标成本除地价外直投, 0) 年初目标成本除地价外直投
,ISNULL(年初目标成本营销费用, 0) 年初目标成本营销费用
,ISNULL(年初目标成本管理费用, 0) 年初目标成本管理费用
,ISNULL(年初目标成本财务费用, 0) 年初目标成本财务费用 
from ydkb_dthz_wq_deal_cbinfo cb
inner join [172.16.4.161].highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization bi on cb.组织架构名称 = bi.组织架构名称
and cb.组织架构父级id = bi.组织架构父级id 
where cb.组织架构类型 =4 and bi.组织架构类型 = 4
 
