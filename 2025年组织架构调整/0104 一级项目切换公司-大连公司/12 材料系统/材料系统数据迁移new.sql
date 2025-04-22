USE dotnet_erp60;
GO

/*注意要替换 MyCost_Erp352_ceshi 以及数据库连接地址库名!!!!!
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏
*/

/*172.16.4.130 erp60库*/
BEGIN
    /*--判断组织架构公司是否存在，如果没有，则需要插入数据
    INSERT INTO dbo.myBusinessUnit(AreaType, BUCode, BUFullName, BUName, BUPersonInCharge, BUType, Charter, CityGUID, Comments, CompanyAddr, CompanyFullName, CompanyGUID, CorporationDeputy ,
                                   erp_bu_guid , erp_bu_name, Fax, FyStationGUID, HierarchyCode, IsCompany, IsEndCompany, IsEndDepartment, IsFc, Level, NamePath, OrderCode, OrderHierarchyCode ,
                                   ParentGUID , PartitionID, ProjGUID, ProvinceGUID, RefStationName, WebSite, BUGUID, CreatedGUID, CreatedName, CreatedTime, ModifiedGUID, ModifiedName, ModifiedTime)
    SELECT  NULL AreaType ,
            BUCode ,
            BUFullName ,
            BUName ,
            BUPersonInCharge ,
            BUType ,
            Charter ,
            NULL CityGUID ,
            Comments ,
            CompanyAddr ,
            NULL CompanyFullName ,
            CompanyGUID ,
            CorporationDeputy ,
            NULL erp_bu_guid ,
            NULL erp_bu_name ,
            Fax ,
            FyStationGUID ,
            HierarchyCode ,
            IsCompany ,
            IsEndCompany ,
            NULL IsEndDepartment ,
            IsFc ,
            Level ,
            NamePath ,
            OrderCode ,
            OrderHierarchyCode ,
            ParentGUID ,
            NULL PartitionID ,
            ProjGUID ,
            NULL ProvinceGUID ,
            RefStationName ,
            WebSite ,
            BUGUID ,
            NULL CreatedGUID ,
            NULL CreatedName ,
            NULL CreatedTime ,
            NULL ModifiedGUID ,
            NULL ModifiedName ,
            NULL ModifiedTime
    FROM    [172.16.4.129].MyCost_Erp352_ceshi.dbo.myBusinessUnit
    WHERE   IsEndCompany = 1 AND BUGUID NOT IN(SELECT   BUGUID FROM dbo.myBusinessUnit);*/

    --处理项目库项目p_Project,注意正式环境需要替换到编码信息

    --创建项目临时表
    SELECT  p.HierarchyCode ,
            ParentCode ,
            ProjCode ,
            bu.HierarchyCode AS newHierarchyCode ,
            bu.BUCode AS newBUCode ,
            old.HierarchyCode AS oldHierarchyCode ,
            old.BUCode AS oldBUCode ,
            t.*
    INTO    #dqy_proj
    FROM    -- [172.16.4.129].MyCost_Erp352.dbo.dqy_proj_20250424 t
            MyCost_Erp352.dbo.dqy_proj_20250424 t
            INNER JOIN dbo.p_Project p ON t.OldProjGuid = p.p_projectId
            INNER JOIN dbo.myBusinessUnit bu ON t.NewBuguid = bu.BUGUID
            INNER JOIN dbo.myBusinessUnit old ON old.BUGUID = t.OldBuguid;

    --处理项目库项目p_Project,注意正式环境需要替换到编码信息
    IF OBJECT_ID(N'p_Project_bak_20250424', N'U') IS NULL
        SELECT  p.*
        INTO    p_Project_bak_20250424
        FROM    dbo.p_Project p
                INNER JOIN #dqy_proj t ON p.p_projectId = t.OldProjGuid;

    UPDATE  p_Project
    SET BUGUID = t.NewBuguid ,
        HierarchyCode = REPLACE(p.HierarchyCode, t.oldHierarchyCode + '.' + t.oldBUCode, newHierarchyCode + '.' + newBUCode) ,
        ParentCode = REPLACE(p.ParentCode, oldBUCode, newBUCode) ,
        ProjCode = REPLACE(p.ProjCode, oldBUCode, newBUCode)
    FROM    dbo.p_Project p
            INNER JOIN #dqy_proj t ON p.p_projectId = t.OldProjGuid;

    PRINT '处理项目库项目p_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    /* --处理服务公司
    IF OBJECT_ID(N'cl_ServiceBusinessUnit_bak_20250121', N'U') IS NULL
        SELECT  p.*
        INTO    cl_ServiceBusinessUnit_bak_20250121
        FROM    dbo.cl_ServiceBusinessUnit p;

    INSERT INTO dbo.cl_ServiceBusinessUnit(Code, FullName, HierarchyCode, Name, ParentGUID, CreatedGUID, CreatedName, CreatedTime, ModifiedGUID, ModifiedName, ModifiedTime, ServiceBusinessUnitGUID ,
                                           Level , HierarchyName)
    SELECT  newBUCode AS Code ,
            '保利发展集团-' + NewBuname AS FullName ,
            newHierarchyCode AS HierarchyCode ,
            NewBuname AS Name ,
            ParentGUID ,
            CreatedGUID ,
            CreatedName ,
            CreatedTime ,
            ModifiedGUID ,
            ModifiedName ,
            ModifiedTime ,
            t.NewBuguid AS ServiceBusinessUnitGUID ,
            Level ,
            HierarchyName
    FROM    cl_ServiceBusinessUnit bu
            INNER JOIN(SELECT   DISTINCT OldBuguid ,
                                         NewBuguid ,
                                         NewBuname ,
                                         newHierarchyCode ,
                                         newBUCode
                       FROM #dqy_proj) t ON bu.ServiceBusinessUnitGUID = t.OldBuguid
    WHERE   t.NewBuguid NOT IN(SELECT   ServiceBusinessUnitGUID FROM    cl_ServiceBusinessUnit);

    PRINT '处理服务公司cl_ServiceBusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
	
    --cl_ClCompany2BusinessUnit
    IF OBJECT_ID(N'cl_ClCompany2BusinessUnit_bak_20250121', N'U') IS NULL
        SELECT  p.*
        INTO    cl_ClCompany2BusinessUnit_bak_20250121
        FROM    dbo.cl_ClCompany2BusinessUnit p;

    INSERT INTO dbo.cl_ClCompany2BusinessUnit(BUGUID, ServiceBusinessUnitGUID, ClCompany2BusinessUnitGUID, CreatedGUID, CreatedName, CreatedTime, ModifiedGUID, ModifiedName, ModifiedTime)
    SELECT  t.NewBuguid AS BUGUID ,
            ServiceBusinessUnitGUID ,
            NEWID() ClCompany2BusinessUnitGUID ,
            CreatedGUID ,
            CreatedName ,
            CreatedTime ,
            ModifiedGUID ,
            ModifiedName ,
            ModifiedTime
    FROM    cl_ServiceBusinessUnit bu
            INNER JOIN(SELECT   DISTINCT OldBuguid ,
                                         NewBuguid ,
                                         NewBuname ,
                                         newHierarchyCode ,
                                         newBUCode
                       FROM #dqy_proj) t ON bu.ServiceBusinessUnitGUID = t.NewBuguid
    WHERE   t.NewBuguid NOT IN(SELECT   BUGUID FROM cl_ClCompany2BusinessUnit);

    PRINT '处理材料公司服务公司（组织公司）关系表cl_ClCompany2BusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
	*/

    --cl_ClCompany2ServiceProject材料公司（组织公司）服务项目关系表
    IF OBJECT_ID(N'cl_ClCompany2ServiceProject_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    cl_ClCompany2ServiceProject_bak_20250424
        FROM    cl_ClCompany2ServiceProject a
                INNER JOIN cl_ServiceProject b ON b.ServiceProjectGUID = a.ServiceProjectGUID
                INNER JOIN #dqy_proj pj ON pj.HierarchyCode = b.HierarchyCode;

    --INNER JOIN(SELECT   DISTINCT oldbuguid, NewBuguid FROM  #dqy_proj) p ON p.oldbuguid = b.BUGUID;
    UPDATE  a
    SET a.BUGUID = pj.NewBUGUID ,
        a.ServiceBusinessUnitGUID = pj.NewBUGUID
    FROM    cl_ClCompany2ServiceProject a
            INNER JOIN cl_ServiceProject b ON b.ServiceProjectGUID = a.ServiceProjectGUID
            INNER JOIN #dqy_proj pj ON pj.HierarchyCode = b.HierarchyCode
    -- INNER JOIN(SELECT   DISTINCT oldbuguid, NewBuguid FROM  #dqy_proj) p ON p.oldbuguid = b.BUGUID;
    WHERE   a.BUGUID <> pj.NewBUGUID;

    PRINT '材料公司（组织公司）服务项目关系表cl_ClCompany2ServiceProject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --cl_ServiceProject服务项目
    IF OBJECT_ID(N'cl_ServiceProject_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    cl_ServiceProject_bak_20250424
        FROM    cl_ServiceProject a
                INNER JOIN #dqy_proj b ON b.HierarchyCode = a.HierarchyCode
                INNER JOIN dbo.p_Project p ON p.p_projectId = b.OldProjGuid;

    UPDATE  a
    SET a.BUGUID = p.BUGUID ,
        a.Code = p.ProjCode ,
        a.HierarchyCode = p.HierarchyCode
    FROM    cl_ServiceProject a
            INNER JOIN #dqy_proj b ON b.HierarchyCode = a.HierarchyCode
            INNER JOIN dbo.p_Project p ON p.p_projectId = b.OldProjGuid;

    PRINT '处理服务项目cl_ServiceProject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --====================================================================================================================
    --处理业务数据
    --材料申请表
    IF OBJECT_ID(N'cl_Apply_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Apply_bak_20250424
        FROM    cl_Apply a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Apply a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '材料申请表cl_Apply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --订单表
    IF OBJECT_ID(N'cl_Order_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Order_bak_20250424
        FROM    cl_Order a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Order a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '订单表cl_Order' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --验收单
    IF OBJECT_ID(N'cl_Recipient_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Recipient_bak_20250424
        FROM    cl_Recipient a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Recipient a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '验收单cl_Recipient' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --退货单
    IF OBJECT_ID(N'x_cl_ReturnOrder_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    x_cl_ReturnOrder_bak_20250424
        FROM    x_cl_ReturnOrder a
                INNER JOIN dbo.p_Project p ON a.x_ProjGUID = p.p_projectId
        WHERE   a.x_ProjGUID IN(SELECT  OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.x_BUGUID = p.BUGUID
    FROM    x_cl_ReturnOrder a
            INNER JOIN dbo.p_Project p ON a.x_ProjGUID = p.p_projectId
    WHERE   a.x_ProjGUID IN(SELECT  OldProjGuid FROM    #dqy_proj);

    PRINT '退货单x_cl_ReturnOrder' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --材料合同表
    IF OBJECT_ID(N'cl_Contract_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Contract_bak_20250424
        FROM    cl_Contract a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Contract a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '材料合同表cl_Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --实际用料计划表
    IF OBJECT_ID(N'cl_ProductRequirement_bak_20250424', N'U') IS NULL
        SELECT  a.*
        INTO    cl_ProductRequirement_bak_20250424
        FROM    cl_ProductRequirement a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_ProductRequirement a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '实际用料计划表cl_ProductRequirement' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --材料表（适用区域）
    --SELECT * FROM dbo.cl_Product WHERE pr

    --材料适用区域关系表
    --SELECT * FROM cl_Product2BusinessUnit

    --战略协议表（项目暂未使用）
    --SELECT *
    --FROM   cl_TacticCgAgreement a
    --     INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    --WHERE  a.ProjGUID IN ( SELECT p_projectId FROM #proj );

    --删除临时表
    --DROP TABLE #dqy_proj;
END;
