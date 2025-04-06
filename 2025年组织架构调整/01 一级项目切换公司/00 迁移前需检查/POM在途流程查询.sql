--SELECT BusinessType, COUNT(1) 
--FROM dbo.myWorkflowProcessEntity 
--WHERE ProcessStatus IN (0,1)
--AND BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'
--GROUP BY BusinessType
--ORDER BY COUNT(1) DESC

--合同变更审批
--合同审批  
--付款申请审批
--设计变更审批
--合同结算审批
--费用付款申请审批
--完工确认审批
--楼栋计划工作汇报审批
--费用非合同审批
--费用合同审批
--部门费用年度预算审批
--非合同审批
--非单独执行合同审批
--合同预呈批审批
--费用非单独执行合同审批
--采购方案审批
--标书文档审批
--里程碑计划审批
--费用申请单审批
--定标结果审批
--楼栋计划批量审批
--费用合同结算审批
--修改结算金额审批
--战略协议审批
--部门计划工作汇报审批
--部门费用月度计划审批
--采购计划审批
--目标成本审批
--修改为非现金支付审批

--定义查询项目范围临时表
--DROP TABLE #proj

SELECT *
INTO #proj
FROM (
    SELECT ProjGUID,
           ProjName,
           Level
    FROM ERP25.dbo.mdm_Project
    WHERE ProjGUID IN (
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
        '4C2CD96B-15EB-EE11-B3A4-F40270D39969'
    )
    UNION
    SELECT ProjGUID,
           ProjName,
           Level
    FROM ERP25.dbo.mdm_Project
    WHERE ParentProjGUID IN (
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
        '4C2CD96B-15EB-EE11-B3A4-F40270D39969'
    )
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

--ERP352
--合同变更审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM vcb_HtAlter cb --替换对应的业务系统表
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTAlterGUID = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON cb.ProjCode = p.ProjCode
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--合同审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM dbo.vcb_Contract cb --替换对应的业务系统表
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.ContractGUID = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--付款申请审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM dbo.vcb_HTFKApply cb --替换对应的业务系统表
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTFKApplyGUID = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--设计变更审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM dbo.vcb_DesignAlter cb --替换对应的业务系统表
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.DesignAlterGuid = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON cb.ProjCodeList = p.ProjCode
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--合同结算审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM dbo.vcb_HTBalance cb
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTBalanceGUID = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--费用付款申请审批 OK 
--完工确认审批 OK 
--楼栋计划工作汇报审批？？

--费用非合同审批 OK 
--费用合同审批 OK 
--部门费用年度预算审批 
--非合同审批 OK 
--非单独执行合同审批 OK 
--合同预呈批审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM dbo.cb_Contract_Pre cb
INNER JOIN dbo.cb_ContractProj d ON cb.PreContractGUID = d.ContractGUID
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.PreContractGUID = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON d.ProjGUID = p.ProjGUID
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--费用非单独执行合同审批 ok 
--采购方案审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM dbo.cg_CgSolution cb
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.CgSolutionGUID = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON cb.ProjCodeList = p.ProjCode
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--标书文档审批
--里程碑计划审批
--费用申请单审批
--定标结果审批
--楼栋计划批量审批
--费用合同结算审批
--修改结算金额审批
--战略协议审批
--部门计划工作汇报审批
--部门费用月度计划审批
--采购计划审批
--目标成本审批
--修改为非现金支付审批
SELECT projname AS 项目名称,
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
FROM #Workflow;
