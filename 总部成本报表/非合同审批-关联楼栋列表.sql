-- SELECT a.BudgetName AS [合约规划名称],
--        a.ProjName AS [项目名称-分期],
--        CASE
--            WHEN b.OldBudgetAmount IS NOT NULL THEN
--                b.OldBudgetAmount
--            WHEN c.OldBudgetAmount IS NOT NULL THEN
--                c.OldBudgetAmount
--            WHEN d.OldBudgetAmount IS NOT NULL THEN
--                d.OldBudgetAmount
--            ELSE
--                0
--        END [原合约规划金额(含税)(目标成本)],
-- 	   a.BudgetAmount AS [当前规划金额(含税)],
-- 	   a.ContractAmount AS [合同金额(含税)],
-- 	   a.Yljbl AS [预留金比例],
-- 	   a.YgAlterAmount AS [预留金金额],
-- 	   a.Ylye AS [结余],
-- 	   a.Zylc AS [总余量池],
-- 	   a.ExecutingBudgetGUID AS [合约规划GUID]
-- FROM
-- (
--     SELECT e.BudgetName,
--            c.ProjName,
--            SUM(ISNULL(a.CfAmount, 0)) AS ContractAmount,
--            CASE
--                WHEN b.bgxs = '总价包干' THEN
--                    e.YGTotalPriceUL
--                ELSE
--                    e.YGPriceUL
--            END Yljbl,
--            SUM(ISNULL(a.YgAlterAmount, 0)) AS YgAlterAmount,
--            SUM(ISNULL(d.BudgetAmount, 0)) - SUM(ISNULL(a.CfAmount, 0)) - SUM(ISNULL(a.YgAlterAmount, 0)) AS Ylye,
--            e.ExecutingBudgetGUID,
--            SUM(ISNULL(d.BudgetAmount, 0)) AS BudgetAmount,
-- 		   SUM(ISNULL(f.LayoutSpare,0)) AS Zylc
--     FROM dbo.cb_BudgetUse a
--         INNER JOIN dbo.cb_Contract b
--             ON b.ContractGUID = a.RefGUID
--         INNER JOIN dbo.p_Project c
--             ON c.ProjCode = a.ProjectCode
--                AND c.BUGUID = b.BUGUID
--         INNER JOIN dbo.cb_Budget d
--             ON d.BudgetGUID = a.BudgetGUID
--         INNER JOIN dbo.cb_Budget_Executing e
--             ON e.ExecutingBudgetGUID = d.ExecutingBudgetGUID
--         INNER JOIN dbo.cb_Cost f
--             ON f.CostGUID = a.CostGUID
--     WHERE a.RefGUID = [业务GUID]
--     GROUP BY e.ExecutingBudgetGUID,
--              b.bgxs,
--              e.YGTotalPriceUL,
--              e.YGPriceUL,
--              e.BudgetName,
--              c.ProjName
-- ) a
--     LEFT JOIN
--     (
--         SELECT SUM(ISNULL(b1.BudgetAmount, 0)) AS OldBudgetAmount,
--                c1.ExecutingBudgetGUID
--         FROM dbo.cb_Contract a1
--             INNER JOIN cb_BudgetUse b1
--                 ON b1.RefGUID = a1.PreContractGUID
--             INNER JOIN cb_Budget c1
--                 ON c1.BudgetGUID = b1.BudgetGUID
--         WHERE a1.ContractGUID = [业务GUID]
--         GROUP BY c1.ExecutingBudgetGUID
--     ) b
--         ON b.ExecutingBudgetGUID = a.ExecutingBudgetGUID
--     LEFT JOIN
--     (
--         SELECT b1.ExecutingBudgetGUID,
--                SUM(ISNULL(b1.amount, 0)) AS OldBudgetAmount
--         FROM dbo.cb_Contract a1
--             INNER JOIN cb_budgetcgplanamount b1
--                 ON b1.CgPlanGUID = a1.CgPlanGUID
--         WHERE a1.ContractGUID = [业务GUID]
--         GROUP BY b1.ExecutingBudgetGUID
--     ) c
--         ON c.ExecutingBudgetGUID = a.ExecutingBudgetGUID
--     LEFT JOIN
--     (
--         SELECT a.ExecutingBudgetGUID,
--                CASE
--                    WHEN c.ExecutingBudgetGUID IS NULL THEN
--                        a.BudgetAmount
--                    ELSE
--                        ISNULL(c.BudgetAmount, 0)
--                END AS OldBudgetAmount
--         FROM dbo.cb_Budget_Executing a
--             INNER JOIN
--             (
--                 SELECT b1.ExecutingBudgetGUID
--                 FROM dbo.cb_BudgetUse a1
--                     INNER JOIN dbo.cb_Budget b1
--                         ON b1.BudgetGUID = a1.BudgetGUID
--                 WHERE a1.RefGUID = [业务GUID]
--                 GROUP BY b1.ExecutingBudgetGUID
--             ) b
--                 ON b.ExecutingBudgetGUID = a.ExecutingBudgetGUID
--             LEFT JOIN
--             (
--                 SELECT a1.ExecutingBudgetGUID,
--                        a1.BudgetAmount,
--                        ROW_NUMBER() OVER (PARTITION BY a1.ExecutingBudgetGUID ORDER BY a1.UpdateDate DESC) AS rowno
--                 FROM cb_BudgetAmountVer a1
--                     INNER JOIN
--                     (
--                         SELECT b1.ExecutingBudgetGUID
--                         FROM dbo.cb_BudgetUse a1
--                             INNER JOIN dbo.cb_Budget b1
--                                 ON b1.BudgetGUID = a1.BudgetGUID
--                         WHERE a1.RefGUID = [业务GUID]
--                         GROUP BY b1.ExecutingBudgetGUID
--                     ) b1
--                         ON b1.ExecutingBudgetGUID = a1.ExecutingBudgetGUID
--             ) c
--                 ON c.rowno = 2
--                    AND a.ExecutingBudgetGUID = c.ExecutingBudgetGUID
--     ) d
--         ON d.ExecutingBudgetGUID = a.ExecutingBudgetGUID;

-- 1、合同审批
-- 关联楼栋的产值拆分列表
SELECT 
       a.BldName AS [楼栋名称],
       a.BldArea as [建筑面积],
       a.ContractCfAmount as [合同拆分金额],
       a.ContractBxCfAmount as [补协金额],
       a.ContractYlCfAmount as [合同预留拆分金额含补协],
       a.ContractCfTotalAmount as [合同拆分总金额],
       a.ContractOutputValueCfGUID as [产值拆分明细GUID]
FROM
(
 SELECT 
       cf.ContractOutputValueCfGUID,
       cf.BldGUID,
       cf.BldName,
       cf.BldArea,
       cf.ContractCfAmountAuto,
       cf.ContractYlCfAmountAuto,
       cf.ContractCfAmount,
       cf.ContractBxCfAmount,
       cf.ContractYlCfAmount,
       cf.ContractCfTotalAmount,
       cf.FtMode,
       cf.CfRate,
       cf.CZManageModel
    FROM dbo.cb_BudgetUse a
	   INNER JOIN dbo.cb_Contract b ON b.ContractGUID = a.RefGUID
        INNER JOIN cb_ContractOutputValueCf  cf on cf.RefGUID =b.ContractGUID 
        INNER JOIN dbo.cb_Cost f ON f.CostGUID = a.CostGUID
      WHERE a.RefGUID = [业务GUID]
) a

-- 2、非合同审批
-- 关联楼栋的产值拆分列表
SELECT 
       a.BldName AS [楼栋名称],
       a.BldArea as [建筑面积],
       a.ContractCfAmount as [合同拆分金额],
       a.ContractBxCfAmount as [补协金额],
       a.ContractYlCfAmount as [合同预留拆分金额含补协],
       a.ContractCfTotalAmount as [合同拆分总金额],
       a.ContractOutputValueCfGUID as [产值拆分明细GUID]
FROM
(
 SELECT 
       cf.ContractOutputValueCfGUID,
       cf.BldGUID,
       cf.BldName,
       cf.BldArea,
       cf.ContractCfAmountAuto,
       cf.ContractYlCfAmountAuto,
       cf.ContractCfAmount,
       cf.ContractBxCfAmount,
       cf.ContractYlCfAmount,
       cf.ContractCfTotalAmount,
       cf.FtMode,
       cf.CfRate,
       cf.CZManageModel
    FROM dbo.cb_BudgetUse a
	   INNER JOIN dbo.cb_Contract b ON b.ContractGUID = a.RefGUID
        INNER JOIN cb_ContractOutputValueCf  cf on cf.RefGUID =b.ContractGUID 
        INNER JOIN dbo.cb_Cost f ON f.CostGUID = a.CostGUID
      WHERE a.RefGUID = [业务GUID]
) a
-- 3、非单独执行合同审批
-- 关联楼栋的产值拆分列表
SELECT 
       a.BldName AS [楼栋名称],
       a.BldArea as [建筑面积],
       a.ContractCfAmount as [合同拆分金额],
       a.ContractBxCfAmount as [补协金额],
       a.ContractYlCfAmount as [合同预留拆分金额含补协],
       a.ContractCfTotalAmount as [合同拆分总金额],
       a.ContractOutputValueCfGUID as [产值拆分明细GUID]
FROM
(
 SELECT 
       cf.ContractOutputValueCfGUID,
       cf.BldGUID,
       cf.BldName,
       cf.BldArea,
       cf.ContractCfAmountAuto,
       cf.ContractYlCfAmountAuto,
       cf.ContractCfAmount,
       cf.ContractBxCfAmount,
       cf.ContractYlCfAmount,
       cf.ContractCfTotalAmount,
       cf.FtMode,
       cf.CfRate,
       cf.CZManageModel
    FROM dbo.cb_BudgetUse a
	   INNER JOIN dbo.cb_Contract b ON b.ContractGUID = a.RefGUID
        INNER JOIN cb_ContractOutputValueCf  cf on cf.RefGUID =b.ContractGUID 
        INNER JOIN dbo.cb_Cost f ON f.CostGUID = a.CostGUID
      WHERE a.RefGUID = [业务GUID]
) a
-- 4、付款申请审批
-- 关联楼栋的产值拆分列表
SELECT 
       BldczcfGUID as [产值拆分明细GUID],
       BldName AS [拆分楼栋],
       JsStatus AS [建设状态], 
       BldArea AS [建筑面积],
       QyAmount AS [签约金额],
       YfsbXcljczJzsc AS [乙方申报现场累计产值(截止上次)],
       JfsdXcljczJzsc AS [甲方审定现场累计产值(截止上次)],
       LjyfkJzsc AS [累计应付款(截止上次)],
       YfsbXcljczHbc AS [乙方申报现场累计产值(含本次)],
       YfsbBccz AS [乙方申报本次产值],
       YfsbXcljqkHbc AS [乙方申报现场累计请款(含本次)],
       YfsbBcqk AS [乙方申报本次请款],
       JfshXcljczHbc AS [甲方审核现场累计产值(含本次)],
       JfshBccz AS [甲方审核本次产值],
       JfshljyfkHbc AS [甲方审核现场累计应付款(含本次)],
       JfshBcyfk AS [甲方审核本次应付款]
FROM cb_HTFKApply_Bldczcf a
    INNER JOIN cb_HTFKApply b 
        ON b.HTFKApplyGUID = a.HTFKApplyGUID
WHERE b.HTFKPlanGUID = [业务GUID]



-- select  
--        a.BudgetName AS [关联楼栋合约规划名称],
--        a.BuildingName AS [楼栋名称],
--        -- a.ExecutingBudgetGUID AS [合约GUID],
--        a.Budget2GCBldGUID as [关联楼栋GUID]
-- from (
--     select  
--             bld.Budget2GCBldGUID,
--             e.BudgetName,
--             e.ExecutingBudgetGUID,
--             bld.BldName as BuildingName
--     from  cb_HTFKApply a 
--     inner JOIN cb_Contract c ON c.ContractGUID = a.ContractGUID
-- 	inner join cb_BudgetUse budgetuse on budgetuse.RefGUID =c.ContractGUID
--     inner JOIN cb_Budget d ON d.BudgetGUID = budgetuse.BudgetGUID
--     inner JOIN cb_Budget_Executing e ON e.ExecutingBudgetGUID = d.ExecutingBudgetGUID
--     inner JOIN cb_Budget_Executing2GCBld bld on bld.BudgetGUID = e.ExecutingBudgetGUID
--     WHERE  a.HTFKPlanGUID=[业务GUID]
-- ) a


SELECT ContractOutputValueCfGUID, RefGUID, BldGUID, BldName, BldArea, 
ContractCfAmountAuto, ContractYlCfAmountAuto, ContractCfAmount, 
isnull(ContractBxCfAmount,0) ContractBxCfAmount, ContractYlCfAmount, ContractCfTotalAmount, FtMode, CfRate, CZManageModel 
FROM cb_ContractOutputValueCf WHERE (2=2) ORDER BY BldName



select  * from  cb_ContractOutputValueCf where 

select * from  cb_Contract where  contractcode ='成都保利石象湖合2024-0001'