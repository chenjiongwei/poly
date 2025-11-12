select 
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
from  myWorkflowProcessEntity a
inner join mybusinessunit bu on a.buguid =bu.BuGUID
 where bu.BUName ='河南公司' and  ProcessStatus in (0,1) and ProcessName like '%杓袁项目%'