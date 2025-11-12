USE MyCost_Erp352
GO

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
     AND sys.objects.name LIKE 'cl_%'
ORDER BY sys.objects.name, sys.columns.column_id


/*172.16.4.129 erp352库*/

BEGIN
    --处理项目库项目p_Project,注意正式环境需要替换到编码信息 
    --创建项目临时表
    SELECT ParentCode,
           ProjCode,
           bu.HierarchyCode AS newHierarchyCode,
           bu.BUCode AS newBUCode,
           old.HierarchyCode AS oldHierarchyCode,
           old.BUCode AS oldBUCode,
           t.*
    INTO #dqy_proj
    FROM dbo.dqy_proj_20250411 t
        INNER JOIN dbo.p_Project p  ON t.OldProjGuid = p.ProjGUID
        INNER JOIN dbo.myBusinessUnit bu   ON t.NewBuguid = bu.BUGUID
        INNER JOIN dbo.myBusinessUnit old ON old.BUGUID = t.OldBuguid;

    --处理业务数据
    --材料申请表
    PRINT '材料申请表cl_Apply';

    IF OBJECT_ID(N'cl_Apply_bak_20250411', N'U') IS NULL
        SELECT a.*
        INTO cl_Apply_bak_20250411
        FROM cl_Apply a
            INNER JOIN dbo.p_Project p
                ON a.ProjGUID = p.ProjGUID
        WHERE a.ProjGUID IN
              (
                  SELECT OldProjGuid FROM #dqy_proj
              );

    UPDATE a
    SET a.BUGUID = p.BUGUID
    FROM cl_Apply a
        INNER JOIN dbo.p_Project p
            ON a.ProjGUID = p.ProjGUID
    WHERE a.ProjGUID IN
          (
              SELECT OldProjGuid FROM #dqy_proj
          );

    --订单表
    PRINT '订单表cl_Order';

    IF OBJECT_ID(N'cl_Order_bak_20250411', N'U') IS NULL
        SELECT a.*
        INTO cl_Order_bak_20250411
        FROM cl_Order a
            INNER JOIN dbo.p_Project p
                ON a.ProjGUID = p.ProjGUID
        WHERE a.ProjGUID IN
              (
                  SELECT OldProjGuid FROM #dqy_proj
              );

    UPDATE a
    SET a.BuGuid = p.BUGUID
    FROM cl_Order a
        INNER JOIN dbo.p_Project p
            ON a.ProjGUID = p.ProjGUID
    WHERE a.ProjGUID IN
          (
              SELECT OldProjGuid FROM #dqy_proj
          );

    --验收单
    PRINT '验收单cl_Recipient';

    IF OBJECT_ID(N'cl_Recipient_bak_20250411', N'U') IS NULL
        SELECT a.*
        INTO cl_Recipient_bak_20250411
        FROM cl_Recipient a
            INNER JOIN dbo.p_Project p
                ON a.ProjGUID = p.ProjGUID
        WHERE a.ProjGUID IN
              (
                  SELECT OldProjGuid FROM #dqy_proj
              );

    UPDATE a
    SET a.BUGUID = p.BUGUID
    FROM cl_Recipient a
        INNER JOIN dbo.p_Project p
            ON a.ProjGUID = p.ProjGUID
    WHERE a.ProjGUID IN
          (
              SELECT OldProjGuid FROM #dqy_proj
          );

    --退货单
    PRINT '退货单cl_ReturnOrder';

    IF OBJECT_ID(N'cl_ReturnOrder_bak_20250411', N'U') IS NULL
        SELECT a.*
        INTO cl_ReturnOrder_bak_20250411
        FROM cl_ReturnOrder a
            INNER JOIN dbo.p_Project p
                ON a.x_ProjGUID = p.ProjGUID
        WHERE a.x_ProjGUID IN
              (
                  SELECT OldProjGuid FROM #dqy_proj
              );

    UPDATE a
    SET a.x_BUGUID = p.BUGUID
    FROM cl_ReturnOrder a
        INNER JOIN dbo.p_Project p
            ON a.x_ProjGUID = p.ProjGUID
    WHERE a.x_ProjGUID IN
          (
              SELECT OldProjGuid FROM #dqy_proj
          );

    --删除临时表
    --DROP TABLE #dqy_proj;
END;
