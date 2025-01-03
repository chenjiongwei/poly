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
	-- 创建临时表时添加聚集索引
	CREATE TABLE #CFBld (
		ProjGUID uniqueidentifier,
		bldGUID varchar(50),
		BUGUID uniqueidentifier,
		BUName nvarchar(100),
		TaskCode nvarchar(50),
		TaskName nvarchar(200),
		KeyNodeName nvarchar(100),
		TaskStateName nvarchar(50),
		TaskState int,
		TaskTypeName nvarchar(50),
		Duration decimal(18,2),
		ActualFinishTime datetime,
		FinishTime datetime,
		ActualStartTime datetime
	);

	-- 创建聚集索引
	CREATE CLUSTERED INDEX IX_CFBld ON #CFBld(ProjGUID, bldGUID);

	-- 优化数据筛选条件，提前过滤
	INSERT INTO #CFBld
	SELECT DISTINCT 
		jh.ProjGUID,
		t.Value AS bldGUID,
		jh.BUGUID,
		jh.BUName,
		jh.TaskCode,
		jh.TaskName,
		jh.KeyNodeName,
		jh.TaskStateName,
		jh.TaskState,
		jh.TaskTypeName,
		jh.Duration,
		jh.ActualFinishTime,
		jh.FinishTime,
		jh.ActualStartTime
	FROM dbo.data_wide_jh_TaskDetail jh
	OUTER APPLY (
		SELECT Value 
		FROM dbo.fn_Split2(jh.BuildingGUIDs,',')
	) t
	WHERE jh.PlanType = 103
	AND jh.level = 2
	AND jh.TaskTypeName = '里程碑'
	AND DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) = DATEADD(yy, DATEDIFF(yy, 0, ISNULL(jh.FinishTime,'2099-12-31')), 0)
	AND ISNULL(jh.FinishTime,'2099-12-31') < GETDATE();

	-- 创建项目维度表的临时表以提高join性能
	SELECT DISTINCT 
		p.ProjGUID,
		p.XMSSCSGSGUID,
		o.ParentOrganizationGUID,
		o.OrgGUID,
		o.OrganizationName
	INTO #ProjectOrg
	FROM data_wide_dws_mdm_Project p
	INNER JOIN data_wide_dws_s_Dimension_Organization o 
		ON o.OrgGUID = p.XMSSCSGSGUID
	WHERE o.OrganizationType = '项目部';

	CREATE CLUSTERED INDEX IX_ProjectOrg ON #ProjectOrg(ProjGUID);

	-- 最终查询
	SELECT 
		po.ParentOrganizationGUID AS buguid,
		po.OrgGUID,
		po.OrganizationName AS 项目部名称,
		COUNT(1) AS 里程碑节点个数,
		SUM(CASE WHEN tk.TaskStateName = '按期完成' THEN 1 ELSE 0 END) AS 按期达成节点数,
		CAST(SUM(CASE WHEN tk.TaskStateName = '按期完成' THEN 1 ELSE 0 END) AS DECIMAL(18,2)) / 
			NULLIF(COUNT(1), 0) AS 完成率
	FROM #CFBld tk
	INNER JOIN #ProjectOrg po ON tk.ProjGUID = po.ProjGUID
	GROUP BY 
		po.ParentOrganizationGUID,
		po.OrgGUID,
		po.OrganizationName;

	-- 清理临时表
	DROP TABLE #CFBld;
	DROP TABLE #ProjectOrg;
    END;