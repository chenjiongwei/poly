USE ERP25
GO
/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏

*/

/*--业务参数设置-问题关闭原因
SELECT  *
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_ProblemCloseResoon' AND  ScopeGUID IN( SELECT BUGUID
                                                             FROM   dbo.myBusinessUnit
                                                             WHERE  BUName = '无锡公司' AND IsEndCompany = 1 );

--将江苏公司的问题关闭原因业务参数复制到无锡公司
INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID, AreaInfo ,
                                 IsLandCbDk , ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf)
SELECT  ParamName ,
        (SELECT BUGUID
         FROM   dbo.myBusinessUnit
         WHERE  BUName = '无锡公司' AND IsEndCompany = 1) AS ScopeGUID ,
        ParamValue ,
        ParamCode ,
        ParentCode ,
        ParamLevel ,
        IfEnd ,
        IfSys ,
        NEWID() AS ParamGUID ,
        IsAjSk ,
        IsQykxdc ,
        TaxItemsDetailCode ,
        IsCalcTax ,
        CompanyGUID ,
        AreaInfo ,
        IsLandCbDk ,
        ReceiveTypeValue ,
        NEWID() AS myBizParamOptionGUID ,
        IsYxfjxzf
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_ProblemCloseResoon' AND  ScopeGUID IN(SELECT BUGUID
                                                             FROM   dbo.myBusinessUnit
                                                             WHERE  BUName = '江苏公司' AND IsEndCompany = 1);

--业务参数设置-问题处理部位
SELECT  *
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_place' AND   ScopeGUID IN(SELECT BUGUID
                                                 FROM   dbo.myBusinessUnit
                                                 WHERE  BUName = '无锡公司' AND IsEndCompany = 1);

--备份
SELECT  * INTO  myBizParamOption_bak20250424 FROM dbo.myBizParamOption;

--删除无锡公司问题处理部位参数
DELETE  FROM dbo.myBizParamOption
--SELECT * FROM myBizParamOption
WHERE   ParamName = 'k_place' AND   ScopeGUID IN(SELECT BUGUID
                                                 FROM   dbo.myBusinessUnit
                                                 WHERE  BUName = '无锡公司' AND IsEndCompany = 1);

--插入问题处理参数
INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID, AreaInfo ,
                                 IsLandCbDk , ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf)
SELECT  ParamName ,
        (SELECT BUGUID
         FROM   dbo.myBusinessUnit
         WHERE  BUName = '无锡公司' AND IsEndCompany = 1) AS ScopeGUID ,
        ParamValue ,
        ParamCode ,
        ParentCode ,
        ParamLevel ,
        IfEnd ,
        IfSys ,
        NEWID() AS ParamGUID ,
        IsAjSk ,
        IsQykxdc ,
        TaxItemsDetailCode ,
        IsCalcTax ,
        CompanyGUID ,
        AreaInfo ,
        IsLandCbDk ,
        ReceiveTypeValue ,
        NEWID() AS myBizParamOptionGUID ,
        IsYxfjxzf
FROM    dbo.myBizParamOption
WHERE   ParamName = 'k_place' AND   ScopeGUID IN(SELECT BUGUID
                                                 FROM   dbo.myBusinessUnit
                                                 WHERE  BUName = '江苏公司' AND IsEndCompany = 1);
*/
BEGIN
    --插入临时表
    SELECT *
    INTO #dqy_proj
    FROM dqy_proj_20250424 t;

    -- --受理单位表
    PRINT '受理单位表k_AcceptBU';

    IF OBJECT_ID(N'k_AcceptBU_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_AcceptBU_bak20250424
        FROM k_AcceptBU a
            INNER JOIN k_Receive b
                ON a.ReceiveGUID = b.ReceiveGUID
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = b.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_AcceptBU a
        INNER JOIN k_Receive b
            ON a.ReceiveGUID = b.ReceiveGUID
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = b.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '受理单位表k_AcceptBU' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ----任务实体
    PRINT '任务实体k_Task';

    IF OBJECT_ID(N'k_Task_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_Task_bak20250424
        FROM k_Task a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Task a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '任务实体k_Task' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ----受理表
    PRINT '受理表k_Receive';

    IF OBJECT_ID(N'k_Receive_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_Receive_bak20250424
        FROM k_Receive a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Receive a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '受理表k_Receive' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --投诉专题表k_Complaint --没有数据
    IF OBJECT_ID(N'k_Complaint_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_Complaint_bak20250424
        FROM k_Complaint a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Complaint a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '投诉专题表k_Complaint' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --赔付记录实体k_Pay --没有数据
    IF OBJECT_ID(N'k_Pay_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_Pay_bak20250424
        FROM k_Pay a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Pay a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '赔付记录实体k_Pay' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- /////////////////////////////// 2025年组织架构调整新增处理表 开始 /////////////////////////////////////////////
    IF OBJECT_ID(N'k_CooperativeProjectDelivery_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_CooperativeProjectDelivery_bak20250424
        FROM k_CooperativeProjectDelivery a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_CooperativeProjectDelivery a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '正式交付记录主表 k_CooperativeProjectDelivery' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'k_GreatComplaint_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_GreatComplaint_bak20250424
        FROM k_GreatComplaint a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_GreatComplaint a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '重大投诉表 k_GreatComplaint' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'k_HZXMJFLR_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_HZXMJFLR_bak20250424
        FROM k_HZXMJFLR a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_HZXMJFLR a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT '合作项目交付录入表 k_HZXMJFLR' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


    IF OBJECT_ID(N'k_Receivedellog_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_Receivedellog_bak20250424
        FROM k_Receivedellog a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_Receivedellog a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT 'k_Receivedellog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'k_taskdellog_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO k_taskdellog_bak20250424
        FROM k_taskdellog a
            INNER JOIN #dqy_proj p
                ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM k_taskdellog a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT 'k_taskdellog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        -- 年交付计划表
    IF OBJECT_ID(N's_YearJLPlan_bak20250424', N'U') IS NULL
        SELECT a.*
        INTO s_YearJLPlan_bak20250424
        FROM s_YearJLPlan a
            INNER JOIN #dqy_proj p ON p.OldProjGuid = a.ProjGUID
        WHERE a.BUGUID <> p.NewBuguid;

    UPDATE a
    SET a.BUGUID = p.NewBuguid
    FROM s_YearJLPlan a
        INNER JOIN #dqy_proj p
            ON p.OldProjGuid = a.ProjGUID
    WHERE a.BUGUID <> p.NewBuguid;

    PRINT 's_YearJLPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    -- /////////////////////////////// 2025年组织架构调整新增处理表 结束 /////////////////////////////////////////////

----接待记录表OK 销售系统迁移脚本中已经处理
--SELECT a.BUGUID ,
--       *
--FROM   k_Receive a
--       INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
--       INNER JOIN dbo.myBusinessUnit bu ON bu.BUGUID = p.BUGUID
--WHERE  bu.BUName = '无锡公司'
--       AND bu.IsEndCompany = 1
--       AND a.BUGUID <> bu.BUGUID;

--k_TaskAutoUpdateSetting
--涉及存储过程：usp_TaskAutoUpdate
--涉及的业务场景：客服任务自动升级，会根据k_TASK的BUGUID关联本表的BUGUID来进行插入升级短信或邮件信息
--SELECT  *
--FROM    k_TaskAutoUpdateSetting
--WHERE   BUGUID IN(SELECT    BUGUID
--                  FROM  dbo.myBusinessUnit
--                  WHERE BUName = '江苏公司' AND IsEndCompany = 1);

--INSERT INTO dbo.k_TaskAutoUpdateSetting(SettingGUID, BUGUID, TaskLevelName, TimeoutThanDay, TimeoutLessDay, ReBuildThanDay, ReBuildLessDay)
--SELECT  NEWID() AS SettingGUID ,
--        (SELECT BUGUID
--         FROM   dbo.myBusinessUnit
--         WHERE  BUName = '无锡公司' AND IsEndCompany = 1) AS BUGUID ,
--        TaskLevelName ,
--        TimeoutThanDay ,
--        TimeoutLessDay ,
--        ReBuildThanDay ,
--        ReBuildLessDay
--FROM    k_TaskAutoUpdateSetting
--WHERE   BUGUID IN(SELECT    BUGUID
--                  FROM  dbo.myBusinessUnit
--                  WHERE BUName = '江苏公司' AND IsEndCompany = 1);

----升级提醒人设置表
--SELECT  *
--FROM    k_TaskWarnManSetting a
--        INNER JOIN dbo.mdm_Project p ON a.ProjGUID = p.ProjGUID
--WHERE   p.DevelopmentCompanyGUID IN(SELECT  DevelopmentCompanyGUID
--                                    FROM    dbo.p_DevelopmentCompany
--                                    WHERE   DevelopmentCompanyName = '无锡公司');

--UPDATE  a
--SET a.BUGUID = (SELECT  BUGUID
--                FROM    dbo.myBusinessUnit
--                WHERE   BUName = '无锡公司' AND IsEndCompany = 1)
--FROM    k_TaskWarnManSetting a
--        INNER JOIN dbo.mdm_Project p ON a.ProjGUID = p.ProjGUID
--WHERE   p.DevelopmentCompanyGUID IN(SELECT  DevelopmentCompanyGUID
--                                    FROM    dbo.p_DevelopmentCompany
--                                    WHERE   DevelopmentCompanyName = '无锡公司');

----任务岗位权限表 --不用处理
--SELECT * FROM k_Station2Action
----验房/交付总结表 --不用处理
--SELECT * FROM k_SumUp

----自动升级标准设置表 --不用处理
--SELECT * FROM  k_TaskAutoUpdateSetting
----任务类型与派工单模板对照表  --不用处理
--SELECT * FROM  dbo.k_TaskType2WorkTemplet
----升级提醒人设置表  --不用处理
--SELECT * FROM  k_TaskWarnManSetting       
END;