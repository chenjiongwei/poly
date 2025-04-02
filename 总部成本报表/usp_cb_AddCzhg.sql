USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_AddCzhg]    Script Date: 2025/3/20 14:22:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*****************************************************
* 存储过程名称: usp_cb_AddCzhg
* 功能描述: 添加产值回顾数据
* 参数说明:
*   @ProjGUID - 项目GUID
*   @OutputValueMonthReviewGUID - 产值月度回顾GUID
*   @IsInit - 是否初始化标志
* 创建日期: 2025/3/20
******************************************************/
ALTER PROC [dbo].[usp_cb_AddCzhg]
(
    @ProjGUID UNIQUEIDENTIFIER,                  -- 项目GUID
    @OutputValueMonthReviewGUID UNIQUEIDENTIFIER, -- 产值月度回顾GUID
    @IsInit BIT                                  -- 是否初始化标志
)
AS

-- 获取工程楼栋信息到临时表
SELECT BldGUID,
       SumBuildArea,
       BldName,
       ProjGUID,
       VersionGUID,
       CurVersion,
       IsActive
INTO #GCbuildTemp
FROM dbo.md_GCBuild
WHERE ProjGUID = @ProjGUID;

-- 插入工程楼栋信息
SELECT a.BldGUID,
       a.SumBuildArea,
       a.BldName,
       a.ProjGUID
INTO #GCbuild
FROM
(
    -- 获取预售查丈版和竣工验收版的楼栋信息
    SELECT ISNULL(p.ProjName, '') + '-' + ISNULL(gc.BldName, '') AS BldName,
           gc.BldName AS ShortBldName,
           gc.SumBuildArea,
           gc.BldGUID,
           gc.ProjGUID
    FROM #GCbuildTemp gc
        LEFT JOIN
        (
            -- 获取最新的项目信息
            SELECT *
            FROM
            (
                SELECT a1.*,
                       ROW_NUMBER() OVER (PARTITION BY a1.ProjGUID ORDER BY a1.CreateDate DESC) AS rowno
                FROM dbo.md_Project a1
                    INNER JOIN #GCbuildTemp b1
                        ON b1.ProjGUID = a1.ProjGUID
            ) t
            WHERE t.rowno = 1
        ) p
            ON gc.ProjGUID = p.ProjGUID
    WHERE gc.CurVersion IN ( '预售查丈版', '竣工验收版' )
          AND gc.IsActive = 1
          AND gc.ProjGUID = @ProjGUID
    
    UNION
    
    -- 获取其他版本的楼栋信息
    SELECT ISNULL(t.ProjName, '') + '-' + ISNULL(t.BldName, '') AS BldName,
           t.BldName AS ShortBldName,
           ISNULL(t.SumBuildArea, 0) AS SumBuildArea,
           t.BldGUID,
           t.ProjGUID
    FROM
    (
        SELECT p.ProjName,
               gc.*
        FROM md_GCBuild gc
            INNER JOIN
            (
                -- 获取最新的已审核项目信息
                SELECT *
                FROM
                (
                    SELECT ROW_NUMBER() OVER (PARTITION BY a1.ProjGUID ORDER BY a1.CreateDate DESC) AS rowmo,
                           a1.*
                    FROM dbo.md_Project a1
                        INNER JOIN #GCbuildTemp
                            ON #GCbuildTemp.VersionGUID = a1.VersionGUID
                    WHERE a1.ApproveState = '已审核'
                          AND ISNULL(a1.CreateReason, '') <> '补录'
                          AND a1.CurVersion IN ( '立项版', '定位版', '修详规版', '建规证版' )
                ) x
                WHERE x.rowmo = 1
            ) p
                ON p.VersionGUID = gc.VersionGUID
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.md_GCBuild
            WHERE CurVersion IN ( '预售查丈版', '竣工验收版' )
                  AND md_GCBuild.IsActive = 1
                  AND md_GCBuild.BldGUID = gc.BldGUID
        )
              AND gc.ProjGUID = @ProjGUID
    ) t
) a;

-- 创建索引以提高查询性能
CREATE NONCLUSTERED INDEX idx_OutputValueReviewDetailGUID
ON #GCbuild (
                BldGUID,
                ProjGUID
            )
INCLUDE (
            BldName,
            SumBuildArea
        );



--取已审核拍照数据
SELECT TOP 1
       a1.*
INTO #cb_OutputValueMonthReview_Approve
FROM dbo.cb_OutputValueMonthReview a1
WHERE a1.ProjGUID = @ProjGUID
      AND a1.ApproveState = '已审核'
ORDER BY a1.ApproveDate DESC;

SELECT b.*
INTO #cb_OutputValueReviewDetail_Approve
FROM #cb_OutputValueMonthReview_Approve a
    INNER JOIN dbo.cb_OutputValueReviewDetail b
        ON b.OutputValueMonthReviewGUID = a.OutputValueMonthReviewGUID;

DECLARE @ApplyBeginDate DATETIME;
DECLARE @ApplyEndDate DATETIME;

SELECT @ApplyBeginDate = ISNULL(CAST(CONVERT(VARCHAR(100), CreateDate, 23) AS DATETIME), '1900-01-01')
FROM #cb_OutputValueMonthReview_Approve;
IF @ApplyBeginDate IS NULL
BEGIN
    SET @ApplyBeginDate = '1900-01-01';
END;

SELECT @ApplyEndDate = CAST(CONVERT(VARCHAR(100), GETDATE(), 23) AS DATETIME);


DECLARE @IsJbProj int;
SET @IsJbProj = 0;
IF @IsInit = 0
BEGIN
    SELECT @IsJbProj = CASE 
                           WHEN CHARINDEX('竣备项目', OutputValueMonthReviewName) > 0 THEN 1 
                           ELSE 0 
                       END 
    FROM cb_OutputValueMonthReview 
    WHERE OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID;
END;

--获取合同信息
SELECT a.ContractName,
       a.ContractGUID,
       a.bgxs,
       a.SumYfAmount,
       @ProjGUID AS ProjGUID,
       a.JsState,
       a.JsAmount - ISNULL(balance.AlterAmount_Fxj, 0) AS JsAmount, --合同结算金额需要扣除非现金金额
       IsFromXyl,
       CASE
           WHEN CHARINDEX('非', a.HtClass) <= 0 THEN
               0
           ELSE
               1
       END AS IsFht
INTO #Contract
FROM dbo.cb_Contract a
    LEFT JOIN
    (
        SELECT ContractGUID,
               SUM(AlterAmount_Fxj) AS AlterAmount_Fxj
        FROM cb_HTBalance
        WHERE ApproveState IN ( '审核中', '已审核' )
              AND BalanceType = '结算'
        GROUP BY ContractGUID
    ) AS balance
        ON a.ContractGUID = balance.ContractGUID
WHERE a.ContractGUID IN
      (
          SELECT a1.ContractGUID
          FROM dbo.cb_ContractProj a1
          WHERE ProjGUID = @ProjGUID
      )
      AND a.ApproveState IN ( '审核中', '已审核' )
      AND a.IfDdhs = 1
      AND a.IsFyControl = 0
      AND a.ProjType IN ( '单项目', '多项目' );

--获取补充合同信息
SELECT CASE
           WHEN ISNULL(a.JsState, '') IN ( '', '未结算' ) THEN
               MAX(b.BlPayAmount)
           ELSE
               0
       END AS BlSumAmount,
       CASE
           WHEN ISNULL(a.JsState, '') IN ( '', '未结算' ) THEN
               ROUND(MAX(b.BlPayAmount) * c.CfRate / 100.00, 2)
           ELSE
               0
       END AS BlPayAmount,
       MAX(b.BlPayAmount) AS FxjSumAmount,
       ROUND(MAX(b.BlPayAmount) * c.CfRate / 100.00, 2) AS FxjAmount,
       MAX(b.ZZGAmount) AS ZZGSumAmount,
       ROUND(MAX(b.ZZGAmount) * c.CfRate / 100.00, 2) AS ZZGAmount,
       MAX(b.FsBxAmount) AS FsBxSumAmount,
       ROUND(MAX(b.FsBxAmount) * c.CfRate / 100.00, 2) AS FsBxAmount,
       c.BldGUID,
       b.MasterContractGUID,
       d.ProjGUID
INTO #BLBcContract
FROM #Contract a
    INNER JOIN
    (
        SELECT MasterContractGUID,
               SUM(   CASE
                          WHEN ISNULL(IsFromXyl, 0) = 1 THEN
                              HtAmount_Bz
                          ELSE
                              0
                      END
                  ) AS BlPayAmount,
               SUM(   CASE
                          WHEN ISNULL(IsZzgbx, 0) = 1 THEN
                              HtAmount_Bz
                          ELSE
                              0
                      END
                  ) AS ZZGAmount,
               SUM(   CASE
                          WHEN ISNULL(HtAmount_Bz, 0) < 0 THEN
                              HtAmount_Bz
                          ELSE
                              0
                      END
                  ) AS FsBxAmount
        FROM cb_Contract
        WHERE ApproveState IN ( '审核中', '已审核' )
              AND IfDdhs = 0
              AND IsFyControl = 0
              AND MasterContractGUID IS NOT NULL
        GROUP BY MasterContractGUID
    ) b
        ON a.ContractGUID = b.MasterContractGUID
    INNER JOIN cb_ContractOutputValueCf c
        ON a.ContractGUID = c.RefGUID
    INNER JOIN #GCbuild d
        ON d.BldGUID = c.BldGUID
GROUP BY c.BldGUID,
         b.MasterContractGUID,
         d.ProjGUID,
         c.CfRate,
         a.JsState;

--补充合同补差
UPDATE a
SET a.BlPayAmount = a.BlPayAmount + (a.BlSumAmount - b.BlPayAmount),
    a.FsBxAmount = a.FsBxAmount + (a.FsBxSumAmount - b.FsBxAmount),
    a.FxjAmount = a.FxjAmount + (a.FxjSumAmount - b.FxjAmount),
    a.ZZGAmount = a.ZZGAmount + (a.ZZGSumAmount - b.ZZGAmount)
FROM #BLBcContract a
    INNER JOIN
    (
        SELECT MAX(BldGUID) BldGUID,
               MasterContractGUID,
               SUM(BlPayAmount) AS BlPayAmount,
               SUM(FxjAmount) AS FxjAmount,
               SUM(ZZGAmount) AS ZZGAmount,
               SUM(FsBxAmount) AS FsBxAmount
        FROM #BLBcContract
        GROUP BY MasterContractGUID
    ) b
        ON (
               ISNULL(a.BlSumAmount, 0) <> ISNULL(b.BlPayAmount, 0)
               OR ISNULL(a.FsBxSumAmount, 0) <> ISNULL(b.FsBxAmount, 0)
               OR ISNULL(a.FxjSumAmount, 0) <> ISNULL(b.FxjAmount, 0)
               OR ISNULL(a.ZZGSumAmount, 0) <> ISNULL(b.ZZGAmount, 0)
           )
           AND a.BldGUID = b.BldGUID
           AND a.MasterContractGUID = b.MasterContractGUID;


--获取合同产值拆分
SELECT a.RefGUID,
       a.ContractCfAmount,
       a.ContractYlCfAmount,
       a.BldName,
       a.BldGUID,
       a.Czglms,
       a.JsState,
       a.SumBuildArea,
       a.ContractGUID,
       a.BusinessType,
       a.ContractBxCfAmount,
       a.IsFromXyl
INTO #cb_ContractOutputValueCf
FROM
(
    -- 获取合同产值拆分信息
    SELECT a1.ContractCfAmount,
           a1.ContractYlCfAmount,
           a1.RefGUID,
           b1.ContractGUID,
           c1.SumBuildArea,
           b1.JsState,
           CASE
               WHEN a1.CZManageModel = '无需产值申报' THEN 1
               WHEN a1.CZManageModel = '按楼栋实际盘点' THEN 4
               WHEN a1.CZManageModel = '分摊至指定楼栋' THEN 2
               WHEN a1.CZManageModel = '分摊至全部楼栋' THEN 3
               ELSE 1
           END AS Czglms,
           c1.BldName,
           a1.BldGUID,
           '合同' AS BusinessType,
           a1.ContractBxCfAmount,
           b1.IsFromXyl
    FROM dbo.cb_ContractOutputValueCf a1
        INNER JOIN #Contract b1
            ON a1.RefGUID = b1.ContractGUID
        INNER JOIN #GCbuild c1
            ON c1.BldGUID = a1.BldGUID
    
    UNION ALL
    
    -- 获取结算产值拆分信息
    SELECT c1.ContractCfAmount,
           c1.ContractYlCfAmount,
           c1.RefGUID,
           b1.ContractGUID,
           d1.SumBuildArea,
           a1.JsState,
           CASE
               WHEN c1.CZManageModel = '无需产值申报' THEN 1
               WHEN c1.CZManageModel = '按楼栋实际盘点' THEN 4
               WHEN c1.CZManageModel = '分摊至指定楼栋' THEN 2
               WHEN c1.CZManageModel = '分摊至全部楼栋' THEN 3
               ELSE 1
           END AS Czglms,
           c1.BldName,
           c1.BldGUID,
           '结算' AS BusinessType,
           0 AS ContractBxCfAmount,
           0 AS IsFromXyl
    FROM #Contract a1
        INNER JOIN dbo.cb_HTBalance b1
            ON b1.ContractGUID = a1.ContractGUID
               AND b1.ApproveState IN ( '已审核', '审核中' )
               AND b1.BalanceType = '结算'
        INNER JOIN cb_ContractOutputValueCf c1
            ON c1.RefGUID = b1.HTBalanceGUID
        INNER JOIN #GCbuild d1
            ON d1.BldGUID = c1.BldGUID
) a;

-- 创建索引以提高查询性能
CREATE NONCLUSTERED INDEX idx_OutputValueReviewDetailGUID
ON #cb_ContractOutputValueCf (
                                BusinessType,
                                BldGUID,
                                RefGUID
                            )
INCLUDE (
            BldName,
            SumBuildArea,
            ContractYlCfAmount,
            ContractCfAmount
        );


--获取合同产值汇总信息
SELECT a.SumYfAmount,
       b.ContractCfAmount,
       b.ContractYlCfAmount,
       a.ContractGUID,
       a.ProjGUID,
       a.ContractName,
       CASE
           WHEN b.Czglms = 1 THEN '无需产值申报'
           WHEN b.Czglms = 4 THEN '按楼栋实际盘点'
           WHEN b.Czglms = 2 THEN '分摊至指定楼栋'
           WHEN b.Czglms = 3 THEN '分摊至全部楼栋'
       END AS Czglms,
       b.BldArea,
       a.bgxs,
       a.JsState,
       a.JsAmount,
       b.ContractBxCfAmount,
       b.IsFromXyl,
       a.IsFht
INTO #ContractCz
FROM #Contract a
    INNER JOIN
    (
        -- 获取合同产值拆分汇总信息
        SELECT a1.RefGUID AS ContractGUID,
               SUM(ISNULL(a1.ContractCfAmount, 0)) AS ContractCfAmount,
               SUM(ISNULL(a1.ContractYlCfAmount, 0)) AS ContractYlCfAmount,
               SUM(ISNULL(a1.ContractBxCfAmount, 0)) AS ContractBxCfAmount,
               SUM(ISNULL(a1.SumBuildArea, 0)) AS BldArea,
               MAX(Czglms) AS Czglms,
               MAX(IsFromXyl) AS IsFromXyl
        FROM
        (
            SELECT a1.RefGUID,
                   a1.ContractCfAmount,
                   a1.ContractYlCfAmount,
                   a1.SumBuildArea,
                   a1.ContractBxCfAmount,
                   a1.Czglms,
                   a1.IsFromXyl
            FROM #cb_ContractOutputValueCf a1
            WHERE a1.BusinessType = '合同'
        ) a1
        GROUP BY a1.RefGUID
    ) b
        ON b.ContractGUID = a.ContractGUID;


CREATE NONCLUSTERED INDEX idx_ContractGUID
ON #ContractCz (
                   ContractGUID,
                   Czglms
               );

BEGIN -- 获取付款申请产值信息
    -- 获取最新的付款申请信息
    SELECT a.ContractGUID
    INTO #cb_HTFKAdvanceApply
    FROM
    (
        SELECT b1.ContractGUID,
               ROW_NUMBER() OVER (PARTITION BY b1.ContractGUID ORDER BY b1.ApplyDate DESC) AS RowNum
        FROM #ContractCz a1
            INNER JOIN dbo.cb_HTFKAdvanceApply b1
                ON b1.ContractGUID = a1.ContractGUID
        WHERE CAST(CONVERT(VARCHAR(100), b1.ApplyDate, 23) AS DATETIME) >= @ApplyBeginDate
              AND CAST(CONVERT(VARCHAR(100), b1.ApplyDate, 23) AS DATETIME) <= @ApplyEndDate
    ) a
    WHERE a.RowNum = 1;

    -- 获取付款申请产值拆分信息
    SELECT ISNULL(b.YfsbXcljczHbc, 0) AS Sgdwysbcz,    -- 施工单位已申报产值
           ISNULL(b.JfshXcljczHbc, 0) AS Jfysdcz,      -- 甲方已审定产值
           ISNULL(b.JfshljyfkHbc, 0) AS Ljyfkje,       -- 累计应付款金额
           ISNULL(b.YfsbXcljqkHbc, 0) AS Sgdwysbyfk,   -- 施工单位已申报应付款
           a.ContractGUID,
           a.HTFKApplyGUID,
           b.BldGUID
    INTO #cb_HTFKApply_Bldczcf
    FROM
    (
        -- 获取最新的已审核付款申请
        SELECT a1.curljywccz,
               a1.curjfljywccz,
               a1.curhtczljyfje,
               a1.CurYfsbXcljqk,
               ROW_NUMBER() OVER (PARTITION BY b1.ContractGUID ORDER BY a1.ApproveDate DESC) AS RowNum,
               a1.ContractGUID,
               a1.HTFKApplyGUID
        FROM dbo.cb_HTFKApply a1
            INNER JOIN #ContractCz b1
                ON b1.ContractGUID = a1.ContractGUID
        WHERE a1.ApplyState = '已审核'
    ) a
        INNER JOIN cb_HTFKApply_Bldczcf b
            ON b.HTFKApplyGUID = a.HTFKApplyGUID
        INNER JOIN #GCbuild c
            ON c.BldGUID = b.BldGUID
    WHERE a.RowNum = 1;
END;

-- 获取实付产值拆分
SELECT c.ContractYlCfAmount,
       a.ContractGUID,
       c.BldGUID
INTO #ContractPayCzCf
FROM #ContractCz a
    INNER JOIN dbo.cb_Voucher b
        ON b.ContractGUID = a.ContractGUID
    INNER JOIN dbo.cb_ContractOutputValueCf c
        ON c.RefGUID = b.VouchGUID
    INNER JOIN #GCbuild d
        ON d.BldGUID = c.BldGUID;

BEGIN -- 获取建设状态
    -- 获取最新的建设状态信息
    SELECT *
    INTO #Jszt
    FROM
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY a1.BldGUID ORDER BY e1.ApproveDate DESC) AS RowID,
               f1.Status,
               a1.BldGUID
        FROM dbo.jd_OutValueJsztBld a1
            INNER JOIN dbo.jd_OutValueJszt b1
                ON b1.OutValueJsztGUID = a1.OutValueJsztGUID
            INNER JOIN dbo.jd_OutValueView e1
                ON e1.OutValueViewGUID = b1.OutValueViewGUID
            INNER JOIN #GCbuild c1
                ON c1.BldGUID = a1.BldGUID
            INNER JOIN dbo.jd_BuildConstruction f1
                ON f1.BuildConstructionGUID = b1.BuildConstructionGUID
        WHERE e1.ApproveState = '已审核'
    ) a1
    WHERE a1.RowID = 1;
END;

BEGIN -- 获取产值上、下限
    -- 获取最新的产值上下限信息
    SELECT *
    INTO #jd_KeyNodeOutValue
    FROM
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY b1.BldGUID ORDER BY d1.LevelCode DESC) AS RowID,
               f1.CzUpperLimit,
               f1.CzLowerLimit,
               b1.BldGUID
        FROM p_BiddingBuilding2Building a1
            INNER JOIN #GCbuild b1
                ON b1.BldGUID = a1.BuildingGUID
            INNER JOIN jd_ProjectPlanExecute c1
                ON c1.ObjectID = a1.BudGUID
            INNER JOIN jd_ProjectPlanTaskExecute d1
                ON c1.ID = d1.PlanID
            INNER JOIN dbo.jd_KeyNode e1
                ON e1.KeyNodeGUID = d1.KeyNodeID
            INNER JOIN jd_KeyNodeOutValue f1
                ON f1.KeyNodeGUID = e1.KeyNodeGUID
        WHERE ISNULL(f1.CzUpperLimit, 0) <> 0
              AND ISNULL(f1.CzLowerLimit, 0) <> 0
    ) a
    WHERE a.RowID = 1;
END;


--插入合约规划使用
SELECT d1.BudgetAmount,
       b1.ContractGUID,
       d1.BudgetName
INTO #Cb_BudgetUse
FROM dbo.cb_BudgetUse a1
    INNER JOIN #ContractCz b1
        ON b1.ContractGUID = a1.RefGUID
    INNER JOIN dbo.cb_Budget d1
        ON d1.BudgetGUID = a1.BudgetGUID;


--插入合约规划信息
SELECT a.BudgetName,
       SUM(ISNULL(a.BudgetAmount, 0)) AS BudgetAmount,
       a.ExecutingBudgetGUID AS BudgetGUID,
       a.ProjectGUID AS ProjGUID,
       b.CZManageModel AS Czglms
INTO #Budget
FROM dbo.cb_Budget a WITH (NOLOCK)
    INNER JOIN dbo.cb_Budget_Executing b
        ON b.ExecutingBudgetGUID = a.ExecutingBudgetGUID
WHERE b.CZManageModel IN ( '按楼栋实际盘点', '分摊至指定楼栋', '分摊至全部楼栋' )
      AND a.ProjectGUID = @ProjGUID
      AND a.IsUseable = 1
      AND a.IfEnd = 1
GROUP BY a.BudgetName,
         a.ExecutingBudgetGUID,
         a.ProjHybGUID,
         a.ProjectGUID,
         b.CZManageModel;


CREATE NONCLUSTERED INDEX idx_BudgetGUID ON #Budget (BudgetGUID);


SELECT b1.BudgetGUID,
       c1.BldName,
       a1.GCBldGUID,
       b1.Czglms,
       c1.SumBuildArea,
       b1.BudgetAmount
INTO #cb_Budget_Executing2GCBld
FROM cb_Budget_Executing2GCBld a1 WITH (NOLOCK)
    INNER JOIN #Budget b1
        ON a1.BudgetGUID = b1.BudgetGUID
    INNER JOIN #GCbuild c1
        ON c1.BldGUID = a1.GCBldGUID;

CREATE NONCLUSTERED INDEX idx_BudgetGUID
ON #cb_Budget_Executing2GCBld (
                                  BudgetGUID,
                                  GCBldGUID,
                                  Czglms
                              )
INCLUDE (
            BldName,
            SumBuildArea
        );



CREATE TABLE #Temp
(
    TempGUID UNIQUEIDENTIFIER PRIMARY KEY
DEFAULT (NEWID()),
    BudgetName VARCHAR(MAX),
    ContractName VARCHAR(400),
    Czglms VARCHAR(20),
    Jjfs VARCHAR(20),
    Sfzzg VARCHAR(20),
    BldName VARCHAR(200),
    BldArea MONEY,
    Jszt VARCHAR(200),
    BudgetAmount MONEY,
    ContractAmount MONEY,
    BcxyAmount MONEY,
    HtylAmount MONEY,
    JsAmount MONEY,
    Bysfsbcz VARCHAR(200),
    Sgdwysbcz MONEY,
    Jfysdcz MONEY,
    Xmpdljwccz MONEY,
    Dfscz MONEY,
    Ljyfkje MONEY,
    LjSfkje MONEY,
	LjSfkjeNoFxj MONEY,
    Ydczwfje MONEY,
    Yfwf MONEY,
    BusinessGUID UNIQUEIDENTIFIER,
    BusinessType VARCHAR(20),
    IsBld TINYINT,
    BldGUID UNIQUEIDENTIFIER,
    CzUpperLimit MONEY,
    CzLowerLimit MONEY,
    Jfysdyfk MONEY,
    Sgdwysbyfk MONEY,
    JsState VARCHAR(10),
    BlPayAmount MONEY
);

--插入结果表信息
INSERT INTO #Temp
(
    BudgetName,
    ContractName,
    Czglms,
    Jjfs,
    Sfzzg,
    BldName,
    BldArea,
    Jszt,
    BudgetAmount,
    ContractAmount,
    BcxyAmount,
    HtylAmount,
    JsAmount,
    Bysfsbcz,
    Sgdwysbcz,
    Jfysdcz,
    Xmpdljwccz,
    Dfscz,
    Ljyfkje,
    LjSfkje,
    LjSfkjeNoFxj,
    Ydczwfje,
    Yfwf,
    BusinessGUID,
    BusinessType,
    IsBld,
    BldGUID,
    CzUpperLimit,
    CzLowerLimit,
    Jfysdyfk,
    Sgdwysbyfk,
    JsState,
    BlPayAmount
)
--查找合约规划使用
SELECT a.BudgetName,                    --合约规划名称       
       '' AS ContractName,              --合同名称
       a.Czglms AS Czglms,              --产值管理模式
       '' AS Jjfs,                      --计价方式
       '' AS Sfzzg,                     --是否暂转固           
       '' AS BldName,                   --楼栋名称
       ISNULL(d.BldArea, 0) AS BldArea, --建筑面积
       '' Jszt,                         --建设状态(二批次内容)
       a.BudgetAmount,                  --合约规划金额（A）
       0.00 AS ContractAmount,          --合同签约金额（B）
       0.00 AS BcxyAmount,              --补充协议金额（C）
       0.00 AS HtylAmount,              --合同预留金额（D）
       0.00 AS JsAmount,                --合同结算金额
       '否' AS Bysfsbcz,                 --本月是否申报产值(二批次内容)
       0.00 AS Sgdwysbcz,               --施工单位已申报产值（E）(二批次内容)
       0.00 AS Jfysdcz,                 --甲方已审定产值（F）(二批次内容)
       0.00 AS Xmpdljwccz,              --项目盘点累计完成产值（G）
       a.BudgetAmount AS Dfscz,         --待发生产值
       0.00 AS Ljyfkje,                 --累计应付款金额(二批次内容)
       0.00 AS LjSfkje,                 --累计实付款
	   0.00 AS LjSfkjeNoFxj,                 --累计实付款不含非现金
       0.00 AS Ydczwfje,                --已达产值未支付金额
       0.00 AS Yfwf,                    --应付未付
       a.BudgetGUID AS BusinessGUID,    --业务GUID
       '合约规划' AS BusinessType,          --业务类型       
       0 AS IsBld,                      --是否楼栋，0是非楼栋层级，1表示楼栋层级
       NULL AS BldGUID,                 --楼栋GUID
       0 AS CzUpperLimit,               --进度产值上限
       0 AS CzLowerLimit,               --进度产值下限	   
       0.00 AS Jfysdyfk,                --施工单位已申报应付款(二批次内容)
       0.00 AS Sgdwysbyfk,              --甲方审核应付款(二批次内容)
       '' AS JsState,                   --结算状态
       0.00 AS BlPayAmount              --保理拆分金额
FROM #Budget a
    LEFT JOIN
    (
        -- 计算楼栋总建筑面积
        SELECT SUM(ISNULL(SumBuildArea, 0)) AS BldArea,
               BudgetGUID
        FROM #cb_Budget_Executing2GCBld
        GROUP BY BudgetGUID
    ) d
        ON d.BudgetGUID = a.BudgetGUID
WHERE a.Czglms IN ( '按楼栋实际盘点', '分摊至指定楼栋', '分摊至全部楼栋' )

UNION

--查找合同信息
SELECT STUFF(
       (
           -- 获取预算名称列表
           SELECT ';' + CAST(budget.BudgetName AS VARCHAR(40))
           FROM
           (
               SELECT DISTINCT
                      a1.BudgetName
               FROM #Cb_BudgetUse a1
               WHERE a1.ContractGUID = a.ContractGUID
           ) budget
           FOR XML PATH('')
       ),
       1,
       1,
       ''
            ) AS BudgetName,                            --合约规划名称     
       a.ContractName AS ContractName,                  --合同名称
       a.Czglms AS Czglms,                              --产值管理模式
       a.bgxs AS Jjfs,                                  --计价方式
       CASE
           WHEN a.bgxs = '单价合同' THEN
               '是'
           ELSE
               ''
       END AS Sfzzg,                                    --是否暂转固           
       '' AS BldName,                                   --楼栋名称
       ISNULL(a.BldArea, 0) AS BldArea,                 --建筑面积
       '' Jszt,                                         --建设状态(二批次内容)
       CASE
           WHEN a.IsFht = 0
                AND a.JsState IN ( '结算', '结算中' ) THEN
               ISNULL(e.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)
           ELSE
               ISNULL(a.ContractYlCfAmount, 0) + ISNULL(a.ContractCfAmount, 0) + ISNULL(bl.FsBxAmount, 0)
               + ISNULL(bl.ZZGAmount, 0)
       END AS BudgetAmount,                             --合约规划金额（A）
       ISNULL(a.ContractCfAmount, 0) AS ContractAmount, --合同签约金额（B）
       ISNULL(a.ContractBxCfAmount, 0) AS BcxyAmount,   --补充协议金额（C）
       ISNULL(a.ContractYlCfAmount, 0) AS HtylAmount,   --合同预留金额（D）
       CASE
           WHEN a.JsState IN ( '结算', '结算中' ) THEN
               ISNULL(e.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)
           ELSE
               0
       END AS JsAmount,                                 --合同结算金额
       CASE
           WHEN c.ContractGUID IS NOT NULL THEN
               '是'
           ELSE
               '否'
       END AS Bysfsbcz,                                 --本月是否申报产值(二批次内容)
       ISNULL(d.Sgdwysbcz, 0) AS Sgdwysbcz,             --施工单位已申报产值（E）(二批次内容)
       ISNULL(d.Jfysdcz, 0) AS Jfysdcz,                 --甲方已审定产值（F）(二批次内容)
       CASE
           WHEN a.JsState IN ( '结算', '结算中' ) THEN
               ISNULL(e.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)
           ELSE
               ISNULL(d.Jfysdcz, 0)
       END AS Xmpdljwccz,                               --项目盘点累计完成产值（G）
       CASE
           WHEN a.JsState IN ( '结算', '结算中' ) THEN 0
           ELSE
               ISNULL(a.ContractYlCfAmount, 0) + ISNULL(a.ContractCfAmount, 0) - ISNULL(d.Jfysdcz, 0)
       END AS Dfscz,                                    --待发生产值
       CASE 
           WHEN ISNULL(@IsJbProj,0) = 0 THEN ISNULL(d.Ljyfkje, 0)
           ELSE 
               CASE
                   WHEN a.IsFht = 0 AND a.JsState IN ( '结算', '结算中' ) THEN
                       (ISNULL(e.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)) * 0.97
                   WHEN a.IsFht = 0 AND a.JsState NOT IN ( '结算', '结算中' ) THEN
                       (ISNULL(a.ContractYlCfAmount, 0) + ISNULL(a.ContractCfAmount, 0) + ISNULL(bl.FsBxAmount, 0) + ISNULL(bl.ZZGAmount, 0)) * 0.85
                   ELSE
                       (ISNULL(a.ContractYlCfAmount, 0) + ISNULL(a.ContractCfAmount, 0) + ISNULL(bl.FsBxAmount, 0) + ISNULL(bl.ZZGAmount, 0)) * 0.97
               END
       END AS Ljyfkje,                                  --累计应付款金额
       ISNULL(f.ContractYlCfAmount, 0) + ISNULL(bl.FxjAmount, 0) AS LjSfkje,      --累计实付款金额
       ISNULL(f.ContractYlCfAmount, 0) AS LjSfkjeNoFxj, --累计实付款金额(不含非现金)
       0.00 AS Ydczwfje,                                --已达产值未支付金额
       0.00 AS Yfwf,                                    --应付未付
       a.ContractGUID AS BusinessGUID,                  --业务GUID
       '合同' AS BusinessType,                            --业务类型       
       0 AS IsBld,                                      --是否楼栋
       NULL AS BldGUID,                                 --楼栋GUID
       0 AS CzUpperLimit,                               --进度产值上限
       0 AS CzLowerLimit,                               --进度产值下限
       ISNULL(d.Ljyfkje, 0) AS Jfysdyfk,                --甲方已审定应付款
       ISNULL(d.Sgdwysbyfk, 0) AS Sgdwysbyfk,          --施工单位已申报应付款
       a.JsState,                                       --结算状态
       ISNULL(bl.BlPayAmount, 0) AS BlPayAmount         --保理支付金额
FROM #ContractCz a
    LEFT JOIN
    (
        -- 获取补充协议金额
        SELECT SUM(ISNULL(a1.HtAmount, 0)) AS BcxyAmount,
               b1.ContractGUID
        FROM dbo.cb_Contract a1
            INNER JOIN #ContractCz b1
                ON b1.ContractGUID = a1.MasterContractGUID
        WHERE a1.ApproveState IN ( '已审核', '审核中' )
              AND a1.IfDdhs = 0
        GROUP BY b1.ContractGUID
    ) b
        ON b.ContractGUID = a.ContractGUID
    LEFT JOIN #cb_HTFKAdvanceApply c
        ON c.ContractGUID = a.ContractGUID
    LEFT JOIN
    (
        -- 获取付款申请汇总信息
        SELECT ContractGUID,
               SUM(ISNULL(Sgdwysbcz, 0)) AS Sgdwysbcz,
               SUM(ISNULL(Jfysdcz, 0)) AS Jfysdcz,
               SUM(ISNULL(Ljyfkje, 0)) AS Ljyfkje,
               SUM(ISNULL(Sgdwysbyfk, 0)) AS Sgdwysbyfk
        FROM #cb_HTFKApply_Bldczcf
        GROUP BY ContractGUID
    ) d
        ON d.ContractGUID = a.ContractGUID
    LEFT JOIN
    (
        -- 获取结算产值汇总信息
        SELECT SUM(ISNULL(ContractCfAmount, 0)) AS ContractCfAmount,
               SUM(ISNULL(ContractYlCfAmount, 0)) AS ContractYlCfAmount,
               ContractGUID
        FROM #cb_ContractOutputValueCf
        WHERE BusinessType = '结算'
        GROUP BY ContractGUID
    ) e
        ON e.ContractGUID = a.ContractGUID
    LEFT JOIN
    (
        -- 获取实付产值汇总信息
        SELECT SUM(ISNULL(ContractYlCfAmount, 0)) AS ContractYlCfAmount,
               ContractGUID
        FROM #ContractPayCzCf
        GROUP BY ContractGUID
    ) f
        ON f.ContractGUID = a.ContractGUID
    LEFT JOIN
    (
        -- 获取保理相关金额汇总
        SELECT SUM(BlPayAmount) AS BlPayAmount,
               SUM(FxjAmount) AS FxjAmount,
               SUM(FsBxAmount) AS FsBxAmount,
               SUM(ZZGAmount) AS ZZGAmount,
               MasterContractGUID
        FROM #BLBcContract
        GROUP BY MasterContractGUID
    ) bl
        ON bl.MasterContractGUID = a.ContractGUID
WHERE a.Czglms IN ( '按楼栋实际盘点', '分摊至指定楼栋', '分摊至全部楼栋' )
UNION ALL
--取合约规划楼栋信息
SELECT '' AS BudgetName,                     --合约规划名称       
       '' AS ContractName,                   --合同名称
       a.Czglms AS Czglms,                   --产值管理模式
       '' AS Jjfs,                           --计价方式
       '' AS Sfzzg,                          --是否暂转固           
                                             --ISNULL(c.BldName, '') AS BldName,     --楼栋名称
                                             --ISNULL(c.SumBuildArea, 0) AS BldArea, --建筑面积
       ISNULL(a.BldName, '') AS BldName,     --楼栋名称
       ISNULL(a.SumBuildArea, 0) AS BldArea, --建筑面积
       d.Status AS Jszt,                     --建设状态(二批次内容)
       a.BudgetAmount AS BudgetAmount,       --合约规划金额（A）
       0.00 AS ContractAmount,               --合同签约金额（B）
       0.00 AS BcxyAmount,                   --补充协议金额（C）
       0.00 AS HtylAmount,                   --合同预留金额（D）
       0.00 AS JsAmount,                     --合同结算金额
       '否' AS Bysfsbcz,                      --本月是否申报产值(二批次内容)
       0.00 AS Sgdwysbcz,                    --施工单位已申报产值（E）(二批次内容)
       0.00 AS Jfysdcz,                      --甲方已审定产值（F）(二批次内容)
       0.00 AS Xmpdljwccz,                   --项目盘点累计完成产值（G）
       0.00 AS Dfscz,                        --待发生产值
       0.00 AS Ljyfkje,                      --累计应付款金额(二批次内容)
       0.00 AS LjSfkje,                      --累计实付款
	   0.00 AS LjSfkjeNoFxj,                  --累计实付款（不含非现金）
       0.00 AS Ydczwfje,                     --已达产值未支付金额
       0.00 AS Yfwf,                         --应付未付
       a.BudgetGUID AS BusinessGUID,         --业务GUID
       '合约规划' AS BusinessType,               --业务类型       
       1 AS IsBld,                           --是否楼栋
       a.GCBldGUID,                          --b.GCBldGUID,
       e.CzUpperLimit AS CzUpperLimit,       --进度产值上限
       e.CzLowerLimit AS CzLowerLimit,       --进度产值下限
       0.00 AS Jfysdyfk,                     --甲方审核应付款(二批次内容)
       0.00 AS Sgdwysbyfk,                   --施工单位已申报应付款(二批次内容)
       '' AS JsState,
       0.00 AS BlPayAmount                   --保理拆分金额
FROM #cb_Budget_Executing2GCBld a
    LEFT JOIN #Jszt d
        ON d.BldGUID = a.GCBldGUID
    LEFT JOIN #jd_KeyNodeOutValue e
        ON e.BldGUID = a.GCBldGUID
WHERE a.Czglms IN ( '按楼栋实际盘点', '分摊至指定楼栋', '分摊至全部楼栋' )
UNION ALL
--取合同楼栋信息
SELECT '' AS BudgetName,                                --合约规划名称      
       '' AS ContractName,                              --合同名称
       b.Czglms AS Czglms,                              --产值管理模式
       '' AS Jjfs,                                      --计价方式
       '' AS Sfzzg,                                     --是否暂转固           
       ISNULL(a.BldName, '') AS BldName,                --楼栋名称
       ISNULL(a.SumBuildArea, 0) AS BldArea,            --建筑面积
       d.Status Jszt,                                   --建设状态(二批次内容)

       CASE
           WHEN b.IsFht = 0
                AND b.JsState IN ( '结算', '结算中' ) THEN
               ISNULL(h.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)
           ELSE
               ISNULL(a.ContractYlCfAmount, 0) + ISNULL(a.ContractCfAmount, 0) + ISNULL(bl.FsBxAmount, 0)
               + ISNULL(bl.ZZGAmount, 0)
       END AS BudgetAmount,                             --合约规划金额（A）
       ISNULL(a.ContractCfAmount, 0) AS ContractAmount, --合同签约金额（B）
       ISNULL(a.ContractBxCfAmount, 0) AS BcxyAmount,   --补充协议金额（C）
       ISNULL(a.ContractYlCfAmount, 0) AS HtylAmount,   --合同预留金额（D）
       CASE
           WHEN a.JsState IN ( '结算', '结算中' ) THEN
               ISNULL(h.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)
           ELSE
               0
       END AS JsAmount,                                 --合同结算金额
       '' AS Bysfsbcz,                                  --本月是否申报产值(二批次内容)
       ISNULL(g.Sgdwysbcz, 0) AS Sgdwysbcz,            --施工单位已申报产值（E）(二批次内容)
       ISNULL(g.Jfysdcz, 0) AS Jfysdcz,                --甲方已审定产值（F）(二批次内容)
       CASE
           WHEN b.JsState IN ( '结算', '结算中' ) THEN
               ISNULL(h.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)
           ELSE
               ISNULL(g.Jfysdcz, 0)
       END AS Xmpdljwccz,                               --项目盘点累计完成产值（G）
       CASE
           WHEN b.JsState IN ( '结算', '结算中' ) THEN 0
           ELSE
               ISNULL(a.ContractCfAmount, 0) + ISNULL(a.ContractYlCfAmount, 0) - ISNULL(g.Jfysdcz, 0)
       END AS Dfscz,                                    --待发生产值
       CASE 
           WHEN ISNULL(@IsJbProj,0) = 0 THEN ISNULL(g.Ljyfkje, 0)
           ELSE 
               CASE
                   WHEN b.IsFht = 0 AND b.JsState IN ( '结算', '结算中' ) THEN
                       (ISNULL(h.ContractYlCfAmount, 0) - ISNULL(bl.FxjAmount, 0)) * 0.97
                   WHEN b.IsFht = 0 AND b.JsState NOT IN ( '结算', '结算中' ) THEN
                       (ISNULL(a.ContractYlCfAmount, 0) + ISNULL(a.ContractCfAmount, 0) + ISNULL(bl.FsBxAmount, 0) + ISNULL(bl.ZZGAmount, 0)) * 0.85
                   ELSE
                       (ISNULL(a.ContractYlCfAmount, 0) + ISNULL(a.ContractCfAmount, 0) + ISNULL(bl.FsBxAmount, 0) + ISNULL(bl.ZZGAmount, 0)) * 0.97
               END
       END AS Ljyfkje,									--累计应付款金额(二批次内容)
       ISNULL(c.ContractYlCfAmount, 0)+ISNULL(bl.FxjAmount, 0) AS LjSfkje,      --累计实付款
	   ISNULL(c.ContractYlCfAmount, 0) AS LjSfkjeNoFxj,      --累计实付款不含非现金
       0 AS Ydczwfje,                                   --已达产值未支付金额
       0 AS Yfwf,                                       --应付未付
       a.RefGUID AS BusinessGUID,                       --业务GUID
       '合同' AS BusinessType,                            --业务类型     
       1 AS IsBld,                                      --是否楼栋
       a.BldGUID,                                       --楼栋GUID
       e.CzUpperLimit,                                  --计划产值上限
       e.CzLowerLimit,                                  --计划产值下限
       ISNULL(g.Ljyfkje, 0) AS Jfysdyfk,                --甲方审核应付款(二批次内容)
       ISNULL(g.Sgdwysbyfk, 0) AS Sgdwysbyfk,           --施工单位已申报应付款(二批次内容)
       a.JsState,
       bl.BlPayAmount AS BlPayAmount                    --保理拆分金额 
FROM #cb_ContractOutputValueCf a
    INNER JOIN #ContractCz b
        ON b.ContractGUID = a.RefGUID
    LEFT JOIN #Jszt d
        ON d.BldGUID = a.BldGUID
    LEFT JOIN #jd_KeyNodeOutValue e
        ON e.BldGUID = a.BldGUID
    LEFT JOIN
    (
        -- 获取付款申请楼栋汇总信息
        SELECT a1.BldGUID,
               SUM(ISNULL(a1.Sgdwysbcz, 0)) AS Sgdwysbcz,
               SUM(ISNULL(a1.Jfysdcz, 0)) AS Jfysdcz,
               SUM(ISNULL(a1.Ljyfkje, 0)) AS Ljyfkje,
               SUM(ISNULL(a1.Sgdwysbyfk, 0)) AS Sgdwysbyfk,
               a1.ContractGUID
        FROM #cb_HTFKApply_Bldczcf a1
        GROUP BY a1.BldGUID,
                 a1.ContractGUID
    ) g
        ON g.BldGUID = a.BldGUID
           AND g.ContractGUID = b.ContractGUID
    LEFT JOIN
    (
        SELECT BldGUID,
               ContractGUID,
               SUM(ISNULL(ContractCfAmount, 0)) AS ContractCfAmount,
               SUM(ISNULL(ContractYlCfAmount, 0)) AS ContractYlCfAmount
        FROM #cb_ContractOutputValueCf
        WHERE BusinessType = '结算'
        GROUP BY BldGUID,
                 ContractGUID
    ) h
        ON h.BldGUID = a.BldGUID
           AND h.ContractGUID = b.ContractGUID
    LEFT JOIN
    (
        SELECT SUM(ISNULL(ContractYlCfAmount, 0)) AS ContractYlCfAmount,
               ContractGUID,
               BldGUID
        FROM #ContractPayCzCf
        GROUP BY BldGUID,
                 ContractGUID
    ) c
        ON c.ContractGUID = a.ContractGUID
           AND c.BldGUID = a.BldGUID
    LEFT JOIN #BLBcContract bl
        ON bl.MasterContractGUID = a.ContractGUID
           AND bl.BldGUID = a.BldGUID
WHERE b.Czglms IN ( '按楼栋实际盘点', '分摊至指定楼栋', '分摊至全部楼栋' )
      AND a.BusinessType = '合同';

-- 获取已审核拍照楼栋信息
SELECT c.*,
       b.BusinessGUID
INTO #cb_OutputValueReviewBld_Approve
FROM
(
    -- 获取最新的已审核拍照
    SELECT TOP 1
           a1.OutputValueMonthReviewGUID
    FROM dbo.cb_OutputValueMonthReview a1 WITH (NOLOCK)
    WHERE a1.ProjGUID = @ProjGUID
          AND a1.ApproveState = '已审核'
    ORDER BY a1.ApproveDate DESC
) a
    INNER JOIN dbo.cb_OutputValueReviewDetail b WITH (NOLOCK)
        ON b.OutputValueMonthReviewGUID = a.OutputValueMonthReviewGUID
    INNER JOIN dbo.cb_OutputValueReviewBld c WITH (NOLOCK)
        ON c.OutputValueReviewDetailGUID = b.OutputValueReviewDetailGUID;

-- 项目盘点累计应付（I）列更新
IF @IsJbProj = 1
BEGIN
    -- 更新竣备项目的累计应付款和项目盘点累计完成产值
    UPDATE a
    SET a.Ljyfkje = CASE 
                        WHEN a.BudgetAmount > a.LjSfkjeNoFxj THEN 
                            CASE 
                                WHEN a.Ljyfkje < a.LjSfkjeNoFxj THEN a.LjSfkjeNoFxj 
                                ELSE a.Ljyfkje 
                            END
                        ELSE a.LjSfkjeNoFxj 
                    END,
        a.Xmpdljwccz = CASE 
                           WHEN a.BudgetAmount > a.LjSfkjeNoFxj THEN 
                               CASE 
                                   WHEN a.JsState IN ( '结算', '结算中') THEN 
                                       CASE 
                                           WHEN a.JsAmount <= a.LjSfkjeNoFxj THEN a.LjSfkjeNoFxj 
                                           ELSE a.JsAmount 
                                       END 
                                   ELSE 
                                       CASE 
                                           WHEN a.BudgetAmount * 0.85 < a.LjSfkjeNoFxj THEN a.LjSfkjeNoFxj 
                                           ELSE a.BudgetAmount * 0.85 
                                       END
                               END
                           ELSE a.LjSfkjeNoFxj 
                       END
    FROM #Temp a
    WHERE a.Ljyfkje <> 0;
END;

-- 更新已审核回顾非8大类的G和H列
UPDATE a
SET a.Xmpdljwccz = b.Xmpdljwccz,
    a.Dfscz = b.Dfscz
FROM #Temp a
    INNER JOIN #cb_OutputValueReviewDetail_Approve b
        ON a.BusinessGUID = b.BusinessGUID
           AND a.BusinessType = b.BusinessType
WHERE a.Czglms IN ( '分摊至指定楼栋', '分摊至全部楼栋' )
      AND ISNULL(a.JsState, '') NOT IN ( '结算', '结算中' )
      AND a.IsBld = 0;

-- 更新已审核回顾非8大类的G和H列(楼栋级)
UPDATE a
SET a.Xmpdljwccz = ISNULL(b.Xmpdljwccz, 0),
    a.Dfscz = ISNULL(b.Dfscz, 0)
FROM #Temp a
    INNER JOIN #cb_OutputValueReviewBld_Approve b
        ON a.BusinessGUID = b.BusinessGUID
           AND a.BldGUID = b.BldGUID
WHERE a.IsBld = 1
      AND a.Czglms IN ( '按楼栋实际盘点' )
      AND ISNULL(a.JsState, '') NOT IN ( '结算', '结算中' );

-- 合约规划待发生默认自动分摊
UPDATE a
SET Dfscz = ROUND(   CASE
                         WHEN ISNULL(b.BldArea, 0) <> 0 THEN
                             a.BudgetAmount * ISNULL(a.BldArea, 0) / ISNULL(b.BldArea, 0)
                         ELSE
                             0
                     END,
                     2
                 )
FROM #Temp a
    INNER JOIN
    (
        -- 计算楼栋总建筑面积
        SELECT SUM(ISNULL(a1.BldArea, 0)) AS BldArea,
               a1.BusinessGUID
        FROM #Temp a1
        WHERE a1.BusinessType = '合约规划'
              AND a1.IsBld = 1
        GROUP BY a1.BusinessGUID
    ) b
        ON a.BusinessGUID = b.BusinessGUID
WHERE a.BusinessType = '合约规划'
      AND a.IsBld = 1;

--合约规划待发生默认自动分摊补差更新
UPDATE a
SET Dfscz = a.Dfscz + a.BudgetAmount - ISNULL(b.Dfscz, 0)
FROM #Temp a
    INNER JOIN
    (
        -- 计算楼栋待发生产值汇总
        SELECT SUM(ISNULL(a1.Dfscz, 0)) AS Dfscz,
               a1.BusinessGUID
        FROM #Temp a1
        WHERE a1.BusinessType = '合约规划'
              AND a1.IsBld = 1
        GROUP BY a1.BusinessGUID
    ) b
        ON a.BusinessGUID = b.BusinessGUID
    INNER JOIN
    (
        -- 获取建筑面积最大的楼栋
        SELECT ROW_NUMBER() OVER (PARTITION BY a1.BusinessGUID
                                  ORDER BY a1.BldArea DESC,
                                           a1.TempGUID DESC
                                 ) AS RowID,
               a1.TempGUID
        FROM #Temp a1
        WHERE a1.BusinessType = '合约规划'
              AND a1.IsBld = 1
    ) c
        ON c.TempGUID = a.TempGUID
           AND c.RowID = 1
WHERE a.BusinessType = '合约规划'
      AND a.IsBld = 1;

--已审核回顾非8大类拆分
UPDATE a
SET Xmpdljwccz = ROUND(   CASE
                              WHEN ISNULL(c.BldArea, 0) <> 0 THEN
                                  ISNULL(b.Xmpdljwccz, 0) * ISNULL(a.BldArea, 0) / ISNULL(c.BldArea, 0)
                              ELSE
                                  0
                          END,
                          2
                      ),
    Dfscz = ROUND(   CASE
                         WHEN ISNULL(c.BldArea, 0) <> 0 THEN
                             ISNULL(b.Dfscz, 0) * ISNULL(a.BldArea, 0) / ISNULL(c.BldArea, 0)
                         ELSE
                             0
                     END,
                     2
                 )
FROM #Temp a
    INNER JOIN #cb_OutputValueReviewDetail_Approve b
        ON a.BusinessGUID = b.BusinessGUID
           AND b.BusinessType = a.BusinessType
    INNER JOIN #Temp c
        ON c.BusinessGUID = a.BusinessGUID
           AND c.IsBld = 0
WHERE a.Czglms IN ( '分摊至指定楼栋', '分摊至全部楼栋' )
      AND a.IsBld = 1
      AND ISNULL(a.JsState, '') NOT IN ( '结算', '结算中' );


--已审核回顾非8大类补差
UPDATE a
SET Dfscz = ISNULL(a.Dfscz, 0) + ISNULL(d.Dfscz, 0) - ISNULL(b.Dfscz, 0)
FROM #Temp a
    INNER JOIN
    (
        -- 计算楼栋待发生产值汇总
        SELECT SUM(ISNULL(a1.Dfscz, 0)) AS Dfscz,
               a1.BusinessGUID
        FROM #Temp a1
            INNER JOIN #cb_OutputValueReviewDetail_Approve b1
                ON a1.BusinessGUID = b1.BusinessGUID
                   AND b1.BusinessType = a1.BusinessType
        WHERE a1.Czglms IN ( '分摊至指定楼栋', '分摊至全部楼栋' )
              AND a1.IsBld = 1
        GROUP BY a1.BusinessGUID
    ) b
        ON a.BusinessGUID = b.BusinessGUID
    INNER JOIN
    (
        -- 获取建筑面积最大的楼栋
        SELECT ROW_NUMBER() OVER (PARTITION BY a1.BusinessGUID
                                  ORDER BY a1.BldArea DESC,
                                           a1.TempGUID DESC
                                 ) AS RowID,
               a1.TempGUID
        FROM #Temp a1
            INNER JOIN #cb_OutputValueReviewDetail_Approve b1
                ON a1.BusinessGUID = b1.BusinessGUID
                   AND b1.BusinessType = a1.BusinessType
        WHERE a1.Czglms IN ( '分摊至指定楼栋', '分摊至全部楼栋' )
              AND a1.IsBld = 1
    ) c
        ON c.TempGUID = a.TempGUID
           AND c.RowID = 1
    INNER JOIN #Temp d
        ON d.BusinessGUID = a.BusinessGUID
           AND d.IsBld = 0
WHERE a.Czglms IN ( '分摊至指定楼栋', '分摊至全部楼栋' )
      AND ISNULL(a.JsState, '') NOT IN ( '结算', '结算中' );

--已审核回顾8大类的汇总更新
UPDATE #Temp
SET Dfscz = ISNULL(c.Dfscz, 0),
    Xmpdljwccz = ISNULL(c.Xmpdljwccz, 0)
FROM #Temp a
    INNER JOIN
    (
        -- 计算楼栋产值汇总
        SELECT SUM(ISNULL(a1.Dfscz, 0)) AS Dfscz,
               SUM(ISNULL(a1.Xmpdljwccz, 0)) AS Xmpdljwccz,
               SUM(ISNULL(a1.Ljyfkje, 0)) AS Ljyfkje,
               a1.BusinessGUID,
               a1.BusinessType
        FROM #Temp a1
            INNER JOIN #cb_OutputValueReviewDetail_Approve b1
                ON b1.BusinessGUID = a1.BusinessGUID
                   AND b1.BusinessType = a1.BusinessType
        WHERE a1.IsBld = 1
              AND a1.Czglms = '按楼栋实际盘点'
        GROUP BY a1.BusinessGUID,
                 a1.BusinessType
    ) c
        ON c.BusinessGUID = a.BusinessGUID
           AND c.BusinessType = a.BusinessType
WHERE a.IsBld = 0
      AND a.Czglms = '按楼栋实际盘点'
      AND ISNULL(a.JsState, '') NOT IN ( '结算', '结算中' );

-- 清空楼栋级合约规划金额
UPDATE #Temp
SET BudgetAmount = 0
WHERE IsBld = 1
      AND BusinessType = '合约规划';

-- 通过已审核版本，更新累计应付款金额
IF EXISTS
(
    SELECT TOP 1
           OutputValueReviewDetailGUID
    FROM #cb_OutputValueReviewDetail_Approve
)
BEGIN
    -- 更新楼栋的累计应付款金额
    UPDATE a
    SET Ljyfkje = CASE
                      WHEN b.OutputValueReviewDetailGUID IS NULL THEN 0
                      ELSE b.Ljyfkje
                  END
    FROM #Temp a
        LEFT JOIN #cb_OutputValueReviewBld_Approve b
            ON b.BldGUID = a.BldGUID
               AND b.BusinessGUID = a.BusinessGUID
    WHERE a.IsBld = 1
          AND a.BusinessType = '合同';

    -- 汇总业务的累计应付款金额
    UPDATE a
    SET Ljyfkje = ISNULL(b.Ljyfkje, 0)
    FROM #Temp a
        INNER JOIN
        (
            -- 计算楼栋累计应付款汇总
            SELECT SUM(ISNULL(a1.Ljyfkje, 0)) AS Ljyfkje,
                   a1.BusinessGUID
            FROM #Temp a1
            WHERE a1.IsBld = 1
            GROUP BY a1.BusinessGUID
        ) b
            ON b.BusinessGUID = a.BusinessGUID
    WHERE a.IsBld = 0
          AND a.BusinessType = '合同';
END;

-- 如果是界面初始化，则不插入实际数据
IF @IsInit = 0
BEGIN
    -- 插入产值回顾明细
    INSERT INTO dbo.cb_OutputValueReviewDetail
    (
        OutputValueReviewDetailGUID,
        OutputValueMonthReviewGUID,
        BusinessGUID,
        BusinessType,
        BusinessName,
        CZManageModel,
        BudgetAmount,
        HtAmount,
        BcxyAmount,
        HtylAmount,
        JsAmount,
        Bysfsbcz,
        Sgdwysbcz,
        Jfysdcz,
        Xmpdljwccz,
        Dfscz,
        Ljyfkje,
        Ljsfk,
        LjsfkNoFxj,
        BudgetNameList,
        Jjfs,
        BldArea,
        Sgdwysbyfk,
        Jfysdyfk,
        JsState
    )
    SELECT TempGUID AS OutputValueReviewDetailGUID,
           @OutputValueMonthReviewGUID,
           BusinessGUID,
           BusinessType,
           CASE
               WHEN BusinessType = '合约规划' THEN BudgetName
               ELSE ContractName
           END AS BusinessName,
           Czglms,
           BudgetAmount,
           ContractAmount,
           BcxyAmount,
           HtylAmount,
           JsAmount,
           Bysfsbcz,
           Sgdwysbcz,
           Jfysdcz,
           Xmpdljwccz,
           Dfscz,
           Ljyfkje,
           LjSfkje,
           LjSfkjeNoFxj,
           CASE
               WHEN BusinessType = '合约规划' THEN ''
               ELSE BudgetName
           END AS BudgetNameList,
           Jjfs,
           BldArea,
           Sgdwysbyfk,
           Jfysdyfk,
           JsState
    FROM #Temp
    WHERE IsBld = 0;

    --插入产值楼栋信息
    INSERT INTO dbo.cb_OutputValueReviewBld
    (
        OutputValueReviewBldGUID,
        OutputValueReviewDetailGUID,
        BudgetAmount,
        HtAmount,
        BcxyAmount,
        HtylAmount,
        JsAmount,
        Bysfsbcz,
        Sgdwysbcz,
        Xmpdljwccz,
        Dfscz,
        Ljyfkje,
        Ljsfk,
        LjsfkNoFxj,
        BldName,
        BldArea,
        BldGUID,
        CzUpperLimit,
        CzLowerLimit,
        Sgdwysbyfk,
        Jfysdyfk,
        Jfysdcz,
        Jszt,
        JsState,
        BlPayAmount
    )
    SELECT a.TempGUID,
           b.TempGUID AS OutputValueReviewDetailGUID,
           a.BudgetAmount,
           a.ContractAmount,
           a.BcxyAmount,
           a.HtylAmount,
           a.JsAmount,
           a.Bysfsbcz,
           a.Sgdwysbcz,
           a.Xmpdljwccz,
           a.Dfscz,
           a.Ljyfkje,
           a.LjSfkje AS Ljsfk,
           a.LjSfkjeNoFxj AS LjsfkNoFxj,
           a.BldName,
           a.BldArea,
           a.BldGUID,
           a.CzUpperLimit,
           a.CzLowerLimit,
           a.Sgdwysbyfk,
           a.Jfysdyfk,
           a.Jfysdcz,
           a.Jszt,
           a.JsState,
           a.BlPayAmount
    FROM #Temp a
        INNER JOIN #Temp b
            ON a.BusinessGUID = b.BusinessGUID
               AND b.IsBld = 0
               AND a.BusinessType = b.BusinessType
    WHERE a.IsBld = 1;

END;

-- 创建结果表
CREATE TABLE #Result
(
    ProjGUID UNIQUEIDENTIFIER,           -- 项目GUID
    ProjName VARCHAR(400),               -- 项目名称
    BuildTotalArea MONEY,                -- 总建筑面积
    StartWorkArea MONEY,                 -- 已开工面积
    ShutDownArea MONEY,                  -- 停工面积
    TotalOutputValue MONEY,              -- 总产值
    YfsOutputValue MONEY,                -- 已发生产值
    DfsOutputValue MONEY,                -- 待发生产值
    LjyfAmount MONEY,                    -- 累计应付金额
    LjsfAmount MONEY,                    -- 累计实付金额
    LjsfNoFxjAmount MONEY,               -- 累计实付金额(不含非现金)
    BnljsfAmount MONEY,                  -- 本年累计实付金额
    YfwfAmount MONEY,                    -- 应付未付金额
    YdczwfAmount MONEY,                  -- 已达产值未付金额
    BlPayAmount MONEY,                   -- 保理支付金额
    XyyfzfAmount MONEY,                  -- 下月应付支付金额
    Ndzjjh MONEY,                        -- 年度资金计划
    BnygsyzfAmount MONEY                 -- 本年预估实际支付金额
);

-- 插入结果数据
INSERT INTO #Result
(
    ProjGUID,
    ProjName,
    BuildTotalArea,
    StartWorkArea,
    ShutDownArea,
    TotalOutputValue,
    YfsOutputValue,
    DfsOutputValue,
    LjyfAmount,
    LjsfAmount,
    LjsfNoFxjAmount,
    BnljsfAmount,
    YfwfAmount,
    YdczwfAmount,
    BlPayAmount,
    XyyfzfAmount,
    Ndzjjh,
    BnygsyzfAmount
)
SELECT a.ProjGUID,
       a.ProjName,
       ISNULL(d.BldArea, 0) AS BuildTotalArea,         -- 总建筑面积
       ISNULL(f.BldArea, 0) AS StartWorkArea,          -- 已开工面积
       ISNULL(e.BldArea, 0) AS ShutDownArea,           -- 停工面积
       g.TotalOutputValue - ISNULL(bl.FxjAmount,0) AS TotalOutputValue,  -- 总产值
       g.Xmpdljwccz AS YfsOutputValue,                 -- 已发生产值
       g.Dfscz AS DfsOutputValue,                      -- 待发生产值
       g.Ljyfkje AS LjyfAmount,                        -- 累计应付金额
       ISNULL(b.SumPayAmount, 0) AS LjsfAmount,        -- 累计实付金额
       ISNULL(b.SumPayAmount, 0) - ISNULL(bl.FxjAmount,0) AS LjsfNoFxjAmount,  -- 累计实付金额(不含非现金)
       ISNULL(c.BnljsfAmount, 0) AS BnljsfAmount,      -- 本年累计实付金额
       g.Ljyfkje - ISNULL(g.LjSfkjeNoFxj, 0) AS YfwfAmount,  -- 应付未付金额
       ISNULL(g.SumPayAmount, 0) AS YdczwfAmount,      -- 已达产值未付金额
       ISNULL(bl.blpayamount, 0) AS BlPayAmount,       -- 保理支付金额
       0 AS XyyfzfAmount,                              -- 下月应付支付金额
       0 AS Ndzjjh,                                    -- 年度资金计划
       0 - ISNULL(c.BnljsfAmount, 0) AS BnygsyzfAmount -- 本年预估实际支付金额
FROM dbo.p_Project a
    LEFT JOIN
    (
        -- 获取支付金额汇总
        SELECT SUM(ISNULL(b1.SumPayAmount, 0)) AS SumPayAmount,
               SUM(ISNULL(a1.ContractCfAmount, 0)) AS ContractCfAmount,
               SUM(ISNULL(a1.ContractYlCfAmount, 0)) AS ContractYlCfAmount,
               a1.ProjGUID
        FROM #ContractCz a1
            LEFT JOIN
            (
                SELECT SUM(ISNULL(ContractYlCfAmount, 0)) AS SumPayAmount,
                       ContractGUID
                FROM #ContractPayCzCf
                GROUP BY ContractGUID
            ) b1 
                ON b1.ContractGUID = a1.ContractGUID
        WHERE a1.Czglms IN ( '按楼栋实际盘点', '分摊至指定楼栋', '分摊至全部楼栋' )
        GROUP BY a1.ProjGUID
    ) b  
    ) b  ON b.ProjGUID = a.ProjGUID
    LEFT JOIN
    (
        SELECT SUM(ISNULL(a1.Dfscz, 0)) AS Dfscz,
               SUM(ISNULL(a1.Xmpdljwccz, 0)) AS Xmpdljwccz,
               SUM(ISNULL(a1.BudgetAmount, 0)) AS TotalOutputValue,
               SUM(ISNULL(a1.Ljyfkje, 0)) AS Ljyfkje,
               @ProjGUID AS ProjGUID,
               SUM(ISNULL(a1.Xmpdljwccz, 0) - ISNULL(a1.LjSfkjeNoFxj, 0)) AS SumPayAmount,
               SUM(ISNULL(a1.LjSfkje, 0)) AS LjSfkje,
			   SUM(ISNULL(a1.LjSfkjeNoFxj, 0)) AS LjSfkjeNoFxj
        FROM #Temp a1
        WHERE IsBld = 0
    ) g
        ON g.ProjGUID = a.ProjGUID
    LEFT JOIN
    (
        SELECT SUM(ISNULL(a.PayAmount, 0)) AS BnljsfAmount,
               b.ProjGUID
        FROM dbo.cb_Pay a
            INNER JOIN #Contract b
                ON b.ContractGUID = a.ContractGUID
            INNER JOIN dbo.cb_Voucher d
                ON d.VouchGUID = a.VouchGUID
        WHERE YEAR(d.KpDate) = YEAR(GETDATE())
        GROUP BY b.ProjGUID
    ) c
        ON c.ProjGUID = a.ProjGUID
    LEFT JOIN
    (
        SELECT SUM(SumBuildArea) AS BldArea,
               ProjGUID
        FROM #GCbuild
        WHERE ProjGUID = @ProjGUID
        GROUP BY ProjGUID
    ) d
        ON d.ProjGUID = a.ProjGUID
    LEFT JOIN
    (
        SELECT SUM(ISNULL(a.SumBuildArea, 0)) AS BldArea,
               a.ProjGUID
        FROM
        (
            SELECT d.BldGUID,
                   ROW_NUMBER() OVER (PARTITION BY d.BldGUID ORDER BY a.ApplicationTime DESC) AS RowID,
                   a.Type,
                   d.SumBuildArea,
                   d.ProjGUID
            FROM jd_StopOrReturnWork a
                INNER JOIN jd_ProjectPlanCompile b
                    ON a.PlanID = b.ID
                INNER JOIN p_BiddingBuilding2Building c
                    ON c.BudGUID = b.ObjectID
                INNER JOIN #GCbuild d
                    ON d.BldGUID = c.BuildingGUID
            WHERE d.ProjGUID = @ProjGUID
                  AND a.ApplyState = '已审核'
        ) a
        WHERE a.Type IN ( '停工', '缓建' )
              AND a.RowID = 1
        GROUP BY a.ProjGUID
    ) e
        ON e.ProjGUID = a.ProjGUID
    LEFT JOIN
    (
        SELECT SUM(ISNULL(a.SumBuildArea, 0)) AS BldArea,
               a.ProjGUID
        FROM #GCbuild a
            INNER JOIN
            (
                SELECT DISTINCT
                       a.BldGUID
                FROM #GCbuild a
                    INNER JOIN p_BiddingBuilding2Building b
                        ON b.BuildingGUID = a.BldGUID
                    INNER JOIN jd_ProjectPlanExecute c
                        ON c.ObjectID = b.BudGUID
                    INNER JOIN jd_ProjectPlanTaskExecute d
                        ON c.ID = d.PlanID
                           AND d.Level = 1
                    INNER JOIN jd_KeyNode e
                        ON e.KeyNodeGUID = d.KeyNodeID
                           AND e.KeyNodeName = '实际开工'
                WHERE a.ProjGUID = @ProjGUID
                      AND d.ActualFinish IS NOT NULL
                      AND c.PlanType = 103
            ) b
                ON a.BldGUID = b.BldGUID
        GROUP BY a.ProjGUID
    ) f
        ON f.ProjGUID = a.ProjGUID
    LEFT JOIN
    (
        SELECT SUM(ISNULL(BlPayAmount, 0)) as blpayamount,
				SUM(ISNULL(FxjAmount, 0)) as FxjAmount,
               ProjGUID
        FROM #BLBcContract
        GROUP BY ProjGUID
    ) bl
        ON bl.ProjGUID = a.ProjGUID
--LEFT JOIN
--(
--	select htproj.ProjGUID,ht.HtAmount_Bz from cb_Contract ht 
--	inner join cb_ContractProj htproj on ht.ContractGUID=htproj.ContractGUID
--	inner join cb_Budget budget on htproj.ProjGUID=budget.ProjectGUID
--	where ht.IsFromXyl=1 and ht.ContractName like '%非现金支付差额变更%'
--)bl  ON bl.ProjGUID = a.ProjGUID
WHERE a.ProjGUID = @ProjGUID;


IF @IsInit = 0
BEGIN
    --更新主表数据
    UPDATE a
    SET a.TotalOutputValue = b.TotalOutputValue,
        a.StartWorkArea = b.StartWorkArea,
        a.BuildTotalArea = b.BuildTotalArea,
        a.ShutDownArea = b.ShutDownArea,
        a.YfsOutputValue = b.YfsOutputValue,
        a.DfsOutputValue = b.DfsOutputValue,
        a.LjyfAmount = b.LjyfAmount,
        a.LjsfAmount = b.LjsfAmount,
		a.LjsfNoFxjAmount = b.LjsfNoFxjAmount,
        a.BnljsfAmount = b.BnljsfAmount,
        a.YfwfAmount = b.YfwfAmount,
        a.YdczwfAmount = b.YdczwfAmount,
        a.BlPayAmount = b.BlPayAmount
    FROM cb_OutputValueMonthReview a
        INNER JOIN #Result b
            ON a.ProjGUID = b.ProjGUID
    WHERE OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID;

    --更新销项数据
    SELECT b.Ysmj,
           b.Dsmj,
           b.Zhz,
           b.Yshz,
           b.Dshz,
           b.dtzksmj,
           a.BldGUID
    INTO #Sale
    FROM
    (
        SELECT DISTINCT
               a1.BldGUID
        FROM dbo.cb_OutputValueReviewBld a1
            INNER JOIN dbo.cb_OutputValueReviewDetail b1
                ON b1.OutputValueReviewDetailGUID = a1.OutputValueReviewDetailGUID
            INNER JOIN dbo.cb_OutputValueMonthReview c1
                ON c1.OutputValueMonthReviewGUID = b1.OutputValueMonthReviewGUID
        WHERE b1.OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID
    ) a
        INNER JOIN vcb_CzhgSaleInfo b
            ON b.GCBldGUID = a.BldGUID;

    DECLARE @Zjksmj MONEY;
    DECLARE @Ysmj MONEY;
    DECLARE @Dsmj MONEY;
    DECLARE @Zhz MONEY;
    DECLARE @Ydysxxhz MONEY;
    DECLARE @Yshz MONEY;
    DECLARE @Dshz MONEY;

    SELECT @Zjksmj = SUM(ISNULL(a.dtzksmj, 0)),
           @Ysmj = SUM(ISNULL(a.Ysmj, 0)),
           @Dsmj = SUM(ISNULL(a.Dsmj, 0)),
           @Zhz = SUM(ISNULL(a.Zhz, 0)),
           @Ydysxxhz = SUM(   CASE
                                  WHEN b.BldGUID IS NOT NULL THEN
                                      ISNULL(a.dtzksmj, 0)
                                  ELSE
                                      0
                              END
                          ),
           @Yshz = SUM(ISNULL(a.Yshz, 0)),
           @Dshz = SUM(ISNULL(a.Dshz, 0))
    FROM #Sale a
        LEFT JOIN
        (
            SELECT DISTINCT
                   a.BldGUID
            FROM #GCbuild a
                INNER JOIN p_BiddingBuilding2Building b
                    ON b.BuildingGUID = a.BldGUID
                INNER JOIN jd_ProjectPlanExecute c
                    ON c.ObjectID = b.BudGUID
                INNER JOIN jd_ProjectPlanTaskExecute d
                    ON c.ID = d.PlanID
                       AND d.Level = 1
                INNER JOIN jd_KeyNode e
                    ON e.KeyNodeGUID = d.KeyNodeID
                       AND e.KeyNodeName = '达到预售形象'
            WHERE a.ProjGUID = @ProjGUID
                  AND d.ActualFinish IS NOT NULL
                  AND c.PlanType = 103
        ) b
            ON a.BldGUID = b.BldGUID;


    UPDATE dbo.cb_OutputValueMonthReview
    SET Zksmj = @Zjksmj,
        Ysmj = @Ysmj,
        Dsmj = @Dsmj,
        Zhz = @Zhz,
        Ydysxxhz = @Ydysxxhz,
        Yshz = @Yshz,
        Dshz = @Dshz
    WHERE OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID;

    DELETE cb_OutputValueMonthSaleBld
    WHERE OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID;

    INSERT INTO dbo.cb_OutputValueMonthSaleBld
    (
        OutputValueMonthReviewGUID,
        BldGUID,
        OutputValueMonthSaleBldGUID,
        Zhz,
        Yshz,
        Dshz
    )
    SELECT @OutputValueMonthReviewGUID,
           BldGUID,
           NEWID() AS OutputValueMonthSaleBldGUID,
           Zhz,
           Yshz,
           Dshz
    FROM #Sale;

    DROP TABLE #Sale;

END;

SELECT *
FROM #Result;

DROP TABLE #Budget;
DROP TABLE #Cb_BudgetUse;
DROP TABLE #Contract;
DROP TABLE #GCbuild;
DROP TABLE #cb_OutputValueReviewBld_Approve;
DROP TABLE #cb_OutputValueReviewDetail_Approve;
DROP TABLE #ContractCz;
DROP TABLE #Result;

DROP TABLE #GCbuildTemp;
DROP TABLE #cb_Budget_Executing2GCBld;

