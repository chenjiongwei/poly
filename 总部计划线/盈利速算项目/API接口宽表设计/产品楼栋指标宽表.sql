-- MOQL sql
-- ********************************************************************--
-- author:developer_chenjw
-- create time:2025-11-27 11:38:18
-- 开发说明：
-- 1、明细事实表/维度表/汇总时表的开发流程，系统会生成开始节点创建临时表xxx_tmp，结束节点将临时表数据同步到正式宽表。
-- 2、SQL内所有清洗加工操作只能系统创建的临时表xxx_tmp，请勿直接操作正式宽表，否则会代码检查不通过导致无法更新发布。
-- ********************************************************************--

-- insert into dws_ylgh_jk_productbuilding_tmp (
--     GUID,                              -- 主键
--     VersionGUID,                       -- 版本主键
--     version_name,                      -- 版本名称
--     master_data_version,               -- 主数据版本
--     projectname,                       -- 项目名称
--     projectguid,                       -- 项目GUID
--     stageguid,                         -- 分期GUID
--     productbuildingname,               -- 产品楼栋名称
--     productbuildingguid,               -- 产品楼栋GUID
--     productbuildingcode,               -- 楼栋编码
--     commoditytype,                     -- 业态类型
--     decorationstandard,                -- 装修标准
--     cost_business_type_name,           -- 成本业态
--     is_saleable,                       -- 是否可售
--     is_held,                           -- 是否自持
--     engineeringbuildingname,           -- 工程楼栋名称
--     engineeringbuildingguid,           -- 工程楼栋GUID
--     business_attribute,                -- 经营属性
--     deallocation_ratio,                -- 分摊比例
--     producttype,                       -- 产品类型
--     producttype_guid,                  -- 产品类型GUID
--     productname,                       -- 产品名称
--     productguid,                       -- 产品GUID
--     is_parking_space,                  -- 是否车位
--     batch_name,                        -- 批次
--     building_area,                     -- 建筑面积
--     saleable_area,                     -- 可售面积
--     aboveground_building_area,         -- 地上建筑面积
--     underground_building_area,         -- 地下建筑面积
--     calculated_area,                   -- 计容面积
--     calculated_saleable_area,          -- 计容可售面积
--     self_held_area,                    -- 自持面积
--     self_held_parking_count,           -- 自持车位数
--     saleable_parking_count,            -- 可售车位数
--     total_parking_count,               -- 总车位数
--     unit_count,                        -- 单元总数
--     aboveground_floors,                -- 地上层数
--     underground_floors,                -- 地下层数
--     total_saleable_area,               -- 总可售面积
--     aboveground_saleable_area,         -- 地上可售面积
--     underground_saleable_area,         -- 地下可售面积
--     aboveground_parking_count,         -- 地上车位数
--     underground_parking_count,         -- 地下车位数
--     interior_area,                     -- 套内面积
--     delivery_date,                     -- 交付日期
--     sales_building_name              -- 售楼楼栋名称
-- )

select
    UUID() as GUID,                              -- 主键
    vr.VersionGUID as VersionGUID,               -- 版本主键
    vr.VersionName as version_name,              -- 版本名称
    pj.ProjectVersionName as master_data_version, -- 主数据版本（如无可拼vr.VersionName）
    pj.ProjName as projectname,                  -- 项目名称
    pj.p_projectId as projectguid,             -- 项目GUID
    stg.p_projectId as stageguid,                -- 分期GUID
    bld.BuildingName as productbuildingname,     -- 楼栋名称
    bld.BuildingGUID as productbuildingguid,     -- 楼栋GUID
    bld.BuildCode as productbuildingcode,   -- 楼栋编码
    bld.x_BusinessType as commoditytype,        -- 商品类型
    bld.x_Zxbz as decorationstandard,-- 装修标准
    bld.x_YtCode as cost_business_type_name, -- 成本业态
    bld.x_IsSale as is_saleable,             -- 是否可售
    bld.x_IsHold as is_held,                     -- 是否自持
    bld.PhysicalBuildingName as engineeringbuildingname,   -- 工程楼栋名称
    bld.PhysicalBuildingGUID as engineeringbuildingguid,  -- 工程楼栋GUID
    bld.ManagementAttributes as business_attribute, -- 经营属性
    bld.x_QHRate as deallocation_ratio, -- 去化比例 
    bld.TopProductTypeName as producttype,         -- 产品类型
    bld.TopProductTypeGUID as producttype_guid,    -- 产品类型GUID
    bld.ProductTypeName as productname,             -- 产品名称
    bld.ProductTypeGuid as productguid,             -- 产品GUID
    bld.IsParkingSpace as is_parking_space,     -- 是否车位
    bld.x_BatchName as batch_name,                -- 批次
    bld.BuildArea as building_area,          -- 建筑面积
    bld.AvailableArea as saleable_area,          -- 可售面积
    bld.UpBuildArea as aboveground_building_area,   -- 地上建筑面积
    bld.DownBuildArea as underground_building_area,   -- 地下建筑面积
    bld.x_JrArea as calculated_area,      -- 计容面积
    bld.x_JrksArea as calculated_saleable_area,     -- 计容可售面积
    case when x_IsHold ='是' then bld.BuildArea else  0  end  as self_held_area,         -- 自持面积
    case when x_IsHold ='是' then bld.CarNum else 0  end as self_held_parking_count, -- 自持车位数
    case when x_IsSale ='是' then bld.CarNum else 0  end as saleable_parking_count,  -- 可售车位数
    bld.CarNum as total_parking_count,       -- 总车位数
    NULL as unit_count,                 -- 单元总数
    bld.UpFloors as aboveground_floors, -- 地上层数
    bld.DownFloors as underground_floors, -- 地下层数
    bld.AvailableArea as total_saleable_area,         -- 总可售面积
    bld.UpSaleArea as aboveground_saleable_area, -- 地上可售面积
    bld.DownSaleArea as underground_saleable_area, -- 地下可售面积
    bld.UpCarNum as aboveground_parking_count, -- 地上车位数
    bld.DownCarNum as underground_parking_count, -- 地下车位数
    bld.InnerArea as interior_area,           -- 套内面积
    bld.YjjfDate as delivery_date,           -- 交付日期 
    bld.BuildingName as sales_building_name -- 销售楼栋名称
from 
    dim_mdm_building bld
    inner join dim_mdm_project pj on pj.p_projectId = bld.ProjGUID and pj.`Level` = 2
    left join dim_mdm_project stg on stg.p_projectId = bld.StageGuid and stg.`Level` = 3
    inner join dwd_jyys_version vr on vr.ProjGUID = pj.p_projectId
    -- left join dwd_jyys_salesorderdata sale  on sale.x_BldGUID = bld.BuildingGUID
