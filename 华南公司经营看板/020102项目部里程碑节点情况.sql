USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_rptzjlkb_KeyNodesProjDept]    Script Date: 2024/12/28 11:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROC [dbo].[usp_s_rptzjlkb_KeyNodesProjDept]
AS
    /*
功能：总经理看板PC报表,获取020102项目部里程碑节点情况
创建人：chenjw
创建时间：20200818
[usp_s_rptzjlkb_KeyNodesProjDept]
*/
    BEGIN
	--计划明细宽表拆分楼栋
	SELECT DISTINCT jh.ProjGUID
		  , t.Value bldGUID
		  ,jh.BUGUID
		  ,jh.BUName
		  ,jh.TaskCode
		  ,jh.TaskName
		  ,jh.KeyNodeName
		  ,jh.TaskStateName
		  ,jh.TaskState
		  ,jh.TaskTypeName
		  ,jh.Duration
		  ,jh.ActualFinishTime
		  ,jh.FinishTime
		  ,jh.ActualStartTime
	INTO  #CFBld
	FROM dbo.data_wide_jh_TaskDetail jh
	OUTER APPLY (SELECT Value FROM dbo.fn_Split2(jh.BuildingGUIDs,',') ) t
	WHERE --jh.BUGUID = '248B1E17-AACB-E511-80B8-E41F13C51836'
		  (1=1) AND  jh.PlanType = 103
		 -- AND jh.Level = 1
		  AND ((jh.KeyNodeName IN ('预售办理','达到预售形象') AND jh.level=2) OR ((jh.KeyNodeName NOT IN ('预售办理','达到预售形象') AND jh.level=2)))
		ORDER BY jh.ProjGUID,t.Value,jh.TaskName;

        --项目部里程碑节点达成数
        SELECT buguid ,
               OrgGUID ,
               项目部名称 ,
               总节点数 AS 里程碑节点个数 ,
               完成节点数 AS 按期达成节点数 ,
               CASE WHEN 总节点数 = 0 THEN 0
                    ELSE 完成节点数 * 1.0 / 总节点数
               END AS 完成率
        FROM   (   SELECT   do.ParentOrganizationGUID AS buguid ,
                            do.OrgGUID ,
                            do.OrganizationName AS 项目部名称 ,
                            COUNT(1) 总节点数 ,
                            SUM(CASE WHEN TaskStateName IN ( '按期完成' ) THEN 1
                                     ELSE 0
                                END) AS 完成节点数
                   FROM     #CFBld tk --data_wide_jh_TaskDetail tk
                            INNER JOIN data_wide_dws_mdm_Project pj ON tk.ProjGUID = pj.ProjGUID
                            INNER JOIN data_wide_dws_s_Dimension_Organization do ON do.OrgGUID = pj.XMSSCSGSGUID
                   WHERE    TaskTypeName = '里程碑'  --AND ((tk.KeyNodeName IN ('预售办理','达到预售形象') AND tk.level = 2)
				  -- OR (tk.KeyNodeName NOT IN ('预售办理','达到预售形象') AND tk.level = 1))
                         --   AND PlanType = 103 
							AND do.OrganizationType = '项目部'
                            AND DATEDIFF(yy, ISNULL(FinishTime,'2099-12-31'), GETDATE()) = 0
							AND ISNULL(FinishTime,'2099-12-31') < GETDATE()
                   GROUP BY do.ParentOrganizationGUID ,
                            do.OrgGUID ,
                            do.OrganizationName ) t;
			DROP TABLE #CFBld;
    END;