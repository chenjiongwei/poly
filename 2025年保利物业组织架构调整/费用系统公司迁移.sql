SELECT sys.objects.name 表名 ,
       sys.columns.name  字段名称,
       sys.types.name 数据类型,
       sys.columns.max_length 长度
FROM   sys.objects
       LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
       LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
WHERE  -- sys.objects.name like '%fy_%' AND  
       sys.objects.type = 'U'
       AND ( sys.columns.name like '%HierarchyCode%' or sys.columns.name like '%BUFullName%'  ) 
          ORDER BY sys.objects.name,sys.columns.column_id




--// 如果出现费用系统的组织架构表同采购系统组织架构表不一致的情况，进行对比修复
-- 创建临时表#bu，存储两个数据库中myBusinessUnit表的差异数据
SELECT bu.* INTO #bu FROM (
    SELECT * FROM [dotnet_erp60_test].dbo.myBusinessUnit 
    EXCEPT 
    SELECT * FROM [dotnet_erp60_test_fy].dbo.myBusinessUnit 
) bu 
WHERE 1=1; -- 无条件过滤，确保所有数据都被选中

-- 备份[dotnet_erp60_test_fy].dbo.myBusinessUnit表到myBusinessUnit_fy_bak0331
SELECT * INTO myBusinessUnit_fy_bak0331 FROM [dotnet_erp60_test_fy].dbo.myBusinessUnit;

-- 从[dotnet_erp60_test_fy].dbo.myBusinessUnit表中删除存在于#bu表中的数据
DELETE FROM [dotnet_erp60_test_fy].dbo.myBusinessUnit
WHERE buguid IN (SELECT BUGUID FROM #bu);

-- 将#bu表中的数据插入到[dotnet_erp60_test_fy].dbo.myBusinessUnit表中
INSERT INTO [dotnet_erp60_test_fy].dbo.myBusinessUnit
SELECT * FROM #bu;


-- cb_BuildStandardModule
-- cb_CashFlowItem
-- cb_PayApprovalTypeGroup
-- 集团管理科目
-- fy_BzCost
--财务科目表
-- fy_BzFinanceCost
-- 公司管理科目
--fy_Cost
-- 财务科目
-- fy_FinanceCost
-- 付款审批类型
-- fy_PayApprovalType
--付款审批类型
-- fy_PayApprovalTypeGroup

-- 年度预算平衡表
-- fy_YearBudgetPoise

BEGIN
    -- 定义变量
    declare @BUGUID varchar(50) -- 调整公司的BUGUID
    declare @OldHierarchyCode varchar(2000) -- 调整前的HierarchyCode
    declare @NewHierarchyCode varchar(2000) -- 调整后的HierarchyCode
    declare @OldBUFullName varchar(2000) -- 调整前的BUFullName
    declare @NewBUFullName varchar(2000) -- 调整后的BUFullName


    set @BUGUID = select buguid from myBusinessUnit where BUName = '新疆物业'

    
    IF NOT EXISTS (SELECT * FROM myBusinessUnitChange20250321 WHERE buguid = @BUGUID)
    BEGIN
        RETURN;
    END;

    -- 查询调整后的组织架构表
    SELECT @OldHierarchyCode = HierarchyCode, @OldBUFullName = BUFullName 
    FROM myBusinessUnitChange20250321 WHERE buguid = @BUGUID;
    -- 查询调整后的组织架构表
    select @NewHierarchyCode = HierarchyCode, @NewBUFullName = BUFullName 
    from  myBusinessUnit where buguid = @BUGUID

    -- 费用承担主体 需要修改
    IF OBJECT_ID(N'fy_SpecialBusinessUnit_bak_20250331', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.fy_SpecialBusinessUnit_bak_20250331
        FROM    dbo.fy_SpecialBusinessUnit a
        where   a.BUGUID = @BUGUID 

        UPDATE  a
        SET a.HierarchyCode = replace(a.HierarchyCode,@OldHierarchyCode,@NewHierarchyCode)
        FROM    fy_SpecialBusinessUnit a
        where   a.BUGUID = @BUGUID and  @OldHierarchyCode is not null

    PRINT '费用承担主体:fy_SpecialBusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


-- select SpecialBusinessUnitFullName, HierarchyCode,BUGUID,BUNames,x_BelongDeptCode,
-- x_BelongDeptGUID,
-- x_BelongDeptName
-- from  fy_SpecialBusinessUnit  
-- where  BUGUID ='7D8FACB6-BFFC-42DC-F8FC-08D913E5D9C5'

END   
        


-- select BUGUID,BUCode,BUName,BUFullName,HierarchyCode from  dotnet_erp60_fy.dbo.myBusinessUnit a
-- except
-- select BUGUID,BUCode,BUName,BUFullName,HierarchyCode from  [172.31.8.106].[dotnet_erp60_cz].dbo.myBusinessUnit b