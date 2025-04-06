--SELECT  BusinessType,
--        COUNT(1)
--FROM    dbo.myWorkflowProcessEntity
--WHERE   ProcessStatus IN (0, 1)
--        AND BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'
--GROUP BY BusinessType
--ORDER BY COUNT(1) DESC;

--SELECT  *
--FROM    dbo.myWorkflowProcessEntity
--WHERE   ProcessStatus IN (0, 1)
--        AND BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'
--        AND BusinessType = '合同呈批件请款审批';

--合同呈批件请款审批 259
--延期签约审批 101
--供款表调整审批 49
--增减权益人审批 40
--付款期限变更审批 32
--调价方案审批 15
--退房审批 14
--退房面积变更审批 8
--折扣方案审批 7
--挞定后退款审批 6
--佣金申报审批 4
--挞定审批 3
--非合同付款审批 2
--折扣变更审批 2
--合同呈批件审批 1

--定义查询项目范围临时表
--DROP TABLE #proj

--将淮海公司项目和分期插入到临时表中
SELECT  *
INTO    #proj
FROM    (
            SELECT  ProjGUID,
                    ProjName,
                    Level
            FROM    ERP25.dbo.mdm_Project
            WHERE   ProjGUID IN (
                    'C0D7AF14-5399-E911-80B7-0A94EF7517DD',
                    '1CEDF708-5C1D-EA11-80B8-0A94EF7517DD',
                    '511B340B-831D-EA11-80B8-0A94EF7517DD',
                    '730BAE17-3021-EA11-80B8-0A94EF7517DD',
                    'B4958473-344F-EA11-80B8-0A94EF7517DD',
                    'DFE1DD0B-043E-E711-80BA-E61F13C57837',
                    'C93FBCC0-083E-E711-80BA-E61F13C57837',
                    '20F99BDB-DD86-E711-80BA-E61F13C57837',
                    'E79353EE-6991-E711-80BA-E61F13C57837',
                    '491FED63-C8AF-E711-80BA-E61F13C57837',
                    '4BE2EB2E-A9FA-E711-80BA-E61F13C57837',
                    'C50B794A-4149-E811-80BA-E61F13C57837',
                    '8EBEC7B7-4149-E811-80BA-E61F13C57837',
                    'E2B7EB0C-4249-E811-80BA-E61F13C57837',
                    'DFB5066E-4249-E811-80BA-E61F13C57837',
                    '7F9EEA25-F24A-E811-80BA-E61F13C57837',
                    '6EB03C5C-F24A-E811-80BA-E61F13C57837',
                    '2ECA0DD4-2C2B-EB11-B398-F40270D39969',
                    'E95E458C-F339-EB11-B398-F40270D39969',
                    'CAD9E1A3-0A3A-EB11-B398-F40270D39969',
                    'E81DECD4-7F46-EB11-B398-F40270D39969',
                    'A4DBA98F-8E46-EB11-B398-F40270D39969',
                    '07EE07C1-10F4-EB11-B398-F40270D39969',
                    'B41363DA-92FE-EB11-B398-F40270D39969',
                    'EC64E753-FEFE-EB11-B398-F40270D39969',
                    'F58F1AA3-0FFF-EB11-B398-F40270D39969',
                    '9B37F481-81E1-ED11-B3A3-F40270D39969',
                    '4C2CD96B-15EB-EE11-B3A4-F40270D39969')
            UNION
            SELECT  ProjGUID,
                    ProjName,
                    Level
            FROM    ERP25.dbo.mdm_Project
            WHERE   ParentProjGUID IN (
                    'C0D7AF14-5399-E911-80B7-0A94EF7517DD',
                    '1CEDF708-5C1D-EA11-80B8-0A94EF7517DD',
                    '511B340B-831D-EA11-80B8-0A94EF7517DD',
                    '730BAE17-3021-EA11-80B8-0A94EF7517DD',
                    'B4958473-344F-EA11-80B8-0A94EF7517DD',
                    'DFE1DD0B-043E-E711-80BA-E61F13C57837',
                    'C93FBCC0-083E-E711-80BA-E61F13C57837',
                    '20F99BDB-DD86-E711-80BA-E61F13C57837',
                    'E79353EE-6991-E711-80BA-E61F13C57837',
                    '491FED63-C8AF-E711-80BA-E61F13C57837',
                    '4BE2EB2E-A9FA-E711-80BA-E61F13C57837',
                    'C50B794A-4149-E811-80BA-E61F13C57837',
                    '8EBEC7B7-4149-E811-80BA-E61F13C57837',
                    'E2B7EB0C-4249-E811-80BA-E61F13C57837',
                    'DFB5066E-4249-E811-80BA-E61F13C57837',
                    '7F9EEA25-F24A-E811-80BA-E61F13C57837',
                    '6EB03C5C-F24A-E811-80BA-E61F13C57837',
                    '2ECA0DD4-2C2B-EB11-B398-F40270D39969',
                    'E95E458C-F339-EB11-B398-F40270D39969',
                    'CAD9E1A3-0A3A-EB11-B398-F40270D39969',
                    'E81DECD4-7F46-EB11-B398-F40270D39969',
                    'A4DBA98F-8E46-EB11-B398-F40270D39969',
                    '07EE07C1-10F4-EB11-B398-F40270D39969',
                    'B41363DA-92FE-EB11-B398-F40270D39969',
                    'EC64E753-FEFE-EB11-B398-F40270D39969',
                    'F58F1AA3-0FFF-EB11-B398-F40270D39969',
                    '9B37F481-81E1-ED11-B3A3-F40270D39969',
                    '4C2CD96B-15EB-EE11-B3A4-F40270D39969')
        ) t;

--创建临时表
CREATE TABLE #Workflow (
    projname VARCHAR(200),
    ProcessKindName VARCHAR(200),
    BusinessType VARCHAR(200),
    ProcessKindGUID UNIQUEIDENTIFIER,
    ProcessName VARCHAR(2000),
    OwnerName VARCHAR(200),
    InitiateDatetime DATETIME,
    ProcessStatus VARCHAR(200)
);

--ERP25 销售变更审批
INSERT INTO #Workflow
SELECT  p.projname,
        pe2.ProcessKindName,
        BusinessType,
        pe2.ProcessKindGUID,
        pe2.ProcessName,
        pe2.OwnerName,
        pe2.InitiateDatetime,
        pe2.ProcessStatus
FROM    vs_SaleModiApply_WF a --替换对应的业务系统表
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON a.SaleModiApplyGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
WHERE   p.ProjGUID IN (SELECT ProjGUID FROM #proj)
        AND pe2.ProcessStatus IN (0, 1);

--合同审批
SELECT  projname AS 项目名称,
        ProcessKindName AS 流程分类,
        BusinessType AS 业务类型,
        ProcessKindGUID,
        ProcessName AS 流程名称,
        OwnerName AS 责任人,
        InitiateDatetime AS 流程发起时间,
        CASE 
            WHEN ProcessStatus = 0 THEN '审批中'
            WHEN ProcessStatus = 1 THEN '待归档'
        END AS 流程状态
FROM    #Workflow;

----删除临时表
--DROP TABLE #Workflow
--DROP TABLE #proj
