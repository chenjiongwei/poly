use  TaskCenterData
go 

 EXEC [usp_cb_ChgProjMoveFq_Inventory] 
     'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 新公司GUID
     'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 旧公司GUID
     '5F4A536B-D813-E911-80BF-E61F13C57837'  -- 分期项目GUID

--- 成本系统存货部分相关表的迁移
create or ALTER  PROC [dbo].[usp_cb_ChgProjMoveFq_Inventory]
    (
      @BuGUIDNew UNIQUEIDENTIFIER ,
      @BuGUIDOld UNIQUEIDENTIFIER ,
      @ProjGUID UNIQUEIDENTIFIER --分期项目GUID
    --   @OldTopProjCode VARCHAR(50), --老一级项目code
    --   @NewTopProjCode VARCHAR(50) --新一级项目code
    )
AS
begin

        DECLARE @OldTopProjCode VARCHAR(50); -- 老一级项目code
        DECLARE @NewTopProjCode VARCHAR(50); -- 新一级项目code

        SELECT 
            @OldTopProjCode = OldParentprojCode352,
            @NewTopProjCode = NewParentprojCode352 
        FROM 
            MyCost_Erp352.dbo.dqy_proj_20251027 AS a
        WHERE 
            OldProjGuid = @ProjGUID;

   
     
        ALTER TABLE cb_ProductJzCbList DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_ProductJzCbList_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_ProductJzCbList_bak_20251027
            FROM    dbo.cb_ProductJzCbList
            where cb_ProductJzCbList.ProjGUID =@ProjGUID;

        UPDATE  cb_ProductJzCbList
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_ProductJzCbList成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

         ALTER TABLE cb_ProductJzCbList ENABLE TRIGGER ALL;
     

        ALTER TABLE cb_StockFtCostImport DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockFtCostImport_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockFtCostImport_bak_20251027
            FROM    dbo.cb_StockFtCostImport
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockFtCostImport
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockFtCostImport成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockFtCostImport ENABLE TRIGGER ALL;


        -- cb_StockFtCostImportPhoto
        ALTER TABLE cb_StockFtCostImportPhoto DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockFtCostImportPhoto_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockFtCostImportPhoto_bak_20251027
            FROM    dbo.cb_StockFtCostImportPhoto
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockFtCostImportPhoto
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockFtCostImportPhoto成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockFtCostImportPhoto ENABLE TRIGGER ALL;


        -- cb_StockFtCostPhoto

          ALTER TABLE cb_StockFtCostPhoto DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockFtCostPhoto_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockFtCostPhoto_bak_20251027
            FROM    dbo.cb_StockFtCostPhoto
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockFtCostPhoto
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockFtCostPhoto成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockFtCostPhoto ENABLE TRIGGER ALL;


        -- cb_StockFtCostTwo
        ALTER TABLE cb_StockFtCostTwo DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockFtCostTwo_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockFtCostTwo_bak_20251027
            FROM    dbo.cb_StockFtCostTwo
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockFtCostTwo
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockFtCostPhoto成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockFtCostTwo ENABLE TRIGGER ALL;

        -- cb_StockFtProjVersionZb

        ALTER TABLE cb_StockFtProjVersionZb DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockFtCostTwo_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockFtProjVersionZb_bak_20251027
            FROM    dbo.cb_StockFtProjVersionZb
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockFtProjVersionZb
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockFtProjVersionZb成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockFtProjVersionZb ENABLE TRIGGER ALL;
        
        -- cb_StockFtProjVersionZbPhoto
        ALTER TABLE cb_StockFtProjVersionZb DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockFtCostTwo_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockFtProjVersionZb_bak_20251027
            FROM    dbo.cb_StockFtProjVersionZb
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockFtProjVersionZb
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockFtProjVersionZb成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockFtProjVersionZb ENABLE TRIGGER ALL;
        

        -- cb_StockHZXMCost
        ALTER TABLE cb_StockHZXMCost DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockFtCostTwo_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockHZXMCost_bak_20251027
            FROM    dbo.cb_StockHZXMCost
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockHZXMCost
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockHZXMCost成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockHZXMCost ENABLE TRIGGER ALL;

        -- cb_StockHZXMProjVersionZb

        ALTER TABLE cb_StockHZXMProjVersionZb DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_StockHZXMProjVersionZb_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_StockHZXMProjVersionZb_bak_20251027
            FROM    dbo.cb_StockHZXMProjVersionZb
            where ProjGUID =@ProjGUID;

        UPDATE  cb_StockHZXMProjVersionZb
        SET    
                ProjCode = replace(ProjCode, @OldTopProjCode, @NewTopProjCode)
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '更新cb_StockHZXMCost成功：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_StockHZXMProjVersionZb ENABLE TRIGGER ALL;


end 