USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_newworkflowAnalysis]    Script Date: 2025/4/11 17:16:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
create chenjw 2025-07-17
流程效率分析报表清洗
每天晚上清洗湾区最近2年的数据
*/

--exec  [usp_rpt_newworkflowAnalysis_wq_qx] 
CREATE OR ALTER PROC [dbo].[usp_rpt_newworkflowAnalysis_wq_qx]
-- (
--     @var_buguid VARCHAR(MAX),
--     @var_bgdate DATETIME,
--     @var_enddate DATETIME
-- )
AS
BEGIN
  -- 湾区
   DECLARE @var_buguid VARCHAR(MAX) = '248B1E17-AACB-E511-80B8-E41F13C51836'
   DECLARE @var_bgdate DATETIME = DATEADD(YEAR, -1, DATEADD(DAY, 1-DATEPART(DAYOFYEAR, GETDATE()), GETDATE())) -- 去年第一天
   DECLARE @var_enddate DATETIME = DATEADD(DAY, -1, DATEADD(YEAR, 1, DATEADD(DAY, 1-DATEPART(DAYOFYEAR, GETDATE()), GETDATE()))) -- 今年最后一天
--    SELECT 
--        a.buguid,
--        a.ProcessGUID,
--        a.businesstype AS '流程类型',
--        e.departmentname AS '部门',
--        e.username AS '姓名',
--        e.usercode AS '用户代码',
--        e.defaultstationname AS '岗位',
--        a.processname AS '流程名称',
--        CASE a.ProcessStatus
--            WHEN 2 THEN '归档'
--            WHEN -2 THEN '作废'
--            WHEN -1 THEN '终止'
--            WHEN 0 THEN '处理中'
--            WHEN 1 THEN '已通过'
--        END '流程状态',
--        c.StepName AS '流程节点名称',
--        d.handledatetime AS '审批日期',
--        notifydatetime AS '规定日期',
--        CASE
--            WHEN d.handledatetime > notifydatetime THEN '是'
--            ELSE '否'
--        END AS '是否超时',
--        d.SysActiveDatetime AS '激活时间',
--        a.InitiateDatetime as '发起时间',
--        CASE WHEN a.ProcessStatus IN (-2,-1) THEN NULL ELSE a.FinishDatetime END AS '归档时间',
--        -- 存储计算工时所需的原始数据，避免重复调用函数
--        d.SysActiveDatetime AS 审批开始时间,
--        d.handledatetime AS 审批结束时间,
--        a.InitiateDatetime AS 流程开始时间,
--        a.FinishDatetime AS 流程结束时间,
--        a.ProcessStatus AS 流程状态码
--    INTO #workflow_base_data
--    FROM myworkflowprocessentity a WITH (NOLOCK)
--    LEFT JOIN myworkflowsteppathentity c WITH (NOLOCK) ON a.processguid = c.processguid
--    INNER JOIN myworkflownodeentity d WITH (NOLOCK) ON c.steppathguid = d.steppathguid AND d.ProcessGUID = a.ProcessGUID
--    LEFT JOIN e_myuser e WITH (NOLOCK) ON d.handler = e.userguid
--    WHERE (1 = 1)
--        AND c.StepPathID <> 1 ---过滤掉第一次发起 yp
--        AND a.buguid IN (SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ','))
--        AND d.SysActiveDatetime BETWEEN @var_bgdate AND @var_enddate;

--    -- 步骤2：批量计算工时并插入最终结果表
--    -- 这里我们一次性计算所有工时，而不是每行调用函数
--    SELECT 
--        base.*,
--        -- 批量计算审批工作时
--        dbo.[fn_GetWorkHoursByBU](base.buguid, base.审批开始时间, base.审批结束时间) AS '审批工作时',
--        -- 批量计算流程总工时
--        CASE WHEN base.流程状态码 IN (-2,-1) THEN NULL 
--             ELSE dbo.[fn_GetWorkHoursByBU](base.buguid, base.流程开始时间, base.流程结束时间) 
--        END AS '流程总工时'
--    INTO #newworkflowAnalysis_wq_qx
--    FROM #workflow_base_data base;

    SELECT DISTINCT
            a.buguid,
            a.ProcessGUID,
            a.businesstype AS '流程类型',
            e.departmentname AS '部门',
            e.username AS '姓名',
            e.usercode AS '用户代码',
            e.defaultstationname AS '岗位',
            a.processname AS '流程名称',
            CASE a.ProcessStatus
                WHEN 2 THEN '归档'
                WHEN -2 THEN '作废'
                WHEN -1 THEN '终止'
                WHEN 0 THEN '处理中'
                WHEN 1 THEN '已通过'
            END AS '流程状态',
            c.StepName AS '流程节点名称',
            d.handledatetime AS '审批日期',
            notifydatetime AS '规定日期',
            CASE
                WHEN TRY_CAST(d.handledatetime as datetime) > TRY_CAST( notifydatetime as datetime )THEN '是'
                ELSE '否'
            END AS '是否超时',
            case when d.NodeStatus =-3 then '已打回'
                when d.NodeStatus =-2 then '已作废'
                when d.NodeStatus =-1 then '已终止'
                when d.NodeStatus =0 then '未激活'
                when d.NodeStatus =1 then '待办'
                when d.NodeStatus =2 then '在办'
                when d.NodeStatus =3 then '已办结'
                when d.NodeStatus =4 then '已交办' end as '节点状态',
            d.HandleText as '处理意见',
            d.SysActiveDatetime AS '激活时间',
            dbo.[fn_GetWorkHoursByBU](a.buguid, TRY_CAST(d.SysActiveDatetime as datetime), TRY_CAST(d.handledatetime as datetime) ) AS '审批工作时',
            a.InitiateDatetime AS '发起时间',
            CASE 
                WHEN a.ProcessStatus IN (-2, -1) THEN NULL
                ELSE a.FinishDatetime 
            END AS '归档时间',
            CASE 
            WHEN a.ProcessStatus IN (-2, -1) THEN null
            ELSE dbo.[fn_GetWorkHoursByBU](a.buguid, a.InitiateDatetime, a.FinishDatetime) 
            END AS '流程总工时'
        into #newworkflowAnalysis_wq_qx
        FROM 
            myworkflowprocessentity a WITH (NOLOCK)
            LEFT JOIN myworkflowsteppathentity c WITH (NOLOCK)  ON a.processguid = c.processguid
            INNER JOIN myworkflownodeentity d WITH (NOLOCK)   ON c.steppathguid = d.steppathguid AND d.ProcessGUID = a.ProcessGUID
            LEFT JOIN e_myuser e WITH (NOLOCK)  ON d.handler = e.userguid
        WHERE 
            c.StepPathID <> 1 
            AND a.buguid IN (SELECT [Value] FROM dbo.fn_Split2(@var_buguid, ','))
            -- 显式转换日期字段（如果字段是 nvarchar）
            AND TRY_CAST(d.SysActiveDatetime AS DATETIME) BETWEEN @var_bgdate AND @var_enddate
    -- ORDER BY 
    --     a.businesstype,
    --     e.DepartmentName,
    --     e.UserName;

   -- 步骤3：先删除后插入
   TRUNCATE TABLE newworkflowAnalysis_wq_qx;
   
   ---- 只插入需要的列，不包括临时计算列
   INSERT INTO [dbo].[newworkflowAnalysis_wq_qx]
   SELECT 
       buguid,
       ProcessGUID,
       [流程类型],
       [部门],
       [姓名],
       [用户代码],
       [岗位],
       [流程名称],
       [流程状态],
       [流程节点名称],
       [审批日期],
       [规定日期],
       [是否超时],
       [激活时间],
       [审批工作时],
       [发起时间],
       [归档时间],
       [流程总工时],
       [节点状态],
       [处理意见]
   FROM #newworkflowAnalysis_wq_qx
   ORDER BY [流程类型], [部门], [姓名];



   -- 删除临时表
   -- DROP TABLE #workflow_base_data;
   DROP TABLE #newworkflowAnalysis_wq_qx;
END;


-- -- 报表查询
-- SELECT [buguid]
--       ,[ProcessGUID]
--       ,[流程类型]
--       ,[部门]
--       ,[姓名]
--       ,[用户代码]
--       ,[岗位]
--       ,[流程名称]
--       ,[流程状态]
--       ,[流程节点名称]
--       ,[审批日期]
--       ,[规定日期]
--       ,[是否超时]
--       ,[激活时间]
--       ,[审批工作时]
--       ,[发起时间]
--       ,[归档时间]
--       ,[流程总工时]
--   FROM [dbo].[newworkflowAnalysis_wq_qx] with (nolock)
--   where  [激活时间] BETWEEN @var_bgdate AND @var_enddate  and  buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') )
--   ORDER BY [流程类型],
--              [部门],
--              [姓名]