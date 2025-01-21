--SELECT   BusinessType,COUNT(1) FROM  dbo.myWorkflowProcessEntity WHERE ProcessStatus IN (0,1)
--AND  BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836'
--GROUP BY BusinessType
--ORDER BY COUNT(1) DESc 

--��ͬ�������
--��ͬ����
--������������
--��Ʊ������
--��ͬ��������
--���ø�����������
--�깤ȷ������
--¥���ƻ������㱨����
--���÷Ǻ�ͬ����
--���ú�ͬ����
--���ŷ������Ԥ������
--�Ǻ�ͬ����
--�ǵ���ִ�к�ͬ����
--��ͬԤ��������
--���÷ǵ���ִ�к�ͬ����
--�ɹ���������
--�����ĵ�����
--��̱��ƻ�����
--�������뵥����
--����������
--¥���ƻ���������
--���ú�ͬ��������
--�޸Ľ���������
--ս��Э������
--���żƻ������㱨����
--���ŷ����¶ȼƻ�����
--�ɹ��ƻ�����
--Ŀ��ɱ�����
--�޸�Ϊ���ֽ�֧������

--�����ѯ��Ŀ��Χ��ʱ��
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

--������ʱ��
CREATE TABLE #Workflow (projname VARCHAR(200) ,
                        ProcessKindName VARCHAR(200) ,
                        BusinessType VARCHAR(200) ,
                        ProcessKindGUID UNIQUEIDENTIFIER ,
                        ProcessName VARCHAR(2000) ,
                        OwnerName VARCHAR(200) ,
                        InitiateDatetime DATETIME ,
                        ProcessStatus VARCHAR(200));

--ERP352
--��ͬ�������
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    vcb_HtAlter cb --�滻��Ӧ��ҵ��ϵͳ��
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTAlterGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjCode = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--��ͬ����
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.vcb_Contract cb --�滻��Ӧ��ҵ��ϵͳ��
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.ContractGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--������������
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.vcb_HTFKApply cb --�滻��Ӧ��ҵ��ϵͳ��
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.HTFKApplyGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjectCode = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--��Ʊ������
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    dbo.vcb_DesignAlter cb --�滻��Ӧ��ҵ��ϵͳ��
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON cb.DesignAlterGuid = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON cb.ProjCodeList = p.ProjCode
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--��ͬ��������
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

--���ø����������� OK 
--�깤ȷ������ OK 
--¥���ƻ������㱨��������

--���÷Ǻ�ͬ���� OK 
--���ú�ͬ���� OK 
--���ŷ������Ԥ������ 
--�Ǻ�ͬ���� OK 
--�ǵ���ִ�к�ͬ���� OK 
--��ͬԤ��������
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

--���÷ǵ���ִ�к�ͬ���� ok 
--�ɹ���������
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

--�����ĵ�����
--��̱��ƻ�����
--�������뵥����
--����������
--¥���ƻ���������
--���ú�ͬ��������
--�޸Ľ���������
--ս��Э������
--���żƻ������㱨����
--���ŷ����¶ȼƻ�����
--�ɹ��ƻ�����
--Ŀ��ɱ�����
--�޸�Ϊ���ֽ�֧������
SELECT  projname AS ��Ŀ���� ,
        ProcessKindName AS ���̷��� ,
        BusinessType AS ҵ������ ,
        ProcessKindGUID ,
        ProcessName AS �������� ,
        OwnerName AS ������ ,
        InitiateDatetime AS ���̷���ʱ�� ,
        CASE WHEN ProcessStatus = 0 THEN '������' WHEN ProcessStatus = 1 THEN '���鵵' END AS ����״̬
FROM    #Workflow;
