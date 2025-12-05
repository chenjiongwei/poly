-- MOQL sql
-- ********************************************************************--
-- author:developer_chenjw
-- create time:2025-11-26 22:11:09
-- 开发说明：
-- 1、明细事实表/维度表/汇总时表的开发流程，系统会生成开始节点创建临时表xxx_tmp，结束节点将临时表数据同步到正式宽表。
-- 2、SQL内所有清洗加工操作只能系统创建的临时表xxx_tmp，请勿直接操作正式宽表，否则会代码检查不通过导致无法更新发布。
-- ********************************************************************--

insert into dws_ylgh_jk_stageinfo_tmp (
    GUID,                                  -- 主键字段
    VersionGUID,                           -- 版本表主键
    version_name,                          -- 版本名称
    master_data_version,                   -- 主数据版本
    companyname,                           -- 公司名称
    companyguid,                           -- 公司GUID
    projectname,                           -- 项目名称
    projectguid,                           -- 项目GUID
    stagename,                             -- 分期名称
    stageguid,                             -- 分期GUID
    management_method,                     -- 管理方式（操盘/委托等）
    product_series,                        -- 产品系（产品线）
    total_land_area,                       -- 总用地面积
    land_occupation_area,                  -- 占地面积
    net_land_area,                         -- 净用地面积
    -- showroom_area,                         -- 展厅面积
    -- sales_center_area,                     -- 销售中心面积
    total_building_area,                   -- 总建筑面积
    aboveground_area,                      -- 地上建筑面积
    underground_area,                      -- 地下建筑面积
    aboveground_saleable_area,             -- 地上可售面积
    underground_saleable_area,             -- 地下可售面积
    greening_area,                         -- 园林绿化面积
    greening_rate,                         -- 园林绿化率
    building_base_area,                    -- 建筑基底面积
    building_density,                      -- 建筑密度
    unit_area_below_90_sqm,                -- 户型面积90㎡以下
    total_saleable_area,                   -- 总可售面积
    floor_area_ratio,                      -- 容积率
    calculated_building_area,              -- 计容建筑面积
    calculated_saleable_area               -- 计容可售面积
)
SELECT
    UUID() AS GUID,                                         -- 主键（系统生成唯一标识符）
    vr.VersionGUID                AS VersionGUID,            -- 版本表主键
    vr.VersionName                AS version_name,           -- 版本名称
    p.ProjectVersionName          AS master_data_version,    -- 主数据版本
    p.BuName                      AS companyname,            -- 公司名称
    p.BUGUID                      AS companyguid,            -- 公司GUID
    pp.ProjName                   AS projectname,            -- 项目名称
    pp.p_projectId                AS projectguid,            -- 项目GUID
    p.ProjName                    AS stagename,              -- 分期名称
    p.p_projectId                 AS stageguid,              -- 分期GUID
    p.DevelopType                 AS management_method,       -- 管理方式
    p.x_Cpxlb                  AS product_series,          -- 产品系（产品线）
    p.UseArea                     AS total_land_area,         -- 总用地面积（㎡）
    p.OccupyArea                  AS land_occupation_area,    -- 占地面积（㎡）
    p.x_Jarea                     AS net_land_area,           -- 净用地面积（㎡）
    -- p.x_SaleShowArea              AS showroom_area,           -- 展厅面积（㎡）
    -- p.x_SaleCenterArea            AS sales_center_area,       -- 销售中心面积（㎡）
    p.BuildArea                   AS total_building_area,     -- 总建筑面积（㎡）
    p.UpArea                      AS aboveground_area,        -- 地上建筑面积（㎡）
    p.DownArea                    AS underground_area,        -- 地下建筑面积（㎡）
    p.UpSaleArea                  AS aboveground_saleable_area,    -- 地上可售面积（㎡）
    p.DownSaleArea                AS underground_saleable_area,    -- 地下可售面积（㎡）
    p.x_YllhArea                  AS greening_area,           -- 园林绿化面积（㎡）
    p.x_YllhRate                  AS greening_rate,           -- 园林绿化率（%）
    p.BuildingJdArea              AS building_base_area,      -- 建筑基底面积（㎡）
    p.BuildDensity                AS building_density,        -- 建筑密度（%）
    p.x_JsyxhxArea                AS unit_area_below_90_sqm,  -- 户型面积90平以下（㎡）
    p.SaleArea                    AS total_saleable_area,     -- 总可售面积（㎡）
    p.Rjl                         AS floor_area_ratio,        -- 容积率
    p.CountRjlArea                AS calculated_building_area,     -- 计容建筑面积（㎡）
    p.x_JrSaleArea                AS calculated_saleable_area      -- 计容可售面积（㎡）
FROM dim_mdm_project p
    INNER JOIN dim_mdm_project pp ON pp.p_projectId = p.ParentGUID AND pp.`Level` = 2
    INNER JOIN dwd_jyys_version vr ON vr.ProjGUID = pp.p_projectId
WHERE p.`Level` = 3

