USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_ProjectMove]    Script Date: 2025/10/27 20:28:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    分期数据迁移脚本
*/
--  SELECT sys.objects.name 表名 ,
--         sys.columns.name  字段名称,
--         sys.types.name 数据类型,
--         sys.columns.max_length 长度,
--  	   sys.objects.create_date 创建日期
--  FROM   sys.objects
--         LEFT JOIN sys.columns ON sys.objects.object_id = sys.columns.object_id
--         LEFT JOIN sys.types ON sys.types.system_type_id = sys.columns.system_type_id
--  WHERE (sys.columns.name = 'projcode' OR sys.columns.name = 'ParentProjGUID' 
--           OR sys.columns.name ='ParentGUID' 
--           OR sys.columns.name = 'ParentName' 
--           OR sys.columns.name = 'ParentCode' 
--           OR sys.columns.name like '%FullName' 
--           OR   sys.columns.name ='HierarchyCode') AND
--         sys.objects.type = 'U'
--         AND sys.objects.name LIKE 'k_%'
--            ORDER BY sys.objects.name,sys.columns.column_id

-- 河南公司 杓袁7号地 分期迁移 
-- EXEC  usp_s_ProjectMoveFq '河南公司','河南公司','5F4A536B-D813-E911-80BF-E61F13C57837','B956D877-F0D7-E811-80BF-E61F13C57837','6C0AD572-3663-EA11-80B8-0A94EF7517DD'

create or  ALTER PROC [dbo].[usp_s_ProjectMoveFq](
                                     @OldBUName VARCHAR(MAX) ,
                                     @NewBUName VARCHAR(MAX),
                                     @ProjGUID UNIQUEIDENTIFIER -- 分期项目GUID
                                --      @OldTopProjGUID UNIQUEIDENTIFIER,    --老的一级项目GUID
                                --      @NewTopProjGUID UNIQUEIDENTIFIER --新一级项目GUID
                                     )
AS 
/*--------------------------------------------------
  存储过程名：
      usp_s_ProjectMove 
  功能：
      销售系统项目转移到新公司；
      适用于统一源公司多个项目同时转移到新公司，不适用于多个源公司项目同时转移；
  参数：
      @OldBUName 待转移的项目所属公司
      @ProjName 待转移项目名称
      @NewBUName 新公司名称  
      
   注意将数据库名名称替换为erp25
 

  Create by ： lp  2017-05-05  V 1.0
  modify by :  lp  2017-10-10  V 2.0  增加销售计划、价格预测相关表
  modify by :  lp  2017-05-04  V 3.0  增加三套系统项目团队调整，楼栋代码替换、新公司楼栋创建方式确认为引入、项目代码替换检查、数据权限表刷新
  modify by :  lp  2018-07-30  V 4.0  调整货值铺排平台公司GUID、增加折扣方案所属公司
  modify by :  yp  20220218  v5.0 补全修复脚本

    --停用触发器
    DISABLE TRIGGER ALL ON dbo.s_Order;
    DISABLE TRIGGER ALL ON dbo.s_Contract;
    DISABLE TRIGGER ALL ON dbo.s_Booking;
    DISABLE TRIGGER ALL ON dbo.s_Opportunity;
    DISABLE TRIGGER ALL ON dbo.s_Voucher;
    DISABLE TRIGGER ALL ON dbo.p_room;
    DISABLE TRIGGER ALL ON dbo.myBusinessUnit;
GO

USE MyCost_Erp352;
GO
DISABLE TRIGGER ALL ON dbo.myBusinessUnit;
GO
USE CRE_ERP_202_SYZL;
GO
DISABLE TRIGGER ALL ON dbo.myBusinessUnit;
GO
USE ERP25;
GO
    ALTER TABLE dbo.s_Order ENABLE TRIGGER ALL;
    ALTER TABLE dbo.s_Contract ENABLE TRIGGER ALL;
    ALTER TABLE dbo.s_Booking ENABLE TRIGGER ALL;
    ALTER TABLE dbo.s_Opportunity ENABLE TRIGGER ALL;
    ALTER TABLE dbo.s_Voucher ENABLE TRIGGER ALL;
    ALTER TABLE dbo.p_room ENABLE TRIGGER ALL;
    ALTER TABLE dbo.myBusinessUnit ENABLE TRIGGER ALL;

    USE MyCost_Erp352;
    ALTER TABLE dbo.myBusinessUnit ENABLE TRIGGER ALL;

    USE CRE_ERP_202_SYZL;

    ALTER TABLE dbo.myBusinessUnit ENABLE TRIGGER ALL;


*/
    --------------------------------------------------
    BEGIN

        SET NOCOUNT OFF;

        PRINT '--创建项目待转移项目临时表';


        SELECT  * into #dqy_proj from dqy_proj_20251027 where OldProjGuid = @ProjGUID;

        CREATE TABLE #Pro (BUGUID VARCHAR(100) ,
                           BUCODE VARCHAR(100) ,
                           ProjGUID VARCHAR(100) ,
                           ProjName VARCHAR(100) ,
                           OldTopProjGUID UNIQUEIDENTIFIER,
                           NewTopProjGUID UNIQUEIDENTIFIER,
                           OldTopProjCode VARCHAR(100),
                           NewTopProjCode VARCHAR(100),
                           OldTopProjName VARCHAR(100),
                           NewTopProjName VARCHAR(100)
                           );

        INSERT INTO #Pro(BUGUID, BUCODE, ProjGUID, ProjName,OldTopProjGUID,NewTopProjGUID,OldTopProjCode,NewTopProjCode,OldTopProjName,NewTopProjName)
        SELECT  p.BUGUID ,
                m.BUCode ,
                p.ProjGUID ,
                p.ProjName,
                pj.OldParentprojguid as OldTopProjGUID ,
                pj.NewParentprojguid as NewTopProjGUID ,
                p1.ProjCode as  OldTopProjCode ,
                (select top  1 ProjCode from  p_project where projguid = pj.NewParentprojguid order by ProjCode desc)  NewTopProjCode,
                (select top  1 Projname from  p_project where projguid = pj.OldParentprojguid order by Projname desc)  OldTopProjName,
                (select top  1 Projname from  p_project where projguid = pj.NewParentprojguid order by Projname desc)  NewTopProjName
        FROM    dbo.p_Project p
                inner join dbo.p_Project p1 on p.ParentCode = p1.ProjCode 
                LEFT JOIN dbo.myBusinessUnit m ON p.BUGUID = m.BUGUID
                left join #dqy_proj pj on pj.OldProjGuid = p.ProjGUID
        WHERE   p.ProjGUID IN(
                              SELECT p1.ProjGUID
                              FROM  p_Project p1
                              WHERE p1.Level = 3 AND p1.ProjGUID IN (SELECT  Value FROM  [dbo].[fn_Split2](@ProjGUID, ',') )) 
                AND p.ApplySys LIKE '%,0101,%';
        

        Print '--->>> 查询需要迁移的项目分期列表'
        SELECT  * FROM  #Pro;

        PRINT '--获取新公司GUID,Code';

        DECLARE @NewBUGUID VARCHAR(100);
        DECLARE @NewBUCODE VARCHAR(100);

        SELECT  @NewBUGUID = BUGUID ,
                @NewBUCODE = BUCode
        FROM    dbo.myBusinessUnit
        WHERE   BUName = @NewBUName AND IsEndCompany = 1 AND IsCompany = 1;

        --SELECT  @NewBUGUID
        PRINT '--调整项目所属公司,项目代码';
        IF OBJECT_ID(N'p_Project_bak_20251027', N'U') IS NULL
            SELECT  *
            INTO    dbo.p_Project_bak_20251027
            FROM    dbo.p_Project

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
            b.ProjCode = REPLACE(b.ProjCode, a.OldTopProjCode, a.NewTopProjCode) ,
            b.ParentCode = REPLACE(b.ParentCode, a.OldTopProjCode, a.NewTopProjCode),
            b.Projname = REPLACE(b.Projname, a.OldTopProjName, a.NewTopProjName)
        FROM    #Pro a
                INNER JOIN dbo.p_Project b ON a.ProjGUID = b.ProjGUID
        where a.ProjGUID =@ProjGUID
      
       PRINT N'项目表:p_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);    


        PRINT '-------修改项目团队相关信息--------';

        ALTER TABLE myBusinessUnit DISABLE TRIGGER ALL;

        --erp25
        IF OBJECT_ID(N'myBusinessUnit_bak_20251027', N'U') IS NULL
                SELECT  *
                INTO    dbo.myBusinessUnit_bak_20251027
                FROM    dbo.myBusinessUnit;

        UPDATE  b
        SET b.BUCode = REPLACE(b.BUCode, a.BUCODE, @NewBUCODE) ,
            b.HierarchyCode = REPLACE(b.HierarchyCode, a.OldTopProjCode, a.NewTopProjCode) ,
            b.ParentGUID = @NewBUGUID , 
            b.CompanyGUID = @NewBUGUID ,
            b.NamePath = REPLACE(b.NamePath, a.OldTopProjName, a.NewTopProjName)
        FROM    #Pro a
                INNER JOIN erp25.dbo.myBusinessUnit b ON b.ProjGUID = a.ProjGUID
        WHERE   a.ProjGUID =@ProjGUID -- AND   b.CompanyGUID <> @NewBUGUID;

        PRINT N'ERP25组织架构表:myBusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);        
        ALTER TABLE myBusinessUnit ENABLE TRIGGER ALL;

        --erp352
        ALTER TABLE MyCost_Erp352.dbo.myBusinessUnit DISABLE TRIGGER ALL;

        UPDATE  b
        SET b.BUCode = REPLACE(b.BUCode, a.BUCODE, @NewBUCODE) ,
            b.HierarchyCode = REPLACE(b.HierarchyCode, a.OldTopProjCode, a.NewTopProjCode) ,
            b.ParentGUID = @NewBUGUID ,
            b.CompanyGUID = @NewBUGUID ,
            b.NamePath = REPLACE(b.NamePath, a.OldTopProjName, a.NewTopProjName)
        FROM    #Pro a
                INNER JOIN MyCost_Erp352.dbo.myBusinessUnit b ON b.ProjGUID = a.ProjGUID
        WHERE   a.ProjGUID =@ProjGUID -- AND   b.CompanyGUID <> @NewBUGUID;


        PRINT N'ERP352组织架构表:myBusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);   

        ALTER TABLE MyCost_Erp352.dbo.myBusinessUnit ENABLE TRIGGER ALL;

        --租赁系统 
        ALTER TABLE CRE_ERP_202_SYZL.dbo.myBusinessUnit DISABLE TRIGGER ALL;

        UPDATE  b
        SET b.BUCode = REPLACE(b.BUCode, a.BUCODE, @NewBUCODE) ,
            b.HierarchyCode = REPLACE(b.HierarchyCode, a.OldTopProjCode, a.NewTopProjCode) ,
            b.ParentGUID = @NewBUGUID ,
            b.CompanyGUID = @NewBUGUID ,
            b.NamePath = REPLACE(b.NamePath, a.OldTopProjName, a.NewTopProjName)
        FROM    #Pro a
                INNER JOIN CRE_ERP_202_SYZL.dbo.myBusinessUnit b ON b.ProjGUID = a.ProjGUID
        WHERE  a.ProjGUID =@ProjGUID -- AND   b.CompanyGUID <> @NewBUGUID;

        PRINT N'租赁组织架构表:myBusinessUnit' + CONVERT(NVARCHAR(20), @@ROWCOUNT);   

        ALTER TABLE CRE_ERP_202_SYZL.dbo.myBusinessUnit ENABLE TRIGGER ALL;

        --修改项目数据权限
        --erp25
        IF OBJECT_ID(N'myStationObject_bak_20251027', N'U') IS NULL
                SELECT  *
                INTO    dbo.myStationObject_bak_20251027
                FROM    dbo.myStationObject;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    erp25.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '项目'
        WHERE  a.ObjectGUID =@ProjGUID 

        PRINT N'修改ERP25项目数据权限:myStationObject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  
        --erp352        
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    MyCost_Erp352.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '项目'
        WHERE  a.ObjectGUID =@ProjGUID 
       
        PRINT N'修改ERP352项目数据权限:myStationObject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  
        --租赁   
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    CRE_ERP_202_SYZL.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '项目'
        WHERE   a.ObjectGUID =@ProjGUID 

        PRINT N'修改租赁项目数据权限:myStationObject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--->>>>>修改销售系统公司GUID开始----';
        PRINT '楼栋表';

        IF OBJECT_ID(N'p_Building_bak_20251027', N'U') IS NULL
                SELECT  *
                INTO    dbo.p_Building_bak_20251027
                FROM    dbo.p_Building
                where p_Building.ProjGUID =@ProjGUID;

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,  
            b.ParentCode = REPLACE(b.ParentCode, a.OldTopProjCode, a.NewTopProjCode ) ,
            b.BldFullName = REPLACE(b.BldFullName, a.OldTopProjName, a.NewTopProjName )
        FROM    #Pro a
                INNER JOIN dbo.p_Building b ON a.ProjGUID = b.ProjGUID
        WHERE   a.ProjGUID =@ProjGUID 

        PRINT N'修改楼栋表:p_Building' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '楼栋表日志表';

        IF OBJECT_ID(N'p_Building_log_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_Building_log_bak_20251027
        FROM    dbo.p_Building_log
        where p_Building_log.ProjGUID =@ProjGUID;

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,  
            b.ParentCode = REPLACE(b.ParentCode, a.OldTopProjCode, a.NewTopProjCode ) ,
            b.BldFullName = REPLACE(b.BldFullName, a.OldTopProjName, a.NewTopProjName )
        FROM    #Pro a
                INNER JOIN dbo.p_Building_log b ON a.ProjGUID = b.ProjGUID
        WHERE   a.ProjGUID =@ProjGUID 

        PRINT N'修改楼栋表日志表:p_Building_log' + CONVERT(NVARCHAR(20), @@ROWCOUNT);   

        PRINT '房间表';

        IF OBJECT_ID(N'p_room_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_room_bak_20251027
        FROM    dbo.p_room
        where p_room.ProjGUID =@ProjGUID;

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
        --     b.RoomCode = REPLACE(b.RoomCode, a.OldTopProjCode, a.NewTopProjCode)
            b.RoomCode = REPLACE(b.RoomCode,
                            SUBSTRING(a.OldTopProjCode,CHARINDEX('.',a.OldTopProjCode)+1,len(a.OldTopProjCode) ), 
                            SUBSTRING(a.NewTopProjCode,CHARINDEX('.',a.NewTopProjCode)+1,len(a.NewTopProjCode) ))
        FROM    #Pro a
                INNER JOIN dbo.p_room b ON a.ProjGUID = b.ProjGUID
        WHERE   a.ProjGUID =@ProjGUID;

        PRINT N'修改房间表:p_room' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--按揭银行（参数配置项目级）（ProjGUID不为空）“按揭银行设置”项目级按照项目处理、公司级按照公司处理（已核实已处理）*';

        IF OBJECT_ID(N's_Bank_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Bank_bak_20251027
        FROM    dbo.s_Bank
        where s_Bank.ProjGUID =@ProjGUID;

        UPDATE  s_Bank
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Bank.ProjGUID) 

        PRINT N'修改按揭银行表:s_Bank' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--按揭银行（备份表）（已核实有数据未使用）*';

        IF OBJECT_ID(N's_BankBackUp_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_BankBackUp_bak_20251027
        FROM    dbo.s_BankBackUp
        where  s_BankBackUp.ProjGUID =@ProjGUID;

        UPDATE  s_BankBackUp
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BankBackUp.ProjGUID) 

        PRINT '--批量传递记录表（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_BatchPass_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_BatchPass_bak_20251027
        FROM    dbo.s_BatchPass
        where  s_BatchPass.ProjGUID =@ProjGUID;

        UPDATE  s_BatchPass
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BatchPass.ProjGUID) 

        PRINT N'修改批量传递记录表:s_BatchPass' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--办理房产证通知（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_BlFczTz_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_BlFczTz_bak_20251027
        FROM    dbo.s_BlFczTz
        where s_BlFczTz.ProjGUID =@ProjGUID;

        UPDATE  s_BlFczTz
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BlFczTz.ProjGUID) 

        PRINT N'修改办理房产证通知:s_BlFczTz' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--预约单（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_Booking_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Booking_bak_20251027
        FROM    dbo.s_Booking
        where  s_Booking.ProjGUID =@ProjGUID;


        UPDATE  s_Booking
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Booking.ProjGUID) 

        PRINT N'修改预约单:s_Booking' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--选房设置表（ProjGUID不为空）项目级业务参数（已核实已处理）*';

        IF OBJECT_ID(N's_ChooseRoom_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_ChooseRoom_bak_20251027
        FROM    dbo.s_ChooseRoom
        where s_ChooseRoom.ProjGUID =@ProjGUID;

        UPDATE  s_ChooseRoom
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ChooseRoom.ProjGUID) 

        PRINT N'修改选房设置表:s_ChooseRoom' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--合同表（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_Contract_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Contract_bak_20251027
        FROM    dbo.s_Contract
        where s_Contract.ProjGUID =@ProjGUID;

        UPDATE  s_Contract
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Contract.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT N'修改合同表:s_Contract' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--产权收件回执（ProjGUID不为空）（已核实已处理）*';
        IF OBJECT_ID(N's_Cqsjhz_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Cqsjhz_bak_20251027
        FROM    dbo.s_Cqsjhz
        where s_Cqsjhz.ProjGUID =@ProjGUID;

        UPDATE  s_Cqsjhz
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Cqsjhz.ProjGUID) 

        PRINT N'修改产权收件回执:s_Cqsjhz' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--代收费用定义（ProjGUID不为空）“代收费用设置”项目级（已核实已处理）*';
        IF OBJECT_ID(N's_DsFeeSet_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_DsFeeSet_bak_20251027
        FROM    dbo.s_DsFeeSet
        where s_DsFeeSet.ProjGUID =@ProjGUID;

        UPDATE  s_DsFeeSet
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_DsFeeSet.ProjGUID) 

        PRINT N'修改代收费用定义:s_DsFeeSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--合同明细（ProjGUID不为空）（已核实已处理）*';
        IF OBJECT_ID(N's_HtDetail_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_HtDetail_bak_20251027
        FROM    dbo.s_HtDetail
        where s_HtDetail.ProjGUID =@ProjGUID;

        UPDATE  s_HtDetail
        SET s_HtDetail.BUGUID = @NewBUGUID,
            s_HtDetail.ProjName = REPLACE(s_HtDetail.ProjName, a.OldTopProjName, a.NewTopProjName )
        from  #Pro a
                INNER JOIN s_HtDetail ON s_HtDetail.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_HtDetail.ProjGUID) 

        PRINT N'修改合同明细:s_HtDetail' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  
        PRINT '--合同明细临时表 （已核实已处理）*';
        IF OBJECT_ID(N's_HtDetail_Template_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_HtDetail_Template_bak_20251027
        FROM    dbo.s_HtDetail_Template
        where s_HtDetail_Template.ProjGUID =@ProjGUID;


        UPDATE  s_HtDetail_Template
        SET s_HtDetail_Template.BUGUID = @NewBUGUID,
            s_HtDetail_Template.ProjName = REPLACE(s_HtDetail_Template.ProjName, a.OldTopProjName, a.NewTopProjName   )  
        from  #Pro a
                INNER JOIN s_HtDetail_Template ON s_HtDetail_Template.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_HtDetail_Template.ProjGUID) 

        PRINT N'修改合同明细临时表:s_HtDetail_Template' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--线索信息（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_Lead_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Lead_bak_20251027
        FROM    dbo.s_Lead
        where s_Lead.ProjGUID =@ProjGUID;

        UPDATE  s_Lead
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Lead.ProjGUID);
        PRINT N'修改线索信息:s_Lead' + CONVERT(NVARCHAR(20), @@ROWCOUNT); 

        PRINT '--****营销方案（ProjGUID不为空）服务器32、40数据 有空数据 添加时项目不能为空  待确认 项目不空（已核实已处理）*';

        IF OBJECT_ID(N's_MarketingPlan_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_MarketingPlan_bak_20251027
        FROM    dbo.s_MarketingPlan
        where s_MarketingPlan.ProjGUID =@ProjGUID;

        UPDATE  s_MarketingPlan
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_MarketingPlan.ProjGUID);

        PRINT N'修改营销方案:s_MarketingPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--销售机会（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_Opportunity_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Opportunity_bak_20251027
        FROM    dbo.s_Opportunity
        where s_Opportunity.ProjGUID =@ProjGUID;

        UPDATE  s_Opportunity
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Opportunity.ProjGUID);

        PRINT N'修改销售机会:s_Opportunity' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--定单（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_Order_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Order_bak_20251027
        FROM    dbo.s_Order
        where s_Order.ProjGUID =@ProjGUID;

        UPDATE  s_Order
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Order.ProjGUID) 

        PRINT N'修改定单:s_Order' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--置业计划定单表（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_OrderTmp_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_OrderTmp_bak_20251027
        FROM    dbo.s_OrderTmp
        where s_OrderTmp.ProjGUID =@ProjGUID;

        UPDATE  s_OrderTmp
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_OrderTmp.ProjGUID) 

        PRINT N'修改置业计划定单表:s_OrderTmp' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--价格变更（RoomGUID不为空,RoomGUID关联）（已核实已处理）*';

        IF OBJECT_ID(N's_PriceChg_bak_20251027', N'U') IS NULL
        SELECT  s_PriceChg.*
        INTO    dbo.s_PriceChg_bak_20251027
        FROM    dbo.s_PriceChg 
        INNER JOIN p_room ON s_PriceChg.RoomGUID = p_room.RoomGUID
        where p_room.ProjGUID =@ProjGUID;

        UPDATE  s_PriceChg
        SET s_PriceChg.BUGUID = @NewBUGUID
        FROM    s_PriceChg
                INNER JOIN p_room ON s_PriceChg.RoomGUID = p_room.RoomGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p_room.ProjGUID) 

        PRINT N'修改价格变更:s_PriceChg' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--认购书编号本（仅有BUGUID）';

        IF OBJECT_ID(N's_PotocolNO_bak_20251027', N'U') IS NULL
        SELECT  s_PotocolNO.*
        INTO    dbo.s_PotocolNO_bak_20251027
        FROM    dbo.s_PotocolNO s_PotocolNO
        INNER JOIN p_PotocolNO2Proj ON p_PotocolNO2Proj.PotocolNoGUID = s_PotocolNO.PotocolNoGUID
        where p_PotocolNO2Proj.ProjGUID =@ProjGUID;

        UPDATE  pno
        SET BUGUID = @NewBUGUID
        FROM    s_PotocolNO pno
                INNER JOIN p_PotocolNO2Proj ON p_PotocolNO2Proj.PotocolNoGUID = pno.PotocolNoGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p_PotocolNO2Proj.ProjGUID) 

        PRINT N'修改认购书编号本:s_PotocolNO' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--项目货值控制表（ProjGUID不为空）（已核实已处理）*';
        
        IF OBJECT_ID(N's_ProjHZKZ_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_ProjHZKZ_bak_20251027
        FROM    dbo.s_ProjHZKZ
        where s_ProjHZKZ.ProjGUID =@ProjGUID;

        UPDATE  s_ProjHZKZ
        SET BUGUID = @NewBUGUID,
            ParentProjGUID = a.NewTopProjGUID
        from #Pro a
                INNER JOIN s_ProjHZKZ ON s_ProjHZKZ.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ProjHZKZ.ProjGUID);

        PRINT N'修改项目货值控制表:s_ProjHZKZ' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        -- PRINT '--项目立项货值表（ProjGUID不为空）（已核实已处理）*';
        -- IF OBJECT_ID(N's_ProjLX_bak_20251027', N'U') IS NULL
        -- SELECT  *
        -- INTO    dbo.s_ProjLX_bak_20251027
        -- FROM    dbo.s_ProjLX
        -- where s_ProjLX.ProjGUID =@ProjGUID;

        -- UPDATE  s_ProjLX
        -- SET BUGUID = @NewBUGUID,
        --     ParentProjGUID = a.NewParentProjGUID
        -- from #Pro a
        --         INNER JOIN s_ProjLX ON s_ProjLX.ProjGUID = a.ProjGUID
        -- WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ProjLX.ProjGUID) 

        -- PRINT N'修改项目立项货值表:s_ProjLX' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--销售日志（ProjGUID不为空）（已核实已处理）*';

        IF OBJECT_ID(N's_SaleDayLog_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleDayLog_bak_20251027
        FROM    dbo.s_SaleDayLog
        where s_SaleDayLog.ProjGUID =@ProjGUID;

        UPDATE  s_SaleDayLog
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleDayLog.ProjGUID) 

        PRINT N'修改销售日志:s_SaleDayLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--销售变更申请（ProjGUID不为空）空数据没有公司（已核实已处理）*';
        IF OBJECT_ID(N's_SaleModiApply_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleModiApply_bak_20251027
        FROM    dbo.s_SaleModiApply
        where s_SaleModiApply.ProjGUID =@ProjGUID;

        UPDATE  s_SaleModiApply
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleModiApply.ProjGUID);

        PRINT N'修改销售变更申请:s_SaleModiApply' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--销售变更日志（ProjGUID不为空）空数据没有公司（已核实已处理）*';

        IF OBJECT_ID(N's_SaleModiLog_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleModiLog_bak_20251027
        FROM    dbo.s_SaleModiLog
        where s_SaleModiLog.ProjGUID =@ProjGUID;

        UPDATE  s_SaleModiLog
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleModiLog.ProjGUID);

        PRINT N'修改销售变更日志:s_SaleModiLog' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '--调价方案（ProjGUID不为空）（已核实已处理）*';
        IF OBJECT_ID(N's_TjPlan_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_TjPlan_bak_20251027
        FROM    dbo.s_TjPlan
        where s_TjPlan.ProjGUID =@ProjGUID;

        UPDATE  s_TjPlan
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_TjPlan.ProjGUID) 

        PRINT N'修改调价方案:s_TjPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT ' --财务单据（ProjGUID不为空）（已核实已处理）*';
        IF OBJECT_ID(N's_Voucher_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Voucher_bak_20251027
        FROM    dbo.s_Voucher
        where s_Voucher.ProjGUID =@ProjGUID;

        UPDATE  s_Voucher
        SET BuGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Voucher.ProjGUID);

        PRINT N'修改财务单据:s_Voucher' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT ' --价格预测    ';
        PRINT '修复项目设置表里面由于投管项目更改所属平台公司导致的平台公司GUID不对的数据';

        IF OBJECT_ID(N's_PricePredictionSetInfo_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_PricePredictionSetInfo_bak_20251027
        FROM    dbo.s_PricePredictionSetInfo
        where s_PricePredictionSetInfo.MDMProjGUID =@ProjGUID;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    s_PricePredictionSetInfo a
                INNER JOIN dbo.mdm_Project mp ON a.MDMProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) 

        PRINT N'修改项目设置表:s_PricePredictionSetInfo' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '项目价格预测';

        IF OBJECT_ID(N's_PricePrediction_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_PricePrediction_bak_20251027
        FROM    dbo.s_PricePrediction
        where s_PricePrediction.ProjGUID =@ProjGUID;

        UPDATE  s_PricePrediction
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_PricePrediction.ProjGUID)

        PRINT N'修改项目价格预测:s_PricePrediction' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复项目价格预测表里面由于投管项目更改所属平台公司导致的平台公司GUID不对的数据';

        IF OBJECT_ID(N's_PricePrediction_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_PricePrediction_bak_20251027
        FROM    dbo.s_PricePrediction
        where s_PricePrediction.MDMProjGUID =@ProjGUID;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    s_PricePrediction a
                INNER JOIN dbo.mdm_Project mp ON a.MDMProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) 

        PRINT N'修改项目价格预测表:s_PricePrediction' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT ' --销售计划  ';
        PRINT '项目销售计划';

        IF OBJECT_ID(N's_SalesBudget_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SalesBudget_bak_20251027
        FROM    dbo.s_SalesBudget
        where s_SalesBudget.ProjGUID =@ProjGUID;

        UPDATE  s_SalesBudget
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SalesBudget.ProjGUID);

        PRINT N'修改项目销售计划:s_SalesBudget' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '项目销售计划历史版本';

        IF OBJECT_ID(N's_SalesBudgetHistory_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SalesBudgetHistory_bak_20251027
        FROM    dbo.s_SalesBudgetHistory
        where s_SalesBudgetHistory.ProjGUID =@ProjGUID;

        UPDATE  s_SalesBudgetHistory
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SalesBudgetHistory.ProjGUID);

        PRINT N'修改项目销售计划历史版本:s_SalesBudgetHistory' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复客户所属表由于项目所属公司变化导致的BUGUID不对数据';

        IF OBJECT_ID(N'p_CstAttach_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_CstAttach_bak_20251027
        FROM    dbo.p_CstAttach
        where p_CstAttach.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_CstAttach a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID);

        PRINT N'修复客户所属表:p_CstAttach' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复活动表由于项目所属公司变化导致的BUGUID不对数据';

        IF OBJECT_ID(N'p_Activity_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_Activity_bak_20251027
        FROM    dbo.p_Activity
        where p_Activity.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BuGUID = p.BUGUID
        FROM    p_Activity a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) ;

        PRINT N'修复活动表:p_Activity' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复客服接待表由于项目所属公司变化导致的BUGUID不对数据';
        
        IF OBJECT_ID(N'k_Receive_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.k_Receive_bak_20251027
        FROM    dbo.k_Receive
        where k_Receive.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    k_Receive a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) ;

        PRINT N'修复客服接待表:k_Receive' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  


        PRINT '修复客服任务表由于项目所属公司变化导致的BUGUID不对数据';
        
        IF OBJECT_ID(N'k_Task_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.k_Task_bak_20251027
        FROM    dbo.k_Task
        where k_Task.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    k_Task a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID);

        PRINT N'修复客服任务表:k_Task' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复合同类别对应表由于项目所属公司变化导致的BUGUID不对数据';
        IF OBJECT_ID(N'p_httype2JCProjNoCtrl_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_httype2JCProjNoCtrl_bak_20251027
        FROM    dbo.p_httype2JCProjNoCtrl
        where p_httype2JCProjNoCtrl.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_httype2JCProjNoCtrl a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID);

        PRINT N'修复合同类别对应表:p_httype2JCProjNoCtrl' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复项目打印设置表由于项目所属公司变化导致的BUGUID不对数据';

        IF OBJECT_ID(N'p_PrintSet_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_PrintSet_bak_20251027
        FROM    dbo.p_PrintSet
        where p_PrintSet.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_PrintSet a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) ;

        PRINT N'修复项目打印设置表:p_PrintSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        -- PRINT '修复项目打印设置模板表由于项目所属公司变化导致的BUGUID不对数据';
        -- IF OBJECT_ID(N'p_PrintSetTemplate_bak_20251027', N'U') IS NULL
        -- SELECT  *
        -- INTO    dbo.p_PrintSetTemplate_bak_20251027
        -- FROM    dbo.p_PrintSetTemplate
        -- where p_PrintSetTemplate.ProjGUID =@ProjGUID;

        -- UPDATE  a
        -- SET a.BUGUID = p.BUGUID
        -- FROM    p_PrintSet a
        --         INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        -- WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) ;

        -- PRINT N'修复项目打印设置模板表:p_PrintSetTemplate' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复楼栋产品表由于项目所属公司变化导致的BUGUID不对数据';

        IF OBJECT_ID(N'p_BuildProduct_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_BuildProduct_bak_20251027
        FROM    dbo.p_BuildProduct
        where p_BuildProduct.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID,
            a.ParentCode =REPLACE(a.ParentCode, proj.OldTopProjCode, proj.NewTopProjCode),
            a.BProductCode =REPLACE(a.BProductCode, proj.OldTopProjCode, proj.NewTopProjCode)
        FROM    p_BuildProduct a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
                inner join  #Pro proj on proj.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) ;

        PRINT N'修复楼栋产品表:p_BuildProduct' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复项目立项表由于项目所属公司变化导致的BUGUID不对数据';

        IF OBJECT_ID(N's_ProjLX_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_ProjLX_bak_20251027
        FROM    dbo.s_ProjLX
        where s_ProjLX.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = p.BUGUID,
            a.ParentProjGUID =proj.NewTopProjGUID
        FROM    s_ProjLX a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
                inner join  #Pro proj on proj.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) 

        PRINT N'修复项目立项表:s_ProjLX' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        --货值铺排 2018年7月30日添加
        PRINT '修复货值铺排明细平台公司GUID';

        IF OBJECT_ID(N's_SaleValuePlan_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleValuePlan_bak_20251027
        FROM    dbo.s_SaleValuePlan
        where s_SaleValuePlan.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    s_SaleValuePlan a
                INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) 

        PRINT N'修复货值铺排明细平台公司GUID:s_SaleValuePlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复货值铺排历史明细平台公司GUID';

        IF OBJECT_ID(N's_SaleValuePlanHistory_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleValuePlanHistory_bak_20251027
        FROM    dbo.s_SaleValuePlanHistory
        where s_SaleValuePlanHistory.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValuePlanHistory a
                INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) 

        PRINT N'修复货值铺排历史明细平台公司GUID:s_SaleValuePlanHistory' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复货值铺排版本表平台公司GUID';

        IF OBJECT_ID(N's_SaleValuePlanVersion_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleValuePlanVersion_bak_20251027
        FROM    dbo.s_SaleValuePlanVersion
        where s_SaleValuePlanVersion.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValuePlanVersion a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) ;

        PRINT N'修复货值铺排版本表平台公司GUID:s_SaleValuePlanVersion' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复货值铺排步骤表平台公司GUID';

        IF OBJECT_ID(N's_SaleValueVersionStep_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleValueVersionStep_bak_20251027
        FROM    dbo.s_SaleValueVersionStep
        where s_SaleValueVersionStep.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueVersionStep a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) ;

        PRINT N'修复货值铺排步骤表平台公司GUID:s_SaleValueVersionStep' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复货值铺排铺排结果表平台公司GUID';

        IF OBJECT_ID(N's_SaleValueBuildLayout_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleValueBuildLayout_bak_20251027
        FROM    dbo.s_SaleValueBuildLayout
        where s_SaleValueBuildLayout.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueBuildLayout a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) ;

        PRINT N'修复货值铺排铺排结果表平台公司GUID:s_SaleValueBuildLayout' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复货值铺排楼栋底表平台公司GUID';

        IF OBJECT_ID(N's_SaleValueBuilding_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleValueBuilding_bak_20251027
        FROM    dbo.s_SaleValueBuilding
        where s_SaleValueBuilding.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueBuilding a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) ;

        PRINT N'修复货值铺排楼栋底表平台公司GUID:s_SaleValueBuilding' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '修复货值铺排铺排明细表平台公司GUID';
        IF OBJECT_ID(N's_ProjQhfa_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_ProjQhfa_bak_20251027
        FROM    dbo.s_ProjQhfa
        where s_ProjQhfa.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_ProjQhfa a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) ;

        PRINT N'修复货值铺排铺排明细表平台公司GUID:s_ProjQhfa' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '折扣方案所属公司修复';

        IF OBJECT_ID(N's_DiscountScheme_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_DiscountScheme_bak_20251027
        FROM    dbo.s_DiscountScheme
        where s_DiscountScheme.ProjGUID =@ProjGUID;

        UPDATE  b
        SET b.BUGUID = a.BUGUID
        FROM    dbo.p_Project a
                INNER JOIN dbo.s_DiscountScheme b ON b.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) ;

        PRINT N'修复折扣方案所属公司修复:s_DiscountScheme' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT 's_fee_collect_Yunke';

        IF OBJECT_ID(N's_fee_collect_Yunke_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_fee_collect_Yunke_bak_20251027
        FROM    dbo.s_fee_collect_Yunke
        where s_fee_collect_Yunke.ProjGUID =@ProjGUID;

        UPDATE  b
        SET b.BUGUID = a.BUGUID
        FROM    dbo.p_Project a
                INNER JOIN dbo.s_fee_collect_Yunke b ON b.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) ;

        PRINT N'修复s_fee_collect_Yunke:s_fee_collect_Yunke' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT 's_getin_collect_Yunke';

        IF OBJECT_ID(N's_getin_collect_Yunke_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_getin_collect_Yunke_bak_20251027
        FROM    dbo.s_getin_collect_Yunke
        where s_getin_collect_Yunke.ProjGUID =@ProjGUID;

        UPDATE  b
        SET b.BUGUID = a.BUGUID
        FROM    dbo.p_Project a
                INNER JOIN dbo.s_getin_collect_Yunke b ON b.ProjGUID = a.ProjGUID
        WHERE   1 = 1 ;

        PRINT N'修复s_getin_collect_Yunke:s_getin_collect_Yunke' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '财务接口';

        IF OBJECT_ID(N'p_cwjkproject_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.p_cwjkproject_bak_20251027
        FROM    dbo.p_cwjkproject
        where p_cwjkproject.ProjGUID =@ProjGUID;

        UPDATE  b
        SET b.BUGUID = p.BUGUID
        FROM    dbo.p_cwjkproject a
                INNER JOIN dbo.p_cwjkcompany b ON b.CompanyGUID = a.CompanyGUID
                INNER JOIN dbo.p_Project p ON p.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) ;

        PRINT N'修复财务接口:p_cwjkproject' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '财务票据';

        IF OBJECT_ID(N'p_Invoice_bak_20251027', N'U') IS NULL
        SELECT  a.*
        INTO    dbo.p_Invoice_bak_20251027
        FROM    dbo.p_Invoice a
		LEFT JOIN p_InvoiceDetail b WITH(NOLOCK)ON a.InvoGUID = b.InvoGUID
		LEFT JOIN s_Voucher c WITH(NOLOCK)ON c.InvoDetailGUID = b.InvoDetailGUID
        where c.ProjGUID =@ProjGUID;

        UPDATE  a
        SET a.BuGUID = c.BuGUID
        FROM    p_Invoice a WITH(NOLOCK)
                LEFT JOIN p_InvoiceDetail b WITH(NOLOCK)ON a.InvoGUID = b.InvoGUID
                LEFT JOIN s_Voucher c WITH(NOLOCK)ON c.InvoDetailGUID = b.InvoDetailGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = c.ProjGUID) ;

        PRINT N'修复财务票据:p_Invoice' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '合作项目业绩';
        IF OBJECT_ID(N's_YJRLProjSet_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_YJRLProjSet_bak_20251027
        FROM    dbo.s_YJRLProjSet
        where s_YJRLProjSet.ProjGUID =@ProjGUID;

        UPDATE  p
        SET p.BUGuid = p1.BUGUID
        FROM    s_YJRLProjSet p
                LEFT JOIN dbo.p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) ;

        PRINT N'修复合作项目业绩:s_YJRLProjSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '特殊业绩';
        PRINT '备案价录入申请表s_BajlrPlan';

        IF OBJECT_ID(N's_BajlrPlan_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_BajlrPlan_bak_20251027
        FROM    dbo.s_BajlrPlan
        where s_BajlrPlan.ProjGUID =@ProjGUID;

        UPDATE  p
        SET p.BuGuid = p1.BUGUID
        FROM    s_BajlrPlan p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGuid
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) ;

        PRINT N'修复备案价录入申请表:s_BajlrPlan' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT '更新备案价录入申请表s_BajlrPlan';
        IF OBJECT_ID(N's_fee_collect_Yunke_wide_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_fee_collect_Yunke_wide_bak_20251027
        FROM    dbo.s_fee_collect_Yunke_wide
        where s_fee_collect_Yunke_wide.ProjGUID =@ProjGUID;

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_fee_collect_Yunke_wide p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) ;

        PRINT N'修复更新备案价铺排申请表:s_fee_collect_Yunke_wide' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT 's_getin_collect_Yunke_wide';

        IF OBJECT_ID(N's_getin_collect_Yunke_wide_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_getin_collect_Yunke_wide_bak_20251027
        FROM    dbo.s_getin_collect_Yunke_wide
        where s_getin_collect_Yunke_wide.ProjGUID =@ProjGUID;

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_getin_collect_Yunke_wide p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) ;

        PRINT N'修复s_getin_collect_Yunke_wide:s_getin_collect_Yunke_wide' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        PRINT 's_SaleHsData_Yunke_wide';

        IF OBJECT_ID(N's_SaleHsData_Yunke_wide_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleHsData_Yunke_wide_bak_20251027
        FROM    dbo.s_SaleHsData_Yunke_wide
        where s_SaleHsData_Yunke_wide.ProjGUID =@ProjGUID;

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_SaleHsData_Yunke_wide p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) ;

        PRINT N'修复s_SaleHsData_Yunke_wide:s_SaleHsData_Yunke_wide' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        IF OBJECT_ID(N'S_PerformanceProjectSet_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.S_PerformanceProjectSet_bak_20251027
        FROM    dbo.S_PerformanceProjectSet
        where S_PerformanceProjectSet.ProjGUID =@ProjGUID;

        UPDATE  p
        SET p.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID,
            p.ParentProjGUID =proj.NewTopProjGUID
        --SELECT p.DevelopmentCompanyGUID ,
        --       mp.DevelopmentCompanyGUID
        FROM    S_PerformanceProjectSet p
                LEFT JOIN dbo.mdm_Project mp ON p.ProjGUID = mp.ProjGUID
                left join #Pro proj on proj.ProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) ;
        
        PRINT N'修复项目设置表:S_PerformanceProjectSet' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        --修改特殊业绩单据表
        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    S_PerformanceAppraisal a
                LEFT JOIN dbo.mdm_Project mp ON a.ManagementProjectGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) ;

        PRINT N'修复特殊业绩单据表:S_PerformanceAppraisal' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  


        --////////////////////////////////////  2025年新增业务表更新 开始 //////////////////////////////////////
        
        IF OBJECT_ID(N's_BizParamAdjustApplyProduct_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_BizParamAdjustApplyProduct_bak_20251027
        FROM    dbo.s_BizParamAdjustApplyProduct
        where s_BizParamAdjustApplyProduct.ProjGUID =@ProjGUID;

        update b set b.BuGuid = p1.BUGUID
        from  s_BizParamAdjustApplyProduct a
        inner join  s_BizParamAdjustApply b on a.BizParamAdjustApplyGUID =b.BizParamAdjustApplyGUID
        LEFT JOIN p_Project p1 ON p1.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) ;

        PRINT N'修复业务参数申请产品类型:s_BizParamAdjustApplyProduct' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  


       /*  142测试环境没有s_CelProjectSaleInfo表，先注释处理
       UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_CelProjectSaleInfo p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGUID <> p1.BUGUID;
        print  's_CelProjectSaleInfo'
         
        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_CelProjectSaleInfo p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGUID <> p1.BUGUID; 
        print 's_CelProjectSaleInfo_User'

       */

        IF OBJECT_ID(N's_Contract_Pre_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_Contract_Pre_bak_20251027
        FROM    dbo.s_Contract_Pre
        where s_Contract_Pre.ProjGUID =@ProjGUID;

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_Contract_Pre p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) ;

        PRINT N'修复合同预呈批表:s_Contract_Pre' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  


        IF OBJECT_ID(N's_HTExtendedFieldData_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_HTExtendedFieldData_bak_20251027
        FROM    dbo.s_HTExtendedFieldData
        where s_HTExtendedFieldData.ProjGUID =@ProjGUID;

        UPDATE  b  set  b.buguid = p1.buguid
		FROM  s_HTExtendedFieldData a
		inner join s_HTExtendedField  b on a.HTExtendedFieldGUID =b.HTExtendedFieldGUID
                LEFT JOIN p_Project p1 ON p1.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) 

        PRINT N'修复合同拓展字段表:s_HTExtendedFieldData' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  

        IF OBJECT_ID(N's_SaleModiApplyBatch_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.s_SaleModiApplyBatch_bak_20251027
        FROM    dbo.s_SaleModiApplyBatch
        where s_SaleModiApplyBatch.ProjGUID =@ProjGUID;

        UPDATE  p set  p.buguid = p1.buguid
		FROM  s_SaleModiApplyBatch p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID)       

        PRINT N'修复批量变更申请表:s_SaleModiApplyBatch' + CONVERT(NVARCHAR(20), @@ROWCOUNT);  


        --////////////////////////////////////  2025年新增业务表更新 结束 //////////////////////////////////////
        PRINT '项目团队';

        IF OBJECT_ID(N'myStation_bak_20251027', N'U') IS NULL
        SELECT  *
        INTO    dbo.myStation_bak_20251027
        FROM    dbo.myStation
        where myStation.ProjGUID =@ProjGUID;

        UPDATE  st
        SET st.CompanyGUID = bu.CompanyGUID
        FROM    myBusinessUnit bu
                INNER JOIN dbo.p_Project p ON p.ProjGUID = bu.ProjGUID AND bu.BUType = 3 AND   p.Level = 2
                INNER JOIN dbo.myStation st ON st.BUGUID = bu.BUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) ;

        -- PRINT '解决销售文员选择不到之前录入的文本列表信息的问题，复制一份原公司的录入列表到新公司';

        -- INSERT INTO dbo.mySysData(SysID, Content, BUGUID, UserGUID)
        -- SELECT  a.SysID ,
        --         a.Content ,
        --         @NewBUGUID AS BUGUID ,
        --         a.UserGUID
        -- FROM    mySysData a
        -- WHERE   EXISTS (SELECT  1 FROM  #Pro p WHERE p.BUGUID = a.BUGUID)
        --         AND   a.SysID IN ('Clerk', 'Clerk2', 'ClerkAfter', 'ClerkAfter2', 'Qdjl', 'QdjlAfter', 'Qdzy', 'Qdzy2', 'QdzyAfter', 'QdzyAfter2', 'Xsjl', 'Xsjl2', 'XsjlAfter', 'XsjlAfter2', 'ywy' ,
        --                           'zygw' , 'zygw2', 'zygwAfter', 'zygwAfter2');

        --基础数据项目对应公司对照表刷新
        -- UPDATE  b
        -- SET b.OrgCompanyGUID = p.BUGUID
        -- FROM    dbo.p_Project p
        --         INNER JOIN MyCost_Erp352.dbo.md_Project2OrgCompany b ON b.ProjGUID = p.ProjGUID
        -- WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  p.BUGUID <> b.OrgCompanyGUID;

        --20210301add 新增p_PrintTemplate 认购书模板打印表修改

        --创建临时表，查询老公司项目对应的认购书模板并插入到临时表
        -- SELECT  DISTINCT a.PrintTemplateGUID ,
        --                  a.TemplateCode ,
        --                  a.TemplateName ,
        --                  a.TemplateType ,
        --                  a.RptID ,
        --                  CONVERT(VARCHAR(MAX), a.Comments) AS Comments ,
        --                  a.Application ,
        --                  a.BUGUID ,
        --                  a.Location ,
        --                  a.IsCreateByFPD
        -- INTO    #p_PrintTemplate
        -- FROM    p_PrintTemplate a
        --         LEFT JOIN p_PrintSet b ON a.PrintTemplateGUID = b.PrintTemplateGUID
        -- WHERE   b.ProjGUID IN(SELECT    ProjGUID
        --                       FROM  dbo.mdm_Project
        --                       WHERE DevelopmentCompanyGUID IN(SELECT    DevelopmentCompanyGUID
        --                                                       FROM  dbo.p_DevelopmentCompany
        --                                                       WHERE DevelopmentCompanyName = @OldBUName));

        -- --修改认购书模板的PrintTemplateGUID和BUGUID
        -- SELECT  a.PrintTemplateGUID ,
        --         NEWID() AS PrintTemplateGUIDNew ,
        --         a.TemplateCode ,
        --         a.TemplateName ,
        --         a.TemplateType ,
        --         a.RptID ,
        --         CONVERT(VARCHAR(MAX), a.Comments) AS Comments ,
        --         a.Application ,
        --         (SELECT BUGUID
        --          FROM   dbo.myBusinessUnit
        --          WHERE  BUName = @NewBUName AND IsEndCompany = 1) AS BUGUID ,   --新公司GUID
        --         a.Location ,
        --         a.IsCreateByFPD
        -- INTO    #p_PrintTemplate2
        -- FROM    #p_PrintTemplate a;

        -- --插入在新公司插入打印模板表p_PrintTemplate
        -- INSERT INTO dbo.p_PrintTemplate(PrintTemplateGUID, TemplateCode, TemplateName, TemplateType, RptID, Comments, Application, BUGUID, Location, IsCreateByFPD)
        -- SELECT  PrintTemplateGUIDNew ,
        --         TemplateCode ,
        --         TemplateName ,
        --         TemplateType ,
        --         RptID ,
        --         Comments ,
        --         Application ,
        --         BUGUID ,
        --         Location ,
        --         IsCreateByFPD
        -- FROM    #p_PrintTemplate2;

        -- --修改p_PrintSet表的PrintTemplateGUID
        -- UPDATE  b
        -- SET b.PrintTemplateGUID = a.PrintTemplateGUIDNew
        -- FROM    #p_PrintTemplate2 a
        --         INNER JOIN p_PrintSet b ON a.PrintTemplateGUID = b.PrintTemplateGUID
        -- WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = b.ProjGUID) AND  a.BUGUID <> b.BUGUID;

        

        --20210301add 新增p_PrintTemplate 认购书模板打印表修改

        --删除临时表
        -- DROP TABLE #p_PrintTemplate;
        -- DROP TABLE #p_PrintTemplate2;
        -- DROP TABLE #Pro;

        -- PRINT '款项类型参数设置';

        -- INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
        --                                  AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        -- SELECT  ParamName ,
        --         @NewBUGUID ,
        --         ParamValue ,
        --         ParamCode ,
        --         ParentCode ,
        --         ParamLevel ,
        --         IfEnd ,
        --         IfSys ,
        --         NEWID() ,
        --         IsAjSk ,
        --         IsQykxdc ,
        --         TaxItemsDetailCode ,
        --         IsCalcTax ,
        --         a.CompanyGUID ,
        --         AreaInfo ,
        --         IsLandCbDk ,
        --         ReceiveTypeValue ,
        --         NEWID() ,
        --         IsYxfjxzf ,
        --         ZTCategory
        -- FROM    myBizParamOption a
        --         INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        -- WHERE   bu.BUName = @OldBUName AND  ParamName = 's_FeeItem' AND NOT EXISTS (SELECT  1
        --                                                                             FROM    myBizParamOption b
        --                                                                             WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);

        -- PRINT '变更原因';

        -- INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
        --                                  AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        -- SELECT  ParamName ,
        --         @NewBUGUID ,
        --         ParamValue ,
        --         ParamCode ,
        --         ParentCode ,
        --         ParamLevel ,
        --         IfEnd ,
        --         IfSys ,
        --         NEWID() ,
        --         IsAjSk ,
        --         IsQykxdc ,
        --         TaxItemsDetailCode ,
        --         IsCalcTax ,
        --         a.CompanyGUID ,
        --         AreaInfo ,
        --         IsLandCbDk ,
        --         ReceiveTypeValue ,
        --         NEWID() ,
        --         IsYxfjxzf ,
        --         ZTCategory
        -- FROM    myBizParamOption a
        --         INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        -- WHERE   bu.BUName = @OldBUName AND  ParamName = 's_ReasonSort' AND  NOT EXISTS (SELECT  1
        --                                                                                 FROM    myBizParamOption b
        --                                                                                 WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);

        -- --回款比例
        -- INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
        --                                  AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        -- SELECT  ParamName ,
        --         @NewBUGUID ,
        --         ParamValue ,
        --         ParamCode ,
        --         ParentCode ,
        --         ParamLevel ,
        --         IfEnd ,
        --         IfSys ,
        --         NEWID() ,
        --         IsAjSk ,
        --         IsQykxdc ,
        --         TaxItemsDetailCode ,
        --         IsCalcTax ,
        --         a.CompanyGUID ,
        --         AreaInfo ,
        --         IsLandCbDk ,
        --         ReceiveTypeValue ,
        --         NEWID() ,
        --         IsYxfjxzf ,
        --         ZTCategory
        -- FROM    myBizParamOption a
        --         INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        -- WHERE   bu.BUName = @OldBUName AND  ParamName = 's_hkRate' AND  NOT EXISTS (SELECT  1
        --                                                                             FROM    myBizParamOption b
        --                                                                             WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);

        -- --发放比例
        -- INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
        --                                  AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        -- SELECT  ParamName ,
        --         @NewBUGUID ,
        --         ParamValue ,
        --         ParamCode ,
        --         ParentCode ,
        --         ParamLevel ,
        --         IfEnd ,
        --         IfSys ,
        --         NEWID() ,
        --         IsAjSk ,
        --         IsQykxdc ,
        --         TaxItemsDetailCode ,
        --         IsCalcTax ,
        --         a.CompanyGUID ,
        --         AreaInfo ,
        --         IsLandCbDk ,
        --         ReceiveTypeValue ,
        --         NEWID() ,
        --         IsYxfjxzf ,
        --         ZTCategory
        -- FROM    myBizParamOption a
        --         INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        -- WHERE   bu.BUName = @OldBUName AND  ParamName = 's_ffRate' AND  NOT EXISTS (SELECT  1
        --                                                                             FROM    myBizParamOption b
        --                                                                             WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);
    END;
