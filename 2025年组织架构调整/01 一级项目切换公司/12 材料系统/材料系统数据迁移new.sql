USE dotnet_erp60;
GO

/*172.16.4.130 erp60��*/
BEGIN
    /*--�ж���֯�ܹ���˾�Ƿ���ڣ����û�У�����Ҫ��������
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
    FROM    [172.16.4.129].MyCost_Erp352.dbo.myBusinessUnit
    WHERE   IsEndCompany = 1 AND BUGUID NOT IN(SELECT   BUGUID FROM dbo.myBusinessUnit);*/

    --������Ŀ����Ŀp_Project,ע����ʽ������Ҫ�滻��������Ϣ

    --������Ŀ��ʱ��
    SELECT  p.HierarchyCode ,
            ParentCode ,
            ProjCode ,
            bu.HierarchyCode AS newHierarchyCode ,
            bu.BUCode AS newBUCode ,
            old.HierarchyCode AS oldHierarchyCode ,
            old.BUCode AS oldBUCode ,
            t.*
    INTO    #dqy_proj
    FROM    [172.16.4.129].MyCost_Erp352.dbo.dqy_proj_20240613 t
            INNER JOIN dbo.p_Project p ON t.OldProjGuid = p.p_projectId
            INNER JOIN dbo.myBusinessUnit bu ON t.NewBuguid = bu.BUGUID
            INNER JOIN dbo.myBusinessUnit old ON old.BUGUID = t.OldBuguid;

    --������Ŀ����Ŀp_Project,ע����ʽ������Ҫ�滻��������Ϣ
    IF OBJECT_ID(N'p_Project_bak_20240613', N'U') IS NULL
        SELECT  p.*
        INTO    p_Project_bak_20240613
        FROM    dbo.p_Project p
                INNER JOIN #dqy_proj t ON p.p_projectId = t.OldProjGuid;

    UPDATE  p_Project
    SET BUGUID = t.NewBuguid ,
        HierarchyCode = REPLACE(p.HierarchyCode, t.oldHierarchyCode + '.' + t.oldBUCode, newHierarchyCode + '.' + newBUCode) ,
        ParentCode = REPLACE(p.ParentCode, oldBUCode, newBUCode) ,
        ProjCode = REPLACE(p.ProjCode, oldBUCode, newBUCode)
    FROM    dbo.p_Project p
            INNER JOIN #dqy_proj t ON p.p_projectId = t.OldProjGuid;

    PRINT '������Ŀ����Ŀp_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    /* --�������˾
    IF OBJECT_ID(N'cl_ServiceBusinessUnit_bak_20240613', N'U') IS NULL
        SELECT  p.*
        INTO    cl_ServiceBusinessUnit_bak_20240613
        FROM    dbo.cl_ServiceBusinessUnit p;

    INSERT INTO dbo.cl_ServiceBusinessUnit(Code, FullName, HierarchyCode, Name, ParentGUID, CreatedGUID, CreatedName, CreatedTime, ModifiedGUID, ModifiedName, ModifiedTime, ServiceBusinessUnitGUID ,
                                           Level , HierarchyName)
    SELECT  newBUCode AS Code ,
            '������չ����-' + NewBuname AS FullName ,
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

    PRINT '�������˾cl_ServiceBusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
	
    --cl_ClCompany2BusinessUnit
    IF OBJECT_ID(N'cl_ClCompany2BusinessUnit_bak_20240613', N'U') IS NULL
        SELECT  p.*
        INTO    cl_ClCompany2BusinessUnit_bak_20240613
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

    PRINT '������Ϲ�˾����˾����֯��˾����ϵ��cl_ClCompany2BusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
	*/

    --cl_ClCompany2ServiceProject���Ϲ�˾����֯��˾��������Ŀ��ϵ��
    IF OBJECT_ID(N'cl_ClCompany2ServiceProject_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    cl_ClCompany2ServiceProject_bak_20240613
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

    PRINT '���Ϲ�˾����֯��˾��������Ŀ��ϵ��cl_ClCompany2ServiceProject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --cl_ServiceProject������Ŀ
    IF OBJECT_ID(N'cl_ServiceProject_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    cl_ServiceProject_bak_20240613
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

    PRINT '���������Ŀcl_ServiceProject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --====================================================================================================================
    --����ҵ������
    --���������
    IF OBJECT_ID(N'cl_Apply_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Apply_bak_20240613
        FROM    cl_Apply a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Apply a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '���������cl_Apply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --������
    IF OBJECT_ID(N'cl_Order_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Order_bak_20240613
        FROM    cl_Order a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Order a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '������cl_Order' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --���յ�
    IF OBJECT_ID(N'cl_Recipient_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Recipient_bak_20240613
        FROM    cl_Recipient a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Recipient a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '���յ�cl_Recipient' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --�˻���
    IF OBJECT_ID(N'x_cl_ReturnOrder_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    x_cl_ReturnOrder_bak_20240613
        FROM    x_cl_ReturnOrder a
                INNER JOIN dbo.p_Project p ON a.x_ProjGUID = p.p_projectId
        WHERE   a.x_ProjGUID IN(SELECT  OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.x_BUGUID = p.BUGUID
    FROM    x_cl_ReturnOrder a
            INNER JOIN dbo.p_Project p ON a.x_ProjGUID = p.p_projectId
    WHERE   a.x_ProjGUID IN(SELECT  OldProjGuid FROM    #dqy_proj);

    PRINT '�˻���x_cl_ReturnOrder';

    --���Ϻ�ͬ��
    IF OBJECT_ID(N'cl_Contract_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    cl_Contract_bak_20240613
        FROM    cl_Contract a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_Contract a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT '���Ϻ�ͬ��cl_Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --ʵ�����ϼƻ���
    IF OBJECT_ID(N'cl_ProductRequirement_bak_20240613', N'U') IS NULL
        SELECT  a.*
        INTO    cl_ProductRequirement_bak_20240613
        FROM    cl_ProductRequirement a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
        WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    UPDATE  a
    SET a.BUGUID = p.BUGUID
    FROM    cl_ProductRequirement a
            INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    WHERE   a.ProjGUID IN(SELECT    OldProjGuid FROM    #dqy_proj);

    PRINT 'ʵ�����ϼƻ���cl_ProductRequirement' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --���ϱ���������
    --SELECT * FROM dbo.cl_Product WHERE pr

    --�������������ϵ��
    --SELECT * FROM cl_Product2BusinessUnit

    --ս��Э�����Ŀ��δʹ�ã�
    --SELECT *
    --FROM   cl_TacticCgAgreement a
    --     INNER JOIN dbo.p_Project p ON a.ProjGUID = p.p_projectId
    --WHERE  a.ProjGUID IN ( SELECT p_projectId FROM #proj );

    --ɾ����ʱ��
    --DROP TABLE #dqy_proj;
END;
