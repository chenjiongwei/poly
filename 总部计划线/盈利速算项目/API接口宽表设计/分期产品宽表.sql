-- MOQL sql
-- ********************************************************************--
-- author:developer_chenjw
-- create time:2025-11-27 11:38:18
-- 开发说明：
-- 1、明细事实表/维度表/汇总时表的开发流程，系统会生成开始节点创建临时表xxx_tmp，结束节点将临时表数据同步到正式宽表。
-- 2、SQL内所有清洗加工操作只能系统创建的临时表xxx_tmp，请勿直接操作正式宽表，否则会代码检查不通过导致无法更新发布。
-- ********************************************************************--

insert into dws_ylgh_jk_productinfo_tmp(
    GUID,                          -- 主键（唯一标识符）
    VersionGUID,                   -- 版本主键
    version_name,                  -- 版本名称
    master_data_version,           -- 主数据版本
    projectguid,                   -- 项目GUID
    projectcode,                   -- 项目编码
    projectname,                   -- 项目名称
    stageguid,                     -- 分期GUID
    stagename,                     -- 分期名称
    managementattributes,           -- 经营属性
    productname,                   -- 产品名称
    producttype,                   -- 产品类型
    ptzzrate,                      -- 普通住宅占比
    fptzzrate ,                    -- 非普通住宅占比
    floorcount,                    -- 层数
    land_area,                     -- 占地面积
    building_area,                 -- 建筑面积
    aboveground_building_area,     -- 地上建筑面积
    underground_building_area,     -- 地下建筑面积
    calculated_area,               -- 计容面积
    salearea,                      -- 可售面积
    upsalearea,                    -- 地上可售面积
    downsalearea,                  -- 地下可售面积
    roomnum ,                     -- 户总数
    -- iscar,                         -- 是否车位
    upcarnum,                      -- 地上车位数
    downcarnum,                    -- 地下车位数
    floor_area_ratio,              -- 容积率
    calculated_saleable_area,      -- 计容可售面积
    product_ratio                  -- 产品占比
)
select
    UUID() as GUID,                                                -- 主键（唯一标识符）
    vr.VersionGUID                as VersionGUID,                  -- 版本主键
    vr.VersionName                as version_name,                 -- 版本名称
    pp.ProjectVersionName         as master_data_version,          -- 主数据版本
    pp.p_projectId                as projectguid,                  -- 项目GUID
    pp.ProjCode                   as projectcode,                  -- 项目编码
    pp.ProjName                   as projectname,                  -- 项目名称
    pro.p_projectId               as stageguid,                    -- 分期GUID
    pro.ProjName                  as stagename,                    -- 分期名称
    pdt.x_ManagementAttributes    as managementattributes,       -- 经营属性
    pdt.x_ProductName             as productname,                  -- 产品名称
    pdt.x_ProductTypeName         as producttype,                  -- 产品类型
    pdt.x_PtzzRate                as ptzzrate,                     -- 普通住宅占比
    pdt.x_FptzzRate               as fptzzrate,                    -- 非普通住宅占比
    pdt.x_FloorNum                as floorcount,                   -- 层数
    pdt.x_OccupyArea              as land_area,                    -- 占地面积
    pdt.x_TotalArea               as building_area,                -- 建筑面积
    pdt.x_UpBuildArea             as aboveground_building_area,    -- 地上建筑面积
    pdt.x_DownBuildArea           as underground_building_area,    -- 地下建筑面积
    pdt.x_CountRjlArea            as calculated_area,              -- 计容面积
    pdt.x_SaleArea                as salearea,                     -- 可售面积
    pdt.x_UpSaleArea              as upsalearea,                   -- 地上可售面积
    pdt.x_DownSaleArea            as downsalearea,                 -- 地下可售面积
    pdt.x_RoomNum                 as roomnum ,                    -- 户总数
    -- pdt.x_IsCar                   as iscar,                        -- 是否车位
    pdt.x_UpCarNum                as upcarnum,                     -- 地上车位数
    pdt.x_DownCarNum              as downcarnum,                   -- 地下车位数
    pdt.x_Rjl                     as floor_area_ratio,             -- 容积率
    pdt.x_JrksArea                as calculated_saleable_area,     -- 计容可售面积
    pdt.x_ProductRate             as product_ratio                 -- 产品占比
from dim_mdm_projectproduct pdt
    inner join dim_mdm_project pro on pro.p_projectId = pdt.x_ProjectGuid and pro.Level = 3
    inner join dim_mdm_project pp on pp.p_projectId = pro.ParentGUID and pp.Level = 2
    inner join dwd_jyys_version vr on vr.ProjGUID = pp.p_projectId
