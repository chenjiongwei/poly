--  SELECT sys.objects.name 表名 ,
--         sys.columns.name  字段名称,
--         sys.types.name 数据类型,
--         sys.columns.max_length 长度,
--  	   sys.objects.create_date 创建日期
--  FROM   sys.objects
--         LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
--         LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
--  WHERE (sys.columns.name = 'projcode' OR sys.columns.name = 'ParentProjGUID' OR sys.columns.name ='ParentGUID' OR sys.columns.name = 'ParentCode') AND
--         sys.objects.type = 'U'
--         AND sys.objects.name LIKE 'cb_%'
--            ORDER BY sys.objects.name,sys.columns.column_id

USE  erp25
go 

-- mdm_LXqueDw
-- mdm_Project
-- mdm_Project_construction_cst1_fenqu
-- mdm_Project_construction_cst1_fenqu_GCbld
-- mdm_Project_Sync
-- mdm_zgprojinfo


BEGIN
    -- 杓袁项目7号地  0e63e1ad-4703-4a95-b661-9e8e415e041f
     SELECT  * INTO  #dqy_proj FROM  dqy_proj_20251027;  
    
     --mdm_LXqueDw只有一级项目
       
     -- 项目表mdm_Project
   IF OBJECT_ID(N'mdm_Project_bak_20251027', N'U') IS NULL
    SELECT  a.*
    INTO    dbo.mdm_Project_bak_20251027
    FROM    dbo.mdm_Project a
    
    
    UPDATE a
        SET 
            a.projcode = b.[NewParentprojCode25] + SUBSTRING(a.ProjCode, CHARINDEX('-', a.ProjCode), LEN(a.ProjCode) - 1),
            a.ParentProjGUID = b.newparentprojguid
        FROM mdm_Project a
        INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

    PRINT N'项目表:mdm_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);    

    -- mdm_Project_Sync 
   IF OBJECT_ID(N'mdm_Project_Sync_bak_20251027', N'U') IS NULL
    SELECT  a.*
    INTO    dbo.mdm_Project_Sync_bak_20251027
    FROM    dbo.mdm_Project_Sync a
    INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;
    
    
    UPDATE a
        SET 
            a.projcode = b.[NewParentprojCode25] + SUBSTRING(a.ProjCode, CHARINDEX('-', a.ProjCode), LEN(a.ProjCode) - 1),
            a.ParentProjGUID = b.newparentprojguid
        FROM mdm_Project_Sync a
        INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

    PRINT N'项目表:mdm_Project_Sync' + CONVERT(NVARCHAR(20), @@ROWCOUNT);    


    -- 

end