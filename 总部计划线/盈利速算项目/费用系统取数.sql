-- 东北公司 22-24年 分年份 分项目 分科目（到二级科目即可） 导出发生的费用总额以及 项目对应的本年度签约合同总额

-- 还有一个字段存储 该二级科目发生的费用总额 / 项目对应本年度的签约合同总额


with data_wide_fy_YearPlanDtl 
as (
SELECT YearPlanDept2CostGUID ,
       BUGUID ,
       DeptGUID ,
       SpecialUnitName ,
       ProjGUID ,
       t.ProjName ,
       ProjectListName ,
       Year ,
       CostGUID ,
       CostCode ,
       CostShortName ,
       CostLevel ,
       CostType ,
       ParentCode ,
       IsEndCost ,
       PlanAmount ,                                                                                --年初预算金额
       AdjustAmount ,                                                                              --调整金额
       FactAmount ,                                                                                --已发生金额
       ISNULL(PlanAmount, 0) + ISNULL(AdjustAmount, 0) - ISNULL(FactAmount, 0) AS YearYsylAmount , --预算余量金额 等于（预算金额+调整金额-已发生金额）
       CASE WHEN ISNULL(YearSaleTargetAmount, 0) = 0 THEN 0
            ELSE ( ISNULL(PlanAmount, 0) + ISNULL(AdjustAmount, 0)) * 1.00 / ISNULL(YearSaleTargetAmount, 0)
       END AS YearRate ,                                                                           --费率（等于本年调整后金额/本年销售任务）
       PayAmount ,                                                                                 --实付金额
	   t.YearHTAmount,  --合同金额
	   t.YearFHTAmount, --非合同金额
       YearSaleCompleteAmount ,                                                                    --年度销售完成率
       YearSaleTargetAmount ,                                                                      --本年销售任务
       YearActualContractAmount ,                                                                  --本年实际签约金额
       YearOrderAmount ,                                                                           --本年实际认购金额
       YearContractAmount ,                                                                        --本年已签合同金额
       ThisYearSurplusContractAmount ,                                                             --本年剩余可签合同金额

       ToLastYearOutstandingAmount ,                                                               --截止到上一年底应付未付金额
       YearDifferAmount ,                                                                          --本年预算与实付差额
       YearNewContractOutstandingAmount ,                                                          --本年新签合同本年应付未付金额
       YearOutstandingAmount                                                                       --本年应付未付金额
FROM
       (   SELECT a.YearPlanDept2CostGUID ,
                  a.BUGUID ,
                  a.DeptGUID ,
                  b.SpecialUnitName ,
                  b.ProjGUID ,
                  p.ProjName ,
                  b.ProjectListName ,
                  a.Year ,
                  a.CostGUID ,
                  d.CostCode ,
                  d.CostShortName ,
                  d.CostLevel ,
                  d.ParentCode ,
                  CASE WHEN d.CostCode = 'C.01' THEN '营销费用类' ELSE d.CostType END AS CostType ,
                  d.IsEndCost ,
                  ISNULL(PlanAmount1, 0) + ISNULL(PlanAmount2, 0) + ISNULL(PlanAmount3, 0) + ISNULL(PlanAmount4, 0)
                  + ISNULL(PlanAmount5, 0) + ISNULL(PlanAmount6, 0) + ISNULL(PlanAmount7, 0) + ISNULL(PlanAmount8, 0)
                  + ISNULL(PlanAmount9, 0) + ISNULL(PlanAmount10, 0) + ISNULL(PlanAmount11, 0) + ISNULL(PlanAmount12, 0) AS PlanAmount , --年初预算金额
                  ISNULL(a.AdjustAmount1, 0) + ISNULL(AdjustAmount2, 0) + ISNULL(AdjustAmount3, 0) + ISNULL(AdjustAmount4, 0)
                  + ISNULL(AdjustAmount5, 0) + ISNULL(AdjustAmount6, 0) + ISNULL(AdjustAmount7, 0) + ISNULL(AdjustAmount8, 0)
                  + ISNULL(AdjustAmount9, 0) + ISNULL(AdjustAmount10, 0) + ISNULL(AdjustAmount11, 0)
                  + ISNULL(AdjustAmount12, 0) AS AdjustAmount ,                                                                          --调整金额
                  ISNULL(a.FactAmount1, 0) + ISNULL(FactAmount2, 0) + ISNULL(FactAmount3, 0) + ISNULL(FactAmount4, 0)
                  + ISNULL(FactAmount5, 0) + ISNULL(FactAmount6, 0) + ISNULL(FactAmount7, 0) + ISNULL(FactAmount8, 0)
                  + ISNULL(FactAmount9, 0) + ISNULL(FactAmount10, 0) + ISNULL(FactAmount11, 0) + ISNULL(FactAmount12, 0) AS FactAmount , --已发生金额

                  ISNULL(PayAmount1, 0) + ISNULL(PayAmount2, 0) + ISNULL(PayAmount3, 0) + ISNULL(PayAmount4, 0)
                  + ISNULL(PayAmount5, 0) + ISNULL(PayAmount6, 0) + ISNULL(PayAmount7, 0) + ISNULL(PayAmount8, 0)
                  + ISNULL(PayAmount9, 0) + ISNULL(PayAmount10, 0) + ISNULL(PayAmount11, 0) + ISNULL(PayAmount12, 0) AS PayAmount ,      --实付金额

                  ISNULL(c.YearHTAmount,0) AS YearHTAmount ,                                                                                                       --本年签署合同金额
                  ISNULL(c.YearFHTAmount,0) AS YearFHTAmount,                                                                                                      --本年签署非合同金额
                  c.YearSaleCompleteAmount ,                                                                                             --年度销售完成率
                  c.YearSaleTargetAmount ,                                                                                               --本年销售任务
                  c.YearActualContractAmount ,                                                                                           --本年实际签约金额
                  c.YearOrderAmount ,                                                                                                    --本年实际认购金额
                  c.YearContractAmount ,                                                                                                 --本年已签合同金额
                  c.ThisYearSurplusContractAmount ,                                                                                      --本年剩余可签合同金额

                  c.ToLastYearOutstandingAmount ,                                                                                        --截止到上一年底应付未付金额
                  c.YearDifferAmount ,                                                                                                   --本年预算与实付差额
                  c.YearNewContractOutstandingAmount ,                                                                                   --本年新签合同本年应付未付金额
                  c.YearOutstandingAmount                                                                                                --本年应付未付金额
           FROM   ys_YearPlanDept2Cost a
                  INNER JOIN ys_YearPlanDept2Cost_IndexYear c ON c.YearPlanDept2CostGUID = a.YearPlanDept2CostGUID
                  INNER JOIN ys_SpecialBusinessUnit b ON a.Year = b.Year
                                                         AND a.DeptGUID = b.SpecialUnitGUID
                  INNER JOIN dbo.ys_DeptCost d ON d.DeptCostGUID = a.CostGUID
                                                  AND d.Year = a.Year
                  INNER JOIN dbo.p_Project p ON p.ProjGUID = b.ProjGUID
           WHERE  d.CostLevel in (2,3) and  a.buguid = '528CA87C-F7AF-4FDD-BD05-79641D9F67FB'
		          --(( d.CostType = '客服类' OR d.CostType = '佣金类' OR d.CostType = '营销推广类' ) AND d.IsEndCost = 1 )
            --      OR d.CostCode = 'C.01' 
		) t

) 


-- 查询结果
select
    DeptGUID as 预算部门GUID ,
	SpecialUnitName as 预算部门名称,
    projguid as 项目guid,
    ProjectListName as 项目名称,
    Year as 年度,
    CostCode as 费用科目编码,
    CostShortName as 费用科目名称,
    CostLevel as 费用科目层级,
    IsEndCost as 是否末级科目,
    CostType as 科目类别,
    PlanAmount as 年初费用预算金额,
    AdjustAmount as 调整费用预算金额,
    FactAmount as 本年已发生金额,
    YearActualContractAmount as 本年实际签约金额
    -- YearContractAmount as 本年已签合同金额
from
    data_wide_fy_YearPlanDtl
where
    buguid = '528CA87C-F7AF-4FDD-BD05-79641D9F67FB'
	order by  SpecialUnitName,Year,CostCode