USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_fy_Dept_Analysis]    Script Date: 2025/6/26 10:43:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROC [dbo].[usp_fy_Dept_Analysis](@var_Date DATETIME)
/*
用途：华南营销看板小屏，内控指标费用模块
运行样例：usp_fy_Dept_Analysis '2024-08-23 10:26:59.937'
author:ltx
date:20210609

modified by lintx 20240430
1、增加科目信息

modified by lintx 20240509
1、签约任务改成从营销看板填报的增量、新增量、存量签约任务之和
*/

AS
/*
本年费用总额: 费用费用系统-费用分析-部门费用分析-调整后预算
本年实际发生费用: 费用费用系统-费用分析-部门费用分析-1月-当月费用已发生数
本年费用使用率:本年实际发生费用/本年费用总额
本年签约进度:本年签约完成率
本年营销费率：本年实际发生费用/本年签约金额
本月费用总额： 费用费用系统-费用分析-部门费用分析-当月月度预算
本月实际发生费用： 费用费用系统-费用分析-部门费用分析-当月费用已发生数
本月费用使用率：本月实际发生费用/本月费用总额
本月签约进度：本月签约完成率
本月营销费率：本月实际发生费用/本月签约金额
 
*/
BEGIN
	--获取项目费用情况
    SELECT 
           pj.ProjGUID,
           cost.DeptCostGUID,
           cost.costcode ,
           cost.CostShortName,
           mon.统计月份 AS month,
           CASE
               WHEN mon.统计月份 = 1 THEN
                   yp.PlanAmount1
               WHEN mon.统计月份 = 2 THEN
                   yp.PlanAmount2
               WHEN mon.统计月份 = 3 THEN
                   yp.PlanAmount3
               WHEN mon.统计月份 = 4 THEN
                   yp.PlanAmount4
               WHEN mon.统计月份 = 5 THEN
                   yp.PlanAmount5
               WHEN mon.统计月份 = 6 THEN
                   yp.PlanAmount6
               WHEN mon.统计月份 = 7 THEN
                   yp.PlanAmount7
               WHEN mon.统计月份 = 8 THEN
                   yp.PlanAmount8
               WHEN mon.统计月份 = 9 THEN
                   yp.PlanAmount9
               WHEN mon.统计月份 = 10 THEN
                   yp.PlanAmount10
               WHEN mon.统计月份 = 11 THEN
                   yp.PlanAmount11
               WHEN mon.统计月份 = 12 THEN
                   yp.PlanAmount12
               ELSE
                   0
           END yPlanAmount,
           CASE
               WHEN mon.统计月份 = 1 THEN
                   t2.planamount
               WHEN mon.统计月份 = 2 THEN
                   t2.planamount
               WHEN mon.统计月份 = 3 THEN
                   t2.planamount
               WHEN mon.统计月份 = 4 THEN
                  t2.planamount
               WHEN mon.统计月份 = 5 THEN
                  t2.planamount
               WHEN mon.统计月份 = 6 THEN
                   t2.planamount
               WHEN mon.统计月份 = 7 THEN
                  t2.planamount
               WHEN mon.统计月份 = 8 THEN
                  t2.planamount
               WHEN mon.统计月份 = 9 THEN
                   t2.planamount
               WHEN mon.统计月份 = 10 THEN
                   t2.planamount
               WHEN mon.统计月份 = 11 THEN
                  t2.planamount
               WHEN mon.统计月份 = 12 THEN
                 t2.planamount
               ELSE
                   0
           END mPlanAmount,
           (CASE
                WHEN mon.统计月份 = 1 THEN
                    yp.FactAmount1
                WHEN mon.统计月份 = 2 THEN
                    yp.FactAmount2
                WHEN mon.统计月份 = 3 THEN
                    yp.FactAmount3
                WHEN mon.统计月份 = 4 THEN
                    yp.FactAmount4
                WHEN mon.统计月份 = 5 THEN
                    yp.FactAmount5
                WHEN mon.统计月份 = 6 THEN
                    yp.FactAmount6
                WHEN mon.统计月份 = 7 THEN
                    yp.FactAmount7
                WHEN mon.统计月份 = 8 THEN
                    yp.FactAmount8
                WHEN mon.统计月份 = 9 THEN
                    yp.FactAmount9
                WHEN mon.统计月份 = 10 THEN
                    yp.FactAmount10
                WHEN mon.统计月份 = 11 THEN
                    yp.FactAmount11
                WHEN mon.统计月份 = 12 THEN
                    yp.FactAmount12
                ELSE
                    0
            END
           ) AS FactAmount,
           (CASE
                WHEN mon.统计月份 = 1 THEN
                    yp.AdjustAmount1
                WHEN mon.统计月份 = 2 THEN
                    yp.AdjustAmount2
                WHEN mon.统计月份 = 3 THEN
                    yp.AdjustAmount3
                WHEN mon.统计月份 = 4 THEN
                    yp.AdjustAmount4
                WHEN mon.统计月份 = 5 THEN
                    yp.AdjustAmount5
                WHEN mon.统计月份 = 6 THEN
                    yp.AdjustAmount6
                WHEN mon.统计月份 = 7 THEN
                    yp.AdjustAmount7
                WHEN mon.统计月份 = 8 THEN
                    yp.AdjustAmount8
                WHEN mon.统计月份 = 9 THEN
                    yp.AdjustAmount9
                WHEN mon.统计月份 = 10 THEN
                    yp.AdjustAmount10
                WHEN mon.统计月份 = 11 THEN
                    yp.AdjustAmount11
                WHEN mon.统计月份 = 12 THEN
                    yp.AdjustAmount12
                ELSE
                    0
            END
           ) AS 调整费用,
           (CASE
                WHEN mon.统计月份 = 1 THEN
                    yp.PayAmount1
                WHEN mon.统计月份 = 2 THEN
                    yp.PayAmount2
                WHEN mon.统计月份 = 3 THEN
                    yp.PayAmount3
                WHEN mon.统计月份 = 4 THEN
                    yp.PayAmount4
                WHEN mon.统计月份 = 5 THEN
                    yp.PayAmount5
                WHEN mon.统计月份 = 6 THEN
                    yp.PayAmount6
                WHEN mon.统计月份 = 7 THEN
                    yp.PayAmount7
                WHEN mon.统计月份 = 8 THEN
                    yp.PayAmount8
                WHEN mon.统计月份 = 9 THEN
                    yp.PayAmount9
                WHEN mon.统计月份 = 10 THEN
                    yp.PayAmount10
                WHEN mon.统计月份 = 11 THEN
                    yp.PayAmount11
                WHEN mon.统计月份 = 12 THEN
                    yp.PayAmount12
                ELSE
                    0
            END
           ) AS 已支付费用,
           (CASE
                WHEN mon.统计月份 = 1 THEN
                    yp.OccupiedAmount1
                WHEN mon.统计月份 = 2 THEN
                    yp.OccupiedAmount2
                WHEN mon.统计月份 = 3 THEN
                    yp.OccupiedAmount3
                WHEN mon.统计月份 = 4 THEN
                    yp.OccupiedAmount4
                WHEN mon.统计月份 = 5 THEN
                    yp.OccupiedAmount5
                WHEN mon.统计月份 = 6 THEN
                    yp.OccupiedAmount6
                WHEN mon.统计月份 = 7 THEN
                    yp.OccupiedAmount7
                WHEN mon.统计月份 = 8 THEN
                    yp.OccupiedAmount8
                WHEN mon.统计月份 = 9 THEN
                    yp.OccupiedAmount9
                WHEN mon.统计月份 = 10 THEN
                    yp.OccupiedAmount10
                WHEN mon.统计月份 = 11 THEN
                    yp.OccupiedAmount11
                WHEN mon.统计月份 = 12 THEN
                    yp.OccupiedAmount12
                ELSE
                    0
            END
           ) AS 已占用费用
	INTO #t1
    FROM [172.16.4.141].MyCost_Erp352.dbo.ys_YearPlanProceeding2Cost yp
        INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.ys_DeptCost cost ON cost.DeptCostGUID = yp.CostGUID 
        INNER JOIN
        (
            SELECT DISTINCT
                   dep.DeptGUID AS DeptGUID,
                   dep.BUGUID,
                   p.ParentCode,
                   dep.Year
            FROM [172.16.4.141].MyCost_Erp352.dbo.fy_DimDept dep
                INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.ys_fy_DeptToProject fp
                    ON dep.DeptGUID = fp.DeptGUID
                INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.p_Project p
                    ON p.ProjGUID = fp.ProjectGUID
        ) act ON act.DeptGUID = yp.DeptGUID AND act.Year = yp.Year
        INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.p_Project pj ON pj.ProjCode = act.ParentCode 
        INNER JOIN
        (
            SELECT 1 AS 统计月份
            UNION ALL
            SELECT 2 AS 统计月份
            UNION ALL
            SELECT 3 AS 统计月份
            UNION ALL
            SELECT 4 AS 统计月份
            UNION ALL
            SELECT 5 AS 统计月份
            UNION ALL
            SELECT 6 AS 统计月份
            UNION ALL
            SELECT 7 AS 统计月份
            UNION ALL
            SELECT 8 AS 统计月份
            UNION ALL
            SELECT 9 AS 统计月份
            UNION ALL
            SELECT 10 AS 统计月份
            UNION ALL
            SELECT 11 AS 统计月份
            UNION ALL
            SELECT 12 AS 统计月份
        ) mon ON 1 = 1
        LEFT JOIN [172.16.4.141].MyCost_Erp352.dbo.ys_fy_SaleMonthPlan planm  ON planm.DeptGUID = yp.DeptGUID 
                       AND mon.统计月份 = planm.Month  AND planm.CostType = '营销类'    and planm.ApproveState = '已审核'
		left JOIN [172.16.4.141].MyCost_Erp352.dbo.ys_fy_SaleMonthPlan_FyysDetail t2 ON planm.GUID = t2.PlanGUID and t2.DeptCostGUID = yp.CostGUID
    WHERE  yp.Year = YEAR(@var_date) and cost.isendcost = 1 and  cost.CostType ='营销类'  -- 需要剔除掉客服类费用
        and cost.costshortname not in  ('政府相关收费','法律诉讼费用','租赁费','其他','大宗交易')
      --    AND cost.CostShortName = '部门费用';
		   
		 
	--获取费用的实际情况
	SELECT ProjGUID,DeptCostGUID,costcode ,CostShortName,
	--SUM(CASE WHEN MONTH BETWEEN 1 AND MONTH(@var_date) then ISNULL(yPlanAmount,0)+ISNULL(调整费用,0) ELSE 0 END ) AS 本年费用总额,
	sum(ISNULL(yPlanAmount,0)+ISNULL(调整费用,0)) AS 本年费用总额,
	SUM(CASE WHEN MONTH BETWEEN 1 AND MONTH(@var_date) then ISNULL(FactAmount,0) ELSE 0 END )  AS 本年实际发生费用,
	sum(ISNULL(FactAmount,0)) AS 本年合同发生费用,
	SUM(CASE WHEN MONTH = MONTH(@var_date) then ISNULL(mPlanAmount,0) ELSE 0 END ) AS 本月费用总额,
	SUM(CASE WHEN MONTH = MONTH(@var_date) then ISNULL(FactAmount,0)  ELSE 0 END )  AS 本月实际发生费用
	INTO #fy
	FROM #t1
	 GROUP BY ProjGUID,DeptCostGUID,costcode ,CostShortName

	--获取项目实际签约情况
	SELECT ParentProjGUID,
		   SUM(ISNULL(CNetAmount, 0) + ISNULL(SpecialCNetAmount, 0)) AS 本年签约金额,
		   SUM(   CASE
					  WHEN MONTH(StatisticalDate) = MONTH(@var_date) THEN
						  ISNULL(CNetAmount, 0) + ISNULL(SpecialCNetAmount, 0)
					  ELSE
						  0
				  END
			  ) AS 本月签约金额
	INTO #qy
	FROM dbo.data_wide_dws_s_SalesPerf
	WHERE StatisticalDate
	BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
	GROUP BY ParentProjGUID;

	--获取项目的签约任务
	SELECT OrganizationGUID,
		   SUM(   CASE
					  WHEN BudgetDimension = '年度' THEN
						  BudgetContractAmount
					  ELSE
						  0
				  END
			  ) AS 本年签约任务,
		   SUM(   CASE
					  WHEN BudgetDimension = '月度' THEN
						  BudgetContractAmount
					  ELSE
						  0
				  END
			  ) AS 本月签约任务
	INTO #task
	FROM dbo.data_wide_dws_s_SalesBudgetVerride t
	inner join data_wide_dws_mdm_Project pj on t.OrganizationGUID = pj.ProjGUID
	WHERE   CHARINDEX(CONVERT(VARCHAR(4), YEAR(@var_date)), BudgetDimensionValue, 1) > 0
		  AND
		  (
			  BudgetDimension = '年度'
			  OR
			  (
				  BudgetDimension = '月度'
				  AND CONVERT(INT, RIGHT(BudgetDimensionValue, 2)) = MONTH(@var_date)
			  )
		  )
		  and pj.BUGUID <> '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
	GROUP BY OrganizationGUID
	--华南公司从营销填报取数
	union all
    select projguid OrganizationGUID,
	        sum(年度签约任务) *10000 AS 本年签约任务,
			sum(月度签约任务) *10000 as 本月签约任务
		   --SUM(ISNULL(rw.本年存量任务, 0) +ISNULL(rw.本年增量任务, 0)+ISNULL(rw.本年新增量任务, 0))*10000 AS 本年签约任务,
		   --SUM(ISNULL(rw.本月存量任务, 0) +ISNULL(rw.本月增量任务, 0)+ISNULL(rw.本月新增量任务, 0))*10000 AS 本月签约任务
    from data_tb_hnyx_jdfxtb rw  
    group by projguid



	--缓存结果表
	SELECT 
     do.OrgGUID  AS 公司Guid, 
     do.OrganizationName AS 公司名称,
	 pj.ProjGUID AS 项目GUid,
	 pj.SpreadName AS 项目名称,
	 isnull(fy.本年费用总额,0) AS  本年费用总额,
	 isnull(fy.本年实际发生费用,0) AS 本年实际发生费用,
	 isnull(fy.本月费用总额,0) AS 本月费用总额,
	 isnull(fy.本月实际发生费用,0) AS 本月实际发生费用,
	 convert(decimal(16,2),0.00) as 本年签约金额,
	 convert(decimal(16,2),0.00) as 本月签约金额, 
	 convert(decimal(16,2),0.00) as 本年签约任务,
	 convert(decimal(16,2),0.00) as 本月签约任务,
	 --isnull(case when costcode= 'C.01.01.01.01' then qy.本年签约金额 else 0 end,0) AS 本年签约金额,
	 --isnull(case when costcode= 'C.01.01.01.01' then qy.本月签约金额 else 0 end,0) AS 本月签约金额, 
	 --isnull(case when costcode= 'C.01.01.01.01' then task.本年签约任务 else 0 end,0) AS 本年签约任务,
	 --isnull(case when costcode= 'C.01.01.01.01' then task.本月签约任务 else 0 end,0) AS 本月签约任务,
	 getdate() qxdate ,
     DeptCostGUID,costcode ,CostShortName,
     本年合同发生费用,
	 ROW_NUMBER() over(partition by pj.projguid order by costcode) as rn
	 into #tmp_res
	  FROM dbo.data_wide_dws_mdm_Project pj 
	 INNER JOIN dbo.data_wide_dws_s_Dimension_Organization do ON do.OrgGUID = pj.BUGUID 
	 LEFT JOIN #fy fy ON pj.ProjGUID = fy.projguid
	 WHERE  pj.level = 2 

	 --按照项目层级排序，然后在项目的某个科目上更新签约情况
	 update  t set t.本年签约金额 =  isnull(qy.本年签约金额,0) ,
	 t.本月签约金额 =  isnull(qy.本月签约金额,0) ,
	 t.本年签约任务 =  isnull(task.本年签约任务,0) ,
	 t.本月签约任务 =  isnull(task.本月签约任务 ,0) 
	 from #tmp_res t
	 LEFT JOIN #qy qy ON t.项目GUid = qy.ParentProjGUID
	 LEFT JOIN #task task ON t.项目GUid = task.OrganizationGUID
	 where t.rn = 1

	 --汇总数据
	 DELETE FROM fy_Dept_Analysis --WHERE DATEDIFF(dd,qxdate,getdate())=0
	 where 1=1

	 INSERT INTO fy_Dept_Analysis(
        [公司Guid],
        [公司名称],
        [项目GUid],
        [项目名称],
        [本年费用总额],
        [本年实际发生费用],
        [本月费用总额],
        [本月实际发生费用],
        [本年签约金额],
        [本月签约金额],
        [本年签约任务],
        [本月签约任务],
        [qxdate],
        [DeptCostGUID],
        [costcode],
        [本年合同发生费用],
		CostShortName)
		select [公司Guid],
			[公司名称],
			[项目GUid],
			[项目名称],
			[本年费用总额],
			[本年实际发生费用],
			[本月费用总额],
			[本月实际发生费用],
			[本年签约金额],
			[本月签约金额],
			[本年签约任务],
			[本月签约任务],
			[qxdate],
			[DeptCostGUID],
			[costcode],
			[本年合同发生费用],
			CostShortName
		from #tmp_res

	 
	
	--删除临时表
	DROP TABLE #qy,#t1,#task,#fy;
END;

 
