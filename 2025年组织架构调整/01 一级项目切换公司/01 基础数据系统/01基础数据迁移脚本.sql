--1�����ݶԱ����������ݱ���Ų飬���������֯�ܹ�������Ӱ�����ػ�������ϵͳ�����£�
--  select buguid, * from md_Room
--  select buguid, * from md_RoomTengNuoLog
--  select buguid, * from md_RoomTengNuoApprove
--  select buguid, * from md_RoomPropertyAdjust
--  ƽ̨��˾��
--  SELECT DevelopmentCompanyGUID,* FROM dbo.md_Project
--2����Խű����˵��������£�
-- a����κ�ͬ�����ڶ����Ŀ����ôǨ�ƺ�ͬ��ĳһ����Ŀ���¹�˾���˺�ͬӦ�����������
-- b�����ҵ���е��������ţ����ҵ������Ǩ�Ƶ��µĹ�˾���棬��ô��Щ���Ź����¹�˾���Ǹ���Ӧ�����У�
-- c������ϵͳҵ�����ݶ�Ӧ�Ĺ�˾GUID���߲�����ϢҪͳһ����Ǩ��
-- d������ϵͳҵ�����ݵ���Ŀ������Ҫ������������Ŀ����Ŀ����
-- e��ҵ�����Ǩ����Ҫ���ʵ�ʳ������кϲ��޸������ҵ��������ͨ��ҵ�����GUID����ʹ�õģ�����Ҫ��ҵ�����ݶ�Ӧ��ҵ�����ˢ�³����µ�ҵ�����GUID
USE MyCost_Erp352;
GO

/****** Object:  StoredProcedure [dbo].[usp_mdm_Updatemdm]    Script Date: 2021/3/3 13:21:50 ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

--exec [usp_mdm_Updatemdm_20240613]

CREATE PROC [dbo].[usp_mdm_Updatemdm_20240613]
/*
     �޸Ļ���������Ŀ����ƽ̨��˾��Ϣ
     */
AS
    BEGIN --��ȡ��Ǩ����Ϣ��
        SELECT  * INTO  #dqy_proj FROM  dqy_proj_20240613;

        --�޸���Ŀ������˾
        IF OBJECT_ID(N'md_Project_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_Project_bak_20240613
            FROM    dbo.md_Project a
                    INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = b.NewDevelopmentCompanyGUID
        FROM    md_Project a
                INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT '��Ŀ��:md_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'md_Project_work_bak_20240613', N'U') IS NULL
            SELECT  A.*
            INTO    dbo.md_Project_work_bak_20240613
            FROM    dbo.md_Project_work A
                    INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = b.NewDevelopmentCompanyGUID
        FROM    md_Project_work a
                INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT '��Ŀ��:md_Project_work' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --�޸Ļ����������ҵ���
        --������ҵϵͳ��Ŀ��֯�ܹ�:20220113, add by lintx
        IF OBJECT_ID(N'md_Project2OrgCompany_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_Project2OrgCompany_bak_20240613
            FROM    md_Project2OrgCompany a
                    INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        UPDATE  a
        SET a.OrgCompanyGUID = b.NewBuguid
        FROM    md_Project2OrgCompany a
                INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT '������ҵϵͳ��Ŀ��֯�ܹ�:md_Project2OrgCompany' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --������Ϣ��
        IF OBJECT_ID(N'md_Room_bak_20240613', N'U') IS NULL
            SELECT  A.*
            INTO    dbo.md_Room_bak_20240613
            FROM    dbo.md_Room A
                    INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        UPDATE  A
        SET A.BUGUID = B.NewBuguid
        FROM    dbo.md_Room A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        PRINT '������Ϣ��:md_Room' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --������Ų��־��  
        IF OBJECT_ID(N'md_RoomTengNuoLog_bak_20240613', N'U') IS NULL
            SELECT  A.*
            INTO    dbo.md_RoomTengNuoLog_bak_20240613
            FROM    dbo.md_RoomTengNuoLog A
                    INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        UPDATE  A
        SET A.BUGUID = B.NewBuguid
        FROM    dbo.md_RoomTengNuoLog A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        PRINT '������Ų��־��:md_RoomTengNuoLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --������Ų��˱�
        IF OBJECT_ID(N'md_RoomTengNuoApprove_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_RoomTengNuoApprove_bak_20240613
            FROM    dbo.md_RoomTengNuoApprove a
                    INNER JOIN md_Room r ON r.RoomGUID = a.RoomGUID
                    INNER JOIN #dqy_proj B ON r.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.BUGUID = B.NewBuguid
        FROM    md_RoomTengNuoApprove a
                INNER JOIN md_Room r ON r.RoomGUID = a.RoomGUID
                INNER JOIN #dqy_proj B ON r.ProjGUID = B.OldProjGuid;

        PRINT '������Ų��˱�:md_RoomTengNuoApprove' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --����ʹ�����Ե���������
        IF OBJECT_ID(N'md_RoomPropertyAdjust_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_RoomPropertyAdjust_bak_20240613
            FROM    dbo.md_RoomPropertyAdjust a
                    INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.BUGUID = B.NewBuguid
        FROM    md_RoomPropertyAdjust a
                INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        PRINT '����ʹ�����Ե���������:md_RoomPropertyAdjust' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        -- md_ProjectOperLog 
        IF OBJECT_ID(N'md_ProjectOperLog_bak_20240613', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_ProjectOperLog_bak_20240613
            FROM    dbo.md_ProjectOperLog a
                    INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = B.NewDevelopmentCompanyGUID
        FROM    md_ProjectOperLog a
                INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        PRINT 'md_ProjectOperLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

		--md_ZBPCRemindSetû�����ݲ�����

        /*--������֯�ܹ���˾��ƽ̨��˾��ӳ���ϵ
        IF OBJECT_ID(N'companyjoin_bak_20240613', N'U') IS NULL
            SELECT  a.* INTO    dbo.companyjoin_bak_20240613 FROM   dbo.CompanyJoin a;

        INSERT INTO CompanyJoin
        SELECT  NEWID() AS companyjoinguid ,
                (SELECT DevelopmentCompanyGUID
                 FROM   dbo.p_DevelopmentCompanyNew
                 WHERE  DevelopmentCompanyGUID = NewDevelopmentCompanyGUID) AS DevelopmentCompanyGUID ,
                (SELECT DevelopmentCompanyName
                 FROM   dbo.p_DevelopmentCompanyNew
                 WHERE  DevelopmentCompanyGUID = NewDevelopmentCompanyGUID) AS DevelopmentCompanyName ,
                (SELECT BUGUID
                 FROM   dbo.myBusinessUnit
                 WHERE  BUGUID = a.NewBuguid AND IsEndCompany = 1) AS buguid ,
                (SELECT BUName
                 FROM   dbo.myBusinessUnit
                 WHERE  BUGUID = a.NewBuguid AND IsEndCompany = 1) AS buname
        FROM(SELECT DISTINCT NewBuguid, NewDevelopmentCompanyGUID FROM  #dqy_proj) a
            LEFT JOIN CompanyJoin b ON a.NewBuguid = b.buguid
        WHERE   b.buguid IS NULL;

        PRINT '��֯�ܹ���˾��ƽ̨��˾��ӳ���ϵcompanyjoin:' + CONVERT(NVARCHAR(20), @@ROWCOUNT);*/

        --ɾ����ʱ��
        DROP TABLE #dqy_proj;
    END;