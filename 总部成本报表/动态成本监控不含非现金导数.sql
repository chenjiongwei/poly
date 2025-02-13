-- 查询动态成本监控模块中动态成本不含非现金
use MyCost_Erp352
go 
SELECT 
    a.CostGUID as  科目主键, --科目主键
    bu.BUName AS 公司名称, --公司名称
    a.BUGUID AS 公司GUID, --公司GUID
    p.ProjName AS 项目分期名称, --项目分期名称
    p.ProjGUID AS 项目分期GUID, --项目分期GUID
	trg.TargetStageVersion as 目标成本业务版本, --目标成本业务版本
    pp.ProjName AS 项目名称, --项目名称
    pp.ProjGUID AS 项目GUID, --项目GUID
    a.CostShortName AS 科目名称, --科目名称
    a.CostShortCode AS 科目短编码, --科目短编码
    a.CostCode AS 科目编码, --科目编码
    a.CostLevel AS 科目层级, --科目层级
    a.CostType AS 科目类别, --科目类别
	a.CostCategory as 科目细类, --科目细类
    a.IfEndCost AS 是否末级科目, --是否末级科目
    IsBigCost as 是否科目大类,--是否科目大类
    ISNULL(a.TargetCost, 0) AS '目标成本（含税）', --目标成本（含税）
    ISNULL(a.TargetCostNoTax, 0) AS '目标成本（不含税）', --目标成本（不含税）
    ISNULL(a.ExcludingTaxYfsCost, 0)+ISNULL(a.ExcludingTaxDfsCost, 0)-ISNULL(a.ExcludingTaxFxjCost, 0) AS '动态成本_不含税_不含非现金', --动态成本（不含税）
    ISNULL(a.YfsCost, 0)+ISNULL(a.DfsCost, 0)-ISNULL(a.FxjCost, 0) AS '动态成本_含税_不含非现金' --动态成本（含税）不含非现金
	-- ISNULL(a.YfsCost, 0)+ISNULL(a.DfsCost, 0) AS '动态成本（含税）含非现金', --动态成本（含税）
FROM dbo.cb_Cost a
     INNER JOIN myBusinessUnit bu ON a.BUGUID=bu.BUGUID
     INNER JOIN p_Project p ON p.ProjCode=a.ProjectCode AND p.Level=3
     LEFT JOIN p_Project pp ON pp.ProjCode=p.ParentCode AND pp.Level=2
	 outer apply (
	   select  top 1 TargetStageVersion from [cb_TargetStage2Project] 
	   where  ProjGUID = p.ProjGUID and  ApproveState ='已审核'
	   order by  ApproveDate desc
	 ) trg
where   1=1  
order by  bu.BUName,p.ProjName,a.CostCode


