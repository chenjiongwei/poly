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
--        AND BusinessType = '��ͬ�������������';

--��ͬ������������� 259
--����ǩԼ���� 101
--������������ 49
--����Ȩ�������� 40
--�������ޱ������ 32
--���۷������� 15
--�˷����� 14
--�˷����������� 8
--�ۿ۷������� 7
--̢�����˿����� 6
--Ӷ���걨���� 4
--̢������ 3
--�Ǻ�ͬ�������� 2
--�ۿ۱������ 2
--��ͬ���������� 1

--�����ѯ��Ŀ��Χ��ʱ��
--DROP TABLE #proj

--�����й�˾��Ŀ�ͷ��ڲ��뵽��ʱ����
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

--ERP25 ���۱������
INSERT INTO #Workflow
SELECT  p.projname ,
        pe2.ProcessKindName ,
        BusinessType ,
        pe2.ProcessKindGUID ,
        pe2.ProcessName ,
        pe2.OwnerName ,
        pe2.InitiateDatetime ,
        pe2.ProcessStatus
FROM    vs_SaleModiApply_WF a --�滻��Ӧ��ҵ��ϵͳ��
        INNER JOIN dbo.myWorkflowProcessEntity pe2 ON a.SaleModiApplyGUID = pe2.BusinessGUID
        INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
WHERE   p.ProjGUID IN(SELECT    ProjGUID FROM   #proj) AND  pe2.ProcessStatus IN (0, 1);

--��ͬ����
SELECT  projname AS ��Ŀ���� ,
        ProcessKindName AS ���̷��� ,
        BusinessType AS ҵ������ ,
        ProcessKindGUID ,
        ProcessName AS �������� ,
        OwnerName AS ������ ,
        InitiateDatetime AS ���̷���ʱ�� ,
        CASE WHEN ProcessStatus = 0 THEN '������' WHEN ProcessStatus = 1 THEN '���鵵' END AS ����״̬
FROM    #Workflow;

----ɾ����ʱ��
--DROP TABLE  #Workflow
--DROP TABLE #proj
