USE [erp25]
GO

/****** Object:  StoredProcedure [dbo].[usp_s_ProjectMove]    Script Date: 2024/6/13 18:36:30 ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;


/*2025年组织架构调整影响的表更新
-- s_BizParamAdjustApplyProduct	业务参数申请产品类型
-- s_CelProjectSaleInfo	
-- s_CelProjectSaleInfo_Msg	
-- s_CelProjectSaleInfo_User	业绩简讯的发送用户设置表
-- s_Contract_Pre	
-- s_HTExtendedFieldData	合同拓展字段表
-- s_SaleModiApplyBatch	批量变更申请表
*/
GO

alter PROC [dbo].[usp_s_ProjectMove](@OldBUName VARCHAR(MAX) ,
                                     @TopProjGUID VARCHAR(MAX) ,    --一级项目GUID
                                     @NewBUName VARCHAR(MAX))
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
 
     EXEC usp_s_ProjectMove '漳州公司','5742DA4E-5EAE-E711-80BA-E61F13C57837,F13693A6-E031-E811-80BA-E61F13C57837,9D41FA6D-0959-E811-80BB-E61F13C57837,C53EE2A0-43AE-E711-80BA-E61F13C57837','厦门公司'   
    
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
        PRINT '--创建项目待转移项目临时表';

        CREATE TABLE #Pro (BUGUID VARCHAR(100) ,
                           BUCODE VARCHAR(100) ,
                           ProjGUID VARCHAR(100) ,
                           ProjName VARCHAR(100));

        INSERT INTO #Pro(BUGUID, BUCODE, ProjGUID, ProjName)
        SELECT  p.BUGUID ,
                m.BUCode ,
                p.ProjGUID ,
                p.ProjName
        FROM    dbo.p_Project p
                LEFT JOIN dbo.myBusinessUnit m ON p.BUGUID = m.BUGUID
        WHERE   p.ProjGUID IN(SELECT    ProjGUID
                              FROM  p_Project
                              WHERE Level = 2 AND   ProjGUID IN(SELECT  Value FROM  [dbo].[fn_Split2](@TopProjGUID, ',') )
                              UNION
                              SELECT    p1.ProjGUID
                              FROM  p_Project p1
                                    LEFT JOIN p_Project p2 ON p1.ParentCode = p2.ProjCode
                              WHERE p1.Level = 3 AND p2.ProjGUID IN(SELECT  Value FROM  [dbo].[fn_Split2](@TopProjGUID, ',') )) AND p.ApplySys LIKE '%,0101,%';

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

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
            b.ProjCode = REPLACE(b.ProjCode, a.BUCODE, @NewBUCODE) ,
            b.ParentCode = REPLACE(b.ParentCode, a.BUCODE, @NewBUCODE)
        FROM    #Pro a
                INNER JOIN dbo.p_Project b ON a.ProjGUID = b.ProjGUID;

        PRINT '-------修改项目团队相关信息--------';

        ALTER TABLE myBusinessUnit DISABLE TRIGGER ALL;

        --erp25
        UPDATE  b
        SET b.BUCode = REPLACE(b.BUCode, a.BUCODE, @NewBUCODE) ,
            b.HierarchyCode = REPLACE(b.HierarchyCode, a.BUCODE, @NewBUCODE) ,
            b.ParentGUID = @NewBUGUID ,
            b.CompanyGUID = @NewBUGUID ,
            b.NamePath = REPLACE(b.NamePath, @OldBUName, @NewBUName)
        FROM    #Pro a
                INNER JOIN erp25.dbo.myBusinessUnit b ON b.ProjGUID = a.ProjGUID
        WHERE   1 = 1 AND   b.CompanyGUID <> @NewBUGUID;

        ALTER TABLE myBusinessUnit ENABLE TRIGGER ALL;

        --erp352
        ALTER TABLE MyCost_Erp352.dbo.myBusinessUnit DISABLE TRIGGER ALL;

        UPDATE  b
        SET b.BUCode = REPLACE(b.BUCode, a.BUCODE, @NewBUCODE) ,
            b.HierarchyCode = REPLACE(b.HierarchyCode, a.BUCODE, @NewBUCODE) ,
            b.ParentGUID = @NewBUGUID ,
            b.CompanyGUID = @NewBUGUID ,
            b.NamePath = REPLACE(b.NamePath, @OldBUName, @NewBUName)
        FROM    #Pro a
                INNER JOIN MyCost_Erp352.dbo.myBusinessUnit b ON b.ProjGUID = a.ProjGUID
        WHERE   1 = 1 AND   b.CompanyGUID <> @NewBUGUID;

        ALTER TABLE MyCost_Erp352.dbo.myBusinessUnit ENABLE TRIGGER ALL;

        --zulin   
        ALTER TABLE CRE_ERP_202_SYZL.dbo.myBusinessUnit DISABLE TRIGGER ALL;

        UPDATE  b
        SET b.BUCode = REPLACE(b.BUCode, a.BUCODE, @NewBUCODE) ,
            b.HierarchyCode = REPLACE(b.HierarchyCode, a.BUCODE, @NewBUCODE) ,
            b.ParentGUID = @NewBUGUID ,
            b.CompanyGUID = @NewBUGUID ,
            b.NamePath = REPLACE(b.NamePath, @OldBUName, @NewBUName)
        FROM    #Pro a
                INNER JOIN CRE_ERP_202_SYZL.dbo.myBusinessUnit b ON b.ProjGUID = a.ProjGUID
        WHERE   1 = 1 AND   b.CompanyGUID <> @NewBUGUID;

        ALTER TABLE CRE_ERP_202_SYZL.dbo.myBusinessUnit ENABLE TRIGGER ALL;

        --修改项目数据权限
        --erp25
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    erp25.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '项目'
        WHERE   1 = 1 AND   a.BUGUID <> p.BUGUID;

        --erp352        
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    MyCost_Erp352.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '项目'
        WHERE   1 = 1 AND   a.BUGUID <> p.BUGUID;

        --zulin       
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    CRE_ERP_202_SYZL.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '项目'
        WHERE   1 = 1 AND   a.BUGUID <> p.BUGUID;

        PRINT '---修改销售系统公司GUID开始----';
        PRINT '楼栋表';

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
            b.ParentCode = REPLACE(b.ParentCode, a.BUCODE, @NewBUCODE)
        FROM    #Pro a
                INNER JOIN dbo.p_Building b ON a.ProjGUID = b.ProjGUID
        WHERE   1 = 1 AND   b.BUGUID <> @NewBUGUID;

        PRINT '房间表';

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
            b.RoomCode = REPLACE(b.RoomCode, a.BUCODE, @NewBUCODE)
        FROM    #Pro a
                INNER JOIN dbo.p_room b ON a.ProjGUID = b.ProjGUID
        WHERE   1 = 1 AND   b.BUGUID <> @NewBUGUID;

        PRINT '--按揭银行（参数配置项目级）（ProjGUID不为空）“按揭银行设置”项目级按照项目处理、公司级按照公司处理（已核实已处理）*';

        UPDATE  s_Bank
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Bank.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--按揭银行（备份表）（已核实有数据未使用）*';

        UPDATE  s_BankBackUp
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BankBackUp.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--批量传递记录表（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_BatchPass
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BatchPass.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--办理房产证通知（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_BlFczTz
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BlFczTz.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--预约单（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_Booking
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Booking.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--选房设置表（ProjGUID不为空）项目级业务参数（已核实已处理）*';

        UPDATE  s_ChooseRoom
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ChooseRoom.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--合同表（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_Contract
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Contract.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--产权收件回执（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_Cqsjhz
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Cqsjhz.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--代收费用定义（ProjGUID不为空）“代收费用设置”项目级（已核实已处理）*';

        UPDATE  s_DsFeeSet
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_DsFeeSet.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--合同明细（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_HtDetail
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_HtDetail.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--合同明细临时表 （已核实已处理）*';

        UPDATE  s_HtDetail_Template
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_HtDetail_Template.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--线索信息（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_Lead
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Lead.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--****营销方案（ProjGUID不为空）服务器32、40数据 有空数据 添加时项目不能为空  待确认 项目不空（已核实已处理）*';

        UPDATE  s_MarketingPlan
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_MarketingPlan.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--销售机会（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_Opportunity
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Opportunity.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--定单（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_Order
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Order.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--置业计划定单表（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_OrderTmp
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_OrderTmp.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--价格变更（RoomGUID不为空,RoomGUID关联）（已核实已处理）*';

        UPDATE  s_PriceChg
        SET s_PriceChg.BUGUID = @NewBUGUID
        FROM    s_PriceChg
                INNER JOIN p_room ON s_PriceChg.RoomGUID = p_room.RoomGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p_room.ProjGUID) AND s_PriceChg.BUGUID <> @NewBUGUID;

        PRINT '--认购书编号本（仅有BUGUID）';

        UPDATE  pno
        SET BUGUID = @NewBUGUID
        FROM    s_PotocolNO pno
                INNER JOIN p_PotocolNO2Proj ON p_PotocolNO2Proj.PotocolNoGUID = pno.PotocolNoGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p_PotocolNO2Proj.ProjGUID) AND   pno.BUGUID <> @NewBUGUID;

        PRINT '--项目货值控制表（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_ProjHZKZ
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ProjHZKZ.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--项目立项货值表（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_ProjLX
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ProjLX.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--销售日志（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_SaleDayLog
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleDayLog.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--销售变更申请（ProjGUID不为空）空数据没有公司（已核实已处理）*';

        UPDATE  s_SaleModiApply
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleModiApply.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--销售变更日志（ProjGUID不为空）空数据没有公司（已核实已处理）*';

        UPDATE  s_SaleModiLog
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleModiLog.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--调价方案（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_TjPlan
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_TjPlan.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT ' --财务单据（ProjGUID不为空）（已核实已处理）*';

        UPDATE  s_Voucher
        SET BuGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Voucher.ProjGUID) AND  BuGUID <> @NewBUGUID;

        PRINT ' --价格预测    ';
        PRINT '修复项目设置表里面由于投管项目更改所属平台公司导致的平台公司GUID不对的数据';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    s_PricePredictionSetInfo a
                INNER JOIN dbo.mdm_Project mp ON a.MDMProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) AND a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '项目价格预测';

        UPDATE  s_PricePrediction
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_PricePrediction.ProjGUID);

        PRINT '修复项目价格预测表里面由于投管项目更改所属平台公司导致的平台公司GUID不对的数据';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    s_PricePrediction a
                INNER JOIN dbo.mdm_Project mp ON a.MDMProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) AND a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT ' --销售计划  ';
        PRINT '项目销售计划';

        UPDATE  s_SalesBudget
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SalesBudget.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '项目销售计划历史版本';

        UPDATE  s_SalesBudgetHistory
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SalesBudgetHistory.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '修复客户所属表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_CstAttach a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '修复活动表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BuGUID = p.BUGUID
        FROM    p_Activity a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BuGUID <> p.BUGUID;

        PRINT '修复客服接待表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    k_Receive a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '修复客服任务表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    k_Task a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '修复合同类别对应表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_httype2JCProjNoCtrl a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '修复项目打印设置表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_PrintSet a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '修复项目打印设置模板表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_PrintSet a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '修复楼栋产品表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_BuildProduct a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '修复项目立项表由于项目所属公司变化导致的BUGUID不对数据';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    s_ProjLX a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        --货值铺排 2018年7月30日添加
        PRINT '修复货值铺排明细平台公司GUID';

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    s_SaleValuePlan a
                INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.BUGUID <> mp.DevelopmentCompanyGUID;

        PRINT '修复货值铺排历史明细平台公司GUID';

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValuePlanHistory a
                INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.BUGUID <> mp.DevelopmentCompanyGUID;

        PRINT '修复货值铺排版本表平台公司GUID';

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValuePlanVersion a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.BUGUID <> mp.DevelopmentCompanyGUID;

        PRINT '修复货值铺排步骤表平台公司GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueVersionStep a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '修复货值铺排铺排结果表平台公司GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueBuildLayout a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '修复货值铺排楼栋底表平台公司GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueBuilding a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '修复货值铺排铺排明细表平台公司GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_ProjQhfa a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '折扣方案所属公司修复';

        UPDATE  b
        SET b.BUGUID = a.BUGUID
        FROM    dbo.p_Project a
                INNER JOIN dbo.s_DiscountScheme b ON b.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  b.BUGUID <> @NewBUGUID;

        PRINT 's_fee_collect_Yunke';

        UPDATE  b
        SET b.BUGUID = a.BUGUID
        FROM    dbo.p_Project a
                INNER JOIN dbo.s_fee_collect_Yunke b ON b.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  b.BUGUID <> a.BUGUID;

        PRINT 's_getin_collect_Yunke';

        UPDATE  b
        SET b.BUGUID = a.BUGUID
        FROM    dbo.p_Project a
                INNER JOIN dbo.s_getin_collect_Yunke b ON b.ProjGUID = a.ProjGUID
        WHERE   1 = 1 AND   b.BUGUID <> a.BUGUID;

        PRINT '财务接口';

        UPDATE  b
        SET b.BUGUID = p.BUGUID
        FROM    dbo.p_cwjkproject a
                INNER JOIN dbo.p_cwjkcompany b ON b.CompanyGUID = a.CompanyGUID
                INNER JOIN dbo.p_Project p ON p.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  b.BUGUID <> p.BUGUID;

        PRINT '财务票据';

        UPDATE  a
        SET a.BuGUID = c.BuGUID
        FROM    p_Invoice a WITH(NOLOCK)
                LEFT JOIN p_InvoiceDetail b WITH(NOLOCK)ON a.InvoGUID = b.InvoGUID
                LEFT JOIN s_Voucher c WITH(NOLOCK)ON c.InvoDetailGUID = b.InvoDetailGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = c.ProjGUID) AND  a.BuGUID <> c.BuGUID;

        PRINT '合作项目业绩';

        UPDATE  p
        SET p.BUGuid = p1.BUGUID
        FROM    s_YJRLProjSet p
                LEFT JOIN dbo.p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGuid <> p1.BUGUID;

        PRINT '特殊业绩';
        PRINT '备案价录入申请表s_BajlrPlan';

        UPDATE  p
        SET p.BuGuid = p1.BUGUID
        FROM    s_BajlrPlan p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGuid
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BuGuid <> p1.BUGUID;

        PRINT '更新备案价录入申请表s_BajlrPlan';

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_fee_collect_Yunke_wide p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGUID <> p1.BUGUID;

        PRINT 's_getin_collect_Yunke_wide';

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_getin_collect_Yunke_wide p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGUID <> p1.BUGUID;

        PRINT 's_SaleHsData_Yunke_wide';

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_SaleHsData_Yunke_wide p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGUID <> p1.BUGUID;

        UPDATE  p
        SET p.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        --SELECT p.DevelopmentCompanyGUID ,
        --       mp.DevelopmentCompanyGUID
        FROM    S_PerformanceProjectSet p
                LEFT JOIN dbo.mdm_Project mp ON p.ProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) AND p.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        --修改特殊业绩单据表
        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    S_PerformanceAppraisal a
                LEFT JOIN dbo.mdm_Project mp ON a.ManagementProjectGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) AND a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;


        --////////////////////////////////////  2025年新增业务表更新 开始 //////////////////////////////////////
        
        update b set b.BuGuid = p1.BUGUID
        from  s_BizParamAdjustApplyProduct a
        inner join  s_BizParamAdjustApply b on a.BizParamAdjustApplyGUID =b.BizParamAdjustApplyGUID
        LEFT JOIN p_Project p1 ON p1.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND b.BUGUID <> p1.BUGUID;
        print '业务参数申请产品类型s_BizParamAdjustApplyProduct'    

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

        UPDATE  p
        SET p.BUGUID = p1.BUGUID
        FROM    s_Contract_Pre p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGUID <> p1.BUGUID; 
        print 's_Contract_Pre'

        UPDATE  b  set  b.buguid = p1.buguid
		FROM  s_HTExtendedFieldData a
		inner join s_HTExtendedField  b on a.HTExtendedFieldGUID =b.HTExtendedFieldGUID
                LEFT JOIN p_Project p1 ON p1.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND b.BUGUID <> p1.BUGUID;        
        print  '合同拓展字段表s_HTExtendedField'

        UPDATE  p set  p.buguid = p1.buguid
		FROM  s_SaleModiApplyBatch p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGUID <> p1.BUGUID;        
        print '批量变更申请表s_SaleModiApplyBatch'


        --////////////////////////////////////  2025年新增业务表更新 结束 //////////////////////////////////////
        PRINT '项目团队';

        UPDATE  st
        SET st.CompanyGUID = bu.CompanyGUID
        FROM    myBusinessUnit bu
                INNER JOIN dbo.p_Project p ON p.ProjGUID = bu.ProjGUID AND bu.BUType = 3 AND   p.Level = 2
                INNER JOIN dbo.myStation st ON st.BUGUID = bu.BUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  st.CompanyGUID <> bu.CompanyGUID;

        PRINT '解决销售文员选择不到之前录入的文本列表信息的问题，复制一份原公司的录入列表到新公司';

        INSERT INTO dbo.mySysData(SysID, Content, BUGUID, UserGUID)
        SELECT  a.SysID ,
                a.Content ,
                @NewBUGUID AS BUGUID ,
                a.UserGUID
        FROM    mySysData a
        WHERE   EXISTS (SELECT  1 FROM  #Pro p WHERE p.BUGUID = a.BUGUID)
                AND   a.SysID IN ('Clerk', 'Clerk2', 'ClerkAfter', 'ClerkAfter2', 'Qdjl', 'QdjlAfter', 'Qdzy', 'Qdzy2', 'QdzyAfter', 'QdzyAfter2', 'Xsjl', 'Xsjl2', 'XsjlAfter', 'XsjlAfter2', 'ywy' ,
                                  'zygw' , 'zygw2', 'zygwAfter', 'zygwAfter2');

        --基础数据项目对应公司对照表刷新
        UPDATE  b
        SET b.OrgCompanyGUID = p.BUGUID
        FROM    dbo.p_Project p
                INNER JOIN MyCost_Erp352.dbo.md_Project2OrgCompany b ON b.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  p.BUGUID <> b.OrgCompanyGUID;

        --20210301add 新增p_PrintTemplate 认购书模板打印表修改

        --创建临时表，查询老公司项目对应的认购书模板并插入到临时表
        SELECT  DISTINCT a.PrintTemplateGUID ,
                         a.TemplateCode ,
                         a.TemplateName ,
                         a.TemplateType ,
                         a.RptID ,
                         CONVERT(VARCHAR(MAX), a.Comments) AS Comments ,
                         a.Application ,
                         a.BUGUID ,
                         a.Location ,
                         a.IsCreateByFPD
        INTO    #p_PrintTemplate
        FROM    p_PrintTemplate a
                LEFT JOIN p_PrintSet b ON a.PrintTemplateGUID = b.PrintTemplateGUID
        WHERE   b.ProjGUID IN(SELECT    ProjGUID
                              FROM  dbo.mdm_Project
                              WHERE DevelopmentCompanyGUID IN(SELECT    DevelopmentCompanyGUID
                                                              FROM  dbo.p_DevelopmentCompany
                                                              WHERE DevelopmentCompanyName = @OldBUName));

        --修改认购书模板的PrintTemplateGUID和BUGUID
        SELECT  a.PrintTemplateGUID ,
                NEWID() AS PrintTemplateGUIDNew ,
                a.TemplateCode ,
                a.TemplateName ,
                a.TemplateType ,
                a.RptID ,
                CONVERT(VARCHAR(MAX), a.Comments) AS Comments ,
                a.Application ,
                (SELECT BUGUID
                 FROM   dbo.myBusinessUnit
                 WHERE  BUName = @NewBUName AND IsEndCompany = 1) AS BUGUID ,   --新公司GUID
                a.Location ,
                a.IsCreateByFPD
        INTO    #p_PrintTemplate2
        FROM    #p_PrintTemplate a;

        --插入在新公司插入打印模板表p_PrintTemplate
        INSERT INTO dbo.p_PrintTemplate(PrintTemplateGUID, TemplateCode, TemplateName, TemplateType, RptID, Comments, Application, BUGUID, Location, IsCreateByFPD)
        SELECT  PrintTemplateGUIDNew ,
                TemplateCode ,
                TemplateName ,
                TemplateType ,
                RptID ,
                Comments ,
                Application ,
                BUGUID ,
                Location ,
                IsCreateByFPD
        FROM    #p_PrintTemplate2;

        --修改p_PrintSet表的PrintTemplateGUID
        UPDATE  b
        SET b.PrintTemplateGUID = a.PrintTemplateGUIDNew
        FROM    #p_PrintTemplate2 a
                INNER JOIN p_PrintSet b ON a.PrintTemplateGUID = b.PrintTemplateGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = b.ProjGUID) AND  a.BUGUID <> b.BUGUID;

        

        --20210301add 新增p_PrintTemplate 认购书模板打印表修改

        --删除临时表
        DROP TABLE #p_PrintTemplate;
        DROP TABLE #p_PrintTemplate2;
        DROP TABLE #Pro;

        PRINT '款项类型参数设置';

        INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
                                         AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        SELECT  ParamName ,
                @NewBUGUID ,
                ParamValue ,
                ParamCode ,
                ParentCode ,
                ParamLevel ,
                IfEnd ,
                IfSys ,
                NEWID() ,
                IsAjSk ,
                IsQykxdc ,
                TaxItemsDetailCode ,
                IsCalcTax ,
                a.CompanyGUID ,
                AreaInfo ,
                IsLandCbDk ,
                ReceiveTypeValue ,
                NEWID() ,
                IsYxfjxzf ,
                ZTCategory
        FROM    myBizParamOption a
                INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        WHERE   bu.BUName = @OldBUName AND  ParamName = 's_FeeItem' AND NOT EXISTS (SELECT  1
                                                                                    FROM    myBizParamOption b
                                                                                    WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);

        PRINT '变更原因';

        INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
                                         AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        SELECT  ParamName ,
                @NewBUGUID ,
                ParamValue ,
                ParamCode ,
                ParentCode ,
                ParamLevel ,
                IfEnd ,
                IfSys ,
                NEWID() ,
                IsAjSk ,
                IsQykxdc ,
                TaxItemsDetailCode ,
                IsCalcTax ,
                a.CompanyGUID ,
                AreaInfo ,
                IsLandCbDk ,
                ReceiveTypeValue ,
                NEWID() ,
                IsYxfjxzf ,
                ZTCategory
        FROM    myBizParamOption a
                INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        WHERE   bu.BUName = @OldBUName AND  ParamName = 's_ReasonSort' AND  NOT EXISTS (SELECT  1
                                                                                        FROM    myBizParamOption b
                                                                                        WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);

        --回款比例
        INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
                                         AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        SELECT  ParamName ,
                @NewBUGUID ,
                ParamValue ,
                ParamCode ,
                ParentCode ,
                ParamLevel ,
                IfEnd ,
                IfSys ,
                NEWID() ,
                IsAjSk ,
                IsQykxdc ,
                TaxItemsDetailCode ,
                IsCalcTax ,
                a.CompanyGUID ,
                AreaInfo ,
                IsLandCbDk ,
                ReceiveTypeValue ,
                NEWID() ,
                IsYxfjxzf ,
                ZTCategory
        FROM    myBizParamOption a
                INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        WHERE   bu.BUName = @OldBUName AND  ParamName = 's_hkRate' AND  NOT EXISTS (SELECT  1
                                                                                    FROM    myBizParamOption b
                                                                                    WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);

        --发放比例
        INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
                                         AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
        SELECT  ParamName ,
                @NewBUGUID ,
                ParamValue ,
                ParamCode ,
                ParentCode ,
                ParamLevel ,
                IfEnd ,
                IfSys ,
                NEWID() ,
                IsAjSk ,
                IsQykxdc ,
                TaxItemsDetailCode ,
                IsCalcTax ,
                a.CompanyGUID ,
                AreaInfo ,
                IsLandCbDk ,
                ReceiveTypeValue ,
                NEWID() ,
                IsYxfjxzf ,
                ZTCategory
        FROM    myBizParamOption a
                INNER JOIN dbo.myBusinessUnit bu ON a.ScopeGUID = bu.BUGUID AND bu.IsEndCompany = 1
        WHERE   bu.BUName = @OldBUName AND  ParamName = 's_ffRate' AND  NOT EXISTS (SELECT  1
                                                                                    FROM    myBizParamOption b
                                                                                    WHERE   a.ParamName = b.ParamName AND   a.ParamValue = b.ParamValue AND b.ScopeGUID = @NewBUGUID);
    END;
