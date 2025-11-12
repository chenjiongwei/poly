/*
当前系统内费用合同
所属分期：郑州杓袁项目-杓袁7号地
合同大类：佣金类
合约库合约名称：销售代理、数字营销、全民营销、第三方分销、老带新

合同名称、合同GUID、合同编号
*/

SELECT 
    p.ProjName            AS [所属项目],
    con.ContractName      AS [合同名称],
    con.ContractGUID      AS [合同GUID],
    con.ContractCode      AS [合同编号],
    con.HtGenera          AS [合同大类],
    con.BudgetLibraryName AS [合约库合约名称]
FROM 
    vcb_ContractGrid con
    INNER JOIN cb_contractproj proj ON con.ContractGUID = proj.ContractGUID
    INNER JOIN p_project p ON p.ProjGUID = proj.ProjGUID
WHERE 
    con.IsFyControl = 1
    AND proj.ProjGUID = '0e63e1ad-4703-4a95-b661-9e8e415e041f'   -- 杓袁7号地
    AND con.HtGenera = '佣金类'
    AND con.BudgetLibraryName IN (
        '销售代理',
        '数字营销',
        '全民营销',
        '第三方分销',
        '老带新'
    )









