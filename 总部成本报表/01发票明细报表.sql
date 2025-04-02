-- 查询发票明细报表
-- 基于所属系统筛选对应的票据数据
-- DECLARE @var_sysName VARCHAR(100) -- 业务系统名称


-- INSERT INTO [dbo].[myKeyword]
--            ([KeywordGUID]
--            ,[KeywordName]
--            ,[KeywordType]
--            ,[Purpose]
--            ,[Syntax]
--            ,[SyntaxType]
--            ,[AppScope]
--            ,[AppScopeText]
--            ,[ReturnValueType]
--            ,[Comments]
--            ,[AssistantKeyword]
--            ,[IsOnlyReturnEndData])
--      VALUES
--            (  newid() 
--            ,'[所属系统]'
--            ,'用户' 
--            ,'辅助录入'
--            ,'select   ''成本系统'' as 所属系统 union select   ''费用系统'' as 所属系统'
--            ,'Select'
--            ,'[ALL]'
--            ,'所有系统'
--            ,'文本'
--            ,null
--            ,null
--            ,0)
-- GO

--发票明细报表
WITH #invoice AS (
    SELECT 
        '成本系统' AS '所属系统',
        a.ContractName AS '合同名称',
        a.ContractCode AS '合同编号',
        a.yfProviderName AS '乙方单位',
        b.InvoiceCode AS '发票代码',
        b.InvoNo AS '票据编号',
        b.InvoiceDate AS '开票日期',
        b.InvoiceAmount AS '发票金额'
    FROM 
        cb_contract a
        LEFT JOIN cb_invoiceitem b ON a.ContractGUID = b.ContractGUID
    WHERE 
        (1 = 1)
        AND a.isfycontrol = 0
        AND b.InvoiceCode IS NOT NULL
        AND a.BUGUID IN (@var_buguid) 
    UNION
    --成本系统
    SELECT 
        '成本系统' AS '所属系统',
        ht.ContractName AS '合同名称',
        ht.ContractCode AS '合同编号',
        ht.yfProviderName AS '乙方单位',
        a.InvoiceCode AS '发票代码',
        a.InvoiceNo AS '票据编号',
        a.KpDate AS '开票日期',
        a.TotalAmount AS '发票金额'
    FROM 
        cb_PayConfirmSheet_Invoice a
        LEFT JOIN dbo.myBusinessUnit b ON b.BUGUID = a.BUGUID
        LEFT JOIN 
        (
            SELECT 
                COUNT(1) AS RowNum,
                InvoiceGUID
            FROM 
                cb_PayConfirmSheet_InvoiceRef a
                INNER JOIN cb_PayConfirmSheet b ON a.PayConfirmSheetGUID = b.PayConfirmSheetGUID
            WHERE 
                a.PayConfirmSheetGUID IS NOT NULL
            GROUP BY 
                InvoiceGUID
        ) c ON c.InvoiceGUID = a.InvoiceGUID
        LEFT JOIN 
        (
            SELECT 
                (
                    SELECT ApplyCode + ';'
                    FROM vcb_PayConfirmSheet_InvoiceRef
                    WHERE InvoiceGUID = ref.InvoiceGUID
                    FOR XML PATH('')
                ) AS ApplyCode,
                InvoiceGUID,
                ContractGUID
            FROM 
                vcb_PayConfirmSheet_InvoiceRef ref
            WHERE 
                ref.ContractGUID IS NOT NULL
            GROUP BY 
                InvoiceGUID,
                ContractGUID
        ) d ON a.InvoiceGUID = d.InvoiceGUID
        INNER JOIN 
            dbo.cb_Contract ht ON d.ContractGUID = ht.ContractGUID
    WHERE 
        (1 = 1)
        AND ht.isfycontrol = 0
        AND ht.BUGUID IN (@var_buguid)
    UNION 
    --费用系统
    SELECT 
        '费用系统' AS '所属系统',
        c.ContractName AS '合同名称',
        c.ContractCode AS '合同编号',
        c.yfProviderName AS '乙方单位',
        a.InvoiceCode AS '发票代码',
        a.InvoiceNo AS '票据编号',
        a.paperDrewDate AS '开票日期',
        a.amountWithTax AS '发票金额'
    FROM 
        fy_Invoice a
        INNER JOIN cb_HTFKApply b ON a.SourceGUID = b.HTFKApplyGUID
        INNER JOIN cb_Contract c ON b.ContractGUID = c.ContractGUID
        LEFT JOIN dbo.myBusinessUnit e ON b.BUGUID = e.BUGUID
    WHERE 1=1  AND   c.isfycontrol = 1
        AND  b.ApplyState = '已审核'
        AND b.BUGUID IN (@var_buguid)
) 

-- 查询结果
SELECT 
    所属系统,
    合同名称,
    合同编号,
    乙方单位,
    发票代码,
    票据编号,
    开票日期,
    发票金额
FROM 
    #invoice
WHERE 
    所属系统 IN ( @var_sysName)