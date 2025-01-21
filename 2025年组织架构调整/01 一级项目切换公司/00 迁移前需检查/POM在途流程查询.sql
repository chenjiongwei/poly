--SELECT   BusinessType,COUNT(1) FROM  dbo.myWorkflowProcessEntity WHERE ProcessStatus IN (0,1)
--AND  BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836'
--GROUP BY BusinessType
--ORDER BY COUNT(1) DESc 

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

SELECT  *
INTO    #proj
FROM(SELECT ProjGUID ,
            ProjName ,
            Level
     FROM   ERP25.dbo.mdm_Project
     WHERE  ProjGUID IN ('B8FA868C-7A36-E911-80B7-0A94EF7517DD', '9410E473-9AF4-E911-80B8-0A94EF7517DD', 'FE0372DE-F00F-E911-80BF-E61F13C57837', '5E2053F6-F00F-E911-80BF-E61F13C57837' ,
                         '96593E08-F10F-E911-80BF-E61F13C57837' , 'B3602B20-F10F-E911-80BF-E61F13C57837', '59056B73-FD65-EB11-B398-F40270D39969', '11D560DD-097C-EB11-B398-F40270D39969' ,
                         'A169EA26-C70A-EC11-B398-F40270D39969' , '64D4173E-F10F-E911-80BF-E61F13C57837', '07DE0456-F10F-E911-80BF-E61F13C57837', '154BDB79-F10F-E911-80BF-E61F13C57837' ,
                         '49D1D48B-F10F-E911-80BF-E61F13C57837' , '7E13BDA3-F10F-E911-80BF-E61F13C57837', '2481A886-E71E-E911-80BF-E61F13C57837')
     UNION
     SELECT ProjGUID ,
            ProjName ,
            Level
     FROM   ERP25.dbo.mdm_Project
     WHERE  ParentProjGUID IN ('B8FA868C-7A36-E911-80B7-0A94EF7517DD', '9410E473-9AF4-E911-80B8-0A94EF7517DD', 'FE0372DE-F00F-E911-80BF-E61F13C57837', '5E2053F6-F00F-E911-80BF-E61F13C57837' ,
                               '96593E08-F10F-E911-80BF-E61F13C57837' , 'B3602B20-F10F-E911-80BF-E61F13C57837', '59056B73-FD65-EB11-B398-F40270D39969', '11D560DD-097C-EB11-B398-F40270D39969' ,
                               'A169EA26-C70A-EC11-B398-F40270D39969' , '64D4173E-F10F-E911-80BF-E61F13C57837', '07DE0456-F10F-E911-80BF-E61F13C57837', '154BDB79-F10F-E911-80BF-E61F13C57837' ,
                               '49D1D48B-F10F-E911-80BF-E61F13C57837' , '7E13BDA3-F10F-E911-80BF-E61F13C57837', '2481A886-E71E-E911-80BF-E61F13C57837')) t;

--创建临时表
CREATE TABLE #Workflow (projname VARCHAR(200) ,
                        ProcessKindName VARCHAR(200) ,
                        BusinessType VARCHAR(200) ,
                        ProcessKindGUID UNIQUEIDENTIFIER ,
                        ProcessName VARCHAR(2000) ,
                        OwnerName VARCHAR(200) ,
                        InitiateDatetime DATETIME ,
                        ProcessStatus VARCHAR(200));

--ERP352
--合同变更审批
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    vcb_HtAlter cb --替换对应的业务系统表
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTAlterGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjCode = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--合同审批
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.vcb_Contract cb --替换对应的业务系统表
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.ContractGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--付款申请审批
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.vcb_HTFKApply cb --替换对应的业务系统表
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTFKApplyGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--设计变更审批
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.vcb_DesignAlter cb --替换对应的业务系统表
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.DesignAlterGuid = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjCodeList = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--合同结算审批
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.vcb_HTBalance cb
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTBalanceGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

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
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.cb_Contract_Pre cb
        INNER JOIN dbo.cb_ContractProj d ON cb.PreContractGUID = d.ContractGUID
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.PreContractGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON d.ProjGUID = p.ProjGUID
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--费用非单独执行合同审批 ok 
--采购方案审批
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.cg_CgSolution cb
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.CgSolutionGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjCodeList = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

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
SELECT  projname AS 项目名称 ,
        ProcessKindName AS 流程分类 ,
        BusinessType AS 业务类型 ,
        ProcessKindGUID ,
        ProcessName AS 流程名称 ,
        OwnerName AS 责任人 ,
        InitiateDatetime AS 流程发起时间 ,
        CASE WHEN ProcessStatus = 0 THEN '审批中' WHEN ProcessStatus = 1 THEN '待归档' END AS 流程状态
FROM    #Workflow;
