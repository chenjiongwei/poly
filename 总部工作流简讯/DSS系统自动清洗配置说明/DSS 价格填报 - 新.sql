USE [dss]
GO
/****** Object:  StoredProcedure [dbo].[usp_nmap_F_�۸��]    Script Date: 05/15/2017 21:02:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[usp_nmap_F_�۸��]
    (
      @CleanDate DATETIME ,
      @DataBaseName VARCHAR(100) ,
      @FillHistoryGUID UNIQUEIDENTIFIER ,
      @IsCurrFillHistory BIT
    )
AS /*

	������@CleanDate  ��ϴ����
		  @DataBaseName ���ݿ��ַ
		  @FillHistoryGUID �����
		  @IsCurrFillHistory �Ƿ�ǰ����
	���ܣ��۸��
	�����ߣ�lifs
	�������ڣ�2016-10-27
*/

    PRINT @CleanDate; 
    PRINT @DataBaseName;  
    PRINT @FillHistoryGUID; 
    PRINT @IsCurrFillHistory; 

    DECLARE @strSql VARCHAR(MAX); 
	--���ǵ�ǰ����ʱ,ˢ����֯γ��
    IF @IsCurrFillHistory = 1
        BEGIN
            EXEC dbo.usp_nmap_S_FillDataSynch_ReCreateBatch @FillHistoryGUID = @FillHistoryGUID;
        END;

 --SBB
    CREATE TABLE #sbb
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          ���ۻ�����Ԫ MONEY ,
          ������� MONEY ,
          ������� MONEY,
	    );
    SET @strSql = ' 
    insert into #sbb(SaleBldGUID,���ۻ�����Ԫ,�������,�������)
    SELECT  sb.SaleBldGUID ,
            SUM(ISNULL(bd.cjtotal, 0)) ���ۻ�����Ԫ ,
            SUM(CASE WHEN ProductType=''������/����'' AND p.ProductName<> ''���´�����'' THEN 1 else ISNULL(bd.ysmjtotal, 0) end) ������� ,
            SUM(CASE WHEN ProductType=''������/����'' AND p.ProductName<> ''���´�����'' THEN 1 ELSE ISNULL(bd.mjtotal, ISNULL(sb.SaleArea, 0)) end) �������
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ( SELECT  b.BldGUID ,
                                --pt.BProductTypeName ProductName ,
                                
                                SUM(ISNULL(t.RmbCjTotal, 0)) cjtotal ,
                                
                                SUM(CASE WHEN r.Status IN ( ''ǩԼ'', ''�Ϲ�'' )
                                         THEN r.BldArea
                                         ELSE 0
                                    END) ysmjtotal ,
                                    SUM(CASE WHEN ( r.Status IN ( ''����'', ''ԤԼ'' )
                                                OR ( r.Status = ''����'' )
                                              ) THEN r.BldArea
                                         ELSE 0
                                    END) mjtotal
                        FROM    ' + @DataBaseName + 'p_Building b
                        LEFT JOIN ' + @DataBaseName
        + 'p_Room r ON r.BldGUID = b.BldGUID
                       
                       LEFT JOIN ( SELECT  RoomGUID ,RmbCjTotal , JfDate
                                            FROM    ' + @DataBaseName
        + 's_Order o
                                            WHERE   o.Status = ''����''
                                                    AND o.OrderType = ''�Ϲ�''
                                            UNION ALL
                                            SELECT  RoomGUID ,
                                                    RmbHtTotal rmbcjtotal ,
                                                    JFDate
                                            FROM    ' + @DataBaseName
        + 's_Contract c
                                            WHERE   c.Status = ''����''
                                          ) t ON t.RoomGUID = r.RoomGUID
                        GROUP BY b.BldGUID 
                      ) bd ON sb.ImportSaleBldGUID = bd.BldGUID
                             
    GROUP BY SaleBldGUID;';
    PRINT 0;
    EXEC(@strSql);
 
 --SBB1 ������
	
    CREATE TABLE #sbb1
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM���۷����׼�ܼ� MONEY ,
          CRM�����³ɽ��ܼ� MONEY ,
          CRM�����³ɽ���Ӧ�ķ����ܼ� MONEY,
	    );
    SET @strSql = ' 
    insert into #sbb1(SaleBldGUID,CRM���۷����׼�ܼ�,CRM�����³ɽ��ܼ�,CRM�����³ɽ���Ӧ�ķ����ܼ�)
    SELECT sb.SaleBldGUID ,
            SUM(CASE WHEN r.Status NOT IN ( ''�Ϲ�'', ''ǩԼ'' )
                     THEN ISNULL(r.Total, 0)
                     ELSE 0
                END) CRM���۷����׼�ܼ� ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM�����³ɽ��ܼ� ,
            SUM(CASE WHEN o.OrderGUID IS NOT NULL
                          OR sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.Total, 0)
                     ELSE 0
                END) CRM�����³ɽ���Ӧ�ķ����ܼ�
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_BuildProductType bp ON r.BProductTypeCode = bp.BProductTypeCode
            LEFT JOIN ' + @DataBaseName
        + 's_Order o ON r.RoomGUID = o.RoomGUID
                                                              AND o.Status = ''����''
                                                              AND OrderType = ''�Ϲ�''
                                                              AND DATEDIFF(DD,
                                                              o.QSDate,
                                                              GETDATE()) < 90
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''����''
                                                              AND HtType = ''��ʽ��ͬ''
                                                              AND DATEDIFF(DD,
                                                              sc.QSDate,
                                                              GETDATE()) < 90
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID; ';
    PRINT 1;
    EXEC(@strSql);
                    
--SBB2  һ����   
    CREATE TABLE #sbb2
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM��һ�³ɽ��ܼ� MONEY ,
          CRM��һ�³ɽ���Ӧ�ķ������ MONEY,
	    ); 
    SET @strSql = '
     insert into #sbb2(SaleBldGUID,CRM��һ�³ɽ��ܼ�,CRM��һ�³ɽ���Ӧ�ķ������)
     SELECT  sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM��һ�³ɽ��ܼ� ,
            SUM(CASE WHEN p.ProductType = ''������/����'' AND p.ProductName <> ''���´�����'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM��һ�³ɽ���Ӧ�ķ������
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
			LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''����''
                                                              AND HtType = ''��ʽ��ͬ''
                                                              AND DATEDIFF(MM,
                                                              sc.QSDate,
                                                              GETDATE()) = 0
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID; ';
    PRINT 2;
    EXEC(@strSql);  

 --SBB3  һ����
    CREATE TABLE #sbb3
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM��һ��ɽ��ܼ� MONEY ,
          CRM��һ��ɽ���Ӧ�ķ������ MONEY,
	    );             
    SET @strSql = '
    insert into #sbb3(SaleBldGUID,CRM��һ��ɽ��ܼ�,CRM��һ��ɽ���Ӧ�ķ������)
    SELECT sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM��һ��ɽ��ܼ� ,
            SUM(CASE WHEN p.ProductType = ''������/����'' AND p.ProductName <> ''���´�����'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM��һ��ɽ���Ӧ�ķ������
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
		LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''����''
                                                              AND HtType = ''��ʽ��ͬ''
                                                              AND DATEDIFF(yyyy,
                                                              sc.QSDate,
                                                              GETDATE()) = 0
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID;  '; 
    PRINT 3;
    EXEC(@strSql);              
--SBB4 �ۼ�   
    CREATE TABLE #sbb4
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM�ۼƳɽ��ܼ� MONEY ,
          CRM�ۼƳɽ���Ӧ�ķ������ MONEY,
	    );            
    SET @strSql = '  
        insert into #sbb4(SaleBldGUID,CRM�ۼƳɽ��ܼ�,CRM�ۼƳɽ���Ӧ�ķ������)
        SELECT sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM�ۼƳɽ��ܼ� ,
            SUM(CASE WHEN p.ProductType = ''������/����'' AND p.ProductName <> ''���´�����'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM�ۼƳɽ���Ӧ�ķ������
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
			LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''����''
                                                              AND HtType = ''��ʽ��ͬ''
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID;   ';
    
    PRINT 4;
    EXEC(@strSql);  
           
    DECLARE @Drr AS VARCHAR(500);  
    DECLARE @DrDate AS DATETIME;  
    SELECT TOP 1
            @Drr = [�������] ,
            @DrDate = [�����ʱ��]
    FROM    [nmap_F_�۸��]
    WHERE   FillHistoryGUID = @FillHistoryGUID; 
  
    CREATE TABLE #TempData
        (
          �۸��GUID UNIQUEIDENTIFIER ,
          FillHistoryGUID UNIQUEIDENTIFIER ,
          BusinessGUID UNIQUEIDENTIFIER ,
          ��Ŀ���� VARCHAR(400) ,
          ��Ŀ���� VARCHAR(400) ,
          ��Ʒ���� VARCHAR(400) ,
          ��Ʒ���� VARCHAR(400) ,
          ���� MONEY ,
          �ۼ�ǩԼ���� MONEY ,
          ����ǩԼ���� MONEY ,
          ����ǩԼ���� MONEY ,
          ����� MONEY ,
          ��λ�� MONEY ,
          ��̬���۵��� MONEY ,
          ��̬������� MONEY ,
          Ŀ��ɱ����� MONEY ,
          ��̬�ɱ����� MONEY ,
          װ�ޱ�׼ VARCHAR(400) ,
          ������� VARCHAR(400) ,
          �����ʱ�� DATETIME ,
          ��˾��� VARCHAR(400) ,
          RowID INT ,
          ProductGuid UNIQUEIDENTIFIER ,
          BusinessType VARCHAR(200) ,
          Remark VARCHAR(500)
        );
    PRINT 5;
  
--�����������,�������� �İ汾��
    DECLARE @FillHistoryGUIDLast UNIQUEIDENTIFIER;
  
    SELECT TOP 1
            @FillHistoryGUIDLast = a.FillHistoryGUID
    FROM    nmap_F_FillHistory a
    WHERE   FillDataGUID = ( SELECT FillDataGUID
                             FROM   nmap_F_FillData
                             WHERE  FillName = '�۸��'
                           )
            AND a.ApproveStatus = '�����'
    ORDER BY EndDate DESC;
  
  
    SET @strSql = ' 
     insert into  #TempData (�۸��GUID ,
                    FillHistoryGUID ,
                    BusinessGUID ,
                    ��˾���,
                    ��Ŀ���� ,
                    ��Ŀ���� ,
                    ��Ʒ���� ,
                    ��Ʒ���� ,
                    ���� ,
                    �ۼ�ǩԼ���� ,
                    ����ǩԼ���� ,
                    ����ǩԼ���� ,
                    ����� ,
                    ��λ�� ,
                    ��̬���۵��� ,
                    ��̬������� ,
                    Ŀ��ɱ����� ,
                    ��̬�ɱ����� ,
                    װ�ޱ�׼ ,
                    ������� ,
                    �����ʱ��,
                    ProductGuid,
                    BusinessType,
                    Remark
                     )
     SELECT  NEWID() [�۸��GUID] ,
            ' + ( CASE WHEN @FillHistoryGUID IS NULL THEN 'NULL'
                       ELSE '''' + CAST(@FillHistoryGUID AS VARCHAR(50))
                            + ''''
                  END ) + ' FillHistoryGUID ,
            B.CompanyGUID [BusinessGUID] ,
            B.CompanyName [��˾���] ,
            ISNULL(p.ProjCode, p1.ProjCode) ��Ŀ���� ,
            ISNULL(p.SpreadName, p1.SpreadName) + ''-'' +
            CASE WHEN p.ProjName IS NULL THEN ''''
                   ELSE p1.ProjName
              END ��Ŀ���� ,
            pd.ProductType ��Ʒ���� ,
            pd.ProductName ��Ʒ���� ,
            ISNULL(A.����, 0.00) [����] ,
            CASE WHEN SUM(sb.CRM�ۼƳɽ���Ӧ�ķ������) = 0 THEN 0
                 ELSE SUM(sb.CRM�ۼƳɽ��ܼ�) / SUM(sb.CRM�ۼƳɽ���Ӧ�ķ������)
            END AS �ۼ�ǩԼ���� ,
            CASE WHEN SUM(sb.CRM��һ��ɽ���Ӧ�ķ������) = 0 THEN 0
                 ELSE SUM(sb.CRM��һ��ɽ��ܼ�) / SUM(sb.CRM��һ��ɽ���Ӧ�ķ������)
            END AS ����ǩԼ���� ,
            CASE WHEN SUM(sb.CRM��һ�³ɽ���Ӧ�ķ������) = 0 THEN 0
                 ELSE SUM(sb.CRM��һ�³ɽ��ܼ�) / SUM(sb.CRM��һ�³ɽ���Ӧ�ķ������)
            END AS ����ǩԼ���� ,
            ISNULL(A.�����, 0.00) [�����] ,
            ISNULL(A.��λ��, 0.00) [��λ��] ,
            CASE WHEN SUM(sb.��̬�������) = 0 THEN 0
                 ELSE SUM(sb.[��̬�����ܼ� ]) / SUM(sb.��̬�������)
            END AS ��̬���۵��� ,
            SUM(sb.��̬�������) AS ��̬������� ,
            ISNULL(A.Ŀ��ɱ�����, 0.00) [Ŀ��ɱ�����] ,
            ISNULL(A.��̬�ɱ�����, 0.00) [��̬�ɱ�����] ,
            ISNULL(A.װ�ޱ�׼, '''') [װ�ޱ�׼] ,
            ' + ( CASE WHEN @Drr IS NULL THEN 'NULL'
                       ELSE '''' + @Drr + ''''
                  END ) + '  [�������] ,
            ' + ( CASE WHEN @DrDate IS NULL THEN 'NULL'
                       ELSE '''' + CONVERT(VARCHAR, @DrDate, 120) + ''''
                  END )
        + ' [�����ʱ��],
            pd.ProductGuid,
            pd.BusinessType,
            pd.Remark
    FROM    ( SELECT    sb.SaleBldGUID ,
                        sb.ProductGUID ,
                        sb.GCBldGUID ,
                        CASE WHEN ( ISNULL(sbb.�������, 0) + ISNULL(sbb.�������, 0) ) = 0
                             THEN ISNULL(sb.SaleArea, 0)
                             ELSE ( ISNULL(sbb.�������, 0) + ISNULL(sbb.�������, 0) )
                        END AS ''��̬�������'' ,
                        CASE WHEN ( CASE WHEN ( ISNULL(sbb.�������, 0)
                                                + ISNULL(sbb.�������, 0) ) = 0
                                         THEN ISNULL(sb.SaleArea, 0)
                                         ELSE ( ISNULL(sbb.�������, 0)
                                                + ISNULL(sbb.�������, 0) )
                                    END ) = 0 THEN 0
                             ELSE ( CASE WHEN ( ISNULL(sbb.���ۻ�����Ԫ, 0)
                                                + ISNULL(CASE WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM���۷����׼�ܼ�,
                                                              0)
                                                              ELSE sbb1.CRM���۷����׼�ܼ�
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END )
                                                         END, 0) ) = 0
                                         THEN sb.PlanSaleTotal
                                         ELSE ( ISNULL(sbb.���ۻ�����Ԫ, 0)
                                                + ISNULL(CASE WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM���۷����׼�ܼ�,
                                                              0)
                                                              ELSE sbb1.CRM���۷����׼�ܼ�
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END )
                                                         END, 0) )
                                    END )
                                  / ( CASE WHEN ( ISNULL(sbb.�������, 0)
                                                  + ISNULL(sbb.�������, 0) ) = 0
                                           THEN sb.SaleArea
                                           ELSE ( ISNULL(sbb.�������, 0)
                                                  + ISNULL(sbb.�������, 0) )
                                      END )
                        END AS ''��̬���۵���'' ,
                        ( ( CASE WHEN ( ISNULL(sbb.�������, 0) + ISNULL(sbb.�������,
                                                              0) ) = 0
                                 THEN ISNULL(sb.SaleArea, 0)
                                 ELSE ( ISNULL(sbb.�������, 0) + ISNULL(sbb.�������,
                                                              0) )
                            END )
                          * ( CASE WHEN ( CASE WHEN ( ISNULL(sbb.�������, 0)
                                                      + ISNULL(sbb.�������, 0) ) = 0
                                               THEN ISNULL(sb.SaleArea, 0)
                                               ELSE ( ISNULL(sbb.�������, 0)
                                                      + ISNULL(sbb.�������, 0) )
                                          END ) = 0 THEN 0
                                   ELSE ( CASE WHEN ( ISNULL(sbb.���ۻ�����Ԫ, 0)
                                                      + ISNULL(CASE
                                                              WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM���۷����׼�ܼ�,
                                                              0)
                                                              ELSE sbb1.CRM���۷����׼�ܼ�
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END )
                                                              END, 0) ) = 0
                                               THEN sb.PlanSaleTotal
                                               ELSE ( ISNULL(sbb.���ۻ�����Ԫ, 0)
                                                      + ISNULL(CASE
                                                              WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM���۷����׼�ܼ�,
                                                              0)
                                                              ELSE sbb1.CRM���۷����׼�ܼ�
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM�����³ɽ��ܼ�
                                                              / sbb1.CRM�����³ɽ���Ӧ�ķ����ܼ�
                                                              END )
                                                              END, 0) )
                                          END )
                                        / ( CASE WHEN ( ISNULL(sbb.�������, 0)
                                                        + ISNULL(sbb.�������, 0) ) = 0
                                                 THEN ISNULL(sb.SaleArea, 0)
                                                 ELSE ( ISNULL(sbb.�������, 0)
                                                        + ISNULL(sbb.�������, 0) )
                                            END )
                              END ) ) AS ''��̬�����ܼ� '' ,
                        ISNULL(sbb2.CRM��һ�³ɽ��ܼ�, 0) AS ''CRM��һ�³ɽ��ܼ�'' ,
                        ISNULL(sbb2.CRM��һ�³ɽ���Ӧ�ķ������, 0) AS ''CRM��һ�³ɽ���Ӧ�ķ������'' ,
                        ISNULL(sbb3.CRM��һ��ɽ��ܼ�, 0) AS ''CRM��һ��ɽ��ܼ�'' ,
                        ISNULL(sbb3.CRM��һ��ɽ���Ӧ�ķ������, 0) AS ''CRM��һ��ɽ���Ӧ�ķ������'' ,
                        ISNULL(sbb4.CRM�ۼƳɽ��ܼ�, 0) AS ''CRM�ۼƳɽ��ܼ�'' ,
                        ISNULL(sbb4.CRM�ۼƳɽ���Ӧ�ķ������, 0) AS ''CRM�ۼƳɽ���Ӧ�ķ������''
              FROM      ' + @DataBaseName
        + 'mdm_SaleBuild sb
                        LEFT JOIN #sbb sbb ON sbb.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb1 sbb1 ON sbb1.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb2 sbb2 ON sbb2.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb3 sbb3 ON sbb3.SaleBldGUID = sb.SaleBldGUID
                        LEFT JOIN #sbb4 sbb4 ON sbb4.SaleBldGUID = sb.SaleBldGUID
            ) sb
            LEFT JOIN ' + @DataBaseName
        + 'mdm_GCBuild gb ON sb.GCBldGUID = gb.GCBldGUID
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Project p1 ON gb.ProjGUID = p1.ProjGUID
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Project p ON p1.ParentProjGUID = p.ProjGUID
                                                              AND p.Level = 2
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Product pd ON sb.ProductGUID = pd.ProductGUID
            LEFT JOIN dbo.nmap_N_CompanyToTerraceBusiness AS C ON C.DevelopmentCompanyGUID = p1.DevelopmentCompanyGUID
            LEFT JOIN [nmap_N_Company] AS B ON B.CompanyGUID = C.CompanyGUID
            LEFT JOIN ( SELECT  [��˾���] ,
                                BusinessGUID ,
                                ��Ʒ���� ,
                                ��Ʒ���� ,
                                ��Ŀ���� ,
                                ��Ŀ���� ,
                                ISNULL([����], 0.00) [����] ,
                                ISNULL([�����], 0.00) [�����] ,
                                ISNULL([��λ��], 0.00) [��λ��] ,
                                ISNULL([Ŀ��ɱ�����], 0.00) [Ŀ��ɱ�����] ,
                                ISNULL([��̬�ɱ�����], 0.00) [��̬�ɱ�����] ,
                                ISNULL([װ�ޱ�׼], '''') [װ�ޱ�׼]
                        FROM    [nmap_F_�۸��]
                        WHERE   FillHistoryGUID = '
        + CASE WHEN @FillHistoryGUIDLast IS NULL THEN 'NULL'
               ELSE '''' + CAST(@FillHistoryGUIDLast AS VARCHAR(50)) + ''''
          END + '
                      ) AS A ON A.BusinessGUID = B.CompanyGUID
                                AND A.[��˾���] = B.CompanyName
                                AND A.��Ŀ���� = ISNULL(p.ProjCode, p1.ProjCode)
                                AND A.��Ŀ���� = ISNULL(p.SpreadName,
                                                    p1.SpreadName)  + ''-'' +
                                CASE WHEN p.ProjName IS NULL THEN ''''
                                       ELSE p1.ProjName
                                  END
                                AND A.��Ʒ���� = pd.ProductType
                                AND A.��Ʒ���� = pd.ProductName
		   GROUP BY
            B.CompanyGUID  ,
            B.CompanyName  ,
            ISNULL(p.ProjCode, p1.ProjCode)  ,
            ISNULL(p.SpreadName, p1.SpreadName) + ''-'' +
            CASE WHEN p.ProjName IS NULL THEN ''''
                   ELSE p1.ProjName
            END ,
            pd.ProductType  ,
            pd.ProductName ,
            ISNULL(A.����, 0.00) , 
            ISNULL(A.�����, 0.00)  ,
            ISNULL(A.��λ��, 0.00) ,
            ISNULL(A.Ŀ��ɱ�����, 0.00) ,
            ISNULL(A.��̬�ɱ�����, 0.00)  ,
            ISNULL(A.װ�ޱ�׼, ''''),  
            pd.ProductGuid,
            pd.BusinessType,
            pd.Remark '
           
    EXEC (@strSql);
		

--ɾ��������  
    DELETE  FROM nmap_F_�۸��
    WHERE   FillHistoryGUID = @FillHistoryGUID;  
 
--����������
    INSERT  INTO nmap_F_�۸��
            ( �۸��GUID ,
              FillHistoryGUID ,
              BusinessGUID ,
              ��Ŀ���� ,
              ��Ŀ���� ,
              ��Ʒ���� ,
              ��Ʒ���� ,
              ���� ,
              �ۼ�ǩԼ���� ,
              ����ǩԼ���� ,
              ����ǩԼ���� ,
              ����� ,
              ��λ�� ,
              ��̬���۵��� ,
              ��̬������� ,
              Ŀ��ɱ����� ,
              ��̬�ɱ����� ,
              װ�ޱ�׼ ,
              ������� ,
              �����ʱ�� ,
              ��˾��� ,
              RowID ,
              ��ƷGUID,
              ��Ʒ���� ,
              ��ע
              
            )
            SELECT  �۸��GUID ,
                    FillHistoryGUID ,
                    BusinessGUID ,
                    ��Ŀ���� ,
                    ��Ŀ���� ,
                    ��Ʒ���� ,
                    ��Ʒ���� ,
                    ���� ,
                    �ۼ�ǩԼ���� ,
                    ����ǩԼ���� ,
                    ����ǩԼ���� ,
                    ����� ,
                    ��λ�� ,
                    ��̬���۵��� ,
                    ��̬������� ,
                    Ŀ��ɱ����� ,
                    ��̬�ɱ����� ,
                    װ�ޱ�׼ ,
                    ������� ,
                    �����ʱ�� ,
                    ��˾��� ,
                    ROW_NUMBER() OVER ( ORDER BY ��˾���, BusinessGUID , ��Ŀ���� , ��Ŀ���� , ��Ʒ���� , ��Ʒ���� ) AS [RowID] ,
                    ProductGuid ,
                    BusinessType ,
                    Remark
            FROM    #TempData;
 
    DROP TABLE #sbb; 
    DROP TABLE #sbb1; 
    DROP TABLE #sbb2;
    DROP TABLE #sbb3; 
    DROP TABLE #sbb4;
    DROP TABLE #TempData;
 