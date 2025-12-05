 use [TaskCenterData]
 go 
 

/**********************************************************************
-- 本脚本用于将每个项目最新一条拍照记录的“审核状态”设置为“已审核”
-- 主要步骤如下：
-- 1. 查询TaskCenterData.dbo.cb_StockFtProjVersionPhoto表，
--    按项目（ProjGUID）分组，取拍照日期（PhotoDate）最新的一条数据。
-- 2. 将筛选出的每个项目最新记录，且尚未审核（ApproveState <> '已审核'）
--    的数据的审核状态设置为“已审核”，记录审核人和审核时间。
**********************************************************************/

-- 备份
select  * into cb_StockFtProjVersionPhoto_bak20251204 from  cb_StockFtProjVersionPhoto


-- 步骤一：找出每个项目最新的拍照记录，并存入临时表#vr
SELECT 
    id,                    -- 主键ID
    VersionGUID,           -- 版本GUID
    ProjName,              -- 项目名称
    PhotoDate,             -- 拍照日期
    DateSource,            -- 数据来源
    ProjGUID,              -- 项目GUID
    ApproveState,          -- 当前审核状态
    ROW_NUMBER() OVER (
        PARTITION BY ProjGUID         -- 按项目分组
        ORDER BY PhotoDate DESC       -- 拍照日期倒序，最新的在最前
    ) AS num
INTO #vr
FROM [TaskCenterData].dbo.cb_StockFtProjVersionPhoto WITH (NOLOCK)
WHERE 1=1
--    可在此添加其他限定条件，例如只取“待审核”状态的数据
--    例：AND ApproveState <> '已审核'

-- 步骤二：将每个项目最新一条且未审核的数据设置为已审核
UPDATE a
   SET a.ApproveState = '已审核',           -- 设置为已审核
       a.ApproveDate = GETDATE(),           -- 当前时间
       a.ApprovedBy  = '系统管理员'           -- 审核人
FROM [TaskCenterData].dbo.cb_StockFtProjVersionPhoto a
INNER JOIN #vr vr ON a.id = vr.id
WHERE vr.ApproveState <> '已审核'            -- 只处理未审核
  AND vr.num = 1                            -- 只处理最新的一条记录