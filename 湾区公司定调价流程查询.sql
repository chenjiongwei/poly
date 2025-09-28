-- 查询 23年-2025 的湾区公司 定调价流程
-- 流程标题、流程状态、发起人、发起时间、归档时间



select  BusinessType,count(1) 
from  myWorkflowProcessEntity where  BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836' and ProcessStatus  in (0,1,2) and year(InitiateDatetime ) in (2023,2024,2025)
group by BusinessType ='调价方案审批'


-4:新建
-3:草稿
-2:已作废
-1:已终止
0:处理中，注意如果涉及被打回步骤，流程状态仍然属于在办
1:已通过
2:已归档

select
    ProcessName as  流程标题,
	case when  ProcessStatus =0 then '处理中' 
       when  ProcessStatus =1 then '已通过'
      --  when  ProcessStatus =-1 then '已终止'   
       when ProcessStatus =2 then '已归档' end as  流程状态,
	OwnerName as  发起人,
	InitiateDatetime as 发起时间,
	FinishDatetime 归档时间
from
    myWorkflowProcessEntity
where
    BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'
    and ProcessStatus in (0, 1, 2)
    and year(InitiateDatetime) in (2023, 2024, 2025)
    and BusinessType = '调价方案审批'