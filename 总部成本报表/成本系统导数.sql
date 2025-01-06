-- 成本系统导数 chenjw 2025-01-02
-- 1、加一列“分期建设状态”
-- 2、数据过滤掉，名称=“待规划合约”的合约规划
use MyCost_Erp352
go 

SELECT  bu.buname AS 公司名称,
        p2.projname  AS 一级项目名称,
        p1.projname AS 分期名称,
        p1.ConstructStatus AS 分期建设状态,
        cbg.BudgetCode AS 合约规划编码,
        cbg.BudgetName AS 合约规划名称,
        cbg.CZManageModel AS 产值管理模式,
        CASE 
            WHEN ISNULL(budget2bld.Budget2GCBldNum, 0) > 0 THEN '是' 
            ELSE '否' 
        END AS 是否关联楼栋
FROM p_Project p
INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
INNER JOIN erp25.dbo.mdm_project p1 ON p1.projguid = p.ProjGUID
INNER JOIN erp25.dbo.mdm_project p2 ON p2.projguid = p1.ParentProjGUID
LEFT JOIN cb_Budget_Executing cbg ON cbg.ProjectGUID = p.ProjGUID
LEFT JOIN (
    SELECT BudgetGUID,
           COUNT(1) AS Budget2GCBldNum 
    FROM cb_Budget_Executing2GCBld  
    GROUP BY BudgetGUID
) budget2bld ON budget2bld.BudgetGUID = cbg.ExecutingBudgetGUID
WHERE 1 = 1  --and  ISNULL(budget2bld.Budget2GCBldNum, 0) > 0
and  cbg.BudgetName <> '待规划合约'
ORDER BY p.ProjCode,
         cbg.BudgetCode
