/*==============================================================*/
/* DBMS name:      Microsoft SQL Server 2012                    */
/* Created on:     2025/11/24 10:33:59                          */
/*==============================================================*/


if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_bldinfo_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_bldinfo_history
go

if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_cbinfo_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_cbinfo_history
go

if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_cbzf_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_cbzf_history
go

if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_ldjd_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_ldjd_history
go

if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_productinfo_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_productinfo_history
go

if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_projinfo_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_projinfo_history
go

if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_stageinfo_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_stageinfo_history
go

if exists (select 1
            from  sysobjects
           where  id = object_id('data_wide_ylgh_jk_yxfy_history')
            and   type = 'U')
   drop table data_wide_ylgh_jk_yxfy_history
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_bldinfo_history                     */
/*==============================================================*/
create table data_wide_ylgh_jk_bldinfo_history (
   versionGUID                uniqueidentifier     null,
   version_name                 nvarchar(200)        null,
   master_data_version                nvarchar(200)        null,
   projectname                 nvarchar(200)        null,
   projectguid               uniqueidentifier     null,
   stageguid               uniqueidentifier     null,
   productbuildingname               nvarchar(200)        null,
   productbuildingguid             uniqueidentifier     null,
   productbuildingcode               nvarchar(200)        null,
   commoditytype                 nvarchar(200)        null,
   decorationstandard                 nvarchar(200)        null,
   cost_business_type_name               nvarchar(200)        null,
   is_saleable                 nvarchar(20)         null,
   is_held                 nvarchar(20)         null,
   engineeringbuildingname               nvarchar(200)        null,
   engineeringbuildingguid           uniqueidentifier     null,
   business_attribute                 nvarchar(200)        null,
   deallocation_ratio                 decimal(32,10)       null,
   producttype                 nvarchar(200)        null,
   producttype_guid             uniqueidentifier     null,
   productname                 nvarchar(200)        null,
   productguid               uniqueidentifier     null,
   is_parking_space                 nvarchar(20)         null,
   batch_name                 nvarchar(20)         null,
   building_area                 decimal(32,10)       null,
   saleable_area                 decimal(32,10)       null,
   aboveground_building_area               decimal(32,10)       null,
   underground_building_area               decimal(32,10)       null,
   calculated_area                 decimal(32,10)       null,
   calculated_saleable_area               decimal(32,10)       null,
   self_held_area                 decimal(32,10)       null,
   self_held_parking_count               int                  null,
   saleable_parking_count               int                  null,
   total_parking_count                 int                  null,
   unit_count                   int                  null,
   aboveground_floors                 int                  null,
   underground_floors                 int                  null,
   total_saleable_area                decimal(32,10)       null,
   aboveground_saleable_area               decimal(32,10)       null,
   underground_saleable_area               decimal(32,10)       null,
   aboveground_parking_count                int                  null,
   underground_parking_count                int                  null,
   interior_area                 decimal(32,10)       null,
   delivery_date                 datetime             null,
   sales_building_name               nvarchar(200)        null,
   year                   int                  null,
   month                   int                  null,
   contract_year_month                 nvarchar(20)         null,
   current_month_contract_area               decimal(32,10)       null,
   current_month_contract_amount               decimal(32,10)       null,
   current_month_contract_avg_price               decimal(32,10)       null,
   current_month_contract_count               int                  null,
   collection_year_month                 nvarchar(20)         null,
   current_month_sold_collected_amount            decimal(32,10)       null,
   current_month_non_loan_unpaid_amount        decimal(32,10)       null,
   current_month_loan_provident_fund_unpaid_amount      decimal(32,10)       null,
   current_month_loan_mortgage_unpaid_amount       decimal(32,10)       null,
   current_month_cooperation_collected_amount           decimal(32,10)       null,
   current_month_special_performance_collected_amount           decimal(32,10)       null,
   current_month_sold_unpaid_amount            decimal(32,10)       null,
   
   transfer_year_month                 nvarchar(20)         null,
   current_month_transfer_area               decimal(32,10)       null,
   current_month_transfer_amount               decimal(32,10)       null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_bldinfo_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '用途：产品楼栋的基础信息、指标信息
   重点维度：项目、分期、产品名称、年月
   重点指标：建筑面积、可售面积、签约面积、签约金额、回笼金额、已售未回金额、结转面积、结转金额', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '版本表主键', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '主数据版本', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'master_data_version'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '项目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '分期GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'stage_guid'
execute sp_addextendedproperty 'MS_Description', '产品楼栋名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'product_building_name'
execute sp_addextendedproperty 'MS_Description', '产品楼栋GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'product_building_guid'
execute sp_addextendedproperty 'MS_Description', '产品楼栋编码', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'product_building_code'
execute sp_addextendedproperty 'MS_Description', '商品类型', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'commodity_type'
execute sp_addextendedproperty 'MS_Description', '装修标准', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'decoration_standard'
execute sp_addextendedproperty 'MS_Description', '成本业态名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'cost_business_type_name'
execute sp_addextendedproperty 'MS_Description', '是否可售', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'is_saleable'
execute sp_addextendedproperty 'MS_Description', '是否持有', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'is_held'
execute sp_addextendedproperty 'MS_Description', '所属工程楼栋', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'engineering_building_name'
execute sp_addextendedproperty 'MS_Description', '所属工程楼栋GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'engineering_building_guid'
execute sp_addextendedproperty 'MS_Description', '经营属性', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'business_attribute'
execute sp_addextendedproperty 'MS_Description', '去化比例', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'deallocation_ratio'
execute sp_addextendedproperty 'MS_Description', '产品类型', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'product_type'
execute sp_addextendedproperty 'MS_Description', '产品类型GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'product_type_guid'
execute sp_addextendedproperty 'MS_Description', '产品名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'product_name'
execute sp_addextendedproperty 'MS_Description', '产品GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'product_guid'
execute sp_addextendedproperty 'MS_Description', '是否车位', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'is_parking_space'
execute sp_addextendedproperty 'MS_Description', '所属批次', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'batch_name'
execute sp_addextendedproperty 'MS_Description', '建筑面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'building_area'
execute sp_addextendedproperty 'MS_Description', '可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'saleable_area'
execute sp_addextendedproperty 'MS_Description', '地上建筑面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'aboveground_building_area'
execute sp_addextendedproperty 'MS_Description', '地下建筑面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'underground_building_area'
execute sp_addextendedproperty 'MS_Description', '计容面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'calculated_area'
execute sp_addextendedproperty 'MS_Description', '计容可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'calculated_saleable_area'
execute sp_addextendedproperty 'MS_Description', '自持面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'self_held_area'
execute sp_addextendedproperty 'MS_Description', '自持车位个数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'self_held_parking_count'
execute sp_addextendedproperty 'MS_Description', '可售车位个数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'saleable_parking_count'
execute sp_addextendedproperty 'MS_Description', '总车位数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'total_parking_count'
execute sp_addextendedproperty 'MS_Description', '套数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'unit_count'
execute sp_addextendedproperty 'MS_Description', '地上层数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'aboveground_floors'
execute sp_addextendedproperty 'MS_Description', '地下层数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'underground_floors'
execute sp_addextendedproperty 'MS_Description', '总可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'total_saleable_area'
execute sp_addextendedproperty 'MS_Description', '地上可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'aboveground_saleable_area'
execute sp_addextendedproperty 'MS_Description', '地下可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'underground_saleable_area'
execute sp_addextendedproperty 'MS_Description', '地上车位数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'aboveground_parking_count'
execute sp_addextendedproperty 'MS_Description', '地下车位数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'underground_parking_count'
execute sp_addextendedproperty 'MS_Description', '套内面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'interior_area'
execute sp_addextendedproperty 'MS_Description', '交房日期', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'delivery_date'
execute sp_addextendedproperty 'MS_Description', '销售楼栋名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'sales_building_name'
execute sp_addextendedproperty 'MS_Description', '年份', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'year'
execute sp_addextendedproperty 'MS_Description', '月份', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'month'
execute sp_addextendedproperty 'MS_Description', '签约年月', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'contract_year_month'
execute sp_addextendedproperty 'MS_Description', '本月签约面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_contract_area'
execute sp_addextendedproperty 'MS_Description', '本月签约金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_contract_amount'
execute sp_addextendedproperty 'MS_Description', '本月签约均价', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_contract_avg_price'
execute sp_addextendedproperty 'MS_Description', '本月签约套数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_contract_count'
execute sp_addextendedproperty 'MS_Description', '回笼年月', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'collection_year_month'
execute sp_addextendedproperty 'MS_Description', '本月已售已回笼金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_sold_collected_amount'
execute sp_addextendedproperty 'MS_Description', '本月非贷款类已售未回款金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_non_loan_unpaid_amount'
execute sp_addextendedproperty 'MS_Description', '本月贷款类公积金已售未回款金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_loan_provident_fund_unpaid_amount'
execute sp_addextendedproperty 'MS_Description', '本月贷款类按揭已售未回款金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_loan_mortgage_unpaid_amount'
execute sp_addextendedproperty 'MS_Description', '本月合作项目回笼金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_cooperation_collected_amount'
execute sp_addextendedproperty 'MS_Description', '本月特殊业绩回笼金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_special_performance_collected_amount'
execute sp_addextendedproperty 'MS_Description', '本月已售未回款金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_sold_unpaid_amount'
execute sp_addextendedproperty 'MS_Description', '结转年月', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'transfer_year_month'
execute sp_addextendedproperty 'MS_Description', '本月结转面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_transfer_area'
execute sp_addextendedproperty 'MS_Description', '本月结转金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_bldinfo_history', 'column', 'current_month_transfer_amount'
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_cbinfo_history                      */
/*==============================================================*/
create table data_wide_ylgh_jk_cbinfo_history (
   VersionGUID                uniqueidentifier     null,
   version_name                 nvarchar(200)        null,
   project_name                 nvarchar(200)        null,
   project_guid               uniqueidentifier     null,
   stage_name                 nvarchar(200)        null,
   stage_guid               uniqueidentifier     null,
   subject_level                 nvarchar(200)        null,
   subject_code                 nvarchar(200)        null,
   subject_name                 nvarchar(200)        null,
   subject_encoding                 nvarchar(200)        null,
   subject_guid               uniqueidentifier     null,
   indicator_type                 nvarchar(200)        null,
   indicator_value                  decimal(32,10)       null,
   coefficient                   decimal(32,10)       null,
   workload                  decimal(32,10)       null,
   target_unit_price                 decimal(32,10)       null,
   deductible_tax_rate                decimal(32,10)       null,
   input_tax_amount                 decimal(32,10)       null,
   cost_excluding_tax              decimal(32,10)       null,
   total_input_tax                decimal(32,10)       null,
   building_unit_price_excluding_deductible_tax          decimal(32,10)       null,
   saleable_unit_price_excluding_deductible_tax          decimal(32,10)       null,
   target_cost_including_tax              decimal(32,10)       null,
   target_cost_excluding_tax             decimal(32,10)       null,
   dynamic_cost_audit_status             nvarchar(20)         null,
   dynamic_cost_version              nvarchar(200)        null,
   dynamic_cost_review_date             datetime             null,
   dynamic_cost_filler              nvarchar(200)        null,
   dynamic_cost_excluding_tax             decimal(32,10)       null,
   dynamic_cost_including_tax              decimal(32,10)       null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_cbinfo_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '分期科目目标动态成本表
   用途：项目分期科目的成本（目标成本、动态成本）
   重点维度：项目、分期、科目
   重点指标：目标成本、动态成本', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '版本表主键', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '项目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '分期名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'stage_name'
execute sp_addextendedproperty 'MS_Description', '分期GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'stage_guid'
execute sp_addextendedproperty 'MS_Description', '科目级别', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'subject_level'
execute sp_addextendedproperty 'MS_Description', '科目代码', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'subject_code'
execute sp_addextendedproperty 'MS_Description', '科目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'subject_name'
execute sp_addextendedproperty 'MS_Description', '科目编码', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'subject_encoding'
execute sp_addextendedproperty 'MS_Description', '科目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'subject_guid'
execute sp_addextendedproperty 'MS_Description', '指标类型', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'indicator_type'
execute sp_addextendedproperty 'MS_Description', '指标值', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'indicator_value'
execute sp_addextendedproperty 'MS_Description', '系数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'coefficient'
execute sp_addextendedproperty 'MS_Description', '工作量', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'workload'
execute sp_addextendedproperty 'MS_Description', '目标单价', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'target_unit_price'
execute sp_addextendedproperty 'MS_Description', '可抵扣税率', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'deductible_tax_rate'
execute sp_addextendedproperty 'MS_Description', '进项税额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'input_tax_amount'
execute sp_addextendedproperty 'MS_Description', '不含税成本合价', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'cost_excluding_tax'
execute sp_addextendedproperty 'MS_Description', '进项税合计', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'total_input_tax'
execute sp_addextendedproperty 'MS_Description', '建筑单方_不含可抵扣税', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'building_unit_price_excluding_deductible_tax'
execute sp_addextendedproperty 'MS_Description', '可售单方_不含可抵扣税', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'saleable_unit_price_excluding_deductible_tax'
execute sp_addextendedproperty 'MS_Description', '目标成本_含税', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'target_cost_including_tax'
execute sp_addextendedproperty 'MS_Description', '目标成本_不含税', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'target_cost_excluding_tax'
execute sp_addextendedproperty 'MS_Description', '动态成本审核状态', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'dynamic_cost_audit_status'
execute sp_addextendedproperty 'MS_Description', '动态成本版本号', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'dynamic_cost_version'
execute sp_addextendedproperty 'MS_Description', '动态成本回顾日期', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'dynamic_cost_review_date'
execute sp_addextendedproperty 'MS_Description', '动态成本填表人', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'dynamic_cost_filler'
execute sp_addextendedproperty 'MS_Description', '动态成本_不含税', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'dynamic_cost_excluding_tax'
execute sp_addextendedproperty 'MS_Description', '动态成本_含税', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbinfo_history', 'column', 'dynamic_cost_including_tax'
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_cbzf_history                        */
/*==============================================================*/
create table data_wide_ylgh_jk_cbzf_history (
   VersionGUID                uniqueidentifier     null,
   version_name                 nvarchar(200)        null,
   project_name                 nvarchar(200)        null,
   project_guid               uniqueidentifier     null,
   stage_name                 nvarchar(200)        null,
   stage_guid               uniqueidentifier     null,
   subject_name                 nvarchar(200)        null,
   subject_number                 nvarchar(200)        null,
   subject_level                 int                  null,
   actual_payment_amount                 decimal(32,10)       null,
   actual_payment_year                  int                  null,
   actual_payment_month                  int                  null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_cbzf_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '土地成本与除地价外直投实付
   用途：项目分期科目的除地价外直投支付（实际）、土地成本支付
   重点维度：项目
   重点指标：支付金额', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '版本表主键', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '项目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '分期名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'stage_name'
execute sp_addextendedproperty 'MS_Description', '分期GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'stage_guid'
execute sp_addextendedproperty 'MS_Description', '科目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'subject_name'
execute sp_addextendedproperty 'MS_Description', '科目编号', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'subject_number'
execute sp_addextendedproperty 'MS_Description', '科目层级', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'subject_level'
execute sp_addextendedproperty 'MS_Description', '实付金额', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'actual_payment_amount'
execute sp_addextendedproperty 'MS_Description', '实付年', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'actual_payment_year'
execute sp_addextendedproperty 'MS_Description', '实付月', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_cbzf_history', 'column', 'actual_payment_month'
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_ldjd_history                        */
/*==============================================================*/
create table data_wide_ylgh_jk_ldjd_history (
   VersionGUID                uniqueidentifier     null,
   version_name                 nvarchar(200)        null,
   projectname                 nvarchar(200)        null,
   projectguid               uniqueidentifier     null,
   stagename                 nvarchar(200)        null,
   stageguid               uniqueidentifier     null,
   productbuildingname               nvarchar(200)        null,
   productbuildingguid             uniqueidentifier     null,
   project_acquisition_time               datetime             null,
   is_launched                nvarchar(20)         null,
   launched_area                 decimal(32,10)       null,
   node_planned_completion_date             datetime             null,
   node_estimated_completion_date             datetime             null,
   node_actual_completion_date             datetime             null,
   node_name                 nvarchar(200)        null,
   node_completion_date               datetime             null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_ldjd_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '用途：产品楼栋的进度节点信息
   重点维度：项目、分期、产品楼栋、节点名称
   重点指标：节点完成日期', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '版本表主键', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '项目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '分期名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'stage_name'
execute sp_addextendedproperty 'MS_Description', '分期GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'stage_guid'
execute sp_addextendedproperty 'MS_Description', '产品楼栋名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'product_building_name'
execute sp_addextendedproperty 'MS_Description', '产品楼栋GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'product_building_guid'
execute sp_addextendedproperty 'MS_Description', '项目获取时间', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'project_acquisition_time'
execute sp_addextendedproperty 'MS_Description', '是否已推售', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'is_launched'
execute sp_addextendedproperty 'MS_Description', '已推面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'launched_area'
execute sp_addextendedproperty 'MS_Description', '节点计划完成日期', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'node_planned_completion_date'
execute sp_addextendedproperty 'MS_Description', '节点预计完成日期', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'node_estimated_completion_date'
execute sp_addextendedproperty 'MS_Description', '节点实际完成日期', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'node_actual_completion_date'
execute sp_addextendedproperty 'MS_Description', '节点名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'node_name'
execute sp_addextendedproperty 'MS_Description', '节点完成日期', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_ldjd_history', 'column', 'node_completion_date'
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_productinfo_history                 */
/*==============================================================*/
create table data_wide_ylgh_jk_productinfo_history (
   VersionGUID                uniqueidentifier     null,
   version_name                 nvarchar(200)        null,
   master_data_version                nvarchar(200)        null,
   projectguid               uniqueidentifier     null,
   projectcode                 nvarchar(200)        null,
   projectname                 nvarchar(200)        null,
   productname                 nvarchar(200)        null,
   producttype                 nvarchar(200)        null,
   floorcount                   int                  null,
   land_area                 decimal(32,10)       null,
   building_area                 decimal(32,10)       null,
   aboveground_building_area                 decimal(32,10)       null,
   underground_building_area                 decimal(32,10)       null,
   calculated_area                 decimal(32,10)       null,
   floor_area_ratio                  decimal(32,10)       null,
   saleable_area_including_parking             decimal(32,10)       null,
   saleable_area_excluding_parking            decimal(32,10)       null,
   aboveground_saleable_area_excluding_parking          decimal(32,10)       null,
   calculated_saleable_area               decimal(32,10)       null,
   product_ratio                 decimal(32,10)       null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_productinfo_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '用途：产品基础信息、产品指标信息
   重点维度：项目、分期、产品名称
   重点指标：建筑面积、可售面积', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '版本表主键', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '主数据版本', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'master_data_version'
execute sp_addextendedproperty 'MS_Description', '项目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '项目编号', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'project_code'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '产品名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'product_name'
execute sp_addextendedproperty 'MS_Description', '产品类型', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'product_type'
execute sp_addextendedproperty 'MS_Description', '层数', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'floor_count'
execute sp_addextendedproperty 'MS_Description', '用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'land_area'
execute sp_addextendedproperty 'MS_Description', '建筑面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'building_area'
execute sp_addextendedproperty 'MS_Description', '地上建面', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'aboveground_building_area'
execute sp_addextendedproperty 'MS_Description', '地下建面', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'underground_building_area'
execute sp_addextendedproperty 'MS_Description', '计容面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'calculated_area'
execute sp_addextendedproperty 'MS_Description', '容积率', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'floor_area_ratio'
execute sp_addextendedproperty 'MS_Description', '可售面积_含车位', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'saleable_area_including_parking'
execute sp_addextendedproperty 'MS_Description', '可售面积_不含车位', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'saleable_area_excluding_parking'
execute sp_addextendedproperty 'MS_Description', '地上可售面积_不含车位', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'aboveground_saleable_area_excluding_parking'
execute sp_addextendedproperty 'MS_Description', '计容可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'calculated_saleable_area'
execute sp_addextendedproperty 'MS_Description', '产品比例', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_productinfo_history', 'column', 'product_ratio'
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_projinfo_history                    */
/*==============================================================*/
create table data_wide_ylgh_jk_projinfo_history (
   VersionGUID                uniqueidentifier     null,
   version_name                 nvarchar(200)        null,
   master_data_version                nvarchar(200)        null,
   companyname                 nvarchar(200)        null,
   companyguid               uniqueidentifier     null,
   projectguid               uniqueidentifier     null,
   investment_management_code                 nvarchar(200)        null,
   projectcode                 nvarchar(200)        null,
   projectname                 nvarchar(200)        null,
   land_parcel                 nvarchar(200)        null,
   acquisitiontime                 datetime             null,
   acquisitionmethod                 nvarchar(200)        null,
   land_nature                 nvarchar(200)        null,
   is_bottom_price_acquisition               nvarchar(200)        null,
   floor_price                 decimal(32,10)       null,
   total_acquisition_cost                decimal(32,10)       null,
   project_equity_ratio               decimal(32,10)       null,
   operation_method                 nvarchar(200)        null,
   consolidation_method                 nvarchar(200)        null,
   project_status                 nvarchar(200)        null,
   SpreadName                nvarchar(200)        null,
   project_company                 nvarchar(200)        null,
   management_method                 nvarchar(200)        null,
   DevelopmentCompanyName                 nvarchar(200)        null,
   city                   nvarchar(200)        null,
   city_category                 nvarchar(200)        null,
   sales_status                 nvarchar(200)        null,
   stage_count                 int                  null,
   building_count                 int                  null,
   total_land_area                decimal(32,10)       null,
   total_building_area                decimal(32,10)       null,
   aboveground_building_area               decimal(32,10)       null,
   underground_building_area               decimal(32,10)       null,
   basement_ratio                decimal(32,10)       null,
   calculated_area                 decimal(32,10)       null,
   floor_area_ratio                  decimal(32,10)       null,
   net_land_area                decimal(32,10)       null,
   total_saleable_area                decimal(32,10)       null,
   aboveground_saleable_area                 decimal(32,10)       null,
   total_calculated_saleable_area              decimal(32,10)       null,
   non_calculated_saleable_area              decimal(32,10)       null,
   greening_rate                decimal(32,10)       null,
   greening_area               decimal(32,10)       null,
   building_density                 decimal(32,10)       null,
   unit_area_below_90_sqm            decimal(32,10)       null,
   building_base_area               decimal(32,10)       null,
   garden_non_display_area             decimal(32,10)       null,
   garden_display_area              decimal(32,10)       null,
   redline_urban_other_land_area          decimal(32,10)       null,
   redline_urban_greening_land_area          decimal(32,10)       null,
   redline_urban_road_land_area          decimal(32,10)       null,
   redline_urban_lake_water_area         decimal(32,10)       null,
   redline_external_construction_area              decimal(32,10)       null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_projinfo_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '项目基础信息表
   用途：项目基础信息、项目级指标信息
   重点维度：项目
   重点指标：建筑面积、可售面积', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '盈利速算的版本主键GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '盈利预算版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '主数据版本', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'master_data_version'
execute sp_addextendedproperty 'MS_Description', '公司名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'company_name'
execute sp_addextendedproperty 'MS_Description', '公司GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'company_guid'
execute sp_addextendedproperty 'MS_Description', '取项目后台UGID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '投管代码', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'investment_management_code'
execute sp_addextendedproperty 'MS_Description', '项目编号', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'project_code'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '所属地块', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'land_parcel'
execute sp_addextendedproperty 'MS_Description', '获取时间', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'acquisition_time'
execute sp_addextendedproperty 'MS_Description', '获取方式', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'acquisition_method'
execute sp_addextendedproperty 'MS_Description', '用地性质', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'land_nature'
execute sp_addextendedproperty 'MS_Description', '是否底价获取', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'is_bottom_price_acquisition'
execute sp_addextendedproperty 'MS_Description', '楼面单价', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'floor_price'
execute sp_addextendedproperty 'MS_Description', '获取总成本', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'total_acquisition_cost'
execute sp_addextendedproperty 'MS_Description', '项目股权比例', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'project_equity_ratio'
execute sp_addextendedproperty 'MS_Description', '操盘方式', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'operation_method'
execute sp_addextendedproperty 'MS_Description', '并表方式', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'consolidation_method'
execute sp_addextendedproperty 'MS_Description', '项目状态', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'project_status'
execute sp_addextendedproperty 'MS_Description', '项目推广名', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'SpreadName'
execute sp_addextendedproperty 'MS_Description', '项目公司', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'project_company'
execute sp_addextendedproperty 'MS_Description', '管理方式', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'management_method'
execute sp_addextendedproperty 'MS_Description', '平台公司', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'DevelopmentCompanyName'
execute sp_addextendedproperty 'MS_Description', '城市', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'city'
execute sp_addextendedproperty 'MS_Description', '城市分类', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'city_category'
execute sp_addextendedproperty 'MS_Description', '销售状态', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'sales_status'
execute sp_addextendedproperty 'MS_Description', '分期数量', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'stage_count'
execute sp_addextendedproperty 'MS_Description', '楼栋数量', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'building_count'
execute sp_addextendedproperty 'MS_Description', '总用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'total_land_area'
execute sp_addextendedproperty 'MS_Description', '总建筑面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'total_building_area'
execute sp_addextendedproperty 'MS_Description', '取可售/不可售产品货量明细子表"地上建筑面积"汇总', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'aboveground_building_area'
execute sp_addextendedproperty 'MS_Description', '取可售/不可售产品货量明细子表"地下建筑面积"汇总', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'underground_building_area'
execute sp_addextendedproperty 'MS_Description', '地下室占比', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'basement_ratio'
execute sp_addextendedproperty 'MS_Description', '计容面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'calculated_area'
execute sp_addextendedproperty 'MS_Description', '容积率', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'floor_area_ratio'
execute sp_addextendedproperty 'MS_Description', '净用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'net_land_area'
execute sp_addextendedproperty 'MS_Description', '总可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'total_saleable_area'
execute sp_addextendedproperty 'MS_Description', '地上可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'aboveground_saleable_area'
execute sp_addextendedproperty 'MS_Description', '总计容可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'total_calculated_saleable_area'
execute sp_addextendedproperty 'MS_Description', '不计容可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'non_calculated_saleable_area'
execute sp_addextendedproperty 'MS_Description', '园林绿化率', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'greening_rate'
execute sp_addextendedproperty 'MS_Description', '园林绿化面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'greening_area'
execute sp_addextendedproperty 'MS_Description', '建筑密度', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'building_density'
execute sp_addextendedproperty 'MS_Description', '户型面积90平以下', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'unit_area_below_90_sqm'
execute sp_addextendedproperty 'MS_Description', '建筑基底面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'building_base_area'
execute sp_addextendedproperty 'MS_Description', '园林非展示区面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'garden_non_display_area'
execute sp_addextendedproperty 'MS_Description', '园林展示区面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'garden_display_area'
execute sp_addextendedproperty 'MS_Description', '红线内城市其他用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'redline_urban_other_land_area'
execute sp_addextendedproperty 'MS_Description', '红线内城市绿化用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'redline_urban_greening_land_area'
execute sp_addextendedproperty 'MS_Description', '红线内城市道路用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'redline_urban_road_land_area'
execute sp_addextendedproperty 'MS_Description', '红线内城市湖泊和水面面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'redline_urban_lake_water_area'
execute sp_addextendedproperty 'MS_Description', '红线外代建面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_projinfo_history', 'column', 'redline_external_construction_area'
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_stageinfo_history                   */
/*==============================================================*/
create table data_wide_ylgh_jk_stageinfo_history (
   VersionGUID                uniqueidentifier     null,
   version_name                 nvarchar(200)        null,
   master_data_version                nvarchar(200)        null,
   companyname                 nvarchar(200)        null,
   companyguid               uniqueidentifier     null,
   projectname                 nvarchar(200)        null,
   projectguid               uniqueidentifier     null,
   stagename                 nvarchar(200)        null,
   stageguid               uniqueidentifier     null,
   management_method                 nvarchar(200)        null,
   product_series                  nvarchar(200)        null,
   total_land_area                decimal(32,10)       null,
   land_occupation_area                 decimal(32,10)       null,
   net_land_area                decimal(32,10)       null,
   showroom_area                decimal(32,10)       null,
   sales_center_area               decimal(32,10)       null,
   total_building_area                decimal(32,10)       null,
   aboveground_area                 decimal(32,10)       null,
   underground_area                 decimal(32,10)       null,
   aboveground_saleable_area               decimal(32,10)       null,
   underground_saleable_area               decimal(32,10)       null,
   greening_area               decimal(32,10)       null,
   greening_rate                decimal(32,10)       null,
   building_base_area               decimal(32,10)       null,
   building_density                 decimal(32,10)       null,
   unit_area_below_90_sqm            decimal(32,10)       null,
   total_saleable_area                decimal(32,10)       null,
   floor_area_ratio                  decimal(32,10)       null,
   calculated_building_area               decimal(32,10)       null,
   calculated_saleable_area               decimal(32,10)       null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_stageinfo_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '用途：分期基础信息、分期级指标信息
   重点维度：项目、分期
   重点指标：建筑面积、可售面积', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '版本表主键', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '主数据版本', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'master_data_version'
execute sp_addextendedproperty 'MS_Description', '公司名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'company_name'
execute sp_addextendedproperty 'MS_Description', '公司GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'company_guid'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '项目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '分期名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'stage_name'
execute sp_addextendedproperty 'MS_Description', '分期GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'stage_guid'
execute sp_addextendedproperty 'MS_Description', '管理方式', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'management_method'
execute sp_addextendedproperty 'MS_Description', '产品系', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'product_series'
execute sp_addextendedproperty 'MS_Description', '总用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'total_land_area'
execute sp_addextendedproperty 'MS_Description', '占地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'land_occupation_area'
execute sp_addextendedproperty 'MS_Description', '净用地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'net_land_area'
execute sp_addextendedproperty 'MS_Description', '样板房面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'showroom_area'
execute sp_addextendedproperty 'MS_Description', '售楼中心面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'sales_center_area'
execute sp_addextendedproperty 'MS_Description', '总建筑面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'total_building_area'
execute sp_addextendedproperty 'MS_Description', '地上面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'aboveground_area'
execute sp_addextendedproperty 'MS_Description', '地下面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'underground_area'
execute sp_addextendedproperty 'MS_Description', '地上可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'aboveground_saleable_area'
execute sp_addextendedproperty 'MS_Description', '地下可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'underground_saleable_area'
execute sp_addextendedproperty 'MS_Description', '园林绿化面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'greening_area'
execute sp_addextendedproperty 'MS_Description', '园林绿化率', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'greening_rate'
execute sp_addextendedproperty 'MS_Description', '建筑基地面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'building_base_area'
execute sp_addextendedproperty 'MS_Description', '建筑密度', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'building_density'
execute sp_addextendedproperty 'MS_Description', '户型面积90平以下', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'unit_area_below_90_sqm'
execute sp_addextendedproperty 'MS_Description', '总可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'total_saleable_area'
execute sp_addextendedproperty 'MS_Description', '容积率', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'floor_area_ratio'
execute sp_addextendedproperty 'MS_Description', '计容建筑面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'calculated_building_area'
execute sp_addextendedproperty 'MS_Description', '计容可售面积', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_stageinfo_history', 'column', 'calculated_saleable_area'
go

/*==============================================================*/
/* Table: data_wide_ylgh_jk_yxfy_history                        */
/*==============================================================*/
create table data_wide_ylgh_jk_yxfy_history (
   VersionGUID                uniqueidentifier     null,-- 版本表主键
   version_name                 nvarchar(200)        null,
   projectname                 nvarchar(200)        null,
   projectguid               uniqueidentifier     null,
   CostName                 nvarchar(200)        null,
   Costcode                 nvarchar(200)        null,
   Yxfy_occurrence_caliber                 decimal(32,10)       null, -- 营销费用_发生口径
   Yxfy_payment_caliber                 decimal(32,10)       null, -- 营销费用_支付口径
   year                  int                  null,
   month                  int                  null
)
go

if exists (select 1 from  sys.extended_properties
           where major_id = object_id('data_wide_ylgh_jk_yxfy_history') and minor_id = 0)
begin 
   declare @CurrentUser sysname 
select @CurrentUser = user_name() 
execute sp_dropextendedproperty 'MS_Description',  
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history' 
 
end 


select @CurrentUser = user_name() 
execute sp_addextendedproperty 'MS_Description',  
   '营销费用发生支付表
   用途：项目科目的发生口径的发生数、支付口径的支付数
   重点维度：项目、科目、年月
   重点指标：已发生金额、已支付金额', 
   'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history'
go

-- 字段注释
declare @CurrentUser sysname
select @CurrentUser = user_name()

execute sp_addextendedproperty 'MS_Description', '版本表主键', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'VersionGUID'
execute sp_addextendedproperty 'MS_Description', '版本名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'version_name'
execute sp_addextendedproperty 'MS_Description', '项目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'project_name'
execute sp_addextendedproperty 'MS_Description', '项目GUID', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'project_guid'
execute sp_addextendedproperty 'MS_Description', '科目名称', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'CostName'
execute sp_addextendedproperty 'MS_Description', '科目代码', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'CostCode'
execute sp_addextendedproperty 'MS_Description', '发生口径', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'occurrence_caliber'
execute sp_addextendedproperty 'MS_Description', '支付口径', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'payment_caliber'
execute sp_addextendedproperty 'MS_Description', '所属年', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'year'
execute sp_addextendedproperty 'MS_Description', '所属月', 'user', @CurrentUser, 'table', 'data_wide_ylgh_jk_yxfy_history', 'column', 'month'
go

