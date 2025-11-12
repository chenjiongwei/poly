USE [MyCost_Erp352]
GO

/***********************************************************************
* 查询数据库中与采购项目相关的表与字段信息，便于核查或扩展迁移逻辑
* 主要关注包含项目GUID、项目Code、项目树结构等信息的字段
***********************************************************************/
-- SELECT sys.objects.name AS 表名,
--        sys.columns.name AS 字段名称,
--        sys.types.name AS 数据类型,
--        sys.columns.max_length AS 长度,
--        sys.objects.create_date AS 创建日期
-- FROM   sys.objects
-- LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
-- LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
-- WHERE (
--           sys.columns.name = 'projcode'        -- 项目编码
--        OR sys.columns.name = 'ParentProjGUID'  -- 父级项目GUID
--        OR sys.columns.name = 'ParentGUID'      -- 父级GUID（可能是项目或其他）
--        OR sys.columns.name = 'ParentName'      -- 父级名称
--        OR sys.columns.name = 'ParentCode'      -- 父级编码
--        OR sys.columns.name LIKE '%FullName'    -- 层级全路径
--        OR sys.columns.name = 'HierarchyCode'   -- 层级编码
--      )
--      AND sys.objects.type = 'U'
--      AND sys.objects.name LIKE 'cg_%'
-- ORDER BY sys.objects.name, sys.columns.column_id

/***********************************************************************
* 存储过程调用样例，参数详解：
* 1. 新公司GUID
* 2. 旧公司GUID
* 3. 分期项目GUID
* 4. 老一级项目代码
* 5. 新一级项目代码
***********************************************************************/
 --EXEC usp_cg_ChgProjMoveFq 
 --     'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 新公司GUID
 --     'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 旧公司GUID
 --     '0E63E1AD-4703-4A95-B661-9E8E415E041F',    -- 分期项目GUID

/***********************************************************************
* 采招系统分期项目迁移脚本主逻辑存储过程
* 实现分期项目下各类基础表的公司、项目关系数据切换
***********************************************************************/
CREATE OR ALTER PROC [dbo].[usp_cg_ChgProjMoveFq]
(
    @BuGUIDNew     UNIQUEIDENTIFIER, -- 新公司GUID
    @BuGUIDOld     UNIQUEIDENTIFIER, -- 旧公司GUID
    @ProjGUID      UNIQUEIDENTIFIER -- 分期项目GUID
    -- @OldTopProjCode VARCHAR(50),     -- 原一级项目编码
    -- @NewTopProjCode VARCHAR(50)      -- 新一级项目编码
)
AS
BEGIN
    SET NOCOUNT OFF;

    -- 定义变量
    DECLARE @OldTopProjCode VARCHAR(50); -- 老一级项目code
    DECLARE @NewTopProjCode VARCHAR(50); -- 新一级项目code

    SELECT
        @OldTopProjCode = OldParentprojCode352,
        @NewTopProjCode = NewParentprojCode352
    FROM
        dqy_proj_20251027 AS a
    WHERE
        OldProjGuid = @ProjGUID;
    
    /***********************************************************
    * 1. 采购申请表 cg_CgApply
    * 备份分期数据后，逐项更新项目编码和公司GUID
    ************************************************************/
    PRINT '采购申请表:cg_CgApply';
    IF OBJECT_ID(N'cg_CgApply_bak_20251027', N'U') IS NULL
    BEGIN
        SELECT a.*
          INTO dbo.cg_CgApply_bak_20251027
          FROM cg_CgApply a
         WHERE a.ProjGUID = @ProjGUID;
    END

    UPDATE a
       SET a.ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode), -- 更换一级项目编码
           a.BUGUID = @BuGUIDNew                                             -- 设置新公司GUID
      FROM cg_CgApply a
     WHERE a.ProjGUID = @ProjGUID;    -- FIXME: 如果ProjCode是项目编码，此处条件可能需确认

    PRINT '采购申请表:cg_CgApply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    /***********************************************************
    * 2. 采购计划表 cg_CgPlan
    * 按涉及分期项目数据进行备份和更新
    ************************************************************/
    PRINT '采购计划表:cg_CgPlan';
    IF OBJECT_ID(N'cg_CgPlan_bak_20251027', N'U') IS NULL
    BEGIN
        SELECT a.*
          INTO dbo.cg_CgPlan_bak_20251027
          FROM cg_CgPlan a
         WHERE CHARINDEX(CONVERT(VARCHAR(50), @ProjGUID), a.ProjectGUIDList) <> 0;
    END

    UPDATE a
       SET a.ProjectCodeList = REPLACE(ProjectCodeList, @OldTopProjCode, @NewTopProjCode), -- 替换一级项目编码
           a.BUGUID = @BuGUIDNew                                                            -- 设置新公司GUID
      FROM cg_CgPlan a
     WHERE CHARINDEX(CONVERT(VARCHAR(50), @ProjGUID), a.ProjectGUIDList) <> 0;

    PRINT '采购计划表:cg_CgPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- 以下表无数据，无需处理（已业务判定，保留注释）
    -- cg_CgCategory
    -- cg_CgCategory_History
    -- cg_CgPlanApproveHistory
    -- cg_CgPlanCollection
    -- cg_CgPlanWork
    -- cg_CgRequest
    -- cg_ExpertType
    -- cg_p_ProjectProduct
    -- cg_PGPlanProvider
    -- cg_PGZrrSetting
    -- cg_TacticCgProviderCoordination
    -- cg_WorkReportCgPlan
    -- cg_ZBTypeWorkTemp

    /***********************************************************
    * 3. 采购方案关联计划表 cg_CgSolutionLinkedPlan
    ************************************************************/
    PRINT '采购方案关联计划表';
    IF OBJECT_ID(N'cg_CgSolutionLinkedPlan_bak_20251027', N'U') IS NULL
    BEGIN
        SELECT a.*
          INTO dbo.cg_CgSolutionLinkedPlan_bak_20251027
          FROM cg_CgSolutionLinkedPlan a
         WHERE a.projguid = @ProjGUID;
    END

    UPDATE a
       SET a.ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode)
      FROM cg_CgSolutionLinkedPlan a
     WHERE a.projguid = @ProjGUID;

    PRINT '采购方案关联计划表:cg_CgSolutionLinkedPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    /***********************************************************
    * 4. 文档归档表 cg_DocArchive
    ************************************************************/
    PRINT '文档归档表';
    IF OBJECT_ID(N'cg_DocArchive_bak_20251027', N'U') IS NULL
    BEGIN
        SELECT a.*
          INTO dbo.cg_DocArchive_bak_20251027
          FROM cg_DocArchive a
         WHERE a.projguid = @ProjGUID;
    END

    UPDATE a
       SET a.ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode),
           a.BUGUID  = @BuGUIDNew
      FROM cg_DocArchive a
     WHERE a.projguid = @ProjGUID;

    PRINT '文档归档表:cg_DocArchive' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    /***********************************************************
    * 5. 履约评估计划表 cg_PGPlan
    ************************************************************/
    PRINT '履约评估计划表';
    IF OBJECT_ID(N'cg_PGPlan_bak_20251027', N'U') IS NULL
    BEGIN
        SELECT a.*
          INTO dbo.cg_PGPlan_bak_20251027
          FROM cg_PGPlan a
         WHERE CHARINDEX(CONVERT(VARCHAR(50), @ProjGUID), a.ProjGUIDList) <> 0;
    END

    UPDATE a
       SET a.BUGUID = @BuGUIDNew,
           a.ProjCodeList = REPLACE(ProjCodeList, @OldTopProjCode, @NewTopProjCode)
      FROM cg_PGPlan a
     WHERE CHARINDEX(CONVERT(VARCHAR(50), @ProjGUID), a.ProjGUIDList) <> 0;

    PRINT '履约评估计划表:cg_PGPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    /***********************************************************
    * 6. 项目进退场单据表 cg_PGProjReceipt
    ************************************************************/
    PRINT '项目进退场单据表';
    IF OBJECT_ID(N'cg_PGProjReceipt_bak_20251027', N'U') IS NULL
    BEGIN
        SELECT a.*
          INTO dbo.cg_PGProjReceipt_bak_20251027
          FROM cg_PGProjReceipt a
         WHERE a.ProjGUID  = @ProjGUID;
    END

    UPDATE a
       SET a.ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode)
      FROM cg_PGProjReceipt a
     WHERE a.ProjGUID = @ProjGUID;

    PRINT '项目进退场单据表:cg_PGProjReceipt' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

END
