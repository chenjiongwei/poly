USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_newworkflowAnalysis]    Script Date: 2025/4/11 17:16:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
流程效率分析报表

---20200605 之前过滤掉发起步骤，现在改为只过滤掉第一次发起 --by yp
*/

--exec  [usp_rpt_newworkflowAnalysis] '248B1E17-AACB-E511-80B8-E41F13C51836','2024-01-01','2025-04-08'
ALTER PROC [dbo].[usp_rpt_newworkflowAnalysis]
(
    @var_buguid VARCHAR(MAX),
    @var_bgdate DATETIME,
    @var_enddate DATETIME
)
AS
BEGIN
    SELECT a.businesstype AS '流程类型',
           e.departmentname AS '部门',
           e.username AS '姓名',
           e.usercode AS '用户代码',
           e.defaultstationname AS '岗位',
           a.processname AS '流程名称',
           CASE a.ProcessStatus
               WHEN 2 THEN
                    '归档'
               WHEN -2 THEN
                    '作废'
               WHEN -1 THEN
                    '终止'
               WHEN 0 THEN
                    '处理中'
               WHEN 1 THEN
                    '已通过'
           END '流程状态',
           c.StepName AS '流程节点名称',
           d.handledatetime AS '审批日期',
           notifydatetime AS '规定日期',
           CASE
               WHEN d.handledatetime > notifydatetime THEN
                    '是'
               ELSE '否'
           END AS '是否超时',
           d.SysActiveDatetime AS '激活时间',
    	      dbo.[fn_GetWorkHoursByBU](a.buguid,d.SysActiveDatetime,d.handledatetime)  as  '审批工作时',
           a.InitiateDatetime as  '发起时间',
           case when a.ProcessStatus in (-2,-1) then null else  a.FinishDatetime end as '归档时间',
           case when  a.ProcessStatus in (-2,-1)  then null else  dbo.[fn_GetWorkHoursByBU](a.buguid,a.InitiateDatetime,a.FinishDatetime) end as '流程总工时'
    FROM myworkflowprocessentity a with (NOLOCK)
         LEFT JOIN myworkflowsteppathentity c with (NOLOCK) ON a.processguid = c.processguid
         INNER JOIN myworkflownodeentity d with (NOLOCK)  ON c.steppathguid = d.steppathguid
                                              AND d.ProcessGUID = a.ProcessGUID
         LEFT JOIN e_myuser e with (NOLOCK) ON d.handler = e.userguid
    WHERE (1 = 1)
          AND c.StepPathID <> 1 ---过滤掉第一次发起 yp
          AND a.buguid IN (
                              SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',')
                          )
          AND d.SysActiveDatetime  BETWEEN @var_bgdate AND @var_enddate
    ORDER BY a.businesstype,
             e.DepartmentName,
             e.UserName;
END;