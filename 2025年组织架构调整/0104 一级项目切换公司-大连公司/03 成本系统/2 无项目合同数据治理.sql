--针对无项目合同做数据治理

-- 查询无项目预呈批
SELECT  c.PreContractGUID,
        c.ContractCode AS 预呈批编码,
        HtClass AS 合同类型,
        ct.HtTypeName AS 预呈批类别,
        c.ContractName AS 预呈批名称,
        c.JfProviderName AS 甲方单位,
        c.YfProviderName AS 乙方单位,
        c.SignDate AS 签订日期,
        HtAmount AS 预呈批金额
FROM    cb_Contract_Pre c
        INNER JOIN myBusinessUnit bu ON c.buguid = bu.buguid
        INNER JOIN cb_HtType ct ON ct.HtTypeCode = c.HtTypeCode
                                  AND ct.BUGUID = c.BUGUID
WHERE   bu.buname = '大连公司'
        AND ISNULL(ProjectCodeList, '') = '';

--需要将公司下所有合同合并到新公司
SELECT DISTINCT  NewBuguid,NewBuname,OldBuguid,OldBuname
INTO #bu
FROM dqy_proj_20250424
  
--处理合同数据 
IF OBJECT_ID(N'cb_contract_bak_20250424_无项目合同', N'U') IS NULL
    SELECT cb.*
    INTO cb_contract_bak_20250424_无项目合同
    FROM cb_Contract cb
    INNER JOIN #bu bu ON bu.OldBuguid = cb.BUGUID
  
UPDATE cb
SET cb.BUGUID = bu.NewBuguid,
    cb.deptguid = bu.NewBuguid
FROM cb_Contract cb
INNER JOIN #bu bu ON bu.OldBuguid = cb.BUGUID

PRINT '刷新合同:cb_Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

--处理预呈批数据 
IF OBJECT_ID(N'cb_Contract_Pre_bak_20250424_无项目合同', N'U') IS NULL
    SELECT cb.*
    INTO cb_Contract_Pre_bak_20250424_无项目合同
    FROM cb_Contract_Pre cb
    INNER JOIN #bu bu ON bu.OldBuguid = cb.BUGUID 

    UPDATE cb
    SET cb.BUGUID = bu.NewBuguid,
        cb.deptguid = bu.NewBuguid
    FROM cb_Contract_Pre cb
    INNER JOIN #bu bu ON bu.OldBuguid = cb.BUGUID 
 PRINT '刷新预呈批:cb_Contract_Pre' + CONVERT(NVARCHAR(20), @@ROWCOUNT);   
 
--处理合同类别
IF OBJECT_ID(N'cb_Contract2HTType_bak_20250424_无项目合同', N'U') IS NULL
    SELECT a.*
    INTO dbo.cb_Contract2HTType_bak_20250424_无项目合同
    FROM dbo.cb_Contract2HTType a
        INNER JOIN dbo.cb_HtType c
            ON a.HtTypeGUID = c.HtTypeGUID
        INNER JOIN #bu bu ON bu.OldBuguid = c.BUGUID
    WHERE  a.ContractGUID IN (
                                    SELECT a.ContractGUID
                                    FROM cb_Contract a
                                        INNER JOIN #bu bu ON bu.NewBuguid = a.BUGUID
                                        LEFT JOIN cb_HtType b
                                            ON a.HtTypeCode = b.HtTypeCode
                                            AND a.BUGUID = b.BUGUID
                                        LEFT JOIN cb_Contract2HTType c
                                            ON a.ContractGUID = c.ContractGUID
                                    WHERE a.ContractGUID <> b.HtTypeGUID
                                        AND a.ContractGUID <> c.HtTypeGUID
                                        AND b.HtTypeGUID <> c.HtTypeGUID
                                );

    UPDATE a
    SET a.HtTypeGUID = d.HtTypeGUID,
        a.BUGUID = c.BUGUID
    FROM cb_Contract2HTType a
        INNER JOIN cb_Contract2HTType_bak_20250424_无项目合同 b
            ON a.ContractGUID = b.ContractGUID
        INNER JOIN dbo.cb_Contract c
            ON a.ContractGUID = c.ContractGUID
        INNER JOIN dbo.cb_HtType d
            ON d.BUGUID = c.BUGUID
            AND d.HtTypeCode = c.HtTypeCode;

PRINT '刷新合同类别:cb_Contract2HTType' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

--刷新json 字段
DECLARE @var_ContractGUID UNIQUEIDENTIFIER;
DECLARE @count INT;
DECLARE @i INT;
SET @i = 1;

SELECT ROW_NUMBER() OVER (ORDER BY a.ContractCode) AS num,
       a.*
INTO #cb_Contract
FROM dbo.cb_Contract a
WHERE a.ContractGUID IN (   SELECT cb.ContractGUID
                            FROM cb_contract_bak_20250424_无项目合同 cb 
                        );

--计算记录数
SELECT @count = COUNT(1)
FROM #cb_Contract;

WHILE @i <= @count
BEGIN
    SELECT @var_ContractGUID = ContractGUID
    FROM #cb_Contract
    WHERE num = @i;
    PRINT '开始刷新json，剩余：';
    PRINT @count - @i;
    PRINT @var_ContractGUID;

    --刷新json
    EXEC dbo.usp_UpdateContractBudgetJson_Ds @var_ContractGUID;

    SET @i = @i + 1;
END;

--刷新票据信息
IF OBJECT_ID(N'cb_InvoiceItem_bak_20250424_无项目合同', N'U') IS NULL
    SELECT a.*
    INTO dbo.cb_InvoiceItem_bak_20250424_无项目合同
    FROM cb_InvoiceItem a
        INNER JOIN dbo.cb_Voucher b
            ON a.RefGUID = b.VouchGUID
        inner JOIN dbo.cb_Contract c
            ON b.ContractGUID = c.ContractGUID 
    WHERE a.BUGUID <> c.BUGUID
        AND c.BUGUID IN (
                            SELECT NewBuguid FROM #bu
                        );

    UPDATE a
    SET a.BUGUID = c.BUGUID
    FROM cb_InvoiceItem a
        INNER JOIN dbo.cb_Voucher b
            ON a.RefGUID = b.VouchGUID
            inner JOIN dbo.cb_Contract c
            ON b.ContractGUID = c.ContractGUID 
    WHERE a.BUGUID <> c.BUGUID
        AND c.BUGUID IN (
                            SELECT NewBuguid FROM #bu
                        );
PRINT '票据信息:cb_InvoiceItem' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

--刷新合同变更
IF OBJECT_ID(N'cb_HTAlter_bak_20250424_无项目合同', N'U') IS NULL
    SELECT a.*
    INTO cb_HTAlter_bak_20250424_无项目合同
    FROM cb_HTAlter a
    LEFT JOIN dbo.cb_Contract b
        ON a.ContractGUID = b.ContractGUID
WHERE a.BUGUID <> b.BUGUID
      AND a.BUGUID IN (
                          SELECT OldBuguid FROM #bu
                      );
UPDATE a
SET a.BUGUID = b.BUGUID
FROM cb_HTAlter a
    LEFT JOIN dbo.cb_Contract b
        ON a.ContractGUID = b.ContractGUID
WHERE a.BUGUID <> b.BUGUID
      AND a.BUGUID IN (
                          SELECT OldBuguid FROM #bu
                      );

PRINT '合同变更:cb_HTAlter' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

--刷新合同付款申请
IF OBJECT_ID(N'cb_HTFKApply_bak_20250424_无项目合同', N'U') IS NULL
    SELECT a.*
    INTO cb_HTFKApply_bak_20250424_无项目合同
    FROM cb_HTFKApply a
        LEFT JOIN dbo.cb_Contract b
            ON a.ContractGUID = b.ContractGUID
    WHERE a.BUGUID <> b.BUGUID
        AND a.BUGUID IN (
                            SELECT OldBuguid FROM #bu
                        );

UPDATE a
SET a.BUGUID = b.BUGUID
FROM cb_HTFKApply a
    inner JOIN dbo.cb_Contract b
        ON a.ContractGUID = b.ContractGUID
WHERE a.BUGUID <> b.BUGUID
      AND a.BUGUID IN (
                          SELECT OldBuguid FROM #bu
                      );

PRINT '合同付款申请:cb_HTFKApply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

--刷新合同付款计划
IF OBJECT_ID(N'cb_HTFKPlan_bak_20250424_无项目合同', N'U') IS NULL
    SELECT a.*
    INTO cb_HTFKPlan_bak_20250424_无项目合同
    FROM cb_HTFKPlan a
        inner JOIN dbo.cb_Contract b
            ON a.ContractGUID = b.ContractGUID
    WHERE a.BUGUID <> b.BUGUID
        AND a.BUGUID IN (
                            SELECT OldBuguid FROM #bu
                        );

UPDATE a
SET a.BUGUID = b.BUGUID
FROM cb_HTFKPlan a
    inner JOIN dbo.cb_Contract b
        ON a.ContractGUID = b.ContractGUID
WHERE a.BUGUID <> b.BUGUID
      AND a.BUGUID IN (
                          SELECT OldBuguid FROM #bu
                      );

PRINT '合同付款计划:cb_HTFKPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
--刷新应收明细
IF OBJECT_ID(N'cb_payfeebill_bak_20250424_无项目合同', N'U') IS NULL
    SELECT bil.*
    INTO cb_payfeebill_bak_20250424_无项目合同
    FROM cb_Contract con 
    INNER JOIN cb_PayFeeBill bil
        ON bil.ContractGUID = con.ContractGUID
WHERE con.BUGUID <> bil.BUGUID
      AND con.BUGUID IN (
                            SELECT newbuguid FROM #bu
                        );

UPDATE bil
SET bil.BUGUID = con.BUGUID
FROM cb_Contract con 
    INNER JOIN cb_PayFeeBill bil
        ON bil.ContractGUID = con.ContractGUID
WHERE con.BUGUID <> bil.BUGUID
      AND con.BUGUID IN (
                            SELECT newbuguid FROM #bu
                        );

PRINT '应收明细:cb_payfeebill' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 
