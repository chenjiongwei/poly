---进度系统修复脚本
/*
--无数据
jd_DeptExamine  
jd_DeptExaminePhotoFormula 
jd_DeptExaminePhotoSystem 
jd_ExaminPhotographRecord 
jd_Examine 
jd_ExecutivesAssigned 
jd_GCBuilding 
jd_GCSubarea 
jd_Holiday 
jd_Monthly_Deptwork 
jd_PlanOffset  
jd_SpecialDay 
jd_SpecialDayExecute  
jd_StandardStation2User 
jd_WorkPlan_Log 
jd_Work 
jd_work_Editing 
jd_PhotoTask

--考核相关的没用上，不需要做迁移
jd_DeptExamineAddSubScoreSetting
jd_DeptExamineFormula
jd_DeptExaminePeriod
jd_DeptExamineSystem
jd_DeptExaminStandardSetting
jd_ExaminPeriodSet
jd_ExaminSet
jd_ExaminStandardSetting

--仅是公司层级的配置，不做迁移
jd_TaskWarningConfig
jd_WorkTaskDelayWarningSet

--湾区跟华南公司没有数据的表，不做迁移
jd_NotProjectSpecialPlanCompile
jd_NotProjectSpecialPlanExecute  
jd_TaskWarningInProgressConfig

--已考虑迁移
jd_ProjectPlanTemplate
jd_ProjectPlanTemplateTask
jd_PlanTaskExecuteObjectForReport
jd_ProjectKeyNodePlanCompile 
jd_ProjectKeyNodePlanExecute 
jd_ProjectPlanCompile 
jd_ProjectPlanExecute  
jd_ProjectPlanExecutePhoto
jd_WorkDay
jd_WorkDayExecute 
jd_PlanTaskExecuteObjectForReportTemp

--待补充脚本
jd_ProjectSpecialPlanCompile
jd_ProjectSpecialPlanExecute 
jd_ProjectSpecialPlanTemplate
*/



USE MyCost_Erp352
GO
/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏
*/

BEGIN
    --缓存pom项目
    SELECT  a.* ,
            b.NewBuguid ,
            b.NewBuname ,
            b.OldBuguid ,
            b.OldBuname ,
            b.OldProjGuid
    INTO    #p
    FROM    dbo.p_HkbProjectWork a
            INNER JOIN dqy_proj_20250121 b ON a.ProjGUID = b.OldProjGuid;

    DECLARE @qytype INT;

    SET @qytype = 1;

       /* 
        迁移类型 qytype：
        0 : 代表着不需要在迁移后公司中新增模板,直接将原有公司模板全部迁移在新公司
        1 :代表着需要在迁移后公司中新增原有公司模板且保持原有模板不变
	*/
    IF(@qytype = 1)
        BEGIN
            --1、计划模板复制一份到新公司
            --缓存一份原公司的计划模板
            SELECT  DISTINCT a.ID oldId ,
                             -- NEWID() AS id ,
                             a.ParentID ,
                             REPLACE(a.Name, t.OldBuname, t.NewBuname) AS Name ,
                             a.Code ,
                             a.IfEnd ,
                             a.CreatorID ,
                             a.CreateDate ,
                             a.Instructions ,
                             a.Remarks ,
                             a.PublishState ,
                             a.KeyNodeTemplateID ,
                             a.PlanType ,
                             t.NewBuguid AS BUGUID ,
                             a.PlanModuleTypeGUID ,
                             a.PlanModuleTypeName
            INTO    #tempPlan
            FROM    jd_ProjectPlanTemplate a
                    INNER JOIN jd_ProjectPlanExecute ex ON ex.TemplatePlanID = a.id
                    INNER JOIN #p t ON t.OldProjGuid = ex.ProjGUID
            -- INNER JOIN(SELECT   DISTINCT OldBuguid, OldBuname, NewBuname, NewBuguid FROM    #p) b ON b.OldBuguid = a.BUGUID;
            WHERE   t.NewBuguid <> a.Buguid;

	    -- 根据需要插入的新公司生成新计划模版的临时表
	    SELECT  NEWID() AS id ,
		    oldId,
                    ParentID ,
                    Name ,
                    Code ,
                    IfEnd ,
                    CreatorID ,
                    CreateDate ,
                    Instructions ,
                    Remarks ,
                    PublishState ,
                    KeyNodeTemplateID ,
                    PlanType ,
                    BUGUID ,
                    PlanModuleTypeGUID ,
                    PlanModuleTypeName 
		    INTO   #temp
		   FROM   #tempPlan
           
	PRINT 'jd_ProjectPlanTemplate';
	IF OBJECT_ID(N'jd_ProjectPlanTemplate_bak_20250406', N'U') IS NULL
                SELECT  a.*
                INTO    dbo.jd_ProjectPlanTemplate_bak_20250406
                FROM    dbo.jd_ProjectPlanTemplate a;

            --复制一份模板到新公司
            INSERT INTO dbo.jd_ProjectPlanTemplate(ID, ParentID, Name, Code, IfEnd, CreatorID, CreateDate, Instructions, Remarks, PublishState, KeyNodeTemplateID, PlanType, BUGUID ,
                                                   PlanModuleTypeGUID , PlanModuleTypeName)
            SELECT  id ,
                    ParentID ,
                    Name ,
                    Code ,
                    IfEnd ,
                    CreatorID ,
                    CreateDate ,
                    Instructions ,
                    Remarks ,
                    PublishState ,
                    KeyNodeTemplateID ,
                    PlanType ,
                    BUGUID ,
                    PlanModuleTypeGUID ,
                    PlanModuleTypeName
            FROM    #temp;

            PRINT '复制模版到新公司jd_ProjectPlanTemplate：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

            ----先刷关联了计划模板的模板ID
            PRINT 'jd_ProjectPlanTemplateTask';

            IF OBJECT_ID(N'jd_ProjectPlanTemplateTask_bak_20250406', N'U') IS NULL
                SELECT  a.*
                INTO    dbo.jd_ProjectPlanTemplateTask_bak_20250406
                FROM    dbo.jd_ProjectPlanTemplateTask a
                        INNER JOIN #temp b ON a.ProjectPlanTemplateID = b.oldId;

            INSERT INTO jd_ProjectPlanTemplateTask(ID, RowNumber, ProjectPlanTemplateID, TaskName, TaskType, Code, LevelCode, ParentCode, Level, IsEnd, PredecessorLinkMemo, KeyNodeID ,
                                                   ProjectAchievementTypeID , Duration, WBSCode, Remarks, IsError, ErrorInfo, ShowTaskType, ShowTaskTypeID, AssessmentStar, ErrorPosition, EditType ,
                                                   NodeType , NodeRemark, IsFromTemplate, StandardDeptID, StandardDept, MustUpload, MustUploadType)
            SELECT  NEWID() ,
                    a.RowNumber ,
                    b.id ,
                    a.TaskName ,
                    a.TaskType ,
                    a.Code ,
                    a.LevelCode ,
                    a.ParentCode ,
                    a.Level ,
                    a.IsEnd ,
                    a.PredecessorLinkMemo ,
                    a.KeyNodeID ,
                    a.ProjectAchievementTypeID ,
                    a.Duration ,
                    a.WBSCode ,
                    a.Remarks ,
                    a.IsError ,
                    a.ErrorInfo ,
                    a.ShowTaskType ,
                    a.ShowTaskTypeID ,
                    a.AssessmentStar ,
                    a.ErrorPosition ,
                    a.EditType ,
                    a.NodeType ,
                    a.NodeRemark ,
                    a.IsFromTemplate ,
                    a.StandardDeptID ,
                    a.StandardDept ,
                    a.MustUpload ,
                    a.MustUploadType
            FROM    dbo.jd_ProjectPlanTemplateTask a
                    INNER JOIN #temp b ON a.ProjectPlanTemplateID = b.oldId;

            PRINT '插入jd_ProjectPlanTemplateTask表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
            PRINT 'jd_ProjectPlanExecute';

            IF OBJECT_ID(N'jd_ProjectPlanExecute_bak_20250406', N'U') IS NULL
                SELECT  a.*
                INTO    dbo.jd_ProjectPlanExecute_bak_20250406
                FROM    dbo.jd_ProjectPlanExecute a
                        INNER JOIN #temp b ON a.TemplatePlanID = b.oldId
                        INNER JOIN #p p ON p.ProjGUID = a.ProjGUID
                WHERE   a.TemplatePlanID <> b.id;

            UPDATE  a
            SET a.TemplatePlanID = b.id
            FROM    dbo.jd_ProjectPlanExecute a
                    INNER JOIN #temp b ON a.TemplatePlanID = b.oldId
                    INNER JOIN #p p ON p.ProjGUID = a.ProjGUID
            WHERE   a.TemplatePlanID <> b.id;

            PRINT '修改jd_ProjectPlanExecute表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
            PRINT 'jd_ProjectPlanCompile';

            IF OBJECT_ID(N'jd_ProjectPlanCompile_bak_20250406', N'U') IS NULL
                SELECT  a.*
                INTO    dbo.jd_ProjectPlanCompile_bak_20250406
                FROM    dbo.jd_ProjectPlanCompile a
                        INNER JOIN #temp b ON a.TemplatePlanID = b.oldId
                        INNER JOIN #p p ON p.ProjGUID = a.ProjGUID
                WHERE   a.TemplatePlanID <> b.id;

            UPDATE  a
            SET a.TemplatePlanID = b.id
            FROM    dbo.jd_ProjectPlanCompile a
                    INNER JOIN #temp b ON a.TemplatePlanID = b.oldId
                    INNER JOIN #p p ON p.ProjGUID = a.ProjGUID
            WHERE   a.TemplatePlanID <> b.id;

            PRINT '修改jd_ProjectPlanCompile' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


        --2、设置的数据复制一份
        /* PRINT 'jd_PlanOffset';

            IF OBJECT_ID(N'jd_PlanOffset_bak_20250121', N'U') IS NULL
                SELECT  a.* INTO    dbo.jd_PlanOffset_bak_20250121 FROM dbo.jd_PlanOffset a;

            INSERT INTO jd_PlanOffset
            SELECT  NEWID() ,
                    b.NewBuguid BUGUID ,
                    a.ParamName ,
                    a.IsEnable ,
                    a.OffsetDay ,
                    a.TipRule ,
                    a.CreaterGUID ,
                    a.CreaterName ,
                    a.CreateDate
            FROM    jd_PlanOffset a
                    INNER JOIN #p b ON b.OldBuguid = a.BUGUID;
           
            PRINT 'jd_DeptExaminePeriod[部门考核周期表]';

            IF OBJECT_ID(N'jd_DeptExaminePeriod_bak_20250121', N'U') IS NULL
                SELECT  a.*
                INTO    dbo.jd_DeptExaminePeriod_bak_20250121
                FROM    jd_DeptExaminePeriod a
                        INNER JOIN #p b ON b.OldBuguid = a.BUGUID;

            INSERT INTO jd_DeptExaminePeriod
            SELECT  NEWID() ,
                    b.NewBuguid BUGUID ,
                    a.Day ,
                    a.ExamineType ,
                    a.Enable
            FROM    jd_DeptExaminePeriod a
                    INNER JOIN #p b ON b.OldBuguid = a.BUGUID;
             */
        END;
    ELSE
        BEGIN
            PRINT 'jd_ProjectPlanTemplate';

            IF OBJECT_ID(N'jd_ProjectPlanTemplate_bak_20250406', N'U') IS NULL
                SELECT  a.*
                INTO    dbo.jd_ProjectPlanTemplate_bak_20250406
                FROM    jd_ProjectPlanTemplate a
                        INNER JOIN #p b ON b.OldBuguid = a.BUGUID
                WHERE   a.BUGUID <> b.BUGUID;

            UPDATE  a
            SET a.BUGUID = b.BUGUID
            FROM    jd_ProjectPlanTemplate a
                    INNER JOIN #p b ON b.OldBuguid = a.BUGUID
            WHERE   a.BUGUID <> b.BUGUID;
        END;

    --里程碑数据转移 
    PRINT 'jd_ProjectPlanCompile';

    IF OBJECT_ID(N'jd_ProjectPlanCompile_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectPlanCompile_bak_20250406
        FROM    jd_ProjectPlanCompile a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectPlanCompile a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    --计划历史表 
    PRINT 'jd_ProjectPlanExecuteHistory';

    IF OBJECT_ID(N'jd_ProjectPlanExecuteHistory_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectPlanExecuteHistory_bak_20250406
        FROM    jd_ProjectPlanExecuteHistory a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectPlanExecuteHistory a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT 'jd_ProjectPlanExecute_del';

    IF OBJECT_ID(N'jd_ProjectPlanExecute_del_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectPlanExecute_del_bak_20250406
        FROM    jd_ProjectPlanExecute_del a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectPlanExecute_del a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT 'jd_ProjectPlanExecutePhoto';

    IF OBJECT_ID(N'jd_ProjectPlanExecutePhoto_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectPlanExecutePhoto_bak_20250406
        FROM    jd_ProjectPlanExecutePhoto a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectPlanExecutePhoto a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT 'jd_WorkDay';

    IF OBJECT_ID(N'jd_WorkDay_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_WorkDay_bak_20250406
        FROM    jd_WorkDay a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_WorkDay a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT 'jd_ProjectPlanExecute';

    IF OBJECT_ID(N'jd_ProjectPlanExecute_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectPlanExecute_bak_20250406
        FROM    jd_ProjectPlanExecute a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectPlanExecute a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '计划工作日执行表jd_WorkDayExecute';

    IF OBJECT_ID(N'jd_WorkDayExecute_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_WorkDayExecute_bak_20250406
        FROM    jd_WorkDayExecute a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_WorkDayExecute a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '计划汇报临时表jd_PlanTaskExecuteObjectForReportTemp';

    IF OBJECT_ID(N'jd_PlanTaskExecuteObjectForReportTemp_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_PlanTaskExecuteObjectForReportTemp_bak_20250406
        FROM    jd_PlanTaskExecuteObjectForReportTemp a
                INNER JOIN #p b ON b.ProjGUID = a.projguid
        WHERE   a.buguid <> b.BUGUID;

    UPDATE  a
    SET a.buguid = b.BUGUID
    FROM    jd_PlanTaskExecuteObjectForReportTemp a
            INNER JOIN #p b ON b.ProjGUID = a.projguid
    WHERE   a.buguid <> b.BUGUID;

    PRINT '里程碑节点计划执行历史表jd_ProjectKeyNodePlanExecuteHistory';

    IF OBJECT_ID(N'jd_ProjectKeyNodePlanExecuteHistory_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectKeyNodePlanExecuteHistory_bak_20250406
        FROM    jd_ProjectKeyNodePlanExecuteHistory a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectKeyNodePlanExecuteHistory a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '节点计划执行历史表jd_WorkDayExecuteHistory';

    IF OBJECT_ID(N'jd_WorkDayExecuteHistory_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_WorkDayExecuteHistory_bak_20250406
        FROM    jd_WorkDayExecuteHistory a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_WorkDayExecuteHistory a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '里程碑节点执行表删除表jd_ProjectKeyNodePlanExecute_del';

    IF OBJECT_ID(N'jd_ProjectKeyNodePlanExecute_del_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectKeyNodePlanExecute_del_bak_20250406
        FROM    jd_ProjectKeyNodePlanExecute_del a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectKeyNodePlanExecute_del a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '计划执行汇报表jd_PlanTaskExecuteObjectForReport';

    IF OBJECT_ID(N'jd_PlanTaskExecuteObjectForReport_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_PlanTaskExecuteObjectForReport_bak_20250406
        FROM    jd_PlanTaskExecuteObjectForReport a
                INNER JOIN #p b ON b.ProjGUID = a.projguid
        WHERE   a.buguid <> b.BUGUID;

    UPDATE  a
    SET a.buguid = b.BUGUID
    FROM    jd_PlanTaskExecuteObjectForReport a
            INNER JOIN #p b ON b.ProjGUID = a.projguid
    WHERE   a.buguid <> b.BUGUID;

    PRINT '里程碑节点执行表jd_ProjectKeyNodePlanExecute';

    IF OBJECT_ID(N'jd_ProjectKeyNodePlanExecute_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectKeyNodePlanExecute_bak_20250406
        FROM    jd_ProjectKeyNodePlanExecute a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectKeyNodePlanExecute a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    PRINT '里程碑节点编制表jd_ProjectKeyNodePlanCompile';

    IF OBJECT_ID(N'jd_ProjectKeyNodePlanCompile_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectKeyNodePlanCompile_bak_20250406
        FROM    jd_ProjectKeyNodePlanCompile a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectKeyNodePlanCompile a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;
 
    PRINT '组团待办接收人设置表 jd_GroupTaskReceiverSet';

    IF OBJECT_ID(N'jd_GroupTaskReceiverSet_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_GroupTaskReceiverSet_bak_20250406
        FROM    jd_GroupTaskReceiverSet a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_GroupTaskReceiverSet a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;
    
    PRINT 'jd_ProjectKeyNodePlanCompile_PreData';

    IF OBJECT_ID(N'jd_ProjectKeyNodePlanCompile_PreData_bak_20250406', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.jd_ProjectKeyNodePlanCompile_PreData_bak_20250406
        FROM    jd_ProjectKeyNodePlanCompile_PreData a
                INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
        WHERE   a.BUGUID <> b.BUGUID;

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    jd_ProjectKeyNodePlanCompile_PreData a
            INNER JOIN #p b ON b.ProjGUID = a.ProjGUID
    WHERE   a.BUGUID <> b.BUGUID;

    --删除临时表
    DROP TABLE #p,#tempPlan
END;
