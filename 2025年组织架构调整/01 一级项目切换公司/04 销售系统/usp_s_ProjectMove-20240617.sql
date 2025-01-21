USE [ERP25];
GO

/****** Object:  StoredProcedure [dbo].[usp_s_ProjectMove]    Script Date: 2024/6/13 18:36:30 ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

ALTER PROC [dbo].[usp_s_ProjectMove](@OldBUName VARCHAR(MAX) ,
                                     @TopProjGUID VARCHAR(MAX) ,    --һ����ĿGUID
                                     @NewBUName VARCHAR(MAX))
AS /*--------------------------------------------------
  �洢��������
      usp_s_ProjectMove 
  ���ܣ�
      ����ϵͳ��Ŀת�Ƶ��¹�˾��
      ������ͳһԴ��˾�����Ŀͬʱת�Ƶ��¹�˾���������ڶ��Դ��˾��Ŀͬʱת�ƣ�
  ������
      @OldBUName ��ת�Ƶ���Ŀ������˾
      @ProjName ��ת����Ŀ����
      @NewBUName �¹�˾����  
      
   ע�⽫���ݿ��������滻Ϊerp25
 
     EXEC usp_s_ProjectMove '���ݹ�˾','5742DA4E-5EAE-E711-80BA-E61F13C57837,F13693A6-E031-E811-80BA-E61F13C57837,9D41FA6D-0959-E811-80BB-E61F13C57837,C53EE2A0-43AE-E711-80BA-E61F13C57837','���Ź�˾'   
    
  Create by �� lp  2017-05-05  V 1.0
  modify by :  lp  2017-10-10  V 2.0  �������ۼƻ����۸�Ԥ����ر�
  modify by :  lp  2017-05-04  V 3.0  ��������ϵͳ��Ŀ�Ŷӵ�����¥�������滻���¹�˾¥��������ʽȷ��Ϊ���롢��Ŀ�����滻��顢����Ȩ�ޱ�ˢ��
  modify by :  lp  2018-07-30  V 4.0  ������ֵ����ƽ̨��˾GUID�������ۿ۷���������˾
  modify by :  yp  20220218  v5.0 ��ȫ�޸��ű�

    --ͣ�ô�����
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
        PRINT '--������Ŀ��ת����Ŀ��ʱ��';

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

        PRINT '--��ȡ�¹�˾GUID,Code';

        DECLARE @NewBUGUID VARCHAR(100);
        DECLARE @NewBUCODE VARCHAR(100);

        SELECT  @NewBUGUID = BUGUID ,
                @NewBUCODE = BUCode
        FROM    dbo.myBusinessUnit
        WHERE   BUName = @NewBUName AND IsEndCompany = 1 AND IsCompany = 1;

        --SELECT  @NewBUGUID
        PRINT '--������Ŀ������˾,��Ŀ����';

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
            b.ProjCode = REPLACE(b.ProjCode, a.BUCODE, @NewBUCODE) ,
            b.ParentCode = REPLACE(b.ParentCode, a.BUCODE, @NewBUCODE)
        FROM    #Pro a
                INNER JOIN dbo.p_Project b ON a.ProjGUID = b.ProjGUID;

        PRINT '-------�޸���Ŀ�Ŷ������Ϣ--------';

        ALTER TABLE myBusinessUnit DISABLE TRIGGER ALL;

        --erp25
        UPDATE  b
        SET b.BUCode = REPLACE(b.BUCode, a.BUCODE, @NewBUCODE) ,
            b.HierarchyCode = REPLACE(b.HierarchyCode, a.BUCODE, @NewBUCODE) ,
            b.ParentGUID = @NewBUGUID ,
            b.CompanyGUID = @NewBUGUID ,
            b.NamePath = REPLACE(b.NamePath, @OldBUName, @NewBUName)
        FROM    #Pro a
                INNER JOIN ERP25.dbo.myBusinessUnit b ON b.ProjGUID = a.ProjGUID
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

        --�޸���Ŀ����Ȩ��
        --erp25
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    ERP25.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '��Ŀ'
        WHERE   1 = 1 AND   a.BUGUID <> p.BUGUID;

        --erp352        
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    MyCost_Erp352.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '��Ŀ'
        WHERE   1 = 1 AND   a.BUGUID <> p.BUGUID;

        --zulin       
        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    CRE_ERP_202_SYZL.dbo.myStationObject a
                INNER JOIN #Pro p ON a.ObjectGUID = p.ProjGUID AND a.TableName = '��Ŀ'
        WHERE   1 = 1 AND   a.BUGUID <> p.BUGUID;

        PRINT '---�޸�����ϵͳ��˾GUID��ʼ----';
        PRINT '¥����';

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
            b.ParentCode = REPLACE(b.ParentCode, a.BUCODE, @NewBUCODE)
        FROM    #Pro a
                INNER JOIN dbo.p_Building b ON a.ProjGUID = b.ProjGUID
        WHERE   1 = 1 AND   b.BUGUID <> @NewBUGUID;

        PRINT '�����';

        UPDATE  b
        SET b.BUGUID = @NewBUGUID ,
            b.RoomCode = REPLACE(b.RoomCode, a.BUCODE, @NewBUCODE)
        FROM    #Pro a
                INNER JOIN dbo.p_room b ON a.ProjGUID = b.ProjGUID
        WHERE   1 = 1 AND   b.BUGUID <> @NewBUGUID;

        PRINT '--�������У�����������Ŀ������ProjGUID��Ϊ�գ��������������á���Ŀ��������Ŀ������˾�����չ�˾�����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Bank
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Bank.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--�������У����ݱ����Ѻ�ʵ������δʹ�ã�*';

        UPDATE  s_BankBackUp
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BankBackUp.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--�������ݼ�¼��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_BatchPass
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BatchPass.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--������֤֪ͨ��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_BlFczTz
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_BlFczTz.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--ԤԼ����ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Booking
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Booking.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--ѡ�����ñ�ProjGUID��Ϊ�գ���Ŀ��ҵ��������Ѻ�ʵ�Ѵ���*';

        UPDATE  s_ChooseRoom
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ChooseRoom.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--��ͬ��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Contract
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Contract.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--��Ȩ�ռ���ִ��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Cqsjhz
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Cqsjhz.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--���շ��ö��壨ProjGUID��Ϊ�գ������շ������á���Ŀ�����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_DsFeeSet
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_DsFeeSet.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--��ͬ��ϸ��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_HtDetail
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_HtDetail.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--��ͬ��ϸ��ʱ�� ���Ѻ�ʵ�Ѵ���*';

        UPDATE  s_HtDetail_Template
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_HtDetail_Template.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--������Ϣ��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Lead
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Lead.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--****Ӫ��������ProjGUID��Ϊ�գ�������32��40���� �п����� ���ʱ��Ŀ����Ϊ��  ��ȷ�� ��Ŀ���գ��Ѻ�ʵ�Ѵ���*';

        UPDATE  s_MarketingPlan
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_MarketingPlan.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--���ۻ��ᣨProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Opportunity
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Opportunity.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--������ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Order
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Order.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--��ҵ�ƻ�������ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_OrderTmp
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_OrderTmp.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--�۸�����RoomGUID��Ϊ��,RoomGUID���������Ѻ�ʵ�Ѵ���*';

        UPDATE  s_PriceChg
        SET s_PriceChg.BUGUID = @NewBUGUID
        FROM    s_PriceChg
                INNER JOIN p_room ON s_PriceChg.RoomGUID = p_room.RoomGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p_room.ProjGUID) AND s_PriceChg.BUGUID <> @NewBUGUID;

        PRINT '--�Ϲ����ű�������BUGUID��';

        UPDATE  pno
        SET BUGUID = @NewBUGUID
        FROM    s_PotocolNO pno
                INNER JOIN p_PotocolNO2Proj ON p_PotocolNO2Proj.PotocolNoGUID = pno.PotocolNoGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p_PotocolNO2Proj.ProjGUID) AND   pno.BUGUID <> @NewBUGUID;

        PRINT '--��Ŀ��ֵ���Ʊ�ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_ProjHZKZ
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ProjHZKZ.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--��Ŀ�����ֵ��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_ProjLX
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_ProjLX.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--������־��ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_SaleDayLog
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleDayLog.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '--���۱�����루ProjGUID��Ϊ�գ�������û�й�˾���Ѻ�ʵ�Ѵ���*';

        UPDATE  s_SaleModiApply
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleModiApply.ProjGUID) AND BUGUID <> @NewBUGUID;

        PRINT '--���۱����־��ProjGUID��Ϊ�գ�������û�й�˾���Ѻ�ʵ�Ѵ���*';

        UPDATE  s_SaleModiLog
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SaleModiLog.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '--���۷�����ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_TjPlan
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_TjPlan.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT ' --���񵥾ݣ�ProjGUID��Ϊ�գ����Ѻ�ʵ�Ѵ���*';

        UPDATE  s_Voucher
        SET BuGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_Voucher.ProjGUID) AND  BuGUID <> @NewBUGUID;

        PRINT ' --�۸�Ԥ��    ';
        PRINT '�޸���Ŀ���ñ���������Ͷ����Ŀ��������ƽ̨��˾���µ�ƽ̨��˾GUID���Ե�����';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    s_PricePredictionSetInfo a
                INNER JOIN dbo.mdm_Project mp ON a.MDMProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) AND a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '��Ŀ�۸�Ԥ��';

        UPDATE  s_PricePrediction
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_PricePrediction.ProjGUID);

        PRINT '�޸���Ŀ�۸�Ԥ�����������Ͷ����Ŀ��������ƽ̨��˾���µ�ƽ̨��˾GUID���Ե�����';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    s_PricePrediction a
                INNER JOIN dbo.mdm_Project mp ON a.MDMProjGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) AND a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT ' --���ۼƻ�  ';
        PRINT '��Ŀ���ۼƻ�';

        UPDATE  s_SalesBudget
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SalesBudget.ProjGUID) AND  BUGUID <> @NewBUGUID;

        PRINT '��Ŀ���ۼƻ���ʷ�汾';

        UPDATE  s_SalesBudgetHistory
        SET BUGUID = @NewBUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = s_SalesBudgetHistory.ProjGUID) AND   BUGUID <> @NewBUGUID;

        PRINT '�޸��ͻ�������������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_CstAttach a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '�޸����������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BuGUID = p.BUGUID
        FROM    p_Activity a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BuGUID <> p.BUGUID;

        PRINT '�޸��ͷ��Ӵ���������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    k_Receive a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '�޸��ͷ������������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    k_Task a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '�޸���ͬ����Ӧ��������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_httype2JCProjNoCtrl a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '�޸���Ŀ��ӡ���ñ�������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_PrintSet a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '�޸���Ŀ��ӡ����ģ���������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_PrintSet a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   a.BUGUID <> p.BUGUID;

        PRINT '�޸�¥����Ʒ��������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    p_BuildProduct a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        PRINT '�޸���Ŀ�����������Ŀ������˾�仯���µ�BUGUID��������';

        UPDATE  a
        SET a.BUGUID = p.BUGUID
        FROM    s_ProjLX a
                INNER JOIN dbo.p_Project p ON a.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  a.BUGUID <> p.BUGUID;

        --��ֵ���� 2018��7��30�����
        PRINT '�޸���ֵ������ϸƽ̨��˾GUID';

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    s_SaleValuePlan a
                INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.BUGUID <> mp.DevelopmentCompanyGUID;

        PRINT '�޸���ֵ������ʷ��ϸƽ̨��˾GUID';

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValuePlanHistory a
                INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.BUGUID <> mp.DevelopmentCompanyGUID;

        PRINT '�޸���ֵ���Ű汾��ƽ̨��˾GUID';

        UPDATE  a
        SET a.BUGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValuePlanVersion a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.BUGUID <> mp.DevelopmentCompanyGUID;

        PRINT '�޸���ֵ���Ų����ƽ̨��˾GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueVersionStep a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '�޸���ֵ�������Ž����ƽ̨��˾GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueBuildLayout a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '�޸���ֵ����¥���ױ�ƽ̨��˾GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_SaleValueBuilding a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '�޸���ֵ����������ϸ��ƽ̨��˾GUID';

        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.s_ProjQhfa a
                LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = a.ProjGUID) AND  a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '�ۿ۷���������˾�޸�';

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

        PRINT '����ӿ�';

        UPDATE  b
        SET b.BUGUID = p.BUGUID
        FROM    dbo.p_cwjkproject a
                INNER JOIN dbo.p_cwjkcompany b ON b.CompanyGUID = a.CompanyGUID
                INNER JOIN dbo.p_Project p ON p.ProjGUID = a.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  b.BUGUID <> p.BUGUID;

        PRINT '����Ʊ��';

        UPDATE  a
        SET a.BuGUID = c.BuGUID
        FROM    p_Invoice a WITH(NOLOCK)
                LEFT JOIN p_InvoiceDetail b WITH(NOLOCK)ON a.InvoGUID = b.InvoGUID
                LEFT JOIN s_Voucher c WITH(NOLOCK)ON c.InvoDetailGUID = b.InvoDetailGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = c.ProjGUID) AND  a.BuGUID <> c.BuGUID;

        PRINT '������Ŀҵ��';

        UPDATE  p
        SET p.BUGuid = p1.BUGUID
        FROM    s_YJRLProjSet p
                LEFT JOIN dbo.p_Project p1 ON p1.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BUGuid <> p1.BUGUID;

        PRINT '����ҵ��';
        PRINT '������¼�������s_BajlrPlan';

        UPDATE  p
        SET p.BuGuid = p1.BUGUID
        FROM    s_BajlrPlan p
                LEFT JOIN p_Project p1 ON p1.ProjGUID = p.ProjGuid
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p1.ProjGUID) AND p.BuGuid <> p1.BUGUID;

        PRINT 's_fee_collect_Yunke_wide';

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

        --�޸�����ҵ�����ݱ�
        UPDATE  a
        SET a.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        FROM    S_PerformanceAppraisal a
                LEFT JOIN dbo.mdm_Project mp ON a.ManagementProjectGUID = mp.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = mp.ProjGUID) AND a.DevelopmentCompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '��Ŀ�Ŷ�';

        UPDATE  st
        SET st.CompanyGUID = bu.CompanyGUID
        FROM    myBusinessUnit bu
                INNER JOIN dbo.p_Project p ON p.ProjGUID = bu.ProjGUID AND bu.BUType = 3 AND   p.Level = 2
                INNER JOIN dbo.myStation st ON st.BUGUID = bu.BUGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  st.CompanyGUID <> bu.CompanyGUID;

        PRINT '���������Աѡ�񲻵�֮ǰ¼����ı��б���Ϣ�����⣬����һ��ԭ��˾��¼���б��¹�˾';

        INSERT INTO dbo.mySysData(SysID, Content, BUGUID, UserGUID)
        SELECT  a.SysID ,
                a.Content ,
                @NewBUGUID AS BUGUID ,
                a.UserGUID
        FROM    mySysData a
        WHERE   EXISTS (SELECT  1 FROM  #Pro p WHERE p.BUGUID = a.BUGUID)
                AND   a.SysID IN ('Clerk', 'Clerk2', 'ClerkAfter', 'ClerkAfter2', 'Qdjl', 'QdjlAfter', 'Qdzy', 'Qdzy2', 'QdzyAfter', 'QdzyAfter2', 'Xsjl', 'Xsjl2', 'XsjlAfter', 'XsjlAfter2', 'ywy' ,
                                  'zygw' , 'zygw2', 'zygwAfter', 'zygwAfter2');

        --����������Ŀ��Ӧ��˾���ձ�ˢ��
        UPDATE  b
        SET b.OrgCompanyGUID = p.BUGUID
        FROM    dbo.p_Project p
                INNER JOIN MyCost_Erp352.dbo.md_Project2OrgCompany b ON b.ProjGUID = p.ProjGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = p.ProjGUID) AND  p.BUGUID <> b.OrgCompanyGUID;

        --20210301add ����p_PrintTemplate �Ϲ���ģ���ӡ���޸�

        --������ʱ����ѯ�Ϲ�˾��Ŀ��Ӧ���Ϲ���ģ�岢���뵽��ʱ��
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

        --�޸��Ϲ���ģ���PrintTemplateGUID��BUGUID
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
                 WHERE  BUName = @NewBUName AND IsEndCompany = 1) AS BUGUID ,   --�¹�˾GUID
                a.Location ,
                a.IsCreateByFPD
        INTO    #p_PrintTemplate2
        FROM    #p_PrintTemplate a;

        --�������¹�˾�����ӡģ���p_PrintTemplate
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

        --�޸�p_PrintSet���PrintTemplateGUID
        UPDATE  b
        SET b.PrintTemplateGUID = a.PrintTemplateGUIDNew
        FROM    #p_PrintTemplate2 a
                INNER JOIN p_PrintSet b ON a.PrintTemplateGUID = b.PrintTemplateGUID
        WHERE   EXISTS (SELECT  1 FROM  #Pro pro WHERE  pro.ProjGUID = b.ProjGUID) AND  a.BUGUID <> b.BUGUID;

        --20210301add ����p_PrintTemplate �Ϲ���ģ���ӡ���޸�

        --ɾ����ʱ��
        DROP TABLE #p_PrintTemplate;
        DROP TABLE #p_PrintTemplate2;
        DROP TABLE #Pro;

        PRINT '�������Ͳ�������';

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

        PRINT '���ԭ��';

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

        --�ؿ����
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

        --���ű���
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
