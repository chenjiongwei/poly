USE [MyCost_Erp352]
GO 

-- SELECT sys.objects.name 表名 ,
--        sys.columns.name  字段名称,
--        sys.types.name 数据类型,
--        sys.columns.max_length 长度,
-- 	   sys.objects.create_date 创建日期
-- FROM   sys.objects
--        LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
--        LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
-- WHERE (sys.columns.name = 'projcode' OR sys.columns.name = 'ParentProjGUID' OR sys.columns.name ='ParentGUID' OR sys.columns.name = 'ParentName') AND
--        sys.objects.type = 'U'
--        AND sys.objects.name LIKE 'md_%'
--           ORDER BY sys.objects.name,sys.columns.column_id

--需要调整的表 projcode 和ParentProjGUID字段
-- md_Project
-- md_Project_Snap
-- md_Project_Work
-- md_ProjectLog
-- md_ProjectOperLog
-- mdm_projforcb  -- 投管系统使用
-- mdm_ProjFQInfoChange -- 投管系统使用

BEGIN 

-- 杓袁项目7号地  0e63e1ad-4703-4a95-b661-9e8e415e041f
    SELECT  * INTO  #dqy_proj FROM  dqy_proj_20251027;

   IF OBJECT_ID(N'md_Project_bak_20251027', N'U') IS NULL
    SELECT  a.*
    INTO    dbo.md_Project_bak_20251027
    FROM    dbo.md_Project a
    
    
    UPDATE a
    SET 
        a.projcode = b.[NewParentprojCode25] + SUBSTRING(a.ProjCode, CHARINDEX('.', a.ProjCode), LEN(a.ProjCode) - 1),
        a.ParentProjGUID = b.newparentprojguid
    FROM md_Project a
    INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

    PRINT N'项目表:md_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- 临时项目表md_Project_Snap
    IF OBJECT_ID(N'md_Project_Snap_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.md_Project_Snap_bak_20251027
        FROM    dbo.md_Project_Snap a
        
        UPDATE a
        SET 
            a.projcode = b.[NewParentprojCode25] + SUBSTRING(a.ProjCode, CHARINDEX('.', a.ProjCode), LEN(a.ProjCode) - 1)
        FROM md_Project_Snap a
        INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT N'项目表:md_Project_Snap' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


   -- 基础数据项目分期编制表 md_Project_Work
    IF OBJECT_ID(N'md_Project_Work_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.md_Project_Work_bak_20251027
        FROM    dbo.md_Project_Work a
        
        UPDATE a
        SET 
            a.projcode = b.[NewParentprojCode25] + SUBSTRING(a.ProjCode, CHARINDEX('.', a.ProjCode), LEN(a.ProjCode) - 1),
            a.ParentProjGUID = b.newparentprojguid
        FROM md_Project_Work a
        INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT N'项目分期编制表:md_Project_Work' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- 修改项目日志表
    IF OBJECT_ID(N'md_ProjectLog_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.md_ProjectLog_bak_20251027
        FROM    dbo.md_ProjectLog a
        INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;
    
        UPDATE a
        SET 
            a.projcode = b.[NewParentprojCode25] + SUBSTRING(a.ProjCode, CHARINDEX('.', a.ProjCode), LEN(a.ProjCode) - 1),
            a.ParentGUID = b.newparentprojguid,
            a.ParentName = c.ProjName
        FROM md_ProjectLog a
        INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid
        inner join  md_Project c on c.ProjGUID = b.newparentprojguid and  c.IsActive =1 and  c.Level =2

        PRINT N'项目日志表:md_ProjectLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- 修改md_ProjectOperLog
     IF OBJECT_ID(N'md_ProjectOperLog_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.md_ProjectOperLog_bak_20251027
        FROM    dbo.md_ProjectOperLog a
        INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

    UPDATE a
    SET 
        a.projcode = b.[NewParentprojCode25] + SUBSTRING(a.ProjCode, CHARINDEX('.', a.ProjCode), LEN(a.ProjCode) - 1),
        a.ParentProjGUID = b.newparentprojguid
    FROM md_ProjectOperLog a
    INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

    PRINT N'项目表:md_ProjectOperLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- md_RoomTengNuoLog
    -- md_RoomTengNuoApprove
    -- md_RoomPropertyAdjust
    -- md_Room


END