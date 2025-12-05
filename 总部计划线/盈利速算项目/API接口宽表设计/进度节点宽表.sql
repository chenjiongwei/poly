-- MOQL sql
-- ********************************************************************--
-- author:developer_chenjw
-- create time:2025-11-26 21:28:30
-- 开发说明：
-- 1、明细事实表/维度表/汇总时表的开发流程，系统会生成开始节点创建临时表xxx_tmp，结束节点将临时表数据同步到正式宽表。
-- 2、SQL内所有清洗加工操作只能系统创建的临时表xxx_tmp，请勿直接操作正式宽表，否则会代码检查不通过导致无法更新发布。
-- ********************************************************************--
insert into dws_ylgh_jk_ldjd_tmp (
   GUID,                                   -- 主键字段
   PlanTaskDataGUID,
   VersionGUID,
   version_name,
   projectname,
   projectguid,
   stagename,
   stageguid,
   productbuildingname,
   productbuildingguid,
   project_acquisition_time,
   is_launched,
   launched_area,
   node_planned_completion_date,
   node_estimated_completion_date,
   node_actual_completion_date,
   node_name,
   node_completion_date
)
SELECT
    UUID() as GUID,
    tk.PlanTaskDataGUID as PlanTaskDataGUID,                                 -- 计划节点数据表主键 
    vr.VersionGUID AS VersionGUID,                                            -- 版本表主键
    vr.VersionName AS version_name,                                           -- 版本名称
    tk.x_ProjName AS projectname,                                             -- 项目名称
    tk.x_ProjGUID AS projectguid,                                             -- 项目GUID
    tk.x_StageName AS stagename,                                              -- 分期名称
    tk.x_StageGUID AS stageguid,                                              -- 分期GUID
    tk.x_BldName AS productbuildingname,                          -- 产品楼栋名称
    tk.x_BldGUID AS productbuildingguid,                          -- 产品楼栋GUID
    tk.x_ProjGetTime AS project_acquisition_time,                  -- 项目获取时间
    tk.x_IsPushed AS is_launched,                                                       -- 是否已推售（枚举：是/否）
    tk.x_PushedArea AS launched_area,                                       -- 已推面积
    tk.x_NodePlanDate AS node_planned_completion_date,           -- 节点计划完成日期
    tk.x_NodeDueDate AS node_estimated_completion_date,       -- 节点预计完成日期
    tk.x_NodeActDate AS node_actual_completion_date,             -- 节点实际完成日期
    tk.x_NodeName AS node_name,                                               -- 节点名称
    tk.x_NodePlanDate AS node_completion_date                           -- 节点完成日期
FROM
    dwd_jyys_plantaskdata tk
    INNER JOIN dwd_jyys_version vr ON vr.VersionGUID = tk.x_VersionGUID