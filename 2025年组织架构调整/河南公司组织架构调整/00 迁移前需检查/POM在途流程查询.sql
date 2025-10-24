--SELECT BusinessType, COUNT(1) 
--FROM dbo.myWorkflowProcessEntity 
--WHERE ProcessStatus IN (0,1)
--AND BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'
--GROUP BY BusinessType
--ORDER BY COUNT(1) DESC

-- 费用非单独执行合同审批 OK
-- 终止动态成本月度回顾 OK
-- 合同预呈批审批 OK
-- 合同变更审批 OK
-- 付款申请审批 OK
-- 合同结算审批 OK
-- 动态成本月度回顾审批 OK
-- 合同审批 OK
-- 费用申请单审批 OK
-- 完工确认审批 OK
-- 部门计划工作汇报审批 OK
-- 部门费用月度计划审批
-- 费用合同结算审批
-- 非单独执行合同审批
-- 费用付款申请审批
-- 费用非合同审批
-- 设计变更审批
-- 楼栋计划工作汇报审批
-- 项目年度预算客服类审批
-- 非合同审批
-- 费用合同审批
-- 修改结算金额审批
-- 采购方案审批

--定义查询项目范围临时表
--DROP TABLE #proj

declare @buguid uniqueidentifier
set @buguid = '289A694A-E5D1-4F02-BFEF-8510E4B6C6A0' -- 齐鲁公司

SELECT *
INTO #proj
FROM (
    SELECT ProjGUID,
           ProjName,
           Level
    FROM ERP25.dbo.mdm_Project
    INNER JOIN ERP25.dbo.p_DevelopmentCompany dc ON mdm_Project.DevelopmentCompanyGUID = dc.DevelopmentCompanyGUID
    WHERE   dc.DevelopmentCompanyName = '齐鲁公司'
) t;

--创建临时表
CREATE TABLE #Workflow (
    projname VARCHAR(200),
	ProcessGUID UNIQUEIDENTIFIER,
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
       pe2.ProcessGUID,
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
       pe2.ProcessGUID,
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
       pe2.ProcessGUID,
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
       pe2.ProcessGUID,
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
       pe2.ProcessGUID,
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

-- 终止动态成本月度回顾
INSERT INTO #Workflow
SELECT cb.ProjectName,
       pe2.ProcessGUID,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM dbo.Cb_Dtjk_Ydhgzz  cb
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.ydhgzzguid  = pe2.BusinessGUID
WHERE cb.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--费用付款申请审批 OK 
--完工确认审批 OK 
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessGUID,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM vcb_HtAlter cb
INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.QrProcessGuid = pe2.BusinessGUID
INNER JOIN dbo.p_Project p ON cb.ProjCode = p.ProjCode
WHERE p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);

--楼栋计划工作汇报审批？？

--费用非合同审批 OK 
--费用合同审批 OK 
--部门费用年度预算审批 
--非合同审批 OK 
--非单独执行合同审批 OK 
--合同预呈批审批
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessGUID,
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
--采购方案审批 OK 
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessGUID,
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
--费用申请单审批 OK
INSERT INTO #Workflow
SELECT p.projname,
       pe2.ProcessGUID,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM  vfy_Apply  cb
  INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.ApplyGUID = pe2.BusinessGUID  
  left join dbo.p_Project p on charindex(p.ProjCode,cb.ProjectCodeList) > 0
WHERE cb.buguid = @buguid -- p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);


-- 楼栋计划工作汇报审批 OK
INSERT INTO #Workflow
SELECT distinct
       e.projname,
	          pe2.ProcessGUID,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
from  [dbo].[jd_ProjectPlanTaskExecute] cb
      LEFT JOIN  jd_ProjectPlanExecute d ON cb.PlanID = d.ID
      LEFT JOIN  p_Project e ON d.ProjGUID = e.ProjGUID
     left join jd_TaskReport  rpt on cb.ID = rpt.taskid
     left join jd_Report_To_WF  wf on rpt.ID = wf.Reportid
     inner join myWorkflowProcessEntity pe2 on wf.BusinessGUID =pe2.BusinessGUID  
WHERE d.buguid = @buguid -- p.ProjGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);


--  动态成本月度回顾审批
INSERT INTO #Workflow
SELECT e.projname,
       pe2.ProcessGUID,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
FROM cb_DTCostRecollect cb
INNER JOIN myWorkflowProcessEntity pe2 ON cb.RecollectGUID = pe2.BusinessGUID
LEFT JOIN p_Project e ON cb.ProjectGUID = e.ProjGUID
WHERE cb.ProjectGUID IN (SELECT ProjGUID FROM #proj)
AND pe2.ProcessStatus IN (0, 1);


INSERT INTO #Workflow
select null as projname,
       pe2.ProcessGUID,
       pe2.ProcessKindName,
       BusinessType,
       pe2.ProcessKindGUID,
       pe2.ProcessName,
       pe2.OwnerName,
       pe2.InitiateDatetime,
       pe2.ProcessStatus
from  myWorkflowProcessEntity pe2
where  pe2.buguid = @buguid 
and pe2.ProcessStatus IN (0, 1)
and  pe2.BusinessType in ('部门费用月度计划审批','部门计划工作汇报审批','采购方案审批','项目年度预算客服类审批','修改结算金额审批')


-- 查询结果
SELECT 

       projname AS 项目名称,
	   ProcessGUID,
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

drop table  #Workflow,#proj
