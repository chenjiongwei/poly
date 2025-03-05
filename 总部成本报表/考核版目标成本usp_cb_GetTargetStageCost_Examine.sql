USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_GetTargetStageCost_Examine]    Script Date: 2025/3/3 14:35:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_cb_GetTargetStageCost_Examine] (
@ProjectGUID VARCHAR(40),
@ProjectTargetStage VARCHAR(40),
@ProductGUIDParam VARCHAR(40))
AS
BEGIN
    DECLARE @ProjCode VARCHAR(100);
    DECLARE @BUGUID UNIQUEIDENTIFIER;
    DECLARE @IsExecVersion TINYINT;



    --列头表  
    CREATE TABLE #MyTemp_Config (id INT,
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
                                 groupName VARCHAR(50));

    --2　插入配置表数据       
    --2.0 行标识串    
    DECLARE @intRow INT;
    SET @intRow = 0;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'IsEdit', '行标识串', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'SharingMode', '分摊模式', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');


    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'AllowModify', '是否允许编辑', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

    --2.1 科目Code      
    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'CostCode', '科目Code', 0, 1, 0, 0, 1, '', '', '', '', 0, 0, 0, '', '', '', '');

    --2.2 科目guid      
    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'CostGUID', '科目GUID', 0, 1, 0, 0, 1, '', '', '', '', 0, 0, 0, '', '', '', '');

    --2.3 父级科目Code      
    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'ParentCode', '父级科目Code', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');
    --2.4 是否末级科目     
    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'IfEndCost', '是否末级科目', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

    --2.5 是否被编辑    
    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'IsEdited', '是否被编辑', 0, 1, 0, 0, 1, '', '', '', '', 0, 0, 0, '', '', '', '');

    --2.6 科目名称Code      
    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'CostNameCode', '科目名称', 1, 0, 1, 1, 0, 'vertical-align:middle', '', '', '', 0, 0, 200, '',
            'CostNameCode', 'left', '');

    SET @intRow = @intRow + 1;
    INSERT INTO #MyTemp_Config (id,
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
                                groupName)
    VALUES (@intRow, 'IndexType', '指标类型', 1, 0, 1, 1, 0, 'vertical-align:middle', '', '', '', 0, 0, 200, '',
            'IndexType', 'left', '');

    IF @ProductGUIDParam IS NULL
    OR @ProductGUIDParam = ''
    OR @ProductGUIDParam = '00000000-0000-0000-0000-000000000000'
    BEGIN
        --2.7 指标值   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'IndexValue', '指标值', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0, 120, '',
                'IndexValue', 'Right', '汇总');

        --2.9 系数      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'Coefficient', '系数', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0, 120, '',
                'Coefficient', 'Right', '汇总');

        --2.8 工作量      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'Workload', '工作量', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0, 120, '',
                'Workload', 'Right', '汇总');

        --2.10 目标单价（不含可抵扣税）      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetUnivalence', '目标单价(不含可抵扣税)', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0,
                160, '', 'TargetUnivalence', 'Right', '汇总');

        --2.11 目标成本（不含可抵扣税）      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetCostNoTax', '目标成本(不含可抵扣税)', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0,
                160, '#,##0.00', 'TargetCostNoTax', 'Right', '汇总');

        --2.12 可抵扣税率      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'DeductionRate', '可抵扣税率(%)', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0, 120,
                '', 'DeductionRate', 'Right', '汇总');

        --2.13 可抵扣税额      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'Tax', '可抵扣税额', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        --2.14 目标成本含税金额      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetCost', '目标成本(含税)', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0, 120,
                '#,##0.00', 'TargetCost', 'Right', '汇总');
        --2.14 备注      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'Remark', '备注', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0, 120, '', 'Remark',
                'Left', '汇总');

        --2.14 建筑单方（不含可抵扣税）      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetBuildPrice', '建筑单方（不含可抵扣税）', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0,
                180, '#,##0.00', 'TargetBuildPrice', 'Right', '汇总');

        --2.15 可售单方（不含可抵扣税）   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetSalePrice', '可售单方（不含可抵扣税）', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0,
                180, '#,##0.00', 'TargetSalePrice', 'Right', '汇总');

        --2.16 可售单方（含税）   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetBuildPriceTax', '建筑单方（含税）', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0,
                180, '#,##0.00', 'TargetBuildPriceTax', 'Right', '汇总');

        --2.17 可售单方（含税）   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetSalePriceTax', '可售单方（含税）', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0, 0,
                180, '#,##0.00', 'TargetSalePriceTax', 'Right', '汇总');

    END;
    ELSE
    BEGIN
        --2.7 指标值   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'IndexValue', '指标值', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');


        --2.10 目标单价（不含可抵扣税）      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetUnivalence', '目标单价(不含可抵扣税)', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');


        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetCostNoTax', '目标成本(不含可抵扣税)', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        --2.12 可抵扣税率      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'DeductionRate', '可抵扣税率(%)', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');


        --2.12 工作量      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'Workload', '工作量', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        --2.12 可抵扣税额      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'Tax', '可抵扣税额', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        --2.12 目标成本（含税）  
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'TargetCost', '目标成本（含税）', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        --2.12 备注      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'Remark', '备注', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');
    END;

    --业态属性明细数据                         
    SELECT IDENTITY(INT, 1, 1) AS RowNum,
           ProductYtGUID AS ProductGUID,
           CAST('' AS VARCHAR(100)) AS ProductName,
           CbYtCode AS ProductCode
    INTO   #cb_ProductTemp
      FROM dbo.cb_ProductYt
     WHERE 1 = 2
     ORDER BY ProductCode;

    DECLARE @ProductNum INT;
    DECLARE @ProductGUID UNIQUEIDENTIFIER;
    DECLARE @ProductName VARCHAR(100);
    DECLARE @ProductCode VARCHAR(100);
    DECLARE @strSQL VARCHAR(8000);
    DECLARE @RowCount INT;

    INSERT INTO #cb_ProductTemp (ProductGUID,
                                 ProductName,
                                 ProductCode)
    SELECT a.ProductGUID,
           a.ProductName AS ProductName,
           a.ProductCode
      FROM cb_ExamineCostProductIndex a
     WHERE a.ProjGUID    = @ProjectGUID
       AND a.ProductGUID = @ProductGUIDParam
     ORDER BY a.ProductCode;

    --2.15 产品信息      
    SET @RowCount = 1;
    SELECT @ProductNum = COUNT(1)
      FROM #cb_ProductTemp;
    WHILE @ProductNum >= @RowCount
    BEGIN
        SELECT @ProductGUID = ProductGUID,
               @ProductName = ProductName,
               @ProductCode = ProductCode
          FROM #cb_ProductTemp
         WHERE RowNum = @RowCount;

        --2.7 指标值   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_IndexValue', '指标值', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '',
                '', 0, 0, 120, '', 'p_' + @ProductCode + '_IndexValue', 'Right', @ProductName);

        --2.9 系数      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_Coefficient', '系数', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '',
                '', 0, 0, 120, '', 'p_' + @ProductCode + '_Coefficient', 'Right', @ProductName);

        --2.8 工作量      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_Workload', '工作量', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '',
                0, 0, 120, '', 'p_' + @ProductCode + '_Workload', 'Right', @ProductName);


        --2.10 目标单价（不含可抵扣税）      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_TargetUnivalence', '目标单价(不含可抵扣税)', 0, 0, 1, 0, 0,
                'vertical-align:middle', '', '', '', 0, 0, 180, '', 'p_' + @ProductCode + '_TargetUnivalence', 'Right',
                @ProductName);

        --2.11 目标成本（不含可抵扣税）      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_TargetCostNoTax', '目标成本(不含可抵扣税)', 0, 0, 1, 0, 0,
                'vertical-align:middle', '', '', '', 0, 0, 180, '#,##0.00', 'p_' + @ProductCode + '_TargetCostNoTax',
                'Right', @ProductName);

        --2.12 可抵扣税率    
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_DeductionRate', '可抵扣税率(%)', 0, 0, 1, 0, 0, 'vertical-align:middle',
                '', '', '', 0, 0, 120, '', 'p_' + @ProductCode + '_DeductionRate', 'Right', @ProductName);

        --2.13 可抵扣税额      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_Tax', '可抵扣税额', 0, 1, 0, 0, 0, '', '', '', '', 0, 0, 0, '', '', '', '');

        --2.14 目标成本含税金额      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_TargetCost', '目标成本(含税)', 0, 0, 1, 0, 0, 'vertical-align:middle', '',
                '', '', 0, 0, 120, '#,##0.00', 'p_' + @ProductCode + '_TargetCost', 'Right', @ProductName);

        --2.14 备注      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_Remark', '备注', 0, 0, 1, 0, 0, 'vertical-align:middle', '', '', '', 0,
                0, 120, '', 'p_' + @ProductCode + '_Remark', 'left', @ProductName);


        --2.14 建筑单方（不含可抵扣税）      
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_TargetBuildPrice', '建筑单方（不含可抵扣税）', 0, 0, 1, 0, 0,
                'vertical-align:middle', '', '', '', 0, 0, 180, '#,##0.00', 'p_' + @ProductCode + '_TargetBuildPrice',
                'Right', @ProductName);

        --2.15 可售单方（不含可抵扣税）   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_TargetSalePrice', '可售单方（不含可抵扣税）', 0, 0, 1, 0, 0,
                'vertical-align:middle', '', '', '', 0, 0, 180, '#,##0.00', 'p_' + @ProductCode + '_TargetSalePrice',
                'Right', @ProductName);

        --2.16 可售单方（含税）   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_TargetBuildPriceTax', '建筑单方（含税）', 0, 0, 1, 0, 0,
                'vertical-align:middle', '', '', '', 0, 0, 180, '#,##0.00',
                'p_' + @ProductCode + '_TargetBuildPriceTax', 'Right', @ProductName);

        --2.17 可售单方（含税）   
        SET @intRow = @intRow + 1;
        INSERT INTO #MyTemp_Config (id,
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
                                    groupName)
        VALUES (@intRow, 'p_' + @ProductCode + '_TargetSalePriceTax', '可售单方（含税）', 0, 0, 1, 0, 0,
                'vertical-align:middle', '', '', '', 0, 0, 180, '#,##0.00',
                'p_' + @ProductCode + '_TargetSalePriceTax', 'Right', @ProductName);

        SET @RowCount = @RowCount + 1;
    END;
    IF @ProjectGUID IS NULL
    OR @ProjectGUID = ''
    OR @ProjectGUID = '00000000-0000-0000-0000-000000000000'
    OR @ProjectTargetStage = '00000000-0000-0000-0000-000000000000'
    OR @ProjectTargetStage = ''
    OR @ProjectTargetStage IS NULL
    BEGIN
        SELECT CostGUID,
               TargetCost,
               '' AS CostName,
               CostCode,
               '' AS CostNameCode,
               '' AS ParentCode,
               CostLevel,
               IfEndCost,
               Remarks,
               0 AS TargetBuildPrice,
               0 AS TargetSalePrice,
               0 AS isedit
          FROM cb_Cost
         WHERE 1 = 2;
    END;
    ELSE
    BEGIN
        IF @ProductGUIDParam = ''
        OR @ProductGUIDParam IS NULL
        OR @ProductGUIDParam = '00000000-0000-0000-0000-000000000000'
        BEGIN
            --科目汇总目标成本  
            SELECT      0 AS isEdit,
                        0 AS IsEdited,
                        a.CostGUID,
                        a.CostShortName AS CostName,
                        a.CostCode,
                        (a.CostShortName + '(' + a.CostCode + ')') AS CostNameCode,
                        a.ParentCode,
                        a.CostLevel,
                        a.IfEndCost,
                        CASE
                             WHEN a.IfEndCost = 1 THEN
                                 CONVERT(
                                     VARCHAR(18), CAST(CONVERT(DECIMAL(15, 2), LTRIM(ISNULL(c2.IndexValue, 0))) AS MONEY), 1)
                             ELSE '' END AS IndexValue, --指标值  
                        CASE
                             WHEN a.IfEndCost = 1 THEN
                                 CONVERT(
                                     VARCHAR(18), CAST(CONVERT(DECIMAL(15, 2), LTRIM(ISNULL(c2.[Workload], 0))) AS MONEY), 1)
                             ELSE '' END AS [Workload], --工作量  
                        CASE
                             WHEN a.IfEndCost = 1 THEN
                                 CONVERT(
                                     VARCHAR(30),
                                     CAST(CONVERT(
                                              DECIMAL(18, 2),
                                              LTRIM(
                                                  CASE
                                                       WHEN ISNULL(c2.IndexValue, 0) = 0 THEN 0
                                                       ELSE
                                                           CASE
                                                                WHEN ISNULL(c2.TargetUnivalence, 0) = 0 THEN 0
                                                                ELSE
                                                                    ISNULL(c2.TargetCostNoTax, 0)
                                                                    / ISNULL(c2.TargetUnivalence, 0) END
                                                           / ISNULL(c2.IndexValue, 0) END)) AS MONEY),
                                     1)
                             ELSE '' END AS Coefficient, --系数  
                        CASE
                             WHEN a.IfEndCost = 1 THEN
                                 CONVERT(
                                     VARCHAR(18),
                                     CAST(CONVERT(DECIMAL(15, 2), LTRIM(ISNULL(c2.TargetUnivalence, 0))) AS MONEY),
                                     1)
                             ELSE '' END AS TargetUnivalence, --目标单价（不含可抵扣税）  
                        ISNULL(c2.TargetCost, 0) AS TargetCost, --目标成本含税金额  
                        CASE
                             WHEN a.IfEndCost = 1 THEN
                                 CONVERT(VARCHAR(20), CONVERT(DECIMAL(15, 4), ISNULL(c2.DeductionRate, 0)), 1)
                             ELSE '' END AS DeductionRate, --可抵扣税率  
                        ISNULL(c2.Tax, 0) AS Tax, -- 税额  
                        ISNULL(c2.TargetCostNoTax, 0) AS TargetCostNoTax, --目标成本（不含可抵扣税）  
                        cb_CostSharingSet.SharingMode, --分摊模式  
                        cb_CostSharingSet.AllowModify, --是否允许编辑  
                        c2.IndexType, --指标类型  
                        c2.Remark,
                        CASE
                             WHEN ISNULL(p2.BuildArea, 0) = 0 THEN 0
                             ELSE ISNULL(c2.TargetCostNoTax, 0) / ISNULL(p2.BuildArea, 0) END AS TargetBuildPrice,
                        CASE
                             WHEN ISNULL(p2.SaleArea, 0) = 0 THEN 0
                             ELSE ISNULL(c2.TargetCostNoTax, 0) / ISNULL(p2.SaleArea, 0) END AS TargetSalePrice,
                        CASE
                             WHEN ISNULL(p2.BuildArea, 0) = 0 THEN 0
                             ELSE ISNULL(c2.TargetCost, 0) / ISNULL(p2.BuildArea, 0) END AS TargetBuildPriceTax,
                        CASE
                             WHEN ISNULL(p2.SaleArea, 0) = 0 THEN 0
                             ELSE ISNULL(c2.TargetCost, 0) / ISNULL(p2.SaleArea, 0) END AS TargetSalePriceTax
            INTO        #MyTemp_Data
              FROM      cb_Cost a
             INNER JOIN dbo.p_Project b
                ON b.ProjCode                     = a.ProjectCode
               AND a.BUGUID                       = b.BUGUID
              LEFT JOIN cb_TargetExamineCost c2
                ON c2.CostGUID                    = a.CostGUID
              LEFT JOIN cb_CostSharingSet
                ON dbo.cb_CostSharingSet.CostGUID = a.CostGUID
              LEFT JOIN (   SELECT SUM(BuildArea) AS BuildArea,
                                   SUM(SaleArea) AS SaleArea,
                                   ProjGUID
                              FROM dbo.cb_ExamineCostProductIndex
                             GROUP BY ProjGUID) p2
                ON c2.ProjGUID                    = p2.ProjGUID
             WHERE      b.ProjGUID = @ProjectGUID;

            SELECT *
              FROM #MyTemp_Data
             ORDER BY CostCode;
        END;
        ELSE
        BEGIN
            --科目汇总目标成本  
            SELECT      0 AS isEdit,
                        0 AS IsEdited,
                        a.CostGUID,
                        a.CostShortName AS CostName,
                        a.CostCode,
                        (a.CostShortName + '(' + a.CostCode + ')') AS CostNameCode,
                        a.ParentCode,
                        a.CostLevel,
                        a.IfEndCost,
                        ISNULL(c2.IndexValue, 0) AS IndexValue, --指标值  
                        ISNULL(c2.[Workload], 0) AS [Workload], --工作量  
                        CASE
                             WHEN ISNULL(c2.IndexValue, 0) = 0 THEN 0
                             ELSE
                                 CASE
                                      WHEN ISNULL(c2.TargetUnivalence, 0) = 0 THEN 0
                                      ELSE ISNULL(c2.TargetCostNoTax, 0) / ISNULL(c2.TargetUnivalence, 0) END
                                 / ISNULL(c2.IndexValue, 0) END AS Coefficient, --系数  
                        ISNULL(c2.TargetUnivalence, 0) AS TargetUnivalence, --目标单价（不含可抵扣税）  
                        ISNULL(c2.TargetCostNoTax, 0) AS TargetCostNoTax, --目标成本（不含可抵扣税）  
                        ISNULL(c2.DeductionRate, 0) AS DeductionRate, --可抵扣税率  
                        ISNULL(c2.Tax, 0) AS Tax, -- 税额  
                        ISNULL(c2.TargetCost, 0) AS TargetCost, --目标成本含税金额  
                        cb_CostSharingSet.SharingMode, --分摊模式  
                        cb_CostSharingSet.AllowModify, --是否允许编辑  
                        c2.IndexType, --指标类型					  
                        c2.Remark
            INTO        #MyTemp_Data1
              FROM      cb_Cost a
             INNER JOIN p_Project b
                ON a.ProjectCode              = b.ProjCode
              LEFT JOIN cb_TargetExamineCost c2
                ON a.CostGUID                 = c2.CostGUID
               AND b.ProjGUID                 = c2.ProjGUID
              LEFT JOIN cb_CostSharingSet
                ON cb_CostSharingSet.CostGUID = a.CostGUID
             WHERE      b.ProjGUID = @ProjectGUID;

            SET @RowCount = 1;
            WHILE @ProductNum >= @RowCount
            BEGIN
                SELECT @ProductGUID = ProductGUID,
                       @ProductName = ProductName,
                       @ProductCode = ProductCode
                  FROM #cb_ProductTemp
                 WHERE RowNum = @RowCount;

                SET @strSQL
                    = 'ALTER TABLE #MyTemp_Data1 ADD [p_' + @ProductCode + '_IndexValue] varchar(20),[p_'
                      + @ProductCode + '_Workload] varchar(20),[p_' + @ProductCode + '_Coefficient] varchar(20),[p_'
                      + @ProductCode + '_TargetUnivalence] varchar(20),[p_' + @ProductCode + '_TargetCost] money,[p_'
                      + @ProductCode + '_DeductionRate] varchar(20),[p_' + @ProductCode + '_Tax] money,[p_'
                      + @ProductCode + '_TargetCostNoTax] money,[p_' + @ProductCode + '_TargetBuildPrice] money,[p_'
                      + @ProductCode + '_TargetSalePrice] money,[p_' + @ProductCode + '_TargetBuildPriceTax] money,[p_'
                      + @ProductCode + '_TargetSalePriceTax] money,[p_' + @ProductCode + '_Remark] varchar(200);';

                EXECUTE (@strSQL);

                SET @strSQL
                    = 'UPDATE #MyTemp_Data1 SET [p_' + @ProductCode + '_TargetCost]=0,[p_' + @ProductCode
                      + '_Tax]=0,[p_' + @ProductCode + '_TargetCostNoTax]=0,[p_' + @ProductCode
                      + '_Remark] = '''';        
   UPDATE #MyTemp_Data1 SET [p_' + @ProductCode
                      + '_IndexValue] = CASE WHEN #MyTemp_Data1.IfEndCost = 1 THEN CONVERT(VARCHAR(18),CAST(CONVERT(DECIMAL(15,2),temp.IndexValue) AS MONEY),1) ELSE '''' END ,[p_'
                      + @ProductCode
                      + '_Workload]= CASE WHEN #MyTemp_Data1.IfEndCost = 1 THEN CONVERT(VARCHAR(18),CAST(CONVERT(DECIMAL(15,2),temp.Workload) AS MONEY),1) ELSE '''' END,    
                           [p_' + @ProductCode
                      + '_Coefficient] = CASE WHEN #MyTemp_Data1.IfEndCost = 1 THEN CONVERT(VARCHAR(18),CAST(CONVERT(DECIMAL(15,2),temp.Coefficient) AS MONEY),1) ELSE '''' END,[p_'
                      + @ProductCode
                      + '_TargetUnivalence]= CASE WHEN #MyTemp_Data1.IfEndCost = 1 THEN CONVERT(VARCHAR(18),CAST(CONVERT(DECIMAL(15,2),temp.TargetUnivalence) AS MONEY),1) ELSE '''' END ,[p_'
                      + @ProductCode + '_TargetCost]= temp.TargetCost,[p_' + @ProductCode
                      + '_DeductionRate]=  CASE WHEN #MyTemp_Data1.IfEndCost = 1 THEN CONVERT(VARCHAR(20),CONVERT(DECIMAL(15,4),temp.DeductionRate))  ELSE '''' END,[p_'
                      + @ProductCode + '_Tax]= temp.Tax,[p_' + @ProductCode
                      + '_TargetCostNoTax]= temp.TargetCostNoTax,[p_' + @ProductCode
                      + '_TargetBuildPrice]= temp.TargetBuildPrice,[p_' + @ProductCode
                      + '_TargetSalePrice]= temp.TargetSalePrice,[p_' + @ProductCode
                      + '_TargetBuildPriceTax]= temp.TargetBuildPriceTax,[p_' + @ProductCode
                      + '_TargetSalePriceTax]= temp.TargetSalePriceTax,[p_' + @ProductCode
                      + '_Remark]= temp.Remark       
   FROM #MyTemp_Data1 inner join ( SELECT b.CostGUID,ISNULL(b.IndexValue, 0) AS IndexValue ,   
                                ISNULL(b.[Workload], 0) AS [Workload] ,   
                                CASE WHEN ISNULL(css.SharingMode,'''') <> ''按指定金额'' THEN   
         Round(CASE WHEN ISNULL(tsc.IndexValue, 0) = 0 OR ISNULL(tsc.TargetUnivalence,  
                  0) = 0 THEN 0  
           ELSE ISNULL(tsc.TargetCostNoTax, 0)  
              / ISNULL(tsc.TargetUnivalence,  
                 0)  
              / ISNULL(tsc.IndexValue, 0)  
         END,2)  
                                ELSE                                                                  
         Round(CASE WHEN ISNULL(b.IndexValue, 0) = 0 OR ISNULL(b.TargetUnivalence,  
                  0) = 0 THEN 0  
           ELSE  ISNULL(b.TargetCostNoTax, 0)  
              / ISNULL(b.TargetUnivalence,  
                 0)  
              / ISNULL(b.IndexValue, 0)  
         END ,2)  
                                END AS Coefficient , --系数  
                                ISNULL(b.TargetUnivalence, 0) AS TargetUnivalence , --目标单价（不含可抵扣税）  
                                ISNULL(b.TargetCost, 0) AS TargetCost , --目标成本含税金额  
                                ISNULL(b.DeductionRate, 0) AS DeductionRate , --可抵扣税率  
                                ISNULL(b.Tax, 0) AS Tax , -- 税额  
                                ISNULL(b.TargetCostNoTax, 0) AS TargetCostNoTax, --目标成本（不含可抵扣税）,  
                                CASE WHEN ISNULL(prod.BuildArea, 0) = 0 THEN 0 ELSE ISNULL(b.TargetCostNoTax, 0) / ISNULL(prod.BuildArea, 0) END AS TargetBuildPrice ,  
        CASE WHEN ISNULL(prod.SaleArea, 0) = 0 THEN 0 ELSE ISNULL(b.TargetCostNoTax, 0) / ISNULL(prod.SaleArea, 0) END AS TargetSalePrice,     
        CASE WHEN ISNULL(prod.BuildArea, 0) = 0 THEN 0 ELSE ISNULL(b.TargetCost, 0) / ISNULL(prod.BuildArea, 0) END AS TargetBuildPriceTax ,  
        CASE WHEN ISNULL(prod.SaleArea, 0) = 0 THEN 0 ELSE ISNULL(b.TargetCost, 0) / ISNULL(prod.SaleArea, 0) END AS TargetSalePriceTax ,                   
                                b.Remark  
                                  FROM  cb_TargetExamineProductCost b INNER JOIN p_Project p ON p.ProjGUID = b.ProjGUID                                     
                                  LEFT JOIN cb_ExamineCostProductIndex prod ON prod.ProductGUID = b.ProductGUID   
                                  LEFT JOIN cb_TargetExamineCost tsc ON tsc.CostGUID = b.CostGUID AND tsc.ProjGUID = b.ProjGUID  
                                  LEFT JOIN cb_CostSharingSet css ON css.CostGUID = b.CostGUID  
                                  WHERE b.ProductGUID=''' + CONVERT(VARCHAR(40), @ProductGUID) + ''' AND b.ProjGUID='''
                      + @ProjectGUID + ''') temp on #MyTemp_Data1.CostGUID=temp.CostGUID    
  '             ;

                PRINT @strSQL;
                EXECUTE (@strSQL);

                SET @RowCount = @RowCount + 1;
            END;
            SELECT *
              FROM #MyTemp_Data1
             ORDER BY CostCode;
        END;
    END;
END;

--3.2）返回数据集      


--3.3）返回数据展示集      
SELECT *
  FROM #MyTemp_Config
 ORDER BY id;

DROP TABLE #cb_ProductTemp;
--DROP TABLE #MyTemp_Data    
DROP TABLE #MyTemp_Config;
