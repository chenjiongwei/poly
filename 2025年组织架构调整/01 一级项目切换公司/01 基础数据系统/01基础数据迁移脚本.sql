
--1、根据对保利基础数据表的排查，现梳理出组织架构调整有影响的相关基础数据系统表，如下：
--  select buguid, * from md_Room
--  select buguid, * from md_RoomTengNuoLog
--  select buguid, * from md_RoomTengNuoApprove
--  select buguid, * from md_RoomPropertyAdjust
--  平台公司：
--  SELECT DevelopmentCompanyGUID,* FROM dbo.md_Project
--2、针对脚本复核的问题如下：
-- a、如何合同归属于多个项目，那么迁移合同的某一个项目到新公司，此合同应该如何做处理？
-- b、针对业务中的所属部门，如果业务数据迁移到新的公司下面，那么这些部门挂在新公司的那个对应部门中？
-- c、所有系统业务数据对应的公司GUID或者部门信息要统一进行迁移
-- d、所有系统业务数据的项目编码需要调整成最新项目的项目编码
-- e、业务参数迁移需要针对实际场景进行合并修复，如果业务数据有通过业务参数GUID进行使用的，还需要将业务数据对应的业务参数刷新成最新的业务参数GUID
USE MyCost_Erp352
GO

/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏

*/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

--exec [usp_mdm_Updatemdm_20250121]

CREATE PROC [dbo].[usp_mdm_Updatemdm_20250121]
/*
     修改基础数据项目所属平台公司信息
     */
AS
    BEGIN --获取待迁移信息表
        SELECT  * INTO  #dqy_proj FROM  dqy_proj_20250121;

        --修改项目所属公司
        IF OBJECT_ID(N'md_Project_bak_20250121', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_Project_bak_20250121
            FROM    dbo.md_Project a
                    INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = b.NewDevelopmentCompanyGUID
        FROM    md_Project a
                INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT '项目表:md_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'md_Project_work_bak_20250121', N'U') IS NULL
            SELECT  A.*
            INTO    dbo.md_Project_work_bak_20250121
            FROM    dbo.md_Project_work A
                    INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = b.NewDevelopmentCompanyGUID
        FROM    md_Project_work a
                INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT '项目表:md_Project_work' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --修改基础数据相关业务表
        --留存物业系统项目组织架构:20220113, add by lintx
        IF OBJECT_ID(N'md_Project2OrgCompany_bak_20250121', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_Project2OrgCompany_bak_20250121
            FROM    md_Project2OrgCompany a
                    INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        UPDATE  a
        SET a.OrgCompanyGUID = b.NewBuguid
        FROM    md_Project2OrgCompany a
                INNER JOIN #dqy_proj b ON a.ProjGUID = b.OldProjGuid;

        PRINT '留存物业系统项目组织架构:md_Project2OrgCompany' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --房间信息表
        IF OBJECT_ID(N'md_Room_bak_20250121', N'U') IS NULL
            SELECT  A.*
            INTO    dbo.md_Room_bak_20250121
            FROM    dbo.md_Room A
                    INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        UPDATE  A
        SET A.BUGUID = B.NewBuguid
        FROM    dbo.md_Room A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        PRINT '房间信息表:md_Room' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --房间腾挪日志表  
        IF OBJECT_ID(N'md_RoomTengNuoLog_bak_20250121', N'U') IS NULL
            SELECT  A.*
            INTO    dbo.md_RoomTengNuoLog_bak_20250121
            FROM    dbo.md_RoomTengNuoLog A
                    INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        UPDATE  A
        SET A.BUGUID = B.NewBuguid
        FROM    dbo.md_RoomTengNuoLog A
                INNER JOIN #dqy_proj B ON A.ProjGUID = B.OldProjGuid;

        PRINT '房间腾挪日志表:md_RoomTengNuoLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --房间腾挪审核表
        IF OBJECT_ID(N'md_RoomTengNuoApprove_bak_20250121', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_RoomTengNuoApprove_bak_20250121
            FROM    dbo.md_RoomTengNuoApprove a
                    INNER JOIN md_Room r ON r.RoomGUID = a.RoomGUID
                    INNER JOIN #dqy_proj B ON r.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.BUGUID = B.NewBuguid
        FROM    md_RoomTengNuoApprove a
                INNER JOIN md_Room r ON r.RoomGUID = a.RoomGUID
                INNER JOIN #dqy_proj B ON r.ProjGUID = B.OldProjGuid;

        PRINT '房间腾挪审核表:md_RoomTengNuoApprove' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --房间使用属性调整方案表
        IF OBJECT_ID(N'md_RoomPropertyAdjust_bak_20250121', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_RoomPropertyAdjust_bak_20250121
            FROM    dbo.md_RoomPropertyAdjust a
                    INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.BUGUID = B.NewBuguid
        FROM    md_RoomPropertyAdjust a
                INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        PRINT '房间使用属性调整方案表:md_RoomPropertyAdjust' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        -- md_ProjectOperLog 
        IF OBJECT_ID(N'md_ProjectOperLog_bak_20250121', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.md_ProjectOperLog_bak_20250121
            FROM    dbo.md_ProjectOperLog a
                    INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = B.NewDevelopmentCompanyGUID
        FROM    md_ProjectOperLog a
                INNER JOIN #dqy_proj B ON a.ProjGUID = B.OldProjGuid;

        PRINT 'md_ProjectOperLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

		--md_ZBPCRemindSet没有数据不处理

        /*--增加组织架构公司跟平台公司的映射关系
        IF OBJECT_ID(N'companyjoin_bak_20250121', N'U') IS NULL
            SELECT  a.* INTO    dbo.companyjoin_bak_20250121 FROM   dbo.CompanyJoin a;

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

        PRINT '组织架构公司跟平台公司的映射关系companyjoin:' + CONVERT(NVARCHAR(20), @@ROWCOUNT);*/

        --删除临时表
        DROP TABLE #dqy_proj;
    END;