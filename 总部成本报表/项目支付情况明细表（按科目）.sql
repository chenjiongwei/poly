USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_ShowProjListPayDtlByCostRpt]    Script Date: 2024/12/26 17:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER  PROC [dbo].[usp_cb_ShowProjListPayDtlByCostRpt] ( @ProjGUIDs VARCHAR(MAX))
/*
创建：chenjw add 20210421
功能：《项目支付情况明细表（按科目）》报表数据源
[usp_cb_ShowProjListPayDtlByCostRpt]
示例：[usp_cb_ShowProjListPayDtlByCostRpt] 'DB3664F7-6D74-E811-80BF-E61F13C57837,CD02731D-F46A-E911-80B7-0A94EF7517DD,55CE17A8-4284-E911-80B7-0A94EF7517DD,F93F5607-F20C-4057-8905-1303F1E892CF';
*/
AS
BEGIN
    DECLARE @CurrMonth VARCHAR(7);
    DECLARE @ProjCode VARCHAR(400);
    DECLARE @MaxCostLevel TINYINT;

    SET @CurrMonth = CONVERT(VARCHAR(7), GETDATE(), 120);

    SELECT ProjCode ,
           ProjGUID ,
           ProjName
    INTO   #p
    FROM   p_Project
    WHERE  ProjGUID IN ( SELECT [Value] FROM dbo.fn_Split2(@ProjGUIDs, ',') );

    --1.1建立项目的临时表    
    CREATE TABLE #MainData
    (   ProjCode VARCHAR(200) ,
        RefGUID UNIQUEIDENTIFIER ,
        CostCode VARCHAR(100) ,
        ParentCostCode VARCHAR(100) ,
        OrderCode VARCHAR(550) ,
        CostShortName VARCHAR(40) ,
        ifendcost int, -- 是否末级科目
        ContractName VARCHAR(200) ,
        YfProviderName VARCHAR(100) ,
        ContractCode VARCHAR(400) ,
        CostLevel TINYINT ,
        IsRef BIT ,
        TargetCost DECIMAL(27, 6) ,
        HtAmount_CurrMonth DECIMAL(27, 6) ,
        HtAmount DECIMAL(27, 6) ,
        FactSchedule_CurrMonth DECIMAL(27, 6) ,
        FactSchedule DECIMAL(27, 6) ,
        ApplyAmount_CurrMonth DECIMAL(27, 6) ,
        ApplyAmount DECIMAL(27, 6) ,
        PayAmount_CurrMonth DECIMAL(27, 6) ,
        PayAmount DECIMAL(27, 6) ,
        FactRate DECIMAL(27, 6) ,
        PayRate DECIMAL(27, 6)
     );

    --1.2插入数据    
    INSERT INTO #MainData ( ProjCode ,
                            RefGUID ,
                            CostCode ,
                            ParentCostCode ,
                            OrderCode ,
                            CostShortName ,
                            ifendcost,
                            ContractName ,
                            YfProviderName ,
                            ContractCode ,
                            CostLevel ,
                            IsRef ,
                            TargetCost ,
                            HtAmount_CurrMonth ,
                            HtAmount ,
                            FactSchedule_CurrMonth ,
                            FactSchedule ,
                            ApplyAmount_CurrMonth ,
                            ApplyAmount ,
                            PayAmount_CurrMonth ,
                            PayAmount ,
                            FactRate ,
                            PayRate )
                SELECT c.ProjectCode ,
                       CostGUID AS RefGUID ,
                       c.CostCode ,
                       ParentCode ,
                       c.CostCode AS OrderCode ,
                       c.CostShortName ,
                       c.ifendcost,
                       '' ,
                       '' ,
                       '' ,
                       c.CostLevel ,
                       0 ,
                       TargetCost + ISNULL(AdjustCost, 0) ,
                       0 ,
                       0 ,
                       0 ,
                       0 ,
                       0 ,
                       0 ,
                       0 ,
                       0 ,
                       0 ,
                       0
                FROM   cb_Cost c
                WHERE  c.ProjectCode IN ( SELECT #p.ProjCode FROM #p );

    --若拆分明细中没有数据，则只返回科目基础结构    
    IF NOT EXISTS ( SELECT 1 FROM cb_CfDtl WHERE ProjectCode IN ( SELECT #p.ProjCode FROM #p ))
    BEGIN

        SELECT ProjCode ,
               RefGUID ,
               CostCode ,
               ParentCostCode ,
               OrderCode ,
               CostShortName ,
               ifendcost,
               ContractName ,
               YfProviderName ,
               ContractCode ,
               CostLevel ,
               IsRef ,
               TargetCost ,
               HtAmount_CurrMonth ,
               HtAmount ,
               FactSchedule_CurrMonth ,
               FactSchedule ,
               ApplyAmount_CurrMonth ,
               ApplyAmount ,
               PayAmount_CurrMonth ,
               PayAmount ,
               0 AS FactRate ,
               0 AS PayRate
        FROM   #MainData;

        DROP TABLE #MainData;

        RETURN;
    END;

    --2.2建立付款申请使用的临时表,存放付款申请科目分摊数据    
    CREATE TABLE #FkApply
    (   ContractGUID UNIQUEIDENTIFIER ,
        HTFKApplyGUID UNIQUEIDENTIFIER ,
        ApplyDate DATETIME ,
        ApplyAmount MONEY ,
        FtAmount MONEY ,
        ProjectCode VARCHAR(200) ,
        CostCode VARCHAR(200));

    --1.3获取付款申请数据    
    INSERT #FkApply EXEC usp_cb_getFkApplyCostFt @ProjGUIDs;

    --项目的各科目下业务发生情况(不包含付款申请业务)    
    INSERT INTO #MainData ( ProjCode ,
                            RefGUID ,
                            CostCode ,
                            ParentCostCode ,
                            OrderCode ,
                            CostShortName ,
                            ifendcost,
                            ContractName ,
                            YfProviderName ,
                            ContractCode ,
                            CostLevel ,
                            IsRef ,
                            TargetCost ,
                            HtAmount_CurrMonth ,
                            HtAmount ,
                            FactSchedule_CurrMonth ,
                            FactSchedule ,
                            ApplyAmount_CurrMonth ,
                            ApplyAmount ,
                            PayAmount_CurrMonth ,
                            PayAmount ,
                            FactRate ,
                            PayRate )
                SELECT ProjectCode ,
                       RefGUID ,
                       '' ,
                       CostCode ,
                       CostCode + '.' + ContractCode AS OrderCode ,
                       '' ,
                       null as ifendcost,
                       ContractName ,
                       YfProviderName ,
                       ContractCode ,
                       0 ,
                       1 ,
                       0 ,
                       HtAmount_CurrMonth ,
                       HtAmount ,
                       FactSchedule_CurrMonth ,
                       FactSchedule ,
                       ApplyAmount_CurrMonth ,
                       ApplyAmount ,
                       PayAmount_CurrMonth ,
                       PayAmount ,
                       0 ,
                       0
                FROM
                       (   SELECT    ProjectCode ,
                                     CostCode ,
                                     ISNULL(c.ContractGUID, so.StockOutGUID) AS RefGUID ,
                                     ISNULL(c.ContractName, so.StockOutName) AS ContractName ,
                                     ISNULL(c.ContractCode, '--') AS ContractCode ,
                                     ISNULL(c.YfProviderName, '--') AS YfProviderName ,
                                     --本月合同+变更    
                                     SUM(CASE WHEN cf.CfTypeCode IN ( '10', '20', '30' )
                                                   AND CONVERT(VARCHAR(7), c.SignDate, 120) = @CurrMonth THEN cf.CfAmount
                                              WHEN cf.CfTypeCode IN ( '11', '12', '13', '14', '21', '22', '23', '24' )
                                                   AND CONVERT(VARCHAR(7), al.ApplyDate, 120) = @CurrMonth THEN cf.CfAmount
                                              WHEN cf.CfTypeCode = '41'
                                                   AND CONVERT(VARCHAR(7), so.HappenTime, 120) = @CurrMonth THEN cf.CfAmount
                                              ELSE 0.00
                                         END) AS HtAmount_CurrMonth ,
                                     --累计合同+变更    
                                     SUM(CASE WHEN cf.CfTypeCode < '42' THEN cf.CfAmount ELSE 0.00 END) AS HtAmount ,
                                     --本月实际值    
                                     SUM(CASE WHEN cf.CfTypeCode = '80'
                                                   AND CONVERT(VARCHAR(7), fk.ApplyDate, 120) = @CurrMonth THEN cf.CfAmount
                                              WHEN cf.CfTypeCode = '41'
                                                   AND CONVERT(VARCHAR(7), so.HappenTime, 120) = @CurrMonth THEN cf.CfAmount
                                              WHEN cf.CfTypeCode = '80'
                                                   AND CONVERT(VARCHAR(7), s.ApplyDate, 120) = @CurrMonth THEN cf.CfAmount
                                              ELSE 0.00
                                         END) AS FactSchedule_CurrMonth ,
                                     --累计实际值     
                                     SUM(CASE WHEN cf.CfTypeCode = '80' OR cf.CfTypeCode = '41' THEN cf.CfAmount ELSE 0.00 END) AS FactSchedule ,
                                     --本月实付值    
                                     SUM(CASE WHEN cf.CfTypeCode = '90'
                                                   AND CONVERT(VARCHAR(7), pay.KpDate, 120) = @CurrMonth THEN cf.CfAmount
                                              WHEN cf.CfTypeCode = '41'
                                                   AND CONVERT(VARCHAR(7), so.HappenTime, 120) = @CurrMonth THEN cf.CfAmount
                                              ELSE 0.00
                                         END) AS PayAmount_CurrMonth ,
                                     --累计实付值    
                                     SUM(CASE WHEN cf.CfTypeCode = '90' OR cf.CfTypeCode = '41' THEN cf.CfAmount ELSE 0.00 END) AS PayAmount ,
                                     --本月付款申请值，只包含库存结转，没有包含付款申请    
                                     SUM(CASE WHEN cf.CfTypeCode = '41'
                                                   AND CONVERT(VARCHAR(7), so.HappenTime, 120) = @CurrMonth THEN cf.CfAmount
                                              ELSE 0.00
                                         END) AS ApplyAmount_CurrMonth ,
                                     --累计付款申请值，只包含库存结转，没有包含付款申请    
                                     SUM(CASE WHEN cf.CfTypeCode = '41' THEN cf.CfAmount ELSE 0.00 END) AS ApplyAmount
                           FROM      cb_CfDtl cf
                                     LEFT JOIN cb_Contract c ON cf.ContractGUID = c.ContractGUID
                                     LEFT JOIN cb_StockOut so ON cf.RefGUID = so.StockOutGUID
                                                                 AND CfTypeCode = '41'
                                     LEFT JOIN
                                     (   SELECT HTAlterGUID ,
                                                CASE WHEN QrApproveState = '已审核' THEN ApproveDate
                                                     WHEN QrApproveState <> '已审核'
                                                          AND ApproveState = '已审核' THEN AlterDate
                                                     ELSE ApplyDate
                                                END AS ApplyDate
                                         FROM   cb_HTAlter ) al ON al.HTAlterGUID = cf.RefGUID
                                                                   AND cf.RefType = '变更'
                                     LEFT JOIN cb_HTFKApply fk ON fk.HTFKApplyGUID = cf.RefGUID
                                                                  AND cf.CfTypeCode = '80'
                                     LEFT JOIN
                                     (   SELECT HTScheduleGUID ,
                                                CASE WHEN ApproveState = '已审核' THEN ApproveDate ELSE ApplyDate END AS ApplyDate
                                         FROM   cb_HTSchedule ) s ON s.HTScheduleGUID = cf.RefGUID
                                                                     AND cf.CfTypeCode = '80'
                                     LEFT JOIN ( SELECT PayGUID, KpDate FROM cb_Pay INNER JOIN cb_Voucher ON cb_Pay.VouchGUID = cb_Voucher.VouchGUID ) pay ON cf.RefGUID = pay.PayGUID
                                                                                                                                                              AND cf.CfTypeCode = '90'
                           WHERE     (   c.ContractGUID IS NOT NULL
                                         OR  so.StockOutGUID IS NOT NULL
                                         OR  al.HTAlterGUID IS NOT NULL
                                         OR  s.HTScheduleGUID IS NOT NULL
                                         OR  fk.HTFKApplyGUID IS NOT NULL
                                         OR  pay.PayGUID IS NOT NULL )
                                     AND cf.ProjectCode IN ( SELECT ProjCode FROM #p )
                           GROUP  BY ProjectCode ,
                                     CostCode ,
                                     c.ContractGUID ,
                                     StockOutGUID ,
                                     c.ContractName ,
                                     StockOutName ,
                                     YfProviderName ,
                                     ContractCode ) a;


    --更新付款申请业务    
    UPDATE a
    SET    a.ApplyAmount_CurrMonth = a.ApplyAmount_CurrMonth + fk.mon ,
           a.ApplyAmount = a.ApplyAmount + fk.Lj
    FROM   #MainData a
           INNER JOIN
           (   SELECT   SUM(FtAmount) AS Lj ,
                        SUM(CASE WHEN CONVERT(VARCHAR(7), ApplyDate, 120) = @CurrMonth THEN FtAmount ELSE 0.00 END) AS mon ,
                        CostCode ,
                        ProjectCode ,
                        ContractGUID
               FROM     #FkApply
               GROUP BY ProjectCode ,
                        CostCode ,
                        ContractGUID ) fk ON a.RefGUID = fk.ContractGUID
                                             AND a.ProjCode = fk.ProjectCode
                                             AND CHARINDEX(fk.CostCode + '.', a.OrderCode + '.', 0) > 0
                                             AND fk.ProjectCode IN ( SELECT ProjCode FROM #p );


    --更新业务数据的层级    
    UPDATE a
    SET    a.CostLevel = c.CostLevel + 1
    FROM   #MainData a
           INNER JOIN cb_Cost c ON a.ParentCostCode = c.CostCode
                                   AND a.ProjCode = c.ProjectCode
                                   AND a.CostCode = '';


    --获取最大科目层级    
    SELECT @MaxCostLevel = MAX(CostLevel)FROM #MainData;

    WHILE @MaxCostLevel > 1
    BEGIN
        UPDATE a
        SET    HtAmount_CurrMonth = a.HtAmount_CurrMonth + b.HtAmount_CurrMonth ,
               HtAmount = a.HtAmount + b.HtAmount ,
               FactSchedule_CurrMonth = a.FactSchedule_CurrMonth + b.FactSchedule_CurrMonth ,
               FactSchedule = a.FactSchedule + b.FactSchedule ,
               ApplyAmount_CurrMonth = a.ApplyAmount_CurrMonth + b.ApplyAmount_CurrMonth ,
               ApplyAmount = a.ApplyAmount + b.ApplyAmount ,
               PayAmount_CurrMonth = a.PayAmount_CurrMonth + b.PayAmount_CurrMonth ,
               PayAmount = a.PayAmount + b.PayAmount
        FROM   #MainData a
               INNER JOIN
               (   SELECT   ProjCode ,
                            ParentCostCode ,
                            SUM(HtAmount_CurrMonth) HtAmount_CurrMonth ,
                            SUM(HtAmount) HtAmount ,
                            SUM(FactSchedule_CurrMonth) FactSchedule_CurrMonth ,
                            SUM(FactSchedule) FactSchedule ,
                            SUM(ApplyAmount_CurrMonth) ApplyAmount_CurrMonth ,
                            SUM(ApplyAmount) ApplyAmount ,
                            SUM(PayAmount_CurrMonth) PayAmount_CurrMonth ,
                            SUM(PayAmount) PayAmount
                   FROM     #MainData
                   WHERE    CostLevel = @MaxCostLevel
                   GROUP BY ProjCode ,
                            ParentCostCode ) b ON a.CostCode = b.ParentCostCode
                                                  AND a.ProjCode = b.ProjCode
        WHERE  a.CostLevel = @MaxCostLevel - 1;


        SET @MaxCostLevel = @MaxCostLevel - 1;
    END;


    SELECT   a.ProjCode ,
             p.ProjGUID ,
             p.ProjName ,
             NEWID() AS RefGUID ,
             a.CostCode ,
             --ParentCostCode,    
             a.OrderCode ,
             a.IsRef ,
             a.CostShortName ,
             case when  a.ifendcost =1 then '是' 
                  when  a.ifendcost =0 then '否' end as ifendcost,
             a.ContractName ,
             a.YfProviderName ,
             a.ContractCode ,
             a.TargetCost ,
             a.HtAmount_CurrMonth ,
             a.HtAmount ,
             a.FactSchedule_CurrMonth ,
             a.FactSchedule ,
             a.ApplyAmount_CurrMonth ,
             a.ApplyAmount ,
             a.PayAmount_CurrMonth ,
             a.PayAmount ,
             CASE WHEN TargetCost = 0 THEN 0.00 ELSE CAST(( FactSchedule / TargetCost ) * 100.00 AS MONEY)END AS FactRate ,
             CASE WHEN TargetCost = 0 THEN 0.00 ELSE CAST(( PayAmount / TargetCost ) * 100.00 AS MONEY)END AS PayRate
    FROM     #MainData a
             LEFT JOIN #p p ON a.ProjCode = p.ProjCode
    ORDER BY a.ProjCode,OrderCode;

    DROP TABLE #MainData;
    DROP TABLE #FkApply;
    DROP TABLE #p;
END;