-- MOQL sql
-- ********************************************************************--
-- author:developer_chenjw
-- create time:2025-11-26 20:37:16
-- 开发说明：
-- 1、明细事实表/维度表/汇总时表的开发流程，系统会生成开始节点创建临时表xxx_tmp，结束节点将临时表数据同步到正式宽表。
-- 2、SQL内所有清洗加工操作只能系统创建的临时表xxx_tmp，请勿直接操作正式宽表，否则会代码检查不通过导致无法更新发布。
-- ********************************************************************--

 insert into  dws_ylgh_jk_yxfy_tmp(
   GUID,
   FeeDataGUID,
   VersionGUID,
   version_name,
   projectname,
   projectguid,
   CostName,
   Costcode,
   Yxfy_occurrence_caliber,
   Yxfy_payment_caliber,
   year,
   month
 )
SELECT
    UUID() AS GUID,
    fee.FeeDataGUID                       as FeeDataGUID, --  费用数据表主键
    vr.VersionGUID                        AS VersionGUID,                           -- 版本表主键
    vr.VersionName                        AS version_name,                          -- 版本名称
    fee.x_ProjName as projectname,
    fee.x_ProjGUID as projectguid,
    fee.x_CostName as CostName,
    fee.x_CostCode as Costcode,
    fee.x_OccurAmount as Yxfy_occurrence_caliber,
    fee.x_PayAmount as Yxfy_payment_caliber,
    fee.x_DataYear as year,
    fee.x_DataMonth as month
FROM
    dwd_jyys_feedata fee
    INNER JOIN dwd_jyys_version vr ON vr.VersionGUID = fee.x_VersionGUID