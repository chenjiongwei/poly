USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_GetCzhgModify]    Script Date: 2025/3/4 9:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_cb_GetCzhgModify]
(@OutputValueMonthReviewGUID UNIQUEIDENTIFIER)
AS
BEGIN
    CREATE TABLE #Temp
    (
        TempGUID UNIQUEIDENTIFIER PRIMARY KEY
            DEFAULT (NEWID()),
        BudgetName VARCHAR(200),
        Qyzt VARCHAR(20),
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
        Ydczwfje MONEY,
        Yfwf MONEY,
        BusinessGUID UNIQUEIDENTIFIER,
        BusinessType VARCHAR(20),
        OrderNo VARCHAR(64),
        ParentGUID UNIQUEIDENTIFIER,
        IsBld TINYINT,
        IsEdit TINYINT
            DEFAULT (0),
        Jfysdyfk MONEY,
        Sgdwysbyfk MONEY
    );

    --插入结果表信息
    INSERT INTO #Temp
    (
        TempGUID,
        BudgetName,
        Qyzt,
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
        Ydczwfje,
        Yfwf,
        BusinessGUID,
        BusinessType,
        OrderNo,
        ParentGUID,
        IsBld,
        Jfysdyfk,
        Sgdwysbyfk
    )
    --查找合约规划使用
    SELECT a.OutputValueReviewDetailGUID,
           a.BusinessName AS BudgetName,   --合约规划名称
           '未签约' AS Qyzt,                  --签约状态
           '' AS ContractName,             --合同名称
           a.CZManageModel AS Czglms,      --产值管理模式
           '' AS Jjfs,                     --计价方式
           '' AS Sfzzg,                    --是否暂转固           
           '' AS BldName,                  --楼栋名称
           NULL AS BldArea,                --建筑面积
           '' Jszt,                        --建设状态(二批次内容)
           a.BudgetAmount,                 --合约规划金额（A）
           NULL AS ContractAmount,         --合同签约金额（B）
           NULL AS BcxyAmount,             --补充协议金额（C）
           NULL AS HtylAmount,             --合同预留金额（D）
           NULL AS JsAmount,               --合同结算金额
           '否' AS Bysfsbcz,                --本月是否申报产值(二批次内容)
           NULL AS Sgdwysbcz,              --施工单位已申报产值（E）(二批次内容)
           NULL AS Jfysdcz,                --甲方已审定产值（F）(二批次内容)
           NULL AS Xmpdljwccz,             --项目盘点累计完成产值（G）
           a.Dfscz AS Dfscz,               --待发生产值
           NULL AS Ljyfkje,                --累计应付款金额(二批次内容)
           NULL AS LjSfkje,                --累计实付款
           NULL AS Ydczwfje,               --已达产值未支付金额
           NULL AS Yfwf,                   --应付未付
           a.BusinessGUID AS BusinessGUID, --业务GUID
           '合约规划' AS BusinessType,         --业务类型
           CAST(a.BusinessGUID AS VARCHAR(40)) AS OrderNo,
           NULL AS ParentGUID,
           0 AS IsBld,
           NULL AS Jfysdyfk,               --甲方已审定应付款(二批次内容)
           NULL AS Sgdwysbyfk              --施工单位已申报应付款(二批次内容)
    FROM cb_OutputValueReviewDetail a
    WHERE a.OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID
          AND a.BusinessType = '合约规划'
    UNION
    --查找合同信息
    SELECT a.OutputValueReviewDetailGUID,
           a.BudgetNameList AS BudgetName,                           --合约规划名称
           '已签约' AS Qyzt,                                            --签约状态
           a.BusinessName AS ContractName,                           --合同名称
           a.CZManageModel AS Czglms,                                --产值管理模式
           a.Jjfs AS Jjfs,                                           --计价方式
           CASE
               WHEN a.Jjfs = '单价包干'
                    AND EXISTS
                        (
                            SELECT TOP 1
                                   a1.ContractGUID
                            FROM dbo.cb_Contract a1
                            WHERE a1.MasterContractGUID = a.BusinessGUID
                                  AND a1.IsZzgbx = 1
                        ) THEN
                   '是'
               ELSE
                   '否'
           END AS Sfzzg,                                             --是否暂转固           
           '' AS BldName,                                            --楼栋名称
           NULL AS BldArea,                                          --建筑面积
           '' AS Jszt,                                               --建设状态(二批次内容)
           ISNULL(a.BudgetAmount, 0) AS BudgetAmount,                --合约规划金额（A）
           ISNULL(a.HtAmount, 0) AS ContractAmount,                  --合同签约金额（B）
           ISNULL(a.BcxyAmount, 0) AS BcxyAmount,                    --补充协议金额（C）
           ISNULL(a.HtylAmount, 0) AS HtylAmount,                    --合同预留金额（D）
           ISNULL(a.JsAmount, 0) AS JsAmount,                        --合同预留金额（D）
           a.Bysfsbcz AS Bysfsbcz,                                   --本月是否申报产值(二批次内容)
           a.Sgdwysbcz AS Sgdwysbcz,                                 --施工单位已申报产值（E）(二批次内容)
           a.Jfysdcz AS Jfysdcz,                                     --甲方已审定产值（F）(二批次内容)
           a.Xmpdljwccz AS Xmpdljwccz,                               --项目盘点累计完成产值（G）
           a.Dfscz AS Dfscz,                                         --待发生产值
           ISNULL(a.Ljyfkje, 0) AS Ljyfkje,                          --累计应付款金额(二批次内容)
           a.Ljsfk AS LjSfkje,                                       --累计实付款
           ISNULL(a.Xmpdljwccz, 0) - ISNULL(a.Ljsfk, 0) AS Ydczwfje, --已达产值未支付金额
           ISNULL(a.Ljyfkje, 0) - ISNULL(a.Ljsfk, 0) AS Yfwf,        --应付未付
           a.BusinessGUID AS BusinessGUID,                           --业务GUID
           '合同' AS BusinessType,                                     --业务类型
           CAST(a.BusinessGUID AS VARCHAR(40)) AS OrderNo,
           NULL AS ParentGUID,
           0 AS IsBld,
           a.Jfysdyfk AS Jfysdyfk,                                   --甲方已审定应付款(二批次内容)
           a.Sgdwysbyfk AS Sgdwysbyfk                                --施工单位已申报应付款(二批次内容)
    FROM cb_OutputValueReviewDetail a
    WHERE a.OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID
          AND a.BusinessType = '合同';
    --UNION ALL
    --取楼栋信息
    --SELECT a.OutputValueReviewBldGUID,
    --       '' AS BudgetName,               --合约规划名称
    --       '' AS Qyzt,                     --签约状态
    --       '' AS ContractName,             --合同名称
    --       '' AS Czglms,                   --产值管理模式
    --       '' AS Jjfs,                     --计价方式
    --       '' AS Sfzzg,                    --是否暂转固           
    --       a.BldName AS BldName,           --楼栋名称
    --       a.BldArea AS BldArea,           --建筑面积
    --       a.Jszt AS Jszt,                 --建设状态(二批次内容)
    --       CASE
    --           WHEN b.BusinessType = '合约规划' THEN
    --               NULL
    --           ELSE
    --               a.BudgetAmount
    --       END AS BudgetAmount,            --合约规划金额（A）
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.HtAmount
    --           ELSE
    --               NULL
    --       END AS ContractAmount,          --合同签约金额（B）
    --       NULL AS BcxyAmount,             --补充协议金额（C）
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.HtylAmount
    --           ELSE
    --               NULL
    --       END AS HtylAmount,              --合同预留金额（D）
    --       a.Bysfsbcz AS Bysfsbcz,         --本月是否申报产值(二批次内容)
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.Sgdwysbcz
    --           ELSE
    --               NULL
    --       END AS Sgdwysbcz,               --施工单位已申报产值（E）(二批次内容)
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.Jfysdcz
    --           ELSE
    --               NULL
    --       END AS Jfysdcz,                 --甲方已审定产值（F）(二批次内容)
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.Xmpdljwccz
    --           ELSE
    --               NULL
    --       END AS Xmpdljwccz,              --项目盘点累计完成产值（G）
    --       a.Dfscz AS Dfscz,               --待发生产值
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.Ljyfkje
    --           ELSE
    --               NULL
    --       END AS Ljyfkje,                 --累计应付款金额(二批次内容)
    --       NULL AS LjSfkje,                --累计实付款
    --       NULL AS Ydczwfje,               --已达产值未支付金额
    --       NULL AS Yfwf,                   --应付未付
    --       b.BusinessGUID AS BusinessGUID, --业务GUID
    --       b.BusinessType AS BusinessType, --业务类型
    --       CAST(b.BusinessGUID AS VARCHAR(40)) + '.'
    --       + CAST(ROW_NUMBER() OVER (PARTITION BY b.BusinessGUID ORDER BY a.BldName DESC) AS VARCHAR(20)) AS OrderNo,
    --       b.BusinessGUID AS ParentGUID,
    --       1 AS IsBld,
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.Jfysdyfk
    --           ELSE
    --               NULL
    --       END AS Jfysdyfk,                --甲方已审定应付款(二批次内容)
    --       CASE
    --           WHEN b.BusinessType = '合同' THEN
    --               a.Sgdwysbyfk
    --           ELSE
    --               NULL
    --       END AS Sgdwysbyfk               --施工单位已申报应付款(二批次内容)
    --FROM cb_OutputValueReviewBld a
    --    INNER JOIN cb_OutputValueReviewDetail b
    --        ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
    --WHERE b.OutputValueMonthReviewGUID = @OutputValueMonthReviewGUID;



    --插入配置表数据       
    BEGIN
        --列头表  
        CREATE TABLE #MyTemp_Config
        (
            id INT,
            columnName VARCHAR(50),
            showName VARCHAR(50),
            isFixed TINYINT,
            isAttribute TINYINT,
            isShow TINYINT,
            isHierarchyShow TINYINT,
            isHierarchyCode TINYINT,
            titleStyle VARCHAR(500),
            detailStyle VARCHAR(500),
            clickEvent VARCHAR(100),
            dblClickEvent VARCHAR(100),
            isEdit TINYINT,
            isAchorPoint TINYINT,
            width VARCHAR(10),
            format VARCHAR(50),
            tipColumn VARCHAR(50),
            align VARCHAR(10),
            groupName VARCHAR(100)
        );

        --行标识串    
        DECLARE @intRow INT;
        SET @intRow = 0;
        DECLARE @columnName VARCHAR(50);

        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'TempGUID', '主键', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'IsEdit', '行标识串', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'IsBld', '是否楼栋', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');


        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'BusinessType', '业务类型', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');


        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'ParentGUID', '父级GUID', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');


        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'OrderNo', '层级标识', 0, 1, 0, 0, 1, '', '', '', '', 0, 0, 0, '', '', '', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'BudgetName', '合约规划名称', 1, 0, 1, 0, 0, '', '', '', '', 0, 0, 150, '', 'BudgetName', '', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Qyzt', '签约状态', 1, 0, 1, 0, 0, '', '', '', '', 0, 0, 120, '', '', '', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'ContractName', '合同名称', 1, 0, 1, 0, 0, '', '', '', '', 0, 0, 120, '', 'ContractName', '', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Czglms', '产值管理模式', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 100, '', '', '', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Jjfs', '计价方式', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 100, '', '', '', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Sfzzg', '是否暂转固', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 90, '', '', '', '');


        --SET @intRow = @intRow + 1;
        --INSERT INTO #MyTemp_Config
        --(
        --    id,
        --    columnName,
        --    showName,
        --    isFixed,
        --    isAttribute,
        --    isShow,
        --    isHierarchyShow,
        --    isHierarchyCode,
        --    titleStyle,
        --    detailStyle,
        --    clickEvent,
        --    dblClickEvent,
        --    isEdit,
        --    isAchorPoint,
        --    width,
        --    format,
        --    tipColumn,
        --    align,
        --    groupName
        --)
        --VALUES
        --(@intRow, 'BldName', '楼栋名称', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 150, '', 'BldName', '', '');

        --SET @intRow = @intRow + 1;
        --INSERT INTO #MyTemp_Config
        --(
        --    id,
        --    columnName,
        --    showName,
        --    isFixed,
        --    isAttribute,
        --    isShow,
        --    isHierarchyShow,
        --    isHierarchyCode,
        --    titleStyle,
        --    detailStyle,
        --    clickEvent,
        --    dblClickEvent,
        --    isEdit,
        --    isAchorPoint,
        --    width,
        --    format,
        --    tipColumn,
        --    align,
        --    groupName
        --)
        --VALUES
        --(@intRow, 'BldArea', '建筑面积', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 90, '###,##0.00', '', 'Right', '');


        --SET @intRow = @intRow + 1;
        --INSERT INTO #MyTemp_Config
        --(
        --    id,
        --    columnName,
        --    showName,
        --    isFixed,
        --    isAttribute,
        --    isShow,
        --    isHierarchyShow,
        --    isHierarchyCode,
        --    titleStyle,
        --    detailStyle,
        --    clickEvent,
        --    dblClickEvent,
        --    isEdit,
        --    isAchorPoint,
        --    width,
        --    format,
        --    tipColumn,
        --    align,
        --    groupName
        --)
        --VALUES
        --(@intRow, 'Jszt', '建设状态', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 90, '', '', '', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'BudgetAmount', '合约规划金额（A）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 120, '###,##0.00', '', 'Right', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'ContractAmount', '合同签约金额（B）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 120, '###,##0.00', '', 'Right',
         '' );


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'BcxyAmount', '补充协议金额（C）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 120, '###,##0.00', '', 'Right', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'HtylAmount', '合同预留金额（含补协）（D）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 180, '###,##0.00', '', 'Right',
         '' );

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'JsAmount', '合同结算金额', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 180, '###,##0.00', '', 'Right', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Bysfsbcz', '本月是否申报产值', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 120, '', '', 'Center', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Sgdwysbcz', '施工单位已申报产值（E）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 150, '###,##0.00', '', 'Right', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Jfysdcz', '甲方已审定产值（F）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 150, '###,##0.00', '', 'Right', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Sgdwysbyfk', '施工单位已申报应付款', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 150, '###,##0.00', '', 'Right', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Jfysdyfk', '甲方已审定应付款', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 150, '###,##0.00', '', 'Right', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Xmpdljwccz', '项目盘点累计完成产值（G）', 0, 0, 1, 0, 0, '', '', '', '', 1, 0, 170, '###,##0.00', '', 'Right',
         '' );

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Ljyfkje', '项目盘点累计应付款（I）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 150, '###,##0.00', '', 'Right', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Dfscz', '待发生产值（H=B+D-G）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 170, '###,##0.00', '', 'Right', '');

        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'LjSfkje', '累计实付款（J）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 110, '###,##0.00', '', 'Right', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Ydczwfje', '已达产值未支付金额（K=G-J）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 180, '###,##0.00', '', 'Right',
         '' );


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config
        (
            id,
            columnName,
            showName,
            isFixed,
            isAttribute,
            isShow,
            isHierarchyShow,
            isHierarchyCode,
            titleStyle,
            detailStyle,
            clickEvent,
            dblClickEvent,
            isEdit,
            isAchorPoint,
            width,
            format,
            tipColumn,
            align,
            groupName
        )
        VALUES
        (@intRow, 'Yfwf', '应付未付（L=I-J）', 0, 0, 1, 0, 0, '', '', '', '', 0, 0, 250, '###,##0.00', '', 'Right', '');
    END;



    SELECT TempGUID,
           BudgetName,
           CASE
               WHEN a.IsBld = 1 THEN
                   ''
               ELSE
                   Qyzt
           END Qyzt,
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
           CASE
               WHEN a.IsBld = 1 THEN
                   ''
               ELSE
                   Bysfsbcz
           END Bysfsbcz,
           Sgdwysbcz,
           Jfysdcz,
           CASE
               WHEN a.BusinessType = '合约规划' THEN
                   NULL
               ELSE
                   a.Xmpdljwccz
           END AS Xmpdljwccz,
           Dfscz,
           CASE
               WHEN a.BusinessType = '合约规划' THEN
                   NULL
               ELSE
                   a.Ljyfkje
           END Ljyfkje,
           LjSfkje,
           Ydczwfje,
           Yfwf,
           BusinessGUID,
           BusinessType,
           OrderNo,
           ParentGUID,
           IsBld,
           CASE
               WHEN Czglms = '无需产值申报' THEN
                   0
               WHEN Czglms = '按楼栋实际盘点' THEN
                   CASE
                       WHEN IsBld = 0 THEN
                           0
                       ELSE
                           1
                   END
               WHEN Czglms = '分摊至指定楼栋'
                    OR Czglms = '分摊至全部楼栋' THEN
                   CASE
                       WHEN IsBld = 0 THEN
                           1
                       ELSE
                           0
                   END
               ELSE
                   0
           END IsEdit,
           a.Jfysdyfk,
           a.Sgdwysbyfk
    FROM
    (
        SELECT a.TempGUID,
               a.BudgetName,
               CASE
                   WHEN a.IsBld = 1 THEN
                       b.Qyzt
                   ELSE
                       a.Qyzt
               END QyztTemp,
               a.Qyzt,
               a.ContractName,
               a.Czglms,
               a.Jjfs,
               a.Sfzzg,
               a.BldName,
               a.BldArea,
               a.Jszt,
               a.BudgetAmount,
               a.ContractAmount,
               a.BcxyAmount,
               a.HtylAmount,
               a.JsAmount,
               CASE
                   WHEN a.IsBld = 1 THEN
                       b.Bysfsbcz
                   ELSE
                       a.Bysfsbcz
               END BysfsbczTemp,
               a.Bysfsbcz,
               a.Sgdwysbcz,
               a.Jfysdcz,
               a.Xmpdljwccz,
               a.Dfscz,
               a.Ljyfkje,
               a.LjSfkje,
               a.Ydczwfje,
               a.Yfwf,
               a.BusinessGUID,
               a.BusinessType,
               a.OrderNo,
               a.ParentGUID,
               a.IsBld,
               a.Sgdwysbyfk,
               a.Jfysdyfk
        FROM #Temp a
            LEFT JOIN #Temp b
                ON b.BusinessGUID = a.ParentGUID
                   AND b.ParentGUID IS NULL
    ) a
    ORDER BY QyztTemp DESC,
             BysfsbczTemp ASC,
             OrderNo;


    SELECT *
    FROM #MyTemp_Config;
END;