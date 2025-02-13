--SELECT  BusinessType ,
--        COUNT(1)
--FROM    dbo.myWorkflowProcessEntity
--WHERE   ProcessStatus IN ( 0, 1 )
--        AND BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'
--GROUP BY BusinessType
--ORDER BY COUNT(1) DESC; 

--SELECT  *
--FROM    dbo.myWorkflowProcessEntity
--WHERE   ProcessStatus IN ( 0, 1 )
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

--将湾中公司项目和分期插入到临时表中
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

--ERP25 销售变更审批
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    vs_SaleModiApply_WF a --替换对应的业务系统表
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON a.SaleModiApplyGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--合同审批
SELECT  projname AS 项目名称 ,
        ProcessKindName AS 流程分类 ,
        BusinessType AS 业务类型 ,
        ProcessKindGUID ,
        ProcessName AS 流程名称 ,
        OwnerName AS 责任人 ,
        InitiateDatetime AS 流程发起时间 ,
        CASE WHEN ProcessStatus = 0 THEN '审批中' WHEN ProcessStatus = 1 THEN '待归档' END AS 流程状态
FROM    #Workflow;

----删除临时表
--DROP TABLE  #Workflow
--DROP TABLE #proj
