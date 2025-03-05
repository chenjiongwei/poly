-- 巡检合同、补协、非合同、变更、签证，完工、结算
-- 1.合同及单独执行的补充协议 拆分金额同合约规划金额不一致
SELECT 
       c.BUName AS [公司名称],
       a.ContractName AS [合同名称],
       a.ContractCode AS [合同编号],
       a.HtAmount AS [合同有效签约金额],
       b.CfAmount AS [合约规划拆分金额],
       a.UseCostInfo AS [合同合约规划字段]
FROM dbo.cb_Contract a
    LEFT JOIN
    (
        SELECT SUM(ISNULL(b1.CfAmount, 0)) AS CfAmount,
               a1.ContractGUID
        FROM dbo.cb_Contract a1
        INNER JOIN dbo.cb_BudgetUse b1 ON b1.RefGUID = a1.ContractGUID  AND a1.IfDdhs = 1
        -- where  b1.CfSource ='合同'
        GROUP BY a1.ContractGUID
    ) b ON b.ContractGUID = a.ContractGUID
    INNER JOIN myBusinessUnit c  ON c.BUGUID = a.BUGUID
WHERE HtClass = '已定合同' 
      AND ISNULL(b.CfAmount, 0) <> ISNULL(a.HtAmount, 0)
      AND a.IsFyControl = 0
      AND a.IfDdhs = 1
      AND ISNULL(a.UseCostInfo, '') <> ''
--and a.ContractName = '佛山市保利清能和悦花园项目二标地下土建及水电安装工程合同'
ORDER BY c.BUGUID DESC;

-- 2、非合同拆分金额同合约规划不一致
SELECT c.BUName AS [公司名称],
       a.ContractName AS [非合同名称], 
       a.ContractCode AS [非合同编号],
       a.HtAmount AS [非合同有效签约金额],
       b.CfAmount AS [合约规划拆分金额],
       a.UseCostInfo AS [非合同合约规划字段]
FROM dbo.cb_Contract a
    LEFT JOIN (
        SELECT SUM(ISNULL(b1.CfAmount, 0)) AS CfAmount,
               a1.ContractGUID 
        FROM dbo.cb_Contract a1
        INNER JOIN dbo.cb_BudgetUse b1  ON b1.RefGUID = a1.ContractGUID AND a1.IfDdhs = 1
        -- where  b1.CfSource ='非合同'
        GROUP BY a1.ContractGUID
    ) b ON b.ContractGUID = a.ContractGUID
    INNER JOIN myBusinessUnit c ON c.BUGUID = a.BUGUID
WHERE HtClass = '已定非合同'
      AND ISNULL(b.CfAmount, 0) <> ISNULL(a.HtAmount, 0)
      AND a.IsFyControl = 0 
      AND a.IfDdhs = 1
      AND ISNULL(a.UseCostInfo, '') <> ''
ORDER BY c.BUGUID DESC;

-- 3、非单独执行的补充协议拆分金额同合约规划不一致
SELECT c.BUName AS [公司名称],
       a.ContractName AS [补充协议名称], 
       a.ContractCode AS [补充协议编号],
       a.HtAmount AS [补充协议有效签约金额],
       b.CfAmount AS [合约规划拆分金额],
       a.UseCostInfo AS [合约规划字段]
FROM dbo.cb_Contract a
    LEFT JOIN (
        SELECT SUM(ISNULL(b1.CfAmount, 0)) AS CfAmount,
               a1.RefGUID as ContractGUID
        FROM dbo.cb_HTAlter a1 
        INNER JOIN dbo.cb_BudgetUse b1  ON b1.RefGUID = a1.HTAlterGUID   
		where  a1.AlterType ='附属合同' 
        GROUP BY a1.RefGUID
    ) b ON b.ContractGUID = a.ContractGUID
    INNER JOIN myBusinessUnit c ON c.BUGUID = a.BUGUID
WHERE ISNULL(b.CfAmount, 0) <> ISNULL(a.HtAmount, 0)
      AND a.IsFyControl = 0 and  ISNULL(a.IfDdhs, 0) = 0
        AND ISNULL(a.UseCostInfo, '') <> ''
ORDER BY c.BUGUID DESC;

-- 4、变更拆分金额同合约规划不一致
SELECT c.BUName AS [公司名称],
       a.AlterName AS [变更名称],
       a.AlterCode AS [变更编号], 
       a.AlterAmount AS [变更金额],
       b.CfAmount AS [合约规划拆分金额],
       a.UseCostInfo AS [合约规划字段]
FROM dbo.cb_HTAlter a
    LEFT JOIN (
        SELECT SUM(ISNULL(b1.CfAmount, 0)) AS CfAmount,
               a1.HTAlterGUID
        FROM dbo.cb_HTAlter a1
        INNER JOIN dbo.cb_BudgetUse b1 ON b1.RefGUID = a1.HTAlterGUID
        WHERE a1.AlterType NOT IN ('附属合同', '结算', '结算调整') 
              AND ISNULL(a1.IsQR, 0) = 0
        GROUP BY a1.HTAlterGUID
    ) b ON b.HTAlterGUID = a.HTAlterGUID
    INNER JOIN myBusinessUnit c ON c.BUGUID = a.BUGUID
WHERE ISNULL(b.CfAmount, 0) <> ISNULL(a.AlterAmount, 0)
      AND ISNULL(a.IsQR, 0) = 0
	  and a.ApproveState ='已审核'
      AND a.AlterType NOT IN ('附属合同', '结算', '结算调整')
      AND ISNULL(a.UseCostInfo, '') <> ''
ORDER BY c.BUGUID DESC;

-- 5、完工拆分金额同合约规划不一致
SELECT c.BUName AS [公司名称],
       a.AlterName AS [完工变更名称], 
       a.AlterCode AS [完工变更编号],
       a.QrAlterAmount AS [完工变更确认金额],
       b.CfAmount AS [合约规划拆分金额],
       a.UseCostInfo AS [合约规划字段]
FROM dbo.cb_HTAlter a
    LEFT JOIN (
        SELECT SUM(ISNULL(b1.CfAmount, 0)) AS CfAmount,
               a1.HTAlterGUID 
        FROM dbo.cb_HTAlter a1 
        INNER JOIN dbo.cb_BudgetUse b1  ON b1.RefGUID = a1.HTAlterGUID   
		where  a1.AlterType not in ('附属合同','结算','结算调整') and isnull(a1.IsQR,0) =1
        GROUP BY a1.HTAlterGUID
    ) b ON b.HTAlterGUID = a.HTAlterGUID
    INNER JOIN myBusinessUnit c ON c.BUGUID = a.BUGUID
WHERE ISNULL(b.CfAmount, 0) <> ISNULL(a.QrAlterAmount, 0)
      and isnull(a.IsQR,0) =1
      and a.QrApproveState ='已审核'
      and  a.AlterType not in ('附属合同','结算','结算调整')
        AND ISNULL(a.UseCostInfo, '') <> ''
ORDER BY c.BUGUID DESC;

-- 6、结算拆分金额同合约规划不一致
SELECT c.BUName AS [公司名称],
       con.ContractName AS [合同名称], 
       a.JsdCode AS [合同结算编号],
       a.BalanceAmount AS [合同结算金额],
       b.JsAmount AS [合约规划结算金额],
       a.UseCostInfo AS [合约规划字段]
FROM dbo.cb_HTBalance a
    inner join cb_Contract con  on con.ContractGUID =a.ContractGUID
    LEFT JOIN (
        SELECT SUM(ISNULL(b1.JsAmount, 0)) AS JsAmount,
               a1.HTBalanceGUID 
        FROM dbo.cb_HTBalance a1 
        INNER JOIN dbo.cb_BudgetUse b1  ON b1.HTBalanceGUID = a1.HTBalanceGUID  
        GROUP BY a1.HTBalanceGUID
    ) b ON b.HTBalanceGUID = a.HTBalanceGUID
    INNER JOIN myBusinessUnit c ON c.BUGUID = con.BUGUID
WHERE ISNULL(b.JsAmount, 0) <> ISNULL(a.BalanceAmount, 0)
        AND ISNULL(a.UseCostInfo, '') <> ''
ORDER BY c.BUGUID DESC;
