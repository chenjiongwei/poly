-- MOQL sql
-- ********************************************************************--
-- author:developer_chenjw
-- create time:2025-11-24 14:34:56
-- 开发说明：
-- 1、明细事实表/维度表/汇总时表的开发流程，系统会生成开始节点创建临时表xxx_tmp，结束节点将临时表数据同步到正式宽表。
-- 2、SQL内所有清洗加工操作只能系统创建的临时表xxx_tmp，请勿直接操作正式宽表，否则会代码检查不通过导致无法更新发布。
-- ********************************************************************--

-- 项目基础信息宽表补齐字段（扩展所有兜底注释掉的字段）
INSERT INTO dws_ylgh_jk_projinfo_tmp (
    GUID,                                   -- 主键字段
    VersionGUID,                            -- 版本表主键
    version_name,                           -- 版本名称
    master_data_version,                    -- 主数据版本
    companyname,                            -- 公司名称
    companyguid,                            -- 公司GUID
    projectguid,                            -- 项目GUID
    investment_management_code,             -- 投管代码
    projectcode,                            -- 项目编码
    projectname,                            -- 项目名称
    land_parcel,                            -- 所属地块
    acquisitiontime,                        -- 获取时间
    acquisitionmethod,                      -- 项目获取方式
    land_nature,                            -- 用地性质
    is_bottom_price_acquisition,            -- 是否底价获取
    floor_price,                            -- 楼面单价
    total_acquisition_cost,                 -- 获取总成本
    project_equity_ratio,                   -- 项目股权比例
    operation_method,                       -- 操盘方式
    consolidation_method,                   -- 并表方式
    project_status,                         -- 项目状态
    SpreadName,                             -- 推广名称
    project_company,                        -- 项目公司
    management_method,                      -- 管理方式
    DevelopmentCompanyName,                 -- 平台公司名称
    city,                                   -- 城市
    city_category,                          -- 城市分类
    sales_status,                           -- 销售状态
    stage_count,                            -- 分期数量
    building_count,                         -- 楼栋数量
    total_land_area,                        -- 总用地面积
    total_building_area,                    -- 总建筑面积
    aboveground_building_area,              -- 地上建筑面积
    underground_building_area,              -- 地下建筑面积
    basement_ratio,                         -- 地下室占比
    calculated_area,                        -- 计容建筑面积
    floor_area_ratio,                       -- 容积率
    net_land_area,                          -- 净用地面积
    total_saleable_area,                    -- 总可售面积
    aboveground_saleable_area,              -- 地上可售面积
    total_calculated_saleable_area,         -- 总计容面积
    non_calculated_saleable_area,           -- 不计容面积
    greening_rate,                          -- 园林绿化率
    greening_area,                          -- 园林绿化面积
    building_density,                       -- 建筑密度
    unit_area_below_90_sqm,                 -- 户型面积90平以下
    building_base_area,                       -- 建筑基底面积
    garden_non_display_area,                -- 园林非展示区面积
    garden_display_area,                    -- 园林展示区面积
    redline_urban_other_land_area,          -- 红线内城市其他用地面积
    redline_urban_greening_land_area,       -- 红线内城市绿地用地面积
    redline_urban_road_land_area,           -- 红线内城市道路用地面积
    redline_urban_lake_water_area,          -- 红线内城市湖泊和水面面积
    redline_external_construction_area      -- 红线外代建面积
)
SELECT
    UUID() AS GUID,
    vr.VersionGUID                        AS VersionGUID,                           -- 版本表主键
    vr.VersionName                        AS version_name,                          -- 版本名称
    p.ProjectVersionName                  AS master_data_version,                   -- 主数据版本
    p.BuName                              AS companyname,                           -- 公司名称
    p.BUGUID                              AS companyguid,                           -- 公司GUID
    p.p_projectId                         AS projectguid,                           -- 项目GUID
    p.x_ProjInvMngCode                    AS investment_management_code,            -- 投管代码
    p.ProjCode                            AS projectcode,                           -- 项目编码
    p.ProjName                            AS projectname,                           -- 项目名称
    p.x_BelongBlock                       AS land_parcel,                           -- 所属地块
    p.x_ProjGrantDate                     AS acquisitiontime,                       -- 获取时间
    p.x_Xmhqfs                            AS acquisitionmethod,                     -- 项目获取方式
    p.x_LandType                          AS land_nature,                           -- 用地性质
    p.x_IsDjhq                            AS is_bottom_price_acquisition,           -- 是否底价获取
    p.x_LMDJ                              AS floor_price,                           -- 楼面单价
    p.x_TotalLandPrice                    AS total_acquisition_cost,                -- 获取总成本
    p.x_ShareHoldingRatio                 AS project_equity_ratio,                  -- 项目股权比例
    p.x_OperatingPlatform                 AS operation_method,                      -- 操盘方式
    p.x_BbWay                             AS consolidation_method,                  -- 并表方式
    p.ProjStatus                          AS project_status,                        -- 项目状态
    p.SpreadName                          AS SpreadName,                            -- 推广名称
    p.x_ProjCompany                       AS project_company,                       -- 项目公司
    p.DevelopType                         AS management_method,                     -- 管理方式
    p.x_DevelopmentCompanyName            AS DevelopmentCompanyName,                -- 平台公司名称
    p.City                                AS city,                                 -- 城市
    p.x_CityType                          AS city_category,                         -- 城市分类
    p.x_SaleStatus                        AS sales_status,                          -- 销售状态
    p.x_StageNum                          AS stage_count,                           -- 分期数量
    p.x_BuildingNum                       AS building_count,                        -- 楼栋数量
    p.UseArea                             AS total_land_area,                       -- 总用地面积
    p.BuildArea                           AS total_building_area,                   -- 总建筑面积
    p.UpArea                              AS aboveground_building_area,             -- 地上建筑面积
    p.DownArea                            AS underground_building_area,             -- 地下建筑面积
    p.x_DownRate                          AS basement_ratio,                        -- 地下室占比
    p.CountRjlArea                        AS calculated_area,                       -- 计容建筑面积
    p.Rjl                                 AS floor_area_ratio,                      -- 容积率
    p.x_Jarea                             AS net_land_area,                         -- 净用地面积
    p.SaleArea                            AS total_saleable_area,                   -- 总可售面积
    p.UpSaleArea                          AS aboveground_saleable_area,             -- 地上可售面积
    p.x_JrSaleArea                        AS total_calculated_saleable_area,        -- 总计容面积
    p.x_NoJrSaleArea                      AS non_calculated_saleable_area,          -- 不计容面积
    p.x_YllhRate                          AS greening_rate,                         -- 园林绿化率
    p.x_YllhArea                          AS greening_area,                         -- 园林绿化面积
    p.BuildDensity                        AS building_density,                      -- 建筑密度
    p.x_JsyxhxArea                        AS unit_area_below_90_sqm,                -- 户型面积90平以下
    p.BuildingJdArea                      AS building_base_area,                     -- 建筑基底面积
    p.x_YlfzsqArea                     AS garden_non_display_area,                -- 园林非展示区面积
    p.x_YlzsqArea                     AS garden_display_area,                     -- 园林展示区面积
    p.x_OtherArea                    AS redline_urban_other_land_area,           -- 红线内城市其他用地面积
    p.x_GreeningArea                 AS redline_urban_greening_land_area,        -- 红线内城市绿地用地面积
    p.x_RoadArea                     AS redline_urban_road_land_area,            -- 红线内城市道路用地面积
    p.x_LakeArea                     AS redline_urban_lake_water_area,           -- 红线内城市湖泊和水面面积
    p.x_OutsideRedLineArea           AS redline_external_construction_area       -- 红线外代建面积
FROM
    dim_mdm_project p
    INNER JOIN dwd_jyys_version vr ON vr.ProjGUID = p.p_projectId
WHERE
    p.Level = 2
