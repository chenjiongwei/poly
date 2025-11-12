USE [MyCost_Erp352]
GO

/*
   分期数据迁移脚本
*/

-- EXEC usp_cb_ChgProjMoveFq 
--     'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 新公司GUID
--     'EE94E591-2916-4400-AD9B-9073B36FCD03',    -- 旧公司GUID
--     '0E63E1AD-4703-4A95-B661-9E8E415E041F'   -- 分期项目GUID


create or ALTER  PROC [dbo].[usp_cb_ChgProjMoveFq]
    (
      @BuGUIDNew UNIQUEIDENTIFIER ,
      @BuGUIDOld UNIQUEIDENTIFIER ,
      @ProjGUID UNIQUEIDENTIFIER  --分期项目GUID
--       @ProjCode VARCHAR(50), --老一级项目code
--       @NewProjCode VARCHAR(50) --新一级项目code
    )
AS
BEGIN

      SET NOCOUNT OFF;
-----------主数据
--DECLARE @BuGUIDNew  UNIQUEIDENTIFIER --新公司GUID
--DECLARE @BuGUIDOld  UNIQUEIDENTIFIER --旧公司GUID
--DECLARE @ProjGUID   UNIQUEIDENTIFIER  --迁移项目GUID
--DECLARE @ProjCode   VARCHAR(50)  --迁移项目编码
        DECLARE @BUCodeNew VARCHAR(50);  --新公司编码
        DECLARE @BUCodeOld VARCHAR(50);  --旧公司编码
--DECLARE @ProjShortCodeMaxNew   VARCHAR(50) --新公司一级项目简编码+1

        --DECLARE @NewProjCode VARCHAR(50);  --新项目编码
        --DECLARE @ProjShor
--获取新公司编码
        SELECT  @BUCodeNew = BUCode
        FROM    dbo.myBusinessUnit
        WHERE   BUGUID = @BuGUIDNew;

        SELECT  @BUCodeOld = BUCode
        FROM    dbo.myBusinessUnit
        WHERE   BUGUID = @BuGUIDOld;


        SELECT  @BUCodeOld = BUCode
        FROM    dbo.myBusinessUnit
        WHERE   BUGUID = @BuGUIDOld;

        -- 定义变量
        DECLARE @OldTopProjCode VARCHAR(50); -- 老一级项目code
        DECLARE @NewTopProjCode VARCHAR(50); -- 新一级项目code
        DECLARE @OldTopProjName VARCHAR(50); -- 老一级项目名称
        DECLARE @NewTopProjName VARCHAR(50); -- 新一级项目名称
        DECLARE @OldTopProjGUID UNIQUEIDENTIFIER; -- 老一级项目GUID
        DECLARE @NewTopProjGUID UNIQUEIDENTIFIER; -- 新一级项目GUID

        SELECT 
            @OldTopProjCode = OldParentprojCode352,
            @NewTopProjCode = NewParentprojCode352,
            @OldTopProjGUID = OldParentprojguid,
            @NewTopProjGUID = NewParentprojguid,
            @OldTopProjName = (
                SELECT TOP 1 ProjName 
                FROM p_project 
                WHERE level = 2 
                  AND ProjGUID = OldParentprojguid
            ),
            @NewTopProjName = (
                SELECT TOP 1 ProjName 
                FROM p_project 
                WHERE level = 2 
                  AND ProjGUID = NewParentprojguid
            )
        FROM dqy_proj_20251027 AS a
        WHERE OldProjGuid = @ProjGUID;

        -- select  * into   from  dqy_proj_20251027

--保存更新前的 p_Project
        SELECT  *
        INTO    #TbTemp_p_Project
        FROM    dbo.p_Project;

--查询一级项目下的所有分期
        SELECT  ROW_NUMBER() OVER ( ORDER BY ProjGUID ) AS Rowid ,
                ProjGUID ,
                ProjCode
        INTO    #tempproject
        FROM    #TbTemp_p_Project
        WHERE   ProjGUID = @ProjGUID
        --WHERE   ParentCode IN ( SELECT  ProjCode
        --                        FROM    #TbTemp_p_Project
        --                        WHERE   ProjGUID = @ProjGUID );

----1.1 更新项目（执行表）
--        UPDATE  p_Project
--        SET     BUGUID = @BuGUIDNew ,
--                ParentCode = @BUCodeNew ,
--                ProjCode = @NewProjCode ,
--                ProjShortCode = @ProjShortCodeMaxNew
--        WHERE   ProjGUID IN ( @ProjGUID );
                      
                    
----1.2 更新项目（编制表）
--        UPDATE  p_HkbProjectWork
--        SET     BUGUID = @BuGUIDNew ,
--                ParentCode = @BUCodeNew ,
--                ProjCode = @NewProjCode ,
--                ProjShortCode = @ProjShortCodeMaxNew
--        WHERE   ProjGUID IN ( @ProjGUID );


----1.3 更新项目（审批表）                      
--        UPDATE  dbo.p_HkbApprove
--        SET     BUGUID = @BuGUIDNew ,
--                ProjInfo = REPLACE(ProjInfo, @BuGUIDOld, @BuGUIDNew)
--        WHERE   HkbApproveGUID IN ( SELECT  HkbApproveGUID
--                                    FROM    p_HkbProjectCompare
--                                    WHERE   ProjGUID IN ( @ProjGUID ) );

----1.4 更新项目（对比表）                       
--        UPDATE  dbo.p_HkbProjectCompare
--        SET     BUGUID = @BuGUIDNew ,
--                ParentCode = @BUCodeNew ,
--                ProjCode = @NewProjCode ,
--                ProjShortCode = @ProjShortCodeMaxNew
--        WHERE   ProjGUID IN ( @ProjGUID );
                      
----1.5 更新项目（历史表）
                   
--        UPDATE  dbo.p_HkbProjectHistory
--        SET     BUGUID = @BuGUIDNew ,
--                ParentCode = @BUCodeNew ,
--                ProjCode = @NewProjCode ,
--                ProjShortCode = @ProjShortCodeMaxNew
--        WHERE   ProjGUID IN ( @ProjGUID );                 


--2.0二级项目分期数据 迁移
--SELECT * FROM p_project WHERE ParentCode='01.002'
--SELECT * FROM p_project WHERE ParentCode=@ProjCode


--2.1 更新项目（执行表）
       
        UPDATE  p_Project
        SET     BUGUID = @BuGUIDNew ,
                ParentCode = @NewTopProjCode ,
                ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode),
                ProjName = REPLACE(ProjName, @OldTopProjName, @NewTopProjName)
        WHERE  ProjGUID IN ( @ProjGUID );

        PRINT N'更新项目表:p_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

                  
--2.2 更新项目（编制表）
        UPDATE  p_HkbProjectWork
        SET     BUGUID = @BuGUIDNew ,
                ParentCode = @NewTopProjCode ,
                ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode),
                ProjName = REPLACE(ProjName, @OldTopProjName, @NewTopProjName)
        WHERE   ProjGUID IN ( @ProjGUID);

        PRINT N'更新项目编制表:p_HkbProjectWork' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

--2.3 更新项目（审批表）                      
        UPDATE  dbo.p_HkbApprove
        SET     BUGUID = @BuGUIDNew ,
                ProjInfo = REPLACE( REPLACE(ProjInfo, @BuGUIDOld, @BuGUIDNew), @OldTopProjGUID,@NewTopProjGUID)
        WHERE   HkbApproveGUID IN (
                SELECT  HkbApproveGUID
                FROM    p_HkbProjectCompare
                WHERE   ProjGUID IN ( @ProjGUID ));

        PRINT N'更新项目审批表:p_HkbApprove' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

--2.4 更新项目（对比表）                       
        UPDATE  dbo.p_HkbProjectCompare
        SET     BUGUID = @BuGUIDNew ,
                ParentCode = @NewTopProjCode ,
                ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode),
                ProjName = REPLACE(ProjName, @OldTopProjName, @NewTopProjName)
        WHERE   ProjGUID IN ( @ProjGUID );

        PRINT N'更新项目对比表:p_HkbProjectCompare' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

--PRINT  @BuGUIDNew   
--PRINT  @NewProjCode   
                      
--2.5 更新项目（历史表）                      
        UPDATE  dbo.p_HkbProjectHistory
        SET     BUGUID = @BuGUIDNew ,
                ParentCode = @NewTopProjCode ,
                ProjCode = REPLACE(ProjCode, @OldTopProjCode, @NewTopProjCode),
                ProjName = REPLACE(ProjName, @OldTopProjName, @NewTopProjName)
        WHERE   ProjGUID IN ( @ProjGUID );
           
        PRINT N'更新项目历史表:p_HkbProjectHistory' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  
----------业务参数
--        SELECT  *
--        FROM    dbo.myBizParamRegist
--        WHERE   Scope = '公司'
--                AND ParamType <> '参数配置'
--                AND ( ParamName LIKE 'Cb_%' ); 

----  cb_AlterInvolveMajor  变更涉及专业
--        DELETE  myBizParamOption
--        WHERE   ParamName = 'cb_AlterInvolveMajor'
--                AND ScopeGUID = @BuGUIDNew;

--        INSERT  INTO myBizParamOption
--                ( ParamName ,
--                  ScopeGUID ,
--                  ParamValue ,
--                  ParamCode ,
--                  ParentCode ,
--                  ParamLevel ,
--                  IfEnd ,
--                  IfSys ,
--                  ParamGUID
--                )
--                SELECT  ParamName ,
--                        @BuGUIDNew ,
--                        ParamValue ,
--                        ParamCode ,
--                        ParentCode ,
--                        ParamLevel ,
--                        IfEnd ,
--                        IfSys ,
--                        NEWID()
--                FROM    myBizParamOption
--                WHERE   ParamName = 'cb_AlterInvolveMajor'
--                        AND ScopeGUID = @BuGUIDOld;
      
-------   cb_AlterTypeAndAlterReason   变更类型及变更原因
--        DELETE  myBizParamOption
--        WHERE   ParamName = 'cb_AlterTypeAndAlterReason'
--                AND ScopeGUID = @BuGUIDNew;

--        INSERT  INTO myBizParamOption
--                ( ParamName ,
--                  ScopeGUID ,
--                  ParamValue ,
--                  ParamCode ,
--                  ParentCode ,
--                  ParamLevel ,
--                  IfEnd ,
--                  IfSys ,
--                  ParamGUID
--                )
--                SELECT  ParamName ,
--                        @BuGUIDNew ,
--                        ParamValue ,
--                        ParamCode ,
--                        ParentCode ,
--                        ParamLevel ,
--                        IfEnd ,
--                        IfSys ,
--                        NEWID()
--                FROM    myBizParamOption
--                WHERE   ParamName = 'cb_AlterTypeAndAlterReason'
--                        AND ScopeGUID = @BuGUIDOld;
       
-------  cb_Bank    财务接口付款银行    
--        DELETE  cb_Bank
--        WHERE   BUGUID = @BuGUIDNew;
    
--        INSERT  INTO cb_Bank
--                ( BankGUID ,
--                  BUGUID ,
--                  BankName ,
--                  BankKH ,
--                  BankCode ,
--                  IfSys
--                )
--                SELECT  NEWID() ,
--                        @BuGUIDNew ,
--                        BankName ,
--                        BankKH ,
--                        BankCode ,
--                        IfSys
--                FROM    cb_Bank
--                WHERE   BUGUID = @BuGUIDOld;   
       
-------  cb_CodeFormat  编码规则设置
--        DELETE  cb_CodeFormat
--        WHERE   BUGUID = @BuGUIDNew;

--        INSERT  INTO cb_CodeFormat
--                ( CodeFormatGUID ,
--                  BUGUID ,
--                  CodeType ,
--                  Num ,
--                  FieldNameChn ,
--                  LevelLimit ,
--                  IfIncluded ,
--                  IfRestore ,
--                  Separator ,
--                  ExampleData
--                )
--                SELECT  NEWID() ,
--                        @BuGUIDNew ,
--                        CodeType ,
--                        Num ,
--                        FieldNameChn ,
--                        LevelLimit ,
--                        IfIncluded ,
--                        IfRestore ,
--                        Separator ,
--                        ExampleData
--                FROM    cb_CodeFormat
--                WHERE   BUGUID = @BuGUIDOld;



-------  cb_FinanceJsParam   结算方式
--        DELETE  myBizParamOption
--        WHERE   ParamName = 'cb_FinanceJsParam'
--                AND ScopeGUID = @BuGUIDNew;

--        INSERT  INTO myBizParamOption
--                ( ParamName ,
--                  ScopeGUID ,
--                  ParamValue ,
--                  ParamCode ,
--                  ParentCode ,
--                  ParamLevel ,
--                  IfEnd ,
--                  IfSys ,
--                  ParamGUID
--                )
--                SELECT  ParamName ,
--                        @BuGUIDNew ,
--                        ParamValue ,
--                        ParamCode ,
--                        ParentCode ,
--                        ParamLevel ,
--                        IfEnd ,
--                        IfSys ,
--                        NEWID()
--                FROM    myBizParamOption
--                WHERE   ParamName = 'cb_FinanceJsParam'
--                        AND ScopeGUID = @BuGUIDOld;
       
       
------  cb_FKSPType    付款审批类型设置
--        DELETE  cb_FKSPType
--        WHERE   BUGUID = @BuGUIDNew;

--        INSERT  INTO cb_FKSPType
--                ( FKSPTypeGUID ,
--                  FKSPTypeCode ,
--                  FKSPTypeName ,
--                  FKSPClass ,
--                  BUGUID ,
--                  ProcessGUID ,
--                  Remarks
--                )
--                SELECT  NEWID() ,
--                        FKSPTypeCode ,
--                        FKSPTypeName ,
--                        FKSPClass ,
--                        @BuGUIDNew ,
--                        ProcessGUID ,
--                        Remarks
--                FROM    cb_FKSPType
--                WHERE   BUGUID = @BuGUIDOld;


------  cb_FundParam   款项类型及款项名称
--        DELETE  myBizParamOption
--        WHERE   ParamName = 'cb_FundParam'
--                AND ScopeGUID = @BuGUIDNew;

--        INSERT  INTO myBizParamOption
--                ( ParamName ,
--                  ScopeGUID ,
--                  ParamValue ,
--                  ParamCode ,
--                  ParentCode ,
--                  ParamLevel ,
--                  IfEnd ,
--                  IfSys ,
--                  ParamGUID
--                )
--                SELECT  ParamName ,
--                        @BuGUIDNew ,
--                        ParamValue ,
--                        ParamCode ,
--                        ParentCode ,
--                        ParamLevel ,
--                        IfEnd ,
--                        IfSys ,
--                        NEWID()
--                FROM    myBizParamOption
--                WHERE   ParamName = 'cb_FundParam'
--                        AND ScopeGUID = @BuGUIDOld;


------  cb_KkType   设置扣款类型
--        DELETE  myBizParamOption
--        WHERE   ParamName = 'cb_KkType'
--                AND ScopeGUID = @BuGUIDNew;

--        INSERT  INTO myBizParamOption
--                ( ParamName ,
--                  ScopeGUID ,
--                  ParamValue ,
--                  ParamCode ,
--                  ParentCode ,
--                  ParamLevel ,
--                  IfEnd ,
--                  IfSys ,
--                  ParamGUID
--                )
--                SELECT  ParamName ,
--                        @BuGUIDNew ,
--                        ParamValue ,
--                        ParamCode ,
--                        ParentCode ,
--                        ParamLevel ,
--                        IfEnd ,
--                        IfSys ,
--                        NEWID()
--                FROM    myBizParamOption
--                WHERE   ParamName = 'cb_KkType'
--                        AND ScopeGUID = @BuGUIDOld;

------  cb_PjType   票据类型
--        DELETE  myBizParamOption
--        WHERE   ParamName = 'cb_PjType'
--                AND ScopeGUID = @BuGUIDNew;

--        INSERT  INTO myBizParamOption
--                ( ParamName ,
--                  ScopeGUID ,
--                  ParamValue ,
--                  ParamCode ,
--                  ParentCode ,
--                  ParamLevel ,
--                  IfEnd ,
--                  IfSys ,
--                  ParamGUID
--                )
--                SELECT  ParamName ,
--                        @BuGUIDNew ,
--                        ParamValue ,
--                        ParamCode ,
--                        ParentCode ,
--                        ParamLevel ,
--                        IfEnd ,
--                        IfSys ,
--                        NEWID()
--                FROM    myBizParamOption
--                WHERE   ParamName = 'cb_PjType'
--                        AND ScopeGUID = @BuGUIDOld;


------  cb_ProductProject   标段
--        DELETE  cb_ProductProject
--        WHERE   BUGUID = @BuGUIDNew;

--        INSERT  INTO cb_ProductProject
--                ( ProductProjectGUID ,
--                  BUGUID ,
--                  ProductProjectShortCode ,
--                  ProductProjectCode ,
--                  ProductProjectShortName ,
--                  ProductProjectName ,
--                  ParentCode ,
--                  Level ,
--                  IfEnd ,
--                  Remarks ,
--                  IsFromDs
--                )
--                SELECT  NEWID() ,
--                        @BuGUIDNew ,
--                        ProductProjectShortCode ,
--                        ProductProjectCode ,
--                        ProductProjectShortName ,
--                        ProductProjectName ,
--                        ParentCode ,
--                        Level ,
--                        IfEnd ,
--                        Remarks ,
--                        IsFromDs
--                FROM    cb_ProductProject
--                WHERE   BUGUID = @BuGUIDOld;

   
-------    cb_Tax   印花税税目设置
--        DELETE  cb_Tax
--        WHERE   BUGUID = @BuGUIDNew;

--        INSERT  INTO cb_Tax
--                ( TaxGUID ,
--                  BUGUID ,
--                  TaxName ,
--                  TaxRate ,
--                  TaxRange ,
--                  TaxObligor ,
--                  Remarks
--                )
--                SELECT  NEWID() ,
--                        @BuGUIDNew ,
--                        TaxName ,
--                        TaxRate ,
--                        TaxRange ,
--                        TaxObligor ,
--                        Remarks
--                FROM    cb_Tax
--                WHERE   BUGUID = @BuGUIDOld;

   
------  cg_p_GradePG     定级得分权重设置
--DELETE cg_p_GradePGSetting WHERE BUGUID=@BuGUIDNew

--INSERT  INTO cg_p_GradePGSetting
--        ( GradePGSettingGUID ,
--          Rate ,
--          GradePGName ,
--          SortNum ,
--          BUGUID
--        )
--        SELECT  NEWID() ,
--                Rate ,
--                GradePGName ,
--                SortNum ,
--                @BuGUIDNew
--        FROM    cg_p_GradePGSetting
--        WHERE   BUGUID = @BuGUIDOld;


------  cg_ProcDataAuthorSetting  采购过程数据查看授
------------------------------------ 业务数据
        -- SELECT DISTINCT
        --         a.表名
        -- FROM    ( SELECT    sys.objects.name 表名
        --           FROM      sys.objects
        --                     JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
        --           WHERE     sys.columns.name LIKE '%proj%'
        --                     AND sys.objects.type = 'U'
        --                     AND sys.objects.name LIKE 'cb_%'
        --         ) a ,
        --         ( SELECT    sys.objects.name 表名
        --           FROM      sys.objects
        --                     JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
        --           WHERE     sys.columns.name = 'buguid'
        --                     AND sys.objects.type = 'U'
        --                     AND sys.objects.name LIKE 'cb_%'
        --         ) b
        -- WHERE   a.表名 = b.表名;

---- cb_Bid  招投标管理表
        ALTER TABLE cb_Bid DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Bid_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_Bid_bak_20251027
            FROM    dbo.cb_Bid
            where cb_Bid.ProjGUID =@ProjGUID;

        UPDATE  cb_Bid
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '招投标管理表:cb_Bid' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_Bid ENABLE TRIGGER ALL;

---- cb_Budget 合约规划表
        ALTER TABLE cb_Budget DISABLE TRIGGER ALL;   
        IF OBJECT_ID(N'cb_Budget_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_Budget_bak_20251027
            FROM    dbo.cb_Budget
            where cb_Budget.ProjectGUID =@ProjGUID;

        UPDATE  cb_Budget
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjectGUID IN (SELECT  @ProjGUID );
 
        ALTER TABLE cb_Budget ENABLE TRIGGER ALL;
 
 ----- cb_Budget_Executing  新合约规划执行表
        ALTER TABLE cb_Budget_Executing DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Budget_Executing_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_Budget_Executing_bak_20251027
            FROM    dbo.cb_Budget_Executing
            where  ProjectGUID IN (SELECT  @ProjGUID );
 
        UPDATE  cb_Budget_Executing
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjectGUID IN (SELECT  @ProjGUID );

        PRINT '新合约规划执行表:cb_Budget_Executing' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_Budget ENABLE TRIGGER ALL;

---- cb_Budget_Working   新合约规划编制表
        ALTER TABLE cb_Budget_Working DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Budget_Working_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_Budget_Working_bak_20251027
            FROM    dbo.cb_Budget_Working
            where  ProjectGUID IN (SELECT  @ProjGUID );

        UPDATE  cb_Budget_Working
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjectGUID IN ( SELECT  @ProjGUID );

        PRINT '新合约规划编制表:cb_Budget_Working' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_Budget_Working ENABLE TRIGGER ALL;

----- cb_BudgetUse  合约规划使用表
        ALTER TABLE cb_BudgetUse DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_BudgetUse_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_BudgetUse_bak_20251027
            FROM    dbo.cb_BudgetUse a
            LEFT JOIN #TbTemp_p_Project B ON a.ProjectCode = B.ProjCode
            where  b.ProjGUID IN (SELECT  @ProjGUID );

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_BudgetUse A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );		

        PRINT '合约规划使用表:cb_BudgetUse' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_BudgetUse ENABLE TRIGGER ALL;
		
---- cb_Contract  合同管理表
        ALTER TABLE cb_Contract DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Contract_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_Contract_bak_20251027
            FROM    dbo.cb_Contract a
            INNER JOIN cb_ContractProj b ON a.ContractGUID = b.ContractGUID
            where  b.ProjGUID IN (SELECT  @ProjGUID );

        DECLARE @count INT;	
        SELECT  @count = COUNT(*)
        FROM    #tempproject;
        
        DECLARE @i INT;
        SET @i = 1;
        WHILE @i <= @count
            BEGIN
                DECLARE @guidProjGUID AS UNIQUEIDENTIFIER;
                DECLARE @OldProjCode AS VARCHAR(100);
		 
                SELECT  @guidProjGUID = ProjGUID ,
                        @OldProjCode = ProjCode
                FROM    #tempproject
                WHERE   Rowid = @i;
				
        --PRINT @i
        --PRINT @guidProjGUID
        --PRINT @OldProjCode
        --PRINT @BuGUIDNew
				
                EXEC usp_p_UpdateProjCodeAndBuguid_Cbgl @guidProjGUID,
                    @OldProjCode, @BuGUIDNew;
                SET @i = @i + 1;
            END;

        PRINT '合同管理表:cb_Contract' 
        ALTER TABLE cb_Contract ENABLE TRIGGER ALL;

 

---- cb_Cost 成本科目设置表
        ALTER TABLE cb_Cost DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Cost_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_Cost_bak_20251027
            FROM    dbo.cb_Cost  a
            LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
            where c.ProjGUID in ( SELECT  @ProjGUID )


        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_Cost A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );	

        print '成本科目设置表:cb_Cost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_Cost ENABLE TRIGGER ALL;

----  cb_CostControlSet  成本控制指标设置表
        ALTER TABLE cb_CostControlSet DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_CostControlSet_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_CostControlSet_bak_20251027
            FROM    dbo.cb_CostControlSet
            where  ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_CostControlSet
        SET     Buguid = @BuGUIDNew
        WHERE   ProjGUID IN ( SELECT  @ProjGUID );	

        print '成本控制指标设置表:cb_CostControlSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_CostControlSet ENABLE TRIGGER ALL;

---- cb_CostPlan 成本保存方案表
        ALTER TABLE cb_CostPlan DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_CostPlan_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_CostPlan_bak_20251027
            FROM    dbo.cb_CostPlan
            where  ProjectGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_CostPlan A
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = A.ProjectGUID
        WHERE   C.ProjGUID IN (SELECT  @ProjGUID );	

        print '成本保存方案表:cb_CostPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_CostPlan ENABLE TRIGGER ALL;

---- cb_CostStationRights  科目岗位权限表
        ALTER TABLE cb_CostStationRights DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_CostStationRights_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_CostStationRights_bak_20251027
            FROM    dbo.cb_CostStationRights
            where  ProjGuid in ( SELECT  @ProjGUID )

        UPDATE  cb_CostStationRights
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGuid IN ( SELECT  @ProjGUID );	

        print '科目岗位权限表:cb_CostStationRights' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
 
        ALTER TABLE cb_CostStationRights ENABLE TRIGGER ALL;

---- cb_costVersion   历史科目版表
        ALTER TABLE cb_costVersion DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_costVersion_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_costVersion_bak_20251027
            FROM    dbo.cb_costVersion a
            LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
            where  C.ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_costVersion A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );		

        print '历史科目版表:cb_costVersion' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_costVersion ENABLE TRIGGER ALL;

------ cb_DesignAlter  设计变更
--ALTER TABLE cb_DesignAlter DISABLE TRIGGER ALL   

--if object_id(N'cb_DesignAlter_bak_20251027',N'U') is null
--SELECT *
--INTO dbo.cb_DesignAlter_bak_20251027
--FROM dbo.cb_DesignAlter; 

--UPDATE  A
--SET     A.ProjCodeList = REPLACE(A.ProjCodeList, B.ProjCode + ';',
--                                    C.ProjCode + ';') ,
--        A.ProjectInfo = REPLACE(A.ProjectInfo, B.ProjName + ',',
--                                    C.ProjName + ',') ,
--        BUGUID = @BuGUIDNew
--FROM    cb_DesignAlter A
--        LEFT JOIN #TbTemp_p_Project B ON A.ProjCodeList LIKE '%'
--                                         + B.ProjCode + ';%'
--        LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
--WHERE   B.ProjCode IS NOT NULL
--        AND C.ProjGUID = @ProjGUID;	

-- ALTER TABLE cb_DesignAlter ENABLE TRIGGER ALL


---- cb_DTCostRecollect  动态成本月度回顾报告主表
        ALTER TABLE cb_DTCostRecollect DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_DTCostRecollect_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_DTCostRecollect_bak_20251027
            FROM    dbo.cb_DTCostRecollect a
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectGUID = B.ProjGUID
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
                where C.ProjGUID in ( SELECT  @ProjGUID )
        
        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                A.ProjectName = C.ProjName ,
                BUGUID = @BuGUIDNew
        FROM    cb_DTCostRecollect A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectGUID = B.ProjGUID
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );
        
        PRINT '动态成本月度回顾报告主表:cb_DTCostRecollect' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_DTCostRecollect ENABLE TRIGGER ALL;

---- cb_DtCostRecollectCost  动态成本回顾科目信息
        ALTER TABLE cb_DtCostRecollectCost DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_DtCostRecollectCost_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_DtCostRecollectCost_bak_20251027
            FROM    dbo.cb_DtCostRecollectCost a
            LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
            where C.ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_DtCostRecollectCost A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );	

        
        PRINT '动态成本回顾科目信息:cb_DtCostRecollectCost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);	

        ALTER TABLE cb_DtCostRecollectCost ENABLE TRIGGER ALL;

---- cb_DtInvestPlan  动态投资计划表
        ALTER TABLE cb_DtInvestPlan DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_DtInvestPlan_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_DtInvestPlan_bak_20251027
            FROM    dbo.cb_DtInvestPlan a
            LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
            where C.ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_DtInvestPlan A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );	

        PRINT '动态投资计划表:cb_DtInvestPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_DtInvestPlan ENABLE TRIGGER ALL;

---- cb_Expense   日常报销表
        ALTER TABLE cb_Expense DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Expense_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_Expense_bak_20251027
            FROM    dbo.cb_Expense
            where ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_Expense
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGUID IN (SELECT  @ProjGUID );

        PRINT '日常报销表:cb_Expense' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_Expense ENABLE TRIGGER ALL;

---- cb_HsCost  核算科目表
        ALTER TABLE cb_HsCost DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_HsCost_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_HsCost_bak_20251027
            FROM    dbo.cb_HsCost a
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
            where C.ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_HsCost A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );

        PRINT '核算科目表:cb_HsCost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_HsCost ENABLE TRIGGER ALL;

---- cb_HsCost_CsVersion  测算科目产品版本表
        ALTER TABLE cb_HsCost_CsVersion DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_HsCost_CsVersion_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_HsCost_CsVersion_bak_20251027
            FROM    dbo.cb_HsCost_CsVersion
            where ProjectGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_HsCost_CsVersion
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjectGUID IN ( SELECT  @ProjGUID );	

        PRINT '测算科目产品版本表:cb_HsCost_CsVersion' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_HsCost_CsVersion ENABLE TRIGGER ALL;


---- cb_HsCost_HtcfProduct  合同拆分产品核算成本
        ALTER TABLE cb_HsCost_HtcfProduct DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_HsCost_HtcfProduct_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_HsCost_HtcfProduct_bak_20251027
            FROM    dbo.cb_HsCost_HtcfProduct
            where ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_HsCost_HtcfProduct
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGUID IN (SELECT  @ProjGUID );	

        PRINT '合同拆分产品核算成本:cb_HsCost_HtcfProduct' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_HsCost_HtcfProduct ENABLE TRIGGER ALL;

---- cb_Loan   领借款表
        ALTER TABLE cb_Loan DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Loan_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_Loan_bak_20251027
            FROM    dbo.cb_Loan
            where ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_Loan
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGUID IN (SELECT  @ProjGUID );	

        PRINT '领借款表:cb_Loan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_Loan ENABLE TRIGGER ALL;

---- cb_PlanAnalyseProj   资金计划项目图形分析拍照表
        ALTER TABLE cb_PlanAnalyseProj DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_PlanAnalyseProj_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_PlanAnalyseProj_bak_20251027
            FROM    dbo.cb_PlanAnalyseProj
            where ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_PlanAnalyseProj
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGUID IN (SELECT  @ProjGUID );	

        PRINT '资金计划项目图形分析拍照表:cb_PlanAnalyseProj' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_PlanAnalyseProj ENABLE TRIGGER ALL;


---- cb_ProjHyb  项目合约包
        ALTER TABLE cb_ProjHyb DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_ProjHyb_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_ProjHyb_bak_20251027
            FROM    dbo.cb_ProjHyb
            where  ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  a
        SET     a.BUGUID = @BuGUIDNew,
                a.HtTypeGUID = newh.HtTypeGUID
        FROM    dbo.cb_ProjHyb a
            INNER JOIN dbo.cb_HtType ht ON ht.HtTypeGUID = a.HtTypeGUID
            INNER JOIN dbo.cb_HtType newh ON newh.HtTypeCode = ht.HtTypeCode AND newh.BUGUID=@BuGUIDNew
        WHERE   a.ProjGUID IN (SELECT  @ProjGUID );	

        UPDATE  a
                SET a.ContractBaseGUID = c.BudgetLibraryGUID ,
                a.YgbgRate = c.YgbgRate ,
                a.IsNeedDataValidSp = CASE WHEN c.IsZlSh = '否' THEN 0 ELSE 1 END
        FROM    cb_ProjHyb a
                INNER JOIN cb_BudgetLibrary b ON a.ContractBaseGUID = b.BudgetLibraryGUID
                LEFT JOIN cb_BudgetLibrary c ON c.BUGUID = @BuGUIDNew AND b.BudgetName = c.BudgetName
        WHERE   a.ProjGUID IN (SELECT  @ProjGUID ) AND  a.ContractBaseGUID = b.BudgetLibraryGUID;

        PRINT '项目合约包:cb_ProjHyb' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_ProjHyb ENABLE TRIGGER ALL;

---- cb_ProjHyb_Version  项目合约包-历史
        ALTER TABLE cb_ProjHyb_Version DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_ProjHyb_Version_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_ProjHyb_Version_bak_20251027
            FROM    dbo.cb_ProjHyb_Version
            where ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_ProjHyb_Version
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGUID IN ( SELECT  @ProjGUID );	

        PRINT '项目合约包-历史:cb_ProjHyb_Version' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_ProjHyb_Version ENABLE TRIGGER ALL;


---- cb_ProjHyb_Working  项目合约包-编制
        ALTER TABLE cb_ProjHyb_Working DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_ProjHyb_Working_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_ProjHyb_Working_bak_20251027
            FROM    dbo.cb_ProjHyb_Working
            WHERE ProjGUID in ( SELECT  @ProjGUID )


       UPDATE A
       SET 
           A.ContractBaseGUID      = c.BudgetLibraryGUID,
           A.YgbgRate              = c.YgbgRate,
           A.IsNeedDataValidSp     = CASE WHEN c.IsZlSh = '否' THEN 0 ELSE 1 END
       FROM dbo.cb_ProjHyb_Working A
           INNER JOIN cb_BudgetLibrary d ON A.ContractBaseGUID = d.BudgetLibraryGUID
           LEFT JOIN cb_BudgetLibrary c ON c.BUGUID = @BuGUIDNew AND d.BudgetName = c.BudgetName
       WHERE
           A.ProjGUID IN (SELECT @ProjGUID);

       UPDATE A
       SET 
           A.BUGUID        = @BuGUIDNew,
           A.HtTypeGUID    = newh.HtTypeGUID
       FROM dbo.cb_ProjHyb_Working A
           INNER JOIN dbo.cb_HtType ht ON ht.HtTypeGUID = A.HtTypeGUID
           INNER JOIN dbo.cb_HtType newh ON newh.HtTypeCode = ht.HtTypeCode AND newh.BUGUID = @BuGUIDNew
       WHERE
           A.ProjGUID IN (SELECT @ProjGUID);


      PRINT '项目合约包-编制:cb_ProjHyb_Working' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


        ALTER TABLE cb_ProjHyb_Working ENABLE TRIGGER ALL;


---- cb_sjkCsfa  测算方案表
        ALTER TABLE cb_sjkCsfa DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_sjkCsfa_Working_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_sjkCsfa_Working_bak_20251027
            FROM    dbo.cb_sjkCsfa a
            LEFT JOIN #TbTemp_p_Project B ON A.ProjGUID = B.ProjGUID
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN (SELECT  @ProjGUID );	

        UPDATE  A
        SET     A.ProjName = C.ProjName ,
                BUGUID = @BuGUIDNew
        FROM    cb_sjkCsfa A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjGUID = B.ProjGUID
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN (SELECT  @ProjGUID );

        PRINT '测算方案表:cb_sjkCsfa' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_sjkCsfa ENABLE TRIGGER ALL;

---- cb_sjkDataCd  成本数据沉淀表
        ALTER TABLE cb_sjkDataCd DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_sjkDataCd_Working_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_sjkDataCd_Working_bak_20251027
            FROM    dbo.cb_sjkDataCd a
            LEFT JOIN #TbTemp_p_Project B ON A.ProjGUID = B.ProjGUID
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN (SELECT  @ProjGUID );

        UPDATE  A
        SET     A.ProjName = C.ProjName ,
                BUGUID = @BuGUIDNew
        FROM    cb_sjkDataCd A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjGUID = B.ProjGUID
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN (SELECT  @ProjGUID );

        PRINT '成本数据沉淀表:cb_sjkDataCd' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_sjkDataCd ENABLE TRIGGER ALL;



    --- ////////////////////////// 2025年新增成本表更新 开始 //////////////////////////
        -- ALTER TABLE cb_ContractCzcfControl DISABLE TRIGGER ALL;

        -- IF OBJECT_ID(N'cb_ContractCzcfControl_bak_20251027', N'U') IS NULL
        -- BEGIN
        --     SELECT 
        --         a.BuGUID,
        --         a.BuName,
        --         a.ContractCzcfControlGUID,
        --         a.ProjGUIDs,
        --         a.ProjNames,
        --         a.ProjGUID
        --     INTO cb_ContractCzcfControl_bak_20251027
        --     FROM (
        --         SELECT 
        --             a.BuName,
        --             a.BuGUID,
        --             a.ContractCzcfControlGUID,
        --             a.ProjGUIDs,
        --             a.ProjNames,
        --             Value AS ProjGUID
        --         FROM cb_ContractCzcfControl a
        --         CROSS APPLY dbo.fn_Split1(a.ProjGUIDs, ',')
        --         WHERE ISNULL(CONVERT(VARCHAR(MAX), a.ProjGUIDs), '') <> ''
        --     ) a
        --     WHERE a.ProjGUID IN (SELECT @ProjGUID);
        -- END

        -- -- 调整buguid和buname信息
        --         UPDATE a
        --         SET a.BuGUID = b.NewBuguid,
        --         a.BuName = b.NewBUName
        --         FROM 
        --         (
        --                 SELECT 
        --                 a.BuName,
        --                 a.BuGUID,
        --                 a.ContractCzcfControlGUID,
        --                 a.ProjGUIDs,
        --                 a.ProjNames,
        --                 Value AS Projguid   
        --                 FROM 
        --                 cb_ContractCzcfControl a
        --                 CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGUIDs, ',') 
        --                 WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        --         ) a 
        --         INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
        --         WHERE a.buguid <> b.NewBuguid;

        --         PRINT '合同产值表:cb_ContractCzcfControl' + CONVERT(NVARCHAR(20), @@ROWCOUNT);        
        -- ALTER TABLE cb_ContractCzcfControl ENABLE TRIGGER ALL;

        -- -- 管控红线项目设置表 
        -- ALTER TABLE cb_ControlRedLineProjects DISABLE TRIGGER ALL;
        -- IF OBJECT_ID(N'cb_ControlRedLineProjects_bak_20251027', N'U') IS NULL
        --         SELECT 
        --         a.BuGUID,
        --         a.BuName,
        --         a.ControlRedLineProjectsGUID,
        --         a.ProjGUIDs,
        --         a.ProjNames
        --         INTO  cb_ControlRedLineProjects_bak_20251027
        --         FROM 
        --         (
        --                 SELECT 
        --                 a.BuName,
        --                 a.BuGUID,
        --                 a.ControlRedLineProjectsGUID,
        --                 a.ProjGUIDs,
        --                 a.ProjNames,
        --                 Value AS Projguid   
        --                 FROM 
        --                 cb_ControlRedLineProjects a
        --                 CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGUIDs, ',') 
        --                 WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        --         ) a 
        --         INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;

        -- -- 调整buguid和buname信息
        -- UPDATE A
        -- SET a.BuGUID = b.NewBuguid,
        --         a.BuName = b.NewBUName        
        -- FROM 
        --         (
        --         SELECT 
        --                 a.BuName,
        --                 a.BuGUID,
        --                 a.ControlRedLineProjectsGUID,
        --                 a.ProjGUIDs,
        --                 a.ProjNames,
        --                 Value AS Projguid   
        --         FROM 
        --                 cb_ControlRedLineProjects a
        --         CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGUIDs, ',') 
        --         WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        --         ) a 
        -- INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
        -- WHERE a.buguid <> b.NewBuguid;
        
        -- PRINT '管控红线项目设置表:cb_ControlRedLineProjects' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 
                
        -- ALTER TABLE cb_ControlRedLineProjects ENABLE TRIGGER ALL;

        -- --  cb_JgbaProjectsSet 竣工备案项目设置表
        -- ALTER TABLE cb_JgbaProjectsSet DISABLE TRIGGER ALL;
        -- IF OBJECT_ID(N'cb_JgbaProjectsSet_bak_20251027', N'U') IS NULL
        --         SELECT 
        --         a.BuGUID,
        --         a.BuName,
        --         a.JgbaProjectsSetGUID,
        --         a.ProjGUIDs,
        --         a.ProjNames
        --         INTO  cb_JgbaProjectsSet_bak_20251027
        --         FROM 
        --         (
        --                 SELECT 
        --                 a.BuName,
        --                 a.BuGUID,
        --                 a.JgbaProjectsSetGUID,
        --                 a.ProjGUIDs,
        --                 a.ProjNames,
        --                 Value AS Projguid   
        --                 FROM   cb_JgbaProjectsSet a
        --                 CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGUIDs, ',') 
        --                 WHERE  ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        --         ) a 
        --         INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;

        -- -- 调整buguid和buname信息
        -- UPDATE A
        -- SET a.BuGUID = b.NewBuguid,
        --         a.BuName = b.NewBUName        
        -- FROM 
        --         (
        --         SELECT 
        --                 a.BuName,
        --                 a.BuGUID,
        --                 a.JgbaProjectsSetGUID,
        --                 a.ProjGUIDs,
        --                 a.ProjNames,
        --                 Value AS Projguid   
        --         FROM 
        --                 cb_JgbaProjectsSet a
        --         CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGUIDs, ',') 
        --         WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        --         ) a 
        -- INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
        -- WHERE a.buguid <> b.NewBuguid;
        
        -- PRINT '竣工备案项目设置表:cb_JgbaProjectsSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 
                
        -- ALTER TABLE cb_JgbaProjectsSet ENABLE TRIGGER ALL;

        -- cb_ProjectBldDelControl  已完工工程楼栋删除设置表
        ALTER TABLE cb_ProjectBldDelControl DISABLE TRIGGER ALL;

        IF OBJECT_ID(N'cb_ProjectBldDelControl_bak_20251027', N'U') IS NULL
                SELECT  A.*
                INTO    dbo.cb_ProjectBldDelControl_bak_20251027
                FROM    dbo.cb_ProjectBldDelControl A
                where  ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET a.BUGUID = @BuGUIDNew
        FROM    dbo.cb_ProjectBldDelControl a
        where  a.ProjGUID in ( SELECT  @ProjGUID )

        PRINT '已完工工程楼栋删除设置表:cb_ProjectBldDelControl' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 
                
        ALTER TABLE cb_ProjectBldDelControl ENABLE TRIGGER ALL;

        -- --项目付款申请端口开放设置表  cb_ControlHTFKApplyProj
        -- ALTER TABLE cb_ControlHTFKApplyProj DISABLE TRIGGER ALL;

        -- IF OBJECT_ID(N'cb_ControlHTFKApplyProj_bak_20251027', N'U') IS NULL
        -- BEGIN
        --         SELECT  a.*
        --         INTO    dbo.cb_ControlHTFKApplyProj_bak_20251027
        --         FROM 
        --         (
        --         SELECT 
        --                 a.BuName,
        --                 a.BuGUID,
        --                 a.ControlHTFKApplyProjGUID,
        --                 a.ProjGUIDs,
        --                 a.ProjNames,
        --                 Value AS Projguid   
        --         FROM 
        --                 cb_ControlHTFKApplyProj a
        --         CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGUIDs, ',') 
        --         WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        --         ) a 
        --         INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;
        -- END

        -- -- 调整buguid和buname信息
        -- UPDATE A
        -- SET a.BuGUID = b.NewBuguid,
        --         a.BuName = b.NewBUName    
        -- FROM 
        -- (
        --         SELECT 
        --                 a.BuName,
        --                 a.BuGUID,
        --                 a.ControlHTFKApplyProjGUID,
        --                 a.ProjGUIDs,
        --                 a.ProjNames,
        --                 Value AS Projguid   
        --         FROM 
        --                 cb_ControlHTFKApplyProj a
        --         CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGUIDs, ',') 
        --         WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGUIDs), '') <> ''
        -- ) a 
        -- INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
        -- WHERE a.buguid <> b.NewBuguid;

        -- PRINT '项目付款申请端口开放设置表：cb_ControlHTFKApplyProj' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 

        -- ALTER TABLE cb_ControlHTFKApplyProj ENABLE TRIGGER ALL;


        -- -- cb_DesignAlterToTZXT  设计变更信息传图纸系统监听表
        -- ALTER TABLE cb_DesignAlterToTZXT DISABLE TRIGGER ALL;

        -- IF OBJECT_ID(N'cb_DesignAlterToTZXT_bak_20251027', N'U') IS NULL
        -- BEGIN
        --         SELECT  a.*
        --         INTO    dbo.cb_DesignAlterToTZXT_bak_20251027
        --         FROM 
        --         (
        --         SELECT 
        --                 a.id,
        --                 a.DesignAlterGuid,
        --                 a.BuGUID,
        --                 a.ProjGuidList,
        --                 a.ProjectInfo,
        --                 Value AS Projguid   
        --         FROM 
        --                 cb_DesignAlterToTZXT a
        --         CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGuidList, ',') 
        --         WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGuidList), '') <> ''
        --         ) a 
        --         INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid;
        -- END

        -- -- 调整buguid和buname信息
        -- UPDATE A
        -- SET a.BuGUID = b.NewBuguid
        -- FROM 
        -- (
        --         SELECT 
        --                 a.id,
        --                 a.DesignAlterGuid,
        --                 a.BuGUID,
        --                 a.ProjGuidList,
        --                 a.ProjectInfo,
        --                 Value AS Projguid   
        --         FROM 
        --                 cb_DesignAlterToTZXT a
        --         CROSS APPLY 
        --                 dbo.fn_Split1(a.ProjGuidList, ',') 
        --         WHERE 
        --                 ISNULL(convert(varchar(max), a.ProjGuidList), '') <> ''
        -- ) a 
        -- INNER JOIN   #dqy_proj b ON a.Projguid = b.OldProjGuid
        -- WHERE a.buguid <> b.NewBuguid;

        -- PRINT '设计变更信息传图纸系统监听表：cb_DesignAlterToTZXT' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 

        -- ALTER TABLE cb_DesignAlterToTZXT ENABLE TRIGGER ALL;

        -- cb_TargetStage2Cost 目标成本表
        ALTER TABLE cb_TargetStage2Cost DISABLE TRIGGER ALL;

        IF OBJECT_ID(N'cb_TargetStage2Cost_bak_20251027', N'U') IS NULL
                SELECT a.* 
                INTO 
                cb_TargetStage2Cost_bak_20251027
                FROM cb_TargetStage2Cost a 
                where  a.ProjGUID in ( SELECT  @ProjGUID )

                -- 调整projcode信息
                UPDATE a
                SET a.projcode = c.projcode  
                FROM cb_TargetStage2Cost a 
                LEFT JOIN #TbTemp_p_Project B ON A.ProjGUID = B.ProjGUID
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
                where  a.ProjGUID in ( SELECT  @ProjGUID )

        PRINT '目标成本表:cb_TargetStage2Cost' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_TargetStage2Cost ENABLE TRIGGER ALL;

        --- ////////////////////////// 2025年新增成本表更新  结束 //////////////////////////  

       -- cb_Task  任务设置表
        ALTER TABLE cb_Task DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_Task_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.cb_Task_bak_20251027
            FROM    dbo.cb_Task
            where  ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  cb_Task
        SET     BUGUID = @BuGUIDNew
        WHERE   ProjGUID IN ( SELECT  @ProjGUID );	

        PRINT '任务设置表:cb_Task' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_Task ENABLE TRIGGER ALL;

---- cb_ZjPlan  资金计划表
        ALTER TABLE cb_ZjPlan DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_ZjPlan_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_ZjPlan_bak_20251027
            FROM    dbo.cb_ZjPlan A
              LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
              LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
            where  c.ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode ,
                BUGUID = @BuGUIDNew
        FROM    cb_ZjPlan A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );	

        PRINT '资金计划表:cb_ZjPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_ZjPlan ENABLE TRIGGER ALL;

-- cb_CfDtl 成本拆分明细表

        ALTER TABLE cb_CfDtl DISABLE TRIGGER ALL;   

        IF OBJECT_ID(N'cb_CfDtl_bak_20251027', N'U') IS NULL
            SELECT  a.*
            INTO    dbo.cb_CfDtl_bak_20251027
            FROM    dbo.cb_CfDtl A
            LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
            LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
            where  c.ProjGUID in ( SELECT  @ProjGUID )

        UPDATE  A
        SET     A.ProjectCode = C.ProjCode
        FROM    cb_CfDtl A
                LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
                LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        WHERE   C.ProjGUID IN ( SELECT  @ProjGUID );	

        PRINT '成本拆分明细表:cb_CfDtl' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        ALTER TABLE cb_CfDtl ENABLE TRIGGER ALL;
                
        ALTER TABLE cb_CfRule DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_CfRule_bak_20251027', N'U') IS NULL
        SELECT  A.*
        INTO    dbo.cb_CfRule_bak_20251027
        FROM    dbo.cb_CfRule A
        LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
        LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
        where  c.ProjGUID in ( SELECT  @ProjGUID )

    UPDATE  a
    SET a.ProjectCode = C.ProjCode
    FROM    dbo.cb_CfRule a
        LEFT JOIN #TbTemp_p_Project B ON A.ProjectCode = B.ProjCode
        LEFT JOIN dbo.p_Project C ON C.ProjGUID = B.ProjGUID
    where  c.ProjGUID in ( SELECT  @ProjGUID )

    PRINT '成本拆分规则表:cb_CfRule' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_CfRule ENABLE TRIGGER ALL;

    --获取待迁移项目个数进行循环更新，同一个公司所属部分不需要刷新
--       EXEC usp_p_UpdateProjDeptGUID @projguid, @BUGUID, @buname;

    --刷新json 字段
    DECLARE @var_ContractGUID UNIQUEIDENTIFIER;
    DECLARE @JsonCount INT;
    SET @i = 1;

    SELECT  ROW_NUMBER() OVER (ORDER BY a.ContractCode) AS num ,
            a.*
    INTO    #cb_Contract
    FROM    dbo.cb_Contract a
            INNER JOIN dbo.cb_ContractProj b ON b.ContractGUID = a.ContractGUID
            INNER JOIN vcb_ContractGrid c ON c.ContractGUID = a.ContractGUID
    WHERE   c.IsUseCostInfo = '是' and b.ProjGUID in ( SELECT  @ProjGUID )

    --计算记录数
    SELECT  @JsonCount = COUNT(1)FROM   #cb_Contract;

    WHILE @i <= @JsonCount
        BEGIN
            SELECT  @var_ContractGUID = ContractGUID FROM   #cb_Contract WHERE  num = @i;

            PRINT '开始刷新json，剩余：';
            PRINT @JsonCount - @i;
            PRINT @var_ContractGUID;

            --刷新json
            EXEC dbo.usp_UpdateContractBudgetJson_Ds @var_ContractGUID;

            SET @i = @i + 1;
        END;


    --- >>>>>>>>>>>>>>>>>>>>>>>> 财务接口和盈利规划数据刷新 开始 >>>>>>>>>>>>>>>>>>>>>>>>>>-------------------

    --刷新成本系统财务接口数据
    --刷新财务公司 
    IF OBJECT_ID(N'p_cwjkcompany_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.p_cwjkcompany_bak_20251027
        FROM    dbo.p_cwjkproject_New a
                INNER JOIN dbo.p_cwjkcompany b ON a.CompanyGUID = b.CompanyGUID
        where  a.ProjGUID in ( SELECT  @ProjGUID )

    UPDATE  b
    SET b.BUGUID =@BuGUIDNew
    FROM    dbo.p_cwjkproject_New a
            INNER JOIN dbo.p_cwjkcompany b ON a.CompanyGUID = b.CompanyGUID
            where  a.ProjGUID in ( SELECT  @ProjGUID )

    PRINT '财务公司p_cwjkcompany：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    --刷新票易通
    IF OBJECT_ID(N'cb_PayConfirmSheet_Invoice_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_PayConfirmSheet_Invoice_bak_20251027
        FROM    dbo.cb_PayConfirmSheet_Invoice a
                LEFT JOIN(SELECT    (SELECT ApplyCode + ';'
                                     FROM   vcb_PayConfirmSheet_InvoiceRef
                                     WHERE  InvoiceGUID = ref.InvoiceGUID
                                    FOR XML PATH('')) AS ApplyCode ,
                                    InvoiceGUID ,
                                    ContractGUID
                          FROM  vcb_PayConfirmSheet_InvoiceRef ref
                          GROUP BY InvoiceGUID ,
                                   ContractGUID) d ON a.InvoiceGUID = d.InvoiceGUID
                LEFT JOIN dbo.cb_Contract ht ON d.ContractGUID = ht.ContractGUID
                left join cb_contractproj cp on cp.contractguid = ht.contractguid
                INNER JOIN dbo.myBusinessUnit bu ON bu.BUGUID = ht.BUGUID
        WHERE   cp.projguid in ( SELECT  @ProjGUID )

    UPDATE  a
    SET a.BUGUID = bu.BUGUID
    FROM    cb_PayConfirmSheet_Invoice a
                LEFT JOIN(SELECT    (SELECT ApplyCode + ';'
                                     FROM   vcb_PayConfirmSheet_InvoiceRef
                                     WHERE  InvoiceGUID = ref.InvoiceGUID
                                    FOR XML PATH('')) AS ApplyCode ,
                                    InvoiceGUID ,
                                    ContractGUID
                          FROM  vcb_PayConfirmSheet_InvoiceRef ref
                          GROUP BY InvoiceGUID ,
                                   ContractGUID) d ON a.InvoiceGUID = d.InvoiceGUID
                LEFT JOIN dbo.cb_Contract ht ON d.ContractGUID = ht.ContractGUID
                left join cb_contractproj cp on cp.contractguid = ht.contractguid
                INNER JOIN dbo.myBusinessUnit bu ON bu.BUGUID = ht.BUGUID
        WHERE   cp.projguid in ( SELECT  @ProjGUID )

    PRINT '易票通cb_PayConfirmSheet_Invoice：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

--     IF OBJECT_ID(N'cb_PayConfirmSheet_Invoice_1_bak_20251027', N'U') IS NULL
--         SELECT  a.*
--         INTO    cb_PayConfirmSheet_Invoice_1_bak_20251027
--         FROM    dbo.cb_PayConfirmSheet_Invoice a
--                 INNER JOIN p_cwjkcompany cw ON cw.CompanyName = a.PurchaserName
--         WHERE   a.BUGUID <> cw.BUGUID AND   a.BUGUID IN(SELECT  OldBuguid FROM  #dqy_proj);

--     UPDATE  a
--     SET a.BUGUID = cw.buguid
--     FROM    dbo.cb_PayConfirmSheet_Invoice a
--             INNER JOIN p_cwjkcompany cw ON cw.CompanyName = a.PurchaserName
--     WHERE   a.BUGUID <> cw.BUGUID AND   a.BUGUID IN(SELECT  OldBuguid FROM  #dqy_proj);

--     PRINT '根据名称刷新cb_PayConfirmSheet_Invoice：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'cb_InvoiceItem_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_InvoiceItem_bak_20251027
        FROM    cb_InvoiceItem a
                INNER JOIN dbo.cb_Voucher b ON a.RefGUID = b.VouchGUID
                INNER JOIN dbo.cb_Contract c ON b.ContractGUID = c.ContractGUID
                left join cb_contractproj cp on cp.contractguid = c.contractguid
          where  cp.projguid in ( SELECT  @ProjGUID )

    UPDATE  a
    SET a.BUGUID = c.BUGUID
    FROM    cb_InvoiceItem a
            INNER JOIN dbo.cb_Voucher b ON a.RefGUID = b.VouchGUID
            INNER JOIN dbo.cb_Contract c ON b.ContractGUID = c.ContractGUID
            left join cb_contractproj cp on cp.contractguid = c.contractguid
    WHERE   cp.projguid in ( SELECT  @ProjGUID )

    PRINT '票据类型cb_InvoiceItem：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    IF OBJECT_ID(N'cb_Bank_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.cb_Bank_bak_20251027
        FROM    cb_Bank a
                INNER JOIN dbo.cb_BankProj b ON a.BankGUID = b.BankGUID
        where  b.projguid in ( SELECT  @ProjGUID )

    UPDATE  a
    SET a.BUGUID = @BuGUIDNew
    FROM    cb_Bank a
            INNER JOIN dbo.cb_BankProj b ON a.BankGUID = b.BankGUID
          where  b.projguid in ( SELECT  @ProjGUID )

    PRINT '银行信息cb_Bank：' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTAlter DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HTAlter_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HTAlter_bak_20251027
        FROM    cb_HTAlter a
                LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
                left join cb_contractproj cp on cp.contractguid = b.contractguid
        WHERE  cp.projguid in ( SELECT  @ProjGUID )

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    cb_HTAlter a
        LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
        left join cb_contractproj cp on cp.contractguid = b.contractguid
    WHERE   cp.projguid in ( SELECT  @ProjGUID )

    PRINT '合同付款:cb_HTAlter' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTAlter ENABLE TRIGGER ALL;

    ALTER TABLE cb_HTFKApply DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HTFKApply_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HTFKApply_bak_20251027
        FROM    cb_HTFKApply a
                LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
                left join cb_contractproj cp on cp.contractguid = b.contractguid
        WHERE   cp.projguid in ( SELECT  @ProjGUID )


        UPDATE  a
        SET a.BUGUID = b.BUGUID
        FROM    cb_HTFKApply a
        LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
        left join cb_contractproj cp on cp.contractguid = b.contractguid
        WHERE   cp.projguid in ( SELECT  @ProjGUID )

    PRINT '合同付款申请:cb_HTFKApply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTFKApply ENABLE TRIGGER ALL;

    ALTER TABLE cb_HTFKPlan DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_HTFKPlan_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    cb_HTFKPlan_bak_20251027
        FROM    cb_HTFKPlan a
        LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
        left join cb_contractproj cp on cp.contractguid = b.contractguid
        WHERE   cp.projguid in ( SELECT  @ProjGUID )

    UPDATE  a
    SET a.BUGUID = b.BUGUID
    FROM    cb_HTFKPlan a
        LEFT JOIN dbo.cb_Contract b ON a.ContractGUID = b.ContractGUID
        left join cb_contractproj cp on cp.contractguid = b.contractguid
        WHERE   cp.projguid in ( SELECT  @ProjGUID )

    PRINT '合同付款计划:cb_HTFKPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_HTFKPlan ENABLE TRIGGER ALL;

    --补充，刷新应收单
    ALTER TABLE cb_payfeebill DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_payfeebill_bak_20251027', N'U') IS NULL
        SELECT  bil.*
        INTO    cb_payfeebill_bak_20251027
        FROM    cb_contract con
                INNER JOIN cb_contractproj pro ON pro.contractguid = con.contractguid
                INNER JOIN cb_payfeebill bil ON bil.contractguid = con.contractguid
        WHERE  pro.projguid in ( SELECT  @ProjGUID )

    UPDATE  bil
    SET bil.BUGUID = con.BUGUID
    FROM    cb_contract con
            INNER JOIN cb_contractproj pro ON pro.contractguid = con.contractguid
            INNER JOIN cb_payfeebill bil ON bil.contractguid = con.contractguid
        WHERE  pro.projguid in ( SELECT  @ProjGUID )

    PRINT '应收单:cb_payfeebill' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_payfeebill ENABLE TRIGGER ALL;

    ------------------------------------补充
    ALTER TABLE cb_pay DISABLE TRIGGER ALL;

    IF OBJECT_ID(N'cb_pay_bak_20251027', N'U') IS NULL
        SELECT  cp.*
        INTO    cb_pay_bak_20251027
        FROM    cb_contract con
                INNER JOIN cb_pay cp ON cp.contractguid = con.contractguid
                inner  join cb_contractproj pro on pro.contractguid = con.contractguid
        WHERE  pro.projguid in ( SELECT  @ProjGUID )

    UPDATE  cp
    SET cp.BUGUID = con.BUGUID
    FROM    cb_contract con
    INNER JOIN cb_pay cp ON cp.contractguid = con.contractguid
    INNER JOIN  cb_contractproj pro on pro.contractguid = con.contractguid
    WHERE  pro.projguid in ( SELECT  @ProjGUID )

    PRINT '实付款单据:cb_pay' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

    ALTER TABLE cb_pay ENABLE TRIGGER ALL;

--     --更新合同和合同预呈批的部门信息:统一刷新为公司信息 
--     UPDATE  p
--     SET p.DeptGUID = (SELECT    TOP 1  dept.BUGUID
--                       FROM  myBusinessUnit dept
--                       WHERE dept.CompanyGUID = p.BUGUID AND dept.Level = 3)
--     FROM    cb_Contract_Pre p
--             INNER JOIN myBusinessUnit bu ON p.DeptGUID = bu.BUGUID
--             INNER JOIN #dqy_proj b ON p.buguid = b.newbuguid
--     WHERE   p.BUGUID <> bu.CompanyGUID;

--     UPDATE  p
--     SET p.DeptGUID = (SELECT    TOP 1  dept.BUGUID
--                       FROM  myBusinessUnit dept
--                       WHERE dept.CompanyGUID = p.BUGUID AND dept.Level = 3)
--     FROM    cb_Contract p
--             INNER JOIN myBusinessUnit bu ON p.DeptGUID = bu.BUGUID
--             INNER JOIN #dqy_proj b ON p.buguid = b.newbuguid
--     WHERE   p.BUGUID <> bu.CompanyGUID;


    --- 财务接口和盈利规划数据刷新 结束 -------------------


        ----- 删除临时表 

        -- DROP TABLE #TbTemp_p_Project;

        -- DROP TABLE #tempproject;   


    END;