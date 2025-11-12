USE [dotnet_erp60]
GO
/*
================================================================================
 用于辅助查表与字段信息的临时代码，可根据实际需要取消注释运行
================================================================================
-- 查询所有以cl_开头的表，获取其与项目、层级相关的主要字段，便于核查数据结构
SELECT sys.objects.name AS 表名,
       sys.columns.name AS 字段名称,
       sys.types.name AS 数据类型,
       sys.columns.max_length AS 长度,
       sys.objects.create_date AS 创建日期
FROM   sys.objects
LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
WHERE (
         sys.columns.name = 'projcode'        -- 项目编码
      OR sys.columns.name = 'ParentProjGUID'  -- 父级项目GUID
      OR sys.columns.name = 'ParentGUID'      -- 父级GUID（可能是项目或其他）
      OR sys.columns.name = 'ParentName'      -- 父级名称
      OR sys.columns.name = 'ParentCode'      -- 父级编码
      OR sys.columns.name LIKE '%FullName'    -- 层级全路径
      OR sys.columns.name = 'HierarchyCode'   -- 层级编码
    )
    AND sys.objects.type = 'U'
    AND sys.objects.name LIKE 'cl__%'
ORDER BY sys.objects.name, sys.columns.column_id
*/

--  EXEC usp_cl_ChgProjMoveFq 
--      'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 新公司GUID
--      'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 旧公司GUID
--      '0E63E1AD-4703-4A95-B661-9E8E415E041F'    -- 分期项目GUID

--------------------------------------------------------------------------------
-- 材料系统分期项目迁移脚本主逻辑
-- 实现分期项目相关基础表的公司、项目关系数据切换
--------------------------------------------------------------------------------
CREATE OR ALTER PROC [dbo].[usp_cl_ChgProjMoveFq]
(
    @BuGUIDNew       UNIQUEIDENTIFIER,   -- 新公司GUID
    @BuGUIDOld       UNIQUEIDENTIFIER,   -- 旧公司GUID
    @ProjGUID        UNIQUEIDENTIFIER   -- 分期项目GUID
    -- @OldTopProjCode  VARCHAR(50),        -- 原一级项目编码
    -- @NewTopProjCode  VARCHAR(50)         -- 新一级项目编码
)
AS
BEGIN
    SET NOCOUNT OFF;

        -- 定义变量
    DECLARE  @OldTopProjCode VARCHAR(50) --老一级项目code
    DECLARE  @NewTopProjCode VARCHAR(50) --新一级项目code

    select  
          @OldTopProjCode =OldParentprojCode352,
          @NewTopProjCode=NewParentprojCode352 
    from MyCost_Erp352.dbo.dqy_proj_20251027 a 
    where OldProjGuid = @ProjGUID
    -- =========================================================================
    -- 1. 构建分期项目信息临时表 #dqy_proj
    --    包含分期项目信息、新旧公司层级编码/编码等。
    --    便于后续批量处理各基础表数据的迁移与编码替换
    -- =========================================================================
    SELECT  
        p.p_projectId,                           -- 分期项目ID
        p.HierarchyCode AS OldHierarchyCode,     -- 分期原层级编码
        @OldTopProjCode   AS OldTopProjCode,     -- 旧一级项目编码
        @NewTopProjCode   AS NewTopProjCode,     -- 新一级项目编码
        p.ProjCode        AS OldProjCode,        -- 分期原项目编码
        @BuGUIDNew        AS NewBuGUID,          -- 新公司GUID
        bu.HierarchyCode  AS newBuHierarchyCode, -- 新公司层级编码
        bu.BUCode         AS newBUCode,          -- 新公司编码
        @BuGUIDOld        AS BuGUIDOld,          -- 旧公司GUID
        old.HierarchyCode AS oldBuHierarchyCode, -- 旧公司层级编码
        old.BUCode        AS oldBUCode,          -- 旧公司编码
        (SELECT TOP 1 ProjName FROM p_Project WHERE Level = 2 AND ProjCode = @OldTopProjCode) AS OldTopProjName,  -- 原一级项目GUID
        (SELECT TOP 1 ProjName FROM p_Project WHERE Level = 2 AND ProjCode = @NewTopProjCode) AS NewTopProjName,  -- 新一级项目GUID   
        (SELECT TOP 1 p_projectId FROM p_Project WHERE Level = 2 AND ProjCode = @OldTopProjCode) AS OldTopProjGUID,  -- 原一级项目GUID
        (SELECT TOP 1 p_projectId FROM p_Project WHERE Level = 2 AND ProjCode = @NewTopProjCode) AS NewTopProjGUID   -- 新一级项目GUID
    INTO #dqy_proj
    FROM dbo.p_Project p
        -- 这里t未定义，逻辑有误，应补充参数来源或相关表，如需根据参数直接取公司
        INNER JOIN dbo.myBusinessUnit bu  ON bu.BUGUID  = @BuGUIDNew
        INNER JOIN dbo.myBusinessUnit old ON old.BUGUID = @BuGUIDOld
    WHERE p.p_projectId = @ProjGUID;

    select  * from #dqy_proj
    

    --------------------------------------------------------------------------
    -- 2. 备份涉及分期项目的数据到临时备份表（如不存在）
    --------------------------------------------------------------------------
    IF OBJECT_ID(N'p_Project_bak_202501027', N'U') IS NULL
    BEGIN
        SELECT p.*
        INTO   p_Project_bak_202501027
        FROM   dbo.p_Project p
               INNER JOIN #dqy_proj t ON p.p_projectId = t.p_projectId;
    END

    --------------------------------------------------------------------------
    -- 3. 更新分期项目(p_Project)主数据
    --    - 公司GUID/层级编码/父级编码及GUID/项目编码等，根据新旧项目信息调整
    --------------------------------------------------------------------------
    UPDATE p
       SET
            BUGUID        = t.NewBuGUID,
            -- 替换层级编码中的旧一级项目编码为新一级项目编码
            HierarchyCode = REPLACE(p.HierarchyCode, t.OldTopProjCode, t.NewTopProjCode),
            ParentCode    = REPLACE(p.ParentCode, t.OldTopProjCode, t.NewTopProjCode),
            projname = REPLACE(p.projname, t.OldTopProjName, t.NewTopProjName),
            ParentGUID    = t.NewTopProjGUID,
            ProjCode      = REPLACE(p.ProjCode, t.OldTopProjCode, t.NewTopProjCode)
      FROM dbo.p_Project p
           INNER JOIN #dqy_proj t ON p.p_projectId = t.p_projectId;

    PRINT N'处理项目库项目p_Project，更新行数: ' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --------------------------------------------------------------------------
    -- 4. 仅注释：以下表无数据无需处理，业务已排查
    --    cl_ClCompanyUserGrant
    --    cl_FundParam
    --    cl_ProductCategory
    --    cl_Provider2Provider
    --    cl_SaleContractType
    --    cl_ServiceBusinessUnit
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- 5. 服务项目(cl_ServiceProject)迁移
    --    - 备份：保存涉及旧层级编码的数据
    --    - 更新：将公司、项目编码与层级编码切换为新分期目标公司&项目
    --------------------------------------------------------------------------
    IF OBJECT_ID(N'cl_ServiceProject_bak_20251027', N'U') IS NULL
    BEGIN
        SELECT a.*
        INTO   cl_ServiceProject_bak_20251027
        FROM   cl_ServiceProject a
               INNER JOIN #dqy_proj b ON b.OldHierarchyCode = a.HierarchyCode
               INNER JOIN dbo.p_Project p ON p.p_projectId = b.p_projectId;
    END

    UPDATE a
       SET a.BUGUID        = p.BUGUID,         -- 切换新公司
           a.Code          = p.ProjCode,       -- 替换新的项目编码
           a.HierarchyCode = p.HierarchyCode   -- 更新新层级编码
      FROM cl_ServiceProject a
           INNER JOIN #dqy_proj b ON b.OldHierarchyCode = a.HierarchyCode
           INNER JOIN dbo.p_Project p ON p.p_projectId = b.p_projectId;

    PRINT N'处理服务项目cl_ServiceProject，更新行数: ' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

END