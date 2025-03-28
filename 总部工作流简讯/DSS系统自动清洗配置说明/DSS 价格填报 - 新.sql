USE [dss]
GO
/****** Object:  StoredProcedure [dbo].[usp_nmap_F_价格填报]    Script Date: 05/15/2017 21:02:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[usp_nmap_F_价格填报]
    (
      @CleanDate DATETIME ,
      @DataBaseName VARCHAR(100) ,
      @FillHistoryGUID UNIQUEIDENTIFIER ,
      @IsCurrFillHistory BIT
    )
AS /*

	参数：@CleanDate  清洗日期
		  @DataBaseName 数据库地址
		  @FillHistoryGUID 填报批次
		  @IsCurrFillHistory 是否当前批次
	功能：价格填报
	创建者：lifs
	创建日期：2016-10-27
*/

    PRINT @CleanDate; 
    PRINT @DataBaseName;  
    PRINT @FillHistoryGUID; 
    PRINT @IsCurrFillHistory; 

    DECLARE @strSql VARCHAR(MAX); 
	--当是当前批次时,刷新组织纬度
    IF @IsCurrFillHistory = 1
        BEGIN
            EXEC dbo.usp_nmap_S_FillDataSynch_ReCreateBatch @FillHistoryGUID = @FillHistoryGUID;
        END;

 --SBB
    CREATE TABLE #sbb
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          已售货量万元 MONEY ,
          已售面积 MONEY ,
          待售面积 MONEY,
	    );
    SET @strSql = ' 
    insert into #sbb(SaleBldGUID,已售货量万元,已售面积,待售面积)
    SELECT  sb.SaleBldGUID ,
            SUM(ISNULL(bd.cjtotal, 0)) 已售货量万元 ,
            SUM(CASE WHEN ProductType=''地下室/车库'' AND p.ProductName<> ''地下储藏室'' THEN 1 else ISNULL(bd.ysmjtotal, 0) end) 已售面积 ,
            SUM(CASE WHEN ProductType=''地下室/车库'' AND p.ProductName<> ''地下储藏室'' THEN 1 ELSE ISNULL(bd.mjtotal, ISNULL(sb.SaleArea, 0)) end) 待售面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
            LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ( SELECT  b.BldGUID ,
                                --pt.BProductTypeName ProductName ,
                                
                                SUM(ISNULL(t.RmbCjTotal, 0)) cjtotal ,
                                
                                SUM(CASE WHEN r.Status IN ( ''签约'', ''认购'' )
                                         THEN r.BldArea
                                         ELSE 0
                                    END) ysmjtotal ,
                                    SUM(CASE WHEN ( r.Status IN ( ''待售'', ''预约'' )
                                                OR ( r.Status = ''销控'' )
                                              ) THEN r.BldArea
                                         ELSE 0
                                    END) mjtotal
                        FROM    ' + @DataBaseName + 'p_Building b
                        LEFT JOIN ' + @DataBaseName
        + 'p_Room r ON r.BldGUID = b.BldGUID
                       
                       LEFT JOIN ( SELECT  RoomGUID ,RmbCjTotal , JfDate
                                            FROM    ' + @DataBaseName
        + 's_Order o
                                            WHERE   o.Status = ''激活''
                                                    AND o.OrderType = ''认购''
                                            UNION ALL
                                            SELECT  RoomGUID ,
                                                    RmbHtTotal rmbcjtotal ,
                                                    JFDate
                                            FROM    ' + @DataBaseName
        + 's_Contract c
                                            WHERE   c.Status = ''激活''
                                          ) t ON t.RoomGUID = r.RoomGUID
                        GROUP BY b.BldGUID 
                      ) bd ON sb.ImportSaleBldGUID = bd.BldGUID
                             
    GROUP BY SaleBldGUID;';
    PRINT 0;
    EXEC(@strSql);
 
 --SBB1 三个月
	
    CREATE TABLE #sbb1
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM待售房间标准总价 MONEY ,
          CRM近三月成交总价 MONEY ,
          CRM近三月成交对应的房间总价 MONEY,
	    );
    SET @strSql = ' 
    insert into #sbb1(SaleBldGUID,CRM待售房间标准总价,CRM近三月成交总价,CRM近三月成交对应的房间总价)
    SELECT sb.SaleBldGUID ,
            SUM(CASE WHEN r.Status NOT IN ( ''认购'', ''签约'' )
                     THEN ISNULL(r.Total, 0)
                     ELSE 0
                END) CRM待售房间标准总价 ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM近三月成交总价 ,
            SUM(CASE WHEN o.OrderGUID IS NOT NULL
                          OR sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.Total, 0)
                     ELSE 0
                END) CRM近三月成交对应的房间总价
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_BuildProductType bp ON r.BProductTypeCode = bp.BProductTypeCode
            LEFT JOIN ' + @DataBaseName
        + 's_Order o ON r.RoomGUID = o.RoomGUID
                                                              AND o.Status = ''激活''
                                                              AND OrderType = ''认购''
                                                              AND DATEDIFF(DD,
                                                              o.QSDate,
                                                              GETDATE()) < 90
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
                                                              AND DATEDIFF(DD,
                                                              sc.QSDate,
                                                              GETDATE()) < 90
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID; ';
    PRINT 1;
    EXEC(@strSql);
                    
--SBB2  一个月   
    CREATE TABLE #sbb2
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM近一月成交总价 MONEY ,
          CRM近一月成交对应的房间面积 MONEY,
	    ); 
    SET @strSql = '
     insert into #sbb2(SaleBldGUID,CRM近一月成交总价,CRM近一月成交对应的房间面积)
     SELECT  sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM近一月成交总价 ,
            SUM(CASE WHEN p.ProductType = ''地下室/车库'' AND p.ProductName <> ''地下储藏室'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM近一月成交对应的房间面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
			LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
                                                              AND DATEDIFF(MM,
                                                              sc.QSDate,
                                                              GETDATE()) = 0
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID; ';
    PRINT 2;
    EXEC(@strSql);  

 --SBB3  一个年
    CREATE TABLE #sbb3
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM近一年成交总价 MONEY ,
          CRM近一年成交对应的房间面积 MONEY,
	    );             
    SET @strSql = '
    insert into #sbb3(SaleBldGUID,CRM近一年成交总价,CRM近一年成交对应的房间面积)
    SELECT sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM近一年成交总价 ,
            SUM(CASE WHEN p.ProductType = ''地下室/车库'' AND p.ProductName <> ''地下储藏室'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM近一年成交对应的房间面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
		LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
                                                              AND DATEDIFF(yyyy,
                                                              sc.QSDate,
                                                              GETDATE()) = 0
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID;  '; 
    PRINT 3;
    EXEC(@strSql);              
--SBB4 累计   
    CREATE TABLE #sbb4
        (
          SaleBldGUID UNIQUEIDENTIFIER ,
          CRM累计成交总价 MONEY ,
          CRM累计成交对应的房间面积 MONEY,
	    );            
    SET @strSql = '  
        insert into #sbb4(SaleBldGUID,CRM累计成交总价,CRM累计成交对应的房间面积)
        SELECT sb.SaleBldGUID ,
            SUM(ISNULL(sc.RmbHtTotal, 0)) CRM累计成交总价 ,
            SUM(CASE WHEN p.ProductType = ''地下室/车库'' AND p.ProductName <> ''地下储藏室'' THEN 1  ELSE CASE WHEN sc.ContractGUID IS NOT NULL
                     THEN ISNULL(r.BldArea, 0)
                     ELSE 0
                END END) CRM累计成交对应的房间面积
    FROM    ' + @DataBaseName + 'mdm_SaleBuild sb
			LEFT JOIN ' + @DataBaseName
        + 'mdm_Product p ON sb.ProductGUID = p.ProductGUID
            LEFT JOIN ' + @DataBaseName
        + 'p_Building b ON sb.ImportSaleBldGUID = b.BldGUID
            LEFT JOIN ' + @DataBaseName + 'p_Room r ON b.BldGUID = r.BldGUID
            LEFT JOIN ' + @DataBaseName
        + 's_Contract sc ON r.RoomGUID = sc.RoomGUID
                                                              AND sc.Status = ''激活''
                                                              AND HtType = ''正式合同''
    WHERE   r.IsVirtualRoom = 0
    GROUP BY sb.SaleBldGUID;   ';
    
    PRINT 4;
    EXEC(@strSql);  
           
    DECLARE @Drr AS VARCHAR(500);  
    DECLARE @DrDate AS DATETIME;  
    SELECT TOP 1
            @Drr = [最后导入人] ,
            @DrDate = [最后导入时间]
    FROM    [nmap_F_价格填报]
    WHERE   FillHistoryGUID = @FillHistoryGUID; 
  
    CREATE TABLE #TempData
        (
          价格填报GUID UNIQUEIDENTIFIER ,
          FillHistoryGUID UNIQUEIDENTIFIER ,
          BusinessGUID UNIQUEIDENTIFIER ,
          项目代码 VARCHAR(400) ,
          项目名称 VARCHAR(400) ,
          产品类型 VARCHAR(400) ,
          产品名称 VARCHAR(400) ,
          单价 MONEY ,
          累计签约均价 MONEY ,
          本年签约均价 MONEY ,
          本月签约均价 MONEY ,
          立项价 MONEY ,
          定位价 MONEY ,
          动态销售单价 MONEY ,
          动态销售面积 MONEY ,
          目标成本单方 MONEY ,
          动态成本单方 MONEY ,
          装修标准 VARCHAR(400) ,
          最后导入人 VARCHAR(400) ,
          最后导入时间 DATETIME ,
          公司简称 VARCHAR(400) ,
          RowID INT ,
          ProductGuid UNIQUEIDENTIFIER ,
          BusinessType VARCHAR(200) ,
          Remark VARCHAR(500)
        );
    PRINT 5;
  
--截至日期最后,且有数据 的版本号
    DECLARE @FillHistoryGUIDLast UNIQUEIDENTIFIER;
  
    SELECT TOP 1
            @FillHistoryGUIDLast = a.FillHistoryGUID
    FROM    nmap_F_FillHistory a
    WHERE   FillDataGUID = ( SELECT FillDataGUID
                             FROM   nmap_F_FillData
                             WHERE  FillName = '价格填报'
                           )
            AND a.ApproveStatus = '已审核'
    ORDER BY EndDate DESC;
  
  
    SET @strSql = ' 
     insert into  #TempData (价格填报GUID ,
                    FillHistoryGUID ,
                    BusinessGUID ,
                    公司简称,
                    项目代码 ,
                    项目名称 ,
                    产品类型 ,
                    产品名称 ,
                    单价 ,
                    累计签约均价 ,
                    本年签约均价 ,
                    本月签约均价 ,
                    立项价 ,
                    定位价 ,
                    动态销售单价 ,
                    动态销售面积 ,
                    目标成本单方 ,
                    动态成本单方 ,
                    装修标准 ,
                    最后导入人 ,
                    最后导入时间,
                    ProductGuid,
                    BusinessType,
                    Remark
                     )
     SELECT  NEWID() [价格填报GUID] ,
            ' + ( CASE WHEN @FillHistoryGUID IS NULL THEN 'NULL'
                       ELSE '''' + CAST(@FillHistoryGUID AS VARCHAR(50))
                            + ''''
                  END ) + ' FillHistoryGUID ,
            B.CompanyGUID [BusinessGUID] ,
            B.CompanyName [公司简称] ,
            ISNULL(p.ProjCode, p1.ProjCode) 项目代码 ,
            ISNULL(p.SpreadName, p1.SpreadName) + ''-'' +
            CASE WHEN p.ProjName IS NULL THEN ''''
                   ELSE p1.ProjName
              END 项目名称 ,
            pd.ProductType 产品类型 ,
            pd.ProductName 产品名称 ,
            ISNULL(A.单价, 0.00) [单价] ,
            CASE WHEN SUM(sb.CRM累计成交对应的房间面积) = 0 THEN 0
                 ELSE SUM(sb.CRM累计成交总价) / SUM(sb.CRM累计成交对应的房间面积)
            END AS 累计签约均价 ,
            CASE WHEN SUM(sb.CRM近一年成交对应的房间面积) = 0 THEN 0
                 ELSE SUM(sb.CRM近一年成交总价) / SUM(sb.CRM近一年成交对应的房间面积)
            END AS 本年签约均价 ,
            CASE WHEN SUM(sb.CRM近一月成交对应的房间面积) = 0 THEN 0
                 ELSE SUM(sb.CRM近一月成交总价) / SUM(sb.CRM近一月成交对应的房间面积)
            END AS 本月签约均价 ,
            ISNULL(A.立项价, 0.00) [立项价] ,
            ISNULL(A.定位价, 0.00) [定位价] ,
            CASE WHEN SUM(sb.动态销售面积) = 0 THEN 0
                 ELSE SUM(sb.[动态销售总价 ]) / SUM(sb.动态销售面积)
            END AS 动态销售单价 ,
            SUM(sb.动态销售面积) AS 动态销售面积 ,
            ISNULL(A.目标成本单方, 0.00) [目标成本单方] ,
            ISNULL(A.动态成本单方, 0.00) [动态成本单方] ,
            ISNULL(A.装修标准, '''') [装修标准] ,
            ' + ( CASE WHEN @Drr IS NULL THEN 'NULL'
                       ELSE '''' + @Drr + ''''
                  END ) + '  [最后导入人] ,
            ' + ( CASE WHEN @DrDate IS NULL THEN 'NULL'
                       ELSE '''' + CONVERT(VARCHAR, @DrDate, 120) + ''''
                  END )
        + ' [最后导入时间],
            pd.ProductGuid,
            pd.BusinessType,
            pd.Remark
    FROM    ( SELECT    sb.SaleBldGUID ,
                        sb.ProductGUID ,
                        sb.GCBldGUID ,
                        CASE WHEN ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积, 0) ) = 0
                             THEN ISNULL(sb.SaleArea, 0)
                             ELSE ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积, 0) )
                        END AS ''动态销售面积'' ,
                        CASE WHEN ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                + ISNULL(sbb.待售面积, 0) ) = 0
                                         THEN ISNULL(sb.SaleArea, 0)
                                         ELSE ( ISNULL(sbb.已售面积, 0)
                                                + ISNULL(sbb.待售面积, 0) )
                                    END ) = 0 THEN 0
                             ELSE ( CASE WHEN ( ISNULL(sbb.已售货量万元, 0)
                                                + ISNULL(CASE WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                         END, 0) ) = 0
                                         THEN sb.PlanSaleTotal
                                         ELSE ( ISNULL(sbb.已售货量万元, 0)
                                                + ISNULL(CASE WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                         END, 0) )
                                    END )
                                  / ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                  + ISNULL(sbb.待售面积, 0) ) = 0
                                           THEN sb.SaleArea
                                           ELSE ( ISNULL(sbb.已售面积, 0)
                                                  + ISNULL(sbb.待售面积, 0) )
                                      END )
                        END AS ''动态销售单价'' ,
                        ( ( CASE WHEN ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积,
                                                              0) ) = 0
                                 THEN ISNULL(sb.SaleArea, 0)
                                 ELSE ( ISNULL(sbb.已售面积, 0) + ISNULL(sbb.待售面积,
                                                              0) )
                            END )
                          * ( CASE WHEN ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                      + ISNULL(sbb.待售面积, 0) ) = 0
                                               THEN ISNULL(sb.SaleArea, 0)
                                               ELSE ( ISNULL(sbb.已售面积, 0)
                                                      + ISNULL(sbb.待售面积, 0) )
                                          END ) = 0 THEN 0
                                   ELSE ( CASE WHEN ( ISNULL(sbb.已售货量万元, 0)
                                                      + ISNULL(CASE
                                                              WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                              END, 0) ) = 0
                                               THEN sb.PlanSaleTotal
                                               ELSE ( ISNULL(sbb.已售货量万元, 0)
                                                      + ISNULL(CASE
                                                              WHEN ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END ) = 0
                                                              THEN ISNULL(sbb1.CRM待售房间标准总价,
                                                              0)
                                                              ELSE sbb1.CRM待售房间标准总价
                                                              * ( CASE
                                                              WHEN ISNULL(sbb1.CRM近三月成交对应的房间总价,
                                                              0) = 0 THEN 0
                                                              ELSE sbb1.CRM近三月成交总价
                                                              / sbb1.CRM近三月成交对应的房间总价
                                                              END )
                                                              END, 0) )
                                          END )
                                        / ( CASE WHEN ( ISNULL(sbb.已售面积, 0)
                                                        + ISNULL(sbb.待售面积, 0) ) = 0
                                                 THEN ISNULL(sb.SaleArea, 0)
                                                 ELSE ( ISNULL(sbb.已售面积, 0)
                                                        + ISNULL(sbb.待售面积, 0) )
                                            END )
                              END ) ) AS ''动态销售总价 '' ,
                        ISNULL(sbb2.CRM近一月成交总价, 0) AS ''CRM近一月成交总价'' ,
                        ISNULL(sbb2.CRM近一月成交对应的房间面积, 0) AS ''CRM近一月成交对应的房间面积'' ,
                        ISNULL(sbb3.CRM近一年成交总价, 0) AS ''CRM近一年成交总价'' ,
                        ISNULL(sbb3.CRM近一年成交对应的房间面积, 0) AS ''CRM近一年成交对应的房间面积'' ,
                        ISNULL(sbb4.CRM累计成交总价, 0) AS ''CRM累计成交总价'' ,
                        ISNULL(sbb4.CRM累计成交对应的房间面积, 0) AS ''CRM累计成交对应的房间面积''
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
            LEFT JOIN ( SELECT  [公司简称] ,
                                BusinessGUID ,
                                产品类型 ,
                                产品名称 ,
                                项目代码 ,
                                项目名称 ,
                                ISNULL([单价], 0.00) [单价] ,
                                ISNULL([立项价], 0.00) [立项价] ,
                                ISNULL([定位价], 0.00) [定位价] ,
                                ISNULL([目标成本单方], 0.00) [目标成本单方] ,
                                ISNULL([动态成本单方], 0.00) [动态成本单方] ,
                                ISNULL([装修标准], '''') [装修标准]
                        FROM    [nmap_F_价格填报]
                        WHERE   FillHistoryGUID = '
        + CASE WHEN @FillHistoryGUIDLast IS NULL THEN 'NULL'
               ELSE '''' + CAST(@FillHistoryGUIDLast AS VARCHAR(50)) + ''''
          END + '
                      ) AS A ON A.BusinessGUID = B.CompanyGUID
                                AND A.[公司简称] = B.CompanyName
                                AND A.项目代码 = ISNULL(p.ProjCode, p1.ProjCode)
                                AND A.项目名称 = ISNULL(p.SpreadName,
                                                    p1.SpreadName)  + ''-'' +
                                CASE WHEN p.ProjName IS NULL THEN ''''
                                       ELSE p1.ProjName
                                  END
                                AND A.产品类型 = pd.ProductType
                                AND A.产品名称 = pd.ProductName
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
            ISNULL(A.单价, 0.00) , 
            ISNULL(A.立项价, 0.00)  ,
            ISNULL(A.定位价, 0.00) ,
            ISNULL(A.目标成本单方, 0.00) ,
            ISNULL(A.动态成本单方, 0.00)  ,
            ISNULL(A.装修标准, ''''),  
            pd.ProductGuid,
            pd.BusinessType,
            pd.Remark '
           
    EXEC (@strSql);
		

--删除旧数据  
    DELETE  FROM nmap_F_价格填报
    WHERE   FillHistoryGUID = @FillHistoryGUID;  
 
--插入新数据
    INSERT  INTO nmap_F_价格填报
            ( 价格填报GUID ,
              FillHistoryGUID ,
              BusinessGUID ,
              项目代码 ,
              项目名称 ,
              产品类型 ,
              产品名称 ,
              单价 ,
              累计签约均价 ,
              本年签约均价 ,
              本月签约均价 ,
              立项价 ,
              定位价 ,
              动态销售单价 ,
              动态销售面积 ,
              目标成本单方 ,
              动态成本单方 ,
              装修标准 ,
              最后导入人 ,
              最后导入时间 ,
              公司简称 ,
              RowID ,
              产品GUID,
              商品类型 ,
              备注
              
            )
            SELECT  价格填报GUID ,
                    FillHistoryGUID ,
                    BusinessGUID ,
                    项目代码 ,
                    项目名称 ,
                    产品类型 ,
                    产品名称 ,
                    单价 ,
                    累计签约均价 ,
                    本年签约均价 ,
                    本月签约均价 ,
                    立项价 ,
                    定位价 ,
                    动态销售单价 ,
                    动态销售面积 ,
                    目标成本单方 ,
                    动态成本单方 ,
                    装修标准 ,
                    最后导入人 ,
                    最后导入时间 ,
                    公司简称 ,
                    ROW_NUMBER() OVER ( ORDER BY 公司简称, BusinessGUID , 项目代码 , 项目名称 , 产品类型 , 产品名称 ) AS [RowID] ,
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
 