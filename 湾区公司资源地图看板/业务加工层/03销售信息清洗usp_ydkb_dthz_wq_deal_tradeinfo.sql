USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_dthz_wq_deal_tradeinfo]    Script Date: 2025/4/21 11:44:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
author:ltx  date:20220430
说明：湾区货量报表交易

运行样例：[usp_ydkb_dthz_wq_deal_tradeinfo]

modify:lintx  date:20220608
增加本年签约面积

modify:lintx date：20221107
1、增加本日、本周、本月、本年退房套数及金额
2、增加本日、本周、本月、本年认购套数及金额，认购含预认购部分
3、增加本日、本周、本月、本年签约套数及金额

modify:lintx date 20231120
1、增加去年认购完成情况
2、增加去年签约完成情况

modify:lintx date 20241030
以前是按照昨天来计算签约认购退房的，现在改成统计当天数
*/
  

ALTER PROC [dbo].[usp_ydkb_dthz_wq_deal_tradeinfo]
AS
BEGIN
    ---------------------参数设置------------------------
    DECLARE @bnYear VARCHAR(4);
    SET @bnYear = YEAR(GETDATE());
    DECLARE @byMonth VARCHAR(2);
    SET @byMonth = MONTH(GETDATE());
    declare @qnDate varchar(10);
    set @qnDate = dateadd(yy,-1,getdate())
    DECLARE @buguid VARCHAR(max) = '248B1E17-AACB-E511-80B8-E41F13C51836,4975b69c-9953-4dd0-a65e-9a36db8c66df,4A1E877C-A0B2-476D-9F19-B5C426173C38,31120F08-22C4-4220-8ED2-DCAD398C823C';
    DECLARE @developmentguid VARCHAR(max) = 'C69E89BB-A2DB-E511-80B8-E41F13C51836,461889dc-e991-4238-9d7c-b29e0aa347bb,5A4B2DEF-E803-49F8-9FE2-308735E7233D,7DF92561-3B0D-E711-80BA-E61F13C57837';
     
	declare @本周一 datetime; --取自然周（周一至周日为一周）
	set @本周一 = CASE WHEN DATEPART(WEEKDAY, GETDATE() - 1) = 1 THEN DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 2), 0))
                        ELSE DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 1), 0))
                   END;
	declare @本周天 datetime;
	set @本周天 =CASE WHEN DATEPART(WEEKDAY, GETDATE() - 1) = 1 THEN DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 2), 6))
                        ELSE DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 1), 6))
                   END


    ---------------------产品楼栋粒度统计--------------------- 
    --获取本月之前的本年认购签约数据
    SELECT SUM(Jan认购金额) AS Jan认购金额,
           SUM(Feb认购金额) AS Feb认购金额,
           SUM(Mar认购金额) AS Mar认购金额,
           SUM(Apr认购金额) AS Apr认购金额,
           SUM(May认购金额) AS May认购金额,
           SUM(Jun认购金额) AS Jun认购金额,
           SUM(Jul认购金额) AS Jul认购金额,
           SUM(Aug认购金额) AS Aug认购金额,
           SUM(Sec认购金额) AS Sec认购金额,
           SUM(Oct认购金额) AS Oct认购金额,
           SUM(Nov认购金额) AS Nov认购金额,
           SUM(Dec认购金额) AS Dec认购金额,
           ProjGUID,
           BldGUID,
           ProductType
    INTO #t_sale_rg1
    FROM
    (
        SELECT pj1.ProjGUID,
               r.BldGUID,
               pt.ProductType,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 1 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Jan认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 2 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Feb认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 3 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Mar认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 4 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Apr认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 5 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS May认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 6 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Jun认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 7 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Jul认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 8 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Aug认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 9 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Sec认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 10 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Oct认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 11 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Nov认购金额,
               SUM(   CASE
                          WHEN MONTH(so.QSDate) = 12 THEN
                      (CASE
                           WHEN sc.status = '激活' THEN
                               sc.jytotal
                           ELSE
                               so.jytotal
                       END
                      )
                          ELSE
                              0
                      END
                  ) / 10000 AS Dec认购金额
        FROM s_Order so
            LEFT JOIN dbo.p_room r
                ON so.RoomGUID = r.RoomGUID
            LEFT JOIN
            (SELECT DISTINCT ProductType, ProductName FROM dbo.mdm_Product) pt
                ON pt.ProductName = r.ProductName
            LEFT JOIN dbo.mdm_Project pj
                ON pj.ProjGUID = so.ProjGUID
            LEFT JOIN dbo.mdm_Project pj1
                ON pj1.ProjGUID = pj.ParentProjGUID
            LEFT JOIN dbo.s_Contract sc
                ON so.TradeGUID = sc.TradeGUID
        WHERE so.BUGUID IN (
                               SELECT Value FROM dbo.fn_Split2(@buguid, ',')
                           )
              AND
              (
                  so.Status = '激活'
                  OR
                  (
                      so.CloseReason = '转签约'
                      AND sc.Status = '激活'
                  )
              )
              AND so.QSDate
              BETWEEN @bnYear + '-01-01' AND @bnYear + '-12-31'
        GROUP BY pj1.ProjGUID,
                 r.BldGUID,
                 pt.ProductType
        UNION ALL
        SELECT pj1.ProjGUID,
               r.BldGUID,
               pt.ProductType,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 1 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Jan认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 2 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Feb认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 3 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Mar认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 4 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Apr认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 5 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS May认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 6 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Jun认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 7 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Jul认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 8 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Aug认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 9 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Sec认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 10 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Oct认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 11 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Nov认购金额,
               SUM(   CASE
                          WHEN MONTH(sc.QSDate) = 12 THEN
                              sc.JyTotal
                          ELSE
                              0
                      END
                  ) / 10000 AS Dec认购金额
        FROM s_Contract sc
            LEFT JOIN dbo.p_room r
                ON sc.RoomGUID = r.RoomGUID
            LEFT JOIN
            (SELECT DISTINCT ProductType, ProductName FROM dbo.mdm_Product) pt
                ON pt.ProductName = r.ProductName
            LEFT JOIN dbo.mdm_Project pj
                ON pj.ProjGUID = sc.ProjGUID
            LEFT JOIN dbo.mdm_Project pj1
                ON pj1.ProjGUID = pj.ParentProjGUID
            LEFT JOIN s_order so
                ON so.TradeGUID = sc.TradeGUID
        WHERE sc.Status = '激活'
              AND sc.BUGUID IN (
                                   SELECT Value FROM dbo.fn_Split2(@buguid, ',')
                               )
              AND so.TradeGUID IS NULL
              AND sc.QSDate
              BETWEEN @bnYear + '-01-01' AND @bnYear + '-12-31'
        GROUP BY pj1.ProjGUID,
                 r.BldGUID,
                 pt.ProductType
    ) t
    GROUP BY projguid,
             t.BldGUID,
             t.ProductType;

    SELECT pj1.ProjGUID,
           r.BldGUID,
           pt.ProductType,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 1 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Jan签约金额,
           SUM(   CASE
                      WHEN MONTH(QSDate) = 2 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Feb签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 3 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Mar签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 4 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Apr签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 5 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS May签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 6 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Jun签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 7 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Jul签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 8 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Aug签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 9 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Sec签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 10 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Oct签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 11 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Nov签约金额,
           SUM(   CASE
                      WHEN  MONTH(QSDate) = 12 THEN
                          sc.JyTotal
                      ELSE
                          0
                  END
              ) / 10000 AS Dec签约金额 
    INTO #t_sale_qy1
    FROM s_Contract sc
        LEFT JOIN dbo.p_room r
            ON sc.RoomGUID = r.RoomGUID
        LEFT JOIN
        (SELECT DISTINCT ProductType, ProductName FROM dbo.mdm_Product) pt
            ON pt.ProductName = r.ProductName
        LEFT JOIN dbo.mdm_Project pj
            ON pj.ProjGUID = sc.ProjGUID
        LEFT JOIN dbo.mdm_Project pj1
            ON pj1.ProjGUID = pj.ParentProjGUID
    WHERE sc.Status = '激活'
          AND sc.BUGUID IN (
                               SELECT value FROM dbo.fn_Split2(@buguid, ',')
                           )
          AND sc.QSDate BETWEEN @bnYear + '-01-01' AND @bnYear + '-12-31'  
    GROUP BY pj1.ProjGUID,
             r.BldGUID,
             pt.ProductType;

    --获取本月及本月之后的认购签约数，从楼栋货量铺排中获取
    SELECT ProjGUID,
           ProductType,
           SaleBldGUID,
           --本年认购
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '1') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jan认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '2') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Feb认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '3') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Mar认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '4') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Apr认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '5') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS May认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '6') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jun认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '7') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS July认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '8') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Aug认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '9') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Sep认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '10') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Oct认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '11') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Nov认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '12' --and ProjGUID<> 'D07CCF43-CBC0-E811-80BF-E61F13C57837' 
                           ) THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Dec认购金额,

           --本年签约
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '1') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jan签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '2') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Feb签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '3') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Mar签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '4') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Apr签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '5') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS May签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '6') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jun签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '7') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS July签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '8') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Aug签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '9') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Sep签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '10') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Oct签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '11') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Nov签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '12' --and ProjGUID<> 'D07CCF43-CBC0-E811-80BF-E61F13C57837' 
                           ) THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Dec签约金额
    INTO #t_sale2
    FROM dbo.s_SaleValueBuildLayout a
    WHERE SaleValuePlanYear = @bnYear
          AND SaleValuePlanMonth >= @byMonth
          AND a.DevelopmentCompanyGUID IN (
                                              SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
                                          )
    GROUP BY ProjGUID,
             ProductType,
             SaleBldGUID;

    SELECT bi.组织架构ID,
           bi.组织架构名称,
           bi.组织架构编码,
           bi.组织架构类型,
           pj.ParentProjGUID AS projguid,
           pr.ProductType,
           --本年认购情况
           SUM(   CASE
                      WHEN @byMonth <= 1 THEN
                          ISNULL(sale2.Jan认购金额, 0)
                      WHEN @byMonth > 1 THEN
                          sale1.Jan认购金额
                      ELSE
                          0
                  END
              ) AS Jan认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 2 THEN
                          ISNULL(sale2.Feb认购金额, 0)
                      WHEN @byMonth > 2 THEN
                          sale1.Feb认购金额
                      ELSE
                          0
                  END
              ) AS Feb认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 3 THEN
                          ISNULL(sale2.Mar认购金额, 0)
                      WHEN @byMonth > 3 THEN
                          sale1.Mar认购金额
                      ELSE
                          0
                  END
              ) AS Mar认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 4 THEN
                          ISNULL(sale2.Apr认购金额, 0)
                      WHEN @byMonth > 4 THEN
                          sale1.Apr认购金额
                      ELSE
                          0
                  END
              ) AS Apr认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 5 THEN
                          ISNULL(sale2.May认购金额, 0)
                      WHEN @byMonth > 5 THEN
                          sale1.May认购金额
                      ELSE
                          0
                  END
              ) AS May认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 6 THEN
                          ISNULL(sale2.Jun认购金额, 0)
                      WHEN @byMonth > 6 THEN
                          sale1.Jun认购金额
                      ELSE
                          0
                  END
              ) AS Jun认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 7 THEN
                          ISNULL(sale2.July认购金额, 0)
                      WHEN @byMonth > 7 THEN
                          sale1.Jul认购金额
                      ELSE
                          0
                  END
              ) AS Jul认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 8 THEN
                          ISNULL(sale2.Aug认购金额, 0)
                      WHEN @byMonth > 8 THEN
                          sale1.Aug认购金额
                      ELSE
                          0
                  END
              ) AS Aug认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 9 THEN
                          ISNULL(sale2.Sep认购金额, 0)
                      WHEN @byMonth > 9 THEN
                          sale1.Sec认购金额
                      ELSE
                          0
                  END
              ) AS Sep认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 10 THEN
                          ISNULL(sale2.Oct认购金额, 0)
                      WHEN @byMonth > 10 THEN
                          sale1.Oct认购金额
                      ELSE
                          0
                  END
              ) AS Oct认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 11 THEN
                          ISNULL(sale2.Nov认购金额, 0)
                      WHEN @byMonth > 11 THEN
                          sale1.Nov认购金额
                      ELSE
                          0
                  END
              ) AS Nov认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 12 THEN
                          ISNULL(sale2.Dec认购金额, 0)
                      WHEN @byMonth > 12 THEN
                          sale1.Dec认购金额
                      ELSE
                          0
                  END
              ) AS Dec认购金额,
           --本年签约 
           SUM(   CASE
                      WHEN @byMonth <= 1 THEN
                          ISNULL(sale2.Jan签约金额, 0)
                      WHEN @byMonth > 1 THEN
                          qy.Jan签约金额
                      ELSE
                          0
                  END
              ) AS Jan签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 2 THEN
                          ISNULL(sale2.Feb签约金额, 0)
                      WHEN @byMonth > 2 THEN
                          qy.Feb签约金额
                      ELSE
                          0
                  END
              ) AS Feb签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 3 THEN
                          ISNULL(sale2.Mar签约金额, 0)
                      WHEN @byMonth > 3 THEN
                          qy.Mar签约金额
                      ELSE
                          0
                  END
              ) AS Mar签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 4 THEN
                          ISNULL(sale2.Apr签约金额, 0)
                      WHEN @byMonth > 4 THEN
                          qy.Apr签约金额
                      ELSE
                          0
                  END
              ) AS Apr签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 5 THEN
                          ISNULL(sale2.May签约金额, 0)
                      WHEN @byMonth > 5 THEN
                          qy.May签约金额
                      ELSE
                          0
                  END
              ) AS May签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 6 THEN
                          ISNULL(sale2.Jun签约金额, 0)
                      WHEN @byMonth > 6 THEN
                          qy.Jun签约金额
                      ELSE
                          0
                  END
              ) AS Jun签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 7 THEN
                          ISNULL(sale2.July签约金额, 0)
                      WHEN @byMonth > 7 THEN
                          qy.Jul签约金额
                      ELSE
                          0
                  END
              ) AS Jul签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 8 THEN
                          ISNULL(sale2.Aug签约金额, 0)
                      WHEN @byMonth > 8 THEN
                          qy.Aug签约金额
                      ELSE
                          0
                  END
              ) AS Aug签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 9 THEN
                          ISNULL(sale2.Sep签约金额, 0)
                      WHEN @byMonth > 9 THEN
                          qy.Sec签约金额
                      ELSE
                          0
                  END
              ) AS Sep签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 10 THEN
                          ISNULL(sale2.Oct签约金额, 0)
                      WHEN @byMonth > 10 THEN
                          qy.Oct签约金额
                      ELSE
                          0
                  END
              ) AS Oct签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 11 THEN
                          ISNULL(sale2.Nov签约金额, 0)
                      WHEN @byMonth > 11 THEN
                          qy.Nov签约金额
                      ELSE
                          0
                  END
              ) AS Nov签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 12 THEN
                          ISNULL(sale2.Dec签约金额, 0)
                      WHEN @byMonth > 12 THEN
                          qy.Dec签约金额
                      ELSE
                          0
                  END
              ) AS Dec签约金额
    INTO #ldhz
    FROM erp25.dbo.ydkb_BaseInfo bi
        LEFT JOIN #t_sale_rg1 sale1
            ON sale1.BldGUID = bi.组织架构ID
        LEFT JOIN #t_sale_qy1 qy
            ON qy.BldGUID = bi.组织架构ID
        LEFT JOIN #t_sale2 sale2
            ON sale2.SaleBldGUID = bi.组织架构ID
        INNER JOIN erp25.dbo.mdm_SaleBuild sb
            ON sb.SaleBldGUID = bi.组织架构ID
        INNER JOIN dbo.mdm_Product pr
            ON pr.ProductGUID = sb.ProductGUID
        INNER JOIN dbo.mdm_Project pj
            ON pj.ProjGUID = pr.ProjGUID
    WHERE bi.组织架构类型 = 5 and bi.平台公司GUID in (SELECT Value FROM dbo.fn_Split2(@developmentguid, ','))
    GROUP BY bi.组织架构ID,
             bi.组织架构名称,
             bi.组织架构编码,
             bi.组织架构类型,
             pj.ParentProjGUID,
             pr.ProductType;

    ---------------------业态粒度统计--------------------- 
    --获取货量铺排的签约认购数据
    --获取本月之前的签约数

    SELECT ProductType,
           ProjGUID,
           SUM(Jan认购金额) AS Jan认购金额,
           SUM(Feb认购金额) AS Feb认购金额,
           SUM(Mar认购金额) AS Mar认购金额,
           SUM(Apr认购金额) AS Apr认购金额,
           SUM(May认购金额) AS May认购金额,
           SUM(Jun认购金额) AS Jun认购金额,
           SUM(Jul认购金额) AS Jul认购金额,
           SUM(Aug认购金额) AS Aug认购金额,
           SUM(Sec认购金额) AS Sep认购金额,
           SUM(Oct认购金额) AS Oct认购金额,
           SUM(Nov认购金额) AS Nov认购金额,
           SUM(Dec认购金额) AS Dec认购金额
    INTO #yt_sale_rg
    FROM #t_sale_rg1
    GROUP BY ProductType,
             ProjGUID;

    SELECT ProductType,
           ProjGUID,
           SUM(Jan签约金额) AS Jan签约金额,
           SUM(Feb签约金额) AS Feb签约金额,
           SUM(Mar签约金额) AS Mar签约金额,
           SUM(Apr签约金额) AS Apr签约金额,
           SUM(May签约金额) AS May签约金额,
           SUM(Jun签约金额) AS Jun签约金额,
           SUM(Jul签约金额) AS Jul签约金额,
           SUM(Aug签约金额) AS Aug签约金额,
           SUM(Sec签约金额) AS Sep签约金额,
           SUM(Oct签约金额) AS Oct签约金额,
           SUM(Nov签约金额) AS Nov签约金额,
           SUM(Dec签约金额) AS Dec签约金额
    INTO #yt_sale1
    FROM #t_sale_qy1
    GROUP BY ProductType,
             ProjGUID;

    --获取本月及本月之后的签约认购数据
    --获取本月及本月之后的认购签约数，从楼栋货量铺排中获取
    SELECT ProjGUID,
           ProductType,
           --本年认购
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '1') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jan认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '2') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Feb认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '3') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Mar认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '4') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Apr认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '5') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS May认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '6') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jun认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '7') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS July认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '8') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Aug认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '9') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Sep认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '10') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Oct认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '11') THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Nov认购金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '12' --and ProjGUID<> 'D07CCF43-CBC0-E811-80BF-E61F13C57837' 
                           ) THEN
                          ISNULL(a.ThisMonthSaleMoneyRg, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Dec认购金额,

           --本年签约
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '1') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jan签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '2') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Feb签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '3') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Mar签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '4') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Apr签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '5') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS May签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '6') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Jun签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '7') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS July签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '8') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Aug签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '9') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Sep签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '10') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Oct签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '11') THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Nov签约金额,
           SUM(   CASE
                      WHEN (SaleValuePlanMonth = '12' --and ProjGUID<> 'D07CCF43-CBC0-E811-80BF-E61F13C57837'
                           ) THEN
                          ISNULL(a.ThisMonthSaleMoneyQy, 0)
                      ELSE
                          0
                  END
              ) * 1.0 / 10000 AS Dec签约金额
    INTO #yt_sale2
    FROM dbo.s_SaleValuePlan a
    WHERE SaleValuePlanYear = @bnYear
          AND SaleValuePlanMonth >= @byMonth
      and a.BUGUID IN (SELECT Value FROM dbo.fn_Split2(@buguid, ',') )
    GROUP BY ProjGUID,
             ProductType;

    --合并业态的值   
    SELECT bi.组织架构ID,
           bi.组织架构名称,
           bi.组织架构编码,
           bi.组织架构类型,
           bi.组织架构父级ID,
           --本年认购
           SUM(   CASE
                      WHEN @byMonth <= 1 THEN
                          ISNULL(s3.Jan认购金额, 0)
                      WHEN @byMonth > 1 THEN
                          ISNULL(s1.Jan认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Jan认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 2 THEN
                          ISNULL(s3.Feb认购金额, 0)
                      WHEN @byMonth > 2 THEN
                          ISNULL(s1.Feb认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Feb认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 3 THEN
                          ISNULL(s3.Mar认购金额, 0)
                      WHEN @byMonth > 3 THEN
                          ISNULL(s1.Mar认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Mar认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 4 THEN
                          ISNULL(s3.Apr认购金额, 0)
                      WHEN @byMonth > 4 THEN
                          ISNULL(s1.Apr认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Apr认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 5 THEN
                          ISNULL(s3.May认购金额, 0)
                      WHEN @byMonth > 5 THEN
                          ISNULL(s1.May认购金额, 0)
                      ELSE
                          0
                  END
              ) AS May认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 6 THEN
                          ISNULL(s3.Jun认购金额, 0)
                      WHEN @byMonth > 6 THEN
                          ISNULL(s1.Jun认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Jun认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 7 THEN
                          ISNULL(s3.July认购金额, 0)
                      WHEN @byMonth > 7 THEN
                          ISNULL(s1.Jul认购金额, 0)
                      ELSE
                          0
                  END
              ) AS July认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 8 THEN
                          ISNULL(s3.Aug认购金额, 0)
                      WHEN @byMonth > 8 THEN
                          ISNULL(s1.Aug认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Aug认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 9 THEN
                          ISNULL(s3.Sep认购金额, 0)
                      WHEN @byMonth > 9 THEN
                          ISNULL(s1.Sep认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Sep认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 10 THEN
                          ISNULL(s3.Oct认购金额, 0)
                      WHEN @byMonth > 10 THEN
                          ISNULL(s1.Oct认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Oct认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 11 THEN
                          ISNULL(s3.Nov认购金额, 0)
                      WHEN @byMonth > 11 THEN
                          ISNULL(s1.Nov认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Nov认购金额,
           SUM(   CASE
                      WHEN @byMonth <= 12 THEN
                          ISNULL(s3.Dec认购金额, 0)
                      WHEN @byMonth > 12 THEN
                          ISNULL(s1.Dec认购金额, 0)
                      ELSE
                          0
                  END
              ) AS Dec认购金额,

           --本年签约 
           SUM(   CASE
                      WHEN @byMonth <= 1 THEN
                          ISNULL(s3.Jan签约金额, 0)
                      WHEN @byMonth > 1 THEN
                          ISNULL(s2.Jan签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Jan签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 2 THEN
                          ISNULL(s3.Feb签约金额, 0)
                      WHEN @byMonth > 2 THEN
                          ISNULL(s2.Feb签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Feb签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 3 THEN
                          ISNULL(s3.May签约金额, 0)
                      WHEN @byMonth > 3 THEN
                          ISNULL(s2.Mar签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Mar签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 4 THEN
                          ISNULL(s3.Apr签约金额, 0)
                      WHEN @byMonth > 4 THEN
                          ISNULL(s2.Apr签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Apr签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 5 THEN
                          ISNULL(s3.May签约金额, 0)
                      WHEN @byMonth > 5 THEN
                          ISNULL(s2.May签约金额, 0)
                      ELSE
                          0
                  END
              ) AS May签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 6 THEN
                          ISNULL(s3.Jun签约金额, 0)
                      WHEN @byMonth > 6 THEN
                          ISNULL(s2.Jun签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Jun签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 7 THEN
                          ISNULL(s3.July签约金额, 0)
                      WHEN @byMonth > 7 THEN
                          ISNULL(s2.Jul签约金额, 0)
                      ELSE
                          0
                  END
              ) AS July签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 8 THEN
                          ISNULL(s3.Aug签约金额, 0)
                      WHEN @byMonth > 8 THEN
                          ISNULL(s2.Aug签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Aug签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 9 THEN
                          ISNULL(s3.Sep签约金额, 0)
                      WHEN @byMonth > 9 THEN
                          ISNULL(s2.Sep签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Sep签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 10 THEN
                          ISNULL(s3.Oct签约金额, 0)
                      WHEN @byMonth > 10 THEN
                          ISNULL(s2.Oct签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Oct签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 11 THEN
                          ISNULL(s3.Nov签约金额, 0)
                      WHEN @byMonth > 11 THEN
                          ISNULL(s2.Nov签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Nov签约金额,
           SUM(   CASE
                      WHEN @byMonth <= 12 THEN
                          ISNULL(s3.Dec签约金额, 0)
                      WHEN @byMonth > 12 THEN
                          ISNULL(s2.Dec签约金额, 0)
                      ELSE
                          0
                  END
              ) AS Dec签约金额
    INTO #ythz
    FROM erp25.dbo.ydkb_BaseInfo bi
        LEFT JOIN #yt_sale_rg s1
            ON s1.ProjGUID = bi.组织架构父级ID
               AND bi.组织架构名称 = s1.ProductType
        LEFT JOIN #yt_sale1 s2
            ON s2.ProjGUID = bi.组织架构父级ID
               AND bi.组织架构名称 = s2.ProductType
        LEFT JOIN #yt_sale2 s3
            ON s3.ProjGUID = bi.组织架构父级ID
               AND bi.组织架构名称 = s3.ProductType
    WHERE bi.组织架构类型 = 4 and bi.平台公司GUID  IN (SELECT Value FROM dbo.fn_Split2(@developmentguid, ','))
    GROUP BY bi.组织架构ID,
             bi.组织架构名称,
             bi.组织架构编码,
             bi.组织架构类型,
             bi.组织架构父级ID;

    /*获取楼栋待收款情况*/
    --找到激活的认购单及合同
    SELECT so.TradeGUID,
           pj1.ProjGUID,
           bi.ProductType,
           r.BldGUID,
           ISNULL(HtType, '认购') AS 合同类型
    INTO #t_sale
    FROM s_Order so
        LEFT JOIN s_Contract sc
            ON so.TradeGUID = sc.TradeGUID
        LEFT JOIN p_room r
            ON r.RoomGUID = so.RoomGUID
        LEFT JOIN mdm_SaleBuild sb
            ON sb.SaleBldGUID = r.BldGUID
        LEFT JOIN mdm_Product bi
            ON sb.ProductGUID = bi.ProductGUID
        LEFT JOIN p_Project pj
            ON pj.ProjGUID = so.ProjGUID
        LEFT JOIN p_Project pj1
            ON pj.ParentCode = pj1.ProjCode
    WHERE (
              so.Status = '激活'
              OR
              (
                  sc.Status = '激活'
                  AND so.CloseReason = '转签约'
              )
          )
          AND so.OrderType = '认购'
          AND so.BUGUID IN (
                               SELECT value FROM dbo.fn_Split2(@buguid, ',')
                           )
    UNION ALL
    --获取直接签约的情况
    SELECT sc.TradeGUID,
           pj1.ProjGUID,
           bi.ProductType,
           r.BldGUID,
           ISNULL(HtType, '认购') AS 合同类型
    FROM s_Contract sc
        LEFT JOIN s_Order so
            ON so.TradeGUID = sc.TradeGUID
        LEFT JOIN p_room r
            ON r.RoomGUID = sc.RoomGUID
        LEFT JOIN mdm_SaleBuild sb
            ON sb.SaleBldGUID = r.BldGUID
        LEFT JOIN mdm_Product bi
            ON sb.ProductGUID = bi.ProductGUID
        LEFT JOIN p_Project pj
            ON pj.ProjGUID = sc.ProjGUID
        LEFT JOIN p_Project pj1
            ON pj.ParentCode = pj1.ProjCode
    WHERE sc.Status = '激活'
          AND so.OrderGUID IS NULL
          AND sc.BUGUID IN (
                               SELECT value FROM dbo.fn_Split2(@buguid, ',')
                           );

    --获取销售情况的应收款
    SELECT s.BldGUID,
           s.ProductType,
           s.ProjGUID,
           SUM(   CASE
                      WHEN
                      (
                          ItemType = '贷款类房款'
                          OR ItemType = '非贷款类房款'
                          OR ItemName = '装修款'
                      ) THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 累计待收款,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '认购', '临时合同' )
                           AND
                           (
                               ItemType = '贷款类房款'
                               OR ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           ) THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 累计非正签待收款,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '认购', '临时合同' )
                           AND ItemType = '贷款类房款' THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 累计未正签按揭待收款,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '认购', '临时合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           ) THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 累计未正签非按揭待收款,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '认购', '临时合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           )
                           AND DATEDIFF(mm, ISNULL(lastDate, '2099-12-31'), GETDATE()) = 0 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 累计未正签非按揭待收款本月到期,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '认购', '临时合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           )
                           AND DATEDIFF(mm, GETDATE(), ISNULL(lastDate, '2099-12-31')) = 1 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 累计未正签非按揭待收款下月到期,
           SUM(   CASE
                      WHEN 合同类型 IN ( '正式合同' )
                           AND
                           (
                               sf.ItemType IN ( '贷款类房款', '非贷款类房款' )
                               OR ItemName = '装修款'
                           ) THEN
                          ISNULL(Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 累计正签待收款,
           SUM(   CASE
                      WHEN 合同类型 IN ( '正式合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           ) THEN
                          ISNULL(Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 正签非按揭待收款,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           )
                           AND DATEDIFF(mm, GETDATE(), ISNULL(lastDate, '2099-12-31')) = 0 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 正签非按揭待收款本月到期,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           )
                           AND DATEDIFF(mm, GETDATE(), ISNULL(lastDate, '2099-12-31')) = 1 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 正签非按揭待收款下月到期,
           SUM(   CASE
                      WHEN 合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName IN ( '按揭装修款', '银行按揭' ) THEN
                          ISNULL(Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 正签商业贷款待收款,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName IN ( '按揭装修款', '银行按揭' )
                           AND DATEDIFF(mm, GETDATE(), ISNULL(lastDate, '2099-12-31')) = 0 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 正签商业贷款待收款本月到期,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName IN ( '按揭装修款', '银行按揭' )
                           AND DATEDIFF(mm, GETDATE(), ISNULL(lastDate, '2099-12-31')) = 1 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 正签商业贷款待收款下月到期,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName NOT IN ( '按揭装修款', '银行按揭' ) THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 正签公积金贷款待收款,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName NOT IN ( '按揭装修款', '银行按揭' )
                           AND DATEDIFF(mm, GETDATE(), ISNULL(lastDate, '2099-12-31')) = 0 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 正签公积金贷款本月到期,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName NOT IN ( '按揭装修款', '银行按揭' )
                           AND DATEDIFF(mm, GETDATE(), ISNULL(lastDate, '2099-12-31')) = 1 THEN
                          ISNULL(sf.Ye, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 正签公积金贷款下月到期
    INTO #s_fee
    FROM #t_sale s
        LEFT JOIN s_Fee sf
            ON s.TradeGUID = sf.TradeGUID
    GROUP BY s.BldGUID,
             s.ProductType,
             s.ProjGUID;

    --获取待收款完成情况
    SELECT s.BldGUID,
           s.ProductType,
           s.ProjGUID,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '认购', '临时合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           ) THEN
                          ISNULL(Amount, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 累计未正签非按揭待收款本月完成,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND
                           (
                               ItemType = '非贷款类房款'
                               OR ItemName = '装修款'
                           ) THEN
                          ISNULL(Amount, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 正签非按揭待收款本月完成,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName IN ( '按揭装修款', '银行按揭' ) THEN
                          ISNULL(Amount, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 正签商业贷款待收款本月完成,
           SUM(   CASE
                      WHEN s.合同类型 IN ( '正式合同' )
                           AND ItemType = '贷款类房款'
                           AND ItemName NOT IN ( '按揭装修款', '银行按揭' ) THEN
                          ISNULL(Amount, 0)
                      ELSE
                          0
                  END
              ) / 10000 AS 正签公积金贷款本月完成
    INTO #s_getin
    FROM #t_sale s
        INNER JOIN s_Getin sg
            ON s.TradeGUID = sg.SaleGUID
    WHERE sg.Status IS NULL
          AND ISNULL(sg.SaleType, '') <> '预约单'
          AND DATEDIFF(mm, GETDATE(), GetDate) = 0
    GROUP BY s.BldGUID,
             s.ProductType,
             s.ProjGUID;

    --获取合作业绩的情况
    SELECT a.ProductType,
           p.ProjGUID,
           SUM(a.Amount) - SUM(a.huilongjiner) AS 待收款金额,
           SUM(a.Amount) AS 累计签约额,
           SUM(a.Area) AS 累计签约面积,
           SUM(   CASE
                      WHEN b.DateMonth = 1
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Jan金额,
           SUM(   CASE
                      WHEN b.DateMonth = 2
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Feb金额,
           SUM(   CASE
                      WHEN b.DateMonth = 3
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Mar金额,
           SUM(   CASE
                      WHEN b.DateMonth = 4
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Apr金额,
           SUM(   CASE
                      WHEN b.DateMonth = 5
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS May金额,
           SUM(   CASE
                      WHEN b.DateMonth = 6
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Jun金额,
           SUM(   CASE
                      WHEN b.DateMonth = 7
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Jul金额,
           SUM(   CASE
                      WHEN b.DateMonth = 8
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Aug金额,
           SUM(   CASE
                      WHEN b.DateMonth = 9
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Sep金额,
           SUM(   CASE
                      WHEN b.DateMonth = 10
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Oct金额,
           SUM(   CASE
                      WHEN b.DateMonth = 11
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Nov金额,
           SUM(   CASE
                      WHEN b.DateMonth = 12
                           AND b.DateYear = @bnYear THEN
                          a.Amount
                      ELSE
                          0
                  END
              ) AS Dec金额
    INTO #hzyj
    FROM dbo.s_YJRLProducteDescript a
        LEFT JOIN dbo.s_YJRLProducteDetail b
            ON b.ProducteDetailGUID = a.ProducteDetailGUID
        LEFT JOIN dbo.s_YJRLProjSet c
            ON c.ProjSetGUID = b.ProjSetGUID
        LEFT JOIN dbo.mdm_Project p
            ON p.ProjGUID = c.ProjGUID
        LEFT JOIN dbo.p_DevelopmentCompany m
            ON m.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
    WHERE b.Shenhe = '审核'
          AND c.BUGuid IN (
                              SELECT value FROM dbo.fn_Split2(@buguid, ',')
                          )
    GROUP BY a.ProductType,
             p.ProjGUID;

    ---------------------------获取本日、本周、本月、本年的退房情况  begin----------------------- 
    --退房 
    select r.BldGUID,sb.GCBldGUID,cp.ProductType,mp.parentprojguid as projguid,
    sum(case when datediff(dd,getdate(),a.ExecDate) = 0 then 1 else 0 end) 今日退房套数, 
    sum(case when datediff(dd,getdate(),a.ExecDate) = 0 then ISNULL(c.JyTotal, o.JyTotal) else 0 end)/ 10000.0 今日退房金额,  
    sum(case when datediff(dd,getdate(),a.ExecDate) = 0 then ISNULL(c.bldarea, o.bldarea) else 0 end) 今日退房面积,   
	sum(case when a.ExecDate between @本周一 and @本周天 then 1 else 0 end) as 本周退房套数,
	sum(case when a.ExecDate between @本周一 and @本周天 then ISNULL(c.JyTotal, o.JyTotal) else 0 end)/ 10000.0 本周退房金额,
    sum(case when a.ExecDate between @本周一 and @本周天 then ISNULL(c.bldarea, o.bldarea) else 0 end) 本周退房面积,
    sum(case when datediff(mm,getdate(),a.ExecDate) = 0 then 1 else 0 end) 本月退房套数,  
    sum(case when datediff(mm,getdate(),a.ExecDate) = 0 then ISNULL(c.JyTotal, o.JyTotal) else 0 end)/ 10000.0 本月退房金额,  
    sum(case when datediff(mm,getdate(),a.ExecDate) = 0 then ISNULL(c.bldarea, o.bldarea) else 0 end) 本月退房面积,  
    sum(1) 本年退房套数,  
    sum(ISNULL(c.JyTotal, o.JyTotal))/ 10000.0 本年退房金额,
    sum(ISNULL(c.bldarea, o.bldarea)) 本年退房面积
    into #tfinfo
    from dbo.s_SaleModiApply a
    inner JOIN dbo.myWorkflowProcessEntity w ON a.SaleModiApplyGUID = w.BusinessGUID 
    inner join dbo.ep_room r ON a.RoomGUID = r.RoomGUID
    LEFT JOIN dbo.mdm_SaleBuild sb ON r.BldGUID = sb.ImportSaleBldGUID
    LEFT JOIN dbo.mdm_Product cp ON cp.ProductGUID = sb.ProductGUID
    LEFT JOIN dbo.mdm_Project mp ON cp.ProjGUID = mp.ProjGUID 
    LEFT JOIN dbo.es_Contract c ON a.SaleGUID = c.ContractGUID
    LEFT JOIN dbo.s_Order o1 ON c.LastSaleGUID = o1.OrderGUID
    LEFT JOIN dbo.es_Order o ON a.SaleGUID = o.OrderGUID
    where w.ProcessStatus IN ( '0', '1', '2' ) and a.ApplyType = '退房' AND w.ProcessGUID IS NOT NULL
    AND datediff(yy,getdate(),a.ExecDate) = 0  and a.BUGUID in (select value from fn_Split2(@buguid,','))
    group by r.BldGUID,sb.GCBldGUID,cp.ProductType,mp.parentprojguid
               
	
          
    ---------------------------获取本日、本周、本月、本年的退房情况  end-------------------------  
	------------------------获取产品楼栋的情况 begin --------------------------------------------
	--插入产品楼栋的值
    SELECT p.BldGUID,
           SUM(JyTotal) / 10000.0 AS 已认购未签约金额
    INTO #so
    FROM dbo.s_Order so
        INNER JOIN p_room p
            ON p.RoomGUID = so.RoomGUID
    WHERE so.Status = '激活'
          AND so.BUGUID IN (SELECT Value FROM dbo.fn_Split2(@buguid, ',') )
    GROUP BY p.BldGUID;

  --获取预认购部分，踢掉已经转认购或签约的部分
    select r.BldGUID,
    sum(case when datediff(dd,pre.CjDate,GetDate()) = 0 then 1 else 0 end ) 本日认购套数,  
    sum(case when datediff(dd,pre.CjDate,GetDate()) = 0 then CjAmount else 0 end )/10000.0 本日认购金额,  
    sum(case when datediff(dd,pre.CjDate,GetDate()) = 0 then r.BldArea else 0 end ) 本日认购面积, 
    sum(case when pre.CjDate between @本周一 and @本周天 then 1 else 0 end ) 本周认购套数,  
	sum(case when pre.CjDate between @本周一 and @本周天  then CjAmount else 0 end )/10000.0 本周认购金额,
	sum(case when pre.CjDate between @本周一 and @本周天  then r.BldArea else 0 end ) 本周认购面积, 
    sum(case when datediff(mm,pre.CjDate,GetDate()) = 0 then 1 else 0 end ) 本月认购套数,  
    sum(case when datediff(mm,pre.CjDate,GetDate()) = 0 then CjAmount else 0 end )/10000.0 本月认购金额,
    sum(case when datediff(mm,pre.CjDate,GetDate()) = 0 then r.BldArea else 0 end ) 本月认购面积,  
    sum(case when datediff(yy,pre.CjDate,GetDate()) = 0 then 1 else 0 end ) 本年认购套数,  
    sum(case when datediff(yy,pre.CjDate,GetDate()) = 0 then CjAmount else 0 end )/10000.0 本年认购金额,
    sum(case when datediff(yy,pre.CjDate,GetDate()) = 0 then r.BldArea else 0 end ) 本年认购面积,
    sum(case when datediff(yy,pre.CjDate,@qnDate) = 0 then 1 else 0 end ) 去年认购套数,  
    sum(case when datediff(yy,pre.CjDate,@qnDate) = 0 then CjAmount else 0 end )/10000.0 去年认购金额,
    sum(case when datediff(yy,pre.CjDate,@qnDate) = 0 then r.BldArea else 0 end ) 去年认购面积,
	--统计已经转认购部分
	sum(case when datediff(dd,isnull(so.qsdate,sc.qsdate),GetDate()) = 0 then 1 else 0 end ) 本日预认购转认购套数,  
    sum(case when datediff(dd,isnull(so.qsdate,sc.qsdate),GetDate()) = 0 then CjAmount else 0 end )/10000.0 本日预认购转认购金额,  
    sum(case when datediff(dd,isnull(so.qsdate,sc.qsdate),GetDate()) = 0 then r.BldArea else 0 end ) 本日预认购转认购面积, 
	sum(case when isnull(so.qsdate,sc.qsdate) between @本周一 and @本周天 then 1 else 0 end ) 本周预认购转认购套数,  
	sum(case when isnull(so.qsdate,sc.qsdate) between @本周一 and @本周天  then CjAmount else 0 end )/10000.0 本周预认购转认购金额,
	sum(case when isnull(so.qsdate,sc.qsdate) between @本周一 and @本周天  then r.BldArea else 0 end ) 本周预认购转认购面积, 
    sum(case when datediff(mm,isnull(so.qsdate,sc.qsdate),GetDate()) = 0  then 1 else 0 end ) 本月预认购转认购套数,  
    sum(case when datediff(mm,isnull(so.qsdate,sc.qsdate),GetDate()) = 0  then CjAmount else 0 end )/10000.0 本月预认购转认购金额,
    sum(case when datediff(mm,isnull(so.qsdate,sc.qsdate),GetDate()) = 0  then r.BldArea else 0 end ) 本月预认购转认购面积,  
    sum(case when datediff(yy,isnull(so.qsdate,sc.qsdate),GetDate()) = 0  then 1 else 0 end ) 本年预认购转认购套数,  
    sum(case when datediff(yy,isnull(so.qsdate,sc.qsdate),GetDate()) = 0  then CjAmount else 0 end )/10000.0 本年预认购转认购金额,
    sum(case when datediff(yy,isnull(so.qsdate,sc.qsdate),GetDate()) = 0  then r.BldArea else 0 end ) 本年预认购转认购面积,
    sum(case when datediff(yy,isnull(so.qsdate,sc.qsdate),@qnDate) = 0  then 1 else 0 end ) 去年预认购转认购套数,  
    sum(case when datediff(yy,isnull(so.qsdate,sc.qsdate),@qnDate) = 0  then CjAmount else 0 end )/10000.0 去年预认购转认购金额,
    sum(case when datediff(yy,isnull(so.qsdate,sc.qsdate),@qnDate) = 0  then r.BldArea else 0 end ) 去年预认购转认购面积,
	--20221128
    count(1)  累计认购套数,
	sum(CjAmount)/10000.0 累计认购金额,
    sum(r.BldArea ) 累计认购面积 ,
    sum(case when isnull(so.qsdate,sc.qsdate) is not null then 1 else 0 end)/10000.0 累计预认购转认购套数,
	sum(case when isnull(so.qsdate,sc.qsdate) is not null then CjAmount else 0 end)/10000.0 累计预认购转认购金额,
    sum(case when isnull(so.qsdate,sc.qsdate) is not null then r.BldArea else 0 end) 累计预认购转认购面积
    into #pre_order
    from s_PreOrder pre
    inner join ep_room r on pre.RoomGUID = r.RoomGUID
    --踢掉已经转认购签约的预认购
    left join (select so.QSDate,so.RoomGUID from es_Order so 
		left join s_Contract sc on so.TradeGUID = sc.TradeGUID 
		where so.Status = '激活' or (so.CloseReason = '转签约' and sc.Status = '激活')) so	on r.RoomGUID = so.RoomGUID 
    left join es_Contract sc on r.RoomGUID = sc.RoomGUID and sc.Status = '激活'
    where pre.BUGUID in (select value from fn_Split2(@BUGUID,','))
    --and so.OrderGUID is null --and sc.ContractGUID is null 
	and pre.ApproveState='已审核'
    --and datediff(yy,pre.CjDate,GetDate()-1) = 0
       group by r.BldGUID
        

    SELECT sp.BldGUID,
       SUM(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) AS 本年已签约套数,
       SUM(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end) / 10000.0 AS 本年已签约金额,
       SUM(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end)  AS 本年已签约面积,
	   SUM(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) AS 去年已签约套数,
       SUM(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end) / 10000.0 AS 去年已签约金额,
       SUM(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end)  AS 去年已签约面积,
       --20221128
       SUM(ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) ) AS 累计已签约套数,
	   SUM(ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) ) / 10000.0 AS 累计已签约金额,
       SUM(ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0))  AS 累计已签约面积,
       --本日、本周、本月签约金额、面积、套数
       sum(case when DATEDIFF(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end)/ 10000.0 as 本日签约金额,
       sum(case when DATEDIFF(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end) as 本日签约面积,
       sum(case when DATEDIFF(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) as 本日签约套数,
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end)/ 10000.0 as 本周签约金额,
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end) as 本周签约面积,
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) as 本周签约套数,
	   sum(case when DATEDIFF(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end)/ 10000.0 as 本月签约金额,
       sum(case when DATEDIFF(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end) as 本月签约面积,
       sum(case when DATEDIFF(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) as 本月签约套数 ,
       --本日、本周、本月、本年认购金额、面积、套数
       sum(case when datediff(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0) else 0 end ) 本日认购套数,  
       sum(case when datediff(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本日认购金额,  
       sum(case when datediff(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本日认购面积, 
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 本周认购套数,  
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(SpecialCNetAmount, 0)+ ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本周认购金额,  
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本周认购面积,  
       sum(case when datediff(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 本月认购套数,  
       sum(case when datediff(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本月认购金额,
       sum(case when datediff(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本月认购面积,  
       sum(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 本年认购套数,  
       sum(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本年认购金额,
       sum(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本年认购面积,
       sum(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 去年认购套数,  
       sum(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 去年认购金额,
       sum(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 去年认购面积,
       sum(ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)) 累计认购套数,
       sum(ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0))/ 10000.0 累计认购金额,
       sum(ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) ) 累计认购面积  
    INTO #sp
    FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
    GROUP BY sp.BldGUID;

  --获取近三个月的平均签约金额
  --判断项目首次签约时间
  SELECT sp.ParentProjGUID,MIN(ISNULL(sp.StatisticalDate,'2099-12-31')) AS skdate 
  INTO #sk
  FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
  GROUP BY sp.ParentProjGUID
  
  SELECT sp.BldGUID,
  SUM(ISNULL(sp.SpecialCNetAmount,0)+ISNULL(sp.CNetAmount,0))/ 10000.0/(CASE WHEN DATEDIFF(mm,sk.skdate,GETDATE()) in (0,1) THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 2 THEN 2.0
  ELSE 3.0 END)  近三个月平均签约流速,
 SUM(ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,GETDATE()) in (0,1) THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 2 THEN 2.0
  ELSE 3.0 END)  近三个月平均签约流速_面积,
   SUM(ISNULL(sp.SpecialCNetCount,0)+ISNULL(sp.CNetCount,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,GETDATE()) in (0,1) THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 2 THEN 2.0
  ELSE 3.0 END)  近三个月平均签约流速_套数
  INTO #xsls
  FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
  INNER JOIN #sk sk ON sk.ParentProjGUID = sp.ParentProjGUID
  WHERE DATEDIFF(mm,sp.StatisticalDate,GETDATE()) BETWEEN 1 AND 3
  GROUP BY sp.BldGUID,sk.skdate;

  ------------------------获取产品楼栋的情况 end --------------------------------------------

  ------------------------获取产品业态的情况 begin --------------------------------------------
   SELECT pj.ParentProjGUID,
           prd.ProductType,
           SUM(JyTotal) / 10000.0 AS 已认购未签约金额
    INTO #so_yt
    FROM dbo.s_Order so
        INNER JOIN p_room p
            ON p.RoomGUID = so.RoomGUID
        INNER JOIN dbo.mdm_Project pj
            ON pj.ProjGUID = p.ProjGUID
        INNER JOIN dbo.mdm_SaleBuild sb
            ON sb.SaleBldGUID = p.BldGUID
        INNER JOIN dbo.mdm_Product prd
            ON prd.ProductGUID = sb.ProductGUID
    WHERE so.Status = '激活'
          AND so.BUGUID IN (SELECT Value FROM dbo.fn_Split2(@buguid, ','))
    GROUP BY pj.ParentProjGUID,
             prd.ProductType;

    select pj.parentprojguid, ProductType,
    sum(isnull(本日认购套数,0)) 本日认购套数,  
    sum(isnull(本日认购金额,0)) 本日认购金额,  
    sum(isnull(本日认购面积,0)) 本日认购面积, 
    sum(isnull(本周认购套数,0)) 本周认购套数,  
    sum(isnull(本周认购金额,0)) 本周认购金额,  
    sum(isnull(本周认购面积,0)) 本周认购面积,  
    sum(isnull(本月认购套数,0)) 本月认购套数,  
    sum(isnull(本月认购金额,0)) 本月认购金额,
    sum(isnull(本月认购面积,0)) 本月认购面积,  
    sum(isnull(本年认购套数,0)) 本年认购套数,  
    sum(isnull(本年认购金额,0)) 本年认购金额,
    sum(isnull(本年认购面积,0)) 本年认购面积,
    sum(isnull(去年认购套数,0)) 去年认购套数,  
    sum(isnull(去年认购金额,0)) 去年认购金额,
    sum(isnull(去年认购面积,0)) 去年认购面积,
    sum(isnull(累计认购套数,0)) 累计认购套数,
	sum(isnull(累计认购金额,0)) 累计认购金额,
    sum(isnull(累计认购面积,0)) 累计认购面积,
	--预认购转认购
	sum(isnull(本日预认购转认购套数,0)) 本日预认购转认购套数,  
    sum(isnull(本日预认购转认购金额,0)) 本日预认购转认购金额,  
    sum(isnull(本日预认购转认购面积,0)) 本日预认购转认购面积, 
    sum(isnull(本周预认购转认购套数,0)) 本周预认购转认购套数,  
    sum(isnull(本周预认购转认购金额,0)) 本周预认购转认购金额,  
    sum(isnull(本周预认购转认购面积,0)) 本周预认购转认购面积,  
    sum(isnull(本月预认购转认购套数,0)) 本月预认购转认购套数,  
    sum(isnull(本月预认购转认购金额,0)) 本月预认购转认购金额,
    sum(isnull(本月预认购转认购面积,0)) 本月预认购转认购面积,  
    sum(isnull(本年预认购转认购套数,0)) 本年预认购转认购套数,  
    sum(isnull(本年预认购转认购金额,0)) 本年预认购转认购金额,
    sum(isnull(本年预认购转认购面积,0)) 本年预认购转认购面积,
    sum(isnull(去年预认购转认购套数,0)) 去年预认购转认购套数,  
    sum(isnull(去年预认购转认购金额,0)) 去年预认购转认购金额,
    sum(isnull(去年预认购转认购面积,0)) 去年预认购转认购面积,
    sum(isnull(累计预认购转认购套数,0)) 累计预认购转认购套数,
	sum(isnull(累计预认购转认购金额,0)) 累计预认购转认购金额,
    sum(isnull(累计预认购转认购面积,0)) 累计预认购转认购面积
       into #pre_order_yt
    from #pre_order pre
    inner join mdm_SaleBuild sb on pre.BldGUID = sb.SaleBldGUID 
       inner join mdm_GCBuild gc on sb.GCBldGUID = gc.GCBldGUID 
    inner join mdm_Product pr on pr.ProductGUID = sb.ProductGUID         
    inner join mdm_Project pj on pj.ProjGUID = gc.ProjGUID
    group by pj.parentprojguid, ProductType

    SELECT sp.ParentProjGUID,
       sp.TopProductTypeName,
       SUM(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end)  AS 本年已签约套数,
       SUM(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end) / 10000.0 AS 本年已签约金额,
       SUM(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetarea, 0) + ISNULL(sp.SpecialCNetarea, 0)else 0 end)  AS 本年已签约面积,
	   SUM(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end)  AS 去年已签约套数,
       SUM(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end) / 10000.0 AS 去年已签约金额,
       SUM(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(sp.CNetarea, 0) + ISNULL(sp.SpecialCNetarea, 0)else 0 end)  AS 去年已签约面积,
	   SUM(ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetcount, 0))  AS 累计已签约套数,
       SUM(ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 10000.0 AS 累计已签约金额,
       SUM(ISNULL(sp.CNetarea, 0) + ISNULL(sp.SpecialCNetarea, 0))  AS 累计已签约面积,
       --本日、本周、本月签约金额、面积、套数
       sum(case when DATEDIFF(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end)/ 10000.0 as 本日签约金额,
       sum(case when DATEDIFF(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end) as 本日签约面积,
       sum(case when DATEDIFF(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) as 本日签约套数,
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end)/ 10000.0 as 本周签约金额,
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end) as 本周签约面积,
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) as 本周签约套数,
       sum(case when DATEDIFF(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) else 0 end)/ 10000.0 as 本月签约金额,
       sum(case when DATEDIFF(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetArea, 0) + ISNULL(sp.SpecialCNetArea, 0) else 0 end) as 本月签约面积,
       sum(case when DATEDIFF(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(sp.CNetCount, 0) + ISNULL(sp.SpecialCNetCount, 0) else 0 end) as 本月签约套数, 
       --认购
       --本日、本周、本月、本年认购金额、面积、套数
       sum(case when datediff(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0) else 0 end ) 本日认购套数,  
       sum(case when datediff(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本日认购金额,  
       sum(case when datediff(dd,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本日认购面积, 
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 本周认购套数,  
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(SpecialCNetAmount, 0)+ ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本周认购金额,  
       sum(case when sp.StatisticalDate between @本周一 and @本周天  then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本周认购面积,  
       sum(case when datediff(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 本月认购套数,  
       sum(case when datediff(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本月认购金额,
       sum(case when datediff(mm,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本月认购面积,  
       sum(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 本年认购套数,  
       sum(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 本年认购金额,
       sum(case when datediff(yy,sp.StatisticalDate,GetDate()) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 本年认购面积,
       sum(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  else 0 end ) 去年认购套数,  
       sum(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0) else 0 end )/ 10000.0 去年认购金额,
       sum(case when datediff(yy,sp.StatisticalDate,@qnDate) = 0 then ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) else 0 end ) 去年认购面积,
       sum(ISNULL(SpecialCNetCount, 0) + ISNULL(ONetCount, 0)  ) 累计认购套数,
       sum(ISNULL(SpecialCNetAmount, 0) + ISNULL(ONetAmount, 0)  )/ 10000.0 累计认购金额,
       sum(ISNULL(SpecialCNetArea, 0) + ISNULL(ONetArea, 0) ) 累计认购面积	   
    INTO #sp_yt
    FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
    --WHERE sp.StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31' or datediff(yy,sp.StatisticalDate,GetDate()-1) = 0
    GROUP BY sp.ParentProjGUID,
             sp.TopProductTypeName;

    SELECT f.ProjGUID,
           f.ProductType,
           SUM(f.累计待收款) AS 累计待收款,
           SUM(f.累计非正签待收款) AS 累计非正签待收款,
           SUM(f.累计未正签按揭待收款) AS 累计未正签按揭待收款,
           SUM(f.累计未正签非按揭待收款) AS 累计未正签非按揭待收款,
           SUM(f.累计未正签非按揭待收款本月到期) AS 累计未正签非按揭待收款本月到期,
           SUM(f.累计未正签非按揭待收款下月到期) AS 累计未正签非按揭待收款下月到期,
           SUM(f.累计正签待收款) AS 累计正签待收款,
           SUM(f.正签非按揭待收款) AS 正签非按揭待收款,
           SUM(f.正签非按揭待收款本月到期) AS 正签非按揭待收款本月到期,
           SUM(f.正签非按揭待收款下月到期) AS 正签非按揭待收款下月到期,
           SUM(f.正签公积金贷款本月到期) AS 正签公积金贷款本月到期,
           SUM(f.正签公积金贷款待收款) AS 正签公积金贷款待收款,
           SUM(f.正签公积金贷款下月到期) AS 正签公积金贷款下月到期,
           SUM(f.正签商业贷款待收款) AS 正签商业贷款待收款,
           SUM(f.正签商业贷款待收款本月到期) AS 正签商业贷款待收款本月到期,
           SUM(f.正签商业贷款待收款下月到期) AS 正签商业贷款待收款下月到期
    INTO #f_yt
    FROM #s_fee f
    GROUP BY f.ProductType,
             f.ProjGUID;

  SELECT sp.parentprojguid AS projguid,sp.TopProductTypeName AS ProductType,
  SUM(ISNULL(sp.SpecialCNetAmount,0)+ISNULL(sp.CNetAmount,0))/ 10000.0/(CASE WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 1 THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 2 THEN 2.0
  ELSE 3.0 END)  近三个月平均签约流速,
   SUM(ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 1 THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 2 THEN 2.0
  ELSE 3.0 END)  近三个月平均签约流速_面积,
  SUM(ISNULL(sp.SpecialCNetCount,0)+ISNULL(sp.CNetCount,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,GETDATE()) in (0,1) THEN 1.0
  WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 2 THEN 2.0
  ELSE 3.0 END)  近三个月平均签约流速_套数
  INTO #xsls_yt
  FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
  INNER JOIN #sk sk ON sk.ParentProjGUID = sp.ParentProjGUID
    WHERE DATEDIFF(mm,sp.StatisticalDate,GETDATE()) BETWEEN 1 AND 3
  GROUP BY sp.parentprojguid,sp.TopProductTypeName,sk.skdate;

  ------------------------获取产品业态的情况 end --------------------------------------------
        
    IF EXISTS
    (
        SELECT *
        FROM dbo.sysobjects
        WHERE id = OBJECT_ID(N'ydkb_dthz_wq_deal_tradeinfo')
              AND OBJECTPROPERTY(id, 'IsTable') = 1
    )
    BEGIN
        DROP TABLE ydkb_dthz_wq_deal_tradeinfo;
    END;


    --湾区PC端货量报表

    CREATE TABLE ydkb_dthz_wq_deal_tradeinfo
    (
        组织架构父级ID UNIQUEIDENTIFIER,
        组织架构ID UNIQUEIDENTIFIER,
        组织架构名称 VARCHAR(400),
        组织架构编码 [VARCHAR](100),
        组织架构类型 [INT],
        本月认购任务 money,
        本年认购任务 money,
        去年认购任务 money,
        本月签约任务 money,
        本年签约任务 money,
        去年签约任务 money,
        明年签约任务 money,
        /*待收款情况*/
        累计待收款 MONEY,
                          --非正签
        累计未正签待收款 MONEY,
        累计未正签非按揭待收款 MONEY,
        累计未正签非按揭待收款本月到期 MONEY,
        累计未正签非按揭待收款本月完成 MONEY,
        累计未正签非按揭待收款下月到期 MONEY,
        累计未正签按揭待收款 MONEY,
                          --正签
        累计正签待收款 MONEY,    -- 正签非按揭待收款 A  + 正签商业贷款待收款 B + 正签公积金贷款待收款 C
        正签非按揭待收款 MONEY,   -- A
        正签非按揭待收款本月到期 MONEY,
        正签非按揭待收款本月完成 MONEY,
        正签非按揭待收款下月到期 MONEY,
        正签商业贷款待收款 MONEY,  --B
        正签商业贷款待收款本月到期 MONEY,
        正签商业贷款待收款本月完成 MONEY,
        正签商业贷款待收款下月到期 MONEY,
        正签公积金贷款待收款 MONEY, --C
        正签公积金贷款本月到期 MONEY,
        正签公积金贷款本月完成 MONEY,
        正签公积金贷款下月到期 MONEY,
                          --1-12月份销售情况
        Jan认购金额 MONEY,
        Feb认购金额 MONEY,
        Mar认购金额 MONEY,
        Apr认购金额 MONEY,
        May认购金额 MONEY,
        Jun认购金额 MONEY,
        July认购金额 MONEY,
        Aug认购金额 MONEY,
        Sep认购金额 MONEY,
        Oct认购金额 MONEY,
        Nov认购金额 MONEY,
        Dec认购金额 MONEY,
        Jan签约金额 MONEY,
        Feb签约金额 MONEY,
        Mar签约金额 MONEY,
        Apr签约金额 MONEY,
        May签约金额 MONEY,
        Jun签约金额 MONEY,
        July签约金额 MONEY,
        Aug签约金额 MONEY,
        Sep签约金额 MONEY,
        Oct签约金额 MONEY,
        Nov签约金额 MONEY,
        Dec签约金额 MONEY,
        本年已签约套数 int,
        本年已签约金额 MONEY,
        本年已签约面积 MONEY,
        去年已签约套数 int,
        去年已签约金额 MONEY,
        去年已签约面积 MONEY,
		--20221128
        累计已签约套数 int,
		累计已签约金额 MONEY,
        累计已签约面积 MONEY,
        已认购未签约金额 MONEY,
        近三个月平均签约流速 MONEY,
        近三个月平均签约流速_面积 MONEY,
        近三个月平均签约流速_套数 money,

        --退房
        今日退房套数 int,  
        今日退房金额 MONEY,  
        今日退房面积 MONEY,  
        本周退房套数 int,  
        本周退房金额 MONEY,   
        本周退房面积 MONEY,  
        本月退房套数 int,   
        本月退房金额 MONEY,  
        本月退房面积 MONEY,   
        本年退房套数 int,   
        本年退房金额 MONEY,
        本年退房面积 MONEY,  
        --本日、本周、本月签约金额、面积、套数、均价
        本日签约金额 MONEY,  
        本日签约面积 MONEY,  
        本日签约套数 int,  
        本日签约均价 MONEY,   
        本周签约金额 MONEY,  
        本周签约面积 MONEY,  
        本周签约套数 int,  
        本周签约均价 MONEY,   
        本月签约金额 MONEY,  
        本月签约面积 MONEY,  
        本月签约套数 int,  
        本月签约均价 MONEY, 
        --本日、本周、本月、本年认购金额、面积、套数、均价
        本日认购金额 MONEY,  
        本日认购面积 MONEY,  
        本日认购套数 int,  
        本日认购均价 MONEY,   
        本周认购金额 MONEY,  
        本周认购面积 MONEY,  
        本周认购套数 int,  
        本周认购均价 MONEY,   
        本月认购金额 MONEY,  
        本月认购面积 MONEY,  
        本月认购套数 int,  
        本月认购均价 MONEY, 
        本年认购金额 MONEY,  
        本年认购面积 MONEY, 
        本年认购套数 int, 
        去年认购金额 MONEY,  
        去年认购面积 MONEY, 
        去年认购套数 int, 
        累计认购套数 int,  
        累计认购金额 MONEY,  
        累计认购面积 MONEY,		
        本年认购均价 MONEY,
        去年认购均价 MONEY,
		累计认购均价 MONEY
    );
   
    INSERT INTO ydkb_dthz_wq_deal_tradeinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        累计待收款,
        累计未正签待收款,
        累计未正签按揭待收款,
        累计未正签非按揭待收款,
        累计未正签非按揭待收款本月到期,
        累计未正签非按揭待收款本月完成,
        累计未正签非按揭待收款下月到期,
        累计正签待收款,
        正签非按揭待收款,   -- A
        正签非按揭待收款本月到期,
        正签非按揭待收款本月完成,
        正签非按揭待收款下月到期,
        正签商业贷款待收款,  --B
        正签商业贷款待收款本月到期,
        正签商业贷款待收款本月完成,
        正签商业贷款待收款下月到期,
        正签公积金贷款待收款, --C
        正签公积金贷款本月到期,
        正签公积金贷款本月完成,
        正签公积金贷款下月到期,
        Jan认购金额,
        Feb认购金额,
        Mar认购金额,
        Apr认购金额,
        May认购金额,
        Jun认购金额,
        July认购金额,
        Aug认购金额,
        Sep认购金额,
        Oct认购金额,
        Nov认购金额,
        Dec认购金额,
        Jan签约金额,
        Feb签约金额,
        Mar签约金额,
        Apr签约金额,
        May签约金额,
        Jun签约金额,
        July签约金额,
        Aug签约金额,
        Sep签约金额,
        Oct签约金额,
        Nov签约金额,
        Dec签约金额,
        本年已签约套数,
        本年已签约金额,
        本年已签约面积,
        去年已签约套数,
        去年已签约金额,
        去年已签约面积,
        累计已签约套数,
		累计已签约金额,
        累计已签约面积,
        已认购未签约金额,
        近三个月平均签约流速, 
        近三个月平均签约流速_面积,
        近三个月平均签约流速_套数,
        --退房
        今日退房套数,  
        今日退房金额,  
        今日退房面积,  
        本周退房套数,  
        本周退房金额,   
        本周退房面积,  
        本月退房套数,   
        本月退房金额,  
        本月退房面积,   
        本年退房套数,   
        本年退房金额,
        本年退房面积,  
        --本日、本周、本月签约金额、面积、套数、均价
        本日签约金额 ,  
        本日签约面积 ,  
        本日签约套数 ,  
        本日签约均价 ,   
        本周签约金额 ,  
        本周签约面积 ,  
        本周签约套数 ,  
        本周签约均价 ,   
        本月签约金额 ,  
        本月签约面积 ,  
        本月签约套数 ,  
        本月签约均价 ,
        --本日、本周、本月、本年认购金额、面积、套数、均价
        本日认购金额 ,  
        本日认购面积 ,  
        本日认购套数 ,  
        本日认购均价 ,   
        本周认购金额 ,  
        本周认购面积 ,  
        本周认购套数 ,  
        本周认购均价 ,   
        本月认购金额 ,  
        本月认购面积 ,  
        本月认购套数 ,  
        本月认购均价 , 
        本年认购金额 ,  
        本年认购面积 ,  
        本年认购套数 ,
        去年认购金额 ,
        去年认购面积 ,
        去年认购套数 ,
        累计认购套数 ,  
        累计认购金额 ,  
        累计认购面积 ,  		
        本年认购均价 ,
        去年认购均价 ,
		累计认购均价 

    )
    SELECT gc.GCBldGUID 组织架构父级ID,
           bi.组织架构ID,
           bi.组织架构名称,
           bi.组织架构编码,
           6 组织架构类型,
           f.累计待收款,
           f.累计非正签待收款,
           f.累计未正签按揭待收款,
           f.累计未正签非按揭待收款,
           f.累计未正签非按揭待收款本月到期,
           g.累计未正签非按揭待收款本月完成,
           f.累计未正签非按揭待收款下月到期,
           f.累计正签待收款,
           f.正签非按揭待收款,   -- A
           f.正签非按揭待收款本月到期,
           g.正签非按揭待收款本月完成,
           f.正签非按揭待收款下月到期,
           f.正签商业贷款待收款,  --B
           f.正签商业贷款待收款本月到期,
           g.正签商业贷款待收款本月完成,
           f.正签商业贷款待收款下月到期,
           f.正签公积金贷款待收款, --C
           f.正签公积金贷款本月到期,
           g.正签公积金贷款本月完成,
           f.正签公积金贷款下月到期,
           ld.Jan认购金额,
           ld.Feb认购金额,
           ld.Mar认购金额,
           ld.Apr认购金额,
           ld.May认购金额,
           ld.Jun认购金额,
           ld.Jul认购金额 AS July认购金额,
           ld.Aug认购金额,
           ld.Sep认购金额,
           ld.Oct认购金额,
           ld.Nov认购金额,
           ld.Dec认购金额,
           ld.Jan签约金额,
           ld.Feb签约金额,
           ld.Mar签约金额,
           ld.Apr签约金额,
           ld.May签约金额,
           ld.Jun签约金额,
           ld.Jul签约金额 AS July签约金额,
           ld.Aug签约金额,
           ld.Sep签约金额,
           ld.Oct签约金额,
           ld.Nov签约金额,
           ld.Dec签约金额,
           sp.本年已签约套数,
           sp.本年已签约金额,
           sp.本年已签约面积,
           sp.去年已签约套数,
           sp.去年已签约金额,
           sp.去年已签约面积,
           sp.累计已签约套数,
		   sp.累计已签约金额,
           sp.累计已签约面积,
           so.已认购未签约金额,
           近三个月平均签约流速,
           近三个月平均签约流速_面积,
           近三个月平均签约流速_套数,
           tf.今日退房套数,  
           tf.今日退房金额,  
           tf.今日退房面积,  
           tf.本周退房套数,  
           tf.本周退房金额,   
           tf.本周退房面积,  
           tf.本月退房套数,   
           tf.本月退房金额,  
           tf.本月退房面积,   
           tf.本年退房套数,   
           tf.本年退房金额,
           tf.本年退房面积,  
           isnull(sp.本日签约金额,0) as 本日签约金额 ,  
           isnull(sp.本日签约面积,0) as 本日签约面积 ,  
           isnull(sp.本日签约套数,0) as 本日签约套数 ,  
           case when isnull(sp.本日签约面积,0) = 0 then 0 else isnull(sp.本日签约金额,0)*10000.0/isnull(sp.本日签约面积,0) end 本日签约均价 ,   
           isnull(sp.本周签约金额,0) as 本周签约金额 ,  
           isnull(sp.本周签约面积,0) as 本周签约面积 ,  
           isnull(sp.本周签约套数,0) as 本周签约套数 ,  
           case when isnull(sp.本周签约面积,0) = 0 then 0 else isnull(sp.本周签约金额,0)*10000.0/isnull(sp.本周签约面积,0) end 本周签约均价 ,   
           isnull(sp.本月签约金额,0) as 本月签约金额 ,  
           isnull(sp.本月签约面积,0) as 本月签约面积 ,  
           isnull(sp.本月签约套数,0) as 本月签约套数 ,  
           case when isnull(sp.本月签约面积,0) = 0 then 0 else isnull(sp.本月签约金额,0)*10000.0/isnull(sp.本月签约面积,0) end 本月签约均价,
           --认购
           isnull(sp.本日认购金额,0)+isnull(preorder.本日认购金额,0)-isnull(preorder.本日预认购转认购金额,0) as 本日认购金额 ,  
           isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0) as 本日认购面积 ,  
           isnull(sp.本日认购套数,0)+isnull(preorder.本日认购套数,0)-isnull(preorder.本日预认购转认购套数,0) as 本日认购套数 ,  
           case when isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0) = 0 then 0 else (isnull(sp.本日认购金额,0)+isnull(preorder.本日认购金额,0)-isnull(preorder.本日预认购转认购金额,0))*10000.0/(isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0)) end 本日认购均价 ,   
           isnull(sp.本周认购金额,0)+isnull(preorder.本周认购金额,0)-isnull(preorder.本周预认购转认购金额,0) as 本周认购金额 ,  
           isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0) as 本周认购面积 ,  
           isnull(sp.本周认购套数,0)+isnull(preorder.本周认购套数,0)-isnull(preorder.本周预认购转认购套数,0) as 本周认购套数 ,  
           case when isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0) = 0 then 0 else (isnull(sp.本周认购金额,0)+isnull(preorder.本周认购金额,0)-isnull(preorder.本周预认购转认购金额,0))*10000.0/(isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0)) end 本周认购均价 ,   
           isnull(sp.本月认购金额,0)+isnull(preorder.本月认购金额,0)-isnull(preorder.本月预认购转认购金额,0)  as 本月认购金额 ,  
           isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0)  as 本月认购面积 ,  
           isnull(sp.本月认购套数,0)+isnull(preorder.本月认购套数,0)-isnull(preorder.本月预认购转认购套数,0)  as 本月认购套数 ,  
           case when isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0) = 0 then 0 else (isnull(sp.本月认购金额,0)+isnull(preorder.本月认购金额,0)-isnull(preorder.本月预认购转认购金额,0))*10000.0/(isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0)) end 本月认购均价 ,   
           isnull(sp.本年认购金额,0)+isnull(preorder.本年认购金额,0)-isnull(preorder.本年预认购转认购金额,0) as 本年认购金额 ,  
           isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0) as 本年认购面积 ,  
           isnull(sp.本年认购套数,0)+isnull(preorder.本年认购套数,0)-isnull(preorder.本年预认购转认购套数,0) as 本年认购套数 , 
           isnull(sp.去年认购金额,0)+isnull(preorder.去年认购金额,0)-isnull(preorder.去年预认购转认购金额,0) as 去年认购金额 ,  
           isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0) as 去年认购面积 ,  
           isnull(sp.去年认购套数,0)+isnull(preorder.去年认购套数,0)-isnull(preorder.去年预认购转认购套数,0) as 去年认购套数 , 
           isnull(sp.累计认购套数,0)+isnull(preorder.累计认购套数,0)-isnull(preorder.累计预认购转认购套数,0) as 累计认购套数 , 
           isnull(sp.累计认购金额,0)+isnull(preorder.累计认购金额,0)-isnull(preorder.累计预认购转认购金额,0) as 累计认购金额 ,  
           isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0) as 累计认购面积 ,  		   
           case when isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0) = 0 then 0 else (isnull(sp.本年认购金额,0)+isnull(preorder.本年认购金额,0)-isnull(preorder.本年预认购转认购金额,0))*10000.0/(isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0)) end 本年认购均价 ,
		   case when isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0) = 0 then 0 else (isnull(sp.去年认购金额,0)+isnull(preorder.去年认购金额,0)-isnull(preorder.去年预认购转认购金额,0))*10000.0/(isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0)) end 去年认购均价 ,
           case when isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0) = 0 then 0 else (isnull(sp.累计认购金额,0)+isnull(preorder.累计认购金额,0)-isnull(preorder.累计预认购转认购金额,0))*10000.0/(isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0)) end 累计认购均价 

    FROM ydkb_BaseInfo bi
        INNER JOIN #ldhz ld
            ON ld.组织架构ID = bi.组织架构ID
        LEFT JOIN #s_getin g
            ON g.BldGUID = ld.组织架构ID
        LEFT JOIN #s_fee f
            ON f.BldGUID = ld.组织架构ID
        LEFT JOIN #sp sp
            ON sp.BldGUID = bi.组织架构ID
        LEFT JOIN #pre_order preorder
            ON preorder.BldGUID = bi.组织架构ID
        LEFT JOIN #so so
            ON bi.组织架构ID = so.BldGUID
        INNER JOIN mdm_SaleBuild sb
            ON bi.组织架构ID = sb.SaleBldGUID
        INNER JOIN mdm_GCBuild gc
            ON sb.GCBldGUID = gc.GCBldGUID
        left JOIN #xsls xsls ON xsls.BldGUID = bi.组织架构ID
        LEFT JOIN #tfinfo tf on tf.BldGUID= bi.组织架构ID
    WHERE bi.组织架构类型 = 5;

    --插入工程楼栋的值
    INSERT INTO ydkb_dthz_wq_deal_tradeinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        累计待收款,
        累计未正签待收款,
        累计未正签按揭待收款,
        累计未正签非按揭待收款,
        累计未正签非按揭待收款本月到期,
        累计未正签非按揭待收款本月完成,
        累计未正签非按揭待收款下月到期,
        累计正签待收款,
        正签非按揭待收款,   -- A
        正签非按揭待收款本月到期,
        正签非按揭待收款本月完成,
        正签非按揭待收款下月到期,
        正签商业贷款待收款,  --B
        正签商业贷款待收款本月到期,
        正签商业贷款待收款本月完成,
        正签商业贷款待收款下月到期,
        正签公积金贷款待收款, --C
        正签公积金贷款本月到期,
        正签公积金贷款本月完成,
        正签公积金贷款下月到期,
        Jan认购金额,
        Feb认购金额,
        Mar认购金额,
        Apr认购金额,
        May认购金额,
        Jun认购金额,
        July认购金额,
        Aug认购金额,
        Sep认购金额,
        Oct认购金额,
        Nov认购金额,
        Dec认购金额,
        Jan签约金额,
        Feb签约金额,
        Mar签约金额,
        Apr签约金额,
        May签约金额,
        Jun签约金额,
        July签约金额,
        Aug签约金额,
        Sep签约金额,
        Oct签约金额,
        Nov签约金额,
        Dec签约金额,
        本年已签约套数,
        本年已签约金额,
        本年已签约面积,
        去年已签约套数,
        去年已签约金额,
        去年已签约面积,
        累计已签约套数,
		累计已签约金额,
        累计已签约面积,
        已认购未签约金额,
        近三个月平均签约流速,
        近三个月平均签约流速_面积,
        近三个月平均签约流速_套数,
        --退房
        今日退房套数,  
        今日退房金额,  
        今日退房面积,  
        本周退房套数,  
        本周退房金额,   
        本周退房面积,  
        本月退房套数,   
        本月退房金额,  
        本月退房面积,   
        本年退房套数,   
        本年退房金额,
        本年退房面积,  
        --本日、本周、本月签约金额、面积、套数、均价
        本日签约金额 ,  
        本日签约面积 ,  
        本日签约套数 ,  
        本日签约均价 ,   
        本周签约金额 ,  
        本周签约面积 ,  
        本周签约套数 ,  
        本周签约均价 ,   
        本月签约金额 ,  
        本月签约面积 ,  
        本月签约套数 ,  
        本月签约均价 ,
        --本日、本周、本月、本年认购金额、面积、套数、均价
        本日认购金额 ,  
        本日认购面积 ,  
        本日认购套数 ,  
        本日认购均价 ,   
        本周认购金额 ,  
        本周认购面积 ,  
        本周认购套数 ,  
        本周认购均价 ,   
        本月认购金额 ,  
        本月认购面积 ,  
        本月认购套数 ,  
        本月认购均价 , 
        本年认购金额 ,  
        本年认购面积 ,  
        本年认购套数 , 
        去年认购金额 ,  
        去年认购面积 ,  
        去年认购套数 , 
        累计认购套数 ,  
        累计认购金额 ,  
        累计认购面积 ,		
        本年认购均价 ,
        去年认购均价 ,
		累计认购均价
    )
    SELECT bi.组织架构父级ID,
           gc.GCBldGUID 组织架构ID,
           gc.BldName 组织架构名称,
           bi2.组织架构编码 组织架构编码,
           5 组织架构类型,
           SUM(ISNULL(f.累计待收款, 0)) 累计待收款,
           SUM(ISNULL(f.累计非正签待收款, 0)) 累计非正签待收款,
           SUM(ISNULL(f.累计未正签按揭待收款, 0)) 累计未正签按揭待收款,
           SUM(ISNULL(f.累计未正签非按揭待收款, 0)) 累计未正签非按揭待收款,
           SUM(ISNULL(f.累计未正签非按揭待收款本月到期, 0)) 累计未正签非按揭待收款本月到期,
           SUM(ISNULL(g.累计未正签非按揭待收款本月完成, 0)) 累计未正签非按揭待收款本月完成,
           SUM(ISNULL(f.累计未正签非按揭待收款下月到期, 0)) 累计未正签非按揭待收款下月到期,
           SUM(ISNULL(f.累计正签待收款, 0)) 累计正签待收款,
           SUM(ISNULL(f.正签非按揭待收款, 0)) 正签非按揭待收款,     -- A
           SUM(ISNULL(f.正签非按揭待收款本月到期, 0)) 正签非按揭待收款本月到期,
           SUM(ISNULL(g.正签非按揭待收款本月完成, 0)) 正签非按揭待收款本月完成,
           SUM(ISNULL(f.正签非按揭待收款下月到期, 0)) 正签非按揭待收款下月到期,
           SUM(ISNULL(f.正签商业贷款待收款, 0)) 正签商业贷款待收款,   --B
           SUM(ISNULL(f.正签商业贷款待收款本月到期, 0)) 正签商业贷款待收款本月到期,
           SUM(ISNULL(g.正签商业贷款待收款本月完成, 0)) 正签商业贷款待收款本月完成,
           SUM(ISNULL(f.正签商业贷款待收款下月到期, 0)) 正签商业贷款待收款下月到期,
           SUM(ISNULL(f.正签公积金贷款待收款, 0)) 正签公积金贷款待收款, --C
           SUM(ISNULL(f.正签公积金贷款本月到期, 0)) 正签公积金贷款本月到期,
           SUM(ISNULL(g.正签公积金贷款本月完成, 0)) 正签公积金贷款本月完成,
           SUM(ISNULL(f.正签公积金贷款下月到期, 0)) 正签公积金贷款下月到期,
           SUM(ISNULL(ld.Jan认购金额, 0)) Jan认购金额,
           SUM(ISNULL(ld.Feb认购金额, 0)) Feb认购金额,
           SUM(ISNULL(ld.Mar认购金额, 0)) Mar认购金额,
           SUM(ISNULL(ld.Apr认购金额, 0)) Apr认购金额,
           SUM(ISNULL(ld.May认购金额, 0)) May认购金额,
           SUM(ISNULL(ld.Jun认购金额, 0)) Jun认购金额,
           SUM(ISNULL(ld.Jul认购金额, 0)) Jul认购金额,
           SUM(ISNULL(ld.Aug认购金额, 0)) Aug认购金额,
           SUM(ISNULL(ld.Sep认购金额, 0)) Sep认购金额,
           SUM(ISNULL(ld.Oct认购金额, 0)) Oct认购金额,
           SUM(ISNULL(ld.Nov认购金额, 0)) Nov认购金额,
           SUM(ISNULL(ld.Dec认购金额, 0)) Dec认购金额,
           SUM(ISNULL(ld.Jan签约金额, 0)) Jan签约金额,
           SUM(ISNULL(ld.Feb签约金额, 0)) Feb签约金额,
           SUM(ISNULL(ld.Mar签约金额, 0)) Mar签约金额,
           SUM(ISNULL(ld.Apr签约金额, 0)) Apr签约金额,
           SUM(ISNULL(ld.May签约金额, 0)) May签约金额,
           SUM(ISNULL(ld.Jun签约金额, 0)) Jun签约金额,
           SUM(ISNULL(ld.Jul签约金额, 0)) AS July签约金额,
           SUM(ISNULL(ld.Aug签约金额, 0)) Aug签约金额,
           SUM(ISNULL(ld.Sep签约金额, 0)) Sep签约金额,
           SUM(ISNULL(ld.Oct签约金额, 0)) Oct签约金额,
           SUM(ISNULL(ld.Nov签约金额, 0)) Nov签约金额,
           SUM(ISNULL(ld.Dec签约金额, 0)) Dec签约金额,
           SUM(ISNULL(sp.本年已签约套数, 0)) AS 本年已签约套数,
           SUM(ISNULL(sp.本年已签约金额, 0)) AS 本年已签约金额,
           SUM(ISNULL(sp.本年已签约面积, 0)) AS 本年已签约面积,
           SUM(ISNULL(sp.去年已签约套数, 0)) AS 去年已签约套数,
           SUM(ISNULL(sp.去年已签约金额, 0)) AS 去年已签约金额,
           SUM(ISNULL(sp.去年已签约面积, 0)) AS 去年已签约面积,
           SUM(ISNULL(sp.累计已签约套数, 0)) AS 累计已签约套数,
		   SUM(ISNULL(sp.累计已签约金额, 0)) AS 累计已签约金额,
           SUM(ISNULL(sp.累计已签约面积, 0)) AS 累计已签约面积,
           SUM(ISNULL(so.已认购未签约金额, 0)) AS 已认购未签约金额,
           SUM(ISNULL(近三个月平均签约流速,0)) AS 近三个月平均签约流速,
           SUM(ISNULL(近三个月平均签约流速_面积,0)) AS 近三个月平均签约流速_面积,
           SUM(ISNULL(近三个月平均签约流速_套数,0)) AS 近三个月平均签约流速_套数,
           SUM(isnull(今日退房套数,0)) AS 今日退房套数,
           SUM(isnull(今日退房金额,0)) AS 今日退房金额,
           SUM(isnull(今日退房面积,0)) AS 今日退房面积,
           SUM(isnull(本周退房套数,0)) AS 本周退房套数,
           SUM(isnull(本周退房金额,0)) AS 本周退房金额,
           SUM(isnull(本周退房面积,0)) AS 本周退房面积,
           SUM(isnull(本月退房套数,0)) AS 本月退房套数,
           SUM(isnull(本月退房金额,0)) AS 本月退房金额,
           SUM(isnull(本月退房面积,0)) AS 本月退房面积,
           SUM(isnull(本年退房套数,0)) AS 本年退房套数,
           SUM(isnull(本年退房金额,0)) AS 本年退房金额,
           SUM(isnull(本年退房面积,0)) AS 本年退房面积,
           sum(isnull(sp.本日签约金额,0)) as 本日签约金额 ,  
           sum(isnull(sp.本日签约面积,0)) as 本日签约面积 ,  
           sum(isnull(sp.本日签约套数,0)) as 本日签约套数 ,  
           case when sum(isnull(sp.本日签约面积,0)) = 0 then 0 else sum(isnull(sp.本日签约金额,0))*10000.0/sum(isnull(sp.本日签约面积,0)) end 本日签约均价 ,   
           sum(isnull(sp.本周签约金额,0)) as 本周签约金额 ,  
           sum(isnull(sp.本周签约面积,0)) as 本周签约面积 ,  
           sum(isnull(sp.本周签约套数,0)) as 本周签约套数 ,  
           case when sum(isnull(sp.本周签约面积,0)) = 0 then 0 else sum(isnull(sp.本周签约金额,0))*10000.0/sum(isnull(sp.本周签约面积,0)) end 本周签约均价 ,   
           sum(isnull(sp.本月签约金额,0)) as 本月签约金额 ,  
           sum(isnull(sp.本月签约面积,0)) as 本月签约面积 ,  
           sum(isnull(sp.本月签约套数,0)) as 本月签约套数 ,  
           case when sum(isnull(sp.本月签约面积,0)) = 0 then 0 else sum(isnull(sp.本月签约金额,0))*10000.0/sum(isnull(sp.本月签约面积,0)) end 本月签约均价,
            --认购
		   sum(isnull(sp.本日认购金额,0)+isnull(preorder.本日认购金额,0)-isnull(preorder.本日预认购转认购金额,0)) as 本日认购金额 ,  
           sum(isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0)) as 本日认购面积 ,  
           sum(isnull(sp.本日认购套数,0)+isnull(preorder.本日认购套数,0)-isnull(preorder.本日预认购转认购套数,0)) as 本日认购套数 ,  
           case when sum(isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本日认购金额,0)+isnull(preorder.本日认购金额,0)-isnull(preorder.本日预认购转认购金额,0))*10000.0/sum(isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0)) end 本日认购均价 ,   
           sum(isnull(sp.本周认购金额,0)+isnull(preorder.本周认购金额,0)-isnull(preorder.本周预认购转认购金额,0)) as 本周认购金额 ,  
           sum(isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0)) as 本周认购面积 ,  
           sum(isnull(sp.本周认购套数,0)+isnull(preorder.本周认购套数,0)-isnull(preorder.本周预认购转认购套数,0)) as 本周认购套数 ,  
           case when sum(isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本周认购金额,0)+isnull(preorder.本周认购金额,0)-isnull(preorder.本周预认购转认购金额,0))*10000.0/sum(isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0)) end 本周认购均价 ,   
           sum(isnull(sp.本月认购金额,0)+isnull(preorder.本月认购金额,0)-isnull(preorder.本月预认购转认购金额,0))  as 本月认购金额 ,  
           sum(isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0))  as 本月认购面积 ,  
           sum(isnull(sp.本月认购套数,0)+isnull(preorder.本月认购套数,0)-isnull(preorder.本月预认购转认购套数,0))  as 本月认购套数 ,  
           case when sum(isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本月认购金额,0)+isnull(preorder.本月认购金额,0)-isnull(preorder.本月预认购转认购金额,0))*10000.0/sum(isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0)) end 本月认购均价 ,   
           sum(isnull(sp.本年认购金额,0)+isnull(preorder.本年认购金额,0)-isnull(preorder.本年预认购转认购金额,0)) as 本年认购金额 ,  
           sum(isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0)) as 本年认购面积 ,  
           sum(isnull(sp.本年认购套数,0)+isnull(preorder.本年认购套数,0)-isnull(preorder.本年预认购转认购套数,0)) as 本年认购套数 , 
           sum(isnull(sp.去年认购金额,0)+isnull(preorder.去年认购金额,0)-isnull(preorder.去年预认购转认购金额,0)) as 去年认购金额 ,  
           sum(isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0)) as 去年认购面积 ,  
           sum(isnull(sp.去年认购套数,0)+isnull(preorder.去年认购套数,0)-isnull(preorder.去年预认购转认购套数,0)) as 去年认购套数 , 
           sum(isnull(sp.累计认购套数,0)+isnull(preorder.累计认购套数,0)-isnull(preorder.累计预认购转认购套数,0)) as 累计认购套数 , 
           sum(isnull(sp.累计认购金额,0)+isnull(preorder.累计认购金额,0)-isnull(preorder.累计预认购转认购金额,0)) as 累计认购金额 ,  
           sum(isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0)) as 累计认购面积 ,  		   
           case when sum(isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本年认购金额,0)+isnull(preorder.本年认购金额,0)-isnull(preorder.本年预认购转认购金额,0))*10000.0/sum(isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0)) end 本年认购均价 ,
		   case when sum(isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.去年认购金额,0)+isnull(preorder.去年认购金额,0)-isnull(preorder.去年预认购转认购金额,0))*10000.0/sum(isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0)) end 去年认购均价 ,
           case when sum(isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.累计认购金额,0)+isnull(preorder.累计认购金额,0)-isnull(preorder.累计预认购转认购金额,0))*10000.0/sum(isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0)) end 累计认购均价 

	   FROM ydkb_BaseInfo bi
        INNER JOIN #ldhz ld
            ON ld.组织架构ID = bi.组织架构ID
        LEFT JOIN #s_getin g
            ON g.BldGUID = ld.组织架构ID
        LEFT JOIN #s_fee f
            ON f.BldGUID = ld.组织架构ID
        LEFT JOIN #sp sp
            ON sp.BldGUID = bi.组织架构ID
        LEFT JOIN #pre_order preorder
            ON preorder.BldGUID = bi.组织架构ID
        LEFT JOIN #so so
            ON bi.组织架构ID = so.BldGUID
    LEFT JOIN #xsls xsls ON xsls.bldguid = bi.组织架构ID
        INNER JOIN mdm_SaleBuild sb
            ON bi.组织架构ID = sb.SaleBldGUID
        INNER JOIN mdm_GCBuild gc
            ON sb.GCBldGUID = gc.GCBldGUID
    INNER JOIN dbo.mdm_Project pj ON pj.ProjGUID = gc.ProjGUID
    INNER JOIN dbo.mdm_Product pr ON pr.ProductGUID = sb.ProductGUID
    INNER JOIN (SELECT DISTINCT 组织架构名称,组织架构父级ID,组织架构编码 FROM dbo.ydkb_BaseInfo) bi2 ON pr.ProductType = bi2.组织架构名称 AND pj.ParentProjGUID = bi2.组织架构父级ID
    LEFT JOIN #tfinfo tf on tf.BldGUID= bi.组织架构ID
    WHERE bi.组织架构类型 = 5
    GROUP BY bi.组织架构父级ID,
             gc.GCBldGUID,
             gc.BldName,
             bi2.组织架构编码,
             ld.ProjGUID;

    --插入业态的值   
    INSERT INTO ydkb_dthz_wq_deal_tradeinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        累计待收款,
        累计未正签待收款,
        累计未正签按揭待收款,
        累计未正签非按揭待收款,
        累计未正签非按揭待收款本月到期,
        累计未正签非按揭待收款本月完成,
        累计未正签非按揭待收款下月到期,
        累计正签待收款,
        正签非按揭待收款,   -- A
        正签非按揭待收款本月到期,
        正签非按揭待收款本月完成,
        正签非按揭待收款下月到期,
        正签商业贷款待收款,  --B
        正签商业贷款待收款本月到期,
        正签商业贷款待收款本月完成,
        正签商业贷款待收款下月到期,
        正签公积金贷款待收款, --C
        正签公积金贷款本月到期,
        正签公积金贷款本月完成,
        正签公积金贷款下月到期,
        Jan认购金额,
        Feb认购金额,
        Mar认购金额,
        Apr认购金额,
        May认购金额,
        Jun认购金额,
        July认购金额,
        Aug认购金额,
        Sep认购金额,
        Oct认购金额,
        Nov认购金额,
        Dec认购金额,
        Jan签约金额,
        Feb签约金额,
        Mar签约金额,
        Apr签约金额,
        May签约金额,
        Jun签约金额,
        July签约金额,
        Aug签约金额,
        Sep签约金额,
        Oct签约金额,
        Nov签约金额,
        Dec签约金额,
        本年已签约套数,
        本年已签约金额,
        本年已签约面积,
        去年已签约套数,
        去年已签约金额,
        去年已签约面积,
        累计已签约套数,
		累计已签约金额,
        累计已签约面积,
        已认购未签约金额,
        近三个月平均签约流速,
        近三个月平均签约流速_面积,
        近三个月平均签约流速_套数,
        --退房
        今日退房套数,  
        今日退房金额,
        今日退房面积,    
        本周退房套数,  
        本周退房金额,  
        本周退房面积,   
        本月退房套数,   
        本月退房金额,  
        本月退房面积,   
        本年退房套数,   
        本年退房金额,
        本年退房面积,  
        --本日、本周、本月签约金额、面积、套数、均价
        本日签约金额 ,  
        本日签约面积 ,  
        本日签约套数 ,  
        本日签约均价 ,   
        本周签约金额 ,  
        本周签约面积 ,  
        本周签约套数 ,  
        本周签约均价 ,   
        本月签约金额 ,  
        本月签约面积 ,  
        本月签约套数 ,  
        本月签约均价 ,
        --本日、本周、本月、本年认购金额、面积、套数、均价
        本日认购金额 ,  
        本日认购面积 ,  
        本日认购套数 ,  
        本日认购均价 ,   
        本周认购金额 ,  
        本周认购面积 ,  
        本周认购套数 ,  
        本周认购均价 ,   
        本月认购金额 ,  
        本月认购面积 ,  
        本月认购套数 ,  
        本月认购均价 , 
        本年认购金额 ,  
        本年认购面积 ,  
        本年认购套数 ,
        去年认购金额 ,  
        去年认购面积 ,  
        去年认购套数 ,
        累计认购套数,
        累计认购金额 ,  
        累计认购面积 ,		
        本年认购均价 ,
        去年认购均价 ,
		累计认购均价
    )
    SELECT bi2.组织架构父级ID,
           bi2.组织架构ID,
           bi2.组织架构名称,
           bi2.组织架构编码,
           bi2.组织架构类型,
           SUM(ISNULL(f.累计待收款, 0) + ISNULL(hzyj.待收款金额, 0)) AS 累计待收款,
           SUM(ISNULL(f.累计非正签待收款, 0)) AS 累计非正签待收款,
           SUM(ISNULL(f.累计未正签按揭待收款, 0)) AS 累计未正签按揭待收款,
           SUM(ISNULL(f.累计未正签非按揭待收款, 0)) AS 累计未正签非按揭待收款,
           SUM(ISNULL(f.累计未正签非按揭待收款本月到期, 0)) AS 累计未正签非按揭待收款本月到期,
           SUM(ISNULL(g.累计未正签非按揭待收款本月完成, 0)) AS 累计未累计未正签非按揭待收款本月完成正签非按揭待收款,
           SUM(ISNULL(f.累计未正签非按揭待收款下月到期, 0)) AS 累累计未正签非按揭待收款下月到期计未正签非按揭待收款,
           SUM(ISNULL(f.累计正签待收款, 0)) AS 累计正签待收款,
           SUM(ISNULL(f.正签非按揭待收款, 0)) AS 正签非按揭待收款,     -- A
           SUM(ISNULL(f.正签非按揭待收款本月到期, 0)) AS 正签非按揭待收款本月到期,
           SUM(ISNULL(g.正签非按揭待收款本月完成, 0)) AS 正签非按揭待收款本月完成,
           SUM(ISNULL(f.正签非按揭待收款下月到期, 0)) AS 正签非按揭待收款下月到期,
           SUM(ISNULL(f.正签商业贷款待收款, 0)) AS 正签商业贷款待收款,   --B
           SUM(ISNULL(f.正签商业贷款待收款本月到期, 0)) AS 正签商业贷款待收款本月到期,
           SUM(ISNULL(g.正签商业贷款待收款本月完成, 0)) AS 正签商业贷款待收款本月完成,
           SUM(ISNULL(f.正签商业贷款待收款下月到期, 0)) AS 正签商业贷款待收款下月到期,
           SUM(ISNULL(f.正签公积金贷款待收款, 0)) AS 正签公积金贷款待收款, --C
           SUM(ISNULL(f.正签公积金贷款本月到期, 0)) AS 正签公积金贷款本月到期,
           SUM(ISNULL(g.正签公积金贷款本月完成, 0)) AS 正签公积金贷款本月完成,
           SUM(ISNULL(f.正签公积金贷款下月到期, 0)) AS 正签公积金贷款下月到期,
           SUM(ISNULL(ld.Jan认购金额, 0) + ISNULL(yt.Jan认购金额, 0) + ISNULL(hzyj.Jan金额, 0)) AS Jan认购金额,
           SUM(ISNULL(ld.Feb认购金额, 0) + ISNULL(yt.Feb认购金额, 0) + ISNULL(hzyj.Feb金额, 0)) AS Feb认购金额,
           SUM(ISNULL(ld.Mar认购金额, 0) + ISNULL(yt.Mar认购金额, 0) + ISNULL(hzyj.Mar金额, 0)) AS Mar认购金额,
           SUM(ISNULL(ld.Apr认购金额, 0) + ISNULL(yt.Apr认购金额, 0) + ISNULL(hzyj.Apr金额, 0)) AS Apr认购金额,
           SUM(ISNULL(ld.May认购金额, 0) + ISNULL(yt.May认购金额, 0) + ISNULL(hzyj.May金额, 0)) AS May认购金额,
           SUM(ISNULL(ld.Jun认购金额, 0) + ISNULL(yt.Jun认购金额, 0) + ISNULL(hzyj.Jun金额, 0)) AS Jun认购金额,
           SUM(ISNULL(ld.Jul认购金额, 0) + ISNULL(yt.July认购金额, 0) + ISNULL(hzyj.Jul金额, 0)) AS July认购金额,
           SUM(ISNULL(ld.Aug认购金额, 0) + ISNULL(yt.Aug认购金额, 0) + ISNULL(hzyj.Aug金额, 0)) AS Aug认购金额,
           SUM(ISNULL(ld.Sep认购金额, 0) + ISNULL(yt.Sep认购金额, 0) + ISNULL(hzyj.Sep金额, 0)) AS Sep认购金额,
           SUM(ISNULL(ld.Oct认购金额, 0) + ISNULL(yt.Oct认购金额, 0) + ISNULL(hzyj.Oct金额, 0)) AS Oct认购金额,
           SUM(ISNULL(ld.Nov认购金额, 0) + ISNULL(yt.Nov认购金额, 0) + ISNULL(hzyj.Nov金额, 0)) AS Nov认购金额,
           SUM(ISNULL(ld.Dec认购金额, 0) + ISNULL(yt.Dec认购金额, 0) + ISNULL(hzyj.Dec金额, 0)) AS Dec认购金额,
           SUM(ISNULL(ld.Jan签约金额, 0) + ISNULL(yt.Jan签约金额, 0) + ISNULL(hzyj.Jan金额, 0)) AS Jan签约金额,
           SUM(ISNULL(ld.Feb签约金额, 0) + ISNULL(yt.Feb签约金额, 0) + ISNULL(hzyj.Feb金额, 0)) AS Feb签约金额,
           SUM(ISNULL(ld.Mar签约金额, 0) + ISNULL(yt.Mar签约金额, 0) + ISNULL(hzyj.Mar金额, 0)) AS Mar签约金额,
           SUM(ISNULL(ld.Apr签约金额, 0) + ISNULL(yt.Apr签约金额, 0) + ISNULL(hzyj.Apr金额, 0)) AS Apr签约金额,
           SUM(ISNULL(ld.May签约金额, 0) + ISNULL(yt.May签约金额, 0) + ISNULL(hzyj.May金额, 0)) AS May签约金额,
           SUM(ISNULL(ld.Jun签约金额, 0) + ISNULL(yt.Jun签约金额, 0) + ISNULL(hzyj.Jun金额, 0)) AS Jun签约金额,
           SUM(ISNULL(ld.Jul签约金额, 0) + ISNULL(yt.July签约金额, 0) + ISNULL(hzyj.Jul金额, 0)) AS July签约金额,
           SUM(ISNULL(ld.Aug签约金额, 0) + ISNULL(yt.Aug签约金额, 0) + ISNULL(hzyj.Aug金额, 0)) AS Aug签约金额,
           SUM(ISNULL(ld.Sep签约金额, 0) + ISNULL(yt.Sep签约金额, 0) + ISNULL(hzyj.Sep金额, 0)) AS Sep签约金额,
           SUM(ISNULL(ld.Oct签约金额, 0) + ISNULL(yt.Oct签约金额, 0) + ISNULL(hzyj.Oct金额, 0)) AS Oct签约金额,
           SUM(ISNULL(ld.Nov签约金额, 0) + ISNULL(yt.Nov签约金额, 0) + ISNULL(hzyj.Nov金额, 0)) AS Nov签约金额,
           SUM(ISNULL(ld.Dec签约金额, 0) + ISNULL(yt.Dec签约金额, 0) + ISNULL(hzyj.Dec金额, 0)) AS Dec签约金额,
           SUM(ISNULL(sp.本年已签约套数, 0)) 本年已签约套数,
           SUM(ISNULL(sp.本年已签约金额, 0)) 本年已签约金额,
           SUM(ISNULL(sp.本年已签约面积, 0)) 本年已签约面积,
           SUM(ISNULL(sp.去年已签约套数, 0)) 去年已签约套数,
           SUM(ISNULL(sp.去年已签约金额, 0)) 去年已签约金额,
           SUM(ISNULL(sp.去年已签约面积, 0)) 去年已签约面积,
           SUM(ISNULL(sp.累计已签约套数, 0)) 累计已签约套数,
		   SUM(ISNULL(sp.累计已签约金额, 0)) 累计已签约金额,
           SUM(ISNULL(sp.累计已签约面积, 0)) 累计已签约面积,
           SUM(ISNULL(so.已认购未签约金额, 0)) 已认购未签约金额,
           SUM(ISNULL(近三个月平均签约流速,0)) 近三个月平均签约流速,
           SUM(ISNULL(近三个月平均签约流速_面积,0)) 近三个月平均签约流速_面积, 
           SUM(ISNULL(近三个月平均签约流速_套数,0)) 近三个月平均签约流速_套数,
           sum(isnull(今日退房套数,0)) as 今日退房套数,  
           sum(isnull(今日退房金额,0)) as 今日退房金额,
           sum(isnull(今日退房面积,0)) as 今日退房面积,    
           sum(isnull(本周退房套数,0)) as 本周退房套数,  
           sum(isnull(本周退房金额,0)) as 本周退房金额,  
           sum(isnull(本周退房面积,0)) as 本周退房面积,   
           sum(isnull(本月退房套数,0)) as 本月退房套数,   
           sum(isnull(本月退房金额,0)) as 本月退房金额,  
           sum(isnull(本月退房面积,0)) as 本月退房面积,   
           sum(isnull(本年退房套数,0)) as 本年退房套数,   
           sum(isnull(本年退房金额,0)) as 本年退房金额,
           sum(isnull(本年退房面积,0)) as 本年退房面积,
           sum(isnull(sp.本日签约金额,0)) as 本日签约金额 ,  
           sum(isnull(sp.本日签约面积,0)) as 本日签约面积 ,  
           sum(isnull(sp.本日签约套数,0)) as 本日签约套数 ,  
           case when sum(isnull(sp.本日签约面积,0)) = 0 then 0 else sum(isnull(sp.本日签约金额,0))*10000.0/sum(isnull(sp.本日签约面积,0)) end 本日签约均价 ,   
           sum(isnull(sp.本周签约金额,0)) as 本周签约金额 ,  
           sum(isnull(sp.本周签约面积,0)) as 本周签约面积 ,  
           sum(isnull(sp.本周签约套数,0)) as 本周签约套数 ,  
           case when sum(isnull(sp.本周签约面积,0)) = 0 then 0 else sum(isnull(sp.本周签约金额,0))*10000.0/sum(isnull(sp.本周签约面积,0)) end 本周签约均价 ,   
           sum(isnull(sp.本月签约金额,0)) as 本月签约金额 ,  
           sum(isnull(sp.本月签约面积,0)) as 本月签约面积 ,  
           sum(isnull(sp.本月签约套数,0)) as 本月签约套数 ,  
           case when sum(isnull(sp.本月签约面积,0)) = 0 then 0 else sum(isnull(sp.本月签约金额,0))*10000.0/sum(isnull(sp.本月签约面积,0)) end 本月签约均价,
           --认购
            sum(isnull(sp.本日认购金额,0)+isnull(preorder.本日认购金额,0)-isnull(preorder.本日预认购转认购金额,0)) as 本日认购金额 ,  
           sum(isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0)) as 本日认购面积 ,  
           sum(isnull(sp.本日认购套数,0)+isnull(preorder.本日认购套数,0)-isnull(preorder.本日预认购转认购套数,0)) as 本日认购套数 ,  
           case when sum(isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本日认购金额,0)+isnull(preorder.本日认购金额,0)-isnull(preorder.本日预认购转认购金额,0))*10000.0/sum(isnull(sp.本日认购面积,0)+isnull(preorder.本日认购面积,0)-isnull(preorder.本日预认购转认购面积,0)) end 本日认购均价 ,   
           sum(isnull(sp.本周认购金额,0)+isnull(preorder.本周认购金额,0)-isnull(preorder.本周预认购转认购金额,0)) as 本周认购金额 ,  
           sum(isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0)) as 本周认购面积 ,  
           sum(isnull(sp.本周认购套数,0)+isnull(preorder.本周认购套数,0)-isnull(preorder.本周预认购转认购套数,0)) as 本周认购套数 ,  
           case when sum(isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本周认购金额,0)+isnull(preorder.本周认购金额,0)-isnull(preorder.本周预认购转认购金额,0))*10000.0/sum(isnull(sp.本周认购面积,0)+isnull(preorder.本周认购面积,0)-isnull(preorder.本周预认购转认购面积,0)) end 本周认购均价 ,   
           sum(isnull(sp.本月认购金额,0)+isnull(preorder.本月认购金额,0)-isnull(preorder.本月预认购转认购金额,0))  as 本月认购金额 ,  
           sum(isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0))  as 本月认购面积 ,  
           sum(isnull(sp.本月认购套数,0)+isnull(preorder.本月认购套数,0)-isnull(preorder.本月预认购转认购套数,0))  as 本月认购套数 ,  
           case when sum(isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本月认购金额,0)+isnull(preorder.本月认购金额,0)-isnull(preorder.本月预认购转认购金额,0))*10000.0/sum(isnull(sp.本月认购面积,0)+isnull(preorder.本月认购面积,0)-isnull(preorder.本月预认购转认购面积,0)) end 本月认购均价 ,   
           sum(isnull(sp.本年认购金额,0)+isnull(preorder.本年认购金额,0)-isnull(preorder.本年预认购转认购金额,0)) as 本年认购金额 ,  
           sum(isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0)) as 本年认购面积 ,  
           sum(isnull(sp.本年认购套数,0)+isnull(preorder.本年认购套数,0)-isnull(preorder.本年预认购转认购套数,0)) as 本年认购套数 , 
           sum(isnull(sp.去年认购金额,0)+isnull(preorder.去年认购金额,0)-isnull(preorder.去年预认购转认购金额,0)) as 去年认购金额 ,  
           sum(isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0)) as 去年认购面积 ,  
           sum(isnull(sp.去年认购套数,0)+isnull(preorder.去年认购套数,0)-isnull(preorder.去年预认购转认购套数,0)) as 去年认购套数 , 
           sum(isnull(sp.累计认购套数,0)+isnull(preorder.累计认购套数,0)-isnull(preorder.累计预认购转认购套数,0)) as 累计认购套数 , 
           sum(isnull(sp.累计认购金额,0)+isnull(preorder.累计认购金额,0)-isnull(preorder.累计预认购转认购金额,0)) as 累计认购金额 ,  
           sum(isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0)) as 累计认购面积 ,  		   
           case when sum(isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.本年认购金额,0)+isnull(preorder.本年认购金额,0)-isnull(preorder.本年预认购转认购金额,0))*10000.0/sum(isnull(sp.本年认购面积,0)+isnull(preorder.本年认购面积,0)-isnull(preorder.本年预认购转认购面积,0)) end 本年认购均价 ,
		   case when sum(isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.去年认购金额,0)+isnull(preorder.去年认购金额,0)-isnull(preorder.去年预认购转认购金额,0))*10000.0/sum(isnull(sp.去年认购面积,0)+isnull(preorder.去年认购面积,0)-isnull(preorder.去年预认购转认购面积,0)) end 去年认购均价 ,
           case when sum(isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0)) = 0 then 0 else sum(isnull(sp.累计认购金额,0)+isnull(preorder.累计认购金额,0)-isnull(preorder.累计预认购转认购金额,0))*10000.0/sum(isnull(sp.累计认购面积,0)+isnull(preorder.累计认购面积,0)-isnull(preorder.累计预认购转认购面积,0)) end 累计认购均价 
		   FROM ydkb_BaseInfo bi2
        --系统自动取数部分
        LEFT JOIN
        (
            SELECT ld.ProjGUID,
                   ld.ProductType,
                   SUM(Jan认购金额) AS Jan认购金额,
                   SUM(Feb认购金额) AS Feb认购金额,
                   SUM(Mar认购金额) AS Mar认购金额,
                   SUM(Apr认购金额) AS Apr认购金额,
                   SUM(May认购金额) AS May认购金额,
                   SUM(Jun认购金额) AS Jun认购金额,
                   SUM(Jul认购金额) AS Jul认购金额,
                   SUM(Aug认购金额) AS Aug认购金额,
                   SUM(Sep认购金额) AS Sep认购金额,
                   SUM(Oct认购金额) AS Oct认购金额,
                   SUM(Nov认购金额) AS Nov认购金额,
                   SUM(Dec认购金额) AS Dec认购金额,
                   SUM(Jan签约金额) AS Jan签约金额,
                   SUM(Feb签约金额) AS Feb签约金额,
                   SUM(Mar签约金额) AS Mar签约金额,
                   SUM(Apr签约金额) AS Apr签约金额,
                   SUM(May签约金额) AS May签约金额,
                   SUM(Jun签约金额) AS Jun签约金额,
                   SUM(Jul签约金额) AS Jul签约金额,
                   SUM(Aug签约金额) AS Aug签约金额,
                   SUM(Sep签约金额) AS Sep签约金额,
                   SUM(Oct签约金额) AS Oct签约金额,
                   SUM(Nov签约金额) AS Nov签约金额,
                   SUM(Dec签约金额) AS Dec签约金额
            FROM #ldhz ld
                LEFT JOIN #hzyj h
                    ON ld.ProjGUID = h.ProjGUID
                       AND ld.ProductType = h.ProductType
                       AND h.ProjGUID <> 'd07ccf43-cbc0-e811-80bf-e61f13c57837'
            GROUP BY ld.ProjGUID,
                     ld.ProductType,
                     ISNULL(h.累计签约额, 0),
                     ISNULL(h.累计签约面积, 0)
        ) ld
            ON ld.ProjGUID = bi2.组织架构父级ID
               AND ld.ProductType = bi2.组织架构名称
    LEFT JOIN #xsls_yt xsls ON xsls.ProjGUID = bi2.组织架构父级ID
               AND xsls.ProductType = bi2.组织架构名称
        --手工铺排部分 
        LEFT JOIN #ythz yt
            ON yt.组织架构父级ID = bi2.组织架构父级ID
               AND yt.组织架构名称 = bi2.组织架构名称
        --合作业绩认购数
        LEFT JOIN #hzyj hzyj
            ON hzyj.ProjGUID = bi2.组织架构父级ID
               AND hzyj.ProductType = bi2.组织架构名称
        --待收款情况
        LEFT JOIN
        (
            SELECT g.ProjGUID,
                   g.ProductType,
                   SUM(g.累计未正签非按揭待收款本月完成) AS 累计未正签非按揭待收款本月完成,
                   SUM(g.正签非按揭待收款本月完成) AS 正签非按揭待收款本月完成,
                   SUM(g.正签公积金贷款本月完成) AS 正签公积金贷款本月完成,
                   SUM(g.正签商业贷款待收款本月完成) 正签商业贷款待收款本月完成
            FROM #s_getin g
            GROUP BY g.ProjGUID,
                     g.ProductType
        ) g
            ON g.ProductType = bi2.组织架构名称
               AND bi2.组织架构父级ID = g.ProjGUID
        LEFT JOIN #f_yt f
            ON f.ProductType = bi2.组织架构名称
               AND bi2.组织架构父级ID = f.ProjGUID
        --获取本年已签约金额
        LEFT JOIN #sp_yt sp
            ON sp.ParentProjGUID = bi2.组织架构父级ID
               AND sp.TopProductTypeName = bi2.组织架构名称
        LEFT JOIN #pre_order_yt preorder
            ON preorder.ParentProjGUID = bi2.组织架构父级ID
               AND preorder.ProductType = bi2.组织架构名称
        LEFT JOIN #so_yt so
            ON so.ParentProjGUID = bi2.组织架构父级ID
               AND so.ProductType = bi2.组织架构名称
        --退房情况
        left join (select ProjGUID,ProductType,
                sum(isnull(今日退房套数,0)) as 今日退房套数,
                sum(isnull(今日退房金额,0)) as 今日退房金额,
                sum(isnull(今日退房面积,0)) as 今日退房面积,
                sum(isnull(本周退房套数,0)) as 本周退房套数,
                sum(isnull(本周退房金额,0)) as 本周退房金额,
                sum(isnull(本周退房面积,0)) as 本周退房面积,
                sum(isnull(本月退房套数,0)) as 本月退房套数,
                sum(isnull(本月退房金额,0)) as 本月退房金额,
                sum(isnull(本月退房面积,0)) as 本月退房面积,
                sum(isnull(本年退房套数,0)) as 本年退房套数,
                sum(isnull(本年退房金额,0)) as 本年退房金额,
                sum(isnull(本年退房面积,0)) as 本年退房面积
               from #tfinfo 
        group by ProjGUID,ProductType) tf ON tf.ProjGUID = bi2.组织架构父级ID
               AND tf.ProductType = bi2.组织架构名称
    WHERE bi2.组织架构类型 = 4  AND bi2.平台公司GUID IN (
                                   SELECT Value FROM dbo.fn_Split2(@developmentguid, ',')
                               )
    GROUP BY bi2.组织架构父级ID,
             bi2.组织架构ID,
             bi2.组织架构名称,
             bi2.组织架构编码,
             bi2.组织架构类型;


    --循环插入项目，城市公司，平台公司的值   
    DECLARE @baseinfo INT;
    SET @baseinfo = 4;

    WHILE (@baseinfo > 1)
    BEGIN

        INSERT INTO ydkb_dthz_wq_deal_tradeinfo
        (
            组织架构父级ID,
            组织架构ID,
            组织架构名称,
            组织架构编码,
            组织架构类型,
            本月认购任务,
            本年认购任务 , 
            去年认购任务 ,
            本月签约任务,
            本年签约任务 ,
            去年签约任务 ,
            明年签约任务 ,
            累计待收款,
            累计未正签待收款,
            累计未正签按揭待收款,
            累计未正签非按揭待收款,
            累计未正签非按揭待收款本月到期,
            累计未正签非按揭待收款本月完成,
            累计未正签非按揭待收款下月到期,
            累计正签待收款,
            正签非按揭待收款,   -- A
            正签非按揭待收款本月到期,
            正签非按揭待收款本月完成,
            正签非按揭待收款下月到期,
            正签商业贷款待收款,  --B
            正签商业贷款待收款本月到期,
            正签商业贷款待收款本月完成,
            正签商业贷款待收款下月到期,
            正签公积金贷款待收款, --C
            正签公积金贷款本月到期,
            正签公积金贷款本月完成,
            正签公积金贷款下月到期,
            Jan认购金额,
            Feb认购金额,
            Mar认购金额,
            Apr认购金额,
            May认购金额,
            Jun认购金额,
            July认购金额,
            Aug认购金额,
            Sep认购金额,
            Oct认购金额,
            Nov认购金额,
            Dec认购金额,
            Jan签约金额,
            Feb签约金额,
            Mar签约金额,
            Apr签约金额,
            May签约金额,
            Jun签约金额,
            July签约金额,
            Aug签约金额,
            Sep签约金额,
            Oct签约金额,
            Nov签约金额,
            Dec签约金额,
            本年已签约套数,
            本年已签约金额,
            本年已签约面积,
            去年已签约套数,
            去年已签约金额,
            去年已签约面积,
            累计已签约套数,
			累计已签约金额,
            累计已签约面积,
            已认购未签约金额,
            近三个月平均签约流速,
            近三个月平均签约流速_面积,
            近三个月平均签约流速_套数,
            --退房
            今日退房套数,
            今日退房金额,
            今日退房面积,
            本周退房套数,
            本周退房金额,
            本周退房面积,
            本月退房套数,
            本月退房金额,
            本月退房面积,
            本年退房套数,
            本年退房金额,
            本年退房面积, 
            --本日、本周、本月签约金额、面积、套数、均价
            本日签约金额 ,  
            本日签约面积 ,  
            本日签约套数 ,  
            本日签约均价 ,   
            本周签约金额 ,  
            本周签约面积 ,  
            本周签约套数 ,  
            本周签约均价 ,   
            本月签约金额 ,  
            本月签约面积 ,  
            本月签约套数 ,  
            本月签约均价 ,
            --本日、本周、本月、本年认购金额、面积、套数、均价
            本日认购金额 ,  
            本日认购面积 ,  
            本日认购套数 ,  
            本日认购均价 ,   
            本周认购金额 ,  
            本周认购面积 ,  
            本周认购套数 ,  
            本周认购均价 ,   
            本月认购金额 ,  
            本月认购面积 ,  
            本月认购套数 ,  
            本月认购均价 , 
            本年认购金额 ,  
            本年认购面积 ,  
            本年认购套数 , 
            去年认购金额 ,  
            去年认购面积 ,  
            去年认购套数 , 
            累计认购套数,
            累计认购金额 ,  
            累计认购面积 ,			
            本年认购均价 ,
            去年认购均价 ,
			累计认购均价
        )
        SELECT bi.组织架构父级ID,
               bi.组织架构ID,
               bi.组织架构名称,
               bi.组织架构编码,
               bi.组织架构类型,
               SUM(本月认购任务) 本月认购任务 ,
               SUM(本年认购任务) 本年认购任务 ,
               SUM(去年认购任务) 去年认购任务 ,
               SUM(本月签约任务) 本月签约任务 ,
               SUM(本年签约任务) 本年签约任务 ,
               SUM(去年签约任务) 去年签约任务 ,
               SUM(明年签约任务) 明年签约任务 ,
               SUM(累计待收款) AS 累计待收款,
               SUM(累计未正签待收款) AS 累计非正签待收款,
               SUM(累计未正签按揭待收款) AS 累计未正签按揭待收款,
               SUM(累计未正签非按揭待收款) AS 累计未正签非按揭待收款,
               SUM(累计未正签非按揭待收款本月到期) AS 累计未正签非按揭待收款本月到期,
               SUM(累计未正签非按揭待收款本月完成) AS 累计未正签非按揭待收款本月完成,
               SUM(累计未正签非按揭待收款下月到期) AS 累计未正签非按揭待收款下月到期,
               SUM(累计正签待收款) AS 累计正签待收款,
               SUM(正签非按揭待收款) AS 正签非按揭待收款,     -- A
               SUM(正签非按揭待收款本月到期) AS 正签非按揭待收款本月到期,
               SUM(正签非按揭待收款本月完成) AS 正签非按揭待收款本月完成,
               SUM(正签非按揭待收款下月到期) AS 正签非按揭待收款下月到期,
               SUM(正签商业贷款待收款) AS 正签商业贷款待收款,   --B
               SUM(正签商业贷款待收款本月到期) AS 正签商业贷款待收款本月到期,
               SUM(正签商业贷款待收款本月完成) AS 正签商业贷款待收款本月完成,
               SUM(正签商业贷款待收款下月到期) AS 正签商业贷款待收款下月到期,
               SUM(正签公积金贷款待收款) AS 正签公积金贷款待收款, --C
               SUM(正签公积金贷款本月到期) AS 正签公积金贷款本月到期,
               SUM(正签公积金贷款本月完成) AS 正签公积金贷款本月完成,
               SUM(正签公积金贷款下月到期) AS 正签公积金贷款下月到期,
               SUM(Jan认购金额) AS Jan认购金额,
               SUM(Feb认购金额) AS Feb认购金额,
               SUM(Mar认购金额) AS Mar认购金额,
               SUM(Apr认购金额) AS Apr认购金额,
               SUM(May认购金额) AS May认购金额,
               SUM(Jun认购金额) AS Jun认购金额,
               SUM(July认购金额) AS July认购金额,
               SUM(Aug认购金额) AS Aug认购金额,
               SUM(Sep认购金额) AS Sep认购金额,
               SUM(Oct认购金额) AS Oct认购金额,
               SUM(Nov认购金额) AS Nov认购金额,
               SUM(Dec认购金额) AS Dec认购金额,
               SUM(Jan签约金额) AS Jan签约金额,
               SUM(Feb签约金额) AS Feb签约金额,
               SUM(Mar签约金额) AS Mar签约金额,
               SUM(Apr签约金额) AS Apr签约金额,
               SUM(May签约金额) AS May签约金额,
               SUM(Jun签约金额) AS Jun签约金额,
               SUM(July签约金额) AS July签约金额,
               SUM(Aug签约金额) AS Aug签约金额,
               SUM(Sep签约金额) AS Sep签约金额,
               SUM(Oct签约金额) AS Oct签约金额,
               SUM(Nov签约金额) AS Nov签约金额,
               SUM(Dec签约金额) AS Dec签约金额,
               SUM(本年已签约套数) AS 本年已签约套数,
               SUM(本年已签约金额) AS 本年已签约金额,
               SUM(本年已签约面积) AS 本年已签约面积,
               SUM(去年已签约套数) AS 去年已签约套数,
               SUM(去年已签约金额) AS 去年已签约金额,
               SUM(去年已签约面积) AS 去年已签约面积,
               SUM(累计已签约套数) AS 累计已签约套数,
			   SUM(累计已签约金额) AS 累计已签约金额,
               SUM(累计已签约面积) AS 累计已签约面积,
               SUM(已认购未签约金额) AS 已认购未签约金额,
               SUM(近三个月平均签约流速) AS 近三个月平均签约流速,
               SUM(近三个月平均签约流速_面积) AS 近三个月平均签约流速_面积,
               SUM(近三个月平均签约流速_套数) AS 近三个月平均签约流速_套数,
               sum(isnull(今日退房套数,0)) as 今日退房套数,
               sum(isnull(今日退房金额,0)) as 今日退房金额,
               sum(isnull(今日退房面积,0)) as 今日退房面积,
               sum(isnull(本周退房套数,0)) as 本周退房套数,
               sum(isnull(本周退房金额,0)) as 本周退房金额,
               sum(isnull(本周退房面积,0)) as 本周退房面积,
               sum(isnull(本月退房套数,0)) as 本月退房套数,
               sum(isnull(本月退房金额,0)) as 本月退房金额,
               sum(isnull(本月退房面积,0)) as 本月退房面积,
               sum(isnull(本年退房套数,0)) as 本年退房套数,
               sum(isnull(本年退房金额,0)) as 本年退房金额,
               sum(isnull(本年退房面积,0)) as 本年退房面积, 
               sum(isnull(本日签约金额,0)) as 本日签约金额 ,  
               sum(isnull(本日签约面积,0)) as 本日签约面积 ,  
               sum(isnull(本日签约套数,0)) as 本日签约套数 ,  
               case when sum(isnull(本日签约面积,0)) = 0 then 0 else sum(isnull(本日签约金额,0))*10000.0/sum(isnull(本日签约面积,0)) end 本日签约均价 ,   
               sum(isnull(本周签约金额,0)) as 本周签约金额 ,  
               sum(isnull(本周签约面积,0)) as 本周签约面积 ,  
               sum(isnull(本周签约套数,0)) as 本周签约套数 ,  
               case when sum(isnull(本周签约面积,0)) = 0 then 0 else sum(isnull(本周签约金额,0))*10000.0/sum(isnull(本周签约面积,0)) end 本周签约均价 ,   
               sum(isnull(本月签约金额,0)) as 本月签约金额 ,  
               sum(isnull(本月签约面积,0)) as 本月签约面积 ,  
               sum(isnull(本月签约套数,0)) as 本月签约套数 ,  
               case when sum(isnull(本月签约面积,0)) = 0 then 0 else sum(isnull(本月签约金额,0))*10000.0/sum(isnull(本月签约面积,0)) end 本月签约均价,
               --认购
               sum(isnull(本日认购金额,0)) as 本日认购金额 ,  
               sum(isnull(本日认购面积,0)) as 本日认购面积 ,  
               sum(isnull(本日认购套数,0)) as 本日认购套数 ,  
               case when sum(isnull(本日认购面积,0)) = 0 then 0 else sum(isnull(本日认购金额,0))*10000.0/sum(isnull(本日认购面积,0)) end 本日认购均价 ,   
               sum(isnull(本周认购金额,0)) as 本周认购金额 ,  
               sum(isnull(本周认购面积,0)) as 本周认购面积 ,  
               sum(isnull(本周认购套数,0)) as 本周认购套数 ,  
               case when sum(isnull(本周认购面积,0)) = 0 then 0 else sum(isnull(本周认购金额,0))*10000.0/sum(isnull(本周认购面积,0)) end 本周认购均价 ,   
               sum(isnull(本月认购金额,0)) as 本月认购金额 ,  
               sum(isnull(本月认购面积,0)) as 本月认购面积 ,  
               sum(isnull(本月认购套数,0)) as 本月认购套数 ,  
               case when sum(isnull(本月认购面积,0)) = 0 then 0 else sum(isnull(本月认购金额,0))*10000.0/sum(isnull(本月认购面积,0)) end 本月认购均价,
               sum(isnull(本年认购金额,0)) as 本年认购金额 ,  
               sum(isnull(本年认购面积,0)) as 本年认购面积 ,  
               sum(isnull(本年认购套数,0)) as 本年认购套数 ,  
               sum(isnull(去年认购金额,0)) as 去年认购金额 ,  
               sum(isnull(去年认购面积,0)) as 去年认购面积 ,  
               sum(isnull(去年认购套数,0)) as 去年认购套数 , 
               sum(isnull(累计认购套数,0)) as 累计认购套数 , 
			   sum(isnull(累计认购金额,0)) as 累计认购金额 ,  
               sum(isnull(累计认购面积,0)) as 累计认购面积 ,  
               case when sum(isnull(本年认购面积,0)) = 0 then 0 else sum(isnull(本年认购金额,0))*10000.0/sum(isnull(本年认购面积,0)) end 本年认购均价,
               case when sum(isnull(去年认购面积,0)) = 0 then 0 else sum(isnull(去年认购金额,0))*10000.0/sum(isnull(去年认购面积,0)) end 去年认购均价,
			   case when sum(isnull(累计认购面积,0)) = 0 then 0 else sum(isnull(累计认购金额,0))*10000.0/sum(isnull(累计认购面积,0)) end 累计认购均价
        FROM ydkb_dthz_wq_deal_tradeinfo b
            INNER JOIN ydkb_BaseInfo bi
                ON bi.组织架构ID = b.组织架构父级ID
        WHERE b.组织架构类型 = @baseinfo
        GROUP BY bi.组织架构父级ID,
                 bi.组织架构ID,
                 bi.组织架构名称,
                 bi.组织架构编码,
                 bi.组织架构类型;
        
        --更新项目层级的任务指标
        if(@baseinfo = 4)
        begin 
            --更新任务指标
            update bi set 
            bi.本年签约任务 = isnull(rw.本年签约任务,0),
            bi.去年签约任务 = isnull(rw.去年签约任务,0),
            bi.本年认购任务 = isnull(rw.本年认购任务,0),
            bi.去年认购任务 = isnull(rw.去年认购任务,0),
            bi.明年签约任务 = isnull(mnrw.明年签约任务,0),
            bi.本月认购任务 = isnull(byrw.本月认购任务,0),
            bi.本月签约任务 = isnull(byrw.本月签约任务,0)
            FROM ydkb_dthz_wq_deal_tradeinfo bi
            left join (
                SELECT a.BusinessGUID,
                    sum(case when DATEDIFF(yy, f.BeginDate, GETDATE()) = 0 then [签约任务（亿元）] else 0 end) * 10000 as 本年签约任务,
                    sum(case when DATEDIFF(yy, f.BeginDate, @qnDate) = 0 then [签约任务（亿元）] else 0 end) * 10000 as 去年签约任务,
                    sum(case when DATEDIFF(yy, f.BeginDate, GETDATE()) = 0 then [认购任务（亿元）] else 0 end) * 10000 as 本年认购任务,
                    sum(case when DATEDIFF(yy, f.BeginDate, @qnDate) = 0 then [认购任务（亿元）] else 0 end) * 10000 as 去年认购任务
                FROM dss.dbo.nmap_F_平台公司项目层级年度任务填报 a
                INNER JOIN dss.dbo.nmap_F_FillHistory f ON f.FillHistoryGUID = a.FillHistoryGUID
                -- where DATEDIFF(yy, f.BeginDate, GETDATE()) = 0
                group by a.BusinessGUID
            ) rw on rw.BusinessGUID = bi.组织架构ID
            left join (
                select a.projguid,
                    sum(ThisMonthSaleMoneyQy) as 明年签约任务
                from  dbo.s_SaleValueBuildLayout a
                WHERE SaleValuePlanYear = @bnYear+1
                group by a.projguid
            )mnrw on mnrw.projguid = bi.组织架构id
            --获取本月任务
            left join (
                SELECT a.BusinessGUID,
                    sum([签约任务（亿元）] ) * 10000 as 本月签约任务, 
                    sum([认购任务（亿元）] ) * 10000 as 本月认购任务
                FROM dss.dbo.nmap_F_平台公司项目层级月度任务填报 a
                INNER JOIN dss.dbo.nmap_F_FillHistory f ON f.FillHistoryGUID = a.FillHistoryGUID
                where DATEDIFF(mm, f.BeginDate, GETDATE()) = 0  
                group by a.BusinessGUID
            )byrw on  byrw.BusinessGUID = bi.组织架构ID
             
        end
        SET @baseinfo = @baseinfo - 1;
    END;

    SELECT * FROM dbo.ydkb_dthz_wq_deal_tradeinfo;

    --删除临时表
    DROP TABLE #ldhz, #hzyj,#s_fee,#s_getin,#t_sale,#t_sale2,#t_sale_qy1,#t_sale_rg1,#ythz,#yt_sale1,#yt_sale2,#yt_sale_rg;

END;
 
